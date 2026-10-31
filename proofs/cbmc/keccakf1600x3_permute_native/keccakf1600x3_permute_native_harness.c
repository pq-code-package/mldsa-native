// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <keccakf1600.h>

void harness(void)
{
  uint64_t *s;
  mld_keccakf1600x3_permute(s);
}
