// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

int mld_poly_decompose_88_native(int32_t *a1, int32_t *a0);

void harness(void)
{
  /* mld_poly_decompose_88_native is only defined for ML-DSA-44 */
#if MLD_CONFIG_PARAMETER_SET == 44
  int32_t *a1;
  int32_t *a0;
  int t;
  t = mld_poly_decompose_88_native(a1, a0);
#endif /* MLD_CONFIG_PARAMETER_SET == 44 */
}
