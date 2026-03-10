(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Common specifications and tactics for AArch64 ML-DSA proofs.              *)
(* This is a trimmed-down version of s2n-bignum's mlkem_mldsa.ml            *)
(* containing only the ARM ML-DSA relevant definitions and theorems.         *)
(* ========================================================================= *)

needs "Library/words.ml";;
needs "Library/isum.ml";;

(* ------------------------------------------------------------------------- *)
(* Bit-reversing order as used in the standard/default order.                *)
(* ------------------------------------------------------------------------- *)

let bitreverse8 = define
 `bitreverse8(n) = val(word_reversefields 1 (word n:8 word))`;;

let reorder = define
 `reorder p (a:num->int) = \i. a(p i)`;;

(* ------------------------------------------------------------------------- *)
(* The precise specs of the actual ARM code for ML-DSA.                      *)
(* ------------------------------------------------------------------------- *)

let arm_mldsa_pure_forward_ntt = define
 `arm_mldsa_pure_forward_ntt f k =
    isum (0..255) (\j. f j * &1753 pow ((2 * k + 1) * j))
    rem &8380417`;;

let arm_mldsa_forward_ntt = define
 `arm_mldsa_forward_ntt f k =
    isum (0..255) (\j. f j * &1753 pow ((2 * bitreverse8 k + 1) * j))
    rem &8380417`;;

let ARM_MLDSA_FORWARD_NTT = prove
 (`arm_mldsa_forward_ntt = reorder bitreverse8 o arm_mldsa_pure_forward_ntt`,
  REWRITE_TAC[FUN_EQ_THM; o_DEF; reorder] THEN
  REWRITE_TAC[arm_mldsa_forward_ntt; arm_mldsa_pure_forward_ntt]);;

(* ------------------------------------------------------------------------- *)
(* Explicit computation rules to evaluate mod-8380417 powers less naively.   *)
(* ------------------------------------------------------------------------- *)

let BITREVERSE8_CLAUSES = end_itlist CONJ (map
 (GEN_REWRITE_CONV I [bitreverse8] THENC DEPTH_CONV WORD_NUM_RED_CONV)
 (map (curry mk_comb `bitreverse8` o mk_small_numeral) (0--255)));;

let ARM_MLDSA_FORWARD_NTT_ALT = prove
 (`arm_mldsa_forward_ntt f k =
   isum (0..255)
        (\j. f j *
             (&1753 pow ((2 * bitreverse8 k + 1) * j)) rem &8380417)
    rem &8380417`,
  REWRITE_TAC[arm_mldsa_forward_ntt] THEN MATCH_MP_TAC
   (REWRITE_RULE[] (ISPEC
      `(\x y. x rem &8380417 = y rem &8380417)` ISUM_RELATED)) THEN
  REWRITE_TAC[INT_REM_EQ; FINITE_NUMSEG; INT_CONG_ADD] THEN
  X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM INT_OF_NUM_REM; GSYM INT_OF_NUM_CLAUSES;
              GSYM INT_REM_EQ] THEN
  CONV_TAC INT_REM_DOWN_CONV THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN CONV_TAC INT_ARITH);;

let ARM_MLDSA_FORWARD_NTT_CONV =
  GEN_REWRITE_CONV I [ARM_MLDSA_FORWARD_NTT_ALT] THENC
  LAND_CONV EXPAND_ISUM_CONV THENC
  DEPTH_CONV NUM_RED_CONV THENC
  GEN_REWRITE_CONV ONCE_DEPTH_CONV [BITREVERSE8_CLAUSES] THENC
  DEPTH_CONV NUM_RED_CONV THENC
  GEN_REWRITE_CONV DEPTH_CONV [INT_OF_NUM_POW; INT_OF_NUM_REM] THENC
  ONCE_DEPTH_CONV EXP_MOD_CONV THENC INT_REDUCE_CONV;;

(* ------------------------------------------------------------------------- *)
(* Abbreviate the Barrett multiplication pattern in the ARM code.            *)
(* ------------------------------------------------------------------------- *)

let arm_mldsa_barmul = define
 `arm_mldsa_barmul (k,b) (a:int32):int32 =
  word_sub (word_mul a b)
           (word_mul (iword_saturate((&2 * ival a * k + &2147483648) div &4294967296))
                     (word 8380417))`;;

(* ------------------------------------------------------------------------- *)
(* From |- (x == y) (mod m) /\ P   to   |- (x == y) (mod n) /\ P           *)
(* ------------------------------------------------------------------------- *)

let WEAKEN_INTCONG_RULE =
  let prule = (MATCH_MP o prove)
   (`(x:int == y) (mod m) ==> !n. m rem n = &0 ==> (x == y) (mod n)`,
    REWRITE_TAC[INT_REM_EQ_0] THEN INTEGER_TAC)
  and conv = GEN_REWRITE_CONV I [INT_REM_ZERO; INT_REM_REFL] ORELSEC
             INT_REM_CONV
  and zth = REFL `&0:int` in
  let lrule n th =
    let th1 = SPEC (mk_intconst n) (prule th) in
    let th2 = LAND_CONV conv (lhand(concl th1)) in
    MP th1 (EQ_MP (SYM th2) zth) in
  fun n th ->
    let th1,th2 = CONJ_PAIR th in
    CONJ (lrule n th1) th2;;

(* ------------------------------------------------------------------------- *)
(* Unify modulus and conjoin a pair of (x == y) (mod m) /\ P theorems.      *)
(* ------------------------------------------------------------------------- *)

let UNIFY_INTCONG_RULE th1 th2 =
  let p1 = dest_intconst (rand(rand(lhand(concl th1))))
  and p2 = dest_intconst (rand(rand(lhand(concl th2)))) in
  let d = gcd_num p1 p2 in
  CONJ (WEAKEN_INTCONG_RULE d th1) (WEAKEN_INTCONG_RULE d th2);;

(* ------------------------------------------------------------------------- *)
(* Process list of inequality into standard congbounds for atomic terms.     *)
(* ------------------------------------------------------------------------- *)

let DIMINDEX_INT_REDUCE_CONV =
  DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC DIMINDEX_CONV) THENC
  INT_REDUCE_CONV;;

let PROCESS_BOUND_ASSUMPTIONS =
  let cth = prove
   (`(ival x <= b <=>
      --(&2 pow (dimindex(:N) - 1)) <= ival x /\ ival x <= b) /\
     (b <= ival x <=>
      b <= ival x /\ ival x <= &2 pow (dimindex(:N) - 1) - &1) /\
     (ival(x:N word) > b <=>
      b + &1 <= ival x /\ ival x <= &2 pow (dimindex(:N) - 1) - &1) /\
     (b > ival(x:N word) <=>
      --(&2 pow (dimindex(:N) - 1)) <= ival x /\ ival x <= b - &1) /\
     (ival(x:N word) >= b <=>
      b <= ival x /\ ival x <= &2 pow (dimindex(:N) - 1) - &1) /\
     (b >= ival(x:N word) <=>
      --(&2 pow (dimindex(:N) - 1)) <= ival x /\ ival x <= b) /\
     (ival(x:N word) < b <=>
      --(&2 pow (dimindex(:N) - 1)) <= ival x /\ ival x <= b - &1) /\
     (b < ival(x:N word) <=>
     b + &1 <= ival x /\ ival x <= &2 pow (dimindex(:N) - 1) - &1) /\
     (abs(ival(x:N word)) <= b <=>
      --b <= ival x /\ ival x <= b) /\
     (abs(ival(x:N word)) < b <=>
      &1 - b <= ival x /\ ival x <= b - &1)`,
    REWRITE_TAC[IVAL_BOUND; INT_ARITH `x:int <= y - &1 <=> x < y`] THEN
    INT_ARITH_TAC)
  and pth = prove
   (`!l u (x:N word).
          l <= ival x /\ ival x <= u
          ==> (ival x == ival x) (mod &0) /\ l <= ival x /\ ival x <= u`,
    REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN INTEGER_TAC) in
  let rule =
    MATCH_MP pth o
    CONV_RULE (BINOP2_CONV (LAND_CONV DIMINDEX_INT_REDUCE_CONV)
                           (RAND_CONV DIMINDEX_INT_REDUCE_CONV)) o
    GEN_REWRITE_RULE I [cth] in
  let rec process lfn ths =
    match ths with
      [] -> lfn
    | th::oths ->
          let lfn' =
            try let th' = rule th in
                let tm = rand(concl th') in
                if is_intconst (rand(rand tm)) && is_intconst (lhand(lhand tm))
                then (rand(lhand(rand tm)) |-> th') lfn
                else lfn
            with Failure _ -> lfn in
          process lfn' oths in
  process undefined;;

(* ------------------------------------------------------------------------- *)
(* Congruence-and-bound propagation, just recursion on the expression tree.  *)
(* ------------------------------------------------------------------------- *)

let CONGBOUND_CONST = prove
 (`!(x:N word) n.
        ival x = n
        ==> (ival x == n) (mod &0) /\ n <= ival x /\ ival x <= n`,
  REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[INT_LE_REFL] THEN INTEGER_TAC);;

let CONGBOUND_ATOM = prove
 (`!x:N word. (ival x == ival x) (mod &0) /\
              --(&2 pow (dimindex(:N) - 1)) <= ival x /\
              ival x <= &2 pow (dimindex(:N) - 1) - &1`,
  GEN_TAC THEN REWRITE_TAC[INT_ARITH `x:int <= y - &1 <=> x < y`] THEN
  REWRITE_TAC[IVAL_BOUND] THEN INTEGER_TAC);;

let CONGBOUND_ATOM_GEN = prove
 (`!x:N word. abs(ival x) <= n
              ==> (ival x == ival x) (mod &0) /\
                  --n <= ival x /\ ival x <= n`,
  REWRITE_TAC[INTEGER_RULE `(x:int == x) (mod n)`] THEN INT_ARITH_TAC);;

let CONGBOUND_IWORD = prove
 (`!x. ((x == x') (mod p) /\ l <= x /\ x <= u)
       ==> --(&2 pow (dimindex(:N) - 1)) <= l /\
           u <= &2 pow (dimindex(:N) - 1) - &1
           ==> (ival(iword x:N word) == x') (mod p) /\
               l <= ival(iword x:N word) /\ ival(iword x:N word) <= u`,
  GEN_TAC THEN STRIP_TAC THEN STRIP_TAC THEN REWRITE_TAC[word_sx] THEN
  W(MP_TAC o PART_MATCH (lhand o rand) IVAL_IWORD o
    lhand o rand o rand o snd) THEN
  ANTS_TAC THENL [ASM_INT_ARITH_TAC; DISCH_THEN SUBST1_TAC] THEN
  ASM_REWRITE_TAC[]);;

let CONGBOUND_WORD_SX = prove
 (`!x:M word.
        ((ival x == x') (mod p) /\ l <= ival x /\ ival x <= u)
        ==> --(&2 pow (dimindex(:N) - 1)) <= l /\
            u <= &2 pow (dimindex(:N) - 1) - &1
            ==> (ival(word_sx x:N word) == x') (mod p) /\
                l <= ival(word_sx x:N word) /\ ival(word_sx x:N word) <= u`,
  REWRITE_TAC[word_sx; CONGBOUND_IWORD]);;

let CONGBOUND_WORD_NEG = prove
 (`!x:N word.
        ((ival x == x') (mod p) /\ lx <= ival x /\ ival x <= ux)
        ==> --lx <= &2 pow (dimindex(:N) - 1) - &1
            ==> (ival(word_neg x) == --x') (mod p) /\
                --ux <= ival(word_neg x) /\
                ival(word_neg x) <= --lx`,
  GEN_TAC THEN STRIP_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `ival(word_neg x:N word) = --(ival x)` SUBST1_TAC THENL
   [REPEAT(POP_ASSUM MP_TAC) THEN WORD_ARITH_TAC;
    ASM_SIMP_TAC[INTEGER_RULE
     `(x:int == x') (mod p) ==> (--x == --x') (mod p)`] THEN
    ASM_ARITH_TAC]);;

let CONGBOUND_WORD_ADD = prove
 (`!x y:N word.
        ((ival x == x') (mod p) /\ lx <= ival x /\ ival x <= ux) /\
        ((ival y == y') (mod p) /\ ly <= ival y /\ ival y <= uy)
        ==> --(&2 pow (dimindex(:N) - 1)) <= lx + ly /\
            ux + uy <= &2 pow (dimindex(:N) - 1) - &1
            ==> (ival(word_add x y) == x' + y') (mod p) /\
                lx + ly <= ival(word_add x y) /\
                ival(word_add x y) <= ux + uy`,
  REPEAT GEN_TAC THEN REWRITE_TAC[WORD_ADD_IMODULAR; imodular] THEN
  STRIP_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_IMP] CONGBOUND_IWORD) THEN
  ASM_SIMP_TAC[INT_CONG_ADD] THEN ASM_INT_ARITH_TAC);;

let CONGBOUND_WORD_SUB = prove
 (`!x y:N word.
        ((ival x == x') (mod p) /\ lx <= ival x /\ ival x <= ux) /\
        ((ival y == y') (mod p) /\ ly <= ival y /\ ival y <= uy)
        ==> --(&2 pow (dimindex(:N) - 1)) <= lx - uy /\
            ux - ly <= &2 pow (dimindex(:N) - 1) - &1
            ==> (ival(word_sub x y) == x' - y') (mod p) /\
                lx - uy <= ival(word_sub x y) /\
                ival(word_sub x y) <= ux - ly`,
  REPEAT GEN_TAC THEN REWRITE_TAC[WORD_SUB_IMODULAR; imodular] THEN
  STRIP_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_IMP] CONGBOUND_IWORD) THEN
  ASM_SIMP_TAC[INT_CONG_SUB] THEN ASM_INT_ARITH_TAC);;

let CONGBOUND_WORD_MUL = prove
 (`!x y:N word.
        ((ival x == x') (mod p) /\ lx <= ival x /\ ival x <= ux) /\
        ((ival y == y') (mod p) /\ ly <= ival y /\ ival y <= uy)
        ==> --(&2 pow (dimindex(:N) - 1))
            <= min (lx * ly) (min (lx * uy) (min (ux * ly) (ux * uy))) /\
            max (lx * ly) (max (lx * uy) (max (ux * ly) (ux * uy)))
            <= &2 pow (dimindex(:N) - 1) - &1
            ==> (ival(word_mul x y) == x' * y') (mod p) /\
                min (lx * ly) (min (lx * uy) (min (ux * ly) (ux * uy)))
                <= ival(word_mul x y) /\
                ival(word_mul x y)
                <= max (lx * ly) (max (lx * uy) (max (ux * ly) (ux * uy)))`,
  let lemma = prove
     (`l:int <= x /\ x <= u
       ==> !a. a * l <= a * x /\ a * x <= a * u \/
               a * u <= a * x /\ a * x <= a * l`,
      MESON_TAC[INT_LE_NEGTOTAL; INT_LE_LMUL;
                INT_ARITH `a * x:int <= a * y <=> --a * y <= --a * x`]) in
  REPEAT GEN_TAC THEN
  DISCH_THEN(CONJUNCTS_THEN(CONJUNCTS_THEN2 ASSUME_TAC MP_TAC)) THEN
  DISCH_THEN(ASSUME_TAC o SPEC `ival(x:N word)` o MATCH_MP lemma) THEN
  DISCH_THEN(MP_TAC o MATCH_MP lemma) THEN DISCH_THEN(fun th ->
        ASSUME_TAC(SPEC `ly:int` th) THEN ASSUME_TAC(SPEC `uy:int` th)) THEN
  REWRITE_TAC[WORD_MUL_IMODULAR; imodular] THEN STRIP_TAC THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_IMP] CONGBOUND_IWORD) THEN
  ASM_SIMP_TAC[INT_CONG_MUL] THEN ASM_INT_ARITH_TAC);;

(* ------------------------------------------------------------------------- *)
(* Congruence and bounds for arm_mldsa_barmul.                               *)
(* ------------------------------------------------------------------------- *)

let CONGBOUND_ARM_MLDSA_BARMUL = prove
 (`!a a' l u.
        ((ival a == a') (mod &8380417) /\ l <= ival a /\ ival a <= u)
        ==> !k b. abs(k) <= &2147483647 /\
                  (max (abs l) (abs u) *
                   abs(&4294967296 * ival b - &16760834 * k) + &17996812765888511) div &4294967296
                  <= &2147483647
                  ==> (ival(arm_mldsa_barmul(k,b) a) == a' * ival b) (mod &8380417) /\
                      --(max (abs l) (abs u) *
                         abs(&4294967296 * ival b - &16760834 * k) + &17996808470921216)
                         div &4294967296
                      <= ival(arm_mldsa_barmul(k,b) a) /\
                      ival(arm_mldsa_barmul(k,b) a) <=
                      (max (abs l) (abs u) * abs(&4294967296 * ival b - &16760834 * k) +
                       &17996812765888511) div &4294967296`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[INT_ABS_BOUNDS] THEN
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[arm_mldsa_barmul] THEN
  REWRITE_TAC[iword_saturate; word_INT_MIN; word_INT_MAX; DIMINDEX_32] THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
  REPEAT(COND_CASES_TAC THENL
   [FIRST_X_ASSUM(MATCH_MP_TAC o MATCH_MP (MESON[] `p ==> ~p ==> q`)) THEN
    REWRITE_TAC[INT_GT; INT_NOT_LT] THEN ASM BOUNDER_TAC[];
    ASM_REWRITE_TAC[]]) THEN
  REWRITE_TAC[WORD_RULE
   `word_sub (word_mul a b) (word_mul (iword k) (word c)) =
    iword(ival a * ival b - &c * k)`] THEN
  MATCH_MP_TAC(MESON[]
   `(x == k) (mod n) /\
    (a <= x /\ x <= b ==> ival(iword x:int32) = x) /\
    (a <= x /\ x <= b)
    ==> (ival(iword x:int32) == k) (mod n) /\
        a <= ival(iword x:int32) /\ ival(iword x:int32) <= b`) THEN
  ASM_SIMP_TAC[INTEGER_RULE
   `(a:int == a') (mod n) ==> (a * b - n * c == a' * b) (mod n)`] THEN
  CONJ_TAC THENL
   [REPEAT STRIP_TAC THEN MATCH_MP_TAC IVAL_IWORD THEN
    REWRITE_TAC[DIMINDEX_32; ARITH] THEN ASM_INT_ARITH_TAC;
    ALL_TAC] THEN
  MATCH_MP_TAC(INT_ARITH
   `&4294967296 * l + &17996808470921216 <= a * (&4294967296 * b - &16760834 * k) /\
    a * (&4294967296 * b - &16760834 * k) <= &4294967296 * u - &17996808470921216
    ==> l <= a * b - &8380417 * (&2 * a * k + &2147483648) div &4294967296 /\
        a * b - &8380417 * (&2 * a * k + &2147483648) div &4294967296 <= u`) THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC(INT_ARITH `abs(y):int <= --x ==> x <= y`);
    MATCH_MP_TAC(INT_ARITH `abs(y):int <= x ==> y <= x`)] THEN
  REWRITE_TAC[INT_ABS_MUL] THEN
  TRANS_TAC INT_LE_TRANS
   `max (abs l) (abs u) * abs(&4294967296 * ival(b:int32) - &16760834 * k)` THEN
  ASM_SIMP_TAC[INT_LE_RMUL; INT_ABS_POS; INT_ARITH
   `l:int <= x /\ x <= u ==> abs x <= max (abs l) (abs u)`] THEN
  CONV_TAC INT_ARITH);;

(* ------------------------------------------------------------------------- *)
(* Bound propagation rules and congruence-bound propagation engine.          *)
(* ------------------------------------------------------------------------- *)

let CONCL_BOUNDS_RULE =
  CONV_RULE(BINOP2_CONV
          (LAND_CONV(RAND_CONV DIMINDEX_INT_REDUCE_CONV))
          (BINOP2_CONV
           (LAND_CONV DIMINDEX_INT_REDUCE_CONV)
           (RAND_CONV DIMINDEX_INT_REDUCE_CONV)));;

let SIDE_ELIM_RULE th =
  MP th (EQT_ELIM(DIMINDEX_INT_REDUCE_CONV(lhand(concl th))));;

let rec ASM_CONGBOUND_RULE lfn tm =
    try apply lfn tm with Failure _ ->
    match tm with
      Comb(Const("word",_),n) when is_numeral n ->
        let th1 = ISPEC tm CONGBOUND_CONST in
        let th2 = WORD_RED_CONV(lhand(lhand(snd(strip_forall(concl th1))))) in
        MATCH_MP th1 th2
    | Comb(Const("iword",_),n) when is_intconst n ->
        let th0 = WORD_IWORD_CONV tm in
        let th1 = ISPEC (rand(concl th0)) CONGBOUND_CONST in
        let th2 = WORD_RED_CONV(lhand(lhand(snd(strip_forall(concl th1))))) in
        SUBS[SYM th0] (MATCH_MP th1 th2)
    | Comb(Comb(Const("arm_mldsa_barmul",_),kb),t) ->
        let ktm,btm = dest_pair kb and th0 = ASM_CONGBOUND_RULE lfn t in
        let th0' = WEAKEN_INTCONG_RULE (num 8380417) th0 in
        let th1 = SPECL [ktm;btm] (MATCH_MP CONGBOUND_ARM_MLDSA_BARMUL th0') in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | Comb(Const("word_sx",_),t) ->
        let th0 = ASM_CONGBOUND_RULE lfn t in
        let tyin = type_match
         (type_of(rator(rand(lhand(funpow 4 rand (snd(dest_forall
            (concl CONGBOUND_WORD_SX)))))))) (type_of(rator tm)) [] in
        let th1 = MATCH_MP (INST_TYPE tyin CONGBOUND_WORD_SX) th0 in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | Comb(Const("word_neg",_),t) ->
        let th0 = ASM_CONGBOUND_RULE lfn t in
        let th1 = MATCH_MP CONGBOUND_WORD_NEG th0 in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | Comb(Comb(Const("word_add",_),ltm),rtm) ->
        let lth = ASM_CONGBOUND_RULE lfn ltm
        and rth = ASM_CONGBOUND_RULE lfn rtm in
        let th1 = MATCH_MP CONGBOUND_WORD_ADD (UNIFY_INTCONG_RULE lth rth) in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | Comb(Comb(Const("word_sub",_),ltm),rtm) ->
        let lth = ASM_CONGBOUND_RULE lfn ltm
        and rth = ASM_CONGBOUND_RULE lfn rtm in
        let th1 = MATCH_MP CONGBOUND_WORD_SUB (UNIFY_INTCONG_RULE lth rth) in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | Comb(Comb(Const("word_mul",_),ltm),rtm) ->
        let lth = ASM_CONGBOUND_RULE lfn ltm
        and rth = ASM_CONGBOUND_RULE lfn rtm in
        let th1 = MATCH_MP CONGBOUND_WORD_MUL (UNIFY_INTCONG_RULE lth rth) in
        CONCL_BOUNDS_RULE(SIDE_ELIM_RULE th1)
    | _ -> CONCL_BOUNDS_RULE(ISPEC tm CONGBOUND_ATOM);;

let GEN_CONGBOUND_RULE aboths =
  ASM_CONGBOUND_RULE (PROCESS_BOUND_ASSUMPTIONS aboths);;

let CONGBOUND_RULE = GEN_CONGBOUND_RULE [];;

let rec LOCAL_CONGBOUND_RULE lfn asms =
  match asms with
    [] -> lfn
  | th::ths ->
      let bod,var = dest_eq (concl th) in
      let th1 = ASM_CONGBOUND_RULE lfn bod in
      let th2 = SUBS[th] th1 in
      let lfn' = (var |-> th2) lfn in
      LOCAL_CONGBOUND_RULE lfn' ths;;

(* ------------------------------------------------------------------------- *)
(* Simplify SIMD cruft and fold relevant definitions when encountered.       *)
(* The ABBREV form also introduces abbreviations for relevant subterms.      *)
(* ------------------------------------------------------------------------- *)

let SIMD_SIMPLIFY_CONV unfold_defs =
  TOP_DEPTH_CONV
   (REWR_CONV WORD_SUBWORD_AND ORELSEC WORD_SIMPLE_SUBWORD_CONV) THENC
  DEPTH_CONV WORD_NUM_RED_CONV THENC
  REWRITE_CONV (map GSYM unfold_defs);;

let SIMD_SIMPLIFY_TAC unfold_defs =
  let arm_simdable = can (term_match [] `read X (s:armstate):int128 = whatever`) in
  let x86_simdable = can (term_match [] `read X (s:x86state):int256 = whatever`) in
  let simdable tm = arm_simdable tm || x86_simdable tm in
  TRY(FIRST_X_ASSUM
   (ASSUME_TAC o
    CONV_RULE(RAND_CONV (SIMD_SIMPLIFY_CONV unfold_defs)) o
    check (simdable o concl)));;

let is_local_definition unfold_defs =
  let pats = map (lhand o snd o strip_forall o concl) unfold_defs in
  let pam t = exists (fun p -> can(term_match [] p) t) pats in
  fun tm -> is_eq tm && is_var(rand tm) && pam(lhand tm);;

let AUTO_ABBREV_TAC tm =
  let gv = genvar(type_of tm) in
  ABBREV_TAC(mk_eq(gv,tm));;

let SIMD_SIMPLIFY_ABBREV_TAC =
  let arm_simdable =
    can (term_match [] `read X (s:armstate):int128 = whatever`)
  and x86_simdable =
    can (term_match [] `read X (s:x86state):int256 = whatever`) in
  let simdable tm = arm_simdable tm || x86_simdable tm in
  fun unfold_defs unfold_aux ->
    let pats = map (lhand o snd o strip_forall o concl) unfold_defs in
    let pam t = exists (fun p -> can(term_match [] p) t) pats in
    let ttac th (asl,w) =
      let th' = CONV_RULE(RAND_CONV
                 (SIMD_SIMPLIFY_CONV (unfold_defs @ unfold_aux))) th in
      let asms =
        map snd (filter (is_local_definition unfold_defs o concl o snd) asl) in
      let th'' = GEN_REWRITE_RULE (RAND_CONV o TOP_DEPTH_CONV) asms th' in
      let tms = sort free_in (find_terms pam (rand(concl th''))) in
      (MP_TAC th'' THEN MAP_EVERY AUTO_ABBREV_TAC tms THEN DISCH_TAC) (asl,w) in
  TRY(FIRST_X_ASSUM(ttac o check (simdable o concl)));;
