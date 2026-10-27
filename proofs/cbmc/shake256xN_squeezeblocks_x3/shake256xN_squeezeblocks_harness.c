// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <fips202x4.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
  uint8_t *out;
  size_t stride, nblocks;
  mld_shake256xNctx *state;
  mld_shake256xN_squeezeblocks(out, stride, nblocks, state);
}
