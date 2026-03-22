// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

int mld_compute_pack_z(uint8_t sig[MLDSA_CRYPTO_BYTES], const mld_poly *cp,
                       const mld_s1vec *s1, const mld_polyvecl *y, mld_poly *z,
                       mld_poly *tmp);

void harness(void)
{
  uint8_t *sig;
  mld_poly *cp;
  mld_s1vec *s1;
  mld_polyvecl *y;
  mld_poly *z;
  mld_poly *tmp;

  int r;
  r = mld_compute_pack_z(sig, cp, s1, y, z, tmp);
}
