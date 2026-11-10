// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>
#include <stddef.h>
#include <stdint.h>

void mld_keccak_squeezeblocks_x3(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                 size_t nblocks, uint64_t *s, unsigned r);

void harness(void)
{
  uint8_t *out0, *out1, *out2;
  size_t nblocks;
  uint64_t *s;
  unsigned r;
  mld_keccak_squeezeblocks_x3(out0, out1, out2, nblocks, s, r);
}
