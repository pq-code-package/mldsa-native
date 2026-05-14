/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H
#define MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H

#include "../../../cbmc.h"
#include "../../../common.h"

#define mld_rv32im_ntt_zetas MLD_NAMESPACE(rv32im_ntt_zetas)

/*
 * Forward NTT zeta table for the RV32-IM backend.
 *
 * 255 logical entries, each a (zeta, zeta * QINV mod 2^32) pair, with
 * zeta in Montgomery form (i.e. R * w^{bitrev_8(k)} mod q where R = 2^32).
 * The order matches the consumption order of the 2+2+2+2 forward NTT.
 */
MLD_INTERNAL_DATA_DECLARATION const int32_t mld_rv32im_ntt_zetas[510];

#define mld_ntt_rv32im_asm MLD_NAMESPACE(ntt_rv32im_asm)
void mld_ntt_rv32im_asm(int32_t *r, const int32_t *zetas)
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_ntt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(r, 0, MLDSA_N, 9 * MLDSA_Q))
);

#endif /* !MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H */
