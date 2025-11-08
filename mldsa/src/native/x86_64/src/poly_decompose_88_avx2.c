/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [REF_AVX2]
 *   CRYSTALS-Dilithium optimized AVX2 implementation
 *   Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé
 *   https://github.com/pq-crystals/dilithium/tree/master/avx2
 */

/*
 * This file is derived from the public domain
 * AVX2 Dilithium implementation @[REF_AVX2].
 *
 * The algorithm for Decompose(r) (more specifically the handling for the
 * wrap-around cases) are modified. See the "Reference" section in the comments
 * below for a more detailed comparison.
 */

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include <immintrin.h>
#include <stdint.h>
#include <string.h>
#include "arith_native_x86_64.h"
#include "consts.h"


#define _mm256_blendv_epi32(a, b, mask)                        \
  _mm256_castps_si256(_mm256_blendv_ps(_mm256_castsi256_ps(a), \
                                       _mm256_castsi256_ps(b), \
                                       _mm256_castsi256_ps(mask)))

void mld_poly_decompose_88_avx2(__m256i *a1, __m256i *a0, const __m256i *a)
{
  unsigned int i;
  __m256i f, f0, f1, t;
  const __m256i q_bound = _mm256_set1_epi32(87 * MLDSA_GAMMA2);
  /* check-magic: 11275 == floor(2**24 / 1488) */
  const __m256i v = _mm256_set1_epi32(11275);
  const __m256i alpha = _mm256_set1_epi32(2 * MLDSA_GAMMA2);
  const __m256i off = _mm256_set1_epi32(127);
  const __m256i shift = _mm256_set1_epi32(128);

  for (i = 0; i < MLDSA_N / 8; i++)
  {
    f = _mm256_load_si256(&a[i]);

    /* check-magic: 1488 == 2 * ((MLDSA_Q-1) // 88) // 128 */
    /*
     * The goal is to compute f1 = round-(f / (2*GAMMA2)), which can be computed
     * alternatively as round-(f / (128B)) = round-(ceil(f / 128) / B) where
     * B = 2*GAMMA2 / 128 = 1488. Here round-() denotes "round half down".
     *
     * range: 0 <= f <= Q-1 = 88*GAMMA2 = 44*128*B
     */

    /* Compute f1' = ceil(f / 128) as floor((f + 127) >> 7) */
    f1 = _mm256_add_epi32(f, off);
    f1 = _mm256_srli_epi32(f1, 7);
    /*
     * range: 0 <= f1' <= (Q-1)/128 = 44B
     *
     * Also, f1' <= (Q-1)/128 = 2^16 - 2^6 < 2^16 ensures that the odd-index
     * 16-bit lanes are all 0, so no bits will be dropped in the input of the
     * _mm256_mulhi_epu16() below.
     */

    /*
     * Compute f1 = round-(f1' / B) ≈ round(f1' * 11275 / 2^24). This is exact
     * for 0 <= f1' < 2^16. Note that half is rounded down since 11275 / 2^24 ≲
     * 1 / 1488.
     *
     * The odd-index 16-bit lanes are still all 0 after this. As such, despite
     * that the following steps use 32-bit lanes, the value of f1 is unaffected.
     */
    f1 = _mm256_mulhi_epu16(f1, v);
    f1 = _mm256_mulhrs_epi16(f1, shift);
    /* range: 0 <= f1 <= 44 */

    /*
     * If f1 = 44, i.e. f > 87*GAMMA2, proceed as if f' = f - Q was given
     * instead. (For f = 87*GAMMA2 + 1 thus f' = -GAMMA2, we still round it to 0
     * like other "wrapped around" cases.)
     *
     * Reference: They handle wrap-around in a somewhat convoluted way. Most
     *            notably, they compute remainder f0 with quotient f1 that's
     *            already wrapped around, so is off by q (instead of by 1) from
     *            what it should be ultimately. They detect the need for
     *            correction by checking if f0 is abnormally large.
     *
     *            Our approach is closer to Algorithm 36 in the specification,
     *            in that we compute f0 normally and correct f1, f0 in the way
     *            they prescribed. The only real difference is that we check for
     *            wrap-around by examining f directly, instead of some other
     *            intermediates computed from it.
     */

    /* Check for wrap-around */
    t = _mm256_cmpgt_epi32(f, q_bound);

    /* Compute remainder f0 */
    f0 = _mm256_mullo_epi32(f1, alpha);
    f0 = _mm256_sub_epi32(f, f0);
    /*
     * range: -GAMMA2 < f0 <= GAMMA2
     *
     * This holds since f1 = round-(f / (2*GAMMA2)) was computed exactly.
     */

    /* If wrap-around is required, set f1 = 0 and f0 -= 1 */
    f1 = _mm256_andnot_si256(t, f1);
    f0 = _mm256_add_epi32(f0, t);
    /* range: 0 <= f1 <= 43, -GAMMA2 <= f0 <= GAMMA2 */

    _mm256_store_si256(&a1[i], f1);
    _mm256_store_si256(&a0[i], f0);
  }
}
#undef _mm256_blendv_epi32

#else /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
       */

MLD_EMPTY_CU(avx2_poly_decompose)

#endif /* !(MLD_ARITH_BACKEND_X86_64_DEFAULT && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED) */
