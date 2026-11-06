/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_FIPS202_NATIVE_RISCV64_SRC_FIPS202_NATIVE_RISCV64_H
#define MLD_FIPS202_NATIVE_RISCV64_SRC_FIPS202_NATIVE_RISCV64_H

#include "../../../../cbmc.h"
#include "../../../../common.h"

#define mld_keccakf1600_round_constants \
  MLD_NAMESPACE(keccakf1600_round_constants)
MLD_INTERNAL_DATA_DECLARATION const uint64_t
    mld_keccakf1600_round_constants[24];

#define mld_keccak_f1600_x1_zbb_riscv64_asm \
  MLD_NAMESPACE(keccak_f1600_x1_zbb_riscv64_asm)
void mld_keccak_f1600_x1_zbb_riscv64_asm(uint64_t state[25],
                                         const uint64_t rc[24])
/* This must be kept in sync with the HOL-Light specification
 * in proofs/hol_light/riscv64/proofs/keccak_f1600_x1_zbb_riscv64_asm.ml */
__contract__(
  requires(memory_no_alias(state, sizeof(uint64_t) * 25 * 1))
  requires(rc == mld_keccakf1600_round_constants)
  assigns(memory_slice(state, sizeof(uint64_t) * 25 * 1))
);

#endif /* !MLD_FIPS202_NATIVE_RISCV64_SRC_FIPS202_NATIVE_RISCV64_H */
