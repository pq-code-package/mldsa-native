/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <mldsa_native.h>
#include "expected_test_vectors.h"

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#include "test_only_rng/notrandombytes.h"
#endif

#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    int rc;                                                   \
    rc = (x);                                                 \
    if (!rc)                                                  \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      return 1;                                               \
    }                                                         \
  } while (0)

#define TEST_MSG \
  "This is a test message for ML-DSA digital signature algorithm!"
#define TEST_MSG_LEN (sizeof(TEST_MSG) - 1)

#define TEST_CTX "test_context_123"
#define TEST_CTX_LEN (sizeof(TEST_CTX) - 1)

int main(void)
{
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  {
    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES];

    randombytes_reset();

    printf("Generating keypair... ");
    CHECK(crypto_sign_keypair(pk, sk) == 0);
    printf("DONE\n");

    printf("Checking keypair against expected values... ");
    CHECK(memcmp(pk, expected_pk, CRYPTO_PUBLICKEYBYTES) == 0);
    CHECK(memcmp(sk, expected_sk, CRYPTO_SECRETKEYBYTES) == 0);
    printf("DONE\n");
  }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
  {
    uint8_t sig[CRYPTO_BYTES];
    size_t siglen;

    printf("Signing message... ");
    CHECK(crypto_sign_signature(sig, &siglen, (const uint8_t *)TEST_MSG,
                                TEST_MSG_LEN, (const uint8_t *)TEST_CTX,
                                TEST_CTX_LEN, expected_sk) == 0);
    printf("DONE\n");

#if !defined(MLD_CONFIG_NO_VERIFY_API)
    printf("Verifying generated signature... ");
    CHECK(crypto_sign_verify(sig, siglen, (const uint8_t *)TEST_MSG,
                             TEST_MSG_LEN, (const uint8_t *)TEST_CTX,
                             TEST_CTX_LEN, expected_pk) == 0);
    printf("DONE\n");
#endif /* !MLD_CONFIG_NO_VERIFY_API */
  }
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
  {
    printf("Verifying expected signature... ");
    CHECK(crypto_sign_verify(expected_sig, sizeof(expected_sig),
                             (const uint8_t *)TEST_MSG, TEST_MSG_LEN,
                             (const uint8_t *)TEST_CTX, TEST_CTX_LEN,
                             expected_pk) == 0);
    printf("DONE\n");
  }
#endif /* !MLD_CONFIG_NO_VERIFY_API */

  printf("All tests passed!\n");
  return 0;
}
