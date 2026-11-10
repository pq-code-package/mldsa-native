/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Unpacking of bit-packed little-endian values of 18, 20 or 24 bits into
 * 32-bit lanes, shared by polyz_unpack_{17,19} and rej_uniform.
 *
 * Lane i holds bits [b*i, b*i + b) of the input, where b is the bit width.
 * These lie within the three bytes starting at off_i = (b*i) >> 3, at
 * shift s_i = (b*i) & 7, since s_i + b <= 24 for the supported widths.
 * The bytes are gathered into the lanes with vrgatherei16: byte k of lane i
 * is taken from off_i + min(k, 2). The fourth byte only duplicates the
 * third and is masked away, so the gather never reads beyond the
 * b*VL/8 bytes loaded. Each lane is then shifted right by s_i and masked
 * to b bits.
 *
 * The 32-bit lanes use register groups of 2 (LMUL=2), the bytes groups of
 * 2 at SEW=8, and the 16-bit gather indices groups of 4.
 *
 * Uses the scalar registers buf, vl, vl4 (= 4 * vl), nbytes, mask and
 * tmp, and the vector registers gidx, gtmp, shifts, src and coeffs, which
 * the including file must define. The indices and shifts depend only on
 * the lane, so the setup for VL = VLMAX also serves any smaller VL.
 */

/* Set up the gather indices and shifts for \bits-bit values and VL = vl. */
.macro unpack_setup bits
        slli        vl4, vl, 2
        li          tmp, \bits
        vsetvli     zero, vl4, e16, m4, ta, ma
        vid.v       gidx
        vsrl.vi     gtmp, gidx, 2
        vmul.vx     gtmp, gtmp, tmp
        vsrl.vi     gtmp, gtmp, 3
        vand.vi     gidx, gidx, 3
        vminu.vx    gidx, gidx, two
        vadd.vv     gidx, gidx, gtmp
.if \bits != 24
        vsetvli     zero, vl, e32, m2, ta, ma
        vid.v       shifts
        vmul.vx     shifts, shifts, tmp
        vand.vi     shifts, shifts, 7
.endif
        li          mask, ((1 << \bits) - 1)
.endm

/* Unpack vl \bits-bit values from the nbytes = \bits*vl/8 bytes at buf into
 * coeffs. Leaves VL = vl at e32,m2. */
.macro unpack bits
        vsetvli     zero, nbytes, e8, m2, ta, ma
        vle8.v      src, (buf)
        vsetvli     zero, vl4, e8, m2, ta, ma
        vrgatherei16.vv coeffs, src, gidx
        vsetvli     zero, vl, e32, m2, ta, ma
.if \bits != 24
        vsrl.vv     coeffs, coeffs, shifts
.endif
        vand.vx     coeffs, coeffs, mask
.endm
