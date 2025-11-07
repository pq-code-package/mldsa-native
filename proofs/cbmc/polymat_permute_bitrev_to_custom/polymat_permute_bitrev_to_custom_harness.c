// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec.h"

void mld_polymat_permute_bitrev_to_custom(mld_polyvecl mat[MLDSA_K]);

void harness(void)
{
  mld_polyvecl *mat;
  mld_polymat_permute_bitrev_to_custom(mat);
}
