// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void harness(void)
{
  uint8_t *r;
  int32_t b;
  mld_poly *scratch;
  uint32_t res;

  res = mld_polyveck_unpack_eta_chknorm(r, b, scratch);
}
