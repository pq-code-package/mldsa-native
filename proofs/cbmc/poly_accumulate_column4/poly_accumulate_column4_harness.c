// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_poly_accumulate_column4(mld_poly acc[4], mld_polymat_lazy *mat,
                                 const mld_poly *v, unsigned int k,
                                 unsigned int l);

void harness(void)
{
  mld_poly *acc;
  mld_polymat_lazy *mat;
  const mld_poly *v;
  unsigned int k, l;
  mld_poly_accumulate_column4(acc, mat, v, k, l);
}
