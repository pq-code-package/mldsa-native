/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [FIPS204]
 *   FIPS 204 Module-Lattice-Based Digital Signature Standard
 *   National Institute of Standards and Technology
 *   https://csrc.nist.gov/pubs/fips/204/final
 */

#include "polyvec_lazy.h"

#include "debug.h"

/* This namespacing is not done at the top to avoid a naming conflict
 * with native backends, which are currently not yet namespaced. */
#define mld_polymat_expand_entry MLD_ADD_PARAM_SET(mld_polymat_expand_entry)

/*************************************************
 * Name:        mld_polymat_expand_entry
 *
 * Description: Sample a single matrix entry A[k][l] of ExpandA(rho)
 *              by rejection sampling from SHAKE128(rho|l|k), and
 *              apply the custom-order permutation when a native NTT
 *              backend is in use.
 *
 *              The caller is expected to have copied rho into the
 *              first MLDSA_SEEDBYTES of seed_ext. This function writes
 *              the domain-separation bytes seed_ext[SEEDBYTES..+2] =
 *              {l, k} before sampling.
 *
 * Arguments:   - mld_poly *p: pointer to output polynomial
 *              - uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)]:
 *                  seed buffer pre-filled with rho in the first
 *                  MLDSA_SEEDBYTES; the final two bytes are overwritten.
 *              - uint8_t l: column index (inner, aka nonce low byte)
 *              - uint8_t k: row index (outer, aka nonce high byte)
 **************************************************/
static MLD_INLINE void mld_polymat_expand_entry(
    mld_poly *p, uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)], uint8_t l,
    uint8_t k)
{
  seed_ext[MLDSA_SEEDBYTES + 0] = l;
  seed_ext[MLDSA_SEEDBYTES + 1] = k;
  mld_poly_uniform(p, seed_ext);
  mld_poly_permute_bitrev_to_custom_optional(p);
}

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)

MLD_INTERNAL_API
void mld_polyvec_matrix_expand_eager(mld_polymat_eager *mat,
                                     const uint8_t rho[MLDSA_SEEDBYTES])
{
  unsigned int i, j;
  MLD_ALIGN uint8_t seed_ext[4][MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];

  for (j = 0; j < 4; j++)
  __loop__(
    assigns(j, object_whole(seed_ext))
    invariant(j <= 4)
    decreases(4 - j)
  )
  {
    mld_memcpy(seed_ext[j], rho, MLDSA_SEEDBYTES);
  }

#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY)
  /* Sample 4 matrix entries a time. */
  for (i = 0; i < (MLDSA_K * MLDSA_L / 4) * 4; i += 4)
  __loop__(
    assigns(i, j, object_whole(seed_ext), memory_slice(mat, sizeof(mld_polymat_eager)))
    invariant(i <= (MLDSA_K * MLDSA_L / 4) * 4 && i % 4 == 0)
    /* vectors 0 .. i / MLDSA_L are completely sampled */
    invariant(forall(k1, 0, i / MLDSA_L, forall(l1, 0, MLDSA_L,
      array_bound(mat->vec[k1].vec[l1].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
    /* last vector is sampled up to i % MLDSA_L */
    invariant(forall(k2, i / MLDSA_L, i / MLDSA_L + 1, forall(l2, 0, i % MLDSA_L,
      array_bound(mat->vec[k2].vec[l2].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
    decreases((MLDSA_K * MLDSA_L / 4) * 4 - i)
  )
  {
    for (j = 0; j < 4; j++)
    __loop__(
      assigns(j, object_whole(seed_ext))
      invariant(j <= 4)
      decreases(4 - j)
    )
    {
      uint8_t x = (uint8_t)((i + j) / MLDSA_L);
      uint8_t y = (uint8_t)((i + j) % MLDSA_L);

      seed_ext[j][MLDSA_SEEDBYTES + 0] = y;
      seed_ext[j][MLDSA_SEEDBYTES + 1] = x;
    }

    mld_poly_uniform_4x(&mat->vec[i / MLDSA_L].vec[i % MLDSA_L],
                        &mat->vec[(i + 1) / MLDSA_L].vec[(i + 1) % MLDSA_L],
                        &mat->vec[(i + 2) / MLDSA_L].vec[(i + 2) % MLDSA_L],
                        &mat->vec[(i + 3) / MLDSA_L].vec[(i + 3) % MLDSA_L],
                        seed_ext);
    mld_poly_permute_bitrev_to_custom_optional(
        &mat->vec[i / MLDSA_L].vec[i % MLDSA_L]);
    mld_poly_permute_bitrev_to_custom_optional(
        &mat->vec[(i + 1) / MLDSA_L].vec[(i + 1) % MLDSA_L]);
    mld_poly_permute_bitrev_to_custom_optional(
        &mat->vec[(i + 2) / MLDSA_L].vec[(i + 2) % MLDSA_L]);
    mld_poly_permute_bitrev_to_custom_optional(
        &mat->vec[(i + 3) / MLDSA_L].vec[(i + 3) % MLDSA_L]);
  }
#else  /* !MLD_CONFIG_SERIAL_FIPS202_ONLY */
  i = 0;
#endif /* MLD_CONFIG_SERIAL_FIPS202_ONLY */

  /* Entries omitted by the batch-sampling are sampled individually. */
  while (i < MLDSA_K * MLDSA_L)
  __loop__(
    assigns(i, object_whole(seed_ext), memory_slice(mat, sizeof(mld_polymat_eager)))
    invariant(i <= MLDSA_K * MLDSA_L)
    /* vectors 0 .. i / MLDSA_L are completely sampled */
    invariant(forall(k1, 0, i / MLDSA_L, forall(l1, 0, MLDSA_L,
      array_bound(mat->vec[k1].vec[l1].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
    /* last vector is sampled up to i % MLDSA_L */
    invariant(forall(k2, i / MLDSA_L, i / MLDSA_L + 1, forall(l2, 0, i % MLDSA_L,
      array_bound(mat->vec[k2].vec[l2].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
    decreases(MLDSA_K * MLDSA_L - i)
  )
  {
    uint8_t x = (uint8_t)(i / MLDSA_L);
    uint8_t y = (uint8_t)(i % MLDSA_L);
    mld_polymat_expand_entry(&mat->vec[x].vec[y], seed_ext[0], y, x);
    i++;
  }

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
}

MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_eager(mld_polyveck *t,
                                                   mld_polymat_eager *mat,
                                                   const mld_polyvecl *v)
{
  unsigned int i;
  mld_assert_abs_bound_2d(v->vec, MLDSA_L, MLDSA_N, MLD_NTT_BOUND);

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    assigns(i, memory_slice(t, sizeof(mld_polyveck)))
    invariant(i <= MLDSA_K)
    invariant(forall(k0, 0, i,
                     array_abs_bound(t->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
    decreases(MLDSA_K - i)
  )
  {
    mld_polyvecl_pointwise_acc_montgomery(&t->vec[i], &mat->vec[i], v);
  }

  mld_assert_abs_bound_2d(t->vec, MLDSA_K, MLDSA_N, MLDSA_Q);
}

#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)

MLD_INTERNAL_API
void mld_polyvec_matrix_expand_lazy(mld_polymat_lazy *mat,
                                    const uint8_t rho[MLDSA_SEEDBYTES])
{
  mld_memcpy(mat->rho, rho, MLDSA_SEEDBYTES);
}

MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_lazy(mld_polyveck *t,
                                                  mld_polymat_lazy *mat,
                                                  const mld_polyvecl *v)
{
  unsigned int i, l;
  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  mld_memcpy(seed_ext, mat->rho, MLDSA_SEEDBYTES);

  for (i = 0; i < MLDSA_K; ++i)
  {
    mld_polymat_expand_entry(&mat->cur, seed_ext, 0, (uint8_t)i);
    mld_poly_pointwise_montgomery(&t->vec[i], &mat->cur, &v->vec[0]);

    for (l = 1; l < MLDSA_L; ++l)
    {
      mld_polymat_expand_entry(&mat->cur, seed_ext, (uint8_t)l, (uint8_t)i);
      /* TODO: if mld_poly_pointwise_montgomery's CBMC and HOL Light specs
       * are strengthened to permit aliasing, the product can be written
       * in place into mat->cur and the separate mat->tmp field dropped. */
      mld_poly_pointwise_montgomery(&mat->tmp, &mat->cur, &v->vec[l]);
      mld_poly_add(&t->vec[i], &mat->tmp);
    }
    mld_poly_reduce(&t->vec[i]);
  }

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
}

#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef mld_polymat_expand_entry
