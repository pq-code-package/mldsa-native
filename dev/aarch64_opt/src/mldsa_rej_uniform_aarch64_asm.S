/*
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) The mlkem-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: rej_uniform_aarch64_asm
  Description: AArch64 rejection sampling of uniform coefficients mod q
  Signature: uint64_t mld_rej_uniform_aarch64_asm(int32_t r[256], const uint8_t *buf, uint64_t buflen, const uint8_t table[256])
  ABI:
    Architecture: aarch64
    CallingConvention: AAPCS64
    Features: [NEON]
    x0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t r[256]
      description: Output buffer (256 x int32_t)
    x1:
      type: buffer
      size_bytes: x2
      permissions: read-only
      c_parameter: const uint8_t *buf
      description: Input buffer
    x2:
      type: scalar
      c_parameter: uint64_t buflen
      description: Length of input buffer (must be a multiple of 24)
      test_with: 840  # MLD_POLY_UNIFORM_NBLOCKS * SHAKE128_RATE = 5 * 168
    x3:
      type: buffer
      size_bytes: 256
      permissions: read-only
      c_parameter: const uint8_t table[256]
      description: Lookup table (256 x uint8_t)
*/

 #include "../../../common.h"
#if defined(MLD_SYS_AARCH64_NEON) && \
    defined(MLD_ARITH_BACKEND_AARCH64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

// We save the output on the stack first, and copy to the actual
// output buffer only in the end. This is because the main loop can overwrite
// by up to 60 bytes, which we account for here (we use 64 bytes for alignment).
#define MLD_STACK_SIZE (4*MLDSA_N + 64)

.macro push_stack
        sub sp, sp, #MLD_STACK_SIZE
.endm

.macro pop_stack
        add sp, sp, #MLD_STACK_SIZE
.endm

    /* Parameters */
    output                      .req x0
    buf                         .req x1
    buflen                      .req x2
    table_idx                   .req x3

    len                         .req x4

    /* Temporary output on the stack */
    xtmp0                       .req x7
    xtmp1                       .req x11
    wtmp                        .req w7
    output_tmp                  .req x7
    output_tmp_base             .req x8

    /* Number of coefficients sampled so far */
    count                       .req x9

    /* Temporary registers */
    initial_zero_count          .req x11
    final_copy_count            .req x11

    rec_idx_0                   .req x12
    rec_idx_1                   .req x13
    rec_idx_2                   .req x14
    rec_idx_3                   .req x15

    ctr0                        .req x12
    ctr1                        .req x13
    ctr2                        .req x14
    ctr3                        .req x15

    ctr01                       .req ctr0
    ctr23                       .req ctr2

    /* Vector registers */

    buf0                        .req v0
    buf0q                       .req q0
    buf1                        .req v1
    buf1q                       .req q1
    buf1d                       .req d1
    buf2                        .req v2
    buf2q                       .req q2

    tmp0                        .req v4
    tmp1                        .req v5
    tmp2                        .req v6

    sign0                       .req v4
    sign1                       .req v5
    sign2                       .req v6
    sign3                       .req v7

    val0                        .req v16
    val0q                       .req q16
    val1                        .req v17
    val1q                       .req q17
    val2                        .req v18
    val2q                       .req q18
    val3                        .req v19
    val3q                       .req q19

    t0                          .req d0
    t1                          .req d1

    unpack0                     .req v20
    unpack0d                    .req d20
    unpack1                     .req v21
    unpack2                     .req v22
    unpack3                     .req v23

    table0                      .req v24
    table0q                     .req q24
    table1                      .req v25
    table1q                     .req q25
    table2                      .req v26
    table2q                     .req q26
    table3                      .req v27
    table3q                     .req q27

    bit23                       .req v28
    packed_bits                 .req v29
    mldsa_q                     .req v30
    bits                        .req v31
    bitsd                       .req d31

    .text
    .global MLD_ASM_NAMESPACE(rej_uniform_aarch64_asm)
    .balign 4
MLD_ASM_FN_SYMBOL(rej_uniform_aarch64_asm)
    push_stack

    // [1, 2, 4, 8]
    movz xtmp0, 0x1
    movk xtmp0, 0x2, lsl 32
    movz xtmp1, 0x4
    movk xtmp1, 0x8, lsl 32
    fmov bitsd, xtmp0
    mov bits.d[1], xtmp1

    // [1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 8, 8, 8, 8].
    movi packed_bits.16b, #1
    mul packed_bits.4s, bits.4s, packed_bits.4s

    // load q = 8380417
    movz wtmp, #57345
    movk wtmp, #127, lsl #16
    dup mldsa_q.4s, wtmp

    // TBL indices for expanding 3-byte samples, 0x80 indices are set to 0.
    // [0, 1, 2, 0x80, 3, 4, 5, 0x80, 6, 7, 8, 0x80, 9, 10, 11, 0x80].
    movz xtmp0, #0x0100
    movk xtmp0, #0x8002, lsl #16
    movk xtmp0, #0x0403, lsl #32
    movk xtmp0, #0x8005, lsl #48
    movz xtmp1, #0x0706
    movk xtmp1, #0x8008, lsl #16
    movk xtmp1, #0x0a09, lsl #32
    movk xtmp1, #0x800b, lsl #48
    fmov unpack0d, xtmp0
    mov unpack0.d[1], xtmp1

    movi bit23.4s, #0x80, lsl #16

    // Each unpack consumes 12 bytes, so set unpack{1,2,3} at {12,24,36} bytes
    // from the start. The TBL instructions are only passed the relevant
    // vectors, so subtract {16,32} from the indices for unpack{2,3} to
    // compensate:
    //                 buf0              buf1              buf2
    // unpack0 reads: [xxxxxxxxxxxx....]
    // unpack1 reads: [............xxxx][xxxxxxxx........]
    // unpack2 reads: (skip 16)         [........xxxxxxxx][xxxx............]
    // unpack3 reads: (skip 32)                           [....xxxxxxxxxxxx]
    movi tmp0.16b, #(12)
    movi tmp1.16b, #(24 - 16)
    movi tmp2.16b, #(36 - 32)
    add unpack1.16b, unpack0.16b, tmp0.16b
    add unpack2.16b, unpack0.16b, tmp1.16b
    add unpack3.16b, unpack0.16b, tmp2.16b

    mov output_tmp_base, sp
    mov output_tmp, output_tmp_base

    // The entire temporary stack buffer is copied to the output buffer
    // at the end of this routine. To avoid leaking original stack contents
    // in case not enough bytes have been sampled, zero the temporary buffer.
    mov initial_zero_count, #0
    eor val0.16b, val0.16b, val0.16b
mld_rej_uniform_initial_zero:
        str val0q, [output_tmp], #64
        str val0q, [output_tmp, #-48]
        str val0q, [output_tmp, #-32]
        str val0q, [output_tmp, #-16]
        add initial_zero_count, initial_zero_count, #16
        cmp initial_zero_count, #MLDSA_N
        b.lt mld_rej_uniform_initial_zero

    mov output_tmp, output_tmp_base

    mov count, #0
    mov len, #MLDSA_N

    cmp buflen, #48
    b.lo mld_rej_uniform_loop48_end

mld_rej_uniform_loop48:
        // Finish once we've generated sufficiently many coefficients
        cmp     count, len
        b.hs    mld_rej_uniform_memory_copy

        sub     buflen, buflen, #48

        // Load sixteen packed 24-bit samples, mask out the top bit and expand
        // to 32-bit elements: [a0, a1, a2 & 0x7f, 0, b0, b1, b2 & 0x7f, ...].
        ldp     buf0q, buf1q, [buf]
        ldr     buf2q, [buf, #32]
        add     buf, buf, #48

        tbl     val0.16b, {buf0.16b}, unpack0.16b
        tbl     val1.16b, {buf0.16b, buf1.16b}, unpack1.16b
        tbl     val2.16b, {buf1.16b, buf2.16b}, unpack2.16b
        tbl     val3.16b, {buf2.16b}, unpack3.16b
        bic     val0.16b, val0.16b, bit23.16b
        bic     val1.16b, val1.16b, bit23.16b
        bic     val2.16b, val2.16b, bit23.16b
        bic     val3.16b, val3.16b, bit23.16b

        // Build a 4-bit validity bitmap for each vector, then use it to look
        // up a TBL permutation that moves valid lanes to the front of the
        // vector. Store each vector and advance the output by its valid count.

        // Set valid lanes to -1 (0b1...1)
        cmhi    sign0.4s, mldsa_q.4s, val0.4s
        cmhi    sign1.4s, mldsa_q.4s, val1.4s
        cmhi    sign2.4s, mldsa_q.4s, val2.4s
        cmhi    sign3.4s, mldsa_q.4s, val3.4s

        // Pack the four vectors' masks into interleaved bytes in each 32-bit
        // lane: [s0[0], s1[0], s2[0], s3[0], s0[1], s1[1], s2[1], s3[1], ...].
        trn1    sign0.16b, sign0.16b, sign1.16b
        trn1    sign1.16b, sign2.16b, sign3.16b
        trn1    sign0.8h, sign0.8h, sign1.8h

        // Retain bit i in each valid byte of 32-bit lane i.
        and     sign0.16b, sign0.16b, packed_bits.16b

        // Sum the 32-bit lanes to get four byte-sized bitmaps. Each is at most
        // 15, so carries cannot cross byte boundaries.
        uaddlv  t0, sign0.4s

        fmov    rec_idx_3, t0
        ubfx    rec_idx_0, rec_idx_3, #0, #4
        ubfx    rec_idx_1, rec_idx_3, #8, #4
        ubfx    rec_idx_2, rec_idx_3, #16, #4
        ubfx    rec_idx_3, rec_idx_3, #24, #4

        ldr     table0q, [table_idx, rec_idx_0, lsl #4]
        ldr     table1q, [table_idx, rec_idx_1, lsl #4]
        ldr     table2q, [table_idx, rec_idx_2, lsl #4]
        ldr     table3q, [table_idx, rec_idx_3, lsl #4]

        // Each byte has one bit set if its coefficient is valid. Sum the byte
        // popcounts into four packed counts. Each sum is at most four, so
        // carries cannot cross byte boundaries.
        cnt     sign0.16b, sign0.16b
        uaddlv  t0, sign0.4s

        fmov    ctr3, t0
        ubfx    ctr0, ctr3, #0, #3
        ubfx    ctr1, ctr3, #8, #3
        ubfx    ctr2, ctr3, #16, #3
        ubfx    ctr3, ctr3, #24, #3

        // Move valid coefficients to the front.
        tbl     val0.16b, {val0.16b}, table0.16b
        tbl     val1.16b, {val1.16b}, table1.16b
        tbl     val2.16b, {val2.16b}, table2.16b
        tbl     val3.16b, {val3.16b}, table3.16b

        st1     {val0.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr0, lsl #2

        st1     {val1.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr1, lsl #2

        st1     {val2.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr2, lsl #2

        st1     {val3.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr3, lsl #2

        add     ctr01, ctr0, ctr1
        add     ctr23, ctr2, ctr3
        add     count, count, ctr01
        add     count, count, ctr23

        cmp buflen, #48
        b.hs mld_rej_uniform_loop48
mld_rej_uniform_loop48_end:

    // Finish once we've generated sufficiently many coefficients
    cmp     count, len
    b.hs    mld_rej_uniform_memory_copy

    cmp buflen, #24
    b.lo mld_rej_uniform_memory_copy

        sub     buflen, buflen, #24

        // Load eight packed 24-bit samples, mask out the top bit and expand
        // to 32-bit elements: [a0, a1, a2 & 0x7f, 0, b0, b1, b2 & 0x7f, ...].
        ldr     buf0q, [buf]
        ldr     buf1d, [buf, #16]
        add     buf, buf, #24

        tbl     val0.16b, {buf0.16b}, unpack0.16b
        tbl     val1.16b, {buf0.16b, buf1.16b}, unpack1.16b
        bic     val0.16b, val0.16b, bit23.16b
        bic     val1.16b, val1.16b, bit23.16b

        cmhi    sign0.4s, mldsa_q.4s, val0.4s
        cmhi    sign1.4s, mldsa_q.4s, val1.4s

        and     sign0.16b, sign0.16b, bits.16b
        and     sign1.16b, sign1.16b, bits.16b

        uaddlv  t0, sign0.4s
        uaddlv  t1, sign1.4s

        fmov    rec_idx_0, t0
        fmov    rec_idx_1, t1

        ldr     table0q, [table_idx, rec_idx_0, lsl #4]
        ldr     table1q, [table_idx, rec_idx_1, lsl #4]

        cnt     sign0.16b, sign0.16b
        cnt     sign1.16b, sign1.16b

        uaddlv  t0, sign0.4s
        uaddlv  t1, sign1.4s

        fmov    ctr0, t0
        fmov    ctr1, t1

        tbl     val0.16b, {val0.16b}, table0.16b
        tbl     val1.16b, {val1.16b}, table1.16b

        st1     {val0.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr0, lsl #2

        st1     {val1.4s}, [output_tmp]
        add     output_tmp, output_tmp, ctr1, lsl #2

        add     count, count, ctr0
        add     count, count, ctr1

mld_rej_uniform_memory_copy:
    // min = min(count,len)
    cmp  count, len
    csel count, count, len, lo

    // Always copy MLDSA_N coefficients from the stack to the destination,
    // even if not all of them may be valid. This simplifies the loop and
    // allows us to stick to vectorized code.
    mov final_copy_count, #0
    mov output_tmp, output_tmp_base
mld_rej_uniform_final_copy:
        ldr val0q, [output_tmp], #64
        ldr val1q, [output_tmp, #-48]
        ldr val2q, [output_tmp, #-32]
        ldr val3q, [output_tmp, #-16]
        str val0q, [output], #64
        str val1q, [output, #-48]
        str val2q, [output, #-32]
        str val3q, [output, #-16]
        add final_copy_count, final_copy_count, #16
        cmp final_copy_count, #MLDSA_N
        b.lt mld_rej_uniform_final_copy

    mov x0, count
    b mld_rej_uniform_return


mld_rej_uniform_return:
    pop_stack
    ret

/****************** REGISTER DEALLOCATIONS *******************/
    .unreq output
    .unreq buf
    .unreq buflen
    .unreq table_idx
    .unreq len
    .unreq output_tmp
    .unreq output_tmp_base
    .unreq count
    .unreq xtmp0
    .unreq xtmp1
    .unreq wtmp
    .unreq final_copy_count
    .unreq initial_zero_count
    .unreq rec_idx_0
    .unreq rec_idx_1
    .unreq rec_idx_2
    .unreq rec_idx_3
    .unreq ctr0
    .unreq ctr1
    .unreq ctr2
    .unreq ctr3
    .unreq ctr01
    .unreq ctr23
    .unreq buf0
    .unreq buf0q
    .unreq buf1
    .unreq buf1q
    .unreq buf1d
    .unreq buf2
    .unreq buf2q
    .unreq tmp0
    .unreq tmp1
    .unreq tmp2
    .unreq sign0
    .unreq sign1
    .unreq sign2
    .unreq sign3
    .unreq val0
    .unreq val0q
    .unreq val1
    .unreq val1q
    .unreq val2
    .unreq val2q
    .unreq val3
    .unreq val3q
    .unreq t0
    .unreq t1
    .unreq unpack0
    .unreq unpack0d
    .unreq unpack1
    .unreq unpack2
    .unreq unpack3
    .unreq table0
    .unreq table0q
    .unreq table1
    .unreq table1q
    .unreq table2
    .unreq table2q
    .unreq table3
    .unreq table3q
    .unreq bit23
    .unreq packed_bits
    .unreq mldsa_q
    .unreq bits
    .unreq bitsd


/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef MLD_STACK_SIZE

/* simpasm: footer-start */
#endif /* MLD_SYS_AARCH64_NEON && MLD_ARITH_BACKEND_AARCH64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
