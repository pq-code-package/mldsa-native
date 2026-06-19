/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H
#define MLD_NATIVE_PPC64LE_SRC_ARITH_NATIVE_PPC64LE_H

#include "../../../common.h"
#include "../../../params.h"

#define mld_poly_caddq_ppc64le_asm MLD_NAMESPACE(poly_caddq_ppc64le_asm)
void mld_poly_caddq_ppc64le_asm(int32_t a[MLDSA_N]);

#endif
