[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Context parameter

This example shows how to add an application context to the mldsa-native public
API and pass it through to custom allocation callbacks.

The example has the same functional coverage as `examples/basic`: it exercises
the randomized and deterministic key-generation and signing APIs, plus
verification, for all three ML-DSA parameter sets.

## Configuration

The generated configuration in
[`mldsa_native_config.h`](mldsa_native/mldsa_native_config.h) enables:

- `MLD_CONFIG_CONTEXT_PARAMETER`
- `MLD_CONFIG_CONTEXT_PARAMETER_TYPE`
- `MLD_CONFIG_CUSTOM_ALLOC_FREE`

Note that `MLD_CONFIG_CUSTOM_ALLOC_FREE` is marked experimental: its scope and
the signatures of `MLD_CUSTOM_ALLOC`/`MLD_CUSTOM_FREE` may still change.

## The allocator

The context in [`example_context.h`](example_context.h) holds a bump allocator
over a statically declared buffer. Two properties of mldsa-native's allocation
behavior keep it this simple:

- **Deallocation happens in reverse order of allocation**, including when
  unwinding after a failed allocation. So a single cursor suffices, and freeing
  a block just moves the cursor back to its address; no per-allocation
  bookkeeping is needed. See [`test_alloc.c`](../../test/src/test_alloc.c),
  which empirically validates this contract for every allocation-failure point.
- **The total allocation per operation is known at compile time.** The buffer
  is sized from `MLD_TOTAL_ALLOC_{44,65,87}`, published by
  [`mldsa_native.h`](../../mldsa/mldsa_native.h) for exactly this purpose.

### Alignment

Memory handed to mldsa-native has to meet the alignment requirements of the
types it allocates. The strictest of those is 32 bytes, needed by the AVX2
backend for its aligned loads (`vmovdqa`); the other backends need less. Rather
than track which backend is in use, this example is conservative and aligns
every allocation to 32 bytes.

The buffer itself is declared with `EXAMPLE_ALIGN`, which mirrors the library's
internal `MLD_ALIGN` (see [`sys.h`](../../mldsa/src/sys.h)) — including its
fallback to no alignment on a toolchain that cannot express the constraint.

## Usage

```bash
make build
make run
```

The `randombytes()` implementation in `test_only_rng/` is for testing only.
Applications must provide a cryptographically secure RNG.
