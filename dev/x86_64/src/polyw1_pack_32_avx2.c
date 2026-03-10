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
     (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87))

#include <immintrin.h>
#include "arith_native_x86_64.h"

/* Pack w1 polynomial (coefficients in [0,15]) for GAMMA2 = (Q-1)/32.
 * Packs 2 nibbles per byte; 64 coefficients per iteration. */
void mld_polyw1_pack_32_avx2(uint8_t *r, const int32_t *a)
{
  unsigned int i;
  const __m256i shift = _mm256_set1_epi16((16 << 8) + 1);
  const __m256i shufbidx =
      _mm256_set_epi8(15, 14, 7, 6, 13, 12, 5, 4, 11, 10, 3, 2, 9, 8, 1, 0, 15,
                      14, 7, 6, 13, 12, 5, 4, 11, 10, 3, 2, 9, 8, 1, 0);

  for (i = 0; i < MLDSA_N / 64; ++i)
  {
    __m256i f0 = _mm256_load_si256((__m256i *)&a[64 * i + 0]);
    __m256i f1 = _mm256_load_si256((__m256i *)&a[64 * i + 8]);
    __m256i f2 = _mm256_load_si256((__m256i *)&a[64 * i + 16]);
    __m256i f3 = _mm256_load_si256((__m256i *)&a[64 * i + 24]);
    __m256i f4 = _mm256_load_si256((__m256i *)&a[64 * i + 32]);
    __m256i f5 = _mm256_load_si256((__m256i *)&a[64 * i + 40]);
    __m256i f6 = _mm256_load_si256((__m256i *)&a[64 * i + 48]);
    __m256i f7 = _mm256_load_si256((__m256i *)&a[64 * i + 56]);
    f0 = _mm256_packus_epi32(f0, f1);
    f1 = _mm256_packus_epi32(f2, f3);
    f2 = _mm256_packus_epi32(f4, f5);
    f3 = _mm256_packus_epi32(f6, f7);
    f0 = _mm256_packus_epi16(f0, f1);
    f1 = _mm256_packus_epi16(f2, f3);
    f0 = _mm256_maddubs_epi16(f0, shift);
    f1 = _mm256_maddubs_epi16(f1, shift);
    f0 = _mm256_packus_epi16(f0, f1);
    f0 = _mm256_permute4x64_epi64(f0, 0xD8);
    f0 = _mm256_shuffle_epi8(f0, shufbidx);
    _mm256_storeu_si256((__m256i *)&r[32 * i], f0);
  }
}

#else /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
         && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == \
         65 || MLD_CONFIG_PARAMETER_SET == 87) */

MLD_EMPTY_CU(avx2_polyw1_pack_32)

#endif /* !(MLD_ARITH_BACKEND_X86_64_DEFAULT &&                                \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED &&                                  \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87)) */
