(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Straight symbolic execution of the fast and slow RV32 forward NTT.        *)
(* ========================================================================= *)

(* The execution rule must come from the caller's checked bytecode.
   This module proves exact output words, without input bounds. The existing
   arithmetic theorem supplies the mathematical NTT and its output bounds.

   Shared s2n-bignum optimizations remain scoped to this proof. Both
   implementations use the same table and coefficient layout; only the
   instruction count, permitted registers, and Barrett folding differ. *)

needs "mldsa_native/riscv32/proofs/mldsa_ntt_layout.ml";;

let RV32_MLDSA_NTT_UNROLL_PAIR_THMS =
  map (fun k ->
    let pair = mk_comb(`rv32_mldsa_ntt_pair`,mk_small_numeral k) in
    (GEN_REWRITE_CONV I [rv32_mldsa_ntt_pair] THENC
     NUM_REDUCE_CONV THENC
     GEN_REWRITE_CONV DEPTH_CONV [rv32_mldsa_ntt_zetas] THENC
     DEPTH_CONV EL_CONV THENC
     DEPTH_CONV WORD_IWORD_CONV) pair)
    (0--254);;

let RV32_MLDSA_NTT_UNROLL_BARRETT_DEFS slow =
  map (fun pth ->
    let th =
      if slow then
        let z,w = dest_pair(rhs(concl pth)) in
        REWRITE_RULE[LET_DEF; LET_END_DEF]
          (SPECL [z;w] MLDSA_BARRETT_MUL_SLOW)
      else REWRITE_RULE[FST; SND]
        (SPEC (rhs(concl pth)) RV32_MLDSA_BARRETT_PAIR) in
    GSYM (CONV_RULE
      (BINDER_CONV (LAND_CONV (DEPTH_CONV WORD_SX_CONV))) th))
    RV32_MLDSA_NTT_UNROLL_PAIR_THMS;;

let RV32_MLDSA_NTT_UNROLL_LAYOUT_STEP_CONV =
  let pairs = Array.of_list RV32_MLDSA_NTT_UNROLL_PAIR_THMS in
  let pair_conv = function
    | Comb(Const("rv32_mldsa_ntt_pair",_),k) as tm ->
        let th = pairs.(dest_small_numeral k) in
        if lhs(concl th) = tm then th else failwith "pair_conv"
    | _ -> failwith "pair_conv" in
  NUM_RED_CONV ORELSEC BETA_CONV ORELSEC WORD_IWORD_CONV ORELSEC
  pair_conv ORELSEC
  GEN_REWRITE_CONV I
   [rv32_mldsa_ntt_phase1234; rv32_mldsa_ntt_phase4;
    rv32_mldsa_ntt_phase123; rv32_mldsa_ntt_phase3;
    rv32_mldsa_ntt_phase12; rv32_mldsa_ntt_phase2;
    rv32_mldsa_ntt_phase1; rv32_mldsa_radix4;
    LET_DEF; LET_END_DEF; COND_CLAUSES];;

let RV32_MLDSA_NTT_UNROLL_LAYOUT_CONV =
  TOP_DEPTH_CONV RV32_MLDSA_NTT_UNROLL_LAYOUT_STEP_CONV;;

(* Fold proved arithmetic expressions while unfolding nested layouts,
   rather than first constructing the fully expanded expression. This
   uses the ordinary context rewrite rules and retains their hypotheses.
   Prepare once for the output context, before splitting its coefficient
   goals. Reuse proofs for repeated subexpressions within
   MEMOIZED_TOP_DEPTH_CONV's bounded cache. *)

let RV32_MLDSA_NTT_UNROLL_LAYOUT_WITH_CONV ths =
  let context_step = GENERAL_REWRITE_CONV true I (basic_net()) ths in
  MEMOIZED_TOP_DEPTH_CONV
    (context_step ORELSEC RV32_MLDSA_NTT_UNROLL_LAYOUT_STEP_CONV);;

let RV32_MLDSA_NTT_UNROLL_REGISTERS slow =
  if slow then
    `[PC; S0; S1; S2; S3; S4; S5;
      A1; T2; T3; T4; A2; A3; A4; A5; A6; A7]`
  else
    `[PC; T0; S0; S1; S2; S3; S4; S5;
      A1; T2; T3; T4; A2; A3; A4; A5; A6; A7]`;;

let RV32_MLDSA_NTT_UNROLL_SPEC mc slow =
  vsubst
   [mc,`code:byte list`;
    mk_small_numeral (if slow then 932 else 748),`end_offset:num`;
    RV32_MLDSA_NTT_UNROLL_REGISTERS slow,
      `allowed_regs:((riscvstate,int32)component)list`]
   `!a zetas:int32. !x:num->int32. !pc:num.
      aligned 4 a /\ aligned 4 zetas /\
      nonoverlapping (word pc,LENGTH code) (a,1024) /\
      nonoverlapping (a,1024) (zetas,2040)
      ==> ensures riscv
        (\s. aligned_bytes_loaded s (word pc) code /\
             read PC s = word(pc + 28) /\
             C_ARGUMENTS [a;zetas] s /\
             wordlist_from_memory(zetas,510) s:int32 list =
               MAP iword rv32_mldsa_ntt_zetas /\
             (!i. i < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * i)))) s =
                 x i))
        (\s. read PC s = word(pc + end_offset) /\
             !i. i < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * i)))) s =
                 rv32_mldsa_ntt_phase1234 x (i DIV 4) (i MOD 4))
        (MAYCHANGE (allowed_regs:((riscvstate,int32)component)list) ,,
         MAYCHANGE [memory :> bytes(a,1024)] ,,
         MAYCHANGE [events])`;;

(* Fact counts are diagnostics, not premises or proof shortcuts. Check both
   immutable table reads and mutable snapshot reads after every instruction. *)

let RV32_MLDSA_NTT_UNROLL_CHECK_TAC n (asl,_ as gl) =
  let count = length(filter (is_frame_read_rule o concl o snd) asl) in
  if count <> 510 then
    failwith ("NTT unrolling immutable read count=" ^ string_of_int count);
  let current_read = list_mk_icomb "read"
    [`memory:(riscvstate,int32->byte)component`;
     mk_var("s" ^ string_of_int n,`:riscvstate`)] in
  let parent_th = find (fun (_,th) ->
    is_eq(concl th) && lhs(concl th) = current_read) asl |> snd in
  let snapshot = rhs(concl parent_th) in
  let views = filter (fun (_,th) ->
    match concl th with
    | Comb(Comb(Const("=",_),
        Comb(Comb(Const("read",_),_),s)),_) -> s = snapshot
    | _ -> false) asl in
  if length views <> 256 then
    failwith "NTT unrolling discarded mutable snapshot reads";
  ALL_TAC gl;;

(* Restore global options on success and failure. Returned justifications
   retain their own proofs and do not depend on these mutable options. *)

let RV32_MLDSA_NTT_UNROLL_WITH_CACHES_TAC tac gl =
  let saved_rewrite = !context_rewrite_cache_enabled in
  let restore () =
    context_rewrite_cache_enabled := saved_rewrite in
  context_rewrite_cache_enabled := true;
  match tac gl with
  | result -> restore(); result
  | exception error -> restore(); raise error;;

let RV32_MLDSA_NTT_UNROLL_RULE mc exec slow =
  let definitions = RV32_MLDSA_NTT_UNROLL_BARRETT_DEFS slow in
  let simplify =
    RV32_SIMPLIFY_ABBREV_WITH_TAC AUTO_ABBREV_TAC
      [mldsa_barrett_mul] definitions in
  let execute = RISCV_SINGLE_STEP_TAC exec in
  let step n =
    execute ("s" ^ string_of_int n) THEN simplify THEN
    RV32_MLDSA_NTT_UNROLL_CHECK_TAC n in
  prove
   (RV32_MLDSA_NTT_UNROLL_SPEC mc slow,
    RV32_MLDSA_NTT_UNROLL_WITH_CACHES_TAC
     (REWRITE_TAC[fst exec; C_ARGUMENTS] THEN
      REPEAT STRIP_TAC THEN
      CONV_TAC(RATOR_CONV(LAND_CONV
        (ONCE_DEPTH_CONV EXPAND_CASES_CONV))) THEN
      CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
      REWRITE_TAC[rv32_mldsa_ntt_zetas; MAP; CONS_11] THEN
      CONV_TAC(ONCE_DEPTH_CONV WORD_IWORD_CONV) THEN
      CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[WORD_ADD_0] THEN
      ENSURES_INIT_TAC ~seed_frame:true "s0" THEN
      ENSURES_READ_ONLY_MEMORY_TAC THEN
      (fun (asl,_ as gl) ->
        let count = length(filter (is_frame_read_rule o concl o snd) asl) in
        if count <> 510 then
          failwith ("NTT initial immutable read count=" ^ string_of_int count);
        ALL_TAC gl) THEN
      WITH_COMPONENT_SNAPSHOTS_TAC
       [`memory:(riscvstate,int32->byte)component`,"memory_snapshot"]
       (MAP_EVERY step (1--(if slow then 12439 else 9369)) THEN
        ENSURES_FINAL_STATE_TAC THEN
        CONJ_TAC THENL
         [CACHED_ASM_REWRITE_TAC[];
          CONV_TAC EXPAND_CASES_CONV THEN
          W(fun (asl,_) ->
            let fold = RAND_CONV
              (RV32_MLDSA_NTT_UNROLL_LAYOUT_WITH_CONV(map snd asl)) in
            REPEAT CONJ_TAC THEN
            CONV_TAC NUM_REDUCE_CONV THEN
            CONV_TAC fold) THEN
          W(fun (asl,_) ->
            CONV_TAC(LAND_CONV(TOP_DEPTH_CONV
              (!extra_context_read_CONV(map snd asl))))) THEN
          CACHED_ASM_REWRITE_TAC[WORD_ADD_0]])));;
