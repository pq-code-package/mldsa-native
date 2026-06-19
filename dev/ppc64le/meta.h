/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_META_H
#define MLD_NATIVE_PPC64LE_META_H

/* Set of primitives this backend replaces (grown incrementally per kernel). */
#define MLD_USE_NATIVE_POLY_CADDQ

/* Backend identifier, for guarding source/assembly files in the build. */
#define MLD_ARITH_BACKEND_PPC64LE

#if !defined(__ASSEMBLER__)
#include "../api.h"
#include "src/arith_native_ppc64le.h"

static MLD_INLINE int mld_poly_caddq_native(int32_t a[MLDSA_N])
{
  mld_poly_caddq_ppc64le_asm(a);
  return MLD_NATIVE_FUNC_SUCCESS;
}

#endif /* !__ASSEMBLER__ */

#endif /* MLD_NATIVE_PPC64LE_META_H */
