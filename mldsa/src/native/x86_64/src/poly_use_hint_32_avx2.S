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



/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/x86_64/src/poly_use_hint_32_avx2.S using scripts/simpasm. Do not modify it directly.
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

.text
.balign 4
.global MLD_ASM_NAMESPACE(mld_poly_use_hint_32_avx2)
MLD_ASM_FN_SYMBOL(mld_poly_use_hint_32_avx2)

        .cfi_startproc
        movl	$0x7f, %ecx
        movl	$0x401, %r8d            # imm = 0x401
        vmovd	%r8d, %xmm8
        vpbroadcastd	%xmm8, %ymm8
        xorl	%eax, %eax
        vpxor	%xmm6, %xmm6, %xmm6
        vmovd	%ecx, %xmm5
        movl	$0x15ba900, %ecx        # imm = 0x15BA900
        movl	$0x200, %r9d            # imm = 0x200
        vmovd	%r9d, %xmm7
        vpbroadcastd	%xmm7, %ymm7
        vmovd	%ecx, %xmm4
        movl	$0xf, %ecx
        vpbroadcastd	%xmm5, %ymm5
        vmovd	%ecx, %xmm3
        vpbroadcastd	%xmm4, %ymm4
        vpbroadcastd	%xmm3, %ymm3

Lmld_poly_use_hint_32_avx2_loop:
        vmovdqa	(%rsi,%rax), %ymm0
        vmovdqa	(%rdx,%rax), %ymm2
        vpaddd	%ymm0, %ymm5, %ymm1
        vpsrld	$0x7, %ymm1, %ymm1
        vpmulhuw	%ymm8, %ymm1, %ymm1
        vpmulhrsw	%ymm7, %ymm1, %ymm1
        vpcmpgtd	%ymm4, %ymm0, %ymm11
        vpandn	%ymm1, %ymm11, %ymm9
        vpslld	$0xa, %ymm1, %ymm10
        vpsubd	%ymm1, %ymm10, %ymm1
        vpslld	$0x9, %ymm1, %ymm1
        vpsubd	%ymm1, %ymm0, %ymm0
        vpaddd	%ymm11, %ymm0, %ymm0
        vpcmpgtd	%ymm6, %ymm0, %ymm0
        vpandn	%ymm2, %ymm0, %ymm0
        vpslld	$0x1, %ymm0, %ymm0
        vpsubd	%ymm0, %ymm2, %ymm2
        vpaddd	%ymm9, %ymm2, %ymm2
        vpand	%ymm3, %ymm2, %ymm2
        vmovdqa	%ymm2, (%rdi,%rax)
        addq	$0x20, %rax
        cmpq	$0x400, %rax            # imm = 0x400
        jne	Lmld_poly_use_hint_32_avx2_loop
        retq
        .cfi_endproc

MLD_ASM_FN_SIZE(mld_poly_use_hint_32_avx2)


#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          65 || MLD_CONFIG_PARAMETER_SET == 87) */
