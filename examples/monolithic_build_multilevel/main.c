/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "expected_test_vectors_multilevel.h"
#include "mldsa_native_all.h"
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

/* Keygen examples */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static int example_mldsa44_keygen(void)
{
  uint8_t pk[MLDSA44_PUBLICKEYBYTES];
  uint8_t sk[MLDSA44_SECRETKEYBYTES];

  printf("  Generating keypair... ");
  CHECK(mldsa44_keypair(pk, sk) == 0);
  CHECK(memcmp(pk, test_vector_pk_44, MLDSA44_PUBLICKEYBYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk_44, MLDSA44_SECRETKEYBYTES) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa65_keygen(void)
{
  uint8_t pk[MLDSA65_PUBLICKEYBYTES];
  uint8_t sk[MLDSA65_SECRETKEYBYTES];

  printf("  Generating keypair... ");
  CHECK(mldsa65_keypair(pk, sk) == 0);
  CHECK(memcmp(pk, test_vector_pk_65, MLDSA65_PUBLICKEYBYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk_65, MLDSA65_SECRETKEYBYTES) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa87_keygen(void)
{
  uint8_t pk[MLDSA87_PUBLICKEYBYTES];
  uint8_t sk[MLDSA87_SECRETKEYBYTES];

  printf("  Generating keypair... ");
  CHECK(mldsa87_keypair(pk, sk) == 0);
  CHECK(memcmp(pk, test_vector_pk_87, MLDSA87_PUBLICKEYBYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk_87, MLDSA87_SECRETKEYBYTES) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_KEYPAIR_API */
static int example_mldsa44_keygen(void)
{
  printf("  Generating keypair... SKIPPED (keygen API disabled)\n");
  return 0;
}
static int example_mldsa65_keygen(void)
{
  printf("  Generating keypair... SKIPPED (keygen API disabled)\n");
  return 0;
}
static int example_mldsa87_keygen(void)
{
  printf("  Generating keypair... SKIPPED (keygen API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_KEYPAIR_API */

/* Sign examples */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static int example_mldsa44_sign(void)
{
  uint8_t sig[MLDSA44_BYTES];
  size_t siglen;

  printf("  Signing message... ");
  CHECK(mldsa44_signature(sig, &siglen, (const uint8_t *)TEST_VECTOR_MSG,
                          TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                          TEST_VECTOR_CTX_LEN, test_vector_sk_44) == 0);
  CHECK(siglen == sizeof(test_vector_sig_44));
  CHECK(memcmp(sig, test_vector_sig_44, siglen) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa65_sign(void)
{
  uint8_t sig[MLDSA65_BYTES];
  size_t siglen;

  printf("  Signing message... ");
  CHECK(mldsa65_signature(sig, &siglen, (const uint8_t *)TEST_VECTOR_MSG,
                          TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                          TEST_VECTOR_CTX_LEN, test_vector_sk_65) == 0);
  CHECK(siglen == sizeof(test_vector_sig_65));
  CHECK(memcmp(sig, test_vector_sig_65, siglen) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa87_sign(void)
{
  uint8_t sig[MLDSA87_BYTES];
  size_t siglen;

  printf("  Signing message... ");
  CHECK(mldsa87_signature(sig, &siglen, (const uint8_t *)TEST_VECTOR_MSG,
                          TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                          TEST_VECTOR_CTX_LEN, test_vector_sk_87) == 0);
  CHECK(siglen == sizeof(test_vector_sig_87));
  CHECK(memcmp(sig, test_vector_sig_87, siglen) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_SIGN_API */
static int example_mldsa44_sign(void)
{
  printf("  Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
static int example_mldsa65_sign(void)
{
  printf("  Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
static int example_mldsa87_sign(void)
{
  printf("  Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_SIGN_API */

/* Verify examples */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static int example_mldsa44_verify(void)
{
  printf("  Verifying signature... ");
  CHECK(mldsa44_verify(test_vector_sig_44, sizeof(test_vector_sig_44),
                       (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN,
                       (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN,
                       test_vector_pk_44) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa65_verify(void)
{
  printf("  Verifying signature... ");
  CHECK(mldsa65_verify(test_vector_sig_65, sizeof(test_vector_sig_65),
                       (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN,
                       (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN,
                       test_vector_pk_65) == 0);
  printf("DONE\n");
  return 0;
}

static int example_mldsa87_verify(void)
{
  printf("  Verifying signature... ");
  CHECK(mldsa87_verify(test_vector_sig_87, sizeof(test_vector_sig_87),
                       (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN,
                       (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN,
                       test_vector_pk_87) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_VERIFY_API */
static int example_mldsa44_verify(void)
{
  printf("  Verifying signature... SKIPPED (verify API disabled)\n");
  return 0;
}
static int example_mldsa65_verify(void)
{
  printf("  Verifying signature... SKIPPED (verify API disabled)\n");
  return 0;
}
static int example_mldsa87_verify(void)
{
  printf("  Verifying signature... SKIPPED (verify API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_VERIFY_API */

int main(void)
{
  int r = 0;

  printf("ML-DSA monolithic_build_multilevel Example\n");
  printf("======================\n\n");

  printf("ML-DSA-44\n");
  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();
  r |= example_mldsa44_keygen();
  /* WARNING: Test-only
   * Normally, you would seed a PRNG _once_ with trustworthy entropy
   * and not reseed it afterwards. Here, we reseed to make tests
   * independent and reproducible. */
  randombytes_reset();
  r |= example_mldsa44_sign();
  r |= example_mldsa44_verify();

  printf("\nML-DSA-65\n");
  randombytes_reset();
  r |= example_mldsa65_keygen();
  randombytes_reset();
  r |= example_mldsa65_sign();
  r |= example_mldsa65_verify();

  printf("\nML-DSA-87\n");
  randombytes_reset();
  r |= example_mldsa87_keygen();
  randombytes_reset();
  r |= example_mldsa87_sign();
  r |= example_mldsa87_verify();

  if (r)
  {
    return 1;
  }

  printf("\nAll tests passed!\n");
  return 0;
}
