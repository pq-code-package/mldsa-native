// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"

void harness(void)
{
#if MLD_CONFIG_PARAMETER_SET != 44
  mld_poly *r;
  uint8_t *a;
  mld_polyw1_unpack_32(r, a);
#endif
}
