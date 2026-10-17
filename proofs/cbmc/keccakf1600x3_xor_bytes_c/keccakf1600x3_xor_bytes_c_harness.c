// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>

void mld_keccakf1600x3_xor_bytes_c(uint64_t *state, const unsigned char *data0,
                                   const unsigned char *data1,
                                   const unsigned char *data2, unsigned offset,
                                   unsigned length);

void harness(void)
{
  uint64_t *state;
  const unsigned char *data0, *data1, *data2;
  unsigned offset;
  unsigned length;
  mld_keccakf1600x3_xor_bytes_c(state, data0, data1, data2, offset, length);
}
