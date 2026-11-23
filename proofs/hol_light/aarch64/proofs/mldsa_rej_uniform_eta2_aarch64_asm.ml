(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Rejection sampling with eta=2 for ML-DSA AArch64.                         *)
(*                                                                           *)
(* Filters 4-bit nibbles < 15, maps accepted values n to (2 - (n mod 5))     *)
(* as int32. A register lookup reduces n modulo 5. A table lookup compacts   *)
(* each group of eight lanes before the direct stores to the result.         *)
(* ========================================================================= *)
needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_rej_uniform_eta_table.ml";;

(**** print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_eta2_aarch64_asm.o";;
 ****)

let mldsa_rej_uniform_eta2_mc = define_assert_from_elf
  "mldsa_rej_uniform_eta2_mc" "aarch64/mldsa/mldsa_rej_uniform_eta2_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0xd2802025;       (* arm_MOV X5 (rvalue (word 257)) *)
  0xf2a02045;       (* arm_MOVK X5 (word 258) 16 *)
  0xf2c02085;       (* arm_MOVK X5 (word 260) 32 *)
  0xf2e02105;       (* arm_MOVK X5 (word 264) 48 *)
  0x4e081cbf;       (* arm_INS_GEN Q31 X5 0 64 *)
  0xd2802205;       (* arm_MOV X5 (rvalue (word 272)) *)
  0xf2a02405;       (* arm_MOVK X5 (word 288) 16 *)
  0xf2c02805;       (* arm_MOVK X5 (word 320) 32 *)
  0xf2e03005;       (* arm_MOVK X5 (word 384) 48 *)
  0x4e181cbf;       (* arm_INS_GEN Q31 X5 64 64 *)
  0xd2802005;       (* arm_MOV X5 (rvalue (word 256)) *)
  0xf2a06045;       (* arm_MOVK X5 (word 770) 16 *)
  0xf2c00085;       (* arm_MOVK X5 (word 4) 32 *)
  0xf2e04025;       (* arm_MOVK X5 (word 513) 48 *)
  0x4e081ca1;       (* arm_INS_GEN Q1 X5 0 64 *)
  0xd2808065;       (* arm_MOV X5 (rvalue (word 1027)) *)
  0xf2a02005;       (* arm_MOVK X5 (word 256) 16 *)
  0xf2c06045;       (* arm_MOVK X5 (word 770) 32 *)
  0xf2e00085;       (* arm_MOVK X5 (word 4) 48 *)
  0x4e181ca1;       (* arm_INS_GEN Q1 X5 64 64 *)
  0x4f00e5fe;       (* arm_MOVI Q30 (word 1085102592571150095) *)
  0x4f008447;       (* arm_MOVI Q7 (word 562958543486978) *)
  0x0f00e5fd;       (* arm_MOVI D29 (word 1085102592571150095) *)
  0xd2802004;       (* arm_MOV X4 (rvalue (word 256)) *)
  0x0cdf7020;       (* arm_LDR D0 X1 (Postimmediate_Offset (word 8)) *)
  0x0e3d1c02;       (* arm_AND_VEC Q2 Q0 Q29 64 *)
  0x2f0c0403;       (* arm_USHR_VEC Q3 Q0 4 8 64 *)
  0x4e033846;       (* arm_ZIP1 Q6 Q2 Q3 8 128 *)
  0x6e2637c4;       (* arm_CMHI_VEC Q4 Q30 Q6 8 128 *)
  0x4f08a485;       (* arm_SSHLL2_VEC Q5 Q4 0 8 *)
  0x0f08a484;       (* arm_SSHLL_VEC Q4 Q4 0 8 *)
  0x4e3f1c84;       (* arm_AND_VEC Q4 Q4 Q31 128 *)
  0x4e3f1ca5;       (* arm_AND_VEC Q5 Q5 Q31 128 *)
  0x6e703894;       (* arm_UADDLV Q20 Q4 8 16 *)
  0x6e7038b5;       (* arm_UADDLV Q21 Q5 8 16 *)
  0x9e66028c;       (* arm_FMOV_FtoI X12 Q20 0 64 *)
  0x9e6602ad;       (* arm_FMOV_FtoI X13 Q21 0 64 *)
  0x92401d8e;       (* arm_AND X14 X12 (rvalue (word 255)) *)
  0x92401daf;       (* arm_AND X15 X13 (rvalue (word 255)) *)
  0xd348fd8c;       (* arm_LSR X12 X12 8 *)
  0xd348fdad;       (* arm_LSR X13 X13 8 *)
  0x3cee7878;       (* arm_LDR Q24 X3 (Shiftreg_Offset X14 4) *)
  0x3cef7879;       (* arm_LDR Q25 X3 (Shiftreg_Offset X15 4) *)
  0x4e060026;       (* arm_TBL Q6 [Q1] Q6 128 *)
  0x2f08a4d0;       (* arm_USHLL_VEC Q16 Q6 0 8 *)
  0x6f08a4d2;       (* arm_USHLL2_VEC Q18 Q6 0 8 *)
  0x4e180210;       (* arm_TBL Q16 [Q16] Q24 128 *)
  0x4e190252;       (* arm_TBL Q18 [Q18] Q25 128 *)
  0x6e7020f1;       (* arm_USUBL2 Q17 Q7 Q16 16 *)
  0x2e7020f0;       (* arm_USUBL Q16 Q7 Q16 16 *)
  0x6e7220f3;       (* arm_USUBL2 Q19 Q7 Q18 16 *)
  0x2e7220f2;       (* arm_USUBL Q18 Q7 Q18 16 *)
  0xf100409f;       (* arm_CMP X4 (rvalue (word 16)) *)
  0x54000149;       (* arm_BLS (word 40) *)
  0xad004410;       (* arm_STP Q16 Q17 X0 (Immediate_Offset (iword (&0))) *)
  0x8b0c0800;       (* arm_ADD X0 X0 (Shiftedreg X12 LSL 2) *)
  0xad004c12;       (* arm_STP Q18 Q19 X0 (Immediate_Offset (iword (&0))) *)
  0x8b0d0800;       (* arm_ADD X0 X0 (Shiftedreg X13 LSL 2) *)
  0xcb0c0084;       (* arm_SUB X4 X4 X12 *)
  0xcb0d0084;       (* arm_SUB X4 X4 X13 *)
  0xf1002042;       (* arm_SUBS X2 X2 (rvalue (word 8)) *)
  0x54fffb61;       (* arm_BNE (word 2097004) *)
  0x14000019;       (* arm_B (word 100) *)
  0xd2800046;       (* arm_MOV X6 (rvalue (word 2)) *)
  0xf100209f;       (* arm_CMP X4 (rvalue (word 8)) *)
  0x54000063;       (* arm_BCC (word 12) *)
  0xad004410;       (* arm_STP Q16 Q17 X0 (Immediate_Offset (iword (&0))) *)
  0x1400000a;       (* arm_B (word 40) *)
  0xaa0003e7;       (* arm_MOV X7 X0 *)
  0x36100064;       (* arm_TBZ W4 2 (word 12) *)
  0x3c8104f0;       (* arm_STR Q16 X7 (Postimmediate_Offset (word 16)) *)
  0x4eb11e30;       (* arm_MOV_VEC Q16 Q17 128 *)
  0x36080064;       (* arm_TBZ W4 1 (word 12) *)
  0xfc0084f0;       (* arm_STR D16 X7 (Postimmediate_Offset (word 8)) *)
  0x6e104210;       (* arm_EXT Q16 Q16 Q16 64 *)
  0x36000044;       (* arm_TBZ W4 0 (word 8) *)
  0xbd0000f0;       (* arm_STR (SREG 16) X7 (Immediate_Offset (word 0)) *)
  0xeb0c0084;       (* arm_SUBS X4 X4 X12 *)
  0x54000109;       (* arm_BLS (word 32) *)
  0x8b0c0800;       (* arm_ADD X0 X0 (Shiftedreg X12 LSL 2) *)
  0xf10004c6;       (* arm_SUBS X6 X6 (rvalue (word 1)) *)
  0x54fffd60;       (* arm_BEQ (word 2097068) *)
  0x4eb21e50;       (* arm_MOV_VEC Q16 Q18 128 *)
  0x4eb31e71;       (* arm_MOV_VEC Q17 Q19 128 *)
  0xaa0d03ec;       (* arm_MOV X12 X13 *)
  0x17ffffeb;       (* arm_B (word 268435372) *)
  0xd2800004;       (* arm_MOV X4 (rvalue (word 0)) *)
  0xd2802000;       (* arm_MOV X0 (rvalue (word 256)) *)
  0xcb040000;       (* arm_SUB X0 X0 X4 *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let MLDSA_REJ_UNIFORM_ETA2_EXEC = ARM_MK_EXEC_RULE mldsa_rej_uniform_eta2_mc;;

let LENGTH_MLDSA_REJ_UNIFORM_ETA2_MC =
  REWRITE_CONV[mldsa_rej_uniform_eta2_mc] `LENGTH mldsa_rej_uniform_eta2_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

(* Q1 holds the residues modulo 5 of the sixteen possible nibbles. *)
let ETA2_TBL_MOD5 = prove
 (`!n. n < 16 ==> word_subword (word 0x00040302010004030201000403020100:int128)
          (8 * n,8):byte = word (n MOD 5)`,
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC WORD_REDUCE_CONV);;

let ETA2_TBL_NIBBLE = prove
 (`!b:byte. val b < 16 ==>
     word_subword (word 0x00040302010004030201000403020100:int128) (8 * val b,8) =
     word_umod b (word 5)`,
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[ETA2_TBL_MOD5] THEN
  REWRITE_TAC[word_umod; modular] THEN CONV_TAC WORD_REDUCE_CONV);;

(* ZIP1 interleaves the two nibbles of each input byte in sampling order. *)
let ETA2_LOAD_NIBBLES = prove
 (`!pc buf (v:int64) e. ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
          read PC s = word(pc+0x60) /\ read X1 s = buf /\
          read Q29 s = word 0x0f0f0f0f0f0f0f0f /\
          read (memory :> bytes64 buf) s = v /\ read events s = e)
     (\s. read PC s = word(pc+0x70) /\ read X1 s = word_add buf (word 8) /\
          (!i. i < 16 ==> word_subword (read Q6 s) (8*i,8):byte =
                          word_zx (word_subword v (4*i,4):4 word)) /\
          read events s = CONS (EventLoad(buf,8)) e)
     (MAYCHANGE [PC;X1] ,, MAYCHANGE [Q0;Q2;Q3;Q6] ,, MAYCHANGE [events])`,
   REPEAT GEN_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--4) THEN
   CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
   REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

(* The packed halfword sum contains the eight-bit mask and its population count. *)
let ETA2_PACKET_MASK = new_definition
 `ETA2_PACKET_MASK p =
    bitval(p 0) + 2 * bitval(p 1) + 4 * bitval(p 2) + 8 * bitval(p 3) +
    16 * bitval(p 4) + 32 * bitval(p 5) + 64 * bitval(p 6) + 128 * bitval(p 7)`;;

let ETA2_PACKET_COUNT = new_definition
 `ETA2_PACKET_COUNT p =
    bitval(p 0) + bitval(p 1) + bitval(p 2) + bitval(p 3) +
    bitval(p 4) + bitval(p 5) + bitval(p 6) + bitval(p 7)`;;

let ETA2_PACKET_LANES = new_definition
 `ETA2_PACKET_LANES (v:int128) g i =
     word_ult (word_subword v (8 * (8*g+i),8):byte) (word 15)`;;

let ETA2_PACKET_REGISTERS = prove
 (`!v:int128 pc. ensures arm
    (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
         read PC s = word(pc + 0x70) /\ read Q6 s = v /\
         read Q31 s = word 0x01800140012001100108010401020101 /\
         read Q30 s = word 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f)
    (\s. read PC s = word(pc+0xa4) /\
         read X14 s = word (ETA2_PACKET_MASK (ETA2_PACKET_LANES v 0)) /\
         read X15 s = word (ETA2_PACKET_MASK (ETA2_PACKET_LANES v 1)) /\
         read X12 s = word (ETA2_PACKET_COUNT (ETA2_PACKET_LANES v 0)) /\
         read X13 s = word (ETA2_PACKET_COUNT (ETA2_PACKET_LANES v 1)))
    (MAYCHANGE [PC; X12; X13; X14; X15] ,, MAYCHANGE [Q4; Q5; Q20; Q21])`,
  REPEAT GEN_TAC THEN ENSURES_INIT_TAC "s0" THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--13) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  REWRITE_TAC[ETA2_PACKET_MASK; ETA2_PACKET_COUNT; ETA2_PACKET_LANES] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[word_ugt;word_ult;relational2;GT;WORD_SHL_ZERO] THEN
  CONV_TAC WORD_REDUCE_CONV THEN
  REPEAT CONJ_TAC THEN
  (fun (_,w as g) ->
    let preds = setify (find_terms (fun t -> is_binary "<" t) w) in
    (MAP_EVERY (fun p -> SPEC_TAC(p,genvar bool_ty)) preds THEN REPEAT GEN_TAC THEN
     REWRITE_TAC[WORD_ADD;WORD_MUL] THEN
     (fun (_,w as g) ->
       let bs = filter (fun v -> type_of v = bool_ty) (frees w) in
       (MAP_EVERY BOOL_CASES_TAC bs THEN REWRITE_TAC[BITVAL_CLAUSES] THEN
        CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV) g)) g));;

let ETA2_SAMPLE32 = define
 `ETA2_SAMPLE32 (v:byte) = word_sub (word 2) (word_zx (word_umod v (word 5))):int32`;;

let ETA2_SAMPLE32_SPEC = prove
 (`!n. n < 16 ==>
    ETA2_SAMPLE32 (word n) = word_sx (word_sub (word 2) (word_umod (word n) (word 5)):4 word)`,
  CONV_TAC EXPAND_CASES_CONV THEN REWRITE_TAC[ETA2_SAMPLE32] THEN CONV_TAC WORD_REDUCE_CONV);;

let ETA2_REDUCE_REGISTER = prove
 (`!v:int128 pc.
    (!i. i < 16 ==> val(word_subword v (8*i,8):byte) < 16) ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0xac) /\ read Q6 s = v /\
           read Q1 s = word 0x00040302010004030201000403020100)
      (\s. read PC s = word(pc+0xb0) /\
           (!i. i < 16 ==> word_subword (read Q6 s) (8*i,8):byte =
                           word_umod (word_subword v (8*i,8):byte) (word 5)))
      (MAYCHANGE [PC] ,, MAYCHANGE [Q6])`,
  REPEAT STRIP_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1] THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  FIRST_X_ASSUM(MP_TAC o CONV_RULE EXPAND_CASES_CONV) THEN
  CONV_TAC NUM_REDUCE_CONV THEN STRIP_TAC THEN ASM_SIMP_TAC[ETA2_TBL_NIBBLE]);;

(* TBL gathers both bytes of each selected halfword. *)
let ETA2_HALFWORD_GATHER = define
 `ETA2_HALFWORD_GATHER (row:int128) (src:int128) (dst:int128) <=>
    !i. i < 8 ==> !j. j < 8 ==>
        word_subword row (16*i,8):byte = word(2*j) /\
        word_subword row (16*i+8,8):byte = word(2*j+1)
        ==> word_subword dst (16*i,16):int16 = word_subword src (16*j,16)`;;

let ETA2_GATHER = prove
 (`!pc x y a b. ensures arm
    (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
         read PC s = word(pc+0xb8) /\ read Q16 s = x /\ read Q18 s = y /\
         read Q24 s = a /\ read Q25 s = b)
    (\s. read PC s = word(pc+0xc0) /\ ETA2_HALFWORD_GATHER a x (read Q16 s) /\
         ETA2_HALFWORD_GATHER b y (read Q18 s))
    (MAYCHANGE [PC] ,, MAYCHANGE [Q16;Q18])`,
  REPEAT GEN_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN
  REWRITE_TAC[ETA2_HALFWORD_GATHER] THEN CONJ_TAC THEN CONV_TAC EXPAND_CASES_CONV THEN
  REPEAT CONJ_TAC THEN CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT CONJ_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  ASM_REWRITE_TAC[] THEN CONV_TAC WORD_REDUCE_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN CONV_TAC WORD_BLAST);;

let ETA2_WIDEN_NIBBLES = prove
 (`!pc v. ensures arm
    (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
         read PC s = word(pc+0xb0) /\ read Q6 s = v)
    (\s. read PC s = word(pc+0xb8) /\
         (!i. i < 8 ==> word_subword (read Q16 s) (16*i,16):int16 =
                        word_zx(word_subword v (8*i,8):byte)) /\
         (!i. i < 8 ==> word_subword (read Q18 s) (16*i,16):int16 =
                        word_zx(word_subword v (8*(i+8),8):byte)))
    (MAYCHANGE [PC] ,, MAYCHANGE [Q16;Q18])`,
  REPEAT GEN_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN
  CONJ_TAC THEN CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

(* Widen the compacted halfwords before subtracting them from 2. *)
let ETA2_WIDEN = prove
 (`!pc lo hi. ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
          read PC s = word(pc+0xc0) /\ read Q16 s = lo /\ read Q18 s = hi /\
          read Q7 s = word 0x00020002000200020002000200020002)
     (\s. read PC s = word(pc+0xd0) /\
          (!i. i < 8 ==>
              word_subword (word_join (read Q17 s) (read Q16 s):int256) (32*i,32):int32 =
              word_sub (word 2) (word_zx (word_subword lo (16*i,16):int16))) /\
          (!i. i < 8 ==>
              word_subword (word_join (read Q19 s) (read Q18 s):int256) (32*i,32):int32 =
              word_sub (word 2) (word_zx (word_subword hi (16*i,16):int16))))
     (MAYCHANGE [PC] ,, MAYCHANGE [Q16;Q17;Q18;Q19])`,
  REPEAT GEN_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--4) THEN
  CONJ_TAC THEN CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN CONV_TAC WORD_REDUCE_CONV THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let ETA2_RETURN = prove
 (`!pc k ra e. k <= 256 ==> ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
          read PC s = word(pc+0x15c) /\ read X4 s = word k /\
          read X30 s = ra /\ read events s = e)
     (\s. read PC s = ra /\ read X0 s = word(256-k) /\
          read events s = CONS (EventJump(word(pc+0x164),ra)) e)
     (MAYCHANGE [PC;X0] ,, MAYCHANGE [events])`,
  REPEAT STRIP_TAC THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--3) THEN
  ASM_SIMP_TAC[WORD_SUB]);;

let ETA2_SETUP = prove
 (`!pc. ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\ read PC s = word pc)
     (\s. read PC s = word(pc+0x60) /\ read X4 s = word 256 /\
          read Q1 s = word 0x00040302010004030201000403020100 /\
          read Q7 s = word 0x00020002000200020002000200020002 /\
          read Q29 s = word 0x0f0f0f0f0f0f0f0f /\
          read Q30 s = word 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f /\
          read Q31 s = word 0x01800140012001100108010401020101)
     (MAYCHANGE [PC;X4;X5] ,, MAYCHANGE [Q1;Q7;Q29;Q30;Q31])`,
   GEN_TAC THEN GHOST_INTRO_TAC `init1:int128` `read Q1` THEN
   GHOST_INTRO_TAC `init31:int128` `read Q31` THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--24) THEN
   CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
   CONV_TAC WORD_REDUCE_CONV THEN CONV_TAC WORD_BLAST);;

(* Each row gathers the low and high bytes of the accepted halfwords. *)
let ETA2_INDICES = define
 `ETA2_INDICES (m:byte) = FILTER (\i. bit i m) [0;1;2;3;4;5;6;7]`;;

let ETA2_MASK_INDICES = prove
 (`!p. ETA2_PACKET_MASK p < 256 /\ ETA2_PACKET_COUNT p <= 8 /\
       ETA2_INDICES(word(ETA2_PACKET_MASK p)) = FILTER p [0;1;2;3;4;5;6;7] /\
       LENGTH(ETA2_INDICES(word(ETA2_PACKET_MASK p))) = ETA2_PACKET_COUNT p`,
  GEN_TAC THEN REWRITE_TAC[ETA2_PACKET_MASK; ETA2_PACKET_COUNT; ETA2_INDICES; FILTER] THEN
  MAP_EVERY BOOL_CASES_TAC (map (fun i -> mk_comb(`p:num->bool`,mk_small_numeral i)) (0--7)) THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC WORD_REDUCE_CONV THEN REWRITE_TAC[LENGTH] THEN CONV_TAC NUM_REDUCE_CONV);;


let ETA2_NIBBLE = define
 `ETA2_NIBBLE (d:int64) i = word_zx(word_subword d (4*i,4):4 word):byte`;;

let ETA2_LANES = define
 `ETA2_LANES (d:int64) g = MAP (\i. ETA2_NIBBLE d (8*g+i)) [0;1;2;3;4;5;6;7]`;;

let ETA2_GROUP = define
 `ETA2_GROUP d g = MAP ETA2_SAMPLE32 (FILTER (\n:byte. val n < 15) (ETA2_LANES d g))`;;

let ETA2_BYTE_SPEC = prove
 (`!x:byte. val x < 16 ==>
    ETA2_SAMPLE32 x = word_sx (word_sub (word 2:4 word) (word_umod (word_zx x) (word 5)))`,
  REPEAT STRIP_TAC THEN MP_TAC(SPEC `val(x:byte)` ETA2_SAMPLE32_SPEC) THEN
  ASM_REWRITE_TAC[WORD_VAL;word_zx]);;

let ETA2_GROUP_FILTER = prove
 (`!d g. ETA2_GROUP d g = MAP (\j. ETA2_SAMPLE32 (ETA2_NIBBLE d (8*g+j)))
       (FILTER (\j. val(ETA2_NIBBLE d (8*g+j)) < 15) [0;1;2;3;4;5;6;7])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ETA2_GROUP;ETA2_LANES;FILTER_MAP;GSYM MAP_o;o_DEF]);;

let ETA2_GROUP_MASK = prove
 (`!d g p. (!j. j < 8 ==> (p j <=> val(ETA2_NIBBLE d (8*g+j)) < 15)) ==>
      ETA2_GROUP d g = MAP (\j. ETA2_SAMPLE32(ETA2_NIBBLE d (8*g+j)))
                            (ETA2_INDICES(word(ETA2_PACKET_MASK p)))`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN MP_TAC(SPEC `p:num->bool` ETA2_MASK_INDICES) THEN
  STRIP_TAC THEN ASM_REWRITE_TAC[ETA2_GROUP_FILTER;FILTER] THEN
  REPEAT AP_TERM_TAC THEN ASM_SIMP_TAC[ARITH_RULE `0<8 /\ 1<8 /\ 2<8 /\ 3<8 /\ 4<8 /\ 5<8 /\ 6<8 /\ 7<8`]);;

let ETA2_NIBBLE4 = define
 `ETA2_NIBBLE4 (d:int64) g = MAP (\i. word_subword d (4*(8*g+i),4):4 word) [0;1;2;3;4;5;6;7]`;;

let ETA2_GROUP_SPEC = prove
 (`!d g. ETA2_GROUP d g = REJ_SAMPLE_ETA2(ETA2_NIBBLE4 d g)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ETA2_GROUP_FILTER; ETA2_NIBBLE4; REJ_SAMPLE_ETA2;
                    ETA2_NIBBLE;FILTER_MAP;o_DEF;GSYM MAP_o] THEN
  SUBGOAL_THEN `!x:4 word. val(word_zx x:byte) = val x` ASSUME_TAC THENL
   [GEN_TAC THEN MATCH_MP_TAC VAL_WORD_ZX THEN REWRITE_TAC[DIMINDEX_4;DIMINDEX_8] THEN ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[o_DEF] THEN
  MATCH_MP_TAC MAP_EQ THEN REWRITE_TAC[GSYM ALL_MEM] THEN X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  MP_TAC(SPEC `val(word_subword (d:int64) (4*(8*g+i),4):4 word)` ETA2_SAMPLE32_SPEC) THEN
  SUBGOAL_THEN `!x:4 word. val x < 16` ASSUME_TAC THENL
   [MP_TAC(INST_TYPE[`:4`,`:N`] VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_4] THEN CONV_TAC NUM_REDUCE_CONV;
    ASM_REWRITE_TAC[WORD_VAL;word_zx]]);;

let ETA2_NIBBLES_CHUNK = prove
 (`!d:int64. BYTES_TO_NIBBLES (MAP (\i. word_subword d (8*i,8):byte) [0;1;2;3;4;5;6;7]) =
            APPEND (ETA2_NIBBLE4 d 0) (ETA2_NIBBLE4 d 1)`,
  GEN_TAC THEN REWRITE_TAC[ETA2_NIBBLE4;MAP;BYTES_TO_NIBBLES;APPEND;CONS_11] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[GSYM BYTE_AND_15_MOD;GSYM BYTE_USHR4_DIV;GSYM word_zx] THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let ETA2_SAMPLE_APPEND = prove
 (`!xs ys. REJ_SAMPLE_ETA2(APPEND xs ys) = APPEND(REJ_SAMPLE_ETA2 xs)(REJ_SAMPLE_ETA2 ys)`,
  REWRITE_TAC[REJ_SAMPLE_ETA2; FILTER_APPEND; MAP_APPEND]);;

let ETA2_TABLE_ROW = define
 `ETA2_TABLE_ROW m = SUB_LIST(16*m,16) mldsa_rej_uniform_eta_table`;;

let ETA2_BYTES_OF_INDICES = prove
 (`!l:num list. !i. i < LENGTH l ==>
    let bytes = ITLIST (\j t. CONS (word(2*j)) (CONS (word(2*j+1):byte) t)) l [] in
    EL (2*i) bytes = word(2 * EL i l) /\ EL (2*i+1) bytes = word(2 * EL i l+1)`,
  REWRITE_TAC[LET_DEF;LET_END_DEF] THEN LIST_INDUCT_TAC THENL
   [REWRITE_TAC[LENGTH;LT]; ALL_TAC] THEN
  X_GEN_TAC `i:num` THEN STRUCT_CASES_TAC (SPEC `i:num` num_CASES) THEN
  REWRITE_TAC[LENGTH;ITLIST;ARITH_RULE `2*0 = 0`;ARITH_RULE `0+1 = SUC 0`;
              ARITH_RULE `2 * SUC i + 1 = SUC(SUC(2*i+1))`;
              ARITH_RULE `2 * SUC i = SUC(SUC(2*i))`;
              EL;HD;TL;ARITH_RULE `SUC i < SUC n <=> i < n`] THEN
  ASM_REWRITE_TAC[]);;

let ETA2_TABLE_PREFIX = prove
 (`!m. m < 256 ==>
    SUB_LIST(0,2 * LENGTH(ETA2_INDICES(word m))) (ETA2_TABLE_ROW m) =
    ITLIST (\i tl. CONS (word(2*i)) (CONS (word(2*i+1):byte) tl)) (ETA2_INDICES(word m)) []`,
  CONV_TAC EXPAND_CASES_CONV THEN REWRITE_TAC[ETA2_INDICES; ETA2_TABLE_ROW; FILTER] THEN
  CONV_TAC(DEPTH_CONV WORD_RED_CONV) THEN
  REWRITE_TAC[LENGTH; ITLIST] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[mldsa_rej_uniform_eta_table] THEN
  CONV_TAC(DEPTH_CONV SUB_LIST_CONV) THEN CONV_TAC(DEPTH_CONV WORD_RED_CONV));;

(* Convert the byte-pair table prefix into the lane facts used by TBL. *)
let ETA2_ROW_LANES = prove
 (`!m i. m < 256 /\ i < LENGTH(ETA2_INDICES(word m)) ==>
    let row = word(num_of_wordlist(ETA2_TABLE_ROW m)):int128 in
    let j = EL i (ETA2_INDICES(word m)) in
    word_subword row (16*i,8):byte = word(2*j) /\
    word_subword row (16*i+8,8):byte = word(2*j+1)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[LET_DEF; LET_END_DEF] THEN
  ABBREV_TAC `idx = ETA2_INDICES(word m)` THEN ABBREV_TAC `row = ETA2_TABLE_ROW m` THEN
  SUBGOAL_THEN `LENGTH(row:byte list) = 16` ASSUME_TAC THENL
   [EXPAND_TAC "row" THEN REWRITE_TAC[ETA2_TABLE_ROW; LENGTH_SUB_LIST] THEN
    SUBGOAL_THEN `LENGTH mldsa_rej_uniform_eta_table = 4096` SUBST1_TAC THENL
     [REWRITE_TAC[mldsa_rej_uniform_eta_table;LENGTH] THEN CONV_TAC NUM_REDUCE_CONV; ASM_ARITH_TAC]; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(idx:num list) <= 8` ASSUME_TAC THENL
   [EXPAND_TAC "idx" THEN REWRITE_TAC[ETA2_INDICES] THEN
    MP_TAC(ISPECL [`\j. bit j (word m:byte)`; `[0;1;2;3;4;5;6;7]`] LENGTH_FILTER) THEN
    REWRITE_TAC[LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `!k. k < 16 ==> word_subword (word(num_of_wordlist row):int128) (8*k,8):byte = EL k row` ASSUME_TAC THENL
   [GEN_TAC THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`row:byte list`; `k:num`] (INST_TYPE [`:128`,`:KL`;`:8`,`:L`] WORD_SUBWORD_NUM_OF_WORDLIST)) THEN
    ASM_REWRITE_TAC[DIMINDEX_128;DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  REWRITE_TAC[ARITH_RULE `16*i = 8*(2*i)`;ARITH_RULE `16*i+8 = 8*(2*i+1)`] THEN
  SUBGOAL_THEN `2*i < 16 /\ 2*i+1 < 16` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPECL [`idx:num list`; `i:num`] ETA2_BYTES_OF_INDICES) THEN
  ASM_REWRITE_TAC[LET_DEF;LET_END_DEF] THEN
  MP_TAC(SPEC `m:num` ETA2_TABLE_PREFIX) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  SUBGOAL_THEN `!k. k < 2 * LENGTH(idx:num list) ==> EL k (SUB_LIST(0,2*LENGTH idx) (row:byte list)) = EL k row` ASSUME_TAC THENL
   [REPEAT STRIP_TAC THEN MP_TAC(ISPECL [`row:byte list`;`0`;`2*LENGTH(idx:num list)`;`k:num`] EL_SUB_LIST) THEN
    ASM_REWRITE_TAC[ADD_CLAUSES] THEN ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[]]; ALL_TAC] THEN
  SUBGOAL_THEN `2*i < 2*LENGTH(idx:num list) /\ 2*i+1 < 2*LENGTH idx` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[]);;

(* A proved gather, followed by USUBL, produces the selected sample at lane i. *)
let ETA2_GROUP_RESULT = prove
 (`!m row src dst out (nib:num->byte).
    m < 256 /\ (row:int128) = word(num_of_wordlist(ETA2_TABLE_ROW m)) /\
    (!j. j < 8 ==> word_subword (src:int128) (16*j,16):int16 = word_zx(word_umod (nib j) (word 5))) /\
    ETA2_HALFWORD_GATHER row src dst /\
    (!i. i < 8 ==> word_subword (out:int256) (32*i,32):int32 = word_sub (word 2) (word_zx(word_subword dst (16*i,16):int16)))
    ==> !i. i < LENGTH(ETA2_INDICES(word m)) ==>
         word_subword out (32*i,32):int32 = ETA2_SAMPLE32(nib(EL i (ETA2_INDICES(word m))))`,
   REPEAT GEN_TAC THEN STRIP_TAC THEN X_GEN_TAC `i:num` THEN DISCH_TAC THEN
   ABBREV_TAC `idx = ETA2_INDICES(word m)` THEN
   SUBGOAL_THEN `LENGTH(idx:num list) <= 8 /\ EL i idx < 8` STRIP_ASSUME_TAC THENL
    [EXPAND_TAC "idx" THEN REWRITE_TAC[ETA2_INDICES] THEN CONJ_TAC THENL
      [MP_TAC(ISPECL [`\j. bit j (word m:byte)`;`[0;1;2;3;4;5;6;7]`] LENGTH_FILTER) THEN REWRITE_TAC[LENGTH] THEN ARITH_TAC;
       UNDISCH_TAC `i < LENGTH(idx:num list)` THEN EXPAND_TAC "idx" THEN REWRITE_TAC[ETA2_INDICES] THEN DISCH_TAC THEN
       SUBGOAL_THEN `MEM (EL i (FILTER (\j. bit j (word m:byte)) [0;1;2;3;4;5;6;7])) [0;1;2;3;4;5;6;7]` MP_TAC THENL
        [ASM_MESON_TAC[MEM_EL;MEM_FILTER];REWRITE_TAC[MEM] THEN ARITH_TAC]]; ALL_TAC] THEN
   SUBGOAL_THEN `i < 8` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
   MP_TAC(SPECL [`m:num`;`i:num`] ETA2_ROW_LANES) THEN ASM_REWRITE_TAC[LET_DEF;LET_END_DEF] THEN STRIP_TAC THEN
   UNDISCH_TAC `ETA2_HALFWORD_GATHER row src dst` THEN REWRITE_TAC[ETA2_HALFWORD_GATHER] THEN
   DISCH_THEN(MP_TAC o SPEC `i:num`) THEN ASM_REWRITE_TAC[] THEN
   DISCH_THEN(MP_TAC o SPEC `EL i (idx:num list)`) THEN ASM_REWRITE_TAC[] THEN
   DISCH_TAC THEN ASM_SIMP_TAC[ETA2_SAMPLE32] THEN
   CONV_TAC WORD_BLAST);;

let ETA2_GROUP_MACHINE = prove
 (`!d g p m (src:int128) dst (out:int256).
    (!j. j < 8 ==> (p j <=> val(ETA2_NIBBLE d (8*g+j)) < 15)) /\
    m = ETA2_PACKET_MASK p /\
    (!j. j < 8 ==> word_subword src (16*j,16):int16 = word_zx(word_umod (ETA2_NIBBLE d (8*g+j)) (word 5))) /\
    ETA2_HALFWORD_GATHER (word(num_of_wordlist(ETA2_TABLE_ROW m))) src dst /\
    (!i. i < 8 ==> word_subword out (32*i,32):int32 = word_sub (word 2) (word_zx(word_subword dst (16*i,16):int16)))
    ==> (LENGTH(ETA2_GROUP d g) = ETA2_PACKET_COUNT p /\
        (!i. i < LENGTH(ETA2_GROUP d g) ==> word_subword out (32*i,32):int32 = EL i (ETA2_GROUP d g)) /\
        ETA2_PACKET_MASK (\j. val(ETA2_NIBBLE d (8*g+j)) < 15) = m)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(SPECL [`d:int64`;`g:num`;`p:num->bool`] ETA2_GROUP_MASK) THEN
  ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
  MP_TAC(SPEC `p:num->bool` ETA2_MASK_INDICES) THEN STRIP_TAC THEN
  MP_TAC(SPECL [`m:num`;`word(num_of_wordlist(ETA2_TABLE_ROW m)):int128`;`src:int128`;`dst:int128`;`out:int256`;`\j. ETA2_NIBBLE d (8*g+j)`] ETA2_GROUP_RESULT) THEN
  ASM_REWRITE_TAC[LENGTH_MAP] THEN STRIP_TAC THEN CONJ_TAC THENL
   [X_GEN_TAC `i:num` THEN DISCH_TAC THEN
    SUBGOAL_THEN `i < LENGTH(FILTER p [0;1;2;3;4;5;6;7])` ASSUME_TAC THENL
     [ASM_MESON_TAC[];ASM_SIMP_TAC[EL_MAP]];
    REWRITE_TAC[ETA2_PACKET_MASK] THEN ASM_SIMP_TAC[ARITH_RULE `0<8 /\ 1<8 /\ 2<8 /\ 3<8 /\ 4<8 /\ 5<8 /\ 6<8 /\ 7<8`]]);;

let ETA2_READ_BYTES_SLICE = prove
 (`!(a:int64) k n (L:byte list) (s:armstate).
      read(memory:>bytes(a,LENGTH L)) s = num_of_wordlist L /\ k + n <= LENGTH L
      ==> read(memory:>bytes(word_add a (word k), n)) s = num_of_wordlist(SUB_LIST(k,n) L)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `k + (LENGTH(L:byte list) - k) = LENGTH L` ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `n + (LENGTH(L:byte list) - (k+n)) = LENGTH L - k` ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `read(memory:>bytes(word_add a (word k), LENGTH(L:byte list) - k)) s =
                num_of_wordlist(SUB_LIST(k, LENGTH L - k) L)` ASSUME_TAC THENL
   [MP_TAC(ISPECL [`memory:(armstate,int64->byte)component`; `a:int64`; `s:armstate`;
       `SUB_LIST(0,k) (L:byte list)`; `SUB_LIST(k, LENGTH(L:byte list) - k) L`;
       `k:num`; `LENGTH(L:byte list) - k`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
    REWRITE_TAC[DIMINDEX_8; LENGTH_SUB_LIST; SUB_0] THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[SUB_LIST_TOPSPLIT] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]);
    ALL_TAC] THEN
  MP_TAC(ISPECL [`memory:(armstate,int64->byte)component`; `word_add a (word k):int64`; `s:armstate`;
     `SUB_LIST(k,n) (L:byte list)`; `SUB_LIST(k+n, LENGTH(L:byte list) - (k+n)) L`;
     `n:num`; `LENGTH(L:byte list) - (k + n)`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[DIMINDEX_8; LENGTH_SUB_LIST] THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`L:byte list`; `n:num`; `LENGTH(L:byte list) - (k+n)`; `k:num`] SUB_LIST_SPLIT) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]));;

let ETA2_LOAD_TABLE = prove
 (`!pc table a b e. a < 256 /\ b < 256 ==>
   ensures arm
    (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
         read PC s = word(pc+0xa4) /\ read X3 s = table /\
         read X14 s = word a /\ read X15 s = word b /\ read events s = e /\
         read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table)
    (\s. read PC s = word(pc+0xac) /\
         read Q24 s = word(num_of_wordlist(ETA2_TABLE_ROW a)) /\
         read Q25 s = word(num_of_wordlist(ETA2_TABLE_ROW b)) /\
         read events s = APPEND [EventLoad(word_add table (word(16*b)),16);
                                 EventLoad(word_add table (word(16*a)),16)] e)
    (MAYCHANGE [PC] ,, MAYCHANGE [Q24;Q25] ,, MAYCHANGE [events])`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word a:int64) = a /\ val(word b:int64) = b` STRIP_ASSUME_TAC THENL
   [CONJ_TAC THEN MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  SUBGOAL_THEN `LENGTH mldsa_rej_uniform_eta_table = 4096` ASSUME_TAC THENL
   [REWRITE_TAC[mldsa_rej_uniform_eta_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  SUBGOAL_THEN `!r. r < 256 ==> read(memory :> bytes128(word_add table (word(16*r)))) s0 =
                  word(num_of_wordlist(ETA2_TABLE_ROW r))`
    (fun th -> MAP_EVERY (fun r -> ASSUME_TAC(MATCH_MP (SPEC r th) (ASSUME(vsubst [r,`r:num`] `r < 256`))) ) [`a:num`; `b:num`]) THENL
   [X_GEN_TAC `r:num` THEN DISCH_TAC THEN REWRITE_TAC[ETA2_TABLE_ROW; bytes128;READ_COMPONENT_COMPOSE;asword;through;read] THEN
    AP_TERM_TAC THEN
    MP_TAC(ISPECL [`table:int64`; `16*r`; `16`; `mldsa_rej_uniform_eta_table`; `s0:armstate`]
                  ETA2_READ_BYTES_SLICE) THEN ASM_REWRITE_TAC[] THEN ANTS_TAC THENL
     [ASM_ARITH_TAC; REWRITE_TAC[READ_COMPONENT_COMPOSE]];
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[APPEND]]);;

(* Reflect the accepted samples of the two groups in the four output vectors. *)
let ETA2_BATCH_REGISTERS = prove
 (`!pc buf table (d:int64) e. ensures arm
    (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
         read PC s = word(pc+0x60) /\ read X1 s = buf /\ read X3 s = table /\
         read(memory :> bytes64 buf) s = d /\ read events s = e /\
         read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
         read Q1 s = word 0x00040302010004030201000403020100 /\
         read Q7 s = word 0x00020002000200020002000200020002 /\
         read Q29 s = word 0x0f0f0f0f0f0f0f0f /\
         read Q30 s = word 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f /\
         read Q31 s = word 0x01800140012001100108010401020101)
    (\s. read PC s = word(pc+0xd0) /\ read X1 s = word_add buf (word 8) /\
         read X12 s = word(LENGTH(ETA2_GROUP d 0)) /\ read X13 s = word(LENGTH(ETA2_GROUP d 1)) /\
         (!i. i < LENGTH(ETA2_GROUP d 0) ==> word_subword (word_join (read Q17 s) (read Q16 s):int256) (32*i,32):int32 = EL i (ETA2_GROUP d 0)) /\
         (!i. i < LENGTH(ETA2_GROUP d 1) ==> word_subword (word_join (read Q19 s) (read Q18 s):int256) (32*i,32):int32 = EL i (ETA2_GROUP d 1)) /\
         read events s = APPEND [EventLoad(word_add table (word(16*ETA2_PACKET_MASK (\i. val(ETA2_NIBBLE d (8+i)) < 15))),16);
                                 EventLoad(word_add table (word(16*ETA2_PACKET_MASK (\i. val(ETA2_NIBBLE d i) < 15))),16);
                                 EventLoad(buf,8)] e)
    (MAYCHANGE [PC;X1;X12;X13;X14;X15] ,,
     MAYCHANGE [Q0;Q2;Q3;Q4;Q5;Q6;Q16;Q17;Q18;Q19;Q20;Q21;Q24;Q25] ,, MAYCHANGE [events])`,
  REPEAT GEN_TAC THEN ENSURES_INIT_TAC "s0" THEN
  MP_TAC(ISPECL [`pc:num`;`buf:int64`;`d:int64`;`e:(uarch_event)list`] ETA2_LOAD_NIBBLES) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s1" THEN
  REABBREV_TAC `nibbles:int128 = read Q6 s1` THEN
  MP_TAC(ISPECL [`nibbles:int128`;`pc:num`] ETA2_PACKET_REGISTERS) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s2" THEN
  ABBREV_TAC `a = ETA2_PACKET_MASK (ETA2_PACKET_LANES nibbles 0)` THEN
  ABBREV_TAC `b = ETA2_PACKET_MASK (ETA2_PACKET_LANES nibbles 1)` THEN
  SUBGOAL_THEN `a < 256 /\ b < 256` STRIP_ASSUME_TAC THENL
   [EXPAND_TAC "a" THEN EXPAND_TAC "b" THEN REWRITE_TAC[ETA2_MASK_INDICES]; ALL_TAC] THEN
  MP_TAC(ISPECL [`pc:num`;`table:int64`;`a:num`;`b:num`;`CONS(EventLoad(buf,8)) e`] ETA2_LOAD_TABLE) THEN
  ASM_REWRITE_TAC[] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s3" THEN
  SUBGOAL_THEN `!i. i < 16 ==> val(word_subword (nibbles:int128) (8*i,8):byte) < 16` ASSUME_TAC THENL
   [ASM_SIMP_TAC[VAL_WORD_ZX;DIMINDEX_4;DIMINDEX_8;ARITH_RULE `4<=8`] THEN
    X_GEN_TAC `i:num` THEN DISCH_TAC THEN ASM_SIMP_TAC[] THEN
    REWRITE_TAC[word_zx;VAL_WORD;DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV THEN
    MP_TAC(ISPEC `word_subword (d:int64) (4*i,4):4 word` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_4] THEN CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`nibbles:int128`;`pc:num`] ETA2_REDUCE_REGISTER) THEN ASM_REWRITE_TAC[] THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s4" THEN
  REABBREV_TAC `reduced:int128 = read Q6 s4` THEN
  MP_TAC(ISPECL [`pc:num`;`reduced:int128`] ETA2_WIDEN_NIBBLES) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s5" THEN
  MAP_EVERY REABBREV_TAC [`leftsrc:int128 = read Q16 s5`; `rightsrc:int128 = read Q18 s5`] THEN
  MP_TAC(ISPECL [`pc:num`;`leftsrc:int128`;`rightsrc:int128`;`word(num_of_wordlist(ETA2_TABLE_ROW a)):int128`;`word(num_of_wordlist(ETA2_TABLE_ROW b)):int128`] ETA2_GATHER) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s6" THEN
  MAP_EVERY REABBREV_TAC [`cx:int128 = read Q16 s6`; `cy:int128 = read Q18 s6`] THEN
  MP_TAC(ISPECL [`pc:num`;`cx:int128`;`cy:int128`] ETA2_WIDEN) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s7" THEN
  (let summarize g src dst out m =
     let idx = mk_small_numeral g in
     let pred = mk_icomb(mk_icomb(`ETA2_PACKET_LANES`, `nibbles:int128`),idx) in
     MP_TAC(SPECL [`d:int64`;idx;pred;m;src;dst;out] ETA2_GROUP_MACHINE) THEN
     ANTS_TAC THENL
      [ASM_REWRITE_TAC[ETA2_PACKET_LANES;ETA2_NIBBLE;word_ult;relational2] THEN
       CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[ADD_CLAUSES;MULT_CLAUSES] THEN
       REPEAT CONJ_TAC THEN X_GEN_TAC `j:num` THEN DISCH_TAC THEN
       ASSUME_TAC(MATCH_MP (ARITH_RULE `j < 8 ==> j < 16 /\ 8+j < 16 /\ j+8 < 16`) (ASSUME `j < 8`)) THEN
       ASM_SIMP_TAC[ARITH_RULE `j+8 = 8+j`; VAL_WORD_ZX; DIMINDEX_4; DIMINDEX_8; ARITH_RULE `4<=8`] THEN
       CONV_TAC WORD_REDUCE_CONV THEN ASM_REWRITE_TAC[];
       REWRITE_TAC[MULT_CLAUSES;ADD_CLAUSES] THEN STRIP_TAC] in
   summarize 0 `leftsrc:int128` `cx:int128` `word_join (read Q17 s7) (read Q16 s7):int256` `a:num` THEN
   summarize 1 `rightsrc:int128` `cy:int128` `word_join (read Q19 s7) (read Q18 s7):int256` `b:num`) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[APPEND]);;

(* The partial store consumes successive 4-, 2- and 1-lane pieces. *)
let ETA2_SHORT_EVENTS = new_definition
 `ETA2_SHORT_EVENTS (dst:int64) pc k e =
    let q = 4 <= k in
    let d = 2 <= k MOD 4 in
    let w = ODD k in
    let dst1 = if q then word_add dst (word 16) else dst in
    let dst2 = if d then word_add dst1 (word 8) else dst1 in
    let e = CONS (EventJump(word(pc+0x114),word(pc+(if q then 0x118 else 0x120)))) e in
    let e = if q then CONS (EventStore(dst,16)) e else e in
    let e = CONS (EventJump(word(pc+0x120),word(pc+(if d then 0x124 else 0x12c)))) e in
    let e = if d then CONS (EventStore(dst1,8)) e else e in
    let e = CONS (EventJump(word(pc+0x12c),word(pc+(if w then 0x130 else 0x134)))) e in
    if w then CONS (EventStore(dst2,4)) e else e`;;

let eta2_split_store =
  let split = CONJUNCTS READ_MEMORY_BYTESIZED_UNSPLIT in
  fun th -> CONV_RULE(TOP_DEPTH_CONV (GEN_REWRITE_CONV I [el 1 split;el 2 split])) th;;

let ETA2_STP_PREFIX = prove
 (`!dst (s:armstate) lo hi.
    read(memory :> bytes128 dst) s = lo /\
    read(memory :> bytes128(word_add dst (word 16))) s = hi ==>
    !i. i < 8 ==> read(memory :> bytes32(word_add dst (word(4*i)))) s =
                  word_subword (word_join hi lo:int256) (32*i,32)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  RULE_ASSUM_TAC eta2_split_store THEN
  RULE_ASSUM_TAC(REWRITE_RULE[GSYM WORD_ADD_ASSOC]) THEN
  RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV WORD_ADD_CONV)) THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let ETA2_STORE_SHORT = prove
 (`!k. k < 8 ==> !dst pc (lo:int128) (hi:int128) e.
    nonoverlapping (word pc,360) (dst,4*k) ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0x110) /\ read X0 s = dst /\
           read X4 s = word k /\ read Q16 s = lo /\ read Q17 s = hi /\
           read events s = e)
      (\s. read PC s = word(pc+0x134) /\
           (!i. i < k ==> read (memory :> bytes32(word_add dst (word(4*i)))) s =
                          word_subword (word_join hi lo:int256) (32*i,32)) /\
           read events s = ETA2_SHORT_EVENTS dst pc k e)
      (MAYCHANGE [PC;X7] ,, MAYCHANGE [Q16] ,, MAYCHANGE [events] ,,
       MAYCHANGE [memory :> bytes(dst,4*k)])`,
  CONV_TAC EXPAND_CASES_CONV THEN REPEAT CONJ_TAC THENL
  map (fun k ->
    REPEAT GEN_TAC THEN CONV_TAC NUM_REDUCE_CONV THEN DISCH_TAC THEN
    ENSURES_INIT_TAC "s0" THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC
      (1--(4 + (if k land 4 = 0 then 0 else 2) + (if k land 2 = 0 then 0 else 2) + k mod 2)) THEN
    RULE_ASSUM_TAC eta2_split_store THEN
    RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[GSYM WORD_ADD_ASSOC; WORD_ADD_0; WORD_ADD]) THEN
    RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV WORD_ADD_CONV)) THEN
    RULE_ASSUM_TAC(CONV_RULE NUM_REDUCE_CONV) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[ETA2_SHORT_EVENTS; LET_DEF; LET_END_DEF] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    TRY(CONV_TAC(ONCE_DEPTH_CONV EXPAND_CASES_CONV)) THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    ASM_REWRITE_TAC[WORD_ADD_0;GSYM WORD_ADD_ASSOC;WORD_ADD] THEN
    CONV_TAC(DEPTH_CONV WORD_ADD_CONV) THEN
    CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
    ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST) (0--7));;

(* The fast path may overstore in each group; only the accepted prefix counts. *)
let ETA2_FAST_STORE = prove
 (`!pc (dst:int64) n a b u0 u1 v0 v1 e.
    16 < n /\ n <= 256 /\ a <= 8 /\ b <= 8 /\
    nonoverlapping (word pc,360) (dst,4*n) ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0xd0) /\ read X0 s = dst /\ read X4 s = word n /\
           read X12 s = word a /\ read X13 s = word b /\
           read Q16 s = u0 /\ read Q17 s = u1 /\
           read Q18 s = v0 /\ read Q19 s = v1 /\ read events s = e)
      (\s. read PC s = word(pc+0xf0) /\ read X4 s = word(n-(a+b)) /\
           read X0 s = word_add dst (word(4*(a+b))) /\
           (!i. i < a ==> read(memory :> bytes32(word_add dst (word(4*i)))) s =
                          word_subword (word_join u1 u0:int256) (32*i,32)) /\
           (!i. i < b ==> read(memory :> bytes32(word_add dst (word(4*(a+i))))) s =
                          word_subword (word_join v1 v0:int256) (32*i,32)) /\
           read events s = APPEND [EventStore(word_add dst (word(4*a)),32);
                                   EventStore(dst,32);
                                   EventJump(word(pc+0xd4),word(pc+0xd8))] e)
      (MAYCHANGE [PC;X0;X4] ,, MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
       MAYCHANGE [memory :> bytes(dst,4*n)])`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word n:int64) = n` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `~(n <= 16)` ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
  SUBGOAL_THEN `16 <= n /\ ~(val(word_sub (word n) (word 16):int64) = 0)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0] THEN CONV_TAC WORD_REDUCE_CONV THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word n:int64) = n`;ASSUME `16 <= n /\ ~(val(word_sub (word n) (word 16):int64) = 0)`]) THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [3;4] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_SHL_WORD]) THEN
  SUBGOAL_THEN `!i. i < a ==> read(memory :> bytes32(word_add dst (word(4*i)))) s4 =
                             word_subword (word_join (u1:int128) (u0:int128):int256) (32*i,32)` ASSUME_TAC THENL
   [X_GEN_TAC `i:num` THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`dst:int64`; `s4:armstate`; `u0:int128`; `u1:int128`] ETA2_STP_PREFIX) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN(MP_TAC o SPEC `i:num`) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[]]; ALL_TAC] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (5--8) THEN
  SUBGOAL_THEN `!i. i < b ==> read(memory :> bytes32(word_add dst (word(4*(a+i))))) s8 =
                             word_subword (word_join (v1:int128) (v0:int128):int256) (32*i,32)` ASSUME_TAC THENL
   [X_GEN_TAC `i:num` THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`word_add dst (word(4*a)):int64`; `s8:armstate`; `v0:int128`; `v1:int128`] ETA2_STP_PREFIX) THEN
    REWRITE_TAC[GSYM WORD_ADD_ASSOC; GSYM WORD_ADD] THEN ASM_REWRITE_TAC[] THEN
    DISCH_THEN(MP_TAC o SPEC `i:num`) THEN ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[LEFT_ADD_DISTRIB]]; ALL_TAC] THEN
  RULE_ASSUM_TAC(CONV_RULE NUM_REDUCE_CONV) THEN ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[APPEND;WORD_SHL_WORD;SOME_FLAGS] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REPEAT CONJ_TAC THENL
   [SUBGOAL_THEN `a+b <= n` ASSUME_TAC THENL [ASM_ARITH_TAC; ASM_SIMP_TAC[WORD_SUB] THEN CONV_TAC WORD_RULE];
    CONV_TAC WORD_RULE;
    MONOTONE_MAYCHANGE_TAC]);;

(* A full store writes eight lanes. A short store writes the remaining capacity. *)
let ETA2_GROUP_EVENTS = new_definition
 `ETA2_GROUP_EVENTS dst pc k e =
    if k < 8 then ETA2_SHORT_EVENTS dst pc k
      (CONS (EventJump(word(pc+0x104),word(pc+0x110))) e)
    else APPEND [EventJump(word(pc+0x10c),word(pc+0x134)); EventStore(dst,32);
                 EventJump(word(pc+0x104),word(pc+0x108))] e`;;

let ETA2_STORE_GROUP = prove
 (`!k dst pc (lo:int128) hi e.
     k <= 16 /\ nonoverlapping (word pc,360) (dst,4*k) ==>
    ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
            read PC s = word(pc+0x100) /\ read X0 s = dst /\
            read X4 s = word k /\ read Q16 s = lo /\ read Q17 s = hi /\
            read events s = e)
       (\s. read PC s = word(pc+0x134) /\
            (!i. i < MIN k 8 ==>
                 read(memory :> bytes32(word_add dst (word(4*i)))) s =
                 word_subword (word_join hi lo:int256) (32*i,32)) /\
            read events s = ETA2_GROUP_EVENTS dst pc k e)
       (MAYCHANGE [PC;X7] ,, MAYCHANGE [Q16] ,, MAYCHANGE SOME_FLAGS ,,
        MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(dst,4*k)])`,
  REWRITE_TAC[SOME_FLAGS] THEN REPEAT STRIP_TAC THEN VAL_INT64_TAC `k:num` THEN
  ENSURES_INIT_TAC "s0" THEN ASM_CASES_TAC `k < 8` THENL
   [SUBGOAL_THEN `~(8 <= k)` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--2) THEN
    MP_TAC(SPECL [`dst:int64`; `pc:num`; `lo:int128`; `hi:int128`;
      `CONS (EventJump(word(pc+0x104),word(pc+0x110))) e`]
      (MATCH_MP (SPEC `k:num` ETA2_STORE_SHORT) (ASSUME `k<8`))) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s3" THEN
    ASM_REWRITE_TAC[] THEN ENSURES_FINAL_STATE_TAC THEN
    ASM_SIMP_TAC[ETA2_GROUP_EVENTS; ARITH_RULE `k < 8 ==> MIN k 8 = k`];
    SUBGOAL_THEN `8 <= k /\ 32 <= 4*k` STRIP_ASSUME_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (1--4) THEN ENSURES_FINAL_STATE_TAC THEN
    ASM_SIMP_TAC[ETA2_GROUP_EVENTS; APPEND; ARITH_RULE `8 <= k ==> MIN k 8 = 8`] THEN
    MATCH_MP_TAC ETA2_STP_PREFIX THEN ASM_REWRITE_TAC[]]);;
(* After each store, test whether the group fills the polynomial. *)
let ETA2_AFTER_GROUP_EVENTS = new_definition
 `ETA2_AFTER_GROUP_EVENTS pc last k a e =
    if k <= a then CONS (EventJump(word(pc+0x138),word(pc+0x158))) e else
    let e = CONS (EventJump(word(pc+0x138),word(pc+0x13c))) e in
    if last then CONS (EventJump(word(pc+0x144),word(pc+0xf0))) e
    else APPEND [EventJump(word(pc+0x154),word(pc+0x100));
                 EventJump(word(pc+0x144),word(pc+0x148))] e`;;

let ETA2_AFTER_GROUP = prove
 (`!dst pc k a b last (v0:int128) v1 e.
     k <= 16 /\ a <= 8 ==>
     ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
            read PC s = word(pc+0x134) /\ read X0 s = dst /\ read X4 s = word k /\
            read X6 s = word(if last then 1 else 2) /\
            read X12 s = word a /\ read X13 s = word b /\
            read Q18 s = v0 /\ read Q19 s = v1 /\ read events s = e)
       (\s. read PC s = word(pc+(if k <= a then 0x15c else if last then 0xf0 else 0x100)) /\
            read X4 s = word(k-a) /\
            (~(k <= a) ==> read X0 s = word_add dst (word(4*a))) /\
            (~(k <= a) /\ ~last ==> read Q16 s = v0 /\ read Q17 s = v1 /\
                 read X12 s = word b /\ read X6 s = word 1) /\
            read events s = ETA2_AFTER_GROUP_EVENTS pc last k a e)
       (MAYCHANGE [PC;X0;X4;X6;X12] ,, MAYCHANGE [Q16;Q17] ,,
        MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events])`,
  REWRITE_TAC[SOME_FLAGS] THEN REPEAT STRIP_TAC THEN VAL_INT64_TAC `k:num` THEN
  VAL_INT64_TAC `a:num` THEN
  ENSURES_INIT_TAC "s0" THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1] THEN
  RULE_ASSUM_TAC (REWRITE_RULE[NOCARRY_WORD_SUB; VAL_WORD_SUB_EQ_0;
    ASSUME `val(word k:int64) = k`; ASSUME `val(word a:int64) = a`]) THEN
  ASM_CASES_TAC `k <= a` THENL
   [SUBGOAL_THEN `~(a <= k /\ ~(k = a)) /\ ~(a < k)` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (2--3);
    SUBGOAL_THEN `a <= k /\ ~(k=a) /\ a < k` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_CASES_TAC `last:bool` THENL
     [UNDISCH_THEN `read X6 s1 = word (if last then 1 else 2)`
        (ASSUME_TAC o REWRITE_RULE[ASSUME `last:bool`]) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (2--5);
      UNDISCH_THEN `read X6 s1 = word (if last then 1 else 2)`
        (ASSUME_TAC o REWRITE_RULE[ASSUME `~last`]) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC (2--9)]] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_SIMP_TAC[ETA2_AFTER_GROUP_EVENTS; LET_DEF; LET_END_DEF;
    APPEND; WORD_SHL_WORD; WORD_SUB; ARITH_RULE `k <= a ==> k-a = 0`] THEN
  CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MULT_SYM] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `(k:num) = a` SUBST1_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[WORD_SUB_REFL]]);;
let ETA2_TAIL_EVENTS = new_definition
 `ETA2_TAIL_EVENTS dst pc k a b e =
    let e1 = ETA2_AFTER_GROUP_EVENTS pc F k a (ETA2_GROUP_EVENTS dst pc k e) in
    if k <= a then e1 else
    ETA2_AFTER_GROUP_EVENTS pc T (k-a) b
      (ETA2_GROUP_EVENTS (word_add dst (word(4*a))) pc (k-a) e1)`;;

let eta2_tail_bigstep th args label =
  MP_TAC(REWRITE_RULE[SOME_FLAGS](SPECL args th)) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC label;;

let ETA2_TAIL_STORE = prove
 (`!pc dst k a b (u0:int128) u1 (v0:int128) v1 e.
    1 <= k /\ k <= 16 /\ a <= 8 /\ b <= 8 /\
    nonoverlapping (word pc,360) (dst,4*k) ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0xfc) /\ read X0 s = dst /\ read X4 s = word k /\
           read X12 s = word a /\ read X13 s = word b /\
           read Q16 s = u0 /\ read Q17 s = u1 /\ read Q18 s = v0 /\ read Q19 s = v1 /\
           read events s = e)
      (\s. read PC s = word(pc+(if k <= a+b then 0x15c else 0xf0)) /\
           read X4 s = word(k-(a+b)) /\
           (a+b < k ==> read X0 s = word_add dst (word (4*(a+b)))) /\
           (!i. i < MIN a k ==> read(memory :> bytes32(word_add dst (word(4*i)))) s =
                                 word_subword (word_join u1 u0:int256) (32*i,32)) /\
           (!i. i < MIN b (k-a) ==> read(memory :> bytes32(word_add dst (word(4*(a+i))))) s =
                                     word_subword (word_join v1 v0:int256) (32*i,32)) /\
           read events s = ETA2_TAIL_EVENTS dst pc k a b e)
      (MAYCHANGE [PC;X0;X4;X6;X7;X12] ,, MAYCHANGE [Q16;Q17] ,,
       MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(dst,4*k)])`,
  REWRITE_TAC[SOME_FLAGS] THEN REPEAT STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1] THEN
  eta2_tail_bigstep ETA2_STORE_GROUP
    [`k:num`; `dst:int64`; `pc:num`; `u0:int128`; `u1:int128`;
     `e:uarch_event list`] "s2" THEN
  eta2_tail_bigstep ETA2_AFTER_GROUP
    [`dst:int64`; `pc:num`; `k:num`; `a:num`; `b:num`; `F`; `v0:int128`;
     `v1:int128`; `ETA2_GROUP_EVENTS dst pc k e`] "s3" THEN
  ASM_CASES_TAC `k <= a` THENL
   [ENSURES_FINAL_STATE_TAC THEN ASM_SIMP_TAC[ETA2_TAIL_EVENTS; LET_DEF; LET_END_DEF;
      ARITH_RULE `k <= a ==> k <= a+b /\ k-a = 0 /\ k-(a+b) = 0 /\ ~(a+b<k)`;
      ARITH_RULE `MIN n 0 = 0`; LT] THEN
    X_GEN_TAC `i:num` THEN DISCH_TAC THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN `a < k /\ k-a <= 16 /\ a+(k-a) = k`
    STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `read X0 s3 = word_add dst (word(4*a))` ASSUME_TAC THENL
   [ASM_MESON_TAC[]; ALL_TAC] THEN
  SUBGOAL_THEN `nonoverlapping (word pc:int64,360) (word_add dst (word (4*a)),4*(k-a))`
    ASSUME_TAC THENL [NONOVERLAPPING_TAC; ALL_TAC] THEN
  UNDISCH_THEN `~(k <= a) ==> read Q16 s3 = v0 /\ read Q17 s3 = v1 /\
                     read X12 s3 = word b /\ read X6 s3 = word 1`
    (fun th -> MP_TAC(MATCH_MP th (ASSUME `~(k <= a)`)) THEN STRIP_TAC) THEN
  SUBGOAL_THEN `!i. i < a ==> read(memory :> bytes32(word_add dst (word(4*i)))) s3 =
                                word_subword (word_join (u1:int128) (u0:int128):int256) (32*i,32)`
    ASSUME_TAC THENL [GEN_TAC THEN DISCH_TAC THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
  eta2_tail_bigstep ETA2_STORE_GROUP
    [`k-a`; `word_add dst (word(4*a)):int64`; `pc:num`; `v0:int128`; `v1:int128`;
     `ETA2_AFTER_GROUP_EVENTS pc F k a (ETA2_GROUP_EVENTS dst pc k e)`] "s4" THEN
  ASM_REWRITE_TAC[] THEN
  eta2_tail_bigstep ETA2_AFTER_GROUP
    [`word_add dst (word(4*a)):int64`; `pc:num`; `k-a`; `b:num`; `b:num`; `T`;
     `v0:int128`; `v1:int128`;
     `ETA2_GROUP_EVENTS (word_add dst (word(4*a))) pc (k-a)
        (ETA2_AFTER_GROUP_EVENTS pc F k a (ETA2_GROUP_EVENTS dst pc k e))`] "s5" THEN
  ASM_REWRITE_TAC[] THEN ENSURES_FINAL_STATE_TAC THEN
  ASM_SIMP_TAC[ETA2_TAIL_EVENTS; LET_DEF; LET_END_DEF; ARITH_RULE `a < k ==> MIN a k = a`;
    ARITH_RULE `a < k ==> (k-a <= b <=> k<=a+b)`; ARITH_RULE `(k-a)-b = k-(a+b)`;
    GSYM WORD_ADD_ASSOC; GSYM WORD_ADD; LEFT_ADD_DISTRIB] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[GSYM WORD_ADD_ASSOC; GSYM WORD_ADD]) THEN
  CONJ_TAC THENL
   [DISCH_TAC THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
    GEN_TAC THEN DISCH_TAC THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC]);;

let ETA2_STORE_EVENTS = define
 `ETA2_STORE_EVENTS dst pc k a b e =
    if 16 < k then
      APPEND [EventStore(word_add dst (word(4*a)),32);EventStore(dst,32);
              EventJump(word(pc+0xd4),word(pc+0xd8))] e
    else ETA2_TAIL_EVENTS dst pc k a b (CONS(EventJump(word(pc+0xd4),word(pc+0xfc))) e)`;;

let ETA2_STORE_BATCH = prove
 (`!pc dst k a b (u0:int128) u1 (v0:int128) v1 e.
    1 <= k /\ k <= 256 /\ a <= 8 /\ b <= 8 /\
    nonoverlapping (word pc,360) (dst,4*k) ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0xd0) /\ read X0 s = dst /\ read X4 s = word k /\
           read X12 s = word a /\ read X13 s = word b /\
           read Q16 s = u0 /\ read Q17 s = u1 /\ read Q18 s = v0 /\ read Q19 s = v1 /\ read events s = e)
      (\s. read PC s = word(pc+(if k <= a+b then 0x15c else 0xf0)) /\
           read X4 s = word(k-(a+b)) /\ (~(k<=a+b) ==> read X0 s = word_add dst (word(4*(a+b)))) /\
           (!i. i < MIN a k ==> read(memory:>bytes32(word_add dst (word(4*i)))) s = word_subword(word_join u1 u0:int256)(32*i,32)) /\
           (!i. i < MIN b (k-a) ==> read(memory:>bytes32(word_add dst (word(4*(a+i))))) s = word_subword(word_join v1 v0:int256)(32*i,32)) /\
           read events s = ETA2_STORE_EVENTS dst pc k a b e)
      (MAYCHANGE [PC;X0;X4;X6;X7;X12] ,, MAYCHANGE [Q16;Q17] ,,
       MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(dst,4*k)])`,
  REWRITE_TAC[SOME_FLAGS] THEN REPEAT STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
  ASM_CASES_TAC `16 < k` THENL
   [MP_TAC(REWRITE_RULE[SOME_FLAGS](SPECL [`pc:num`;`dst:int64`;`k:num`;`a:num`;`b:num`;`u0:int128`;`u1:int128`;`v0:int128`;`v1:int128`;`e:(uarch_event)list`] ETA2_FAST_STORE)) THEN
    ASM_REWRITE_TAC[] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s1" THEN
    SUBGOAL_THEN `~(k <= a+b) /\ MIN a k = a /\ MIN b (k-a) = b` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[ETA2_STORE_EVENTS];
    VAL_INT64_TAC `k:num` THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN
    SUBGOAL_THEN `~(16 <= val(word k:int64) /\ ~(val(word_sub(word k)(word 16):int64)=0))` ASSUME_TAC THENL
     [ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0] THEN CONV_TAC WORD_REDUCE_CONV THEN ASM_ARITH_TAC;ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[VAL_WORD_SUB_EQ_0]) THEN RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
    SUBGOAL_THEN `~(16 <= k /\ ~(k = 16))` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word k:int64) = k`; ASSUME `~(16 <= k /\ ~(k = 16))`]) THEN
    MP_TAC(REWRITE_RULE[SOME_FLAGS](SPECL [`pc:num`;`dst:int64`;`k:num`;`a:num`;`b:num`;`u0:int128`;`u1:int128`;`v0:int128`;`v1:int128`;`CONS(EventJump(word(pc+0xd4),word(pc+0xfc))) e`]
                           ETA2_TAIL_STORE)) THEN
    ASM_REWRITE_TAC[ARITH_RULE `k <= 16 <=> ~(16 < k)`] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s3" THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[ETA2_STORE_EVENTS]]);;

(* A block reads eight bytes and two shuffle rows. The acceptance mask
   determines both rows, the store addresses and the loop branches. *)
let ETA2_BLOCK_EVENTS = new_definition
 `ETA2_BLOCK_EVENTS res buf table pc i k ma mb a b e =
    let dst = word_add res (word(4*(256-k))) in
    let e = APPEND [EventLoad(word_add table (word(16*mb)),16);
                    EventLoad(word_add table (word(16*ma)),16);
                    EventLoad(word_add buf (word(8*i)),8)] e in
    if 16 < k then
      APPEND [EventStore(word_add dst (word(4*a)),32); EventStore(dst,32);
              EventJump(word(pc+0xd4),word(pc+0xd8))] e
    else ETA2_TAIL_EVENTS dst pc k a b
           (CONS (EventJump(word(pc+0xd4),word(pc+0xfc))) e)`;;

let ETA2_RUN_EVENTS = new_recursive_definition num_RECURSION
 `(ETA2_RUN_EVENTS res buf table pc ra mask 0 i k e = e) /\
  (ETA2_RUN_EVENTS res buf table pc ra mask (SUC n) i k e =
    let p = \g j. EL (16*i+8*g+j) mask in
    let a = ETA2_PACKET_COUNT (p 0) in
    let b = ETA2_PACKET_COUNT (p 1) in
    let e = ETA2_BLOCK_EVENTS res buf table pc i k
              (ETA2_PACKET_MASK (p 0)) (ETA2_PACKET_MASK (p 1)) a b e in
    if k <= a+b then CONS (EventJump(word(pc+0x164),ra)) e
    else if n = 0 then
      APPEND [EventJump(word(pc+0x164),ra);
              EventJump(word(pc+0xf8),word(pc+0x15c));
              EventJump(word(pc+0xf4),word(pc+0xf8))] e
    else ETA2_RUN_EVENTS res buf table pc ra mask n (i+1) (k-(a+b))
           (CONS (EventJump(word(pc+0xf4),word(pc+0x60))) e))`;;
(* The partial stores cover at most the remaining output capacity. *)
let ETA2_SHORT_INBOUNDS = prove
 (`!k. k < 8 ==> !res pc j rr e.
    j+k <= 256 /\ memaccess_inbounds e rr [res,1024] ==>
    memaccess_inbounds (ETA2_SHORT_EVENTS (word_add res (word(4*j))) pc k e)
                       rr [res,1024]`,
  CONV_TAC EXPAND_CASES_CONV THEN REPEAT CONJ_TAC THEN REPEAT GEN_TAC THEN
  REWRITE_TAC[ETA2_SHORT_EVENTS; LET_DEF; LET_END_DEF] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
  STRIP_TAC THEN ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THEN CONTAINED_TAC);;

let ETA2_GROUP_INBOUNDS = prove
 (`!res pc j k rr e. j+k <= 256 /\ memaccess_inbounds e rr [res,1024] ==>
    memaccess_inbounds (ETA2_GROUP_EVENTS (word_add res (word(4*j))) pc k e)
                       rr [res,1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[ETA2_GROUP_EVENTS] THEN
  COND_CASES_TAC THENL
   [MATCH_MP_TAC(MATCH_MP (SPEC `k:num` ETA2_SHORT_INBOUNDS) (ASSUME `k < 8`)) THEN
    ASM_REWRITE_TAC[]; REWRITE_TAC[APPEND]] THEN
  POP_ASSUM_LIST(fun ths -> MAP_EVERY (MP_TAC o REWRITE_RULE[memaccess_inbounds]) ths) THEN
  REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
  REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONTAINED_TAC);;

let ETA2_AFTER_GROUP_INBOUNDS = prove
 (`!pc last k a e rr wr. memaccess_inbounds e rr wr ==>
    memaccess_inbounds (ETA2_AFTER_GROUP_EVENTS pc last k a e) rr wr`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ETA2_AFTER_GROUP_EVENTS; LET_DEF; LET_END_DEF] THEN
  REPEAT COND_CASES_TAC THEN REWRITE_TAC[APPEND;memaccess_inbounds;ALL]);;

let ETA2_TAIL_INBOUNDS = prove
 (`!res pc j k a b rr e. j+k <= 256 /\ memaccess_inbounds e rr [res,1024] ==>
    memaccess_inbounds (ETA2_TAIL_EVENTS (word_add res (word(4*j))) pc k a b e)
                       rr [res,1024]`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[ETA2_TAIL_EVENTS; LET_DEF; LET_END_DEF] THEN
  COND_CASES_TAC THEN REPEAT(FIRST
    [MATCH_MP_TAC ETA2_AFTER_GROUP_INBOUNDS;
     MATCH_MP_TAC ETA2_GROUP_INBOUNDS THEN CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC];
     CHANGED_TAC(REWRITE_TAC[GSYM WORD_ADD_ASSOC; GSYM WORD_ADD; GSYM LEFT_ADD_DISTRIB])]) THEN
  ASM_REWRITE_TAC[]);;
let ETA2_BLOCK_INBOUNDS = prove
 (`!res buf table pc i k ma mb a b e len.
    8*(i+1) <= len /\ k <= 256 /\ ma < 256 /\ mb < 256 /\ a <= 8 /\
    memaccess_inbounds e [buf,len;table,4096] [res,1024] ==>
    memaccess_inbounds (ETA2_BLOCK_EVENTS res buf table pc i k ma mb a b e)
                       [buf,len;table,4096] [res,1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[ETA2_BLOCK_EVENTS; LET_DEF; LET_END_DEF] THEN
  ABBREV_TAC `loads = APPEND [EventLoad(word_add table (word(16*mb)):int64,16);
    EventLoad(word_add table (word(16*ma)),16); EventLoad(word_add buf (word(8*i)),8)] e` THEN
  SUBGOAL_THEN `memaccess_inbounds (loads:uarch_event list) [buf,len;table,4096] [res,1024]` ASSUME_TAC THENL
   [EXPAND_TAC "loads" THEN ASM_REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN
    REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN REPEAT CONJ_TAC THEN
    FIRST [DISJ1_TAC THEN CONTAINED_TAC; DISJ2_TAC THEN CONTAINED_TAC]; ALL_TAC] THEN
  COND_CASES_TAC THENL
   [ASM_REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN
    REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
    REPEAT CONJ_TAC THEN CONTAINED_TAC;
    MATCH_MP_TAC ETA2_TAIL_INBOUNDS THEN CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ONCE_REWRITE_TAC[MEMACCESS_INBOUNDS_CONS] THEN ASM_REWRITE_TAC[memaccess_inbounds; ALL]]);;

let ETA2_PACKET_BOUNDS = prove
 (`!p. ETA2_PACKET_MASK p < 256 /\ ETA2_PACKET_COUNT p <= 8`,
  GEN_TAC THEN REWRITE_TAC[ETA2_PACKET_MASK; ETA2_PACKET_COUNT] THEN
  MAP_EVERY (fun i -> MP_TAC(SPEC (mk_comb(`p:num->bool`,mk_small_numeral i)) BITVAL_BOUND)) (0--7) THEN ARITH_TAC);;

let ETA2_RUN_INBOUNDS = prove
 (`!blocks i k e res buf table pc ra mask len.
    8*(i+blocks) <= len /\ k <= 256 /\
    memaccess_inbounds e [buf,len;table,4096] [res,1024] ==>
    memaccess_inbounds (ETA2_RUN_EVENTS res buf table pc ra mask blocks i k e)
                       [buf,len;table,4096] [res,1024]`,
  INDUCT_TAC THEN REPEAT GEN_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[ETA2_RUN_EVENTS] THEN
  REWRITE_TAC[LET_DEF; LET_END_DEF] THEN BETA_TAC THEN
  ABBREV_TAC `lo = \j. EL (16*i+8*0+j) (mask:bool list)` THEN
  ABBREV_TAC `hi = \j. EL (16*i+8*1+j) (mask:bool list)` THEN
  MAP_EVERY (STRIP_ASSUME_TAC o C SPEC ETA2_PACKET_BOUNDS) [`lo:num->bool`;`hi:num->bool`] THEN
  ABBREV_TAC `blocktrace = ETA2_BLOCK_EVENTS res buf table pc i k
    (ETA2_PACKET_MASK lo) (ETA2_PACKET_MASK hi) (ETA2_PACKET_COUNT lo) (ETA2_PACKET_COUNT hi) e` THEN
  SUBGOAL_THEN `memaccess_inbounds (blocktrace:uarch_event list) [buf,len;table,4096] [res,1024]` ASSUME_TAC THENL
   [EXPAND_TAC "blocktrace" THEN MATCH_MP_TAC ETA2_BLOCK_INBOUNDS THEN ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THENL
   [ALL_TAC; REWRITE_TAC[APPEND]; FIRST_X_ASSUM MATCH_MP_TAC THEN
    REPEAT CONJ_TAC THEN TRY ASM_ARITH_TAC] THEN
  UNDISCH_TAC `memaccess_inbounds (blocktrace:uarch_event list) [buf,len;table,4096] [res,1024]` THEN
  REWRITE_TAC[memaccess_inbounds;ALL]);;

let ETA2_NEXT_BUFFER = prove
 (`!pc n e. 8 <= n /\ n < 2 EXP 64 ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word(pc+0xf0) /\ read X2 s = word n /\ read events s = e)
      (\s. read PC s = word(pc+(if n=8 then 0x15c else 0x60)) /\
           read X2 s = word(n-8) /\
           read events s = (if n=8 then
                  APPEND [EventJump(word(pc+0xf8),word(pc+0x15c));
                          EventJump(word(pc+0xf4),word(pc+0xf8))] e
                else CONS(EventJump(word(pc+0xf4),word(pc+0x60))) e))
      (MAYCHANGE [PC;X2] ,, MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `val(word n:int64) = n` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN ASM_REWRITE_TAC[DIMINDEX_64]; ALL_TAC] THEN
  ASM_CASES_TAC `n = 8` THENL
   [ASM_REWRITE_TAC[APPEND] THEN ARM_SIM_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2;3] THEN
    CONV_TAC NUM_REDUCE_CONV;
    ASM_REWRITE_TAC[APPEND] THEN ENSURES_INIT_TAC "s0" THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC [1;2] THEN ENSURES_FINAL_STATE_TAC THEN
    ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0; WORD_SUB;SOME_FLAGS] THEN CONV_TAC WORD_REDUCE_CONV THEN
    ASM_REWRITE_TAC[]] THEN REWRITE_TAC[SOME_FLAGS] THEN MONOTONE_MAYCHANGE_TAC);;

(* Relate the sixteen sampled nibbles to the whole-input acceptance mask. *)
let REJ_MASK_ETA2 = define
  `REJ_MASK_ETA2 (l:byte list) : bool list =
   MAP (\x:int16. val x < 15) (NIBBLES_OF_BYTES l)`;;

let NIBBLES_OF_BYTES_SUB_LIST = prove
 (`!l a b. NIBBLES_OF_BYTES(SUB_LIST(a,b) l) =
           SUB_LIST(2*a,2*b)(NIBBLES_OF_BYTES l)`,
  LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; SUB_LIST_CLAUSES; APPEND;
              MULT_CLAUSES; ADD_CLAUSES; ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`] THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES; APPEND]);;

let SUB_LIST_MAP_GEN = prove
 (`!(f:A->B) l a b. SUB_LIST(a,b)(MAP f l) = MAP f (SUB_LIST(a,b) l)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[MAP; SUB_LIST_CLAUSES]);;

let REJ_MASK_ETA2_SUB_LIST = prove
 (`!l a b. REJ_MASK_ETA2(SUB_LIST(a,b) l) = SUB_LIST(2*a,2*b)(REJ_MASK_ETA2 l)`,
  REWRITE_TAC[REJ_MASK_ETA2; NIBBLES_OF_BYTES_SUB_LIST; SUB_LIST_MAP_GEN]);;


let ETA2_REJ_MASK_NIBBLES = prove
 (`!bs. REJ_MASK_ETA2 bs = MAP (\n:4 word. val n < 15) (BYTES_TO_NIBBLES bs)`,
  GEN_TAC THEN REWRITE_TAC[REJ_MASK_ETA2; NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES; GSYM MAP_o;o_DEF] THEN
  SIMP_TAC[VAL_WORD_ZX; DIMINDEX_4; DIMINDEX_16; ARITH_RULE `4 <= 16`]);;

let ETA2_INPUT_GROUP_MASK = prove
 (`!d g j. j < 8 ==> EL j (MAP (\n:4 word. val n < 15) (ETA2_NIBBLE4 d g)) =
                         (val(ETA2_NIBBLE d (8*g+j)) < 15)`,
  GEN_TAC THEN GEN_TAC THEN CONV_TAC EXPAND_CASES_CONV THEN
  REWRITE_TAC[ETA2_NIBBLE4;ETA2_NIBBLE;MAP;EL_CONS] THEN CONV_TAC NUM_REDUCE_CONV THEN
  SIMP_TAC[VAL_WORD_ZX;DIMINDEX_4;DIMINDEX_8;ARITH_RULE `4 <= 8`]);;


let ETA2_INPUT_CHUNK = prove
 (`!buf len bs i s (d:int64).
    8*(i+1) <= len /\ LENGTH bs = len /\
    read(memory:>bytes(buf,len)) s = num_of_wordlist bs /\
    read(memory:>bytes64(word_add buf (word(8*i)))) s = d
    ==> REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES(SUB_LIST(8*i,8)bs)) = APPEND(ETA2_GROUP d 0)(ETA2_GROUP d 1) /\
        (!g j. g<2 /\ j<8 ==> (EL(16*i+8*g+j)(REJ_MASK_ETA2 bs) <=> val(ETA2_NIBBLE d (8*g+j)) < 15))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `SUB_LIST(8*i,8) bs = MAP (\j. word_subword (d:int64) (8*j,8):byte) [0;1;2;3;4;5;6;7]` ASSUME_TAC THENL
   [MP_TAC(ISPECL [`buf:int64`;`len:num`;`bs:byte list`;`i:num`;`s:armstate`] SUB_LIST_8_BYTES_FROM_INT64) THEN
    ASM_REWRITE_TAC[MAP] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  CONJ_TAC THENL [ASM_REWRITE_TAC[ETA2_NIBBLES_CHUNK;ETA2_SAMPLE_APPEND;ETA2_GROUP_SPEC];ALL_TAC] THEN
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`bs:byte list`;`8*i`;`8`] REJ_MASK_ETA2_SUB_LIST) THEN
  DISCH_THEN(MP_TAC o AP_TERM `EL(8*g+j) : bool list->bool`) THEN
  SUBGOAL_THEN `8*g+j < 16 /\ 2*(8*i)+8*g+j < LENGTH(REJ_MASK_ETA2 bs)` STRIP_ASSUME_TAC THENL
   [ASM_REWRITE_TAC[ETA2_REJ_MASK_NIBBLES;LENGTH_MAP;LENGTH_BYTES_TO_NIBBLES] THEN ASM_ARITH_TAC;ALL_TAC] THEN
  ASM_SIMP_TAC[EL_SUB_LIST;ARITH_RULE `2*8=16`; ARITH_RULE `2*(8*i)+(8*g+j)=16*i+8*g+j`;ETA2_REJ_MASK_NIBBLES;ETA2_NIBBLES_CHUNK;MAP_APPEND] THEN
  SUBGOAL_THEN `LENGTH(MAP (\n:4 word. val n < 15) (ETA2_NIBBLE4 d 0)) = 8` ASSUME_TAC THENL
   [REWRITE_TAC[ETA2_NIBBLE4;LENGTH_MAP;LENGTH] THEN CONV_TAC NUM_REDUCE_CONV;ALL_TAC] THEN
  MP_TAC(ISPECL [`d:int64`;`g:num`;`j:num`] ETA2_INPUT_GROUP_MASK) THEN ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `g=0 \/ g=1` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC;ALL_TAC] THEN
  ASM_REWRITE_TAC[EL_APPEND;MULT_CLAUSES;ADD_CLAUSES;ARITH_RULE `~(8+j<8) /\ (8+j)-8=j`] THEN
  ASM_MESON_TAC[ETA2_REJ_MASK_NIBBLES]);;

let ETA2_INPUT_MASK_COUNTS = prove
 (`!d g p. (!j. j<8 ==> (p j <=> val(ETA2_NIBBLE d (8*g+j)) < 15)) ==>
    LENGTH(ETA2_GROUP d g) = ETA2_PACKET_COUNT p /\ LENGTH(ETA2_GROUP d g) <= 8 /\
    ETA2_PACKET_MASK (\j. val(ETA2_NIBBLE d(8*g+j)) < 15) = ETA2_PACKET_MASK p`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  MP_TAC(ISPECL [`d:int64`;`g:num`;`p:num->bool`] ETA2_GROUP_MASK) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN SUBST1_TAC THEN MP_TAC(SPEC `p:num->bool` ETA2_MASK_INDICES) THEN
  SIMP_TAC[LENGTH_MAP] THEN STRIP_TAC THEN ASM_REWRITE_TAC[ETA2_PACKET_MASK] THEN
  ASM_SIMP_TAC[ARITH_RULE `0<8 /\ 1<8 /\ 2<8 /\ 3<8 /\ 4<8 /\ 5<8 /\ 6<8 /\ 7<8`]);;

let ETA2_OUTPUT_WORDLIST = prove
 (`!xs:int32 list. !a s:armstate.
    (!i. i < LENGTH xs ==> read(memory :> bytes32(word_add a (word(4*i)))) s = EL i xs) ==>
    read(memory :> bytes(a,4*LENGTH xs)) s = num_of_wordlist xs`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  MP_TAC(ISPECL [`a:int64`;`LENGTH(xs:int32 list)`;`4*LENGTH(xs:int32 list)`;`xs:int32 list`;`s:armstate`]
    WORDLIST_FROM_MEMORY_EQ_ALT) THEN
  REWRITE_TAC[DIMINDEX_32;ARITH_RULE `32*n = 8*(4*n)`] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
  GEN_REWRITE_TAC I [LIST_EQ] THEN REWRITE_TAC[LENGTH_WORDLIST_FROM_MEMORY] THEN
  X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  ASM_SIMP_TAC[EL_WORDLIST_FROM_MEMORY; DIMINDEX_4; GSYM BYTES32_WBYTES]);;


let ETA2_VCONSTS = define
 `ETA2_VCONSTS s <=> read Q1 s = word 0x00040302010004030201000403020100 /\
   read Q7 s = word 0x00020002000200020002000200020002 /\ read Q29 s = word 0x0f0f0f0f0f0f0f0f /\
   read Q30 s = word 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f /\ read Q31 s = word 0x01800140012001100108010401020101`;;

let ETA2_OUTPUT_GROUPS = prove
 (`!xs ys:int32 list. !k dst s.
    (!j. j < MIN (LENGTH xs) k ==> read(memory:>bytes32(word_add dst (word(4*j)))) s = EL j xs) /\
    (!j. j < MIN (LENGTH ys) (k - LENGTH xs) ==>
       read(memory:>bytes32(word_add dst (word(4*(LENGTH xs+j))))) s = EL j ys) ==>
    read(memory:>bytes(dst,4*LENGTH(SUB_LIST(0,k)(APPEND xs ys))))s = num_of_wordlist(SUB_LIST(0,k)(APPEND xs ys))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN MATCH_MP_TAC ETA2_OUTPUT_WORDLIST THEN
  X_GEN_TAC `j:num` THEN REWRITE_TAC[LENGTH_SUB_LIST;LENGTH_APPEND;SUB_0] THEN DISCH_TAC THEN
  SUBGOAL_THEN `j<k /\ j < LENGTH(xs:int32 list)+LENGTH(ys:int32 list)` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
  ASM_SIMP_TAC[EL_SUB_LIST;ADD_CLAUSES;LENGTH_APPEND;EL_APPEND] THEN COND_CASES_TAC THENL
   [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
    SUBGOAL_THEN `LENGTH(xs:int32 list)+(j-LENGTH xs)=j /\ j-LENGTH xs < MIN(LENGTH(ys:int32 list))(k-LENGTH xs)` STRIP_ASSUME_TAC THENL
     [ASM_ARITH_TAC;FIRST_X_ASSUM(MP_TAC o SPEC `j-LENGTH(xs:int32 list)`) THEN ASM_REWRITE_TAC[]]]);;

let ETA2_SINGLE_BLOCK = prove
 (`!pc res buf table len bs i k e.
    LENGTH bs=len /\ 8*(i+1)<=len /\ 1<=k /\ k<=256 /\
    nonoverlapping (word pc,360) (word_add res (word(4*(256-k))),4*k) ==>
    ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\ read PC s = word(pc+0x60) /\
          read X0 s = word_add res (word(4*(256-k))) /\ read X4 s = word k /\
          read X1 s = word_add buf (word(8*i)) /\ read X3 s=table /\ ETA2_VCONSTS s /\
          read(memory:>bytes(buf,len))s = num_of_wordlist bs /\
          read(memory:>bytes(table,4096))s = num_of_wordlist mldsa_rej_uniform_eta_table /\ read events s=e)
     (\s. let p = \g j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs) in
          let a = ETA2_PACKET_COUNT(p 0) in let b = ETA2_PACKET_COUNT(p 1) in
          let chunk = REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES(SUB_LIST(8*i,8)bs)) in
          let dst = word_add res (word(4*(256-k))) in
          read PC s = word(pc+(if k<=a+b then 0x15c else 0xf0)) /\
          read X4 s = word(k-(a+b)) /\ (~(k<=a+b) ==> read X0 s = word_add dst (word(4*(a+b)))) /\
          read X1 s = word_add buf (word(8*(i+1))) /\ LENGTH chunk = a+b /\
          read(memory:>bytes(dst,4*LENGTH(SUB_LIST(0,k) chunk)))s = num_of_wordlist(SUB_LIST(0,k)chunk) /\
          read events s = ETA2_BLOCK_EVENTS res buf table pc i k (ETA2_PACKET_MASK(p 0))(ETA2_PACKET_MASK(p 1)) a b e)
     (MAYCHANGE [PC;X0;X1;X4;X6;X7;X12;X13;X14;X15] ,,
      MAYCHANGE [Q0;Q2;Q3;Q4;Q5;Q6;Q16;Q17;Q18;Q19;Q20;Q21;Q24;Q25] ,,
      MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,, MAYCHANGE [memory:>bytes(word_add res (word(4*(256-k))),4*k)])`,
  REWRITE_TAC[LET_DEF;LET_END_DEF;ETA2_VCONSTS;SOME_FLAGS] THEN REPEAT STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN
  ABBREV_TAC `p = \g j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs)` THEN
  ABBREV_TAC `dst = word_add res (word(4*(256-k))):int64` THEN
  REABBREV_TAC `d:int64 = read(memory:>bytes64(word_add buf (word(8*i)))) s0` THEN
  MP_TAC(ISPECL [`buf:int64`;`len:num`;`bs:byte list`;`i:num`;`s0:armstate`;`d:int64`] ETA2_INPUT_CHUNK) THEN
  ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
  (let groups g =
     let idx = mk_small_numeral g in
     MP_TAC(ISPECL [`d:int64`;idx;mk_comb(`p:num->num->bool`,idx)] ETA2_INPUT_MASK_COUNTS) THEN
     ANTS_TAC THENL [X_GEN_TAC `j:num` THEN DISCH_TAC THEN EXPAND_TAC "p" THEN FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; STRIP_TAC] in
   groups 0 THEN groups 1) THEN
  MP_TAC(ISPECL [`pc:num`;`word_add buf (word(8*i)):int64`;`table:int64`;`d:int64`;`e:(uarch_event)list`] ETA2_BATCH_REGISTERS) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s1" THEN
  MAP_EVERY REABBREV_TAC [`firstlo:int128 = read Q16 s1`;`firsthi:int128 = read Q17 s1`;
                           `secondlo:int128 = read Q18 s1`;`secondhi:int128 = read Q19 s1`] THEN
  REABBREV_TAC `reads:(uarch_event)list = read events s1` THEN
  MP_TAC(REWRITE_RULE[SOME_FLAGS](ISPECL [`pc:num`;`dst:int64`;`k:num`;`LENGTH(ETA2_GROUP d 0)`;`LENGTH(ETA2_GROUP d 1)`;
     `firstlo:int128`;`firsthi:int128`;`secondlo:int128`;`secondhi:int128`;`reads:(uarch_event)list`] ETA2_STORE_BATCH)) THEN
  ANTS_TAC THENL [ASM_MESON_TAC[];ALL_TAC] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s2" THEN
  SUBGOAL_THEN `!g. (\j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs)) = p g` ASSUME_TAC THENL
   [GEN_TAC THEN EXPAND_TAC "p" THEN REWRITE_TAC[];ALL_TAC] THEN
  SUBGOAL_THEN `(!j. j < MIN (LENGTH(ETA2_GROUP d 0)) k ==> read(memory:>bytes32(word_add dst (word(4*j)))) s2 = EL j (ETA2_GROUP d 0)) /\
               (!j. j < MIN (LENGTH(ETA2_GROUP d 1)) (k-LENGTH(ETA2_GROUP d 0)) ==> read(memory:>bytes32(word_add dst (word(4*(LENGTH(ETA2_GROUP d 0)+j))))) s2 = EL j (ETA2_GROUP d 1))` STRIP_ASSUME_TAC THENL
   [CONJ_TAC THENL
     [X_GEN_TAC `j:num` THEN DISCH_TAC THEN SUBGOAL_THEN `j < LENGTH(ETA2_GROUP d 0)` ASSUME_TAC THENL [ASM_ARITH_TAC;ASM_SIMP_TAC[]];
      X_GEN_TAC `j:num` THEN DISCH_TAC THEN SUBGOAL_THEN `j < LENGTH(ETA2_GROUP d 1)` ASSUME_TAC THENL [ASM_ARITH_TAC;ASM_SIMP_TAC[]]];
    ALL_TAC] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[MULT_CLAUSES;ADD_CLAUSES]) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[LENGTH_APPEND] THEN
  REPEAT CONJ_TAC THENL
   [ASM_MESON_TAC[];
    REWRITE_TAC[GSYM WORD_ADD_ASSOC;GSYM WORD_ADD;ARITH_RULE `8*(i+1)=8*i+8`];
    MATCH_MP_TAC ETA2_OUTPUT_GROUPS THEN CONJ_TAC THEN FIRST_ASSUM ACCEPT_TAC;
    REWRITE_TAC[ETA2_STORE_EVENTS;ETA2_BLOCK_EVENTS;LET_DEF;LET_END_DEF] THEN
    SUBGOAL_THEN `reads = APPEND [EventLoad(word_add table (word(16*ETA2_PACKET_MASK(p 1))),16);EventLoad(word_add table (word(16*ETA2_PACKET_MASK(p 0))),16);EventLoad(word_add buf (word(8*i)),8)] e` SUBST1_TAC THENL
     [FIRST_X_ASSUM(MP_TAC o SYM o check (fun th -> is_eq(concl th) && rand(concl th) = `reads:(uarch_event)list`)) THEN ASM_REWRITE_TAC[];ASM_REWRITE_TAC[]]]);;

(* Accepted coefficients from consecutive eight-byte blocks. *)
let ETA2_SUFFIX = new_definition
 `ETA2_SUFFIX bs i n = REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES(SUB_LIST(8*i,8*n) bs))`;;

let ETA2_SUFFIX_ZERO = prove
 (`!bs i. ETA2_SUFFIX bs i 0 = []`,
  REWRITE_TAC[ETA2_SUFFIX; MULT_CLAUSES; SUB_LIST_CLAUSES; BYTES_TO_NIBBLES; REJ_SAMPLE_ETA2; FILTER; MAP]);;

let ETA2_SUFFIX_ONE = prove
 (`!bs i. ETA2_SUFFIX bs i 1 = REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES(SUB_LIST(8*i,8) bs))`,
  REWRITE_TAC[ETA2_SUFFIX; MULT_CLAUSES]);;

let ETA2_SUFFIX_FULL = prove
 (`!bs n. LENGTH bs = 8*n ==> ETA2_SUFFIX bs 0 n = REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES bs)`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  ASM_REWRITE_TAC[ETA2_SUFFIX; MULT_CLAUSES] THEN
  AP_TERM_TAC THEN AP_TERM_TAC THEN MATCH_MP_TAC SUB_LIST_REFL THEN ASM_ARITH_TAC);;

let ETA2_SUFFIX_STEP = prove
 (`!bs i n. ETA2_SUFFIX bs i (SUC n) = APPEND (ETA2_SUFFIX bs i 1) (ETA2_SUFFIX bs (i+1) n)`,
  SUBGOAL_THEN `!xs ys. BYTES_TO_NIBBLES(APPEND xs ys) = APPEND(BYTES_TO_NIBBLES xs)(BYTES_TO_NIBBLES ys)` ASSUME_TAC THENL
   [LIST_INDUCT_TAC THEN ASM_REWRITE_TAC[APPEND; BYTES_TO_NIBBLES]; ALL_TAC] THEN
  REPEAT GEN_TAC THEN ASM_REWRITE_TAC[ETA2_SUFFIX; MULT_CLAUSES; ARITH_RULE `8 * SUC n = 8 + 8*n`;
    ARITH_RULE `8*(i+1) = 8*i+8`] THEN
  MP_TAC(ISPECL [`bs:byte list`;`8`;`8*n`;`8*i`] SUB_LIST_SPLIT) THEN
  DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[ETA2_SAMPLE_APPEND]);;

let ETA2_PREFIX_APPEND = prove
 (`!xs ys:A list. !k. SUB_LIST(0,k) (APPEND xs ys) =
    APPEND (SUB_LIST(0,k) xs) (SUB_LIST(0,k-LENGTH xs) ys)`,
  LIST_INDUCT_TAC THEN REWRITE_TAC[LENGTH;SUB_LIST_CLAUSES;APPEND;SUB_0] THEN
  GEN_TAC THEN INDUCT_TAC THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES;APPEND;ARITH_RULE `0-n=0`;ARITH_RULE `SUC k-SUC n=k-n`]);;

let ETA2_OUTPUT_APPEND = prove
 (`!dst s xs ys:int32 list.
    read(memory :> bytes(dst,4*LENGTH xs)) s = num_of_wordlist xs /\
    read(memory :> bytes(word_add dst (word(4*LENGTH xs)),4*LENGTH ys)) s = num_of_wordlist ys ==>
    read(memory :> bytes(dst,4*LENGTH(APPEND xs ys))) s = num_of_wordlist(APPEND xs ys)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[LENGTH_APPEND; LEFT_ADD_DISTRIB] THEN
  MP_TAC(ISPECL [`memory:(armstate,int64->byte)component`;`dst:int64`;`s:armstate`;
    `xs:int32 list`;`ys:int32 list`;`4*LENGTH(xs:int32 list)`;`4*LENGTH(ys:int32 list)`]
    BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[DIMINDEX_32; ARITH_RULE `32*n=8*(4*n)`] THEN MESON_TAC[]);;

let ETA2_LOOP_RESULT = prove
 (`!n res buf table pc ra (bs:byte list) len i k e.
    0<n /\ len=8*(i+n) /\ len<2 EXP 64 /\ LENGTH bs=len /\ 1<=k /\ k<=256 /\
    ALL(nonoverlapping(res,1024))[(word pc,360);(buf,len);(table,4096)] ==>
    ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\ read PC s=word(pc+0x60) /\
          read X0 s = word_add res (word(4*(256-k))) /\ read X4 s = word k /\
          read X1 s = word_add buf (word(8*i)) /\ read X2 s = word(8*n) /\ read X3 s=table /\ read X30 s=ra /\
          ETA2_VCONSTS s /\ read(memory:>bytes(buf,len))s = num_of_wordlist bs /\
          read(memory:>bytes(table,4096))s = num_of_wordlist mldsa_rej_uniform_eta_table /\ read events s=e)
     (\s. let xs = SUB_LIST(0,k)(ETA2_SUFFIX bs i n) in let dst=word_add res (word(4*(256-k))) in
          read PC s=ra /\ read X0 s = word(256-k+LENGTH xs) /\
          read(memory:>bytes(dst,4*LENGTH xs))s = num_of_wordlist xs /\
          read events s=ETA2_RUN_EVENTS res buf table pc ra (REJ_MASK_ETA2 bs) n i k e)
     (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,, MAYCHANGE[memory:>bytes(word_add res (word(4*(256-k))),4*k)])`,
  let abbreviate = (fun (asl,_ as g)-> let names=["a";"b";"chunk";"blocktrace";"dst"] in
   let abbs = filter (fun th -> let t=concl th in is_eq t && is_var(rand t) && mem(fst(dest_var(rand t))) names) (map snd asl) in
   let proj=ASSUME `!g. (\j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs)) = p g` in
   REWRITE_TAC(proj::abbs) g) in
  INDUCT_TAC THEN REPEAT GEN_TAC THEN REWRITE_TAC[LT_REFL] THEN
  REWRITE_TAC[ALL;LET_DEF;LET_END_DEF;ETA2_VCONSTS;MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN STRIP_TAC THEN
  ENSURES_INIT_TAC "s0" THEN
  ABBREV_TAC `p = \g j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs)` THEN ABBREV_TAC `a = ETA2_PACKET_COUNT(p 0)` THEN
  ABBREV_TAC `b = ETA2_PACKET_COUNT(p 1)` THEN
  ABBREV_TAC `dst = word_add res (word(4*(256-k))):int64` THEN
  ABBREV_TAC `chunk = ETA2_SUFFIX bs i 1` THEN
  ABBREV_TAC `rest = ETA2_SUFFIX bs (i+1) n` THEN
  ABBREV_TAC `blocktrace = ETA2_BLOCK_EVENTS res buf table pc i k (ETA2_PACKET_MASK(p 0))(ETA2_PACKET_MASK(p 1)) a b e` THEN
  SUBGOAL_THEN `nonoverlapping (word pc,360)(dst:int64,4*k) /\ nonoverlapping (buf,len)(dst,4*k) /\ nonoverlapping (table,4096)(dst,4*k)` STRIP_ASSUME_TAC THENL
   [EXPAND_TAC "dst" THEN REPEAT CONJ_TAC THEN NONOVERLAPPING_TAC; ALL_TAC] THEN
  MP_TAC(REWRITE_RULE[SOME_FLAGS;ETA2_VCONSTS;LET_DEF;LET_END_DEF;GSYM ETA2_SUFFIX_ONE]
    (ISPECL [`pc:num`;`res:int64`;`buf:int64`;`table:int64`;`len:num`;`bs:byte list`;`i:num`;`k:num`;`e:(uarch_event)list`] ETA2_SINGLE_BLOCK)) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;ALL_TAC] THEN
  SUBGOAL_THEN `!g. (\j. EL(16*i+8*g+j)(REJ_MASK_ETA2 bs)) = p g` ASSUME_TAC THENL
   [GEN_TAC THEN EXPAND_TAC "p" THEN REWRITE_TAC[];ALL_TAC] THEN
  abbreviate THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s1" THEN
  SUBGOAL_THEN `ETA2_SUFFIX bs i (SUC n) = APPEND (chunk:int32 list) rest` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[ETA2_SUFFIX_STEP]; ALL_TAC] THEN
  SUBGOAL_THEN `ETA2_RUN_EVENTS res buf table pc ra (REJ_MASK_ETA2 bs) (SUC n) i k e =
    if k<=a+b then CONS(EventJump(word(pc+0x164),ra)) blocktrace else if n=0 then
     APPEND [EventJump(word(pc+0x164),ra);EventJump(word(pc+0xf8),word(pc+0x15c));EventJump(word(pc+0xf4),word(pc+0xf8))] blocktrace
    else ETA2_RUN_EVENTS res buf table pc ra (REJ_MASK_ETA2 bs) n (i+1) (k-(a+b))
     (CONS(EventJump(word(pc+0xf4),word(pc+0x60))) blocktrace)` ASSUME_TAC THENL
   [GEN_REWRITE_TAC LAND_CONV [ETA2_RUN_EVENTS] THEN REWRITE_TAC[LET_DEF;LET_END_DEF] THEN abbreviate;ALL_TAC] THEN
  (* A full result returns immediately, even if more input is available. *)
  ASM_CASES_TAC `k<=a+b` THENL
   [RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `k<=a+b`]) THEN ASSUME_TAC(ASSUME `k<=a+b`) THEN
    MP_TAC(ISPECL [`pc:num`;`k-(a+b)`;`ra:int64`;`blocktrace:(uarch_event)list`] ETA2_RETURN) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s2" THEN
    SUBGOAL_THEN `SUB_LIST(0,k)(APPEND (chunk:int32 list) rest)=SUB_LIST(0,k)chunk /\ LENGTH(SUB_LIST(0,k)chunk)=k /\ 256-(k-(a+b)) = 256-k+k` STRIP_ASSUME_TAC THENL
     [CONJ_TAC THENL [MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_ARITH_TAC; REWRITE_TAC[LENGTH_SUB_LIST;SUB_0] THEN ASM_ARITH_TAC];ALL_TAC] THEN
    SUBGOAL_THEN `read(memory:>bytes(dst,4*k))s2 = num_of_wordlist(SUB_LIST(0,k)(chunk:int32 list))` ASSUME_TAC THENL
     [ASM_MESON_TAC[];ALL_TAC] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN TRY MONOTONE_MAYCHANGE_TAC;
    ALL_TAC] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `~(k<=a+b)`]) THEN ASSUME_TAC(ASSUME `~(k<=a+b)`) THEN
  SUBGOAL_THEN `8<=8*SUC n /\ 8*SUC n < 2 EXP 64 /\ (8*SUC n=8 <=> n=0) /\ 8*SUC n-8=8*n` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
  MP_TAC(REWRITE_RULE[SOME_FLAGS](ISPECL [`pc:num`;`8*SUC n`;`blocktrace:(uarch_event)list`] ETA2_NEXT_BUFFER)) THEN
  REWRITE_TAC[ASSUME `8<=8*SUC n`;ASSUME `8*SUC n < 2 EXP 64`;ASSUME `8*SUC n=8 <=> n=0`;ASSUME `8*SUC n-8=8*n`] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s2" THEN
  ASM_CASES_TAC `n=0` THENL
   [RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `n=0`]) THEN ASSUME_TAC(ASSUME `n=0`) THEN
    MP_TAC(ISPECL [`pc:num`;`k-(a+b)`;`ra:int64`;
     `APPEND [EventJump(word(pc+0xf8),word(pc+0x15c));EventJump(word(pc+0xf4),word(pc+0xf8))] blocktrace`] ETA2_RETURN) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s3" THEN
    SUBGOAL_THEN `rest:int32 list=[]` ASSUME_TAC THENL [ASM_MESON_TAC[ETA2_SUFFIX_ZERO];ALL_TAC] THEN
    SUBGOAL_THEN `256-(k-(a+b))=256-k+LENGTH(SUB_LIST(0,k)(chunk:int32 list))` ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_SUB_LIST;SUB_0] THEN ASM_ARITH_TAC;ALL_TAC] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[APPEND_NIL;APPEND] THEN TRY MONOTONE_MAYCHANGE_TAC;
    ALL_TAC] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `~(n=0)`]) THEN ASSUME_TAC(ASSUME `~(n=0)`) THEN
  (* The recursive call may write only after this block's output. *)
  SUBGOAL_THEN `SUB_LIST(0,k)(chunk:int32 list)=chunk` ASSUME_TAC THENL
   [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `read(memory:>bytes(dst,4*(a+b)))s2 = num_of_wordlist(chunk:int32 list)` ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o check (fun t-> is_eq(concl t) && can (find_term (fun x->x = `SUB_LIST(0,k)(chunk:int32 list)`)) (rand(concl t)))) THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  ABBREV_TAC `nextdst=word_add dst (word(4*(a+b))):int64` THEN
  SUBGOAL_THEN `word_add res (word(4*(256-(k-(a+b)))))=nextdst:int64` ASSUME_TAC THENL
   [SUBGOAL_THEN `4*(256-(k-(a+b)))=4*(256-k)+4*(a+b)` SUBST1_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[WORD_ADD;WORD_ADD_ASSOC] THEN ASM_REWRITE_TAC[]];ALL_TAC] THEN
  SUBGOAL_THEN `nonoverlapping (dst:int64,4*(a+b))(nextdst:int64,4*(k-(a+b)))` ASSUME_TAC THENL
   [SUBGOAL_THEN `4*(a+b)+4*(k-(a+b)) <= 2 EXP 64` MP_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
    REWRITE_TAC[GSYM (ASSUME `word_add dst (word(4*(a+b)))=nextdst:int64`)] THEN
    SPEC_TAC(`4*(k-(a+b))`,`y:num`) THEN SPEC_TAC(`4*(a+b)`,`x:num`) THEN
    REPEAT GEN_TAC THEN DISCH_TAC THEN NONOVERLAPPING_TAC;ALL_TAC] THEN
  SUBGOAL_THEN `nonoverlapping (word pc:int64,360)(nextdst,4*(k-(a+b)))` ASSUME_TAC THENL
   [REWRITE_TAC[GSYM (ASSUME `word_add dst (word(4*(a+b)))=nextdst:int64`)] THEN NONOVERLAPPING_TAC;ALL_TAC] THEN
  FIRST_X_ASSUM(MP_TAC o SPECL [`res:int64`;`buf:int64`;`table:int64`;`pc:num`;`ra:int64`;`bs:byte list`;`len:num`;`i+1`;`k-(a+b)`;`CONS(EventJump(word(pc+0xf4),word(pc+0x60))) blocktrace`]) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[ALL] THEN ASM_ARITH_TAC;ALL_TAC] THEN
  REWRITE_TAC[ETA2_VCONSTS;LET_DEF;LET_END_DEF;MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
    ASSUME `ETA2_SUFFIX bs (i+1) n = rest:int32 list`; ASSUME `word_add res (word(4*(256-(k-(a+b)))))=nextdst:int64`] THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s3" THEN
  SUBGOAL_THEN `read(memory:>bytes(dst,4*LENGTH(APPEND (chunk:int32 list) (SUB_LIST(0,k-(a+b)) rest))))s3 = num_of_wordlist(APPEND chunk (SUB_LIST(0,k-(a+b)) rest))` ASSUME_TAC THENL
   [MATCH_MP_TAC ETA2_OUTPUT_APPEND THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  SUBGOAL_THEN `SUB_LIST(0,k)(ETA2_SUFFIX bs i (SUC n)) = APPEND(chunk:int32 list)(SUB_LIST(0,k-(a+b))rest)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[ETA2_PREFIX_APPEND]; ALL_TAC] THEN
  SUBGOAL_THEN `256-(k-(a+b))=256-k+(a+b)` ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[ETA2_PREFIX_APPEND;LENGTH_APPEND;ADD_ASSOC] THEN CONJ_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o check (fun th -> is_eq(concl th) && can (find_term (fun t -> is_const t && name_of t="APPEND")) (rand(concl th)) && can (find_term (fun t -> t=`s3:armstate`)) (lhand(concl th)))) THEN ASM_REWRITE_TAC[LENGTH_APPEND];
    RULE_ASSUM_TAC (REWRITE_RULE[GSYM(ASSUME `word_add dst (word(4*(a+b)))=nextdst:int64`)]) THEN MONOTONE_MAYCHANGE_TAC]);;

let ETA2_CORE_RESULT = prove
 (`!res buf buflen table (bs:byte list) pc ra e.
   8 divides val buflen /\ 8 <= val buflen /\ LENGTH bs = val buflen /\
   ALL (nonoverlapping (res,1024)) [(word pc,LENGTH mldsa_rej_uniform_eta2_mc);
                                      (buf,val buflen); (table,4096)] ==>
   ensures arm
     (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
          read PC s = word pc /\ read X30 s = ra /\ C_ARGUMENTS [res;buf;buflen;table] s /\
          read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
          read(memory :> bytes(buf,val buflen)) s = num_of_wordlist bs /\ read events s = e)
     (\s. read PC s = ra /\
          C_RETURN s = word(LENGTH(SUB_LIST(0,256)(REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES bs)))) /\
          read(memory :> bytes(res,4*LENGTH(SUB_LIST(0,256)(REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES bs))))) s =
             num_of_wordlist(SUB_LIST(0,256)(REJ_SAMPLE_ETA2(BYTES_TO_NIBBLES bs))) /\
          read events s = ETA2_RUN_EVENTS res buf table pc ra (REJ_MASK_ETA2 bs) (val buflen DIV 8) 0 256 e)
     (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,, MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[LENGTH_MLDSA_REJ_UNIFORM_ETA2_MC; ALL; C_ARGUMENTS; C_RETURN] THEN
  STRIP_TAC THEN ABBREV_TAC `n = val(buflen:int64) DIV 8` THEN
  SUBGOAL_THEN `8*n = val(buflen:int64)` ASSUME_TAC THENL
   [EXPAND_TAC "n" THEN ONCE_REWRITE_TAC[MULT_SYM] THEN ASM_REWRITE_TAC[GSYM DIVIDES_DIV_MULT]; ALL_TAC] THEN
  SUBGOAL_THEN `0<n /\ LENGTH(bs:byte list)=8*n /\ val(buflen:int64)<2 EXP 64`
    STRIP_ASSUME_TAC THENL [REWRITE_TAC[VAL_BOUND_64] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN MP_TAC(SPEC `pc:num` ETA2_SETUP) THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s1" THEN
  MP_TAC(SPECL [`n:num`;`res:int64`;`buf:int64`;`table:int64`;`pc:num`;`ra:int64`;
    `bs:byte list`;`val(buflen:int64)`;`0`;`256`;`e:uarch_event list`] ETA2_LOOP_RESULT) THEN
  REWRITE_TAC[ALL;ETA2_VCONSTS;LET_DEF;LET_END_DEF;ADD_CLAUSES] THEN
  REWRITE_TAC[SUB_REFL;MULT_CLAUSES;ARITH_RULE `4*256=1024 /\ 1<=256 /\ 256<=256`] THEN
  ASM_SIMP_TAC[ADD_CLAUSES;WORD_ADD_0;WORD_VAL;ETA2_SUFFIX_FULL;MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN
  ARM_BIGSTEP_TAC MLDSA_REJ_UNIFORM_ETA2_EXEC "s2" THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN
  MONOTONE_MAYCHANGE_TAC);;

(* Appending an incoming event history commutes with each sampler block. *)
let ETA2_BLOCK_EVENTS_APPEND = prove
 (`!res buf table pc i k ma mb a b e tail.
    ETA2_BLOCK_EVENTS res buf table pc i k ma mb a b (APPEND e tail) =
    APPEND (ETA2_BLOCK_EVENTS res buf table pc i k ma mb a b e) tail`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ETA2_BLOCK_EVENTS;ETA2_TAIL_EVENTS;
    ETA2_AFTER_GROUP_EVENTS;ETA2_GROUP_EVENTS;ETA2_SHORT_EVENTS;
    LET_DEF;LET_END_DEF;APPEND] THEN
  REPEAT (COND_CASES_TAC THEN ASM_REWRITE_TAC[APPEND]));;

let ETA2_RUN_EVENTS_APPEND = prove
 (`!blocks i k e tail res buf table pc ra mask.
    ETA2_RUN_EVENTS res buf table pc ra mask blocks i k (APPEND e tail) =
    APPEND (ETA2_RUN_EVENTS res buf table pc ra mask blocks i k e) tail`,
  INDUCT_TAC THEN REPEAT GEN_TAC THEN ASM_REWRITE_TAC[ETA2_RUN_EVENTS] THEN
  REWRITE_TAC[LET_DEF;LET_END_DEF;ETA2_BLOCK_EVENTS_APPEND] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[APPEND]) THEN
  ONCE_REWRITE_TAC[GSYM(CONJUNCT2 APPEND)] THEN ASM_REWRITE_TAC[]);;

let ETA2_PREFIX_BOUND = prove
 (`!xs i. let outlist = SUB_LIST(0,256)(REJ_SAMPLE_ETA2 xs) in
    i < LENGTH outlist ==> ival(EL i outlist:int32) < &3 /\ -- &3 < ival(EL i outlist:int32)`,
  REPEAT GEN_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN DISCH_TAC THEN
  MP_TAC(ISPECL [`REJ_SAMPLE_ETA2 xs`;`0`;`256`;`i:num`] EL_SUB_LIST) THEN
  REWRITE_TAC[ADD_CLAUSES] THEN ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_THEN SUBST1_TAC] THEN
  SUBGOAL_THEN `i < LENGTH(FILTER (\x:4 word. val x < 15) xs)` ASSUME_TAC THENL
   [RULE_ASSUM_TAC(REWRITE_RULE[REJ_SAMPLE_ETA2;LENGTH_MAP]) THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[REJ_SAMPLE_ETA2;EL_MAP] THEN
  SPEC_TAC (`EL i (FILTER (\x:4 word. val x < 15) xs)`,`x:4 word`) THEN
  GEN_REWRITE_TAC I [BETA_RULE(ISPEC `\n:num (x:4 word). (P:4 word->bool) x` FORALL_VAL_GEN)] THEN REWRITE_TAC[DIMINDEX_4] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV));;
(* Instantiate the byte-list theorem with the initial event history. *)
let eta2_project_core history =
  REWRITE_TAC[ensures] THEN X_GEN_TAC `s0:armstate` THEN STRIP_TAC THEN
  MP_TAC(SPECL [`res:int64`; `buf:int64`; `buflen:int64`; `table:int64`;
    `bs:byte list`; `pc:num`; `returnaddress:int64`; history] ETA2_CORE_RESULT) THEN
  ASM_REWRITE_TAC[ensures] THEN DISCH_THEN(MP_TAC o SPEC `s0:armstate`) THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[RIGHT_IMP_FORALL_THM] EVENTUALLY_MONO) THEN
  X_GEN_TAC `s:armstate` THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_CORRECT = prove
 (`!res buf buflen table (inlist:(4 word)list) pc returnaddress.
    8 divides val buflen /\ 8 <= val buflen /\ LENGTH inlist = 2 * val buflen /\
    ALL (nonoverlapping (res,1024))
        [(word pc,LENGTH mldsa_rej_uniform_eta2_mc); (buf,val buflen); (table,4096)] ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word pc /\ read X30 s = returnaddress /\
           C_ARGUMENTS [res;buf;buflen;table] s /\
           read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
           read(memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist)
      (\s. read PC s = returnaddress /\
           let outlist = SUB_LIST(0,256)(REJ_SAMPLE_ETA2 inlist) in
           let outlen = LENGTH outlist in
           outlen <= 256 /\ C_RETURN s = word outlen /\
           read(memory :> bytes(res,4*outlen)) s = num_of_wordlist outlist /\
           (!i. i < outlen ==> ival(EL i outlist:int32) < &3 /\ -- &3 < ival(EL i outlist:int32)))
      (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,, MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(ISPEC `inlist:(4 word)list` BYTES_TO_NIBBLES_SURJ) THEN ANTS_TAC THENL
   [REWRITE_TAC[EVEN_EXISTS] THEN EXISTS_TAC `val(buflen:int64)` THEN ASM_REWRITE_TAC[];
    DISCH_THEN(X_CHOOSE_THEN `bs:byte list` STRIP_ASSUME_TAC)] THEN
  UNDISCH_THEN `BYTES_TO_NIBBLES bs = inlist` (SUBST_ALL_TAC o SYM) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[LENGTH_BYTES_TO_NIBBLES; ARITH_RULE `2*a=2*b <=> a=b`]) THEN
  REWRITE_TAC[NUM_OF_BYTES_TO_NIBBLES; LET_DEF; LET_END_DEF] THEN
  eta2_project_core `read events s0` THEN CONJ_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST] THEN ARITH_TAC;
    REWRITE_TAC[REWRITE_RULE[LET_DEF;LET_END_DEF] ETA2_PREFIX_BOUND]]);;

(* The trace prefix starts with an empty history, so its address bounds
   depend only on the arguments and the acceptance mask. *)
let ETA2_TRACE_RESULT = prove
 (`!res buf buflen table (bs:byte list) pc returnaddress e.
    8 divides val buflen /\ 8 <= val buflen /\ LENGTH bs = val buflen /\
    ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_eta2_mc); (buf,val buflen); (table,4096)] ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word pc /\ read X30 s = returnaddress /\
           C_ARGUMENTS [res;buf;buflen;table] s /\
           read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
           read(memory :> bytes(buf,val buflen)) s = num_of_wordlist bs /\ read events s = e)
      (\s. read PC s = returnaddress /\
           let trace = ETA2_RUN_EVENTS res buf table pc returnaddress
                         (REJ_MASK_ETA2 bs) (val buflen DIV 8) 0 256 [] in
           read events s = APPEND trace e /\ memaccess_inbounds trace [buf,val buflen;table,4096] [res,1024])
      (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,, MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[LET_DEF;LET_END_DEF] THEN
  eta2_project_core `e:uarch_event list` THEN CONJ_TAC THENL
   [MATCH_ACCEPT_TAC(REWRITE_RULE[APPEND] (SPEC `[]:uarch_event list`
      (SPECL [`val(buflen:int64) DIV 8`; `0`; `256`] ETA2_RUN_EVENTS_APPEND)));
    MATCH_MP_TAC ETA2_RUN_INBOUNDS THEN REWRITE_TAC[ADD_CLAUSES; LE_REFL; memaccess_inbounds; ALL] THEN
    REWRITE_TAC[DIV_MUL_LE]]);;

let eta2_project_trace =
  MP_TAC(SPECL [`res:int64`; `buf:int64`; `buflen:int64`; `table:int64`;
    `inlist:byte list`; `pc:num`; `returnaddress:int64`; `e:uarch_event list`]
    ETA2_TRACE_RESULT) THEN
  ASM_REWRITE_TAC[ensures;LET_DEF;LET_END_DEF] THEN
  MATCH_MP_TAC MONO_FORALL THEN X_GEN_TAC `s0:armstate` THEN
  MATCH_MP_TAC MONO_IMP THEN REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[RIGHT_IMP_FORALL_THM] EVENTUALLY_MONO) THEN
  X_GEN_TAC `s:armstate` THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN ASM_MESON_TAC[];;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_MEMSAFE = prove
 (`!res buf buflen table (inlist:byte list) pc e returnaddress.
    8 divides val buflen /\ 8 <= val buflen /\ LENGTH inlist = val buflen /\
    ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_eta2_mc); (buf,val buflen); (table,4096)] ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word pc /\ read X30 s = returnaddress /\
           C_ARGUMENTS [res;buf;buflen;table] s /\
           read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
           read(memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist /\ read events s = e)
      (\s. read PC s = returnaddress /\
           ?e2. read events s = APPEND e2 e /\
                memaccess_inbounds e2 [buf,val buflen;table,4096] [res,1024])
      (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,, MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN eta2_project_trace);;

let MLDSA_REJ_UNIFORM_ETA2_SUBROUTINE_SAFE = prove
 (`?f_events:int64->int64->int64->int64->num->int64->bool list->uarch_event list.
   !res buf buflen table (inlist:byte list) pc e returnaddress.
    8 divides val buflen /\ 8 <= val buflen /\ LENGTH inlist = val buflen /\
    ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_eta2_mc); (buf,val buflen); (table,4096)] ==>
    ensures arm
      (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta2_mc /\
           read PC s = word pc /\ read X30 s = returnaddress /\
           C_ARGUMENTS [res;buf;buflen;table] s /\
           read(memory :> bytes(table,4096)) s = num_of_wordlist mldsa_rej_uniform_eta_table /\
           read(memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist /\ read events s = e)
      (\s. read PC s = returnaddress /\
           ?e2. read events s = APPEND e2 e /\
                e2 = f_events res buf buflen table pc returnaddress (REJ_MASK_ETA2 inlist) /\
                memaccess_inbounds e2 [buf,val buflen;table,4096] [res,1024])
      (\s s'. T)`,
  EXISTS_TAC `\res buf (buflen:int64) table pc returnaddress mask.
    ETA2_RUN_EVENTS res buf table pc returnaddress mask (val buflen DIV 8) 0 256 []` THEN
  REPEAT GEN_TAC THEN STRIP_TAC THEN BETA_TAC THEN eta2_project_trace);;
