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
#define mld_polymat_macc_cell MLD_ADD_PARAM_SET(mld_polymat_macc_cell)

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
__contract__(
  requires(memory_no_alias(p, sizeof(mld_poly)))
  requires(memory_no_alias(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  assigns(memory_slice(p, sizeof(mld_poly)))
  assigns(memory_slice(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  ensures(array_bound(p->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
)
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
void mld_polyvec_matrix_pointwise_montgomery_row_eager(mld_poly *t_row,
                                                       mld_polymat_eager *mat,
                                                       const mld_polyvecl *v,
                                                       unsigned int i)
{
  mld_polyvecl_pointwise_acc_montgomery(t_row, &mat->vec[i], v);
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_yvec_eager(mld_polyveck *w,
                                                        mld_polymat_eager *mat,
                                                        const mld_yvec_eager *y,
                                                        mld_polyvecl *scratch)
{
  unsigned int i;
  *scratch = y->vec;
  mld_polyvecl_ntt(scratch);

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    assigns(i, memory_slice(w, sizeof(mld_polyveck)))
    invariant(i <= MLDSA_K)
    invariant(forall(k0, 0, i,
                     array_abs_bound(w->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
    decreases(MLDSA_K - i)
  )
  {
    mld_polyvec_matrix_pointwise_montgomery_row_eager(&w->vec[i], mat, scratch,
                                                      i);
  }

  mld_polyveck_invntt_tomont(w);
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)

MLD_INTERNAL_API
void mld_polyvec_matrix_expand_lazy(mld_polymat_lazy *mat,
                                    const uint8_t rho[MLDSA_SEEDBYTES])
{
  mld_memcpy(mat->rho, rho, MLDSA_SEEDBYTES);
}

/*************************************************
 * Name:        mld_polymat_macc_cell
 *
 * Description: Multiply-accumulate one cell of a lazy matrix-vector product:
 *
 *                  out (op)= polymat_expand_entry(seed_ext, l, k) * operand,
 *
 *              where (op) is "=" on the first call (acc_count == 0) and "+="
 *              on subsequent calls. On the first call, out is overwritten and
 *              its prior contents are ignored; on subsequent calls, scratch
 *              is used as temporary storage for the sampled matrix entry.
 *
 *              acc_count is the number of accumulations already applied to
 *              out (0 on the first call, 1 after the first, etc.).
 *
 * Arguments:   - mld_poly *out: pointer to accumulator polynomial
 *              - mld_poly *scratch: temporary polynomial storage
 *              - uint8_t seed_ext[...]: seed buffer (last 2 bytes overwritten)
 *              - uint8_t l: column index (inner)
 *              - uint8_t k: row index (outer)
 *              - const mld_poly *operand: pointer to operand polynomial
 *              - unsigned int acc_count: number of accumulations already done
 **************************************************/
static MLD_INLINE void mld_polymat_macc_cell(
    mld_poly *out, mld_poly *scratch,
    uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)], uint8_t l, uint8_t k,
    const mld_poly *operand, unsigned int acc_count)
__contract__(
  requires(memory_no_alias(out, sizeof(mld_poly)))
  requires(memory_no_alias(scratch, sizeof(mld_poly)))
  requires(memory_no_alias(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  requires(memory_no_alias(operand, sizeof(mld_poly)))
  requires(array_abs_bound(operand->coeffs, 0, MLDSA_N, MLD_NTT_BOUND))
  requires(acc_count < MLDSA_L)
  requires(acc_count == 0 ||
           array_abs_bound(out->coeffs, 0, MLDSA_N,
                           (int)acc_count * MLDSA_Q))
  assigns(memory_slice(out, sizeof(mld_poly)))
  assigns(memory_slice(scratch, sizeof(mld_poly)))
  assigns(memory_slice(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  ensures(array_abs_bound(out->coeffs, 0, MLDSA_N,
                          ((int)acc_count + 1) * MLDSA_Q))
)
{
  if (acc_count == 0)
  {
    mld_polymat_expand_entry(out, seed_ext, l, k);
    mld_poly_pointwise_montgomery(out, operand);
  }
  else
  {
    mld_polymat_expand_entry(scratch, seed_ext, l, k);
    mld_poly_pointwise_montgomery(scratch, operand);
    mld_poly_add(out, scratch);
  }
}

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_row_lazy(mld_poly *t_row,
                                                      mld_polymat_lazy *mat,
                                                      const mld_polyvecl *v,
                                                      unsigned int i)
{
  unsigned int l;
  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  mld_memcpy(seed_ext, mat->rho, MLDSA_SEEDBYTES);

  for (l = 0; l < MLDSA_L; ++l)
  __loop__(
    assigns(l, object_whole(seed_ext),
            memory_slice(t_row, sizeof(mld_poly)),
            memory_slice(mat, sizeof(mld_polymat_lazy)))
    invariant(l <= MLDSA_L)
    invariant(l == 0 ||
              array_abs_bound(t_row->coeffs, 0, MLDSA_N, (int)l * MLDSA_Q))
    decreases(MLDSA_L - l)
  )
  {
    mld_polymat_macc_cell(t_row, &mat->cur, seed_ext, (uint8_t)l, (uint8_t)i,
                          &v->vec[l], l);
  }
  mld_poly_reduce(t_row);

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_yvec_lazy(mld_polyveck *w,
                                                       mld_polymat_lazy *mat,
                                                       const mld_yvec_lazy *y,
                                                       mld_polyvecl *scratch)
{
  unsigned int k, l;
  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  /* Only the first poly of the polyvecl scratch is used. The polyvecl type
   * matches the eager variant for API uniformity; in REDUCE_RAM mode the
   * polyvecl storage is provided "for free" by the caller's polyveck/polyvecl
   * union. */
  mld_poly *y_ntt = &scratch->vec[0];

  mld_memcpy(seed_ext, mat->rho, MLDSA_SEEDBYTES);

  /* Column-by-column: sample y[l], NTT, accumulate column l of A into w. */
  for (l = 0; l < MLDSA_L; l++)
  __loop__(
    assigns(k, l, object_whole(seed_ext),
            memory_slice(w, sizeof(mld_polyveck)),
            memory_slice(mat, sizeof(mld_polymat_lazy)),
            memory_slice(scratch, sizeof(mld_polyvecl)))
    invariant(l <= MLDSA_L)
    invariant(l == 0 ||
              forall(k0, 0, MLDSA_K,
                     array_abs_bound(w->vec[k0].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q)))
    decreases(MLDSA_L - l)
  )
  {
    mld_yvec_get_poly_lazy(y_ntt, y, l);
    mld_poly_ntt(y_ntt);
    for (k = 0; k < MLDSA_K; k++)
    __loop__(
      assigns(k, object_whole(seed_ext),
              memory_slice(w, sizeof(mld_polyveck)),
              memory_slice(mat, sizeof(mld_polymat_lazy)))
      invariant(k <= MLDSA_K)
      invariant(forall(k1, 0, k,
                       array_abs_bound(w->vec[k1].coeffs, 0, MLDSA_N,
                                       ((int)l + 1) * MLDSA_Q)))
      invariant(l == 0 ||
                forall(k2, k, MLDSA_K,
                       array_abs_bound(w->vec[k2].coeffs, 0, MLDSA_N,
                                       (int)l * MLDSA_Q)))
      decreases(MLDSA_K - k)
    )
    {
      mld_polymat_macc_cell(&w->vec[k], &mat->cur, seed_ext, (uint8_t)l,
                            (uint8_t)k, y_ntt, l);
    }
  }

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
  mld_polyveck_reduce(w);
  mld_polyveck_invntt_tomont(w);
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef mld_polymat_expand_entry
#undef mld_polymat_macc_cell
