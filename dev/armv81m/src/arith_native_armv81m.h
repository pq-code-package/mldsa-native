/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H
#define MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H

#include "../../../common.h"

#define mld_poly_pointwise_montgomery_mve_asm \
  MLD_NAMESPACE(poly_pointwise_montgomery_mve_asm)
/* Assembly exports an external symbol even in a static C monobuild. */
void mld_poly_pointwise_montgomery_mve_asm(int32_t a[MLDSA_N],
                                           const int32_t b[MLDSA_N]);

#define mld_poly_chknorm_mve MLD_NAMESPACE(poly_chknorm_mve)
MLD_INTERNAL_API
int mld_poly_chknorm_mve(const int32_t *a, int32_t B);

#if !defined(MLD_CONFIG_NO_VERIFY_API) &&          \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
#define mld_poly_use_hint_32_mve MLD_NAMESPACE(poly_use_hint_32_mve)
MLD_INTERNAL_API
void mld_poly_use_hint_32_mve(int32_t *a, const int32_t *h);
#endif /* !MLD_CONFIG_NO_VERIFY_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87) */

#endif /* !MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H */
