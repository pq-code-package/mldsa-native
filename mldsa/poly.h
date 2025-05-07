/*
 * Copyright (c) 2025 The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0
 */
#ifndef MLD_POLY_H
#define MLD_POLY_H

#include <stdint.h>
#include "cbmc.h"
#include "common.h"
#include "ntt.h"
#include "reduce.h"
#include "rounding.h"

typedef struct
{
  int32_t coeffs[MLDSA_N];
} poly;

#define poly_reduce MLD_NAMESPACE(poly_reduce)
/*************************************************
 * Name:        poly_reduce
 *
 * Description: Inplace reduction of all coefficients of polynomial to
 *              representative in [-6283008,6283008].
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_reduce(poly *a)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, INT32_MIN, REDUCE_DOMAIN_MAX))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_bound(a->coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX))
);

#define poly_caddq MLD_NAMESPACE(poly_caddq)
/*************************************************
 * Name:        poly_caddq
 *
 * Description: For all coefficients of in/out polynomial add MLDSA_Q if
 *              coefficient is negative.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_caddq(poly *a)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_Q))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_bound(a->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
);

#define poly_add MLD_NAMESPACE(poly_add)
/*************************************************
 * Name:        poly_add
 *
 * Description: Add polynomials. No modular reduction is performed.
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const poly *a: pointer to first summand
 *              - const poly *b: pointer to second summand
 **************************************************/
void poly_add(poly *c, const poly *a, const poly *b)
__contract__(
  requires(memory_no_alias(c, sizeof(poly)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(b, sizeof(poly)))
  requires(forall(k0, 0, MLDSA_N, (int64_t) a->coeffs[k0] + b->coeffs[k0] <= INT32_MAX))
  requires(forall(k1, 0, MLDSA_N, (int64_t) a->coeffs[k1] + b->coeffs[k1] >= INT32_MIN))
  assigns(memory_slice(c, sizeof(poly)))
);

#define poly_sub MLD_NAMESPACE(poly_sub)
/*************************************************
 * Name:        poly_sub
 *
 * Description: Subtract polynomials. No modular reduction is
 *              performed.
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const poly *a: pointer to first input polynomial
 *              - const poly *b: pointer to second input polynomial to be
 *                               subtraced from first input polynomial
 **************************************************/
void poly_sub(poly *c, const poly *a, const poly *b)
__contract__(
  requires(memory_no_alias(c, sizeof(poly)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(b, sizeof(poly)))
  requires(forall(k0, 0, MLDSA_N, (int64_t) a->coeffs[k0] - b->coeffs[k0] <= INT32_MAX))
  requires(forall(k1, 0, MLDSA_N, (int64_t) a->coeffs[k1] - b->coeffs[k1] >= INT32_MIN))
  assigns(memory_slice(c, sizeof(poly))));

#define poly_shiftl MLD_NAMESPACE(poly_shiftl)
/*************************************************
 * Name:        poly_shiftl
 *
 * Description: Multiply polynomial by 2^MLDSA_D without modular reduction.
 *Assumes input coefficients to be less than 2^{31-MLDSA_D} in absolute value.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_shiftl(poly *a)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_abs_bound(a->coeffs, 0, MLDSA_N, 1 << (31 - MLDSA_D)))
  assigns(memory_slice(a, sizeof(poly)))
);

#define poly_ntt MLD_NAMESPACE(poly_ntt)
/*************************************************
 * Name:        poly_ntt
 *
 * Description: Inplace forward NTT. Coefficients can grow by
 *              8*MLDSA_Q in absolute value.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_ntt(poly *a)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_Q))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_abs_bound(a->coeffs, 0, MLDSA_N, MLD_NTT_BOUND))
);


#define poly_invntt_tomont MLD_NAMESPACE(poly_invntt_tomont)
/*************************************************
 * Name:        poly_invntt_tomont
 *
 * Description: Inplace inverse NTT and multiplication by 2^{32}.
 *              Input coefficients need to be less than MLDSA_Q in absolute
 *              value and output coefficients are again bounded by MLDSA_Q.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_invntt_tomont(poly *a)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_Q))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_Q))
);

#define poly_pointwise_montgomery MLD_NAMESPACE(poly_pointwise_montgomery)
/*************************************************
 * Name:        poly_pointwise_montgomery
 *
 * Description: Pointwise multiplication of polynomials in NTT domain
 *              representation and multiplication of resulting polynomial
 *              by 2^{-32}.
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const poly *a: pointer to first input polynomial
 *              - const poly *b: pointer to second input polynomial
 **************************************************/
void poly_pointwise_montgomery(poly *c, const poly *a, const poly *b)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(b, sizeof(poly)))
  requires(memory_no_alias(c, sizeof(poly)))
  assigns(memory_slice(c, sizeof(poly)))
);

#define poly_power2round MLD_NAMESPACE(poly_power2round)
/*************************************************
 * Name:        poly_power2round
 *
 * Description: For all coefficients c of the input polynomial,
 *              compute c0, c1 such that c mod MLDSA_Q = c1*2^MLDSA_D + c0
 *              with -2^{MLDSA_D-1} < c0 <= 2^{MLDSA_D-1}. Assumes coefficients
 *to be standard representatives.
 *
 * Arguments:   - poly *a1: pointer to output polynomial with coefficients c1
 *              - poly *a0: pointer to output polynomial with coefficients c0
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void poly_power2round(poly *a1, poly *a0, const poly *a)
__contract__(
  requires(memory_no_alias(a0, sizeof(poly)))
  requires(memory_no_alias(a1, sizeof(poly)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  assigns(memory_slice(a1, sizeof(poly)))
  assigns(memory_slice(a0, sizeof(poly)))
  ensures(array_bound(a0->coeffs, 0, MLDSA_N, -(MLD_2_POW_D/2)+1, (MLD_2_POW_D/2)+1))
  ensures(array_bound(a1->coeffs, 0, MLDSA_N, 0, (MLD_2_POW_D/2)+1))
);


#define poly_decompose MLD_NAMESPACE(poly_decompose)
/*************************************************
 * Name:        poly_decompose
 *
 * Description: For all coefficients c of the input polynomial,
 *              compute high and low bits c0, c1 such c mod MLDSA_Q = c1*ALPHA +
 *              c0 with -ALPHA/2 < c0 <= ALPHA/2 except
 *              c1 = (MLDSA_Q-1)/ALPHA where we set
 *              c1 = 0 and -ALPHA/2 <= c0 = c mod MLDSA_Q - MLDSA_Q < 0.
 *              Assumes coefficients to be standard representatives.
 *
 * Arguments:   - poly *a1: pointer to output polynomial with coefficients c1
 *              - poly *a0: pointer to output polynomial with coefficients c0
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void poly_decompose(poly *a1, poly *a0, const poly *a)
__contract__(
  requires(memory_no_alias(a1,  sizeof(poly)))
  requires(memory_no_alias(a0, sizeof(poly)))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  assigns(object_whole(a1))
  assigns(object_whole(a0))
  ensures(array_bound(a1->coeffs, 0, MLDSA_N, 0, (MLDSA_Q-1)/(2*MLDSA_GAMMA2)))
  ensures(array_abs_bound(a0->coeffs, 0, MLDSA_N, MLDSA_GAMMA2+1))
);

#define poly_make_hint MLD_NAMESPACE(poly_make_hint)
/*************************************************
 * Name:        poly_make_hint
 *
 * Description: Compute hint polynomial. The coefficients of which indicate
 *              whether the low bits of the corresponding coefficient of
 *              the input polynomial overflow into the high bits.
 *
 * Arguments:   - poly *h: pointer to output hint polynomial
 *              - const poly *a0: pointer to low part of input polynomial
 *              - const poly *a1: pointer to high part of input polynomial
 *
 * Returns number of 1 bits.
 **************************************************/
unsigned int poly_make_hint(poly *h, const poly *a0, const poly *a1)
__contract__(
  requires(memory_no_alias(h,  sizeof(poly)))
  requires(memory_no_alias(a0, sizeof(poly)))
  requires(memory_no_alias(a1, sizeof(poly)))
  assigns(memory_slice(h, sizeof(poly)))
  ensures(return_value <= MLDSA_N)
);

#define poly_use_hint MLD_NAMESPACE(poly_use_hint)
/*************************************************
 * Name:        poly_use_hint
 *
 * Description: Use hint polynomial to correct the high bits of a polynomial.
 *
 * Arguments:   - poly *b: pointer to output polynomial with corrected high bits
 *              - const poly *a: pointer to input polynomial
 *              - const poly *h: pointer to input hint polynomial
 **************************************************/
void poly_use_hint(poly *b, const poly *a, const poly *h)
__contract__(
  requires(memory_no_alias(a,  sizeof(poly)))
  requires(memory_no_alias(b, sizeof(poly)))
  requires(memory_no_alias(h, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
  requires(array_bound(h->coeffs, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(b, sizeof(poly)))
  ensures(array_bound(b->coeffs, 0, MLDSA_N, 0, (MLDSA_Q-1)/(2*MLDSA_GAMMA2)))
);

#define poly_chknorm MLD_NAMESPACE(poly_chknorm)
/*************************************************
 * Name:        poly_chknorm
 *
 * Description: Check infinity norm of polynomial against given bound.
 *              Assumes input coefficients were reduced by reduce32().
 *
 * Arguments:   - const poly *a: pointer to polynomial
 *              - int32_t B: norm bound
 *
 * Returns 0 if norm is strictly smaller than B <= (MLDSA_Q-1)/8 and 1
 *otherwise.
 **************************************************/
int poly_chknorm(const poly *a, int32_t B)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(0 <= B && B <= (MLDSA_Q - 1) / 8)
  requires(array_bound(a->coeffs, 0, MLDSA_N, -REDUCE_RANGE_MAX, REDUCE_RANGE_MAX))
  ensures(return_value == 0 || return_value == 1)
  ensures((return_value == 0) == array_abs_bound(a->coeffs, 0, MLDSA_N, B))
);


#define poly_uniform MLD_NAMESPACE(poly_uniform)
/*************************************************
 * Name:        poly_uniform
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [0,MLDSA_Q-1] by performing rejection sampling on the
 *              output stream of SHAKE128(seed|nonce)
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *                MLDSA_SEEDBYTES
 *              - uint16_t nonce: 2-byte nonce
 **************************************************/
void poly_uniform(poly *a, const uint8_t seed[MLDSA_SEEDBYTES], uint16_t nonce)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(seed, MLDSA_SEEDBYTES))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_bound(a->coeffs, 0, MLDSA_N, 0, MLDSA_Q))
);

#define poly_uniform_eta MLD_NAMESPACE(poly_uniform_eta)
/*************************************************
 * Name:        poly_uniform_eta
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [-MLDSA_ETA,MLDSA_ETA] by performing rejection sampling on
 *              the output stream from SHAKE256(seed|nonce)
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *                MLDSA_CRHBYTES
 *              - uint16_t nonce: 2-byte nonce
 **************************************************/
void poly_uniform_eta(poly *a, const uint8_t seed[MLDSA_CRHBYTES],
                      uint16_t nonce)
__contract__(
  requires(memory_no_alias(a, sizeof(poly)))
  requires(memory_no_alias(seed, MLDSA_CRHBYTES))
  assigns(memory_slice(a, sizeof(poly)))
  ensures(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_ETA + 1))
);

#define poly_uniform_gamma1 MLD_NAMESPACE(poly_uniform_gamma1)
/*************************************************
 * Name:        poly_uniform_gamma1m1
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [-(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1] by unpacking output
 *              stream of SHAKE256(seed|nonce)
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *                MLDSA_CRHBYTES
 *              - uint16_t nonce: 16-bit nonce
 **************************************************/
void poly_uniform_gamma1(poly *a, const uint8_t seed[MLDSA_CRHBYTES],
                         uint16_t nonce);

#define poly_challenge MLD_NAMESPACE(poly_challenge)
/*************************************************
 * Name:        poly_challenge
 *
 * Description: Implementation of H. Samples polynomial with MLDSA_TAU nonzero
 *              coefficients in {-1,1} using the output stream of
 *              SHAKE256(seed).
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const uint8_t mu[]: byte array containing seed of length
 *                MLDSA_CTILDEBYTES
 **************************************************/
void poly_challenge(poly *c, const uint8_t seed[MLDSA_CTILDEBYTES])
__contract__(
  requires(memory_no_alias(c, sizeof(poly)))
  requires(memory_no_alias(seed, MLDSA_CTILDEBYTES))
  assigns(memory_slice(c, sizeof(poly)))
  /* All coefficients of c are -1, 0 or +1 */
  ensures(array_bound(c->coeffs, 0, MLDSA_N, -1, 2))
);

#define polyeta_pack MLD_NAMESPACE(polyeta_pack)
/*************************************************
 * Name:        polyeta_pack
 *
 * Description: Bit-pack polynomial with coefficients in [-MLDSA_ETA,MLDSA_ETA].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_POLYETA_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyeta_pack(uint8_t *r, const poly *a)
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYETA_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_abs_bound(a->coeffs, 0, MLDSA_N, MLDSA_ETA + 1))
  assigns(memory_slice(r, MLDSA_POLYETA_PACKEDBYTES))
);

/*
 * polyeta_unpack produces coefficients in [-MLDSA_ETA,MLDSA_ETA] for
 * well-formed inputs (i.e., those produced by polyeta_pack).
 * However, when passed an arbitrary byte array, it may produce smaller values,
 * i.e, values in [MLD_POLYETA_UNPACK_LOWER_BOUND,MLDSA_ETA]
 * Even though this should never happen, we use use the bound for arbitrary
 * inputs in the CBMC proofs.
 */
#if MLDSA_ETA == 2
#define MLD_POLYETA_UNPACK_LOWER_BOUND (-5)
#elif MLDSA_ETA == 4
#define MLD_POLYETA_UNPACK_LOWER_BOUND (-11)
#else
#error "Invalid value of MLDSA_ETA"
#endif

#define polyeta_unpack MLD_NAMESPACE(polyeta_unpack)
/*************************************************
 * Name:        polyeta_unpack
 *
 * Description: Unpack polynomial with coefficients in [-MLDSA_ETA,MLDSA_ETA].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyeta_unpack(poly *r, const uint8_t *a)
__contract__(
  requires(memory_no_alias(r, sizeof(poly)))
  requires(memory_no_alias(a, MLDSA_POLYETA_PACKEDBYTES))
  assigns(memory_slice(r, sizeof(poly)))
  ensures(array_bound(r->coeffs, 0, MLDSA_N, MLD_POLYETA_UNPACK_LOWER_BOUND, MLDSA_ETA + 1))
);

#define polyt1_pack MLD_NAMESPACE(polyt1_pack)
/*************************************************
 * Name:        polyt1_pack
 *
 * Description: Bit-pack polynomial t1 with coefficients fitting in 10 bits.
 *              Input coefficients are assumed to be standard representatives.
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_POLYT1_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyt1_pack(uint8_t *r, const poly *a)
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYT1_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, 1 << 10))
  assigns(object_whole(r))
);

#define polyt1_unpack MLD_NAMESPACE(polyt1_unpack)
/*************************************************
 * Name:        polyt1_unpack
 *
 * Description: Unpack polynomial t1 with 10-bit coefficients.
 *              Output coefficients are standard representatives.
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyt1_unpack(poly *r, const uint8_t *a)
__contract__(
  requires(memory_no_alias(r, sizeof(poly)))
  requires(memory_no_alias(a, MLDSA_POLYT1_PACKEDBYTES))
  assigns(memory_slice(r, sizeof(poly)))
  ensures(array_bound(r->coeffs, 0, MLDSA_N, 0, 1 << 10))
);

#define polyt0_pack MLD_NAMESPACE(polyt0_pack)
/*************************************************
 * Name:        polyt0_pack
 *
 * Description: Bit-pack polynomial t0 with coefficients in ]-2^{MLDSA_D-1},
 *              2^{MLDSA_D-1}].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_POLYT0_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyt0_pack(uint8_t *r, const poly *a)
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYT0_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, -(1<<(MLDSA_D-1)) + 1, (1<<(MLDSA_D-1)) + 1))
  assigns(memory_slice(r, MLDSA_POLYT0_PACKEDBYTES))
);


#define polyt0_unpack MLD_NAMESPACE(polyt0_unpack)
/*************************************************
 * Name:        polyt0_unpack
 *
 * Description: Unpack polynomial t0 with coefficients in ]-2^{MLDSA_D-1},
 *2^{MLDSA_D-1}].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyt0_unpack(poly *r, const uint8_t *a)
__contract__(
  requires(memory_no_alias(r, sizeof(poly)))
  requires(memory_no_alias(a, MLDSA_POLYT0_PACKEDBYTES))
  assigns(memory_slice(r, sizeof(poly)))
  ensures(array_bound(r->coeffs, 0, MLDSA_N, -(1<<(MLDSA_D-1)) + 1, (1<<(MLDSA_D-1)) + 1))
);

#define polyz_pack MLD_NAMESPACE(polyz_pack)
/*************************************************
 * Name:        polyz_pack
 *
 * Description: Bit-pack polynomial with coefficients
 *              in [-(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_POLYZ_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyz_pack(uint8_t *r, const poly *a)
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYZ_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, -(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1 + 1))
  assigns(object_whole(r))
);

#define polyz_unpack MLD_NAMESPACE(polyz_unpack)
/*************************************************
 * Name:        polyz_unpack
 *
 * Description: Unpack polynomial z with coefficients
 *              in [-(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyz_unpack(poly *r, const uint8_t *a)
__contract__(
  requires(memory_no_alias(r, sizeof(poly)))
  requires(memory_no_alias(a, MLDSA_POLYZ_PACKEDBYTES))
  assigns(memory_slice(r, sizeof(poly)))
  ensures(array_bound(r->coeffs, 0, MLDSA_N, -(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1 + 1))
);


#define polyw1_pack MLD_NAMESPACE(polyw1_pack)
/*************************************************
 * Name:        polyw1_pack
 *
 * Description: Bit-pack polynomial w1 with coefficients in [0,15] or [0,43].
 *              Input coefficients are assumed to be standard representatives.
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            MLDSA_POLYW1_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyw1_pack(uint8_t *r, const poly *a)
#if MLDSA_MODE == 2
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYW1_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, 44))
  assigns(object_whole(r)));
#else  /* MLDSA_MODE == 2 */
__contract__(
  requires(memory_no_alias(r, MLDSA_POLYW1_PACKEDBYTES))
  requires(memory_no_alias(a, sizeof(poly)))
  requires(array_bound(a->coeffs, 0, MLDSA_N, 0, 16))
  assigns(object_whole(r)));
#endif /* MLDSA_MODE != 2 */


#endif /* !MLD_POLY_H */
