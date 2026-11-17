// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"

void mld_poly_accumulate_column_entry(mld_poly *acc, mld_poly *entry,
                                      const mld_poly *v, unsigned int l);

void harness(void)
{
  mld_poly *acc;
  mld_poly *entry;
  const mld_poly *v;
  unsigned int l;
  mld_poly_accumulate_column_entry(acc, entry, v, l);
}
