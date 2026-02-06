// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

void mld_poly_permute_bitrev_to_custom(int32_t p[MLDSA_N]);

void harness(void)
{
  int32_t *r;
  mld_poly_permute_bitrev_to_custom(r);
}
