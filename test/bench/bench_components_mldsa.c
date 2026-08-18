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
#include "../../mldsa/src/poly.h"
#include "../../mldsa/src/poly_kl.h"
#include "../../mldsa/src/polyvec.h"
#include "../../mldsa/src/polyvec_lazy.h"
#include "../../mldsa/src/randombytes.h"
#include "hal.h"

#ifndef MLD_BENCHMARK_NWARMUP
#define MLD_BENCHMARK_NWARMUP 50
#endif

#ifndef MLD_BENCHMARK_NITERATIONS
#define MLD_BENCHMARK_NITERATIONS 300
#endif

#ifndef MLD_BENCHMARK_NTESTS
#define MLD_BENCHMARK_NTESTS 20
#endif

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
  return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

#define BENCH(txt, code)                                                     \
  for (i = 0; i < MLD_BENCHMARK_NTESTS; i++)                                 \
  {                                                                          \
    CHECK(mld_randombytes((uint8_t *)data0, sizeof(data0)) == 0);            \
    CHECK(mld_randombytes((uint8_t *)&polyvecl_a, sizeof(polyvecl_a)) == 0); \
    CHECK(mld_randombytes((uint8_t *)&polyvecl_b, sizeof(polyvecl_b)) == 0); \
    CHECK(mld_randombytes((uint8_t *)&polymat, sizeof(polymat)) == 0);       \
    for (j = 0; j < MLD_BENCHMARK_NWARMUP; j++)                              \
    {                                                                        \
      code;                                                                  \
    }                                                                        \
                                                                             \
    t0 = get_cyclecounter();                                                 \
    for (j = 0; j < MLD_BENCHMARK_NITERATIONS; j++)                          \
    {                                                                        \
      code;                                                                  \
    }                                                                        \
    t1 = get_cyclecounter();                                                 \
    (cyc)[i] = t1 - t0;                                                      \
  }                                                                          \
  qsort((cyc), MLD_BENCHMARK_NTESTS, sizeof(uint64_t), cmp_uint64_t);        \
  printf(txt " cycles=%" PRIu64 "\n",                                        \
         (cyc)[MLD_BENCHMARK_NTESTS >> 1] / MLD_BENCHMARK_NITERATIONS);

static int bench(void)
{
  MLD_ALIGN int32_t data0[256];
  MLD_ALIGN int32_t data1[256];
  MLD_ALIGN mld_poly poly_out;
  MLD_ALIGN mld_polyvecl polyvecl_a, polyvecl_b;
  MLD_ALIGN mld_polymat polymat;
  uint64_t cyc[MLD_BENCHMARK_NTESTS];
  unsigned i, j;
  uint64_t t0, t1;
  uint32_t chknorm_acc = 0;

  /* ntt */
  BENCH("poly_ntt", mld_poly_ntt((mld_poly *)data0))
  BENCH("poly_invntt_tomont", mld_poly_invntt_tomont((mld_poly *)data0))

  /* pointwise */
#if !defined(MLD_CONFIG_REDUCE_RAM)
  BENCH("polyvecl_pointwise_acc_montgomery",
        mld_polyvecl_pointwise_acc_montgomery(&poly_out, &polyvecl_a,
                                              &polyvecl_b))
#endif
  BENCH("polyvec_matrix_pointwise_montgomery_row",
        mld_polyvec_matrix_pointwise_montgomery_row(&poly_out, &polymat,
                                                    &polyvecl_b, 0))

  /* polyz_unpack */
  BENCH("polyz_unpack", mld_polyz_unpack(&poly_out, (const uint8_t *)data0))

  /* rej_uniform (via poly_uniform) */
  {
    uint8_t seed[MLDSA_SEEDBYTES + 2];
    CHECK(mld_randombytes(seed, MLDSA_SEEDBYTES) == 0);
    seed[MLDSA_SEEDBYTES] = 0;
    seed[MLDSA_SEEDBYTES + 1] = 0;
    BENCH("poly_uniform", mld_poly_uniform(&poly_out, seed))
  }

  BENCH("poly_caddq", mld_poly_caddq((mld_poly *)data0));

  /* poly_uniform_eta_4x — exercises rej_uniform_eta{2,4}_avx2_asm on x86 */
#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    !defined(MLD_CONFIG_NO_KEYPAIR_API)
  {
    MLD_ALIGN mld_poly poly_eta0, poly_eta1, poly_eta2, poly_eta3;
    BENCH(
        "poly_uniform_eta_4x",
        mld_poly_uniform_eta_4x(&poly_eta0, &poly_eta1, &poly_eta2, &poly_eta3,
                                (const uint8_t *)data0, 0, 1, 2, 3))
  }
#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY && !MLD_CONFIG_NO_KEYPAIR_API */

  BENCH("poly_chknorm",
        chknorm_acc ^=
        mld_poly_chknorm((const mld_poly *)data0, MLDSA_GAMMA1 - MLDSA_BETA);)

  BENCH("poly_decompose", mld_poly_decompose((mld_poly *)data0, &poly_out))

  BENCH("poly_use_hint",
        mld_poly_use_hint((mld_poly *)data0, (mld_poly *)data1));

  return (int)chknorm_acc;
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
