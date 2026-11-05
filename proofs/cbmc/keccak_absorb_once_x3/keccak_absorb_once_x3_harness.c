// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>
#include <stddef.h>
#include <stdint.h>

void mld_keccak_absorb_once_x3(uint64_t *s, unsigned r, const uint8_t *in0,
                               const uint8_t *in1, const uint8_t *in2,
                               size_t inlen, uint8_t p);

void harness(void)
{
  uint64_t *s;
  unsigned r;
  const uint8_t *in0, *in1, *in2;
  size_t inlen;
  uint8_t p;
  mld_keccak_absorb_once_x3(s, r, in0, in1, in2, inlen, p);
}
