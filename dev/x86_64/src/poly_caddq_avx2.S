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
 * Name:        mld_poly_caddq_avx2
 *
 * Description: For all coefficients of in/out polynomial add Q if
 *              coefficient is negative.
 *
 * Arguments:   - int32_t *r: pointer to input/output polynomial
 **************************************************/

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
.global MLD_ASM_NAMESPACE(poly_caddq_avx2)
.balign 16
MLD_ASM_FN_SYMBOL(poly_caddq_avx2)

mov $8380417, %edx
leaq 1024(%rdi), %rax
vpxor %xmm2, %xmm2, %xmm2
vmovd %edx, %xmm1
vpbroadcastd %xmm1, %ymm1

poly_caddq_avx2_loop:

caddq_vector 0, %ymm0
caddq_vector 32, %ymm3
caddq_vector 64, %ymm4
caddq_vector 96, %ymm5

addq   $128, %rdi        /* advance by 128 bytes (4 vectors) */ 
cmpq   %rdi, %rax
jne    poly_caddq_avx2_loop   /* 8 iterations (32/4 = 8) */ 
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
