(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Proving that a stack region has been zeroized.                            *)
(* ========================================================================= *)

(* Proves `read (memory :> bytes(a,n)) s = 0` for n a multiple of 8. *)
let STACK_ZERO_TAC =
  let split_assum n pat =
    REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o CONV_RULE(READ_MEMORY_SPLIT_CONV n) o
      check (can (term_match [] pat) o concl))) in
  W(fun (asl,w) ->
    let n = dest_small_numeral(rand(rand(rand(rand(rator(lhand w)))))) in
    let nth = SYM(NUM_REDUCE_CONV(mk_binop `( * ):num->num->num`
                    (mk_small_numeral 8) (mk_small_numeral(n / 8)))) in
    CONV_TAC(LAND_CONV(RATOR_CONV(RAND_CONV(RAND_CONV(RAND_CONV(RAND_CONV
      (fun t -> if t = lhs(concl nth) then nth else failwith "")))))))) THEN
  CONV_TAC(LAND_CONV BIGNUM_EXPAND_CONV) THEN
  split_assum 2 `read (memory :> bytes256 a) s = x` THEN
  split_assum 1 `read (memory :> bytes128 a) s = x` THEN
  CONV_TAC(ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) THEN
  ASM_REWRITE_TAC[WORD_XOR_REFL] THEN
  CONV_TAC(WORD_REDUCE_CONV THENC NUM_REDUCE_CONV);;
