#!/usr/bin/env bash
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT" || exit

if [[ $# == 0 ]]; then
  set -- proofs/hol_light/riscv32/proofs/*.ml
fi

grep -hE "^[[:space:]]*let[[:space:]]+[^[:space:]]+[[:space:]]+=[[:space:]]+(time[[:space:]]+)?prove" "$@" |
  sed -E "s/^[[:space:]]*let[[:space:]]+([^[:space:]]+)[[:space:]]+=.*/\1/"
