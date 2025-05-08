/*
 * Copyright (c) 2025 The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0
 */
#ifndef MLD_POLYVEC_H
#define MLD_POLYVEC_H

#include <stdint.h>
#include "cbmc.h"
#include "common.h"
#include "poly.h"

/* Vectors of polynomials of length MLDSA_L */
typedef struct
{
  poly vec[MLDSA_L];
} polyvecl;

#define polyvecl_uniform_eta MLD_NAMESPACE(polyvecl_uniform_eta)
/*************************************************
 * Name:        polyvecl_uniform_eta
 *
 * Description: Sample vector of polynomials with uniformly random coefficients
 *              in [-MLDSA_ETA, MLDSA_ETA] by performing rejection sampling on
 *              the output stream from SHAKE256(seed|nonce). The vector has
 *              MLDSA_L polynomials.
 *
 * Arguments:   - polyvecl *v: pointer to output polynomial vector
 *              - const uint8_t seed[]: byte array with seed of length
 *                MLDSA_CRHBYTES
 *              - uint16_t nonce: 2-byte nonce
 **************************************************/
void polyvecl_uniform_eta(polyvecl *v, const uint8_t seed[MLDSA_CRHBYTES],
                          uint16_t nonce)
__contract__(
  requires(memory_no_alias(v, sizeof(polyvecl)))
  requires(memory_no_alias(seed, MLDSA_CRHBYTES))
  assigns(memory_slice(v, sizeof(polyvecl)))
  ensures(forall(k0, 0, MLDSA_L,
    array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_ETA + 1)))
);

#define polyvecl_uniform_gamma1 MLD_NAMESPACE(polyvecl_uniform_gamma1)
void polyvecl_uniform_gamma1(polyvecl *v, const uint8_t seed[MLDSA_CRHBYTES],
                             uint16_t nonce);

#define polyvecl_reduce MLD_NAMESPACE(polyvecl_reduce)
/*************************************************
 * Name:        polyvecl_reduce
 *
 * Description: Inplace reduction of all coefficients of all polynomial in a
 *              vector of length MLDSA_L to
 *              representative in [-6283008,6283008].
 *
 * Arguments:   - poly *v: pointer to input/output vector
 **************************************************/
void polyvecl_reduce(polyvecl *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyvecl)))
  requires(forall(k0, 0, MLDSA_L,
    array_bound(v->vec[k0].coeffs, 0, MLDSA_N, INT32_MIN, REDUCE_DOMAIN_MAX)))
  assigns(memory_slice(v, sizeof(polyvecl)))
  ensures(forall(k1, 0, MLDSA_L,
    array_bound(v->vec[k1].coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX)))
);

#define polyvecl_add MLD_NAMESPACE(polyvecl_add)
/*************************************************
 * Name:        polyvecl_add
 *
 * Description: Add vectors of polynomials of length MLDSA_L.
 *              No modular reduction is performed.
 *
 * Arguments:   - polyvecl *w: pointer to output vector
 *              - const polyvecl *u: pointer to first summand
 *              - const polyvecl *v: pointer to second summand
 **************************************************/
void polyvecl_add(polyvecl *w, const polyvecl *u, const polyvecl *v)
__contract__(
  requires(memory_no_alias(w, sizeof(polyvecl)))
  requires(memory_no_alias(u, sizeof(polyvecl)))
  requires(memory_no_alias(v, sizeof(polyvecl)))
  requires(forall(k0, 0, MLDSA_L,
    forall(k1, 0, MLDSA_N, (int64_t) u->vec[k0].coeffs[k1] + v->vec[k0].coeffs[k1] <= INT32_MAX)))
  requires(forall(k2, 0, MLDSA_L,
    forall(k3, 0, MLDSA_N, (int64_t) u->vec[k2].coeffs[k3] + v->vec[k2].coeffs[k3] >= INT32_MIN)))
  assigns(memory_slice(w, sizeof(polyvecl)))
);

#define polyvecl_ntt MLD_NAMESPACE(polyvecl_ntt)
/*************************************************
 * Name:        polyvecl_ntt
 *
 * Description: Forward NTT of all polynomials in vector of length MLDSA_L.
 *              Coefficients can grow by 8*MLDSA_Q in absolute value.
 *
 * Arguments:   - polyvecl *v: pointer to input/output vector
 **************************************************/
void polyvecl_ntt(polyvecl *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyvecl)))
  requires(forall(k0, 0, MLDSA_L, array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
  assigns(memory_slice(v, sizeof(polyvecl)))
  ensures(forall(k1, 0, MLDSA_L, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
);

#define polyvecl_invntt_tomont MLD_NAMESPACE(polyvecl_invntt_tomont)
/*************************************************
 * Name:        polyvecl_invntt_tomont
 *
 * Description: Inplace inverse NTT and multiplication by 2^{32}.
 *              Input coefficients need to be less than MLDSA_Q in absolute
 *              value and output coefficients are again bounded by MLDSA_Q.
 *
 * Arguments:   - polyvecl *v: pointer to input/output vector
 **************************************************/
void polyvecl_invntt_tomont(polyvecl *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyvecl)))
  requires(forall(k0, 0, MLDSA_L, array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
  assigns(memory_slice(v, sizeof(polyvecl)))
  ensures(forall(k1, 0, MLDSA_L, array_abs_bound(v->vec[k1].coeffs, 0 , MLDSA_N, MLDSA_Q)))
);

#define polyvecl_pointwise_poly_montgomery \
  MLD_NAMESPACE(polyvecl_pointwise_poly_montgomery)
/*************************************************
 * Name:        polyvecl_pointwise_poly_montgomery
 *
 * Description: Pointwise multiplication of a polynomial vector of length
 *              MLDSA_L by a single polynomial in NTT domain and multiplication
 *              of the resulting polynomial vector by 2^{-32}.
 *
 * Arguments:   - polyvecl *r: pointer to output vector
 *              - poly *a: pointer to input polynomial
 *              - polyvecl *v: pointer to input vector
 **************************************************/
void polyvecl_pointwise_poly_montgomery(polyvecl *r, const poly *a,
                                        const polyvecl *v)
__contract__(
  requires(memory_no_alias(r, sizeof(polyvecl)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(v, sizeof(polyvecl)))
  assigns(memory_slice(r, sizeof(polyvecl)))
);

#define polyvecl_pointwise_acc_montgomery \
  MLD_NAMESPACE(polyvecl_pointwise_acc_montgomery)
/*************************************************
 * Name:        polyvecl_pointwise_acc_montgomery
 *
 * Description: Pointwise multiply vectors of polynomials of length MLDSA_L,
 *multiply resulting vector by 2^{-32} and add (accumulate) polynomials in it.
 *Input/output vectors are in NTT domain representation.
 *
 * Arguments:   - poly *w: output polynomial
 *              - const polyvecl *u: pointer to first input vector
 *              - const polyvecl *v: pointer to second input vector
 **************************************************/
void polyvecl_pointwise_acc_montgomery(poly *w, const polyvecl *u,
                                       const polyvecl *v);


#define polyvecl_chknorm MLD_NAMESPACE(polyvecl_chknorm)
/*************************************************
 * Name:        polyvecl_chknorm
 *
 * Description: Check infinity norm of polynomials in vector of length MLDSA_L.
 *              Assumes input polyvecl to be reduced by polyvecl_reduce().
 *
 * Arguments:   - const polyvecl *v: pointer to vector
 *              - int32_t B: norm bound
 *
 * Returns 0 if norm of all polynomials is strictly smaller than B <=
 *(MLDSA_Q-1)/8 and 1 otherwise.
 **************************************************/
int polyvecl_chknorm(const polyvecl *v, int32_t B);



/* Vectors of polynomials of length MLDSA_K */
typedef struct
{
  poly vec[MLDSA_K];
} polyveck;

#define polyveck_uniform_eta MLD_NAMESPACE(polyveck_uniform_eta)
void polyveck_uniform_eta(polyveck *v, const uint8_t seed[MLDSA_CRHBYTES],
                          uint16_t nonce);

#define polyveck_reduce MLD_NAMESPACE(polyveck_reduce)
/*************************************************
 * Name:        polyveck_reduce
 *
 * Description: Reduce coefficients of polynomials in vector of length MLDSA_K
 *              to representatives in [-6283008,6283008].
 *
 * Arguments:   - polyveck *v: pointer to input/output vector
 **************************************************/
void polyveck_reduce(polyveck *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(v->vec[k0].coeffs, 0, MLDSA_N, INT32_MIN, REDUCE_DOMAIN_MAX)))
  assigns(memory_slice(v, sizeof(polyveck)))
  ensures(forall(k1, 0, MLDSA_K,
    array_bound(v->vec[k1].coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX)))
);

#define polyveck_caddq MLD_NAMESPACE(polyveck_caddq)
/*************************************************
 * Name:        polyveck_caddq
 *
 * Description: For all coefficients of polynomials in vector of length MLDSA_K
 *              add MLDSA_Q if coefficient is negative.
 *
 * Arguments:   - polyveck *v: pointer to input/output vector
 **************************************************/
void polyveck_caddq(polyveck *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
  assigns(memory_slice(v, sizeof(polyveck)))
  ensures(forall(k1, 0, MLDSA_K,
    array_bound(v->vec[k1].coeffs, 0, MLDSA_N, 0, MLDSA_Q)))
);

#define polyveck_add MLD_NAMESPACE(polyveck_add)
/*************************************************
 * Name:        polyveck_add
 *
 * Description: Add vectors of polynomials of length MLDSA_K.
 *              No modular reduction is performed.
 *
 * Arguments:   - polyveck *w: pointer to output vector
 *              - const polyveck *u: pointer to first summand
 *              - const polyveck *v: pointer to second summand
 **************************************************/
void polyveck_add(polyveck *w, const polyveck *u, const polyveck *v)
__contract__(
  requires(memory_no_alias(w, sizeof(polyveck)))
  requires(memory_no_alias(u, sizeof(polyveck)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    forall(k1, 0, MLDSA_N, (int64_t) u->vec[k0].coeffs[k1] + v->vec[k0].coeffs[k1] <= INT32_MAX)))
  requires(forall(k2, 0, MLDSA_K,
    forall(k3, 0, MLDSA_N, (int64_t) u->vec[k2].coeffs[k3] + v->vec[k2].coeffs[k3] >= INT32_MIN)))
  assigns(memory_slice(w, sizeof(polyveck)))
);

#define polyveck_sub MLD_NAMESPACE(polyveck_sub)
/*************************************************
 * Name:        polyveck_sub
 *
 * Description: Subtract vectors of polynomials of length MLDSA_K.
 *              No modular reduction is performed.
 *
 * Arguments:   - polyveck *w: pointer to output vector
 *              - const polyveck *u: pointer to first input vector
 *              - const polyveck *v: pointer to second input vector to be
 *                                   subtracted from first input vector
 **************************************************/
void polyveck_sub(polyveck *w, const polyveck *u, const polyveck *v)
__contract__(
  requires(memory_no_alias(w, sizeof(polyveck)))
  requires(memory_no_alias(u, sizeof(polyveck)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    forall(k1, 0, MLDSA_N, (int64_t) u->vec[k0].coeffs[k1] - v->vec[k0].coeffs[k1] <= INT32_MAX)))
  requires(forall(k2, 0, MLDSA_K,
    forall(k3, 0, MLDSA_N, (int64_t) u->vec[k2].coeffs[k3] - v->vec[k2].coeffs[k3] >= INT32_MIN)))
  assigns(memory_slice(w, sizeof(polyveck)))
);

#define polyveck_shiftl MLD_NAMESPACE(polyveck_shiftl)
/*************************************************
 * Name:        polyveck_shiftl
 *
 * Description: Multiply vector of polynomials of Length MLDSA_K by 2^MLDSA_D
 *without modular reduction. Assumes input coefficients to be less than
 *2^{31-MLDSA_D}.
 *
 * Arguments:   - polyveck *v: pointer to input/output vector
 **************************************************/
void polyveck_shiftl(polyveck *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K, array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, 1 << (31 - MLDSA_D))))
  assigns(memory_slice(v, sizeof(polyveck)))
);

#define polyveck_ntt MLD_NAMESPACE(polyveck_ntt)
/*************************************************
 * Name:        polyveck_ntt
 *
 * Description: Forward NTT of all polynomials in vector of length MLDSA_K.
 *              Coefficients can grow by 8*MLDSA_Q in absolute value.
 *
 * Arguments:   - polyveck *v: pointer to input/output vector
 **************************************************/
void polyveck_ntt(polyveck *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K, array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
  assigns(memory_slice(v, sizeof(polyveck)))
  ensures(forall(k1, 0, MLDSA_K, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
);

#define polyveck_invntt_tomont MLD_NAMESPACE(polyveck_invntt_tomont)
/*************************************************
 * Name:        polyveck_invntt_tomont
 *
 * Description: Inverse NTT and multiplication by 2^{32} of polynomials
 *              in vector of length MLDSA_K. Input coefficients need to be less
 *              than 2*MLDSA_Q.
 *
 * Arguments:   - polyveck *v: pointer to input/output vector
 **************************************************/
void polyveck_invntt_tomont(polyveck *v)
__contract__(
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K, array_abs_bound(v->vec[k0].coeffs, 0, MLDSA_N, MLDSA_Q)))
  assigns(memory_slice(v, sizeof(polyveck)))
  ensures(forall(k1, 0, MLDSA_K, array_abs_bound(v->vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
);

#define polyveck_pointwise_poly_montgomery \
  MLD_NAMESPACE(polyveck_pointwise_poly_montgomery)
/*************************************************
 * Name:        polyveck_pointwise_poly_montgomery
 *
 * Description: Pointwise multiplication of a polynomial vector of length
 *              MLDSA_K by a single polynomial in NTT domain and multiplication
 *              of the resulting polynomial vector by 2^{-32}.
 *
 * Arguments:   - polyveck *r: pointer to output vector
 *              - poly *a: pointer to input polynomial
 *              - polyveck *v: pointer to input vector
 **************************************************/
void polyveck_pointwise_poly_montgomery(polyveck *r, const poly *a,
                                        const polyveck *v)
__contract__(
  requires(memory_no_alias(r, sizeof(polyveck)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  assigns(memory_slice(r, sizeof(polyveck)))
);

#define polyveck_chknorm MLD_NAMESPACE(polyveck_chknorm)
/*************************************************
 * Name:        polyveck_chknorm
 *
 * Description: Check infinity norm of polynomials in vector of length MLDSA_K.
 *              Assumes input polyveck to be reduced by polyveck_reduce().
 *
 * Arguments:   - const polyveck *v: pointer to vector
 *              - int32_t B: norm bound
 *
 * Returns 0 if norm of all polynomials are strictly smaller than B <=
 *(MLDSA_Q-1)/8 and 1 otherwise.
 **************************************************/
int polyveck_chknorm(const polyveck *v, int32_t B);

#define polyveck_power2round MLD_NAMESPACE(polyveck_power2round)
/*************************************************
 * Name:        polyveck_power2round
 *
 * Description: For all coefficients a of polynomials in vector of length
 *MLDSA_K, compute a0, a1 such that a mod^+ MLDSA_Q = a1*2^MLDSA_D + a0 with
 *-2^{MLDSA_D-1} < a0 <= 2^{MLDSA_D-1}. Assumes coefficients to be standard
 *representatives.
 *
 * Arguments:   - polyveck *v1: pointer to output vector of polynomials with
 *                              coefficients a1
 *              - polyveck *v0: pointer to output vector of polynomials with
 *                              coefficients a0
 *              - const polyveck *v: pointer to input vector
 **************************************************/
void polyveck_power2round(polyveck *v1, polyveck *v0, const polyveck *v)
__contract__(
  requires(memory_no_alias(v1, sizeof(polyveck)))
  requires(memory_no_alias(v0, sizeof(polyveck)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K, array_bound(v->vec[k0].coeffs, 0, MLDSA_N, 0, MLDSA_Q)))
  assigns(memory_slice(v1, sizeof(polyveck)))
  assigns(memory_slice(v0, sizeof(polyveck)))
  ensures(forall(k1, 0, MLDSA_K, array_bound(v0->vec[k1].coeffs, 0, MLDSA_N, -(MLD_2_POW_D/2)+1, (MLD_2_POW_D/2)+1)))
  ensures(forall(k2, 0, MLDSA_K, array_bound(v1->vec[k2].coeffs, 0, MLDSA_N, 0, (MLD_2_POW_D/2)+1)))
);

#define polyveck_decompose MLD_NAMESPACE(polyveck_decompose)
/*************************************************
 * Name:        polyveck_decompose
 *
 * Description: For all coefficients a of polynomials in vector of length
 *MLDSA_K, compute high and low bits a0, a1 such a mod^+ MLDSA_Q = a1*ALPHA
 *+ a0 with -ALPHA/2 < a0 <= ALPHA/2 except a1 = (MLDSA_Q-1)/ALPHA where we set
 *a1 = 0 and -ALPHA/2 <= a0 = a mod MLDSA_Q - MLDSA_Q < 0. Assumes coefficients
 *to be standard representatives.
 *
 * Arguments:   - polyveck *v1: pointer to output vector of polynomials with
 *                              coefficients a1
 *              - polyveck *v0: pointer to output vector of polynomials with
 *                              coefficients a0
 *              - const polyveck *v: pointer to input vector
 **************************************************/
void polyveck_decompose(polyveck *v1, polyveck *v0, const polyveck *v)
__contract__(
  requires(memory_no_alias(v1,  sizeof(polyveck)))
  requires(memory_no_alias(v0, sizeof(polyveck)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(v->vec[k0].coeffs, 0, MLDSA_N, 0, MLDSA_Q)))
  assigns(object_whole(v1))
  assigns(object_whole(v0))
  ensures(forall(k1, 0, MLDSA_K,
                 array_bound(v1->vec[k1].coeffs, 0, MLDSA_N, 0, (MLDSA_Q-1)/(2*MLDSA_GAMMA2)) &&
                 array_abs_bound(v0->vec[k1].coeffs, 0, MLDSA_N, MLDSA_GAMMA2+1)))
);

#define polyveck_make_hint MLD_NAMESPACE(polyveck_make_hint)
/*************************************************
 * Name:        polyveck_make_hint
 *
 * Description: Compute hint vector.
 *
 * Arguments:   - polyveck *h: pointer to output vector
 *              - const polyveck *v0: pointer to low part of input vector
 *              - const polyveck *v1: pointer to high part of input vector
 *
 * Returns number of 1 bits.
 **************************************************/
unsigned int polyveck_make_hint(polyveck *h, const polyveck *v0,
                                const polyveck *v1)
__contract__(
  requires(memory_no_alias(h,  sizeof(polyveck)))
  requires(memory_no_alias(v0, sizeof(polyveck)))
  requires(memory_no_alias(v1, sizeof(polyveck)))
  assigns(object_whole(h))
  ensures(return_value <= MLDSA_N * MLDSA_K)
);

#define polyveck_use_hint MLD_NAMESPACE(polyveck_use_hint)
/*************************************************
 * Name:        polyveck_use_hint
 *
 * Description: Use hint vector to correct the high bits of input vector.
 *
 * Arguments:   - polyveck *w: pointer to output vector of polynomials with
 *                             corrected high bits
 *              - const polyveck *u: pointer to input vector
 *              - const polyveck *h: pointer to input hint vector
 **************************************************/
void polyveck_use_hint(polyveck *w, const polyveck *v, const polyveck *h)
__contract__(
  requires(memory_no_alias(w,  sizeof(polyveck)))
  requires(memory_no_alias(v, sizeof(polyveck)))
  requires(memory_no_alias(h, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(v->vec[k0].coeffs, 0, MLDSA_N, 0, MLDSA_Q)))
  requires(forall(k1, 0, MLDSA_K,
    array_bound(h->vec[k1].coeffs, 0, MLDSA_N, 0, 2)))
  assigns(memory_slice(w, sizeof(polyveck)))
  requires(forall(k2, 0, MLDSA_K,
    array_bound(w->vec[k2].coeffs, 0, MLDSA_N, 0, (MLDSA_Q-1)/(2*MLDSA_GAMMA2))))
);

#define polyveck_pack_w1 MLD_NAMESPACE(polyveck_pack_w1)
/*************************************************
 * Name:        polyveck_pack_w1
 *
 * Description: Bit-pack polynomial vector w1 with coefficients in [0,15] or
 *              [0,43].
 *              Input coefficients are assumed to be standard representatives.
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_K* MLDSA_POLYW1_PACKEDBYTES bytes
 *              - const polyveck *a: pointer to input polynomial vector
 **************************************************/
void polyveck_pack_w1(uint8_t r[MLDSA_K * MLDSA_POLYW1_PACKEDBYTES],
                      const polyveck *w1)
#if MLDSA_MODE == 2
__contract__(
  requires(memory_no_alias(r, MLDSA_K * MLDSA_POLYW1_PACKEDBYTES))
  requires(memory_no_alias(w1, sizeof(polyveck)))
  requires(forall(k1, 0, MLDSA_K,
    array_bound(w1->vec[k1].coeffs, 0, MLDSA_N, 0, 44)))
  assigns(object_whole(r)));
#else  /* MLDSA_MODE == 2 */
__contract__(
  requires(memory_no_alias(r, MLDSA_K * MLDSA_POLYW1_PACKEDBYTES))
  requires(memory_no_alias(w1, sizeof(polyveck)))
  requires(forall(k1, 0, MLDSA_K,
    array_bound(w1->vec[k1].coeffs, 0, MLDSA_N, 0, 16)))
  assigns(object_whole(r)));
#endif /* MLDSA_MODE != 2 */


#define polyveck_pack_eta MLD_NAMESPACE(polyveck_pack_eta)
void polyveck_pack_eta(uint8_t r[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES],
                       const polyveck *p)
__contract__(
  requires(memory_no_alias(r,  MLDSA_K * MLDSA_POLYETA_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyveck)))
  requires(forall(k1, 0, MLDSA_K,
    array_abs_bound(p->vec[k1].coeffs, 0, MLDSA_N, MLDSA_ETA + 1)))
  assigns(object_whole(r))
);

#define polyvecl_pack_eta MLD_NAMESPACE(polyvecl_pack_eta)
void polyvecl_pack_eta(uint8_t r[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES],
                       const polyvecl *p)
__contract__(
  requires(memory_no_alias(r,  MLDSA_L * MLDSA_POLYETA_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyvecl)))
  requires(forall(k1, 0, MLDSA_L,
    array_abs_bound(p->vec[k1].coeffs, 0, MLDSA_N, MLDSA_ETA + 1)))
  assigns(object_whole(r))
);

#define polyvecl_pack_z MLD_NAMESPACE(polyvecl_pack_z)
void polyvecl_pack_z(uint8_t r[MLDSA_L * MLDSA_POLYZ_PACKEDBYTES],
                     const polyvecl *p)
__contract__(
  requires(memory_no_alias(r,  MLDSA_L * MLDSA_POLYZ_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyvecl)))
  requires(forall(k1, 0, MLDSA_L,
                  array_bound(p->vec[k1].coeffs, 0, MLDSA_N, -(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1 + 1)))
  assigns(object_whole(r))
);

#define polyveck_pack_t0 MLD_NAMESPACE(polyveck_pack_t0)
void polyveck_pack_t0(uint8_t r[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES],
                      const polyveck *p)
__contract__(
  requires(memory_no_alias(r,  MLDSA_K * MLDSA_POLYT0_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(p->vec[k0].coeffs, 0, MLDSA_N, -(1<<(MLDSA_D-1)) + 1, (1<<(MLDSA_D-1)) + 1)))
  assigns(object_whole(r))
);

#define polyvecl_unpack_eta MLD_NAMESPACE(polyvecl_unpack_eta)
void polyvecl_unpack_eta(polyvecl *p,
                         const uint8_t r[MLDSA_L * MLDSA_POLYETA_PACKEDBYTES])
__contract__(
  requires(memory_no_alias(r,  MLDSA_L * MLDSA_POLYETA_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyvecl)))
  assigns(object_whole(p))
  ensures(forall(k1, 0, MLDSA_L,
    array_bound(p->vec[k1].coeffs, 0, MLDSA_N, MLD_POLYETA_UNPACK_LOWER_BOUND, MLDSA_ETA + 1)))
);

#define polyvecl_unpack_z MLD_NAMESPACE(polyvecl_unpack_z)
void polyvecl_unpack_z(polyvecl *z,
                       const uint8_t r[MLDSA_L * MLDSA_POLYZ_PACKEDBYTES])
__contract__(
  requires(memory_no_alias(r,  MLDSA_L * MLDSA_POLYZ_PACKEDBYTES))
  requires(memory_no_alias(z, sizeof(polyvecl)))
  assigns(object_whole(z))
  ensures(forall(k1, 0, MLDSA_L,
    array_bound(z->vec[k1].coeffs, 0, MLDSA_N, -(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1 + 1)))
);

#define polyveck_unpack_eta MLD_NAMESPACE(polyveck_unpack_eta)
void polyveck_unpack_eta(polyveck *p,
                         const uint8_t r[MLDSA_K * MLDSA_POLYETA_PACKEDBYTES])
__contract__(
  requires(memory_no_alias(r,  MLDSA_K * MLDSA_POLYETA_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyveck)))
  assigns(object_whole(p))
  ensures(forall(k1, 0, MLDSA_K,
    array_bound(p->vec[k1].coeffs, 0, MLDSA_N, MLD_POLYETA_UNPACK_LOWER_BOUND, MLDSA_ETA + 1)))
);

#define polyveck_unpack_t0 MLD_NAMESPACE(polyveck_unpack_t0)
void polyveck_unpack_t0(polyveck *p,
                        const uint8_t r[MLDSA_K * MLDSA_POLYT0_PACKEDBYTES])
__contract__(
  requires(memory_no_alias(r,  MLDSA_K * MLDSA_POLYT0_PACKEDBYTES))
  requires(memory_no_alias(p, sizeof(polyveck)))
  assigns(object_whole(p))
  ensures(forall(k1, 0, MLDSA_K,
    array_bound(p->vec[k1].coeffs, 0, MLDSA_N, -(1<<(MLDSA_D-1)) + 1, (1<<(MLDSA_D-1)) + 1)))
);

#define polyvec_matrix_expand MLD_NAMESPACE(polyvec_matrix_expand)
/*************************************************
 * Name:        polyvec_matrix_expand
 *
 * Description: Implementation of ExpandA. Generates matrix A with uniformly
 *              random coefficients a_{i,j} by performing rejection
 *              sampling on the output stream of SHAKE128(rho|j|i)
 *
 * Arguments:   - polyvecl mat[MLDSA_K]: output matrix
 *              - const uint8_t rho[]: byte array containing seed rho
 **************************************************/
void polyvec_matrix_expand(polyvecl mat[MLDSA_K],
                           const uint8_t rho[MLDSA_SEEDBYTES]);

#define polyvec_matrix_pointwise_montgomery \
  MLD_NAMESPACE(polyvec_matrix_pointwise_montgomery)
void polyvec_matrix_pointwise_montgomery(polyveck *t,
                                         const polyvecl mat[MLDSA_K],
                                         const polyvecl *v);

#endif /* !MLD_POLYVEC_H */
