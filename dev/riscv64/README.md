[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# RISC-V Vector Extension Backend

This is an arithmetic backend for CPUs implementing the RISC-V Vector Extension. The backend is functional for all physical `VLEN`, but the NTT and inverse NTT are so far only implemented for VLEN=128 and VLEN=256, falling back to the default C implementations for other VLENs.

## Requirements

- RISC-V 64-bit architecture
- Vector extension (RVV) version 1.0, or Zve64x with VLEN=64
- Standard "gc" extensions (integer and compressed instructions)

## Implementation notes

- All routines are written in assembly in `dev/riscv64/src` and imported into `mldsa/src/native/riscv64/src` by `scripts/autogen` via `scripts/simpasm`. Compressed instructions and linker relaxation are disabled (`.option norvc`, `.option norelax`), so that the object code is fixed, as needed for formal verification.
- Multiplications by known constants (twiddles, scaling factors) use Barrett multiplication[^NeonNTT], based on `vsmul`. The routines set the fixed-point rounding mode `vxrm`, which is not preserved across calls. Multiplications of two variables use Montgomery multiplication, matching the C reference exactly.
- The NTT makes two passes over memory. Layers 1-4 load the coefficients with unit stride and use scalar twiddles on register groups of 8, 4, 2 and 1. Layers 5-8 load them with a stride of 16 coefficients, so that the butterfly partners of these layers are in different registers, and use per-lane twiddles. This avoids permutations within registers, which are costly on the SpacemiT X60 for register groups.
- The register group sizes (LMUL) were chosen by benchmarks on the SpacemiT X60 (VLEN=256). The pointwise multiplication, `poly_decompose` and `poly_use_hint` use LMUL=8, about 7% faster than LMUL=4; `poly_caddq` and `poly_chknorm` use LMUL=4, as LMUL=8 is slower. The pointwise multiplication with accumulation uses LMUL=4 for the inputs and LMUL=8 for the 64-bit accumulator, about 12% faster than LMUL=2. The NTT layers 5-8 use register groups of 4, 4, 2 and 1 with replicated twiddles, about 7% faster than LMUL=1. The eta rejection samplers use LMUL=2 for the nibbles, 16-24% faster than LMUL=1. Rejection sampling and `polyz_unpack` use LMUL=2: LMUL=4 is 50-65% slower because of the cost of `vrgatherei16` on large register groups, and LMUL=1 is slower for rejection sampling and does not divide into whole bytes for `polyz_unpack_17` at VLEN=64. Other microarchitectures may favor different choices.

<!--- bibliography --->
[^NeonNTT]: Becker, Hwang, Kannwischer, Yang, Yang: Neon NTT: Faster Dilithium, Kyber, and Saber on Cortex-A72 and Apple M1, [https://eprint.iacr.org/2021/986](https://eprint.iacr.org/2021/986)
