[//]: # (SPDX-License-Identifier: CC-BY-4.0)

### Cross-compilation

**mldsa-native** supports cross-compilation for ARM embedded targets using the GNU Arm Embedded Toolchain.

#### Prerequisites

- **ARM Toolchain**: `arm-none-eabi-gcc` (GNU Arm Embedded Toolchain)
- **QEMU** (optional, for testing): `qemu-system-arm` with mps2-an505 support

To set up the required tools, use the nix shell configuration:

```bash
nix develop --experimental-features 'nix-command flakes' .#arm-embedded
```


#### Building for m33-an524 (Recommended)

The recommended way to build for m33-an524 is using the platform makefile:

```bash
# C backend (portable)
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# DSP backend (optimized, when available)
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=1
```

This method correctly builds all three security levels (ML-DSA-44, ML-DSA-65, ML-DSA-87) with proper symbol definitions.

#### Backend Selection

The build system automatically selects the optimal backend:

- **Cortex-M33/M35 with OPT=1**: Uses DSP-optimized backend
- **Other ARM targets with OPT=1**: Falls back to C backend (with warning)
- **Any target with OPT=0**: Uses portable C backend

#### Testing on QEMU

A complete testing platform is available for m33-an524

```bash
# Step 1: Build libraries from root directory
make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Step 2: Run tests
cd test/baremetal/platform/m33-an524
make run_func_all
make run_bench_all
```

#### Troubleshooting

**"undefined reference to PQCP_MLDSA_NATIVE_MLDSA65_keypair"**: This error occurs when libraries are built with incorrect parameter sets. Use `EXTRA_MAKEFILE` instead of overriding CFLAGS, or ensure you include `-DMLD_CONFIG_PARAMETER_SET=XX` when building individual libraries.

For detailed ARM development instructions, see `.kiro/steering/arm-development.md`.
