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

`test_keccakf1600x4_bytes()` in [test_unit.c](../src/test_unit.c) checks the
native x4 Keccak XOR and extraction helpers whenever
`MLD_USE_NATIVE_FIPS202_X4` is enabled. It was added for the Armv8.1-M MVE
helpers: their partial-lane prologue must advance buffer pointers to the next
8-byte lane, then choose byte accesses if any resulting pointer is unaligned
for MVE word gathers or scatters. Even an initially word-aligned buffer can
become unaligned after processing a partial lane.

The test exercises every state offset from 0 through 200 and every buffer
alignment modulo 4. All four buffers share the selected alignment; mixed
alignments between buffers are not covered. It uses representative lengths
around lane and larger boundaries, zero length, and the exact remaining
state length at each offset, including `(offset, length) = (200, 0)`. This
covers the partial-lane prologue, aligned word path, unaligned byte path, and
final partial lane.

For each case, it checks partial XOR against a bytewise expected result by
extracting the entire state, including bytes outside the XOR range. It then
checks partial extraction from a separately restored nonzero state, without
the preceding partial XOR. This prevents matching mistakes in the two partial
operations from cancelling. Input buffers and extraction state must remain
unchanged, and `0xA5` sentinels must survive outside the requested output range.
The existing randomized XOR/permute/extract test provides a separate comparison
with the x1 C reference, but samples only nonempty ranges within the first
136 state bytes and does not explicitly vary buffer alignment.

Run the full unit suite for all three ML-DSA parameter sets with this backend
on Cortex-M55 QEMU from the repository root:

```sh
export EXTRA_MAKEFILE=test/zephyr/platform.mk
export ZEPHYR_TARGET=mps3-an547
nix develop .#zephyr --command ./scripts/tests unit --no-auto --opt=opt
```

`--no-auto` leaves target selection to Zephyr instead of detecting the host
architecture. The Zephyr CI job runs the full unit suite on AN547 with native
and portable configurations. The larger main stack in `app/prj.conf` lets the
full ML-DSA-87 suite fit; it is needed for the suite's polynomial vectors.

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
