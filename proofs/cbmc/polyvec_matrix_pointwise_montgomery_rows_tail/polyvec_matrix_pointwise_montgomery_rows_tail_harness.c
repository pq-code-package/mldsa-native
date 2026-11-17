// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void harness(void)
{
  mld_poly *t_rows;
  mld_polymat *mat;
  mld_polyvecl *v;
  unsigned int i;
  /* Prove the partial batch after the last full four-row start. */
  __CPROVER_assume(i > MLDSA_K - 4);
  mld_polyvec_matrix_pointwise_montgomery_rows(t_rows, mat, v, i);
}
