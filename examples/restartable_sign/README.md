[//]: # (SPDX-License-Identifier: CC-BY-4.0)


This directory contains a minimal example of *restartable signing*: pausing the
ML-DSA rejection-sampling loop and resuming it later, so that each signing call
has a bounded runtime while the overall result is identical to an uninterrupted
signature.

## Use Case

ML-DSA signing retries until a candidate signature passes rejection sampling,
so a single call has an unbounded runtime. On a system with strict timing
constraints you may want to cap the work done per call and continue later.
The signing hooks let you do that while retaining functional equivalence to
an uninterrupted ML-DSA signature operation.

## Configuration

The configuration file [mldsa_native_config.h](mldsa_native/mldsa_native_config.h) sets:
- `MLD_CONFIG_SIGN_HOOK_RESUME` / `_ATTEMPT` / `_FINISH`: the three hooks around
  the rejection-sampling loop. The attempt hook may pause signing (which then
  returns `MLD_ERR_SIGNING_PAUSED`); the resume hook continues from the paused
  attempt on the next call.
- `MLD_CONFIG_NO_RANDOMIZED_API`: resuming is only sound when the randomness is
  fixed across calls, so the caller drives the deterministic internal API.
- `MLD_CONFIG_NAMESPACE_PREFIX`: Symbol prefix (set to `mldsa`)

## Resume state: global vs. context

This example keeps the resume state in a **global variable**, so the hooks take
no arguments beyond the attempt counter. That is the simplest integration and
suits a single-threaded caller signing one message at a time.

For concurrent or interleaved signing, keep the state **per caller** instead:
enable `MLD_CONFIG_CONTEXT_PARAMETER`, give it your state type, and every public
API function gains a trailing context argument that is forwarded to the hooks.
See [test/src/test_sign_hook.c](../../test/src/test_sign_hook.c) for that
variant.

## Notes

- This is incompatible with `MLD_CONFIG_KEYGEN_PCT` (pairwise consistency test):
  the PCT runs a single internal signature that cannot be resumed.

## Usage

```bash
make build   # Build the example
make run     # Run the example
```
