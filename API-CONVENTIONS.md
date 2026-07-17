[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# API conventions

This document describes conventions shared by all public functions declared in [`mldsa/mldsa_native.h`](mldsa/mldsa_native.h). The per-function documentation in that header takes precedence wherever it is more specific.

## Return values

Functions returning `int` return `0` on success and a negative error code on failure. Error codes are enumerated as `MLD_ERR_XXX` constants in `mldsa_native.h`.

Errors have different origins, and not all are fatal. For example, signature verification routines use `MLD_ERR_FAIL` to signal an invalid signature, and signing hooks use `MLD_ERR_SIGNING_PAUSED` to signal a paused signing operation. Other errors, such as `MLD_ERR_SIGN_ATTEMPTS_EXHAUSTED` or `MLD_ERR_RNG_FAIL`, should never be observed in normal operation and hint at a deeper failure in the system.

Return values must always be checked; the public API is annotated with `warn_unused_result` on compilers that support it.

## Pointer arguments

All pointer arguments are assumed to be valid and non-NULL, and every buffer is assumed to have the size implied by its parameter type. mldsa-native does not check pointers for NULL and does not validate buffer sizes; passing a NULL or otherwise invalid pointer, or an undersized buffer, is undefined behavior. Ensuring these preconditions is the caller's responsibility.

The exception is a pointer paired with a length: it may be NULL when that length is `0` — for example, the message `m` when `mlen == 0`, or `ctx` when `ctxlen == 0`. Such cases are called out in the per-function documentation.

## Output buffers on error

When a function returns an error, each caller-owned output buffer is left either unchanged or fully zeroized. An output buffer is never left holding partially computed or otherwise stale data that could be mistaken for a valid result.
