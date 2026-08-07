/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H
#define MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H

#include "../../../cbmc.h"
#include "../../../common.h"

#define mld_ntt_armv81m_asm MLD_NAMESPACE(ntt_armv81m_asm)
void mld_ntt_armv81m_asm(int32_t r[MLDSA_N])
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(r, 0, MLDSA_N, MLD_NTT_BOUND))
);

#endif /* !MLD_NATIVE_ARMV81M_SRC_ARITH_NATIVE_ARMV81M_H */
