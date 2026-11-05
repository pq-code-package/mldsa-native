// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include "poly_kl.h"

#define MLD_HARNESS_POLY(i) mld_poly *r##i;
#define MLD_HARNESS_NONCE(i) uint16_t n##i;
#define MLD_HARNESS_ARG(i) r##i,
#define MLD_HARNESS_NONCE_ARG(i) n##i,

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  MLD_XN_LANES(MLD_HARNESS_POLY)
  MLD_XN_LANES(MLD_HARNESS_NONCE)
  const uint8_t *seed;

  mld_poly_uniform_gamma1_xN(MLD_XN_LANES(MLD_HARNESS_ARG)
                                 MLD_XN_LANES(MLD_HARNESS_NONCE_ARG) seed);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
