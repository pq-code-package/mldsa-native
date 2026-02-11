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

/* Reference:
 * - @[REF_AVX2] calls poly_decompose to compute all a1, a0 before the loop.
 * - Our implementation of decompose() is slightly different from that in
 *   @[REF_AVX2]. See poly_decompose_32_avx2 for more information.
 */

// a aliased with a0
.macro decompose32_avx2 a1, a, temp1, temp2, temp3
// Compute a1 = round-(a / 523776) ≈ round(a * 1074791425 /
// 2^49), where round-() denotes "round half down". This is
// exact for 0 <= a < Q. Note that half is rounded down since
// 1074791425 / 2^49 ≲ 1 / 523776.
vpaddd	\a, %ymm5,  \temp1        
vpsrld	$7, \temp1, \temp1       
vpmulhuw	%ymm8, \temp1, \temp1    
vpmulhrsw	%ymm7, \temp1, \temp1   

// If a1 = 16, i.e. a > 31*GAMMA2, proceed as if a' = a - Q was
// given instead. (For a = 31*GAMMA2 + 1 thus a' = -GAMMA2, we
// still round it to 0 like other "wrapped around" cases.)

// Check for wrap-around
vpcmpgtd	%ymm4, \a, \temp2    
vpandn	\temp1, \temp2, \a1      

// Compute remainder a0
vpslld	$10, \temp1, \temp3      
vpsubd	\temp1, \temp3, \temp1   
vpslld	$9, \temp1, \temp1       
vpsubd	\temp1, \a, \a  

// check if wrap-around is required
vpaddd	\temp2, \a, \a
.endm

/* Reference: The reference avx2 implementation checks a0 >= 0, which is
 * different from the specification and the reference C implementation. We
 * follow the specification and check a0 > 0.
 */

// a aliased with delta
.macro use_hint32_avx2 b, a, h, a1, temp1, temp2, temp3
decompose32_avx2 \a1, \a, \temp1, \temp2, \temp3

// delta = (a0 <= 0) ? -1 : 1
vpcmpgtd	%ymm6, \a, \a            
vpandn	\h, \a, \a               
vpslld	$1, \a, \a               
vpsubd	\a, \h, \h               

// b = (b + delta * h) % 16
vpaddd	\a1, \h, \b              
vpand	%ymm3, \b, \b            
.endm

.text
.balign 16
.global MLD_ASM_NAMESPACE(mld_poly_use_hint_32_avx2)
MLD_ASM_FN_SYMBOL(mld_poly_use_hint_32_avx2)

// Initialize constants
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

use_hint32_avx2 %ymm2, %ymm0, %ymm2, %ymm9, %ymm1, %ymm11, %ymm10

vmovdqa	%ymm2, (%rdi,%rax)
addq	$32, %rax
cmpq	$1024, %rax
jne	mld_poly_use_hint_32_avx2_loop
ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          65 || MLD_CONFIG_PARAMETER_SET == 87) */
