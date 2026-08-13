(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Public acceptance pattern for eta rejection sampling.                    *)
(*                                                                           *)
(* The variable-time eta2/eta4 kernels may reveal which candidate nibbles   *)
(* are accepted. They must not reveal the accepted nibble values themselves. *)
(* The boolean list below records exactly that declassified pattern, in the  *)
(* same low-nibble/high-nibble order as NIBBLES_OF_BYTES.                    *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/base.ml";;

let MLDSA_REJ_ACCEPTANCE_BITMAP = define
 `MLDSA_REJ_ACCEPTANCE_BITMAP bound ([]:byte list) = [] /\
  MLDSA_REJ_ACCEPTANCE_BITMAP bound (CONS (b:byte) t) =
    CONS (val b MOD 16 < bound)
      (CONS (val b DIV 16 < bound)
        (MLDSA_REJ_ACCEPTANCE_BITMAP bound t))`;;

let MLDSA_REJ_UNIFORM_ETA2_ACCEPTANCE_BITMAP = new_definition
 `MLDSA_REJ_UNIFORM_ETA2_ACCEPTANCE_BITMAP (l:byte list) =
    MLDSA_REJ_ACCEPTANCE_BITMAP 15 l`;;

let MLDSA_REJ_UNIFORM_ETA4_ACCEPTANCE_BITMAP = new_definition
 `MLDSA_REJ_UNIFORM_ETA4_ACCEPTANCE_BITMAP (l:byte list) =
    MLDSA_REJ_ACCEPTANCE_BITMAP 9 l`;;

let MLDSA_REJ_ACCEPTANCE_BITMAP_APPEND = prove
 (`!bound (l1:byte list) l2.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound (APPEND l1 l2) =
     APPEND (MLDSA_REJ_ACCEPTANCE_BITMAP bound l1)
            (MLDSA_REJ_ACCEPTANCE_BITMAP bound l2)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP; APPEND]);;

let MLDSA_REJ_ACCEPTANCE_BITMAP_LENGTH = prove
 (`!bound (l:byte list).
     LENGTH(MLDSA_REJ_ACCEPTANCE_BITMAP bound l) = 2 * LENGTH l`,
  REPEAT GEN_TAC THEN
  SPEC_TAC(`l:byte list`,`l:byte list`) THEN
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP; LENGTH] THEN
  ARITH_TAC);;

let FILTER_PREDICATE_MAP_LENGTH = prove
 (`!p (l:A list). LENGTH(FILTER p l) = LENGTH(FILTER I (MAP p l))`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[FILTER; MAP; LENGTH; I_THM] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

let MLDSA_REJ_ACCEPTANCE_COUNT = new_definition
 `MLDSA_REJ_ACCEPTANCE_COUNT bound (l:byte list) =
    LENGTH(FILTER I (MLDSA_REJ_ACCEPTANCE_BITMAP bound l))`;;

let MLDSA_REJ_ACCEPTANCE_COUNT_APPEND = prove
 (`!bound (l1:byte list) l2.
     MLDSA_REJ_ACCEPTANCE_COUNT bound (APPEND l1 l2) =
     MLDSA_REJ_ACCEPTANCE_COUNT bound l1 +
     MLDSA_REJ_ACCEPTANCE_COUNT bound l2`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT;
              MLDSA_REJ_ACCEPTANCE_BITMAP_APPEND;
              FILTER_APPEND; LENGTH_APPEND]);;

(* The table lookup index for four source bytes is the little-endian mask of
   their eight acceptance bits. *)
let MLDSA_REJ_ACCEPTANCE_MASK = define
 `MLDSA_REJ_ACCEPTANCE_MASK ([]:bool list) = 0 /\
  MLDSA_REJ_ACCEPTANCE_MASK (CONS h t) =
    bitval h + 2 * MLDSA_REJ_ACCEPTANCE_MASK t`;;

let MLDSA_REJ_ACCEPTANCE_MASK_8 = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
     MLDSA_REJ_ACCEPTANCE_MASK [b0;b1;b2;b3;b4;b5;b6;b7] =
     bitval b0 + 2 * bitval b1 + 4 * bitval b2 + 8 * bitval b3 +
     16 * bitval b4 + 32 * bitval b5 + 64 * bitval b6 +
     128 * bitval b7`,
  REPEAT GEN_TAC THEN REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_MASK] THEN
  ARITH_TAC);;

let MLDSA_REJ_ACCEPTANCE_TABLE_INDEX_4 = prove
 (`!bound b0 b1 b2 b3:byte.
     MLDSA_REJ_ACCEPTANCE_MASK
       (MLDSA_REJ_ACCEPTANCE_BITMAP bound [b0;b1;b2;b3]) =
     bitval(val b0 MOD 16 < bound) +
     2 * bitval(val b0 DIV 16 < bound) +
     4 * bitval(val b1 MOD 16 < bound) +
     8 * bitval(val b1 DIV 16 < bound) +
     16 * bitval(val b2 MOD 16 < bound) +
     32 * bitval(val b2 DIV 16 < bound) +
     64 * bitval(val b3 MOD 16 < bound) +
     128 * bitval(val b3 DIV 16 < bound)`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP; MLDSA_REJ_ACCEPTANCE_MASK] THEN
  ARITH_TAC);;

(* Exact arithmetic shape produced by UADDLV after the eight comparison lanes
   have been ANDed with weights 1,2,...,128. *)
let MLDSA_REJ_ACCEPTANCE_MASK_WORD_SUM_8 = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
     val
      (word_add
        (word_and (word 1:int128) (word_neg(word(bitval b0))))
        (word_add
          (word_and (word 2:int128) (word_neg(word(bitval b1))))
          (word_add
            (word_and (word 4:int128) (word_neg(word(bitval b2))))
            (word_add
              (word_and (word 8:int128) (word_neg(word(bitval b3))))
              (word_add
                (word_and (word 16:int128) (word_neg(word(bitval b4))))
                (word_add
                  (word_and (word 32:int128) (word_neg(word(bitval b5))))
                  (word_add
                    (word_and (word 64:int128) (word_neg(word(bitval b6))))
                    (word_and (word 128:int128)
                              (word_neg(word(bitval b7))))))))))) =
     MLDSA_REJ_ACCEPTANCE_MASK [b0;b1;b2;b3;b4;b5;b6;b7]`,
  REPEAT GEN_TAC THEN
  BOOL_CASES_TAC `b0:bool` THEN BOOL_CASES_TAC `b1:bool` THEN
  BOOL_CASES_TAC `b2:bool` THEN BOOL_CASES_TAC `b3:bool` THEN
  BOOL_CASES_TAC `b4:bool` THEN BOOL_CASES_TAC `b5:bool` THEN
  BOOL_CASES_TAC `b6:bool` THEN BOOL_CASES_TAC `b7:bool` THEN
  ASM_REWRITE_TAC[bitval; MLDSA_REJ_ACCEPTANCE_MASK] THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
  CONV_TAC NUM_REDUCE_CONV);;

let MLDSA_REJ_ACCEPTANCE_COUNT_4 = prove
 (`!bound b0 b1 b2 b3:byte.
     MLDSA_REJ_ACCEPTANCE_COUNT bound [b0;b1;b2;b3] =
     bitval(val b0 MOD 16 < bound) +
     bitval(val b0 DIV 16 < bound) +
     bitval(val b1 MOD 16 < bound) +
     bitval(val b1 DIV 16 < bound) +
     bitval(val b2 MOD 16 < bound) +
     bitval(val b2 DIV 16 < bound) +
     bitval(val b3 MOD 16 < bound) +
     bitval(val b3 DIV 16 < bound)`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT; MLDSA_REJ_ACCEPTANCE_BITMAP;
              FILTER; I_THM; LENGTH] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[bitval; LENGTH]) THEN
  ARITH_TAC);;

(* Exact arithmetic shape produced by the second UADDLV, after CNT has turned
   each weighted acceptance lane into zero or one. *)
let MLDSA_REJ_ACCEPTANCE_COUNT_WORD_SUM_8 = prove
 (`!b0 b1 b2 b3 b4 b5 b6 b7.
     val(word_zx(word_subword
       (word_add
         (word_subword
           (word_join (word 0:byte) (word(bitval b0):byte):int16)
           (0,16):int128)
         (word_add
           (word_subword
             (word_join (word 0:byte) (word(bitval b1):byte):int16)
             (0,16):int128)
           (word_add
             (word_subword
               (word_join (word 0:byte) (word(bitval b2):byte):int16)
               (0,16):int128)
             (word_add
               (word_subword
                 (word_join (word 0:byte) (word(bitval b3):byte):int16)
                 (0,16):int128)
               (word_add
                 (word_subword
                   (word_join (word 0:byte) (word(bitval b4):byte):int16)
                   (0,16):int128)
                 (word_add
                   (word_subword
                     (word_join (word 0:byte) (word(bitval b5):byte):int16)
                     (0,16):int128)
                   (word_add
                     (word_subword
                       (word_join (word 0:byte) (word(bitval b6):byte):int16)
                       (0,16):int128)
                     (word_subword
                       (word_join (word 0:byte) (word(bitval b7):byte):int16)
                       (0,16):int128))))))))
       (0,32):int32):int64) =
     bitval b0 + bitval b1 + bitval b2 + bitval b3 +
     bitval b4 + bitval b5 + bitval b6 + bitval b7`,
  REPEAT GEN_TAC THEN
  BOOL_CASES_TAC `b0:bool` THEN BOOL_CASES_TAC `b1:bool` THEN
  BOOL_CASES_TAC `b2:bool` THEN BOOL_CASES_TAC `b3:bool` THEN
  BOOL_CASES_TAC `b4:bool` THEN BOOL_CASES_TAC `b5:bool` THEN
  BOOL_CASES_TAC `b6:bool` THEN BOOL_CASES_TAC `b7:bool` THEN
  ASM_REWRITE_TAC[bitval] THEN
  CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
  CONV_TAC NUM_REDUCE_CONV);;

let MLDSA_REJ_ACCEPTANCE_TABLE_UADDLV_4 = prove
 (`!bound b0 b1 b2 b3:byte.
     val
      (word_add
        (word_and (word 1:int128)
          (word_neg(word(bitval(val b0 MOD 16 < bound)))))
        (word_add
          (word_and (word 2:int128)
            (word_neg(word(bitval(val b0 DIV 16 < bound)))))
          (word_add
            (word_and (word 4:int128)
              (word_neg(word(bitval(val b1 MOD 16 < bound)))))
            (word_add
              (word_and (word 8:int128)
                (word_neg(word(bitval(val b1 DIV 16 < bound)))))
              (word_add
                (word_and (word 16:int128)
                  (word_neg(word(bitval(val b2 MOD 16 < bound)))))
                (word_add
                  (word_and (word 32:int128)
                    (word_neg(word(bitval(val b2 DIV 16 < bound)))))
                  (word_add
                    (word_and (word 64:int128)
                      (word_neg(word(bitval(val b3 MOD 16 < bound)))))
                    (word_and (word 128:int128)
                      (word_neg(word(bitval(val b3 DIV 16 < bound)))))))))))) =
     MLDSA_REJ_ACCEPTANCE_MASK
       (MLDSA_REJ_ACCEPTANCE_BITMAP bound [b0;b1;b2;b3])`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_MASK_WORD_SUM_8;
              MLDSA_REJ_ACCEPTANCE_BITMAP]);;

let MLDSA_REJ_ACCEPTANCE_COUNT_UADDLV_4 = prove
 (`!bound b0 b1 b2 b3:byte.
     val(word_zx(word_subword
       (word_add
         (word_subword
           (word_join (word 0:byte)
             (word(bitval(val b0 MOD 16 < bound)):byte):int16)
           (0,16):int128)
         (word_add
           (word_subword
             (word_join (word 0:byte)
               (word(bitval(val b0 DIV 16 < bound)):byte):int16)
             (0,16):int128)
           (word_add
             (word_subword
               (word_join (word 0:byte)
                 (word(bitval(val b1 MOD 16 < bound)):byte):int16)
               (0,16):int128)
             (word_add
               (word_subword
                 (word_join (word 0:byte)
                   (word(bitval(val b1 DIV 16 < bound)):byte):int16)
                 (0,16):int128)
               (word_add
                 (word_subword
                   (word_join (word 0:byte)
                     (word(bitval(val b2 MOD 16 < bound)):byte):int16)
                   (0,16):int128)
                 (word_add
                   (word_subword
                     (word_join (word 0:byte)
                       (word(bitval(val b2 DIV 16 < bound)):byte):int16)
                     (0,16):int128)
                   (word_add
                     (word_subword
                       (word_join (word 0:byte)
                         (word(bitval(val b3 MOD 16 < bound)):byte):int16)
                       (0,16):int128)
                     (word_subword
                       (word_join (word 0:byte)
                         (word(bitval(val b3 DIV 16 < bound)):byte):int16)
                       (0,16):int128))))))))
       (0,32):int32):int64) =
     MLDSA_REJ_ACCEPTANCE_COUNT bound [b0;b1;b2;b3]`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT_WORD_SUM_8;
              MLDSA_REJ_ACCEPTANCE_COUNT_4]);;

(* The only input-dependent coordinates in one eight-byte assembly iteration:
   two table indices, the initial stack offset, the second-store offset, and
   the next-iteration stack offset. *)
let MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES = new_definition
 `MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound (l:byte list) n =
    [MLDSA_REJ_ACCEPTANCE_MASK
       (SUB_LIST(16*n,8) (MLDSA_REJ_ACCEPTANCE_BITMAP bound l));
     MLDSA_REJ_ACCEPTANCE_MASK
       (SUB_LIST(16*n+8,8) (MLDSA_REJ_ACCEPTANCE_BITMAP bound l));
     MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l);
     MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n+4) l);
     MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*(n+1)) l)]`;;

let MLDSA_REJ_ACCEPTANCE_BITMAP_PREFIX = prove
 (`!bound (l:byte list) k.
     k <= LENGTH l
     ==> MLDSA_REJ_ACCEPTANCE_BITMAP bound (SUB_LIST(0,k) l) =
         SUB_LIST(0,2*k) (MLDSA_REJ_ACCEPTANCE_BITMAP bound l)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`l:byte list`; `k:num`] SUB_LIST_TOPSPLIT) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(fun th ->
    MP_TAC(AP_TERM `MLDSA_REJ_ACCEPTANCE_BITMAP bound` th)) THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP_APPEND] THEN
  DISCH_THEN(fun th ->
    GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [GSYM th]) THEN
  CONV_TAC SYM_CONV THEN
  TRANS_TAC EQ_TRANS
   `SUB_LIST (0,2*k)
      (MLDSA_REJ_ACCEPTANCE_BITMAP bound (SUB_LIST(0,k) l))` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN
    REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP_LENGTH; LENGTH_SUB_LIST] THEN
    ASM_ARITH_TAC;
    MATCH_MP_TAC SUB_LIST_REFL THEN
    REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP_LENGTH; LENGTH_SUB_LIST] THEN
    ASM_ARITH_TAC]);;

let MLDSA_REJ_ACCEPTANCE_BITMAP_PREFIX_EQ = prove
 (`!bound (l1:byte list) l2 k.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound l1 =
       MLDSA_REJ_ACCEPTANCE_BITMAP bound l2 /\
     k <= LENGTH l1 /\ k <= LENGTH l2
     ==> MLDSA_REJ_ACCEPTANCE_BITMAP bound (SUB_LIST(0,k) l1) =
         MLDSA_REJ_ACCEPTANCE_BITMAP bound (SUB_LIST(0,k) l2)`,
  REPEAT STRIP_TAC THEN
  ASM_SIMP_TAC[MLDSA_REJ_ACCEPTANCE_BITMAP_PREFIX]);;

let MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_EQ = prove
 (`!bound (l1:byte list) l2 k.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound l1 =
       MLDSA_REJ_ACCEPTANCE_BITMAP bound l2 /\
     k <= LENGTH l1 /\ k <= LENGTH l2
     ==> MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,k) l1) =
         MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,k) l2)`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT] THEN
  AP_TERM_TAC THEN AP_TERM_TAC THEN
  MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_BITMAP_PREFIX_EQ THEN
  ASM_REWRITE_TAC[]);;

(* One eight-byte iteration has two four-byte table lookups and stores.  These
   equalities expose the exact prefix-count values before, between, and after
   those two halves. *)
let MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_STEP_8 = prove
 (`!bound (l:byte list) i.
     MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*i+4) l) =
       MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*i) l) +
       MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(8*i,4) l) /\
     MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*(i+1)) l) =
       MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*i+4) l) +
       MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(8*i+4,4) l)`,
  REPEAT GEN_TAC THEN CONJ_TAC THENL
   [MP_TAC(ISPECL [`l:byte list`; `8*i`; `4`; `0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN SUBST1_TAC THEN
    REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT_APPEND];
    MP_TAC(ISPECL [`l:byte list`; `8*i+4`; `4`; `0`] SUB_LIST_SPLIT) THEN
    REWRITE_TAC[ADD_CLAUSES;
                ARITH_RULE `(8*i+4)+4 = 8*(i+1)`] THEN
    DISCH_THEN SUBST1_TAC THEN
    REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_COUNT_APPEND]]);;

(* Public loop-exit decision at iteration [n].  The buffer term is public;
   the only input-dependent term is the declassified acceptance prefix. *)
let MLDSA_REJ_ACCEPTANCE_LOOP_EXIT = new_definition
 `MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound (l:byte list) buflen n <=>
    buflen < 8 * (n + 1) \/
    256 <= MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l)`;;

let MLDSA_REJ_ACCEPTANCE_LOOP_EXIT_EQ = prove
 (`!bound (l1:byte list) l2 buflen n.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound l1 =
       MLDSA_REJ_ACCEPTANCE_BITMAP bound l2 /\
     8*n <= LENGTH l1 /\ 8*n <= LENGTH l2
     ==> (MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen n <=>
          MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen n)`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_LOOP_EXIT] THEN
  SUBGOAL_THEN
   `MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l1) =
    MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l2)`
  SUBST1_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_EQ THEN
    ASM_REWRITE_TAC[];
    REFL_TAC]);;

(* The minimal-exit predicate is therefore determined by the bitmap too.  The
   bound on [N] also covers every preceding continuation decision. *)
let MLDSA_REJ_ACCEPTANCE_STOPPING_INDEX_EQ = prove
 (`!bound (l1:byte list) l2 buflen N.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound l1 =
       MLDSA_REJ_ACCEPTANCE_BITMAP bound l2 /\
     8*N <= LENGTH l1 /\ 8*N <= LENGTH l2
     ==>
     ((MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen N /\
       (!n. n < N
            ==> ~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen n)) <=>
      (MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen N /\
       (!n. n < N
            ==> ~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen n)))`,
  REPEAT STRIP_TAC THEN EQ_TAC THENL
   [STRIP_TAC THEN CONJ_TAC THENL
     [MP_TAC(SPECL [`bound:num`; `l1:byte list`; `l2:byte list`;
                    `buflen:num`; `N:num`]
                   MLDSA_REJ_ACCEPTANCE_LOOP_EXIT_EQ) THEN
      ASM_REWRITE_TAC[];
      X_GEN_TAC `n:num` THEN DISCH_TAC THEN
      SUBGOAL_THEN
       `~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen n`
      ASSUME_TAC THENL
       [UNDISCH_TAC
         `!n. n < N
              ==> ~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen n` THEN
        DISCH_THEN(MP_TAC o SPEC `n:num`) THEN ASM_REWRITE_TAC[];
        MP_TAC(SPECL [`bound:num`; `l1:byte list`; `l2:byte list`;
                      `buflen:num`; `n:num`]
                     MLDSA_REJ_ACCEPTANCE_LOOP_EXIT_EQ) THEN
        ANTS_TAC THENL
         [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
          ASM_REWRITE_TAC[]]]];
    STRIP_TAC THEN CONJ_TAC THENL
     [MP_TAC(SPECL [`bound:num`; `l1:byte list`; `l2:byte list`;
                    `buflen:num`; `N:num`]
                   MLDSA_REJ_ACCEPTANCE_LOOP_EXIT_EQ) THEN
      ASM_REWRITE_TAC[];
      X_GEN_TAC `n:num` THEN DISCH_TAC THEN
      SUBGOAL_THEN
       `~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen n`
      ASSUME_TAC THENL
       [UNDISCH_TAC
         `!n. n < N
              ==> ~MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen n` THEN
        DISCH_THEN(MP_TAC o SPEC `n:num`) THEN ASM_REWRITE_TAC[];
        MP_TAC(SPECL [`bound:num`; `l1:byte list`; `l2:byte list`;
                      `buflen:num`; `n:num`]
                     MLDSA_REJ_ACCEPTANCE_LOOP_EXIT_EQ) THEN
        ANTS_TAC THENL
         [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
          ASM_REWRITE_TAC[]]]]]);;

let MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES_EQ = prove
 (`!bound (l1:byte list) l2 n.
     MLDSA_REJ_ACCEPTANCE_BITMAP bound l1 =
       MLDSA_REJ_ACCEPTANCE_BITMAP bound l2 /\
     8 * (n + 1) <= LENGTH l1 /\ 8 * (n + 1) <= LENGTH l2
     ==> MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound l1 n =
         MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound l2 n`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN
   `MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l1) =
    MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n) l2)`
  ASSUME_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_EQ THEN
    ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN
   `MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n+4) l1) =
    MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*n+4) l2)`
  ASSUME_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_EQ THEN
    ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  SUBGOAL_THEN
   `MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*(n+1)) l1) =
    MLDSA_REJ_ACCEPTANCE_COUNT bound (SUB_LIST(0,8*(n+1)) l2)`
  ASSUME_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_PREFIX_COUNT_EQ THEN
    ASM_REWRITE_TAC[];
    ALL_TAC] THEN
  ASM_REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES]);;

let MLDSA_REJ_UNIFORM_ETA2_EVENT_COORDINATES_EQ = prove
 (`!l1:byte list l2 n.
     MLDSA_REJ_UNIFORM_ETA2_ACCEPTANCE_BITMAP l1 =
       MLDSA_REJ_UNIFORM_ETA2_ACCEPTANCE_BITMAP l2 /\
     8 * (n + 1) <= LENGTH l1 /\ 8 * (n + 1) <= LENGTH l2
     ==> MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES 15 l1 n =
         MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES 15 l2 n`,
  REPEAT STRIP_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[MLDSA_REJ_UNIFORM_ETA2_ACCEPTANCE_BITMAP]) THEN
  MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES_EQ THEN
  ASM_REWRITE_TAC[]);;

let MLDSA_REJ_UNIFORM_ETA4_EVENT_COORDINATES_EQ = prove
 (`!l1:byte list l2 n.
     MLDSA_REJ_UNIFORM_ETA4_ACCEPTANCE_BITMAP l1 =
       MLDSA_REJ_UNIFORM_ETA4_ACCEPTANCE_BITMAP l2 /\
     8 * (n + 1) <= LENGTH l1 /\ 8 * (n + 1) <= LENGTH l2
     ==> MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES 9 l1 n =
         MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES 9 l2 n`,
  REPEAT STRIP_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[MLDSA_REJ_UNIFORM_ETA4_ACCEPTANCE_BITMAP]) THEN
  MATCH_MP_TAC MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES_EQ THEN
  ASM_REWRITE_TAC[]);;

(* Abstract event skeleton only. A false tag carries the five coordinates of
   one continued iteration; a true tag marks termination and has no payload. *)
let MLDSA_REJ_ACCEPTANCE_ITER_EVENTS = new_definition
 `MLDSA_REJ_ACCEPTANCE_ITER_EVENTS bound (l:byte list) n =
    [(F,MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound l n)]`;;

(* [fuel] bounds the number of continued iterations represented. A
   termination at the current index is retained even when no fuel remains. *)
let MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS = define
 `MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS bound (l:byte list) buflen n 0 =
    (if MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l buflen n
     then [(T,([]:num list))]
     else []) /\
  MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS bound l buflen n (SUC fuel) =
    (if MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l buflen n
     then [(T,([]:num list))]
     else APPEND (MLDSA_REJ_ACCEPTANCE_ITER_EVENTS bound l n)
                 (MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS
                   bound l buflen (n + 1) fuel))`;;

let MLDSA_REJ_ACCEPTANCE_LOOP_EVENT_SKELETON_EQ = prove
 (`!bound (l1:byte list) l2 buflen n fuel.
     (!i. MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound l1 i =
          MLDSA_REJ_ACCEPTANCE_EVENT_COORDINATES bound l2 i) /\
     (!i. MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l1 buflen i <=>
          MLDSA_REJ_ACCEPTANCE_LOOP_EXIT bound l2 buflen i)
     ==> MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS bound l1 buflen n fuel =
         MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS bound l2 buflen n fuel`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SPEC_TAC(`n:num`,`n:num`) THEN
  SPEC_TAC(`fuel:num`,`fuel:num`) THEN
  INDUCT_TAC THEN GEN_TAC THEN
  ASM_REWRITE_TAC[MLDSA_REJ_ACCEPTANCE_LOOP_EVENTS;
                  MLDSA_REJ_ACCEPTANCE_ITER_EVENTS]);;
