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

#include "../common.h"
#if !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
    !defined(MLD_CONFIG_SERIAL_FIPS202_ONLY)

#include "../ct.h"
#include "fips202.h"
#include "fips202x4.h"
#include "keccakf1600.h"

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_REDUCE_RAM) || \
    defined(MLD_UNIT_TEST)
static void mld_keccak_absorb_once_xN(uint64_t *s, unsigned r,
                                      const uint8_t *in, size_t stride,
                                      size_t inlen, uint8_t p)
__contract__(
  requires(inlen <= stride && stride <= MLD_MAX_BUFFER_SIZE)
  requires(memory_no_alias(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
  requires(r > 0)
  requires(r <= sizeof(uint64_t) * MLD_KECCAK_LANES)
  requires(memory_no_alias(in, (MLD_KECCAK_WAY - 1) * stride + inlen))
  assigns(memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY)))
{
  size_t pos = 0;
  while (inlen - pos >= r)
  __loop__(
    assigns(pos, memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    invariant(pos <= inlen)
    decreases(inlen - pos))
  {
    mld_keccakf1600xN_xor_bytes(s, in + pos, stride, 0, r);
    mld_keccakf1600xN_permute(s);
    pos += r;
  }

  /* Safety: At this point, inlen - pos < r, so the truncations to unsigned are
   * safe below. */
  if (pos < inlen)
  {
    mld_keccakf1600xN_xor_bytes(s, in + pos, stride, 0,
                                (unsigned)(inlen - pos));
  }

  /* The padding is the same for every state: stride 0. */
  if (inlen - pos == r - 1)
  {
    p |= 128;
    mld_keccakf1600xN_xor_bytes(s, &p, 0, (unsigned)(inlen - pos), 1);
  }
  else
  {
    mld_keccakf1600xN_xor_bytes(s, &p, 0, (unsigned)(inlen - pos), 1);
    p = 128;
    mld_keccakf1600xN_xor_bytes(s, &p, 0, r - 1, 1);
  }
}

static void mld_keccak_squeezeblocks_xN(uint8_t *out, size_t stride,
                                        size_t nblocks, uint64_t *s, unsigned r)
__contract__(
    requires(r <= sizeof(uint64_t) * MLD_KECCAK_LANES)
    requires(nblocks <= 8 /* somewhat arbitrary bound */)
    requires(nblocks * r <= stride && stride <= MLD_MAX_BUFFER_SIZE)
    requires(memory_no_alias(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    requires(memory_no_alias(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * r))
    assigns(memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY))
    assigns(memory_slice(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * r)))
{
  size_t current_offset = 0;
  while (nblocks > 0)
  __loop__(
    assigns(nblocks, current_offset,
            memory_slice(s, sizeof(uint64_t) * MLD_KECCAK_LANES * MLD_KECCAK_WAY),
            memory_slice(out, (MLD_KECCAK_WAY - 1) * stride + nblocks * r))
    invariant(nblocks <= loop_entry(nblocks))
    invariant(current_offset == (loop_entry(nblocks) - nblocks) * r)
    decreases(nblocks))
  {
    mld_keccakf1600xN_permute(s);
    mld_keccakf1600xN_extract_bytes(s, out + current_offset, stride, 0, r);
    current_offset += r;
    nblocks--;
  }
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_REDUCE_RAM || \
          MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)
MLD_INTERNAL_API
void mld_shake128xN_absorb_once(mld_shake128xNctx *state, const uint8_t *in,
                                size_t stride, size_t inlen)
{
  mld_memset(state, 0, sizeof(mld_shake128xNctx));
  mld_keccak_absorb_once_xN(state->ctx, SHAKE128_RATE, in, stride, inlen, 0x1F);
}

MLD_INTERNAL_API
void mld_shake128xN_squeezeblocks(uint8_t *out, size_t stride, size_t nblocks,
                                  mld_shake128xNctx *state)
{
  mld_keccak_squeezeblocks_xN(out, stride, nblocks, state->ctx, SHAKE128_RATE);
}

MLD_INTERNAL_API
void mld_shake128xN_init(mld_shake128xNctx *state) { (void)state; }
MLD_INTERNAL_API
void mld_shake128xN_release(mld_shake128xNctx *state)
{
  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(state, sizeof(mld_shake128xNctx));
}
#endif /* !MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || \
    (!defined(MLD_CONFIG_NO_SIGN_API) &&   \
     (!defined(MLD_CONFIG_REDUCE_RAM) || defined(MLD_UNIT_TEST)))
MLD_INTERNAL_API
void mld_shake256xN_absorb_once(mld_shake256xNctx *state, const uint8_t *in,
                                size_t stride, size_t inlen)
{
  mld_memset(state, 0, sizeof(mld_shake256xNctx));
  mld_keccak_absorb_once_xN(state->ctx, SHAKE256_RATE, in, stride, inlen, 0x1F);
}

MLD_INTERNAL_API
void mld_shake256xN_squeezeblocks(uint8_t *out, size_t stride, size_t nblocks,
                                  mld_shake256xNctx *state)
{
  mld_keccak_squeezeblocks_xN(out, stride, nblocks, state->ctx, SHAKE256_RATE);
}

MLD_INTERNAL_API
void mld_shake256xN_init(mld_shake256xNctx *state) { (void)state; }
MLD_INTERNAL_API
void mld_shake256xN_release(mld_shake256xNctx *state)
{
  /* @[FIPS204, Section 3.6.3] Destruction of intermediate values. */
  mld_zeroize(state, sizeof(mld_shake256xNctx));
}
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || (!MLD_CONFIG_NO_SIGN_API && \
          (!MLD_CONFIG_REDUCE_RAM || MLD_UNIT_TEST)) */

#endif /* !MLD_CONFIG_MULTILEVEL_NO_SHARED && !MLD_CONFIG_SERIAL_FIPS202_ONLY \
        */
