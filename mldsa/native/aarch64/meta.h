/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_AARCH64_META_H
#define MLD_NATIVE_AARCH64_META_H

/* Set of primitives that this backend replaces */
#define MLD_USE_NATIVE_NTT
#define MLD_USE_NATIVE_INTT
#define MLD_USE_NATIVE_POINTWISE

/* Identifier for this backend so that source and assembly files
 * in the build can be appropriately guarded. */
#define MLD_ARITH_BACKEND_AARCH64


#if !defined(__ASSEMBLER__)
#include "src/arith_native_aarch64.h"

static MLD_INLINE void mld_ntt_native(int32_t data[MLDSA_N])
{
  mld_ntt_asm(data, mld_aarch64_ntt_zetas_layer123456,
              mld_aarch64_ntt_zetas_layer78);
}

static MLD_INLINE void mld_intt_native(int32_t data[MLDSA_N])
{
  mld_intt_asm(data, mld_aarch64_intt_zetas_layer78,
               mld_aarch64_intt_zetas_layer123456);
}

static MLD_INLINE void mld_pointwise_montgomery_native(
    int32_t out[MLDSA_N], const int32_t in0[MLDSA_N],
    const int32_t in1[MLDSA_N])
{
  mld_pointwise_montgomery_asm(out, in0, in1);
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_NATIVE_AARCH64_META_H */
