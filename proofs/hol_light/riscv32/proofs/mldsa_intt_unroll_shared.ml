(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Straight symbolic execution of both RV32 inverse NTT implementations.     *)
(* ========================================================================= *)

needs "mldsa_native/riscv32/proofs/mldsa_ntt_unroll_shared.ml";;
needs "mldsa_native/riscv32/proofs/mldsa_unroll_shared.ml";;
needs "mldsa_native/riscv32/proofs/mldsa_intt_layout.ml";;

(* The slow normalization uses the same shift/add multiplication by q as
   the butterflies, applied to the rounded multiply-high quotient. *)

let RV32_MLDSA_INTT_UNROLL_SCALE_SLOW = prove
 (`!a:int32.
      let t =
        word_ishr
          (word_add
            (word_subword
              (word_mul
                (word_sx a:int64)
                (word_sx (word 16791564:int32):int64))
              (32,32):int32)
            (word 1))
          1 in
      word_sub
        (word_add
          (word_sub (word_mul a (word 16382)) t)
          (word_shl t 13))
        (word_shl (word_shl t 13) 10) =
      arm_mldsa_barmul (&4197891,word 16382) a`,
  GEN_TAC THEN
  REWRITE_TAC
   [LET_DEF; LET_END_DEF; MLDSA_Q_MUL_SHIFT_ADD;
    MLDSA_INTT_SCALE_MULH]);;

let RV32_MLDSA_INTT_UNROLL_DEFS slow =
  let scale =
    if slow then
      REWRITE_RULE[LET_DEF; LET_END_DEF]
        RV32_MLDSA_INTT_UNROLL_SCALE_SLOW
    else MLDSA_INTT_SCALE_MULH in
  GSYM(CONV_RULE
    (BINDER_CONV (LAND_CONV (DEPTH_CONV WORD_SX_CONV))) scale) ::
  RV32_MLDSA_NTT_UNROLL_BARRETT_DEFS slow;;

let RV32_MLDSA_INTT_UNROLL_LAYOUT_STEP_CONV =
  NUM_RED_CONV ORELSEC BETA_CONV ORELSEC WORD_IWORD_CONV ORELSEC
  GEN_REWRITE_CONV I
   [rv32_mldsa_intt_output;
    rv32_mldsa_intt_phase1234; rv32_mldsa_intt_phase4;
    rv32_mldsa_intt_phase123; rv32_mldsa_intt_phase3;
    rv32_mldsa_intt_phase12; rv32_mldsa_intt_phase2;
    rv32_mldsa_intt_phase1; rv32_mldsa_intt_radix4;
    LET_DEF; LET_END_DEF; COND_CLAUSES] ORELSEC
  RV32_MLDSA_NTT_UNROLL_LAYOUT_STEP_CONV;;

let RV32_MLDSA_INTT_UNROLL_LAYOUT_WITH_CONV =
  RV32_MLDSA_UNROLL_LAYOUT_WITH_CONV
    RV32_MLDSA_INTT_UNROLL_LAYOUT_STEP_CONV;;

let RV32_MLDSA_INTT_UNROLL_SPEC mc slow =
  let registers =
    if slow then
      `[PC; S0; S1; S2; S3; S4; S5; S6; S7;
        A1; T2; T3; T4; T5; A2; A3; A4; A5; A6; A7]`
    else
      `[PC; T0; S0; S1; S2; S3; S4; S5; S6; S7;
        A1; T2; T3; T4; T5; A2; A3; A4; A5; A6; A7]` in
  vsubst
   [mc,`code:byte list`;
    mk_small_numeral (if slow then 1020 else 824),`end_offset:num`;
    registers,`allowed_regs:((riscvstate,int32)component)list`]
   `!a zetas:int32. !x:num->int32. !pc:num.
      aligned 4 a /\ aligned 4 zetas /\
      nonoverlapping (word pc,LENGTH code) (a,1024) /\
      nonoverlapping (a,1024) (zetas,2040)
      ==> ensures riscv
        (\s. aligned_bytes_loaded s (word pc) code /\
             read PC s = word(pc + 36) /\
             C_ARGUMENTS [a;zetas] s /\
             wordlist_from_memory(zetas,510) s:int32 list =
               MAP iword rv32_mldsa_ntt_zetas /\
             (!i. i < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * i)))) s =
                 x i))
        (\s. read PC s = word(pc + end_offset) /\
             !i. i < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * i)))) s =
                 rv32_mldsa_intt_output x i)
        (MAYCHANGE (allowed_regs:((riscvstate,int32)component)list) ,,
         MAYCHANGE [memory :> bytes(a,1024)] ,,
         MAYCHANGE [events])`;;

let RV32_MLDSA_INTT_UNROLL_RULE mc exec slow =
  prove
   (RV32_MLDSA_INTT_UNROLL_SPEC mc slow,
    RV32_MLDSA_UNROLL_WITH_CACHES_TAC
     (REWRITE_TAC[fst exec; C_ARGUMENTS] THEN
      REPEAT STRIP_TAC THEN
      CONV_TAC(RATOR_CONV(LAND_CONV
        (ONCE_DEPTH_CONV EXPAND_CASES_CONV))) THEN
      CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
      REWRITE_TAC[rv32_mldsa_ntt_zetas; MAP; CONS_11] THEN
      CONV_TAC(ONCE_DEPTH_CONV WORD_IWORD_CONV) THEN
      CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ADD_0] THEN
      RV32_MLDSA_UNROLL_TAC exec
        (if slow then 15774 else 11936) 510
        [mldsa_barrett_mul; arm_mldsa_barmul]
        (RV32_MLDSA_INTT_UNROLL_DEFS slow)
        RV32_MLDSA_INTT_UNROLL_LAYOUT_WITH_CONV));;
