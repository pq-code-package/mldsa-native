// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

int mld_sign_pk_from_sk(uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
                        const uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES]);

void harness(void)
{
  uint8_t *pk;
  uint8_t *sk;

  int r;
  r = mld_sign_pk_from_sk(pk, sk);
}
