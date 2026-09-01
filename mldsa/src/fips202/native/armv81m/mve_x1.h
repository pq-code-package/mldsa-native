/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_ARMV81M_MVE_X1_H
#define MLD_FIPS202_NATIVE_ARMV81M_MVE_X1_H

#define MLD_FIPS202_NATIVE_ARMV81M

/* Part of backend API */
#define MLD_USE_NATIVE_FIPS202_X1
#define MLD_USE_NATIVE_FIPS202_X1_XOR_BYTES
#define MLD_USE_NATIVE_FIPS202_X1_EXTRACT_BYTES
/* Guard for assembly files */
#define MLD_FIPS202_ARMV81M_NEED_X1

#if !defined(__ASSEMBLER__)
#include "../api.h"

#define mld_keccak_f1600_x1_native_impl \
  MLD_NAMESPACE(keccak_f1600_x1_native_impl)
MLD_INTERNAL_API
int mld_keccak_f1600_x1_native_impl(uint64_t *state);

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccak_f1600_x1_native(uint64_t *state)
{
  return mld_keccak_f1600_x1_native_impl(state);
}

#define mld_keccakf1600_xor_bytes_x1_native_impl \
  MLD_NAMESPACE(keccakf1600_xor_bytes_x1_native_impl)
MLD_INTERNAL_API
int mld_keccakf1600_xor_bytes_x1_native_impl(uint64_t *state,
                                             const uint8_t *data,
                                             unsigned offset, unsigned length);

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccakf1600_xor_bytes_x1_native(uint64_t *state,
                                                          const uint8_t *data,
                                                          unsigned offset,
                                                          unsigned length)
{
  return mld_keccakf1600_xor_bytes_x1_native_impl(state, data, offset, length);
}

#define mld_keccakf1600_extract_bytes_x1_native_impl \
  MLD_NAMESPACE(keccakf1600_extract_bytes_x1_native_impl)
MLD_INTERNAL_API
int mld_keccakf1600_extract_bytes_x1_native_impl(uint64_t *state, uint8_t *data,
                                                 unsigned offset,
                                                 unsigned length);

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_keccakf1600_extract_bytes_x1_native(uint64_t *state,
                                                              uint8_t *data,
                                                              unsigned offset,
                                                              unsigned length)
{
  return mld_keccakf1600_extract_bytes_x1_native_impl(state, data, offset,
                                                      length);
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_FIPS202_NATIVE_ARMV81M_MVE_X1_H */
