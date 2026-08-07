/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) 2026 Arm Limited
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * This helper is adapted from the Armv8.1-M MVE x1 byte-operation work in
 * mlkem-native. It converts two adjacent Keccak lanes at once between the
 * bit-interleaved x1 representation and bytes.
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
      permissions: read-only
      c_parameter: void *state
      description: Bit-interleaved x1 Keccak state, naturally aligned for 32-bit MVE state accesses
    r1:
      type: buffer
      size_bytes: r3
      permissions: write-only
      c_parameter: uint8_t *data
      description: Arbitrarily byte-aligned output bytes
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset within the first 192 state bytes; the C wrapper dispatches final-lane ranges to the scalar helper
      test_with: 7
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of output bytes such that offset plus length is at most 192
      test_with: 9
  Stack:
    bytes: 40
    description: AAPCS32 preservation of r4-r11 and lr; the MVE fast path uses only caller-saved q0-q3 and p0
*/

/*
 * AAPCS32 contract: preserves r4-r11, sp, and d8-d15/q4-q7. The caller-saved
 * r0-r3, r12, lr, APSR condition flags, q0-q3, and p0 may be clobbered.
 * The MVE fast path covers only byte ranges ending at or before state byte
 * 192, so each 16-byte state vector access remains within the 200-byte state.
 * The C wrapper dispatches ranges touching the final eight-byte lane to the
 * scalar helper.
 */

#include "../../../../common.h"

#if defined(MLD_FIPS202_ARMV81M_NEED_X1) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__ARM_FEATURE_MVE)
/* simpasm: header-end */

.thumb
.syntax unified
.text

/* Expand the compact even-bit representation into byte positions. */
.macro mld_keccak_x1_mve_deinterleave_even e, tmp, const4, const16
    vsli.u32    \e, \e, #8
    vsli.u16    \e, \e, #4
    vsli.u8     \e, \e, #1
    vqdmulh.s8  \tmp, \e, \const16
    vsli.u8     \e, \tmp, #4
    vqdmulh.s8  \tmp, \e, \const4
    vsli.u8     \e, \tmp, #6
.endm

/* q0: two bit-interleaved lanes; prepare their even and odd bit planes. */
.macro mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
    mov         \tmp, #0x0f0f
    vmsr        p0, \tmp
    vrev32.u16  q1, q0
    vrev64.u32  q2, q1
    vrev64.u32  q3, q0
    vpsel       q0, q0, q2
    vpsel       q1, q3, q1
.endm

/* Expand the prepared bit planes and merge them into byte-order lanes. */
.macro mld_keccak_x1_mve_finish_from_bit_interleaving tmp, const4, const16
    mld_keccak_x1_mve_deinterleave_even q0, q2, \const4, \const16
    mld_keccak_x1_mve_deinterleave_even q1, q2, \const4, \const16
    mov         \tmp, #0x55
    vdup.u8     q2, \tmp
    vand.u32    q0, q0, q2
    vand.u32    q1, q1, q2
    vshl.u32    q1, q1, #1
    vorr.u32    q0, q1, q0
.endm

.balign 8
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_extract_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_extract_bytes_asm)
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_exit

    push    {r4-r12, lr}

    state             .req r0
    dp                .req r1
    off_full          .req r2
    length            .req r3
    tmp               .req r4
    nbytes            .req lr
    off               .req r5
    const4            .req r6
    const16           .req r7
    state_pair_offset .req r9
    mask              .req r11
    qdata             .req q0

    mov     const4, #4
    mov     const16, #16
    and     off, off_full, #15
    bic     state_pair_offset, off_full, #15
    add     state, state, state_pair_offset

    /* Extract the first partial two-lane group, if any. */
    cmp     off, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_pre_main
    subs    dp, dp, off
    rsb     nbytes, off, #16
    cmp     length, nbytes
    it      ls
    movls   nbytes, length
    subs    length, length, nbytes
    vldrw.u32 qdata, [state], #16
    mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
    mld_keccak_x1_mve_finish_from_bit_interleaving tmp, const4, const16
    vctp.8  nbytes
    vmrs    mask, p0
    lsl     mask, mask, off
    vmsr    p0, mask
    vpst
    vstrbt.u8 qdata, [dp], #16
    cmp     length, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_restore

mld_keccak_f1600_x1_state_extract_bytes_mve_pre_main:
    lsr     nbytes, length, #4
    wls     nbytes, nbytes, mld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end
mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare:
    vldrw.u32 qdata, [state], #16
    mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_start:
    mld_keccak_x1_mve_finish_from_bit_interleaving tmp, const4, const16
    /* Byte vector stores keep the public data pointer alignment-independent. */
    vstrb.u8 qdata, [dp], #16
mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_end:
    le      nbytes, mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare
mld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end:
    ands    length, length, #15
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_restore

    vldrw.u32 qdata, [state]
    mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
    mld_keccak_x1_mve_finish_from_bit_interleaving tmp, const4, const16
    vctp.8  length
    vpst
    vstrbt.u8 qdata, [dp], #16

mld_keccak_f1600_x1_state_extract_bytes_mve_restore:
    pop     {r4-r12, lr}
mld_keccak_f1600_x1_state_extract_bytes_mve_exit:
    bx      lr

    .unreq state
    .unreq dp
    .unreq off_full
    .unreq length
    .unreq tmp
    .unreq nbytes
    .unreq off
    .unreq const4
    .unreq const16
    .unreq state_pair_offset
    .unreq mask
    .unreq qdata

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */
