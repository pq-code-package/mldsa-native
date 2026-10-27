# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ stdenv, fetchFromGitHub, writeText, ... }:
stdenv.mkDerivation rec {
  pname = "s2n_bignum";
  version = "a87e6f9f6180bdf11b8563993cb8950f7719dd72";
  src = fetchFromGitHub {
    owner = "hanno-becker";
    repo = "s2n-bignum";
    rev = "${version}";
    hash = "sha256-eB+MsFz6iAFir1obxd6iTzQAm0Cn1r5Ip5fXLkF5O6c=";
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
