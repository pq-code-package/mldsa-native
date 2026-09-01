/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_FIPS202_NATIVE_ARMV81M_SRC_FIPS202_NATIVE_ARMV81M_X1_H
#define MLD_FIPS202_NATIVE_ARMV81M_SRC_FIPS202_NATIVE_ARMV81M_X1_H

#include "../../../../common.h"

/* Scalar x1 Keccak round constants followed by its loop terminator */
#define mld_keccakf1600_round_constants_x1 \
  MLD_NAMESPACE(keccakf1600_round_constants_x1)
MLD_INTERNAL_DATA_DECLARATION const uint32_t
    mld_keccakf1600_round_constants_x1[49];

#endif /* !MLD_FIPS202_NATIVE_ARMV81M_SRC_FIPS202_NATIVE_ARMV81M_X1_H */
