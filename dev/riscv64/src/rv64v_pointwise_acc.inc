/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Shared body of polyvecl_pointwise_acc_montgomery_l{4,5,7}: computes
 *
 *   w[i] = (sum_l u[l][i] * v[l][i]) * 2^-32 mod q
 *
 * accumulating the products in 64 bits and reducing once, as the C
 * reference does; see rv64v_montgomery.inc.
 *
 * Vector-length agnostic: works for any VLEN. The 32-bit inputs use
 * register groups of 4 (LMUL=4), the 64-bit accumulator groups of 8. VLMAX
 * for e32,m4 is a power of 2, so it either divides 256 or exceeds it.
 * Hence a single vsetvli with AVL = 256 yields a VL that is used unchanged
 * for every iteration.
 *
 * Bounds: 0 <= u < q and |v| < MLD_NTT_BOUND, so for L <= 7 the sum is
 * bounded by 7 * q * MLD_NTT_BOUND < 2^31 * q in absolute value, and the
 * result by q.
 */

#define w_ptr           a0
#define u_ptr           a1
#define v_ptr           a2
#define count           a3
#define u_cur           a4
#define v_cur           a5
#define poly_bytes      a6
#define vl              t0
#define modulus         t1
#define qinv            t2
#define stride          t3
#define shift32         t4

#define u_vec           v0  /* register group of 4 */
#define v_vec           v4  /* register group of 4 */
#define acc             v8  /* register group of 8 (64-bit lanes) */
#define acc_lo          v16 /* register group of 4 */
#define acc_hi          v20 /* register group of 4 */

#include "rv64v_montgomery.inc"

/* \len: number of polynomials L. \loop: loop label. */
.macro pointwise_acc_montgomery len, loop
        montgomery_setup
        li          count, MLDSA_N
        li          shift32, 32
        li          poly_bytes, (4 * MLDSA_N)

        vsetvli     vl, count, e32, m4, ta, ma
        slli        stride, vl, 2

\loop:
        vle32.v     u_vec, (u_ptr)
        vle32.v     v_vec, (v_ptr)
        vwmul.vv    acc, u_vec, v_vec
        mv          u_cur, u_ptr
        mv          v_cur, v_ptr
        .rept \len - 1
        add         u_cur, u_cur, poly_bytes
        add         v_cur, v_cur, poly_bytes
        vle32.v     u_vec, (u_cur)
        vle32.v     v_vec, (v_cur)
        vwmacc.vv   acc, u_vec, v_vec
        .endr

        vnsrl.wi    acc_lo, acc, 0
        vnsra.wx    acc_hi, acc, shift32
        montgomery_reduce acc_lo, acc_lo, acc_hi
        vse32.v     acc_lo, (w_ptr)

        add         w_ptr, w_ptr, stride
        add         u_ptr, u_ptr, stride
        add         v_ptr, v_ptr, stride
        sub         count, count, vl
        bnez        count, \loop
.endm
