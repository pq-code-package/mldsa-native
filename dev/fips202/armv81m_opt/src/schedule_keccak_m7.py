#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""Schedule the scalar Keccak-f[1600] round body for Cortex-M7.

The input must mark the schedulable region with the labels below and describe
all abstract memory dependencies with ``@slothy:reads`` and
``@slothy:writes`` tags.  This driver derives the corresponding hint-register
outputs after macro expansion; it deliberately does not encode a list tied to
one particular Keccak implementation.

Configuration rationale
-----------------------
* ``inputs_are_outputs`` is required because this is a loop body: all state
  carried from one four-round iteration to the next must retain its register.
* ``reserved_regs`` locks r13 (the stack pointer) and flags.  r13 is
  non-negotiable because the body addresses its fixed stack frame.  LR/r14 is
  deliberately available for renaming: the function saves it before the
  scheduling region and returns with ``pop {..., pc}`` after it, so its entry
  value is not live across the region.
* The region is too large for a monolithic solve, so the split heuristic and
  its dependency-aware preprocessing are enabled.  Factor 18 is retained from
  the measured parameter search so that this M7-specific experiment does not
  also retune the split factor.  Use a larger factor after solver timeouts or
  memory pressure, and a smaller factor only if hardware data shows that
  window boundaries dominate.
* The M7 search uses two passes, a six-instruction seam extension, and a 0.05
  split step.  These replace the M55-derived one-pass/no-seam/automatic-step
  settings: the M7 model needs its own search-quality tuning.  Treat further
  changes as isolated experiments and compare their generated kernels on
  N657x0 hardware.
* Whole-body performance estimation is diagnostic only and is disabled by
  default: on this body it added roughly four minutes after all scheduling
  decisions were complete.  Enable ``--estimate-performance`` when a model
  estimate is specifically needed; N657x0 measurements remain authoritative.
* The M7 target's store-to-load rule is active.  The generic hazard controls
  also retain their tested settings, including stack accesses, even though the
  M7 target does not consult all of them.  They may change only in a separately
  benchmarked calibration experiment, not merely to obtain a schedule.
* ``variable_size`` lets each split solve minimize its own stalls.  An initial
  64-stall feasibility budget avoids repeated infeasible 16/32-stall solves
  for the dense theta and chi regions.  The driver defaults to a 60/30-second
  primary/retry budget for exploratory runs; the Makefile grants the full
  checked-in artifact a 900-second primary ceiling.  The checked-in unattended
  run found every accepted incumbent within 743 seconds, permitting unattended
  regeneration with evidence-based headroom.  The driver logs the fixed seed
  and output hash to identify results, while a wall-clock-limited CP-SAT solve is not
  assumed to be byte-for-byte reproducible.
* Address-offset fixup is disabled because the kernel's address registers have
  meanings beyond an isolated load/store stream.  Enabling it without a proof
  of that precondition is unsound.

All other SLOTHY options intentionally retain their model defaults: scalar
reordering and renaming are enabled, spills and software pipelining are not,
and the M7 target supplies latency and functional-unit constraints.
"""

import argparse
import ast
import hashlib
import logging
import math
import re
import sys

from slothy import Slothy
from slothy.helper import AsmHelper
import slothy.targets.arm_v7m.arch_v7m as Arch_Armv7M
import slothy.targets.arm_v7m.cortex_m7 as Target_CortexM7


KERNEL_START = "mld_keccak_f1600_x1_armv7m_asm_slothy_start"
KERNEL_END = "mld_keccak_f1600_x1_armv7m_asm_slothy_end"
IMMEDIATE_EXPRESSION = re.compile(r"#(?P<expression>[0-9][0-9*+\- ]*)")
SCALAR_WIDTH_SUFFIX = re.compile(r"\b(?P<mnemonic>eor|ldr|str)\.w\b")
SCALAR_MEMORY_INSTRUCTION = re.compile(
    r"^\s*(?P<mnemonic>"
    r"ldr(?:b|h|sb|sh|d)?|str(?:b|h|d)?|"
    r"ldm(?:ia|db)?|stm(?:ia|db)?|push|pop"
    r")(?:\.[a-z0-9]+)?\b",
    re.IGNORECASE,
)
EQU_EXPRESSION = re.compile(
    r"(?P<prefix>^\s*\.equ\s+[_a-zA-Z][_a-zA-Z0-9]*\s*,\s*)"
    r"(?P<expression>[0-9][0-9*+\- ]*)(?P<suffix>\s*(?:@.*)?$)"
)


def evaluate_immediate(expression):
    """Evaluate the numeric assembler expressions left after macro expansion."""
    node = ast.parse(expression, mode="eval").body

    def visit(current):
        if isinstance(current, ast.Constant) and isinstance(current.value, int):
            return current.value
        if isinstance(current, ast.BinOp) and isinstance(
            current.op, (ast.Add, ast.Sub, ast.Mult)
        ):
            left = visit(current.left)
            right = visit(current.right)
            if isinstance(current.op, ast.Add):
                return left + right
            if isinstance(current.op, ast.Sub):
                return left - right
            return left * right
        if isinstance(current, ast.UnaryOp) and isinstance(current.op, ast.USub):
            return -visit(current.operand)
        raise ValueError(f"unsupported assembler immediate expression: {expression!r}")

    return visit(node)


def normalize_immediates(slothy):
    """Convert ``#8*4``-style constants to the literal form M7 parsing needs."""
    _, body, _ = AsmHelper.extract(slothy.source, KERNEL_START, KERNEL_END)

    def normalize(text):
        def replacement(match):
            expression = match.group("expression")
            if not any(operator in expression for operator in "+-*"):
                return match.group(0)
            return f"#{evaluate_immediate(expression)}"

        return IMMEDIATE_EXPRESSION.sub(replacement, text)

    for line in body:
        line.transform_text(normalize)


def normalize_scalar_load_store_spelling(slothy):
    """Normalize scalar spellings consistently for the Arm SLOTHY parser."""
    _, body, _ = AsmHelper.extract(slothy.source, KERNEL_START, KERNEL_END)
    for line in body:
        line.transform_text(lambda text: SCALAR_WIDTH_SUFFIX.sub(r"\g<mnemonic>", text))


def normalize_equ_definitions(slothy):
    """Make numeric ``.equ`` aliases parseable after SLOTHY expands them."""
    for line in slothy.source:

        def replacement(match):
            expression = match.group("expression")
            if not any(operator in expression for operator in "+-*"):
                return match.group(0)
            return f"{match.group('prefix')}{evaluate_immediate(expression)}{match.group('suffix')}"

        line.transform_text(lambda text: EQU_EXPRESSION.sub(replacement, text))


def kernel_outputs(slothy):
    """Return APSR and every symbolic memory-dependency register in the body."""
    _, body, _ = AsmHelper.extract(slothy.source, KERNEL_START, KERNEL_END)
    outputs = {"flags"}

    for line in body:
        memory_tags = {"reads": 0, "writes": 0}
        for access in ("reads", "writes"):
            tags = line.tags.get(access, [])
            if isinstance(tags, str):
                tags = [tags]
            for tag in tags:
                if not isinstance(tag, str) or "\\" in tag:
                    raise ValueError(
                        "unexpanded or malformed SLOTHY memory tag "
                        f"{tag!r} in the Keccak scheduling region"
                    )
                outputs.add(f"hint_{tag}")
                memory_tags[access] += 1

        match = SCALAR_MEMORY_INSTRUCTION.match(line.text)
        if match:
            mnemonic = match.group("mnemonic").lower()
            expected_access = (
                "reads"
                if mnemonic.startswith(("ldr", "ldm")) or mnemonic == "pop"
                else "writes"
            )
            if memory_tags[expected_access] == 0:
                raise ValueError(
                    f"memory {expected_access} instruction without a SLOTHY "
                    f"{expected_access} tag in the Keccak scheduling region: "
                    f"{line.text!r}"
                )

    if len(outputs) == 1:
        raise ValueError("the Keccak scheduling region has no memory-dependency tags")
    return sorted(outputs)


def configure(slothy, args):
    """Apply the evidence-oriented M7 scheduling configuration."""
    normalize_equ_definitions(slothy)
    # Expand macros before collecting tags, so macro arguments yield the actual
    # symbolic memory locations used by this concrete Keccak implementation.
    slothy.unfold(start=KERNEL_START, end=KERNEL_END)
    normalize_immediates(slothy)
    normalize_scalar_load_store_spelling(slothy)

    slothy.config.outputs = kernel_outputs(slothy)
    slothy.config.inputs_are_outputs = True

    # The region has a fixed SP-based frame, but LR was saved before it and is
    # restored into PC afterwards.  Keep r13 fixed and let SLOTHY use r14.
    slothy.config.reserved_regs = ["flags", "r13"]
    assert "r13" in slothy.config.locked_registers
    assert "r14" not in slothy.config.locked_registers

    slothy.config.unsafe_address_offset_fixup = False
    slothy.config.variable_size = True
    slothy.config.solver_random_seed = args.seed
    slothy.config.timeout = args.timeout
    slothy.config.retry_timeout = args.retry_timeout

    slothy.config.constraints.allow_spills = False
    slothy.config.constraints.stalls_first_attempt = args.initial_stall_budget
    slothy.config.constraints.st_ld_hazard = True
    slothy.config.constraints.st_ld_hazard_ignore_stack = False
    slothy.config.constraints.st_ld_hazard_ignore_scattergather = False
    slothy.config.constraints.minimize_st_ld_hazards = False

    slothy.config.split_heuristic = True
    slothy.config.split_heuristic_factor = args.split_factor
    slothy.config.split_heuristic_repeat = args.split_repeat
    slothy.config.split_heuristic_optimize_seam = args.split_seam
    slothy.config.split_heuristic_preprocess_naive_interleaving = True
    slothy.config.split_heuristic_estimate_performance = args.estimate_performance
    if args.split_step is not None:
        slothy.config.split_heuristic_stepsize = args.split_step


def integer_at_least(minimum):
    """Return an argparse converter for an integer with a lower bound."""

    def convert(value):
        parsed = int(value)
        if parsed < minimum:
            raise argparse.ArgumentTypeError(
                f"expected an integer greater than or equal to {minimum}"
            )
        return parsed

    return convert


def number_at_least(minimum):
    """Return an argparse converter for a finite float with a lower bound."""

    def convert(value):
        parsed = float(value)
        if not math.isfinite(parsed) or parsed < minimum:
            raise argparse.ArgumentTypeError(
                f"expected a finite number greater than or equal to {minimum}"
            )
        return parsed

    return convert


def portable_seed(value):
    """Parse a non-negative seed accepted consistently by CP-SAT hosts."""
    parsed = int(value)
    if not 0 <= parsed <= 0x7FFFFFFF:
        raise argparse.ArgumentTypeError(
            "expected a seed in the inclusive range 0..2147483647"
        )
    return parsed


def parse_args():
    parser = argparse.ArgumentParser(
        description="Schedule a labelled scalar Keccak round body for Cortex-M7"
    )
    parser.add_argument("input", help="assembly source containing the labelled body")
    parser.add_argument(
        "output", nargs="?", help="path for scheduled assembly (omitted for --dry-run)"
    )
    parser.add_argument("--timeout", type=integer_at_least(1), default=60)
    parser.add_argument("--retry-timeout", type=integer_at_least(1), default=30)
    parser.add_argument("--seed", type=portable_seed, default=42)
    parser.add_argument("--initial-stall-budget", type=integer_at_least(1), default=64)
    parser.add_argument("--split-factor", type=number_at_least(2), default=18.0)
    parser.add_argument("--split-repeat", type=integer_at_least(1), default=2)
    parser.add_argument("--split-seam", type=integer_at_least(0), default=6)
    parser.add_argument("--split-step", type=float, default=0.05)
    parser.add_argument("--estimate-performance", action="store_true")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="expand the body and report derived outputs without scheduling or writing",
    )
    args = parser.parse_args()
    if not args.dry_run and args.output is None:
        parser.error("output is required unless --dry-run is used")
    if args.split_step is not None and not (0 < args.split_step <= 1):
        parser.error("--split-step must be greater than zero and no larger than one")
    return args


def main():
    args = parse_args()
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    slothy = Slothy(
        Arch_Armv7M,
        Target_CortexM7,
        logger=logging.getLogger("schedule-keccak-m7"),
    )
    slothy.load_source_from_file(args.input)
    configure(slothy, args)
    logging.info(
        "configuration: seed=%d timeout=%d retry_timeout=%d "
        "initial_stall_budget=%d split_factor=%g split_repeat=%d "
        "split_seam=%d split_step=%s estimate_performance=%s "
        "preprocess_naive_interleaving=%s unsafe_address_offset_fixup=%s "
        "inputs_are_outputs=%s variable_size=%s",
        args.seed,
        args.timeout,
        args.retry_timeout,
        args.initial_stall_budget,
        args.split_factor,
        args.split_repeat,
        args.split_seam,
        "auto" if args.split_step is None else args.split_step,
        args.estimate_performance,
        slothy.config.split_heuristic_preprocess_naive_interleaving,
        slothy.config.unsafe_address_offset_fixup,
        slothy.config.inputs_are_outputs,
        slothy.config.variable_size,
    )
    if args.split_step is not None and args.split_step > 1 / args.split_factor:
        logging.warning(
            "split_step=%g exceeds the window width %g and leaves portions "
            "of the body outside all optimization windows",
            args.split_step,
            1 / args.split_factor,
        )
    logging.info("preserved outputs: %s", ", ".join(slothy.config.outputs))

    if args.dry_run:
        return

    slothy.optimize(start=KERNEL_START, end=KERNEL_END)
    slothy.write_source_to_file(args.output)
    digest = hashlib.sha256()
    with open(args.output, "rb") as output_file:
        for chunk in iter(lambda: output_file.read(1024 * 1024), b""):
            digest.update(chunk)
    logging.info("output sha256: %s", digest.hexdigest())


if __name__ == "__main__":
    main()
