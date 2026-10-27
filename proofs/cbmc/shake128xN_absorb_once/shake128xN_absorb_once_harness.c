// Copyright (c) The mldsa-native project authors
// Copyright (c) The mlkem-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <fips202x4.h>
#include <stddef.h>
#include <stdint.h>

void harness(void)
{
#if !defined(MLD_CONFIG_REDUCE_RAM)
  mld_shake128xNctx *state;
  const uint8_t *in;
  size_t stride, inlen;
  mld_shake128xN_absorb_once(state, in, stride, inlen);
#endif /* !MLD_CONFIG_REDUCE_RAM */
}
