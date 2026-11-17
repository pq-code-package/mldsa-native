// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_polyveck_accumulate_column_x4(
    mld_polyveck *w, mld_polymat_lazy *mat, const mld_poly *v,
    uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)], unsigned int l);

void harness(void)
{
  mld_polyveck *w;
  mld_polymat_lazy *mat;
  const mld_poly *v;
  uint8_t *seed_ext;
  unsigned int l;
  mld_polyveck_accumulate_column_x4(w, mat, v, seed_ext, l);
}
