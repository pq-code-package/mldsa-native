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
  Name: polyz_unpack_17_avx2_asm
  Description: x86_64 AVX2 unpacking of 17-bit packed coefficients.
    Unpack polynomial z with 18-bit packed coefficients (GAMMA1 = 2^17),
    mapping packed [0, 2^18-1] to signed [-(2^17-1), 2^17] via GAMMA1 - x.
  Signature: void mld_polyz_unpack_17_avx2_asm(int32_t *r, const uint8_t *a)
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t *r
      description: Output polynomial (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 576
      permissions: read-only
      c_parameter: const uint8_t *a
      description: Packed input bytes
*/

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    (!defined(MLD_CONFIG_NO_SIGN_API) ||           \
     !defined(MLD_CONFIG_NO_VERIFY_API)) &&        \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     MLD_CONFIG_PARAMETER_SET == 44)

/* simpasm: header-end */

/* Unpack one block of 8 coefficients (18 packed input bytes -> 8 x int32).
 *
 * Load bytes [18i .. 18i+15] into the low 128-bit half and [18i+2 .. 18i+17]
 * into the high 128-bit half, then replicate the AVX2 intrinsic pipeline:
 * byte shuffle, per-lane variable right shift, mask to 18 bits, and
 * gamma1 - x. */
.macro unpack17_block i
vmovdqu (18*\i)(%rsi), %xmm0
vmovdqu (18*\i + 2)(%rsi), %xmm5
vinserti128 $1, %xmm5, %ymm0, %ymm0
vpshufb %ymm1, %ymm0, %ymm0
vpsrlvd %ymm2, %ymm0, %ymm0
vpand   %ymm3, %ymm0, %ymm0
vpsubd  %ymm0, %ymm4, %ymm0
vmovdqa %ymm0, (32*\i)(%rdi)
.endm

.text
.global MLD_ASM_NAMESPACE(polyz_unpack_17_avx2_asm)
.balign 16
MLD_ASM_FN_SYMBOL(polyz_unpack_17_avx2_asm)

/* Build the 256-bit byte-shuffle constant (shufbidx) in %ymm1.
 *   Low  128: {00,01,02,FF, 02,03,04,FF, 04,05,06,FF, 06,07,08,FF}
 *   High 128: {17,18,19,FF, 19,1A,1B,FF, 1B,1C,1D,FF, 1D,1E,1F,FF} */
movabs $0xFF040302FF020100, %rax
vmovq  %rax, %xmm1
movabs $0xFF080706FF060504, %rax
vpinsrq $1, %rax, %xmm1, %xmm1
movabs $0xFF1B1A19FF191817, %rax
vmovq  %rax, %xmm5
movabs $0xFF1F1E1DFF1D1C1B, %rax
vpinsrq $1, %rax, %xmm5, %xmm5
vinserti128 $1, %xmm5, %ymm1, %ymm1

/* Build the per-lane right-shift constant (srlvdidx) = (6,4,2,0,6,4,2,0)
 * in %ymm2; the two 128-bit halves are identical. */
movabs $0x0000000200000000, %rax
vmovq  %rax, %xmm2
movabs $0x0000000600000004, %rax
vpinsrq $1, %rax, %xmm2, %xmm2
vinserti128 $1, %xmm2, %ymm2, %ymm2

/* Build the 18-bit mask (0x3FFFF) broadcast into %ymm3. */
mov $0x3FFFF, %eax
vmovd %eax, %xmm3
vpbroadcastd %xmm3, %ymm3

/* Build gamma1 = 2^17 (0x20000) broadcast into %ymm4. */
mov $0x20000, %eax
vmovd %eax, %xmm4
vpbroadcastd %xmm4, %ymm4

unpack17_block 0
unpack17_block 1
unpack17_block 2
unpack17_block 3
unpack17_block 4
unpack17_block 5
unpack17_block 6
unpack17_block 7
unpack17_block 8
unpack17_block 9
unpack17_block 10
unpack17_block 11
unpack17_block 12
unpack17_block 13
unpack17_block 14
unpack17_block 15
unpack17_block 16
unpack17_block 17
unpack17_block 18
unpack17_block 19
unpack17_block 20
unpack17_block 21
unpack17_block 22
unpack17_block 23
unpack17_block 24
unpack17_block 25
unpack17_block 26
unpack17_block 27
unpack17_block 28
unpack17_block 29
unpack17_block 30
unpack17_block 31
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && (!MLD_CONFIG_NO_SIGN_API || \
          !MLD_CONFIG_NO_VERIFY_API) && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */
