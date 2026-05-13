/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA pointwise polynomial multiplication with Montgomery
 * reduction. Computes
 *
 *     a[i] = (a[i] * b[i]) * R^-1  mod q,    R = 2^32, |result| < q,
 *
 * for i in 0..256, in-place in a.
 *
 * Modular arithmetic: standard signed Montgomery reduction. Unlike the
 * NTT, neither operand is constant, so we can't precompute a twisted
 * form -- the kernel uses 4 multiplies per coefficient:
 *
 *     plo = low (a * b)            ; mul
 *     m   = low (plo * QINV)       ; mul (low 32 of (plo * QINV))
 *     phi = high(a * b)            ; mulh
 *     mh  = high(m * q)            ; mulh
 *     r   = phi - mh               ; sub
 *
 * Bounds: requires |a[i]|, |b[i]| < MLD_NTT_BOUND = 9*q. The product
 * is bounded by (9q)^2 < 2^31 * q, well within the safe input range
 * for `mld_montgomery_reduce` (which is |a| <= 2^31 * q).
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv32/src/poly_pointwise_montgomery_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(poly_pointwise_montgomery_rv32im_asm)
MLD_ASM_FN_SYMBOL(poly_pointwise_montgomery_rv32im_asm)

        .cfi_startproc
        addi sp, sp, -0x8
        .cfi_adjust_cfa_offset 0x8
        sw s0, 0x0(sp)
        sw s1, 0x4(sp)
        lui s0, 0x7fe
        addi s0, s0, 0x1
        lui s1, 0x3802
        addi s1, s1, 0x1
        addi t0, a0, 0x400

Lpoly_pointwise_montgomery_rv32im_loop:
        lw a2, 0x0(a0)
        lw a3, 0x0(a1)
        mul a4, a2, a3
        mul a6, a4, s1
        mulh a5, a2, a3
        mulh a7, a6, s0
        sub a2, a5, a7
        sw a2, 0x0(a0)
        addi a0, a0, 0x4
        addi a1, a1, 0x4
        bne a0, t0, Lpoly_pointwise_montgomery_rv32im_loop
        lw s0, 0x0(sp)
        lw s1, 0x4(sp)
        addi sp, sp, 0x8
        .cfi_adjust_cfa_offset -0x8
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(poly_pointwise_montgomery_rv32im_asm)

#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
