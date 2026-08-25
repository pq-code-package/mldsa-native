[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Formal Verification in mldsa-native: Scope, Assumptions, Risks

This document describes the scope, assumptions and risks of the formal verification
efforts around mldsa-native.

We see this as a living document. If you have suggestions for improvements, such as soundness risks
missing from or insufficiently covered in this document, please reach out to us or open an issue.
However, if you find a potential security vulnerability in mldsa-native, do **not** open
a public GitHub issue, but instead use [private vulnerability reporting](https://github.com/pq-code-package/mldsa-native/security).

## Shared analysis with mlkem-native

mldsa-native uses the same verification methodology as its sister project mlkem-native:
[CBMC](https://github.com/diffblue/cbmc) for the C code (memory safety, type safety, and absence
of undefined behavior), and [HOL Light](https://hol-light.github.io/) together with the
[s2n-bignum](https://github.com/awslabs/s2n-bignum/) verification infrastructure for the
AArch64 and x86_64 assembly backends (functional correctness, memory safety, and
secret-independent execution).

The detailed analysis of the methods, formal models, trusted computing base, gaps and risks
of these verification stacks is given in mlkem-native's SOUNDNESS document[^mlkem_native_soundness]
and the underlying s2n-bignum soundness document[^s2n_bignum_soundness]. Except for the
FIPS 203 vs. FIPS 204 specifications and the differing modular arithmetic constants, the
analysis applies to mldsa-native unchanged: the same proof tools, the same ISA models, the
same TCB, and therefore the same shared mitigations and residual risks.

## Additional risks specific to mldsa-native

### Rejection sampling

Both the AArch64 and x86_64 backends are fully covered by HOL Light proofs of functional correctness
and memory safety; the full list of functions is maintained in
[proofs/hol_light/README.md](proofs/hol_light/README.md). The two rejection samplers are handled
specially with respect to secret-independent timing, for two different reasons.

The matrix sampler `rej_uniform` expands the public matrix A from the public seed rho. Since it
operates on public data only, secret-independent timing is not a requirement, and admitting
variable-time execution enables a faster implementation. It is proven functionally correct and
memory-safe on both backends, and is deliberately not proven constant-time.

The secret-vector samplers `rej_uniform_eta{2,4}` do operate on secret data, so their timing must not
depend on the secret coefficient values. Their memory-access pattern and trip count do depend on which
candidate coefficients fall inside vs. outside the acceptance interval, but that reject pattern is
public: it is a statistically-independent function of the public XOF stream (Section 5.5 of the
Dilithium Round 3 specification[^Round3_Spec]) and reveals nothing about the accepted values. On
both AArch64 and x86_64 this is now formally proved -- the microarchitectural event trace is proven to
be a function of the public pointers and the per-nibble accept/reject bitmap only ("constant-time up to
the reject pattern").

<!--- bibliography --->
[^Round3_Spec]: Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé: CRYSTALS-Dilithium Algorithm Specifications and Supporting Documentation (Version 3.1), [https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf)
[^mlkem_native_soundness]: pq-code-package: mlkem-native SOUNDNESS document, [https://github.com/pq-code-package/mlkem-native/blob/main/SOUNDNESS.md](https://github.com/pq-code-package/mlkem-native/blob/main/SOUNDNESS.md)
[^s2n_bignum_soundness]: Amazon Web Services: s2n-bignum soundness documentation, [https://github.com/awslabs/s2n-bignum/blob/main/SOUNDNESS.md](https://github.com/awslabs/s2n-bignum/blob/main/SOUNDNESS.md)
