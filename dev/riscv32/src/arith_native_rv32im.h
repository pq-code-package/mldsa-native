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

#define mld_ntt_rv32im_fastmul_asm MLD_NAMESPACE(ntt_rv32im_fastmul_asm)
void mld_ntt_rv32im_fastmul_asm(int32_t r[MLDSA_N], const int32_t zetas[510])
/* This must be kept in sync with the HOL-Light subroutine specification in
 * proofs/hol_light/riscv32/proofs/mldsa_ntt_rv32im_asm.ml. */
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

#define mld_ntt_rv32im_slowmul_asm MLD_NAMESPACE(ntt_rv32im_slowmul_asm)
void mld_ntt_rv32im_slowmul_asm(int32_t r[MLDSA_N], const int32_t zetas[510])
/* This must be kept in sync with the HOL-Light subroutine specification in
 * proofs/hol_light/riscv32/proofs/mldsa_ntt_rv32im_slowmul_asm.ml. */
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

#define mld_intt_rv32im_fastmul_asm MLD_NAMESPACE(intt_rv32im_fastmul_asm)
void mld_intt_rv32im_fastmul_asm(int32_t r[MLDSA_N], const int32_t zetas[510])
/* This must be kept in sync with the HOL-Light subroutine specification in
 * proofs/hol_light/riscv32/proofs/mldsa_intt_rv32im_asm.ml. */
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_ntt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
);

#define mld_intt_rv32im_slowmul_asm MLD_NAMESPACE(intt_rv32im_slowmul_asm)
void mld_intt_rv32im_slowmul_asm(int32_t r[MLDSA_N], const int32_t zetas[510])
/* This must be kept in sync with the HOL-Light subroutine specification in
 * proofs/hol_light/riscv32/proofs/mldsa_intt_rv32im_slowmul_asm.ml. */
__contract__(
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  requires(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
  requires(zetas == mld_rv32im_ntt_zetas)
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(array_abs_bound(r, 0, MLDSA_N, MLDSA_Q))
);

#define mld_poly_pointwise_montgomery_rv32im_asm \
  MLD_NAMESPACE(poly_pointwise_montgomery_rv32im_asm)
#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
    defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
void mld_poly_pointwise_montgomery_rv32im_asm(int32_t a[MLDSA_N],
                                              const int32_t b[MLDSA_N])
/* This must be kept in sync with the HOL-Light subroutine specification in
 * proofs/hol_light/riscv32/proofs/
 * mldsa_poly_pointwise_montgomery_rv32im_asm.ml. */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(b, sizeof(int32_t) * MLDSA_N))
  /* This is MLD_NTT_BOUND, the exclusive output bound in the generic C and
   * native forward-NTT contracts and the exclusive input bound in the
   * pointwise-Montgomery contracts. */
  /* check-magic: 94279698 == 9 * ((5 * MLDSA_Q + 3) / 4) */
  requires(array_abs_bound(a, 0, MLDSA_N, 94279698))
  requires(array_abs_bound(b, 0, MLDSA_N, 94279698))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  /* The q-bound is both the pointwise postcondition and the inverse-NTT
   * input precondition in the generic C and native contracts. */
  ensures(array_abs_bound(a, 0, MLDSA_N, MLDSA_Q))
);
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API || \
          MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#define mld_rej_uniform_rv32im_asm MLD_NAMESPACE(rej_uniform_rv32im_asm)
MLD_MUST_CHECK_RETURN_VALUE
unsigned mld_rej_uniform_rv32im_asm(int32_t r[MLDSA_N], const uint8_t *buf,
                                    unsigned buflen)
/* This must be kept in sync with the HOL-Light specification in
 * proofs/hol_light/riscv32/proofs/mldsa_rej_uniform_rv32im_asm.ml. */
__contract__(
  requires(buflen > 0 && buflen % 12 == 0)
  requires(memory_no_alias(buf, buflen))
  requires(memory_no_alias(r, sizeof(int32_t) * MLDSA_N))
  assigns(memory_slice(r, sizeof(int32_t) * MLDSA_N))
  ensures(return_value <= MLDSA_N)
  ensures(array_bound(r, 0, return_value, 0, MLDSA_Q))
);

#if !defined(MLD_CONFIG_NO_SIGN_API)
#define mld_poly_decompose_32_rv32im_asm \
  MLD_NAMESPACE(poly_decompose_32_rv32im_asm)
void mld_poly_decompose_32_rv32im_asm(int32_t a1[MLDSA_N], int32_t a0[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv32/proofs/mldsa_poly_decompose_32_rv32im_asm.ml */
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

#define mld_poly_decompose_88_rv32im_asm \
  MLD_NAMESPACE(poly_decompose_88_rv32im_asm)
void mld_poly_decompose_88_rv32im_asm(int32_t a1[MLDSA_N], int32_t a0[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv32/proofs/mldsa_poly_decompose_88_rv32im_asm.ml */
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
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
#define mld_poly_use_hint_32_rv32im_asm \
  MLD_NAMESPACE(poly_use_hint_32_rv32im_asm)
void mld_poly_use_hint_32_rv32im_asm(int32_t a[MLDSA_N],
                                     const int32_t h[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv32/proofs/mldsa_poly_use_hint_32_rv32im_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(h, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_bound(h, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(a, 0, MLDSA_N, 0, 16))
);

#define mld_poly_use_hint_88_rv32im_asm \
  MLD_NAMESPACE(poly_use_hint_88_rv32im_asm)
void mld_poly_use_hint_88_rv32im_asm(int32_t a[MLDSA_N],
                                     const int32_t h[MLDSA_N])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv32/proofs/mldsa_poly_use_hint_88_rv32im_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(memory_no_alias(h, sizeof(int32_t) * MLDSA_N))
  requires(array_bound(a, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_bound(h, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(a, sizeof(int32_t) * MLDSA_N))
  ensures(array_bound(a, 0, MLDSA_N, 0, 44))
);
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#define mld_poly_chknorm_rv32im_asm MLD_NAMESPACE(poly_chknorm_rv32im_asm)
MLD_MUST_CHECK_RETURN_VALUE
int mld_poly_chknorm_rv32im_asm(const int32_t a[MLDSA_N], int32_t B)
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv32/proofs/mldsa_poly_chknorm_rv32im_asm.ml */
__contract__(
  requires(memory_no_alias(a, sizeof(int32_t) * MLDSA_N))
  requires(0 < B)
  ensures(return_value == 0 || return_value == 1)
  ensures((return_value == 0) == array_abs_bound(a, 0, MLDSA_N, B))
);

/*
 * `array_abs_bound` is exclusive, matching the strict bounds in the forward
 * NTT and pointwise HOL-Light theorems. Its MLDSA_Q form is equivalent to the
 * inclusive `abs <= MLDSA_Q - 1` bound used by the inverse NTT theorems.
 *
 * The assigns clauses give the same caller-visible footprint as HOL-Light:
 * only the 1024-byte output array changes. HOL-Light also tracks the private
 * 16- or 32-byte stack frame used during a call and proves that the stack
 * pointer is restored before return.
 */

#endif /* !MLD_NATIVE_RV32IM_SRC_ARITH_NATIVE_RV32IM_H */
