// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>

int mld_keccak_f1600_x3_native(uint64_t *state);

void harness(void)
{
  uint64_t *s;
  int t = mld_keccak_f1600_x3_native(s);
}
