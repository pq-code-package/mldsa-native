// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <fips202x3.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
  uint8_t *out0, *out1, *out2;
  size_t nblocks;
  mld_shake256x3ctx *state;
  mld_shake256x3_squeezeblocks(out0, out1, out2, nblocks, state);
}
