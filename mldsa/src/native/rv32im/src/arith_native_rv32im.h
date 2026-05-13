/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H
#define MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H

#include "../../../cbmc.h"
#include "../../../common.h"

#define mld_rv32im_ntt_zetas MLD_NAMESPACE(rv32im_ntt_zetas)

/* Length in 32-bit words of the zeta table consumed by mld_ntt_rv32im_asm.
 *  - layers 1..3: 7 (zeta, zeta*qinv) pairs                         = 14 words
 *  - layers 4..6: 8 outer groups, each (1 + 2 + 4) = 7 pairs        = 112 words
 *  - layers 7..8: 32 inner iterations, each 6 pairs                 = 384 words
 * Total: 14 + 112 + 384                                              = 510
 * words. */
#define MLD_RV32IM_NTT_ZETAS_LEN 510

MLD_INTERNAL_DATA_DECLARATION const int32_t
    mld_rv32im_ntt_zetas[MLD_RV32IM_NTT_ZETAS_LEN];

#define mld_ntt_rv32im_asm MLD_NAMESPACE(ntt_rv32im_asm)
void mld_ntt_rv32im_asm(int32_t *r, const int32_t *zetas)
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_ntt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 75423753 == 9 * MLDSA_Q */
  ensures(array_abs_bound(r, 0, MLDSA_N, 75423753))
);

#define mld_rv32im_intt_zetas MLD_NAMESPACE(rv32im_intt_zetas)

/* Length in 32-bit words of the zeta table consumed by mld_intt_rv32im_asm.
 * Layout mirrors the forward table but in reverse layer order:
 *  - inv layers 1..2: 32 inner iterations, each 6 pairs              = 384
 * words
 *  - inv layers 3..5: 8 outer groups, each (4 + 2 + 1) = 7 pairs     = 112
 * words
 *  - inv layers 6..8: a single 7-pair table loaded once              =  14
 * words Total: 384 + 112 + 14                                              =
 * 510 words. */
#define MLD_RV32IM_INTT_ZETAS_LEN 510

MLD_INTERNAL_DATA_DECLARATION const int32_t
    mld_rv32im_intt_zetas[MLD_RV32IM_INTT_ZETAS_LEN];

#define mld_intt_rv32im_asm MLD_NAMESPACE(intt_rv32im_asm)
void mld_intt_rv32im_asm(int32_t *r, const int32_t *zetas)
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_intt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
);

#endif /* !MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H */
