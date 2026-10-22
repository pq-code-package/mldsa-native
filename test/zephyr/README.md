[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Zephyr test platform

This is a test platform that builds the mldsa-native test applications as
[Zephyr](https://www.zephyrproject.org/) applications, so they can run on
QEMU-emulated Arm MPS boards and the NUCLEO-N657X0-Q hardware board. It covers
Cortex-M3/M4/M7/M33/M55 through a single platform, without the need for
per-board hardware abstraction layers.

## Usage

The platform is selected through the `EXTRA_MAKEFILE` environment variable and
driven by the usual test targets from the top-level `Makefile`. It must run
inside the `zephyr` Nix development shell, which provides the Arm toolchain,
QEMU, and the Zephyr tree (`ZEPHYR_BASE`). The board is chosen with the
`ZEPHYR_TARGET` environment variable (default `mps3-an547`):

```
export EXTRA_MAKEFILE=test/zephyr/platform.mk
export ZEPHYR_TARGET=mps3-an547
nix develop .#zephyr --command ./scripts/tests func --opt=opt
```

Currently supported targets:

| `ZEPHYR_TARGET`     | Zephyr board             | Runner         | Core       |
| ------------------- | ------------------------ | -------------- | ---------- |
| `mps2-an385`        | `mps2/an385`             | `mps2-an385`   | Cortex-M3  |
| `mps2-an386`        | `mps2/an386`             | `mps2-an386`   | Cortex-M4  |
| `mps2-an500`        | `mps2/an500`             | `mps2-an500`   | Cortex-M7  |
| `mps2-an521`        | `mps2/an521/cpu0`        | `mps2-an521`   | Cortex-M33 |
| `mps3-an547`        | `mps3/corstone300/an547` | `mps3-an547`   | Cortex-M55 |
| `nucleo-n657x0-q`   | `nucleo_n657x0_q`        | OpenOCD + GDB  | Cortex-M55 |

The Armv8.1-M MVE FIPS202 backend is an `OPT=1` feature and is built for
`mps3-an547` and `nucleo-n657x0-q`.

## Native x4 Keccak byte-access regression test

`test_keccakf1600x4_xor_permute_extract()` in
[test_unit.c](../src/test_unit.c) compares native x4 Keccak XOR, permutation,
and extraction with the x1 C reference when `MLD_USE_NATIVE_FIPS202_X4` is
enabled. The Armv8.1-M MVE byte-access helpers must advance partial-lane
pointers to the next 8-byte lane, then use byte accesses if any resulting
pointer is unaligned for word gathers or scatters. An initially aligned
buffer can become unaligned after processing a partial lane.

The randomized trials cycle through eight equal and mixed buffer-offset
tuples for inputs and outputs. Equal offsets allow the aligned word path;
mixed offsets exercise the byte path. Thirteen fixed extraction cases follow
the randomized trials, covering alignment after a partial-lane prologue,
word and byte paths with partial tails, each output individually unaligned,
prologue-only and tail-only ranges, empty ranges, and the state endpoint.
Sentinels before and after each output range detect out-of-range writes.
This follows the test structure merged in mlkem-native PR #1766.

Run the full unit suite for all three ML-DSA parameter sets with this backend
on Cortex-M55 QEMU from the repository root:

```sh
export EXTRA_MAKEFILE=test/zephyr/platform.mk
export ZEPHYR_TARGET=mps3-an547
nix develop .#zephyr --command ./scripts/tests unit --no-auto --opt=opt
```

`--no-auto` leaves target selection to Zephyr instead of detecting the host
architecture. Zephyr CI runs unit tests on every emulated target, including
native and portable configurations on AN547. The larger main stack in
`app/prj.conf` lets the full ML-DSA-87 suite fit; it is needed for the suite's
polynomial vectors.

## How it works

Test binaries are built as Zephyr applications using Zephyr's standard
CMake-based build, registered as a `CUSTOM_BUILD` hook in mldsa-native's
makefiles.

The Zephyr application lives in `app/`:

- `app/CMakeLists.txt` compiles the `mldsa_native.c` amalgamation, the test
  sources, and `shim.c`. The test's `main()` is renamed to `mld_test_main` via
  `-Dmain=mld_test_main` so the shim can own `main()`.
- `app/shim.c` fetches argv via semihosting, calls `mld_test_main`, and exits
  QEMU with the test's return code (again via semihosting).
- `app/Kconfig` force-selects the FPU/MVE features for Corstone-300, whose
  Zephyr SoC does not otherwise advertise MVE.

`platform.mk` forwards the test binary's full `CFLAGS` to the CMake build. The
application selects Zephyr's speed policy and supplements its `-O2` with the
project's normal `-O3` through `CONFIG_COMPILER_OPT`. CMake reapplies that
configured option to application sources because Zephyr's target options would
otherwise follow them. This gives ML-DSA, the test harness, support sources,
and Zephyr itself an effective final `-O3`. The resolved ordering can be
inspected in the per-binary Zephyr build directory's `compile_commands.json`.

`exec_wrapper.py` runs a built ELF under QEMU (`-nographic`, semihosting on),
forwarding the guest's exit code; it is wired in as `EXEC_WRAPPER`.
