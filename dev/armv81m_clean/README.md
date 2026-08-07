[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Armv8.1-M pqmx NTT/iNTT: clean inputs

This directory contains the regular, readable pqmx forward- and inverse-NTT
inputs for the Cortex-M55. The matching files under `../armv81m_opt/src/` hold
the selected SLOTHY schedules. The inverse schedule follows pqmx's selected
output with its temporary whole-buffer reduction passes omitted. See that
directory's README for provenance, generation commands, and the custom-order
contract.
