[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Bring your own FIPS-202 (Static State Variant)

This directory contains a minimal example for how to use mldsa-native with external FIPS-202
HW/SW-implementations that use a single global state (for example, some hardware accelerators).
Specifically, this example demonstrates the use of the serial-only FIPS-202 configuration
`MLD_CONFIG_SERIAL_FIPS202_ONLY`.

**WARNING:** This example is EXPECTED TO PRODUCE INCORRECT RESULTS because ML-DSA requires
multiple independent FIPS-202 contexts to be active simultaneously. This example demonstrates
what happens when only a single global state is available.

## Components

An application using mldsa-native with a custom FIPS-202 implementation needs the following:

1. Arithmetic part of the mldsa-native source tree: [`mldsa/src/`](../../mldsa/src)
2. A secure pseudo random number generator, implementing [`randombytes.h`](../../mldsa/src/randombytes.h).
3. A custom FIPS-202 with `fips202.h` header compatible with [`mldsa/fips202/fips202.h`](../../mldsa/src/fips202/fips202.h).
   With `MLD_CONFIG_SERIAL_FIPS202_ONLY`, the FIPS-202x4 parallel API is not used.
4. The application source code

**WARNING:** The `randombytes()` implementation used here is for TESTING ONLY. You MUST NOT use this implementation
outside of testing.

## Usage

Build this example with `make build`, run with `make run`.

You should see verification failures, which is the expected behavior demonstrating that a single
global FIPS-202 state is insufficient for ML-DSA.

<!--- bibliography --->
[^tiny_sha3]: Markku-Juhani O. Saarinen: tiny_sha3, [https://github.com/mjosaarinen/tiny_sha3](https://github.com/mjosaarinen/tiny_sha3)
