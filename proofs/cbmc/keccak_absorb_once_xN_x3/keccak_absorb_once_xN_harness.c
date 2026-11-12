// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <keccakf1600.h>
#include <stddef.h>
#include <stdint.h>

void mld_keccak_absorb_once_xN(uint64_t *s, unsigned r, const uint8_t *in,
                               size_t stride, size_t inlen, uint8_t p);

void harness(void)
{
  uint64_t *s;
  unsigned r;
  const uint8_t *in;
  size_t stride, inlen;
  uint8_t p;
  mld_keccak_absorb_once_xN(s, r, in, stride, inlen, p);
}
