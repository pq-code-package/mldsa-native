/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_RV32IM_META_H
#define MLD_NATIVE_RV32IM_META_H

/*
 * Experimental arithmetic backend for the RISC-V RV32-IM ISA and the
 * ILP32, ILP32F, and ILP32D family of ABIs for RV32-IM. It is deliberately
 * not selected by mldsa/src/native/meta.h: users must define
 * MLD_CONFIG_USE_NATIVE_BACKEND_ARITH and set
 * MLD_CONFIG_ARITH_BACKEND_FILE to native/rv32im/meta.h.
 *
 * The assembly has fixed control flow and secret-independent memory
 * addresses. Constant-time use also relies on the target's 32-bit multiplier
 * executing RV32M mul and mulh with data-independent latency. RV32IM does not
 * architecturally guarantee this property; integrators must establish it for
 * the selected core. The backend is covered by functional tests, but
 * currently has no formal proof.
 */

/* Set of primitives that this backend replaces. */
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
