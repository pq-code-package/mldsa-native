/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [FIPS204]
 *   FIPS 204 Module-Lattice-Based Digital Signature Standard
 *   National Institute of Standards and Technology
 *   https://csrc.nist.gov/pubs/fips/204/final
 *
 * - [FIPS204_UPDATES]
 *   FIPS 204 Potential Updates (Errata)
 *   National Institute of Standards and Technology
 *   https://csrc.nist.gov/files/pubs/fips/204/final/docs/fips-204-potential-updates.xlsx
 */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Expose the deterministic internal signing API and struct test_sign_hook_ctx
 * (declared by the custom config in MLD_CONFIG_CONTEXT_PARAMETER_TYPE). */
#define MLD_BUILD_INTERNAL
#include "../../mldsa/mldsa_native.h"
#include "../notrandombytes/notrandombytes.h"
#include "expected_test_vectors.h"

#ifndef NTESTS
#define NTESTS 1000
#endif

/* Number of randomized iterations in test_restartable. Overridable from the
 * build for longer/shorter runs. */
#ifndef MLD_SIGN_HOOK_ITERATIONS
/* Even if NTESTS < 10, we want to run the test at least once; so round up. */
#define MLD_SIGN_HOOK_ITERATIONS (((NTESTS) + 9) / 10)
#endif

/* Number of one-shot signing operations in test_distribution. Overridable from
 * the build; bump this up for a more accurate attempts distribution. Kept
 * independent of NTESTS so the distribution check has a fixed sample budget
 * (see MLD_SIGN_HOOK_MIN_CHECK_N for the resulting tolerance and confidence).
 *
 * Targets where signing is expensive (e.g. full-system emulation) override this
 * down via -DMLD_SIGN_HOOK_DIST_ITERATIONS. */
#ifndef MLD_SIGN_HOOK_DIST_ITERATIONS
#define MLD_SIGN_HOOK_DIST_ITERATIONS 2000
#endif

/* Expected mean number of signing attempts per signature, in thousandths (i.e.
 * the true mean times 1000, kept integer to avoid floating point). ML-DSA
 * signing is rejection sampling, so this is the mean 1/p of a geometric
 * distribution and is parameter-set dependent.
 *
 * These values are obtained empirically: the mean over 3 x 100,000,000
 * signatures, each with a fresh key (so the estimate is key-averaged, not tied
 * to one key), which pins the mean to +-0.001; an independent BoringSSL
 * measurement agrees to within 0.15%.
 *
 * They match the 4.36 / 5.14 / 3.91 that @[FIPS204_UPDATES] gives for
 * @[FIPS204, Table 1]. They exceed the published 4.25 / 5.10 / 3.85, which
 * model only the first-stage rejection (the ||z|| and ||r0|| low-bits checks)
 * and omit the second-stage @[FIPS204, Algorithm 7, line 28] checks (the
 * ||ct0|| norm and the hint weight <= omega). */
#if MLD_CONFIG_PARAMETER_SET == 44
#define MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 4361
#elif MLD_CONFIG_PARAMETER_SET == 65
#define MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 5138
#elif MLD_CONFIG_PARAMETER_SET == 87
#define MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 3906
#endif

/* Signature size for the configured parameter set. */
#define MLDSA_SIG_BYTES MLDSA_BYTES(MLD_CONFIG_PARAMETER_SET)

/* The distribution test only checks the measured attempts/signature ratio
 * against the expected mean once it has enough samples for the check to be
 * meaningful.
 *
 * At N = 2000, the relative standard error is ~2% (widest level), so the
 * +-10% (100 per-mille) tolerance is a ~5-sigma band: a healthy implementation
 * exceeds it (a spurious failure) with probability ~10^{-6} per level.
 *
 * Dedicated runs can raise N and lower MLD_SIGN_HOOK_RATIO_TOL_PERMILLE. */
#define MLD_SIGN_HOOK_MIN_CHECK_N 2000
/* Relative tolerance in per mille. Overridable from the build: dedicated
 * high-sample runs tighten it (see above). */
#ifndef MLD_SIGN_HOOK_RATIO_TOL_PERMILLE
#define MLD_SIGN_HOOK_RATIO_TOL_PERMILLE 100
#endif

/* The signing hooks and this whole test exercise the internal signing API, so
 * there is nothing to test when signing is disabled. */
#if !defined(MLD_CONFIG_NO_SIGN_API)

#include "decode_hex.h"

/*
 * This test exercises the restartable-signing hooks enabled by
 * MLD_CONFIG_SIGN_HOOK_RESUME, MLD_CONFIG_SIGN_HOOK_ATTEMPT and
 * MLD_CONFIG_SIGN_HOOK_FINISH.
 *
 * The custom config (test/configs/test_sign_hook_config.h) only enables the
 * hooks and forward-declares struct test_sign_hook_ctx; the context type and
 * the three hook implementations live here. The attempt hook pauses signing --
 * returning MLD_ERR_SIGNING_PAUSED -- after `attempts_per_call` uninterrupted
 * attempts, recording the resume point in the context; the resume hook
 * continues from there on the next call. attempts_per_call == -1 disables
 * pausing (one-shot signing).
 */

/* Histogram size. Bucket i (0-based) counts signatures that took i+1 attempts;
 * the last bucket also counts every signature of >= MLD_SIGN_HOOK_HIST_N
 * attempts. */
#ifndef MLD_SIGN_HOOK_HIST_N
#define MLD_SIGN_HOOK_HIST_N 30
#endif

/* Statistics accumulated across all signing operations that share a context,
 * maintained by the attempt and finish hooks. */
struct test_sign_hook_stats
{
  uint64_t signatures; /* completed signatures (finish-hook calls) */
  uint64_t attempts;   /* attempts actually performed */
  uint64_t histogram[MLD_SIGN_HOOK_HIST_N]; /* attempts per signature */
};

/* Per-operation state for the signing hooks, carried via the context parameter.
 * The test sets attempts_per_call / record_stats before each signing operation;
 * the hooks maintain the rest. */
struct test_sign_hook_ctx
{
  int attempts_per_call; /* uninterrupted attempts per call before pausing;
                          * -1 = never pause (one-shot) */
  int paused_attempt;    /* attempt the next call resumes from; reset to 0 */
  int final_attempt;     /* attempt at which signing succeeded; -1 until
                          * finish runs */
  int record_stats;      /* if nonzero, this operation contributes to `stats`;
                          * lets the test count each logical signature once
                          * despite re-signing */
  struct test_sign_hook_stats stats; /* run-wide statistics */
};

/*
 * Signing hooks (declared by the config, defined here). Resume returns the
 * attempt to continue from; attempt pauses after attempts_per_call
 * uninterrupted attempts and otherwise counts the attempt; finish records the
 * completed signature.
 */
uint16_t mld_sign_hook_resume(struct test_sign_hook_ctx *context)
{
  /* Resume from where the previous call paused (0 on a fresh op). */
  return (uint16_t)context->paused_attempt;
}

int mld_sign_hook_attempt(uint16_t attempt, struct test_sign_hook_ctx *context)
{
  /* Having resumed at paused_attempt, run attempts_per_call attempts
   * uninterrupted, then pause: when `attempt` reaches paused_attempt +
   * attempts_per_call, record it as the new resume point and pause. -1 means
   * never pause. */
  if (context->attempts_per_call >= 0 &&
      (int)attempt == context->paused_attempt + context->attempts_per_call)
  {
    context->paused_attempt = (int)attempt;
    return 1; /* pause before this attempt */
  }
  /* Count only attempts that actually proceed (and only when this operation
   * opted in), so the statistics are independent of how the work is split
   * across calls. */
  if (context->record_stats)
  {
    context->stats.attempts++;
  }
  return 0; /* proceed */
}

void mld_sign_hook_finish(uint16_t attempt, struct test_sign_hook_ctx *context)
{
  if (context->record_stats)
  {
    /* A signature that succeeds at attempt index `attempt` took attempt + 1
     * attempts; bucket it (last bucket is saturating). */
    int n = (int)attempt + 1;
    int bucket =
        (n < MLD_SIGN_HOOK_HIST_N) ? (n - 1) : (MLD_SIGN_HOOK_HIST_N - 1);
    context->stats.signatures++;
    context->stats.histogram[bucket]++;
  }
  /* Record the successful attempt and reset the resume point so a subsequent
   * operation starts fresh. */
  context->final_attempt = (int)attempt;
  context->paused_attempt = 0;
}

#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    if (!(x))                                                 \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      return 1;                                               \
    }                                                         \
  } while (0)

/*
 * Accessors for struct test_sign_hook_ctx. The test only touches the context
 * through these, so its layout can be restructured without changing the tests.
 */

/* Initialize a fresh context: zero statistics, no pending operation. */
static void test_sign_ctx_init(struct test_sign_hook_ctx *ctx)
{
  memset(ctx, 0, sizeof(*ctx));
}

/* Begin a signing operation: pause every `attempts_per_call` attempts (-1 =
 * never), and record statistics for this operation iff `record_stats`. A value
 * of 0 would ask the attempt hook to pause before the very first attempt with
 * no progress -- livelock -- so we clamp it up to 1. */
static void test_sign_ctx_begin_op(struct test_sign_hook_ctx *ctx,
                                   int attempts_per_call, int record_stats)
{
  if (attempts_per_call == 0)
  {
    attempts_per_call = 1;
  }
  ctx->attempts_per_call = attempts_per_call;
  ctx->paused_attempt = 0;
  ctx->final_attempt = -1;
  ctx->record_stats = record_stats;
}

static uint64_t test_sign_ctx_signatures(const struct test_sign_hook_ctx *ctx)
{
  return ctx->stats.signatures;
}
static uint64_t test_sign_ctx_attempts(const struct test_sign_hook_ctx *ctx)
{
  return ctx->stats.attempts;
}
static uint64_t test_sign_ctx_histogram(const struct test_sign_hook_ctx *ctx,
                                        int i)
{
  return ctx->stats.histogram[i];
}

/*
 * Core helper: sign (m, pre) with secret key `sk` and randomness `rnd`, pausing
 * every `attempts_per_call` attempts (-1 = never pause), looping over the
 * paused calls until the signature completes. The completed (fixed-size)
 * signature is written to sig and -- if `expected` is non-NULL -- checked to
 * equal expected/MLDSA_SIG_BYTES.
 *
 * `ctx` is the shared hook context: its statistics accumulate across calls, so
 * the same context is threaded through every test. Statistics are recorded for
 * this operation only when `record_stats` is nonzero, so each logical signature
 * is counted once even though the test re-signs it several ways.
 *
 * Returns 0 on success, 1 on a signing error or a mismatch against `expected`.
 */
static int sign_and_compare(struct test_sign_hook_ctx *ctx,
                            int attempts_per_call, int record_stats,
                            uint8_t sig[MLDSA_SIG_BYTES],
                            const uint8_t *expected, const uint8_t *m,
                            size_t mlen, const uint8_t *pre, size_t prelen,
                            const uint8_t *rnd, const uint8_t *sk)
{
  int rc;

  test_sign_ctx_begin_op(ctx, attempts_per_call, record_stats);

  for (;;)
  {
    rc = mld_signature_internal(sig, m, mlen, pre, prelen, rnd, sk,
                                0 /* externalmu */, ctx);
    if (rc == 0)
    {
      break;
    }
    if (rc == MLD_ERR_SIGNING_PAUSED)
    {
      continue; /* resume from the recorded attempt */
    }
    fprintf(stderr, "ERROR: signing failed with rc=%d\n", rc);
    return 1;
  }

  if (expected != NULL && memcmp(sig, expected, MLDSA_SIG_BYTES) != 0)
  {
    fprintf(stderr, "ERROR: signature mismatch (attempts_per_call=%d)\n",
            attempts_per_call);
    return 1;
  }

  return 0;
}

/*
 * Build the pure-ML-DSA domain-separation prefix for context string
 * `ctx`/`ctxlen` using mldsa-native's own API. Returns the prefix length, or 0
 * on error.
 */
static size_t make_pre(uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES],
                       const uint8_t *ctx, size_t ctxlen)
{
  return mld_prepare_domain_separation_prefix(pre, NULL, 0, ctx, ctxlen,
                                              MLD_PREHASH_NONE);
}

/*
 * Smoke test: run the core helper against the known test vector. Signing the
 * test-vector message with the test-vector key and randomness must reproduce
 * the recorded signature, both one-shot and single-step.
 */
static int test_known_answer(struct test_sign_hook_ctx *ctx)
{
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES];
  size_t prelen =
      make_pre(pre, (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN);

  CHECK(prelen != 0);

  /* Statistics are gathered only by the distribution test, so neither run here
   * records. */
  CHECK(sign_and_compare(ctx, -1, 0 /* don't record */, sig, test_vector_sig,
                         (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN,
                         pre, prelen, test_vector_rnd, test_vector_sk) == 0);
  CHECK(sign_and_compare(ctx, 1, 0 /* don't record */, sig, test_vector_sig,
                         (const uint8_t *)TEST_VECTOR_MSG, TEST_VECTOR_MSG_LEN,
                         pre, prelen, test_vector_rnd, test_vector_sk) == 0);

  printf("Known-answer smoke test PASSED.\n");
  return 0;
}

/*
 * Restartable-signing equivalence test. Uses the fixed test-vector message and
 * key; for each of `iterations` rounds, pick fresh signing randomness, produce
 * the signature one-shot (the reference), then re-sign with the same randomness
 * and check that we obtain the same signature both (a) single-step (one attempt
 * per call) and (b) with a random number of attempts per call.
 */
static int test_restartable(struct test_sign_hook_ctx *ctx, int iterations)
{
  uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES];
  size_t prelen =
      make_pre(pre, (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN);
  int i;

  CHECK(prelen != 0);

  for (i = 0; i < iterations; i++)
  {
    uint8_t rnd[MLDSA_RNDBYTES];
    uint8_t ref_sig[MLDSA_SIG_BYTES];
    uint8_t sig[MLDSA_SIG_BYTES];
    uint8_t rand_byte;
    int rand_apc;

    /* Fresh signing randomness, chosen at runtime. The reference and the
     * re-signs below all use the same message, key and randomness. */
    CHECK(randombytes(rnd, sizeof(rnd)) == 0);
    CHECK(randombytes(&rand_byte, 1) == 0);
    /* Random attempts-per-call in [1, 4], biased toward 1 so that most
     * iterations actually exercise multiple pause/resume cycles. The mean
     * number of attempts per signature is ~4-5, so a uniform draw over [1, 4]
     * would leave apc=3, 4 mostly completing in one call and collapsing to
     * the one-shot baseline. Distribution: P(1)=1/2, P(2)=1/4, P(3)=P(4)=1/8.
     */
    {
      unsigned int b = (unsigned int)rand_byte % 8u;
      if (b < 4u)
      {
        rand_apc = 1;
      }
      else if (b < 6u)
      {
        rand_apc = 2;
      }
      else if (b < 7u)
      {
        rand_apc = 3;
      }
      else
      {
        rand_apc = 4;
      }
    }

    /* Reference signature, produced one-shot. Statistics are gathered only by
     * the distribution test, so this does not record. */
    CHECK(sign_and_compare(ctx, -1, 0 /* don't record */, ref_sig, NULL,
                           (const uint8_t *)TEST_VECTOR_MSG,
                           TEST_VECTOR_MSG_LEN, pre, prelen, rnd,
                           test_vector_sk) == 0);

    /* (a) Single-step: pause after every attempt. */
    CHECK(sign_and_compare(ctx, 1, 0 /* don't record */, sig, ref_sig,
                           (const uint8_t *)TEST_VECTOR_MSG,
                           TEST_VECTOR_MSG_LEN, pre, prelen, rnd,
                           test_vector_sk) == 0);

    /* (b) Random number of attempts per call. */
    CHECK(sign_and_compare(ctx, rand_apc, 0 /* don't record */, sig, ref_sig,
                           (const uint8_t *)TEST_VECTOR_MSG,
                           TEST_VECTOR_MSG_LEN, pre, prelen, rnd,
                           test_vector_sk) == 0);
  }

  printf("Restartable signing equivalence test PASSED (%d iteration(s)).\n",
         iterations);
  return 0;
}

/*
 * Distribution test: run `iterations` uninterrupted (one-shot) signing
 * operations, each with a fresh key and fresh signing randomness, recording
 * statistics for every one. Drawing a new key each iteration makes the measured
 * mean an estimate of the key-averaged expected attempts per signature (the
 * rejection probability is mildly key-dependent via the r0- and hint-checks),
 * not a single-key conditional mean. Run with a large iteration count for an
 * accurate picture.
 *
 * This is the only test that generates keys, so it is compiled out under
 * MLD_CONFIG_NO_KEYPAIR_API; the other two use the fixed test-vector key.
 */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static int test_distribution(struct test_sign_hook_ctx *ctx, int iterations)
{
  uint8_t pre[MLD_DOMAIN_SEPARATION_MAX_BYTES];
  size_t prelen =
      make_pre(pre, (const uint8_t *)TEST_VECTOR_CTX, TEST_VECTOR_CTX_LEN);
  int i;

  CHECK(prelen != 0);

  for (i = 0; i < iterations; i++)
  {
    uint8_t kgseed[MLDSA_SEEDBYTES];
    uint8_t rnd[MLDSA_RNDBYTES];
    uint8_t pk[MLDSA_PUBLICKEYBYTES(MLD_CONFIG_PARAMETER_SET)];
    uint8_t sk[MLDSA_SECRETKEYBYTES(MLD_CONFIG_PARAMETER_SET)];
    uint8_t sig[MLDSA_SIG_BYTES];

    /* Fresh key and fresh signing randomness each iteration. keypair_internal
     * takes the context parameter (MLD_CONFIG_CONTEXT_PARAMETER is set) but
     * does not invoke the signing hooks, so passing `ctx` here is inert. */
    CHECK(randombytes(kgseed, sizeof(kgseed)) == 0);
    CHECK(mld_keypair_internal(pk, sk, kgseed, ctx) == 0);
    CHECK(randombytes(rnd, sizeof(rnd)) == 0);

    CHECK(sign_and_compare(ctx, -1, 1 /* record */, sig, NULL,
                           (const uint8_t *)TEST_VECTOR_MSG,
                           TEST_VECTOR_MSG_LEN, pre, prelen, rnd, sk) == 0);
  }

  {
    /* Measured attempts/signature ratio, in thousandths (integer), against the
     * expected geometric mean; both shown to three decimals. */
    uint64_t a = test_sign_ctx_attempts(ctx);
    uint64_t s = test_sign_ctx_signatures(ctx);
    uint64_t ratio_x1000 = (s != 0) ? (1000u * a + s / 2) / s : 0;
    printf("  Measured attempts/signature: %llu.%03llu (expected %d.%03d)\n",
           (unsigned long long)(ratio_x1000 / 1000),
           (unsigned long long)(ratio_x1000 % 1000),
           MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 / 1000,
           MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 % 1000);

    /* With enough samples, check that ratio against the expected mean. All
     * integer: compare 1000*attempts against EXPECTED_RATIO_X1000*signatures,
     * allowing a +-TOL_PERMILLE per-mille relative band. */
    if (iterations >= MLD_SIGN_HOOK_MIN_CHECK_N)
    {
      uint64_t lhs = 1000u * a;
      uint64_t mid = (uint64_t)MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 * s;
      uint64_t tol = (uint64_t)MLD_SIGN_HOOK_RATIO_TOL_PERMILLE * mid / 1000u;
      uint64_t diff = (lhs > mid) ? (lhs - mid) : (mid - lhs);
      if (diff > tol)
      {
        int exp_int = MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 / 1000;
        int exp_frac = MLD_SIGN_HOOK_EXPECTED_RATIO_X1000 % 1000;
        int tol_int = MLD_SIGN_HOOK_RATIO_TOL_PERMILLE / 10;
        int tol_frac = MLD_SIGN_HOOK_RATIO_TOL_PERMILLE % 10;
        /* Report the measured value on stderr too: on failure the harness
         * surfaces stderr, not stdout, so include it here to make the failure
         * diagnosable (and reproducible via the printed PRNG seed). */
        fprintf(stderr,
                "ERROR: attempts/signature ratio out of range: measured "
                "%llu.%03llu, expected %d.%03d +- %d.%d%%\n",
                (unsigned long long)(ratio_x1000 / 1000),
                (unsigned long long)(ratio_x1000 % 1000), exp_int, exp_frac,
                tol_int, tol_frac);
        return 1;
      }
    }
  }

  printf("Distribution test PASSED (%d signature(s)).\n", iterations);
  return 0;
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

/* Print the run-wide statistics accumulated in the shared context. The
 * histogram is shown both numerically and as a bar chart, where each bar is
 * `*` repeated round(100 * count / signatures) times (i.e. percent of all
 * signatures that took that many attempts). */
static void print_stats(const struct test_sign_hook_ctx *ctx)
{
  uint64_t total = test_sign_ctx_signatures(ctx);
  int i;
  printf("\nSigning statistics:\n");
  printf("  Signatures: %llu\n", (unsigned long long)total);
  printf("  Attempts:   %llu\n",
         (unsigned long long)test_sign_ctx_attempts(ctx));
  printf("  Attempts-per-signature histogram (bar = %% of signatures):\n");
  for (i = 0; i < MLD_SIGN_HOOK_HIST_N; i++)
  {
    uint64_t count = test_sign_ctx_histogram(ctx, i);
    const char *rel = (i == MLD_SIGN_HOOK_HIST_N - 1) ? ">=" : "  ";
    /* Bar length: percent of all signatures, rounded to nearest integer. */
    int bar = (total != 0) ? (int)((100 * count + total / 2) / total) : 0;
    int j;
    printf("    [%s%2d|%6llu]: ", rel, i + 1, (unsigned long long)count);
    for (j = 0; j < bar; j++)
    {
      printf("*");
    }
    printf("\n");
  }
}

/* Bytes of PRNG seed accepted on the command line (argv[1] = "seed=HEX"). */
#define MLD_SIGN_HOOK_SEED_BYTES 32

#if defined(main)
int main(int argc, char *argv[]);
#endif
int main(int argc, char *argv[])
{
  int r = 0;
  /* A single context shared across all tests, so the statistics maintained by
   * the hooks accumulate over the entire run. */
  struct test_sign_hook_ctx ctx;
  test_sign_ctx_init(&ctx);

  /* Optional argv[1] = "seed=HEX": a hex seed for the (testing-only) PRNG,
   * printed so a run is reproducible by re-passing it. Absent, the default
   * pi-digit seed keeps the run deterministic. */
  if (argc > 1)
  {
    unsigned char *seed = decode_hex("seed", MLD_SIGN_HOOK_SEED_BYTES, argv[1]);
    int i;
    if (seed == NULL)
    {
      return 1; /* decode_hex already printed a usage message */
    }
    randombytes_seed(seed, MLD_SIGN_HOOK_SEED_BYTES);
    printf("PRNG seed (hex): ");
    for (i = 0; i < MLD_SIGN_HOOK_SEED_BYTES; i++)
    {
      printf("%02x", seed[i]);
    }
    printf("\n");
  }
  else
  {
    printf("PRNG seed: default (deterministic); pass seed=HEX to randomize\n");
  }

  r |= test_known_answer(&ctx);
  r |= test_restartable(&ctx, MLD_SIGN_HOOK_ITERATIONS);
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  r |= test_distribution(&ctx, MLD_SIGN_HOOK_DIST_ITERATIONS);
#endif

  if (r)
  {
    return 1;
  }

  print_stats(&ctx);

  printf("\nAll good! Restartable signing matches one-shot signing.\n");
  return 0;
}

#else /* !MLD_CONFIG_NO_SIGN_API */

#if defined(main)
int main(void);
#endif
int main(void)
{
  printf("Signing API disabled; nothing to test.\n");
  return 0;
}

#endif /* MLD_CONFIG_NO_SIGN_API */
