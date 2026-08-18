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

(* ------------------------------------------------------------------------- *)
(* Byte->nibble decomposition helpers, shared between the eta2/eta4          *)
(* rejection-sampling proofs.                                                *)
(*                                                                           *)
(* NIBBLES_OF_BYTES stores the two nibbles of each byte in int16 lanes,      *)
(* matching the SIMD register layout the loop body works in. The public     *)
(* REJ_SAMPLE_ETA{2,4} spec instead uses BYTES_TO_NIBBLES at the natural     *)
(* 4-bit width; the two views are bridged in the proofs.                     *)
(* ------------------------------------------------------------------------- *)

let NIBBLE_PAIR = define
  `NIBBLE_PAIR (b:byte) =
   [word(val b MOD 16):int16; word(val b DIV 16):int16]`;;

let NIBBLES_OF_BYTES = define
  `NIBBLES_OF_BYTES [] = ([]:(int16)list) /\
   NIBBLES_OF_BYTES (CONS (b:byte) t) =
   APPEND (NIBBLE_PAIR b) (NIBBLES_OF_BYTES t)`;;

let NIBBLES_OF_BYTES_APPEND = prove
 (`!l1 l2. NIBBLES_OF_BYTES(APPEND l1 l2) =
           APPEND (NIBBLES_OF_BYTES l1) (NIBBLES_OF_BYTES l2)`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; APPEND; APPEND_ASSOC]);;

(* Splits each input byte into its low and high 4-bit nibbles at the natural *)
(* 4-bit width consumed by the REJ_SAMPLE_ETA{2,4} spec. The output is twice *)
(* the length of the input.                                                  *)
let BYTES_TO_NIBBLES = define
  `BYTES_TO_NIBBLES [] = ([]:(4 word) list) /\
   BYTES_TO_NIBBLES (CONS (b:byte) t) =
   APPEND [word(val b MOD 16):4 word; word(val b DIV 16):4 word]
          (BYTES_TO_NIBBLES t)`;;

(* Bridge lemmas relating the byte-list and nibble-list views, used at the    *)
(* subroutine-spec boundary to state the public spec over a (4 word) list.    *)

let LENGTH_BYTES_TO_NIBBLES = prove
 (`!l:byte list. LENGTH(BYTES_TO_NIBBLES l) = 2 * LENGTH l`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[BYTES_TO_NIBBLES; LENGTH; LENGTH_APPEND] THEN ARITH_TAC);;

let NUM_OF_BYTES_TO_NIBBLES = prove
 (`!l:byte list. num_of_wordlist (BYTES_TO_NIBBLES l) = num_of_wordlist l`,
  LIST_INDUCT_TAC THEN
  REWRITE_TAC[BYTES_TO_NIBBLES; num_of_wordlist; NUM_OF_WORDLIST_APPEND;
              LENGTH; DIMINDEX_4; DIMINDEX_8; VAL_WORD; MOD_MOD_REFL] THEN
  CONV_TAC NUM_REDUCE_CONV THEN ASM_REWRITE_TAC[] THEN
  MP_TAC(ISPEC `h:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
  DISCH_TAC THEN
  SUBGOAL_THEN `val(h:byte) DIV 16 MOD 16 = val h DIV 16` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `val(h:byte) MOD 16 MOD 16 = val h MOD 16` SUBST1_TAC THENL
   [REWRITE_TAC[MOD_MOD_REFL]; ALL_TAC] THEN
  MP_TAC(SPECL [`val(h:byte)`; `16`] DIVISION) THEN ARITH_TAC);;

let BYTES_TO_NIBBLES_SURJ = prove
 (`!l:(4 word) list. EVEN(LENGTH l)
                     ==> ?bs:byte list. BYTES_TO_NIBBLES bs = l /\
                                        LENGTH bs = LENGTH l DIV 2`,
  GEN_TAC THEN WF_INDUCT_TAC `LENGTH(l:(4 word) list)` THEN
  DISCH_TAC THEN ASM_CASES_TAC `l:(4 word) list = []` THENL
   [EXISTS_TAC `[]:byte list` THEN ASM_REWRITE_TAC[BYTES_TO_NIBBLES; LENGTH] THEN
    CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  MP_TAC(ISPEC `l:(4 word) list` list_CASES) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `n0:4 word`
              (X_CHOOSE_THEN `t0:(4 word) list` SUBST_ALL_TAC)) THEN
  ASM_CASES_TAC `t0:(4 word) list = []` THENL
   [POP_ASSUM SUBST_ALL_TAC THEN
    UNDISCH_TAC `EVEN (LENGTH (CONS (n0:4 word) []))` THEN
    REWRITE_TAC[LENGTH; EVEN; ARITH_RULE `~(SUC 0 = 0)`]; ALL_TAC] THEN
  MP_TAC(ISPEC `t0:(4 word) list` list_CASES) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `n1:4 word`
              (X_CHOOSE_THEN `t:(4 word) list` SUBST_ALL_TAC)) THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `t:(4 word) list`) THEN
  REWRITE_TAC[LENGTH; ARITH_RULE `n < SUC(SUC n)`] THEN
  UNDISCH_TAC `EVEN (LENGTH (CONS (n0:4 word) (CONS n1 t)))` THEN
  REWRITE_TAC[LENGTH; EVEN] THEN DISCH_TAC THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `bs:byte list` STRIP_ASSUME_TAC) THEN
  EXISTS_TAC `CONS (word(val(n0:4 word) + 16 * val(n1:4 word)):byte) bs` THEN
  ASM_REWRITE_TAC[BYTES_TO_NIBBLES; LENGTH; APPEND; CONS_11] THEN
  MP_TAC(ISPEC `n0:4 word` VAL_BOUND) THEN
  MP_TAC(ISPEC `n1:4 word` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_4] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT DISCH_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN
    `(val(n0:4 word) + 16 * val(n1:4 word)) MOD 256 = val n0 + 16 * val n1`
    SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `val(n0:4 word) + 16 * val(n1:4 word) = val n1 * 16 + val n0` SUBST1_TAC THENL
   [ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[MOD_MULT_ADD; DIV_MULT_ADD; ARITH_EQ; MOD_LT; DIV_LT;
               ADD_CLAUSES] THEN
  REWRITE_TAC[WORD_VAL] THEN
  UNDISCH_TAC `EVEN (LENGTH (t:(4 word) list))` THEN
  REWRITE_TAC[EVEN_EXISTS] THEN
  DISCH_THEN(X_CHOOSE_THEN `m:num` SUBST1_TAC) THEN
  REWRITE_TAC[ARITH_RULE `2 * m = m * 2`; DIV_MULT; ARITH_EQ] THEN ARITH_TAC);;

(* ========================================================================= *)
(* Lemmas shared by the AVX2 rejection-sampling proofs (rej_uniform_eta2 and  *)
(* rej_uniform_eta4): popcount / accepted-count bounds, byte/nibble value     *)
(* lemmas, word-slice and sub-list helpers, and modular-split arithmetic.     *)
(* ========================================================================= *)

let VAL_WORD_ZX_64_32 = prove
 (`!a. a < 2 EXP 32 ==> val(word_zx(word a:int64):int32) = a`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_32; VAL_WORD; DIMINDEX_64] THEN
  SUBGOAL_THEN `a MOD 2 EXP 64 = a` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  MATCH_MP_TAC MOD_LT THEN ASM_REWRITE_TAC[]);;

(* Loop-guard fall-through bridge: after `cmp $k, %e_x` with the 64-bit      *)
(* register holding `word a` (a <= k <= 2^32-1), the `ja` (jump-if-above,    *)
(* unsigned >) is NOT taken. The x86 model emits the taken-condition as      *)
(* `~(~EQ \/ ZF)` where EQ is the CF-via-int-equality and ZF the zero test;  *)
(* this lemma proves `~EQ \/ ZF` holds so the taken-condition is false and   *)
(* execution falls through. Stated with `word a:int64` (the register width)  *)
(* and `&`:int (int_of_num) to match the model's flag terms EXACTLY, so      *)
(* X86_STEPS_TAC resolves the conditional RIP automatically when this lemma  *)
(* (instantiated for the right a,k) is in the assumptions. Used at all five  *)
(* cmp/ja sites in the SIMD loop body (the two loop-head guards on ctr<=248  *)
(* and pos<=256, plus the three mid-iteration early-exit checks).            *)

let NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES = prove
 (`!l:byte list.
     NIBBLES_OF_BYTES l = MAP (\x:4 word. word_zx x:int16) (BYTES_TO_NIBBLES l)`,
  LIST_INDUCT_TAC THENL
   [REWRITE_TAC[NIBBLES_OF_BYTES; BYTES_TO_NIBBLES; MAP]; ALL_TAC] THEN
  REWRITE_TAC[NIBBLES_OF_BYTES; BYTES_TO_NIBBLES; MAP; APPEND] THEN
  ASM_REWRITE_TAC[NIBBLE_PAIR; MAP; APPEND] THEN
  REPEAT(AP_THM_TAC ORELSE AP_TERM_TAC) THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_4; DIMINDEX_16; word_zx] THEN
  CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MOD_MOD_REFL] THEN
  REPEAT AP_TERM_TAC THEN AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
  MATCH_MP_TAC(GSYM MOD_LT) THEN MP_TAC(ISPEC `h:byte` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

(* Bridge: byte-shape composition equals the public nibble-list spec         *)
(* applied to BYTES_TO_NIBBLES. Used only at the subroutine-spec boundary.   *)

let WORD_POPCOUNT_LOW8_LE_8 = prove
 (`!w:int32. word_popcount(word_zx (word_subword w (0,8):byte):int32) <= 8`,
  GEN_TAC THEN
  MATCH_MP_TAC WORD_POPCOUNT_BOUND_SIZE THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_32] THEN
  W(MP_TAC o PART_MATCH lhand VAL_BOUND o lhand o lhand o snd) THEN
  REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

(* val of (word(popcnt low 8 bits)) is bounded by 8. Used as the popcnt      *)
(* bound for sub-iter writeback vmovdqu nonoverlap proofs.                   *)

let VAL_WORD_POPCOUNT_LOW8_LE_8 = prove
 (`!w:int32. val(word(word_popcount(word_zx (word_subword w (0,8):byte):int32)):int32) <= 8`,
  GEN_TAC THEN
  MP_TAC(SPEC `w:int32` WORD_POPCOUNT_LOW8_LE_8) THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN
  STRIP_TAC THEN
  SUBGOAL_THEN
   `word_popcount(word_zx (word_subword (w:int32) (0,8):byte):int32) MOD 2 EXP 32 =
    word_popcount(word_zx (word_subword (w:int32) (0,8):byte):int32)`
   SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN
    UNDISCH_TAC `word_popcount(word_zx (word_subword (w:int32) (0,8):byte):int32) <= 8` THEN
    REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC;
    ASM_REWRITE_TAC[]]);;

(* RAX-after-popcnt-add bridge: the asm `add eax, r9d` after popcnt produces *)
(* RAX = word_zx(word_add(word_zx(word outlen)) (word_zx pcnt)). When        *)
(* outlen <= 248 (loop-head precondition) and val pcnt <= 8 (popcnt bound),  *)
(* this equals word(outlen + val pcnt) and the sum is bounded by 256,        *)
(* enabling the subsequent vmovdqu's nonoverlap proof.                       *)

let RAX_BOUND_AFTER_POPCNT_ADD = prove
 (`!outlen:num pcnt:int32.
     outlen <= 248 /\ val pcnt <= 8
     ==> (word_zx (word_add (word_zx (word outlen:int32):int32) (word_zx pcnt:int32):int32):int64) =
         word(outlen + val pcnt) /\
         outlen + val pcnt <= 256`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  CONJ_TAC THENL
   [REWRITE_TAC[GSYM VAL_EQ; VAL_WORD] THEN
    REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_64; DIMINDEX_32; VAL_WORD_ADD; VAL_WORD] THEN
    SUBGOAL_THEN `outlen MOD 2 EXP 32 = outlen /\
                  val(pcnt:int32) MOD 2 EXP 32 = val pcnt`
     (fun th -> REWRITE_TAC[th]) THENL
     [CONJ_TAC THEN MATCH_MP_TAC MOD_LT THENL
       [UNDISCH_TAC `outlen <= 248` THEN
        REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC;
        MP_TAC(ISPEC `pcnt:int32` VAL_BOUND) THEN
        REWRITE_TAC[DIMINDEX_32]];
      ALL_TAC] THEN
    SUBGOAL_THEN `(outlen + val(pcnt:int32)) MOD 2 EXP 32 = outlen + val pcnt`
      SUBST1_TAC THENL
     [MATCH_MP_TAC MOD_LT THEN
      UNDISCH_TAC `outlen <= 248` THEN UNDISCH_TAC `val(pcnt:int32) <= 8` THEN
      REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `(outlen + val(pcnt:int32)) MOD 2 EXP 64 = outlen + val pcnt`
      SUBST1_TAC THENL
     [MATCH_MP_TAC MOD_LT THEN
      UNDISCH_TAC `outlen <= 248` THEN UNDISCH_TAC `val(pcnt:int32) <= 8` THEN
      REWRITE_TAC[ARITH_RULE `2 EXP 64 = 18446744073709551616`] THEN ARITH_TAC;
      REFL_TAC];
    UNDISCH_TAC `outlen <= 248` THEN UNDISCH_TAC `val(pcnt:int32) <= 8` THEN
    ARITH_TAC]);;

(* Generic int32 word_zx(word_add(word_zx(word a), word_zx(word b))) = word(a+b) *)
(* when a+b fits in int32. Used at every sub-iter boundary for both the      *)
(* outlen-tracking RAX accumulator and the RCX position counter.             *)

let RAX_BOUND_GENERIC = prove
 (`!a:num b:num.
     a + b < 2 EXP 32
     ==> (word_zx (word_add (word_zx (word a:int32):int32) (word_zx (word b:int32):int32):int32):int64) =
         word(a + b)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_64; DIMINDEX_32; VAL_WORD_ADD; VAL_WORD] THEN
  SUBGOAL_THEN `a MOD 2 EXP 32 = a /\ b MOD 2 EXP 32 = b`
   (fun th -> REWRITE_TAC[th]) THENL
   [CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN
    UNDISCH_TAC `a + b < 2 EXP 32` THEN ARITH_TAC;
    ALL_TAC] THEN
  ASM_SIMP_TAC[MOD_LT] THEN
  MATCH_MP_TAC MOD_LT THEN
  UNDISCH_TAC `a + b < 2 EXP 32` THEN
  REWRITE_TAC[ARITH_RULE `2 EXP 64 = 18446744073709551616`;
              ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC);;

(* Direct bridge for the actual asm RAX form after `add eax, r9d` where      *)
(* r9 = popcntl r10d (and r10d came from movzx r10d, r8b — bounded by        *)
(* 256). The simulator produces RAX with two nested word_zx wrappers         *)
(* (one from popcntl int32 result wrapping into int64). This bridge          *)
(* takes the bound `val x < 2 EXP 8` directly (from movzx semantics)         *)
(* and produces the canonical `word(outlen + n) /\ outlen + n <= 256`.       *)

let RAX_BOUND_AFTER_POPCNT_ADD_DIRECT = prove
 (`!outlen:num x:int64.
     outlen <= 248 /\ val(x:int64) < 2 EXP 8
     ==> ?n. n <= 8 /\
             word_zx (word_add (word_zx (word outlen:int32):int32)
                               (word_zx (word_zx (word(word_popcount(word_zx x:int32)):int32):int32):int32):int32):int64 =
             word(outlen + n):int64 /\
             outlen + n <= 256`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `word_popcount(word_zx (x:int64):int32) <= 8`
    ASSUME_TAC THENL
   [MATCH_MP_TAC WORD_POPCOUNT_BOUND_SIZE THEN
    REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_32; DIMINDEX_64] THEN
    SUBGOAL_THEN `val(x:int64) MOD 2 EXP 32 = val x` SUBST1_TAC THENL
     [MATCH_MP_TAC MOD_LT THEN
      UNDISCH_TAC `val(x:int64) < 2 EXP 8` THEN ARITH_TAC;
      ALL_TAC] THEN
    UNDISCH_TAC `val(x:int64) < 2 EXP 8` THEN ARITH_TAC;
    ALL_TAC] THEN
  EXISTS_TAC `word_popcount(word_zx (x:int64):int32)` THEN
  CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_64; DIMINDEX_32; VAL_WORD_ADD; VAL_WORD] THEN
  SUBGOAL_THEN
   `outlen MOD 2 EXP 32 = outlen /\
    word_popcount(word_zx (x:int64):int32) MOD 2 EXP 32 =
    word_popcount(word_zx (x:int64):int32)`
   (fun th -> REWRITE_TAC[th]) THENL
   [CONJ_TAC THEN MATCH_MP_TAC MOD_LT THENL
    [UNDISCH_TAC `outlen <= 248` THEN
     REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC;
     UNDISCH_TAC `word_popcount(word_zx (x:int64):int32) <= 8` THEN
     REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC];
    ALL_TAC] THEN
  SUBGOAL_THEN
   `(outlen + word_popcount(word_zx (x:int64):int32)) MOD 2 EXP 32 =
    outlen + word_popcount(word_zx (x:int64):int32)`
   SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN
    UNDISCH_TAC `outlen <= 248` THEN
    UNDISCH_TAC `word_popcount(word_zx (x:int64):int32) <= 8` THEN
    REWRITE_TAC[ARITH_RULE `2 EXP 32 = 4294967296`] THEN ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN
   `(outlen + word_popcount(word_zx (x:int64):int32)) MOD 2 EXP 64 =
    outlen + word_popcount(word_zx (x:int64):int32)`
   SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN
    UNDISCH_TAC `outlen <= 248` THEN
    UNDISCH_TAC `word_popcount(word_zx (x:int64):int32) <= 8` THEN
    REWRITE_TAC[ARITH_RULE `2 EXP 64 = 18446744073709551616`] THEN ARITH_TAC;
    ALL_TAC] THEN
  ASM_ARITH_TAC);;

(* Chained sub-iter step: combines RAX_BOUND_AFTER_POPCNT_ADD with the       *)
(* popcnt bound to give an existential `?n. n <= 8 /\ RAX_form = word        *)
(* (outlen+n) /\ outlen+n <= 232` directly from the asm's mask-based         *)
(* popcnt expression. This is the per-sub-iter inductive bridge: at          *)
(* each sub-iter k, given outlen <= 248 (loop-head invariant), the post-     *)
(* popcnt-add RAX has the canonical form word(outlen + n) where n is the     *)
(* per-sub-iter popcount (at most 8 nibbles accepted out of 4 bytes).        *)

let RAX_AFTER_SUB_ITER = prove
 (`!outlen:num mask:int32.
     outlen <= 248
     ==> ?n. n <= 8 /\
             (word_zx (word_add (word_zx (word outlen:int32):int32)
                                (word_zx (word(word_popcount(word_zx (word_subword mask (0,8):byte):int32)):int32):int32)
                                :int32):int64) =
             word(outlen + n) /\
             outlen + n <= 256`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  EXISTS_TAC `val(word(word_popcount(word_zx (word_subword (mask:int32) (0,8):byte):int32)):int32)` THEN
  CONJ_TAC THENL [REWRITE_TAC[VAL_WORD_POPCOUNT_LOW8_LE_8]; ALL_TAC] THEN
  MATCH_MP_TAC RAX_BOUND_AFTER_POPCNT_ADD THEN
  ASM_REWRITE_TAC[VAL_WORD_POPCOUNT_LOW8_LE_8]);;

(* word_popcount of a byte expanded as the sum of 8 bit-bitvals.             *)
(* This is the bridge from the popcnt instruction to a per-bit count.        *)

let WORD_POPCOUNT_BYTE = prove
 (`!b:byte. word_popcount b =
            bitval(bit 0 b) + bitval(bit 1 b) + bitval(bit 2 b) +
            bitval(bit 3 b) + bitval(bit 4 b) + bitval(bit 5 b) +
            bitval(bit 6 b) + bitval(bit 7 b)`,
  GEN_TAC THEN
  REWRITE_TAC[WORD_POPCOUNT_NSUM; DIMINDEX_8] THEN
  SUBGOAL_THEN `{i | i < 8} = {0,1,2,3,4,5,6,7}` SUBST1_TAC THENL
   [REWRITE_TAC[EXTENSION; IN_ELIM_THM; IN_INSERT; NOT_IN_EMPTY] THEN
    ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN `{0,1,2,3,4,5,6,7} = 0..7` SUBST1_TAC THENL
   [REWRITE_TAC[EXTENSION; IN_INSERT; IN_NUMSEG; NOT_IN_EMPTY] THEN
    ARITH_TAC;
    ALL_TAC] THEN
  CONV_TAC(LAND_CONV EXPAND_NSUM_CONV) THEN ARITH_TAC);;

(* For a byte a with val a < 16 (i.e. nibble-sized), bit 7 of (a - 9)        *)
(* (computed as a byte subtraction) is set iff a < 9.                        *)
(* The bridge from the VPSUBB byte subtraction to a bit-test.                *)

let RB64 = prove
 (`!(a:int64) (s:x86state). read(memory:>bytes64 a) s = word(read(memory:>bytes(a,8)) s)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[bytes64; READ_COMPONENT_COMPOSE; asword; through; read]);;

(* Read an n-byte window at offset k of a byte region known to hold num_of_wordlist L:
   the window holds num_of_wordlist(SUB_LIST(k,n) L).  (NB: HOL parses `k + LENGTH L - k`
   as `k + (LENGTH L - k)` since `-` binds tighter than `+`; the SUB_ADD-style reductions
   here go through ASM_ARITH_TAC with the k+n<=LENGTH L hypothesis.) *)

let BYTES256_PREFIX_WORDLIST = prove
 (`!(A:int64) (V:int256) k (s:x86state).
      read(memory:>bytes256 A) s = V /\ k <= 8
      ==> read(memory:>bytes(A, 4*k)) s = num_of_wordlist(wordlist_of_num k (val V):int32 list)`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[NUM_OF_WORDLIST_OF_NUM; DIMINDEX_32; READ_COMPONENT_COMPOSE] THEN
  SUBGOAL_THEN `read (bytes(A,32)) (read memory (s:x86state)) = val(V:int256)` ASSUME_TAC THENL
   [UNDISCH_TAC `read(memory:>bytes256 A) s = V` THEN
    REWRITE_TAC[bytes256; READ_COMPONENT_COMPOSE; asword; through; read] THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN REWRITE_TAC[VAL_WORD; DIMINDEX_256] THEN
    CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
    REWRITE_TAC[GSYM DIMINDEX_256] THEN
    MP_TAC(ISPECL[`A:int64`;`32`;`read memory (s:x86state)`] READ_BYTES_BOUND) THEN
    REWRITE_TAC[DIMINDEX_256] THEN ARITH_TAC;
    ALL_TAC] THEN
  MP_TAC(ISPECL [`A:int64`; `32`; `4*k`; `read memory (s:x86state)`] READ_BYTES_MOD) THEN
  ASM_REWRITE_TAC[ARITH_RULE `8 * 4 * k = 32 * k`] THEN
  SUBGOAL_THEN `MIN 32 (4*k) = 4*k` SUBST1_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC);;

(* The j-th lane (j<k<=8) of wordlist_of_num k (val V) is word_subword V (32j,32). *)

let EL_WORDLIST_OF_NUM_VAL = prove
 (`!(V:int256) k j. j < k
     ==> EL j (wordlist_of_num k (val V):int32 list) = word_subword V (32*j,32)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`wordlist_of_num k (val(V:int256)):int32 list`; `j:num`] EL_NUM_OF_WORDLIST) THEN
  REWRITE_TAC[LENGTH_WORDLIST_OF_NUM; NUM_OF_WORDLIST_OF_NUM; DIMINDEX_32] THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[word_subword; DIMINDEX_32; DIMINDEX_256] THEN CONV_TAC NUM_REDUCE_CONV THEN
  MATCH_MP_TAC(MESON[] `(word x:int32) = word y ==> word x:int32 = word y`) THEN
  ONCE_REWRITE_TAC[GSYM WORD_MOD_SIZE] THEN REWRITE_TAC[DIMINDEX_32] THEN AP_TERM_TAC THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`; MOD_MOD_REFL] THEN
  REWRITE_TAC[DIV_MOD; GSYM EXP_ADD; MOD_MOD_EXP_MIN] THEN
  SUBGOAL_THEN `MIN (32 * k) (32 * j + 32) = 32 * j + 32` SUBST1_TAC THENL
   [ASM_ARITH_TAC; REWRITE_TAC[]]);;

(* If V's first k lanes match L's elements (and LENGTH L = k <= 8), the low-k-lane digit
   list of V is exactly L. *)

let WORDLIST_OF_NUM_VAL_EQ = prove
 (`!(V:int256) (L:int32 list) k.
      LENGTH L = k /\ (!j. j < k ==> word_subword V (32*j,32) = EL j L)
      ==> wordlist_of_num k (val V) = L`,
  REPEAT STRIP_TAC THEN ONCE_REWRITE_TAC[LIST_EQ] THEN
  REWRITE_TAC[LENGTH_WORDLIST_OF_NUM] THEN ASM_REWRITE_TAC[] THEN
  X_GEN_TAC `j:num` THEN STRIP_TAC THEN
  ASM_SIMP_TAC[EL_WORDLIST_OF_NUM_VAL] THEN ASM_MESON_TAC[]);;

(* Full-width subword identity (used to close the per-lane vpmovsxbd extraction:
   word_subword (word_sx b:int32) (0,32) = word_sx b, with the word_sx(..) taken as W). *)

let SUB_LIST_0_MAP = prove
 (`!(f:A->B) n l. SUB_LIST(0,n) (MAP f l) = MAP f (SUB_LIST(0,n) l)`,
  GEN_TAC THEN INDUCT_TAC THEN REWRITE_TAC[SUB_LIST_CLAUSES; MAP] THEN
  LIST_INDUCT_TAC THEN ASM_REWRITE_TAC[SUB_LIST_CLAUSES; MAP]);;

(* Nesting/composition of SUB_LIST: a window of width n starting at a, taken from
   a window of width m starting at b, equals the width-n window starting at b+a in
   the original list (provided the inner window covers it and lies inside the list).
   Used to slice the 4-byte sub-iter block SUB_LIST(16i,4) out of the 16-byte chunk
   SUB_LIST(16i,16) when threading per-block facts in the clean loop body. *)

let MAP_FILTER_WORD_NIB = prove
 (`!(f:int16->int32) P (L:num list).
     (!v. MEM v L ==> v < 16)
     ==> MAP f (FILTER P (MAP (word:num->int16) L)) =
         MAP (\v. f(word v)) (FILTER (\v. P(word v)) L)`,
  GEN_TAC THEN GEN_TAC THEN LIST_INDUCT_TAC THEN
  REWRITE_TAC[MAP; FILTER] THEN
  REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o check (is_imp o concl)) THEN
  ANTS_TAC THENL [ASM_MESON_TAC[MEM]; ALL_TAC] THEN
  DISCH_THEN(fun th -> ASM_CASES_TAC `(P:int16->bool)(word h)` THEN
    ASM_REWRITE_TAC[MAP; th]));;

(* For a list of nibble values (< 16), the int16-word accept predicate         *)
(* val(word v) < 9 agrees with the numeric v < 9, so the two FILTERs coincide. *)

let WZZ_LOW = prove
 (`!(p:int256) j. j < 8
    ==> word_subword (word_zx (word_zx p:int128):int64) (8*j,8):byte = word_subword p (8*j,8)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`word_zx (p:int256):int128`;`8*j`;`8`]
    (INST_TYPE[`:64`,`:N`;`:128`,`:M`;`:8`,`:P`] WORD_SUBWORD_ZX)) THEN
  MP_TAC(ISPECL [`p:int256`;`8*j`;`8`]
    (INST_TYPE[`:128`,`:N`;`:256`,`:M`;`:8`,`:P`] WORD_SUBWORD_ZX)) THEN
  REWRITE_TAC[DIMINDEX_8;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
  SUBGOAL_THEN `MIN (8*j+8) 128 <= 256 /\ MIN (8*j+8) 256 <= 128 /\ MIN(8*j+8) 128 <= 64` MP_TAC THENL
   [POP_ASSUM MP_TAC THEN ARITH_TAC;
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th1 -> DISCH_THEN(fun th2 -> REWRITE_TAC[th2;th1]))]);;

(* ZZCOLLAPSE: strip word_zx 128<-256<-128 on a low-lane byte subword (j<8); used in    *)
(* the sub-iter store gather subgoal (the vpmovsxbd source g = word_zx(word_zx(...))).  *)

let WORD_BYTE_MOD = prove
 (`!n. word(n MOD 256):byte = word n`,
  GEN_TAC THEN SUBGOAL_THEN `256 = 2 EXP dimindex(:8)` SUBST1_TAC THENL
   [REWRITE_TAC[DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV; REWRITE_TAC[WORD_MOD_SIZE]]);;

let WORD_ADD_256_BYTE = prove
 (`!a x. word(a + 256 * x):byte = word a`,
  REPEAT GEN_TAC THEN ONCE_REWRITE_TAC[GSYM WORD_BYTE_MOD] THEN
  AP_TERM_TAC THEN REWRITE_TAC[MOD_MULT_ADD; ARITH_RULE `256 * x = x * 256`] THEN
  REWRITE_TAC[MOD_MULT_ADD]);;

let WORD_SUBWORD_USHR_LOW8 = prove
 (`(!w:int32. word_subword (word_ushr w 8:int32) (0,8):byte =
              word_subword w (8,8)) /\
   (!w:int32. word_subword (word_ushr w 16:int32) (0,8):byte =
              word_subword w (16,8)) /\
   (!w:int32. word_subword (word_ushr w 24:int32) (0,8):byte =
              word_subword w (24,8))`,
  REPEAT CONJ_TAC THEN GEN_TAC THEN CONV_TAC WORD_BLAST);;

(* AND with 0xF (mask 15) is the byte-level "low nibble" extraction.         *)
(* Used for VPAND ymm0, ymm0, mask where mask = broadcast(0x0F0F0F0F).       *)

let VAL_WORD_AND_15 = prove
 (`!b:byte. val(word_and b (word 15:byte)) = val b MOD 16`,
  GEN_TAC THEN
  SUBGOAL_THEN `(word 15:byte) = word(2 EXP 4 - 1)` SUBST1_TAC THENL
   [REWRITE_TAC[ARITH]; ALL_TAC] THEN
  REWRITE_TAC[VAL_WORD_AND_MASK_WORD] THEN ARITH_TAC);;

let VAL_WORD_AND_15_LT_16 = prove
 (`!b:byte. val(word_and b (word 15:byte)) < 16`,
  GEN_TAC THEN REWRITE_TAC[VAL_WORD_AND_15] THEN ARITH_TAC);;

(* val of a nibble word stays as the nibble value (since nibble < 16 < 256). *)
(* Used after the byte form `word(val b MOD 16):byte` appears in the proof.  *)

let VAL_WORD_NIBBLE = prove
 (`!b:byte. val(word(val b MOD 16):byte) = val b MOD 16 /\
            val(word(val b DIV 16):byte) = val b DIV 16`,
  GEN_TAC THEN MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_8; VAL_WORD; DIMINDEX_8] THEN
  STRIP_TAC THEN CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC);;

(* word_zx (word n :byte) :int16 = word n when n < 256 (no truncation).      *)

let WORD_ZX_BYTE_TO_INT16 = prove
 (`!n. n < 256 ==> word_zx (word n:byte):int16 = word n`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_ZX_GEN; VAL_WORD;
              DIMINDEX_8; DIMINDEX_16] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `n < 256 ==> n < 65536`]);;

(* LENGTH FILTER (val<9) commutes with MAP word_zx (byte->int16).            *)

let ENSURES_STRENGTHEN_POST_X86 = prove
 (`!P (Q:x86state->bool) Q' R.
     ensures x86 P Q' R /\ (!s. Q' s ==> Q s) ==> ensures x86 P Q R`,
  REPEAT GEN_TAC THEN DISCH_THEN(CONJUNCTS_THEN2 MP_TAC ASSUME_TAC) THEN
  REWRITE_TAC[ensures] THEN MATCH_MP_TAC MONO_FORALL THEN
  X_GEN_TAC `s0:x86state` THEN MATCH_MP_TAC MONO_IMP THEN REWRITE_TAC[] THEN
  MP_TAC(BETA_RULE(ISPECL [`x86`;
    `\s':x86state. (Q':x86state->bool) s' /\
                   (R:x86state->x86state->bool) (s0:x86state) s'`;
    `\s':x86state. (Q:x86state->bool) s' /\
                   (R:x86state->x86state->bool) (s0:x86state) s'`]
    EVENTUALLY_MONO)) THEN
  ANTS_TAC THENL [ASM_MESON_TAC[]; MESON_TAC[]]);;

(* SUB_LIST length cap: outlist length <= 256, used for SUBROUTINE_CORRECT   *)
(* `outlen <= 256` postcondition.                                            *)

let ADD256_MOD = prove
 (`!a b. a < 256 ==> (a + 256 * b) MOD 256 = a`,
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[MOD_MULT_ADD; MOD_LT]);;

let LOW8_LT = prove
 (`!p:num->bool. bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) < 256`,
  GEN_TAC THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [0;1;2;3;4;5;6;7] THEN ARITH_TAC);;

let MOD_RED = prove
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
     256*bitval(p 16) + 512*bitval(p 17) + 1024*bitval(p 18) + 2048*bitval(p 19) +
     4096*bitval(p 20) + 8192*bitval(p 21) + 16384*bitval(p 22) + 32768*bitval(p 23) +
     65536*bitval(p 24) + 131072*bitval(p 25) + 262144*bitval(p 26) + 524288*bitval(p 27) +
     1048576*bitval(p 28) + 2097152*bitval(p 29) + 4194304*bitval(p 30) + 8388608*bitval(p 31))`
   SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  MATCH_MP_TAC ADD256_MOD THEN REWRITE_TAC[LOW8_LT]);;

let RAX_NEST_REDUCE = prove
 (`!a b. a + b < 2 EXP 32
     ==> word_zx (word_add (word_zx (word a:int64):int32)
                           (word_zx (word_zx (word b:int32):int64):int32):int32):int64 =
         word(a + b)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `a < 2 EXP 32 /\ b < 2 EXP 32 /\ a + b < 2 EXP 64` STRIP_ASSUME_TAC THENL
   [REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[GSYM VAL_EQ] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_ADD; VAL_WORD; DIMINDEX_32; DIMINDEX_64] THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `x < 2 EXP 32 ==> x < 2 EXP 64`] THEN
  ASM_SIMP_TAC[MOD_LT]);;

let JA_NOT_TAKEN_LE = prove
 (`!a k:num. a <= k /\ k < 2 EXP 32
     ==> ~(&(val(word_zx(word a:int64):int32)):int - &k =
           &(val(word_sub (word_zx(word a:int64):int32) (word k:int32)))) \/
         val(word_sub (word_zx(word a:int64):int32) (word k:int32)) = 0`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `val(word_zx(word a:int64):int32) = a` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `val(word k:int32) = k` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_32] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  ASM_CASES_TAC `a = k:num` THEN ASM_REWRITE_TAC[] THENL
   [DISJ2_TAC THEN
    SUBGOAL_THEN `word_zx(word k:int64):int32 = word k` SUBST1_TAC THENL
     [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_SIMP_TAC[VAL_WORD_ZX_64_32] THEN
      CONV_TAC SYM_CONV THEN MATCH_MP_TAC VAL_WORD_EQ THEN
      REWRITE_TAC[DIMINDEX_32] THEN ASM_REWRITE_TAC[];
      REWRITE_TAC[WORD_SUB_REFL; VAL_WORD_0]];
    DISJ1_TAC THEN
    SUBGOAL_THEN `a < k` ASSUME_TAC THENL
     [REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `val(word_sub (word_zx(word a:int64):int32) (word k:int32)) =
                  a + 2 EXP 32 - k` SUBST1_TAC THENL
     [REWRITE_TAC[VAL_WORD_SUB_CASES; DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN
      COND_CASES_TAC THENL
       [REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC; REFL_TAC];
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `&a:int < &k` MP_TAC THENL
     [REWRITE_TAC[INT_OF_NUM_LT] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SPEC_TAC(`a + 2 EXP 32 - k`,`m:num`) THEN INT_ARITH_TAC]);;

(* word_add evaluation when both summands are bounded by 248 (and thus the   *)
(* sum is also bounded). Used to compute exact RAX value after `add eax, r9d`*)
(* in sub-iter 1 of the body proof.                                          *)

let NUM_OF_WORDLIST_SINGLETON_INT32 = prove
 (`!(x:int32). num_of_wordlist [x] = val x`,
  REWRITE_TAC[num_of_wordlist] THEN ARITH_TAC);;

let SUB_LIST_256_LE = prove
 (`!(l:int32 list). LENGTH l <= 256 ==> SUB_LIST(0, 256) l = l`,
  REPEAT STRIP_TAC THEN ABBREV_TAC `m = LENGTH (l:int32 list)` THEN
  MP_TAC(ISPECL [`l:int32 list`; `m:num`; `256 - m`; `0`] SUB_LIST_SPLIT) THEN
  ASM_REWRITE_TAC[ARITH_RULE `0 + a = a`] THEN
  ASM_SIMP_TAC[ARITH_RULE `m <= 256 ==> m + (256 - m) = 256`] THEN
  DISCH_THEN SUBST1_TAC THEN
  ASM_REWRITE_TAC[SUB_LIST_LENGTH; SUB_LIST_TRIVIAL; LE_REFL; APPEND_NIL] THEN
  UNDISCH_TAC `LENGTH (l:int32 list) = m` THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN REWRITE_TAC[SUB_LIST_LENGTH] THEN
  MP_TAC(ISPECL [`l:int32 list`; `LENGTH (l:int32 list)`;
                 `256 - LENGTH (l:int32 list)`] SUB_LIST_TRIVIAL) THEN
  REWRITE_TAC[LE_REFL] THEN DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[APPEND_NIL]);;

(* When the input has its full known length, SUB_LIST(0, that length) is a   *)
(* no-op: applies to LENGTH inlist = 272.                                    *)

let PURGE_STALE_STATES_TAC names =
  let rec refs_stale tm = match tm with
    | Comb(Comb(Const("read",_),_),Var(nm,_)) when List.mem nm names -> true
    | Comb(a,b) -> refs_stale a || refs_stale b | Abs(_,b) -> refs_stale b | _ -> false in
  REPEAT(FIRST_X_ASSUM(fun th -> if refs_stale (concl th) then ALL_TAC else failwith "keep"));;

let DROP_WORDJOIN_TAC : tactic = fun (asl,w) ->
  (REPEAT(FIRST_X_ASSUM(fun th ->
     if can (find_term (fun u -> match u with Const("word_join",_) -> true | _ -> false)) (concl th)
     then ALL_TAC else failwith "keep"))) (asl,w);;

let wzx_id = prove(`!x:int128. word_zx x:int128 = x`, REWRITE_TAC[WORD_ZX_TRIVIAL]);;

let VAL_WORD_BYTE_LT256 = prove
 (`!n. n < 256 ==> val(word n:byte) = n`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN MATCH_MP_TAC MOD_LT THEN ASM_REWRITE_TAC[]);;

let BYTE_DIV16_LT = prove
 (`!b:byte. val b DIV 16 < 256`,
  GEN_TAC THEN MP_TAC(REWRITE_RULE[DIMINDEX_8](ISPEC `b:byte` VAL_BOUND)) THEN ARITH_TAC);;

let BYTE_MOD16_LT = prove
 (`!b:byte. val b MOD 16 < 256`,
  GEN_TAC THEN MP_TAC(SPECL[`val(b:byte)`;`16`] MOD_LT_EQ) THEN ARITH_TAC);;

let MM64_256 = prove
 (`!a. a MOD 18446744073709551616 MOD 256 = a MOD 256`,
  GEN_TAC THEN
  GEN_REWRITE_TAC (LAND_CONV o LAND_CONV o RAND_CONV)
    [ARITH_RULE `18446744073709551616 = 256 * 72057594037927936`] THEN
  REWRITE_TAC[MOD_MOD]);;

(* a MOD 2^32 MOD 2^64 = a MOD 2^32                                          *)

let MM32_64 = prove
 (`!a. a MOD 4294967296 MOD 18446744073709551616 = a MOD 4294967296`,
  GEN_TAC THEN MATCH_MP_TAC MOD_LT THEN
  MP_TAC(SPECL[`a:num`;`4294967296`] MOD_LT_EQ) THEN
  CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

(* (x DIV 2^8) MOD 2^8 = (x MOD 2^16) DIV 2^8                                *)

let divmod_swap = prove
 (`!x. (x DIV 2 EXP 8) MOD 2 EXP 8 = (x MOD 2 EXP 16) DIV 2 EXP 8`,
  GEN_TAC THEN REWRITE_TAC[DIV_MOD; GSYM EXP_ADD] THEN CONV_TAC NUM_REDUCE_CONV);;

(* (S MOD 2^32 DIV 256) MOD 256 = (S DIV 256) MOD 256                        *)

let MM32_DIV256 = prove
 (`!S. (S MOD 4294967296 DIV 256) MOD 256 = (S DIV 256) MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`; ARITH_RULE `256 = 2 EXP 8`] THEN
  REWRITE_TAC[divmod_swap] THEN
  REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

(* mask8b = word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64,
   the R8-shifted-by-8 value at the start of sub-iter 2.  Its low byte = byte 1 of S. *)

let LOW16_LT = prove
 (`!p:num->bool. bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) < 65536`,
  GEN_TAC THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15] THEN ARITH_TAC);;

let MASK_USHR8_STEP = prove
 (`!m:int64. val(word_zx(word_ushr(word_zx m:int32) 8):int64) MOD 256 = (val m DIV 256) MOD 256`,
  GEN_TAC THEN REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_USHR; DIMINDEX_32; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN REWRITE_TAC[MM64_256; MM32_DIV256]);;

let DIVLT = prove(`!a k e. a < e ==> a DIV k < e`,
  REPEAT STRIP_TAC THEN TRANS_TAC LET_TRANS `a:num` THEN ASM_REWRITE_TAC[DIV_LE]);;

let divmod_swap16 = prove(`!x. (x DIV 2 EXP 16) MOD 2 EXP 8 = (x MOD 2 EXP 24) DIV 2 EXP 16`,
  GEN_TAC THEN REWRITE_TAC[DIV_MOD; GSYM EXP_ADD] THEN CONV_TAC NUM_REDUCE_CONV);;

let divmod_swap24 = prove(`!x. (x DIV 2 EXP 24) MOD 2 EXP 8 = (x MOD 2 EXP 32) DIV 2 EXP 24`,
  GEN_TAC THEN REWRITE_TAC[DIV_MOD; GSYM EXP_ADD] THEN CONV_TAC NUM_REDUCE_CONV);;

(* full val of the byte-1 / byte-2 masks (mask8b = ushr8 once; mask8c = ushr8 twice) *)

let VAL_MASK8B = prove
 (`!S. val(word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64) = (S MOD 4294967296) DIV 256`,
  GEN_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_USHR; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`; ARITH_RULE `256 = 2 EXP 8`] THEN
  MP_TAC(SPECL[`S:num`;`2 EXP 32`] MOD_LT_EQ) THEN REWRITE_TAC[EXP_EQ_0; ARITH_EQ] THEN
  ABBREV_TAC `q = S MOD 2 EXP 32` THEN DISCH_TAC THEN
  SUBGOAL_THEN `q < 2 EXP 64` ASSUME_TAC THENL
   [TRANS_TAC LTE_TRANS `2 EXP 32` THEN ASM_REWRITE_TAC[LE_EXP] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `q MOD 2 EXP 64 MOD 2 EXP 32 = q` SUBST1_TAC THENL
   [ASM_SIMP_TAC[MOD_LT]; ALL_TAC] THEN
  MATCH_MP_TAC MOD_LT THEN TRANS_TAC LET_TRANS `q:num` THEN REWRITE_TAC[DIV_LE] THEN ASM_REWRITE_TAC[]);;

let VAL_MASK8C = prove
 (`!S. val(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64):int32) 8):int64) =
       (S MOD 4294967296) DIV 65536`,
  GEN_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_USHR; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`] THEN
  MP_TAC(SPECL[`S:num`;`2 EXP 32`] MOD_LT_EQ) THEN REWRITE_TAC[EXP_EQ_0; ARITH_EQ] THEN
  ABBREV_TAC `q = S MOD 2 EXP 32` THEN DISCH_TAC THEN
  SUBGOAL_THEN `q < 2 EXP 64 /\ q DIV 2 EXP 8 < 2 EXP 64 /\ q DIV 2 EXP 8 < 2 EXP 32 /\
                q DIV 2 EXP 8 DIV 2 EXP 8 < 2 EXP 64` STRIP_ASSUME_TAC THENL
   [SUBGOAL_THEN `q < 2 EXP 64 /\ q < 2 EXP 32` STRIP_ASSUME_TAC THENL
     [ASM_REWRITE_TAC[] THEN TRANS_TAC LTE_TRANS `2 EXP 32` THEN ASM_REWRITE_TAC[LE_EXP] THEN ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[DIVLT]; ALL_TAC] THEN
  ASM_SIMP_TAC[MOD_LT] THEN REWRITE_TAC[DIV_DIV] THEN AP_TERM_TAC THEN CONV_TAC NUM_REDUCE_CONV);;

(* mask byte for sub-iter 3 (double ushr) = byte 2 ; sub-iter 4 (triple ushr) = byte 3 *)

let SUMTERM_BYTE23 = `(bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
   16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
   256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
   4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
   65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
   1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
   16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
   268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31))`;;

let R_EQ = prove(`val (word_zx (word_zx (word (val (mask8:int64) MOD 256):byte):int32):int64):num = val (mask8:int64) MOD 256`,
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`] THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let RLT = prove(`val (mask8:int64) MOD 256 < 256`, REWRITE_TAC[MOD_LT_EQ] THEN ARITH_TAC);;

let SUBWORD_ZX_LOW = prove
 (`!(y:(M)word) lo wid. lo + wid <= dimindex(:P)
     ==> word_subword (word_zx y:(P)word) (lo,wid):(N)word = word_subword y (lo,wid)`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[WORD_EQ_BITS_ALT] THEN
  X_GEN_TAC `k:num` THEN STRIP_TAC THEN
  REWRITE_TAC[BIT_WORD_SUBWORD; BIT_WORD_ZX] THEN
  ASM_CASES_TAC `k < MIN wid (dimindex(:N))` THEN ASM_REWRITE_TAC[] THEN
  POP_ASSUM MP_TAC THEN REWRITE_TAC[ARITH_RULE `k < MIN a b <=> k < a /\ k < b`] THEN
  STRIP_TAC THEN
  SUBGOAL_THEN `lo + k < dimindex(:P)` (fun th -> REWRITE_TAC[th]) THEN ASM_ARITH_TAC);;

let ZX_128_256_128 = prove(`!(x:(128)word). word_zx(word_zx x:(256)word):(128)word = x`,
  GEN_TAC THEN REWRITE_TAC[WORD_EQ_BITS_ALT; DIMINDEX_128] THEN X_GEN_TAC `k:num` THEN STRIP_TAC THEN
  REWRITE_TAC[BIT_WORD_ZX; DIMINDEX_128; DIMINDEX_256] THEN
  SUBGOAL_THEN `k < 128 /\ k < 256` (fun th -> REWRITE_TAC[th]) THEN ASM_ARITH_TAC);;

let SUBWORD_USHR = prove
 (`!(x:(M)word) n lo wid. word_subword (word_ushr x n) (lo,wid):(N)word = word_subword x (lo+n,wid)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[WORD_EQ_BITS_ALT] THEN X_GEN_TAC `k:num` THEN STRIP_TAC THEN
  REWRITE_TAC[BIT_WORD_SUBWORD; BIT_WORD_USHR] THEN
  REWRITE_TAC[ARITH_RULE `(lo + k) + n = (lo + n) + k`]);;


(* --- prefix_g_full_tac ---                                                 *)

let DIVMOD256_SPLIT = prove
 (`!a b c. a < 256 /\ b < 256 ==> (a + 256 * b + 65536 * c) DIV 256 MOD 256 = b`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `(a + 256 * b + 65536 * c) DIV 256 = b + 256 * c` SUBST1_TAC THENL
   [MATCH_MP_TAC DIV_UNIQ THEN EXISTS_TAC `a:num` THEN ASM_ARITH_TAC;
    REWRITE_TAC[ARITH_RULE `b + 256 * c = c * 256 + b`; MOD_MULT_ADD] THEN
    ASM_SIMP_TAC[MOD_LT]]);;

let R_EQ_B = prove(`val (word_zx (word_zx (word (val (mask8b:int64) MOD 256):byte):int32):int64):num = val (mask8b:int64) MOD 256`,
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`] THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let RLT_B = prove(`val (mask8b:int64) MOD 256 < 256`, REWRITE_TAC[MOD_LT_EQ] THEN ARITH_TAC);;

let DIVMOD65536_SPLIT = prove
 (`!a b c. a < 65536 /\ b < 256 ==> (a + 65536 * b + 16777216 * c) DIV 65536 MOD 256 = b`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `(a + 65536 * b + 16777216 * c) DIV 65536 = b + 256 * c` SUBST1_TAC THENL
   [MATCH_MP_TAC DIV_UNIQ THEN EXISTS_TAC `a:num` THEN ASM_ARITH_TAC;
    REWRITE_TAC[ARITH_RULE `b + 256 * c = c * 256 + b`; MOD_MULT_ADD] THEN ASM_SIMP_TAC[MOD_LT]]);;

let R_EQ_C = prove(`val (word_zx (word_zx (word (val (mask8c:int64) MOD 256):byte):int32):int64):num = val (mask8c:int64) MOD 256`,
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`] THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let RLT_C = prove(`val (mask8c:int64) MOD 256 < 256`, REWRITE_TAC[MOD_LT_EQ] THEN ARITH_TAC);;

let DIVMOD16777216_SPLIT = prove
 (`!a b. a < 16777216 ==> (a + 16777216 * b) DIV 16777216 MOD 256 = b MOD 256`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `(a + 16777216 * b) DIV 16777216 = b` (fun th -> REWRITE_TAC[th]) THEN
  MATCH_MP_TAC DIV_UNIQ THEN EXISTS_TAC `a:num` THEN ASM_ARITH_TAC);;

let R_EQ_D = prove(`val (word_zx (word_zx (word (val (mask8d:int64) MOD 256):byte):int32):int64):num = val (mask8d:int64) MOD 256`,
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_8] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`] THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let RLT_D = prove(`val (mask8d:int64) MOD 256 < 256`, REWRITE_TAC[MOD_LT_EQ] THEN ARITH_TAC);;

let MM64_32 = prove(`!a. a MOD 2 EXP 64 MOD 2 EXP 32 = a MOD 2 EXP 32`,
  GEN_TAC THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let LENGTH_BUTLAST_GEN = prove
 (`!l:A list. ~(l = []) ==> LENGTH l = LENGTH(BUTLAST l) + 1`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPEC `l:A list` APPEND_BUTLAST_LAST) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [SYM th]) THEN
  REWRITE_TAC[LENGTH_APPEND; LENGTH] THEN ARITH_TAC);;
