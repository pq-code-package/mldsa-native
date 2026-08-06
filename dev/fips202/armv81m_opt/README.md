[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# FIPS202 backend for Armv8.1-M: Development sources

This directory contains the development sources for a scalar FIPS202 backend
targeting Armv8.1-M Mainline processors, including Cortex-M55.

The x1 Keccak-f[1600] `*_opt_m55.S` source is generated from the clean
`../armv81m_clean/src/keccak_f1600_x1_armv81m.S` input using the
`Arm_v81M` / `Arm_Cortex_M55r1` SLOTHY target model. Its `LDRD` state loads
require the internal `uint64_t state[25]` ABI's natural eight-byte alignment.
In theta, paired theta parity loads fetch a lane's even and odd 32-bit
components together with one `LDRD`. The checked-in output is the selected
schedule; it is intentionally retained even when a later solver run chooses a
different valid schedule.

The pinned SLOTHY revision is
`fed47d3f1e40b9c1f202f759f1d6c4100fe14f4d`
([slothy-optimizer/slothy#464](https://github.com/slothy-optimizer/slothy/pull/464)).
The M55 configuration uses the documented split policy and 1000-second initial
and retry timeouts. The clean input owns the generated file's metadata and
integration guards. Regenerate a candidate schedule with:

```sh
scripts/autogen --slothy keccak_f1600_x1_armv7m_opt_m55
```

**Warning:** This backend is still in active development and has not yet undergone
the same level of review as the rest of the code. Use at your own risk!
