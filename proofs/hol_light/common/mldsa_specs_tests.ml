(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;

let SIMD_ABBREV_TEST_MUL = new_definition
 `simd_abbrev_test_mul (x:int32) = word_mul x (word 8380417)`;;

let simd_abbrev_test_statement =
 `!s:armstate x y z w:int32.
    read Q0 s =
      word_join
        (word_join (simd_abbrev_test_mul x) (simd_abbrev_test_mul y):int64)
        (word_join (simd_abbrev_test_mul z) (simd_abbrev_test_mul w):int64) /\
    val (simd_abbrev_test_mul x) < 100
    ==> read Q0 s =
      word_join
        (word_join (simd_abbrev_test_mul x) (simd_abbrev_test_mul y):int64)
        (word_join (simd_abbrev_test_mul z) (simd_abbrev_test_mul w):int64)`;;

let SIMD_ABBREV_TEST_LEGACY = prove
 (simd_abbrev_test_statement,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SIMD_SIMPLIFY_ABBREV_TAC [SIMD_ABBREV_TEST_MUL] [] THEN
  ASM_REWRITE_TAC[]);;

let () =
  if hyp SIMD_ABBREV_TEST_LEGACY <> [] ||
     concl SIMD_ABBREV_TEST_LEGACY <> simd_abbrev_test_statement
  then failwith "SIMD abbreviation regression changed its claim";
  Printf.printf "SIMD_ABBREVIATION_REGRESSIONS_PASSED\n%!";;

(* REAL_INTEGER_TAC proves structural integer closure without consulting
   assumptions. Keep those facts out of its recursively split subgoals. *)
let () =
  let goal =
    `integer(real_of_int(x:int) +
             real_of_int(y:int) * real_of_int(z:int))` in
  let context = ["unused",ADD_ASSUM `p:bool` (ASSUME `q:bool`)] in
  List.iter (fun tac ->
    let _,goals,justify = tac (context,goal) in
    let th = justify null_inst [] in
    if goals <> [] || concl th <> goal || hyp th <> [] then
      failwith "Integer closure changed its closed claim";
    let th = justify ([],[`v:int`,`x:int`],[]) [] in
    if concl th <>
       `integer(real_of_int(v:int) +
                real_of_int(y:int) * real_of_int(z:int))` ||
       hyp th <> [] then
      failwith "Integer closure lost later instantiation")
   [REAL_INTEGER_TAC; POP_ASSUM_LIST(K REAL_INTEGER_TAC)];
  let bad = `integer(real_of_int(x:int) / &2)` in
  let rejects tac =
    try ignore(tac (["bad",ASSUME bad],bad)); false with Failure _ -> true in
  if not(rejects REAL_INTEGER_TAC) ||
     not(rejects (POP_ASSUM_LIST(K REAL_INTEGER_TAC))) then
    failwith "Integer closure accepted a generally non-integral expression";
  Printf.printf "CONTEXT_FREE_INTEGER_CLOSURE_REGRESSIONS_PASSED\n%!";;
