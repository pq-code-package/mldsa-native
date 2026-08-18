// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

#if MLDSA_GAMMA2 == ((MLDSA_Q - 1) / 88)
int mld_poly_use_hint_88_native(int32_t *a, const int32_t *h);
#else
int mld_poly_use_hint_32_native(int32_t *a, const int32_t *h);
#endif

void harness(void)
{
  int32_t *a, *h;
  int t;

#if MLDSA_GAMMA2 == ((MLDSA_Q - 1) / 88)
  t = mld_poly_use_hint_88_native(a, h);
#else
  t = mld_poly_use_hint_32_native(a, h);
#endif
}
