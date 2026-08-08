[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Armv8.1-M pqmx NTT/iNTT: clean inputs

This directory contains the regular, readable pqmx forward- and inverse-NTT
inputs for the Cortex-M55. The matching files under `../armv81m_opt/src/` hold
the selected SLOTHY schedules. The inverse kernel accepts the same custom
4-by-4-transposed NTT order produced by the native forward kernel and returns
the normal-order output required by `poly_invntt_tomont`, with its final
ToMont scale fused. See that
directory's README for provenance and generation commands.
