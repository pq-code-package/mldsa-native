/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
           (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
            MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
/* simpasm: header-end */

/*
 * polyw1_pack_32: Pack w1 polynomial for GAMMA2 = (Q-1)/32.
 *
 * Each coefficient is in [0, 15] (4 bits) stored in a 32-bit word.
 * Pack 2 coefficients per byte: r[i] = a[2i] | (a[2i+1] << 4)
 * 256 coefficients -> 128 output bytes.
 *
 * UZP1 narrowing chain (32->16->8 bit) extracts the low byte from
 * each coefficient; UZP1/UZP2 separate even/odd coefficients;
 * SLI shifts and inserts the odd nibbles.
 *
 * 4x unrolled, 2 iterations for 256 coefficients.
 */

        output          .req x0
        input           .req x1
        count           .req x2

.text
.global MLD_ASM_NAMESPACE(polyw1_pack_32_asm)
.balign 4
MLD_ASM_FN_SYMBOL(polyw1_pack_32_asm)

        mov count, #(256 / (32 * 4))

polyw1_pack_32_loop:

        /* Block 0: coefficients 0-31 */
        ldp q0, q1, [input], #512
        ldp q2, q3, [input, #(32 - 512)]
        ldp q4, q5, [input, #(64 - 512)]
        ldp q6, q7, [input, #(96 - 512)]
        uzp1 v0.8h, v0.8h, v1.8h
        uzp1 v2.8h, v2.8h, v3.8h
        uzp1 v4.8h, v4.8h, v5.8h
        uzp1 v6.8h, v6.8h, v7.8h
        uzp1 v0.16b, v0.16b, v2.16b
        uzp1 v4.16b, v4.16b, v6.16b
        uzp1 v16.16b, v0.16b, v4.16b
        uzp2 v0.16b, v0.16b, v4.16b
        sli v16.16b, v0.16b, #4

        /* Block 1: coefficients 32-63 */
        ldp q0, q1, [input, #(128 - 512)]
        ldp q2, q3, [input, #(160 - 512)]
        ldp q4, q5, [input, #(192 - 512)]
        ldp q6, q7, [input, #(224 - 512)]
        uzp1 v0.8h, v0.8h, v1.8h
        uzp1 v2.8h, v2.8h, v3.8h
        uzp1 v4.8h, v4.8h, v5.8h
        uzp1 v6.8h, v6.8h, v7.8h
        uzp1 v0.16b, v0.16b, v2.16b
        uzp1 v4.16b, v4.16b, v6.16b
        uzp1 v17.16b, v0.16b, v4.16b
        uzp2 v0.16b, v0.16b, v4.16b
        sli v17.16b, v0.16b, #4

        /* Block 2: coefficients 64-95 */
        ldp q0, q1, [input, #(256 - 512)]
        ldp q2, q3, [input, #(288 - 512)]
        ldp q4, q5, [input, #(320 - 512)]
        ldp q6, q7, [input, #(352 - 512)]
        uzp1 v0.8h, v0.8h, v1.8h
        uzp1 v2.8h, v2.8h, v3.8h
        uzp1 v4.8h, v4.8h, v5.8h
        uzp1 v6.8h, v6.8h, v7.8h
        uzp1 v0.16b, v0.16b, v2.16b
        uzp1 v4.16b, v4.16b, v6.16b
        uzp1 v18.16b, v0.16b, v4.16b
        uzp2 v0.16b, v0.16b, v4.16b
        sli v18.16b, v0.16b, #4

        /* Block 3: coefficients 96-127 */
        ldp q0, q1, [input, #(384 - 512)]
        ldp q2, q3, [input, #(416 - 512)]
        ldp q4, q5, [input, #(448 - 512)]
        ldp q6, q7, [input, #(480 - 512)]
        uzp1 v0.8h, v0.8h, v1.8h
        uzp1 v2.8h, v2.8h, v3.8h
        uzp1 v4.8h, v4.8h, v5.8h
        uzp1 v6.8h, v6.8h, v7.8h
        uzp1 v0.16b, v0.16b, v2.16b
        uzp1 v4.16b, v4.16b, v6.16b
        uzp1 v19.16b, v0.16b, v4.16b
        uzp2 v0.16b, v0.16b, v4.16b
        sli v19.16b, v0.16b, #4

        st1 {v16.16b, v17.16b, v18.16b, v19.16b}, [output], #64

        subs count, count, #1
        bne polyw1_pack_32_loop

        ret

        .unreq output
        .unreq input
        .unreq count
/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87) */
