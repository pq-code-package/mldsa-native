// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include "poly.h"

#define MLD_HARNESS_POLY(i) mld_poly *r##i;
#define MLD_HARNESS_ARG(i) r##i,

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  MLD_XN_LANES(MLD_HARNESS_POLY)
  uint8_t (*seed)[MLD_ALIGN_UP(MLDSA_SEEDBYTES + 2)];

  mld_poly_uniform_xN(MLD_XN_LANES(MLD_HARNESS_ARG) seed);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
