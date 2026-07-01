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
(* Coefficient (un)packing helpers shared across the polyz_unpack proofs.    *)
(* ------------------------------------------------------------------------- *)

(* Split ncoeffs d-bit coefficients into chunks of chunk_size. *)
let mk_split_theorem d ncoeffs chunk_size =
  let total = d * chunk_size in
  let nchunks = ncoeffs / chunk_size in
  let d_ty = mk_finty (Num.num_of_int d) in
  let total_ty = mk_finty (Num.num_of_int total) in
  prove(
    subst [mk_small_numeral ncoeffs, `ncoeffs:num`;
           mk_small_numeral chunk_size, `cs:num`;
           mk_small_numeral nchunks, `nc:num`]
    (inst [d_ty, `:D`; total_ty, `:T`]
      `!(l: (D word) list). LENGTH l = ncoeffs ==>
         num_of_wordlist l = num_of_wordlist (MAP ((word:num->T word) o num_of_wordlist)
           (list_of_seq (\i. SUB_LIST (cs * i, cs) l) nc))`),
    REPEAT STRIP_TAC THEN
    UNDISCH_THEN (subst [mk_small_numeral ncoeffs, `n:num`]
      (inst [d_ty, `:D`] `LENGTH (l : (D word) list) = n`)) (fun th ->
       GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
         [MATCH_MP (CONV_RULE NUM_REDUCE_CONV
           (ISPECL [mk_small_numeral chunk_size; mk_small_numeral nchunks;
                    `l:'a list`] SUBLIST_PARTITION)) th]
       THEN ASSUME_TAC th) THEN
    IMP_REWRITE_TAC [CONV_RULE (ONCE_DEPTH_CONV DIMINDEX_CONV THENC NUM_REDUCE_CONV)
      (ISPECL [inst [d_ty, `:D`] `ll: ((D word) list) list`;
               mk_small_numeral chunk_size]
        (INST_TYPE [d_ty, `:N`; total_ty, `:M`] NUM_OF_WORDLIST_FLATTEN))] THEN
    CONV_TAC(ONCE_DEPTH_CONV LIST_OF_SEQ_CONV) THEN
    ASM_REWRITE_TAC[ALL; LENGTH_SUB_LIST] THEN
    ARITH_TAC);;

(* Extract individual d-bit coefficients from a (d*chunk_size)-bit word. *)
let mk_subword_cases d chunk_size =
  let total = d * chunk_size in
  let d_ty = mk_finty (Num.num_of_int d) in
  let total_ty = mk_finty (Num.num_of_int total) in
  let arith_simp =
    let lhs = mk_eq(mk_small_numeral total,
                mk_comb(mk_comb(`( * ):num->num->num`,
                  mk_small_numeral d), `n:num`)) in
    let rhs = mk_eq(`n:num`, mk_small_numeral chunk_size) in
    ARITH_RULE (mk_eq(lhs, rhs)) in
  let meson_simp =
    let n_eq = mk_eq(`n:num`, mk_small_numeral chunk_size) in
    let k_lt_n = mk_comb(mk_comb(`(<):num->num->bool`, `k:num`), `n:num`) in
    let k_lt_cs = mk_comb(mk_comb(`(<):num->num->bool`, `k:num`),
                    mk_small_numeral chunk_size) in
    MESON[] (mk_eq(mk_conj(n_eq, k_lt_n), mk_conj(n_eq, k_lt_cs))) in
  let base =
    let th = INST_TYPE [total_ty, `:KL`; d_ty, `:L`] WORD_SUBWORD_NUM_OF_WORDLIST in
    let th = CONV_RULE(DEPTH_CONV DIMINDEX_CONV) th in
    REWRITE_RULE[arith_simp; meson_simp] th in
  let mk k =
    let th = SPEC (mk_small_numeral k)
      (SPEC (inst [d_ty, `:L`] `ls:(L word)list`) base) in
    CONV_RULE NUM_REDUCE_CONV (REWRITE_RULE[ARITH] th) in
  map mk (0 -- (chunk_size - 1));;

(* Split a 256-element 32-bit-word list into 32 chunks of 8 (256-bit words),
   used to express the output spec as 32 store-sized pieces. *)
let NUM_OF_WORDLIST_SPLIT_32_256_8 = prove
 (`!(L:(32 word) list). LENGTH L = 256 ==> num_of_wordlist L =
     num_of_wordlist (MAP ((word:num->256 word) o num_of_wordlist)
       (list_of_seq (\i. SUB_LIST(8*i,8) L) 32))`,
  REPEAT STRIP_TAC THEN
  UNDISCH_THEN `LENGTH(L:(32 word)list)=256` (fun th ->
    GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
      [MATCH_MP (CONV_RULE NUM_REDUCE_CONV
        (ISPECL [`8`;`32`;`L:(32 word)list`] SUBLIST_PARTITION)) th] THEN ASSUME_TAC th) THEN
  IMP_REWRITE_TAC[CONV_RULE(ONCE_DEPTH_CONV DIMINDEX_CONV THENC NUM_REDUCE_CONV)
    (ISPECL [`ll:((32 word)list)list`;`8`] (INST_TYPE[`:32`,`:N`;`:256`,`:M`] NUM_OF_WORDLIST_FLATTEN))] THEN
  CONV_TAC(ONCE_DEPTH_CONV LIST_OF_SEQ_CONV) THEN
  ASM_REWRITE_TAC[ALL;LENGTH_SUB_LIST] THEN ARITH_TAC);;

(* MAP commutes with SUB_LIST. *)
let MAP_SUB_LIST = prove
 (`!(f:A->B) p q l. MAP f (SUB_LIST(p,q) l) = SUB_LIST(p,q) (MAP f l)`,
  GEN_TAC THEN
  ONCE_REWRITE_TAC[MESON[] `(!p q l. P p q l) <=> (!l p q. P p q l)`] THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[MAP; SUB_LIST_CLAUSES] THEN
  REPEAT GEN_TAC THEN SPEC_TAC(`q:num`,`q:num`) THEN SPEC_TAC(`p:num`,`p:num`) THEN
  MATCH_MP_TAC num_INDUCTION THEN ASM_REWRITE_TAC[SUB_LIST_CLAUSES; MAP] THEN
  REPEAT STRIP_TAC THEN SPEC_TAC(`q:num`,`q:num`) THEN MATCH_MP_TAC num_INDUCTION THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES; MAP]);;

(* ------------------------------------------------------------------------- *)
(* Shared 256-bit-block / 8-lane framework for the in-place poly routines     *)
(* (poly_use_hint_32/88 etc.) that loop over 32 blocks of eight int32 lanes.   *)
(* These are arch-independent of the per-coefficient model.                    *)
(* ------------------------------------------------------------------------- *)

(* Eight consecutive int32 coefficients packed into one 256-bit word. *)
let pack8 = new_definition
  `pack8 (f:num->int32) (b:num) : int256 =
     word_join
       (word_join (word_join (f (8*b+7)) (f (8*b+6)):int64)
                  (word_join (f (8*b+5)) (f (8*b+4)):int64):int128)
       (word_join (word_join (f (8*b+3)) (f (8*b+2)):int64)
                  (word_join (f (8*b+1)) (f (8*b+0)):int64):int128)`;;

(* Lane k (k<8) of a packed block is coefficient 8b+k. *)
let PACK8_LANE = prove(
  `!f b. !k. k < 8 ==> word_subword (pack8 f b) (32*k,32):int32 = f(8*b+k)`,
  GEN_TAC THEN GEN_TAC THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[pack8] THEN REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

(* Lane k of a SIMD8 map is the scalar map applied to the corresponding lanes. *)
let SIMD8_LANE = prove(
  `!(g:int32->int32->int32) av hv. !k. k < 8 ==>
      word_subword (simd8 g av hv) (32*k,32):int32 =
      g (word_subword av (32*k,32)) (word_subword hv (32*k,32))`,
  GEN_TAC THEN GEN_TAC THEN GEN_TAC THEN
  REWRITE_TAC[simd8;simd4;simd2;DIMINDEX_32] THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT CONJ_TAC THEN CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN REFL_TAC);;

(* Coefficient address 4*(8b+k) split into block base 32*b plus lane offset. *)
let ADDR_SPLIT = prove(
  `!p:int64 b k. word_add p (word(4*(8*b+k))) =
                 word_add (word_add p (word(32*b))) (word(4*k))`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ARITH_RULE `4*(8*b+k) = 32*b+4*k`] THEN
  CONV_TAC WORD_RULE);;

(* A coefficient (bytes32) read is the matching lane of the block (bytes256) read. *)
let BLOCK_SPLIT = prove(
  `!p:int64 s:x86state b. !k. k < 8 ==>
      read (memory :> bytes32 (word_add p (word(4*(8*b+k))))) s =
      word_subword (read (memory :> bytes256 (word_add p (word(32*b)))) s) (32*k,32):int32`,
  GEN_TAC THEN GEN_TAC THEN GEN_TAC THEN
  CONV_TAC(RAND_CONV(ONCE_DEPTH_CONV(READ_MEMORY_MERGE_CONV 3))) THEN
  GEN_REWRITE_TAC (BINDER_CONV o RAND_CONV o LAND_CONV o ONCE_DEPTH_CONV) [ADDR_SPLIT] THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[WORD_RULE `word_add q (word 0) = q`] THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

(* The block (bytes256) read assembles from its eight coefficient reads. *)
let PACK8_MERGE = prove(
  `!(x:num->int32) p:int64 s:x86state b.
      b < 32 /\
      (!i. i < 256 ==> read(memory :> bytes32(word_add p (word(4*i)))) s = x i)
      ==> read (memory :> bytes256 (word_add p (word(32*b)))) s = pack8 x b`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[pack8] THEN
  CONV_TAC(LAND_CONV(READ_MEMORY_MERGE_CONV 3)) THEN
  SUBGOAL_THEN
   `!k. k < 8 ==> read (memory :> bytes32 (word_add (word_add p (word(32*b))) (word(4*k)))) (s:x86state) = x(8*b+k)`
   (fun th ->
      MP_TAC(SPEC `0` th) THEN MP_TAC(SPEC `1` th) THEN MP_TAC(SPEC `2` th) THEN MP_TAC(SPEC `3` th) THEN
      MP_TAC(SPEC `4` th) THEN MP_TAC(SPEC `5` th) THEN MP_TAC(SPEC `6` th) THEN MP_TAC(SPEC `7` th)) THENL
   [GEN_TAC THEN DISCH_TAC THEN REWRITE_TAC[GSYM ADDR_SPLIT] THEN
    FIRST_X_ASSUM(fun th -> MP_TAC(SPEC `8*b+k` th)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `b:num<32` THEN UNDISCH_TAC `k:num<8` THEN ARITH_TAC; SIMP_TAC[]];
    CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[WORD_RULE `word_add q (word 0) = q`] THEN
    REPEAT(DISCH_THEN SUBST1_TAC) THEN REFL_TAC]);;

(* Two int256 words agree if all eight 32-bit lanes agree. *)
let LANES8_EQ = prove
 (`!x y:int256. (!k. k < 8 ==> word_subword x (32*k,32):int32 = word_subword y (32*k,32)) ==> x = y`,
  REPEAT GEN_TAC THEN
  DISCH_THEN(fun th -> MP_TAC(CONV_RULE(EXPAND_CASES_CONV THENC NUM_REDUCE_CONV) th)) THEN
  CONV_TAC WORD_BLAST);;

(* 32-byte blocks preserve 32-byte alignment of the base pointer. *)
let ALIGNED_32I = prove
 (`!i. aligned 32 (word(32*i):int64)`,
  GEN_TAC THEN REWRITE_TAC[aligned; DIMINDEX_64; VAL_WORD; DIMINDEX_64] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[DIVIDES_MOD] THEN CONV_TAC NUM_REDUCE_CONV;
    MP_TAC(SPECL [`32`; `32 * i`; `2 EXP 64`] DIVIDES_MOD2) THEN
    ANTS_TAC THENL
     [REWRITE_TAC[DIVIDES_MOD] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN NUMBER_TAC]);;

let ALIGNED_BLOCK = prove
 (`!a:int64 i. aligned 32 a ==> aligned 32 (word_add a (word(32*i)))`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC ALIGNED_WORD_ADD THEN
  ASM_REWRITE_TAC[ALIGNED_32I]);;

(* word_join of a zero high half is just zero-extension of the low half. *)
let JOIN_ZERO_ZX = prove
 (`!lo:(16)word. word_join (word 0:(16)word) lo :int32 = word_zx lo`,
  GEN_TAC THEN CONV_TAC WORD_BLAST);;

(* word_ile/word_igt against 0 are complementary on int32. *)
let ILE_IGT = BITBLAST_RULE
  `!a0:int32. word_ile a0 (word 0) <=> ~(word_igt a0 (word 0))`;;

let WORD_NOT_0 = WORD_RULE `!x:N word. word_and x (word_not (word 0)) = x`;;

(* Per-step state compaction during SIMD body simulation: abbreviate every large
   int256 register value to a fresh atom so it propagates compactly (essential
   for instructions like VPBLENDVB whose byte-mux otherwise duplicates the value). *)
let ABBREV_BIG_TAC : tactic = fun (asl,w) ->
  MAP_EVERY (fun (_,th) -> AUTO_ABBREV_TAC (rand(concl th)))
    (filter (fun (_,th) -> let c=concl th in is_eq c &&
       (try is_comb(lhs c) && fst(dest_const(fst(strip_comb(lhs c))))="read"
            && type_of(lhs c)=`:int256` && not(is_var(rand c)) with _->false)
       && String.length(string_of_term(rand c)) > 1500) asl) (asl,w);;

(* ------------------------------------------------------------------------- *)
(* Shared scalar UseHint lemmas (poly_use_hint_32/88).  Arch- and            *)
(* parameter-independent: the per-coefficient Barrett rounding, lane         *)
(* value/sign-extension facts and the +/-1 delta-encoding bridge.            *)
(* ------------------------------------------------------------------------- *)

(* Rounding division: ((q DIV n) + 1) DIV 2 = (q + n) DIV (2 * n). *)
let ROUND_DIV = prove(`!q n. ~(n = 0) ==> (q DIV n + 1) DIV 2 = (q + n) DIV (2 * n)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `(q + n) DIV (2 * n) = (q + n) DIV n DIV 2` SUBST1_TAC THENL
  [REWRITE_TAC[DIV_DIV] THEN AP_TERM_TAC THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(q + n) DIV n = q DIV n + 1` (fun th -> REWRITE_TAC[th]) THEN
  ASM_SIMP_TAC[DIV_ADD; DIVIDES_REFL] THEN ASM_SIMP_TAC[DIV_REFL]);;

(* The pre-shift t = (a + 127) >>u 7 has value (val a + 127) DIV 128 (no overflow
   since val a < Q < 2^31). This is the f1' input to the Barrett step. *)
let VAL_T = prove(`!x:int32. val x < 8380417
   ==> val(word_ushr (word_add (word 127) x) 7 :int32) = (val x + 127) DIV 128`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[VAL_WORD_USHR] THEN
  SUBGOAL_THEN `val(word_add (word 127:int32) x) = val x + 127` SUBST1_TAC THENL
  [REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
   SUBGOAL_THEN `(127 + val(x:int32)) MOD 4294967296 = 127 + val x`
     (fun th -> REWRITE_TAC[th] THEN ARITH_TAC) THEN
   MATCH_MP_TAC MOD_LT THEN MP_TAC(ISPEC `x:int32` VAL_BOUND) THEN
   REWRITE_TAC[DIMINDEX_32] THEN ASM_ARITH_TAC;
   REWRITE_TAC[ARITH_RULE `2 EXP 7 = 128`]]);;

(* Bounded 16->32 sign-extension equals zero-extension on value: for a 16-bit
   lane below 2^15 (top bit clear) word_sx agrees with the numeric value. Used to
   evaluate the signed 16x16 multiply in the vpmulhrsw lane. *)
let VAL_WORD_SX_SMALL = prove(`!u:16 word. val u < 32768
   ==> val((word_sx u):int32) = val u`,
  GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `(word_sx (u:16 word)):int32 = word_zx u` SUBST1_TAC THENL
  [REWRITE_TAC[WORD_SX_ZX_GEN; DIMINDEX_16] THEN
   CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
   SUBGOAL_THEN `bit 15 (u:16 word) = F` SUBST1_TAC THENL
   [REWRITE_TAC[BIT_VAL] THEN ASM_ARITH_TAC; ALL_TAC] THEN
   REWRITE_TAC[BITVAL_CLAUSES;
               WORD_REDUCE_CONV `word_shl (word_neg (word 0:int32)) 16`;
               WORD_OR_0]; ALL_TAC] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN `val(u:16 word) MOD 4294967296 = val u` (fun th->REWRITE_TAC[th]) THEN
  MATCH_MP_TAC MOD_LT THEN MP_TAC(ISPEC `u:16 word` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_16] THEN ARITH_TAC);;

(* delta encoding bridge (needs the hint bound val h <= 1):
   the assembly computes delta*h as h - (andnot(dlt,h))<<1 with
   dlt = (a0 >s 0); the model uses word_mul of the +1/-1 delta. *)
let DELTA_EQ_BOUNDED = prove
 (`!a0:int32 h:int32. val h <= 1 ==>
     word_sub h (word_shl (word_and (word_not
        (if word_igt a0 (word 0) then word 4294967295 else word 0)) h) 1) =
     word_mul (word_or (word_neg (word (bitval (word_ile a0 (word 0))))) (word 1)) h`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN REWRITE_TAC[ILE_IGT] THEN
  SUBGOAL_THEN `h:int32 = word 0 \/ h = word 1` STRIP_ASSUME_TAC THENL
   [POP_ASSUM MP_TAC THEN SPEC_TAC(`h:int32`,`h:int32`) THEN
    REWRITE_TAC[GSYM VAL_EQ_0; GSYM VAL_EQ_1] THEN ARITH_TAC;
    ASM_REWRITE_TAC[] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_BLAST;
    ASM_REWRITE_TAC[] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC WORD_BLAST]);;

(* ------------------------------------------------------------------------- *)
(* Barrett-quotient DIV/MOD tactics over the per-variant divisor 2*GAMMA2     *)
(* (gg below): 523776 for poly_use_hint_32, 190464 for poly_use_hint_88.      *)
(* Each proof aliases these at its concrete gg.                               *)
(* ------------------------------------------------------------------------- *)

(* Eliminate `r MOD gg` / `r DIV gg` from the assumptions and abstract them,
   leaving an arithmetic goal solvable by ASM_ARITH_TAC. *)
let LINEARIZE_DIV_MOD_BY_TAC gg =
  let s = subst [mk_small_numeral gg, `gg:num`] in
  REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th ->
    free_in (s `r MOD gg`) (concl th) || free_in (s `r DIV gg`) (concl th)))) THEN
  MP_TAC(SPECL [`r:num`; mk_small_numeral gg] (CONJUNCT1 DIVISION_SIMP)) THEN
  SPEC_TAC(s `r MOD gg`, `m:num`) THEN
  SPEC_TAC(s `r DIV gg`, `q:num`) THEN
  REPEAT GEN_TAC THEN ASM_ARITH_TAC;;

(* Replace `(r - r MOD gg) DIV gg` with `r DIV gg`. *)
let DIV_MOD_TO_DIV_BY_TAC gg =
  let s = subst [mk_small_numeral gg, `gg:num`] in
  SUBGOAL_THEN (s `(r - r MOD gg) DIV gg = r DIV gg`) SUBST1_TAC THENL
  [MP_TAC(SPECL [`r:num`; mk_small_numeral gg] (CONJUNCT1 DIVISION_SIMP)) THEN
   DISCH_TAC THEN
   SUBGOAL_THEN (s `r - r MOD gg = gg * r DIV gg`) SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
   MP_TAC(SPECL [mk_small_numeral gg; s `r DIV gg`] DIV_MULT) THEN
   CONV_TAC NUM_REDUCE_CONV; ALL_TAC];;

(* Prove `r DIV gg = k` via DIV_SANDWICH + LE_MULT_RCANCEL. *)
let DIV_EQ_K_BY_TAC gg k =
  let s = subst [mk_small_numeral gg, `gg:num`] in
  let k_num = mk_small_numeral k and km1 = mk_small_numeral (k-1)
  and kp1 = mk_small_numeral (k+1)
  and q = mk_var("q",`:num`) and le = `(<=):num->num->bool`
  and lt = `(<):num->num->bool` and c = mk_small_numeral gg in
  let mk_mul a b = mk_binop (rator(rator `0*0`)) a b in
  MATCH_MP_TAC DIV_SANDWICH THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th ->
    free_in (s `r MOD gg`) (concl th) || free_in (s `r DIV gg`) (concl th)))) THEN
  MP_TAC(SPECL [`r:num`; c] (CONJUNCT1 DIVISION_SIMP)) THEN
  SPEC_TAC(s `r MOD gg`, `m:num`) THEN
  SPEC_TAC(s `r DIV gg`, q) THEN
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  ASM_CASES_TAC(mk_comb(mk_comb(le, q), km1)) THENL
  [SUBGOAL_THEN(mk_comb(mk_comb(le, mk_mul q c), mk_mul km1 c)) ASSUME_TAC THENL
   [ASM_SIMP_TAC[LE_MULT_RCANCEL]; ALL_TAC] THEN
   CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC;
   SUBGOAL_THEN(mk_comb(mk_comb(le, mk_mul k_num c), mk_mul q c)) ASSUME_TAC THENL
   [ASM_SIMP_TAC[LE_MULT_RCANCEL] THEN DISJ1_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
   ASM_CASES_TAC(mk_comb(mk_comb(lt, k_num), q)) THENL
   [SUBGOAL_THEN(mk_comb(mk_comb(le, mk_mul kp1 c), mk_mul q c)) ASSUME_TAC THENL
    [ASM_SIMP_TAC[LE_MULT_RCANCEL] THEN DISJ1_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC;
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC]];;
