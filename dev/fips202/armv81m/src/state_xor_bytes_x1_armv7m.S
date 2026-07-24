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
  Name: keccak_f1600_x1_state_xor_bytes_asm
  Description: Armv7-M byte absorption into a bit-interleaved x1 Keccak state
  Signature: void mld_keccak_f1600_x1_state_xor_bytes_asm(void *state, const uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    r0:
      type: buffer
      size_bytes: 200
      permissions: read/write
      c_parameter: void *state
      description: Bit-interleaved x1 state as even/odd 32-bit halves for each Keccak lane
    r1:
      type: buffer
      size_bytes: r3
      permissions: read-only
      c_parameter: const uint8_t *data
      description: Input bytes XORed into the state
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset into the 200-byte logical Keccak state
      test_with: 3
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of input bytes; offset plus length must not exceed 200
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
.macro toBitInterleaving x0, x1, s0, s1, t, over
    and     \t, \x0, #0x55555555
    orr     \t, \t, \t, lsr #1
    and     \t, \t, #0x33333333
    orr     \t, \t, \t, lsr #2
    and     \t, \t, #0x0f0f0f0f
    orr     \t, \t, \t, lsr #4
    and     \t, \t, #0x00ff00ff
    bfi     \t, \t, #8, #8
    .if \over != 0
    lsr     \s0, \t, #8
    .else
    eor     \s0, \s0, \t, lsr #8
    .endif

    and     \t, \x1, #0x55555555
    orr     \t, \t, \t, lsr #1
    and     \t, \t, #0x33333333
    orr     \t, \t, \t, lsr #2
    and     \t, \t, #0x0f0f0f0f
    orr     \t, \t, \t, lsr #4
    and     \t, \t, #0x00ff00ff
    orr     \t, \t, \t, lsr #8
    eor     \s0, \s0, \t, lsl #16

    and     \t, \x0, #0xaaaaaaaa
    orr     \t, \t, \t, lsl #1
    and     \t, \t, #0xcccccccc
    orr     \t, \t, \t, lsl #2
    and     \t, \t, #0xf0f0f0f0
    orr     \t, \t, \t, lsl #4
    and     \t, \t, #0xff00ff00
    orr     \t, \t, \t, lsl #8
    .if \over != 0
    lsr     \s1, \t, #16
    .else
    eor     \s1, \s1, \t, lsr #16
    .endif

    and     \t, \x1, #0xaaaaaaaa
    orr     \t, \t, \t, lsl #1
    and     \t, \t, #0xcccccccc
    orr     \t, \t, \t, lsl #2
    and     \t, \t, #0xf0f0f0f0
    orr     \t, \t, \t, lsl #4
    and     \t, \t, #0xff00ff00
    orr     \t, \t, \t, lsl #8
    bfc     \t, #0, #16
    eors    \s1, \s1, \t
.endm

.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_xor_bytes_asm)
    /* Keep one prologue/epilogue path so generated CFI covers length == 0. */
    push    {r4-r8, lr}
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_exit

    bic     r4, r2, #7
    adds    r0, r0, r4
    ands    r2, r2, #7
    beq     mld_keccak_f1600_x1_state_xor_bytes_check_lanes

    /* Absorb the portion before the first lane boundary. */
    movs    r4, r3
    rsb     r5, r2, #8
    cmp     r4, r5
    ble     mld_keccak_f1600_x1_state_xor_bytes_first_size_ready
    movs    r4, r5
mld_keccak_f1600_x1_state_xor_bytes_first_size_ready:
    sub     r8, r3, r4
    movs    r3, r4
    movs    r4, #0
    movs    r5, #0
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, r2, sp
mld_keccak_f1600_x1_state_xor_bytes_first_loop:
    ldrb    r5, [r1], #1
    strb    r5, [r2], #1
    subs    r3, r3, #1
    bne     mld_keccak_f1600_x1_state_xor_bytes_first_loop
    ldrd    r4, r5, [sp]
    add     sp, #8
    ldrd    r6, r7, [r0]
    toBitInterleaving r4, r5, r6, r7, r3, 0
    strd    r6, r7, [r0], #8
    mov     r3, r8

mld_keccak_f1600_x1_state_xor_bytes_check_lanes:
    lsrs    r2, r3, #3
    beq     mld_keccak_f1600_x1_state_xor_bytes_check_tail
    mov     r8, r3
mld_keccak_f1600_x1_state_xor_bytes_lanes_loop:
    ldr     r4, [r1], #4
    ldr     r5, [r1], #4
    ldrd    r6, r7, [r0]
    toBitInterleaving r4, r5, r6, r7, r3, 0
    strd    r6, r7, [r0], #8
    subs    r2, r2, #1
    bne     mld_keccak_f1600_x1_state_xor_bytes_lanes_loop
    and     r3, r8, #7

mld_keccak_f1600_x1_state_xor_bytes_check_tail:
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_exit

    /* Absorb the final partial lane. */
    movs    r2, #0
    movs    r4, #0
    movs    r5, #0
    sub     sp, #8
    strd    r4, r5, [sp]
    add     r2, r2, sp
mld_keccak_f1600_x1_state_xor_bytes_tail_loop:
    ldrb    r5, [r1], #1
    strb    r5, [r2], #1
    subs    r3, r3, #1
    bne     mld_keccak_f1600_x1_state_xor_bytes_tail_loop
    ldrd    r4, r5, [sp]
    add     sp, #8
    ldrd    r6, r7, [r0]
    toBitInterleaving r4, r5, r6, r7, r3, 0
    strd    r6, r7, [r0], #8

mld_keccak_f1600_x1_state_xor_bytes_exit:
    pop     {r4-r8, pc}

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_xor_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
