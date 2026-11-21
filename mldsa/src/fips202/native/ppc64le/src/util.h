/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_PPC64LE_SRC_UTIL_H
#define MLD_FIPS202_NATIVE_PPC64LE_SRC_UTIL_H

/* **************************************************************************************************************
 *
 * This code is based on the official documentation for
 * https://csrc.nist.gov/csrc/media/Projects/hash-functions/documents/Keccak-reference-3.0.pdf
 * Follows the guidelines provided by https://keccak.team
 * Original keccak implementation from the keccak team:
 * https://github.com/XKCP/XKCP
 *
 * additional helper sources:
 * https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
 * https://csrc.nist.gov/files/pubs/fips/180-4/upd1/final/docs/fips180-4-draft-aug2014.pdf
 *
 **************************************************************************************************************
 * */
#include "../../../../common.h"
#if defined(MLD_FIPS202_PPC64LE) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
#include <inttypes.h>
#include "macros.h"

/* Include AltiVec SIMD instructions for PowerPC optimization */
/* Undefine conflicting macros to prevent naming collisions with standard types
 */
#if defined(__ALTIVEC__)
#include <altivec.h>
#undef vector
#undef pixel
#undef bool
#endif /* __ALTIVEC__ */

/* Keccak/SHA-3 state structure constants (ALL LENGTHS IN BYTES) */
#define MLD_SLICE 5      /* Keccak state is a 5x5 array  */
#define MLD_LANE_BYTES 8 /* Each lane is 8 bytes (64 bits)  */
/* check-magic: 6 == log2(64), the Keccak lane size in bits */
#define MLD_KECCAKl 6
#define MLD_NROUNDS \
  (2 * KECCAKl) + 12         /* Number of rounds: 24 for Keccak-f[1600]    */
#define MLD_STATE_SIZE 5 * 5 /* Total state size: 25 lanes (5x5 array)     */
#define MLD_KECCAK_BITS_TOTAL \
  25 << KECCAKl              /* Total state size in bits: 1600         */
#define MLD_WORDSZ 64        /* Word size in bits (64-bit architecture)    */
#define MLD_NUM_OF_ROUNDS 24 /* Number of required rounds for keccak       */
#define MLD_KECCAK_STATE_BYTES \
  25 * 8 /* Total state size in bytes (25 lanes × 8 bytes) */

/* Domain separation suffixes for different hash functions */
#define MLD_SHA3_SUFFIX \
  0x06 /* Suffix for SHA-3 variants (binary: 0b00000110)  */
#define MLD_SHAKE_SUFFIX \
  0x1F /* Suffix for SHAKE variants (binary: 0b00011111)  */
#define MLD_KECCAK_DOM \
  0x80 /* Domain separation bit (binary: 0b10000000)      */

/* Digest sizes in bits for different SHA-3 and SHAKE variants */
#define MLD_SHA3_224_DIGEST \
  256 /* SHA3-224 digest size (224 bits output, 256 capacity) */
#define MLD_SHA3_256_DIGEST \
  256 /* SHA3-256 digest size                                 */
#define MLD_SHA3_384_DIGEST \
  384 /* SHA3-384 digest size                                 */
#define MLD_SHA3_512_DIGEST \
  512 /* SHA3-512 digest size                                 */
#define MLD_SHAKE128_DIGEST \
  128 /* SHAKE128 security level                              */
#define MLD_SHAKE256_DIGEST \
  256 /* SHAKE256 security level                              */

/* Vector types for SIMD operations (AltiVec) - namespaced to avoid leakage */
typedef __vector unsigned long long
    mld_v2_u64; /* Vector of 2 x 64-bit unsigned integers */
typedef __vector unsigned char
    mld_v16_u8; /* Vector of 16 x 8-bit unsigned chars    */
typedef __vector unsigned int
    mld_v4_u32; /* Vector of 4 x 32-bit unsigned integers */

/*
 * Keccak round constants for the iota step
 *
 * Security note: capacity == 2 * digest length
 * This ensures that finding a collision of size digest length requires
 * 2^(digest_length) operations, providing the expected security level.
 *
 * Each constant is duplicated in the vector for parallel processing of multiple
 * states.
 */

#define mld_keccakf1600_round_constants_ppc64le \
  MLD_NAMESPACE(keccakf1600_round_constants_ppc64le)

extern const mld_v2_u64
    mld_keccakf1600_round_constants_ppc64le[MLD_NUM_OF_ROUNDS];

#endif /* MLD_FIPS202_PPC64LE && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
#endif /* !MLD_FIPS202_NATIVE_PPC64LE_SRC_UTIL_H */
