// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

int mld_attempt_signature_generation(uint8_t *sig, const uint8_t *mu,
                                     const uint8_t rhoprime[MLDSA_CRHBYTES],
                                     uint16_t nonce, mld_polymat *mat,
                                     const mld_s1vec *s1, const mld_s2vec *s2,
                                     const mld_t0vec *t0);

void harness(void)
{
  uint8_t *sig;
  uint8_t *mu;
  uint8_t *rhoprime;
  uint16_t nonce;
  mld_polymat *mat;
  mld_s1vec *s1;
  mld_s2vec *s2;
  mld_t0vec *t0;

  int r;
  r = mld_attempt_signature_generation(sig, mu, rhoprime, nonce, mat, s1, s2,
                                       t0);
}
