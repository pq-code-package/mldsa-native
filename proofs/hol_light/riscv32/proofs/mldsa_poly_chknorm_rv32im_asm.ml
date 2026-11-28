(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Infinity norm check of a polynomial.                                      *)
(* ========================================================================= *)

(* This file proves that the RV32 routine returns 1 if some coefficient x of
   a satisfies |x| >= B, and 0 otherwise.
   `MLDSA_POLY_CHKNORM_SUBROUTINE_CORRECT` states this for a call of the
   routine, and `MLDSA_POLY_CHKNORM_SUBROUTINE_SAFE` proves that the call
   reads only a and that its trace does not depend on a or B.

   The theorem holds for all coefficients and all 0 < B < 2^31: the routine
   tests whether the unsigned value x + (B - 1) exceeds 2B - 2. *)

needs "s2n_bignum/riscv/proofs/base.ml";;

(**** print_literal_from_elf
 "riscv32/mldsa/mldsa_poly_chknorm_rv32im_asm.o";;
 ****)

let mldsa_poly_chknorm_mc = define_assert_from_elf
  "mldsa_poly_chknorm_mc"
  "riscv32/mldsa/mldsa_poly_chknorm_rv32im_asm.o"
(*** BYTECODE START ***)
[
  0xfff58693;       (* riscv_ADDI A3 A1 (word 4294967295) *)
  0x00d68733;       (* riscv_ADD A4 A3 A3 *)
  0x00000793;       (* riscv_ADDI A5 ZERO (word 0) *)
  0x40050613;       (* riscv_ADDI A2 A0 (word 1024) *)
  0x00052283;       (* riscv_LW T0 A0 (word 0) *)
  0x00452303;       (* riscv_LW T1 A0 (word 4) *)
  0x00852383;       (* riscv_LW T2 A0 (word 8) *)
  0x00c52e03;       (* riscv_LW T3 A0 (word 12) *)
  0x00d282b3;       (* riscv_ADD T0 T0 A3 *)
  0x005732b3;       (* riscv_SLTU T0 A4 T0 *)
  0x0057e7b3;       (* riscv_OR A5 A5 T0 *)
  0x00d30333;       (* riscv_ADD T1 T1 A3 *)
  0x00673333;       (* riscv_SLTU T1 A4 T1 *)
  0x0067e7b3;       (* riscv_OR A5 A5 T1 *)
  0x00d383b3;       (* riscv_ADD T2 T2 A3 *)
  0x007733b3;       (* riscv_SLTU T2 A4 T2 *)
  0x0077e7b3;       (* riscv_OR A5 A5 T2 *)
  0x00de0e33;       (* riscv_ADD T3 T3 A3 *)
  0x01c73e33;       (* riscv_SLTU T3 A4 T3 *)
  0x01c7e7b3;       (* riscv_OR A5 A5 T3 *)
  0x01050513;       (* riscv_ADDI A0 A0 (word 16) *)
  0xfac51ee3;       (* riscv_BNE A0 A2 (word 4294967228) *)
  0x00078513;       (* riscv_ADDI A0 A5 (word 0) *)
  0x00008067       (* riscv_JALR ZERO RA (word 0) *)
];;
(*** BYTECODE END ***)

let MLDSA_POLY_CHKNORM_EXEC = RISCV_MK_EXEC_RULE mldsa_poly_chknorm_mc;;

let LENGTH_MLDSA_POLY_CHKNORM_MC =
  REWRITE_CONV[mldsa_poly_chknorm_mc] `LENGTH mldsa_poly_chknorm_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

(* ------------------------------------------------------------------------- *)
(* One coefficient: with d = B - 1, the unsigned test d + d < x + d holds    *)
(* exactly when |x| >= B.                                                    *)
(* ------------------------------------------------------------------------- *)

let IVAL_WORD_NEG_POS = prove
 (`!b:int32. &0 < ival b ==> ival(word_neg b) = --(ival b)`,
  GEN_TAC THEN DISCH_TAC THEN
  GEN_REWRITE_TAC (LAND_CONV o RAND_CONV o RAND_CONV) [GSYM IWORD_IVAL] THEN
  REWRITE_TAC[GSYM IWORD_INT_NEG] THEN
  MATCH_MP_TAC IVAL_IWORD THEN
  MP_TAC(ISPEC `b:int32` IVAL_BOUND) THEN
  REWRITE_TAC[DIMINDEX_32] THEN CONV_TAC NUM_REDUCE_CONV THEN
  ASM_INT_ARITH_TAC);;

let RV32_CHKNORM_TEST = prove
 (`!x b:int32.
      &0 < ival b
      ==> (val(word_add (word_add b (word 4294967295))
                        (word_add b (word 4294967295)):int32) <
           val(word_add x (word_add b (word 4294967295)):int32) <=>
           abs(ival x) >= ival b)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(BITBLAST_RULE
   `!x b:int32.
      word_igt b (word 0)
      ==> (val(word_add (word_add b (word 4294967295))
                        (word_add b (word 4294967295)):int32) <
           val(word_add x (word_add b (word 4294967295)):int32) <=>
           word_ige x b \/ word_ile x (word_neg b))`) THEN
  DISCH_THEN(MP_TAC o SPECL [`x:int32`; `b:int32`]) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[WORD_IGT; IVAL_WORD_0] THEN ASM_INT_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN
  ASM_SIMP_TAC[WORD_IGE; WORD_ILE; IVAL_WORD_NEG_POS] THEN INT_ARITH_TAC);;

let COND_WORD_BITVAL_32 = prove
 (`!p. (if p then word 1 else word 0):int32 = word(bitval p)`,
  GEN_TAC THEN BOOL_CASES_TAC `p:bool` THEN REWRITE_TAC[BITVAL_CLAUSES]);;

let WORD_OR_BITVAL_32 = prove
 (`!p q. word_or (word(bitval p)) (word(bitval q)):int32 =
         word(bitval(p \/ q))`,
  REPEAT GEN_TAC THEN MAP_EVERY BOOL_CASES_TAC [`p:bool`; `q:bool`] THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC WORD_REDUCE_CONV);;

let CHKNORM_EXISTS_STEP = prove
 (`!P i. (?j. j < 4 * (i + 1) /\ P j) <=>
         (((((?j. j < 4 * i /\ P j) \/ P(4 * i)) \/ P(4 * i + 1)) \/
           P(4 * i + 2)) \/ P(4 * i + 3))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[ARITH_RULE
   `j < 4 * (i + 1) <=>
    j < 4 * i \/ j = 4 * i \/ j = 4 * i + 1 \/ j = 4 * i + 2 \/
    j = 4 * i + 3`] THEN
  MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Main loop: four coefficients per iteration.                               *)
(* ------------------------------------------------------------------------- *)

let ALIGNED4_A_OFFSET = prove
 (`!a:int32 n. aligned 4 a ==> aligned 4 (word_add a (word(4 * n)):int32)`,
  REPEAT STRIP_TAC THEN
  ASM_SIMP_TAC[ALIGNED_WORD_ADD_EQ; ALIGNED_WORD; DIMINDEX_32] THEN
  CONJ_TAC THENL
   [CONV_TAC NUM_DIVIDES_CONV;
    MATCH_MP_TAC DIVIDES_RMUL THEN REWRITE_TAC[DIVIDES_REFL]]);;

(* Instantiate the input invariant for coefficient 4 * i + k at the address
   the k-th load of the iteration uses. *)

let CHKNORM_LOAD_TAC k =
  let kk = mk_small_numeral k in
  let ii = mk_comb(mk_comb(`(+):num->num->num`, `4 * i`), kk) in
  let eqn = ARITH_RULE(mk_eq(mk_comb(`( * ) 4`, ii),
    mk_comb(mk_comb(`(+):num->num->num`, `16 * i`),
            mk_small_numeral (4 * k)))) in
  FIRST_ASSUM(fun th ->
    if is_forall(concl th) && vfree_in `x:num->int32` (concl th)
    then MP_TAC(SPEC ii th) else NO_TAC) THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[eqn; ADD_0] THEN DISCH_TAC THEN
  MP_TAC(SPECL [`a:int32`; ii] ALIGNED4_A_OFFSET) THEN
  ASM_REWRITE_TAC[eqn; ADD_0] THEN DISCH_TAC;;

let MLDSA_POLY_CHKNORM_CORRECT = prove
 (`!a b:int32 x:num->int32 pc.
    aligned 4 a /\ &0 < ival b
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_poly_chknorm_mc /\
           read PC s = word pc /\
           C_ARGUMENTS [a; b] s /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i))
      (\s. read PC s = word(pc + 92) /\
           C_RETURN s =
           word(bitval(?i. i < 256 /\ abs(ival(x i)) >= ival b)))
      (MAYCHANGE [PC; A0; A2; A3; A4; A5; T0; T1; T2; T3] ,,
       MAYCHANGE [events])`,
  MAP_EVERY X_GEN_TAC [`a:int32`; `b:int32`; `x:num->int32`; `pc:num`] THEN
  REWRITE_TAC[C_ARGUMENTS; C_RETURN] THEN REPEAT STRIP_TAC THEN
  ENSURES_WHILE_UP_TAC `64` `pc + 16` `pc + 84`
   `\i s. read A3 s = word_add b (word 4294967295) /\
          read A4 s = word_add (word_add b (word 4294967295))
                               (word_add b (word 4294967295)) /\
          read A2 s = word_add a (word 1024) /\
          read A0 s = word_add a (word(16 * i)) /\
          read A5 s =
          word(bitval(?j. j < 4 * i /\ abs(ival(x j)) >= ival b)) /\
          (!j. j < 256 ==>
               read(memory :> bytes32(word_add a (word(4 * j)))) s = x j)` THEN
  REPEAT CONJ_TAC THENL
   [CONV_TAC NUM_REDUCE_CONV;
    ENSURES_INIT_TAC "s0" THEN
    RISCV_STEPS_TAC MLDSA_POLY_CHKNORM_EXEC (1--4) THEN
    ENSURES_FINAL_STATE_TAC THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; ARITH_RULE `~(j < 0)`;
                    BITVAL_CLAUSES];
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    MAP_EVERY CHKNORM_LOAD_TAC [0; 1; 2; 3] THEN
    RISCV_STEPS_TAC MLDSA_POLY_CHKNORM_EXEC (1--17) THEN
    ENSURES_FINAL_STATE_TAC THEN
    ASM_SIMP_TAC[RV32_CHKNORM_TEST; COND_WORD_BITVAL_32;
                 WORD_OR_BITVAL_32] THEN
    REWRITE_TAC[CHKNORM_EXISTS_STEP] THEN
    CONV_TAC WORD_RULE;
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
    SUBGOAL_THEN
     `~(word_add a (word (16 * i)):int32 = word_add a (word 1024))`
    ASSUME_TAC THENL
     [REWRITE_TAC[WORD_RULE
       `word_add a (word x):int32 = word_add a (word y) <=>
        (word x:int32) = word y`] THEN
      REWRITE_TAC[WORD_EQ; DIMINDEX_32; CONG] THEN
      CONV_TAC NUM_REDUCE_CONV THEN
      SUBGOAL_THEN `16 * i < 4294967296`
       (fun th -> REWRITE_TAC[MATCH_MP MOD_LT th]) THEN
      ASM_ARITH_TAC;
      ALL_TAC] THEN
    RISCV_STEPS_TAC MLDSA_POLY_CHKNORM_EXEC [1] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];
    ENSURES_INIT_TAC "s0" THEN
    RISCV_STEPS_TAC MLDSA_POLY_CHKNORM_EXEC (1--2) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Subroutine form.                                                          *)
(* ------------------------------------------------------------------------- *)

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/rv32im/src/arith_native_rv32im.h *)

let MLDSA_POLY_CHKNORM_SUBROUTINE_CORRECT = prove
 (`!a b:int32 x:num->int32 pc returnaddress.
    aligned 4 a /\ aligned 4 returnaddress /\ &0 < ival b
    ==> ensures riscv
      (\s. aligned_bytes_loaded s (word pc) mldsa_poly_chknorm_mc /\
           read PC s = word pc /\
           read RA s = returnaddress /\
           C_ARGUMENTS [a; b] s /\
           (!i. i < 256 ==>
                read(memory :> bytes32(word_add a (word(4 * i)))) s = x i))
      (\s. read PC s = returnaddress /\
           C_RETURN s =
           word(bitval(?i. i < 256 /\ abs(ival(x i)) >= ival b)))
      MAYCHANGE_REGS_PERMITTED_BY_ABI`,
  REWRITE_TAC[fst MLDSA_POLY_CHKNORM_EXEC] THEN
  RISCV_ADD_RETURN_NOSTACK_TAC MLDSA_POLY_CHKNORM_EXEC
    (REWRITE_RULE[fst MLDSA_POLY_CHKNORM_EXEC] MLDSA_POLY_CHKNORM_CORRECT));;

(* ------------------------------------------------------------------------- *)
(* Constant-time and memory-safety proof.                                    *)
(* ------------------------------------------------------------------------- *)

needs "s2n_bignum/riscv/proofs/consttime.ml";;
needs "mldsa_native/riscv32/proofs/consttime_aux.ml";;

let mldsa_poly_chknorm_rv32im_signature =
  ([("a","int32_t[static 256]","true");
    ("b","int32_t","false")],
   "int",
   [("a","256",4)],
   [],
   []);;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    mldsa_poly_chknorm_rv32im_signature
    MLDSA_POLY_CHKNORM_SUBROUTINE_CORRECT
    MLDSA_POLY_CHKNORM_EXEC;;

let MLDSA_POLY_CHKNORM_SUBROUTINE_SAFE = time prove
 (`exists f_events.
     forall e a b pc returnaddress.
       aligned 4 a /\ aligned 4 returnaddress /\ &0 < ival b
       ==> ensures riscv
            (\s. aligned_bytes_loaded s (word pc) mldsa_poly_chknorm_mc /\
                 read PC s = word pc /\
                 read RA s = returnaddress /\
                 C_ARGUMENTS [a; b] s /\
                 read events s = e)
            (\s. read PC s = returnaddress /\
                 exists e2.
                   read events s = APPEND e2 e /\
                   e2 = f_events a pc returnaddress /\
                   memaccess_inbounds e2 [a,1024] [])
            (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars MLDSA_POLY_CHKNORM_EXEC);;
