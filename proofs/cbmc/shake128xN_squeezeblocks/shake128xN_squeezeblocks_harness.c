// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <fips202xN.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  uint8_t *out;
  size_t stride, nblocks;
  mld_shake128xNctx *state;
  mld_shake128xN_squeezeblocks(out, stride, nblocks, state);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
