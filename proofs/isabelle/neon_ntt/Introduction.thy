(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Introduction
  imports Asm_Montgomery Asm_Barrett
begin

chapter \<open>Introduction\<close>

text \<open>
The Number Theoretic Transform (NTT) is a performance-critical component of
lattice-based cryptography: ML-KEM~\cite{FIPS203} and ML-DSA~\cite{FIPS204} both
spend the majority of their arithmetic time in NTTs and the modular arithmetic
operations they are comprised of. Fast implementations of ML-KEM and ML-DSA --- including
\texttt{mlkem-native}~\cite{mlkemnative} and
\texttt{mldsa-native}~\cite{mldsanative} --- handle those modular
arithmetic cores through bespoke assembly instruction kernels tailored to the
target architecture.

The Neon NTT paper~\cite{NeonNTT} introduced
multiple novel such assembly kernels for the Armv8-A Neon vector instruction set,
notably signed Barrett multiplication, and presented a bounds reasoning for
Barrett arithmetic based on an equivalence between Barrett and Montgomery
multiplication and reduction. The correctness arguments for the kernels and the
Barrett--Montgomery equivalence are pen-and-paper, and errors at this level are
easy to make and easy to miss: an off-by-one in an absolute bound, a mis-stated
parity hypothesis, or a silently shared assumption between the Barrett and
Montgomery analyses can compromise an otherwise-audited NTT.

This document provides a machine-checked Isabelle/HOL formalisation of this
modular-arithmetic core of~\cite{NeonNTT}. First, at the level of abstract
algebraic operations: We develop parametric theories of Barrett and Montgomery
reduction and multiplication, uniform in modulus, word width, and integer
approximation, prove the identity linking Barrett and Montgomery arithmetic, and
treat the doubling- and rounding-Montgomery variants. We also offer a conceptual
recasting of the Barrett--Montgomery equivalence through the duality between
Euclidean and 2-adic rounding. Second, at the level of concrete assembly kernels:
we model the relevant Neon instructions --- \asminst{MUL}, \asminst{MULH}, \asminst{MLA}, \asminst{MLS}, \asminst{SQDMULH},
\asminst{SQRDMULH}, and \asminst{SHSUB} --- as operations on machine words, and prove correctness
and bounds theorems for the signed-word kernels shipped by \texttt{mlkem-native}
and \texttt{mldsa-native}. The kernel-level theorems are stated against this
abstract word model, assumed to match the corresponding Armv8-A ISA semantics;
NTT- and butterfly-level correctness, and a decoder from the abstract model to
concrete binaries, are out of scope.

Beyond its technical content, the development serves as a case study in
human-directed, model-generated formalisation. Claude Opus~4.7 and~4.8, connecting to
Isabelle through the open-source \texttt{AutoCorrode}~\cite{AutoCorrode} toolkit,
drafted the Isabelle source under the author's direction --- the author owned the
architecture and proof strategy, while the model supplied the formal text and
absorbed the bookkeeping of iteration and refactoring.
\autoref{ch:methodology} describes the loop in more detail.

Our formalisation uses the Isabelle/HOL interactive proof assistant.
Isabelle/HOL is one of the most mature proof assistants available today,
with a development history spanning over three decades. It has been used in
large-scale verification efforts including the seL4
microkernel~\cite{Klein2009seL4,Klein2014seL4}, the formal proof of the
Kepler conjecture~\cite{Hales2017Kepler}, recent work on cryptographic
library verification at Apple~\cite{AppleCorecrypto2025}, and the ongoing
verification of the AWS Nitro Isolation
Engine~\cite{AWSNitro2025}. The Archive of Formal
Proofs~\cite{AFP}, a refereed collection of Isabelle developments, hosts
close to a thousand entries at the time of writing. Beyond maturity, we
chose Isabelle/HOL for its
general ease of use; its structured proof language Isar, which reads close
to natural mathematical exposition; its document preparation system, which
makes it possible to share a single source between paper and formal proof;
and the author's prior familiarity with the system.

\medskip\noindent\textbf{Contributions.}
\begin{enumerate}
\item A machine-checked Isabelle/HOL formalisation of the arithmetic core
  of~\cite{NeonNTT}.
\item A demonstrator for human-directed, model-generated formalisation at the
  scale of a research paper.
\end{enumerate}
We do not claim novelty on the formal verification of assembly-level
modular arithmetic kernels --- several prior efforts have established
such results (see next section).

\medskip\noindent\textbf{Related work.}
\cite{NeonNTT} is the reference for the algorithms and bounds formalised
here; its Lemma~1, Propositions~1--4, Facts~1--3, Corollaries~1 and~2, and
Algorithms~2, 5, 7, 8, 9, 10, 12, and~13 each have a named counterpart in this
development. Algorithms~1, 3, 4, 6, and~11 are pseudocode renderings of the same
operators, captured at the operator level rather than as separate formal artifacts.

Multiple prior efforts have established formal correctness for assembly-level
modular arithmetic kernels used in post-quantum cryptography. CryptoLine
verifies NTT multiplications for Kyber, SABER, and NTRU at the instruction
level for both AVX2 and Cortex-M4~\cite{CryptoLine2022,CryptoLine2025}.
The Formosa Crypto project~\cite{FormosaCrypto} uses Jasmin and EasyCrypt to
produce verified high-speed implementations with end-to-end guarantees from
source to binary. Apple's recent verification of
corecrypto~\cite{AppleCorecrypto2025} covers assembly-level modular arithmetic
in a production cryptographic library. And \texttt{mlkem-native} and
\texttt{mldsa-native} ship HOL Light + \texttt{s2n-bignum} proofs that work
at the binary level against a model of the Armv8-A instruction decoder and
semantics for the deployed kernels.
Relative to these efforts, the present development does not target a specific
deployed binary but isolates the algebraic content shared across kernels ---
parametrically over modulus, word width, and rounding mode --- so that a new
kernel or parameter set reuses the bounds rather than reproving them.

\medskip\noindent\textbf{Source code.}
The Isabelle sources for this document reside in the \texttt{mldsa-native}
repository~\cite{mldsanative} under
\url{https://github.com/pq-code-package/mldsa-native/tree/main/proofs/isabelle/neon_ntt}.
\<close>

chapter \<open>Methodology \label{ch:methodology}\<close>

text \<open>
\medskip\noindent\textbf{AutoCorrode.}
Large language models are powerful across many domains, and their efficacy
can often be amplified by providing direct interfaces to their target, such
as CLIs or MCPs. In the context of interactive theorem proving, a tight
feedback loop based on a direct and persistent connection between agent and
proof kernel allows the agent to develop proofs faster and more effectively
than a repeated edit-and-rebuild loop.

The \texttt{AutoCorrode}~\cite{AutoCorrode} verification infrastructure
includes two agent--prover interfaces for Isabelle. First, Isabelle/Q
(``I/Q'') is an Isabelle/jEdit plugin exposing proof editing and exploration
as an MCP server --- the agent edits theory files and observes prover
feedback in the same way a human would, without triggering a rebuild after
every change. However, it is not conducive to concurrent edits by both human
and the agent. For that, Isabelle/REPL (``I/R'') lets the agent talk
directly to the Isabelle/ML prover process in a REPL loop, bypassing jEdit
and PIDE. I/R is integrated into I/Q: the agent can fork a REPL at an
arbitrary point in a theory opened in Isabelle/jEdit (e.g.\ a
\texttt{sorry}'ed proof) and start exploring alternative theory texts
without yet making the edits in jEdit. I/R is ad-hoc and may be replaced by
something more PIDE-native in the future, but it demonstrates what
concurrent human/AI proof editing can look like: the agent works out
multiple proofs while the human keeps editing the document elsewhere.
\texttt{AutoCorrode} also includes Isabelle/Proxy (``I/P''), which offloads
the Isabelle/ML prover process to a remote server while keeping
Isabelle/jEdit and the JVM local --- a powerful capability for large-scale
developments, though less relevant for the present example.

\medskip\noindent\textbf{The human/AI loop.}
The agent provided the initial auto-formalisation of
\cite{NeonNTT} completely autonomously. It lacked clarity,
brevity, and generally did not make for a paper-style artifact that a human
would like to consume. It was the task of the human author to then
gradually nudge the agent to adjust the narrative, compact proofs, tweak
definitions, introduce suitable syntax, and decide on what to abridge and
what to include. No proof was ultimately written by the human --- even under
strong editorial direction, the formal text remained
model-generated. Despite this heavy involvement, the development was much
faster than had the human formalised the material themselves. In addition to
the time-saving of not having to write definitions and proofs manually, the
agent was hugely effective at making cross-cutting changes such as syntax
adjustments, propagating signature changes through many call sites, and
relocating code across theories.

It was noteworthy that the agent had often disregarded existing proofs and
even proof strategies from \cite{NeonNTT}, and come up with its
own approaches --- for better or for worse. Two examples stand out. First,
instead of relying on the Barrett--Montgomery equivalence to establish
bounds for Barrett arithmetic, the agent proved those bounds directly. This
is interesting per se, but directly opposed to the approach of
\cite{NeonNTT}, which demonstrates how the obvious Montgomery
bound can be carried over to Barrett using the equivalence. Second,
\cite[Algorithm~8]{NeonNTT} states the correctness of Montgomery
multiplication with rounding under a parity hypothesis (\<open>a\<close> odd or \<open>b\<close>
odd). The agent correctly noted that this assumption is unnecessary and
proved the algorithm unconditionally correct --- a genuine improvement over
\cite{NeonNTT} surfaced by the
formalisation.\footnote{Interestingly, a recent contribution
(\url{https://github.com/pq-code-package/mlkem-native/pull/1184}) to
\texttt{mlkem-native} had independently used this algorithm: the PPC64
compiler developers had discovered and implemented it without the parity
assumption
(\url{https://github.com/pq-code-package/mlkem-native/pull/1184\#issuecomment-4485661049}).}

\medskip\noindent\textbf{Unifying paper and proof.}
When paper and formal development live in separate artifacts, time and care
is needed to ensure that they stay in sync as changes are made on either
side. To avoid this overhead and soundness risk, we use Isabelle's document
preparation system to auto-generate all documentation from the formal
sources. Every chapter of this document is an Isabelle theory file.
Refactoring a lemma moves the surrounding prose with it; adding a new
abbreviation propagates to every displayed term downstream. Isabelle's
mixfix syntax keeps the formal text close to the notation a reader would
expect from a paper. The present version is heavily abridged --- most
auxiliary lemmas and almost all proofs are elided for the sake of
highlighting the main arguments. The full theory contents can be included
by rebuilding with different tags.
\<close>

chapter \<open>Roadmap\<close>

text \<open>
We provide a brief summary of each chapter:

\begin{description}
\item[\autoref{ch:integer_approx} (\<open>Integer_Approximation\<close>)]
  develops the parametric notion of integer approximation
  \<open>\<lbrakk>_\<rbrakk> : \<rat> \<rightarrow> \<int>\<close> and the residue operator
  \<^term>\<open>z mod\<lbrakk>f\<rbrakk> N\<close>.

\item[\autoref{ch:montgomery_red} (\<open>Montgomery_Reduction\<close>)] develops
  Montgomery reduction and multiplication operators. We distinguish
  additive vs.\ subtractive and signed vs.\ unsigned versions.

\item[\autoref{ch:barrett_red} (\<open>Barrett_Reduction\<close>)] develops
  signed and unsigned Barrett reduction and multiplication operators,
  parametric in a choice of integer approximation \<open>\<lbrakk>_\<rbrakk>\<close>. We also introduce a 'refined' 
  Barrett reduction at an inflated radix. Output bounds are
  deferred to \autoref{ch:barrett_montgomery}, where they fall out of
  the Barrett--Montgomery equivalence.

\item[\autoref{ch:barrett_montgomery} (\<open>Barrett_Montgomery\<close>)] proves
  the Barrett--Montgomery equivalence: Barrett reduction of \<^term>\<open>z\<close> equals
  Montgomery reduction of \<open>z \<cdot> (R mod\<lbrakk>f\<rbrakk> N)\<close>. This
  collapses the bounds proofs of the two families
  \cite[Corollaries~1 and~2]{NeonNTT} into a single
  argument.

\item[\autoref{ch:barrett_bound_quality}
  (\<open>Barrett_Bound_Quality\<close>)] checks the quality of the abstract
  Barrett bounds against empirical maxima at three concrete moduli:
  a small illustrative prime ($N = 97$), the ML-KEM modulus
  ($N = 3329$), and the ML-DSA modulus ($N = 8380417$).

\item[\autoref{ch:montgomery_doubling} (\<open>Montgomery_Doubling\<close>)]
  formalises the doubling- and rounding-Montgomery variants
  \cite[Algorithms~7 and~8]{NeonNTT}.

\item[\autoref{ch:bridge_conceptual} (\<open>Bridge_Conceptual\<close>)] revisits
  the Barrett--Montgomery equivalence from a conceptual viewpoint,
  casting it as a consequence of the duality between Euclidean and
  2-adic rounding of a rational number.

\item[\autoref{ch:barrett_division_even} (\<open>Barrett_Division_Even\<close>)]
  generalises the bridge to an arbitrary modulus, replacing the use of 
  modular inverses by choices of modular quotients. This is relevant
  for the \<open>decompose\<close> routine in ML-DSA..

\item[\autoref{ch:word_ops} (\<open>Word_Ops\<close>)] models the per-lane behavior 
  of relevant Neon instructions as parametric operations on arbitrary-width words.

\item[\autoref{ch:asm_barrett} (\<open>Asm_Barrett\<close>)] proves correctness of
  some Barrett Neon kernels --- Barrett multiplication, plain Barrett reduction, refined
  Barrett reduction, and 'even' Barrett reduction --- against the models of
  \autoref{ch:word_ops}.

\item[\autoref{ch:asm_montgomery} (\<open>Asm_Montgomery\<close>)] proves
  correctness of some Montgomery Neon kernels --- including the doubling- and
  rounding-based variants --- against the models of \autoref{ch:word_ops}.

\end{description}
\<close>

end
