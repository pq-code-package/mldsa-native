// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  mld_polyveck *a;
  mld_polyveck_ntt(a);
#endif
}
