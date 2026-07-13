/*
 * Copyright (c) The mldsa-native project authors
 * Copyright (c) The mlkem-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <inttypes.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "src/common.h"

#include "hal.h"
#include "mldsa_native.h"
#include "src/randombytes.h"

#include "../src/test_namespace.h"

#ifndef MLD_BENCHMARK_NWARMUP
#define MLD_BENCHMARK_NWARMUP 3
#endif
#ifndef MLD_BENCHMARK_NITERATIONS
#define MLD_BENCHMARK_NITERATIONS 5
#endif
#ifndef MLD_BENCHMARK_NTESTS
#define MLD_BENCHMARK_NTESTS 1000
#endif
#define MLEN 59
#define CTXLEN 1

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

static int cmp_uint64_t(const void *a, const void *b)
{
  const uint64_t va = *((const uint64_t *)a);
  const uint64_t vb = *((const uint64_t *)b);

  /* Avoid subtracting uint64_t values: qsort only needs the sign, and the
   * difference may exceed int range after long benchmark runs. */
  return (va > vb) - (va < vb);
}

static void print_avg(const char *txt, uint64_t cyc[MLD_BENCHMARK_NTESTS])
{
  uint64_t avg = 0;
  int i;
  for (i = 0; i < MLD_BENCHMARK_NTESTS; i++)
  {
    avg += cyc[i];
  }
  avg /= (MLD_BENCHMARK_NTESTS * MLD_BENCHMARK_NITERATIONS);
  printf("%10s cycles (avg) = %" PRIu64 "\n", txt, avg);
}


static int percentiles[] = {1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 99};

static void print_percentile_legend(void)
{
  unsigned i;
  printf("%21s", "percentile");
  for (i = 0; i < sizeof(percentiles) / sizeof(percentiles[0]); i++)
  {
    printf("%12d", percentiles[i]);
  }
  printf("\n");
}

static void print_percentiles(const char *txt,
                              uint64_t cyc[MLD_BENCHMARK_NTESTS])
{
  unsigned i;
  printf("%10s percentiles:", txt);
  for (i = 0; i < sizeof(percentiles) / sizeof(percentiles[0]); i++)
  {
    printf("%12" PRIu64, (cyc)[MLD_BENCHMARK_NTESTS * percentiles[i] / 100] /
                             MLD_BENCHMARK_NITERATIONS);
  }
  printf("\n");
}

static int bench(void)
{
  unsigned i;

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  uint8_t pk[MLDSA_PK_BYTES];
  uint8_t sk[MLDSA_SK_BYTES];
  unsigned char kg_rand[MLDSA_SEEDBYTES];
  uint64_t cycles_kg[MLD_BENCHMARK_NTESTS];
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
  uint8_t sig[MLDSA_SIG_BYTES];
  uint8_t m[MLEN];
  uint8_t ctx[CTXLEN];
  unsigned char sig_rand[MLDSA_SEEDBYTES];
  size_t siglen;
  unsigned char pre[CTXLEN + 2];
  uint64_t cycles_sign[MLD_BENCHMARK_NTESTS];
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
  uint64_t cycles_verify[MLD_BENCHMARK_NTESTS];
#endif

  for (i = 0; i < MLD_BENCHMARK_NTESTS; i++)
  {
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
    {
      unsigned j;
      uint64_t t0, t1;
      int ret = 0;
      CHECK(mld_randombytes(kg_rand, sizeof(kg_rand)) == 0);

      /* Key-pair generation */
      for (j = 0; j < MLD_BENCHMARK_NWARMUP; j++)
      {
        ret |= mld_sign_keypair_internal(pk, sk, kg_rand);
      }

      t0 = get_cyclecounter();
      for (j = 0; j < MLD_BENCHMARK_NITERATIONS; j++)
      {
        ret |= mld_sign_keypair_internal(pk, sk, kg_rand);
      }
      t1 = get_cyclecounter();
      cycles_kg[i] = t1 - t0;
      CHECK(ret == 0);
    }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
    {
      unsigned j;
      uint64_t t0, t1;
      int ret = 0;
      /* Signing */
      CHECK(mld_randombytes(sig_rand, sizeof(sig_rand)) == 0);
      CHECK(mld_randombytes(ctx, CTXLEN) == 0);
      CHECK(mld_randombytes(m, MLEN) == 0);

      pre[0] = 0;
      pre[1] = CTXLEN;
      memcpy(pre + 2, ctx, CTXLEN);

      for (j = 0; j < MLD_BENCHMARK_NWARMUP; j++)
      {
        ret |= mld_sign_signature_internal(sig, &siglen, m, MLEN, pre,
                                           CTXLEN + 2, sig_rand, sk, 0);
      }
      t0 = get_cyclecounter();
      for (j = 0; j < MLD_BENCHMARK_NITERATIONS; j++)
      {
        ret |= mld_sign_signature_internal(sig, &siglen, m, MLEN, pre,
                                           CTXLEN + 2, sig_rand, sk, 0);
      }
      t1 = get_cyclecounter();
      cycles_sign[i] = t1 - t0;
      CHECK(ret == 0);
    }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
    {
      unsigned j;
      uint64_t t0, t1;
      int ret = 0;
      /* Verification */
      for (j = 0; j < MLD_BENCHMARK_NWARMUP; j++)
      {
        ret |= mld_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk);
      }
      t0 = get_cyclecounter();
      for (j = 0; j < MLD_BENCHMARK_NITERATIONS; j++)
      {
        ret |= mld_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk);
      }
      t1 = get_cyclecounter();
      cycles_verify[i] = t1 - t0;
      CHECK(ret == 0);
    }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API && \
          !MLD_CONFIG_NO_VERIFY_API */
  }

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  print_avg("keypair", cycles_kg);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
  print_avg("sign", cycles_sign);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
  print_avg("verify", cycles_verify);
#endif

  printf("\n");

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  qsort(cycles_kg, MLD_BENCHMARK_NTESTS, sizeof(uint64_t), cmp_uint64_t);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
  qsort(cycles_sign, MLD_BENCHMARK_NTESTS, sizeof(uint64_t), cmp_uint64_t);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
  qsort(cycles_verify, MLD_BENCHMARK_NTESTS, sizeof(uint64_t), cmp_uint64_t);
#endif

  print_percentile_legend();

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  print_percentiles("keypair", cycles_kg);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
  print_percentiles("sign", cycles_sign);
#endif
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
  print_percentiles("verify", cycles_verify);
#endif

  return 0;
}

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(void);
#endif
int main(void)
{
  enable_cyclecounter();
  bench();
  disable_cyclecounter();

  return 0;
}
