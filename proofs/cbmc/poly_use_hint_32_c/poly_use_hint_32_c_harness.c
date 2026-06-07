// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"

// Prototype for the function under test
void mld_poly_use_hint_32_c(mld_poly *a, const mld_poly *h);

void harness(void)
{
#if MLD_CONFIG_PARAMETER_SET != 44
  mld_poly *a, *h;
  mld_poly_use_hint_32_c(a, h);
#endif
}
