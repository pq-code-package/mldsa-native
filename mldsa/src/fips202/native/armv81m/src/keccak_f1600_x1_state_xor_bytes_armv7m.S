/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * This helper adapts the CC0-1.0 bit-interleaving and byte-access routines in
 * keccakp1600_fast_cortexm3-4.S at commit
 * b18cd6e792efd911fe9c24fd0d5fe65a534fc620 of:
 * https://github.com/aadomn/keccak_armv7m
 * The bit-interleaving transform is credited there to Henry S. Warren,
 * Hacker's Delight, Addison-Wesley, 2002.
 */

/*yaml
  Name: keccak_f1600_x1_state_xor_bytes_asm
  Description: XOR bytes into an x1 Keccak state while converting each touched lane to the bit-interleaved Armv7-M representation
  Signature: void mld_keccak_f1600_x1_state_xor_bytes_asm(void *state, const uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: []
    r0:
      type: buffer
      size_bytes: 200
      permissions: read/write
      c_parameter: void *state
      description: Bit-interleaved x1 Keccak state
    r1:
      type: buffer
      size_bytes: r3
      permissions: read-only
      c_parameter: const uint8_t *data
      description: Bytes to XOR into the state
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset within the 200-byte state
      test_with: 7
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of input bytes
      test_with: 9
  Stack:
    bytes: 32
    description: register preservation (24) plus one temporary lane (8)
*/

/*
 * AAPCS32 contract: preserves r4-r11 and sp. The caller-saved r0-r3, r12,
 * APSR condition flags, and lr may be clobbered. No floating-point or MVE
 * registers are accessed.
 */

#include "../../../../common.h"

#if defined(MLD_FIPS202_ARMV81M_NEED_X1) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m_opt/src/keccak_f1600_x1_state_xor_bytes_armv7m.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm)
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_xor_bytes_asm)

        .cfi_startproc
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_xor_bytes_exit @ imm = #0x254
        push.w {r4, r5, r6, r7, r8, lr}
        .cfi_adjust_cfa_offset 0x18
        .cfi_rel_offset r4, 0x0
        .cfi_rel_offset r5, 0x4
        .cfi_rel_offset r6, 0x8
        .cfi_rel_offset r7, 0xc
        .cfi_rel_offset r8, 0x10
        .cfi_rel_offset lr, 0x14
        bic r4, r2, #0x7
        adds r0, r0, r4
        ands r2, r2, #0x7
        beq.w Lmld_keccak_f1600_x1_state_xor_bytes_check_lanes @ imm = #0xcc
        movs r4, r3
        rsb.w r5, r2, #0x8
        cmp r4, r5
        ble Lmld_keccak_f1600_x1_state_xor_bytes_align @ imm = #0x0
        movs r4, r5

Lmld_keccak_f1600_x1_state_xor_bytes_align:
        sub.w r8, r3, r4
        movs r3, r4
        movs r4, #0x0
        movs r5, #0x0
        sub sp, #0x8
        .cfi_adjust_cfa_offset 0x8
        strd r4, r5, [sp]
        add r2, sp, r2

Lmld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_first:
        ldrb r5, [r1], #1
        strb r5, [r2], #1
        subs r3, #0x1
        bne Lmld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_first @ imm = #-0xe
        ldrd r4, r5, [sp]
        add sp, #0x8
        .cfi_adjust_cfa_offset -0x8
        ldrd r6, r7, [r0]
        and r3, r4, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        bfi r3, r3, #8, #8
        eor.w r6, r6, r3, lsr #8
        and r3, r5, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        orr.w r3, r3, r3, lsr #8
        eor.w r6, r6, r3, lsl #16
        and r3, r4, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        eor.w r7, r7, r3, lsr #16
        and r3, r5, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        bfc r3, #0, #16
        eors r7, r3
        strd r6, r7, [r0], #8
        mov r3, r8

Lmld_keccak_f1600_x1_state_xor_bytes_check_lanes:
        lsrs r2, r3, #0x3
        beq.w Lmld_keccak_f1600_x1_state_xor_bytes_tail @ imm = #0xac
        mov r8, r3

Lmld_keccak_f1600_x1_state_xor_bytes_lanes_loop:
        ldr r4, [r1], #4
        ldr r5, [r1], #4
        ldrd r6, r7, [r0]
        and r3, r4, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        bfi r3, r3, #8, #8
        eor.w r6, r6, r3, lsr #8
        and r3, r5, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        orr.w r3, r3, r3, lsr #8
        eor.w r6, r6, r3, lsl #16
        and r3, r4, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        eor.w r7, r7, r3, lsr #16
        and r3, r5, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        bfc r3, #0, #16
        eors r7, r3
        strd r6, r7, [r0], #8
        subs r2, #0x1
        bne Lmld_keccak_f1600_x1_state_xor_bytes_lanes_loop @ imm = #-0xa8
        and r3, r8, #0x7

Lmld_keccak_f1600_x1_state_xor_bytes_tail:
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_xor_bytes_restore @ imm = #0xba
        movs r2, #0x0
        movs r4, #0x0
        movs r5, #0x0
        sub sp, #0x8
        .cfi_adjust_cfa_offset 0x8
        strd r4, r5, [sp]
        add r2, sp, r2

Lmld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_tail:
        ldrb r5, [r1], #1
        strb r5, [r2], #1
        subs r3, #0x1
        bne Lmld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_tail @ imm = #-0xe
        ldrd r4, r5, [sp]
        add sp, #0x8
        .cfi_adjust_cfa_offset -0x8
        ldrd r6, r7, [r0]
        and r3, r4, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        bfi r3, r3, #8, #8
        eor.w r6, r6, r3, lsr #8
        and r3, r5, #0x55555555
        orr.w r3, r3, r3, lsr #1
        and r3, r3, #0x33333333
        orr.w r3, r3, r3, lsr #2
        and r3, r3, #0xf0f0f0f
        orr.w r3, r3, r3, lsr #4
        and r3, r3, #0xff00ff
        orr.w r3, r3, r3, lsr #8
        eor.w r6, r6, r3, lsl #16
        and r3, r4, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        eor.w r7, r7, r3, lsr #16
        and r3, r5, #0xaaaaaaaa
        orr.w r3, r3, r3, lsl #1
        and r3, r3, #0xcccccccc
        orr.w r3, r3, r3, lsl #2
        and r3, r3, #0xf0f0f0f0
        orr.w r3, r3, r3, lsl #4
        and r3, r3, #0xff00ff00
        orr.w r3, r3, r3, lsl #8
        bfc r3, #0, #16
        eors r7, r3
        strd r6, r7, [r0], #8

Lmld_keccak_f1600_x1_state_xor_bytes_restore:
        pop.w {r4, r5, r6, r7, r8, lr}
        .cfi_restore r4
        .cfi_restore r5
        .cfi_restore r6
        .cfi_restore r7
        .cfi_restore r8
        .cfi_restore lr
        .cfi_adjust_cfa_offset -0x18

Lmld_keccak_f1600_x1_state_xor_bytes_exit:
        bx lr
        .cfi_endproc

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_xor_bytes_asm)

#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
