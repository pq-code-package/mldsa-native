// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly.h"
#include "sign.h"

int mld_reconstruct_w1_row(mld_poly *w1row, mld_poly *tmp, uint8_t *packed,
                           const mld_poly *cp, const uint8_t *pk,
                           const uint8_t *sig, unsigned int i);

void harness(void)
{
  mld_poly *w1row;
  mld_poly *tmp;
  uint8_t *packed;
  const mld_poly *cp;
  const uint8_t *pk;
  const uint8_t *sig;
  unsigned int i;

  mld_reconstruct_w1_row(w1row, tmp, packed, cp, pk, sig, i);
}
