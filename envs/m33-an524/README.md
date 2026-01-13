[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Cortex-M33 MPS3-AN524 Platform Environment

This directory contains the complete CMSIS-compliant platform environment for Cortex-M33 on MPS3-AN524, providing 100% feature parity with the M55-AN547 reference implementation.

## Directory Structure

```
envs/m33-an524/
├── src/platform/           # Platform source files
│   ├── ARMCM33.h          # Device header with AN524 peripherals
│   ├── core_cm33.h        # ARM Cortex-M33 core definitions
│   ├── cmsis_*.h          # CMSIS compiler abstraction
│   ├── system_ARMCM33.*   # System initialization
│   ├── startup_ARMCM33.c  # Startup code and vector table
│   ├── m33-an524.ld       # Linker script (MPS3-AN524 memory map)
│   ├── semihosting.c      # ARM semihosting implementation
│   ├── uart.*             # UART hardware driver
│   ├── cmdline.c          # Command line argument support
│   ├── libfns.c           # Enhanced syscall wrappers
│   └── m-profile/         # ARM v8-M feature headers
│       ├── armv8m_mpu.h   # Memory Protection Unit
│       ├── armv8m_pmu.h   # Performance Monitoring Unit
│       └── armv7m_cachel1.h # L1 Cache management
├── config/
│   └── mps3-an524.mk      # Platform-specific build configuration
└── README.md              # This file
```

## Platform Features

### Hardware Support
- **Target**: ARM Cortex-M33 on MPS3-AN524 FPGA board
- **QEMU**: Full support for `qemu-system-arm -M mps3-an524`
- **Memory Map**: 
  - Flash: 0x10000000 (Secure BRAM, 512KB)
  - RAM: 0x70000000 (Secure DDR4, 2MB)
- **Clock**: 250 MHz (matches STM32H5 series)

### CMSIS Compliance
- **Core CMSIS**: Complete ARM CMSIS v5 headers
- **Device Templates**: CMSIS-compliant startup and system files
- **Hardware Abstraction**: UART driver and semihosting support
- **System Integration**: Command line and enhanced syscalls
- **ARM v8-M Features**: MPU, PMU, and L1 cache support

### I/O Support
- **Semihosting**: ARM-standard semihosting for debug I/O
- **UART**: Hardware UART driver for real hardware deployment
- **Printf**: Full 64-bit integer support with soft-float ABI

## Usage

This environment is designed to be used via the project-specific platform configuration:

```bash
# Build with main build system
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Run functional tests
make run_func_44 EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0
```

## Technical Decisions

1. **Soft-float ABI**: Uses `mfloat-abi=soft` to avoid double-precision FPU issues
2. **Full printf**: Uses `nosys.specs` (not `nano.specs`) for 64-bit integer support
3. **No custom HAL**: Uses default `test/hal/hal.c` like M55-AN547 (returns 0 for cycles)
4. **CMSIS compliance**: 100% feature parity with M55-AN547 reference

## Future Work

This environment is structured to facilitate:
- **pqmx integration**: Easy extraction to separate repository like M55-AN547
- **Multi-project reuse**: Clean separation from project-specific files
- **Nix packaging**: Direct packaging of `envs/m33-an524/` directory

## Attribution

Platform files are adapted from:
- **ARM CMSIS_5**: Official ARM CMSIS headers and device templates
- **pqmx repository**: Base implementations for UART, cmdline, and libfns
- **mldsa-native**: Project-specific adaptations and integration

All files retain original license headers with clear attribution.
