// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"
#include "sign.h"

int mld_compute_pack_t0_t1(
    uint8_t pk_t1[MLDSA_K * MLDSA_POLYT1_PACKEDBYTES],
    uint8_t t0_packed[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES],
    const mld_polyvecl *s1hat,
    const uint8_t s2_packed[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES],
    const uint8_t *rho);

void harness(void)
{
  uint8_t *pk_t1;
  uint8_t *t0_packed;
  mld_polyvecl *s1hat;
  uint8_t *s2_packed;
  uint8_t *rho;

  mld_compute_pack_t0_t1(pk_t1, t0_packed, s1hat, s2_packed, rho);
}
