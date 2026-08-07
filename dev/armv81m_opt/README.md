[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Armv8.1-M pqmx NTT/iNTT: development sources

This directory retains the selected SLOTHY outputs for the Cortex-M55 ML-DSA
forward and inverse NTTs. The forward NTT's clean input is
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

The inverse NTT's clean input is
`../armv81m_clean/src/intt_armv81m_asm.S`; its selected output is based on
the unscaled pqmx M55 schedule at SLOTHY revision
[`504d1e8d`](https://github.com/slothy-optimizer/slothy/commit/504d1e8d).
The two temporary whole-buffer Barrett-reduction passes in that imported
artifact are omitted: they are not part of the clean input or the loop
schedule and are unnecessary within the ML-DSA iNTT bounds. The kernel
intentionally leaves the final ML-DSA ToMont scale to the existing scalar
`41978` post-scale in the backend wrapper.

The kernels use a 4-by-4-transposed arrangement in every 16-coefficient
block. With both kernels selected, the backend retains that custom NTT-domain
order: the forward NTT produces it, the matrix-expansion helper converts C
bit-reversed data to it, and the inverse NTT consumes it before returning
normal coefficient order.

Regenerate a candidate schedule with the Arm_v81M / Arm_Cortex_M55r1 model,
the recorded loop-by-loop configuration, and 1000-second initial/retry
timeouts:

```sh
scripts/autogen --slothy ntt_armv81m_asm
scripts/autogen --slothy intt_armv81m_asm
```

SLOTHY schedules can vary between solver runs. The checked-in output is the
selected valid schedule; the clean input owns its source metadata and ABI
contract.
