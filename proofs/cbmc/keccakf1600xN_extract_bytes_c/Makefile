# Copyright (c) The mldsa-native project authors
# Copyright (c) The mlkem-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = keccakf1600xN_extract_bytes_c_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = keccakf1600xN_extract_bytes_c

DEFINES += 
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/fips202/keccakf1600.c

CHECK_FUNCTION_CONTRACTS=mld_keccakf1600xN_extract_bytes_c
USE_FUNCTION_CONTRACTS=mld_keccakf1600_extract_bytes
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Supported CBMC configurations
CBMC_SUPPORTED_CONFIGS = \
  LP64:bitwuzla \
  LP64:z3 \
  LP64:cvc5_arrays_exp
CBMC_DEFAULT_CONFIG = LP64:bitwuzla

FUNCTION_NAME = mld_keccakf1600xN_extract_bytes_c

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
