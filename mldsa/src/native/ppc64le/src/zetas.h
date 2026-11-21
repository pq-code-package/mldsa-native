/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_SRC_ZETAS_H
#define MLD_NATIVE_PPC64LE_SRC_ZETAS_H

#include "../../../common.h"
#include "../../../params.h"

#define mld_zetas_ MLD_NAMESPACE(zetas_)
#define mld_zetas_inv_al MLD_NAMESPACE(zetas_inv_al)

extern const int32_t mld_zetas_[MLDSA_N];
extern const int32_t mld_zetas_inv_al[MLDSA_N];

#endif /* !MLD_NATIVE_PPC64LE_SRC_ZETAS_H */
