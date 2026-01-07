# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

{ stdenvNoCC
, fetchFromGitHub
}:

let
  # CMSIS_5 repository from ARM
  # Commit: 55b19837f5703e418ca37894d5745b1dc05e4c91 (2024-09-03)
  # This commit corresponds to CMSIS v5.3.0 on the develop branch
  # 
  # Rationale for using fetchFromGitHub:
  # - Fetches entire repository once instead of 12 individual files
  # - More resilient to upstream URL changes
  # - Easier to add new files from the same repository
  # - Only requires maintaining one SHA256 hash
  #
  # To update to a newer CMSIS_5 version:
  # 1. Find the desired commit hash from https://github.com/ARM-software/CMSIS_5
  # 2. Run: nix-prefetch-github ARM-software CMSIS_5 --rev <commit-hash>
  # 3. Update the rev and sha256 below
  # 4. Verify all file paths still exist in the new commit
  # 5. Test that patches still apply successfully
  cmsis5_src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "CMSIS_5";
    rev = "55b19837f5703e418ca37894d5745b1dc05e4c91";
    sha256 = "07hdcpd90r7g1wy1km2k69q2ny43bksdy8d3hpb32y1fgl83xra5";
  };

in
stdenvNoCC.mkDerivation {
  pname = "m33-an524-cmsis";
  version = "2026-01-29";

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    
    # Create directory structure matching patch expectations
    mkdir -p envs/m33-an524/src/platform/m-profile

    # Copy CMSIS_5 files from repository to match patch paths
    # All files are sourced from the CMSIS_5 repository at commit 55b19837
    cp ${cmsis5_src}/CMSIS/Core/Include/core_cm33.h envs/m33-an524/src/platform/core_cm33.h
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_compiler.h envs/m33-an524/src/platform/cmsis_compiler.h
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_gcc.h envs/m33-an524/src/platform/cmsis_gcc.h
    cp ${cmsis5_src}/CMSIS/Core/Include/cmsis_version.h envs/m33-an524/src/platform/cmsis_version.h
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Include/ARMCM33.h envs/m33-an524/src/platform/ARMCM33.h
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/startup_ARMCM33.c envs/m33-an524/src/platform/startup_ARMCM33.c
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/system_ARMCM33.c envs/m33-an524/src/platform/system_ARMCM33.c
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Include/system_ARMCM33.h envs/m33-an524/src/platform/system_ARMCM33.h
    cp ${cmsis5_src}/Device/ARM/ARMCM33/Source/GCC/gcc_arm.ld envs/m33-an524/src/platform/m33-an524.ld
    cp ${cmsis5_src}/CMSIS/Core/Include/mpu_armv8.h envs/m33-an524/src/platform/m-profile/armv8m_mpu.h
    cp ${cmsis5_src}/CMSIS/Core/Include/cachel1_armv7.h envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h

    # Make files writable for patching
    chmod -R u+w envs/

    # Copy patches from repository
    cp -r ${../../test/baremetal/platform/m33-an524/patches} patches
    chmod -R u+w patches

    # Apply patches to customize files for mldsa-native
    patch -p0 < patches/cmsis5/core_cm33.h.patch || true
    patch -p0 < patches/cmsis5/ARMCM33.patch || true
    patch -p0 < patches/cmsis5/startup_ARMCM33.patch || true
    patch -p0 < patches/cmsis5/system_ARMCM33.patch || true
    patch -p0 < patches/cmsis5/m33-an524.ld.patch || true
    
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/CMSIS/m-profile
    
    # Copy patched files to output in CMSIS directory structure
    cp envs/m33-an524/src/platform/core_cm33.h $out/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_compiler.h $out/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_gcc.h $out/CMSIS/
    cp envs/m33-an524/src/platform/cmsis_version.h $out/CMSIS/
    cp envs/m33-an524/src/platform/ARMCM33.h $out/CMSIS/
    cp envs/m33-an524/src/platform/startup_ARMCM33.c $out/CMSIS/
    cp envs/m33-an524/src/platform/system_ARMCM33.c $out/CMSIS/
    cp envs/m33-an524/src/platform/system_ARMCM33.h $out/CMSIS/
    cp envs/m33-an524/src/platform/m33-an524.ld $out/CMSIS/
    cp envs/m33-an524/src/platform/m-profile/armv8m_mpu.h $out/CMSIS/m-profile/
    cp envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h $out/CMSIS/m-profile/
  '';

  meta = {
    description = "Patched CMSIS files for Cortex-M33 (AN524)";
    homepage = "https://github.com/ARM-software/CMSIS_5";
  };
}
