/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA forward NTT, POWER8 VSX. Cooley-Tukey, in place, natural order
 * (matches the C reference exactly). 8 layers; the outer 6 (len >= 4) are
 * vectorized 4 coefficients at a time with a per-block broadcast twiddle and
 * the word-domain Montgomery butterfly t = montgomery_reduce(b*zeta),
 * b' = a - t, a' = a + t. The inner 2 layers (len = 2, 1) have within-vector
 * partners, so they run scalar. Twiddles are streamed in natural k order
 * (k = 1..255, one per block, consecutive across layers).
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_PPC64LE) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__POWER8_VECTOR__)
/* simpasm: header-end */

.machine "power8"
.text
.balign 16
.global MLD_ASM_NAMESPACE(ntt_ppc64le_asm)
MLD_ASM_FN_SYMBOL(ntt_ppc64le_asm)
        /* r3 = coeffs (256 int32, in/out), r4 = zetas (natural k order). */
        stdu    1, -48(1)
        std     14, 16(1)
        std     15, 24(1)
        std     16, 32(1)
        lis     14, 0x7F
        ori     14, 14, 0xE001          /* r14 = q = 8380417 */
        lis     15, 0x380
        ori     15, 15, 0x2001          /* r15 = QINV = 58728449 */
        mtvsrd  32+10, 14
        xxspltw 32+10, 32+10, 1         /* v10 = q */
        mtvsrd  32+11, 15
        xxspltw 32+11, 32+11, 1         /* v11 = QINV */
        addi    4, 4, 4                 /* skip zetas[0]; r4 -> &zetas[1] */

        /* ---- vector layers: len = 128, 64, 32, 16, 8, 4 ---- */
        li      5, 128                  /* r5 = len (coeffs) */
.Lntt_vlayer:
        slwi    6, 5, 2                 /* r6 = len_bytes */
        li      7, 0                    /* r7 = start (bytes) */
.Lntt_vblock:
        lwz     0, 0(4)
        addi    4, 4, 4
        mtvsrd  32+8, 0
        xxspltw 32+8, 32+8, 1           /* v8 = zeta (broadcast) */
        li      8, 0                    /* r8 = i (bytes) */
.Lntt_vbf:
        add     9, 7, 8                 /* idx_j  = start + i */
        add     10, 9, 6                /* idx_jl = idx_j + len_bytes */
        lxvd2x  32+0, 9, 3              /* v0 = a = r[j..j+3] */
        lxvd2x  32+1, 10, 3             /* v1 = b = r[j+len..] */
        vmulesw 3, 1, 8                 /* b*zeta even -> dw */
        vmulosw 4, 1, 8                 /* b*zeta odd  -> dw */
        vmrgow  7, 3, 4                 /* low32(prod) */
        vmuluwm 7, 7, 11                /* m = low32(prod*QINV) */
        vmulesw 5, 7, 10                /* m*q even */
        vmulosw 6, 7, 10                /* m*q odd  */
        vsubudm 3, 3, 5                 /* (prod-m*q) even */
        vsubudm 4, 4, 6                 /* (prod-m*q) odd  */
        vmrgew  2, 3, 4                 /* v2 = t = high32 */
        vsubuwm 1, 0, 2                 /* b' = a - t */
        vadduwm 0, 0, 2                 /* a' = a + t */
        stxvd2x 32+1, 10, 3
        stxvd2x 32+0, 9, 3
        addi    8, 8, 16
        cmpw    8, 6
        blt     .Lntt_vbf
        slwi    0, 6, 1                 /* 2*len_bytes */
        add     7, 7, 0
        cmpwi   7, 1024
        blt     .Lntt_vblock
        srwi    5, 5, 1
        cmpwi   5, 4
        bge     .Lntt_vlayer

        /* ---- scalar layers: len = 2, 1 ---- */
.Lntt_slayer:
        slwi    6, 5, 2                 /* len_bytes */
        li      7, 0
.Lntt_sblock:
        lwa     12, 0(4)                /* zeta (sign-extended) */
        addi    4, 4, 4
        li      8, 0
.Lntt_sbf:
        add     9, 7, 8                 /* idx_j */
        add     10, 9, 6                /* idx_jl */
        lwax    11, 10, 3               /* a_jl = r[j+len] */
        mulld   11, 11, 12              /* prod = a_jl * zeta */
        mullw   0, 11, 15               /* m = low32(prod*QINV) */
        extsw   0, 0
        mulld   0, 0, 14                /* m*q */
        subf    11, 0, 11               /* prod - m*q */
        sradi   11, 11, 32              /* t = (prod-m*q) >> 32 */
        lwax    0, 9, 3                 /* a_j = r[j] */
        subf    16, 11, 0               /* r[j+len] = a_j - t */
        add     0, 0, 11                /* r[j]     = a_j + t */
        stwx    16, 10, 3
        stwx    0, 9, 3
        addi    8, 8, 4
        cmpw    8, 6
        blt     .Lntt_sbf
        slwi    0, 6, 1
        add     7, 7, 0
        cmpwi   7, 1024
        blt     .Lntt_sblock
        srwi    5, 5, 1
        cmpwi   5, 1
        bge     .Lntt_slayer

        ld      14, 16(1)
        ld      15, 24(1)
        ld      16, 32(1)
        addi    1, 1, 48
        blr
MLD_ASM_FN_SIZE(ntt_ppc64le_asm)

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && __POWER8_VECTOR__ */
