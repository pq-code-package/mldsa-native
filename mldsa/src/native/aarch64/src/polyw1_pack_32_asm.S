/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
           (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
            MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/aarch64_opt/src/polyw1_pack_32_asm.S using scripts/simpasm. Do not modify it directly.
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

.text
.balign 4
.global MLD_ASM_NAMESPACE(polyw1_pack_32_asm)
MLD_ASM_FN_SYMBOL(polyw1_pack_32_asm)

        .cfi_startproc
        mov	x2, #0x2                // =2

Lpolyw1_pack_32_loop:
        ldp	q0, q1, [x1], #0x200
        ldp	q2, q3, [x1, #-0x1e0]
        ldp	q4, q5, [x1, #-0x1c0]
        ldp	q6, q7, [x1, #-0x1a0]
        uzp1	v0.8h, v0.8h, v1.8h
        uzp1	v2.8h, v2.8h, v3.8h
        uzp1	v4.8h, v4.8h, v5.8h
        uzp1	v6.8h, v6.8h, v7.8h
        uzp1	v0.16b, v0.16b, v2.16b
        uzp1	v4.16b, v4.16b, v6.16b
        uzp1	v16.16b, v0.16b, v4.16b
        uzp2	v0.16b, v0.16b, v4.16b
        sli	v16.16b, v0.16b, #0x4
        ldp	q0, q1, [x1, #-0x180]
        ldp	q2, q3, [x1, #-0x160]
        ldp	q4, q5, [x1, #-0x140]
        ldp	q6, q7, [x1, #-0x120]
        uzp1	v0.8h, v0.8h, v1.8h
        uzp1	v2.8h, v2.8h, v3.8h
        uzp1	v4.8h, v4.8h, v5.8h
        uzp1	v6.8h, v6.8h, v7.8h
        uzp1	v0.16b, v0.16b, v2.16b
        uzp1	v4.16b, v4.16b, v6.16b
        uzp1	v17.16b, v0.16b, v4.16b
        uzp2	v0.16b, v0.16b, v4.16b
        sli	v17.16b, v0.16b, #0x4
        ldp	q0, q1, [x1, #-0x100]
        ldp	q2, q3, [x1, #-0xe0]
        ldp	q4, q5, [x1, #-0xc0]
        ldp	q6, q7, [x1, #-0xa0]
        uzp1	v0.8h, v0.8h, v1.8h
        uzp1	v2.8h, v2.8h, v3.8h
        uzp1	v4.8h, v4.8h, v5.8h
        uzp1	v6.8h, v6.8h, v7.8h
        uzp1	v0.16b, v0.16b, v2.16b
        uzp1	v4.16b, v4.16b, v6.16b
        uzp1	v18.16b, v0.16b, v4.16b
        uzp2	v0.16b, v0.16b, v4.16b
        sli	v18.16b, v0.16b, #0x4
        ldp	q0, q1, [x1, #-0x80]
        ldp	q2, q3, [x1, #-0x60]
        ldp	q4, q5, [x1, #-0x40]
        ldp	q6, q7, [x1, #-0x20]
        uzp1	v0.8h, v0.8h, v1.8h
        uzp1	v2.8h, v2.8h, v3.8h
        uzp1	v4.8h, v4.8h, v5.8h
        uzp1	v6.8h, v6.8h, v7.8h
        uzp1	v0.16b, v0.16b, v2.16b
        uzp1	v4.16b, v4.16b, v6.16b
        uzp1	v19.16b, v0.16b, v4.16b
        uzp2	v0.16b, v0.16b, v4.16b
        sli	v19.16b, v0.16b, #0x4
        st1	{ v16.16b, v17.16b, v18.16b, v19.16b }, [x0], #64
        subs	x2, x2, #0x1
        b.ne	Lpolyw1_pack_32_loop
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(polyw1_pack_32_asm)

#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87) */
