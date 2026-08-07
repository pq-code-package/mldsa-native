[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Armv8.1-M pqmx forward NTT: development sources

This directory retains the selected SLOTHY output for the Cortex-M55
forward ML-DSA NTT. Its clean input is
`../armv81m_clean/src/ntt_armv81m_asm.S`; both representations carry the
original pqmx MIT notice and are derived from pqmx commit
[`1eeaf854`](https://github.com/pq-code-package/pqmx/commit/1eeaf854e60d4ac30a2866d2a05f5935199ad6a6)
and its recorded SLOTHY submodule commit
[`ed3b034b`](https://github.com/slothy-optimizer/slothy/commit/ed3b034b3a3fbf06530784dd01a7622d4f6cf0fb).
That revision records the provenance of the imported artifact. Candidate
regeneration uses mldsa-native's currently pinned SLOTHY revision
[`fed47d3f`](https://github.com/slothy-optimizer/slothy/commit/fed47d3f1e40b9c1f202f759f1d6c4100fe14f4d),
which carries the temporary Cortex-M55 shifted-source latency-model update
from [slothy#464](https://github.com/slothy-optimizer/slothy/pull/464).

The kernel emits a 4-by-4-transposed arrangement in every 16-coefficient
block. The Armv8.1-M backend applies that self-inverse transpose after the
kernel, restoring mldsa-native's standard bit-reversed NTT order while the C
inverse NTT remains selected.

Regenerate a candidate schedule with the Arm_v81M / Arm_Cortex_M55r1 model,
the recorded loop-by-loop configuration, and 1000-second initial/retry
timeouts:

```sh
scripts/autogen --slothy ntt_armv81m_asm
```

SLOTHY schedules can vary between solver runs. The checked-in output is the
selected valid schedule; the clean input owns its source metadata and ABI
contract.
