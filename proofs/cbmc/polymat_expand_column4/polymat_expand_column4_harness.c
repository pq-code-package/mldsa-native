// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_polymat_expand_column4(mld_poly p[4],
                                const uint8_t rho[MLDSA_SEEDBYTES],
                                unsigned int k, unsigned int l);

void harness(void)
{
  mld_poly *p;
  const uint8_t *rho;
  unsigned int k, l;
  mld_polymat_expand_column4(p, rho, k, l);
}
