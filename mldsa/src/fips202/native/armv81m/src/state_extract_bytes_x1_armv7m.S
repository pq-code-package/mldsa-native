/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [ADOMNICAI23]
 *   An update on Keccak performance on ARMv7-M
 *   Alexandre Adomnicai
 *   https://eprint.iacr.org/2023/773
 *
 * - [XKCP]
 *   eXtended Keccak Code Package
 *   Bertoni, Daemen, Peeters, Van Assche, Van Keer
 *   https://github.com/XKCP/XKCP
 */

/*
 * This clean helper is split from the sibling clean Armv7-M Keccak-f[1600]
 * source keccak_f1600_x1_armv7m.S. That source is based on public domain XKCP
 * code @[XKCP], with additional optimizations by Alexandre Adomnicai
 * @[ADOMNICAI23].
 */

/*yaml
  Name: keccak_f1600_x1_state_extract_bytes_asm
  Description: Armv7-M byte extraction from a bit-interleaved x1 Keccak state
  Signature: void mld_keccak_f1600_x1_state_extract_bytes_asm(void *state, uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    r0:
      type: buffer
      size_bytes: 200
      permissions: read-only
      c_parameter: void *state
      description: Bit-interleaved x1 state as even/odd 32-bit halves for each Keccak lane
    r1:
      type: buffer
      size_bytes: r3
      permissions: write-only
      c_parameter: uint8_t *data
      description: Output bytes reconstructed from the state
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset into the 200-byte logical Keccak state
      test_with: 3
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of output bytes; offset plus length must not exceed 200
      test_with: 196
  Stack:
    bytes: 32
    description: register preservation (24 bytes) and partial-lane scratch (8 bytes)
*/

#include "../../../../common.h"

#if defined(MLD_FIPS202_ARMV81M_NEED_X1) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m/src/state_extract_bytes_x1_armv7m.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm)
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_extract_bytes_asm)

        .cfi_startproc
        push.w {r4, r5, r6, r7, r8, lr}
        .cfi_adjust_cfa_offset 0x18
        .cfi_rel_offset r4, 0x0
        .cfi_rel_offset r5, 0x4
        .cfi_rel_offset r6, 0x8
        .cfi_rel_offset r7, 0xc
        .cfi_rel_offset r8, 0x10
        .cfi_rel_offset lr, 0x14
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_exit @ imm = #0x1f0
        bic r4, r2, #0x7
        adds r0, r0, r4
        ands r2, r2, #0x7
        beq Lmld_keccak_f1600_x1_state_extract_bytes_check_lanes @ imm = #0xaa
        movs r4, r3
        rsb.w r5, r2, #0x8
        cmp r4, r5
        ble Lmld_keccak_f1600_x1_state_extract_bytes_first_size_ready @ imm = #0x0
        movs r4, r5

Lmld_keccak_f1600_x1_state_extract_bytes_first_size_ready:
        sub.w r8, r3, r4
        movs r3, r4
        ldrd r4, r5, [r0], #8
        movs r6, r4
        bfi r4, r5, #16, #16
        bfc r5, #0, #16
        orr.w r5, r5, r6, lsr #16
        eor.w r6, r4, r4, lsr #8
        and r6, r6, #0xff00
        eors r4, r6
        eor.w r4, r4, r6, lsl #8
        eor.w r6, r4, r4, lsr #4
        and r6, r6, #0xf000f0
        eors r4, r6
        eor.w r4, r4, r6, lsl #4
        eor.w r6, r4, r4, lsr #2
        and r6, r6, #0xc0c0c0c
        eors r4, r6
        eor.w r4, r4, r6, lsl #2
        eor.w r6, r4, r4, lsr #1
        and r6, r6, #0x22222222
        eors r4, r6
        eor.w r4, r4, r6, lsl #1
        eor.w r6, r5, r5, lsr #8
        and r6, r6, #0xff00
        eors r5, r6
        eor.w r5, r5, r6, lsl #8
        eor.w r6, r5, r5, lsr #4
        and r6, r6, #0xf000f0
        eors r5, r6
        eor.w r5, r5, r6, lsl #4
        eor.w r6, r5, r5, lsr #2
        and r6, r6, #0xc0c0c0c
        eors r5, r6
        eor.w r5, r5, r6, lsl #2
        eor.w r6, r5, r5, lsr #1
        and r6, r6, #0x22222222
        eors r5, r6
        eor.w r5, r5, r6, lsl #1
        sub sp, #0x8
        .cfi_adjust_cfa_offset 0x8
        strd r4, r5, [sp]
        add r2, sp, r2

Lmld_keccak_f1600_x1_state_extract_bytes_first_loop:
        ldrb r4, [r2], #1
        subs r3, #0x1
        strb r4, [r1], #1
        bne Lmld_keccak_f1600_x1_state_extract_bytes_first_loop @ imm = #-0xe
        add sp, #0x8
        .cfi_adjust_cfa_offset -0x8
        mov r3, r8

Lmld_keccak_f1600_x1_state_extract_bytes_check_lanes:
        lsrs r2, r3, #0x3
        beq Lmld_keccak_f1600_x1_state_extract_bytes_check_tail @ imm = #0x92
        mov r8, r3

Lmld_keccak_f1600_x1_state_extract_bytes_lanes_loop:
        ldrd r4, r5, [r0], #8
        movs r3, r4
        bfi r4, r5, #16, #16
        bfc r5, #0, #16
        orr.w r5, r5, r3, lsr #16
        eor.w r3, r4, r4, lsr #8
        and r3, r3, #0xff00
        eors r4, r3
        eor.w r4, r4, r3, lsl #8
        eor.w r3, r4, r4, lsr #4
        and r3, r3, #0xf000f0
        eors r4, r3
        eor.w r4, r4, r3, lsl #4
        eor.w r3, r4, r4, lsr #2
        and r3, r3, #0xc0c0c0c
        eors r4, r3
        eor.w r4, r4, r3, lsl #2
        eor.w r3, r4, r4, lsr #1
        and r3, r3, #0x22222222
        eors r4, r3
        eor.w r4, r4, r3, lsl #1
        eor.w r3, r5, r5, lsr #8
        and r3, r3, #0xff00
        eors r5, r3
        eor.w r5, r5, r3, lsl #8
        eor.w r3, r5, r5, lsr #4
        and r3, r3, #0xf000f0
        eors r5, r3
        eor.w r5, r5, r3, lsl #4
        eor.w r3, r5, r5, lsr #2
        and r3, r3, #0xc0c0c0c
        eors r5, r3
        eor.w r5, r5, r3, lsl #2
        eor.w r3, r5, r5, lsr #1
        and r3, r3, #0x22222222
        eors r5, r3
        eor.w r5, r5, r3, lsl #1
        str r4, [r1], #4
        subs r2, #0x1
        str r5, [r1], #4
        bne Lmld_keccak_f1600_x1_state_extract_bytes_lanes_loop @ imm = #-0x90
        and r3, r8, #0x7

Lmld_keccak_f1600_x1_state_extract_bytes_check_tail:
        cmp r3, #0x0
        beq.w Lmld_keccak_f1600_x1_state_extract_bytes_exit @ imm = #0x9a
        movs r2, #0x0
        ldrd r4, r5, [r0], #8
        movs r6, r4
        bfi r4, r5, #16, #16
        bfc r5, #0, #16
        orr.w r5, r5, r6, lsr #16
        eor.w r6, r4, r4, lsr #8
        and r6, r6, #0xff00
        eors r4, r6
        eor.w r4, r4, r6, lsl #8
        eor.w r6, r4, r4, lsr #4
        and r6, r6, #0xf000f0
        eors r4, r6
        eor.w r4, r4, r6, lsl #4
        eor.w r6, r4, r4, lsr #2
        and r6, r6, #0xc0c0c0c
        eors r4, r6
        eor.w r4, r4, r6, lsl #2
        eor.w r6, r4, r4, lsr #1
        and r6, r6, #0x22222222
        eors r4, r6
        eor.w r4, r4, r6, lsl #1
        eor.w r6, r5, r5, lsr #8
        and r6, r6, #0xff00
        eors r5, r6
        eor.w r5, r5, r6, lsl #8
        eor.w r6, r5, r5, lsr #4
        and r6, r6, #0xf000f0
        eors r5, r6
        eor.w r5, r5, r6, lsl #4
        eor.w r6, r5, r5, lsr #2
        and r6, r6, #0xc0c0c0c
        eors r5, r6
        eor.w r5, r5, r6, lsl #2
        eor.w r6, r5, r5, lsr #1
        and r6, r6, #0x22222222
        eors r5, r6
        eor.w r5, r5, r6, lsl #1
        sub sp, #0x8
        .cfi_adjust_cfa_offset 0x8
        strd r4, r5, [sp]
        add r2, sp, r2

Lmld_keccak_f1600_x1_state_extract_bytes_tail_loop:
        ldrb r4, [r2], #1
        subs r3, #0x1
        strb r4, [r1], #1
        bne Lmld_keccak_f1600_x1_state_extract_bytes_tail_loop @ imm = #-0xe
        add sp, #0x8
        .cfi_adjust_cfa_offset -0x8

Lmld_keccak_f1600_x1_state_extract_bytes_exit:
        pop.w {r4, r5, r6, r7, r8, pc}
        .cfi_restore r4
        .cfi_restore r5
        .cfi_restore r6
        .cfi_restore r7
        .cfi_restore r8
        .cfi_restore lr
        .cfi_adjust_cfa_offset -0x18
        .cfi_endproc
        nop

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
