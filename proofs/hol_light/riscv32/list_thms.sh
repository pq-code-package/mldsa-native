#!/usr/bin/env bash
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Lists the main theorems of the RV32IM HOL-Light proofs, one per line.
# These are the theorems each proof must establish (checked by `lint`)
# and the ones that trace replay checks. Only the subroutine
# theorems, which describe a call of the routine, are listed; the core
# theorems that they are derived from are intermediate results.
#
# The prefix is the routine name without _rv32im_asm, in upper case. It
# carries the `mldsa_` namespace. For routine foo_rv32im_asm:
#   FOO_SUBROUTINE_CORRECT, FOO_SUBROUTINE_SAFE
# The slow-multiplication NTTs and the pointwise multiplication name
# their theorems differently from their routines.
# rej_uniform has no constant-time proof and uses MEMSAFE instead of SAFE.
#
# Usage: list_thms.sh [ROUTINE...]  (default: all routines of list_proofs.sh)

set -euo pipefail

if [[ $# == 0 ]]; then
  routines=$("$(dirname "$(realpath "$0")")/list_proofs.sh")
  # shellcheck disable=SC2086 # routine names contain no spaces
  set -- $routines
fi

for routine in "$@"; do
  name=${routine%_rv32im_asm}
  [[ $routine == mldsa_ntt_rv32im_slowmul_asm ]] && name=mldsa_ntt_slow
  [[ $routine == mldsa_intt_rv32im_slowmul_asm ]] && name=mldsa_intt_slow
  [[ $routine == mldsa_poly_pointwise_montgomery_rv32im_asm ]] && name=mldsa_pointwise_montgomery
  prefix=$(echo "$name" | tr '[:lower:]' '[:upper:]')
  safe=SAFE
  [[ $routine == mldsa_rej_uniform_rv32im_asm ]] && safe=MEMSAFE
  echo "${prefix}_SUBROUTINE_CORRECT"
  echo "${prefix}_SUBROUTINE_${safe}"
done
