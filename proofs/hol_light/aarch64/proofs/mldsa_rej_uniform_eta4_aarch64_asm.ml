(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Rejection sampling with eta=4 for ML-DSA AArch64.                         *)
(*                                                                           *)
(* Filters 4-bit nibbles < 9, maps accepted values n to (4 - n) as int32.    *)
(* Uses a 256-entry TBL lookup indexed by 8-bit masks (16 bytes each).       *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_rej_uniform_eta_table.ml";;

(**** print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_eta4_aarch64_asm.o";;
 ****)

let mldsa_rej_uniform_eta4_mc = define_assert_from_elf
  "mldsa_rej_uniform_eta4_mc" "aarch64/mldsa/mldsa_rej_uniform_eta4_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0xd10903ff;       (* arm_SUB SP SP (rvalue (word 576)) *)
  0xd2800027;       (* arm_MOV X7 (rvalue (word 1)) *)
  0xf2a00047;       (* arm_MOVK X7 (word 2) 16 *)
  0xf2c00087;       (* arm_MOVK X7 (word 4) 32 *)
  0xf2e00107;       (* arm_MOVK X7 (word 8) 48 *)
  0x4e081cff;       (* arm_INS_GEN Q31 X7 0 64 *)
  0xd2800207;       (* arm_MOV X7 (rvalue (word 16)) *)
  0xf2a00407;       (* arm_MOVK X7 (word 32) 16 *)
  0xf2c00807;       (* arm_MOVK X7 (word 64) 32 *)
  0xf2e01007;       (* arm_MOVK X7 (word 128) 48 *)
  0x4e181cff;       (* arm_INS_GEN Q31 X7 64 64 *)
  0x4f00853e;       (* arm_MOVI Q30 (word 2533313445691401) *)
  0x4f008487;       (* arm_MOVI Q7 (word 1125917086973956) *)
  0x910003e8;       (* arm_ADD X8 SP (rvalue (word 0)) *)
  0xaa0803e7;       (* arm_MOV X7 X8 *)
  0xd280000b;       (* arm_MOV X11 (rvalue (word 0)) *)
  0x6e301e10;       (* arm_EOR_VEC Q16 Q16 Q16 128 *)
  0x3c8404f0;       (* arm_STR Q16 X7 (Postimmediate_Offset (word 64)) *)
  0x3c9d00f0;       (* arm_STR Q16 X7 (Immediate_Offset (word 18446744073709551568)) *)
  0x3c9e00f0;       (* arm_STR Q16 X7 (Immediate_Offset (word 18446744073709551584)) *)
  0x3c9f00f0;       (* arm_STR Q16 X7 (Immediate_Offset (word 18446744073709551600)) *)
  0x9100816b;       (* arm_ADD X11 X11 (rvalue (word 32)) *)
  0xf104017f;       (* arm_CMP X11 (rvalue (word 256)) *)
  0x54ffff4b;       (* arm_BLT (word 2097128) *)
  0xaa0803e7;       (* arm_MOV X7 X8 *)
  0xd2800009;       (* arm_MOV X9 (rvalue (word 0)) *)
  0xd2802004;       (* arm_MOV X4 (rvalue (word 256)) *)
  0xeb04013f;       (* arm_CMP X9 X4 *)
  0x54000482;       (* arm_BCS (word 144) *)
  0xd1002042;       (* arm_SUB X2 X2 (rvalue (word 8)) *)
  0x0cdf7020;       (* arm_LDR D0 X1 (Postimmediate_Offset (word 8)) *)
  0x0f00e5fa;       (* arm_MOVI D26 (word 1085102592571150095) *)
  0x0e3a1c1b;       (* arm_AND_VEC Q27 Q0 Q26 64 *)
  0x2f0c041c;       (* arm_USHR_VEC Q28 Q0 4 8 64 *)
  0x0e1c3b7a;       (* arm_ZIP1 Q26 Q27 Q28 8 64 *)
  0x0e1c7b7d;       (* arm_ZIP2 Q29 Q27 Q28 8 64 *)
  0x2f08a750;       (* arm_USHLL_VEC Q16 Q26 0 8 *)
  0x2f08a7b1;       (* arm_USHLL_VEC Q17 Q29 0 8 *)
  0x6e7037c4;       (* arm_CMHI_VEC Q4 Q30 Q16 16 128 *)
  0x6e7137c5;       (* arm_CMHI_VEC Q5 Q30 Q17 16 128 *)
  0x4e3f1c84;       (* arm_AND_VEC Q4 Q4 Q31 128 *)
  0x4e3f1ca5;       (* arm_AND_VEC Q5 Q5 Q31 128 *)
  0x6e703894;       (* arm_UADDLV Q20 Q4 8 16 *)
  0x6e7038b5;       (* arm_UADDLV Q21 Q5 8 16 *)
  0x1e26028c;       (* arm_FMOV_FtoI W12 Q20 0 32 *)
  0x1e2602ad;       (* arm_FMOV_FtoI W13 Q21 0 32 *)
  0x3cec7878;       (* arm_LDR Q24 X3 (Shiftreg_Offset X12 4) *)
  0x3ced7879;       (* arm_LDR Q25 X3 (Shiftreg_Offset X13 4) *)
  0x4e205884;       (* arm_CNT Q4 Q4 128 *)
  0x4e2058a5;       (* arm_CNT Q5 Q5 128 *)
  0x6e703894;       (* arm_UADDLV Q20 Q4 8 16 *)
  0x6e7038b5;       (* arm_UADDLV Q21 Q5 8 16 *)
  0x1e26028c;       (* arm_FMOV_FtoI W12 Q20 0 32 *)
  0x1e2602ad;       (* arm_FMOV_FtoI W13 Q21 0 32 *)
  0x4e180210;       (* arm_TBL Q16 [Q16] Q24 128 *)
  0x4e190231;       (* arm_TBL Q17 [Q17] Q25 128 *)
  0x4c0074f0;       (* arm_STR Q16 X7 No_Offset *)
  0x8b0c04e7;       (* arm_ADD X7 X7 (Shiftedreg X12 LSL 1) *)
  0x4c0074f1;       (* arm_STR Q17 X7 No_Offset *)
  0x8b0d04e7;       (* arm_ADD X7 X7 (Shiftedreg X13 LSL 1) *)
  0x8b0d018c;       (* arm_ADD X12 X12 X13 *)
  0x8b0c0129;       (* arm_ADD X9 X9 X12 *)
  0xf100205f;       (* arm_CMP X2 (rvalue (word 8)) *)
  0x54fffb82;       (* arm_BCS (word 2097008) *)
  0xeb04013f;       (* arm_CMP X9 X4 *)
  0x9a843129;       (* arm_CSEL X9 X9 X4 Condition_CC *)
  0xd280000b;       (* arm_MOV X11 (rvalue (word 0)) *)
  0xaa0803e7;       (* arm_MOV X7 X8 *)
  0x3cc204f0;       (* arm_LDR Q16 X7 (Postimmediate_Offset (word 32)) *)
  0x3cdf00f2;       (* arm_LDR Q18 X7 (Immediate_Offset (word 18446744073709551600)) *)
  0x6e7084f0;       (* arm_SUB_VEC Q16 Q7 Q16 16 128 *)
  0x6e7284f2;       (* arm_SUB_VEC Q18 Q7 Q18 16 128 *)
  0x4f10a611;       (* arm_SSHLL2_VEC Q17 Q16 0 16 *)
  0x0f10a610;       (* arm_SSHLL_VEC Q16 Q16 0 16 *)
  0x4f10a653;       (* arm_SSHLL2_VEC Q19 Q18 0 16 *)
  0x0f10a652;       (* arm_SSHLL_VEC Q18 Q18 0 16 *)
  0x3c840410;       (* arm_STR Q16 X0 (Postimmediate_Offset (word 64)) *)
  0x3c9d0011;       (* arm_STR Q17 X0 (Immediate_Offset (word 18446744073709551568)) *)
  0x3c9e0012;       (* arm_STR Q18 X0 (Immediate_Offset (word 18446744073709551584)) *)
  0x3c9f0013;       (* arm_STR Q19 X0 (Immediate_Offset (word 18446744073709551600)) *)
  0x9100416b;       (* arm_ADD X11 X11 (rvalue (word 16)) *)
  0xf104017f;       (* arm_CMP X11 (rvalue (word 256)) *)
  0x54fffe4b;       (* arm_BLT (word 2097096) *)
  0xaa0903e0;       (* arm_MOV X0 X9 *)
  0x910903ff;       (* arm_ADD SP SP (rvalue (word 576)) *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let MLDSA_REJ_UNIFORM_ETA4_EXEC = ARM_MK_EXEC_RULE mldsa_rej_uniform_eta4_mc;;

let LENGTH_MLDSA_REJ_UNIFORM_ETA4_MC =
  REWRITE_CONV[mldsa_rej_uniform_eta4_mc] `LENGTH mldsa_rej_uniform_eta4_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

(* Named preamble/postamble lengths and core-loop pc range. The preamble is *)
(* one MOV setting up the eta-table sentinel constant in W4; the postamble  *)
(* is MOV X0,X9 + ADD SP,SP,#576 + RET. *)
let MLDSA_REJ_UNIFORM_ETA4_PREAMBLE_LENGTH = new_definition
  `MLDSA_REJ_UNIFORM_ETA4_PREAMBLE_LENGTH = 4`;;

let MLDSA_REJ_UNIFORM_ETA4_POSTAMBLE_LENGTH = new_definition
  `MLDSA_REJ_UNIFORM_ETA4_POSTAMBLE_LENGTH = 8`;;

let MLDSA_REJ_UNIFORM_ETA4_CORE_START = new_definition
  `MLDSA_REJ_UNIFORM_ETA4_CORE_START = MLDSA_REJ_UNIFORM_ETA4_PREAMBLE_LENGTH`;;

let MLDSA_REJ_UNIFORM_ETA4_CORE_END = new_definition
  `MLDSA_REJ_UNIFORM_ETA4_CORE_END =
   LENGTH mldsa_rej_uniform_eta4_mc - MLDSA_REJ_UNIFORM_ETA4_POSTAMBLE_LENGTH`;;

let LENGTH_SIMPLIFY_CONV =
  REWRITE_CONV[LENGTH_MLDSA_REJ_UNIFORM_ETA4_MC;
               MLDSA_REJ_UNIFORM_ETA4_CORE_START;
               MLDSA_REJ_UNIFORM_ETA4_CORE_END;
               MLDSA_REJ_UNIFORM_ETA4_PREAMBLE_LENGTH;
               MLDSA_REJ_UNIFORM_ETA4_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV [ADD_0];;

(* ------------------------------------------------------------------------- *)
(* Supporting lemmas.                                                        *)
(*                                                                           *)
(* The public spec REJ_SAMPLE_ETA4 (in common/mldsa_specs.ml) takes a       *)
(* nibble list. The proof below is naturally written against the byte-list  *)
(* shape, since the loop invariant peels off 8 bytes / 16 nibbles per       *)
(* iteration, so we introduce private byte-shape aliases below and bridge   *)
(* to the public spec at the subroutine spec.                               *)
(* ------------------------------------------------------------------------- *)

let REJ_NIBBLES_ETA4 = define
  `REJ_NIBBLES_ETA4 (l:byte list) =
   FILTER (\x:int16. val x < 9) (NIBBLES_OF_BYTES l)`;;

let REJ_SAMPLE_ETA4_BYTES = define
  `REJ_SAMPLE_ETA4_BYTES (l:byte list) =
   MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32)
       (REJ_NIBBLES_ETA4 l)`;;

(* Bridge: byte-shape composition equals the public nibble-list spec        *)
(* applied to BYTES_TO_NIBBLES. Used only at the subroutine-spec boundary.  *)
let REJ_SAMPLE_ETA4_BYTES_EQ = prove
 (`!l:byte list. REJ_SAMPLE_ETA4_BYTES l =
                 REJ_SAMPLE_ETA4 (BYTES_TO_NIBBLES l)`,
  GEN_TAC THEN
  REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4; REJ_SAMPLE_ETA4;
              NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES] THEN
  REWRITE_TAC[FILTER_MAP; o_DEF; GSYM MAP_o] THEN
  (* Reduce val(word_zx x:int16) to val x in the FILTER predicate. *)
  SUBGOAL_THEN `!x:4 word. val (word_zx x:int16) = val x`
    (fun th -> REWRITE_TAC[th]) THENL
   [GEN_TAC THEN MATCH_MP_TAC VAL_WORD_ZX THEN
    REWRITE_TAC[DIMINDEX_4; DIMINDEX_16] THEN ARITH_TAC;
    ALL_TAC] THEN
  (* Per-element equivalence between the int16-stored and native (4 word)   *)
  (* forms, gated by the val<9 filter predicate.                             *)
  SPEC_TAC(`BYTES_TO_NIBBLES (l:byte list)`,`xs:(4 word) list`) THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; MAP] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN
  POP_ASSUM MP_TAC THEN POP_ASSUM(K ALL_TAC) THEN
  BITBLAST_TAC);;

let REJ_NIBBLES_ETA4_EMPTY = prove
 (`REJ_NIBBLES_ETA4 [] = []`,
  REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; FILTER]);;

let REJ_NIBBLES_ETA4_APPEND = prove
 (`!l1 l2. REJ_NIBBLES_ETA4(APPEND l1 l2) =
           APPEND (REJ_NIBBLES_ETA4 l1) (REJ_NIBBLES_ETA4 l2)`,
  REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES_APPEND; FILTER_APPEND]);;

let REJ_NIBBLES_ETA4_STEP = prove
 (`!inlist:byte list. !i:num.
   8 * (i + 1) <= LENGTH inlist
   ==> REJ_NIBBLES_ETA4(SUB_LIST(0, 8 * (i + 1)) inlist) =
       APPEND (REJ_NIBBLES_ETA4(SUB_LIST(0, 8 * i) inlist))
              (REJ_NIBBLES_ETA4(SUB_LIST(8 * i, 8) inlist))`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM REJ_NIBBLES_ETA4_APPEND] THEN
  AP_TERM_TAC THEN
  SUBGOAL_THEN `8 * (i + 1) = 0 + 8 * i + 8` SUBST1_TAC THENL
   [ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[SUB_LIST_SPLIT; SUB_LIST_CLAUSES; APPEND; ADD_CLAUSES]);;

(* FILTER length = sum of bitvals for 8 elements *)
let FILTER_LENGTH_BITVAL = prove(
  `!a b c d e f g h:int16.
   LENGTH(FILTER (\x:int16. val x < 9) [a;b;c;d;e;f;g;h]) =
   bitval(val a < 9) + bitval(val b < 9) + bitval(val c < 9) +
   bitval(val d < 9) + bitval(val e < 9) + bitval(val f < 9) +
   bitval(val g < 9) + bitval(val h < 9)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[FILTER] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH; bitval]) THEN
  ARITH_TAC);;

let REJ_NIBBLES_COUNT_4 = prove
 (`!b0 b1 b2 b3:byte.
   LENGTH(FILTER (\x:int16. val x < 9) (NIBBLES_OF_BYTES [b0;b1;b2;b3])) =
   bitval(val b0 MOD 16 < 9) + bitval(val b0 DIV 16 < 9) +
   bitval(val b1 MOD 16 < 9) + bitval(val b1 DIV 16 < 9) +
   bitval(val b2 MOD 16 < 9) + bitval(val b2 DIV 16 < 9) +
   bitval(val b3 MOD 16 < 9) + bitval(val b3 DIV 16 < 9)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[NIBBLES_OF_BYTES_4] THEN
  REWRITE_TAC[ISPECL [`word(val(b0:byte) MOD 16):int16`;
    `word(val(b0:byte) DIV 16):int16`;
    `word(val(b1:byte) MOD 16):int16`;
    `word(val(b1:byte) DIV 16):int16`;
    `word(val(b2:byte) MOD 16):int16`;
    `word(val(b2:byte) DIV 16):int16`;
    `word(val(b3:byte) MOD 16):int16`;
    `word(val(b3:byte) DIV 16):int16`] FILTER_LENGTH_BITVAL] THEN
  REWRITE_TAC[VAL_WORD_NIBBLE_LT]);;

let LENGTH_REJ_NIBBLES_ETA4 = prove
 (`!l:byte list. LENGTH(REJ_NIBBLES_ETA4 l) <= 2 * LENGTH l`,
  GEN_TAC THEN REWRITE_TAC[REJ_NIBBLES_ETA4] THEN
  TRANS_TAC LE_TRANS `LENGTH(NIBBLES_OF_BYTES l:int16 list)` THEN
  CONJ_TAC THENL [REWRITE_TAC[LENGTH_FILTER]; ALL_TAC] THEN
  SPEC_TAC(`l:byte list`,`l:byte list`) THEN
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; LENGTH; NIBBLE_PAIR;
                  APPEND; LENGTH_APPEND; LE_0] THEN
  UNDISCH_TAC `LENGTH(NIBBLES_OF_BYTES t:int16 list) <=
               2 * LENGTH(t:byte list)` THEN ARITH_TAC);;

let NIBLEN_BOUND_FROM_WOP = prove
 (`!inlist:byte list. !N.
   0 < N /\
   (!m. m < N ==> 8 * (m + 1) <= LENGTH inlist /\
        LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*m) inlist)) < 256)
   ==> LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list) < 272`,
  REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `N - 1`) THEN
  ASM_REWRITE_TAC[ARITH_RULE `N - 1 < N <=> 0 < N`] THEN STRIP_TAC THEN
  SUBGOAL_THEN `8 * N = 0 + 8 * (N - 1) + 8` SUBST1_TAC THENL
   [UNDISCH_TAC `0 < N` THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[SUB_LIST_SPLIT; SUB_LIST_CLAUSES; APPEND; ADD_CLAUSES] THEN
  REWRITE_TAC[REJ_NIBBLES_ETA4_APPEND; LENGTH_APPEND] THEN
  MP_TAC(ISPEC `SUB_LIST(8*(N-1),8) inlist:byte list`
    LENGTH_REJ_NIBBLES_ETA4) THEN
  REWRITE_TAC[LENGTH_SUB_LIST] THEN
  UNDISCH_TAC
   `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*(N-1)) inlist):int16 list) < 256` THEN
  ARITH_TAC);;

let COUNT_BRIDGE_ABSTRACT_4 = prove(
  `!x0:int128. !b0 b1 b2 b3:byte.
      word_subword x0 (0,16):int16 = word_zx(word_and b0 (word 15):byte):int16 /\
      word_subword x0 (16,16):int16 = word_zx(word_ushr b0 4:byte):int16 /\
      word_subword x0 (32,16):int16 = word_zx(word_and b1 (word 15):byte):int16 /\
      word_subword x0 (48,16):int16 = word_zx(word_ushr b1 4:byte):int16 /\
      word_subword x0 (64,16):int16 = word_zx(word_and b2 (word 15):byte):int16 /\
      word_subword x0 (80,16):int16 = word_zx(word_ushr b2 4:byte):int16 /\
      word_subword x0 (96,16):int16 = word_zx(word_and b3 (word 15):byte):int16 /\
      word_subword x0 (112,16):int16 = word_zx(word_ushr b3 4:byte):int16
      ==>
      bitval(val(word_subword x0 (0,16):int16) < 9) +
      bitval(val(word_subword x0 (16,16):int16) < 9) +
      bitval(val(word_subword x0 (32,16):int16) < 9) +
      bitval(val(word_subword x0 (48,16):int16) < 9) +
      bitval(val(word_subword x0 (64,16):int16) < 9) +
      bitval(val(word_subword x0 (80,16):int16) < 9) +
      bitval(val(word_subword x0 (96,16):int16) < 9) +
      bitval(val(word_subword x0 (112,16):int16) < 9) =
      LENGTH(REJ_NIBBLES_ETA4 [b0;b1;b2;b3])`,
  REPEAT GEN_TAC THEN DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN SUBST1_TAC) THEN
  REWRITE_TAC[REJ_NIBBLES_ETA4; REJ_NIBBLES_COUNT_4] THEN
  REWRITE_TAC[VAL_WORD_ZX_BYTE16; BYTE_AND_15_MOD; BYTE_USHR4_DIV] THEN
  ARITH_TAC);;

let REJ_NIBBLES_ETA4_LENGTH_4 = prove
 (`!b0 b1 b2 b3:byte.
     LENGTH(REJ_NIBBLES_ETA4 [b0;b1;b2;b3]:int16 list) <= 8`,
  REPEAT GEN_TAC THEN REWRITE_TAC[REJ_NIBBLES_ETA4] THEN
  W(MP_TAC o PART_MATCH lhand LENGTH_FILTER o lhand o snd) THEN
  REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; LENGTH] THEN
  ARITH_TAC);;

let REJ_SAMPLE_ETA4_SUB_LIST_PREFIX = prove
 (`!k (l:byte list).
     k <= LENGTH l
     ==> ?rest:int32 list.
         APPEND (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,k) l)) rest =
         REJ_SAMPLE_ETA4_BYTES l`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `REJ_SAMPLE_ETA4_BYTES (SUB_LIST(k, LENGTH l - k) l):int32 list` THEN
  REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; GSYM MAP_APPEND] THEN
  AP_TERM_TAC THEN
  REWRITE_TAC[REJ_NIBBLES_ETA4; GSYM FILTER_APPEND] THEN
  AP_TERM_TAC THEN
  REWRITE_TAC[GSYM NIBBLES_OF_BYTES_APPEND] THEN
  AP_TERM_TAC THEN
  MP_TAC(ISPECL [`l:byte list`; `k:num`] SUB_LIST_TOPSPLIT) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> GEN_REWRITE_TAC RAND_CONV [SYM th]) THEN
  REFL_TAC);;

let SUB_LIST_256_PREFIX_LARGE = prove
 (`!inlist:byte list. !nn:num.
     256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 8*nn) inlist):int16 list)
     ==>
     SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist) =
     SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES (SUB_LIST(0, 8*nn) inlist))`,
  REPEAT STRIP_TAC THEN
  ASM_CASES_TAC `8 * nn <= LENGTH(inlist:byte list)` THENL
   [MP_TAC(ISPECL [`8 * nn:num`; `inlist:byte list`]
                REJ_SAMPLE_ETA4_SUB_LIST_PREFIX) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN(X_CHOOSE_THEN `rest:int32 list` (fun th ->
      GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [SYM th])) THEN
    MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN
    REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP] THEN ASM_REWRITE_TAC[];

    SUBGOAL_THEN `SUB_LIST(0, 8 * nn) (inlist:byte list) = inlist` SUBST1_TAC THENL
     [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_ARITH_TAC;
      REFL_TAC]]);;

(* canonical word(num_of_wordlist [4 int32s]) form. *)

let SSHLL_CHUNK_WORD_SUBWORD_LO_INT64 = BITBLAST_RULE
 `word_subword
  (word_join
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword (c:int128) (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (48,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (32,16):int16):int32) 0):int64)
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (16,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (0,16):int16):int32) 0):int64):int128) (0,64):int64 =
  word_join (word_sx(word_sub (word 4:int16) (word_subword c (16,16):int16)):int32)
            (word_sx(word_sub (word 4:int16) (word_subword c (0,16):int16)):int32):int64`;;

let SSHLL_CHUNK_WORD_SUBWORD_HI_INT64 = BITBLAST_RULE
 `word_subword
  (word_join
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword (c:int128) (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (48,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (32,16):int16):int32) 0):int64)
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (16,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (0,64):int64) (0,16):int16):int32) 0):int64):int128) (64,64):int64 =
  word_join (word_sx(word_sub (word 4:int16) (word_subword c (48,16):int16)):int32)
            (word_sx(word_sub (word 4:int16) (word_subword c (32,16):int16)):int32):int64`;;

let SSHLL_CHUNK_WORD_SUBWORD_LO_INT64_HIINNER = BITBLAST_RULE
 `word_subword
  (word_join
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword (c:int128) (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (48,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (32,16):int16):int32) 0):int64)
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (16,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (0,16):int16):int32) 0):int64):int128) (0,64):int64 =
  word_join (word_sx(word_sub (word 4:int16) (word_subword c (80,16):int16)):int32)
            (word_sx(word_sub (word 4:int16) (word_subword c (64,16):int16)):int32):int64`;;

let BIGNUM_LIST_OF_SEQ_EQ_NUM_SUB_LIST =
  ISPEC `\x:int16. word_sx (word_sub (word 4:int16) x):int32`
        BIGNUM_LIST_OF_SEQ_EQ_NUM_SUB_LIST_POLY;;

let PAIR_MAP_IDX_128 =
  let pairs_str = String.concat ";\n      "
    (List.map (fun k ->
       Printf.sprintf
         "word_join (word_sx (word_sub (word 4:int16) (EL %d l)):int32) (word_sx (word_sub (word 4:int16) (EL %d l)):int32)"
         (2*k+1) (2*k)) (0--127)) in
  let goal_str = Printf.sprintf
    "!l:int16 list. 256 <= LENGTH l ==> \
     bignum_of_wordlist [%s] = \
     num_of_wordlist (MAP (\\x:int16. word_sx (word_sub (word 4) x):int32) (SUB_LIST (0,256) l))"
    pairs_str in
  prove
   (parse_term goal_str,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[BIGNUM_OF_WORDLIST_EQ_NUM_OF_WORDLIST] THEN
    SUBGOAL_THEN `[]:int64 list = pair_wordlist ([]:int32 list)` (fun th ->
      GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV) [th]) THENL
     [REWRITE_TAC[pair_wordlist]; ALL_TAC] THEN
    REWRITE_TAC[GSYM(el 0 (CONJUNCTS pair_wordlist))] THEN
    REWRITE_TAC[NUM_OF_PAIR_WORDLIST] THEN
    MP_TAC(ISPECL [`256`; `l:int16 list`] SUB_LIST_EQ_LIST_OF_SEQ) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN SUBST1_TAC THEN
    CONV_TAC(RAND_CONV(RAND_CONV(RAND_CONV LIST_OF_SEQ_CONV))) THEN
    REWRITE_TAC[MAP]);;

let SSHLL_CHUNK_WORD_SUBWORD_HI_INT64_HIINNER = BITBLAST_RULE
 `word_subword
  (word_join
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword (c:int128) (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (48,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (32,16):int16):int32) 0):int64)
   (word_join
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (16,16):int16):int32) 0)
    (word_shl (word_sx (word_subword (word_subword
      (word_join (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (112,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (96,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (80,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (64,16):int16):int16):int32):int64)
       (word_join (word_join
         (word_sub (word 4:int16) (word_subword c (48,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (32,16):int16):int16):int32)
        (word_join (word_sub (word 4:int16) (word_subword c (16,16):int16):int16)
         (word_sub (word 4:int16) (word_subword c (0,16):int16):int16):int32):int64)
       :int128) (64,64):int64) (0,16):int16):int32) 0):int64):int128) (64,64):int64 =
  word_join (word_sx(word_sub (word 4:int16) (word_subword c (112,16):int16)):int32)
            (word_sx(word_sub (word 4:int16) (word_subword c (96,16):int16)):int32):int64`;;

let REJ_NIBBLES_ETA4_SPLIT_8 = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7:byte.
     REJ_NIBBLES_ETA4 [b0;b1;b2;b3;b4;b5;b6;b7] =
     APPEND (REJ_NIBBLES_ETA4 [b0;b1;b2;b3])
            (REJ_NIBBLES_ETA4 [b4;b5;b6;b7]:int16 list)`,
  REPEAT GEN_TAC THEN
  SUBST1_TAC(SYM(EQT_ELIM(REWRITE_CONV[APPEND]
    `APPEND [b0:byte;b1;b2;b3] [b4;b5;b6;b7] =
     [b0;b1;b2;b3;b4;b5;b6;b7]`))) THEN
  REWRITE_TAC[REJ_NIBBLES_ETA4_APPEND]);;

let CASE_B_TRUNCATE_L = prove
 (`!res:int64 niblen:num niblist:int16 list (L:int16 list) s:armstate.
    niblen <= 256 /\
    LENGTH niblist = niblen /\
    LENGTH L = 256 /\
    SUB_LIST(0, niblen) L = niblist /\
    read (memory :> bytes (res, 1024)) s =
    num_of_wordlist (MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32) L)
    ==>
    read (memory :> bytes (res, 4 * niblen)) s =
    num_of_wordlist (MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32) niblist)`,
  REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o AP_TERM `(\n:num. n MOD 2 EXP (8 * (4 * niblen)))`) THEN
  CONV_TAC(ONCE_DEPTH_CONV BETA_CONV) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_MOD] THEN
  SUBGOAL_THEN `MIN 1024 (4 * niblen) = 4 * niblen` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `8 * 4 * niblen = dimindex(:32) * niblen` SUBST1_TAC THENL
   [REWRITE_TAC[DIMINDEX_32] THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[GSYM NUM_OF_WORDLIST_SUB_LIST_0] THEN
  SUBGOAL_THEN
    `SUB_LIST(0, niblen)
       (MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32) L) =
     MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32) niblist`
    SUBST1_TAC THENL
   [REWRITE_TAC[SUB_LIST_MAP] THEN AP_TERM_TAC THEN ASM_REWRITE_TAC[];
    REWRITE_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Correctness proof.                                                        *)
(*                                                                           *)
(* Strategy: WOP-based loop count N, ENSURES_WHILE_UP_TAC over main loop,    *)
(* split computation + writeback at pc+256, then Case A (niblen>=256) and    *)
(* Case B (niblen<256) closures.                                             *)
(* ------------------------------------------------------------------------- *)


let MLDSA_REJ_UNIFORM_ETA4_CORRECT = prove
 (`!res buf buflen table (inlist:byte list) pc stackpointer.
      8 divides val buflen /\
      8 <= val buflen /\
      LENGTH inlist = val buflen /\
      ALL (nonoverlapping (stackpointer,576))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (buf,val buflen); (table,4096)] /\
      ALL (nonoverlapping (res,1024))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (stackpointer,576)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word(pc + MLDSA_REJ_UNIFORM_ETA4_CORE_START) /\
                read SP s = stackpointer /\
                C_ARGUMENTS [res;buf;buflen;table] s /\
                read(memory :> bytes(table,4096)) s =
                num_of_wordlist mldsa_rej_uniform_eta_table /\
                read(memory :> bytes(buf,val buflen)) s =
                num_of_wordlist inlist)
           (\s. read PC s = word(pc + MLDSA_REJ_UNIFORM_ETA4_CORE_END) /\
                let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES inlist) in
                let outlen = LENGTH outlist in
                C_RETURN s = word outlen /\
                read(memory :> bytes(res,4 * outlen)) s =
                num_of_wordlist outlist)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024);
                       memory :> bytes(stackpointer,576)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  REWRITE_TAC[fst MLDSA_REJ_UNIFORM_ETA4_EXEC;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
    C_ARGUMENTS; ALL; C_RETURN] THEN
 MAP_EVERY X_GEN_TAC [`res:int64`; `buf:int64`] THEN
 W64_GEN_TAC `buflen:num` THEN
 MAP_EVERY X_GEN_TAC
  [`table:int64`; `inlist:byte list`; `pc:num`; `stackpointer:int64`] THEN
 DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

 ENSURES_SEQUENCE_TAC `pc + 256`
  `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
       read PC s = word(pc + 256) /\
       read X0 s = res /\ read X4 s = word 256 /\
       read X8 s = stackpointer /\
       read Q7 s = word 20769504351625144638033088116686852 /\
       ALL (nonoverlapping (res,1024)) [(word pc,344); (stackpointer,576)] /\
       ?n. let niblist = REJ_NIBBLES_ETA4(SUB_LIST(0,8*n) inlist) in
           let niblen = LENGTH niblist in
           niblen < 272 /\
           (buflen < 8 * (n + 1) \/ 256 <= niblen) /\
           read X9 s = word niblen /\
           read (memory :> bytes (stackpointer,2 * niblen)) s =
           num_of_wordlist niblist` THEN
 CONJ_TAC THENL
  [ALL_TAC;

   ENSURES_INIT_TAC "s0" THEN
   FIRST_X_ASSUM(X_CHOOSE_THEN `nn:num` MP_TAC) THEN
   CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
   ABBREV_TAC `niblist = REJ_NIBBLES_ETA4
     (SUB_LIST(0,8*nn) inlist):int16 list` THEN
   ABBREV_TAC `niblen = LENGTH(niblist:int16 list)` THEN
   DISCH_THEN(fun th ->
     MAP_EVERY ASSUME_TAC (CONJUNCTS th)) THEN
   SUBGOAL_THEN `val(word niblen:int64) = niblen` ASSUME_TAC THENL
    [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
     UNDISCH_TAC `niblen < 272` THEN ARITH_TAC; ALL_TAC] THEN
   BIGNUM_LDIGITIZE_TAC "b_"
     `read (memory :> bytes(stackpointer,8 * 64)) s0` THEN
   MEMORY_128_FROM_64_TAC "stackpointer" 0 32 THEN
   ASM_REWRITE_TAC[WORD_ADD_0] THEN STRIP_TAC THEN
   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--245) THEN
   ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
   SUBGOAL_THEN
     `LENGTH(SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist):int32 list) =
      MIN 256 niblen`
   ASSUME_TAC THENL
    [REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN
     FIRST_X_ASSUM DISJ_CASES_TAC THENL
      [(* Case A: buflen < 8*(nn+1). Together with 8 divides buflen,
          forces either 8*nn = buflen (SUB_LIST = inlist) or 8*nn > buflen
          (also SUB_LIST = inlist). Either way niblist = REJ_NIBBLES_ETA4 inlist. *)
       SUBGOAL_THEN `SUB_LIST(0, 8 * nn) (inlist:byte list) = inlist`
         SUBST_ALL_TAC THENL
        [MATCH_MP_TAC SUB_LIST_REFL THEN
         UNDISCH_TAC `8 divides buflen` THEN REWRITE_TAC[divides] THEN
         DISCH_THEN(X_CHOOSE_THEN `k:num` SUBST_ALL_TAC) THEN
         UNDISCH_TAC `LENGTH(inlist:byte list) = 8 * k` THEN
         DISCH_THEN SUBST1_TAC THEN
         REWRITE_TAC[LE_MULT_LCANCEL] THEN
         UNDISCH_TAC `8 * k < 8 * (nn + 1)` THEN
         REWRITE_TAC[LT_MULT_LCANCEL] THEN ARITH_TAC;
         ALL_TAC] THEN
       SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = niblen`
         SUBST1_TAC THENL
        [REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP] THEN ASM_REWRITE_TAC[];
         REFL_TAC];

       ASM_CASES_TAC `8 * nn <= LENGTH(inlist:byte list)` THENL
        [(* 8*nn <= buflen: prefix lemma gives APPEND niblist rest = REJ_SAMPLE *)
         MP_TAC(ISPECL [`8 * nn`; `inlist:byte list`]
                REJ_SAMPLE_ETA4_SUB_LIST_PREFIX) THEN
         ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
         DISCH_THEN(X_CHOOSE_THEN `rest:int32 list` ASSUME_TAC) THEN
         SUBGOAL_THEN
           `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) =
            niblen + LENGTH(rest:int32 list)`
          SUBST1_TAC THENL
          [FIRST_X_ASSUM(fun th ->
             GEN_REWRITE_TAC(LAND_CONV o ONCE_DEPTH_CONV)[SYM th]) THEN
           REWRITE_TAC[LENGTH_APPEND; REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP] THEN
           ASM_REWRITE_TAC[];
           ALL_TAC] THEN
         UNDISCH_TAC `256 <= niblen` THEN ARITH_TAC;

         SUBGOAL_THEN `SUB_LIST(0, 8 * nn) (inlist:byte list) = inlist`
           SUBST_ALL_TAC THENL
          [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_ARITH_TAC;
           ALL_TAC] THEN
         SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = niblen`
           SUBST1_TAC THENL
          [REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP] THEN ASM_REWRITE_TAC[];
           REFL_TAC]]]; ALL_TAC] THEN
   ASM_REWRITE_TAC[] THEN
   CONJ_TAC THENL
    [(* Conjunct 1: word(MIN 256 niblen) = if niblen < 256 then word niblen else word 256 *)
     COND_CASES_TAC THEN AP_TERM_TAC THEN ASM_ARITH_TAC;

     FIRST_X_ASSUM(DISJ_CASES_THEN ASSUME_TAC) THENL
      [(* Case B: buflen < 8*(nn+1). SUB_LIST(0, 8*nn) inlist = inlist,
          so niblist = REJ_NIBBLES_ETA4 inlist. *)
       SUBGOAL_THEN `SUB_LIST(0, 8 * nn) (inlist:byte list) = inlist`
         ASSUME_TAC THENL
        [MATCH_MP_TAC SUB_LIST_8nn_INLIST THEN EXISTS_TAC `buflen:num` THEN
         ASM_REWRITE_TAC[];
         ALL_TAC] THEN

       SUBGOAL_THEN
        `REJ_SAMPLE_ETA4_BYTES (inlist:byte list) =
         MAP (\x. word_sx(word_sub (word 4:int16) x):int32) niblist`
       ASSUME_TAC THENL
        [REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES] THEN AP_TERM_TAC THEN
         UNDISCH_TAC
           `REJ_NIBBLES_ETA4 (SUB_LIST(0,8 * nn) (inlist:byte list)) =
            (niblist:int16 list)` THEN
         ASM_REWRITE_TAC[];
         ALL_TAC] THEN

       ASM_CASES_TAC `256 <= niblen` THENL
        [(* niblen >= 256 sub-branch: reuses Case A closure verbatim.        *)
         SUBGOAL_THEN `MIN 256 niblen = 256` SUBST1_TAC THENL
          [ASM_ARITH_TAC; ALL_TAC] THEN
         REWRITE_TAC[ARITH_RULE `4 * 256 = 1024`] THEN
         SUBGOAL_THEN
          `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES (inlist:byte list)) =
           SUB_LIST(0,256)(MAP (\x. word_sx(word_sub (word 4:int16) x):int32)
                             (niblist:int16 list))`
         SUBST1_TAC THENL
          [ASM_REWRITE_TAC[];
           ALL_TAC] THEN
         REWRITE_TAC[SUB_LIST_MAP] THEN
         SUBGOAL_THEN
           `SUB_LIST(0, 256) (niblist:int16 list) = STACK_CONTENT niblist`
         SUBST1_TAC THENL
          [CONV_TAC SYM_CONV THEN MATCH_MP_TAC STACK_CONTENT_LARGE THEN
           UNDISCH_TAC `LENGTH(niblist:int16 list) = niblen` THEN
           DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[];
           ALL_TAC] THEN
         MP_TAC(GEN `k:num` (ISPECL [`s245:armstate`; `stackpointer:int64`;
                                      `niblist:int16 list`; `k:num`]
                                     BK_FROM_STACK_GE256)) THEN
         ASM_REWRITE_TAC[] THEN
         DISCH_THEN(fun bk_univ ->
           MAP_EVERY (fun i ->
             let inst = SPEC (mk_small_numeral i) bk_univ in
             let premise = EQT_ELIM (NUM_LT_CONV (lhand(concl inst))) in
             ASSUME_TAC (MP inst premise)) (0--63)) THEN
         RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV NUM_MULT_CONV)) THEN
         RULE_ASSUM_TAC(REWRITE_RULE[WORD_ADD_0]) THEN
         (fun (asl, _ as gl) ->
           let bk_trans_thms = List.filter_map (fun (_, th) ->
             let c = concl th in
             if is_eq c then
               let rhs = rand c in
               if is_var rhs && String.length (fst (dest_var rhs)) >= 2 &&
                  String.sub (fst (dest_var rhs)) 0 2 = "b_" then
                 let lhs = lhand c in
                 let bk_fact = List.find_opt (fun (_, th2) ->
                   let c2 = concl th2 in
                   is_eq c2 && lhs = lhand c2 && rhs <> rand c2) asl in
                 (match bk_fact with
                  | Some (_, bk_th) -> Some (TRANS (SYM th) bk_th)
                  | None -> None)
               else None
             else None) asl in
           MAP_EVERY ASSUME_TAC bk_trans_thms gl) THEN
         REWRITE_TAC[ARITH_RULE `1024 = 8 * 128`] THEN
         CONV_TAC(ONCE_DEPTH_CONV BIGNUM_LEXPAND_CONV) THEN
         RULE_ASSUM_TAC(CONV_RULE(ONCE_DEPTH_CONV(READ_MEMORY_SPLIT_CONV 1))) THEN
         ASM_REWRITE_TAC[] THEN
         REWRITE_TAC[SSHLL_CHUNK_WORD_SUBWORD_LO_INT64;
                     SSHLL_CHUNK_WORD_SUBWORD_HI_INT64;
                     SSHLL_CHUNK_WORD_SUBWORD_LO_INT64_HIINNER;
                     SSHLL_CHUNK_WORD_SUBWORD_HI_INT64_HIINNER] THEN
         SUBGOAL_THEN `256 <= LENGTH (niblist:int16 list)` ASSUME_TAC THENL
          [UNDISCH_TAC `LENGTH(niblist:int16 list) = niblen` THEN
           DISCH_THEN SUBST1_TAC THEN
           UNDISCH_TAC `256 <= niblen` THEN REWRITE_TAC[];
           ALL_TAC] THEN
         MP_TAC(GEN `a:num` (ISPECL [`niblist:int16 list`; `a:num`]
                                    WORD_SUBWORD_JOIN_SUB_LIST_H)) THEN
         DISCH_THEN(fun univ_th ->
           MAP_EVERY (fun i ->
             let inst = SPEC (mk_small_numeral i) univ_th in
             let prem_term = lhand(concl inst) in
             let prem_thm = ARITH_RULE(mk_imp(
               `256 <= LENGTH (niblist:int16 list)`, prem_term)) in
             let raw = MATCH_MP inst
               (MP prem_thm (ASSUME `256 <= LENGTH (niblist:int16 list)`)) in
             let discharged = CONV_RULE (REWRITE_CONV[ARITH]) raw in
             REWRITE_TAC[discharged])
             (List.map (fun k -> 8 * k) (0--31))) THEN
         SUBGOAL_THEN `STACK_CONTENT (niblist:int16 list) = SUB_LIST(0, 256) niblist`
           SUBST1_TAC THENL
          [MATCH_MP_TAC STACK_CONTENT_LARGE THEN ASM_REWRITE_TAC[];
           ALL_TAC] THEN
         MP_TAC(ISPECL
           [`128`;
            `MAP (\x. word_sx (word_sub (word 4:int16) x):int32)
                 (SUB_LIST(0, 256) (niblist:int16 list))`]
           BIGNUM_WORDJOIN_PAIRS_EXISTS) THEN
         ANTS_TAC THENL
          [REWRITE_TAC[LENGTH_MAP; LENGTH_SUB_LIST] THEN
           UNDISCH_TAC `256 <= LENGTH (niblist:int16 list)` THEN ARITH_TAC;
           ALL_TAC] THEN
         DISCH_THEN(X_CHOOSE_THEN `pairs:int64 list` STRIP_ASSUME_TAC) THEN
         MP_TAC(ISPECL [`niblist:int16 list`; `128`]
                       BIGNUM_LIST_OF_SEQ_EQ_NUM_SUB_LIST) THEN
         ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
         REWRITE_TAC[ARITH_RULE `2 * 128 = 256`] THEN
         DISCH_THEN(SUBST1_TAC o SYM) THEN
         AP_TERM_TAC THEN
         CONV_TAC SYM_CONV THEN
         CONV_TAC(LAND_CONV (
           REWRITE_CONV (list_of_seq :: APPEND ::
             List.map (fun k -> num_CONV (mk_small_numeral k)) (1--128))
           THENC TOP_DEPTH_CONV BETA_CONV
           THENC NUM_REDUCE_CONV)) THEN
         REFL_TAC;

         SUBGOAL_THEN `niblen < 256` ASSUME_TAC THENL
          [ASM_ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN `MIN 256 niblen = niblen` SUBST1_TAC THENL
          [ASM_ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN
           `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES (inlist:byte list)) =
            MAP (\x. word_sx(word_sub (word 4:int16) x):int32) niblist`
           SUBST1_TAC THENL
          [ASM_REWRITE_TAC[] THEN MATCH_MP_TAC SUB_LIST_REFL THEN
           REWRITE_TAC[LENGTH_MAP] THEN ASM_ARITH_TAC;
           ALL_TAC] THEN
         MP_TAC(ISPECL [`stackpointer:int64`; `256`; `s245:armstate`]
                       BYTES_EXISTS_WORDLIST) THEN
         REWRITE_TAC[ARITH_RULE `2 * 256 = 512`] THEN
         DISCH_THEN(X_CHOOSE_THEN `L:int16 list` STRIP_ASSUME_TAC) THEN
         SUBGOAL_THEN `SUB_LIST(0, niblen) (L:int16 list) = niblist`
           ASSUME_TAC THENL
          [MATCH_MP_TAC PREFIX_FROM_STACK THEN
           MAP_EVERY EXISTS_TAC
             [`stackpointer:int64`; `s245:armstate`] THEN
           ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
           ALL_TAC] THEN
         MATCH_MP_TAC CASE_B_TRUNCATE_L THEN
         EXISTS_TAC `L:int16 list` THEN
         ASM_REWRITE_TAC[] THEN
         CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN `256 <= LENGTH (L:int16 list)` ASSUME_TAC THENL
          [ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
         MP_TAC(GEN `k:num` (ISPECL [`s245:armstate`; `stackpointer:int64`;
                                      `L:int16 list`; `k:num`]
                                     BK_FROM_STACK_GE256)) THEN
         ASM_REWRITE_TAC[ARITH_RULE `2 * 256 = 512`] THEN
         DISCH_THEN(fun bk_univ ->
           MAP_EVERY (fun i ->
             let inst = SPEC (mk_small_numeral i) bk_univ in
             let premise = EQT_ELIM (NUM_LT_CONV (lhand(concl inst))) in
             ASSUME_TAC (MP inst premise)) (0--63)) THEN
         RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV NUM_MULT_CONV)) THEN
         RULE_ASSUM_TAC(REWRITE_RULE[WORD_ADD_0]) THEN
         (fun (asl, _ as gl) ->
           let bk_trans_thms = List.filter_map (fun (_, th) ->
             let c = concl th in
             if is_eq c then
               let rhs = rand c in
               if is_var rhs && String.length (fst (dest_var rhs)) >= 2 &&
                  String.sub (fst (dest_var rhs)) 0 2 = "b_" then
                 let lhs = lhand c in
                 let bk_fact = List.find_opt (fun (_, th2) ->
                   let c2 = concl th2 in
                   is_eq c2 && lhs = lhand c2 && rhs <> rand c2) asl in
                 (match bk_fact with
                  | Some (_, bk_th) -> Some (TRANS (SYM th) bk_th)
                  | None -> None)
               else None
             else None) asl in
             (List.length bk_trans_thms);
           MAP_EVERY ASSUME_TAC bk_trans_thms gl) THEN
         REWRITE_TAC[ARITH_RULE `1024 = 8 * 128`] THEN
         CONV_TAC(ONCE_DEPTH_CONV BIGNUM_LEXPAND_CONV) THEN
         RULE_ASSUM_TAC(CONV_RULE(ONCE_DEPTH_CONV(READ_MEMORY_SPLIT_CONV 1))) THEN
         ASM_REWRITE_TAC[] THEN
         REWRITE_TAC[SSHLL_CHUNK_WORD_SUBWORD_LO_INT64;
                     SSHLL_CHUNK_WORD_SUBWORD_HI_INT64;
                     SSHLL_CHUNK_WORD_SUBWORD_LO_INT64_HIINNER;
                     SSHLL_CHUNK_WORD_SUBWORD_HI_INT64_HIINNER] THEN
         MP_TAC(GEN `a:num` (ISPECL [`L:int16 list`; `a:num`]
                                    WORD_SUBWORD_JOIN_SUB_LIST_H)) THEN
         DISCH_THEN(fun univ_th ->
           MAP_EVERY (fun i ->
             let inst = SPEC (mk_small_numeral i) univ_th in
             let prem_term = lhand(concl inst) in
             let prem_thm = ARITH_RULE(mk_imp(
               `256 <= LENGTH (L:int16 list)`, prem_term)) in
             let raw = MATCH_MP inst
               (MP prem_thm (ASSUME `256 <= LENGTH (L:int16 list)`)) in
             let discharged = CONV_RULE (REWRITE_CONV[ARITH]) raw in
             REWRITE_TAC[discharged])
             (List.map (fun k -> 8 * k) (0--31))) THEN

         SUBGOAL_THEN `SUB_LIST(0, 256) (L:int16 list) = L` SUBST1_TAC THENL
          [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_REWRITE_TAC[LE_REFL];
           ALL_TAC] THEN
         MP_TAC(SPEC `L:int16 list` PAIR_MAP_IDX_128) THEN
         ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
         SUBGOAL_THEN `SUB_LIST(0, 256) (L:int16 list) = L` SUBST1_TAC THENL
          [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_REWRITE_TAC[LE_REFL];
           DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC]];
       SUBGOAL_THEN `MIN 256 niblen = 256` SUBST1_TAC THENL
        [ASM_ARITH_TAC; ALL_TAC] THEN
       REWRITE_TAC[ARITH_RULE `4 * 256 = 1024`] THEN
       SUBGOAL_THEN
        `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES (inlist:byte list)) =
         SUB_LIST(0,256)(MAP (\x. word_sx(word_sub (word 4:int16) x):int32)
                           (niblist:int16 list))`
       SUBST1_TAC THENL
        [MP_TAC(SPECL [`inlist:byte list`; `nn:num`] SUB_LIST_256_PREFIX_LARGE) THEN
         ANTS_TAC THENL
          [(* 256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0, 8*nn) inlist)) *)
           UNDISCH_TAC
             `REJ_NIBBLES_ETA4 (SUB_LIST(0,8 * nn) (inlist:byte list)) =
              (niblist:int16 list)` THEN
           DISCH_THEN SUBST1_TAC THEN
           UNDISCH_TAC `LENGTH(niblist:int16 list) = niblen` THEN
           DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[];
           ALL_TAC] THEN
         DISCH_THEN SUBST1_TAC THEN AP_TERM_TAC THEN
         ASM_REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES];
         ALL_TAC] THEN

       REWRITE_TAC[SUB_LIST_MAP] THEN
       SUBGOAL_THEN
         `SUB_LIST(0, 256) (niblist:int16 list) = STACK_CONTENT niblist`
       SUBST1_TAC THENL
        [CONV_TAC SYM_CONV THEN MATCH_MP_TAC STACK_CONTENT_LARGE THEN
         UNDISCH_TAC `LENGTH(niblist:int16 list) = niblen` THEN
         DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[];
         ALL_TAC] THEN
       MP_TAC(GEN `k:num` (ISPECL [`s245:armstate`; `stackpointer:int64`;
                                    `niblist:int16 list`; `k:num`]
                                   BK_FROM_STACK_GE256)) THEN
       ASM_REWRITE_TAC[] THEN
       DISCH_THEN(fun bk_univ ->
         MAP_EVERY (fun i ->
           let inst = SPEC (mk_small_numeral i) bk_univ in
           let premise = EQT_ELIM (NUM_LT_CONV (lhand(concl inst))) in
           ASSUME_TAC (MP inst premise)) (0--63)) THEN
       RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV NUM_MULT_CONV)) THEN
       RULE_ASSUM_TAC(REWRITE_RULE[WORD_ADD_0]) THEN
       (fun (asl, _ as gl) ->
         let bk_trans_thms = List.filter_map (fun (_, th) ->
           let c = concl th in
           if is_eq c then
             let rhs = rand c in
             if is_var rhs && String.length (fst (dest_var rhs)) >= 2 &&
                String.sub (fst (dest_var rhs)) 0 2 = "b_" then
               let lhs = lhand c in
               let bk_fact = List.find_opt (fun (_, th2) ->
                 let c2 = concl th2 in
                 is_eq c2 && lhs = lhand c2 && rhs <> rand c2) asl in
               (match bk_fact with
                | Some (_, bk_th) ->
                  Some (TRANS (SYM th) bk_th)
                | None -> None)
             else None
           else None) asl in
           (List.length bk_trans_thms);
         MAP_EVERY ASSUME_TAC bk_trans_thms gl) THEN

       REWRITE_TAC[ARITH_RULE `1024 = 8 * 128`] THEN
       CONV_TAC(ONCE_DEPTH_CONV BIGNUM_LEXPAND_CONV) THEN
       RULE_ASSUM_TAC(CONV_RULE(ONCE_DEPTH_CONV(READ_MEMORY_SPLIT_CONV 1))) THEN
       ASM_REWRITE_TAC[] THEN
       REWRITE_TAC[SSHLL_CHUNK_WORD_SUBWORD_LO_INT64;
                   SSHLL_CHUNK_WORD_SUBWORD_HI_INT64;
                   SSHLL_CHUNK_WORD_SUBWORD_LO_INT64_HIINNER;
                   SSHLL_CHUNK_WORD_SUBWORD_HI_INT64_HIINNER] THEN

       SUBGOAL_THEN `256 <= LENGTH (niblist:int16 list)` ASSUME_TAC THENL
        [UNDISCH_TAC `LENGTH(niblist:int16 list) = niblen` THEN
         DISCH_THEN SUBST1_TAC THEN
         UNDISCH_TAC `256 <= niblen` THEN REWRITE_TAC[];
         ALL_TAC] THEN
       MP_TAC(GEN `a:num` (ISPECL [`niblist:int16 list`; `a:num`]
                                  WORD_SUBWORD_JOIN_SUB_LIST_H)) THEN
       DISCH_THEN(fun univ_th ->
         MAP_EVERY (fun i ->
           let inst = SPEC (mk_small_numeral i) univ_th in
           let prem_term = lhand(concl inst) in
           let prem_thm = ARITH_RULE(mk_imp(
             `256 <= LENGTH (niblist:int16 list)`, prem_term)) in
           let raw = MATCH_MP inst
             (MP prem_thm (ASSUME `256 <= LENGTH (niblist:int16 list)`)) in
           let discharged = CONV_RULE
             (REWRITE_CONV[ARITH]) raw in
           REWRITE_TAC[discharged])
           (List.map (fun k -> 8 * k) (0--31))) THEN

       SUBGOAL_THEN `STACK_CONTENT (niblist:int16 list) = SUB_LIST(0, 256) niblist`
         SUBST1_TAC THENL
        [MATCH_MP_TAC STACK_CONTENT_LARGE THEN ASM_REWRITE_TAC[];
         ALL_TAC] THEN
       MATCH_MP_TAC PAIR_MAP_IDX_128 THEN
       ASM_REWRITE_TAC[]]]] THEN

 SUBGOAL_THEN
  `?N. buflen < 8 * (N + 1) \/
       256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)`
 MP_TAC THENL
  [EXISTS_TAC `buflen:num` THEN DISJ1_TAC THEN ARITH_TAC;
   GEN_REWRITE_TAC LAND_CONV [num_WOP]] THEN
 DISCH_THEN(X_CHOOSE_THEN `N:num`
   (CONJUNCTS_THEN2 ASSUME_TAC MP_TAC)) THEN
 REWRITE_TAC[DE_MORGAN_THM; NOT_LT; NOT_LE] THEN STRIP_TAC THEN

 SUBGOAL_THEN `0 < N` ASSUME_TAC THENL
  [(* ASM_ARITH_TAC times out on many irrelevant hyps; use MP_TAC + ARITH *)
   MP_TAC(ASSUME `buflen < 8 * (N + 1) \/
     256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)`) THEN
   UNDISCH_TAC `8 <= buflen` THEN
   STRUCT_CASES_TAC (ARITH_RULE `N = 0 \/ 0 < N`) THEN
   ASM_REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES;
                   REJ_NIBBLES_ETA4_EMPTY; LENGTH] THEN
   ARITH_TAC;
   ALL_TAC] THEN

 ENSURES_WHILE_UP_TAC `N:num` `pc + 108` `pc + 248`
  `\i s. read (memory :> bytes (table,4096)) s =
         num_of_wordlist mldsa_rej_uniform_eta_table /\
         read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
         aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
         read Q7 s = word 20769504351625144638033088116686852 /\
         read Q30 s = word 46731384791156575435574448262545417 /\
         read Q31 s = word 664619068533544770747334646890102785 /\
         let niblist = REJ_NIBBLES_ETA4(SUB_LIST(0,8 * i) inlist) in
         let niblen = LENGTH niblist in
         read X0 s = res /\
         read X1 s = word_add buf (word(8 * i)) /\
         read X2 s = word_sub (word buflen) (word(8 * i)) /\
         read X3 s = table /\ read X4 s = word 256 /\
         read X7 s = word_add stackpointer (word(2 * niblen)) /\
         read X8 s = stackpointer /\ read X9 s = word niblen /\
         read (memory :> bytes (stackpointer,2 * niblen)) s =
         num_of_wordlist niblist` THEN
 REPEAT CONJ_TAC THENL
  [(*** Subgoal 1: 0 < N ***)
   ASM_ARITH_TAC;

   GHOST_INTRO_TAC `q31_init:int128` `read Q31` THEN
   ENSURES_INIT_TAC "s0" THEN
   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--75) THEN
   ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
   CONJ_TAC THENL [REWRITE_TAC[WORD_INSERT_Q31]; ALL_TAC] THEN
   REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; REJ_NIBBLES_ETA4_EMPTY] THEN
   CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REWRITE_TAC[LENGTH] THEN
   REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; WORD_SUB_0] THEN
   REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_TRIVIAL; num_of_wordlist];

   X_GEN_TAC `i:num` THEN STRIP_TAC THEN
   ABBREV_TAC `curlist = REJ_NIBBLES_ETA4(SUB_LIST(0,8 * i) inlist)` THEN
   ABBREV_TAC `curlen = LENGTH(curlist:int16 list)` THEN
   SUBGOAL_THEN `curlen < 256` ASSUME_TAC THENL
    [EXPAND_TAC "curlen" THEN EXPAND_TAC "curlist" THEN
     FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
     UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
   SUBGOAL_THEN `8 * (i + 1) <= buflen` ASSUME_TAC THENL
    [FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
     UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
   CONV_TAC(RATOR_CONV(LAND_CONV(TOP_DEPTH_CONV let_CONV))) THEN
   ASM_REWRITE_TAC[] THEN

   ENSURES_SEQUENCE_TAC `pc + 0xe0`
    `\s. read (memory :> bytes (table,4096)) s =
         num_of_wordlist mldsa_rej_uniform_eta_table /\
         read (memory :> bytes (buf,buflen)) s = num_of_wordlist (inlist:byte list) /\
         aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
         read Q7 s = word 20769504351625144638033088116686852 /\
         read Q30 s = word 46731384791156575435574448262545417 /\
         read Q31 s = word 664619068533544770747334646890102785 /\
         read X0 s = res /\
         read X1 s = word_add buf (word(8 * (i + 1))) /\
         read X2 s = word_sub (word buflen) (word(8 * (i + 1))) /\
         read X3 s = table /\ read X4 s = word 256 /\
         read X7 s = word_add stackpointer (word(2 * curlen)) /\
         read X8 s = stackpointer /\ read X9 s = word curlen /\
         read (memory :> bytes (stackpointer,2 * curlen)) s =
         num_of_wordlist (curlist:int16 list) /\
         (?lis0 lis1:int16 list.
            LENGTH lis0 <= 8 /\ LENGTH lis1 <= 8 /\
            val(read X12 s:int64) = LENGTH lis0 /\
            val(read X13 s:int64) = LENGTH lis1 /\
            APPEND lis0 lis1 =
              REJ_NIBBLES_ETA4(SUB_LIST(8 * i,8) inlist) /\
            read Q16 s = word(num_of_wordlist lis0):int128 /\
            read Q17 s = word(num_of_wordlist lis1):int128) /\
         curlen < 256 /\
         nonoverlapping (stackpointer,576) (word pc,344)` THEN
   CONJ_TAC THENL
    [(* First half: SIMD compute chain — 29 steps *)
     GHOST_INTRO_TAC `nibbles1:int128` `read Q17` THEN
     ENSURES_INIT_TAC "s0" THEN
     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
     SUBGOAL_THEN `~(256 <= val(word curlen:int64))` ASSUME_TAC THENL
      [REWRITE_TAC[NOT_LE; VAL_WORD; DIMINDEX_64] THEN
       CONV_TAC NUM_REDUCE_CONV THEN
       SUBGOAL_THEN `curlen MOD 18446744073709551616 = curlen`
        SUBST1_TAC THENL
        [MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `curlen < 256` THEN
         ARITH_TAC; UNDISCH_TAC `curlen < 256` THEN ARITH_TAC];
       ALL_TAC] THEN
     RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `~(256 <= val(word curlen:int64))`]) THEN

     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [3] THEN

     ABBREV_TAC `loaded_d:int64 = read (memory :> bytes64 (word_add buf (word (8 * i)))) s3` THEN

     ARM_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (4--11) THEN
     REABBREV_TAC `nibbles0:int128 = read Q16 s11` THEN
     REABBREV_TAC `nibbles1b:int128 = read Q17 s11` THEN
     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (12--19) THEN
     RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
     RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
     RULE_ASSUM_TAC(REWRITE_RULE
      [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
     RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
     RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
     MAP_EVERY REABBREV_TAC
      [`idx0 = read X12 s19`; `idx1 = read X13 s19`] THEN
     MAP_EVERY ABBREV_TAC
      [`tab0 = read(memory :> bytes128(word_add table
                   (word(16 * val(idx0:int64))))) s19`;
       `tab1 = read(memory :> bytes128(word_add table
                   (word(16 * val(idx1:int64))))) s19`] THEN
     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (20--27) THEN
     RULE_ASSUM_TAC(REWRITE_RULE[WORD_SUBWORD_AND]) THEN
     RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
     RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
     RULE_ASSUM_TAC(REWRITE_RULE
      [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
     RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
     RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN

     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (28--29) THEN
     SUBGOAL_THEN
       `read Q16 s29 = word(num_of_wordlist
                            (REJ_NIBBLES_ETA4
                              [word_subword (loaded_d:int64) (0,8):byte;
                               word_subword loaded_d (8,8);
                               word_subword loaded_d (16,8);
                               word_subword loaded_d (24,8)])) /\
        read Q17 s29 = word(num_of_wordlist
                            (REJ_NIBBLES_ETA4
                              [word_subword (loaded_d:int64) (32,8):byte;
                               word_subword loaded_d (40,8);
                               word_subword loaded_d (48,8);
                               word_subword loaded_d (56,8)]))`
     MP_TAC THENL
      [(* Establish the 16 halfword identities inline: nibbles_k halfwords
           are word_zx of byte-nibble expressions. *)
       REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
       REWRITE_TAC(List.map (fun k -> BITBLAST_RULE
         (vsubst [mk_small_numeral k, `k:num`]
         `bit k (word_subword (word_neg (word (bitval b):16 word))
                 (0,8):8 word) <=> b`)) (0--7)) THEN
       ASM_REWRITE_TAC[] THEN
       (let prove_hw name pos byte_pos op =
          let rhs_inner = if op = "and"
            then Printf.sprintf
              "(word_and (word_subword (loaded_d:int64) (%d,8):byte) (word 15):byte)"
              byte_pos
            else Printf.sprintf
              "(word_ushr (word_subword (loaded_d:int64) (%d,8):byte) 4:byte)"
              byte_pos in
          let goal_str = Printf.sprintf
            "(word_subword (%s:int128) (%d,16)):int16 = word_zx %s :int16"
            name pos rhs_inner in
          SUBGOAL_THEN (parse_term goal_str) ASSUME_TAC THENL
           [FIRST_X_ASSUM(MP_TAC o SYM o check
              (fun th -> let c = concl th in is_eq c &&
                (try fst(dest_var(rhs c)) = name with _ -> false))) THEN
            DISCH_THEN(fun th -> SUBST1_TAC th THEN ASSUME_TAC(SYM th)) THEN
            CONV_TAC WORD_BLAST;
            ALL_TAC] in
        prove_hw "nibbles0" 0 0 "and" THEN
        prove_hw "nibbles0" 16 0 "ushr" THEN
        prove_hw "nibbles0" 32 8 "and" THEN
        prove_hw "nibbles0" 48 8 "ushr" THEN
        prove_hw "nibbles0" 64 16 "and" THEN
        prove_hw "nibbles0" 80 16 "ushr" THEN
        prove_hw "nibbles0" 96 24 "and" THEN
        prove_hw "nibbles0" 112 24 "ushr" THEN
        prove_hw "nibbles1b" 0 32 "and" THEN
        prove_hw "nibbles1b" 16 32 "ushr" THEN
        prove_hw "nibbles1b" 32 40 "and" THEN
        prove_hw "nibbles1b" 48 40 "ushr" THEN
        prove_hw "nibbles1b" 64 48 "and" THEN
        prove_hw "nibbles1b" 80 48 "ushr" THEN
        prove_hw "nibbles1b" 96 56 "and" THEN
        prove_hw "nibbles1b" 112 56 "ushr") THEN
       (fun (asl, w) ->
          let halfword_hyps =
            List.filter (fun (_,th) ->
              let c = concl th in
              is_eq c &&
              (try let l = lhand c in
                   match l with
                   | Comb(Comb(Const("word_subword",_), v),
                          Comb(Comb(Const(",",_), _), len_tm)) ->
                       is_var v &&
                       (let nm = fst(dest_var v) in
                        nm = "nibbles0" || nm = "nibbles1b") &&
                       (try dest_small_numeral len_tm = 16 with _ -> false)
                   | _ -> false
               with _ -> false)) asl in
          let byte_lemmas = BYTE_SPLIT_AND @ BYTE_SPLIT_USHR in
          let new_facts = List.concat (List.map (fun (_, h) ->
            List.concat (List.map (fun lem ->
              try CONJUNCTS(MATCH_MP lem h)
              with _ -> []) byte_lemmas)) halfword_hyps) in
          (MAP_EVERY ASSUME_TAC new_facts) (asl, w)) THEN
       UNDISCH_TAC
        `read(memory :> bytes(table,4096)) s29 =
         num_of_wordlist mldsa_rej_uniform_eta_table` THEN
       REPLICATE_TAC 4
        (GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
              [GSYM NUM_OF_PAIR_WORDLIST]) THEN
       REWRITE_TAC[mldsa_rej_uniform_eta_table; pair_wordlist] THEN
       CONV_TAC WORD_REDUCE_CONV THEN
       CONV_TAC(LAND_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN
       REWRITE_TAC[GSYM BYTES128_WBYTES] THEN REPEAT STRIP_TAC THEN
       DISCARD_MATCHING_ASSUMPTIONS
        [`read Q24 s = x`; `read Q25 s = x`] THEN
       REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
         (fun th -> is_var(rhs(concl th)) &&
                    let n = fst(dest_var(rhs(concl th))) in
                    n = "tab0" || n = "tab1"))) THEN
       DISCARD_MATCHING_ASSUMPTIONS
        [`read X12 s = x`; `read X13 s = x`] THEN
       REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
         (fun th -> is_var(rhs(concl th)) &&
                    let n = fst(dest_var(rhs(concl th))) in
                    n = "idx0" || n = "idx1"))) THEN
       ASM_REWRITE_TAC[] THEN
       DISCARD_MATCHING_ASSUMPTIONS
        [`read Q16 s = x`; `read Q17 s = x`] THEN
       REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THEN
       REWRITE_TAC[FILTER] THEN
       REWRITE_TAC[VAL_WORD_ZX_BYTE16; BYTE_AND_15_MOD; BYTE_USHR4_DIV;
                   VAL_WORD_NIBBLE_LT] THEN
       REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
       REWRITE_TAC[BITVAL_CLAUSES] THEN
       CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
       CONV_TAC NUM_REDUCE_CONV THEN
       REWRITE_TAC[WORD_ADD_0] THEN
       ASM_REWRITE_TAC[] THEN
       CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
       CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
       CONV_TAC NUM_REDUCE_CONV THEN
       REWRITE_TAC[num_of_wordlist; MULT_CLAUSES; ADD_CLAUSES] THEN
       CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
       RULE_ASSUM_TAC(REWRITE_RULE[BYTE_AND_15_MOD; BYTE_USHR4_DIV;
                                   VAL_WORD_ZX_BYTE16; VAL_WORD_NIBBLE_LT]) THEN
       ASM_REWRITE_TAC[] THEN
       REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
       CONV_TAC NUM_REDUCE_CONV THEN
       REWRITE_TAC[VAL_BYTE_NIB_MOD_65536] THEN
       CONV_TAC WORD_BLAST;
       STRIP_TAC] THEN
     DISCARD_MATCHING_ASSUMPTIONS
      [`read Q16 s = word_join (x:int64) (y:int64):int128`;
       `read Q17 s = word_join (x:int64) (y:int64):int128`] THEN
     ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
     ASM_REWRITE_TAC[WORD_SUBWORD_AND] THEN
     CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
     CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
     REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; ADD_CLAUSES] THEN
     REWRITE_TAC[POPCOUNT_AND_POWERS] THEN
     REPEAT CONJ_TAC THEN
     TRY(CONV_TAC WORD_RULE) THEN
     TRY(NONOVERLAPPING_TAC) THEN
     TRY(REWRITE_TAC[UADDLV_BOUND_LEMMA] THEN NO_TAC) THEN
     TRY(ASM_REWRITE_TAC[] THEN NO_TAC) THEN
     TRY(ASM_ARITH_TAC) THEN
     EXISTS_TAC
       `REJ_NIBBLES_ETA4
          [word_subword (loaded_d:int64) (0,8):byte;
           word_subword loaded_d (8,8);
           word_subword loaded_d (16,8);
           word_subword loaded_d (24,8)]` THEN
     EXISTS_TAC
       `REJ_NIBBLES_ETA4
          [word_subword (loaded_d:int64) (32,8):byte;
           word_subword loaded_d (40,8);
           word_subword loaded_d (48,8);
           word_subword loaded_d (56,8)]` THEN
     REWRITE_TAC[REJ_NIBBLES_ETA4_LENGTH_4] THEN
     MP_TAC(SPECL [`buf:int64`; `buflen:num`; `inlist:byte list`;
                   `i:num`; `s29:armstate`] SUB_LIST_8_BYTES_FROM_INT64) THEN
     ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
     ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
     ASM_REWRITE_TAC[REJ_NIBBLES_ETA4_SPLIT_8] THEN
     REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
     REWRITE_TAC(List.map (fun k -> BITBLAST_RULE
       (vsubst [mk_small_numeral k, `k:num`]
       `bit k (word_subword (word_neg (word (bitval b):16 word))
               (0,8):8 word) <=> b`)) (0--7)) THEN
     ASM_REWRITE_TAC[] THEN
     (let prove_hw name pos byte_pos op =
        let rhs_inner = if op = "and"
          then Printf.sprintf
            "(word_and (word_subword (loaded_d:int64) (%d,8):byte) (word 15):byte)"
            byte_pos
          else Printf.sprintf
            "(word_ushr (word_subword (loaded_d:int64) (%d,8):byte) 4:byte)"
            byte_pos in
        let goal_str = Printf.sprintf
          "(word_subword (%s:int128) (%d,16)):int16 = word_zx %s :int16"
          name pos rhs_inner in
        SUBGOAL_THEN (parse_term goal_str) ASSUME_TAC THENL
         [FIRST_X_ASSUM(MP_TAC o SYM o check
            (fun th -> let c = concl th in is_eq c &&
              (try fst(dest_var(rhs c)) = name with _ -> false))) THEN
          DISCH_THEN(fun th -> SUBST1_TAC th THEN ASSUME_TAC(SYM th)) THEN
          CONV_TAC WORD_BLAST;
          ALL_TAC] in
      prove_hw "nibbles0" 0 0 "and" THEN
      prove_hw "nibbles0" 16 0 "ushr" THEN
      prove_hw "nibbles0" 32 8 "and" THEN
      prove_hw "nibbles0" 48 8 "ushr" THEN
      prove_hw "nibbles0" 64 16 "and" THEN
      prove_hw "nibbles0" 80 16 "ushr" THEN
      prove_hw "nibbles0" 96 24 "and" THEN
      prove_hw "nibbles0" 112 24 "ushr" THEN
      prove_hw "nibbles1b" 0 32 "and" THEN
      prove_hw "nibbles1b" 16 32 "ushr" THEN
      prove_hw "nibbles1b" 32 40 "and" THEN
      prove_hw "nibbles1b" 48 40 "ushr" THEN
      prove_hw "nibbles1b" 64 48 "and" THEN
      prove_hw "nibbles1b" 80 48 "ushr" THEN
      prove_hw "nibbles1b" 96 56 "and" THEN
      prove_hw "nibbles1b" 112 56 "ushr") THEN

     REPEAT CONJ_TAC THEN
     FIRST
      [(* X12/X13 val-to-LENGTH: COUNT_BRIDGE_ABSTRACT_4 on nibbles0 *)
       MP_TAC(SPECL
        [`nibbles0:int128`;
         `word_subword (loaded_d:int64) (0,8):byte`;
         `word_subword (loaded_d:int64) (8,8):byte`;
         `word_subword (loaded_d:int64) (16,8):byte`;
         `word_subword (loaded_d:int64) (24,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
       ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
       DISCH_THEN SUBST1_TAC THEN REFL_TAC;
       MP_TAC(SPECL
        [`nibbles1b:int128`;
         `word_subword (loaded_d:int64) (32,8):byte`;
         `word_subword (loaded_d:int64) (40,8):byte`;
         `word_subword (loaded_d:int64) (48,8):byte`;
         `word_subword (loaded_d:int64) (56,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
       ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
       DISCH_THEN SUBST1_TAC THEN REFL_TAC;
       FIRST_ASSUM(fun my_hyp ->
         FIRST_ASSUM(fun arm_hyp ->
           try ACCEPT_TAC(TRANS (SYM arm_hyp) my_hyp)
           with _ -> NO_TAC))];
     ALL_TAC] THEN

   ENSURES_INIT_TAC "s0" THEN

   FIRST_X_ASSUM(X_CHOOSE_THEN `lis0:int16 list` MP_TAC o check
     (fun th -> try fst(dest_var(fst(dest_exists(concl th)))) = "lis0"
                with _ -> false)) THEN
   DISCH_THEN(X_CHOOSE_THEN `lis1:int16 list` STRIP_ASSUME_TAC) THEN
   ABBREV_TAC `len0 = LENGTH(lis0:int16 list)` THEN
   ABBREV_TAC `len1 = LENGTH(lis1:int16 list)` THEN

   SUBGOAL_THEN `val(read X12 s0:int64) = len0 /\ val(read X13 s0:int64) = len1`
     STRIP_ASSUME_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [1] THEN

   SUBGOAL_THEN
    `read (memory :> bytes (stackpointer, 2 * (curlen + len0))) s1 =
     num_of_wordlist(APPEND curlist lis0:int16 list)`
   ASSUME_TAC THENL
    [REWRITE_TAC[LEFT_ADD_DISTRIB] THEN
     SUBGOAL_THEN `LENGTH(curlist:int16 list) = curlen` ASSUME_TAC THENL
      [EXPAND_TAC "curlen" THEN REFL_TAC; ALL_TAC] THEN
     W(MP_TAC o PART_MATCH (lhand o rand)
       BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
     ANTS_TAC THENL
      [REWRITE_TAC[DIMINDEX_16] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC;
       ALL_TAC] THEN
     DISCH_THEN SUBST1_TAC THEN
     CONJ_TAC THENL
      [ASM_REWRITE_TAC[];
       SUBGOAL_THEN
        `read (memory :> bytes128
               (word_add stackpointer (word (2 * curlen)))) s1 =
         word(num_of_wordlist(lis0:int16 list)):int128`
       MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
       DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
       REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                   VAL_READ_WBYTES;
                   DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
       SUBGOAL_THEN `2 * len0 = MIN 16 (2 * len0)` SUBST1_TAC THENL
        [UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC;
         REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
       DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
       REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
       MATCH_MP_TAC MOD_LT THEN
       MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
       ASM_REWRITE_TAC[DIMINDEX_16] THEN
       UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC];
     ALL_TAC] THEN
   SUBGOAL_THEN `read X12 s1:int64 = word len0` ASSUME_TAC THENL
    [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
     CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
     UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
   SUBGOAL_THEN `read X13 s1:int64 = word len1` ASSUME_TAC THENL
    [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
     CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
     UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
   ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s2" THEN
   FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1]) THEN
   ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
   SUBGOAL_THEN
    `nonoverlapping (word_add stackpointer (word(2 * (curlen + len0))):int64,
                     16) (word pc:int64, 344)`
   ASSUME_TAC THENL [NONOVERLAPPING_TAC; ALL_TAC] THEN
   SUBGOAL_THEN `val(word len0:int64) = len0` ASSUME_TAC THENL
    [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
     UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
   RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word len0:int64) = len0`]) THEN

   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [3] THEN

   RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word len0:int64) = len0`]) THEN

   SUBGOAL_THEN
    `read (memory :> bytes (stackpointer, 2 * ((curlen + len0) + len1))) s3 =
     num_of_wordlist(APPEND (APPEND curlist lis0) lis1:int16 list)`
   ASSUME_TAC THENL
    [REWRITE_TAC[LEFT_ADD_DISTRIB] THEN
     SUBGOAL_THEN
       `LENGTH(APPEND curlist lis0:int16 list) = curlen + len0`
     ASSUME_TAC THENL
      [REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
     W(MP_TAC o PART_MATCH (lhand o rand)
       BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
     ANTS_TAC THENL
      [REWRITE_TAC[DIMINDEX_16] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC;
       ALL_TAC] THEN
     DISCH_THEN SUBST1_TAC THEN

     SUBGOAL_THEN
       `word_add stackpointer (word (2 * curlen + 2 * len0):int64) =
        word_add stackpointer (word (2 * (curlen + len0)))`
      (fun th -> REWRITE_TAC[th]) THENL
      [CONV_TAC WORD_RULE; ALL_TAC] THEN
     SUBGOAL_THEN `2 * curlen + 2 * len0 = 2 * (curlen + len0)`
      SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
     CONJ_TAC THENL
      [ASM_REWRITE_TAC[];
       SUBGOAL_THEN
        `read (memory :> bytes128
               (word_add stackpointer (word (2 * (curlen + len0))))) s3 =
         word(num_of_wordlist(lis1:int16 list)):int128`
       MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
       DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
       REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                   VAL_READ_WBYTES;
                   DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
       SUBGOAL_THEN `2 * len1 = MIN 16 (2 * len1)` SUBST1_TAC THENL
        [UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC;
         REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
       DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
       REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
       MATCH_MP_TAC MOD_LT THEN
       MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
       ASM_REWRITE_TAC[DIMINDEX_16] THEN
       UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC];
     ALL_TAC] THEN
   ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s4" THEN
   FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1]) THEN
   ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (5--6) THEN
   ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
   CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
   SUBGOAL_THEN `8 * (i + 1) <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
    [ASM_REWRITE_TAC[] THEN
     MP_TAC(ASSUME `8 * (i + 1) <= buflen`) THEN ARITH_TAC;
     ALL_TAC] THEN
   MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP) THEN
   ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
   ABBREV_TAC `newbatch = REJ_NIBBLES_ETA4(SUB_LIST(8*i, 8) inlist):int16 list` THEN

   SUBGOAL_THEN `APPEND (lis0:int16 list) lis1 = newbatch` ASSUME_TAC THENL
    [EXPAND_TAC "newbatch" THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
   SUBGOAL_THEN `LENGTH(newbatch:int16 list) = len0 + len1` ASSUME_TAC THENL
    [UNDISCH_TAC `APPEND (lis0:int16 list) lis1 = newbatch` THEN
     DISCH_THEN(SUBST1_TAC o SYM) THEN
     REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN

   SUBGOAL_THEN `val(word len0:int64) = len0 /\ val(word len1:int64) = len1`
     STRIP_ASSUME_TAC THENL
    [CONJ_TAC THEN MATCH_MP_TAC VAL_WORD_EQ THEN
     REWRITE_TAC[DIMINDEX_64] THENL
      [UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC;
       UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC];
     ALL_TAC] THEN
   REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[] THEN
   REPEAT CONJ_TAC THEN
   TRY(CONV_TAC WORD_RULE) THEN
   TRY(AP_TERM_TAC THEN AP_TERM_TAC THEN
       ASM_REWRITE_TAC[] THEN ARITH_TAC) THEN
   SUBGOAL_THEN
     `2 * (curlen + len0 + len1) = 2 * ((curlen + len0) + len1)`
    SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
   SUBGOAL_THEN
     `APPEND curlist (newbatch:int16 list) =
      APPEND (APPEND curlist lis0) lis1`
    SUBST1_TAC THENL
     [UNDISCH_TAC `APPEND (lis0:int16 list) lis1 = newbatch` THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN
      REWRITE_TAC[APPEND_ASSOC]; ALL_TAC] THEN
   ASM_REWRITE_TAC[];

   X_GEN_TAC `i:num` THEN STRIP_TAC THEN
   CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
   ENSURES_INIT_TAC "s0" THEN
   SUBGOAL_THEN `8 <= val(word_sub (word buflen:int64) (word(8 * i)))`
   ASSUME_TAC THENL
    [SUBGOAL_THEN `8 * (i + 1) <= buflen` ASSUME_TAC THENL
      [FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
       UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
     SUBGOAL_THEN `8 * i < 2 EXP 64` ASSUME_TAC THENL
      [UNDISCH_TAC `buflen < 2 EXP 64` THEN
       UNDISCH_TAC `8 * (i + 1) <= buflen` THEN ARITH_TAC; ALL_TAC] THEN
     VAL_INT64_TAC `8 * i` THEN ASM_REWRITE_TAC[VAL_WORD_SUB_CASES] THEN
     UNDISCH_TAC `8 * (i + 1) <= buflen` THEN ARITH_TAC; ALL_TAC] THEN
   ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
   ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];

   CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
   ABBREV_TAC `niblen = LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)` THEN
   SUBGOAL_THEN `niblen < 272` ASSUME_TAC THENL
    [EXPAND_TAC "niblen" THEN
     MATCH_MP_TAC NIBLEN_BOUND_FROM_WOP THEN
     ASM_REWRITE_TAC[] THEN
     X_GEN_TAC `mm:num` THEN DISCH_TAC THEN
     FIRST_X_ASSUM(MP_TAC o SPEC `mm:num`) THEN
     ASM_REWRITE_TAC[];
     ALL_TAC] THEN
   VAL_INT64_TAC `niblen:num` THEN
   ASM_CASES_TAC `256 <= niblen` THENL
    [(* Case: 256 <= niblen — enough samples *)
     ASM_CASES_TAC `8 <= val(word_sub (word buflen:int64) (word(8 * N)))` THENL
      [(* Subcase: X2 >= 8 — back edge branches to pc+108, then CMP X9>=X4 *)

       ENSURES_SEQUENCE_TAC `pc + 108`
        `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
             read PC s = word(pc + 108) /\
             read X0 s = res /\ read X4 s = word 256 /\
             read X8 s = stackpointer /\
             read Q7 s = word 20769504351625144638033088116686852 /\
             read X9 s = word niblen /\
             read (memory :> bytes (stackpointer,2 * niblen)) s =
             num_of_wordlist (REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list) /\
             ALL (nonoverlapping (res,1024)) [(word pc,344); (stackpointer,576)]` THEN
       CONJ_TAC THENL
        [(* pc+248 -> pc+108: CMP X2,8; BCS back *)
         ENSURES_INIT_TAC "s0" THEN
         ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
         ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
         REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
         CONJ_TAC THENL [NONOVERLAPPING_TAC; NONOVERLAPPING_TAC];

         ENSURES_INIT_TAC "s0" THEN
         SUBGOAL_THEN `256 <= val(word niblen:int64)` ASSUME_TAC THENL
          [REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
           SUBGOAL_THEN `niblen MOD 2 EXP 64 = niblen` SUBST1_TAC THENL
            [MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `niblen < 272` THEN
             ARITH_TAC;
             ASM_REWRITE_TAC[]];
           ALL_TAC] THEN
         ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
         ENSURES_FINAL_STATE_TAC THEN
         REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
         EXISTS_TAC `N:num` THEN
         CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
         UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
         ARITH_TAC];

       ENSURES_INIT_TAC "s0" THEN
       ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
       ENSURES_FINAL_STATE_TAC THEN
       REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
       EXISTS_TAC `N:num` THEN
       CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
       UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
       ARITH_TAC];

     SUBGOAL_THEN `buflen < 8 * (N + 1)` ASSUME_TAC THENL
      [FIRST_X_ASSUM(DISJ_CASES_THEN ASSUME_TAC) THEN ASM_REWRITE_TAC[] THEN
       UNDISCH_TAC `~(256 <= niblen)` THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
     SUBGOAL_THEN `8 * N <= buflen` ASSUME_TAC THENL
      [FIRST_X_ASSUM(MP_TAC o SPEC `N - 1`) THEN
       UNDISCH_TAC `0 < N` THEN ARITH_TAC; ALL_TAC] THEN
     SUBGOAL_THEN `8 * N = buflen` ASSUME_TAC THENL
      [MP_TAC(ASSUME `8 divides buflen`) THEN
       REWRITE_TAC[divides] THEN
       DISCH_THEN(X_CHOOSE_TAC `d:num`) THEN ASM_REWRITE_TAC[] THEN
       UNDISCH_TAC `buflen < 8 * (N + 1)` THEN ASM_REWRITE_TAC[] THEN
       UNDISCH_TAC `8 * N <= buflen` THEN ASM_REWRITE_TAC[] THEN
       REWRITE_TAC[GSYM MULT_ASSOC; LT_MULT_LCANCEL; LE_MULT_LCANCEL] THEN
       CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC; ALL_TAC] THEN
     SUBGOAL_THEN `SUB_LIST(0,buflen) inlist = inlist:byte list`
       (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th])) THENL
      [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_REWRITE_TAC[LE_REFL]; ALL_TAC] THEN
     ASM_REWRITE_TAC[] THEN
     SUBGOAL_THEN `~(8 <= val(word_sub (word buflen:int64) (word buflen)))`
       ASSUME_TAC THENL
      [REWRITE_TAC[WORD_SUB_REFL; VAL_WORD_0] THEN ARITH_TAC; ALL_TAC] THEN
     ENSURES_INIT_TAC "s0" THEN
     ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
     ENSURES_FINAL_STATE_TAC THEN
     REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
     EXISTS_TAC `N:num` THEN
     CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
     CONJ_TAC THENL
      [UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
       ARITH_TAC; ALL_TAC] THEN
     CONJ_TAC THENL
      [DISJ1_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
     ASM_REWRITE_TAC[]]]);;


(* ------------------------------------------------------------------------- *)
(* Strengthened correctness: per-coefficient bound matching CBMC contract     *)
(* ensures(array_abs_bound(r, 0, return_value, MLDSA_ETA + 1)).              *)
(* ------------------------------------------------------------------------- *)

let REJ_SAMPLE_ETA4_ELEMENT_BOUND = BITBLAST_RULE
 `!x:int16. val x < 9
    ==> ival(word_sx(word_sub (word 4:int16) x):int32) < &5 /\
        -- &5 < ival(word_sx(word_sub (word 4:int16) x):int32)`;;

let REJ_SAMPLE_ETA4_ALL_BOUND = prove
 (`!l:byte list i. i < LENGTH(REJ_SAMPLE_ETA4_BYTES l)
    ==> ival(EL i (REJ_SAMPLE_ETA4_BYTES l):int32) < &5 /\
        -- &5 < ival(EL i (REJ_SAMPLE_ETA4_BYTES l):int32)`,
  REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; LENGTH_MAP] THEN
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN
    `EL i (MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32)
              (REJ_NIBBLES_ETA4 (l:byte list))) =
     word_sx(word_sub (word 4) (EL i (REJ_NIBBLES_ETA4 l)))` SUBST1_TAC THENL
   [MATCH_MP_TAC EL_MAP THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  MATCH_MP_TAC REJ_SAMPLE_ETA4_ELEMENT_BOUND THEN
  MP_TAC(ISPECL [`\x:int16. val x < 9`;
                 `NIBBLES_OF_BYTES(l:byte list)`; `i:num`]
    FILTER_EL_SATISFIES) THEN
  REWRITE_TAC[REJ_NIBBLES_ETA4] THEN BETA_TAC THEN
  DISCH_THEN MATCH_MP_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[REJ_NIBBLES_ETA4]) THEN ASM_REWRITE_TAC[]);;

(* Bridge from EL i of the SUB_LIST(0,256) prefix to EL i of the full         *)
(* REJ_SAMPLE_ETA4_BYTES list, used to apply REJ_SAMPLE_ETA4_ALL_BOUND in the       *)
(* subroutine postcondition.                                                  *)

let EL_REJ_SAMPLE_ETA4_SUB_LIST_256 = prove
 (`!l:byte list i.
        i < LENGTH(SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES l):int32 list)
        ==> EL i (SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES l):int32 list) =
            EL i (REJ_SAMPLE_ETA4_BYTES l)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN DISCH_TAC THEN
  MP_TAC(ISPECL
    [`REJ_SAMPLE_ETA4_BYTES (l:byte list)`; `0`; `256`; `i:num`]
    EL_SUB_LIST) THEN
  REWRITE_TAC[ADD_CLAUSES] THEN
  ANTS_TAC THENL
   [UNDISCH_TAC `i < MIN 256 (LENGTH(REJ_SAMPLE_ETA4_BYTES (l:byte list)))` THEN
    ARITH_TAC;
    DISCH_THEN SUBST1_TAC THEN REFL_TAC]);;

(* ------------------------------------------------------------------------- *)
(* Subroutine correctness with array_abs_bound matching CBMC contract        *)
(* ensures(array_abs_bound(r, 0, return_value, MLDSA_ETA + 1)) for eta = 4.  *)
(* ------------------------------------------------------------------------- *)

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/aarch64/src/arith_native_aarch64.h *)

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_CORRECT = prove
 (`!res buf buflen table (inlist:(4 word) list) pc stackpointer returnaddress.
        8 divides val buflen /\
        8 <= val buflen /\
        LENGTH inlist = 2 * val buflen /\
        ALL (nonoverlapping (word_sub stackpointer (word 576),576))
            [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
             (buf,val buflen); (table,4096)] /\
        ALL (nonoverlapping (res,1024))
            [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
             (word_sub stackpointer (word 576),576)]
        ==> ensures arm
             (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                  read PC s = word pc /\
                  read SP s = stackpointer /\
                  read X30 s = returnaddress /\
                  C_ARGUMENTS [res;buf;buflen;table] s /\
                  read(memory :> bytes(table,4096)) s =
                  num_of_wordlist mldsa_rej_uniform_eta_table /\
                  read(memory :> bytes(buf,val buflen)) s =
                  num_of_wordlist inlist)
             (\s. read PC s = returnaddress /\
                  let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4 inlist) in
                  let outlen = LENGTH outlist in
                  outlen <= 256 /\
                  C_RETURN s = word outlen /\
                  read(memory :> bytes(res,4 * outlen)) s =
                  num_of_wordlist outlist /\
                  (!i. i < outlen
                       ==> ival(EL i outlist:int32) < &5 /\
                           -- &5 < ival(EL i outlist:int32)))
             (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(res,1024);
                         memory :> bytes(word_sub stackpointer (word 576),576)])`,
  (* See eta2 _SUBROUTINE_CORRECT for the bridge rationale. *)
  REPEAT GEN_TAC THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  MP_TAC(ISPEC `inlist:(4 word) list` BYTES_TO_NIBBLES_SURJ) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[EVEN_EXISTS] THEN EXISTS_TAC `val(buflen:int64)` THEN
    ASM_REWRITE_TAC[]; ALL_TAC] THEN
  DISCH_THEN(X_CHOOSE_THEN `bs:byte list` STRIP_ASSUME_TAC) THEN
  UNDISCH_THEN `BYTES_TO_NIBBLES (bs:byte list) = inlist`
    (SUBST_ALL_TAC o SYM) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[LENGTH_BYTES_TO_NIBBLES;
                              ARITH_RULE `2 * a = 2 * b <=> a = b`]) THEN
  REWRITE_TAC[NUM_OF_BYTES_TO_NIBBLES; GSYM REJ_SAMPLE_ETA4_BYTES_EQ] THEN
  MP_TAC(SPECL
   [`res:int64`; `buf:int64`; `buflen:int64`; `table:int64`;
    `bs:byte list`; `pc:num`; `stackpointer:int64`; `returnaddress:int64`]
   (prove
    (`!res buf buflen table (inlist:byte list) pc stackpointer returnaddress.
        8 divides val buflen /\
        8 <= val buflen /\
        LENGTH inlist = val buflen /\
        ALL (nonoverlapping (word_sub stackpointer (word 576),576))
            [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
             (buf,val buflen); (table,4096)] /\
        ALL (nonoverlapping (res,1024))
            [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
             (word_sub stackpointer (word 576),576)]
        ==> ensures arm
             (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                  read PC s = word pc /\
                  read SP s = stackpointer /\
                  read X30 s = returnaddress /\
                  C_ARGUMENTS [res;buf;buflen;table] s /\
                  read(memory :> bytes(table,4096)) s =
                  num_of_wordlist mldsa_rej_uniform_eta_table /\
                  read(memory :> bytes(buf,val buflen)) s =
                  num_of_wordlist inlist)
             (\s. read PC s = returnaddress /\
                  let outlist = SUB_LIST(0,256)
                      (REJ_SAMPLE_ETA4_BYTES inlist) in
                  let outlen = LENGTH outlist in
                  outlen <= 256 /\
                  C_RETURN s = word outlen /\
                  read(memory :> bytes(res,4 * outlen)) s =
                  num_of_wordlist outlist /\
                  (!i. i < outlen
                       ==> ival(EL i outlist:int32) < &5 /\
                           -- &5 < ival(EL i outlist:int32)))
             (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(res,1024);
                         memory :> bytes(word_sub stackpointer (word 576),576)])`,
     ARM_ADD_RETURN_STACK_TAC
       ~pre_post_nsteps:(1,1)
       MLDSA_REJ_UNIFORM_ETA4_EXEC
       (REWRITE_RULE[fst MLDSA_REJ_UNIFORM_ETA4_EXEC]
          (CONV_RULE LENGTH_SIMPLIFY_CONV MLDSA_REJ_UNIFORM_ETA4_CORRECT))
       `[]:((armstate,int64)component)list` 576 THEN
     REPEAT STRIP_TAC THEN
     POP_ASSUM_LIST(MP_TAC o end_itlist CONJ) THEN
     CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
     STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
     CONJ_TAC THENL
      [REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN ARITH_TAC; ALL_TAC] THEN
     X_GEN_TAC `i:num` THEN DISCH_TAC THEN
     SUBGOAL_THEN
       `EL i (SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES (inlist:byte list)):int32 list) =
        EL i (REJ_SAMPLE_ETA4_BYTES inlist)`
      SUBST1_TAC THENL
      [MATCH_MP_TAC EL_REJ_SAMPLE_ETA4_SUB_LIST_256 THEN ASM_REWRITE_TAC[];
       ALL_TAC] THEN
     MATCH_MP_TAC REJ_SAMPLE_ETA4_ALL_BOUND THEN
     UNDISCH_TAC `i < LENGTH(SUB_LIST(0,256)
       (REJ_SAMPLE_ETA4_BYTES (inlist:byte list)):int32 list)` THEN
     REWRITE_TAC[LENGTH_SUB_LIST; SUB_0] THEN ARITH_TAC))) THEN
  ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[]);;


(* ========================================================================= *)
(* Memory Safety Proof                                                       *)
(*                                                                           *)
(* The safety specification below differs in shape from the ones used in     *)
(* most other HOL-Light proofs, which consolidate memory safety and          *)
(* secret-independent timing into a single theorem. Here we prove memory     *)
(* safety on its own: the kernel emits _some_ list of microarchitectural     *)
(* events whose memory accesses fall within the expected bounds.             *)
(*                                                                           *)
(* Secret-independent timing is proven separately below (see "Constant-time  *)
(* rejection sampling"): rather than assert full data-obliviousness, the     *)
(* event-generating function there takes the reject bitmap -- one accept/    *)
(* reject bit per candidate nibble -- as its data argument, declassifying    *)
(* which coefficients are in bounds vs. out of bounds, but not their values. *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/consttime.ml";;
needs "mldsa_native/aarch64/proofs/subroutine_signatures.ml";;

(* Helper: discharge the memsafe postcondition
     exists e2. read events s = APPEND e2 e /\ memaccess_inbounds e2 R W
   after symbolic simulation, using accumulated events from the invariant. *)
let DISCHARGE_MEMSAFE_TAC:tactic =
  SAFE_META_EXISTS_TAC allowed_vars_e THEN
  CONJ_TAC THENL [ EXISTS_E2_TAC allowed_vars_e; ALL_TAC ] THEN
  DISCHARGE_MEMACCESS_INBOUNDS_TAC;;

(* Like SIMPLE_ARITH_TAC but allows `val` in assumptions since
   contained_modulo bounds may involve val terms. *)
let (MEMSAFE_ARITH_TAC:tactic) =
  let numty = `:num` in
  let is_num_relop tm =
    exists (fun op -> is_binary op tm &&
                      (let x,_ = dest_binary op tm in type_of x = numty))
           ["=";"<";"<=";">";">="]
  and avoiders = ["lowdigits"; "highdigits"; "bigdigit";
                  "read"; "write"; "word"] in
  let avoiderp tm =
    match tm with Const(n,_) -> mem n avoiders | _ -> false in
  let filtered tm =
    (is_num_relop tm || (is_neg tm && is_num_relop (dest_neg tm))) &&
    not(can (find_term avoiderp) tm) in
  let tweak = GEN_REWRITE_RULE TRY_CONV [ARITH_RULE `~(n = 0) <=> 1 <= n`] in
  W(fun (asl,w) ->
    let asl' = filter (fun (_,th) -> filtered(concl th)) asl in
    MAP_EVERY (MP_TAC o tweak o snd) asl' THEN CONV_TAC ARITH_RULE);;

(* ASM-aware version of CONTAINED_TAC for loop-body proofs with
   symbolic memory address bounds. *)
let CONTAINED_ASM_TAC =
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  GEN_REWRITE_TAC (BINOP_CONV o LAND_CONV o LAND_CONV o TOP_DEPTH_CONV)
   [VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(BINOP_CONV(LAND_CONV MOD_DOWN_CONV)) THEN
  GEN_REWRITE_TAC I [CONTAINED_MODULO_MOD2] THEN
  ((GEN_REWRITE_TAC I [CONTAINED_MODULO_REFL] THEN
    MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
    MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_SIMPLE THEN MEMSAFE_ARITH_TAC));;

(* ASM-aware version of DISCHARGE_MEMSAFE_TAC for loop-body proofs. *)
let DISCHARGE_MEMSAFE_ASM_TAC:tactic =
  SAFE_META_EXISTS_TAC allowed_vars_e THEN
  CONJ_TAC THENL [ EXISTS_E2_TAC allowed_vars_e; ALL_TAC ] THEN
  REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
    REPEAT CONJ_TAC THEN
    TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                CONTAINED_ASM_TAC) THEN NO_TAC);
    REWRITE_TAC[APPEND; APPEND_NIL] THEN
    FIRST_ASSUM ACCEPT_TAC];;

(* Strip an existential `?e_acc. read events s = APPEND e_acc e /\ ...` *)
let STRIP_EXISTS_ASSUM_TAC =
  FIRST_X_ASSUM(CHOOSE_THEN
   (CONJUNCTS_THEN2 ASSUME_TAC (ASSUME_TAC)));;

(* ========================================================================= *)
(* The main memory safety theorem.                                           *)
(* ========================================================================= *)


let MLDSA_REJ_UNIFORM_ETA4_MEMSAFE = prove
 (`!res buf buflen table (inlist:byte list) pc e stackpointer.
      8 divides val buflen /\
      8 <= val buflen /\
      LENGTH inlist = val buflen /\
      ALL (nonoverlapping (stackpointer,576))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (buf,val buflen); (table,4096)] /\
      ALL (nonoverlapping (res,1024))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (stackpointer,576)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word(pc + MLDSA_REJ_UNIFORM_ETA4_CORE_START) /\
                read SP s = stackpointer /\
                C_ARGUMENTS [res;buf;buflen;table] s /\
                read(memory :> bytes(table,4096)) s =
                num_of_wordlist mldsa_rej_uniform_eta_table /\
                read(memory :> bytes(buf,val buflen)) s =
                num_of_wordlist inlist /\
                read events s = e)
           (\s. read PC s = word(pc + MLDSA_REJ_UNIFORM_ETA4_CORE_END) /\
                (exists e2.
                     read events s = APPEND e2 e /\
                     memaccess_inbounds e2
                       [buf,val buflen; table,4096; stackpointer,576]
                       [stackpointer,576; res,1024]))
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes(res,1024);
                       memory :> bytes(stackpointer,576)])`,
  (* ---- Phase 0: setup ---- *)
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  REWRITE_TAC[fst MLDSA_REJ_UNIFORM_ETA4_EXEC;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
    C_ARGUMENTS; ALL; C_RETURN] THEN
  MAP_EVERY X_GEN_TAC [`res:int64`; `buf:int64`] THEN
  W64_GEN_TAC `buflen:num` THEN
  MAP_EVERY X_GEN_TAC
   [`table:int64`; `inlist:byte list`; `pc:num`;
    `e:(uarch_event)list`; `stackpointer:int64`] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

  (* ---- Intermediate sequence point at pc+256 ---- *)
  ENSURES_SEQUENCE_TAC `pc + 256`
   `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
        read PC s = word(pc + 256) /\
        read X0 s = res /\ read X4 s = word 256 /\
        read X8 s = stackpointer /\
        read Q7 s = word 20769504351625144638033088116686852 /\
        ALL (nonoverlapping (res,1024)) [(word pc,344); (stackpointer,576)] /\
        ?n. let niblist = REJ_NIBBLES_ETA4(SUB_LIST(0,8*n) inlist) in
            let niblen = LENGTH niblist in
            niblen < 272 /\
            (buflen < 8 * (n + 1) \/ 256 <= niblen) /\
            read X9 s = word niblen /\
            read (memory :> bytes (stackpointer,2 * niblen)) s =
            num_of_wordlist niblist /\
            (exists e_acc.
              read events s = APPEND e_acc e /\
              memaccess_inbounds e_acc
                [buf,buflen; table,4096; stackpointer,576]
                [stackpointer,576; res,1024])` THEN
  CONJ_TAC THENL
   [ALL_TAC;

    (* ---- Writeback branch (pc+256 -> pc+336) ----
       Skip BIGNUM_LDIGITIZE_TAC and MEMORY_128_FROM_64_TAC: they introduce
       ~100 stack bytes64/bytes128 reads needed for CORRECT to derive nibble
       values, but irrelevant to memory safety (only events + PC + memaccess
       bounds matter). Keeping them inflates per-step ARM_STEPS_TAC cost. *)
    ENSURES_INIT_TAC "s0" THEN
    FIRST_X_ASSUM(X_CHOOSE_THEN `nn:num` MP_TAC) THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    ABBREV_TAC `niblist = REJ_NIBBLES_ETA4
      (SUB_LIST(0,8*nn) inlist):int16 list` THEN
    ABBREV_TAC `niblen = LENGTH(niblist:int16 list)` THEN
    DISCH_THEN(fun th -> MAP_EVERY ASSUME_TAC (CONJUNCTS th)) THEN
    STRIP_EXISTS_ASSUM_TAC THEN
    SUBGOAL_THEN `val(word niblen:int64) = niblen` ASSUME_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
      UNDISCH_TAC `niblen < 272` THEN ARITH_TAC; ALL_TAC] THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--245) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    TRY DISCHARGE_MEMSAFE_TAC THEN
    ALL_TAC] THEN

  (* ---- WOP: find smallest N ---- *)
  SUBGOAL_THEN
   `?N. buflen < 8 * (N + 1) \/
        256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)`
  MP_TAC THENL
   [EXISTS_TAC `buflen:num` THEN DISJ1_TAC THEN ARITH_TAC;
    GEN_REWRITE_TAC LAND_CONV [num_WOP]] THEN
  DISCH_THEN(X_CHOOSE_THEN `N:num`
    (CONJUNCTS_THEN2 ASSUME_TAC MP_TAC)) THEN
  REWRITE_TAC[DE_MORGAN_THM; NOT_LT; NOT_LE] THEN STRIP_TAC THEN

  SUBGOAL_THEN `0 < N` ASSUME_TAC THENL
   [MP_TAC(ASSUME `buflen < 8 * (N + 1) \/
      256 <= LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)`) THEN
    UNDISCH_TAC `8 <= buflen` THEN
    STRUCT_CASES_TAC (ARITH_RULE `N = 0 \/ 0 < N`) THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES;
                    REJ_NIBBLES_ETA4_EMPTY; LENGTH] THEN
    ARITH_TAC; ALL_TAC] THEN

  ENSURES_WHILE_UP_TAC `N:num` `pc + 108` `pc + 248`
   `\i s. read (memory :> bytes (table,4096)) s =
          num_of_wordlist mldsa_rej_uniform_eta_table /\
          read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
          aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
          read Q7 s = word 20769504351625144638033088116686852 /\
          read Q30 s = word 46731384791156575435574448262545417 /\
          read Q31 s = word 664619068533544770747334646890102785 /\
          (let niblist = REJ_NIBBLES_ETA4(SUB_LIST(0,8 * i) inlist) in
           let niblen = LENGTH niblist in
           read X0 s = res /\
           read X1 s = word_add buf (word(8 * i)) /\
           read X2 s = word_sub (word buflen) (word(8 * i)) /\
           read X3 s = table /\ read X4 s = word 256 /\
           read X7 s = word_add stackpointer (word(2 * niblen)) /\
           read X8 s = stackpointer /\ read X9 s = word niblen /\
           read (memory :> bytes (stackpointer,2 * niblen)) s =
           num_of_wordlist niblist /\
           (exists e_acc.
             read events s = APPEND e_acc e /\
             memaccess_inbounds e_acc
               [buf,buflen; table,4096; stackpointer,576]
               [stackpointer,576; res,1024]))` THEN
  REPEAT CONJ_TAC THENL
   [(*** Subgoal 1: 0 < N ***)
    ASM_ARITH_TAC;

    (*** Subgoal 2: Pre-loop init (75 ARM steps) ***)
    GHOST_INTRO_TAC `q31_init:int128` `read Q31` THEN
    ENSURES_INIT_TAC "s0" THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--75) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    CONJ_TAC THENL [REWRITE_TAC[WORD_INSERT_Q31]; ALL_TAC] THEN
    REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; REJ_NIBBLES_ETA4_EMPTY] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REWRITE_TAC[LENGTH] THEN
    REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; WORD_SUB_0] THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_TRIVIAL; num_of_wordlist] THEN
    TRY DISCHARGE_MEMSAFE_TAC THEN
    ALL_TAC;

    (*** Subgoal 3: Loop body ***)
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    ABBREV_TAC `curlist = REJ_NIBBLES_ETA4(SUB_LIST(0,8 * i) inlist)` THEN
    ABBREV_TAC `curlen = LENGTH(curlist:int16 list)` THEN
    SUBGOAL_THEN `curlen < 256` ASSUME_TAC THENL
     [EXPAND_TAC "curlen" THEN EXPAND_TAC "curlist" THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
      UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `8 * (i + 1) <= buflen` ASSUME_TAC THENL
     [FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
      UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
    CONV_TAC(RATOR_CONV(LAND_CONV(TOP_DEPTH_CONV let_CONV))) THEN
    ASM_REWRITE_TAC[] THEN
    ENSURES_SEQUENCE_TAC `pc + 0xe0`
     `\s. read (memory :> bytes (table,4096)) s =
          num_of_wordlist mldsa_rej_uniform_eta_table /\
          read (memory :> bytes (buf,buflen)) s =
            num_of_wordlist (inlist:byte list) /\
          aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
          read Q7 s = word 20769504351625144638033088116686852 /\
          read Q30 s = word 46731384791156575435574448262545417 /\
          read Q31 s = word 664619068533544770747334646890102785 /\
          read X0 s = res /\
          read X1 s = word_add buf (word(8 * (i + 1))) /\
          read X2 s = word_sub (word buflen) (word(8 * (i + 1))) /\
          read X3 s = table /\ read X4 s = word 256 /\
          read X7 s = word_add stackpointer (word(2 * curlen)) /\
          read X8 s = stackpointer /\ read X9 s = word curlen /\
          read (memory :> bytes (stackpointer,2 * curlen)) s =
          num_of_wordlist (curlist:int16 list) /\
          (?lis0 lis1:int16 list.
             LENGTH lis0 <= 8 /\ LENGTH lis1 <= 8 /\
             val(read X12 s:int64) = LENGTH lis0 /\
             val(read X13 s:int64) = LENGTH lis1 /\
             APPEND lis0 lis1 =
               REJ_NIBBLES_ETA4(SUB_LIST(8 * i,8) inlist) /\
             read Q16 s = word(num_of_wordlist lis0):int128 /\
             read Q17 s = word(num_of_wordlist lis1):int128) /\
          curlen < 256 /\
          nonoverlapping (stackpointer,576) (word pc,344) /\
          (exists e_acc.
            read events s = APPEND e_acc e /\
            memaccess_inbounds e_acc
              [buf,buflen; table,4096; stackpointer,576]
              [stackpointer,576; res,1024])` THEN
    CONJ_TAC THENL
     [(* First half (pc+108 -> pc+0xe0): SIMD compute chain *)
      GHOST_INTRO_TAC `nibbles1:int128` `read Q17` THEN
      ENSURES_INIT_TAC "s0" THEN
      STRIP_EXISTS_ASSUM_TAC THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
      SUBGOAL_THEN `~(256 <= val(word curlen:int64))` ASSUME_TAC THENL
       [REWRITE_TAC[NOT_LE; VAL_WORD; DIMINDEX_64] THEN
        CONV_TAC NUM_REDUCE_CONV THEN
        SUBGOAL_THEN `curlen MOD 18446744073709551616 = curlen` SUBST1_TAC THENL
         [MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `curlen < 256` THEN ARITH_TAC;
          UNDISCH_TAC `curlen < 256` THEN ARITH_TAC]; ALL_TAC] THEN
      RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `~(256 <= val(word curlen:int64))`]) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [3] THEN
      ABBREV_TAC
       `loaded_d:int64 = read (memory :> bytes64 (word_add buf (word (8 * i)))) s3` THEN
      ARM_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (4--11) THEN
      REABBREV_TAC `nibbles0:int128 = read Q16 s11` THEN
      REABBREV_TAC `nibbles1b:int128 = read Q17 s11` THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (12--19) THEN
      RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
      RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
      RULE_ASSUM_TAC(REWRITE_RULE
       [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
      RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
      RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
      MAP_EVERY REABBREV_TAC
       [`idx0 = read X12 s19`; `idx1 = read X13 s19`] THEN
      MAP_EVERY ABBREV_TAC
       [`tab0 = read(memory :> bytes128(word_add table
                    (word(16 * val(idx0:int64))))) s19`;
        `tab1 = read(memory :> bytes128(word_add table
                    (word(16 * val(idx1:int64))))) s19`] THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (20--27) THEN
      RULE_ASSUM_TAC(REWRITE_RULE[WORD_SUBWORD_AND]) THEN
      RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
      RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
      RULE_ASSUM_TAC(REWRITE_RULE
       [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
      RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
      RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (28--29) THEN
      SUBGOAL_THEN
        `read Q16 s29 = word(num_of_wordlist
                             (REJ_NIBBLES_ETA4
                               [word_subword (loaded_d:int64) (0,8):byte;
                                word_subword loaded_d (8,8);
                                word_subword loaded_d (16,8);
                                word_subword loaded_d (24,8)])) /\
         read Q17 s29 = word(num_of_wordlist
                             (REJ_NIBBLES_ETA4
                               [word_subword (loaded_d:int64) (32,8):byte;
                                word_subword loaded_d (40,8);
                                word_subword loaded_d (48,8);
                                word_subword loaded_d (56,8)]))`
      MP_TAC THENL
       [(fun (asl, w) ->
          FIRST_X_ASSUM(K ALL_TAC o check (fun th ->
            let c = concl th in
            is_eq c &&
            (match lhs c with
             | Comb(Comb(Const("read",_), Const("events",_)), _) -> true
             | _ -> false))) (asl, w)) THEN
        REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
        REWRITE_TAC(List.map (fun k -> BITBLAST_RULE
          (vsubst [mk_small_numeral k, `k:num`]
          `bit k (word_subword (word_neg (word (bitval b):16 word))
                  (0,8):8 word) <=> b`)) (0--7)) THEN
        ASM_REWRITE_TAC[] THEN
        (let prove_hw name pos byte_pos op =
           let rhs_inner = if op = "and"
             then Printf.sprintf
               "(word_and (word_subword (loaded_d:int64) (%d,8):byte) (word 15):byte)"
               byte_pos
             else Printf.sprintf
               "(word_ushr (word_subword (loaded_d:int64) (%d,8):byte) 4:byte)"
               byte_pos in
           let goal_str = Printf.sprintf
             "(word_subword (%s:int128) (%d,16)):int16 = word_zx %s :int16"
             name pos rhs_inner in
           SUBGOAL_THEN (parse_term goal_str) ASSUME_TAC THENL
            [FIRST_X_ASSUM(MP_TAC o SYM o check
               (fun th -> let c = concl th in is_eq c &&
                 (try fst(dest_var(rhs c)) = name with _ -> false))) THEN
             DISCH_THEN(fun th -> SUBST1_TAC th THEN ASSUME_TAC(SYM th)) THEN
             CONV_TAC WORD_BLAST;
             ALL_TAC] in
         prove_hw "nibbles0" 0 0 "and" THEN
         prove_hw "nibbles0" 16 0 "ushr" THEN
         prove_hw "nibbles0" 32 8 "and" THEN
         prove_hw "nibbles0" 48 8 "ushr" THEN
         prove_hw "nibbles0" 64 16 "and" THEN
         prove_hw "nibbles0" 80 16 "ushr" THEN
         prove_hw "nibbles0" 96 24 "and" THEN
         prove_hw "nibbles0" 112 24 "ushr" THEN
         prove_hw "nibbles1b" 0 32 "and" THEN
         prove_hw "nibbles1b" 16 32 "ushr" THEN
         prove_hw "nibbles1b" 32 40 "and" THEN
         prove_hw "nibbles1b" 48 40 "ushr" THEN
         prove_hw "nibbles1b" 64 48 "and" THEN
         prove_hw "nibbles1b" 80 48 "ushr" THEN
         prove_hw "nibbles1b" 96 56 "and" THEN
         prove_hw "nibbles1b" 112 56 "ushr") THEN
        (fun (asl, w) ->
          let halfword_hyps =
            List.filter (fun (_,th) ->
              let c = concl th in
              is_eq c &&
              (try let l = lhand c in
                   match l with
                   | Comb(Comb(Const("word_subword",_), v),
                          Comb(Comb(Const(",",_), _), len_tm)) ->
                       is_var v &&
                       (let nm = fst(dest_var v) in
                        nm = "nibbles0" || nm = "nibbles1b") &&
                       (try dest_small_numeral len_tm = 16 with _ -> false)
                   | _ -> false
               with _ -> false)) asl in
          let byte_lemmas = BYTE_SPLIT_AND @ BYTE_SPLIT_USHR in
          let new_facts = List.concat (List.map (fun (_, h) ->
            List.concat (List.map (fun lem ->
              try CONJUNCTS(MATCH_MP lem h)
              with _ -> []) byte_lemmas)) halfword_hyps) in
          (MAP_EVERY ASSUME_TAC new_facts) (asl, w)) THEN
        UNDISCH_TAC
         `read(memory :> bytes(table,4096)) s29 =
          num_of_wordlist mldsa_rej_uniform_eta_table` THEN
        REPLICATE_TAC 4
         (GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
               [GSYM NUM_OF_PAIR_WORDLIST]) THEN
        REWRITE_TAC[mldsa_rej_uniform_eta_table; pair_wordlist] THEN
        CONV_TAC WORD_REDUCE_CONV THEN
        CONV_TAC(LAND_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN
        REWRITE_TAC[GSYM BYTES128_WBYTES] THEN REPEAT STRIP_TAC THEN
        DISCARD_MATCHING_ASSUMPTIONS
         [`read Q24 s = x`; `read Q25 s = x`] THEN
        REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
          (fun th -> is_var(rhs(concl th)) &&
                     let n = fst(dest_var(rhs(concl th))) in
                     n = "tab0" || n = "tab1"))) THEN
        DISCARD_MATCHING_ASSUMPTIONS
         [`read X12 s = x`; `read X13 s = x`] THEN
        REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
          (fun th -> is_var(rhs(concl th)) &&
                     let n = fst(dest_var(rhs(concl th))) in
                     n = "idx0" || n = "idx1"))) THEN
        ASM_REWRITE_TAC[] THEN
        DISCARD_MATCHING_ASSUMPTIONS
         [`read Q16 s = x`; `read Q17 s = x`] THEN
        REWRITE_TAC[REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THEN
        REWRITE_TAC[FILTER] THEN
        REWRITE_TAC[VAL_WORD_ZX_BYTE16; BYTE_AND_15_MOD; BYTE_USHR4_DIV;
                    VAL_WORD_NIBBLE_LT] THEN
        REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
        REWRITE_TAC[BITVAL_CLAUSES] THEN
        CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
        CONV_TAC NUM_REDUCE_CONV THEN
        REWRITE_TAC[WORD_ADD_0] THEN
        ASM_REWRITE_TAC[] THEN
        CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
        CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
        CONV_TAC NUM_REDUCE_CONV THEN
        REWRITE_TAC[num_of_wordlist; MULT_CLAUSES; ADD_CLAUSES] THEN
        CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
        RULE_ASSUM_TAC(REWRITE_RULE[BYTE_AND_15_MOD; BYTE_USHR4_DIV;
                                    VAL_WORD_ZX_BYTE16; VAL_WORD_NIBBLE_LT]) THEN
        ASM_REWRITE_TAC[] THEN
        REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
        CONV_TAC NUM_REDUCE_CONV THEN
        REWRITE_TAC[VAL_BYTE_NIB_MOD_65536] THEN
        CONV_TAC WORD_BLAST;
        STRIP_TAC] THEN
      DISCARD_MATCHING_ASSUMPTIONS
       [`read Q16 s = word_join (x:int64) (y:int64):int128`;
        `read Q17 s = word_join (x:int64) (y:int64):int128`] THEN
      ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
      ASM_REWRITE_TAC[WORD_SUBWORD_AND] THEN
      CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
      CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
      REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; ADD_CLAUSES] THEN
      REWRITE_TAC[POPCOUNT_AND_POWERS] THEN
      REPEAT CONJ_TAC THEN
      TRY(CONV_TAC WORD_RULE) THEN
      TRY(NONOVERLAPPING_TAC) THEN
      TRY(REWRITE_TAC[UADDLV_BOUND_LEMMA] THEN NO_TAC) THEN
      TRY(ASM_REWRITE_TAC[] THEN NO_TAC) THEN
      TRY(ASM_ARITH_TAC) THEN
      TRY (
      (* Two remaining goals (per subgoal arm):
         (a) `?e_acc'. ... = APPEND e_acc' e /\ memaccess_inbounds e_acc' ...`
             — discharge with DISCHARGE_MEMSAFE_ASM_TAC.
         (b) `?lis0 lis1. ...` — same existential as the parent CORRECT proof's
             post-TBL closure (line ~3250); reuse that pattern.
         Use FIRST so each subgoal picks its appropriate closer. *)
      FIRST
       [(* Establish table index bounds for memory safety: idx0/idx1 < 256.
           Required so DISCHARGE_MEMSAFE_ASM_TAC can prove the table access
           at word_add table (word(16 * val idx)) is contained in the table
           region (4096 bytes).

           idx0/idx1 are the X12/X13 popcount-accumulator values at s19,
           with shape word_zx (word_subword X (0,32)):int64 where X is the
           int128 word_add of 8 summands word_and (word 2^k) (mask) for
           k = 0..7. Each summand is 0 or 2^k, so the sum is bounded by
           1+2+...+128 = 255. The two helper lemmas below close the bound
           generically over any word width with dimindex >= 8:
             SUM_8_BIT_BOUND_POLY: sum of 8 bounded summands is <= 255
             SBND_K_POLY:         val(word_and (word k) X) <= k for k <= 128
           SUBST1_TAC the popcount equation, REWRITE val(word_zx ...) and
           val(word_subword (...,0,32)), then MATCH_MP_TAC each lemma. *)
        SUBGOAL_THEN `val(idx0:int64) < 256 /\ val(idx1:int64) < 256`
          STRIP_ASSUME_TAC THENL
         [          (let close_idx name =
             FIRST_X_ASSUM(SUBST1_TAC o SYM o check (fun th ->
               let c = concl th in
               is_eq c &&
               (try fst(dest_var(rhs c)) = name with _ -> false))) THEN
             REWRITE_TAC[WORD_ZX_INT32_INT64; VAL_WORD_SUBWORD_0_32] THEN
             MATCH_MP_TAC(ARITH_RULE `n <= 255 ==> n MOD 2 EXP 32 < 256`) THEN
             MATCH_MP_TAC SUM_8_BIT_BOUND_POLY THEN
             REWRITE_TAC[DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64;
                         DIMINDEX_128] THEN
             CONV_TAC NUM_REDUCE_CONV THEN
             REPEAT CONJ_TAC THEN
             MATCH_MP_TAC SBND_K_POLY THEN
             REWRITE_TAC[DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64;
                         DIMINDEX_128] THEN
             CONV_TAC NUM_REDUCE_CONV in
           CONJ_TAC THENL
            [close_idx "idx0";
             close_idx "idx1"]);
          ALL_TAC] THEN
        DISCHARGE_MEMSAFE_ASM_TAC;
        (* lis0/lis1 existential closure — copied verbatim from the parent
           CORRECT proof. *)
        EXISTS_TAC
          `REJ_NIBBLES_ETA4
             [word_subword (loaded_d:int64) (0,8):byte;
              word_subword loaded_d (8,8);
              word_subword loaded_d (16,8);
              word_subword loaded_d (24,8)]` THEN
        EXISTS_TAC
          `REJ_NIBBLES_ETA4
             [word_subword (loaded_d:int64) (32,8):byte;
              word_subword loaded_d (40,8);
              word_subword loaded_d (48,8);
              word_subword loaded_d (56,8)]` THEN
        REWRITE_TAC[REJ_NIBBLES_ETA4_LENGTH_4] THEN
      MP_TAC(SPECL [`buf:int64`; `buflen:num`; `inlist:byte list`;
                    `i:num`; `s29:armstate`] SUB_LIST_8_BYTES_FROM_INT64) THEN
      ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
      ASM_REWRITE_TAC[REJ_NIBBLES_ETA4_SPLIT_8] THEN
      REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
      REWRITE_TAC(List.map (fun k -> BITBLAST_RULE
        (vsubst [mk_small_numeral k, `k:num`]
        `bit k (word_subword (word_neg (word (bitval b):16 word))
                (0,8):8 word) <=> b`)) (0--7)) THEN
      ASM_REWRITE_TAC[] THEN
      (let prove_hw name pos byte_pos op =
         let rhs_inner = if op = "and"
           then Printf.sprintf
             "(word_and (word_subword (loaded_d:int64) (%d,8):byte) (word 15):byte)"
             byte_pos
           else Printf.sprintf
             "(word_ushr (word_subword (loaded_d:int64) (%d,8):byte) 4:byte)"
             byte_pos in
         let goal_str = Printf.sprintf
           "(word_subword (%s:int128) (%d,16)):int16 = word_zx %s :int16"
           name pos rhs_inner in
         SUBGOAL_THEN (parse_term goal_str) ASSUME_TAC THENL
          [FIRST_X_ASSUM(MP_TAC o SYM o check
             (fun th -> let c = concl th in is_eq c &&
               (try fst(dest_var(rhs c)) = name with _ -> false))) THEN
           DISCH_THEN(fun th -> SUBST1_TAC th THEN ASSUME_TAC(SYM th)) THEN
           CONV_TAC WORD_BLAST;
           ALL_TAC] in
       prove_hw "nibbles0" 0 0 "and" THEN
       prove_hw "nibbles0" 16 0 "ushr" THEN
       prove_hw "nibbles0" 32 8 "and" THEN
       prove_hw "nibbles0" 48 8 "ushr" THEN
       prove_hw "nibbles0" 64 16 "and" THEN
       prove_hw "nibbles0" 80 16 "ushr" THEN
       prove_hw "nibbles0" 96 24 "and" THEN
       prove_hw "nibbles0" 112 24 "ushr" THEN
       prove_hw "nibbles1b" 0 32 "and" THEN
       prove_hw "nibbles1b" 16 32 "ushr" THEN
       prove_hw "nibbles1b" 32 40 "and" THEN
       prove_hw "nibbles1b" 48 40 "ushr" THEN
       prove_hw "nibbles1b" 64 48 "and" THEN
       prove_hw "nibbles1b" 80 48 "ushr" THEN
       prove_hw "nibbles1b" 96 56 "and" THEN
       prove_hw "nibbles1b" 112 56 "ushr") THEN
      REPEAT CONJ_TAC THEN
      FIRST
       [MP_TAC(SPECL
         [`nibbles0:int128`;
          `word_subword (loaded_d:int64) (0,8):byte`;
          `word_subword (loaded_d:int64) (8,8):byte`;
          `word_subword (loaded_d:int64) (16,8):byte`;
          `word_subword (loaded_d:int64) (24,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN REFL_TAC;
        MP_TAC(SPECL
         [`nibbles1b:int128`;
          `word_subword (loaded_d:int64) (32,8):byte`;
          `word_subword (loaded_d:int64) (40,8):byte`;
          `word_subword (loaded_d:int64) (48,8):byte`;
          `word_subword (loaded_d:int64) (56,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN REFL_TAC;
        FIRST_ASSUM(fun my_hyp ->
          FIRST_ASSUM(fun arm_hyp ->
            try ACCEPT_TAC(TRANS (SYM arm_hyp) my_hyp)
            with _ -> NO_TAC))]]) THEN
      ALL_TAC;
            (* Second half (pc+0xe0 -> pc+248): stores *)
      ENSURES_INIT_TAC "s0" THEN
      STRIP_EXISTS_ASSUM_TAC THEN
      FIRST_X_ASSUM(X_CHOOSE_THEN `lis0:int16 list` MP_TAC o check
        (fun th -> try fst(dest_var(fst(dest_exists(concl th)))) = "lis0"
                   with _ -> false)) THEN
      DISCH_THEN(X_CHOOSE_THEN `lis1:int16 list` STRIP_ASSUME_TAC) THEN
      ABBREV_TAC `len0 = LENGTH(lis0:int16 list)` THEN
      ABBREV_TAC `len1 = LENGTH(lis1:int16 list)` THEN
      SUBGOAL_THEN `val(read X12 s0:int64) = len0 /\ val(read X13 s0:int64) = len1`
        STRIP_ASSUME_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [1] THEN
      SUBGOAL_THEN
       `read (memory :> bytes (stackpointer, 2 * (curlen + len0))) s1 =
        num_of_wordlist(APPEND curlist lis0:int16 list)`
      ASSUME_TAC THENL
       [REWRITE_TAC[LEFT_ADD_DISTRIB] THEN
        SUBGOAL_THEN `LENGTH(curlist:int16 list) = curlen` ASSUME_TAC THENL
         [EXPAND_TAC "curlen" THEN REFL_TAC; ALL_TAC] THEN
        W(MP_TAC o PART_MATCH (lhand o rand)
          BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
        ANTS_TAC THENL
         [REWRITE_TAC[DIMINDEX_16] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC;
          ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN
        CONJ_TAC THENL
         [ASM_REWRITE_TAC[];
          SUBGOAL_THEN
           `read (memory :> bytes128
                  (word_add stackpointer (word (2 * curlen)))) s1 =
            word(num_of_wordlist(lis0:int16 list)):int128`
          MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
          DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
          REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                      VAL_READ_WBYTES;
                      DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
          SUBGOAL_THEN `2 * len0 = MIN 16 (2 * len0)` SUBST1_TAC THENL
           [UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC;
            REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
          REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
          MATCH_MP_TAC MOD_LT THEN
          MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
          ASM_REWRITE_TAC[DIMINDEX_16] THEN
          UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC];
        ALL_TAC] THEN
      SUBGOAL_THEN `read X12 s1:int64 = word len0` ASSUME_TAC THENL
       [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
        CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
        UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `read X13 s1:int64 = word len1` ASSUME_TAC THENL
       [REWRITE_TAC[GSYM VAL_EQ] THEN ASM_REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
        CONV_TAC SYM_CONV THEN MATCH_MP_TAC MOD_LT THEN
        UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
      ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s2" THEN
      FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1]) THEN
      ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
      SUBGOAL_THEN
       `nonoverlapping (word_add stackpointer (word(2 * (curlen + len0))):int64,
                        16) (word pc:int64, 344)`
      ASSUME_TAC THENL [NONOVERLAPPING_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `val(word len0:int64) = len0` ASSUME_TAC THENL
       [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
        UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC; ALL_TAC] THEN
      RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word len0:int64) = len0`]) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [3] THEN
      RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `val(word len0:int64) = len0`]) THEN
      SUBGOAL_THEN
       `read (memory :> bytes (stackpointer, 2 * ((curlen + len0) + len1))) s3 =
        num_of_wordlist(APPEND (APPEND curlist lis0) lis1:int16 list)`
      ASSUME_TAC THENL
       [REWRITE_TAC[LEFT_ADD_DISTRIB] THEN
        SUBGOAL_THEN
          `LENGTH(APPEND curlist lis0:int16 list) = curlen + len0`
        ASSUME_TAC THENL
         [REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        W(MP_TAC o PART_MATCH (lhand o rand)
          BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
        ANTS_TAC THENL
         [REWRITE_TAC[DIMINDEX_16] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC;
          ALL_TAC] THEN
        DISCH_THEN SUBST1_TAC THEN
        SUBGOAL_THEN
          `word_add stackpointer (word (2 * curlen + 2 * len0):int64) =
           word_add stackpointer (word (2 * (curlen + len0)))`
         (fun th -> REWRITE_TAC[th]) THENL
         [CONV_TAC WORD_RULE; ALL_TAC] THEN
        SUBGOAL_THEN `2 * curlen + 2 * len0 = 2 * (curlen + len0)`
         SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
        CONJ_TAC THENL
         [ASM_REWRITE_TAC[];
          SUBGOAL_THEN
           `read (memory :> bytes128
                  (word_add stackpointer (word (2 * (curlen + len0))))) s3 =
            word(num_of_wordlist(lis1:int16 list)):int128`
          MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
          DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
          REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                      VAL_READ_WBYTES;
                      DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
          SUBGOAL_THEN `2 * len1 = MIN 16 (2 * len1)` SUBST1_TAC THENL
           [UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC;
            REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
          REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
          MATCH_MP_TAC MOD_LT THEN
          MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
          ASM_REWRITE_TAC[DIMINDEX_16] THEN
          UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC];
        ALL_TAC] THEN
      ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s4" THEN
      FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1]) THEN
      ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (5--6) THEN
      ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
      CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      SUBGOAL_THEN `8 * (i + 1) <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
       [ASM_REWRITE_TAC[] THEN
        MP_TAC(ASSUME `8 * (i + 1) <= buflen`) THEN ARITH_TAC;
        ALL_TAC] THEN
      MP_TAC(SPECL [`inlist:byte list`; `i:num`] REJ_NIBBLES_ETA4_STEP) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
      ABBREV_TAC `newbatch = REJ_NIBBLES_ETA4(SUB_LIST(8*i, 8) inlist):int16 list` THEN
      SUBGOAL_THEN `APPEND (lis0:int16 list) lis1 = newbatch` ASSUME_TAC THENL
       [EXPAND_TAC "newbatch" THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      SUBGOAL_THEN `LENGTH(newbatch:int16 list) = len0 + len1` ASSUME_TAC THENL
       [UNDISCH_TAC `APPEND (lis0:int16 list) lis1 = newbatch` THEN
        DISCH_THEN(SUBST1_TAC o SYM) THEN
        REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      SUBGOAL_THEN `val(word len0:int64) = len0 /\ val(word len1:int64) = len1`
        STRIP_ASSUME_TAC THENL
       [CONJ_TAC THEN MATCH_MP_TAC VAL_WORD_EQ THEN
        REWRITE_TAC[DIMINDEX_64] THENL
         [UNDISCH_TAC `len0:num <= 8` THEN ARITH_TAC;
          UNDISCH_TAC `len1:num <= 8` THEN ARITH_TAC];
        ALL_TAC] THEN
      REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[] THEN
      REPEAT CONJ_TAC THEN
      TRY(CONV_TAC WORD_RULE) THEN
      TRY(AP_TERM_TAC THEN AP_TERM_TAC THEN
          ASM_REWRITE_TAC[] THEN ARITH_TAC) THEN
      TRY(SUBGOAL_THEN
           `2 * (curlen + len0 + len1) = 2 * ((curlen + len0) + len1)`
         SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
         SUBGOAL_THEN
          `APPEND curlist (newbatch:int16 list) =
           APPEND (APPEND curlist lis0) lis1`
         SUBST1_TAC THENL
          [UNDISCH_TAC `APPEND (lis0:int16 list) lis1 = newbatch` THEN
           DISCH_THEN(SUBST1_TAC o SYM) THEN
           REWRITE_TAC[APPEND_ASSOC]; ALL_TAC] THEN
         ASM_REWRITE_TAC[] THEN NO_TAC) THEN
      (* e_acc existential at end: reuse the loop-entry e_acc with 6 new events *)
      TRY(W(fun (_,w) ->
        if (try fst(dest_var(fst(dest_exists w))) = "e_acc" with _ -> false)
        then DISCHARGE_MEMSAFE_ASM_TAC
        else NO_TAC)) THEN
      (* Remaining goal is the `?e_acc'.` existential for the 2 stack stores;
         DISCHARGE_MEMSAFE_ASM_TAC handles the CONS_TO_APPEND + memaccess_inbounds. *)
      TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
      ALL_TAC];

    (*** Subgoal 4: Backedge ***)
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    ENSURES_INIT_TAC "s0" THEN
    STRIP_EXISTS_ASSUM_TAC THEN
    SUBGOAL_THEN `8 <= val(word_sub (word buflen:int64) (word(8 * i)))`
    ASSUME_TAC THENL
     [SUBGOAL_THEN `8 * (i + 1) <= buflen` ASSUME_TAC THENL
       [FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN
        UNDISCH_TAC `i < N:num` THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `8 * i < 2 EXP 64` ASSUME_TAC THENL
       [UNDISCH_TAC `buflen < 2 EXP 64` THEN
        UNDISCH_TAC `8 * (i + 1) <= buflen` THEN ARITH_TAC; ALL_TAC] THEN
      VAL_INT64_TAC `8 * i` THEN ASM_REWRITE_TAC[VAL_WORD_SUB_CASES] THEN
      UNDISCH_TAC `8 * (i + 1) <= buflen` THEN ARITH_TAC; ALL_TAC] THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
    ALL_TAC;

    (*** Subgoal 5: Post-loop ***)
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    ABBREV_TAC `niblen = LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list)` THEN
    SUBGOAL_THEN `niblen < 272` ASSUME_TAC THENL
     [EXPAND_TAC "niblen" THEN
      MATCH_MP_TAC NIBLEN_BOUND_FROM_WOP THEN
      ASM_REWRITE_TAC[] THEN
      X_GEN_TAC `mm:num` THEN DISCH_TAC THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `mm:num`) THEN
      ASM_REWRITE_TAC[];
      ALL_TAC] THEN
    VAL_INT64_TAC `niblen:num` THEN
    ASM_CASES_TAC `256 <= niblen` THENL
     [      ASM_CASES_TAC `8 <= val(word_sub (word buflen:int64) (word(8 * N)))` THENL
       [        ENSURES_SEQUENCE_TAC `pc + 108`
         `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
              read PC s = word(pc + 108) /\
              read X0 s = res /\ read X4 s = word 256 /\
              read X8 s = stackpointer /\
              read Q7 s = word 20769504351625144638033088116686852 /\
              read X9 s = word niblen /\
              read (memory :> bytes (stackpointer,2 * niblen)) s =
              num_of_wordlist (REJ_NIBBLES_ETA4(SUB_LIST(0,8*N) inlist):int16 list) /\
              ALL (nonoverlapping (res,1024)) [(word pc,344); (stackpointer,576)] /\
              (exists e_acc.
                read events s = APPEND e_acc e /\
                memaccess_inbounds e_acc
                  [buf,buflen; table,4096; stackpointer,576]
                  [stackpointer,576; res,1024])` THEN
        CONJ_TAC THENL
         [          ENSURES_INIT_TAC "s0" THEN
          STRIP_EXISTS_ASSUM_TAC THEN
          ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
          ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
          REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
          REPEAT CONJ_TAC THEN
          TRY(NONOVERLAPPING_TAC) THEN
          TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
          ALL_TAC;
          ENSURES_INIT_TAC "s0" THEN
          STRIP_EXISTS_ASSUM_TAC THEN
          SUBGOAL_THEN `256 <= val(word niblen:int64)` ASSUME_TAC THENL
           [REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN
            SUBGOAL_THEN `niblen MOD 2 EXP 64 = niblen` SUBST1_TAC THENL
             [MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `niblen < 272` THEN
              ARITH_TAC;
              ASM_REWRITE_TAC[]];
            ALL_TAC] THEN
          ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
          ENSURES_FINAL_STATE_TAC THEN
          REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
          EXISTS_TAC `N:num` THEN
          CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
          REPEAT CONJ_TAC THEN
          TRY(UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
              ARITH_TAC) THEN
          TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
          ALL_TAC];
        ENSURES_INIT_TAC "s0" THEN
        STRIP_EXISTS_ASSUM_TAC THEN
        ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
        ENSURES_FINAL_STATE_TAC THEN
        REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
        EXISTS_TAC `N:num` THEN
        CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
        REPEAT CONJ_TAC THEN
        TRY(UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
            ARITH_TAC) THEN
        TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
        ALL_TAC];
      SUBGOAL_THEN `buflen < 8 * (N + 1)` ASSUME_TAC THENL
       [FIRST_X_ASSUM(DISJ_CASES_THEN ASSUME_TAC) THEN ASM_REWRITE_TAC[] THEN
        UNDISCH_TAC `~(256 <= niblen)` THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      SUBGOAL_THEN `8 * N <= buflen` ASSUME_TAC THENL
       [FIRST_X_ASSUM(MP_TAC o SPEC `N - 1`) THEN
        UNDISCH_TAC `0 < N` THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `8 * N = buflen` ASSUME_TAC THENL
       [MP_TAC(ASSUME `8 divides buflen`) THEN
        REWRITE_TAC[divides] THEN
        DISCH_THEN(X_CHOOSE_TAC `d:num`) THEN ASM_REWRITE_TAC[] THEN
        UNDISCH_TAC `buflen < 8 * (N + 1)` THEN ASM_REWRITE_TAC[] THEN
        UNDISCH_TAC `8 * N <= buflen` THEN ASM_REWRITE_TAC[] THEN
        REWRITE_TAC[GSYM MULT_ASSOC; LT_MULT_LCANCEL; LE_MULT_LCANCEL] THEN
        CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `SUB_LIST(0,buflen) inlist = inlist:byte list`
        (fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th])) THENL
       [MATCH_MP_TAC SUB_LIST_REFL THEN ASM_REWRITE_TAC[LE_REFL]; ALL_TAC] THEN
      ASM_REWRITE_TAC[] THEN
      SUBGOAL_THEN `~(8 <= val(word_sub (word buflen:int64) (word buflen)))`
        ASSUME_TAC THENL
       [REWRITE_TAC[WORD_SUB_REFL; VAL_WORD_0] THEN ARITH_TAC; ALL_TAC] THEN
      ENSURES_INIT_TAC "s0" THEN
      STRIP_EXISTS_ASSUM_TAC THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
      ENSURES_FINAL_STATE_TAC THEN
      REWRITE_TAC[ALL] THEN ASM_REWRITE_TAC[] THEN
      EXISTS_TAC `N:num` THEN
      CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
      REPEAT CONJ_TAC THEN
      TRY(UNDISCH_TAC `niblen < 272` THEN EXPAND_TAC "niblen" THEN
          ARITH_TAC) THEN
      TRY(DISJ1_TAC THEN ASM_REWRITE_TAC[]) THEN
      TRY DISCHARGE_MEMSAFE_ASM_TAC THEN
      ALL_TAC]]);;


(* ------------------------------------------------------------------------- *)
(* Memory safety of the subroutine form.                                     *)
(* ------------------------------------------------------------------------- *)


let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_MEMSAFE = time prove
 (`!res buf buflen table (inlist:byte list) pc e stackpointer returnaddress.
      8 divides val buflen /\
      8 <= val buflen /\
      LENGTH inlist = val buflen /\
      ALL (nonoverlapping (word_sub stackpointer (word 576),576))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (buf,val buflen); (table,4096)] /\
      ALL (nonoverlapping (res,1024))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (word_sub stackpointer (word 576),576)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word pc /\
                read SP s = stackpointer /\
                read X30 s = returnaddress /\
                C_ARGUMENTS [res;buf;buflen;table] s /\
                read(memory :> bytes(table,4096)) s =
                num_of_wordlist mldsa_rej_uniform_eta_table /\
                read(memory :> bytes(buf,val buflen)) s =
                num_of_wordlist inlist /\
                read events s = e)
           (\s. read PC s = returnaddress /\
                (exists e2.
                     read events s = APPEND e2 e /\
                     memaccess_inbounds e2
                       [buf,val buflen; table,4096;
                        word_sub stackpointer (word 576),576]
                       [word_sub stackpointer (word 576),576; res,1024]))
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes(res,1024);
                       memory :> bytes(word_sub stackpointer (word 576),576)])`,
  ARM_ADD_RETURN_STACK_TAC
    ~pre_post_nsteps:(1,1)
    MLDSA_REJ_UNIFORM_ETA4_EXEC
    (REWRITE_RULE[fst MLDSA_REJ_UNIFORM_ETA4_EXEC]
       (CONV_RULE LENGTH_SIMPLIFY_CONV MLDSA_REJ_UNIFORM_ETA4_MEMSAFE))
    `[]:int64 list` 576 THEN
  DISCHARGE_MEMSAFE_TAC);;

(* Constant-time (secret-independent timing) proof for rej_uniform_eta4.
   See proofs/hol_light/README.md for the security property and the statement of
   MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_SAFE.

   This is a rejection sampler, so it is NOT data-oblivious and the standard
   PROVE_SAFETY_SPEC_TAC does not apply. We prove constant-time up to the reject
   pattern: the event trace is a function of the public pointers and the reject
   bitmap REJ_MASK_ETA4 (one accept/reject bit per nibble, "accept" = val < 9),
   never the accepted values. gen_mk_safety_spec cannot express this (its
   f_events takes only pointers/pc/sp/ra), so the spec is hand-written with the
   reject mask as an extra public argument.

   Secret-dependent behaviour lives only in the loop8 sampler:
     - table reads    ldr q,[x3, mask*16]         address = 8-bit accept mask
     - scratch stores st1 [x7]; x7 += 2*popcount  offset  = accepted count
     - loop trip count = f(accept masks, buflen)
   All three are functions of the accept masks and the public buflen; the
   prologue zero-init and the final Barrett-reduce copy have fixed trip counts. *)

(* The public reject-mask projection: one accept/reject bit per nibble, with  *)
(* the accepted values DISCARDED. Mirrors REJ_NIBBLES_ETA4 (which FILTERs the *)
(* same predicate to keep the accepted values = the SECRET); here we MAP the  *)
(* predicate to keep only the decisions. From this bool list one recovers the *)
(* per-group 8-bit masks (pack 8 bits), the accepted counts (popcounts), and  *)
(* hence every secret-dependent address/branch above — but not the values.    *)
(*                                                                            *)
(* NOTE: REJ_NIBBLES_ETA4 l = FILTER (\x. val x < 9) (NIBBLES_OF_BYTES l)     *)
(*       so LENGTH(REJ_NIBBLES_ETA4 l) = number of `true` in REJ_MASK_ETA4 l. *)
(*       REJ_NIBBLES_ETA4 is NOT recoverable from REJ_MASK_ETA4 alone (the    *)
(*       accepted values are gone) — that is the whole point.                 *)

let REJ_MASK_ETA4 = define
  `REJ_MASK_ETA4 (l:byte list) : bool list =
   MAP (\x:int16. val x < 9) (NIBBLES_OF_BYTES l)`;;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* These are the "store-advance / trip-count" half of the mask bridge (the    *)
(* and independently of the assembly (pure list facts). They express the      *)
(* SECRET accepted-count (which drives niblen, every stack-store offset       *)
(* sp+2*niblen, and the loop trip count) as a function of the PUBLIC reject   *)
(* mask only — the accepted VALUES never appear. Migrate together with the    *)
(* SUBROUTINE_SAFE theorem when the proof is closed.                          *)
(* -------------------------------------------------------------------------- *)

(* Abstract core: #elements passing P = #`true`s in the boolean image.        *)
let LENGTH_FILTER_EQ_LENGTH_FILTER_MAP = prove
 (`!(P:A->bool) xs.
     LENGTH(FILTER (\b:bool. b) (MAP P xs)) = LENGTH(FILTER P xs)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN
  REWRITE_TAC[MAP; FILTER; LENGTH] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

(* THE store-advance / trip-count bridge: the number of ACCEPTED nibbles
   (= niblen, driving all sp+2*niblen store offsets and the WOP trip count N)
   equals the number of `true`s in the PUBLIC reject mask.  Value-free: the RHS
   mentions only REJ_MASK_ETA4 (public), never the accepted values. *)
let LENGTH_REJ_NIBBLES_ETA4_EQ_MASK = prove
 (`!l:byte list.
     LENGTH(REJ_NIBBLES_ETA4 l) = LENGTH(FILTER (\b:bool. b) (REJ_MASK_ETA4 l))`,
  REWRITE_TAC[REJ_NIBBLES_ETA4; REJ_MASK_ETA4;
              LENGTH_FILTER_EQ_LENGTH_FILTER_MAP]);;

(* A clean public "accepted count" over a mask, additive over APPEND — the
   form the f_events per-iteration store-offset witness will use. *)
let NUM_ACCEPTED = define
  `NUM_ACCEPTED (m:bool list) = LENGTH(FILTER (\b:bool. b) m)`;;

let NUM_ACCEPTED_APPEND = prove
 (`!m1 m2. NUM_ACCEPTED(APPEND m1 m2) = NUM_ACCEPTED m1 + NUM_ACCEPTED m2`,
  REWRITE_TAC[NUM_ACCEPTED; FILTER_APPEND; LENGTH_APPEND]);;

(* Public table-index witness: the 8-bit LSB-first packing of an accept-mask
   group.  The compaction table (mldsa_rej_uniform_eta_table) is indexed by this
   0..255 value, so the loop's data-dependent table read decodes to
   EventLoad (table + 16 * PACK_MASK8 <group mask>) — a function of the PUBLIC
   mask only.  Explicit 8-EL form (not nsum) to match the eventual hardware
   value-bridge, whose shape mirrors UADDLV_COUNT_LEMMA (8 explicit bits). *)
let PACK_MASK8 = define
  `PACK_MASK8 (bs:bool list) =
     bitval(EL 0 bs) +   2 * bitval(EL 1 bs) +
     4 * bitval(EL 2 bs) + 8 * bitval(EL 3 bs) +
    16 * bitval(EL 4 bs) + 32 * bitval(EL 5 bs) +
    64 * bitval(EL 6 bs) + 128 * bitval(EL 7 bs)`;;

let PACK_MASK8_BOUND = prove
 (`!bs:bool list. PACK_MASK8 bs < 256`,
  GEN_TAC THEN REWRITE_TAC[PACK_MASK8] THEN
  MAP_EVERY (fun t -> MP_TAC(SPEC t BITVAL_BOUND))
   [`EL 0 (bs:bool list)`; `EL 1 (bs:bool list)`; `EL 2 (bs:bool list)`;
    `EL 3 (bs:bool list)`; `EL 4 (bs:bool list)`; `EL 5 (bs:bool list)`;
    `EL 6 (bs:bool list)`; `EL 7 (bs:bool list)`] THEN
  ARITH_TAC);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* table index; it drives the data-dependent table read                       *)
(*   LDR Q24,[X3,X12,LSL#4]  =  EventLoad(table + 16 * val(idx0)).            *)
(* idx0 = FMOV(UADDLV(AND(CMHI(Q30=15-per-lane,                               *)
(* nibbles),Q31=[1;2;4;..;128]))) i.e. the WEIGHTED 8-bit pack of the         *)
(* per-nibble accept mask (NOT popcount; the eta4.ml:2744                     *)
(* "popcount-accumulator" comment is stale — the real bound proof at          *)
(* 2754-2774 uses SUM_8_BIT_BOUND_POLY with weights <=128, val<256). with the *)
(* 8 per-nibble accept predicates (val nibble_k < 9) ABSTRACTED to booleans   *)
(* b0..b7. Lane layout (from the word_join tree): b0 = highest lane = weight  *)
(* 128, ..., b7 = lowest lane = weight 1.                                     *)
(*                                                                            *)
(* PACK companion to UADDLV_COUNT_LEMMA (aarch64_utils.ml:534, the POPCOUNT   *)
(* used for the X9/X7 store advance). Proven UADDLV_COUNT_LEMMA-style: REPEAT *)
(* NUM_REDUCE_CONV (256 concrete cases, ~84s).                                *)
(*                                                                            *)
(* SECRET-INDEPENDENCE LINK: in nibble order the accept bits b0..b7 of a      *)
(* 4-byte group = REJ_MASK_ETA4 of that group, and 128*b0+64*b1+..+bitval b7  *)
(* = PACK_MASK8 (that group's mask) [PACK_MASK8 above]. So val(idx0) — hence  *)
(* the table-read address table+16*val(idx0) — is a function of the PUBLIC    *)
(* reject the 2nd 4 bytes; the same lemma applies.)                           *)
(* -------------------------------------------------------------------------- *)

let UADDLV_PACK_LEMMA = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
     (val (word_zx (word_subword ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (0,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (16,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (32,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (48,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (64,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (80,16):(128)word)) ((word_add (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (96,16):(128)word)) (word_subword ((word_and (word 664619068533544770747334646890102785:(128)word)) (word_join (word_join (word_join (word_neg (word (bitval b0):(16)word)) (word_neg (word (bitval b1):(16)word)):(32)word) (word_join (word_neg (word (bitval b2):(16)word)) (word_neg (word (bitval b3):(16)word)):(32)word):(64)word) (word_join (word_join (word_neg (word (bitval b4):(16)word)) (word_neg (word (bitval b5):(16)word)):(32)word) (word_join (word_neg (word (bitval b6):(16)word)) (word_neg (word (bitval b7):(16)word)):(32)word):(64)word):(128)word)) (112,16):(128)word)))))))) (0,32):(32)word):(64)word)) =
     128 * bitval b0 + 64 * bitval b1 + 32 * bitval b2 + 16 * bitval b3 +
     8 * bitval b4 + 4 * bitval b5 + 2 * bitval b6 + bitval b7`,
  REPEAT GEN_TAC THEN
  MAP_EVERY BOOL_CASES_TAC [`b0:bool`;`b1:bool`;`b2:bool`;`b3:bool`;
    `b4:bool`;`b5:bool`;`b6:bool`;`b7:bool`] THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN CONV_TAC NUM_REDUCE_CONV);;

(* The value bridge's weighted sum IS PACK_MASK8 of the accept-mask in NIBBLE *)
(* order. UADDLV_PACK_LEMMA's b0..b7 are in LANE order (b0 = highest lane =   *)
(* byte3's high nibble = weight 128 ... b7 = lowest lane = byte0's low nibble *)
(* = weight 1). NIBBLES_OF_BYTES [byte0;byte1;byte2;byte3] lists nibbles      *)
(* low-first per byte: [byte0-lo; byte0-hi; byte1-lo; ...; byte3-hi] =        *)
(* [b7;b6;b5;b4;b3;b2; b1;b0]. Hence val(idx0) = PACK_MASK8 (REJ_MASK_ETA4    *)
(* <that 4-byte group>) once the abstract booleans are instantiated to (val   *)
(* nibble_k < 9) — the core _SAFE proof does that instantiation using the     *)
(* eta4 nibble machinery.                                                     *)
let PACK_CONNECT = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7:bool.
     128 * bitval b0 + 64 * bitval b1 + 32 * bitval b2 + 16 * bitval b3 +
     8 * bitval b4 + 4 * bitval b5 + 2 * bitval b6 + bitval b7 =
     PACK_MASK8 [b7;b6;b5;b4;b3;b2;b1;b0]`,
  REWRITE_TAC[PACK_MASK8] THEN
  CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* misc.ml:2100). Its guard FAILS the unification if the per-iteration event  *)
(* LHS contains ANY free variable that is not *syntactically* one of          *)
(* f_ev_loop8's applied arguments. The hand-written f_events spec passes the  *)
(* WHOLE reject mask (REJ_MASK_ETA4 inlist) as f_ev_loop8's mask argument. If *)
(* that argument stays the COMPOUND term (REJ_MASK_ETA4 inlist), then `frees` *)
(* extracts the atom `inlist`, which is NOT syntactically the compound arg,   *)
(* so                                                                         *)
(*   TEST (s124, live): unify `f_ev table mask i = [EventLoad(table+16*       *)
(*   PACK_MASK8(SUB_LIST(16*i,16) mask),16)]` SUCCEEDS with atomic `mask`,    *)
(*   but the same with the compound (REJ_MASK_ETA4 inlist) FAILS.             *)
(*                                                                            *)
(*   `mask = REJ_MASK_ETA4 inlist`  (atomic var).  Then the postcondition     *)
(* extracts e_loop = \i. f_ev_loop8 .. mask i (atomic). The loop-body mask    *)
(* bridge must then rewrite every hardware `inlist`-form into a SUB_LIST of   *)
(* the atomic `mask` via REJ_MASK_ETA4_SUB_LIST below:                        *)
(*   idx0 = PACK_MASK8(REJ_MASK_ETA4(SUB_LIST(8*i,4) inlist))                 *)
(*        = PACK_MASK8(SUB_LIST(16*i,8) mask)                                 *)
(*   idx1 = PACK_MASK8(SUB_LIST(16*i+8,8) mask)                               *)
(*   curlen (store advance base) =                                            *)
(*        NUM_ACCEPTED(REJ_MASK_ETA4(SUB_LIST(0,8*i) inlist))                 *)
(*      = NUM_ACCEPTED(SUB_LIST(0,16*i) mask)                                 *)
(* The `inlist`-only parts (curlist = REJ_NIBBLES_ETA4 .., memory contents)   *)
(* keep `inlist`; they never enter the event LHS.                             *)
(* -------------------------------------------------------------------------- *)

(* byte-index SUB_LIST maps to a nibble-index SUB_LIST at 2x offset/length.   *)
let NIBBLES_OF_BYTES_SUB_LIST = prove
 (`!l a b. NIBBLES_OF_BYTES(SUB_LIST(a,b) l) =
           SUB_LIST(2*a,2*b)(NIBBLES_OF_BYTES l)`,
  LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; SUB_LIST_CLAUSES; APPEND;
              MULT_CLAUSES; ADD_CLAUSES; ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`] THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES; APPEND]);;

(* General-offset MAP/SUB_LIST commutation (aarch64_utils' SUB_LIST_MAP is    *)
(* prefix-only, (0,n)).                                                       *)
let SUB_LIST_MAP_GEN = prove
 (`!(f:A->B) l a b. SUB_LIST(a,b)(MAP f l) = MAP f (SUB_LIST(a,b) l)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[MAP; SUB_LIST_CLAUSES]);;

(* THE mask-level length-doubling commutation: converts a hardware            *)
(* REJ_MASK_ETA4(SUB_LIST(a,b) inlist) into a SUB_LIST of the ATOMIC mask —   *)
let REJ_MASK_ETA4_SUB_LIST = prove
 (`!l a b. REJ_MASK_ETA4(SUB_LIST(a,b) l) = SUB_LIST(2*a,2*b)(REJ_MASK_ETA4 l)`,
  REWRITE_TAC[REJ_MASK_ETA4; NIBBLES_OF_BYTES_SUB_LIST; SUB_LIST_MAP_GEN]);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* The number of loop8 iterations is data-dependent but PUBLIC: a function of *)
(* the public buflen and the public reject mask ONLY (never the accepted      *)
(* values). It equals MEMSAFE's WOP-defined N (rej_uniform_eta4_aarch64_asm   *)
(* .ml:2442): the least n at which EITHER the input is exhausted (val buflen  *)
(* < 8*(n+1)) OR the output is full (256 <= accepted-so-far). Each loop       *)
(* iteration consumes 8 bytes = 16 nibbles, and the accepted count after n    *)
(* iterations = NUM_ACCEPTED of the first 16n mask bits, because              *)
(* LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8n) inlist)) =                          *)
(* NUM_ACCEPTED(SUB_LIST(0,16n)(REJ_MASK_ETA4 inlist)) [s117 count bridge].   *)
(* So this is exactly MEMSAFE's N whenever mask = REJ_MASK_ETA4 inlist, and   *)
(* it is expressed WITHOUT reference to inlist (secret-independent).          *)
(* -------------------------------------------------------------------------- *)

let MLDSA_ETA4_LOOP8_TRIP = define
  `MLDSA_ETA4_LOOP8_TRIP (buflen:int64) (mask:bool list) : num =
     minimal n. val buflen < 8 * (n + 1) \/
                256 <= NUM_ACCEPTED (SUB_LIST(0,16 * n) mask)`;;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* This is the analytical crux of loop8's DUAL-EXIT closure. loop8 exits when *)
(* EITHER the input is exhausted (remaining < 8, i.e. val buflen < 8*(i+1))   *)
(* OR the output is full (256 <= accepted so far). In the prove PC = (if i+1  *)
(* < TRIP then pc1 else pc2), which requires connecting the two HARDWARE      *)
(* branch conditions (X2<8 at the bottom b.hs 0xf8; X9>=256 at the top b.hs   *)
(* 0x6c) to the arithmetic predicate i+1 < TRIP. This lemma is exactly that   *)
(* connector, derived from the minimality of TRIP:                            *)
(*   - part 1 (the exit disjunction AT the trip point) tells the exit tail    *)
(*     WHICH branch fired (input-exhaust vs output-full = which EventJump     *)
(*     list the last iteration emits);                                        *)
(*   - part 2 (neither condition holds strictly BELOW the trip point) is the  *)
(*     "we execute iteration i" fact — it kills the top b.hs (curlen<256, so  *)
(*     0x6c falls through to 0x70) and guarantees the bottom b.hs is taken    *)
(*     back to 0x68 for every non-final iteration, exactly MEMSAFE's          *)
(*     invariant conjuncts `curlen < 256` (eta4.ml:2504) and `8*(i+1) <=      *)
(*     buflen` (eta4.ml:2508), but stated over the PUBLIC atomic mask via the *)
(*     s117 count bridge (LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,8i) inlist)) =   *)
(*     NUM_ACCEPTED(SUB_LIST(0,16i)(REJ_MASK_ETA4 inlist))) rather than the   *)
(*     secret niblen.  Pure arithmetic on `minimal` (MINIMAL); no SIMD.       *)
(* -------------------------------------------------------------------------- *)

let MLDSA_ETA4_LOOP8_TRIP_MINIMAL = prove
 (`!(buflen:int64) (mask:(bool)list).
     (val buflen < 8 * (MLDSA_ETA4_LOOP8_TRIP buflen mask + 1) \/
      256 <= NUM_ACCEPTED(SUB_LIST(0,16 * MLDSA_ETA4_LOOP8_TRIP buflen mask) mask)) /\
     (!i. i < MLDSA_ETA4_LOOP8_TRIP buflen mask
          ==> ~(val buflen < 8 * (i + 1)) /\
              ~(256 <= NUM_ACCEPTED(SUB_LIST(0,16 * i) mask)))`,
  REPEAT GEN_TAC THEN REWRITE_TAC[MLDSA_ETA4_LOOP8_TRIP] THEN
  SUBGOAL_THEN
    `?n. val(buflen:int64) < 8 * (n + 1) \/ 256 <= NUM_ACCEPTED(SUB_LIST(0,16 * n) mask)`
    ASSUME_TAC THENL
   [EXISTS_TAC `val(buflen:int64)` THEN DISJ1_TAC THEN ARITH_TAC; ALL_TAC] THEN
  FIRST_X_ASSUM(STRIP_ASSUME_TAC o REWRITE_RULE[MINIMAL]) THEN
  ASM_REWRITE_TAC[] THEN
  X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM DE_MORGAN_THM] THEN FIRST_X_ASSUM MATCH_MP_TAC THEN
  ASM_REWRITE_TAC[]);;

(* -------------------------------------------------------------------------- *)
(* MATERIALIZED + mask-bridge demonstrated end-to-end (not just asserted).    *)
(*                                                                            *)
(* EVENT VOCABULARY (confirmed from arm/proofs/instruction.ml + live steps):  *)
(*   EventLoad (addr:int64, size:num)   EventStore (addr:int64, size:num)     *)
(*   EventJump (pc:int64, pc_next:int64)   -- all accumulate via CONS.        *)
(*   arm_Bcond (instruction.ml:997): EVERY conditional branch (taken OR not-  *)
(*   taken) emits CONS(EventJump(pc, pc_next)) where pc_next is the symbolic  *)
(*   `if <cond> then <target> else <pc+4>`. A symbolic-condition branch steps *)
(*   to a CLEAN `if`-term for BOTH read PC and the EventJump target.          *)
(*                                                                            *)
(*   read events s = CONS (EventStore (sp + 2*curlen, 16))          [st1 0xdc]*)
(*     (CONS (EventLoad (table + 16*val idx1, 16))                  [ldr 0xb8]*)
(*     (CONS (EventLoad (table + 16*val idx0, 16))                  [ldr 0xb4]*)
(*     (CONS (EventLoad (buf + 8*i, 8)) e0)))                       [ld1 0x74]*)
(*   Second store (0xe4) is EventStore(sp + 2*(curlen + val len0), 16), after *)
(*   `add x7,x7,x12,lsl#1`. So the full per-iteration f_ev_loop8 = the 3 loads*)
(*   + 2 stores + the trailing branch EventJump(s), all as CONS on e0.        *)
(*                                                                            *)
(* MASK BRIDGE demonstrated LIVE (the s124 "integration asserted not          *)
(* demonstrated" gap is now CLOSED at the compute half): after the MEMSAFE    *)
(* simp chain (eta4.ml:2564-2569), the live idx0 = read X12 collapses to      *)
(* EXACTLY UADDLV_PACK_LEMMA's LHS shape                                      *)
(*   val(word_zx(word_subword(word_add(...word_and Q31                        *)
(*     (word_join.. word_neg(word(bitval(val(word_subword nibbles0 (k,16))<15)))))))) *)
(* machinery + REJ_MASK_ETA4_SUB_LIST + `REJ_MASK_ETA4 inlist = mask` give    *)
(*   val idx0 = PACK_MASK8(SUB_LIST(16*i,8) mask)                             *)
(*   val idx1 = PACK_MASK8(SUB_LIST(16*i+8,8) mask)                           *)
(*   curlen   = NUM_ACCEPTED(SUB_LIST(0,16*i) mask)                           *)
(*   val len0 = NUM_ACCEPTED(SUB_LIST(16*i,8) mask)                           *)
(* mask), so f_ev_loop8 (a CONCRETIZE meta-var) auto-instantiates via         *)
(* REJECT-MASK, demonstrated. (Accepted VALUES never enter the trace.)        *)
(*                                                                            *)
(*     add x7; add x12; add x9; cmp x2,#8].                                   *)
(* BEFORE `add x7`. (b) stores need `nonoverlapping (word pc,344)             *)
(* (stackpointer,576)` in context (from the theorem's ALL clause) AND the 2nd *)
(* store additionally needs val len0<=8 (UADDLV_BOUND_LEMMA) + the MEMSAFE    *)
(* WORD_ADD_SHL1 rewrite (eta4.ml:2971) on the word_shl'd X7 offset, else     *)
(* "could not prove updates will not modify the program code".                *)
(*                                                                            *)
(* `8 <= val(read X2 <after>)`:                                               *)
(*   * remaining>=8 (input not exhausted): step 0x68 (cmp x9,x4), 0x6c (b.cs, *)
(*   if val buflen < 8*(i+2) then <CaseB list> else <remaining>=8 list>       *)
(* the theorem's loop8 leaf; connect 256<=val(curlen') and remaining bounds   *)
(* to `i+1<k` via MLDSA_ETA4_LOOP8_TRIP + the count bridge, keeping mask      *)
(* -------------------------------------------------------------------------- *)

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* OBLIVIOUS but its back-edge is a SIGNED `cmp x11,#256; b.lt` whose         *)
(* symbolic-i flag condition the stepper leaves in raw `ival` form. MEMSAFE   *)
(* we prove the branch equivalence once. ZINIT_BRANCH says the raw b.lt       *)
(* condition on the post-increment counter 32*(i+1) equals the loop bound     *)
(* i+1<8, given i<8. IVAL_WORD_SMALL is the standard `ival(word m)=&m` for m  *)
(* below the signed bound (2^63), used to evaluate both compared operands.    *)
(* -------------------------------------------------------------------------- *)

let IVAL_WORD_SMALL = prove
 (`!m. m < 2 EXP 63 ==> ival(word m:int64) = &m`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word m:int64) = m` ASSUME_TAC THENL
   [REWRITE_TAC[VAL_WORD; DIMINDEX_64] THEN MATCH_MP_TAC MOD_LT THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `~bit 63 (word m:int64)` ASSUME_TAC THENL
   [REWRITE_TAC[BIT_WORD; DIMINDEX_64] THEN
    SUBGOAL_THEN `m DIV 2 EXP 63 = 0` SUBST1_TAC THENL
     [MATCH_MP_TAC DIV_LT THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  ASM_REWRITE_TAC[IVAL_VAL; DIMINDEX_64; ARITH_RULE `64 - 1 = 63`;
                  BITVAL_CLAUSES] THEN
  INT_ARITH_TAC);;

(* The signed b.lt back-edge condition for the zero-init counter: given i<8   *)
(* (loop bound), the raw stepper flag condition on 32*(i+1) is equivalent to  *)
(* the loop-continuation predicate i+1<8. This is what the loop-body PC leaf  *)
let ZINIT_BRANCH = prove
 (`!i. i < 8 ==>
     (~(ival (word_add (word (32 * i)) (word 18446744073709551392):int64) < &0 <=>
        ~(ival (word_add (word (32 * i)) (word 32):int64) - &256 =
          ival (word_add (word (32 * i)) (word 18446744073709551392):int64)))
      <=> i + 1 < 8)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN
    `ival (word_add (word (32 * i)) (word 32):int64) = &(32 * i) + &32`
    SUBST1_TAC THENL
   [SUBGOAL_THEN `word_add (word (32*i)) (word 32):int64 = word(32*i+32)`
      SUBST1_TAC THENL [CONV_TAC WORD_RULE; ALL_TAC] THEN
    SUBGOAL_THEN `ival(word(32*i+32):int64) = &(32*i+32)`
      (fun th -> REWRITE_TAC[th; GSYM INT_OF_NUM_ADD]) THEN
    MATCH_MP_TAC IVAL_WORD_SMALL THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `ival (word_add (word (32 * i)) (word 18446744073709551392):int64) =
     &(32 * i) - &224`
    SUBST1_TAC THENL
   [SUBGOAL_THEN
      `word_add (word (32*i)) (word 18446744073709551392):int64 =
       iword(&(32*i) - &224)` SUBST1_TAC THENL
     [REWRITE_TAC[IWORD_INT_SUB; GSYM WORD_IWORD] THEN
      REWRITE_TAC[WORD_RULE `word_sub a (b:int64) = word_add a (word_neg b)`] THEN
      AP_TERM_TAC THEN CONV_TAC WORD_REDUCE_CONV; ALL_TAC] THEN
    MATCH_MP_TAC IVAL_IWORD THEN REWRITE_TAC[DIMINDEX_64] THEN
    ASM_SIMP_TAC[GSYM INT_OF_NUM_MUL; GSYM INT_OF_NUM_LT] THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(&(32 * i) + &32) - &256 = &(32 * i) - &224:int` SUBST1_TAC THENL
   [INT_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[] THEN
  REWRITE_TAC[INT_ARITH `(x:int) - &224 < &0 <=> x < &224`;
              GSYM INT_OF_NUM_MUL; GSYM INT_OF_NUM_LT] THEN
  ARITH_TAC);;

(* The signed b.lt back-edge condition for the FINAL-COPY (fcopy) counter:    *)
(* given i<16 (loop bound), the raw stepper flag condition on the             *)
(* post-increment counter 16*(i+1) is equivalent to the loop-continuation     *)
(* predicate i+1<16. This is FCOPY's analogue of ZINIT_BRANCH (32*(i+1) vs    *)
(* 8): 16*(i+1) vs 256, -240 = word 18446744073709551376 (= 16 - 256 in two's *)
(* complement).                                                               *)
let FCOPY_BRANCH = prove
 (`!i. i < 16 ==>
     (~(ival (word_add (word (16 * i)) (word 18446744073709551376):int64) < &0 <=>
        ~(ival (word_add (word (16 * i)) (word 16):int64) - &256 =
          ival (word_add (word (16 * i)) (word 18446744073709551376):int64)))
      <=> i + 1 < 16)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN
    `ival (word_add (word (16 * i)) (word 16):int64) = &(16 * i) + &16`
    SUBST1_TAC THENL
   [SUBGOAL_THEN `word_add (word (16*i)) (word 16):int64 = word(16*i+16)`
      SUBST1_TAC THENL [CONV_TAC WORD_RULE; ALL_TAC] THEN
    SUBGOAL_THEN `ival(word(16*i+16):int64) = &(16*i+16)`
      (fun th -> REWRITE_TAC[th; GSYM INT_OF_NUM_ADD]) THEN
    MATCH_MP_TAC IVAL_WORD_SMALL THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `ival (word_add (word (16 * i)) (word 18446744073709551376):int64) =
     &(16 * i) - &240`
    SUBST1_TAC THENL
   [SUBGOAL_THEN
      `word_add (word (16*i)) (word 18446744073709551376):int64 =
       iword(&(16*i) - &240)` SUBST1_TAC THENL
     [REWRITE_TAC[IWORD_INT_SUB; GSYM WORD_IWORD] THEN
      REWRITE_TAC[WORD_RULE `word_sub a (b:int64) = word_add a (word_neg b)`] THEN
      AP_TERM_TAC THEN CONV_TAC WORD_REDUCE_CONV; ALL_TAC] THEN
    MATCH_MP_TAC IVAL_IWORD THEN REWRITE_TAC[DIMINDEX_64] THEN
    ASM_SIMP_TAC[GSYM INT_OF_NUM_MUL; GSYM INT_OF_NUM_LT] THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(&(16 * i) + &16) - &256 = &(16 * i) - &240:int` SUBST1_TAC THENL
   [INT_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[] THEN
  REWRITE_TAC[INT_ARITH `(x:int) - &240 < &0 <=> x < &240`;
              GSYM INT_OF_NUM_MUL; GSYM INT_OF_NUM_LT] THEN
  ARITH_TAC);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* These two word-arith lemmas are the ONLY analytical pieces (beyond the     *)
(* already-landed MLDSA_ETA4_LOOP8_TRIP_MINIMAL) needed to discharge loop8's  *)
(*                                                                            *)
(*   BOTTOM branch (0xf4 cmp x2,#8 ; 0xf8 b.cs 0x68), x2 = buflen-8*(i+1):    *)
(*     live form:  read PC = if 8 <= val(word_sub buflen (word(8*(i+1))))     *)
(*                          then word(pc+108)[=0x68] else word(pc+256)[=0xfc] *)
(*     LOOP8_BOT_VAL_BRIDGE turns the hw cond into ~(val buflen < 8*(i+2))    *)
(*     (input-exhaust), given the invariant fact 8*(i+1) <= val buflen        *)
(*     (= MINIMAL part 2 at j=i, i.e. ~(val buflen < 8*(i+1))).               *)
(*                                                                            *)
(*   TOP branch (0x68 cmp x9,x4=256 ; 0x6c b.cs 0xfc), x9 = curlen' =         *)
(*     word(NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)):                         *)
(*     live form:  read PC = if 256 <= val(word(NUM_ACCEPTED(...)))           *)
(*                          then word(pc+256)[=0xfc] else word(pc+116)[=0x70] *)
(*     LOOP8_TOP_VAL_BRIDGE turns the hw cond into 256 <= NUM_ACCEPTED(...)   *)
(*     (output-full), given NUM_ACCEPTED(...) < 2^64 (from the loop invariant *)
(*     conjunct curlen' < 256+8 that mirrors MEMSAFE's niblen<256, eta4.ml    *)
(*     :2504 — MUST be added to the loop8 UP2 invariant).                     *)
(* -------------------------------------------------------------------------- *)

let LOOP8_TOP_VAL_BRIDGE = prove
 (`!n. n < 2 EXP 64 ==> (256 <= val(word n:int64) <=> 256 <= n)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word n:int64) = n` SUBST1_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN ASM_REWRITE_TAC[DIMINDEX_64]; ALL_TAC] THEN
  REWRITE_TAC[]);;

let LOOP8_BOT_VAL_BRIDGE = prove
 (`!(buflen:int64) i. 8*(i+1) <= val buflen
     ==> (8 <= val(word_sub buflen (word(8*(i+1))):int64) <=> ~(val buflen < 8*(i+2)))`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word(8*(i+1)):int64) = 8*(i+1)` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN
    MP_TAC(ISPEC `buflen:int64` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_64] THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[VAL_WORD_SUB_CASES] THEN ASM_ARITH_TAC);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* This is the analytical core of the loop8 tail-close PC obligation. It      *)
(* connects the TOP branch's hardware condition (256 <= curlen', where        *)
(* curlen' = NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask) is the accepted count    *)
(* after iteration i) to the loop-exit predicate ~(i+1 < TRIP), GIVEN the     *)
(* BOTTOM branch fell through to the top check (input not exhausted at i+1,   *)
(* i.e. ~(val buflen < 8*(i+2))). Both directions follow from                 *)
(* MLDSA_ETA4_LOOP8_TRIP_MINIMAL:                                             *)
(*   (<=)  ~(i+1<TRIP) => i+1 = TRIP (with i<TRIP); part 1 at TRIP gives      *)
(*         input-exhaust OR output-full; input-not-exhausted (hyp) forces     *)
(*         output-full (256 <= curlen').                                      *)
(*   (=>)  256 <= curlen' with i+1<TRIP contradicts part 2 at i+1             *)
(*         (~(256 <= NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask))).               *)
(* Pure arithmetic on MINIMAL; no SIMD. This is exactly the "which arm"       *)
(* -------------------------------------------------------------------------- *)

let LOOP8_OUTPUT_FULL_IFF = prove
 (`!(buflen:int64) mask i.
     i < MLDSA_ETA4_LOOP8_TRIP buflen mask /\
     ~(val buflen < 8 * (i + 2))
     ==> (256 <= NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask) <=>
          ~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(SPECL[`buflen:int64`;`mask:(bool)list`] MLDSA_ETA4_LOOP8_TRIP_MINIMAL) THEN
  DISCH_THEN(CONJUNCTS_THEN2 ASSUME_TAC (LABEL_TAC "PT2")) THEN
  ASM_CASES_TAC `i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask` THENL
   [ASM_REWRITE_TAC[] THEN
    USE_THEN "PT2" (MP_TAC o SPEC `i + 1`) THEN ANTS_TAC THENL
     [ASM_REWRITE_TAC[]; DISCH_THEN(fun th -> REWRITE_TAC[CONJUNCT2 th])];
    SUBGOAL_THEN `i + 1 = MLDSA_ETA4_LOOP8_TRIP buflen mask` ASSUME_TAC THENL
     [MAP_EVERY UNDISCH_TAC
        [`i < MLDSA_ETA4_LOOP8_TRIP buflen mask`;
         `~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask)`] THEN ARITH_TAC;
      ALL_TAC] THEN
    ASM_REWRITE_TAC[] THEN
    FIRST_ASSUM(DISJ_CASES_TAC o check (is_disj o concl)) THEN ASM_ARITH_TAC]);;

let MLDSA_ETA4_LOOP8_TAIL_CLOSE = prove
 (`!res (buf:int64) (buflen:int64) table mask pc i (e:(uarch_event)list) stackpointer
     (tabval:num) (bufval:num) (returnaddress:int64).
    i < MLDSA_ETA4_LOOP8_TRIP buflen mask /\
    NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask) < 2 EXP 64
    ==> ensures arm
         (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
              read PC s = word (pc + 0xf8) /\
              read SP s = word_sub stackpointer (word 576) /\
              read X30 s = returnaddress /\
              read X0 s = res /\
              read X1 s = word_add buf (word(8*(i+1))) /\
              read X2 s = word_sub buflen (word(8*(i+1))) /\
              read X3 s = table /\
              read X4 s = word 256 /\
              read X7 s = word_add (word_sub stackpointer (word 576))
                                   (word(2 * NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask))) /\
              read X8 s = word_sub stackpointer (word 576) /\
              read X9 s = word (NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)) /\
              read Q30 s = word 46731384791156575435574448262545417 /\
              read Q31 s = word 664619068533544770747334646890102785 /\
              read (memory :> bytes(table,4096)) s = tabval /\
              read (memory :> bytes(buf, val buflen)) s = bufval /\
              read events s = e)
         (\s. read PC s =
                word (pc + (if i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask then 0x74 else 0x100)) /\
              read SP s = word_sub stackpointer (word 576) /\
              read X30 s = returnaddress /\
              read X0 s = res /\
              read X1 s = word_add buf (word(8*(i+1))) /\
              read X2 s = word_sub buflen (word(8*(i+1))) /\
              read X3 s = table /\
              read X4 s = word 256 /\
              read X7 s = word_add (word_sub stackpointer (word 576))
                                   (word(2 * NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask))) /\
              read X8 s = word_sub stackpointer (word 576) /\
              read X9 s = word (NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)) /\
              read Q30 s = word 46731384791156575435574448262545417 /\
              read Q31 s = word 664619068533544770747334646890102785 /\
              read (memory :> bytes(table,4096)) s = tabval /\
              read (memory :> bytes(buf, val buflen)) s = bufval /\
              read events s =
                APPEND
                 (if 8 <= val(word_sub buflen (word(8*(i+1))):int64)
                  then [EventJump(word(pc+112),
                          (if 256 <= val(word(NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)):int64)
                           then word(pc+256) else word(pc+116)));
                        EventJump(word(pc+252), word(pc+108))]
                  else [EventJump(word(pc+252), word(pc+256))]) e)
         (\s s'. T)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `8 * (i + 1) <= val(buflen:int64)` ASSUME_TAC THENL
   [MP_TAC(SPECL[`buflen:int64`;`mask:(bool)list`] MLDSA_ETA4_LOOP8_TRIP_MINIMAL) THEN
    DISCH_THEN(MP_TAC o SPEC `i:num` o CONJUNCT2) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN(MP_TAC o CONJUNCT1) THEN ARITH_TAC;
    ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
  ASM_CASES_TAC `8 <= val(word_sub buflen (word(8*(i+1))):int64)` THENL
   [UNDISCH_TAC `8 <= val(word_sub buflen (word(8*(i+1))):int64)` THEN
    DISCH_THEN(fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th]) THEN ASSUME_TAC th) THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (3--4) THEN
    SUBGOAL_THEN
      `256 <= val(word(NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)):int64) <=>
       ~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask)` ASSUME_TAC THENL
     [ASM_SIMP_TAC[LOOP8_TOP_VAL_BRIDGE] THEN
      MATCH_MP_TAC LOOP8_OUTPUT_FULL_IFF THEN
      ASM_MESON_TAC[LOOP8_BOT_VAL_BRIDGE];
      ALL_TAC] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[APPEND] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[];
    SUBGOAL_THEN `val (buflen:int64) < 8 * (i + 2)` ASSUME_TAC THENL
     [UNDISCH_TAC `~(8 <= val(word_sub buflen (word(8*(i+1))):int64))` THEN
      ASM_SIMP_TAC[LOOP8_BOT_VAL_BRIDGE]; ALL_TAC] THEN
    SUBGOAL_THEN `~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask)` ASSUME_TAC THENL
     [DISCH_TAC THEN
      MP_TAC(SPECL[`buflen:int64`;`mask:(bool)list`] MLDSA_ETA4_LOOP8_TRIP_MINIMAL) THEN
      DISCH_THEN(MP_TAC o SPEC `i + 1` o CONJUNCT2) THEN
      ASM_REWRITE_TAC[ARITH_RULE `8 * ((i + 1) + 1) = 8 * (i + 2)`]; ALL_TAC] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[APPEND]]);;

(* Count-bridge for the loop8 per-iteration accepted count (final X9 value    *)
(* and the 2nd stack-store address): the accepted-count after i+1 groups =    *)
(* the count after i groups + the two 4-byte-half counts of group i. Pure     *)
(* list                                                                       *)
let NUM_ACCEPTED_SUB_LIST_STEP = prove
 (`!(mask:bool list) i.
     NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask) =
     NUM_ACCEPTED(SUB_LIST(0,16*i) mask) +
     NUM_ACCEPTED(SUB_LIST(16*i,8) mask) +
     NUM_ACCEPTED(SUB_LIST(16*i+8,8) mask)`,
  REPEAT GEN_TAC THEN
  ASSUME_TAC(REWRITE_RULE[ADD_CLAUSES; ARITH_RULE `8+8=16`]
    (ISPECL[`mask:bool list`;`8`;`8`;`16*i:num`] SUB_LIST_SPLIT)) THEN
  ASSUME_TAC(REWRITE_RULE[ADD_CLAUSES]
    (ISPECL[`mask:bool list`;`16*i:num`;`16`;`0`] SUB_LIST_SPLIT)) THEN
  ASM_REWRITE_TAC[ARITH_RULE `16*(i+1) = 16*i+16`; NUM_ACCEPTED_APPEND] THEN
  ARITH_TAC);;

(* Each 4-byte loop8 half-group accepts at most 8 nibbles (LENGTH bound).     *)
(* Used to bound the per-iteration store advance so the 2nd stack store's     *)
(* address stays                                                              *)
let NUM_ACCEPTED_LE_8 = prove
 (`!(m:bool list) a. NUM_ACCEPTED(SUB_LIST(a,8) m) <= 8`,
  REPEAT GEN_TAC THEN REWRITE_TAC[NUM_ACCEPTED] THEN
  MATCH_MP_TAC LE_TRANS THEN
  EXISTS_TAC `LENGTH(SUB_LIST(a,8) (m:bool list))` THEN
  REWRITE_TAC[LENGTH_FILTER; LENGTH_SUB_LIST] THEN ARITH_TAC);;

(* Cancel a prefix of known length off an APPEND equality.                    *)
let APPEND_EQ_LEN = prove
 (`!l1 m1 l2 m2:A list. LENGTH l1 = LENGTH m1
     ==> (APPEND l1 l2 = APPEND m1 m2 <=> l1 = m1 /\ l2 = m2)`,
  LIST_INDUCT_TAC THEN LIST_INDUCT_TAC THEN
  REWRITE_TAC[LENGTH; NOT_SUC; SUC_INJ; APPEND; CONS_11] THEN
  REPEAT STRIP_TAC THEN ASM_MESON_TAC[]);;

(* Split a known 8-element SUB_LIST into its two 4-element halves (the loop8  *)
(* group is 8 bytes = two 4-byte lanes feeding idx0 and idx1 respectively).   *)
let SUB_LIST_4_FROM_8 = prove
 (`!(l:A list) a x0 x1 x2 x3 x4 x5 x6 x7.
     SUB_LIST(a,8) l = [x0;x1;x2;x3;x4;x5;x6;x7]
     ==> SUB_LIST(a,4) l = [x0;x1;x2;x3] /\ SUB_LIST(a+4,4) l = [x4;x5;x6;x7]`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `8 <= LENGTH(l:A list) - a` ASSUME_TAC THENL
   [FIRST_ASSUM(MP_TAC o AP_TERM `LENGTH:A list->num`) THEN
    REWRITE_TAC[LENGTH_SUB_LIST; LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `APPEND (SUB_LIST(a,4)(l:A list)) (SUB_LIST(a+4,4) l) =
                [x0;x1;x2;x3;x4;x5;x6;x7]` MP_TAC THENL
   [FIRST_X_ASSUM(fun th -> REWRITE_TAC[SYM th]) THEN
    MP_TAC(ISPECL[`l:A list`;`4`;`4`;`a:num`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ARITH_RULE `4+4=8`] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC;
    ALL_TAC] THEN
  MP_TAC(ISPECL[`SUB_LIST(a,4)(l:A list)`;`[x0;x1;x2;x3]:A list`;
                `SUB_LIST(a+4,4)(l:A list)`;`[x4;x5;x6;x7]:A list`] APPEND_EQ_LEN) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV THEN
    ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[APPEND] THEN DISCH_THEN(fun th -> ONCE_REWRITE_TAC[GSYM th]) THEN
  DISCH_THEN ACCEPT_TAC);;

(* Expand the reject mask of an explicit 4-byte group into the 8 per-nibble   *)
(* accept predicates (low then high nibble of each byte, matching the SIMD    *)
(* lane order after the AND/USHR/ZIP/UXTL chain).                             *)
let MASK_SLICE_4 = prove
 (`!(l:byte list) a b0 b1 b2 b3.
     SUB_LIST(a,4) l = [b0;b1;b2;b3]
     ==> REJ_MASK_ETA4(SUB_LIST(a,4) l) =
         [val b0 MOD 16 < 9; val b0 DIV 16 < 9; val b1 MOD 16 < 9; val b1 DIV 16 < 9;
          val b2 MOD 16 < 9; val b2 DIV 16 < 9; val b3 MOD 16 < 9; val b3 DIV 16 < 9]`,
  REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[REJ_MASK_ETA4; NIBBLES_OF_BYTES_4; MAP] THEN
  REWRITE_TAC[VAL_WORD_NIBBLE_LT]);;

(* --- self-contained helper tactics for the COMPUTE proof ---                *)
let bitblast8_compute = List.map (fun k -> BITBLAST_RULE (vsubst[mk_small_numeral k,`k:num`]
   `bit k (word_subword (word_neg (word (bitval b):16 word)) (0,8):8 word) <=> b`)) (0--7);;

(* rewrite the goal with (mk th) for every assumption where mk succeeds       *)
let COLLECT_COMPUTE (mk:thm->thm) : tactic = fun (asl,w) ->
  REWRITE_TAC(List.filter_map (fun (_,th) -> try Some(mk th) with _ -> None) asl) (asl,w);;

let is_nibvar_compute v = (try let n = fst(dest_var v) in n="nibbles0"||n="nibbles1b" with _ -> false);;
let NIBGSYM_COMPUTE : tactic = COLLECT_COMPUTE (fun th ->
  match lhs(concl th) with
  | Comb(Comb(Const("word_subword",_),v),_) when is_nibvar_compute v -> GSYM th
  | _ -> failwith "no");;
(* MASK_SLICE_4 applied to each SUB_LIST(_,4) assumption                      *)
let MASKSLICE_COMPUTE : tactic = COLLECT_COMPUTE (fun th -> MATCH_MP MASK_SLICE_4 th);;
let is_sub4_compute c = is_eq c && (try let (f,a)=strip_comb(lhs c) in
   fst(dest_const f)="SUB_LIST" && dest_small_numeral(snd(dest_pair(hd a)))=4 with _ -> false);;
let SUB4GSYM_COMPUTE : tactic = COLLECT_COMPUTE (fun th -> if is_sub4_compute(concl th) then GSYM th else failwith "no");;

(* find first assumption whose conclusion satisfies p, apply f to it          *)
let W_ASM_COMPUTE p (f:thm->tactic) : tactic = fun (asl,w) ->
  f (snd(List.find (fun (_,th) -> try p(concl th) with _ -> false) asl)) (asl,w);;

(* the 16 per-nibble facts word_subword nibbles0/1b (16k,16) =                *)
(* word_zx(word_and/ushr..)                                                   *)
let PROVE_HW_ALL_COMPUTE : tactic =
  let prove_hw name pos byte_pos op =
    let rhs_inner = if op = "and"
      then Printf.sprintf
        "(word_and (word_subword (loaded_d:int64) (%d,8):byte) (word 15):byte)" byte_pos
      else Printf.sprintf
        "(word_ushr (word_subword (loaded_d:int64) (%d,8):byte) 4:byte)" byte_pos in
    let goal_str = Printf.sprintf
      "(word_subword (%s:int128) (%d,16)):int16 = word_zx %s :int16" name pos rhs_inner in
    SUBGOAL_THEN (parse_term goal_str) ASSUME_TAC THENL
     [FIRST_X_ASSUM(MP_TAC o SYM o check
         (fun th -> let c = concl th in is_eq c &&
           (try fst(dest_var(rhs c)) = name with _ -> false) &&
           (match lhs c with Comb(Comb(Const("read",_),_),_)->false|_->true))) THEN
      DISCH_THEN(fun th -> SUBST1_TAC th THEN ASSUME_TAC(SYM th)) THEN
      CONV_TAC WORD_BLAST;
      ALL_TAC] in
  prove_hw "nibbles0" 0 0 "and" THEN prove_hw "nibbles0" 16 0 "ushr" THEN
  prove_hw "nibbles0" 32 8 "and" THEN prove_hw "nibbles0" 48 8 "ushr" THEN
  prove_hw "nibbles0" 64 16 "and" THEN prove_hw "nibbles0" 80 16 "ushr" THEN
  prove_hw "nibbles0" 96 24 "and" THEN prove_hw "nibbles0" 112 24 "ushr" THEN
  prove_hw "nibbles1b" 0 32 "and" THEN prove_hw "nibbles1b" 16 32 "ushr" THEN
  prove_hw "nibbles1b" 32 40 "and" THEN prove_hw "nibbles1b" 48 40 "ushr" THEN
  prove_hw "nibbles1b" 64 48 "and" THEN prove_hw "nibbles1b" 80 48 "ushr" THEN
  prove_hw "nibbles1b" 96 56 "and" THEN prove_hw "nibbles1b" 112 56 "ushr";;

(* the postcondition fold: normalise driven state + target to a common form   *)
let POSTCOND_FOLD_COMPUTE : tactic = fun (asl,w) ->
  let find p = snd(List.find (fun (_,th) -> try p(concl th) with _ -> false) asl) in
  let maskeq  = find (fun c -> c = `mask:(bool)list = REJ_MASK_ETA4 inlist`) in
  let curleneq= find (fun c -> c = `NUM_ACCEPTED (SUB_LIST (0,16 * i) mask) = curlen`) in
  let len0na  = find (fun c -> c = `val(len0:int64) = NUM_ACCEPTED (SUB_LIST (16 * i,8) mask)`) in
  let len1na  = find (fun c -> c = `val(len1:int64) = NUM_ACCEPTED (SUB_LIST (16 * i + 8,8) mask)`) in
  let is_lenlen v c = is_eq c && lhs c = v &&
     (try fst(dest_const(fst(strip_comb(rhs c))))="LENGTH" with _->false) in
  let len0len = find (is_lenlen `val(len0:int64)`) in
  let len1len = find (is_lenlen `val(len1:int64)`) in
  (REWRITE_TAC[GSYM maskeq] THEN REWRITE_TAC[NUM_ACCEPTED_SUB_LIST_STEP] THEN
   REWRITE_TAC[GSYM len0len; GSYM len1len] THEN REWRITE_TAC[curleneq] THEN
   REWRITE_TAC[GSYM len0na; GSYM len1na] THEN
   REWRITE_TAC[ARITH_RULE `8*(i+1) = 8*i+8`; APPEND] THEN
   REPEAT CONJ_TAC THEN TRY(CONV_TAC WORD_RULE) THEN TRY REFL_TAC) (asl,w);;

let MLDSA_ETA4_LOOP8_COMPUTE = prove
 (`!res (buf:int64) (buflen:int64) (table:int64) (inlist:byte list) (mask:(bool)list)
    (pc:num) (i:num) (e:(uarch_event)list) (stackpointer:int64) (tabval:num)
    (returnaddress:int64).
      mask = REJ_MASK_ETA4 inlist /\
      LENGTH inlist = val buflen /\
      8 * (i + 1) <= val buflen /\
      NUM_ACCEPTED(SUB_LIST(0,16 * i) mask) < 256 /\
      ALL (nonoverlapping (word_sub stackpointer (word 576),576))
          [(word pc,344); (buf,val buflen); (table,4096)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word (pc + 0x74) /\
                read SP s = word_sub stackpointer (word 576) /\
                read X30 s = returnaddress /\
                read X0 s = res /\
                read X1 s = word_add buf (word(8 * i)) /\
                read X2 s = word_sub buflen (word(8 * i)) /\
                read X3 s = table /\
                read X4 s = word 256 /\
                read X7 s = word_add (word_sub stackpointer (word 576))
                                     (word(2 * NUM_ACCEPTED(SUB_LIST(0,16 * i) mask))) /\
                read X8 s = word_sub stackpointer (word 576) /\
                read X9 s = word (NUM_ACCEPTED(SUB_LIST(0,16 * i) mask)) /\
                read Q30 s = word 46731384791156575435574448262545417 /\
                read Q31 s = word 664619068533544770747334646890102785 /\
                read (memory :> bytes(table,4096)) s = tabval /\
                read (memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist /\
                read events s = e)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word (pc + 0xf8) /\
                read SP s = word_sub stackpointer (word 576) /\
                read X30 s = returnaddress /\
                read X0 s = res /\
                read X1 s = word_add buf (word(8 * (i + 1))) /\
                read X2 s = word_sub buflen (word(8 * (i + 1))) /\
                read X3 s = table /\
                read X4 s = word 256 /\
                read X7 s = word_add (word_sub stackpointer (word 576))
                                     (word(2 * NUM_ACCEPTED(SUB_LIST(0,16 * (i + 1)) mask))) /\
                read X8 s = word_sub stackpointer (word 576) /\
                read X9 s = word (NUM_ACCEPTED(SUB_LIST(0,16 * (i + 1)) mask)) /\
                read Q30 s = word 46731384791156575435574448262545417 /\
                read Q31 s = word 664619068533544770747334646890102785 /\
                read (memory :> bytes(table,4096)) s = tabval /\
                read (memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist /\
                read events s =
                  APPEND
                   [EventStore (word_add (word_sub stackpointer (word 576))
                       (word(2 * (NUM_ACCEPTED(SUB_LIST(0,16 * i) mask) +
                                  NUM_ACCEPTED(SUB_LIST(16 * i,8) mask)))), 16);
                    EventStore (word_add (word_sub stackpointer (word 576))
                       (word(2 * NUM_ACCEPTED(SUB_LIST(0,16 * i) mask))), 16);
                    EventLoad (word_add table
                       (word(16 * PACK_MASK8(SUB_LIST(16 * i + 8,8) mask))), 16);
                    EventLoad (word_add table
                       (word(16 * PACK_MASK8(SUB_LIST(16 * i,8) mask))), 16);
                    EventLoad (word_add buf (word(8 * i)), 8)]
                   e)
           (\s s'. T)`,
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  ABBREV_TAC `curlen = NUM_ACCEPTED(SUB_LIST(0,16 * i) mask)` THEN
  GHOST_INTRO_TAC `nibbles1:int128` `read Q17` THEN
  ENSURES_INIT_TAC "s0" THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [1] THEN
  ABBREV_TAC `loaded_d:int64 = read (memory :> bytes64 (word_add buf (word (8 * i)))) s1` THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [2] THEN
  ARM_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (3--9) THEN
  REABBREV_TAC `nibbles0:int128 = read Q16 s9` THEN
  REABBREV_TAC `nibbles1b:int128 = read Q17 s9` THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (10--17) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  PROVE_HW_ALL_COMPUTE THEN
  SUBGOAL_THEN
   `SUB_LIST(8 * i,8) inlist =
     [word_subword (loaded_d:int64) (0,8):byte; word_subword loaded_d (8,8);
      word_subword loaded_d (16,8); word_subword loaded_d (24,8);
      word_subword loaded_d (32,8); word_subword loaded_d (40,8);
      word_subword loaded_d (48,8); word_subword loaded_d (56,8)]`
   ASSUME_TAC THENL
   [MP_TAC(SPECL[`buf:int64`;`val(buflen:int64)`;`inlist:byte list`;`i:num`;`s17:armstate`]
      SUB_LIST_8_BYTES_FROM_INT64) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  FIRST_ASSUM(fun th -> STRIP_ASSUME_TAC(MATCH_MP SUB_LIST_4_FROM_8 th)) THEN
  SUBGOAL_THEN `val(read X12 s17:int64) = PACK_MASK8(SUB_LIST(16 * i,8) mask)` ASSUME_TAC THENL
   [W_ASM_COMPUTE (fun c -> is_eq c && lhs c = `read X12 s17:int64`)
      (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [th]) THEN
    REWRITE_TAC[UADDLV_PACK_LEMMA; PACK_CONNECT] THEN AP_TERM_TAC THEN
    SUBGOAL_THEN `SUB_LIST(16 * i,8) mask = REJ_MASK_ETA4(SUB_LIST(8 * i,4) inlist)`
      SUBST1_TAC THENL
     [REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
      ASM_REWRITE_TAC[ARITH_RULE`2*(8*i)=16*i`; ARITH_RULE`2*4=8`]; ALL_TAC] THEN
    MASKSLICE_COMPUTE THEN
    ASM_REWRITE_TAC[VAL_WORD_ZX_BYTE16; BYTE_AND_15_MOD; BYTE_USHR4_DIV]; ALL_TAC] THEN
  SUBGOAL_THEN `val(read X13 s17:int64) = PACK_MASK8(SUB_LIST(16 * i + 8,8) mask)` ASSUME_TAC THENL
   [W_ASM_COMPUTE (fun c -> is_eq c && lhs c = `read X13 s17:int64`)
      (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [th]) THEN
    REWRITE_TAC[UADDLV_PACK_LEMMA; PACK_CONNECT] THEN AP_TERM_TAC THEN
    SUBGOAL_THEN `SUB_LIST(16 * i + 8,8) mask = REJ_MASK_ETA4(SUB_LIST(8 * i + 4,4) inlist)`
      SUBST1_TAC THENL
     [REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
      ASM_REWRITE_TAC[ARITH_RULE`2*(8*i+4)=16*i+8`; ARITH_RULE`2*4=8`]; ALL_TAC] THEN
    MASKSLICE_COMPUTE THEN
    ASM_REWRITE_TAC[VAL_WORD_ZX_BYTE16; BYTE_AND_15_MOD; BYTE_USHR4_DIV]; ALL_TAC] THEN
  MAP_EVERY REABBREV_TAC [`idx0:int64 = read X12 s17`; `idx1:int64 = read X13 s17`] THEN
  MAP_EVERY ABBREV_TAC
   [`tab0:int128 = read(memory :> bytes128(word_add table (word(16 * val(idx0:int64))))) s17`;
    `tab1:int128 = read(memory :> bytes128(word_add table (word(16 * val(idx1:int64))))) s17`] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (18--25) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_SUBWORD_AND]) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  SUBGOAL_THEN `val(read X12 s25:int64) =
     LENGTH(REJ_NIBBLES_ETA4 [word_subword (loaded_d:int64) (0,8):byte;
       word_subword loaded_d (8,8); word_subword loaded_d (16,8);
       word_subword loaded_d (24,8)])` ASSUME_TAC THENL
   [W_ASM_COMPUTE (fun c -> is_eq c && lhs c = `read X12 s25:int64`)
      (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [th]) THEN
    REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; ADD_CLAUSES] THEN
    REWRITE_TAC[POPCOUNT_AND_POWERS] THEN REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
    REWRITE_TAC bitblast8_compute THEN NIBGSYM_COMPUTE THEN
    MP_TAC(SPECL[`nibbles0:int128`; `word_subword (loaded_d:int64) (0,8):byte`;
      `word_subword (loaded_d:int64) (8,8):byte`; `word_subword (loaded_d:int64) (16,8):byte`;
      `word_subword (loaded_d:int64) (24,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN `val(read X12 s25:int64) = NUM_ACCEPTED(SUB_LIST(16 * i,8) mask)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED] THEN AP_TERM_TAC THEN
    SUB4GSYM_COMPUTE THEN REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
    ASM_REWRITE_TAC[ARITH_RULE`2*(8*i)=16*i`; ARITH_RULE`2*4=8`]; ALL_TAC] THEN
  SUBGOAL_THEN `val(read X13 s25:int64) =
     LENGTH(REJ_NIBBLES_ETA4 [word_subword (loaded_d:int64) (32,8):byte;
       word_subword loaded_d (40,8); word_subword loaded_d (48,8);
       word_subword loaded_d (56,8)])` ASSUME_TAC THENL
   [W_ASM_COMPUTE (fun c -> is_eq c && lhs c = `read X13 s25:int64`)
      (fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [th]) THEN
    REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; ADD_CLAUSES] THEN
    REWRITE_TAC[POPCOUNT_AND_POWERS] THEN REWRITE_TAC[UADDLV_COUNT_LEMMA] THEN
    REWRITE_TAC bitblast8_compute THEN NIBGSYM_COMPUTE THEN
    MP_TAC(SPECL[`nibbles1b:int128`; `word_subword (loaded_d:int64) (32,8):byte`;
      `word_subword (loaded_d:int64) (40,8):byte`; `word_subword (loaded_d:int64) (48,8):byte`;
      `word_subword (loaded_d:int64) (56,8):byte`] COUNT_BRIDGE_ABSTRACT_4) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN `val(read X13 s25:int64) = NUM_ACCEPTED(SUB_LIST(16 * i + 8,8) mask)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED] THEN AP_TERM_TAC THEN
    SUB4GSYM_COMPUTE THEN REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
    ASM_REWRITE_TAC[ARITH_RULE`2*(8*i+4)=16*i+8`; ARITH_RULE`2*4=8`]; ALL_TAC] THEN
  ABBREV_TAC `sp0:int64 = word_sub stackpointer (word 576)` THEN
  MAP_EVERY REABBREV_TAC [`len0:int64 = read X12 s25`; `len1:int64 = read X13 s25`] THEN
  FIRST_X_ASSUM(STRIP_ASSUME_TAC o REWRITE_RULE[ALL] o check
    (fun th -> match concl th with Comb(Comb(Const("ALL",_),_),_) -> true | _ -> false)) THEN
  SUBGOAL_THEN `val(len0:int64) <= 8` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[NUM_ACCEPTED_LE_8; REJ_NIBBLES_ETA4_LENGTH_4]; ALL_TAC] THEN
  SUBGOAL_THEN `val(len1:int64) <= 8` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[NUM_ACCEPTED_LE_8; REJ_NIBBLES_ETA4_LENGTH_4]; ALL_TAC] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (26--28) THEN
  ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s29" THEN
  FIRST_X_ASSUM(fun th -> if is_eq(concl th) && lhs(concl th) = `read X7 s29:int64`
    then ASSUME_TAC(GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1] th) else failwith "no") THEN
  SUBGOAL_THEN
   `nonoverlapping (word_add sp0 (word(2*(curlen + val(len0:int64)))):int64,16) (word pc:int64,344)`
    ASSUME_TAC THENL [NONOVERLAPPING_TAC; ALL_TAC] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC [30] THEN
  ARM_VERBOSE_STEP_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC "s31" THEN
  FIRST_X_ASSUM(fun th -> if is_eq(concl th) && lhs(concl th) = `read X7 s31:int64`
    then ASSUME_TAC(GEN_REWRITE_RULE RAND_CONV [WORD_ADD_SHL1] th) else failwith "no") THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (32--33) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN POSTCOND_FOLD_COMPUTE);;

(* -------------------------------------------------------------------------- *)
(*                                                                            *)
(* are `\s. program_decodes s /\ read PC s = word pc1 /\ (GROUPED loopinv) /\ *)
(* (APPEND e_front acc) /\ memaccess_inbounds e2 ...)}` (relational.ml:1974   *)
(* pth) — which does NOT flat-match MLDSA_ETA4_LOOP8_BODY's precond.          *)
(*                                                                            *)
(*      BOTH pre AND post, but BODY's postcond (=TAIL_CLOSE's) DROPS aligned. *)
(*      => augment TAIL_CLOSE/BODY with `aligned_bytes_loaded s (word pc) mc` *)
(*      aligned so it re-proves for free, exactly like s135's SP/X30 augment).*)
(*      pre, covar post, SAME `(\s s'.T)` frame — all of COMPUTE/TAIL_CLOSE/  *)
(*      BODY use `(\s s'.T)`), instantiating P/Q to BODY_AL's pre/post with   *)
(*      acc)) e.  Pre-strengthen: grouped=>flat + pick the events witness.    *)
(*      Post-weaken: PC bridge (word(pc+if..)=word(if..then pc+116..) via     *)
(*      with e_loop i = the per-iter delta), memaccess (see (3)).  Body conjunct *)
(*  (3) memaccess of the NEW e2 splits (MEMACCESS_INBOUNDS_APPEND) into the   *)
(*      per-iter delta memaccess (proven concretely) AND the pre's accumulated*)
(*      memaccess.  The latter is state-independent, so it is threaded via    *)
(*      => MI available in-context for the post; ~MI => the pre's `?e2 ... /\   *)
(*      memaccess e2_pre` is unsatisfiable so the ensures is vacuous            *)
(*  (4) The per-iter delta memaccess: jumps (EventJumps) close via              *)
(*      the buf load needs `8*i+8<=val buflen` which MENTIONS `val` so          *)
(*                                                                            *)
(* MLDSA_ETA4_LOOP8_BODY_ADAPTED is stated with e_front/acc as FREE vars its  *)
(* 3 ambient hyps (mask=REJ_MASK_ETA4 inlist, LENGTH inlist=val buflen, ALL   *)
(* nonoverlapping) discharge from the main-proof context. conj2 is built (no  *)
(* SIMD), guaranteeing the statement is exactly the shape the front emits.    *)
(* -------------------------------------------------------------------------- *)

let TAIL_CLOSE_AL =
  let th = SPEC_ALL MLDSA_ETA4_LOOP8_TAIL_CLOSE in
  let hyps = lhand (concl th) in
  let ens = rand (concl th) in
  let args = snd(strip_comb ens) in
  let p = el 1 args and q = el 2 args and c = el 3 args in
  let sv,qb = dest_abs q in
  let aligned = subst [sv,`s:armstate`]
    `aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc` in
  let q' = mk_abs(sv, mk_conj(aligned, qb)) in
  let goal = mk_imp(hyps, list_mk_icomb "ensures" [`arm`;p;q';c]) in
  GEN_ALL (prove(goal,
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    SUBGOAL_THEN `8 * (i + 1) <= val(buflen:int64)` ASSUME_TAC THENL
     [MP_TAC(SPECL[`buflen:int64`;`mask:(bool)list`] MLDSA_ETA4_LOOP8_TRIP_MINIMAL) THEN
      DISCH_THEN(MP_TAC o SPEC `i:num` o CONJUNCT2) THEN
      ASM_REWRITE_TAC[] THEN DISCH_THEN(MP_TAC o CONJUNCT1) THEN ARITH_TAC;
      ALL_TAC] THEN
    ENSURES_INIT_TAC "s0" THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--2) THEN
    ASM_CASES_TAC `8 <= val(word_sub buflen (word(8*(i+1))):int64)` THENL
     [UNDISCH_TAC `8 <= val(word_sub buflen (word(8*(i+1))):int64)` THEN
      DISCH_THEN(fun th -> RULE_ASSUM_TAC(REWRITE_RULE[th]) THEN ASSUME_TAC th) THEN
      ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (3--4) THEN
      SUBGOAL_THEN
        `256 <= val(word(NUM_ACCEPTED(SUB_LIST(0,16*(i+1)) mask)):int64) <=>
         ~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask)` ASSUME_TAC THENL
       [ASM_SIMP_TAC[LOOP8_TOP_VAL_BRIDGE] THEN
        MATCH_MP_TAC LOOP8_OUTPUT_FULL_IFF THEN
        ASM_MESON_TAC[LOOP8_BOT_VAL_BRIDGE];
        ALL_TAC] THEN
      ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
      REWRITE_TAC[APPEND] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[];
      SUBGOAL_THEN `val (buflen:int64) < 8 * (i + 2)` ASSUME_TAC THENL
       [UNDISCH_TAC `~(8 <= val(word_sub buflen (word(8*(i+1))):int64))` THEN
        ASM_SIMP_TAC[LOOP8_BOT_VAL_BRIDGE]; ALL_TAC] THEN
      SUBGOAL_THEN `~(i + 1 < MLDSA_ETA4_LOOP8_TRIP buflen mask)` ASSUME_TAC THENL
       [DISCH_TAC THEN
        MP_TAC(SPECL[`buflen:int64`;`mask:(bool)list`] MLDSA_ETA4_LOOP8_TRIP_MINIMAL) THEN
        DISCH_THEN(MP_TAC o SPEC `i + 1` o CONJUNCT2) THEN
        ASM_REWRITE_TAC[ARITH_RULE `8 * ((i + 1) + 1) = 8 * (i + 2)`]; ALL_TAC] THEN
      ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[APPEND]]));;

let BODY_AL =
  let strip_PQR th =
    let b = concl (SPEC_ALL th) in
    let body = if is_imp b then rand b else b in
    let (_,args) = strip_comb body in (el 1 args, el 2 args, el 3 args) in
  let (cP,cQ,cR) = strip_PQR MLDSA_ETA4_LOOP8_COMPUTE in
  let (tP,tQ,tR) = strip_PQR TAIL_CLOSE_AL in
  let _,cQbody = dest_abs cQ in
  let ev_compute =
    rhs (find (fun c -> is_eq c && lhs c = `read events (s:armstate)`)
              (conjuncts cQbody)) in
  let subl = [`num_of_wordlist(inlist:byte list)`,`bufval:num`;
              ev_compute,`e:(uarch_event)list`] in
  let tQ_inst = subst subl tQ in
  let c_hyps = conjuncts (lhand (concl (SPEC_ALL MLDSA_ETA4_LOOP8_COMPUTE))) in
  let bl_hyps = list_mk_conj
    [el 0 c_hyps; el 1 c_hyps; `i < MLDSA_ETA4_LOOP8_TRIP buflen mask`; last c_hyps] in
  let ef,eargs = strip_comb (rand (concl (SPEC_ALL MLDSA_ETA4_LOOP8_COMPUTE))) in
  let bl_ensures = list_mk_comb(ef, [el 0 eargs; el 1 eargs; tQ_inst; el 3 eargs]) in
  let midstate = let sv,body = dest_abs cQ in
                 mk_abs(sv, list_mk_conj (tl (tl (conjuncts body)))) in
  GEN_ALL(prove(mk_imp(bl_hyps, bl_ensures),
    STRIP_TAC THEN
    SUBGOAL_THEN
      `~(val (buflen:int64) < 8 * (i + 1)) /\
       ~(256 <= NUM_ACCEPTED(SUB_LIST(0,16 * i) mask))`
      STRIP_ASSUME_TAC THENL
     [MATCH_MP_TAC(CONJUNCT2(SPECL[`buflen:int64`;`mask:(bool)list`]
          MLDSA_ETA4_LOOP8_TRIP_MINIMAL)) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    ENSURES_SEQUENCE_TAC `pc + 0xf8` midstate THEN
    CONJ_TAC THENL
     [ MATCH_MP_TAC MLDSA_ETA4_LOOP8_COMPUTE THEN
       REPEAT CONJ_TAC THENL
        [ FIRST_ASSUM ACCEPT_TAC; FIRST_ASSUM ACCEPT_TAC;
          ASM_ARITH_TAC; ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC ];
       MATCH_MP_TAC TAIL_CLOSE_AL THEN
       CONJ_TAC THENL
        [ FIRST_ASSUM ACCEPT_TAC;
          REWRITE_TAC[NUM_ACCEPTED_SUB_LIST_STEP] THEN
          MP_TAC(SPECL[`mask:(bool)list`;`16 * i`] NUM_ACCEPTED_LE_8) THEN
          MP_TAC(SPECL[`mask:(bool)list`;`16 * i + 8`] NUM_ACCEPTED_LE_8) THEN
          CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN ASM_ARITH_TAC ] ]));;

let MLDSA_ETA4_LOOP8_BODY_ADAPTED =
  let appty = `APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list` in
  let body = SPEC_ALL BODY_AL in
  let bargs = snd(strip_comb (rand (concl body))) in
  let bP = el 1 bargs and bQ = el 2 bargs in
(* loop8_inv = BODY_AL-pre minus aligned/PC (front 2) and events (last)       *)
  let sv, bpbody = dest_abs bP in
  let loop8_inv = mk_abs(`i:num`, mk_abs(sv, list_mk_conj (butlast (tl (tl (conjuncts bpbody)))))) in
(* e_loop = \i. APPEND jumps five (per-iter delta from BODY_AL-post events)   *)
  let _, bqbody = dest_abs bQ in
  let ev_rhs = rhs (last (conjuncts bqbody)) in
  let jumps, rest = dest_binary "APPEND" ev_rhs in
  let five, _ = dest_binary "APPEND" rest in
  let e_loop = mk_abs(`i:num`, mk_binop appty jumps five) in
  let rr = `[(buf:int64),val(buflen:int64); (table:int64),4096;
             word_sub (stackpointer:int64) (word 576),576]` in
  let wr = `[word_sub (stackpointer:int64) (word 576),576; (res:int64),1024]` in
  let mkinb e2v = list_mk_icomb "memaccess_inbounds" [e2v; rr; wr] in
  let e_front = `f_ev_loop8_prol:(uarch_event)list` in
  let acc = `f_ev_acc:(uarch_event)list` in
  let enum_i = list_mk_comb(`ENUMERATEL:num->(num->(uarch_event)list)->(uarch_event)list`,[`i:num`; e_loop]) in
  let e2_pre = mk_binop appty enum_i (mk_binop appty e_front acc) in
  let eB = mk_binop appty e2_pre `e:(uarch_event)list` in
  let bP_inst = subst [eB,`e:(uarch_event)list`] bP in
  let bQ_inst = subst [eB,`e:(uarch_event)list`] bQ in
  let mi = mkinb e2_pre in
  let trip = `MLDSA_ETA4_LOOP8_TRIP buflen mask` in
  let pc1 = `pc + 116` and pc2 = `pc + 256` in
  let pre =
    let e2 = `e2:(uarch_event)list` in
    mk_abs(`s:armstate`,
      list_mk_conj
       [`aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc`;
        `read PC s = word (pc+116)`;
        list_mk_comb(loop8_inv,[`0`;`s:armstate`]);
        mk_exists(e2, list_mk_conj [`read events s = APPEND e2 e`; mk_eq(e2,e_front); mkinb e2])]) in
  let enum_trip = list_mk_comb(`ENUMERATEL:num->(num->(uarch_event)list)->(uarch_event)list`,[trip; e_loop]) in
  let post_e2val =
    mk_binop appty (mk_binop appty `f_ev_epil:(uarch_event)list`
                      (mk_binop appty enum_trip e_front)) acc in
  let post =
    let e2 = `e2:(uarch_event)list` in
    mk_abs(`s:armstate`,
      list_mk_conj
       [`read PC s = returnaddress`;
        mk_exists(e2, list_mk_conj [`read events s = APPEND e2 e`; mk_eq(e2,post_e2val); mkinb e2])]) in
  let syn_goal = list_mk_icomb "ensures" [`arm`; pre; post; `\(s:armstate) (s':armstate). T`] in
  let conj2 =
    let (_,gls,_) = ENSURES_EVENTS_WHILE_UP2_TAC trip pc1 pc2 loop8_inv ([],syn_goal) in
    el 2 (conjuncts (snd (hd gls))) in
  let enum_i1 = list_mk_comb(`ENUMERATEL:num->(num->(uarch_event)list)->(uarch_event)list`,[`i+1`; e_loop]) in
  let e2_post = mk_binop appty enum_i1 (mk_binop appty e_front acc) in
  let ambient = list_mk_conj
    [`mask = REJ_MASK_ETA4 inlist`;
     `LENGTH (inlist:byte list) = val (buflen:int64)`;
     `ALL (nonoverlapping (word_sub stackpointer (word 576),576))
          [(word pc,344); (buf:int64,val (buflen:int64)); (table:int64,4096)]`] in
  prove(mk_imp(ambient, conj2),
    REPEAT STRIP_TAC THEN
    ASM_CASES_TAC mi THENL
     [ MATCH_MP_TAC ENSURES_PREPOSTCONDITION_THM THEN
       MAP_EVERY EXISTS_TAC [bP_inst; bQ_inst] THEN
       REPEAT CONJ_TAC THENL
        [ GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
          GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN
          UNDISCH_THEN `mask = REJ_MASK_ETA4 inlist` (K ALL_TAC) THEN
          ASM_REWRITE_TAC[] THEN
          CONJ_TAC THENL
           [ AP_TERM_TAC THEN COND_CASES_TAC THEN ARITH_TAC;
             EXISTS_TAC e2_post THEN REPEAT CONJ_TAC THENL
              [ ASM_REWRITE_TAC[ENUMERATEL_ADD1] THEN REWRITE_TAC[APPEND; APPEND_ASSOC];
                REFL_TAC;
                REWRITE_TAC[ENUMERATEL_ADD1] THEN REWRITE_TAC[APPEND; APPEND_ASSOC] THEN
                REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN
                RULE_ASSUM_TAC(REWRITE_RULE[APPEND; APPEND_ASSOC; MEMACCESS_INBOUNDS_APPEND]) THEN
                ASM_REWRITE_TAC[] THEN
                SUBGOAL_THEN `8 * (i + 1) <= val(buflen:int64) /\
                              NUM_ACCEPTED(SUB_LIST(0,16*i) mask) < 256`
                  STRIP_ASSUME_TAC THENL
                 [MP_TAC(SPEC `i:num` (CONJUNCT2(SPECL[`buflen:int64`;`mask:(bool)list`]
                      MLDSA_ETA4_LOOP8_TRIP_MINIMAL))) THEN ASM_REWRITE_TAC[] THEN ARITH_TAC;
                  ALL_TAC] THEN
                ASSUME_TAC(SPECL[`mask:(bool)list`;`16*i`] NUM_ACCEPTED_LE_8) THEN
                ASSUME_TAC(SPEC `SUB_LIST(16*i,8) (mask:(bool)list)` PACK_MASK8_BOUND) THEN
                ASSUME_TAC(SPEC `SUB_LIST(16*i+8,8) (mask:(bool)list)` PACK_MASK8_BOUND) THEN
                CONJ_TAC THENL
                 [ COND_CASES_TAC THEN DISCHARGE_MEMACCESS_INBOUNDS_TAC;
                   DISCHARGE_CONCRETE_MEMACCESS_INBOUNDS_TAC THEN
                   DISJ1_TAC THEN
                   GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
                   GEN_REWRITE_TAC (BINOP_CONV o LAND_CONV o LAND_CONV o TOP_DEPTH_CONV)
                     [VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
                   CONV_TAC(BINOP_CONV(LAND_CONV MOD_DOWN_CONV)) THEN
                   GEN_REWRITE_TAC I [CONTAINED_MODULO_MOD2] THEN
                   (MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE ORELSE
                    MATCH_MP_TAC CONTAINED_MODULO_SIMPLE) THEN
                   UNDISCH_TAC `8 * (i + 1) <= val(buflen:int64)` THEN ARITH_TAC ] ] ];
          MATCH_MP_TAC BODY_AL THEN ASM_REWRITE_TAC[] ];
       MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC `\s:armstate. F` THEN
       CONJ_TAC THENL
        [ GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_MESON_TAC[];
          REWRITE_TAC[ensures] THEN MESON_TAC[] ] ]);;

(* Restore the recursive `STRIP_EXISTS_ASSUM_TAC` from s2n-bignum             *)
(* common/misc.ml, which the constant-time proof below was developed against. *)
(* The MEMSAFE section (near line 2363) locally redefines                     *)
(* STRIP_EXISTS_ASSUM_TAC to a *shallow* variant that only splits the         *)
(* outermost conjunction of the chosen existential. The event-loop leaves     *)
(* below feed `~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)` an invariant of  *)
(* the form `?e2. read events s = ... /\ e2 = ... /\ memaccess_inbounds e2    *)
(* ...`; the shallow variant leaves `e2 = ... /\ memaccess_inbounds e2 ...`   *)
(* conjoined, so DISCHARGE_MEMACCESS_INBOUNDS_USING_ASM_TAC (which filters    *)
(* assumptions by head symbol) cannot see the `memaccess_inbounds e2` fact    *)
(* and the discharge fails. The recursive STRIP_ASSUME_TAC form splits it     *)
(* into a standalone assumption.                                              *)
let STRIP_EXISTS_ASSUM_TAC =
  FIRST_X_ASSUM (STRIP_ASSUME_TAC o (check (is_exists o concl)));;

(* Proof machinery for MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_SAFE: derive the concretized f_events lambda and
   the loop8/fcopy invariants from BODY_AL (see the theorem below). *)
let ETA4_SAFE_MACHINERY =
  let appty = `APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list` in
  let bodyth = SPEC_ALL BODY_AL in
  let bargs = snd(strip_comb (rand (concl bodyth))) in
  let bP = el 1 bargs and bQ = el 2 bargs in
  let sv,bpbody = dest_abs bP in
  let loop8_inv =
    mk_abs(`i:num`, mk_abs(sv, list_mk_conj (butlast (tl (tl (conjuncts bpbody)))))) in
  let _,bqbody = dest_abs bQ in
  let ev_rhs = rhs (last (conjuncts bqbody)) in
  let jumps,rest = dest_binary "APPEND" ev_rhs in
  let five,_ = dest_binary "APPEND" rest in
  let loop8_inv_real =
    subst [`num_of_wordlist mldsa_rej_uniform_eta_table`,`tabval:num`] loop8_inv in
  let orig_lam =
   `\(res:int64)(buf:int64)(buflen:int64)(table:int64)(pc:num)(sp:int64)
       (ra:int64)(mask:(bool)list).
     APPEND
      (APPEND
       (APPEND
        (APPEND
         (f_ev_epi res buf buflen table pc sp ra mask)
         (APPEND (ENUMERATEL 16 (\j. f_ev_fcopy res buf buflen table pc sp ra mask j))
                 (f_ev_fcopy_prol res buf buflen table pc sp ra mask)))
        (APPEND (ENUMERATEL (MLDSA_ETA4_LOOP8_TRIP buflen mask)
                            (\i. f_ev_loop8 res buf buflen table pc sp ra mask i))
                (f_ev_loop8_prol res buf buflen table pc sp ra mask)))
       (APPEND (ENUMERATEL 8 (\k. f_ev_zinit res buf buflen table pc sp ra mask k))
               (f_ev_zinit_prol res buf buflen table pc sp ra mask)))
      (f_ev_begin res buf buflen table pc sp ra mask) :(uarch_event)list` in
  let lamvars,obody = strip_abs orig_lam in
  let is_l8 t = is_abs t &&
    (let _,b = dest_abs t in is_comb b &&
     (let h = fst(strip_comb b) in is_var h && fst(dest_var h) = "f_ev_loop8")) in
  let l8_old = find_term is_l8 obody in
  let e_loop_lam = mk_abs(`i:num`,
    subst [`sp:int64`,`stackpointer:int64`; `ra:int64`,`returnaddress:int64`]
          (mk_binop appty jumps five)) in
  let modified_lam = list_mk_abs(lamvars, subst [e_loop_lam,l8_old] obody) in
  let REASSOC_LOOP8 = METIS[APPEND_ASSOC]
    `(exists e2. P e2 /\
      e2 = APPEND (APPEND (APPEND epil (APPEND loop prol)) tail) tail2 /\ Q e2)
     <=>
     (exists e2. P e2 /\
      e2 = APPEND (APPEND epil (APPEND loop prol)) (APPEND tail tail2) /\ Q e2)` in
  let REASSOC_FCOPY = METIS[APPEND_ASSOC]
    `(exists e2. P e2 /\
      e2 = APPEND (APPEND fe (APPEND l8e l8p)) zb /\ Q e2)
     <=>
     (exists e2. P e2 /\
      e2 = APPEND fe (APPEND l8e (APPEND l8p zb)) /\ Q e2)` in
(* MINIMAL fcopy invariant (postcond doesn't constrain regs; omit             *)
(* X9/v-consts).                                                              *)
  let fcopy_inv =
    `\(i:num) s. read SP s = word_sub stackpointer (word 576) /\
        read X30 s = returnaddress /\
        read X0 s = word_add res (word(64 * i)) /\
        read X7 s = word_add (word_sub stackpointer (word 576)) (word(32 * i)) /\
        read X8 s = word_sub stackpointer (word 576) /\
        read X11 s = word(16 * i)` in
  (modified_lam, loop8_inv_real, REASSOC_LOOP8, fcopy_inv, REASSOC_FCOPY);;

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_SAFE = time prove
 (`?f_events:int64->int64->int64->int64->num->int64->int64->
             (bool list)->(uarch_event)list.
   !res buf buflen table (inlist:byte list) pc e stackpointer returnaddress.
      8 divides val buflen /\
      8 <= val buflen /\
      LENGTH inlist = val buflen /\
      ALL (nonoverlapping (word_sub stackpointer (word 576),576))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (buf,val buflen); (table,4096)] /\
      ALL (nonoverlapping (res,1024))
          [(word pc,LENGTH mldsa_rej_uniform_eta4_mc);
           (word_sub stackpointer (word 576),576)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read PC s = word pc /\
                read SP s = stackpointer /\
                read X30 s = returnaddress /\
                C_ARGUMENTS [res;buf;buflen;table] s /\
                read(memory :> bytes(table,4096)) s =
                num_of_wordlist mldsa_rej_uniform_eta_table /\
                read(memory :> bytes(buf,val buflen)) s =
                num_of_wordlist (inlist:byte list) /\
                read events s = e)
           (\s. read PC s = returnaddress /\
                (?e2.
                     read events s = APPEND e2 e /\
                     e2 = f_events res buf buflen table pc stackpointer
                                   returnaddress (REJ_MASK_ETA4 inlist) /\
                     memaccess_inbounds e2
                       [buf,val buflen; table,4096;
                        word_sub stackpointer (word 576),576]
                       [word_sub stackpointer (word 576),576; res,1024]))
           (\s s'. T)`,
(* -------------------------------------------------------------------------- *)
(* bignum_copy_row_from_table.ml:635-880 (LEFT-leaning lambda association).   *)
(* -------------------------------------------------------------------------- *)
  let modified_lam, loop8_inv_real, REASSOC_LOOP8, fcopy_inv, REASSOC_FCOPY =
      ETA4_SAFE_MACHINERY in
  CONCRETIZE_F_EVENTS_TAC modified_lam THEN
  REPEAT META_EXISTS_TAC THEN REPEAT GEN_TAC THEN
  REWRITE_TAC[C_ARGUMENTS; NONOVERLAPPING_CLAUSES; ALL;
              fst MLDSA_REJ_UNIFORM_ETA4_EXEC] THEN
  REPEAT STRIP_TAC THEN
  ABBREV_TAC `mask:(bool)list = REJ_MASK_ETA4 inlist` THEN
  ENSURES_EVENTS_SEQUENCE_TAC `pc + 0x44`
   `\s. read X30 s = returnaddress /\ read X0 s = res /\ read X1 s = buf /\
        read X2 s = buflen /\ read X3 s = table /\
        read SP s = word_sub stackpointer (word 576) /\
        read X7 s = word_sub stackpointer (word 576) /\
        read X8 s = word_sub stackpointer (word 576) /\
        read X11 s = word 0 /\
        read Q30 s = word 46731384791156575435574448262545417 /\
        read Q31 s = word 664619068533544770747334646890102785 /\
        read Q16 s = word 0 /\
        read (memory :> bytes (table,4096)) s =
        num_of_wordlist mldsa_rej_uniform_eta_table /\
        read (memory :> bytes (buf,val buflen)) s = num_of_wordlist (inlist:byte list)` THEN
  CONJ_TAC THENL [
    GHOST_INTRO_TAC `q31_init:int128` `read Q31` THEN
    ENSURES_INIT_TAC "s0" THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--17) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[WORD_INSERT_Q31] THEN
    DISCHARGE_SAFETY_PROPERTY_TAC;
    ALL_TAC] THEN
  ENSURES_EVENTS_WHILE_UP2_TAC `8` `pc + 0x44` `pc + 0x60`
   `\(i:num) s. read SP s = word_sub stackpointer (word 576) /\
        read X30 s = returnaddress /\ read X0 s = res /\ read X1 s = buf /\
        read X2 s = buflen /\ read X3 s = table /\
        read X8 s = word_sub stackpointer (word 576) /\
        read X7 s = word_add (word_sub stackpointer (word 576)) (word (64 * i)) /\
        read X11 s = word (32 * i) /\
        read Q30 s = word 46731384791156575435574448262545417 /\
        read Q31 s = word 664619068533544770747334646890102785 /\
        read Q16 s = word 0 /\
        read (memory :> bytes (table,4096)) s =
        num_of_wordlist mldsa_rej_uniform_eta_table /\
        read (memory :> bytes (buf,val buflen)) s = num_of_wordlist (inlist:byte list)` THEN
  REPEAT CONJ_TAC THENL [
    ARITH_TAC;
    ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
        ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--0) THEN
    REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0] THEN DISCHARGE_SAFETY_PROPERTY_TAC;
    REPEAT STRIP_TAC THEN
    ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
        ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--7) THEN
    CONJ_TAC THENL
     [ASM_SIMP_TAC[ZINIT_BRANCH] THEN REWRITE_TAC[COND_RAND] THEN
      COND_CASES_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
    CONJ_TAC THENL
     [REWRITE_TAC[ARITH_RULE `64*(i+1)=64*i+64`] THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
    CONJ_TAC THENL
     [REWRITE_TAC[ARITH_RULE `32*(i+1)=32*i+32`] THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
    DISCHARGE_SAFETY_PROPERTY_TAC;
    ONCE_REWRITE_TAC[REASSOC_LOOP8] THEN
    ENSURES_EVENTS_WHILE_UP2_TAC `MLDSA_ETA4_LOOP8_TRIP buflen mask`
      `pc + 0x74` `pc + 0x100` loop8_inv_real THEN
    REPEAT CONJ_TAC THENL [
      SUBGOAL_THEN `NUM_ACCEPTED(SUB_LIST(0,16 * 0) (mask:(bool)list)) = 0` ASSUME_TAC THENL
       [REWRITE_TAC[ARITH_RULE `16 * 0 = 0`; SUB_LIST_CLAUSES; NUM_ACCEPTED; FILTER; LENGTH];
        ALL_TAC] THEN
      DISCH_TAC THEN
      MP_TAC(CONJUNCT1(SPECL[`buflen:int64`;`mask:(bool)list`]
        MLDSA_ETA4_LOOP8_TRIP_MINIMAL)) THEN
      ASM_REWRITE_TAC[ARITH_RULE `8 * (0 + 1) = 8`] THEN ASM_ARITH_TAC;
      ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
          ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--5) THEN
      REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; NUM_ACCEPTED; FILTER; LENGTH] THEN
      REPEAT CONJ_TAC THEN TRY(CONV_TAC WORD_RULE) THEN DISCHARGE_SAFETY_PROPERTY_TAC;
      MATCH_MP_TAC MLDSA_ETA4_LOOP8_BODY_ADAPTED THEN ASM_REWRITE_TAC[] THEN
      REWRITE_TAC[ALL] THEN REPEAT CONJ_TAC THEN NONOVERLAPPING_TAC;
      ONCE_REWRITE_TAC[REASSOC_FCOPY] THEN
      ENSURES_EVENTS_WHILE_UP2_TAC `16` `pc + 0x110` `pc + 0x14c` fcopy_inv THEN
      REPEAT CONJ_TAC THENL [
        ARITH_TAC;
        ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
            ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--4) THEN
        REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0] THEN
        REPEAT CONJ_TAC THEN TRY(CONV_TAC WORD_RULE) THEN DISCHARGE_SAFETY_PROPERTY_TAC;
        REPEAT STRIP_TAC THEN
        ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
            ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--15) THEN
        CONJ_TAC THENL
         [ASM_SIMP_TAC[FCOPY_BRANCH] THEN REWRITE_TAC[COND_RAND] THEN
          COND_CASES_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        CONJ_TAC THENL
         [REWRITE_TAC[ARITH_RULE `64*(i+1)=64*i+64`; ARITH_RULE `32*(i+1)=32*i+32`;
                      ARITH_RULE `16*(i+1)=16*i+16`] THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
        CONJ_TAC THENL
         [REWRITE_TAC[ARITH_RULE `64*(i+1)=64*i+64`; ARITH_RULE `32*(i+1)=32*i+32`;
                      ARITH_RULE `16*(i+1)=16*i+16`] THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
        CONJ_TAC THENL
         [REWRITE_TAC[ARITH_RULE `64*(i+1)=64*i+64`; ARITH_RULE `32*(i+1)=32*i+32`;
                      ARITH_RULE `16*(i+1)=16*i+16`] THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
        DISCHARGE_SAFETY_PROPERTY_TAC;
        ARM_SIM_TAC ~preprocess_tac:(TRY STRIP_EXISTS_ASSUM_TAC)
            ~canonicalize_pc_diff:false MLDSA_REJ_UNIFORM_ETA4_EXEC (1--3) THEN
        DISCHARGE_SAFETY_PROPERTY_TAC]]]);;
