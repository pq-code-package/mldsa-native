[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Cortex-M33 MPS3-AN524 Platform

CMSIS platform files for ARM Cortex-M33 on MPS3-AN524 FPGA (SSE-200 subsystem). Runs on QEMU `qemu-system-arm -M mps3-an524` and real hardware.

**Target:** ARM Cortex-M33 r0p4 with FPU, DSP, TrustZone, caches enabled  
**Memory:** 512KB Flash @ 0x10000000, 2MB RAM @ 0x70000000 (secure DDR4)  
**Clock:** 250 MHz

## Build

```bash
# With Nix shell (includes toolchain + QEMU)
nix develop --experimental-features 'nix-command flakes' .#arm-embedded
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0
```

## Patches

Adapted from ARM CMSIS_5/6 and pqmx. Key changes:

- **ARMCM33.h**: Generic Cortex-M33 -> AN524 board config with 95 interrupts (UART, GPIO, SPI, Ethernet, I2S), enabled FPU/DSP/SAU/caches
- **m33-an524.ld**: Memory map for AN524 (Flash 0x10000000, RAM 0x70000000), 64KB stack + 512KB heap for ML-DSA-87
- **startup_ARMCM33.c**: Vector table with 95 AN524 interrupt handlers, reset handler fixes
- **system_ARMCM33.c**: Semihosting syscalls for printf() support
- **core_cm33.h**: Corrected ARMv8-M MPU include path

Per ARM DAI0524F Application Note (https://developer.arm.com/documentation/dai0524/latest).
