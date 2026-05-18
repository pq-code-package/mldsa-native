# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

ISABELLE_VERSION ?= Isabelle2025-2
ISABELLE_HOME ?= /Applications/$(ISABELLE_VERSION).app/bin
ISABELLE_DIR  ?= /Applications/$(ISABELLE_VERSION).app

PDF_NAME ?= neon_ntt_autoformalized.pdf

# Number of random samples per non-8-bit op when running `make conformance`.
CONFORMANCE_RUNS ?= 50000

# Locate the Isabelle binary up-front: bail out with a clear message rather
# than letting `make` die on an opaque "No such file or directory" when the
# default macOS app path doesn't apply.
define CHECK_ISABELLE
	@if [ ! -x "$(ISABELLE_HOME)/isabelle" ]; then \
	  echo "error: '$(ISABELLE_HOME)/isabelle' not found or not executable." >&2; \
	  echo "Set ISABELLE_HOME to the directory containing the 'isabelle' binary, e.g.:" >&2; \
	  echo "  make ISABELLE_HOME=/path/to/Isabelle/bin $@" >&2; \
	  exit 1; \
	fi
endef

all:
	$(CHECK_ISABELLE)
	$(ISABELLE_HOME)/isabelle build -D .
	cp output/document.pdf $(PDF_NAME)

clean:
	$(CHECK_ISABELLE)
	$(ISABELLE_HOME)/isabelle build -c -D .
	rm -f $(PDF_NAME)
	$(MAKE) -C model/hw clean
	$(MAKE) -C model/sml clean

jedit:
	$(CHECK_ISABELLE)
	$(ISABELLE_HOME)/isabelle jedit -D . Asm_Montgomery.thy

# --- Conformance testing -------------------------------------------------
# Build the AArch64 NEON reference (model/hw) and the Isabelle-exported SML
# model (model/sml), then drive both side-by-side from model/conformance.

model/hw/hw_exec:
	$(MAKE) -C model/hw

model/sml/model_exec:
	$(MAKE) -C model/sml ISABELLE_DIR=$(ISABELLE_DIR)

conformance: model/hw/hw_exec model/sml/model_exec
	python3 model/conformance/run.py edge
	python3 model/conformance/run.py random -n $(CONFORMANCE_RUNS)

.PHONY: all clean jedit conformance
