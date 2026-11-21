/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_X86_64_KECCAK_F1600_X4_AVX2_H
#define MLD_FIPS202_NATIVE_X86_64_KECCAK_F1600_X4_AVX2_H

#include "../../../common.h"

/* Only needed if the built-in FIPS202-x4 code is used. */
#if !defined(MLD_CONFIG_FIPS202_CUSTOM_HEADER) &&                              \
    !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) &&                                \
    (!defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
     defined(MLD_UNIT_TEST))
#define MLD_FIPS202_X86_64_NEED_X4_AVX2

/* Part of backend API */
#define MLD_USE_NATIVE_FIPS202_X4

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/fips202_native_x86_64.h"
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccak_f1600_x4_native(uint64_t *state)
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_X86_64_AVX2))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_keccak_f1600_x4_avx2_asm(state, mld_keccakf1600_round_constants,
                               mld_keccak_rho8, mld_keccak_rho56);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !__ASSEMBLER__ */

#endif /* !MLD_CONFIG_FIPS202_CUSTOM_HEADER && !MLD_CONFIG_SERIAL_FIPS202_ONLY \
          && (!MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM ||          \
          MLD_UNIT_TEST) */
#endif /* !MLD_FIPS202_NATIVE_X86_64_KECCAK_F1600_X4_AVX2_H */
