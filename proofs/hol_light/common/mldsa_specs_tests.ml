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
