/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */


/*
 * This file is derived from the public domain
 * AVX2 Dilithium implementation @[REF_AVX2].
 */

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include <immintrin.h>
#include <stdint.h>
#include <string.h>
#include "arith_native_x86_64.h"
#include "consts.h"

/*
 * Reference: The pqcrystals implementation assumes a buffer that is 8 bytes
 *.           larger as the first loop overreads by 8 bytes that are then
 *            discarded. We instead do not pad the buffer and do not overread.
 *            The performance impact is negligible and it does not force the
 *            frontend to perform the unintuitive padding.
 */

unsigned int mld_rej_uniform_avx2(
    int32_t *MLD_RESTRICT r, const uint8_t buf[MLD_AVX2_REJ_UNIFORM_BUFLEN])
{
  unsigned int ctr, pos;
  uint32_t good;
  __m256i d, tmp;
  const __m256i bound = _mm256_set1_epi32(MLDSA_Q);
  const __m256i mask = _mm256_set1_epi32(0x7FFFFF);
  const __m256i idx8 =
      _mm256_set_epi8(-1, 15, 14, 13, -1, 12, 11, 10, -1, 9, 8, 7, -1, 6, 5, 4,
                      -1, 11, 10, 9, -1, 8, 7, 6, -1, 5, 4, 3, -1, 2, 1, 0);

  ctr = pos = 0;
  while (ctr <= MLDSA_N - 8 && pos <= MLD_AVX2_REJ_UNIFORM_BUFLEN - 32)
  {
    d = _mm256_loadu_si256((__m256i *)&buf[pos]);
    d = _mm256_permute4x64_epi64(d, 0x94);
    d = _mm256_shuffle_epi8(d, idx8);
    d = _mm256_and_si256(d, mask);
    pos += 24;

    tmp = _mm256_sub_epi32(d, bound);
    good = _mm256_movemask_ps((__m256)tmp);
    tmp = _mm256_cvtepu8_epi32(
        _mm_loadl_epi64((__m128i *)&mld_rej_uniform_table[good]));
    d = _mm256_permutevar8x32_epi32(d, tmp);

    _mm256_storeu_si256((__m256i *)&r[ctr], d);
    ctr += _mm_popcnt_u32(good);
  }

  while (ctr < MLDSA_N && pos <= MLD_AVX2_REJ_UNIFORM_BUFLEN - 3)
  {
    uint32_t t = buf[pos++];
    t |= (uint32_t)buf[pos++] << 8;
    t |= (uint32_t)buf[pos++] << 16;
    t &= 0x7FFFFF;

    if (t < MLDSA_Q)
    {
      r[ctr++] = t;
    }
  }

  return ctr;
}

#else /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
       */

MLD_EMPTY_CU(avx2_rej_uniform)

#endif /* !(MLD_ARITH_BACKEND_X86_64_DEFAULT && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED) */
