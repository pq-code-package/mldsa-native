/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_FIPS202_NATIVE_PPC64LE_SRC_KECCAKF1600_PPC64LE_H
#define MLD_FIPS202_NATIVE_PPC64LE_SRC_KECCAKF1600_PPC64LE_H

#include "../../../../common.h"

#define mld_keccakf1600x4_permute24_ppc64le \
  MLD_NAMESPACE(keccakf1600x4_permute24_ppc64le)
void mld_keccakf1600x4_permute24_ppc64le(uint64_t *states);

#endif /* !MLD_FIPS202_NATIVE_PPC64LE_SRC_KECCAKF1600_PPC64LE_H */
