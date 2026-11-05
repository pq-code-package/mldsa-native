#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""
Link a test binary into the Xous baremetal image for the Dabao board.

Invoked as the linker (LD) with `-o <out> <objects> <libraries>`. The inputs
are first partially linked into one object whose initialized data is gathered
in `.mld_data`: the image format has no general .data loader, so the C side
copies that section into place itself (see dabao.c). The object is handed to
the Rust link of the baremetal crate through DABAO_LINK_OBJ, and the
signed UF2 image is written to <out>.

XOUS_CORE is the xous-core checkout to build in. It is cloned at XOUS_REV
and patched with xous-core.patch if it does not exist yet.
"""

import fcntl
import hashlib
import os
import shutil
import subprocess
import sys

UF2 = "target/riscv32imac-unknown-none-elf/release/baremetal.uf2"

XOUS_URL = "https://github.com/betrusted-io/xous-core"
XOUS_REV = "c0254413a6c2cc27872f8a4b92420311cf1653ca"
# `git describe --long` of XOUS_REV; image signing needs a version and a
# shallow clone has no tags.
XOUS_DESCRIBE = "v0.10.2-155-gc0254413"
PLATFORM_DIR = os.path.dirname(os.path.abspath(__file__))
PATCH = os.path.join(PLATFORM_DIR, "xous-core.patch")
PARTIAL_LDSCRIPT = os.path.join(PLATFORM_DIR, "partial.ld")


def parse_args(argv):
    out = None
    args = []
    it = iter(argv)
    for a in it:
        if a == "-o":
            out = next(it)
        elif a.startswith("-") and not a.startswith(("-L", "-l")):
            # compiler-driver flags have no meaning for the partial link
            continue
        else:
            args.append(a)
    if out is None:
        sys.exit("link.py: missing -o <output>")
    return out, args


def ensure_xous(xous):
    with open(PATCH, "rb") as f:
        stamp = XOUS_REV + " " + hashlib.sha256(f.read()).hexdigest()
    marker = os.path.join(xous, ".mld-stamp")
    if os.path.exists(marker):
        with open(marker) as f:
            if f.read().strip() == stamp:
                return
        sys.exit(
            f"link.py: {xous} was set up for a different revision or patch; remove it"
        )
    os.makedirs(xous, exist_ok=True)

    def git(*args):
        subprocess.run(["git", "-C", xous] + list(args), check=True)

    git("init", "-q")
    git("fetch", "-q", "--depth", "1", XOUS_URL, XOUS_REV)
    git("checkout", "-q", "FETCH_HEAD")
    git("apply", PATCH)
    with open(marker, "w") as f:
        f.write(stamp + "\n")


def main():
    out, args = parse_args(sys.argv[1:])
    xous = os.environ.get("XOUS_CORE")
    if not xous:
        sys.exit("link.py: XOUS_CORE is not set")

    partial = os.path.abspath(out + ".o")
    subprocess.run(
        [
            os.environ["DABAO_LD"],
            "-r",
            "-T",
            PARTIAL_LDSCRIPT,
            "-o",
            partial,
            "--start-group",
        ]
        + args
        + ["--end-group"],
        check=True,
        # nix's ld wrapper adds -z relro/now, which do not apply to ld -r
        env=dict(os.environ, NIX_HARDENING_ENABLE=""),
    )
    # Only the entry point is visible to the Rust side; newlib's own
    # definitions (abort, mem*, ...) must not clash with the Rust runtime.
    subprocess.run(
        [
            os.environ["DABAO_OBJCOPY"],
            "--keep-global-symbol=mld_bench_entry",
            partial,
        ],
        check=True,
    )

    env = dict(os.environ)
    env["DABAO_LINK_OBJ"] = partial
    # xtask reads CARGO_HOME, which only rustup's proxies set; this is
    # cargo's own default.
    env.setdefault("CARGO_HOME", os.path.expanduser("~/.cargo"))
    # Keep the project's host build flags out of cargo
    for v in ("CFLAGS", "CPPFLAGS", "LDFLAGS", "CC", "LD", "AR"):
        env.pop(v, None)

    cmd = [
        "cargo",
        "xtask",
        "bao1x-baremetal-dabao",
        "--loader-feature",
        "mldsa-bench",
        "--git-describe",
        XOUS_DESCRIBE,
    ]

    # All test binaries share one cargo output; build them one at a time.
    os.makedirs(os.path.dirname(xous), exist_ok=True)
    with open(xous + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        ensure_xous(xous)
        res = subprocess.run(
            cmd, cwd=xous, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        if res.returncode != 0 or b"Created UF2" not in res.stdout:
            sys.stdout.write(res.stdout.decode(errors="replace"))
            sys.exit(f"link.py: xtask failed for {out}")
        shutil.copyfile(os.path.join(xous, UF2), out)


if __name__ == "__main__":
    main()
