(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

(* ========================================================================= *)
(* Functional correctness of poly_decompose_32:                              *)
(* Decompose polynomial coefficients into (a1, a0) where a = a1*2*GAMMA2+a0 *)
(* for GAMMA2 = (Q-1)/32 = 261888 (ML-DSA-65/87)                            *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;

(**** print_literal_from_elf "aarch64/mldsa/poly_decompose_32_aarch64_asm.o";;
 ****)

let poly_decompose_32_aarch64_asm_mc = define_assert_from_elf "poly_decompose_32_aarch64_asm_mc" "aarch64/mldsa/poly_decompose_32_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0x529c0024;       (* arm_MOV W4 (rvalue (word 57345)) *)
  0x72a00fe4;       (* arm_MOVK W4 (word 127) 16 *)
  0x4e040c94;       (* arm_DUP_GEN Q20 X4 32 128 *)
  0x529c2005;       (* arm_MOV W5 (rvalue (word 57600)) *)
  0x72a00f65;       (* arm_MOVK W5 (word 123) 16 *)
  0x4e040cb5;       (* arm_DUP_GEN Q21 X5 32 128 *)
  0x529fc007;       (* arm_MOV W7 (rvalue (word 65024)) *)
  0x72a000e7;       (* arm_MOVK W7 (word 7) 16 *)
  0x4e040cf6;       (* arm_DUP_GEN Q22 X7 32 128 *)
  0x5280802b;       (* arm_MOV W11 (rvalue (word 1025)) *)
  0x72a8020b;       (* arm_MOVK W11 (word 16400) 16 *)
  0x4e040d77;       (* arm_DUP_GEN Q23 X11 32 128 *)
  0xd2800203;       (* arm_MOV X3 (rvalue (word 16)) *)
  0x3dc00420;       (* arm_LDR Q0 X1 (Immediate_Offset (word 16)) *)
  0x3dc00831;       (* arm_LDR Q17 X1 (Immediate_Offset (word 32)) *)
  0x3dc00c22;       (* arm_LDR Q2 X1 (Immediate_Offset (word 48)) *)
  0x3dc0103a;       (* arm_LDR Q26 X1 (Immediate_Offset (word 64)) *)
  0x3dc00030;       (* arm_LDR Q16 X1 (Immediate_Offset (word 0)) *)
  0x3dc01832;       (* arm_LDR Q18 X1 (Immediate_Offset (word 96)) *)
  0x4eb5363f;       (* arm_CMGT_VEC Q31 Q17 Q21 32 128 *)
  0x4eb7b623;       (* arm_SQDMULH_VEC Q3 Q17 Q23 32 128 *)
  0x4eb53444;       (* arm_CMGT_VEC Q4 Q2 Q21 32 128 *)
  0x4eb53605;       (* arm_CMGT_VEC Q5 Q16 Q21 32 128 *)
  0x4eb7b613;       (* arm_SQDMULH_VEC Q19 Q16 Q23 32 128 *)
  0x4eb7b447;       (* arm_SQDMULH_VEC Q7 Q2 Q23 32 128 *)
  0x4f2e2463;       (* arm_SRSHR_VEC Q3 Q3 18 32 128 *)
  0x4eb7b758;       (* arm_SQDMULH_VEC Q24 Q26 Q23 32 128 *)
  0x4f2e267b;       (* arm_SRSHR_VEC Q27 Q19 18 32 128 *)
  0x6eb69471;       (* arm_MLS_VEC Q17 Q3 Q22 32 128 *)
  0x4f2e24fd;       (* arm_SRSHR_VEC Q29 Q7 18 32 128 *)
  0x4e7f1c66;       (* arm_BIC_VEC Q6 Q3 Q31 128 *)
  0x4e651f61;       (* arm_BIC_VEC Q1 Q27 Q5 128 *)
  0x6eb69770;       (* arm_MLS_VEC Q16 Q27 Q22 32 128 *)
  0x3d800806;       (* arm_STR Q6 X0 (Immediate_Offset (word 32)) *)
  0x3c840401;       (* arm_STR Q1 X0 (Postimmediate_Offset (word 64)) *)
  0x6eb697a2;       (* arm_MLS_VEC Q2 Q29 Q22 32 128 *)
  0x4ebf8626;       (* arm_ADD_VEC Q6 Q17 Q31 32 128 *)
  0x4eb7b643;       (* arm_SQDMULH_VEC Q3 Q18 Q23 32 128 *)
  0x3d800826;       (* arm_STR Q6 X1 (Immediate_Offset (word 32)) *)
  0x4ea58614;       (* arm_ADD_VEC Q20 Q16 Q5 32 128 *)
  0x3c840434;       (* arm_STR Q20 X1 (Postimmediate_Offset (word 64)) *)
  0x4ea48451;       (* arm_ADD_VEC Q17 Q2 Q4 32 128 *)
  0xd1000863;       (* arm_SUB X3 X3 (rvalue (word 2)) *)
  0x4eb53401;       (* arm_CMGT_VEC Q1 Q0 Q21 32 128 *)
  0x3dc00c25;       (* arm_LDR Q5 X1 (Immediate_Offset (word 48)) *)
  0x4eb53646;       (* arm_CMGT_VEC Q6 Q18 Q21 32 128 *)
  0x4eb7b414;       (* arm_SQDMULH_VEC Q20 Q0 Q23 32 128 *)
  0x3c9f0031;       (* arm_STR Q17 X1 (Immediate_Offset (word 18446744073709551600)) *)
  0x4f2e2463;       (* arm_SRSHR_VEC Q3 Q3 18 32 128 *)
  0x4e641fa7;       (* arm_BIC_VEC Q7 Q29 Q4 128 *)
  0x4eb53742;       (* arm_CMGT_VEC Q2 Q26 Q21 32 128 *)
  0x4eb7b4b0;       (* arm_SQDMULH_VEC Q16 Q5 Q23 32 128 *)
  0x4f2e271c;       (* arm_SRSHR_VEC Q28 Q24 18 32 128 *)
  0x3c9f0007;       (* arm_STR Q7 X0 (Immediate_Offset (word 18446744073709551600)) *)
  0x4eb534a4;       (* arm_CMGT_VEC Q4 Q5 Q21 32 128 *)
  0x4f2e269f;       (* arm_SRSHR_VEC Q31 Q20 18 32 128 *)
  0x6eb69472;       (* arm_MLS_VEC Q18 Q3 Q22 32 128 *)
  0x4e661c63;       (* arm_BIC_VEC Q3 Q3 Q6 128 *)
  0x6eb6979a;       (* arm_MLS_VEC Q26 Q28 Q22 32 128 *)
  0x4e621f93;       (* arm_BIC_VEC Q19 Q28 Q2 128 *)
  0x3d800803;       (* arm_STR Q3 X0 (Immediate_Offset (word 32)) *)
  0x4f2e261d;       (* arm_SRSHR_VEC Q29 Q16 18 32 128 *)
  0x3c840413;       (* arm_STR Q19 X0 (Postimmediate_Offset (word 64)) *)
  0x6eb697e0;       (* arm_MLS_VEC Q0 Q31 Q22 32 128 *)
  0x4e611ffe;       (* arm_BIC_VEC Q30 Q31 Q1 128 *)
  0x4ea68643;       (* arm_ADD_VEC Q3 Q18 Q6 32 128 *)
  0x3dc01832;       (* arm_LDR Q18 X1 (Immediate_Offset (word 96)) *)
  0x6eb697a5;       (* arm_MLS_VEC Q5 Q29 Q22 32 128 *)
  0x3c99001e;       (* arm_STR Q30 X0 (Immediate_Offset (word 18446744073709551504)) *)
  0x4ea2875b;       (* arm_ADD_VEC Q27 Q26 Q2 32 128 *)
  0x3dc0103a;       (* arm_LDR Q26 X1 (Immediate_Offset (word 64)) *)
  0x4ea18419;       (* arm_ADD_VEC Q25 Q0 Q1 32 128 *)
  0x3dc00420;       (* arm_LDR Q0 X1 (Immediate_Offset (word 16)) *)
  0x3d800823;       (* arm_STR Q3 X1 (Immediate_Offset (word 32)) *)
  0x4eb7b643;       (* arm_SQDMULH_VEC Q3 Q18 Q23 32 128 *)
  0x3c9d0039;       (* arm_STR Q25 X1 (Immediate_Offset (word 18446744073709551568)) *)
  0x3c84043b;       (* arm_STR Q27 X1 (Postimmediate_Offset (word 64)) *)
  0x4ea484b1;       (* arm_ADD_VEC Q17 Q5 Q4 32 128 *)
  0x4eb7b758;       (* arm_SQDMULH_VEC Q24 Q26 Q23 32 128 *)
  0xf1000463;       (* arm_SUBS X3 X3 (rvalue (word 1)) *)
  0x54fffb61;       (* arm_BNE (word 2097004) *)
  0x3dc00c30;       (* arm_LDR Q16 X1 (Immediate_Offset (word 48)) *)
  0x3dc00425;       (* arm_LDR Q5 X1 (Immediate_Offset (word 16)) *)
  0x4eb7b41c;       (* arm_SQDMULH_VEC Q28 Q0 Q23 32 128 *)
  0x4eb53753;       (* arm_CMGT_VEC Q19 Q26 Q21 32 128 *)
  0x4eb53402;       (* arm_CMGT_VEC Q2 Q0 Q21 32 128 *)
  0x3c9f0031;       (* arm_STR Q17 X1 (Immediate_Offset (word 18446744073709551600)) *)
  0x4f2e247f;       (* arm_SRSHR_VEC Q31 Q3 18 32 128 *)
  0x4eb7b4a1;       (* arm_SQDMULH_VEC Q1 Q5 Q23 32 128 *)
  0x4eb53606;       (* arm_CMGT_VEC Q6 Q16 Q21 32 128 *)
  0x4f2e2718;       (* arm_SRSHR_VEC Q24 Q24 18 32 128 *)
  0x4f2e2799;       (* arm_SRSHR_VEC Q25 Q28 18 32 128 *)
  0x4eb7b614;       (* arm_SQDMULH_VEC Q20 Q16 Q23 32 128 *)
  0x4eb53651;       (* arm_CMGT_VEC Q17 Q18 Q21 32 128 *)
  0x6eb697f2;       (* arm_MLS_VEC Q18 Q31 Q22 32 128 *)
  0x4eb534bb;       (* arm_CMGT_VEC Q27 Q5 Q21 32 128 *)
  0x4f2e243e;       (* arm_SRSHR_VEC Q30 Q1 18 32 128 *)
  0x6eb69720;       (* arm_MLS_VEC Q0 Q25 Q22 32 128 *)
  0x4e621f3c;       (* arm_BIC_VEC Q28 Q25 Q2 128 *)
  0x4f2e2687;       (* arm_SRSHR_VEC Q7 Q20 18 32 128 *)
  0x4e731f19;       (* arm_BIC_VEC Q25 Q24 Q19 128 *)
  0x6eb6971a;       (* arm_MLS_VEC Q26 Q24 Q22 32 128 *)
  0x4e7b1fd4;       (* arm_BIC_VEC Q20 Q30 Q27 128 *)
  0x3c9d001c;       (* arm_STR Q28 X0 (Immediate_Offset (word 18446744073709551568)) *)
  0x4eb18643;       (* arm_ADD_VEC Q3 Q18 Q17 32 128 *)
  0x6eb697c5;       (* arm_MLS_VEC Q5 Q30 Q22 32 128 *)
  0x3d800414;       (* arm_STR Q20 X0 (Immediate_Offset (word 16)) *)
  0x4e661cfc;       (* arm_BIC_VEC Q28 Q7 Q6 128 *)
  0x6eb694f0;       (* arm_MLS_VEC Q16 Q7 Q22 32 128 *)
  0x3d800823;       (* arm_STR Q3 X1 (Immediate_Offset (word 32)) *)
  0x3d800c1c;       (* arm_STR Q28 X0 (Immediate_Offset (word 48)) *)
  0x4ea28403;       (* arm_ADD_VEC Q3 Q0 Q2 32 128 *)
  0x4e641fa7;       (* arm_BIC_VEC Q7 Q29 Q4 128 *)
  0x3c840419;       (* arm_STR Q25 X0 (Postimmediate_Offset (word 64)) *)
  0x3c9d0023;       (* arm_STR Q3 X1 (Immediate_Offset (word 18446744073709551568)) *)
  0x4ebb84b8;       (* arm_ADD_VEC Q24 Q5 Q27 32 128 *)
  0x3c9b0007;       (* arm_STR Q7 X0 (Immediate_Offset (word 18446744073709551536)) *)
  0x4eb38753;       (* arm_ADD_VEC Q19 Q26 Q19 32 128 *)
  0x4ea68619;       (* arm_ADD_VEC Q25 Q16 Q6 32 128 *)
  0x4e711fe6;       (* arm_BIC_VEC Q6 Q31 Q17 128 *)
  0x3d800438;       (* arm_STR Q24 X1 (Immediate_Offset (word 16)) *)
  0x3c840433;       (* arm_STR Q19 X1 (Postimmediate_Offset (word 64)) *)
  0x3c9e0006;       (* arm_STR Q6 X0 (Immediate_Offset (word 18446744073709551584)) *)
  0x3c9f0039;       (* arm_STR Q25 X1 (Immediate_Offset (word 18446744073709551600)) *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let POLY_DECOMPOSE_32_AARCH64_ASM_EXEC = ARM_MK_EXEC_RULE poly_decompose_32_aarch64_asm_mc;;

(* ========================================================================= *)
(* Constants                                                                 *)
(* ========================================================================= *)

let LENGTH_POLY_DECOMPOSE_32_AARCH64_ASM_MC =
  REWRITE_CONV[poly_decompose_32_aarch64_asm_mc] `LENGTH poly_decompose_32_aarch64_asm_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let POLY_DECOMPOSE_32_AARCH64_ASM_CORE_START = new_definition
  `POLY_DECOMPOSE_32_AARCH64_ASM_CORE_START = 0`;;

let POLY_DECOMPOSE_32_AARCH64_ASM_POSTAMBLE_LENGTH = new_definition
  `POLY_DECOMPOSE_32_AARCH64_ASM_POSTAMBLE_LENGTH = 4`;;

let POLY_DECOMPOSE_32_AARCH64_ASM_CORE_END = new_definition
  `POLY_DECOMPOSE_32_AARCH64_ASM_CORE_END =
     LENGTH poly_decompose_32_aarch64_asm_mc - POLY_DECOMPOSE_32_AARCH64_ASM_POSTAMBLE_LENGTH`;;

let LENGTH_SIMPLIFY_CONV =
  REWRITE_CONV[LENGTH_POLY_DECOMPOSE_32_AARCH64_ASM_MC;
              POLY_DECOMPOSE_32_AARCH64_ASM_CORE_START; POLY_DECOMPOSE_32_AARCH64_ASM_CORE_END;
              POLY_DECOMPOSE_32_AARCH64_ASM_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV [ADD_0];;

(* ========================================================================= *)
(* Word-level helper functions                                               *)
(* Per-lane operations matching the assembly's SQDMULH+SRSHR, BIC, MLS+ADD  *)
(* ========================================================================= *)

(* h32: quotient = srshr(sqdmulh(x, magic), 18) ≈ round(x / 523776) *)
let h32 = define
  `h32 (x:int32) : int32 =
   iword((ival((iword_saturate:int->int32)
     ((&2 * ival x * &1074791425) div &4294967296)) +
     &131072) div &262144)`;;

(* decompose32_a1: a1 = h AND (NOT mask) where mask = -1 if x > threshold *)
let decompose32_a1 = define
  `decompose32_a1 (x:int32) : int32 =
   word_and (h32 x)
     (word_not(word_neg(word(bitval(ival x > &8118528)))))`;;

(* decompose32_a0: a0 = (x - h*2*GAMMA2) + mask *)
let decompose32_a0 = define
  `decompose32_a0 (x:int32) : int32 =
   word_add (word_sub x (word_mul (h32 x) (word 523776)))
     (word_neg(word(bitval(ival x > &8118528))))`;;

(* ========================================================================= *)
(* Distribution lemmas for word_and/word_not over word_join                  *)
(* Needed because BIC (arm_BIC_VEC) operates at 128-bit level               *)
(* ========================================================================= *)

let WORD_AND_JOIN_64 = WORD_BLAST
  `!a b c d : int32.
   word_and ((word_join:int32->int32->int64) a b)
            ((word_join:int32->int32->int64) c d) =
   word_join (word_and a c) (word_and b d)`;;

let WORD_AND_JOIN_128 = WORD_BLAST
  `!a b c d : int64.
   word_and ((word_join:int64->int64->int128) a b)
            ((word_join:int64->int64->int128) c d) =
   word_join (word_and a c) (word_and b d)`;;

let WORD_NOT_JOIN_64 = WORD_BLAST
  `!a b : int32.
   word_not ((word_join:int32->int32->int64) a b) =
   word_join (word_not a) (word_not b)`;;

let WORD_NOT_JOIN_128 = WORD_BLAST
  `!a b : int64.
   word_not ((word_join:int64->int64->int128) a b) =
   word_join (word_not a) (word_not b)`;;

(* ========================================================================= *)
(* Mathematical correctness lemmas                                           *)
(* Connect word-level decompose32_a1/a0 to spec-level mldsa_decompose_32           *)
(* ========================================================================= *)

(* Case split: a1 is either h32 or 0 depending on the threshold *)
let DECOMPOSE32_A1_CASES = prove(
  `!x:int32. decompose32_a1 x =
     if ival x > &8118528 then word 0 else h32 x`,
  REWRITE_TAC[decompose32_a1] THEN BITBLAST_TAC);;

(* Case split: a0 subtracts 1 in the special case *)
let DECOMPOSE32_A0_CASES = prove(
  `!x:int32. decompose32_a0 x =
     if ival x > &8118528
     then word_sub (word_sub x (word_mul (h32 x) (word 523776))) (word 1)
     else word_sub x (word_mul (h32 x) (word 523776))`,
  GEN_TAC THEN REWRITE_TAC[decompose32_a0] THEN
  COND_CASES_TAC THEN
  REWRITE_TAC[bitval] THEN CONV_TAC WORD_RULE);;

(* ival equals val for values in the positive int32 range *)
let IVAL_EQ_VAL = prove(
  `!x:int32. val x < 2 EXP 31 ==> ival x = &(val x)`,
  GEN_TAC THEN REWRITE_TAC[IVAL_VAL; DIMINDEX_32] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_EXP_CONV) THEN
  DISCH_TAC THEN
  SUBGOAL_THEN `bit (32 - 1) (x:int32) = F` ASSUME_TAC THENL [
    REWRITE_TAC[BIT_VAL; DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
    ASM_ARITH_TAC;
    ASM_REWRITE_TAC[bitval] THEN INT_ARITH_TAC]);;

(* ========================================================================= *)
(* Barrett reduction correctness for h32                                     *)
(* Shows that SQDMULH+SRSHR computes round(x / 523776) correctly            *)
(* ========================================================================= *)

(* Algebraic expansion: n*K + q*E = q*D*P + r*K
   where K=2149582850, M=523776, D=262144, P=4294967296, E=1024 *)
let BARRETT32_EXPAND = prove(
  `!n. n * 2149582850 + (n DIV 523776) * 1024 =
       (n DIV 523776) * 262144 * 4294967296 + (n MOD 523776) * 2149582850`,
  GEN_TAC THEN
  MP_TAC(SPECL [`n:num`; `523776`] DIVISION) THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(CONJUNCTS_THEN2 (fun th -> GEN_REWRITE_TAC (LAND_CONV o LAND_CONV o LAND_CONV) [th]) ASSUME_TAC) THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC NUM_RING);;

(* DIV_BOUNDS_EQ: if q*d <= b < (q+1)*d then b DIV d = q *)
let DIV_BOUNDS_EQ = prove(
  `!b d q. ~(d = 0) /\ q * d <= b /\ b < (q + 1) * d ==> b DIV d = q`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC(ARITH_RULE `q <= r /\ r < q + 1 ==> r = q`) THEN
  CONJ_TAC THENL [
    ASM_SIMP_TAC[LE_RDIV_EQ] THEN ASM_ARITH_TAC;
    ASM_SIMP_TAC[RDIV_LT_EQ] THEN ASM_ARITH_TAC]);;

(* Barrett reduction: (n*K) DIV P with rounding = round(n / M) *)
let BARRETT32_CORRECT = prove(
  `!n. n < 8380417 ==>
    ((n * 2149582850) DIV 4294967296 + 131072) DIV 262144 =
    (if n MOD 523776 * 2 <= 523776
     then n DIV 523776
     else n DIV 523776 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN
  ASM_CASES_TAC `n = 8380416` THENL [
    ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  ABBREV_TAC `q = n DIV 523776` THEN
  ABBREV_TAC `r = n MOD 523776` THEN
  SUBGOAL_THEN `n = q * 523776 + r` ASSUME_TAC THENL [
    EXPAND_TAC "q" THEN EXPAND_TAC "r" THEN
    MESON_TAC[DIVISION; ARITH_RULE `~(523776 = 0)`]; ALL_TAC] THEN
  SUBGOAL_THEN `r < 523776` ASSUME_TAC THENL [
    EXPAND_TAC "r" THEN SIMP_TAC[MOD_LT_EQ] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `q <= 15` ASSUME_TAC THENL [
    EXPAND_TAC "q" THEN ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(523776 = 0)`] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(SPEC `n:num` BARRETT32_EXPAND) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
  COND_CASES_TAC THENL [
    (* Round-down case: r * 2 <= 523776, so r <= 261888 *)
    ABBREV_TAC `d = ((q * 523776 + r) * 2149582850) DIV 4294967296` THEN
    MP_TAC(SPECL [`(q * 523776 + r) * 2149582850`; `4294967296`] DIVISION) THEN
    ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
    SUBGOAL_THEN `d * 4294967296 + q * 1024 <= q * 262144 * 4294967296 + r * 2149582850` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `q * 262144 * 4294967296 + r * 2149582850 < (d + 1) * 4294967296 + q * 1024` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `r * 2149582850 <= 261888 * 2149582850` ASSUME_TAC THENL [
      MATCH_MP_TAC LE_MULT2 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    MATCH_MP_TAC DIV_BOUNDS_EQ THEN CONV_TAC NUM_REDUCE_CONV THEN CONJ_TAC THENL [
      MP_TAC(ARITH_RULE `261888 * 2149582850 < 131072 * 4294967296`) THEN ASM_ARITH_TAC;
      MP_TAC(ARITH_RULE `261888 * 2149582850 < 131072 * 4294967296`) THEN ASM_ARITH_TAC];
    (* Round-up case: ~(r * 2 <= 523776), so r >= 261889 *)
    ABBREV_TAC `d = ((q * 523776 + r) * 2149582850) DIV 4294967296` THEN
    MP_TAC(SPECL [`(q * 523776 + r) * 2149582850`; `4294967296`] DIVISION) THEN
    ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
    SUBGOAL_THEN `d * 4294967296 + q * 1024 <= q * 262144 * 4294967296 + r * 2149582850` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `q * 262144 * 4294967296 + r * 2149582850 < (d + 1) * 4294967296 + q * 1024` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `261889 * 2149582850 <= r * 2149582850` ASSUME_TAC THENL [
      MATCH_MP_TAC LE_MULT2 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `r * 2149582850 < 523776 * 2149582850` ASSUME_TAC THENL [
      REWRITE_TAC[LT_MULT_RCANCEL] THEN ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `q * 1024 <= 15 * 1024` ASSUME_TAC THENL [
      MATCH_MP_TAC LE_MULT2 THEN ASM_ARITH_TAC; ALL_TAC] THEN
    MATCH_MP_TAC DIV_BOUNDS_EQ THEN CONV_TAC NUM_REDUCE_CONV THEN CONJ_TAC THENL [
      MP_TAC(ARITH_RULE `131072 * 4294967296 + 15 * 1024 <= 261889 * 2149582850`) THEN
      ASM_ARITH_TAC;
      MP_TAC(ARITH_RULE `523776 * 2149582850 < 262144 * 4294967296`) THEN
      ASM_ARITH_TAC]]);;

(* ========================================================================= *)
(* Word-level to natural number connection for h32                           *)
(* ========================================================================= *)

(* h32 computes the correct rounding quotient: round(val x / 523776)
   Eliminates iword_saturate by inlining its definition and using BOUNDER_TAC
   to discharge the impossible saturation cases (consistent with mlkem-native). *)
let H32_CORRECT = prove(
  `!x:int32. val x < 8380417 ==>
    val(h32 x) = (if val x MOD 523776 * 2 <= 523776
                  then val x DIV 523776
                  else val x DIV 523776 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[h32; iword_saturate; word_INT_MIN; word_INT_MAX; DIMINDEX_32] THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
  REPEAT(COND_CASES_TAC THENL
   [FIRST_X_ASSUM(MATCH_MP_TAC o MATCH_MP (MESON[] `p ==> ~p ==> q`)) THEN
    REWRITE_TAC[INT_GT; INT_NOT_LT] THEN BOUNDER_TAC[];
    ASM_REWRITE_TAC[]]) THEN
  MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
  ASM_REWRITE_TAC[INT_OF_NUM_MUL] THEN
  SUBGOAL_THEN `2 * val(x:int32) * 1074791425 = val x * 2149582850` SUBST1_TAC THENL [
    ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[INT_OF_NUM_DIV] THEN
  SUBGOAL_THEN `(val(x:int32) * 2149582850) DIV 4294967296 < 2147483648` ASSUME_TAC THENL [
    ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(4294967296 = 0)`] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `ival(iword(&((val(x:int32) * 2149582850) DIV 4294967296)):int32) =
    &((val x * 2149582850) DIV 4294967296)` SUBST1_TAC THENL [
    MATCH_MP_TAC IVAL_IWORD THEN REWRITE_TAC[DIMINDEX_32] THEN
    CONV_TAC(ONCE_DEPTH_CONV NUM_EXP_CONV) THEN
    REWRITE_TAC[INT_OF_NUM_LT; INT_LE_NEG2; INT_OF_NUM_LE] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[INT_OF_NUM_ADD; INT_OF_NUM_DIV] THEN
  SUBGOAL_THEN `((val(x:int32) * 2149582850) DIV 4294967296 + 131072) DIV 262144 < 2147483648` ASSUME_TAC THENL [
    ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(262144 = 0)`] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[GSYM WORD_IWORD; VAL_WORD; DIMINDEX_32] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_EXP_CONV) THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `n < 2147483648 ==> n < 4294967296`] THEN
  MATCH_MP_TAC BARRETT32_CORRECT THEN ASM_REWRITE_TAC[]);;

(* Special case: rounding quotient = 16 when val x > 8118528 *)
let ROUND32_SPECIAL = prove(
  `!n. 8118528 < n /\ n < 8380417 ==>
    (if n MOD 523776 * 2 <= 523776 then n DIV 523776 else n DIV 523776 + 1) = 16`,
  REPEAT STRIP_TAC THEN
  ASM_CASES_TAC `n < 8380416` THENL [
    SUBGOAL_THEN `n DIV 523776 = 15` ASSUME_TAC THENL [
      MATCH_MP_TAC DIV_BOUNDS_EQ THEN CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC;
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
    COND_CASES_TAC THENL [
      MP_TAC(SPECL [`n:num`; `523776`] DIVISION) THEN
      ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
      STRIP_TAC THEN ASM_ARITH_TAC;
      REWRITE_TAC[]];
    SUBGOAL_THEN `n = 8380416` SUBST_ALL_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    CONV_TAC NUM_REDUCE_CONV]);;

(* ========================================================================= *)
(* Main correctness lemmas: connect word-level to spec-level                 *)
(* ========================================================================= *)

(* decompose32_a1 computes FST(mldsa_decompose_32(val x)) *)
let DECOMPOSE32_A1_CORRECT = prove(
  `!x:int32. val x < 8380417
    ==> val(decompose32_a1 x) = FST(mldsa_decompose_32(val x))`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[DECOMPOSE32_A1_CASES; MLDSA_DECOMPOSE_32_EXPAND; LET_DEF; LET_END_DEF; FST] THEN
  COND_CASES_TAC THENL [
    (* ival x > &8118528: a1 = word 0, h = 16, FST = 0 *)
    REWRITE_TAC[VAL_WORD_0; FST] THEN
    SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    SUBGOAL_THEN `&(val(x:int32)):int > &8118528` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
    REWRITE_TAC[INT_OF_NUM_GT; GT] THEN DISCH_TAC THEN
    MP_TAC(SPEC `val(x:int32)` ROUND32_SPECIAL) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[FST];
    (* ~(ival x > &8118528): a1 = h32 x, h < 16 *)
    MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    COND_CASES_TAC THENL [
      (* Round-down case *)
      SUBGOAL_THEN `val(x:int32) <= 8118528` ASSUME_TAC THENL [
        SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
        SUBGOAL_THEN `~(&(val(x:int32)):int > &8118528)` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[INT_GT; INT_NOT_LT; INT_OF_NUM_LE]; ALL_TAC] THEN
      SUBGOAL_THEN `~(val(x:int32) DIV 523776 = 16)` ASSUME_TAC THENL [
        DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `523776`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
        STRIP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[FST];
      (* Round-up case *)
      SUBGOAL_THEN `val(x:int32) <= 8118528` ASSUME_TAC THENL [
        SUBGOAL_THEN `val(x:int32) < 2 EXP 31` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPEC `x:int32` IVAL_EQ_VAL) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
        SUBGOAL_THEN `~(&(val(x:int32)):int > &8118528)` MP_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[INT_GT; INT_NOT_LT; INT_OF_NUM_LE]; ALL_TAC] THEN
      SUBGOAL_THEN `~(val(x:int32) DIV 523776 + 1 = 16)` ASSUME_TAC THENL [
        REWRITE_TAC[ARITH_RULE `n + 1 = 16 <=> n = 15`] THEN DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `523776`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
        STRIP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[FST]]]);;

(* mldsa_cmod n 523776 is bounded by [-261888, 261888], well within int32 range *)
let CMOD_ABS_BOUND_523776 = prove(
  `!n. abs(mldsa_cmod n 523776) <= &261888`,
  GEN_TAC THEN REWRITE_TAC[mldsa_cmod] THEN
  SUBGOAL_THEN `n MOD 523776 < 523776` MP_TAC THENL [
    SIMP_TAC[MOD_LT_EQ; ARITH_RULE `~(523776 = 0)`]; ALL_TAC] THEN
  SPEC_TAC(`n MOD 523776`, `m:num`) THEN GEN_TAC THEN DISCH_TAC THEN
  COND_CASES_TAC THEN
  REWRITE_TAC[INT_ABS; INT_POS; INT_OF_NUM_LE;
              INT_OF_NUM_SUB; INT_SUB_LE; INT_NEG_SUB] THEN
  ASM_ARITH_TAC);;

(* decompose32_a0 computes SND(mldsa_decompose_32(val x)) *)
let DECOMPOSE32_A0_CORRECT = prove(
  `!x:int32. val x < 8380417
    ==> ival(decompose32_a0 x) = SND(mldsa_decompose_32(val x))`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[DECOMPOSE32_A0_CASES; MLDSA_DECOMPOSE_32_EXPAND; LET_DEF; LET_END_DEF; SND] THEN
  (* Express word_sub x (word_mul (h32 x) (word 523776)) as iword(...) *)
  SUBGOAL_THEN `word_sub x (word_mul (h32 x) (word 523776)) : int32 =
    iword(ival x - ival(h32 x) * &523776)` SUBST1_TAC THENL [
    CONV_TAC WORD_RULE; ALL_TAC] THEN
  (* Convert ival x and ival(h32 x) to val-based expressions *)
  SUBGOAL_THEN `ival(x:int32) = &(val x)` SUBST1_TAC THENL [
    MATCH_MP_TAC IVAL_EQ_VAL THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `ival(h32 x:int32) = &(val(h32 x))` SUBST1_TAC THENL [
    MATCH_MP_TAC IVAL_EQ_VAL THEN
    MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `~(523776 = 0)`] THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  (* Substitute h32 value using H32_CORRECT *)
  MP_TAC(SPEC `x:int32` H32_CORRECT) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[INT_OF_NUM_GT] THEN
  ABBREV_TAC `h = (if val(x:int32) MOD 523776 * 2 <= 523776
    then val x DIV 523776 else val x DIV 523776 + 1)` THEN
  (* Establish DIVISION identity in int form *)
  SUBGOAL_THEN `&(val(x:int32)):int =
    &(val x DIV 523776) * &523776 + &(val x MOD 523776)` ASSUME_TAC THENL [
    MP_TAC(SPECL [`val(x:int32)`; `523776`] DIVISION) THEN
    ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(MP_TAC o AP_TERM `int_of_num` o CONJUNCT1) THEN
    REWRITE_TAC[INT_OF_NUM_MUL; INT_OF_NUM_ADD]; ALL_TAC] THEN
  (* Prove key identity: val x - h * 523776 = mldsa_cmod(val x) 523776 *)
  SUBGOAL_THEN `&(val(x:int32)) - &h * &523776 = mldsa_cmod (val x) 523776`
    ASSUME_TAC THENL [
    REWRITE_TAC[mldsa_cmod] THEN
    FIRST_X_ASSUM(MP_TAC o SYM o check (fun th ->
      fst(dest_cond(fst(dest_eq(concl th)))) =
        `val (x:int32) MOD 523776 * 2 <= 523776`)) THEN
    COND_CASES_TAC THENL [
      DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[] THEN INT_ARITH_TAC;
      DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[GSYM INT_OF_NUM_ADD;
        GSYM INT_OF_NUM_MUL] THEN INT_ARITH_TAC]; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  (* Case split on val x > 8118528 *)
  COND_CASES_TAC THENL [
    (* Special case: val x > 8118528, h = 16 *)
    SUBGOAL_THEN `h = 16` SUBST1_TAC THENL [
      MP_TAC(SPEC `val(x:int32)` ROUND32_SPECIAL) THEN
      ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN ASM_MESON_TAC[];
      ALL_TAC] THEN
    REWRITE_TAC[SND] THEN
    SUBGOAL_THEN `word_sub (iword(mldsa_cmod (val(x:int32)) 523776)) (word 1) : int32 =
      iword(mldsa_cmod (val x) 523776 - &1)` SUBST1_TAC THENL [
      REWRITE_TAC[GSYM IWORD_INT_SUB; WORD_IWORD]; ALL_TAC] THEN
    MATCH_MP_TAC(INST_TYPE [`:32`,`:N`] IVAL_IWORD) THEN
    REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(SPEC `val(x:int32)` CMOD_ABS_BOUND_523776) THEN INT_ARITH_TAC;
    (* Normal case: ~(val x > 8118528), h != 16 *)
    SUBGOAL_THEN `~(h = 16)` ASSUME_TAC THENL [
      DISCH_TAC THEN
      SUBGOAL_THEN `val(x:int32) <= 8118528` ASSUME_TAC THENL [
        ASM_ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `(if val(x:int32) MOD 523776 * 2 <= 523776
        then val x DIV 523776 else val x DIV 523776 + 1) = 16` MP_TAC THENL [
        ASM_MESON_TAC[]; ALL_TAC] THEN
      COND_CASES_TAC THENL [
        DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `523776`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
        STRIP_TAC THEN ASM_ARITH_TAC;
        REWRITE_TAC[ARITH_RULE `n + 1 = 16 <=> n = 15`] THEN DISCH_TAC THEN
        MP_TAC(SPECL [`val(x:int32)`; `523776`] DIVISION) THEN
        ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
        STRIP_TAC THEN ASM_ARITH_TAC]; ALL_TAC] THEN
    ASM_REWRITE_TAC[SND] THEN
    MATCH_MP_TAC(INST_TYPE [`:32`,`:N`] IVAL_IWORD) THEN
    REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(SPEC `val(x:int32)` CMOD_ABS_BOUND_523776) THEN INT_ARITH_TAC]);;

(* ========================================================================= *)
(* Specification                                                             *)
(* ========================================================================= *)

let POLY_DECOMPOSE_32_AARCH64_ASM_CORRECT = prove(
 `!pc a r1 x.
    nonoverlapping (word pc, LENGTH poly_decompose_32_aarch64_asm_mc)
                   (r1, 1024) /\
    nonoverlapping (word pc, LENGTH poly_decompose_32_aarch64_asm_mc)
                   (a, 1024) /\
    nonoverlapping (r1, 1024) (a, 1024)
    ==> ensures arm
         (\s. aligned_bytes_loaded s (word pc) poly_decompose_32_aarch64_asm_mc /\
              read PC s = word(pc + POLY_DECOMPOSE_32_AARCH64_ASM_CORE_START) /\
              C_ARGUMENTS [r1; a] s /\
              (!i. i < 256
                   ==> read(memory :> bytes32(word_add a (word(4 * i)))) s =
                       x i))
         (\s. read PC s = word(pc + POLY_DECOMPOSE_32_AARCH64_ASM_CORE_END) /\
              ((!i. i < 256 ==> val(x i:int32) < 8380417)
               ==> (!i. i < 256
                        ==> val(read(memory :> bytes32
                          (word_add r1 (word(4 * i)))) s) =
                            FST(mldsa_decompose_32(val(x i)))) /\
                   (!i. i < 256
                        ==> ival(read(memory :> bytes32
                          (word_add a (word(4 * i)))) s) =
                            SND(mldsa_decompose_32(val(x i))))))
         (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
          MAYCHANGE [memory :> bytes(r1, 1024)] ,,
          MAYCHANGE [memory :> bytes(a, 1024)])`,

  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  MAP_EVERY X_GEN_TAC [`pc:num`; `a:int64`; `r1:int64`; `x:num->int32`] THEN
  REWRITE_TAC[NONOVERLAPPING_CLAUSES; C_ARGUMENTS; SOME_FLAGS;
              fst POLY_DECOMPOSE_32_AARCH64_ASM_EXEC;
              MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN
  STRIP_TAC THEN

  (* Expand the quantified input condition to individual coefficients *)
  CONV_TAC(RATOR_CONV(LAND_CONV(ONCE_DEPTH_CONV
    (EXPAND_CASES_CONV THENC ONCE_DEPTH_CONV NUM_MULT_CONV)))) THEN

  ENSURES_INIT_TAC "s0" THEN

  (* Merge 4x32-bit coefficient reads into 128-bit vector reads *)
  MP_TAC(end_itlist CONJ (map (fun n -> READ_MEMORY_MERGE_CONV 2
            (subst[mk_small_numeral(16*n),`n:num`]
                  `read (memory :> bytes128(word_add a (word n))) s0`))
            (0--63))) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 a) s = x`] THEN
  STRIP_TAC THEN

  RULE_ASSUM_TAC(REWRITE_RULE[ADD_CLAUSES]) THEN

  (* Symbolic execution with folding to decompose32_a1/a0 *)
  MAP_UNTIL_TARGET_PC (fun n ->
    ARM_STEPS_TAC POLY_DECOMPOSE_32_AARCH64_ASM_EXEC [n] THEN
    RULE_ASSUM_TAC(CONV_RULE(
      TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV THENC
      ONCE_REWRITE_CONV [GSYM h32] THENC
      REWRITE_CONV [WORD_NOT_JOIN_128; WORD_NOT_JOIN_64;
                    WORD_AND_JOIN_128; WORD_AND_JOIN_64] THENC
      ONCE_REWRITE_CONV [WORD_IGT] THENC
      DEPTH_CONV WORD_IVAL_CONV THENC
      ONCE_REWRITE_CONV [GSYM decompose32_a1] THENC
      ONCE_REWRITE_CONV [GSYM decompose32_a0]))) 1 THEN

  (* Establish postcondition *)
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN

  (* Discharge bound premise from postcondition *)
  DISCH_TAC THEN

  (* Split bytes128 results back into bytes32 *)
  REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
    CONV_RULE(READ_MEMORY_SPLIT_CONV 2) o
    check (can (term_match [] `read qqq s:int128 = xxx`) o concl))) THEN

  RULE_ASSUM_TAC(CONV_RULE(RAND_CONV(
    TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV))) THEN

  CONV_TAC(ONCE_DEPTH_CONV EXPAND_CASES_CONV THENC
    ONCE_DEPTH_CONV NUM_MULT_CONV) THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN

  (* Apply mathematical correctness lemmas *)
  REPEAT CONJ_TAC THEN
  (MATCH_MP_TAC DECOMPOSE32_A1_CORRECT ORELSE
   MATCH_MP_TAC DECOMPOSE32_A0_CORRECT) THEN
  FIRST_ASSUM MATCH_MP_TAC THEN
  CONV_TAC NUM_REDUCE_CONV);;

(* ========================================================================= *)
(* Subroutine form: wraps CORRECT with RET handling                         *)
(* ========================================================================= *)

let POLY_DECOMPOSE_32_AARCH64_ASM_SUBROUTINE_CORRECT = prove(
 `!pc a r1 x returnaddress.
    nonoverlapping (word pc, LENGTH poly_decompose_32_aarch64_asm_mc)
                   (r1, 1024) /\
    nonoverlapping (word pc, LENGTH poly_decompose_32_aarch64_asm_mc)
                   (a, 1024) /\
    nonoverlapping (r1, 1024) (a, 1024)
    ==> ensures arm
         (\s. aligned_bytes_loaded s (word pc) poly_decompose_32_aarch64_asm_mc /\
              read PC s = word pc /\
              read X30 s = returnaddress /\
              C_ARGUMENTS [r1; a] s /\
              (!i. i < 256
                   ==> read(memory :> bytes32(word_add a (word(4 * i)))) s =
                       x i))
         (\s. read PC s = returnaddress /\
              ((!i. i < 256 ==> val(x i:int32) < 8380417)
               ==> (!i. i < 256
                        ==> val(read(memory :> bytes32
                          (word_add r1 (word(4 * i)))) s) =
                            FST(mldsa_decompose_32(val(x i)))) /\
                   (!i. i < 256
                        ==> ival(read(memory :> bytes32
                          (word_add a (word(4 * i)))) s) =
                            SND(mldsa_decompose_32(val(x i)))) /\
                   (!i. i < 256
                        ==> val(read(memory :> bytes32
                          (word_add r1 (word(4 * i)))) s) <= 15) /\
                   (!i. i < 256
                        ==> --(&261888) <=
                            ival(read(memory :> bytes32
                              (word_add a (word(4 * i)))) s) /\
                            ival(read(memory :> bytes32
                              (word_add a (word(4 * i)))) s) <= &261888)))
         (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
          MAYCHANGE [memory :> bytes(r1, 1024)] ,,
          MAYCHANGE [memory :> bytes(a, 1024)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  REWRITE_TAC[NONOVERLAPPING_CLAUSES; C_ARGUMENTS; SOME_FLAGS;
              fst POLY_DECOMPOSE_32_AARCH64_ASM_EXEC;
              MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN
  REPEAT STRIP_TAC THEN
  REWRITE_TAC(!simulation_precanon_thms) THEN
  ENSURES_INIT_TAC "s0" THEN
  MP_TAC(REWRITE_RULE[NONOVERLAPPING_CLAUSES; C_ARGUMENTS; SOME_FLAGS;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI]
   (SPECL [`pc:num`; `a:int64`; `r1:int64`; `x:num->int32`]
    (CONV_RULE LENGTH_SIMPLIFY_CONV POLY_DECOMPOSE_32_AARCH64_ASM_CORRECT))) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
  ARM_BIGSTEP_TAC POLY_DECOMPOSE_32_AARCH64_ASM_EXEC "s1" THEN
  ARM_STEPS_TAC POLY_DECOMPOSE_32_AARCH64_ASM_EXEC [2] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  DISCH_TAC THEN
  FIRST_X_ASSUM(ASSUME_TAC o C MATCH_MP
    (ASSUME `!i. i < 256 ==> val((x:num->int32) i) < 8380417`)) THEN
  ASM_REWRITE_TAC[] THEN
  CONJ_TAC THENL [
    REPEAT STRIP_TAC THEN ASM_SIMP_TAC[] THEN
    MATCH_MP_TAC MLDSA_DECOMPOSE_32_A1_BOUND THEN
    FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_REWRITE_TAC[];
    GEN_TAC THEN DISCH_TAC THEN ASM_SIMP_TAC[] THEN
    MATCH_MP_TAC MLDSA_DECOMPOSE_32_A0_BOUND THEN
    FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_REWRITE_TAC[]]);;

(* ========================================================================= *)
(* Constant-time and memory safety proof.                                    *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/consttime.ml";;
needs "mldsa_native/aarch64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    (assoc "poly_decompose_32_aarch64_asm" subroutine_signatures)
    POLY_DECOMPOSE_32_AARCH64_ASM_SUBROUTINE_CORRECT
    POLY_DECOMPOSE_32_AARCH64_ASM_EXEC;;

let POLY_DECOMPOSE_32_AARCH64_ASM_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e pc a r1 returnaddress.
           nonoverlapping (word pc,LENGTH poly_decompose_32_aarch64_asm_mc) (r1,1024) /\
           nonoverlapping (word pc,LENGTH poly_decompose_32_aarch64_asm_mc) (a,1024) /\
           nonoverlapping (r1,1024) (a,1024)
           ==> ensures arm
               (\s.
                    aligned_bytes_loaded s (word pc)
                    poly_decompose_32_aarch64_asm_mc /\
                    read PC s = word pc /\
                    read X30 s = returnaddress /\
                    C_ARGUMENTS [r1; a] s /\
                    read events s = e)
               (\s.
                    read PC s = returnaddress /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events r1 a pc returnaddress /\
                         memaccess_inbounds e2 [a,1024; r1,1024]
                         [r1,1024; a,1024]))
               (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars POLY_DECOMPOSE_32_AARCH64_ASM_EXEC);;
