// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_polymat_expand_entry(
    mld_poly *p, uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)], uint8_t l,
    uint8_t k);

void harness(void)
{
  mld_poly *p;
  uint8_t *seed_ext;
  uint8_t l, k;
  mld_polymat_expand_entry(p, seed_ext, l, k);
}
