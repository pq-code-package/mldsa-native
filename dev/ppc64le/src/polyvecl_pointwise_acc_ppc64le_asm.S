/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA polyvecl_pointwise_acc_montgomery (L in {4,5,7}), POWER8 VSX.
 *   w[i] = montgomery_reduce( sum_{j<L} (int64)u[j][i] * v[j][i] ).
 *
 * Accumulates the exact 64-bit even/odd products across the L polynomials with
 * vaddudm (|sum| < 7 * q * NTT_BOUND < 2^53, no doubleword overflow), then a
 * single word-domain Montgomery reduction (same primitive as the pointwise
 * kernel). Outer loop over the 64 coefficient vectors; the L accumulation is
 * unrolled per entry.
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_PPC64LE) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__POWER8_VECTOR__)
/* simpasm: header-end */

.machine "power8"
.text

/* One accumulate-reduce kernel for a given vector length L.
 *   r3 = w (out), r4 = u (L x 256 int32), r5 = v.  q -> v10, QINV -> v11.
 *   r6/r7 = per-coefficient u/v cursors; r10 = coefficient byte offset. */
.macro ACC_FN L
.balign 16
.global MLD_ASM_NAMESPACE(polyvecl_pointwise_acc_montgomery_l\L\()_ppc64le_asm)
MLD_ASM_FN_SYMBOL(polyvecl_pointwise_acc_montgomery_l\L\()_ppc64le_asm)
        lis     9, 0x7F
        ori     9, 9, 0xE001
        mtvsrd  32+10, 9
        xxspltw 32+10, 32+10, 1         /* v10 = q */
        lis     9, 0x380
        ori     9, 9, 0x2001
        mtvsrd  32+11, 9
        xxspltw 32+11, 32+11, 1         /* v11 = QINV */
        li      10, 0
        li      9, 64
        mtctr   9
1:
        add     6, 4, 10                /* u + coeff_off */
        add     7, 5, 10                /* v + coeff_off */
        vxor    20, 20, 20              /* pe_acc = 0 */
        vxor    21, 21, 21              /* po_acc = 0 */
        .rept   \L
        lxvd2x  32+0, 0, 6              /* u[j] */
        lxvd2x  32+1, 0, 7              /* v[j] */
        vmulesw 3, 0, 1                 /* even products (dw) */
        vmulosw 4, 0, 1                 /* odd  products (dw) */
        vaddudm 20, 20, 3               /* accumulate even */
        vaddudm 21, 21, 4               /* accumulate odd  */
        addi    6, 6, 1024              /* next polynomial (256 int32) */
        addi    7, 7, 1024
        .endr
        /* single Montgomery reduction of the accumulated 64-bit sums */
        vmrgow  7, 20, 21               /* low32(acc), coeff order */
        vmuluwm 7, 7, 11                /* m = low32(acc*QINV) */
        vmulesw 5, 7, 10                /* m*q even */
        vmulosw 6, 7, 10                /* m*q odd  */
        vsubudm 20, 20, 5               /* (acc - m*q) even */
        vsubudm 21, 21, 6               /* (acc - m*q) odd  */
        vmrgew  0, 20, 21               /* high32 = w, coeff order */
        stxvd2x 32+0, 10, 3
        addi    10, 10, 16
        bdnz    1b
        blr
MLD_ASM_FN_SIZE(polyvecl_pointwise_acc_montgomery_l\L\()_ppc64le_asm)
.endm

ACC_FN 4
ACC_FN 5
ACC_FN 7

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && __POWER8_VECTOR__ */
