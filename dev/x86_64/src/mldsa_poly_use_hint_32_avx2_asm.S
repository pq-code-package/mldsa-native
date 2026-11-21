/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [REF_AVX2]
 *   CRYSTALS-Dilithium optimized AVX2 implementation
 *   Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé
 *   https://github.com/pq-crystals/dilithium/tree/master/avx2
 */

/*
 * This file is derived from the public domain
 * AVX2 Dilithium implementation @[REF_AVX2].
 */


/*yaml
  Name: poly_use_hint_32_avx2_asm
  Description: x86_64 AVX2 hint application (alpha = (Q-1)/32).
    Use the hint polynomial h to correct the high bits of the polynomial a,
    in place. Variant for parameter sets ML-DSA-65 and ML-DSA-87
    (GAMMA2 = (Q-1)/32).
  Signature: void mld_poly_use_hint_32_avx2_asm(int32_t *a, const int32_t *h)
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t *a
      description: Input/output polynomial (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t *h
      description: Hint polynomial (256 x int32_t)
*/

#include "../../../common.h"

#if defined(MLD_SYS_X86_64_AVX2) && \
    defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&          \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87))

/* simpasm: header-end */

/* Reference:
 * - @[REF_AVX2] calls poly_decompose to compute all a1, a0 before the loop.
 * - Our implementation of decompose() is slightly different from that in
 *   @[REF_AVX2]. See poly_decompose_32_avx2.c for more information.
 */

/*
 * Note on operand order: if a commutative VEX instruction such as vpaddd
 * has one source register in ymm8-15 and the other in ymm0-7, the one in
 * ymm8-15 comes second. Only then do all assemblers emit the same bytes:
 * clang's assembler would swap the operands itself to use the 2-byte VEX
 * prefix, while GNU as keeps the order. The HOL Light proofs are about
 * these bytes.
 */

// a aliased with a0
.macro decompose32_avx2 a1, a, temp
// Compute a1 = round-(a / 523776), where 523776 = 2*GAMMA2 = 128*B
// with B = 4092, and round-() denotes "round half down". This is
// exact for 0 <= a < Q. It is computed as round-(ceil(a / 128) / B)
// ≈ round(ceil(a / 128) * 1025 / 2^22), with 1025 = floor(2^22 / B):
//   a1 = ceil(a / 128) = floor((a + 127) / 2^7)   (vpaddd 127; vpsrld 7)
//   a1 = floor(a1 * 1025 / 2^16)                  (vpmulhuw by 1025)
//   a1 = round(a1 / 2^6) via mulhrs(a1, 2^9)      (vpmulhrsw)
// See mld_poly_decompose_32_avx2() for the detailed argument.
vpaddd  \a, %ymm5, \a1
vpsrld  $7, \a1, \a1
vpmulhuw    %ymm8, \a1, \a1
vpmulhrsw   %ymm7, \a1, \a1

// No wrap-around correction: for a > 31*GAMMA2, a1 = 16 is reduced
// to 0 mod 16 below, and a0 <= 0 holds with or without it.

// Compute remainder a0 = a - a1 * 2 * GAMMA2 = a - a1 * 523776
vpslld  $10, \a1, \temp
vpsubd  \a1, \temp, \temp
vpslld  $9, \temp, \temp
vpsubd  \temp, \a, \a
.endm

/* We follow the specification and the reference C implementation and check
 * a0 > 0. The @[REF_AVX2] implementation used to check a0 >= 0 instead, but
 * this was corrected to match the specification in pq-crystals/dilithium
 * commit bba9534a3c5cbef66481cd6518d786e23ae601b5.
 */

// a aliased with delta
.macro use_hint32_avx2 b, a, h, a1, temp
decompose32_avx2 \a1, \a, \temp

// delta = (a0 <= 0) ? -1 : 1
vpcmpgtd    %ymm6, \a, \a
vpandn  \h, \a, \a
vpslld  $1, \a, \a
vpsubd  \a, \h, \h

// b = (b + delta * h) % 16
vpaddd  \h, \a1, \b
vpand   %ymm3, \b, \b
.endm

.text
.balign 16
.global MLD_ASM_NAMESPACE(poly_use_hint_32_avx2_asm)
MLD_ASM_FN_SYMBOL(poly_use_hint_32_avx2_asm)

// Initialize constants
movl    $127, %ecx

/* check-magic: 1025 == floor(2^22 / 4092) */
movl    $1025, %r8d
vmovd   %r8d, %xmm8
vpbroadcastd    %xmm8, %ymm8

xorl    %eax, %eax
vpxor   %xmm6, %xmm6, %xmm6
vmovd   %ecx, %xmm5

/* round(x * 2^9 / 2^15) => round(x / 2^6), for f1 = round(f1'' / 2^6) */
movl    $512, %r9d
vmovd   %r9d, %xmm7
vpbroadcastd    %xmm7, %ymm7

movl    $15, %ecx
vpbroadcastd    %xmm5, %ymm5
vmovd   %ecx, %xmm3
vpbroadcastd    %xmm3, %ymm3


mld_poly_use_hint_32_avx2_asm_loop:
vmovdqa (%rdi), %ymm0
vmovdqa (%rsi), %ymm2

use_hint32_avx2 %ymm2, %ymm0, %ymm2, %ymm9, %ymm1

vmovdqa %ymm2, (%rdi)
addq    $32, %rdi
addq    $32, %rsi
addq    $32, %rax
cmpq    $1024, %rax
jne mld_poly_use_hint_32_avx2_asm_loop
/* Clear upper halves of YMM registers to avoid a performance
 * penalty when switching to SSE. */
vzeroupper
ret

/* simpasm: footer-start */

#endif /* MLD_SYS_X86_64_AVX2 && MLD_ARITH_BACKEND_X86_64_DEFAULT && \
          !MLD_CONFIG_NO_VERIFY_API && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87) */
