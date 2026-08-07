/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_META_H
#define MLD_NATIVE_ARMV81M_META_H

/* MVE-only backend; otherwise, leave the C NTT selected. */
#if defined(__ARM_FEATURE_MVE)

/* Identifier for this backend so its assembly is only emitted when selected. */
#define MLD_ARITH_BACKEND_ARMV81M_PQMX
#define MLD_USE_NATIVE_NTT

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_armv81m.h"

/*
 * pqmx's forward kernel leaves each 16-coefficient block in a 4-by-4
 * transposed layout. The transpose is self-inverse; undo it here so the
 * public native-NTT contract remains normal input to bit-reversed output
 * while the existing C inverse NTT remains in use.
 */
static MLD_INLINE void mld_armv81m_pqmx_restore_bitrev(int32_t data[MLDSA_N])
{
  unsigned int block;

  for (block = 0; block < MLDSA_N; block += 16)
  {
    int32_t tmp[16];
    unsigned int row, col;

    for (row = 0; row < 16; row++)
    {
      tmp[row] = data[block + row];
    }
    for (row = 0; row < 4; row++)
    {
      for (col = 0; col < 4; col++)
      {
        data[block + 4 * row + col] = tmp[4 * col + row];
      }
    }
  }
}

MLD_MUST_CHECK_RETURN_VALUE
static MLD_INLINE int mld_ntt_native(int32_t data[MLDSA_N])
{
  if (!mld_sys_check_capability(MLD_SYS_CAP_ARMV81M_MVE))
  {
    return MLD_NATIVE_FUNC_FALLBACK;
  }

  mld_ntt_armv81m_asm(data);
  mld_armv81m_pqmx_restore_bitrev(data);
  return MLD_NATIVE_FUNC_SUCCESS;
}
#endif /* !__ASSEMBLER__ */

#endif /* __ARM_FEATURE_MVE */

#endif /* !MLD_NATIVE_ARMV81M_META_H */
