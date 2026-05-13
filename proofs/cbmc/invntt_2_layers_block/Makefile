# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = invntt_2_layers_block_harness

PROOF_UID = mld_invntt_2_layers_block

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly.c

CHECK_FUNCTION_CONTRACTS=mld_invntt_2_layers_block
USE_FUNCTION_CONTRACTS=mld_fqmul
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--bitwuzla

FUNCTION_NAME = mld_invntt_2_layers_block

CBMC_OBJECT_BITS = 9

include ../Makefile.common
