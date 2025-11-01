/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "prehash.h"
#include "symmetric.h"

#if !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
#define MLD_PRE_HASH_OID_LEN 11

/*************************************************
 * Name:        mld_get_hash_oid
 *
 * Description: Returns the OID of a given SHA-2/SHA-3 hash function.
 *
 * Arguments:   - uint8_t oid[11]: pointer to output oid
 *              - mld_hash_alg_t hashAlg: hash algorithm enumeration
 *
 **************************************************/
static void mld_get_hash_oid(uint8_t oid[MLD_PRE_HASH_OID_LEN],
                             mld_hash_alg_t hashAlg)
{
  unsigned int i;
  static const struct
  {
    mld_hash_alg_t alg;
    uint8_t oid[MLD_PRE_HASH_OID_LEN];
  } oid_map[] = {
      {MLD_SHA2_224,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04}},
      {MLD_SHA2_256,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01}},
      {MLD_SHA2_384,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02}},
      {MLD_SHA2_512,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03}},
      {MLD_SHA2_512_224,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x05}},
      {MLD_SHA2_512_256,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x06}},
      {MLD_SHA3_224,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x07}},
      {MLD_SHA3_256,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x08}},
      {MLD_SHA3_384,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x09}},
      {MLD_SHA3_512,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x0A}},
      {MLD_SHAKE_128,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x0B}},
      {MLD_SHAKE_256,
       {0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x0C}}};

  for (i = 0; i < sizeof(oid_map) / sizeof(oid_map[0]); i++)
  __loop__(
    invariant(i <= sizeof(oid_map) / sizeof(oid_map[0]))
  )
  {
    if (oid_map[i].alg == hashAlg)
    {
      mld_memcpy(oid, oid_map[i].oid, MLD_PRE_HASH_OID_LEN);
      return;
    }
  }
}

int mld_validate_hash_length(mld_hash_alg_t hashAlg, size_t len)
{
  switch (hashAlg)
  {
    case MLD_SHA2_224:
      return (len == 224 / 8) ? 0 : -1;
    case MLD_SHA2_256:
      return (len == 256 / 8) ? 0 : -1;
    case MLD_SHA2_384:
      return (len == 384 / 8) ? 0 : -1;
    case MLD_SHA2_512:
      return (len == 512 / 8) ? 0 : -1;
    case MLD_SHA2_512_224:
      return (len == 224 / 8) ? 0 : -1;
    case MLD_SHA2_512_256:
      return (len == 256 / 8) ? 0 : -1;
    case MLD_SHA3_224:
      return (len == 224 / 8) ? 0 : -1;
    case MLD_SHA3_256:
      return (len == 256 / 8) ? 0 : -1;
    case MLD_SHA3_384:
      return (len == 384 / 8) ? 0 : -1;
    case MLD_SHA3_512:
      return (len == 512 / 8) ? 0 : -1;
    case MLD_SHAKE_128:
      return (len == 256 / 8) ? 0 : -1;
    case MLD_SHAKE_256:
      return (len == 512 / 8) ? 0 : -1;
  }
  return -1;
}

size_t mld_format_pre_hash_message(
    uint8_t fmsg[MLD_PRE_HASH_MAX_FORMATTED_MESSAGE_BYTES], const uint8_t *ph,
    size_t phlen, const uint8_t *ctx, size_t ctxlen, mld_hash_alg_t hashAlg)
{
  /* Format: 0x01 || ctxlen (1 byte) || ctx || oid (11 bytes) || ph */
  fmsg[0] = 1;
  fmsg[1] = (uint8_t)ctxlen;

  /* Copy context if present */
  if (ctxlen > 0)
  {
    mld_memcpy(fmsg + 2, ctx, ctxlen);
  }

  /* Write OID */
  mld_get_hash_oid(fmsg + 2 + ctxlen, hashAlg);

  /* Copy pre-hash */
  mld_memcpy(fmsg + 2 + ctxlen + MLD_PRE_HASH_OID_LEN, ph, phlen);

  /* Return total formatted message length */
  return 2 + ctxlen + MLD_PRE_HASH_OID_LEN + phlen;
}

#endif /* !MLD_CONFIG_MULTILEVEL_NO_SHARED */
