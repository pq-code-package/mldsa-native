/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_META_H
#define MLD_NATIVE_PPC64LE_META_H

/* Set of primitives this backend replaces (grown incrementally per kernel). */
#define MLD_USE_NATIVE_POLY_CADDQ
#define MLD_USE_NATIVE_NTT
#define MLD_USE_NATIVE_INTT
#define MLD_USE_NATIVE_POINTWISE_MONTGOMERY
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7

/* Backend identifier, for guarding source/assembly files in the build. */
#define MLD_ARITH_BACKEND_PPC64LE

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_ppc64le.h"

static MLD_INLINE int mld_poly_caddq_native(int32_t a[MLDSA_N])
{
  mld_poly_caddq_ppc64le_asm(a);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
    defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_poly_pointwise_montgomery_native(
    int32_t a[MLDSA_N], const int32_t b[MLDSA_N])
{
  mld_poly_pointwise_montgomery_ppc64le_asm(a, b);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 4
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l4_native(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N])
{
  mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le_asm(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 5
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l5_native(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N])
{
  mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le_asm(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 7
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l7_native(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N])
{
  mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le_asm(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif

static MLD_INLINE int mld_ntt_native(int32_t a[MLDSA_N])
{
  mld_ntt_ppc64le_asm(a, mld_ppc64le_zetas);
  return MLD_NATIVE_FUNC_SUCCESS;
}

static MLD_INLINE int mld_intt_native(int32_t a[MLDSA_N])
{
  mld_intt_ppc64le_asm(a, mld_ppc64le_zetas);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#endif /* !__ASSEMBLER__ */

#endif /* MLD_NATIVE_PPC64LE_META_H */
