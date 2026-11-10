/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_NATIVE_RISCV64_SRC_ARITH_NATIVE_RISCV64_H
#define MLD_NATIVE_RISCV64_SRC_ARITH_NATIVE_RISCV64_H

#include "../../../cbmc.h"
#include "../../../common.h"

#define mld_rv64v_ntt_zetas MLD_NAMESPACE(rv64v_ntt_zetas)
#define mld_rv64v_intt_zetas MLD_NAMESPACE(rv64v_intt_zetas)

MLD_INTERNAL_DATA_DECLARATION const int32_t mld_rv64v_ntt_zetas[512];
MLD_INTERNAL_DATA_DECLARATION const int32_t mld_rv64v_intt_zetas[512];

#define mld_ntt_vlen256_riscv64_asm MLD_NAMESPACE(ntt_vlen256_riscv64_asm)
void mld_ntt_vlen256_riscv64_asm(int32_t p[MLDSA_N], const int32_t zetas[512])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_ntt_vlen256_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(p, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv64v_ntt_zetas)
  assigns(memory_slice(p, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  ensures(array_abs_bound(p, 0, MLDSA_N, 94279698))
);

#define mld_ntt_vlen128_riscv64_asm MLD_NAMESPACE(ntt_vlen128_riscv64_asm)
void mld_ntt_vlen128_riscv64_asm(int32_t p[MLDSA_N], const int32_t zetas[512])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_ntt_vlen128_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(p, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv64v_ntt_zetas)
  assigns(memory_slice(p, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  ensures(array_abs_bound(p, 0, MLDSA_N, 94279698))
);

#define mld_intt_vlen256_riscv64_asm MLD_NAMESPACE(intt_vlen256_riscv64_asm)
void mld_intt_vlen256_riscv64_asm(int32_t p[MLDSA_N], const int32_t zetas[512])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_intt_vlen256_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(p, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv64v_intt_zetas)
  assigns(memory_slice(p, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
);

#define mld_intt_vlen128_riscv64_asm MLD_NAMESPACE(intt_vlen128_riscv64_asm)
void mld_intt_vlen128_riscv64_asm(int32_t p[MLDSA_N], const int32_t zetas[512])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_intt_vlen128_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(p, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv64v_intt_zetas)
  assigns(memory_slice(p, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(p, 0, MLDSA_N, MLDSA_Q))
);

#define mld_rej_uniform_riscv64_asm MLD_NAMESPACE(rej_uniform_riscv64_asm)
MLD_MUST_CHECK_RETURN_VALUE
uint64_t mld_rej_uniform_riscv64_asm(int32_t *r, uint64_t len,
                                     const uint8_t *buf, uint64_t buflen)
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_rej_uniform_riscv64_asm.ml */
__contract__(
  requires(len <= MLDSA_N && buflen <= 840 && buflen % 3 == 0)
  requires(memory_no_alias(buf, buflen))
  requires(memory_no_alias(r, sizeof(int32_t) * len))
  assigns(memory_slice(r, sizeof(int32_t) * len))
  ensures(return_value <= len)
  ensures(array_bound(r, 0, (unsigned) return_value, 0, MLDSA_Q))
);

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_ETA == 2
#define mld_rej_uniform_eta2_riscv64_asm \
  MLD_NAMESPACE(rej_uniform_eta2_riscv64_asm)
MLD_MUST_CHECK_RETURN_VALUE
uint64_t mld_rej_uniform_eta2_riscv64_asm(int32_t *r, uint64_t len,
                                          const uint8_t *buf, uint64_t buflen)
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_rej_uniform_eta2_riscv64_asm.ml */
__contract__(
  requires(len <= MLDSA_N && buflen <= 272)
  requires(memory_no_alias(buf, buflen))
  requires(memory_no_alias(r, sizeof(int32_t) * len))
  assigns(memory_slice(r, sizeof(int32_t) * len))
  ensures(return_value <= len)
  ensures(array_abs_bound(r, 0, (unsigned) return_value, 3))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_ETA == 2 */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_ETA == 4
#define mld_rej_uniform_eta4_riscv64_asm \
  MLD_NAMESPACE(rej_uniform_eta4_riscv64_asm)
MLD_MUST_CHECK_RETURN_VALUE
uint64_t mld_rej_uniform_eta4_riscv64_asm(int32_t *r, uint64_t len,
                                          const uint8_t *buf, uint64_t buflen)
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_rej_uniform_eta4_riscv64_asm.ml */
__contract__(
  requires(len <= MLDSA_N && buflen <= 272)
  requires(memory_no_alias(buf, buflen))
  requires(memory_no_alias(r, sizeof(int32_t) * len))
  assigns(memory_slice(r, sizeof(int32_t) * len))
  ensures(return_value <= len)
  ensures(array_abs_bound(r, 0, (unsigned) return_value, 5))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_ETA == 4 */
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
#define mld_poly_decompose_32_riscv64_asm \
  MLD_NAMESPACE(poly_decompose_32_riscv64_asm)
void mld_poly_decompose_32_riscv64_asm(int32_t a1[MLDSA_N], int32_t a0[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_decompose_32_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a1, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(a0, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a0, 0, MLDSA_N, 0, MLDSA_Q))
  assigns(memory_slice(a1, sizeof(int32_t) * MLDSA_N))
  assigns(memory_slice(a0, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 16 == (MLDSA_Q - 1) / (2 * ((MLDSA_Q - 1) / 32)) */
  ensures(array_bound(a1, 0, MLDSA_N, 0, 16))
  /* check-magic: 261889 == (MLDSA_Q - 1) / 32 + 1 */
  ensures(array_abs_bound(a0, 0, MLDSA_N, 261889))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87 */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44
#define mld_poly_decompose_88_riscv64_asm \
  MLD_NAMESPACE(poly_decompose_88_riscv64_asm)
void mld_poly_decompose_88_riscv64_asm(int32_t a1[MLDSA_N], int32_t a0[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_decompose_88_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a1, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(a0, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a0, 0, MLDSA_N, 0, MLDSA_Q))
  assigns(memory_slice(a1, sizeof(int32_t) * MLDSA_N))
  assigns(memory_slice(a0, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 44 == (MLDSA_Q - 1) / (2 * ((MLDSA_Q - 1) / 88)) */
  ensures(array_bound(a1, 0, MLDSA_N, 0, 44))
  /* check-magic: 95233 == (MLDSA_Q - 1) / 88 + 1 */
  ensures(array_abs_bound(a0, 0, MLDSA_N, 95233))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44 \
        */
#endif /* !MLD_CONFIG_NO_SIGN_API */

#define mld_poly_caddq_riscv64_asm MLD_NAMESPACE(poly_caddq_riscv64_asm)
void mld_poly_caddq_riscv64_asm(int32_t a[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_caddq_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(a, 0, MLDSA_N, MLDSA_Q))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(a, 0, MLDSA_N, 0, MLDSA_Q))
);

#if !defined(MLD_CONFIG_NO_VERIFY_API)
#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
#define mld_poly_use_hint_32_riscv64_asm \
  MLD_NAMESPACE(poly_use_hint_32_riscv64_asm)
void mld_poly_use_hint_32_riscv64_asm(int32_t a[MLDSA_N],
                                      const int32_t h[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_use_hint_32_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(h, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_bound(h, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(a, 0, MLDSA_N, 0, 16))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87 */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44
#define mld_poly_use_hint_88_riscv64_asm \
  MLD_NAMESPACE(poly_use_hint_88_riscv64_asm)
void mld_poly_use_hint_88_riscv64_asm(int32_t a[MLDSA_N],
                                      const int32_t h[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_use_hint_88_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(h, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_bound(h, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(a, 0, MLDSA_N, 0, 44))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44 \
        */
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#define mld_poly_chknorm_riscv64_asm MLD_NAMESPACE(poly_chknorm_riscv64_asm)
MLD_MUST_CHECK_RETURN_VALUE
int mld_poly_chknorm_riscv64_asm(const int32_t a[MLDSA_N], int64_t B)
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_poly_chknorm_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(forall(k0, 0, MLDSA_N, a[k0] > INT32_MIN))
  requires(0 <= B && B <= INT32_MAX)
  ensures(return_value == 0 || return_value == 1)
  ensures((return_value == 0) == array_abs_bound(a, 0, MLDSA_N, B))
);

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44
#define mld_polyz_unpack_17_riscv64_asm \
  MLD_NAMESPACE(polyz_unpack_17_riscv64_asm)
void mld_polyz_unpack_17_riscv64_asm(int32_t r[MLDSA_N], const uint8_t buf[576])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_polyz_unpack_17_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(buf, 576))
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(r, 0, MLDSA_N, -((1 << 17) - 1), (1 << 17) + 1))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44 \
        */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
    (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)
#define mld_polyz_unpack_19_riscv64_asm \
  MLD_NAMESPACE(polyz_unpack_19_riscv64_asm)
void mld_polyz_unpack_19_riscv64_asm(int32_t r[MLDSA_N], const uint8_t buf[640])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/mldsa_polyz_unpack_19_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(buf, 640))
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(r, 0, MLDSA_N, -((1 << 19) - 1), (1 << 19) + 1))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87 */
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
    defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
#define mld_poly_pointwise_montgomery_riscv64_asm \
  MLD_NAMESPACE(poly_pointwise_montgomery_riscv64_asm)
void mld_poly_pointwise_montgomery_riscv64_asm(int32_t a[MLDSA_N],
                                               const int32_t b[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification in
 * proofs/hol_light/riscv64/proofs/mldsa_poly_pointwise_montgomery_riscv64_asm.ml.
 */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(b, sizeof(int32_t) * MLDSA_N))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  requires(array_abs_bound(a, 0, MLDSA_N, 94279698))
  requires(array_abs_bound(b, 0, MLDSA_N, 94279698))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(a, 0, MLDSA_N, MLDSA_Q))
);
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API || \
          MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 4
#define mld_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l4_riscv64_asm)
void mld_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm(
    int32_t w[MLDSA_N], const int32_t u[4][MLDSA_N],
    const int32_t v[4][MLDSA_N])
/* This must be kept in sync with the HOL-Light specification in
 * proofs/hol_light/riscv64/proofs/mldsa_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm.ml.
 */
__contract__(
  requires(memory_no_alias(w, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(u, sizeof(int32_t) * 4 * MLDSA_N))
  requires(memory_no_alias(v, sizeof(int32_t) * 4 * MLDSA_N))
  requires(forall(l0, 0, 4, array_bound(u[l0], 0, MLDSA_N, 0, MLDSA_Q)))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  requires(forall(l1, 0, 4, array_abs_bound(v[l1], 0, MLDSA_N, 94279698)))
  assigns(memory_slice(w, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(w, 0, MLDSA_N, MLDSA_Q))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_L == 4 */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 5
#define mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l5_riscv64_asm)
void mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm(
    int32_t w[MLDSA_N], const int32_t u[5][MLDSA_N],
    const int32_t v[5][MLDSA_N])
/* This must be kept in sync with the HOL-Light specification in
 * proofs/hol_light/riscv64/proofs/mldsa_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm.ml.
 */
__contract__(
  requires(memory_no_alias(w, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(u, sizeof(int32_t) * 5 * MLDSA_N))
  requires(memory_no_alias(v, sizeof(int32_t) * 5 * MLDSA_N))
  requires(forall(l0, 0, 5, array_bound(u[l0], 0, MLDSA_N, 0, MLDSA_Q)))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  requires(forall(l1, 0, 5, array_abs_bound(v[l1], 0, MLDSA_N, 94279698)))
  assigns(memory_slice(w, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(w, 0, MLDSA_N, MLDSA_Q))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_L == 5 */

#if defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 7
#define mld_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery_l7_riscv64_asm)
void mld_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm(
    int32_t w[MLDSA_N], const int32_t u[7][MLDSA_N],
    const int32_t v[7][MLDSA_N])
/* This must be kept in sync with the HOL-Light specification in
 * proofs/hol_light/riscv64/proofs/mldsa_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm.ml.
 */
__contract__(
  requires(memory_no_alias(w, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(u, sizeof(int32_t) * 7 * MLDSA_N))
  requires(memory_no_alias(v, sizeof(int32_t) * 7 * MLDSA_N))
  requires(forall(l0, 0, 7, array_bound(u[l0], 0, MLDSA_N, 0, MLDSA_Q)))
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  requires(forall(l1, 0, 7, array_abs_bound(v[l1], 0, MLDSA_N, 94279698)))
  assigns(memory_slice(w, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(w, 0, MLDSA_N, MLDSA_Q))
);
#endif /* MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_L == 7 */

#endif /* !MLD_NATIVE_RISCV64_SRC_ARITH_NATIVE_RISCV64_H */
