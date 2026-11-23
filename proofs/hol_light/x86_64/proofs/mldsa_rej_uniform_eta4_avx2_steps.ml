(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* The eta4 instruction proofs load these tactics after defining the
   machine code and the sampling specification. The tactics establish
   the arithmetic and state updates used by the vector and scalar loops. *)

needs "mldsa_native/x86_64/proofs/mldsa_rej_eta_avx2_common.ml";;

module Make_rej_uniform_eta4_steps(Input : sig
  val exec : thm * thm option array
  val code_length : thm
  val nibbles : thm
  val sample_bytes : thm
end) = struct
  let MLDSA_REJ_UNIFORM_ETA4_EXEC = Input.exec;;
  let LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC = Input.code_length;;
  let REJ_NIBBLES_ETA4 = Input.nibbles;;
  let REJ_SAMPLE_ETA4_BYTES = Input.sample_bytes;;

  (* SUBITER_STORE_POSTCOND: the full single-store value bridge. Given the     *)
  (* bytes256 read of the destination equals the vpshufb->vpmovsxbd store      *)
  (* value (PSHUFB pipeline form) and k<=8, the 4k stored bytes = the          *)
  (* num_of_wordlist of the k-element accepted block. Lane-match is discharged *)
  (* internally via STORE_LANE_EQ_REJBLOCK.                                    *)

  let SUBITER_STORE_POSTCOND = prove
   (`!A s (g:int128) m k.
       k <= 8 /\
       read (memory :> bytes256 A) s =
         (usimd8 (\b:byte. word_sx b:int32)
              (word_zx (word_zx (word_zx (usimd16 (\i. if bit 7 i then word 0:byte
                  else word_subword g (8 * val (word_subword i (0,4):4 word),8))
                (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256):int128):int64))
       ==> read (memory :> bytes(A, 4 * k)) s =
           num_of_wordlist (MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST g m)))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    MP_TAC(ISPECL [`A:int64`;
      `usimd8 (\b:byte. word_sx b:int32)
              (word_zx (word_zx (word_zx (usimd16 (\i. if bit 7 i then word 0:byte
                  else word_subword (g:int128) (8 * val (word_subword i (0,4):4 word),8))
                (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256):int128):int64)`;
      `MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST (g:int128) m))`;
      `k:num`; `s:x86state`] STORE_BYTES256_NUM_OF_WORDLIST) THEN
    ASM_REWRITE_TAC[] THEN
    ANTS_TAC THENL
     [REWRITE_TAC[LENGTH_MAP; LENGTH_SUB_LIST; LENGTH_PSHUFB_OUT_LIST] THEN
      CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
      REPEAT STRIP_TAC THEN MATCH_MP_TAC STORE_LANE_EQ_REJBLOCK THEN ASM_REWRITE_TAC[];
      DISCH_THEN(fun th -> REWRITE_TAC[th])]);;

  (*** print_literal_from_elf "x86_64/mldsa/mldsa_rej_uniform_eta4_avx2_asm.o";;
   ***)

  let REJ_NIBBLES_ETA4_EMPTY = prove
   (`REJ_NIBBLES_ETA4 [] = []`,
    REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; FILTER]);;

  let REJ_NIBBLES_ETA4_APPEND = prove
   (`!l1 l2. REJ_NIBBLES_ETA4(APPEND l1 l2) =
             APPEND (REJ_NIBBLES_ETA4 l1) (REJ_NIBBLES_ETA4 l2)`,
    REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES_APPEND; FILTER_APPEND]);;

  (* Loop step: peel off 16 bytes per iteration. Used in loop body.            *)
  let REJ_NIBBLES_ETA4_STEP_16 = prove
   (`!inlist:byte list. !i:num.
     16 * (i + 1) <= LENGTH inlist
     ==> REJ_NIBBLES_ETA4(SUB_LIST(0, 16 * (i + 1)) inlist) =
         APPEND (REJ_NIBBLES_ETA4(SUB_LIST(0, 16 * i) inlist))
                (REJ_NIBBLES_ETA4(SUB_LIST(16 * i, 16) inlist))`,
    REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM REJ_NIBBLES_ETA4_APPEND] THEN
    AP_TERM_TAC THEN
    SUBGOAL_THEN `16 * (i + 1) = 0 + 16 * i + 16` SUBST1_TAC THENL
     [ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[SUB_LIST_SPLIT; SUB_LIST_CLAUSES; APPEND; ADD_CLAUSES]);;

  (* Length bound on filtered nibbles - used for ABBREV bounds                 *)
  let LENGTH_REJ_NIBBLES_ETA4 = prove
   (`!l:byte list. LENGTH(REJ_NIBBLES_ETA4 l) <= 2 * LENGTH l`,
    GEN_TAC THEN REWRITE_TAC[REJ_NIBBLES_ETA4] THEN
    TRANS_TAC LE_TRANS `LENGTH(NIBBLES_OF_BYTES l:int16 list)` THEN
    CONJ_TAC THENL [REWRITE_TAC[LENGTH_FILTER]; ALL_TAC] THEN
    SPEC_TAC(`l:byte list`,`l:byte list`) THEN
    LIST_INDUCT_TAC THEN
    ASM_REWRITE_TAC[NIBBLES_OF_BYTES; LENGTH; NIBBLE_PAIR;
                    APPEND; LENGTH_APPEND; LE_0] THEN
    UNDISCH_TAC `LENGTH(NIBBLES_OF_BYTES t:int16 list) <=
                 2 * LENGTH(t:byte list)` THEN ARITH_TAC);;

  (* General prefix monotonicity of the accepted-nibble count: a shorter       *)
  (* input prefix accepts no more nibbles than a longer one. (niblen is        *)
  (* FILTER of NIBBLES_OF_BYTES, both monotone under list prefix.) Used to     *)
  (* derive the intra-block sub-iter bounds from the binding end-of-block      *)
  (* bound -- the clean-block control-flow argument: the SIMD loop has three   *)
  (* mid-iteration `ja` early-exits (after sub-iters 1,2,3), and a block runs  *)
  (* to completion (loops back) exactly when niblen at its END (offset         *)
  (* 16*j+12 covering all but the last sub-iter's stores; the 4th adds no      *)
  (* further guard) stays <= 248; this lemma propagates that bound to the      *)
  (* earlier sub-iter offsets so all three mid-iter ja's fall through.         *)
  let NIBLEN_PREFIX_MONO = prove
   (`!l:byte list a b. a <= b
       ==> LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,a) l):int16 list) <=
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,b) l):int16 list)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `SUB_LIST(0,b) (l:byte list) =
                  APPEND (SUB_LIST(0,a) l) (SUB_LIST(a,b-a) l)` SUBST1_TAC THENL
     [MP_TAC(ISPECL [`l:byte list`; `a:num`; `b - a`; `0`] SUB_LIST_SPLIT) THEN
      ASM_SIMP_TAC[ARITH_RULE `a <= b ==> a + (b - a) = b`; ADD_CLAUSES];
      REWRITE_TAC[REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND] THEN ARITH_TAC]);;

  (* Bridge: relate val (word_zx of byte) < 9 to val byte < 9, useful for      *)
  (* the popcnt-to-FILTER bridge in each sub-iter.                             *)
  let VAL_WORD_ZX_BYTE_LT_9 = prove
   (`!b:byte. (val (word_zx b:int16) < 9) <=> (val b < 9)`,
    GEN_TAC THEN AP_THM_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC VAL_WORD_ZX THEN
    REWRITE_TAC[DIMINDEX_8; DIMINDEX_16] THEN ARITH_TAC);;

  (* SUB_ITER_TAC: processes one of the 4 sub-iterations.                      *)
  (* Parameters:                                                               *)
  (*   start   - state index where this sub-iter begins (e.g. 35 for k=2)      *)
  (*   stop    - state index where this sub-iter ends (e.g. 47 for k=2)        *)
  (*   sub_pc  - PC offset where this sub-iter's first instr is located        *)
  (*   end_pc  - PC offset of the cmp-eax-0xf8 (after popcntl/add/shr/add)*)
  (*   k       - sub-iter index (0..3): 0 uses extracted xmm5 directly;        *)
  (*             1 uses vpsrldq xmm5,8; 2 uses vextracti128 $1; 3 uses         *)
  (*             vpsrldq xmm5,8 again                                          *)
  (*   chunk_off - byte offset within the 16-byte block (0, 4, 8, or 12)       *)
  (*                                                                           *)
  (* This tactic is conceptual; calling it requires the full pipeline of       *)
  (* (1) establish RIP=word(pc + sub_pc) via JA-not-taken,                     *)
  (* (2) X86_STEPS_TAC stop-start instructions,                                *)
  (* (3) bridge popcnt -> LENGTH FILTER via FILTER_LT_9_LENGTH_8,              *)
  (* (4) bridge vmovdqu store data -> num_of_wordlist of accepted nibbles      *)
  (*     (an 8-way ASM_CASES_TAC + WORD_BLAST),                                *)
  (* (5) update outlen invariant: outlen' = outlen + popcnt_k.                 *)
  (* These are too dependent on local state to abstract cleanly, but the       *)
  (* shape is identical for k=0..3.                                            *)

  (* REJ_SAMPLE_ETA4_BYTES decomposition: append on lists.                     *)
  let REJ_SAMPLE_ETA4_BYTES_APPEND = prove
   (`!l1 l2:byte list. REJ_SAMPLE_ETA4_BYTES (APPEND l1 l2) =
                       APPEND (REJ_SAMPLE_ETA4_BYTES l1) (REJ_SAMPLE_ETA4_BYTES l2)`,
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4_APPEND;
                MAP_APPEND]);;

  (* For sub-iter k (0 <= k <= 3), the contribution to outlen is               *)
  (* LENGTH(REJ_NIBBLES_ETA4 [b_(4k); ...; b_(4k+3)])                          *)
  (* Equivalently in int32 form:                                               *)
  (* LENGTH(REJ_SAMPLE_ETA4_BYTES [b_(4k); ...; b_(4k+3)])                     *)
  let LENGTH_REJ_SAMPLE_ETA4_BYTES = prove
   (`!l:byte list.
       LENGTH(REJ_SAMPLE_ETA4_BYTES l:int32 list) =
       LENGTH(REJ_NIBBLES_ETA4 l:int16 list)`,
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP]);;

  (* The popcnt of the low byte of any int32 is at most 8. Used to bound       *)
  (* the increment to RAX from popcntl in each sub-iteration.                  *)
  let VPSUBB_SIGN_BIT_LT_9 = prove
   (`!a:byte. val a < 16
       ==> (bit 7 (word_sub a (word 9):byte) <=> val a < 9)`,
    GEN_TAC THEN DISCH_TAC THEN
    REWRITE_TAC[BIT_VAL; DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[VAL_WORD_SUB; DIMINDEX_8; VAL_WORD] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    ASM_CASES_TAC `val(a:byte) < 9` THEN ASM_REWRITE_TAC[] THENL
     [SUBGOAL_THEN `(val(a:byte) + 247) MOD 256 = val a + 247`
      SUBST1_TAC THENL
       [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC(MESON[ODD; ARITH_RULE `ODD 1`] `n = 1 ==> ODD n`) THEN
      MATCH_MP_TAC DIV_UNIQ THEN
      EXISTS_TAC `val(a:byte) + 119` THEN ASM_ARITH_TAC;
      REWRITE_TAC[NOT_ODD] THEN
      SUBGOAL_THEN `(val(a:byte) + 247) MOD 256 = val a - 9`
      SUBST1_TAC THENL
       [SUBGOAL_THEN `val(a:byte) + 247 = (val a - 9) + 1 * 256`
        SUBST1_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        REWRITE_TAC[MOD_MULT_ADD] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC;
        ALL_TAC] THEN
      SIMP_TAC[DIV_LT; EVEN] THEN ASM_ARITH_TAC]);;

  (* Generalization of GATHER_FILTERED_IDX_8 post-composed with a value map f: *)
  (* gathering f-of-element at the positions where P holds equals MAP f of the *)
  (* P-FILTERed list. Used at the vmovdqu store where the gathered (compacted) *)
  (* bytes are sign-extended (f = word_sx) and the predicate P selects accepted *)
  (* nibbles. Keeps the value function f and predicate P independent, matching *)
  (* the asm where pshufb gathers the (4-nibble) vector while the mask predicate *)
  (* is on the nibble value.                                                   *)
  let SUBITER_STORE = prove
   (`!(g:int128) (m:byte) (n0:byte) n1 n2 n3 n4 n5 n6 n7.
      val n0 < 16 /\ val n1 < 16 /\ val n2 < 16 /\ val n3 < 16 /\
      val n4 < 16 /\ val n5 < 16 /\ val n6 < 16 /\ val n7 < 16 /\
      (!j. j < 8 ==> (bit j m <=> val(EL j [n0;n1;n2;n3;n4;n5;n6;n7]:byte) < 9)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
                     word_sub (word 4) (EL j [n0;n1;n2;n3;n4;n5;n6;n7]))
      ==> SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m) =
          MAP (\x:byte. word_sub (word 4) x)
              (FILTER (\x:byte. val x < 9) [n0;n1;n2;n3;n4;n5;n6;n7])`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`g:int128`; `val(m:byte)`] PSHUFB_ACCEPTED_PREFIX_NUM) THEN
    REWRITE_TAC[WORD_VAL] THEN
    ANTS_TAC THENL
     [MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC;
      DISCH_THEN SUBST1_TAC] THEN
    REWRITE_TAC[ACC_IDX] THEN
    MP_TAC(ISPECL [`\x:byte. word_sub (word 4) x:byte`; `\x:byte. val x < 9`;
                   `n0:byte`;`n1:byte`;`n2:byte`;`n3:byte`;`n4:byte`;`n5:byte`;`n6:byte`;`n7:byte`]
                  GATHER_FILTER_MAP_IDX_8) THEN
    REWRITE_TAC[] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
    SUBGOAL_THEN
     `(!j. MEM j [0;1;2;3;4;5;6;7] ==> (bit j (m:byte) <=> val(EL j [n0;n1;n2;n3;n4;n5;n6;n7]:byte) < 9)) /\
      (!j. MEM j [0;1;2;3;4;5;6;7] ==> word_subword (g:int128) (8*j,8):byte =
                     word_sub (word 4) (EL j [n0;n1;n2;n3;n4;n5;n6;n7]))`
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

  (* For an accepted nibble (n < 9), the byte-width and int16-width forms of the *)
  (* eta coefficient (4 - n) sign-extend to the SAME int32. Needed because the *)
  (* asm computes 4-nibble in byte lanes (vpsubb) then vpmovsxbd, while the spec *)
  (* uses int16 nibbles; both give word(4-n):int32 for n<9 (no underflow since *)
  (* n<=4 gives 4-n, and 5..8 give the sign-extended negative). 9-way blast.   *)
  let SX_SUB4_BYTE_EQ_INT16 = prove
   (`!n. n < 9
         ==> word_sx(word_sub (word 4:byte) (word n:byte)):int32 =
             word_sx(word_sub (word 4:int16) (word n:int16)):int32`,
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(DISJ_CASES_TAC o MATCH_MP (ARITH_RULE
      `n < 9 ==> n=0\/n=1\/n=2\/n=3\/n=4\/n=5\/n=6\/n=7\/n=8`)) THEN
    POP_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC) THEN
    CONV_TAC WORD_BLAST);;

  (* SUBITER STORE (int32 form) — the per-sub-iter store-value lemma keyed to  *)
  (* numeric nibble values. Given gather byte j = (4 - v_j) and mask bit j =   *)
  (* (v_j < 9), the 8-int32 vpmovsxbd output, truncated to popcount(m) lanes,  *)
  (* equals MAP (\v. word_sx(word_sub 4 v)) over the accepted nibbles — i.e. the *)
  (* int32 eta coefficients in compacted order. This is exactly the vmovdqu    *)
  (* store contribution of one sub-iter; instantiated 4x and composed over the *)
  (* four 4-byte blocks to give the iteration's REJ_SAMPLE step.               *)
  let SUBITER_STORE_INT32 = prove
   (`!(g:int128) (m:byte) v0 v1 v2 v3 v4 v5 v6 v7.
      v0<16/\v1<16/\v2<16/\v3<16/\v4<16/\v5<16/\v6<16/\v7<16 /\
      (!j. j < 8 ==> (bit j m <=> EL j [v0;v1;v2;v3;v4;v5;v6;v7] < 9)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
                     word_sub (word 4) (word(EL j [v0;v1;v2;v3;v4;v5;v6;v7]):byte))
      ==> MAP (\b:byte. word_sx b:int32)
              (SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m)) =
          MAP (\v. word_sx(word_sub (word 4:int16) (word v)):int32)
              (FILTER (\v. v < 9) [v0;v1;v2;v3;v4;v5;v6;v7])`,
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
    ASM_SIMP_TAC[SX_SUB4_BYTE_EQ_INT16]);;

  (* Push a num->int16 word-cast through MAP/FILTER: gathering f over the int16 *)
  (* P-filtered (word-cast) list equals gathering (f o word) over the numeric  *)
  (* (P o word)-filtered list. Used to convert SUBITER_STORE_INT32's numeric   *)
  (* nibble form to the spec's int16 NIBBLES_OF_BYTES form.                    *)
  let FILTER_VAL_WORD_NIB = prove
   (`!L:num list. (!v. MEM v L ==> v < 16)
       ==> FILTER (\v. val(word v:int16) < 9) L = FILTER (\v. v < 9) L`,
    LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; MEM] THEN
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(word h:int16) = h` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_16] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `h:num`) THEN REWRITE_TAC[MEM] THEN ARITH_TAC;
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `FILTER (\v. val(word v:int16) < 9) t = FILTER (\v. v < 9) t`
      SUBST1_TAC THENL
     [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_MESON_TAC[MEM]; ALL_TAC] THEN
    REWRITE_TAC[]);;

  (* SUBITER STORE (spec form) — the body-ready per-sub-iter store lemma.      *)
  (* Given mask m = accept predicate on the 8 nibbles of a 4-byte block        *)
  (* [b0;b1;b2;b3] (in NIBBLES_OF_BYTES order: lo,hi per byte) and gather byte *)
  (* j = (4 - nibble_j), the int32 vmovdqu store of one sub-iter (truncated to *)
  (* popcount(m) lanes) equals REJ_SAMPLE_ETA4_BYTES [b0;b1;b2;b3]. The two    *)
  (* hypotheses are discharged in the loop body from the proven nibble-extract *)
  (* and bound/mask (VPSUBB_SIGN_BIT_LT_9, VMOVMSKB) lane lemmas.              *)
  (* Instantiated 4x (one per sub-iter) and composed over the four 4-byte      *)
  (* blocks to give the full iteration's contribution.                         *)
  let SUBITER_STORE_SPEC = prove
   (`!(g:int128) (m:byte) (b0:byte) b1 b2 b3.
      (!j. j < 8 ==> (bit j m <=>
          EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16] < 9)) /\
      (!j. j < 8 ==> word_subword g (8*j,8):byte =
          word_sub (word 4) (word(EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16]):byte))
      ==> MAP (\b:byte. word_sx b:int32)
              (SUB_LIST(0, LENGTH(ACC_IDX m)) (PSHUFB_OUT_LIST g m)) =
          REJ_SAMPLE_ETA4_BYTES [b0;b1;b2;b3]`,
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
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4] THEN
    SUBGOAL_THEN
     `NIBBLES_OF_BYTES [b0;b1;b2;b3] =
      MAP (word:num->int16)
          [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
           val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16]`
     SUBST1_TAC THENL
     [REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; MAP]; ALL_TAC] THEN
    MP_TAC(ISPECL [`\x:int16. word_sx(word_sub (word 4) x):int32`; `\x:int16. val x < 9`;
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
    REWRITE_TAC[] THEN
    ASM_SIMP_TAC[FILTER_VAL_WORD_NIB]);;

  (* General length bound: at most 2 nibbles per byte.                         *)
  let LENGTH_REJ_SAMPLE_ETA4_BYTES_BOUND = prove
   (`!l:byte list. LENGTH(REJ_SAMPLE_ETA4_BYTES l:int32 list) <= 2 * LENGTH l`,
    GEN_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; LENGTH_REJ_NIBBLES_ETA4]);;

  (* Per-sub-iter monotonicity bounds: partial outlen at sub-iter k is at      *)
  (* most outlen at end of main iter (= 16-byte chunk). Used to show           *)
  (* JA-not-taken for intermediate sub-iters when end-of-iter outlen ≤ 248.    *)

  (* Generic prefix monotonicity for REJ_SAMPLE_ETA4_BYTES (int32 form).       *)
  let LENGTH_REJ_SAMPLE_ETA4_BYTES_APPEND_LE = prove
   (`!l1 l2:byte list.
       LENGTH(REJ_SAMPLE_ETA4_BYTES l1:int32 list) <=
       LENGTH(REJ_SAMPLE_ETA4_BYTES (APPEND l1 l2):int32 list)`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_APPEND; LENGTH_APPEND] THEN ARITH_TAC);;

  (* SHR by 8/16/24 commutes with low-byte extraction.                         *)
  (* After `shr r8d, 8`, the low 8 bits of r8d are bits 8..15 of original.     *)
  (* Used to identify the per-sub-iter mask byte after each SHR.               *)
  let LENGTH_FILTER_LT_9_MAP_WORD_ZX = prove
   (`!l:byte list. LENGTH(FILTER (\x:int16. val x < 9) (MAP word_zx l)) =
                    LENGTH(FILTER (\x:byte. val x < 9) l)`,
    LIST_INDUCT_TAC THEN
    REWRITE_TAC[MAP; FILTER; LENGTH; VAL_WORD_ZX_BYTE_LT_9] THEN
    COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

  (* Array_bound element lemma: each element of REJ_SAMPLE_ETA4_BYTES l is     *)
  (* in [-4, 4]. This is the per-element form of the CBMC array_bound          *)
  (* postcondition.                                                            *)
  let REJ_SAMPLE_ETA4_BYTES_COEFF_BOUND = prove
   (`!(l:byte list) c:int32.
       MEM c (REJ_SAMPLE_ETA4_BYTES l)
       ==> --(&4):int <= ival c /\ ival c <= &4`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4; MEM_MAP; MEM_FILTER] THEN
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THENL
     [SUBGOAL_THEN `(x:int16) = word(val x)` SUBST1_TAC THENL
       [REWRITE_TAC[WORD_VAL]; ALL_TAC] THEN
      UNDISCH_TAC `val(x:int16) < 9` THEN
      SPEC_TAC(`val(x:int16)`,`n:num`) THEN GEN_TAC THEN DISCH_TAC THEN
      SUBGOAL_THEN `n IN {0,1,2,3,4,5,6,7,8}` MP_TAC THENL
       [REWRITE_TAC[IN_INSERT; NOT_IN_EMPTY] THEN ASM_ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[IN_INSERT; NOT_IN_EMPTY] THEN STRIP_TAC THEN
      ASM_REWRITE_TAC[] THEN
      CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN CONV_TAC INT_REDUCE_CONV;
      SUBGOAL_THEN `(x:int16) = word(val x)` SUBST1_TAC THENL
       [REWRITE_TAC[WORD_VAL]; ALL_TAC] THEN
      UNDISCH_TAC `val(x:int16) < 9` THEN
      SPEC_TAC(`val(x:int16)`,`n:num`) THEN GEN_TAC THEN DISCH_TAC THEN
      SUBGOAL_THEN `n IN {0,1,2,3,4,5,6,7,8}` MP_TAC THENL
       [REWRITE_TAC[IN_INSERT; NOT_IN_EMPTY] THEN ASM_ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[IN_INSERT; NOT_IN_EMPTY] THEN STRIP_TAC THEN
      ASM_REWRITE_TAC[] THEN
      CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN CONV_TAC INT_REDUCE_CONV]);;

  (* Strengthen-post lemma: an `ensures` whose post implies a stronger post    *)
  (* gives an `ensures` for the stronger post.                                 *)
  (* Used to derive SUBROUTINE_CORRECT (with array_bound) from CORRECT         *)
  (* (without array_bound) by showing the array_bound holds at exit.           *)
  let LENGTH_SUB_LIST_REJ_SAMPLE_ETA4_BYTES = prove
   (`!(l:byte list).
       LENGTH(SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES l):int32 list) <= 256`,
    GEN_TAC THEN REWRITE_TAC[LENGTH_SUB_LIST] THEN ARITH_TAC);;

  (* The exact form needed for SUBROUTINE_CORRECT postcondition:               *)
  (*   (!i. i < outlen ==> ival(EL i outlist) < &5 /\ -- &5 < ival(EL i ...))  *)
  (* matching PR #1040's aarch64 eta4 SUBROUTINE_CORRECT.                      *)
  let REJ_SAMPLE_ETA4_BYTES_EL_BOUND = prove
   (`!(l:byte list) i.
       i < LENGTH(SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES l):int32 list)
       ==> ival(EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES l):int32 list)) < &5 /\
           -- &5 < ival(EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES l):int32 list))`,
    REPEAT GEN_TAC THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`l:byte list`;
                   `EL i (SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES (l:byte list)):int32 list):int32`]
                  REJ_SAMPLE_ETA4_BYTES_COEFF_BOUND) THEN
    ANTS_TAC THENL
     [MP_TAC(ISPECL [`REJ_SAMPLE_ETA4_BYTES (l:byte list):int32 list`; `256`]
                    SUB_LIST_TOPSPLIT) THEN
      DISCH_THEN(fun th ->
        GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV) [SYM th]) THEN
      REWRITE_TAC[MEM_APPEND] THEN DISJ1_TAC THEN
      MATCH_MP_TAC MEM_EL THEN ASM_REWRITE_TAC[];
      INT_ARITH_TAC]);;

  (* MAJOR BRIDGE: byte-form LENGTH FILTER for the 8 nibbles extracted from    *)
  (* 4 input bytes (after VPMOVZXBW + VPSLLW + VPOR + VPAND) equals            *)
  (* LENGTH(REJ_NIBBLES_ETA4 [b0;b1;b2;b3]).                                   *)
  let LENGTH_FILTER_BYTE_NIBBLES_4_BYTES = prove
   (`!(b0:byte) (b1:byte) (b2:byte) (b3:byte).
       LENGTH(FILTER (\x:byte. val x < 9)
               [word(val b0 MOD 16); word(val b0 DIV 16);
                word(val b1 MOD 16); word(val b1 DIV 16);
                word(val b2 MOD 16); word(val b2 DIV 16);
                word(val b3 MOD 16); word(val b3 DIV 16)]) =
       LENGTH(REJ_NIBBLES_ETA4 [b0;b1;b2;b3]:int16 list)`,
    REPEAT GEN_TAC THEN
    REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THEN
    CONV_TAC SYM_CONV THEN
    MP_TAC(SPEC
     `[word(val(b0:byte) MOD 16); word(val(b0:byte) DIV 16);
       word(val(b1:byte) MOD 16); word(val(b1:byte) DIV 16);
       word(val(b2:byte) MOD 16); word(val(b2:byte) DIV 16);
       word(val(b3:byte) MOD 16); word(val(b3:byte) DIV 16)]:byte list`
     LENGTH_FILTER_LT_9_MAP_WORD_ZX) THEN
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

  (* ------------------------------------------------------------------------- *)
  (* movzbl/popcnt low-byte reduction for the clean loop body.  After the      *)
  (* movzbl r8b->r10d the popcnt operand is word_zx layers over                *)
  (* word(val mask8 MOD 256) where mask8 = word_zx(word(32-term vpmovmskb      *)
  (* bitval sum)); the low-8 popcount reduction collapses the whole popcnt to  *)
  (* the low-8 bitval sum bitval(p0)+..+bitval(p7), which then composes with   *)
  (* the maskbit bridge (p k = bit 7 of f1bnd byte k) to give the              *)
  (* block accept count.  Supporting: ADD256_MOD, LOW8_LT, MOD_RED.            *)
  (* ------------------------------------------------------------------------- *)

  let BITVAL_SUM_8_EQ_LENGTH_FILTER = prove
   (`!a0 a1 a2 a3 a4 a5 a6 a7:byte.
       bitval(val a0 < 9) + bitval(val a1 < 9) + bitval(val a2 < 9) + bitval(val a3 < 9) +
       bitval(val a4 < 9) + bitval(val a5 < 9) + bitval(val a6 < 9) + bitval(val a7 < 9) =
       LENGTH(FILTER (\x:byte. val x < 9) [a0;a1;a2;a3;a4;a5;a6;a7])`,
    REPEAT GEN_TAC THEN REWRITE_TAC[FILTER; LENGTH] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH; BITVAL_CLAUSES]) THEN ARITH_TAC);;

  (* ACC_LENGTH_EQ_FILTER: given the per-lane mask<->accept correspondence, the accept *)
  (* count LENGTH(ACC_IDX m) equals LENGTH(FILTER (<9) [the 8 nibble bytes]) = LENGTH *)
  (* (REJ_NIBBLES block) = LENGTH(REJ_SAMPLE block). Width reconciliation for the *)
  (* SUBITER_STORE_EXTEND fold. (Placed after BITVAL_SUM_8_EQ_LENGTH_FILTER which it uses.)*)
  let ACC_LENGTH_EQ_FILTER = prove
   (`!(m:byte) (n0:byte) (n1:byte) (n2:byte) (n3:byte) (n4:byte) (n5:byte) (n6:byte) (n7:byte).
       (bit 0 m <=> val n0 < 9) /\ (bit 1 m <=> val n1 < 9) /\ (bit 2 m <=> val n2 < 9) /\
       (bit 3 m <=> val n3 < 9) /\ (bit 4 m <=> val n4 < 9) /\ (bit 5 m <=> val n5 < 9) /\
       (bit 6 m <=> val n6 < 9) /\ (bit 7 m <=> val n7 < 9)
       ==> LENGTH(ACC_IDX m) = LENGTH(FILTER (\x:byte. val x < 9) [n0;n1;n2;n3;n4;n5;n6;n7])`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_ACC_IDX_BITSUM] THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[BITVAL_SUM_8_EQ_LENGTH_FILTER]);;

  let SUBITER_OUTLEN_BOUND_1 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i, 4) inlist):int16 list) <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 12 = 16`]
                       (ISPECL [`inlist:byte list`; `4`; `12`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th ->
      RULE_ASSUM_TAC(REWRITE_RULE[th; REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND])) THEN
    ASM_ARITH_TAC);;

  let SUBITER_OUTLEN_BOUND_2 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 4, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 8 = 16`]
                       (ISPECL [`inlist:byte list`; `8`; `8`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th2; REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND;
                                  th1]))) THEN
    ASM_ARITH_TAC);;

  let SUBITER_OUTLEN_BOUND_3 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 4, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 8, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `12 + 4 = 16`]
                       (ISPECL [`inlist:byte list`; `12`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 4 = 12`]
                       (ISPECL [`inlist:byte list`; `8`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 -> DISCH_THEN(fun th3 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th3; th2; th1; REJ_NIBBLES_ETA4_APPEND;
                                  LENGTH_APPEND])))) THEN
    ASM_ARITH_TAC);;

  (* Byte structure of the full nibble-extraction SIMD chain (vpmovzxbw +
     vpsllw $4 + vpor + vpand mask) against the CONCRETE 0x0F0F0F0F broadcast
     constant carried in the loop invariant (YMM2). Output byte 2j = low
     nibble of input byte j (= val MOD 16), byte 2j+1 = high nibble (val DIV
     16) -- matching NIBBLES_OF_BYTES order. This is what reduces the vpand
     result (opaque without the YMM2 invariant) to nibble form in CLEAN_BODY. *)
  let F0NIB_BYTES = prove
   (`!q:int128.
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (0,8):byte =
       word(val(word_subword q (0,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (8,8):byte =
       word(val(word_subword q (0,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (16,8):byte =
       word(val(word_subword q (8,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (24,8):byte =
       word(val(word_subword q (8,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (32,8):byte =
       word(val(word_subword q (16,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (40,8):byte =
       word(val(word_subword q (16,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (48,8):byte =
       word(val(word_subword q (24,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (56,8):byte =
       word(val(word_subword q (24,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (64,8):byte =
       word(val(word_subword q (32,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (72,8):byte =
       word(val(word_subword q (32,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (80,8):byte =
       word(val(word_subword q (40,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (88,8):byte =
       word(val(word_subword q (40,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (96,8):byte =
       word(val(word_subword q (48,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (104,8):byte =
       word(val(word_subword q (48,8):byte) DIV 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (112,8):byte =
       word(val(word_subword q (56,8):byte) MOD 16)) /\
      (word_subword (word_and (word_or (usimd16 (\b:byte. word_zx b:int16) q:int256)
                (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) q:int256):int256))
          (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)) (120,8):byte =
       word(val(word_subword q (56,8):byte) DIV 16))`,
    GEN_TAC THEN
    REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
    CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_BLAST);;

  (* ------------------------------------------------------------------------- *)
  (* HIGH-HALF byte lemmas (output bytes 16..31 of the 32-byte SIMD vectors,   *)
  (* i.e. bit offsets 128..248).  Sub-iters 3 and 4 read the high 128-bit lane *)
  (* of f0sub/f1bnd (via `vextracti128 $1`), which holds the nibbles of input  *)
  (* chunk bytes 8..15.  The low-half F0NIB_BYTES lemma only covers bytes      *)
  (* 0..15; these are the verbatim analogues for bytes 16..31, proved by the   *)
  (* identical recipes.                                                        *)
  let F0NIB_BYTES_HI =
    let chain = rand(rator(lhand(hd(conjuncts(snd(strip_forall(concl F0NIB_BYTES))))))) in
    let mk_cj bi =
      let off = 128 + 8*bi in
      let qbyte = 8 + bi/2 in
      let hi = (bi mod 2 = 1) in
      let lhs = mk_comb(mk_comb(`word_subword:int256->num#num->byte`, chain),
                        mk_pair(mk_small_numeral off, `8`)) in
      let v = mk_comb(`val:byte->num`, mk_comb(mk_comb(`word_subword:int128->num#num->byte`,`q:int128`),
                        mk_pair(mk_small_numeral(8*qbyte), `8`))) in
      let nib = if hi then mk_binop `DIV` v `16` else mk_binop `MOD` v `16` in
      mk_eq(lhs, mk_comb(`word:num->byte`, nib)) in
    prove(mk_forall(`q:int128`, end_itlist (curry mk_conj) (map mk_cj (0--15))),
      GEN_TAC THEN
      REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;
                  DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
      CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_BLAST);;

  (* ------------------------------------------------------------------------- *)
  (* Mid-guard / partial-outlen lemmas for CLEAN_BODY's sub-iter `ja` checks.  *)
  (* After sub-iter 1 (which appends the first 4-byte block), the running      *)
  (* count RAX = outlen0 + |accepted nibbles in block 0| = niblen(16i+4); the  *)
  (* mid-iter `ja $248` must NOT fire on a clean iteration (i+1 < N), i.e. that *)
  (* partial count is <= 248 because it is a prefix of niblen(16(i+1)) <= 248. *)

  (* SCALAR TAIL HELPER: REJ_SAMPLE_ETA4_BYTES on a single byte = at most 2    *)
  (* int32s, computed from low nibble (b MOD 16) and high nibble (b DIV 16).*)
  (* The scalar tail loop processes one byte per iteration this way.           *)
  let REJ_SAMPLE_ETA4_BYTES_1 = prove
   (`!b:byte.
       REJ_SAMPLE_ETA4_BYTES [b] =
       APPEND
        (if val b MOD 16 < 9
         then [word_sx(word_sub (word 4:int16) (word(val b MOD 16))):int32]
         else [])
        (if val b DIV 16 < 9
         then [word_sx(word_sub (word 4:int16) (word(val b DIV 16))):int32]
         else [])`,
    GEN_TAC THEN
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4;
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

  (* Length bound on REJ_SAMPLE_ETA4_BYTES restricted to a SUB_LIST prefix.    *)
  let LENGTH_REJ_SAMPLE_ETA4_BYTES_SUB_LIST_BOUND = prove
   (`!(inlist:byte list) k.
       k <= LENGTH inlist
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,k) inlist):int32 list) <= 2 * k`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPEC `SUB_LIST(0, k) (inlist:byte list):byte list`
                LENGTH_REJ_SAMPLE_ETA4_BYTES_BOUND) THEN
    ASM_SIMP_TAC[LENGTH_SUB_LIST_0]);;

  (* Prefix lemma: REJ_SAMPLE_ETA4_BYTES has a prefix structure on SUB_LIST    *)
  let REJ_SAMPLE_ETA4_SUB_LIST_PREFIX = prove
   (`!k (l:byte list).
       k <= LENGTH l
       ==> ?rest:int32 list.
           APPEND (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,k) l)) rest =
           REJ_SAMPLE_ETA4_BYTES l`,
    REPEAT STRIP_TAC THEN
    EXISTS_TAC `REJ_SAMPLE_ETA4_BYTES (SUB_LIST(k, LENGTH l - k) l):int32 list` THEN
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; GSYM MAP_APPEND] THEN
    AP_TERM_TAC THEN
    REWRITE_TAC[REJ_NIBBLES_ETA4; GSYM FILTER_APPEND] THEN
    AP_TERM_TAC THEN
    REWRITE_TAC[GSYM NIBBLES_OF_BYTES_APPEND] THEN
    AP_TERM_TAC THEN
    MP_TAC(ISPECL [`l:byte list`; `k:num`] SUB_LIST_TOPSPLIT) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th -> GEN_REWRITE_TAC RAND_CONV [SYM th]) THEN
    REFL_TAC);;

  (* Step lemma: outlen after processing one more byte equals current outlen   *)
  (* + contribution of that byte (0, 1, or 2 elements).                        *)
  let SUB_LIST_STEP_BYTE = prove
   (`!(l:byte list) (k:num).
       k < LENGTH l
       ==> SUB_LIST(0, k+1) l = APPEND (SUB_LIST(0, k) l) [EL k l]`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`l:byte list`; `k:num`; `1`; `0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ARITH_RULE `0 + k = k`] THEN DISCH_THEN SUBST1_TAC THEN
    AP_TERM_TAC THEN ASM_REWRITE_TAC[SUB_LIST_1]);;

  let REJ_SAMPLE_ETA4_BYTES_STEP_1 = prove
   (`!(l:byte list) (k:num).
       k < LENGTH l
       ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, k+1) l) =
           APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, k) l))
                  (REJ_SAMPLE_ETA4_BYTES [EL k l])`,
    REPEAT STRIP_TAC THEN
    ASM_SIMP_TAC[SUB_LIST_STEP_BYTE; REJ_SAMPLE_ETA4_BYTES_APPEND]);;

  (* SUB_LIST capping: when output already has length <= 256, the SUB_LIST(0,  *)
  (* 256) cap is a no-op. Used in scalar-tail final-state composition.         *)
  let SUB_LIST_BYTE_272 = prove
   (`!(l:byte list). LENGTH l = 272 ==> SUB_LIST(0, 272) l = l`,
    REPEAT STRIP_TAC THEN UNDISCH_TAC `LENGTH (l:byte list) = 272` THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN MATCH_ACCEPT_TAC SUB_LIST_LENGTH);;

  (* Per-byte helpers for the scalar tail proof. Three cases by which nibble   *)
  (* (low and/or high) is < 9 (accepted) or >= 9 (rejected).                   *)
  let REJ_SAMPLE_ETA4_BYTES_1_REJECT_BOTH = prove
   (`!b:byte. ~(val b MOD 16 < 9) /\ ~(val b DIV 16 < 9)
              ==> REJ_SAMPLE_ETA4_BYTES [b] = []`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA4_BYTES_1_LOW_ONLY = prove
   (`!b:byte. val b MOD 16 < 9 /\ ~(val b DIV 16 < 9)
              ==> REJ_SAMPLE_ETA4_BYTES [b] =
                  [word_sx(word_sub (word 4:int16) (word(val b MOD 16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA4_BYTES_1_HIGH_ONLY = prove
   (`!b:byte. ~(val b MOD 16 < 9) /\ val b DIV 16 < 9
              ==> REJ_SAMPLE_ETA4_BYTES [b] =
                  [word_sx(word_sub (word 4:int16) (word(val b DIV 16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_1; APPEND]);;

  let REJ_SAMPLE_ETA4_BYTES_1_BOTH = prove
   (`!b:byte. val b MOD 16 < 9 /\ val b DIV 16 < 9
              ==> REJ_SAMPLE_ETA4_BYTES [b] =
                  [word_sx(word_sub (word 4:int16) (word(val b MOD 16))):int32;
                   word_sx(word_sub (word 4:int16) (word(val b DIV 16))):int32]`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_1; APPEND]);;

  let LENGTH_REJ_SAMPLE_ETA4_BYTES_1 = prove
   (`!b:byte. LENGTH(REJ_SAMPLE_ETA4_BYTES [b] :int32 list) =
              (if val b MOD 16 < 9 then 1 else 0) +
              (if val b DIV 16 < 9 then 1 else 0)`,
    GEN_TAC THEN REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_1; LENGTH_APPEND] THEN
    COND_CASES_TAC THEN COND_CASES_TAC THEN REWRITE_TAC[LENGTH] THEN ARITH_TAC);;

  (* ===== INLINED CLEAN_BODY chain + exit-block assets =====                  *)

  (* ========================================================================= *)
  (* CLEAN_BODY full proof build. Uses EXEC, the store lemmas,                 *)
  (* SUBITER_STORE_SPEC, etc., and proves MLDSA_REJ_UNIFORM_ETA4_CLEAN_BODY.   *)
  (* ========================================================================= *)

  let EXEC = MLDSA_REJ_UNIFORM_ETA4_EXEC;;

  let LEN_RECONCILE = prove
   (`!(m:byte) (chunk0:int128).
       (!j. j < 8 ==> (bit j m <=>
          EL j [val(word_subword chunk0 (0,8):byte) MOD 16; val(word_subword chunk0 (0,8):byte) DIV 16;
                val(word_subword chunk0 (8,8):byte) MOD 16; val(word_subword chunk0 (8,8):byte) DIV 16;
                val(word_subword chunk0 (16,8):byte) MOD 16; val(word_subword chunk0 (16,8):byte) DIV 16;
                val(word_subword chunk0 (24,8):byte) MOD 16; val(word_subword chunk0 (24,8):byte) DIV 16] < 9))
       ==> LENGTH(ACC_IDX m) =
           LENGTH(REJ_SAMPLE_ETA4_BYTES [word_subword chunk0 (0,8); word_subword chunk0 (8,8);
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
      `word(val(word_subword (chunk0:int128) (24,8):byte) DIV 16):byte`] ACC_LENGTH_EQ_FILTER) THEN
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
      REWRITE_TAC[LENGTH_FILTER_BYTE_NIBBLES_4_BYTES; LENGTH_REJ_SAMPLE_ETA4_BYTES]]);;

  (* SUBITER_FOLD_STEP: reusable fold of one sub-iter's REJ block onto the running prefix.
     Given (a) the accept-count = block length [from LEN_RECONCILE], (b) the prefix store
     read(bytes(res, 4*LEN(REJ prefixbytes))) = nwl(REJ prefixbytes), and (c) this sub-iter's
     block store read(bytes(res + 4*LEN(REJ prefixbytes), 4*LEN(ACC_IDX m))) = nwl(REJ blk),
     conclude read(bytes(res, 4*LEN(REJ (prefixbytes++blk)))) = nwl(REJ (prefixbytes++blk)).
     Applies identically to all 4 sub-iters (prefixbytes = SUB_LIST(0,16i+4k), blk = next 4 bytes),
     turning prefixbytes++blk back into SUB_LIST(0,16i+4(k+1)). *)
  let SUBITER_FOLD_STEP = prove
   (`!res s (m:byte) (blk:byte list) (prefixbytes:byte list).
       LENGTH(ACC_IDX m) = LENGTH(REJ_SAMPLE_ETA4_BYTES blk:int32 list) /\
       read(memory:>bytes(res, 4*LENGTH(REJ_SAMPLE_ETA4_BYTES prefixbytes:int32 list))) s =
         num_of_wordlist(REJ_SAMPLE_ETA4_BYTES prefixbytes) /\
       read(memory:>bytes(word_add res (word(4*LENGTH(REJ_SAMPLE_ETA4_BYTES prefixbytes:int32 list))),
                          4*LENGTH(ACC_IDX m))) s =
         num_of_wordlist(REJ_SAMPLE_ETA4_BYTES blk)
       ==> read(memory:>bytes(res, 4*LENGTH(REJ_SAMPLE_ETA4_BYTES(APPEND prefixbytes blk):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(APPEND prefixbytes blk))`,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    MP_TAC(ISPECL [`res:int64`; `s:x86state`;
                   `REJ_SAMPLE_ETA4_BYTES prefixbytes:int32 list`;
                   `REJ_SAMPLE_ETA4_BYTES blk:int32 list`] SUBITER_STORE_EXTEND) THEN
    ANTS_TAC THENL
     [ASM_REWRITE_TAC[] THEN
      FIRST_X_ASSUM(fun th -> if can(find_term(fun u->u=`ACC_IDX (m:byte)`)) (concl th)
                              then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[];
      REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_APPEND; LENGTH_APPEND;
                  ARITH_RULE `4*a+4*b = 4*(a+b)`]]);;

  let maskbit_tgt =
    `!j. j < 8 ==> (bit j (word (val (mask8:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (0,8):byte) MOD 16;
           val(word_subword chunk0 (0,8):byte) DIV 16; val(word_subword chunk0 (8,8):byte) MOD 16;
           val(word_subword chunk0 (8,8):byte) DIV 16; val(word_subword chunk0 (16,8):byte) MOD 16;
           val(word_subword chunk0 (16,8):byte) DIV 16; val(word_subword chunk0 (24,8):byte) MOD 16;
           val(word_subword chunk0 (24,8):byte) DIV 16] < 9)`;;

  let clean_body_tm = `
     !res buf table (inlist:byte list) pc N (i:num) stackpointer.
          LENGTH inlist = 272 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          ~(N = 0) /\ i + 1 < N /\ 16 * (i + 1) <= 272 /\
          LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16 * (i+1)) inlist)) <= 248
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 52) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
                    read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
                    read RCX s = word(16*i) /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s = num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist)))
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 52) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                    read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
                    read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list)) /\
                    read RCX s = word(16*(i+1)) /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list))) s = num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist)))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM5; ZMM6] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,,
                MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* Sub-iter k (k>=1) popcount->length keystone lemmas.                       *)
  (* These generalize sub-iter 1's popeq/pop_len recipe to sub-iters 2,3,4 whose *)
  (* mask byte is R8 shifted right by 8*k bits.  Sub-iter 2's mask8b is reabbreved *)
  (* to a bare var before the movzbl read, giving the clean R10/R9 popcnt shape *)
  (* word_zx(word_zx(word(val mask8b MOD 256))) identical to sub-iter 1.       *)
  (* ========================================================================= *)

  (* SUBITER_OUTLEN_BOUND_4: the 5-term niblen sum through sub-iter 4 stays <=248. *)
  let SUBITER_OUTLEN_BOUND_4 = prove
   (`!(inlist:byte list) i.
       16*(i+1) <= LENGTH inlist /\
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16*(i+1)) inlist):int16 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 4, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 8, 4) inlist):int16 list) +
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i + 12, 4) inlist):int16 list)
           <= 248`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP_16) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN
     (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th; LENGTH_APPEND])) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `12 + 4 = 16`]
                       (ISPECL [`inlist:byte list`; `12`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `8 + 4 = 12`]
                       (ISPECL [`inlist:byte list`; `8`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    MP_TAC(REWRITE_RULE[ARITH_RULE `4 + 4 = 8`]
                       (ISPECL [`inlist:byte list`; `4`; `4`; `16*i`] SUB_LIST_SPLIT)) THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 -> DISCH_THEN(fun th3 ->
      RULE_ASSUM_TAC(REWRITE_RULE[th3; th2; th1; REJ_NIBBLES_ETA4_APPEND;
                                  LENGTH_APPEND])))) THEN
    ASM_ARITH_TAC);;

  (* --- maskbit_tgt_tac ---                                                   *)
  (* TAB1_TEQ_TAC: derive the sub-iter-1 table-load bridge teq                 *)
  (* `tab1 = word_zx(word_zx(word(num_of_wordlist(TABLE_ENTRY ...))))` at s13. *)
  (* Generator for the four per-sub-iter table-load teq tactics: read the vmovq  *)
  (* table load at state `rds`, MP TABLE_VMOVQ_READ with the mask<256 bound, then *)
  (* rewrite the YMM6 read at state `ymms` by the zx-collapse lemma.  Varies only *)
  (* in the two state indices, the mask var, and the RLT/R_EQ support lemmas.     *)
  let mk_tab_teq (rds:int) (ymms:int) (maskv:term) (rlt:thm) (req:thm) : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let rdst = mk_var("s"^string_of_int rds,`:x86state`)
      and ymmst = mk_var("s"^string_of_int ymms,`:x86state`) in
      let tblinv = find (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),v)),_) ->
           v=rdst && can(find_term(fun u->u=`mldsa_rej_uniform_table:byte list`)) (concl th) | _ -> false) asms in
      let mmod = mk_binop `MOD` (mk_comb(`val:int64->num`,maskv)) `256` in
      let tvr = MP (ISPECL[`table:int64`; mmod; rdst] TABLE_VMOVQ_READ) (CONJ tblinv rlt) in
      let ymm6 = find (fun th -> match concl th with
         Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("YMM6",_)),v)),_)-> v=ymmst |_->false) asms in
      ASSUME_TAC (REWRITE_RULE[req; tvr] ymm6));;

  let TAB1_TEQ_TAC : tactic = mk_tab_teq 13 14 `mask8:int64` RLT R_EQ;;

  (* --- pf_target_proof ---                                                   *)
  (* ===== pf_target proof for sub-iter 1 =====
     Establishes pshuf1 = pf_target by: SYM pshuf1-word_join def, rewrite tab1 via the
     genuine teq (tab1 = word_zx^k(word(nwl(TABLE_ENTRY(word(val mask8 MOD 256)))))) derived
     by TAB1_TEQ_TAC, expand usimd16, then COLLAPSE the redundant word_zx towers:
       - SUBWORD_ZX_LOW: word_subword(word_zx y)(lo,wid) = word_subword y (lo,wid) when lo+wid<=dimindex(P)
         (covers BOTH widening and narrowing zx, since only the low target bits matter)
       - ZX_128_256_128: word_zx(word_zx(x:int128):int256):int128 = x   (the f0sub gather-source g) *)
  (* Generator for the four per-sub-iter pshufb gather-target discharge tactics: *)
  (* find the `pshuf` word_join def + the `tab` TABLE_ENTRY eq by shape, then run *)
  (* the fixed rewrite/conv pipeline.  PF_PROOF{,_2,_3,_4} are instances.         *)
  let mk_pf_proof (pshuf:term) (tab:term) : tactic =
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

  let PF_PROOF : tactic = mk_pf_proof `pshuf1:int256` `tab1:int256`;;

  (* SUBWORD_USHR: word_subword(word_ushr x n)(lo,wid) = word_subword x (lo+n,wid). Needed for
     the >>64-shifted gather sources of sub-iters 2 and 4 (vpsrldq). *)
  (* Shared RIP-resolution step used by the mid-guard / mid-exit twins.  The     *)
  (* value chain grabs the assumption mentioning `pc + pcoff` directly; the      *)
  (* memory-safety chain must additionally require RIP on the LHS at state       *)
  (* `s<st>` (the anchored events fact also mentions `pc + pcoff`, so the bare    *)
  (* find_term would grab it and REFL_TAC would fail).                            *)
  (* EVENTS-ROBUST rip_mp (else-branch structural read-RIP guard):
     BOTH branches require a structural `read RIP _ = _` assumption, so a threaded
     `read events s = e` fact (whose EventJump targets embed pc+N) can never be
     selected on the SAFE clean-block/midexit proofs.  memsafe=true behaviour is
     unchanged (still pins the exact state var); memsafe=false additionally requires
     the read-RIP shape (neutral for the events-free CORRECT proofs). *)
  let rip_mp (memsafe:bool) (pcoff:int) (st:int) : tactic =
    let pctm = mk_binop `(+):num->num->num` `pc:num` (mk_small_numeral pcoff) in
    let stv = mk_var("s"^string_of_int st,`:x86state`) in
    let is_rip_read th =
      match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),v)),_) ->
          (not memsafe) || v = stv
      | _ -> false in
    FIRST_ASSUM(fun th -> if can(find_term(fun u->u=pctm))(concl th) && is_rip_read th
                          then MP_TAC th else NO_TAC);;

  let mk_prefix_g_full (memsafe:bool) : tactic =
    REPEAT GEN_TAC THEN
    (ALL_TAC THEN
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `16 * i <= 256` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC; ALL_TAC] THEN
    ENSURES_INIT_TAC "s0" THEN
    (if memsafe then STRIP_EXISTS_ASSUM_TAC else ALL_TAC) THEN
    MP_TAC(SPECL [`buf:int64`;`272`;`inlist:byte list`;`i:num`;`s0:x86state`] SUB_LIST_16_BYTES_FROM_INT128) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC; ALL_TAC] THEN
    ABBREV_TAC `chunk0 = read(memory:>bytes128(word_add buf (word(16*i)))) s0` THEN DISCH_TAC THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) <= 248` ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
      TRANS_TAC LE_TRANS `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16 * (i+1)) inlist):int16 list)` THEN
      ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NIBLEN_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
    ABBREV_TAC `outlen0 = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)` THEN
    FIRST_ASSUM(fun th -> if concl th =
        `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) = outlen0`
      then (RULE_ASSUM_TAC(REWRITE_RULE[th]) THEN ASSUME_TAC th) else NO_TAC) THEN
    MP_TAC(SPECL [`outlen0:num`;`248`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    MP_TAC(SPECL [`16*i`;`256`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    VAL_INT64_TAC `outlen0:num` THEN
    X86_STEPS_TAC EXEC (1--2) THEN
    SUBGOAL_THEN `read RIP s2 = word(pc + 63):int64` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&248:int`))(concl th)
                             then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 314`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
    X86_STEPS_TAC EXEC (3--4) THEN
    SUBGOAL_THEN `read RIP s4 = word(pc + 75):int64` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&256:int`))(concl th)
                             then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 314`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC (5--5) THEN
    SUBGOAL_THEN `val(word(16*i):int64) = 16*i` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
      UNDISCH_TAC `16*i <= 256` THEN ARITH_TAC; ALL_TAC] THEN
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
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM2 s5 =
      word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256`]) THEN
    SUBGOAL_THEN (mk_eq(`read YMM0 s8:int256`, F0NIB_CHUNK0)) ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && can(find_term((=)`read YMM0 s8`))(lhand(concl th)) then SUBST1_TAC th else NO_TAC) THEN
      REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
      CONV_TAC WORD_BLAST; ALL_TAC] THEN
    DROP_WORDJOIN_TAC THEN PURGE_STALE_STATES_TAC ["s5";"s6";"s7"] THEN
    ASSUME_TAC(SPEC `chunk0:int128` F0NIB_BYTES) THEN
    ASSUME_TAC(SPEC `chunk0:int128` F0NIB_BYTES_HI) THEN
    ABBREV_TAC `fn:int256 = read YMM0 s8` THEN
    RULE_ASSUM_TAC(REWRITE_RULE[GSYM(ASSUME(mk_eq(`fn:int256`, F0NIB_CHUNK0)))]) THEN
    X86_VSTEPS_TAC EXEC (9--9) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s8 = fn:int256`;
       ASSUME `read YMM4 s8 = word 4086779620140571603184858294424279100703646517610843436686738259102816340233:int256`]) THEN
    ABBREV_TAC `f1bnd:int256 = read YMM1 s9` THEN
    X86_VSTEPS_TAC EXEC (10--10) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s9 = fn:int256`;
       ASSUME `read YMM3 s9 = word 1816346497840254045859937019744124044757176230049263749638550337379029484548:int256`]) THEN
    ABBREV_TAC `f0sub:int256 = read YMM0 s10` THEN
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let gather_imp = prove
         (mk_imp(concl f0d,
          `!j. j < 8 ==>
             word_subword (word_subword (f0sub:int256) (0,128):int128) (8*j,8):byte =
             word_sub (word 4) (word(EL j [val(word_subword (chunk0:int128) (0,8):byte) MOD 16;
                val(word_subword chunk0 (0,8):byte) DIV 16; val(word_subword chunk0 (8,8):byte) MOD 16;
                val(word_subword chunk0 (8,8):byte) DIV 16; val(word_subword chunk0 (16,8):byte) MOD 16;
                val(word_subword chunk0 (16,8):byte) DIV 16; val(word_subword chunk0 (24,8):byte) MOD 16;
                val(word_subword chunk0 (24,8):byte) DIV 16]):byte)`),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP gather_imp f0d)) THEN
    (* bg2: sub-iter-2 gather forall over the >>64-shifted low-lane source g2 (lanes 8-15 /
       chunk0 nibbles 32,40,48,56). Derived early (f0sub word_join live); survives to s28.
       Built as the SUBITER_STORE_SPEC gather-hyp shape so SI2_FOLD discharges by MATCH_ACCEPT. *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
        let bg2_concl = List.nth (conjuncts(lhand(concl(ISPECL [g2; `word (val (mask8b:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (32,8):byte`; `word_subword (chunk0:int128) (40,8):byte`;
             `word_subword (chunk0:int128) (48,8):byte`; `word_subword (chunk0:int128) (56,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg2_imp = prove(mk_imp(concl f0d, bg2_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            REWRITE_TAC[SUBWORD_USHR] THEN CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg2_imp f0d)) THEN
    (* bg3: sub-iter-3 gather forall over the HIGH 128 lane g3 (lanes 16-23 / chunk0 nibbles 64,72,80,88).
       No shift (vextracti128 ,1 then vpshufb). Same JOIN-extract proof as bg1 (no SUBWORD_USHR). *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
        let bg3_concl = List.nth (conjuncts(lhand(concl(ISPECL [g3; `word (val (mask8c:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (64,8):byte`; `word_subword (chunk0:int128) (72,8):byte`;
             `word_subword (chunk0:int128) (80,8):byte`; `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg3_imp = prove(mk_imp(concl f0d, bg3_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg3_imp f0d)) THEN
    (* bg4: sub-iter-4 gather forall over the HIGH 128 lane >>64 (lanes 24-31 / chunk0 nibbles 96,104,112,120). *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
        let bg4_concl = List.nth (conjuncts(lhand(concl(ISPECL [g4; `word (val (mask8d:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (96,8):byte`; `word_subword (chunk0:int128) (104,8):byte`;
             `word_subword (chunk0:int128) (112,8):byte`; `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg4_imp = prove(mk_imp(concl f0d, bg4_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            REWRITE_TAC[SUBWORD_USHR] THEN CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg4_imp f0d)) THEN
    (* MASKBIT forall derived NOW (f1bnd word_join def still present): bit 7(f1bnd lane k) <=>
       EL k[chunk0 nibbles]<9. ASSUME it — survives the DROP below + downstream purges. Used by
       counter stage 3b. *)
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+16),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (64,8):byte) MOD 16; val(word_subword chunk0 (64,8):byte) DIV 16;
                    val(word_subword chunk0 (72,8):byte) MOD 16; val(word_subword chunk0 (72,8):byte) DIV 16;
                    val(word_subword chunk0 (80,8):byte) MOD 16; val(word_subword chunk0 (80,8):byte) DIV 16;
                    val(word_subword chunk0 (88,8):byte) MOD 16; val(word_subword chunk0 (88,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+24),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (96,8):byte) MOD 16; val(word_subword chunk0 (96,8):byte) DIV 16;
                    val(word_subword chunk0 (104,8):byte) MOD 16; val(word_subword chunk0 (104,8):byte) DIV 16;
                    val(word_subword chunk0 (112,8):byte) MOD 16; val(word_subword chunk0 (112,8):byte) DIV 16;
                    val(word_subword chunk0 (120,8):byte) MOD 16; val(word_subword chunk0 (120,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp2 = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+8),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (32,8):byte) MOD 16; val(word_subword chunk0 (32,8):byte) DIV 16;
                    val(word_subword chunk0 (40,8):byte) MOD 16; val(word_subword chunk0 (40,8):byte) DIV 16;
                    val(word_subword chunk0 (48,8):byte) MOD 16; val(word_subword chunk0 (48,8):byte) DIV 16;
                    val(word_subword chunk0 (56,8):byte) MOD 16; val(word_subword chunk0 (56,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp2 f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        (* prove `f1bnd = wj ==> (!k...)` as a CLOSED implication (f1d discharged as antecedent,
           so the result has NO extra hyps), then MP with f1d. The DISCH'd eq is used to rewrite. *)
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*k,8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (0,8):byte) MOD 16; val(word_subword chunk0 (0,8):byte) DIV 16;
                    val(word_subword chunk0 (8,8):byte) MOD 16; val(word_subword chunk0 (8,8):byte) DIV 16;
                    val(word_subword chunk0 (16,8):byte) MOD 16; val(word_subword chunk0 (16,8):byte) DIV 16;
                    val(word_subword chunk0 (24,8):byte) MOD 16; val(word_subword chunk0 (24,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    (* DROP f0sub/f1bnd word_join defs BEFORE vpmovmskb (s11).
       This keeps R8/R9's vpmovmskb+popcount over the OPAQUE `f1bnd` var (via the
       `read YMM1 s10 = f1bnd` fold) instead of the expanded word_join, so stage d's popeq / low8 /
       BOOL_CASES (over `word_subword f1bnd (8k,8)`) match the popcount term. Without this, R9 s21 =
       popcount(...word_join expanded...) and stage d leaves unsolved goals. *)
    REPEAT(FIRST_X_ASSUM(fun th ->
       if is_eq(concl th) && (lhand(concl th) = `f0sub:int256` || lhand(concl th) = `f1bnd:int256`)
       then ALL_TAC else failwith "keep")) THEN
    (* ---- STEP s11-s17 FIRST (vpmovmskb, vextracti128, movzbl R10 capture, vmovq, vpshufb,
       vpmovsxbd, vmovdqu store), keeping f0sub/f1bnd defs. The gather/mask SUBGOALs are proven
       AFTER stepping: their `EL j [...]`-shaped assumptions confuse X86_VSTEPS' simulator
       (vextracti128 at s12 fails with "mk_comb: types do not agree" if they're in context). ---- *)
    X86_VSTEPS_TAC EXEC (11--11) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM1 s10 = f1bnd:int256`]) THEN
    PURGE_STALE_STATES_TAC ["s10"] THEN
    X86_VSTEPS_TAC EXEC (12--12) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s11 = f0sub:int256`]) THEN
    PURGE_STALE_STATES_TAC ["s11"] THEN
    REABBREV_TAC `mask8 = read R8 s12` THEN
    X86_VERBOSE_STEP_TAC EXEC "s13" THEN
    MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s12 = mask8:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt ASSUME_TAC THENL [MASKBIT_TGT_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (14--14) THEN
    TAB1_TEQ_TAC THEN
    REABBREV_TAC `tab1 = read YMM6 s14` THEN
    X86_VSTEPS_TAC EXEC (15--15) THEN REABBREV_TAC `pshuf1 = read YMM6 s15` THEN
    PURGE_STALE_STATES_TAC ["s14"] THEN
    X86_VSTEPS_TAC EXEC (16--16) THEN REABBREV_TAC `sx1 = read YMM1 s16` THEN
    (* stepA: establish sx1 = usimd8 word_sx (word_zx(word_zx pshuf1)) (the vpmovsxbd lane form). *)
    SUBGOAL_THEN `sx1:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf1:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx1def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx1:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx1def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    PURGE_STALE_STATES_TAC ["s15"] THEN
    X86_STEPS_TAC EXEC (17--17) THEN
    PURGE_STALE_STATES_TAC ["s16"] THEN
    X86_STEPS_TAC EXEC (18--21) THEN
    MP_TAC(ISPECL[`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES) THEN
    ANTS_TAC THENL
     [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `LENGTH(inlist:byte list) = 272` THEN
      UNDISCH_TAC `16 * i <= 256` THEN ARITH_TAC; STRIP_TAC] THEN
    W(fun (asl,w) ->
       let m8def = find (fun th -> match concl th with Comb(Comb(Const("=",_),_),Var("mask8",_)) -> true | _ -> false) (map snd asl) in
       RULE_ASSUM_TAC(fun th -> if concl th = maskbit_tgt ||
          can(find_term(fun u->match u with Const("TABLE_ENTRY",_)->true|_->false))(concl th)
          then th else REWRITE_RULE[GSYM m8def] th)) THEN
    (* === REORDERED branch resolution (NO RULE_ASSUM over s21 state) ===      *)
    W(fun (asl,w) ->
      (* 1. popeq: word_popcount(word_zx^3(word(val mask8 MOD 256))) = bitsum8(low8 of f1bnd) *)
      let r9 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("R9",_)),Var("s21",_))),_) -> true | _ -> false) asl in
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
      (* 2. bitsum8 = LENGTH(REJ_NIBBLES block0) via maskbit forall + block byte facts *)
      let maskbit = snd(find (fun (_,th) -> let c=concl th in is_forall c &&
          can(find_term(fun u->u=`f1bnd:int256`))c && can(find_term(fun u->match u with Comb(Const("bit",_),_)->true|_->false))c &&
          not(can(find_term(fun u->match u with Const("word_zx",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c &&
          not(can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c)) asl) in
      let mb_tm = concl maskbit in
      let mb_assumed = ASSUME mb_tm in
      let mbits = map (fun k -> let th=SPEC(mk_small_numeral k) mb_assumed in
           CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
      let blk0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
             (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
      let blkeq = mk_eq(low8, `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)`) in
      let blk0_tm = concl(snd blk0) in
      let bsum_raw = prove(mk_imp(mb_tm, mk_imp(blk0_tm, blkeq)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN DISCH_THEN(fun b -> REWRITE_TAC[b]) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
        ASM_SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let bsum = MP (MP bsum_raw maskbit) (snd blk0) in
      (* combined: word_popcount(...) = LENGTH(REJ_NIBBLES block0)             *)
      let pop_len = TRANS popeq bsum in
      (* 3. bound: outlen0 + LENGTH(REJ_NIBBLES block0) <= 248                 *)
      let leninl = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Var("inlist",_))),_) -> true | _ -> false) asl in
      let i116 = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("<=",_),Comb(Comb(Const("*",_),_),Comb(Comb(Const("+",_),Var("i",_)),_))),_) -> true | _ -> false) asl in
      let nible = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_NIBBLES_ETA4",_),_))),_) -> true | _ -> false) asl in
      let len_eq = find (fun (_,th) -> match concl th with
         Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) asl in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=272 ==> (LENGTH(inlist:byte list)=272 ==> 16*(i+1)<=LENGTH inlist)`)
                      (snd i116)) (snd leninl) in
      let bnd0 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_1) (CONJ a1 (snd nible)) in
      let bnd = REWRITE_RULE[snd len_eq] bnd0 in  (* outlen0 + LENGTH(REJ_NIBBLES block0) <= 248 *)
      (* 4. RAX collapse: word_zx(word_add(word_zx(word outlen0))(word_zx(word_zx(word popcount)))) = word(outlen0+block0len) *)
      let block0len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)` in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in  (* word_zx(...word outlen0...word block0len...) = word(outlen0+block0len) *)
      (* but RAX has popcount, not block0len; rewrite popcount->block0len first via pop_len *)
      let rax_red = REWRITE_RULE[pop_len] (GSYM(REWRITE_RULE[GSYM pop_len] (SYM rax_red0))) in
      (* JA_NOT_TAKEN: outlen0+block0len <= 248                                *)
      let ja = MP (ISPECL[mk_binop `(+):num->num->num` `outlen0:num` block0len; `248`] JA_NOT_TAKEN_LE)
                  (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
      (* stash these as assumptions for the step                               *)
      ASSUME_TAC pop_len THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
    X86_STEPS_TAC EXEC (22--23) THEN
    (* resolve the ja branch: RIP s23 = pc+163 (fall through to sub-iter 2)    *)
    SUBGOAL_THEN `read RIP s23 = word (pc + 163):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let blk0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
               (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
        let rax_red0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
        let ja = find (fun (_,th) -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th)) asl in
        rip_mp memsafe 163 23 THEN
        REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
        REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    (* fold RAX read clean using the assumed pop_len + rax_red0 (now in asl)   *)
    W(fun (asl,w) ->
      let pl = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let rr = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr])) THEN
    ALL_TAC);;

  (* --- si1_fold_v2 ---                                                       *)
  (* SI1_FOLD_V2: sub-iter-1 store recombination. gather forall + maskbit_tgt are
     ALREADY ASSUMEd by PREFIX_G_FULL_TAC, so fetch them from asl (no SUBGOAL_THEN). Only
     pf_target is a real subgoal, discharged by PF_PROOF (genuine table-load bridge). *)
  let SI1_FOLD_V2 : tactic =
    SUBGOAL_THEN pf_target (fun pfth ->
      W(fun (asl,w) ->
        let asms = map snd asl in
        let bg = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))c &&
            not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
            can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c) asms in
        let mthm = find (fun th -> concl th = maskbit_tgt) asms in
        let storef = find (fun th -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false))(concl th) &&
            can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))(concl th) &&
            (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s23",_))),_)->true|_->false)) asms in
        let store_full = REWRITE_RULE[pfth] storef in
        let g = `word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128` in
        let m = `word (val (mask8:int64) MOD 256):byte` in
        let pc = ISPECL [`word_add res (word (4 * outlen0)):int64`; `s23:x86state`; g; m; `LENGTH(ACC_IDX (word (val (mask8:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
        let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
        let spec = ISPECL [g; m; `word_subword (chunk0:int128) (0,8):byte`; `word_subword (chunk0:int128) (8,8):byte`; `word_subword (chunk0:int128) (16,8):byte`; `word_subword (chunk0:int128) (24,8):byte`] SUBITER_STORE_SPEC in
        let gather_hyp = List.nth (conjuncts(lhand(concl spec))) 1 in
        let gthm = EQ_MP (SYM(REWRITE_CONV[WORD_ZX_TRIVIAL] gather_hyp)) bg in
        let specres = MP spec (CONJ mthm gthm) in
        let rej_store = REWRITE_RULE[specres] res_th0 in
        let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
        let blk = `[word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8); word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:byte list` in
        let prefixbytes = `SUB_LIST(0,16*i) (inlist:byte list)` in
        let prefix_store = find (fun th ->
             (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s23",_))),_) -> true | _ -> false) &&
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
        let lenle = REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1) <= 272 ==> 16*i+16 <= 272`) i116) in
        let lr = MP (ISPECL [m; `chunk0:int128`] LEN_RECONCILE) mthm in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES) (CONJ lenle blk16) in
        let blk_bytes = CONJUNCT1 bb in
        let rej_store2 = REWRITE_RULE[SYM len_eq] rej_store in
        let prefix_store2 = REWRITE_RULE[SYM len_eq] prefix_store in
        let fold = MP (ISPECL [`res:int64`;`s23:x86state`;m;blk;prefixbytes] SUBITER_FOLD_STEP)
                      (CONJ lr (CONJ prefix_store2 rej_store2)) in
        let split0 = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i`;`4`;`0`] SUB_LIST_SPLIT) in
        let clean = REWRITE_RULE[GSYM blk_bytes; GSYM split0] fold in
        ASSUME_TAC clean))
    THENL [PF_PROOF; ALL_TAC];;

  (* --- maskbit_tgt_2_tac ---                                                 *)
  (* maskbit_tgt_2 + MASKBIT_TGT_2_TAC: sub-iter-2 analog of maskbit_tgt/MASKBIT_TGT_TAC.
     mask8b = R8 after the ushr-by-8 (= bits 8-15 of SUM32). maskbit_tgt_2 relates
     bit j (word(val mask8b MOD 256)) to chunk0 nibbles 32,40,48,56 (lanes 8-15) < 9.
     KEY EXTRA vs si1: val mask8b MOD 256 = (SUM32 DIV 256) MOD 256 (MASK_SHIFT8_MOD256);
     regroup SUM32 = SUM_low8 + 256*SUM8' + 65536*SUM_high16 (ARITH, linear in bitvals);
     DIVMOD256_SPLIT extracts SUM8' (= the lanes-8-15 8-term bitsum). Then same MASK_LOW_BIT
     + lanes-8-15 maskbit forall mechanism as si1. valeq MUST be folded via REWRITE_RULE[m8b]
     so its LHS is `val mask8b MOD 256` (not the unfolded word_zx tower). *)
  let maskbit_tgt_2 =
    `!j. j < 8 ==> (bit j (word (val (mask8b:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (32,8):byte) MOD 16;
           val(word_subword chunk0 (32,8):byte) DIV 16; val(word_subword chunk0 (40,8):byte) MOD 16;
           val(word_subword chunk0 (40,8):byte) DIV 16; val(word_subword chunk0 (48,8):byte) MOD 16;
           val(word_subword chunk0 (48,8):byte) DIV 16; val(word_subword chunk0 (56,8):byte) MOD 16;
           val(word_subword chunk0 (56,8):byte) DIV 16] < 9)`;;

  let TAB2_TEQ_TAC : tactic = mk_tab_teq 25 26 `mask8b:int64` RLT_B R_EQ_B;;

  (* --- si2_fold_pieces ---                                                   *)
  (* Sub-iter-2 store-fold pieces (gather-side ingredients + fold-carry-forward
     across states). *)

  (* PF_PROOF_2: discharge the sub-iter-2 `pshuf2 = pf_target_2` subgoal.      *)
  let PF_PROOF_2 : tactic = mk_pf_proof `pshuf2:int256` `tab2:int256`;;

  (* --- si2_fold_complete ---                                                 *)
  (* Sub-iter-2 store fold COMPLETE +. The full generalized mechanism:
     gather (bg2 early) + maskbit_tgt_2 + teq2 + pf_target_2 + SUBITER_STORE_SPEC fold + carry-forward.
     KEY: the running prefix store must be stated with length = acc1 (the next write's offset var) so
     it carries past the s29 vpmovdqu write; acc1_ident bridges LENGTH(REJ_SAMPLE(SUB_LIST(0,16i+4)))=acc1.
     Load after main + cbb_defs + .pf_target_proof + .maskbit_tgt_2_tac + .tab2_teq_tac + .si2_fold_pieces. *)

  (* LEN_RECONCILE_GEN: LEN_RECONCILE generalized to arbitrary 4 block bytes b0..b3 (si1 had block0
     hardcoded). Needed because sub-iter k's block bytes are chunk0 (32,40,48,56) etc, not (0,8,16,24). *)
  let LEN_RECONCILE_GEN = prove
   (`!(m:byte) (b0:byte) (b1:byte) (b2:byte) (b3:byte).
       (!j. j < 8 ==> (bit j m <=>
          EL j [val b0 MOD 16; val b0 DIV 16; val b1 MOD 16; val b1 DIV 16;
                val b2 MOD 16; val b2 DIV 16; val b3 MOD 16; val b3 DIV 16] < 9))
       ==> LENGTH(ACC_IDX m) =
           LENGTH(REJ_SAMPLE_ETA4_BYTES [b0;b1;b2;b3]:int32 list)`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL [`m:byte`;
      `word(val(b0:byte) MOD 16):byte`; `word(val(b0:byte) DIV 16):byte`;
      `word(val(b1:byte) MOD 16):byte`; `word(val(b1:byte) DIV 16):byte`;
      `word(val(b2:byte) MOD 16):byte`; `word(val(b2:byte) DIV 16):byte`;
      `word(val(b3:byte) MOD 16):byte`; `word(val(b3:byte) DIV 16):byte`] ACC_LENGTH_EQ_FILTER) THEN
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
      REWRITE_TAC[LENGTH_FILTER_BYTE_NIBBLES_4_BYTES; LENGTH_REJ_SAMPLE_ETA4_BYTES]]);;

  (* ACC1_IDENT_TAC: prove & ASSUME `LENGTH(REJ_SAMPLE(SUB_LIST(0,16i+4)))=acc1` (acc1 must be ABBREV'd
     as outlen0 + LENGTH(REJ_NIBBLES(SUB_LIST(16i,4))), outlen0 def + that ABBREV in asl). Re-run right
     before each fold (it gets consumed by the store-address restate). *)
  let ACC1_IDENT_TAC : tactic =
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` ASSUME_TAC THENL
    [ONCE_REWRITE_TAC[REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i`;`4`;`0`] SUB_LIST_SPLIT)] THEN
     REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND] THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_))->true|_->false)
         then ASSUME_TAC(REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA4_BYTES] th) else NO_TAC) THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_NIBBLES_ETA4",_),_))),Var("outlen0",_))->true|_->false)
         then REWRITE_TAC[th] else NO_TAC) THEN
     FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),_),Var("acc1",_))->can(find_term(fun u->u=`outlen0:num`))(concl th)|_->false) then (MP_TAC th THEN ARITH_TAC) else NO_TAC); ALL_TAC];;

  let SI2_MG_TAC : tactic =
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
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),_) -> true | _ -> false))c) in
    let mb2_tm = concl mb2 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le))
                      blk16) in
    let blk1_eq = el 1 (CONJUNCTS bb) in
    let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                   word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
    let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block1)) in
    let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    (* fold explicit block1 -> SUB_LIST(16i+4,4) via blk1_eq (GSYM)            *)
    let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
    (* bound: outlen0 + niblen(block0) + block1len <= 248                      *)
    let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 272`) in
    let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
    let a1 = MP (MP (ARITH_RULE `16*(i+1)<=272 ==> (LENGTH(inlist:byte list)=272 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
    let bnd2 = MP (ISPECL[`inlist:byte list`;`i:num`] SUBITER_OUTLEN_BOUND_2) (CONJ a1 nibbnd) in
    (* acc1 = outlen0 + niblen(block0); outlen0 = LENGTH(REJ_SAMPLE...(SUB_LIST(0,16i))). Rewrite bnd2's
       first two terms into acc1. *)
    let outlen0_def = find_a (fun th -> match concl th with
       Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),_)),Var("outlen0",_)) -> true | _ -> false) in
    let acc1_def = find_a (fun th -> match concl th with
       Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),_),_)),Var("acc1",_)) -> true | _ -> false) in
    (* bnd2 : LENGTH(REJ_SAMPLE(SUB_LIST(0,16i))) + niblen(SUB_LIST(16i,4)) + block1len <= 248
       rewrite LENGTH(REJ_SAMPLE...) -> outlen0, then (outlen0 + niblen(...)) -> acc1. *)
    let bnd2a = REWRITE_RULE[outlen0_def; ADD_ASSOC] bnd2 in
    let bnd2c = REWRITE_RULE[acc1_def] bnd2a in
    (* bnd2c : acc1 + block1len <= 248                                         *)
    let block1len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
    let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd2c in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let ja = MP (ISPECL[mk_binop `(+):num->num->num` `acc1:num` block1len; `248`] JA_NOT_TAKEN_LE)
                (CONJ bnd2c (ARITH_RULE `248 < 2 EXP 32`)) in
    ASSUME_TAC pop_len2 THEN ASSUME_TAC bnd2c THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja);;

  let SI2_RESOLVE : tactic =
    X86_STEPS_TAC EXEC (34--35) THEN
    SUBGOAL_THEN `read RIP s35 = word (pc + 215):int64` ASSUME_TAC THENL
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
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s35",_))),r) ->
             (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asms in
        MP_TAC ifrip THEN REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC];;

  (* --- si2_integrated ---                                                    *)
  (* SI2_INTEGRATED: complete sub-iter-2 = gather + store-fold + counter + mid-guard.
     From post-SI1 s23 (RIP=pc+163, si1 clean store for SUB_LIST(0,16i+4) present), reaches s35 RIP=pc+215
     with the running clean store folded to SUB_LIST(0,16i+8). Composes SI2_GATHER_TO_STORE +
     ACC1_IDENT/restate + the si2 fold W + SI2_MG_TAC + SI2_RESOLVE.
     Load deps: .pf_target_proof, .maskbit_tgt_2_tac, .tab2_teq_tac, .si2_fold_pieces, .si2_fold_complete, .si2_full.
     NB the si1 store must FIRST be restated to bytes(res,4*acc1) (via ACC1_IDENT) BEFORE the gather, so it
     carries past the s29 vpmovdqu. *)
  let SI2_INTEGRATED : tactic =
    REABBREV_TAC `mask8b = read R8 s23` THEN
    ABBREV_TAC `acc1 = outlen0 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)` THEN
    ACC1_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1`]) THEN
    X86_VSTEPS_TAC EXEC (24--24) THEN
    X86_VERBOSE_STEP_TAC EXEC "s25" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s24 = mask8b:int64`]) THEN
    X86_VSTEPS_TAC EXEC (26--26) THEN TAB2_TEQ_TAC THEN REABBREV_TAC `tab2 = read YMM6 s26` THEN
    X86_VSTEPS_TAC EXEC (27--27) THEN REABBREV_TAC `pshuf2 = read YMM6 s27` THEN
    PURGE_STALE_STATES_TAC ["s26"] THEN
    X86_VSTEPS_TAC EXEC (28--28) THEN REABBREV_TAC `sx2 = read YMM1 s28` THEN
    VAL_INT64_TAC `acc1:num` THEN
    X86_STEPS_TAC EXEC (29--29) THEN
    SUBGOAL_THEN `sx2:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf2:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx2def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx2:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx2def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    (SUBGOAL_THEN maskbit_tgt_2 ASSUME_TAC THENL [MASKBIT_TGT_2_TAC; ALL_TAC]) THEN
    (SUBGOAL_THEN pf_target_2 ASSUME_TAC THENL [PF_PROOF_2; ALL_TAC]) THEN
    ACC1_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let bg2 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c) asms in
      let mthm2 = find (fun th -> concl th = maskbit_tgt_2) asms in
      let pfth2 = find (fun th -> concl th = pf_target_2) asms in
      let sx2u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx2",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
      let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s29",_))),Var("sx2",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
      let store_full = REWRITE_RULE[pfth2] (REWRITE_RULE[sx2u] storef0) in
      let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8b:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc1)):int64`; `s29:x86state`; g2; m; `LENGTH(ACC_IDX (word (val (mask8b:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g2; m; `word_subword (chunk0:int128) (32,8):byte`; `word_subword (chunk0:int128) (40,8):byte`; `word_subword (chunk0:int128) (48,8):byte`; `word_subword (chunk0:int128) (56,8):byte`] SUBITER_STORE_SPEC in
      let rej_store = REWRITE_RULE[MP spec (CONJ mthm2 bg2)] res_th0 in
      let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
      let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (32,8):byte`;`word_subword (chunk0:int128) (40,8):byte`;`word_subword (chunk0:int128) (48,8):byte`;`word_subword (chunk0:int128) (56,8):byte`] LEN_RECONCILE_GEN) mthm2 in
      let lr = REWRITE_RULE[GSYM blk1_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk1_eq] rej_store in
      let acc1_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc1",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s29",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc1:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc1_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc1_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s29:x86state`;m;`SUB_LIST(16*i+4,4) (inlist:byte list)`;`SUB_LIST(0,16*i+4) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+4`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+4)+4 = 16*i+8`] fold in
      ASSUME_TAC clean) THEN
    X86_STEPS_TAC EXEC (30--33) THEN
    SI2_MG_TAC THEN SI2_RESOLVE;;

  (* --- si3_full ---                                                          *)
  (* Sub-iter 3: from RIP=pc+215 (after SI2_RESOLVE) to RIP=pc+268 (mid-guard 3 fall-through).
     Mask = mask8c (R8 ushr16, byte 2 -> lanes 16-23, block2 = SUB_LIST(16i+8,4)). Uses PREFIX4's
     lanes-16..23 maskbit + POPCNT_BYTE2. Requires SI2 chain already applied (RIP=pc+215, RAX still
     the unfolded sub-iter-2 popcount nest). *)

  (* SI3_PRE: fold RAX s35 -> word acc2, abbrev acc2, reabbrev mask8c, establish acc2<=248. *)
  let SI3_PRE : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let pop_len2_old = find (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asms in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) pop_len2_old in
      let rax_red0 = find (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asms in
      RULE_ASSUM_TAC(REWRITE_RULE[pop_len2_typed]) THEN RULE_ASSUM_TAC(REWRITE_RULE[rax_red0])) THEN
    ABBREV_TAC `acc2 = acc1 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (16*i+4,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8c = read R8 s35` THEN
    (* bound acc2 + niblen(16i+8,4) <= 248, then acc2 <= 248                   *)
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 272`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=272 ==> (LENGTH(inlist:byte list)=272 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
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

  (* SI3_MG: forward facts pop_len3/bnd3c'/rax_red0_3/ja3 for mid-guard 3.     *)
  let SI3_MG : tactic =
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
      let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
              length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in   (* SUB_LIST(16*i+8,4) = [chunk0 64,72,80,88] *)
      let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                     word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
      let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block2)) in
      let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum, block2len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
      let bnd3c = find_a (fun th -> match concl th with
         Comb(Comb(Const("<=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> true | _ -> false) in
      let block2len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
      let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd3c in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let ja = MP (ISPECL[mk_binop `(+):num->num->num` `acc2:num` block2len; `248`] JA_NOT_TAKEN_LE)
                  (CONJ bnd3c (ARITH_RULE `248 < 2 EXP 32`)) in
      ASSUME_TAC pop_len3 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja);;

  (* SI3_RESOLVE: step cmp/ja (s46-47), typed-popcount branch resolution -> RIP s47 = pc+268. *)
  let SI3_RESOLVE : tactic =
    X86_STEPS_TAC EXEC (46--47) THEN
    SUBGOAL_THEN `read RIP s47 = word (pc + 268):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let asms = map snd asl in
        let find_a p = find p asms in
        (* The counter step already folded popcnt->LENGTH(REJ_NIBBLES[explicit block2]) into the COND.
           Convert that explicit block2 to SUB_LIST(16i+8,4) form via GSYM blk2_eq so rax_red0/ja match. *)
        let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
        let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
        let blk16 = find_a (fun th -> is_eq(concl th) &&
           (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
        let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                    (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
        let blk2_eq = el 2 (CONJUNCTS bb) in
        let rax_red0 = find (fun th -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
              can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) asms in
        let ja = find (fun th -> is_disj(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`acc2:num`))(concl th)) asms in
        let ifrip = find (fun th -> match concl th with
           Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s47",_))),r) ->
             (match r with Comb(Comb(Comb(Const("COND",_),_),_),_) -> true | _ -> false) | _ -> false) asms in
        MP_TAC ifrip THEN REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
        REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC];;

  (* --- si3_fold_pieces ---                                                   *)
  (* Sub-iter-3 fold pieces. g3 = hi 128 lane (no shift) = word_zx(word_zx(word_subword f0sub (128,128))).
     mask8c (R8 ushr16), block2 = SUB_LIST(16i+8,4), lanes 16-23. Load after main+cbb+pf_target_proof+
     si2_fold_complete (DIVMOD256_SPLIT, ACC1_IDENT_TAC) + .si3_full (SI3_PRE/MG/RESOLVE). *)

  let maskbit_tgt_3 =
    `!j. j < 8 ==> (bit j (word (val (mask8c:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (64,8):byte) MOD 16;
           val(word_subword chunk0 (64,8):byte) DIV 16; val(word_subword chunk0 (72,8):byte) MOD 16;
           val(word_subword chunk0 (72,8):byte) DIV 16; val(word_subword chunk0 (80,8):byte) MOD 16;
           val(word_subword chunk0 (80,8):byte) DIV 16; val(word_subword chunk0 (88,8):byte) MOD 16;
           val(word_subword chunk0 (88,8):byte) DIV 16] < 9)`;;

  let TAB3_TEQ_TAC : tactic = mk_tab_teq 37 38 `mask8c:int64` RLT_C R_EQ_C;;

  let PF_PROOF_3 : tactic = mk_pf_proof `pshuf3:int256` `tab3:int256`;;

  (* ACC2_IDENT_TAC: prove & ASSUME LENGTH(REJ_SAMPLE(SUB_LIST(0,16i+8)))=acc2 by forward inference
     (non-destructive; needs acc1_ident [LENGTH REJ_SAMPLE form] + acc2 ABBREV def in asl). *)
  let ACC2_IDENT_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let acc1_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc1",_))->true|_->false) asms in
      let acc2_def = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),Var("acc2",_))->true|_->false) asms in
      let split = REWRITE_RULE[ADD_CLAUSES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] (ISPECL[`inlist:byte list`;`16*i+4`;`4`;`0`] SUB_LIST_SPLIT) in
      let step1 = (REWRITE_CONV[LENGTH_REJ_SAMPLE_ETA4_BYTES] THENC ONCE_DEPTH_CONV(REWR_CONV split) THENC REWRITE_CONV[REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND])
                    `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` in
      let acc1_nib = REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA4_BYTES] acc1_ident in
      let final = TRANS step1 (TRANS (AP_THM (AP_TERM `(+):num->num->num` acc1_nib) `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+4,4) inlist):int16 list)`) acc2_def) in
      ASSUME_TAC final);;

  (* --- si3_integrated ---                                                    *)
  (* SI3_INTEGRATED: full sub-iter-3 (gather + store-fold + counter + mid-guard).
     From s35 (RIP=pc+215, running store SUB_LIST(0,16i+8)) to s47 (RIP=pc+268), store folded to
     SUB_LIST(0,16i+12). Deps: .si3_full (SI3_PRE/GATHER/MG/RESOLVE), .si3_fold_pieces, .si2_fold_complete
     (LEN_RECONCILE_GEN), .pf_target_proof. g3 = hi 128 lane (no shift) so gthm=bg3 directly. *)
  let SI3_INTEGRATED : tactic =
    SI3_PRE THEN              (* abbrev acc2, reabbrev mask8c, bounds; RAX folded to word acc2 *)
    ACC2_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2`]) THEN
    X86_VSTEPS_TAC EXEC (36--36) THEN
    X86_VERBOSE_STEP_TAC EXEC "s37" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s36 = mask8c:int64`]) THEN
    X86_VSTEPS_TAC EXEC (38--38) THEN TAB3_TEQ_TAC THEN REABBREV_TAC `tab3 = read YMM6 s38` THEN
    X86_VSTEPS_TAC EXEC (39--39) THEN REABBREV_TAC `pshuf3 = read YMM6 s39` THEN
    PURGE_STALE_STATES_TAC ["s38"] THEN
    X86_VSTEPS_TAC EXEC (40--40) THEN REABBREV_TAC `sx3 = read YMM1 s40` THEN
    VAL_INT64_TAC `acc2:num` THEN
    X86_STEPS_TAC EXEC (41--41) THEN
    SUBGOAL_THEN `sx3:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf3:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx3def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx3:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx3def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    (SUBGOAL_THEN maskbit_tgt_3 ASSUME_TAC THENL [MASKBIT_TGT_3_TAC; ALL_TAC]) THEN
    (SUBGOAL_THEN pf_target_3 ASSUME_TAC THENL [PF_PROOF_3; ALL_TAC]) THEN
    ACC2_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let bg3 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm3 = find (fun th -> concl th = maskbit_tgt_3) asms in
      let pfth3 = find (fun th -> concl th = pf_target_3) asms in
      let sx3u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx3",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
      let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s41",_))),Var("sx3",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
      let store_full = REWRITE_RULE[pfth3] (REWRITE_RULE[sx3u] storef0) in
      let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
      let m = `word (val (mask8c:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc2)):int64`; `s41:x86state`; g3; m; `LENGTH(ACC_IDX (word (val (mask8c:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g3; m; `word_subword (chunk0:int128) (64,8):byte`; `word_subword (chunk0:int128) (72,8):byte`; `word_subword (chunk0:int128) (80,8):byte`; `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC in
      let rej_store = REWRITE_RULE[MP spec (CONJ mthm3 bg3)] res_th0 in
      let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
      let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (64,8):byte`;`word_subword (chunk0:int128) (72,8):byte`;`word_subword (chunk0:int128) (80,8):byte`;`word_subword (chunk0:int128) (88,8):byte`] LEN_RECONCILE_GEN) mthm3 in
      let lr = REWRITE_RULE[GSYM blk2_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk2_eq] rej_store in
      let acc2_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc2",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s41",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc2:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc2_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc2_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s41:x86state`;m;`SUB_LIST(16*i+8,4) (inlist:byte list)`;`SUB_LIST(0,16*i+8) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+8)+4 = 16*i+12`] fold in
      ASSUME_TAC clean) THEN
    X86_STEPS_TAC EXEC (42--45) THEN
    SI3_MG THEN SI3_RESOLVE;;

  (* --- si4_full ---                                                          *)
  (* Sub-iter 4: from RIP=pc+268 (after SI3_RESOLVE) through the jmp pc+52 (loop back-edge).
     Mask = mask8d (R8 ushr24, byte 3 -> lanes 24-31, block3 = SUB_LIST(16i+12,4)). NO mid-guard
     (sub-iter 4 has no cmp/ja; ends jmp pc+52). Uses PREFIX4's lanes-24..31 maskbit + POPCNT_BYTE3. *)

  (* SI4_PRE: fold RAX s47 -> word acc3, abbrev acc3, reabbrev mask8d, establish acc3<=248. *)
  let SI4_PRE : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let pop_len3 = find (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) ->
            can(find_term(fun u->u=`mask8c:int64`))(concl th) | _ -> false) asms in
      let rax_red0 = find (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) asms in
      (* fold popcnt->block2len(SUB_LIST) then collapse the nest to word(acc2+block2len) *)
      RULE_ASSUM_TAC(REWRITE_RULE[pop_len3]) THEN RULE_ASSUM_TAC(REWRITE_RULE[rax_red0])) THEN
    ABBREV_TAC `acc3 = acc2 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (16*i+8,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8d = read R8 s47` THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let i116 = find_a (fun th -> concl th = `16 * (i + 1) <= 272`) in
      let nibbnd = find_a (fun th -> concl th = `LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (0,16 * (i + 1)) inlist):int16 list) <= 248`) in
      let a1 = MP (MP (ARITH_RULE `16*(i+1)<=272 ==> (LENGTH(inlist:byte list)=272 ==> 16*(i+1)<=LENGTH inlist)`) i116) leninl in
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

  (* --- si4_fold_pieces ---                                                   *)
  (* Sub-iter-4 fold pieces. g4 = hi 128 lane >>64 = word_zx(word_zx(word_ushr(word_zx(word_zx(word_subword
     f0sub (128,128)))) 64)). mask8d (R8 ushr24), block3 = SUB_LIST(16i+12,4), lanes 24-31. BYTE3 (DIV 2^24).
     NO mid-guard (sub-iter 4 ends jmp pc+52). *)

  let maskbit_tgt_4 =
    `!j. j < 8 ==> (bit j (word (val (mask8d:int64) MOD 256):byte) <=>
         EL j [val(word_subword (chunk0:int128) (96,8):byte) MOD 16;
           val(word_subword chunk0 (96,8):byte) DIV 16; val(word_subword chunk0 (104,8):byte) MOD 16;
           val(word_subword chunk0 (104,8):byte) DIV 16; val(word_subword chunk0 (112,8):byte) MOD 16;
           val(word_subword chunk0 (112,8):byte) DIV 16; val(word_subword chunk0 (120,8):byte) MOD 16;
           val(word_subword chunk0 (120,8):byte) DIV 16] < 9)`;;

  let TAB4_TEQ_TAC : tactic = mk_tab_teq 49 50 `mask8d:int64` RLT_D R_EQ_D;;

  let PF_PROOF_4 : tactic = mk_pf_proof `pshuf4:int256` `tab4:int256`;;

  (* ACC3_IDENT_TAC: LENGTH(REJ_SAMPLE(SUB_LIST(0,16i+12)))=acc3 by forward inference. acc3 = acc2 +
     niblen(SUB_LIST(16i+8,4)); needs acc2_ident + acc3 ABBREV def. *)
  let ACC3_IDENT_TAC : tactic =
    W(fun (asl,w) ->
      let asms = map snd asl in
      let acc2_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc2",_))->true|_->false) asms in
      let acc3_def = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),Var("acc3",_))->true|_->false) asms in
      let split = REWRITE_RULE[ADD_CLAUSES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let step1 = (REWRITE_CONV[LENGTH_REJ_SAMPLE_ETA4_BYTES] THENC ONCE_DEPTH_CONV(REWR_CONV split) THENC REWRITE_CONV[REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND])
                    `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` in
      let acc2_nib = REWRITE_RULE[LENGTH_REJ_SAMPLE_ETA4_BYTES] acc2_ident in
      let final = TRANS step1 (TRANS (AP_THM (AP_TERM `(+):num->num->num` acc2_nib) `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+8,4) inlist):int16 list)`) acc3_def) in
      ASSUME_TAC final);;

  (* --- si4_integrated ---                                                    *)
  (* SI4_INTEGRATED: full sub-iter-4 (gather + store-fold + counter + jmp).
     From s47 (RIP=pc+268, running store SUB_LIST(0,16i+12)) to s57 (RIP=pc+52, back-edge),
     store folded to SUB_LIST(0,16i+16). NO mid-guard. g4 = hi 128 lane >>64. Deps: .si4_full
     (SI4_PRE/GATHER), .si4_fold_pieces, .si2_fold_complete (LEN_RECONCILE_GEN), .pf_target_proof. *)
  let SI4_INTEGRATED : tactic =
    SI4_PRE THEN
    ACC3_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3`]) THEN
    X86_VSTEPS_TAC EXEC (48--48) THEN
    X86_VERBOSE_STEP_TAC EXEC "s49" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s48 = mask8d:int64`]) THEN
    X86_VSTEPS_TAC EXEC (50--50) THEN TAB4_TEQ_TAC THEN REABBREV_TAC `tab4 = read YMM6 s50` THEN
    X86_VSTEPS_TAC EXEC (51--51) THEN REABBREV_TAC `pshuf4 = read YMM6 s51` THEN
    PURGE_STALE_STATES_TAC ["s50"] THEN
    X86_VSTEPS_TAC EXEC (52--52) THEN REABBREV_TAC `sx4 = read YMM1 s52` THEN
    VAL_INT64_TAC `acc3:num` THEN
    X86_STEPS_TAC EXEC (53--53) THEN
    SUBGOAL_THEN `sx4:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf4:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx4def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx4:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx4def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    (SUBGOAL_THEN maskbit_tgt_4 ASSUME_TAC THENL [MASKBIT_TGT_4_TAC; ALL_TAC]) THEN
    (SUBGOAL_THEN pf_target_4 ASSUME_TAC THENL [PF_PROOF_4; ALL_TAC]) THEN
    ACC3_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let bg4 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm4 = find (fun th -> concl th = maskbit_tgt_4) asms in
      let pfth4 = find (fun th -> concl th = pf_target_4) asms in
      let sx4u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx4",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
      let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s53",_))),Var("sx4",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
      let store_full = REWRITE_RULE[pfth4] (REWRITE_RULE[sx4u] storef0) in
      let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8d:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc3)):int64`; `s53:x86state`; g4; m; `LENGTH(ACC_IDX (word (val (mask8d:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g4; m; `word_subword (chunk0:int128) (96,8):byte`; `word_subword (chunk0:int128) (104,8):byte`; `word_subword (chunk0:int128) (112,8):byte`; `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC in
      let rej_store = REWRITE_RULE[MP spec (CONJ mthm4 bg4)] res_th0 in
      let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
      let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (96,8):byte`;`word_subword (chunk0:int128) (104,8):byte`;`word_subword (chunk0:int128) (112,8):byte`;`word_subword (chunk0:int128) (120,8):byte`] LEN_RECONCILE_GEN) mthm4 in
      let lr = REWRITE_RULE[GSYM blk3_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk3_eq] rej_store in
      let acc3_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc3",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s53",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc3:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc3_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc3_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s53:x86state`;m;`SUB_LIST(16*i+12,4) (inlist:byte list)`;`SUB_LIST(0,16*i+12) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+12`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+12)+4 = 16*i+16`] fold in
      ASSUME_TAC clean) THEN
    X86_STEPS_TAC EXEC (54--57);;

  (* --- acc_full_len ---                                                      *)
  (* ACC_FULL_LEN: the 5-term niblen sum (outlen0-block + 4 sub-iter blocks) = niblen(SUB_LIST(0,16(i+1))).
     Needed by RAX_FINAL_TAC. Plus SL16_4WAY helper (SUB_LIST(16i,16) = APPEND of the 4 4-blocks). *)
  let ACC_FULL_LEN = prove
   (`!inlist:byte list. !i:num. 16*i+16 <= LENGTH inlist ==>
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*i) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+4,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+8,4) inlist):int16 list) +
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+12,4) inlist):int16 list) =
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*(i+1)) inlist):int16 list)`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[ARITH_RULE `16*(i+1) = 16*i+16`] THEN
    ONCE_REWRITE_TAC[ISPECL[`inlist:byte list`;`16*i`;`16`;`0`] SUB_LIST_SPLIT] THEN
    REWRITE_TAC[ADD_CLAUSES] THEN
    REWRITE_TAC[SL16_4WAY] THEN
    REWRITE_TAC[REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND] THEN ARITH_TAC);;

  (* --- rax_final ---                                                         *)
  (* Discharge the RAX final-state subgoal (goal 0):
     word_zx(word_add(word_zx(word acc3))(word_zx(word_zx(word(word_popcount(mask8d-arg)))))) =
       word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16(i+1))))). *)
  let RAX_FINAL_TAC : tactic =
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
      let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
      let blk3_eq = el 3 (CONJUNCTS bb) in   (* SUB_LIST(16*i+12,4) = [chunk0 96,104,112,120] *)
      let block3 = `[word_subword (chunk0:int128) (96,8); word_subword chunk0 (104,8);
                     word_subword chunk0 (112,8); word_subword chunk0 (120,8)]:byte list` in
      let block3len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block3)) in
      let bsum4_raw = prove(mk_imp(mb4_tm, mk_eq(lanesum, block3len_x)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
              (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
        SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let pop_len4 = REWRITE_RULE[GSYM blk3_eq] (TRANS popcnt4 (MP bsum4_raw mb4)) in
      (* bound acc3 + block3len < 2^32                                         *)
      let bnd4d = find_a (fun th -> match concl th with
         Comb(Comb(Const("<=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),_) -> true | _ -> false) in
      let block3len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+12,4) inlist):int16 list)` in
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
      let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let af = MP (ISPECL [`inlist:byte list`; `i:num`] ACC_FULL_LEN)
                  (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) in
      REWRITE_TAC[SYM acc3_def; SYM acc2_def; SYM acc1_def] THEN
      REWRITE_TAC[SYM outlen0_def] THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
      MP_TAC af THEN ARITH_TAC);;

  (* --- rcx_final ---                                                         *)
  (* Final-state RCX discharge for CLEAN_BODY: the quadruple-nested word_zx/word_add(+4)
     counter chain = word(16*(i+1)). Plus helper lemmas. Load after main file. *)

  let RCX_FINAL_TAC : tactic =
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
     [REPEAT CONJ_TAC THEN UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[MOD_LT] THEN ARITH_TAC;;

  (* --- clean_block ---                                                       *)
  (* ========================================================================= *)
  (* CLEAN_BLOCK: the SIMD 16-byte block body pc+52 -> pc+52,                  *)
  (* WITHOUT the `~(N=0)` and `i+1<N` hyps of clean_body_tm (the gather tactics *)
  (* never use them), and with the relaxed bound `16*(i+1)<=272` (so it covers *)
  (* BOTH clean blocks AND the exit block at i=N-1 where 16*N=272). Proved by the *)
  (* same CLEAN_BODY_FULL_TAC. This is the asset for the exit-block OFFSET arm: *)
  (* CLEAN_BLOCK @ i=N-1 takes pc+52/pos=16(N-1) -> pc+52/pos=16N, then the head *)
  (* guard cmp ecx,256 fires (16N=272>256) -> pc+314, then SCALAR_TAIL_AT_P@272. *)
  (* Load after the full CLEAN_BODY chain (needs CLEAN_BODY_FULL_TAC + clean_body_tm). *)
  (* ========================================================================= *)
  let clean_block_tm =
    let hs = conjuncts(fst(dest_imp(snd(strip_forall clean_body_tm)))) in
    let hs' = filter (fun h -> h <> `~(N = 0)` && h <> `i + 1 < N`) hs in
    list_mk_forall(fst(strip_forall clean_body_tm),
      mk_imp(list_mk_conj hs', snd(dest_imp(snd(strip_forall clean_body_tm)))));;

  (* --- scalar_tail_lemmas ---                                                *)
  (* Foundational spec lemmas for the SCALAR_TAIL proof (pc+314 byte-at-a-time loop).
     Each scalar iteration consumes 1 input byte = 2 nibbles (low then high), accepting each if <9,
     matching REJ_SAMPLE_ETA4_BYTES_1. These give the per-byte step of the loop invariant. *)

  let SUB_LIST_1_EL = prove
   (`!l:byte list. !p. p < LENGTH l ==> SUB_LIST(p,1) l = [EL p l]`,
    LIST_INDUCT_TAC THEN REWRITE_TAC[LENGTH; LT] THEN
    X_GEN_TAC `p:num` THEN ASM_CASES_TAC `p = 0` THEN
    ASM_REWRITE_TAC[] THENL
     [REWRITE_TAC[ARITH_RULE `1 = SUC 0`; SUB_LIST_CLAUSES; SUB_LIST; EL; HD] THEN
      REWRITE_TAC[ONE; SUB_LIST_CLAUSES];
      DISCH_TAC THEN
      SUBGOAL_THEN `?q. p = SUC q` (CHOOSE_THEN SUBST_ALL_TAC) THENL
       [EXISTS_TAC `p - 1` THEN ASM_ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[SUB_LIST_CLAUSES; EL; TL] THEN
      FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC]);;

  let SUB_LIST_STEP_1 = prove
   (`!l:byte list. !p. p < LENGTH l ==> SUB_LIST(0,p+1) l = APPEND (SUB_LIST(0,p) l) [EL p l]`,
    REPEAT STRIP_TAC THEN
    MP_TAC(ISPECL[`l:byte list`;`p:num`;`1`;`0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
    ASM_SIMP_TAC[SUB_LIST_1_EL]);;

  let REJ_SAMPLE_STEP_1 = prove
   (`!inlist:byte list. !p. p < LENGTH inlist ==>
       REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) =
       APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)) (REJ_SAMPLE_ETA4_BYTES [EL p inlist])`,
    REPEAT STRIP_TAC THEN ASM_SIMP_TAC[SUB_LIST_STEP_1; REJ_SAMPLE_ETA4_BYTES_APPEND]);;

  let LENGTH_REJ_SAMPLE_STEP_1 = prove
   (`!inlist:byte list. !p. p < LENGTH inlist ==>
       LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
       LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) +
       (if val(EL p inlist) MOD 16 < 9 then 1 else 0) + (if val(EL p inlist) DIV 16 < 9 then 1 else 0)`,
    REPEAT STRIP_TAC THEN ASM_SIMP_TAC[REJ_SAMPLE_STEP_1; LENGTH_APPEND; LENGTH_REJ_SAMPLE_ETA4_BYTES_1] THEN ARITH_TAC);;

  (* --- scalar_tail_build ---                                                 *)
  (* Scalar-tail proof build file. Loaded after the main eta4 file + .scalar_tail_lemmas.ml.
     Builds: READ_1BYTE_EL, the per-byte loop body lemma, the WOP scalar-loop wrapper,
     and finally MLDSA_REJ_UNIFORM_ETA4_SCALAR_TAIL. *)

  (* Read one input byte at offset p from the buffer's num_of_wordlist contract. *)
  let READ_1BYTE_EL = prove
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

  (* jae(Condition_NB) fall-through: when a<k the unsigned >= jump is NOT taken.
     The model's flag condition is INT-typed (int_of_num &), NOT real — matching
     it requires the :int annotation (the classic invisible-type trap). Resolves
     the scalar-tail guards at pc+319 (256), pc+327 (272), pc+369/pc+383 (256). *)
  let JAE_NOT_TAKEN_LT = prove
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

  (* jae(Condition_NB) TAKEN: when k<=a the unsigned >= jump IS taken (flag eq holds).
     Companion of JAE_NOT_TAKEN_LT for the nibble-reject branches (cmp r10d/r11d, 9). *)
  let JAE_TAKEN_GE = prove
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

  (* Fast RIP-cond resolver: rewrites ONLY the RIP equation (a small term), not the
     whole eventually-goal — avoids a catastrophic whole-goal REWRITE. Finds
     the RIP=(if cond then..else..) assumption, the matching ~cond among assumptions
     (must be present and SAME-TYPED), and collapses via COND_CLAUSES. *)

  (* ========================================================================= *)
  (* Per-byte scalar-tail body lemma: one trip pc+314 -> pc+314, consuming     *)
  (* input byte at position p, extending output by REJ_SAMPLE_ETA4_BYTES[b].   *)
  (* Entry generalized to arbitrary p so the wrapper can iterate; the          *)
  (* ~(L=255 /\ low<9) hypothesis rules out the mid-byte exit (handled by the  *)
  (* terminal segment, not this looping body).                                 *)
  (* ========================================================================= *)

  (* Nibble-value bridge: the X86_VSTEPS-produced R10 expression (low nibble) after
     `mov r10d,r11d; and r10d,15` over the movzbl-loaded byte b, collapses to
     word(val b MOD 16):int64. The zx-tower shape (byte->int16->int32 widenings)
     is exactly what VSTEPS emits for the load + zero-extends. *)
  let R10_NIBBLE_VAL = prove
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

  (* High-nibble bridge: R11 after `shr r11d,4; and r11d,15` collapses to
     word(val b DIV 16):int64. Shape matches the X86_VSTEPS emission (ushr after a
     byte->int32->int64->int32 zx-tower, then 2 more zx, then and). *)
  let R11_NIBBLE_VAL = prove
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

  (* RAX after `inc eax` over RAX=word L (L<256): the int32 inc widens back to word(L+1):int64. *)
  let RAX_INC = prove
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

  (* Store-value bridges: the scalar tail computes `4 - nibble` as int32 then the
     model wraps it in word_zx(word_zx(...)) (32->64->32 round trip) at the vmovd/store.
     For accepted nibbles (<9) this equals the spec coefficient word_sx(word_sub(word 4:int16)..).
     Proved by enumerating the 9 accepted nibble values + WORD_BLAST. *)
  let LO_STORE_VAL = prove
   (`!b:byte. val b MOD 16 < 9
     ==> word_zx(word_zx(word_sub (word 4:int32) (word_zx(word(val b MOD 16):int64):int32):int32):int64):int32 =
         word_sx(word_sub (word 4:int16) (word(val b MOD 16):int16):int16):int32`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(b:byte) MOD 16 = 0 \/ val b MOD 16 = 1 \/ val b MOD 16 = 2 \/ val b MOD 16 = 3 \/
                  val b MOD 16 = 4 \/ val b MOD 16 = 5 \/ val b MOD 16 = 6 \/ val b MOD 16 = 7 \/ val b MOD 16 = 8`
     MP_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_BLAST);;

  let HI_STORE_VAL = prove
   (`!b:byte. val b DIV 16 < 9
     ==> word_zx(word_zx(word_sub (word 4:int32) (word_zx(word(val b DIV 16):int64):int32):int32):int64):int32 =
         word_sx(word_sub (word 4:int16) (word(val b DIV 16):int16):int16):int32`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `val(b:byte) DIV 16 = 0 \/ val b DIV 16 = 1 \/ val b DIV 16 = 2 \/ val b DIV 16 = 3 \/
                  val b DIV 16 = 4 \/ val b DIV 16 = 5 \/ val b DIV 16 = 6 \/ val b DIV 16 = 7 \/ val b DIV 16 = 8`
     MP_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_BLAST);;

  (* Per-byte output-length step lemmas, one per nibble-acceptance combination.
     Drive the loop invariant's RAX update (LENGTH outlist grows by 0/1/2). *)
  let LEN_STEP_BOTH = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 9 /\ val(EL p inlist) DIV 16 < 9
     ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) + 2`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_LO = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 9 /\ ~(val(EL p inlist) DIV 16 < 9)
     ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) + 1`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_HI = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 9) /\ val(EL p inlist) DIV 16 < 9
     ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) + 1`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;
  let LEN_STEP_NONE = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 9) /\ ~(val(EL p inlist) DIV 16 < 9)
     ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) =
         LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;

  (* Per-byte output-list APPEND step, one per acceptance combination.
     Used in the body lemma's memory fold: REJ(SUB(0,p+1)) = APPEND (REJ(SUB(0,p))) <new coeffs>. *)
  let REJ_STEP_BOTH = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 9 /\ val(EL p inlist) DIV 16 < 9
     ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 4:int16) (word(val(EL p inlist) MOD 16))):int32;
                 word_sx(word_sub (word 4:int16) (word(val(EL p inlist) DIV 16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA4_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA4_BYTES_1_BOTH THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_LO = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ val(EL p inlist) MOD 16 < 9 /\ ~(val(EL p inlist) DIV 16 < 9)
     ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 4:int16) (word(val(EL p inlist) MOD 16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA4_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA4_BYTES_1_LOW_ONLY THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_HI = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 9) /\ val(EL p inlist) DIV 16 < 9
     ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) =
         APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                [word_sx(word_sub (word 4:int16) (word(val(EL p inlist) DIV 16))):int32]`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA4_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
    MATCH_MP_TAC REJ_SAMPLE_ETA4_BYTES_1_HIGH_ONLY THEN ASM_REWRITE_TAC[]);;
  let REJ_STEP_NONE = prove
   (`!(inlist:byte list) p. p < LENGTH inlist /\ ~(val(EL p inlist) MOD 16 < 9) /\ ~(val(EL p inlist) DIV 16 < 9)
     ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) = REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)`,
    REPEAT STRIP_TAC THEN MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_SAMPLE_ETA4_BYTES_STEP_1) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN `REJ_SAMPLE_ETA4_BYTES [EL p (inlist:byte list)] = []` SUBST1_TAC THENL
     [MATCH_MP_TAC REJ_SAMPLE_ETA4_BYTES_1_REJECT_BOTH THEN ASM_REWRITE_TAC[]; REWRITE_TAC[APPEND_NIL]]);;

  (* Count-exit cap lemmas for the WOP wrapper terminal case (outlen >= 256).  *)
  (* Spec side: SUB_LIST(0,256) of full REJ = SUB_LIST(0,256) of any prefix whose
     output already reached >=256 elements. *)
  let SUB_LIST_256_PREFIX_GE = prove
   (`!(inlist:byte list) k.
       k <= LENGTH inlist /\
       256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,k) inlist):int32 list)
       ==> SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist :int32 list) =
           SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,k) inlist))`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`k:num`; `inlist:byte list`] REJ_SAMPLE_ETA4_SUB_LIST_PREFIX) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(X_CHOOSE_THEN `ext:int32 list` (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [SYM th])) THEN
    MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_REWRITE_TAC[]);;

  (* --- scalar_body_lemma ---                                                 *)
  (* ========================================================================= *)
  (* SCALAR_TAIL per-byte body lemma — full proof.                             *)
  (* One trip pc+314 -> pc+314 consuming input byte at position p, extending   *)
  (* the output by REJ_SAMPLE_ETA4_BYTES[EL p inlist]. Entry generalized to    *)
  (* arbitrary p. The ~(L=255 /\ low<9) hyp rules out the mid-byte exit (that  *)
  (* case is the terminal segment, handled by the WOP wrapper, not this body). *)
  (* Loaded after main eta4 file + .scalar_tail_lemmas + .scalar_tail_build.   *)
  (* Requires type_invention_error := true.                                    *)
  (* ========================================================================= *)

  (* Common RCX closer: word_zx(word_add(word_zx(word p))(word 1)):int64 = word(p+1) for p<272. *)
  let RCX_INC_TAC =
    REWRITE_TAC[GSYM VAL_EQ] THEN
    SUBGOAL_THEN `val(word_zx(word p:int64):int32) = p` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN MP_TAC(ASSUME `p<272`) THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `val(word_zx(word_add (word_zx (word p:int64):int32) (word 1:int32)):int64) = p+1` SUBST1_TAC THENL
     [SUBGOAL_THEN `val(word_add (word_zx (word p:int64):int32) (word 1:int32)) = p + 1` ASSUME_TAC THENL
       [REWRITE_TAC[VAL_WORD_ADD; DIMINDEX_32] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN
        CONV_TAC NUM_REDUCE_CONV THEN MATCH_MP_TAC MOD_LT THEN MP_TAC(ASSUME `p<272`) THEN ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC EQ_TRANS THEN EXISTS_TAC `val(word_add (word_zx (word p:int64):int32) (word 1:int32))` THEN
      CONJ_TAC THENL [MATCH_MP_TAC VAL_WORD_ZX THEN REWRITE_TAC[DIMINDEX_32;DIMINDEX_64] THEN ARITH_TAC; ASM_REWRITE_TAC[]];
      REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
      MP_TAC(ASSUME `p<272`) THEN ARITH_TAC];;

  (* setup to s8: lands RIP=pc+343 with R10=word(val(EL p (inlist:byte list)) MOD 16), outlen0 abbreviated,
     LENGTH(REJ(SUB(0,p)))=outlen0 kept. *)
  let SCALAR_BODY_SETUP =
    REPEAT GEN_TAC THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    MP_TAC(ISPECL [`inlist:byte list`; `buf:int64`; `s0:x86state`; `p:num`; `272`] READ_1BYTE_EL) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    ABBREV_TAC `outlen0 = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)` THEN
    FIRST_X_ASSUM(fun th -> if concl th = `L:num = outlen0` then SUBST_ALL_TAC th else NO_TAC) THEN
    SUBGOAL_THEN `~(&(val(word_zx(word outlen0:int64):int32)):int - &256 = &(val(word_sub(word_zx(word outlen0:int64):int32) (word 256):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `~(&(val(word_zx(word p:int64):int32)):int - &272 = &(val(word_sub(word_zx(word p:int64):int32) (word 272):int32)))` ASSUME_TAC THENL
     [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--8) THEN
    SUBGOAL_THEN `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64` ASSUME_TAC THENL
     [AP_TERM_TAC THEN AP_TERM_TAC THEN REWRITE_TAC[MULT_CLAUSES] THEN
      MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `p < 272`) THEN ARITH_TAC; ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64`;
                                ASSUME `read (memory :> bytes8 (word_add buf (word p))) s4 = EL p (inlist:byte list)`;
                                R10_NIBBLE_VAL]) THEN
    DISCARD_OLDSTATE_TAC "s8";;

  (* prove read(bytes(addr,4)) sN = val(word_sx ...) from a spec-form bytes32 store hyp. *)
  let scalar_tail_body_tm =
   `!res buf table (inlist:byte list) pc (p:num) (L:num) stackpointer.
          LENGTH inlist = 272 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table, 2048) /\
          p < 272 /\ L < 256 /\
          L = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) /\
          ~(L = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 9)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word L /\ read RCX s = word p /\
                    read(memory :> bytes(res, 4 * L)) s =
                      num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)))
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    (let outlist = REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist) in
                     read RAX s = word(LENGTH outlist) /\ read RCX s = word(p+1) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* --- scalar_tail_run ---                                                   *)
  (* ========================================================================= *)
  (* SCALAR_TAIL_RUN: byte-loop-to-exit by strong induction on byte-budget d.  *)
  (* Needs hyp LENGTH(REJ(SUB(0,p)))<=256 (the SIMD loop exits with outlen<=256, *)
  (* so count-exit gives outlen=256 exactly = cap length). Load after main +   *)
  (* .scalar_tail_lemmas + .scalar_tail_build + .scalar_body_lemma.            *)
  (*                                                                           *)
  (* . Induction on d; 4-way split                                             *)
  (* per step: count-exit (outlen>=256), offset-exit (p=272), mid-byte exit    *)
  (* (outlen=255 /\ low<9), clean-recursive (body trip then IH at p+1 via      *)
  (* ENSURES_SEQUENCE_TAC + ENSURES_PRECONDITION/POSTCONDITION_THM).           *)
  (* ========================================================================= *)

  (* LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc) = 405 (tmc has length 406).    *)
  let LENGTH_BUTLAST_TMC = prove
   (`LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc) = 405`,
    MP_TAC(ISPEC `mldsa_rej_uniform_eta4_tmc` LENGTH_BUTLAST_GEN) THEN
    REWRITE_TAC[GSYM LENGTH_EQ_NIL; LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

  let scalar_tail_run_tm =
   `!d res buf table (inlist:byte list) pc (p:num) stackpointer.
          272 - p <= d /\
          LENGTH inlist = 272 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          p <= 272 /\
          LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 256
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
                    read RCX s = word p /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list))) s =
                      num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)))
               (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
                    (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES inlist) in
                     read RAX s = word(LENGTH outlist) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,,
                MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ========================================================================= *)
  (* SCALAR_TAIL_AT_P: the scalar-tail contract at an ARBITRARY exit position p *)
  (* (not just 16*N). This is the form CORRECT's leg-2 uses: the SIMD region   *)
  (* can exit at any sub-iter offset p (via a mid-guard), and at that exit     *)
  (* niblen(p)<=256 always holds (OUTLEN0_LE_256_FROM_SUBITER: the guard 4 bytes *)
  (* earlier ensured niblen(p-4)<=248, +<=8 = <=256), from RUN.                *)
  (* ========================================================================= *)
  let scalar_tail_at_p_tm =
   `!res buf table (inlist:byte list) pc p stackpointer.
          LENGTH inlist = 272 /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val res,1024) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (pc, 406) (val table,2048) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 272) /\
          nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
          p <= 272 /\
          LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 256
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                    read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                    read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
                    read RCX s = word p /\
                    read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list))) s =
                      num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)))
               (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
                    (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES inlist) in
                     read RAX s = word(LENGTH outlist) /\
                     read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist))
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* --- subiter_bridge_lemmas ---                                             *)
  (* ========================================================================= *)
  (* Sub-iteration spec bridges for the Phase-2 SIMD-loop RE-DECOMPOSITION.    *)
  (* eta4's SIMD loop has per-sub-iteration `cmp eax,248; ja scalar` mid-guards *)
  (* (file offsets 0xa0/0xd8/0x10d; the head 0x3c also has cmp ecx,256). To get *)
  (* the TIGHT outlen0<=256 bound at scalar-tail entry (which the 16-byte-block *)
  (* invariant only bounds <=280), the loop must be counted at 4-byte sub-iter *)
  (* granularity. Each sub-iteration adds <=8 output coefficients, and the     *)
  (* outlen<=256 bound follows from the per-sub-iter accounting below.         *)
  (* ========================================================================= *)

  (* A 4-byte sub-iteration contributes <= 8 output coefficients.              *)
  let SUBITER_STEP_BOUND_8 = prove
   (`!(inlist:byte list) k.
       LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(k,4) inlist):int32 list) <= 8`,
    REPEAT GEN_TAC THEN
    MP_TAC(ISPEC `SUB_LIST(k,4) (inlist:byte list)` LENGTH_REJ_SAMPLE_ETA4_BYTES_BOUND) THEN
    REWRITE_TAC[LENGTH_SUB_LIST] THEN ARITH_TAC);;

  (* Processing 4 more input bytes appends their samples; length grows by <= 8. *)
  let SUBITER_BRIDGE_ETA4 = prove
   (`!(inlist:byte list) p.
       p + 4 <= LENGTH inlist
       ==> REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+4) inlist):int32 list =
             APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                    (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(p,4) inlist)) /\
           LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+4) inlist):int32 list) =
             LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) +
             LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(p,4) inlist):int32 list) /\
           LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(p,4) inlist):int32 list) <= 8`,
    REPEAT STRIP_TAC THENL
     [ONCE_REWRITE_TAC[ARITH_RULE `p + 4 = 0 + (p + 4)`] THEN
      MP_TAC(ISPECL [`inlist:byte list`;`p:num`;`4`;`0`] SUB_LIST_SPLIT) THEN
      REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_APPEND];
      ONCE_REWRITE_TAC[ARITH_RULE `p + 4 = 0 + (p + 4)`] THEN
      MP_TAC(ISPECL [`inlist:byte list`;`p:num`;`4`;`0`] SUB_LIST_SPLIT) THEN
      REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES_APPEND; LENGTH_APPEND];
      REWRITE_TAC[SUBITER_STEP_BOUND_8]]);;

  (* The TIGHT bound: count <=248 before the last sub-iter guard => <=256 after *)
  (* processing the 4 bytes. This discharges SCALAR_TAIL_FROM_RUN's            *)
  (* `LENGTH(REJ(SUB(0,16N)))<=256` hypothesis from the sub-iter loop invariant. *)
  let OUTLEN0_LE_256_FROM_SUBITER = prove
   (`!(inlist:byte list) p.
       p + 4 <= LENGTH inlist /\
       LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 248
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+4) inlist):int32 list) <= 256`,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`inlist:byte list`;`p:num`] SUBITER_BRIDGE_ETA4) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
    REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in
      can (find_term (fun t -> t = `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(p,4) inlist):int32 list`)) c
      || c = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) <= 248`))) THEN
    ARITH_TAC);;

  (* Prefix monotonicity of the output count: a<=b => niblen(SUB(0,a))<=niblen(SUB(0,b)). *)
  (* Used by the sub-iter loop invariant to show no mid-guard fires before the exit step *)
  (* (if niblen(p+4)<256 then niblen at every earlier sub-iter offset is also <256). *)
  let REJ_SAMPLE_ETA4_PREFIX_MONO = prove
   (`!(inlist:byte list) a b.
       a <= b
       ==> LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,a) inlist):int32 list) <=
           LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,b) inlist):int32 list)`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `SUB_LIST(0,b) (inlist:byte list) = APPEND (SUB_LIST(0,a) inlist) (SUB_LIST(a,b-a) inlist)` SUBST1_TAC THENL
     [MP_TAC(ISPECL [`inlist:byte list`;`a:num`;`b-a`;`0`] SUB_LIST_SPLIT) THEN
      ASM_SIMP_TAC[ADD_CLAUSES; ARITH_RULE `a <= b ==> a + (b - a) = b`];
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES_APPEND_LE]]);;

  (* JA (Condition_NBE, unsigned >) TAKEN when a>k: companion of s2n-bignum's  *)
  (* JA_NOT_TAKEN_LE. Negates the not-taken disjunction. Used in the exit-block *)
  (* proof to resolve the mid-guards `cmp eax,248; ja scalar` when the running *)
  (* count exceeds 248 (the guard fires -> exit to pc+314).                    *)
  let CORRECT_LOOPINV =
   `\i s. read RSP s = stackpointer /\
          read (memory :> bytes (buf, 272)) s = num_of_wordlist inlist /\
          read (memory :> bytes (table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
          read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
          read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
          read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
          read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
          read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
          read RCX s = word(16*i) /\
          read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s =
            num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist))`;;

  (* --- midexit_prefix ---                                                    *)
  (* PREFIX_TO_S21_TAC: the bound-independent body of PREFIX_G_FULL_TAC (gather/store s17 +
     counter steps 18-21 + SUBITER_BLOCK_BYTES + m8def rewrite), reaching s21 with
     RAX=acc-popcount, RCX, store(16i+4). Uses ONLY niblen(16i)<=248 (true in all exit cases).
     Shared by the clean (not-taken) and MID-EXIT (taken) guard resolutions. *)
  (* Generator for the value + memory-safety twins of the prefix-to-s21 body     *)
  (* stepping.  The two are identical except the MS variant strips the events     *)
  (* existential right after ENSURES_INIT (STRIP_EXISTS_ASSUM_TAC), so it is a    *)
  (* `memsafe` flag toggling that one step.                                       *)
  let mk_prefix_to_s21 (memsafe:bool) : tactic =
    REPEAT GEN_TAC THEN
    (ALL_TAC THEN
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `16 * i <= 256` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC; ALL_TAC] THEN
    ENSURES_INIT_TAC "s0" THEN
    (if memsafe then STRIP_EXISTS_ASSUM_TAC else ALL_TAC) THEN
    MP_TAC(SPECL [`buf:int64`;`272`;`inlist:byte list`;`i:num`;`s0:x86state`] SUB_LIST_16_BYTES_FROM_INT128) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC; ALL_TAC] THEN
    ABBREV_TAC `chunk0 = read(memory:>bytes128(word_add buf (word(16*i)))) s0` THEN DISCH_TAC THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) <= 248` ASSUME_TAC THENL
     [FIRST [FIRST_ASSUM ACCEPT_TAC;
             (* mid-exit: derive from a later sample bound niblen(16i+4k)<=248 via prefix monotonicity *)
             (FIRST_X_ASSUM(fun th -> match concl th with
                Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),k) when k=`248`
                  -> MP_TAC th | _ -> NO_TAC) THEN
              MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
              MATCH_MP_TAC REJ_SAMPLE_ETA4_PREFIX_MONO THEN ARITH_TAC);
             (REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
              TRANS_TAC LE_TRANS `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 16 * (i+1)) inlist):int16 list)` THEN
              ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NIBLEN_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
    ABBREV_TAC `outlen0 = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)` THEN
    FIRST_ASSUM(fun th -> if concl th =
        `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list) = outlen0`
      then (RULE_ASSUM_TAC(REWRITE_RULE[th]) THEN ASSUME_TAC th) else NO_TAC) THEN
    MP_TAC(SPECL [`outlen0:num`;`248`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    MP_TAC(SPECL [`16*i`;`256`] JA_NOT_TAKEN_LE) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    VAL_INT64_TAC `outlen0:num` THEN
    X86_STEPS_TAC EXEC (1--2) THEN
    SUBGOAL_THEN `read RIP s2 = word(pc + 63):int64` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&248:int`))(concl th)
                             then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 314`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
    X86_STEPS_TAC EXEC (3--4) THEN
    SUBGOAL_THEN `read RIP s4 = word(pc + 75):int64` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_imp(concl th) && can(find_term((=)`&256:int`))(concl th)
                             then ASSUME_TAC(MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th))))) else NO_TAC) THEN
      FIRST_X_ASSUM(fun th -> if can(find_term((=)`pc + 314`))(concl th) then MP_TAC th else NO_TAC) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC; ALL_TAC] THEN
    X86_VSTEPS_TAC EXEC (5--5) THEN
    SUBGOAL_THEN `val(word(16*i):int64) = 16*i` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
      UNDISCH_TAC `16*i <= 256` THEN ARITH_TAC; ALL_TAC] THEN
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
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM2 s5 =
      word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256`]) THEN
    SUBGOAL_THEN (mk_eq(`read YMM0 s8:int256`, F0NIB_CHUNK0)) ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && can(find_term((=)`read YMM0 s8`))(lhand(concl th)) then SUBST1_TAC th else NO_TAC) THEN
      REWRITE_TAC[usimd16;usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128] THEN
      CONV_TAC WORD_BLAST; ALL_TAC] THEN
    DROP_WORDJOIN_TAC THEN PURGE_STALE_STATES_TAC ["s5";"s6";"s7"] THEN
    ASSUME_TAC(SPEC `chunk0:int128` F0NIB_BYTES) THEN
    ASSUME_TAC(SPEC `chunk0:int128` F0NIB_BYTES_HI) THEN
    ABBREV_TAC `fn:int256 = read YMM0 s8` THEN
    RULE_ASSUM_TAC(REWRITE_RULE[GSYM(ASSUME(mk_eq(`fn:int256`, F0NIB_CHUNK0)))]) THEN
    X86_VSTEPS_TAC EXEC (9--9) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s8 = fn:int256`;
       ASSUME `read YMM4 s8 = word 4086779620140571603184858294424279100703646517610843436686738259102816340233:int256`]) THEN
    ABBREV_TAC `f1bnd:int256 = read YMM1 s9` THEN
    X86_VSTEPS_TAC EXEC (10--10) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s9 = fn:int256`;
       ASSUME `read YMM3 s9 = word 1816346497840254045859937019744124044757176230049263749638550337379029484548:int256`]) THEN
    ABBREV_TAC `f0sub:int256 = read YMM0 s10` THEN
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let gather_imp = prove
         (mk_imp(concl f0d,
          `!j. j < 8 ==>
             word_subword (word_subword (f0sub:int256) (0,128):int128) (8*j,8):byte =
             word_sub (word 4) (word(EL j [val(word_subword (chunk0:int128) (0,8):byte) MOD 16;
                val(word_subword chunk0 (0,8):byte) DIV 16; val(word_subword chunk0 (8,8):byte) MOD 16;
                val(word_subword chunk0 (8,8):byte) DIV 16; val(word_subword chunk0 (16,8):byte) MOD 16;
                val(word_subword chunk0 (16,8):byte) DIV 16; val(word_subword chunk0 (24,8):byte) MOD 16;
                val(word_subword chunk0 (24,8):byte) DIV 16]):byte)`),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP gather_imp f0d)) THEN
    (* bg2: sub-iter-2 gather forall over the >>64-shifted low-lane source g2 (lanes 8-15 /
       chunk0 nibbles 32,40,48,56). Derived early (f0sub word_join live); survives to s28.
       Built as the SUBITER_STORE_SPEC gather-hyp shape so SI2_FOLD discharges by MATCH_ACCEPT. *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
        let bg2_concl = List.nth (conjuncts(lhand(concl(ISPECL [g2; `word (val (mask8b:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (32,8):byte`; `word_subword (chunk0:int128) (40,8):byte`;
             `word_subword (chunk0:int128) (48,8):byte`; `word_subword (chunk0:int128) (56,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg2_imp = prove(mk_imp(concl f0d, bg2_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            REWRITE_TAC[SUBWORD_USHR] THEN CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg2_imp f0d)) THEN
    (* bg3: sub-iter-3 gather forall over the HIGH 128 lane g3 (lanes 16-23 / chunk0 nibbles 64,72,80,88).
       No shift (vextracti128 ,1 then vpshufb). Same JOIN-extract proof as bg1 (no SUBWORD_USHR). *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
        let bg3_concl = List.nth (conjuncts(lhand(concl(ISPECL [g3; `word (val (mask8c:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (64,8):byte`; `word_subword (chunk0:int128) (72,8):byte`;
             `word_subword (chunk0:int128) (80,8):byte`; `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg3_imp = prove(mk_imp(concl f0d, bg3_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg3_imp f0d)) THEN
    (* bg4: sub-iter-4 gather forall over the HIGH 128 lane >>64 (lanes 24-31 / chunk0 nibbles 96,104,112,120). *)
    W(fun (asl,w) ->
        let f0d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f0sub:int256`) (map snd asl) in
        let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
        let bg4_concl = List.nth (conjuncts(lhand(concl(ISPECL [g4; `word (val (mask8d:int64) MOD 256):byte`;
             `word_subword (chunk0:int128) (96,8):byte`; `word_subword (chunk0:int128) (104,8):byte`;
             `word_subword (chunk0:int128) (112,8):byte`; `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC)))) 1 in
        let bg4_imp = prove(mk_imp(concl f0d, bg4_concl),
          DISCH_THEN(fun f0eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ZX_TRIVIAL] THEN
            REWRITE_TAC[SUBWORD_USHR] THEN CONV_TAC NUM_REDUCE_CONV THEN
            SIMP_TAC[WORD_SUBWORD_SUBWORD;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
            REWRITE_TAC[f0eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC)) in
        ASSUME_TAC (MP bg4_imp f0d)) THEN
    (* MASKBIT forall derived NOW (f1bnd word_join def still present): bit 7(f1bnd lane k) <=>
       EL k[chunk0 nibbles]<9. ASSUME it — survives the DROP below + downstream purges. Used by
       counter stage 3b. *)
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+16),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (64,8):byte) MOD 16; val(word_subword chunk0 (64,8):byte) DIV 16;
                    val(word_subword chunk0 (72,8):byte) MOD 16; val(word_subword chunk0 (72,8):byte) DIV 16;
                    val(word_subword chunk0 (80,8):byte) MOD 16; val(word_subword chunk0 (80,8):byte) DIV 16;
                    val(word_subword chunk0 (88,8):byte) MOD 16; val(word_subword chunk0 (88,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+24),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (96,8):byte) MOD 16; val(word_subword chunk0 (96,8):byte) DIV 16;
                    val(word_subword chunk0 (104,8):byte) MOD 16; val(word_subword chunk0 (104,8):byte) DIV 16;
                    val(word_subword chunk0 (112,8):byte) MOD 16; val(word_subword chunk0 (112,8):byte) DIV 16;
                    val(word_subword chunk0 (120,8):byte) MOD 16; val(word_subword chunk0 (120,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        let maskbit_imp2 = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*(k+8),8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (32,8):byte) MOD 16; val(word_subword chunk0 (32,8):byte) DIV 16;
                    val(word_subword chunk0 (40,8):byte) MOD 16; val(word_subword chunk0 (40,8):byte) DIV 16;
                    val(word_subword chunk0 (48,8):byte) MOD 16; val(word_subword chunk0 (48,8):byte) DIV 16;
                    val(word_subword chunk0 (56,8):byte) MOD 16; val(word_subword chunk0 (56,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp2 f1d)) THEN
    W(fun (asl,w) ->
        let f1d = find (fun th -> is_eq(concl th) && lhand(concl th) = `f1bnd:int256`) (map snd asl) in
        (* prove `f1bnd = wj ==> (!k...)` as a CLOSED implication (f1d discharged as antecedent,
           so the result has NO extra hyps), then MP with f1d. The DISCH'd eq is used to rewrite. *)
        let maskbit_imp = prove
         (mk_imp(concl f1d,
          `!k. k < 8 ==> (bit 7 (word_subword (f1bnd:int256) (8*k,8):byte) <=>
              EL k ([val(word_subword (chunk0:int128) (0,8):byte) MOD 16; val(word_subword chunk0 (0,8):byte) DIV 16;
                    val(word_subword chunk0 (8,8):byte) MOD 16; val(word_subword chunk0 (8,8):byte) DIV 16;
                    val(word_subword chunk0 (16,8):byte) MOD 16; val(word_subword chunk0 (16,8):byte) DIV 16;
                    val(word_subword chunk0 (24,8):byte) MOD 16; val(word_subword chunk0 (24,8):byte) DIV 16]:num list) < 9)`),
          DISCH_THEN(fun f1eq -> REPEAT STRIP_TAC THEN
            FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
              (ARITH_RULE `k<8 ==> k=0\/k=1\/k=2\/k=3\/k=4\/k=5\/k=6\/k=7`)) THEN
            CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
            REWRITE_TAC[f1eq] THEN
            REPEAT(CHANGED_TAC(SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
                     DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256;ARITH] THEN
              CONV_TAC NUM_REDUCE_CONV)) THEN
            REWRITE_TAC[WORD_SUBWORD_BYTE_ID] THEN
            W(fun (asl2,w2) ->
               let nibarg = find_term (fun u -> match u with
                  Comb(Comb(Const("MOD",_),_),_) | Comb(Comb(Const("DIV",_),_),_) -> true | _ -> false) w2 in
               let bt = find_term (fun u -> try fst(dest_const(fst(strip_comb u)))="word_subword" &&
                 type_of u = `:byte` && can(find_term(fun v->v=`chunk0:int128`)) u with _->false) w2 in
               let valeq = prove(mk_eq(mk_comb(`val:byte->num`, mk_comb(`word:num->byte`, nibarg)), nibarg),
                  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN MATCH_MP_TAC MOD_LT THEN
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let nlt16 = prove(mk_binop `(<):num->num->bool` nibarg `16`,
                  MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC bt VAL_BOUND)) THEN ARITH_TAC) in
               let vp = REWRITE_RULE[valeq] (SPEC (mk_comb(`word:num->byte`, nibarg)) VPSUBB_SIGN_BIT_LT_9) in
               ACCEPT_TAC (MP vp nlt16)))) in
        ASSUME_TAC (MP maskbit_imp f1d)) THEN
    (* DROP f0sub/f1bnd word_join defs BEFORE vpmovmskb (s11).
       This keeps R8/R9's vpmovmskb+popcount over the OPAQUE `f1bnd` var (via the
       `read YMM1 s10 = f1bnd` fold) instead of the expanded word_join, so stage d's popeq / low8 /
       BOOL_CASES (over `word_subword f1bnd (8k,8)`) match the popcount term. Without this, R9 s21 =
       popcount(...word_join expanded...) and stage d leaves unsolved goals. *)
    REPEAT(FIRST_X_ASSUM(fun th ->
       if is_eq(concl th) && (lhand(concl th) = `f0sub:int256` || lhand(concl th) = `f1bnd:int256`)
       then ALL_TAC else failwith "keep")) THEN
    (* ---- STEP s11-s17 FIRST (vpmovmskb, vextracti128, movzbl R10 capture, vmovq, vpshufb,
       vpmovsxbd, vmovdqu store), keeping f0sub/f1bnd defs. The gather/mask SUBGOALs are proven
       AFTER stepping: their `EL j [...]`-shaped assumptions confuse X86_VSTEPS' simulator
       (vextracti128 at s12 fails with "mk_comb: types do not agree" if they're in context). ---- *)
    X86_VSTEPS_TAC EXEC (11--11) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM1 s10 = f1bnd:int256`]) THEN
    PURGE_STALE_STATES_TAC ["s10"] THEN
    X86_VSTEPS_TAC EXEC (12--12) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read YMM0 s11 = f0sub:int256`]) THEN
    PURGE_STALE_STATES_TAC ["s11"] THEN
    REABBREV_TAC `mask8 = read R8 s12` THEN
    X86_VERBOSE_STEP_TAC EXEC "s13" THEN
    MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s12 = mask8:int64`]) THEN
    (SUBGOAL_THEN maskbit_tgt ASSUME_TAC THENL [MASKBIT_TGT_TAC; ALL_TAC]) THEN
    X86_VSTEPS_TAC EXEC (14--14) THEN
    TAB1_TEQ_TAC THEN
    REABBREV_TAC `tab1 = read YMM6 s14` THEN
    X86_VSTEPS_TAC EXEC (15--15) THEN REABBREV_TAC `pshuf1 = read YMM6 s15` THEN
    PURGE_STALE_STATES_TAC ["s14"] THEN
    X86_VSTEPS_TAC EXEC (16--16) THEN REABBREV_TAC `sx1 = read YMM1 s16` THEN
    (* stepA: establish sx1 = usimd8 word_sx (word_zx(word_zx pshuf1)) (the vpmovsxbd lane form). *)
    SUBGOAL_THEN `sx1:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf1:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx1def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx1:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx1def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    PURGE_STALE_STATES_TAC ["s15"] THEN
    X86_STEPS_TAC EXEC (17--17) THEN
    PURGE_STALE_STATES_TAC ["s16"] THEN
    X86_STEPS_TAC EXEC (18--21) THEN
    MP_TAC(ISPECL[`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES) THEN
    ANTS_TAC THENL
     [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `LENGTH(inlist:byte list) = 272` THEN
      UNDISCH_TAC `16 * i <= 256` THEN ARITH_TAC; STRIP_TAC] THEN
    W(fun (asl,w) ->
       let m8def = find (fun th -> match concl th with Comb(Comb(Const("=",_),_),Var("mask8",_)) -> true | _ -> false) (map snd asl) in
       RULE_ASSUM_TAC(fun th -> if concl th = maskbit_tgt ||
          can(find_term(fun u->match u with Const("TABLE_ENTRY",_)->true|_->false))(concl th)
          then th else REWRITE_RULE[GSYM m8def] th)) THEN
    ALL_TAC);;
    ALL_TAC;;

  (* --- midexit_subiter1 ---                                                  *)
  (* MID_EXIT_SUBITER1: sub-iter-1 mid-guard fires TAKEN -> pc+314 at pos 16i+4.
     Entry pc+52/pos=16i (q56-style), niblen(16i)<=248, niblen(16i+4)>248, 16(i+1)<=272.
     Reaches pc+314 with RCX=16i+4, RAX=niblen(16i+4), store=REJ_SAMPLE(0,16i+4).
     Composes PREFIX_TO_S21_TAC (clean gather/store/counter to s21) + the mid-guard-1 TAKEN
     resolution (mirrors PREFIX's not-taken tail but uses JA_TAKEN_GT) + SI1_FOLD_V2 store fold.
     Load after: full CLEAN_BODY chain, .midexit_prefix (PREFIX_TO_S21_TAC), .subiter_bridge_lemmas. *)

  (* midexit1_cframe: the MAYCHANGE frame shared by the mid-exit lemmas.       *)
  let midexit1_cframe =
    `MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
     MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
     MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes (res,1024)]`;;

  let midexit1_pre =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
         read RIP s = word(pc + 52) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
         read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
         read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list)) /\
         read RCX s = word(16*i) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i) inlist))`;;

  let midexit1_post =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
         read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+4) inlist):int32 list)) /\
         read RCX s = word(16*i+4) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+4) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+4) inlist))`;;

  let midexit1_tm =
    list_mk_forall([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`i:num`;`stackpointer:int64`],
    mk_imp(list_mk_conj([`LENGTH (inlist:byte list) = 272`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(res:int64),1024)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(table:int64),2048)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(table:int64),2048)`;
      `16 * (i + 1) <= 272`;
      `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i) inlist):int32 list) <= 248`;
      `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`]),
      list_mk_comb(`ensures x86`,[midexit1_pre; midexit1_post; midexit1_cframe])));;

  let mk_midexit1 (memsafe:bool) (disch:tactic) : tactic =
  (mk_prefix_to_s21 memsafe) THEN
    (* count facts                                                             *)
    SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 256` ASSUME_TAC THENL
     [MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
     [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 256` THEN ARITH_TAC; ALL_TAC] THEN
    (* pop_len: word_popcount(...) = niblen(SUB(16i,4))                        *)
    W(fun (asl,w) ->
      let r9 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("R9",_)),Var("s21",_))),_) -> true | _ -> false) asl in
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
      let blkeq = mk_eq(low8, `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)`) in
      let blk0_tm = concl(snd blk0) in
      let bsum_raw = prove(mk_imp(mb_tm, mk_imp(blk0_tm, blkeq)),
        DISCH_THEN(fun mbthm ->
          let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
            CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
          REWRITE_TAC mbs) THEN DISCH_THEN(fun b -> REWRITE_TAC[b]) THEN
        GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
        REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
        ASM_SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
      let bsum = MP (MP bsum_raw maskbit) (snd blk0) in
      let pop_len = TRANS popeq bsum in
      ASSUME_TAC pop_len) THEN
    (* bridge: outlen0 + niblen(SUB(16i,4)) = niblen_sample(16i+4)             *)
    SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)` ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`;`16*i`] SUBITER_BRIDGE_ETA4) THEN
      ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
      DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
      UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i) inlist):int32 list) = outlen0` THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
    (* lt32 + rax_red0 + ja_taken                                              *)
    SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list) < 2 EXP 32` ASSUME_TAC THENL
     [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
      UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32` THEN REWRITE_TAC[]; ALL_TAC] THEN
    W(fun (asl,w) ->
      let block0len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)` in
      let sum = mk_binop `(+):num->num->num` `outlen0:num` block0len in
      let lt32 = snd(find (fun (_,th) -> concl th = mk_binop `(<):num->num->bool` sum `2 EXP 32`) asl) in
      let pop_len = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
      let bridge = snd(find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_) -> true | _ -> false) asl) in
      let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
      let gt248 = REWRITE_RULE[SYM bridge] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`) asl)) in
      let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
      ASSUME_TAC pop_len THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (22--23) THEN
    (* resolve RIP s23 = pc+314 (mid-guard1 TAKEN)                             *)
    SUBGOAL_THEN `read RIP s23 = word (pc + 314):int64` ASSUME_TAC THENL
     [W(fun (asl,w) ->
        let blk0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
               (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
        let rax_red0 = find (fun (_,th) -> match concl th with
            Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
        let ja = find (fun (_,th) -> is_neg(concl th) &&
            can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
            can(find_term(fun u->u=`248`))(concl th)) asl in
        rip_mp memsafe 314 23 THEN
        REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
        REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
      ALL_TAC] THEN
    SI1_FOLD_V2 THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    (* discharge if-guard (taken), RAX collapse, RCX collapse                  *)
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
      let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                     (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)`)
                           (ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) < 2 EXP 32`)) in
      REWRITE_TAC[ntake]) THEN
    (* RCX collapse                                                            *)
    SUBGOAL_THEN `val(word(16*i):int64) = 16*i` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
    MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN disch;;

  (* --- midexit_subiter2 ---                                                  *)
  (* MID_EXIT_SUBITER2: sub-iter-2 mid-guard fires TAKEN -> pc+314 at pos 16i+8.
     Entry pc+52/pos=16i (q56-style), niblen(16i+4)<=248 (mg1 not taken), niblen(16i+8)>248
     (mg2 taken), 16(i+1)<=272. Reaches pc+314 with RCX=16i+8, RAX=niblen(16i+8),
     store=REJ_SAMPLE(0,16i+8).
     Composes: prefix-monotonicity prelude (niblen(16i)<=248) + PREFIX_TO_S21 + MG1_NT (mg1 not
     taken -> pc+163) + SI1_FOLD_V2 + purge leftover COND-RIP-s23 + SI2_BODY (gather/store/counter
     to s33) + SI2_MG2_TAKEN (mg2 taken -> pc+314) + ENSURES_FINAL + RAX/RCX/guard discharge.
     Load after: full CLEAN_BODY chain, .midexit_prefix (PREFIX_TO_S21_TAC), .mg1_nt (MG1_NT_TAC),
   .subiter_bridge_lemmas, .midexit_subiter1 (RCX4_COLLAPSE).. *)

  (* SI2_BODY_TAC: SI2_INTEGRATED body (gather/store-fold/counter to s33) w/o the not-taken mg2 resolve. *)
  let SI2_BODY_TAC : tactic =
    REABBREV_TAC `mask8b = read R8 s23` THEN
    ABBREV_TAC `acc1 = outlen0 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)` THEN
    ACC1_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1`]) THEN
    X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (24--24) THEN
    X86_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s25" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s24 = mask8b:int64`]) THEN
    X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (26--26) THEN TAB2_TEQ_TAC THEN REABBREV_TAC `tab2 = read YMM6 s26` THEN
    X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (27--27) THEN REABBREV_TAC `pshuf2 = read YMM6 s27` THEN
    PURGE_STALE_STATES_TAC ["s26"] THEN
    X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (28--28) THEN REABBREV_TAC `sx2 = read YMM1 s28` THEN
    VAL_INT64_TAC `acc1:num` THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (29--29) THEN
    SUBGOAL_THEN `sx2:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf2:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx2def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx2:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx2def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    (SUBGOAL_THEN maskbit_tgt_2 ASSUME_TAC THENL [MASKBIT_TGT_2_TAC; ALL_TAC]) THEN
    (SUBGOAL_THEN pf_target_2 ASSUME_TAC THENL [PF_PROOF_2; ALL_TAC]) THEN
    ACC1_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let bg2 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c) asms in
      let mthm2 = find (fun th -> concl th = maskbit_tgt_2) asms in
      let pfth2 = find (fun th -> concl th = pf_target_2) asms in
      let sx2u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx2",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
      let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s29",_))),Var("sx2",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
      let store_full = REWRITE_RULE[pfth2] (REWRITE_RULE[sx2u] storef0) in
      let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
      let m = `word (val (mask8b:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc1)):int64`; `s29:x86state`; g2; m; `LENGTH(ACC_IDX (word (val (mask8b:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g2; m; `word_subword (chunk0:int128) (32,8):byte`; `word_subword (chunk0:int128) (40,8):byte`; `word_subword (chunk0:int128) (48,8):byte`; `word_subword (chunk0:int128) (56,8):byte`] SUBITER_STORE_SPEC in
      let rej_store = REWRITE_RULE[MP spec (CONJ mthm2 bg2)] res_th0 in
      let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
      let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
      let blk1_eq = el 1 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (32,8):byte`;`word_subword (chunk0:int128) (40,8):byte`;`word_subword (chunk0:int128) (48,8):byte`;`word_subword (chunk0:int128) (56,8):byte`] LEN_RECONCILE_GEN) mthm2 in
      let lr = REWRITE_RULE[GSYM blk1_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk1_eq] rej_store in
      let acc1_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc1",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s29",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc1:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc1_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc1_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s29:x86state`;m;`SUB_LIST(16*i+4,4) (inlist:byte list)`;`SUB_LIST(0,16*i+4) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+4`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+4)+4 = 16*i+8`] fold in
      ASSUME_TAC clean) THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (30--33);;

  let me2_pre = midexit1_pre;;
  let me2_post =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
         read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+8) inlist):int32 list)) /\
         read RCX s = word(16*i+8) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+8) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+8) inlist))`;;

  let midexit2_tm =
    list_mk_forall([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`i:num`;`stackpointer:int64`],
    mk_imp(list_mk_conj([`LENGTH (inlist:byte list) = 272`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(res:int64),1024)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(table:int64),2048)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(table:int64),2048)`;
      `16 * (i + 1) <= 272`;
      `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) <= 248`;
      `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`]),
      list_mk_comb(`ensures x86`,[me2_pre; me2_post; midexit1_cframe])));;

  (* --- midexit_subiter3 ---                                                  *)
  (* MID_EXIT_SUBITER3: sub-iter-3 mid-guard fires TAKEN -> pc+314 at pos 16i+12.
     Entry pc+52/pos=16i, niblen(16i+8)<=248 (mg1,mg2 not taken), niblen(16i+12)>248 (mg3 taken),
     16(i+1)<=272. Reaches pc+314 with RCX=16i+12, RAX=niblen(16i+12), store=REJ_SAMPLE(0,16i+12).
     Load after: full CLEAN_BODY chain, .midexit_prefix, .mg1_nt, .mg2_nt, .midexit_subiter2 (SI2_BODY_TAC),
     .midexit_subiter1 (RCX4_COLLAPSE), .subiter_bridge_lemmas, .si3_full/.si3_integrated/.si3_fold_pieces
     (SI3_TAIL uses ACC2_IDENT_TAC, TAB3_TEQ_TAC, MASKBIT_TGT_3_TAC, PF_PROOF_3, etc.).
  . *)

  let SI3_BODY3_TAC : tactic =
    ABBREV_TAC `acc2 = acc1 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (16*i+4,4) inlist):int16 list)` THEN
    REABBREV_TAC `mask8c = read R8 s35` THEN
    SUBGOAL_THEN `acc2 <= 248` ASSUME_TAC THENL
     [(* after ABBREV acc2, the bridge2 (acc1+niblen(16i+4,4)=niblen_sample(16i+8)) folds to
         (acc2 = niblen_sample(16i+8)); SUBST it then ACCEPT niblen(16i+8)<=248. *)
      FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Var("acc2",_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_)))->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
      FIRST [FIRST_ASSUM ACCEPT_TAC;
             (* case-4: niblen(16i+8)<=248 from niblen(16i+12)<=248 by monotonicity *)
             (FIRST_X_ASSUM(fun th -> match concl th with
                Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),k) when k=`248`
                  -> MP_TAC th | _ -> NO_TAC) THEN
              MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
              MATCH_MP_TAC REJ_SAMPLE_ETA4_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
    VAL_INT64_TAC `acc2:num` THEN
    ACC2_IDENT_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2`]) THEN
    X86_VSTEPS_TAC EXEC (36--36) THEN
    X86_VERBOSE_STEP_TAC EXEC "s37" THEN MOVZBL_R10_CAPTURE_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s36 = mask8c:int64`]) THEN
    X86_VSTEPS_TAC EXEC (38--38) THEN TAB3_TEQ_TAC THEN REABBREV_TAC `tab3 = read YMM6 s38` THEN
    X86_VSTEPS_TAC EXEC (39--39) THEN REABBREV_TAC `pshuf3 = read YMM6 s39` THEN
    PURGE_STALE_STATES_TAC ["s38"] THEN
    X86_VSTEPS_TAC EXEC (40--40) THEN REABBREV_TAC `sx3 = read YMM1 s40` THEN
    VAL_INT64_TAC `acc2:num` THEN
    X86_STEPS_TAC EXEC (41--41) THEN
    SUBGOAL_THEN `sx3:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf3:int256):int128):int64)` ASSUME_TAC THENL
     [W(fun (asl,w) ->
         let sx3def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx3:int256` &&
             can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
         SUBST1_TAC(SYM sx3def) THEN
         REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
         CONV_TAC WORD_BLAST);
      ALL_TAC] THEN
    (SUBGOAL_THEN maskbit_tgt_3 ASSUME_TAC THENL [MASKBIT_TGT_3_TAC; ALL_TAC]) THEN
    (SUBGOAL_THEN pf_target_3 ASSUME_TAC THENL [PF_PROOF_3; ALL_TAC]) THEN
    ACC2_IDENT_TAC THEN
    W(fun (asl,w) ->
      let asms = map snd asl in
      let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
      let bg3 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
          not(can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c) &&
          can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c &&
          can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
      let mthm3 = find (fun th -> concl th = maskbit_tgt_3) asms in
      let pfth3 = find (fun th -> concl th = pf_target_3) asms in
      let sx3u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx3",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
      let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s41",_))),Var("sx3",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
      let store_full = REWRITE_RULE[pfth3] (REWRITE_RULE[sx3u] storef0) in
      let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
      let m = `word (val (mask8c:int64) MOD 256):byte` in
      let pc = ISPECL [`word_add res (word (4 * acc2)):int64`; `s41:x86state`; g3; m; `LENGTH(ACC_IDX (word (val (mask8c:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
      let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
      let spec = ISPECL [g3; m; `word_subword (chunk0:int128) (64,8):byte`; `word_subword (chunk0:int128) (72,8):byte`; `word_subword (chunk0:int128) (80,8):byte`; `word_subword (chunk0:int128) (88,8):byte`] SUBITER_STORE_SPEC in
      let rej_store = REWRITE_RULE[MP spec (CONJ mthm3 bg3)] res_th0 in
      let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
      let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
      let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
      let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (64,8):byte`;`word_subword (chunk0:int128) (72,8):byte`;`word_subword (chunk0:int128) (80,8):byte`;`word_subword (chunk0:int128) (88,8):byte`] LEN_RECONCILE_GEN) mthm3 in
      let lr = REWRITE_RULE[GSYM blk2_eq] lr0 in
      let rej_store1 = REWRITE_RULE[GSYM blk2_eq] rej_store in
      let acc2_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc2",_)) -> true | _ -> false) asms in
      let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s41",_))),_) -> true | _ -> false) &&
           hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc2:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
      let prefix_store = REWRITE_RULE[GSYM acc2_ident] prefix_store0 in
      let rej_store2 = REWRITE_RULE[GSYM acc2_ident] rej_store1 in
      let fold = MP (ISPECL [`res:int64`;`s41:x86state`;m;`SUB_LIST(16*i+8,4) (inlist:byte list)`;`SUB_LIST(0,16*i+8) (inlist:byte list)`] SUBITER_FOLD_STEP)
                    (CONJ lr (CONJ prefix_store rej_store2)) in
      let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+8`;`4`;`0`] SUB_LIST_SPLIT) in
      let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+8)+4 = 16*i+12`] fold in
      ASSUME_TAC clean) THEN
    X86_STEPS_TAC EXEC (42--45) THEN
    ALL_TAC;;

  let me3_post =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
         read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+12) inlist):int32 list)) /\
         read RCX s = word(16*i+12) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+12) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*i+12) inlist))`;;

  let midexit3_tm =
    list_mk_forall([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`i:num`;`stackpointer:int64`],
    mk_imp(list_mk_conj([`LENGTH (inlist:byte list) = 272`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(res:int64),1024)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(table:int64),2048)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(table:int64),2048)`;
      `16 * (i + 1) <= 272`;
      `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) <= 248`;
      `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`]),
      list_mk_comb(`ensures x86`,[midexit1_pre; me3_post; midexit1_cframe])));;

  (* --- midexit_case4 ---                                                     *)
  (* MID_EXIT_CASE4: all 4 sub-iters of the i=N-1-style block run clean (niblen(16i+4),16i+8,16i+12
     <=248), then at the loop back-edge pc+52/pos16(i+1) the head-guard1 (cmp eax,248) fires TAKEN
     since niblen(16(i+1))>248 -> pc+314 at pos16(i+1).
     Entry pc+52/pos=16i; hyps niblen(16i+12)<=248 (=> niblen(16i+4),16i+8 <=248 by mono),
     niblen(16(i+1))>248, 16(i+1)<=272. Reaches pc+314 with RCX=16(i+1), RAX=niblen(16(i+1)),
     store=REJ_SAMPLE(0,16(i+1)).
     Composes: PREFIX_TO_S21 + MG1_NT + SI1_FOLD + purge + SI2_BODY + MG2_NT + purge + SI3_BODY3
     + MG3_NT + purge + SI4_BODY4 (back-edge s57) + RAX-fold + head-guard1 eax-TAKEN (s58-59) +
     ENSURES_FINAL + RCX/store discharge. Load after .mg1_nt/.mg2_nt/.mg3_nt/.midexit_subiter2(SI2_BODY)
   /.midexit_subiter3(SI3_BODY3)/.si4_body4/.midexit_subiter1(RCX4_COLLAPSE).. *)

  let me4_post =
    `\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
         read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
         read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
         read(memory :> bytes(table,2048)) s = num_of_wordlist (mldsa_rej_uniform_table:byte list) /\
         read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
         read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list)) /\
         read RCX s = word(16*(i+1)) /\
         read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist):int32 list))) s =
           num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(i+1)) inlist))`;;

  let midexit4_tm =
    list_mk_forall([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`i:num`;`stackpointer:int64`],
    mk_imp(list_mk_conj([`LENGTH (inlist:byte list) = 272`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(res:int64),1024)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (pc, 406) (val(table:int64),2048)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(buf:int64), 272)`;
      `nonoverlapping_modulo (2 EXP 64) (val(res:int64),1024) (val(table:int64),2048)`;
      `16 * (i + 1) <= 272`;
      `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) <= 248`;
      `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`]),
      list_mk_comb(`ensures x86`,[midexit1_pre; me4_post; midexit1_cframe])));;

  (* ========================================================================= *)
  (* Main CORRECT theorem.                                                     *)
  (* CORRECT_SCAFFOLD_TAC reduces to the i=N-1 exit block; OFFSET_ARM_TAC /    *)
  (* MIDEXIT_ARM_TAC discharge the two niblen(16N) cases.                      *)
  (* ========================================================================= *)
  let correct_eta4_tm =
   `!res buf table (inlist:byte list) pc.
          LENGTH inlist = 272 /\
          nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
          nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
          nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
          nonoverlapping (res, 1024) (buf, 272) /\
          nonoverlapping (res, 1024) (table, 2048)
          ==> ensures x86
               (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                    read RIP s = word pc /\
                    C_ARGUMENTS [res; buf; table] s /\
                    read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                    read(memory :> bytes(table,2048)) s =
                      num_of_wordlist mldsa_rej_uniform_table)
               (\s. read RIP s = word(pc + LENGTH (BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
                    let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES inlist) in
                    let outlen = LENGTH outlist in
                    C_RETURN s = word outlen /\
                    read(memory :> bytes(res,4 * outlen)) s =
                      num_of_wordlist outlist)
               (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
                MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                           ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
                MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
                MAYCHANGE [memory :> bytes(res,1024)])`;;

  (* ------------------------------------------------------------------------- *)
  (* Subroutine correctness with array_abs_bound matching CBMC contract        *)
  (* ensures(array_abs_bound(r, 0, return_value, MLDSA_ETA + 1)) for eta = 4.  *)
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
  (* Memory safety theorem                                                     *)
end;;
