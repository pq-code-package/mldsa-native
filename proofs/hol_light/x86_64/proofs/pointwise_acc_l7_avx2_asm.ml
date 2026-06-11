(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Pointwise multiplication and accumulation of polynomials in ML-DSA NTT    *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_zetas.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_utils.ml";;

(*** print_literal_from_elf "x86_64/mldsa/pointwise_acc_l7_avx2_asm.o";;
 ***)

let mldsa_pointwise_acc_l7_mc = define_assert_from_elf "mldsa_pointwise_acc_l7_mc" "x86_64/mldsa/pointwise_acc_l7_avx2_asm.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0xc5; 0xfd; 0x6f; 0x41; 0x20;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rcx,32))) *)
  0xc5; 0xfd; 0x6f; 0x09;  (* VMOVDQA (%_% ymm1) (Memop Word256 (%% (rcx,0))) *)
  0x31; 0xc0;              (* XOR (% eax) (% eax) *)
  0xc5; 0xfd; 0x6f; 0x36;  (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,0))) *)
  0xc5; 0x7d; 0x6f; 0x46; 0x20;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,32))) *)
  0xc5; 0x7d; 0x6f; 0x12;  (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,0))) *)
  0xc5; 0x7d; 0x6f; 0x62; 0x20;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,32))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xfd; 0x6f; 0xd6;  (* VMOVDQA (%_% ymm2) (%_% ymm6) *)
  0xc5; 0xfd; 0x6f; 0xdf;  (* VMOVDQA (%_% ymm3) (%_% ymm7) *)
  0xc5; 0x7d; 0x7f; 0xc4;  (* VMOVDQA (%_% ymm4) (%_% ymm8) *)
  0xc5; 0x7d; 0x7f; 0xcd;  (* VMOVDQA (%_% ymm5) (%_% ymm9) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x04; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,1024))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x04; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,1056))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x04; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,1024))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x04; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,1056))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x08; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,2048))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x08; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,2080))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x08; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,2048))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x08; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,2080))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x0c; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,3072))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x0c; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,3104))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x0c; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,3072))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x0c; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,3104))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x10; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,4096))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x10; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,4128))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x10; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,4096))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x10; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,4128))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x14; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,5120))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x14; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,5152))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x14; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,5120))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x14; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,5152))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc5; 0xfd; 0x6f; 0xb6; 0x00; 0x18; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rsi,6144))) *)
  0xc5; 0x7d; 0x6f; 0x86; 0x20; 0x18; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm8) (Memop Word256 (%% (rsi,6176))) *)
  0xc5; 0x7d; 0x6f; 0x92; 0x00; 0x18; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rdx,6144))) *)
  0xc5; 0x7d; 0x6f; 0xa2; 0x20; 0x18; 0x00; 0x00;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rdx,6176))) *)
  0xc5; 0xc5; 0x73; 0xd6; 0x20;
                           (* VPSRLQ (%_% ymm7) (%_% ymm6) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x35; 0x73; 0xd0; 0x20;
                           (* VPSRLQ (%_% ymm9) (%_% ymm8) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm10) *)
  0xc4; 0xc2; 0x45; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm11) *)
  0xc4; 0x42; 0x3d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm8) (%_% ymm12) *)
  0xc4; 0x42; 0x35; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm9) (%_% ymm13) *)
  0xc5; 0xcd; 0xd4; 0xd2;  (* VPADDQ (%_% ymm2) (%_% ymm6) (%_% ymm2) *)
  0xc5; 0xc5; 0xd4; 0xdb;  (* VPADDQ (%_% ymm3) (%_% ymm7) (%_% ymm3) *)
  0xc5; 0xbd; 0xd4; 0xe4;  (* VPADDQ (%_% ymm4) (%_% ymm8) (%_% ymm4) *)
  0xc5; 0xb5; 0xd4; 0xed;  (* VPADDQ (%_% ymm5) (%_% ymm9) (%_% ymm5) *)
  0xc4; 0xe2; 0x7d; 0x28; 0xf2;
                           (* VPMULDQ (%_% ymm6) (%_% ymm0) (%_% ymm2) *)
  0xc4; 0xe2; 0x7d; 0x28; 0xfb;
                           (* VPMULDQ (%_% ymm7) (%_% ymm0) (%_% ymm3) *)
  0xc4; 0x62; 0x7d; 0x28; 0xc4;
                           (* VPMULDQ (%_% ymm8) (%_% ymm0) (%_% ymm4) *)
  0xc4; 0x62; 0x7d; 0x28; 0xcd;
                           (* VPMULDQ (%_% ymm9) (%_% ymm0) (%_% ymm5) *)
  0xc4; 0xe2; 0x75; 0x28; 0xf6;
                           (* VPMULDQ (%_% ymm6) (%_% ymm1) (%_% ymm6) *)
  0xc4; 0xe2; 0x75; 0x28; 0xff;
                           (* VPMULDQ (%_% ymm7) (%_% ymm1) (%_% ymm7) *)
  0xc4; 0x42; 0x75; 0x28; 0xc0;
                           (* VPMULDQ (%_% ymm8) (%_% ymm1) (%_% ymm8) *)
  0xc4; 0x42; 0x75; 0x28; 0xc9;
                           (* VPMULDQ (%_% ymm9) (%_% ymm1) (%_% ymm9) *)
  0xc5; 0xed; 0xfb; 0xd6;  (* VPSUBQ (%_% ymm2) (%_% ymm2) (%_% ymm6) *)
  0xc5; 0xe5; 0xfb; 0xdf;  (* VPSUBQ (%_% ymm3) (%_% ymm3) (%_% ymm7) *)
  0xc4; 0xc1; 0x5d; 0xfb; 0xe0;
                           (* VPSUBQ (%_% ymm4) (%_% ymm4) (%_% ymm8) *)
  0xc4; 0xc1; 0x55; 0xfb; 0xe9;
                           (* VPSUBQ (%_% ymm5) (%_% ymm5) (%_% ymm9) *)
  0xc5; 0xed; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm2) (%_% ymm2) (Imm8 (word 32)) *)
  0xc5; 0xfe; 0x16; 0xe4;  (* VMOVSHDUP (%_% ymm4) (%_% ymm4) *)
  0xc4; 0xe3; 0x6d; 0x02; 0xd3; 0xaa;
                           (* VPBLENDD (%_% ymm2) (%_% ymm2) (%_% ymm3) (Imm8 (word 170)) *)
  0xc4; 0xe3; 0x5d; 0x02; 0xe5; 0xaa;
                           (* VPBLENDD (%_% ymm4) (%_% ymm4) (%_% ymm5) (Imm8 (word 170)) *)
  0xc5; 0xfd; 0x7f; 0x17;  (* VMOVDQA (Memop Word256 (%% (rdi,0))) (%_% ymm2) *)
  0xc5; 0xfd; 0x7f; 0x67; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rdi,32))) (%_% ymm4) *)
  0x48; 0x83; 0xc6; 0x40;  (* ADD (% rsi) (Imm8 (word 64)) *)
  0x48; 0x83; 0xc2; 0x40;  (* ADD (% rdx) (Imm8 (word 64)) *)
  0x48; 0x83; 0xc7; 0x40;  (* ADD (% rdi) (Imm8 (word 64)) *)
  0x83; 0xc0; 0x01;        (* ADD (% eax) (Imm8 (word 1)) *)
  0x83; 0xf8; 0x10;        (* CMP (% eax) (Imm8 (word 16)) *)
  0x0f; 0x82; 0x2f; 0xfd; 0xff; 0xff;
                           (* JB (Imm32 (word 4294966575)) *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_pointwise_acc_l7_tmc = define_trimmed "mldsa_pointwise_acc_l7_tmc" mldsa_pointwise_acc_l7_mc;;
let MLDSA_POINTWISE_ACC_L7_TMC_EXEC = X86_MK_CORE_EXEC_RULE mldsa_pointwise_acc_l7_tmc;;

(* ========================================================================= *)
(* Correctness proof                                                         *)
(* ========================================================================= *)

let MLDSA_POINTWISE_ACC_L7_CORRECT = prove
 (`!c a b consts x y pc.
    aligned 32 c /\
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc, 0x2DD) (c, 1024) /\
    nonoverlapping (word pc, 0x2DD) (a, 7168) /\
    nonoverlapping (word pc, 0x2DD) (b, 7168) /\
    nonoverlapping (word pc, 0x2DD) (consts, 2496) /\
    nonoverlapping (c, 1024) (a, 7168) /\
    nonoverlapping (c, 1024) (b, 7168) /\
    nonoverlapping (c, 1024) (consts, 2496) /\
    nonoverlapping (a, 7168) (b, 7168) /\
    nonoverlapping (a, 7168) (consts, 2496) /\
    nonoverlapping (b, 7168) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) (BUTLAST mldsa_pointwise_acc_l7_tmc) /\
              read RIP s = word pc /\
              C_ARGUMENTS [c; a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 1792 ==> abs(ival(x i)) <= &8380416) /\
              (!i. i < 1792 ==> abs(ival(y i)) <= &94279697) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = word(pc + 0x2DC) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add c (word(4 * i)))) s in
                (ival zi == mldsa_pointwise_acc_l7 (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                      ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
           MAYCHANGE [RAX] ,, MAYCHANGE SOME_FLAGS ,,
           MAYCHANGE [memory :> bytes(c, 1024)])`,

  MAP_EVERY X_GEN_TAC
    [`c:int64`; `a:int64`; `b:int64`; `consts:int64`;
     `x:num->int32`; `y:num->int32`; `pc:num`] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS;
              NONOVERLAPPING_CLAUSES; ALL] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  GLOBALIZE_PRECONDITION_TAC THEN
  SUBGOAL_THEN
    `!i. i < 1792 ==> abs(ival((x:num->int32) i)) <= &94279697`
    ASSUME_TAC THENL
  [GEN_TAC THEN DISCH_TAC THEN
   MATCH_MP_TAC INT_LE_TRANS THEN EXISTS_TAC `&8380416:int` THEN
   CONJ_TAC THENL [ASM_MESON_TAC[]; CONV_TAC INT_REDUCE_CONV];
   ALL_TAC] THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(ONCE_DEPTH_CONV EXPAND_CASES_CONV))) THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT STRIP_TAC THEN
  REWRITE_TAC [SOME_FLAGS; fst MLDSA_POINTWISE_ACC_L7_TMC_EXEC] THEN

  GHOST_INTRO_TAC `init_ymm0:int256` `read YMM0` THEN
  GHOST_INTRO_TAC `init_ymm1:int256` `read YMM1` THEN
  GHOST_INTRO_TAC `init_ymm2:int256` `read YMM2` THEN
  GHOST_INTRO_TAC `init_ymm3:int256` `read YMM3` THEN
  GHOST_INTRO_TAC `init_ymm4:int256` `read YMM4` THEN
  GHOST_INTRO_TAC `init_ymm5:int256` `read YMM5` THEN
  GHOST_INTRO_TAC `init_ymm6:int256` `read YMM6` THEN
  GHOST_INTRO_TAC `init_ymm7:int256` `read YMM7` THEN
  GHOST_INTRO_TAC `init_ymm8:int256` `read YMM8` THEN
  GHOST_INTRO_TAC `init_ymm9:int256` `read YMM9` THEN
  GHOST_INTRO_TAC `init_ymm10:int256` `read YMM10` THEN
  GHOST_INTRO_TAC `init_ymm11:int256` `read YMM11` THEN
  GHOST_INTRO_TAC `init_ymm12:int256` `read YMM12` THEN
  GHOST_INTRO_TAC `init_ymm13:int256` `read YMM13` THEN
  GHOST_INTRO_TAC `init_ymm14:int256` `read YMM14` THEN
  GHOST_INTRO_TAC `init_ymm15:int256` `read YMM15` THEN

  MAP_EVERY (fun n ->
    let vname = "init_c" ^ string_of_int n in
    GHOST_INTRO_TAC (mk_var(vname, `:int256`))
      (subst[mk_small_numeral(32*n),`n:num`]
        `read (memory :> bytes256(word_add c (word n)))`))
    (0--31) THEN
  ENSURES_INIT_TAC "s0" THEN

  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add a (word n))) s0`)) (0--223))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add b (word n))) s0`)) (0--223))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 a) s = x`] THEN

  FIRST_X_ASSUM(MP_TAC o CONV_RULE (LAND_CONV WORDLIST_FROM_MEMORY_CONV)) THEN
  REWRITE_TAC[mldsa_complete_qdata; MAP; CONS_11] THEN
  STRIP_TAC THEN
  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add consts (word n))) s0`)) (0--1))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 consts) s = z`] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  SUBGOAL_THEN
   `!i. i < 1792 ==>
     abs(ival(word_mul (word_sx ((x:num->int32) i):int64)
                       (word_sx ((y:num->int32) i):int64))) <= &790103081213952`
   ASSUME_TAC THENL
  [REPEAT STRIP_TAC THEN
   MP_TAC(ISPECL [`(x:num->int32) i`; `(y:num->int32) i`] IVAL_WORD_MUL_SX32_64) THEN
   ANTS_TAC THENL
    [ASM_MESON_TAC[]; DISCH_THEN(fun th -> REWRITE_TAC[th])] THEN
   REWRITE_TAC[INT_ABS_MUL] THEN
   MATCH_MP_TAC INT_LE_TRANS THEN EXISTS_TAC `&8380416 * &94279697:int` THEN
   CONJ_TAC THENL
    [MATCH_MP_TAC INT_LE_MUL2 THEN REWRITE_TAC[INT_ABS_POS] THEN ASM_MESON_TAC[];
     CONV_TAC INT_REDUCE_CONV];
   ALL_TAC] THEN

  MAP_EVERY (fun n -> X86_STEPS_TAC MLDSA_POINTWISE_ACC_L7_TMC_EXEC [n] THEN
                      SIMD_SIMPLIFY_TAC[mldsa_pointwise_montred])
        (1--2179) THEN
  ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[] THEN

  REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
    CONV_RULE(READ_MEMORY_SPLIT_CONV 3) o
    check (can (term_match [] `read qqq s2179:int256 = xxx`) o concl))) THEN
  
  CONV_TAC(TOP_DEPTH_CONV EXPAND_CASES_CONV) THEN
  CONV_TAC(DEPTH_CONV NUM_MULT_CONV THENC DEPTH_CONV NUM_ADD_CONV) THEN
  REWRITE_TAC[WORD_ADD_0] THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  REWRITE_TAC[USHR32_SUBWORD; DUP32_SUBWORD] THEN
  REWRITE_TAC[Q_MUL_COMM; GSYM mldsa_pointwise_montred] THEN
  REWRITE_TAC[WORD_JOIN_SUBWORD] THEN

  W(fun (asl,w) ->
    let lfn = PROCESS_BOUND_ASSUMPTIONS
      (CONJUNCTS(tryfind (CONV_RULE EXPAND_CASES_CONV o snd) asl))
    in
    (* Pre-compute 1792 ival_mul theorems via ISPECL + assumption lookup *)
    let ival_mul_thms = Array.init 1792 (fun i ->
      let iterm = mk_small_numeral i in
      let xi = mk_comb(`x:num->int32`, iterm) in
      let yi = mk_comb(`y:num->int32`, iterm) in
      let th = ISPECL [xi; yi] IVAL_WORD_MUL_SX32_64 in
      let ante = lhand(concl th) in
      let ante_x, ante_y = dest_conj ante in
      let ilt = ARITH_RULE(mk_comb(mk_comb(`(<):num->num->bool`, iterm), `1792`)) in
      let prove_bound bt =
        tryfind (fun (_,ath) ->
          try let a' = SPEC iterm ath in
              let a'' = MP a' ilt in
              if aconv (concl a'') bt then a'' else failwith ""
          with _ -> failwith "") asl in
      MP th (CONJ (prove_bound ante_x) (prove_bound ante_y))) in
    (* Extract 256 coefficient pairs from the goal conjunction *)
    let rec pair_up = function
      | a :: b :: rest -> mk_conj(a,b) :: pair_up rest
      | [x] -> [x] | [] -> [] in
    let pairs = pair_up (conjuncts w) in
    (* Prove each pair independently *)
    let prove_pair idx pair =
      let mr = rand(lhand(rator(lhand pair))) in
      let cb_th = ASM_CONGBOUND_RULE lfn mr in
      let relevant_ival = map (fun k -> ival_mul_thms.(idx + 256 * k)) [0;1;2;3;4;5;6] in
      let (_,sgs,just) = (
        MP_TAC cb_th THEN
        MATCH_MP_TAC MONO_AND THEN CONJ_TAC THENL
         [REWRITE_TAC[INVERSE_MOD_CONV `inverse_mod 8380417 4294967296`] THEN
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] INT_CONG_TRANS) THEN
          REWRITE_TAC[GSYM INT_REM_EQ; o_THM; mldsa_pointwise_acc_l7;
                       INVERSE_MOD_CONV `inverse_mod 8380417 4294967296`] THEN
          CONV_TAC INT_REM_DOWN_CONV THEN
          CONV_TAC(DEPTH_CONV NUM_ADD_CONV) THEN
          REWRITE_TAC relevant_ival THEN
          CONV_TAC(DEPTH_CONV NUM_ADD_CONV) THEN
          AP_THM_TAC THEN AP_TERM_TAC THEN INT_ARITH_TAC;
          REWRITE_TAC[INT_ABS_BOUNDS] THEN
          MATCH_MP_TAC(INT_ARITH
           `l':int <= l /\ u <= u'
            ==> l <= x /\ x <= u ==> l' <= x /\ x <= u'`) THEN
          CONV_TAC INT_REDUCE_CONV]) (asl, pair) in
      if sgs <> [] then failwith ("prove_pair " ^ string_of_int idx)
      else just null_inst [] in
    let all_thms = List.map2 prove_pair (0--255) pairs in
    ACCEPT_TAC(end_itlist CONJ all_thms)));;

(* ========================================================================= *)
(* Subroutine form                                                           *)
(* ========================================================================= *)

let MLDSA_POINTWISE_ACC_L7_NOIBT_SUBROUTINE_CORRECT = prove
 (`!c a b consts x y pc stackpointer returnaddress.
    aligned 32 c /\
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_tmc) (c, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_tmc) (a, 7168) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_tmc) (b, 7168) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_tmc) (consts, 2496) /\
    nonoverlapping (c, 1024) (a, 7168) /\
    nonoverlapping (c, 1024) (b, 7168) /\
    nonoverlapping (c, 1024) (consts, 2496) /\
    nonoverlapping (a, 7168) (b, 7168) /\
    nonoverlapping (a, 7168) (consts, 2496) /\
    nonoverlapping (b, 7168) (consts, 2496) /\
    nonoverlapping (stackpointer, 8) (c, 1024) /\
    nonoverlapping (stackpointer, 8) (a, 7168) /\
    nonoverlapping (stackpointer, 8) (b, 7168) /\
    nonoverlapping (stackpointer, 8) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) mldsa_pointwise_acc_l7_tmc /\
              read RIP s = word pc /\
              read RSP s = stackpointer /\
              read (memory :> bytes64 stackpointer) s = returnaddress /\
              C_ARGUMENTS [c; a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 1792 ==> abs(ival(x i)) <= &8380416) /\
              (!i. i < 1792 ==> abs(ival(y i)) <= &94279697) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = returnaddress /\
              read RSP s = word_add stackpointer (word 8) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add c (word(4 * i)))) s in
                (ival zi == mldsa_pointwise_acc_l7 (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(c, 1024)])`,
  let TWEAK_CONV = ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV in
  CONV_TAC TWEAK_CONV THEN
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_pointwise_acc_l7_tmc
    (CONV_RULE TWEAK_CONV MLDSA_POINTWISE_ACC_L7_CORRECT));;

let MLDSA_POINTWISE_ACC_L7_SUBROUTINE_CORRECT = prove
 (`!c a b consts x y pc stackpointer returnaddress.
    aligned 32 c /\
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_mc) (c, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_mc) (a, 7168) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_mc) (b, 7168) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_acc_l7_mc) (consts, 2496) /\
    nonoverlapping (c, 1024) (a, 7168) /\
    nonoverlapping (c, 1024) (b, 7168) /\
    nonoverlapping (c, 1024) (consts, 2496) /\
    nonoverlapping (a, 7168) (b, 7168) /\
    nonoverlapping (a, 7168) (consts, 2496) /\
    nonoverlapping (b, 7168) (consts, 2496) /\
    nonoverlapping (stackpointer, 8) (c, 1024) /\
    nonoverlapping (stackpointer, 8) (a, 7168) /\
    nonoverlapping (stackpointer, 8) (b, 7168) /\
    nonoverlapping (stackpointer, 8) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) mldsa_pointwise_acc_l7_mc /\
              read RIP s = word pc /\
              read RSP s = stackpointer /\
              read (memory :> bytes64 stackpointer) s = returnaddress /\
              C_ARGUMENTS [c; a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 1792 ==> abs(ival(x i)) <= &8380416) /\
              (!i. i < 1792 ==> abs(ival(y i)) <= &94279697) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 1792 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = returnaddress /\
              read RSP s = word_add stackpointer (word 8) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add c (word(4 * i)))) s in
                (ival zi == mldsa_pointwise_acc_l7 (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(c, 1024)])`,
  let TWEAK_CONV = ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV in
  CONV_TAC TWEAK_CONV THEN
  MATCH_ACCEPT_TAC(ADD_IBT_RULE
    (CONV_RULE TWEAK_CONV MLDSA_POINTWISE_ACC_L7_NOIBT_SUBROUTINE_CORRECT)));;

(* ========================================================================= *)
(* Constant-time and memory safety proof.                                    *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/consttime.ml";;
needs "mldsa_native/x86_64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:true
    (assoc "mldsa_pointwise_acc_l7_x86" subroutine_signatures)
    MLDSA_POINTWISE_ACC_L7_CORRECT
    MLDSA_POINTWISE_ACC_L7_TMC_EXEC;;

let MLDSA_POINTWISE_ACC_L7_SAFE =
  REWRITE_RULE [MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS]
  (time prove
   (full_spec,
    REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS] THEN
    PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars
      MLDSA_POINTWISE_ACC_L7_TMC_EXEC));;

let MLDSA_POINTWISE_ACC_L7_NOIBT_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e c a b consts pc stackpointer returnaddress.
          aligned 32 c /\ aligned 32 a /\ aligned 32 b /\ aligned 32 consts /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_tmc) (c, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_tmc) (a, 7168) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_tmc) (b, 7168) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_tmc) (consts, 2496) /\
          nonoverlapping (c, 1024) (a, 7168) /\ nonoverlapping (c, 1024) (b, 7168) /\
          nonoverlapping (c, 1024) (consts, 2496) /\ nonoverlapping (a, 7168) (b, 7168) /\
          nonoverlapping (a, 7168) (consts, 2496) /\ nonoverlapping (b, 7168) (consts, 2496) /\
          nonoverlapping (stackpointer, 8) (c, 1024) /\
          nonoverlapping (stackpointer, 8) (a, 7168) /\
          nonoverlapping (stackpointer, 8) (b, 7168) /\
          nonoverlapping (stackpointer, 8) (consts, 2496)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) mldsa_pointwise_acc_l7_tmc /\
                    read RIP s = word pc /\
                    read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [c; a; b; consts] s /\
                    read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events c a b consts pc stackpointer returnaddress /\
                         memaccess_inbounds e2
                           [a,7168; b,7168; consts,2496; c,1024; stackpointer,8]
                           [c,1024; stackpointer,8]))
               (\s s'. true)`,
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_pointwise_acc_l7_tmc
    MLDSA_POINTWISE_ACC_L7_SAFE THEN
  DISCHARGE_SAFETY_PROPERTY_TAC);;

let MLDSA_POINTWISE_ACC_L7_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e c a b consts pc stackpointer returnaddress.
          aligned 32 c /\ aligned 32 a /\ aligned 32 b /\ aligned 32 consts /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_mc) (c, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_mc) (a, 7168) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_mc) (b, 7168) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_acc_l7_mc) (consts, 2496) /\
          nonoverlapping (c, 1024) (a, 7168) /\ nonoverlapping (c, 1024) (b, 7168) /\
          nonoverlapping (c, 1024) (consts, 2496) /\ nonoverlapping (a, 7168) (b, 7168) /\
          nonoverlapping (a, 7168) (consts, 2496) /\ nonoverlapping (b, 7168) (consts, 2496) /\
          nonoverlapping (stackpointer, 8) (c, 1024) /\
          nonoverlapping (stackpointer, 8) (a, 7168) /\
          nonoverlapping (stackpointer, 8) (b, 7168) /\
          nonoverlapping (stackpointer, 8) (consts, 2496)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) mldsa_pointwise_acc_l7_mc /\
                    read RIP s = word pc /\
                    read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [c; a; b; consts] s /\
                    read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events c a b consts pc stackpointer returnaddress /\
                         memaccess_inbounds e2
                           [a,7168; b,7168; consts,2496; c,1024; stackpointer,8]
                           [c,1024; stackpointer,8]))
               (\s s'. true)`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_POINTWISE_ACC_L7_NOIBT_SUBROUTINE_SAFE));;
