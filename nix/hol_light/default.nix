# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# To pin a specific upstream revision instead of nixpkgs' hol_light, merge
# the commented override below into the active one, adjusting
# `version`/`rev`/`hash`.

{ pkgs }:

pkgs.hol_light.overrideAttrs (old: {
  # HOL Light's build uses update_database_5.4.ml, written for the
  # Longident.Ldot interface that OCaml 5.4 introduced, only for OCaml
  # 5.4 itself. With OCaml 5.5 it would use update_database_5.ml, which
  # HOL Light loads at startup and which no longer type-checks.
  # Use the 5.4 helper for OCaml 5.5 too.
  postPatch = (old.postPatch or "") + ''
    substituteInPlace update_database/chooser.sh \
      --replace-fail 'if [ ''${OCAML_BINARY_VERSION} = "5.4" ]' \
        'if [ ''${OCAML_BINARY_VERSION} = "5.4" ] || [ ''${OCAML_BINARY_VERSION} = "5.5" ]'
  '';
})

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
