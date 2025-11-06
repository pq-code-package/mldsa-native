[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Building mldsa-native

This directory contains a minimal example showing how to build **mldsa-native** for use cases only requiring the deterministic key generation and signing APIs (`crypto_sign_keypair_internal` and `crypto_sign_signature_internal`). In that case, no implementation of `randombytes()` has to be provided.

## Components

An application using mldsa-native as-is needs to include the following components:

1. mldsa-native source tree, including [`mldsa/src/`](../../mldsa/src) and [`mldsa/src/fips202/`](../../mldsa/src/fips202).
2. The application source code

## Usage

Build this example with `make build`, run with `make run`.

## What this example demonstrates

This basic_deterministic example shows how to use the ML-DSA (Module-Lattice-Based Digital Signature Algorithm) for:

1. **Key Generation**: Generate a public/private key pair
2. **Signing**: Sign a message with a private key and optional context
3. **Signature Verification**: Verify a signature using the public key

## Parameter Sets

ML-DSA supports three parameter sets:
- **ML-DSA-44**
- **ML-DSA-65**
- **ML-DSA-87**

The example builds and runs all three parameter sets to demonstrate the different security levels and their corresponding key/signature sizes.
