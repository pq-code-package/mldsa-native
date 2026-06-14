/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/aarch64_opt/src/poly_decompose_88_aarch64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
#ifdef __APPLE__
.global _mld_poly_decompose_88_aarch64_asm
_mld_poly_decompose_88_aarch64_asm:
#else
.global mld_poly_decompose_88_aarch64_asm
mld_poly_decompose_88_aarch64_asm:
#endif

        .cfi_startproc
        mov w4, #0xe001             // =57345
        movk w4, #0x7f, lsl #16
        dup v20.4s, w4
        mov w5, #0x6c00             // =27648
        movk w5, #0x7e, lsl #16
        dup v21.4s, w5
        mov w7, #0xe800             // =59392
        movk w7, #0x2, lsl #16
        dup v22.4s, w7
        mov w11, #0x581             // =1409
        movk w11, #0x5816, lsl #16
        dup v23.4s, w11
        mov x3, #0x10               // =16
        ldr q0, [x1, #0x10]
        ldr q17, [x1, #0x20]
        ldr q2, [x1, #0x30]
        ldr q26, [x1, #0x40]
        ldr q16, [x1]
        ldr q18, [x1, #0x60]
        cmgt v31.4s, v17.4s, v21.4s
        sqdmulh v3.4s, v17.4s, v23.4s
        cmgt v4.4s, v2.4s, v21.4s
        cmgt v5.4s, v16.4s, v21.4s
        sqdmulh v19.4s, v16.4s, v23.4s
        sqdmulh v7.4s, v2.4s, v23.4s
        srshr v3.4s, v3.4s, #0x11
        sqdmulh v24.4s, v26.4s, v23.4s
        srshr v27.4s, v19.4s, #0x11
        mls v17.4s, v3.4s, v22.4s
        srshr v29.4s, v7.4s, #0x11
        bic v6.16b, v3.16b, v31.16b
        bic v1.16b, v27.16b, v5.16b
        mls v16.4s, v27.4s, v22.4s
        str q6, [x0, #0x20]
        str q1, [x0], #0x40
        mls v2.4s, v29.4s, v22.4s
        add v6.4s, v17.4s, v31.4s
        sqdmulh v3.4s, v18.4s, v23.4s
        str q6, [x1, #0x20]
        add v20.4s, v16.4s, v5.4s
        str q20, [x1], #0x40
        add v17.4s, v2.4s, v4.4s
        sub x3, x3, #0x2

Lpoly_decompose_88_loop:
        cmgt v1.4s, v0.4s, v21.4s
        ldr q5, [x1, #0x30]
        cmgt v6.4s, v18.4s, v21.4s
        sqdmulh v20.4s, v0.4s, v23.4s
        stur q17, [x1, #-0x10]
        srshr v3.4s, v3.4s, #0x11
        bic v7.16b, v29.16b, v4.16b
        cmgt v2.4s, v26.4s, v21.4s
        sqdmulh v16.4s, v5.4s, v23.4s
        srshr v28.4s, v24.4s, #0x11
        stur q7, [x0, #-0x10]
        cmgt v4.4s, v5.4s, v21.4s
        srshr v31.4s, v20.4s, #0x11
        mls v18.4s, v3.4s, v22.4s
        bic v3.16b, v3.16b, v6.16b
        mls v26.4s, v28.4s, v22.4s
        bic v19.16b, v28.16b, v2.16b
        str q3, [x0, #0x20]
        srshr v29.4s, v16.4s, #0x11
        str q19, [x0], #0x40
        mls v0.4s, v31.4s, v22.4s
        bic v30.16b, v31.16b, v1.16b
        add v3.4s, v18.4s, v6.4s
        ldr q18, [x1, #0x60]
        mls v5.4s, v29.4s, v22.4s
        stur q30, [x0, #-0x70]
        add v27.4s, v26.4s, v2.4s
        ldr q26, [x1, #0x40]
        add v25.4s, v0.4s, v1.4s
        ldr q0, [x1, #0x10]
        str q3, [x1, #0x20]
        sqdmulh v3.4s, v18.4s, v23.4s
        stur q25, [x1, #-0x30]
        str q27, [x1], #0x40
        add v17.4s, v5.4s, v4.4s
        sqdmulh v24.4s, v26.4s, v23.4s
        subs x3, x3, #0x1
        b.ne Lpoly_decompose_88_loop
        ldr q16, [x1, #0x30]
        ldr q5, [x1, #0x10]
        sqdmulh v28.4s, v0.4s, v23.4s
        cmgt v19.4s, v26.4s, v21.4s
        cmgt v2.4s, v0.4s, v21.4s
        stur q17, [x1, #-0x10]
        srshr v31.4s, v3.4s, #0x11
        sqdmulh v1.4s, v5.4s, v23.4s
        cmgt v6.4s, v16.4s, v21.4s
        srshr v24.4s, v24.4s, #0x11
        srshr v25.4s, v28.4s, #0x11
        sqdmulh v20.4s, v16.4s, v23.4s
        cmgt v17.4s, v18.4s, v21.4s
        mls v18.4s, v31.4s, v22.4s
        cmgt v27.4s, v5.4s, v21.4s
        srshr v30.4s, v1.4s, #0x11
        mls v0.4s, v25.4s, v22.4s
        bic v28.16b, v25.16b, v2.16b
        srshr v7.4s, v20.4s, #0x11
        bic v25.16b, v24.16b, v19.16b
        mls v26.4s, v24.4s, v22.4s
        bic v20.16b, v30.16b, v27.16b
        stur q28, [x0, #-0x30]
        add v3.4s, v18.4s, v17.4s
        mls v5.4s, v30.4s, v22.4s
        str q20, [x0, #0x10]
        bic v28.16b, v7.16b, v6.16b
        mls v16.4s, v7.4s, v22.4s
        str q3, [x1, #0x20]
        str q28, [x0, #0x30]
        add v3.4s, v0.4s, v2.4s
        bic v7.16b, v29.16b, v4.16b
        str q25, [x0], #0x40
        stur q3, [x1, #-0x30]
        add v24.4s, v5.4s, v27.4s
        stur q7, [x0, #-0x50]
        add v19.4s, v26.4s, v19.4s
        add v25.4s, v16.4s, v6.4s
        bic v6.16b, v31.16b, v17.16b
        str q24, [x1, #0x10]
        str q19, [x1], #0x40
        stur q6, [x0, #-0x20]
        stur q25, [x1, #-0x10]
        ret
        .cfi_endproc

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
