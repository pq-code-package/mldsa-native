/*
 * Copyright (c) 2024 Jipeng Zhang and the PQRV authors
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: MIT
 */

/*
 * Inverse NTT for ML-DSA on RV32IM.
 *
 * Derived from the `intt_8l_rv32im` kernel of
 * `ntt_8l_singleissue_mont_rv32im.S` in the PQRV repository at
 * https://github.com/Ji-Peng/PQRV/blob/87440598d6cbd83e3c0471298ebde533c8ab885b/ntt/dilithium/ntt_8l_singleissue_mont_rv32im.S
 *
 * The kernel implements a 2+3+3 layer-merging strategy for the 8-layer
 * inverse NTT and folds the final 1/256 scaling so that only the four
 * coefficients in the high half of the last layer-8 butterfly need an
 * extra `montmul_inplace`. The zeta table is laid out as
 * (zeta, low(zeta * qinv)) pairs (matching the forward table); see
 * scripts/autogen for the exact layout.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv32/src/intt_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(intt_rv32im_asm)
MLD_ASM_FN_SYMBOL(intt_rv32im_asm)

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
        addi a4, a0, 0x400

Lintt_rv32im_looper_12:
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
        sub a2, t0, t1
        add t0, t0, t1
        mul t1, a2, s1
        mulh a3, a2, s0
        mulh t1, t1, a6
        sub t1, a3, t1
        sub a2, t2, t3
        add t2, t2, t3
        mul t3, a2, s3
        mulh a3, a2, s2
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t0, t2
        add t0, t0, t2
        mul t2, a2, s5
        mulh a3, a2, s4
        mulh t2, t2, a6
        sub t2, a3, t2
        sub a2, t1, t3
        add t1, t1, t3
        mul t3, a2, s5
        mulh a3, a2, s4
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t4, t5
        add t4, t4, t5
        mul t5, a2, s7
        mulh a3, a2, s6
        mulh t5, t5, a6
        sub t5, a3, t5
        sub a2, t6, tp
        add t6, t6, tp
        mul tp, a2, s9
        mulh a3, a2, s8
        mulh tp, tp, a6
        sub tp, a3, tp
        sub a2, t4, t6
        add t4, t4, t6
        mul t6, a2, s11
        mulh a3, a2, s10
        mulh t6, t6, a6
        sub t6, a3, t6
        sub a2, t5, tp
        add t5, t5, tp
        mul tp, a2, s11
        mulh a3, a2, s10
        mulh tp, tp, a6
        sub tp, a3, tp
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
        bne a4, a0, Lintt_rv32im_looper_12
        addi a0, a0, -0x400
        addi a5, a1, 0x1c0

Lintt_rv32im_outer_345:
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

Lintt_rv32im_inner_345:
        lw t0, 0x0(a0)
        lw t1, 0x10(a0)
        lw t2, 0x20(a0)
        lw t3, 0x30(a0)
        lw t4, 0x40(a0)
        lw t5, 0x50(a0)
        lw t6, 0x60(a0)
        lw tp, 0x70(a0)
        sub a2, t0, t1
        add t0, t0, t1
        mul t1, a2, s1
        mulh a3, a2, s0
        mulh t1, t1, a6
        sub t1, a3, t1
        sub a2, t2, t3
        add t2, t2, t3
        mul t3, a2, s3
        mulh a3, a2, s2
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t4, t5
        add t4, t4, t5
        mul t5, a2, s5
        mulh a3, a2, s4
        mulh t5, t5, a6
        sub t5, a3, t5
        sub a2, t6, tp
        add t6, t6, tp
        mul tp, a2, s7
        mulh a3, a2, s6
        mulh tp, tp, a6
        sub tp, a3, tp
        sub a2, t0, t2
        add t0, t0, t2
        mul t2, a2, s9
        mulh a3, a2, s8
        mulh t2, t2, a6
        sub t2, a3, t2
        sub a2, t1, t3
        add t1, t1, t3
        mul t3, a2, s9
        mulh a3, a2, s8
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t4, t6
        add t4, t4, t6
        mul t6, a2, s11
        mulh a3, a2, s10
        mulh t6, t6, a6
        sub t6, a3, t6
        sub a2, t5, tp
        add t5, t5, tp
        mul tp, a2, s11
        mulh a3, a2, s10
        mulh tp, tp, a6
        sub tp, a3, tp
        sub a2, t0, t4
        add t0, t0, t4
        mul t4, a2, ra
        mulh a3, a2, gp
        mulh t4, t4, a6
        sub t4, a3, t4
        sub a2, t1, t5
        add t1, t1, t5
        mul t5, a2, ra
        mulh a3, a2, gp
        mulh t5, t5, a6
        sub t5, a3, t5
        sub a2, t2, t6
        add t2, t2, t6
        mul t6, a2, ra
        mulh a3, a2, gp
        mulh t6, t6, a6
        sub t6, a3, t6
        sub a2, t3, tp
        add t3, t3, tp
        mul tp, a2, ra
        mulh a3, a2, gp
        mulh tp, tp, a6
        sub tp, a3, tp
        sw t0, 0x0(a0)
        sw t1, 0x10(a0)
        sw t2, 0x20(a0)
        sw t3, 0x30(a0)
        sw t4, 0x40(a0)
        sw t5, 0x50(a0)
        sw t6, 0x60(a0)
        sw tp, 0x70(a0)
        addi a0, a0, 0x4
        bne a4, a0, Lintt_rv32im_inner_345
        addi a0, a0, 0x70
        addi a1, a1, 0x38
        bne a5, a1, Lintt_rv32im_outer_345
        addi a0, a0, -0x400
        addi a4, a0, 0x80
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
        lui a7, 0xa
        addi a7, a7, 0x3fa
        lui a5, 0xff7fe
        addi a5, a5, 0x3fa

Lintt_rv32im_looper_678:
        lw t0, 0x0(a0)
        lw t1, 0x80(a0)
        lw t2, 0x100(a0)
        lw t3, 0x180(a0)
        lw t4, 0x200(a0)
        lw t5, 0x280(a0)
        lw t6, 0x300(a0)
        lw tp, 0x380(a0)
        sub a2, t0, t1
        add t0, t0, t1
        mul t1, a2, s1
        mulh a3, a2, s0
        mulh t1, t1, a6
        sub t1, a3, t1
        sub a2, t2, t3
        add t2, t2, t3
        mul t3, a2, s3
        mulh a3, a2, s2
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t4, t5
        add t4, t4, t5
        mul t5, a2, s5
        mulh a3, a2, s4
        mulh t5, t5, a6
        sub t5, a3, t5
        sub a2, t6, tp
        add t6, t6, tp
        mul tp, a2, s7
        mulh a3, a2, s6
        mulh tp, tp, a6
        sub tp, a3, tp
        sub a2, t0, t2
        add t0, t0, t2
        mul t2, a2, s9
        mulh a3, a2, s8
        mulh t2, t2, a6
        sub t2, a3, t2
        sub a2, t1, t3
        add t1, t1, t3
        mul t3, a2, s9
        mulh a3, a2, s8
        mulh t3, t3, a6
        sub t3, a3, t3
        sub a2, t4, t6
        add t4, t4, t6
        mul t6, a2, s11
        mulh a3, a2, s10
        mulh t6, t6, a6
        sub t6, a3, t6
        sub a2, t5, tp
        add t5, t5, tp
        mul tp, a2, s11
        mulh a3, a2, s10
        mulh tp, tp, a6
        sub tp, a3, tp
        sub a2, t0, t4
        add t0, t0, t4
        mul t4, a2, ra
        mulh a3, a2, gp
        mulh t4, t4, a6
        sub t4, a3, t4
        sub a2, t1, t5
        add t1, t1, t5
        mul t5, a2, ra
        mulh a3, a2, gp
        mulh t5, t5, a6
        sub t5, a3, t5
        sub a2, t2, t6
        add t2, t2, t6
        mul t6, a2, ra
        mulh a3, a2, gp
        mulh t6, t6, a6
        sub t6, a3, t6
        sub a2, t3, tp
        add t3, t3, tp
        mul tp, a2, ra
        mulh a3, a2, gp
        mulh tp, tp, a6
        sub tp, a3, tp
        mul a2, t0, a5
        mulh t0, t0, a7
        mulh a2, a2, a6
        sub t0, t0, a2
        mul a2, t1, a5
        mulh t1, t1, a7
        mulh a2, a2, a6
        sub t1, t1, a2
        mul a2, t2, a5
        mulh t2, t2, a7
        mulh a2, a2, a6
        sub t2, t2, a2
        mul a2, t3, a5
        mulh t3, t3, a7
        mulh a2, a2, a6
        sub t3, t3, a2
        sw t0, 0x0(a0)
        sw t1, 0x80(a0)
        sw t2, 0x100(a0)
        sw t3, 0x180(a0)
        sw t4, 0x200(a0)
        sw t5, 0x280(a0)
        sw t6, 0x300(a0)
        sw tp, 0x380(a0)
        addi a0, a0, 0x4
        bne a4, a0, Lintt_rv32im_looper_678
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

MLD_ASM_FN_SIZE(intt_rv32im_asm)

#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
