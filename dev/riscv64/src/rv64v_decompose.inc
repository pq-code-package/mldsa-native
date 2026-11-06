/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Decompose, shared by poly_decompose_{32,88} and poly_use_hint_{32,88}.
 * Mirrors mld_decompose() in the C reference, which documents the
 * approximations used. For 0 <= a < q, computes a1, a0 with
 * a mod q = a1 * 2 * GAMMA2 + a0:
 *
 *   a1 = (a + 127) >> 7
 *   GAMMA2 = (q-1)/32: a1 = ((a1 * 1025 + 2^21) >> 22) & 15
 *   GAMMA2 = (q-1)/88: a1 = (a1 * 11275 + 2^23) >> 24; a1 = 0 if a1 > 43
 *   a0 = a - a1 * 2 * GAMMA2
 *   a0 = a0 - q if a0 > (q-1)/2
 *
 * Uses the scalar registers c127, dec_mul, dec_round, two_gamma2,
 * half_q, modulus and (for GAMMA2 = (q-1)/88) c43, which the including
 * file must define.
 */

/* Load the scalar constants for \gamma2_div = 32 or 88. */
.macro decompose_setup gamma2_div
        li          modulus, MLDSA_Q
        li          c127, 127
        li          half_q, ((MLDSA_Q - 1) / 2)
        li          two_gamma2, (2 * ((MLDSA_Q - 1) / \gamma2_div))
.if \gamma2_div == 32
        li          dec_mul, 1025
        li          dec_round, (1 << 21)
.else
        li          dec_mul, 11275
        li          dec_round, (1 << 23)
        li          c43, 43
.endif
.endm

/* \a1, \a0 = decompose(\a0), at the current LMUL. \t is a temporary. */
.macro decompose gamma2_div, a1, a0, t
        vadd.vx     \a1, \a0, c127
        vsra.vi     \a1, \a1, 7
        vmul.vx     \a1, \a1, dec_mul
        vadd.vx     \a1, \a1, dec_round
.if \gamma2_div == 32
        vsra.vi     \a1, \a1, 22
        vand.vi     \a1, \a1, 15
.else
        vsra.vi     \a1, \a1, 24
        /* a1 ^= ((43 - a1) >> 31) & a1, that is, a1 = 0 if a1 > 43 */
        vrsub.vx    \t, \a1, c43
        vsra.vi     \t, \t, 31
        vand.vv     \t, \t, \a1
        vxor.vv     \a1, \a1, \t
.endif
        vnmsac.vx   \a0, two_gamma2, \a1
        /* a0 -= ((half_q - a0) >> 31) & q */
        vrsub.vx    \t, \a0, half_q
        vsra.vi     \t, \t, 31
        vand.vx     \t, \t, modulus
        vsub.vv     \a0, \a0, \t
.endm
