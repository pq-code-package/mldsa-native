/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

/*
 * RV32 ILP32 ABI compliance testing stub.
 *
 * C signature:
 *   void asm_call_stub_riscv32(struct riscv32_register_state *input,
 *                              struct riscv32_register_state *output,
 *                              void (*function_ptr)(void));
 *
 * The target kernels take their first two arguments in a0/a1. The stub seeds
 * those registers, the reserved gp/tp registers, and all twelve callee-saved
 * integer registers from `input`, calls the target, and captures the
 * preserved set in `output`.
 *
 * It separately saves its caller's ra, gp, tp, and s0-s11 in an 80-byte
 * frame. The frame remains 16-byte aligned as required by the RISC-V ILP32
 * ABI.
 */

#define FRAME_SIZE 80
#define LOC_OUTPUT 60
#define LOC_FUNCTION 64

.text
.balign 4
.global asm_call_stub_riscv32
.type asm_call_stub_riscv32, @function
asm_call_stub_riscv32:
        .cfi_startproc
        addi sp, sp, -FRAME_SIZE
        .cfi_def_cfa_offset FRAME_SIZE
        sw   ra,  0(sp)
        sw   s0,  4(sp)
        sw   s1,  8(sp)
        sw   s2, 12(sp)
        sw   s3, 16(sp)
        sw   s4, 20(sp)
        sw   s5, 24(sp)
        sw   s6, 28(sp)
        sw   s7, 32(sp)
        sw   s8, 36(sp)
        sw   s9, 40(sp)
        sw   s10, 44(sp)
        sw   s11, 48(sp)
        sw   gp, 52(sp)
        sw   tp, 56(sp)
        .cfi_offset ra, -80
        .cfi_offset s0, -76
        .cfi_offset s1, -72
        .cfi_offset s2, -68
        .cfi_offset s3, -64
        .cfi_offset s4, -60
        .cfi_offset s5, -56
        .cfi_offset s6, -52
        .cfi_offset s7, -48
        .cfi_offset s8, -44
        .cfi_offset s9, -40
        .cfi_offset s10, -36
        .cfi_offset s11, -32
        .cfi_offset gp, -28
        .cfi_offset tp, -24

        sw   a1, LOC_OUTPUT(sp)
        sw   a2, LOC_FUNCTION(sp)

        /* Seed gp/tp (x3/x4), s0/s1 (x8/x9), and s2-s11 (x18-x27). */
        lw   gp,  (3 * 4)(a0)
        lw   tp,  (4 * 4)(a0)
        lw   s0,  (8 * 4)(a0)
        lw   s1,  (9 * 4)(a0)
        lw   s2,  (18 * 4)(a0)
        lw   s3,  (19 * 4)(a0)
        lw   s4,  (20 * 4)(a0)
        lw   s5,  (21 * 4)(a0)
        lw   s6,  (22 * 4)(a0)
        lw   s7,  (23 * 4)(a0)
        lw   s8,  (24 * 4)(a0)
        lw   s9,  (25 * 4)(a0)
        lw   s10, (26 * 4)(a0)
        lw   s11, (27 * 4)(a0)

        /* Load target arguments last because a0 is the input-state base. */
        lw   a1, (11 * 4)(a0)
        lw   a0, (10 * 4)(a0)

        lw   t0, LOC_FUNCTION(sp)
        jalr ra, t0, 0

        /* Capture the preserved set before restoring the stub's own. */
        lw   t0, LOC_OUTPUT(sp)
        sw   gp,  (3 * 4)(t0)
        sw   tp,  (4 * 4)(t0)
        sw   s0,  (8 * 4)(t0)
        sw   s1,  (9 * 4)(t0)
        sw   s2,  (18 * 4)(t0)
        sw   s3,  (19 * 4)(t0)
        sw   s4,  (20 * 4)(t0)
        sw   s5,  (21 * 4)(t0)
        sw   s6,  (22 * 4)(t0)
        sw   s7,  (23 * 4)(t0)
        sw   s8,  (24 * 4)(t0)
        sw   s9,  (25 * 4)(t0)
        sw   s10, (26 * 4)(t0)
        sw   s11, (27 * 4)(t0)

        lw   ra,  0(sp)
        lw   s0,  4(sp)
        lw   s1,  8(sp)
        lw   s2, 12(sp)
        lw   s3, 16(sp)
        lw   s4, 20(sp)
        lw   s5, 24(sp)
        lw   s6, 28(sp)
        lw   s7, 32(sp)
        lw   s8, 36(sp)
        lw   s9, 40(sp)
        lw   s10, 44(sp)
        lw   s11, 48(sp)
        lw   gp, 52(sp)
        lw   tp, 56(sp)
        .cfi_restore ra
        .cfi_restore s0
        .cfi_restore s1
        .cfi_restore s2
        .cfi_restore s3
        .cfi_restore s4
        .cfi_restore s5
        .cfi_restore s6
        .cfi_restore s7
        .cfi_restore s8
        .cfi_restore s9
        .cfi_restore s10
        .cfi_restore s11
        .cfi_restore gp
        .cfi_restore tp
        addi sp, sp, FRAME_SIZE
        .cfi_def_cfa_offset 0
        ret
        .cfi_endproc
