[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Using a custom configuration and FIPS-202 backend

This directory contains a minimal example for how to use mldsa-native as a code package, with a custom FIPS-202
backend and a custom configuration. We use [^tiny_sha3] as an example.

## Components

An application using mldsa-native with a custom FIPS-202 backend and custom configuration needs the following:

1. Arithmetic part of the mldsa-native source tree: [`mldsa/src/`](../../mldsa/src). In this example, we disable arithmetic
   backends, hence it is safe to remove the entire `native` subfolder.
2. A secure pseudo random number generator, implementing [`randombytes.h`](../../mldsa/src/randombytes.h). **WARNING:** The
   `randombytes()` implementation used here is for TESTING ONLY. You MUST NOT use this implementation outside of testing.
3. FIPS-202 part of the mldsa-native source tree, [`fips202/`](../../mldsa/src/fips202). If you only want to use your backend,
   you can remove all existing backends; that's what this example does.
4. A custom FIPS-202 backend. In this example, the backend file is
   [custom.h](mldsa_native/mldsa/src/fips202/native/custom/custom.h), wrapping
   [sha3.c](mldsa_native/mldsa/src/fips202/native/custom/src/sha3.c) and setting `MLD_USE_FIPS202_X1_NATIVE` to indicate that we
   replace 1-fold Keccak-F1600.
5. Either modify the existing [config.h](mldsa_native/mldsa/src/config.h), or register a new config. In this example, we add
   a new config [custom_config.h](mldsa_native/custom_config.h) and register it from the command line for
   `-DMLD_CONFIG_FILE="custom_config.h"` -- no further changes to the build are needed. For the sake of
   demonstration, we set a custom namespace. We set `MLD_CONFIG_FIPS202_BACKEND_FILE` to point to our custom FIPS-202
   backend, but leave `MLD_CONFIG_USE_NATIVE_BACKEND_ARITH` undefined to indicate that we wish to use the C backend.

## Note

The tiny_sha3 code uses a byte-reversed presentation of the Keccakf1600 state for big-endian targets. Since
mldsa-native's FIPS202 frontend assumes a standard presentation, the corresponding byte-reversal in
[sha3.c](mldsa_native/mldsa/src/fips202/native/custom/src/sha3.c) is removed.

## Usage

Build this example with `make build`, run with `make run`.

<!--- bibliography --->
[^tiny_sha3]: Markku-Juhani O. Saarinen: tiny_sha3, [https://github.com/mjosaarinen/tiny_sha3](https://github.com/mjosaarinen/tiny_sha3)
