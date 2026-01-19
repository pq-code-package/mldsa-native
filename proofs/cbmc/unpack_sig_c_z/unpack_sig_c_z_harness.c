// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "packing.h"


void harness(void)
{
  uint8_t *c;
  uint8_t *sig;
  mld_polyvecl *z;
  mld_unpack_sig_c_z(c, z, sig);
}
