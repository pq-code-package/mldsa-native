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
 * 255 logical entries, each a (zeta, w) Barrett pair: zeta is the plain
 * centered twiddle w^{bitrev_8(k)} mod q (|zeta| <= q/2) and
 * w = round(zeta * 2^32 / q) is the Barrett multiplier used by the
 * constant-twiddle butterfly. The order matches the consumption order of
 * the 2+2+2+2 forward NTT.
 */
MLD_INTERNAL_DATA_DECLARATION const int32_t mld_rv32im_ntt_zetas[510];

#define mld_ntt_rv32im_asm MLD_NAMESPACE(ntt_rv32im_asm)
void mld_ntt_rv32im_asm(int32_t r[MLDSA_N], const int32_t zetas[510])
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_ntt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  /* The truncating `mulh` Barrett multiply has output bound
   * ceil(5*q/4), so eight CT layers grow the input-q bound to
   * q + 8*ceil(5*q/4) < 9*ceil(5*q/4). */
  /* This is MLD_NTT_BOUND, the exclusive output bound in the generic C and
   * native NTT contracts and the exclusive input bound in the pointwise
   * Montgomery contracts. */
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  ensures(array_abs_bound(r, 0, MLDSA_N, 94279698))
);

/*
 * This contract documents the C-facing assumptions and bounds used by the
 * assembly. Unlike the proved AArch64 and x86_64 backends, the experimental
 * RV32IM backend currently has no formal proof discharging it.
 */

#endif /* !MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H */
