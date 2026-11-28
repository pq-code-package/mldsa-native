// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

int mld_poly_decompose_32_native(int32_t *a1, int32_t *a0);

void harness(void)
{
  /* mld_poly_decompose_32_native is only defined for ML-DSA-65 and ML-DSA-87 */
#if MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87
  int32_t *a1;
  int32_t *a0;
  int t;
  t = mld_poly_decompose_32_native(a1, a0);
#endif /* MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87 */
}
