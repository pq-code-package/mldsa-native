# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ stdenv, fetchFromGitHub, writeText, ... }:
stdenv.mkDerivation rec {
  pname = "s2n_bignum";
  version = "32d9bbfe8ad3b1cc6c2f06b81bee1630685d08c6";
  src = fetchFromGitHub {
    owner = "hanno-becker";
    repo = "s2n-bignum";
    rev = "${version}";
    hash = "sha256-RGVCB7Zqu1TD+0KLQYAG29b7sbji2HaCLBQS7xR5StM=";
  };
  setupHook = writeText "setup-hook.sh" ''
    export S2N_BIGNUM_DIR="$1"
  '';
  patches = [ ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -a . $out/
  '';
}
