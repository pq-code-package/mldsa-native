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
 */

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     MLD_CONFIG_PARAMETER_SET == 44)

#include <immintrin.h>
#include "arith_native_x86_64.h"

/* Pack w1 polynomial (coefficients in [0,43]) for GAMMA2 = (Q-1)/88.
 * 6-bit encoding, 4 coefficients per 3 bytes; 32 coefficients per iteration. */
void mld_polyw1_pack_88_avx2(uint8_t *r, const int32_t *a)
{
  unsigned int i;
  const __m256i shift1 = _mm256_set1_epi16((64 << 8) + 1);
  const __m256i shift2 = _mm256_set1_epi32(((1 << 12) << 16) + 1);
  const __m256i shufdidx1 = _mm256_set_epi32(7, 3, 6, 2, 5, 1, 4, 0);
  const __m256i shufdidx2 = _mm256_set_epi32(-1, -1, 6, 5, 4, 2, 1, 0);
  const __m256i shufbidx =
      _mm256_set_epi8(-1, -1, -1, -1, 14, 13, 12, 10, 9, 8, 6, 5, 4, 2, 1, 0,
                      -1, -1, -1, -1, 14, 13, 12, 10, 9, 8, 6, 5, 4, 2, 1, 0);

  for (i = 0; i < MLDSA_N / 32; i++)
  {
    __m256i f0 = _mm256_load_si256((__m256i *)&a[32 * i + 0]);
    __m256i f1 = _mm256_load_si256((__m256i *)&a[32 * i + 8]);
    __m256i f2 = _mm256_load_si256((__m256i *)&a[32 * i + 16]);
    __m256i f3 = _mm256_load_si256((__m256i *)&a[32 * i + 24]);
    f0 = _mm256_packus_epi32(f0, f1);
    f1 = _mm256_packus_epi32(f2, f3);
    f0 = _mm256_packus_epi16(f0, f1);
    f0 = _mm256_maddubs_epi16(f0, shift1);
    f0 = _mm256_madd_epi16(f0, shift2);
    f0 = _mm256_permutevar8x32_epi32(f0, shufdidx1);
    f0 = _mm256_shuffle_epi8(f0, shufbidx);
    f0 = _mm256_permutevar8x32_epi32(f0, shufdidx2);

    /* Each iteration produces 24 valid bytes in the low 192 bits.
     * Store as 128-bit + 64-bit to avoid writing past the output buffer. */
    {
      __m128i lo = _mm256_castsi256_si128(f0);
      __m128i hi = _mm256_extracti128_si256(f0, 1);
      _mm_storeu_si128((__m128i *)&r[24 * i], lo);
      _mm_storel_epi64((__m128i *)&r[24 * i + 16], hi);
    }
  }
}

#else /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
         && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
         44) */

MLD_EMPTY_CU(avx2_polyw1_pack_88)

#endif /* !(MLD_ARITH_BACKEND_X86_64_DEFAULT &&                             \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED &&                               \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
          44)) */
