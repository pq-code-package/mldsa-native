/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_X86_64_META_H
#define MLD_NATIVE_X86_64_META_H

/* Identifier for this backend so that source and assembly files
 * in the build can be appropriately guarded. */
#define MLD_ARITH_BACKEND_X86_64_DEFAULT

#define MLD_USE_NATIVE_NTT_CUSTOM_ORDER
#define MLD_USE_NATIVE_NTT
#define MLD_USE_NATIVE_INTT
#define MLD_USE_NATIVE_POINTWISE

#if !defined(__ASSEMBLER__)
#include <string.h>
#include "../../common.h"
#include "src/arith_native_x86_64.h"

static MLD_INLINE void mld_poly_permute_bitrev_to_custom(int32_t data[MLDSA_N])
{
  mld_nttunpack_avx2((__m256i *)(data));
}

static MLD_INLINE void mld_ntt_native(int32_t data[MLDSA_N])
{
  mld_ntt_avx2((__m256i *)data, mld_qdata.vec);
}
static MLD_INLINE void mld_intt_native(int32_t data[MLDSA_N])
{
  mld_invntt_avx2((__m256i *)data, mld_qdata.vec);
}

static MLD_INLINE void mld_pointwise_montgomery_native(
    int32_t out[MLDSA_N], const int32_t in0[MLDSA_N],
    const int32_t in1[MLDSA_N])
{
  mld_pointwise_montgomery_avx2((__m256i *)out, (const __m256i *)in0,
                                (const __m256i *)in1, mld_qdata.vec);
}

static MLD_INLINE void mld_pointwise_acc_montgomery_native(
    int32_t out[MLDSA_N], const int32_t in0[MLDSA_N],
    const int32_t in1[MLDSA_N])
{
  mld_pointwise_acc_montgomery_avx2((__m256i *)out, (const __m256i *)in0,
                                    (const __m256i *)in1, mld_qdata.vec);
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_NATIVE_X86_64_META_H */
