/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA inverse NTT, slow-multiplier variant.
 *
 * Thin wrapper: the kernel body is shared via intt_rv32im_asm.i, which here
 * computes the Barrett low(t*q) reduction with a shift-add chain (exploiting
 * q = 2^23 - 2^13 + 1), trading the multiply for cheap ALU ops -- preferred
 * when the multiplier is slow. The fast-multiplier variant lives in
 * intt_rv32im_asm.S. Exactly one of the two is selected, by
 * MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
    defined(MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv32/src/intt_rv32im_slowmul_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(intt_rv32im_asm)
MLD_ASM_FN_SYMBOL(intt_rv32im_asm)

        .cfi_startproc
        addi sp, sp, -0x20
        .cfi_adjust_cfa_offset 0x20
        sw s0, 0x0(sp)
        sw s1, 0x4(sp)
        sw s2, 0x8(sp)
        sw s3, 0xc(sp)
        sw s4, 0x10(sp)
        sw s5, 0x14(sp)
        sw s6, 0x18(sp)
        sw s7, 0x1c(sp)
        addi a1, a1, 0x7f8
        mv t2, a0
        addi t3, a0, 0x400

Lintt_rv32im_p1_outer:
        addi a1, a1, -0x18
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        lw a2, 0x0(t2)
        lw a3, 0x4(t2)
        lw a4, 0x8(t2)
        lw a5, 0xc(t2)
        sub a6, a3, a2
        add a2, a2, a3
        mulh a7, a6, s5
        mul a3, a6, s4
        sub a3, a3, a7
        slli a7, a7, 0xd
        add a3, a3, a7
        slli a7, a7, 0xa
        sub a3, a3, a7
        sub a6, a5, a4
        add a4, a4, a5
        mulh a7, a6, s3
        mul a5, a6, s2
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sub a6, a4, a2
        add a2, a2, a4
        mulh a7, a6, s1
        mul a4, a6, s0
        sub a4, a4, a7
        slli a7, a7, 0xd
        add a4, a4, a7
        slli a7, a7, 0xa
        sub a4, a4, a7
        sub a6, a5, a3
        add a3, a3, a5
        mulh a7, a6, s1
        mul a5, a6, s0
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sw a2, 0x0(t2)
        sw a3, 0x4(t2)
        sw a4, 0x8(t2)
        sw a5, 0xc(t2)
        addi t2, t2, 0x10
        bne t2, t3, Lintt_rv32im_p1_outer
        mv t2, a0
        addi t3, a0, 0x400

Lintt_rv32im_p2_outer:
        addi a1, a1, -0x18
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi t4, t2, 0x10

Lintt_rv32im_p2_inner:
        lw a2, 0x0(t2)
        lw a3, 0x10(t2)
        lw a4, 0x20(t2)
        lw a5, 0x30(t2)
        sub a6, a3, a2
        add a2, a2, a3
        mulh a7, a6, s5
        mul a3, a6, s4
        sub a3, a3, a7
        slli a7, a7, 0xd
        add a3, a3, a7
        slli a7, a7, 0xa
        sub a3, a3, a7
        sub a6, a5, a4
        add a4, a4, a5
        mulh a7, a6, s3
        mul a5, a6, s2
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sub a6, a4, a2
        add a2, a2, a4
        mulh a7, a6, s1
        mul a4, a6, s0
        sub a4, a4, a7
        slli a7, a7, 0xd
        add a4, a4, a7
        slli a7, a7, 0xa
        sub a4, a4, a7
        sub a6, a5, a3
        add a3, a3, a5
        mulh a7, a6, s1
        mul a5, a6, s0
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sw a2, 0x0(t2)
        sw a3, 0x10(t2)
        sw a4, 0x20(t2)
        sw a5, 0x30(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lintt_rv32im_p2_inner
        addi t2, t2, 0x30
        bne t2, t3, Lintt_rv32im_p2_outer
        mv t2, a0
        addi t3, a0, 0x400

Lintt_rv32im_p3_outer:
        addi a1, a1, -0x18
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi t4, t2, 0x40

Lintt_rv32im_p3_inner:
        lw a2, 0x0(t2)
        lw a3, 0x40(t2)
        lw a4, 0x80(t2)
        lw a5, 0xc0(t2)
        sub a6, a3, a2
        add a2, a2, a3
        mulh a7, a6, s5
        mul a3, a6, s4
        sub a3, a3, a7
        slli a7, a7, 0xd
        add a3, a3, a7
        slli a7, a7, 0xa
        sub a3, a3, a7
        sub a6, a5, a4
        add a4, a4, a5
        mulh a7, a6, s3
        mul a5, a6, s2
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sub a6, a4, a2
        add a2, a2, a4
        mulh a7, a6, s1
        mul a4, a6, s0
        sub a4, a4, a7
        slli a7, a7, 0xd
        add a4, a4, a7
        slli a7, a7, 0xa
        sub a4, a4, a7
        sub a6, a5, a3
        add a3, a3, a5
        mulh a7, a6, s1
        mul a5, a6, s0
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sw a2, 0x0(t2)
        sw a3, 0x40(t2)
        sw a4, 0x80(t2)
        sw a5, 0xc0(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lintt_rv32im_p3_inner
        addi t2, t2, 0xc0
        bne t2, t3, Lintt_rv32im_p3_outer
        addi a1, a1, -0x18
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        mv t2, a0
        addi t4, a0, 0x100

Lintt_rv32im_p4_inner:
        lw a2, 0x0(t2)
        lw a3, 0x100(t2)
        lw a4, 0x200(t2)
        lw a5, 0x300(t2)
        sub a6, a3, a2
        add a2, a2, a3
        mulh a7, a6, s5
        mul a3, a6, s4
        sub a3, a3, a7
        slli a7, a7, 0xd
        add a3, a3, a7
        slli a7, a7, 0xa
        sub a3, a3, a7
        sub a6, a5, a4
        add a4, a4, a5
        mulh a7, a6, s3
        mul a5, a6, s2
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sub a6, a4, a2
        add a2, a2, a4
        mulh a7, a6, s1
        mul a4, a6, s0
        sub a4, a4, a7
        slli a7, a7, 0xd
        add a4, a4, a7
        slli a7, a7, 0xa
        sub a4, a4, a7
        sub a6, a5, a3
        add a3, a3, a5
        mulh a7, a6, s1
        mul a5, a6, s0
        sub a5, a5, a7
        slli a7, a7, 0xd
        add a5, a5, a7
        slli a7, a7, 0xa
        sub a5, a5, a7
        sw a2, 0x0(t2)
        sw a3, 0x100(t2)
        sw a4, 0x200(t2)
        sw a5, 0x300(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lintt_rv32im_p4_inner
        lui s6, 0x4
        addi s6, s6, -0x2
        lui s7, 0x1004
        addi s7, s7, -0x7f4
        mv t2, a0
        addi t5, a0, 0x400

Lintt_rv32im_scale:
        lw a2, 0x0(t2)
        mulh a6, a2, s7
        addi a6, a6, 0x1
        srai a6, a6, 0x1
        mul a3, a2, s6
        sub a3, a3, a6
        slli a6, a6, 0xd
        add a3, a3, a6
        slli a6, a6, 0xa
        sub a3, a3, a6
        sw a3, 0x0(t2)
        addi t2, t2, 0x4
        bne t2, t5, Lintt_rv32im_scale
        lw s0, 0x0(sp)
        lw s1, 0x4(sp)
        lw s2, 0x8(sp)
        lw s3, 0xc(sp)
        lw s4, 0x10(sp)
        lw s5, 0x14(sp)
        lw s6, 0x18(sp)
        lw s7, 0x1c(sp)
        addi sp, sp, 0x20
        .cfi_adjust_cfa_offset -0x20
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(intt_rv32im_asm)

#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
