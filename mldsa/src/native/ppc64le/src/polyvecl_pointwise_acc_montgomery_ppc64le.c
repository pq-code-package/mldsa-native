/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_PPC64LE) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include <altivec.h>

#define VLL0 ((__vector signed long long){0, 0})

/*************************************************
 * Name:        montgomery_reduce_ppc64le
 *
 * Description: Montgomery reduction for PPC64LE backend.
 *              Self-contained implementation without frontend dependencies.
 *              Given a 64-bit integer a, computes 32-bit integer congruent
 *              to a * R^-1 mod q, where R=2^32
 *
 * Arguments:   - int64_t a: input integer to be reduced
 *
 * Returns:     Integer congruent to a * R^-1 modulo q
 **************************************************/
static inline int32_t montgomery_reduce_ppc64le(int64_t a)
{
  /* check-magic: 58728449 == unsigned_mod(pow(MLDSA_Q, -1, 2^32), 2^32) */
  const uint64_t QINV = 58728449;

  /* Compute a*q^{-1} mod 2^32 in unsigned representatives */
  const uint32_t a_reduced = (uint32_t)(a & UINT32_MAX);
  const uint32_t a_inverted = (a_reduced * QINV) & UINT32_MAX;

  /* Lift to signed canonical representative mod 2^32 */
  const int32_t t = (int32_t)a_inverted;

  /* Montgomery reduction: (a - t*q) >> 32 */
  int64_t r = a - (int64_t)t * MLDSA_Q;
  r = r >> 32;

  return (int32_t)r;
}

/* Helper functions to load & store */
static inline __vector signed int vec_load_aligned_int(const int32_t *coef)
{
  const int32_t *coeff = coef;
  return *(const __vector signed int *)__builtin_assume_aligned(coeff, 16);
}

static inline void vec_store_llint(int64_t tmpv[2], __vector signed long long v)
{
  tmpv[0] = v[0];
  tmpv[1] = v[1];
}

/*************************************************
 * polyvecl_pointwise_acc_montgomery_core
 *
 * Core SIMD implementation for pointwise accumulation.
 * Processes 4 coefficients at a time using AltiVec instructions.
 *
 * Arguments:
 * - int32_t *w: output polynomial coefficients [MLDSA_N]
 * - const int32_t *u: first input vector as flat array [L][MLDSA_N]
 * - const int32_t *v: second input vector as flat array [L][MLDSA_N]
 * - unsigned int L: vector length (4, 5, or 7)
 **************************************************/
static void polyvecl_pointwise_acc_montgomery_core(int32_t *w, const int32_t *u,
                                                   const int32_t *v,
                                                   unsigned int L)
{
  size_t j, n;
  __vector signed long long ve, vo;
  __vector signed int va, vb;
  int64_t tmpve[2], tmpvo[2];

  for (n = 0; n < MLDSA_N; n += 4)
  {
    ve = vo = VLL0;
    for (j = 0; j < L; j++)
    {
      /* Load 4 coefficients from u[j][n] */
      const int32_t *u_ptr = u + j * MLDSA_N + n;

      /* Load 4 coefficients from v[j][n] */
      const int32_t *v_ptr = v + j * MLDSA_N + n;

      /* Load vectors (4 int32_t values each) */
      va = vec_load_aligned_int(u_ptr);
      vb = vec_load_aligned_int(v_ptr);

      /* vec_mule: multiply even lanes (0,2) → 2 int64_t results
       * vec_mulo: multiply odd lanes (1,3) → 2 int64_t results
       * accumulate products across all j columns */
      ve += (__vector signed long long)vec_mule(va, vb);
      vo += (__vector signed long long)vec_mulo(va, vb);
    }

    /* Extract accumulated 64-bit numbers to scalar array */
    vec_store_llint(tmpve, ve);
    vec_store_llint(tmpvo, vo);

    /* Apply montgomery reduction and store results
     * output order: [even0, odd0, even1, odd1] → [lane0, lane1, lane2, lane3]
     */
    int32_t *w_ptr = w + n;
    w_ptr[0] = montgomery_reduce_ppc64le(tmpve[0]);
    w_ptr[1] = montgomery_reduce_ppc64le(tmpvo[0]);
    w_ptr[2] = montgomery_reduce_ppc64le(tmpve[1]);
    w_ptr[3] = montgomery_reduce_ppc64le(tmpvo[1]);
  }
}

/*************************************************
 * mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le
 *
 * PPC64LE implementation of polyvecl_pointwise_acc_montgomery for L=4.
 * Pointwise multiply vectors of polynomials of length 4,
 * multiply resulting vector by 2^{-32} and add (accumulate)
 * polynomials in it.
 *
 * Arguments:
 * - int32_t w[MLDSA_N]: output polynomial
 * - const int32_t u[4][MLDSA_N]: first input vector
 * - const int32_t v[4][MLDSA_N]: second input vector
 **************************************************/
void mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N])
{
  polyvecl_pointwise_acc_montgomery_core(w, (const int32_t *)u,
                                         (const int32_t *)v, 4);
}

/*************************************************
 * mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le
 *
 * PPC64LE implementation of polyvecl_pointwise_acc_montgomery for L=5.
 * Pointwise multiply vectors of polynomials of length 5,
 * multiply resulting vector by 2^{-32} and add (accumulate)
 * polynomials in it.
 *
 * Arguments:
 * - int32_t w[MLDSA_N]: output polynomial
 * - const int32_t u[5][MLDSA_N]: first input vector
 * - const int32_t v[5][MLDSA_N]: second input vector
 **************************************************/
void mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N])
{
  polyvecl_pointwise_acc_montgomery_core(w, (const int32_t *)u,
                                         (const int32_t *)v, 5);
}

/*************************************************
 * mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le
 *
 * PPC64LE implementation of polyvecl_pointwise_acc_montgomery for L=7.
 * Pointwise multiply vectors of polynomials of length 7,
 * multiply resulting vector by 2^{-32} and add (accumulate)
 * polynomials in it.
 *
 * Arguments:
 * - int32_t w[MLDSA_N]: output polynomial
 * - const int32_t u[7][MLDSA_N]: first input vector
 * - const int32_t v[7][MLDSA_N]: second input vector
 **************************************************/
void mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N])
{
  polyvecl_pointwise_acc_montgomery_core(w, (const int32_t *)u,
                                         (const int32_t *)v, 7);
}

#endif /* MLD_ARITH_BACKEND_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef VLL0
