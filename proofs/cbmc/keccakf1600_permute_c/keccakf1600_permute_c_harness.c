// Copyright (c) The mldsa-native project authors
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#include <keccakf1600.h>

void mld_keccakf1600_permute_c(uint64_t *state);

void harness(void)
{
  uint64_t *s;
  mld_keccakf1600_permute_c(s);
}
