[//]: # (SPDX-License-Identifier: CC-BY-4.0)

mldsa-native v2.0.0
===================

Release notes
-------------

v2.0.0 is the first stable release of mldsa-native, a secure, fast and portable C90 implementation of
[ML-DSA](https://csrc.nist.gov/pubs/fips/204/final) derived from the
[ML-DSA reference implementation](https://github.com/pq-crystals/dilithium).
It carries the version number v2.0.0 rather than v1.0.0 because its public API and configuration are aligned with
those of the upcoming v2 release of the sister project
[mlkem-native](https://github.com/pq-code-package/mlkem-native).

mldsa-native v2.0.0 offers:
* High maintainability and extensibility through modular frontend/backend design.
* High performance through AArch64 (Neon) and x86_64 (AVX2) assembly backends and the use of the
  [SLOTHY super-optimizer](https://github.com/slothy-optimizer/slothy).
* High assurance through memory- and type-safety proofs for the C frontend and backend (CBMC),
  functional-correctness and memory-safety proofs for both the AArch64 and x86_64 assembly
  backends (HOL Light and s2n-bignum), and extensive constant-time testing.

mldsa-native v2.0.0 is uniformly licensed Apache-2.0 OR MIT OR ISC, giving consumers the choice to use any of these
licenses.

Assurance
---------

v2.0.0 marks the completion of the two formal-verification efforts underpinning mldsa-native: the HOL Light proofs for
the AArch64 (Neon) and x86_64 (AVX2) assembly backends and the CBMC proofs for the C code are now both complete.

- **AArch64 and x86_64 assembly proved in HOL Light.** Every routine in both the AArch64 (Neon) and x86_64 (AVX2)
  backends is proved functionally correct and memory-safe at the object-code level, using
  [HOL Light](https://hol-light.github.io/) and the [s2n-bignum](https://github.com/awslabs/s2n-bignum) verification
  infrastructure. All routines except the secret-vector rejection samplers (`rej_uniform_eta{2,4}`) are additionally
  proved to have secret-independent timing (those samplers _do_ have secret-independent timing, but this property is
  not yet backed by proof).
- **CBMC proofs for the C code**, establishing memory safety, type safety and absence of various classes of undefined
  behaviour for all C code involved in running mldsa-native with its C backend.

See [SOUNDNESS.md](SOUNDNESS.md) for more detail on the scope, assumptions and residual risks of the verification
work; it shares its methodology, formal models and trusted computing base with the sister project
[mlkem-native](https://github.com/pq-code-package/mlkem-native).

Breaking changes since v1.0.0-beta2
-----------------------------------

Between the last beta release
([v1.0.0-beta2](https://github.com/pq-code-package/mldsa-native/releases/tag/v1.0.0-beta2)) and this release, a number
of breaking changes to the public API and configuration have been introduced. Consumers upgrading from
`v1.0.0-beta2` should be aware of the following:

- **`siglen` removed from the signing and verification APIs.** Signing functions no longer take a `size_t *siglen`
  out-parameter and verification functions no longer take a `size_t siglen` in-parameter; signatures are always
  `MLDSA_BYTES(MLD_CONFIG_PARAMETER_SET)` bytes and verification now takes a fixed-size signature array. Drop the
  `siglen` argument at every call site. ([#1240](https://github.com/pq-code-package/mldsa-native/pull/1240))
- **SUPERCOP-style aliases and constants removed.** The `crypto_sign_keypair` / `crypto_sign_signature` /
  `crypto_sign_verify` aliases, the `CRYPTO_SECRETKEYBYTES` / `CRYPTO_PUBLICKEYBYTES` / `CRYPTO_BYTES` size macros, and
  the `MLD_CONFIG_NO_SUPERCOP` option were removed. Use the namespaced API directly and derive sizes from
  `MLDSA_SECRETKEYBYTES` / `MLDSA_PUBLICKEYBYTES` / `MLDSA_BYTES`.
  ([#1248](https://github.com/pq-code-package/mldsa-native/pull/1248))
- **SUPERCOP signed-message API removed.** The combined signed-message functions (`crypto_sign` / `crypto_sign_open`
  and their namespaced equivalents, which produced/consumed signature-prepended messages) were removed. Applications
  needing that format should build it on top of the detached `signature` / `verify` API.
  ([#1236](https://github.com/pq-code-package/mldsa-native/pull/1236))
- **`MLD_ERR_FAIL` split into specific error codes.** Failure conditions that previously all surfaced as
  `MLD_ERR_FAIL` now have dedicated codes: `MLD_ERR_INVALID_SIGNATURE` (verification rejected the signature),
  `MLD_ERR_INVALID_KEY` (`pk_from_sk` found the secret key malformed or internally inconsistent), `MLD_ERR_PCT_FAIL`
  (the key-generation pairwise consistency test failed) and `MLD_ERR_INVALID_ARG` (unsupported pre-hash algorithm or
  context string longer than 255 bytes). The previously existing codes keep their values, but callers matching on
  `MLD_ERR_FAIL` must be updated; it is no longer externally observable.
  ([#1309](https://github.com/pq-code-package/mldsa-native/pull/1309))
- **Legacy header-time configuration removed.** The deprecated `MLD_CONFIG_API_*` macros
  (`MLD_CONFIG_API_PARAMETER_SET`, `MLD_CONFIG_API_NAMESPACE_PREFIX`, `MLD_CONFIG_API_NO_SUPERCOP`,
  `MLD_CONFIG_API_CONSTANTS_ONLY`, `MLD_CONFIG_API_QUALIFIER`) were removed in favour of configuring through the
  [config file](mldsa/mldsa_native_config.h) (`MLD_CONFIG_PARAMETER_SET`, `MLD_CONFIG_NAMESPACE_PREFIX`,
  `MLD_CONFIG_CONSTANTS_ONLY`, `MLD_CONFIG_EXTERNAL_API_QUALIFIER`). For multi-level builds, set
  `MLD_CONFIG_MULTILEVEL_BUILD` and do not bake the 44/65/87 suffix into the namespace prefix; the security level is
  now appended automatically. ([#1206](https://github.com/pq-code-package/mldsa-native/pull/1206),
  [#1270](https://github.com/pq-code-package/mldsa-native/pull/1270))
- **FIPS-202 backend flags renamed to the `MLD_USE_NATIVE_*` convention.** Custom FIPS-202 backends must rename the
  flags they define: `MLD_USE_FIPS202_X1_NATIVE` -> `MLD_USE_NATIVE_FIPS202_X1`, `MLD_USE_FIPS202_X4_NATIVE` ->
  `MLD_USE_NATIVE_FIPS202_X4`, `MLD_USE_FIPS202_X4_XOR_BYTES_NATIVE` -> `MLD_USE_NATIVE_FIPS202_X4_XOR_BYTES`, and
  `MLD_USE_FIPS202_X4_EXTRACT_BYTES_NATIVE` -> `MLD_USE_NATIVE_FIPS202_X4_EXTRACT_BYTES`. Default builds are
  unaffected. ([#1207](https://github.com/pq-code-package/mldsa-native/pull/1207))
- **Capability enum values prefixed with the architecture.** `mld_sys_cap` values were renamed
  (`MLD_SYS_CAP_AVX2` -> `MLD_SYS_CAP_X86_64_AVX2`, `MLD_SYS_CAP_SHA3` -> `MLD_SYS_CAP_AARCH64_SHA3`,
  `MLD_SYS_CAP_MVE` -> `MLD_SYS_CAP_ARMV81M_MVE`). This affects integrators with custom native backends or a custom
  capability-check function. ([#1208](https://github.com/pq-code-package/mldsa-native/pull/1208))
- **Minimum FIPS 204 signing-attempt bound raised from 814 to 821.** Builds that set
  `MLD_CONFIG_MAX_SIGNING_ATTEMPTS` explicitly must now use a value of at least 821; 814 through 820 no longer compile.
  The [FIPS 204 errata](https://csrc.nist.gov/files/pubs/fips/204/final/docs/fips-204-potential-updates.xlsx) revises
  the Repetitions row of Table 1 to 4.36 / 5.14 / 3.91 and, with it, the minimum loop-iteration limit for
  `ML-DSA.Sign_internal` in Table 3 from 814 to 821.
  ([#1349](https://github.com/pq-code-package/mldsa-native/pull/1349))

We hope these simplifications make integrations easier for the majority of consumers. Moving forward, APIs and
configuration options not marked as experimental are guaranteed to be stable until a new major version (`v3`) is
released; additional APIs and configuration options may be introduced at any time.

If the breaking changes above cause any issues for your application, please
[open a GitHub issue](https://github.com/pq-code-package/mldsa-native/issues). If your application could benefit from
additional APIs or configuration options, please open an issue as well.

What's New
----------

### Restartable and bounded signing for real-time systems

ML-DSA signing is a rejection-sampling loop: it draws a candidate signature and retries until one passes the
bounds checks. The number of attempts is not known in advance, so a single signing call has an *unbounded* worst-case
runtime.
For environments with strict timing requirements that is a problem: a signing call cannot be allowed to run for an
arbitrary number of iterations before returning control to the caller.

mldsa-native addresses this with three optional, independent **signing hooks** around the rejection-sampling loop,
enabled with `MLD_CONFIG_SIGN_HOOK_ATTEMPT`, `MLD_CONFIG_SIGN_HOOK_RESUME` and `MLD_CONFIG_SIGN_HOOK_FINISH`. The
attempt hook runs before each attempt and may **pause** the operation; signing then returns the new
`MLD_ERR_SIGNING_PAUSED` code instead of iterating further. At the start of the next call the resume hook is queried
for the attempt to restart from (the one the attempt hook recorded when it paused), so signing continues exactly where
it left off; the finish hook fires with the succeeding attempt once a signature is found. The split, resumed run
produces exactly the same signature as a single uninterrupted call.

To bound per-call runtime, the attempt hook pauses once a per-call budget is spent, and the caller re-invokes signing
in a loop until it completes.

For concurrent or interleaved signers, hold the resume state per caller by enabling `MLD_CONFIG_CONTEXT_PARAMETER`
instead of a global; each API function then forwards a context argument to the hooks. A complete example is in
[examples/restartable_sign](examples/restartable_sign).
([#1237](https://github.com/pq-code-package/mldsa-native/pull/1237))

This feature is experimental: its scope, configuration and hook signatures may change, including after v2.
We would love to hear your feedback on this feature.

### API and configuration

- **`MLD_SYS_AARCH64_FAST_SHA3`** opts non-Apple AArch64 cores with fast SHA3 instructions into the SHA3-instruction
  path. ([#1254](https://github.com/pq-code-package/mldsa-native/pull/1254))

### Platforms and testing

- **Windows MSVC** test support (KAT, Wycheproof, allocation-failure and RNG-failure tests).
  ([#1247](https://github.com/pq-code-package/mldsa-native/pull/1247))
- **AVR baremetal / 16-bit** platform support. ([#1158](https://github.com/pq-code-package/mldsa-native/pull/1158))
- **Zephyr** hardware and QEMU test platforms, including NUCLEO-N657X0-Q.
  ([#1259](https://github.com/pq-code-package/mldsa-native/pull/1259),
  [#1269](https://github.com/pq-code-package/mldsa-native/pull/1269))
- **ABI checker** for AArch64, x86_64 (SysV) and Armv8.1-M+MVE.
  ([#1195](https://github.com/pq-code-package/mldsa-native/pull/1195))

### Documentation

- **FIPS 204 references** annotated throughout the code and expanded in the documentation, mapping the implementation
  to [the standard](https://csrc.nist.gov/pubs/fips/204/final).
- **[API-CONVENTIONS.md](API-CONVENTIONS.md)** documents the conventions shared by all public functions: return
  values, pointer validity (all pointers are assumed valid and non-NULL, except a pointer paired with a length, which
  may be NULL when that length is `0`), and the state of output buffers on error (left either unchanged or fully
  zeroized, never holding partially computed data).

