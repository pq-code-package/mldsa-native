[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# HOL Light functional correctness proofs

This directory contains functional correctness proofs for AArch64 and x86_64 assembly routines
used in mldsa-native. The proofs are written in the [HOL Light](https://hol-light.github.io/) theorem
prover, utilizing the assembly verification infrastructure from [s2n-bignum](https://github.com/awslabs/s2n-bignum).

Each function is proved in a separate `.ml` file in [aarch64/proofs/](aarch64/proofs) and [x86_64/proofs/](x86_64/proofs). Each file
contains the byte code being verified, as well as the specification that is being proved.

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

will build and run the proofs. Note that this may take hours even on powerful machines.

For convenience, you can also use `tests hol_light` which wraps the `make` invocation above; see `tests hol_light --help`.

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

## What is covered?

### AArch64
- ML-DSA Arithmetic:
  * AArch64 forward NTT: [ntt_aarch64_asm.S](aarch64/mldsa/ntt_aarch64_asm.S)
  * AArch64 inverse NTT: [intt_aarch64_asm.S](aarch64/mldsa/intt_aarch64_asm.S)
  * AArch64 poly_caddq: [poly_caddq_aarch64_asm.S](aarch64/mldsa/poly_caddq_aarch64_asm.S)
  * AArch64 poly_chknorm: [poly_chknorm_aarch64_asm.S](aarch64/mldsa/poly_chknorm_aarch64_asm.S)
  * AArch64 poly_use_hint (l=5,7): [poly_use_hint_32_aarch64_asm.S](aarch64/mldsa/poly_use_hint_32_aarch64_asm.S)
  * AArch64 poly_use_hint (l=4): [poly_use_hint_88_aarch64_asm.S](aarch64/mldsa/poly_use_hint_88_aarch64_asm.S)
  * AArch64 poly_decompose (l=5,7): [poly_decompose_32_aarch64_asm.S](aarch64/mldsa/poly_decompose_32_aarch64_asm.S)
  * AArch64 poly_decompose (l=4): [poly_decompose_88_aarch64_asm.S](aarch64/mldsa/poly_decompose_88_aarch64_asm.S)
  * AArch64 pointwise multiplication: [pointwise_montgomery_aarch64_asm.S](aarch64/mldsa/pointwise_montgomery_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=4): [mld_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S](aarch64/mldsa/mld_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=5): [mld_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S](aarch64/mldsa/mld_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.S)
  * AArch64 pointwise multiplication-accumulation (l=7): [mld_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S](aarch64/mldsa/mld_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.S)
  * AArch64 rejection sampling: [rej_uniform_aarch64_asm.S](aarch64/mldsa/rej_uniform_aarch64_asm.S)
  * AArch64 rejection sampling (eta=2): [rej_uniform_eta2_aarch64_asm.S](aarch64/mldsa/rej_uniform_eta2_aarch64_asm.S)
  * AArch64 rejection sampling (eta=4): [rej_uniform_eta4_aarch64_asm.S](aarch64/mldsa/rej_uniform_eta4_aarch64_asm.S)
- FIPS202:
  * Keccak-F1600 using lazy rotations[^HYBRID]: [keccak_f1600_x1_scalar_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x1_scalar_aarch64_asm.S)
  * Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x1_v84a_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x1_v84a_aarch64_asm.S)
  * 2-fold Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x2_v84a_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x2_v84a_aarch64_asm.S)
  * 'Hybrid' 4-fold Keccak-F1600 using scalar and v8-A Neon instructions: [keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm.S)
  * 'Triple hybrid' 4-fold Keccak-F1600 using scalar, v8-A Neon and v8.4-A+SHA3 Neon instructions: [keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S](aarch64/mldsa/keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.S)



### x86_64
- ML-DSA Arithmetic:
  * x86_64 forward NTT: [ntt_avx2_asm.S](x86_64/mldsa/ntt_avx2_asm.S)
  * x86_64 inverse NTT: [intt_avx2_asm.S](x86_64/mldsa/intt_avx2_asm.S)
  * x86_64 poly_caddq: [poly_caddq_avx2_asm.S](x86_64/mldsa/poly_caddq_avx2_asm.S)
  * x86_64 NTT unpack: [nttunpack_avx2_asm.S](x86_64/mldsa/nttunpack_avx2_asm.S)
  * x86_64 pointwise multiplication: [pointwise_avx2_asm.S](x86_64/mldsa/pointwise_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=4): [pointwise_acc_l4_avx2_asm.S](x86_64/mldsa/pointwise_acc_l4_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=5): [pointwise_acc_l5_avx2_asm.S](x86_64/mldsa/pointwise_acc_l5_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=7): [pointwise_acc_l7_avx2_asm.S](x86_64/mldsa/pointwise_acc_l7_avx2_asm.S)
- FIPS202:
  * 4-fold Keccak-F1600 using AVX2: [keccak_f1600_x4_avx2_asm.S](x86_64/mldsa/keccak_f1600_x4_avx2_asm.S)

<!--- bibliography --->
[^HYBRID]: Becker, Kannwischer: Hybrid scalar/vector implementations of Keccak and SPHINCS+ on AArch64, [https://eprint.iacr.org/2022/1243](https://eprint.iacr.org/2022/1243)
