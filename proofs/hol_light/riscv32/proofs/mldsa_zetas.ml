(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* RV32IM ML-DSA transform constants.                                        *)
(* ========================================================================= *)

(* This file checks the table used by the four RV32 NTT routines.
   `rv32_mldsa_ntt_generated_zetas` describes, from the ML-DSA root, the
   `(zeta,w)` pairs needed by each pair of NTT layers.
   `RV32_MLDSA_NTT_ZETAS_LENGTH` proves that the generated literal has 510
   words, and `RV32_MLDSA_NTT_ZETAS_CORRECT` proves that every word is in the
   required order and has the required value.

   `mldsa_ntt_shared.ml` imports these two results. The four assembly proofs
   then use them to turn concrete table loads into mathematical roots. *)

needs "s2n_bignum/riscv/proofs/base.ml";;
needs "mldsa_native/riscv32/proofs/mldsa_specs_aux.ml";;

(* The generator indexes a layer root by 2^layer + block, bit-reverses that
   index, and stores the centered power together with its signed-high Barrett
   multiplier. *)

let rv32_mldsa_ntt_root = define
 `rv32_mldsa_ntt_root n =
    let z = (&1753 pow (bitreverse8 n)) rem &8380417 in
    if z <= &4190208 then z else z - &8380417`;;

let rv32_mldsa_ntt_root_multiplier = define
 `rv32_mldsa_ntt_root_multiplier z =
    if &0 <= z then
      (z * &4294967296 + &4190208) div &8380417
    else
      --((--z * &4294967296 + &4190208) div &8380417)`;;

let rv32_mldsa_ntt_root_pair = define
 `rv32_mldsa_ntt_root_pair n =
    let z = rv32_mldsa_ntt_root n in
    [z; rv32_mldsa_ntt_root_multiplier z]`;;

(* One assembly loop handles layers 2p and 2p+1 together. Each group loads
   one root for the first layer and two roots for the second layer. *)

let rv32_mldsa_ntt_root_triplet = define
 `rv32_mldsa_ntt_root_triplet p i =
    APPEND
     (rv32_mldsa_ntt_root_pair (2 EXP (2 * p) + i))
     (APPEND
       (rv32_mldsa_ntt_root_pair (2 EXP (2 * p + 1) + 2 * i))
       (rv32_mldsa_ntt_root_pair
         (2 EXP (2 * p + 1) + 2 * i + 1)))`;;

let rv32_mldsa_ntt_generated_zetas = define
 `rv32_mldsa_ntt_generated_zetas =
    ITLIST APPEND
     (list_of_seq
       (\p. ITLIST APPEND
             (list_of_seq (rv32_mldsa_ntt_root_triplet p)
                          (2 EXP (2 * p))) [])
       4) []`;;

(* Evaluate one generated centered root at a concrete table index. For
   example, applying `RV32_MLDSA_NTT_ROOT_CONV` to
   `rv32_mldsa_ntt_root 1` returns an equality with the corresponding signed
   root on the right. *)

let RV32_MLDSA_NTT_ROOT_CONV =
  GEN_REWRITE_CONV I [rv32_mldsa_ntt_root] THENC
  GEN_REWRITE_CONV ONCE_DEPTH_CONV [BITREVERSE8_CLAUSES] THENC
  ONCE_DEPTH_CONV MLDSA_ROOT_POWER_CONV THENC
  ONCE_DEPTH_CONV let_CONV THENC
  INT_REDUCE_CONV;;

(* Evaluate the two-word `(z,w)` Barrett pair at a concrete table index. For
   example, applying `RV32_MLDSA_NTT_ROOT_PAIR_CONV` to
   `rv32_mldsa_ntt_root_pair 1` returns the concrete two-element list. *)

let RV32_MLDSA_NTT_ROOT_PAIR_CONV =
  GEN_REWRITE_CONV I [rv32_mldsa_ntt_root_pair] THENC
  ONCE_DEPTH_CONV RV32_MLDSA_NTT_ROOT_CONV THENC
  ONCE_DEPTH_CONV let_CONV THENC
  GEN_REWRITE_CONV ONCE_DEPTH_CONV
   [rv32_mldsa_ntt_root_multiplier] THENC
  INT_REDUCE_CONV;;

needs "mldsa_native/riscv32/proofs/mldsa_zetas_table.ml";;

let RV32_MLDSA_NTT_ZETAS_LENGTH = prove
 (`LENGTH rv32_mldsa_ntt_zetas = 510`,
  REWRITE_TAC[rv32_mldsa_ntt_zetas; LENGTH] THEN
  CONV_TAC NUM_REDUCE_CONV);;

let RV32_MLDSA_NTT_ZETAS_CORRECT = prove
 (`rv32_mldsa_ntt_zetas = rv32_mldsa_ntt_generated_zetas`,
  REWRITE_TAC[rv32_mldsa_ntt_zetas;
              rv32_mldsa_ntt_generated_zetas] THEN
  CONV_TAC (ONCE_DEPTH_CONV LIST_OF_SEQ_CONV) THEN
  CONV_TAC (DEPTH_CONV (CHANGED_CONV NUM_REDUCE_CONV)) THEN
  CONV_TAC (ONCE_DEPTH_CONV LIST_OF_SEQ_CONV) THEN
  REWRITE_TAC[ITLIST; rv32_mldsa_ntt_root_triplet] THEN
  CONV_TAC (DEPTH_CONV (CHANGED_CONV NUM_REDUCE_CONV)) THEN
  CONV_TAC (ONCE_DEPTH_CONV RV32_MLDSA_NTT_ROOT_PAIR_CONV) THEN
  REWRITE_TAC[APPEND]);;
