// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  mld_poly *r0;
  mld_poly *r1;
  mld_poly *r2;
  uint8_t (*seed)[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];

  mld_poly_uniform_3x(r0, r1, r2, seed);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
