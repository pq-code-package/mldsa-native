/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "../notrandombytes/notrandombytes.h"
#include "expected_test_vectors.h"
#include "mldsa_native.h"
#include "src/sys.h"

#include "test_namespace.h"

#ifndef NTESTS
#define NTESTS 100
#endif
#define MLEN 59
#define CTXLEN 1

#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    int r;                                                    \
    r = (x);                                                  \
    if (!r)                                                   \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      return 1;                                               \
    }                                                         \
  } while (0)

/* For test-configurations with a low threshold of signing attempts,
 * consider the possibility of signatures failing. */
#if defined(MLD_ALLOW_NONCOMPLIANT_SIGNING_BOUND)
#define CHECK_SIGN_RC(rc)                      \
  do                                           \
  {                                            \
    if (rc == MLD_ERR_SIGN_ATTEMPTS_EXHAUSTED) \
    {                                          \
      return 0;                                \
    }                                          \
    CHECK(rc == 0);                            \
  } while (0)
#else /* MLD_ALLOW_NONCOMPLIANT_SIGNING_BOUND */
#define CHECK_SIGN_RC(rc) CHECK(rc == 0)
#endif /* !MLD_ALLOW_NONCOMPLIANT_SIGNING_BOUND */


#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&                                      \
    !defined(MLD_CONFIG_NO_RANDOMIZED_API)
static int test_sign_core(uint8_t pk[MLDSA_PK_BYTES],
                          uint8_t sk[MLDSA_SK_BYTES],
                          uint8_t sig[MLDSA_SIG_BYTES], uint8_t m[MLEN],
                          uint8_t ctx[CTXLEN])
{
  int rc;


  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, CTXLEN);
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, MLEN);

  CHECK_SIGN_RC(mld_sign_signature(sig, m, MLEN, ctx, CTXLEN, sk));

  rc = mld_sign_verify(sig, m, MLEN, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));

  if (rc)
  {
    printf("ERROR: verify\n");
    return 1;
  }

  return 0;
}

static int test_sign(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];

  return test_sign_core(pk, sk, sig, m, ctx);
}

static int test_sign_unaligned(void)
{
  MLD_ALIGN uint8_t pk[MLDSA_PK_BYTES + 1];
  MLD_ALIGN uint8_t sk[MLDSA_SK_BYTES + 1];
  MLD_ALIGN uint8_t sig[MLDSA_SIG_BYTES + 1];
  MLD_ALIGN uint8_t m[MLEN + 1];
  MLD_ALIGN uint8_t ctx[CTXLEN + 1];

  return test_sign_core(pk + 1, sk + 1, sig + 1, m + 1, ctx + 1);
}

static int test_sign_extmu(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t mu[MLDSA_CRHBYTES];

  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(mu, MLDSA_CRHBYTES) == 0);
  MLD_CT_TESTING_SECRET(mu, sizeof(mu));

  CHECK_SIGN_RC(mld_sign_signature_extmu(sig, mu, sk));
  CHECK(mld_sign_verify_extmu(sig, mu, pk) == 0);

  return 0;
}


static int test_sign_pre_hash(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  uint8_t rnd[MLDSA_RNDBYTES];


  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));
  CHECK(randombytes(rnd, MLDSA_RNDBYTES) == 0);
  MLD_CT_TESTING_SECRET(rnd, sizeof(rnd));

  CHECK_SIGN_RC(
      mld_sign_signature_pre_hash_shake256(sig, m, MLEN, ctx, CTXLEN, rnd, sk));
  CHECK(mld_sign_verify_pre_hash_shake256(sig, m, MLEN, ctx, CTXLEN, pk) == 0);

  /* MLD_PREHASH_NONE must be rejected by the internal prehash APIs. */
  CHECK(mld_sign_verify_pre_hash_internal(sig, m, MLEN, ctx, CTXLEN, pk,
                                          MLD_PREHASH_NONE) ==
        MLD_ERR_INVALID_ARG);
  CHECK(mld_sign_signature_pre_hash_internal(sig, m, MLEN, ctx, CTXLEN, rnd, sk,
                                             MLD_PREHASH_NONE) ==
        MLD_ERR_INVALID_ARG);

  return 0;
}

/* Empty message with a NULL pointer: m may be NULL when mlen == 0.
 * Covers both the pure and SHAKE256 pre-hash paths, so the mlen == 0
 * behaviour is exercised for prehash as well, across all backends in CI. */
static int test_sign_empty_message(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t ctx[CTXLEN];
  uint8_t rnd[MLDSA_RNDBYTES];
  int rc;

  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, CTXLEN);

  /* Pure ML-DSA */
  CHECK_SIGN_RC(mld_sign_signature(sig, NULL, 0, ctx, CTXLEN, sk));
  rc = mld_sign_verify(sig, NULL, 0, ctx, CTXLEN, pk);
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  if (rc)
  {
    printf("ERROR: empty_message: pure verify\n");
    return 1;
  }

  /* HashML-DSA (SHAKE256 pre-hash) */
  CHECK(randombytes(rnd, MLDSA_RNDBYTES) == 0);
  MLD_CT_TESTING_SECRET(rnd, sizeof(rnd));
  CHECK_SIGN_RC(
      mld_sign_signature_pre_hash_shake256(sig, NULL, 0, ctx, CTXLEN, rnd, sk));
  rc = mld_sign_verify_pre_hash_shake256(sig, NULL, 0, ctx, CTXLEN, pk);
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  if (rc)
  {
    printf("ERROR: empty_message: pre-hash verify\n");
    return 1;
  }

  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API && \
          !MLD_CONFIG_NO_VERIFY_API && !MLD_CONFIG_NO_RANDOMIZED_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static int test_pk_from_sk(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t pk_derived[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sk_corrupted[MLDSA_SK_BYTES];
  uint8_t seed[MLDSA_SEEDBYTES];
  int rc;

  /* Generate a keypair. Drive the internal entry point so that this test
   * also runs when the randomized API is disabled. */
  CHECK(randombytes(seed, MLDSA_SEEDBYTES) == 0);
  MLD_CT_TESTING_SECRET(seed, MLDSA_SEEDBYTES);
  CHECK(mld_sign_keypair_internal(pk, sk, seed) == 0);

  /* Derive public key from secret key */
  CHECK(mld_sign_pk_from_sk(pk_derived, sk) == 0);

  /* Verify derived public key matches original */
  if (memcmp(pk, pk_derived, MLDSA_PK_BYTES) != 0)
  {
    printf("ERROR: pk_from_sk - derived public key does not match original\n");
    return 1;
  }

  /* Test with corrupted t0 in secret key - should fail validation */
  memcpy(sk_corrupted, sk, MLDSA_SK_BYTES);
  /* Corrupt a byte in the t0 portion of the secret key */
  sk_corrupted[MLDSA_SEEDBYTES + MLDSA_TRBYTES + MLDSA_SEEDBYTES + 10] ^= 1;

  rc = mld_sign_pk_from_sk(pk_derived, sk_corrupted);

  /* Constant time: Declassify to check result */
  MLD_CT_TESTING_DECLASSIFY(&rc, sizeof(int));

  if (rc != MLD_ERR_INVALID_KEY)
  {
    printf("ERROR: pk_from_sk - should fail with corrupted t0 in secret key\n");
    return 1;
  }

  /* Test with corrupted tr in secret key - should fail validation */
  memcpy(sk_corrupted, sk, MLDSA_SK_BYTES);
  /* Corrupt a byte in the tr portion of the secret key */
  /* tr starts at offset 2 * MLDSA_SEEDBYTES (after rho and key) */
  sk_corrupted[2 * MLDSA_SEEDBYTES + 10] ^= 1;

  rc = mld_sign_pk_from_sk(pk_derived, sk_corrupted);

  /* Constant time: Declassify to check result */
  MLD_CT_TESTING_DECLASSIFY(&rc, sizeof(int));

  if (rc != MLD_ERR_INVALID_KEY)
  {
    printf(
        "ERROR: pk_from_sk - should fail with corrupted tr in "
        "secret key\n");
    return 1;
  }

  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&                                      \
    !defined(MLD_CONFIG_NO_RANDOMIZED_API)
static int test_wrong_pk(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  int rc;
  size_t idx;

  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK_SIGN_RC(mld_sign_signature(sig, m, MLEN, ctx, CTXLEN, sk));

  /* flip bit in public key */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= MLDSA_PK_BYTES;

  pk[idx] ^= 1;

  rc = mld_sign_verify(sig, m, MLEN, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));

  if (rc != MLD_ERR_INVALID_SIGNATURE)
  {
    printf("ERROR: wrong_pk: verify\n");
    return 1;
  }
  return 0;
}

static int test_wrong_sig(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  int rc;
  size_t idx;

  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK_SIGN_RC(mld_sign_signature(sig, m, MLEN, ctx, CTXLEN, sk));

  /* flip bit in signature */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= MLDSA_SIG_BYTES;

  sig[idx] ^= 1;

  rc = mld_sign_verify(sig, m, MLEN, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));

  if (rc != MLD_ERR_INVALID_SIGNATURE)
  {
    printf("ERROR: wrong_sig: verify\n");
    return 1;
  }
  return 0;
}


static int test_wrong_ctx(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  int rc;
  size_t idx;

  CHECK(mld_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK_SIGN_RC(mld_sign_signature(sig, m, MLEN, ctx, CTXLEN, sk));

  /* flip bit in ctx */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= CTXLEN;

  ctx[idx] ^= 1;

  rc = mld_sign_verify(sig, m, MLEN, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));

  if (rc != MLD_ERR_INVALID_SIGNATURE)
  {
    printf("ERROR: wrong_ctx: verify\n");
    return 1;
  }
  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API && \
          !MLD_CONFIG_NO_VERIFY_API && !MLD_CONFIG_NO_RANDOMIZED_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static int test_sign_expected_keypair(void)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  uint8_t test_vector_sk_copy[MLDSA_SK_BYTES];

  /* test_vector_rnd is the seed the deterministic test RNG hands out, so the
   * internal entry point must reproduce the same keypair. */
  CHECK(mld_sign_keypair_internal(pk, sk, test_vector_rnd) == 0);

  /* Declassify sk's for comparison. This is for testing purposes only.
   * Don't declassify the test_vector_sk itself because we need it to stay
   * secret for the CT signing tests. */
  MLD_CT_TESTING_DECLASSIFY(sk, MLDSA_SK_BYTES);
  memcpy(test_vector_sk_copy, test_vector_sk, MLDSA_SK_BYTES);
  MLD_CT_TESTING_DECLASSIFY(test_vector_sk_copy, MLDSA_SK_BYTES);

  CHECK(memcmp(pk, test_vector_pk, MLDSA_PK_BYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk_copy, MLDSA_SK_BYTES) == 0);

  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static int test_sign_expected_sign(void)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES];
  size_t pre_len;

  pre_len = mld_prepare_domain_separation_prefix(
      pre, NULL, 0, (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN,
      MLD_PREHASH_NONE);
  CHECK(pre_len != 0);
  CHECK_SIGN_RC(mld_sign_signature_internal(
      sig, (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN, pre, pre_len,
      test_vector_rnd, test_vector_sk, 0));
  CHECK(memcmp(sig, test_vector_sig, MLDSA_SIG_BYTES) == 0);

  return 0;
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static int test_sign_expected_verify(void)
{
  CHECK(mld_sign_verify(test_vector_sig, (const uint8_t *)TEST_VECTOR_MSG,
                        TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                        TEST_VECTOR_CTX_LEN, test_vector_pk) == 0);

  return 0;
}
#endif /* !MLD_CONFIG_NO_VERIFY_API */

static int test_sign_expected(void)
{
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  if (test_sign_expected_keypair() != 0)
  {
    return 1;
  }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */
#if !defined(MLD_CONFIG_NO_SIGN_API)
  if (test_sign_expected_sign() != 0)
  {
    return 1;
  }
#endif /* !MLD_CONFIG_NO_SIGN_API */
#if !defined(MLD_CONFIG_NO_VERIFY_API)
  if (test_sign_expected_verify() != 0)
  {
    return 1;
  }
#endif /* !MLD_CONFIG_NO_VERIFY_API */

  return 0;
}

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(void);
#endif
int main(void)
{
  unsigned i;
  int r;

  MLD_CT_TESTING_DECLASSIFY(test_vector_pk, MLDSA_PK_BYTES);
  MLD_CT_TESTING_DECLASSIFY(test_vector_sig, MLDSA_SIG_BYTES);
  MLD_CT_TESTING_SECRET(test_vector_sk, MLDSA_SK_BYTES);

  /* Check hardcoded test vectors as a minimal smoke test that works
   * even in reduced configurations. */
  if (test_sign_expected() != 0)
  {
    return 1;
  }

  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();

  for (i = 0; i < NTESTS; i++)
  {
    r = 0;
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&                                      \
    !defined(MLD_CONFIG_NO_RANDOMIZED_API)
    r |= test_sign();
    r |= test_sign_unaligned();
    r |= test_wrong_pk();
    r |= test_wrong_sig();
    r |= test_wrong_ctx();
    r |= test_sign_extmu();
    r |= test_sign_pre_hash();
    r |= test_sign_empty_message();
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API && \
          !MLD_CONFIG_NO_VERIFY_API && !MLD_CONFIG_NO_RANDOMIZED_API */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
    r |= test_pk_from_sk();
#endif

    if (r)
    {
      return 1;
    }
  }

  printf("MLDSA_SK_BYTES:  %d\n", MLDSA_SK_BYTES);
  printf("MLDSA_PK_BYTES:  %d\n", MLDSA_PK_BYTES);
  printf("MLDSA_SIG_BYTES: %d\n", MLDSA_SIG_BYTES);

  return 0;
}
