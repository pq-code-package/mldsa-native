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

/** Context for the non-incremental 4-way SHAKE128 API. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES *
               MLD_KECCAK_WAY]; /**< 4-way Keccak state, stored sequentially. */
} mld_shake128x4ctx;

/** Context for the 4-way batched SHAKE256 XOF. */
typedef struct
{
  uint64_t ctx[MLD_KECCAK_LANES *
               MLD_KECCAK_WAY]; /**< Interleaved 4-way Keccak state. */
} mld_shake256x4ctx;

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
#define mld_shake128x4_absorb_once MLD_NAMESPACE(shake128x4_absorb_once)
MLD_INTERNAL_API
void mld_shake128x4_absorb_once(mld_shake128x4ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                const uint8_t *in3, size_t inlen)
__contract__(
  requires(inlen <= MLD_MAX_BUFFER_SIZE)
  requires(disjoint(state, (in0, inlen), (in1, inlen), (in2, inlen), (in3, inlen)))
  assigns(slices(state))
);

#define mld_shake128x4_squeezeblocks MLD_NAMESPACE(shake128x4_squeezeblocks)
MLD_INTERNAL_API
void mld_shake128x4_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  uint8_t *out3, size_t nblocks,
                                  mld_shake128x4ctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(disjoint(state,
                    (out0, nblocks * SHAKE128_RATE),
                    (out1, nblocks * SHAKE128_RATE),
                    (out2, nblocks * SHAKE128_RATE),
                    (out3, nblocks * SHAKE128_RATE)))
  assigns(slices((out0, nblocks * SHAKE128_RATE),
                 (out1, nblocks * SHAKE128_RATE),
                 (out2, nblocks * SHAKE128_RATE),
                 (out3, nblocks * SHAKE128_RATE),
                 state))
);

#define mld_shake128x4_init MLD_NAMESPACE(shake128x4_init)
MLD_INTERNAL_API
void mld_shake128x4_init(mld_shake128x4ctx *state);

#define mld_shake128x4_release MLD_NAMESPACE(shake128x4_release)
MLD_INTERNAL_API
void mld_shake128x4_release(mld_shake128x4ctx *state);
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || \
    (!defined(MLD_CONFIG_NO_SIGN_API) &&   \
     (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)))
#define mld_shake256x4_absorb_once MLD_NAMESPACE(shake256x4_absorb_once)
MLD_INTERNAL_API
void mld_shake256x4_absorb_once(mld_shake256x4ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                const uint8_t *in3, size_t inlen)
__contract__(
  requires(inlen <= MLD_MAX_BUFFER_SIZE)
  requires(disjoint(state, (in0, inlen), (in1, inlen), (in2, inlen), (in3, inlen)))
  assigns(slices(state))
);

#define mld_shake256x4_squeezeblocks MLD_NAMESPACE(shake256x4_squeezeblocks)
MLD_INTERNAL_API
void mld_shake256x4_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  uint8_t *out3, size_t nblocks,
                                  mld_shake256x4ctx *state)
__contract__(
  requires(nblocks <= 8 /* somewhat arbitrary bound */)
  requires(disjoint(state,
                    (out0, nblocks * SHAKE256_RATE),
                    (out1, nblocks * SHAKE256_RATE),
                    (out2, nblocks * SHAKE256_RATE),
                    (out3, nblocks * SHAKE256_RATE)))
  assigns(slices((out0, nblocks * SHAKE256_RATE),
                 (out1, nblocks * SHAKE256_RATE),
                 (out2, nblocks * SHAKE256_RATE),
                 (out3, nblocks * SHAKE256_RATE),
                 state))
);

#define mld_shake256x4_init MLD_NAMESPACE(shake256x4_init)
MLD_INTERNAL_API
void mld_shake256x4_init(mld_shake256x4ctx *state);

#define mld_shake256x4_release MLD_NAMESPACE(shake256x4_release)
MLD_INTERNAL_API
void mld_shake256x4_release(mld_shake256x4ctx *state);
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || (!MLD_CONFIG_NO_SIGN_API && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST)) */

#endif /* !MLD_CONFIG_SERIAL_FIPS202_ONLY */
#endif /* !MLD_FIPS202_FIPS202X4_H */
