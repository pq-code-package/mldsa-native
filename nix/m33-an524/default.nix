# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

{ stdenvNoCC
, fetchFromGitHub
, writeText
}:

let
  cmsis5_src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "CMSIS_5";
    rev = "55b19837f5703e418ca37894d5745b1dc05e4c91";
    sha256 = "07hdcpd90r7g1wy1km2k69q2ny43bksdy8d3hpb32y1fgl83xra5";
  };

in
stdenvNoCC.mkDerivation {
  pname = "m33-an524-platform";
  version = "2026-01-30";

  # Fetch platform files from pqmx (envs/m55-an547)
  src = fetchFromGitHub {
    owner = "slothy-optimizer";
    repo = "pqmx";
    rev = "4ed493d3cf2af62a08fd9fe36c3472a0dc50ad9f";
    hash = "sha256-jLIqwknjRwcoDeEAETlMhRqZQ5a3QGCDZX9DENelGeQ=";
  };

  buildPhase = ''
    runHook preBuild

    # Create directory structure for patching
    mkdir -p envs/m33-an524/src/platform/m-profile

    # --- Platform files from pqmx (copy first, then make writable) ---
    cp -r envs/m55-an547/src/platform/. envs/m33-an524/src/platform/
    cp integration/*.c envs/m33-an524/src/platform/
    chmod -R u+w envs/

    # --- CMSIS files from ARM CMSIS_5 (commit 55b19837) ---
    cp ${cmsis5_src}/CMSIS/Core/Include/core_cm33.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_compiler.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_gcc.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_version.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Include/ARMCM33.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/startup_ARMCM33.c envs/m33-an524/src/platform/
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/system_ARMCM33.c envs/m33-an524/src/platform/
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Include/system_ARMCM33.h envs/m33-an524/src/platform/
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/GCC/gcc_arm.ld envs/m33-an524/src/platform/m33-an524.ld
    cp ${cmsis5_src}/CMSIS/Core/Include/mpu_armv8.h envs/m33-an524/src/platform/m-profile/armv8m_mpu.h
    cp ${cmsis5_src}/CMSIS/Core/Include/cachel1_armv7.h envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h

    # Copy patches from repository
    cp -r ${../../test/baremetal/platform/m33-an524/patches} patches
    chmod -R u+w patches

    # Apply CMSIS patches
    patch -p0 < patches/cmsis5/core_cm33.h.patch
    patch -p0 < patches/cmsis5/ARMCM33.patch
    patch -p0 < patches/cmsis5/startup_ARMCM33.patch
    patch -p0 < patches/cmsis5/system_ARMCM33.patch
    patch -p0 < patches/cmsis5/m33-an524.ld.patch

    # Apply platform patches
    patch -p0 < patches/platform/cmdline.patch
    patch -p0 < patches/platform/uart.patch

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/platform/CMSIS/m-profile

    # CMSIS files
    cp envs/m33-an524/src/platform/core_cm33.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_compiler.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_gcc.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_version.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/ARMCM33.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/startup_ARMCM33.c $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/system_ARMCM33.c $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/system_ARMCM33.h $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/m33-an524.ld $out/platform/CMSIS/
    cp envs/m33-an524/src/platform/m-profile/armv8m_mpu.h $out/platform/CMSIS/m-profile/
    cp envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h $out/platform/CMSIS/m-profile/

    # Platform files
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
    description = "Platform and CMSIS files for Cortex-M33 (AN524)";
    homepage = "https://github.com/ARM-software/CMSIS_5";
  };
}
