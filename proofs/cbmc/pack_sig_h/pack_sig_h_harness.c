// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"

void harness(void)
{
  uint8_t *sig;
  mld_polyveck *w0;
  uint8_t *w1_packed;
  mld_poly *scratch;
  int r;
  r = mld_pack_sig_h(sig, w0, w1_packed, scratch);
}
