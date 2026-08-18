/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef TEST_NAMESPACE_H
#define TEST_NAMESPACE_H

/* Build-config-independent aliases for the public API under test. */
#define MLD_TEST_CONCAT_(a, b) a##b
#define MLD_TEST_CONCAT(a, b) MLD_TEST_CONCAT_(a, b)
#define MLDSA_NAMESPACE(sym) \
  MLD_TEST_CONCAT(MLD_TEST_CONCAT(MLD_CONFIG_NAMESPACE_PREFIX, _), sym)

#define mld_prepare_domain_separation_prefix \
  MLDSA_NAMESPACE(prepare_domain_separation_prefix)
#define mld_sign_keypair MLDSA_NAMESPACE(keypair)
#define mld_sign_keypair_internal MLDSA_NAMESPACE(keypair_internal)
#define mld_sign_pk_from_sk MLDSA_NAMESPACE(pk_from_sk)
#define mld_sign_signature MLDSA_NAMESPACE(signature)
#define mld_sign_signature_internal MLDSA_NAMESPACE(signature_internal)
#define mld_sign_signature_extmu MLDSA_NAMESPACE(signature_extmu)
#define mld_sign_signature_pre_hash_internal \
  MLDSA_NAMESPACE(signature_pre_hash_internal)
#define mld_sign_signature_pre_hash_shake256 \
  MLDSA_NAMESPACE(signature_pre_hash_shake256)
#define mld_sign_verify MLDSA_NAMESPACE(verify)
#define mld_sign_verify_internal MLDSA_NAMESPACE(verify_internal)
#define mld_sign_verify_extmu MLDSA_NAMESPACE(verify_extmu)
#define mld_sign_verify_pre_hash_internal \
  MLDSA_NAMESPACE(verify_pre_hash_internal)
#define mld_sign_verify_pre_hash_shake256 \
  MLDSA_NAMESPACE(verify_pre_hash_shake256)

/* Convenience abbreviations for the key and signature sizes.
 *
 * Ordinarily you know the parameter set you're working with, so you would
 * just use the level-specific constants directly, e.g. MLDSA44_PUBLICKEYBYTES,
 * MLDSA65_BYTES, or MLDSA87_SECRETKEYBYTES.
 *
 * The tests, however, are built for all three parameter sets (44, 65, 87), so
 * we keep things generic by deriving the sizes from the configured
 * MLD_CONFIG_PARAMETER_SET. */
#define MLDSA_PK_BYTES MLDSA_PUBLICKEYBYTES(MLD_CONFIG_PARAMETER_SET)
#define MLDSA_SK_BYTES MLDSA_SECRETKEYBYTES(MLD_CONFIG_PARAMETER_SET)
#define MLDSA_SIG_BYTES MLDSA_BYTES(MLD_CONFIG_PARAMETER_SET)

#endif /* !TEST_NAMESPACE_H */
