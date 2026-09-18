/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) 2026 Arm Limited
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * This helper is adapted from mlkem-native commit
 * fc76e8bc6e9a9a2f72941093745c715394bec331, files
 * mlkem/src/fips202/native/armv81m/src/state_xor_bytes_x1_mve_asm.S and
 * state_extract_bytes_x1_mve_asm.S. Those files are copyright the
 * mlkem-native and mldsa-native project authors and Arm Limited, and are
 * available under Apache-2.0 OR ISC OR MIT. It converts two adjacent Keccak
 * lanes at once between bytes and the bit-interleaved x1 representation.
 */

/*yaml
  Name: keccak_f1600_x1_state_xor_bytes_asm
  Description: Armv8.1-M MVE fast path for XORing bytes into an x1 bit-interleaved Keccak state
  Signature: void mld_keccak_f1600_x1_state_xor_bytes_asm(void *state, const uint8_t *data, unsigned offset, unsigned length)
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: [MVE]
    r0:
      type: buffer
      size_bytes: 200
      alignment_bytes: 8
      permissions: read/write
      c_parameter: void *state
      description: Bit-interleaved x1 Keccak state, naturally aligned for 32-bit MVE state accesses
    r1:
      type: buffer
      size_bytes: r3
      alignment_bytes: 1
      permissions: read-only
      c_parameter: const uint8_t *data
      description: Arbitrarily byte-aligned input bytes to XOR into the state
    r2:
      type: scalar
      c_parameter: unsigned offset
      description: Byte offset within the 200-byte Keccak state
      test_with: 192
    r3:
      type: scalar
      c_parameter: unsigned length
      description: Number of input bytes such that offset plus length is at most 200
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

/* Compact the even bits of each element into the low half. */
.macro mld_keccak_x1_mve_interleave_evens t, u, const8, const16, const32, const128, const32768
    vqdmulh.s8  \u, \t, \const32
    vsli.u8     \t, \u, #1
    vqdmulh.s8  \u, \t, \const16
    vsli.u8     \t, \u, #2
    vqdmulh.s8  \u, \t, \const8
    vsli.u8     \t, \u, #3
    vqdmulh.s16 \u, \t, \const128
    vsli.u8     \t, \u, #4
    vqdmulh.s32 \u, \t, \const32768
    vsli.u16    \t, \u, #8
.endm

/* q0: two byte-order lanes; result: their bit-interleaved representation. */
.macro mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    vshr.u32 q1, q0, #1
    mld_keccak_x1_mve_interleave_evens q1, q2, \const8, \const16, \const32, \const128, \const32768
    vrev64.u32 q2, q1
    vsli.u32 q2, q1, #16
    mld_keccak_x1_mve_interleave_evens q0, q3, \const8, \const16, \const32, \const128, \const32768
    vrev64.u32 q3, q0
    vsli.u32 q0, q3, #16
.endm

/* Kept outside the SLOTHY region: the pinned parser has no VMSR/VPSEL
 * predicate-instruction support. */
.macro mld_keccak_x1_mve_select_bit_planes tmp
    mov \tmp, #0x0f0f
    vmsr p0, \tmp
    vpsel q0, q0, q2
.endm

.balign 8
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_state_xor_bytes_asm), %function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_state_xor_bytes_asm)
    cmp     r3, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_exit

    push    {r4-r12, lr}

    state             .req r0
    dp                .req r1
    off_full          .req r2
    length            .req r3
    tmp               .req r4
    off               .req r5
    state_pair_offset .req r6
    state_tail        .req r7
    const8            .req r8
    const16           .req r9
    const32           .req r10
    const128          .req r11
    const32768        .req r12
    nbytes            .req lr
    qdata             .req q0
    qstate            .req q1
    dstate            .req d2
    dstate_hi         .req d3

    mov     const8, #8
    mov     const16, #16
    mov     const32, #32
    mov     const128, #128
    mov     const32768, #32768
    add     state_tail, state, #176

    and     off, off_full, #15
    bic     state_pair_offset, off_full, #15
    add     state, state, state_pair_offset

    /* Absorb the first partial two-lane group, if any. */
    cmp     off, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_pre_main
    subs    dp, dp, off
    rsb     nbytes, off, #16
    cmp     length, nbytes
    it      ls
    movls   nbytes, length
    subs    length, length, nbytes
    vctp.8  nbytes
    vmrs    tmp, p0
    lsl     tmp, tmp, off
    vmsr    p0, tmp
    vpst
    vldrbt.u8 qdata, [dp], #16
    mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    mld_keccak_x1_mve_select_bit_planes tmp
    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_xor_bytes_mve_first_state_tail
    vldrw.u32 qstate, [state]
    veor    qstate, qstate, qdata
    vstrw.u32 qstate, [state], #16
    b.w     mld_keccak_f1600_x1_state_xor_bytes_mve_first_done

mld_keccak_f1600_x1_state_xor_bytes_mve_first_state_tail:
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_first_penultimate_lane
    vldr    dstate, [state]
    veor    qstate, qstate, qdata
    vstr    dstate, [state]
    add     state, state, #16
    b.w     mld_keccak_f1600_x1_state_xor_bytes_mve_first_done

mld_keccak_f1600_x1_state_xor_bytes_mve_first_penultimate_lane:
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]
    veor    qstate, qstate, qdata
    vstr    dstate, [state]
    vstr    dstate_hi, [state, #8]
    add     state, state, #16

mld_keccak_f1600_x1_state_xor_bytes_mve_first_done:
    cmp     length, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_restore

mld_keccak_f1600_x1_state_xor_bytes_mve_pre_main:
    lsr     nbytes, length, #4
    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_xor_bytes_mve_main_loop_end
    sub     tmp, state_tail, state
    lsr     tmp, tmp, #4
    cmp     nbytes, tmp
    it      hi
    movhi   nbytes, tmp
    lsl     tmp, nbytes, #4
    sub     length, length, tmp
    wls     nbytes, nbytes, mld_keccak_f1600_x1_state_xor_bytes_mve_main_loop_end
        mld_keccak_f1600_x1_state_xor_bytes_mve_slothy_start:
                                       // Instructions:    26
                                       // Expected cycles: 26
                                       // Expected IPC:    1.00
                                       //
                                       // ----- cycle (expected) ------>
                                       // 0                        25
                                       // |------------------------|----
        vldrb.U8 q0, [r1], #16         // *.............................
        vshr.U32 q3, q0, #1            // .*............................
        vqdmulh.S8 q1, q3, r10         // ..*...........................
        vsli.U8 q3, q1, #1             // ...*..........................
        vqdmulh.S8 q2, q3, r9          // ....*.........................
        vsli.U8 q3, q2, #2             // .....*........................
        vqdmulh.S8 q2, q3, r8          // ......*.......................
        vsli.U8 q3, q2, #3             // .......*......................
        vqdmulh.S16 q2, q3, r11        // ........*.....................
        vsli.U8 q3, q2, #4             // .........*....................
        vqdmulh.S32 q2, q3, r12        // ..........*...................
        vsli.U16 q3, q2, #8            // ...........*..................
        vrev64.U32 q2, q3              // ............*.................
        vqdmulh.S8 q1, q0, r10         // .............*................
        vsli.U32 q2, q3, #16           // ..............*...............
        vsli.U8 q0, q1, #1             // ...............*..............
        vqdmulh.S8 q3, q0, r9          // ................*.............
        vsli.U8 q0, q3, #2             // .................*............
        vqdmulh.S8 q3, q0, r8          // ..................*...........
        vsli.U8 q0, q3, #3             // ...................*..........
        vqdmulh.S16 q3, q0, r11        // ....................*.........
        vsli.U8 q0, q3, #4             // .....................*........
        vqdmulh.S32 q3, q0, r12        // ......................*.......
        vsli.U16 q0, q3, #8            // .......................*......
        vrev64.U32 q3, q0              // ........................*.....
        vsli.U32 q0, q3, #16           // .........................*....

                                                // ------ cycle (expected) ------>
                                                // 0                        25
                                                // |------------------------|-----
        // vldrb.U8 q0, [r1], #16               // *..............................
        // vshr.U32 q3, q0, #1                  // .*.............................
        // vqdmulh.S8 q1, q3, r10               // ..*............................
        // vsli.U8 q3, q1, #1                   // ...*...........................
        // vqdmulh.S8 q1, q3, r9                // ....*..........................
        // vsli.U8 q3, q1, #2                   // .....*.........................
        // vqdmulh.S8 q1, q3, r8                // ......*........................
        // vsli.U8 q3, q1, #3                   // .......*.......................
        // vqdmulh.S16 q1, q3, r11              // ........*......................
        // vsli.U8 q3, q1, #4                   // .........*.....................
        // vqdmulh.S32 q1, q3, r12              // ..........*....................
        // vsli.U16 q3, q1, #8                  // ...........*...................
        // vrev64.U32 q2, q3                    // ............*..................
        // vsli.U32 q2, q3, #16                 // ..............*................
        // vqdmulh.S8 q3, q0, r10               // .............*.................
        // vsli.U8 q0, q3, #1                   // ...............*...............
        // vqdmulh.S8 q3, q0, r9                // ................*..............
        // vsli.U8 q0, q3, #2                   // .................*.............
        // vqdmulh.S8 q3, q0, r8                // ..................*............
        // vsli.U8 q0, q3, #3                   // ...................*...........
        // vqdmulh.S16 q3, q0, r11              // ....................*..........
        // vsli.U8 q0, q3, #4                   // .....................*.........
        // vqdmulh.S32 q1, q0, r12              // ......................*........
        // vsli.U16 q0, q1, #8                  // .......................*.......
        // vrev64.U32 q3, q0                    // ........................*......
        // vsli.U32 q0, q3, #16                 // .........................*.....

        mld_keccak_f1600_x1_state_xor_bytes_mve_slothy_end:


    mld_keccak_x1_mve_select_bit_planes tmp
    vldrw.u32 qstate, [state]
    veor    qstate, qstate, qdata
    vstrw.u32 qstate, [state], #16
    le      nbytes, mld_keccak_f1600_x1_state_xor_bytes_mve_slothy_start
mld_keccak_f1600_x1_state_xor_bytes_mve_main_loop_end:
    cmp     length, #0
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_restore

    cmp     state, state_tail
    bhs.w   mld_keccak_f1600_x1_state_xor_bytes_mve_tail_state_tail

    vctp.8  length
    vpst
    vldrbt.u8 qdata, [dp], #16
    mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    mld_keccak_x1_mve_select_bit_planes tmp
    vldrw.u32 qstate, [state]
    veor    qstate, qstate, qdata
    vstrw.u32 qstate, [state]
    b.w     mld_keccak_f1600_x1_state_xor_bytes_mve_restore

mld_keccak_f1600_x1_state_xor_bytes_mve_tail_state_tail:
    beq.w   mld_keccak_f1600_x1_state_xor_bytes_mve_tail_penultimate_lane

mld_keccak_f1600_x1_state_xor_bytes_mve_tail_final_lane:
    vctp.8  length
    vpst
    vldrbt.u8 qdata, [dp], #16
    mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    mld_keccak_x1_mve_select_bit_planes tmp
    vldr    dstate, [state]
    veor    qstate, qstate, qdata
    vstr    dstate, [state]
    b.w     mld_keccak_f1600_x1_state_xor_bytes_mve_restore

mld_keccak_f1600_x1_state_xor_bytes_mve_tail_penultimate_lane:
    cmp     length, #16
    blo.w   mld_keccak_f1600_x1_state_xor_bytes_mve_tail_penultimate_partial
    vldrb.u8 qdata, [dp], #16
    subs    length, length, #16
    mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    mld_keccak_x1_mve_select_bit_planes tmp
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]
    veor    qstate, qstate, qdata
    vstr    dstate, [state]
    vstr    dstate_hi, [state, #8]
    add     state, state, #16
    cmp     length, #0
    bne.w   mld_keccak_f1600_x1_state_xor_bytes_mve_tail_final_lane
    b.w     mld_keccak_f1600_x1_state_xor_bytes_mve_restore

mld_keccak_f1600_x1_state_xor_bytes_mve_tail_penultimate_partial:
    vctp.8  length
    vpst
    vldrbt.u8 qdata, [dp], #16
    mld_keccak_x1_mve_to_bit_interleaving tmp, const8, const16, const32, const128, const32768
    mld_keccak_x1_mve_select_bit_planes tmp
    vldr    dstate, [state]
    vldr    dstate_hi, [state, #8]
    veor    qstate, qstate, qdata
    vstr    dstate, [state]
    vstr    dstate_hi, [state, #8]

mld_keccak_f1600_x1_state_xor_bytes_mve_restore:
    pop     {r4-r12, lr}
mld_keccak_f1600_x1_state_xor_bytes_mve_exit:
    bx      lr

    .unreq state
    .unreq dp
    .unreq off_full
    .unreq length
    .unreq tmp
    .unreq off
    .unreq state_pair_offset
    .unreq state_tail
    .unreq const8
    .unreq const16
    .unreq const32
    .unreq const128
    .unreq const32768
    .unreq nbytes
    .unreq qdata
    .unreq qstate
    .unreq dstate
    .unreq dstate_hi

MLD_ASM_FN_SIZE(keccak_f1600_x1_state_xor_bytes_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */
