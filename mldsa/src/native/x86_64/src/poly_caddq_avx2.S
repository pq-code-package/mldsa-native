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


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/x86_64/src/poly_caddq_avx2.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(poly_caddq_avx2)
MLD_ASM_FN_SYMBOL(poly_caddq_avx2)

        .cfi_startproc
        movl	$0x7fe001, %edx         # imm = 0x7FE001
        leaq	0x400(%rdi), %rax
        vpxor	%xmm2, %xmm2, %xmm2
        vmovd	%edx, %xmm1
        vpbroadcastd	%xmm1, %ymm1

Lpoly_caddq_avx2_loop:
        vpcmpgtd	(%rdi), %ymm2, %ymm0
        vpand	%ymm1, %ymm0, %ymm0
        vpaddd	(%rdi), %ymm0, %ymm0
        vmovdqa	%ymm0, (%rdi)
        vpcmpgtd	0x20(%rdi), %ymm2, %ymm3
        vpand	%ymm1, %ymm3, %ymm3
        vpaddd	0x20(%rdi), %ymm3, %ymm3
        vmovdqa	%ymm3, 0x20(%rdi)
        vpcmpgtd	0x40(%rdi), %ymm2, %ymm4
        vpand	%ymm1, %ymm4, %ymm4
        vpaddd	0x40(%rdi), %ymm4, %ymm4
        vmovdqa	%ymm4, 0x40(%rdi)
        vpcmpgtd	0x60(%rdi), %ymm2, %ymm5
        vpand	%ymm1, %ymm5, %ymm5
        vpaddd	0x60(%rdi), %ymm5, %ymm5
        vmovdqa	%ymm5, 0x60(%rdi)
        addq	$0x80, %rdi
        cmpq	%rdi, %rax
        jne	Lpoly_caddq_avx2_loop
        retq
        .cfi_endproc

MLD_ASM_FN_SIZE(poly_caddq_avx2)


#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
