(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* UseHint for GAMMA2 = (q-1)/88.                                           *)
(* ========================================================================= *)

(* This file proves that the RV32 routine replaces each coefficient r of a
   by UseHint(h, r) for the corresponding hint h.
   `MLDSA_POLY_USE_HINT_88_SUBROUTINE_CORRECT` states this for a call of the
   routine, and `MLDSA_POLY_USE_HINT_88_SUBROUTINE_SAFE` proves that the
   call accesses only a and h and that its trace does not depend on the
   coefficients or the hints. *)

needs "s2n_bignum/riscv/proofs/base.ml";;

(**** print_literal_from_elf
 "riscv32/mldsa/mldsa_poly_use_hint_88_rv32im_asm.o";;
 ****)

let mldsa_poly_use_hint_88_mc = define_assert_from_elf
  "mldsa_poly_use_hint_88_mc"
  "riscv32/mldsa/mldsa_poly_use_hint_88_rv32im_asm.o"
(*** BYTECODE START ***)
[
  0x000032b7;       (* riscv_LUI T0 (word 12288) *)
  0xc0b28293;       (* riscv_ADDI T0 T0 (word 4294966283) *)
  0x00800337;       (* riscv_LUI T1 (word 8388608) *)
  0x0002f3b7;       (* riscv_LUI T2 (word 192512) *)
  0x80038393;       (* riscv_ADDI T2 T2 (word 4294965248) *)
  0x003ffe37;       (* riscv_LUI T3 (word 4190208) *)
  0x40050613;       (* riscv_ADDI A2 A0 (word 1024) *)
  0x00052683;       (* riscv_LW A3 A0 (word 0) *)
  0x0005a703;       (* riscv_LW A4 A1 (word 0) *)
  0x00452783;       (* riscv_LW A5 A0 (word 4) *)
  0x0045a803;       (* riscv_LW A6 A1 (word 4) *)
  0x07f68e93;       (* riscv_ADDI T4 A3 (word 127) *)
  0x007ede93;       (* riscv_SRLI T4 T4 7 *)
  0x025e8eb3;       (* riscv_MUL T4 T4 T0 *)
  0x006e8eb3;       (* riscv_ADD T4 T4 T1 *)
  0x018ede93;       (* riscv_SRLI T4 T4 24 *)
  0x027e8f33;       (* riscv_MUL T5 T4 T2 *)
  0x41e68f33;       (* riscv_SUB T5 A3 T5 *)
  0xffff0f13;       (* riscv_ADDI T5 T5 (word 4294967295) *)
  0x01cf3f33;       (* riscv_SLTU T5 T5 T3 *)
  0x00ef7f33;       (* riscv_AND T5 T5 A4 *)
  0x001f1f13;       (* riscv_SLLI T5 T5 1 *)
  0x40ee8eb3;       (* riscv_SUB T4 T4 A4 *)
  0x01ee8eb3;       (* riscv_ADD T4 T4 T5 *)
  0x41fedf13;       (* riscv_SRAI T5 T4 31 *)
  0x02cf7f13;       (* riscv_ANDI T5 T5 (word 44) *)
  0x01ee8eb3;       (* riscv_ADD T4 T4 T5 *)
  0x02cebf13;       (* riscv_SLTIU T5 T4 (word 44) *)
  0x41e00f33;       (* riscv_SUB T5 ZERO T5 *)
  0x01eef6b3;       (* riscv_AND A3 T4 T5 *)
  0x07f78e93;       (* riscv_ADDI T4 A5 (word 127) *)
  0x007ede93;       (* riscv_SRLI T4 T4 7 *)
  0x025e8eb3;       (* riscv_MUL T4 T4 T0 *)
  0x006e8eb3;       (* riscv_ADD T4 T4 T1 *)
  0x018ede93;       (* riscv_SRLI T4 T4 24 *)
  0x027e8f33;       (* riscv_MUL T5 T4 T2 *)
  0x41e78f33;       (* riscv_SUB T5 A5 T5 *)
  0xffff0f13;       (* riscv_ADDI T5 T5 (word 4294967295) *)
  0x01cf3f33;       (* riscv_SLTU T5 T5 T3 *)
  0x010f7f33;       (* riscv_AND T5 T5 A6 *)
  0x001f1f13;       (* riscv_SLLI T5 T5 1 *)
  0x410e8eb3;       (* riscv_SUB T4 T4 A6 *)
  0x01ee8eb3;       (* riscv_ADD T4 T4 T5 *)
  0x41fedf13;       (* riscv_SRAI T5 T4 31 *)
  0x02cf7f13;       (* riscv_ANDI T5 T5 (word 44) *)
  0x01ee8eb3;       (* riscv_ADD T4 T4 T5 *)
  0x02cebf13;       (* riscv_SLTIU T5 T4 (word 44) *)
  0x41e00f33;       (* riscv_SUB T5 ZERO T5 *)
  0x01eef7b3;       (* riscv_AND A5 T4 T5 *)
  0x00d52023;       (* riscv_SW A3 A0 (word 0) *)
  0x00f52223;       (* riscv_SW A5 A0 (word 4) *)
  0x00850513;       (* riscv_ADDI A0 A0 (word 8) *)
  0x00858593;       (* riscv_ADDI A1 A1 (word 8) *)
  0xf4c514e3;       (* riscv_BNE A0 A2 (word 4294967112) *)
  0x00008067       (* riscv_JALR ZERO RA (word 0) *)
];;
(*** BYTECODE END ***)

let MLDSA_POLY_USE_HINT_88_EXEC =
  RISCV_MK_EXEC_RULE mldsa_poly_use_hint_88_mc;;

let LENGTH_MLDSA_POLY_USE_HINT_88_MC =
  REWRITE_CONV[mldsa_poly_use_hint_88_mc] `LENGTH mldsa_poly_use_hint_88_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

needs "mldsa_native/riscv32/proofs/mldsa_specs_aux.ml";;

(* ------------------------------------------------------------------------- *)
(* One coefficient.                                                          *)
(*                                                                           *)
(* With f the high part of c rounded half down (as in Decompose, but before  *)
(* its wrap-around value 44 is mapped to 0), the routine computes            *)
(* r = f - h + 2*(h & s), where s says whether the low part c - f*2*GAMMA2   *)
(* is positive, and maps r = -1 to 43 and r = 44 to 0.                       *)
(* ------------------------------------------------------------------------- *)

let DECOMPOSE_ROUND_88 = prove
 (`!r. r < 8380417
       ==> (((r + 127) DIV 128) * 11275 + 8388608) DIV 16777216 =
           (if r MOD 190464 * 2 <= 190464 then r DIV 190464
            else r DIV 190464 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN
  ABBREV_TAC `k = (r + 95231) DIV 190464` THEN
  MP_TAC(SPECL [`r + 95231`; `190464`] DIVISION) THEN
  MP_TAC(SPECL [`r:num`; `190464`] DIVISION) THEN
  MP_TAC(SPECL [`r + 127`; `128`] DIVISION) THEN
  ASM_REWRITE_TAC[ARITH_EQ] THEN
  ABBREV_TAC `f = (r + 127) DIV 128` THEN
  ABBREV_TAC `q = r DIV 190464` THEN
  ABBREV_TAC `s = r MOD 190464` THEN
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `k <= 44` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `f + 743 >= 1488 * k /\ f <= 1488 * k + 744`
  STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(f * 11275 + 8388608) DIV 16777216 = k` SUBST1_TAC THENL
   [MATCH_MP_TAC DIV_SANDWICH THEN ASM_ARITH_TAC; ALL_TAC] THEN
  COND_CASES_TAC THEN ASM_ARITH_TAC);;

let RV32_DECOMPOSE_88_ROUND_VAL = prove
 (`!x:int32. val x < 8380417
     ==> val(word_ushr
              (word_add
                (word_mul (word_ushr (word_add x (word 127)) 7)
                          (word 11275))
                (word 8388608))
              24) =
         (if val x MOD 190464 * 2 <= 190464 then val x DIV 190464
          else val x DIV 190464 + 1)`,
  GEN_TAC THEN DISCH_TAC THEN
  FIRST_ASSUM(fun th -> REWRITE_TAC[GSYM(MATCH_MP DECOMPOSE_ROUND_88 th)]) THEN
  REWRITE_TAC[VAL_WORD_USHR; VAL_WORD_ADD; VAL_WORD_MUL; VAL_WORD;
              DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  SUBGOAL_THEN `(val(x:int32) + 127) MOD 4294967296 = val x + 127`
  SUBST1_TAC THENL [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(val(x:int32) + 127) DIV 128 <= 65472` ASSUME_TAC THENL
   [ASM_SIMP_TAC[RDIV_LT_EQ; ARITH_RULE `a <= b <=> a < b + 1`; ARITH_EQ] THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
   `((val(x:int32) + 127) DIV 128 * 11275) MOD 4294967296 =
    (val x + 127) DIV 128 * 11275` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
   `((val(x:int32) + 127) DIV 128 * 11275 + 8388608) MOD 4294967296 =
    (val x + 127) DIV 128 * 11275 + 8388608` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; REFL_TAC]);;

let IVAL_IWORD_32 = prove
 (`!z. --(&2147483648) <= z /\ z < &2147483648 ==> ival(iword z:int32) = z`,
  GEN_TAC THEN STRIP_TAC THEN MATCH_MP_TAC IVAL_IWORD THEN
  REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC INT_REDUCE_CONV THEN ASM_REWRITE_TAC[]);;

let USE_HINT_SIGN_88 = prove
 (`!r H. r < 8380417 /\ H <= 44 /\
         --(&95232) <= &r - &H * &190464:int /\ &r - &H * &190464:int <= &95232
     ==> (val(word_add (word_sub (word r) (word_mul (word H) (word 190464)))
                       (word 4294967295):int32) < 4190208 <=>
          &0 < &r - &H * &190464:int)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[WORD_IWORD; GSYM IWORD_INT_SUB; GSYM IWORD_INT_MUL] THEN
  SUBGOAL_THEN `iword(&4294967295):int32 = iword(-- &1)` SUBST1_TAC THENL
   [CONV_TAC WORD_REDUCE_CONV; ALL_TAC] THEN
  REWRITE_TAC[GSYM IWORD_INT_ADD] THEN
  ABBREV_TAC `z:int = &r - &H * &190464` THEN
  SUBGOAL_THEN `ival(iword(z + -- &1):int32) = z + -- &1` MP_TAC THENL
   [MATCH_MP_TAC IVAL_IWORD_32 THEN ASM_INT_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[ival; DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
  MP_TAC(ISPEC `iword(z + -- &1):int32` VAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
  COND_CASES_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[GSYM INT_OF_NUM_LT]) THEN
  REWRITE_TAC[GSYM INT_OF_NUM_LT] THEN ASM_INT_ARITH_TAC);;
let USE_HINT_88_TAIL = BITBLAST_RULE
 `!f h b:int32.
    val f <= 44 /\ val h <= 1 /\ val b <= 1
    ==> word_and
         (word_add (word_add (word_sub f h) (word_shl (word_and b h) 1))
                   (word_and (word_ishr (word_add (word_sub f h)
                                          (word_shl (word_and b h) 1)) 31)
                             (word 44)))
         (word_sub (word 0)
           (if val (word_add (word_add (word_sub f h)
                                       (word_shl (word_and b h) 1))
                     (word_and (word_ishr (word_add (word_sub f h)
                                            (word_shl (word_and b h) 1)) 31)
                               (word 44))) < 44
            then word 1 else word 0)) =
        if h = word 0 then (if val f < 44 then f else word 0)
        else if b = word 1 then
          (if val f < 43 then word_add f (word 1) else word 0)
        else (if f = word 0 then word 43 else word_sub f (word 1))`;;

let rv32_use_hint_88 = new_definition
 `rv32_use_hint_88 (c:int32) (h:int32):int32 =
    let f = word_ushr
              (word_add
                (word_mul (word_ushr (word_add c (word 127)) 7) (word 11275))
                (word 8388608))
              24 in
    let b = if val (word_add (word_sub c (word_mul f (word 190464)))
                             (word 4294967295)) < 4190208
            then word 1 else word 0 in
    let g = word_add (word_sub f h) (word_shl (word_and b h) 1) in
    let g2 = word_add g (word_and (word_ishr g 31) (word 44)) in
    word_and g2 (word_sub (word 0) (if val g2 < 44 then word 1 else word 0))`;;

let COND_WORD_EQ_1 = prove
 (`!p. ((if p then word 1 else word 0):int32 = word 1) <=> p`,
  GEN_TAC THEN COND_CASES_TAC THEN REWRITE_TAC[] THEN CONV_TAC WORD_REDUCE_CONV);;

let VAL_COND_01 = prove
 (`!p. val((if p then word 1 else word 0):int32) <= 1`,
  GEN_TAC THEN COND_CASES_TAC THEN CONV_TAC WORD_REDUCE_CONV THEN ARITH_TAC);;

let USE_HINT_88_VAL = prove
 (`!H b. H <= 44
     ==> val((if b then (if H < 43 then word_add (word H) (word 1) else word 0)
              else (if (word H:int32) = word 0 then word 43
                    else word_sub (word H) (word 1))):int32) =
         (if b then (if H < 43 then H + 1 else 0)
          else (if H = 0 then 43 else H - 1))`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `((word H:int32) = word 0) <=> H = 0` SUBST1_TAC THENL
   [REWRITE_TAC[WORD_EQ; DIMINDEX_32; CONG] THEN CONV_TAC NUM_REDUCE_CONV THEN
    ASM_SIMP_TAC[MOD_LT; ARITH_RULE `H <= 44 ==> H < 4294967296`]; ALL_TAC] THEN
  REPEAT COND_CASES_TAC THEN
  ASM_REWRITE_TAC[VAL_WORD_ADD; VAL_WORD_SUB_CASES; VAL_WORD; DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `H <= 44 ==> H < 4294967296`;
               ARITH_RULE `H <= 44 ==> H + 1 < 4294967296`] THEN
  ASM_ARITH_TAC);;

let RV32_USE_HINT_88_CORRECT = prove
 (`!c h:int32. val c < 8380417 /\ val h <= 1
     ==> val(rv32_use_hint_88 c h) = mldsa_use_hint_88 (val h) (val c)`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[rv32_use_hint_88] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  ABBREV_TAC `f:int32 = word_ushr
              (word_add
                (word_mul (word_ushr (word_add c (word 127)) 7) (word 11275))
                (word 8388608))
              24` THEN
  FIRST_ASSUM(MP_TAC o MATCH_MP RV32_DECOMPOSE_88_ROUND_VAL) THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPECL [`val(c:int32)`; `190464`] DIVISION) THEN
  REWRITE_TAC[ARITH_EQ] THEN
  ABBREV_TAC `r = val(c:int32)` THEN
  ABBREV_TAC `q = r DIV 190464` THEN
  ABBREV_TAC `s = r MOD 190464` THEN
  ABBREV_TAC `H = if s * 2 <= 190464 then q else q + 1` THEN
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `H <= 44` ASSUME_TAC THENL
   [MP_TAC(ASSUME `(if s * 2 <= 190464 then q else q + 1) = H`) THEN
    COND_CASES_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `&r - &H * &190464:int = (if s * 2 <= 190464 then &s else &s - &190464) /\
                --(&95232) <= &r - &H * &190464:int /\ &r - &H * &190464:int <= &95232`
  STRIP_ASSUME_TAC THENL
   [MP_TAC(ASSUME `(if s * 2 <= 190464 then q else q + 1) = H`) THEN
    COND_CASES_TAC THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
    ASM_REWRITE_TAC[GSYM INT_OF_NUM_ADD; GSYM INT_OF_NUM_MUL] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[GSYM INT_OF_NUM_LT; GSYM INT_OF_NUM_LE;
       GSYM INT_OF_NUM_EQ; GSYM INT_OF_NUM_ADD; GSYM INT_OF_NUM_MUL]) THEN
    MP_TAC(SPEC `s:num` INT_POS) THEN MP_TAC(SPEC `q:num` INT_POS) THEN
    REPEAT STRIP_TAC THEN ASM_INT_ARITH_TAC;
    ALL_TAC] THEN
  UNDISCH_TAC `r = q * 190464 + s` THEN DISCH_THEN(K ALL_TAC) THEN
  MP_TAC(ISPECL [`f:int32`; `h:int32`;
   `(if val (word_add (word_sub (c:int32) (word_mul (f:int32) (word 190464)))
                      (word 4294967295)) < 4190208
     then word 1 else word 0):int32`] USE_HINT_88_TAIL) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[VAL_COND_01] THEN ASM_ARITH_TAC; DISCH_THEN SUBST1_TAC] THEN
  REWRITE_TAC[COND_WORD_EQ_1] THEN
  SUBGOAL_THEN `(f:int32) = word H /\ (c:int32) = word r` (CONJUNCTS_THEN SUBST1_TAC) THENL
   [ASM_MESON_TAC[WORD_VAL]; ALL_TAC] THEN
  MP_TAC(SPECL [`r:num`; `H:num`] USE_HINT_SIGN_88) THEN
  ANTS_TAC THENL
   [REPEAT CONJ_TAC THEN FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC];
    DISCH_THEN SUBST1_TAC] THEN
  REWRITE_TAC[ASSUME `&r - &H * &190464:int = (if s * 2 <= 190464 then &s else &s - &190464)`] THEN
  SUBGOAL_THEN `val(word H:int32) = H` SUBST1_TAC THENL
   [REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[MLDSA_USE_HINT_88_UNFOLD; decompose_88_r1; decompose_88_r0;
              MLDSA_DECOMPOSE_88_EXPAND; mldsa_cmod] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[ASSUME `r MOD 190464 = s`; ASSUME `r DIV 190464 = q`] THEN
  SUBGOAL_THEN `val(word H:int32) = H` ASSUME_TAC THENL
   [REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(h:int32) = word 0 \/ (h:int32) = word 1` MP_TAC THENL
   [SUBGOAL_THEN `val(h:int32) = 0 \/ val h = 1` MP_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    MESON_TAC[WORD_VAL];
    ALL_TAC] THEN
  DISCH_THEN(DISJ_CASES_THEN SUBST1_TAC) THEN
  CONV_TAC WORD_REDUCE_CONV THEN
  ASM_SIMP_TAC[USE_HINT_88_VAL] THEN
  (ASM_CASES_TAC `s * 2 <= 190464` THENL
   [SUBGOAL_THEN `H:num = q` SUBST_ALL_TAC THENL [ASM_MESON_TAC[]; ALL_TAC];
    SUBGOAL_THEN `H:num = q + 1` SUBST_ALL_TAC THENL [ASM_MESON_TAC[]; ALL_TAC]]) THEN
  ASM_REWRITE_TAC[] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[VAL_WORD_0]) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[GSYM INT_OF_NUM_LT; GSYM INT_OF_NUM_LE;
     GSYM INT_OF_NUM_EQ; INT_GT]) THEN
  TRY ASM_ARITH_TAC THEN TRY ASM_INT_ARITH_TAC);;

(* ------------------------------------------------------------------------- *)
(* Main loop: two coefficients per iteration, with the two stores at the     *)
(* end of the iteration.                                                     *)
(* ------------------------------------------------------------------------- *)

let ALIGNED4_A_OFFSET = prove
 (`!a:int32 n. aligned 4 a ==> aligned 4 (word_add a (word(4 * n)):int32)`,
  REPEAT STRIP_TAC THEN
  ASM_SIMP_TAC[ALIGNED_WORD_ADD_EQ; ALIGNED_WORD; DIMINDEX_32] THEN
  CONJ_TAC THENL
   [CONV_TAC NUM_DIVIDES_CONV;
    MATCH_MP_TAC DIVIDES_RMUL THEN REWRITE_TAC[DIVIDES_REFL]]);;

let COEFFICIENT_ORTHOGONAL_SAME = prove
 (`!a:int32 i j.
      i < 256 /\ j < 256 /\ ~(j = i)
      ==> orthogonal_components
           ((memory :> bytes32 (word_add a (word(4 * j))))
            : (riscvstate,int32)component)
           (memory :> bytes32 (word_add a (word(4 * i))))`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN
   `nonoverlapping (word_add (a:int32) (word(4 * j)),4)
                   (word_add a (word(4 * i)),4)`
  MP_TAC THENL
   [REWRITE_TAC[nonoverlapping] THEN
    MATCH_MP_TAC NONOVERLAPPING_MODULO_OFFSET_BOTH THEN
    REWRITE_TAC[DIMINDEX_32] THEN
    SUBGOAL_THEN `j:num < i \/ i < j` STRIP_ASSUME_TAC THEN ASM_ARITH_TAC;
    DISCH_TAC THEN ORTHOGONAL_COMPONENTS_TAC]);;

let COEFFICIENT_ORTHOGONAL_DIFF = prove
 (`!a b:int32 i j.
      nonoverlapping (a,1024) (b,1024) /\ i < 256 /\ j < 256
      ==> orthogonal_components
           ((memory :> bytes32 (word_add a (word(4 * i))))
            : (riscvstate,int32)component)
           (memory :> bytes32 (word_add b (word(4 * j))))`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN
   `nonoverlapping (word_add (a:int32) (word(4 * i)),4)
                   (word_add b (word(4 * j)),4)`
  MP_TAC THENL
   [NONOVERLAPPING_TAC;
    DISCH_TAC THEN ORTHOGONAL_COMPONENTS_TAC]);;

let READ_THROUGH_ORTH = prove
 (`orthogonal_components c d /\ read c s = z
   ==> read c (write d y s) = z`,
  MESON_TAC[orthogonal_components]);;

(* Read a component through the writes of the stores: take the stored value
   if the component is the one written, otherwise pass the write using an
   orthogonality fact. Once no write is left, finish with fin. *)

let is_read_write tm =
  try fst(dest_const(fst(strip_comb(rand(lhs tm))))) = "write"
  with _ -> false;;

let rec READ_THROUGH_STORES_TAC fin (asl,w as g) =
  if not(is_read_write w) then fin g else
  (FIRST
    [CHANGED_TAC(CONV_TAC(LAND_CONV COMPONENT_READ_OVER_WRITE_CONV)) THEN
     READ_THROUGH_STORES_TAC fin;
     MATCH_MP_TAC READ_THROUGH_ORTH THEN CONJ_TAC THENL
      [FIRST [ASM_REWRITE_TAC[] THEN NO_TAC; ORTHOGONAL_COMPONENTS_TAC];
       READ_THROUGH_STORES_TAC fin]]) g;;

let INDEX_RULES =
  [ARITH_RULE `4 * (2 * i + 0) = 8 * i`; ARITH_RULE `4 * (2 * i + 1) = 8 * i + 4`;
   ARITH_RULE `4 * (2 * i) = 8 * i`; ADD_0];;

let USE_HINT_REWRITE_STORES_TAC =
  MAP_EVERY (fun l -> USE_THEN l (fun th -> ONCE_REWRITE_TAC[GSYM th]))
   ["store1"; "store0"];;

let USE_HINT_88_VALUE_TAC =
  USE_HINT_REWRITE_STORES_TAC THEN
  READ_THROUGH_STORES_TAC
   (CONV_TAC(TOP_DEPTH_CONV COMPONENT_READ_OVER_WRITE_CONV) THEN
    ASM_REWRITE_TAC[rv32_use_hint_88] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REFL_TAC);;

let USE_HINT_FRAME_TAC arr =
  MAP_EVERY (fun k ->
    let ii = mk_comb(mk_comb(`(+):num->num->num`, `2 * i`),
                     mk_small_numeral k) in
    (if arr = `a:int32`
     then MP_TAC(SPECL [arr; ii; `j:num`] COEFFICIENT_ORTHOGONAL_SAME)
     else MP_TAC(SPECL [arr; `a:int32`; `j:num`; ii]
                   COEFFICIENT_ORTHOGONAL_DIFF)) THEN
    ANTS_TAC THENL
     [REPEAT CONJ_TAC THEN FIRST [NONOVERLAPPING_TAC; ASM_ARITH_TAC];
      REWRITE_TAC INDEX_RULES THEN DISCH_TAC]) [0; 1] THEN
  USE_HINT_REWRITE_STORES_TAC THEN
  READ_THROUGH_STORES_TAC (ASM_SIMP_TAC[] THEN NO_TAC);;

let MLDSA_POLY_USE_HINT_88_CORE = prove
 (`!a h:int32 x y:num->int32 pc.
    aligned 4 a /\ aligned 4 h /\
    nonoverlapping (a,1024) (h,1024) /\
    nonoverlapping (word pc,LENGTH mldsa_poly_use_hint_88_mc) (a,1024)
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_poly_use_hint_88_mc /\
           read PC s = word pc /\
           C_ARGUMENTS [a; h] s /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add h (word(4 * i)))) s = y i))
      (\s. read PC s = word(pc + 216) /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s =
                rv32_use_hint_88 (x i) (y i)))
      (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6;
                  T0; T1; T2; T3; T4; T5] ,,
       MAYCHANGE [events] ,,
       MAYCHANGE [memory :> bytes(a,1024)])`,
  MAP_EVERY X_GEN_TAC
   [`a:int32`; `h:int32`; `x:num->int32`; `y:num->int32`; `pc:num`] THEN
  REWRITE_TAC[LENGTH_MLDSA_POLY_USE_HINT_88_MC; C_ARGUMENTS] THEN
  REPEAT STRIP_TAC THEN
  ENSURES_WHILE_UP_TAC `128` `pc + 28` `pc + 212`
   `\i s. read T0 s = word 11275 /\ read T1 s = word 8388608 /\
          read T2 s = word 190464 /\ read T3 s = word 4190208 /\
          read A2 s = word_add a (word 1024) /\
          read A0 s = word_add a (word(8 * i)) /\
          read A1 s = word_add h (word(8 * i)) /\
          (!j. j < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * j)))) s =
               if j < 2 * i then rv32_use_hint_88 (x j) (y j) else x j) /\
          (!j. j < 256 ==>
               read(memory :> bytes32(word_add h (word(4 * j)))) s = y j)` THEN
  REPEAT CONJ_TAC THENL
   [CONV_TAC NUM_REDUCE_CONV;
    ENSURES_INIT_TAC "s0" THEN
    RISCV_STEPS_TAC MLDSA_POLY_USE_HINT_88_EXEC (1--7) THEN
    ENSURES_FINAL_STATE_TAC THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; ARITH_RULE `~(j < 0)`] THEN
    CONV_TAC WORD_REDUCE_CONV;
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    MAP_EVERY (fun (arr,k) ->
      MP_TAC(SPECL [arr; mk_comb(mk_comb(`(+):num->num->num`, `2 * i`),
                                 mk_small_numeral k)] ALIGNED4_A_OFFSET) THEN
      ASM_REWRITE_TAC INDEX_RULES THEN DISCH_TAC)
     [`a:int32`,0; `a:int32`,1; `h:int32`,0; `h:int32`,1] THEN
    MAP_EVERY (fun (arr,k) ->
      let ii = mk_comb(mk_comb(`(+):num->num->num`, `2 * i`),
                       mk_small_numeral k) in
      FIRST_ASSUM(fun th ->
        if is_forall(concl th) && vfree_in arr (concl th) &&
           not(vfree_in (if arr = `a:int32` then `h:int32` else `a:int32`)
                 (concl th))
        then MP_TAC(SPEC ii th) else NO_TAC) THEN
      ANTS_TAC THENL
       [ASM_ARITH_TAC;
        REWRITE_TAC(ARITH_RULE `~(2 * i + k < 2 * i)` :: INDEX_RULES) THEN
        DISCH_TAC])
     [`a:int32`,0; `a:int32`,1; `h:int32`,0; `h:int32`,1] THEN
    RISCV_STEPS_TAC MLDSA_POLY_USE_HINT_88_EXEC (1--42) THEN
    MAP_EVERY (fun n ->
      RISCV_STEP_TAC MLDSA_POLY_USE_HINT_88_EXEC []
        ("s" ^ string_of_int (42 + n)) None
       (fun th -> LABEL_TAC ("store" ^ string_of_int (n - 1)) th THEN
                  STRIP_TAC)) (1--2) THEN
    SUBGOAL_THEN
     `!j. j < 256 ==>
          read(memory :> bytes32(word_add a (word(4 * j)))) s44 =
          if j < 2 * (i + 1) then rv32_use_hint_88 (x j) (y j) else x j`
    ASSUME_TAC THENL
     [X_GEN_TAC `j:num` THEN DISCH_TAC THEN
      REWRITE_TAC[ARITH_RULE
       `j < 2 * (i + 1) <=> j < 2 * i \/ j = 2 * i + 0 \/ j = 2 * i + 1`] THEN
      ASM_CASES_TAC `j = 2 * i + 0` THENL
       [ASM_REWRITE_TAC INDEX_RULES THEN USE_HINT_88_VALUE_TAC; ALL_TAC] THEN
      ASM_CASES_TAC `j = 2 * i + 1` THENL
       [ASM_REWRITE_TAC INDEX_RULES THEN USE_HINT_88_VALUE_TAC; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN USE_HINT_FRAME_TAC `a:int32`;
      ALL_TAC] THEN
    SUBGOAL_THEN
     `!j. j < 256 ==>
          read(memory :> bytes32(word_add h (word(4 * j)))) s44 = y j`
    ASSUME_TAC THENL
     [X_GEN_TAC `j:num` THEN DISCH_TAC THEN USE_HINT_FRAME_TAC `h:int32`;
      ALL_TAC] THEN
    DISCARD_OLDSTATE_TAC "s44" THEN
    RISCV_STEPS_TAC MLDSA_POLY_USE_HINT_88_EXEC (45--46) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    CONV_TAC WORD_RULE;
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    SUBGOAL_THEN
     `~(word_add a (word (8 * i)):int32 = word_add a (word 1024))`
    ASSUME_TAC THENL
     [REWRITE_TAC[WORD_RULE
       `word_add a (word x):int32 = word_add a (word y) <=>
        (word x:int32) = word y`] THEN
      REWRITE_TAC[WORD_EQ; DIMINDEX_32; CONG] THEN
      CONV_TAC NUM_REDUCE_CONV THEN
      SUBGOAL_THEN `8 * i < 4294967296`
       (fun th -> REWRITE_TAC[MATCH_MP MOD_LT th]) THEN
      ASM_ARITH_TAC;
      ALL_TAC] THEN
    RISCV_STEPS_TAC MLDSA_POLY_USE_HINT_88_EXEC [1] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];
    ENSURES_INIT_TAC "s0" THEN
    RISCV_STEPS_TAC MLDSA_POLY_USE_HINT_88_EXEC [1] THEN
    RULE_ASSUM_TAC(CONV_RULE NUM_REDUCE_CONV) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    X_GEN_TAC `j:num` THEN DISCH_TAC THEN ASM_SIMP_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Subroutine form.                                                          *)
(* ------------------------------------------------------------------------- *)

let MLDSA_POLY_USE_HINT_88_SUBROUTINE_EXACT = prove
 (`!a h:int32 x y:num->int32 pc returnaddress.
    aligned 4 a /\ aligned 4 h /\ aligned 4 returnaddress /\
    nonoverlapping (a,1024) (h,1024) /\
    nonoverlapping (word pc,LENGTH mldsa_poly_use_hint_88_mc) (a,1024)
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_poly_use_hint_88_mc /\
           read PC s = word pc /\
           read RA s = returnaddress /\
           C_ARGUMENTS [a; h] s /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add h (word(4 * i)))) s = y i))
      (\s. read PC s = returnaddress /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s =
                rv32_use_hint_88 (x i) (y i)))
      (MAYCHANGE_REGS_PERMITTED_BY_ABI ,,
       MAYCHANGE [memory :> bytes(a,1024)])`,
  REWRITE_TAC[fst MLDSA_POLY_USE_HINT_88_EXEC] THEN
  RISCV_ADD_RETURN_NOSTACK_TAC MLDSA_POLY_USE_HINT_88_EXEC
    (REWRITE_RULE[fst MLDSA_POLY_USE_HINT_88_EXEC]
      MLDSA_POLY_USE_HINT_88_CORE));;

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/rv32im/src/arith_native_rv32im.h *)

let MLDSA_POLY_USE_HINT_88_SUBROUTINE_CORRECT = prove
 (`!a h:int32 x y:num->int32 pc returnaddress.
    aligned 4 a /\ aligned 4 h /\ aligned 4 returnaddress /\
    nonoverlapping (a,1024) (h,1024) /\
    nonoverlapping (word pc,LENGTH mldsa_poly_use_hint_88_mc) (a,1024) /\
    (!i. i < 256 ==> val(x i) < 8380417) /\
    (!i. i < 256 ==> val(y i) <= 1)
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_poly_use_hint_88_mc /\
           read PC s = word pc /\
           read RA s = returnaddress /\
           C_ARGUMENTS [a; h] s /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add h (word(4 * i)))) s = y i))
      (\s. read PC s = returnaddress /\
           (!i. i < 256 ==>
                val(read(memory :> bytes32(word_add a (word(4 * i)))) s) =
                mldsa_use_hint_88 (val(y i)) (val(x i))))
      (MAYCHANGE_REGS_PERMITTED_BY_ABI ,,
       MAYCHANGE [memory :> bytes(a,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(SPECL [`a:int32`; `h:int32`; `x:num->int32`; `y:num->int32`;
                `pc:num`; `returnaddress:int32`]
    MLDSA_POLY_USE_HINT_88_SUBROUTINE_EXACT) THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_POSTCONDITION_THM) THEN
  REWRITE_TAC[] THEN X_GEN_TAC `s:riscvstate` THEN STRIP_TAC THEN
  ASM_SIMP_TAC[RV32_USE_HINT_88_CORRECT]);;

(* ------------------------------------------------------------------------- *)
(* Constant-time and memory-safety proof.                                    *)
(* ------------------------------------------------------------------------- *)

needs "s2n_bignum/riscv/proofs/consttime.ml";;
needs "mldsa_native/riscv32/proofs/consttime_aux.ml";;

let mldsa_poly_use_hint_88_rv32im_signature =
  ([("a","int32_t[static 256]","false");
    ("h","int32_t[static 256]","true")],
   "void",
   [("a","256",4); ("h","256",4)],
   [("a","256",4)],
   []);;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    mldsa_poly_use_hint_88_rv32im_signature
    MLDSA_POLY_USE_HINT_88_SUBROUTINE_EXACT
    MLDSA_POLY_USE_HINT_88_EXEC;;

let MLDSA_POLY_USE_HINT_88_SUBROUTINE_SAFE = time prove
 (`exists f_events.
     forall e a h pc returnaddress.
       aligned 4 a /\ aligned 4 h /\ aligned 4 returnaddress /\
       nonoverlapping (a,1024) (h,1024) /\
       nonoverlapping (word pc,LENGTH mldsa_poly_use_hint_88_mc) (a,1024)
       ==> ensures riscv
            (\s. aligned_bytes_loaded s (word pc) mldsa_poly_use_hint_88_mc /\
                 read PC s = word pc /\
                 read RA s = returnaddress /\
                 C_ARGUMENTS [a; h] s /\
                 read events s = e)
            (\s. read PC s = returnaddress /\
                 exists e2.
                   read events s = APPEND e2 e /\
                   e2 = f_events h a pc returnaddress /\
                   memaccess_inbounds e2 [a,1024; h,1024] [a,1024])
            (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars MLDSA_POLY_USE_HINT_88_EXEC);;
