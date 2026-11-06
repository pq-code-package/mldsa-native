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
ABICHECK_REQ_RVV_FILES :=
ABICHECK_REQ_ZBB_FILES :=

# RVV: RISC-V Vector extension 1.0
ABICHECK_REQ_RVV_FILES := \
  mldsa/src/native/riscv64/src/mldsa_intt_vlen128_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_intt_vlen256_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_ntt_vlen128_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_ntt_vlen256_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_caddq_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_chknorm_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_decompose_32_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_decompose_88_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_pointwise_montgomery_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_use_hint_32_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_poly_use_hint_88_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_polyz_unpack_17_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_polyz_unpack_19_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_rej_uniform_eta2_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_rej_uniform_eta4_riscv64_asm.S \
  mldsa/src/native/riscv64/src/mldsa_rej_uniform_riscv64_asm.S
ABICHECK_REQ_RVV_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_RVV_FILES))
$(ABICHECK_REQ_RVV_OBJS): CFLAGS += -march=rv64gcv

# ZBB: RISC-V Zbb extension
ABICHECK_REQ_ZBB_FILES := \
  mldsa/src/fips202/native/riscv64/src/keccak_f1600_x1_zbb_riscv64_asm.S
ABICHECK_REQ_ZBB_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_ZBB_FILES))
$(ABICHECK_REQ_ZBB_OBJS): CFLAGS += -march=rv64gc_zbb
