// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"


void harness(void)
{
  uint8_t *a, *b, *c, *d;
  mld_sk_t0hat *t0;
  mld_sk_s1hat *s1;
  mld_sk_s2hat *s2;
  mld_unpack_sk(a, b, c, t0, s1, s2, d);
}
