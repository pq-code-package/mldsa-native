[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# FIPS202 backend for Armv8.1-M + MVE: Development sources

This directory contains the development sources for a FIPS202 backend targeting
the Armv8.1-M + MVE/Helium architecture.

The x1 Keccak-f[1600] `*_opt_m55.S` source is generated from
`../armv81m_clean/src/keccak_f1600_x1_armv7m.S` using the `Arm_v81M` /
`Arm_Cortex_M55r1` SLOTHY target model. The pinned SLOTHY revision is
`fed47d3f1e40b9c1f202f759f1d6c4100fe14f4d`
([slothy-optimizer/slothy#464](https://github.com/slothy-optimizer/slothy/pull/464)).
The clean input owns the generated file's metadata and integration guards, so
SLOTHY can reproduce them directly. Regenerate it with:

```sh
scripts/autogen --slothy keccak_f1600_x1_armv7m_opt_m55
```

**Warning:** This backend is still in active development and has not yet undergone
the same level of review as the rest of the code. Use at your own risk!
