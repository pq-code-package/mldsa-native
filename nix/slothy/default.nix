# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# slothy is packaged in nixpkgs (>= 26.05) and used by default.
#
# To pin a specific upstream revision instead, comment out `pkgs.slothy`
# below and uncomment the override, adjusting `version`/`sha256`.

{ pkgs }:

# pkgs.slothy

pkgs.slothy.overrideAttrs (old: rec {
  # slothy-optimizer/slothy#464: Cortex-M55 shifted-source latency model.
  version = "fed47d3f1e40b9c1f202f759f1d6c4100fe14f4d";
  src = pkgs.fetchFromGitHub {
    owner = "slothy-optimizer";
    repo = "slothy";
    rev = version;
    sha256 = "sha256-x8bioD4mKxu5YxOpL4yuLV3tIJG6fCD+gsOvrJ/1P24=";
  };
})
