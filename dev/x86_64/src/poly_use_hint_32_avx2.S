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
 * Name:        mld_poly_use_hint
 *
 * Description: Use hint polynomial to correct the high bits of a polynomial.
 *
 * Arguments:   - mld_poly *b: pointer to output polynomial with corrected high
 *                bits
 *              - const mld_poly *a: pointer to input polynomial
 *              - const mld_poly *hint: pointer to input hint polynomial
 **************************************************/



#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87))


/* simpasm: header-end */


.text
.balign 16
.global MLD_ASM_NAMESPACE(mld_poly_use_hint_32_avx2)
MLD_ASM_FN_SYMBOL(mld_poly_use_hint_32_avx2)

movl	$127, %ecx

/* check-magic: 1025 == floor(2^22 / 4092) */
movl $1025, %r8d
vmovd %r8d, %xmm8
vpbroadcastd %xmm8, %ymm8

xorl	%eax, %eax
vpxor	%xmm6, %xmm6, %xmm6
vmovd	%ecx, %xmm5

/* 87 * ((Q-1) / 32), wrap-around threshold */
movl	$22784256, %ecx

/* round(x * 2^9 / 2^15) => round(x / 2^6), for f1 = round(f1''/ 2^6)*/
movl $512, %r9d              
vmovd %r9d, %xmm7              
vpbroadcastd %xmm7, %ymm7     

vmovd	%ecx, %xmm4
movl	$15, %ecx
vpbroadcastd	%xmm5, %ymm5
vmovd	%ecx, %xmm3
vpbroadcastd	%xmm4, %ymm4
vpbroadcastd	%xmm3, %ymm3


mld_poly_use_hint_32_avx2_loop:
vmovdqa	(%rsi,%rax), %ymm0
vmovdqa	(%rdx,%rax), %ymm2
vpaddd	%ymm0, %ymm5, %ymm1
vpcmpgtd	%ymm4, %ymm0, %ymm11
vpsrld	$7, %ymm1, %ymm1
vpmulhuw	%ymm8, %ymm1, %ymm1
vpmulhrsw	%ymm7, %ymm1, %ymm1
vpslld	$10, %ymm1, %ymm10
vpandn	%ymm1, %ymm11, %ymm9
vpsubd	%ymm1, %ymm10, %ymm1
vpslld	$9, %ymm1, %ymm1
vpsubd	%ymm1, %ymm0, %ymm0
vpaddd	%ymm11, %ymm0, %ymm0
vpcmpgtd	%ymm6, %ymm0, %ymm0
vandnps	%ymm2, %ymm0, %ymm0
vpslld	$1, %ymm0, %ymm0
vpsubd	%ymm0, %ymm2, %ymm2
vpaddd	%ymm9, %ymm2, %ymm2
vpand	%ymm3, %ymm2, %ymm2
vmovdqa	%ymm2, (%rdi,%rax)


addq	$32, %rax
cmpq	$1024, %rax
jne	mld_poly_use_hint_32_avx2_loop
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          65 || MLD_CONFIG_PARAMETER_SET == 87) */
