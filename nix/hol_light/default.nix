# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# To pin a specific upstream revision instead of nixpkgs' hol_light, comment
# out `pkgs.hol_light` below and uncomment the override, adjusting
# `version`/`rev`/`hash`.

{ pkgs }:

pkgs.hol_light

# pkgs.hol_light.overrideAttrs (old: rec {
#   version = "unstable-2026-09-19";
#   src = pkgs.fetchFromGitHub {
#     owner = "jrh13";
#     repo = "hol-light";
#     rev = "cba9198db76e9dfb89cbd653df9412d01f65b22a";
#     hash = "sha256-y9Z5QN2+STyKKgU20nugAocu+/sz6YpfxwBDjASC/d4=";
#   };
#   # Current HOL Light already accepts camlp5 8.05. Keep only nixpkgs'
#   # findlib-linkage patch.
#   patches = [ (builtins.elemAt old.patches 1) ];
# })
