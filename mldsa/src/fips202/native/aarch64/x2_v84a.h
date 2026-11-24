/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_AARCH64_X2_V84A_H
#define MLD_FIPS202_NATIVE_AARCH64_X2_V84A_H

#if !defined(__ARM_FEATURE_SHA3)
#error This backend can only be used if SHA3 extensions are available.
#endif

/* Part of backend API */
#define MLD_USE_NATIVE_FIPS202_X4
/* Guard for assembly file */
/* Only needed if the built-in FIPS202-x4 code is used. */
#if !defined(MLD_CONFIG_FIPS202_CUSTOM_HEADER) &&                              \
    !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) &&                                \
    (!defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
     defined(MLD_UNIT_TEST))
#define MLD_FIPS202_AARCH64_NEED_X2_V84A

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/fips202_native_aarch64.h"

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccak_f1600_x4_native(uint64_t *state)
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_AARCH64_NEON) ||
      !mld_sys_check_capability(MLD_SYS_CAP_AARCH64_SHA3))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_keccak_f1600_x2_v84a_aarch64_asm(state + 0 * 25,
                                       mld_keccakf1600_round_constants);
  mld_keccak_f1600_x2_v84a_aarch64_asm(state + 2 * 25,
                                       mld_keccakf1600_round_constants);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !__ASSEMBLER__ */

#endif /* !MLD_CONFIG_FIPS202_CUSTOM_HEADER && !MLD_CONFIG_SERIAL_FIPS202_ONLY \
          && (!MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM ||          \
          MLD_UNIT_TEST) */
#endif /* !MLD_FIPS202_NATIVE_AARCH64_X2_V84A_H */
