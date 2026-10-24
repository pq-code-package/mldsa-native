// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>

void harness(void)
{
  uint64_t *state;
  const unsigned char *data0, *data1, *data2;
  unsigned offset;
  unsigned length;
  mld_keccakf1600x3_xor_bytes(state, data0, data1, data2, offset, length);
}
