[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# FIPS202 backend for Armv8.1-M + MVE: Development sources

This directory contains the development sources for a FIPS202 backend targeting
the Armv8.1-M + MVE/Helium architecture.

The x1 Keccak-f[1600] `*_opt_m7.S` and `*_opt_m55.S` sources are generated from
`../armv81m_clean/src/keccak_f1600_x1_armv7m.S` using `src/Makefile`. The
Makefile invokes SLOTHY with the `Arm_v7M`/`Arm_Cortex_M7` or
`Arm_v81M`/`Arm_Cortex_M55r1` architecture and target models; regenerate through
`scripts/autogen --slothy keccak_f1600_x1_armv7m_opt_m7` or
`scripts/autogen --slothy keccak_f1600_x1_armv7m_opt_m55` with `slothy-cli`
available in `PATH`.

**Warning:** This backend is still in active development and has not yet undergone
the same level of review as the rest of the code. Use at your own risk!
