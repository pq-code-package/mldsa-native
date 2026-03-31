// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"


int mld_poly_pointwise_montgomery_native(int32_t c[MLDSA_N],
                                         const int32_t a[MLDSA_N],
                                         const int32_t b[MLDSA_N]);

void harness(void)
{
  int32_t *c, *a, *b;
  int t;
  t = mld_poly_pointwise_montgomery_native(c, a, b);
}
