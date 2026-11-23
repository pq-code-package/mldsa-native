(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* ML-DSA Rejection uniform sampling for eta=2 (x86_64 AVX2).                *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_utils.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_table.ml";;

(* Make silent type-variable invention an error (avoids nondeterministic     *)
(* "seqapply: Length mismatch" failures from fresh tyvars across subgoals).  *)
type_invention_error := true;;

let mldsa_rej_uniform_eta2_mc = define_assert_from_elf
  "mldsa_rej_uniform_eta2_mc" "x86_64/mldsa/mldsa_rej_uniform_eta2_avx2_asm.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0x41; 0xb8; 0x0f; 0x0f; 0x0f; 0x0f;
                           (* MOV (% r8d) (Imm32 (word 252645135)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xd8;
                           (* VMOVD (%_% xmm3) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xdb;
                           (* VPBROADCASTD (%_% ymm3) (%_% xmm3) *)
  0x41; 0xb8; 0x02; 0x02; 0x02; 0x02;
                           (* MOV (% r8d) (Imm32 (word 33686018)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xe0;
                           (* VMOVD (%_% xmm4) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xe4;
                           (* VPBROADCASTD (%_% ymm4) (%_% xmm4) *)
  0x41; 0xb8; 0x0f; 0x0f; 0x0f; 0x0f;
                           (* MOV (% r8d) (Imm32 (word 252645135)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xe8;
                           (* VMOVD (%_% xmm5) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xed;
                           (* VPBROADCASTD (%_% ymm5) (%_% xmm5) *)
  0x41; 0xb8; 0x60; 0xe6; 0xff; 0xff;
                           (* MOV (% r8d) (Imm32 (word 4294960736)) *)
  0xc4; 0xc1; 0x49; 0xc4; 0xf0; 0x00;
                           (* VPINSRW (%_% xmm6) (%_% xmm6) (% r8d) (Imm8 (word 0)) *)
  0xc4; 0xe2; 0x7d; 0x79; 0xf6;
                           (* VPBROADCASTW (%_% ymm6) (%_% xmm6) *)
  0x41; 0xb8; 0x05; 0x00; 0x00; 0x00;
                           (* MOV (% r8d) (Imm32 (word 5)) *)
  0xc4; 0xc1; 0x41; 0xc4; 0xf8; 0x00;
                           (* VPINSRW (%_% xmm7) (%_% xmm7) (% r8d) (Imm8 (word 0)) *)
  0xc4; 0xe2; 0x7d; 0x79; 0xff;
                           (* VPBROADCASTW (%_% ymm7) (%_% xmm7) *)
  0x31; 0xc0;              (* XOR (% eax) (% eax) *)
  0x31; 0xc9;              (* XOR (% ecx) (% ecx) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x0f; 0x87; 0x2e; 0x01; 0x00; 0x00;
                           (* JA (Imm32 (word 302)) *)
  0x83; 0xf9; 0x78;        (* CMP (% ecx) (Imm8 (word 120)) *)
  0x0f; 0x87; 0x25; 0x01; 0x00; 0x00;
                           (* JA (Imm32 (word 293)) *)
  0xc4; 0xe2; 0x7d; 0x30; 0x04; 0x0e;
                           (* VPMOVZXBW (%_% ymm0) (Memop Word128 (%%% (rsi,0,rcx))) *)
  0xc5; 0xf5; 0x71; 0xf0; 0x04;
                           (* VPSLLW (%_% ymm1) (%_% ymm0) (Imm8 (word 4)) *)
  0xc5; 0xfd; 0xeb; 0xc1;  (* VPOR (%_% ymm0) (%_% ymm0) (%_% ymm1) *)
  0xc5; 0xfd; 0xdb; 0xc3;  (* VPAND (%_% ymm0) (%_% ymm0) (%_% ymm3) *)
  0xc5; 0xfd; 0xf8; 0xcd;  (* VPSUBB (%_% ymm1) (%_% ymm0) (%_% ymm5) *)
  0xc5; 0xdd; 0xf8; 0xc0;  (* VPSUBB (%_% ymm0) (%_% ymm4) (%_% ymm0) *)
  0xc5; 0x7d; 0xd7; 0xc1;  (* VPMOVMSKB (% r8d) (%_% ymm1) *)
  0xc4; 0xc3; 0x7d; 0x39; 0xc0; 0x00;
                           (* VEXTRACTI128 (%_% xmm8) (%_% ymm0) (Imm8 (word 0)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0x21; 0x7a; 0x7e; 0x0c; 0xd2;
                           (* VMOVQ (%_% xmm9) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0x42; 0x39; 0x00; 0xc9;
                           (* VPSHUFB (%_% xmm9) (%_% xmm8) (%_% xmm9) *)
  0xc4; 0xc2; 0x7d; 0x21; 0xc9;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm9) *)
  0xc4; 0xe2; 0x75; 0x0b; 0xd6;
                           (* VPMULHRSW (%_% ymm2) (%_% ymm1) (%_% ymm6) *)
  0xc5; 0xed; 0xd5; 0xd7;  (* VPMULLW (%_% ymm2) (%_% ymm2) (%_% ymm7) *)
  0xc5; 0xf5; 0xfe; 0xca;  (* VPADDD (%_% ymm1) (%_% ymm1) (%_% ymm2) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x0f; 0x87; 0xc0; 0x00; 0x00; 0x00;
                           (* JA (Imm32 (word 192)) *)
  0xc4; 0xc1; 0x39; 0x73; 0xd8; 0x08;
                           (* VPSRLDQ (%_% xmm8) (%_% xmm8) (Imm8 (word 8)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0x21; 0x7a; 0x7e; 0x0c; 0xd2;
                           (* VMOVQ (%_% xmm9) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0x42; 0x39; 0x00; 0xc9;
                           (* VPSHUFB (%_% xmm9) (%_% xmm8) (%_% xmm9) *)
  0xc4; 0xc2; 0x7d; 0x21; 0xc9;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm9) *)
  0xc4; 0xe2; 0x75; 0x0b; 0xd6;
                           (* VPMULHRSW (%_% ymm2) (%_% ymm1) (%_% ymm6) *)
  0xc5; 0xed; 0xd5; 0xd7;  (* VPMULLW (%_% ymm2) (%_% ymm2) (%_% ymm7) *)
  0xc5; 0xf5; 0xfe; 0xca;  (* VPADDD (%_% ymm1) (%_% ymm1) (%_% ymm2) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x77; 0x7e;              (* JA (Imm8 (word 126)) *)
  0xc4; 0xc3; 0x7d; 0x39; 0xc0; 0x01;
                           (* VEXTRACTI128 (%_% xmm8) (%_% ymm0) (Imm8 (word 1)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0x21; 0x7a; 0x7e; 0x0c; 0xd2;
                           (* VMOVQ (%_% xmm9) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0x42; 0x39; 0x00; 0xc9;
                           (* VPSHUFB (%_% xmm9) (%_% xmm8) (%_% xmm9) *)
  0xc4; 0xc2; 0x7d; 0x21; 0xc9;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm9) *)
  0xc4; 0xe2; 0x75; 0x0b; 0xd6;
                           (* VPMULHRSW (%_% ymm2) (%_% ymm1) (%_% ymm6) *)
  0xc5; 0xed; 0xd5; 0xd7;  (* VPMULLW (%_% ymm2) (%_% ymm2) (%_% ymm7) *)
  0xc5; 0xf5; 0xfe; 0xca;  (* VPADDD (%_% ymm1) (%_% ymm1) (%_% ymm2) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x77; 0x3c;              (* JA (Imm8 (word 60)) *)
  0xc4; 0xc1; 0x39; 0x73; 0xd8; 0x08;
                           (* VPSRLDQ (%_% xmm8) (%_% xmm8) (Imm8 (word 8)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0x21; 0x7a; 0x7e; 0x0c; 0xd2;
                           (* VMOVQ (%_% xmm9) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0x42; 0x39; 0x00; 0xc9;
                           (* VPSHUFB (%_% xmm9) (%_% xmm8) (%_% xmm9) *)
  0xc4; 0xc2; 0x7d; 0x21; 0xc9;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm9) *)
  0xc4; 0xe2; 0x75; 0x0b; 0xd6;
                           (* VPMULHRSW (%_% ymm2) (%_% ymm1) (%_% ymm6) *)
  0xc5; 0xed; 0xd5; 0xd7;  (* VPMULLW (%_% ymm2) (%_% ymm2) (%_% ymm7) *)
  0xc5; 0xf5; 0xfe; 0xca;  (* VPADDD (%_% ymm1) (%_% ymm1) (%_% ymm2) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0xe9; 0xc7; 0xfe; 0xff; 0xff;
                           (* JMP (Imm32 (word 4294966983)) *)
  0x3d; 0x00; 0x01; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 256)) *)
  0x0f; 0x83; 0x84; 0x00; 0x00; 0x00;
                           (* JAE (Imm32 (word 132)) *)
  0x81; 0xf9; 0x88; 0x00; 0x00; 0x00;
                           (* CMP (% ecx) (Imm32 (word 136)) *)
  0x73; 0x7c;              (* JAE (Imm8 (word 124)) *)
  0x44; 0x0f; 0xb6; 0x1c; 0x0e;
                           (* MOVZX (% r11d) (Memop Byte (%%% (rsi,0,rcx))) *)
  0xff; 0xc1;              (* INC (% ecx) *)
  0x45; 0x89; 0xda;        (* MOV (% r10d) (% r11d) *)
  0x41; 0x83; 0xe2; 0x0f;  (* AND (% r10d) (Imm8 (word 15)) *)
  0x41; 0x83; 0xfa; 0x0f;  (* CMP (% r10d) (Imm8 (word 15)) *)
  0x73; 0x2b;              (* JAE (Imm8 (word 43)) *)
  0x45; 0x89; 0xd3;        (* MOV (% r11d) (% r10d) *)
  0x45; 0x69; 0xdb; 0xcd; 0x00; 0x00; 0x00;
                           (* IMUL3 (% r11d) (% r11d,Imm32 (word 205)) *)
  0x41; 0xc1; 0xeb; 0x0a;  (* SHR (% r11d) (Imm8 (word 10)) *)
  0x45; 0x6b; 0xdb; 0x05;  (* IMUL3 (% r11d) (% r11d,Imm8 (word 5)) *)
  0x45; 0x29; 0xda;        (* SUB (% r10d) (% r11d) *)
  0x41; 0xbb; 0x02; 0x00; 0x00; 0x00;
                           (* MOV (% r11d) (Imm32 (word 2)) *)
  0x45; 0x29; 0xd3;        (* SUB (% r11d) (% r10d) *)
  0x44; 0x89; 0x1c; 0x87;  (* MOV (Memop Doubleword (%%% (rdi,2,rax))) (% r11d) *)
  0xff; 0xc0;              (* INC (% eax) *)
  0x3d; 0x00; 0x01; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 256)) *)
  0x73; 0x3d;              (* JAE (Imm8 (word 61)) *)
  0x44; 0x0f; 0xb6; 0x5c; 0x0e; 0xff;
                           (* MOVZX (% r11d) (Memop Byte (%%%% (rsi,0,rcx,-- &1))) *)
  0x41; 0xc1; 0xeb; 0x04;  (* SHR (% r11d) (Imm8 (word 4)) *)
  0x41; 0x83; 0xe3; 0x0f;  (* AND (% r11d) (Imm8 (word 15)) *)
  0x41; 0x83; 0xfb; 0x0f;  (* CMP (% r11d) (Imm8 (word 15)) *)
  0x73; 0x9a;              (* JAE (Imm8 (word 154)) *)
  0x45; 0x89; 0xda;        (* MOV (% r10d) (% r11d) *)
  0x45; 0x69; 0xd2; 0xcd; 0x00; 0x00; 0x00;
                           (* IMUL3 (% r10d) (% r10d,Imm32 (word 205)) *)
  0x41; 0xc1; 0xea; 0x0a;  (* SHR (% r10d) (Imm8 (word 10)) *)
  0x45; 0x6b; 0xd2; 0x05;  (* IMUL3 (% r10d) (% r10d,Imm8 (word 5)) *)
  0x45; 0x29; 0xd3;        (* SUB (% r11d) (% r10d) *)
  0x41; 0xba; 0x02; 0x00; 0x00; 0x00;
                           (* MOV (% r10d) (Imm32 (word 2)) *)
  0x45; 0x29; 0xda;        (* SUB (% r10d) (% r11d) *)
  0x44; 0x89; 0x14; 0x87;  (* MOV (Memop Doubleword (%%% (rdi,2,rax))) (% r10d) *)
  0xff; 0xc0;              (* INC (% eax) *)
  0xe9; 0x71; 0xff; 0xff; 0xff;
                           (* JMP (Imm32 (word 4294967153)) *)
  0xc5; 0xf8; 0x77;        (* VZEROUPPER *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_rej_uniform_eta2_tmc = define_trimmed
  "mldsa_rej_uniform_eta2_tmc" mldsa_rej_uniform_eta2_mc;;

(* ========================================================================= *)
(* Supporting spec lemmas + byte-shape interior aliases (CORRECT).           *)
(* ========================================================================= *)
(* The public spec REJ_SAMPLE_ETA2 (common/mldsa_specs.ml) takes a nibble list. *)
(* The proof below is written against the byte-list shape, so we introduce a *)
(* byte-shape alias REJ_SAMPLE_ETA2_BYTES and bridge to the public spec at the *)
(* subroutine-spec boundary via REJ_SAMPLE_ETA2_BYTES_EQ.                    *)

(* ------------------------------------------------------------------------- *)
(* Model of the AVX2 VPMULHRSW (packed multiply high with round-and-scale)   *)
(* on a single int16 lane: (x*y >> 14) + 1, taking the high 16 bits.  Used to *)
(* express the eta=2 mod-5 reduction (vpmulhrsw/vpmullw/vpaddd) at the store. *)
(* ------------------------------------------------------------------------- *)
let mulhrs_eta2 = new_definition
  `mulhrs_eta2 (x:int16) (y:int16) : int16 =
     word_subword
       (word_add (word_ushr (word_mul (word_sx x) (word_sx y):int32) 14)
                 (word 1:int32))
       (1,16)`;;

(* ========================================================================= *)
(* eta2 CORRECT: spec/algebra lemmas.                                        *)
(* Accept threshold is nibble < 15; the coefficient map is eta2's mod-5 form. *)
(* The int16-nibble path is developed as REJ_SAMPLE_ETA2_BYTES, with the     *)
(* shortcut form (REJ_SAMPLE_ETA2 (BYTES_TO_NIBBLES l)) recovered as         *)
(* REJ_SAMPLE_ETA2_BYTES_EQ.                                                 *)
(* ========================================================================= *)

(* Internal byte->nibble decomposition stored in int16 lanes (matching the   *)
(* SIMD register layout used by the loop body). Accept nibble n iff n < 15.  *)
let REJ_NIBBLES_ETA2 = define
  `REJ_NIBBLES_ETA2 (l:byte list) =
   FILTER (\x:int16. val x < 15) (NIBBLES_OF_BYTES l)`;;

(* int16-nibble-path sample: map each accepted nibble to its eta=2           *)
(* coefficient  2 - (n MOD 5)  in [-2,2], stored sign-extended into int32.   *)
let REJ_SAMPLE_ETA2_BYTES = define
  `REJ_SAMPLE_ETA2_BYTES (l:byte list) =
   MAP (\x:int16. word_sx(word_sub (word 2:int16) (word_umod x (word 5))):int32)
       (REJ_NIBBLES_ETA2 l)`;;

(* Conversion lemma: NIBBLES_OF_BYTES (int16 list) =                         *)
(* MAP word_zx of BYTES_TO_NIBBLES (4 word list).                            *)
let REJ_SAMPLE_ETA2_BYTES_EQ = prove
 (`!l:byte list. REJ_SAMPLE_ETA2_BYTES l =
                 REJ_SAMPLE_ETA2 (BYTES_TO_NIBBLES l)`,
  GEN_TAC THEN
  REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2; REJ_SAMPLE_ETA2;
              NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES] THEN
  REWRITE_TAC[FILTER_MAP; o_DEF; GSYM MAP_o] THEN
  SUBGOAL_THEN `!x:4 word. val (word_zx x:int16) = val x`
    (fun th -> REWRITE_TAC[th]) THENL
   [GEN_TAC THEN MATCH_MP_TAC VAL_WORD_ZX THEN
    REWRITE_TAC[DIMINDEX_4; DIMINDEX_16] THEN ARITH_TAC;
    ALL_TAC] THEN
  SPEC_TAC(`BYTES_TO_NIBBLES (l:byte list)`,`xs:(4 word) list`) THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; MAP] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN
  SUBGOAL_THEN
   `!x:4 word. val x < 15
      ==> word_sx (word_sub (word 2:int16)
                             (word_umod (word_zx x:int16) (word 5))):int32 =
          word_sx (word_sub (word 2:4 word)
                             (word_umod x (word 5:4 word))):int32`
   (fun th -> ASM_MESON_TAC[th]) THEN
  SUBGOAL_THEN
   `!n. n < 15
      ==> word_sx (word_sub (word 2:int16)
                             (word_umod (word_zx (word n:4 word):int16)
                                        (word 5))):int32 =
          word_sx (word_sub (word 2:4 word)
                             (word_umod (word n:4 word) (word 5:4 word))):int32`
   MP_TAC THENL
   [CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC WORD_REDUCE_CONV;
    ALL_TAC] THEN
  DISCH_TAC THEN GEN_TAC THEN
  ONCE_REWRITE_TAC[GSYM WORD_VAL] THEN DISCH_TAC THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `val (x:4 word):num`) THEN
  ANTS_TAC THENL
   [POP_ASSUM MP_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_4] THEN
    MP_TAC(ISPEC `x:4 word` VAL_BOUND) THEN
    REWRITE_TAC[DIMINDEX_4] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(SPECL [`val(x:4 word):num`; `16`] MOD_LT) THEN
    ASM_SIMP_TAC[LT_TRANS] THEN ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[WORD_VAL]);;

needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_eta2_avx2_steps.ml";;

include Make_rej_uniform_eta2_steps(struct
  let trimmed_code = mldsa_rej_uniform_eta2_tmc
  let reduce_nibble = mulhrs_eta2
  let nibbles = REJ_NIBBLES_ETA2
  let sample_bytes = REJ_SAMPLE_ETA2_BYTES
end);;

type_invention_error := false;;
needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_avx2_utils.ml";;
type_invention_error := true;;

let (MEMSAFE_ARITH_TAC:tactic) =
  let numty = `:num` in
  let is_num_relop tm =
    exists (fun op -> is_binary op tm &&
                      (let x,_ = dest_binary op tm in type_of x = numty))
           ["=";"<";"<=";">";">="]
  and avoiders = ["lowdigits"; "highdigits"; "bigdigit";
                  "read"; "write"; "word"] in
  let avoiderp tm =
    match tm with Const(n,_) -> mem n avoiders | _ -> false in
  let filtered tm =
    (is_num_relop tm || (is_neg tm && is_num_relop (dest_neg tm))) &&
    not(can (find_term avoiderp) tm) in
  let tweak = GEN_REWRITE_RULE TRY_CONV [ARITH_RULE `~(n = 0) <=> 1 <= n`] in
  W(fun (asl,w) ->
    let asl' = filter (fun (_,th) -> filtered(concl th)) asl in
    MAP_EVERY (MP_TAC o tweak o snd) asl' THEN CONV_TAC ARITH_RULE);;

let MEMSAFE_BITVAL_TAC:tactic =
  W(fun (asl,w) ->
    let bvs = find_terms (fun t ->
      try fst(dest_const(rator t)) = "bitval" with _ -> false) w in
    let bvs = setify bvs in
    MAP_EVERY (fun bv ->
      MP_TAC(SPEC (rand bv) BITVAL_BOUND)) bvs);;

let CONTAINED_ASM_TAC =
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  GEN_REWRITE_TAC (BINOP_CONV o LAND_CONV o LAND_CONV o TOP_DEPTH_CONV)
   [VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(BINOP_CONV(LAND_CONV MOD_DOWN_CONV)) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2; CONTAINED_MODULO_LMOD] THEN
  ((GEN_REWRITE_TAC I [CONTAINED_MODULO_REFL] THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_SIMPLE THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC));;

let TABLE_IDX_LT_256 = prove
 (`!K:num. val((word_zx:(M)word->int64)
              ((word_zx:(N)word->(M)word)
              ((word:num->(N)word)(K MOD 256)))) < 256`,
  REPEAT GEN_TAC THEN REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD] THEN
  TRANS_TAC LET_TRANS `K MOD 256` THEN
  CONJ_TAC THENL
   [MESON_TAC[MOD_LE; LE_TRANS];
    SIMP_TAC[DIVISION; ARITH_EQ]]);;

let GATHER_CONTAINED = prove
 (`!(table:int64) idx:int64. val idx < 256
     ==> contained_modulo (2 EXP 64)
           (val(word_add table (word(8 * val idx))),8) (val table,2048)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
  ASM_ARITH_TAC);;

let GATHER_BOUND_TAC : tactic =
  DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN MATCH_ACCEPT_TAC TABLE_IDX_LT_256;;

let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

let ETA2_SI1_COUNTER_MS_TAC : tactic =
  X86_STEPS_TAC EXEC (21--24) THEN
  MP_TAC(ISPECL[`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES) THEN
  ANTS_TAC THENL
   [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `LENGTH(inlist:byte list) = 136` THEN
    UNDISCH_TAC `16 * i <= 120` THEN ARITH_TAC; STRIP_TAC] THEN
  W(fun (asl,w) ->
     let m8def = find (fun th -> match concl th with Comb(Comb(Const("=",_),_),Var("mask8",_)) -> true | _ -> false) (map snd asl) in
     RULE_ASSUM_TAC(fun th -> if concl th = maskbit_tgt ||
        can(find_term(fun u->match u with Const("TABLE_ENTRY",_)->true|_->false))(concl th)
        then th else REWRITE_RULE[GSYM m8def] th)) THEN
  W(fun (asl,w) ->
    let r9 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("R9",_)),Var("s24",_))),_) -> true | _ -> false) asl in
    let goal_pc = find_term (fun t -> match t with Comb(Const("word_popcount",_),_) -> true | _ -> false) (concl(snd r9)) in
    let low8 = `bitval(bit 7 (word_subword (f1bnd:int256) (0,8):byte)) + bitval(bit 7 (word_subword f1bnd (8,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (16,8):byte)) + bitval(bit 7 (word_subword f1bnd (24,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (32,8):byte)) + bitval(bit 7 (word_subword f1bnd (40,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (48,8):byte)) + bitval(bit 7 (word_subword f1bnd (56,8):byte))` in
    let mr = CONV_RULE(DEPTH_CONV BETA_CONV THENC NUM_REDUCE_CONV)
               (SPEC `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` MOD_RED) in
    let popeq = prove(mk_eq(goal_pc, low8),
      REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
      REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`; MOD_MOD_EXP_MIN] THEN
      CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
      REWRITE_TAC[ARITH_RULE `2 EXP 8 = 256`; mr] THEN
      MAP_EVERY (fun b -> BOOL_CASES_TAC b)
        [`bit 7 (word_subword (f1bnd:int256) (0,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (8,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (16,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (24,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (32,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (40,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (48,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (56,8):byte)`] THEN
      REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV) in
    let maskbit = snd(find (fun (_,th) -> let c=concl th in is_forall c &&
        can(find_term(fun u->u=`f1bnd:int256`))c && can(find_term(fun u->match u with Comb(Const("bit",_),_)->true|_->false))c &&
        not(can(find_term(fun u->match u with Const("word_zx",_)->true|_->false))c) &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c)) asl) in
    let mb_tm = concl maskbit in
    let blk0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
           (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
    let blkeq = mk_eq(low8, `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)`) in
    let blk0_tm = concl(snd blk0) in
    let bsum_raw = prove(mk_imp(mb_tm, mk_imp(blk0_tm, blkeq)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN DISCH_THEN(fun b -> REWRITE_TAC[b]) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
      ASM_SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let bsum = MP (MP bsum_raw maskbit) (snd blk0) in
    let pop_len = TRANS popeq bsum in
    let leninl = find (fun (_,th) -> match concl th with
       Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asl in
    let i116 = find (fun (_,th) -> match concl th with
       Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asl in
    let nible = find (fun (_,th) -> match concl th with
       Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_NIBBLES_ETA2",_),_))),_) -> true | _ -> false) asl in
    let len_eq = find (fun (_,th) -> match concl th with
       Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) asl in
    let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`)
                    (snd i116)) (snd leninl) in
    let bnd0 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_1) (CONJ a1 (snd nible)) in
    let bnd = REWRITE_RULE[snd len_eq] bnd0 in
    let block0len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)` in
    let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let ja = MP (ISPECL[mk_binop `(+):num->num->num` `outlen0:num` block0len; `248`] JA_NOT_TAKEN_LE)
                (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
    ASSUME_TAC pop_len THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
  X86_STEPS_TAC EXEC (25--26) THEN
  (* MS FIX: resolve RIP s26 = pc+207 via the structural COND match (SI2/SI3 style),
     not find_term(pc+207) — the anchored events fact also mentions pc+207. *)
  SUBGOAL_THEN `read RIP s26 = word (pc + 207):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let blk0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
             (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let ja = find (fun (_,th) -> is_disj(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th)) asl in
      let ifrip = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s26",_))),r) ->
           (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asl in
      MP_TAC (snd ifrip) THEN
      REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
      REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC] THEN
  W(fun (asl,w) ->
    let pl = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
    let rr = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
    RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr])) THEN
  ALL_TAC;;

let EXEC_ETA2 = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

let rec conj_append_right t ev =
  if is_conj t then
    let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let rec conj_append_right t ev =
  if is_conj t then let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let LENGTH_REJ_SAMPLE_ETA2_BYTES_SUB_LIST_BOUND = prove
 (`!(inlist:byte list) k.
     k <= LENGTH inlist
     ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,k) inlist):int32 list) <= 2 * k`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPEC `SUB_LIST(0, k) (inlist:byte list):byte list`
              LENGTH_REJ_SAMPLE_ETA2_BYTES_BOUND) THEN
  ASM_SIMP_TAC[LENGTH_SUB_LIST_0]);;

let q399_ms_eta2 = `\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
      read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
      read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
      read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
      read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
      read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist):int32 list)) /\
      read RCX s = word(16*N) /\
      read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist):int32 list))) s =
        num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist))) /\
      (exists e_acc:(uarch_event)list. read events s = APPEND e_acc (e:(uarch_event)list) /\
        memaccess_inbounds e_acc [(buf:int64),136; (table:int64),2048] [(res:int64),1024])`;;

let q86_ms_eta2 = `\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
      read RIP s = word(pc + 86) /\ read RSP s = stackpointer /\
      read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
      read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
      read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
      read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
      read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
      read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
      read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
      read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
      read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist):int32 list)) /\
      read RCX s = word(16*N) /\
      read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist):int32 list))) s =
        num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*N) inlist))) /\
      (exists e_acc:(uarch_event)list. read events s = APPEND e_acc (e:(uarch_event)list) /\
        memaccess_inbounds e_acc [(buf:int64),136; (table:int64),2048] [(res:int64),1024])`;;

let is_le256_rej g =
  match g with
    Comb(Comb(Const("<=",_),
      Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),
      n) -> n = `256`
  | _ -> false;;

let CLOSE_LE256_TAC : tactic =
  W(fun (asl,g) ->
    let arg = rand(rand(lhand g)) in   (* the SUB_LIST(0,p) inlist argument *)
    FIRST_X_ASSUM(fun th ->
       match concl th with
         Comb(Comb(Const("<=",_),
           Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),a))),
           Comb(Const("NUMERAL",_),_)) when a = arg -> MP_TAC th
       | _ -> NO_TAC) THEN
    ARITH_TAC);;

let exit_offset_ms_eta2_tm = `
  !res buf table (inlist:byte list) pc N stackpointer e.
       LENGTH inlist = 136 /\
       nonoverlapping_modulo (2 EXP 64) (pc, 546) (val res,1024) /\
       nonoverlapping_modulo (2 EXP 64) (pc, 546) (val buf, 136) /\
       nonoverlapping_modulo (2 EXP 64) (pc, 546) (val table,2048) /\
       nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 136) /\
       nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
       16 * N = 128 /\
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list) <= 248
       ==> ensures x86
            (\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                 read RIP s = word(pc + 86) /\ read RSP s = stackpointer /\
                 read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                 read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                 read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                 read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                 read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
                 read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                 read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
                 read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
                 read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(N-1)) inlist):int32 list)) /\
                 read RCX s = word(16*(N-1)) /\
                 read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(N-1)) inlist):int32 list))) s =
                   num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(N-1)) inlist))) /\
                 (exists e_acc:(uarch_event)list. read events s = APPEND e_acc e /\
                   memaccess_inbounds e_acc [buf,136; table,2048] [res,1024]))
            (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
                 (exists e2. read events s = APPEND e2 e /\
                   memaccess_inbounds e2 [buf,136; table,2048] [res,1024]))
            (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
             MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                        ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
             MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(res,1024)])`;;

let core_ms_eta2_tm = `!res buf table (inlist:byte list) e pc.
        LENGTH inlist = 136 /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (res, 1024) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (buf, 136) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (table, 2048) /\
        nonoverlapping (res, 1024) (buf, 136) /\
        nonoverlapping (res, 1024) (table, 2048)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                  read RIP s = word pc /\
                  C_ARGUMENTS [res; buf; table] s /\
                  read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                  read(memory :> bytes(table,2048)) s =
                    num_of_wordlist mldsa_rej_uniform_table /\
                  read events s = e)
             (\s. read RIP s = word(pc + LENGTH (BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
                  (exists e2.
                     read events s = APPEND e2 e /\
                     memaccess_inbounds e2 [buf,136; table,2048] [res,1024]))
             (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
              MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                         ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
              MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
              MAYCHANGE [memory :> bytes(res,1024)])`;;

needs "mldsa_native/x86_64/proofs/subroutine_signatures.ml";;

(* ========================================================================= *)
(* Constant-time (secret-independent timing) machinery for rej_uniform_eta2. *)
(* Arch-neutral prelude shared with the aarch64 proof: the public            *)
(* reject-mask projection and its list algebra, with one accept/reject bit   *)
(* per nibble (accept = val < 15) and the accepted VALUES discarded. From    *)
(* this bool list one recovers the per-group 8-bit table index (PACK_MASK8)  *)
(* and the accepted counts (NUM_ACCEPTED = store-advance / trip-count        *)
(* driver) — every secret-dependent address, but not the accepted values.    *)
(* ========================================================================= *)

let REJ_MASK_ETA2 = define
  `REJ_MASK_ETA2 (l:byte list) : bool list =
   MAP (\x:int16. val x < 15) (NIBBLES_OF_BYTES l)`;;

(* Abstract core: #elements passing P = #`true`s in the boolean image.       *)
let LENGTH_FILTER_EQ_LENGTH_FILTER_MAP = prove
 (`!(P:A->bool) xs.
     LENGTH(FILTER (\b:bool. b) (MAP P xs)) = LENGTH(FILTER P xs)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN
  REWRITE_TAC[MAP; FILTER; LENGTH] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

(* Store-advance / trip-count bridge: #ACCEPTED nibbles = #`true`s in the    *)
(* PUBLIC reject mask.  Value-free.                                          *)
let LENGTH_REJ_NIBBLES_ETA2_EQ_MASK = prove
 (`!l:byte list.
     LENGTH(REJ_NIBBLES_ETA2 l) = LENGTH(FILTER (\b:bool. b) (REJ_MASK_ETA2 l))`,
  REWRITE_TAC[REJ_NIBBLES_ETA2; REJ_MASK_ETA2;
              LENGTH_FILTER_EQ_LENGTH_FILTER_MAP]);;

(* Public "accepted count" over a mask, additive over APPEND.                *)
let NUM_ACCEPTED = define
  `NUM_ACCEPTED (m:bool list) = LENGTH(FILTER (\b:bool. b) m)`;;

let NUM_ACCEPTED_APPEND = prove
 (`!m1 m2. NUM_ACCEPTED(APPEND m1 m2) = NUM_ACCEPTED m1 + NUM_ACCEPTED m2`,
  REWRITE_TAC[NUM_ACCEPTED; FILTER_APPEND; LENGTH_APPEND]);;

(* Public table-index witness: 8-bit LSB-first packing of an accept-mask     *)
(* group.  The compaction table is indexed by this 0..255 value.            *)
let PACK_MASK8 = define
  `PACK_MASK8 (bs:bool list) =
     bitval(EL 0 bs) +   2 * bitval(EL 1 bs) +
     4 * bitval(EL 2 bs) + 8 * bitval(EL 3 bs) +
    16 * bitval(EL 4 bs) + 32 * bitval(EL 5 bs) +
    64 * bitval(EL 6 bs) + 128 * bitval(EL 7 bs)`;;

let PACK_MASK8_BOUND = prove
 (`!bs:bool list. PACK_MASK8 bs < 256`,
  GEN_TAC THEN REWRITE_TAC[PACK_MASK8] THEN
  MAP_EVERY (fun t -> MP_TAC(SPEC t BITVAL_BOUND))
   [`EL 0 (bs:bool list)`; `EL 1 (bs:bool list)`; `EL 2 (bs:bool list)`;
    `EL 3 (bs:bool list)`; `EL 4 (bs:bool list)`; `EL 5 (bs:bool list)`;
    `EL 6 (bs:bool list)`; `EL 7 (bs:bool list)`] THEN
  ARITH_TAC);;

(* byte-index SUB_LIST maps to nibble-index SUB_LIST at 2x offset/length.     *)
let NIBBLES_OF_BYTES_SUB_LIST = prove
 (`!l a b. NIBBLES_OF_BYTES(SUB_LIST(a,b) l) =
           SUB_LIST(2*a,2*b)(NIBBLES_OF_BYTES l)`,
  LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; SUB_LIST_CLAUSES; APPEND;
              MULT_CLAUSES; ADD_CLAUSES; ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`] THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES; APPEND]);;

(* General-offset MAP/SUB_LIST commutation.                                  *)
let SUB_LIST_MAP_GEN = prove
 (`!(f:A->B) l a b. SUB_LIST(a,b)(MAP f l) = MAP f (SUB_LIST(a,b) l)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[MAP; SUB_LIST_CLAUSES]);;

(* mask-level length-doubling commutation: hardware REJ_MASK_ETA2(SUB_LIST)  *)
(* into SUB_LIST of the ATOMIC mask.                                         *)
let REJ_MASK_ETA2_SUB_LIST = prove
 (`!l a b. REJ_MASK_ETA2(SUB_LIST(a,b) l) = SUB_LIST(2*a,2*b)(REJ_MASK_ETA2 l)`,
  REWRITE_TAC[REJ_MASK_ETA2; NIBBLES_OF_BYTES_SUB_LIST; SUB_LIST_MAP_GEN]);;


(* ------------------------------------------------------------------------- *)
(* Trip-count lemmas.                                                         *)
(* ------------------------------------------------------------------------- *)

(* --- niblen(16N,inlist) = NUM_ACCEPTED(SUB_LIST(0,32N) mask): the public    *)
(*     re-expression of the (inlist-based) exit predicate over the mask.  --- *)
let NIBLEN_EQ_NUMACC_ETA2 = prove
 (`!(inlist:byte list) (N:num).
     LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16 * N) inlist):int16 list) =
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; NUM_ACCEPTED;
              REJ_MASK_ETA2_SUB_LIST] THEN
  REWRITE_TAC[MULT_CLAUSES; ARITH_RULE `2 * (16 * N) = 32 * N`]);;

(* --- The mask-based trip count (public loop iteration count). --- *)
let N_OF_MASK_ETA2 = define
  `N_OF_MASK_ETA2 (mask:bool list) : num =
     minimal N. 120 < 16 * N \/ 248 < NUM_ACCEPTED(SUB_LIST(0,32 * N) mask)`;;

(* --- Trip minimality (dual-exit crux), analogue of                          *)
(*     MLDSA_ETA2_LOOP8_TRIP_MINIMAL. --- *)
let N_OF_MASK_ETA2_MINIMAL = prove
 (`!(mask:bool list).
     (120 < 16 * N_OF_MASK_ETA2 mask \/
      248 < NUM_ACCEPTED(SUB_LIST(0,32 * N_OF_MASK_ETA2 mask) mask)) /\
     (!i. i < N_OF_MASK_ETA2 mask
          ==> ~(120 < 16 * i) /\
              ~(248 < NUM_ACCEPTED(SUB_LIST(0,32 * i) mask)))`,
  GEN_TAC THEN REWRITE_TAC[N_OF_MASK_ETA2] THEN
  SUBGOAL_THEN
    `?n. 120 < 16 * n \/ 248 < NUM_ACCEPTED(SUB_LIST(0,32 * n)(mask:bool list))`
    ASSUME_TAC THENL
   [EXISTS_TAC `8` THEN DISJ1_TAC THEN ARITH_TAC; ALL_TAC] THEN
  FIRST_X_ASSUM(STRIP_ASSUME_TAC o REWRITE_RULE[MINIMAL]) THEN
  ASM_REWRITE_TAC[] THEN
  X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM DE_MORGAN_THM] THEN FIRST_X_ASSUM MATCH_MP_TAC THEN
  ASM_REWRITE_TAC[]);;

(* ========================================================================= *)
(* Constant-time (SAFE) proof layer.                                          *)
(*                                                                            *)
(* Scalar-tail cluster: the OFFSET-arm SAFE ingredients — head-guard leg,     *)
(* per-byte body, full scalar-tail run, the at-p corollary, and the           *)
(* scalar-tail / head-guard memaccess-recovery lemmas.                        *)
(* ========================================================================= *)

(* --- Head-guard events + LEG1B_HEADGUARD_SAFE_ETA2 --- *)
(* SAFE leg1b head-guard step lemma (exit block, OFFSET arm): pc+86 @ pos 16N *)
(* -> pc+399, concrete public events. The 4-instruction head-guard segment    *)
(* emits exactly two public EventJumps (eax-guard not-taken, ecx-guard taken).*)

let f_ev_headguard_eta2 = define
 `f_ev_headguard_eta2 (pc:num) =
    [EventJump (word (pc + 106),word (pc + 399));
     EventJump (word (pc + 97),word (pc + 97))]`;;

(* q86_safe / q399_safe : the MEMSAFE value predicates with the existential   *)
(* events conjunct replaced by CONCRETE events (thread events-equality only;  *)
(* memaccess is form-independent, recovered at assembly time).                *)
(* OFFSET arm: 16*N=128 (N=8) always, so use concrete 128-form predicates -   *)
(* self-consistent for stepping; the assembly bridges 16*N=128 when composing.*)
let q86_safe_eta2 =
  let sv,body = dest_abs q86_ms_eta2 in
  mk_abs(sv, mk_conj(subst[`128`,`16 * N`] (lhand body), `read events (s:x86state) = ec`));;
let q399_safe_eta2 =
  let sv,body = dest_abs q399_ms_eta2 in
  mk_abs(sv, mk_conj(subst[`128`,`16 * N`] (lhand body),
    `read events (s:x86state) = APPEND (f_ev_headguard_eta2 pc) ec`));;

let exoff = snd(strip_forall exit_offset_ms_eta2_tm);;
let ens = snd(dest_imp exoff);;
let frame = rand ens;;
let ens_hd = rator(rator(rator ens));;

let leg1b_headguard_safe_tm = list_mk_forall
  ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
    `N:num`;`stackpointer:int64`;`e:(uarch_event)list`;`ec:(uarch_event)list`],
   mk_imp(lhand exoff,
     mk_comb(mk_comb(mk_comb(ens_hd, q86_safe_eta2), q399_safe_eta2), frame)));;

let ja_eax_128 =
 `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,128) inlist):int32 list)):int64):int32)):int - &248 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,128) inlist):int32 list)):int64):int32) (word 248):int32))) \/ val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,128) inlist):int32 list)):int64):int32) (word 248):int32) = 0`;;

let ja_ecx_128 =
 `~(~(&(val(word_zx(word(128):int64):int32)):int - &120 = &(val(word_sub(word_zx(word(128):int64):int32) (word 120):int32))) \/ val(word_sub(word_zx(word(128):int64):int32) (word 120):int32) = 0)`;;

let LEG1B_HEADGUARD_SAFE_ETA2 = prove(leg1b_headguard_safe_tm,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,128) inlist):int32 list) <= 248` ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    SUBST1_TAC(SYM(ASSUME `16 * N = 128`)) THEN FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  SUBGOAL_THEN ja_eax_128 ASSUME_TAC THENL
   [MATCH_MP_TAC JA_NOT_TAKEN_LE THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN ja_ecx_128 ASSUME_TAC THENL
   [MATCH_MP_TAC JA_TAKEN_GT THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--4) THEN
  ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[f_ev_headguard_eta2; APPEND]);;


(* --- f_ev_scalar_body + SCALAR_TAIL_BODY_SAFE_ETA2 --- *)
(* SAFE scalar-tail per-byte BODY (leg2, land-the-body): pc+399 -> pc+399     *)
(* consuming input byte p, with CONCRETE PUBLIC events. f_ev_scalar_body is a *)
(* COND tree over the two PUBLIC nibble conditions (low<15, high<15). Proof = *)
(* SCALAR_TAIL_BODY_MEMSAFE_ETA2 with 2 swaps:                                *)
(*   (a) setup no-strip: SCALAR_BODY_SETUP_ETA2 (not _MS)                     *)
(*   (b) DISCHARGE_MEMSAFE_ASM_TAC -> SAFE_SCALAR_DISCHARGE_TAC (x4).         *)

let f_ev_scalar_body = define
 `f_ev_scalar_body (res:int64) (buf:int64) (pc:num) (inlist:byte list)
                   (p:num) (outlen0:num) =
    if val(EL p inlist) MOD 16 < 15 then
      (if val(EL p inlist) DIV 16 < 15 then
         [EventJump (word (pc + 542),word (pc + 399));
          EventStore (word_add res (word (4 * (outlen0 + 1))),4);
          EventJump (word (pc + 501),word (pc + 501));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 481),word (pc + 481));
          EventStore (word_add res (word (4 * val (word outlen0:int64))),4);
          EventJump (word (pc + 438),word (pc + 438));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 418),word (pc + 418));
          EventJump (word (pc + 410),word (pc + 410))]
       else
         [EventJump (word (pc + 501),word (pc + 399));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 481),word (pc + 481));
          EventStore (word_add res (word (4 * val (word outlen0:int64))),4);
          EventJump (word (pc + 438),word (pc + 438));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 418),word (pc + 418));
          EventJump (word (pc + 410),word (pc + 410))])
    else
      (if val(EL p inlist) DIV 16 < 15 then
         [EventJump (word (pc + 542),word (pc + 399));
          EventStore (word_add res (word (4 * outlen0)),4);
          EventJump (word (pc + 501),word (pc + 501));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 438),word (pc + 481));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 418),word (pc + 418));
          EventJump (word (pc + 410),word (pc + 410))]
       else
         [EventJump (word (pc + 501),word (pc + 399));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 438),word (pc + 481));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 418),word (pc + 418));
          EventJump (word (pc + 410),word (pc + 410))])`;;

(* Concrete-events discharge (replaces DISCHARGE_MEMSAFE_ASM_TAC).  Goal at    *)
(* each branch end: read events sN = APPEND (f_ev_scalar_body ...) e /\         *)
(* memaccess_inbounds (f_ev_scalar_body ...) [buf,136;table,2048] [res,1024].   *)
(* Unfold the def; the branch conds (in the asl) reduce the COND uniformly;     *)
(* events-eq closes by APPEND + the stepped events assumption; memaccess reuses *)
(* the MEMSAFE containment machinery (raw = public here, no bridge).           *)
let SAFE_SCALAR_DISCHARGE_TAC =
  REWRITE_TAC[f_ev_scalar_body] THEN
  CONJ_TAC THENL
   [ASM_REWRITE_TAC[APPEND];
    ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
    REPEAT CONJ_TAC THEN
    TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                CONTAINED_ASM_TAC) THEN NO_TAC)];;

(* Build the SAFE goal term: concrete events conjoined onto SCALAR_TAIL_BODY_ETA2's
   pre & post (events OUTERMOST), universally over the extra `e`.  outlen0 slot
   uses the statement var `L`; the setup substitutes L->outlen0. *)
let scalar_body_safe_eta2_tm =
  let qvars, body = strip_forall scalar_tail_body_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let fev = `f_ev_scalar_body res buf pc (inlist:byte list) p L` in
  let eq_pre = `read events (s:x86state) = e` in
  let eq_post = mk_conj
     (mk_eq(`read events (s:x86state)`, mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)),
      list_mk_comb(`memaccess_inbounds:(uarch_event)list->(int64#num)list->(int64#num)list->bool`,
        [fev; `[(buf:int64),136; (table:int64),2048]`; `[(res:int64),1024]`])) in
  let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] eq_pre)) in
  let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] eq_post)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

let SCALAR_TAIL_BODY_SAFE_ETA2 = prove
 (scalar_body_safe_eta2_tm,
  SCALAR_BODY_SETUP_ETA2 THEN
  ASM_CASES_TAC `val(EL p (inlist:byte list)) MOD 16 < 15` THENL
   [(* ============ ACCEPT-LOW (low<15): jae s10 NOT taken ============ *)
    SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 15):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC_ETA2 (9--19) THEN
    FIRST_X_ASSUM(fun th -> let c=concl th in
       if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s19:x86state`))c
       then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC_ETA2 (ASSUME `outlen0<256`)] th) else NO_TAC) THEN
    SUBGOAL_THEN `outlen0 + 1 < 256` ASSUME_TAC THENL
     [REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th->let c=concl th in c=`outlen0<256`||c=`val(EL p (inlist:byte list)) MOD 16 < 15`||c=`~(outlen0=255/\val(EL p (inlist:byte list)) MOD 16 < 15)`))) THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `~(&(val(word_zx(word(outlen0+1):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(outlen0+1):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC_ETA2 (20--21) THEN
    RELOAD_PREP_ETA2 `s21:x86state` THEN
    X86_VSTEPS_TAC EXEC_ETA2 (22--24) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[R11_NIBBLE_VAL_ETA2]) THEN DISCARD_OLDSTATE_TAC "s24" THEN
    ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 15` THENL
     [(* ===== ACCEPT-ACCEPT ===== *)
      SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 15):int32)))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `val(word(outlen0+1):int64) = outlen0+1` ASSUME_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0+1<256`) THEN ARITH_TAC; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (25--35) THEN
      X86_VSTEPS_TAC EXEC_ETA2 (36--36) THEN DISCARD_OLDSTATE_TAC "s36" THEN
      FIRST_X_ASSUM(fun th -> let c=concl th in
         if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s36:x86state`))c
         then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC_ETA2 (ASSUME `outlen0+1<256`)] th) else NO_TAC) THEN
      ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 2` ASSUME_TAC THENL
       [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_BOTH_ETA2) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
        DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
        FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
      ASM_REWRITE_TAC[ARITH_RULE `(outlen0+1)+1 = outlen0+2`] THEN
      CONJ_TAC THENL
       [TRY(CONJ_TAC THENL [RCX_INC_TAC; ALL_TAC]) THEN
        SUBGOAL_THEN `REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist) =
           APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                  [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32;
                   word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]` SUBST1_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_BOTH_ETA2) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
        SUBGOAL_THEN `4 * (outlen0 + 2) = 4 * outlen0 + 8` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s36:x86state`;
           `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list`;
           `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32;
             word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]`;
           `4*outlen0`; `8`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
        ANTS_TAC THENL
         [REWRITE_TAC[DIMINDEX_32] THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN CONJ_TAC THENL
         [FIRST_ASSUM ACCEPT_TAC;
          GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [GSYM(REWRITE_CONV[APPEND] `APPEND [a:int32] [b:int32]`)] THEN
          SUBGOAL_THEN `(8:num) = 4 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
          MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `word_add res (word(4*outlen0)):int64`; `s36:x86state`;
             `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]`;
             `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]`;
             `4`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
          ANTS_TAC THENL [REWRITE_TAC[DIMINDEX_32; LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
          SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
           [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
          ETA2_STORE_SPEC_TAC `s36:x86state` `val(EL p (inlist:byte list)) MOD 16` THEN
          ETA2_STORE_SPEC_TAC `s36:x86state` `val(EL p (inlist:byte list)) DIV 16` THEN
          CONJ_TAC THENL
           [FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c)
               then MP_TAC th else NO_TAC) THEN
            ASM_REWRITE_TAC[] THEN
            STORE4_FROM_SPEC `s36:x86state` `word_add res (word(4 * outlen0)):int64`;
            SUBGOAL_THEN `word_add (word_add res (word (4 * outlen0))) (word 4):int64 = word_add res (word (4 * (outlen0+1)))` SUBST1_TAC THENL
             [CONV_TAC WORD_RULE; ALL_TAC] THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c && not(can(find_term is_cond)c)
               then MP_TAC th else NO_TAC) THEN
            ASM_REWRITE_TAC[] THEN
            STORE4_FROM_SPEC `s36:x86state` `word_add res (word(4 * (outlen0+1))):int64`]];
        SAFE_SCALAR_DISCHARGE_TAC];
      (* ===== LO-only ===== *)
      SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 15):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL
         [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) DIV 16 < 15)`) THEN ARITH_TAC;
          MP_TAC(ISPEC `EL p (inlist:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
          MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] DIV_LE) THEN ARITH_TAC]; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (25--26) THEN DISCARD_OLDSTATE_TAC "s26" THEN
      ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 1` ASSUME_TAC THENL
       [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_LO_ETA2) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
        DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
        FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN
      CONJ_TAC THENL
       [TRY(CONJ_TAC THENL [RCX_INC_TAC; ALL_TAC]) THEN
        SUBGOAL_THEN `REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist) =
           APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                  [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]` SUBST1_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_LO_ETA2) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
        SUBGOAL_THEN `4 * (outlen0 + 1) = 4 * outlen0 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s26:x86state`;
           `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list`;
           `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]`;
           `4*outlen0`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
        ANTS_TAC THENL
         [REWRITE_TAC[DIMINDEX_32] THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
        CONJ_TAC THENL
         [FIRST_ASSUM ACCEPT_TAC;
          SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
           [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
          ETA2_STORE_SPEC_TAC `s26:x86state` `val(EL p (inlist:byte list)) MOD 16` THEN
          FIRST_X_ASSUM(fun th -> let c=concl th in
             if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c)
             then MP_TAC th else NO_TAC) THEN
          ASM_REWRITE_TAC[] THEN
          STORE4_FROM_SPEC `s26:x86state` `word_add res (word(4 * outlen0)):int64`];
        SAFE_SCALAR_DISCHARGE_TAC]];
    (* ============ REJECT-LOW (low>=15): jae s10 TAKEN -> movzbl s11 ============ *)
    SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 15):int32))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL
       [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) MOD 16 < 15)`) THEN ARITH_TAC;
        MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] MOD_LT_EQ) THEN ARITH_TAC]; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC_ETA2 (9--10) THEN
    RELOAD_PREP_ETA2 `s10:x86state` THEN
    X86_VSTEPS_TAC EXEC_ETA2 (11--13) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[R11_NIBBLE_VAL_ETA2]) THEN DISCARD_OLDSTATE_TAC "s13" THEN
    ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 15` THENL
     [(* ===== HI-only ===== *)
      SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 15):int32)))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (14--23) THEN
      X86_VSTEPS_TAC EXEC_ETA2 (24--25) THEN DISCARD_OLDSTATE_TAC "s25" THEN
      FIRST_X_ASSUM(fun th -> let c=concl th in
         if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s25:x86state`))c
         then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC_ETA2 (ASSUME `outlen0<256`)] th) else NO_TAC) THEN
      ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 1` ASSUME_TAC THENL
       [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_HI_ETA2) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
        DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
        FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN
      CONJ_TAC THENL
       [TRY(CONJ_TAC THENL [RCX_INC_TAC; ALL_TAC]) THEN
        SUBGOAL_THEN `REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist) =
           APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                  [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]` SUBST1_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_HI_ETA2) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
        SUBGOAL_THEN `4 * (outlen0 + 1) = 4 * outlen0 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s25:x86state`;
           `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list`;
           `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]`;
           `4*outlen0`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
        ANTS_TAC THENL
         [REWRITE_TAC[DIMINDEX_32] THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
        CONJ_TAC THENL
         [FIRST_ASSUM ACCEPT_TAC;
          ETA2_STORE_SPEC_TAC `s25:x86state` `val(EL p (inlist:byte list)) DIV 16` THEN
          FIRST_X_ASSUM(fun th -> let c=concl th in
             if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c && not(can(find_term is_cond)c)
             then MP_TAC th else NO_TAC) THEN
          ASM_REWRITE_TAC[] THEN
          STORE4_FROM_SPEC `s25:x86state` `word_add res (word(4 * outlen0)):int64`];
        SAFE_SCALAR_DISCHARGE_TAC];
      (* ===== NONE (low>=15, high>=15): jae s15 TAKEN -> pc+399, no store ===== *)
      SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 15):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL
         [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) DIV 16 < 15)`) THEN ARITH_TAC;
          MP_TAC(ISPEC `EL p (inlist:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
          MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] DIV_LE) THEN ARITH_TAC]; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (14--15) THEN DISCARD_OLDSTATE_TAC "s15" THEN
      ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0` ASSUME_TAC THENL
       [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_NONE_ETA2) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
        DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
        FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
      SUBGOAL_THEN `REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p+1) inlist):int32 list = REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist)` ASSUME_TAC THENL
       [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_NONE_ETA2) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN
      TRY RCX_INC_TAC THEN SAFE_SCALAR_DISCHARGE_TAC]]);;


(* --- f_ev_scalar_tail + FEV_TAIL_* --- *)
(* f_ev_scalar_tail — the public event trace of the eta2 scalar tail          *)
(* (byte loop pc+399 .. pc+542), by recursion on the byte budget d.           *)
(* Terminals:                                                                 *)
(*   count-exit  (outlen>=256):  [Jump(410,542)]                             *)
(*   offset-exit (p>=136,<256):  [Jump(418,542); Jump(410,410)]              *)
(*   mid-byte    (outlen=255,low<15): [Jump(481,542); Store(res+1020,4);      *)
(*      Jump(438,438); Load(buf+p,1); Jump(418,418); Jump(410,410)]          *)
(*   recursive:  APPEND (f_ev_scalar_tail d .. (p+1)) (f_ev_scalar_body .. p) *)
(* (events prepend: later segment is the APPEND-left/newer prefix).           *)
(* Threads events-EQUALITY only (memaccess recovered separately).             *)

let f_ev_scalar_tail = define
 `(f_ev_scalar_tail 0 (res:int64) (buf:int64) (pc:num) (inlist:byte list) (p:num) =
     (if 256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)
      then [EventJump (word (pc + 410),word (pc + 542))]
      else [EventJump (word (pc + 418),word (pc + 542));
            EventJump (word (pc + 410),word (pc + 410))])) /\
  (f_ev_scalar_tail (SUC d) (res:int64) (buf:int64) (pc:num) (inlist:byte list) (p:num) =
     (if 256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)
      then [EventJump (word (pc + 410),word (pc + 542))]
      else if p = 136
      then [EventJump (word (pc + 418),word (pc + 542));
            EventJump (word (pc + 410),word (pc + 410))]
      else if LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
              val(EL p inlist) MOD 16 < 15
      then [EventJump (word (pc + 481),word (pc + 542));
            EventStore (word_add res (word 1020),4);
            EventJump (word (pc + 438),word (pc + 438));
            EventLoad (word_add buf (word p),1);
            EventJump (word (pc + 418),word (pc + 418));
            EventJump (word (pc + 410),word (pc + 410))]
      else APPEND (f_ev_scalar_tail d res buf pc inlist (p+1))
                  (f_ev_scalar_body res buf pc inlist p
                     (LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)))))`;;

(* -- Per-terminal reduction lemmas (conditional rewrites, uniform over d). -- *)
let FEV_TAIL_COUNT = prove
 (`!d res buf pc (inlist:byte list) p.
     256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)
     ==> f_ev_scalar_tail d res buf pc inlist p =
         [EventJump (word (pc + 410),word (pc + 542))]`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  STRUCT_CASES_TAC (SPEC `d:num` num_CASES) THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail]);;

let FEV_TAIL_OFFSET = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     p = 136
     ==> f_ev_scalar_tail d res buf pc inlist p =
         [EventJump (word (pc + 418),word (pc + 542));
          EventJump (word (pc + 410),word (pc + 410))]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  STRUCT_CASES_TAC (SPEC `d:num` num_CASES) THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail]);;

let FEV_TAIL_MIDBYTE = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     ~(p = 136) /\
     LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
     val(EL p inlist) MOD 16 < 15
     ==> f_ev_scalar_tail (SUC d) res buf pc inlist p =
         [EventJump (word (pc + 481),word (pc + 542));
          EventStore (word_add res (word 1020),4);
          EventJump (word (pc + 438),word (pc + 438));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 418),word (pc + 418));
          EventJump (word (pc + 410),word (pc + 410))]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail]);;

let FEV_TAIL_REC = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     ~(p = 136) /\
     ~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
       val(EL p inlist) MOD 16 < 15)
     ==> f_ev_scalar_tail (SUC d) res buf pc inlist p =
         APPEND (f_ev_scalar_tail d res buf pc inlist (p+1))
                (f_ev_scalar_body res buf pc inlist p
                   (LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail]);;


(* --- SCALAR_TAIL_RUN_SAFE_ETA2 --- *)
(* SCALAR_TAIL_RUN_SAFE_ETA2 — the SAFE (constant-time) scalar tail run        *)
(* (byte loop pc+399 -> pc+542) with CONCRETE PUBLIC events                    *)
(* (f_ev_scalar_tail).  Mirrors SCALAR_TAIL_RUN_ETA2 (value) with:             *)
(*   - pre  : + read events s = e      (concrete anchor; NO strip)             *)
(*   - post : + read events s = APPEND (f_ev_scalar_tail d res buf pc inlist p) e *)
(*     (events-EQUALITY only; memaccess recovered separately).  Events         *)
(*     threaded DEEP-RIGHT (conj_append_right) to keep the canonical           *)
(*     bytes_loaded /\ RIP=.. /\ REST shape ENSURES_SEQUENCE needs.            *)
(* Terminal exits close by reducing f_ev_scalar_tail (FEV_TAIL_COUNT/OFFSET/   *)
(* MIDBYTE) + APPEND.  Recursive leg composes SCALAR_TAIL_BODY_SAFE_ETA2 + the *)
(* IH via ENSURES_SEQUENCE, with the IH's `e` set to APPEND(f_ev_body p L)e    *)
(* and R pre-rewritten via FEV_TAIL_REC + GSYM APPEND_ASSOC to match IH_post.  *)
(* ========================================================================= *)

let EXEC_ETA2 = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

let rec conj_append_right t ev =
  if is_conj t then
    let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let scalar_run_safe_eta2_tm =
  let qvars, body = strip_forall scalar_tail_run_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let fev = `f_ev_scalar_tail d res buf pc (inlist:byte list) p` in
  let eq_pre = `read events (s:x86state) = e` in
  let eq_post = mk_eq(`read events (s:x86state)`,
                      mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)) in
  let pre' = mk_abs(sv, conj_append_right preb (vsubst[sv,`s:x86state`] eq_pre)) in
  let post' = mk_abs(sv2, conj_append_right postb (vsubst[sv2,`s:x86state`] eq_post)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;


let SCALAR_TAIL_RUN_SAFE_ETA2 = prove
 (scalar_run_safe_eta2_tm,
  INDUCT_TAC THENL
   [(* ================= BASE CASE: d = 0 => p = 136 ================= *)
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `p = 136` SUBST_ALL_TAC THENL
     [REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in c=`136 - p <= 0` || c=`p <= 136`))) THEN ARITH_TAC; ALL_TAC] THEN
    MP_TAC(SPEC `inlist:byte list` SUB_LIST_BYTE_136) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `SUB_LIST(0,136) (inlist:byte list) = inlist`]) THEN
    REWRITE_TAC[ASSUME `SUB_LIST(0,136) (inlist:byte list) = inlist`] THEN
    ASM_CASES_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = 256` THENL
     [(* --- BASE COUNT-EXIT: outlen = 256 --- *)
      MP_TAC(SPEC `REJ_SAMPLE_ETA2_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
      ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
      REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = 256`] THEN
      REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = REJ_SAMPLE_ETA2_BYTES inlist`] THEN
      ENSURES_INIT_TAC "s0" THEN
      SUBGOAL_THEN `&(val(word_zx(word 256:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 256:int64):int32) (word 256):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (1--3) THEN
      ENSURES_FINAL_STATE_TAC THEN
      SUBGOAL_THEN `f_ev_scalar_tail 0 res buf pc (inlist:byte list) 136 = [EventJump (word (pc + 410),word (pc + 542))]` SUBST1_TAC THENL
       [MATCH_MP_TAC FEV_TAIL_COUNT THEN
        SUBGOAL_THEN `SUB_LIST(0,136)(inlist:byte list) = inlist` SUBST1_TAC THENL
         [MATCH_MP_TAC SUB_LIST_BYTE_136 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = 256`] THEN
      REWRITE_TAC[LENGTH_BUTLAST_TMC_ETA2] THEN ASM_REWRITE_TAC[APPEND];
      (* --- BASE OFFSET-EXIT: outlen < 256, p = 136 ---                     *)
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) < 256` ASSUME_TAC THENL
       [REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in c=`LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) <= 256` || c=`~(LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = 256)`))) THEN ARITH_TAC; ALL_TAC] THEN
      MP_TAC(SPEC `REJ_SAMPLE_ETA2_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
      ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
      REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = REJ_SAMPLE_ETA2_BYTES inlist`] THEN
      ENSURES_INIT_TAC "s0" THEN
      SUBGOAL_THEN `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list)):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list)):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
      SUBGOAL_THEN `&(val(word_zx(word 136:int64):int32)):int - &136 = &(val(word_sub(word_zx(word 136:int64):int32) (word 136):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (1--5) THEN
      ENSURES_FINAL_STATE_TAC THEN
      SUBGOAL_THEN `f_ev_scalar_tail 0 res buf pc (inlist:byte list) 136 =
          [EventJump (word (pc + 418),word (pc + 542)); EventJump (word (pc + 410),word (pc + 410))]` SUBST1_TAC THENL
       [MATCH_MP_TAC FEV_TAIL_OFFSET THEN
        SUBGOAL_THEN `SUB_LIST(0,136)(inlist:byte list) = inlist` SUBST1_TAC THENL
         [MATCH_MP_TAC SUB_LIST_BYTE_136 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[NOT_LE] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      REWRITE_TAC[LENGTH_BUTLAST_TMC_ETA2] THEN ASM_REWRITE_TAC[APPEND]];
    (* ================= STEP CASE: SUC d =================                  *)
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    ASM_CASES_TAC `256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)` THENL
     [(* --- STEP COUNT-EXIT: outlen >= 256 (=256 by invariant) --- *)
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256` ASSUME_TAC THENL
       [ASM_ARITH_TAC; ALL_TAC] THEN
      MP_TAC(SPECL [`inlist:byte list`; `p:num`] SUB_LIST_256_PREFIX_GE) THEN
      ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
      MP_TAC(SPEC `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list` SUB_LIST_256_LE) THEN
      ANTS_TAC THENL [ASM_REWRITE_TAC[LE_REFL]; ALL_TAC] THEN DISCH_TAC THEN
      SUBGOAL_THEN `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)` ASSUME_TAC THENL
       [ASM_REWRITE_TAC[]; ALL_TAC] THEN
      REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)`;
                  ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256`] THEN
      ENSURES_INIT_TAC "s0" THEN
      SUBGOAL_THEN `&(val(word_zx(word 256:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 256:int64):int32) (word 256):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
      X86_VSTEPS_TAC EXEC_ETA2 (1--3) THEN
      ENSURES_FINAL_STATE_TAC THEN
      SUBGOAL_THEN `f_ev_scalar_tail (SUC d) res buf pc (inlist:byte list) p = [EventJump (word (pc + 410),word (pc + 542))]` SUBST1_TAC THENL
       [MATCH_MP_TAC FEV_TAIL_COUNT THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256`; LENGTH_BUTLAST_TMC_ETA2] THEN
      ASM_REWRITE_TAC[APPEND];
      (* --- not count-exit: outlen < 256 ---                                *)
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) < 256` ASSUME_TAC THENL
       [ASM_ARITH_TAC; ALL_TAC] THEN
      ASM_CASES_TAC `p = 136` THENL
       [(* --- STEP OFFSET-EXIT: p = 136 --- *)
        FIRST_X_ASSUM(SUBST_ALL_TAC o check (fun th -> concl th = `p = 136`)) THEN
        MP_TAC(SPEC `inlist:byte list` SUB_LIST_BYTE_136) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
        RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `SUB_LIST(0,136) (inlist:byte list) = inlist`]) THEN
        REWRITE_TAC[ASSUME `SUB_LIST(0,136) (inlist:byte list) = inlist`] THEN
        MP_TAC(SPEC `REJ_SAMPLE_ETA2_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
        ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
        REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) = REJ_SAMPLE_ETA2_BYTES inlist`] THEN
        ENSURES_INIT_TAC "s0" THEN
        SUBGOAL_THEN `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list)):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA2_BYTES inlist:int32 list)):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
        SUBGOAL_THEN `&(val(word_zx(word 136:int64):int32)):int - &136 = &(val(word_sub(word_zx(word 136:int64):int32) (word 136):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
        X86_VSTEPS_TAC EXEC_ETA2 (1--5) THEN
        ENSURES_FINAL_STATE_TAC THEN
        SUBGOAL_THEN `f_ev_scalar_tail (SUC d) res buf pc (inlist:byte list) 136 =
            [EventJump (word (pc + 418),word (pc + 542)); EventJump (word (pc + 410),word (pc + 410))]` SUBST1_TAC THENL
         [MATCH_MP_TAC FEV_TAIL_OFFSET THEN
        SUBGOAL_THEN `SUB_LIST(0,136)(inlist:byte list) = inlist` SUBST1_TAC THENL
         [MATCH_MP_TAC SUB_LIST_BYTE_136 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[NOT_LE] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        REWRITE_TAC[LENGTH_BUTLAST_TMC_ETA2] THEN ASM_REWRITE_TAC[APPEND];
        (* --- p < 136 ---                                                   *)
        SUBGOAL_THEN `p < 136` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        ASM_CASES_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 15` THENL
         [(* --- STEP MID-BYTE EXIT: outlen=255, low<15 --- *)
          FIRST_X_ASSUM(CONJUNCTS_THEN ASSUME_TAC o check (fun th -> is_conj(concl th) && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))(concl th))) THEN
          SUBGOAL_THEN `256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list)` ASSUME_TAC THENL
           [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN
            ASM_REWRITE_TAC[] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `?rest. REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list =
             APPEND (APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                            [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]) rest`
           STRIP_ASSUME_TAC THENL
           [ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 15` THENL
             [EXISTS_TAC `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) DIV 16)) (word 5:int16))):int32]` THEN
              MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_BOTH_ETA2) THEN
              ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
              DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND; GSYM APPEND_ASSOC];
              EXISTS_TAC `[]:int32 list` THEN
              MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_LO_ETA2) THEN
              ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
              DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_NIL]]; ALL_TAC] THEN
          MP_TAC(SPECL [`inlist:byte list`; `p+1`] SUB_LIST_256_PREFIX_GE) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
          SUBGOAL_THEN `LENGTH(APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                            [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]:int32 list) = 256` ASSUME_TAC THENL
           [REWRITE_TAC[LENGTH_APPEND; LENGTH] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) =
               APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                      [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]` ASSUME_TAC THENL
           [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && (try lhs(concl th) = `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list)` with _->false) then SUBST1_TAC th else NO_TAC) THEN
            FIRST_X_ASSUM(fun th -> if is_eq(concl th) && (try lhs(concl th) = `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list` with _->false) then SUBST1_TAC th else NO_TAC) THEN
            W(fun (asl,gl) -> let lt = rhs gl in
               MATCH_MP_TAC EQ_TRANS THEN EXISTS_TAC (mk_comb(`SUB_LIST(0,256):(int32)list->(int32)list`, lt)) THEN
               CONJ_TAC THENL
                [MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_REWRITE_TAC[LE_REFL];
                 MATCH_MP_TAC SUB_LIST_256_LE THEN ASM_REWRITE_TAC[LE_REFL]]); ALL_TAC] THEN
          REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) =
                APPEND (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist))
                [word_sx (word_sub (word 2:int16) (word_umod (word (val (EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]`] THEN
          REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255`] THEN
          ENSURES_INIT_TAC "s0" THEN
          MP_TAC(ISPECL [`inlist:byte list`; `buf:int64`; `s0:x86state`; `p:num`; `136`] READ_1BYTE_EL_ETA2) THEN
          ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
          SUBGOAL_THEN `~(&(val(word_zx(word 255:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 255:int64):int32) (word 256):int32)))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
          SUBGOAL_THEN `~(&(val(word_zx(word p:int64):int32)):int - &136 = &(val(word_sub(word_zx(word p:int64):int32) (word 136):int32)))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
          X86_VSTEPS_TAC EXEC_ETA2 (1--8) THEN
          SUBGOAL_THEN `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64` ASSUME_TAC THENL
           [AP_TERM_TAC THEN AP_TERM_TAC THEN REWRITE_TAC[MULT_CLAUSES] THEN
            MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `p < 136`) THEN ARITH_TAC; ALL_TAC] THEN
          RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64`;
                                      ASSUME `read (memory :> bytes8 (word_add buf (word p))) s4 = EL p (inlist:byte list)`;
                                      R10_NIBBLE_VAL_ETA2]) THEN
          DISCARD_OLDSTATE_TAC "s8" THEN
          SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &15 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 15):int32)))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `val(word 255:int64) = 255` ASSUME_TAC THENL
           [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ARITH_TAC; ALL_TAC] THEN
          X86_VSTEPS_TAC EXEC_ETA2 (9--19) THEN
          FIRST_X_ASSUM(fun th -> let c=concl th in
             if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s19:x86state`))c
             then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC_ETA2 (ARITH_RULE `255<256`)] th) else NO_TAC) THEN
          SUBGOAL_THEN `&(val(word_zx(word(255+1):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(255+1):int64):int32) (word 256):int32))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_TAKEN_GE_ETA2 THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
          X86_VSTEPS_TAC EXEC_ETA2 (20--22) THEN
          ENSURES_FINAL_STATE_TAC THEN
          SUBGOAL_THEN `f_ev_scalar_tail (SUC d) res buf pc (inlist:byte list) p =
              [EventJump (word (pc + 481),word (pc + 542));
               EventStore (word_add res (word 1020),4);
               EventJump (word (pc + 438),word (pc + 438));
               EventLoad (word_add buf (word p),1);
               EventJump (word (pc + 418),word (pc + 418));
               EventJump (word (pc + 410),word (pc + 410))]` SUBST1_TAC THENL
           [MATCH_MP_TAC FEV_TAIL_MIDBYTE THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
          REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist:int32 list) =
                APPEND (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,p) inlist))
                [word_sx (word_sub (word 2:int16) (word_umod (word (val (EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]`] THEN
          CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
          REWRITE_TAC[ASSUME `LENGTH(APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]:int32 list) = 256`] THEN
          REWRITE_TAC[LENGTH_BUTLAST_TMC_ETA2] THEN ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
          [REPEAT CONJ_TAC THEN
          (* memory fold: bytes(res,4*256) = APPEND prefix [lo]              *)
          SUBGOAL_THEN `4 * 256 = 4 * 255 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
          MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s22:x86state`;
             `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list`;
             `[word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p (inlist:byte list)) MOD 16)) (word 5:int16))):int32]`;
             `4*255`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
          ANTS_TAC THENL [REWRITE_TAC[DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
          CONJ_TAC THENL
           [ASM_REWRITE_TAC[];
            SUBGOAL_THEN `word(4 * 255):int64 = word 1020` SUBST1_TAC THENL [CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
            ETA2_STORE_SPEC_TAC `s22:x86state` `val(EL p (inlist:byte list)) MOD 16` THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c)
               then MP_TAC th else NO_TAC) THEN
            ASM_REWRITE_TAC[] THEN
            STORE4_FROM_SPEC `s22:x86state` `word_add res (word 1020):int64`];
           REWRITE_TAC[APPEND] THEN ASM_REWRITE_TAC[]];
          (* --- STEP CLEAN-RECURSIVE: body trip then IH at p+1 ---          *)
          SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list) <= 256` ASSUME_TAC THENL
           [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN ASM_REWRITE_TAC[] THEN
            DISCH_THEN SUBST1_TAC THEN
            REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th -> let c=concl th in
               c = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) < 256` ||
               c = `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 15)`))) THEN
            REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN ARITH_TAC; ALL_TAC] THEN
          (* rewrite the goal's f_ev(SUC d) to expose the recursive APPEND    *)
          MP_TAC(SPECL[`d:num`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;`p:num`] FEV_TAIL_REC) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
          DISCH_THEN(fun th -> REWRITE_TAC[th; GSYM APPEND_ASSOC]) THEN
          (* body lemma instance at (p, outlen(p)) with events e             *)
          MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p:num`;
             `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)`;`stackpointer:int64`;`e:(uarch_event)list`] SCALAR_TAIL_BODY_SAFE_ETA2) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN(fun body_th ->
            let bodyQ = rand(rator(concl body_th)) in
            ENSURES_SEQUENCE_TAC `pc + 399` bodyQ THEN
            CONJ_TAC THENL
             [(* leg1: P -> bodyQ via the body lemma *)
              MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
              EXISTS_TAC (rand(rator(concl body_th))) THEN CONJ_TAC THENL
               [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
                MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN
                EXISTS_TAC (rand(rator(rator(concl body_th)))) THEN CONJ_TAC THENL
                 [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
                  ACCEPT_TAC body_th]];
              ALL_TAC]) THEN
          (* leg2: weaken pre to IH's expanded pre, then apply IH@(p+1) w/ e' *)
          W(fun (asl,g) ->
             let ih = snd(List.find (fun (_,th) -> is_forall(concl th) &&
                 can (find_term (fun x -> x = `136 - p <= d`)) (concl th)) asl) in
             let ih_inst = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p+1`;`stackpointer:int64`;
                 `APPEND (f_ev_scalar_body res buf pc (inlist:byte list) p (LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list))) (e:(uarch_event)list)`] ih in
             let ih_pre = rand(rator(rator(snd(dest_imp(concl ih_inst))))) in
             MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC ih_pre THEN CONJ_TAC THENL
              [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
               MP_TAC ih_inst THEN ANTS_TAC THENL
                [ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THEN TRY ASM_ARITH_TAC; DISCH_THEN ACCEPT_TAC]])]]]]);;


(* --- MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_SAFE --- *)
(* MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_SAFE — the scalar-tail SAFE         *)
(* (constant-time) contract at an arbitrary exit position p, a trivial        *)
(* corollary of SCALAR_TAIL_RUN_SAFE_ETA2 with budget d := 136 - p (136-p<=d  *)
(* by LE_REFL).  Events threaded deep-right; concrete tail events =           *)
(* f_ev_scalar_tail (136 - p) res buf pc inlist p.  Mirrors                   *)
(* MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_MEMSAFE.                            *)

let rec conj_append_right t ev =
  if is_conj t then
    let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let scalar_at_p_safe_eta2_tm =
  let qvars, body = strip_forall scalar_tail_at_p_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let fev = `f_ev_scalar_tail (136 - p) res buf pc (inlist:byte list) p` in
  let eq_pre = `read events (s:x86state) = e` in
  let eq_post = mk_eq(`read events (s:x86state)`,
                      mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)) in
  let pre' = mk_abs(sv, conj_append_right preb (vsubst[sv,`s:x86state`] eq_pre)) in
  let post' = mk_abs(sv2, conj_append_right postb (vsubst[sv2,`s:x86state`] eq_post)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

let MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_SAFE = prove
 (scalar_at_p_safe_eta2_tm,
  REPEAT STRIP_TAC THEN
  MP_TAC(SPECL [`136 - p`; `res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p:num`;`stackpointer:int64`;`e:(uarch_event)list`] SCALAR_TAIL_RUN_SAFE_ETA2) THEN
  ASM_REWRITE_TAC[LE_REFL]);;


(* --- MEMACCESS_F_EV_SCALAR_{BODY,TAIL} + HEADGUARD --- *)
(* MEMACCESS_F_EV_SCALAR_TAIL: per-budget memaccess bound for the eta2 scalar *)
(* tail's public event trace f_ev_scalar_tail.  Mirror of                     *)
(* MEMACCESS_F_EV_LOOP_ETA2 — the memaccess-recovery half that core_safe      *)
(* feeds into MEMACCESS_ENUM_ACC + MEMACCESS_INBOUNDS_APPEND.  Read window     *)
(* [buf,136; table,2048] and write window [res,1024] MATCH the loop's window  *)
(* lists (table unused by the tail, harmless).                                *)
(* ========================================================================= *)

(* -- containment helpers (STORE_CONTAINED / BUF_CONTAINED) -- *)

(* 4-byte compaction store  res + 4*cnt  within [res,1024]: 4*255 + 4 = 1024. *)
let STORE4_CONTAINED = prove
 (`!(res:int64) cnt. cnt <= 255
     ==> contained_modulo (2 EXP 64)
           (val(word_add res (word(4 * cnt))),4) (val res,1024)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

(* 1-byte input load  buf + p  within [buf,136]:  p < 136 ==> p + 1 <= 136. *)
let LOAD1_CONTAINED = prove
 (`!(buf:int64) p. p < 136
     ==> contained_modulo (2 EXP 64)
           (val(word_add buf (word p)),1) (val buf,136)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

(* -- trivial: the head-guard segment is Jumps-only -> in-bounds for any     --
   read/write windows.  A core_safe ingredient (mirrors the exit-block glue's
   f_ev_headguard segment; sits alongside MEMACCESS_ENUM_ACC + F_EV_LOOP +
   F_EV_SCALAR_TAIL for recovering the full-f_events memaccess).             *)
let MEMACCESS_F_EV_HEADGUARD = prove
 (`!pc rr wr. memaccess_inbounds (f_ev_headguard_eta2 pc) rr wr`,
  REWRITE_TAC[f_ev_headguard_eta2; memaccess_inbounds; ALL; EX; FST; SND]);;


(* ========================================================================= *)
(* Constant-time (SAFE) loop-side, mid-exit, exit-block, core, and           *)
(* SUBROUTINE_SAFE cluster.                                                   *)
(* ========================================================================= *)

(* ------------------------------------------------------------------------- *)
(* f_ev_loop_eta2 — the per-iteration PUBLIC events delta.                    *)
(* A fully type-annotated concrete definition, bound to the ML name           *)
(* f_ev_loop_eta2_def.                                                        *)
(* ------------------------------------------------------------------------- *)
let f_ev_loop_eta2_def = new_definition `((((=):(uarch_event)list->(uarch_event)list->bool) ((((((((f_ev_loop_eta2):(64)word->(64)word->(64)word->num->(bool)list->num->(uarch_event)list) (res:(64)word)) (buf:(64)word)) (table:(64)word)) (pc:num)) (mask:(bool)list)) (i:num))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (399:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (86:num)))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (339:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (339:num)))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (273:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (273:num)))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (207:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))))) (((int_of_num):num->int) (248:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (399:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (207:num))))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (buf:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (16:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (106:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))))) (((int_of_num):num->int) (120:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (((word):num->(32)word) (120:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (((word):num->(32)word) (120:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (399:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (106:num))))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (97:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))))) (((int_of_num):num->int) (248:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word):num->(32)word) (248:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word):num->(32)word) (248:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (399:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (97:num))))))) ((NIL):(uarch_event)list)))))))))))))))))))))`;;

let bs = map (fun k -> mk_var("b" ^ string_of_int k, `:bool`)) (0--31);;

(* --- Group-link bridges (pack_group) --- *)
let VAL_WORD_NIB16 = prove
 (`!x. x < 16 ==> val(word x:int16) = x`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
  MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC);;

let mk_group_link gm =
  let mb = eta2_mk_maskbit_forall gm in
  let boff = gm / 2 in
  let bytelist =
    mk_list(map (fun j -> subst[mk_small_numeral(8*(boff+j)),`OFF:num`]
                   `word_subword (chunk0:int128) (OFF,8):byte`) (0--3), `:byte`) in
  let sublhs = subst[mk_small_numeral boff, `BOFF:num`]
                 `SUB_LIST(16*i+BOFF,4) (inlist:byte list)` in
  let link = mk_eq(sublhs, bytelist) in
  let lhs_bits =
    mk_list(map (fun k -> subst[mk_small_numeral(8*(k+gm)),`OFF:num`]
                   `bit 7 (word_subword (f1bnd:int256) (OFF,8):byte)`) (0--7), `:bool`) in
  let moff = 32*0 + gm in
  ignore moff;
  let rhs = subst[mk_small_numeral gm, `GM:num`]
              `SUB_LIST(32*i+GM,8)(REJ_MASK_ETA2 (inlist:byte list))` in
  mk_imp(mb, mk_imp(link, mk_eq(lhs_bits, rhs)));;

let VAL_WORD_NIB_LO = prove
 (`!w:byte. val(word(val w MOD 16):int16) = val w MOD 16`,
  GEN_TAC THEN MATCH_MP_TAC VAL_WORD_NIB16 THEN
  MP_TAC(SPECL[`val(w:byte)`;`16`] MOD_LT_EQ) THEN ARITH_TAC);;
let VAL_WORD_NIB_HI = prove
 (`!w:byte. val(word(val w DIV 16):int16) = val w DIV 16`,
  GEN_TAC THEN MATCH_MP_TAC VAL_WORD_NIB16 THEN
  MP_TAC(ISPEC `w:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

let prove_group_link gm =
  let goal = mk_group_link gm in
  let boff = gm / 2 in
  let arith_off = ARITH_RULE(mk_eq(
      `2 * (16 * i + BOFF)`, `32 * i + GM`)
      |> subst[mk_small_numeral boff,`BOFF:num`; mk_small_numeral gm,`GM:num`]) in
  let rhs_reduced = subst[mk_small_numeral boff,`BOFF:num`]
                      `REJ_MASK_ETA2(SUB_LIST(16*i+BOFF,4) (inlist:byte list))` in
  let goal_rhs = subst[mk_small_numeral gm,`GM:num`]
                   `SUB_LIST(32*i+GM,8)(REJ_MASK_ETA2 (inlist:byte list))` in
  prove(goal,
    DISCH_THEN(fun mb -> DISCH_THEN(fun link ->
      SUBGOAL_THEN (mk_eq(goal_rhs, rhs_reduced)) SUBST1_TAC THENL
       [ONCE_REWRITE_TAC[REJ_MASK_ETA2_SUB_LIST] THEN
        REWRITE_TAC[arith_off] THEN CONV_TAC NUM_REDUCE_CONV;
        ALL_TAC] THEN
      REWRITE_TAC[link] THEN
      REWRITE_TAC[REJ_MASK_ETA2; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; MAP] THEN
      REWRITE_TAC[VAL_WORD_NIB_LO; VAL_WORD_NIB_HI] THEN
      (let mbs = map (fun k -> let th = SPEC (mk_small_numeral k) mb in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
       REWRITE_TAC mbs) THEN
      REFL_TAC)));;

let ETA2_PACK_GROUP0 = prove_group_link 0;;
let ETA2_PACK_GROUP1 = prove_group_link 8;;
let ETA2_PACK_GROUP2 = prove_group_link 16;;
let ETA2_PACK_GROUP3 = prove_group_link 24;;

(* --- BYTE0_DIVMOD (build_p0) --- *)
let BYTE0_DIVMOD = prove
 (`!p:num->bool.
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) MOD 256 =
    bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
    16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7)`,
  GEN_TAC THEN
  SUBGOAL_THEN
   `(bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) =
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7)) +
    256 * (bitval(p 8) + 2*bitval(p 9) + 4*bitval(p 10) + 8*bitval(p 11) +
     16*bitval(p 12) + 32*bitval(p 13) + 64*bitval(p 14) + 128*bitval(p 15) +
     256*(bitval(p 16) + 2*bitval(p 17) + 4*bitval(p 18) + 8*bitval(p 19) +
     16*bitval(p 20) + 32*bitval(p 21) + 64*bitval(p 22) + 128*bitval(p 23) +
     256*(bitval(p 24) + 2*bitval(p 25) + 4*bitval(p 26) + 8*bitval(p 27) +
     16*bitval(p 28) + 32*bitval(p 29) + 64*bitval(p 30) + 128*bitval(p 31))))`
   SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  MATCH_MP_TAC ADD256_MOD THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [0;1;2;3;4;5;6;7] THEN ARITH_TAC);;

(* --- STORE_BRIDGE + GATHER_BRIDGE1 (bridge_values) --- *)
let STORE_BRIDGE = prove
 (`!inlist:byte list. !B.
     LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,B) inlist):int32 list) =
     NUM_ACCEPTED(SUB_LIST(0,2*B)(REJ_MASK_ETA2 inlist))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; LENGTH_REJ_NIBBLES_ETA2_EQ_MASK;
              NUM_ACCEPTED] THEN
  REWRITE_TAC[REJ_MASK_ETA2_SUB_LIST; MULT_CLAUSES]);;

let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)`;;
let byte1_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE1_DIVMOD);;
let bigsum = lhand(lhand(lhand(concl byte1_inst)));;
let tower8 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64`;;

let GATHER_BRIDGE1 = prove
 (mk_imp(mk_eq(tower8,`mask8b:int64`),
   mk_imp(eta2_mk_maskbit_forall 8,
    mk_imp(`SUB_LIST(16*i+4,4) (inlist:byte list) =
             [word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
              word_subword chunk0 (48,8); word_subword chunk0 (56,8)]`,
      `val (mask8b:int64) MOD 256 =
       PACK_MASK8(SUB_LIST(32*i+8,8)(REJ_MASK_ETA2 (inlist:byte list)))`))),
  STRIP_TAC THEN STRIP_TAC THEN STRIP_TAC THEN
  FIRST_X_ASSUM(SUBST1_TAC o SYM o
    check (fun th -> try rand(concl th) = `mask8b:int64` with _ -> false)) THEN
  REWRITE_TAC[MASK_SHIFT8_MOD256] THEN
  MP_TAC(SPEC pinst BYTE1_DIVMOD) THEN
  CONV_TAC(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
  DISCH_THEN SUBST1_TAC THEN
  W(fun (asl,w) ->
     let mb = find (fun th -> is_forall(concl th)) (map snd asl) in
     let link = find (fun th -> is_eq(concl th) &&
        (try fst(dest_const(fst(strip_comb(lhand(concl th))))) = "SUB_LIST"
         with _ -> false)) (map snd asl) in
     let pg = MP (MP (SPEC_ALL ETA2_PACK_GROUP1) mb) link in
     GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM pg]) THEN
  REWRITE_TAC[PACK_MASK8] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;

(* --- GATHER_BRIDGE2/3 (gather_all) --- *)
let byte2_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE2_DIVMOD);;
let byte3_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE3_DIVMOD);;
let bigsum = lhand(lhand(lhand(concl byte2_inst)));;

let link_of gm =
  let boff = gm / 2 in
  mk_eq(subst[mk_small_numeral boff,`BOFF:num`] `SUB_LIST(16*i+BOFF,4)(inlist:byte list)`,
        mk_list(map (fun j -> subst[mk_small_numeral(8*(boff+j)),`OFF:num`]
                       `word_subword (chunk0:int128) (OFF,8):byte`) (0--3), `:byte`));;

let prove_gather gm maskv shiftlem byteinst packgrp tower =
  let goal =
    mk_imp(mk_eq(tower, maskv),
     mk_imp(eta2_mk_maskbit_forall gm,
      mk_imp(link_of gm,
        mk_eq(mk_comb(mk_comb(`MOD`,mk_comb(`val:int64->num`,maskv)),`256`),
              subst[mk_small_numeral gm,`GM:num`]
                `PACK_MASK8(SUB_LIST(32*i+GM,8)(REJ_MASK_ETA2 (inlist:byte list)))`)))) in
  prove(goal,
    STRIP_TAC THEN STRIP_TAC THEN STRIP_TAC THEN
    FIRST_X_ASSUM(SUBST1_TAC o SYM o
      check (fun th -> try rand(concl th) = maskv with _ -> false)) THEN
    REWRITE_TAC[shiftlem] THEN
    MP_TAC byteinst THEN DISCH_THEN SUBST1_TAC THEN
    W(fun (asl,w) ->
       let mb = find (fun th -> is_forall(concl th)) (map snd asl) in
       let link = find (fun th -> is_eq(concl th) &&
          (try fst(dest_const(fst(strip_comb(lhand(concl th))))) = "SUB_LIST"
           with _ -> false)) (map snd asl) in
       let pg = MP (MP (SPEC_ALL packgrp) mb) link in
       GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM pg]) THEN
    REWRITE_TAC[PACK_MASK8] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;

let tower16 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64):int32) 8):int64`;;
let tower24 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64):int32) 8):int64):int32) 8):int64`;;

let GATHER_BRIDGE2 = prove_gather 16 `mask8c:int64` MASK_SHIFT16_MOD256 byte2_inst ETA2_PACK_GROUP2 tower16;;
let GATHER_BRIDGE3 = prove_gather 24 `mask8d:int64` MASK_SHIFT24_MOD256 byte3_inst ETA2_PACK_GROUP3 tower24;;

(* ------------------------------------------------------------------------- *)
(* Events-bridge linchpin: f_ev_loop_eta2 (above) + P0_BRIDGE +               *)
(* ETA2_EVENTS_BRIDGE.  P0_BRIDGE is a fully type-annotated term proved by     *)
(* the build_p0 tactic; ETA2_EVENTS_BRIDGE is proved by EB_TAC, which          *)
(* rebuilds the 9 value facts (P0_BRIDGE / GATHER_BRIDGE1-3 / STORE_BRIDGE +   *)
(* a niblen identity) from the stripped antecedent and rewrites raw->public.   *)
(* ------------------------------------------------------------------------- *)

let MS0 = prove
 (`!S:num. val(word_zx(word S:int32):int64) MOD 256 = S MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`; MOD_MOD_EXP_MIN] THEN
  CONV_TAC NUM_REDUCE_CONV);;

let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)`;;

let P0_BRIDGE = prove(`((((==>):bool->bool->bool) (((!):(num->bool)->bool) (\(k:num). ((((==>):bool->bool->bool) ((((<):num->num->bool) (k:num)) (8:num))) ((((=):bool->bool->bool) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) ((((*):num->num->num) (8:num)) ((((+):num->num->num) (k:num)) (0:num)))) (8:num))))) ((((<):num->num->bool) ((((EL):num->(num)list->num) (k:num)) ((((CONS):num->(num)list->(num)list) ((((MOD):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (0:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((DIV):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (0:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((MOD):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (8:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((DIV):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (8:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((MOD):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (16:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((DIV):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (16:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((MOD):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (24:num)) (8:num))))) (16:num))) ((((CONS):num->(num)list->(num)list) ((((DIV):num->num->num) (((val):(8)word->num) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (24:num)) (8:num))))) (16:num))) ((NIL):(num)list))))))))))) (15:num))))))) ((((==>):bool->bool->bool) ((((=):((8)word)list->((8)word)list->bool) ((((SUB_LIST):num#num->((8)word)list->((8)word)list) ((((,):num->num->num#num) ((((*):num->num->num) (16:num)) (i:num))) (4:num))) (inlist:((8)word)list))) ((((CONS):(8)word->((8)word)list->((8)word)list) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (0:num)) (8:num)))) ((((CONS):(8)word->((8)word)list->((8)word)list) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (8:num)) (8:num)))) ((((CONS):(8)word->((8)word)list->((8)word)list) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (16:num)) (8:num)))) ((((CONS):(8)word->((8)word)list->((8)word)list) ((((word_subword):(128)word->num#num->(8)word) (chunk0:(128)word)) ((((,):num->num->num#num) (24:num)) (8:num)))) ((NIL):((8)word)list))))))) ((((=):num->num->bool) ((((MOD):num->num->num) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word):num->(32)word) ((((+):num->num->num) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (0:num)) (8:num)))))) ((((+):num->num->num) ((((*):num->num->num) (2:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (8:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (4:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (16:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (8:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (24:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (16:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (32:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (40:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (64:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (48:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (128:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (56:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (256:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (64:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (512:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (72:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (1024:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (80:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (2048:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (88:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (4096:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (96:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (8192:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (104:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (16384:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (112:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (32768:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (120:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (65536:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (128:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (131072:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (136:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (262144:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (144:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (524288:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (152:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (1048576:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (160:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (2097152:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (168:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (4194304:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (176:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (8388608:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (184:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (16777216:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (192:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (33554432:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (200:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (67108864:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (208:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (134217728:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (216:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (268435456:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (224:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (536870912:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (232:num)) (8:num))))))) ((((+):num->num->num) ((((*):num->num->num) (1073741824:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (240:num)) (8:num))))))) ((((*):num->num->num) (2147483648:num)) (((bitval):bool->num) ((((bit):num->(8)word->bool) (7:num)) ((((word_subword):(256)word->num#num->(8)word) (f1bnd:(256)word)) ((((,):num->num->num#num) (248:num)) (8:num))))))))))))))))))))))))))))))))))))))))) (256:num))) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (((REJ_MASK_ETA2):((8)word)list->(bool)list) (inlist:((8)word)list)))))))`,
  STRIP_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[MS0] THEN
  MP_TAC(SPEC pinst BYTE0_DIVMOD) THEN
  CONV_TAC(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
  DISCH_THEN SUBST1_TAC THEN
  W(fun (asl,w) ->
     let mb = find (fun th -> is_forall(concl th)) (map snd asl) in
     let link = find (fun th -> is_eq(concl th) &&
        (try fst(dest_const(fst(strip_comb(lhand(concl th))))) = "SUB_LIST" with _ -> false)) (map snd asl) in
     let pg0 = REWRITE_RULE[ARITH_RULE `16*i+0 = 16*i`; ARITH_RULE `32*i+0 = 32*i`] (SPEC_ALL ETA2_PACK_GROUP0) in
     let pg = MP (MP pg0 mb) link in
     GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM pg]) THEN
  REWRITE_TAC[PACK_MASK8] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;

let EB_TAC : tactic =
  STRIP_TAC THEN REWRITE_TAC[f_ev_loop_eta2_def] THEN
  W(fun (asl,w) ->
    let assoc_asl = map snd asl in
    let fnd p = find (fun th -> p (concl th)) assoc_asl in
    let tower8_mask8b = fnd (fun c -> is_eq c && rand c=`mask8b:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false)) c) in
    let mask8c_def = fnd (fun c -> is_eq c && rand c=`mask8c:int64`) in
    let mask8d_def = fnd (fun c -> is_eq c && rand c=`mask8d:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false)) c) in
    let mb g = fnd (fun c -> is_forall c && can(find_term(fun u->u=`f1bnd:int256`)) c && can(find_term(fun u->u = mk_binop `( * ):num->num->num` `8` (mk_binop `(+):num->num->num` `k:num` (mk_small_numeral g)))) c) in
    let ol_def = fnd (fun c -> is_eq c && rand c=`outlen0:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA2_BYTES",_)->true|_->false)) c) in
    let a1_def = fnd (fun c -> is_eq c && rand c=`acc1:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA2_BYTES",_)->true|_->false)) c) in
    let a2_def = fnd (fun c -> is_eq c && rand c=`acc2:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA2_BYTES",_)->true|_->false)) c) in
    let a3_def = fnd (fun c -> is_eq c && rand c=`acc3:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA2_BYTES",_)->true|_->false)) c) in
    let i_le = fnd (fun c -> c = `16 * i <= 120`) in
    let leninl = fnd (fun c -> c = `LENGTH(inlist:byte list) = 136`) in
    let blk16 = fnd (fun c -> is_eq c && (try fst(dest_const(fst(strip_comb(lhand c))))="SUB_LIST" && length(dest_list(rand c))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
    let links = CONJUNCTS bb in
    let t16m8c = REWRITE_RULE[SYM tower8_mask8b] mask8c_def in
    let t24m8d = REWRITE_RULE[SYM t16m8c] mask8d_def in
    let f0 = MP (MP P0_BRIDGE (mb 0)) (el 0 links) in
    let f1 = MP (MP (MP GATHER_BRIDGE1 tower8_mask8b) (mb 8)) (el 1 links) in
    let f2 = MP (MP (MP GATHER_BRIDGE2 t16m8c) (mb 16)) (el 2 links) in
    let f3 = MP (MP (MP GATHER_BRIDGE3 t24m8d) (mb 24)) (el 3 links) in
    let so = TRANS (SYM ol_def) (REWRITE_RULE[ARITH_RULE `2*(16*i)=32*i`] (SPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE)) in
    let s1 = TRANS (SYM a1_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+4)=32*i+8`] (SPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE)) in
    let s2 = TRANS (SYM a2_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+8)=32*i+16`] (SPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE)) in
    let s3 = TRANS (SYM a3_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+12)=32*i+24`] (SPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE)) in
    let niblen0_gen = prove
     (`LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i,4) inlist):int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA2 (inlist:byte list)))`,
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED] THEN
      REWRITE_TAC[REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2*(16*i)=32*i`; ARITH_RULE `2*4=8`]) in
    let niblen0 = REWRITE_RULE[el 0 links] niblen0_gen in
    let facts = [f0;f1;f2;f3;so;s1;s2;s3;niblen0] in
    CONV_TAC(LAND_CONV(GEN_REWRITE_CONV TOP_DEPTH_CONV facts THENC REWRITE_CONV[]))) THEN
  REFL_TAC;;

let ETA2_EVENTS_BRIDGE = prove(
`(((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 0)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (0,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (0,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (8,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (8,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (16,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (16,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (24,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (24,8)):(8)word)) DIV 16)]) < 15)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 16)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (64,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (64,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (72,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (72,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (80,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (80,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (88,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (88,8)):(8)word)) DIV 16)]) < 15)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 8)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (32,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (32,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (40,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (40,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (48,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (48,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (56,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (56,8)):(8)word)) DIV 16)]) < 15)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 24)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (96,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (96,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (104,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (104,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (112,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (112,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (120,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (120,8)):(8)word)) DIV 16)]) < 15)))) /\
(((16 * i) <= 120) /\
(((SUB_LIST ((16 * i),16) (inlist:((8)word)list)) = [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word);
((word_subword (chunk0:(128)word) (32,8)):(8)word);
((word_subword (chunk0:(128)word) (40,8)):(8)word);
((word_subword (chunk0:(128)word) (48,8)):(8)word);
((word_subword (chunk0:(128)word) (56,8)):(8)word);
((word_subword (chunk0:(128)word) (64,8)):(8)word);
((word_subword (chunk0:(128)word) (72,8)):(8)word);
((word_subword (chunk0:(128)word) (80,8)):(8)word);
((word_subword (chunk0:(128)word) (88,8)):(8)word);
((word_subword (chunk0:(128)word) (96,8)):(8)word);
((word_subword (chunk0:(128)word) (104,8)):(8)word);
((word_subword (chunk0:(128)word) (112,8)):(8)word);
((word_subword (chunk0:(128)word) (120,8)):(8)word)]) /\
(((LENGTH (inlist:((8)word)list)) = 136) /\
(((LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,(16 * i)) (inlist:((8)word)list)))) = outlen0) /\
(((LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,((16 * i) + 8)) (inlist:((8)word)list)))) = acc2) /\
(((LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,((16 * i) + 4)) (inlist:((8)word)list)))) = acc1) /\
(((LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,((16 * i) + 12)) (inlist:((8)word)list)))) = acc3) /\
((((word_zx (word_ushr ((word_zx (mask8b:(64)word)):(32)word) 8)):(64)word) = (mask8c:(64)word)) /\
((((word_zx (word_ushr ((word_zx (mask8c:(64)word)):(32)word) 8)):(64)word) = (mask8d:(64)word)) /\
(((word_zx (word_ushr ((word_zx ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)):(32)word) 8)):(64)word) = (mask8b:(64)word))))))))))))))) ==>
([(EventJump (((word (pc + 399)):(64)word),((word (pc + 86)):(64)word)));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8d:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc3)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8d:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 339)):(64)word),((word (pc + 339)):(64)word)));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8c:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc2)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8c:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 273)):(64)word),((word (pc + 273)):(64)word)));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8b:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc1)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8b:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 207)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA2 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word))) (&248)) = (&(val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA2 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word)))))) \/ ((val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA2 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word))) = 0))) then ((word (pc + 399)):(64)word) else ((word (pc + 207)):(64)word))));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * outlen0)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventLoad ((word_add (buf:(64)word) ((word (16 * i)):(64)word)),16));
(EventJump (((word (pc + 106)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word (16 * i)):(64)word)):(32)word))) (&120)) = (&(val (word_sub ((word_zx ((word (16 * i)):(64)word)):(32)word) ((word 120):(32)word)))))) \/ ((val (word_sub ((word_zx ((word (16 * i)):(64)word)):(32)word) ((word 120):(32)word))) = 0))) then ((word (pc + 399)):(64)word) else ((word (pc + 106)):(64)word))));
(EventJump (((word (pc + 97)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word outlen0):(64)word)):(32)word))) (&248)) = (&(val (word_sub ((word_zx ((word outlen0):(64)word)):(32)word) ((word 248):(32)word)))))) \/ ((val (word_sub ((word_zx ((word outlen0):(64)word)):(32)word) ((word 248):(32)word))) = 0))) then ((word (pc + 399)):(64)word) else ((word (pc + 97)):(64)word))))] = (f_ev_loop_eta2 (res:(64)word) (buf:(64)word) (table:(64)word) pc (REJ_MASK_ETA2 (inlist:((8)word)list)) i)))`,
  EB_TAC);;

(* --- memacc helpers --- *)
let NUM_ACCEPTED_PREFIX_MONO = prove
 (`!mask:bool list a b. a <= b
     ==> NUM_ACCEPTED(SUB_LIST(0,a) mask) <= NUM_ACCEPTED(SUB_LIST(0,b) mask)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `SUB_LIST(0,b) (mask:bool list) =
                APPEND (SUB_LIST(0,a) mask) (SUB_LIST(a,b-a) mask)` SUBST1_TAC THENL
   [MP_TAC(ISPECL [`mask:bool list`; `a:num`; `b - a`; `0`] SUB_LIST_SPLIT) THEN
    ASM_SIMP_TAC[ARITH_RULE `a <= b ==> a + (b - a) = b`; ADD_CLAUSES];
    REWRITE_TAC[NUM_ACCEPTED_APPEND] THEN ARITH_TAC]);;

let STORE_CONTAINED = prove
 (`!(res:int64) cnt. cnt <= 248
     ==> contained_modulo (2 EXP 64)
           (val(word_add res (word(4 * cnt))),32) (val res,1024)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

let BUF_CONTAINED = prove
 (`!(buf:int64) j. 16 * j + 16 <= 136
     ==> contained_modulo (2 EXP 64)
           (val(word_add buf (word(16 * j))),16) (val buf,136)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

let PACK_MASK8_MOD256 = prove
 (`!bs:bool list. PACK_MASK8 bs = PACK_MASK8 bs MOD 256`,
  GEN_TAC THEN MATCH_MP_TAC(GSYM MOD_LT) THEN REWRITE_TAC[PACK_MASK8_BOUND]);;

let MEMACCESS_F_EV_LOOP_ETA2 = prove
 (`!res buf table pc mask j.
     16 * j + 16 <= 136 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * j + 24) mask) <= 248
     ==> memaccess_inbounds (f_ev_loop_eta2 res buf table pc mask j)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * j) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * j + 8) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * j + 16) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [REPEAT CONJ_TAC THEN
    TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * j + 24) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[f_ev_loop_eta2_def; memaccess_inbounds; ALL; EX; FST; SND] THEN
  ONCE_REWRITE_TAC[PACK_MASK8_MOD256] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC STORE_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ1_TAC THEN MATCH_MP_TAC BUF_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN
    MATCH_ACCEPT_TAC TABLE_IDX_LT_256]);;

(* --- SAFE clean-block defs/closer + ETA2_CLEAN_BLOCK_SAFE --- *)
(* ETA2_SAFE_CLOSER references ETA2_EVENTS_BRIDGE (the events-bridge linchpin   *)
(* above).                                                                      *)
let clean_block_safe_eta2_tm =
  let qvars, body = strip_forall clean_block_eta2_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let pretempl = `read events (s:x86state) = (e:(uarch_event)list)` in
  let posttempl =
    `read events (s:x86state) =
       APPEND (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i)
              (e:(uarch_event)list) /\
     memaccess_inbounds
       (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i)
       [(buf:int64),136; (table:int64),2048] [(res:int64),1024]` in
  let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] pretempl)) in
  let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] posttempl)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

let ETA2_SAFE_STEP_TAC : tactic =
  mk_eta2_prefix_to_s11 false THEN
  ETA2_SI1_FOLD THEN ETA2_SI1_COUNTER_MS_TAC THEN
  ETA2_SI2_FOLD THEN ETA2_SI2_COUNTER_TAC THEN
  ETA2_SI3_FOLD THEN ETA2_SI3_COUNTER_TAC THEN
  ETA2_SI4_FOLD THEN ETA2_SI4_COUNTER_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ARITH_RULE `16*i+16 = 16*(i+1)`]) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  CONJ_TAC THENL [ETA2_RAX_FINAL_TAC; ALL_TAC] THEN
  CONJ_TAC THENL [ETA2_RCX_FINAL_TAC; ALL_TAC];;

let ETA2_SAFE_CLOSER : tactic =
  MP_TAC ETA2_EVENTS_BRIDGE THEN
  ANTS_TAC THENL
   [ REPEAT CONJ_TAC THEN FIRST_ASSUM ACCEPT_TAC;
     DISCH_THEN(fun bridge ->
       CONJ_TAC THENL
        [ REWRITE_TAC[GSYM bridge; APPEND] THEN
          (REFL_TAC ORELSE FIRST_ASSUM ACCEPT_TAC ORELSE ASM_REWRITE_TAC[APPEND]);
          REWRITE_TAC[GSYM bridge] THEN
          REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
          REPEAT CONJ_TAC THEN
          TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                      CONTAINED_ASM_TAC) THEN NO_TAC) THEN
          GATHER_BOUND_TAC ]) ];;

let ETA2_CLEAN_BLOCK_SAFE =
  prove(clean_block_safe_eta2_tm, ETA2_SAFE_STEP_TAC THEN ETA2_SAFE_CLOSER);;

(* --- SAFE loop scaffold + ETA2_LOOP_SAFE + MEMACCESS_ENUM_ACC --- *)
let SAFE_THREAD_EVENTS_STEP = prove
 (`!(d:num->(uarch_event)list) i e.
      APPEND (d i) (APPEND (ENUMERATEL i d) e) = APPEND (ENUMERATEL (i+1) d) e`,
  REWRITE_TAC[ENUMERATEL_ADD1; APPEND_ASSOC]);;

let ev_concrete_eta2 =
  `read events (s:x86state) =
     APPEND (ENUMERATEL i (f_ev_loop_eta2 res buf table pc
              (REJ_MASK_ETA2 (inlist:byte list)))) (e:(uarch_event)list)`;;

let SAFE_LOOPINV_ETA2 =
  let iv,rest = dest_abs CORRECT_LOOPINV_ETA2 in
  let sv,body = dest_abs rest in
  mk_abs(iv, mk_abs(sv,
    conj_append_right body (vsubst[sv,`s:x86state`; iv,`i:num`] ev_concrete_eta2)));;

let loop_safe_eta2_tm =
  let qvars,body = strip_forall core_ms_eta2_tm in
  let hyps_tm,ens = dest_imp body in
  let ensc,ppf = strip_comb ens in
  let pre = el 1 ppf and frame = el 3 ppf in
  let wop = `!m. m < N ==> 16 * m <= 120 /\
               LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let hyps' = list_mk_conj (conjuncts hyps_tm @ [`~(N = 0)`; `~(N = 1)`; wop]) in
  let sv = `s:x86state` in
  let svp,preb = dest_abs pre in
  let pre' = mk_abs(svp, conj_append_right preb
    (vsubst[svp,sv] `read RSP (s:x86state) = stackpointer`)) in
  let iv2,rest2 = dest_abs SAFE_LOOPINV_ETA2 in
  let sv2,invbody = dest_abs rest2 in
  let inv_body = vsubst[`N-1`,iv2; sv,sv2] invbody in
  let post = mk_abs(sv, list_mk_conj
    [ `bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc)`;
      `read RIP s = word(pc + 86)`;
      inv_body ]) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post; frame]) in
  list_mk_forall(qvars @ [`N:num`; `stackpointer:int64`], mk_imp(hyps', ens'));;

let G2_SAFE_BODY_BRIDGE_ETA2_TAC : tactic =
  REPEAT STRIP_TAC THEN
  MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`i:num`;`stackpointer:int64`;
     `APPEND (ENUMERATEL i (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 inlist))) (e:(uarch_event)list)`]
     ETA2_CLEAN_BLOCK_SAFE) THEN
  ANTS_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `i+1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN STRIP_TAC THEN
    REPEAT CONJ_TAC THEN
    (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC; ASM_REWRITE_TAC[]]); ALL_TAC] THEN
  DISCH_THEN(fun bth ->
    W(fun (asl,gl) ->
      let lframe = rand(concl bth) in
      let lpost  = rand(rator(concl bth)) in
      let lpre   = rand(rator(rator(concl bth))) in
      let gframe = rand gl in
      let subsumed_tm = mk_binop `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool` lframe gframe in
      let subsumed_th = prove(subsumed_tm,
        REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN SUBSUMED_MAYCHANGE_TAC) in
      let bth' = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
      CONJ_TAC THENL
       [GEN_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN TRY(ASM_MESON_TAC[]);
        MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
        CONJ_TAC THENL
         [GEN_TAC THEN STRIP_TAC THEN
          ASM_REWRITE_TAC[GSYM SAFE_THREAD_EVENTS_STEP] THEN TRY(ASM_MESON_TAC[]);
          ACCEPT_TAC bth']]));;

let SAFE_LOOP_SCAFFOLD_ETA2_TAC : tactic =
  MAP_EVERY X_GEN_TAC [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                       `e:(uarch_event)list`;`pc:num`;`N:num`;`stackpointer:int64`] THEN
  REWRITE_TAC[C_ARGUMENTS; C_RETURN; SOME_FLAGS; NONOVERLAPPING_CLAUSES;
              LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC] THEN
  STRIP_TAC THEN
  ENSURES_WHILE_UP_TAC `N - 1` `pc + 86` `pc + 86` SAFE_LOOPINV_ETA2 THEN
  REPEAT CONJ_TAC THENL
   [REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th->concl th=`~(N=0)`||concl th=`~(N=1)`))) THEN ARITH_TAC;
    ENSURES_INIT_TAC "s0" THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--10) THEN
    X86_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s11" THEN
    X86_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s12" THEN
    COLLAPSE_VPBW_TAC `read YMM6 s12` YMM6_CONST_ETA2 THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (13--13) THEN
    X86_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s14" THEN
    X86_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s15" THEN
    COLLAPSE_VPBW_TAC `read YMM7 s15` YMM7_CONST_ETA2 THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (16--17) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES; REJ_SAMPLE_ETA2_BYTES;
                REJ_NIBBLES_ETA2; NIBBLES_OF_BYTES; FILTER; MAP; LENGTH; num_of_wordlist] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_MEMORY_BYTES_TRIVIAL] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    ASM_REWRITE_TAC[ENUMERATEL; APPEND];
    G2_SAFE_BODY_BRIDGE_ETA2_TAC;
    REPEAT STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];
    ENSURES_INIT_TAC "s0" THEN ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[]];;

let ETA2_LOOP_SAFE = prove(loop_safe_eta2_tm, SAFE_LOOP_SCAFFOLD_ETA2_TAC);;

let MEMACCESS_ENUM_ACC = prove
 (`!(d:num->(uarch_event)list) rr wr J.
     (!j. j < J ==> memaccess_inbounds (d j) rr wr)
     ==> memaccess_inbounds (ENUMERATEL J d) rr wr`,
  REPLICATE_TAC 3 GEN_TAC THEN INDUCT_TAC THENL
   [REWRITE_TAC[ENUMERATEL; memaccess_inbounds; ALL];
    REWRITE_TAC[ADD1] THEN ONCE_REWRITE_TAC[ENUMERATEL_ADD1] THEN
    REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN STRIP_TAC THEN CONJ_TAC THENL
     [FIRST_X_ASSUM MATCH_MP_TAC THEN ARITH_TAC;
      FIRST_X_ASSUM MATCH_MP_TAC THEN GEN_TAC THEN DISCH_TAC THEN
      FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC]]);;

(* --- EXIT_OFFSET_SAFE_ETA2 (+ bridges) --- *)
let ev_append_op = `APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`;;
let tail_events_e1 =
  `APPEND (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) (N-1))
          (e:(uarch_event)list)`;;
let tail_events_e2 = mk_comb(mk_comb(ev_append_op,`f_ev_headguard_eta2 pc`), tail_events_e1);;
let scalar_tail_events = `f_ev_scalar_tail (136 - 128) res buf pc (inlist:byte list) 128`;;
let exit_events_offset = mk_comb(mk_comb(ev_append_op, scalar_tail_events), tail_events_e2);;

let q86_pred_e1  = vsubst[tail_events_e1,`ec:(uarch_event)list`] q86_safe_eta2;;
let q399_pred_e1 = vsubst[tail_events_e1,`ec:(uarch_event)list`] q399_safe_eta2;;

let rej_eta_result =
  `\s:x86state.
    let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES (inlist:byte list)) in
    read RAX s = word(LENGTH outlist) /\
    read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist`;;

let exit_offset_safe_eta2_tm =
  let exoff_ms = snd(strip_forall exit_offset_ms_eta2_tm) in
  let hyps_tm, ens = dest_imp exoff_ms in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let pre_val = lhand preb in
  let pre' = mk_abs(sv, mk_conj(pre_val, vsubst[sv,`s:x86state`] `read events (s:x86state) = e`)) in
  let sv2, postb = dest_abs post in
  let post_rip = lhand postb in
  let post_ev = vsubst[sv2,`s:x86state`] (mk_eq(`read events (s:x86state)`, exit_events_offset)) in
  let post' =
    add_rej_eta_result rej_eta_result (mk_abs(sv2, mk_conj(post_rip, post_ev))) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps_tm, list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame])));;

let EXIT_BRIDGE_CLOSE_TAC : tactic =
  GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN RULE_ASSUM_TAC BETA_RULE THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `16 * N = 128`]) THEN ASM_REWRITE_TAC[];;

let SAFE_BRIDGE_FROM_ETA2 (bth:thm) : tactic =
  W(fun (asl,gl) ->
    let lframe = rand(concl bth) in
    let lpost  = rand(rator(concl bth)) in
    let lpre   = rand(rator(rator(concl bth))) in
    let gframe = rand gl in
    let subsumed_tm = mk_binop `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool` lframe gframe in
    let subsumed_th = prove(subsumed_tm,
      REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN SUBSUMED_MAYCHANGE_TAC) in
    let bth' = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
    MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
    CONJ_TAC THENL
     [EXIT_BRIDGE_CLOSE_TAC;
      MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
      CONJ_TAC THENL [EXIT_BRIDGE_CLOSE_TAC; ACCEPT_TAC bth']]);;

let SCALAR_TAIL_LEG2_SAFE_ETA2 (p:term) (etail:term) : tactic =
  W(fun (asl,gl) ->
    let atp = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;p;`stackpointer:int64`;etail]
                    MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_SAFE in
    let atp_ens = snd(dest_imp(concl atp)) in
    let _,ppf = strip_comb atp_ens in
    let atp_pre = el 1 ppf and atp_post = el 2 ppf in
    MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC atp_post THEN
    CONJ_TAC THENL
     [EXIT_BRIDGE_CLOSE_TAC;
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC atp_pre THEN
      CONJ_TAC THENL
       [EXIT_BRIDGE_CLOSE_TAC;
        MP_TAC atp THEN
        ANTS_TAC THENL
         [REPEAT CONJ_TAC THEN
          (fun (a,g) ->
             if is_le256_rej g then (FIRST [FIRST_ASSUM ACCEPT_TAC; CLOSE_LE256_TAC]) (a,g)
             else (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]) (a,g));
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_FRAME_SUBSUMED) THEN
          REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
          SUBSUMED_MAYCHANGE_TAC]]]);;

let EXIT_OFFSET_SAFE_ETA2 = prove(exit_offset_safe_eta2_tm,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `~(N = 0)` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * N = 128` THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list) <= 248` then ACCEPT_TAC th else NO_TAC); ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,128) inlist):int32 list) <= 248` ASSUME_TAC THENL
   [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
    SUBST1_TAC(ASSUME `16 * N = 128`) THEN REWRITE_TAC[]; ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC q399_pred_e1 THEN
  CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN CONJ_TAC THENL
   [MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC q86_pred_e1 THEN
    CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN CONJ_TAC THENL
     [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`] ETA2_CLEAN_BLOCK_SAFE) THEN
      SUBGOAL_THEN `N - 1 + 1 = N` (fun th -> REWRITE_TAC[th]) THENL [ASM_ARITH_TAC; ALL_TAC] THEN
      ANTS_TAC THENL
       [REPEAT CONJ_TAC THEN (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
      DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA2 bth);
      MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`stackpointer:int64`;`e:(uarch_event)list`; tail_events_e1] LEG1B_HEADGUARD_SAFE_ETA2) THEN
      ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
      DISCH_THEN ACCEPT_TAC];
    SCALAR_TAIL_LEG2_SAFE_ETA2 `128` tail_events_e2]);;

(* --- f_ev_midexit_subiter{1..4} + MEMACCESS_F_EV_MIDEXIT --- *)
let feld138 = SPEC_ALL f_ev_loop_eta2_def;;
let evs138 = dest_list (rand(concl feld138));;
let ejc138 = rator (el 0 evs138);;
let w399_138 = fst(dest_pair(rand(el 0 evs138)));;
let midsrc138 j = fst(dest_pair(rand(el j evs138)));;
let xover138 src = mk_comb(ejc138, mk_pair(src, w399_138));;
let evty138 = type_of (el 0 evs138);;
let midlist138 idxs headx =
  mk_list(headx :: map (fun j -> el j evs138) idxs, evty138);;

let mid_lhs_vars138 = [`res:int64`;`buf:int64`;`table:int64`;`pc:num`;`mask:bool list`;`i:num`];;
let mkmiddef138 name l =
  let listty = type_of l in
  let fnty = itlist (fun v ty -> mk_fun_ty (type_of v) ty) mid_lhs_vars138 listty in
  define(mk_eq(list_mk_comb(mk_var(name, fnty), mid_lhs_vars138), l));;

let f_ev_midexit_subiter1 =
  mkmiddef138 "f_ev_midexit_subiter1"
    (midlist138 [13;14;15;16;17;18] (xover138 (midsrc138 12)));;
let f_ev_midexit_subiter2 =
  mkmiddef138 "f_ev_midexit_subiter2"
    (midlist138 [9;10;11;12;13;14;15;16;17;18] (xover138 (midsrc138 8)));;
let f_ev_midexit_subiter3 =
  mkmiddef138 "f_ev_midexit_subiter3"
    (midlist138 [5;6;7;8;9;10;11;12;13;14;15;16;17;18] (xover138 (midsrc138 4)));;
let f_ev_midexit_subiter4 =
  mkmiddef138 "f_ev_midexit_subiter4"
    (midlist138 [0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18] (xover138 (midsrc138 18)));;

let MIDEXIT_MEMACC_CORE_TAC (def:thm) : tactic =
  REWRITE_TAC[def; memaccess_inbounds; ALL; EX; FST; SND] THEN
  ONCE_REWRITE_TAC[PACK_MASK8_MOD256] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC STORE_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ1_TAC THEN MATCH_MP_TAC BUF_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN MATCH_ACCEPT_TAC TABLE_IDX_LT_256];;

let MEMACCESS_F_EV_MIDEXIT_SUBITER1 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 136 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter1 res buf table pc mask i)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN MIDEXIT_MEMACC_CORE_TAC f_ev_midexit_subiter1);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER2 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 136 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter2 res buf table pc mask i)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248` ASSUME_TAC THENL
   [TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC f_ev_midexit_subiter2);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER3 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 136 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter3 res buf table pc mask i)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [CONJ_TAC THEN TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC f_ev_midexit_subiter3);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER4 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 136 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 24) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter4 res buf table pc mask i)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [REPEAT CONJ_TAC THEN TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 24) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC f_ev_midexit_subiter4);;

(* --- The 4 MID_EXIT_SUBITER SAFE arms --- *)
let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

let midexit_safe_eta2_tm value_tm fev_tm =
  let qvars, body = strip_forall value_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let pretempl = `read events (s:x86state) = (e:(uarch_event)list)` in
  let posttempl =
    mk_conj(`read events (s:x86state) = APPEND FEV (e:(uarch_event)list)`,
            `memaccess_inbounds FEV [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`) in
  let posttempl = subst [fev_tm, `FEV:(uarch_event)list`] posttempl in
  let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] pretempl)) in
  let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] posttempl)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

let midexit1_safe_eta2_tm =
  midexit_safe_eta2_tm midexit1_eta2_tm
    `f_ev_midexit_subiter1 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i`;;

let ETA2_MIDEXIT_OPEN_SAFE_TAC : tactic =
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `16 * i <= 120` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  MP_TAC(SPECL [`buf:int64`;`136`;`inlist:byte list`;`i:num`;`s0:x86state`] SUB_LIST_16_BYTES_FROM_INT128) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC; ALL_TAC] THEN
  ABBREV_TAC `chunk0 = read(memory:>bytes128(word_add buf (word(16*i)))) s0` THEN DISCH_TAC THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) <= 248` ASSUME_TAC THENL
   [FIRST [FIRST_ASSUM ACCEPT_TAC;
           (FIRST_X_ASSUM(fun th -> match concl th with
              Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),k) when k=`248`
                -> MP_TAC th | _ -> NO_TAC) THEN
            MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
            MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
  ABBREV_TAC `outlen0 = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)` THEN
  FIRST_ASSUM(fun th -> if concl th =
      `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) = outlen0`
    then (RULE_ASSUM_TAC(REWRITE_RULE[th]) THEN ASSUME_TAC th) else NO_TAC) THEN
  MP_TAC(SPECL [`outlen0:num`;`248`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
  MP_TAC(SPECL [`16*i`;`120`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
  VAL_INT64_TAC `outlen0:num` THEN
  X86_STEPS_TAC EXEC (1--2) THEN
  SUBGOAL_THEN `read RIP s2 = word(pc + 97):int64` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&248:int`))(concl th)
                           then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
    FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 399`))(concl th) &&
                              (match concl th with
                                 Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s2",_))),_) -> true
                               | _ -> false)
                            then MP_TAC th else NO_TAC) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
  X86_STEPS_TAC EXEC (3--4) THEN
  SUBGOAL_THEN `read RIP s4 = word(pc + 106):int64` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&120:int`))(concl th)
                           then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
    FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 399`))(concl th) &&
                              (match concl th with
                                 Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s4",_))),_) -> true
                               | _ -> false)
                            then MP_TAC th else NO_TAC) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC];;

let ETA2_MIDEXIT_PREFIX_SAFE_TAC : tactic =
  ETA2_MIDEXIT_OPEN_SAFE_TAC THEN
  X86_VSTEPS_TAC EXEC (5--5) THEN
  SUBGOAL_THEN `val(word(16*i):int64) = 16*i` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
    UNDISCH_TAC `16*i <= 120` THEN ARITH_TAC; ALL_TAC] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word(16*i):int64) = 16*i`; ARITH_RULE `1 * x = x`]) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read (memory :> bytes128 (word_add buf (word (16 * i)))) s4 = chunk0`]) THEN
  SUBGOAL_THEN `read YMM0 s5 = usimd16 (\b:byte. word_zx b:int16) chunk0:int256` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && can(find_term((=)`read YMM0 s5`))(lhand(concl th)) then SUBST1_TAC th else NO_TAC) THEN
    REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
    CONV_TAC WORD_BLAST; ALL_TAC] THEN
  DROP_WORDJOIN_TAC THEN PURGE_STALE_STATES_TAC ["s4"] THEN
  X86_VSTEPS_TAC EXEC (6--6) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s5 = usimd16 (\b:byte. word_zx b:int16) chunk0:int256`]) THEN
  X86_VSTEPS_TAC EXEC (7--7) THEN X86_VSTEPS_TAC EXEC (8--8) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM3 s5 =
    word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256`]) THEN
  SUBGOAL_THEN (mk_eq(`read YMM0 s8:int256`, F0NIB_CHUNK0)) ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && can(find_term((=)`read YMM0 s8`))(lhand(concl th)) then SUBST1_TAC th else NO_TAC) THEN
    REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
    CONV_TAC WORD_BLAST; ALL_TAC] THEN
  DROP_WORDJOIN_TAC THEN PURGE_STALE_STATES_TAC ["s5";"s6";"s7"] THEN
  X86_VSTEPS_TAC EXEC (9--9) THEN
  ABBREV_TAC `f1bnd:int256 = read YMM1 s9` THEN
  ETA2_MASKBIT_ASSUME_TAC 0 THEN
  ETA2_MASKBIT_ASSUME_TAC 8 THEN
  ETA2_MASKBIT_ASSUME_TAC 16 THEN
  ETA2_MASKBIT_ASSUME_TAC 24 THEN
  REPEAT(FIRST_X_ASSUM(fun th ->
     if is_eq(concl th) && lhand(concl th) = `f1bnd:int256`
     then ALL_TAC else failwith "keep")) THEN
  X86_VSTEPS_TAC EXEC (10--10) THEN
  X86_VSTEPS_TAC EXEC (11--11) THEN
  ABBREV_TAC `f0sub:int256 = read YMM0 s11` THEN
  eta2_gather_block g1_eta2 (eta2_ellist 0)  false THEN
  eta2_gather_block g2_eta2 (eta2_ellist 32) true THEN
  eta2_gather_block g3_eta2 (eta2_ellist 64) false THEN
  eta2_gather_block g4_eta2 (eta2_ellist 96) true THEN
  ETA2_SI1_FOLD;;

let SUBITER1_BODY_TAC : tactic =
  SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 256` ASSUME_TAC THENL
   [MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER_ETA2 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
   [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 256` THEN ARITH_TAC; ALL_TAC] THEN
  X86_STEPS_TAC EXEC (21--24) THEN
  MP_TAC(ISPECL[`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES) THEN
  ANTS_TAC THENL
   [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `LENGTH(inlist:byte list) = 136` THEN
    UNDISCH_TAC `16 * i <= 120` THEN ARITH_TAC; STRIP_TAC] THEN
  W(fun (asl,w) ->
     let m8def = find (fun th -> match concl th with Comb(Comb(Const("=",_),_),Var("mask8",_)) -> true | _ -> false) (map snd asl) in
     RULE_ASSUM_TAC(fun th -> if concl th = maskbit_tgt ||
        can(find_term(fun u->match u with Const("TABLE_ENTRY",_)->true|_->false))(concl th)
        then th else REWRITE_RULE[GSYM m8def] th)) THEN
  W(fun (asl,w) ->
    let r9 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("R9",_)),Var("s24",_))),_) -> true | _ -> false) asl in
    let goal_pc = find_term (fun t -> match t with Comb(Const("word_popcount",_),_) -> true | _ -> false) (concl(snd r9)) in
    let low8 = `bitval(bit 7 (word_subword (f1bnd:int256) (0,8):byte)) + bitval(bit 7 (word_subword f1bnd (8,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (16,8):byte)) + bitval(bit 7 (word_subword f1bnd (24,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (32,8):byte)) + bitval(bit 7 (word_subword f1bnd (40,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (48,8):byte)) + bitval(bit 7 (word_subword f1bnd (56,8):byte))` in
    let mr = CONV_RULE(DEPTH_CONV BETA_CONV THENC NUM_REDUCE_CONV)
               (SPEC `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` MOD_RED) in
    let popeq = prove(mk_eq(goal_pc, low8),
      REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
      REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`; MOD_MOD_EXP_MIN] THEN
      CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
      REWRITE_TAC[ARITH_RULE `2 EXP 8 = 256`; mr] THEN
      MAP_EVERY (fun b -> BOOL_CASES_TAC b)
        [`bit 7 (word_subword (f1bnd:int256) (0,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (8,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (16,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (24,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (32,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (40,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (48,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (56,8):byte)`] THEN
      REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV) in
    let maskbit = snd(find (fun (_,th) -> let c=concl th in is_forall c &&
        can(find_term(fun u->u=`f1bnd:int256`))c && can(find_term(fun u->match u with Comb(Const("bit",_),_)->true|_->false))c &&
        not(can(find_term(fun u->match u with Const("word_zx",_)->true|_->false))c) &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c)) asl) in
    let mb_tm = concl maskbit in
    let blk0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
           (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
    let blkeq = mk_eq(low8, `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)`) in
    let blk0_tm = concl(snd blk0) in
    let bsum_raw = prove(mk_imp(mb_tm, mk_imp(blk0_tm, blkeq)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN DISCH_THEN(fun b -> REWRITE_TAC[b]) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
      ASM_SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let bsum = MP (MP bsum_raw maskbit) (snd blk0) in
    let pop_len = TRANS popeq bsum in
    ASSUME_TAC pop_len) THEN
  SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i`] SUBITER_BRIDGE_ETA2) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i) inlist):int32 list) = outlen0` THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list) < 2 EXP 32` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
    UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32` THEN REWRITE_TAC[]; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block0len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `outlen0:num` block0len in
    let lt32 = snd(find (fun (_,th) -> concl th = mk_binop `(<):num->num->bool` sum `2 EXP 32`) asl) in
    let pop_len = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let bridge = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_) -> true | _ -> false) asl) in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let gt248 = REWRITE_RULE[SYM bridge] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`) asl)) in
    let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
    ASSUME_TAC pop_len THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
  X86_STEPS_TAC EXEC (25--26) THEN
  SUBGOAL_THEN `read RIP s26 = word (pc + 399):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let blk0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
             (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let ja = find (fun (_,th) -> is_neg(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`248`))(concl th)) asl in
      let ifrip = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s26",_))),r) ->
           (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asl in
      MP_TAC (snd ifrip) THEN
      REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
      REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  W(fun (asl,w) ->
    let blk0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
           (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
    let rax_red0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
    let bridge = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_) -> true | _ -> false) asl in
    REWRITE_TAC[GSYM(snd blk0); snd rax_red0; snd bridge]) THEN
  W(fun (asl,w) ->
    let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                   (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`)
                         (ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32`)) in
    REWRITE_TAC[ntake]) THEN
  SUBGOAL_THEN `val(word(16*i):int64) = 16*i` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
  MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN
  ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]);;

let MID_EXIT_SUBITER1_SAFE_CLOSER : tactic =
  CONJ_TAC THENL
   [FIRST_ASSUM(fun a1 -> FIRST_ASSUM(fun a2 -> ASSUME_TAC(MP (MP P0_BRIDGE a1) a2))) THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE));
      ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter1; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER1 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`]
               (ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

let MID_EXIT_SUBITER1_SAFE_ETA2 = prove(midexit1_safe_eta2_tm,
  ETA2_MIDEXIT_PREFIX_SAFE_TAC THEN SUBITER1_BODY_TAC THEN MID_EXIT_SUBITER1_SAFE_CLOSER);;

(* --- SUBITER2 (s140) --- *)
let midexit2_safe_eta2_tm =
  midexit_safe_eta2_tm midexit2_eta2_tm
    `f_ev_midexit_subiter2 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i`;;

let MP_BRIDGE_FROM_ASL (bridge:thm) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let rec go th =
      if is_imp (concl th) then
        let ante = lhand (concl th) in
        let a = try find (fun a -> aconv (concl a) ante) asms
                with Failure _ ->
                  failwith ("MP_BRIDGE_FROM_ASL: unmatched antecedent: " ^
                            string_of_term ante) in
        go (MP th a)
      else th in
    ASSUME_TAC (go bridge));;

let SUBITER2_SAFE_DISCH : tactic =
  CONJ_TAC THENL
   [MP_BRIDGE_FROM_ASL P0_BRIDGE THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter2; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER2 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`]
               (ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

let MID_EXIT_SUBITER2_SAFE_ETA2 = prove(midexit2_safe_eta2_tm,
  mk_midexit2_eta2 true ETA2_MIDEXIT_PREFIX_SAFE_TAC SUBITER2_SAFE_DISCH);;

(* --- SUBITER3 (s142) --- *)
let midexit3_safe_eta2_tm =
  midexit_safe_eta2_tm midexit3_eta2_tm
    `f_ev_midexit_subiter3 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i`;;

let ASSUME_MASK_TOWERS : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let fnd p = find (fun th -> p (concl th)) asms in
    let tower8_mask8b = fnd (fun c -> is_eq c && rand c = `mask8b:int64` &&
        can (find_term (fun u -> match u with Const("word_ushr",_)->true|_->false)) c) in
    let mask8c_def = fnd (fun c -> is_eq c && rand c = `mask8c:int64`) in
    let t16m8c = REWRITE_RULE[SYM tower8_mask8b] mask8c_def in
    let t24opt =
      try let mask8d_def = fnd (fun c -> is_eq c && rand c = `mask8d:int64` &&
            can (find_term (fun u -> match u with Const("word_ushr",_)->true|_->false)) c) in
          [REWRITE_RULE[SYM t16m8c] mask8d_def]
      with Failure _ -> [] in
    EVERY (map ASSUME_TAC (t16m8c :: t24opt)));;

let SUBITER3_SAFE_DISCH : tactic =
  CONJ_TAC THENL
   [ASSUME_MASK_TOWERS THEN
    MP_BRIDGE_FROM_ASL P0_BRIDGE THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE2 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc2 = NUM_ACCEPTED(SUB_LIST(0,32*i+16)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 8) inlist):int32 list) = acc2` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`](ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
              word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+8,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 4,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter3; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER3 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`]
               (ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

let MID_EXIT_SUBITER3_SAFE_ETA2 = prove(midexit3_safe_eta2_tm,
  mk_midexit3_eta2 true ETA2_MIDEXIT_PREFIX_SAFE_TAC SUBITER3_SAFE_DISCH);;

(* --- SUBITER4 (s143) --- *)
let midexit4_safe_eta2_tm =
  midexit_safe_eta2_tm midexit4_eta2_tm
    `f_ev_midexit_subiter4 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) i`;;

let SUB4_MG3_REDUCE : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
    let blk2_eq = el 2 (CONJUNCTS bb) in
    let ident = find_a (fun th -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),Var("acc3",_)) -> true
        | _ -> false) in
    let acc3_le = find_a (fun th -> concl th = `acc3 <= 248`) in
    let bnd_sublist = REWRITE_RULE[SYM ident] acc3_le in
    let bnd_chunk = REWRITE_RULE[blk2_eq] bnd_sublist in
    let sum = lhand(concl bnd_chunk) in
    let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd_chunk in
    let rax_red = MATCH_MP RAX_NEST_REDUCE lt32 in
    let ja = MP (ISPECL [sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd_chunk (ARITH_RULE `248 < 2 EXP 32`)) in
    REWRITE_TAC[rax_red; ja]);;

let SUB4_EVENTS_CLOSER : tactic =
    ASSUME_MASK_TOWERS THEN
    MP_BRIDGE_FROM_ASL P0_BRIDGE THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE2 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE3 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc2 = NUM_ACCEPTED(SUB_LIST(0,32*i+16)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 8) inlist):int32 list) = acc2` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`](ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN `acc3 = NUM_ACCEPTED(SUB_LIST(0,32*i+24)(REJ_MASK_ETA2 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,16 * i + 12) inlist):int32 list) = acc3` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 12) = 32 * i + 24`](ISPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
              word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+8,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 4,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA2 [word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
              word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+16,8)(REJ_MASK_ETA2 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 8,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA2_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA2_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUB4_MG3_REDUCE THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter4; APPEND];;

let SUB4_MEMACCESS_CLOSER : tactic =
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER4 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 12) = 32 * i + 24`]
               (ISPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]];;

let SUBITER4_SAFE_DISCH : tactic =
  W(fun (asl,w) -> if is_eq w then SUB4_EVENTS_CLOSER else SUB4_MEMACCESS_CLOSER);;

let MID_EXIT_SUBITER4_SAFE_ETA2 = prove(midexit4_safe_eta2_tm,
  mk_midexit4_eta2 true ETA2_MIDEXIT_PREFIX_SAFE_TAC SUBITER4_SAFE_DISCH);;

(* --- nibble<->mask bridges --- *)
let LENGTH_NIBBLES_OF_BYTES = prove
 (`!l:byte list. LENGTH(NIBBLES_OF_BYTES l) = 2 * LENGTH l`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; LENGTH; LENGTH_APPEND] THEN
  ARITH_TAC);;

let EL_NIBBLES_OF_BYTES = prove
 (`!(l:byte list) p. p < LENGTH l
     ==> EL (2*p) (NIBBLES_OF_BYTES l) = (word(val(EL p l) MOD 16):int16) /\
         EL (2*p+1) (NIBBLES_OF_BYTES l) = (word(val(EL p l) DIV 16):int16)`,
  LIST_INDUCT_TAC THENL
   [REWRITE_TAC[LENGTH; LT];
    GEN_TAC THEN REWRITE_TAC[LENGTH] THEN
    STRUCT_CASES_TAC(SPEC `p:num` num_CASES) THEN
    REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THENL
     [REWRITE_TAC[ARITH_RULE `2 * 0 = 0`; ARITH_RULE `2 * 0 + 1 = SUC 0`;
                  EL; HD; TL];
      REWRITE_TAC[LT_SUC] THEN DISCH_TAC THEN
      REWRITE_TAC[ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`;
                  ARITH_RULE `2 * SUC n + 1 = SUC(SUC(2*n+1))`;
                  EL; TL; HD] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `n:num`) THEN ASM_REWRITE_TAC[]]]);;

let REJ_MASK_EL_ETA2 = prove
 (`!(l:byte list) p. p < LENGTH l
     ==> (EL (2*p)   (REJ_MASK_ETA2 l) <=> val(EL p l) MOD 16 < 15) /\
         (EL (2*p+1) (REJ_MASK_ETA2 l) <=> val(EL p l) DIV 16 < 15)`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  MP_TAC(SPECL [`l:byte list`; `p:num`] EL_NIBBLES_OF_BYTES) THEN
  ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
  REWRITE_TAC[REJ_MASK_ETA2] THEN
  SUBGOAL_THEN `2 * p < LENGTH(NIBBLES_OF_BYTES(l:byte list)) /\
                2 * p + 1 < LENGTH(NIBBLES_OF_BYTES(l:byte list))` STRIP_ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_NIBBLES_OF_BYTES] THEN
    UNDISCH_TAC `p < LENGTH(l:byte list)` THEN ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[EL_MAP] THEN ASM_REWRITE_TAC[] THEN
  MP_TAC(ISPEC `EL p (l:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
  DISCH_TAC THEN
  MP_TAC(SPECL [`val(EL p (l:byte list))`; `16`] DIVISION) THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN STRIP_TAC THEN
  SUBGOAL_THEN
    `val(word(val(EL p (l:byte list)) MOD 16):int16) = val(EL p l) MOD 16 /\
     val(word(val(EL p (l:byte list)) DIV 16):int16) = val(EL p l) DIV 16`
    STRIP_ASSUME_TAC THENL
   [CONJ_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN MATCH_MP_TAC MOD_LT THEN
    CONV_TAC(RAND_CONV NUM_REDUCE_CONV) THEN ASM_ARITH_TAC;
    ASM_REWRITE_TAC[]]);;

let newrhs_body =
  let eqn = snd(strip_forall(concl f_ev_scalar_body)) in
  let _,rhs = dest_eq eqn in
  let condlo = `val(EL p (inlist:byte list)) MOD 16 < 15` in
  let condhi = `val(EL p (inlist:byte list)) DIV 16 < 15` in
  subst [`EL (2*p) (mask:bool list)`, condlo;
         `EL (2*p+1) (mask:bool list)`, condhi] rhs;;

let f_ev_scalar_body_mask =
  let fty = `:int64->int64->num->(bool)list->num->num->(uarch_event)list` in
  let hd = mk_var("f_ev_scalar_body_mask", fty) in
  let lhs = list_mk_comb(hd, [`res:int64`;`buf:int64`;`pc:num`;
                              `mask:bool list`;`p:num`;`outlen0:num`]) in
  define (mk_eq(lhs, newrhs_body));;

let FEV_SCALAR_BODY_MASK = prove
 (`!res buf pc (inlist:byte list) p outlen0.
     p < LENGTH inlist
     ==> f_ev_scalar_body res buf pc inlist p outlen0 =
         f_ev_scalar_body_mask res buf pc (REJ_MASK_ETA2 inlist) p outlen0`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[f_ev_scalar_body; f_ev_scalar_body_mask] THEN
  ASM_SIMP_TAC[REJ_MASK_EL_ETA2]);;

let f_ev_scalar_tail_mask = define
 `(f_ev_scalar_tail_mask 0 (res:int64) (buf:int64) (pc:num) (mask:bool list) (p:num) =
     (if 256 <= NUM_ACCEPTED(SUB_LIST(0,2*p) mask)
      then [EventJump (word (pc + 410),word (pc + 542))]
      else [EventJump (word (pc + 418),word (pc + 542));
            EventJump (word (pc + 410),word (pc + 410))])) /\
  (f_ev_scalar_tail_mask (SUC d) (res:int64) (buf:int64) (pc:num) (mask:bool list) (p:num) =
     (if 256 <= NUM_ACCEPTED(SUB_LIST(0,2*p) mask)
      then [EventJump (word (pc + 410),word (pc + 542))]
      else if p = 136
      then [EventJump (word (pc + 418),word (pc + 542));
            EventJump (word (pc + 410),word (pc + 410))]
      else if NUM_ACCEPTED(SUB_LIST(0,2*p) mask) = 255 /\ EL (2*p) mask
      then [EventJump (word (pc + 481),word (pc + 542));
            EventStore (word_add res (word 1020),4);
            EventJump (word (pc + 438),word (pc + 438));
            EventLoad (word_add buf (word p),1);
            EventJump (word (pc + 418),word (pc + 418));
            EventJump (word (pc + 410),word (pc + 410))]
      else APPEND (f_ev_scalar_tail_mask d res buf pc mask (p+1))
                  (f_ev_scalar_body_mask res buf pc mask p
                     (NUM_ACCEPTED(SUB_LIST(0,2*p) mask)))))`;;

let FEV_SCALAR_TAIL_MASK = prove
 (`!d res buf pc (inlist:byte list) p.
     LENGTH inlist = 136 /\ p <= 136
     ==> f_ev_scalar_tail d res buf pc inlist p =
         f_ev_scalar_tail_mask d res buf pc (REJ_MASK_ETA2 inlist) p`,
  INDUCT_TAC THEN REPEAT GEN_TAC THEN STRIP_TAC THENL
   [REWRITE_TAC[f_ev_scalar_tail; f_ev_scalar_tail_mask; STORE_BRIDGE];
    ASM_CASES_TAC `p = 136` THENL
     [ASM_REWRITE_TAC[f_ev_scalar_tail; f_ev_scalar_tail_mask; STORE_BRIDGE];
      SUBGOAL_THEN `p < LENGTH(inlist:byte list) /\ p + 1 <= 136` STRIP_ASSUME_TAC THENL
       [ASM_ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[f_ev_scalar_tail; f_ev_scalar_tail_mask] THEN
      REWRITE_TAC[STORE_BRIDGE] THEN
      SUBGOAL_THEN
        `f_ev_scalar_tail d res buf pc inlist (p+1) =
         f_ev_scalar_tail_mask d res buf pc (REJ_MASK_ETA2 inlist) (p+1)`
        SUBST1_TAC THENL
       [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ASM_SIMP_TAC[REJ_MASK_EL_ETA2; FEV_SCALAR_BODY_MASK]]]);;

(* --- mask-side memacc (STORE4/LOAD1_CONTAINED) --- *)
let MEMACCESS_F_EV_SCALAR_BODY_MASK = prove
 (`!res buf table pc (mask:bool list) p outlen0.
     p < 136 /\ outlen0 <= 255 /\
     ~(outlen0 = 255 /\ EL (2 * p) mask)
     ==> memaccess_inbounds (f_ev_scalar_body_mask res buf pc mask p outlen0)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[f_ev_scalar_body_mask] THEN REPEAT COND_CASES_TAC THEN
  ASM_REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [DISJ1_TAC THEN MATCH_MP_TAC LOAD1_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    MATCH_MP_TAC STORE4_CONTAINED THEN
    TRY(FIRST_X_ASSUM
         ((fun th -> MP_TAC th THEN ASM_REWRITE_TAC[]) o
          check (fun th -> is_neg(concl th) && is_conj(rand(concl th))))) THEN
    ASM_ARITH_TAC]);;

let MEMACCESS_F_EV_SCALAR_TAIL_MASK = prove
 (`!d res buf table pc (mask:bool list) p.
     p + d <= 136
     ==> memaccess_inbounds (f_ev_scalar_tail_mask d res buf pc mask p)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  INDUCT_TAC THENL
   [REPEAT GEN_TAC THEN STRIP_TAC THEN
    REWRITE_TAC[f_ev_scalar_tail_mask] THEN COND_CASES_TAC THEN
    REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    REWRITE_TAC[f_ev_scalar_tail_mask] THEN REPEAT COND_CASES_TAC THENL
     [REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
      REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
      REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN REPEAT CONJ_TAC THEN
      FIRST [REWRITE_TAC[ARITH_RULE `1020 = 4 * 255`] THEN
             MATCH_MP_TAC STORE4_CONTAINED THEN ARITH_TAC;
             DISJ1_TAC THEN MATCH_MP_TAC LOAD1_CONTAINED THEN ASM_ARITH_TAC];
      REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN CONJ_TAC THENL
       [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
        MATCH_MP_TAC MEMACCESS_F_EV_SCALAR_BODY_MASK THEN REPEAT CONJ_TAC THENL
         [ASM_ARITH_TAC; ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC]]]]);;

let f_ev_exit = define
 `f_ev_exit (res:int64) (buf:int64) (table:int64) (pc:num) (mask:bool list) (N:num)
    : (uarch_event)list =
    if NUM_ACCEPTED(SUB_LIST(0,32 * N) mask) <= 248
    then APPEND (f_ev_scalar_tail_mask (136 - 16 * N) res buf pc mask (16 * N))
                (APPEND (f_ev_headguard_eta2 pc)
                        (f_ev_loop_eta2 res buf table pc mask (N-1)))
    else if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8) mask) <= 248
    then (if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16) mask) <= 248
          then (if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24) mask) <= 248
                then APPEND (f_ev_scalar_tail_mask (136 - 16 * N) res buf pc mask (16 * N))
                            (f_ev_midexit_subiter4 res buf table pc mask (N-1))
                else APPEND (f_ev_scalar_tail_mask (136 - (16 * (N-1) + 12)) res buf pc mask
                              (16 * (N-1) + 12))
                            (f_ev_midexit_subiter3 res buf table pc mask (N-1)))
          else APPEND (f_ev_scalar_tail_mask (136 - (16 * (N-1) + 8)) res buf pc mask
                        (16 * (N-1) + 8))
                      (f_ev_midexit_subiter2 res buf table pc mask (N-1)))
    else APPEND (f_ev_scalar_tail_mask (136 - (16 * (N-1) + 4)) res buf pc mask
                  (16 * (N-1) + 4))
                (f_ev_midexit_subiter1 res buf table pc mask (N-1))`;;

let MEMACCESS_F_EV_EXIT = prove
 (`!res buf table pc (mask:bool list) N.
     16 * N <= 136 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1)) mask) <= 248
     ==> memaccess_inbounds (f_ev_exit res buf table pc mask N)
           [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  REPEAT COND_CASES_TAC THEN
  REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC MEMACCESS_F_EV_SCALAR_TAIL_MASK THEN ASM_ARITH_TAC;
    MATCH_ACCEPT_TAC MEMACCESS_F_EV_HEADGUARD;
    MATCH_MP_TAC MEMACCESS_F_EV_LOOP_ETA2 THEN CONJ_TAC THENL
     [ASM_ARITH_TAC;
      MATCH_MP_TAC LE_TRANS THEN
      EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32 * N) (mask:bool list))` THEN
      CONJ_TAC THENL
       [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ASM_ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER1 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER2 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER3 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER4 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC]]);;

(* --- events bridges + exists helpers --- *)
let OFFSET_EVENTS_BRIDGE = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 136 /\ 16 * N = 128 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248
     ==> APPEND (f_ev_scalar_tail (136 - 128) res buf pc inlist 128)
                (APPEND (f_ev_headguard_eta2 pc)
                        (APPEND (f_ev_loop_eta2 res buf table pc
                                   (REJ_MASK_ETA2 (inlist:byte list)) (N-1))
                                (e:(uarch_event)list)))
         = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`136 - 128`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;`128`]
               FEV_SCALAR_TAIL_MASK) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT1_EVENTS_BRIDGE = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
                (APPEND (f_ev_midexit_subiter1 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`136 - (16 * (N-1) + 4)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 4`] FEV_SCALAR_TAIL_MASK) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT2_EVENTS_BRIDGE = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
                (APPEND (f_ev_midexit_subiter2 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`136 - (16 * (N-1) + 8)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 8`] FEV_SCALAR_TAIL_MASK) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT3_EVENTS_BRIDGE = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
                (APPEND (f_ev_midexit_subiter3 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`136 - (16 * (N-1) + 12)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 12`] FEV_SCALAR_TAIL_MASK) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT4_EVENTS_BRIDGE = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248
     ==> APPEND (f_ev_scalar_tail (136 - 16 * N) res buf pc inlist (16 * N))
                (APPEND (f_ev_midexit_subiter4 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`136 - 16 * N`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * N`] FEV_SCALAR_TAIL_MASK) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let OFFSET_EXISTS = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 136 /\ 16 * N = 128 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248 /\
     read events s =
       APPEND (f_ev_scalar_tail (136 - 128) res buf pc inlist 128)
              (APPEND (f_ev_headguard_eta2 pc)
                      (APPEND (f_ev_loop_eta2 res buf table pc
                                 (REJ_MASK_ETA2 inlist) (N-1)) e))
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC OFFSET_EVENTS_BRIDGE THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT THEN ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
     [ASM_ARITH_TAC;
      MATCH_MP_TAC LE_TRANS THEN
      EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist))` THEN
      CONJ_TAC THENL
       [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]]]);;

let MIDEXIT1_EXISTS = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
              (APPEND (f_ev_midexit_subiter1 res buf table pc (REJ_MASK_ETA2 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT1_EVENTS_BRIDGE THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT2_EXISTS = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
              (APPEND (f_ev_midexit_subiter2 res buf table pc (REJ_MASK_ETA2 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT2_EVENTS_BRIDGE THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT3_EXISTS = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
              (APPEND (f_ev_midexit_subiter3 res buf table pc (REJ_MASK_ETA2 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT3_EVENTS_BRIDGE THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT4_EXISTS = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 136 /\ 16 * N <= 136 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248 /\
     read events s =
       APPEND (f_ev_scalar_tail (136 - 16 * N) res buf pc inlist (16 * N))
              (APPEND (f_ev_midexit_subiter4 res buf table pc (REJ_MASK_ETA2 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT4_EVENTS_BRIDGE THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT THEN ASM_REWRITE_TAC[]]);;

(* --- SAFE dispatch tactics --- *)
let midexit_qpost_safe_eta2 (midthm:thm) : term =
  let post = rand(rator(snd(dest_imp(snd(strip_forall(concl midthm)))))) in
  let post = vsubst [`N-1`,`i:num`] post in
  let sv, body = dest_abs post in
  let value_post = lhand body in
  let ev_and_ma  = rand body in
  let ev_eq      = lhand ev_and_ma in
  mk_abs(sv, mk_conj(value_post, ev_eq));;

let MIDEXIT_DISPATCH_SAFE_ETA2 (safearm:thm) (fev_tm:term) (pexpr:term) (prevpos:term) : tactic =
  let qpost = midexit_qpost_safe_eta2 safearm in
  let _, qbody = dest_abs qpost in
  let etail = rand (rand qbody) in
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC qpost THEN
  CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
  CONJ_TAC THENL
   [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`] safearm) THEN
    ANTS_TAC THENL
     [REPEAT CONJ_TAC THEN (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
    DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA2 bth);
    SUBGOAL_THEN (mk_comb(mk_comb(`(<=):num->num->bool`,
        mk_comb(`LENGTH:(int32)list->num`, mk_comb(`REJ_SAMPLE_ETA2_BYTES:byte list->int32 list`,
          mk_comb(mk_comb(`SUB_LIST:num#num->byte list->byte list`,mk_pair(`0`,pexpr)),`inlist:byte list`)))), `256`)) ASSUME_TAC THENL
     [SUBGOAL_THEN (mk_eq(pexpr, mk_binop `(+):num->num->num` prevpos `4`)) SUBST1_TAC THENL
       [UNDISCH_TAC `~(N=0)` THEN UNDISCH_TAC `16 * N <= 136` THEN ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER_ETA2 THEN CONJ_TAC THENL
       [UNDISCH_TAC `16 * N <= 136` THEN UNDISCH_TAC `~(N=0)` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    SCALAR_TAIL_LEG2_SAFE_ETA2 pexpr etail];;

let OFFSET_ARM_SAFE_ETA2_TAC : tactic =
  SUBGOAL_THEN `16 * N = 128` ASSUME_TAC THENL
   [SUBGOAL_THEN `120 < 16 * N` ASSUME_TAC THENL
     [UNDISCH_TAC `120 < 16 * N \/ 248 < LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * N) inlist):int16 list)` THEN
      REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
      UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
      ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `N = 8` (fun th -> REWRITE_TAC[th] THEN CONV_TAC NUM_REDUCE_CONV) THEN
    SUBGOAL_THEN `16 * N <= 136` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (N-1) <= 120` THEN UNDISCH_TAC `~(N=0)` THEN
      SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC; ALL_TAC] THEN
    UNDISCH_TAC `120 < 16 * N` THEN UNDISCH_TAC `16 * N <= 136` THEN ARITH_TAC; ALL_TAC] THEN
  MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`stackpointer:int64`;`e:(uarch_event)list`] EXIT_OFFSET_SAFE_ETA2) THEN
  ANTS_TAC THENL
   [ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ASM_REWRITE_TAC[] THEN
    UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
    SUBST1_TAC(ASSUME `16 * N = 128`) THEN REWRITE_TAC[]; ALL_TAC] THEN
  DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA2 bth);;

(* --- EXIT_BLOCK_SAFE arms 2/3/4 (defines shared builder) --- *)
let MASK_DBL_N1 = ARITH_RULE `2 * (16 * (N - 1)) = 32 * (N - 1)`;;
let MASK_DBL_N = ARITH_RULE `2 * (16 * N) = 32 * N`;;
let MASK_DBL_N1_4 = ARITH_RULE `2 * (16 * (N - 1) + 4) = 32 * (N - 1) + 8`;;
let MASK_DBL_N1_8 = ARITH_RULE `2 * (16 * (N - 1) + 8) = 32 * (N - 1) + 16`;;
let MASK_DBL_N1_12 = ARITH_RULE `2 * (16 * (N - 1) + 12) = 32 * (N - 1) + 24`;;

let MASK_OF (maskgoal:term) (bexp:term) (redthm:thm) : tactic =
  SUBGOAL_THEN maskgoal ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`; bexp] STORE_BRIDGE) THEN
    REWRITE_TAC[redthm] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
    ALL_TAC];;

let mk_midexit_safe_tm (extraconds:term list) : term =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA2)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 120 /\
                 LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `120 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list)` in
  let hyps' = list_mk_conj (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN] @ extraconds) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let MIDEXIT_SETUP_TAC : tactic =
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 120 /\
     LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  SUBGOAL_THEN
    `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)) inlist):int32 list) <= 248`
    ASSUME_TAC THENL
   [ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES]; ALL_TAC] THEN
  SUBGOAL_THEN `16 * N <= 136` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (N-1) <= 120` THEN UNDISCH_TAC `~(N = 0)` THEN
    SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
    ALL_TAC];;

let exit_block_midexit2_safe_tm = mk_midexit_safe_tm
  [`~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248)`];;

let midexit2_concrete_post =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
                (APPEND (f_ev_midexit_subiter2 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT2 = prove
 (exit_block_midexit2_safe_tm,
  MIDEXIT_SETUP_TAC THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit2_concrete_post THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1 THEN
    MASK_OF `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248)`
            `16 * N` MASK_DBL_N THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4 THEN
    MASK_OF `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248)`
            `16 * (N-1) + 8` MASK_DBL_N1_8 THEN
    MATCH_MP_TAC MIDEXIT2_EXISTS THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA2 MID_EXIT_SUBITER2_SAFE_ETA2
      `f_ev_midexit_subiter2 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) (N-1)`
      `16*(N-1)+8` `16*(N-1)+4`]);;

let exit_block_midexit3_safe_tm = mk_midexit_safe_tm
  [`~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248`;
   `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248)`];;

let midexit3_concrete_post =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
                (APPEND (f_ev_midexit_subiter3 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT3 = prove
 (exit_block_midexit3_safe_tm,
  MIDEXIT_SETUP_TAC THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit3_concrete_post THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1 THEN
    MASK_OF `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248)`
            `16 * N` MASK_DBL_N THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4 THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 8` MASK_DBL_N1_8 THEN
    MASK_OF `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248)`
            `16 * (N-1) + 12` MASK_DBL_N1_12 THEN
    MATCH_MP_TAC MIDEXIT3_EXISTS THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA2 MID_EXIT_SUBITER3_SAFE_ETA2
      `f_ev_midexit_subiter3 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) (N-1)`
      `16*(N-1)+12` `16*(N-1)+8`]);;

(* --- OFFSET arm --- *)
let exit_block_offset_safe_tm =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA2)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 120 /\
                 LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `120 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list)` in
  let offbyte = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` in
  let hyps' = list_mk_conj (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN; offbyte]) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let EXIT_BLOCK_SAFE_OFFSET = prove
 (exit_block_offset_safe_tm,
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 120 /\
     LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC (rand(rator(snd(dest_imp(snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA2))))))) THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SUBGOAL_THEN `16 * N = 128` ASSUME_TAC THENL
     [SUBGOAL_THEN `N = 8` (fun th -> REWRITE_TAC[th] THEN CONV_TAC NUM_REDUCE_CONV) THEN
      SUBGOAL_THEN `120 < 16 * N` ASSUME_TAC THENL
       [UNDISCH_TAC `120 < 16 * N \/
                     248 < LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list)` THEN
        REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
        UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
        ARITH_TAC;
        ALL_TAC] THEN
      SUBGOAL_THEN `16 * N <= 136` ASSUME_TAC THENL
       [UNDISCH_TAC `16 * (N-1) <= 120` THEN UNDISCH_TAC `~(N = 0)` THEN
        SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
        ALL_TAC] THEN
      UNDISCH_TAC `120 < 16 * N` THEN UNDISCH_TAC `16 * N <= 136` THEN ARITH_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN
      `NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * N`] STORE_BRIDGE) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * N) = 32 * N`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    MATCH_MP_TAC OFFSET_EXISTS THEN ASM_REWRITE_TAC[];
    OFFSET_ARM_SAFE_ETA2_TAC]);;

(* --- MIDEXIT1 arm --- *)
let exit_block_midexit1_safe_tm =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA2)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 120 /\
                 LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `120 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list)` in
  let midcase = `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)` in
  let sub1sel = `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248)` in
  let hyps' = list_mk_conj
    (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN; midcase; sub1sel]) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let midexit1_concrete_post =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail (136 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
                (APPEND (f_ev_midexit_subiter1 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT1 = prove
 (exit_block_midexit1_safe_tm,
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 120 /\
     LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  SUBGOAL_THEN
    `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)) inlist):int32 list) <= 248`
    ASSUME_TAC THENL
   [ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES]; ALL_TAC] THEN
  SUBGOAL_THEN `16 * N <= 136` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (N-1) <= 120` THEN UNDISCH_TAC `~(N = 0)` THEN
    SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
    ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit1_concrete_post THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SUBGOAL_THEN `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * (N-1)`] STORE_BRIDGE) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (N-1)) = 32 * (N-1)`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248)`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * N`] STORE_BRIDGE) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * N) = 32 * N`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248)`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * (N-1) + 4`] STORE_BRIDGE) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (N-1) + 4) = 32 * (N-1) + 8`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    MATCH_MP_TAC MIDEXIT1_EXISTS THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA2 MID_EXIT_SUBITER1_SAFE_ETA2
      `f_ev_midexit_subiter1 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) (N-1)`
      `16*(N-1)+4` `16*(N-1)`]);;

(* --- MIDEXIT4 arm --- *)
let SAFE_BRIDGE_CLEAN (bth:thm) : tactic =
  W(fun (asl,gl) ->
    let lframe = rand(concl bth) in
    let lpost  = rand(rator(concl bth)) in
    let lpre   = rand(rator(rator(concl bth))) in
    let gframe = rand gl in
    let subsumed_tm = mk_binop
      `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool`
      lframe gframe in
    let subsumed_th = prove(subsumed_tm,
      REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
      SUBSUMED_MAYCHANGE_TAC) in
    let bth2 = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
    MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
      CONJ_TAC THENL
       [GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
        ACCEPT_TAC bth2]]);;

let SCALAR_TAIL_LEG2_CLEAN (p:term) (etail:term) : tactic =
  W(fun (asl,gl) ->
    let atp = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                     `pc:num`;p;`stackpointer:int64`;etail]
                    MLDSA_REJ_UNIFORM_ETA2_SCALAR_TAIL_AT_P_SAFE in
    let atp_ens = snd(dest_imp(concl atp)) in
    let _,ppf = strip_comb atp_ens in
    let atp_pre = el 1 ppf and atp_post = el 2 ppf in
    MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC atp_post THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC atp_pre THEN
      CONJ_TAC THENL
       [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
        MP_TAC atp THEN ANTS_TAC THENL
         [REPEAT CONJ_TAC THEN FIRST_ASSUM ACCEPT_TAC;
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_FRAME_SUBSUMED) THEN
          REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
          SUBSUMED_MAYCHANGE_TAC]]]);;

let exit_block_midexit4_safe_tm = mk_midexit_safe_tm
  [`~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248`];;

let midexit4_concrete_post =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail (136 - (16 * ((N-1) + 1))) res buf pc inlist (16 * ((N-1) + 1)))
                (APPEND (f_ev_midexit_subiter4 res buf table pc (REJ_MASK_ETA2 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT4 = prove
 (exit_block_midexit4_safe_tm,
  MIDEXIT_SETUP_TAC THEN
  SUBGOAL_THEN `16 * ((N-1) + 1) = 16 * N` ASSUME_TAC THENL
   [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*((N-1)+1)) inlist):int32 list)`
    ASSUME_TAC THENL
   [SUBST1_TAC(ASSUME `16 * ((N-1) + 1) = 16 * N`) THEN
    UNDISCH_TAC `~(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)` THEN
    ARITH_TAC; ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit4_concrete_post THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `16 * ((N-1) + 1) = 16 * N`]) THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1 THEN
    MASK_OF `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA2 inlist)) <= 248)`
            `16 * N` MASK_DBL_N THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4 THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 8` MASK_DBL_N1_8 THEN
    MASK_OF `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA2 inlist)) <= 248`
            `16 * (N-1) + 12` MASK_DBL_N1_12 THEN
    MATCH_MP_TAC MIDEXIT4_EXISTS THEN ASM_REWRITE_TAC[];
    MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN
    EXISTS_TAC (midexit_qpost_safe_eta2 MID_EXIT_SUBITER4_SAFE_ETA2) THEN
    CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
    CONJ_TAC THENL
     [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                    `pc:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`]
                   MID_EXIT_SUBITER4_SAFE_ETA2) THEN
      ANTS_TAC THENL
       [REPEAT CONJ_TAC THEN (FIRST[FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
      DISCH_THEN(fun bth -> SAFE_BRIDGE_CLEAN bth);
      SUBGOAL_THEN `16 * ((N-1) + 1) <= 136` ASSUME_TAC THENL
       [UNDISCH_TAC `16 * N <= 136` THEN UNDISCH_TAC `16 * ((N-1) + 1) = 16 * N` THEN
        ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN
        `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*((N-1)+1)) inlist):int32 list) <= 256`
        ASSUME_TAC THENL
       [SUBGOAL_THEN `16 * ((N-1) + 1) = (16 * (N-1) + 12) + 4` SUBST1_TAC THENL
         [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; ALL_TAC] THEN
        MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER_ETA2 THEN CONJ_TAC THENL
         [UNDISCH_TAC `16 * N <= 136` THEN UNDISCH_TAC `16 * ((N-1) + 1) = 16 * N` THEN
          UNDISCH_TAC `LENGTH(inlist:byte list) = 136` THEN ARITH_TAC;
          FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
      SCALAR_TAIL_LEG2_CLEAN `16 * ((N-1) + 1)`
        `APPEND (f_ev_midexit_subiter4 res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) (N-1))
                (e:(uarch_event)list)`]]);;

(* --- EXIT_BLOCK_SAFE_ETA2 (assembled) --- *)
let exit_block_safe_eta2_tm = mk_midexit_safe_tm [];;

let EXIT_BLOCK_SAFE_ETA2 = prove
 (exit_block_safe_eta2_tm,
  MIDEXIT_SETUP_TAC THEN
  ASM_CASES_TAC
    `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THENL
   [MATCH_MP_TAC EXIT_BLOCK_SAFE_OFFSET THEN ASM_REWRITE_TAC[];
    ASM_CASES_TAC
      `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248` THENL
     [ASM_CASES_TAC
        `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248` THENL
       [ASM_CASES_TAC
          `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248` THENL
         [MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT4 THEN ASM_REWRITE_TAC[];
          MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT3 THEN ASM_REWRITE_TAC[]];
        MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT2 THEN ASM_REWRITE_TAC[]];
      MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT1 THEN ASM_REWRITE_TAC[]]]);;

(* --- CORE_SAFE_FREEN_ETA2 --- *)
let MEMACCESS_ENUM_LOOP_ETA2 = prove
 (`!res buf table inlist pc N.
      ~(N = 0) /\ 16 * (N - 1) <= 120 /\
      (!m. m < N ==> 16 * m <= 120 /\
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*m) inlist):int16 list) <= 248)
      ==> memaccess_inbounds
            (ENUMERATEL (N-1) (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 inlist)))
            [buf,136; table,2048] [res,1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC MEMACCESS_ENUM_ACC THEN
  X_GEN_TAC `j:num` THEN DISCH_TAC THEN
  MATCH_MP_TAC MEMACCESS_F_EV_LOOP_ETA2 THEN
  CONJ_TAC THENL
   [MAP_EVERY UNDISCH_TAC [`j < N - 1`; `16 * (N - 1) <= 120`] THEN ARITH_TAC;
    MATCH_MP_TAC LE_TRANS THEN
    EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32*(j+1))(REJ_MASK_ETA2 inlist))` THEN
    CONJ_TAC THENL
     [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
      MP_TAC(SPECL[`inlist:byte list`;`16*(j+1)`] STORE_BRIDGE) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (j + 1)) = 32 * (j + 1)`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `j + 1` o check(is_forall o concl)) THEN
      ANTS_TAC THENL
       [UNDISCH_TAC `j < N - 1` THEN UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC;
        REWRITE_TAC[] THEN STRIP_TAC THEN FIRST_ASSUM ACCEPT_TAC]]]);;

let core_safe_freeN_tm =
  let bod = snd(strip_forall(concl ETA2_LOOP_SAFE)) in
  let hyps,ens = dest_imp bod in
  let comb,args = strip_comb ens in
  let step = el 0 args and pre = el 1 args and frame = el 3 args in
  let pN = `120 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*N) inlist):int16 list)` in
  let hyps' = list_mk_conj (conjuncts hyps @ [pN]) in
  let sv = `s:x86state` in
  let post = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word (pc + LENGTH (BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 (inlist:byte list)) N)
                       (ENUMERATEL (N - 1)
                          (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 inlist))) /\
           memaccess_inbounds e2 [(buf:int64),136; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(comb, [step; pre; post; frame]) in
  list_mk_forall(fst(strip_forall(concl ETA2_LOOP_SAFE)), mk_imp(hyps', ens'));;

let LOOP' = REWRITE_RULE[SOME_FLAGS] ETA2_LOOP_SAFE;;
let loop_post_tm = el 2 (snd(strip_comb(snd(dest_imp(snd(strip_forall(concl ETA2_LOOP_SAFE)))))));;
let EXIT_INST = SPECL
  [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;
   `stackpointer:int64`;
   `APPEND (ENUMERATEL (N-1) (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 inlist)))
           (e:(uarch_event)list)`]
  EXIT_BLOCK_SAFE_ETA2;;
let q_inter = el 1 (snd(strip_comb(snd(dest_imp(concl EXIT_INST)))));;
let exit_post_tm = el 2 (snd(strip_comb(snd(dest_imp(concl EXIT_INST)))));;

let CORE_SAFE_FREEN_ETA2 = prove
 (core_safe_freeN_tm,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[SOME_FLAGS] THEN
  DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN
  EXISTS_TAC q_inter THEN
  CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
    EXISTS_TAC loop_post_tm THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC LOOP' THEN ASM_REWRITE_TAC[]];
    SUBGOAL_THEN `16 * (N - 1) <= 120` ASSUME_TAC THENL
     [FIRST_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
      ANTS_TAC THENL
       [UNDISCH_TAC `~(N=0)` THEN ARITH_TAC;
        DISCH_THEN(ACCEPT_TAC o CONJUNCT1)];
      ALL_TAC] THEN
    MP_TAC EXIT_INST THEN ANTS_TAC THENL
     [RULE_ASSUM_TAC(REWRITE_RULE[NONOVERLAPPING_CLAUSES;
                                 LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC]) THEN
      ASM_REWRITE_TAC[];
      DISCH_THEN(fun exitth ->
        MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
        EXISTS_TAC exit_post_tm THEN
        CONJ_TAC THENL
         [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
          FIRST_X_ASSUM(SUBST_ALL_TAC o
            check (fun th -> is_eq(concl th) && is_var(lhs(concl th)))) THEN
          CONJ_TAC THENL
           [ASM_REWRITE_TAC[];
            EXISTS_TAC
              `APPEND (f_ev_exit res buf table pc (REJ_MASK_ETA2 inlist) N)
                      (ENUMERATEL (N-1)
                         (f_ev_loop_eta2 res buf table pc (REJ_MASK_ETA2 inlist)))` THEN
            REPEAT CONJ_TAC THENL
             [ASM_REWRITE_TAC[APPEND_ASSOC];
              REFL_TAC;
              REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN CONJ_TAC THENL
               [FIRST_ASSUM ACCEPT_TAC;
                MATCH_MP_TAC MEMACCESS_ENUM_LOOP_ETA2 THEN ASM_REWRITE_TAC[]]]];
          ACCEPT_TAC exitth])]]);;

(* --- CORE_SAFE + SUBROUTINE_SAFE --- *)
let f_ev_core_eta2 =
  `\(res:int64) (buf:int64) (table:int64) (pc:num) (mask:(bool)list).
      APPEND (f_ev_exit res buf table pc mask (N_OF_MASK_ETA2 mask))
             (ENUMERATEL (N_OF_MASK_ETA2 mask - 1)
                         (f_ev_loop_eta2 res buf table pc mask))
        :(uarch_event)list`;;

let core_safe_eta2_tm =
 `?f_events:int64->int64->int64->num->(bool)list->(uarch_event)list.
   !res buf table (inlist:byte list) e pc.
    LENGTH inlist = 136 /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta2_tmc) (res,1024) /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta2_tmc) (buf,136) /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta2_tmc) (table,2048) /\
    nonoverlapping (res,1024) (buf,136) /\
    nonoverlapping (res,1024) (table,2048)
    ==> ensures x86
        (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
             read RIP s = word pc /\
             C_ARGUMENTS [res; buf; table] s /\
             read (memory :> bytes (buf,136)) s = num_of_wordlist inlist /\
             read (memory :> bytes (table,2048)) s =
             num_of_wordlist mldsa_rej_uniform_table /\
             read events s = e)
        (\s. read RIP s =
             word (pc + LENGTH (BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
             (?e2. read events s = APPEND e2 e /\
                   e2 = f_events res buf table pc (REJ_MASK_ETA2 inlist) /\
                   memaccess_inbounds e2 [buf,136; table,2048] [res,1024]))
        (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
         MAYCHANGE
         [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
          ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
         MAYCHANGE SOME_FLAGS ,,
         MAYCHANGE [events] ,,
         MAYCHANGE [memory :> bytes (res,1024)])`;;

let MLDSA_REJ_UNIFORM_ETA2_CORE_CORRECT_SAFE = prove
 (add_rej_eta_core_result rej_eta_result core_safe_eta2_tm,
  EXISTS_TAC f_ev_core_eta2 THEN
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  GHOST_INTRO_TAC `stackpointer:int64` `read RSP` THEN
  CONV_TAC(TOP_DEPTH_CONV BETA_CONV) THEN
  MATCH_MP_TAC CORE_SAFE_FREEN_ETA2 THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPEC `REJ_MASK_ETA2 (inlist:byte list)` N_OF_MASK_ETA2_MINIMAL) THEN
  REWRITE_TAC[GSYM NIBLEN_EQ_NUMACC_ETA2] THEN
  ABBREV_TAC `NN = N_OF_MASK_ETA2 (REJ_MASK_ETA2 (inlist:byte list))` THEN
  DISCH_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC) THEN
  REPEAT CONJ_TAC THENL
   [DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o check(is_disj o concl)) THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES;
                    REJ_NIBBLES_ETA2_EMPTY; LENGTH] THEN
    ARITH_TAC;
    DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o check(is_disj o concl)) THEN
    ASM_REWRITE_TAC[ARITH_RULE `16 * 1 = 16`; ARITH_RULE `~(120 < 16)`] THEN
    MP_TAC(ISPECL [`inlist:byte list`; `16`]
                  LENGTH_REJ_SAMPLE_ETA2_BYTES_SUB_LIST_BOUND) THEN
    ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC;
    X_GEN_TAC `m:num` THEN DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `m:num` o check(is_forall o concl)) THEN
    ASM_REWRITE_TAC[] THEN REWRITE_TAC[NOT_LT] THEN DISCH_THEN ACCEPT_TAC;
    FIRST_ASSUM ACCEPT_TAC]);;

let MLDSA_REJ_UNIFORM_ETA2_CORE_SAFE = prove
 (core_safe_eta2_tm, REJ_ETA_CORE_SAFE_TAC MLDSA_REJ_UNIFORM_ETA2_CORE_CORRECT_SAFE);;

let MLDSA_REJ_UNIFORM_ETA2_CORE_SAFE_CONCRETE =
  CONV_RULE(REWRITE_CONV[LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC;
                         fst MLDSA_REJ_UNIFORM_ETA2_EXEC])
    MLDSA_REJ_UNIFORM_ETA2_CORE_SAFE;;

let MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_SAFE =
  let saved_tic = !type_invention_error in
  type_invention_error := false;
  let th = prove
   (`?f_events:int64->int64->int64->num->(bool)list->int64->int64->
              (uarch_event)list.
     !res buf table (inlist:byte list) e pc stackpointer returnaddress.
        LENGTH inlist = 136 /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (res, 1024) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (buf, 136) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (table, 2048) /\
        nonoverlapping (res, 1024) (buf, 136) /\
        nonoverlapping (res, 1024) (table, 2048) /\
        nonoverlapping (stackpointer, 8) (res, 1024) /\
        nonoverlapping (stackpointer, 8) (buf, 136) /\
        nonoverlapping (stackpointer, 8) (table, 2048) /\
        nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta2_tmc)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta2_tmc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [res; buf; table] s /\
                  read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                  read(memory :> bytes(table,2048)) s =
                    num_of_wordlist mldsa_rej_uniform_table /\
                  read events s = e)
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (?e2. read events s = APPEND e2 e /\
                        e2 = f_events res buf table pc (REJ_MASK_ETA2 inlist)
                                      stackpointer returnaddress /\
                        memaccess_inbounds e2
                          [buf,136; table,2048; stackpointer,8]
                          [res,1024]))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(res,1024)])`,
    REWRITE_TAC[LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC] THEN
    X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_rej_uniform_eta2_tmc
      MLDSA_REJ_UNIFORM_ETA2_CORE_SAFE_CONCRETE THEN
    ABBREV_TAC `mask:(bool)list = REJ_MASK_ETA2 (inlist:byte list)` THEN
    DISCHARGE_SAFETY_PROPERTY_TAC) in
  type_invention_error := saved_tic;
  th;;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_SAFE =
  ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_SAFE;;

(* Memory safety follows by forgetting the event-trace equality. *)
type_invention_error := false;;

let MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_MEMSAFE = prove
 (`!res buf table (inlist:byte list) e pc stackpointer returnaddress.
      LENGTH inlist = 136 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (buf, 136) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 136) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 136) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta2_tmc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta2_tmc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table /\
                read events s = e)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (exists e2.
                   read events s = APPEND e2 e /\
                   memaccess_inbounds e2
                     [buf,136; table,2048; stackpointer,8]
                     [res,1024]))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REJ_ETA_MEMSAFE_TAC MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_SAFE);;

type_invention_error := true;;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_MEMSAFE = prove
 (`!res buf table (inlist:byte list) e pc stackpointer returnaddress.
      LENGTH inlist = 136 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (buf, 136) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 136) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 136) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta2_mc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table /\
                read events s = e)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (exists e2.
                   read events s = APPEND e2 e /\
                   memaccess_inbounds e2
                     [buf,136; table,2048; stackpointer,8]
                     [res,1024]))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_MEMSAFE));;

let MLDSA_REJ_UNIFORM_ETA2_CORRECT = prove
 (correct_eta2_tm, REJ_ETA_CORE_CORRECT_TAC MLDSA_REJ_UNIFORM_ETA2_CORE_CORRECT_SAFE);;

let correct_bound = prove
 (`!res buf table (inlist:byte list) pc.
    LENGTH inlist = 136 /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (res, 1024) /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (buf, 136) /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (table, 2048) /\
    nonoverlapping (res, 1024) (buf, 136) /\
    nonoverlapping (res, 1024) (table, 2048)
    ==> ensures x86
         (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
              read RIP s = word pc /\
              C_ARGUMENTS [res; buf; table] s /\
              read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
              read(memory :> bytes(table,2048)) s =
                num_of_wordlist mldsa_rej_uniform_table)
         (\s. read RIP s = word(pc + LENGTH (BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
              (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES inlist) in
               let outlen = LENGTH outlist in
               outlen <= 256 /\
               C_RETURN s = word outlen /\
               read(memory :> bytes(res,4 * outlen)) s =
                 num_of_wordlist outlist /\
               (!i. i < outlen
                    ==> ival(EL i outlist:int32) < &3 /\
                        -- &3 < ival(EL i outlist:int32))))
         (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
          MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                     ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
          MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
          MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC ENSURES_STRENGTHEN_POST_X86 THEN
  EXISTS_TAC
   `\s:x86state.
      read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
      (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES (inlist:byte list)) in
       let outlen = LENGTH outlist in
       C_RETURN s = word outlen /\
       read(memory :> bytes(res:int64,4 * outlen)) s =
         num_of_wordlist outlist)` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_UNIFORM_ETA2_CORRECT THEN ASM_REWRITE_TAC[];
    BETA_TAC THEN GEN_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    CONJ_TAC THENL
     [MATCH_ACCEPT_TAC LENGTH_SUB_LIST_REJ_SAMPLE_ETA2_BYTES; ALL_TAC] THEN
    MATCH_ACCEPT_TAC REJ_SAMPLE_ETA2_BYTES_EL_BOUND]);;

let correct_bound_concrete =
  CONV_RULE(REWRITE_CONV[LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC;
                         fst MLDSA_REJ_UNIFORM_ETA2_EXEC])
    correct_bound;;

type_invention_error := false;;

let MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_CORRECT = prove
 (`!res buf table (inlist:byte list) pc stackpointer returnaddress.
      LENGTH inlist = 136 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (buf, 136) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_tmc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 136) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 136) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta2_tmc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta2_tmc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (let outlist = SUB_LIST(0,256)
                    (REJ_SAMPLE_ETA2_BYTES inlist) in
                 let outlen = LENGTH outlist in
                 outlen <= 256 /\
                 C_RETURN s = word outlen /\
                 read(memory :> bytes(res,4 * outlen)) s =
                   num_of_wordlist outlist /\
                 (!i. i < outlen
                      ==> ival(EL i outlist:int32) < &3 /\
                          -- &3 < ival(EL i outlist:int32))))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REWRITE_TAC[LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC] THEN
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_rej_uniform_eta2_tmc
    correct_bound_concrete);;

type_invention_error := true;;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_CORRECT_BYTES =
  ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA2_NOIBT_SUBROUTINE_CORRECT;;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_CORRECT = prove
 (`!res buf table (inlist:(4 word) list) pc stackpointer returnaddress.
      LENGTH inlist = 272 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (buf, 136) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta2_mc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 136) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 136) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta2_mc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (let outlist = SUB_LIST(0,256)
                    (REJ_SAMPLE_ETA2 inlist) in
                 let outlen = LENGTH outlist in
                 outlen <= 256 /\
                 C_RETURN s = word outlen /\
                 read(memory :> bytes(res,4 * outlen)) s =
                   num_of_wordlist outlist /\
                 (!i. i < outlen
                      ==> ival(EL i outlist:int32) < &3 /\
                          -- &3 < ival(EL i outlist:int32))))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  MP_TAC(ISPEC `inlist:(4 word) list` BYTES_TO_NIBBLES_SURJ) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[EVEN_EXISTS] THEN EXISTS_TAC `136` THEN
    ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  DISCH_THEN(X_CHOOSE_THEN `bs:byte list` STRIP_ASSUME_TAC) THEN
  UNDISCH_THEN `BYTES_TO_NIBBLES (bs:byte list) = inlist`
    (SUBST_ALL_TAC o SYM) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[LENGTH_BYTES_TO_NIBBLES]) THEN
  SUBGOAL_THEN `LENGTH (bs:byte list) = 136` ASSUME_TAC THENL
   [UNDISCH_TAC `2 * LENGTH (bs:byte list) = 272` THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[NUM_OF_BYTES_TO_NIBBLES; GSYM REJ_SAMPLE_ETA2_BYTES_EQ] THEN
  MP_TAC(SPECL
   [`res:int64`; `buf:int64`; `table:int64`; `bs:byte list`; `pc:num`;
    `stackpointer:int64`; `returnaddress:int64`]
   MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_CORRECT_BYTES) THEN
  ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[]);;
