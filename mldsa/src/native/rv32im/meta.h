/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_RV32IM_META_H
#define MLD_NATIVE_RV32IM_META_H

/* Set of primitives that this backend replaces */
#define MLD_USE_NATIVE_NTT

/* Identifier for this backend so that source and assembly files
 * in the build can be appropriately guarded. */
#define MLD_ARITH_BACKEND_RV32IM


#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_rv32im.h"

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_ntt_native(int32_t data[MLDSA_N])
{
  mld_ntt_rv32im_asm(data, mld_rv32im_ntt_zetas);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#endif /* !__ASSEMBLER__ */
#endif /* !MLD_NATIVE_RV32IM_META_H */
