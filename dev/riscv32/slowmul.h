/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_DEV_RISCV32_SLOWMUL_H
#define MLD_DEV_RISCV32_SLOWMUL_H

/*
 * Arithmetic backend for the RISC-V RV32-IM ISA and the ILP32, ILP32F, and
 * ILP32D family of ABIs. Select this profile explicitly through
 * MLD_CONFIG_ARITH_BACKEND_FILE when shift/add multiplication by q is
 * preferable to the default fastmul profile.
 *
 * This profile replaces the Barrett low(t*q) multiply in the forward and
 * inverse NTT wrappers by a shift/add chain exploiting q = 2^23 - 2^13 + 1.
 * It still uses RV32M `mulh`, and constant-time use still relies on the
 * target's RV32M multiplier, including `mul` and `mulh`, having
 * data-independent latency even if it is comparatively slow.
 *
 * The assembly has fixed control flow and secret-independent memory
 * addresses. RV32IM does not architecturally guarantee constant-latency
 * multiplication, so integrators must establish this property for the
 * selected core. HOL-Light proves functional correctness, memory safety, and
 * secret-independent execution subject to that multiplier assumption.
 * CBMC proves that these C wrappers satisfy the native arithmetic contracts.
 */

/* Set of primitives that this backend replaces. */
#define MLD_USE_NATIVE_NTT
#define MLD_USE_NATIVE_INTT
#define MLD_USE_NATIVE_POINTWISE_MONTGOMERY

/* Identifier for this backend so that source and assembly files
 * in the build can be appropriately guarded. */
#define MLD_ARITH_BACKEND_RV32IM

#define MLD_RV32IM_NEED_SLOWMUL

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_rv32im.h"

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_ntt_native(int32_t data[MLDSA_N])
{
  mld_ntt_rv32im_slowmul_asm(data, mld_rv32im_ntt_zetas);
  return MLD_NATIVE_FUNC_SUCCESS;
}

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_intt_native(int32_t data[MLDSA_N])
{
  mld_intt_rv32im_slowmul_asm(data, mld_rv32im_ntt_zetas);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
    defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_poly_pointwise_montgomery_native(
    int32_t a[MLDSA_N], const int32_t b[MLDSA_N])
{
  mld_poly_pointwise_montgomery_rv32im_asm(a, b);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API || \
          MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_DEV_RISCV32_SLOWMUL_H */
