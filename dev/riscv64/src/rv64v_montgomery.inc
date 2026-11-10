/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Signed Montgomery reduction at SEW=32, shared by the pointwise
 * multiplications.
 *
 * For a 64-bit value p = phi * 2^32 + plo with |p| < 2^31 * q, and
 * QINV = q^-1 mod 2^32:
 *
 *   m = low(plo * QINV), interpreted as signed
 *   r = phi - high(m * q) = (p - m * q) / 2^32
 *
 * The low words of p and m * q agree, so p - m * q is divisible by 2^32 and
 * the high-word difference computes the quotient without a borrow. Hence
 * r == p * 2^-32 mod q and |r| < |p| / 2^32 + q / 2 < q. This is the
 * computation of mld_montgomery_reduce() in the C reference.
 *
 * Uses the scalar registers modulus and qinv, which the including file
 * must define.
 */

/* Load the scalar constants. */
.macro montgomery_setup
        li          modulus, MLDSA_Q
        li          qinv, 58728449         // q^-1 mod 2^32
.endm

/* \r = Montgomery reduction of \lo, \hi (low and high halves of p), at the
 * current LMUL. Clobbers \lo. \r may alias \hi. */
.macro montgomery_reduce r, lo, hi
        vmul.vx     \lo, \lo, qinv
        vmulh.vx    \lo, \lo, modulus
        vsub.vv     \r, \hi, \lo
.endm
