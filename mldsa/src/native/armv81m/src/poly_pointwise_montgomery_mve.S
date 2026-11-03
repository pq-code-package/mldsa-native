/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* Four-lane Montgomery product. No stack or callee-saved regs.
 * For |a|,|b| < 94279698, vqdmulh cannot saturate. Low32(a*b)*qinv
 * determines signed t; the two doubled high products differ by exactly
 * 2*((a*b-t*q)/2^32), so vhsub returns the C representative exactly.
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_ARMV81M) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/armv81m/src/poly_pointwise_montgomery_mve.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(poly_pointwise_montgomery_mve_asm)
MLD_ASM_FN_SYMBOL(poly_pointwise_montgomery_mve_asm)

        .cfi_startproc
        movw r2, #0x2001
        movt r2, #0x380
        movw r3, #0xe001
        movt r3, #0x7f
        mov.w r12, #0x40

Lmld_poly_pointwise_montgomery_mve_loop:
        vldrw.u32 q0, [r0]
        vldrw.u32 q1, [r1], #16
        vmul.i32 q2, q0, q1
        vmul.i32 q2, q2, r2
        vqdmulh.s32 q0, q0, q1
        vqdmulh.s32 q2, q2, r3
        vhsub.s32 q0, q0, q2
        vstrw.32 q0, [r0], #16
        subs.w r12, r12, #0x1
        bne Lmld_poly_pointwise_montgomery_mve_loop @ imm = #-0x28
        bx lr
        .cfi_endproc

MLD_ASM_FN_SIZE(poly_pointwise_montgomery_mve_asm)

#endif /* MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
