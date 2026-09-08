/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA pointwise polynomial multiplication with Montgomery
 * reduction. Computes
 *
 *     a[i] = (a[i] * b[i]) * R^-1  mod q,    R = 2^32, |result| < q,
 *
 * for 0 <= i < 256, in-place in a.
 *
 * Modular arithmetic: signed Montgomery reduction. Write R = 2^32 and
 * QINV = q^-1 mod R = 58728449. Unlike the NTT, neither operand is constant,
 * so a twisted constant cannot be precomputed. For p = a*b, the kernel uses
 * four multiplications:
 *
 *     plo = low(p)
 *     phi = high(p)
 *     m   = low(plo * QINV), interpreted as signed
 *     mhi = high(m * q)
 *     r   = phi - mhi = (p - m*q) / R.
 *
 * The low words of p and m*q agree because m*q == plo (mod R), so p-m*q
 * is divisible by R and the high-word subtraction computes its quotient.
 * Consequently r == a*b*R^-1 (mod q).
 *
 * MLD_NTT_BOUND is the exclusive postcondition of the generic C and native
 * forward-NTT interfaces and the exclusive input precondition of pointwise
 * Montgomery multiplication. It is therefore the full input range exposed
 * to this routine by the C/CBMC-facing interface, not an additional
 * assembly-specific assumption.
 *
 * Inputs satisfy
 *
 *   |a|, |b| < MLD_NTT_BOUND = 94279698,
 *   |p| < 94279698^2 = 8888661454971204
 *       < q*R/2 = 17996808470921216.
 *
 * Signed Montgomery reduction then gives |r| < |p|/R + q/2 < q. In
 * particular, `phi-mhi` is in signed int32 range and cannot overflow. The
 * q-bound is also the pointwise postcondition and the inverse-NTT input
 * precondition, so the forward NTT, pointwise product, and inverse NTT
 * compose under the shared contracts.
 */

/*yaml
  Name: poly_pointwise_montgomery_rv32im_asm
  Description: RV32IM pointwise Montgomery multiplication of two polynomials
  Signature: void mld_poly_pointwise_montgomery_rv32im_asm(int32_t a[256], const int32_t b[256])
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t a[256]
      description: Input/output polynomial (256 x int32_t)
    a1:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t b[256]
      description: Input polynomial (256 x int32_t)
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) &&                                      \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
     defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)) &&              \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

/*****************************************************************
 * Register aliases
 *****************************************************************/

/* Arguments */
#define a_ptr       a0
#define b_ptr       a1

/* Loop control */
#define a_end       t0          /* end-of-array sentinel for a_ptr */

/* Per-coefficient working set (caller-saved) */
#define a_val       a2
#define b_val       a3
#define product_lo  a4
#define product_hi  a5
#define factor      a6
#define factor_hi   a7

/* Constants (callee-saved) */
#define q           s0          /* MLDSA_Q = 8380417           */
#define qinv        s1          /* QINV    = 58728449          */

/*****************************************************************
 * Macros
 *****************************************************************/

/* montgomery_mul dst, lhs, rhs, lo, hi, m, mq_hi:
 *
 * Compute dst = lhs*rhs*R^-1 mod q with |dst| < q under the input bound
 * documented above. The macro expands to the five-instruction reduction
 * sequence and clobbers lo, hi, m, and mq_hi.
 */
.macro montgomery_mul dst, lhs, rhs, lo, hi, m, mq_hi
        mul   \lo,    \lhs, \rhs
        mulh  \hi,    \lhs, \rhs
        mul   \m,     \lo,  qinv
        /* Signed high word: `mulh` interprets m as signed. */
        mulh  \mq_hi, \m,   q
        sub   \dst,   \hi,  \mq_hi
.endm

/*****************************************************************
 * Function
 *****************************************************************/

        .text
        .global MLD_ASM_NAMESPACE(poly_pointwise_montgomery_rv32im_asm)
        .balign 4
MLD_ASM_FN_SYMBOL(poly_pointwise_montgomery_rv32im_asm)

        /* This function uses only s0/s1 from the callee-saved register set.
         * Preserve them while retaining the ILP32 ABI's 16-byte stack
         * alignment. */
        addi sp, sp, -16
        sw   s0, 0(sp)
        sw   s1, 4(sp)

        /* q    = 0x007FE001 */
        lui  q, 0x7FE
        addi q, q, 1
        /* qinv = 0x03802001 = 58728449
         *   lui qinv, 0x3802; addi qinv, qinv, 1  -> 0x03802001 */
        lui  qinv, 0x3802
        addi qinv, qinv, 1

        addi a_end, a_ptr, 1024     /* 256 * 4 bytes */

mld_poly_pointwise_montgomery_rv32im_loop:
        lw   a_val, 0(a_ptr)
        lw   b_val, 0(b_ptr)
        /* Bounds: |a_val|, |b_val| < MLD_NTT_BOUND = 94279698. */

        montgomery_mul a_val, a_val, b_val, product_lo, product_hi, factor, factor_hi
        /* Bounds: |a_val| < q. */

        sw   a_val, 0(a_ptr)

        addi a_ptr, a_ptr, 4
        addi b_ptr, b_ptr, 4
        bne  a_ptr, a_end, mld_poly_pointwise_montgomery_rv32im_loop

        lw   s0, 0(sp)
        lw   s1, 4(sp)
        addi sp, sp, 16
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef a_ptr
#undef b_ptr
#undef a_end
#undef a_val
#undef b_val
#undef product_lo
#undef product_hi
#undef factor
#undef factor_hi
#undef q
#undef qinv

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && (!MLD_CONFIG_NO_SIGN_API || \
          !MLD_CONFIG_NO_VERIFY_API || MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST) \
          && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
