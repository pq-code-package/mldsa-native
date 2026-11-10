/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_DEV_FIPS202_RISCV64_X1_ZBB_H
#define MLD_DEV_FIPS202_RISCV64_X1_ZBB_H

/* Part of backend API */
#define MLD_USE_NATIVE_FIPS202_X1
/* Guard for assembly file */
#define MLD_FIPS202_RISCV64_NEED_X1_ZBB

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/fips202_native_riscv64.h"
MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccak_f1600_x1_native(uint64_t *state)
{
  mld_keccak_f1600_x1_zbb_riscv64_asm(state, mld_keccakf1600_round_constants);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !__ASSEMBLER__ */

#endif /* !MLD_DEV_FIPS202_RISCV64_X1_ZBB_H */
