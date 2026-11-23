(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* Mask packing, shuffle rows and output-prefix lemmas for the AArch64 eta samplers. *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_rej_uniform_eta_table.ml";;

(* The low byte of a packet is the shuffle mask. Its high byte counts accepted lanes. *)
let MLDSA_ETA_PACKET_MASK = new_definition
 `MLDSA_ETA_PACKET_MASK p =
    bitval(p 0) + 2 * bitval(p 1) + 4 * bitval(p 2) + 8 * bitval(p 3) +
    16 * bitval(p 4) + 32 * bitval(p 5) + 64 * bitval(p 6) + 128 * bitval(p 7)`;;

let MLDSA_ETA_PACKET_COUNT = new_definition
 `MLDSA_ETA_PACKET_COUNT p =
    bitval(p 0) + bitval(p 1) + bitval(p 2) + bitval(p 3) +
    bitval(p 4) + bitval(p 5) + bitval(p 6) + bitval(p 7)`;;

(* Each selected halfword contributes two adjacent bytes to the table lookup. *)
let MLDSA_ETA_HALFWORD_GATHER = define
 `MLDSA_ETA_HALFWORD_GATHER (row:int128) (src:int128) (dst:int128) <=>
    !i. i < 8 ==> !j. j < 8 ==>
        word_subword row (16*i,8):byte = word(2*j) /\
        word_subword row (16*i+8,8):byte = word(2*j+1)
        ==> word_subword dst (16*i,16):int16 = word_subword src (16*j,16)`;;

let MLDSA_ETA_INDICES = define
 `MLDSA_ETA_INDICES (m:byte) = FILTER (\i. bit i m) [0;1;2;3;4;5;6;7]`;;

let MLDSA_ETA_MASK_INDICES = prove
 (`!p. MLDSA_ETA_PACKET_MASK p < 256 /\ MLDSA_ETA_PACKET_COUNT p <= 8 /\
       MLDSA_ETA_INDICES(word(MLDSA_ETA_PACKET_MASK p)) = FILTER p [0;1;2;3;4;5;6;7] /\
       LENGTH(MLDSA_ETA_INDICES(word(MLDSA_ETA_PACKET_MASK p))) = MLDSA_ETA_PACKET_COUNT p`,
  GEN_TAC THEN REWRITE_TAC[MLDSA_ETA_PACKET_MASK; MLDSA_ETA_PACKET_COUNT; MLDSA_ETA_INDICES; FILTER] THEN
  MAP_EVERY BOOL_CASES_TAC (map (fun i -> mk_comb(`p:num->bool`,mk_small_numeral i)) (0--7)) THEN
  REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN
  CONV_TAC WORD_REDUCE_CONV THEN REWRITE_TAC[LENGTH] THEN CONV_TAC NUM_REDUCE_CONV);;

let MLDSA_ETA_NIBBLE = define
 `MLDSA_ETA_NIBBLE (d:int64) i = word_zx(word_subword d (4*i,4):4 word):byte`;;

let MLDSA_ETA_LANES = define
 `MLDSA_ETA_LANES (d:int64) g = MAP (\i. MLDSA_ETA_NIBBLE d (8*g+i)) [0;1;2;3;4;5;6;7]`;;

let MLDSA_ETA_NIBBLE4 = define
 `MLDSA_ETA_NIBBLE4 (d:int64) g = MAP (\i. word_subword d (4*(8*g+i),4):4 word) [0;1;2;3;4;5;6;7]`;;

let MLDSA_ETA_NIBBLES_CHUNK = prove
 (`!d:int64. BYTES_TO_NIBBLES (MAP (\i. word_subword d (8*i,8):byte) [0;1;2;3;4;5;6;7]) =
            APPEND (MLDSA_ETA_NIBBLE4 d 0) (MLDSA_ETA_NIBBLE4 d 1)`,
  GEN_TAC THEN REWRITE_TAC[MLDSA_ETA_NIBBLE4;MAP;BYTES_TO_NIBBLES;APPEND;CONS_11] THEN
  CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[GSYM BYTE_AND_15_MOD;GSYM BYTE_USHR4_DIV;GSYM word_zx] THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let MLDSA_ETA_TABLE_ROW = define
 `MLDSA_ETA_TABLE_ROW m = SUB_LIST(16*m,16) mldsa_rej_uniform_eta_table`;;

let MLDSA_ETA_BYTES_OF_INDICES = prove
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

(* Each of the 256 rows lists the accepted lanes in input order. *)
let MLDSA_ETA_TABLE_PREFIX = prove
 (`!m. m < 256 ==>
    SUB_LIST(0,2 * LENGTH(MLDSA_ETA_INDICES(word m))) (MLDSA_ETA_TABLE_ROW m) =
    ITLIST (\i tl. CONS (word(2*i)) (CONS (word(2*i+1):byte) tl)) (MLDSA_ETA_INDICES(word m)) []`,
  CONV_TAC EXPAND_CASES_CONV THEN REWRITE_TAC[MLDSA_ETA_INDICES; MLDSA_ETA_TABLE_ROW; FILTER] THEN
  CONV_TAC(DEPTH_CONV WORD_RED_CONV) THEN
  REWRITE_TAC[LENGTH; ITLIST] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[mldsa_rej_uniform_eta_table] THEN
  CONV_TAC(DEPTH_CONV SUB_LIST_CONV) THEN CONV_TAC(DEPTH_CONV WORD_RED_CONV));;

let MLDSA_ETA_ROW_LANES = prove
 (`!m i. m < 256 /\ i < LENGTH(MLDSA_ETA_INDICES(word m)) ==>
    let row = word(num_of_wordlist(MLDSA_ETA_TABLE_ROW m)):int128 in
    let j = EL i (MLDSA_ETA_INDICES(word m)) in
    word_subword row (16*i,8):byte = word(2*j) /\
    word_subword row (16*i+8,8):byte = word(2*j+1)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN REWRITE_TAC[LET_DEF; LET_END_DEF] THEN
  ABBREV_TAC `idx = MLDSA_ETA_INDICES(word m)` THEN ABBREV_TAC `row = MLDSA_ETA_TABLE_ROW m` THEN
  SUBGOAL_THEN `LENGTH(row:byte list) = 16` ASSUME_TAC THENL
   [EXPAND_TAC "row" THEN REWRITE_TAC[MLDSA_ETA_TABLE_ROW; LENGTH_SUB_LIST] THEN
    SUBGOAL_THEN `LENGTH mldsa_rej_uniform_eta_table = 4096` SUBST1_TAC THENL
     [REWRITE_TAC[mldsa_rej_uniform_eta_table;LENGTH] THEN CONV_TAC NUM_REDUCE_CONV; ASM_ARITH_TAC]; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(idx:num list) <= 8` ASSUME_TAC THENL
   [EXPAND_TAC "idx" THEN REWRITE_TAC[MLDSA_ETA_INDICES] THEN
    MP_TAC(ISPECL [`\j. bit j (word m:byte)`; `[0;1;2;3;4;5;6;7]`] LENGTH_FILTER) THEN
    REWRITE_TAC[LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `!k. k < 16 ==> word_subword (word(num_of_wordlist row):int128) (8*k,8):byte = EL k row` ASSUME_TAC THENL
   [GEN_TAC THEN DISCH_TAC THEN
    MP_TAC(ISPECL [`row:byte list`; `k:num`] (INST_TYPE [`:128`,`:KL`;`:8`,`:L`] WORD_SUBWORD_NUM_OF_WORDLIST)) THEN
    ASM_REWRITE_TAC[DIMINDEX_128;DIMINDEX_8] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  REWRITE_TAC[ARITH_RULE `16*i = 8*(2*i)`;ARITH_RULE `16*i+8 = 8*(2*i+1)`] THEN
  SUBGOAL_THEN `2*i < 16 /\ 2*i+1 < 16` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPECL [`idx:num list`; `i:num`] MLDSA_ETA_BYTES_OF_INDICES) THEN
  ASM_REWRITE_TAC[LET_DEF;LET_END_DEF] THEN
  MP_TAC(SPEC `m:num` MLDSA_ETA_TABLE_PREFIX) THEN ASM_REWRITE_TAC[] THEN
  DISCH_THEN(SUBST1_TAC o SYM) THEN
  SUBGOAL_THEN `!k. k < 2 * LENGTH(idx:num list) ==> EL k (SUB_LIST(0,2*LENGTH idx) (row:byte list)) = EL k row` ASSUME_TAC THENL
   [REPEAT STRIP_TAC THEN MP_TAC(ISPECL [`row:byte list`;`0`;`2*LENGTH(idx:num list)`;`k:num`] EL_SUB_LIST) THEN
    ASM_REWRITE_TAC[ADD_CLAUSES] THEN ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[]]; ALL_TAC] THEN
  SUBGOAL_THEN `2*i < 2*LENGTH(idx:num list) /\ 2*i+1 < 2*LENGTH idx` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[]);;

(* Recover one aligned or unaligned slice of a byte list from memory. *)
let MLDSA_ETA_READ_BYTES_SLICE = prove
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

let mldsa_eta_split_store =
  let split = CONJUNCTS READ_MEMORY_BYTESIZED_UNSPLIT in
  fun th -> CONV_RULE(TOP_DEPTH_CONV (GEN_REWRITE_CONV I [el 1 split;el 2 split])) th;;

let MLDSA_ETA_STP_PREFIX = prove
 (`!dst (s:armstate) lo hi.
    read(memory :> bytes128 dst) s = lo /\
    read(memory :> bytes128(word_add dst (word 16))) s = hi ==>
    !i. i < 8 ==> read(memory :> bytes32(word_add dst (word(4*i)))) s =
                  word_subword (word_join hi lo:int256) (32*i,32)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  RULE_ASSUM_TAC mldsa_eta_split_store THEN
  RULE_ASSUM_TAC(REWRITE_RULE[GSYM WORD_ADD_ASSOC]) THEN
  RULE_ASSUM_TAC(CONV_RULE(DEPTH_CONV WORD_ADD_CONV)) THEN
  CONV_TAC EXPAND_CASES_CONV THEN CONV_TAC NUM_REDUCE_CONV THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN CONV_TAC(DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let MLDSA_ETA_PACKET_BOUNDS = prove
 (`!p. MLDSA_ETA_PACKET_MASK p < 256 /\ MLDSA_ETA_PACKET_COUNT p <= 8`,
  GEN_TAC THEN REWRITE_TAC[MLDSA_ETA_PACKET_MASK; MLDSA_ETA_PACKET_COUNT] THEN
  MAP_EVERY (fun i -> MP_TAC(SPEC (mk_comb(`p:num->bool`,mk_small_numeral i)) BITVAL_BOUND)) (0--7) THEN ARITH_TAC);;

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

(* Join the accepted words into the contiguous output prefix. *)
let MLDSA_ETA_OUTPUT_WORDLIST = prove
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

let MLDSA_ETA_OUTPUT_GROUPS = prove
 (`!xs ys:int32 list. !k dst s.
    (!j. j < MIN (LENGTH xs) k ==> read(memory:>bytes32(word_add dst (word(4*j)))) s = EL j xs) /\
    (!j. j < MIN (LENGTH ys) (k - LENGTH xs) ==>
       read(memory:>bytes32(word_add dst (word(4*(LENGTH xs+j))))) s = EL j ys) ==>
    read(memory:>bytes(dst,4*LENGTH(SUB_LIST(0,k)(APPEND xs ys))))s = num_of_wordlist(SUB_LIST(0,k)(APPEND xs ys))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN MATCH_MP_TAC MLDSA_ETA_OUTPUT_WORDLIST THEN
  X_GEN_TAC `j:num` THEN REWRITE_TAC[LENGTH_SUB_LIST;LENGTH_APPEND;SUB_0] THEN DISCH_TAC THEN
  SUBGOAL_THEN `j<k /\ j < LENGTH(xs:int32 list)+LENGTH(ys:int32 list)` STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC;ALL_TAC] THEN
  ASM_SIMP_TAC[EL_SUB_LIST;ADD_CLAUSES;LENGTH_APPEND;EL_APPEND] THEN COND_CASES_TAC THENL
   [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
    SUBGOAL_THEN `LENGTH(xs:int32 list)+(j-LENGTH xs)=j /\ j-LENGTH xs < MIN(LENGTH(ys:int32 list))(k-LENGTH xs)` STRIP_ASSUME_TAC THENL
     [ASM_ARITH_TAC;FIRST_X_ASSUM(MP_TAC o SPEC `j-LENGTH(xs:int32 list)`) THEN ASM_REWRITE_TAC[]]]);;

let MLDSA_ETA_PREFIX_APPEND = prove
 (`!xs ys:A list. !k. SUB_LIST(0,k) (APPEND xs ys) =
    APPEND (SUB_LIST(0,k) xs) (SUB_LIST(0,k-LENGTH xs) ys)`,
  LIST_INDUCT_TAC THEN REWRITE_TAC[LENGTH;SUB_LIST_CLAUSES;APPEND;SUB_0] THEN
  GEN_TAC THEN INDUCT_TAC THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES;APPEND;ARITH_RULE `0-n=0`;ARITH_RULE `SUC k-SUC n=k-n`]);;

let MLDSA_ETA_OUTPUT_APPEND = prove
 (`!dst s xs ys:int32 list.
    read(memory :> bytes(dst,4*LENGTH xs)) s = num_of_wordlist xs /\
    read(memory :> bytes(word_add dst (word(4*LENGTH xs)),4*LENGTH ys)) s = num_of_wordlist ys ==>
    read(memory :> bytes(dst,4*LENGTH(APPEND xs ys))) s = num_of_wordlist(APPEND xs ys)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[LENGTH_APPEND; LEFT_ADD_DISTRIB] THEN
  MP_TAC(ISPECL [`memory:(armstate,int64->byte)component`;`dst:int64`;`s:armstate`;
    `xs:int32 list`;`ys:int32 list`;`4*LENGTH(xs:int32 list)`;`4*LENGTH(ys:int32 list)`]
    BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
  REWRITE_TAC[DIMINDEX_32; ARITH_RULE `32*n=8*(4*n)`] THEN MESON_TAC[]);;
