# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

{ stdenvNoCC, writeText }:

stdenvNoCC.mkDerivation {
  pname = "mldsa-native-m33-an524";
  version = "local-2026-01-10";
  
  src = ../../envs/m33-an524;
  
  dontBuild = true;
  
  installPhase = ''
    mkdir -p $out/
    cp -r . $out/
  '';
  
  setupHook = writeText "setup-hook.sh" ''
    export M33_AN524_PATH="$1/src/platform/"
  '';

  meta = {
    description = "Platform files for the Cortex-M33 (AN524)";
    homepage = "https://github.com/mldsa-native/mldsa-native";
  };
}