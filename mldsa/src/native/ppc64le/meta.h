/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_META_H
#define MLD_NATIVE_PPC64LE_META_H

/* ============================================================================
 * These macros signal to the build system which operations have native support.
 */

#define MLD_USE_NATIVE_NTT
#define MLD_USE_NATIVE_INTT
#define MLD_USE_NATIVE_POINTWISE_MONTGOMERY
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5
#define MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7

/* Backend identifier for conditional compilation in source/assembly files */
#define MLD_ARITH_BACKEND_PPC64LE

/* ============================================================================
 * Native Function Wrappers
 * ============================================================================
 * These inline functions provide a uniform interface for calling PowerPC64LE
 * optimized implementations. Runtime capability detection is used to select
 * between POWER10 and POWER8/9 implementations where applicable.
 */

#if !defined(__ASSEMBLER__)

#include "../../common.h"
#include "../../params.h"
#include "../../sys.h"
#include "../api.h"
#include "src/arith_native_ppc64le.h"

static MLD_INLINE int mld_ntt_native(int32_t data[MLDSA_N])
{
  if (mld_sys_check_capability(MLD_SYS_CAP_POWER10))
  {
    mld_ntt_p10_ppc64le(data);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  else if (mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    mld_ntt_p8p9_ppc64le(data);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  return MLD_NATIVE_FUNC_FALLBACK;
}

static MLD_INLINE int mld_intt_native(int32_t data[MLDSA_N])
{
  if (mld_sys_check_capability(MLD_SYS_CAP_POWER10))
  {
    mld_intt_p10_ppc64le(data);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  else if (mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    mld_intt_p8p9_ppc64le(data);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  return MLD_NATIVE_FUNC_FALLBACK;
}

static MLD_INLINE int mld_poly_pointwise_montgomery_native(
    int32_t a[MLDSA_N], const int32_t b[MLDSA_N])
{
  if (mld_sys_check_capability(MLD_SYS_CAP_POWER10))
  {
    mld_poly_pointwise_montgomery_p10_ppc64le(a, b);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  else if (mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    mld_poly_pointwise_montgomery_p8p9_ppc64le(a, b);
    return MLD_NATIVE_FUNC_SUCCESS;
  }

  return MLD_NATIVE_FUNC_FALLBACK;
}

static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l4_native(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N])
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}

static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l5_native(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N])
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}

static MLD_INLINE int mld_polyvecl_pointwise_acc_montgomery_l7_native(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N])
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le(w, u, v);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#endif /* !__ASSEMBLER__ */
#endif /* !MLD_NATIVE_PPC64LE_META_H */
