// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "params.h"

void mld_ntt_2_layers_block(int32_t r[MLDSA_N], unsigned start,
                            unsigned len_inner, int32_t z0, int32_t z0_twst,
                            int32_t z1, int32_t z1_twst, int32_t z2,
                            int32_t z2_twst, const int32_t bound);

void harness(void)
{
  int32_t *r;
  unsigned start, len_inner;
  int32_t z0, z0_twst, z1, z1_twst, z2, z2_twst, bound;
  mld_ntt_2_layers_block(r, start, len_inner, z0, z0_twst, z1, z1_twst, z2,
                         z2_twst, bound);
}
