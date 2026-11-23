(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "s2n_bignum/x86/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_utils.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_table.ml";;

(* AVX2 compaction and word arithmetic shared by eta2 and eta4. *)

let TABLE_ENTRY = define
 `TABLE_ENTRY (m:byte) = SUB_LIST(8 * val m, 8) (mldsa_rej_uniform_table:byte list)`;;

let READ_BYTES_SLICE = prove
 (`!(a:int64) k n (L:byte list) (s:x86state).
      read(memory:>bytes(a,LENGTH L)) s = num_of_wordlist L /\ k + n <= LENGTH L
      ==> read(memory:>bytes(word_add a (word k), n)) s = num_of_wordlist(SUB_LIST(k,n) L)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `k + (LENGTH(L:byte list) - k) = LENGTH L` ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `n + (LENGTH(L:byte list) - (k+n)) = LENGTH L - k` ASSUME_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `read(memory:>bytes(word_add a (word k), LENGTH(L:byte list) - k)) s =
                num_of_wordlist(SUB_LIST(k, LENGTH L - k) L)` ASSUME_TAC THENL
   [MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `a:int64`; `s:x86state`;
       `SUB_LIST(0,k) (L:byte list)`; `SUB_LIST(k, LENGTH(L:byte list) - k) L`;
       `k:num`; `LENGTH(L:byte list) - k`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
    REWRITE_TAC[DIMINDEX_8; LENGTH_SUB_LIST; SUB_0] THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[SUB_LIST_TOPSPLIT] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]);
    ALL_TAC] THEN
  MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `word_add a (word k):int64`; `s:x86state`;
     `SUB_LIST(k,n) (L:byte list)`; `SUB_LIST(k+n, LENGTH(L:byte list) - (k+n)) L`;
     `n:num`; `LENGTH(L:byte list) - (k + n)`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[DIMINDEX_8; LENGTH_SUB_LIST] THEN
  ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`L:byte list`; `n:num`; `LENGTH(L:byte list) - (k+n)`; `k:num`] SUB_LIST_SPLIT) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]));;

let STORE_BYTES256_NUM_OF_WORDLIST = prove
 (`!(A:int64) (V:int256) (L:int32 list) k (s:x86state).
      read(memory:>bytes256 A) s = V /\ LENGTH L = k /\ k <= 8 /\
      (!j. j < k ==> word_subword V (32*j,32):int32 = EL j L)
      ==> read(memory:>bytes(A, 4*k)) s = num_of_wordlist L`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`A:int64`; `V:int256`; `k:num`; `s:x86state`] BYTES256_PREFIX_WORDLIST) THEN
  ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
  AP_TERM_TAC THEN MATCH_MP_TAC WORDLIST_OF_NUM_VAL_EQ THEN ASM_REWRITE_TAC[]);;

let TABLE_VMOVQ_READ = prove
 (`!(table:int64) r (s:x86state).
      read(memory:>bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\ r < 256
      ==> read(memory:>bytes64(word_add table (word(8*r)))) s =
          word(num_of_wordlist(TABLE_ENTRY(word r:byte)))`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[RB64; TABLE_ENTRY] THEN AP_TERM_TAC THEN
  SUBGOAL_THEN `LENGTH(mldsa_rej_uniform_table:byte list) = 2048` ASSUME_TAC THENL
   [REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  SUBGOAL_THEN `val(word r:byte) = r` SUBST1_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_8] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL [`table:int64`; `8*r`; `8`; `mldsa_rej_uniform_table:byte list`; `s:x86state`]
    READ_BYTES_SLICE) THEN
  ASM_REWRITE_TAC[] THEN ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_THEN MATCH_ACCEPT_TAC]);;

let ACC_IDX = define
 `ACC_IDX (m:byte) = FILTER (\i. bit i m) [0;1;2;3;4;5;6;7]`;;

let TABLE_PREFIX_ACC = prove
 (`!m. m < 256 ==>
    SUB_LIST(0, LENGTH(ACC_IDX(word m:byte))) (TABLE_ENTRY(word m)) =
    MAP word (ACC_IDX(word m:byte)):byte list`,
  CONV_TAC EXPAND_CASES_CONV THEN
  REWRITE_TAC[ACC_IDX; TABLE_ENTRY; FILTER] THEN
  CONV_TAC(DEPTH_CONV WORD_RED_CONV) THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[LENGTH] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[mldsa_rej_uniform_table] THEN
  CONV_TAC(DEPTH_CONV SUB_LIST_CONV) THEN
  REWRITE_TAC[MAP] THEN CONV_TAC(DEPTH_CONV WORD_RED_CONV));;

let PSHUFB_GATHER_BYTE = prove
 (`!(w:int128) (c:byte). val c < 8
     ==> (if bit 7 c then word 0:byte
          else word_subword w (8 * val (word_subword c (0,4):byte),8)) =
         word_subword w (8 * val c,8)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `~(bit 7 (c:byte))` ASSUME_TAC THENL
   [REWRITE_TAC[BIT_VAL] THEN
    SUBGOAL_THEN `val(c:byte) DIV 2 EXP 7 = 0` (fun th -> REWRITE_TAC[th]) THENL
     [MATCH_MP_TAC DIV_LT THEN UNDISCH_TAC `val(c:byte) < 8` THEN ARITH_TAC;
      CONV_TAC NUM_REDUCE_CONV];
    ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `val(word_subword (c:byte) (0,4):byte) = val c` SUBST1_TAC THENL
   [REWRITE_TAC[VAL_WORD_SUBWORD; DIMINDEX_8] THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[DIV_1] THEN
    MATCH_MP_TAC MOD_LT THEN UNDISCH_TAC `val(c:byte) < 8` THEN ARITH_TAC;
    REFL_TAC]);;

let PSHUFB_LANE_EXTRACT = prove
 (`!(ff:byte->byte) (c:int64).
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (0,8):byte = ff(word_subword c (0,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (8,8):byte = ff(word_subword c (8,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (16,8):byte = ff(word_subword c (16,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (24,8):byte = ff(word_subword c (24,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (32,8):byte = ff(word_subword c (32,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (40,8):byte = ff(word_subword c (40,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (48,8):byte = ff(word_subword c (48,8)) /\
     word_subword (usimd16 ff (word_zx (word_zx c:int128):int128):int128) (56,8):byte = ff(word_subword c (56,8))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[usimd16; usimd8; usimd4; usimd2] THEN
  SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
           DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64; DIMINDEX_128; ARITH] THEN
  REPEAT CONJ_TAC THEN
  (SIMP_TAC[WORD_SUBWORD_TRIVIAL; DIMINDEX_8; LE_REFL] THEN
   AP_TERM_TAC THEN CONV_TAC WORD_BLAST));;

let ALL_TABLE_LT_8 = prove
 (`ALL (\b:byte. val b < 8) mldsa_rej_uniform_table`,
  REWRITE_TAC[mldsa_rej_uniform_table; ALL] THEN
  CONV_TAC(DEPTH_CONV WORD_RED_CONV) THEN CONV_TAC NUM_REDUCE_CONV);;

let TABLE_BYTES_LT_8 = prove
 (`!j. j < 2048 ==> val(EL j (mldsa_rej_uniform_table:byte list)) < 8`,
  GEN_TAC THEN DISCH_TAC THEN
  MP_TAC(ISPECL [`\b:byte. val b < 8`; `mldsa_rej_uniform_table:byte list`]
                ALL_EL) THEN
  REWRITE_TAC[ALL_TABLE_LT_8] THEN
  DISCH_THEN(MP_TAC o SPEC `j:num`) THEN REWRITE_TAC[] THEN
  SUBGOAL_THEN `LENGTH(mldsa_rej_uniform_table:byte list) = 2048`
    (fun th -> REWRITE_TAC[th]) THENL
   [REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV;
    ASM_REWRITE_TAC[]]);;

let PSHUFB_TABLE_GATHER_8 = prove
 (`!(g:int128) (c:int64).
     (!k. k < 8 ==> val(word_subword c (8*k,8):byte) < 8)
     ==> (!k. k < 8 ==>
            word_subword (usimd16
              (\(i:byte). if bit 7 i then word 0:byte
                  else word_subword g (8 * val(word_subword i (0,4):byte),8))
              (word_zx (word_zx c:int128):int128):int128) (8*k,8):byte =
            word_subword g (8 * val(word_subword c (8*k,8):byte),8))`,
  GEN_TAC THEN GEN_TAC THEN DISCH_TAC THEN
  CONV_TAC EXPAND_CASES_CONV THEN
  REWRITE_TAC[ARITH] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[PSHUFB_LANE_EXTRACT] THEN
  REPEAT CONJ_TAC THEN MATCH_MP_TAC PSHUFB_GATHER_BYTE THEN
  ASM_SIMP_TAC[ARITH] THEN
  FIRST_X_ASSUM(fun th ->
    MP_TAC(SPEC `0` th) THEN MP_TAC(SPEC `1` th) THEN MP_TAC(SPEC `2` th) THEN
    MP_TAC(SPEC `3` th) THEN MP_TAC(SPEC `4` th) THEN MP_TAC(SPEC `5` th) THEN
    MP_TAC(SPEC `6` th) THEN MP_TAC(SPEC `7` th)) THEN
  CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MULT_CLAUSES] THEN
  REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[]);;

let CTRL_BYTE_TABLE = prove
 (`!m k. k < 8
     ==> word_subword (word(num_of_wordlist(TABLE_ENTRY m)):int64) (8*k,8):byte
         = EL k (TABLE_ENTRY m)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`TABLE_ENTRY m:byte list`; `k:num`]
    (INST_TYPE[`:64`,`:KL`; `:8`,`:L`] WORD_SUBWORD_NUM_OF_WORDLIST)) THEN
  REWRITE_TAC[DIMINDEX_64; DIMINDEX_8] THEN
  SUBGOAL_THEN `LENGTH(TABLE_ENTRY m:byte list) = 8` SUBST1_TAC THENL
   [REWRITE_TAC[TABLE_ENTRY; LENGTH_SUB_LIST] THEN
    SUBGOAL_THEN `LENGTH(mldsa_rej_uniform_table:byte list) = 2048`
      (fun th -> REWRITE_TAC[th]) THENL
     [REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
    MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC;
    ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
  DISCH_THEN MATCH_MP_TAC THEN ASM_REWRITE_TAC[]);;

let TABLE_ENTRY_BYTES_LT_8 = prove
 (`!m k. k < 8 ==> val(EL k (TABLE_ENTRY m):byte) < 8`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[TABLE_ENTRY] THEN
  MP_TAC(ISPECL [`mldsa_rej_uniform_table:byte list`; `k:num`; `8 * val(m:byte)`; `8`]
    EL_SUB_LIST) THEN
  ANTS_TAC THENL
   [ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `LENGTH(mldsa_rej_uniform_table:byte list) = 2048`
      (fun th -> REWRITE_TAC[th]) THENL
     [REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
    MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC;
    DISCH_THEN SUBST1_TAC] THEN
  MATCH_MP_TAC TABLE_BYTES_LT_8 THEN
  MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ASM_ARITH_TAC);;

let PSHUFB_OUT_BYTE = prove
 (`!(g:int128) (m:byte) k. k < 8
     ==> word_subword (usimd16
            (\(i:byte). if bit 7 i then word 0:byte
                else word_subword g (8 * val(word_subword i (0,4):byte),8))
            (word_zx (word_zx (word(num_of_wordlist(TABLE_ENTRY m)):int64):int128):int128):int128)
            (8*k,8):byte =
         word_subword g (8 * val(EL k (TABLE_ENTRY m):byte), 8)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(SPECL [`g:int128`; `word(num_of_wordlist(TABLE_ENTRY m)):int64`]
    PSHUFB_TABLE_GATHER_8) THEN
  ANTS_TAC THENL
   [REPEAT STRIP_TAC THEN ASM_SIMP_TAC[CTRL_BYTE_TABLE] THEN
    ASM_SIMP_TAC[TABLE_ENTRY_BYTES_LT_8];
    DISCH_THEN(MP_TAC o SPEC `k:num`) THEN ASM_REWRITE_TAC[] THEN
    ASM_SIMP_TAC[CTRL_BYTE_TABLE]]);;

let PSHUFB_OUT_LIST = define
 `PSHUFB_OUT_LIST (g:int128) (m:byte) =
    [word_subword g (8 * val(EL 0 (TABLE_ENTRY m):byte),8):byte;
     word_subword g (8 * val(EL 1 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 2 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 3 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 4 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 5 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 6 (TABLE_ENTRY m):byte),8);
     word_subword g (8 * val(EL 7 (TABLE_ENTRY m):byte),8)]`;;

let PSHUFB_OUT_LIST_AS_MAP = prove
 (`!g m. PSHUFB_OUT_LIST g m =
         MAP (\b:byte. word_subword g (8 * val b,8):byte) (TABLE_ENTRY m)`,
  REPEAT GEN_TAC THEN
  SUBGOAL_THEN `?a0 a1 a2 a3 a4 a5 a6 a7:byte.
       TABLE_ENTRY m = [a0;a1;a2;a3;a4;a5;a6;a7]` STRIP_ASSUME_TAC THENL
   [SUBGOAL_THEN `LENGTH(TABLE_ENTRY m:byte list) = 8` MP_TAC THENL
     [REWRITE_TAC[TABLE_ENTRY; LENGTH_SUB_LIST] THEN
      SUBGOAL_THEN `LENGTH(mldsa_rej_uniform_table:byte list) = 2048`
        (fun th -> REWRITE_TAC[th]) THENL
       [REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN CONV_TAC NUM_REDUCE_CONV;
        ALL_TAC] THEN
      MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC;
      ALL_TAC] THEN
    SPEC_TAC(`TABLE_ENTRY m:byte list`,`l:byte list`) THEN
    REWRITE_TAC[ARITH_RULE `8 = SUC(SUC(SUC(SUC(SUC(SUC(SUC(SUC 0)))))))`] THEN
    REWRITE_TAC[LENGTH_EQ_CONS; LENGTH_EQ_NIL] THEN MESON_TAC[];
    ASM_REWRITE_TAC[PSHUFB_OUT_LIST; MAP] THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REWRITE_TAC[]]);;

let SUB_LIST_NEST = prove
 (`!a n b m l:A list. a + n <= m /\ b + m <= LENGTH l
     ==> SUB_LIST(a,n)(SUB_LIST(b,m) l) = SUB_LIST(b+a,n) l`,
  REPEAT STRIP_TAC THEN ONCE_REWRITE_TAC[LIST_EQ] THEN
  REWRITE_TAC[LENGTH_SUB_LIST] THEN CONJ_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  X_GEN_TAC `j:num` THEN STRIP_TAC THEN
  SUBGOAL_THEN `j < n` ASSUME_TAC THENL
   [POP_ASSUM MP_TAC THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(SUB_LIST(b,m) (l:A list)) = m` ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `EL j (SUB_LIST(a,n)(SUB_LIST(b,m) (l:A list))) = EL (a+j) (SUB_LIST(b,m) l)`
    SUBST1_TAC THENL
   [MATCH_MP_TAC EL_SUB_LIST THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `EL (a+j) (SUB_LIST(b,m) (l:A list)) = EL (b+(a+j)) l`
    SUBST1_TAC THENL
   [MATCH_MP_TAC EL_SUB_LIST THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `EL j (SUB_LIST(b+a,n) (l:A list)) = EL ((b+a)+j) l`
    SUBST1_TAC THENL
   [MATCH_MP_TAC EL_SUB_LIST THEN ASM_ARITH_TAC; ALL_TAC] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN ARITH_TAC);;

let SUBITER_BLOCK_BYTES = prove
 (`!inlist i chunk0:int128.
      16 * i + 16 <= LENGTH(inlist:byte list) /\
      SUB_LIST(16*i,16) inlist =
        [word_subword chunk0 (0,8); word_subword chunk0 (8,8);
         word_subword chunk0 (16,8); word_subword chunk0 (24,8);
         word_subword chunk0 (32,8); word_subword chunk0 (40,8);
         word_subword chunk0 (48,8); word_subword chunk0 (56,8);
         word_subword chunk0 (64,8); word_subword chunk0 (72,8);
         word_subword chunk0 (80,8); word_subword chunk0 (88,8);
         word_subword chunk0 (96,8); word_subword chunk0 (104,8);
         word_subword chunk0 (112,8); word_subword chunk0 (120,8)]
      ==> SUB_LIST(16*i,4) inlist =
            [word_subword chunk0 (0,8); word_subword chunk0 (8,8);
             word_subword chunk0 (16,8); word_subword chunk0 (24,8)] /\
          SUB_LIST(16*i+4,4) inlist =
            [word_subword chunk0 (32,8); word_subword chunk0 (40,8);
             word_subword chunk0 (48,8); word_subword chunk0 (56,8)] /\
          SUB_LIST(16*i+8,4) inlist =
            [word_subword chunk0 (64,8); word_subword chunk0 (72,8);
             word_subword chunk0 (80,8); word_subword chunk0 (88,8)] /\
          SUB_LIST(16*i+12,4) inlist =
            [word_subword chunk0 (96,8); word_subword chunk0 (104,8);
             word_subword chunk0 (112,8); word_subword chunk0 (120,8)]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REPEAT CONJ_TAC THENL
   [MP_TAC(ISPECL[`0`;`4`;`16*i:num`;`16`;`inlist:byte list`] SUB_LIST_NEST);
    MP_TAC(ISPECL[`4`;`4`;`16*i:num`;`16`;`inlist:byte list`] SUB_LIST_NEST);
    MP_TAC(ISPECL[`8`;`4`;`16*i:num`;`16`;`inlist:byte list`] SUB_LIST_NEST);
    MP_TAC(ISPECL[`12`;`4`;`16*i:num`;`16`;`inlist:byte list`] SUB_LIST_NEST)] THEN
  (ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
   REWRITE_TAC[ARITH_RULE `16*i+0 = 16*i`] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
   ASM_REWRITE_TAC[] THEN CONV_TAC(LAND_CONV SUB_LIST_CONV) THEN REFL_TAC));;

let ACC_IDX_LT_8 = prove
 (`!m x. MEM x (ACC_IDX m) ==> x < 8`,
  REWRITE_TAC[ACC_IDX] THEN REPEAT GEN_TAC THEN
  REWRITE_TAC[MEM_FILTER; MEM] THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN ARITH_TAC);;

let LENGTH_ACC_IDX_BITSUM = prove
 (`!m:byte. LENGTH(ACC_IDX m) =
            bitval(bit 0 m) + bitval(bit 1 m) + bitval(bit 2 m) + bitval(bit 3 m) +
            bitval(bit 4 m) + bitval(bit 5 m) + bitval(bit 6 m) + bitval(bit 7 m)`,
  GEN_TAC THEN REWRITE_TAC[ACC_IDX] THEN
  MAP_EVERY ASM_CASES_TAC
   [`bit 0 (m:byte)`;`bit 1 (m:byte)`;`bit 2 (m:byte)`;`bit 3 (m:byte)`;
    `bit 4 (m:byte)`;`bit 5 (m:byte)`;`bit 6 (m:byte)`;`bit 7 (m:byte)`] THEN
  ASM_REWRITE_TAC[FILTER; LENGTH; BITVAL_CLAUSES] THEN ARITH_TAC);;

let GATHER_FILTERED_IDX_8 = prove
 (`!(P:A->bool) a0 a1 a2 a3 a4 a5 a6 a7.
     MAP (\j. EL j [a0;a1;a2;a3;a4;a5;a6;a7])
         (FILTER (\j. P (EL j [a0;a1;a2;a3;a4;a5;a6;a7])) [0;1;2;3;4;5;6;7]) =
     FILTER P [a0;a1;a2;a3;a4;a5;a6;a7]`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[FILTER; MAP] THEN
  CONV_TAC(DEPTH_CONV EL_CONV) THEN
  REWRITE_TAC[] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP; FILTER]) THEN
  CONV_TAC(DEPTH_CONV EL_CONV) THEN REWRITE_TAC[]);;

let GATHER_FILTER_MAP_IDX_8 = prove
 (`!(f:byte->A) (P:byte->bool) n0 n1 n2 n3 n4 n5 n6 n7.
     MAP (\j. f (EL j [n0;n1;n2;n3;n4;n5;n6;n7]:byte))
         (FILTER (\j. P (EL j [n0;n1;n2;n3;n4;n5;n6;n7])) [0;1;2;3;4;5;6;7]) =
     MAP f (FILTER P [n0;n1;n2;n3;n4;n5;n6;n7])`,
  REPEAT GEN_TAC THEN
  MP_TAC(ISPECL [`P:byte->bool`; `n0:byte`;`n1:byte`;`n2:byte`;`n3:byte`;
                 `n4:byte`;`n5:byte`;`n6:byte`;`n7:byte`] GATHER_FILTERED_IDX_8) THEN
  DISCH_THEN(fun th -> GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM th]) THEN
  REWRITE_TAC[GSYM MAP_o; o_DEF]);;

let PSHUFB_ACCEPTED_PREFIX = prove
 (`!(g:int128) m. m < 256 ==>
     SUB_LIST(0, LENGTH(ACC_IDX(word m:byte))) (PSHUFB_OUT_LIST g (word m)) =
     MAP (\b:byte. word_subword g (8 * val b,8):byte)
         (MAP word (ACC_IDX(word m:byte)):byte list)`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[PSHUFB_OUT_LIST_AS_MAP] THEN
  REWRITE_TAC[SUB_LIST_0_MAP] THEN
  AP_TERM_TAC THEN
  ASM_SIMP_TAC[TABLE_PREFIX_ACC]);;

let PSHUFB_ACCEPTED_PREFIX_NUM = prove
 (`!(g:int128) m. m < 256 ==>
     SUB_LIST(0, LENGTH(ACC_IDX(word m:byte))) (PSHUFB_OUT_LIST g (word m)) =
     MAP (\j:num. word_subword g (8 * j,8):byte) (ACC_IDX(word m:byte))`,
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[PSHUFB_ACCEPTED_PREFIX] THEN
  REWRITE_TAC[GSYM MAP_o; o_DEF] THEN
  MATCH_MP_TAC MAP_EQ THEN REWRITE_TAC[GSYM ALL_MEM] THEN
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word x:byte) = x` (fun th -> REWRITE_TAC[th]) THEN
  MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_8] THEN
  FIRST_ASSUM(MP_TAC o MATCH_MP ACC_IDX_LT_8) THEN ARITH_TAC);;

let WORD_SUBWORD_BYTE_ID = prove
 (`!x:byte. word_subword x (0,8):byte = x`,
  GEN_TAC THEN CONV_TAC WORD_BLAST);;

let MASK_LOW_BIT = prove
 (`!(p:num->bool) j. j < 8
     ==> (bit j (word(bitval(p 0) + 2 * bitval(p 1) + 4 * bitval(p 2) + 8 * bitval(p 3) +
                       16 * bitval(p 4) + 32 * bitval(p 5) + 64 * bitval(p 6) +
                       128 * bitval(p 7)):byte) <=> p j)`,
  REPEAT GEN_TAC THEN
  DISCH_THEN(DISJ_CASES_TAC o MATCH_MP (ARITH_RULE
    `j < 8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
  POP_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC) THEN
  MAP_EVERY BOOL_CASES_TAC [`(p:num->bool) 0`;`(p:num->bool) 1`;`(p:num->bool) 2`;`(p:num->bool) 3`;
                            `(p:num->bool) 4`;`(p:num->bool) 5`;`(p:num->bool) 6`;`(p:num->bool) 7`] THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC(DEPTH_CONV BIT_WORD_CONV) THEN REWRITE_TAC[]);;

let SUB_LIST_16_BYTES_FROM_INT128 = prove
 (`!buf:int64 buflen inlist i s.
    16 * (i + 1) <= buflen /\
    LENGTH (inlist:byte list) = buflen /\
    read (memory :> bytes (buf, buflen)) s = num_of_wordlist inlist
    ==> SUB_LIST (16 * i, 16) inlist =
        [word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (0,8):byte;
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (8,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (16,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (24,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (32,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (40,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (48,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (56,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (64,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (72,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (80,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (88,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (96,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (104,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (112,8);
         word_subword (read (memory :> bytes128 (word_add buf (word (16 * i)))) s) (120,8)]`,
  REPEAT STRIP_TAC THEN
  ABBREV_TAC
    `loaded_d = read (memory :> bytes128 (word_add buf (word (16 * i)))) s` THEN
  CONV_TAC SYM_CONV THEN
  REWRITE_TAC[LISTS_NUM_OF_WORDLIST_EQ] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[LENGTH; LENGTH_SUB_LIST] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[NUM_OF_WORDLIST_SUB_LIST; DIMINDEX_8] THEN
  FIRST_X_ASSUM(MP_TAC o AP_TERM
    `\x. x DIV 2 EXP (8 * 16 * i) MOD 2 EXP (8 * 16)`) THEN
  CONV_TAC(ONCE_DEPTH_CONV BETA_CONV) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_DIV; READ_BYTES_MOD] THEN
  SUBGOAL_THEN `MIN (buflen - 16 * i) 16 = 16` SUBST1_TAC THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  MP_TAC(ISPECL
    [`word_add buf (word (16 * i)):int64`; `read memory s`]
    (INST_TYPE[`:128`,`:N`] VAL_READ_WBYTES)) THEN
  REWRITE_TAC[DIMINDEX_128] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[GSYM BYTES128_WBYTES; GSYM READ_COMPONENT_COMPOSE] THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  REWRITE_TAC[num_of_wordlist; DIMINDEX_8] THEN
  CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_BLAST);;

let OP8_R8B_READ = prove
 (`!s:x86state. read (OPERAND8 (% r8b) s) s = word(val(read R8 s) MOD 256)`,
  GEN_TAC THEN REWRITE_TAC[OPERAND8; r8b; GPR8; register_size; regsize] THEN
  REWRITE_TAC[GSYM(NUM_EXP_CONV `2 EXP 8`)] THEN
  ONCE_REWRITE_TAC[MESON[EXP; DIV_1] `x MOD 2 EXP n = x DIV 2 EXP 0 MOD 2 EXP n`] THEN
  REWRITE_TAC[GSYM word_subword; READ_COMPONENT_COMPOSE; R8] THEN
  REWRITE_TAC[bottom_32; bottom_16; bottom_8; bottomhalf; READ_SUBWORD] THEN
  ONCE_REWRITE_TAC [WORD_EQ_BITS_ALT] THEN REWRITE_TAC[BIT_WORD_SUBWORD] THEN
  CONV_TAC(ONCE_DEPTH_CONV DIMINDEX_CONV) THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV);;

let MOVZBL_R10_CAPTURE_TAC : tactic =
  RULE_ASSUM_TAC(CONV_RULE(REWRITE_CONV[OP8_R8B_READ] THENC ONCE_DEPTH_CONV COMPONENT_READ_OVER_WRITE_CONV));;

let LACC8 = prove(`!m:byte. LENGTH(ACC_IDX m) <= 8`,
  GEN_TAC THEN REWRITE_TAC[ACC_IDX] THEN
  MP_TAC(ISPECL [`\i. bit i (m:byte)`; `[0;1;2;3;4;5;6;7]:num list`] LENGTH_FILTER) THEN
  REWRITE_TAC[LENGTH] THEN ARITH_TAC);;

let SUBITER_STORE_EXTEND = prove
 (`!res s (prefix:int32 list) (block:int32 list).
     read (memory :> bytes(res, 4 * LENGTH prefix)) s = num_of_wordlist prefix /\
     read (memory :> bytes(word_add res (word (4 * LENGTH prefix)), 4 * LENGTH block)) s
       = num_of_wordlist block
     ==> read (memory :> bytes(res, 4 * LENGTH prefix + 4 * LENGTH block)) s
         = num_of_wordlist (APPEND prefix block)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s:x86state`;
                 `prefix:int32 list`; `block:int32 list`;
                 `4 * LENGTH(prefix:int32 list)`; `4 * LENGTH(block:int32 list)`]
        (INST_TYPE [`:32`,`:N`] BYTES_EQ_NUM_OF_WORDLIST_APPEND)) THEN
  REWRITE_TAC[DIMINDEX_32] THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  ASM_REWRITE_TAC[]);;

let VPMOVSXBD_LANE_EXTRACT = prove
 (`!(x:int64).
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (0,32):int32 = word_sx(word_subword x (0,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (32,32):int32 = word_sx(word_subword x (8,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (64,32):int32 = word_sx(word_subword x (16,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (96,32):int32 = word_sx(word_subword x (24,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (128,32):int32 = word_sx(word_subword x (32,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (160,32):int32 = word_sx(word_subword x (40,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (192,32):int32 = word_sx(word_subword x (48,8):byte)) /\
     (word_subword (usimd8 (\b:byte. word_sx b:int32) x:int256) (224,32):int32 = word_sx(word_subword x (56,8):byte))`,
  GEN_TAC THEN
  REWRITE_TAC[usimd8; usimd4; usimd2] THEN
  SIMP_TAC[WORD_SUBWORD_JOIN_LOWER; WORD_SUBWORD_JOIN_UPPER;
           DIMINDEX_8; DIMINDEX_16; DIMINDEX_32; DIMINDEX_64; DIMINDEX_128;
           DIMINDEX_256; ARITH] THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let VPMOVSXBD_LANE_J = prove
 (`!(x:int64) j. j < 8
    ==> word_subword (usimd8 (\b:byte. word_sx b:int32) x) (32*j,32):int32
        = word_sx (word_subword x (8*j,8):byte)`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[ARITH_RULE `j < 8 <=> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`] THEN
  STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[VPMOVSXBD_LANE_EXTRACT]);;

let WSZ_OK = prove
 (`!(x:int128) j. j < 8
    ==> word_subword (word_zx x:int256) (8 * j,8):byte = word_subword x (8 * j,8)`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  MATCH_MP_TAC (ISPECL [`x:int128`; `8*j`; `8`]
    (INST_TYPE [`:256`,`:N`; `:128`,`:M`; `:8`,`:P`] WORD_SUBWORD_ZX)) THEN
  REWRITE_TAC[DIMINDEX_8;DIMINDEX_128;DIMINDEX_256] THEN
  POP_ASSUM MP_TAC THEN ARITH_TAC);;

let LENGTH_MLDSA_REJ_UNIFORM_TABLE = prove
 (`LENGTH (mldsa_rej_uniform_table:byte list) = 2048`,
  REWRITE_TAC[mldsa_rej_uniform_table; LENGTH] THEN
  CONV_TAC NUM_REDUCE_CONV);;

let LENGTH_TABLE_ENTRY = prove
 (`!m:byte. LENGTH(TABLE_ENTRY m) = 8`,
  GEN_TAC THEN REWRITE_TAC[TABLE_ENTRY; LENGTH_SUB_LIST; LENGTH_MLDSA_REJ_UNIFORM_TABLE] THEN
  MP_TAC(ISPEC `m:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

let VAL4EQ8 = prove
 (`!i:byte. val(word_subword i (0,4):4 word) = val(word_subword i (0,4):8 word)`,
  GEN_TAC THEN REWRITE_TAC[VAL_WORD_SUBWORD] THEN
  SIMP_TAC[DIMINDEX_4;DIMINDEX_8;DIMINDEX_16] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let PSHUF1_LOWLANE_BYTE = prove
 (`!g m j. j < 8
    ==> word_subword
          (word_zx
            (usimd16 (\i. if bit 7 i then word 0:byte
                          else word_subword (g:int128) (8 * val (word_subword i (0,4):4 word),8))
              (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256)
          (8 * j,8):byte
        = word_subword g (8 * val (EL j (TABLE_ENTRY m)),8)`,
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[WSZ_OK] THEN
  REWRITE_TAC[VAL4EQ8] THEN ASM_SIMP_TAC[PSHUFB_OUT_BYTE]);;

let LENGTH_PSHUFB_OUT_LIST = prove
 (`!g:int128. !m:byte. LENGTH(PSHUFB_OUT_LIST g m) = 8`,
  REWRITE_TAC[PSHUFB_OUT_LIST_AS_MAP; LENGTH_MAP; LENGTH_TABLE_ENTRY]);;

let PSHUF1_BYTE_EQ_OUTLIST = prove
 (`!g m j. j < 8
    ==> word_subword
          (word_zx
            (usimd16 (\i. if bit 7 i then word 0:byte
                          else word_subword (g:int128) (8 * val (word_subword i (0,4):4 word),8))
              (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256)
          (8 * j,8):byte
        = EL j (PSHUFB_OUT_LIST g m)`,
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[PSHUF1_LOWLANE_BYTE] THEN
  ASM_SIMP_TAC[PSHUFB_OUT_LIST_AS_MAP; EL_MAP; LENGTH_TABLE_ENTRY]);;

let STORE_LANE_MATCH = prove
 (`!(g:int128) m j. j < 8
    ==> word_subword
          (usimd8 (\b:byte. word_sx b:int32)
            (word_zx (word_zx
              (word_zx
                (usimd16 (\i. if bit 7 i then word 0:byte
                              else word_subword g (8 * val (word_subword i (0,4):4 word),8))
                  (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256)
              :int128):int64))
          (32*j,32):int32
        = word_sx (EL j (PSHUFB_OUT_LIST g m))`,
  REPEAT STRIP_TAC THEN
  ASM_SIMP_TAC[VPMOVSXBD_LANE_J] THEN ASM_SIMP_TAC[WZZ_LOW] THEN
  ASM_SIMP_TAC[PSHUF1_BYTE_EQ_OUTLIST]);;

let SUBWORD_ZX_LOW_CONV : conv =
  fun tm ->
      let inst = PART_MATCH (lhs o snd o dest_imp) SUBWORD_ZX_LOW tm in
      let ant = REWRITE_RULE[DIMINDEX_4;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] inst in
      MP ant (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl ant))));;

let MASK_SHIFT8_MOD256 = prove
 (`!S. val(word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64) MOD 256 =
       (S DIV 256) MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD_USHR; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[VAL_WORD; DIMINDEX_32] THEN CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
  REWRITE_TAC[MM32_64; MOD_MOD_REFL; MM64_256; MM32_DIV256]);;

let LOW24_LT = prove
 (`!p:num->bool. bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) < 16777216`,
  GEN_TAC THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23] THEN ARITH_TAC);;

let BYTE1_DIVMOD = prove
 (`!p:num->bool.
    ((bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
      16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
      256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
      4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
      65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
      1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
      16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
      268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) DIV 256) MOD 256 =
    bitval(p 8) + 2*bitval(p 9) + 4*bitval(p 10) + 8*bitval(p 11) +
    16*bitval(p 12) + 32*bitval(p 13) + 64*bitval(p 14) + 128*bitval(p 15)`,
  GEN_TAC THEN
  SUBGOAL_THEN
   `(bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) =
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7)) +
    256 * (bitval(p 8) + 2*bitval(p 9) + 4*bitval(p 10) + 8*bitval(p 11) +
     16*bitval(p 12) + 32*bitval(p 13) + 64*bitval(p 14) + 128*bitval(p 15) +
     256*(bitval(p 16) + 2*bitval(p 17) + 4*bitval(p 18) + 8*bitval(p 19) +
     16*bitval(p 20) + 32*bitval(p 21) + 64*bitval(p 22) + 128*bitval(p 23) +
     256*(bitval(p 24) + 2*bitval(p 25) + 4*bitval(p 26) + 8*bitval(p 27) +
     16*bitval(p 28) + 32*bitval(p 29) + 64*bitval(p 30) + 128*bitval(p 31))))`
   SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  SIMP_TAC[DIV_MULT_ADD; ARITH_EQ; LOW8_LT; DIV_LT; ADD_CLAUSES] THEN
  GEN_REWRITE_TAC (LAND_CONV o LAND_CONV) [ARITH_RULE
   `bitval (p 8) + 2 * bitval (p 9) + 4 * bitval (p 10) + 8 * bitval (p 11) +
    16 * bitval (p 12) + 32 * bitval (p 13) + 64 * bitval (p 14) + 128 * bitval (p 15) + Z =
    (bitval (p 8) + 2 * bitval (p 9) + 4 * bitval (p 10) + 8 * bitval (p 11) +
     16 * bitval (p 12) + 32 * bitval (p 13) + 64 * bitval (p 14) + 128 * bitval (p 15)) + Z`] THEN
  MATCH_MP_TAC ADD256_MOD THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [8;9;10;11;12;13;14;15] THEN ARITH_TAC);;

let BYTE2_DIVMOD = prove
 (`!p:num->bool.
    ((bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
      16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
      256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
      4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
      65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
      1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
      16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
      268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) DIV 65536) MOD 256 =
    bitval(p 16) + 2*bitval(p 17) + 4*bitval(p 18) + 8*bitval(p 19) +
    16*bitval(p 20) + 32*bitval(p 21) + 64*bitval(p 22) + 128*bitval(p 23)`,
  GEN_TAC THEN
  SUBGOAL_THEN
   `(bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) =
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15)) +
    65536 * ((bitval(p 16) + 2*bitval(p 17) + 4*bitval(p 18) + 8*bitval(p 19) +
     16*bitval(p 20) + 32*bitval(p 21) + 64*bitval(p 22) + 128*bitval(p 23)) +
     256*(bitval(p 24) + 2*bitval(p 25) + 4*bitval(p 26) + 8*bitval(p 27) +
     16*bitval(p 28) + 32*bitval(p 29) + 64*bitval(p 30) + 128*bitval(p 31)))`
   SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  SIMP_TAC[DIV_MULT_ADD; ARITH_EQ; LOW16_LT; DIV_LT; ADD_CLAUSES] THEN
  MATCH_MP_TAC ADD256_MOD THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [16;17;18;19;20;21;22;23] THEN ARITH_TAC);;

let BYTE3_DIVMOD = prove
 (`!p:num->bool.
    ((bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
      16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
      256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
      4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
      65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
      1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
      16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
      268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) DIV 16777216) MOD 256 =
    bitval(p 24) + 2*bitval(p 25) + 4*bitval(p 26) + 8*bitval(p 27) +
    16*bitval(p 28) + 32*bitval(p 29) + 64*bitval(p 30) + 128*bitval(p 31)`,
  GEN_TAC THEN
  SUBGOAL_THEN
   `(bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) =
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23)) +
    16777216 * (bitval(p 24) + 2*bitval(p 25) + 4*bitval(p 26) + 8*bitval(p 27) +
     16*bitval(p 28) + 32*bitval(p 29) + 64*bitval(p 30) + 128*bitval(p 31))`
   SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
  SIMP_TAC[DIV_MULT_ADD; ARITH_EQ; LOW24_LT; DIV_LT; ADD_CLAUSES] THEN
  MATCH_MP_TAC MOD_LT THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [24;25;26;27;28;29;30;31] THEN ARITH_TAC);;

let MASK_SHIFT16_MOD256 = prove
 (`!S. val(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64):int32) 8):int64) MOD 256 =
       (S DIV 65536) MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[MASK_USHR8_STEP; VAL_MASK8B; DIV_DIV] THEN
  REWRITE_TAC[ARITH_RULE `256 * 256 = 65536`] THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`; ARITH_RULE `65536 = 2 EXP 16`; ARITH_RULE `256 = 2 EXP 8`] THEN
  REWRITE_TAC[divmod_swap16] THEN
  REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let MASK_SHIFT24_MOD256 = prove
 (`!S. val(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word S:int32):int64):int32) 8):int64):int32) 8):int64):int32) 8):int64) MOD 256 =
       (S DIV 16777216) MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[MASK_USHR8_STEP; VAL_MASK8C; DIV_DIV] THEN
  REWRITE_TAC[ARITH_RULE `65536 * 256 = 16777216`] THEN
  REWRITE_TAC[ARITH_RULE `4294967296 = 2 EXP 32`; ARITH_RULE `16777216 = 2 EXP 24`; ARITH_RULE `256 = 2 EXP 8`] THEN
  REWRITE_TAC[divmod_swap24] THEN
  REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC NUM_REDUCE_CONV);;

let POPCNT_BYTE1 = prove
 (`!p:num->bool.
     word_popcount
       (word_zx (word_zx (word_zx
          (word (val (word_zx (word_ushr (word_zx (word_zx
             (word (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
              16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
              256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
              4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
              65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
              1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
              16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
              268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)):int32):int64):int32) 8):int64)
            MOD 256):int32):int32):int32):int32) =
     bitval(p 8) + bitval(p 9) + bitval(p 10) + bitval(p 11) +
     bitval(p 12) + bitval(p 13) + bitval(p 14) + bitval(p 15)`,
  GEN_TAC THEN
  REWRITE_TAC[MASK_SHIFT8_MOD256; BYTE1_DIVMOD] THEN
  MAP_EVERY (fun k -> BOOL_CASES_TAC (mk_comb(`p:num->bool`, mk_small_numeral k)))
    [8;9;10;11;12;13;14;15] THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC WORD_REDUCE_CONV);;

let POPCNT_BYTE2 =
  let arg = subst [SUMTERM_BYTE23, `SUMV:num`]
    (subst [`word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word SUMV:int32):int64):int32) 8):int64):int32) 8):int64`, `MASKC:int64`]
       `word_zx(word_zx(word_zx(word(val (MASKC:int64) MOD 256):byte):int32):int64):int32`) in
  prove(mk_forall(`p:num->bool`, mk_eq(mk_comb(`word_popcount:int32->num`, arg),
     `bitval(p 16) + bitval(p 17) + bitval(p 18) + bitval(p 19) +
      bitval(p 20) + bitval(p 21) + bitval(p 22) + bitval(p 23)`)),
    GEN_TAC THEN REWRITE_TAC[MASK_SHIFT16_MOD256; BYTE2_DIVMOD] THEN
    MAP_EVERY (fun k -> BOOL_CASES_TAC (mk_comb(`p:num->bool`, mk_small_numeral k)))
      [16;17;18;19;20;21;22;23] THEN
    REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV);;

let POPCNT_BYTE3 =
  let arg = subst [SUMTERM_BYTE23, `SUMV:num`]
    (subst [`word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word SUMV:int32):int64):int32) 8):int64):int32) 8):int64):int32) 8):int64`, `MASKC:int64`]
       `word_zx(word_zx(word_zx(word(val (MASKC:int64) MOD 256):byte):int32):int64):int32`) in
  prove(mk_forall(`p:num->bool`, mk_eq(mk_comb(`word_popcount:int32->num`, arg),
     `bitval(p 24) + bitval(p 25) + bitval(p 26) + bitval(p 27) +
      bitval(p 28) + bitval(p 29) + bitval(p 30) + bitval(p 31)`)),
    GEN_TAC THEN REWRITE_TAC[MASK_SHIFT24_MOD256; BYTE3_DIVMOD] THEN
    MAP_EVERY (fun k -> BOOL_CASES_TAC (mk_comb(`p:num->bool`, mk_small_numeral k)))
      [24;25;26;27;28;29;30;31] THEN
    REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV);;

let zxbyte_eq = prove
 (`!v. v < 256 ==>
     word_zx(word_zx(word_zx(word v:byte):int32):int64):int32 =
     word_zx(word_zx(word_zx(word v:int32):int32):int32):int32`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM VAL_EQ] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `v < 256 ==> v < 2 EXP 8 /\ v < 2 EXP 32 /\ v < 2 EXP 64`] THEN
  CONV_TAC(DEPTH_CONV NUM_REDUCE_CONV) THEN
  ASM_SIMP_TAC[MOD_LT; ARITH_RULE `v < 256 ==> v < 2 EXP 8 /\ v < 2 EXP 32`]);;

let MASKBIT_TGT_TAC : tactic =
  W(fun (asl,w) ->
    let m8 = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8:int64` &&
        can(find_term(fun u->match u with Const("bitval",_)->true|_->false))(concl th)) (map snd asl) in
    let sum32 = rand(rand(lhand(concl m8))) in
    let summands = striplist (dest_binop `(+):num->num->num`) sum32 in
    let getbitval s = if is_binop `( * ):num->num->num` s then rand s else s in
    let bvs = map getbitval summands in
    let sum8 = end_itlist (fun a b -> mk_binop `(+):num->num->num` a b)
      (List.map2 (fun wt bv -> if wt=1 then bv else mk_binop `( * ):num->num->num` (mk_small_numeral wt) bv) [1;2;4;8;16;32;64;128] (map (fun i->List.nth bvs i) (0--7))) in
    let high = end_itlist (fun a b -> mk_binop `(+):num->num->num` a b)
      (map (fun i -> let wt = 1 lsl (i-8) in if wt=1 then List.nth bvs i else mk_binop `( * ):num->num->num` (mk_small_numeral wt) (List.nth bvs i)) (8--31)) in
    let splitth = prove(mk_eq(sum32, mk_binop `(+):num->num->num` sum8 (mk_binop `( * ):num->num->num` `256` high)), ARITH_TAC) in
    let byteeq32 = TRANS (AP_TERM `word:num->byte` splitth) (SPECL [sum8; high] WORD_ADD_256_BYTE) in
    let beq = mk_eq(`word (val (mask8:int64) MOD 256):byte`, mk_comb(`word:num->byte`, sum8)) in
    let preds8 = map (fun i -> rand (List.nth bvs i)) (0--7) in
    let plist = mk_abs(`k:num`, mk_comb(mk_comb(`EL:num->(bool)list->bool`,`k:num`),
       (end_itlist (fun a b -> mk_binop `CONS:bool->(bool)list->(bool)list` a b) (preds8 @ [`[]:(bool)list`])))) in
    let mb0 = find (fun th -> let c=concl th in is_forall c &&
        can(find_term(fun u->u=`f1bnd:int256`))c &&
        can(find_term(fun u->match u with Comb(Const("bit",_),_)->true|_->false))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c)) (map snd asl) in
    let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mb0 in
       CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
    SUBGOAL_THEN beq ASSUME_TAC THENL
     [SUBGOAL_THEN (mk_eq(`val (mask8:int64)`, mk_binop `MOD` sum32 `2 EXP 32`)) SUBST1_TAC THENL
       [SUBST1_TAC(SYM m8) THEN REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_64; DIMINDEX_32] THEN
        MATCH_MP_TAC MOD_LT THEN MP_TAC(SPECL [sum32; `2 EXP 32`] MOD_LT_EQ) THEN REWRITE_TAC[EXP_EQ_0; ARITH_EQ] THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN (mk_eq(mk_binop `MOD` (mk_binop `MOD` sum32 `2 EXP 32`) `256`, mk_binop `MOD` sum32 `256`)) SUBST1_TAC THENL
       [REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`] THEN REWRITE_TAC[MOD_MOD_EXP_MIN] THEN CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV); ALL_TAC] THEN
      REWRITE_TAC[WORD_BYTE_MOD] THEN ACCEPT_TAC byteeq32;
      ALL_TAC] THEN
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(fun beqth -> if is_eq(concl beqth) && lhand(concl beqth)=`word (val (mask8:int64) MOD 256):byte` then REWRITE_TAC[beqth] else NO_TAC) THEN
    MP_TAC(SPECL [plist; `j:num`] MASK_LOW_BIT) THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
      (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC mbs THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC);;

let F0NIB_CHUNK0 =
  `word_and (word_or (usimd16 (\b:byte. word_zx b:int16) chunk0:int256)
                     (usimd16 (\z:int16. word_shl z 4) (usimd16 (\b:byte. word_zx b:int16) chunk0:int256):int256))
            (word 6811299366900952671974763824040465167839410862684739061144563765171360567055:int256)`;;

let STORE_LANE_EQ_REJBLOCK = prove
 (`!(g:int128) m k j. j < k /\ k <= 8
    ==> word_subword
          (usimd8 (\b:byte. word_sx b:int32)
            (word_zx (word_zx
              (word_zx
                (usimd16 (\i. if bit 7 i then word 0:byte
                              else word_subword g (8 * val (word_subword i (0,4):4 word),8))
                  (word_zx (word_zx (word (num_of_wordlist (TABLE_ENTRY m)):int64):int128):int128)):int256)
              :int128):int64))
          (32*j,32):int32
        = EL j (MAP (\b:byte. word_sx b:int32) (SUB_LIST(0,k) (PSHUFB_OUT_LIST g m)))`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `j < 8` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[STORE_LANE_MATCH] THEN
  SUBGOAL_THEN `LENGTH(SUB_LIST(0,k)(PSHUFB_OUT_LIST (g:int128) m)) = k` ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST; LENGTH_PSHUFB_OUT_LIST] THEN ASM_ARITH_TAC;
    ASM_SIMP_TAC[EL_MAP] THEN
    ASM_SIMP_TAC[EL_SUB_LIST; LENGTH_PSHUFB_OUT_LIST; ADD_CLAUSES] THEN
    ASM_ARITH_TAC]);;

let pf_target =
  `pshuf1:int256 =
   word_zx
   (usimd16
    (\i:byte. if bit 7 i
         then word 0:byte
         else word_subword (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128)
              (8 * val (word_subword i (0,4):4 word),8):byte)
   (word_zx
   (word_zx (word (num_of_wordlist (TABLE_ENTRY (word (val (mask8:int64) MOD 256):byte))):int64):int128):int128):int128)`;;

let MASKBIT_TGT_2_TAC : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let m8b = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8b:int64` &&
        can(find_term(fun u->match u with Const("bitval",_)->true|_->false))(concl th)) asms in
    let sum32 = find_term (fun u -> match u with
       Comb(Comb(Const("+",_),_),_) -> can(find_term(fun v->match v with Const("bitval",_)->true|_->false)) u | _ -> false) (concl m8b) in
    let summands = striplist (dest_binop `(+):num->num->num`) sum32 in
    let getbitval s = if is_binop `( * ):num->num->num` s then rand s else s in
    let bvs = map getbitval summands in
    let mksum idxs wts = end_itlist (fun a b -> mk_binop `(+):num->num->num` a b)
       (List.map2 (fun wt i -> let bv = List.nth bvs i in if wt=1 then bv else mk_binop `( * ):num->num->num` (mk_small_numeral wt) bv) wts idxs) in
    let sum_low8 = mksum [0;1;2;3;4;5;6;7] [1;2;4;8;16;32;64;128] in
    let sum8' = mksum [8;9;10;11;12;13;14;15] [1;2;4;8;16;32;64;128] in
    let sum_high16 = mksum (16--31) (map (fun i->1 lsl (i-16)) (16--31)) in
    let regroup = prove(mk_eq(sum32, mk_binop `(+):num->num->num` sum_low8
       (mk_binop `(+):num->num->num` (mk_binop `( * ):num->num->num` `256` sum8')
                                      (mk_binop `( * ):num->num->num` `65536` sum_high16))), ARITH_TAC) in
    let low8lt = prove(mk_binop `(<):num->num->bool` sum_low8 `256`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (0--7)))) THEN ARITH_TAC) in
    let s8lt = prove(mk_binop `(<):num->num->bool` sum8' `256`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (8--15)))) THEN ARITH_TAC) in
    let vshift = SPEC sum32 MASK_SHIFT8_MOD256 in
    let dms = MP (SPECL [sum_low8; sum8'; sum_high16] DIVMOD256_SPLIT) (CONJ low8lt s8lt) in
    let valeq = REWRITE_RULE[m8b] (TRANS vshift (TRANS (AP_THM (AP_TERM `(MOD)` (AP_THM (AP_TERM `(DIV)` regroup) `256`)) `256`) dms)) in
    let beq = mk_eq(`word (val (mask8b:int64) MOD 256):byte`, mk_comb(`word:num->byte`, sum8')) in
    let preds8 = map (fun i -> rand (List.nth bvs i)) (8--15) in
    let plist = mk_abs(`k:num`, mk_comb(mk_comb(`EL:num->(bool)list->bool`,`k:num`),
       (end_itlist (fun a b -> mk_binop `CONS:bool->(bool)list->(bool)list` a b) (preds8 @ [`[]:(bool)list`])))) in
    let mb2 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c) &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c)) asms in
    let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mb2 in
       CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
    SUBGOAL_THEN beq ASSUME_TAC THENL
     [REWRITE_TAC[AP_TERM `word:num->byte` valeq];
      ALL_TAC] THEN
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(fun beqth -> if is_eq(concl beqth) && lhand(concl beqth)=`word (val (mask8b:int64) MOD 256):byte` then REWRITE_TAC[beqth] else NO_TAC) THEN
    MP_TAC(SPECL [plist; `j:num`] MASK_LOW_BIT) THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
      (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC mbs THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC);;

let pf_target_2 =
  let g1 = `word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128` in
  let g2 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128) 64):int128):int128` in
  subst [g2,g1; `mask8b:int64`,`mask8:int64`; `pshuf2:int256`,`pshuf1:int256`] pf_target;;

let MASKBIT_TGT_3_TAC : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let m8c_def = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8c:int64` &&
        can(find_term(fun u->u=`mask8b:int64`))(concl th)) asms in
    let m8b_def = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8b:int64` &&
        can(find_term(fun u->match u with Const("bitval",_)->true|_->false))(concl th)) asms in
    let sum32 = find_term (fun u -> match u with
       Comb(Comb(Const("+",_),_),_) -> can(find_term(fun v->match v with Const("bitval",_)->true|_->false)) u | _ -> false) (concl m8b_def) in
    let summands = striplist (dest_binop `(+):num->num->num`) sum32 in
    let getbitval s = if is_binop `( * ):num->num->num` s then rand s else s in
    let bvs = map getbitval summands in
    let mksum idxs wts = end_itlist (fun a b -> mk_binop `(+):num->num->num` a b)
       (List.map2 (fun wt i -> let bv = List.nth bvs i in if wt=1 then bv else mk_binop `( * ):num->num->num` (mk_small_numeral wt) bv) wts idxs) in
    let low16 = mksum (0--15) (map (fun i->1 lsl i) (0--15)) in
    let sum8'' = mksum [16;17;18;19;20;21;22;23] [1;2;4;8;16;32;64;128] in
    let high8 = mksum (24--31) (map (fun i->1 lsl (i-24)) (24--31)) in
    let regroup = prove(mk_eq(sum32, mk_binop `(+):num->num->num` low16
       (mk_binop `(+):num->num->num` (mk_binop `( * ):num->num->num` `65536` sum8'')
                                      (mk_binop `( * ):num->num->num` `16777216` high8))), ARITH_TAC) in
    let low16lt = prove(mk_binop `(<):num->num->bool` low16 `65536`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (0--15)))) THEN ARITH_TAC) in
    let s8lt = prove(mk_binop `(<):num->num->bool` sum8'' `256`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (16--23)))) THEN ARITH_TAC) in
    let m8c_over_sum = REWRITE_RULE[SYM m8b_def] m8c_def in
    let vshift = SPEC sum32 MASK_SHIFT16_MOD256 in
    let dms = MP (SPECL [low16; sum8''; high8] DIVMOD65536_SPLIT) (CONJ low16lt s8lt) in
    let valeq = TRANS (REWRITE_RULE[m8c_over_sum] vshift) (TRANS (AP_THM (AP_TERM `(MOD)` (AP_THM (AP_TERM `(DIV)` regroup) `65536`)) `256`) dms) in
    let beq = mk_eq(`word (val (mask8c:int64) MOD 256):byte`, mk_comb(`word:num->byte`, sum8'')) in
    let preds8 = map (fun i -> rand (List.nth bvs i)) (16--23) in
    let plist = mk_abs(`k:num`, mk_comb(mk_comb(`EL:num->(bool)list->bool`,`k:num`),
       (end_itlist (fun a b -> mk_binop `CONS:bool->(bool)list->(bool)list` a b) (preds8 @ [`[]:(bool)list`])))) in
    let mb3 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c) &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (56,8):byte`))c)) asms in
    let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mb3 in
       CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
    SUBGOAL_THEN beq ASSUME_TAC THENL
     [REWRITE_TAC[AP_TERM `word:num->byte` valeq];
      ALL_TAC] THEN
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(fun beqth -> if is_eq(concl beqth) && lhand(concl beqth)=`word (val (mask8c:int64) MOD 256):byte` then REWRITE_TAC[beqth] else NO_TAC) THEN
    MP_TAC(SPECL [plist; `j:num`] MASK_LOW_BIT) THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
      (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC mbs THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC);;

let pf_target_3 =
  let g1 = `word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128` in
  let g3 = `word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128` in
  subst [g3,g1; `mask8c:int64`,`mask8:int64`; `pshuf3:int256`,`pshuf1:int256`] pf_target;;

let MASKBIT_TGT_4_TAC : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let m8d_def = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8d:int64` && can(find_term(fun u->u=`mask8c:int64`))(concl th)) asms in
    let m8c_def = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8c:int64` && can(find_term(fun u->u=`mask8b:int64`))(concl th)) asms in
    let m8b_def = find (fun th -> is_eq(concl th) && rand(concl th)=`mask8b:int64` && can(find_term(fun u->match u with Const("bitval",_)->true|_->false))(concl th)) asms in
    let sum32 = find_term (fun u -> match u with
       Comb(Comb(Const("+",_),_),_) -> can(find_term(fun v->match v with Const("bitval",_)->true|_->false)) u | _ -> false) (concl m8b_def) in
    let summands = striplist (dest_binop `(+):num->num->num`) sum32 in
    let getbitval s = if is_binop `( * ):num->num->num` s then rand s else s in
    let bvs = map getbitval summands in
    let mksum idxs wts = end_itlist (fun a b -> mk_binop `(+):num->num->num` a b)
       (List.map2 (fun wt i -> let bv = List.nth bvs i in if wt=1 then bv else mk_binop `( * ):num->num->num` (mk_small_numeral wt) bv) wts idxs) in
    let low24 = mksum (0--23) (map (fun i->1 lsl i) (0--23)) in
    let sum8''' = mksum [24;25;26;27;28;29;30;31] [1;2;4;8;16;32;64;128] in
    let regroup = prove(mk_eq(sum32, mk_binop `(+):num->num->num` low24
       (mk_binop `( * ):num->num->num` `16777216` sum8''')), ARITH_TAC) in
    let low24lt = prove(mk_binop `(<):num->num->bool` low24 `16777216`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (0--23)))) THEN ARITH_TAC) in
    let s8lt = prove(mk_binop `(<):num->num->bool` sum8''' `256`,
       MP_TAC(end_itlist CONJ (map (fun b -> SPEC b BITVAL_BOUND) (map (fun i->rand(List.nth bvs i)) (24--31)))) THEN ARITH_TAC) in
    (* mask8d over SUM32: subst mask8c def (over mask8b) then mask8b def (over SUM32) *)
    let m8d_over_sum = REWRITE_RULE[SYM m8b_def] (REWRITE_RULE[SYM m8c_def] m8d_def) in
    let vshift = SPEC sum32 MASK_SHIFT24_MOD256 in
    let dms = MP (SPECL [low24; sum8'''] DIVMOD16777216_SPLIT) low24lt in
    let s8mod = prove(mk_eq(mk_binop `MOD` sum8''' `256`, sum8'''), MATCH_MP_TAC MOD_LT THEN ACCEPT_TAC s8lt) in
    let valeq = TRANS (REWRITE_RULE[m8d_over_sum] vshift)
                  (TRANS (AP_THM (AP_TERM `(MOD)` (AP_THM (AP_TERM `(DIV)` regroup) `16777216`)) `256`) (TRANS dms s8mod)) in
    let beq = mk_eq(`word (val (mask8d:int64) MOD 256):byte`, mk_comb(`word:num->byte`, sum8''')) in
    let preds8 = map (fun i -> rand (List.nth bvs i)) (24--31) in
    let plist = mk_abs(`k:num`, mk_comb(mk_comb(`EL:num->(bool)list->bool`,`k:num`),
       (end_itlist (fun a b -> mk_binop `CONS:bool->(bool)list->(bool)list` a b) (preds8 @ [`[]:(bool)list`])))) in
    let mb4 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (120,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (64,8):byte`))c)) asms in
    let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mb4 in
       CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
    SUBGOAL_THEN beq ASSUME_TAC THENL
     [REWRITE_TAC[AP_TERM `word:num->byte` valeq];
      ALL_TAC] THEN
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(fun beqth -> if is_eq(concl beqth) && lhand(concl beqth)=`word (val (mask8d:int64) MOD 256):byte` then REWRITE_TAC[beqth] else NO_TAC) THEN
    MP_TAC(SPECL [plist; `j:num`] MASK_LOW_BIT) THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
    ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
    FIRST_ASSUM(REPEAT_TCL DISJ_CASES_THEN SUBST1_TAC o MATCH_MP
      (ARITH_RULE `j<8 ==> j=0\/j=1\/j=2\/j=3\/j=4\/j=5\/j=6\/j=7`)) THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC mbs THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC);;

let pf_target_4 =
  let g1 = `word_zx (word_zx (word_subword (f0sub:int256) (0,128):int128):int128):int128` in
  let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
  subst [g4,g1; `mask8d:int64`,`mask8:int64`; `pshuf4:int256`,`pshuf1:int256`] pf_target;;

let SL16_4WAY = prove
 (`SUB_LIST(16*i,16) (inlist:byte list) =
   APPEND (SUB_LIST(16*i,4) inlist)
   (APPEND (SUB_LIST(16*i+4,4) inlist)
   (APPEND (SUB_LIST(16*i+8,4) inlist) (SUB_LIST(16*i+12,4) inlist)))`,
  MP_TAC(ISPECL[`inlist:byte list`;`4`;`12`;`16*i`] SUB_LIST_SPLIT) THEN
  MP_TAC(ISPECL[`inlist:byte list`;`4`;`8`;`16*i+4`] SUB_LIST_SPLIT) THEN
  MP_TAC(ISPECL[`inlist:byte list`;`4`;`4`;`16*i+8`] SUB_LIST_SPLIT) THEN
  REWRITE_TAC[ARITH_RULE `(16*i+4)+4=16*i+8`; ARITH_RULE `(16*i+8)+4=16*i+12`;
    ARITH_RULE `4+8=12`; ARITH_RULE `4+4=8`; ARITH_RULE `4+12=16`] THEN
  REPEAT(DISCH_THEN SUBST1_TAC) THEN REFL_TAC);;

let MM_4G_4G = prove(`!a. a MOD 4294967296 MOD 4294967296 = a MOD 4294967296`, REWRITE_TAC[MOD_MOD_REFL]);;

let MM_4G_18 = prove(`!a. a MOD 4294967296 MOD 18446744073709551616 = a MOD 4294967296`,
  GEN_TAC THEN MATCH_MP_TAC MOD_LT THEN
  MP_TAC(SPECL[`a:num`;`4294967296`] MOD_LT_EQ) THEN CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

let STORE4_FROM_SPEC sN addrt =
  REWRITE_TAC[bytes32; READ_COMPONENT_COMPOSE; asword; through; read] THEN
  DISCH_THEN(MP_TAC o AP_TERM `val:int32->num`) THEN REWRITE_TAC[VAL_WORD] THEN
  SUBGOAL_THEN (subst[sN,`s:x86state`;addrt,`a:int64`]
     `read (bytes (a:int64,4)) (read memory (s:x86state)) < 2 EXP dimindex(:32)`) ASSUME_TAC THENL
   [REWRITE_TAC[DIMINDEX_32] THEN
    MP_TAC(ISPECL[addrt;`4`;mk_comb(`read memory:x86state->int64->byte`,sN)] READ_BYTES_BOUND) THEN
    CONV_TAC NUM_REDUCE_CONV THEN REWRITE_TAC[MULT_CLAUSES] THEN ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[MOD_LT] THEN REWRITE_TAC[READ_COMPONENT_COMPOSE] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN REFL_TAC;;

let JA_TAKEN_GT = prove
 (`!a k:num. k < a /\ a < 2 EXP 32
     ==> ~(~(&(val(word_zx(word a:int64):int32)):int - &k =
             &(val(word_sub(word_zx(word a:int64):int32) (word k):int32))) \/
           val(word_sub(word_zx(word a:int64):int32) (word k):int32) = 0)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `val(word_zx(word a:int64):int32) = a` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_ZX_64_32 THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `val(word_sub (word_zx(word a:int64):int32) (word k:int32)) = a - k` ASSUME_TAC THENL
   [REWRITE_TAC[VAL_WORD_SUB_CASES; DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN
    SUBGOAL_THEN `val(word k:int32) = k` SUBST1_TAC THENL
     [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_32] THEN ASM_ARITH_TAC; ALL_TAC] THEN
    COND_CASES_TAC THENL [REFL_TAC; REPEAT(POP_ASSUM MP_TAC) THEN ARITH_TAC]; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `(a - k = 0) <=> F` SUBST1_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[] THEN
  MP_TAC(SPECL[`k:num`;`a:num`] INT_OF_NUM_SUB) THEN ANTS_TAC THENL
   [ASM_ARITH_TAC; DISCH_THEN(SUBST1_TAC) THEN REWRITE_TAC[]]);;

let RCX4_COLLAPSE = prove
 (`!a:num. a + 4 < 2 EXP 32 ==> word_zx(word_add(word_zx(word a:int64):int32)(word 4:int32)):int64 = word(a + 4)`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM VAL_EQ] THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; DIMINDEX_64; DIMINDEX_32; VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
  SUBGOAL_THEN `a MOD 2 EXP 64 = a` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC; ALL_TAC] THEN
  CONV_TAC MOD_DOWN_CONV THEN
  SUBGOAL_THEN `(a + 4) MOD 2 EXP 32 = a + 4` SUBST1_TAC THENL
   [MATCH_MP_TAC MOD_LT THEN ASM_REWRITE_TAC[]; REFL_TAC]);;
