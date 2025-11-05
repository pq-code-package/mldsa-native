// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

#define mld_matrix_permute_bitrev_to_custom \
  MLD_NAMESPACE_KL(mld_matrix_permute_bitrev_to_custom)
void mld_matrix_permute_bitrev_to_custom(mld_polyvecl mat[MLDSA_K]);

void harness(void)
{
  mld_polyvecl *mat;
  mld_matrix_permute_bitrev_to_custom(mat);
}
