
[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Cortex-M33 MPS3-AN524 Platform

CMSIS platform files for ARM Cortex-M33 on MPS3-AN524 FPGA (SSE-200 subsystem). Runs on QEMU `qemu-system-arm -M mps3-an524` and real hardware.

**Target:** ARM Cortex-M33 r0p4 with FPU, DSP, TrustZone, caches enabled  
**Memory:** 512KB Flash @ 0x10000000, 128KB SRAM @ 0x20000000  

## Build

```bash
# Nix shell (provides toolchain and QEMU)
nix develop --experimental-features 'nix-command flakes' .#arm-embedded

# Build library
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Run functional tests
make run_func_44 EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Run benchmarks
make run_bench_44 EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0 CYCLES=PMU
```

## Patches

Adapted from ARM CMSIS_5 and pqmx. Key changes:

- **ARMCM33.h**: Generic Cortex-M33 -> AN524 board config with 95 interrupts (UART, GPIO, SPI, Ethernet, I2S), enabled FPU/DSP/SAU/caches
- **m33-an524.ld**: Memory map for AN524 (Flash 0x10000000, SRAM 0x20000000), 96KB stack, single PHDRS load segment, `.ARM.exidx` inside `.text` to prevent auto-generated ARM_EXIDX segment
- **startup_ARMCM33.c**: Vector table with 95 AN524 interrupt handlers
- **system_ARMCM33.c**: UART initialization at 32 MHz, `uart_putc()` for stdio output
- **uart.c**: UART driver at 0x41303000 with 32 MHz clock
- **core_cm33.h**: Corrected ARMv8-M MPU include path

Per ARM DAI0524F Application Note.
