/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
           (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/aarch64_opt/src/polyw1_pack_88_asm.S using scripts/simpasm. Do not modify it directly.
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

.text
.balign 4
.global MLD_ASM_NAMESPACE(polyw1_pack_88_asm)
MLD_ASM_FN_SYMBOL(polyw1_pack_88_asm)

        .cfi_startproc
        ldp	q24, q25, [x2]
        ldp	q26, q27, [x2, #0x20]
        mov	x3, #0x4                // =4

Lpolyw1_pack_88_loop:
        ldp	q0, q1, [x1], #0x100
        ldp	q2, q3, [x1, #-0xe0]
        ushl	v0.4s, v0.4s, v24.4s
        ushl	v1.4s, v1.4s, v24.4s
        ushl	v2.4s, v2.4s, v24.4s
        ushl	v3.4s, v3.4s, v24.4s
        addp	v0.4s, v0.4s, v1.4s
        addp	v2.4s, v2.4s, v3.4s
        addp	v16.4s, v0.4s, v2.4s
        ldp	q0, q1, [x1, #-0xc0]
        ldp	q2, q3, [x1, #-0xa0]
        ushl	v0.4s, v0.4s, v24.4s
        ushl	v1.4s, v1.4s, v24.4s
        ushl	v2.4s, v2.4s, v24.4s
        ushl	v3.4s, v3.4s, v24.4s
        addp	v0.4s, v0.4s, v1.4s
        addp	v2.4s, v2.4s, v3.4s
        addp	v17.4s, v0.4s, v2.4s
        ldp	q0, q1, [x1, #-0x80]
        ldp	q2, q3, [x1, #-0x60]
        ushl	v0.4s, v0.4s, v24.4s
        ushl	v1.4s, v1.4s, v24.4s
        ushl	v2.4s, v2.4s, v24.4s
        ushl	v3.4s, v3.4s, v24.4s
        addp	v0.4s, v0.4s, v1.4s
        addp	v2.4s, v2.4s, v3.4s
        addp	v18.4s, v0.4s, v2.4s
        ldp	q0, q1, [x1, #-0x40]
        ldp	q2, q3, [x1, #-0x20]
        ushl	v0.4s, v0.4s, v24.4s
        ushl	v1.4s, v1.4s, v24.4s
        ushl	v2.4s, v2.4s, v24.4s
        ushl	v3.4s, v3.4s, v24.4s
        addp	v0.4s, v0.4s, v1.4s
        addp	v2.4s, v2.4s, v3.4s
        addp	v19.4s, v0.4s, v2.4s
        tbl	v20.16b, { v16.16b, v17.16b }, v25.16b
        tbl	v21.16b, { v17.16b, v18.16b }, v26.16b
        tbl	v22.16b, { v18.16b, v19.16b }, v27.16b
        st1	{ v20.16b, v21.16b, v22.16b }, [x0], #48
        subs	x3, x3, #0x1
        b.ne	Lpolyw1_pack_88_loop
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(polyw1_pack_88_asm)

#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */
