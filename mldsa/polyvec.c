/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <stdint.h>
#include <string.h>

#include "common.h"
#include "poly.h"
#include "polyvec.h"

#if !defined(MLD_USE_NATIVE_NTT_CUSTOM_ORDER)
/* This namespacing is not done at the top to avoid a naming conflict
 * with native backends, which are currently not yet namespaced. */
#define mld_poly_permute_bitrev_to_custom \
  MLD_NAMESPACE(mld_poly_permute_bitrev_to_custom)

static MLD_INLINE void mld_poly_permute_bitrev_to_custom(int32_t data[MLDSA_N])
{
  ((void)data);
}
#endif /* !MLD_USE_NATIVE_NTT_CUSTOM_ORDER */


void polyvec_matrix_expand(polyvecl mat[MLDSA_K],
                           const uint8_t rho[MLDSA_SEEDBYTES])
{
  unsigned int i, j;

  /*
   * We generate four separate seed arrays rather than a single one to work
   * around limitations in CBMC function contracts dealing with disjoint slices
   * of the same parent object.
   */

  MLD_ALIGN uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
  memcpy(seed_ext, rho, MLDSA_SEEDBYTES);
  i = 0;
  while (i < MLDSA_K * MLDSA_L)
  __loop__(
    assigns(i, object_whole(seed_ext), memory_slice(mat, MLDSA_K * sizeof(polyvecl)))
    invariant(i <= MLDSA_K * MLDSA_L)
    /* vectors 0 .. i / MLDSA_L are completely sampled */
    invariant(forall(k1, 0, i / MLDSA_L, forall(l1, 0, MLDSA_L,
      array_bound(mat[k1].vec[l1].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
    /* last vector is sampled up to i % MLDSA_L */
    invariant(forall(k2, i / MLDSA_L, i / MLDSA_L + 1, forall(l2, 0, i % MLDSA_L,
      array_bound(mat[k2].vec[l2].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
  )
  {
    poly tmp;
    uint8_t x = i / MLDSA_L;
    uint8_t y = i % MLDSA_L;

    seed_ext[MLDSA_SEEDBYTES + 0] = y;
    seed_ext[MLDSA_SEEDBYTES + 1] = x;


    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    poly_uniform(&tmp, seed_ext);
    mat[i / MLDSA_L].vec[i % MLDSA_L] = tmp;

    i++;
  }

  /*
   * The public matrix is generated in NTT domain. If the native backend
   * uses a custom order in NTT domain, permute A accordingly.
   */
  for (i = 0; i < MLDSA_K; i++)
  {
    for (j = 0; j < MLDSA_L; j++)
    {
      mld_poly_permute_bitrev_to_custom(mat[i].vec[j].coeffs);
    }
  }
}

void polyvec_matrix_pointwise_montgomery(polyveck *t,
                                         const polyvecl mat[MLDSA_K],
                                         const polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  {
    polyvecl_pointwise_acc_montgomery(&t->vec[i], &mat[i], v);
  }
}

/**************************************************************/
/************ Vectors of polynomials of length MLDSA_L **************/
/**************************************************************/
void polyvecl_uniform_gamma1(polyvecl *v, const uint8_t seed[MLDSA_CRHBYTES],
                             uint16_t nonce)
{
  nonce = MLDSA_L * nonce;
#if MLDSA_L == 4
  poly_uniform_gamma1_4x(&v->vec[0], &v->vec[1], &v->vec[2], &v->vec[3], seed,
                         nonce, nonce + 1, nonce + 2, nonce + 3);
#elif MLDSA_L == 5
  poly_uniform_gamma1_4x(&v->vec[0], &v->vec[1], &v->vec[2], &v->vec[3], seed,
                         nonce, nonce + 1, nonce + 2, nonce + 3);
  poly_uniform_gamma1(&v->vec[4], seed, nonce + 4);
#elif MLDSA_L == 7
  poly_uniform_gamma1_4x(&v->vec[0], &v->vec[1], &v->vec[2],
                         &v->vec[3 /* irrelevant */], seed, nonce, nonce + 1,
                         nonce + 2, 0xFF /* irrelevant */);
  poly_uniform_gamma1_4x(&v->vec[3], &v->vec[4], &v->vec[5], &v->vec[6], seed,
                         nonce + 3, nonce + 4, nonce + 5, nonce + 6);
#endif /* MLDSA_L == 7 */
}

void polyvecl_reduce(polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  __loop__(
    invariant(i <= MLDSA_L)
    invariant(forall(k0, i, MLDSA_L, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k2, 0, i,
      array_bound(v->vec[k2].coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX))))
  {
    poly t = v->vec[i];
    poly_reduce(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

/* Reference: We use destructive version (output=first input) to avoid
 *            reasoning about aliasing in the CBMC specification */
void polyvecl_add(polyvecl *u, const polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  __loop__(
    invariant(i <= MLDSA_L)
    invariant(forall(k0, i, MLDSA_L, 
              forall(k1, 0, MLDSA_N, u->vec[k0].coeffs[k1] == loop_entry(*u).vec[k0].coeffs[k1]))))
  {
    poly tmp = u->vec[i];
    poly_add(&tmp, &v->vec[i]);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    u->vec[i] = tmp;
  }
}

void polyvecl_ntt(polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  __loop__(
    invariant(i <= MLDSA_L)
    invariant(forall(k0, i, MLDSA_L, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k1, 0, i, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND))))
  {
    poly t = v->vec[i];
    poly_ntt(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

void polyvecl_invntt_tomont(polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  __loop__(
    invariant(i <= MLDSA_L)
    invariant(forall(k0, i, MLDSA_L, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k1, 0, i, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_INTT_BOUND))))
  {
    poly t = v->vec[i];
    poly_invntt_tomont(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

void polyvecl_pointwise_poly_montgomery(polyvecl *r, const poly *a,
                                        const polyvecl *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  {
    poly_pointwise_montgomery(&r->vec[i], a, &v->vec[i]);
  }
}

void polyvecl_pointwise_acc_montgomery(poly *w, const polyvecl *u,
                                       const polyvecl *v)
{
  unsigned int i, j;
  /* The second input is bounded by 9q. Hence, we can safely accumulate
   * in 64-bits without intermediate reductions as
   * MLDSA_L * MLD_NTT_BOUND * INT32_MAX < INT64_MAX
   * worst case is ML-DSA-87: 7 * 9 * q * 2**31 < 2**63
   * (likewise for negative values)
   */

  for (i = 0; i < MLDSA_N; i++)
  __loop__(
    assigns(i, j, object_whole(w))
    invariant(i <= MLDSA_N)
  )
  {
    int64_t t = 0;
    for (j = 0; j < MLDSA_L; j++)
    __loop__(
      assigns(j, t)
      invariant(j <= MLDSA_L)
      invariant(t <= -(int64_t)j*INT32_MIN*MLD_NTT_BOUND)
      invariant(t >= (int64_t)j*INT32_MIN*MLD_NTT_BOUND)
    )
    {
      t += (int64_t)u->vec[j].coeffs[i] * v->vec[j].coeffs[i];
    }
    w->coeffs[i] = montgomery_reduce(t);
  }
}


int polyvecl_chknorm(const polyvecl *v, int32_t bound)
{
  unsigned int i;

  for (i = 0; i < MLDSA_L; ++i)
  __loop__(
    invariant(i <= MLDSA_L)
  )
  {
    if (poly_chknorm(&v->vec[i], bound))
    {
      return 1;
    }
  }

  return 0;
}

/**************************************************************/
/************ Vectors of polynomials of length MLDSA_K **************/
/**************************************************************/

void polyveck_reduce(polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k2, 0, i,
      array_bound(v->vec[k2].coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX)))
  )
  {
    poly t = v->vec[i];
    poly_reduce(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

void polyveck_caddq(polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k1, 0, i, array_bound(v->vec[k1].coeffs, 0, MLDSA_N, 0, MLDSA_Q))))
  {
    poly t = v->vec[i];
    poly_caddq(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

/* Reference: We use destructive version (output=first input) to avoid
 *            reasoning about aliasing in the CBMC specification */
void polyveck_add(polyveck *u, const polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, 
             forall(k1, 0, MLDSA_N, u->vec[k0].coeffs[k1] == loop_entry(*u).vec[k0].coeffs[k1]))))
  {
    poly tmp = u->vec[i];
    poly_add(&tmp, &v->vec[i]);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    u->vec[i] = tmp;
  }
}

void polyveck_sub(polyveck *u, const polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, 
             forall(k1, 0, MLDSA_N, u->vec[k0].coeffs[k1] == loop_entry(*u).vec[k0].coeffs[k1]))))
  {
    poly tmp = u->vec[i];
    poly_sub(&tmp, &v->vec[i]);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    u->vec[i] = tmp;
  }
}

void polyveck_shiftl(polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  {
    poly_shiftl(&v->vec[i]);
  }
}

void polyveck_ntt(polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k1, 0, i, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND))))
  {
    poly t = v->vec[i];
    poly_ntt(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

void polyveck_invntt_tomont(polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k0, i, MLDSA_K, forall(k1, 0, MLDSA_N, v->vec[k0].coeffs[k1] == loop_entry(*v).vec[k0].coeffs[k1])))
    invariant(forall(k1, 0, i, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_INTT_BOUND))))
  {
    poly t = v->vec[i];
    poly_invntt_tomont(&t);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v->vec[i] = t;
  }
}

void polyveck_pointwise_poly_montgomery(polyveck *r, const poly *a,
                                        const polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  {
    poly_pointwise_montgomery(&r->vec[i], a, &v->vec[i]);
  }
}


int polyveck_chknorm(const polyveck *v, int32_t bound)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
  )
  {
    if (poly_chknorm(&v->vec[i], bound))
    {
      return 1;
    }
  }

  return 0;
}

void polyveck_power2round(polyveck *v1, polyveck *v0, const polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K)
    invariant(forall(k1, 0, i, array_bound(v0->vec[k1].coeffs, 0, MLDSA_N, -(MLD_2_POW_D/2)+1, (MLD_2_POW_D/2)+1)))
    invariant(forall(k2, 0, i, array_bound(v1->vec[k2].coeffs, 0, MLDSA_N, 0, (MLD_2_POW_D/2)+1))))
  {
    poly a1, a0;
    poly_power2round(&a1, &a0, &v->vec[i]);

    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v1->vec[i] = a1;
    v0->vec[i] = a0;
  }
}

void polyveck_decompose(polyveck *v1, polyveck *v0, const polyveck *v)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    assigns(i, object_whole(v0), object_whole(v1))
    invariant(i <= MLDSA_K)
    invariant(forall(k1, 0, i,
                     array_bound(v1->vec[k1].coeffs, 0, MLDSA_N, 0, (MLDSA_Q-1)/(2*MLDSA_GAMMA2)) &&
                     array_abs_bound(v0->vec[k1].coeffs, 0, MLDSA_N, MLDSA_GAMMA2+1)))
  )
  {
    poly c0, c1;

    poly_decompose(&c1, &c0, &v->vec[i]);

    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    v0->vec[i] = c0;
    v1->vec[i] = c1;
  }
}

unsigned int polyveck_make_hint(polyveck *h, const polyveck *v0,
                                const polyveck *v1)
{
  unsigned int i, s = 0;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    assigns(i, s, object_whole(h))
    invariant(i <= MLDSA_K)
    invariant(s <= i * MLDSA_N)
  )
  {
    s += poly_make_hint(&h->vec[i], &v0->vec[i], &v1->vec[i]);
  }

  return s;
}

void polyveck_use_hint(polyveck *w, const polyveck *u, const polyveck *h)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  __loop__(
    invariant(i <= MLDSA_K))
  {
    poly t;
    poly_use_hint(&t, &u->vec[i], &h->vec[i]);
    /* Full struct assignment from local variables to simplify proof */
    /* TODO: eliminate once CBMC resolves
     * https://github.com/diffblue/cbmc/issues/8617 */
    w->vec[i] = t;
  }
}

void polyveck_pack_w1(uint8_t r[MLDSA_K * MLDSA_POLYW1_PACKEDBYTES],
                      const polyveck *w1)
{
  unsigned int i;

  for (i = 0; i < MLDSA_K; ++i)
  {
    polyw1_pack(&r[i * MLDSA_POLYW1_PACKEDBYTES], &w1->vec[i]);
  }
}

void polyveck_pack_eta(uint8_t r[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES],
                       const polyveck *p)
{
  unsigned int i;
  for (i = 0; i < MLDSA_K; ++i)
  {
    polyeta_pack(r + i * MLDSA_POLYETA_PACKEDBYTES, &p->vec[i]);
  }
}

void polyvecl_pack_eta(uint8_t r[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES],
                       const polyvecl *p)
{
  unsigned int i;
  for (i = 0; i < MLDSA_L; ++i)
  {
    polyeta_pack(r + i * MLDSA_POLYETA_PACKEDBYTES, &p->vec[i]);
  }
}

void polyvecl_pack_z(uint8_t r[MLDSA_L * MLDSA_POLYZ_PACKEDBYTES],
                     const polyvecl *p)
{
  unsigned int i;
  for (i = 0; i < MLDSA_L; ++i)
  {
    polyz_pack(r + i * MLDSA_POLYZ_PACKEDBYTES, &p->vec[i]);
  }
}


void polyveck_pack_t0(uint8_t r[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES],
                      const polyveck *p)
{
  unsigned int i;
  for (i = 0; i < MLDSA_K; ++i)
  {
    polyt0_pack(r + i * MLDSA_POLYT0_PACKEDBYTES, &p->vec[i]);
  }
}

void polyvecl_unpack_eta(polyvecl *p,
                         const uint8_t r[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES])
{
  unsigned int i;
  for (i = 0; i < MLDSA_L; ++i)
  {
    polyeta_unpack(&p->vec[i], r + i * MLDSA_POLYETA_PACKEDBYTES);
  }
}

void polyvecl_unpack_z(polyvecl *z,
                       const uint8_t r[MLDSA_L * MLDSA_POLYZ_PACKEDBYTES])
{
  unsigned int i;
  for (i = 0; i < MLDSA_L; ++i)
  {
    polyz_unpack(&z->vec[i], r + i * MLDSA_POLYZ_PACKEDBYTES);
  }
}

void polyveck_unpack_eta(polyveck *p,
                         const uint8_t r[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES])
{
  unsigned int i;
  for (i = 0; i < MLDSA_K; ++i)
  {
    polyeta_unpack(&p->vec[i], r + i * MLDSA_POLYETA_PACKEDBYTES);
  }
}

void polyveck_unpack_t0(polyveck *p,
                        const uint8_t r[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES])
{
  unsigned int i;
  for (i = 0; i < MLDSA_K; ++i)
  {
    polyt0_unpack(&p->vec[i], r + i * MLDSA_POLYT0_PACKEDBYTES);
  }
}
