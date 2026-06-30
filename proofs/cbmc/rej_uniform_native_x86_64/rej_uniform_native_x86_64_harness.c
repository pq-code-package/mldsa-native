// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"


int mld_rej_uniform_native(int32_t *r, unsigned len, const uint8_t *buf,
                           unsigned buflen);

void harness(void)
{
  int32_t *r;
  unsigned len;
  const uint8_t *buf;
  unsigned buflen;

  mld_rej_uniform_native(r, len, buf, buflen);
}
