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

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/x86_64/src/poly_use_hint_88_avx2.S using scripts/simpasm. Do not modify it directly.
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

.text
.balign 4
.global MLD_ASM_NAMESPACE(mld_poly_use_hint_88_avx2)  
MLD_ASM_FN_SYMBOL(mld_poly_use_hint_88_avx2)  

        .cfi_startproc
        movl	$0x7f, %ecx
        xorl	%eax, %eax
        vpxor	%xmm5, %xmm5, %xmm5
        movl	$0x2c0b, %r8d           # imm = 0x2C0B
        vmovd	%r8d, %xmm8
        vpbroadcastd	%xmm8, %ymm8
        vmovd	%ecx, %xmm4
        movl	$0x7e6c00, %ecx         # imm = 0x7E6C00
        movl	$0x80, %r9d
        vmovd	%r9d, %xmm7
        vpbroadcastd	%xmm7, %ymm7
        movl	$0x2b, %r10d
        vmovd	%r10d, %xmm6
        vpbroadcastd	%xmm6, %ymm6
        vmovd	%ecx, %xmm3
        vpbroadcastd	%xmm4, %ymm4
        vpbroadcastd	%xmm3, %ymm3

Lmld_poly_use_hint_88_avx2_loop:
        vmovdqa	(%rsi,%rax), %ymm0
        vmovdqa	(%rdx,%rax), %ymm1
        vpaddd	%ymm0, %ymm4, %ymm10
        vpcmpgtd	%ymm3, %ymm0, %ymm11
        vpsrld	$0x7, %ymm10, %ymm10
        vpmulhuw	%ymm8, %ymm10, %ymm10
        vpmulhrsw	%ymm7, %ymm10, %ymm10
        vpslld	$0x1, %ymm10, %ymm12
        vpandn	%ymm10, %ymm11, %ymm9
        vpaddd	%ymm10, %ymm12, %ymm12
        vpslld	$0x5, %ymm12, %ymm10
        vpsubd	%ymm12, %ymm10, %ymm10
        vpslld	$0xb, %ymm10, %ymm10
        vpsubd	%ymm10, %ymm0, %ymm0
        vpaddd	%ymm11, %ymm0, %ymm0
        vpcmpgtd	%ymm5, %ymm0, %ymm0
        vandnps	%ymm1, %ymm0, %ymm0
        vpslld	$0x1, %ymm0, %ymm0
        vpsubd	%ymm0, %ymm1, %ymm0
        vpaddd	%ymm9, %ymm0, %ymm0
        vblendvps	%ymm0, %ymm6, %ymm0, %ymm0
        vpcmpgtd	%ymm6, %ymm0, %ymm1
        vpandn	%ymm0, %ymm1, %ymm0
        vmovdqa	%ymm0, (%rdi,%rax)
        addq	$0x20, %rax
        cmpq	$0x400, %rax            # imm = 0x400
        jne	Lmld_poly_use_hint_88_avx2_loop
        retq
        .cfi_endproc

MLD_ASM_FN_SIZE(mld_poly_use_hint_88_avx2)  


#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          44) */

