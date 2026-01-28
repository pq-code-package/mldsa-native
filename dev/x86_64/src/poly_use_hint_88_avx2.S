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
    MLD_CONFIG_PARAMETER_SET == 44)
/* simpasm: header-end */

/* Reference:
 * - @[REF_AVX2] calls poly_decompose to compute all a1, a0 before the loop.
 * - Our implementation of decompose() is slightly different from that in
 *   @[REF_AVX2]. See poly_decompose_88_avx2.c for more information.
 */

// a aliased with a0
.macro decompose88_avx2 a1, a, temp1, temp2, temp3
// Compute a1 = round-(a / 190464) ≈ round(a * 1477838209 /
// 2^48), where round-() denotes "round half down". This is
// exact for 0 <= a < Q. Note that half is rounded down since
// 1477838209 / 2^48 ≲ 1 / 190464.
vpaddd	\a, %ymm4, \temp1        
vpsrld	$7, \temp1, \temp1       
vpmulhuw	%ymm8, \temp1, \temp1    
vpmulhrsw	%ymm7, \temp1, \temp1   

// If a1 = 44, i.e. a > 87*GAMMA2, proceed as if a' = a - Q was
// given instead. (For a = 87*GAMMA2 + 1 thus a' = -GAMMA2, we
// still round it to 0 like other "wrapped around" cases.)

// Check for wrap-around
vpcmpgtd	%ymm3, \a, \temp2    
vpandn	\temp1, \temp2, \a1      

// Compute remainder a0
vpslld	$1, \temp1, \temp3       
vpaddd	\temp1, \temp3, \temp3   
vpslld	$5, \temp3, \temp1       
vpsubd	\temp3, \temp1, \temp1   
vpslld	$11, \temp1, \temp1      
vpsubd	\temp1, \a, \a           

// check if wrap-around is required
vpaddd	\temp2, \a, \a           
.endm

/* Reference: The reference avx2 implementation checks a0 >= 0, which is
 * different from the specification and the reference C implementation. We
 * follow the specification and check a0 > 0.
 */

// a aliased with delta
.macro use_hint88_avx2 b, a, h, a1, temp1, temp2, temp3
decompose88_avx2 \a1, \a, \temp1, \temp2, \temp3

// delta = (a0 <= 0) ? -1 : 1
vpcmpgtd	%ymm5, \a, \a            
vpandn	\h, \a, \a               
vpslld	$1, \a, \a               
vpsubd	\a, \h, \a               

// b = (b + delta * h) % 44
vpaddd	\a1, \a, \b              
vblendvps	\b, %ymm6, \b, \b    
vpcmpgtd	%ymm6, \b, \h            
vpandn	\b, \h, \b               
.endm

.text
.balign 16
.global MLD_ASM_NAMESPACE(mld_poly_use_hint_88_avx2)  
MLD_ASM_FN_SYMBOL(mld_poly_use_hint_88_avx2)

movl	$127, %ecx
xorl	%eax, %eax
vpxor	%xmm5, %xmm5, %xmm5

/* check-magic: 11275 == floor(2^24 / 1488) */
movl $11275, %r8d
vmovd %r8d, %xmm8
vpbroadcastd %xmm8, %ymm8

vmovd	%ecx, %xmm4

/* 87 * ((Q-1) / 88), wrap-around threshold */
movl	$8285184, %ecx

/* round(x * 2^7 / 2^15) => round(x / 2^8), for f1 = round(f1''/ 2^8)*/
movl $128, %r9d
vmovd %r9d, %xmm7
vpbroadcastd %xmm7, %ymm7

 /* max a1 value */
movl $43, %r10d
vmovd %r10d, %xmm6
vpbroadcastd %xmm6, %ymm6

vmovd	%ecx, %xmm3
vpbroadcastd	%xmm4, %ymm4
vpbroadcastd	%xmm3, %ymm3

mld_poly_use_hint_88_avx2_loop:
vmovdqa	(%rsi,%rax), %ymm0
vmovdqa	(%rdx,%rax), %ymm1
vpaddd	%ymm0, %ymm4, %ymm10
vpcmpgtd	%ymm3, %ymm0, %ymm11
vpsrld	$7, %ymm10, %ymm10
vpmulhuw	%ymm8, %ymm10, %ymm10
vpmulhrsw	%ymm7, %ymm10, %ymm10
vpslld	$1, %ymm10, %ymm12
vpandn	%ymm10, %ymm11, %ymm9
vpaddd	%ymm10, %ymm12, %ymm12
vpslld	$5, %ymm12, %ymm10
vpsubd	%ymm12, %ymm10, %ymm10
vpslld	$11, %ymm10, %ymm10
vpsubd	%ymm10, %ymm0, %ymm0
vpaddd	%ymm11, %ymm0, %ymm0
vpcmpgtd	%ymm5, %ymm0, %ymm0
vandnps	%ymm1, %ymm0, %ymm0
vpslld	$1, %ymm0, %ymm0
vpsubd	%ymm0, %ymm1, %ymm0
vpaddd	%ymm9, %ymm0, %ymm0
vblendvps	%ymm0, %ymm6, %ymm0, %ymm0
vpcmpgtd	%ymm2, %ymm0, %ymm1
vandnps	%ymm0, %ymm1, %ymm0
vmovaps	%ymm0, (%rdi,%rax)


addq	$32, %rax
cmpq	$1024, %rax
jne	mld_poly_use_hint_88_avx2_loop

ret

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          44) */

