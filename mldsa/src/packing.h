/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_PACKING_H
#define MLD_PACKING_H

#include "polyvec.h"
#include "polyvec_lazy.h"

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#define mld_pack_pk MLD_NAMESPACE_KL(pack_pk)
/*************************************************
 * Name:        mld_pack_pk
 *
 * Description: Bit-pack public key pk = (rho, t1).
 *
 * Arguments:   - uint8_t pk[]: output byte array
 *              - const uint8_t rho[]: byte array containing rho
 *              - const mld_polyveck *t1: pointer to vector t1
 **************************************************/
MLD_INTERNAL_API
void mld_pack_pk(uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
                 const uint8_t rho[MLDSA_SEEDBYTES], const mld_polyveck *t1)
__contract__(
  requires(memory_no_alias(pk, MLDSA_CRYPTO_PUBLICKEYBYTES))
  requires(memory_no_alias(rho, MLDSA_SEEDBYTES))
  requires(memory_no_alias(t1, sizeof(mld_polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(t1->vec[k0].coeffs, 0, MLDSA_N, 0, 1 << 10)))
  assigns(memory_slice(pk, MLDSA_CRYPTO_PUBLICKEYBYTES))
);


#define mld_pack_sk_s1 MLD_NAMESPACE_KL(pack_sk_s1)
/*************************************************
 * Name:        mld_pack_sk_s1
 *
 * Description: Bit-pack the s1 component into the secret key.
 *
 * Arguments:   - uint8_t sk[]: output byte array
 *              - const mld_polyvecl *s1: pointer to vector s1
 **************************************************/
MLD_INTERNAL_API
void mld_pack_sk_s1(uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
                    const mld_polyvecl *s1)
__contract__(
  requires(memory_no_alias(sk, MLDSA_CRYPTO_SECRETKEYBYTES))
  requires(memory_no_alias(s1, sizeof(mld_polyvecl)))
  requires(forall(k1, 0, MLDSA_L,
    array_abs_bound(s1->vec[k1].coeffs, 0, MLDSA_N, MLDSA_ETA + 1)))
  assigns(memory_slice(sk, MLDSA_CRYPTO_SECRETKEYBYTES))
);

#define mld_pack_sk_rho_key_tr_s2_t0 MLD_NAMESPACE_KL(pack_sk_rho_key_tr_s2_t0)
/*************************************************
 * Name:        mld_pack_sk_rho_key_tr_s2_t0
 *
 * Description: Bit-pack rho, key, tr, s2, t0 into the secret key.
 *              s1 must already be packed via mld_pack_sk_s1.
 *
 * Arguments:   - uint8_t sk[]: output byte array
 *              - const uint8_t rho[]: byte array containing rho
 *              - const uint8_t tr[]: byte array containing tr
 *              - const uint8_t key[]: byte array containing key
 *              - const mld_polyveck *t0: pointer to vector t0
 *              - const mld_polyveck *s2: pointer to vector s2
 **************************************************/
MLD_INTERNAL_API
void mld_pack_sk_rho_key_tr_s2_t0(uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES],
                                  const uint8_t rho[MLDSA_SEEDBYTES],
                                  const uint8_t tr[MLDSA_TRBYTES],
                                  const uint8_t key[MLDSA_SEEDBYTES],
                                  const mld_polyveck *t0,
                                  const mld_polyveck *s2)
__contract__(
  requires(memory_no_alias(sk, MLDSA_CRYPTO_SECRETKEYBYTES))
  requires(memory_no_alias(rho, MLDSA_SEEDBYTES))
  requires(memory_no_alias(tr, MLDSA_TRBYTES))
  requires(memory_no_alias(key, MLDSA_SEEDBYTES))
  requires(memory_no_alias(t0, sizeof(mld_polyveck)))
  requires(memory_no_alias(s2, sizeof(mld_polyveck)))
  requires(forall(k0, 0, MLDSA_K,
    array_bound(t0->vec[k0].coeffs, 0, MLDSA_N, -(1<<(MLDSA_D-1)) + 1, (1<<(MLDSA_D-1)) + 1)))
  requires(forall(k2, 0, MLDSA_K,
    array_abs_bound(s2->vec[k2].coeffs, 0, MLDSA_N, MLDSA_ETA + 1)))
  assigns(memory_slice(sk, MLDSA_CRYPTO_SECRETKEYBYTES))
);
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */


#if !defined(MLD_CONFIG_NO_SIGN_API)
#define mld_pack_sig_c MLD_NAMESPACE_KL(pack_sig_c)
/*************************************************
 * Name:        mld_pack_sig_c
 *
 * Description: Bit-pack challenge c into sig = (c, z, h).
 *
 * Arguments:   - uint8_t sig[]: output byte array
 *              - const uint8_t *c: pointer to challenge hash
 **************************************************/
MLD_INTERNAL_API
void mld_pack_sig_c(uint8_t sig[MLDSA_CRYPTO_BYTES],
                    const uint8_t c[MLDSA_CTILDEBYTES])
__contract__(
  requires(memory_no_alias(sig, MLDSA_CRYPTO_BYTES))
  requires(memory_no_alias(c, MLDSA_CTILDEBYTES))
  assigns(memory_slice(sig, MLDSA_CRYPTO_BYTES))
);

#define mld_pack_sig_h_poly MLD_NAMESPACE_KL(pack_sig_h_poly)
/*************************************************
 * Name:        mld_pack_sig_h_poly
 *
 * Description: Pack hints for one polynomial into the hint section of sig.
 *              Must be called once per polynomial in order k = 0, ..., K-1.
 *              The hint section of sig must be zeroed before the first call.
 *
 * Arguments:   - uint8_t sig[]: byte array containing signature
 *              - const mld_poly *h: pointer to hint polynomial (0/1 coeffs)
 *              - unsigned int k: index of polynomial in vector (0..K-1)
 *              - unsigned int n: total number of hints written so far
 **************************************************/
MLD_INTERNAL_API
void mld_pack_sig_h_poly(uint8_t sig[MLDSA_CRYPTO_BYTES], const mld_poly *h,
                         unsigned int k, unsigned int n)
__contract__(
  requires(memory_no_alias(sig, MLDSA_CRYPTO_BYTES))
  requires(memory_no_alias(h, sizeof(mld_poly)))
  requires(k < MLDSA_K)
  requires(n <= MLDSA_OMEGA)
  requires(array_bound(h->coeffs, 0, MLDSA_N, 0, 2))
  assigns(memory_slice(sig, MLDSA_CRYPTO_BYTES))
);

#define mld_pack_sig_z MLD_NAMESPACE_KL(pack_sig_z)
/*************************************************
 * Name:        mld_pack_sig_z
 *
 * Description: Bit-pack single polynomial of z component of sig = (c, z, h).
 *              The c and h components are packed separately using
 *              mld_pack_sig_c and mld_pack_sig_h_poly.
 *
 * Arguments:   - uint8_t sig[]: output byte array
 *              - const mld_poly *zi: pointer to a single polynomial in z
 *              - const unsigned int i: index of zi in vector z
 *
 **************************************************/
MLD_INTERNAL_API
void mld_pack_sig_z(uint8_t sig[MLDSA_CRYPTO_BYTES], const mld_poly *zi,
                    unsigned i)
__contract__(
  requires(memory_no_alias(sig, MLDSA_CRYPTO_BYTES))
  requires(memory_no_alias(zi, sizeof(mld_poly)))
  requires(i < MLDSA_L)
  requires(array_bound(zi->coeffs, 0, MLDSA_N, -(MLDSA_GAMMA1 - 1), MLDSA_GAMMA1 + 1))
  assigns(memory_slice(sig, MLDSA_CRYPTO_BYTES))
);
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
#define mld_unpack_pk_t1 MLD_NAMESPACE_KL(unpack_pk_t1)
/*************************************************
 * Name:        mld_unpack_pk_t1
 *
 * Description: Unpack a single polynomial of the t1 component of a public
 *              key pk = (rho, t1).
 *
 * Arguments:   - mld_poly *t1: pointer to output polynomial t1[i]
 *              - uint8_t pk[]: byte array containing bit-packed pk
 *              - unsigned int i: row index, must be < MLDSA_K
 **************************************************/
MLD_INTERNAL_API
void mld_unpack_pk_t1(mld_poly *t1,
                      const uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES],
                      unsigned int i)
__contract__(
  requires(memory_no_alias(pk, MLDSA_CRYPTO_PUBLICKEYBYTES))
  requires(memory_no_alias(t1, sizeof(mld_poly)))
  requires(i < MLDSA_K)
  assigns(memory_slice(t1, sizeof(mld_poly)))
  ensures(array_bound(t1->coeffs, 0, MLDSA_N, 0, 1 << 10))
);
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
#define mld_unpack_sk MLD_NAMESPACE_KL(unpack_sk)
/*************************************************
 * Name:        mld_unpack_sk
 *
 * Description: Unpack secret key sk = (rho, tr, key, t0, s1, s2).
 *
 *              NOTE: In REDUCE_RAM mode, s1/s2/t0 borrow from sk
 *              rather than copying.
 *
 * Arguments:   - const uint8_t rho[]: output byte array for rho
 *              - const uint8_t tr[]: output byte array for tr
 *              - const uint8_t key[]: output byte array for key
 *              - mld_sk_t0hat *t0: pointer to output vector t0
 *              - mld_sk_s1hat *s1: pointer to output vector s1
 *              - mld_sk_s2hat *s2: pointer to output vector s2
 *              - uint8_t sk[]: byte array containing bit-packed sk
 **************************************************/
MLD_INTERNAL_API
void mld_unpack_sk(uint8_t rho[MLDSA_SEEDBYTES], uint8_t tr[MLDSA_TRBYTES],
                   uint8_t key[MLDSA_SEEDBYTES], mld_sk_t0hat *t0,
                   mld_sk_s1hat *s1, mld_sk_s2hat *s2,
                   const uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES])
__contract__(
  requires(memory_no_alias(rho, MLDSA_SEEDBYTES))
  requires(memory_no_alias(tr, MLDSA_TRBYTES))
  requires(memory_no_alias(key, MLDSA_SEEDBYTES))
  requires(memory_no_alias(t0, sizeof(mld_sk_t0hat)))
  requires(memory_no_alias(s1, sizeof(mld_sk_s1hat)))
  requires(memory_no_alias(s2, sizeof(mld_sk_s2hat)))
  requires(memory_no_alias(sk, MLDSA_CRYPTO_SECRETKEYBYTES))
  assigns(memory_slice(rho, MLDSA_SEEDBYTES))
  assigns(memory_slice(tr, MLDSA_TRBYTES))
  assigns(memory_slice(key, MLDSA_SEEDBYTES))
  assigns(memory_slice(t0, sizeof(mld_sk_t0hat)))
  assigns(memory_slice(s1, sizeof(mld_sk_s1hat)))
  assigns(memory_slice(s2, sizeof(mld_sk_s2hat)))
  MLD_IF_NOT_REDUCE_RAM(
    ensures(forall(k0, 0, MLDSA_K,
      array_abs_bound(t0->vec.vec[k0].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
    ensures(forall(k1, 0, MLDSA_L,
      array_abs_bound(s1->vec.vec[k1].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
    ensures(forall(k2, 0, MLDSA_K,
      array_abs_bound(s2->vec.vec[k2].coeffs, 0, MLDSA_N, MLD_NTT_BOUND)))
  )
  MLD_IF_REDUCE_RAM(
    ensures(s1->packed == old(sk) + 2 * MLDSA_SEEDBYTES + MLDSA_TRBYTES)
    ensures(s2->packed == old(sk) + 2 * MLDSA_SEEDBYTES + MLDSA_TRBYTES +
                          MLDSA_L * MLDSA_POLYETA_PACKEDBYTES)
    ensures(t0->packed == old(sk) + 2 * MLDSA_SEEDBYTES + MLDSA_TRBYTES +
                          (MLDSA_L + MLDSA_K) * MLDSA_POLYETA_PACKEDBYTES)
  )
);
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
#define mld_sig_unpack_hints MLD_NAMESPACE_KL(sig_unpack_hints)
/*************************************************
 * Name:        mld_sig_unpack_hints
 *
 * Description: Decode and validate a single row of the hint vector h
 *              from a signature buffer. The hint encoding is shared
 *              across all rows (a count array followed by a single
 *              index list), so this function performs the validation
 *              relevant to row i:
 *                - the i'th hint count is non-decreasing and bounded
 *                  by MLDSA_OMEGA;
 *                - the indices for row i are strictly ascending;
 *                - on i == MLDSA_K - 1, the trailing index slots are
 *                  zero.
 *              Callers must invoke this for every
 *              i in {0, 1, ..., MLDSA_K - 1}; if any call returns
 *              MLD_ERR_FAIL the encoding is malformed and the signature
 *              must be rejected.
 *
 * Arguments:   - mld_poly *h: pointer to output polynomial h[i]
 *              - const uint8_t sig[]: signature buffer
 *              - unsigned int i: row index, must be < MLDSA_K
 *
 * Returns MLD_ERR_FAIL in case of malformed hints; otherwise 0.
 **************************************************/
MLD_INTERNAL_API
MLD_MUST_CHECK_RETURN_VALUE
int mld_sig_unpack_hints(mld_poly *h, const uint8_t sig[MLDSA_CRYPTO_BYTES],
                         unsigned int i)
__contract__(
  requires(memory_no_alias(sig, MLDSA_CRYPTO_BYTES))
  requires(memory_no_alias(h, sizeof(mld_poly)))
  requires(i < MLDSA_K)
  assigns(memory_slice(h, sizeof(mld_poly)))
  ensures(return_value == 0 || return_value == MLD_ERR_FAIL)
  ensures(return_value == 0 ==> array_bound(h->coeffs, 0, MLDSA_N, 0, 2))
);
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#endif /* !MLD_PACKING_H */
