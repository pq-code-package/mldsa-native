/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../mldsa/src/fips202/fips202.h"
#include "../../mldsa/src/packing.h"
#include "../../mldsa/src/params.h"
#include "../../mldsa/src/polyvec.h"
#include "../../mldsa/src/sign.h"
#include "../../mldsa/src/sys.h"
#include "../notrandombytes/notrandombytes.h"

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

/* Enum to specify which vector to corrupt in tests */
typedef enum
{
  CORRUPT_S1,
  CORRUPT_S2
} corrupt_vector_t;

/* Struct to define a coefficient corruption test case */
typedef struct
{
  corrupt_vector_t vector;  /* Which vector to corrupt (s1 or s2) */
  unsigned int poly_idx;    /* Polynomial index within the vector */
  unsigned int coeff_idx;   /* Coefficient index within the polynomial */
  int32_t corruption_value; /* Value to set the coefficient to */
  const char *description;  /* Description of the test case */
} corruption_test_case_t;


static int test_sign_core(uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
                          uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
                          uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES],
                          uint8_t m[MLEN],
                          uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES],
                          uint8_t ctx[CTXLEN])
{
  size_t smlen;
  size_t mlen;
  int rc;


  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, CTXLEN);
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, MLEN);

  CHECK(crypto_sign(sm, &smlen, m, MLEN, ctx, CTXLEN, sk) == 0);

  rc = crypto_sign_open(m2, &mlen, sm, smlen, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  MLD_CT_TESTING_DECLASSIFY(m, MLEN);
  MLD_CT_TESTING_DECLASSIFY(m2, (MLEN + MLDSA_CRYPTO_BYTES));

  if (rc)
  {
    printf("ERROR: crypto_sign_open\n");
    return 1;
  }

  if (memcmp(m, m2, MLEN))
  {
    printf("ERROR: crypto_sign_open - wrong message\n");
    return 1;
  }

  if (smlen != MLEN + MLDSA_CRYPTO_BYTES)
  {
    printf("ERROR: crypto_sign_open - wrong smlen\n");
    return 1;
  }

  if (mlen != MLEN)
  {
    printf("ERROR: crypto_sign_open - wrong mlen\n");
    return 1;
  }

  return 0;
}

static int test_sign(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN];
  uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES];
  uint8_t ctx[CTXLEN];

  return test_sign_core(pk, sk, sm, m, m2, ctx);
}

static int test_sign_unaligned(void)
{
  MLD_ALIGN uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES + 1];
  MLD_ALIGN uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES + 1];
  MLD_ALIGN uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES + 1];
  MLD_ALIGN uint8_t m[MLEN + 1];
  MLD_ALIGN uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES + 1];
  MLD_ALIGN uint8_t ctx[CTXLEN + 1];

  return test_sign_core(pk + 1, sk + 1, sm + 1, m + 1, m2 + 1, ctx + 1);
}

static int test_sign_extmu(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES];
  uint8_t mu[MLDSA_CRHBYTES];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(mu, MLDSA_CRHBYTES) == 0);
  MLD_CT_TESTING_SECRET(mu, sizeof(mu));

  CHECK(crypto_sign_signature_extmu(sig, &siglen, mu, sk) == 0);
  CHECK(crypto_sign_verify_extmu(sig, siglen, mu, pk) == 0);

  return 0;
}


static int test_sign_pre_hash(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  uint8_t rnd[MLDSA_RNDBYTES];
  size_t siglen;


  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));
  CHECK(randombytes(rnd, MLDSA_RNDBYTES) == 0);
  MLD_CT_TESTING_SECRET(rnd, sizeof(rnd));

  CHECK(crypto_sign_signature_pre_hash_shake256(sig, &siglen, m, MLEN, ctx,
                                                CTXLEN, rnd, sk) == 0);
  CHECK(crypto_sign_verify_pre_hash_shake256(sig, siglen, m, MLEN, ctx, CTXLEN,
                                             pk) == 0);

  return 0;
}

static int test_pk_from_sk(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t pk_derived[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sk_corrupted[MLDSA_CRYPTO_SECRETKEYBYTES];
  int rc;

  /* Generate a keypair */
  CHECK(crypto_sign_keypair(pk, sk) == 0);

  /* Derive public key from secret key */
  CHECK(crypto_sign_pk_from_sk(pk_derived, sk) == 0);

  /* Verify derived public key matches original */
  if (memcmp(pk, pk_derived, MLDSA_CRYPTO_PUBLICKEYBYTES) != 0)
  {
    printf("ERROR: pk_from_sk - derived public key does not match original\n");
    return 1;
  }

  /* Test with corrupted t0 in secret key - should fail validation */
  memcpy(sk_corrupted, sk, MLDSA_CRYPTO_SECRETKEYBYTES);
  /* Corrupt a byte in the t0 portion of the secret key */
  sk_corrupted[MLDSA_SEEDBYTES + MLDSA_TRBYTES + MLDSA_SEEDBYTES + 10] ^= 1;

  rc = crypto_sign_pk_from_sk(pk_derived, sk_corrupted);

  /* Constant time: Declassify to check result */
  MLD_CT_TESTING_DECLASSIFY(&rc, sizeof(int));

  if (rc != -1)
  {
    printf("ERROR: pk_from_sk - should fail with corrupted t0 in secret key\n");
    return 1;
  }

  /* Test with corrupted tr in secret key - should fail validation */
  memcpy(sk_corrupted, sk, MLDSA_CRYPTO_SECRETKEYBYTES);
  /* Corrupt a byte in the tr portion of the secret key */
  /* tr starts at offset 2 * MLDSA_SEEDBYTES (after rho and key) */
  sk_corrupted[2 * MLDSA_SEEDBYTES + 10] ^= 1;

  rc = crypto_sign_pk_from_sk(pk_derived, sk_corrupted);

  /* Constant time: Declassify to check result */
  MLD_CT_TESTING_DECLASSIFY(&rc, sizeof(int));

  if (rc != -1)
  {
    printf(
        "ERROR: crypto_sign_pk_from_sk - should fail with corrupted tr in "
        "secret key\n");
    return 1;
  }

  return 0;
}

/* Helper function to check if s1 and s2 coefficients are within valid range
 * [-eta, eta] */
static int check_s1_s2_coeffs_in_range(
    const uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES])
{
  uint8_t rho[MLDSA_SEEDBYTES];
  uint8_t tr[MLDSA_TRBYTES];
  uint8_t key[MLDSA_SEEDBYTES];
  mld_polyveck t0;
  mld_polyvecl s1;
  mld_polyveck s2;

  /* Unpack the secret key to extract s1 and s2 */
  mld_unpack_sk(rho, tr, key, &t0, &s1, &s2, sk);

  /* Check all coefficients in s1 are within [-MLDSA_ETA, MLDSA_ETA] */
  for (unsigned int i = 0; i < MLDSA_L; i++)
  {
    for (unsigned int j = 0; j < MLDSA_N; j++)
    {
      int32_t coeff = s1.vec[i].coeffs[j];
      if (coeff < -MLDSA_ETA || coeff > MLDSA_ETA)
      {
        return 0; /* Out of range */
      }
    }
  }

  /* Check all coefficients in s2 are within [-MLDSA_ETA, MLDSA_ETA] */
  for (unsigned int i = 0; i < MLDSA_K; i++)
  {
    for (unsigned int j = 0; j < MLDSA_N; j++)
    {
      int32_t coeff = s2.vec[i].coeffs[j];
      if (coeff < -MLDSA_ETA || coeff > MLDSA_ETA)
      {
        return 0; /* Out of range */
      }
    }
  }

  return 1; /* All coefficients in range */
}


/* Helper function to test crypto_sign_pk_from_sk with invalid s1 or s2
 * coefficients */
static int test_corrupted_sk(const corruption_test_case_t *test_case)
{
  uint8_t sk_corrupted[MLDSA_CRYPTO_SECRETKEYBYTES];
  int rc;
  const char *vector_name = (test_case->vector == CORRUPT_S1) ? "s1" : "s2";

  /* Start from a valid key pair */
  uint8_t pk_valid[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk_valid[MLDSA_CRYPTO_SECRETKEYBYTES];
  CHECK(crypto_sign_keypair(pk_valid, sk_valid) == 0);

  uint8_t rho[MLDSA_SEEDBYTES];
  uint8_t tr[MLDSA_TRBYTES];
  uint8_t key[MLDSA_SEEDBYTES];
  mld_polyveck t0;
  mld_polyvecl s1;
  mld_polyveck s2;

  mld_unpack_sk(rho, tr, key, &t0, &s1, &s2, sk_valid);

  /* Corrupt the specified coefficient */
  if (test_case->vector == CORRUPT_S1)
  {
    /* Validate indices are within bounds */
    if (test_case->poly_idx >= MLDSA_L || test_case->coeff_idx >= MLDSA_N)
    {
      printf("ERROR: s1 indices out of bounds: [%u][%u] (max [%u][%u])\n",
             test_case->poly_idx, test_case->coeff_idx, MLDSA_L - 1,
             MLDSA_N - 1);
      return 1;
    }
    s1.vec[test_case->poly_idx].coeffs[test_case->coeff_idx] =
        test_case->corruption_value;
  }
  else
  {
    /* Validate indices are within bounds */
    if (test_case->poly_idx >= MLDSA_K || test_case->coeff_idx >= MLDSA_N)
    {
      printf("ERROR: s2 indices out of bounds: [%u][%u] (max [%u][%u])\n",
             test_case->poly_idx, test_case->coeff_idx, MLDSA_K - 1,
             MLDSA_N - 1);
      return 1;
    }
    s2.vec[test_case->poly_idx].coeffs[test_case->coeff_idx] =
        test_case->corruption_value;
  }

  /* Regenerate t0, t1, tr, and pk to be consistent with the corrupted vector
   * https://github.com/aws/aws-lc/blob/0336dd78a0f2623c1f9b209a98cd497026d9c779/crypto/fipsmodule/ml_dsa/ml_dsa_ref/packing.c#L7-L61
   */
  mld_polymat mat;
  mld_polyveck t1;
  uint8_t pk_consistent[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t tr_consistent[MLDSA_TRBYTES];

  /* Expand matrix A from rho */
  mld_polyvec_matrix_expand(&mat, rho);

  /* Compute t = A * s1 + s2 */
  mld_polyvecl s1_ntt = s1;
  mld_polyvecl_ntt(&s1_ntt);
  mld_polyvec_matrix_pointwise_montgomery(&t1, &mat, &s1_ntt);
  mld_polyveck_reduce(&t1);
  mld_polyveck_invntt_tomont(&t1);
  mld_polyveck_add(&t1, &s2);
  mld_polyveck_reduce(&t1);
  mld_polyveck_caddq(&t1);

  /* Power2Round to get t1 and t0 */
  mld_polyveck_power2round(&t1, &t0, &t1);

  /* Pack public key and compute tr */
  mld_pack_pk(pk_consistent, rho, &t1);
  mld_shake256(tr_consistent, MLDSA_TRBYTES, pk_consistent,
               MLDSA_CRYPTO_PUBLICKEYBYTES);

  /* Pack the corrupted secret key */
  mld_pack_sk(sk_corrupted, rho, tr_consistent, key, &t0, &s1, &s2);

  /* Verify that it is corrupted */
  if (check_s1_s2_coeffs_in_range(sk_corrupted))
  {
    printf("ERROR: failed to corrupt secret key %s\n", vector_name);
    return 1;
  }

  /* Test crypto_sign_pk_from_sk with corrupted key */
  uint8_t pk_derived[MLDSA_CRYPTO_PUBLICKEYBYTES];
  rc = crypto_sign_pk_from_sk(pk_derived, sk_corrupted);
  MLD_CT_TESTING_DECLASSIFY(&rc, sizeof(int));

  if (rc != -1)
  {
    printf(
        "ERROR: pk_from_sk - should fail with corrupted secret key - %s - "
        "%s[%u][%u] = %d\n",
        test_case->description, vector_name, test_case->poly_idx,
        test_case->coeff_idx, test_case->corruption_value);
    return 1;
  }

  return 0;
}


static int test_wrong_pk(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN];
  uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES] = {0};
  uint8_t ctx[CTXLEN];
  size_t smlen;
  size_t mlen;
  int rc;
  size_t idx;
  size_t i;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK(crypto_sign(sm, &smlen, m, MLEN, ctx, CTXLEN, sk) == 0);

  /* flip bit in public key */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= MLDSA_CRYPTO_PUBLICKEYBYTES;

  pk[idx] ^= 1;

  rc = crypto_sign_open(m2, &mlen, sm, smlen, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  MLD_CT_TESTING_DECLASSIFY(m2, sizeof(m2));

  if (!rc)
  {
    printf("ERROR: wrong_pk: crypto_sign_open\n");
    return 1;
  }

  for (i = 0; i < MLEN; i++)
  {
    if (m2[i] != 0)
    {
      printf("ERROR: wrong_pk: crypto_sign_open - message should be zero\n");
      return 1;
    }
  }
  return 0;
}

static int test_wrong_sig(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN];
  uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES] = {0};
  uint8_t ctx[CTXLEN];
  size_t smlen;
  size_t mlen;
  int rc;
  size_t idx;
  size_t i;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK(crypto_sign(sm, &smlen, m, MLEN, ctx, CTXLEN, sk) == 0);

  /* flip bit in signed message */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= MLEN + MLDSA_CRYPTO_BYTES;

  sm[idx] ^= 1;

  rc = crypto_sign_open(m2, &mlen, sm, smlen, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  MLD_CT_TESTING_DECLASSIFY(m2, sizeof(m2));

  if (!rc)
  {
    printf("ERROR: wrong_sig: crypto_sign_open\n");
    return 1;
  }

  for (i = 0; i < MLEN; i++)
  {
    if (m2[i] != 0)
    {
      printf("ERROR: wrong_sig: crypto_sign_open - message should be zero\n");
      return 1;
    }
  }
  return 0;
}


static int test_wrong_ctx(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN];
  uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES] = {0};
  uint8_t ctx[CTXLEN];
  size_t smlen;
  size_t mlen;
  int rc;
  size_t idx;
  size_t i;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(randombytes(ctx, CTXLEN) == 0);
  MLD_CT_TESTING_SECRET(ctx, sizeof(ctx));
  CHECK(randombytes(m, MLEN) == 0);
  MLD_CT_TESTING_SECRET(m, sizeof(m));

  CHECK(crypto_sign(sm, &smlen, m, MLEN, ctx, CTXLEN, sk) == 0);

  /* flip bit in ctx */
  CHECK(randombytes((uint8_t *)&idx, sizeof(size_t)) == 0);
  idx %= CTXLEN;

  ctx[idx] ^= 1;

  rc = crypto_sign_open(m2, &mlen, sm, smlen, ctx, CTXLEN, pk);

  /* Constant time: Declassify outputs to check them. */
  MLD_CT_TESTING_DECLASSIFY(rc, sizeof(int));
  MLD_CT_TESTING_DECLASSIFY(m2, sizeof(m2));

  if (!rc)
  {
    printf("ERROR: wrong_sig: crypto_sign_open\n");
    return 1;
  }

  for (i = 0; i < MLEN; i++)
  {
    if (m2[i] != 0)
    {
      printf("ERROR: wrong_sig: crypto_sign_open - message should be zero\n");
      return 1;
    }
  }
  return 0;
}

int main(void)
{
  unsigned i;
  int r;

  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();

  for (i = 0; i < NTESTS; i++)
  {
    r = test_sign();
    r |= test_sign_unaligned();
    r |= test_wrong_pk();
    r |= test_wrong_sig();
    r |= test_wrong_ctx();
    r |= test_sign_extmu();
    r |= test_sign_pre_hash();
    r |= test_pk_from_sk();
    if (r)
    {
      return 1;
    }
  }

  /* Run comprehensive corrupted key tests */
  corruption_test_case_t test_cases[] = {
      /* Test s1 vector corruptions */
      {CORRUPT_S1, 0, 0, -(MLDSA_ETA + 1), "s1 underflow at [0][0]"},
      {CORRUPT_S1, 0, 0, MLDSA_ETA + 1, "s1 overflow at [0][0]"},
      {CORRUPT_S1, 0, 1, -(MLDSA_ETA + 2), "s1 underflow at [0][1]"},
      {CORRUPT_S1, 0, 1, MLDSA_ETA + 2, "s1 overflow at [0][1]"},
      {CORRUPT_S1, 0, MLDSA_N - 1, -(MLDSA_ETA + 1),
       "s1 underflow at [0][N-1]"},
      {CORRUPT_S1, 0, MLDSA_N - 1, MLDSA_ETA + 1, "s1 overflow at [0][N-1]"},
      {CORRUPT_S1, MLDSA_L - 1, 0, -(MLDSA_ETA + 1),
       "s1 underflow at [L-1][0]"},
      {CORRUPT_S1, MLDSA_L - 1, 0, MLDSA_ETA + 1, "s1 overflow at [L-1][0]"},

      /* Test s2 vector corruptions */
      {CORRUPT_S2, 0, 0, -(MLDSA_ETA + 1), "s2 underflow at [0][0]"},
      {CORRUPT_S2, 0, 0, MLDSA_ETA + 1, "s2 overflow at [0][0]"},
      {CORRUPT_S2, 0, 1, -(MLDSA_ETA + 2), "s2 underflow at [0][1]"},
      {CORRUPT_S2, 0, 1, MLDSA_ETA + 2, "s2 overflow at [0][1]"},
      {CORRUPT_S2, 0, MLDSA_N - 1, -(MLDSA_ETA + 1),
       "s2 underflow at [0][N-1]"},
      {CORRUPT_S2, 0, MLDSA_N - 1, MLDSA_ETA + 1, "s2 overflow at [0][N-1]"},
      {CORRUPT_S2, MLDSA_K - 1, 0, -(MLDSA_ETA + 1),
       "s2 underflow at [K-1][0]"},
      {CORRUPT_S2, MLDSA_K - 1, 0, MLDSA_ETA + 1, "s2 overflow at [K-1][0]"},
  };

  size_t num_test_cases = sizeof(test_cases) / sizeof(test_cases[0]);
  for (size_t num = 0; num < num_test_cases; num++)
  {
    if (test_corrupted_sk(&test_cases[num]))
    {
      printf("ERROR: Test case %zu failed: %s\n", num,
             test_cases[num].description);
      return 1;
    }
  }

  printf("MLDSA_CRYPTO_SECRETKEYBYTES:  %d\n", MLDSA_CRYPTO_SECRETKEYBYTES);
  printf("MLDSA_CRYPTO_PUBLICKEYBYTES:  %d\n", MLDSA_CRYPTO_PUBLICKEYBYTES);
  printf("MLDSA_CRYPTO_BYTES: %d\n", MLDSA_CRYPTO_BYTES);

  return 0;
}
