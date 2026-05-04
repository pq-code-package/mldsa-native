// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"

void harness(void)
{
  uint8_t *sig;
  mld_poly *h;
  unsigned int i;
  int r;
  r = mld_sig_unpack_hints(h, sig, i);
}
