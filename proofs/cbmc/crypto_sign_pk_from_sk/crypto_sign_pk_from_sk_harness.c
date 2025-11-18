// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

int crypto_sign_pk_from_sk(uint8_t pk[CRYPTO_PUBLICKEYBYTES],
                           const uint8_t sk[CRYPTO_SECRETKEYBYTES]);

void harness(void)
{
  uint8_t *pk;
  uint8_t *sk;

  int r;
  r = crypto_sign_pk_from_sk(pk, sk);
}
