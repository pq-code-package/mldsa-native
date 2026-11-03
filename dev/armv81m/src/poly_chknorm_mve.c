/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
/* MVE adaptation of mldsa/src/poly.c mld_poly_chknorm_c.
 * Inputs: 256 const int32_t in [-6283009,6283009), 0<=B<=2097408.
 * Returns 0 iff every abs(a[i])<B, otherwise 1. No early exit.
 */
#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_ARMV81M) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
#include <arm_mve.h>
#include "arith_native_armv81m.h"

MLD_INTERNAL_API
int mld_poly_chknorm_mve(const int32_t *a, int32_t B)
{
  int32x4_t peak = vdupq_n_s32(0);
  for (unsigned i = 0; i < 256; i += 4)
  {
    peak = vmaxq_s32(peak, vabsq_s32(vld1q_s32(a + i)));
  }
  int32_t largest = vmaxvq_s32(0, peak);
  return (int)((uint32_t)(B - 1 - largest) >> 31);
}

#else  /* MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
MLD_EMPTY_CU(poly_chknorm_mve)
#endif /* !(MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED) */
