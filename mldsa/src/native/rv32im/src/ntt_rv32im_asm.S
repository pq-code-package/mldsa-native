/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA forward NTT.
 *
 * Layered structure: 2+2+2+2 (four passes, each merging two layers, with
 * a radix-4 inner kernel holding 4 coefficients in registers).
 *
 * Modular arithmetic: standard signed Montgomery multiplication.
 * Each zeta is provided in Montgomery form (R * w^{bitrev(k)} mod q,
 * R = 2^32) along with its precomputed twist  z' = (z * QINV) mod 2^32,
 * so a Montgomery multiply is 3 multiplies + 1 sub:
 *
 *   m  = low(a * z')
 *   r  = hi(a * z) - hi(m * q)
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
        addi sp, sp, -0x20
        .cfi_adjust_cfa_offset 0x20
        sw s0, 0x0(sp)
        sw s1, 0x4(sp)
        sw s2, 0x8(sp)
        sw s3, 0xc(sp)
        sw s4, 0x10(sp)
        sw s5, 0x14(sp)
        sw s6, 0x18(sp)
        lui s6, 0x7fe
        addi s6, s6, 0x1
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi a1, a1, 0x18
        mv t2, a0
        addi t4, a0, 0x100

Lntt_rv32im_p1_loop:
        lw a2, 0x0(t2)
        lw a3, 0x100(t2)
        lw a4, 0x200(t2)
        lw a5, 0x300(t2)
        mul a7, a4, s1
        mulh a6, a4, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a4, a2, a6
        add a2, a2, a6
        mul a7, a5, s1
        mulh a6, a5, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a3, a6
        add a3, a3, a6
        mul a7, a3, s3
        mulh a6, a3, s2
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a3, a2, a6
        add a2, a2, a6
        mul a7, a5, s5
        mulh a6, a5, s4
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a4, a6
        add a4, a4, a6
        sw a2, 0x0(t2)
        sw a3, 0x100(t2)
        sw a4, 0x200(t2)
        sw a5, 0x300(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lntt_rv32im_p1_loop
        mv t2, a0
        addi t3, a0, 0x400

Lntt_rv32im_p2_outer:
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi a1, a1, 0x18
        addi t4, t2, 0x40

Lntt_rv32im_p2_inner:
        lw a2, 0x0(t2)
        lw a3, 0x40(t2)
        lw a4, 0x80(t2)
        lw a5, 0xc0(t2)
        mul a7, a4, s1
        mulh a6, a4, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a4, a2, a6
        add a2, a2, a6
        mul a7, a5, s1
        mulh a6, a5, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a3, a6
        add a3, a3, a6
        mul a7, a3, s3
        mulh a6, a3, s2
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a3, a2, a6
        add a2, a2, a6
        mul a7, a5, s5
        mulh a6, a5, s4
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a4, a6
        add a4, a4, a6
        sw a2, 0x0(t2)
        sw a3, 0x40(t2)
        sw a4, 0x80(t2)
        sw a5, 0xc0(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lntt_rv32im_p2_inner
        addi t2, t2, 0xc0
        bne t2, t3, Lntt_rv32im_p2_outer
        mv t2, a0
        addi t3, a0, 0x400

Lntt_rv32im_p3_outer:
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi a1, a1, 0x18
        addi t4, t2, 0x10

Lntt_rv32im_p3_inner:
        lw a2, 0x0(t2)
        lw a3, 0x10(t2)
        lw a4, 0x20(t2)
        lw a5, 0x30(t2)
        mul a7, a4, s1
        mulh a6, a4, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a4, a2, a6
        add a2, a2, a6
        mul a7, a5, s1
        mulh a6, a5, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a3, a6
        add a3, a3, a6
        mul a7, a3, s3
        mulh a6, a3, s2
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a3, a2, a6
        add a2, a2, a6
        mul a7, a5, s5
        mulh a6, a5, s4
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a4, a6
        add a4, a4, a6
        sw a2, 0x0(t2)
        sw a3, 0x10(t2)
        sw a4, 0x20(t2)
        sw a5, 0x30(t2)
        addi t2, t2, 0x4
        bne t2, t4, Lntt_rv32im_p3_inner
        addi t2, t2, 0x30
        bne t2, t3, Lntt_rv32im_p3_outer
        mv t2, a0
        addi t3, a0, 0x400

Lntt_rv32im_p4_outer:
        lw s0, 0x0(a1)
        lw s1, 0x4(a1)
        lw s2, 0x8(a1)
        lw s3, 0xc(a1)
        lw s4, 0x10(a1)
        lw s5, 0x14(a1)
        addi a1, a1, 0x18
        lw a2, 0x0(t2)
        lw a3, 0x4(t2)
        lw a4, 0x8(t2)
        lw a5, 0xc(t2)
        mul a7, a4, s1
        mulh a6, a4, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a4, a2, a6
        add a2, a2, a6
        mul a7, a5, s1
        mulh a6, a5, s0
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a3, a6
        add a3, a3, a6
        mul a7, a3, s3
        mulh a6, a3, s2
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a3, a2, a6
        add a2, a2, a6
        mul a7, a5, s5
        mulh a6, a5, s4
        mulh a7, a7, s6
        sub a6, a6, a7
        sub a5, a4, a6
        add a4, a4, a6
        sw a2, 0x0(t2)
        sw a3, 0x4(t2)
        sw a4, 0x8(t2)
        sw a5, 0xc(t2)
        addi t2, t2, 0x10
        bne t2, t3, Lntt_rv32im_p4_outer
        lw s0, 0x0(sp)
        lw s1, 0x4(sp)
        lw s2, 0x8(sp)
        lw s3, 0xc(sp)
        lw s4, 0x10(sp)
        lw s5, 0x14(sp)
        lw s6, 0x18(sp)
        addi sp, sp, 0x20
        .cfi_adjust_cfa_offset -0x20
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(ntt_rv32im_asm)

#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
