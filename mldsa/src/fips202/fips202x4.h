/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_FIPS202_FIPS202X4_H
#define MLD_FIPS202_FIPS202X4_H

#include "../common.h"

#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY)

#include <stddef.h>

#include "../cbmc.h"
#include "fips202.h"
#include "keccakf1600.h"

/*
 * Batched SHAKE128/SHAKE256 for MLD_KECCAK_WAY inputs at once (the batching
 * factor, see common.h). The inputs and the outputs each live in one buffer:
 * input i starts at in + i * stride, output i at out + i * stride.
 *
 * A custom FIPS202 implementation (MLD_CONFIG_FIPS202X4_CUSTOM_HEADER) instead
 * provides the 4-way mld_shake{128,256}x4_* functions; see FIPS202.md.
 */

/** Context for the batched SHAKE128. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES * MLD_KECCAK_WAY]; /**< Batched Keccak state,
                                                      stored sequentially. */
} mld_shake128xNctx;

/** Context for the batched SHAKE256. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES * MLD_KECCAK_WAY]; /**< Batched Keccak state,
                                                      stored sequentially. */
} mld_shake256xNctx;

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
#define mld_shake128xN_absorb_once MLD_NAMESPACE(shake128xN_absorb_once)
MLD_INTERNAL_API
void mld_shake128xN_absorb_once(mld_shake128xNctx *state, const uint8_t *in,
                                size_t stride, size_t inlen)
__contract__(
  requires(inlen <= stride && stride <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake128xNctx)))
  requires(memory_no_alias(in, (MLD_KECCAK_WAY - 1) * stride + inlen))
  assigns(memory_slice(state, sizeof(mld_shake128xNctx)))
);

#define mld_shake128xN_squeezeblocks MLD_NAMESPACE(shake128xN_squeezeblocks)
MLD_INTERNAL_API
void mld_shake128xN_squeezeblocks(uint8_t *out, size_t stride, size_t nblocks,
                                  mld_shake128xNctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(nblocks * SHAKE128_RATE <= stride && stride <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake128xNctx)))
  requires(memory_no_alias(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * SHAKE128_RATE))
  assigns(memory_slice(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * SHAKE128_RATE),
    memory_slice(state, sizeof(mld_shake128xNctx)))
);

#define mld_shake128xN_init MLD_NAMESPACE(shake128xN_init)
MLD_INTERNAL_API
void mld_shake128xN_init(mld_shake128xNctx *state);

#define mld_shake128xN_release MLD_NAMESPACE(shake128xN_release)
MLD_INTERNAL_API
void mld_shake128xN_release(mld_shake128xNctx *state);
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || \
    (!defined(MLD_CONFIG_NO_SIGN_API) &&   \
     (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)))
#define mld_shake256xN_absorb_once MLD_NAMESPACE(shake256xN_absorb_once)
MLD_INTERNAL_API
void mld_shake256xN_absorb_once(mld_shake256xNctx *state, const uint8_t *in,
                                size_t stride, size_t inlen)
__contract__(
  requires(inlen <= stride && stride <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake256xNctx)))
  requires(memory_no_alias(in, (MLD_KECCAK_WAY - 1) * stride + inlen))
  assigns(memory_slice(state, sizeof(mld_shake256xNctx)))
);

#define mld_shake256xN_squeezeblocks MLD_NAMESPACE(shake256xN_squeezeblocks)
MLD_INTERNAL_API
void mld_shake256xN_squeezeblocks(uint8_t *out, size_t stride, size_t nblocks,
                                  mld_shake256xNctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(nblocks * SHAKE256_RATE <= stride && stride <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake256xNctx)))
  requires(memory_no_alias(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * SHAKE256_RATE))
  assigns(memory_slice(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * SHAKE256_RATE),
    memory_slice(state, sizeof(mld_shake256xNctx)))
);

#define mld_shake256xN_init MLD_NAMESPACE(shake256xN_init)
MLD_INTERNAL_API
void mld_shake256xN_init(mld_shake256xNctx *state);

#define mld_shake256xN_release MLD_NAMESPACE(shake256xN_release)
MLD_INTERNAL_API
void mld_shake256xN_release(mld_shake256xNctx *state);
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || (!MLD_CONFIG_NO_SIGN_API && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST)) */

#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY */
#endif /* !MLD_FIPS202_FIPS202X4_H */
