(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Conclusions
  imports Asm_Montgomery Asm_Barrett
begin

chapter \<open>Conclusions \label{ch:conclusions}\<close>

text \<open>
We have given a machine-checked Isabelle/HOL account of the
modular-arithmetic core of~\cite{NeonNTT}: parametric Barrett and
Montgomery reduction and multiplication uniform in modulus, word
width, and integer approximation; the Barrett--Montgomery equivalence
and its recasting through Euclidean--2-adic rounding duality; an
empirical bound-quality study at the ML-KEM~\cite{FIPS203} and ML-DSA~\cite{FIPS204} moduli;
an extension of the Barrett--Montgomery bridge to even moduli, underpinning
ML-DSA's \texttt{decompose}; and
correctness theorems for the signed-word Neon kernels shipped by
\texttt{mlkem-native} and \texttt{mldsa-native}. A small algorithmic
improvement surfaced in the process: the parity hypothesis on
\cite[Algorithm~8]{NeonNTT} is unnecessary, as independently
discovered by the PPC64 contributors to \texttt{mlkem-native}.

The development also functions as a demonstrator for human-directed,
model-generated formalisation at the scale of a research paper. With a
tight agent--prover feedback loop --- here, \texttt{AutoCorrode}'s I/Q
and I/R interfaces --- the agent drafted definitions and proofs while
the human author owned the architecture, the narrative, and the
editorial choices. The result was both faster than writing the formal
text by hand and arguably tighter: the discipline of mechanization
sharpens definitions and surfaces silent assumptions, and cross-cutting
refactors that a human author would otherwise defer become cheap
enough to perform routinely. We expect this style of work to become
common in cryptographic engineering research.

Two pieces of infrastructure made this practical and warrant continued
investment. Agent--prover interfaces such as those of
\texttt{AutoCorrode}~\cite{AutoCorrode} give the agent direct access
to prover state and a feedback channel without rebuilds. Isabelle's
document preparation system keeps paper and proof in a single source:
every chapter of this document is a theory file, and the
synchronization overhead of maintaining separate paper and proof
artifacts is removed by construction.
\<close>

end
