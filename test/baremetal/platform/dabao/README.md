[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Dabao (Baochip-1x) test platform

This platform runs mldsa-native test and benchmark binaries on a
[Dabao](https://www.crowdsupply.com/baochip/dabao) evaluation board, whose
Baochip-1x SoC has a VexRiscv RV32IMAC core at 350 MHz. The board only needs
a USB connection to the host.

## How it works

The Baochip-1x only boots signed images, and bare-metal C code has no USB
stack of its own. Each test binary is therefore linked into the `baremetal`
image of [xous-core](https://github.com/betrusted-io/xous-core), which
provides the USB serial console:

- The C sources are compiled with a RV32IMAC/ilp32 newlib toolchain
  (`nix develop .#dabao`). `dabao.c` provides the newlib system calls.
- `link.py` is the linker. It partially links the test, then builds the Xous
  `baremetal` image around it with `cargo xtask bao1x-baremetal-dabao`. The
  output, named like the test binary, is a UF2 image signed with the xous-core
  developer key. On the first link, `link.py` clones xous-core into
  `test/build/xous-core` at a pinned revision and applies
  `xous-core.patch`.
- `exec_wrapper.py` writes the image through the `uf2` command of the boot1
  console, boots it, starts the test with the image's `mldsa` command, and
  forwards its output. The image then resets back into boot1.

`xous-core.patch` adds the `mldsa` command and the `mldsa-bench` feature to
the `baremetal` crate. It also makes these changes to xous-core:

- a 16-byte aligned initial stack, which C varargs rely on;
- a larger flash region;
- support in `xous-copy-object` for the test's initialized data;
- a watchdog that resets the board if a test hangs;
- a build that does not require the Xous `std` toolchain.

## Host setup

- Nix. The `.#dabao` shell provides both the C toolchain and a Rust
  toolchain with the `riscv32imac-unknown-none-elf` target (from
  rust-overlay). The first `nix develop .#dabao` builds the C toolchain from
  source.
- Access to the board's USB serial devices. The board enumerates as a new
  device on every boot, so grant access with a udev rule covering both the
  boot1 console and the image, for example in
  `/etc/udev/rules.d/70-dabao.rules` (numbered below 73 so that `uaccess`
  takes effect):

  ```
  SUBSYSTEM=="tty", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6196", GROUP="dialout", MODE="0660", TAG+="uaccess"
  SUBSYSTEM=="tty", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="3613", GROUP="dialout", MODE="0660", TAG+="uaccess"
  ```

  Then run `sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=tty`,
  and make sure the runner user is in the `dialout` group.
- The board must have bootwait enabled, which is how it ships and how every
  run leaves it. The wrapper starts from the boot1 console. If an interrupted
  run left an image running, the wrapper resets the image, or waits for the
  image to finish or for its watchdog to fire. Set `DABAO_SERIAL` to
  the USB serial number to pick one board if several are attached.

## Run

```sh
nix develop .#dabao
make run_bench_44 EXTRA_MAKEFILE=test/baremetal/platform/dabao/platform.mk CYCLES=PMU OPT=1
# or, as in CI:
EXTRA_MAKEFILE=test/baremetal/platform/dabao/platform.mk ./scripts/tests bench -c PMU --opt=opt
```

A full ML-DSA-44 benchmark run, including flashing, takes about 25 seconds.
