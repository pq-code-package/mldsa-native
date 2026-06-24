// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "params.h"

void mld_invntt_2_layers_block(int32_t r[MLDSA_N], unsigned start,
                               unsigned len_inner, int32_t z_outer,
                               int32_t z_outer_twst, int32_t z_in_l,
                               int32_t z_in_l_twst, int32_t z_in_r,
                               int32_t z_in_r_twst, const int32_t bound);

void harness(void)
{
  int32_t *r;
  unsigned start, len_inner;
  int32_t z_outer, z_outer_twst, z_in_l, z_in_l_twst, z_in_r, z_in_r_twst,
      bound;
  mld_invntt_2_layers_block(r, start, len_inner, z_outer, z_outer_twst, z_in_l,
                            z_in_l_twst, z_in_r, z_in_r_twst, bound);
}
