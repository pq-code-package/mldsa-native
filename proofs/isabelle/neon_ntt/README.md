[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Neon NTT — Isabelle/HOL Formalisation

This directory provides additional formal documentation of the approach to
modular arithmetic used in various assembly kernels in `mldsa-native` and
`mlkem-native`. Specifically, it contains the source for an Isabelle/HOL
formalisation of the original "Neon NTT" paper [^NeonNTT] of Becker, Hwang,
Kannwischer, Yang, and Yang. A companion PDF — generated directly from the
theory sources via Isabelle's document-preparation system — is produced by
[`make`](#building) and is also published as the `neon_ntt_autoformalized`
artifact of the [Isabelle CI workflow](../../../.github/workflows/isabelle.yml).

## What the PDF covers

The PDF reads as a paper but is auto-generated from the `.thy` files in this
directory: every chapter corresponds to a theory and the prose, displayed
terms, and theorem statements are the formal text. There is no separate
narrative to drift out of sync.

Two layers of content:

- **Abstract algebra.** Parametric Barrett and Montgomery reduction and
  multiplication, uniform in modulus, word width, and integer approximation;
  the Barrett–Montgomery equivalence; the doubling- and rounding-Montgomery
  variants; a recasting of the equivalence as Euclidean / 2-adic rounding
  duality; and an empirical bound-quality study at the ML-KEM (`N = 3329`)
  and ML-DSA (`N = 8380417`) moduli.
- **Concrete kernels.** A model of the relevant Armv8-A Neon instructions
  (`MUL`, `MLA`, `MLS`, `MULH`, `UMULH`, `SQDMULH`, `SQRDMULH`, `SQRDMLAH`,
  `SHSUB`, `SRSHR`) as parametric word operations, and correctness and
  bounds theorems for the signed-word Barrett and Montgomery kernels shipped
  by `mldsa-native` (and `mlkem-native`).

Methodologically, the development is a human-directed auto-formalisation:
theory text was drafted by Claude Opus 4.7 driving Isabelle through
AutoCorrode's I/Q (jEdit/MCP) and I/R (REPL) interfaces [^AutoCorrode], with
the human author owning architecture, abstractions, and editorial control.

## Relation to the mldsa-native source

The kernels analysed here are the modular-arithmetic primitives used inside
the AArch64 NTT and pointwise-multiplication assembly under
[`mldsa/src/native/aarch64/src/`](../../../mldsa/src/native/aarch64/src/) —
in particular `ntt_aarch64_asm.S`, `intt_aarch64_asm.S`,
`pointwise_montgomery_aarch64_asm.S`, and the
`mld_polyvecl_pointwise_acc_montgomery_l{4,5,7}_aarch64_asm.S` variants.

The proofs are stated against an abstract word model assumed to match the
Armv8-A semantics; agreement of the model with actual silicon is
exercised separately, see [Conformance testing](#conformance-testing) below.
The development does **not** descend to a concrete instruction decoder
or to NTT- and butterfly-level correctness. End-to-end, binary-level
verification of the deployed kernels is covered separately by the HOL Light +
[s2n-bignum](https://github.com/awslabs/s2n-bignum) proofs under
[`proofs/hol_light`](../../hol_light). The two efforts are complementary:
this development isolates the algebraic content shared across kernels so
that a new kernel or parameter set reuses the bounds rather than reproving
them.

## Theory layout

| File | Role |
|---|---|
| `Introduction.thy` | Motivation, methodology, roadmap |
| `Integer_Approximation.thy` | Parametric integer approximation `⟦·⟧ : ℚ → ℤ` |
| `Montgomery_Reduction.thy` | Abstract Montgomery reduction / multiplication |
| `Barrett_Reduction.thy` | Abstract Barrett reduction / multiplication |
| `Barrett_Montgomery.thy` | Barrett–Montgomery equivalence and Barrett bounds |
| `Barrett_Bound_Quality.thy` | Empirical bound study at `N ∈ {97, 3329, 8380417}` |
| `Montgomery_Doubling.thy` | Doubling / rounding Montgomery variants |
| `Bridge_Conceptual.thy` | Euclidean / 2-adic rounding duality |
| `Word_Ops.thy` | Width-parametric model of the Neon instructions |
| `Asm_Barrett.thy` | Correctness of the Neon Barrett kernels |
| `Asm_Montgomery.thy` | Correctness of the Neon Montgomery kernels |
| `Conclusions.thy` | Summary |

`document/` holds the LaTeX preamble, bibliography, and IACR class.
`model/` holds executable harnesses (SML/C) used for the bound-quality study
and conformance testing of the word model against actual hardware.

## Prerequisites

- Isabelle/HOL — see [../README.md](../README.md) for installation (tested
  with `Isabelle2025-2`). CI builds against the
  [`makarius/isabelle:Isabelle2025-2_ARM_X11_Latex`](https://hub.docker.com/r/makarius/isabelle)
  Docker image.
- A TeX distribution providing `luacode.sty` (loaded transitively by
  `iacrtrans` → `hyperref` → `hyperxmp`). On Debian/Ubuntu this is
  `texlive-luatex`; the Isabelle macOS app already bundles it.
- For the conformance harnesses under `model/hw` and `model/sml`: a C
  toolchain (`gcc`, `libc`, `make`) and Python 3. `model/hw/hw_exec.c`
  requires an AArch64 host (it rejects other architectures at compile time).

## Building

Build with the included Makefile:

```
make           # build PDF
make jedit     # open Asm_Montgomery.thy in Isabelle/jEdit
```

See [../README.md](../README.md) for how to obtain Isabelle and point the
Makefile at it.

The default build is heavily abridged — auxiliary lemmas and most proof
bodies are elided via Isabelle document tags. A full-proof build can be
produced by overriding the `internal` and `proof` tags in `document/root.tex`.

## Conformance testing

The `Word_Ops` theory provides an ad-hoc model of the relevant Neon
instructions; the correctness theorems for the assembly kernels are stated
against that model. Conformance testing empirically confirms that this
ad-hoc model agrees with native execution on an AArch64 host.

Two binaries are compared side-by-side, both reading the same stream of
`MNEMONIC BITWIDTH ARGS...` cases on stdin and emitting one hex result per
line on stdout:

- `model/sml/model_exec` — Isabelle-exported SML code for `Word_Ops`. The
  Isabelle build produces `model.ML` via `export_code` (driven by
  `Word_Ops_Export.thy` and `Conformance_Testing.thy`); the Makefile under
  `model/sml/` wraps it in a thin script that invokes Isabelle's bundled
  PolyML.
- `model/hw/hw_exec` — a small C harness that issues the corresponding Neon
  intrinsics directly. It must be built and run on an AArch64 host.

`model/conformance/run.py` drives both processes through random, edge-value,
and (for 8-bit ops) exhaustive case streams across all instruction /
bit-width combinations covered in `Word_Ops`.

To build and run conformance from the `neon_ntt` root:

```
make conformance                       # edge cases + 50k random per op
make conformance CONFORMANCE_RUNS=1000000
```

The underlying driver also exposes `full` (exhaustive, 8-bit only) and
`all` modes, plus `--mnemonic` / `--bitwidth` filters; invoke
`python3 model/conformance/run.py --help` for details.

<!--- bibliography --->
[^AutoCorrode]: Becker, Chong, Dockins, Grundy, Hu, Mulder, Mulligan, Mure, Paulson, Slind: AutoCorrode software verification framework for Isabelle/HOL, [https://github.com/awslabs/autocorrode](https://github.com/awslabs/autocorrode)
[^NeonNTT]: Becker, Hwang, Kannwischer, Yang, Yang: Neon NTT: Faster Dilithium, Kyber, and Saber on Cortex-A72 and Apple M1, [https://eprint.iacr.org/2021/986](https://eprint.iacr.org/2021/986)
