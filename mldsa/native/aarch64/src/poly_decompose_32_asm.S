/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

.macro decompose32 a1, a0, input, temp
        // Step 1: Compute ceil(a / 128) using floor((a + 127) / 128)
        // This is the first part of computing a1 = floor(a / (2*GAMMA2))
        // where 2*GAMMA2 = 523776. We break this into two steps:
        // ceil(a / 128) followed by round(temp / 4092)
        add \a1\().4s, \input\().4s, offset_127.4s
        ushr \a1\().4s, \a1\().4s, #7

        // Step 2: Barrett reduction with rounding: round(temp * 1025 / 2^22)
        // This computes: round(ceil(a/128) / 4092)
        // Combined: a1 ≈ round(ceil(a/128) / 4092) ≈ floor(a / 523776)
        // sqrdmulh computes: (2 * temp * 524800 + 2^31) >> 32
        // which is equivalent to: (temp * 1025 + 2^21) >> 22.
        sqrdmulh \a1\().4s, \a1\().4s, barrett_const.4s

        // Step 3: Mask to valid range [0, 14] since (Q-1)/(2*GAMMA2) = 15
        and \a1\().16b, \a1\().16b, mask_15.16b

        // Step 4: Compute a0 = a - a1 * 2*GAMMA2 (low part of decomposition)
        mls \input\().4s, \a1\().4s, gamma2_2x.4s

        // Step 5: Conditional reduction: if a0 > (Q-1)/2 then a0 -= Q
        cmgt \temp\().4s, \input\().4s, q_half.4s
        and  \temp\().16b, \temp\().16b, q.16b
        sub \a0\().4s, \input\().4s, \temp\().4s
.endm

        /* Parameters */
        a1_ptr          .req x0     // Output polynomial with coefficients c1
        a0_ptr          .req x1     // Output polynomial with coefficients c0
        a_ptr           .req x2     // Input polynomial

        count           .req x3

        /* Constant register assignments */
        q               .req v20    // Q = 8380417
        q_half          .req v21    // (Q-1)/2
        gamma2_2x       .req v22    // 2*GAMMA2 = 523776
        mask_15         .req v23    // mask = 15
        offset_127      .req v24    // offset = 127
        barrett_const   .req v25    // Barrett constant = 524800


.text
.global MLD_ASM_NAMESPACE(poly_decompose_32_asm)
.balign 4
MLD_ASM_FN_SYMBOL(poly_decompose_32_asm)
        // Load constants into SIMD registers
        movz w4, #57345
        movk w4, #127, lsl #16
        dup q.4s, w4

        lsr w5, w4, #1
        dup q_half.4s, w5

        movz w7, #0xfe00
        movk w7, #7, lsl #16
        dup gamma2_2x.4s, w7

        movi mask_15.4s, #15
        movi offset_127.4s, #127

        movz w11, #0x0200
        movk w11, #8, lsl #16
        dup barrett_const.4s, w11

        mov count, #(64/4)

poly_decompose_32_loop:
        ldr q1, [a_ptr, #1*16]
        ldr q2, [a_ptr, #2*16]
        ldr q3, [a_ptr, #3*16]
        ldr q0, [a_ptr], #4*16

        decompose32 v4, v5, v1, v26
        decompose32 v6, v7, v2, v26
        decompose32 v16, v17, v3, v26
        decompose32 v18, v19, v0, v26


        str q4, [a1_ptr, #1*16]
        str q6, [a1_ptr, #2*16]
        str q16, [a1_ptr, #3*16]
        str q18, [a1_ptr], #4*16
        str q5, [a0_ptr, #1*16]
        str q7, [a0_ptr, #2*16]
        str q17, [a0_ptr, #3*16]
        str q19, [a0_ptr], #4*16

        subs count, count, #1
        bne poly_decompose_32_loop

        ret

        .unreq a1_ptr
        .unreq a0_ptr
        .unreq a_ptr
        .unreq count
        .unreq q
        .unreq q_half
        .unreq gamma2_2x
        .unreq mask_15
        .unreq offset_127
        .unreq barrett_const

#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
