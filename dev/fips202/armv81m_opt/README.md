[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# FIPS202 backend for Armv8.1-M: Development sources

This directory contains the selected SLOTHY outputs for the Armv8.1-M x1
FIPS202 backend targeting Mainline processors, including Cortex-M55.

The x1 Keccak-f[1600] `*_opt_m55.S` permutation is generated from the clean
`../armv81m_clean/src/keccak_f1600_x1_armv81m.S` input using the
`Arm_v81M` / `Arm_Cortex_M55r1` SLOTHY target model. Its `LDRD` state loads
require the internal `uint64_t state[25]` ABI's natural eight-byte alignment.
In theta, paired theta parity loads fetch a lane's even and odd 32-bit
components together with one `LDRD`.

The MVE x1 byte XOR/extract helpers are likewise generated from clean inputs
in `../armv81m_clean/src/`. They transform two adjacent state lanes at once,
use byte-vector loads/stores so their public data buffers may be arbitrarily
aligned, and use only caller-saved `q0`--`q3` and `p0`. Their fast path covers
the first 192 state bytes; a scalar fallback handles ranges touching the final
eight-byte lane so no 16-byte access extends past the 200-byte state.

Each checked-in output is the selected schedule; it is intentionally retained
even when a later solver run chooses a different valid schedule.

The pinned SLOTHY revision is
`fed47d3f1e40b9c1f202f759f1d6c4100fe14f4d`
([slothy-optimizer/slothy#464](https://github.com/slothy-optimizer/slothy/pull/464)).
The M55 configuration uses the documented split policy and 1000-second initial
and retry timeouts. The clean input owns the generated file's metadata and
integration guards. The pinned parser does not model `VMSR`/`VPSEL`, so the
MVE helper schedules deliberately leave predicate setup outside the scheduled
region. Regenerate candidate schedules with:

```sh
scripts/autogen --slothy keccak_f1600_x1_armv7m_opt_m55 \
  keccak_f1600_x1_state_xor_bytes_mve \
  keccak_f1600_x1_state_extract_bytes_mve
```

**Warning:** This backend is still in active development and has not yet undergone
the same level of review as the rest of the code. Use at your own risk!
