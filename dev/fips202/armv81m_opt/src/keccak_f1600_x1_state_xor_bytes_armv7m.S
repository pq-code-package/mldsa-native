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
/* simpasm: header-end */

.thumb
.syntax unified
.text

/* Convert one little-endian lane to the even/odd bit-interleaved form. */
.macro mld_keccak_x1_to_bit_interleaving x0, x1, s0, s1, t, over
    and     \t, \x0, #0x55555555
    orr     \t, \t, \t, LSR #1
    and     \t, \t, #0x33333333
    orr     \t, \t, \t, LSR #2
    and     \t, \t, #0x0F0F0F0F
    orr     \t, \t, \t, LSR #4
    and     \t, \t, #0x00FF00FF
    bfi     \t, \t, #8, #8
    .if \over != 0
    lsr     \s0, \t, #8
    .else
    eor     \s0, \s0, \t, LSR #8
    .endif

    and     \t, \x1, #0x55555555
    orr     \t, \t, \t, LSR #1
    and     \t, \t, #0x33333333
    orr     \t, \t, \t, LSR #2
    and     \t, \t, #0x0F0F0F0F
    orr     \t, \t, \t, LSR #4
    and     \t, \t, #0x00FF00FF
    orr     \t, \t, \t, LSR #8
    eor     \s0, \s0, \t, LSL #16

    and     \t, \x0, #0xAAAAAAAA
    orr     \t, \t, \t, LSL #1
    and     \t, \t, #0xCCCCCCCC
    orr     \t, \t, \t, LSL #2
    and     \t, \t, #0xF0F0F0F0
    orr     \t, \t, \t, LSL #4
    and     \t, \t, #0xFF00FF00
    orr     \t, \t, \t, LSL #8
    .if \over != 0
    lsr     \s1, \t, #16
    .else
    eor     \s1, \s1, \t, LSR #16
    .endif

    and     \t, \x1, #0xAAAAAAAA
    orr     \t, \t, \t, LSL #1
    and     \t, \t, #0xCCCCCCCC
    orr     \t, \t, \t, LSL #2
    and     \t, \t, #0xF0F0F0F0
    orr     \t, \t, \t, LSL #4
    and     \t, \t, #0xFF00FF00
    orr     \t, \t, \t, LSL #8
    bfc     \t, #0, #16
    eors    \s1, \s1, \t
.endm

.macro mld_keccak_x1_xor_lanes
mld_keccak_f1600_x1_state_xor_bytes_lanes_loop:
    ldr     r4, [r1], #4
    ldr     r5, [r1], #4
    ldrd    r6, r7, [r0]
    mld_keccak_x1_to_bit_interleaving r4, r5, r6, r7, r3, 0
    strd    r6, r7, [r0], #8
    subs    r2, r2, #1
    bne     mld_keccak_f1600_x1_state_xor_bytes_lanes_loop
.endm

.macro mld_keccak_x1_xor_bytes_in_lane label
    movs    r4, #0
    movs    r5, #0
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, r2, sp
mld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_\label:
    ldrb    r5, [r1], #1
    strb    r5, [r2], #1
    subs    r3, r3, #1
    bne     mld_keccak_f1600_x1_state_xor_bytes_in_lane_loop_\label
    ldrd    r4, r5, [sp]
    add     sp, #8
    ldrd    r6, r7, [r0]
    mld_keccak_x1_to_bit_interleaving r4, r5, r6, r7, r3, 0
    strd    r6, r7, [r0], #8
.endm

.align 8
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_xor_bytes_asm)
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_exit
    push    {r4-r8, lr}
    bic     r4, r2, #7
    adds    r0, r0, r4
    ands    r2, r2, #7
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_check_lanes
    movs    r4, r3
    rsb     r5, r2, #8
    cmp     r4, r5
    ble     mld_keccak_f1600_x1_state_xor_bytes_align
    movs    r4, r5
mld_keccak_f1600_x1_state_xor_bytes_align:
    sub     r8, r3, r4
    movs    r3, r4
    mld_keccak_x1_xor_bytes_in_lane first
    mov     r3, r8
mld_keccak_f1600_x1_state_xor_bytes_check_lanes:
    lsrs    r2, r3, #3
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_tail
    mov     r8, r3
    mld_keccak_x1_xor_lanes
    and     r3, r8, #7
mld_keccak_f1600_x1_state_xor_bytes_tail:
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_restore
    movs    r2, #0
    mld_keccak_x1_xor_bytes_in_lane tail
mld_keccak_f1600_x1_state_xor_bytes_restore:
    pop     {r4-r8, lr}
mld_keccak_f1600_x1_state_xor_bytes_exit:
    bx      lr

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_xor_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
