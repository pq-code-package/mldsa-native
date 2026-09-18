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
    state_tail        .req r8
    state_pair_offset .req r9
    mask              .req r11
    qdata             .req q0
    dstate            .req d0
    dstate_hi         .req d1

    mov     const4, #4
    mov     const16, #16
    add     state_tail, state, #176
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
    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_extract_bytes_mve_first_state_tail
    vldrw.u32 qdata, [state], #16
    b.w     mld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded

mld_keccak_f1600_x1_state_extract_bytes_mve_first_state_tail:
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_first_penultimate_lane
    vldr    dstate, [state]
    add     state, state, #16
    b.w     mld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded

mld_keccak_f1600_x1_state_extract_bytes_mve_first_penultimate_lane:
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]
    add     state, state, #16

mld_keccak_f1600_x1_state_extract_bytes_mve_first_loaded:
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
    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end
    sub     tmp, state_tail, state
    lsr     tmp, tmp, #4
    cmp     nbytes, tmp
    it      hi
    movhi   nbytes, tmp
    lsl     tmp, nbytes, #4
    sub     length, length, tmp
    wls     nbytes, nbytes, mld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end
mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare:
    vldrw.u32 qdata, [state], #16
    mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
        mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_start:
                                      // Instructions:    21
                                      // Expected cycles: 21
                                      // Expected IPC:    1.00
                                      //
                                      // ----- cycle (expected) ------>
                                      // 0                        25
                                      // |------------------------|----
        vsli.U32 q0, q0, #8           // *.............................
        vsli.U16 q0, q0, #4           // .*............................
        vsli.U8 q0, q0, #1            // ..*...........................
        vqdmulh.S8 q3, q0, r7         // ...*..........................
        vsli.U8 q0, q3, #4            // ....*.........................
        vqdmulh.S8 q2, q0, r6         // .....*........................
        vsli.U32 q1, q1, #8           // ......*.......................
        vsli.U8 q0, q2, #6            // .......*......................
        vsli.U16 q1, q1, #4           // ........*.....................
        vsli.U8 q1, q1, #1            // .........*....................
        vqdmulh.S8 q2, q1, r7         // ..........*...................
        vsli.U8 q1, q2, #4            // ...........*..................
        vqdmulh.S8 q3, q1, r6         // ............*.................
        vsli.U8 q1, q3, #6            // .............*................
        mov r2, #0x55                 // ..............*...............
        vdup.U8 q3, r2                // ...............*..............
        vand.U32 q2, q0, q3           // ................*.............
        vand.U32 q3, q1, q3           // .................*............
        vshl.U32 q1, q3, #1           // ..................*...........
        vorr.U32 q0, q1, q2           // ...................*..........
        vstrb.U8 q0, [r1], #16        // ....................*.........

                                               // ------ cycle (expected) ------>
                                               // 0                        25
                                               // |------------------------|-----
        // vsli.U32 q0, q0, #8                 // *..............................
        // vsli.U16 q0, q0, #4                 // .*.............................
        // vsli.U8 q0, q0, #1                  // ..*............................
        // vqdmulh.S8 q3, q0, r7               // ...*...........................
        // vsli.U8 q0, q3, #4                  // ....*..........................
        // vqdmulh.S8 q3, q0, r6               // .....*.........................
        // vsli.U8 q0, q3, #6                  // .......*.......................
        // vsli.U32 q1, q1, #8                 // ......*........................
        // vsli.U16 q1, q1, #4                 // ........*......................
        // vsli.U8 q1, q1, #1                  // .........*.....................
        // vqdmulh.S8 q3, q1, r7               // ..........*....................
        // vsli.U8 q1, q3, #4                  // ...........*...................
        // vqdmulh.S8 q3, q1, r6               // ............*..................
        // vsli.U8 q1, q3, #6                  // .............*.................
        // mov r2, #0x55                       // ..............*................
        // vdup.U8 q3, r2                      // ...............*...............
        // vand.U32 q2, q0, q3                 // ................*..............
        // vand.U32 q1, q1, q3                 // .................*.............
        // vshl.U32 q1, q1, #1                 // ..................*............
        // vorr.U32 q0, q1, q2                 // ...................*...........
        // vstrb.U8 q0, [r1], #16              // ....................*..........

        mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_end:


    le      nbytes, mld_keccak_f1600_x1_state_extract_bytes_mve_slothy_prepare
mld_keccak_f1600_x1_state_extract_bytes_mve_main_loop_end:
    cmp     length, #0
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_restore

    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_extract_bytes_mve_tail_state_tail
    vldrw.u32 qdata, [state]
    b.w     mld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded

mld_keccak_f1600_x1_state_extract_bytes_mve_tail_state_tail:
    beq.w   mld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_lane

mld_keccak_f1600_x1_state_extract_bytes_mve_tail_final_lane:
    vldr    dstate, [state]
    b.w     mld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded

mld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_lane:
    cmp     length, #16
    blo.w   mld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_partial
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]
    mld_keccak_x1_mve_prepare_from_bit_interleaving tmp
    mld_keccak_x1_mve_finish_from_bit_interleaving tmp, const4, const16
    vstrb.u8 qdata, [dp], #16
    add     state, state, #16
    subs    length, length, #16
    bne.w   mld_keccak_f1600_x1_state_extract_bytes_mve_tail_final_lane
    b.w     mld_keccak_f1600_x1_state_extract_bytes_mve_restore

mld_keccak_f1600_x1_state_extract_bytes_mve_tail_penultimate_partial:
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]

mld_keccak_f1600_x1_state_extract_bytes_mve_tail_loaded:
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
    .unreq state_tail
    .unreq state_pair_offset
    .unreq mask
    .unreq qdata
    .unreq dstate
    .unreq dstate_hi

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_extract_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */
