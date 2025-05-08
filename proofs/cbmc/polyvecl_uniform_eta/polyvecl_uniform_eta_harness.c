// Copyright (c) 2025 The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0

#include "fips202/fips202.h"
#include "poly.h"
#include "polyvec.h"

void harness(void)
{
  polyvecl *v;
  const uint8_t *seed;
  uint16_t nonce;

  polyvecl_uniform_eta(v, seed, nonce);
}
