// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"

void harness(void)
{
  mld_poly *a, *b;
  mld_poly_pointwise_montgomery(a, b);
}
