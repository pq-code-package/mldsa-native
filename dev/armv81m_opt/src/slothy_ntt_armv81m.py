#!/usr/bin/env python3
# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""Generate the selected Cortex-M55 schedule for the pqmx forward NTT."""

import argparse
import logging
import sys

from slothy import Slothy
import slothy.targets.arm_v81m.arch_v81m as Arch_Armv81M
import slothy.targets.arm_v81m.cortex_m55r1 as Target_CortexM55r1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    slothy = Slothy(
        Arch_Armv81M,
        Target_CortexM55r1,
        logger=logging.getLogger("slothy-ntt-m55"),
    )
    slothy.load_source_from_file(args.input)

    slothy.config.inputs_are_outputs = True
    slothy.config.sw_pipelining.enabled = True
    slothy.config.timeout = 1000
    slothy.config.retry_timeout = 1000

    slothy.optimize_loop("mld_ntt_armv81m_asm_layer12_loop")
    slothy.optimize_loop("mld_ntt_armv81m_asm_layer34_loop")
    slothy.config.sw_pipelining.optimize_preamble = True
    slothy.config.sw_pipelining.optimize_postamble = False
    slothy.optimize_loop(
        "mld_ntt_armv81m_asm_layer56_loop",
        postamble_label="mld_ntt_armv81m_asm_layer56_loop_end",
    )
    slothy.config.sw_pipelining.optimize_preamble = False
    slothy.config.sw_pipelining.optimize_postamble = True
    slothy.config.constraints.st_ld_hazard = False
    slothy.optimize_loop("mld_ntt_armv81m_asm_layer78_loop")

    slothy.config.outputs = slothy.last_result.kernel_input_output + ["r14"]
    slothy.config.constraints.st_ld_hazard = True
    slothy.config.sw_pipelining.enabled = False
    slothy.optimize(
        start="mld_ntt_armv81m_asm_layer56_loop_end",
        end="mld_ntt_armv81m_asm_layer78_loop",
    )
    slothy.write_source_to_file(args.output)


if __name__ == "__main__":
    main()
