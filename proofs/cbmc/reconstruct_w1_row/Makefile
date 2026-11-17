# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = reconstruct_w1_row_harness
PROOF_UID = reconstruct_w1_row

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/sign.c

CHECK_FUNCTION_CONTRACTS=mld_reconstruct_w1_row
USE_FUNCTION_CONTRACTS=mld_unpack_pk_t1
USE_FUNCTION_CONTRACTS+=mld_sig_unpack_hints
USE_FUNCTION_CONTRACTS+=mld_poly_ntt
USE_FUNCTION_CONTRACTS+=mld_poly_shiftl
USE_FUNCTION_CONTRACTS+=mld_poly_pointwise_montgomery
USE_FUNCTION_CONTRACTS+=mld_poly_sub
USE_FUNCTION_CONTRACTS+=mld_poly_reduce
USE_FUNCTION_CONTRACTS+=mld_poly_invntt_tomont
USE_FUNCTION_CONTRACTS+=mld_poly_caddq
USE_FUNCTION_CONTRACTS+=mld_poly_use_hint
USE_FUNCTION_CONTRACTS+=mld_polyw1_pack

APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

CBMC_SUPPORTED_CONFIGS = LP64:z3_no_bv_extract
CBMC_DEFAULT_CONFIG = LP64:z3_no_bv_extract

FUNCTION_NAME = reconstruct_w1_row
CBMC_OBJECT_BITS = 10

include ../Makefile.common
