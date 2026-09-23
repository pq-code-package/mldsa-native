#!/usr/bin/env bash
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT" || exit
ls -1 proofs/hol_light/riscv32/mldsa/*.S |
  cut -d '/' -f 5 |
  sed 's/\.S//'
