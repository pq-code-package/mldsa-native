/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA Comprehensive Functional Test for Cortex-M33
 *
 * Tests: sign/verify, unaligned access, invalid inputs, external mu,
 *        pre-hash, and public key derivation
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "../../../../mldsa/src/sign.h"
#include "../../../../mldsa/src/sys.h"
#include "../../../notrandombytes/notrandombytes.h"

#define FUNCNTESTS 1
#define MLEN 59
#define CTXLEN 1

/*===========================================================================
 * Semihosting I/O
 *===========================================================================*/

static inline void semihost_print(const char *str)
{
  __asm__ volatile("mov r0, #0x04\n mov r1, %0\n bkpt 0xAB\n"
                   :
                   : "r"(str)
                   : "r0", "r1", "memory");
}

static inline void semihost_exit(int code)
{
  __asm__ volatile("mov r0, #0x18\n mov r1, %0\n bkpt 0xAB\n"
                   :
                   : "r"(code)
                   : "r0", "r1", "memory");
}

static int test_failures = 0;

#define CHECK(x)                               \
  do                                           \
  {                                            \
    if (!(x))                                  \
    {                                          \
      semihost_print("ERROR: Check failed\n"); \
      test_failures++;                         \
      return 1;                                \
    }                                          \
  } while (0)

/*===========================================================================
 * Test Functions
 *===========================================================================*/

/* Core sign/verify cycle */
static int test_sign_core(uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
                          uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
                          uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES],
                          uint8_t m[MLEN],
                          uint8_t m2[MLEN + MLDSA_CRYPTO_BYTES],
                          uint8_t ctx[CTXLEN])
{
  size_t smlen, mlen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  randombytes(ctx, CTXLEN);
  randombytes(m, MLEN);
  CHECK(crypto_sign(sm, &smlen, m, MLEN, ctx, CTXLEN, sk) == 0);

  if (crypto_sign_open(m2, &mlen, sm, smlen, ctx, CTXLEN, pk) != 0)
  {
    return 1;
  }
  if (memcmp(m, m2, MLEN) != 0)
  {
    return 1;
  }
  if (smlen != MLEN + MLDSA_CRYPTO_BYTES || mlen != MLEN)
  {
    return 1;
  }

  return 0;
}

static int test_sign(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES], sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES], m[MLEN], m2[MLEN + MLDSA_CRYPTO_BYTES],
      ctx[CTXLEN];
  return test_sign_core(pk, sk, sm, m, m2, ctx);
}

/* Unaligned memory access test */
static int test_sign_unaligned(void)
{
  MLD_ALIGN uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES + 1];
  MLD_ALIGN uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES + 1];
  MLD_ALIGN uint8_t sm[MLEN + MLDSA_CRYPTO_BYTES + 1];
  MLD_ALIGN uint8_t m[MLEN + 1], m2[MLEN + MLDSA_CRYPTO_BYTES + 1],
      ctx[CTXLEN + 1];
  return test_sign_core(pk + 1, sk + 1, sm + 1, m + 1, m2 + 1, ctx + 1);
}

/* External mu signing */
static int test_sign_extmu(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES], sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES], mu[MLDSA_CRHBYTES];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  randombytes(mu, MLDSA_CRHBYTES);
  CHECK(crypto_sign_signature_extmu(sig, &siglen, mu, sk) == 0);
  CHECK(crypto_sign_verify_extmu(sig, siglen, mu, pk) == 0);
  return 0;
}

/* Pre-hash signing (SHAKE256) */
static int test_sign_pre_hash(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES], sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES], m[MLEN], ctx[CTXLEN], rnd[MLDSA_RNDBYTES];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  randombytes(ctx, CTXLEN);
  randombytes(m, MLEN);
  randombytes(rnd, MLDSA_RNDBYTES);
  CHECK(crypto_sign_signature_pre_hash_shake256(sig, &siglen, m, MLEN, ctx,
                                                CTXLEN, rnd, sk) == 0);
  CHECK(crypto_sign_verify_pre_hash_shake256(sig, siglen, m, MLEN, ctx, CTXLEN,
                                             pk) == 0);
  return 0;
}

/* Public key derivation from secret key */
static int test_pk_from_sk(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
      pk_derived[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES], sk_bad[MLDSA_CRYPTO_SECRETKEYBYTES];

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(crypto_sign_pk_from_sk(pk_derived, sk) == 0);
  if (memcmp(pk, pk_derived, MLDSA_CRYPTO_PUBLICKEYBYTES) != 0)
  {
    return 1;
  }

  /* Corrupted SK should fail */
  memcpy(sk_bad, sk, MLDSA_CRYPTO_SECRETKEYBYTES);
  sk_bad[MLDSA_SEEDBYTES + MLDSA_TRBYTES + MLDSA_SEEDBYTES + 10] ^= 1;
  if (crypto_sign_pk_from_sk(pk_derived, sk_bad) != -1)
  {
    return 1;
  }

  return 0;
}

/* Verification with wrong public key (should fail) */
static int test_wrong_pk(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
      pk_wrong[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
      sk_wrong[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES], m[MLEN], ctx[CTXLEN];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  CHECK(crypto_sign_keypair(pk_wrong, sk_wrong) == 0);
  randombytes(ctx, CTXLEN);
  randombytes(m, MLEN);
  CHECK(crypto_sign_signature(sig, &siglen, m, MLEN, ctx, CTXLEN, sk) == 0);
  return (crypto_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk_wrong) == 0)
             ? 1
             : 0;
}

/* Corrupted signature (should fail) */
static int test_wrong_sig(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES], sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES], m[MLEN], ctx[CTXLEN];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  randombytes(ctx, CTXLEN);
  randombytes(m, MLEN);
  CHECK(crypto_sign_signature(sig, &siglen, m, MLEN, ctx, CTXLEN, sk) == 0);
  sig[0] ^= 1;
  return (crypto_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk) == 0) ? 1
                                                                          : 0;
}

/* Wrong context (should fail) */
static int test_wrong_ctx(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES], sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES], m[MLEN], ctx[CTXLEN], ctx_wrong[CTXLEN];
  size_t siglen;

  CHECK(crypto_sign_keypair(pk, sk) == 0);
  randombytes(ctx, CTXLEN);
  randombytes(m, MLEN);
  memcpy(ctx_wrong, ctx, CTXLEN);
  ctx_wrong[0] ^= 1;
  CHECK(crypto_sign_signature(sig, &siglen, m, MLEN, ctx, CTXLEN, sk) == 0);
  return (crypto_sign_verify(sig, siglen, m, MLEN, ctx_wrong, CTXLEN, pk) == 0)
             ? 1
             : 0;
}

/*===========================================================================
 * Main
 *===========================================================================*/

static void uint_to_str(uint32_t val, char *buf)
{
  if (val == 0)
  {
    buf[0] = '0';
    buf[1] = '\0';
    return;
  }
  char tmp[12];
  int i = 0;
  while (val > 0)
  {
    tmp[i++] = '0' + (val % 10);
    val /= 10;
  }
  int j = 0;
  while (i > 0)
  {
    buf[j++] = tmp[--i];
  }
  buf[j] = '\0';
}

int main(void)
{
  char buf[32];

  semihost_print("\n=== ML-DSA Functional Test ===\n");
  semihost_print("Platform: Cortex-M33 (QEMU mps2-an521)\n");
  semihost_print("Parameter Set: ML-DSA-");
#if MLD_CONFIG_PARAMETER_SET == 44
  semihost_print("44\n\n");
#elif MLD_CONFIG_PARAMETER_SET == 65
  semihost_print("65\n\n");
#elif MLD_CONFIG_PARAMETER_SET == 87
  semihost_print("87\n\n");
#else
  semihost_print("Unknown\n\n");
#endif

  randombytes_reset();

  for (unsigned i = 0; i < FUNCNTESTS; i++)
  {
    struct
    {
      const char *name;
      int (*fn)(void);
    } tests[] = {
        {"Basic sign/verify", test_sign},
        {"Unaligned memory", test_sign_unaligned},
        {"Wrong public key", test_wrong_pk},
        {"Wrong signature", test_wrong_sig},
        {"Wrong context", test_wrong_ctx},
        {"External mu", test_sign_extmu},
        {"Pre-hash", test_sign_pre_hash},
        {"PK from SK", test_pk_from_sk},
    };

    for (unsigned t = 0; t < sizeof(tests) / sizeof(tests[0]); t++)
    {
      semihost_print("  - ");
      semihost_print(tests[t].name);
      semihost_print("... ");
      if (tests[t].fn())
      {
        semihost_print("FAILED\n");
        semihost_exit(1);
      }
      semihost_print("PASSED\n");
    }
  }

  semihost_print("\nKey sizes: SK=");
  uint_to_str(MLDSA_CRYPTO_SECRETKEYBYTES, buf);
  semihost_print(buf);
  semihost_print(" PK=");
  uint_to_str(MLDSA_CRYPTO_PUBLICKEYBYTES, buf);
  semihost_print(buf);
  semihost_print(" SIG=");
  uint_to_str(MLDSA_CRYPTO_BYTES, buf);
  semihost_print(buf);
  semihost_print("\n\n=== ALL TESTS PASSED ===\n");

  semihost_exit(0);
  return 0;
}
