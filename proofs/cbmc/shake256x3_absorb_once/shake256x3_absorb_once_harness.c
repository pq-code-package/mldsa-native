// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <fips202x3.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
  mld_shake256x3ctx *state;
  const uint8_t *in0, *in1, *in2;
  size_t inlen;
  mld_shake256x3_absorb_once(state, in0, in1, in2, inlen);
}
