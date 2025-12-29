/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <stddef.h>
#include <stdio.h>
#include <string.h>

/* Expose declaration of randombytes (normally internal) */
#define MLD_BUILD_INTERNAL
#include "../mldsa/mldsa_native.h"
#include "../mldsa/src/common.h"
#include "notrandombytes/notrandombytes.h"

/*
 * This test checks that we handle randombytes failures correctly by:
 * - Returning MLD_ERR_RNG_FAIL when randombytes fails
 * - Cleaning up all memory when randombytes fails
 *
 * This is done through a custom randombytes implementation that can be
 * configured to fail at specific invocation counts.
 */

/*
 * Randombytes invocation tracker
 */

int randombytes_counter = 0;
int randombytes_fail_on_counter = -1;

static void reset_all(void)
{
  randombytes_reset();
  randombytes_counter = 0;
  randombytes_fail_on_counter = -1;
}

int mld_randombytes(uint8_t *out, size_t outlen)
{
  int current_invocation = randombytes_counter++;

  if (current_invocation == randombytes_fail_on_counter)
  {
    return -1;
  }

  return randombytes(out, outlen);
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

static int test_keygen_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];

  TEST_RNG_FAILURE("mld_keypair", mld_keypair(pk, sk));
  return 0;
}

static int test_sign_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  /* Generate valid keypair first */
  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in sign test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE(
      "mld_signature",
      mld_signature(sig, &siglen, msg, sizeof(msg), ctx, sizeof(ctx) - 1, sk));
  return 0;
}

static int test_verify_rng_failure(void)
{
  uint8_t pk[MLDSA_PUBLICKEYBYTES(MLD_CONFIG_API_PARAMETER_SET)];
  uint8_t sk[MLDSA_SECRETKEYBYTES(MLD_CONFIG_API_PARAMETER_SET)];
  uint8_t sig[MLDSA_BYTES(MLD_CONFIG_API_PARAMETER_SET)];
  size_t siglen;
  uint8_t msg[32] = {0};
  uint8_t ctx[10] = "test";

  /* Generate valid keypair and signature first */
  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: crypto_sign_keypair failed in verify test setup\n");
    return 1;
  }

  if (mld_signature(sig, &siglen, msg, sizeof(msg), ctx, sizeof(ctx), sk) != 0)
  {
    fprintf(stderr,
            "ERROR: crypto_sign_signature failed in verify test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE(
      "crypto_sign_verify",
      mld_verify(sig, siglen, msg, sizeof(msg), ctx, sizeof(ctx), pk));
  return 0;
}

static int test_sign_combined_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sm[CRYPTO_BYTES + 32];
  uint8_t msg[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t smlen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in sign combined test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE("mld_sign", mld_sign(sm, &smlen, msg, sizeof(msg), ctx,
                                        sizeof(ctx) - 1, sk));
  return 0;
}

static int test_open_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sm[CRYPTO_BYTES + 32];
  uint8_t msg[32] = {0};
  uint8_t msg_out[CRYPTO_BYTES + 32];
  const uint8_t ctx[] = "test context";
  size_t smlen, mlen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in open test setup\n");
    return 1;
  }

  if (mld_sign(sm, &smlen, msg, sizeof(msg), ctx, sizeof(ctx) - 1, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_sign failed in open test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE("mld_open", mld_open(msg_out, &mlen, sm, smlen, ctx,
                                        sizeof(ctx) - 1, pk));
  return 0;
}

static int test_signature_extmu_rng_failure(void)
{
  uint8_t pk[MLDSA_PUBLICKEYBYTES(MLD_CONFIG_API_PARAMETER_SET)];
  uint8_t sk[MLDSA_SECRETKEYBYTES(MLD_CONFIG_API_PARAMETER_SET)];
  uint8_t sig[MLDSA_BYTES(MLD_CONFIG_API_PARAMETER_SET)];
  size_t siglen;
  uint8_t mu[MLDSA_CRHBYTES];

  /* Generate valid keypair first */
  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(
        stderr,
        "ERROR: crypto_sign_keypair failed in signature_extmu test setup\n");
    return 1;
  }

  /* Fill mu with test data */
  randombytes(mu, sizeof(mu));

  TEST_RNG_FAILURE("crypto_sign_signature_extmu",
                   mld_signature_extmu(sig, &siglen, mu, sk));
  return 0;
}

static int test_verify_extmu_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t mu[64] = {0};
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in verify_extmu test setup\n");
    return 1;
  }

  if (mld_signature_extmu(sig, &siglen, mu, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_signature_extmu failed in verify_extmu test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE("mld_verify_extmu", mld_verify_extmu(sig, siglen, mu, pk));
  return 0;
}

static int test_signature_pre_hash_shake256_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  uint8_t rnd[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_keypair failed in signature_pre_hash_shake256 test "
            "setup\n");
    return 1;
  }

  TEST_RNG_FAILURE(
      "mld_signature_pre_hash_shake256",
      mld_signature_pre_hash_shake256(sig, &siglen, msg, sizeof(msg), ctx,
                                      sizeof(ctx) - 1, rnd, sk));
  return 0;
}

static int test_verify_pre_hash_shake256_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  uint8_t rnd[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_keypair failed in verify_pre_hash_shake256 test "
            "setup\n");
    return 1;
  }

  if (mld_signature_pre_hash_shake256(sig, &siglen, msg, sizeof(msg), ctx,
                                      sizeof(ctx) - 1, rnd, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_signature_pre_hash_shake256 failed in "
            "verify_pre_hash_shake256 test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE("mld_verify_pre_hash_shake256",
                   mld_verify_pre_hash_shake256(sig, siglen, msg, sizeof(msg),
                                                ctx, sizeof(ctx) - 1, pk));
  return 0;
}

static int test_pk_from_sk_rng_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in pk_from_sk test setup\n");
    return 1;
  }

  TEST_RNG_FAILURE("mld_pk_from_sk", mld_pk_from_sk(pk, sk));
  return 0;
}

int main(void)
{
  if (test_keygen_rng_failure() != 0)
  {
    return 1;
  }

  if (test_sign_rng_failure() != 0)
  {
    return 1;
  }

  if (test_verify_rng_failure() != 0)
  {
    return 1;
  }

  if (test_sign_combined_rng_failure() != 0)
  {
    return 1;
  }

  if (test_open_rng_failure() != 0)
  {
    return 1;
  }

  if (test_signature_extmu_rng_failure() != 0)
  {
    return 1;
  }

  if (test_verify_extmu_rng_failure() != 0)
  {
    return 1;
  }

  if (test_signature_pre_hash_shake256_rng_failure() != 0)
  {
    return 1;
  }

  if (test_verify_pre_hash_shake256_rng_failure() != 0)
  {
    return 1;
  }

  if (test_pk_from_sk_rng_failure() != 0)
  {
    return 1;
  }

  return 0;
}
