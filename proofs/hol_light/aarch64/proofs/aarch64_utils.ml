(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

needs "common/mldsa_specs.ml";;

let ENSURES_STRENGTHEN_POST = prove(
  `!P (Q:armstate->bool) Q' R.
     ensures arm P Q' R /\ (!s. Q' s ==> Q s) ==> ensures arm P Q R`,
  REPEAT GEN_TAC THEN DISCH_THEN(CONJUNCTS_THEN2 MP_TAC ASSUME_TAC) THEN
  REWRITE_TAC[ensures] THEN MATCH_MP_TAC MONO_FORALL THEN
  X_GEN_TAC `s0:armstate` THEN MATCH_MP_TAC MONO_IMP THEN REWRITE_TAC[] THEN
  MP_TAC(BETA_RULE(ISPECL [`arm`;
    `\s':armstate. (Q':armstate->bool) s' /\ (R:armstate->armstate->bool) (s0:armstate) s'`;
    `\s':armstate. (Q:armstate->bool) s' /\ (R:armstate->armstate->bool) (s0:armstate) s'`]
    EVENTUALLY_MONO)) THEN
  ANTS_TAC THENL [ASM_MESON_TAC[]; MESON_TAC[]]);;

(* Merge 4 x bytes32 reads into bytes128 reads *)
let MEMORY_128_FROM_32_TAC =
  let a_tm = `a:int64` and n_tm = `n:num` and i64_ty = `:int64`
  and pat = `read (memory :> bytes128(word_add a (word n))) s0` in
  fun v boff n ->
    let pat' = subst[mk_var(v,i64_ty),a_tm] pat in
    let f i =
      let itm = mk_small_numeral(boff + 16*i) in
      READ_MEMORY_MERGE_CONV 2 (subst[itm,n_tm] pat') in
    MP_TAC(end_itlist CONJ (map f (0--(n-1))));;

(* ------------------------------------------------------------------------- *)
(* Symbolic execution until target PC is reached.                            *)
(* ------------------------------------------------------------------------- *)
let MAP_UNTIL_TARGET_PC f n = fun (asl, w) ->
  let is_pc_condition = can (term_match [] `read PC some_state = some_value`) in
  let extract_target_pc_from_goal goal =
    let _, insts, _ = term_match [] `eventually arm (\s'. P) some_state` goal in
    insts |> rev_assoc `P: bool` |> conjuncts |> find is_pc_condition in
  let extract_pc_assumption asl =
    try Some (find (is_pc_condition o concl o snd) asl |> snd |> concl) with _ -> None in
  let has_matching_pc_assumption asl target_pc =
    match extract_pc_assumption asl with
     | None -> false
     | Some(asm) -> can (term_match [`returnaddress: 64 word`; `pc: num`] target_pc) asm in
  let target_pc = extract_target_pc_from_goal w in
  let TARGET_PC_REACHED_TAC target_pc = fun (asl, w) ->
    if has_matching_pc_assumption asl target_pc then ALL_TAC (asl, w)
    else NO_TAC (asl, w) in
  let rec core n (asl, w) =
    (TARGET_PC_REACHED_TAC target_pc ORELSE (f n THEN core (n + 1))) (asl, w)
  in core n (asl, w);;

(* ========================================================================= *)
(* SIMD simplification: subword extraction + numeric reduction + folding.    *)
(* ========================================================================= *)

let SIMD_SIMPLIFY_CONV unfold_defs =
  TOP_DEPTH_CONV
   (REWR_CONV WORD_SUBWORD_AND ORELSEC WORD_SIMPLE_SUBWORD_CONV) THENC
  DEPTH_CONV WORD_NUM_RED_CONV THENC
  REWRITE_CONV (map GSYM unfold_defs);;

let SIMD_SIMPLIFY_TAC unfold_defs =
  let simdable = can (term_match [] `read X (s:armstate):int128 = whatever`) in
  TRY(FIRST_X_ASSUM
   (ASSUME_TAC o
    CONV_RULE(RAND_CONV (SIMD_SIMPLIFY_CONV unfold_defs)) o
    check (simdable o concl)));;

(* ========================================================================= *)
(* Parametric infrastructure for d-bit packed coefficients (SIMD).           *)
(* Supports d=18 (GAMMA1=2^17) and d=20 (GAMMA1=2^19).                      *)
(* ========================================================================= *)

(* Convert MOD/DIV expressions to word_subword of (16*d)-bit word *)
let mk_base_simps d =
  let total = 16 * d in
  let rem = total - 256 in
  let total_ty = mk_finty (Num.num_of_int total) in
  let rem_ty = mk_finty (Num.num_of_int rem) in
  let mod_128 = CONV_RULE NUM_REDUCE_CONV (prove(
    inst [total_ty, `:N`]
      `word (t MOD 2 EXP 128) : 128 word =
       word_subword (word t : N word) (0, 128)`,
    REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; VAL_WORD; DIMINDEX_128] THEN
    REWRITE_TAC[EXP; DIV_1; MOD_MOD_REFL; MIN] THEN CONV_TAC NUM_REDUCE_CONV THEN
    CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN
    MP_TAC (SPECL [`t:num`; `2`; mk_small_numeral total; `128`] MOD_MOD_EXP_MIN) THEN
    CONV_TAC NUM_REDUCE_CONV THEN DISCH_THEN (SUBST1_TAC o SYM) THEN REFL_TAC)) in
  let div_128_mod_128 = CONV_RULE NUM_REDUCE_CONV (prove(
    inst [total_ty, `:N`]
      `word ((t DIV 2 EXP 128) MOD 2 EXP 128) : 128 word =
       word_subword (word t : N word) (128, 128)`,
    REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; VAL_WORD; DIMINDEX_128] THEN
    CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN
    REWRITE_TAC[ARITH_RULE `MIN 128 128 = 128`; MOD_MOD_REFL] THEN
    REWRITE_TAC[DIV_MOD; GSYM EXP_ADD; MOD_MOD_EXP_MIN] THEN
    CONV_TAC NUM_REDUCE_CONV)) in
  let div_256 = CONV_RULE NUM_REDUCE_CONV (prove(
    inst [total_ty, `:N`; rem_ty, `:M`]
      `word (t DIV 2 EXP 256) : M word =
       word_subword (word t : N word) (256, dimindex(:M))`,
    REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; VAL_WORD] THEN
    CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[DIV_MOD; GSYM EXP_ADD; MOD_MOD_EXP_MIN] THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MOD_MOD_REFL])) in
  [mod_128; div_128_mod_128; div_256];;

(* Split ncoeffs d-bit coefficients into chunks of chunk_size *)
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

(* Extract individual d-bit coefficients from (d*chunk_size)-bit word *)
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

(* ========================================================================= *)
(* zunpack lane conversion for TBL + USHL + AND + SUB pipeline.              *)
(* ========================================================================= *)

let ZUNPACK_LANE_CONV d i tm =
  let gamma1 = 1 lsl (d - 1) in
  let word_bits = 16 * d in
  let t_ty = mk_finty (Num.num_of_int word_bits) in
  let is_target t =
    try fst(dest_type(type_of t)) = "word" &&
        Num.int_of_num(dest_finty(hd(snd(dest_type(type_of t))))) = word_bits
    with _ -> false in
  let t_var_opt = try Some(find_term is_target tm) with _ -> None in
  match t_var_opt with
  | Some t_var ->
      let d_ty = mk_finty (Num.num_of_int d) in
      let goal = mk_eq(tm,
        subst [mk_small_numeral (d*i), `pos:num`;
               mk_small_numeral d, `bw:num`;
               mk_small_numeral gamma1, `g:num`;
               t_var, mk_var("t", mk_type("word",[t_ty]))]
          (inst [d_ty, `:B`; t_ty, `:T`]
            `word_sub (word g : 32 word)
                      (word_zx (word_subword (t : T word) (pos,bw) : B word))`)) in
      WORD_BLAST goal
  | None -> failwith ("ZUNPACK_LANE_CONV: no " ^ string_of_int word_bits ^ "-bit word");;

let ZUNPACK_128_CONV d tm =
  tryfind (fun base_i ->
    let f i = ZUNPACK_LANE_CONV d (base_i + i) in
    RAND_CONV (
      COMB2_CONV
        (RAND_CONV (COMB2_CONV (RAND_CONV (f 3)) (f 2)))
        (COMB2_CONV (RAND_CONV (f 1)) (f 0)))
    tm) [0; 4; 8; 12];;

let SIMP_ZUNPACK_TAC d zunpack_correct =
  let zunpack_const =
    fst(strip_comb(rhs(snd(strip_forall(concl zunpack_correct))))) in
  let already_processed tm =
    can (find_term ((=) zunpack_const)) tm in
  RULE_ASSUM_TAC (fun th ->
    if already_processed (concl th) then th
    else CONV_RULE (TRY_CONV (ZUNPACK_128_CONV d) THENC
                    TRY_CONV (ONCE_REWRITE_CONV [zunpack_correct])) th);;

(* ------------------------------------------------------------------------- *)
(* Overlapping memory read: derive bytes128 at an unaligned offset from      *)
(* bytes128@16 and a tail read at offset 32.                                 *)
(* For D=20: bytes128@16 + bytes64@32 -> bytes128@24                         *)
(* For D=18: bytes128@16 + bytes32@32 -> bytes128@20                         *)
(* ------------------------------------------------------------------------- *)

let split_k_l_at base k l =
  let a_tm = mk_comb(mk_comb(`word_add:int64->int64->int64`, `a:int64`),
    mk_comb(`word:num->int64`, mk_small_numeral base)) in
  CONV_RULE (ONCE_DEPTH_CONV NUM_ADD_CONV THENC DEPTH_CONV NUM_MULT_CONV)
    (INST [mk_small_numeral k,`k:num`; mk_small_numeral l,`l:num`;
           a_tm, `a:int64`] READ_BYTES_SPLIT_ANY);;

(* For D=20: bytes128@16 + bytes64@32 -> bytes128@24 *)
let BYTES128_FROM_OVERLAP_64 = prove
 (`read (memory :> bytes128 (word_add a (word 16))) (s:armstate) = (word m16 : int128) /\
   read (memory :> bytes64 (word_add a (word 32))) (s:armstate) = (word m64 : int64)
   ==> read (memory :> bytes128 (word_add a (word 24))) s =
       (word_join (word m64 : int64) (word(m16 DIV 2 EXP 64) : int64) : int128)`,
  REWRITE_TAC[BYTES128_WBYTES; BYTES64_WBYTES; READ_COMPONENT_COMPOSE;
              GSYM VAL_EQ; VAL_READ_WBYTES] THEN
  CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN CONV_TAC NUM_REDUCE_CONV THEN
  ABBREV_TAC `m = read memory (s:armstate)` THEN
  REWRITE_TAC[VAL_WORD_JOIN; DIMINDEX_64; VAL_WORD; DIMINDEX_128] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  ONCE_REWRITE_TAC[split_k_l_at 16 8 8] THEN
  ONCE_REWRITE_TAC[split_k_l_at 24 8 8] THEN
  REWRITE_TAC[WORD_ADD_ASSOC_CONSTS] THEN
  CONV_TAC(DEPTH_CONV NUM_ADD_CONV) THEN
  CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
  let COMMON_SETUP =
    SUBGOAL_THEN
     `(m16 DIV 18446744073709551616) MOD 18446744073709551616 < 18446744073709551616 /\
      m64 MOD 18446744073709551616 < 18446744073709551616`
     STRIP_ASSUME_TAC
      THENL [REWRITE_TAC[MOD_LT_EQ; EXP_EQ_0; ARITH_EQ] THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN
     `(18446744073709551616 * m64 MOD 18446744073709551616 +
       (m16 DIV 18446744073709551616) MOD 18446744073709551616) <
      340282366920938463463374607431768211456`
     ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[MOD_LT] in
  CONJ_TAC THENL [
    COMMON_SETUP THEN
    REWRITE_TAC[MOD_MULT_ADD; MOD_MOD_EXP_MIN; GSYM EXP_ADD] THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MOD_MOD_REFL] THEN
    REWRITE_TAC[GSYM(CONV_RULE NUM_REDUCE_CONV
      (SPECL [`m16:num`; `18446744073709551616`; `18446744073709551616`] DIV_MOD))];
    COMMON_SETUP THEN
    SIMP_TAC[DIV_MULT_ADD; ARITH_EQ] THEN ASM_SIMP_TAC[DIV_LT] THEN ARITH_TAC]);;

(* Instantiate overlap theorem for chunk i and ASSUME_TAC the result *)
let DERIVE_OVERLAP_TAC overlap_thm chunk_size i =
  let off16 = chunk_size*i + 16 and off32 = chunk_size*i + 32 in
  let w16 = mk_small_numeral off16 and w32 = mk_small_numeral off32 in
  let has t th = can (find_term ((=) t)) (concl th) in
  let a_val = mk_comb(mk_comb(`word_add:int64->int64->int64`, `b:int64`),
    mk_comb(`word:num->int64`, mk_small_numeral (chunk_size * i))) in
  let inst = INST [a_val, `a:int64`; `s0:armstate`, `s:armstate`] overlap_thm in
  let thm = CONV_RULE (ONCE_DEPTH_CONV(GEN_REWRITE_CONV I [WORD_ADD_ASSOC_CONSTS]) THENC
             DEPTH_CONV NUM_ADD_CONV) inst in
  FIRST_ASSUM(fun th128 ->
    if not(has w16 th128 && has `bytes128` th128 && has `b:int64` th128) then failwith "" else
    FIRST_ASSUM(fun thtail ->
      if not(has w32 thtail && has `b:int64` thtail &&
             not(has `bytes128` thtail)) then failwith "" else
      ASSUME_TAC(MATCH_MP thm (CONJ th128 thtail))));;
