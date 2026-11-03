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
/* simpasm: header-end */
        .syntax unified
        .text
        .align 4
        .thumb
        .global MLD_ASM_NAMESPACE(poly_pointwise_montgomery_mve_asm)
MLD_ASM_FN_SYMBOL(poly_pointwise_montgomery_mve_asm)
        movw r2, #0x2001
        movt r2, #0x0380
        movw r3, #0xe001
        movt r3, #0x007f
        mov r12, #64
mld_poly_pointwise_montgomery_mve_loop:
        vldrw.s32 q0, [r0]
        vldrw.s32 q1, [r1], #16
        vmul.u32 q2, q0, q1
        vmul.u32 q2, q2, r2
        vqdmulh.s32 q0, q0, q1
        vqdmulh.s32 q2, q2, r3
        vhsub.s32 q0, q0, q2
        vstrw.s32 q0, [r0], #16
        subs r12, r12, #1
        bne mld_poly_pointwise_montgomery_mve_loop
        bx lr
MLD_ASM_FN_SIZE(poly_pointwise_montgomery_mve_asm)

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
