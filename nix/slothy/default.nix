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
  version = "0.2.2";
  src = pkgs.fetchFromGitHub {
    owner = "slothy-optimizer";
    repo = "slothy";
    rev = version;
    sha256 = "sha256-pyES6ithBVAFSVdjsM61kp6eeEUxNsLs7jdekpX+YuA=";
  };
})
