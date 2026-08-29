// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void harness(void)
{
  uint8_t *r;
  mld_polyveck *v0;
  mld_poly *scratch;
  mld_polyveck_decompose_pack_w1(r, v0, scratch);
}
