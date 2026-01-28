[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Incremental Platform Validation Tests

Minimal tests to validate the Cortex-M33 MPS3-AN524 platform setup before running complex ML-DSA tests. Use these to isolate platform issues from ML-DSA complexity.

**Note:** ML-DSA uses static allocation (no heap). Stack is the key resource to validate.

## Test Hierarchy

| Test | Validates | If Fails |
|------|-----------|----------|
| `hello` | Startup, semihosting, printf, basic execution | Platform setup is broken |
| `stack_test` | Stack region accessible, measures usage | Stack configuration issue |
| ML-DSA tests | Full cryptographic operations | Likely stack size issue |

## Quick Start

```bash
# Enter Nix environment
nix develop .#arm-embedded

# Run all validation tests
make -f test/baremetal/hello/Makefile run_all

# Or run individually
make -f test/baremetal/hello/Makefile run_hello
make -f test/baremetal/hello/Makefile run_stack_test
```

## Interpreting Results

### If hello works but ML-DSA fails
→ Stack size issue. Check `stack_test` output for usage and compare with ML-DSA requirements.

### If hello fails
→ Platform setup issue. Check:
- CMSIS files are present (`$M33_AN524_CMSIS_PATH`)
- Linker script memory map is correct
- Semihosting is enabled in QEMU

### Stack Requirements (measured on Cortex-M33, portable C, -O3)

| Level | KeyGen | Sign | Verify | Peak |
|-------|--------|------|--------|------|
| ML-DSA-44 | 45 KB | 57 KB | 43 KB | 57 KB |
| ML-DSA-65 | 69 KB | 84 KB | 66 KB | 84 KB |
| ML-DSA-87 | 107 KB | 126 KB | 102 KB | 126 KB |

Current configuration: 256KB stack (50% headroom for ML-DSA-87).

## Adjusting Stack Size

If tests indicate insufficient stack, modify `envs/m33-an524/patches/cmsis5/m33-an524.ld.patch`:

```ld
/* Current: 256KB stack */
__STACK_SIZE = 0x00040000;
```

Then rebuild the Nix package:
```bash
nix build .#m33-an524-cmsis --rebuild
```

## Files

- `hello.c` - Minimal printf test, validates semihosting
- `stack_test.c` - Paints stack, measures high water mark
- `mldsa_stack_test.c` - Measures actual ML-DSA stack usage per operation
- `Makefile` - Build and run targets

## ML-DSA Stack Measurement

To measure real stack usage for each ML-DSA security level:

```bash
# Build ML-DSA libraries first
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Run stack measurements
make -f test/baremetal/hello/Makefile run_mldsa_stack_all

# Or individually
make -f test/baremetal/hello/Makefile run_mldsa_stack_44
make -f test/baremetal/hello/Makefile run_mldsa_stack_65
make -f test/baremetal/hello/Makefile run_mldsa_stack_87
```
