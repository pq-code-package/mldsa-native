/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Import public mldsa-native API
 *
 * This requires specifying the parameter set and namespace prefix
 * used for the build.
 *
 * The parameter set is configured on the command line
 */

#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa
#include <mldsa_native.h>
#include "expected_signatures.h"
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

int main(void)
{
  const char *test_msg =
      "This is a test message for ML-DSA digital signature algorithm!";
  const char *test_ctx = "test_context_123";
  size_t msglen = strlen(test_msg);
  size_t ctxlen = strlen(test_ctx);

  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t sm[msglen + CRYPTO_BYTES]; /* signed message buffer */
  uint8_t m2[msglen];                /* recovered message buffer */
  size_t siglen;
  size_t smlen;
  size_t mlen;

  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();

  printf("ML-DSA-%d monolithic_build Example\n", MLD_CONFIG_API_PARAMETER_SET);
  printf("======================\n\n");

  printf("Message: %s\n", test_msg);
  printf("Context: %s\n\n", test_ctx);

  printf("Generating keypair ... ");

  /* Alice generates a public/private key pair */
  CHECK(crypto_sign_keypair(pk, sk) == 0);

  printf("DONE\n");
  printf("Signing message... ");

  /* Alice signs the message */
  CHECK(crypto_sign_signature(sig, &siglen, (const uint8_t *)test_msg, msglen,
                              (const uint8_t *)test_ctx, ctxlen, sk) == 0);

  printf("DONE\n");
  printf("Verifying signature... ");

  /* Bob verifies Alice's signature */
  CHECK(crypto_sign_verify(sig, siglen, (const uint8_t *)test_msg, msglen,
                           (const uint8_t *)test_ctx, ctxlen, pk) == 0);

  printf("DONE\n");
  printf("Creating signed message... ");

  /* Alternative API: Create a signed message (signature + message combined) */
  CHECK(crypto_sign(sm, &smlen, (const uint8_t *)test_msg, msglen,
                    (const uint8_t *)test_ctx, ctxlen, sk) == 0);

  printf("DONE\n");
  printf("Opening signed message... ");

  /* Bob opens the signed message to recover the original message */
  CHECK(crypto_sign_open(m2, &mlen, sm, smlen, (const uint8_t *)test_ctx,
                         ctxlen, pk) == 0);

  printf("DONE\n");
  printf("Compare messages... ");

  /* Verify the recovered message matches the original */
  CHECK(mlen == msglen);
  CHECK(memcmp(test_msg, m2, msglen) == 0);

  printf("DONE\n\n");

  printf("Results:\n");
  printf("--------\n");
  printf("Public key size:  %d bytes\n", CRYPTO_PUBLICKEYBYTES);
  printf("Secret key size:  %d bytes\n", CRYPTO_SECRETKEYBYTES);
  printf("Signature size:   %d bytes\n", CRYPTO_BYTES);
  printf("Message length:   %zu bytes\n", msglen);
  printf("Signature length: %zu bytes\n", siglen);
  printf("Signed msg length: %zu bytes\n", smlen);

#if !defined(MLD_CONFIG_KEYGEN_PCT)
  /* Check against expected signature to make sure that
   * we integrated the library correctly */
  printf("Checking deterministic signature... ");
  {
    /* Compare the generated signature directly against the expected signature
     */
    CHECK(siglen == sizeof(expected_signature));
    CHECK(memcmp(sig, expected_signature, siglen) == 0);
  }
  printf("DONE\n");
#else
  printf(
      "[WARNING] Skipping KAT test since PCT is enabled and modifies PRNG\n");
#endif

  printf("Signature verification completed successfully!\n");

  printf("\nAll tests passed! ML-DSA signature verification successful.\n");
  return 0;
}
