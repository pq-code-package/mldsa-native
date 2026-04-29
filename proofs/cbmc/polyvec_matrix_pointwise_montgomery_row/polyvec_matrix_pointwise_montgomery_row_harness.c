// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void harness(void)
{
  mld_poly *t_row;
  mld_polymat *mat;
  mld_polyvecl *v;
  unsigned int i;
  mld_polyvec_matrix_pointwise_montgomery_row(t_row, mat, v, i);
}
