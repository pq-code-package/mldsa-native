// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

#define MLD_SAMPLE_BATCH 4

static void mld_sample_pack_s1_s2(uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
                                  const uint8_t seed[MLDSA_CRHBYTES],
                                  mld_poly buf[MLD_SAMPLE_BATCH]);

void harness(void)
{
  uint8_t *sk;
  uint8_t *seed;
  mld_poly *buf;

  mld_sample_pack_s1_s2(sk, seed, buf);
}
