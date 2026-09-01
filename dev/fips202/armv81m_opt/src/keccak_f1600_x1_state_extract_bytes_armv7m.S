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
  Name: keccak_f1600_x1_state_extract_bytes_asm
  Description: Extract bytes from an x1 Keccak state while converting touched lanes from the bit-interleaved Armv7-M representation
  Signature: void mld_keccak_f1600_x1_state_extract_bytes_asm(void *state, uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: []
    r0:
      type: buffer
      size_bytes: 200
      permissions: read-only
      c_parameter: void *state
      description: Bit-interleaved x1 Keccak state
    r1:
      type: buffer
      size_bytes: r3
      permissions: write-only
      c_parameter: uint8_t *data
      description: Output byte buffer
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset within the 200-byte state
      test_with: 7
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of output bytes
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
/* simpasm: header-end */

.thumb
.syntax unified
.text

/* Convert one lane from even/odd bit-interleaved form to little-endian bytes. */
.macro mld_keccak_x1_from_bit_interleaving x0, x1, t
    movs    \t, \x0
    bfi     \x0, \x1, #16, #16
    bfc     \x1, #0, #16
    orr     \x1, \x1, \t, LSR #16

    eor     \t, \x0, \x0, LSR #8
    and     \t, #0x0000FF00
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #8

    eor     \t, \x0, \x0, LSR #4
    and     \t, #0x00F000F0
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #4

    eor     \t, \x0, \x0, LSR #2
    and     \t, #0x0C0C0C0C
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #2

    eor     \t, \x0, \x0, LSR #1
    and     \t, #0x22222222
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #1

    eor     \t, \x1, \x1, LSR #8
    and     \t, #0x0000FF00
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #8

    eor     \t, \x1, \x1, LSR #4
    and     \t, #0x00F000F0
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #4

    eor     \t, \x1, \x1, LSR #2
    and     \t, #0x0C0C0C0C
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #2

    eor     \t, \x1, \x1, LSR #1
    and     \t, #0x22222222
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #1
.endm

.macro mld_keccak_x1_extract_lanes
mld_keccak_f1600_x1_state_extract_bytes_lanes_loop:
    ldrd    r4, r5, [r0], #8
    mld_keccak_x1_from_bit_interleaving r4, r5, r3
    str     r4, [r1], #4
    subs    r2, r2, #1
    str     r5, [r1], #4
    bne     mld_keccak_f1600_x1_state_extract_bytes_lanes_loop
.endm

.macro mld_keccak_x1_extract_bytes_in_lane label
    ldrd    r4, r5, [r0], #8
    mld_keccak_x1_from_bit_interleaving r4, r5, r6
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, sp, r2
mld_keccak_f1600_x1_state_extract_bytes_in_lane_loop_\label:
    ldrb    r4, [r2], #1
    subs    r3, r3, #1
    strb    r4, [r1], #1
    bne     mld_keccak_f1600_x1_state_extract_bytes_in_lane_loop_\label
    add     sp, #8
.endm

.align 8
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_extract_bytes_asm)
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_exit
    push    {r4-r8, lr}
    bic     r4, r2, #7
    adds    r0, r0, r4
    ands    r2, r2, #7
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_check_lanes
    movs    r4, r3
    rsb     r5, r2, #8
    cmp     r4, r5
    ble     mld_keccak_f1600_x1_state_extract_bytes_align
    movs    r4, r5
mld_keccak_f1600_x1_state_extract_bytes_align:
    sub     r8, r3, r4
    movs    r3, r4
    mld_keccak_x1_extract_bytes_in_lane first
    mov     r3, r8
mld_keccak_f1600_x1_state_extract_bytes_check_lanes:
    lsrs    r2, r3, #3
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_tail
    mov     r8, r3
    mld_keccak_x1_extract_lanes
    and     r3, r8, #7
mld_keccak_f1600_x1_state_extract_bytes_tail:
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_restore
    movs    r2, #0
    mld_keccak_x1_extract_bytes_in_lane tail
mld_keccak_f1600_x1_state_extract_bytes_restore:
    pop     {r4-r8, lr}
mld_keccak_f1600_x1_state_extract_bytes_exit:
    bx      lr

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
