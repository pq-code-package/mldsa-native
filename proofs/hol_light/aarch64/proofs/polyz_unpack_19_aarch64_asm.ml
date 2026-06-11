(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Functional correctness of polyz_unpack_19:                                *)
(* Unpack polynomial z with 20-bit packed coefficients (GAMMA1 = 2^19)       *)
(* Maps packed [0, 2^20-1] to signed [-(2^19-1), 2^19] via GAMMA1 - x       *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_polyz_unpack_consts.ml";;

(**** print_literal_from_elf "aarch64/mldsa/polyz_unpack_19_aarch64_asm.o";;
 ****)

let mldsa_polyz_unpack_19_mc = define_assert_from_elf
  "mldsa_polyz_unpack_19_mc" "aarch64/mldsa/polyz_unpack_19_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0x3dc00058;       (* arm_LDR Q24 X2 (Immediate_Offset (word 0)) *)
  0x3dc00459;       (* arm_LDR Q25 X2 (Immediate_Offset (word 16)) *)
  0x3dc0085a;       (* arm_LDR Q26 X2 (Immediate_Offset (word 32)) *)
  0x3dc00c5b;       (* arm_LDR Q27 X2 (Immediate_Offset (word 48)) *)
  0xd2c01f83;       (* arm_MOVZ X3 (word 252) 32 *)
  0x4e080c7c;       (* arm_DUP_GEN Q28 X3 64 128 *)
  0x4f00d5fd;       (* arm_MOVI Q29 (word 4503595333451775) *)
  0x4f00451e;       (* arm_MOVI Q30 (word 2251799814209536) *)
  0xd2800209;       (* arm_MOV X9 (rvalue (word 16)) *)
  0x4c40a020;       (* arm_LDP Q0 Q1 X1 No_Offset *)
  0x91006021;       (* arm_ADD X1 X1 (rvalue (word 24)) *)
  0x4cdf7022;       (* arm_LDR Q2 X1 (Postimmediate_Offset (word 16)) *)
  0x4e180004;       (* arm_TBL Q4 [Q0] Q24 128 *)
  0x4e192005;       (* arm_TBL2 Q5 Q0 Q1 Q25 128 *)
  0x4e1a0026;       (* arm_TBL Q6 [Q1] Q26 128 *)
  0x4e1b2027;       (* arm_TBL2 Q7 Q1 Q2 Q27 128 *)
  0x6ebc4484;       (* arm_USHL_VEC Q4 Q4 Q28 32 128 *)
  0x4e3d1c84;       (* arm_AND_VEC Q4 Q4 Q29 128 *)
  0x6ea487c4;       (* arm_SUB_VEC Q4 Q30 Q4 32 128 *)
  0x6ebc44a5;       (* arm_USHL_VEC Q5 Q5 Q28 32 128 *)
  0x4e3d1ca5;       (* arm_AND_VEC Q5 Q5 Q29 128 *)
  0x6ea587c5;       (* arm_SUB_VEC Q5 Q30 Q5 32 128 *)
  0x6ebc44c6;       (* arm_USHL_VEC Q6 Q6 Q28 32 128 *)
  0x4e3d1cc6;       (* arm_AND_VEC Q6 Q6 Q29 128 *)
  0x6ea687c6;       (* arm_SUB_VEC Q6 Q30 Q6 32 128 *)
  0x6ebc44e7;       (* arm_USHL_VEC Q7 Q7 Q28 32 128 *)
  0x4e3d1ce7;       (* arm_AND_VEC Q7 Q7 Q29 128 *)
  0x6ea787c7;       (* arm_SUB_VEC Q7 Q30 Q7 32 128 *)
  0x3d800405;       (* arm_STR Q5 X0 (Immediate_Offset (word 16)) *)
  0x3d800806;       (* arm_STR Q6 X0 (Immediate_Offset (word 32)) *)
  0x3d800c07;       (* arm_STR Q7 X0 (Immediate_Offset (word 48)) *)
  0x3c840404;       (* arm_STR Q4 X0 (Postimmediate_Offset (word 64)) *)
  0xf1000529;       (* arm_SUBS X9 X9 (rvalue (word 1)) *)
  0x54fffd01;       (* arm_BNE (word 2097056) *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let MLDSA_POLYZ_UNPACK_19_EXEC = ARM_MK_EXEC_RULE mldsa_polyz_unpack_19_mc;;

(* ------------------------------------------------------------------------- *)
(* Code length constants                                                     *)
(* ------------------------------------------------------------------------- *)

let LENGTH_MLDSA_POLYZ_UNPACK_19_MC =
  REWRITE_CONV[mldsa_polyz_unpack_19_mc] `LENGTH mldsa_polyz_unpack_19_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let MLDSA_POLYZ_UNPACK_19_PREAMBLE_LENGTH = new_definition
  `MLDSA_POLYZ_UNPACK_19_PREAMBLE_LENGTH = 0`;;

let MLDSA_POLYZ_UNPACK_19_POSTAMBLE_LENGTH = new_definition
  `MLDSA_POLYZ_UNPACK_19_POSTAMBLE_LENGTH = 4`;;

let MLDSA_POLYZ_UNPACK_19_CORE_START = new_definition
  `MLDSA_POLYZ_UNPACK_19_CORE_START = MLDSA_POLYZ_UNPACK_19_PREAMBLE_LENGTH`;;

let MLDSA_POLYZ_UNPACK_19_CORE_END = new_definition
  `MLDSA_POLYZ_UNPACK_19_CORE_END =
     LENGTH mldsa_polyz_unpack_19_mc - MLDSA_POLYZ_UNPACK_19_POSTAMBLE_LENGTH`;;

let LENGTH_SIMPLIFY_CONV_19 =
  REWRITE_CONV[LENGTH_MLDSA_POLYZ_UNPACK_19_MC;
              MLDSA_POLYZ_UNPACK_19_CORE_START; MLDSA_POLYZ_UNPACK_19_CORE_END;
              MLDSA_POLYZ_UNPACK_19_PREAMBLE_LENGTH;
              MLDSA_POLYZ_UNPACK_19_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV [ADD_0];;

(* ------------------------------------------------------------------------- *)
(* D=20 instantiations for SIMD infrastructure                               *)
(* ------------------------------------------------------------------------- *)

let BASE_SIMPS_D20 = mk_base_simps 20;;
let NUM_OF_WORDLIST_SPLIT_20_256 = mk_split_theorem 20 256 16;;
let READ_MEMORY_WBYTES_SPLIT_128_128_64 = prove
 (`t < 2 EXP 320
    ==> (read (memory :> wbytes a) (s:armstate) = (word t : 320 word) <=>
         read (memory :> bytes128 a) s = (word (t MOD 2 EXP 128) : int128) /\
         read (memory :> bytes128 (word_add a (word 16))) s =
         (word ((t DIV 2 EXP 128) MOD 2 EXP 128) : int128) /\
         read (memory :> bytes64 (word_add a (word 32))) s =
         (word (t DIV 2 EXP 256) : int64))`,
  let split_16_24 = CONV_RULE (ONCE_DEPTH_CONV NUM_ADD_CONV THENC
                                DEPTH_CONV NUM_MULT_CONV)
    (INST [`16`,`k:num`; `24`,`l:num`] READ_BYTES_SPLIT_ANY) in
  let split_16_8 = CONV_RULE (ONCE_DEPTH_CONV NUM_ADD_CONV THENC
                               DEPTH_CONV NUM_MULT_CONV)
    (INST [`16`,`k:num`; `8`,`l:num`] READ_BYTES_SPLIT_ANY) in
  STRIP_TAC THEN
  REWRITE_TAC[BYTES128_WBYTES; BYTES64_WBYTES; GSYM VAL_EQ;
              VAL_READ_WBYTES; READ_COMPONENT_COMPOSE] THEN
  CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[split_16_24] THEN REWRITE_TAC[split_16_8] THEN
  REWRITE_TAC[WORD_ADD_ASSOC_CONSTS] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[DIV_DIV; GSYM EXP_ADD] THEN CONV_TAC NUM_REDUCE_CONV THEN
  IMP_REWRITE_TAC[VAL_WORD_EXACT] THEN
  CONV_TAC(DEPTH_CONV DIMINDEX_CONV) THEN ASM_ARITH_TAC);;
let WORD_SUBWORD_NUM_OF_WORDLIST_CASES_D20 = mk_subword_cases 20 16;;

(* ------------------------------------------------------------------------- *)
(* Core correctness theorem                                                  *)
(* ------------------------------------------------------------------------- *)

let MLDSA_POLYZ_UNPACK_19_CORRECT = prove
 (`!r b t (l:(20 word) list) pc.
        LENGTH l = 256 /\
        ALLPAIRS nonoverlapping
         [(r,1024)]
         [(word pc,LENGTH mldsa_polyz_unpack_19_mc); (b,640); (t,64)]
        ==> ensures arm
             (\s. aligned_bytes_loaded s (word pc) mldsa_polyz_unpack_19_mc /\
                  read PC s = word (pc + MLDSA_POLYZ_UNPACK_19_CORE_START) /\
                  C_ARGUMENTS [r; b; t] s /\
                  read(memory :> bytes(t,64)) s =
                    num_of_wordlist mldsa_polyz_unpack_19_indices /\
                  read(memory :> bytes(b,640)) s = num_of_wordlist l)
             (\s. read PC s = word(pc + MLDSA_POLYZ_UNPACK_19_CORE_END) /\
                  read(memory :> bytes(r,1024)) s =
                       num_of_wordlist (MAP zunpack19 l))
             (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(r,1024)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV_19 THEN
  MAP_EVERY X_GEN_TAC [`r:int64`; `b:int64`; `t:int64`;
                        `l:(20 word) list`; `pc:num`] THEN
  REWRITE_TAC[C_ARGUMENTS; MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
              NONOVERLAPPING_CLAUSES; ALL; ALLPAIRS] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

  ENSURES_INIT_TAC "s0" THEN

  (*** Expand table precondition into 4 x bytes128 reads ***)
  FIRST_X_ASSUM(MP_TAC o check (can (term_match []
    `read(memory :> bytes(t:int64,64)) s = x`) o concl)) THEN
  REWRITE_TAC[mldsa_polyz_unpack_19_indices] THEN
  REPLICATE_TAC 4
   (GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
         [GSYM NUM_OF_PAIR_WORDLIST]) THEN
  REWRITE_TAC[pair_wordlist] THEN
  CONV_TAC WORD_REDUCE_CONV THEN
  CONV_TAC(LAND_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN
  REWRITE_TAC[GSYM BYTES128_WBYTES] THEN
  STRIP_TAC THEN

  (*** Split 256 20-bit coefficients into 16 chunks of 16 as 320-bit words ***)
  UNDISCH_TAC `read(memory :> bytes(b,640)) s0 = num_of_wordlist(l:(20 word) list)` THEN
  IMP_REWRITE_TAC [NUM_OF_WORDLIST_SPLIT_20_256] THEN
  CONV_TAC (ONCE_DEPTH_CONV LIST_OF_SEQ_CONV) THEN
  REWRITE_TAC [MAP; o_DEF] THEN
  CONV_TAC(LAND_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN

  (*** Split each 320-bit wbytes into bytes128 + bytes128 + bytes64 ***)
  IMP_REWRITE_TAC [READ_MEMORY_WBYTES_SPLIT_128_128_64] THEN
  MAP_EVERY (fun n -> SUBGOAL_THEN (subst[mk_small_numeral n,`k:num`]
    `num_of_wordlist (SUB_LIST (16 * k,16) (l : (20 word) list)) < 2 EXP 320`)
     (fun th -> REWRITE_TAC[th]) THENL [
       TRANS_TAC LTE_TRANS (subst[mk_small_numeral n,`k:num`]
                            `2 EXP (dimindex(:20) * LENGTH(SUB_LIST(16*k,16) (l : (20 word) list)))`) THEN
       REWRITE_TAC[NUM_OF_WORDLIST_BOUND] THEN
       REWRITE_TAC[LENGTH_SUB_LIST; DIMINDEX_CONV `dimindex (:20)`] THEN
       ASM_SIMP_TAC [] THEN NUM_REDUCE_TAC;
       ALL_TAC]) (0--15) THEN
  REWRITE_TAC [WORD_ADD_ASSOC_CONSTS] THEN CONV_TAC (TOP_SWEEP_CONV NUM_ADD_CONV) THEN
  STRIP_TAC THEN

  (*** Derive overlapping bytes128 reads at offset 24 for each chunk ***)
  MAP_EVERY (DERIVE_OVERLAP_TAC BYTES128_FROM_OVERLAP_64 40) (0--15) THEN

  (*** Gather LENGTH assumptions for sublists ***)
  MAP_EVERY (fun i -> SUBGOAL_THEN
    (subst [mk_small_numeral (16 * i), `i: num`]
      `LENGTH (SUB_LIST (i, 16) (l : (20 word) list)) = 16`) ASSUME_TAC
    THENL [ASM_REWRITE_TAC [LENGTH_SUB_LIST] THEN NUM_REDUCE_TAC; ALL_TAC])
    (0 -- 15) THEN

  (*** Symbolic execution with per-step simplification ***)
  MAP_UNTIL_TARGET_PC (fun n ->
    ARM_STEPS_TAC MLDSA_POLYZ_UNPACK_19_EXEC [n] THEN
    SIMD_SIMPLIFY_TAC (map GSYM BASE_SIMPS_D20) THEN
    SIMP_ZUNPACK_TAC 20 ZUNPACK19_CORRECT) 1 THEN

  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN

  (*** Fold output back to MAP zunpack19 l ***)
  REPEAT (FIRST_X_ASSUM(MP_TAC o check
     (can (term_match [] `read (memory :> bytes128 r) s0 = xxx`) o concl))) THEN
  TRY (IMP_REWRITE_TAC WORD_SUBWORD_NUM_OF_WORDLIST_CASES_D20) THEN
  UNDISCH_THEN `LENGTH (l : (20 word) list) = 256`
    (fun th -> CONV_TAC (TOP_SWEEP_CONV (EL_SUB_LIST_CONV th)) THEN ASSUME_TAC th) THEN
  REPEAT DISCH_TAC THEN
  GEN_REWRITE_TAC (RAND_CONV o RAND_CONV o RAND_CONV) [GSYM LIST_OF_SEQ_EQ_SELF] THEN
  ASM_REWRITE_TAC[LENGTH_MAP] THEN
  CONV_TAC (TOP_SWEEP_CONV LIST_OF_SEQ_CONV) THEN
  ASM_REWRITE_TAC [MAP] THEN
  REPLICATE_TAC 2 (CONV_TAC (ONCE_REWRITE_CONV [GSYM NUM_OF_PAIR_WORDLIST])) THEN
  REWRITE_TAC[pair_wordlist] THEN
  CONV_TAC (ONCE_DEPTH_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN
  ASM_REWRITE_TAC[GSYM BYTES128_WBYTES]);;

(* ------------------------------------------------------------------------- *)
(* Subroutine correctness                                                    *)
(* ------------------------------------------------------------------------- *)

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/aarch64/src/arith_native_aarch64.h *)

let MLDSA_POLYZ_UNPACK_19_SUBROUTINE_CORRECT = prove
 (`!r b t (l:(20 word) list) pc returnaddress.
        LENGTH l = 256 /\
        ALLPAIRS nonoverlapping
         [(r,1024)]
         [(word pc,LENGTH mldsa_polyz_unpack_19_mc); (b,640); (t,64)]
        ==> ensures arm
             (\s. aligned_bytes_loaded s (word pc) mldsa_polyz_unpack_19_mc /\
                  read PC s = word pc /\
                  read X30 s = returnaddress /\
                  C_ARGUMENTS [r; b; t] s /\
                  read(memory :> bytes(t,64)) s =
                    num_of_wordlist mldsa_polyz_unpack_19_indices /\
                  read(memory :> bytes(b,640)) s = num_of_wordlist l)
             (\s. read PC s = returnaddress /\
                  read(memory :> bytes(r,1024)) s =
                       num_of_wordlist (MAP zunpack19 l) /\
                  (!i. i < 256 ==>
                       --(&(2 EXP 19) - &1) <= ival(EL i (MAP zunpack19 l)) /\
                       ival(EL i (MAP zunpack19 l)) <= &(2 EXP 19)))
             (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(r,1024)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV_19 THEN
  ARM_ADD_RETURN_NOSTACK_TAC MLDSA_POLYZ_UNPACK_19_EXEC
   (CONV_RULE LENGTH_SIMPLIFY_CONV_19 MLDSA_POLYZ_UNPACK_19_CORRECT) THEN
  REPEAT STRIP_TAC THEN
  MP_TAC(CONV_RULE NUM_REDUCE_CONV
    (ISPECL [`l:(20 word) list`; `i:num`] ZUNPACK19_MAP_BOUND)) THEN
  ASM_REWRITE_TAC[] THEN SIMP_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Constant-time and memory safety proof.                                    *)
(* ------------------------------------------------------------------------- *)

needs "s2n_bignum/arm/proofs/consttime.ml";;
needs "mldsa_native/aarch64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    (assoc "mldsa_polyz_unpack_19" subroutine_signatures)
    MLDSA_POLYZ_UNPACK_19_SUBROUTINE_CORRECT
    MLDSA_POLYZ_UNPACK_19_EXEC;;

let MLDSA_POLYZ_UNPACK_19_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e r b t (l:(20 word) list) pc returnaddress.
           LENGTH l = 256 /\
           ALLPAIRS nonoverlapping
            [(r,1024)]
            [(word pc,LENGTH mldsa_polyz_unpack_19_mc); (b,640); (t,64)]
           ==> ensures arm
               (\s.
                    aligned_bytes_loaded s (word pc)
                    mldsa_polyz_unpack_19_mc /\
                    read PC s = word pc /\
                    read X30 s = returnaddress /\
                    C_ARGUMENTS [r; b; t] s /\
                    read events s = e)
               (\s.
                    read PC s = returnaddress /\
                    (exists e2.
                         read events s = APPEND e2 e /\
                         e2 = f_events b t r pc returnaddress /\
                         memaccess_inbounds e2 [b,640; t,64; r,1024]
                         [r,1024]))
               (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars MLDSA_POLYZ_UNPACK_19_EXEC);;
