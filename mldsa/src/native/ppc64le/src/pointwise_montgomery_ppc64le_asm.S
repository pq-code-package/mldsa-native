/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA pointwise Montgomery multiply, POWER8 VSX.
 *   a[i] = montgomery_reduce((int64)a[i] * b[i]).  q = 8380417, QINV = 58728449.
 *
 * Word-domain Montgomery reduction (the int32 keystone, reused by the acc
 * kernels): even/odd 32x32->64 products via vmulesw/vmulosw, m = low32(prod*QINV)
 * via vmuluwm, then (prod - m*q) >> 32 extracted as the high words. The even/odd
 * split (vmrgow for low words, vmrgew for high words) is a closed permutation
 * back to input coefficient order, so VSX lane order need not be reasoned about
 * globally -- the load/store and merges stay self-consistent.
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_PPC64LE) &&                                      \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
     defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)) &&              \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__POWER8_VECTOR__)
/* simpasm: header-end */

.machine "power8"
.text
.balign 16
.global MLD_ASM_NAMESPACE(poly_pointwise_montgomery_ppc64le_asm)
MLD_ASM_FN_SYMBOL(poly_pointwise_montgomery_ppc64le_asm)
        /* r3 = a (in/out), r4 = b. Build q -> v10, QINV -> v11. */
        lis     9, 0x7F
        ori     9, 9, 0xE001
        mtvsrd  32+10, 9
        xxspltw 32+10, 32+10, 1         /* v10 = {q,q,q,q} */
        lis     9, 0x380
        ori     9, 9, 0x2001
        mtvsrd  32+11, 9
        xxspltw 32+11, 32+11, 1         /* v11 = {QINV,...} */
        li      10, 0
        .rept   64
        lxvd2x  32+0, 10, 3             /* v0 = a[i..i+3] */
        lxvd2x  32+1, 10, 4             /* v1 = b[i..i+3] */
        vmulesw 3, 0, 1                 /* v3 = pe  (a*b even lanes -> dw) */
        vmulosw 4, 0, 1                 /* v4 = po  (a*b odd  lanes -> dw) */
        vmrgow  7, 3, 4                 /* v7 = low32(prod), coeff order */
        vmuluwm 7, 7, 11                /* v7 = m = low32(prod*QINV) */
        vmulesw 5, 7, 10                /* v5 = m*q even */
        vmulosw 6, 7, 10                /* v6 = m*q odd */
        vsubudm 3, 3, 5                 /* v3 = (prod - m*q) even */
        vsubudm 4, 4, 6                 /* v4 = (prod - m*q) odd */
        vmrgew  0, 3, 4                 /* v0 = high32 = r, coeff order */
        stxvd2x 32+0, 10, 3
        addi    10, 10, 16
        .endr
        blr
MLD_ASM_FN_SIZE(poly_pointwise_montgomery_ppc64le_asm)

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_PPC64LE && (...) && __POWER8_VECTOR__ */
