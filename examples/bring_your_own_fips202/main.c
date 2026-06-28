/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Import public mldsa-native API
 *
 * This requires specifying the parameter set and namespace prefix
 * used for the build.
 */
#include <mldsa_native.h>
#include "expected_test_vectors.h"
#include "test_only_rng/notrandombytes.h"

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

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static int example_keygen(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];

  printf("Generating keypair... ");
  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(memcmp(pk, test_vector_pk, CRYPTO_PUBLICKEYBYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk, CRYPTO_SECRETKEYBYTES) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_KEYPAIR_API */
static int example_keygen(void)
{
  printf("Generating keypair... SKIPPED (keygen API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static int example_sign(void)
{
  uint8_t sig[CRYPTO_BYTES];
  size_t siglen;

  printf("Signing message... ");
  CHECK(crypto_sign_signature(sig, &siglen, (const uint8_t *)TEST_VECTOR_MSG,
                              TEST_VECTOR_MSG_LEN,
                              (const uint8_t *)TEST_VECTOR_CTX,
                              TEST_VECTOR_CTX_LEN, test_vector_sk) == 0);
  CHECK(siglen == sizeof(test_vector_sig));
  CHECK(memcmp(sig, test_vector_sig, siglen) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_SIGN_API */
static int example_sign(void)
{
  printf("Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static int example_verify(void)
{
  printf("Verifying signature... ");
  CHECK(crypto_sign_verify(test_vector_sig, sizeof(test_vector_sig),
                           (const uint8_t *)TEST_VECTOR_MSG,
                           TEST_VECTOR_MSG_LEN,
                           (const uint8_t *)TEST_VECTOR_CTX,
                           TEST_VECTOR_CTX_LEN, test_vector_pk) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_VERIFY_API */
static int example_verify(void)
{
  printf("Verifying signature... SKIPPED (verify API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_VERIFY_API */

int main(void)
{
  int r = 0;

  printf("ML-DSA-%d Bring Your Own FIPS-202 Example\n",
         MLD_CONFIG_PARAMETER_SET);
  printf("======================\n\n");

  printf("Message: %s\n", TEST_VECTOR_MSG);
  printf("Context: %s\n\n", TEST_VECTOR_CTX);

  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();
  r |= example_keygen();

  /* WARNING: Test-only
   * Normally, you would seed a PRNG _once_ with trustworthy entropy
   * and not reseed it afterwards. Here, we reseed to make tests
   * independent and reproducible. */
  randombytes_reset();
  r |= example_sign();

  r |= example_verify();

  if (r)
  {
    return 1;
  }

  printf("\nAll tests passed! ML-DSA signature verification successful.\n");
  return 0;
}
