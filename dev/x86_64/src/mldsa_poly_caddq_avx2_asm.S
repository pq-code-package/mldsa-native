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
  Name: poly_caddq_avx2_asm
  Description: x86_64 AVX2 conditional addition of q to each coefficient.
    For all coefficients of the in/out polynomial, add Q if the coefficient
    is negative.
  Signature: void mld_poly_caddq_avx2_asm(int32_t *r)
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t *r
      description: Input/output polynomial (256 x int32_t)
*/

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/* simpasm: header-end */

.macro caddq_vector offset, reg
vpcmpgtd \offset(%rdi), %ymm2, \reg
vpand   %ymm1, \reg, \reg
vpaddd  \offset(%rdi), \reg, \reg
vmovdqa  \reg, \offset(%rdi)
.endm

.text
.global MLD_ASM_NAMESPACE(poly_caddq_avx2_asm)
.balign 16
MLD_ASM_FN_SYMBOL(poly_caddq_avx2_asm)

vpxor %xmm2, %xmm2, %xmm2
mov $8380417, %eax
vmovd %eax, %xmm1
vpbroadcastd %xmm1, %ymm1

caddq_vector 0, %ymm0
caddq_vector 32, %ymm3
caddq_vector 64, %ymm4
caddq_vector 96, %ymm5
caddq_vector 128, %ymm0
caddq_vector 160, %ymm3
caddq_vector 192, %ymm4
caddq_vector 224, %ymm5
caddq_vector 256, %ymm0
caddq_vector 288, %ymm3
caddq_vector 320, %ymm4
caddq_vector 352, %ymm5
caddq_vector 384, %ymm0
caddq_vector 416, %ymm3
caddq_vector 448, %ymm4
caddq_vector 480, %ymm5
caddq_vector 512, %ymm0
caddq_vector 544, %ymm3
caddq_vector 576, %ymm4
caddq_vector 608, %ymm5
caddq_vector 640, %ymm0
caddq_vector 672, %ymm3
caddq_vector 704, %ymm4
caddq_vector 736, %ymm5
caddq_vector 768, %ymm0
caddq_vector 800, %ymm3
caddq_vector 832, %ymm4
caddq_vector 864, %ymm5
caddq_vector 896, %ymm0
caddq_vector 928, %ymm3
caddq_vector 960, %ymm4
caddq_vector 992, %ymm5
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
