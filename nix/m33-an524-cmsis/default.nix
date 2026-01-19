# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

{ stdenvNoCC
, fetchurl
}:

let
  # CMSIS_5 files from ARM repository (using develop branch commit with V5.3.0)
  cmsis5_core_cm33 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/core_cm33.h";
    sha256 = "0wjb20lr31kbfqq5hc6bx7pvl13crs12xvjzv6sz8q11wm83qqvm";
  };

  cmsis5_cmsis_compiler = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/cmsis_compiler.h";
    sha256 = "10id6sg8vcq5ldia2r3lqx2qb43mqh77amkqihi4x3d80kfmwz3l";
  };

  cmsis5_cmsis_gcc = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/cmsis_gcc.h";
    sha256 = "0201ac72m93nv9y30yim1xmy9xa30hsdfa1vh3af8n3g5f1wv4ig";
  };

  cmsis5_cmsis_version = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/cmsis_version.h";
    sha256 = "1cx4ps1zl1fvv4cwnv4yykxpbgj8rm4ls2ssygnk4dp77vyijk0q";
  };

  cmsis5_ARMCM33 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/Device/ARM/ARMCM33/Include/ARMCM33.h";
    sha256 = "0v1dvnadpxn3q7j7g29554s8gx1p11y51200z3wj29plaxr15hrf";
  };

  cmsis5_startup_ARMCM33 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/Device/ARM/ARMCM33/Source/startup_ARMCM33.c";
    sha256 = "0ignjfpgv5kvqc0bxz2xfjnqbhq28vdn00rcf1kndfnhi8vw85rh";
  };

  cmsis5_system_ARMCM33_c = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/Device/ARM/ARMCM33/Source/system_ARMCM33.c";
    sha256 = "0g3lyxxc2ky6wasl7q8l556lp3kadn3y7bgzfnl8vz4h26l29f85";
  };

  cmsis5_system_ARMCM33_h = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/Device/ARM/ARMCM33/Include/system_ARMCM33.h";
    sha256 = "0f4ry3s17k97cfjvfpd702jbxg95vr4wiidp0gx1c566ghbki6ix";
  };

  cmsis5_gcc_arm_ld = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/Device/ARM/ARMCM33/Source/GCC/gcc_arm.ld";
    sha256 = "1r41jg6904wqrwwa3xry6bqj0ixrisgbc3h3n7hwm9gb8w4yn0h4";
  };

  cmsis5_mpu_armv8 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/mpu_armv8.h";
    sha256 = "0x6awm83k21192sdlhadhi1zqii3ijy2qpldvd0fqy9iw3wfjzw0";
  };

  cmsis5_pmu_armv8 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/pmu_armv8.h";
    sha256 = "186c8zj6npc3qa6k90s3856css40flwqx7jdzqqsh6zlql2w3a6f";
  };

  cmsis5_cachel1_armv7 = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_5/55b19837f5703e418ca37894d5745b1dc05e4c91/CMSIS/Core/Include/cachel1_armv7.h";
    sha256 = "1la8l693jndx1bjxslcrhj5hx6wis2n2kxqwbwh6wxg3szdk9h29";
  };

  # CMSIS_6 file
  cmsis6_gcc_m = fetchurl {
    url = "https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/m-profile/cmsis_gcc_m.h";
    sha256 = "1fzapffamainrd8q62sz2l3vj2yk94cqrqi98kw4i03rnkjiq92n";
  };

in
stdenvNoCC.mkDerivation {
  pname = "m33-an524-cmsis";
  version = "2026-01-15";

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    
    # Create directory structure matching patch expectations
    mkdir -p envs/m33-an524/src/platform/m-profile

    # Copy CMSIS_5 files to match patch paths
    cp ${cmsis5_core_cm33} envs/m33-an524/src/platform/core_cm33.h
    cp ${cmsis5_cmsis_compiler} envs/m33-an524/src/platform/cmsis_compiler.h
    cp ${cmsis5_cmsis_gcc} envs/m33-an524/src/platform/cmsis_gcc.h
    cp ${cmsis5_cmsis_version} envs/m33-an524/src/platform/cmsis_version.h
    cp ${cmsis5_ARMCM33} envs/m33-an524/src/platform/ARMCM33.h
    cp ${cmsis5_startup_ARMCM33} envs/m33-an524/src/platform/startup_ARMCM33.c
    cp ${cmsis5_system_ARMCM33_c} envs/m33-an524/src/platform/system_ARMCM33.c
    cp ${cmsis5_system_ARMCM33_h} envs/m33-an524/src/platform/system_ARMCM33.h
    cp ${cmsis5_gcc_arm_ld} envs/m33-an524/src/platform/m33-an524.ld
    cp ${cmsis5_mpu_armv8} envs/m33-an524/src/platform/m-profile/armv8m_mpu.h
    cp ${cmsis5_pmu_armv8} envs/m33-an524/src/platform/m-profile/armv8m_pmu.h
    cp ${cmsis5_cachel1_armv7} envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h

    # Copy CMSIS_6 file
    cp ${cmsis6_gcc_m} envs/m33-an524/src/platform/m-profile/cmsis_gcc_m.h

    # Make files writable
    chmod -R u+w envs/

    # Copy patches from repository
    cp -r ${../../envs/m33-an524/patches} patches
    chmod -R u+w patches

    # Apply patches
    patch -p0 < patches/cmsis5/core_cm33.h.patch || true
    patch -p0 < patches/cmsis5/cmsis_compiler.h.patch || true
    patch -p0 < patches/cmsis5/cmsis_gcc.h.patch || true
    patch -p0 < patches/cmsis5/cmsis_version.h.patch || true
    patch -p0 < patches/cmsis5/ARMCM33.patch || true
    patch -p0 < patches/cmsis5/startup_ARMCM33.patch || true
    patch -p0 < patches/cmsis5/system_ARMCM33.patch || true
    patch -p0 < patches/cmsis5/m33-an524.ld.patch || true
    patch -p0 < patches/cmsis5/m-profile-armv8m_mpu.h.patch || true
    patch -p0 < patches/cmsis5/m-profile-armv8m_pmu.h.patch || true
    patch -p0 < patches/cmsis5/m-profile-armv7m_cachel1.h.patch || true
    
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
    cp envs/m33-an524/src/platform/m-profile/armv8m_pmu.h $out/CMSIS/m-profile/
    cp envs/m33-an524/src/platform/m-profile/armv7m_cachel1.h $out/CMSIS/m-profile/
    cp envs/m33-an524/src/platform/m-profile/cmsis_gcc_m.h $out/CMSIS/m-profile/
  '';

  meta = {
    description = "Patched CMSIS files for Cortex-M33 (AN524)";
    homepage = "https://github.com/ARM-software/CMSIS_5";
  };
}
