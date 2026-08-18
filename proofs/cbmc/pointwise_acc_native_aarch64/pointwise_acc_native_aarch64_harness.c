// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

#if MLDSA_L == 4
int mld_polyvecl_pointwise_acc_montgomery_l4_native(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N]);
#elif MLDSA_L == 5
int mld_polyvecl_pointwise_acc_montgomery_l5_native(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N]);
#elif MLDSA_L == 7
int mld_polyvecl_pointwise_acc_montgomery_l7_native(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N]);
#endif

void harness(void)
{
  int32_t *w;
  int t;

#if MLDSA_L == 4
  int32_t (*u)[MLDSA_N], (*v)[MLDSA_N];
  t = mld_polyvecl_pointwise_acc_montgomery_l4_native(w, u, v);
#elif MLDSA_L == 5
  int32_t (*u)[MLDSA_N], (*v)[MLDSA_N];
  t = mld_polyvecl_pointwise_acc_montgomery_l5_native(w, u, v);
#elif MLDSA_L == 7
  int32_t (*u)[MLDSA_N], (*v)[MLDSA_N];
  t = mld_polyvecl_pointwise_acc_montgomery_l7_native(w, u, v);
#endif
}
