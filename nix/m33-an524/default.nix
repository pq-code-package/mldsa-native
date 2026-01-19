# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

{ stdenvNoCC
, m33-an524-cmsis
, fetchFromGitHub
, writeText
}:

stdenvNoCC.mkDerivation {
  pname = "m33-an524-platform";
  version = "2026-01-15";

  # Fetch platform files from pqmx (envs/m55-an547)
  src = fetchFromGitHub {
    owner = "slothy-optimizer";
    repo = "pqmx";
    rev = "4ed493d3cf2af62a08fd9fe36c3472a0dc50ad9f";
    hash = "sha256-jLIqwknjRwcoDeEAETlMhRqZQ5a3QGCDZX9DENelGeQ=";
  };

  buildInputs = [ m33-an524-cmsis ];

  buildPhase = ''
    runHook preBuild
    
    # Create directory structure for patching
    mkdir -p envs/m33-an524/src/platform
    
    # Copy m55 platform files to m33 location
    cp -r envs/m55-an547/src/platform/. envs/m33-an524/src/platform/
    cp integration/*.c envs/m33-an524/src/platform/
    
    # Make files writable
    chmod -R u+w envs/
    
    # Patch cmdline.c to change ARMCM55.h to ARMCM33.h
    sed -i 's/#include "ARMCM55\.h"/#include "ARMCM33.h"/' envs/m33-an524/src/platform/cmdline.c
    
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/platform/CMSIS
    
    # Copy CMSIS files from CMSIS derivation
    cp -r ${m33-an524-cmsis}/CMSIS/* $out/platform/CMSIS/
    
    # Copy patched platform files
    cp envs/m33-an524/src/platform/uart.c $out/platform/
    cp envs/m33-an524/src/platform/uart.h $out/platform/
    cp envs/m33-an524/src/platform/cmdline.c $out/platform/
    cp envs/m33-an524/src/platform/libfns.c $out/platform/
    cp envs/m33-an524/src/platform/semihosting.c $out/platform/
  '';

  setupHook = writeText "setup-hook.sh" ''
    export M33_AN524_PATH="$1/platform"
    export M33_AN524_CMSIS_PATH="$1/platform/CMSIS"
  '';

  meta = {
    description = "Platform files for Cortex-M33 (AN524) with patched CMSIS";
    homepage = "https://github.com/ARM-software/CMSIS_5";
  };
}
