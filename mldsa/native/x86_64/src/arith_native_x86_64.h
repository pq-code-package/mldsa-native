/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_NATIVE_X86_64_SRC_ARITH_NATIVE_X86_64_H
#define MLD_NATIVE_X86_64_SRC_ARITH_NATIVE_X86_64_H
#include "../../../common.h"

#include <immintrin.h>
#include <stdint.h>
#include "consts.h"
#define mld_ntt_avx2 MLD_NAMESPACE(ntt_avx2)
void mld_ntt_avx2(__m256i *r, const __m256i *mld_qdata);

#define mld_invntt_avx2 MLD_NAMESPACE(invntt_avx2)
void mld_invntt_avx2(__m256i *r, const __m256i *mld_qdata);

#define mld_nttunpack_avx2 MLD_NAMESPACE(nttunpack_avx2)
void mld_nttunpack_avx2(__m256i *r);

#define mld_poly_reduce_avx2 MLD_NAMESPACE(poly_reduce_avx2)
void mld_poly_reduce_avx2(int32_t *r);

#define mld_poly_caddq_avx2 MLD_NAMESPACE(poly_caddq_avx2)
void mld_poly_caddq_avx2(int32_t *r);

#endif /* !MLD_NATIVE_X86_64_SRC_ARITH_NATIVE_X86_64_H */
