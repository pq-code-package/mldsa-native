# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# WARNING: This file is auto-generated from scripts/autogen
#          in the mldsa-native repository.
#          Do not modify it directly.
#
# Edit the YAML 'ABI.Features:' list in dev/<arch>/src/<kernel>.S
# and re-run scripts/autogen instead.
#
# For each capability declared by a kernel's ABI.Features list, this
# file appends the capability's CFLAGS to that kernel's .S object
# under mldsa/src/.

# Default each cap's file list to empty so the unconditional appends
# below are safe even when a cap has no kernels on this arch.
ABICHECK_REQ_RV32M_FILES :=

# RV32M: RISC-V RV32M integer multiplication
ABICHECK_REQ_RV32M_FILES := \
  mldsa/src/native/rv32im/src/mldsa_intt_rv32im_asm.S \
  mldsa/src/native/rv32im/src/mldsa_ntt_rv32im_asm.S \
  mldsa/src/native/rv32im/src/mldsa_poly_pointwise_montgomery_rv32im_asm.S \
  test/abicheck/riscv32/callstub_riscv32.S \
  test/abicheck/riscv32/selftest_riscv32.S
ABICHECK_REQ_RV32M_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_RV32M_FILES))
