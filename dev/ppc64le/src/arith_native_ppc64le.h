/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H
#define MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H

#include "../../../common.h"
#include "../../../params.h"

#define mld_poly_caddq_ppc64le_asm MLD_NAMESPACE(poly_caddq_ppc64le_asm)
void mld_poly_caddq_ppc64le_asm(int32_t a[MLDSA_N]);


#define mld_poly_pointwise_montgomery_ppc64le_asm \
  MLD_NAMESPACE(poly_pointwise_montgomery_ppc64le_asm)
void mld_poly_pointwise_montgomery_ppc64le_asm(int32_t a[MLDSA_N],
                                               const int32_t b[MLDSA_N]);

#define mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l4_ppc64le_asm)
void mld_polyvecl_pointwise_acc_montgomery_l4_ppc64le_asm(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N]);

#define mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l5_ppc64le_asm)
void mld_polyvecl_pointwise_acc_montgomery_l5_ppc64le_asm(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N]);

#define mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l7_ppc64le_asm)
void mld_polyvecl_pointwise_acc_montgomery_l7_ppc64le_asm(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N]);

#define mld_ppc64le_zetas MLD_NAMESPACE(ppc64le_zetas)
extern const int32_t mld_ppc64le_zetas[MLDSA_N];

#define mld_ntt_ppc64le_asm MLD_NAMESPACE(ntt_ppc64le_asm)
void mld_ntt_ppc64le_asm(int32_t *a, const int32_t *zetas);

#define mld_intt_ppc64le_asm MLD_NAMESPACE(intt_ppc64le_asm)
void mld_intt_ppc64le_asm(int32_t *a, const int32_t *zetas);

#endif
