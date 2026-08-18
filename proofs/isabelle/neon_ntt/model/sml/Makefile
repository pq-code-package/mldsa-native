# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Build the SML reference model_exec wrapper by:
#   1) running `isabelle build NeonNTT` (which produces model.ML via export_code),
#   2) extracting model.ML to export/...,
#   3) emitting a thin shell wrapper that invokes Isabelle's bundled `poly`
#      with --use main.sml (which itself `use`s the generated model.ML).
#
# Override ISABELLE_DIR if your Isabelle install lives elsewhere:
#   make ISABELLE_DIR=/path/to/Isabelle2025-2.app
# Everything else is queried from Isabelle.
#
# We deliberately avoid `polyc` here: it would require linking against
# Isabelle's bundled libgmp, whose shipped install_name on macOS points at
# the (long-deleted) build-host path. `poly` itself has the right rpath
# baked in, so invoking it directly side-steps the whole mess.

ISABELLE_DIR ?= /Applications/Isabelle2025-2.app
ISABELLE     := $(ISABELLE_DIR)/bin/isabelle

POLYML_HOME    := $(shell $(ISABELLE) getenv -b POLYML_HOME)
APPLE_PLATFORM := $(shell $(ISABELLE) getenv -b ISABELLE_APPLE_PLATFORM64)
PLATFORM64     := $(shell $(ISABELLE) getenv -b ISABELLE_PLATFORM64)
ML_PLATFORM    := $(if $(APPLE_PLATFORM),$(APPLE_PLATFORM),$(PLATFORM64))
POLY           := $(POLYML_HOME)/$(ML_PLATFORM)/poly

NEON_NTT_DIR := $(realpath ../..)
HERE         := $(realpath .)

GENERATED := export/NeonNTT.Word_Ops_Export/code/model.ML

.PHONY: all clean build_isabelle

all: model_exec

build_isabelle:
	cd $(NEON_NTT_DIR) && $(ISABELLE) build -d . NeonNTT

$(GENERATED): build_isabelle
	rm -rf export
	cd $(NEON_NTT_DIR) && $(ISABELLE) export -d . -O $(HERE)/export -x '*:code/*' NeonNTT

model_exec: $(GENERATED) main.sml Makefile
	@# Wrapper script: cd to this dir (so main.sml's relative `use` of
	@# export/.../model.ML resolves), then invoke poly. The `--` separator
	@# isolates user argv from poly's own flags; main.sml's user_args ()
	@# strips everything before the `--`.
	@printf '%s\n' \
	  '#!/bin/sh' \
	  'cd "$(HERE)" || exit 1' \
	  'exec "$(POLY)" -q --use main.sml --eval "val () = main ()" --error-exit -- "$$@"' \
	  > $@
	@chmod +x $@

clean:
	rm -rf export model_exec build
