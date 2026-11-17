// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void harness(void)
{
  mld_poly *t_rows;
  mld_polymat *mat;
  mld_polyvecl *v;
  unsigned int i;
#if defined(MLD_CONFIG_REDUCE_RAM_X4)
  /* Prove the four-row branch; the tail has a separate harness. */
  __CPROVER_assume(i <= MLDSA_K - 4);
#endif
  mld_polyvec_matrix_pointwise_montgomery_rows(t_rows, mat, v, i);
}
