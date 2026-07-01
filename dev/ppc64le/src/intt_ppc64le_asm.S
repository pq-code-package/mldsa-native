/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA inverse NTT (to Montgomery domain), POWER8 VSX. Gentleman-Sande,
 * in place, natural order; layers 8..1 (len = 1,2,...,128). Inner 2 layers
 * (len = 1,2) run scalar, outer 6 (len >= 4) vectorized. Butterfly:
 * r[j]' = a + b, r[j+len]' = montgomery_reduce((a-b)*zeta). Twiddles are
 * streamed in descending k order (k = 255..1) and negated (zeta = -zetas[k]).
 * A final pass scales every coefficient by f = 41978 = 2^(64-8) mod q.
 */
#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_PPC64LE) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__POWER8_VECTOR__)
/* simpasm: header-end */

.machine "power8"
.text
.balign 16
.global MLD_ASM_NAMESPACE(intt_ppc64le_asm)
MLD_ASM_FN_SYMBOL(intt_ppc64le_asm)
        /* r3 = coeffs (in/out), r4 = zetas (natural k order). */
        stdu    1, -48(1)
        std     14, 16(1)
        std     15, 24(1)
        std     16, 32(1)
        lis     14, 0x7F
        ori     14, 14, 0xE001          /* r14 = q */
        lis     15, 0x380
        ori     15, 15, 0x2001          /* r15 = QINV */
        mtvsrd  32+10, 14
        xxspltw 32+10, 32+10, 1         /* v10 = q */
        mtvsrd  32+11, 15
        xxspltw 32+11, 32+11, 1         /* v11 = QINV */
        addi    4, 4, 1020              /* r4 -> &zetas[255] */

        /* ---- scalar layers: len = 1, 2 ---- */
        li      5, 1
.Li_slayer:
        slwi    6, 5, 2
        li      7, 0
.Li_sblock:
        lwa     12, 0(4)
        neg     12, 12                  /* zeta = -zetas[k] */
        addi    4, 4, -4
        li      8, 0
.Li_sbf:
        add     9, 7, 8
        add     10, 9, 6
        lwax    0, 9, 3                 /* a = r[j] */
        lwax    11, 10, 3               /* b = r[j+len] */
        add     16, 0, 11               /* r[j]' = a + b */
        subf    11, 11, 0               /* tmp = a - b */
        mulld   11, 11, 12              /* prod = tmp*zeta */
        mullw   0, 11, 15               /* m */
        extsw   0, 0
        mulld   0, 0, 14                /* m*q */
        subf    11, 0, 11               /* prod - m*q */
        sradi   11, 11, 32              /* r[j+len]' = mont */
        stwx    16, 9, 3
        stwx    11, 10, 3
        addi    8, 8, 4
        cmpw    8, 6
        blt     .Li_sbf
        slwi    0, 6, 1
        add     7, 7, 0
        cmpwi   7, 1024
        blt     .Li_sblock
        slwi    5, 5, 1
        cmpwi   5, 2
        ble     .Li_slayer

        /* ---- vector layers: len = 4, 8, ..., 128 ---- */
.Li_vlayer:
        slwi    6, 5, 2
        li      7, 0
.Li_vblock:
        lwz     0, 0(4)
        neg     0, 0                    /* -zetas[k] */
        addi    4, 4, -4
        mtvsrd  32+8, 0
        xxspltw 32+8, 32+8, 1           /* v8 = -zeta */
        li      8, 0
.Li_vbf:
        add     9, 7, 8
        add     10, 9, 6
        lxvd2x  32+0, 9, 3              /* a */
        lxvd2x  32+1, 10, 3             /* b */
        vadduwm 2, 0, 1                 /* a + b -> r[j] */
        vsubuwm 1, 0, 1                 /* tmp = a - b */
        vmulesw 3, 1, 8                 /* mont(tmp*zeta) ... */
        vmulosw 4, 1, 8
        vmrgow  7, 3, 4
        vmuluwm 7, 7, 11
        vmulesw 5, 7, 10
        vmulosw 6, 7, 10
        vsubudm 3, 3, 5
        vsubudm 4, 4, 6
        vmrgew  1, 3, 4                 /* r[j+len]' = mont */
        stxvd2x 32+1, 10, 3
        stxvd2x 32+2, 9, 3
        addi    8, 8, 16
        cmpw    8, 6
        blt     .Li_vbf
        slwi    0, 6, 1
        add     7, 7, 0
        cmpwi   7, 1024
        blt     .Li_vblock
        slwi    5, 5, 1
        cmpwi   5, 128
        ble     .Li_vlayer

        /* ---- final scale: r[j] = montgomery_reduce(r[j] * 41978) ---- */
        li      0, 0
        ori     0, 0, 41978
        mtvsrd  32+8, 0
        xxspltw 32+8, 32+8, 1           /* v8 = f */
        li      8, 0
.Li_scale:
        lxvd2x  32+0, 8, 3
        vmulesw 3, 0, 8
        vmulosw 4, 0, 8
        vmrgow  7, 3, 4
        vmuluwm 7, 7, 11
        vmulesw 5, 7, 10
        vmulosw 6, 7, 10
        vsubudm 3, 3, 5
        vsubudm 4, 4, 6
        vmrgew  0, 3, 4
        stxvd2x 32+0, 8, 3
        addi    8, 8, 16
        cmpwi   8, 1024
        blt     .Li_scale

        ld      14, 16(1)
        ld      15, 24(1)
        ld      16, 32(1)
        addi    1, 1, 48
        blr
MLD_ASM_FN_SIZE(intt_ppc64le_asm)

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
          && __POWER8_VECTOR__ */
