// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <fips202x4.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
  mld_shake256xNctx *state;
  const uint8_t *in;
  size_t stride, inlen;
  mld_shake256xN_absorb_once(state, in, stride, inlen);
}
