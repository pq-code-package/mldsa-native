/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA poly_caddq, POWER8 VSX (first ppc64le kernel).
 *   For each int32 coeff a:  a = (a < 0) ? a + MLDSA_Q : a.   MLDSA_Q = 8380417.
 *
 * Branch-free (.rept-unrolled) to match the ppc64le backend convention and to
 * keep simpasm regeneration well-defined (no intra-symbol branch targets).
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_PPC64LE) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__POWER8_VECTOR__)
/* simpasm: header-end */

.machine "power8"
.text
.balign 16
.global MLD_ASM_NAMESPACE(poly_caddq_ppc64le_asm)
MLD_ASM_FN_SYMBOL(poly_caddq_ppc64le_asm)
        /* r3 = a (MLDSA_N = 256 int32). Build q = 8380417 = 0x007FE001 and
           splat across 4 word lanes. caddq is element-wise, so VSX lane order
           is irrelevant: each coeff is loaded, conditionally +q'd, stored back
           through the same lxvd2x/stxvd2x, preserving order. */
        lis     9, 0x7F
        ori     9, 9, 0xE001            /* r9 = 8380417 = q */
        mtvsrd  32+4, 9
        xxspltw 32+4, 32+4, 1           /* v4 = {q, q, q, q} */
        vxor    5, 5, 5                  /* v5 = {0,0,0,0} */
        li      10, 0                    /* running byte offset */
        /* 256 coeffs / 4 per vector = 64 vectors, fully unrolled. */
        .rept   64
        lxvd2x  32+0, 10, 3             /* v0 = 4 coeffs at a+off */
        vcmpgtsw 1, 5, 0                /* v1 = (0 > a) = (a < 0) mask */
        vadduwm 2, 0, 4                 /* v2 = a + q */
        xxsel   32+0, 32+0, 32+2, 32+1 /* mask ? a+q : a */
        stxvd2x 32+0, 10, 3
        addi    10, 10, 16
        .endr
        blr
MLD_ASM_FN_SIZE(poly_caddq_ppc64le_asm)

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && __POWER8_VECTOR__ */
