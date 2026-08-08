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
`../armv81m_clean/src/intt_armv81m_asm.S`; it is based on the pqmx M55 source
at SLOTHY revision
[`504d1e8d`](https://github.com/slothy-optimizer/slothy/commit/504d1e8d).
Its two temporary whole-buffer Barrett-reduction passes are omitted, as they
are not needed within the ML-DSA iNTT bounds. The iNTT consumes the same
per-16-coefficient 4-by-4-transposed NTT order produced by the native forward
kernel, and its final layer fuses the ToMont scale.

The iNTT generator uses the Arm_v81M / Arm_Cortex_M55r1 model with
input/output aliasing and software pipelining. It schedules the layer-7/8,
layer-5/6, layer-3/4, and layer-1/2 loops in that order, with 1000-second
initial and retry timeouts.

Regenerate a candidate schedule with:

```sh
scripts/autogen --slothy ntt_armv81m_asm
scripts/autogen --slothy intt_armv81m_asm
```

SLOTHY schedules can vary between solver runs. The checked-in output is the
selected valid schedule; the clean input owns its source metadata and ABI
contract.
