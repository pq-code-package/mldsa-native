/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_API_H
#define MLD_NATIVE_API_H
/*
 * Native arithmetic interface
 *
 * This header is primarily for documentation purposes.
 * It should not be included by backend implementations.
 *
 * To ensure consistency with backends, the header will be
 * included automatically after inclusion of the active
 * backend, to ensure consistency of function signatures,
 * and run sanity checks.
 */

#include <stdint.h>
#include "../cbmc.h"
#include "../common.h"

/*
 * This is the C<->native interface allowing for the drop-in of
 * native code for performance critical arithmetic components of ML-DSA.
 *
 * A _backend_ is a specific implementation of (part of) this interface.
 *
 * To add a function to a backend, define MLD_USE_NATIVE_XXX and
 * implement `static inline xxx(...)` in the profile header.
 *
 */

/*
 * Those functions are meant to be trivial wrappers around the chosen native
 * implementation. The are static inline to avoid unnecessary calls.
 * The macro before each declaration controls whether a native
 * implementation is present.
 */

#if defined(MLD_USE_NATIVE_NTT)
/*************************************************
 * Name:        mld_ntt_native
 *
 * Description: Computes negacyclic number-theoretic transform (NTT) of
 *              a polynomial in place.
 *
 *              The input polynomial is assumed to be in normal order.
 *              The output polynomial is in bitreversed order.
 *
 * Arguments:   - int32_t p[MLDSA_N]: pointer to in/output polynomial
 **************************************************/
static MLD_INLINE void mld_ntt_native(int32_t p[MLDSA_N]);
#endif /* MLD_USE_NATIVE_NTT */


#if defined(MLD_USE_NATIVE_NTT_CUSTOM_ORDER)
/*
 * This must only be set if NTT and INTT have native implementations
 * that are adapted to the custom order.
 */
#if !defined(MLD_USE_NATIVE_NTT) || !defined(MLD_USE_NATIVE_INTT)
#error \
    "Invalid native profile: MLD_USE_NATIVE_NTT_CUSTOM_ORDER can only be \
set if there are native implementations for NTT and INTT."
#endif

/*************************************************
 * Name:        mlD_poly_permute_bitrev_to_custom
 *
 * Description: When MLD_USE_NATIVE_NTT_CUSTOM_ORDER is defined,
 *              convert a polynomial in NTT domain from bitreversed
 *              order to the custom order output by the native NTT.
 *
 *              This must only be defined if there is native code for
 *              both the NTT and INTT.
 *
 * Arguments:   - int32_t p[MLDSA_N]: pointer to in/output polynomial
 *
 **************************************************/
static MLD_INLINE void mld_poly_permute_bitrev_to_custom(int32_t p[MLDSA_N]);
#endif /* MLD_USE_NATIVE_NTT_CUSTOM_ORDER */


#if defined(MLD_USE_NATIVE_INTT)
/*************************************************
 * Name:        mld_intt_native
 *
 * Description: Computes inverse of negacyclic number-theoretic transform
 *(NTT) of a polynomial in place.
 *
 *              The input polynomial is in bitreversed order.
 *              The output polynomial is assumed to be in normal order.
 *
 * Arguments:   - uint32_t p[MLDSA_N]: pointer to in/output polynomial
 **************************************************/
static MLD_INLINE void mld_intt_native(int32_t p[MLDSA_N]);
#endif /* MLD_USE_NATIVE_INTT */

#if defined(MLD_USE_NATIVE_POLY_REDUCE)
/*************************************************
 * Name:        mld_poly_reduce_native
 *
 * Description: Inplace reduction of all coefficients of polynomial to
 *              representative in [-6283009,6283008]. Assumes input
 *              coefficients to be at most 2^31 - 2^22 - 1 in absolute
 *value.
 *
 * Arguments:   - int32_t *a: pointer to input/output polynomial
 **************************************************/
static MLD_INLINE void mld_poly_reduce_native(int32_t a[MLDSA_N]);
#endif /* MLD_USE_NATIVE_POLY_REDUCE */

#if defined(MLD_USE_NATIVE_POLY_CADDQ)
/*************************************************
 * Name:        mld_poly_caddq_native
 *
 * Description: For all coefficients of in/out polynomial add Q if
 *              coefficient is negative.
 *
 * Arguments:   - int32_t *a: pointer to input/output polynomial
 **************************************************/
static MLD_INLINE void mld_poly_caddq_native(int32_t a[MLDSA_N]);
#endif /* MLD_USE_NATIVE_POLY_CADDQ */

#endif /* !MLD_NATIVE_API_H */
