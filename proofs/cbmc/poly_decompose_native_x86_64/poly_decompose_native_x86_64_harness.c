// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

#if MLDSA_GAMMA2 == ((MLDSA_Q - 1) / 88)
int mld_poly_decompose_88_native(int32_t *a1, int32_t *a0);
#else
int mld_poly_decompose_32_native(int32_t *a1, int32_t *a0);
#endif

void harness(void)
{
  int32_t *a1, *a0;
  int t;

#if MLDSA_GAMMA2 == ((MLDSA_Q - 1) / 88)
  t = mld_poly_decompose_88_native(a1, a0);
#else
  t = mld_poly_decompose_32_native(a1, a0);
#endif
}
