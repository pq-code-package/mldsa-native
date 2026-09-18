/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) 2026 Arm Limited
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * This helper is adapted from mlkem-native commit
 * fc76e8bc6e9a9a2f72941093745c715394bec331, files
 * mlkem/src/fips202/native/armv81m/src/state_extract_bytes_x1_mve_asm.S and
 * state_xor_bytes_x1_mve_asm.S. Those files are copyright the mlkem-native
 * and mldsa-native project authors and Arm Limited, and are available under
 * Apache-2.0 OR ISC OR MIT. It converts two adjacent Keccak lanes at once
 * between the bit-interleaved x1 representation and bytes.
 */

/*yaml
  Name: keccak_f1600_x1_state_extract_bytes_asm
  Description: Armv8.1-M MVE fast path for extracting bytes from an x1 bit-interleaved Keccak state
  Signature: void mld_keccak_f1600_x1_state_extract_bytes_asm(void *state, uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: [MVE]
    r0:
      type: buffer
      size_bytes: 200
      alignment_bytes: 8
      permissions: read-only
      c_parameter: void *state
      description: Bit-interleaved x1 Keccak state, naturally aligned for 32-bit MVE state accesses
    r1:
      type: buffer
      size_bytes: r3
      alignment_bytes: 1
      permissions: write-only
      c_parameter: uint8_t *data
      description: Arbitrarily byte-aligned output bytes
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset within the 200-byte Keccak state
      test_with: 192
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of output bytes such that offset plus length is at most 200
      test_with: 8
  Stack:
    bytes: 40
    description: AAPCS32 preservation of r4-r11 and lr; the MVE fast path uses only caller-saved q0-q3 and p0
*/

/*
 * AAPCS32 contract: preserves r4-r11, sp, and d8-d15/q4-q7. The caller-saved
 * r0-r3, r12, lr, APSR condition flags, q0-q3, and p0 may be clobbered.
 * Full two-lane groups before the final two lanes use 16-byte MVE state
 * accesses. The final 16-byte pair and final 8-byte lane use ordinary,
 * exact-width D-register accesses. This keeps every state access within the
 * 200-byte object for every permitted 8-byte state alignment.
 */

#include "../../../../common.h"

#if defined(MLD_FIPS202_ARMV81M_NEED_X1) &&  !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__ARM_FEATURE_MVE)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m_opt/src/keccak_f1600_x1_state_extract_bytes_mve.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm)
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_extract_bytes_asm)

        .cfi_startproc
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_exit @ imm = #0x2b0
        push.w {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
        .cfi_adjust_cfa_offset 0x28
        .cfi_rel_offset r4, 0x0
        .cfi_rel_offset r5, 0x4
        .cfi_rel_offset r6, 0x8
        .cfi_rel_offset r7, 0xc
        .cfi_rel_offset r8, 0x10
        .cfi_rel_offset r9, 0x14
        .cfi_rel_offset r10, 0x18
        .cfi_rel_offset r11, 0x1c
        .cfi_rel_offset lr, 0x24
        mov.w r6, #0x4
        mov.w r7, #0x10
        add.w r8, r0, #0xb0
        and r5, r2, #0xf
        bic r9, r2, #0xf
        add r0, r9
        cmp r5, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_pre_main @ imm = #0xc4
        subs r1, r1, r5
        rsb.w lr, r5, #0x10
        cmp r3, lr
        it ls
        movls lr, r3
        subs.w r3, r3, lr
        cmp r0, r8
        bhs.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_state_tail @ imm = #0x8
        vldrw.u32 q0, [r0], #16
        b.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded @ imm = #0x1c

Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_state_tail:
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_penultimate_lane @ imm = #0xc
        vldr d0, [r0]
        add.w r0, r0, #0x10
        b.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded @ imm = #0xc

Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_penultimate_lane:
        vldr d0, [r0]
        vldr d1, [r0, #8]
        add.w r0, r0, #0x10

Lmld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded:
        movw r4, #0xf0f
        vmsr p0, r4
        vrev32.16 q1, q0
        vrev64.32 q2, q1
        vrev64.32 q3, q0
        vpsel q0, q0, q2
        vpsel q1, q3, q1
        vsli.32 q0, q0, #0x8
        vsli.16 q0, q0, #0x4
        vsli.8 q0, q0, #0x1
        vqdmulh.s8 q2, q0, r7
        vsli.8 q0, q2, #0x4
        vqdmulh.s8 q2, q0, r6
        vsli.8 q0, q2, #0x6
        vsli.32 q1, q1, #0x8
        vsli.16 q1, q1, #0x4
        vsli.8 q1, q1, #0x1
        vqdmulh.s8 q2, q1, r7
        vsli.8 q1, q2, #0x4
        vqdmulh.s8 q2, q1, r6
        vsli.8 q1, q2, #0x6
        mov.w r4, #0x55
        vdup.8 q2, r4
        vand q0, q0, q2
        vand q1, q1, q2
        vshl.i32 q1, q1, #0x1
        vorr q0, q1, q0
        vctp.8 lr
        vmrs r11, p0
        lsl.w r11, r11, r5
        vmsr p0, r11
        vpst
        vstrbt.8 q0, [r1], #16
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_restore @ imm = #0x1c8

Lmld_keccak_f1600_x1_state_extract_bytes_mve_pre_main:
        lsr.w lr, r3, #0x4
        cmp r0, r8
        bhs.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end @ imm = #0x92
        sub.w r4, r8, r0
        lsr.w r4, r4, #0x4
        cmp lr, r4
        it hi
        movhi lr, r4
        lsl.w r4, lr, #0x4
        sub.w r3, r3, r4
        wls lr, lr, Lmld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end @ imm = #0x78

Lmld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare:
        vldrw.u32 q0, [r0], #16
        movw r4, #0xf0f
        vmsr p0, r4
        vrev32.16 q1, q0
        vrev64.32 q2, q1
        vrev64.32 q3, q0
        vpsel q0, q0, q2
        vpsel q1, q3, q1

Lmld_keccak_f1600_x1_state_extract_bytes_mve_slothy_start:
        vsli.32 q0, q0, #0x8
        vsli.16 q0, q0, #0x4
        vsli.8 q0, q0, #0x1
        vqdmulh.s8 q3, q0, r7
        vsli.8 q0, q3, #0x4
        vqdmulh.s8 q2, q0, r6
        vsli.32 q1, q1, #0x8
        vsli.8 q0, q2, #0x6
        vsli.16 q1, q1, #0x4
        vsli.8 q1, q1, #0x1
        vqdmulh.s8 q2, q1, r7
        vsli.8 q1, q2, #0x4
        vqdmulh.s8 q3, q1, r6
        vsli.8 q1, q3, #0x6
        mov.w r2, #0x55
        vdup.8 q3, r2
        vand q2, q0, q3
        vand q3, q1, q3
        vshl.i32 q1, q3, #0x1
        vorr q0, q1, q2
        vstrb.8 q0, [r1], #16

Lmld_keccak_f1600_x1_state_extract_bytes_mve_slothy_end:
        le lr, Lmld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare @ imm = #-0x78

Lmld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end:
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_restore @ imm = #0x126
        cmp r0, r8
        bhs.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_state_tail @ imm = #0x8
        vldrw.u32 q0, [r0]
        b.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded @ imm = #0xa0

Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_state_tail:
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_lane @ imm = #0x8

Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_final_lane:
        vldr d0, [r0]
        b.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded @ imm = #0x94

Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_lane:
        cmp r3, #0x10
        blo.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_partial @ imm = #0x86
        vldr d0, [r0]
        vldr d1, [r0, #8]
        movw r4, #0xf0f
        vmsr p0, r4
        vrev32.16 q1, q0
        vrev64.32 q2, q1
        vrev64.32 q3, q0
        vpsel q0, q0, q2
        vpsel q1, q3, q1
        vsli.32 q0, q0, #0x8
        vsli.16 q0, q0, #0x4
        vsli.8 q0, q0, #0x1
        vqdmulh.s8 q2, q0, r7
        vsli.8 q0, q2, #0x4
        vqdmulh.s8 q2, q0, r6
        vsli.8 q0, q2, #0x6
        vsli.32 q1, q1, #0x8
        vsli.16 q1, q1, #0x4
        vsli.8 q1, q1, #0x1
        vqdmulh.s8 q2, q1, r7
        vsli.8 q1, q2, #0x4
        vqdmulh.s8 q2, q1, r6
        vsli.8 q1, q2, #0x6
        mov.w r4, #0x55
        vdup.8 q2, r4
        vand q0, q0, q2
        vand q1, q1, q2
        vshl.i32 q1, q1, #0x1
        vorr q0, q1, q0
        vstrb.8 q0, [r1], #16
        add.w r0, r0, #0x10
        subs r3, #0x10
        bne.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_final_lane @ imm = #-0x90
        b.w Lmld_keccak_f1600_x1_state_extract_bytes_mve_restore @ imm = #0x80

Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_partial:
        vldr d0, [r0]
        vldr d1, [r0, #8]

Lmld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded:
        movw r4, #0xf0f
        vmsr p0, r4
        vrev32.16 q1, q0
        vrev64.32 q2, q1
        vrev64.32 q3, q0
        vpsel q0, q0, q2
        vpsel q1, q3, q1
        vsli.32 q0, q0, #0x8
        vsli.16 q0, q0, #0x4
        vsli.8 q0, q0, #0x1
        vqdmulh.s8 q2, q0, r7
        vsli.8 q0, q2, #0x4
        vqdmulh.s8 q2, q0, r6
        vsli.8 q0, q2, #0x6
        vsli.32 q1, q1, #0x8
        vsli.16 q1, q1, #0x4
        vsli.8 q1, q1, #0x1
        vqdmulh.s8 q2, q1, r7
        vsli.8 q1, q2, #0x4
        vqdmulh.s8 q2, q1, r6
        vsli.8 q1, q2, #0x6
        mov.w r4, #0x55
        vdup.8 q2, r4
        vand q0, q0, q2
        vand q1, q1, q2
        vshl.i32 q1, q1, #0x1
        vorr q0, q1, q0
        vctp.8 r3
        vpst
        vstrbt.8 q0, [r1], #16

Lmld_keccak_f1600_x1_state_extract_bytes_mve_restore:
        pop.w {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
        .cfi_restore r4
        .cfi_restore r5
        .cfi_restore r6
        .cfi_restore r7
        .cfi_restore r8
        .cfi_restore r9
        .cfi_restore r10
        .cfi_restore r11
        .cfi_restore lr
        .cfi_adjust_cfa_offset -0x28

Lmld_keccak_f1600_x1_state_extract_bytes_mve_exit:
        bx lr
        .cfi_endproc

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
