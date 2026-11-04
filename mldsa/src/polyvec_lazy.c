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
#define mld_polymat_expand_column4 MLD_ADD_PARAM_SET(mld_polymat_expand_column4)
#define mld_poly_accumulate_column_entry \
  MLD_ADD_PARAM_SET(mld_poly_accumulate_column_entry)
#define mld_poly_accumulate_column4 \
  MLD_ADD_PARAM_SET(mld_poly_accumulate_column4)
#define mld_polyveck_accumulate_column_x4 \
  MLD_ADD_PARAM_SET(mld_polyveck_accumulate_column_x4)

#if defined(MLD_CONFIG_REDUCE_RAM_X4)
/* Four entries from one column, without retaining complete matrix rows. */
static void mld_polymat_expand_column4(mld_poly p[4],
                                       const uint8_t rho[MLDSA_SEEDBYTES],
                                       unsigned int k, unsigned int l)
__contract__(
  requires(memory_no_alias(p, 4 * sizeof(mld_poly)))
  requires(memory_no_alias(rho, MLDSA_SEEDBYTES))
  requires(k <= MLDSA_K - 4)
  requires(l < MLDSA_L)
  assigns(memory_slice(p, 4 * sizeof(mld_poly)))
  ensures(array_bound(p[0].coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  ensures(array_bound(p[1].coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  ensures(array_bound(p[2].coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  ensures(array_bound(p[3].coeffs, 0, MLDSA_N, 0, MLDSA_Q))
)
{
  unsigned int j;
  MLD_ALIGN uint8_t seed[4][MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  for (j = 0; j < 4; j++)
  __loop__(
    assigns(j, object_whole(seed))
    invariant(j <= 4)
    decreases(4 - j)
  )
  {
    mld_memcpy(seed[j], rho, MLDSA_SEEDBYTES);
    seed[j][MLDSA_SEEDBYTES] = (uint8_t)l;
    seed[j][MLDSA_SEEDBYTES + 1] = (uint8_t)(k + j);
  }
  mld_poly_uniform_4x(&p[0], &p[1], &p[2], &p[3], seed);
  for (j = 0; j < 4; j++)
  __loop__(
    assigns(j, memory_slice(p, 4 * sizeof(mld_poly)))
    invariant(j <= 4)
    invariant(forall(j0, 0, 4,
      array_bound(p[j0].coeffs, 0, MLDSA_N, 0, MLDSA_Q)))
    decreases(4 - j)
  )
  {
    mld_poly_permute_bitrev_to_custom_optional(&p[j]);
  }
  mld_zeroize(seed, sizeof(seed));
}

/* Accumulate one sampled column entry into a row of A * v. */
static MLD_INLINE void mld_poly_accumulate_column_entry(mld_poly *acc,
                                                        mld_poly *entry,
                                                        const mld_poly *v,
                                                        unsigned int l)
__contract__(
  requires(memory_no_alias(acc, sizeof(mld_poly)))
  requires(memory_no_alias(entry, sizeof(mld_poly)))
  requires(memory_no_alias(v, sizeof(mld_poly)))
  requires(l < MLDSA_L)
  requires(array_bound(entry->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_abs_bound(v->coeffs, 0, MLDSA_N, MLD_NTT_BOUND))
  requires(l == 0 ||
           array_abs_bound(acc->coeffs, 0, MLDSA_N, (int)l * MLDSA_Q))
  assigns(memory_slice(acc, sizeof(mld_poly)))
  assigns(memory_slice(entry, sizeof(mld_poly)))
  ensures(array_abs_bound(acc->coeffs, 0, MLDSA_N,
                          ((int)l + 1) * MLDSA_Q))
)
{
  mld_poly_pointwise_montgomery(entry, v);
  if (l == 0)
  {
    *acc = *entry;
  }
  else
  {
    mld_poly_add(acc, entry);
  }
}

/* Consume one matrix column for four consecutive rows. */
static void mld_poly_accumulate_column4(mld_poly acc[4], mld_polymat_lazy *mat,
                                        const mld_poly *v, unsigned int k,
                                        unsigned int l)
__contract__(
  requires(memory_no_alias(acc, 4 * sizeof(mld_poly)))
  requires(memory_no_alias(mat, sizeof(mld_polymat_lazy)))
  requires(memory_no_alias(v, sizeof(mld_poly)))
  requires(k <= MLDSA_K - 4)
  requires(l < MLDSA_L)
  requires(array_abs_bound(v->coeffs, 0, MLDSA_N, MLD_NTT_BOUND))
  requires(l == 0 || array_abs_bound(acc[0].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q))
  requires(l == 0 || array_abs_bound(acc[1].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q))
  requires(l == 0 || array_abs_bound(acc[2].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q))
  requires(l == 0 || array_abs_bound(acc[3].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q))
  assigns(memory_slice(acc, 4 * sizeof(mld_poly)))
  assigns(memory_slice(mat->cur, 4 * sizeof(mld_poly)))
  ensures(array_abs_bound(acc[0].coeffs, 0, MLDSA_N,
                          ((int)l + 1) * MLDSA_Q))
  ensures(array_abs_bound(acc[1].coeffs, 0, MLDSA_N,
                          ((int)l + 1) * MLDSA_Q))
  ensures(array_abs_bound(acc[2].coeffs, 0, MLDSA_N,
                          ((int)l + 1) * MLDSA_Q))
  ensures(array_abs_bound(acc[3].coeffs, 0, MLDSA_N,
                          ((int)l + 1) * MLDSA_Q))
)
{
  mld_polymat_expand_column4(mat->cur, mat->rho, k, l);
  mld_poly_accumulate_column_entry(&acc[0], &mat->cur[0], v, l);
  mld_poly_accumulate_column_entry(&acc[1], &mat->cur[1], v, l);
  mld_poly_accumulate_column_entry(&acc[2], &mat->cur[2], v, l);
  mld_poly_accumulate_column_entry(&acc[3], &mat->cur[3], v, l);
}
#endif /* MLD_CONFIG_REDUCE_RAM_X4 */

/**
 * Sample a single matrix entry A[k][l] of ExpandA(rho) by rejection sampling
 * from SHAKE128(rho|l|k), and apply the custom-order permutation when a
 * native NTT backend is in use.
 *
 * The caller is expected to have copied rho into the first MLDSA_SEEDBYTES
 * of seed_ext. This function writes the domain-separation bytes
 * seed_ext[SEEDBYTES..+2] = {l, k} before sampling.
 *
 * @spec{Partially implements @[FIPS204, Algorithm 32, ExpandA] (samples one
 * matrix entry via @[FIPS204, Algorithm 30, RejNTTPoly]).}
 *
 * @param[out]    p        Pointer to output polynomial.
 * @param[in,out] seed_ext Seed buffer pre-filled with rho in the first
 *                         MLDSA_SEEDBYTES; the final two bytes are
 *                         overwritten.
 * @param         l        Column index (inner, aka nonce low byte).
 * @param         k        Row index (outer, aka nonce high byte).
 */
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

#if defined(MLD_CONFIG_REDUCE_RAM_X4) && !defined(MLD_CONFIG_NO_SIGN_API)
#define MLD_X4_COLUMN_INPUT(row) \
  requires(l == 0 ||             \
           array_abs_bound(w->vec[row].coeffs, 0, MLDSA_N, (int)l * MLDSA_Q))
#define MLD_X4_COLUMN_OUTPUT(row) \
  ensures(                        \
      array_abs_bound(w->vec[row].coeffs, 0, MLDSA_N, ((int)l + 1) * MLDSA_Q))
#if MLDSA_K == 4
#define MLD_X4_COLUMN_EXTRA_INPUT
#define MLD_X4_COLUMN_EXTRA_OUTPUT
#elif MLDSA_K == 6
#define MLD_X4_COLUMN_EXTRA_INPUT MLD_X4_COLUMN_INPUT(4) MLD_X4_COLUMN_INPUT(5)
#define MLD_X4_COLUMN_EXTRA_OUTPUT \
  MLD_X4_COLUMN_OUTPUT(4) MLD_X4_COLUMN_OUTPUT(5)
#elif MLDSA_K == 8
#define MLD_X4_COLUMN_EXTRA_INPUT \
  MLD_X4_COLUMN_INPUT(4)          \
  MLD_X4_COLUMN_INPUT(5) MLD_X4_COLUMN_INPUT(6) MLD_X4_COLUMN_INPUT(7)
#define MLD_X4_COLUMN_EXTRA_OUTPUT \
  MLD_X4_COLUMN_OUTPUT(4)          \
  MLD_X4_COLUMN_OUTPUT(5) MLD_X4_COLUMN_OUTPUT(6) MLD_X4_COLUMN_OUTPUT(7)
#else /* MLDSA_K == 8 */
#error Unsupported MLDSA_K for reduced-RAM x4 column accumulation.
#endif /* MLDSA_K != 4 && MLDSA_K != 6 && MLDSA_K != 8 */
/* Accumulate one signing column over the supported matrix row counts. */
static void mld_polyveck_accumulate_column_x4(
    mld_polyveck *w, mld_polymat_lazy *mat, const mld_poly *v,
    uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)], unsigned int l)
__contract__(
  requires(memory_no_alias(w, sizeof(mld_polyveck)))
  requires(memory_no_alias(mat, sizeof(mld_polymat_lazy)))
  requires(memory_no_alias(v, sizeof(mld_poly)))
  requires(memory_no_alias(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  requires(l < MLDSA_L)
  requires(array_abs_bound(v->coeffs, 0, MLDSA_N, MLD_NTT_BOUND))
  MLD_X4_COLUMN_INPUT(0)
  MLD_X4_COLUMN_INPUT(1)
  MLD_X4_COLUMN_INPUT(2)
  MLD_X4_COLUMN_INPUT(3)
  MLD_X4_COLUMN_EXTRA_INPUT
  assigns(memory_slice(w, sizeof(mld_polyveck)))
  assigns(memory_slice(mat->cur, 4 * sizeof(mld_poly)))
  assigns(memory_slice(seed_ext, MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)))
  MLD_X4_COLUMN_OUTPUT(0)
  MLD_X4_COLUMN_OUTPUT(1)
  MLD_X4_COLUMN_OUTPUT(2)
  MLD_X4_COLUMN_OUTPUT(3)
  MLD_X4_COLUMN_EXTRA_OUTPUT
)
{
  mld_poly_accumulate_column4(&w->vec[0], mat, v, 0, l);
#if MLDSA_K == 6
  /* The final two ML-DSA-65 rows use scalar sampling. */
  mld_polymat_expand_entry(&mat->cur[0], seed_ext, (uint8_t)l, 4);
  mld_poly_accumulate_column_entry(&w->vec[4], &mat->cur[0], v, l);
  mld_polymat_expand_entry(&mat->cur[0], seed_ext, (uint8_t)l, 5);
  mld_poly_accumulate_column_entry(&w->vec[5], &mat->cur[0], v, l);
#elif MLDSA_K == 8
  mld_poly_accumulate_column4(&w->vec[4], mat, v, 4, l);
#elif MLDSA_K != 4
#error Unsupported MLDSA_K for reduced-RAM x4 column accumulation.
#endif
  (void)seed_ext;
}
#undef MLD_X4_COLUMN_INPUT
#undef MLD_X4_COLUMN_OUTPUT
#undef MLD_X4_COLUMN_EXTRA_INPUT
#undef MLD_X4_COLUMN_EXTRA_OUTPUT
#endif /* MLD_CONFIG_REDUCE_RAM_X4 && !MLD_CONFIG_NO_SIGN_API */

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
void mld_polyvec_matrix_pointwise_montgomery_yvec_eager(
    mld_polyveck *w, mld_polymat_eager *mat, const mld_yvec_eager *y,
    mld_yvec_scratch_eager *scratch)
{
  unsigned int i;
  *scratch = y->vec;
  mld_polyvecl_ntt(scratch);

  for (i = 0; i < MLDSA_K; i++)
  __loop__(
    assigns(i, memory_slice(w, sizeof(mld_polyveck)))
    invariant(i <= MLDSA_K)
    invariant(forall(k0, 0, i, MLDSA_K,
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

  mld_polymat_expand_entry(t_row, seed_ext, 0, (uint8_t)i);
  mld_poly_pointwise_montgomery(t_row, &v->vec[0]);

  for (l = 1; l < MLDSA_L; l++)
  __loop__(
    assigns(l, object_whole(seed_ext),
            memory_slice(t_row, sizeof(mld_poly)),
            memory_slice(mat, sizeof(mld_polymat_lazy)))
    invariant(l >= 1 && l <= MLDSA_L)
    invariant(array_abs_bound(t_row->coeffs, 0, MLDSA_N, l * MLDSA_Q))
    decreases(MLDSA_L - l)
  )
  {
    mld_polymat_expand_entry(&mat->cur[0], seed_ext, (uint8_t)l, (uint8_t)i);
    mld_poly_pointwise_montgomery(&mat->cur[0], &v->vec[l]);
    mld_poly_add(t_row, &mat->cur[0]);
  }
  mld_poly_reduce(t_row);

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_yvec_lazy(
    mld_polyveck *w, mld_polymat_lazy *mat, const mld_yvec_lazy *y,
    mld_yvec_scratch_lazy *scratch)
{
#if defined(MLD_CONFIG_REDUCE_RAM_X4)
#define MLD_X4_SIGN_LOOP_INVARIANT(row) \
  invariant(l == 0 ||                   \
            array_abs_bound(w->vec[row].coeffs, 0, MLDSA_N, (int)l * MLDSA_Q))
#if MLDSA_K == 4
#define MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS
#elif MLDSA_K == 6
#define MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS \
  MLD_X4_SIGN_LOOP_INVARIANT(4) MLD_X4_SIGN_LOOP_INVARIANT(5)
#elif MLDSA_K == 8
#define MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS \
  MLD_X4_SIGN_LOOP_INVARIANT(4)           \
  MLD_X4_SIGN_LOOP_INVARIANT(5)           \
  MLD_X4_SIGN_LOOP_INVARIANT(6) MLD_X4_SIGN_LOOP_INVARIANT(7)
#else /* MLDSA_K == 8 */
#error Unsupported MLDSA_K for reduced-RAM x4 signing.
#endif /* MLDSA_K != 4 && MLDSA_K != 6 && MLDSA_K != 8 */
  unsigned int l;
  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  mld_memcpy(seed_ext, mat->rho, MLDSA_SEEDBYTES);

  /* Keep columns outermost: sample and NTT each y[l] only once. */
  for (l = 0; l < MLDSA_L; l++)
  __loop__(
    assigns(l, object_whole(seed_ext),
            memory_slice(w, sizeof(mld_polyveck)),
            memory_slice(mat, sizeof(mld_polymat_lazy)),
            memory_slice(scratch, sizeof(mld_yvec_scratch_lazy)))
    invariant(l <= MLDSA_L)
    MLD_X4_SIGN_LOOP_INVARIANT(0)
    MLD_X4_SIGN_LOOP_INVARIANT(1)
    MLD_X4_SIGN_LOOP_INVARIANT(2)
    MLD_X4_SIGN_LOOP_INVARIANT(3)
    MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS
    decreases(MLDSA_L - l)
  )
  {
    mld_yvec_get_poly_lazy(scratch, y, l);
    mld_poly_ntt(scratch);
    mld_polyveck_accumulate_column_x4(w, mat, scratch, seed_ext, l);
  }
  mld_zeroize(seed_ext, sizeof(seed_ext));
  mld_polyveck_reduce(w);
  mld_polyveck_invntt_tomont(w);
#undef MLD_X4_SIGN_LOOP_INVARIANT
#undef MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS
#else  /* MLD_CONFIG_REDUCE_RAM_X4 */
  unsigned int k, l;
  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];

  mld_memcpy(seed_ext, mat->rho, MLDSA_SEEDBYTES);

  /* Column-by-column: sample y[l], NTT, accumulate column l of A into w. */
  for (l = 0; l < MLDSA_L; l++)
  __loop__(
    assigns(k, l, object_whole(seed_ext),
            memory_slice(w, sizeof(mld_polyveck)),
            memory_slice(mat, sizeof(mld_polymat_lazy)),
            memory_slice(scratch, sizeof(mld_yvec_scratch_lazy)))
    invariant(l <= MLDSA_L)
    invariant(l == 0 ||
              forall(k0, 0, MLDSA_K,
                     array_abs_bound(w->vec[k0].coeffs, 0, MLDSA_N,
                                     (int)l * MLDSA_Q)))
    decreases(MLDSA_L - l)
  )
  {
    mld_yvec_get_poly_lazy(scratch, y, l);
    mld_poly_ntt(scratch);
    for (k = 0; k < MLDSA_K; k++)
    __loop__(
      assigns(k, object_whole(seed_ext),
              memory_slice(w, sizeof(mld_polyveck)),
              memory_slice(mat, sizeof(mld_polymat_lazy)))
      invariant(k <= MLDSA_K)
      invariant(l != 0 ||
                forall(k1, 0, k, MLDSA_K,
                       array_abs_bound(w->vec[k1].coeffs, 0, MLDSA_N, MLDSA_Q)))
      invariant(l == 0 ||
                forall(k2, 0, k, MLDSA_K,
                       array_abs_bound(w->vec[k2].coeffs, 0, MLDSA_N,
                                       ((int)l + 1) * MLDSA_Q)))
      invariant(l == 0 ||
                forall(k3, k, MLDSA_K,
                       array_abs_bound(w->vec[k3].coeffs, 0, MLDSA_N,
                                       (int)l * MLDSA_Q)))
      decreases(MLDSA_K - k)
    )
    {
      if (l == 0)
      {
        mld_polymat_expand_entry(&w->vec[k], seed_ext, 0, (uint8_t)k);
        mld_poly_pointwise_montgomery(&w->vec[k], scratch);
      }
      else
      {
        mld_polymat_expand_entry(&mat->cur[0], seed_ext, (uint8_t)l,
                                 (uint8_t)k);
        mld_poly_pointwise_montgomery(&mat->cur[0], scratch);
        mld_poly_add(&w->vec[k], &mat->cur[0]);
      }
    }
  }

  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(seed_ext, sizeof(seed_ext));
  mld_polyveck_reduce(w);
  mld_polyveck_invntt_tomont(w);
#endif /* !MLD_CONFIG_REDUCE_RAM_X4 */
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
MLD_INTERNAL_API
void mld_polyvec_matrix_pointwise_montgomery_rows(
    mld_poly t_rows[MLD_MATRIX_ROW_BATCH_SIZE], mld_polymat *mat,
    const mld_polyvecl *v, unsigned int i)
{
#if defined(MLD_CONFIG_REDUCE_RAM_X4)
  unsigned int l, j;
  if (i <= MLDSA_K - 4)
  {
    for (l = 0; l < MLDSA_L; l++)
    __loop__(
      assigns(l, memory_slice(t_rows, 4 * sizeof(mld_poly)),
              memory_slice(mat, sizeof(mld_polymat)))
      invariant(l <= MLDSA_L)
      invariant(l == 0 || array_abs_bound(t_rows[0].coeffs, 0, MLDSA_N,
                                          (int)l * MLDSA_Q))
      invariant(l == 0 || array_abs_bound(t_rows[1].coeffs, 0, MLDSA_N,
                                          (int)l * MLDSA_Q))
      invariant(l == 0 || array_abs_bound(t_rows[2].coeffs, 0, MLDSA_N,
                                          (int)l * MLDSA_Q))
      invariant(l == 0 || array_abs_bound(t_rows[3].coeffs, 0, MLDSA_N,
                                          (int)l * MLDSA_Q))
      decreases(MLDSA_L - l)
    )
    {
      mld_poly_accumulate_column4(t_rows, mat, &v->vec[l], i, l);
    }
    mld_poly_reduce(&t_rows[0]);
    mld_poly_reduce(&t_rows[1]);
    mld_poly_reduce(&t_rows[2]);
    mld_poly_reduce(&t_rows[3]);
  }
  else
  {
    for (j = 0; j < MLDSA_K - i; j++)
    __loop__(
      assigns(j, memory_slice(t_rows, 4 * sizeof(mld_poly)),
              memory_slice(mat, sizeof(mld_polymat)))
      invariant(j <= MLDSA_K - i)
      invariant(forall(k0, 0, j,
        array_abs_bound(t_rows[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
      decreases(MLDSA_K - i - j)
    )
    {
      mld_polyvec_matrix_pointwise_montgomery_row_lazy(&t_rows[j], mat, v,
                                                       i + j);
    }
  }
#else  /* MLD_CONFIG_REDUCE_RAM_X4 */
  mld_polyvec_matrix_pointwise_montgomery_row(&t_rows[0], mat, v, i);
#endif /* !MLD_CONFIG_REDUCE_RAM_X4 */
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_VERIFY_API */

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef mld_polymat_expand_entry
#undef mld_polymat_expand_column4
#undef mld_poly_accumulate_column_entry
#undef mld_poly_accumulate_column4
#undef mld_polyveck_accumulate_column_x4
#undef MLD_X4_COLUMN_INPUT
#undef MLD_X4_COLUMN_OUTPUT
#undef MLD_X4_COLUMN_EXTRA_INPUT
#undef MLD_X4_COLUMN_EXTRA_OUTPUT
#undef MLD_X4_SIGN_LOOP_INVARIANT
#undef MLD_X4_SIGN_EXTRA_LOOP_INVARIANTS
