/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_ALL_H
#define MLD_ALL_H

/* API for MLDSA-44 */
#define MLD_CONFIG_API_PARAMETER_SET 44
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa44
#include "mldsa_native/mldsa/mldsa_native.h"
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H

/* API for MLDSA-65 */
#define MLD_CONFIG_API_PARAMETER_SET 65
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa65
#include "mldsa_native/mldsa/mldsa_native.h"
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H

/* API for MLDSA-87 */
#define MLD_CONFIG_API_PARAMETER_SET 87
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa87
#include "mldsa_native/mldsa/mldsa_native.h"
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H

#endif /* !MLD_ALL_H */
