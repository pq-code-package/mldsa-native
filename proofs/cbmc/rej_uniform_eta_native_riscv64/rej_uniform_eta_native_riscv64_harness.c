// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include <stdint.h>
#include "cbmc.h"
#include "params.h"

#if MLDSA_ETA == 2
int mld_rej_uniform_eta2_native(int32_t *r, unsigned len, const uint8_t *buf,
                                unsigned buflen);
#elif MLDSA_ETA == 4
int mld_rej_uniform_eta4_native(int32_t *r, unsigned len, const uint8_t *buf,
                                unsigned buflen);
#endif

void harness(void)
{
  int32_t *r;
  unsigned len;
  const uint8_t *buf;
  unsigned buflen;
  int t;

#if MLDSA_ETA == 2
  t = mld_rej_uniform_eta2_native(r, len, buf, buflen);
#elif MLDSA_ETA == 4
  t = mld_rej_uniform_eta4_native(r, len, buf, buflen);
#endif
}
