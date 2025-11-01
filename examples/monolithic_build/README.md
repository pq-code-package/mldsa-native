[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Single-level mldsa-native in a single compilation unit

This directory contains a minimal example for how to build a single instance of mldsa-native in a single compilation
unit. Only the C-backend is exercised.

The auto-generated source file [mldsa_native.c](mldsa/mldsa_native.c) includes all mldsa-native C source
files. Moreover, it clears all `#define`s clauses set by mldsa-native at the end, and is hence amenable to multiple
inclusion in another compilation unit. It exposes the API [../../mldsa/mldsa_native.h](mldsa/mldsa_native.h).

## Usage

Build this example with `make build`, run with `make run`.

**WARNING:** The `randombytes()` implementation used here is for TESTING ONLY. You MUST NOT use this implementation
outside of testing.
