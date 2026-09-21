#############################################################################
# Copyright (c) The mldsa-native project authors
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
#############################################################################

.DEFAULT_GOAL := run_proofs

OSTYPE_RESULT=$(shell uname -s)

SRC ?= $(S2N_BIGNUM_DIR)

CROSS_PREFIX ?= riscv32-unknown-linux-gnu-
ARCHFLAGS = -march=rv32im -mabi=ilp32

ifeq ($(shell command -v $(CROSS_PREFIX)as >/dev/null 2>&1 && echo yes),)
$(error Cross-toolchain not found. Please run in the 'hol_light-cross-riscv32' nix shell via: nix develop .#hol_light-cross-riscv32)
endif

ASSEMBLE = $(CROSS_PREFIX)as $(ARCHFLAGS)
OBJDUMP = $(CROSS_PREFIX)objdump -d
STRIP = $(CROSS_PREFIX)strip

ifeq ($(OSTYPE_RESULT),Darwin)
PREPROCESS = sed -e 's/\/\/.*//' | $(CC) -E -xassembler-with-cpp -
else
PREPROCESS = $(CC) -E -xassembler-with-cpp -
endif

SPLIT = tr ';' '\n'

OBJ = mldsa/mldsa_ntt_rv32im_asm.o \
      mldsa/mldsa_ntt_rv32im_slowmul_asm.o \
      mldsa/mldsa_intt_rv32im_asm.o \
      mldsa/mldsa_intt_rv32im_slowmul_asm.o \
      mldsa/mldsa_poly_pointwise_montgomery_rv32im_asm.o

$(OBJ): %.o : %.S
	@echo "Preparing $@ ..."
	@echo "AS: `$(ASSEMBLE) --version`"
	@echo "OBJDUMP: `$(OBJDUMP) --version`"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	cat $< | $(PREPROCESS) | $(SPLIT) | $(ASSEMBLE) -o $@ -
	$(STRIP) $@

clean:; rm -f */*.o */*/*.o */*.correct */*.native

HOLDIR ?= $(HOLLIGHTDIR)
HOLLIGHT := $(HOLDIR)/hol.sh

BASE ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PROOF_BINS = $(OBJ:.o=.native)
PROOF_LOGS = $(OBJ:.o=.correct)

proofs/dump_bytecode.native: proofs/dump_bytecode.ml $(OBJ)
	./proofs/build-proof.sh $(BASE)/$< "$(HOLLIGHT)" "$@"

.SECONDEXPANSION:
%.native: proofs/$$(*F).ml %.o
	./proofs/build-proof.sh $(BASE)/$< "$(HOLLIGHT)" "$@"

%.correct: %.native
	cd .. ; ./riscv32/$< 2>&1 | tee ./riscv32/$@
	@if (grep -i "error:\|exception:" "$@" >/dev/null); then \
		echo "$< had errors!"; \
		exit 1; \
	else \
		echo "$< OK"; \
	fi

build_proofs: $(PROOF_BINS);
run_proofs: build_proofs $(PROOF_LOGS);

proofs: run_proofs ; $(SRC)/tools/count-proofs.sh .

dump_bytecode: proofs/dump_bytecode.native
	cd .. ; ./riscv32/$<

.PHONY: proofs build_proofs run_proofs clean dump_bytecode
