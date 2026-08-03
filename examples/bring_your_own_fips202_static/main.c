/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
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

/* Convenience abbreviations for the key and signature sizes.
 *
 * Ordinarily you know the parameter set you're working with, so you would
 * just use the level-specific constants directly, e.g. MLDSA44_PUBLICKEYBYTES,
 * MLDSA65_BYTES, or MLDSA87_SECRETKEYBYTES.
 *
 * These examples, however, are compiled for all three parameter sets (44, 65,
 * 87), so we keep things generic by deriving the sizes from the configured
 * MLD_CONFIG_PARAMETER_SET. */
#define MLDSA_PK_BYTES MLDSA_PUBLICKEYBYTES(MLD_CONFIG_PARAMETER_SET)
#define MLDSA_SK_BYTES MLDSA_SECRETKEYBYTES(MLD_CONFIG_PARAMETER_SET)
#define MLDSA_SIG_BYTES MLDSA_BYTES(MLD_CONFIG_PARAMETER_SET)

/*
 * This example demonstrates a static global state FIPS-202 implementation
 * that works correctly with ML-DSA when FIPS-202 operations are used serially.
 *
 * This implementation uses a single global state for SHAKE128 and SHAKE256,
 * requiring that no interleaved FIPS-202 operations occur.
 */

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
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];

#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  printf("Generating keypair (randomized)... ");
  CHECK(mldsa_keypair(pk, sk) == 0);
  CHECK(memcmp(pk, test_vector_pk, MLDSA_PK_BYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk, MLDSA_SK_BYTES) == 0);
  printf("DONE\n");
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

  printf("Generating keypair (deterministic)... ");
  CHECK(mldsa_keypair_internal(pk, sk, test_vector_rnd) == 0);
  CHECK(memcmp(pk, test_vector_pk, MLDSA_PK_BYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk, MLDSA_SK_BYTES) == 0);
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
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t pre[TEST_VECTOR_CTX_LEN + 2]; /* (0, ctxlen, ctx) */

#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  printf("Signing message (randomized)... ");
  CHECK(mldsa_signature(sig, (const uint8_t *)TEST_VECTOR_MSG,
                        TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                        TEST_VECTOR_CTX_LEN, test_vector_sk) == 0);
  CHECK(memcmp(sig, test_vector_sig, sizeof(test_vector_sig)) == 0);
  printf("DONE\n");
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

  printf("Signing message (deterministic)... ");
  pre[0] = 0;
  pre[1] = TEST_VECTOR_CTX_LEN;
  memcpy(pre + 2, TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN);
  CHECK(mldsa_signature_internal(sig, (const uint8_t *)TEST_VECTOR_MSG,
                                 TEST_VECTOR_MSG_LEN, pre, sizeof(pre),
                                 test_vector_rnd, test_vector_sk, 0) == 0);
  CHECK(memcmp(sig, test_vector_sig, sizeof(test_vector_sig)) == 0);
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
  CHECK(mldsa_verify(test_vector_sig, (const uint8_t *)TEST_VECTOR_MSG,
                     TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
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

  printf("ML-DSA-%d Bring Your Own FIPS-202 (Static) Example\n",
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

  printf("OK\n");

  return 0;
}
