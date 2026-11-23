(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "s2n_bignum/x86/proofs/consttime.ml";;

(* Drop the event-trace equality while retaining the memory access bounds. *)
let REJ_ETA_MEMSAFE_TAC safe =
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC safe THEN
  DISCH_THEN(CHOOSE_THEN (fun th ->
    let args, _ = strip_forall(concl th) in
    MP_TAC(SPECL args th))) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th ->
    let _, [_; _; post; _] = strip_comb(concl th) in
    ENSURES_POSTCONDITION_TAC post THEN
    CONJ_TAC THENL [BETA_TAC THEN MESON_TAC[]; ACCEPT_TAC th]);;

(* Keep the instruction pointer and the result together so the event
   obligation can be discharged on its own. *)
let add_rej_eta_result result post =
  let s, body = dest_abs post in
  let pc, events = dest_conj body in
  let result_state, value = dest_abs result in
  mk_abs(s, mk_conj(mk_conj(pc, vsubst[s,result_state] value), events));;

let add_rej_eta_core_result result spec =
  let trace, statement = dest_exists spec in
  let args, body = strip_forall statement in
  let hypotheses, core = dest_imp body in
  let ensures_const, [step; pre; post; frame] = strip_comb core in
  let post' = add_rej_eta_result result post in
  mk_exists(trace, list_mk_forall(args,
    mk_imp(hypotheses, list_mk_comb(ensures_const, [step; pre; post'; frame]))));;

(* Project the trace-only statement from the combined core proof. *)
let REJ_ETA_CORE_SAFE_TAC core =
  MP_TAC core THEN MATCH_MP_TAC MONO_EXISTS THEN GEN_TAC THEN
  REPEAT(MATCH_MP_TAC MONO_FORALL THEN GEN_TAC) THEN
  MATCH_MP_TAC MONO_IMP THEN REWRITE_TAC[] THEN
  DISCH_THEN(fun th ->
    let _, [_; _; post; _] = strip_comb(concl th) in
    ENSURES_POSTCONDITION_TAC post THEN
    CONJ_TAC THENL [BETA_TAC THEN MESON_TAC[]; ACCEPT_TAC th]);;

(* The result depends on the input bytes. Choose the actual initial
   event log and discard the trace after obtaining the combined result. *)
let REJ_ETA_CORE_CORRECT_TAC core =
  let _, statement = dest_exists(concl core) in
  let args, _ = strip_forall statement in
  let e = `e:(uarch_event)list` in
  let state = `s0:x86state` in
  let initial_events = `read events (s0:x86state)` in
  let specialize arg = if arg = e then initial_events else arg in
  MAP_EVERY X_GEN_TAC (filter (fun arg -> arg <> e) args) THEN
  STRIP_TAC THEN REWRITE_TAC[ensures; C_RETURN] THEN
  X_GEN_TAC state THEN STRIP_TAC THEN
  MP_TAC core THEN DISCH_THEN(CHOOSE_THEN(MP_TAC o SPECL (map specialize args))) THEN
  ASM_REWRITE_TAC[ensures] THEN DISCH_THEN(MP_TAC o SPEC state) THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[RIGHT_IMP_FORALL_THM] EVENTUALLY_MONO) THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  SIMP_TAC[];;
