// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  mld_polyvecl *v;
  const uint8_t *seed;
  uint16_t kappa;

  mld_polyvecl_uniform_gamma1(v, seed, kappa);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
