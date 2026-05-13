/*
 * Copyright (c) 2024 Jipeng Zhang and the PQRV authors
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: MIT
 */

/*
 * Forward NTT for ML-DSA on RV32IM.
 *
 * The kernel and supporting macros are derived from the
 * `ntt_8l_singleissue_mont_rv32im.S` kernel in the PQRV repository at
 * https://github.com/Ji-Peng/PQRV/blob/87440598d6cbd83e3c0471298ebde533c8ab885b/ntt/dilithium/ntt_8l_singleissue_mont_rv32im.S
 *
 * The kernel implements a 3+3+2 layer-merging strategy for the 8-layer
 * forward NTT. It expects a precomputed zeta table laid out as
 * (zeta, low(zeta * qinv)) pairs in signed Montgomery form; see
 * scripts/autogen for the exact layout.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv32/src/ntt_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(ntt_rv32im_asm)
MLD_ASM_FN_SYMBOL(ntt_rv32im_asm)

        .cfi_startproc
        addi sp, sp, -0x3c
        .cfi_adjust_cfa_offset 0x3c
        sw s0, 0x0(sp)
        sw s1, 0x4(sp)
        sw s2, 0x8(sp)
        sw s3, 0xc(sp)
        sw s4, 0x10(sp)
        sw s5, 0x14(sp)
        sw s6, 0x18(sp)
        sw s7, 0x1c(sp)
        sw s8, 0x20(sp)
        sw s9, 0x24(sp)
        sw s10, 0x28(sp)
        sw s11, 0x2c(sp)
        sw gp, 0x30(sp)
        sw tp, 0x34(sp)
        sw ra, 0x38(sp)
        lui a6, 0x7fe
        addi a6, a6, 0x1
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        lw s6, 0x18(a1)
        lw s7, 0x1c(a1)
        lw s8, 0x20(a1)
        lw s9, 0x24(a1)
        lw s10, 0x28(a1)
        lw s11, 0x2c(a1)
        lw gp, 0x30(a1)
        lw ra, 0x34(a1)
        addi a4, a0, 0x80

Lntt_rv32im_looper_123:
        lw t0, 0x0(a0)
        lw t1, 0x80(a0)
        lw t2, 0x100(a0)
        lw t3, 0x180(a0)
        lw t4, 0x200(a0)
        lw t5, 0x280(a0)
        lw t6, 0x300(a0)
        lw tp, 0x380(a0)
        mul a2, t4, s1
        mulh a3, t4, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t4, t0, a2
        add t0, t0, a2
        mul a2, t5, s1
        mulh a3, t5, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t5, t1, a2
        add t1, t1, a2
        mul a2, t6, s1
        mulh a3, t6, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t6, t2, a2
        add t2, t2, a2
        mul a2, tp, s1
        mulh a3, tp, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t3, a2
        add t3, t3, a2
        mul a2, t2, s3
        mulh a3, t2, s2
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t2, t0, a2
        add t0, t0, a2
        mul a2, t3, s3
        mulh a3, t3, s2
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t1, a2
        add t1, t1, a2
        mul a2, t6, s5
        mulh a3, t6, s4
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t6, t4, a2
        add t4, t4, a2
        mul a2, tp, s5
        mulh a3, tp, s4
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t5, a2
        add t5, t5, a2
        mul a2, t1, s7
        mulh a3, t1, s6
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t1, t0, a2
        add t0, t0, a2
        mul a2, t3, s9
        mulh a3, t3, s8
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t2, a2
        add t2, t2, a2
        mul a2, t5, s11
        mulh a3, t5, s10
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t5, t4, a2
        add t4, t4, a2
        mul a2, tp, ra
        mulh a3, tp, gp
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t6, a2
        add t6, t6, a2
        sw t0, 0x0(a0)
        sw t1, 0x80(a0)
        sw t2, 0x100(a0)
        sw t3, 0x180(a0)
        sw t4, 0x200(a0)
        sw t5, 0x280(a0)
        sw t6, 0x300(a0)
        sw tp, 0x380(a0)
        addi a0, a0, 0x4
        bne a4, a0, Lntt_rv32im_looper_123
        addi a0, a0, -0x80
        addi a1, a1, 0x38
        addi a5, a1, 0x1c0

Lntt_rv32im_outer_456:
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        lw s6, 0x18(a1)
        lw s7, 0x1c(a1)
        lw s8, 0x20(a1)
        lw s9, 0x24(a1)
        lw s10, 0x28(a1)
        lw s11, 0x2c(a1)
        lw gp, 0x30(a1)
        lw ra, 0x34(a1)
        addi a4, a0, 0x10

Lntt_rv32im_inner_456:
        lw t0, 0x0(a0)
        lw t1, 0x10(a0)
        lw t2, 0x20(a0)
        lw t3, 0x30(a0)
        lw t4, 0x40(a0)
        lw t5, 0x50(a0)
        lw t6, 0x60(a0)
        lw tp, 0x70(a0)
        mul a2, t4, s1
        mulh a3, t4, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t4, t0, a2
        add t0, t0, a2
        mul a2, t5, s1
        mulh a3, t5, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t5, t1, a2
        add t1, t1, a2
        mul a2, t6, s1
        mulh a3, t6, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t6, t2, a2
        add t2, t2, a2
        mul a2, tp, s1
        mulh a3, tp, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t3, a2
        add t3, t3, a2
        mul a2, t2, s3
        mulh a3, t2, s2
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t2, t0, a2
        add t0, t0, a2
        mul a2, t3, s3
        mulh a3, t3, s2
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t1, a2
        add t1, t1, a2
        mul a2, t6, s5
        mulh a3, t6, s4
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t6, t4, a2
        add t4, t4, a2
        mul a2, tp, s5
        mulh a3, tp, s4
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t5, a2
        add t5, t5, a2
        mul a2, t1, s7
        mulh a3, t1, s6
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t1, t0, a2
        add t0, t0, a2
        mul a2, t3, s9
        mulh a3, t3, s8
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t2, a2
        add t2, t2, a2
        mul a2, t5, s11
        mulh a3, t5, s10
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t5, t4, a2
        add t4, t4, a2
        mul a2, tp, ra
        mulh a3, tp, gp
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t6, a2
        add t6, t6, a2
        sw t0, 0x0(a0)
        sw t1, 0x10(a0)
        sw t2, 0x20(a0)
        sw t3, 0x30(a0)
        sw t4, 0x40(a0)
        sw t5, 0x50(a0)
        sw t6, 0x60(a0)
        sw tp, 0x70(a0)
        addi a0, a0, 0x4
        bne a4, a0, Lntt_rv32im_inner_456
        addi a0, a0, 0x70
        addi a1, a1, 0x38
        bne a5, a1, Lntt_rv32im_outer_456
        addi a0, a0, -0x400
        addi a4, a0, 0x400

Lntt_rv32im_looper_78:
        lw t0, 0x0(a0)
        lw t1, 0x4(a0)
        lw t2, 0x8(a0)
        lw t3, 0xc(a0)
        lw t4, 0x10(a0)
        lw t5, 0x14(a0)
        lw t6, 0x18(a0)
        lw tp, 0x1c(a0)
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        lw s6, 0x18(a1)
        lw s7, 0x1c(a1)
        lw s8, 0x20(a1)
        lw s9, 0x24(a1)
        lw s10, 0x28(a1)
        lw s11, 0x2c(a1)
        mul a2, t2, s1
        mulh a3, t2, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t2, t0, a2
        add t0, t0, a2
        mul a2, t3, s1
        mulh a3, t3, s0
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t1, a2
        add t1, t1, a2
        mul a2, t1, s3
        mulh a3, t1, s2
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t1, t0, a2
        add t0, t0, a2
        mul a2, t3, s5
        mulh a3, t3, s4
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t3, t2, a2
        add t2, t2, a2
        mul a2, t6, s7
        mulh a3, t6, s6
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t6, t4, a2
        add t4, t4, a2
        mul a2, tp, s7
        mulh a3, tp, s6
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t5, a2
        add t5, t5, a2
        mul a2, t5, s9
        mulh a3, t5, s8
        mulh a2, a2, a6
        sub a2, a3, a2
        sub t5, t4, a2
        add t4, t4, a2
        mul a2, tp, s11
        mulh a3, tp, s10
        mulh a2, a2, a6
        sub a2, a3, a2
        sub tp, t6, a2
        add t6, t6, a2
        sw t0, 0x0(a0)
        sw t1, 0x4(a0)
        sw t2, 0x8(a0)
        sw t3, 0xc(a0)
        sw t4, 0x10(a0)
        sw t5, 0x14(a0)
        sw t6, 0x18(a0)
        sw tp, 0x1c(a0)
        addi a0, a0, 0x20
        addi a1, a1, 0x30
        bne a4, a0, Lntt_rv32im_looper_78
        lw s0, 0x0(sp)
        lw s1, 0x4(sp)
        lw s2, 0x8(sp)
        lw s3, 0xc(sp)
        lw s4, 0x10(sp)
        lw s5, 0x14(sp)
        lw s6, 0x18(sp)
        lw s7, 0x1c(sp)
        lw s8, 0x20(sp)
        lw s9, 0x24(sp)
        lw s10, 0x28(sp)
        lw s11, 0x2c(sp)
        lw gp, 0x30(sp)
        lw tp, 0x34(sp)
        lw ra, 0x38(sp)
        addi sp, sp, 0x3c
        .cfi_adjust_cfa_offset -0x3c
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(ntt_rv32im_asm)

#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
