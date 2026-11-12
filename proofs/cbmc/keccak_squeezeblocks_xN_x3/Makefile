# Copyright (c) The mldsa-native project authors
# Copyright (c) The mlkem-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Same proof as ../keccak_squeezeblocks_xN (same harness), at batching factor 3 (MLD_CONFIG_USE_X3).

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = keccak_squeezeblocks_xN_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = keccak_squeezeblocks_xN_x3

DEFINES += -DMLD_CONFIG_USE_X3
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/fips202/fips202xN.c

CHECK_FUNCTION_CONTRACTS=mld_keccak_squeezeblocks_xN
USE_FUNCTION_CONTRACTS=mld_keccakf1600xN_extract_bytes mld_keccakf1600xN_permute
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Supported CBMC configurations
CBMC_SUPPORTED_CONFIGS = \
  LP64:bitwuzla \
  LP64:z3
CBMC_DEFAULT_CONFIG = LP64:bitwuzla

FUNCTION_NAME = mld_keccak_squeezeblocks_xN

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
