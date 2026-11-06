#!/usr/bin/env bash
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Lists the main theorems of the RV32IM HOL-Light proofs, one per line.
# Only the subroutine correctness and safety theorems are replayed.
#
# Usage: list_thms.sh [ROUTINE...]  (default: all routines)

set -euo pipefail

if [[ $# == 0 ]]; then
  routines=$("$(dirname "$(realpath "$0")")/list_proofs.sh")
  # shellcheck disable=SC2086 # routine names contain no spaces
  set -- $routines
fi

for routine in "$@"; do
  case "$routine" in
    mldsa_ntt_rv32im_slowmul_asm)
      prefix=MLDSA_NTT_SLOW
      ;;
    mldsa_intt_rv32im_slowmul_asm)
      prefix=MLDSA_INTT_SLOW
      ;;
    mldsa_poly_pointwise_montgomery_rv32im_asm)
      prefix=MLDSA_POINTWISE_MONTGOMERY
      ;;
    *)
      prefix=$(echo "${routine%_rv32im_asm}" | tr '[:lower:]' '[:upper:]')
      ;;
  esac
  echo "${prefix}_SUBROUTINE_CORRECT"
  echo "${prefix}_SUBROUTINE_SAFE"
done
