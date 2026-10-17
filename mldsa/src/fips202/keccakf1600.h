/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_FIPS202_KECCAKF1600_H
#define MLD_FIPS202_KECCAKF1600_H
#include "../cbmc.h"
#include "../common.h"
#include "fips202.h"

#define MLD_KECCAK_LANES 25
#define MLD_KECCAK_WAY 4

/* Batching width of the 3-way (x3) Keccak path used with MLD_CONFIG_USE_X3.
 * Kept separate from MLD_KECCAK_WAY (=4), which the x4 API and its contracts
 * depend on. */
#define MLD_KECCAK_WAY_X3 3

/*
 * WARNING:
 * The contents of this structure, including the placement
 * and interleaving of Keccak lanes, are IMPLEMENTATION-DEFINED.
 * The struct is only exposed here to allow its construction on the stack.
 */

#define mld_keccakf1600_extract_bytes MLD_NAMESPACE(keccakf1600_extract_bytes)
MLD_INTERNAL_API
void mld_keccakf1600_extract_bytes(uint64_t *state, unsigned char *data,
                                   unsigned offset, unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES))
    requires(memory_no_alias(data, length))
    assigns(memory_slice(data, length))
);

#define mld_keccakf1600_xor_bytes MLD_NAMESPACE(keccakf1600_xor_bytes)
MLD_INTERNAL_API
void mld_keccakf1600_xor_bytes(uint64_t *state, const unsigned char *data,
                               unsigned offset, unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES))
    requires(memory_no_alias(data, length))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES))
);

#if (!defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
     defined(MLD_UNIT_TEST)) &&                                                \
    !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY)
#if !defined(MLD_CONFIG_USE_X3) || defined(MLD_UNIT_TEST)
#define mld_keccakf1600x4_extract_bytes \
  MLD_NAMESPACE(keccakf1600x4_extract_bytes)
MLD_INTERNAL_API
void mld_keccakf1600x4_extract_bytes(uint64_t *state, unsigned char *data0,
                                     unsigned char *data1, unsigned char *data2,
                                     unsigned char *data3, unsigned offset,
                                     unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    requires(memory_no_alias(data0, length))
    requires(memory_no_alias(data1, length))
    requires(memory_no_alias(data2, length))
    requires(memory_no_alias(data3, length))
    assigns(memory_slice(data0, length))
    assigns(memory_slice(data1, length))
    assigns(memory_slice(data2, length))
    assigns(memory_slice(data3, length))
);

#define mld_keccakf1600x4_xor_bytes MLD_NAMESPACE(keccakf1600x4_xor_bytes)
MLD_INTERNAL_API
void mld_keccakf1600x4_xor_bytes(uint64_t *state, const unsigned char *data0,
                                 const unsigned char *data1,
                                 const unsigned char *data2,
                                 const unsigned char *data3, unsigned offset,
                                 unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    requires(memory_no_alias(data0, length))
    /* Case 1: all input buffers are distinct; Case 2: All input buffers are the same */
    requires((data0 == data1 &&
              data0 == data2 &&
              data0 == data3) ||
         (memory_no_alias(data1, length) &&
              memory_no_alias(data2, length) &&
              memory_no_alias(data3, length)))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
);

#define mld_keccakf1600x4_permute MLD_NAMESPACE(keccakf1600x4_permute)
MLD_INTERNAL_API
void mld_keccakf1600x4_permute(uint64_t *state)
__contract__(
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
);
#endif /* !MLD_CONFIG_USE_X3 || MLD_UNIT_TEST */

#if defined(MLD_CONFIG_USE_X3)
/* 3-way (x3) batched Keccak primitives, used with MLD_CONFIG_USE_X3. They
 * mirror the x4 trio above but operate on 3 sequential states
 * (MLD_KECCAK_WAY_X3), and back the 3-way SHAKE128/SHAKE256 in fips202x3. */
#define mld_keccakf1600x3_extract_bytes \
  MLD_NAMESPACE(keccakf1600x3_extract_bytes)
MLD_INTERNAL_API
void mld_keccakf1600x3_extract_bytes(uint64_t *state, unsigned char *data0,
                                     unsigned char *data1, unsigned char *data2,
                                     unsigned offset, unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    requires(memory_no_alias(data0, length))
    requires(memory_no_alias(data1, length))
    requires(memory_no_alias(data2, length))
    assigns(memory_slice(data0, length))
    assigns(memory_slice(data1, length))
    assigns(memory_slice(data2, length))
);

#define mld_keccakf1600x3_xor_bytes MLD_NAMESPACE(keccakf1600x3_xor_bytes)
MLD_INTERNAL_API
void mld_keccakf1600x3_xor_bytes(uint64_t *state, const unsigned char *data0,
                                 const unsigned char *data1,
                                 const unsigned char *data2, unsigned offset,
                                 unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    requires(memory_no_alias(data0, length))
    /* Case 1: all input buffers are distinct; Case 2: All input buffers are the same */
    requires((data0 == data1 &&
              data0 == data2) ||
         (memory_no_alias(data1, length) &&
              memory_no_alias(data2, length)))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
);

#define mld_keccakf1600x3_permute MLD_NAMESPACE(keccakf1600x3_permute)
MLD_INTERNAL_API
void mld_keccakf1600x3_permute(uint64_t *state)
__contract__(
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
);
#endif /* MLD_CONFIG_USE_X3 */
#endif /* (!MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM || \
          MLD_UNIT_TEST) && !MLD_CONFIG_SERIAL_FIPS202_ONLY */

#define mld_keccakf1600_permute MLD_NAMESPACE(keccakf1600_permute)
MLD_INTERNAL_API
void mld_keccakf1600_permute(uint64_t *state)
__contract__(
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES))
);

#endif /* !MLD_FIPS202_KECCAKF1600_H */
