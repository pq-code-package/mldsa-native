[//]: # (SPDX-License-Identifier: CC-BY-4.0)

mldsa-native v2.1.0
===================

Release notes
-------------

mldsa-native v2.1.0 adds further backends, reduces RAM usage, and
strengthens the trust anchor for its verification artifacts.

See the [full change log](https://github.com/pq-code-package/mldsa-native/compare/v2.0.0...42e60d0f4d912306b436f5258c6cdc5aeed1b29e)
and the [v2.0.0 release notes](https://github.com/pq-code-package/mldsa-native/blob/v2.0.0/RELEASE.md).

Backends
--------

- **32-bit RISC-V.** A new ML-DSA arithmetic backend supports RV32IM.
  Constant-time operation requires data-independent multiplication latency.
  See the [RV32IM backend guide](dev/riscv32/README.md).
  ([#1119](https://github.com/pq-code-package/mldsa-native/pull/1119),
  [#1426](https://github.com/pq-code-package/mldsa-native/pull/1426))
- **x86_64.** A new FIPS 202 backend accelerates Keccak on AVX-512 targets.
  If a custom runtime check rejects AVX-512, the AVX-512 routines fall back
  to C. If you require a portable build applying AVX-512, AVX2 or C backend
  as applicable to the host, you currently need to write custom dispatch logic.
  In CI benchmarks of optimized ML-DSA-87 builds on EC2 c7a, c7i, c8a,
  and c8i, AVX-512 reduced cycle counts by 22–29% for key generation,
  15–19% for signing, and 18–27% for verification. The gains vary by CPU.
  ([#1584](https://github.com/pq-code-package/mldsa-native/pull/1584))
- **AArch64.** The Neon backend has faster rejection sampling. Across
  optimized ML-DSA-87 benchmarks on Graviton2 through Graviton5, the sampler
  update cut cycle counts by 3.0–4.5% for key generation, 1.1–1.5% for
  signing, and 2.2–3.3% for verification.
  ([#1582](https://github.com/pq-code-package/mldsa-native/pull/1582))

See the [CI benchmarks](https://pq-code-package.github.io/mldsa-native/dev/bench/)
for the full results.

RAM usage
---------

Key generation, public-key recovery, and signing use less RAM. The table
compares large allocations in low-memory builds (`MLD_CONFIG_REDUCE_RAM`)
between v2.0.0 and v2.1.0, in decimal kilobytes. liboqs now uses this mode
with `OQS_MEMOPT_BUILD`.
([#1410](https://github.com/pq-code-package/mldsa-native/pull/1410),
[#1345](https://github.com/pq-code-package/mldsa-native/pull/1345),
[#1529](https://github.com/pq-code-package/mldsa-native/pull/1529))

| Parameter set | Key generation without PCT | Public-key recovery | Signing |
| --- | ---: | ---: | ---: |
| ML-DSA-44 | 11.6 → 7.5 kB | 13.2 → 10.1 kB | 13.1 → 9.8 kB |
| ML-DSA-65 | 14.7 → 8.5 kB | 17.1 → 11.9 kB | 17.2 → 11.9 kB |
| ML-DSA-87 | 18.8 → 10.6 kB | 22.0 → 14.8 kB | 21.3 → 14.2 kB |

Total stack usage also includes other local allocations. See
[mldsa_native.h](mldsa/mldsa_native.h).

Trust
-----

With new proofs being primarily written by AI, the soundness of verification
is of increasing importance.

v2.1 introduces proof capture and replay using [HOLTrace](https://holtrace.cr.yp.to/)
to remove the need to review and trust HOL Light proof scripts. In particular, this
detects proof scripts that cheat by adding new axioms, bypassing the kernel, or using
non-standard definitions.

See [hol_trace/README.md](proofs/hol_light/hol_trace/README.md)
and [SOUNDNESS.md](SOUNDNESS.md) for details.
([#1551](https://github.com/pq-code-package/mldsa-native/pull/1551))

CBMC now checks 211 of 218 64-bit proof harnesses with at least two distinct
solvers. This reduces reliance on any single solver. See
[SOUNDNESS.md](SOUNDNESS.md#cbmc-proofs-discharged-by-a-single-solver)
for the risks of single-solver proofs.
([#1423](https://github.com/pq-code-package/mldsa-native/pull/1423),
[issue #1527](https://github.com/pq-code-package/mldsa-native/issues/1527))

Bug fixes
---------

- **AArch64 alignment.** Fixed alignment faults in the rejection samplers on
  targets that require aligned accesses.
  ([#1582](https://github.com/pq-code-package/mldsa-native/pull/1582))
