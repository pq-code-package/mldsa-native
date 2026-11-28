/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_PPC64LE_AUTO_H
#define MLD_FIPS202_NATIVE_PPC64LE_AUTO_H

#include "../../../common.h"

#define MLD_FIPS202_PPC64LE

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/keccakf1600_ppc64le.h"

#define MLD_USE_FIPS202_X4_NATIVE
static MLD_INLINE int mld_keccak_f1600_x4_native(uint64_t *state)
{
  if (mld_sys_check_capability(MLD_SYS_CAP_POWER8))
  {
    mld_keccakf1600x4_permute24_ppc64le(state);
    return MLD_NATIVE_FUNC_SUCCESS;
  }
  return MLD_NATIVE_FUNC_FALLBACK;
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_FIPS202_NATIVE_PPC64LE_AUTO_H */
