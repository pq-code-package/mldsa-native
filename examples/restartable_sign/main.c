/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <mldsa_native.h>
#include "expected_test_vectors.h"

/* Convenience abbreviations for the secret-key and signature sizes, derived
 * from the configured parameter set. */
#define MLDSA_SK_BYTES MLDSA_SECRETKEYBYTES(MLD_CONFIG_PARAMETER_SET)
#define MLDSA_SIG_BYTES MLDSA_BYTES(MLD_CONFIG_PARAMETER_SET)

/* For testing, we use fixed test-vector randomness (test_vector_rnd) so that we
 * produce the same keys and signatures as the basic example -- and, crucially,
 * the same signature regardless of how the signing work is split across
 * restarts. A real integration must use cryptographic randomness for key
 * generation.
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

/*
 * Signing hooks.
 *
 * This example keeps all restart state in a single global, so the hooks take
 * no context argument (the build leaves MLD_CONFIG_CONTEXT_PARAMETER unset).
 * This is the simplest possible integration and fine for a single-threaded
 * caller that signs one message at a time.
 *
 * For anything more -- concurrent or interleaved signing operations, or state
 * owned by a caller object -- enable MLD_CONFIG_CONTEXT_PARAMETER instead. Each
 * public API function then takes a trailing context argument that is forwarded
 * to the hooks, so the state below moves out of the global and into that
 * context. See test/src/test_sign_hook.c for the context-based variant.
 */

/* The three hooks this integration must provide. mldsa-native calls them from
 * its signing loop; the matching declarations in the configuration file are
 * gated behind MLD_BUILD_INTERNAL, so we repeat them here to define the hooks
 * with only the public API in scope. */
uint16_t mld_sign_hook_resume(void);
int mld_sign_hook_attempt(uint16_t attempt);
void mld_sign_hook_finish(uint16_t attempt);

/* How many rejection-sampling attempts each signing call runs before pausing;
 * set by the driver before each operation. 0 means never pause (one-shot). */
static unsigned attempts_per_call = 0;

/* Attempt from which the next signing call resumes. Advanced by the attempt
 * hook when it pauses, reset to 0 by the finish hook on success. */
static uint16_t resume_attempt = 0;

/* Resume from wherever the previous call paused (0 on a fresh operation). */
uint16_t mld_sign_hook_resume(void) { return resume_attempt; }

/* Called before each attempt. Return non-zero to pause; signing then returns
 * MLD_ERR_SIGNING_PAUSED and the next call resumes from `attempt`. */
int mld_sign_hook_attempt(uint16_t attempt)
{
  if (attempts_per_call != 0 && attempt >= resume_attempt + attempts_per_call)
  {
    resume_attempt = attempt;
    return 1; /* pause before this attempt */
  }
  return 0; /* proceed */
}

/* Called once signing succeeds; reset the resume point for the next operation.
 */
void mld_sign_hook_finish(uint16_t attempt)
{
  (void)attempt;
  resume_attempt = 0;
}

#if !defined(MLD_CONFIG_NO_SIGN_API)
/*
 * Drive one signing operation to completion, pausing every `apc` attempts
 * (0 = one-shot). Repeatedly calls the deterministic signing API with the same
 * (message, sk, rnd); each MLD_ERR_SIGNING_PAUSED just means "call again to
 * continue". Returns the number of restarts (extra calls beyond the first), or
 * -1 on a genuine error.
 */
static int sign_restartable(uint8_t sig[MLDSA_SIG_BYTES], const uint8_t *pre,
                            size_t prelen, const uint8_t *rnd,
                            const uint8_t *sk, unsigned apc)
{
  int restarts = 0;

  /* Start a fresh operation and select the per-call attempt budget. */
  resume_attempt = 0;
  attempts_per_call = apc;

  for (;;)
  {
    int rc = mldsa_signature_internal(sig, (const uint8_t *)TEST_VECTOR_MSG,
                                      TEST_VECTOR_MSG_LEN, pre, prelen, rnd, sk,
                                      0 /* externalmu */);
    if (rc == 0)
    {
      return restarts; /* done */
    }
    if (rc == MLD_ERR_SIGNING_PAUSED)
    {
      restarts++;
      continue; /* resume from resume_attempt */
    }
    fprintf(stderr, "ERROR: signing failed with rc=%d\n", rc);
    return -1;
  }
}
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static int example_sign(const uint8_t sk[MLDSA_SK_BYTES])
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t ref_sig[MLDSA_SIG_BYTES];
  uint8_t pre[TEST_VECTOR_CTX_LEN + 2]; /* prefix string (0, ctxlen, ctx) */
  int restarts;

  /* Prepare pre = (0, ctxlen, ctx) for pure ML-DSA domain separation. */
  pre[0] = 0;
  pre[1] = TEST_VECTOR_CTX_LEN;
  memcpy(pre + 2, TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN);

  /* Single-step: pause after every attempt, so the operation is spread over as
   * many calls as it takes attempts. */
  printf("Signing message (single-step, pausing every attempt)... ");
  restarts = sign_restartable(sig, pre, sizeof(pre), test_vector_rnd, sk, 1);
  CHECK(restarts >= 0);
  printf("DONE after %d restart(s)\n", restarts);

  /* One-shot: never pause, i.e. ordinary uninterrupted signing. */
  printf("Signing message (one-shot, no pausing)... ");
  restarts =
      sign_restartable(ref_sig, pre, sizeof(pre), test_vector_rnd, sk, 0);
  CHECK(restarts == 0);
  printf("DONE\n");

  /* The key property: splitting the work across restarts neither repeats nor
   * skips a rejection-sampling attempt, so both runs produce the very same
   * signature -- and it is the reference test vector. */
  CHECK(memcmp(sig, ref_sig, MLDSA_SIG_BYTES) == 0);
  CHECK(sizeof(test_vector_sig) == MLDSA_SIG_BYTES);
  CHECK(memcmp(sig, test_vector_sig, MLDSA_SIG_BYTES) == 0);
  printf("Single-step and one-shot signatures match the reference vector.\n");
  return 0;
}
#else  /* !MLD_CONFIG_NO_SIGN_API */
static int example_sign(const uint8_t sk[MLDSA_SK_BYTES])
{
  (void)sk;
  printf("Signing message... SKIPPED (sign API disabled)\n");
  return 0;
}
#endif /* MLD_CONFIG_NO_SIGN_API */

int main(void)
{
  printf("ML-DSA-%d Restartable Signing Example\n", MLD_CONFIG_PARAMETER_SET);
  printf("====================================\n\n");

  printf("Message: %s\n", TEST_VECTOR_MSG);
  printf("Context: %s\n\n", TEST_VECTOR_CTX);

  /* Sign with the reference secret key; the example is solely about splitting
   * the signing loop across restarts and reproducing the one-shot signature. */
  if (example_sign(test_vector_sk) != 0)
  {
    return 1;
  }

  printf("\nAll tests passed! Restartable signing works.\n");
  return 0;
}
