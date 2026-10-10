// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

static void mld_sample_pack_s1_s2(
    uint8_t s1_packed[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES],
    uint8_t s2_packed[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES], mld_polyvecl *s1,
    const uint8_t seed[MLDSA_CRHBYTES]);

void harness(void)
{
  uint8_t *s1_packed;
  uint8_t *s2_packed;
  uint8_t *seed;
  mld_polyvecl *s1;

  mld_sample_pack_s1_s2(s1_packed, s2_packed, s1, seed);
}
