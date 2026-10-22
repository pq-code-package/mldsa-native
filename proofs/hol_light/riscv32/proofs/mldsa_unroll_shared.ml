(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Shared symbolic unrolling for the RV32 ML-DSA arithmetic routines.         *)
(* ========================================================================= *)

needs "mldsa_native/riscv32/proofs/mldsa_specs_aux.ml";;

(* These counts check that execution retains the input reads. They are
   diagnostics, not additional hypotheses or replacements for a proof. *)

let RV32_MLDSA_UNROLL_CHECK_TAC immutable_count mutable_count n
    (asl,_ as gl) =
  let count = length(filter (is_frame_read_rule o concl o snd) asl) in
  if count <> immutable_count then
    failwith ("RV32 unrolling immutable read count=" ^ string_of_int count);
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
  if length views <> mutable_count then
    failwith "RV32 unrolling discarded mutable snapshot reads";
  ALL_TAC gl;;

(* Restore global options on success and failure. The returned
   justifications retain their proofs independently of these options. *)

let RV32_MLDSA_UNROLL_WITH_CACHES_TAC tac gl =
  let saved_rewrite = !context_rewrite_cache_enabled in
  let restore () =
    context_rewrite_cache_enabled := saved_rewrite in
  context_rewrite_cache_enabled := true;
  match tac gl with
  | result -> restore(); result
  | exception error -> restore(); raise error;;

(* Fold arithmetic expressions as a coefficient layout is unfolded.
   Reuse proofs for repeated subexpressions within the bounded cache.
   Context rewrites keep their hypotheses; the conversion cache is valid
   only while those proofs and the basic rewrite net remain unchanged. *)

let RV32_MLDSA_UNROLL_LAYOUT_WITH_CONV step =
  CACHE_LAST_THEOREM_CONV (fun ths ->
    let context_step = CACHED_CONTEXT_REWRITE_CONV true I basic_net ths in
    MEMOIZED_TOP_DEPTH_CONV (context_step ORELSEC step));;

(* Callers expand their input arrays before initialization and supply the
   checked execution rule, exact instruction count, and proved arithmetic
   identities. Both transform and pointwise routines have 256 mutable
   coefficient reads; immutable inputs are protected by the proved frame. *)

let RV32_MLDSA_UNROLL_TAC exec count immutable_count operations definitions
    layout_with_conv =
  let step n =
    RISCV_SINGLE_STEP_TAC exec ("s" ^ string_of_int n) THEN
    RV32_SIMPLIFY_ABBREV_WITH_TAC AUTO_ABBREV_TAC
      operations definitions THEN
    RV32_MLDSA_UNROLL_CHECK_TAC immutable_count 256 n in
  ENSURES_INIT_TAC ~seed_frame:true "s0" THEN
  ENSURES_READ_ONLY_MEMORY_TAC THEN
  WITH_COMPONENT_SNAPSHOTS_TAC
   [`memory:(riscvstate,int32->byte)component`,"memory_snapshot"]
   (MAP_EVERY step (1--count) THEN
    ENSURES_FINAL_STATE_TAC THEN
    CONJ_TAC THENL
     [CACHED_ASM_REWRITE_TAC[];
      CONV_TAC EXPAND_CASES_CONV THEN
      REPEAT CONJ_TAC THEN
      CONV_TAC NUM_REDUCE_CONV THEN
      W(fun (asl,_) ->
        CONV_TAC(RAND_CONV(layout_with_conv(map snd asl)))) THEN
      W(fun (asl,_) ->
        CONV_TAC(LAND_CONV(TOP_DEPTH_CONV
          (!extra_context_read_CONV(map snd asl))))) THEN
      CACHED_ASM_REWRITE_TAC[WORD_ADD_0]]);;
