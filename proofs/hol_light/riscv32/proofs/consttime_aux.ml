(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Additional constant-time tactics for the long RV32 proofs.               *)
(*                                                                           *)
(* Load s2n_bignum/riscv/proofs/consttime.ml before loading this file.       *)
(* ========================================================================= *)

(* The upstream safety tactic builds one theorem containing the complete
   instruction trace. That becomes too deep for the long RV32 NTT routines;
   the slow inverse proof, for example, visits 15,793 machine states.

   `MATERIALIZE_ONE_GOAL_TAC` saves the result reached after one block of
   instructions as a separate theorem. `GEN_PROVE_SAFETY_SPEC_TAC` repeats
   that process in blocks of 125 instructions.
   `CLOSE_ABBREVIATED_SAFETY_PROPERTY_TAC` uses the saved block theorems to
   prove the final trace and memory-access claims without rebuilding one large
   proof term. `PROVE_SAFETY_SPEC_TAC` is the entry point used by all five
   top-level RV32 proof files. *)

(* Finish the safety proof without expanding the saved trace. Keep each local
   trace definition folded, then reuse the existing proof that every memory
   access is within its permitted region. *)
let CLOSE_ABBREVIATED_SAFETY_PROPERTY_TAC
    (stored_abbrevs:thm list ref):tactic =
  fun (asl,w) ->
    let _,body = dest_exists w in
    let event_eq,f_events_eq =
      match conjuncts body with
      | event_eq::f_events_eq::_ -> event_eq,f_events_eq
      | _ -> failwith "expected the generated safety property" in
    (* A trace with no events remains the initial event list instead of
       becoming APPEND [] initial_events. *)
    let compact_trace,empty_trace =
      let final_events = lhs event_eq in
      if is_binary "APPEND" final_events then
        fst (dest_binary "APPEND" final_events),false
      else
        let _,initial_events =
          dest_binary "APPEND" (rhs event_eq) in
        if final_events = initial_events then
          let event_ty =
            match dest_type (type_of final_events) with
            | "list",[ty] -> ty
            | _ -> failwith "expected an event list" in
          mk_list([],event_ty),true
        else failwith "unexpected final event trace" in
    let f_events,args = strip_comb (rhs f_events_eq) in
    let open_f_events = list_mk_abs(args,compact_trace) in
    let close_one (acc,acc_equals_open) th =
      let definition,trace_var = dest_eq (concl th) in
      let binder = mk_abs(trace_var,acc) in
      let closed_acc = mk_comb(binder,definition) in
      let closed_acc_equals_acc =
        CONV_RULE (RAND_CONV BETA_CONV)
          (AP_TERM binder th) in
      closed_acc,TRANS closed_acc_equals_acc acc_equals_open in
    let _,closed_equals_open =
      List.fold_left close_one
        (open_f_events,REFL open_f_events)
        !stored_abbrevs in
    let compact_equals_closed =
      let applied_equals_open =
        List.fold_left
          (fun th arg -> AP_THM th arg)
          closed_equals_open args in
      SYM
        (CONV_RULE
          (RAND_CONV (DEPTH_CONV BETA_CONV))
          applied_equals_open) in
    (EXISTS_TAC compact_trace THEN
     CONJ_TAC THENL [
       (if empty_trace then REWRITE_TAC[APPEND] else REFL_TAC);
       CONJ_TAC THENL [
         UNIFY_ACCEPT_TAC [f_events] compact_equals_closed;
         DISCHARGE_MEMACCESS_INBOUNDS_TAC
       ]
     ]) (asl,w);;

(* Run a tactic that leaves one goal, then save the work it has already done
   as a theorem. Quantifying the new variables and assumptions lets later
   steps reuse that theorem instead of rebuilding the same proof term. *)
let MATERIALIZE_ONE_GOAL_TAC (tac:tactic):tactic =
  fun ((asl0,w0) as goal0) ->
    let ((mvs,inst),goals,just) = tac goal0 in
    match goals with
    | [asl1,w1] ->
        let goal_terms asl w =
          w::itlist
            (fun (_,th) acc -> concl th::(hyp th @ acc))
            asl [] in
        let asms1 =
          itlist
            (fun (_,th) acc ->
              union (insert (concl th) (hyp th)) acc)
            asl1 [] in
        let oldvars = freesl (goal_terms asl0 w0) in
        let newvars = freesl (w1::asms1) in
        let localvars = subtract newvars (union mvs oldvars) in
        let package =
          list_mk_forall
            (localvars,itlist (fun a b -> mk_imp(a,b)) asms1 w1) in
        let fake_subgoal =
          funpow (length asms1) UNDISCH
            (SPECL localvars (ASSUME package)) in
        let cached = just null_inst [fake_subgoal] in
        let bridge = DISCH package cached in
        ((mvs,inst),goals,
         fun i ths ->
           match ths with
           | [th] ->
               let asms_i = map (instantiate i) asms1
               and localvars_i = map (instantiate i) localvars
               and package_i = instantiate i package in
               let discharged = itlist DISCH asms_i th in
               if exists
                    (fun v -> exists (vfree_in v) (hyp discharged))
                    localvars_i
               then failwith
                 "MATERIALIZE_ONE_GOAL_TAC: local variable escaped";
               let packed = GENL localvars_i discharged in
               let packed =
                 if concl packed = package_i then packed
                 else EQ_MP (ALPHA (concl packed) package_i) packed in
               MP (INSTANTIATE_ALL i bridge) packed
           | _ ->
               failwith
                 "MATERIALIZE_ONE_GOAL_TAC: bad theorem list")
    | _ ->
        failwith "MATERIALIZE_ONE_GOAL_TAC: expected one subgoal";;

(* Replace the upstream driver with a block-based version without changing
   theorem statements. Save a theorem after each block and keep the trace
   abbreviated until the final memory bounds are proved. *)
let GEN_PROVE_SAFETY_SPEC_TAC =
  let mainfn ?(public_vars:term list option)
    ?(tac_before_maychange_simp:tactic option) exec
    (extra_unpack_thms:thm list) single_step_tac
    :tactic =

    REWRITE_TAC[C_ARGUMENTS;ALL;ALLPAIRS;SOME_FLAGS;fst exec] THEN
    REWRITE_TAC extra_unpack_thms THEN

    W (fun (asl,w) ->
      let f_events = fst (dest_exists w) in
      let quantvars,forall_body = strip_forall(snd(dest_exists w)) in
      let stored_abbrevs = ref [] in

      if quantvars = [] || name_of (hd quantvars) <> "e" ||
         not (is_uarch_event_list_ty (type_of (hd quantvars)))
      then failwith "The goal must be `exists f_events. forall e ...`" else

      let dest_pc_addr =
        let triple = if is_imp forall_body
          then snd (dest_imp forall_body) else forall_body in
        let _,(sem::pre::post::frame::[]) = strip_comb triple in
        let read_pc_eq =
          find_term (fun t -> is_eq t && is_read_pc (lhs t)) post in
        snd (dest_eq read_pc_eq) in

      X_META_EXISTS_TAC f_events THEN
      REPEAT_GEN_AND_OFFSET_STACKPTR_TAC THEN
      TRY DISCH_TAC THEN
      REPEAT SPLIT_FIRST_CONJ_ASSUM_TAC THEN

      ENSURES_INIT_TAC "s0" THEN
      (match public_vars with
      | None -> ALL_TAC
      | Some public_vars ->
        DISCARD_ASSUMPTIONS_TAC (fun th ->
            let t = concl th in
            is_eq t && is_binary "read" (lhs t) &&
            intersect (frees t) public_vars = [])) THEN

      let chunksize = 125 in
      let i = ref 0 in
      let successful = ref true and hasnext = ref true in
      WHILE_TAC hasnext
        (MATERIALIZE_ONE_GOAL_TAC
          (W (fun (_,_) ->
            REPEAT_N chunksize (W (fun (asl,w) ->
              match List.find_opt (fun (_,th) ->
                  is_eq (concl th) && is_read_pc (lhs (concl th)))
                  asl with
              | None ->
                successful := false; hasnext := false; ALL_TAC
              | Some (_,read_pc_th) ->
                if rhs (concl read_pc_th) = dest_pc_addr
                then (hasnext := false; ALL_TAC)
                else
                  let _ = i := !i + 1 in
                  single_step_tac exec ("s" ^ string_of_int !i)))
            THEN

            (match tac_before_maychange_simp with
             | Some tac -> tac | None -> ALL_TAC) THEN
            SIMPLIFY_MAYCHANGES_TAC)) THEN
         ABBREV_TRACE_TAC stored_abbrevs THEN
         CLARIFY_TAC) THEN

      W (fun (asl,w) ->
        if not !successful
        then FAIL_TAC
          ("could not reach to the destination pc (" ^
           string_of_term dest_pc_addr ^ ")")
        else ALL_TAC) THEN

      ENSURES_FINAL_STATE_TAC THEN
      ASM_REWRITE_TAC[] THEN
      CLOSE_ABBREVIATED_SAFETY_PROPERTY_TAC stored_abbrevs)
  in mainfn;;

(* Provide the block-based driver through the RISC-V entry point used by the
   top-level proofs. *)

let PROVE_SAFETY_SPEC_TAC ?(public_vars:term list option) exec:tactic =
  GEN_PROVE_SAFETY_SPEC_TAC ?public_vars:public_vars exec
    [ALIGNED_BYTES_LOADED_APPEND_CLAUSE;
     MAYCHANGE_REGS_PERMITTED_BY_ABI]
    RISCV_SINGLE_STEP_TAC;;
