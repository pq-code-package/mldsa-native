// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <keccakf1600.h>
#include <stddef.h>
#include <stdint.h>

void mld_keccak_squeezeblocks_xN(uint8_t *out, size_t stride, size_t nblocks,
                                 uint64_t *s, unsigned r);

void harness(void)
{
  uint8_t *out;
  size_t stride, nblocks;
  uint64_t *s;
  unsigned r;
  mld_keccak_squeezeblocks_xN(out, stride, nblocks, s, r);
}
