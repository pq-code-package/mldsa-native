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
  Name: polyz_unpack_19_avx2_asm
  Description: x86_64 AVX2 unpacking of 19-bit packed coefficients.
    Unpack polynomial z with 20-bit packed coefficients (GAMMA1 = 2^19),
    mapping packed [0, 2^20-1] to signed [-(2^19-1), 2^19] via GAMMA1 - x.
  Signature: void mld_polyz_unpack_19_avx2_asm(int32_t *r, const uint8_t *a)
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
      size_bytes: 640
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
     (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87))

/* simpasm: header-end */

/* Unpack one block of 8 coefficients (20 packed input bytes -> 8 x int32).
 *
 * Load bytes [20i .. 20i+15] into the low 128-bit half and [20i+4 .. 20i+19]
 * into the high 128-bit half, then replicate the AVX2 intrinsic pipeline:
 * byte shuffle, per-lane variable right shift, mask to 20 bits, and
 * gamma1 - x. */
.macro unpack19_block i
vmovdqu (20*\i)(%rsi), %xmm0
vmovdqu (20*\i + 4)(%rsi), %xmm5
vinserti128 $1, %xmm5, %ymm0, %ymm0
vpshufb %ymm1, %ymm0, %ymm0
vpsrlvd %ymm2, %ymm0, %ymm0
vpand   %ymm3, %ymm0, %ymm0
vpsubd  %ymm0, %ymm4, %ymm0
vmovdqa %ymm0, (32*\i)(%rdi)
.endm

.text
.global MLD_ASM_NAMESPACE(polyz_unpack_19_avx2_asm)
.balign 16
MLD_ASM_FN_SYMBOL(polyz_unpack_19_avx2_asm)

/* Build the 256-bit byte-shuffle constant (shufbidx) in %ymm1.
 *   Low  128: {00,01,02,FF, 02,03,04,FF, 05,06,07,FF, 07,08,09,FF}
 *   High 128: {16,17,18,FF, 18,19,1A,FF, 1B,1C,1D,FF, 1D,1E,1F,FF} */
movabs $0xFF040302FF020100, %rax
vmovq  %rax, %xmm1
movabs $0xFF090807FF070605, %rax
vpinsrq $1, %rax, %xmm1, %xmm1
movabs $0xFF1A1918FF181716, %rax
vmovq  %rax, %xmm5
movabs $0xFF1F1E1DFF1D1C1B, %rax
vpinsrq $1, %rax, %xmm5, %xmm5
vinserti128 $1, %xmm5, %ymm1, %ymm1

/* Build the per-lane right-shift constant (srlvdidx) = (4,0,4,0,4,0,4,0)
 * in %ymm2; the two 128-bit halves are identical. */
movabs $0x0000000400000000, %rax
vmovq  %rax, %xmm2
movabs $0x0000000400000000, %rax
vpinsrq $1, %rax, %xmm2, %xmm2
vinserti128 $1, %xmm2, %ymm2, %ymm2

/* Build the 20-bit mask (0xFFFFF) broadcast into %ymm3. */
mov $0xFFFFF, %eax
vmovd %eax, %xmm3
vpbroadcastd %xmm3, %ymm3

/* Build gamma1 = 2^19 (0x80000) broadcast into %ymm4. */
mov $0x80000, %eax
vmovd %eax, %xmm4
vpbroadcastd %xmm4, %ymm4

unpack19_block 0
unpack19_block 1
unpack19_block 2
unpack19_block 3
unpack19_block 4
unpack19_block 5
unpack19_block 6
unpack19_block 7
unpack19_block 8
unpack19_block 9
unpack19_block 10
unpack19_block 11
unpack19_block 12
unpack19_block 13
unpack19_block 14
unpack19_block 15
unpack19_block 16
unpack19_block 17
unpack19_block 18
unpack19_block 19
unpack19_block 20
unpack19_block 21
unpack19_block 22
unpack19_block 23
unpack19_block 24
unpack19_block 25
unpack19_block 26
unpack19_block 27
unpack19_block 28
unpack19_block 29
unpack19_block 30
unpack19_block 31
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && (!MLD_CONFIG_NO_SIGN_API || \
          !MLD_CONFIG_NO_VERIFY_API) && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87) */
