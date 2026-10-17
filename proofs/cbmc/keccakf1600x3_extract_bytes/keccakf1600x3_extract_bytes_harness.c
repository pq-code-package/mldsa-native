// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>

void harness(void)
{
  uint64_t *state;
  unsigned char *data0, *data1, *data2;
  unsigned offset;
  unsigned length;
  mld_keccakf1600x3_extract_bytes(state, data0, data1, data2, offset, length);
}
