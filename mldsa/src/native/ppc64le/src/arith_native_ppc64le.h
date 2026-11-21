/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H
#define MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H

#include <stdint.h>
#include "../../../common.h"

#define mld_ntt_p10_ppc64le MLD_NAMESPACE(ntt_p10_ppc64le)
void mld_ntt_p10_ppc64le(int32_t r[MLDSA_N]);

#define mld_intt_p10_ppc64le MLD_NAMESPACE(intt_p10_ppc64le)
void mld_intt_p10_ppc64le(int32_t r[MLDSA_N]);

#define mld_ntt_p8p9_ppc64le MLD_NAMESPACE(ntt_p8p9_ppc64le)
void mld_ntt_p8p9_ppc64le(int32_t r[MLDSA_N]);

#define mld_intt_p8p9_ppc64le MLD_NAMESPACE(intt_p8p9_ppc64le)
void mld_intt_p8p9_ppc64le(int32_t r[MLDSA_N]);

#define mld_poly_pointwise_montgomery_p10_ppc64le \
  MLD_NAMESPACE(poly_pointwise_montgomery_p10_ppc64le)
void mld_poly_pointwise_montgomery_p10_ppc64le(int32_t *a, const int32_t *b);

#define mld_poly_pointwise_montgomery_p8p9_ppc64le \
  MLD_NAMESPACE(poly_pointwise_montgomery_p8p9_ppc64le)
void mld_poly_pointwise_montgomery_p8p9_ppc64le(int32_t *a, const int32_t *b);

#define mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l4_ppc64le)
void mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N]);

#define mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l5_ppc64le)
void mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N]);

#define mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l7_ppc64le)
void mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N]);


#endif /* !MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H */
