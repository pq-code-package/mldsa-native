// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"
#include "sign.h"

int mld_compute_pack_z(uint8_t sig[MLDSA_CRYPTO_BYTES], const mld_poly *cp,
                       const mld_sk_s1hat *s1, const mld_yvec *y, mld_poly *z,
                       mld_poly *tmp);

void harness(void)
{
  uint8_t *sig;
  mld_poly *cp;
  mld_sk_s1hat *s1;
  mld_yvec *y;
  mld_poly *z;
  mld_poly *tmp;

  int r;
  r = mld_compute_pack_z(sig, cp, s1, y, z, tmp);
}
