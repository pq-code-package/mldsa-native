# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = sign_finish_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = mld_sign_finish

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/sign.c

CHECK_FUNCTION_CONTRACTS=mld_sign_hook_finish
USE_FUNCTION_CONTRACTS=

APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Supported CBMC configurations
CBMC_SUPPORTED_CONFIGS = LP64:z3
CBMC_DEFAULT_CONFIG = LP64:z3

FUNCTION_NAME = mld_sign_hook_finish

CBMC_OBJECT_BITS = 8

include ../Makefile.common
