#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: MIT

"""Schedule the Armv8.1-M MVE x1 Keccak byte-helper hot loops.

The selected schedule is deliberately restricted to q0-q3: q4-q7 alias the
AAPCS32 callee-saved d8-d15 registers, while these public helpers have no MVE
save/restore wrapper. The clean source owns the metadata and non-loop safety
logic; only the marked hot loop is given to SLOTHY.
"""

import argparse
import logging
import os
import tempfile

from slothy import Slothy
import slothy.targets.arm_v81m.arch_v81m as Arch_Armv81M
import slothy.targets.arm_v81m.cortex_m55r1 as Target_CortexM55r1


def configure(slothy, helper, functional_only):
    """Apply the fixed scheduling policy shared by both helper variants."""

    slothy.config.inputs_are_outputs = True
    # The scheduled XOR conversion feeds the fixed predicate/select sequence
    # immediately after it. Declare those values and the byte pointer as live.
    # The extract schedule includes its final byte store, so only its pointer
    # must remain live across loop iterations.
    slothy.config.outputs = ["q0", "q2", "r1"] if helper == "xor" else ["r1"]
    slothy.config.variable_size = not functional_only
    # `reserved_regs` replaces the target default, so retain flags, r13/r14.
    # q4-q7 are d8-d15 and must not be introduced by register renaming.
    slothy.config.reserved_regs = [
        "flags",
        "r13",
        "r14",
        "q4",
        "q5",
        "q6",
        "q7",
    ]
    slothy.config.locked_registers = slothy.config.reserved_regs
    slothy.config.unsafe_address_offset_fixup = False
    slothy.config.constraints.functional_only = functional_only
    slothy.config.constraints.allow_reordering = True
    slothy.config.constraints.max_displacement = 0.1 if functional_only else 1.0
    slothy.config.constraints.stalls_first_attempt = 64
    slothy.config.constraints.stalls_maximum_attempt = 4096
    slothy.config.timeout = 1000
    slothy.config.retry_timeout = 1000

    if not functional_only:
        slothy.config.split_heuristic = True
        slothy.config.split_heuristic_stepsize = 0.05
        slothy.config.split_heuristic_factor = 26
        slothy.config.split_heuristic_repeat = 2
        slothy.config.split_heuristic_estimate_performance = False
        slothy.config.split_heuristic_optimize_seam = 2


def optimize(input_file, output_file, start, end, helper, functional_only):
    slothy = Slothy(
        Arch_Armv81M,
        Target_CortexM55r1,
        logger=logging.getLogger("slothy-keccak-x1-helpers-mve"),
    )
    configure(slothy, helper, functional_only)
    slothy.load_source_from_file(input_file)
    slothy.optimize(start=start, end=end)
    slothy.write_source_to_file(output_file)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("helper", choices=("xor", "extract"))
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    stem = "mld_keccak_f1600_x1_state_{}_bytes_mve".format(args.helper)
    start = stem + "_slothy_start"
    end = stem + "_slothy_end"

    with tempfile.NamedTemporaryFile(suffix=".S", delete=False) as tmp:
        tmp_name = tmp.name
    try:
        optimize(args.input, tmp_name, start, end, args.helper, functional_only=True)
        optimize(tmp_name, args.output, start, end, args.helper, functional_only=False)
    finally:
        os.unlink(tmp_name)


if __name__ == "__main__":
    main()
