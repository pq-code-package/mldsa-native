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
/* The batching factor MLD_KECCAK_WAY is defined in common.h. */

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
/*
 * Batched Keccak-f1600 state access for MLD_KECCAK_WAY states, stored one
 * after another (MLD_KECCAK_LANES lanes each). The batching factor is chosen
 * in common.h (default 4; the backend's factor with MLD_USE_NATIVE_FIPS202_XN).
 *
 * The data of all states lives in one buffer: the bytes for state i start at
 * data + i * stride. For xor_bytes, stride 0 means the same bytes for every
 * state (used for the padding byte).
 */
#define mld_keccakf1600xN_extract_bytes \
  MLD_NAMESPACE(keccakf1600xN_extract_bytes)
MLD_INTERNAL_API
void mld_keccakf1600xN_extract_bytes(uint64_t *state, unsigned char *data,
                                     size_t stride, unsigned offset,
                                     unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires(length <= stride && stride <= MLD_MAX_BUFFER_SIZE)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    requires(memory_no_alias(data, (MLD_KECCAK_WAY - 1) * stride + length))
    assigns(memory_slice(data, (MLD_KECCAK_WAY - 1) * stride + length))
);

#define mld_keccakf1600xN_xor_bytes MLD_NAMESPACE(keccakf1600xN_xor_bytes)
MLD_INTERNAL_API
void mld_keccakf1600xN_xor_bytes(uint64_t *state, const unsigned char *data,
                                 size_t stride, unsigned offset,
                                 unsigned length)
__contract__(
    requires(0 <= offset && offset <= MLD_KECCAK_LANES * sizeof(uint64_t) &&
         0 <= length && length <= MLD_KECCAK_LANES * sizeof(uint64_t) - offset)
    requires((stride == 0 || length <= stride) && stride <= MLD_MAX_BUFFER_SIZE)
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    requires(memory_no_alias(data, (MLD_KECCAK_WAY - 1) * stride + length))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
);

#define mld_keccakf1600xN_permute MLD_NAMESPACE(keccakf1600xN_permute)
MLD_INTERNAL_API
void mld_keccakf1600xN_permute(uint64_t *state)
__contract__(
    requires(memory_no_alias(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    assigns(memory_slice(state, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
);
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
