[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# ML-DSA Compression Proofs

Isabelle/HOL proofs for the Barrett division used in ML-DSA's `Decompose` routine.

## Theory Files

- [Rounding.thy](Rounding.thy) — Round-half-down rounding and its stability properties
- [Barrett_Division.thy](Barrett_Division.thy) — Barrett approximation and correctness theorem
- [ML-DSA_Compress.thy](ML-DSA_Compress.thy) — ML-DSA specific instantiations for C/AVX2 and AArch64

## Building

See [../README.md](../README.md) for how to obtain Isabelle. With the
`isabelle` binary on your `PATH`, build via

```
isabelle build -D .
```

Alternatively, use the provided [Makefile](Makefile):

```
make jedit     # interactive proof session in Isabelle/jEdit
make           # build the proofs from the command line
```

## Limitation

The proofs operate on unbounded integers, not fixed-width machine words.
Connecting to actual implementations requires additional word-level reasoning.
