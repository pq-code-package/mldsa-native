(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* Symbolically execute the complete RV32-IM forward NTT core.
   The shared unrolling helper proves exact output words without input
   bounds. The existing arithmetic theorem supplies the mathematical NTT
   and output bounds. Keep the public correctness and safety claims
   unchanged. *)

let rv32_ntt_unroll_started = Unix.gettimeofday();;
needs "s2n_bignum/riscv/proofs/base.ml";;

let mldsa_ntt_mc = define_assert_from_elf
  "mldsa_ntt_mc" "riscv32/mldsa/mldsa_ntt_rv32im_asm.o"
(*** BYTECODE START ***)
[
  0xfe010113;       (* riscv_ADDI SP SP (word 4294967264) *)
  0x00812023;       (* riscv_SW S0 SP (word 0) *)
  0x00912223;       (* riscv_SW S1 SP (word 4) *)
  0x01212423;       (* riscv_SW S2 SP (word 8) *)
  0x01312623;       (* riscv_SW S3 SP (word 12) *)
  0x01412823;       (* riscv_SW S4 SP (word 16) *)
  0x01512a23;       (* riscv_SW S5 SP (word 20) *)
  0x007fe2b7;       (* riscv_LUI T0 (word 8380416) *)
  0x00128293;       (* riscv_ADDI T0 T0 (word 1) *)
  0x0005a403;       (* riscv_LW S0 A1 (word 0) *)
  0x0045a483;       (* riscv_LW S1 A1 (word 4) *)
  0x0085a903;       (* riscv_LW S2 A1 (word 8) *)
  0x00c5a983;       (* riscv_LW S3 A1 (word 12) *)
  0x0105aa03;       (* riscv_LW S4 A1 (word 16) *)
  0x0145aa83;       (* riscv_LW S5 A1 (word 20) *)
  0x01858593;       (* riscv_ADDI A1 A1 (word 24) *)
  0x00050393;       (* riscv_ADDI T2 A0 (word 0) *)
  0x10050e93;       (* riscv_ADDI T4 A0 (word 256) *)
  0x0003a603;       (* riscv_LW A2 T2 (word 0) *)
  0x1003a683;       (* riscv_LW A3 T2 (word 256) *)
  0x2003a703;       (* riscv_LW A4 T2 (word 512) *)
  0x3003a783;       (* riscv_LW A5 T2 (word 768) *)
  0x029718b3;       (* riscv_MULH A7 A4 S1 *)
  0x02870833;       (* riscv_MUL A6 A4 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x41060733;       (* riscv_SUB A4 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x029798b3;       (* riscv_MULH A7 A5 S1 *)
  0x02878833;       (* riscv_MUL A6 A5 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410687b3;       (* riscv_SUB A5 A3 A6 *)
  0x010686b3;       (* riscv_ADD A3 A3 A6 *)
  0x033698b3;       (* riscv_MULH A7 A3 S3 *)
  0x03268833;       (* riscv_MUL A6 A3 S2 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410606b3;       (* riscv_SUB A3 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x035798b3;       (* riscv_MULH A7 A5 S5 *)
  0x03478833;       (* riscv_MUL A6 A5 S4 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410707b3;       (* riscv_SUB A5 A4 A6 *)
  0x01070733;       (* riscv_ADD A4 A4 A6 *)
  0x00c3a023;       (* riscv_SW A2 T2 (word 0) *)
  0x10d3a023;       (* riscv_SW A3 T2 (word 256) *)
  0x20e3a023;       (* riscv_SW A4 T2 (word 512) *)
  0x30f3a023;       (* riscv_SW A5 T2 (word 768) *)
  0x00438393;       (* riscv_ADDI T2 T2 (word 4) *)
  0xf7d39ee3;       (* riscv_BNE T2 T4 (word 4294967164) *)
  0x00050393;       (* riscv_ADDI T2 A0 (word 0) *)
  0x40050e13;       (* riscv_ADDI T3 A0 (word 1024) *)
  0x0005a403;       (* riscv_LW S0 A1 (word 0) *)
  0x0045a483;       (* riscv_LW S1 A1 (word 4) *)
  0x0085a903;       (* riscv_LW S2 A1 (word 8) *)
  0x00c5a983;       (* riscv_LW S3 A1 (word 12) *)
  0x0105aa03;       (* riscv_LW S4 A1 (word 16) *)
  0x0145aa83;       (* riscv_LW S5 A1 (word 20) *)
  0x01858593;       (* riscv_ADDI A1 A1 (word 24) *)
  0x04038e93;       (* riscv_ADDI T4 T2 (word 64) *)
  0x0003a603;       (* riscv_LW A2 T2 (word 0) *)
  0x0403a683;       (* riscv_LW A3 T2 (word 64) *)
  0x0803a703;       (* riscv_LW A4 T2 (word 128) *)
  0x0c03a783;       (* riscv_LW A5 T2 (word 192) *)
  0x029718b3;       (* riscv_MULH A7 A4 S1 *)
  0x02870833;       (* riscv_MUL A6 A4 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x41060733;       (* riscv_SUB A4 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x029798b3;       (* riscv_MULH A7 A5 S1 *)
  0x02878833;       (* riscv_MUL A6 A5 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410687b3;       (* riscv_SUB A5 A3 A6 *)
  0x010686b3;       (* riscv_ADD A3 A3 A6 *)
  0x033698b3;       (* riscv_MULH A7 A3 S3 *)
  0x03268833;       (* riscv_MUL A6 A3 S2 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410606b3;       (* riscv_SUB A3 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x035798b3;       (* riscv_MULH A7 A5 S5 *)
  0x03478833;       (* riscv_MUL A6 A5 S4 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410707b3;       (* riscv_SUB A5 A4 A6 *)
  0x01070733;       (* riscv_ADD A4 A4 A6 *)
  0x00c3a023;       (* riscv_SW A2 T2 (word 0) *)
  0x04d3a023;       (* riscv_SW A3 T2 (word 64) *)
  0x08e3a023;       (* riscv_SW A4 T2 (word 128) *)
  0x0cf3a023;       (* riscv_SW A5 T2 (word 192) *)
  0x00438393;       (* riscv_ADDI T2 T2 (word 4) *)
  0xf7d39ee3;       (* riscv_BNE T2 T4 (word 4294967164) *)
  0x0c038393;       (* riscv_ADDI T2 T2 (word 192) *)
  0xf5c39ae3;       (* riscv_BNE T2 T3 (word 4294967124) *)
  0x00050393;       (* riscv_ADDI T2 A0 (word 0) *)
  0x40050e13;       (* riscv_ADDI T3 A0 (word 1024) *)
  0x0005a403;       (* riscv_LW S0 A1 (word 0) *)
  0x0045a483;       (* riscv_LW S1 A1 (word 4) *)
  0x0085a903;       (* riscv_LW S2 A1 (word 8) *)
  0x00c5a983;       (* riscv_LW S3 A1 (word 12) *)
  0x0105aa03;       (* riscv_LW S4 A1 (word 16) *)
  0x0145aa83;       (* riscv_LW S5 A1 (word 20) *)
  0x01858593;       (* riscv_ADDI A1 A1 (word 24) *)
  0x01038e93;       (* riscv_ADDI T4 T2 (word 16) *)
  0x0003a603;       (* riscv_LW A2 T2 (word 0) *)
  0x0103a683;       (* riscv_LW A3 T2 (word 16) *)
  0x0203a703;       (* riscv_LW A4 T2 (word 32) *)
  0x0303a783;       (* riscv_LW A5 T2 (word 48) *)
  0x029718b3;       (* riscv_MULH A7 A4 S1 *)
  0x02870833;       (* riscv_MUL A6 A4 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x41060733;       (* riscv_SUB A4 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x029798b3;       (* riscv_MULH A7 A5 S1 *)
  0x02878833;       (* riscv_MUL A6 A5 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410687b3;       (* riscv_SUB A5 A3 A6 *)
  0x010686b3;       (* riscv_ADD A3 A3 A6 *)
  0x033698b3;       (* riscv_MULH A7 A3 S3 *)
  0x03268833;       (* riscv_MUL A6 A3 S2 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410606b3;       (* riscv_SUB A3 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x035798b3;       (* riscv_MULH A7 A5 S5 *)
  0x03478833;       (* riscv_MUL A6 A5 S4 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410707b3;       (* riscv_SUB A5 A4 A6 *)
  0x01070733;       (* riscv_ADD A4 A4 A6 *)
  0x00c3a023;       (* riscv_SW A2 T2 (word 0) *)
  0x00d3a823;       (* riscv_SW A3 T2 (word 16) *)
  0x02e3a023;       (* riscv_SW A4 T2 (word 32) *)
  0x02f3a823;       (* riscv_SW A5 T2 (word 48) *)
  0x00438393;       (* riscv_ADDI T2 T2 (word 4) *)
  0xf7d39ee3;       (* riscv_BNE T2 T4 (word 4294967164) *)
  0x03038393;       (* riscv_ADDI T2 T2 (word 48) *)
  0xf5c39ae3;       (* riscv_BNE T2 T3 (word 4294967124) *)
  0x00050393;       (* riscv_ADDI T2 A0 (word 0) *)
  0x40050e13;       (* riscv_ADDI T3 A0 (word 1024) *)
  0x0005a403;       (* riscv_LW S0 A1 (word 0) *)
  0x0045a483;       (* riscv_LW S1 A1 (word 4) *)
  0x0085a903;       (* riscv_LW S2 A1 (word 8) *)
  0x00c5a983;       (* riscv_LW S3 A1 (word 12) *)
  0x0105aa03;       (* riscv_LW S4 A1 (word 16) *)
  0x0145aa83;       (* riscv_LW S5 A1 (word 20) *)
  0x01858593;       (* riscv_ADDI A1 A1 (word 24) *)
  0x0003a603;       (* riscv_LW A2 T2 (word 0) *)
  0x0043a683;       (* riscv_LW A3 T2 (word 4) *)
  0x0083a703;       (* riscv_LW A4 T2 (word 8) *)
  0x00c3a783;       (* riscv_LW A5 T2 (word 12) *)
  0x029718b3;       (* riscv_MULH A7 A4 S1 *)
  0x02870833;       (* riscv_MUL A6 A4 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x41060733;       (* riscv_SUB A4 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x029798b3;       (* riscv_MULH A7 A5 S1 *)
  0x02878833;       (* riscv_MUL A6 A5 S0 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410687b3;       (* riscv_SUB A5 A3 A6 *)
  0x010686b3;       (* riscv_ADD A3 A3 A6 *)
  0x033698b3;       (* riscv_MULH A7 A3 S3 *)
  0x03268833;       (* riscv_MUL A6 A3 S2 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410606b3;       (* riscv_SUB A3 A2 A6 *)
  0x01060633;       (* riscv_ADD A2 A2 A6 *)
  0x035798b3;       (* riscv_MULH A7 A5 S5 *)
  0x03478833;       (* riscv_MUL A6 A5 S4 *)
  0x025888b3;       (* riscv_MUL A7 A7 T0 *)
  0x41180833;       (* riscv_SUB A6 A6 A7 *)
  0x410707b3;       (* riscv_SUB A5 A4 A6 *)
  0x01070733;       (* riscv_ADD A4 A4 A6 *)
  0x00c3a023;       (* riscv_SW A2 T2 (word 0) *)
  0x00d3a223;       (* riscv_SW A3 T2 (word 4) *)
  0x00e3a423;       (* riscv_SW A4 T2 (word 8) *)
  0x00f3a623;       (* riscv_SW A5 T2 (word 12) *)
  0x01038393;       (* riscv_ADDI T2 T2 (word 16) *)
  0xf7c390e3;       (* riscv_BNE T2 T3 (word 4294967136) *)
  0x00012403;       (* riscv_LW S0 SP (word 0) *)
  0x00412483;       (* riscv_LW S1 SP (word 4) *)
  0x00812903;       (* riscv_LW S2 SP (word 8) *)
  0x00c12983;       (* riscv_LW S3 SP (word 12) *)
  0x01012a03;       (* riscv_LW S4 SP (word 16) *)
  0x01412a83;       (* riscv_LW S5 SP (word 20) *)
  0x02010113;       (* riscv_ADDI SP SP (word 32) *)
  0x00008067       (* riscv_JALR ZERO RA (word 0) *)
];;
(*** BYTECODE END ***)

let MLDSA_NTT_EXEC = RISCV_MK_EXEC_RULE mldsa_ntt_mc;;

let LENGTH_MLDSA_NTT_MC =
  REWRITE_CONV[mldsa_ntt_mc] `LENGTH mldsa_ntt_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let MLDSA_NTT_PREAMBLE_LENGTH = new_definition
  `MLDSA_NTT_PREAMBLE_LENGTH = 28`;;

let MLDSA_NTT_POSTAMBLE_LENGTH = new_definition
  `MLDSA_NTT_POSTAMBLE_LENGTH = 32`;;

let MLDSA_NTT_CORE_START = new_definition
  `MLDSA_NTT_CORE_START = MLDSA_NTT_PREAMBLE_LENGTH`;;

let MLDSA_NTT_CORE_END = new_definition
  `MLDSA_NTT_CORE_END =
   LENGTH mldsa_ntt_mc - MLDSA_NTT_POSTAMBLE_LENGTH`;;

let MLDSA_NTT_LENGTH_SIMPLIFY_CONV =
  REWRITE_CONV
    [LENGTH_MLDSA_NTT_MC;
     MLDSA_NTT_CORE_START; MLDSA_NTT_CORE_END;
     MLDSA_NTT_PREAMBLE_LENGTH; MLDSA_NTT_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV[ADD_0];;

needs "mldsa_native/riscv32/proofs/mldsa_ntt_unroll_shared.ml";;

let RV32_MLDSA_NTT_UNROLLED =
  RV32_MLDSA_NTT_UNROLL_RULE
    (lhs(concl mldsa_ntt_mc)) MLDSA_NTT_EXEC false;;
Printf.printf "CHECKED FAST NTT UNROLL COMPLETE elapsed=%.3f\n%!"
  (Unix.gettimeofday() -. rv32_ntt_unroll_started);;

needs "mldsa_native/riscv32/proofs/mldsa_ntt_arithmetic.ml";;

let MLDSA_NTT_CORE_CORRECT = prove
 (`!a zetas:int32. !x:num->int32. !pc:num.
    aligned 4 a /\
    aligned 4 zetas /\
    nonoverlapping ((word pc):int32,LENGTH mldsa_ntt_mc) (a,1024) /\
    nonoverlapping (a,1024) (zetas,2040)
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_ntt_mc /\
           read PC s = word (pc + MLDSA_NTT_CORE_START) /\
           C_ARGUMENTS [a;zetas] s /\
           wordlist_from_memory (zetas,510) s:int32 list =
             MAP iword rv32_mldsa_ntt_zetas /\
           (!i. i < 256 ==> abs(ival(x i)) < &8380417) /\
           (!i. i < 256 ==>
             read(memory :> bytes32(word_add a (word(4 * i)))) s =
             x i))
      (\s. read PC s = word (pc + MLDSA_NTT_CORE_END) /\
           !i. i < 256 ==>
             let zi =
               read(memory :> bytes32(word_add a (word(4 * i)))) s in
             (ival zi == mldsa_bitreverse_forward_ntt (ival o x) i)
               (mod &8380417) /\
             abs(ival zi) < &94279698)
      (MAYCHANGE
        [PC; T0; S0; S1; S2; S3; S4; S5;
         A1; T2; T3; T4; A2; A3; A4; A5; A6; A7] ,,
       MAYCHANGE [memory :> bytes(a,1024)] ,,
       MAYCHANGE [events])`,
  MAP_EVERY X_GEN_TAC
   [`a:int32`; `zetas:int32`; `x:num->int32`; `pc:num`] THEN
  REPEAT STRIP_TAC THEN
  GLOBALIZE_PRECONDITION_TAC THEN
  MP_TAC
   (SPECL
     [`a:int32`; `zetas:int32`; `x:num->int32`; `pc:num`]
     RV32_MLDSA_NTT_UNROLLED) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(LABEL_TAC "machine") THEN
  MATCH_MP_TAC ENSURES_PREPOSTCONDITION_THM THEN
  USE_THEN "machine"
   (fun th ->
     let tm = concl th in
     MAP_EVERY EXISTS_TAC
      [rand(rator(rator tm)); rand(rator tm)]) THEN
  REPEAT CONJ_TAC THENL
   [CONV_TAC MLDSA_NTT_LENGTH_SIMPLIFY_CONV THEN
    BETA_TAC THEN REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    FIRST_X_ASSUM MATCH_MP_TAC THEN
    ASM_ARITH_TAC;
    CONV_TAC MLDSA_NTT_LENGTH_SIMPLIFY_CONV THEN
    BETA_TAC THEN X_GEN_TAC `s:riscvstate` THEN
    DISCH_THEN
     (fun th ->
       let ths = CONJUNCTS th in
       MAP_EVERY ASSUME_TAC ths THEN
       LABEL_TAC "outputs" (last ths)) THEN
    ASM_REWRITE_TAC[] THEN
    X_GEN_TAC `i:num` THEN DISCH_TAC THEN
    CONV_TAC let_CONV THEN
    SUBGOAL_THEN
     `read
       (memory :>
        bytes32 (word_add a (word (4 * i)))) s =
      rv32_mldsa_ntt_phase1234 x (i DIV 4) (i MOD 4)`
    SUBST1_TAC THENL
     [USE_THEN "outputs" (MATCH_MP_TAC o SPEC `i:num`) THEN
      ASM_REWRITE_TAC[];
      MP_TAC
       (SPEC `x:num->int32`
         RV32_MLDSA_NTT_PHASE1234_CORRECT) THEN
      ASM_REWRITE_TAC[] THEN
      DISCH_THEN(MP_TAC o SPEC `i:num`) THEN
      ASM_REWRITE_TAC[]];
    USE_THEN "machine" ACCEPT_TAC]);;
Printf.printf "CHECKED FAST NTT CORE COMPLETE elapsed=%.3f\n%!"
  (Unix.gettimeofday() -. rv32_ntt_unroll_started);;

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/rv32im/src/arith_native_rv32im.h *)

let MLDSA_NTT_SUBROUTINE_CORRECT = prove
 (`!a zetas:int32. !x:num->int32. !pc:num.
    !stackpointer returnaddress:int32.
    aligned 4 a /\
    aligned 4 zetas /\
    aligned 16 stackpointer /\
    aligned 4 returnaddress /\
    ALLPAIRS nonoverlapping
      [(a,1024);
       (word_sub stackpointer (word 32),32)]
      [((word pc):int32,LENGTH mldsa_ntt_mc);
       (zetas,2040)] /\
    nonoverlapping (a,1024)
      (word_sub stackpointer (word 32),32)
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_ntt_mc /\
           read PC s = word pc /\
           read SP s = stackpointer /\
           read RA s = returnaddress /\
           C_ARGUMENTS [a;zetas] s /\
           wordlist_from_memory (zetas,510) s:int32 list =
             MAP iword rv32_mldsa_ntt_zetas /\
           (!i. i < 256 ==> abs(ival(x i)) < &8380417) /\
           (!i. i < 256 ==>
             read(memory :> bytes32(word_add a (word(4 * i)))) s =
             x i))
      (\s. read PC s = returnaddress /\
           read SP s = stackpointer /\
           !i. i < 256 ==>
             let zi =
               read(memory :> bytes32(word_add a (word(4 * i)))) s in
             (ival zi == mldsa_bitreverse_forward_ntt (ival o x) i)
               (mod &8380417) /\
             abs(ival zi) < &94279698)
      (MAYCHANGE_REGS_PERMITTED_BY_ABI ,,
       MAYCHANGE
        [memory :> bytes(a,1024);
         memory :> bytes(word_sub stackpointer (word 32),32)])`,
  REWRITE_TAC[fst MLDSA_NTT_EXEC] THEN
  RISCV_ADD_RETURN_STACK_TAC
    ~core_precondition_tac:RV32_MLDSA_NTT_STACK_TABLE_TAC
    MLDSA_NTT_EXEC
    (REWRITE_RULE[fst MLDSA_NTT_EXEC]
      (CONV_RULE MLDSA_NTT_LENGTH_SIMPLIFY_CONV
        MLDSA_NTT_CORE_CORRECT))
    `[S0; S1; S2; S3; S4; S5]` 32);;
Printf.printf "CHECKED FAST NTT SUBROUTINE COMPLETE elapsed=%.3f\n%!"
  (Unix.gettimeofday() -. rv32_ntt_unroll_started);;

(* The timing model assumes operand-independent MUL and MULH latency. *)

needs "s2n_bignum/riscv/proofs/consttime.ml";;
needs "mldsa_native/riscv32/proofs/consttime_aux.ml";;

let mldsa_ntt_rv32im_signature =
  ([("a","int32_t[static 256]","false");
    ("zetas","int32_t[static 510]","true")],
   "void",
   [("a","256",4);
    ("zetas","510",4)],
   [("a","256",4)],
   []);;

let mldsa_ntt_full_spec,mldsa_ntt_public_vars =
  mk_safety_spec
    ~keep_maychanges:false
    mldsa_ntt_rv32im_signature
    MLDSA_NTT_SUBROUTINE_CORRECT
    MLDSA_NTT_EXEC;;

let MLDSA_NTT_SUBROUTINE_SAFE = time prove
 (`exists f_events.
   forall e a zetas pc stackpointer returnaddress.
     aligned 4 a /\
     aligned 4 zetas /\
     aligned 16 stackpointer /\
     aligned 4 returnaddress /\
     ALLPAIRS nonoverlapping
       [a,1024; word_sub stackpointer (word 32),32]
       [word pc,LENGTH mldsa_ntt_mc; zetas,2040] /\
     nonoverlapping (a,1024)
       (word_sub stackpointer (word 32),32)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_ntt_mc /\
               read PC s = word pc /\
               read SP s = stackpointer /\
               read RA s = returnaddress /\
               C_ARGUMENTS [a;zetas] s /\
               read events s = e)
          (\s. read PC s = returnaddress /\
               exists e2.
                 read events s = APPEND e2 e /\
                 e2 =
                   f_events zetas a pc
                     (word_sub stackpointer (word 32)) returnaddress /\
                 memaccess_inbounds e2
                   [a,1024; zetas,2040;
                    word_sub stackpointer (word 32),32]
                   [a,1024; word_sub stackpointer (word 32),32])
          (\s s'. true)`,
  ASSERT_CONCL_TAC mldsa_ntt_full_spec THEN
  PROVE_SAFETY_SPEC_TAC
    ~defer_witness:true
    ~public_vars:mldsa_ntt_public_vars
    MLDSA_NTT_EXEC);;
Printf.printf "CHECKED FAST NTT SAFETY COMPLETE elapsed=%.3f\n%!"
  (Unix.gettimeofday() -. rv32_ntt_unroll_started);;
