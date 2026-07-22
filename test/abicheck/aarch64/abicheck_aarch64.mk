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
ABICHECK_REQ_NEON_FILES :=
ABICHECK_REQ_SHA3_FILES :=

# NEON: AArch64 NEON
ABICHECK_REQ_NEON_FILES := \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x1_v84a_aarch64_asm.S \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x2_v84a_aarch64_asm.S \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm.S \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S \
  mldsa/src/native/aarch64/src/intt_aarch64_asm.S \
  mldsa/src/native/aarch64/src/mld_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S \
  mldsa/src/native/aarch64/src/mld_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S \
  mldsa/src/native/aarch64/src/mld_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S \
  mldsa/src/native/aarch64/src/ntt_aarch64_asm.S \
  mldsa/src/native/aarch64/src/pointwise_montgomery_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_caddq_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_chknorm_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_decompose_32_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_decompose_88_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_use_hint_32_aarch64_asm.S \
  mldsa/src/native/aarch64/src/poly_use_hint_88_aarch64_asm.S \
  mldsa/src/native/aarch64/src/polyz_unpack_17_aarch64_asm.S \
  mldsa/src/native/aarch64/src/polyz_unpack_19_aarch64_asm.S \
  mldsa/src/native/aarch64/src/rej_uniform_aarch64_asm.S \
  mldsa/src/native/aarch64/src/rej_uniform_eta2_aarch64_asm.S \
  mldsa/src/native/aarch64/src/rej_uniform_eta4_aarch64_asm.S
ABICHECK_REQ_NEON_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_NEON_FILES))
$(ABICHECK_REQ_NEON_OBJS): CFLAGS += -march=armv8-a+simd

# SHA3: Armv8.4-A SHA3 (eor3, rax1, xar, bcax)
ABICHECK_REQ_SHA3_FILES := \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x1_v84a_aarch64_asm.S \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x2_v84a_aarch64_asm.S \
  mldsa/src/fips202/native/aarch64/src/keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S
ABICHECK_REQ_SHA3_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_SHA3_FILES))
$(ABICHECK_REQ_SHA3_OBJS): CFLAGS += -march=armv8.4-a+sha3
