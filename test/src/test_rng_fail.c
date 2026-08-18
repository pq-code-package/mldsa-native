/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <stddef.h>
#include <stdio.h>
#include <string.h>

/* Expose internal functions */
#define MLD_BUILD_INTERNAL
#include "../../mldsa/mldsa_native.h"
#include "../../mldsa/src/common.h"
#include "expected_test_vectors.h"

#include "test_namespace.h"

/*
 * This test checks that we handle randombytes failures correctly by:
 * - Returning MLD_ERR_RNG_FAIL when randombytes fails
 *
 * This is done through a custom randombytes implementation that can be
 * configured to fail at specific invocation counts.
 */

/* Include notrandombytes, renaming its randombytes to notrandombytes */
#define randombytes notrandombytes
#include "../notrandombytes/notrandombytes.c"
#undef randombytes

/*
 * Randombytes invocation tracker
 */

int randombytes(uint8_t *buf, size_t len);
int randombytes_counter = 0;
int randombytes_fail_on_counter = -1;

static void reset_all(void)
{
  randombytes_counter = 0;
  randombytes_fail_on_counter = -1;
  randombytes_reset();
}

int randombytes(uint8_t *buf, size_t len)
{
  int current_invocation = randombytes_counter++;

  if (current_invocation == randombytes_fail_on_counter)
  {
    return -1;
  }

  return notrandombytes(buf, len);
}

#define TEST_RNG_FAILURE(test_name, call)                              \
  do                                                                   \
  {                                                                    \
    int num_randombytes_calls, i, rc;                                  \
    /* First pass: count randombytes invocations */                    \
    reset_all();                                                       \
    rc = call;                                                         \
    if (rc != 0)                                                       \
    {                                                                  \
      fprintf(stderr,                                                  \
              "ERROR: %s failed with return code %d "                  \
              "in dry-run\n",                                          \
              test_name, rc);                                          \
      return 1;                                                        \
    }                                                                  \
    num_randombytes_calls = randombytes_counter;                       \
    if (num_randombytes_calls == 0)                                    \
    {                                                                  \
      printf("Skipping %s (no randombytes() calls)\n", test_name);     \
      break;                                                           \
    }                                                                  \
    /* Second pass: test each randombytes failure */                   \
    for (i = 0; i < num_randombytes_calls; i++)                        \
    {                                                                  \
      reset_all();                                                     \
      randombytes_fail_on_counter = i;                                 \
      rc = call;                                                       \
      if (rc != MLD_ERR_RNG_FAIL)                                      \
      {                                                                \
        int rc2;                                                       \
        /* Re-run to ensure clean state */                             \
        reset_all();                                                   \
        rc2 = call;                                                    \
        (void)rc2;                                                     \
        if (rc == 0)                                                   \
        {                                                              \
          fprintf(stderr,                                              \
                  "ERROR: %s unexpectedly succeeded when randombytes " \
                  "%d/%d was instrumented to fail\n",                  \
                  test_name, i + 1, num_randombytes_calls);            \
        }                                                              \
        else                                                           \
        {                                                              \
          fprintf(stderr,                                              \
                  "ERROR: %s failed with wrong error code %d "         \
                  "(expected %d) when randombytes %d/%d was "          \
                  "instrumented to fail\n",                            \
                  test_name, rc, MLD_ERR_RNG_FAIL, i + 1,              \
                  num_randombytes_calls);                              \
        }                                                              \
        return 1;                                                      \
      }                                                                \
    }                                                                  \
    printf(                                                            \
        "RNG failure test for %s PASSED.\n"                            \
        "  Tested %d randombytes invocation point(s)\n",               \
        test_name, num_randombytes_calls);                             \
  } while (0)

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
static int test_keygen_rng_failure(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];

  TEST_RNG_FAILURE("keypair", mld_sign_keypair(pk, sk));
  return 0;
}
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

static int test_pk_from_sk_rng_failure(void)
{
  uint8_t pk[MLDSA_PK_BYTES];

  TEST_RNG_FAILURE("pk_from_sk", mld_sign_pk_from_sk(pk, test_vector_sk));
  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
static int test_sign_rng_failure(void)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  TEST_RNG_FAILURE(
      "signature",
      mld_sign_signature(sig, (const uint8_t *)TEST_VECTOR_MSG,
                         TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                         TEST_VECTOR_CTX_LEN, test_vector_sk));
  return 0;
}

static int test_signature_extmu_rng_failure(void)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t mu[64] = {0};

  TEST_RNG_FAILURE("signature_extmu",
                   mld_sign_signature_extmu(sig, mu, test_vector_sk));
  return 0;
}
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

static int test_signature_pre_hash_shake256_rng_failure(void)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t rnd[32] = {0};
  TEST_RNG_FAILURE("signature_pre_hash_shake256",
                   mld_sign_signature_pre_hash_shake256(
                       sig, (const uint8_t *)TEST_VECTOR_MSG,
                       TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                       TEST_VECTOR_CTX_LEN, rnd, test_vector_sk));
  return 0;
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static int test_verify_rng_failure(void)
{
  TEST_RNG_FAILURE(
      "verify",
      mld_sign_verify(test_vector_sig, (const uint8_t *)TEST_VECTOR_MSG,
                      TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                      TEST_VECTOR_CTX_LEN, test_vector_pk));
  return 0;
}

static int test_verify_extmu_rng_failure(void)
{
  TEST_RNG_FAILURE("verify_extmu",
                   mld_sign_verify_extmu(test_vector_sig_extmu, test_vector_mu,
                                         test_vector_pk));
  return 0;
}

static int test_verify_pre_hash_shake256_rng_failure(void)
{
  TEST_RNG_FAILURE(
      "verify_pre_hash_shake256",
      mld_sign_verify_pre_hash_shake256(
          test_vector_sig_pre_hash_shake256, (const uint8_t *)TEST_VECTOR_MSG,
          TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
          TEST_VECTOR_CTX_LEN, test_vector_pk));
  return 0;
}
#endif /* !MLD_CONFIG_NO_VERIFY_API */

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(void);
#endif
int main(void)
{
  int r = 0;

  /* Keygen tests */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  r |= test_keygen_rng_failure();
#endif
  r |= test_pk_from_sk_rng_failure();
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

  /* Sign tests */
#if !defined(MLD_CONFIG_NO_SIGN_API)
#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  r |= test_sign_rng_failure();
  r |= test_signature_extmu_rng_failure();
#endif
  r |= test_signature_pre_hash_shake256_rng_failure();
#endif /* !MLD_CONFIG_NO_SIGN_API */

  /* Verify tests */
#if !defined(MLD_CONFIG_NO_VERIFY_API)
  r |= test_verify_rng_failure();
  r |= test_verify_extmu_rng_failure();
  r |= test_verify_pre_hash_shake256_rng_failure();
#endif

  if (r)
  {
    return 1;
  }

  return 0;
}
