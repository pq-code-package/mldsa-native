#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#
# Conformance testing driver: empirically validates that the formal model of
# the ISA matches real hardware.
#
# Subcommands:
#   random  --runs N         random unsigned inputs in [0, 2^bw)
#   full                     exhaustive over the input space (8-bit only feasible)
#   edge                     cartesian product of edge values
#   all                      `full` for 8-bit ops; `random N + edge` for the rest
#                            (N defaults to 1,000,000)
#
# Each subcommand also accepts --mnemonic / --bitwidth filters.
#
# Both binaries support a streaming mode (--stream): one space-separated
# case per line on stdin, one hex result per line on stdout. We use that
# to avoid per-case process overhead.
#

import argparse
import itertools
import pathlib
import random
import subprocess
import sys
import time
from dataclasses import dataclass


# Standard color definitions (mirrors scripts/check-magic).
GREEN = "\033[32m"
RED = "\033[31m"
NORMAL = "\033[0m"

OK_TAG = f"{GREEN}OK{NORMAL}"


def fail_tag(n):
    return f"{RED}FAIL({n}){NORMAL}"


HERE = pathlib.Path(__file__).resolve().parent
MODEL_EXEC = (HERE / ".." / "sml" / "model_exec").resolve()
HW_EXEC = (HERE / ".." / "hw" / "hw_exec").resolve()


@dataclass(frozen=True)
class Spec:
    mnemonic: str
    bitwidth: int
    arity: int  # how many integer ARG fields after MNEMONIC BITWIDTH


SPECS = [
    Spec("MUL", 8, 2),
    Spec("MUL", 16, 2),
    Spec("MUL", 32, 2),
    Spec("MLA", 8, 3),
    Spec("MLA", 16, 3),
    Spec("MLA", 32, 3),
    Spec("MLS", 8, 3),
    Spec("MLS", 16, 3),
    Spec("MLS", 32, 3),
    Spec("SQDMULH", 16, 2),
    Spec("SQDMULH", 32, 2),
    Spec("SQRDMULH", 16, 2),
    Spec("SQRDMULH", 32, 2),
    Spec("SQRDMLAH", 16, 3),
    Spec("SQRDMLAH", 32, 3),
    Spec("SHSUB", 8, 2),
    Spec("SHSUB", 16, 2),
    Spec("SHSUB", 32, 2),
    Spec("SRSHR", 8, 2),
    Spec("SRSHR", 16, 2),
    Spec("SRSHR", 32, 2),
    Spec("MULH", 64, 2),
    Spec("UMULH", 64, 2),
]


def edge_values(bw):
    mask = (1 << bw) - 1
    pow_n_1 = 1 << (bw - 1)
    return sorted(
        {
            0,
            1,
            2,
            mask,  # all ones (-1 signed)
            mask - 1,  # -2
            pow_n_1,  # signed min
            pow_n_1 - 1,  # signed max
            pow_n_1 + 1,  # signed min + 1
            1 << (bw // 2),
            (1 << (bw // 2)) - 1,
        }
    )


def case_line(spec, args):
    return f"{spec.mnemonic} {spec.bitwidth} " + " ".join(f"0x{a:x}" for a in args)


# ----------------------------------------
# Case generators (yield tuples of args)
# ----------------------------------------


def gen_random(spec, n, rng):
    """Yield n random arg-tuples drawn uniformly over [0, 2^bw)."""
    bw = spec.bitwidth
    mask = (1 << bw) - 1
    if spec.mnemonic == "SRSHR":
        # SRSHR's first argument is the immediate shift amount, restricted to [1, bw].
        for _ in range(n):
            yield (rng.randint(1, bw), rng.randint(0, mask))
    else:
        for _ in range(n):
            yield tuple(rng.randint(0, mask) for _ in range(spec.arity))


def gen_full(spec):
    """Yield every arg-tuple in the input space (only feasible for 8-bit ops)."""
    bw = spec.bitwidth
    mask = (1 << bw) - 1
    if spec.mnemonic == "SRSHR":
        # Outer loop over the shift immediate, inner over the lane value.
        for k in range(1, bw + 1):
            for x in range(mask + 1):
                yield (k, x)
        return
    rng = range(mask + 1)
    if spec.arity == 2:
        for a in rng:
            for b in rng:
                yield (a, b)
    elif spec.arity == 3:
        for a in rng:
            for b in rng:
                for c in rng:
                    yield (a, b, c)


def gen_edge(spec):
    """Yield the cartesian product of edge values (zero, all-ones, signed extremes, ...)."""
    bw = spec.bitwidth
    edges = edge_values(bw)
    if spec.mnemonic == "SRSHR":
        # Sample three representative shifts: minimum, midpoint, maximum.
        for k in (1, max(1, bw // 2), bw):
            for x in edges:
                yield (k, x)
        return
    if spec.arity == 2:
        for a in edges:
            for b in edges:
                yield (a, b)
    elif spec.arity == 3:
        for a in edges:
            for b in edges:
                for c in edges:
                    yield (a, b, c)


# ----------------
# Streaming driver
# ----------------


def feed_and_compare(spec, cases, model_proc, hw_proc, stop_after=5, batch=4096):
    """Pipe cases into both procs, read results in lockstep, count divergences.

    Args:
        spec: Spec for the operation under test (mnemonic, bitwidth, arity);
            used to format each case line and to label diagnostics.
        cases: iterable of arg-tuples to feed into both processes.
        model_proc: subprocess.Popen running model_exec --stream.
        hw_proc: subprocess.Popen running hw_exec --stream.
        stop_after: maximum number of divergences to print verbatim before
            suppressing further per-case output (the total count is still
            returned).
        batch: number of cases written before reading responses; trades memory
            for syscall overhead.

    Returns:
        (total, fails) where total is the number of cases compared and fails
        is the number where model_exec and hw_exec produced different output.
    """
    total = 0
    fails = 0
    iterator = iter(cases)

    while True:
        block = list(itertools.islice(iterator, batch))
        if not block:
            break

        text = "".join(case_line(spec, t) + "\n" for t in block)
        model_proc.stdin.write(text)
        model_proc.stdin.flush()
        hw_proc.stdin.write(text)
        hw_proc.stdin.flush()

        for args in block:
            m_line = model_proc.stdout.readline()
            h_line = hw_proc.stdout.readline()
            if not m_line or not h_line:
                # One side closed stdout before answering: surface a clear
                # error rather than spinning. Both binaries are designed to
                # exit on any malformed input, so this points at a real bug.
                raise RuntimeError(
                    f"streaming child closed stdout while expecting a result "
                    f"for {case_line(spec, args)} "
                    f"(model_eof={not m_line}, hw_eof={not h_line})"
                )
            m = m_line.rstrip("\n")
            h = h_line.rstrip("\n")
            total += 1
            if m != h:
                fails += 1
                if fails <= stop_after:
                    print(f"DIVERGE  {case_line(spec, args)}")
                    print(f"  model_exec -> {m}")
                    print(f"  hw_exec    -> {h}")
                if fails == stop_after + 1:
                    print(
                        f"  ... suppressing further divergences for "
                        f"{spec.mnemonic} bw={spec.bitwidth}"
                    )
    return total, fails


def open_stream(binary):
    return subprocess.Popen(
        [str(binary), "--stream"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1 << 16,
    )


def shutdown(*procs):
    for p in procs:
        try:
            p.stdin.close()
        except Exception:
            pass
        p.wait(timeout=10)


# --------------------------------------------------------------------
# Top-level driver: build the case stream for each spec, run it through
# `feed_and_compare`, and aggregate counts.
# --------------------------------------------------------------------


def filter_specs(args):
    """Return the SPECS matching the user's --mnemonic / --bitwidth filters."""
    out = []
    for s in SPECS:
        if args.mnemonic and s.mnemonic != args.mnemonic:
            continue
        if args.bitwidth and s.bitwidth != args.bitwidth:
            continue
        out.append(s)
    return out


def run_mode(args, mode):
    """Run the conformance comparison for a single subcommand.

    Args:
        args: parsed argparse Namespace; must carry `model`, `hw`, `seed`,
            `mnemonic`, `bitwidth`, and the mode-specific knobs (`runs`,
            `all_runs`).
        mode: one of {"random", "full", "edge", "all"}; "all" expands to
            "full" for 8-bit ops and "random+edge" for the rest.

    Returns:
        Process exit code: 0 on perfect agreement, 1 if any divergences,
        2 if no specs matched the filters.
    """
    specs = filter_specs(args)
    if not specs:
        print("no matching specs", file=sys.stderr)
        return 2

    # `seed` is only carried by the modes that actually consume randomness;
    # default to 0 elsewhere so this function can stay mode-agnostic.
    rng = random.Random(getattr(args, "seed", 0))
    grand_total = 0
    grand_fails = 0
    t0 = time.time()

    for spec in specs:
        m_proc = open_stream(args.model)
        h_proc = open_stream(args.hw)
        try:
            cases_list = []
            label_parts = []

            effective_mode = mode
            if mode == "all":
                if spec.bitwidth == 8:
                    effective_mode = "full"
                else:
                    effective_mode = "random+edge"

            if effective_mode == "random":
                cases_list.append(gen_random(spec, args.runs, rng))
                label_parts.append(f"random={args.runs}")
            elif effective_mode == "edge":
                cases_list.append(gen_edge(spec))
                label_parts.append("edge")
            elif effective_mode == "full":
                cases_list.append(gen_full(spec))
                label_parts.append("full")
            elif effective_mode == "random+edge":
                cases_list.append(gen_edge(spec))
                cases_list.append(gen_random(spec, args.all_runs, rng))
                label_parts.append(f"edge+random={args.all_runs}")
            else:
                raise AssertionError(mode)

            spec_t = time.time()
            total, fails = feed_and_compare(
                spec, itertools.chain(*cases_list), m_proc, h_proc
            )
            dt = time.time() - spec_t
            grand_total += total
            grand_fails += fails
            tag = OK_TAG if fails == 0 else fail_tag(fails)
            print(
                f"{tag:7s}  {spec.mnemonic:9s} bw={spec.bitwidth:3d}  "
                f"cases={total:>10d}  {','.join(label_parts):20s}  {dt:6.2f}s"
            )
        finally:
            shutdown(m_proc, h_proc)

    dt = time.time() - t0
    print(f"\nTotal: {grand_total} cases, {grand_fails} divergences  ({dt:.2f}s)")
    return 0 if grand_fails == 0 else 1


def _main():
    p = argparse.ArgumentParser()
    p.add_argument("--model", default=str(MODEL_EXEC))
    p.add_argument("--hw", default=str(HW_EXEC))
    sub = p.add_subparsers(dest="cmd", required=True)

    def add_filters(sp):
        sp.add_argument("--mnemonic")
        sp.add_argument("--bitwidth", type=int)

    sp_random = sub.add_parser("random", help="random sampling")
    add_filters(sp_random)
    sp_random.add_argument("-n", "--runs", type=int, default=1000)
    sp_random.add_argument("--seed", type=int, default=0)

    sp_full = sub.add_parser(
        "full", help="exhaustive enumeration (8-bit only feasible)"
    )
    add_filters(sp_full)

    sp_edge = sub.add_parser("edge", help="edge-value cartesian product")
    add_filters(sp_edge)

    sp_all = sub.add_parser(
        "all", help="full for 8-bit, random+edge (1M each) for the rest"
    )
    add_filters(sp_all)
    sp_all.add_argument("--seed", type=int, default=0)
    sp_all.add_argument(
        "--all-runs",
        type=int,
        default=1_000_000,
        help="random samples per non-8-bit op [default: 1,000,000]",
    )

    args = p.parse_args()

    for path, name in [(args.model, "model_exec"), (args.hw, "hw_exec")]:
        if not pathlib.Path(path).exists():
            print(f"error: {name} not found at {path}", file=sys.stderr)
            return 2

    return run_mode(args, args.cmd)


if __name__ == "__main__":
    sys.exit(_main())
