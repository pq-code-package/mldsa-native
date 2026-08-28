/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Import public mldsa-native API. This also pulls in example_context.h,
 * which mldsa_native_config.h includes for the context parameter type. */
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

/* Size of the region the bump allocator hands out.
 *
 * MLD_TOTAL_ALLOC_{44,65,87} is published by mldsa_native.h precisely for this
 * purpose: it is the maximum accumulated MLD_ALLOC usage across key generation,
 * signing and verification, and it already accounts for the alignment rounding
 * the allocator applies. So this buffer is exactly large enough, and no
 * operation can run out of memory. */
#if MLD_CONFIG_PARAMETER_SET == 44
#define EXAMPLE_ALLOC_SIZE MLD_TOTAL_ALLOC_44
#elif MLD_CONFIG_PARAMETER_SET == 65
#define EXAMPLE_ALLOC_SIZE MLD_TOTAL_ALLOC_65
#else
#define EXAMPLE_ALLOC_SIZE MLD_TOTAL_ALLOC_87
#endif

static EXAMPLE_ALIGN uint8_t alloc_buffer[EXAMPLE_ALLOC_SIZE];

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
static int example_keygen(example_context *context)
{
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];

#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  printf("Generating keypair (randomized)... ");
  CHECK(mldsa_keypair(pk, sk, context) == 0);
  CHECK(memcmp(pk, test_vector_pk, MLDSA_PK_BYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk, MLDSA_SK_BYTES) == 0);
  printf("DONE\n");
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

  printf("Generating keypair (deterministic)... ");
  CHECK(mldsa_keypair_internal(pk, sk, test_vector_rnd, context) == 0);
  CHECK(memcmp(pk, test_vector_pk, MLDSA_PK_BYTES) == 0);
  CHECK(memcmp(sk, test_vector_sk, MLDSA_SK_BYTES) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_KEYPAIR_API */
static int example_keygen(example_context *context)
{
  (void)context;
  printf("Generating keypair... SKIPPED (keygen API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static int example_sign(example_context *context)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES];
  size_t pre_len;

#if !defined(MLD_CONFIG_NO_RANDOMIZED_API)
  printf("Signing message (randomized)... ");
  CHECK(mldsa_signature(sig, (const uint8_t *)TEST_VECTOR_MSG,
                        TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                        TEST_VECTOR_CTX_LEN, test_vector_sk, context) == 0);
  CHECK(memcmp(sig, test_vector_sig, sizeof(test_vector_sig)) == 0);
  printf("DONE\n");
#endif /* !MLD_CONFIG_NO_RANDOMIZED_API */

  printf("Signing message (deterministic)... ");
  /* prepare_domain_separation_prefix does not allocate and takes no context. */
  pre_len = mldsa_prepare_domain_separation_prefix(
      pre, NULL, 0, (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN,
      MLD_PREHASH_NONE);
  CHECK(pre_len != 0);
  CHECK(mldsa_signature_internal(
            sig, (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN, pre,
            pre_len, test_vector_rnd, test_vector_sk, 0, context) == 0);
  CHECK(memcmp(sig, test_vector_sig, sizeof(test_vector_sig)) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_SIGN_API */
static int example_sign(example_context *context)
{
  (void)context;
  printf("Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static int example_verify(example_context *context)
{
  printf("Verifying signature... ");
  CHECK(mldsa_verify(test_vector_sig, (const uint8_t *)TEST_VECTOR_MSG,
                     TEST_VECTOR_MSG_LEN, (const uint8_t *)TEST_VECTOR_CTX,
                     TEST_VECTOR_CTX_LEN, test_vector_pk, context) == 0);
  printf("DONE\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_VERIFY_API */
static int example_verify(example_context *context)
{
  (void)context;
  printf("Verifying signature... SKIPPED (verify API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_VERIFY_API */

int main(void)
{
  int r = 0;
  example_context context;

  printf("ML-DSA-%d, %d byte allocation buffer\n", MLD_CONFIG_PARAMETER_SET,
         (int)EXAMPLE_ALLOC_SIZE);
  example_context_init(&context, alloc_buffer, sizeof(alloc_buffer));

  /* WARNING: Test-only
   * Normally, you would seed a PRNG _once_ with trustworthy entropy and not
   * reseed it afterwards. Here, we reseed before each API call to make each
   * test independent and reproducible even when some API is disabled. */
  randombytes_reset();
  r |= example_keygen(&context);
  CHECK(context.used == 0);
  randombytes_reset();
  r |= example_sign(&context);
  CHECK(context.used == 0);
  r |= example_verify(&context);
  CHECK(context.used == 0);

  return r;
}
