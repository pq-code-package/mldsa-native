[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# mldsa-native

mldsa-native is a secure, fast and portable C90 implementation of the ML-DSA
post-quantum signature standard (FIPS 204).

These pages are rendered from the documentation in the mldsa-native sources:

* mldsa/mldsa_native.h declares the public API and the sizes of the
  cryptographic material.
* mldsa/mldsa_native_config.h documents the build-time configuration options.
* The remaining files are internal to mldsa-native and are documented here for
  the benefit of contributors and reviewers; they are not part of the public
  API and may change at any time.

Conventions shared by all public functions, such as return values, pointer
validity and the state of output buffers on error, are described in
[API-CONVENTIONS.md](https://github.com/pq-code-package/mldsa-native/blob/main/API-CONVENTIONS.md).
For everything else, including build instructions and examples, see the
[mldsa-native repository](https://github.com/pq-code-package/mldsa-native).
