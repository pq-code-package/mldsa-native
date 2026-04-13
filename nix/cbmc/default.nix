# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ buildEnv
, cbmc
, fetchFromGitHub
, callPackage
, bitwuzla
, ninja
, cadical
, z3
, cudd
, replaceVars
, fetchpatch
}:

buildEnv {
  name = "pqcp-cbmc";
  paths =
    builtins.attrValues {
      cbmc = cbmc.overrideAttrs (old: rec {
        version = "6.8.0";
        src = fetchFromGitHub {
          owner = "hanno-becker";
          repo = "cbmc";
          hash = "sha256-P6aIyOOrrjQz6vpxlVFN7X306oC+8FG/PSX4j5k2g+k=";
          rev = "9135bb7c68401a306bd0f6077577bb57d17f0e42";
        };
        srccadical = cadical.src; # 3.0.0 from nixpkgs-unstable
        patches = [
          (builtins.elemAt old.patches 0) # cudd patch from nixpkgs
          ./0002-Do-not-download-sources-in-cmake.patch # cadical 3.0.0
        ];
        env = old.env // {
          NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=switch-enum";
        };
      });
      litani = callPackage ./litani.nix { }; # 1.29.0
      cbmc-viewer = callPackage ./cbmc-viewer.nix { }; # 3.12
      z3 = z3.overrideAttrs (old: rec {
        version = "4.15.3";
        src = fetchFromGitHub {
          owner = "Z3Prover";
          repo = "z3";
          rev = "z3-4.15.3";
          hash = "sha256-Lw037Z0t0ySxkgMXkbjNW5CB4QQLRrrSEBsLJqiomZ4=";
        };
      });

      inherit
        cadical# 3.0.0
        bitwuzla# 0.8.2
        ninja; # 1.13.2
    };
}
