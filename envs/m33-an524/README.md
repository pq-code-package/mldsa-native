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

### Modifications to ARM-Originated Files

The following files were adapted from external sources. **Detailed patches showing exact changes are available in this directory (18 total):**

**ARM CMSIS Core Headers (from ARM-software/CMSIS_5):**
- `core_cm33.h.patch` - Core Cortex-M33 definitions (350KB - large file)
- `cmsis_compiler.h.patch` - CMSIS compiler abstraction (17KB)
- `cmsis_gcc.h.patch` - GCC-specific CMSIS definitions (77KB - large file)
- `cmsis_version.h.patch` - CMSIS version information (2.5KB)

**ARM CMSIS Device Files (from ARM-software/CMSIS_5):**
- `startup_ARMCM33.patch` - Changes to startup code and vector table (16KB)
- `system_ARMCM33.patch` - Clock configuration changes (5.5KB)
- `system_ARMCM33.h.patch` - Header file changes (2.1KB)
- `ARMCM33.patch` - Device peripheral definitions changes (18KB)
- `m33-an524.ld.patch` - Linker script changes (9.6KB)

**ARM v8-M Profile Headers (from ARM-software/CMSIS_5 and CMSIS_6):**
- `m-profile-armv8m_mpu.h.patch` - MPU support adaptations (24KB) - CMSIS_5
- `m-profile-armv8m_pmu.h.patch` - PMU support adaptations (39KB) - CMSIS_5
- `m-profile-armv7m_cachel1.h.patch` - Cache management adaptations (24KB) - CMSIS_5
- `m-profile-cmsis_gcc_m.h.patch` - M-profile GCC definitions (28KB) - CMSIS_6

**pqmx Files (from slothy-optimizer/pqmx):**
- `uart.c.patch` - UART driver adaptations for AN524 (4.3KB)
- `uart.h.patch` - UART header adaptations for AN524 (1.7KB)
- `cmdline.c.patch` - Command line processing adaptations for AN524 (2.2KB)
- `libfns.c.patch` - Library functions adaptations for AN524 (1.9KB)
- `semihosting.c.patch` - Semihosting implementation adaptations for AN524 (6.0KB)

**Modified ARM CMSIS Files:**

1. **startup_ARMCM33.c** - Vector table and interrupt handlers:
   - Updated header comment to specify "MPS3 AN524"
   - Changed vector table from generic `Interrupt0-9_Handler` to MPS3 AN524-specific handlers:
     - UART0-2 RX/TX handlers
     - GPIO0-3 handlers
     - Timer, MPC, PPC, MSC handlers
   - Modified Reset_Handler to use naked function with proper stack setup
   - Added Reset_Handler_C for proper C initialization
   - Original ARM vector table structure preserved
   - **See `startup_ARMCM33.patch` for complete diff**

2. **system_ARMCM33.c** - Clock configuration:
   - Changed `XTAL` from **25 MHz to 250 MHz** (matches STM32H5 series)
   - Updated `SYSTEM_CLOCK` to 250 MHz
   - Updated header comment to specify "MPS3 AN524"
   - Core system initialization logic unchanged
   - **See `system_ARMCM33.patch` for complete diff**

3. **system_ARMCM33.h** - Header update:
   - Updated header comment to specify "MPS3 AN524"
   - Function declarations unchanged
   - **See `system_ARMCM33.h.patch` for complete diff**

4. **ARMCM33.h** - Device peripheral definitions:
   - Updated header comment to specify "MPS3 AN524"
   - Added MPS3 AN524-specific interrupt numbers (UART0-2, GPIO, Timers, etc.)
   - Added MPS3 AN524 memory map definitions:
     - Code SRAM: 0x00000000
     - SRAM: 0x20000000
     - DDR4 (NS): 0x60000000
     - DDR4 (S): 0x70000000
     - UART0: 0x40004000 (QEMU SSE-200 memory map)
     - UART1: 0x40005000
     - Timer, GPIO, and other peripheral addresses
   - Added MPS3_UART_TypeDef structure for UART registers
   - Core Cortex-M33 definitions unchanged
   - **See `ARMCM33.patch` for complete diff**

5. **m33-an524.ld** - Linker script:
   - Based on ARM CMSIS GCC linker template (gcc_arm.ld)
   - Customized memory regions for MPS3 AN524:
     - Flash: 0x10000000 (Secure BRAM, 512KB)
     - RAM: 0x70000000 (Secure DDR4, 2MB)
   - Increased stack to 64KB (for ML-DSA-87)
   - Increased heap to 512KB (for cryptographic operations)
   - Added detailed memory map documentation from ARM DAI 0524F
   - **See `m33-an524.ld.patch` for complete diff**

**Modified pqmx Files:**

6. **uart.c** - UART driver:
   - Adapted from pqmx M55-AN547 implementation
   - Changed UART base address from 0x49303000 (AN547) to 0x40004000 (AN524)
   - Updated to use MPS3_UART_TypeDef from ARMCM33.h
   - Updated header comment to specify "MPS3 AN524"
   - **See `uart.c.patch` for complete diff**

7. **uart.h** - UART header:
   - Adapted from pqmx M55-AN547 implementation
   - Updated header comment to specify "MPS3 AN524"
   - Function declarations unchanged
   - **See `uart.h.patch` for complete diff**

8. **cmdline.c** - Command line processing:
   - Adapted from pqmx M55-AN547 implementation
   - Changed memory region from AN547 to AN524 DDR4 (0x70000000)
   - Updated header comment to specify "MPS3 AN524"
   - **See `cmdline.c.patch` for complete diff**

9. **libfns.c** - Library functions:
   - Adapted from pqmx M55-AN547 implementation
   - Updated header comment to specify "MPS3 AN524"
   - Enhanced syscall wrappers unchanged
   - **See `libfns.c.patch` for complete diff**

10. **semihosting.c** - Semihosting implementation:
    - Adapted from pqmx M55-AN547 implementation
    - Aligned with M55-AN547 for main build compatibility
    - Updated header comment to specify "MPS3 AN524"
    - **See `semihosting.c.patch` for complete diff**

**Note on CMSIS Sources:**

The platform intentionally uses files from both ARM CMSIS_5 and CMSIS_6:
- **CMSIS_5** (12 files): Core headers, device templates, and most m-profile headers
- **CMSIS_6** (1 file): `m-profile/cmsis_gcc_m.h` (provides enhanced M-profile GCC definitions)

This mix is **intentional and working correctly**. CMSIS_6 is backward compatible with CMSIS_5, and using the newer M-profile header provides better support without requiring a full CMSIS_6 migration.

**Future CMSIS_6 Migration:** If a full migration to CMSIS_6 is desired, all 18 .patch files document the exact changes made to CMSIS_5 files. These changes (250 MHz clock, AN524 memory map, vector table, etc.) would need to be carefully reapplied to CMSIS_6 files and thoroughly tested to ensure no regressions.

All modifications maintain original licenses (Apache-2.0) and include clear attribution.

**Note**: All 18 files show differences from their originals. These differences are due to platform-specific adaptations for MPS3-AN524 (memory map, clock configuration, peripherals) and integration changes for mldsa-native. See the respective .patch files for complete details.
