// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

void harness(void)
{
  /* `context` is consumed by the call macro (the CBMC config has no context
   * parameter), exactly as at the call sites in sign.c. */
  uint16_t attempt = mld_sign_resume(context);
  ((void)attempt);
}
