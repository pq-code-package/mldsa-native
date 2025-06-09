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
#include "../mldsa/ntt.h"
#include "../mldsa/poly.h"
#include "../mldsa/polyvec.h"
#include "../mldsa/randombytes.h"
#include "hal.h"

#define NWARMUP 50
#define NITERATIONS 300
#define NTESTS 20

static int cmp_uint64_t(const void *a, const void *b)
{
  return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

#define BENCH(txt, code)                                \
  for (i = 0; i < NTESTS; i++)                          \
  {                                                     \
    randombytes((uint8_t *)data0, sizeof(data0));       \
    randombytes((uint8_t *)data1, sizeof(data1));       \
    randombytes((uint8_t *)data2, sizeof(data2));       \
    randombytes((uint8_t *)data3, sizeof(data3));       \
    for (j = 0; j < NWARMUP; j++)                       \
    {                                                   \
      code;                                             \
    }                                                   \
                                                        \
    t0 = get_cyclecounter();                            \
    for (j = 0; j < NITERATIONS; j++)                   \
    {                                                   \
      code;                                             \
    }                                                   \
    t1 = get_cyclecounter();                            \
    (cyc)[i] = t1 - t0;                                 \
  }                                                     \
  qsort((cyc), NTESTS, sizeof(uint64_t), cmp_uint64_t); \
  printf(txt " cycles=%" PRIu64 "\n", (cyc)[NTESTS >> 1] / NITERATIONS);

static int bench(void)
{
  MLD_ALIGN int32_t data0[MLDSA_N * MLDSA_K];
  MLD_ALIGN int32_t data1[MLDSA_N * MLDSA_K];
  MLD_ALIGN int32_t data2[MLDSA_N * MLDSA_K];
  MLD_ALIGN int32_t data3[MLDSA_N * MLDSA_K];
  uint64_t cyc[NTESTS];
  unsigned i, j;
  uint64_t t0, t1;

  BENCH("poly_ntt", poly_ntt((poly *)data0))
  BENCH("poly_invntt_tomont", poly_invntt_tomont((poly *)data0))

  BENCH("poly_pointwise_montgomery",
        poly_pointwise_montgomery((poly *)data0, (poly *)data1, (poly *)data2))
  BENCH("poly_reduce", poly_reduce((poly *)data0))
  BENCH("poly_caddq", poly_caddq((poly *)data0))
  BENCH("poly_add", poly_add((poly *)data0, (poly *)data1))
  BENCH("poly_sub", poly_sub((poly *)data0, (poly *)data1))
  BENCH("poly_shiftl", poly_shiftl((poly *)data0))
  BENCH("poly_power2round",
        poly_power2round((poly *)data0, (poly *)data1, (poly *)data2))
  BENCH("poly_decompose",
        poly_decompose((poly *)data0, (poly *)data1, (poly *)data2))
  BENCH("poly_make_hint",
        poly_make_hint((poly *)data0, (poly *)data1, (poly *)data2))
  BENCH("poly_use_hint",
        poly_use_hint((poly *)data0, (poly *)data1, (poly *)data2))
  BENCH("poly_chknorm", poly_chknorm((poly *)data0, INT32_MAX))
  BENCH("polyz_unpack", polyz_unpack((poly *)data0, (uint8_t *)data1))
  BENCH("polyw1_pack", polyw1_pack((uint8_t *)data0, (poly *)data1))
  BENCH("polyt1_unpack", polyt1_unpack((poly *)data0, (uint8_t *)data1))
  BENCH("polyt1_unpack", polyt1_unpack((poly *)data0, (uint8_t *)data1))
  BENCH("poly_uniform", poly_uniform((poly *)data0, (uint8_t *)data1))
  BENCH("poly_uniform_4x", poly_uniform((poly *)data0, (uint8_t *)data1))
  BENCH("poly_uniform_eta_4x",
        poly_uniform_eta_4x((poly *)data0, (poly *)data1, (poly *)data2,
                            (poly *)data3, (uint8_t *)data1, 0, 1, 2, 3))

  BENCH("polyvecl_pointwise_acc_montgomery",
        polyvecl_pointwise_acc_montgomery((poly *)data0, (polyvecl *)data1,
                                          (polyvecl *)data2))

  return 0;
}

int main(void)
{
  enable_cyclecounter();
  bench();
  disable_cyclecounter();

  return 0;
}
