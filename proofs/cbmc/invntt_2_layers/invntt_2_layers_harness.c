// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "params.h"

void mld_invntt_2_layers(int32_t r[MLDSA_N], unsigned layer);

void harness(void)
{
  int32_t *r;
  unsigned layer;
  mld_invntt_2_layers(r, layer);
}
