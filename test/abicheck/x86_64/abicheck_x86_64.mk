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
ABICHECK_REQ_AVX2_FILES :=

# AVX2: AVX2
ABICHECK_REQ_AVX2_FILES := \
  mldsa/src/fips202/native/x86_64/src/keccak_f1600_x4_avx2_asm.S \
  mldsa/src/native/x86_64/src/intt_avx2_asm.S \
  mldsa/src/native/x86_64/src/ntt_avx2_asm.S \
  mldsa/src/native/x86_64/src/nttunpack_avx2_asm.S \
  mldsa/src/native/x86_64/src/pointwise_acc_l4_avx2_asm.S \
  mldsa/src/native/x86_64/src/pointwise_acc_l5_avx2_asm.S \
  mldsa/src/native/x86_64/src/pointwise_acc_l7_avx2_asm.S \
  mldsa/src/native/x86_64/src/pointwise_avx2_asm.S \
  mldsa/src/native/x86_64/src/poly_caddq_avx2_asm.S \
  mldsa/src/native/x86_64/src/poly_chknorm_avx2_asm.S \
  mldsa/src/native/x86_64/src/poly_decompose_32_avx2_asm.S \
  mldsa/src/native/x86_64/src/poly_decompose_88_avx2_asm.S \
  mldsa/src/native/x86_64/src/polyz_unpack_17_avx2_asm.S \
  mldsa/src/native/x86_64/src/polyz_unpack_19_avx2_asm.S
ABICHECK_REQ_AVX2_OBJS := $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_REQ_AVX2_FILES))
$(ABICHECK_REQ_AVX2_OBJS): CFLAGS += -mavx2 -mbmi2
