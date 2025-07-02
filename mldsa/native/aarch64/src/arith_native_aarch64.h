/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_AARCH64_SRC_ARITH_NATIVE_AARCH64_H
#define MLD_NATIVE_AARCH64_SRC_ARITH_NATIVE_AARCH64_H

#include <stdint.h>
#include "../../../common.h"

#define mld_aarch64_ntt_zetas_layer123456 \
  MLD_NAMESPACE(mld_aarch64_ntt_zetas_layer123456)
#define mld_aarch64_ntt_zetas_layer78 \
  MLD_NAMESPACE(mld_aarch64_ntt_zetas_layer78)

#define mld_aarch64_intt_zetas_layer78 \
  MLD_NAMESPACE(mld_aarch64_intt_zetas_layer78)
#define mld_aarch64_intt_zetas_layer123456 \
  MLD_NAMESPACE(mld_aarch64_intt_zetas_layer123456)

extern const int32_t mld_aarch64_ntt_zetas_layer123456[];
extern const int32_t mld_aarch64_ntt_zetas_layer78[];

extern const int32_t mld_aarch64_intt_zetas_layer78[];
extern const int32_t mld_aarch64_intt_zetas_layer123456[];

#define mld_ntt_asm MLD_NAMESPACE(ntt_asm)
void mld_ntt_asm(int32_t *, const int32_t *, const int32_t *);

#define mld_intt_asm MLD_NAMESPACE(intt_asm)
void mld_intt_asm(int32_t *, const int32_t *, const int32_t *);

#define mld_pointwise_montgomery_asm MLD_NAMESPACE(mld_pointwise_montgomery_asm)
void mld_pointwise_montgomery_asm(int32_t *, const int32_t *, const int32_t *);

#endif /* !MLD_NATIVE_AARCH64_SRC_ARITH_NATIVE_AARCH64_H */
