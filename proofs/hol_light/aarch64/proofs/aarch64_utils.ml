(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

needs "mldsa_native/common/mldsa_specs.ml";;

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

(* Merge 2 x bytes32 reads into bytes64 reads *)
let MEMORY_64_FROM_32_TAC =
  let a_tm = `a:int64` and n_tm = `n:num` and i64_ty = `:int64`
  and pat = `read (memory :> bytes64(word_add a (word n))) s0` in
  fun v boff n ->
    let pat' = subst[mk_var(v,i64_ty),a_tm] pat in
    let f i =
      let itm = mk_small_numeral(boff + 8*i) in
      READ_MEMORY_MERGE_CONV 1 (subst[itm,n_tm] pat') in
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

(* ========================================================================= *)
(* Shared lemmas for eta rejection sampling proofs.                          *)
(* ========================================================================= *)

(* Internal byte->nibble decomposition stored in int16 lanes (matching the   *)
(* SIMD register layout used by the loop body). The public spec uses        *)
(* BYTES_TO_NIBBLES at the natural 4-word bitwidth instead; this view is    *)
(* bridged to the public one via NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES.       *)
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

let NIBBLES_OF_BYTES_4 = prove
 (`!b0 b1 b2 b3:byte.
   NIBBLES_OF_BYTES [b0;b1;b2;b3] =
   [word(val b0 MOD 16); word(val b0 DIV 16);
    word(val b1 MOD 16); word(val b1 DIV 16);
    word(val b2 MOD 16); word(val b2 DIV 16);
    word(val b3 MOD 16); word(val b3 DIV 16):int16]`,
  REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND]);;

let DIMINDEX_16 = DIMINDEX_CONV `dimindex(:16)`;;

let VAL_WORD_NIBBLE_LT = prove
 (`!b:byte.
   val(word(val b MOD 16):int16) = val b MOD 16 /\
   val(word(val b DIV 16):int16) = val b DIV 16`,
  GEN_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN
  MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

let BYTE_AND_15_MOD = BITBLAST_RULE
  `val(word_and (b:byte) (word 15):byte) = val b MOD 16`;;

(* Splits each input byte into its low and high 4-bit nibbles, expressed at *)
(* the natural 4-bit width consumed by the REJ_SAMPLE_ETA{2,4} spec. The    *)
(* output is twice the length of the input. Used at the proof boundary to   *)
(* bridge the byte-shaped internal proof view to the nibble-shaped public   *)
(* spec.                                                                    *)
let BYTES_TO_NIBBLES = define
  `BYTES_TO_NIBBLES [] = ([]:(4 word) list) /\
   BYTES_TO_NIBBLES (CONS (b:byte) t) =
   APPEND [word(val b MOD 16):4 word; word(val b DIV 16):4 word]
          (BYTES_TO_NIBBLES t)`;;

(* Bridge: little-endian bit-content of a byte list equals little-endian    *)
(* bit-content of its nibble decomposition.                                 *)
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

let LENGTH_BYTES_TO_NIBBLES = prove
 (`!l:byte list. LENGTH(BYTES_TO_NIBBLES l) = 2 * LENGTH l`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[BYTES_TO_NIBBLES; LENGTH; LENGTH_APPEND] THEN ARITH_TAC);;

(* Surjectivity onto even-length nibble lists: any nibble list of even      *)
(* length is the BYTES_TO_NIBBLES image of some byte list (twice as short). *)
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

(* Relate the two byte->nibble views: NIBBLES_OF_BYTES carries nibbles in    *)
(* int16 lanes (matching SIMD storage), whereas BYTES_TO_NIBBLES uses the   *)
(* natural 4-bit width consumed by the public REJ_SAMPLE_ETA{2,4} spec.     *)
let NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES = prove
 (`!l:byte list.
     NIBBLES_OF_BYTES l = MAP (\x:4 word. word_zx x:int16) (BYTES_TO_NIBBLES l)`,
  LIST_INDUCT_TAC THENL
   [REWRITE_TAC[NIBBLES_OF_BYTES; BYTES_TO_NIBBLES; MAP]; ALL_TAC] THEN
  REWRITE_TAC[NIBBLES_OF_BYTES; BYTES_TO_NIBBLES; MAP; APPEND] THEN
  ASM_REWRITE_TAC[NIBBLE_PAIR] THEN
  REWRITE_TAC[CONS_11; word_zx; VAL_WORD; DIMINDEX_4; DIMINDEX_16] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[APPEND; CONS_11; MOD_MOD_REFL] THEN
  REPEAT DISCH_TAC THEN AP_TERM_TAC THEN
  MP_TAC(ISPEC `h:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
  MP_TAC(SPECL [`val (h:byte) DIV 16`; `16`] MOD_LT) THEN ARITH_TAC);;

(* Splits a contiguous 8-byte chunk of a byte-list-shape memory contract     *)
(* into the 8 byte-subwords of the int64 read at that offset. Used in the   *)
(* main loop of rej_uniform_eta_{2,4}, where each iteration consumes 8      *)
(* bytes from the input via LDR Q0,[buf,...]; this lemma exposes those 8   *)
(* bytes as the components of the SUB_LIST(8*i, 8) of the abstract list.    *)
let SUB_LIST_8_BYTES_FROM_INT64 = prove
 (`!buf:int64 buflen inlist i s.
    8 * (i + 1) <= buflen /\
    LENGTH (inlist:byte list) = buflen /\
    read (memory :> bytes (buf, buflen)) s = num_of_wordlist inlist
    ==> SUB_LIST (8 * i, 8) inlist =
        [word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (0,8):byte;
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (8,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (16,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (24,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (32,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (40,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (48,8);
         word_subword
           (read (memory :> bytes64 (word_add buf (word (8 * i)))) s) (56,8)]`,
  REPEAT STRIP_TAC THEN
  ABBREV_TAC
    `loaded_d = read (memory :> bytes64 (word_add buf (word (8 * i)))) s` THEN
  CONV_TAC SYM_CONV THEN
  REWRITE_TAC[LISTS_NUM_OF_WORDLIST_EQ] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[LENGTH; LENGTH_SUB_LIST] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[NUM_OF_WORDLIST_SUB_LIST; DIMINDEX_8] THEN
  FIRST_X_ASSUM(MP_TAC o AP_TERM
    `\x. x DIV 2 EXP (8 * 8 * i) MOD 2 EXP (8 * 8)`) THEN
  CONV_TAC(ONCE_DEPTH_CONV BETA_CONV) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_DIV; READ_BYTES_MOD] THEN
  SUBGOAL_THEN `MIN (buflen - 8 * i) 8 = 8` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL
    [`word_add buf (word (8 * i)):int64`; `read memory s`]
    (INST_TYPE[`:64`,`:N`] VAL_READ_WBYTES)) THEN
  REWRITE_TAC[DIMINDEX_64] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[GSYM BYTES64_WBYTES; GSYM READ_COMPONENT_COMPOSE] THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  REWRITE_TAC[num_of_wordlist; DIMINDEX_8] THEN
  CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_BLAST);;

let BYTE_SPLIT_AND = map (fun k ->
    BITBLAST_RULE(parse_term(Printf.sprintf
     "!x:int128 b:byte. \
       word_subword x (%d,16):int16 = word_zx(word_and b (word 15):byte):int16 \
       ==> word_subword x (%d,8):byte = word_and b (word 15):byte /\\ \
           word_subword x (%d,8):byte = word 0:byte"
     (k*16) (k*16) (k*16+8))))
  (0--7);;

let BYTE_SPLIT_USHR = map (fun k ->
    BITBLAST_RULE(parse_term(Printf.sprintf
     "!x:int128 b:byte. \
       word_subword x (%d,16):int16 = word_zx(word_ushr b 4:byte):int16 \
       ==> word_subword x (%d,8):byte = word_ushr b 4:byte /\\ \
           word_subword x (%d,8):byte = word 0:byte"
     (k*16) (k*16) (k*16+8))))
  (0--7);;

let BYTE_USHR4_DIV = WORD_BLAST
  `val(word_ushr (b:byte) 4:byte) = val b DIV 16`;;

let POPCOUNT_AND_POWERS = BITBLAST_RULE
  `word_popcount(word_and (word 1) x:byte) = bitval(bit 0 x) /\
   word_popcount(word_and (word 2) x:byte) = bitval(bit 1 x) /\
   word_popcount(word_and (word 4) x:byte) = bitval(bit 2 x) /\
   word_popcount(word_and (word 8) x:byte) = bitval(bit 3 x) /\
   word_popcount(word_and (word 16) x:byte) = bitval(bit 4 x) /\
   word_popcount(word_and (word 32) x:byte) = bitval(bit 5 x) /\
   word_popcount(word_and (word 64) x:byte) = bitval(bit 6 x) /\
   word_popcount(word_and (word 128) x:byte) = bitval(bit 7 x)`;;

let UADDLV_BOUND_LEMMA = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
   val(word_zx(word_subword
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b0):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b1):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b2):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b3):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b4):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b5):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b6):byte):int16)(0,16):int128)
     (word_subword(word_join (word 0:byte) (word(bitval b7):byte):int16)(0,16):int128))))))))(0,32):int32):int64) <= 8`,
  REPEAT GEN_TAC THEN
  MAP_EVERY BOOL_CASES_TAC [`b0:bool`;`b1:bool`;`b2:bool`;`b3:bool`;
    `b4:bool`;`b5:bool`;`b6:bool`;`b7:bool`] THEN
  REWRITE_TAC[bitval] THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV));;

let UADDLV_COUNT_LEMMA = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
   val(word_zx(word_subword
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b0):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b1):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b2):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b3):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b4):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b5):byte):int16)(0,16):int128)
     (word_add (word_subword(word_join (word 0:byte) (word(bitval b6):byte):int16)(0,16):int128)
     (word_subword(word_join (word 0:byte) (word(bitval b7):byte):int16)(0,16):int128))))))))(0,32):int32):int64) =
   bitval b0 + bitval b1 + bitval b2 + bitval b3 +
   bitval b4 + bitval b5 + bitval b6 + bitval b7`,
  REPEAT GEN_TAC THEN
  MAP_EVERY BOOL_CASES_TAC [`b0:bool`;`b1:bool`;`b2:bool`;`b3:bool`;
    `b4:bool`;`b5:bool`;`b6:bool`;`b7:bool`] THEN
  REWRITE_TAC[bitval] THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV));;

let VAL_WORD_ZX_BYTE16 = WORD_BLAST
  `val(word_zx (b:byte):int16) = val b`;;

let VAL_BYTE_NIB_MOD_65536 = prove(
  `!b:byte. (val b DIV 16) MOD 65536 = val b DIV 16 /\
            val b MOD 16 MOD 65536 = val b MOD 16`,
  GEN_TAC THEN CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN
  MP_TAC(ISPEC `b:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

let WORD_ADD_SHL1 = WORD_BLAST
 `!sp (x:int64) k.
    word_add (word_add sp (word(2 * k):int64))
             (word_shl x 1:int64) =
    word_add sp (word(2 * (k + val(x:int64))):int64)`;;

let LENGTH_FILTER = prove
 (`!P l:A list. LENGTH(FILTER P l) <= LENGTH l`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN ASM_REWRITE_TAC[FILTER; LE_REFL] THEN
  COND_CASES_TAC THEN REWRITE_TAC[LENGTH] THEN ASM_ARITH_TAC);;

let SUB_LIST_MAP = prove(
  `!f (l:A list) n.
     SUB_LIST(0,n)(MAP f l) = MAP f (SUB_LIST(0,n) l):B list`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN INDUCT_TAC THEN
  ASM_REWRITE_TAC[MAP; SUB_LIST_CLAUSES]);;

let EL_SUB_LIST = prove
 (`!l:(A)list. !m n i:num.
     i < n /\ m + i < LENGTH l
     ==> EL i (SUB_LIST (m,n) l) = EL (m + i) l`,
  LIST_INDUCT_TAC THEN REWRITE_TAC[LENGTH; LT] THEN
  MATCH_MP_TAC num_INDUCTION THEN CONJ_TAC THENL
   [MATCH_MP_TAC num_INDUCTION THEN CONJ_TAC THENL
     [REWRITE_TAC[LT];
      X_GEN_TAC `n:num` THEN DISCH_THEN(K ALL_TAC) THEN
      X_GEN_TAC `i:num` THEN REWRITE_TAC[SUB_LIST; ADD_CLAUSES] THEN
      STRUCT_CASES_TAC (SPEC `i:num` num_CASES) THENL
       [REWRITE_TAC[EL; HD];
        REWRITE_TAC[EL; TL; LT_SUC; LENGTH; ADD_CLAUSES] THEN
        STRIP_TAC THEN
        FIRST_X_ASSUM(MP_TAC o SPECL [`0`; `n:num`; `n':num`]) THEN
        ASM_REWRITE_TAC[ADD_CLAUSES] THEN
        DISCH_THEN MATCH_MP_TAC THEN ASM_ARITH_TAC]];
    X_GEN_TAC `m:num` THEN DISCH_THEN(K ALL_TAC) THEN
    X_GEN_TAC `n:num` THEN X_GEN_TAC `i:num` THEN
    REWRITE_TAC[SUB_LIST; LENGTH; ADD_CLAUSES; EL; TL] THEN
    STRIP_TAC THEN
    FIRST_X_ASSUM(MP_TAC o SPECL [`m:num`; `n:num`; `i:num`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_MP_TAC THEN ASM_ARITH_TAC]);;

let SUB_LIST_4_EL = prove
 (`!l:(A)list. !k:num.
     k + 4 <= LENGTH l
     ==> SUB_LIST(k, 4) l =
         [EL k l; EL (k+1) l; EL (k+2) l; EL (k+3) l]`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[LIST_EQ; LENGTH_SUB_LIST; LENGTH] THEN
  CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  X_GEN_TAC `i:num` THEN
  REWRITE_TAC[ARITH_RULE `SUC(SUC(SUC(SUC 0))) = 4`] THEN
  STRIP_TAC THEN
  MP_TAC(ISPECL [`l:(A)list`; `k:num`; `4`; `i:num`] EL_SUB_LIST) THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_THEN SUBST1_TAC] THEN
  SUBGOAL_THEN
    `!P (a:A) b c d.
       (i = 0 ==> P a) /\ (i = 1 ==> P b) /\
       (i = 2 ==> P c) /\ (i = 3 ==> P d)
       ==> P(EL i [a;b;c;d])`
    (fun th -> MATCH_MP_TAC th) THENL
   [REPEAT GEN_TAC THEN STRIP_TAC THEN UNDISCH_TAC `i < 4` THEN
    REWRITE_TAC[ARITH_RULE
      `i < 4 <=> i = 0 \/ i = 1 \/ i = 2 \/ i = 3`] THEN
    STRIP_TAC THEN
    ASM_SIMP_TAC[ARITH_RULE `3 = SUC 2 /\ 2 = SUC 1 /\ 1 = SUC 0`;
                 EL; HD; TL];
    REPEAT CONJ_TAC THEN DISCH_THEN SUBST1_TAC THEN
    REWRITE_TAC[ADD_CLAUSES]]);;

let SUB_LIST_SPLIT_AT = prove
 (`!(l:A list) i.
     i <= LENGTH l
     ==> l = APPEND (SUB_LIST(0, i) l) (SUB_LIST(i, LENGTH l - i) l)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`l:A list`; `i:num`] SUB_LIST_TOPSPLIT) THEN
  ASM_REWRITE_TAC[] THEN DISCH_THEN(fun th -> GEN_REWRITE_TAC LAND_CONV [SYM th]) THEN
  REFL_TAC);;

let SUB_LIST_8nn_INLIST = prove
 (`!inlist:byte list. !nn:num. !buflen:num.
     8 divides buflen /\
     buflen < 8 * (nn + 1) /\
     LENGTH inlist = buflen
     ==>
     SUB_LIST(0, 8 * nn) inlist = inlist`,
  REPEAT STRIP_TAC THEN
  MATCH_MP_TAC SUB_LIST_REFL THEN
  UNDISCH_TAC `8 divides buflen` THEN REWRITE_TAC[divides] THEN
  DISCH_THEN(X_CHOOSE_THEN `k:num` SUBST_ALL_TAC) THEN
  UNDISCH_TAC `LENGTH(inlist:byte list) = 8 * k` THEN
  DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[LE_MULT_LCANCEL] THEN
  UNDISCH_TAC `8 * k < 8 * (nn + 1)` THEN
  REWRITE_TAC[LT_MULT_LCANCEL] THEN ARITH_TAC);;

let STACK_CONTENT = define
 `STACK_CONTENT (niblist:int16 list) =
    SUB_LIST(0, 256) (APPEND niblist (REPLICATE 256 (word 0:int16)))`;;

let STACK_CONTENT_LARGE = prove
 (`!niblist:int16 list.
     256 <= LENGTH niblist
     ==> STACK_CONTENT niblist = SUB_LIST(0, 256) niblist`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[STACK_CONTENT] THEN
  MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_REWRITE_TAC[]);;

let BYTES8_INT16S_TO_BYTES64 = prove
 (`!s:armstate (a:int64) (ws:int16 list).
    LENGTH ws = 4 /\
    read (memory :> bytes (a, 8)) s = num_of_wordlist ws
    ==>
    read (memory :> bytes64 a) s = word(num_of_wordlist ws)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `num_of_wordlist (ws:int16 list) < 2 EXP 64` ASSUME_TAC THENL
   [MP_TAC(ISPECL [`ws:int16 list`; `64:num`] NUM_OF_WORDLIST_BOUND_GEN) THEN
    REWRITE_TAC[DIMINDEX_16] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[GSYM VAL_EQ; READ_COMPONENT_COMPOSE; BYTES64_WBYTES;
              VAL_READ_WBYTES; DIMINDEX_64; ARITH_RULE `64 DIV 8 = 8`;
              VAL_WORD; DIMINDEX_64] THEN
  REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
  ASM_REWRITE_TAC[] THEN CONV_TAC SYM_CONV THEN
  MATCH_MP_TAC MOD_LT THEN ASM_REWRITE_TAC[]);;

let BK_FROM_STACK = prove
 (`!s:armstate. !sp:int64. !niblist:int16 list. !k:num.
    4 * (k + 1) <= LENGTH niblist /\
    read (memory :> bytes (sp, 2 * LENGTH niblist)) s = num_of_wordlist niblist
    ==>
    read (memory :> bytes64 (word_add sp (word (8 * k)))) s =
    word(num_of_wordlist (SUB_LIST(4*k, 4) niblist))`,
  REPEAT STRIP_TAC THEN
  MATCH_MP_TAC BYTES8_INT16S_TO_BYTES64 THEN
  REWRITE_TAC[LENGTH_SUB_LIST] THEN
  CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `read (memory :> bytes (sp, 2 * LENGTH(niblist:int16 list))) s =
     num_of_wordlist (APPEND (SUB_LIST(0, 4 * k) niblist)
                             (SUB_LIST(4 * k, LENGTH niblist - 4 * k) niblist))`
  MP_TAC THENL
   [MP_TAC(ISPECL [`niblist:int16 list`; `4 * k:num`] SUB_LIST_SPLIT_AT) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(fun th -> GEN_REWRITE_TAC
      (RAND_CONV o RAND_CONV o ONCE_DEPTH_CONV) [SYM th]) THEN
    ASM_REWRITE_TAC[];
    ALL_TAC] THEN
  SUBGOAL_THEN `2 * LENGTH(niblist:int16 list) = 8 * k + (2 * LENGTH niblist - 8 * k)`
    (fun th -> GEN_REWRITE_TAC (LAND_CONV o LAND_CONV o ONCE_DEPTH_CONV) [th]) THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`memory:(armstate,(64)word->(8)word)component`;
                 `sp:int64`; `s:armstate`;
                 `SUB_LIST(0, 4 * k) (niblist:int16 list)`;
                 `SUB_LIST(4 * k, LENGTH(niblist:int16 list) - 4 * k) (niblist:int16 list)`;
                 `8 * k:num`; `2 * LENGTH(niblist:int16 list) - 8 * k:num`]
                BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[LENGTH_SUB_LIST; SUB_0; DIMINDEX_16] THEN
  SUBGOAL_THEN `MIN (4 * k) (LENGTH(niblist:int16 list)) = 4 * k` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> DISCH_THEN(MP_TAC o (REWRITE_RULE[th]))) THEN
  DISCH_THEN(MP_TAC o CONJUNCT2) THEN
  SUBGOAL_THEN
    `SUB_LIST(4 * k, LENGTH(niblist:int16 list) - 4 * k) niblist =
     APPEND (SUB_LIST(4 * k, 4) niblist)
            (SUB_LIST(4 * k + 4, LENGTH niblist - 4 * k - 4) niblist)`
  (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV o ONCE_DEPTH_CONV) [th]) THENL
   [MP_TAC(ISPECL [`niblist:int16 list`; `4:num`; `LENGTH(niblist:int16 list) - 4 * k - 4`;
                   `4 * k:num`] SUB_LIST_SPLIT) THEN
    SUBGOAL_THEN `4 + LENGTH(niblist:int16 list) - 4 * k - 4 = LENGTH niblist - 4 * k`
      SUBST1_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN `2 * LENGTH(niblist:int16 list) - 8 * k = 8 + (2 * LENGTH niblist - 8 * k - 8)`
    (fun th -> GEN_REWRITE_TAC (LAND_CONV o LAND_CONV o ONCE_DEPTH_CONV) [th]) THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`memory:(armstate,(64)word->(8)word)component`;
                 `word_add sp (word (8 * k)):int64`; `s:armstate`;
                 `SUB_LIST(4 * k, 4) (niblist:int16 list)`;
                 `SUB_LIST(4 * k + 4, LENGTH(niblist:int16 list) - 4 * k - 4) niblist`;
                 `8:num`; `2 * LENGTH(niblist:int16 list) - 8 * k - 8:num`]
                BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[LENGTH_SUB_LIST; DIMINDEX_16] THEN
  SUBGOAL_THEN `MIN 4 (LENGTH(niblist:int16 list) - 4 * k) = 4` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> DISCH_THEN(MP_TAC o (REWRITE_RULE[th]))) THEN
  DISCH_THEN(MP_TAC o CONJUNCT1) THEN
  REWRITE_TAC[]);;

let BK_FROM_STACK_GE256 = prove
 (`!s:armstate. !sp:int64. !niblist:int16 list. !k:num.
    k < 64 /\ 256 <= LENGTH niblist /\
    read (memory :> bytes (sp, 2 * LENGTH niblist)) s = num_of_wordlist niblist
    ==>
    read (memory :> bytes64 (word_add sp (word (8 * k)))) s =
    word(num_of_wordlist (SUB_LIST(4*k, 4) niblist))`,
  REPEAT STRIP_TAC THEN
  MATCH_MP_TAC BK_FROM_STACK THEN ASM_REWRITE_TAC[] THEN
  ASM_ARITH_TAC);;

let BYTES_EXISTS_WORDLIST = prove
 (`!(a:int64) n s.
    ?(L:int16 list). LENGTH L = n /\
    read (memory :> bytes (a, 2 * n)) s = num_of_wordlist L`,
  GEN_TAC THEN INDUCT_TAC THEN GEN_TAC THENL
   [EXISTS_TAC `[]:int16 list` THEN
    REWRITE_TAC[LENGTH; MULT_CLAUSES; num_of_wordlist;
                READ_COMPONENT_COMPOSE; READ_BYTES_TRIVIAL];
    ALL_TAC] THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `s:armstate`) THEN
  DISCH_THEN(X_CHOOSE_THEN `L:int16 list` STRIP_ASSUME_TAC) THEN
  EXISTS_TAC `APPEND (L:int16 list)
                [word (read (memory :> bytes (word_add a (word (2*n)), 2)) s):int16]` THEN
  REWRITE_TAC[LENGTH_APPEND; LENGTH] THEN
  ASM_REWRITE_TAC[ARITH_RULE `n + 1 = SUC n`] THEN
  REWRITE_TAC[ARITH_RULE `2 * SUC n = 2 * n + 2`] THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_COMBINE] THEN
  REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
  ASM_REWRITE_TAC[NUM_OF_WORDLIST_APPEND; DIMINDEX_16; num_of_wordlist;
                  MULT_CLAUSES; ADD_CLAUSES] THEN
  REWRITE_TAC[ARITH_RULE `8 * 2 * n = 16 * n`] THEN
  AP_TERM_TAC THEN AP_TERM_TAC THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
  CONV_TAC SYM_CONV THEN
  MATCH_MP_TAC MOD_LT THEN
  MP_TAC(ISPECL [`word_add (a:int64) (word (2*n)):int64`; `2`;
                 `read memory s`] READ_BYTES_BOUND) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE] THEN
  CONV_TAC NUM_REDUCE_CONV);;

let PREFIX_FROM_STACK = prove
 (`!stackpointer:int64 (niblist:int16 list) (L:int16 list) s:armstate niblen.
    LENGTH niblist = niblen /\
    LENGTH L = 256 /\
    niblen <= 256 /\
    read (memory :> bytes (stackpointer, 2 * niblen)) s = num_of_wordlist niblist /\
    read (memory :> bytes (stackpointer, 512)) s = num_of_wordlist L
    ==> SUB_LIST(0, niblen) L = niblist`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`memory:(armstate,(64)word->(8)word)component`;
                 `stackpointer:int64`; `s:armstate`;
                 `SUB_LIST(0, niblen) (L:int16 list)`;
                 `SUB_LIST(niblen, 256 - niblen) (L:int16 list)`;
                 `2 * niblen:num`; `512 - 2 * niblen:num`]
                BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[DIMINDEX_16; LENGTH_SUB_LIST; SUB_0] THEN
  SUBGOAL_THEN `MIN niblen (LENGTH(L:int16 list)) = niblen` SUBST1_TAC THENL
   [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `2 * niblen + 512 - 2 * niblen = 512` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
     `APPEND (SUB_LIST(0, niblen) (L:int16 list))
             (SUB_LIST(niblen, 256 - niblen) L) = L`
    ASSUME_TAC THENL
   [MP_TAC(ISPECL [`L:int16 list`; `niblen:num`] SUB_LIST_SPLIT_AT) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th -> GEN_REWRITE_TAC RAND_CONV [th]) THEN
    REFL_TAC;
    ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  STRIP_TAC THEN
  MP_TAC(ISPECL [`SUB_LIST(0, niblen) (L:int16 list)`; `niblist:int16 list`]
                LISTS_NUM_OF_WORDLIST_EQ) THEN
  DISCH_THEN(fun th -> ONCE_REWRITE_TAC[th]) THEN
  ASM_REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN
  ASM_ARITH_TAC);;

let BIGNUM_OF_WORDLIST_EQ_NUM_OF_WORDLIST = prove
 (`!l:int64 list. bignum_of_wordlist l = num_of_wordlist l`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[bignum_of_wordlist; num_of_wordlist; DIMINDEX_64]);;

let BIGNUM_CONS_WORDJOIN = prove
 (`!a:int32. !b:int32. !t:int64 list.
     bignum_of_wordlist (CONS (word_join a b:int64) t) =
     num_of_wordlist [b; a] + 2 EXP 64 * bignum_of_wordlist t`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[bignum_of_wordlist; num_of_wordlist;
              DIMINDEX_32; MULT_CLAUSES; ADD_CLAUSES] THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_JOIN; DIMINDEX_64; DIMINDEX_32] THEN
  MP_TAC(ISPEC `a:int32` VAL_BOUND) THEN
  MP_TAC(ISPEC `b:int32` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_32] THEN REPEAT DISCH_TAC THEN
  SUBGOAL_THEN `(2 EXP 32 * val(a:int32) + val(b:int32)) MOD 2 EXP 64 =
                2 EXP 32 * val a + val b` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC;
    ARITH_TAC]);;

let VAL_WORD_JOIN_INT32_INT64 = prove
 (`!a:int32. !b:int32.
     val (word_join (a:int32) (b:int32):int64) = 2 EXP 32 * val a + val b`,
  REPEAT GEN_TAC THEN REWRITE_TAC[VAL_WORD_JOIN; DIMINDEX_64; DIMINDEX_32] THEN
  MP_TAC(ISPEC `a:int32` VAL_BOUND) THEN
  MP_TAC(ISPEC `b:int32` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_32] THEN REPEAT DISCH_TAC THEN
  MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC);;

let BIGNUM_WORDJOIN_PAIRS_EXISTS = prove
 (`!n l:int32 list. LENGTH l = 2 * n
   ==> ?pairs:int64 list.
         LENGTH pairs = n /\
         bignum_of_wordlist pairs = num_of_wordlist l /\
         (!i. i < n ==> EL i pairs = word_join (EL (2*i+1) l) (EL (2*i) l))`,
  INDUCT_TAC THENL
   [REWRITE_TAC[MULT_CLAUSES; LENGTH_EQ_NIL] THEN
    GEN_TAC THEN DISCH_THEN SUBST1_TAC THEN
    EXISTS_TAC `[]:int64 list` THEN
    REWRITE_TAC[LENGTH; bignum_of_wordlist; num_of_wordlist; LT];
    ALL_TAC] THEN
  LIST_INDUCT_TAC THENL
   [REWRITE_TAC[LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  STRUCT_CASES_TAC (ISPEC `t:int32 list` list_CASES) THENL
   [REWRITE_TAC[LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[LENGTH;
    ARITH_RULE `SUC(SUC(LENGTH(t':int32 list))) = 2 * SUC n <=>
                LENGTH t' = 2 * n`] THEN
  DISCH_TAC THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `t':int32 list`) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `pairs:int64 list` STRIP_ASSUME_TAC) THEN
  EXISTS_TAC `CONS (word_join (h':int32) (h:int32):int64) pairs` THEN
  ASM_REWRITE_TAC[LENGTH] THEN
  CONJ_TAC THENL
   [MP_TAC(SPECL [`h':int32`; `h:int32`; `pairs:int64 list`]
                 BIGNUM_CONS_WORDJOIN) THEN
    DISCH_THEN SUBST1_TAC THEN
    ASM_REWRITE_TAC[num_of_wordlist; DIMINDEX_32] THEN ARITH_TAC;
    X_GEN_TAC `i:num` THEN
    STRUCT_CASES_TAC (SPEC `i:num` num_CASES) THENL
     [REWRITE_TAC[EL; HD; MULT_CLAUSES; ADD_CLAUSES; TL] THEN
      REWRITE_TAC[ARITH_RULE `1 = SUC 0`; EL; TL; HD];
      REWRITE_TAC[EL; TL; LT_SUC] THEN DISCH_TAC THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `n':num`) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
      REWRITE_TAC[ARITH_RULE `2 * SUC n' + 1 = SUC(SUC(2 * n' + 1)) /\
                               2 * SUC n' = SUC(SUC(2 * n'))`] THEN
      REWRITE_TAC[EL; TL; HD]]]);;

let SUB_LIST_EQ_LIST_OF_SEQ = prove
 (`!n l:A list. n <= LENGTH l ==> SUB_LIST (0,n) l = list_of_seq (\i. EL i l) n`,
  INDUCT_TAC THENL
   [REWRITE_TAC[SUB_LIST_CLAUSES; LIST_OF_SEQ]; ALL_TAC] THEN
  LIST_INDUCT_TAC THENL [REWRITE_TAC[LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[SUB_LIST_CLAUSES; LIST_OF_SEQ; LENGTH; LE_SUC] THEN
  DISCH_TAC THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `t:A list`) THEN
  ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[EL; HD; TL; o_THM] THEN
  AP_TERM_TAC THEN AP_THM_TAC THEN AP_TERM_TAC THEN
  REWRITE_TAC[FUN_EQ_THM; o_THM; EL; TL]);;

let WORD_OF_NUM_4INT16 = prove
 (`!h0 h1 h2 h3:int16.
     word (num_of_wordlist [h0;h1;h2;h3]):int64 =
     word_join (word_join h3 h2:int32) (word_join h1 h0:int32)`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[num_of_wordlist; DIMINDEX_16; MULT_CLAUSES; ADD_CLAUSES] THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_JOIN; DIMINDEX_64; DIMINDEX_32;
              DIMINDEX_16; VAL_WORD] THEN
  MP_TAC(ISPEC `h0:int16` VAL_BOUND) THEN
  MP_TAC(ISPEC `h1:int16` VAL_BOUND) THEN
  MP_TAC(ISPEC `h2:int16` VAL_BOUND) THEN
  MP_TAC(ISPEC `h3:int16` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_16] THEN REPEAT DISCH_TAC THEN
  SUBGOAL_THEN `(2 EXP 16 * val(h3:int16) + val(h2:int16)) MOD 2 EXP 32 =
                2 EXP 16 * val h3 + val h2` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(2 EXP 16 * val(h1:int16) + val(h0:int16)) MOD 2 EXP 32 =
                2 EXP 16 * val h1 + val h0` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN ARITH_TAC);;

let WORD_SUBWORD_JOIN_SUB_LIST_H = prove
 (`!niblist:int16 list. !a:num.
     a + 8 <= LENGTH niblist
     ==>
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (0,16):int16 =
       EL a niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (16,16):int16 =
       EL (a+1) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (32,16):int16 =
       EL (a+2) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (48,16):int16 =
       EL (a+3) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (64,16):int16 =
       EL (a+4) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (80,16):int16 =
       EL (a+5) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (96,16):int16 =
       EL (a+6) niblist /\
     word_subword (word_join
       (word(num_of_wordlist(SUB_LIST(a+4,4) niblist)):int64)
       (word(num_of_wordlist(SUB_LIST(a,4) niblist)):int64):int128) (112,16):int16 =
       EL (a+7) niblist`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `a + 4 <= LENGTH(niblist:int16 list) /\
                (a + 4) + 4 <= LENGTH(niblist:int16 list)` STRIP_ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`niblist:int16 list`; `a:num`] SUB_LIST_4_EL) THEN
  MP_TAC(ISPECL [`niblist:int16 list`; `a+4:num`] SUB_LIST_4_EL) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN SUBST1_TAC THEN DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[ARITH_RULE `(a+4)+1 = a+5 /\ (a+4)+2 = a+6 /\ (a+4)+3 = a+7`] THEN
  REWRITE_TAC[WORD_OF_NUM_4INT16] THEN CONV_TAC WORD_BLAST);;

let WORD_INSERT_Q31 = prove(
  `word_insert ((word_insert:int128->num#num->int64->int128) q (0,64)
    (word 2251816993685505)) (64,64) (word 36029071898968080:int64) =
    (word 664619068533544770747334646890102785:int128)`,
  CONV_TAC WORD_BLAST);;

let FILTER_EL_SATISFIES = prove(
 `!(P:A->bool) l i. i < LENGTH(FILTER P l) ==> P(EL i (FILTER P l))`,
 GEN_TAC THEN LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; LENGTH; LT] THEN
 GEN_TAC THEN COND_CASES_TAC THENL
  [STRUCT_CASES_TAC(SPEC `i:num` num_CASES) THEN
   REWRITE_TAC[EL; HD; TL; LENGTH; LT_SUC] THENL
    [ASM_REWRITE_TAC[]; ASM_MESON_TAC[]];
   ASM_MESON_TAC[]]);;

(* ========================================================================= *)
(* Bound lemmas for closing val(idx0)/val(idx1) < 256 in MEMSAFE Subgoal 3   *)
(* of rejection sampling proofs. idx0/idx1 are X12/X13 popcount-accumulator  *)
(* values; their formal shape is word_zx (word_subword (sum-of-8) (0,32)).   *)
(*                                                                           *)
(* These four lemmas have no dependency on consttime symbols and are safe    *)
(* to load at the top of any proof file. The MEMSAFE-discharge tactical      *)
(* helpers (DISCHARGE_MEMSAFE_TAC etc.) depend on consttime symbols and are  *)
(* therefore kept inline in eta2/eta4, where consttime is loaded mid-file.   *)
(* ========================================================================= *)

let WORD_ZX_INT32_INT64 = prove
 (`!w:int32. val(word_zx w:int64) = val w`,
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_64] THEN
  GEN_TAC THEN MATCH_MP_TAC MOD_LT THEN
  MP_TAC(SPEC `w:int32` (INST_TYPE [`:32`,`:N`] VAL_BOUND)) THEN
  REWRITE_TAC[DIMINDEX_32] THEN ARITH_TAC);;

let VAL_WORD_SUBWORD_0_32 = prove
 (`!X:M word. val(word_subword X (0,32):int32) = val X MOD 2 EXP 32`,
  GEN_TAC THEN REWRITE_TAC[VAL_WORD_SUBWORD; DIMINDEX_32] THEN
  REWRITE_TAC[ARITH_RULE `MIN 32 32 = 32`; EXP; DIV_1]);;

(* Polymorphic version: works for any word width N where 256 <= 2^dimindex(:N). *)
let SUM_8_BIT_BOUND_POLY = prove
 (`!a1 a2 a3 a4 a5 a6 a7 a8:N word.
     256 <= 2 EXP dimindex(:N) /\
     val a1 <= 1 /\ val a2 <= 2 /\ val a3 <= 4 /\ val a4 <= 8 /\
     val a5 <= 16 /\ val a6 <= 32 /\ val a7 <= 64 /\ val a8 <= 128
     ==> val(word_add a1 (word_add a2 (word_add a3 (word_add a4
              (word_add a5 (word_add a6 (word_add a7 a8))))))) <= 255`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[VAL_WORD_ADD] THEN
  REPEAT(W(MP_TAC o PART_MATCH (lhand o rand) MOD_LT o lhand o snd) THEN
         (ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC]) THEN
         DISCH_THEN SUBST1_TAC) THEN
  ASM_ARITH_TAC);;

(* Polymorphic SBND for any (k, N): val(word_and (word k:N word) X) <= k for k <= 128. *)
let SBND_K_POLY = prove
 (`!k:num B:bool X.
     k <= 128 /\ 8 <= dimindex(:N)
     ==> val((word_and (word k:N word) X):N word) <= k`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC LE_TRANS `val(word k:N word)` THEN
  REWRITE_TAC[VAL_WORD_AND_LE] THEN
  REWRITE_TAC[VAL_WORD] THEN
  W(MP_TAC o PART_MATCH lhand MOD_LE o lhand o snd) THEN
  REWRITE_TAC[]);;

(* Generic version of BIGNUM_LIST_OF_SEQ_EQ_NUM_SUB_LIST: relate a paired   *)
(* int64 list-of-seq built from a per-element function `f` to the          *)
(* num_of_wordlist of MAP f over a 2*n-element prefix of niblist. Used by  *)
(* rej_uniform_eta_{2,4} with f instantiated to the per-element decode.    *)
let BIGNUM_LIST_OF_SEQ_EQ_NUM_SUB_LIST_POLY = prove
 (`!(f:int16 -> int32) (niblist:int16 list) n.
     2 * n <= LENGTH niblist
     ==>
     bignum_of_wordlist
       (list_of_seq (\i:num. word_join
           (f (EL (2*i+1) niblist)) (f (EL (2*i) niblist)):int64) n) =
     num_of_wordlist (MAP f (SUB_LIST(0, 2*n) niblist))`,
  GEN_TAC THEN GEN_TAC THEN INDUCT_TAC THENL
   [REWRITE_TAC[MULT_CLAUSES; list_of_seq; bignum_of_wordlist;
                SUB_LIST_CLAUSES; MAP; num_of_wordlist];
    ALL_TAC] THEN
  DISCH_TAC THEN
  FIRST_X_ASSUM(MP_TAC o check (is_imp o concl)) THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_TAC] THEN
  REWRITE_TAC[list_of_seq;
              BIGNUM_OF_WORDLIST_APPEND; LENGTH_LIST_OF_SEQ;
              bignum_of_wordlist; MULT_CLAUSES; ADD_CLAUSES] THEN
  ASM_REWRITE_TAC[] THEN
  REWRITE_TAC[VAL_WORD_JOIN_INT32_INT64] THEN
  SUBGOAL_THEN
    `SUB_LIST(0, 2 + 2 * n) (niblist:int16 list) =
     APPEND (SUB_LIST(0, 2 * n) niblist) (SUB_LIST(2 * n, 2) niblist)`
    SUBST1_TAC THENL
   [MP_TAC(ISPECL [`niblist:int16 list`; `2*n:num`; `2`; `0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ADD_CLAUSES; ARITH_RULE `2 * n + 2 = 2 + 2 * n`] THEN
    DISCH_THEN SUBST1_TAC THEN REFL_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[MAP_APPEND; NUM_OF_WORDLIST_APPEND; DIMINDEX_32;
              LENGTH_MAP; LENGTH_SUB_LIST] THEN
  ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `MIN (2 * n) (LENGTH(niblist:int16 list) - 0) = 2 * n`
    SUBST1_TAC THENL
   [REWRITE_TAC[SUB_0] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  AP_TERM_TAC THEN
  REWRITE_TAC[ARITH_RULE `64 * n = 32 * 2 * n`] THEN
  AP_TERM_TAC THEN
  SUBGOAL_THEN `SUB_LIST(2 * n, 2) (niblist:int16 list) =
                [EL (2*n) niblist; EL (2*n+1) niblist]` SUBST1_TAC THENL
   [REWRITE_TAC[LIST_EQ; LENGTH_SUB_LIST; LENGTH] THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    X_GEN_TAC `i:num` THEN REWRITE_TAC[ARITH_RULE `SUC(SUC 0) = 2`] THEN
    DISCH_TAC THEN
    MP_TAC(ISPECL [`niblist:int16 list`; `2*n:num`; `2`; `i:num`]
                  EL_SUB_LIST) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_THEN SUBST1_TAC] THEN
    SUBGOAL_THEN `i = 0 \/ i = 1` MP_TAC THENL
     [ASM_ARITH_TAC;
      STRIP_TAC THEN ASM_REWRITE_TAC[EL; HD; TL; ADD_CLAUSES; num_CONV `1`]];
    REWRITE_TAC[MAP; num_of_wordlist; DIMINDEX_32; MULT_CLAUSES;
                ADD_CLAUSES] THEN ARITH_TAC]);;

