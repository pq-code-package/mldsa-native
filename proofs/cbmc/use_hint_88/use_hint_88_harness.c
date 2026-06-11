// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "rounding.h"

void harness(void)
{
#if MLD_CONFIG_PARAMETER_SET == 44
  int32_t a, r, hint;
  r = mld_use_hint_88(a, hint);
#endif
}
