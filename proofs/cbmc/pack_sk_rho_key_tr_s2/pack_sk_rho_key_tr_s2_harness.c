// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"

void harness(void)
{
  uint8_t *sk, *rho, *tr, *key;
  mld_polyveck *s2;
  mld_pack_sk_rho_key_tr_s2(sk, rho, tr, key, s2);
}
