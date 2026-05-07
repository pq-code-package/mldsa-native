// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_polymat_macc_cell(mld_poly *out, mld_poly *scratch,
                           uint8_t seed_ext[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)],
                           uint8_t l, uint8_t k, const mld_poly *operand,
                           unsigned int acc_count);

void harness(void)
{
  mld_poly *out;
  mld_poly *scratch;
  uint8_t *seed_ext;
  uint8_t l, k;
  mld_poly *operand;
  unsigned int acc_count;
  mld_polymat_macc_cell(out, scratch, seed_ext, l, k, operand, acc_count);
}
