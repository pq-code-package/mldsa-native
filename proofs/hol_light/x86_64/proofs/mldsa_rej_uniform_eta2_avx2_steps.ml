(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* The eta2 instruction proofs load these tactics after defining the
   machine code and the sampling specification. The tactics establish
   the arithmetic and state updates used by the vector and scalar loops. *)

needs "mldsa_native/x86_64/proofs/mldsa_rej_eta_avx2_common.ml";;

module Make_rej_uniform_eta2_steps(Input : sig
  val trimmed_code : thm
  val reduce_nibble : thm
  val nibbles : thm
  val sample_bytes : thm
end) = struct
  let mldsa_rej_uniform_eta2_tmc = Input.trimmed_code;;
  let mulhrs_eta2 = Input.reduce_nibble;;
  let REJ_NIBBLES_ETA2 = Input.nibbles;;
  let REJ_SAMPLE_ETA2_BYTES = Input.sample_bytes;;

  (*** Bytecode extracted from mldsa_rej_uniform_eta2_avx2_asm.o (.text section) ***)

  let REJ_NIBBLES_ETA2_EMPTY = prove
   (`REJ_NIBBLES_ETA2 [] = []`,
    REWRITE_TAC[REJ_NIBBLES_ETA2; NIBBLES_OF_BYTES; FILTER]);;

  let REJ_NIBBLES_ETA2_APPEND = prove
   (`!l1 l2. REJ_NIBBLES_ETA2(APPEND l1 l2) =
             APPEND (REJ_NIBBLES_ETA2 l1) (REJ_NIBBLES_ETA2 l2)`,
    REWRITE_TAC[REJ_NIBBLES_ETA2; NIBBLES_OF_BYTES_APPEND; FILTER_APPEND]);;

  (* Loop step: peel off 16 bytes per iteration. Used in loop body.            *)
  let REJ_NIBBLES_ETA2_STEP_16 = prove
   (`!inlist:byte list. !i:num.
     16 * (i + 1) <= LENGTH inlist
     ==> REJ_NIBBLES_ETA2(SUB_LIST(0, 16 * (i + 1)) inlist) =
         APPEND (REJ_NIBBLES_ETA2(SUB_LIST(0, 16 * i) inlist))
                (REJ_NIBBLES_ETA2(SUB_LIST(16 * i, 16) inlist))`,
    REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM REJ_NIBBLES_ETA2_APPEND] THEN
    AP_TERM_TAC THEN
    SUBGOAL_THEN `16 * (i + 1) = 0 + 16 * i + 16` SUBST1_TAC THENL
     [ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[SUB_LIST_SPLIT; SUB_LIST_CLAUSES; APPEND; ADD_CLAUSES]);;

  (* Length bound on filtered nibbles - used for ABBREV bounds                 *)
  let LENGTH_REJ_NIBBLES_ETA2 = prove
   (`!l:byte list. LENGTH(REJ_NIBBLES_ETA2 l) <= 2 * LENGTH l`,
    GEN_TAC THEN REWRITE_TAC[REJ_NIBBLES_ETA2] THEN
    TRANS_TAC LE_TRANS `LENGTH(NIBBLES_OF_BYTES l:int16 list)` THEN
    CONJ_TAC THENL [REWRITE_TAC[LENGTH_FILTER]; ALL_TAC] THEN
    SPEC_TAC(`l:byte list`,`l:byte list`) THEN
    LIST_INDUCT_TAC THEN
    ASM_REWRITE_TAC[NIBBLES_OF_BYTES; LENGTH; NIBBLE_PAIR;
                    APPEND; LENGTH_APPEND; LE_0] THEN
    UNDISCH_TAC `LENGTH(NIBBLES_OF_BYTES t:int16 list) <=
                 2 * LENGTH(t:byte list)` THEN ARITH_TAC);;

  (* General prefix monotonicity of the accepted-nibble count.                 *)
  let NIBLEN_PREFIX_MONO = prove
   (`!l:byte list a b. a <= b
       ==> LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,a) l):int16 list) <=
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,b) l):int16 list)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `SUB_LIST(0,b) (l:byte list) =
                  APPEND (SUB_LIST(0,a) l) (SUB_LIST(a,b-a) l)` SUBST1_TAC THENL
     [MP_TAC(ISPECL [`l:byte list`; `a:num`; `b - a`; `0`] SUB_LIST_SPLIT) THEN
      ASM_SIMP_TAC[ARITH_RULE `a <= b ==> a + (b - a) = b`; ADD_CLAUSES];
      REWRITE_TAC[REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND] THEN ARITH_TAC]);;

  (* ========================================================================= *)
  (* eta2 CORRECT: sub-iter list decomposition + coefficient bounds.           *)
  (* The eta2 coefficient bound is [-2,2] (ival in (-3,3)).                    *)
  (* Uses REJ_NIBBLES_ETA2, REJ_SAMPLE_ETA2_BYTES.                             *)
  (* ========================================================================= *)

  (* REJ_SAMPLE_ETA2_BYTES decomposition: append on lists.                     *)
  let REJ_SAMPLE_ETA2_BYTES_APPEND = prove
   (`!l1 l2:byte list. REJ_SAMPLE_ETA2_BYTES (APPEND l1 l2) =
                       APPEND (REJ_SAMPLE_ETA2_BYTES l1)
                              (REJ_SAMPLE_ETA2_BYTES l2)`,
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2_APPEND; MAP_APPEND]);;

  (* int32-list length = int16-nibble-list length (MAP preserves length).      *)
  let LENGTH_REJ_SAMPLE_ETA2_BYTES = prove
   (`!l:byte list.
       LENGTH(REJ_SAMPLE_ETA2_BYTES l:int32 list) =
       LENGTH(REJ_NIBBLES_ETA2 l:int16 list)`,
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; LENGTH_MAP]);;

  let LENGTH_REJ_SAMPLE_ETA2_BYTES_BOUND = prove
   (`!l:byte list. LENGTH(REJ_SAMPLE_ETA2_BYTES l:int32 list) <= 2 * LENGTH l`,
    GEN_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; LENGTH_REJ_NIBBLES_ETA2]);;

  (* Generic prefix monotonicity for the int32 form.                           *)
  let LENGTH_REJ_SAMPLE_ETA2_BYTES_APPEND_LE = prove
   (`!l1 l2:byte list.
       LENGTH(REJ_SAMPLE_ETA2_BYTES l1:int32 list) <=
       LENGTH(REJ_SAMPLE_ETA2_BYTES (APPEND l1 l2):int32 list)`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_APPEND; LENGTH_APPEND] THEN ARITH_TAC);;

  (* SUB_LIST length cap: outlist length <= 256.                               *)
  let LENGTH_SUB_LIST_REJ_SAMPLE_ETA2_BYTES = prove
   (`!(l:byte list).
       LENGTH(SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES l):int32 list) <= 256`,
    GEN_TAC THEN REWRITE_TAC[LENGTH_SUB_LIST] THEN ARITH_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* Coefficient bound: each accepted eta2 coefficient is in [-2,2], i.e.      *)
  (* ival in (-3,3). Ported from arm-eta2 REJ_SAMPLE_ETA2_ELEMENT_BOUND.       *)
  (* ------------------------------------------------------------------------- *)

  let REJ_SAMPLE_ETA2_ELEMENT_BOUND = prove
   (`!x:int16. val x < 15
      ==> ival(word_sx(word_sub (word 2:int16) (word_umod x (word 5:int16))):int32) < &3 /\
          -- &3 < ival(word_sx(word_sub (word 2:int16) (word_umod x (word 5:int16))):int32)`,
    GEN_TAC THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`x:int16`; `word 5:int16`] VAL_WORD_UMOD) THEN
    REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN CONV_TAC NUM_REDUCE_CONV THEN
    DISCH_TAC THEN
    SUBGOAL_THEN `word_umod (x:int16) (word 5) = word(val x MOD 5):int16`
      SUBST1_TAC THENL
     [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
      CONV_TAC NUM_REDUCE_CONV THEN
      CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
      UNDISCH_TAC `val(x:int16) < 15` THEN ARITH_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `val(x:int16) MOD 5 = 0 \/ val x MOD 5 = 1 \/
                  val x MOD 5 = 2 \/ val x MOD 5 = 3 \/ val x MOD 5 = 4` MP_TAC THENL
     [MP_TAC(SPECL [`val(x:int16)`; `5`] MOD_LT_EQ) THEN ARITH_TAC;
      ALL_TAC] THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV));;

  (* Per-element form over the int32 sample list (for SUBROUTINE array_bound). *)
  let REJ_SAMPLE_ETA2_BYTES_COEFF_BOUND = prove
   (`!(l:byte list) c:int32.
       MEM c (REJ_SAMPLE_ETA2_BYTES l)
       ==> --(&3):int < ival c /\ ival c < &3`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2; MEM_MAP; MEM_FILTER] THEN
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    MP_TAC(ISPEC `x:int16` REJ_SAMPLE_ETA2_ELEMENT_BOUND) THEN
    ASM_REWRITE_TAC[] THEN INT_ARITH_TAC);;

  let REJ_SAMPLE_ETA2_BYTES_EL_BOUND = prove
   (`!(l:byte list) i.
       i < LENGTH(SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES l):int32 list)
       ==> ival(EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES l):int32 list)) < &3 /\
           -- &3 < ival(EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES l):int32 list))`,
    REPEAT GEN_TAC THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`l:byte list`;
                   `EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES (l:byte list)):int32 list):int32`]
                  REJ_SAMPLE_ETA2_BYTES_COEFF_BOUND) THEN
    ANTS_TAC THENL
     [MP_TAC(ISPECL [`REJ_SAMPLE_ETA2_BYTES (l:byte list):int32 list`; `256`]
                    SUB_LIST_TOPSPLIT) THEN
      DISCH_THEN(fun th ->
        GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV) [SYM th]) THEN
      REWRITE_TAC[MEM_APPEND] THEN DISJ1_TAC THEN
      MATCH_MP_TAC MEM_EL THEN ASM_REWRITE_TAC[];
      INT_ARITH_TAC]);;

  (* Strengthen-post lemma: ensures with implied stronger post. (Generic.)     *)
  let VAL_WORD_ZX_BYTE_LT_15 = prove
   (`!b:byte. (val (word_zx b:int16) < 15) <=> (val b < 15)`,
    GEN_TAC THEN AP_THM_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC VAL_WORD_ZX THEN
    REWRITE_TAC[DIMINDEX_8; DIMINDEX_16] THEN ARITH_TAC);;

  (* popcnt low-byte bound <= 8.                                               *)
  let VPSUBB_SIGN_BIT_LT_15 = prove
   (`!a:byte. val a < 16
       ==> (bit 7 (word_sub a (word 15):byte) <=> val a < 15)`,
    GEN_TAC THEN DISCH_TAC THEN
    REWRITE_TAC[BIT_VAL; DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[VAL_WORD_SUB; DIMINDEX_8; VAL_WORD] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    ASM_CASES_TAC `val(a:byte) < 15` THEN ASM_REWRITE_TAC[] THENL
     [SUBGOAL_THEN `(val(a:byte) + 241) MOD 256 = val a + 241`
      SUBST1_TAC THENL
       [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC(MESON[ODD; ARITH_RULE `ODD 1`] `n = 1 ==> ODD n`) THEN
      MATCH_MP_TAC DIV_UNIQ THEN
      EXISTS_TAC `val(a:byte) + 113` THEN ASM_ARITH_TAC;
      REWRITE_TAC[NOT_ODD] THEN
      SUBGOAL_THEN `(val(a:byte) + 241) MOD 256 = val a - 15`
      SUBST1_TAC THENL
       [SUBGOAL_THEN `val(a:byte) + 241 = (val a - 15) + 1 * 256`
        SUBST1_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        REWRITE_TAC[MOD_MULT_ADD] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC;
        ALL_TAC] THEN
      SIMP_TAC[DIV_LT; EVEN] THEN ASM_ARITH_TAC]);;

  (* Nibble-extraction helpers (threshold-independent).                        *)
  let LENGTH_FILTER_LT_15_MAP_WORD_ZX = prove
   (`!l:byte list. LENGTH(FILTER (\x:int16. val x < 15) (MAP word_zx l)) =
                    LENGTH(FILTER (\x:byte. val x < 15) l)`,
    LIST_INDUCT_TAC THEN
    REWRITE_TAC[MAP; FILTER; LENGTH; VAL_WORD_ZX_BYTE_LT_15] THEN
    COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

  (* Byte-form LENGTH FILTER for the 8 nibbles of 4 bytes = REJ_NIBBLES_ETA2.  *)
  let LENGTH_FILTER_BYTE_NIBBLES_4_BYTES = prove
   (`!(b0:byte) (b1:byte) (b2:byte) (b3:byte).
       LENGTH(FILTER (\x:byte. val x < 15)
               [word(val b0 MOD 16); word(val b0 DIV 16);
                word(val b1 MOD 16); word(val b1 DIV 16);
                word(val b2 MOD 16); word(val b2 DIV 16);
                word(val b3 MOD 16); word(val b3 DIV 16)]) =
       LENGTH(REJ_NIBBLES_ETA2 [b0;b1;b2;b3]:int16 list)`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_NIBBLES_ETA2; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THEN
    CONV_TAC SYM_CONV THEN
    MP_TAC(SPEC
     `[word(val(b0:byte) MOD 16); word(val(b0:byte) DIV 16);
       word(val(b1:byte) MOD 16); word(val(b1:byte) DIV 16);
       word(val(b2:byte) MOD 16); word(val(b2:byte) DIV 16);
       word(val(b3:byte) MOD 16); word(val(b3:byte) DIV 16)]:byte list`
     LENGTH_FILTER_LT_15_MAP_WORD_ZX) THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN
    REWRITE_TAC[MAP] THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
    REWRITE_TAC[CONS_11; PAIR_EQ] THEN
    REPEAT CONJ_TAC THEN CONV_TAC SYM_CONV THEN
    MATCH_MP_TAC WORD_ZX_BYTE_TO_INT16 THEN
    MP_TAC(ISPEC `b0:byte` VAL_BOUND) THEN
    MP_TAC(ISPEC `b1:byte` VAL_BOUND) THEN
    MP_TAC(ISPEC `b2:byte` VAL_BOUND) THEN
    MP_TAC(ISPEC `b3:byte` VAL_BOUND) THEN
    REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

  (* ========================================================================= *)
  (* eta2 CORRECT: table-gather / VPSHUFB compaction lemmas.                   *)
  (* These operate on the shared mldsa_rej_uniform_table + VPSHUFB gather      *)
  (* semantics, so they are coefficient- and threshold-independent, EXCEPT     *)
  (* the accept predicate is n < 15 (eta2 accepts n<15).                       *)
  (* From SUBITER_STORE on, the store VALUE is eta2-specific (mod-5 reduction, *)
  (* composing the per-lane red_lane chain).                                   *)
  (* NB TABLE_PREFIX_ACC is a 256-mask eval.                                   *)
  (* ========================================================================= *)

  (* SUBITER_STORE (byte form), eta2 centering 2-n and accept <15.             *)
  let SUBITER_STORE = prove
   (`!(g:int128) (m:byte) (n0:byte) n1 n2 n3 n4 n5 n6 n7.
      val n0 < 16 /\ val n1 < 16 /\ val n2 < 16 /\ val n3 < 16 /\
      val n4 < 16 /\ val n5 < 16 /\ val n6 < 16 /\ val n7 < 16 /\
      (!j. j < 8 ==> (bit j m <=> val(EL j [n0;n1;n2;n3;n4;n5;n6;n7]:byte) < 15)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
                     word_sub (word 2) (EL j [n0;n1;n2;n3;n4;n5;n6;n7]))
      ==> SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m) =
          MAP (\x:byte. word_sub (word 2) x)
              (FILTER (\x:byte. val x < 15) [n0;n1;n2;n3;n4;n5;n6;n7])`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`g:int128`; `val(m:byte)`] PSHUFB_ACCEPTED_PREFIX_NUM) THEN
    REWRITE_TAC[WORD_VAL] THEN
    ANTS_TAC THENL
     [MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC;
      DISCH_THEN SUBST1_TAC] THEN
    REWRITE_TAC[ACC_IDX] THEN
    MP_TAC(ISPECL [`\x:byte. word_sub (word 2) x:byte`; `\x:byte. val x < 15`;
                   `n0:byte`;`n1:byte`;`n2:byte`;`n3:byte`;`n4:byte`;`n5:byte`;`n6:byte`;`n7:byte`]
                  GATHER_FILTER_MAP_IDX_8) THEN
    REWRITE_TAC[] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
    SUBGOAL_THEN
     `(!j. MEM j [0;1;2;3;4;5;6;7] ==> (bit j (m:byte) <=> val(EL j [n0;n1;n2;n3;n4;n5;n6;n7]:byte) < 15)) /\
      (!j. MEM j [0;1;2;3;4;5;6;7] ==> word_subword (g:int128) (8*j,8):byte =
                     word_sub (word 2) (EL j [n0;n1;n2;n3;n4;n5;n6;n7]))`
     MP_TAC THENL
     [CONJ_TAC THEN GEN_TAC THEN REWRITE_TAC[MEM] THEN
      STRIP_TAC THEN ASM_REWRITE_TAC[] THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ARITH_TAC;
      ALL_TAC] THEN
    STRIP_TAC THEN
    REWRITE_TAC[FILTER; MAP; MEM] THEN
    REPEAT(FIRST_X_ASSUM(fun th ->
      if is_forall(concl th) then
        (MP_TAC(SPEC `0` th) THEN MP_TAC(SPEC `1` th) THEN MP_TAC(SPEC `2` th) THEN
         MP_TAC(SPEC `3` th) THEN MP_TAC(SPEC `4` th) THEN MP_TAC(SPEC `5` th) THEN
         MP_TAC(SPEC `6` th) THEN MP_TAC(SPEC `7` th))
      else NO_TAC)) THEN
    REWRITE_TAC[MEM] THEN CONV_TAC NUM_REDUCE_CONV THEN
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV EL_CONV)) THEN
    CONV_TAC(DEPTH_CONV EL_CONV) THEN ASM_REWRITE_TAC[] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP]) THEN
    CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(DEPTH_CONV EL_CONV) THEN ASM_REWRITE_TAC[]);;

  (* Byte vs int16 centered value sign-extend to the same int32, for n<15.     *)
  (* eta2 15-way blast.                                                        *)
  let SX_SUB2_BYTE_EQ_INT16 = prove
   (`!n. n < 15
         ==> word_sx(word_sub (word 2:byte) (word n:byte)):int32 =
             word_sx(word_sub (word 2:int16) (word n:int16)):int32`,
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(DISJ_CASES_TAC o MATCH_MP (ARITH_RULE
      `n < 15 ==> n=0\/n=1\/n=2\/n=3\/n=4\/n=5\/n=6\/n=7\/n=8\/
                  n=9\/n=10\/n=11\/n=12\/n=13\/n=14`)) THEN
    POP_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC) THEN
    CONV_TAC WORD_BLAST);;

  (* SUBITER_STORE (int32 form), eta2: the sign-extended centered store value. *)
  (* This is BEFORE the mod-5 reduction — lanes are word_sx(word_sub 2 v).     *)
  let SUBITER_STORE_INT32 = prove
   (`!(g:int128) (m:byte) v0 v1 v2 v3 v4 v5 v6 v7.
      v0<16/\v1<16/\v2<16/\v3<16/\v4<16/\v5<16/\v6<16/\v7<16 /\
      (!j. j < 8 ==> (bit j m <=> EL j [v0;v1;v2;v3;v4;v5;v6;v7] < 15)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
                     word_sub (word 2) (word(EL j [v0;v1;v2;v3;v4;v5;v6;v7]):byte))
      ==> MAP (\b:byte. word_sx b:int32)
              (SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m)) =
          MAP (\v. word_sx(word_sub (word 2:int16) (word v)):int32)
              (FILTER (\v. v < 15) [v0;v1;v2;v3;v4;v5;v6;v7])`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`g:int128`; `m:byte`;
      `word v0:byte`;`word v1:byte`;`word v2:byte`;`word v3:byte`;
      `word v4:byte`;`word v5:byte`;`word v6:byte`;`word v7:byte`] SUBITER_STORE) THEN
    SUBGOAL_THEN `val(word v0:byte)=v0/\val(word v1:byte)=v1/\val(word v2:byte)=v2/\
                  val(word v3:byte)=v3/\val(word v4:byte)=v4/\val(word v5:byte)=v5/\
                  val(word v6:byte)=v6/\val(word v7:byte)=v7`
      STRIP_ASSUME_TAC THENL
     [REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN REPEAT CONJ_TAC THEN
      MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    ANTS_TAC THENL
     [SUBGOAL_THEN
        `!j. j < 8 ==> val(EL j [word v0;word v1;word v2;word v3;
                                 word v4;word v5;word v6;word v7]:byte) =
                       EL j [v0;v1;v2;v3;v4;v5;v6;v7]`
        ASSUME_TAC THENL
       [X_GEN_TAC `j:num` THEN DISCH_TAC THEN
        SUBGOAL_THEN `j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`
          (REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC) THENL
         [ASM_ARITH_TAC; ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC] THEN
        CONV_TAC(DEPTH_CONV EL_CONV) THEN ASM_REWRITE_TAC[];
        ALL_TAC] THEN
      CONJ_TAC THEN X_GEN_TAC `j:num` THEN DISCH_TAC THENL
       [FIRST_X_ASSUM(MP_TAC o SPEC `j:num`) THEN
        ASM_SIMP_TAC[] THEN DISCH_THEN(K ALL_TAC) THEN
        FIRST_X_ASSUM(MP_TAC o SPEC `j:num` o check (fun th ->
          let s=string_of_term(concl th) in
          let h n=let nl=String.length n and hl=String.length s in
            let rec go i=if i+nl>hl then false else if String.sub s i nl=n then true else go(i+1) in go 0 in
          h "bit j")) THEN ASM_REWRITE_TAC[];
        FIRST_X_ASSUM(MP_TAC o SPEC `j:num` o check (fun th ->
          let s=string_of_term(concl th) in
          let h n=let nl=String.length n and hl=String.length s in
            let rec go i=if i+nl>hl then false else if String.sub s i nl=n then true else go(i+1) in go 0 in
          h "word_subword")) THEN ASM_REWRITE_TAC[] THEN
        DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
        SUBGOAL_THEN `j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`
          (REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC) THENL
         [ASM_ARITH_TAC; ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC;ALL_TAC] THEN
        CONV_TAC(DEPTH_CONV EL_CONV) THEN REWRITE_TAC[]];
      DISCH_THEN SUBST1_TAC] THEN
    REWRITE_TAC[GSYM MAP_o; o_DEF] THEN
    REWRITE_TAC[FILTER; MAP] THEN ASM_REWRITE_TAC[] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP]) THEN
    ASM_SIMP_TAC[SX_SUB2_BYTE_EQ_INT16]);;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SUBITER_STORE_SPEC crux.                                *)
  (*                                                                           *)
  (* After the pre-gather centering (2 - nibble), the table gather (vpshufb),  *)
  (* and the sign-extend (vpmovsxbd), the eta2 body runs the int32-lane mod-5  *)
  (* reduction                                                                 *)
  (*   vpmulhrsw ymm6,ymm1,ymm2 ; vpmullw ymm7,ymm2,ymm2 ; vpaddd ymm2,ymm1,ymm1 *)
  (* (asm 0xa7-0xb0) before the vmovdqu store.  The store lane j is            *)
  (*   word_add (word_subword v (32j,32))                                      *)
  (*            (word_subword <mullw(mulhrs(v,0xe660),5)> (32j,32))            *)
  (* with v = the vpmovsxbd output (word_sx of the gathered centered byte).    *)
  (* This is exactly the eta2 per-lane mod-5 reduction chain, captured here as *)
  (* red_lane : int32 -> int32.  We then compose it through the gather         *)
  (* compaction to give the full                                               *)
  (* sub-iter store value = REJ_SAMPLE_ETA2_BYTES [b0;b1;b2;b3].               *)
  (* ========================================================================= *)

  (* The int32-lane reduction, as a function of the vpmovsxbd output lane v.   *)
  (* red_lane v = word_add v (mullw-join-of-mulhrs), matching the stepper form. *)
  let red_lane = new_definition
    `red_lane (v:int32):int32 =
       word_add v
         (word_join
            (word_mul (mulhrs_eta2 (word_subword v (16,16)) (word 0xe660:int16))
                      (word 5:int16))
            (word_mul (mulhrs_eta2 (word_subword v (0,16)) (word 0xe660:int16))
                      (word 5:int16))
          : int32)`;;

  (* Per-lane spec: for an accepted nibble n (< 15), applying red_lane to the  *)
  (* sign-extend of the centered byte (2 - n) recovers the eta=2 coefficient   *)
  (*   2 - (n MOD 5)  as a sign-extended int32 (int16-umod form, matching      *)
  (* REJ_SAMPLE_ETA2_BYTES's element).  This is the per-lane mod-5 reduction   *)
  (* with the RHS restated in the int16-word-umod shape; proven directly by 15-way *)
  (* WORD_REDUCE so it can slot straight into the composition below.           *)
  let RED_LANE_SPEC = prove
   (`!n. n < 15
         ==> red_lane (word_sx (word_sub (word 2:byte) (word n:byte)):int32)
             = word_sx (word_sub (word 2:int16)
                                 (word_umod (word n:int16) (word 5:int16))):int32`,
    REWRITE_TAC[red_lane; mulhrs_eta2] THEN
    CONV_TAC EXPAND_CASES_CONV THEN
    CONV_TAC(DEPTH_CONV NUM_RED_CONV) THEN
    CONV_TAC WORD_REDUCE_CONV);;

  (* Same, on the int16-centered form (word_sub (word 2:int16) (word v)) that  *)
  (* SUBITER_STORE_INT32 actually produces. Bridged from RED_LANE_SPEC         *)
  (* by SX_SUB2_BYTE_EQ_INT16 which equates the byte- and int16-centered       *)
  (* sign-extensions for v < 15.                                               *)
  let RED_LANE_SPEC_I16 = prove
   (`!v. v < 15
         ==> red_lane (word_sx (word_sub (word 2:int16) (word v)):int32)
             = word_sx (word_sub (word 2:int16)
                                 (word_umod (word v:int16) (word 5:int16))):int32`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPEC `v:num` RED_LANE_SPEC) THEN ASM_REWRITE_TAC[] THEN
    MP_TAC(SPEC `v:num` SX_SUB2_BYTE_EQ_INT16) THEN ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]));;

  (* Push a num->int16 word-cast through MAP/FILTER.                           *)
  let FILTER_VAL_WORD_NIB = prove
   (`!L:num list. (!v. MEM v L ==> v < 16)
       ==> FILTER (\v. val(word v:int16) < 15) L = FILTER (\v. v < 15) L`,
    LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; MEM] THEN
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(word h:int16) = h` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_16] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `h:num`) THEN REWRITE_TAC[MEM] THEN ARITH_TAC;
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `FILTER (\v. val(word v:int16) < 15) t = FILTER (\v. v < 15) t`
      SUBST1_TAC THENL
     [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_MESON_TAC[MEM]; ALL_TAC] THEN
    REWRITE_TAC[]);;

  (* ------------------------------------------------------------------------- *)
  (* THE CRUX: SUBITER_STORE_SPEC (eta2 spec form).                            *)
  (*                                                                           *)
  (* The full sub-iter SIMD store value — MAP red_lane over the sign-extended  *)
  (* gather (i.e. the vpmulhrsw/vpmullw/vpaddd int32-lane mod-5 reduction      *)
  (* applied to each vpmovsxbd lane) — equals REJ_SAMPLE_ETA2_BYTES on the     *)
  (* 4-byte block [b0;b1;b2;b3].  The two hypotheses (accept mask m, and the   *)
  (* gather source g holding the centered (2 - nibble) bytes) are discharged in *)
  (* the loop body from the proven nibble-extract, VPSUBB_SIGN_BIT_LT_15 and   *)
  (* VPMOVMSKB lane lemmas.  Composed 4x per iteration and stitched via the    *)
  (* 16-as-4 decomposition.                                                    *)
  let SUBITER_STORE_SPEC = prove
   (`!(g:int128) (m:byte) (b0:byte) b1 b2 b3.
      (!j. j < 8 ==> (bit j m <=>
          EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16] < 15)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
          word_sub (word 2) (word(EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16]):byte))
      ==> MAP red_lane
              (MAP (\b:byte. word_sx b:int32)
                   (SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m))) =
          REJ_SAMPLE_ETA2_BYTES [b0;b1;b2;b3]`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`g:int128`; `m:byte`;
      `val(b0:byte) MOD 16`; `val(b0:byte) DIV 16`; `val(b1:byte) MOD 16`; `val(b1:byte) DIV 16`;
      `val(b2:byte) MOD 16`; `val(b2:byte) DIV 16`; `val(b3:byte) MOD 16`; `val(b3:byte) DIV 16`]
      SUBITER_STORE_INT32) THEN
    ANTS_TAC THENL
     [ASM_REWRITE_TAC[] THEN
      MP_TAC(ISPEC `b0:byte` VAL_BOUND) THEN MP_TAC(ISPEC `b1:byte` VAL_BOUND) THEN
      MP_TAC(ISPEC `b2:byte` VAL_BOUND) THEN MP_TAC(ISPEC `b3:byte` VAL_BOUND) THEN
      REWRITE_TAC[DIMINDEX_8] THEN
      SIMP_TAC[MOD_LT_EQ; ARITH_EQ; RDIV_LT_EQ] THEN REPEAT STRIP_TAC THEN ASM_ARITH_TAC;
      DISCH_THEN SUBST1_TAC] THEN
    REWRITE_TAC[GSYM MAP_o] THEN
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2] THEN
    SUBGOAL_THEN
     `NIBBLES_OF_BYTES [b0;b1;b2;b3] =
      MAP (word:num->int16)
          [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
           val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16]`
     SUBST1_TAC THENL
     [REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; MAP]; ALL_TAC] THEN
    MP_TAC(ISPECL [`\x:int16. word_sx(word_sub (word 2) (word_umod x (word 5))):int32`;
      `\x:int16. val x < 15`;
      `[val(b0:byte) MOD 16; val b0 DIV 16; val(b1:byte) MOD 16; val b1 DIV 16;
        val(b2:byte) MOD 16; val b2 DIV 16; val(b3:byte) MOD 16; val b3 DIV 16]`]
      MAP_FILTER_WORD_NIB) THEN
    SUBGOAL_THEN
     `!v. MEM v [val(b0:byte) MOD 16; val b0 DIV 16; val(b1:byte) MOD 16; val b1 DIV 16;
                 val(b2:byte) MOD 16; val b2 DIV 16; val(b3:byte) MOD 16; val b3 DIV 16]
          ==> v < 16`
     ASSUME_TAC THENL
     [REWRITE_TAC[MEM] THEN REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
      MP_TAC(ISPEC `b0:byte` VAL_BOUND) THEN MP_TAC(ISPEC `b1:byte` VAL_BOUND) THEN
      MP_TAC(ISPEC `b2:byte` VAL_BOUND) THEN MP_TAC(ISPEC `b3:byte` VAL_BOUND) THEN
      REWRITE_TAC[DIMINDEX_8] THEN
      SIMP_TAC[MOD_LT_EQ; ARITH_EQ; RDIV_LT_EQ] THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    REWRITE_TAC[o_DEF] THEN
    ASM_SIMP_TAC[FILTER_VAL_WORD_NIB] THEN
    MATCH_MP_TAC MAP_EQ THEN REWRITE_TAC[GSYM ALL_MEM] THEN
    X_GEN_TAC `v:num` THEN REWRITE_TAC[MEM_FILTER] THEN STRIP_TAC THEN
    MP_TAC(SPEC `v:num` RED_LANE_SPEC_I16) THEN ASM_REWRITE_TAC[]);;

  (* ========================================================================= *)
  (* eta2 CORRECT: EXEC rule + LENGTH lemma.                                   *)
  (*                                                                           *)
  (* The core exec rule that drives every X86_STEPS_TAC in the body/scalar-tail *)
  (* proof, plus the trimmed-mc LENGTH.                                        *)
  (* ========================================================================= *)

  let MLDSA_REJ_UNIFORM_ETA2_EXEC =
    X86_MK_CORE_EXEC_RULE mldsa_rej_uniform_eta2_tmc;;

  let LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC =
    REWRITE_CONV[mldsa_rej_uniform_eta2_tmc] `LENGTH mldsa_rej_uniform_eta2_tmc`
    |> CONV_RULE (RAND_CONV LENGTH_CONV);;

  (* The two int16-broadcast constants, as word_duplicate <-> numeral bridges. *)
  (* Kept as named lemmas so the prologue tactic (and later the loop-invariant *)
  (* discharge) can rewrite YMM6/YMM7 to a canonical numeral form.             *)
  let YMM6_CONST_ETA2 = prove
   (`word_duplicate (word 58976:int16):int256 =
     word 104203162506446325494781756494581186443189907921581107878096444258040508638816`,
    CONV_TAC WORD_REDUCE_CONV);;

  let YMM7_CONST_ETA2 = prove
   (`word_duplicate (word 5:int16):int256 =
     word 8834370125682169483754557489027840684616615904908870377619408255734579205`,
    CONV_TAC WORD_REDUCE_CONV);;

  (* The vpbroadcastw-collapse: the raw stepper form for YMM6/YMM7 after the   *)
  (* vpinsrw ; vpbroadcastw pair collapses (by WORD_BLAST) to the constant,    *)
  (* INDEPENDENT of the ghost prior register value.  The intermediate word_zx  *)
  (* widths are simulator-determined (do NOT hand-type them — that invents type *)
  (* variables that WORD_REDUCE cannot close), so we apply the collapse as an  *)
  (* IN-CONTEXT step on whatever `read <ymm> sN = <form>` assumption the stepper *)
  (* actually produced.                                                        *)
  (*                                                                           *)
  (* COLLAPSE_VPBW_TAC ymmread bridge: given the ghost-carrying assumption     *)
  (*   read <ymm> sN = rhs   (rhs contains word_insert of the ghost register), *)
  (* and a bridge  |- word_duplicate (word imm:int16):int256 = word <const>,   *)
  (* prove  rhs = word_duplicate(word imm)  by WORD_BLAST on the CONCRETE rhs  *)
  (* (fully typed, ghost atomic -> no type invention), TRANS with the bridge to *)
  (* get  rhs = word <const>, and rewrite the assumption to  read <ymm> sN =   *)
  (* word <const>.  The constant fact then propagates through the remaining    *)
  (* plain steps like YMM3/4/5 do.                                             *)
  let COLLAPSE_VPBW_TAC (ymmread:term) (bridge:thm) : tactic =
    W(fun (asl,w) ->
      let tgt = find (fun t -> is_eq t && lhand t = ymmread)
                     (map (fun (_,th) -> concl th) asl) in
      let rhs = rand tgt in
      let dup = lhand(concl bridge) in
      let blast_eq = WORD_BLAST (mk_eq(rhs, dup)) in    (* |- rhs = word_duplicate(word imm) *)
      let full = TRANS blast_eq bridge in                (* |- rhs = word <const> *)
      RULE_ASSUM_TAC(REWRITE_RULE[full]));;

  (* ========================================================================= *)
  (* eta2 CORRECT: the CLEAN_BODY goal statement.                              *)
  (*                                                                           *)
  (* The per-iteration SIMD body obligation: from the loop top (pc+86) at      *)
  (* position 16*i with outlen accepted coeffs stored, run one 16-byte block   *)
  (* (4 sub-iters) back to the loop top at position 16*(i+1).                  *)
  (*                                                                           *)
  (* Key eta2 facts:                                                           *)
  (*   - pc-length 546, buf 136, loop top pc+86.                               *)
  (*   - FIVE YMM consts: YMM6 (0xe660 x16) + YMM7 (5 x16) are the mod-5       *)
  (*     reduction constants the in-body vpmulhrsw/vpmullw consume.            *)
  (*   - MAYCHANGE ZMM set = body-touched regs [ZMM0;ZMM1;ZMM2;ZMM8;ZMM9]:     *)
  (*     ymm0 vpmovzxbw, ymm1 shift/shuffle/sxbd/paddd, ymm2 mulhrsw/mullw     *)
  (*     reduction temp, ymm8 gather-source (vextracti128/vpsrldq), ymm9 table *)
  (*     lane (vmovq/vpshufb).                                                 *)
  (*   - niblen bound 248: head-guard cmp eax,0xf8 (=248).                     *)
  (*                                                                           *)
  (* Body offset map (trimmed mc, read off MLDSA_REJ_UNIFORM_ETA2_EXEC):       *)
  (*   loop top pc+86 cmp eax,0xf8 ; pc+91 ja scalar ; pc+97 cmp ecx,0x78 ;    *)
  (*   pc+100 ja scalar ; SIMD sub-iter-1 pc+106 vpmovzxbw .. pc+176 vmovdqu   *)
  (*   store (incl mod-5 vpmulhrsw@163/vpmullw@168/vpaddd@172), pc+181 popcnt .. *)
  (*   pc+196 cmp eax,0xf8 ; pc+201 ja (mid-guard) ; sub-iters 2/3/4 similar.  *)
  (* ========================================================================= *)

  let clean_body_eta2_tm = `
     !res buf table (inlist:byte list) pc N (i:num) stackpointer.
          LENGTH inlist = 136 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          ~(N = 0) /\ i + 1 < N /\ 16 * (i + 1) <= 136 /\
          LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16 * (i+1)) inlist)) <= 248
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 86) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
                    read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
                    read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
                    read RCX s = word(16*i) /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s = num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist)))
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 86) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
                    read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
                    read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list)) /\
                    read RCX s = word(16*(i+1)) /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list))) s = num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*(i+1)) inlist)))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM8; ZMM9] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,,
                MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: the nibble-extraction / gather / mask lemma family.         *)
  (*                                                                           *)
  (* These are the byte-structure lemmas the CLEAN_BODY prefix (PREFIX_G) and  *)
  (* the sub-iter store folds depend on.  They describe, purely at the word    *)
  (* level (no ISA stepping), the SIMD nibble-extraction chain and the two     *)
  (* vpsubb constants of the eta2 body:                                        *)
  (*                                                                           *)
  (*   nibchain(q) = vpand (vpor (vpmovzxbw q) (vpsllw $4 ...)) 0x0f0f0f0f     *)
  (*     -> byte 2j = val(q byte j) MOD 16, byte 2j+1 = val(q byte j) DIV 16   *)
  (*        (F0NIB_BYTES_ETA2 / _HI).                                          *)
  (*   center vpsubb ymm4,ymm0,ymm0  (ymm4 = 0x02020202 broadcast)             *)
  (*     -> byte j = word_sub (word 2) (nibchain byte j).                      *)
  (*        eta2 centres with 0x02.                                            *)
  (*   accept vpsubb ymm5,ymm0,ymm1  (ymm5 = 0x0f0f0f0f broadcast)             *)
  (*     -> byte j = word_sub (nibchain byte j) (word 15).                     *)
  (*        eta2 subtracts 0x0f (accept nibble < 15).                          *)
  (*                                                                           *)
  (* Composed:                                                                 *)
  (*   the centred gather source byte j = word_sub (word 2) (word nibble_j)    *)
  (*       — SUBITER_STORE_SPEC's gather hyp.                                  *)
  (*   the accept byte: bit 7 <=> nibble_j < 15 — the vpmovmskb input, giving  *)
  (*       SUBITER_STORE_SPEC's mask hyp.                                      *)
  (*   MASK_LOW_BIT : the vpmovmskb bit-packing bridge                         *)
  (*       (bit j of the packed mask byte <=> nibble_j < 15).                  *)
  (*                                                                           *)
  (* All statements are built programmatically from lane-base generators, so   *)
  (* the 16-conjunct forms cannot drift from a hand-transcription error, and   *)
  (* LO (bytes 0..15) / HI (bytes 16..31 = input bytes 8..15) share one        *)
  (* generator.                                                                *)
  (*                                                                           *)
  (* Uses: VPSUBB_SIGN_BIT_LT_15 (accept-bit lemma) + the usimd/simd           *)
  (* definitions.                                                              *)
  (* ========================================================================= *)

  (* eta2 broadcast constants:
       0x0f0f0f0f broadcast (nibble mask ymm3, accept ymm5):
         6811299366900952671974763824040465167839410862684739061144563765171360567055
       0x02020202 broadcast (centre const ymm4):
         908173248920127022929968509872062022378588115024631874819275168689514742274 *)

  (* ETA2_NIBCHAIN: the eta2 nibble-extraction chain                           *)
  (* vpand(vpor(vpmovzxbw q)(vpsllw $4 ...)) 0x0f0f0f0f.                       *)
  let ETA2_NIBCHAIN =
   `word_and (word_or (usimd16 (\b:byte. word_zx b:int16) (q:int128):int256)
              (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) (q:int128):int256):int256))
        (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)`;;

  let wsw256 = `word_subword:int256->num#num->byte`;;
  let wsw128 = `word_subword:int128->num#num->byte`;;

  (* ------------------------------------------------------------------------- *)
  (* F0NIB: the vpand-nibble bytes (0x0f mask).                                *)
  let gen_f0nib obase qoffbase =
    let mk bi =
      let off = obase + 8*bi and qoff = qoffbase + 8*(bi/2) and hi = (bi mod 2 = 1) in
      let lhs = mk_comb(mk_comb(wsw256, ETA2_NIBCHAIN), mk_pair(mk_small_numeral off, `8`)) in
      let v = mk_comb(`val:byte->num`,
                mk_comb(mk_comb(wsw128,`q:int128`), mk_pair(mk_small_numeral qoff, `8`))) in
      let nib = if hi then mk_binop `DIV` v `16` else mk_binop `MOD` v `16` in
      mk_eq(lhs, mk_comb(`word:num->byte`, nib)) in
    mk_forall(`q:int128`, end_itlist (curry mk_conj) (map mk (0--15)));;

  let f0nib_tac =
    GEN_TAC THEN
    REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
    CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_BLAST;;

  let F0NIB_BYTES_ETA2    = prove(gen_f0nib 0 0,   f0nib_tac);;
  let F0NIB_BYTES_HI_ETA2 = prove(gen_f0nib 128 64, f0nib_tac);;

  (* ------------------------------------------------------------------------- *)
  (* SIGN_NIB (accept-bit at nibble granularity): for n<16, bit 7 of           *)
  (* word_sub (word n) (word 15) <=> n < 15.  eta4 used (word 9)/(n<9).        *)
  let SIGN_NIB_ETA2 = prove
   (`!n. n < 16 ==> (bit 7 (word_sub (word n:byte) (word 15)) <=> n < 15)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(word n:byte) = n` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_8] THEN ASM_ARITH_TAC; ALL_TAC] THEN
    MP_TAC(ISPEC `word n:byte` VPSUBB_SIGN_BIT_LT_15) THEN ASM_REWRITE_TAC[]);;

  (* ========================================================================= *)
  (* eta2 CORRECT: PREFIX_G opening-dependency scalar lemmas.                  *)
  (*                                                                           *)
  (* The small word-level / loop-guard helper lemmas that eta2's PREFIX_G tactic *)
  (* (the CLEAN_BODY prefix stepping) needs before it can step the body.  They *)
  (* are constant-independent (they concern the 32-bit register / loop-guard   *)
  (* arithmetic, not the eta constant): VAL_WORD_ZX_64_32, JA_NOT_TAKEN_LE, and *)
  (* the buffer-chunk lemma SUB_LIST_16_BYTES_FROM_INT128 (parametric in the   *)
  (* buffer length).                                                           *)
  (*                                                                           *)
  (* Head-guard facts these support:                                           *)
  (*   loop top pc+86; steps 1--2 (cmp eax,0xf8=248 + ja) -> RIP pc+97;        *)
  (*   steps 3--4 (cmp ecx,0x78=120 + ja) -> RIP pc+106 (= 0x6e, SIMD start);  *)
  (*   scalar target (ja taken) = pc+399 (0x18f).  eta2's ecx guard is 120 (buf *)
  (*   136), so the second JA_NOT_TAKEN_LE is instantiated at 120.             *)
  (* ========================================================================= *)

  (* word_zx of a 64-bit register holding a value < 2^32, read back at 32 bits, *)
  (* recovers the value (constant-independent).                                *)
  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  let mk_eta2_prefix_open (memsafe:bool) : tactic =
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `16 * i <= 120` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC; ALL_TAC] THEN
    ENSURES_INIT_TAC "s0" THEN
    (if memsafe then STRIP_EXISTS_ASSUM_TAC else ALL_TAC) THEN
    MP_TAC(SPECL [`buf:int64`;`136`;`inlist:byte list`;`i:num`;`s0:x86state`] SUB_LIST_16_BYTES_FROM_INT128) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC; ALL_TAC] THEN
    ABBREV_TAC `chunk0 = read(memory:>bytes128(word_add buf (word(16*i)))) s0` THEN DISCH_TAC THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) <= 248` ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
      TRANS_TAC LE_TRANS `LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16 * (i+1)) inlist):int16 list)` THEN
      ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NIBLEN_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
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
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 399`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
    X86_STEPS_TAC EXEC (3--4) THEN
    SUBGOAL_THEN `read RIP s4 = word(pc + 106):int64` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&120:int`))(concl th)
                             then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 399`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC];;

  (* Accept-count = filter-length lemmas: the 8-bit bitval sum (resp. ACC_IDX  *)
  (* length) equals LENGTH(FILTER (val<15) [bytes]).                           *)
  let BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2 = prove
   (`!a0 a1 a2 a3 a4 a5 a6 a7:byte.
       bitval(val a0 < 15) + bitval(val a1 < 15) + bitval(val a2 < 15) + bitval(val a3 < 15) +
       bitval(val a4 < 15) + bitval(val a5 < 15) + bitval(val a6 < 15) + bitval(val a7 < 15) =
       LENGTH(FILTER (\x:byte. val x < 15) [a0;a1;a2;a3;a4;a5;a6;a7])`,
    REPEAT GEN_TAC THEN REWRITE_TAC[FILTER; LENGTH] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH; BITVAL_CLAUSES]) THEN ARITH_TAC);;

  let ACC_LENGTH_EQ_FILTER_ETA2 = prove
   (`!(m:byte) (n0:byte) (n1:byte) (n2:byte) (n3:byte) (n4:byte) (n5:byte) (n6:byte) (n7:byte).
       (bit 0 m <=> val n0 < 15) /\ (bit 1 m <=> val n1 < 15) /\ (bit 2 m <=> val n2 < 15) /\
       (bit 3 m <=> val n3 < 15) /\ (bit 4 m <=> val n4 < 15) /\ (bit 5 m <=> val n5 < 15) /\
       (bit 6 m <=> val n6 < 15) /\ (bit 7 m <=> val n7 < 15)
       ==> LENGTH(ACC_IDX m) = LENGTH(FILTER (\x:byte. val x < 15) [n0;n1;n2;n3;n4;n5;n6;n7])`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_ACC_IDX_BITSUM] THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2]);;

  (* LEN_RECONCILE: accept count = LENGTH(REJ_SAMPLE block) (accept < 15).     *)
  let LEN_RECONCILE = prove
   (`!(m:byte) (chunk0:int128).
       (!j. j < 8 ==> (bit j m <=>
          EL j [val(word_subword chunk0 (0,8):byte) MOD 16; val(word_subword chunk0 (0,8):byte) DIV 16;
                val(word_subword chunk0 (8,8):byte) MOD 16; val(word_subword chunk0 (8,8):byte) DIV 16;
                val(word_subword chunk0 (16,8):byte) MOD 16; val(word_subword chunk0 (16,8):byte) DIV 16;
                val(word_subword chunk0 (24,8):byte) MOD 16; val(word_subword chunk0 (24,8):byte) DIV 16] < 15))
       ==> LENGTH(ACC_IDX m) =
           LENGTH(REJ_SAMPLE_ETA2_BYTES [word_subword chunk0 (0,8); word_subword chunk0 (8,8);
                                         word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int32 list)`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`m:byte`;
      `word(val(word_subword (chunk0:int128) (0,8):byte) MOD 16):byte`;
      `word(val(word_subword (chunk0:int128) (0,8):byte) DIV 16):byte`;
      `word(val(word_subword (chunk0:int128) (8,8):byte) MOD 16):byte`;
      `word(val(word_subword (chunk0:int128) (8,8):byte) DIV 16):byte`;
      `word(val(word_subword (chunk0:int128) (16,8):byte) MOD 16):byte`;
      `word(val(word_subword (chunk0:int128) (16,8):byte) DIV 16):byte`;
      `word(val(word_subword (chunk0:int128) (24,8):byte) MOD 16):byte`;
      `word(val(word_subword (chunk0:int128) (24,8):byte) DIV 16):byte`] ACC_LENGTH_EQ_FILTER_ETA2) THEN
    ANTS_TAC THENL
     [REPEAT CONJ_TAC THEN
      W(fun (asl,gw) -> let n = rand(rator(lhand gw)) in
         MP_TAC(SPEC n (find (fun th -> is_forall(concl th) && can(find_term(fun u->match u with Const("EL",_)->true|_->false))(concl th)) (map snd asl)))) THEN
      CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
      DISCH_THEN SUBST1_TAC THEN
      W(fun (asl,gw) -> let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" && type_of u=`:byte` with _->false) gw in
         MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN STRIP_TAC THEN
         SUBGOAL_THEN (mk_eq(mk_comb(`val:byte->num`,mk_comb(`word:num->byte`,mk_binop `MOD` (mk_comb(`val:byte->num`,bt)) `16`)), mk_binop `MOD` (mk_comb(`val:byte->num`,bt)) `16`)) SUBST1_TAC THENL
          [REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN (mk_eq(mk_comb(`val:byte->num`,mk_comb(`word:num->byte`,mk_binop `DIV` (mk_comb(`val:byte->num`,bt)) `16`)), mk_binop `DIV` (mk_comb(`val:byte->num`,bt)) `16`)) SUBST1_TAC THENL
          [REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
         REFL_TAC);
      DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[LENGTH_FILTER_BYTE_NIBBLES_4_BYTES; LENGTH_REJ_SAMPLE_ETA2_BYTES]]);;

  (* SUBITER_FOLD_STEP: fold one sub-iter's REJ block onto the running prefix. *)
  let SUBITER_FOLD_STEP = prove
   (`!res s (m:byte) (blk:byte list) (prefixbytes:byte list).
       LENGTH(ACC_IDX m) = LENGTH(REJ_SAMPLE_ETA2_BYTES blk:int32 list) /\
       read(memory:>bytes(res, 4*LENGTH(REJ_SAMPLE_ETA2_BYTES prefixbytes:int32 list))) s =
         num_of_wordlist(REJ_SAMPLE_ETA2_BYTES prefixbytes) /\
       read(memory:>bytes(word_add res (word(4*LENGTH(REJ_SAMPLE_ETA2_BYTES prefixbytes:int32 list))),
                          4*LENGTH(ACC_IDX m))) s =
         num_of_wordlist(REJ_SAMPLE_ETA2_BYTES blk)
       ==> read(memory:>bytes(res, 4*LENGTH(REJ_SAMPLE_ETA2_BYTES(APPEND prefixbytes blk):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(APPEND prefixbytes blk))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    MP_TAC(ISPECL [`res:int64`; `s:x86state`;
                   `REJ_SAMPLE_ETA2_BYTES prefixbytes:int32 list`;
                   `REJ_SAMPLE_ETA2_BYTES blk:int32 list`] SUBITER_STORE_EXTEND) THEN
    ANTS_TAC THENL
     [ASM_REWRITE_TAC[] THEN
      FIRST_X_ASSUM(fun th -> if can(find_term(fun u->u=`ACC_IDX (m:byte)`)) (concl th)
                              then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[];
      REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_APPEND; LENGTH_APPEND;
                  ARITH_RULE `4*a+4*b = 4*(a+b)`]]);;

  (* ------------------------------------------------------------------------- *)
  (* Cumulative outlen bounds through sub-iters 1-4.  Buffer length stays      *)
  (* symbolic (LENGTH inlist).                                                 *)
  let SUBITER_OUTLEN_BOUND_1 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i, 4) inlist):int16 list) <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA2_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 12 = 16`]
                       (ISPECL [`inlist:byte list`; `4`; `12`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th ->
      RULE_ASSUM_TAC(REWRITE_RULE[th; REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND])) THEN
    ASM_ARITH_TAC);;

  let SUBITER_OUTLEN_BOUND_2 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 4, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA2_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 8 = 16`]
                       (ISPECL [`inlist:byte list`; `8`; `8`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th2; REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND;
                                  th1]))) THEN
    ASM_ARITH_TAC);;

  let SUBITER_OUTLEN_BOUND_3 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 4, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 8, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA2_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `12 + 4 = 16`]
                       (ISPECL [`inlist:byte list`; `12`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 4 = 12`]
                       (ISPECL [`inlist:byte list`; `8`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 -> DISCH_THEN(fun th3 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th3; th2; th1; REJ_NIBBLES_ETA2_APPEND;
                                  LENGTH_APPEND])))) THEN
    ASM_ARITH_TAC);;

  let SUBITER_OUTLEN_BOUND_4 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 4, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 8, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i + 12, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA2_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `12 + 4 = 16`]
                       (ISPECL [`inlist:byte list`; `12`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 4 = 12`]
                       (ISPECL [`inlist:byte list`; `8`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 -> DISCH_THEN(fun th3 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th3; th2; th1; REJ_NIBBLES_ETA2_APPEND;
                                  LENGTH_APPEND])))) THEN
    ASM_ARITH_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* maskbit_tgt: the mask8-byte <-> chunk0-nibble<15 EL-list correspondence   *)
  (* that LEN_RECONCILE consumes.                                              *)
  let maskbit_tgt =
    `!j. j < 8 ==> (bit j (word (val (mask8:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (0,8):byte) MOD 16;
           val(word_subword chunk0 (0,8):byte) DIV 16; val(word_subword chunk0 (8,8):byte) MOD 16;
           val(word_subword chunk0 (8,8):byte) DIV 16; val(word_subword chunk0 (16,8):byte) MOD 16;
           val(word_subword chunk0 (16,8):byte) DIV 16; val(word_subword chunk0 (24,8):byte) MOD 16;
           val(word_subword chunk0 (24,8):byte) DIV 16] < 15)`;;

  let maskbit_tgt_2 =
    `!j. j < 8 ==> (bit j (word (val (mask8b:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (32,8):byte) MOD 16;
           val(word_subword chunk0 (32,8):byte) DIV 16; val(word_subword chunk0 (40,8):byte) MOD 16;
           val(word_subword chunk0 (40,8):byte) DIV 16; val(word_subword chunk0 (48,8):byte) MOD 16;
           val(word_subword chunk0 (48,8):byte) DIV 16; val(word_subword chunk0 (56,8):byte) MOD 16;
           val(word_subword chunk0 (56,8):byte) DIV 16] < 15)`;;

  let maskbit_tgt_3 =
    `!j. j < 8 ==> (bit j (word (val (mask8c:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (64,8):byte) MOD 16;
           val(word_subword chunk0 (64,8):byte) DIV 16; val(word_subword chunk0 (72,8):byte) MOD 16;
           val(word_subword chunk0 (72,8):byte) DIV 16; val(word_subword chunk0 (80,8):byte) MOD 16;
           val(word_subword chunk0 (80,8):byte) DIV 16; val(word_subword chunk0 (88,8):byte) MOD 16;
           val(word_subword chunk0 (88,8):byte) DIV 16] < 15)`;;

  let maskbit_tgt_4 =
    `!j. j < 8 ==> (bit j (word (val (mask8d:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (96,8):byte) MOD 16;
           val(word_subword chunk0 (96,8):byte) DIV 16; val(word_subword chunk0 (104,8):byte) MOD 16;
           val(word_subword chunk0 (104,8):byte) DIV 16; val(word_subword chunk0 (112,8):byte) MOD 16;
           val(word_subword chunk0 (112,8):byte) DIV 16; val(word_subword chunk0 (120,8):byte) MOD 16;
           val(word_subword chunk0 (120,8):byte) DIV 16] < 15)`;;

  (* DIVMOD256_SPLIT: for the sub-iters 2-4 maskbit derivation.                *)
  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* Opening + the nibble chain s5-s8. Leaves `read YMM0 s8 =                  *)
  (* F0NIB_CHUNK0` ASSUMEd, chunk0/outlen0 abbreviated, both head guards done, *)
  (* s4/s5/s6/s7 word_join equalities purged.  Ready for the s9 accept-vpsubb. *)
  let mk_eta2_prefix_to_s8 (memsafe:bool) : tactic =
    mk_eta2_prefix_open memsafe THEN
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
    DROP_WORDJOIN_TAC THEN PURGE_STALE_STATES_TAC ["s5";"s6";"s7"];;

  (* ========================================================================= *)
  (* eta2 CORRECT: PREFIX_G extension through s9 (accept-vpsubb) +             *)
  (* the four vpmovmskb maskbit foralls.                                       *)
  (*                                                                           *)
  (* ETA2_PREFIX_TO_S9_TAC extends ETA2_PREFIX_TO_S8_TAC with the accept-vpsubb *)
  (* step and the four "maskbit" foralls that the popcount stage (post-        *)
  (* vpmovmskb) will consume.  eta2 does the ACCEPT vpsubb (ymm5) at s9 and    *)
  (* centres LATER (s11).                                                      *)
  (*                                                                           *)
  (*   s9  vpsubb ymm5,ymm0,ymm1  (ymm5 = 0x0f0f0f0f broadcast)                *)
  (*       -> read YMM1 s9 = word_join tree of                                 *)
  (*            word_sub (word_subword <F0NIB explicit> (8j,8)) (word 15), j<32 *)
  (*          = the ACCEPT form f1bnd (nibble - 15; bit 7 <=> nibble < 15).    *)
  (*       RIP s9 = pc+129.                                                    *)
  (*                                                                           *)
  (* Because ETA2_PREFIX_TO_S8_TAC leaves YMM0 s8 as the EXPLICIT F0NIB_CHUNK0, *)
  (* the accept tree carries the explicit nibble chain, so each maskbit lane   *)
  (* reduces via F0NIB_BYTES_ETA2 / _HI + SIGN_NIB_ETA2 (accept threshold 15)  *)
  (* directly.                                                                 *)
  (*                                                                           *)
  (* The four foralls (lane groups 0/8/16/24 of the 32-byte f1bnd) match the   *)
  (* maskbit_tgt targets at chunk0 nibble bases 0/32/64/96.  They are ASSUMEd  *)
  (* BEFORE the vpmovmskb (s10) so the popcount at s21 is over the OPAQUE f1bnd. *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* Build the maskbit forall term for f1bnd lane group g (g in {0,8,16,24}),  *)
  (* over chunk0 nibble base b = 4*g. Shape matches 's maskbit_tgt list.       *)
  let eta2_mk_maskbit_forall g =
    let b = 4*g in
    let nib off hi =
      let v = subst [mk_small_numeral off, `OFF:num`] `val(word_subword (chunk0:int128) (OFF,8):byte)` in
      if hi then mk_binop `DIV` v `16` else mk_binop `MOD` v `16` in
    let ellist = end_itlist (fun a b -> mk_binop `CONS:num->(num)list->(num)list` a b)
       ([nib b false; nib b true; nib (b+8) false; nib (b+8) true;
         nib (b+16) false; nib (b+16) true; nib (b+24) false; nib (b+24) true] @ [`[]:num list`]) in
    (* build the LHS via subst into a fully-typed template (avoids mk_comb on the *)
    (* polymorphic `bit 7`, whose word type won't unify against :byte).        *)
    let bitapp = subst [mk_small_numeral g, `G:num`]
                   `bit 7 (word_subword (f1bnd:int256) (8*(k+G),8):byte)` in
    mk_forall(`k:num`,
      mk_imp(`k < 8`,
        mk_eq(bitapp,
              mk_binop `(<):num->num->bool` (mk_comb(mk_comb(`EL:num->(num)list->num`,`k:num`), ellist)) `15`)));;

  (* Prove & ASSUME the maskbit forall for lane group g, given the f1bnd def   *)
  (* (`f1bnd = <accept tree>`) is in context.  Constant-independent mechanism. *)
  let ETA2_MASKBIT_ASSUME_TAC (g:int) : tactic =
    W(fun (asl,w) ->
      let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
      let tgt = eta2_mk_maskbit_forall g in
      let mb_imp = prove(mk_imp(concl f1d, tgt),
        DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
          FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
            (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
          CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
          REWRITE_TAC[f1eq] THEN
          REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                   DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            CONV_TAC NUM_REDUCE_CONV)) THEN
          REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
          REWRITE_TAC[SPEC `chunk0:int128` F0NIB_BYTES_ETA2;
                      SPEC `chunk0:int128` F0NIB_BYTES_HI_ETA2] THEN
          W(fun (a2,w2) ->
             let nibarg = find_term (fun u -> match u with
                Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
             let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
               type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
             let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
             ACCEPT_TAC (MP (SPEC nibarg SIGN_NIB_ETA2) nlt16)))) in
      ASSUME_TAC (MP mb_imp f1d));;

  (* Full opening through s9 + the four maskbit foralls, f1bnd abbreviated.    *)
  let mk_eta2_prefix_to_s9 (memsafe:bool) : tactic =
    mk_eta2_prefix_to_s8 memsafe THEN
    X86_VSTEPS_TAC EXEC (9--9) THEN
    ABBREV_TAC `f1bnd:int256 = read YMM1 s9` THEN
    ETA2_MASKBIT_ASSUME_TAC 0 THEN
    ETA2_MASKBIT_ASSUME_TAC 8 THEN
    ETA2_MASKBIT_ASSUME_TAC 16 THEN
    ETA2_MASKBIT_ASSUME_TAC 24;;

  (* ========================================================================= *)
  (* eta2 CORRECT: PREFIX_G through s10 (vpmovmskb) + s11 (centre              *)
  (* vpsubb) + the four gather foralls.                                        *)
  (*                                                                           *)
  (* ETA2_PREFIX_TO_S11_TAC extends the s9-accept + 4-maskbit-foralls state    *)
  (* through the eta2 ORDER: vpmovmskb FIRST (s10), then the centre vpsubb     *)
  (* (s11):                                                                    *)
  (*   eta2: s9 accept, s10 MSKB (R8, over opaque f1bnd), s11 CENTRE (f0sub).  *)
  (*                                                                           *)
  (* Control flow:                                                             *)
  (*   read RIP s10 = pc+133 ; read RIP s11 = pc+137 ; read YMM4 s10 = 0x02020202 *)
  (*   read R8 s10  = word_zx(word(SUM32 over bit 7 of word_subword f1bnd (8k,8))) *)
  (*                  — the packed 32-bit popcount MASK over the OPAQUE f1bnd  *)
  (*                    (requires the f1bnd def DROPPED before s10).           *)
  (*   read YMM0 s11 = word_join tree of                                       *)
  (*                     word_sub (word 2) (word_subword <explicit F0NIB> (8j,8)) *)
  (*                  = the CENTRE form f0sub (2 - nibble).                    *)
  (*                                                                           *)
  (* The DROP of the f1bnd word_join def before s10 keeps R8/popcount over the *)
  (* opaque `f1bnd` var (via the read YMM1 s9 = f1bnd fold that ABBREV_TAC left). *)
  (* f0sub is then abbreviated at s11 and the four gather foralls (lane groups *)
  (* over the low/high 128 halves, +/- the >>64 shift) are ASSUMEd in the      *)
  (* SUBITER_STORE_SPEC gather-hypothesis shape (centre value word 2), so SI1..SI4 *)
  (* fold by MATCH_ACCEPT.  Because YMM0 s8 is kept explicit, each lane reduces *)
  (* via F0NIB_BYTES_ETA2/_HI directly.                                        *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* Prove+ASSUME the gather forall for one lane block, given f0sub def, the   *)
  (* extraction term `gsub` (word_subword f0sub (..,128) possibly ushr'd) and the *)
  (* 8-nibble EL list `ellist`.  `shifted` toggles the SUBWORD_USHR rewrite.   *)
  let eta2_gather_block (gsub:term) (ellist:term) (shifted:bool) : tactic =
    W(fun (asl,w) ->
      let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
      let jbody =
        mk_eq(mk_comb(mk_comb(`word_subword:int128->num#num->byte`, gsub), `(8*j,8)`),
              mk_comb(mk_comb(`word_sub:byte->byte->byte`,`word 2:byte`),
                      mk_comb(`word:num->byte`, mk_comb(mk_comb(`EL:num->(num)list->num`,`j:num`), ellist)))) in
      let tgt = mk_forall(`j:num`, mk_imp(`j < 8`, jbody)) in
      let core_tac f0eq =
        REPEAT STRIP_TAC THEN
        FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
          (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
        CONV_TAC NUM_REDUCE_CONV THEN
        (if shifted then REWRITE_TAC[WORD_ZX_TRIVIAL] THEN REWRITE_TAC[SUBWORD_USHR] THEN CONV_TAC NUM_REDUCE_CONV
         else REWRITE_TAC[WORD_ZX_TRIVIAL]) THEN
        SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
        REWRITE_TAC[f0eq] THEN
        REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                 DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
          CONV_TAC NUM_REDUCE_CONV)) THEN
        REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
        REWRITE_TAC[SPEC `chunk0:int128` F0NIB_BYTES_ETA2;
                    SPEC `chunk0:int128` F0NIB_BYTES_HI_ETA2] THEN
        CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC in
      let gather_imp = prove(mk_imp(concl f0d, tgt), DISCH_THEN core_tac) in
      ASSUME_TAC (MP gather_imp f0d));;

  (* The four nibble EL lists (chunk0 byte bases 0/32/64/96).                  *)
  let eta2_ellist nbase =
    let nib off hi =
      let v = subst [mk_small_numeral off, `OFF:num`] `val(word_subword (chunk0:int128) (OFF,8):byte)` in
      if hi then mk_binop `DIV` v `16` else mk_binop `MOD` v `16` in
    end_itlist (fun a b -> mk_binop `CONS:num->(num)list->(num)list` a b)
      ([nib nbase false; nib nbase true; nib (nbase+8) false; nib (nbase+8) true;
        nib (nbase+16) false; nib (nbase+16) true; nib (nbase+24) false; nib (nbase+24) true]
       @ [`[]:num list`]);;

  (* The four gather sources off f0sub.                                        *)
  let g1_eta2 = `word_subword (f0sub:int256) (0,128):int128`;;
  let g2_eta2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128`;;
  let g3_eta2 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128`;;
  let g4_eta2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128`;;

  let mk_eta2_prefix_to_s11 (memsafe:bool) : tactic =
    mk_eta2_prefix_to_s9 memsafe THEN
    (* DROP the f1bnd word_join def so the vpmovmskb reads the opaque f1bnd.   *)
    REPEAT(FIRST_X_ASSUM(fun th ->
       if is_eq(concl th) && lhand(concl th) = `f1bnd:int256`
       then ALL_TAC else failwith "keep")) THEN
    X86_VSTEPS_TAC EXEC (10--10) THEN
    X86_VSTEPS_TAC EXEC (11--11) THEN
    ABBREV_TAC `f0sub:int256 = read YMM0 s11` THEN
    (* four gather foralls (bg1 direct low-128; bg2 low-128>>64; bg3 high-128; bg4 high-128>>64) *)
    eta2_gather_block g1_eta2 (eta2_ellist 0)  false THEN
    eta2_gather_block g2_eta2 (eta2_ellist 32) true THEN
    eta2_gather_block g3_eta2 (eta2_ellist 64) false THEN
    eta2_gather_block g4_eta2 (eta2_ellist 96) true;;

  (* The per-int32-lane reduction bridge: red_lane v = the exact stepper expr.
     The multiply constant `word 4294960736:int32` is `word_sx(word 0xe660:int16)`;
     red_lane holds it as `word 0xe660` sign-extended, so one WORD_REDUCE closes it. *)
  let RED_LANE_STEPFORM = prove
   (`!v:int32. red_lane v =
       word_add v
         (word_join
            (word_mul (word_subword (word_add (word_ushr (word_mul (word_sx (word_subword v (16,16):int16)) (word 4294960736:int32)) 14) (word 1)) (1,16):int16) (word 5:int16))
            (word_mul (word_subword (word_add (word_ushr (word_mul (word_sx (word_subword v (0,16):int16)) (word 4294960736:int32)) 14) (word 1)) (1,16):int16) (word 5:int16))
          :int32)`,
    GEN_TAC THEN REWRITE_TAC[red_lane; mulhrs_eta2] THEN
    REWRITE_TAC[WORD_REDUCE_CONV `word_sx (word 58976:int16):int32`]);;

  (* Collapse word_subword(word_subword x (p1,l1))(p2,l2) with concrete numerals:
     the usimd8 expansion of `usimd8 red_lane sx1` produces
     word_subword(word_subword sx1 (32k,32))(16,16), which the flat stepper tree
     has as word_subword sx1 (32k+16,16). *)
  let SUBWORD_SUBWORD_CONV : conv =
    fun tm ->
      let inst = PART_MATCH (lhs o snd o dest_imp) WORD_SUBWORD_SUBWORD tm in
      let ant = REWRITE_RULE[DIMINDEX_4;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;
                             DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] inst in
      let solved = MP ant (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl ant)))) in
      CONV_RULE(RAND_CONV(RAND_CONV(NUM_REDUCE_CONV))) solved;;

  (* ========================================================================= *)
  (* eta2 CORRECT: the red_lane-composed store postcond.                       *)
  (*                                                                           *)
  (* The eta2 store value is `usimd8 red_lane (<word_sx gather pipeline>)` (the *)
  (* s17-19 mod-5 reduction wraps red_lane over the vpmovsxbd output).  These  *)
  (* three lemmas lift the word_sx-level store bridges through that extra      *)
  (* `usimd8 red_lane`, giving a SUBITER_STORE_POSTCOND_RL whose RHS carries the *)
  (* `MAP red_lane` that SUBITER_STORE_SPEC then rewrites to                   *)
  (* REJ_SAMPLE_ETA2_BYTES.                                                    *)
  (*                                                                           *)
  (*   USIMD8_LANE : generic int32-lane extract for an OPAQUE per-lane fn f:   *)
  (*     j<8 ==> word_subword (usimd8 f Y) (32j,32) = f (word_subword Y (32j,32)). *)
  (*     (The red_lane wrap needs the opaque-f version.  Proved by usimd8      *)
  (*     expansion + the WORD_SUBWORD_JOIN lane pick + SUBWORD_SUBWORD_CONV    *)
  (*     collapse + the trivial word_subword x (0,32)=x for int32.)            *)
  (*                                                                           *)
  (*   STORE_LANE_EQ_REJBLOCK_RL : lane j of the red_lane-wrapped store =      *)
  (*     EL j (MAP red_lane (MAP word_sx (SUB_LIST(0,k)(PSHUFB_OUT_LIST g m)))). *)
  (*                                                                           *)
  (*   SUBITER_STORE_POSTCOND_RL : the capstone.  Given the bytes256 dest holds *)
  (*     usimd8 red_lane (<word_sx pipeline>) and k<=8, the 4k stored bytes =  *)
  (*     num_of_wordlist(MAP red_lane (MAP word_sx (SUB_LIST(0,k)(PSHUFB_OUT_LIST *)
  (*     g m)))).  Proved by the same STORE_BYTES256_NUM_OF_WORDLIST MP, lane-match *)
  (*     via STORE_LANE_EQ_REJBLOCK_RL.                                        *)
  (*                                                                           *)
  (* SI1 fold plan: after the reduction refold rewrites the s20 store as       *)
  (* usimd8 red_lane (pf_target gather), MP SUBITER_STORE_POSTCOND_RL at       *)
  (* k = LENGTH(ACC_IDX mask8) to get the store =                              *)
  (* num_of_wordlist(MAP red_lane (MAP word_sx ...)); then MP SUBITER_STORE_SPEC *)
  (* (its LHS is exactly that MAP red_lane form) to fold to                    *)
  (* REJ_SAMPLE_ETA2_BYTES [b0..b3], and SUBITER_FOLD_STEP appends the block.  *)
  (* ========================================================================= *)

  (* Generic int32-lane extract for an opaque per-lane fn (red_lane, here).    *)
  let USIMD8_LANE = prove
   (`!(f:int32->int32) (Y:int256) j. j < 8
       ==> word_subword (usimd8 f Y) (32*j,32):int32 = f (word_subword Y (32*j,32))`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[ARITH_RULE `j < 8 <=> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`] THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[usimd8;usimd4;usimd2;
       DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN
    REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
             DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
      CONV_TAC NUM_REDUCE_CONV)) THEN
    CONV_TAC(DEPTH_CONV SUBWORD_SUBWORD_CONV) THEN
    REWRITE_TAC[WORD_BLAST `!x:int32. word_subword x (0,32):int32 = x`]);;

  (* Lane j of the red_lane-wrapped store = the red_lane-mapped gather element. *)
  let STORE_LANE_EQ_REJBLOCK_RL = prove
   (`!(g:int128) m k j. j < k /\ k <= 8
      ==> word_subword
            (usimd8 red_lane
              (usimd8 (\b:byte. word_sx b:int32)
                (word_zx (word_zx
                  (word_zx
                    (usimd16 (\i. if bit 7 i then word 0:byte
                                  else word_subword g (8 * val (word_subword i (0,4):4 word),8))
                      (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256)
                  :int128):int64)))
            (32*j,32):int32
          = EL j (MAP red_lane (MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST g m))))`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `j < 8` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[USIMD8_LANE] THEN
    ASM_SIMP_TAC[STORE_LANE_EQ_REJBLOCK] THEN
    SUBGOAL_THEN `LENGTH(MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k)(PSHUFB_OUT_LIST (g:int128) m))) = k` ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_MAP; LENGTH_SUB_LIST; LENGTH_PSHUFB_OUT_LIST] THEN ASM_ARITH_TAC;
      ASM_SIMP_TAC[EL_MAP]]);;

  (* Capstone: the eta2 red_lane store postcond.                               *)
  let SUBITER_STORE_POSTCOND_RL = prove
   (`!A s (g:int128) m k.
       k <= 8 /\
       read (memory :> bytes256 A) s =
         usimd8 red_lane
           (usimd8 (\b:byte. word_sx b:int32)
              (word_zx (word_zx (word_zx (usimd16 (\i. if bit 7 i then word 0:byte
                  else word_subword g (8 * val (word_subword i (0,4):4 word),8))
                (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256):int128):int64))
       ==> read (memory :> bytes(A, 4 * k)) s =
           num_of_wordlist (MAP red_lane (MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST g m))))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    MP_TAC(ISPECL [`A:int64`;
      `usimd8 red_lane
         (usimd8 (\b:byte. word_sx b:int32)
            (word_zx (word_zx (word_zx (usimd16 (\i. if bit 7 i then word 0:byte
                else word_subword (g:int128) (8 * val (word_subword i (0,4):4 word),8))
              (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256):int128):int64))`;
      `MAP red_lane (MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST (g:int128) m)))`;
      `k:num`; `s:x86state`] STORE_BYTES256_NUM_OF_WORDLIST) THEN
    ASM_REWRITE_TAC[] THEN
    ANTS_TAC THENL
     [REWRITE_TAC[LENGTH_MAP; LENGTH_SUB_LIST; LENGTH_PSHUFB_OUT_LIST] THEN
      CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
      REPEAT STRIP_TAC THEN MATCH_MP_TAC STORE_LANE_EQ_REJBLOCK_RL THEN ASM_REWRITE_TAC[];
      DISCH_THEN(fun th -> REWRITE_TAC[th])]);;

  (* ETA2_TAB1_TEQ_TAC: derive+ASSUME the s14 table-load teq (YMM9, s13/s14).  *)
  (* Generator for the four per-sub-iter table-load teq tactics: read the vmovq  *)
  (* table load at state `rds`, MP TABLE_VMOVQ_READ with the mask<256 bound, then *)
  (* rewrite the YMM9 read at state `ymms` by the zx-collapse lemma.  Varies only *)
  (* in the two state indices, the mask var, and the RLT/R_EQ support lemmas.     *)
  let ETA2_TAB_TEQ_GEN (rds:int) (ymms:int) (maskv:term) (rlt:thm) (req:thm) : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let rdst = mk_var("s"^string_of_int rds,`:x86state`)
      and ymmst = mk_var("s"^string_of_int ymms,`:x86state`) in
      let tblinv = find (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),v)),_) ->
           v=rdst && can(find_term(fun u->u=`mldsa_rej_uniform_table:byte list`)) (concl th) | _ -> false) asms in
      let mmod = mk_binop `MOD` (mk_comb(`val:int64->num`,maskv)) `256` in
      let tvr = MP (ISPECL[`table:int64`; mmod; rdst] TABLE_VMOVQ_READ) (CONJ tblinv rlt) in
      let ymm9 = find (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("YMM9",_)),v)),_)-> v=ymmst |_->false) asms in
      ASSUME_TAC (REWRITE_RULE[req; tvr] ymm9));;

  let ETA2_TAB1_TEQ_TAC : tactic = ETA2_TAB_TEQ_GEN 13 14 `mask8:int64` RLT R_EQ;;

  (* pf_target discharge (gather source g, table via mask8).                   *)
  (* Generator for the four per-sub-iter pshufb gather-target discharge tactics: *)
  (* find the `pshuf` word_join def + the `tab` TABLE_ENTRY eq by shape, then run *)
  (* the fixed rewrite/conv pipeline.  ETA2_PF_PROOF{,_2,_3,_4} are instances.    *)
  let mk_eta2_pf_proof (pshuf:term) (tab:term) : tactic =
    W(fun (asl,w) ->
      let pdef = find (fun th -> is_eq(concl th) && rand(concl th)=pshuf && can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
      let teq0 = find (fun th -> is_eq(concl th) &&
          (lhand(concl th)=tab || rand(concl th)=tab) &&
          can(find_term(fun u->match u with Const("TABLE_ENTRY",_)->true|_->false))(concl th) &&
          not(can(find_term(fun u->u=`f1bnd:int256`))(concl th))) (map snd asl) in
      let teq = if lhand(concl teq0)=tab then teq0 else SYM teq0 in
      SUBST1_TAC(SYM pdef) THEN REWRITE_TAC[teq] THEN
      REWRITE_TAC[usimd16;usimd8;usimd4;usimd2] THEN CONV_TAC(DEPTH_CONV BETA_CONV) THEN
      SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;DIMINDEX_4;ARITH] THEN
      CONV_TAC NUM_REDUCE_CONV THEN
      REWRITE_TAC[WORD_ZX_TRIVIAL; VAL_WORD_ZX_GEN; DIMINDEX_64; DIMINDEX_32; DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV THEN
      CONV_TAC(TOP_DEPTH_CONV SUBWORD_ZX_LOW_CONV) THEN REWRITE_TAC[ZX_128_256_128]);;

  let ETA2_PF_PROOF : tactic = mk_eta2_pf_proof `pshuf1:int256` `tab1:int256`;;

  (* Convenience: fold f0sub then discharge the pf_target subgoal.             *)
  (* Generator for the four ETA2_ESTABLISH_PF_TARGET*_TAC: fold the f0sub        *)
  (* word_join def into the `pshuf` assumption, then establish pf_target via the *)
  (* matching PF_PROOF tactic.  Instances differ only in pshuf/pf_target/pfproof.*)
  let mk_eta2_establish_pf_target (pshuf:term) (pft:term) (pfproof:tactic) : tactic =
    W(fun (asl,w) ->
      let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th)=`f0sub:int256` || rand(concl th)=`f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
      let f0fold = if rand(concl f0d)=`f0sub:int256` then f0d else SYM f0d in
      RULE_ASSUM_TAC(fun th ->
        if is_eq(concl th) && rand(concl th)=pshuf
        then REWRITE_RULE[f0fold] th else th)) THEN
    SUBGOAL_THEN pft ASSUME_TAC THENL [pfproof; ALL_TAC];;

  let ETA2_ESTABLISH_PF_TARGET_TAC : tactic =
    mk_eta2_establish_pf_target `pshuf1:int256` pf_target ETA2_PF_PROOF;;

  (* ========================================================================= *)
  (* eta2 CORRECT: the sub-iter-1 store fold.                                  *)
  (*                                                                           *)
  (* Runs after ETA2_PREFIX_TO_S11_TAC, which leaves f0sub abbreviated, the    *)
  (* four gather foralls (centre word 2) assumed, mask8 at R8, and the four    *)
  (* maskbit foralls (<15).  Step map:                                         *)
  (*   s12 vextracti128 $0 -> XMM8 (gather source = word_zx(subword f0sub))    *)
  (*   s13 movzbl r8b -> r10d                                                  *)
  (*   s14 vmovq (rdx,r10,8) -> YMM9 (table lane)                              *)
  (*   s15 vpshufb -> YMM9                                                     *)
  (*   s16 vpmovsxbd -> YMM1 (sx1)                                             *)
  (*   s17 vpmulhrsw ymm6 / s18 vpmullw ymm7 / s19 vpaddd (the mod-5 reduction, *)
  (*       absent in eta4; store value = red_lane(word_sx(2-nibble)))          *)
  (*   s20 vmovdqu STORE to word_add res (word (4 * outlen0))                  *)
  (*                                                                           *)
  (* Ordering matters: keep sx1 opaque through the reduction and step the      *)
  (* store raw (s20) first with the raw word_join tree present, since the      *)
  (* store simulator needs the raw stepper form (injecting the usimd8 red_lane *)
  (* form before s20 makes X86_STEPS fail with a mk_comb type mismatch).       *)
  (* Only after the store do we refold the store fact to usimd8 red_lane sx1   *)
  (* and rewrite it into the SUBITER_STORE_POSTCOND_RL shape, then apply       *)
  (* SUBITER_STORE_SPEC to fold to REJ_SAMPLE_ETA2_BYTES and append the block  *)
  (* onto the running prefix store SUB_LIST(0,16i) -> SUB_LIST(0,16i+4).       *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* Step s12 through the raw store s20, sx1 kept opaque, no refold yet.       *)
  let ETA2_SI1_STEP_TO_STORE_TAC : tactic =
    PURGE_STALE_STATES_TAC ["s10"] THEN
    X86_VSTEPS_TAC EXEC (12--12) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s11 = f0sub:int256`]) THEN
    PURGE_STALE_STATES_TAC ["s11"] THEN
    REABBREV_TAC `mask8 = read R8 s12` THEN
    X86_VERBOSE_STEP_TAC EXEC "s13" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s12 = mask8:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt ASSUME_TAC THENL [MASKBIT_TGT_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (14--14) THEN ETA2_TAB1_TEQ_TAC THEN
    REABBREV_TAC `tab1 = read YMM9 s14` THEN
    X86_VSTEPS_TAC EXEC (15--15) THEN REABBREV_TAC `pshuf1 = read YMM9 s15` THEN
    PURGE_STALE_STATES_TAC ["s14"] THEN
    X86_VSTEPS_TAC EXEC (16--16) THEN REABBREV_TAC `sx1 = read YMM1 s16` THEN
    PURGE_STALE_STATES_TAC ["s15"] THEN
    X86_VSTEPS_TAC EXEC (17--17) THEN X86_VSTEPS_TAC EXEC (18--18) THEN
    X86_VSTEPS_TAC EXEC (19--19) THEN
    PURGE_STALE_STATES_TAC ["s16";"s17";"s18"] THEN
    X86_STEPS_TAC EXEC (20--20);;

  (* Refold the store fact (bytes256 dest, s20) to `usimd8 red_lane sx1`, using
   the same per-lane mechanism as ETA2_SI1_REDUCE_REFOLD_TAC but with
     the store fact as the target/rewrite source (read YMM1 s19 is gone).  The
     raw-tree store fact is matched by requiring `word_join` in the RHS (the raw
     stepper form) — this disambiguates it from the MAYCHANGE frame (which also
     carries a bytes256 component and a trailing s20) and from any later refolded
     copy.  It ASSUMEs `read(mem:>bytes256 A) s20 = usimd8 red_lane sx1`. *)
  (* Generator for the per-sub-iter store-refold tactic: find the bytes256 store *)
  (* fact at state `store_st`, then prove its LHS equals `usimd8 red_lane sx` by  *)
  (* rewriting the store word_join tree and reducing both sides (SUBWORD_SUBWORD + *)
  (* WORD_SIMPLE_SUBWORD collapse the vpaddd/vpmullw packing so REFL_TAC closes).  *)
  let mk_eta2_store_refold (store_st:string) (sx:term) : tactic =
    W(fun (asl,w) ->
      let stv = mk_var(store_st,`:x86state`) in
      let storef = find (fun th -> is_eq(concl th) &&
          can(find_term(fun u->match u with Const("bytes256",_)->true|_->false))(lhand(concl th)) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(rand(concl th)) &&
          (match concl th with
             Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),v)),_)-> v=stv|_->false))
         (map snd asl) in
      let memlhs = lhand(concl storef) in
      let rhs = subst [sx,`sx1:int256`] `usimd8 red_lane (sx1:int256)` in
      SUBGOAL_THEN (mk_eq(memlhs, rhs)) ASSUME_TAC THENL
       [REWRITE_TAC[storef] THEN
        REWRITE_TAC[usimd8;usimd4;usimd2;
           DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
        CONV_TAC(DEPTH_CONV BETA_CONV) THEN
        REWRITE_TAC[RED_LANE_STEPFORM] THEN
        CONV_TAC(DEPTH_CONV SUBWORD_SUBWORD_CONV) THEN
        CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
        REFL_TAC;
        ALL_TAC]);;

  let ETA2_STORE_REFOLD_TAC : tactic = mk_eta2_store_refold "s20" `sx1:int256`;;

  (* sx1 clean form (the vpmovsxbd lane form).                                 *)
  (* Generator for the per-sub-iter sx-clean tactic: prove `sx = usimd8 word_sx  *)
  (* (word_zx(word_zx pshuf))` by substituting the sx word_join def and WORD_BLAST.*)
  (* The goal term is built by substituting sx/pshuf into sub-iter 1's literal so *)
  (* the shape/types are guaranteed identical to the hand-written original.        *)
  let mk_eta2_sx_clean (sx:term) (pshuf:term) : tactic =
    let goal = subst [sx,`sx1:int256`; pshuf,`pshuf1:int256`]
      `sx1:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf1:int256):int128):int64)` in
    SUBGOAL_THEN goal ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sxdef = find (fun th -> is_eq(concl th) && rand(concl th)=sx &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sxdef) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC];;

  let ETA2_SX1_CLEAN_TAC : tactic = mk_eta2_sx_clean `sx1:int256` `pshuf1:int256`;;

  (* The full SI1 store fold: from post-ETA2_PREFIX_TO_S11_TAC to the folded
     running-prefix store fact ASSUMEd at s20. *)
  let ETA2_SI1_FOLD : tactic =
    ETA2_SI1_STEP_TO_STORE_TAC THEN
    ETA2_STORE_REFOLD_TAC THEN
    ETA2_SX1_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      (* the store refold: read(mem:>bytes256 A) s20 = usimd8 red_lane sx1.  Match loosely
         (bytes256 in LHS + red_lane in RHS) so a perturbed sx1 form still matches. *)
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      (* sx1 clean form                                                        *)
      let sx1clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx1:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      (* pf_target: pshuf1 = <gather form>                                     *)
      let pfth = find (fun th -> concl th = pf_target) asms in
      (* the gather forall (bg1) for lane block 0, ASSUMEd by ETA2_PREFIX_TO_S11 *)
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))c &&
          not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt) asms in
      (* store fact in the SUBITER_STORE_POSTCOND_RL LHS shape                 *)
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx1clean] storerf) in
      let g = `word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128` in
      let m = `word (val (mask8:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * outlen0)):int64`; `s20:x86state`; g; m;
                       `LENGTH(ACC_IDX (word (val (mask8:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      (* SUBITER_STORE_SPEC: MAP red_lane (MAP word_sx (SUB_LIST(0,k)(PSHUFB_OUT_LIST g m)))
         = REJ_SAMPLE_ETA2_BYTES [b0..b3] *)
      let spec = ISPECL [g; m; `word_subword (chunk0:int128) (0,8):byte`;
          `word_subword (chunk0:int128) (8,8):byte`; `word_subword (chunk0:int128) (16,8):byte`;
          `word_subword (chunk0:int128) (24,8):byte`] SUBITER_STORE_SPEC in
      let gather_hyp = List.nth (conjuncts(lhand(concl spec))) 1 in
      let gthm = EQ_MP (SYM(REWRITE_CONV[WORD_ZX_TRIVIAL] gather_hyp)) bg in
      let specres = MP spec (CONJ mthm gthm) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      (* fold onto the running prefix (SUB_LIST(0,16i) -> SUB_LIST(0,16i+4))   *)
      let blk = `[word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
                  word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:byte list` in
      let prefixbytes = `SUB_LIST(0,16*i) (inlist:byte list)` in
      let prefix_store = find (fun th ->
           (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s20",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th &&
           can(find_term(fun u->u=`res:int64`))(lhand(concl th)) &&
           can(find_term(fun u->u=`outlen0:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th)) asms in
      let len_eq = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let lenle = REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1) <= 136 ==> 16*i+16 <= 136`) i116) in
      let lr = MP (ISPECL [m; `chunk0:int128`] LEN_RECONCILE) mthm in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES) (CONJ lenle blk16) in
      let blk_bytes = CONJUNCT1 bb in
      let rej_store2 = REWRITE_RULE[SYM len_eq] rej_store in
      let prefix_store2 = REWRITE_RULE[SYM len_eq] prefix_store in
      let fold = MP (ISPECL [`res:int64`;`s20:x86state`;m;blk;prefixbytes] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store2 rej_store2)) in
      let split0 = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM blk_bytes; GSYM split0] fold in
      ASSUME_TAC clean);;

  (* ========================================================================= *)
  (* eta2 CORRECT: SI2+ constant-independent substrate.                        *)
  (*                                                                           *)
  (* The two eta2-generalized helpers the sub-iter 2/3/4 store folds need.  Both *)
  (* are pure list/word algebra.                                               *)
  (*                                                                           *)
  (* LEN_RECONCILE_GEN: LEN_RECONCILE generalized to arbitrary 4 block bytes   *)
  (*   b0..b3 (LEN_RECONCILE hardcoded chunk0 lanes 0/8/16/24).  Needed because *)
  (*   sub-iter k's block bytes are chunk0 (32,40,48,56) for SI2, (64,72,80,88) *)
  (*   for SI3, etc.                                                           *)
  let LEN_RECONCILE_GEN = prove
   (`!(m:byte) (b0:byte) (b1:byte) (b2:byte) (b3:byte).
       (!j. j < 8 ==> (bit j m <=>
          EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16] < 15))
       ==> LENGTH(ACC_IDX m) =
           LENGTH(REJ_SAMPLE_ETA2_BYTES [b0;b1;b2;b3]:int32 list)`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`m:byte`;
      `word(val(b0:byte) MOD 16):byte`; `word(val(b0:byte) DIV 16):byte`;
      `word(val(b1:byte) MOD 16):byte`; `word(val(b1:byte) DIV 16):byte`;
      `word(val(b2:byte) MOD 16):byte`; `word(val(b2:byte) DIV 16):byte`;
      `word(val(b3:byte) MOD 16):byte`; `word(val(b3:byte) DIV 16):byte`] ACC_LENGTH_EQ_FILTER_ETA2) THEN
    ANTS_TAC THENL
     [REPEAT CONJ_TAC THEN
      W(fun (asl,gw) -> let n = rand(rator(lhand gw)) in
         MP_TAC(SPEC n (find (fun th -> is_forall(concl th) && can(find_term(fun u->match u with Const("EL",_)->true|_->false))(concl th)) (map snd asl)))) THEN
      CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
      DISCH_THEN SUBST1_TAC THEN
      W(fun (asl,gw) -> let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="val" && type_of(rand u)=`:byte` with _->false) gw in
         let bt = rand bt in
         MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN STRIP_TAC THEN
         SUBGOAL_THEN (mk_eq(mk_comb(`val:byte->num`,mk_comb(`word:num->byte`,mk_binop `MOD` (mk_comb(`val:byte->num`,bt)) `16`)), mk_binop `MOD` (mk_comb(`val:byte->num`,bt)) `16`)) SUBST1_TAC THENL
          [REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN (mk_eq(mk_comb(`val:byte->num`,mk_comb(`word:num->byte`,mk_binop `DIV` (mk_comb(`val:byte->num`,bt)) `16`)), mk_binop `DIV` (mk_comb(`val:byte->num`,bt)) `16`)) SUBST1_TAC THENL
          [REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
         REFL_TAC);
      DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[LENGTH_FILTER_BYTE_NIBBLES_4_BYTES; LENGTH_REJ_SAMPLE_ETA2_BYTES]]);;

  (* ACC1_IDENT_TAC.  acc1 must be ABBREV'd as
     outlen0 + LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16i,4))), with the outlen0 def in
     asl.  Proves & ASSUMEs LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16i+4)))=acc1. *)
  let ACC1_IDENT_TAC : tactic =
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` ASSUME_TAC THENL
    [ONCE_REWRITE_TAC[REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i`;`4`;`0`] SUB_LIST_SPLIT)] THEN
     REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND] THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_))->true|_->false)
         then ASSUME_TAC(REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA2_BYTES] th) else NO_TAC) THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_NIBBLES_ETA2",_),_))),Var("outlen0",_))->true|_->false)
         then REWRITE_TAC[th] else NO_TAC) THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),_),Var("acc1",_))->can(find_term(fun u->u=`outlen0:num`))(concl th)|_->false) then (MP_TAC th THEN ARITH_TAC) else NO_TAC); ALL_TAC];;

  (* ETA2_TAB2_TEQ_TAC: derive the sub-iter-2 table-load bridge teq (tab2) at s28. *)
  let ETA2_TAB2_TEQ_TAC : tactic = ETA2_TAB_TEQ_GEN 28 29 `mask8b:int64` RLT_B R_EQ_B;;

  (* ETA2_PF_PROOF_2: discharge the sub-iter-2 `pshuf2 = pf_target_2` subgoal. *)
  let ETA2_PF_PROOF_2 : tactic = mk_eta2_pf_proof `pshuf2:int256` `tab2:int256`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SI2 store fold.                                         *)
  (*                                                                           *)
  (* The sub-iter-2 analogue of ETA2_SI1_FOLD.  Runs AFTER ETA2_SI1_COUNTER_TAC, *)
  (* which leaves s26 (RIP=pc+207 = SI2 entry), R8 s26 = mask8>>8 (the         *)
  (* sub-iter-2 mask byte, bits 8-15 of the packed 32-bit popcount mask), and  *)
  (* the running-prefix store fact folded to SUB_LIST(0,16i+4) present.  It    *)
  (* advances the SIMD store for block1 (chunk0 lanes 32/40/48/56) and folds the *)
  (* prefix to SUB_LIST(0,16i+8).  Uses the red_lane store wrap                *)
  (* (SUBITER_STORE_POSTCOND_RL), the >>64-shifted gather source g2, and the   *)
  (* f0sub RE-FOLD on XMM8 (the SI1 counter block does NOT carry the           *)
  (* `read YMM0 s11 = f0sub` fold onto XMM8, so f0sub is EXPANDED at s27; its  *)
  (* ABBREV def survives in the asl, so RULE_ASSUM re-folds it).               *)
  (*                                                                           *)
  (* eta2 SI2 step map:                                                        *)
  (*   s27 vpsrldq $8 xmm8 (0xd3) -> XMM8 (gather src, f0sub EXPANDED),        *)
  (*       RIP s27 = pc+213                                                    *)
  (*   s28 movzbl r8b -> r10d (REX-byte shim; MOVZBL_R10_CAPTURE_TAC)          *)
  (*   s29 vmovq (rdx,r10,8) -> YMM9 (table lane; ETA2_TAB2_TEQ_TAC)           *)
  (*   s30 vpshufb -> YMM9 (pshuf2)                                            *)
  (*   s31 vpmovsxbd -> YMM1 (sx2)                                             *)
  (*   s32 vpmulhrsw ymm6 / s33 vpmullw ymm7 / s34 vpaddd — the mod-5 reduction *)
  (*   s35 vmovdqu STORE to word_add res (word (4 * acc1))                     *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* Setup + step s27..s35 (raw store, sx2 opaque).  From s26 (post-SI1-counter). *)
  let ETA2_SI2_STEP_TO_STORE_TAC : tactic =
    REABBREV_TAC `mask8b = read R8 s26` THEN
    ABBREV_TAC `acc1 = outlen0 + LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)` THEN
    ACC1_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1`]) THEN
    (* s27 vpsrldq -> XMM8; f0sub is EXPANDED here.  Its surviving ABBREV def (the
       s11 stepper assumption, with `read YMM0 s11` abstracted to f0sub) is
       `f0sub = <word_join tree>` (f0sub on LHS).  Fold the expanded tree back to
       `f0sub` via `<tree> = f0sub` (= SYM of the def).  Skip the def itself so it
       survives for pf_target_2's fold. *)
    X86_VSTEPS_TAC EXEC (27--27) THEN
    W(fun (asl,w) ->
       let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th) = `f0sub:int256` || rand(concl th) = `f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       let f0fold = if rand(concl f0d) = `f0sub:int256` then f0d else SYM f0d in
       RULE_ASSUM_TAC(fun th -> if concl th = concl f0d then th else REWRITE_RULE[f0fold] th)) THEN
    X86_VERBOSE_STEP_TAC EXEC "s28" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s27 = mask8b:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt_2 ASSUME_TAC THENL [MASKBIT_TGT_2_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (29--29) THEN ETA2_TAB2_TEQ_TAC THEN
    REABBREV_TAC `tab2 = read YMM9 s29` THEN
    X86_VSTEPS_TAC EXEC (30--30) THEN REABBREV_TAC `pshuf2 = read YMM9 s30` THEN
    PURGE_STALE_STATES_TAC ["s29"] THEN
    X86_VSTEPS_TAC EXEC (31--31) THEN REABBREV_TAC `sx2 = read YMM1 s31` THEN
    PURGE_STALE_STATES_TAC ["s30"] THEN
    X86_VSTEPS_TAC EXEC (32--32) THEN X86_VSTEPS_TAC EXEC (33--33) THEN
    X86_VSTEPS_TAC EXEC (34--34) THEN
    PURGE_STALE_STATES_TAC ["s31";"s32";"s33"] THEN
    VAL_INT64_TAC `acc1:num` THEN
    X86_STEPS_TAC EXEC (35--35);;

  (* Refold the s35 store fact (bytes256) to `usimd8 red_lane sx2` —
     ETA2_STORE_REFOLD_TAC with s20->s35, sx1->sx2 (constant-independent). *)
  let ETA2_STORE_REFOLD_2_TAC : tactic = mk_eta2_store_refold "s35" `sx2:int256`;;

  (* sx2 clean form (vpmovsxbd lane form) — ETA2_SX1_CLEAN_TAC, sx1->sx2.      *)
  let ETA2_SX2_CLEAN_TAC : tactic = mk_eta2_sx_clean `sx2:int256` `pshuf2:int256`;;

  (* PERF: fold the expanded f0sub subtree back to the var in the pshuf2 def, then
   discharge pf_target_2 — ETA2_ESTABLISH_PF_TARGET_TAC for pshuf2. *)
  let ETA2_ESTABLISH_PF_TARGET_2_TAC : tactic =
    mk_eta2_establish_pf_target `pshuf2:int256` pf_target_2 ETA2_PF_PROOF_2;;

  (* The full SI2 store fold: from post-ETA2_SI1_COUNTER (s26) to the folded
     running-prefix store fact ASSUMEd at s35 (prefix SUB_LIST(0,16i+8)). *)
  let ETA2_SI2_FOLD : tactic =
    ETA2_SI2_STEP_TO_STORE_TAC THEN
    ETA2_STORE_REFOLD_2_TAC THEN
    ETA2_SX2_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_2_TAC THEN
    ACC1_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      (* store refold: read(mem:>bytes256 A) s35 = usimd8 red_lane sx2         *)
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      let sx2clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx2:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      let pfth = find (fun th -> concl th = pf_target_2) asms in
      (* the >>64-shifted gather forall (bg2) for lane block 32, ASSUMEd by ETA2_PREFIX_TO_S11 *)
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c &&
          not(can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c)) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt_2) asms in
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx2clean] storerf) in
      let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8b:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc1)):int64`; `s35:x86state`; g2; m;
                       `LENGTH(ACC_IDX (word (val (mask8b:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      (* SUBITER_STORE_SPEC on the block1 lanes (chunk0 32/40/48/56)           *)
      let spec = ISPECL [g2; m; `word_subword (chunk0:int128) (32,8):byte`;
          `word_subword (chunk0:int128) (40,8):byte`; `word_subword (chunk0:int128) (48,8):byte`;
          `word_subword (chunk0:int128) (56,8):byte`] SUBITER_STORE_SPEC in
      let specres = MP spec (CONJ mthm bg) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      (* block1 bytes, fold onto the running prefix SUB_LIST(0,16i+4) -> SUB_LIST(0,16i+8) *)
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=136 ==> 16*i+16<=136`) i116)) blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in    (* SUB_LIST(16i+4,4) = [lanes 32,40,48,56] *)
      (* LEN_RECONCILE_GEN over the block1 bytes                               *)
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (32,8):byte`;`word_subword (chunk0:int128) (40,8):byte`;
          `word_subword (chunk0:int128) (48,8):byte`;`word_subword (chunk0:int128) (56,8):byte`] LEN_RECONCILE_GEN) mthm in
      let lr = REWRITE_RULE[GSYM blk1_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk1_eq] rej_store in
      (* restate store addresses/prefix via acc1_ident                         *)
      let acc1_ident = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc1",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s35",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc1:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc1_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc1_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s35:x86state`;m;`SUB_LIST(16*i+4,4) (inlist:byte list)`;`SUB_LIST(0,16*i+4) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+4`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+4)+4 = 16*i+8`] fold in
      ASSUME_TAC clean);;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SI2 counter+branch block (s36-41).                      *)
  (*                                                                           *)
  (* The sub-iter-2 counter, using POPCNT_BYTE1 because the SI2 mask byte is   *)
  (* byte-1 of the packed 32-bit popcount sum: mask8b = R8 s26 =               *)
  (* word_zx(word_ushr(word_zx(word(SUM32 over f1bnd lanes 0-31))) 8) (the SUM32 *)
  (* survives inside the mask8b ABBREV def).  POPCNT_BYTE1 (which encodes the >>8 *)
  (* + MOD 256 internally) extracts bits 8-15 = f1bnd lanes 8-15 = block1      *)
  (* (chunk0 lanes 32-56).                                                     *)
  (*                                                                           *)
  (* Runs AFTER ETA2_SI2_FOLD from s35 (running prefix store folded to         *)
  (* SUB_LIST(0,16i+8), mask8b + acc1 abbreviated, maskbit_tgt_2 ASSUMEd).  It *)
  (* advances RAX (acc1 -> acc1 + block1len), RCX (16i+4 -> 16i+8), R8 (mask8b -> *)
  (* mask8b>>8 = mask8c), and resolves the mid-iteration ja to the SI3 entry.  *)
  (*                                                                           *)
  (* Control flow:                                                             *)
  (*   s36 popcnt %r10d,%r9d ; s37 add %r9d,%eax ; s38 shr $0x8,%r8d ;         *)
  (*   s39 add $0x4,%ecx (RIP s39 = pc+266) ; s40 cmp $0xf8,%eax ; s41 ja scalar *)
  (*   -> RIP s41 = if <ja> then pc+399 else pc+273  (fall-through = SI3 entry). *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* SI2_MG: build pop_len2 (popcount = block1len), bnd2c (acc1+block1len<=248),
     rax_red0 (RAX collapse), ja (JA_NOT_TAKEN). *)
  let ETA2_SI2_MG_TAC : tactic =
    X86_STEPS_TAC EXEC (36--39) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt2 = REWRITE_RULE[m8b_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE1)) in
      let lanesum8 = rand(concl popcnt2) in
      (* the f1bnd-lane maskbit forall for lanes 8-15 (the `8*(k+8)` one)      *)
      let mb2 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),c) -> c=`8` | _ -> false))c) in
      let mb2_tm = concl mb2 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le))
                        blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in
      let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                     word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
      let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block1)) in
      let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      (* fold explicit block1 -> SUB_LIST(16i+4,4) via blk1_eq (GSYM)          *)
      let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
      (* bound: acc1 + block1len <= 248, via SUBITER_OUTLEN_BOUND_2 rewritten to acc1 *)
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 136`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
      let bnd2 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_2) (CONJ a1 nibbnd) in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),_),_)),Var("acc1",_)) -> true | _ -> false) in
      let bnd2a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd2 in
      let bnd2c = REWRITE_RULE[acc1_def] bnd2a in   (* acc1 + block1len <= 248 *)
      let block1len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd2c in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL[mk_binop `(+):num->num->num` `acc1:num` block1len; `248`] JA_NOT_TAKEN_LE)
                  (CONJ bnd2c (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len2 THEN ASSUME_TAC bnd2c THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja);;

  (* SI2_RESOLVE: step s40-41, resolve RIP s41 = pc+273.                       *)
  let ETA2_SI2_RESOLVE_TAC : tactic =
    X86_STEPS_TAC EXEC (40--41) THEN
    SUBGOAL_THEN `read RIP s41 = word (pc + 273):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let pop_len2_old = find (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asms in
        let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
        let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) pop_len2_old in
        let rax_red0 = find (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asms in
        let ja = find (fun th -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc1:num`))(concl th)) asms in
        let ifrip = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s41",_))),r) ->
             (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asms in
        MP_TAC ifrip THEN REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* fold RAX read clean using pop_len2 + rax_red0 (now in asl)              *)
    W(fun (asl,w) ->
      let pl = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let rr = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pl_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pl) in
      RULE_ASSUM_TAC(REWRITE_RULE[pl_typed]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr])) THEN
    ALL_TAC;;

  let ETA2_SI2_COUNTER_TAC : tactic =
    ETA2_SI2_MG_TAC THEN ETA2_SI2_RESOLVE_TAC;;

  (* DIVMOD65536_SPLIT / R_EQ_C / RLT_C.                                       *)
  let ETA2_TAB3_TEQ_TAC : tactic = ETA2_TAB_TEQ_GEN 43 44 `mask8c:int64` RLT_C R_EQ_C;;

  (* ETA2_PF_PROOF_3: discharge the sub-iter-3 `pshuf3 = pf_target_3` subgoal. *)
  let ETA2_PF_PROOF_3 : tactic = mk_eta2_pf_proof `pshuf3:int256` `tab3:int256`;;

  (* ACC2_IDENT_TAC.  acc2 = acc1 + LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16i+4,4)));
     needs acc1_ident (LENGTH REJ_SAMPLE form) + acc2 ABBREV def in asl.  Proves &
     ASSUMEs LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16i+8)))=acc2. *)
  let ACC2_IDENT_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let acc1_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc1",_))->true|_->false) asms in
      let acc2_def = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_))->true|_->false) asms in
      let split = REWRITE_RULE[ADD_CLAUSES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] (ISPECL[`inlist:byte list`;`16*i+4`;`4`;`0`] SUB_LIST_SPLIT) in
      let step1 = (REWRITE_CONV[LENGTH_REJ_SAMPLE_ETA2_BYTES] THENC ONCE_DEPTH_CONV(REWR_CONV split) THENC REWRITE_CONV[REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND])
                    `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` in
      let acc1_nib = REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA2_BYTES] acc1_ident in
      let final = TRANS step1 (TRANS (AP_THM (AP_TERM `(+):num->num->num` acc1_nib) `LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i+4,4) inlist):int16 list)`) acc2_def) in
      ASSUME_TAC final);;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SI3 store fold.                                         *)
  (*                                                                           *)
  (* The sub-iter-3 analogue of ETA2_SI2_FOLD.  Runs AFTER ETA2_SI2_COUNTER_TAC, *)
  (* which leaves s41 (RIP=pc+273 = SI3 entry), R8 s41 = mask8b>>8 (= mask8c,  *)
  (* byte 2 of the packed sum), RAX s41 = word(acc1 + block1len) [ALREADY folded *)
  (* by the SI2 counter], and the running-prefix store fact folded to          *)
  (* SUB_LIST(0,16i+8).  It advances the SIMD store for block2 (chunk0 lanes   *)
  (* 64/72/80/88) and folds the prefix to SUB_LIST(0,16i+12).                  *)
  (*                                                                           *)
  (* eta2 SI3 step map:                                                        *)
  (*   s42 vextracti128 $1 xmm8 (0x115) -> XMM8 (HIGH-128 of f0sub, EXPANDED), *)
  (*       RIP s42 = pc+279                                                    *)
  (*   s43 movzbl r8b -> r10d (shim; MOVZBL_R10_CAPTURE_TAC)                   *)
  (*   s44 vmovq (rdx,r10,8) -> YMM9 (ETA2_TAB3_TEQ_TAC)                       *)
  (*   s45 vpshufb -> YMM9 (pshuf3)                                            *)
  (*   s46 vpmovsxbd -> YMM1 (sx3)                                             *)
  (*   s47 vpmulhrsw / s48 vpmullw / s49 vpaddd — the mod-5 reduction          *)
  (*   s50 vmovdqu STORE to word_add res (word (4 * acc2))                     *)
  (*                                                                           *)
  (* Differences vs the SI2 fold: opener is vextracti128 $1 (not vpsrldq),     *)
  (* extracting the HIGH 128 of f0sub -> gather source g3 = word_zx(word_zx    *)
  (* (word_subword f0sub (128,128))) (NO >>64 shift), so the bg3 gather forall is *)
  (* used DIRECTLY (no WORD_ZX_TRIVIAL massage); acc1->acc2 base; block1->block2 *)
  (* (chunk0 lanes 64-88, `el 2` of SUBITER_BLOCK_BYTES); mask8b->mask8c;      *)
  (* prefix SUB_LIST(0,16i+8) -> SUB_LIST(0,16i+12).  RAX is already folded by the *)
  (* SI2 counter, so SI3_PRE only abbrevs acc2 + reabbrevs mask8c + bounds.    *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* SI3_PRE: abbrev acc2, reabbrev mask8c, bounds acc2<=248, VAL_INT64.  eta2's
     SI2 counter ALREADY folded RAX to word(acc1+block1len), so the acc2 ABBREV
     makes RAX = word acc2 directly (no pop_len/rax_red RULE_ASSUM). *)
  let ETA2_SI3_PRE_TAC : tactic =
    ABBREV_TAC `acc2 = acc1 + LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (16*i+4,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8c = read R8 s41` THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 136`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
      let bnd3 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_3) (CONJ a1 nibbnd) in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),Var("acc1",_)) -> true | _ -> false) in
      let acc2_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_)) -> true | _ -> false) in
      let bnd3a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd3 in
      let bnd3b = REWRITE_RULE[acc1_def] bnd3a in
      let bnd3c = REWRITE_RULE[acc2_def] (REWRITE_RULE[ADD_ASSOC] bnd3b) in
      ASSUME_TAC bnd3c THEN
      ASSUME_TAC (MATCH_MP (ARITH_RULE `acc2 + x <= 248 ==> acc2 <= 248`) bnd3c)) THEN
    VAL_INT64_TAC `acc2:num`;;

  (* Setup + step s42..s50 (raw store, sx3 opaque).  From s41 (post-SI2-counter). *)
  let ETA2_SI3_STEP_TO_STORE_TAC : tactic =
    ETA2_SI3_PRE_TAC THEN
    ACC2_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2`]) THEN
    (* s42 vextracti128 $1 -> XMM8 (HIGH-128 of EXPANDED f0sub); re-fold f0sub. *)
    X86_VSTEPS_TAC EXEC (42--42) THEN
    W(fun (asl,w) ->
       let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th) = `f0sub:int256` || rand(concl th) = `f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       let f0fold = if rand(concl f0d) = `f0sub:int256` then f0d else SYM f0d in
       RULE_ASSUM_TAC(fun th -> if concl th = concl f0d then th else REWRITE_RULE[f0fold] th)) THEN
    X86_VERBOSE_STEP_TAC EXEC "s43" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s42 = mask8c:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt_3 ASSUME_TAC THENL [MASKBIT_TGT_3_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (44--44) THEN ETA2_TAB3_TEQ_TAC THEN
    REABBREV_TAC `tab3 = read YMM9 s44` THEN
    X86_VSTEPS_TAC EXEC (45--45) THEN REABBREV_TAC `pshuf3 = read YMM9 s45` THEN
    PURGE_STALE_STATES_TAC ["s44"] THEN
    X86_VSTEPS_TAC EXEC (46--46) THEN REABBREV_TAC `sx3 = read YMM1 s46` THEN
    PURGE_STALE_STATES_TAC ["s45"] THEN
    X86_VSTEPS_TAC EXEC (47--47) THEN X86_VSTEPS_TAC EXEC (48--48) THEN
    X86_VSTEPS_TAC EXEC (49--49) THEN
    PURGE_STALE_STATES_TAC ["s46";"s47";"s48"] THEN
    VAL_INT64_TAC `acc2:num` THEN
    X86_STEPS_TAC EXEC (50--50);;

  (* Refold the s50 store fact (bytes256) to `usimd8 red_lane sx3`.            *)
  let ETA2_STORE_REFOLD_3_TAC : tactic = mk_eta2_store_refold "s50" `sx3:int256`;;

  (* sx3 clean form.                                                           *)
  let ETA2_SX3_CLEAN_TAC : tactic = mk_eta2_sx_clean `sx3:int256` `pshuf3:int256`;;

  (* PERF: fold expanded f0sub in the pshuf3 def, then discharge pf_target_3.  *)
  let ETA2_ESTABLISH_PF_TARGET_3_TAC : tactic =
    mk_eta2_establish_pf_target `pshuf3:int256` pf_target_3 ETA2_PF_PROOF_3;;

  (* The full SI3 store fold: from post-SI2-counter (s41) to the folded
     running-prefix store fact ASSUMEd at s50 (prefix SUB_LIST(0,16i+12)). *)
  let ETA2_SI3_FOLD : tactic =
    ETA2_SI3_STEP_TO_STORE_TAC THEN
    ETA2_STORE_REFOLD_3_TAC THEN
    ETA2_SX3_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_3_TAC THEN
    ACC2_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      let sx3clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx3:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      let pfth = find (fun th -> concl th = pf_target_3) asms in
      (* the HIGH-128 gather forall (bg3): f0sub, chunk0 lane 64, NO word_ushr, has f0sub (128,128) *)
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt_3) asms in
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx3clean] storerf) in
      let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
      let m = `word (val (mask8c:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc2)):int64`; `s50:x86state`; g3; m;
                       `LENGTH(ACC_IDX (word (val (mask8c:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g3; m; `word_subword (chunk0:int128) (64,8):byte`;
          `word_subword (chunk0:int128) (72,8):byte`; `word_subword (chunk0:int128) (80,8):byte`;
          `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC in
      let specres = MP spec (CONJ mthm bg) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      (* block2 bytes (el 2), fold onto the running prefix SUB_LIST(0,16i+8) -> SUB_LIST(0,16i+12) *)
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=136 ==> 16*i+16<=136`) i116)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in    (* SUB_LIST(16i+8,4) = [lanes 64,72,80,88] *)
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (64,8):byte`;`word_subword (chunk0:int128) (72,8):byte`;
          `word_subword (chunk0:int128) (80,8):byte`;`word_subword (chunk0:int128) (88,8):byte`] LEN_RECONCILE_GEN) mthm in
      let lr = REWRITE_RULE[GSYM blk2_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk2_eq] rej_store in
      let acc2_ident = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc2",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s50",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc2:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc2_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc2_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s50:x86state`;m;`SUB_LIST(16*i+8,4) (inlist:byte list)`;`SUB_LIST(0,16*i+8) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+8)+4 = 16*i+12`] fold in
      ASSUME_TAC clean);;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SI3 counter+branch block (s51-56).                      *)
  (*                                                                           *)
  (* The sub-iter-3 analogue of ETA2_SI2_COUNTER_TAC.  Runs AFTER ETA2_SI3_FOLD, *)
  (* which leaves s50 (running prefix store folded to SUB_LIST(0,16i+12), mask8c *)
  (* + acc2 abbreviated, maskbit_tgt_3 ASSUMEd).  It advances RAX (acc2 -> acc2 + *)
  (* block2len), RCX (16i+8 -> 16i+12), R8 (mask8c -> mask8c>>8 = mask8d), and *)
  (* resolves the mid-iteration ja to the SI4 entry.                           *)
  (*                                                                           *)
  (* Control flow:                                                             *)
  (*   s51 popcnt %r10d,%r9d ; s52 add %r9d,%eax ; s53 shr $0x8,%r8d ;         *)
  (*   s54 add $0x4,%ecx (RIP s54 = pc+332) ; s55 cmp $0xf8,%eax ; s56 ja scalar *)
  (*   -> RIP s56 = if <ja> then pc+399 else pc+339  (fall-through = SI4 entry; *)
  (*      SI4 opener raw 0x157 = vpsrldq $8 %xmm8 = tmc pc+339).               *)
  (*   RAX s54 = word_zx(word_add(word_zx(word acc2))(word_zx^2(word(word_popcount *)
  (*     (word_zx^3(word(val mask8c MOD 256))))))) ; R8 s54 = mask8c>>8.       *)
  (*                                                                           *)
  (* Uses POPCNT_BYTE2 (byte 2 of the packed 32-bit popcount sum = f1bnd lanes *)
  (* 16-23), the mb3 f1bnd-lane maskbit forall (`8*(k+16)`), SUBITER_OUTLEN_   *)
  (* BOUND_3 (rewritten to acc2 base), and zxbyte_eq for the RAX-fold type bridge. *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* SI3_MG: build pop_len3 (popcount = block2len), bnd3c (acc2+block2len<=248),
     rax_red0 (RAX collapse), ja (JA_NOT_TAKEN). *)
  let ETA2_SI3_MG_TAC : tactic =
    X86_STEPS_TAC EXEC (51--54) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      (* BOTH defs: mask8c = mask8b>>8, so folding the SUM32 needs m8b_def first
         (SUM32 -> mask8b) then m8c_def (mask8b>>8 -> mask8c).  Using only m8c_def
         leaves the popcount over the expanded SUM32. *)
      let popcnt3 = REWRITE_RULE[m8b_def; m8c_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE2)) in
      let lanesum8 = rand(concl popcnt3) in
      (* the f1bnd-lane maskbit forall for lanes 16-23 (the `8*(k+16)` one)    *)
      let mb3 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),c) -> c=`16` | _ -> false))c) in
      let mb3_tm = concl mb3 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le))
                        blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                     word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
      let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block2)) in
      let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum8, block2len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
      (* bound: acc2 + block2len <= 248, via SUBITER_OUTLEN_BOUND_3 rewritten to acc2 *)
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 136`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
      let bnd3 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_3) (CONJ a1 nibbnd) in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),Var("acc1",_)) -> true | _ -> false) in
      let acc2_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_)) -> true | _ -> false) in
      let bnd3a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd3 in
      let bnd3b = REWRITE_RULE[acc1_def] bnd3a in
      let bnd3c = REWRITE_RULE[acc2_def] (REWRITE_RULE[ADD_ASSOC] bnd3b) in  (* acc2 + block2len <= 248 *)
      let block2len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd3c in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL[mk_binop `(+):num->num->num` `acc2:num` block2len; `248`] JA_NOT_TAKEN_LE)
                  (CONJ bnd3c (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len3 THEN ASSUME_TAC bnd3c THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja);;

  (* SI3_RESOLVE (zxbyte_eq bridge): step s55-56, resolve RIP s56 = pc+339.  The
     COND's popcount arg is byte-zx-typed (byte->i32->i64->i32) while pop_len3
     (POPCNT_BYTE2) is all-int32 — they print identically but aconv=false, so we
     MUST bridge via zbe before REWRITE (as SI2 does), else REFL_TAC fails.
     Disambiguate pop_len3 (mask8c / SUB_LIST(16i+8,4)) from the leftover
     SI2 pop_len2 (mask8b / SUB_LIST(16i+4,4)) via the SUB_LIST(16i+8,4) marker. *)
  let ETA2_SI3_RESOLVE_TAC : tactic =
    X86_STEPS_TAC EXEC (55--56) THEN
    SUBGOAL_THEN `read RIP s56 = word (pc + 339):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let find_a p = find p asms in
        (* The counter step already folded popcnt->LENGTH(REJ_NIBBLES[EXPLICIT block2]) into the
           COND (not SUB_LIST); convert explicit block2 -> SUB_LIST(16i+8,4) via GSYM blk2_eq so
           rax_red0/ja match. *)
        let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
        let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
        let blk16 = find_a (fun th -> is_eq(concl th) &&
           (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                    (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
        let blk2_eq = el 2 (CONJUNCTS bb) in
        let rax_red0 = find (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
              can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) asms in
        let ja = find (fun th -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc2:num`))(concl th)) asms in
        let ifrip = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s56",_))),r) ->
             (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asms in
        MP_TAC ifrip THEN REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* fold RAX read clean: the RAX read carries popcnt folded to LENGTH(REJ_NIBBLES[EXPLICIT
       block2]); convert -> SUB_LIST(16i+8,4) via GSYM blk2_eq, then rax_red0 collapses it to
       word(acc2 + block2len).  (Same explicit->SUB_LIST issue as the RIP resolution.) *)
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let rr = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
      RULE_ASSUM_TAC(REWRITE_RULE[GSYM blk2_eq]) THEN RULE_ASSUM_TAC(REWRITE_RULE[rr])) THEN
    ALL_TAC;;

  let ETA2_SI3_COUNTER_TAC : tactic =
    ETA2_SI3_MG_TAC THEN ETA2_SI3_RESOLVE_TAC;;

  (* DIVMOD16777216_SPLIT / R_EQ_D / RLT_D.                                    *)
  let ETA2_TAB4_TEQ_TAC : tactic = ETA2_TAB_TEQ_GEN 58 59 `mask8d:int64` RLT_D R_EQ_D;;

  (* ETA2_PF_PROOF_4: discharge the sub-iter-4 `pshuf4 = pf_target_4` subgoal. *)
  let ETA2_PF_PROOF_4 : tactic = mk_eta2_pf_proof `pshuf4:int256` `tab4:int256`;;

  (* ACC3_IDENT_TAC.  acc3 = acc2 + LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16i+8,4)));
     needs acc2_ident (LENGTH REJ_SAMPLE form) + acc3 ABBREV def in asl.  Proves &
     ASSUMEs LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16i+12)))=acc3. *)
  let ACC3_IDENT_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let acc2_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc2",_))->true|_->false) asms in
      let acc3_def = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),Var("acc3",_))->true|_->false) asms in
      let split = REWRITE_RULE[ADD_CLAUSES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let step1 = (REWRITE_CONV[LENGTH_REJ_SAMPLE_ETA2_BYTES] THENC ONCE_DEPTH_CONV(REWR_CONV split) THENC REWRITE_CONV[REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND])
                    `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` in
      let acc2_nib = REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA2_BYTES] acc2_ident in
      let final = TRANS step1 (TRANS (AP_THM (AP_TERM `(+):num->num->num` acc2_nib) `LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i+8,4) inlist):int16 list)`) acc3_def) in
      ASSUME_TAC final);;

  (* ========================================================================= *)
  (* eta2 CORRECT: the SI4 store fold.                                         *)
  (*                                                                           *)
  (* The sub-iter-4 (LAST) analogue of ETA2_SI3_FOLD.  Runs AFTER              *)
  (* ETA2_SI3_COUNTER_TAC, which leaves s56 (RIP=pc+339 = SI4 entry), R8 s56 = *)
  (* mask8c>>8 (= mask8d, byte 3 of the packed sum), RAX s56 = word(acc2 +     *)
  (* block2len) [ALREADY folded by the SI3 counter], and the running-prefix    *)
  (* store fact folded to SUB_LIST(0,16i+12).  It advances the SIMD store for  *)
  (* block3 (chunk0 lanes 96/104/112/120) and folds the prefix to              *)
  (* SUB_LIST(0,16i+16) = SUB_LIST(0,16(i+1)).                                 *)
  (*                                                                           *)
  (* eta2 SI4 step map:                                                        *)
  (*   s57 vpsrldq $0x8 xmm8 (0x157) -> XMM8, RIP s56 = pc+339                 *)
  (*       (SI3 left the vextracti128 $1 HIGH-128 of f0sub in xmm8; vpsrldq $8 *)
  (*        shifts it right 8 bytes -> gather source g4 = the >>64 (high 64) of *)
  (*        that high-128 = word_ushr(word_subword f0sub (128,128)) 64; f0sub is *)
  (*        EXPANDED on XMM8, must be RE-FOLDED like SI2/SI3 fold).            *)
  (*   s58 movzbl r8b -> r10d (shim; MOVZBL_R10_CAPTURE_TAC)                   *)
  (*   s59 vmovq (rdx,r10,8) -> YMM9 (ETA2_TAB4_TEQ_TAC)                       *)
  (*   s60 vpshufb -> YMM9 (pshuf4)                                            *)
  (*   s61 vpmovsxbd -> YMM1 (sx4)                                             *)
  (*   s62 vpmulhrsw / s63 vpmullw / s64 vpaddd — the mod-5 reduction          *)
  (*   s65 vmovdqu STORE (0x17e) to word_add res (word (4 * acc3))             *)
  (*                                                                           *)
  (* Differences vs the SI3 fold: opener is vpsrldq $8 (like SI2, NOT          *)
  (* vextracti128 $1) extracting the >>64 of the HIGH 128 of f0sub -> gather   *)
  (* source g4 has the word_ushr(...)64 shift (like SI2's g2, but off the HIGH *)
  (* half); acc2->acc3 base; block2->block3 (chunk0 lanes 96-120, `el 3` of    *)
  (* SUBITER_BLOCK_BYTES); mask8c->mask8d; prefix SUB_LIST(0,16i+12) ->        *)
  (* SUB_LIST(0,16i+16).  RAX is already folded by the SI3 counter, so SI4_PRE *)
  (* only abbrevs acc3 + reabbrevs mask8d + bounds.                            *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* SI4_PRE.  UNLIKE the SI2->SI3 boundary (where the SI2 counter pre-folds the
     RAX read), the SI3 counter leaves RAX at s56 as the RAW popcount nest
       word_zx(word_add(word_zx(word acc2))(word_zx^2(word(word_popcount(...mask8c...)))))
     and leaves pop_len3 (word_popcount(...mask8c...) = LENGTH(REJ_NIBBLES_ETA2
     (SUB_LIST(16i+8,4)))) in the asl, but NO standalone rax_red0 fact.  So we
     FIRST rewrite RAX with pop_len3 (popcount->block2len), then BUILD rax_red0 via
     RAX_NEST_REDUCE from the acc2+block2len<2^32 bound (rebuilt with SUBITER_OUTLEN_
     BOUND_3, as SI3_PRE does), then rewrite RAX -> word(acc2+block2len), THEN abbrev
     acc3.  This is the key SI4-vs-SI3 difference: SI3_PRE could skip the fold (SI2
     counter did it), SI4_PRE cannot. *)
  let ETA2_SI4_PRE_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      (* pop_len3: identify via the mask8c popcount arg (SI3's; not the SI1/SI2 leftovers). *)
      let pop_len3 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`mask8c:int64`))(concl th) | _ -> false) in
      (* rebuild acc2 + block2len <= 248 via SUBITER_OUTLEN_BOUND_3 (as SI3_PRE does),
         collapsing outlen0/acc1/acc2 defs so the bound reads over acc2. *)
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 136`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
      let bnd3 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_3) (CONJ a1 nibbnd) in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),Var("acc1",_)) -> true | _ -> false) in
      let acc2_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_)) -> true | _ -> false) in
      let bnd3a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd3 in
      let bnd3b = REWRITE_RULE[acc1_def] bnd3a in
      let bnd3c = REWRITE_RULE[acc2_def] (REWRITE_RULE[ADD_ASSOC] bnd3b) in  (* acc2 + block2len <= 248 *)
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd3c in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      RULE_ASSUM_TAC(REWRITE_RULE[pop_len3]) THEN RULE_ASSUM_TAC(REWRITE_RULE[rax_red0])) THEN
    ABBREV_TAC `acc3 = acc2 + LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (16*i+8,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8d = read R8 s56` THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 136`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=136 ==> (LENGTH(inlist:byte list)=136 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
      let bnd4 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_4) (CONJ a1 nibbnd) in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),Var("acc1",_)) -> true | _ -> false) in
      let acc2_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_)) -> true | _ -> false) in
      let acc3_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),Var("acc3",_)) -> true | _ -> false) in
      let bnd4a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd4 in
      let bnd4b = REWRITE_RULE[acc1_def] bnd4a in
      let bnd4c = REWRITE_RULE[acc2_def] (REWRITE_RULE[ADD_ASSOC] bnd4b) in
      let bnd4d = REWRITE_RULE[acc3_def] (REWRITE_RULE[ADD_ASSOC] bnd4c) in
      ASSUME_TAC bnd4d THEN
      ASSUME_TAC (MATCH_MP (ARITH_RULE `acc3 + x <= 248 ==> acc3 <= 248`) bnd4d)) THEN
    VAL_INT64_TAC `acc3:num`;;

  (* Setup + step s57..s65 (raw store, sx4 opaque).  From s56 (post-SI3-counter). *)
  let ETA2_SI4_STEP_TO_STORE_TAC : tactic =
    ETA2_SI4_PRE_TAC THEN
    ACC3_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3`]) THEN
    (* s57 vpsrldq $8 -> XMM8 (>>64 of the HIGH-128 of EXPANDED f0sub); re-fold f0sub. *)
    X86_VSTEPS_TAC EXEC (57--57) THEN
    W(fun (asl,w) ->
       let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th) = `f0sub:int256` || rand(concl th) = `f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       let f0fold = if rand(concl f0d) = `f0sub:int256` then f0d else SYM f0d in
       RULE_ASSUM_TAC(fun th -> if concl th = concl f0d then th else REWRITE_RULE[f0fold] th)) THEN
    X86_VERBOSE_STEP_TAC EXEC "s58" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s57 = mask8d:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt_4 ASSUME_TAC THENL [MASKBIT_TGT_4_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (59--59) THEN ETA2_TAB4_TEQ_TAC THEN
    REABBREV_TAC `tab4 = read YMM9 s59` THEN
    X86_VSTEPS_TAC EXEC (60--60) THEN REABBREV_TAC `pshuf4 = read YMM9 s60` THEN
    PURGE_STALE_STATES_TAC ["s59"] THEN
    X86_VSTEPS_TAC EXEC (61--61) THEN REABBREV_TAC `sx4 = read YMM1 s61` THEN
    PURGE_STALE_STATES_TAC ["s60"] THEN
    X86_VSTEPS_TAC EXEC (62--62) THEN X86_VSTEPS_TAC EXEC (63--63) THEN
    X86_VSTEPS_TAC EXEC (64--64) THEN
    PURGE_STALE_STATES_TAC ["s61";"s62";"s63"] THEN
    VAL_INT64_TAC `acc3:num` THEN
    X86_STEPS_TAC EXEC (65--65);;

  (* Refold the s65 store fact (bytes256) to `usimd8 red_lane sx4`.            *)
  let ETA2_STORE_REFOLD_4_TAC : tactic = mk_eta2_store_refold "s65" `sx4:int256`;;

  (* sx4 clean form.                                                           *)
  let ETA2_SX4_CLEAN_TAC : tactic = mk_eta2_sx_clean `sx4:int256` `pshuf4:int256`;;

  (* PERF: fold expanded f0sub in the pshuf4 def, then discharge pf_target_4.  *)
  let ETA2_ESTABLISH_PF_TARGET_4_TAC : tactic =
    mk_eta2_establish_pf_target `pshuf4:int256` pf_target_4 ETA2_PF_PROOF_4;;

  (* The full SI4 store fold: from post-SI3-counter (s56) to the folded
     running-prefix store fact ASSUMEd at s65 (prefix SUB_LIST(0,16i+16)). *)
  let ETA2_SI4_FOLD : tactic =
    ETA2_SI4_STEP_TO_STORE_TAC THEN
    ETA2_STORE_REFOLD_4_TAC THEN
    ETA2_SX4_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_4_TAC THEN
    ACC3_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      let sx4clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx4:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      let pfth = find (fun th -> concl th = pf_target_4) asms in
      (* the >>64-shifted HIGH-128 gather forall (bg4): f0sub, chunk0 lane 96, HAS word_ushr,
         has f0sub (128,128) *)
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt_4) asms in
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx4clean] storerf) in
      let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8d:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc3)):int64`; `s65:x86state`; g4; m;
                       `LENGTH(ACC_IDX (word (val (mask8d:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g4; m; `word_subword (chunk0:int128) (96,8):byte`;
          `word_subword (chunk0:int128) (104,8):byte`; `word_subword (chunk0:int128) (112,8):byte`;
          `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC in
      let specres = MP spec (CONJ mthm bg) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      (* block3 bytes (el 3), fold onto the running prefix SUB_LIST(0,16i+12) -> SUB_LIST(0,16i+16) *)
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=136 ==> 16*i+16<=136`) i116)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in    (* SUB_LIST(16i+12,4) = [lanes 96,104,112,120] *)
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (96,8):byte`;`word_subword (chunk0:int128) (104,8):byte`;
          `word_subword (chunk0:int128) (112,8):byte`;`word_subword (chunk0:int128) (120,8):byte`] LEN_RECONCILE_GEN) mthm in
      let lr = REWRITE_RULE[GSYM blk3_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk3_eq] rej_store in
      let acc3_ident = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc3",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s65",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc3:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc3_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc3_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s65:x86state`;m;`SUB_LIST(16*i+12,4) (inlist:byte list)`;`SUB_LIST(0,16*i+12) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+12`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+12)+4 = 16*i+16`] fold in
      ASSUME_TAC clean);;

  (* ========================================================================= *)
  (* eta2 CORRECT: SI4 counter + finals.                                       *)
  (*                                                                           *)
  (* The LAST piece of the CLEAN_BODY body port.  Runs AFTER ETA2_SI4_FOLD,    *)
  (* which leaves s65 (store folded to SUB_LIST(0,16i+16) = SUB_LIST(0,16(i+1))), *)
  (* RAX s65 = word acc3, R8 s65 = mask8d).                                    *)
  (*                                                                           *)
  (* Control flow:                                                             *)
  (*   s66 popcnt %r10d,%r9d (0x183) ; s67 add %r9d,%eax (0x188) ;             *)
  (*   s68 add $0x4,%ecx (0x18b) ; s69 jmp 5a (0x18e, UNCONDITIONAL to loop top *)
  (*   pc+86).  The SI4 counter is SIMPLER than SI1-3: only 4 steps, NO shr, NO *)
  (*   cmp, NO conditional ja/mid-guard (SI4 is the last sub-iter — it always  *)
  (*   loops back).  So the jmp lands RIP directly at pc+86; no COND to resolve. *)
  (*                                                                           *)
  (* We step s66-69 straight through, leaving RAX as the raw popcount nest     *)
  (*   word_zx(word_add(word_zx(word acc3))(word_zx^2(word(word_popcount(...))))) *)
  (* and RCX = word_zx(word_add(word_zx(word(16*i+12)))(word_zx(word 4))).  The *)
  (* RAX/RCX collapse to the CLEAN_BODY postcondition forms is deferred to     *)
  (* ETA2_RAX_FINAL_TAC / ETA2_RCX_FINAL_TAC (which run after                  *)
  (* ENSURES_FINAL_STATE_TAC).                                                 *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* SI4 counter: step s66-69 (popcnt/add/add/jmp).  jmp is unconditional so RIP
     lands at pc+86 (loop top) directly.  Leaves RAX/RCX as raw stepper nests for
     the finals to collapse. *)
  let ETA2_SI4_COUNTER_TAC : tactic =
    X86_STEPS_TAC EXEC (66--69);;

  (* ACC_FULL_LEN: the 5-term niblen sum (prefix + 4 sub-iter blocks) telescopes *)
  (* to niblen(16*(i+1)).                                                      *)
  let ACC_FULL_LEN = prove
   (`!inlist:byte list. !i:num. 16*i+16 <= LENGTH inlist ==>
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*i) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i+4,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i+8,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(16*i+12,4) inlist):int16 list) =
       LENGTH(REJ_NIBBLES_ETA2(SUB_LIST(0,16*(i+1)) inlist):int16 list)`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[ARITH_RULE `16*(i+1) = 16*i+16`] THEN
    ONCE_REWRITE_TAC[ISPECL[`inlist:byte list`;`16*i`;`16`;`0`] SUB_LIST_SPLIT] THEN
    REWRITE_TAC[ADD_CLAUSES] THEN
    REWRITE_TAC[SL16_4WAY] THEN
    REWRITE_TAC[REJ_NIBBLES_ETA2_APPEND; LENGTH_APPEND] THEN ARITH_TAC);;

  (* ETA2_RAX_FINAL_TAC: discharge the RAX final-state subgoal (goal 0):
     word_zx(word_add(word_zx(word acc3))(word_zx^2(word(word_popcount(mask8d-arg))))) =
       word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16(i+1))))). *)
  let ETA2_RAX_FINAL_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let m8d_val = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),_),r) -> r = `mask8d:int64` &&
            can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))(concl th) | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      (* popcnt4: fold SUM->mask8b->mask8c (forward), then mask8c-ushr-form -> mask8d via m8d_val *)
      let popcnt4 = REWRITE_RULE[m8d_val] (REWRITE_RULE[m8b_def; m8c_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE3))) in
      let lanesum = rand(concl popcnt4) in
      (* lanes-24..31 maskbit                                                  *)
      let mb4 = find_a (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`24` | _ -> false))c) in
      let mb4_tm = concl mb4 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in   (* SUB_LIST(16*i+12,4) = [chunk0 96,104,112,120] *)
      let block3 = `[word_subword (chunk0:int128) (96,8); word_subword chunk0 (104,8);
                     word_subword chunk0 (112,8); word_subword chunk0 (120,8)]:byte list` in
      let block3len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block3)) in
      let bsum4_raw = prove(mk_imp(mb4_tm, mk_eq(lanesum, block3len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len4 = REWRITE_RULE[GSYM blk3_eq] (TRANS popcnt4 (MP bsum4_raw mb4)) in
      (* bound acc3 + block3len < 2^32                                         *)
      let bnd4d = find_a (fun th -> match concl th with
         Comb(Comb(Const("<=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),_) -> true | _ -> false) in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd4d in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      (* rewrite goal: popcnt -> block3len, then rax_red0 -> word(acc3+block3len) *)
      REWRITE_TAC[pop_len4] THEN REWRITE_TAC[rax_red0]) THEN
    (* now goal: word(acc3 + block3len) = word(LENGTH(REJ_SAMPLE(SUB_LIST(0,16(i+1))))) *)
    AP_TERM_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let outlen0_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
      let acc1_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),Var("acc1",_)) -> true | _ -> false) in
      let acc2_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_)) -> true | _ -> false) in
      let acc3_def = find_a (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),Var("acc3",_)) -> true | _ -> false) in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let af = MP (ISPECL [`inlist:byte list`; `i:num`] ACC_FULL_LEN)
                  (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) in
      REWRITE_TAC[SYM acc3_def; SYM acc2_def; SYM acc1_def] THEN
      REWRITE_TAC[SYM outlen0_def] THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
      MP_TAC af THEN ARITH_TAC);;

  (* RCX final helpers.                                                        *)
  let ETA2_RCX_FINAL_TAC : tactic =
    SUBGOAL_THEN `16 * (i + 1) = 16 * i + 4 + 4 + 4 + 4` SUBST1_TAC THENL
     [ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[GSYM VAL_EQ] THEN
    REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_ADD; VAL_WORD; DIMINDEX_32; DIMINDEX_64] THEN
    REWRITE_TAC[MM64_32] THEN CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
    REWRITE_TAC[MM_4G_4G; MM_4G_18] THEN
    SUBGOAL_THEN `16 * i < 4294967296 /\ 16*i+4 < 4294967296 /\ 16*i+4+4 < 4294967296 /\
                  16*i+4+4+4 < 4294967296 /\ 16*i+16 < 18446744073709551616 /\
                  (16*i+4)+4 < 4294967296 /\ ((16*i+4)+4)+4 < 4294967296 /\ (((16*i+4)+4)+4)+4 < 4294967296`
      STRIP_ASSUME_TAC THENL
     [REPEAT CONJ_TAC THEN UNDISCH_TAC `16 * (i + 1) <= 136` THEN ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[MOD_LT] THEN ARITH_TAC;;

  (* ========================================================================= *)
  (* eta2 CORRECT: CLEAN_BLOCK.                                                *)
  (*                                                                           *)
  (* The SIMD 16-byte block body pc+86 -> pc+86, WITHOUT the `~(N=0)` and      *)
  (* `i+1<N` hyps of clean_body_eta2_tm (the gather tactics never use them), and *)
  (* with the relaxed bound `16*(i+1)<=136` (so it covers BOTH interior clean  *)
  (* blocks AND the exit block at i=N-1 where 16*N=136).  Proved by the SAME   *)
  (* ETA2_CLEAN_BODY_FULL_TAC.                                                 *)
  (*                                                                           *)
  (* This is the asset for the exit-block OFFSET arm: CLEAN_BLOCK @ i=N-1 takes *)
  (* pc+86/pos=16(N-1) -> pc+86/pos=16N, then the head guard fires and control *)
  (* drops to the scalar tail, handled by SCALAR_TAIL_AT_P@136.                *)
  (* ========================================================================= *)

  let clean_block_eta2_tm =
    let hs = conjuncts(fst(dest_imp(snd(strip_forall clean_body_eta2_tm)))) in
    let hs' = filter (fun h -> h <> `~(N = 0)` && h <> `i + 1 < N`) hs in
    list_mk_forall(fst(strip_forall clean_body_eta2_tm),
      mk_imp(list_mk_conj hs', snd(dest_imp(snd(strip_forall clean_body_eta2_tm)))));;

  (* ========================================================================= *)
  (* eta2 CORRECT: scalar-tail spec/algebra lemmas.                            *)
  (*                                                                           *)
  (* The pure spec-level per-byte step lemmas that drive the byte-at-a-time    *)
  (* scalar tail loop at pc+399 (0x193).  Each scalar iteration consumes 1     *)
  (* input byte = 2 nibbles (low then high), accepting each if < 15, matching  *)
  (* REJ_SAMPLE_ETA2_BYTES.  The eta2 coefficient is                           *)
  (*   word_sx(word_sub (word 2:int16) (word_umod (word n) (word 5:int16))).   *)
  (* ========================================================================= *)

  (* ------------------------------------------------------------------------- *)
  (* Per-byte spec: REJ_SAMPLE_ETA2_BYTES [b] as an APPEND of the two          *)
  (* nibble contributions.                                                     *)
  (* ------------------------------------------------------------------------- *)
  let REJ_SAMPLE_ETA2_BYTES_1 = prove
   (`!b:byte.
       REJ_SAMPLE_ETA2_BYTES [b] =
       APPEND
        (if val b MOD 16 < 15
         then [word_sx(word_sub (word 2:int16)
                                (word_umod (word(val b MOD 16)) (word 5:int16))):int32]
         else [])
        (if val b DIV 16 < 15
         then [word_sx(word_sub (word 2:int16)
                                (word_umod (word(val b DIV 16)) (word 5:int16))):int32]
         else [])`,
    GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; REJ_NIBBLES_ETA2;
                NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; FILTER; MAP] THEN
    REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    SUBGOAL_THEN
     `val(b:byte) MOD 16 MOD 65536 = val b MOD 16 /\
      val(b:byte) DIV 16 MOD 65536 = val b DIV 16`
     (fun th -> REWRITE_TAC[th]) THENL
     [MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
      STRIP_TAC THEN CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC;
      ALL_TAC] THEN
    COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP; APPEND] THEN
    COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP; APPEND]);;

  (* ------------------------------------------------------------------------- *)
  (* Per-byte length.                                                          *)
  (* ------------------------------------------------------------------------- *)
  let LENGTH_REJ_SAMPLE_ETA2_BYTES_1 = prove
   (`!b:byte. LENGTH(REJ_SAMPLE_ETA2_BYTES [b] :int32 list) =
              (if val b MOD 16 < 15 then 1 else 0) +
              (if val b DIV 16 < 15 then 1 else 0)`,
    GEN_TAC THEN REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_1; LENGTH_APPEND] THEN
    COND_CASES_TAC THEN COND_CASES_TAC THEN REWRITE_TAC[LENGTH] THEN ARITH_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* Per-byte case lemmas (one per acceptance combination).                    *)
  (* ------------------------------------------------------------------------- *)
  let REJ_SAMPLE_ETA2_BYTES_1_REJECT_BOTH = prove
   (`!b:byte. ~(val b MOD 16 < 15) /\ ~(val b DIV 16 < 15)
              ==> REJ_SAMPLE_ETA2_BYTES [b] = []`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA2_BYTES_1_LOW_ONLY = prove
   (`!b:byte. val b MOD 16 < 15 /\ ~(val b DIV 16 < 15)
              ==> REJ_SAMPLE_ETA2_BYTES [b] =
                  [word_sx(word_sub (word 2:int16)
                                    (word_umod (word(val b MOD 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA2_BYTES_1_HIGH_ONLY = prove
   (`!b:byte. ~(val b MOD 16 < 15) /\ val b DIV 16 < 15
              ==> REJ_SAMPLE_ETA2_BYTES [b] =
                  [word_sx(word_sub (word 2:int16)
                                    (word_umod (word(val b DIV 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA2_BYTES_1_BOTH = prove
   (`!b:byte. val b MOD 16 < 15 /\ val b DIV 16 < 15
              ==> REJ_SAMPLE_ETA2_BYTES [b] =
                  [word_sx(word_sub (word 2:int16)
                                    (word_umod (word(val b MOD 16)) (word 5:int16))):int32;
                   word_sx(word_sub (word 2:int16)
                                    (word_umod (word(val b DIV 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_1; APPEND]);;

  (* ------------------------------------------------------------------------- *)
  (* SUB_LIST prefix-extension step (arch-generic).                            *)
  (* ------------------------------------------------------------------------- *)
  let SUB_LIST_STEP_BYTE_ETA2 = prove
   (`!(l:byte list) (k:num).
       k < LENGTH l
       ==> SUB_LIST(0, k+1) l = APPEND (SUB_LIST(0, k) l) [EL k l]`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`l:byte list`; `k:num`; `1`; `0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ARITH_RULE `0 + k = k`] THEN DISCH_THEN SUBST1_TAC THEN
    AP_TERM_TAC THEN ASM_REWRITE_TAC[SUB_LIST_1]);;

  (* REJ prefix step: REJ(SUB(0,k+1)) = APPEND (REJ(SUB(0,k))) (REJ [EL k]).   *)
  let REJ_SAMPLE_ETA2_BYTES_STEP_1 = prove
   (`!(l:byte list) (k:num).
       k < LENGTH l
       ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, k+1) l) =
           APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, k) l))
                  (REJ_SAMPLE_ETA2_BYTES [EL k l])`,
    REPEAT STRIP_TAC THEN
    ASM_SIMP_TAC[SUB_LIST_STEP_BYTE_ETA2; REJ_SAMPLE_ETA2_BYTES_APPEND]);;

  let LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1 = prove
   (`!(inlist:byte list) k.
       k < LENGTH inlist
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, k+1) inlist):int32 list) =
           LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, k) inlist):int32 list) +
           (if val(EL k inlist) MOD 16 < 15 then 1 else 0) +
           (if val(EL k inlist) DIV 16 < 15 then 1 else 0)`,
    REPEAT STRIP_TAC THEN
    ASM_SIMP_TAC[REJ_SAMPLE_ETA2_BYTES_STEP_1; LENGTH_APPEND;
                 LENGTH_REJ_SAMPLE_ETA2_BYTES_1] THEN ARITH_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* Per-byte length step lemmas (drive the RAX update; grow by 0/1/2).        *)
  (* ------------------------------------------------------------------------- *)
  let LEN_STEP_BOTH_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 15 /\ val(EL p inlist) DIV 16 < 15
     ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) + 2`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_LO_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 15 /\ ~(val(EL p inlist) DIV 16 < 15)
     ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) + 1`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_HI_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 15) /\ val(EL p inlist) DIV 16 < 15
     ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) + 1`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_NONE_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 15) /\ ~(val(EL p inlist) DIV 16 < 15)
     ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* Per-byte output-list APPEND step (drive the memory fold).                 *)
  (* ------------------------------------------------------------------------- *)
  let REJ_STEP_BOTH_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 15 /\ val(EL p inlist) DIV 16 < 15
     ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p inlist) MOD 16)) (word 5:int16))):int32;
                 word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p inlist) DIV 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA2_BYTES_1_BOTH THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_LO_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 15 /\ ~(val(EL p inlist) DIV 16 < 15)
     ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p inlist) MOD 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA2_BYTES_1_LOW_ONLY THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_HI_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 15) /\ val(EL p inlist) DIV 16 < 15
     ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 2:int16) (word_umod (word(val(EL p inlist) DIV 16)) (word 5:int16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA2_BYTES_1_HIGH_ONLY THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_NONE_ETA2 = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 15) /\ ~(val(EL p inlist) DIV 16 < 15)
     ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist) = REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA2_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN `REJ_SAMPLE_ETA2_BYTES [EL p (inlist:byte list)] = []` SUBST1_TAC THENL
     [MATCH_MP_TAC REJ_SAMPLE_ETA2_BYTES_1_REJECT_BOTH THEN ASM_REWRITE_TAC[]; REWRITE_TAC[APPEND_NIL]]);;

  (* ------------------------------------------------------------------------- *)
  (* num_of_wordlist for a singleton int32.                                    *)
  (* ------------------------------------------------------------------------- *)
  let JAE_NOT_TAKEN_LT_ETA2 = prove
   (`!a k:num. a < k /\ k < 2 EXP 32
       ==> ~(&(val(word_zx(word a:int64):int32)):int - &k =
             &(val(word_sub(word_zx(word a:int64):int32) (word k):int32)))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `val(word_zx(word a:int64):int32) = a` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `val(word_sub (word_zx(word a:int64):int32) (word k:int32)) = a + 2 EXP 32 - k` ASSUME_TAC THENL
     [REWRITE_TAC[VAL_WORD_SUB_CASES; DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN
      SUBGOAL_THEN `val(word k:int32) = k` SUBST1_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_32] THEN ASM_ARITH_TAC; ALL_TAC] THEN
      COND_CASES_TAC THENL [REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC; REFL_TAC];
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `a + 2 EXP 32 - k = (a + 2 EXP 32) - k /\ k <= a + 2 EXP 32` STRIP_ASSUME_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `&((a + 2 EXP 32) - k):int = &(a + 2 EXP 32) - &k` SUBST1_TAC THENL
     [MATCH_MP_TAC(GSYM INT_OF_NUM_SUB) THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    MP_TAC(ARITH_RULE `0 < 2 EXP 32`) THEN
    REWRITE_TAC[GSYM INT_OF_NUM_LT; GSYM INT_OF_NUM_ADD] THEN INT_ARITH_TAC);;

  let JAE_TAKEN_GE_ETA2 = prove
   (`!a k:num. k <= a /\ a < 2 EXP 32
       ==> (&(val(word_zx(word a:int64):int32)):int - &k =
            &(val(word_sub(word_zx(word a:int64):int32) (word k):int32)))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `val(word_zx(word a:int64):int32) = a` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `val(word_sub (word_zx(word a:int64):int32) (word k:int32)) = a - k` ASSUME_TAC THENL
     [REWRITE_TAC[VAL_WORD_SUB_CASES; DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN
      SUBGOAL_THEN `val(word k:int32) = k` SUBST1_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_32] THEN ASM_ARITH_TAC; ALL_TAC] THEN
      COND_CASES_TAC THENL [REFL_TAC; REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC];
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `&(a - k):int = &a - &k` SUBST1_TAC THENL
     [MATCH_MP_TAC(GSYM INT_OF_NUM_SUB) THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    REFL_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* READ_1BYTE_EL (arch-generic).                                             *)
  (* Read one input byte at offset p from the buffer's num_of_wordlist contract. *)
  (* ------------------------------------------------------------------------- *)
  let READ_1BYTE_EL_ETA2 = prove
   (`!(inlist:byte list) (buf:int64) (s:x86state) p n.
       LENGTH inlist = n /\ p < n /\
       read(memory :> bytes(buf, n)) s = num_of_wordlist inlist
       ==> read(memory :> bytes8 (word_add buf (word p))) s = EL p inlist`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`inlist:byte list`; `p:num`] EL_NUM_OF_WORDLIST) THEN
    ASM_REWRITE_TAC[DIMINDEX_8] THEN DISCH_THEN SUBST1_TAC THEN
    REWRITE_TAC[bytes8; READ_COMPONENT_COMPOSE; asword; through; read] THEN
    SUBGOAL_THEN
     `read (bytes (word_add buf (word p),1)) (read memory s) =
      read (bytes (buf,n)) (read memory s) DIV 2 EXP (8 * p) MOD 256`
     SUBST1_TAC THENL
     [REWRITE_TAC[READ_BYTES_DIV] THEN
      MP_TAC(ISPECL [`word_add buf (word p):int64`; `n - p`; `1`; `read memory s:int64->byte`] READ_BYTES_MOD) THEN
      SUBGOAL_THEN `MIN (n - p) 1 = 1` SUBST1_TAC THENL
       [REWRITE_TAC[ARITH_RULE `MIN a 1 = 1 <=> 1 <= a`] THEN ASM_ARITH_TAC; ALL_TAC] THEN
      CONV_TAC NUM_REDUCE_CONV THEN DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC;
      ALL_TAC] THEN
    UNDISCH_TAC `read (memory :> bytes (buf,n)) s = num_of_wordlist (inlist:byte list)` THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE] THEN DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN `(256:num) = 2 EXP dimindex(:8)` SUBST1_TAC THENL
     [REWRITE_TAC[DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
    REWRITE_TAC[WORD_MOD_SIZE]);;

  (* ------------------------------------------------------------------------- *)
  (* RAX_INC (arch-generic).                                                   *)
  (* ------------------------------------------------------------------------- *)
  let RAX_INC_ETA2 = prove
   (`!L. L < 256 ==> word_zx(word_add (word_zx (word L:int64):int32) (word 1:int32)):int64 = word(L+1)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(word_zx(word L:int64):int32) = L` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[GSYM VAL_EQ] THEN
    SUBGOAL_THEN `val(word_zx(word_add (word_zx (word L:int64):int32) (word 1:int32)):int64) = L+1` SUBST1_TAC THENL
     [SUBGOAL_THEN `val(word_add (word_zx (word L:int64):int32) (word 1:int32)) = L + 1` ASSUME_TAC THENL
       [REWRITE_TAC[VAL_WORD_ADD; DIMINDEX_32] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN
        CONV_TAC NUM_REDUCE_CONV THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC EQ_TRANS THEN EXISTS_TAC `val(word_add (word_zx (word L:int64):int32) (word 1:int32))` THEN
      CONJ_TAC THENL [MATCH_MP_TAC VAL_WORD_ZX THEN REWRITE_TAC[DIMINDEX_32;DIMINDEX_64] THEN ARITH_TAC; ASM_REWRITE_TAC[]];
      REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC]);;

  (* ========================================================================= *)
  (* eta2 CORRECT: scalar-tail store-value bridge.                             *)
  (*                                                                           *)
  (* The eta2 scalar tail store value is the scalar Barrett mod-5 reduction    *)
  (* 2-(n MOD5).  After                                                        *)
  (*   mov r10d,r11d; imul 0xcd(=205),r11d; shr 0xa,r11d; imul 5,r11d;         *)
  (*   sub r11d,r10d; mov 2,r11d; sub r10d,r11d; mov r11d,(rdi,rax,4)          *)
  (* the model stores at res+4*outlen0 the int32 (n = nibble val b MOD/DIV 16): *)
  (*   word_zx(word_zx(word_sub (word 2)                                       *)
  (*     (word_zx(word_zx(word_sub (word_zx(word n))                           *)
  (*       (word_zx(word_zx(word_mul (word_zx(word_zx(word_ushr                *)
  (*         (word_zx(word_zx(word_mul (word_zx(word_zx(word_zx(word n))))     *)
  (*           (word 205)))) 10))) (word 5)))))))))                            *)
  (* and this = word_sx(word_sub (word 2:int16) (word_umod (word n) (word 5))) *)
  (* :int32 for n < 15.                                                        *)
  (*                                                                           *)
  (* NOTE: stating this equality as a STANDALONE n-parametrized lemma is fragile *)
  (* — the deeply-nested word_zx tower's intermediate widths are simulator-    *)
  (* determined and a hand-written term triggers "inventing type variables"    *)
  (* (a polymorphic word) that WORD_REDUCE cannot reduce.  The reliable route is *)
  (* to apply the reduction as an IN-BODY SUBGOAL_THEN whose LHS is COPIED from *)
  (* the store hypothesis at that point (fully typed by the read-context),     *)
  (* closed by                                                                 *)
  (*   SUBGOAL_THEN `n=0 \/ ... \/ n=14` MP_TAC + ASM_ARITH_TAC,               *)
  (*   then STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_REDUCE_CONV.   *)
  (* SCALAR_STORE_REDUCE_TAC below packages that.                              *)
  (* ========================================================================= *)

  (* Scalar Barrett core: n - 5*((205*n) DIV 1024) = n MOD 5 for n < 15.

     Underpins the store-value reduction; a standalone numeric identity, robust. *)

  (* In-body store-value reducer: given a goal/hyp mentioning the (typed) store
     term for nibble value `nib`, prove the store-value = spec coefficient by
     15-way enumeration + WORD_REDUCE.  `nib` is the num term (val b MOD 16 or
     val b DIV 16); `lt15` is the accept hypothesis `nib < 15` in the assumptions.
     Usage in the body: MP_TAC the store hyp, then
       SCALAR_STORE_REDUCE_TAC `val(EL p inlist) MOD 16`
     after asserting the equality as a SUBGOAL_THEN copied from the store term. *)
  let SCALAR_STORE_REDUCE_TAC nib : tactic =
    SUBGOAL_THEN (subst [nib,`nn:num`]
       `nn = 0 \/ nn = 1 \/ nn = 2 \/ nn = 3 \/ nn = 4 \/ nn = 5 \/ nn = 6 \/ nn = 7 \/
        nn = 8 \/ nn = 9 \/ nn = 10 \/ nn = 11 \/ nn = 12 \/ nn = 13 \/ nn = 14`)
      MP_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_REDUCE_CONV;;

  (* ========================================================================= *)
  (* eta2 CORRECT: SCALAR_TAIL_BODY (per-byte scalar-tail trip).               *)
  (*                                                                           *)
  (* One trip pc+399 -> pc+399 consuming input byte at position p, extending   *)
  (* the output list by REJ_SAMPLE_ETA2_BYTES [EL p inlist].  Entry            *)
  (* generalized to arbitrary p.  The ~(L=255 /\ low<15) hyp rules out the     *)
  (* mid-byte exit (handled by the RUN wrapper's mid-exit case, not this body). *)
  (*                                                                           *)
  (* eta2 specifics: entry pc+399, buf 136, accept <15, store value Barrett    *)
  (* 2-(n MOD5) (SCALAR_STORE_REDUCE_TAC).  The HIGH-nibble block (raw 0x1e5)  *)
  (* RELOADS the input byte from -1(rsi,rcx) (rcx = p+1) because the low Barrett *)
  (* clobbers r11d, so the high path needs a fresh READ_1BYTE_EL_ETA2 fact + a *)
  (* WORD_RULE address rewrite before its movzbl step.  The high block is SHARED *)
  (* by low-accept-fallthrough and low-reject (jae 0x1e5), so cases are        *)
  (* structured (low<15?) x (high<15?).                                        *)
  (*                                                                           *)
  (* Step map:                                                                 *)
  (*   SETUP: 1--8  -> s8 R10=low nibble, RIP=pc+432 (raw 0x1b4 cmp)           *)
  (*   s9 cmp 0xf,r10d ; s10 jae 0x1e5(high)                                   *)
  (*   low-accept (jae not taken): s11 mov ; s12 imul 0xcd ; s13 shr 0xa ;     *)
  (*     s14 imul 5 ; s15 sub ; s16 mov 2 ; s17 sub ; s18 store(res+4*outlen0) ; *)
  (*     s19 inc eax ; s20 cmp 0x100 ; s21 jae 0x222(done)                     *)
  (*   HIGH block (raw 0x1e5): reload movzbl -1(rsi,rcx) ; shr 4 ; and 0xf ;   *)
  (*     cmp 0xf ; jae 0x193(loop top=pc+399) ; then high Barrett + store + inc + *)
  (*     jmp 0x193(pc+399).                                                    *)
  (*                                                                           *)
  (* Requires type_invention_error := true.                                    *)
  (* ========================================================================= *)

  let EXEC_ETA2 = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* ------------------------------------------------------------------------- *)
  (* Low-nibble bridge: r10d after `mov r11d,r10d; and 0xf,r10d` collapses to  *)
  (* word(val b MOD 16).                                                       *)
  (* ------------------------------------------------------------------------- *)
  let R10_NIBBLE_VAL_ETA2 = prove
   (`!b:byte. word_zx(word_and (word_zx (word_zx (word_zx (word_zx (word_zx b:int32):int64):int32):int64):int32) (word 15:int32)):int64 = word(val b MOD 16)`,
    GEN_TAC THEN REWRITE_TAC[GSYM VAL_EQ] THEN
    SUBGOAL_THEN `(word 15:int32) = word(2 EXP 4 - 1)` SUBST1_TAC THENL
     [CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
    SIMP_TAC[VAL_WORD_ZX_GEN; VAL_WORD_AND_MASK_WORD; DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64;
             VAL_WORD; ARITH] THEN
    MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN STRIP_TAC THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    SUBGOAL_THEN `val(b:byte) MOD 4294967296 = val b /\ val(b:byte) MOD 18446744073709551616 = val b`
      STRIP_ASSUME_TAC THENL [CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `val(b:byte) MOD 16 < 18446744073709551616` ASSUME_TAC THENL
     [MP_TAC(SPECL[`val(b:byte)`;`16`] MOD_LT_EQ) THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[MOD_LT] THEN CONV_TAC NUM_REDUCE_CONV);;

  (* High-nibble bridge: r11d after `movzbl(reload); shr 4; and 0xf` collapses to *)
  (* word(val b DIV 16) (reload gives the byte through the movzbl zx tower, then *)
  (* ushr 4, then and 15).                                                     *)
  let R11_NIBBLE_VAL_ETA2 = prove
   (`!b:byte. word_zx (word_and (word_zx (word_zx (word_ushr (word_zx (word_zx (word_zx (b:byte) :int32) :int64) :int32) 4) :int64) :int32) (word 15 :int32)) :int64 = word (val b DIV 16)`,
    GEN_TAC THEN REWRITE_TAC[GSYM VAL_EQ] THEN
    SUBGOAL_THEN `(word 15:int32) = word(2 EXP 4 - 1)` SUBST1_TAC THENL
     [CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
    SIMP_TAC[VAL_WORD_ZX_GEN; VAL_WORD_AND_MASK_WORD; VAL_WORD_USHR; DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64;
             VAL_WORD; ARITH] THEN
    MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN STRIP_TAC THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    SUBGOAL_THEN `val(b:byte) MOD 4294967296 = val b /\ val(b:byte) MOD 18446744073709551616 = val b /\ (val(b:byte) DIV 16) MOD 18446744073709551616 = val b DIV 16 /\ (val(b:byte) DIV 16) MOD 4294967296 = val b DIV 16 /\ (val(b:byte) DIV 16) MOD 16 = val b DIV 16`
      STRIP_ASSUME_TAC THENL
     [REPEAT CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN MP_TAC(SPECL[`val(b:byte)`;`16`] DIV_LT) THEN ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[]);;

  (* Common RCX closer: word_zx(word_add(word_zx(word p))(word 1)):int64 = word(p+1) for p<136. *)
  let RCX_INC_TAC =
    REWRITE_TAC[GSYM VAL_EQ] THEN
    SUBGOAL_THEN `val(word_zx(word p:int64):int32) = p` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN MP_TAC(ASSUME `p<136`) THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `val(word_zx(word_add (word_zx (word p:int64):int32) (word 1:int32)):int64) = p+1` SUBST1_TAC THENL
     [SUBGOAL_THEN `val(word_add (word_zx (word p:int64):int32) (word 1:int32)) = p + 1` ASSUME_TAC THENL
       [REWRITE_TAC[VAL_WORD_ADD; DIMINDEX_32] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN
        CONV_TAC NUM_REDUCE_CONV THEN MATCH_MP_TAC MOD_LT THEN MP_TAC(ASSUME `p<136`) THEN ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC EQ_TRANS THEN EXISTS_TAC `val(word_add (word_zx (word p:int64):int32) (word 1:int32))` THEN
      CONJ_TAC THENL [MATCH_MP_TAC VAL_WORD_ZX THEN REWRITE_TAC[DIMINDEX_32;DIMINDEX_64] THEN ARITH_TAC; ASM_REWRITE_TAC[]];
      REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
      MP_TAC(ASSUME `p<136`) THEN ARITH_TAC];;

  (* prove read(bytes(addr,4)) sN = val(word_sx ...) from a spec-form bytes32 store hyp. *)
  let SCALAR_BODY_SETUP_ETA2 =
    REPEAT GEN_TAC THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    MP_TAC(ISPECL [`inlist:byte list`; `buf:int64`; `s0:x86state`; `p:num`; `136`] READ_1BYTE_EL_ETA2) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    ABBREV_TAC `outlen0 = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)` THEN
    FIRST_X_ASSUM(fun th -> if concl th = `L:num = outlen0` then SUBST_ALL_TAC th else NO_TAC) THEN
    SUBGOAL_THEN `~(&(val(word_zx(word outlen0:int64):int32)):int - &256 = &(val(word_sub(word_zx(word outlen0:int64):int32) (word 256):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `~(&(val(word_zx(word p:int64):int32)):int - &136 = &(val(word_sub(word_zx(word p:int64):int32) (word 136):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT_ETA2 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC_ETA2 (1--8) THEN
    SUBGOAL_THEN `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64` ASSUME_TAC THENL
     [AP_TERM_TAC THEN AP_TERM_TAC THEN REWRITE_TAC[MULT_CLAUSES] THEN
      MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `p < 136`) THEN ARITH_TAC; ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64`;
                                ASSUME `read (memory :> bytes8 (word_add buf (word p))) s4 = EL p (inlist:byte list)`;
                                R10_NIBBLE_VAL_ETA2]) THEN
    DISCARD_OLDSTATE_TAC "s8";;

  (* ------------------------------------------------------------------------- *)
  (* RELOAD_PREP_ETA2 sN : establish the high-nibble reload byte fact + address. *)
  (* At state sN (RCX = word_zx(word_add(word_zx(word p))(word 1))), before the *)
  (* movzbl -1(rsi,rcx), prove read RCX sN = word(p+1), the reload READ_1BYTE  *)
  (* fact, and the address equality word_add buf (word(1*val(word(p+1))+0xF..F)) *)
  (* = word_add buf (word p).  (Fold happens after the movzbl step.)           *)
  (* ------------------------------------------------------------------------- *)
  let RELOAD_PREP_ETA2 sN : tactic =
    (* Collapse the (unique) read RCX sN = word_zx(word_add(word_zx(word p))(word 1))
       assumption to = word(p+1) IN PLACE via RAX_INC_ETA2.  This leaves exactly one
       RCX assumption (canonical word(p+1) form) — the stepper needs one unambiguous
       RCX value to evaluate the movzbl -1(rsi,rcx) address, and a duplicate (both
       inc-form and word(p+1)) makes its lookup `tryfind` fail. *)
    RULE_ASSUM_TAC(REWRITE_RULE[MATCH_MP RAX_INC_ETA2
       (MATCH_MP (ARITH_RULE `p<136 ==> p<256`) (ASSUME `p<136`))]) THEN
    MP_TAC(ISPECL [`inlist:byte list`; `buf:int64`; sN; `p:num`; `136`] READ_1BYTE_EL_ETA2) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
    SUBGOAL_THEN `word_add buf (word(1 * val(word(p+1):int64) + 18446744073709551615)):int64 = word_add buf (word p)` ASSUME_TAC THENL
     [AP_TERM_TAC THEN
      SUBGOAL_THEN `val(word(p+1):int64) = p+1` SUBST1_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `p<136`) THEN ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[ARITH_RULE `1 * (p+1) + 18446744073709551615 = p + 2 EXP 64`] THEN
      REWRITE_TAC[WORD_ADD] THEN
      SUBGOAL_THEN `word(2 EXP 64):int64 = word 0` SUBST1_TAC THENL
       [REWRITE_TAC[GSYM VAL_EQ; VAL_WORD; DIMINDEX_64] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
      CONV_TAC WORD_RULE; ALL_TAC];;

  (* ------------------------------------------------------------------------- *)
  (* NB: the ACCEPT-* paths step a low store to res+4*outlen0 (s18), THEN the  *)
  (* high-nibble reload movzbl -1(rsi,rcx) at s22.  The stepper's read-over-write *)
  (* resolution for read(buf+p) THROUGH the store to res+4*outlen0 needs the   *)
  (* store-frame nonoverlap discharged before the movzbl.  RELOAD_PREP_ETA2 is *)
  (* the reload-address helper; the LOW-REJECT path (reload with NO prior store) *)
  (* uses it directly.                                                         *)
  (* ------------------------------------------------------------------------- *)

  (* ========================================================================= *)
  (* eta2 CORRECT: SCALAR_TAIL_BODY (the per-byte scalar trip).                *)
  (*                                                                           *)
  (* One trip pc+399 -> pc+399 consuming input byte at position p, extending   *)
  (* the output list by REJ_SAMPLE_ETA2_BYTES [EL p inlist].  Entry pc+399 ;   *)
  (* buf 136 ; accept <15 ; store 2-(n MOD5) via Barrett.                      *)
  (*                                                                           *)
  (* KEY STRUCTURAL NOTES:                                                     *)
  (*  (1) eta2's HIGH-nibble block RELOADS the byte from -1(rsi,rcx) (raw 0x1e5) *)
  (*      via RELOAD_PREP_ETA2 (the low Barrett clobbers r11d).                *)
  (*  (2) STEP-MAP ORDER: store(s18) -> inc eax(s19) -> cmp(s20) -> jae(s21) -> *)
  (*      movzbl(s22).  RAX MUST be folded to word(outlen0+1) at s19 so the s21 *)
  (*      jae resolves to a concrete RIP; else the s22 movzbl DECODE fails     *)
  (*      `tryfind`.                                                           *)
  (*  (3) HIGH store (s34 accept-accept / s23 hi-only) has RAX = word(outlen0+1) *)
  (*      resp word(outlen0): establish val(word ..)=.. BEFORE the store step so *)
  (*      the stepper proves the store addr non-code-overlapping.              *)
  (*  (4) Store value is the deep Barrett word_zx tower; bridge it to spec form *)
  (*      via ETA2_STORE_SPEC_TAC (clean-subgoal SCALAR_STORE_REDUCE_TAC) — the *)
  (*      tower is simulator-typed so no standalone lemma (memory lesson).     *)
  (*                                                                           *)
  (* Full step maps (objdump mldsa_rej_uniform_eta2_avx2_asm.o, tmc offsets=raw-4):  *)
  (*   SETUP 1-8 -> s8 RIP pc+432 (0x1b4 cmp), R10 = low nibble.               *)
  (*   s9 cmp 0xf,r10d ; s10 jae 0x1e5 (high).                                 *)
  (*   ACCEPT-LOW (s10 not taken): s11..s18 low Barrett+store(pc+472);         *)
  (*     s19 inc eax ; s20 cmp 0x100 ; s21 jae done (not taken) -> s22 movzbl. *)
  (*     HIGH: s22 movzbl reload ; s23 shr4 ; s24 and0xf -> R11=high nibble ;  *)
  (*       s25 cmp 0xf ; s26 jae loop.                                         *)
  (*       ACCEPT-ACCEPT (s26 not taken): s27..s34 high Barrett+store ; s35 inc ; *)
  (*         s36 jmp -> pc+399.                                                *)
  (*       LO-only (s26 taken): -> pc+399.                                     *)
  (*   REJECT-LOW (s10 taken): s11 movzbl reload ; s12 shr4 ; s13 and0xf ->    *)
  (*     R11=high nibble ; s14 cmp 0xf ; s15 jae loop.                         *)
  (*       HI-only (s15 not taken): s16..s23 high Barrett+store ; s24 inc ;    *)
  (*         s25 jmp -> pc+399.                                                *)
  (*       NONE (s15 taken): -> pc+399.                                        *)
  (*                                                                           *)
  (* Requires type_invention_error := true.                                    *)
  (* ========================================================================= *)

  (* ------------------------------------------------------------------------- *)
  (* ETA2_STORE_SPEC_TAC sN nibt : bridge the tower-valued bytes32 store fact at *)
  (* state sN, nibble `nibt` (= `val(EL p inlist) MOD 16` or `... DIV 16`), to *)
  (* spec form `word_sx(word_sub 2 (word_umod (word nibt) 5)):int32`, on a     *)
  (* CLEANED subgoal (accept hyp `nibt < 15` + the store fact only) so the     *)
  (* 15-way WORD_REDUCE is fast (~1min) rather than >4min with all ensures asms. *)
  (* ------------------------------------------------------------------------- *)
  let ETA2_SPECRHS_OF nibt =
    subst [nibt,`nn:num`]
     `word_sx(word_sub (word 2:int16) (word_umod (word nn) (word 5:int16))):int32`;;

  let ETA2_STORE_SPEC_TAC (sN:term) (nibt:term) : tactic =
    let acc = mk_binary "<" (nibt,`15`) in
    let specrhs = ETA2_SPECRHS_OF nibt in
    FIRST_ASSUM (fun ath ->
      if concl ath <> acc then NO_TAC else
      FIRST_X_ASSUM (fun th ->
        let c = concl th in
        if is_eq c
           && can (find_term (fun t -> try fst(dest_const t)="bytes32" with _->false)) c
           && can (find_term (fun t -> t=sN)) c
           && can (find_term (fun t -> t=nibt)) c
           && not (can (find_term is_cond) c)
        then
          SUBGOAL_THEN (mk_eq (lhand c, specrhs)) ASSUME_TAC THENL
           [MP_TAC th THEN POP_ASSUM_LIST (K ALL_TAC) THEN
            MP_TAC ath THEN DISCH_TAC THEN
            DISCH_THEN SUBST1_TAC THEN SCALAR_STORE_REDUCE_TAC nibt;
            ALL_TAC]
        else NO_TAC));;

  let scalar_tail_body_tm =
   `!res buf table (inlist:byte list) pc (p:num) (L:num) stackpointer.
          LENGTH inlist = 136 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table, 2048) /\
          p < 136 /\ L < 256 /\
          L = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) /\
          ~(L = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 15)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word L /\ read RCX s = word p /\
                    read(memory :> bytes(res, 4 * L)) s =
                      num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)))
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    (let outlist = REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+1) inlist) in
                     read RAX s = word(LENGTH outlist) /\ read RCX s = word(p+1) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: SCALAR_TAIL_RUN substrate (pure list algebra).              *)
  (*                                                                           *)
  (* The buf-length / output-cap list lemmas the SCALAR_TAIL_RUN induction     *)
  (* needs (buf 136, tmc-length, REJ_SAMPLE_ETA2_BYTES).  All pure             *)
  (* list/arithmetic (no ISA stepping).                                        *)
  (* ========================================================================= *)

  (* Generic: LENGTH l = LENGTH(BUTLAST l) + 1 for nonempty l.                 *)
  let LENGTH_BUTLAST_TMC_ETA2 = prove
   (`LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc) = 545`,
    MP_TAC(ISPEC `mldsa_rej_uniform_eta2_tmc` LENGTH_BUTLAST_GEN) THEN
    REWRITE_TAC[GSYM LENGTH_EQ_NIL; LENGTH_MLDSA_REJ_UNIFORM_ETA2_TMC] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

  (* SUB_LIST(0,136) inlist = inlist when LENGTH inlist = 136.                 *)
  let SUB_LIST_BYTE_136 = prove
   (`!(l:byte list). LENGTH l = 136 ==> SUB_LIST(0, 136) l = l`,
    REPEAT STRIP_TAC THEN UNDISCH_TAC `LENGTH (l:byte list) = 136` THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN MATCH_ACCEPT_TAC SUB_LIST_LENGTH);;

  (* Output cap is the identity when the list is short.                        *)
  let REJ_SAMPLE_ETA2_SUB_LIST_PREFIX = prove
   (`!k (l:byte list).
       k <= LENGTH l
       ==> ?rest:int32 list.
           APPEND (REJ_SAMPLE_ETA2_BYTES (SUB_LIST (0,k) l)) rest =
           REJ_SAMPLE_ETA2_BYTES l`,
    REPEAT STRIP_TAC THEN
    EXISTS_TAC `REJ_SAMPLE_ETA2_BYTES (SUB_LIST(k, LENGTH l - k) l):int32 list` THEN
    REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES; GSYM MAP_APPEND] THEN
    AP_TERM_TAC THEN
    REWRITE_TAC[REJ_NIBBLES_ETA2; GSYM FILTER_APPEND] THEN
    AP_TERM_TAC THEN
    REWRITE_TAC[GSYM NIBBLES_OF_BYTES_APPEND] THEN
    AP_TERM_TAC THEN
    MP_TAC(ISPECL [`l:byte list`; `k:num`] SUB_LIST_TOPSPLIT) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th -> GEN_REWRITE_TAC RAND_CONV [SYM th]) THEN
    REFL_TAC);;

  (* Capped full-input output = capped partial output once the partial reaches *)
  (* 256.                                                                      *)
  let SUB_LIST_256_PREFIX_GE = prove
   (`!(inlist:byte list) k.
       k <= LENGTH inlist /\
       256 <= LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,k) inlist):int32 list)
       ==> SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES inlist :int32 list) =
           SUB_LIST(0,256)(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,k) inlist))`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`k:num`; `inlist:byte list`] REJ_SAMPLE_ETA2_SUB_LIST_PREFIX) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(X_CHOOSE_THEN `ext:int32 list` (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [SYM th])) THEN
    MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_REWRITE_TAC[]);;

  let scalar_tail_run_tm =
   `!d res buf table (inlist:byte list) pc (p:num) stackpointer.
          136 - p <= d /\
          LENGTH inlist = 136 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          p <= 136 /\
          LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 256
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
                    read RCX s = word p /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list))) s =
                      num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)))
               (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
                    (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES inlist) in
                     read RAX s = word(LENGTH outlist) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,,
                MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: SCALAR_TAIL_FROM_RUN + SCALAR_TAIL_AT_P.                    *)
  (*                                                                           *)
  (* Corollaries of SCALAR_TAIL_RUN_ETA2 :                                     *)
  (*  - FROM_RUN: instantiate d := 136 - 16*N, p := 16*N.  The scalar-tail     *)
  (*    contract in the form the main SIMD loop hands off to (entry at a 16-byte *)
  (*    block boundary 16*N).                                                  *)
  (*  - AT_P: instantiate d := 136 - p.  The scalar-tail contract at an        *)
  (*    ARBITRARY exit position p (the form CORRECT's mid-exit legs use).      *)
  (* ========================================================================= *)

  let scalar_tail_at_p_tm =
   `!res buf table (inlist:byte list) pc p stackpointer.
          LENGTH inlist = 136 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 546) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 136) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          p <= 136 /\
          LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 256
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
                    read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
                    read RCX s = word p /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list))) s =
                      num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist)))
               (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta2_tmc)) /\
                    (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES inlist) in
                     read RAX s = word(LENGTH outlist) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: goal statement and proof scaffold.                          *)
  (*                                                                           *)
  (* Control flow (from the .o; tmc offset = raw - 4):                         *)
  (*                                                                           *)
  (*  PROLOGUE  raw 0x00..0x59 (tmc pc..pc+85): 17 insns, 5 vector consts      *)
  (*    (YMM3=YMM5 nibble mask 0x0f, YMM4 eta2 broadcast 0x02, YMM6 0xe660 x16, *)
  (*    YMM7 5 x16), xor eax/ecx.                                              *)
  (*                                                                           *)
  (*  SIMD LOOP TOP  raw 0x5a (tmc pc+86):                                     *)
  (*     0x5a cmp eax,248 ; 0x5f ja scalar    0x65 cmp ecx,120 ; 0x68 ja scalar *)
  (*     0x6e.. sub-iter-1 (store 0xb4, mid-guard 0xc8 cmp eax,248/ja)         *)
  (*     0xd3.. sub-iter-2 (store 0xfa, mid-guard 0x10e)                       *)
  (*     0x115.. sub-iter-3 (store 0x14c, mid-guard 0x150)                     *)
  (*     0x157.. sub-iter-4 (store 0x17e; 0x183 popcnt/add; 0x18e jmp top).    *)
  (*             SI4 has no mid-guard (unconditional back-edge).               *)
  (*                                                                           *)
  (*  SCALAR TAIL  raw 0x193 (tmc pc+399):                                     *)
  (*     0x193 cmp eax,256 ; jae done    0x19e cmp ecx,136 ; jae done          *)
  (*     0x1a6.. byte-at-a-time.                                               *)
  (*                                                                           *)
  (*  DONE  raw 0x222 (tmc pc+542).                                            *)
  (*                                                                           *)
  (* The SIMD head guard is cmp ecx,120 (not 136): the SIMD loop exits once    *)
  (* 16*i > 120 (first at i=8, pos 128), and the scalar tail (guard cmp        *)
  (* ecx,136) consumes the last 8 bytes.  Hence the scalar tail does real      *)
  (* work here, unlike eta4 where the SIMD loop consumes all 16 blocks.        *)
  (*                                                                           *)
  (* WOP predicate: `120 < 16*i \/ 248 < niblen(SUB(0,16i))`.  N=0 and N=1 are *)
  (* both impossible; the exit block is at i=N-1.  The scaffold runs:          *)
  (*   1. WOP to choose least N, ruling out N=0,1.                             *)
  (*   2. Init pc -> pc+86 (prologue): RAX=RCX=0, 5 YMM consts = loop inv i=0. *)
  (*   3. ENSURES_WHILE_UP_TAC over N-1 iters with body CLEAN_BODY @ i.        *)
  (*   4. Exit block at i=N-1 splits on niblen(16N)<=248:                      *)
  (*      - OFFSET arm: head guard cmp ecx,120 fires at pos 16N; CLEAN_BLOCK   *)
  (*        finishes the block, then SCALAR_TAIL_AT_P @ 16N runs the tail.     *)
  (*      - MID-EXIT arm: a sub-iter mid-guard cmp eax,248 fires inside the    *)
  (*        block at the first offset p where niblen(p)>248, then              *)
  (*        SCALAR_TAIL_AT_P @ p.                                              *)
  (* ========================================================================= *)

  (* The eta2 CORRECT goal.  MAYCHANGE ZMM set = full ZMM0..9; CLEAN_BODY's    *)
  (* tighter [0;1;2;8;9] is subsumed in the loop-body scaffold step.           *)
  let correct_eta2_tm = `
     !res buf table (inlist:byte list) pc.
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
                    let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA2_BYTES inlist) in
                    let outlen = LENGTH outlist in
                    C_RETURN s = word outlen /\
                    read(memory :> bytes(res,4 * outlen)) s =
                      num_of_wordlist outlist)
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE SOME_FLAGS ,,
                MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* The strengthened loop invariant (adds the 5 YMM broadcast constants).     *)
  let CORRECT_LOOPINV_ETA2 =
   `\i s. read RSP s = stackpointer /\
          read (memory :> bytes (buf, 136)) s = num_of_wordlist inlist /\
          read (memory :> bytes (table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
          read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
          read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
          read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
          read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
          read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
          read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
          read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
          read RCX s = word(16*i) /\
          read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s =
            num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist))`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: MID-EXIT substrate (pure arith / list algebra) +            *)
  (* the 4 MID_EXIT lemma STATEMENTS.                                          *)
  (*                                                                           *)
  (* The MID-EXIT arm of the exit block (the FALSE branch of ASM_CASES         *)
  (* niblen(16N)<=248) needs 4 MID_EXIT lemmas (real-stepping the i=N-1 block  *)
  (* up to whichever sub-iter mid-guard fires TAKEN) + MIDEXIT_ARM_TAC (dispatch *)
  (* by crossover offset).  This section front-loads everything that needs NO  *)
  (* stepping:                                                                 *)
  (*                                                                           *)
  (*  - RCX4_COLLAPSE: word_zx(word_add(word_zx(word a))(word 4)) = word(a+4). *)
  (*    Architecture-generic; the +4 RCX advance the mid-guard counter blocks  *)
  (*    emit.                                                                  *)
  (*  - REJ_SAMPLE_ETA2_PREFIX_MONO: a<=b => outlen(SUB(0,a))<=outlen(SUB(0,b)). *)
  (*  - SUBITER_STEP_BOUND_8_ETA2 / SUBITER_BRIDGE_ETA2:                       *)
  (*    processing 4 more bytes appends <=8 samples.                           *)
  (*  - OUTLEN0_LE_256_FROM_SUBITER_ETA2: outlen(SUB(0,p))<=248 =>             *)
  (*    outlen(SUB(0,p+4))<=256, discharges SCALAR_TAIL_AT_P's <=256 hyp on the *)
  (*    mid-exit legs.                                                         *)
  (*  - the clean-block guard bound: a clean block's 3 internal guards are all *)
  (*    <=248 (used by MID_EXIT_CASE4 setup).                                  *)
  (* ========================================================================= *)

  (* ---- pure word arithmetic: the RCX +4 collapse ----                       *)
  let REJ_SAMPLE_ETA2_PREFIX_MONO = prove
   (`!(inlist:byte list) a b.
       a <= b
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,a) inlist):int32 list) <=
           LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,b) inlist):int32 list)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `SUB_LIST(0,b) (inlist:byte list) = APPEND (SUB_LIST(0,a) inlist) (SUB_LIST(a,b-a) inlist)` SUBST1_TAC THENL
     [MP_TAC(ISPECL [`inlist:byte list`;`a:num`;`b-a`;`0`] SUB_LIST_SPLIT) THEN
      ASM_SIMP_TAC[ADD_CLAUSES; ARITH_RULE `a <= b ==> a + (b - a) = b`];
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES_APPEND_LE]]);;

  (* ---- per-4-byte sample count <= 8 ----                                    *)
  let SUBITER_STEP_BOUND_8_ETA2 = prove
   (`!(inlist:byte list) k.
       LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(k,4) inlist):int32 list) <= 8`,
    REPEAT GEN_TAC THEN
    MP_TAC(ISPEC `SUB_LIST(k,4) (inlist:byte list)` LENGTH_REJ_SAMPLE_ETA2_BYTES_BOUND) THEN
    REWRITE_TAC[LENGTH_SUB_LIST] THEN ARITH_TAC);;

  (* ---- 4-byte sub-iter bridge: append + length + <=8 ----                   *)
  let SUBITER_BRIDGE_ETA2 = prove
   (`!(inlist:byte list) p.
       p + 4 <= LENGTH inlist
       ==> REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+4) inlist):int32 list =
             APPEND (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist))
                    (REJ_SAMPLE_ETA2_BYTES(SUB_LIST(p,4) inlist)) /\
           LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+4) inlist):int32 list) =
             LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) +
             LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(p,4) inlist):int32 list) /\
           LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(p,4) inlist):int32 list) <= 8`,
    REPEAT STRIP_TAC THENL
     [ONCE_REWRITE_TAC[ARITH_RULE `p + 4 = 0 + (p + 4)`] THEN
      MP_TAC(ISPECL [`inlist:byte list`;`p:num`;`4`;`0`] SUB_LIST_SPLIT) THEN
      REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_APPEND];
      ONCE_REWRITE_TAC[ARITH_RULE `p + 4 = 0 + (p + 4)`] THEN
      MP_TAC(ISPECL [`inlist:byte list`;`p:num`;`4`;`0`] SUB_LIST_SPLIT) THEN
      REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[REJ_SAMPLE_ETA2_BYTES_APPEND; LENGTH_APPEND];
      REWRITE_TAC[SUBITER_STEP_BOUND_8_ETA2]]);;

  (* ---- tight <=256 after one more sub-iter ----                             *)
  let OUTLEN0_LE_256_FROM_SUBITER_ETA2 = prove
   (`!(inlist:byte list) p.
       p + 4 <= LENGTH inlist /\
       LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p+4) inlist):int32 list) <= 256`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`inlist:byte list`;`p:num`] SUBITER_BRIDGE_ETA2) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
    REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in
      can (find_term (fun t -> t = `REJ_SAMPLE_ETA2_BYTES(SUB_LIST(p,4) inlist):int32 list`)) c
      || c = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 248`))) THEN
    ARITH_TAC);;

  (* ========================================================================= *)
  (* The 4 MID_EXIT lemma STATEMENTS.                                          *)
  (* Shared pre/cframe (eta2 form: pc+86 loop top, 5 YMM consts, ZMM0..9 frame). *)
  (* ========================================================================= *)

  let midexit_eta2_cframe =
    `MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
     MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
     MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes (res,1024)]`;;

  let midexit_eta2_pre =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
         read RIP s = word(pc + 86) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read YMM3 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
         read YMM4 s = word 908173248920127022929968509872062022378588115024631874819275168689514742274 /\
         read YMM5 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
         read YMM6 s = word 104203162506446325494781756494581186443189907921581107878096444258040508638816 /\
         read YMM7 s = word 8834370125682169483754557489027840684616615904908870377619408255734579205 /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
         read RCX s = word(16*i) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, 16*i) inlist))`;;

  (* post at a mid-guard-taken exit position pexpr (pc+399, scalar tail entry). *)
  let midexit_eta2_post_at pexpr =
    subst [pexpr,`PP:num`]
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta2_tmc) /\
         read RIP s = word(pc + 399) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 136)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, PP) inlist):int32 list)) /\
         read RCX s = word(PP) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, PP) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0, PP) inlist))`;;

  (* shared nonoverlapping+length hyps (eta2: 546, 136).                       *)
  let midexit_eta2_hyps =
    [`LENGTH (inlist:byte list) = 136`;
     `nonoverlapping_modulo (2 EXP 64) (pc, 546) (val(res:int64),1024)`;
     `nonoverlapping_modulo (2 EXP 64) (pc, 546) (val(buf:int64), 136)`;
     `nonoverlapping_modulo (2 EXP 64) (pc, 546) (val(table:int64),2048)`;
     `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(buf:int64), 136)`;
     `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(table:int64),2048)`;
     `16 * (i + 1) <= 136`];;

  let mk_midexit_tm extra_hyps pexpr =
    list_mk_forall([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`i:num`;`stackpointer:int64`],
     mk_imp(list_mk_conj(midexit_eta2_hyps @ extra_hyps),
       list_mk_comb(`ensures x86`,[midexit_eta2_pre; midexit_eta2_post_at pexpr; midexit_eta2_cframe])));;

  (* SUBITER1: mid-guard-1 fires taken at pos 16i+4.                           *)
  let midexit1_eta2_tm = mk_midexit_tm
    [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i) inlist):int32 list) <= 248`;
     `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`]
    `16*i+4`;;

  (* SUBITER2: mid-guard-2 fires taken at pos 16i+8.                           *)
  let midexit2_eta2_tm = mk_midexit_tm
    [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 248`;
     `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`]
    `16*i+8`;;

  (* SUBITER3: mid-guard-3 fires taken at pos 16i+12.                          *)
  let midexit3_eta2_tm = mk_midexit_tm
    [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) <= 248`;
     `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`]
    `16*i+12`;;

  (* CASE4: all 3 internal guards clean, head-guard1 fires taken at back-edge pos 16(i+1). *)
  let midexit4_eta2_tm = mk_midexit_tm
    [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) <= 248`;
     `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`]
    `16*(i+1)`;;

  (* ========================================================================= *)
  (* eta2 CORRECT: MID_EXIT_SUBITER2 (mid-guard-2 fires TAKEN).                *)
  (*                                                                           *)
  (* Sub-iter-1's mid-guard is NOT taken (niblen(16i+4)<=248), then sub-iter-2's *)
  (* mid-guard fires TAKEN (niblen(16i+8)>248) -> pc+399 with RCX=16i+8,       *)
  (* RAX=niblen(16i+8), res holding REJ_SAMPLE(0,16i+8).                       *)
  (*                                                                           *)
  (* Structure:                                                                *)
  (* ETA2_MIDEXIT_PREFIX_TAC -> s20, SI1 store folded                          *)
  (*   ETA2_MG1_NT_TAC                          -> s26, mid-guard-1 NOT taken  *)
  (*                                               (pc+207), bound from DIRECT *)
  (*                                               niblen(16i+4)<=248 via bridge *)
  (* ETA2_SI2_FOLD -> s35, SI2 store folded                                    *)
  (*   ETA2_SI2_MG2_TAKEN_TAC                   -> s41, mid-guard-2 TAKEN pc+399 *)
  (*   ENSURES_FINAL + RAX/RCX discharge                                       *)
  (*                                                                           *)
  (* NEW tactics here:                                                         *)
  (* - ETA2_MG1_NT_TAC = ETA2_SI1_COUNTER_TAC with the ONE bound step swapped: *)
  (*    instead of SUBITER_OUTLEN_BOUND_1 (needs niblen(16(i+1))<=248), derive *)
  (*    outlen0+block0len<=248 via SUBITER_BRIDGE_ETA2 + the DIRECT hyp        *)
  (*    niblen_sample(16i+4)<=248 (FIRST[ACCEPT; PREFIX_MONO]).                *)
  (* - ETA2_SI2_MG2_TAKEN_TAC = ETA2_SI2_MG_TAC with the bound swapped to      *)
  (*    gt248/lt32 + JA_TAKEN_GT (mid-guard-2 fires) + RIP pc+399.             *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* ------------------------------------------------------------------------- *)
  (* Shared RIP-resolution step for the eta2 mid-guard twins.  The value chain  *)
  (* grabs the assumption mentioning `pc + pcoff` directly; the memory-safety    *)
  (* chain instead finds the RIP-COND assumption at state s<st> by shape (the    *)
  (* anchored events fact also mentions pc+pcoff, so the bare find_term would    *)
  (* grab it).                                                                   *)
  let eta2_rip_mp (memsafe:bool) (pcoff:int) (st:int) : tactic =
    let pctm = mk_binop `(+):num->num->num` `pc:num` (mk_small_numeral pcoff) in
    let stv = mk_var("s"^string_of_int st,`:x86state`) in
    if memsafe then
      W(fun (asl,_) ->
        let ifrip = find (fun (_,th) -> match concl th with
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),v)),r) ->
             v=stv && (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false)
           | _ -> false) asl in
        MP_TAC (snd ifrip))
    else
      FIRST_ASSUM(fun th -> if can(find_term(fun u->u=pctm))(concl th) then MP_TAC th else NO_TAC);;

  (* ETA2_MG1_NT_TAC: SI1 counter block s21-26, mid-guard-1 NOT taken (pc+207), *)
  (* bound derived from the DIRECT hyp niblen_sample(16i+4)<=248 (via bridge)  *)
  (* rather than SUBITER_OUTLEN_BOUND_1.                                       *)
  let mk_eta2_mg1_nt (memsafe:bool) : tactic =
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
    (* pop_len (identical to SI1_COUNTER: R9 s24 popcount = block0len)         *)
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
    (* bridge: outlen0 + niblen(SUB(16i,4)) = niblen_sample(16i+4)             *)
    SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN
      UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i) inlist):int32 list) = outlen0` THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    (* bnd: outlen0 + block0len <= 248, from the DIRECT niblen(16i+4)<=248 hyp *)
    SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list) <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
      FIRST [FIRST_ASSUM ACCEPT_TAC;
             (FIRST_X_ASSUM(fun th -> match concl th with
                Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),k) when k=`248`
                  -> MP_TAC th | _ -> NO_TAC) THEN
              MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
              MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block0len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `outlen0:num` block0len in
      let bnd = snd(find (fun (_,th) -> concl th = mk_binop `(<=):num->num->bool` sum `248`) asl) in
      let pop_len = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL[sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
    X86_STEPS_TAC EXEC (25--26) THEN
    SUBGOAL_THEN `read RIP s26 = word (pc + 207):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let blk0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
               (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
        let rax_red0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
        let ja = find (fun (_,th) -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th)) asl in
        eta2_rip_mp memsafe 207 26 THEN
        REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
        REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    W(fun (asl,w) ->
      let pl = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let rr = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_SI2_MG2_TAKEN_TAC: SI2 counter s36-41, mid-guard-2 fires TAKEN (pc+399). *)
  (* From s35 (post-SI2-fold).                                                 *)
  let mk_eta2_si2_mg2_taken (memsafe:bool) : tactic =
    X86_STEPS_TAC EXEC (36--39) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt2 = REWRITE_RULE[m8b_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE1)) in
      let lanesum8 = rand(concl popcnt2) in
      let mb2 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),c) -> c=`8` | _ -> false))c) in
      let mb2_tm = concl mb2 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in
      let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                     word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
      let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block1)) in
      let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
      ASSUME_TAC pop_len2) THEN
    (* bridge2: acc1 + block1len = niblen_sample(16i+8)                        *)
    SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
      FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then MP_TAC th else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] OUTLEN0_LE_256_FROM_SUBITER_ETA2) THEN
      ANTS_TAC THENL
       [CONJ_TAC THENL
         [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC;
          FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
      REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN ARITH_TAC; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block1len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `acc1:num` block1len in
      let bridge2 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_) -> true | _ -> false) asl) in
      let lt32 = REWRITE_RULE[SYM bridge2] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32`) asl)) in
      let pop_len2 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let gt248 = REWRITE_RULE[SYM bridge2] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`) asl)) in
      let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
      ASSUME_TAC pop_len2 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
    X86_STEPS_TAC EXEC (40--41) THEN
    SUBGOAL_THEN `read RIP s41 = word (pc + 399):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let pop_len2_old = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
        let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
        let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2_old) in
        let rax_red0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
        let ja = find (fun (_,th) -> is_neg(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc1:num`))(concl th)) asl in
        eta2_rip_mp memsafe 399 41 THEN
        REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[snd rax_red0] THEN
        REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC];;

  (* MID_EXIT_SUBITER2_ETA2: sub-iter-2 mid-guard fires TAKEN at pos 16i+8.    *)
  let mk_midexit2_eta2 (memsafe:bool) (prefix:tactic) (disch:tactic) : tactic =
  prefix THEN
    SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
    (mk_eta2_mg1_nt memsafe) THEN
    ETA2_SI2_FOLD THEN
    (mk_eta2_si2_mg2_taken memsafe) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    (* RAX collapse (pop_len2_typed -> bridge2 -> niblen(16i+8)); ja_taken guard; RCX. *)
    W(fun (asl,w) ->
      let pop_len2 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2) in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let bridge2 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_) -> true | _ -> false) asl in
      REWRITE_TAC[pop_len2_typed; snd rax_red0; snd bridge2]) THEN
    W(fun (asl,w) ->
      let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                     (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`)
                           (ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32`)) in
      REWRITE_TAC[ntake]) THEN
    (* RCX collapse: double +4 nest (16i -> 16i+4 -> 16i+8)                    *)
    MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[ARITH_RULE `16*i+4+4 = 16*i+8`] THEN DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    (if memsafe then CONJ_TAC THENL [AP_TERM_TAC THEN ARITH_TAC; disch] else TRY(AP_TERM_TAC THEN ARITH_TAC));;

  (* ========================================================================= *)
  (* eta2 CORRECT: MID_EXIT_SUBITER3 (mid-guard-3 fires TAKEN).                *)
  (*                                                                           *)
  (* Sub-iters 1+2 mid-guards NOT taken (niblen(16i+4)<=248, niblen(16i+8)<=248), *)
  (* then sub-iter-3's mid-guard fires TAKEN (niblen(16i+12)>248) -> pc+399 with *)
  (* RCX=16i+12, RAX=niblen(16i+12), res holding REJ_SAMPLE(0,16i+12).         *)
  (*                                                                           *)
  (* Structure:                                                                *)
  (* ETA2_MIDEXIT_PREFIX_TAC -> s20 SI1 store folded                           *)
  (* ETA2_MG1_NT_TAC -> s26 mg1 NOT taken (pc+207)                             *)
  (* ETA2_SI2_FOLD -> s35 SI2 store folded                                     *)
  (*   ETA2_MG2_NT_TAC                     -> s41   mg2 NOT taken (pc+273)     *)
  (* ETA2_SI3_FOLD -> s50 SI3 store folded                                     *)
  (*   ETA2_SI3_MG3_TAKEN_TAC             -> s56   mg3 TAKEN (pc+399)          *)
  (*   ENSURES_FINAL + RAX/RCX discharge                                       *)
  (*                                                                           *)
  (* NEW tactics:                                                              *)
  (*  - ETA2_MG2_NT_TAC = ETA2_SI2_MG2_TAKEN_TAC's pop_len2/bridge2 build but  *)
  (*    JA_NOT_TAKEN_LE + RIP pc+273 (bound from DIRECT niblen(16i+8)<=248 via *)
  (*    the bridge), ending with an RAX-fold so ETA2_SI3_FOLD's acc2 abbrev+RAX *)
  (*    match works.                                                           *)
  (*  - ETA2_SI3_MG3_TAKEN_TAC = ETA2_SI3_MG (build pop_len3/bridge3) then     *)
  (*    gt248/lt32 + JA_TAKEN_GT -> RIP pc+399.                                *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_SI3_BODY3_TAC: the SI3 store fold for the MID-EXIT context.  The     *)
  (* clean-body ETA2_SI3_FOLD derives the                                      *)
  (* acc2<=248 bound via SUBITER_OUTLEN_BOUND_3 (needs niblen(16(i+1))<=248),  *)
  (* which is ABSENT in the mid-exit goals.  ETA2_SI3_BODY3 instead abbrevs acc2 *)
  (* and derives acc2<=248 from the DIRECT hyp niblen_sample(16i+8)<=248 (via  *)
  (* ACC2_IDENT giving niblen_sample(16i+8)=acc2), then runs the identical SI3 *)
  (* step/refold/fold body as ETA2_SI3_FOLD's post-PRE portion.                *)
  (* NOTE MG2_NT does NOT abbrev acc2 (unlike the clean-body SI2 counter), so the *)
  (* ABBREV must happen here.                                                  *)
  let ETA2_SI3_PRE3_TAC : tactic =
    ABBREV_TAC `acc2 = acc1 + LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (16*i+4,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8c = read R8 s41` THEN
    ACC2_IDENT_TAC THEN
    SUBGOAL_THEN `acc2 <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
    VAL_INT64_TAC `acc2:num`;;

  let ETA2_SI3_BODY3_TAC : tactic =
    ETA2_SI3_PRE3_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2`]) THEN
    (* s42 vextracti128 $1 -> XMM8 (HIGH-128 of EXPANDED f0sub); re-fold f0sub. *)
    X86_VSTEPS_TAC EXEC (42--42) THEN
    W(fun (asl,w) ->
       let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th) = `f0sub:int256` || rand(concl th) = `f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       let f0fold = if rand(concl f0d) = `f0sub:int256` then f0d else SYM f0d in
       RULE_ASSUM_TAC(fun th -> if concl th = concl f0d then th else REWRITE_RULE[f0fold] th)) THEN
    X86_VERBOSE_STEP_TAC EXEC "s43" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s42 = mask8c:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt_3 ASSUME_TAC THENL [MASKBIT_TGT_3_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (44--44) THEN ETA2_TAB3_TEQ_TAC THEN
    REABBREV_TAC `tab3 = read YMM9 s44` THEN
    X86_VSTEPS_TAC EXEC (45--45) THEN REABBREV_TAC `pshuf3 = read YMM9 s45` THEN
    PURGE_STALE_STATES_TAC ["s44"] THEN
    X86_VSTEPS_TAC EXEC (46--46) THEN REABBREV_TAC `sx3 = read YMM1 s46` THEN
    PURGE_STALE_STATES_TAC ["s45"] THEN
    X86_VSTEPS_TAC EXEC (47--47) THEN X86_VSTEPS_TAC EXEC (48--48) THEN
    X86_VSTEPS_TAC EXEC (49--49) THEN
    PURGE_STALE_STATES_TAC ["s46";"s47";"s48"] THEN
    VAL_INT64_TAC `acc2:num` THEN
    X86_STEPS_TAC EXEC (50--50) THEN
    ETA2_STORE_REFOLD_3_TAC THEN
    ETA2_SX3_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_3_TAC THEN
    ACC2_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      let sx3clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx3:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      let pfth = find (fun th -> concl th = pf_target_3) asms in
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt_3) asms in
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx3clean] storerf) in
      let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
      let m = `word (val (mask8c:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc2)):int64`; `s50:x86state`; g3; m;
                       `LENGTH(ACC_IDX (word (val (mask8c:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g3; m; `word_subword (chunk0:int128) (64,8):byte`;
          `word_subword (chunk0:int128) (72,8):byte`; `word_subword (chunk0:int128) (80,8):byte`;
          `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC in
      let specres = MP spec (CONJ mthm bg) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=136 ==> 16*i+16<=136`) i116)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (64,8):byte`;`word_subword (chunk0:int128) (72,8):byte`;
          `word_subword (chunk0:int128) (80,8):byte`;`word_subword (chunk0:int128) (88,8):byte`] LEN_RECONCILE_GEN) mthm in
      let lr = REWRITE_RULE[GSYM blk2_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk2_eq] rej_store in
      let acc2_ident = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc2",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s50",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc2:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc2_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc2_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s50:x86state`;m;`SUB_LIST(16*i+8,4) (inlist:byte list)`;`SUB_LIST(0,16*i+8) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+8)+4 = 16*i+12`] fold in
      ASSUME_TAC clean);;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_MG2_NT_TAC: SI2 counter s36-41, mid-guard-2 NOT taken -> pc+273.     *)
  (* bound acc1+block1len<=248 from DIRECT niblen(16i+8)<=248 (FIRST[ACCEPT;MONO]) *)
  (* Ends with an RAX-fold for the SI3 store.                                  *)
  let mk_eta2_mg2_nt (memsafe:bool) : tactic =
    X86_STEPS_TAC EXEC (36--39) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt2 = REWRITE_RULE[m8b_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE1)) in
      let lanesum8 = rand(concl popcnt2) in
      let mb2 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`8` | _ -> false))c) in
      let mb2_tm = concl mb2 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in
      let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                     word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
      let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block1)) in
      let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
      ASSUME_TAC pop_len2) THEN
    SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
      FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then MP_TAC th else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list) <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
      FIRST [FIRST_ASSUM ACCEPT_TAC;
             (FIRST_X_ASSUM(fun th -> match concl th with
                Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),k) when k=`248`
                  -> MP_TAC th | _ -> NO_TAC) THEN
              MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
              MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block1len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `acc1:num` block1len in
      let bnd = snd(find (fun (_,th) -> concl th = mk_binop `(<=):num->num->bool` sum `248`) asl) in
      let pop_len2 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL [sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len2 THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
    X86_STEPS_TAC EXEC (40--41) THEN
    SUBGOAL_THEN `read RIP s41 = word (pc + 273):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        (* disambiguate the block1 pop_len (SUB_LIST(16i+4,4)) from the stale MG1
           pop_len (SUB_LIST(16i,4)) — both are word_popcount facts now. *)
        let pop_len2_old = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
              can(find_term(fun u->u=`SUB_LIST(16*i+4,4) (inlist:byte list)`))(concl th) | _ -> false) asl in
        let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
        let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2_old) in
        let rax_red0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
              can(find_term(fun u->u=`acc1:num`))(concl th) | _ -> false) asl in
        let ja = find (fun (_,th) -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc1:num`))(concl th)) asl in
        eta2_rip_mp memsafe 273 41 THEN
        REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[snd rax_red0] THEN
        REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* RAX-fold so SI3 store discharges                                        *)
    W(fun (asl,w) ->
      let pl = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`SUB_LIST(16*i+4,4) (inlist:byte list)`))(concl th) | _ -> false) asl in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pl_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pl) in
      let rr = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc1:num`))(concl th) | _ -> false) asl in
      RULE_ASSUM_TAC(REWRITE_RULE[pl_typed]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_SI3_MG3_TAKEN_TAC: SI3 counter s51-56, mid-guard-3 fires TAKEN (pc+399). *)
  (* = ETA2_SI3_MG's pop_len3/bridge3 build but JA_TAKEN_GT + RIP pc+399.      *)
  let ETA2_SI3_MG3_TAKEN_TAC : tactic =
    X86_STEPS_TAC EXEC (51--54) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt3 = REWRITE_RULE[m8b_def; m8c_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE2)) in
      let lanesum = rand(concl popcnt3) in
      let mb3 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`16` | _ -> false))c) in
      let mb3_tm = concl mb3 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                     word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
      let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block2)) in
      let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum, block2len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
      ASSUME_TAC pop_len3) THEN
    (* bridge3: acc2 + block2len = niblen_sample(16i+12)                       *)
    SUBGOAL_THEN `acc2 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
      FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then MP_TAC th else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] OUTLEN0_LE_256_FROM_SUBITER_ETA2) THEN
      ANTS_TAC THENL
       [CONJ_TAC THENL
         [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC;
          FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
      REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN ARITH_TAC; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block2len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `acc2:num` block2len in
      let bridge3 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> true | _ -> false) asl) in
      let lt32 = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32`) asl)) in
      let pop_len3 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let gt248 = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`) asl)) in
      let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
      ASSUME_TAC pop_len3 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
    X86_STEPS_TAC EXEC (55--56) THEN
    SUBGOAL_THEN `read RIP s56 = word (pc + 399):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let find_a p = find p asms in
        let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
        let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
        let blk16 = find_a (fun th -> is_eq(concl th) &&
           (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                    (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
        let blk2_eq = el 2 (CONJUNCTS bb) in
        let rax_red0 = find_a (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
              can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
        let ja = find_a (fun th -> is_neg(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc2:num`))(concl th)) in
        let ifrip = find_a (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s56",_))),r) ->
             (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) in
        MP_TAC ifrip THEN REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC];;

  (* MID_EXIT_SUBITER3_ETA2: sub-iter-3 mid-guard fires TAKEN at pos 16i+12.   *)
  let mk_midexit3_eta2 (memsafe:bool) (prefix:tactic) (disch:tactic) : tactic =
  prefix THEN
    SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
    (mk_eta2_mg1_nt memsafe) THEN
    ETA2_SI2_FOLD THEN
    (mk_eta2_mg2_nt memsafe) THEN
    ETA2_SI3_BODY3_TAC THEN
    ETA2_SI3_MG3_TAKEN_TAC THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    (* RAX collapse (pop_len3 -> bridge3 -> niblen(16i+12)); ja_taken guard; RCX. *)
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let pop_len3 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) in
      let rax_red0 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
      let bridge3 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> true | _ -> false) in
      REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN REWRITE_TAC[bridge3]) THEN
    W(fun (asl,w) ->
      let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                     (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`)
                           (ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32`)) in
      REWRITE_TAC[ntake]) THEN
    (* RCX collapse: triple +4 nest (16i -> +4 -> +8 -> +12).  After each
       RCX4_COLLAPSE rewrite the goal carries `word((..)+4)`; NORMALISE that
       bracketed sum to the flat `16*i+k` form *after* the DISCH (not before, or
       the SPEC of the next level's collapse can't match).  Then AP_TERM+ARITH
       closes the final `word((16*i+8)+4) = word(16*i+12)`. *)
    MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
    MP_TAC(SPEC `16*i+8` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    TRY(AP_TERM_TAC THEN ARITH_TAC) THEN REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN (if memsafe then disch else ALL_TAC);;

  (* ========================================================================= *)
  (* eta2 CORRECT: MID_EXIT_CASE4 (all 3 internal guards clean, head-guard-1   *)
  (* fires TAKEN at the back-edge).                                            *)
  (*                                                                           *)
  (* Sub-iters 1/2/3 mid-guards all NOT taken; sub-iter-4 processes, then      *)
  (* niblen(16(i+1))>248 so the head-guard fires at the next loop-top pc+86.   *)
  (*                                                                           *)
  (* Structure:                                                                *)
  (*   ETA2_MIDEXIT_PREFIX_TAC  -> s20  SI1 store folded                       *)
  (*   ETA2_MG1_NT_TAC          -> s26  mg1 not taken (pc+207)                 *)
  (*   ETA2_SI2_FOLD            -> s35  SI2 store folded                       *)
  (*   ETA2_MG2_NT_TAC          -> s41  mg2 not taken (pc+273)                 *)
  (*   ETA2_SI3_BODY3_TAC       -> s50  SI3 store folded                       *)
  (*   ETA2_MG3_NT_TAC          -> s56  mg3 not taken (pc+339)                 *)
  (*   ETA2_SI4_BODY4_TAC       -> s65  SI4 store folded                       *)
  (*   ETA2_SI4_COUNTER_TAC     -> s69  popcnt/add/add/JMP -> pc+86            *)
  (*   [head-guard-1 cmp eax,248 TAKEN] s70-71 -> pc+399, then ENSURES_FINAL.  *)
  (*                                                                           *)
  (* eta2-vs-eta4 divergence: eta4's SI4 sub-iter ends with the head-guard-1   *)
  (* eax cmp inline.  In eta2 the SI4 counter is popcnt/add/add/JMP (s66-69,   *)
  (* unconditional jmp to pc+86, no inline cmp/ja), so head-guard-1 (cmp       *)
  (* eax,248; ja) is re-executed at the loop top after the jmp.  For CASE4     *)
  (* that head-guard fires TAKEN (niblen(16(i+1))>248) -> pc+399.              *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA2_EXEC;;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_MG3_NT_TAC: SI3 counter s51-56, mid-guard-3 NOT taken -> pc+339.     *)
  (* bound acc2+block2len<=248 from DIRECT niblen(16i+12)<=248 (FIRST[ACCEPT;MONO]) *)
  (* Ends with an RAX-fold for the SI4 store.                                  *)
  let mk_eta2_mg3_nt (memsafe:bool) : tactic =
    X86_STEPS_TAC EXEC (51--54) THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt3 = REWRITE_RULE[m8b_def; m8c_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE2)) in
      let lanesum = rand(concl popcnt3) in
      let mb3 = find_a (fun th -> let c=concl th in is_forall c &&
         can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`16` | _ -> false))c) in
      let mb3_tm = concl mb3 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                     word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
      let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block2)) in
      let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum, block2len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
      ASSUME_TAC pop_len3) THEN
    (* bridge3: acc2 + block2len = niblen_sample(16i+12)                       *)
    SUBGOAL_THEN `acc2 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
      FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then MP_TAC th else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    (* bound acc2 + block2len <= 248 from the DIRECT niblen(16i+12)<=248 hyp   *)
    SUBGOAL_THEN `acc2 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list) <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
      FIRST [FIRST_ASSUM ACCEPT_TAC;
             (FIRST_X_ASSUM(fun th -> match concl th with
                Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),k) when k=`248`
                  -> MP_TAC th | _ -> NO_TAC) THEN
              MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
              MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block2len = `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `acc2:num` block2len in
      let bnd = snd(find (fun (_,th) -> concl th = mk_binop `(<=):num->num->bool` sum `248`) asl) in
      let pop_len3 = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`SUB_LIST(16*i+8,4) (inlist:byte list)`))(concl th) | _ -> false) asl) in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL [sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len3 THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
    X86_STEPS_TAC EXEC (55--56) THEN
    SUBGOAL_THEN `read RIP s56 = word (pc + 339):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let find_a p = find p asms in
        let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
        let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
        let blk16 = find_a (fun th -> is_eq(concl th) &&
           (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                    (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
        let blk2_eq = el 2 (CONJUNCTS bb) in
        let rax_red0 = find_a (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
              can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
        let ja = find_a (fun th -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc2:num`))(concl th)) in
        eta2_rip_mp memsafe 339 56 THEN
        REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* RAX-fold so SI4 store discharges                                        *)
    W(fun (asl,w) ->
      let pl = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`SUB_LIST(16*i+8,4) (inlist:byte list)`))(concl th) | _ -> false) asl in
      let rr = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) asl in
      RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

  (* ------------------------------------------------------------------------- *)
  (* ETA2_SI4_BODY4_TAC: SI4 store fold for MID-EXIT.                          *)
  (* Forked SI4_PRE: acc3<=248 from DIRECT niblen(16i+12)<=248 (ACC3_IDENT +   *)
  (* FIRST[ACCEPT;PREFIX_MONO]) instead of SUBITER_OUTLEN_BOUND_4.  RAX already *)
  (* folded by MG3_NT, so PRE4 only abbrevs acc3, reabbrevs mask8d, bounds.    *)
  (* The step/refold/fold body is identical to ETA2_SI4_FOLD's post-PRE portion. *)
  let ETA2_SI4_PRE4_TAC : tactic =
    ABBREV_TAC `acc3 = acc2 + LENGTH (REJ_NIBBLES_ETA2 (SUB_LIST (16*i+8,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8d = read R8 s56` THEN
    ACC3_IDENT_TAC THEN
    SUBGOAL_THEN `acc3 <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
    VAL_INT64_TAC `acc3:num`;;

  let ETA2_SI4_BODY4_TAC : tactic =
    ETA2_SI4_PRE4_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3`]) THEN
    (* s57 vpsrldq $8 -> XMM8 (>>64 of the HIGH-128 of EXPANDED f0sub); re-fold f0sub. *)
    X86_VSTEPS_TAC EXEC (57--57) THEN
    W(fun (asl,w) ->
       let f0d = find (fun th -> is_eq(concl th) &&
          (lhand(concl th) = `f0sub:int256` || rand(concl th) = `f0sub:int256`) &&
          can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       let f0fold = if rand(concl f0d) = `f0sub:int256` then f0d else SYM f0d in
       RULE_ASSUM_TAC(fun th -> if concl th = concl f0d then th else REWRITE_RULE[f0fold] th)) THEN
    X86_VERBOSE_STEP_TAC EXEC "s58" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s57 = mask8d:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt_4 ASSUME_TAC THENL [MASKBIT_TGT_4_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (59--59) THEN ETA2_TAB4_TEQ_TAC THEN
    REABBREV_TAC `tab4 = read YMM9 s59` THEN
    X86_VSTEPS_TAC EXEC (60--60) THEN REABBREV_TAC `pshuf4 = read YMM9 s60` THEN
    PURGE_STALE_STATES_TAC ["s59"] THEN
    X86_VSTEPS_TAC EXEC (61--61) THEN REABBREV_TAC `sx4 = read YMM1 s61` THEN
    PURGE_STALE_STATES_TAC ["s60"] THEN
    X86_VSTEPS_TAC EXEC (62--62) THEN X86_VSTEPS_TAC EXEC (63--63) THEN
    X86_VSTEPS_TAC EXEC (64--64) THEN
    PURGE_STALE_STATES_TAC ["s61";"s62";"s63"] THEN
    VAL_INT64_TAC `acc3:num` THEN
    X86_STEPS_TAC EXEC (65--65) THEN
    ETA2_STORE_REFOLD_4_TAC THEN
    ETA2_SX4_CLEAN_TAC THEN
    ETA2_ESTABLISH_PF_TARGET_4_TAC THEN
    ACC3_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let storerf = find (fun th -> is_eq(concl th) &&
           can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) (lhand(concl th)) &&
           can(find_term(fun u->match u with Const("red_lane",_)->true|_->false)) (rand(concl th)) &&
           not(can(find_term(fun u->match u with Const("word_mul",_)->true|_->false)) (rand(concl th)))) asms in
      let sx4clean = find (fun th -> is_eq(concl th) && lhand(concl th)=`sx4:int256` &&
           can(find_term(fun u->match u with Const("usimd8",_)->true|_->false)) (rand(concl th))) asms in
      let pfth = find (fun th -> concl th = pf_target_4) asms in
      let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm = find (fun th -> concl th = maskbit_tgt_4) asms in
      let store_full = REWRITE_RULE[pfth] (REWRITE_RULE[sx4clean] storerf) in
      let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8d:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc3)):int64`; `s65:x86state`; g4; m;
                       `LENGTH(ACC_IDX (word (val (mask8d:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND_RL in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g4; m; `word_subword (chunk0:int128) (96,8):byte`;
          `word_subword (chunk0:int128) (104,8):byte`; `word_subword (chunk0:int128) (112,8):byte`;
          `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC in
      let specres = MP spec (CONJ mthm bg) in
      let rej_store = REWRITE_RULE[specres] res_th0 in
      let leninl = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asms in
      let i116 = find (fun th -> match concl th with
           Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th &&
           (try length(dest_list(rand(concl th))) = 16 with _ -> false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=136 ==> 16*i+16<=136`) i116)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (96,8):byte`;`word_subword (chunk0:int128) (104,8):byte`;
          `word_subword (chunk0:int128) (112,8):byte`;`word_subword (chunk0:int128) (120,8):byte`] LEN_RECONCILE_GEN) mthm in
      let lr = REWRITE_RULE[GSYM blk3_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk3_eq] rej_store in
      let acc3_ident = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_))),Var("acc3",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s65",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc3:num`))(lhand(concl th)) &&
           not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc3_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc3_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s65:x86state`;m;`SUB_LIST(16*i+12,4) (inlist:byte list)`;`SUB_LIST(0,16*i+12) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+12`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+12)+4 = 16*i+16`] fold in
      ASSUME_TAC clean);;

  (* MID_EXIT_CASE4_ETA2: all 4 sub-iters clean, head-guard-1 fires at 16(i+1).*)
  let mk_midexit4_eta2 (memsafe:bool) (prefix:tactic) (disch:tactic) : tactic =
  prefix THEN
    SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
    (* CASE4 hyp is niblen(16i+12)<=248; derive niblen(16i+4),niblen(16i+8)<=248 by mono. *)
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) <= 248` then MP_TAC th else NO_TAC) THEN
      MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
      MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) <= 248` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) <= 248` then MP_TAC th else NO_TAC) THEN
      MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
      MATCH_MP_TAC REJ_SAMPLE_ETA2_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
    (mk_eta2_mg1_nt memsafe) THEN
    ETA2_SI2_FOLD THEN
    (mk_eta2_mg2_nt memsafe) THEN
    ETA2_SI3_BODY3_TAC THEN
    (mk_eta2_mg3_nt memsafe) THEN
    ETA2_SI4_BODY4_TAC THEN
    ETA2_SI4_COUNTER_TAC THEN
    (* Step the head-guard 70-71 immediately after the counter, with the state clean
       (no le256/bridge4/<2^32 asserts yet — asserting them first puts `acc3+...`
       equations in scope that the stepper mis-applies to `read RAX s69`; the isolated
       step from a bare s69 succeeds).  RIP s69 = pc+86; s70 = cmp eax,0xf8; s71 = ja ->
       COND(pc+399,pc+97).  Then build the bounds + resolve. *)
    X86_STEPS_TAC EXEC (70--71) THEN
    (* SI4 counter jmp lands at pc+86; RAX/RCX raw nests.  Build the niblen(16(i+1))
       bound + pop_len4 + rax_red0 + head-guard1 ja TAKEN, then resolve RIP s71 -> pc+399. *)
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) <= 256` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+12`] OUTLEN0_LE_256_FROM_SUBITER_ETA2) THEN
      ANTS_TAC THENL
       [CONJ_TAC THENL
         [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC;
   (* ETA2_SI4_BODY4_TAC's RULE_ASSUM rewrote the mid-exit hyp
             `niblen(16i+12)<=248` into `acc3<=248` via the ACC3_IDENT fact
             `niblen(16i+12)=acc3`, so the antecedent is no longer present in the
             original form.  Accept it whether it survives as `niblen(16i+12)<=248`
             OR as `acc3<=248`: rewrite the goal via the ident fact (if present)
             then accept acc3<=248. *)
          FIRST[FIRST_ASSUM ACCEPT_TAC;
                (FIRST_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3` then SUBST1_TAC th else NO_TAC) THEN
                 FIRST_ASSUM ACCEPT_TAC)]]; ALL_TAC] THEN
      REWRITE_TAC[ARITH_RULE `(16*i+12)+4 = 16*(i+1)`; ARITH_RULE `16*i+16=16*(i+1)`]; ALL_TAC] THEN
    (* bridge4: acc3 + block3len = niblen_sample(16(i+1))                      *)
    SUBGOAL_THEN `acc3 + LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+12,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i+12`] SUBITER_BRIDGE_ETA2) THEN
      ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 136` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=136` THEN ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES; ARITH_RULE `(16*i+12)+4 = 16*(i+1)`; ARITH_RULE `16*i+16 = 16*(i+1)`] THEN
      FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3` then MP_TAC th else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA2_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    (* niblen(16(i+1)) < 2^32 (for JA_TAKEN_GT / RAX_NEST_REDUCE).             *)
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
     [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) <= 256` THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `read RIP s71 = word (pc + 399):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let find_a p = find p asms in
        let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
        let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
        let m8d_val = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8d:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))(concl th) | _ -> false) in
        let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
        let popcnt4 = REWRITE_RULE[m8d_val] (REWRITE_RULE[m8b_def; m8c_def]
           (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE3))) in
        let lanesum = rand(concl popcnt4) in
        let mb4 = find_a (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
           can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`24` | _ -> false))c) in
        let mb4_tm = concl mb4 in
        let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
        let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
        let blk16 = find_a (fun th -> is_eq(concl th) && (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                    (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
        let blk3_eq = el 3 (CONJUNCTS bb) in
        let block3 = `[word_subword (chunk0:int128) (96,8); word_subword chunk0 (104,8); word_subword chunk0 (112,8); word_subword chunk0 (120,8)]:byte list` in
        let block3len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block3)) in
        let bsum4_raw = prove(mk_imp(mb4_tm, mk_eq(lanesum, block3len_x)),
          DISCH_THEN(fun mbthm ->
            let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
              CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
            REWRITE_TAC mbs) THEN
          GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
          REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
          SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
        let pop_len4 = REWRITE_RULE[GSYM blk3_eq] (TRANS popcnt4 (MP bsum4_raw mb4)) in
        let bridge4 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_)))->true|_->false) in
        let lt32 = REWRITE_RULE[SYM bridge4] (find_a (fun th -> concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32`)) in
        let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
        let gt248 = REWRITE_RULE[SYM bridge4] (find_a (fun th -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`)) in
        let ja_taken = MP (ISPECL [mk_binop `(+):num->num->num` `acc3:num` `LENGTH(REJ_NIBBLES_ETA2 (SUB_LIST(16*i+12,4) inlist):int16 list)`; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
        (* POPCNT_BYTE3's masked arg is the byte-tower `word(val mask8d MOD 256):byte`
           (unlike POPCNT_BYTE1/BYTE2 which are i32-tower), so `pop_len4` already has the
           byte-tower LHS matching the RIP COND; the zbe (byte->i32) bridge needed for
           BYTE1/BYTE2 does not apply here.  Provide both the byte form and (only when it
           constructs) the zbe-bridged i32 form in the rewrite list, so REWRITE picks
           whichever matches the actual RIP COND tower — the try/with keeps a TRANS failure
           on the unused typed form from aborting the tactic. *)
        let poprws =
          pop_len4 ::
          (try [TRANS (AP_TERM `word_popcount:int32->num`
                  (MP (SPEC `val (mask8d:int64) MOD 256` zxbyte_eq)
                      (ARITH_RULE `val (mask8d:int64) MOD 256 < 256`))) pop_len4]
           with Failure _ -> []) in
        eta2_rip_mp memsafe 399 71 THEN
        REWRITE_TAC poprws THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja_taken] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* rebuild pop_len4/rax_red0/bridge4 for the RAX-final collapse below (ASSUME them now,
       AFTER stepping, so they don't interfere with the stepper). *)
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
      let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
      let m8d_val = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8d:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))(concl th) | _ -> false) in
      let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
      let popcnt4 = REWRITE_RULE[m8d_val] (REWRITE_RULE[m8b_def; m8c_def]
         (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE3))) in
      let lanesum = rand(concl popcnt4) in
      let mb4 = find_a (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
         can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`24` | _ -> false))c) in
      let mb4_tm = concl mb4 in
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) && (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in
      let block3 = `[word_subword (chunk0:int128) (96,8); word_subword chunk0 (104,8); word_subword chunk0 (112,8); word_subword chunk0 (120,8)]:byte list` in
      let block3len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA2`, block3)) in
      let bsum4_raw = prove(mk_imp(mb4_tm, mk_eq(lanesum, block3len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER_ETA2] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len4 = REWRITE_RULE[GSYM blk3_eq] (TRANS popcnt4 (MP bsum4_raw mb4)) in
      let bridge4 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_)))->true|_->false) in
      let lt32 = REWRITE_RULE[SYM bridge4] (find_a (fun th -> concl th = `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32`)) in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      ASSUME_TAC pop_len4 THEN ASSUME_TAC rax_red0) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    (* Do not rewrite 16*(i+1)->16*i+16 here: the postcondition midexit4_eta2_tm is stated
       in 16*(i+1) form, and bridge4/ntake are too — an early normalise to 16*i+16 leaves the
       RAX/memory conjuncts as niblen(16*(i+1))=niblen(16*i+16) unclosed.  Keep 16*(i+1)
       throughout; the RCX collapse reconciles its own 16*i+16 tail back to 16*(i+1) at the end. *)
    (* RAX collapse (pop_len4 -> rax_red0 -> bridge4 -> niblen(16(i+1))).  pop_len4 is the
       byte-tower (POPCNT_BYTE3) so REWRITE directly; zbe-bridged form kept as fallback. *)
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let pop_len4 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`mask8d:int64`))(concl th) | _ -> false) asl in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc3:num`))(concl th) | _ -> false) asl in
      let bridge4 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA2_BYTES",_),_)))->true|_->false) asl in
   (* The RAX-conjunct carries the explicit block3 list [chunk0 96,104,112,120];
         convert -> SUB_LIST(16i+12,4) via GSYM blk3_eq first, so bridge4
         (SUB_LIST form) folds it. *)
      let i_le = find_a (fun th -> concl th = `16 * i <= 120`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 136`) in
      let blk16 = find_a (fun th -> is_eq(concl th) && (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=120 ==> 16*i+16<=136`) i_le)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in
      let poprws =
        (snd pop_len4) ::
        (try [TRANS (AP_TERM `word_popcount:int32->num`
                (MP (SPEC `val (mask8d:int64) MOD 256` zxbyte_eq)
                    (ARITH_RULE `val (mask8d:int64) MOD 256 < 256`))) (snd pop_len4)]
         with Failure _ -> []) in
      REWRITE_TAC[GSYM blk3_eq] THEN
      REWRITE_TAC (poprws @ [snd rax_red0; snd bridge4])) THEN
   (* The RIP conjunct of the postcondition is the raw stepper
       COND `if <cond over niblen(16(i+1))> then pc+399 else pc+97`; after the RAX
       collapse folds it to a COND over niblen(16(i+1)), fold the COND -> pc+399 via
       JA_TAKEN_GT. Needs `248<niblen(16(i+1))` + `niblen(16(i+1))<2^32`
       (both in scope from the earlier SUBGOAL_THENs). *)
    W(fun (asl,w) ->
      let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                     (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`)
                           (ASSUME `LENGTH(REJ_SAMPLE_ETA2_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32`)) in
      REWRITE_TAC[ntake]) THEN
    (* RCX collapse: quadruple +4 nest (16i -> +4 -> +8 -> +12 -> +16)         *)
    MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
    MP_TAC(SPEC `16*i+8` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
    MP_TAC(SPEC `16*i+12` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=120` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+12)+4 = 16*i+16`] THEN
    (* After the RCX collapse two conjuncts remain — RCX
       `word(16*i+16) = word(16*(i+1))` and the memory store `read(mem...16*(i+1)...) = num_of_wordlist
       (...16*(i+1)...)`.  Normalise the goal's 16*(i+1) -> 16*i+16 (the SI4_BODY4 store fact is folded
       to SUB_LIST(0,16*i+16)), then ASM_REWRITE closes both (RCX by REFL, memory by the folded store
       assumption); REFL_TAC/ARITH mop up any residual. *)
    REWRITE_TAC[ARITH_RULE `16*(i+1) = 16*i+16`] THEN
    ASM_REWRITE_TAC[] THEN TRY(CONJ_TAC) THEN TRY REFL_TAC THEN TRY(AP_TERM_TAC THEN ARITH_TAC) THEN (if memsafe then disch else ALL_TAC);;

  (* ------------------------------------------------------------------------- *)
  (* Subroutine correctness with array_abs_bound matching CBMC contract        *)
  (* ensures(array_abs_bound(r, 0, return_value, MLDSA_ETA + 1)) for eta = 2.  *)
  (* ------------------------------------------------------------------------- *)

  (* NOTE: This must be kept in sync with the CBMC specification
   * in mldsa/src/native/x86_64/src/arith_native_x86_64.h *)

  (* Strengthen the base CORRECT postcondition with the array bound (the CBMC
     postcondition) and specialise the mc length. *)

  (* This statement needs type-variable invention; the file's stricter
     setting is restored immediately afterwards. *)
  let () = type_invention_error := false;;

  let () = type_invention_error := true;;

  (* ========================================================================= *)
  (* Memory safety.                                                            *)
  (* ========================================================================= *)

  (* ------------------------------------------------------------------------- *)
  (* Memory-safety section.  Rides on the generic constant-time / memory-safety *)
  (* infrastructure in consttime.ml (which transitively pulls equiv.ml and     *)
  (* supplies SIMPLIFY_MAYCHANGES_TAC / allowed_vars_e / EXISTS_E2_TAC /       *)
  (* SAFE_META_EXISTS_TAC / DISCHARGE_MEMACCESS_INBOUNDS_TAC, plus             *)
  (* memaccess_inbounds, MEMACCESS_INBOUNDS_APPEND and the CONTAINED_MODULO_*  *)
  (* lemmas).  This file sets type_invention_error := true globally for the    *)
  (* CORRECT proofs, but equiv.ml's MAYCHANGE-range helper only typechecks under *)
  (* the HOL default (false); on a cold load these deps load fresh here, so we *)
  (* toggle the default around the needs and then restore this file's setting. *)
  (* ------------------------------------------------------------------------- *)
end;;
