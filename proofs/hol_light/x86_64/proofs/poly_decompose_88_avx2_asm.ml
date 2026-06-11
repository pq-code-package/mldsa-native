(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Functional correctness of poly_decompose_88 (x86_64 AVX2):                *)
(* Decompose polynomial coefficients into (a1, a0) where                     *)
(* a mod^+ Q = a1*2*GAMMA2 + a0 for GAMMA2 = (Q-1)/88 = 95232               *)
(* (ML-DSA-44).                                                  *)
(*                                                                           *)
(* The high-bits quotient is computed with the AVX2 mulhi/mulhrs Barrett     *)
(* sequence (VPADDD/VPSRLD/VPMULHUW/VPMULHRSW), which differs from the       *)
(* AArch64 SQDMULH+SRSHR path but computes the same round-half-down          *)
(* quotient.                                                                 *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_utils.ml";;


(**** print_literal_from_elf "x86_64/mldsa/poly_decompose_88_avx2_asm.o";;
 ****)

let mldsa_decompose88_mc = define_assert_from_elf "mldsa_decompose88_mc" "x86_64/mldsa/poly_decompose_88_avx2_asm.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0xb8; 0x7f; 0x00; 0x00; 0x00;
                           (* MOV (% eax) (Imm32 (word 127)) *)
  0xc5; 0x79; 0x6e; 0xd0;  (* VMOVD (%_% xmm10) (% eax) *)
  0xc4; 0x42; 0x7d; 0x58; 0xd2;
                           (* VPBROADCASTD (%_% ymm10) (%_% xmm10) *)
  0xb8; 0x0b; 0x2c; 0x00; 0x00;
                           (* MOV (% eax) (Imm32 (word 11275)) *)
  0xc5; 0x79; 0x6e; 0xd8;  (* VMOVD (%_% xmm11) (% eax) *)
  0xc4; 0x42; 0x7d; 0x58; 0xdb;
                           (* VPBROADCASTD (%_% ymm11) (%_% xmm11) *)
  0xb8; 0x80; 0x00; 0x00; 0x00;
                           (* MOV (% eax) (Imm32 (word 128)) *)
  0xc5; 0x79; 0x6e; 0xe0;  (* VMOVD (%_% xmm12) (% eax) *)
  0xc4; 0x42; 0x7d; 0x58; 0xe4;
                           (* VPBROADCASTD (%_% ymm12) (%_% xmm12) *)
  0xb8; 0x00; 0x6c; 0x7e; 0x00;
                           (* MOV (% eax) (Imm32 (word 8285184)) *)
  0xc5; 0x79; 0x6e; 0xe8;  (* VMOVD (%_% xmm13) (% eax) *)
  0xc4; 0x42; 0x7d; 0x58; 0xed;
                           (* VPBROADCASTD (%_% ymm13) (%_% xmm13) *)
  0xb8; 0x00; 0xe8; 0x02; 0x00;
                           (* MOV (% eax) (Imm32 (word 190464)) *)
  0xc5; 0x79; 0x6e; 0xf0;  (* VMOVD (%_% xmm14) (% eax) *)
  0xc4; 0x42; 0x7d; 0x58; 0xf6;
                           (* VPBROADCASTD (%_% ymm14) (%_% xmm14) *)
  0xc5; 0xfd; 0x6f; 0x06;  (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,0))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x0f;  (* VMOVDQA (Memop Word256 (%% (rdi,0))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x16;  (* VMOVDQA (Memop Word256 (%% (rsi,0))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x46; 0x20;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,32))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x4f; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rdi,32))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x56; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rsi,32))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x46; 0x40;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,64))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x4f; 0x40;
                           (* VMOVDQA (Memop Word256 (%% (rdi,64))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x56; 0x40;
                           (* VMOVDQA (Memop Word256 (%% (rsi,64))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x46; 0x60;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,96))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x4f; 0x60;
                           (* VMOVDQA (Memop Word256 (%% (rdi,96))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x56; 0x60;
                           (* VMOVDQA (Memop Word256 (%% (rsi,96))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x80; 0x00; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,128))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x80; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,128))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x80; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,128))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xa0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,160))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xa0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,160))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xa0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,160))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xc0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,192))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xc0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,192))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xc0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,192))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xe0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,224))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xe0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,224))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xe0; 0x00; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,224))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x00; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,256))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x00; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,256))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x00; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,256))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x20; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,288))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x20; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,288))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x20; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,288))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x40; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,320))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x40; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,320))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x40; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,320))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x60; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,352))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x60; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,352))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x60; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,352))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x80; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,384))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x80; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,384))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x80; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,384))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xa0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,416))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xa0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,416))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xa0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,416))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xc0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,448))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xc0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,448))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xc0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,448))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xe0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,480))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xe0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,480))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xe0; 0x01; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,480))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x00; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,512))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x00; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,512))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x00; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,512))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x20; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,544))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x20; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,544))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x20; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,544))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x40; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,576))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x40; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,576))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x40; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,576))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x60; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,608))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x60; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,608))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x60; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,608))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x80; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,640))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x80; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,640))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x80; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,640))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xa0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,672))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xa0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,672))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xa0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,672))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xc0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,704))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xc0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,704))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xc0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,704))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xe0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,736))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xe0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,736))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xe0; 0x02; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,736))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x00; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,768))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x00; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,768))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x00; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,768))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x20; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,800))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x20; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,800))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x20; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,800))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x40; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,832))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x40; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,832))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x40; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,832))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x60; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,864))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x60; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,864))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x60; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,864))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0x80; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,896))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0x80; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,896))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0x80; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,896))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xa0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,928))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xa0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,928))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xa0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,928))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xc0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,960))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xc0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,960))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xc0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,960))) (%_% ymm2) *)
  0xc5; 0xfd; 0x6f; 0x86; 0xe0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rsi,992))) *)
  0xc4; 0xc1; 0x7d; 0xfe; 0xca;
                           (* VPADDD (%_% ymm1) (%_% ymm0) (%_% ymm10) *)
  0xc5; 0xf5; 0x72; 0xd1; 0x07;
                           (* VPSRLD (%_% ymm1) (%_% ymm1) (Imm8 (word 7)) *)
  0xc4; 0xc1; 0x75; 0xe4; 0xcb;
                           (* VPMULHUW (%_% ymm1) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0xc2; 0x75; 0x0b; 0xcc;
                           (* VPMULHRSW (%_% ymm1) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0xc1; 0x7d; 0x66; 0xdd;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm0) (%_% ymm13) *)
  0xc4; 0xc2; 0x75; 0x40; 0xd6;
                           (* VPMULLD (%_% ymm2) (%_% ymm1) (%_% ymm14) *)
  0xc5; 0xfd; 0xfa; 0xd2;  (* VPSUBD (%_% ymm2) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xe5; 0xdf; 0xc9;  (* VPANDN (%_% ymm1) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xed; 0xfe; 0xd3;  (* VPADDD (%_% ymm2) (%_% ymm2) (%_% ymm3) *)
  0xc5; 0xfd; 0x7f; 0x8f; 0xe0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rdi,992))) (%_% ymm1) *)
  0xc5; 0xfd; 0x7f; 0x96; 0xe0; 0x03; 0x00; 0x00;
                           (* VMOVDQA (Memop Word256 (%% (rsi,992))) (%_% ymm2) *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_decompose88_tmc = define_trimmed "mldsa_decompose88_tmc" mldsa_decompose88_mc;;
let MLDSA_DECOMPOSE88_EXEC = X86_MK_CORE_EXEC_RULE mldsa_decompose88_tmc;;

(* ========================================================================= *)
(* Word-level lane functions matching the AVX2 instruction sequence.         *)
(* ========================================================================= *)

(* High-bits quotient h, x86 mulhi/mulhrs path (matches VPMULHUW+VPMULHRSW).  *)
let decompose88_h = define
 `decompose88_h (y:int32) : int32 =
   word_join
    (word_subword
     (word_add
      (word_ushr
       (word_mul
        (word_sx
        (word_subword
         (word_mul
          (word_zx (word_subword (word_ushr (word_add y (word 127)) 7) (16,16):16 word):int32)
         (word 0:int32)) (16,16):16 word):int32)
       (word 0:int32)) 14)
      (word 1:int32)) (1,16):16 word)
    (word_subword
     (word_add
      (word_ushr
       (word_mul
        (word_sx
        (word_subword
         (word_mul
          (word_zx (word_subword (word_ushr (word_add y (word 127)) 7) (0,16):16 word):int32)
         (word 11275:int32)) (16,16):16 word):int32)
       (word 128:int32)) 14)
      (word 1:int32)) (1,16):16 word) :int32`;;

let decompose88_a1 = define
 `decompose88_a1 (y:int32) : int32 =
   word_and (word_not (if word_igt y (word 8285184) then word 4294967295 else word 0))
            (decompose88_h y)`;;

let decompose88_a0 = define
 `decompose88_a0 (y:int32) : int32 =
   word_add (word_sub y (word_mul (decompose88_h y) (word 190464)))
            (if word_igt y (word 8285184) then word 4294967295 else word 0)`;;

(* The unsigned high-16 multiply (VPMULHUW) on a sub-2^16 lane, specialized
   to the Barrett magic constant 11275 from the shared MULHI_LANE_GEN. *)
let MULHI_LANE = prove(
  `!t:int32. val t < 65536 ==>
     val(word_subword (word_mul (word_zx (word_subword t (0,16):16 word):int32)
                                (word 11275)) (16,16):16 word) =
     (val t * 11275) DIV 65536`,
  GEN_TAC THEN DISCH_TAC THEN MATCH_MP_TAC MULHI_LANE_GEN THEN
  ASM_REWRITE_TAC[] THEN ARITH_TAC);;

(* The high 16-bit lane of the VPMULHUW/VPMULHRSW chain is identically zero
   (the high subword of (x+127)>>7 is multiplied by zero). *)
let HI16_ZERO =
  let rhs = rand(concl decompose88_h) in
  let hi16 = rand(rator rhs) in
  prove(mk_eq(hi16, `word 0:16 word`),
    SUBGOAL_THEN `word_mul (word_zx (word_subword (word_ushr (word_add (y:int32) (word 127)) 7) (16,16):16 word):int32)
                     (word 0):int32 = word 0` SUBST1_TAC THENL
     [CONV_TAC WORD_RULE; ALL_TAC] THEN CONV_TAC WORD_REDUCE_CONV);;

(* Numerical form of decompose88_h: the nested mulhi/mulhrs floors. *)
let H_NUM = prove(
  `!x:int32. val x < 8380417 ==>
     val(decompose88_h x) =
     (((((val x + 127) DIV 128 * 11275) DIV 65536) * 128) DIV 16384 + 1) DIV 2`,
  GEN_TAC THEN DISCH_TAC THEN
  GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [decompose88_h] THEN
  REWRITE_TAC[HI16_ZERO] THEN
  REWRITE_TAC[VAL_WORD_JOIN; DIMINDEX_16; DIMINDEX_32; VAL_WORD_0; ADD_CLAUSES; MULT_CLAUSES] THEN
  ABBREV_TAC `m:16 word = word_subword (word_mul (word_zx (word_subword (word_ushr (word_add (x:int32) (word 127)) 7) (0,16):16 word):int32) (word 11275)) (16,16)` THEN
  SUBGOAL_THEN `val(m:16 word) = ((val(x:int32) + 127) DIV 128 * 11275) DIV 65536` ASSUME_TAC THENL
   [EXPAND_TAC "m" THEN
    MP_TAC(SPEC `word_ushr (word_add (x:int32) (word 127)) 7` MULHI_LANE) THEN
    ASM_SIMP_TAC[H_T] THEN ANTS_TAC THENL
     [ASM_SIMP_TAC[H_T] THEN MP_TAC(SPEC `x:int32` T_BOUND) THEN ASM_ARITH_TAC;
      DISCH_THEN SUBST1_TAC THEN ASM_SIMP_TAC[H_T]]; ALL_TAC] THEN
  SUBGOAL_THEN `val(m:16 word) < 11275` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[] THEN SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(65536 = 0)`] THEN
    MP_TAC(SPEC `x:int32` T_BOUND) THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[VAL_WORD_SUBWORD; VAL_WORD_ADD; VAL_WORD_USHR; VAL_WORD_MUL; VAL_WORD;
              DIMINDEX_16; DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN `val(word_sx (m:16 word):int32) = val m` SUBST1_TAC THENL
   [MATCH_MP_TAC VAL_SX_16_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `((val(x:int32) + 127) DIV 128 * 11275) DIV 65536 < 11275` ASSUME_TAC THENL
   [ASM_MESON_TAC[]; ALL_TAC] THEN
  ABBREV_TAC `q = ((val(x:int32) + 127) DIV 128 * 11275) DIV 65536` THEN
  SUBGOAL_THEN `(q * 128) MOD 4294967296 = q * 128` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(q * 128) DIV 16384 < 89` ASSUME_TAC THENL
   [SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(16384 = 0)`] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `((q * 128) DIV 16384 + 1) MOD 4294967296 = (q * 128) DIV 16384 + 1` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `((q * 128) DIV 16384 + 1) DIV 2 < 65536` ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `n < 65536 ==> n < 4294967296`]);;

(* Collapse the two trailing right-shift floors into one. *)
let ADD128_DIV = prove(
  `!c1. (c1 + 128) DIV 128 = c1 DIV 128 + 1`,
  GEN_TAC THEN SUBGOAL_THEN `c1 + 128 = c1 + 1 * 128` SUBST1_TAC THENL
   [ARITH_TAC; SIMP_TAC[DIV_MULT_ADD; ARITH_RULE `~(128 = 0)`]]);;

let DIVMUL_HELP = prove(`!a. (a * 128) DIV 16384 = a DIV 128`,
  GEN_TAC THEN REWRITE_TAC[ARITH_RULE `16384 = 128 * 128`] THEN
  GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [MULT_SYM] THEN
  ONCE_REWRITE_TAC[MULT_SYM] THEN
  SIMP_TAC[DIV_MULT2; ARITH_RULE `~(128 = 0)`]);;

let E_COLLAPSE = prove(
  `!c. ((((c * 11275) DIV 65536) * 128) DIV 16384 + 1) DIV 2 =
       ((c * 11275) DIV 65536 + 128) DIV 256`,
  GEN_TAC THEN REWRITE_TAC[DIVMUL_HELP; GSYM ADD128_DIV] THEN
  REWRITE_TAC[ARITH_RULE `256 = 128 * 2`; DIV_DIV]);;

(* Barrett-style correctness of the mulhi/mulhrs quotient. *)
let BARRETT_CORE = prove(
  `!c. c < 65473 ==> ((c * 11275) DIV 65536 + 128) DIV 256 = (c + 743) DIV 1488`,
  GEN_TAC THEN DISCH_TAC THEN
  ABBREV_TAC `c1 = (c * 11275) DIV 65536` THEN
  MP_TAC(SPECL [`c * 11275`; `65536`] DIVISION) THEN ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
  MATCH_MP_TAC DIV_BOUNDS_EQ THEN CONV_TAC NUM_REDUCE_CONV THEN
  MP_TAC(SPECL [`c + 743`; `1488`] DIVISION) THEN ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  ABBREV_TAC `q = (c + 743) DIV 1488` THEN
  ABBREV_TAC `t = (c + 743) MOD 1488` THEN STRIP_TAC THEN
  SUBGOAL_THEN `q <= 44` ASSUME_TAC THENL
   [SUBGOAL_THEN `q * 1488 <= c + 743` MP_TAC THENL [ASM_ARITH_TAC; ASM_ARITH_TAC]; ALL_TAC] THEN
  ASM_ARITH_TAC);;

(* round-half-down closed form. *)
let ROUND_CLOSED = prove(
  `!r. (if r MOD 190464 * 2 <= 190464 then r DIV 190464 else r DIV 190464 + 1) =
       (r + 95231) DIV 190464`,
  GEN_TAC THEN
  MP_TAC(SPECL [`r:num`; `190464`] DIVISION) THEN ANTS_TAC THENL [ARITH_TAC; STRIP_TAC] THEN
  ABBREV_TAC `q = r DIV 190464` THEN ABBREV_TAC `m = r MOD 190464` THEN
  COND_CASES_TAC THENL
   [SUBGOAL_THEN `(r + 95231) DIV 190464 = q` (fun th -> REWRITE_TAC[th]) THEN
    MATCH_MP_TAC DIV_UNIQ THEN EXISTS_TAC `m + 95231` THEN ASM_ARITH_TAC;
    SUBGOAL_THEN `95233 <= m` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `(r + 95231) DIV 190464 = q + 1` (fun th -> REWRITE_TAC[th]) THEN
    MATCH_MP_TAC DIV_UNIQ THEN EXISTS_TAC `m - 95233` THEN ASM_ARITH_TAC]);;

let C_TO_R = prove(
  `!r. (((r + 127) DIV 128) + 743) DIV 1488 = (r + 95231) DIV 190464`,
  GEN_TAC THEN
  SUBGOAL_THEN `(r + 127) DIV 128 + 743 = (r + 95231) DIV 128` SUBST1_TAC THENL
   [SUBGOAL_THEN `r + 95231 = (r + 127) + 743 * 128` SUBST1_TAC THENL
     [ARITH_TAC; SIMP_TAC[DIV_MULT_ADD; ARITH_RULE `~(128 = 0)`]]; ALL_TAC] THEN
  REWRITE_TAC[DIV_DIV] THEN REWRITE_TAC[ARITH_RULE `128 * 1488 = 190464`]);;

let H_ROUND = prove(
  `!r. r < 8380417 ==>
     (((((r + 127) DIV 128 * 11275) DIV 65536) * 128) DIV 16384 + 1) DIV 2 =
     (if r MOD 190464 * 2 <= 190464 then r DIV 190464 else r DIV 190464 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[E_COLLAPSE] THEN
  SUBGOAL_THEN `(r + 127) DIV 128 < 65473` ASSUME_TAC THENL
   [SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(128 = 0)`] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[BARRETT_CORE] THEN
  REWRITE_TAC[C_TO_R; ROUND_CLOSED]);;

(* Correctness of the high-bits quotient: same round-half-down form proven for
   AArch64 (h32), enabling reuse of the spec-connection lemmas below. *)
let H32_CORRECT = prove(
  `!x:int32. val x < 8380417 ==>
    val(decompose88_h x) = (if val x MOD 190464 * 2 <= 190464
                            then val x DIV 190464
                            else val x DIV 190464 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN ASM_SIMP_TAC[H_NUM] THEN ASM_SIMP_TAC[H_ROUND]);;

(* The wrap-around test in word form, specialized to the threshold 8285184
   from the shared IGT_BOUND_GEN. *)
let IGT_BOUND =
  GEN_ALL(MP (SPECL [`x:int32`; `8285184`] IGT_BOUND_GEN)
             (ARITH_RULE `8285184 < 2147483648`));;

(* a1 = 0 on wrap-around, else h. *)
let DECOMPOSE88_A1_CASES = prove(
  `!x:int32. decompose88_a1 x = if ival x > &8285184 then word 0 else decompose88_h x`,
  GEN_TAC THEN REWRITE_TAC[decompose88_a1; GSYM IGT_BOUND] THEN
  ABBREV_TAC `h = decompose88_h x` THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN BITBLAST_TAC);;

(* a0 subtracts one extra on wrap-around. *)
let DECOMPOSE88_A0_CASES = prove(
  `!x:int32. decompose88_a0 x =
     if ival x > &8285184
     then word_sub (word_sub x (word_mul (decompose88_h x) (word 190464))) (word 1)
     else word_sub x (word_mul (decompose88_h x) (word 190464))`,
  GEN_TAC THEN REWRITE_TAC[decompose88_a0; GSYM IGT_BOUND] THEN
  ABBREV_TAC `h = decompose88_h x` THEN
  SUBGOAL_THEN `word 4294967295:int32 = word_neg(word 1)` SUBST1_TAC THENL
   [CONV_TAC WORD_REDUCE_CONV; ALL_TAC] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_RULE);;

(* On wrap-around (val x > 87*GAMMA2) the rounding quotient is exactly 44. *)
let ROUND32_SPECIAL = prove(
  `!n. 8285184 < n /\ n < 8380417 ==>
    (if n MOD 190464 * 2 <= 190464 then n DIV 190464 else n DIV 190464 + 1) = 44`,
  REPEAT STRIP_TAC THEN
  ASM_CASES_TAC `n < 8380416` THENL
   [SUBGOAL_THEN `n DIV 190464 = 43` ASSUME_TAC THENL
     [MATCH_MP_TAC DIV_BOUNDS_EQ THEN CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
    COND_CASES_TAC THENL
     [MP_TAC(SPECL [`n:num`; `190464`] DIVISION) THEN ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_ARITH_TAC;
      REWRITE_TAC[]];
    SUBGOAL_THEN `n = 8380416` SUBST_ALL_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    CONV_TAC NUM_REDUCE_CONV]);;

let CMOD_ABS_BOUND_190464 = prove(
  `!n. abs(mldsa_cmod n 190464) <= &95232`,
  GEN_TAC THEN REWRITE_TAC[mldsa_cmod] THEN
  SUBGOAL_THEN `n MOD 190464 < 190464` MP_TAC THENL
   [SIMP_TAC[MOD_LT_EQ; ARITH_RULE `~(190464 = 0)`]; ALL_TAC] THEN
  SPEC_TAC(`n MOD 190464`, `m:num`) THEN GEN_TAC THEN DISCH_TAC THEN
  COND_CASES_TAC THEN
  REWRITE_TAC[INT_ABS; INT_POS; INT_OF_NUM_LE; INT_OF_NUM_SUB; INT_SUB_LE; INT_NEG_SUB] THEN
  ASM_ARITH_TAC);;

(* a1 lane computes the high bits FST(mldsa_decompose_88(val x)). *)
let DECOMPOSE88_A1_CORRECT = prove(
  `!x:int32. val x < 8380417
    ==> val(decompose88_a1 x) = FST(mldsa_decompose_88(val x))`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[DECOMPOSE88_A1_CASES; MLDSA_DECOMPOSE_88_EXPAND; LET_DEF; LET_END_DEF; FST] THEN
  COND_CASES_TAC THENL
   [REWRITE_TAC[VAL_WORD_0; FST] THEN
    SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    SUBGOAL_THEN `&(val(x:int32)):int > &8285184` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
    REWRITE_TAC[INT_OF_NUM_GT; GT] THEN DISCH_TAC THEN
    MP_TAC(SPEC `val(x:int32)` ROUND32_SPECIAL) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[FST];
    MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    COND_CASES_TAC THENL
     [SUBGOAL_THEN `val(x:int32) <= 8285184` ASSUME_TAC THENL
       [SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
        SUBGOAL_THEN `~(&(val(x:int32)):int > &8285184)` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[INT_GT; INT_NOT_LT; INT_OF_NUM_LE]; ALL_TAC] THEN
      SUBGOAL_THEN `~(val(x:int32) DIV 190464 = 44)` ASSUME_TAC THENL
       [DISCH_TAC THEN MP_TAC(SPECL [`val(x:int32)`; `190464`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[FST];
      SUBGOAL_THEN `val(x:int32) <= 8285184` ASSUME_TAC THENL
       [SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
        SUBGOAL_THEN `~(&(val(x:int32)):int > &8285184)` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[INT_GT; INT_NOT_LT; INT_OF_NUM_LE]; ALL_TAC] THEN
      SUBGOAL_THEN `~(val(x:int32) DIV 190464 + 1 = 44)` ASSUME_TAC THENL
       [REWRITE_TAC[ARITH_RULE `n + 1 = 44 <=> n = 43`] THEN DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `190464`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[FST]]]);;

(* a0 lane computes the low bits SND(mldsa_decompose_88(val x)). *)
let DECOMPOSE88_A0_CORRECT = prove(
  `!x:int32. val x < 8380417
    ==> ival(decompose88_a0 x) = SND(mldsa_decompose_88(val x))`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[DECOMPOSE88_A0_CASES; MLDSA_DECOMPOSE_88_EXPAND; LET_DEF; LET_END_DEF; SND] THEN
  SUBGOAL_THEN `word_sub x (word_mul (decompose88_h x) (word 190464)) : int32 =
    iword(ival x - ival(decompose88_h x) * &190464)` SUBST1_TAC THENL
   [CONV_TAC WORD_RULE; ALL_TAC] THEN
  SUBGOAL_THEN `ival(x:int32) = &(val x)` SUBST1_TAC THENL
   [MATCH_MP_TAC IVAL_EQ_VAL THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `ival(decompose88_h x:int32) = &(val(decompose88_h x))` SUBST1_TAC THENL
   [MATCH_MP_TAC IVAL_EQ_VAL THEN
    MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(190464 = 0)`] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[INT_OF_NUM_GT] THEN
  ABBREV_TAC `h = (if val(x:int32) MOD 190464 * 2 <= 190464
    then val x DIV 190464 else val x DIV 190464 + 1)` THEN
  SUBGOAL_THEN `&(val(x:int32)):int =
    &(val x DIV 190464) * &190464 + &(val x MOD 190464)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`val(x:int32)`; `190464`] DIVISION) THEN
    ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(MP_TAC o AP_TERM `int_of_num` o CONJUNCT1) THEN
    REWRITE_TAC[INT_OF_NUM_MUL; INT_OF_NUM_ADD]; ALL_TAC] THEN
  SUBGOAL_THEN `&(val(x:int32)) - &h * &190464 = mldsa_cmod (val x) 190464`
    ASSUME_TAC THENL
   [REWRITE_TAC[mldsa_cmod] THEN
    FIRST_X_ASSUM(MP_TAC o SYM o check (fun th ->
      fst(dest_cond(fst(dest_eq(concl th)))) =
        `val (x:int32) MOD 190464 * 2 <= 190464`)) THEN
    COND_CASES_TAC THENL
     [DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[] THEN INT_ARITH_TAC;
      DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[GSYM INT_OF_NUM_ADD;
        GSYM INT_OF_NUM_MUL] THEN INT_ARITH_TAC]; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  COND_CASES_TAC THENL
   [SUBGOAL_THEN `h = 44` SUBST1_TAC THENL
     [MP_TAC(SPEC `val(x:int32)` ROUND32_SPECIAL) THEN
      ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN ASM_MESON_TAC[]; ALL_TAC] THEN
    REWRITE_TAC[SND] THEN
    SUBGOAL_THEN `word_sub (iword(mldsa_cmod (val(x:int32)) 190464)) (word 1) : int32 =
      iword(mldsa_cmod (val x) 190464 - &1)` SUBST1_TAC THENL
     [REWRITE_TAC[GSYM IWORD_INT_SUB; WORD_IWORD]; ALL_TAC] THEN
    MATCH_MP_TAC(INST_TYPE [`:32`,`:N`] IVAL_IWORD) THEN
    REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(SPEC `val(x:int32)` CMOD_ABS_BOUND_190464) THEN INT_ARITH_TAC;
    SUBGOAL_THEN `~(h = 44)` ASSUME_TAC THENL
     [DISCH_TAC THEN
      SUBGOAL_THEN `val(x:int32) <= 8285184` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `(if val(x:int32) MOD 190464 * 2 <= 190464
        then val x DIV 190464 else val x DIV 190464 + 1) = 44` MP_TAC THENL
       [ASM_MESON_TAC[]; ALL_TAC] THEN
      COND_CASES_TAC THENL
       [DISCH_TAC THEN MP_TAC(SPECL [`val(x:int32)`; `190464`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_ARITH_TAC;
        REWRITE_TAC[ARITH_RULE `n + 1 = 44 <=> n = 43`] THEN DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `190464`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_ARITH_TAC]; ALL_TAC] THEN
    ASM_REWRITE_TAC[SND] THEN
    MATCH_MP_TAC(INST_TYPE [`:32`,`:N`] IVAL_IWORD) THEN
    REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(SPEC `val(x:int32)` CMOD_ABS_BOUND_190464) THEN INT_ARITH_TAC]);;

(* Range bounds on the lane outputs, phrased on the word-level lane functions
   so the main proof can discharge the CBMC-contract bounds uniformly. *)
let DECOMPOSE88_A1_BOUND_LEMMA = prove(
  `!x:int32. val x < 8380417 ==> val(decompose88_a1 x) <= 43`,
  GEN_TAC THEN DISCH_TAC THEN
  ASM_SIMP_TAC[DECOMPOSE88_A1_CORRECT; MLDSA_DECOMPOSE_88_A1_BOUND]);;

let DECOMPOSE88_A0_BOUND_LO = prove(
  `!x:int32. val x < 8380417 ==> --(&95232) <= ival(decompose88_a0 x)`,
  GEN_TAC THEN DISCH_TAC THEN
  ASM_SIMP_TAC[DECOMPOSE88_A0_CORRECT] THEN
  MP_TAC(SPEC `val(x:int32)` MLDSA_DECOMPOSE_88_A0_BOUND) THEN ASM_REWRITE_TAC[] THEN INT_ARITH_TAC);;

let DECOMPOSE88_A0_BOUND_HI = prove(
  `!x:int32. val x < 8380417 ==> ival(decompose88_a0 x) <= &95232`,
  GEN_TAC THEN DISCH_TAC THEN
  ASM_SIMP_TAC[DECOMPOSE88_A0_CORRECT] THEN
  MP_TAC(SPEC `val(x:int32)` MLDSA_DECOMPOSE_88_A0_BOUND) THEN ASM_REWRITE_TAC[] THEN INT_ARITH_TAC);;

(* ========================================================================= *)
(* Core correctness theorem                                                  *)
(* ========================================================================= *)

let MLDSA_DECOMPOSE88_CORRECT = prove(
 `!a1 a (x:num->int32) pc.
        ALL (nonoverlapping (word pc, 2144))
            [(a1,1024); (a,1024)] /\
        nonoverlapping (a1,1024) (a,1024) /\
        aligned 32 a1 /\ aligned 32 a
        ==> ensures x86
             (\s. bytes_loaded s (word pc) (BUTLAST mldsa_decompose88_tmc) /\
                  read RIP s = word pc /\
                  C_ARGUMENTS [a1; a] s /\
                  (!i. i < 256 ==>
                     read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> val(x i:int32) < 8380417))
             (\s. read RIP s = word(pc + 2143) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) =
                           FST(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> ival(read(memory :> bytes32(word_add a (word(4*i)))) s) =
                           SND(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) <= 43) /\
                  (!i. i < 256
                       ==> --(&95232) <=
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) /\
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) <= &95232))
             (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(a1,1024)] ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  MAP_EVERY X_GEN_TAC [`a1:int64`; `a:int64`; `x:num->int32`; `pc:num`] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS; ALL;
              NONOVERLAPPING_CLAUSES; fst MLDSA_DECOMPOSE88_EXEC] THEN
  STRIP_TAC THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(ONCE_DEPTH_CONV
    (EXPAND_CASES_CONV THENC ONCE_DEPTH_CONV NUM_MULT_CONV)))) THEN
  ENSURES_INIT_TAC "s0" THEN
  MP_TAC(end_itlist CONJ
    (map (fun n -> READ_MEMORY_MERGE_CONV 3
                     (subst[mk_small_numeral(32*n),`n:num`]
                           `read (memory :> bytes256(word_add a (word n))) s0`))
         (0--31))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 a) s = x`] THEN
  STRIP_TAC THEN
  MAP_EVERY (fun n ->
    X86_STEPS_TAC MLDSA_DECOMPOSE88_EXEC [n] THEN
    SIMD_SIMPLIFY_TAC[decompose88_a1; decompose88_a0]) (1--399) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_NOT_JOIN_256; WORD_NOT_JOIN_128; WORD_NOT_JOIN_64]) THEN
  REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
     CONV_RULE(SIMD_SIMPLIFY_CONV[decompose88_h; decompose88_a1; decompose88_a0]) o
     CONV_RULE(READ_MEMORY_SPLIT_CONV 3) o
     check (can (term_match [] `read (memory :> bytes256 zzz) s399 = xxx`) o concl))) THEN
  CONV_TAC(ONCE_DEPTH_CONV EXPAND_CASES_CONV THENC ONCE_DEPTH_CONV NUM_MULT_CONV) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  REPEAT CONJ_TAC THEN
  FIRST (map (fun th -> MATCH_MP_TAC th THEN FIRST_ASSUM ACCEPT_TAC)
     [DECOMPOSE88_A1_CORRECT; DECOMPOSE88_A0_CORRECT;
      DECOMPOSE88_A1_BOUND_LEMMA; DECOMPOSE88_A0_BOUND_LO;
      DECOMPOSE88_A0_BOUND_HI]));;

(* ========================================================================= *)
(* Subroutine form with return, bounds matching the CBMC contract.           *)
(* This must be kept in sync with the CBMC specification in                  *)
(* mldsa/src/native/x86_64/src/arith_native_x86_64.h                         *)
(* ========================================================================= *)

let MLDSA_DECOMPOSE88_NOIBT_SUBROUTINE_CORRECT = prove(
 `!a1 a (x:num->int32) pc stackpointer returnaddress.
        aligned 32 a1 /\ aligned 32 a /\
        ALL (nonoverlapping (word pc, LENGTH mldsa_decompose88_tmc))
            [(a1,1024); (a,1024)] /\
        nonoverlapping (a1,1024) (a,1024) /\
        nonoverlapping (stackpointer,8) (a1,1024) /\
        nonoverlapping (stackpointer,8) (a,1024)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_decompose88_tmc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [a1; a] s /\
                  (!i. i < 256
                       ==> read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> val(x i:int32) < 8380417))
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) =
                           FST(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> ival(read(memory :> bytes32(word_add a (word(4*i)))) s) =
                           SND(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) <= 43) /\
                  (!i. i < 256
                       ==> --(&95232) <=
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) /\
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) <= &95232))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(a1,1024)] ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_decompose88_tmc MLDSA_DECOMPOSE88_CORRECT);;

let MLDSA_DECOMPOSE88_SUBROUTINE_CORRECT = prove(
 `!a1 a (x:num->int32) pc stackpointer returnaddress.
        aligned 32 a1 /\ aligned 32 a /\
        ALL (nonoverlapping (word pc, LENGTH mldsa_decompose88_mc))
            [(a1,1024); (a,1024)] /\
        nonoverlapping (a1,1024) (a,1024) /\
        nonoverlapping (stackpointer,8) (a1,1024) /\
        nonoverlapping (stackpointer,8) (a,1024)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_decompose88_mc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [a1; a] s /\
                  (!i. i < 256
                       ==> read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> val(x i:int32) < 8380417))
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) =
                           FST(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> ival(read(memory :> bytes32(word_add a (word(4*i)))) s) =
                           SND(mldsa_decompose_88(val(x i)))) /\
                  (!i. i < 256
                       ==> val(read(memory :> bytes32(word_add a1 (word(4*i)))) s) <= 43) /\
                  (!i. i < 256
                       ==> --(&95232) <=
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) /\
                           ival(read(memory :> bytes32(word_add a (word(4*i)))) s) <= &95232))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(a1,1024)] ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_DECOMPOSE88_NOIBT_SUBROUTINE_CORRECT));;

(* ========================================================================= *)
(* Memory safety.                                                            *)
(* Decompose has no data-dependent control flow or memory accesses, so the   *)
(* memory-safety property is proven directly from the correctness spec.      *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/consttime.ml";;
needs "mldsa_native/x86_64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:true
    (assoc "mldsa_poly_decompose_88_x86" subroutine_signatures)
    (REWRITE_RULE[SOME_FLAGS] MLDSA_DECOMPOSE88_CORRECT)
    MLDSA_DECOMPOSE88_EXEC;;

let MLDSA_DECOMPOSE88_SAFE =
  REWRITE_RULE [MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS]
  (time prove
   (full_spec,
    REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS] THEN
    PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars
      MLDSA_DECOMPOSE88_EXEC));;

let MLDSA_DECOMPOSE88_NOIBT_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a1 a pc stackpointer returnaddress.
          aligned 32 a1 /\ aligned 32 a /\
          ALL (nonoverlapping (word pc, LENGTH mldsa_decompose88_tmc))
              [(a1,1024); (a,1024)] /\
          nonoverlapping (a1,1024) (a,1024) /\
          nonoverlapping (stackpointer,8) (a1,1024) /\
          nonoverlapping (stackpointer,8) (a,1024)
          ==> ensures x86
               (\s.
                    bytes_loaded s (word pc) mldsa_decompose88_tmc /\
                    read RIP s = word pc /\
                    read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [a1; a] s /\
                    read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events a1 a pc stackpointer returnaddress /\
                         memaccess_inbounds e2 [a,1024; a1,1024; a,1024; stackpointer,8]
                                               [a1,1024; a,1024; stackpointer,8]))
               (\s s'. true)`,
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_decompose88_tmc MLDSA_DECOMPOSE88_SAFE THEN
  DISCHARGE_SAFETY_PROPERTY_TAC);;

let MLDSA_DECOMPOSE88_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a1 a pc stackpointer returnaddress.
          aligned 32 a1 /\ aligned 32 a /\
          ALL (nonoverlapping (word pc, LENGTH mldsa_decompose88_mc))
              [(a1,1024); (a,1024)] /\
          nonoverlapping (a1,1024) (a,1024) /\
          nonoverlapping (stackpointer,8) (a1,1024) /\
          nonoverlapping (stackpointer,8) (a,1024)
          ==> ensures x86
               (\s.
                    bytes_loaded s (word pc) mldsa_decompose88_mc /\
                    read RIP s = word pc /\
                    read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [a1; a] s /\
                    read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events a1 a pc stackpointer returnaddress /\
                         memaccess_inbounds e2 [a,1024; a1,1024; a,1024; stackpointer,8]
                                               [a1,1024; a,1024; stackpointer,8]))
               (\s s'. true)`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_DECOMPOSE88_NOIBT_SUBROUTINE_SAFE));;
