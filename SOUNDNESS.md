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

### Rejection sampling for the secret vector (`rej_uniform_eta{2,4}`)

Both the AArch64 and x86_64 backends are fully covered by HOL Light proofs; the full list of
functions is maintained in [proofs/hol_light/README.md](proofs/hol_light/README.md).

The one exception to the three target properties is the rejection-sampling kernels for the
secret vector, `rej_uniform_eta{2,4}`, on both backends: these are proven functionally correct
and memory-safe, but their secret-independent timing is not yet formally proved (see
[#1160](https://github.com/pq-code-package/mldsa-native/issues/1160)). Their memory access
pattern depends on which coefficients fall inside vs. outside the acceptance interval, but no
other information about the secret coefficients is leaked, and the indices of in-bound vs.
out-of-bound coefficients are statistically independent of the secret key; see Section 5.5 of
@[Round3_Spec]. This property is validated empirically through the `valgrind`-based
constant-time tests, but not formally proved.

<!--- bibliography --->
[^mlkem_native_soundness]: pq-code-package: mlkem-native SOUNDNESS document, [https://github.com/pq-code-package/mlkem-native/blob/main/SOUNDNESS.md](https://github.com/pq-code-package/mlkem-native/blob/main/SOUNDNESS.md)
[^s2n_bignum_soundness]: Amazon Web Services: s2n-bignum soundness documentation, [https://github.com/awslabs/s2n-bignum/blob/main/doc/s2n_bignum_soundness.md](https://github.com/awslabs/s2n-bignum/blob/main/doc/s2n_bignum_soundness.md)
