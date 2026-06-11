// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "rounding.h"

void harness(void)
{
#if MLD_CONFIG_PARAMETER_SET != 44
  int32_t *a0, *a1;
  int32_t a;
  mld_decompose_32(a0, a1, a);
#endif
}
