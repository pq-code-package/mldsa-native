// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

int mld_polyz_unpack_17_native(int32_t *r, const uint8_t *a);

void harness(void)
{
  /* mld_polyz_unpack_17_native is only defined for ML-DSA-44 */
#if MLD_CONFIG_PARAMETER_SET == 44
  int32_t *r;
  const uint8_t *a;
  int t;
  t = mld_polyz_unpack_17_native(r, a);
#endif /* MLD_CONFIG_PARAMETER_SET == 44 */
}
