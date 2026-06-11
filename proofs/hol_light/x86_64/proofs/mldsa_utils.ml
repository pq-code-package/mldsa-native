(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ------------------------------------------------------------------------- *)
(* Some convenient proof tools.                                              *)
(* ------------------------------------------------------------------------- *)

let READ_MEMORY_MERGE_CONV =
  let baseconv =
    GEN_REWRITE_CONV I [READ_MEMORY_BYTESIZED_SPLIT] THENC
    LAND_CONV(LAND_CONV(RAND_CONV(RAND_CONV
     (TRY_CONV(GEN_REWRITE_CONV I [GSYM WORD_ADD_ASSOC] THENC
               RAND_CONV WORD_ADD_CONV))))) in
  let rec conv n tm =
    if n = 0 then REFL tm else
    (baseconv THENC BINOP_CONV (conv(n - 1))) tm in
  conv;;

let READ_MEMORY_SPLIT_CONV =
  let baseconv =
    GEN_REWRITE_CONV I [READ_MEMORY_BYTESIZED_UNSPLIT] THENC
    BINOP_CONV(LAND_CONV(LAND_CONV(RAND_CONV(RAND_CONV
     (TRY_CONV(GEN_REWRITE_CONV I [GSYM WORD_ADD_ASSOC] THENC
               RAND_CONV WORD_ADD_CONV)))))) in
  let rec conv n tm =
    if n = 0 then REFL tm else
    (baseconv THENC BINOP_CONV (conv(n - 1))) tm in
  conv;;

let MEMORY_128_FROM_16_TAC =
  let a_tm = `a:int64` and n_tm = `n:num` and i64_ty = `:int64`
  and pat = `read (memory :> bytes128(word_add a (word n))) s0` in
  fun v n ->
    let pat' = subst[mk_var(v,i64_ty),a_tm] pat in
    let f i =
      let itm = mk_small_numeral(16*i) in
      READ_MEMORY_MERGE_CONV 3 (subst[itm,n_tm] pat') in
    MP_TAC(end_itlist CONJ (map f (0--(n-1))));;

(* This tactic repeated calls `f n with monotonically increasing values of n
   until the target PC matches one of the assumptions.

   The goal must be of the form `ensure arm ...`. Clauses constraining the PC
   must be of the form `read PC some_state = some_value`. *)
let MAP_UNTIL_TARGET_PC f n = fun (asl, w) ->
  let is_pc_condition = can (term_match [] `read PC some_state = some_value`) in
  (* We assume that the goal has the form
     `ensure arm (\s. ... /\ read PC s = some_value /\ ...)` *)
  let extract_target_pc_from_goal goal =
    let _, insts, _ = term_match [] `eventually x86 (\s'. P) some_state` goal in
    insts
      |> rev_assoc `P: bool`
      |> conjuncts
      |> find is_pc_condition in
  (* Find PC-constraining assumption from the list of all assumptions. *)
  let extract_pc_assumption asl =
    try Some (find (is_pc_condition o concl o snd) asl |> snd |> concl) with find -> None in
  (* Check if there is an assumption constraining the PC to the target PC *)
  let has_matching_pc_assumption asl target_pc =
    match extract_pc_assumption asl with
     | None -> false
     | Some(asm) -> can (term_match [`returnaddress: 64 word`; `pc: num`] target_pc) asm in
  let target_pc = extract_target_pc_from_goal w in
  (* ALL_TAC if we reached the target PC, NO_TAC otherwise, so
     TARGET_PC_REACHED_TAC target_pc ORELSE SOME_OTHER_TACTIC
     is effectively `if !(target_pc_reached) SOME_OTHER_TACTIC` *)
  let TARGET_PC_REACHED_TAC target_pc = fun (asl, w) ->
    if has_matching_pc_assumption asl target_pc then
      ALL_TAC (asl, w)
    else
      NO_TAC (asl, w) in
  let rec core n (asl, w) =
    (TARGET_PC_REACHED_TAC target_pc ORELSE (f n THEN core (n + 1))) (asl, w)
  in
    core n (asl, w);;

(* ------------------------------------------------------------------------- *)
(* Word-arithmetic helper lemmas shared by the poly_decompose_{32,88} AVX2   *)
(* proofs. These are x86-only and live here (rather than common/) so they do *)
(* not leak into the AArch64 proofs, which carry their own copies.           *)
(* ------------------------------------------------------------------------- *)

(* val of the right-shift-by-7 of (x+127), for in-range x. *)
let H_T = prove(
  `!x:int32. val x < 8380417 ==>
     val(word_ushr (word_add (x:int32) (word 127)) 7) = (val x + 127) DIV 128`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[VAL_WORD_USHR; VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN `(val(x:int32) + 127) MOD 4294967296 = val x + 127` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; REWRITE_TAC[]]);;

(* The shifted value stays below the next power-of-two boundary. *)
let T_BOUND = prove(
  `!x:int32. val x < 8380417 ==> (val x + 127) DIV 128 < 65473`,
  GEN_TAC THEN DISCH_TAC THEN
  SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(128 = 0)`] THEN ASM_ARITH_TAC);;

(* DIV bound helper: pins a quotient from a multiplicative bracket. *)
let DIV_BOUNDS_EQ = prove(
  `!b d q. ~(d = 0) /\ q * d <= b /\ b < (q + 1) * d ==> b DIV d = q`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC(ARITH_RULE `q <= r /\ r < q + 1 ==> r = q`) THEN
  CONJ_TAC THENL
   [ASM_SIMP_TAC[LE_RDIV_EQ] THEN ASM_ARITH_TAC;
    ASM_SIMP_TAC[RDIV_LT_EQ] THEN ASM_ARITH_TAC]);;

(* ival = val for in-range positive int32. *)
let IVAL_EQ_VAL = prove(
  `!x:int32. val x < 2 EXP 31 ==> ival x = &(val x)`,
  GEN_TAC THEN REWRITE_TAC[IVAL_VAL; DIMINDEX_32] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_EXP_CONV) THEN
  DISCH_TAC THEN
  SUBGOAL_THEN `bit (32 - 1) (x:int32) = F` ASSUME_TAC THENL
   [REWRITE_TAC[BIT_VAL; DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC;
    ASM_REWRITE_TAC[bitval] THEN INT_ARITH_TAC]);;

(* val of a 16->32 sign extension when the source is below 2^15. *)
let VAL_SX_16_32 = prove(
  `!w:16 word. val w < 32768 ==> val(word_sx w:int32) = val w`,
  GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `bit 15 (w:16 word) = F` ASSUME_TAC THENL
   [REWRITE_TAC[BIT_VAL; DIMINDEX_16] THEN CONV_TAC NUM_REDUCE_CONV THEN
    SUBGOAL_THEN `val(w:16 word) DIV 32768 = 0` SUBST1_TAC THENL
     [MATCH_MP_TAC DIV_LT THEN ASM_REWRITE_TAC[]; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
  SUBGOAL_THEN `ival(w:16 word) = &(val w)` ASSUME_TAC THENL
   [MP_TAC(ISPEC `w:16 word` VAL_IVAL) THEN
    REWRITE_TAC[DIMINDEX_16; ARITH_RULE `16 - 1 = 15`] THEN
    ASM_REWRITE_TAC[BITVAL_CLAUSES; INT_MUL_RZERO; INT_ADD_RID] THEN INT_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `ival(word_sx (w:16 word):int32) = &(val w)` ASSUME_TAC THENL
   [MP_TAC(ISPECL [`w:16 word`] (INST_TYPE [`:16`,`:M`; `:32`,`:N`] IVAL_WORD_SX)) THEN
    REWRITE_TAC[DIMINDEX_16; DIMINDEX_32] THEN ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[]; ALL_TAC] THEN
  MP_TAC(ISPEC `word_sx (w:16 word):int32` VAL_IVAL) THEN
  REWRITE_TAC[DIMINDEX_32; ARITH_RULE `32 - 1 = 31`] THEN
  SUBGOAL_THEN `bit 31 (word_sx (w:16 word):int32) = F` SUBST1_TAC THENL
   [MP_TAC(ISPEC `word_sx (w:16 word):int32` MSB_IVAL) THEN
    REWRITE_TAC[DIMINDEX_32; ARITH_RULE `32 - 1 = 31`] THEN DISCH_THEN SUBST1_TAC THEN
    ASM_REWRITE_TAC[] THEN INT_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[BITVAL_CLAUSES; INT_MUL_RZERO; INT_ADD_RID] THEN
  ASM_REWRITE_TAC[] THEN REWRITE_TAC[INT_OF_NUM_EQ] THEN ASM_MESON_TAC[]);;

(* Signed comparison against a non-negative bound below 2^31: word_igt
   reduces to a comparison on the signed interpretation. Parameterized over
   the threshold b (variant-specific GAMMA2-derived constant). *)
let IGT_BOUND_GEN = prove(
  `!x:int32 b. b < 2147483648 ==> (word_igt x (word b) <=> ival x > &b)`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `ival(word b:int32) = &b` ASSUME_TAC THENL
   [MP_TAC(ISPEC `word b:int32` IVAL_EQ_VAL) THEN
    REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN
    SUBGOAL_THEN `b MOD 2 EXP 32 = b` SUBST1_TAC THENL
     [MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `b < 2147483648` THEN ARITH_TAC;
      ANTS_TAC THENL [UNDISCH_TAC `b < 2147483648` THEN ARITH_TAC; SIMP_TAC[]]];
    ASM_REWRITE_TAC[WORD_IGT; irelational2; GT]]);;

(* High 16 bits of a 16x16->32 unsigned multiply (VPMULHUW lane semantics).
   Parameterized over the multiplier m (the Barrett magic constant). *)
let MULHI_LANE_GEN = prove(
  `!t:int32 m. val t < 65536 /\ m < 65536 ==>
     val(word_subword (word_mul (word_zx (word_subword t (0,16):16 word):int32)
                                (word m)) (16,16):16 word) =
     (val t * m) DIV 65536`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `val(t:int32) * m < 4294967296` ASSUME_TAC THENL
   [MATCH_MP_TAC LET_TRANS THEN EXISTS_TAC `65535 * 65535` THEN
    CONJ_TAC THENL [MATCH_MP_TAC LE_MULT2 THEN ASM_ARITH_TAC; ARITH_TAC];
    ALL_TAC] THEN
  REWRITE_TAC[VAL_WORD_SUBWORD; VAL_WORD_MUL; VAL_WORD_ZX_GEN; VAL_WORD;
              DIMINDEX_16; DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN `val(t:int32) DIV 1 = val t /\ val(t:int32) MOD 65536 = val t`
    (fun th -> REWRITE_TAC[th]) THENL
   [ASM_SIMP_TAC[DIV_1; MOD_LT]; ALL_TAC] THEN
  SUBGOAL_THEN `val(t:int32) MOD 4294967296 = val t /\ m MOD 4294967296 = m`
    (fun th -> REWRITE_TAC[th]) THENL
   [CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(val(t:int32) * m) MOD 4294967296 = val t * m` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  MATCH_MP_TAC MOD_LT THEN
  SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(65536 = 0)`] THEN ASM_ARITH_TAC);;

(* word_not distributes over word_join at the 64/128/256-bit AVX2 lane widths. *)
let WORD_NOT_JOIN_64 = WORD_BLAST
  `!a b : int32. word_not ((word_join:int32->int32->int64) a b) =
   word_join (word_not a) (word_not b)`;;
let WORD_NOT_JOIN_128 = WORD_BLAST
  `!a b : int64. word_not ((word_join:int64->int64->int128) a b) =
   word_join (word_not a) (word_not b)`;;
let WORD_NOT_JOIN_256 = WORD_BLAST
  `!a b : int128. word_not ((word_join:int128->int128->int256) a b) =
   word_join (word_not a) (word_not b)`;;
