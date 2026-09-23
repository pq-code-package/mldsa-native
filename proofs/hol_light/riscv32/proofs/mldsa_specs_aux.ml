(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* RV32-specific ML-DSA specifications and arithmetic lemmas.                *)
(* ========================================================================= *)

(* The shared mathematical definitions remain in `common/mldsa_specs.ml`.
   This file adds only the facts needed by the RV32 proofs:

   - local names for the existing forward and inverse NTT definitions;
   - `MLDSA_BARRETT_MUL_SLOW` for the shift/add replacement of
     multiplication by q;
   - bounds for the Barrett and Montgomery operations used by the assembly;
   - tactics that prove the resulting integer congruences and bounds;
   - cached powers of the ML-DSA root; and
   - `MLDSA_BITREVERSE_INVERSE_NTT_REORDERED`, which puts the inverse NTT sum
     in the coefficient order produced by the RV32 loops.

   The pointwise proof uses the Montgomery bounds. The forward and inverse
   arithmetic files use the root, congruence, and bit-reversal results.
   `mldsa_zetas.ml` uses the root evaluator to check the generated table. *)

needs "s2n_bignum/riscv/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;

(* The shared transform definitions have ARM names because the ARM proofs
   introduced them first. Give them RV32-independent names locally, without
   changing the shared file or the existing ARM and x86 proofs. *)

let mldsa_bitreverse_forward_ntt = define
 `mldsa_bitreverse_forward_ntt = arm_mldsa_forward_ntt`;;

let MLDSA_BITREVERSE_FORWARD_NTT_ALT = prove
 (`mldsa_bitreverse_forward_ntt f k =
   isum (0..255)
        (\j. f j *
             (&1753 pow ((2 * bitreverse8 k + 1) * j)) rem &8380417)
    rem &8380417`,
  REWRITE_TAC
   [mldsa_bitreverse_forward_ntt;
    ARM_MLDSA_FORWARD_NTT_ALT]);;

let mldsa_bitreverse_inverse_ntt = define
 `mldsa_bitreverse_inverse_ntt = arm_mldsa_inverse_ntt`;;

(* Arithmetic idioms used by the RV32 fast- and slow-multiplier code. *)

let mldsa_barrett_mul = define
 `mldsa_barrett_mul ((z:int32),(w:int32)) (a:int32):int32 =
    word_sub
      (word_mul a z)
      (word_mul
        (word_subword
          (word_mul (word_sx a:int64) (word_sx w:int64))
          (32,32):int32)
        (word 8380417))`;;

let MLDSA_Q_MUL_SHIFT_ADD = prove
 (`!x t:int32.
    word_sub
      (word_add (word_sub x t) (word_shl t 13))
      (word_shl (word_shl t 13) 10) =
    word_sub x (word_mul t (word 8380417))`,
  REPEAT GEN_TAC THEN CONV_TAC WORD_RULE);;

let MLDSA_BARRETT_MUL_SLOW = prove
 (`!z:int32. !w:int32. !a:int32.
    let t =
      word_subword
       (word_mul (word_sx a:int64) (word_sx w:int64))
       (32,32):int32 in
    word_sub
      (word_add
        (word_sub (word_mul a z) t)
        (word_shl t 13))
      (word_shl (word_shl t 13) 10) =
    mldsa_barrett_mul (z,w) a`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[LET_DEF; LET_END_DEF; mldsa_barrett_mul] THEN
  CONV_TAC WORD_RULE);;

(* A product of two signed 32-bit values fits exactly in a signed 64-bit
   word, so machine multiplication agrees with integer multiplication. *)

let IVAL_WORD_MUL_SX32_64_EXACT = prove
 (`!x:int32. !y:int32.
    ival(word_mul (word_sx x:int64) (word_sx y:int64)) =
    ival x * ival y`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[WORD_RULE
   `word_mul a b:int64 = iword(ival a * ival b)`] THEN
  SIMP_TAC[IVAL_WORD_SX; DIMINDEX_32; DIMINDEX_64; ARITH] THEN
  MATCH_MP_TAC IVAL_IWORD THEN
  REWRITE_TAC[DIMINDEX_64] THEN
  MP_TAC(ISPEC `x:int32` IVAL_BOUND) THEN
  MP_TAC(ISPEC `y:int32` IVAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  STRIP_TAC THEN STRIP_TAC THEN
  BOUNDER_TAC[]);;

(* Identify the rounded multiply-high sequence used for inverse-transform
   scaling with the existing common `arm_mldsa_barmul` specification. *)

let MLDSA_INTT_SCALE_MULH =
  let int_div_round_halve = prove
   (`!x:int.
      (x div &4294967296 + &1) div &2 =
      (x + &4294967296) div &8589934592`,
    GEN_TAC THEN
    SUBGOAL_THEN
     `&8589934592:int = &4294967296 * &2`
     SUBST1_TAC THENL
     [CONV_TAC INT_REDUCE_CONV; ALL_TAC] THEN
    let thdiv =
      MATCH_MP
       (SPECL
         [`x + &4294967296:int`; `&4294967296:int`; `&2:int`]
         INT_DIV_DIV)
       (EQT_ELIM(INT_REDUCE_CONV `&0:int <= &4294967296`))
    and thadd =
      MATCH_MP
       (SPECL
         [`&1:int`; `&4294967296:int`; `x:int`]
         (el 2 (CONJUNCTS INT_DIV_MUL_ADD)))
       (EQT_ELIM(INT_REDUCE_CONV
         `~(&4294967296:int = &0)`)) in
    ONCE_REWRITE_TAC[GSYM thdiv] THEN
    REWRITE_TAC[REWRITE_RULE[INT_MUL_LID] thadd]) in
  let int_div_lmul_cancel = prove
   (`!c x d:int.
      &0 < c ==> (c * x) div (c * d) = x div d`,
    REPEAT STRIP_TAC THEN
    SUBGOAL_THEN `&0:int <= c` ASSUME_TAC THENL
     [ASM_INT_ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC
     [GSYM INT_DIV_DIV; INT_DIV_MUL; INT_LT_IMP_NE]) in
  let quotient_int = prove
   (`!a:int.
      ((a * &16791564) div &4294967296 + &1) div &2 =
      (&2 * a * &4197891 + &2147483648) div &4294967296`,
    GEN_TAC THEN
    REWRITE_TAC[int_div_round_halve] THEN
    SUBGOAL_THEN
     `&8589934592:int = &2 * &4294967296`
     SUBST1_TAC THENL
     [CONV_TAC INT_REDUCE_CONV; ALL_TAC] THEN
    TRANS_TAC EQ_TRANS
     `(&2 * (&2 * a * &4197891 + &2147483648)) div
      (&2 * &4294967296)` THEN
    CONJ_TAC THENL
     [MATCH_MP_TAC(MESON[]
       `(x:int) = y ==> x div d = y div d`) THEN
      INT_ARITH_TAC;
      MATCH_MP_TAC int_div_lmul_cancel THEN
      CONV_TAC INT_REDUCE_CONV]) in
  let high_bounds = prove
   (`!a:int32.
      -- &8395782 <=
        ival(word_subword
          (word_mul
            (word_sx a:int64)
            (word_sx (word 16791564:int32):int64))
          (32,32):int32) /\
      ival(word_subword
        (word_mul
          (word_sx a:int64)
          (word_sx (word 16791564:int32):int64))
        (32,32):int32) <= &8395781`,
    GEN_TAC THEN
    REWRITE_TAC
     [IVAL_WORD_SUBWORD_DIV_32;
      IVAL_WORD_MUL_SX32_64_EXACT] THEN
    CONV_TAC(ONCE_DEPTH_CONV WORD_NUM_RED_CONV) THEN
    MP_TAC(ISPEC `a:int32` IVAL_BOUND) THEN
    REWRITE_TAC[DIMINDEX_32] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    SIMP_TAC
     [INT_LE_DIV_EQ; INT_DIV_LE_EQ;
      INT_OF_NUM_LT; ARITH] THEN
    CONV_TAC(ONCE_DEPTH_CONV INT_REDUCE_CONV) THEN
    INT_ARITH_TAC) in
  let quotient_bounds = prove
   (`!a:int32.
      -- &4197891 <=
        (&2 * ival a * &4197891 + &2147483648) div
        &4294967296 /\
      (&2 * ival a * &4197891 + &2147483648) div
        &4294967296 <= &4197891`,
    GEN_TAC THEN
    MP_TAC(ISPEC `a:int32` IVAL_BOUND) THEN
    REWRITE_TAC[DIMINDEX_32] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    SIMP_TAC
     [INT_LE_DIV_EQ; INT_DIV_LE_EQ;
      INT_OF_NUM_LT; ARITH] THEN
    CONV_TAC(ONCE_DEPTH_CONV INT_REDUCE_CONV) THEN
    INT_ARITH_TAC) in
  let high_add = prove
   (`!a:int32.
      ival(word_add
        (word_subword
          (word_mul
            (word_sx a:int64)
            (word_sx (word 16791564:int32):int64))
          (32,32):int32)
        (word 1)) =
      ival(word_subword
        (word_mul
          (word_sx a:int64)
          (word_sx (word 16791564:int32):int64))
        (32,32):int32) + &1`,
    GEN_TAC THEN
    REWRITE_TAC[WORD_RULE
     `word_add x (word 1):int32 = iword(ival x + &1)`] THEN
    MATCH_MP_TAC IVAL_IWORD THEN
    REWRITE_TAC[DIMINDEX_32] THEN
    MP_TAC(SPEC `a:int32` high_bounds) THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    INT_ARITH_TAC) in
  let quotient_word = prove
   (`!a:int32.
      word_ishr
        (word_add
          (word_subword
            (word_mul
              (word_sx a:int64)
              (word_sx (word 16791564:int32):int64))
            (32,32):int32)
          (word 1))
        1 =
      iword((&2 * ival a * &4197891 + &2147483648) div
            &4294967296)`,
    GEN_TAC THEN
    REWRITE_TAC
     [word_ishr; high_add;
      IVAL_WORD_SUBWORD_DIV_32;
      IVAL_WORD_MUL_SX32_64_EXACT] THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    REWRITE_TAC[quotient_int]) in
  prove
   (`!a:int32.
      word_sub
        (word_mul a (word 16382))
        (word_mul
          (word_ishr
            (word_add
              (word_subword
                (word_mul
                  (word_sx a:int64)
                  (word_sx (word 16791564:int32):int64))
                (32,32):int32)
              (word 1))
            1)
          (word 8380417)) =
      arm_mldsa_barmul (&4197891,word 16382) a`,
    GEN_TAC THEN
    REWRITE_TAC
     [quotient_word; arm_mldsa_barmul; iword_saturate;
      word_INT_MIN; word_INT_MAX; DIMINDEX_32] THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    MP_TAC(SPEC `a:int32` quotient_bounds) THEN
    STRIP_TAC THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    ASM_INT_ARITH_TAC);;

(* Given a congruence and bounds for the input, prove the corresponding
   congruence and bounds after one Barrett multiplication. *)

let CONGBOUND_MLDSA_BARRETT_MUL = prove
 (`!a a' l u.
      ((ival a == a') (mod &8380417) /\
       l <= ival a /\ ival a <= u)
      ==> !z:int32. !w:int32.
          (max (abs l) (abs u) *
             abs(&4294967296 * ival z - &8380417 * ival w) +
             &35993616933462015) div &4294967296
          <= &2147483647
          ==> (ival(mldsa_barrett_mul (z,w) a) ==
               a' * ival z) (mod &8380417) /\
              --((max (abs l) (abs u) *
                    abs(&4294967296 * ival z - &8380417 * ival w) +
                    &35993616933462015) div &4294967296)
              <= ival(mldsa_barrett_mul (z,w) a) /\
              ival(mldsa_barrett_mul (z,w) a) <=
              (max (abs l) (abs u) *
                 abs(&4294967296 * ival z - &8380417 * ival w) +
                 &35993616933462015) div &4294967296`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[mldsa_barrett_mul] THEN
  REWRITE_TAC[WORD_RULE
   `word_sub (word_mul a z)
      (word_mul t (word 8380417):int32) =
    iword(ival a * ival z - ival t * &8380417)`] THEN
  REWRITE_TAC[IVAL_WORD_SUBWORD_DIV_32;
              IVAL_WORD_MUL_SX32_64_EXACT] THEN
  MATCH_MP_TAC(MESON[]
   `(x == k) (mod n) /\
    (lo <= x /\ x <= hi ==> ival(iword x:int32) = x) /\
    (lo <= x /\ x <= hi)
    ==> (ival(iword x:int32) == k) (mod n) /\
        lo <= ival(iword x:int32) /\
        ival(iword x:int32) <= hi`) THEN
  ASM_SIMP_TAC[INTEGER_RULE
   `(a:int == a') (mod q)
    ==> (a * z - (a * w) div d * q == a' * z) (mod q)`] THEN
  CONJ_TAC THENL
   [REPEAT STRIP_TAC THEN MATCH_MP_TAC IVAL_IWORD THEN
    REWRITE_TAC[DIMINDEX_32; ARITH] THEN ASM_INT_ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN
   `abs(ival(a:int32) *
        (&4294967296 * ival(z:int32) -
         &8380417 * ival(w:int32)))
    <= max (abs l) (abs u) *
       abs(&4294967296 * ival(z:int32) -
           &8380417 * ival(w:int32))`
  ASSUME_TAC THENL
   [REWRITE_TAC[INT_ABS_MUL] THEN
    ASM_SIMP_TAC[INT_LE_RMUL; INT_ABS_POS; INT_ARITH
     `l:int <= x /\ x <= u
      ==> abs x <= max (abs l) (abs u)`];
    ALL_TAC] THEN
  MP_TAC(SPECL
   [`ival(a:int32) * ival(w:int32):int`;
    `&4294967296:int`] INT_DIVISION) THEN
  CONV_TAC(ONCE_DEPTH_CONV INT_REDUCE_CONV) THEN
  STRIP_TAC THEN
  MP_TAC(SPECL
   [`ival(a:int32):int`; `ival(z:int32):int`;
    `ival(w:int32):int`;
    `(ival(a:int32) * ival(w:int32)) div &4294967296`;
    `(ival(a:int32) * ival(w:int32)) rem &4294967296`]
   (INTEGER_RULE
    `!a z w t r:int.
      a * w = t * &4294967296 + r
      ==> &4294967296 * (a * z - t * &8380417) =
          a * (&4294967296 * z - &8380417 * w) +
          &8380417 * r`)) THEN
  ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
  REWRITE_TAC[INT_ARITH
   `--(b div d) <= x <=> --x <= b div d`] THEN
  ASM_SIMP_TAC[INT_LE_DIV_EQ; INT_OF_NUM_LT; ARITH] THEN
  ASM_INT_ARITH_TAC);;

(* The pointwise routine constructs the Montgomery table pair from its
   run-time multiplier. These lemmas connect that pair to the common
   `mldsa_montmul` bound theorem. *)

let MLDSA_QINV_RUNTIME_PAIR = prove
 (`!y:int32.
    (&8380417 *
     ival(word_sx (word_mul y (word 58728449)):int64))
    rem &4294967296 =
    ival(word_sx y:int64) rem &4294967296`,
  GEN_TAC THEN
  SIMP_TAC[IVAL_WORD_SX; DIMINDEX_32; DIMINDEX_64; ARITH] THEN
  REWRITE_TAC[INT_REM_EQ] THEN
  MP_TAC(ISPECL [`y:int32`; `word 58728449:int32`]
    ICONG_WORD_MUL) THEN
  REWRITE_TAC[DIMINDEX_32] THEN
  CONV_TAC WORD_REDUCE_CONV THEN
  CONV_TAC(ONCE_DEPTH_CONV INT_REDUCE_CONV) THEN
  DISCH_THEN(LABEL_TAC "wordmul") THEN
  MATCH_MP_TAC INT_CONG_TRANS THEN
  EXISTS_TAC
   `&8380417 * (ival(y:int32) * &58728449):int` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC INT_CONG_LMUL THEN
    USE_THEN "wordmul" MATCH_ACCEPT_TAC;
    REWRITE_TAC[INT_MUL_AC; INT_MUL_LID; INT_MUL_RID] THEN
    MATCH_MP_TAC
     (REWRITE_RULE[INT_MUL_AC; INT_MUL_LID; INT_MUL_RID]
      (SPECL
        [`&8380417 * &58728449:int`;
         `&1:int`;
         `ival(y:int32)`;
         `&4294967296:int`]
        INT_CONG_RMUL)) THEN
    REWRITE_TAC[GSYM INT_REM_EQ] THEN CONV_TAC INT_REDUCE_CONV]);;

let CONGBOUND_MLDSA_MONTMUL_RUNTIME = prove
 (`!x x' lx ux.
      ((ival x == x') (mod &8380417) /\
       lx <= ival x /\ ival x <= ux)
      ==> !y:int32.
          (ival(mldsa_montmul
             (word_sx y,
              word_sx (word_mul y (word 58728449))) x) ==
           &(inverse_mod 8380417 4294967296) * ival y * x')
          (mod &8380417) /\
          (min (ival y * lx) (ival y * ux) - &17996808462540799)
          div &4294967296 <=
          ival(mldsa_montmul
            (word_sx y,
             word_sx (word_mul y (word 58728449))) x) /\
          ival(mldsa_montmul
            (word_sx y,
             word_sx (word_mul y (word 58728449))) x) <=
          (max (ival y * lx) (ival y * ux) + &17996812765888511)
          div &2 pow 32`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN X_GEN_TAC `y:int32` THEN
  FIRST_X_ASSUM(fun th ->
    MP_TAC(SPECL
      [`word_sx (y:int32):int64`;
       `word_sx (word_mul (y:int32) (word 58728449)):int64`]
      (MATCH_MP CONGBOUND_MLDSA_MONTMUL th))) THEN
  ANTS_TAC THENL
   [REPEAT CONJ_TAC THENL
     [MP_TAC(ISPEC `y:int32` IVAL_BOUND) THEN
      REWRITE_TAC[DIMINDEX_32] THEN
      SIMP_TAC[IVAL_WORD_SX; DIMINDEX_32; DIMINDEX_64; ARITH] THEN
      CONV_TAC NUM_REDUCE_CONV THEN INT_ARITH_TAC;
      MP_TAC(ISPEC `y:int32` IVAL_BOUND) THEN
      REWRITE_TAC[DIMINDEX_32] THEN
      SIMP_TAC[IVAL_WORD_SX; DIMINDEX_32; DIMINDEX_64; ARITH] THEN
      CONV_TAC NUM_REDUCE_CONV THEN INT_ARITH_TAC;
      MATCH_ACCEPT_TAC MLDSA_QINV_RUNTIME_PAIR];
    SIMP_TAC[IVAL_WORD_SX; DIMINDEX_32; DIMINDEX_64; ARITH]]);;

(* Add the RV32 Barrett operation to the shared tactic that computes
   congruences and bounds. Cache each result because the transform proofs
   revisit the same large butterfly expressions many times. *)

let RV32_ASM_CONGBOUND_STEP rule tm =
  match tm with
  | Comb(Const("word",_),n) when is_numeral n ->
      let th1 = ISPEC tm CONGBOUND_CONST in
      let th2 =
        WORD_RED_CONV
          (lhand(lhand(snd(strip_forall(concl th1))))) in
      MATCH_MP th1 th2
  | Comb(Const("iword",_),n) when is_intconst n ->
      let th0 = WORD_IWORD_CONV tm in
      let th1 = ISPEC (rand(concl th0)) CONGBOUND_CONST in
      let th2 =
        WORD_RED_CONV
          (lhand(lhand(snd(strip_forall(concl th1))))) in
      SUBS[SYM th0] (MATCH_MP th1 th2)
  | Comb(Comb(Const("mldsa_barrett_mul",_),zw),t) ->
      let ztm,wtm = dest_pair zw
      and th0 = rule t in
      let th0' =
        WEAKEN_INTCONG_RULE (num 8380417) th0 in
      let th1 =
        SPECL [ztm;wtm]
          (MATCH_MP CONGBOUND_MLDSA_BARRETT_MUL th0') in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Const("mldsa_montred",_),t) ->
      let th1 =
        WEAKEN_INTCONG_RULE (num 8380417) (rule t) in
      CONCL_BOUNDS_RULE
        (SIDE_ELIM_RULE(MATCH_MP CONGBOUND_MLDSA_MONTRED th1))
  | Comb(Const("mldsa_pointwise_montred",_),t) ->
      let th1 =
        WEAKEN_INTCONG_RULE (num 8380417) (rule t) in
      CONCL_BOUNDS_RULE
        (SIDE_ELIM_RULE
          (MATCH_MP CONGBOUND_MLDSA_POINTWISE_MONTRED th1))
  | Comb(Const("mldsa_barred",_),t) ->
      let th1 =
        WEAKEN_INTCONG_RULE (num 8380417) (rule t) in
      CONCL_BOUNDS_RULE
        (SIDE_ELIM_RULE(MATCH_MP CONGBOUND_MLDSA_BARRED th1))
  | Comb(Comb(Const("mldsa_montmul",_),ab),t) ->
      let atm,btm = dest_pair ab
      and th0 = rule t in
      let th0' =
        WEAKEN_INTCONG_RULE (num 8380417) th0 in
      let th1 =
        SPECL [atm;btm]
          (MATCH_MP CONGBOUND_MLDSA_MONTMUL th0') in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Comb(Const("arm_mldsa_barmul",_),kb),t) ->
      let ktm,btm = dest_pair kb
      and th0 = rule t in
      let th0' =
        WEAKEN_INTCONG_RULE (num 8380417) th0 in
      let th1 =
        SPECL [ktm;btm]
          (MATCH_MP CONGBOUND_ARM_MLDSA_BARMUL th0') in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Const("word_sx",_),t) ->
      let th0 = rule t in
      let tyin =
        type_match
          (type_of
            (rator
              (rand
                (lhand
                  (funpow 4 rand
                    (snd(dest_forall
                      (concl CONGBOUND_WORD_SX))))))))
          (type_of(rator tm)) [] in
      let th1 =
        MATCH_MP (INST_TYPE tyin CONGBOUND_WORD_SX) th0 in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Const("word_neg",_),t) ->
      let th1 = MATCH_MP CONGBOUND_WORD_NEG (rule t) in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Comb(Const("word_add",_),ltm),rtm) ->
      let lth = rule ltm
      and rth = rule rtm in
      let th1 =
        MATCH_MP CONGBOUND_WORD_ADD
          (UNIFY_INTCONG_RULE lth rth) in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Comb(Const("word_sub",_),ltm),rtm) ->
      let lth = rule ltm
      and rth = rule rtm in
      let th1 =
        MATCH_MP CONGBOUND_WORD_SUB
          (UNIFY_INTCONG_RULE lth rth) in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | Comb(Comb(Const("word_mul",_),ltm),rtm) ->
      let lth = rule ltm
      and rth = rule rtm in
      let th1 =
        MATCH_MP CONGBOUND_WORD_MUL
          (UNIFY_INTCONG_RULE lth rth) in
      CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
  | _ ->
      CONCL_BOUNDS_RULE(ISPEC tm CONGBOUND_ATOM);;

let RV32_MEMOIZED_ASM_CONGBOUND_RULE lfn =
  let cache = ref undefined in
  let rec rule tm =
    try apply lfn tm with Failure _ ->
    try apply !cache tm with Failure _ ->
    let th = RV32_ASM_CONGBOUND_STEP rule tm in
    cache := (tm |-> th) !cache;
    th in
  rule;;

(* The common abbreviation tactic recognizes ARM and x86 vector-register
   reads. The RV32 proof uses the same mechanism for scalar X-register reads,
   so keep that small specialization local. *)

let RV32_SIMPLIFY_ABBREV_TAC =
  let readable =
    can (term_match [] `read X (s:riscvstate):int32 = whatever`) in
  fun unfold_defs unfold_aux ->
    let pats =
      map (lhand o snd o strip_forall o concl) unfold_defs in
    let pam t =
      exists (fun p -> can(term_match [] p) t) pats in
    let ttac th (asl,w) =
      let th' =
        CONV_RULE
          (RAND_CONV
            (SIMD_SIMPLIFY_CONV (unfold_defs @ unfold_aux)))
          th in
      let asms =
        map snd
          (filter
            (is_local_definition unfold_defs o concl o snd)
            asl) in
      let th'' =
        GEN_REWRITE_RULE (RAND_CONV o TOP_DEPTH_CONV) asms th' in
      let tms =
        sort free_in (find_terms pam (rand(concl th''))) in
      (MP_TAC th'' THEN
       MAP_EVERY AUTO_ABBREV_TAC tms THEN
       DISCH_TAC) (asl,w) in
    TRY(FIRST_X_ASSUM(ttac o check (readable o concl)));;

(* Cache all powers of the ML-DSA root. The RV32 transform proofs evaluate
   thousands of concrete powers; using the generic modular exponentiation
   conversion at every occurrence makes those proofs impractically slow. *)

let MLDSA_ROOT_POWER_SUC = prove
 (`!n. (&1753 pow (SUC n)) rem &8380417 =
       (&1753 * ((&1753 pow n) rem &8380417)) rem &8380417`,
  GEN_TAC THEN REWRITE_TAC[INT_POW] THEN
  CONV_TAC INT_REM_DOWN_CONV THEN REFL_TAC);;

let MLDSA_ROOT_POWERS =
  let th0 = prove
   (`(&1753 pow 0) rem &8380417 = &1`,
    CONV_TAC INT_REDUCE_CONV) in
  let rec build n th acc =
    if n = 512 then Array.of_list (List.rev(th::acc)) else
    let th' =
      REWRITE_RULE[th]
       (SPEC (mk_small_numeral n) MLDSA_ROOT_POWER_SUC) in
    let th'' =
      CONV_RULE
       (LAND_CONV (LAND_CONV (RAND_CONV NUM_SUC_CONV)) THENC
        RAND_CONV INT_REDUCE_CONV) th' in
    build (n + 1) th'' (th::acc) in
  build 0 th0 [];;

let MLDSA_ROOT_POWER_PERIODIC = prove
 (`!n. (&1753 pow n) rem &8380417 =
       (&1753 pow (n MOD 512)) rem &8380417`,
  GEN_TAC THEN
  TRANS_TAC EQ_TRANS
   `(&1753 pow (512 * (n DIV 512) + n MOD 512)) rem &8380417` THEN
  CONJ_TAC THENL [REWRITE_TAC[DIVISION_SIMP]; ALL_TAC] THEN
  REWRITE_TAC[INT_POW_ADD; GSYM INT_POW_POW] THEN
  GEN_REWRITE_TAC LAND_CONV [GSYM INT_MUL_REM] THEN
  GEN_REWRITE_TAC (LAND_CONV o LAND_CONV o LAND_CONV)
   [GSYM INT_POW_REM] THEN
  REWRITE_TAC[MLDSA_ROOT_POWERS.(512); INT_POW_ONE; INT_REM_REM] THEN
  CONV_TAC (ONCE_DEPTH_CONV INT_REDUCE_CONV) THEN
  REWRITE_TAC[INT_MUL_LID; INT_REM_REM]);;

let MLDSA_ROOT_POWER_CONV tm =
  match tm with
    Comb(Comb(Const("rem",_),
              Comb(Comb(Const("int_pow",_),a),n)),q)
    when a = `(&1753:int)` && q = `(&8380417:int)` && is_numeral n ->
      let r =
        Num.int_of_num (mod_num (dest_numeral n) (num 512)) in
      let pth = SPEC n MLDSA_ROOT_POWER_PERIODIC in
      let pth' =
        CONV_RULE
         (RAND_CONV (LAND_CONV (RAND_CONV NUM_MOD_CONV))) pth in
      TRANS pth' MLDSA_ROOT_POWERS.(r)
  | _ -> failwith "MLDSA_ROOT_POWER_CONV";;

let MLDSA_INVERSE_ROOT_POWER = prove
 (`!n. (&731434 pow n) rem &8380417 =
       (&1753 pow (511 * n)) rem &8380417`,
  GEN_TAC THEN
  ONCE_REWRITE_TAC[GSYM MLDSA_ROOT_POWERS.(511)] THEN
  REWRITE_TAC[INT_POW_REM; INT_POW_POW]);;

(* Bit reversal permutes the coefficient numbers 0 through 255. The final
   theorem uses that permutation to put the inverse NTT sum in the order used
   by the RV32 assembly. *)

let MLDSA_BITREVERSE8_BOUND = prove
 (`!n. bitreverse8 n < 256`,
  GEN_TAC THEN
  REWRITE_TAC[bitreverse8] THEN
  MP_TAC
   (ISPEC
     `word_reversefields 1 (word n:8 word)`
     VAL_BOUND) THEN
  CONV_TAC
   (DEPTH_CONV DIMINDEX_CONV THENC NUM_REDUCE_CONV));;

let MLDSA_BITREVERSE8_INVOLUTION = prove
 (`!n. n < 256
       ==> bitreverse8 (bitreverse8 n) = n`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC
   [bitreverse8; WORD_VAL;
    WORD_REVERSEFIELDS_REVERSEFIELDS;
    VAL_WORD; DIMINDEX_8] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  ASM_SIMP_TAC[MOD_LT]);;

let MLDSA_BITREVERSE8_INJECTIVE = prove
 (`!x y.
     x < 256 /\ y < 256 /\
     bitreverse8 x = bitreverse8 y
     ==> x = y`,
  REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o AP_TERM `bitreverse8`) THEN
  ASM_SIMP_TAC[MLDSA_BITREVERSE8_INVOLUTION]);;

let MLDSA_ISUM_BITREVERSE8 = prove
 (`!f:num->int.
     isum (0..255) (f o bitreverse8) =
     isum (0..255) f`,
  GEN_TAC THEN
  MATCH_MP_TAC ISUM_INJECTION THEN
  REWRITE_TAC[FINITE_NUMSEG] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[IN_NUMSEG] THEN
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[LE_0] THEN
    MP_TAC(SPEC `x:num` MLDSA_BITREVERSE8_BOUND) THEN
    ARITH_TAC;
    REWRITE_TAC[IN_NUMSEG] THEN
    REPEAT STRIP_TAC THEN
    MATCH_MP_TAC MLDSA_BITREVERSE8_INJECTIVE THEN
    ASM_REWRITE_TAC[] THEN
    ASM_ARITH_TAC]);;

let MLDSA_BITREVERSE_INVERSE_NTT_REORDERED = prove
 (`!f:num->int. !k.
     mldsa_bitreverse_inverse_ntt f k =
     (&2 pow 24 *
      isum (0..255)
       (\j. f j *
            &731434 pow ((2 * bitreverse8 j + 1) * k)))
     rem &8380417`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC
   [mldsa_bitreverse_inverse_ntt; arm_mldsa_inverse_ntt] THEN
  MATCH_MP_TAC(MESON[] `(x:int) = y ==> x rem q = y rem q`) THEN
  MATCH_MP_TAC(MESON[] `(x:int) = y ==> c * x = c * y`) THEN
  let h =
   `\j. (f:num->int) j *
        &731434 pow ((2 * bitreverse8 j + 1) * k)` in
  TRANS_TAC EQ_TRANS
   (subst [h,`H:num->int`]
     `isum (0..255) (H o bitreverse8)`) THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC ISUM_EQ THEN
    REWRITE_TAC[IN_NUMSEG; o_THM] THEN
    REPEAT STRIP_TAC THEN
    ASM_SIMP_TAC
     [MLDSA_BITREVERSE8_INVOLUTION;
      ARITH_RULE `x <= 255 ==> x < 256`];
    MATCH_ACCEPT_TAC
     (SPEC h MLDSA_ISUM_BITREVERSE8)]);;
