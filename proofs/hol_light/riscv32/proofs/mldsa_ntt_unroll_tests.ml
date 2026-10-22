(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "mldsa_native/riscv32/proofs/mldsa_intt_unroll_shared.ml";;

let _ =
  let code = mk_var("test_code",`:byte list`) in
  let fast = RV32_MLDSA_NTT_UNROLL_SPEC code false
  and slow = RV32_MLDSA_NTT_UNROLL_SPEC code true in
  if not(vfree_in code fast) || not(vfree_in code slow) ||
     fast = slow || frees fast <> [code] || frees slow <> [code]
  then failwith "unroll specification parameters were lost";
  let inverse_fast = RV32_MLDSA_INTT_UNROLL_SPEC code false
  and inverse_slow = RV32_MLDSA_INTT_UNROLL_SPEC code true in
  if not(vfree_in code inverse_fast) ||
     not(vfree_in code inverse_slow) ||
     inverse_fast = inverse_slow ||
     frees inverse_fast <> [code] || frees inverse_slow <> [code]
  then failwith "inverse unroll specification parameters were lost";
  let saved_rewrite = !context_rewrite_cache_enabled in
  let inside _ =
    if not !context_rewrite_cache_enabled
    then failwith "unroll options were not enabled";
    failwith "intentional unroll-option regression" in
  let failed =
    try ignore(RV32_MLDSA_NTT_UNROLL_WITH_CACHES_TAC inside ([],`T`));
        false
    with Failure message ->
      message = "intentional unroll-option regression" in
  if not failed ||
     !context_rewrite_cache_enabled <> saved_rewrite
  then failwith "failed unroll tactic did not restore its options";
  ignore(RV32_MLDSA_NTT_UNROLL_WITH_CACHES_TAC ALL_TAC ([],`T`));
  if !context_rewrite_cache_enabled <> saved_rewrite
  then failwith "successful unroll tactic did not restore its options";;

let _ =
  let saved_rewrite = !context_rewrite_cache_enabled in
  let inside _ =
    if not !context_rewrite_cache_enabled
    then failwith "shared unroll options were not enabled";
    failwith "intentional shared-unroll regression" in
  let failed =
    try ignore(RV32_MLDSA_UNROLL_WITH_CACHES_TAC inside ([],`T`)); false
    with Failure message -> message = "intentional shared-unroll regression" in
  if not failed ||
     !context_rewrite_cache_enabled <> saved_rewrite
  then failwith "failed shared unroll tactic did not restore its options";
  ignore(RV32_MLDSA_UNROLL_WITH_CACHES_TAC ALL_TAC ([],`T`));
  if !context_rewrite_cache_enabled <> saved_rewrite
  then failwith "successful shared unroll tactic did not restore its options";;

let _ =
  let target = `rv32_mldsa_ntt_phase12 (x:num->int32) 0 0 0` in
  let expanded = RV32_MLDSA_NTT_UNROLL_LAYOUT_CONV target in
  let expression = find_term (fun tm ->
    let head,args = strip_comb tm in
    head = `mldsa_barrett_mul` && length args = 2)
    (rhs(concl expanded)) in
  let name = mk_var("ntt_layout_fold_test",`:int32`) in
  let definition = ASSUME(mk_eq(expression,name)) in
  let late =
    (RV32_MLDSA_NTT_UNROLL_LAYOUT_CONV THENC
     REWRITE_CONV[definition]) target
  and early =
    RV32_MLDSA_NTT_UNROLL_LAYOUT_WITH_CONV [definition] target in
  if concl early <> concl late || hyp early <> hyp late ||
     not(vfree_in name (rhs(concl early)))
  then failwith "early layout folding changed its result or hypotheses";
  let contextual = ADD_ASSUM `p:bool` definition in
  let result =
    RV32_MLDSA_NTT_UNROLL_LAYOUT_WITH_CONV [contextual] target in
  if not(mem `p:bool` (hyp result)) then
    failwith "layout folding reused a theorem from another context";;

let _ =
  (* Output zero is a sum only; output one contains a Barrett product. *)
  let target = `rv32_mldsa_intt_phase12 (x:num->int32) 0 0 1` in
  let layout_conv =
    TOP_DEPTH_CONV RV32_MLDSA_INTT_UNROLL_LAYOUT_STEP_CONV in
  let expanded = layout_conv target in
  let expression = find_term (fun tm ->
    let head,args = strip_comb tm in
    head = `mldsa_barrett_mul` && length args = 2)
    (rhs(concl expanded)) in
  let name = mk_var("intt_layout_fold_test",`:int32`) in
  let definition = ASSUME(mk_eq(expression,name)) in
  let late = (layout_conv THENC REWRITE_CONV[definition]) target
  and early =
    RV32_MLDSA_INTT_UNROLL_LAYOUT_WITH_CONV [definition] target in
  if concl early <> concl late || hyp early <> hyp late ||
     not(vfree_in name (rhs(concl early)))
  then failwith "inverse layout folding changed its result or hypotheses";
  let contextual = ADD_ASSUM `p:bool` definition in
  let result =
    RV32_MLDSA_INTT_UNROLL_LAYOUT_WITH_CONV [contextual] target in
  if not(mem `p:bool` (hyp result)) then
    failwith "inverse layout folding reused another context's theorem";;

Printf.printf "RV32 NTT UNROLL FACTORY REGRESSIONS PASSED\n%!";;
