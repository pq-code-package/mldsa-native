[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# HOL Light functional correctness proofs

This directory contains functional correctness proofs for AArch64 and x86_64 assembly routines
used in mldsa-native. The proofs are written in the [HOL Light](https://hol-light.github.io/) theorem
prover, utilizing the assembly verification infrastructure from [s2n-bignum](https://github.com/awslabs/s2n-bignum).

Each function is proved in a separate `.ml` file in [aarch64/proofs/](aarch64/proofs) and [x86_64/proofs/](x86_64/proofs). Each file
contains the byte code being verified, as well as the specification that is being proved.

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
  * x86_64 NTT unpack: [nttunpack_avx2_asm.S](x86_64/mldsa/nttunpack_avx2_asm.S)
  * x86_64 pointwise multiplication: [pointwise_avx2_asm.S](x86_64/mldsa/pointwise_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=4): [pointwise_acc_l4_avx2_asm.S](x86_64/mldsa/pointwise_acc_l4_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=5): [pointwise_acc_l5_avx2_asm.S](x86_64/mldsa/pointwise_acc_l5_avx2_asm.S)
  * x86_64 pointwise multiplication-accumulation (l=7): [pointwise_acc_l7_avx2_asm.S](x86_64/mldsa/pointwise_acc_l7_avx2_asm.S)
- FIPS202:
  * 4-fold Keccak-F1600 using AVX2: [keccak_f1600_x4_avx2_asm.S](x86_64/mldsa/keccak_f1600_x4_avx2_asm.S)

<!--- bibliography --->
[^HYBRID]: Becker, Kannwischer: Hybrid scalar/vector implementations of Keccak and SPHINCS+ on AArch64, [https://eprint.iacr.org/2022/1243](https://eprint.iacr.org/2022/1243)
