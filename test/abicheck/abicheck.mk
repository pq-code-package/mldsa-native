# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# WARNING: This file is auto-generated from scripts/autogen
#          in the mldsa-native repository.
#          Do not modify it directly.
#
# Includes the per-arch abicheck_<arch>.mk, each of which appends
# its capabilities' CFLAGS to the matching .S objects.

include test/abicheck/aarch64/abicheck_aarch64.mk
include test/abicheck/armv81m/abicheck_armv81m.mk
include test/abicheck/x86_64/abicheck_x86_64.mk
