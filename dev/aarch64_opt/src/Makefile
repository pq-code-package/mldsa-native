# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

######
# To run, see the README.md file
######
.PHONY: all clean

# ISA to optimize for
TARGET_ISA=Arm_AArch64

# MicroArch target to optimize for
# Changing this to Arm_Cortex_A55 results in significantly better performance
# on the Cortex-A55, but may result in worse performance on other CPUs.
TARGET_MICROARCH=Arm_Neoverse_N1_experimental

SLOTHY_EXTRA_FLAGS ?=

SLOTHY_FLAGS=-c sw_pipelining.enabled=true \
             -c inputs_are_outputs \
             -c sw_pipelining.minimize_overlapping=False \
             -c sw_pipelining.allow_post \
             -c variable_size \
             -c constraints.stalls_first_attempt=64 \
             $(SLOTHY_EXTRA_FLAGS)

SLOTHY_FLAGS_SPLIT= -c inputs_are_outputs \
                    -c variable_size \
                    -c constraints.stalls_first_attempt=64 \
                    -c split_heuristic=true \
                    -c split_heuristic_repeat=2 \
                    -c sw_pipelining.enabled=true \
                    -c sw_pipelining.halving_heuristic=True \
                    $(SLOTHY_EXTRA_FLAGS)

# For kernels which stash callee-saved v8-v15 but don't stash callee-saved GPRs x19-x30. 
# Allow SLOTHY to use all V-registers, but only caller-saved GPRs.
RESERVE_X_ONLY_FLAG=-c reserved_regs="[x18--x30,sp]"

# Used for kernels which don't stash callee-saved registers.
# Restrict SLOTHY to caller-saved registers.
RESERVE_ALL_FLAG=-c reserved_regs="[x18--x30,sp,v8--v15]"

all: mldsa_ntt_aarch64_asm.S \
     mldsa_intt_aarch64_asm.S \
     mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S \
     mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S \
     mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S \
     mldsa_pointwise_montgomery_aarch64_asm.S \
     mldsa_poly_caddq_aarch64_asm.S \
     mldsa_poly_chknorm_aarch64_asm.S \
     mldsa_poly_decompose_32_aarch64_asm.S \
     mldsa_poly_decompose_88_aarch64_asm.S \
     mldsa_poly_use_hint_32_aarch64_asm.S \
     mldsa_poly_use_hint_88_aarch64_asm.S \
     mldsa_polyz_unpack_17_aarch64_asm.S \
     mldsa_polyz_unpack_19_aarch64_asm.S \
     mldsa_rej_uniform_aarch64_asm.S \
     mldsa_rej_uniform_eta2_aarch64_asm.S \
     mldsa_rej_uniform_eta4_aarch64_asm.S

# These units explicitly save and restore registers v8-v15, so SLOTHY can freely use
# those registers.
mldsa_ntt_aarch64_asm.S: ../../aarch64_clean/src/mldsa_ntt_aarch64_asm.S
	# optimize first loop in one go and write to temp file
	$(eval TMPFILE := $(shell mktemp))
	slothy-cli $(TARGET_ISA) $(TARGET_MICROARCH) $< -o $(TMPFILE) -l mld_ntt_layer123_start $(SLOTHY_FLAGS) $(RESERVE_X_ONLY_FLAG)
	# optimize second loop using split heuristic
	slothy-cli $(TARGET_ISA) $(TARGET_MICROARCH) $(TMPFILE) -o $@ -l mld_ntt_layer45678_start $(SLOTHY_FLAGS_SPLIT) -c split_heuristic_factor=1.5 $(RESERVE_X_ONLY_FLAG)

# Copy remaining files without optimization for now
mldsa_intt_aarch64_asm.S: ../../aarch64_clean/src/mldsa_intt_aarch64_asm.S
	# optimize first loop in one go and write to temp file
	$(eval TMPFILE := $(shell mktemp))
	slothy-cli $(TARGET_ISA) $(TARGET_MICROARCH) $< -o $(TMPFILE) -l mld_intt_layer5678_start $(SLOTHY_FLAGS) -c reserved_regs="[x0,x18--x30,sp]"
	# optimize second loop using split heuristic
	slothy-cli $(TARGET_ISA) $(TARGET_MICROARCH) $(TMPFILE) -o $@ -l mld_intt_layer1234_start $(SLOTHY_FLAGS_SPLIT) -c split_heuristic_factor=2.5 $(RESERVE_X_ONLY_FLAG)

mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S: ../../aarch64_clean/src/mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S
	cp $< $@

mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S: ../../aarch64_clean/src/mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S
	cp $< $@

mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S: ../../aarch64_clean/src/mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S
	cp $< $@

mldsa_pointwise_montgomery_aarch64_asm.S: ../../aarch64_clean/src/mldsa_pointwise_montgomery_aarch64_asm.S
	cp $< $@

mldsa_poly_caddq_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_caddq_aarch64_asm.S
	cp $< $@

mldsa_poly_chknorm_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_chknorm_aarch64_asm.S
	cp $< $@

mldsa_poly_decompose_32_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_decompose_32_aarch64_asm.S
	cp $< $@

mldsa_poly_decompose_88_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_decompose_88_aarch64_asm.S
	cp $< $@

mldsa_poly_use_hint_32_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_use_hint_32_aarch64_asm.S
	cp $< $@

mldsa_poly_use_hint_88_aarch64_asm.S: ../../aarch64_clean/src/mldsa_poly_use_hint_88_aarch64_asm.S
	cp $< $@

mldsa_polyz_unpack_17_aarch64_asm.S: ../../aarch64_clean/src/mldsa_polyz_unpack_17_aarch64_asm.S
	cp $< $@

mldsa_polyz_unpack_19_aarch64_asm.S: ../../aarch64_clean/src/mldsa_polyz_unpack_19_aarch64_asm.S
	cp $< $@

mldsa_rej_uniform_aarch64_asm.S: ../../aarch64_clean/src/mldsa_rej_uniform_aarch64_asm.S
	cp $< $@

mldsa_rej_uniform_eta2_aarch64_asm.S: ../../aarch64_clean/src/mldsa_rej_uniform_eta2_aarch64_asm.S
	cp $< $@

mldsa_rej_uniform_eta4_aarch64_asm.S: ../../aarch64_clean/src/mldsa_rej_uniform_eta4_aarch64_asm.S
	cp $< $@

clean:
	-$(RM) -rf *.S
