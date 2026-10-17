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

/* Batched Keccak permute declarations and lane/way constants for the
 * keccakf1600x4_permute and keccakf1600x3_permute benchmarks. */
#include "../../mldsa/src/fips202/keccakf1600.h"

#ifndef MLD_BENCHMARK_NWARMUP
#define MLD_BENCHMARK_NWARMUP 50
#endif

#ifndef MLD_BENCHMARK_NITERATIONS
#define MLD_BENCHMARK_NITERATIONS 300
#endif

#ifndef MLD_BENCHMARK_NTESTS
#define MLD_BENCHMARK_NTESTS 20
#endif

#include "../src/test_common.h"

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

  /* poly_uniform_4x — the 4-way batched ExpandA (matrix) sampler; x4
   * counterpart to poly_uniform_3x below. Only benchmarked in the x4 build:
   * under MLD_CONFIG_USE_X3 its Keccak falls back to a non-native path, so the
   * number would not reflect the real x4 kernel. Guard also matches its
   * declaration in poly.h. */
#if !defined(MLD_CONFIG_USE_X3) && !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST))
  {
    MLD_ALIGN mld_poly poly_a0, poly_a1, poly_a2, poly_a3;
    MLD_ALIGN uint8_t seed_ext4[4][MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
    CHECK(mld_randombytes((uint8_t *)seed_ext4, sizeof(seed_ext4)) == 0);
    BENCH("poly_uniform_4x", mld_poly_uniform_4x(&poly_a0, &poly_a1, &poly_a2,
                                                 &poly_a3, seed_ext4))
  }
#endif /* !MLD_CONFIG_USE_X3 && !MLD_CONFIG_SERIAL_FIPS202_ONLY && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST) */

  BENCH("poly_caddq", mld_poly_caddq((mld_poly *)data0));

  /* poly_uniform_eta_4x — exercises rej_uniform_eta{2,4}_avx2_asm on x86.
   * Not benchmarked with MLD_CONFIG_USE_X3, where the AArch64 backend provides
   * the x3 kernel instead and this row would measure a fallback. */
#if !defined(MLD_CONFIG_USE_X3) && !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    !defined(MLD_CONFIG_NO_KEYPAIR_API)
  {
    MLD_ALIGN mld_poly poly_eta0, poly_eta1, poly_eta2, poly_eta3;
    BENCH(
        "poly_uniform_eta_4x",
        mld_poly_uniform_eta_4x(&poly_eta0, &poly_eta1, &poly_eta2, &poly_eta3,
                                (const uint8_t *)data0, 0, 1, 2, 3))
  }
#endif /* !MLD_CONFIG_USE_X3 && !MLD_CONFIG_SERIAL_FIPS202_ONLY && \
          !MLD_CONFIG_NO_KEYPAIR_API */

  /* poly_uniform_gamma1_4x — ExpandMask x4 sampler. x4 build only (same reason
   * as eta_4x above). Guard matches its declaration in poly_kl.h. */
#if !defined(MLD_CONFIG_USE_X3) && !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST))
  {
    MLD_ALIGN mld_poly poly_g0, poly_g1, poly_g2, poly_g3;
    BENCH("poly_uniform_gamma1_4x",
          mld_poly_uniform_gamma1_4x(&poly_g0, &poly_g1, &poly_g2, &poly_g3,
                                     (const uint8_t *)data0, 0, 1, 2, 3))
  }
#endif /* !MLD_CONFIG_USE_X3 && !MLD_CONFIG_SERIAL_FIPS202_ONLY && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST) */

  /* keccakf1600x4_permute — raw 4-way permutation (four sequential Keccak
   * states, one call); x4 counterpart to keccakf1600x3_permute below (per
   * state: x4 value / 4 vs x3 value / 3). x4 build only (same reason as
   * eta_4x above). Guard matches its declaration in keccakf1600.h. */
#if !defined(MLD_CONFIG_USE_X3) && !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    (!defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
     defined(MLD_UNIT_TEST))
  {
    MLD_ALIGN uint64_t x4_state[MLD_KECCAK_LANES * MLD_KECCAK_WAY];
    CHECK(mld_randombytes((uint8_t *)x4_state, sizeof(x4_state)) == 0);
    BENCH("keccakf1600x4_permute", mld_keccakf1600x4_permute(x4_state))
  }
#endif /* !MLD_CONFIG_USE_X3 && !MLD_CONFIG_SERIAL_FIPS202_ONLY && \
          (!MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM || \
          MLD_UNIT_TEST) */

#if defined(MLD_CONFIG_USE_X3)
  /*
   * x3 (3-way) batched Keccak benchmarks, built with MLD_CONFIG_USE_X3: the raw
   * permutation and the ExpandA, ExpandS and ExpandMask samplers, to compare
   * with the x4 sampler rows above (per poly: x3 value / 3 vs x4 value / 4).
   */

  /* Raw x3 permutation (three sequential Keccak states, one call). */
  {
    MLD_ALIGN uint64_t x3_state[MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3];
    CHECK(mld_randombytes((uint8_t *)x3_state, sizeof(x3_state)) == 0);
    BENCH("keccakf1600x3_permute", mld_keccakf1600x3_permute(x3_state))
  }

  /* ExpandA x3 sampler (SHAKE128, three matrix entries per call). */
  {
    MLD_ALIGN mld_poly poly_a0, poly_a1, poly_a2;
    MLD_ALIGN uint8_t seed_ext[3][MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];
    CHECK(mld_randombytes((uint8_t *)seed_ext, sizeof(seed_ext)) == 0);
    BENCH("poly_uniform_3x",
          mld_poly_uniform_3x(&poly_a0, &poly_a1, &poly_a2, seed_ext))
  }

  /* ExpandS x3 sampler (SHAKE256, three secret polynomials per call). */
#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    !defined(MLD_CONFIG_NO_KEYPAIR_API)
  {
    MLD_ALIGN mld_poly poly_s0, poly_s1, poly_s2;
    BENCH("poly_uniform_eta_3x",
          mld_poly_uniform_eta_3x(&poly_s0, &poly_s1, &poly_s2,
                                  (const uint8_t *)data0, 0, 1, 2))
  }
#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY && !MLD_CONFIG_NO_KEYPAIR_API */

  /* ExpandMask x3 sampler (SHAKE256, three gamma1 mask polynomials per call).
   */
#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && \
    (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST))
  {
    MLD_ALIGN mld_poly poly_g0, poly_g1, poly_g2;
    BENCH("poly_uniform_gamma1_3x",
          mld_poly_uniform_gamma1_3x(&poly_g0, &poly_g1, &poly_g2,
                                     (const uint8_t *)data0, 0, 1, 2))
  }
#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY && (!MLD_CONFIG_REDUCE_RAM || \
          MLD_UNIT_TEST) */
#endif /* MLD_CONFIG_USE_X3 */

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
