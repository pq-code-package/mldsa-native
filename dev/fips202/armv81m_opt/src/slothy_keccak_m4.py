#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: MIT

import argparse
import logging
import sys

from slothy import Slothy
import slothy.targets.arm_v7m.arch_v7m as Arch_Armv7M
import slothy.targets.arm_v7m.cortex_m7 as Target_CortexM7


ADOMNICAI_M4_OUTPUTS = [
    "flags",
    "hint_r0Aba1",
    "hint_r0Aka1",
    "hint_spEba0",
    "hint_spEba1",
    "hint_spEbe0",
    "hint_spEbe1",
    "hint_spEbi0",
    "hint_spEbi1",
    "hint_spEbo0",
    "hint_spEbo1",
    "hint_spEbu0",
    "hint_spEbu1",
    "hint_spEga0",
    "hint_spEga1",
    "hint_spEge0",
    "hint_spEge1",
    "hint_spEgi0",
    "hint_spEgi1",
    "hint_spEgo0",
    "hint_spEgo1",
    "hint_spEgu0",
    "hint_spEgu1",
    "hint_spEka0",
    "hint_spEka1",
    "hint_spEke0",
    "hint_spEke1",
    "hint_spEki0",
    "hint_spEki1",
    "hint_spEko0",
    "hint_spEko1",
    "hint_spEku0",
    "hint_spEku1",
    "hint_spEma0",
    "hint_spEma1",
    "hint_spEme0",
    "hint_spEme1",
    "hint_spEmi0",
    "hint_spEmi1",
    "hint_spEmo0",
    "hint_spEmo1",
    "hint_spEmu0",
    "hint_spEmu1",
    "hint_spEsa0",
    "hint_spEsa1",
    "hint_spEse0",
    "hint_spEse1",
    "hint_spEsi0",
    "hint_spEsi1",
    "hint_spEso0",
    "hint_spEso1",
    "hint_spEsu0",
    "hint_spEsu1",
    "hint_spmDa0",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    slothy = Slothy(
        Arch_Armv7M,
        Target_CortexM7,
        logger=logging.getLogger("slothy-keccak-m4"),
    )

    slothy.config.inputs_are_outputs = True
    slothy.config.variable_size = True
    slothy.config.reserved_regs = ["sp", "r13"]
    slothy.config.locked_registers = ["sp", "r13"]
    slothy.config.unsafe_address_offset_fixup = False

    slothy.config.split_heuristic = True
    slothy.config.split_heuristic_preprocess_naive_interleaving = True
    slothy.config.split_heuristic_repeat = 2
    slothy.config.split_heuristic_optimize_seam = 6
    slothy.config.split_heuristic_stepsize = 0.05

    slothy.config.outputs = ADOMNICAI_M4_OUTPUTS
    slothy.config.split_heuristic_factor = 22
    slothy.config.constraints.stalls_first_attempt = 16

    slothy.config.timeout = 1000

    slothy.load_source_from_file(args.input)
    slothy.optimize(
        start="mld_keccak_f1600_x1_armv7m_asm_slothy_start",
        end="mld_keccak_f1600_x1_armv7m_asm_slothy_end",
    )
    slothy.write_source_to_file(args.output)


if __name__ == "__main__":
    main()
