[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# HOL Light proofs

This directory contains HOL Light proofs for the AArch64, x86_64, and RV32IM
assembly routines used in mldsa-native. The proofs are written in the
[HOL Light](https://hol-light.github.io/) theorem prover, utilizing the
assembly verification infrastructure from
[s2n-bignum](https://github.com/awslabs/s2n-bignum).

Each function is proved in a separate `.ml` file under
[aarch64/proofs/](aarch64/proofs), [x86_64/proofs/](x86_64/proofs), or
[riscv32/proofs/](riscv32/proofs). Each proof entry contains the checked
bytecode for its corresponding object file near the top.

## What is proven

Unless documented otherwise, for each assembly routine listed below, we prove three properties:

1. **Functional correctness** — the routine computes the specified mathematical function (e.g., that `mldsa_ntt` computes the ML-DSA forward NTT modulo `q = 8380417`).
2. **Memory safety** — the routine accesses only those memory regions permitted by its specification (input/output buffers, stack frame).
3. **Secret-independent timing** — the sequence of microarchitectural events (e.g. memory accesses, branch decisions) emitted by the routine is a function of public inputs only, and does not depend on secret data.

For RV32IM, the timing claim follows the s2n-bignum RISC-V model. In
particular, `MUL` and `MULH` are modeled without operand-dependent timing
events. The proof therefore applies to implementations where those
instructions have fixed latency, or where any operand-dependent latency is
otherwise excluded from the attacker model.

### By design: rejection sampling for the public matrix (`rej_uniform`)

`rej_uniform` expands the public matrix A from the public seed rho. Because it operates on public data only,
secret-independent timing is not a requirement, and admitting variable-time execution enables a faster
implementation. We therefore prove properties 1 and 2 for it, but deliberately not property 3.

### Constant-time rejection sampling for the secret vector (`rej_uniform_eta{2,4}`)

The `rej_uniform_eta{2,4}` kernels (on both AArch64 and x86_64) sample the secret vectors `s1`/`s2` by
rejection, so their control flow and memory-access pattern depend on *which* candidates are accepted, and
the standard one-line safety tactic asserting full obliviousness does not apply. Instead we prove
**secret-independence against a public reject pattern**: the microarchitectural event trace is a function
of the public pointers and the reject pattern — one accept/reject bit per candidate nibble — and of nothing
else, in particular not of the accepted coefficient *values*. The XOF stream is secret, but the reject pattern is
safe to leak, each acceptance decision being statistically independent of the accepted values (Section 5.5
of [^Round3_Spec]).

Concretely, the constant-time safety theorems for `rej_uniform_eta2` and `rej_uniform_eta4` state
that some event-generating function `f_events`, depending only on public data, reproduces the
entire trace (shown here for eta2; the eta4 statement is identical with `REJ_MASK_ETA4` and `val x < 9`):

```ocaml
`?f_events.
   !res buf buflen table (inlist:byte list) pc e stackpointer returnaddress.
     (* same alignment / non-overlap preconditions as _MEMSAFE *)
     ...
     ==> ensures arm
          (\s. (* same precondition as _MEMSAFE: code at pc, C arguments
                  [res;buf;buflen;table], input bytes at buf, table at table,
                  event log = e *)
               ... /\ read events s = e)
          (\s. read PC s = returnaddress /\
               ?e2. read events s = APPEND e2 e /\
                    (* the events of this call are EXACTLY f_events applied to the
                       public arguments and the reject pattern -- and not the
                       accepted coefficient values *)
                    e2 = f_events res buf buflen table pc stackpointer
                                  returnaddress (REJ_MASK_ETA2 inlist) /\
                    memaccess_inbounds e2 (read set) (write set))
          (\s s'. T)`
```

where `REJ_MASK_ETA2 l = MAP (\x. val x < 15) (NIBBLES_OF_BYTES l)` is the reject pattern — one
accept/reject bit per nibble, accepted values discarded. (Contrast `REJ_NIBBLES_ETA2`, which *keeps* the
accepted values and is secret.) Because the whole trace factors through the reject pattern, two inputs with
the same pattern are indistinguishable to a timing/cache adversary regardless of their coefficient
values.

The x86_64 AVX2 kernels prove the identical property (with `ensures x86`). Because the x86_64
`rej_uniform_eta{2,4}` assembly processes a fixed-length input buffer (136 bytes for eta2, 272 for eta4)
rather than taking a runtime `buflen` argument, its `f_events` and preconditions specialise `buflen` to
that constant; the reject-pattern factoring is otherwise identical.


## Primer

Proofs are 'post-hoc' in the sense that HOL-Light/s2n-bignum operate on the final object code. In particular, the means by which the code was generated need not be trusted.

Specifications are essentially [Hoare triples](https://en.wikipedia.org/wiki/Hoare_logic), with the noteworthy difference that the program is implicit as the content of memory at the PC; which is asserted to
be the code under verification as part of the precondition. For example, the following is the specification of the `mldsa_ntt` function:

```ocaml
 (* For all (abbreviated by `!` in HOL):
    - a: Polynomial coefficients pointer
    - zetas: NTT constants pointer
    - x: Original polynomial coefficients
    - pc: Current value of Program Counter (PC)
    - stackpointer: Stack pointer
    - returnaddress: Return address on the stack *)
`!a zetas x pc stackpointer returnaddress.
    (* Alignment and non-overlapping requirements *)
    aligned 32 a /\
    aligned 32 zetas /\
    nonoverlapping (word pc,LENGTH mldsa_ntt_mc) (a, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_ntt_mc) (zetas, 2496) /\
    nonoverlapping (a, 1024) (zetas, 2496) /\
    nonoverlapping (stackpointer,8) (a, 1024) /\
    nonoverlapping (stackpointer,8) (zetas, 2496)
    ==> ensures x86
      (* Precondition *)
      (\s. (* The memory at the current PC is the byte-code of mldsa_ntt() *)
        bytes_loaded s (word pc) mldsa_ntt_mc /\
        read RIP s = word pc /\
        read RSP s = stackpointer /\
        (* The return address is on the stack *)
        read (memory :> bytes64 stackpointer) s = returnaddress /\
        (* Arguments are passed via C calling convention *)
        C_ARGUMENTS [a; zetas] s /\
        (* NTT constants are properly loaded *)
        wordlist_from_memory(zetas,624) s = MAP (iword: int -> 32 word) mldsa_complete_qdata /\
        (* Input bounds checking *)
        (!i. i < 256 ==> abs(ival(x i)) <= &8380416) /\
        (* Give a name to the memory contents at the source pointer *)
        !i. i < 256
            ==> read(memory :> bytes32(word_add a (word(4 * i)))) s = x i)
      (* Postcondition: Eventually we reach a state where ... *)
      (\s.
        (* The PC is the return address *)
        read RIP s = returnaddress /\
        (* Stack pointer is adjusted *)
        read RSP s = word_add stackpointer (word 8) /\
        (* The integers represented by the final memory contents
         * are congruent to the ML-DSA forward NTT transformation
         * of the original coefficients, modulo 8380417, with proper bounds *)
        !i. i < 256
            ==> let zi = read(memory :> bytes32(word_add a (word(4 * i)))) s in
                (ival zi == mldsa_forward_ntt (ival o x) i) (mod &8380417) /\
                abs(ival zi) <= &42035261)
      (* Footprint: The program may modify (only) the ABI permitted registers
       * and flags, stack pointer, and the memory contents at the source pointer. *)
      (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
       MAYCHANGE [memory :> bytes(a,1024)])`
```

## Reproducing the proofs

To reproduce the proofs, enter the nix shell via

```bash
nix develop .#hol_light --experimental-features 'nix-command flakes'
```

from mldsa-native's base directory. Then

```bash
make -C proofs/hol_light/aarch64
```
or

```bash
make -C proofs/hol_light/x86_64
```

For RV32IM, use the shell containing the cross toolchain:

```bash
nix develop .#hol_light-cross-riscv32 \
  --experimental-features 'nix-command flakes'
make -C proofs/hol_light/riscv32
```

These commands build and run the proofs. Note that this may take hours even
on powerful machines.

For convenience, you can also use `tests hol_light`, which wraps the `make`
invocation above. Pass `-a riscv32` when cross-checking RV32IM proofs on
another host; see `tests hol_light --help`.

### RV32IM arithmetic proof unrolling

All five RV32IM routine entries execute every core instruction symbolically:

| Routine | Core instructions |
| --- | ---: |
| Forward NTT | 9,369 |
| Forward NTT, slow multiplier | 12,439 |
| Inverse NTT | 11,936 |
| Inverse NTT, slow multiplier | 15,774 |
| Pointwise Montgomery multiplication | 2,821 |

Their bytecode assertions and public core, subroutine and safety
specifications are unchanged. The local helpers first prove exact output
words without input bounds; the existing arithmetic theorems then establish
the mathematical result and output bounds. Inverse NTT execution includes
the final scaling loop. Pointwise execution retains the second input array
as frame-protected immutable reads.

The entries enable scoped s2n-bignum context rewriting and memory snapshots,
and explicitly request permitted-frame seeding. They use ordinary arithmetic
abbreviations and memoized output-expression traversal. Their block-based
safety proofs track intermediate frames and keep the final trace function
under a short name until the whole safety proof has been assembled.
No HOL Light source or kernel change is needed.

### Symbolic execution support

The Nix package pins the reviewed s2n-bignum fork revision and source hash
in `nix/s2n_bignum/default.nix`. The normal cross shell selects this package;
the production proofs do not require a local override or a HOL Light patch.
The selected source includes nine execution optimizations plus the two
opt-in helpers described below. It excludes phase profiling, goal-only
abbreviations, omission of intermediate frames and the replay-only proof cache.

For development against an editable s2n-bignum checkout, use Nix's dependency
redirect from the repository root:

```bash
nix develop .#hol_light-cross-riscv32 \
  --redirect .#s2n_bignum "$HOME/repos/s2n-bignum-task-speedups"
```

The shell exports the selected source as `S2N_BIGNUM_DIR` and points the
namespaced HOL Light import at it. The redirect affects only that development
shell; it does not change the committed revision or source hash.

Context rewriting reuses preparation for unchanged assumption-list tails.
A HOL Light conversion takes a term `t` and returns a theorem
`Gamma |- t = u`: a checked equality to the simplified term `u`, with any
hypotheses `Gamma` used by the rewrite.

Output folding opts into `MEMOIZED_TOP_DEPTH_CONV`. For an expression such as
`f 0 + f 0`, ordinary traversal proves the simplification of `f 0` twice;
the new traversal remembers the first equality theorem and reuses it.
The cache keys are exact terms, including types and variable names, not
rewrite patterns. Its limit of 16384 entries bounds the number of results,
not their total size. `CACHE_LAST_THEOREM_CONV` rebuilds the conversion when
the actual context proof objects or basic rewrite table change. Reused
theorems keep their hypotheses: a fact derived from one context is not
treated as an unconditional equality in a different context.

Arithmetic names use ordinary `AUTO_ABBREV_TAC`, which rewrites the whole
context. Existing s2n-bignum `TOP_DEPTH_CONV` callers remain unchanged.

A HOL Light tactic returns subgoals and a justification function. Once the
subgoals have been proved, that function assembles the input goal's theorem
and applies substitutions found during the remaining proof.

The safety specification chooses a function describing the complete event
trace. Substituting that large function into saved instruction theorems
repeatedly traverses the same expression. All five RV32 entries select
`PROVE_SAFETY_SPEC_TAC ~defer_witness:true`, wrapping the complete safety
driver in `WITH_DEFERRED_ABBREVS_TAC`, including its existential introduction.
For the function `t`, the wrapper supplies a fresh name `n` under the
temporary theorem hypothesis `t = n`. Saved justifications substitute that
short name while assembling the proof.

Only afterwards does existential elimination remove the naming equation,
using the checked theorem `|- ?n. t = n`, proved by choosing `t`.
No naming equation remains in the final theorem; ordinary kernel checks
still reject captured local variables. Memory-access bounds, intermediate
frame tracking and public claims are unchanged. Callers without the flag
keep the ordinary witness path.

`ENSURES_INIT_TAC` tracks the actual writes from an initially empty frame
by default, preserving the intermediate frame facts used by existing proofs.
Use `ENSURES_INIT_TAC ~seed_frame:true` to start from the permitted frame
instead. This requires a proof that the frame is reflexive; unsupported
frames fall back to the empty starter. Opted-in callers keep frame size
bounded while stepping through longer instruction sequences.

The RV32 NTT helper has focused regressions for specification parameters,
restoring scoped tactic options on success and failure, and preserving
hypotheses when folding the final output expressions. From the repository
root, inside the HOL Light cross shell, build and run them with:

```bash
unroll_test_dir="$(mktemp -d /tmp/mldsa-ntt-unroll-tests.XXXXXX)"
cd proofs/hol_light
riscv32/proofs/build-proof.sh \
  "$PWD/riscv32/proofs/mldsa_ntt_unroll_tests.ml" \
  "$HOLLIGHT_DIR/hol.sh" "$unroll_test_dir/ntt-unroll-tests.native"
OCAMLRUNPARAM=l=2000000000 "$unroll_test_dir/ntt-unroll-tests.native"
```

Require a zero exit status, the factory-regression success message and the
final `Running time` line. These focused checks do not prove the NTT itself;
the complete routine entries must also prove correctness and safety.

The ARM and x86 loops prepare their step and SIMD simplification tactics
once and reuse them after each instruction. The abbreviation helpers also
prepare the arithmetic conversion outside their per-fact callback. For
example, use `let step = ARM_STEPS_TAC exec and simplify =
SIMD_SIMPLIFY_TAC rules in MAP_EVERY (fun n -> step [n] THEN simplify)
numbers`, rather than preparing both tactics inside `fun n -> ...`.
Prepared conversions capture the basic rewrite rules in effect at that
point; prepare again if those rules or the arithmetic definitions change.

The NTT proofs use ordinary `SIMD_SIMPLIFY_ABBREV_TAC`, which rewrites the
whole context when it introduces arithmetic names. At the final
integer-closure goal, these proofs discard execution assumptions before
calling `REAL_INTEGER_TAC`, which does not consult them.

For final RV32 output folding, prepare one conversion from the final
context before splitting the 256 coefficient goals. Reuse its bounded
subterm proof cache across those goals. A different context requires a
new conversion: equal fact conclusions can have different hypotheses.
This shares the actual equality proofs for repeated expressions, rather
than caching construction of the conversion function.

## Interactive proof development

For interactive proof development, start the HOL Light server:

```bash
hol-server [port]  # default port is 2012
```

Then use the [HOL Light extension for VS Code](https://marketplace.visualstudio.com/items?itemName=monadius.hol-light-simple)
to connect and send commands interactively.

Alternatively, send commands using netcat:

```bash
echo '1+1;;' | nc -w 5 127.0.0.1 2012
```

## Routines covered

All routines listed below have been proven correct, memory-safe, and secret-independent in their timing, except for the matrix sampler `rej_uniform`, which is proven correct and memory-safe, and is variable-time by design (see [By design](#by-design-rejection-sampling-for-the-public-matrix-rej_uniform)). `rej_uniform_eta{2,4}` are proven correct, memory-safe, and secret-independent in timing: their event trace is a function of the public pointers and the reject pattern only, never of the accepted coefficient values (see [Constant-time rejection sampling](#constant-time-rejection-sampling-for-the-secret-vector-rej_uniform_eta24)).

### AArch64
- ML-DSA Arithmetic:
  * AArch64 forward NTT: [mldsa_ntt_aarch64_asm.S](aarch64/mldsa/mldsa_ntt_aarch64_asm.S)
  * AArch64 inverse NTT: [mldsa_intt_aarch64_asm.S](aarch64/mldsa/mldsa_intt_aarch64_asm.S)
  * AArch64 poly_caddq: [mldsa_poly_caddq_aarch64_asm.S](aarch64/mldsa/mldsa_poly_caddq_aarch64_asm.S)
  * AArch64 poly_chknorm: [mldsa_poly_chknorm_aarch64_asm.S](aarch64/mldsa/mldsa_poly_chknorm_aarch64_asm.S)
  * AArch64 poly_use_hint (l=5,7): [mldsa_poly_use_hint_32_aarch64_asm.S](aarch64/mldsa/mldsa_poly_use_hint_32_aarch64_asm.S)
  * AArch64 poly_use_hint (l=4): [mldsa_poly_use_hint_88_aarch64_asm.S](aarch64/mldsa/mldsa_poly_use_hint_88_aarch64_asm.S)
  * AArch64 poly_decompose (l=5,7): [mldsa_poly_decompose_32_aarch64_asm.S](aarch64/mldsa/mldsa_poly_decompose_32_aarch64_asm.S)
  * AArch64 poly_decompose (l=4): [mldsa_poly_decompose_88_aarch64_asm.S](aarch64/mldsa/mldsa_poly_decompose_88_aarch64_asm.S)
  * AArch64 polyz_unpack (l=4): [mldsa_polyz_unpack_17_aarch64_asm.S](aarch64/mldsa/mldsa_polyz_unpack_17_aarch64_asm.S)
  * AArch64 polyz_unpack (l=5,7): [mldsa_polyz_unpack_19_aarch64_asm.S](aarch64/mldsa/mldsa_polyz_unpack_19_aarch64_asm.S)
  * AArch64 pointwise multiplication: [mldsa_pointwise_montgomery_aarch64_asm.S](aarch64/mldsa/mldsa_pointwise_montgomery_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=4): [mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S](aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=5): [mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S](aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=7): [mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S](aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S)
  * AArch64 rejection sampling: [mldsa_rej_uniform_aarch64_asm.S](aarch64/mldsa/mldsa_rej_uniform_aarch64_asm.S)
  * AArch64 rejection sampling (eta=2): [mldsa_rej_uniform_eta2_aarch64_asm.S](aarch64/mldsa/mldsa_rej_uniform_eta2_aarch64_asm.S)
  * AArch64 rejection sampling (eta=4): [mldsa_rej_uniform_eta4_aarch64_asm.S](aarch64/mldsa/mldsa_rej_uniform_eta4_aarch64_asm.S)
- FIPS202:
  * Keccak-F1600 using lazy rotations[^HYBRID]: [keccak_f1600_x1_scalar_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x1_scalar_aarch64_asm.S)
  * Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x1_v84a_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x1_v84a_aarch64_asm.S)
  * 2-fold Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x2_v84a_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x2_v84a_aarch64_asm.S)
  * 'Hybrid' 4-fold Keccak-F1600 using scalar and v8-A Neon instructions: [keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm.S)
  * 'Triple hybrid' 4-fold Keccak-F1600 using scalar, v8-A Neon and v8.4-A+SHA3 Neon instructions: [keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S)



### x86_64
- ML-DSA Arithmetic:
  * x86_64 forward NTT: [mldsa_ntt_avx2_asm.S](x86_64/mldsa/mldsa_ntt_avx2_asm.S)
  * x86_64 inverse NTT: [mldsa_intt_avx2_asm.S](x86_64/mldsa/mldsa_intt_avx2_asm.S)
  * x86_64 poly_caddq: [mldsa_poly_caddq_avx2_asm.S](x86_64/mldsa/mldsa_poly_caddq_avx2_asm.S)
  * x86_64 NTT unpack: [mldsa_nttunpack_avx2_asm.S](x86_64/mldsa/mldsa_nttunpack_avx2_asm.S)
  * x86_64 pointwise multiplication: [mldsa_pointwise_avx2_asm.S](x86_64/mldsa/mldsa_pointwise_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=4): [mldsa_pointwise_acc_l4_avx2_asm.S](x86_64/mldsa/mldsa_pointwise_acc_l4_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=5): [mldsa_pointwise_acc_l5_avx2_asm.S](x86_64/mldsa/mldsa_pointwise_acc_l5_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=7): [mldsa_pointwise_acc_l7_avx2_asm.S](x86_64/mldsa/mldsa_pointwise_acc_l7_avx2_asm.S)
  * x86_64 poly_chknorm: [mldsa_poly_chknorm_avx2_asm.S](x86_64/mldsa/mldsa_poly_chknorm_avx2_asm.S)
  * x86_64 poly_decompose (l=5,7): [mldsa_poly_decompose_32_avx2_asm.S](x86_64/mldsa/mldsa_poly_decompose_32_avx2_asm.S)
  * x86_64 poly_decompose (l=4): [mldsa_poly_decompose_88_avx2_asm.S](x86_64/mldsa/mldsa_poly_decompose_88_avx2_asm.S)
  * x86_64 polyz_unpack (l=4): [mldsa_polyz_unpack_17_avx2_asm.S](x86_64/mldsa/mldsa_polyz_unpack_17_avx2_asm.S)
  * x86_64 polyz_unpack (l=5,7): [mldsa_polyz_unpack_19_avx2_asm.S](x86_64/mldsa/mldsa_polyz_unpack_19_avx2_asm.S)
  * x86_64 poly_use_hint (l=5,7): [mldsa_poly_use_hint_32_avx2_asm.S](x86_64/mldsa/mldsa_poly_use_hint_32_avx2_asm.S)
  * x86_64 poly_use_hint (l=4): [mldsa_poly_use_hint_88_avx2_asm.S](x86_64/mldsa/mldsa_poly_use_hint_88_avx2_asm.S)
  * x86_64 rejection uniform sampling: [mldsa_rej_uniform_avx2_asm.S](x86_64/mldsa/mldsa_rej_uniform_avx2_asm.S)
  * x86_64 rejection sampling (eta=2): [mldsa_rej_uniform_eta2_avx2_asm.S](x86_64/mldsa/mldsa_rej_uniform_eta2_avx2_asm.S)
  * x86_64 rejection sampling (eta=4): [mldsa_rej_uniform_eta4_avx2_asm.S](x86_64/mldsa/mldsa_rej_uniform_eta4_avx2_asm.S)
- FIPS202:
  * 4-fold Keccak-F1600 using AVX2: [keccak_f1600_x4_avx2_asm.S](x86_64/mldsa/keccak_f1600_x4_avx2_asm.S)

### RV32IM

- ML-DSA Arithmetic:
  * RV32IM forward NTT: [mldsa_ntt_rv32im_asm.S](riscv32/mldsa/mldsa_ntt_rv32im_asm.S)
  * RV32IM forward NTT for slow multipliers: [mldsa_ntt_rv32im_slowmul_asm.S](riscv32/mldsa/mldsa_ntt_rv32im_slowmul_asm.S)
  * RV32IM inverse NTT: [mldsa_intt_rv32im_asm.S](riscv32/mldsa/mldsa_intt_rv32im_asm.S)
  * RV32IM inverse NTT for slow multipliers: [mldsa_intt_rv32im_slowmul_asm.S](riscv32/mldsa/mldsa_intt_rv32im_slowmul_asm.S)
  * RV32IM pointwise multiplication: [mldsa_poly_pointwise_montgomery_rv32im_asm.S](riscv32/mldsa/mldsa_poly_pointwise_montgomery_rv32im_asm.S)

<!--- bibliography --->
[^HYBRID]: Becker, Kannwischer: Hybrid scalar/vector implementations of Keccak and SPHINCS+ on AArch64, [https://eprint.iacr.org/2022/1243](https://eprint.iacr.org/2022/1243)
[^Round3_Spec]: Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé: CRYSTALS-Dilithium Algorithm Specifications and Supporting Documentation (Version 3.1), [https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf)
