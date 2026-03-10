/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
           (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44)
/* simpasm: header-end */

/*
 * polyw1_pack_88: Pack w1 polynomial for GAMMA2 = (Q-1)/88.
 *
 * Each coefficient is in [0, 43] (6 bits) stored in a 32-bit word.
 * Pack 4 coefficients into 3 bytes:
 *   r[3i+0] =  a[4i+0]       | (a[4i+1] << 6)
 *   r[3i+1] = (a[4i+1] >> 2) | (a[4i+2] << 4)
 *   r[3i+2] = (a[4i+2] >> 4) | (a[4i+3] << 2)
 * 256 coefficients -> 192 output bytes.
 *
 * Each group of 4 coefficients in a .4s vector is shifted to its
 * bit position using USHL, then reduced with ADDP to form one
 * 24-bit packed value per 32-bit lane.
 *
 * Three 2-register TBL instructions then extract the useful 3 bytes
 * from each 32-bit lane across pairs of adjacent result vectors,
 * producing 3 contiguous 16-byte output vectors (48 bytes total).
 *
 * 4x unrolled, 4 iterations for 256 coefficients.
 */

        output          .req x0
        input           .req x1
        table           .req x2
        count           .req x3

        v_shifts        .req v24
        v_tbl0          .req v25
        v_tbl1          .req v26
        v_tbl2          .req v27

.text
.global MLD_ASM_NAMESPACE(polyw1_pack_88_asm)
.balign 4
MLD_ASM_FN_SYMBOL(polyw1_pack_88_asm)

        /* Load constants from table pointer (x2):
         * [0:15]  = v_shifts.4s = {0, 6, 12, 18}
         * [16:31] = v_tbl0: TBL indices for out0 from {v16, v17}
         * [32:47] = v_tbl1: TBL indices for out1 from {v17, v18}
         * [48:63] = v_tbl2: TBL indices for out2 from {v18, v19} */
        ldp q24, q25, [table]
        ldp q26, q27, [table, #32]

        mov count, #(256 / (16 * 4))

polyw1_pack_88_loop:

        /* Block 0: coefficients 0-15 */
        ldp q0, q1, [input], #256
        ldp q2, q3, [input, #(32 - 256)]
        ushl v0.4s, v0.4s, v_shifts.4s
        ushl v1.4s, v1.4s, v_shifts.4s
        ushl v2.4s, v2.4s, v_shifts.4s
        ushl v3.4s, v3.4s, v_shifts.4s
        addp v0.4s, v0.4s, v1.4s
        addp v2.4s, v2.4s, v3.4s
        addp v16.4s, v0.4s, v2.4s

        /* Block 1: coefficients 16-31 */
        ldp q0, q1, [input, #(64 - 256)]
        ldp q2, q3, [input, #(96 - 256)]
        ushl v0.4s, v0.4s, v_shifts.4s
        ushl v1.4s, v1.4s, v_shifts.4s
        ushl v2.4s, v2.4s, v_shifts.4s
        ushl v3.4s, v3.4s, v_shifts.4s
        addp v0.4s, v0.4s, v1.4s
        addp v2.4s, v2.4s, v3.4s
        addp v17.4s, v0.4s, v2.4s

        /* Block 2: coefficients 32-47 */
        ldp q0, q1, [input, #(128 - 256)]
        ldp q2, q3, [input, #(160 - 256)]
        ushl v0.4s, v0.4s, v_shifts.4s
        ushl v1.4s, v1.4s, v_shifts.4s
        ushl v2.4s, v2.4s, v_shifts.4s
        ushl v3.4s, v3.4s, v_shifts.4s
        addp v0.4s, v0.4s, v1.4s
        addp v2.4s, v2.4s, v3.4s
        addp v18.4s, v0.4s, v2.4s

        /* Block 3: coefficients 48-63 */
        ldp q0, q1, [input, #(192 - 256)]
        ldp q2, q3, [input, #(224 - 256)]
        ushl v0.4s, v0.4s, v_shifts.4s
        ushl v1.4s, v1.4s, v_shifts.4s
        ushl v2.4s, v2.4s, v_shifts.4s
        ushl v3.4s, v3.4s, v_shifts.4s
        addp v0.4s, v0.4s, v1.4s
        addp v2.4s, v2.4s, v3.4s
        addp v19.4s, v0.4s, v2.4s

        /* Compact + splice into 3 output vectors */
        tbl v20.16b, {v16.16b, v17.16b}, v_tbl0.16b
        tbl v21.16b, {v17.16b, v18.16b}, v_tbl1.16b
        tbl v22.16b, {v18.16b, v19.16b}, v_tbl2.16b

        st1 {v20.16b, v21.16b, v22.16b}, [output], #48

        subs count, count, #1
        bne polyw1_pack_88_loop

        ret

        .unreq output
        .unreq input
        .unreq table
        .unreq count
        .unreq v_shifts
        .unreq v_tbl0
        .unreq v_tbl1
        .unreq v_tbl2
/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */
