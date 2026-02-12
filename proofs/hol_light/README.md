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

- ML-DSA Arithmetic:
  * AArch64 poly_caddq: [mldsa_poly_caddq.S](aarch64/mldsa/mldsa_poly_caddq.S)
  * AArch64 poly_chknorm: [mldsa_poly_chknorm.S](aarch64/mldsa/mldsa_poly_chknorm.S)
  * x86_64 forward NTT: [mldsa_ntt.S](x86_64/mldsa/mldsa_ntt.S)
  * x86_64 inverse NTT: [mldsa_intt.S](x86_64/mldsa/mldsa_intt.S)
- FIPS202:
  * Keccak-F1600 using lazy rotations[^HYBRID]: [keccak_f1600_x1_scalar.S](aarch64/mldsa/keccak_f1600_x1_scalar.S)
  * Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x1_v84a.S](aarch64/mldsa/keccak_f1600_x1_v84a.S)
  * 2-fold Keccak-F1600 using v8.4-A SHA3 instructions: [keccak_f1600_x2_v84a.S](aarch64/mldsa/keccak_f1600_x2_v84a.S)
  * 'Hybrid' 4-fold Keccak-F1600 using scalar and v8-A Neon instructions: [keccak_f1600_x4_v8a_scalar.S](aarch64/mldsa/keccak_f1600_x4_v8a_scalar.S)
  * 'Triple hybrid' 4-fold Keccak-F1600 using scalar, v8-A Neon and v8.4-A+SHA3 Neon instructions: [keccak_f1600_x4_v8a_v84a_scalar.S](aarch64/mldsa/keccak_f1600_x4_v8a_v84a_scalar.S)



<!--- bibliography --->
[^HYBRID]: Becker, Kannwischer: Hybrid scalar/vector implementations of Keccak and SPHINCS+ on AArch64, [https://eprint.iacr.org/2022/1243](https://eprint.iacr.org/2022/1243)
