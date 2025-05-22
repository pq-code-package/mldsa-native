// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void harness(void)
{
  polyveck *a;
  polyvecl *b, *c;
  polyvec_matrix_pointwise_montgomery(a, b, c);
}
