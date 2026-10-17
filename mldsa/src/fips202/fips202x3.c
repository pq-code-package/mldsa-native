/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [FIPS204]
 *   FIPS 204 Module-Lattice-Based Digital Signature Standard
 *   National Institute of Standards and Technology
 *   https://csrc.nist.gov/pubs/fips/204/final
 */

/*
 * 3-way batched SHAKE128/SHAKE256 (MLD_CONFIG_USE_X3), mirroring fips202x4.c
 * but 3-wide. See fips202x3.h.
 */

#include "../common.h"
#if !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
    !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY) && defined(MLD_CONFIG_USE_X3)

#include "../ct.h"
#include "fips202.h"
#include "fips202x3.h"
#include "keccakf1600.h"

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
    defined(MLD_UNIT_TEST)
static void mld_keccak_absorb_once_x3(uint64_t *s, unsigned r,
                                      const uint8_t *in0, const uint8_t *in1,
                                      const uint8_t *in2, size_t inlen,
                                      uint8_t p)
__contract__(
  requires(inlen <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
  requires(r > 0)
  requires(r <= sizeof(uint64_t) * MLD_KECCAK_LANES)
  requires(memory_no_alias(in0, inlen))
  requires(memory_no_alias(in1, inlen))
  requires(memory_no_alias(in2, inlen))
  assigns(memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3)))
{
  while (inlen >= r)
  __loop__(
    assigns(inlen, in0, in1, in2, memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    invariant(inlen <= loop_entry(inlen))
    invariant(in0 == loop_entry(in0) + (loop_entry(inlen) - inlen))
    invariant(in1 == loop_entry(in1) + (loop_entry(inlen) - inlen))
    invariant(in2 == loop_entry(in2) + (loop_entry(inlen) - inlen))
    decreases(inlen))
  {
    mld_keccakf1600x3_xor_bytes(s, in0, in1, in2, 0, r);
    mld_keccakf1600x3_permute(s);

    in0 += r;
    in1 += r;
    in2 += r;
    inlen -= r;
  }

  /* Safety: At this point, inlen < r, so the truncations to unsigned are safe
   * below. */
  if (inlen > 0)
  {
    mld_keccakf1600x3_xor_bytes(s, in0, in1, in2, 0, (unsigned)inlen);
  }

  if (inlen == r - 1)
  {
    p |= 128;
    mld_keccakf1600x3_xor_bytes(s, &p, &p, &p, (unsigned)inlen, 1);
  }
  else
  {
    mld_keccakf1600x3_xor_bytes(s, &p, &p, &p, (unsigned)inlen, 1);
    p = 128;
    mld_keccakf1600x3_xor_bytes(s, &p, &p, &p, r - 1, 1);
  }
}

static void mld_keccak_squeezeblocks_x3(uint8_t *out0, uint8_t *out1,
                                        uint8_t *out2, size_t nblocks,
                                        uint64_t *s, unsigned r)
__contract__(
    requires(r <= sizeof(uint64_t) * MLD_KECCAK_LANES)
    requires(nblocks <= 8 /* somewhat arbitrary bound */)
    requires(memory_no_alias(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    requires(memory_no_alias(out0, nblocks * r))
    requires(memory_no_alias(out1, nblocks * r))
    requires(memory_no_alias(out2, nblocks * r))
    assigns(memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3))
    assigns(memory_slice(out0, nblocks * r))
    assigns(memory_slice(out1, nblocks * r))
    assigns(memory_slice(out2, nblocks * r)))
{
  size_t current_offset = 0;
  while (nblocks > 0)
  __loop__(
    assigns(nblocks, current_offset,
            memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY_X3),
            memory_slice(out0, nblocks * r),
            memory_slice(out1, nblocks * r),
            memory_slice(out2, nblocks * r))
    invariant(nblocks <= loop_entry(nblocks))
    invariant(current_offset == (loop_entry(nblocks) - nblocks) * r)
    decreases(nblocks))
  {
    mld_keccakf1600x3_permute(s);
    mld_keccakf1600x3_extract_bytes(s, &out0[current_offset],
                                    &out1[current_offset],
                                    &out2[current_offset], 0, r);
    current_offset += r;
    nblocks--;
  }
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM || \
          MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
MLD_INTERNAL_API
void mld_shake128x3_absorb_once(mld_shake128x3ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                size_t inlen)
{
  mld_memset(state, 0, sizeof(mld_shake128x3ctx));
  mld_keccak_absorb_once_x3(state->ctx, SHAKE128_RATE, in0, in1, in2, inlen,
                            0x1F);
}

MLD_INTERNAL_API
void mld_shake128x3_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  size_t nblocks, mld_shake128x3ctx *state)
{
  mld_keccak_squeezeblocks_x3(out0, out1, out2, nblocks, state->ctx,
                              SHAKE128_RATE);
}

MLD_INTERNAL_API
void mld_shake128x3_init(mld_shake128x3ctx *state) { (void)state; }
MLD_INTERNAL_API
void mld_shake128x3_release(mld_shake128x3ctx *state)
{
  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(state, sizeof(mld_shake128x3ctx));
}
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) ||                                  \
    (!defined(MLD_CONFIG_NO_SIGN_API) &&                                    \
     (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)))
MLD_INTERNAL_API
void mld_shake256x3_absorb_once(mld_shake256x3ctx *state, const uint8_t *in0,
                                const uint8_t *in1, const uint8_t *in2,
                                size_t inlen)
{
  mld_memset(state, 0, sizeof(mld_shake256x3ctx));
  mld_keccak_absorb_once_x3(state->ctx, SHAKE256_RATE, in0, in1, in2, inlen,
                            0x1F);
}

MLD_INTERNAL_API
void mld_shake256x3_squeezeblocks(uint8_t *out0, uint8_t *out1, uint8_t *out2,
                                  size_t nblocks, mld_shake256x3ctx *state)
{
  mld_keccak_squeezeblocks_x3(out0, out1, out2, nblocks, state->ctx,
                              SHAKE256_RATE);
}

MLD_INTERNAL_API
void mld_shake256x3_init(mld_shake256x3ctx *state) { (void)state; }
MLD_INTERNAL_API
void mld_shake256x3_release(mld_shake256x3ctx *state)
{
  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(state, sizeof(mld_shake256x3ctx));
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || (!MLD_CONFIG_NO_SIGN_API && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST)) */

#endif /* !MLD_CONFIG_MULTILEVEL_NO_SHARED && !MLD_CONFIG_SERIAL_FIPS202_ONLY \
          && MLD_CONFIG_USE_X3 */
