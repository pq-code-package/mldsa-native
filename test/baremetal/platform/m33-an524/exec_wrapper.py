#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""QEMU wrapper for executing Cortex-M33 bare-metal ELF binaries (mps3-an524)."""

import struct as st
import sys
import subprocess
import tempfile
import os


def err(msg, **kwargs):
    print(msg, file=sys.stderr, **kwargs)


binpath = sys.argv[1]
args = sys.argv[1:]

# Memory layout: [argc] [offset1] [offset2] ... [string1\0] [string2\0] ...
# AN524 DDR4: 0x70000000-0x701FFFFF (2MB)
# Place cmdline at 0x70190000 (within heap area, before stack)
cmdline_offset = 0x2000F000  
arg0_offset = cmdline_offset + 4 + len(args) * 4
arg_offsets = [sum(map(len, args[:i])) + i + arg0_offset for i in range(len(args))]

binargs = st.pack(
    f"<{1+len(args)}I" + "".join(f"{len(a)+1}s" for a in args),
    len(args),
    *arg_offsets,
    *map(lambda x: x.encode("utf-8"), args),
)

with tempfile.NamedTemporaryFile(mode="wb", delete=False, suffix=".bin") as fd:
    args_file = fd.name
    fd.write(binargs)

try:
    qemu_cmd = f"qemu-system-arm -M mps3-an524 -cpu cortex-m33 -nographic -semihosting -kernel {binpath} -device loader,file={args_file},addr=0x{cmdline_offset:x}".split()
    result = subprocess.run(qemu_cmd, capture_output=True, text=True, timeout=300)

except subprocess.TimeoutExpired:
    err("FAIL!")
    err("Test timed out after 300 seconds")
    exit(1)
finally:
    os.unlink(args_file)

# AArch32 semihosting exit code behavior:
# - Exit code 0 is reserved for specific conditions that don't apply to bare-metal programs
# - Exit code 1 indicates the VM terminated via semihosting (not an error)
# We check stderr for actual QEMU errors instead.
has_error = False
if result.returncode != 0 and result.stderr:
    stderr_lower = result.stderr.lower()
    if any(
        keyword in stderr_lower
        for keyword in ["qemu:", "error:", "fatal:", "failed to"]
    ):
        has_error = True

if has_error:
    err("FAIL!")
    err(f"{qemu_cmd} failed with error code {result.returncode}")
    err(result.stderr)
    exit(1)

for line in result.stdout.splitlines():
    print(line)

# Semihosting output goes to stderr
for line in result.stderr.splitlines():
    print(line)
