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


/*************************************************
 * Name:        mld_poly_chknorm_avx2_asm
 *
 * Description: Check infinity norm of polynomial against given bound.
 *              Returns 0 if norm is strictly smaller than B; otherwise
 *              returns 1.
 *
 * Arguments:   - const int32_t *a: pointer to input polynomial
 *              - int32_t B:  bound
 *
 * Returns:     - 1 if any |coefficient| >= B, 0 otherwise.
 **************************************************/

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/* simpasm: header-end */

.macro chknorm_vector offset, reg
vpabsd  \offset(%rdi), \reg
vpcmpgtd %ymm2, \reg, \reg
vpor    \reg, %ymm1, %ymm1
.endm

.text
.global MLD_ASM_NAMESPACE(poly_chknorm_avx2_asm)
.balign 16
MLD_ASM_FN_SYMBOL(poly_chknorm_avx2_asm)

subl    $1, %esi
vpxor   %xmm1, %xmm1, %xmm1
vmovd   %esi, %xmm2
vpbroadcastd %xmm2, %ymm2

chknorm_vector 0,    %ymm0
chknorm_vector 32,   %ymm3
chknorm_vector 64,   %ymm4
chknorm_vector 96,   %ymm5
chknorm_vector 128,  %ymm0
chknorm_vector 160,  %ymm3
chknorm_vector 192,  %ymm4
chknorm_vector 224,  %ymm5
chknorm_vector 256,  %ymm0
chknorm_vector 288,  %ymm3
chknorm_vector 320,  %ymm4
chknorm_vector 352,  %ymm5
chknorm_vector 384,  %ymm0
chknorm_vector 416,  %ymm3
chknorm_vector 448,  %ymm4
chknorm_vector 480,  %ymm5
chknorm_vector 512,  %ymm0
chknorm_vector 544,  %ymm3
chknorm_vector 576,  %ymm4
chknorm_vector 608,  %ymm5
chknorm_vector 640,  %ymm0
chknorm_vector 672,  %ymm3
chknorm_vector 704,  %ymm4
chknorm_vector 736,  %ymm5
chknorm_vector 768,  %ymm0
chknorm_vector 800,  %ymm3
chknorm_vector 832,  %ymm4
chknorm_vector 864,  %ymm5
chknorm_vector 896,  %ymm0
chknorm_vector 928,  %ymm3
chknorm_vector 960,  %ymm4
chknorm_vector 992,  %ymm5

xorl    %eax, %eax
vptest  %ymm1, %ymm1
setne   %al
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
