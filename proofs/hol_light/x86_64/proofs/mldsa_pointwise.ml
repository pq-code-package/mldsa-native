(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Pointwise multiplication of polynomials in NTT domain for ML-DSA.         *)
(* ========================================================================= *)

needs "x86/proofs/base.ml";;
needs "common/mldsa_specs.ml";;
needs "x86_64/proofs/mldsa_zetas.ml";;
needs "x86_64/proofs/mldsa_utils.ml";;

(*** print_literal_from_elf "x86_64/mldsa/mldsa_pointwise.o";;
 ***)

let mldsa_pointwise_mc = define_assert_from_elf "mldsa_pointwise_mc" "x86_64/mldsa/mldsa_pointwise.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0xc5; 0xfd; 0x6f; 0x42; 0x20;
                           (* VMOVDQA (%_% ymm0) (Memop Word256 (%% (rdx,32))) *)
  0xc5; 0xfd; 0x6f; 0x0a;  (* VMOVDQA (%_% ymm1) (Memop Word256 (%% (rdx,0))) *)
  0x31; 0xc0;              (* XOR (% eax) (% eax) *)
  0xc5; 0xfd; 0x6f; 0x17;  (* VMOVDQA (%_% ymm2) (Memop Word256 (%% (rdi,0))) *)
  0xc5; 0xfd; 0x6f; 0x67; 0x20;
                           (* VMOVDQA (%_% ymm4) (Memop Word256 (%% (rdi,32))) *)
  0xc5; 0xfd; 0x6f; 0x77; 0x40;
                           (* VMOVDQA (%_% ymm6) (Memop Word256 (%% (rdi,64))) *)
  0xc5; 0x7d; 0x6f; 0x16;  (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rsi,0))) *)
  0xc5; 0x7d; 0x6f; 0x66; 0x20;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rsi,32))) *)
  0xc5; 0x7d; 0x6f; 0x76; 0x40;
                           (* VMOVDQA (%_% ymm14) (Memop Word256 (%% (rsi,64))) *)
  0xc5; 0xe5; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm3) (%_% ymm2) (Imm8 (word 32)) *)
  0xc5; 0xd5; 0x73; 0xd4; 0x20;
                           (* VPSRLQ (%_% ymm5) (%_% ymm4) (Imm8 (word 32)) *)
  0xc5; 0xfe; 0x16; 0xfe;  (* VMOVSHDUP (%_% ymm7) (%_% ymm6) *)
  0xc4; 0xc1; 0x25; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm11) (%_% ymm10) (Imm8 (word 32)) *)
  0xc4; 0xc1; 0x15; 0x73; 0xd4; 0x20;
                           (* VPSRLQ (%_% ymm13) (%_% ymm12) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xfe;
                           (* VMOVSHDUP (%_% ymm15) (%_% ymm14) *)
  0xc4; 0xc2; 0x6d; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm2) (%_% ymm2) (%_% ymm10) *)
  0xc4; 0xc2; 0x65; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm3) (%_% ymm3) (%_% ymm11) *)
  0xc4; 0xc2; 0x5d; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm4) (%_% ymm4) (%_% ymm12) *)
  0xc4; 0xc2; 0x55; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm5) (%_% ymm5) (%_% ymm13) *)
  0xc4; 0xc2; 0x4d; 0x28; 0xf6;
                           (* VPMULDQ (%_% ymm6) (%_% ymm6) (%_% ymm14) *)
  0xc4; 0xc2; 0x45; 0x28; 0xff;
                           (* VPMULDQ (%_% ymm7) (%_% ymm7) (%_% ymm15) *)
  0xc4; 0x62; 0x7d; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm10) (%_% ymm0) (%_% ymm2) *)
  0xc4; 0x62; 0x7d; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm11) (%_% ymm0) (%_% ymm3) *)
  0xc4; 0x62; 0x7d; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm12) (%_% ymm0) (%_% ymm4) *)
  0xc4; 0x62; 0x7d; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm13) (%_% ymm0) (%_% ymm5) *)
  0xc4; 0x62; 0x7d; 0x28; 0xf6;
                           (* VPMULDQ (%_% ymm14) (%_% ymm0) (%_% ymm6) *)
  0xc4; 0x62; 0x7d; 0x28; 0xff;
                           (* VPMULDQ (%_% ymm15) (%_% ymm0) (%_% ymm7) *)
  0xc4; 0x42; 0x75; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm10) (%_% ymm1) (%_% ymm10) *)
  0xc4; 0x42; 0x75; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm11) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0x42; 0x75; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm12) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0x42; 0x75; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm13) (%_% ymm1) (%_% ymm13) *)
  0xc4; 0x42; 0x75; 0x28; 0xf6;
                           (* VPMULDQ (%_% ymm14) (%_% ymm1) (%_% ymm14) *)
  0xc4; 0x42; 0x75; 0x28; 0xff;
                           (* VPMULDQ (%_% ymm15) (%_% ymm1) (%_% ymm15) *)
  0xc4; 0xc1; 0x6d; 0xfb; 0xd2;
                           (* VPSUBQ (%_% ymm2) (%_% ymm2) (%_% ymm10) *)
  0xc4; 0xc1; 0x65; 0xfb; 0xdb;
                           (* VPSUBQ (%_% ymm3) (%_% ymm3) (%_% ymm11) *)
  0xc4; 0xc1; 0x5d; 0xfb; 0xe4;
                           (* VPSUBQ (%_% ymm4) (%_% ymm4) (%_% ymm12) *)
  0xc4; 0xc1; 0x55; 0xfb; 0xed;
                           (* VPSUBQ (%_% ymm5) (%_% ymm5) (%_% ymm13) *)
  0xc4; 0xc1; 0x4d; 0xfb; 0xf6;
                           (* VPSUBQ (%_% ymm6) (%_% ymm6) (%_% ymm14) *)
  0xc4; 0xc1; 0x45; 0xfb; 0xff;
                           (* VPSUBQ (%_% ymm7) (%_% ymm7) (%_% ymm15) *)
  0xc5; 0xed; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm2) (%_% ymm2) (Imm8 (word 32)) *)
  0xc5; 0xdd; 0x73; 0xd4; 0x20;
                           (* VPSRLQ (%_% ymm4) (%_% ymm4) (Imm8 (word 32)) *)
  0xc5; 0xfe; 0x16; 0xf6;  (* VMOVSHDUP (%_% ymm6) (%_% ymm6) *)
  0xc4; 0xe3; 0x6d; 0x02; 0xd3; 0xaa;
                           (* VPBLENDD (%_% ymm2) (%_% ymm2) (%_% ymm3) (Imm8 (word 170)) *)
  0xc4; 0xe3; 0x5d; 0x02; 0xe5; 0xaa;
                           (* VPBLENDD (%_% ymm4) (%_% ymm4) (%_% ymm5) (Imm8 (word 170)) *)
  0xc4; 0xe3; 0x4d; 0x02; 0xf7; 0xaa;
                           (* VPBLENDD (%_% ymm6) (%_% ymm6) (%_% ymm7) (Imm8 (word 170)) *)
  0xc5; 0xfd; 0x7f; 0x17;  (* VMOVDQA (Memop Word256 (%% (rdi,0))) (%_% ymm2) *)
  0xc5; 0xfd; 0x7f; 0x67; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rdi,32))) (%_% ymm4) *)
  0xc5; 0xfd; 0x7f; 0x77; 0x40;
                           (* VMOVDQA (Memop Word256 (%% (rdi,64))) (%_% ymm6) *)
  0x48; 0x83; 0xc7; 0x60;  (* ADD (% rdi) (Imm8 (word 96)) *)
  0x48; 0x83; 0xc6; 0x60;  (* ADD (% rsi) (Imm8 (word 96)) *)
  0x83; 0xc0; 0x01;        (* ADD (% eax) (Imm8 (word 1)) *)
  0x83; 0xf8; 0x0a;        (* CMP (% eax) (Imm8 (word 10)) *)
  0x0f; 0x82; 0x0b; 0xff; 0xff; 0xff;
                           (* JB (Imm32 (word 4294967051)) *)
  0xc5; 0xfd; 0x6f; 0x17;  (* VMOVDQA (%_% ymm2) (Memop Word256 (%% (rdi,0))) *)
  0xc5; 0xfd; 0x6f; 0x67; 0x20;
                           (* VMOVDQA (%_% ymm4) (Memop Word256 (%% (rdi,32))) *)
  0xc5; 0x7d; 0x6f; 0x16;  (* VMOVDQA (%_% ymm10) (Memop Word256 (%% (rsi,0))) *)
  0xc5; 0x7d; 0x6f; 0x66; 0x20;
                           (* VMOVDQA (%_% ymm12) (Memop Word256 (%% (rsi,32))) *)
  0xc5; 0xe5; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm3) (%_% ymm2) (Imm8 (word 32)) *)
  0xc5; 0xd5; 0x73; 0xd4; 0x20;
                           (* VPSRLQ (%_% ymm5) (%_% ymm4) (Imm8 (word 32)) *)
  0xc4; 0x41; 0x7e; 0x16; 0xda;
                           (* VMOVSHDUP (%_% ymm11) (%_% ymm10) *)
  0xc4; 0x41; 0x7e; 0x16; 0xec;
                           (* VMOVSHDUP (%_% ymm13) (%_% ymm12) *)
  0xc4; 0xc2; 0x6d; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm2) (%_% ymm2) (%_% ymm10) *)
  0xc4; 0xc2; 0x65; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm3) (%_% ymm3) (%_% ymm11) *)
  0xc4; 0xc2; 0x5d; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm4) (%_% ymm4) (%_% ymm12) *)
  0xc4; 0xc2; 0x55; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm5) (%_% ymm5) (%_% ymm13) *)
  0xc4; 0x62; 0x7d; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm10) (%_% ymm0) (%_% ymm2) *)
  0xc4; 0x62; 0x7d; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm11) (%_% ymm0) (%_% ymm3) *)
  0xc4; 0x62; 0x7d; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm12) (%_% ymm0) (%_% ymm4) *)
  0xc4; 0x62; 0x7d; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm13) (%_% ymm0) (%_% ymm5) *)
  0xc4; 0x42; 0x75; 0x28; 0xd2;
                           (* VPMULDQ (%_% ymm10) (%_% ymm1) (%_% ymm10) *)
  0xc4; 0x42; 0x75; 0x28; 0xdb;
                           (* VPMULDQ (%_% ymm11) (%_% ymm1) (%_% ymm11) *)
  0xc4; 0x42; 0x75; 0x28; 0xe4;
                           (* VPMULDQ (%_% ymm12) (%_% ymm1) (%_% ymm12) *)
  0xc4; 0x42; 0x75; 0x28; 0xed;
                           (* VPMULDQ (%_% ymm13) (%_% ymm1) (%_% ymm13) *)
  0xc4; 0xc1; 0x6d; 0xfb; 0xd2;
                           (* VPSUBQ (%_% ymm2) (%_% ymm2) (%_% ymm10) *)
  0xc4; 0xc1; 0x65; 0xfb; 0xdb;
                           (* VPSUBQ (%_% ymm3) (%_% ymm3) (%_% ymm11) *)
  0xc4; 0xc1; 0x5d; 0xfb; 0xe4;
                           (* VPSUBQ (%_% ymm4) (%_% ymm4) (%_% ymm12) *)
  0xc4; 0xc1; 0x55; 0xfb; 0xed;
                           (* VPSUBQ (%_% ymm5) (%_% ymm5) (%_% ymm13) *)
  0xc5; 0xed; 0x73; 0xd2; 0x20;
                           (* VPSRLQ (%_% ymm2) (%_% ymm2) (Imm8 (word 32)) *)
  0xc5; 0xfe; 0x16; 0xe4;  (* VMOVSHDUP (%_% ymm4) (%_% ymm4) *)
  0xc4; 0xe3; 0x65; 0x02; 0xd2; 0x55;
                           (* VPBLENDD (%_% ymm2) (%_% ymm3) (%_% ymm2) (Imm8 (word 85)) *)
  0xc4; 0xe3; 0x55; 0x02; 0xe4; 0x55;
                           (* VPBLENDD (%_% ymm4) (%_% ymm5) (%_% ymm4) (Imm8 (word 85)) *)
  0xc5; 0xfd; 0x7f; 0x17;  (* VMOVDQA (Memop Word256 (%% (rdi,0))) (%_% ymm2) *)
  0xc5; 0xfd; 0x7f; 0x67; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rdi,32))) (%_% ymm4) *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_pointwise_tmc = define_trimmed "mldsa_pointwise_tmc" mldsa_pointwise_mc;;
let MLDSA_POINTWISE_TMC_EXEC = X86_MK_CORE_EXEC_RULE mldsa_pointwise_tmc;;


(* ========================================================================= *)
(* Correctness proof                                                         *)
(* ========================================================================= *)

let MLDSA_POINTWISE_CORRECT = prove
 (`!a b consts x y pc.
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc, 0x0195) (a, 1024) /\
    nonoverlapping (word pc, 0x0195) (b, 1024) /\
    nonoverlapping (word pc, 0x0195) (consts, 2496) /\
    nonoverlapping (a, 1024) (b, 1024) /\
    nonoverlapping (a, 1024) (consts, 2496) /\
    nonoverlapping (b, 1024) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) (BUTLAST mldsa_pointwise_tmc) /\
              read RIP s = word pc /\
              C_ARGUMENTS [a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 256 ==> abs(ival(x i)) <= &75423752) /\
              (!i. i < 256 ==> abs(ival(y i)) <= &75423752) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = word(pc + 0x0194) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add a (word(4 * i)))) s in
                (ival zi == mldsa_pointwise (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                      ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
           MAYCHANGE [RAX] ,, MAYCHANGE SOME_FLAGS ,,
           MAYCHANGE [memory :> bytes(a, 1024)])`,

  (* Setup - strip quantifiers, introduce preconditions *)
  MAP_EVERY X_GEN_TAC
    [`a:int64`; `b:int64`; `consts:int64`;
     `x:num->int32`; `y:num->int32`; `pc:num`] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS;
              NONOVERLAPPING_CLAUSES; ALL] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  GLOBALIZE_PRECONDITION_TAC THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(ONCE_DEPTH_CONV EXPAND_CASES_CONV))) THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT STRIP_TAC THEN
  REWRITE_TAC [SOME_FLAGS; fst MLDSA_POINTWISE_TMC_EXEC] THEN

  (* Ghost variables for YMM registers *)
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

  ENSURES_INIT_TAC "s0" THEN

  (* Merge memory reads from array a *)
  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add a (word n))) s0`)) (0--31))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  (* Merge memory reads from array b *)
  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add b (word n))) s0`)) (0--31))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  (* Discard bytes32 reads (a and b are now merged into bytes256) *)
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 a) s = x`] THEN

  (* Expand the qdata table *)
  FIRST_X_ASSUM(MP_TAC o CONV_RULE (LAND_CONV WORDLIST_FROM_MEMORY_CONV)) THEN
  REWRITE_TAC[mldsa_complete_qdata; MAP; CONS_11] THEN
  STRIP_TAC THEN

  (* Merge constants memory - only first 2 blocks needed by the assembly *)
  MP_TAC(end_itlist CONJ (map (fun n ->
    READ_MEMORY_MERGE_CONV 3 (subst[mk_small_numeral(32*n),`n:num`]
      `read (memory :> bytes256(word_add consts (word n))) s0`)) (0--1))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 consts) s = z`] THEN
  CONV_TAC(LAND_CONV WORD_REDUCE_CONV) THEN
  STRIP_TAC THEN

  (* Add product bounds as assumptions *)
  SUBGOAL_THEN
   `!i. i < 256 ==>
     abs(ival(word_mul (word_sx ((x:num->int32) i):int64)
                       (word_sx ((y:num->int32) i):int64))) <= &5688742365757504`
   ASSUME_TAC THENL
  [REPEAT STRIP_TAC THEN
   MP_TAC(ISPECL [`(x:num->int32) i`; `(y:num->int32) i`] IVAL_WORD_MUL_SX32_64) THEN
   ANTS_TAC THENL
    [ASM_MESON_TAC[]; DISCH_THEN(fun th -> REWRITE_TAC[th])] THEN
   REWRITE_TAC[INT_ABS_MUL] THEN
   MATCH_MP_TAC INT_LE_TRANS THEN EXISTS_TAC `&75423752 * &75423752:int` THEN
   CONJ_TAC THENL
    [MATCH_MP_TAC INT_LE_MUL2 THEN REWRITE_TAC[INT_ABS_POS] THEN ASM_MESON_TAC[];
     CONV_TAC INT_REDUCE_CONV];
   ALL_TAC] THEN

  (* Execute all 533 instructions with SIMD simplification *)
  MAP_EVERY (fun n -> X86_STEPS_TAC MLDSA_POINTWISE_TMC_EXEC [n] THEN
                      SIMD_SIMPLIFY_TAC[mldsa_pointwise_montred])
        (1--533) THEN
  ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[] THEN

  (* Split bytes256 -> bytes32 *)
  REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
    CONV_RULE(READ_MEMORY_SPLIT_CONV 3) o
    check (can (term_match [] `read qqq s533:int256 = xxx`) o concl))) THEN

  (* Expand output cases, substitute, collapse subwords, fold *)
  CONV_TAC(TOP_DEPTH_CONV EXPAND_CASES_CONV) THEN
  CONV_TAC(DEPTH_CONV NUM_MULT_CONV THENC DEPTH_CONV NUM_ADD_CONV) THEN
  REWRITE_TAC[WORD_ADD_0] THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  REWRITE_TAC[USHR32_SUBWORD; DUP32_SUBWORD] THEN
  REWRITE_TAC[Q_MUL_COMM; GSYM mldsa_pointwise_montred] THEN
  REWRITE_TAC[WORD_JOIN_SUBWORD] THEN

  (* Prove postcondition - congruence + bounds for each coefficient *)
  W(fun (asl,w) ->
    let lfn = PROCESS_BOUND_ASSUMPTIONS
      (CONJUNCTS(tryfind (CONV_RULE EXPAND_CASES_CONV o snd) asl))
    in
    let prove_group =
      W(fun (asl,w) ->
        let mr = rand(lhand(rator(lhand w))) in
        MP_TAC(ASM_CONGBOUND_RULE lfn mr) THEN
        MATCH_MP_TAC MONO_AND THEN CONJ_TAC THENL
         [(* Congruence branch *)
          REWRITE_TAC[INVERSE_MOD_CONV `inverse_mod 8380417 4294967296`] THEN
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] INT_CONG_TRANS) THEN
          REWRITE_TAC[GSYM INT_REM_EQ; o_THM; mldsa_pointwise;
                       INVERSE_MOD_CONV `inverse_mod 8380417 4294967296`] THEN
          CONV_TAC INT_REM_DOWN_CONV THEN
          W(fun (_,w) ->
            let prod = find_term
              (can (term_match []
                `ival(word_mul (word_sx (x:int32):int64) (word_sx (y:int32)))`)) w in
            let wm = rand prod in
            let xi = rand(rand(rator wm)) in
            let yi = rand(rand wm) in
            SUBGOAL_THEN (mk_eq(prod,
              mk_binop `( * ):int->int->int`
                (mk_comb(`ival:int32->int`, xi))
                (mk_comb(`ival:int32->int`, yi)))) SUBST1_TAC THENL
             [MATCH_MP_TAC IVAL_WORD_MUL_SX32_64 THEN
              CONJ_TAC THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ARITH_TAC;
              AP_THM_TAC THEN AP_TERM_TAC THEN INT_ARITH_TAC]);
          (* Bounds branch *)
          REWRITE_TAC[INT_ABS_BOUNDS] THEN
          MATCH_MP_TAC(INT_ARITH
           `l':int <= l /\ u <= u'
            ==> l <= x /\ x <= u ==> l' <= x /\ x <= u'`) THEN
          CONV_TAC INT_REDUCE_CONV])
    in
    REPEAT(W(fun (_,w) ->
      if length(conjuncts w) > 2 then CONJ_TAC else NO_TAC)) THEN
    prove_group));;

(* ========================================================================= *)
(* Subroutine form                                                           *)
(* ========================================================================= *)

let MLDSA_POINTWISE_NOIBT_SUBROUTINE_CORRECT = prove
 (`!a b consts x y pc stackpointer returnaddress.
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_tmc) (a, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_tmc) (b, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_tmc) (consts, 2496) /\
    nonoverlapping (a, 1024) (b, 1024) /\
    nonoverlapping (a, 1024) (consts, 2496) /\
    nonoverlapping (b, 1024) (consts, 2496) /\
    nonoverlapping (stackpointer, 8) (a, 1024) /\
    nonoverlapping (stackpointer, 8) (b, 1024) /\
    nonoverlapping (stackpointer, 8) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) mldsa_pointwise_tmc /\
              read RIP s = word pc /\
              read RSP s = stackpointer /\
              read (memory :> bytes64 stackpointer) s = returnaddress /\
              C_ARGUMENTS [a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 256 ==> abs(ival(x i)) <= &75423752) /\
              (!i. i < 256 ==> abs(ival(y i)) <= &75423752) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = returnaddress /\
              read RSP s = word_add stackpointer (word 8) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add a (word(4 * i)))) s in
                (ival zi == mldsa_pointwise (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(a, 1024)])`,
  let TWEAK_CONV = ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV in
  CONV_TAC TWEAK_CONV THEN
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_pointwise_tmc
    (CONV_RULE TWEAK_CONV MLDSA_POINTWISE_CORRECT));;

let MLDSA_POINTWISE_SUBROUTINE_CORRECT = prove
 (`!a b consts x y pc stackpointer returnaddress.
    aligned 32 a /\
    aligned 32 b /\
    aligned 32 consts /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_mc) (a, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_mc) (b, 1024) /\
    nonoverlapping (word pc,LENGTH mldsa_pointwise_mc) (consts, 2496) /\
    nonoverlapping (a, 1024) (b, 1024) /\
    nonoverlapping (a, 1024) (consts, 2496) /\
    nonoverlapping (b, 1024) (consts, 2496) /\
    nonoverlapping (stackpointer, 8) (a, 1024) /\
    nonoverlapping (stackpointer, 8) (b, 1024) /\
    nonoverlapping (stackpointer, 8) (consts, 2496)
    ==> ensures x86
          (\s. bytes_loaded s (word pc) mldsa_pointwise_mc /\
              read RIP s = word pc /\
              read RSP s = stackpointer /\
              read (memory :> bytes64 stackpointer) s = returnaddress /\
              C_ARGUMENTS [a; b; consts] s /\
              wordlist_from_memory(consts,624) s =
                MAP (iword: int -> 32 word) mldsa_complete_qdata /\
              (!i. i < 256 ==> abs(ival(x i)) <= &75423752) /\
              (!i. i < 256 ==> abs(ival(y i)) <= &75423752) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
              (!i. i < 256 ==>
                read(memory :> bytes32(word_add b (word(4 * i)))) s = y i))
          (\s. read RIP s = returnaddress /\
              read RSP s = word_add stackpointer (word 8) /\
              (!i. i < 256 ==>
                let zi = read(memory :> bytes32(word_add a (word(4 * i)))) s in
                (ival zi == mldsa_pointwise (ival o x) (ival o y) i)
                  (mod &8380417) /\
                abs(ival zi) <= &8380416))
          (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(a, 1024)])`,
  let TWEAK_CONV = ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV in
  CONV_TAC TWEAK_CONV THEN
  MATCH_ACCEPT_TAC(ADD_IBT_RULE
    (CONV_RULE TWEAK_CONV MLDSA_POINTWISE_NOIBT_SUBROUTINE_CORRECT)));;

(* ========================================================================= *)
(* Constant-time and memory safety proof.                                    *)
(* ========================================================================= *)

needs "x86/proofs/consttime.ml";;
needs "x86_64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:true
    (assoc "mldsa_pointwise_x86" subroutine_signatures)
    MLDSA_POINTWISE_CORRECT
    MLDSA_POINTWISE_TMC_EXEC;;

let MLDSA_POINTWISE_SAFE =
  REWRITE_RULE [MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS]
  (time prove
   (full_spec,
    REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; SOME_FLAGS] THEN
    PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars
      MLDSA_POINTWISE_TMC_EXEC));;

let MLDSA_POINTWISE_NOIBT_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a b consts pc stackpointer returnaddress.
          aligned 32 a /\ aligned 32 b /\ aligned 32 consts /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_tmc) (a, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_tmc) (b, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_tmc) (consts, 2496) /\
          nonoverlapping (a, 1024) (b, 1024) /\
          nonoverlapping (a, 1024) (consts, 2496) /\ nonoverlapping (b, 1024) (consts, 2496) /\
          nonoverlapping (stackpointer, 8) (a, 1024) /\
          nonoverlapping (stackpointer, 8) (b, 1024) /\
          nonoverlapping (stackpointer, 8) (consts, 2496)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) mldsa_pointwise_tmc /\
                    read RIP s = word pc /\ read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [a; b; consts] s /\ read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2. read events s = APPEND e2 e /\
                         e2 = f_events b consts a pc stackpointer returnaddress /\
                         memaccess_inbounds e2
                           [a,1024; b,1024; consts,2496; stackpointer,8]
                           [a,1024; stackpointer,8]))
               (\s s'. true)`,
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_pointwise_tmc
    MLDSA_POINTWISE_SAFE THEN DISCHARGE_SAFETY_PROPERTY_TAC);;

let MLDSA_POINTWISE_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a b consts pc stackpointer returnaddress.
          aligned 32 a /\ aligned 32 b /\ aligned 32 consts /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_mc) (a, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_mc) (b, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_pointwise_mc) (consts, 2496) /\
          nonoverlapping (a, 1024) (b, 1024) /\
          nonoverlapping (a, 1024) (consts, 2496) /\ nonoverlapping (b, 1024) (consts, 2496) /\
          nonoverlapping (stackpointer, 8) (a, 1024) /\
          nonoverlapping (stackpointer, 8) (b, 1024) /\
          nonoverlapping (stackpointer, 8) (consts, 2496)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) mldsa_pointwise_mc /\
                    read RIP s = word pc /\ read RSP s = stackpointer /\
                    read (memory :> bytes64 stackpointer) s = returnaddress /\
                    C_ARGUMENTS [a; b; consts] s /\ read events s = e)
               (\s. read RIP s = returnaddress /\
                    read RSP s = word_add stackpointer (word 8) /\
                    (exists e2. read events s = APPEND e2 e /\
                         e2 = f_events b consts a pc stackpointer returnaddress /\
                         memaccess_inbounds e2
                           [a,1024; b,1024; consts,2496; stackpointer,8]
                           [a,1024; stackpointer,8]))
               (\s s'. true)`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_POINTWISE_NOIBT_SUBROUTINE_SAFE));;
