// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

#if MLD_CONFIG_PARAMETER_SET == 44
int mld_polyz_unpack_17_native(int32_t *r, const uint8_t *a);
#else
int mld_polyz_unpack_19_native(int32_t *r, const uint8_t *a);
#endif

void harness(void)
{
  int32_t *r;
  const uint8_t *a;
  int t;

#if MLD_CONFIG_PARAMETER_SET == 44
  t = mld_polyz_unpack_17_native(r, a);
#else
  t = mld_polyz_unpack_19_native(r, a);
#endif
}
