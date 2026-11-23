/*
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) The mlkem-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: rej_uniform_eta2_aarch64_asm
  Description: AArch64 rejection sampling of eta=2 secret coefficients
  Signature: uint64_t mld_rej_uniform_eta2_aarch64_asm(int32_t r[256], const uint8_t *buf, uint64_t buflen, const uint8_t table[4096])
  ABI:
    Architecture: aarch64
    CallingConvention: AAPCS64
    Features: [NEON]
    x0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t r[256]
      description: Output buffer, disjoint from buf and table. The return value is its valid prefix length.
    x1:
      type: buffer
      size_bytes: x2
      permissions: read-only
      c_parameter: const uint8_t *buf
      description: Input buffer
    x2:
      type: scalar
      c_parameter: uint64_t buflen
      description: Length of input buffer (must be a positive multiple of 8)
      test_with: 136  # MLD_AARCH64_REJ_UNIFORM_ETA2_BUFLEN
    x3:
      type: buffer
      size_bytes: 4096
      permissions: read-only
      c_parameter: const uint8_t table[4096]
      description: Lookup table (4096 x uint8_t)
*/

#include "../../../common.h"
#if defined(MLD_SYS_AARCH64_NEON) && \
    defined(MLD_ARITH_BACKEND_AARCH64) && \
    !defined(MLD_CONFIG_NO_KEYPAIR_API) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_ETA == 2)
/* simpasm: header-end */

    // For each nibble t < 15, append 2 - (t % 5) to r. Stop at MLDSA_N
    // coefficients or the end of the input, and return the number accepted.
    output          .req x0
    return_count    .req x0
    buf             .req x1
    buflen          .req x2
    table           .req x3
    remaining       .req x4
    tmp             .req x5
    groups          .req x6
    dst             .req x7
    packed0         .req x12
    packed1         .req x13
    mask0           .req x14
    mask1           .req x15
    count0          .req x12
    count1          .req x13

    bytes           .req v0
    mod5            .req v1
    low             .req v2
    high            .req v3
    valid0          .req v4
    valid1          .req v5
    nibbles         .req v6
    eta             .req v7
    lo0             .req v16
    lo0q            .req q16
    lo0d            .req d16
    lo0s            .req s16
    hi0             .req v17
    hi0q            .req q17
    lo1             .req v18
    lo1q            .req q18
    hi1             .req v19
    hi1q            .req q19
    sum0            .req s20
    sum0_d          .req d20
    sum1            .req s21
    sum1_d          .req d21
    shuffle0        .req v24
    shuffle0q       .req q24
    shuffle1        .req v25
    shuffle1q       .req q25
    nibble_mask     .req v29
    bound           .req v30
    weights         .req v31

    .text
    .global MLD_ASM_NAMESPACE(rej_uniform_eta2_aarch64_asm)
    .balign 4
MLD_ASM_FN_SYMBOL(rej_uniform_eta2_aarch64_asm)
    // Halfword i holds 1 in the high byte and 1 << i in the low byte.
    movz    tmp, #0x101
    movk    tmp, #0x102, lsl #16
    movk    tmp, #0x104, lsl #32
    movk    tmp, #0x108, lsl #48
    mov     weights.d[0], tmp
    movz    tmp, #0x110
    movk    tmp, #0x120, lsl #16
    movk    tmp, #0x140, lsl #32
    movk    tmp, #0x180, lsl #48
    mov     weights.d[1], tmp

    // The nibble t indexes mod5.16b to obtain t % 5.
    // mod5.16b = [0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0].
    movz    tmp, #0x0100
    movk    tmp, #0x0302, lsl #16
    movk    tmp, #0x0004, lsl #32
    movk    tmp, #0x0201, lsl #48
    mov     mod5.d[0], tmp
    movz    tmp, #0x0403
    movk    tmp, #0x0100, lsl #16
    movk    tmp, #0x0302, lsl #32
    movk    tmp, #0x0004, lsl #48
    mov     mod5.d[1], tmp
    movi    bound.16b, #15
    movi    eta.8h, #2
    movi    nibble_mask.8b, #15
    // remaining counts the free coefficient slots starting at output.
    mov     remaining, #MLDSA_N

mld_rej_uniform_eta2_loop:
    // Group 0 takes bytes 0..3 and group 1 takes bytes 4..7, low nibble first.
    ld1     {bytes.8b}, [buf], #8
    and     low.8b, bytes.8b, nibble_mask.8b
    ushr    high.8b, bytes.8b, #4
    zip1    nibbles.16b, low.16b, high.16b

    // For each group of eight, the acceptance mask selects the shuffle row
    // and the accepted count tells us how far to advance output.
    // CMHI sets each byte to 0xff if its nibble is below bound, else 0.
    cmhi    valid0.16b, bound.16b, nibbles.16b
    // Widen each mask to 0xffff or 0 so it covers both bytes of a weight.
    // Take lanes 8..15 into valid1 before widening lanes 0..7 in place.
    sxtl2   valid1.8h, valid0.16b
    sxtl    valid0.8h, valid0.8b

    // AND selects the byte pair (1, 1 << i) for accepted lane i and
    // (0, 0) otherwise. UADDLV sums the pairs to give (count, mask).
    // Each lane has a distinct mask bit, so there is no carry into the count.
    // Lanes 0 and 2 alone give (1, 0x01) + (1, 0x04) = (2, 0x05).
    and     valid0.16b, valid0.16b, weights.16b
    and     valid1.16b, valid1.16b, weights.16b
    uaddlv  sum0, valid0.8h
    uaddlv  sum1, valid1.8h
    // Copy each packed sum from its SIMD register into an integer register.
    fmov    packed0, sum0_d
    fmov    packed1, sum1_d
    and     mask0, packed0, #255
    and     mask1, packed1, #255
    lsr     count0, packed0, #8
    lsr     count1, packed1, #8

    // Each row lists the two byte indices of each accepted halfword in order.
    // Mask 0x05 gives [0, 1, 4, 5, 0xff, ...]. TBL zeroes the padding.
    ldr     shuffle0q, [table, mask0, lsl #4]
    ldr     shuffle1q, [table, mask1, lsl #4]

    // Reduce t modulo 5 after testing the original nibble for acceptance.
    tbl     nibbles.16b, {mod5.16b}, nibbles.16b
    uxtl    lo0.8h, nibbles.8b
    uxtl2   lo1.8h, nibbles.16b
    tbl     lo0.16b, {lo0.16b}, shuffle0.16b
    tbl     lo1.16b, {lo1.16b}, shuffle1.16b
    // Widen before subtracting so negative coefficients are signed 32-bit
    // words. The zero-filled lanes become +2 padding.
    usubl2  hi0.4s, eta.8h, lo0.8h
    usubl   lo0.4s, eta.4h, lo0.4h
    usubl2  hi1.4s, eta.8h, lo1.8h
    usubl   lo1.4s, eta.4h, lo1.4h

    // With more than 16 slots, even two full groups leave room for another
    // iteration. Store eight words per group and advance past the accepted
    // words so the next store overwrites any padding.
    cmp     remaining, #16
    b.ls    mld_rej_uniform_eta2_tail
    stp     lo0q, hi0q, [output]
    add     output, output, count0, lsl #2
    stp     lo1q, hi1q, [output]
    add     output, output, count1, lsl #2
    sub     remaining, remaining, count0
    sub     remaining, remaining, count1
mld_rej_uniform_eta2_next:
    subs    buflen, buflen, #8
    b.ne    mld_rej_uniform_eta2_loop
    b       mld_rej_uniform_eta2_return

mld_rej_uniform_eta2_tail:
    // Either group can fill r. Check capacity again before storing group 1.
    mov     groups, #2
mld_rej_uniform_eta2_store_group:
    cmp     remaining, #8
    b.lo    mld_rej_uniform_eta2_store_partial
    stp     lo0q, hi0q, [output]
    b       mld_rej_uniform_eta2_stored

mld_rej_uniform_eta2_store_partial:
    mov     dst, output
    // With 1 to 7 slots left, a clear bit 2 means fewer than 4 words fit.
    // TBZ then skips the 4-word store. Bits 1 and 0 select the smaller stores.
    tbz     remaining, #2, mld_rej_uniform_eta2_store_two
    str     lo0q, [dst], #16
    // After a 4- or 2-word store, bring the next coefficient to lane 0.
    mov     lo0.16b, hi0.16b
mld_rej_uniform_eta2_store_two:
    tbz     remaining, #1, mld_rej_uniform_eta2_store_one
    str     lo0d, [dst], #8
    ext     lo0.16b, lo0.16b, lo0.16b, #8
mld_rej_uniform_eta2_store_one:
    tbz     remaining, #0, mld_rej_uniform_eta2_stored
    str     lo0s, [dst]
mld_rej_uniform_eta2_stored:
    // If count0 >= remaining, every available word holds an accepted sample.
    subs    remaining, remaining, count0
    b.ls    mld_rej_uniform_eta2_full
    add     output, output, count0, lsl #2
    subs    groups, groups, #1
    b.eq    mld_rej_uniform_eta2_next
    mov     lo0.16b, lo1.16b
    mov     hi0.16b, hi1.16b
    mov     count0, count1
    b       mld_rej_uniform_eta2_store_group
mld_rej_uniform_eta2_full:
    mov     remaining, #0
mld_rej_uniform_eta2_return:
    mov     return_count, #MLDSA_N
    sub     return_count, return_count, remaining
    ret

    .unreq output
    .unreq return_count
    .unreq buf
    .unreq buflen
    .unreq table
    .unreq remaining
    .unreq tmp
    .unreq groups
    .unreq dst
    .unreq packed0
    .unreq packed1
    .unreq mask0
    .unreq mask1
    .unreq count0
    .unreq count1
    .unreq bytes
    .unreq mod5
    .unreq low
    .unreq high
    .unreq valid0
    .unreq valid1
    .unreq nibbles
    .unreq eta
    .unreq lo0
    .unreq lo0q
    .unreq lo0d
    .unreq lo0s
    .unreq hi0
    .unreq hi0q
    .unreq lo1
    .unreq lo1q
    .unreq hi1
    .unreq hi1q
    .unreq sum0
    .unreq sum0_d
    .unreq sum1
    .unreq sum1_d
    .unreq shuffle0
    .unreq shuffle0q
    .unreq shuffle1
    .unreq shuffle1q
    .unreq nibble_mask
    .unreq bound
    .unreq weights

/* simpasm: footer-start */
#endif /* MLD_SYS_AARCH64_NEON && MLD_ARITH_BACKEND_AARCH64 && \
          !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_ETA == 2) */
