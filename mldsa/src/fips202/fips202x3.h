/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_FIPS202_FIPS202X3_H
#define MLD_FIPS202_FIPS202X3_H

#include "../common.h"

#if !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && defined(MLD_CONFIG_USE_X3)

#include <stddef.h>

#include "../cbmc.h"
#include "fips202.h"
#include "keccakf1600.h"

/*
 * 3-way batched SHAKE (MLD_CONFIG_USE_X3), mirroring fips202x4 but 3-wide.
 * Provides SHAKE128 (x3 ExpandA: mld_poly_uniform_3x) and SHAKE256 (x3
 * ExpandS and ExpandMask: mld_poly_uniform_eta_3x, mld_poly_uniform_gamma1_3x).
 * Mirrors the SHAKE128/SHAKE256 blocks in fips202x4.h.
 */

/** Context for the non-incremental 3-way SHAKE128 API. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3]; /**< 3-way Keccak state,
                                                         stored sequentially. */
} mld_shake128x3ctx;

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
#define mld_shake128x3_absorb_once MLD_NAMESPACE(shake128x3_absorb_once)
MLD_INTERNAL_API
void mld_shake128x3_absorb_once(mld_shake128x3ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                size_t inlen)
__contract__(
  requires(inlen <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake128x3ctx)))
  requires(memory_no_alias(in0, inlen))
  requires(memory_no_alias(in1, inlen))
  requires(memory_no_alias(in2, inlen))
  assigns(memory_slice(state, sizeof(mld_shake128x3ctx)))
);

#define mld_shake128x3_squeezeblocks MLD_NAMESPACE(shake128x3_squeezeblocks)
MLD_INTERNAL_API
void mld_shake128x3_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  size_t nblocks, mld_shake128x3ctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(memory_no_alias(state, sizeof(mld_shake128x3ctx)))
  requires(memory_no_alias(out0, nblocks * SHAKE128_RATE))
  requires(memory_no_alias(out1, nblocks * SHAKE128_RATE))
  requires(memory_no_alias(out2, nblocks * SHAKE128_RATE))
  assigns(memory_slice(out0, nblocks * SHAKE128_RATE),
    memory_slice(out1, nblocks * SHAKE128_RATE),
    memory_slice(out2, nblocks * SHAKE128_RATE),
    memory_slice(state, sizeof(mld_shake128x3ctx)))
);

#define mld_shake128x3_init MLD_NAMESPACE(shake128x3_init)
MLD_INTERNAL_API
void mld_shake128x3_init(mld_shake128x3ctx *state);

#define mld_shake128x3_release MLD_NAMESPACE(shake128x3_release)
MLD_INTERNAL_API
void mld_shake128x3_release(mld_shake128x3ctx *state);
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

/** Context for the non-incremental 3-way SHAKE256 API. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3]; /**< 3-way Keccak state,
                                                         stored sequentially. */
} mld_shake256x3ctx;

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || \
    (!defined(MLD_CONFIG_NO_SIGN_API) &&   \
     (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)))
#define mld_shake256x3_absorb_once MLD_NAMESPACE(shake256x3_absorb_once)
MLD_INTERNAL_API
void mld_shake256x3_absorb_once(mld_shake256x3ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                size_t inlen)
__contract__(
  requires(inlen <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(state, sizeof(mld_shake256x3ctx)))
  requires(memory_no_alias(in0, inlen))
  requires(memory_no_alias(in1, inlen))
  requires(memory_no_alias(in2, inlen))
  assigns(memory_slice(state, sizeof(mld_shake256x3ctx)))
);

#define mld_shake256x3_squeezeblocks MLD_NAMESPACE(shake256x3_squeezeblocks)
MLD_INTERNAL_API
void mld_shake256x3_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  size_t nblocks, mld_shake256x3ctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(memory_no_alias(state, sizeof(mld_shake256x3ctx)))
  requires(memory_no_alias(out0, nblocks * SHAKE256_RATE))
  requires(memory_no_alias(out1, nblocks * SHAKE256_RATE))
  requires(memory_no_alias(out2, nblocks * SHAKE256_RATE))
  assigns(memory_slice(out0, nblocks * SHAKE256_RATE),
    memory_slice(out1, nblocks * SHAKE256_RATE),
    memory_slice(out2, nblocks * SHAKE256_RATE),
    memory_slice(state, sizeof(mld_shake256x3ctx)))
);

#define mld_shake256x3_init MLD_NAMESPACE(shake256x3_init)
MLD_INTERNAL_API
void mld_shake256x3_init(mld_shake256x3ctx *state);

#define mld_shake256x3_release MLD_NAMESPACE(shake256x3_release)
MLD_INTERNAL_API
void mld_shake256x3_release(mld_shake256x3ctx *state);
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || (!MLD_CONFIG_NO_SIGN_API && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST)) */

#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY && MLD_CONFIG_USE_X3 */
#endif /* !MLD_FIPS202_FIPS202X3_H */
