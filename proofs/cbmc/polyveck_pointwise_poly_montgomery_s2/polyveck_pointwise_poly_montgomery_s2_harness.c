// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "polyvec_lazy.h"
#include "sign.h"

void mld_polyveck_pointwise_poly_montgomery_s2(mld_polyveck *h,
                                               const mld_poly *cp,
                                               const mld_sk_s2hat *s2,
                                               mld_poly *tmp);

void harness(void)
{
  mld_polyveck *h;
  mld_poly *cp;
  mld_sk_s2hat *s2;
  mld_poly *tmp;

  mld_polyveck_pointwise_poly_montgomery_s2(h, cp, s2, tmp);
}
