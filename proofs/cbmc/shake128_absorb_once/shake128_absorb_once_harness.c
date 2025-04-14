// Copyright (c) 2025 The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0

#include "fips202/fips202.h"

void harness(void)
{
  keccak_state *s;
  const uint8_t *in;
  size_t inlen;

  shake128_absorb_once(s, in, inlen);
}
