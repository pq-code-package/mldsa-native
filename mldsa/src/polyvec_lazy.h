/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Eager and lazy variants of polynomial vector types.
 *
 * In eager mode, full vectors are precomputed and stored in memory.
 * In lazy mode, data is stored in packed form and expanded on demand,
 * trading computation for reduced memory usage.
 *
 * MLD_CONFIG_REDUCE_RAM selects which variant is used.
 */

#ifndef MLD_POLYVEC_LAZY_H
#define MLD_POLYVEC_LAZY_H

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_SIGN_API)

#include "poly.h"
#include "polyvec.h"

/* Parameter set namespacing */
#define mld_sk_s1hat_eager MLD_ADD_PARAM_SET(mld_sk_s1hat_eager)
#define mld_sk_s1hat_lazy MLD_ADD_PARAM_SET(mld_sk_s1hat_lazy)
#define mld_sk_s1hat MLD_ADD_PARAM_SET(mld_sk_s1hat)
#define mld_unpack_sk_s1hat_eager MLD_ADD_PARAM_SET(mld_unpack_sk_s1hat_eager)
#define mld_unpack_sk_s1hat_lazy MLD_ADD_PARAM_SET(mld_unpack_sk_s1hat_lazy)
#define mld_sk_s1hat_get_poly_eager \
  MLD_ADD_PARAM_SET(mld_sk_s1hat_get_poly_eager)
#define mld_sk_s1hat_get_poly_lazy MLD_ADD_PARAM_SET(mld_sk_s1hat_get_poly_lazy)
#define mld_sk_s2hat_eager MLD_ADD_PARAM_SET(mld_sk_s2hat_eager)
#define mld_sk_s2hat_lazy MLD_ADD_PARAM_SET(mld_sk_s2hat_lazy)
#define mld_sk_s2hat MLD_ADD_PARAM_SET(mld_sk_s2hat)
#define mld_unpack_sk_s2hat_eager MLD_ADD_PARAM_SET(mld_unpack_sk_s2hat_eager)
#define mld_unpack_sk_s2hat_lazy MLD_ADD_PARAM_SET(mld_unpack_sk_s2hat_lazy)
#define mld_sk_s2hat_get_poly_eager \
  MLD_ADD_PARAM_SET(mld_sk_s2hat_get_poly_eager)
#define mld_sk_s2hat_get_poly_lazy MLD_ADD_PARAM_SET(mld_sk_s2hat_get_poly_lazy)
#define mld_sk_t0hat_eager MLD_ADD_PARAM_SET(mld_sk_t0hat_eager)
#define mld_sk_t0hat_lazy MLD_ADD_PARAM_SET(mld_sk_t0hat_lazy)
#define mld_sk_t0hat MLD_ADD_PARAM_SET(mld_sk_t0hat)
#define mld_unpack_sk_t0hat_eager MLD_ADD_PARAM_SET(mld_unpack_sk_t0hat_eager)
#define mld_unpack_sk_t0hat_lazy MLD_ADD_PARAM_SET(mld_unpack_sk_t0hat_lazy)
#define mld_sk_t0hat_get_poly_eager \
  MLD_ADD_PARAM_SET(mld_sk_t0hat_get_poly_eager)
#define mld_sk_t0hat_get_poly_lazy MLD_ADD_PARAM_SET(mld_sk_t0hat_get_poly_lazy)
/* End of parameter set namespacing */

/* Eager: precompute and store full NTT'd vector */
typedef struct
{
  mld_polyvecl vec;
} mld_sk_s1hat_eager;

typedef struct
{
  mld_polyveck vec;
} mld_sk_s2hat_eager;

typedef struct
{
  mld_polyveck vec;
} mld_sk_t0hat_eager;

/* Lazy: borrow packed data, unpack and NTT on demand */
typedef struct
{
  const uint8_t *packed;
} mld_sk_s1hat_lazy;

typedef struct
{
  const uint8_t *packed;
} mld_sk_s2hat_lazy;

typedef struct
{
  const uint8_t *packed;
} mld_sk_t0hat_lazy;

/* s1vec */

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_s1hat_eager(
    mld_sk_s1hat_eager *s1,
    const uint8_t packed_s1[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES])
{
  mld_polyvecl_unpack_eta(&s1->vec, packed_s1);
  mld_polyvecl_ntt(&s1->vec);
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_s1hat_get_poly_eager(mld_poly *buf,
                                                   const mld_sk_s1hat_eager *s1,
                                                   unsigned int i)
{
  *buf = s1->vec.vec[i];
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */
#if defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_s1hat_lazy(
    mld_sk_s1hat_lazy *s1,
    const uint8_t packed_s1[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES])
{
  s1->packed = packed_s1;
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_s1hat_get_poly_lazy(mld_poly *buf,
                                                  const mld_sk_s1hat_lazy *s1,
                                                  unsigned int i)
{
  mld_polyeta_unpack(buf, s1->packed + i * MLDSA_POLYETA_PACKEDBYTES);
  mld_poly_ntt(buf);
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/* s2vec */

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_s2hat_eager(
    mld_sk_s2hat_eager *s2,
    const uint8_t packed_s2[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES])
{
  mld_polyveck_unpack_eta(&s2->vec, packed_s2);
  mld_polyveck_ntt(&s2->vec);
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_s2hat_get_poly_eager(mld_poly *buf,
                                                   const mld_sk_s2hat_eager *s2,
                                                   unsigned int i)
{
  *buf = s2->vec.vec[i];
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */
#if defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_s2hat_lazy(
    mld_sk_s2hat_lazy *s2,
    const uint8_t packed_s2[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES])
{
  s2->packed = packed_s2;
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_s2hat_get_poly_lazy(mld_poly *buf,
                                                  const mld_sk_s2hat_lazy *s2,
                                                  unsigned int i)
{
  mld_polyeta_unpack(buf, s2->packed + i * MLDSA_POLYETA_PACKEDBYTES);
  mld_poly_ntt(buf);
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/* t0vec */

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_t0hat_eager(
    mld_sk_t0hat_eager *t0,
    const uint8_t packed_t0[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES])
{
  mld_polyveck_unpack_t0(&t0->vec, packed_t0);
  mld_polyveck_ntt(&t0->vec);
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_t0hat_get_poly_eager(mld_poly *buf,
                                                   const mld_sk_t0hat_eager *t0,
                                                   unsigned int i)
{
  *buf = t0->vec.vec[i];
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */
#if defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
static MLD_INLINE void mld_unpack_sk_t0hat_lazy(
    mld_sk_t0hat_lazy *t0,
    const uint8_t packed_t0[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES])
{
  t0->packed = packed_t0;
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_INLINE void mld_sk_t0hat_get_poly_lazy(mld_poly *buf,
                                                  const mld_sk_t0hat_lazy *t0,
                                                  unsigned int i)
{
  mld_polyt0_unpack(buf, t0->packed + i * MLDSA_POLYT0_PACKEDBYTES);
  mld_poly_ntt(buf);
}
#endif /* !MLD_CONFIG_NO_SIGN_API */
#endif /* MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/* Dispatch: typedef and define based on MLD_CONFIG_REDUCE_RAM */
#if defined(MLD_CONFIG_REDUCE_RAM)
typedef mld_sk_s1hat_lazy mld_sk_s1hat;
typedef mld_sk_s2hat_lazy mld_sk_s2hat;
typedef mld_sk_t0hat_lazy mld_sk_t0hat;
#define mld_unpack_sk_s1hat mld_unpack_sk_s1hat_lazy
#define mld_unpack_sk_s2hat mld_unpack_sk_s2hat_lazy
#define mld_unpack_sk_t0hat mld_unpack_sk_t0hat_lazy
#if !defined(MLD_CONFIG_NO_SIGN_API)
#define mld_sk_s1hat_get_poly mld_sk_s1hat_get_poly_lazy
#define mld_sk_s2hat_get_poly mld_sk_s2hat_get_poly_lazy
#define mld_sk_t0hat_get_poly mld_sk_t0hat_get_poly_lazy
#endif
#else /* MLD_CONFIG_REDUCE_RAM */
typedef mld_sk_s1hat_eager mld_sk_s1hat;
typedef mld_sk_s2hat_eager mld_sk_s2hat;
typedef mld_sk_t0hat_eager mld_sk_t0hat;
#define mld_unpack_sk_s1hat mld_unpack_sk_s1hat_eager
#define mld_unpack_sk_s2hat mld_unpack_sk_s2hat_eager
#define mld_unpack_sk_t0hat mld_unpack_sk_t0hat_eager
#if !defined(MLD_CONFIG_NO_SIGN_API)
#define mld_sk_s2hat_get_poly mld_sk_s2hat_get_poly_eager
#define mld_sk_s1hat_get_poly mld_sk_s1hat_get_poly_eager
#define mld_sk_t0hat_get_poly mld_sk_t0hat_get_poly_eager
#endif
#endif /* !MLD_CONFIG_REDUCE_RAM */

#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_SIGN_API */
#endif /* !MLD_POLYVEC_LAZY_H */
