// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"

void harness(void)
{
#if MLD_CONFIG_PARAMETER_SET == 44
  mld_poly *a0, *a1;
  mld_poly_decompose_88(a1, a0);
#endif
}
