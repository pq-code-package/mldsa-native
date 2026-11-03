/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_META_H
#define MLD_NATIVE_ARMV81M_META_H

/* Opt-in Armv8.1-M MVE arithmetic; other primitives retain C fallbacks. */
#if !defined(MLD_SYS_ARMV81M_MVE)
#error This arithmetic backend requires Armv8.1-M MVE
#endif

#define MLD_ARITH_BACKEND_ARMV81M
#define MLD_USE_NATIVE_POINTWISE_MONTGOMERY
#define MLD_USE_NATIVE_POLY_CHKNORM
#define MLD_USE_NATIVE_POLY_USE_HINT_32

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_armv81m.h"

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_poly_pointwise_montgomery_native(
    int32_t a[MLDSA_N], const int32_t b[MLDSA_N])
{
  mld_poly_pointwise_montgomery_mve_asm(a, b);
  return MLD_NATIVE_FUNC_SUCCESS;
}

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_poly_chknorm_native(const int32_t *a, int32_t B)
{
  return mld_poly_chknorm_mve(a, B);
}

#if !defined(MLD_CONFIG_NO_VERIFY_API) &&          \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_poly_use_hint_32_native(int32_t *a, const int32_t *h)
{
  mld_poly_use_hint_32_mve(a, h);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !MLD_CONFIG_NO_VERIFY_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87) */
#endif /* !__ASSEMBLER__ */
#endif /* !MLD_NATIVE_ARMV81M_META_H */
