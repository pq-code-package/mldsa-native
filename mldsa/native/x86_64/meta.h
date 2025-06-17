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
#define MLD_USE_NATIVE_POLY_REDUCE
#define MLD_USE_NATIVE_POLY_CADDQ

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

static MLD_INLINE void mld_poly_reduce_native(int32_t a[MLDSA_N])
{
  mld_poly_reduce_avx2(a);
}

static MLD_INLINE void mld_poly_caddq_native(int32_t a[MLDSA_N])
{
  mld_poly_caddq_avx2(a);
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_NATIVE_X86_64_META_H */
