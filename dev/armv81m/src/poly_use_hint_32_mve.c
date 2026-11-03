/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
/* MVE adaptation of mldsa/src/rounding.h mld_decompose/mld_use_hint.
 * Inputs: disjoint arrays of 256 int32_t; 0<=a<8380417, h in {0,1}.
 * Exact gamma2=(q-1)/32 semantics; gamma2=(q-1)/88 is not supported.
 */
#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_ARMV81M) &&          \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&          \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
#include <arm_mve.h>
#include "arith_native_armv81m.h"

MLD_INTERNAL_API
void mld_poly_use_hint_32_mve(int32_t *a, const int32_t *h)
{
  for (unsigned i = 0; i < 256; i += 4)
  {
    int32x4_t x = vld1q_s32(a + i);
    int32x4_t hi = vshrq_n_s32(vaddq_n_s32(x, 127), 7);
    hi = vshrq_n_s32(vaddq_n_s32(vmulq_n_s32(hi, 1025), 1 << 21), 22);
    hi = vandq_s32(hi, vdupq_n_s32(15));
    int32x4_t lo = vsubq_s32(x, vmulq_n_s32(hi, 523776));
    int32x4_t wrap = vshrq_n_s32(vsubq_s32(vdupq_n_s32(4190208), lo), 31);
    lo = vaddq_s32(lo, vmulq_n_s32(wrap, 8380417));
    int32x4_t sign = vshrq_n_s32(vsubq_n_s32(lo, 1), 31);
    int32x4_t delta = vaddq_n_s32(vmulq_n_s32(sign, 2), 1);
    int32x4_t out = vaddq_s32(hi, vmulq_s32(vld1q_s32(h + i), delta));
    vst1q_s32(a + i, vandq_s32(out, vdupq_n_s32(15)));
  }
}

#else  /* MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED &&   \
          !MLD_CONFIG_NO_VERIFY_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87) */
MLD_EMPTY_CU(poly_use_hint_32_mve)
#endif /* !(MLD_ARITH_BACKEND_ARMV81M && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          !MLD_CONFIG_NO_VERIFY_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)) \
        */
