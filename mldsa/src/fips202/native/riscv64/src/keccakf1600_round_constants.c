/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */

#include "../../../../common.h"

#if defined(MLD_FIPS202_RISCV64_NEED_X1_ZBB) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include "fips202_native_riscv64.h"

MLD_ALIGN MLD_INTERNAL_DATA_DEFINITION const uint64_t
    mld_keccakf1600_round_constants[24] = {
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
        0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
        0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
        0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
        0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
        0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
        0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
};

#else /* MLD_FIPS202_RISCV64_NEED_X1_ZBB && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
       */

MLD_EMPTY_CU(fips202_riscv64_round_constants)

#endif /* !(MLD_FIPS202_RISCV64_NEED_X1_ZBB && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED) */
