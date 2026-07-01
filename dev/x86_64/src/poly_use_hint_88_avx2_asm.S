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
  Name: poly_use_hint_88_avx2_asm
  Description: x86_64 AVX2 hint application (alpha = (Q-1)/88).
    Use the hint polynomial h to correct the high bits of the polynomial a,
    in place. Variant for parameter set ML-DSA-44 (GAMMA2 = (Q-1)/88).
  Signature: void mld_poly_use_hint_88_avx2_asm(int32_t *a, const int32_t *h)
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

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&          \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    MLD_CONFIG_PARAMETER_SET == 44)
/* simpasm: header-end */

/* Reference:
 * - @[REF_AVX2] calls poly_decompose to compute all a1, a0 before the loop.
 * - Our implementation of decompose() is slightly different from that in
 *   @[REF_AVX2]. See poly_decompose_88_avx2.c for more information.
 */

// a aliased with a0
.macro decompose88_avx2 a1, a, temp1, temp2, temp3
// Compute a1 = round-(a / 190464), where 190464 = 2*GAMMA2 = 128*B
// with B = 1488, and round-() denotes "round half down". This is
// exact for 0 <= a < Q. It is computed as round-(ceil(a / 128) / B)
// ≈ round(ceil(a / 128) * 11275 / 2^24), with 11275 = floor(2^24 / B):
//   temp1 = ceil(a / 128) = floor((a + 127) / 2^7)   (vpaddd 127; vpsrld 7)
//   temp1 = floor(temp1 * 11275 / 2^16)               (vpmulhuw by 11275)
//   temp1 = round(temp1 / 2^8) via mulhrs(temp1, 2^7) (vpmulhrsw)
// See mld_poly_decompose_88_avx2() for the detailed argument.
vpaddd  \a, %ymm4, \temp1
vpsrld  $7, \temp1, \temp1
vpmulhuw    %ymm8, \temp1, \temp1
vpmulhrsw   %ymm7, \temp1, \temp1

// If a1 = 44, i.e. a > 87*GAMMA2, proceed as if a' = a - Q was
// given instead. (For a = 87*GAMMA2 + 1 thus a' = -GAMMA2, we
// still round it to 0 like other "wrapped around" cases.)

// Check for wrap-around
vpcmpgtd    %ymm3, \a, \temp2
vpandn  \temp1, \temp2, \a1

// Compute remainder a0 = a - a1 * 2 * GAMMA2 = a - a1 * 190464
vpslld  $1, \temp1, \temp3
vpaddd  \temp1, \temp3, \temp3
vpslld  $5, \temp3, \temp1
vpsubd  \temp3, \temp1, \temp1
vpslld  $11, \temp1, \temp1
vpsubd  \temp1, \a, \a

// If wrap-around is required, adjust a0 by -1
vpaddd  \temp2, \a, \a
.endm

/* We follow the specification and the reference C implementation and check
 * a0 > 0. The @[REF_AVX2] implementation used to check a0 >= 0 instead, but
 * this was corrected to match the specification in pq-crystals/dilithium
 * commit bba9534a3c5cbef66481cd6518d786e23ae601b5.
 */

// a aliased with delta
.macro use_hint88_avx2 b, a, h, a1, temp1, temp2, temp3
decompose88_avx2 \a1, \a, \temp1, \temp2, \temp3

// delta = (a0 <= 0) ? -1 : 1
vpcmpgtd    %ymm5, \a, \a
vpandn  \h, \a, \a
vpslld  $1, \a, \a
vpsubd  \a, \h, \a

// b = (b + delta * h) % 44
vpaddd  \a1, \a, \b
// If b wrapped below 0 (a1 == 0, delta == -1), set b = 43.
// b is in [-1, 44], so the per-dword sign bit and the per-byte
// blend mask of vpblendvb coincide.
vpblendvb   \b, %ymm6, \b, \b
// If b overflowed above 43 (a1 == 43, delta == +1), set b = 0.
vpcmpgtd    %ymm6, \b, \h
vpandn  \b, \h, \b
.endm

.text
.balign 16
.global MLD_ASM_NAMESPACE(poly_use_hint_88_avx2_asm)
MLD_ASM_FN_SYMBOL(poly_use_hint_88_avx2_asm)

// Initialize constants
movl    $127, %ecx
xorl    %eax, %eax
vpxor   %xmm5, %xmm5, %xmm5

/* check-magic: 11275 == floor(2^24 / 1488) */
movl    $11275, %r8d
vmovd   %r8d, %xmm8
vpbroadcastd    %xmm8, %ymm8

vmovd   %ecx, %xmm4

/* 87 * ((Q-1) / 88) == 87 * GAMMA2, wrap-around threshold */
movl    $8285184, %ecx

/* round(x * 2^7 / 2^15) => round(x / 2^8), for f1 = round(f1'' / 2^8) */
movl    $128, %r9d
vmovd   %r9d, %xmm7
vpbroadcastd    %xmm7, %ymm7

/* max a1 value */
movl    $43, %r10d
vmovd   %r10d, %xmm6
vpbroadcastd    %xmm6, %ymm6

vmovd   %ecx, %xmm3
vpbroadcastd    %xmm4, %ymm4
vpbroadcastd    %xmm3, %ymm3

poly_use_hint_88_avx2_asm_loop:
vmovdqa (%rdi), %ymm0
vmovdqa (%rsi), %ymm1

use_hint88_avx2 %ymm0, %ymm0, %ymm1, %ymm9, %ymm10, %ymm11, %ymm12

vmovdqa %ymm0, (%rdi)
addq    $32, %rdi
addq    $32, %rsi
addq    $32, %rax
cmpq    $1024, %rax
jne poly_use_hint_88_avx2_asm_loop

ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_NO_VERIFY_API && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */
