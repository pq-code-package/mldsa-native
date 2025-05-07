// Copyright (c) 2025 The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0

#include "fips202/fips202.h"
#include "poly.h"

void harness(void)
{
  poly *a;
  const uint8_t *seed;
  uint16_t nonce;

  poly_uniform_eta(a, seed, nonce);
}
