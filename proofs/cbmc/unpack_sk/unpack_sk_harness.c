// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"


void harness(void)
{
  uint8_t *a, *b, *c, *d;
  mld_t0vec *t0;
  mld_s1vec *s1;
  mld_s2vec *s2;
  mld_unpack_sk(a, b, c, t0, s1, s2, d);
}
