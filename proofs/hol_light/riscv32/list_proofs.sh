#!/usr/bin/env bash
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

set -euo pipefail
cd "$(dirname "$(realpath "$0")")/mldsa"
ls -1 -- *.S | sed 's/\.S$//'
