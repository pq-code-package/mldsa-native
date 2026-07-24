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
/* simpasm: header-end */

.thumb
.syntax unified
.text

/* Credit: Henry S. Warren, Hacker's Delight, Addison-Wesley, 2002. */
.macro fromBitInterleaving x0, x1, t
    movs    \t, \x0
    bfi     \x0, \x1, #16, #16
    bfc     \x1, #0, #16
    orr     \x1, \x1, \t, lsr #16

    eor     \t, \x0, \x0, lsr #8
    and     \t, #0x0000ff00
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, lsl #8

    eor     \t, \x0, \x0, lsr #4
    and     \t, #0x00f000f0
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, lsl #4

    eor     \t, \x0, \x0, lsr #2
    and     \t, #0x0c0c0c0c
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, lsl #2

    eor     \t, \x0, \x0, lsr #1
    and     \t, #0x22222222
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, lsl #1

    eor     \t, \x1, \x1, lsr #8
    and     \t, #0x0000ff00
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, lsl #8

    eor     \t, \x1, \x1, lsr #4
    and     \t, #0x00f000f0
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, lsl #4

    eor     \t, \x1, \x1, lsr #2
    and     \t, #0x0c0c0c0c
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, lsl #2

    eor     \t, \x1, \x1, lsr #1
    and     \t, #0x22222222
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, lsl #1
.endm

.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_extract_bytes_asm)
    /* Keep one prologue/epilogue path so generated CFI covers length == 0. */
    push    {r4-r8, lr}
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_exit

    bic     r4, r2, #7
    adds    r0, r0, r4
    ands    r2, r2, #7
    beq     mld_keccak_f1600_x1_state_extract_bytes_check_lanes

    /* Extract the portion before the first lane boundary. */
    movs    r4, r3
    rsb     r5, r2, #8
    cmp     r4, r5
    ble     mld_keccak_f1600_x1_state_extract_bytes_first_size_ready
    movs    r4, r5
mld_keccak_f1600_x1_state_extract_bytes_first_size_ready:
    sub     r8, r3, r4
    movs    r3, r4
    ldrd    r4, r5, [r0], #8
    fromBitInterleaving r4, r5, r6
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, sp, r2
mld_keccak_f1600_x1_state_extract_bytes_first_loop:
    ldrb    r4, [r2], #1
    subs    r3, r3, #1
    strb    r4, [r1], #1
    bne     mld_keccak_f1600_x1_state_extract_bytes_first_loop
    add     sp, #8
    mov     r3, r8

mld_keccak_f1600_x1_state_extract_bytes_check_lanes:
    lsrs    r2, r3, #3
    beq     mld_keccak_f1600_x1_state_extract_bytes_check_tail
    mov     r8, r3
mld_keccak_f1600_x1_state_extract_bytes_lanes_loop:
    ldrd    r4, r5, [r0], #8
    fromBitInterleaving r4, r5, r3
    str     r4, [r1], #4
    subs    r2, r2, #1
    str     r5, [r1], #4
    bne     mld_keccak_f1600_x1_state_extract_bytes_lanes_loop
    and     r3, r8, #7

mld_keccak_f1600_x1_state_extract_bytes_check_tail:
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_exit

    /* Extract the final partial lane. */
    movs    r2, #0
    ldrd    r4, r5, [r0], #8
    fromBitInterleaving r4, r5, r6
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, sp, r2
mld_keccak_f1600_x1_state_extract_bytes_tail_loop:
    ldrb    r4, [r2], #1
    subs    r3, r3, #1
    strb    r4, [r1], #1
    bne     mld_keccak_f1600_x1_state_extract_bytes_tail_loop
    add     sp, #8

mld_keccak_f1600_x1_state_extract_bytes_exit:
    pop     {r4-r8, pc}

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
