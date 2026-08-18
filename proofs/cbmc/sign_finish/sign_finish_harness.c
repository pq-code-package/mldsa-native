// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "sign.h"

/* `context` is consumed by the call macro (the CBMC config has no context
 * parameter), exactly as at the call sites in sign.c. */
void harness(void)
{
  {
    /* Dummy use of `free` to work around CBMC issue #8814. */
    free(NULL);
  }

  uint16_t attempt;
  mld_sign_finish(attempt, context);
}
