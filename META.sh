#!/usr/bin/env bash
# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Helper script to query META.yml
#
# Arguments
# - Scheme to query: ML-DSA-44, ML-DSA-65, ML-DSA-87
# - Field to query, e.g. "kat-sha256"
#
# Optional:
# - Value to compare against. If omitted, stdin is read instead:
#   if stdin is "SKIPPED", the test is reported as skipped;
#   otherwise stdin is hashed with sha256 and compared.

META=META.yml

# Manual extraction of metadata with basic cmd line tools
VAL=$(cat $META |
  grep "name\|$2" |
  grep "$1" -A 1 |
  grep "$2" |
  cut -d ":" -f 2 | tr -d ' ')

# More robust extraction using yq
if (which yq >/dev/null 2>&1); then
  QUERY=".implementations | .[] | select(.name==\"$1\") | .\"$2\""
  echo "cat $META | yq \"$QUERY\" -r"
  VAL_JQ=$(cat $META | yq "$QUERY" -r)

  if [[ $VAL_JQ != "$VAL" ]]; then
    echo "ERROR parsing metadata file $META"
    exit 1
  fi
fi

# Determine the input to compare against
if [[ $3 != "" ]]; then
  INPUT=$3
else
  STDIN=$(cat)
  if [[ $STDIN == SKIPPED* ]]; then
    echo "$META $1 $2: SKIPPED"
    exit 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    SHA256SUM="shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    SHA256SUM="sha256sum"
  else
    echo "ERROR: Neither 'shasum' nor 'sha256sum' found."
    exit 1
  fi
  INPUT=$(echo "$STDIN" | $SHA256SUM | cut -d " " -f 1)
fi

if [[ $INPUT != "$VAL" ]]; then
  echo "$META $1 $2: FAIL ($VAL != $INPUT)"
  exit 1
else
  echo "$META $1 $2: OK"
  exit 0
fi
