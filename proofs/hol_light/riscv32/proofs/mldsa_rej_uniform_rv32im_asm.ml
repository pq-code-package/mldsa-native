(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Uniform rejection sampling for ML-DSA, filtering packed numbers < Q.      *)
(* ========================================================================= *)

(* This file proves that the RV32 routine writes the first (at most 256)
   elements of REJ_SAMPLE inlist to r and returns their number.
   `MLDSA_REJ_UNIFORM_SUBROUTINE_CORRECT` states this for a call of the
   routine, and `MLDSA_REJ_UNIFORM_SUBROUTINE_MEMSAFE` proves that the call
   reads only buf and writes only r. There is no constant-time theorem: the
   input is public, and the control flow depends on it.

   Two preconditions go beyond the C contract in arith_native_rv32im.h:
   - r and buf are 4-byte aligned, since the routine uses word accesses.
     r is an int32_t array, and the C wrapper falls back for unaligned buf.
   - Neither r[0, 256) nor buf wraps around the 32-bit address space, since
     the loop tests compare pointers. *)

needs "s2n_bignum/riscv/proofs/base.ml";;

(**** print_literal_from_elf
 "riscv32/mldsa/mldsa_rej_uniform_rv32im_asm.o";;
 ****)

let mldsa_rej_uniform_mc = define_assert_from_elf
  "mldsa_rej_uniform_mc"
  "riscv32/mldsa/mldsa_rej_uniform_rv32im_asm.o"
(*** BYTECODE START ***)
[
  0x007fe2b7;       (* riscv_LUI T0 (word 8380416) *)
  0x00128293;       (* riscv_ADDI T0 T0 (word 1) *)
  0x00800337;       (* riscv_LUI T1 (word 8388608) *)
  0xfff30313;       (* riscv_ADDI T1 T1 (word 4294967295) *)
  0x00050693;       (* riscv_ADDI A3 A0 (word 0) *)
  0x3f050713;       (* riscv_ADDI A4 A0 (word 1008) *)
  0x40050793;       (* riscv_ADDI A5 A0 (word 1024) *)
  0x00c58833;       (* riscv_ADD A6 A1 A2 *)
  0xff480393;       (* riscv_ADDI T2 A6 (word 4294967284) *)
  0x0005ae03;       (* riscv_LW T3 A1 (word 0) *)
  0x0045ae83;       (* riscv_LW T4 A1 (word 4) *)
  0x0085af03;       (* riscv_LW T5 A1 (word 8) *)
  0x00c58593;       (* riscv_ADDI A1 A1 (word 12) *)
  0x006e7fb3;       (* riscv_AND T6 T3 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x018e5f93;       (* riscv_SRLI T6 T3 24 *)
  0x008e9893;       (* riscv_SLLI A7 T4 8 *)
  0x011f8fb3;       (* riscv_ADD T6 T6 A7 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x010edf93;       (* riscv_SRLI T6 T4 16 *)
  0x010f1893;       (* riscv_SLLI A7 T5 16 *)
  0x011f8fb3;       (* riscv_ADD T6 T6 A7 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x008f5f93;       (* riscv_SRLI T6 T5 8 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x0905fe63;       (* riscv_BGEU A1 A6 (word 156) *)
  0xf8d770e3;       (* riscv_BGEU A4 A3 (word 4294967168) *)
  0x08f6fa63;       (* riscv_BGEU A3 A5 (word 148) *)
  0x0005ae03;       (* riscv_LW T3 A1 (word 0) *)
  0x0045ae83;       (* riscv_LW T4 A1 (word 4) *)
  0x0085af03;       (* riscv_LW T5 A1 (word 8) *)
  0x00c58593;       (* riscv_ADDI A1 A1 (word 12) *)
  0x006e7fb3;       (* riscv_AND T6 T3 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x06f6f663;       (* riscv_BGEU A3 A5 (word 108) *)
  0x018e5f93;       (* riscv_SRLI T6 T3 24 *)
  0x008e9893;       (* riscv_SLLI A7 T4 8 *)
  0x011f8fb3;       (* riscv_ADD T6 T6 A7 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x04f6f463;       (* riscv_BGEU A3 A5 (word 72) *)
  0x010edf93;       (* riscv_SRLI T6 T4 16 *)
  0x010f1893;       (* riscv_SLLI A7 T5 16 *)
  0x011f8fb3;       (* riscv_ADD T6 T6 A7 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x02f6f263;       (* riscv_BGEU A3 A5 (word 36) *)
  0x008f5f93;       (* riscv_SRLI T6 T5 8 *)
  0x006fffb3;       (* riscv_AND T6 T6 T1 *)
  0x005fb8b3;       (* riscv_SLTU A7 T6 T0 *)
  0x01f6a023;       (* riscv_SW T6 A3 (word 0) *)
  0x00289893;       (* riscv_SLLI A7 A7 2 *)
  0x011686b3;       (* riscv_ADD A3 A3 A7 *)
  0x00f6f463;       (* riscv_BGEU A3 A5 (word 8) *)
  0xf6b3fae3;       (* riscv_BGEU T2 A1 (word 4294967156) *)
  0x40a68533;       (* riscv_SUB A0 A3 A0 *)
  0x00255513;       (* riscv_SRLI A0 A0 2 *)
  0x00008067       (* riscv_JALR ZERO RA (word 0) *)
];;
(*** BYTECODE END ***)

let MLDSA_REJ_UNIFORM_EXEC = RISCV_MK_EXEC_RULE mldsa_rej_uniform_mc;;

let LENGTH_MLDSA_REJ_UNIFORM_MC =
  REWRITE_CONV[mldsa_rej_uniform_mc] `LENGTH mldsa_rej_uniform_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

needs "mldsa_native/riscv32/proofs/mldsa_specs_aux.ml";;
needs "s2n_bignum/riscv/proofs/consttime.ml";;

(* Discharge `?e2. read events s = APPEND e2 e /\ memaccess_inbounds ...`
   after symbolic simulation. MEMSAFE_ARITH_TAC filters the assumptions to
   the numeric ones before calling the arithmetic decision procedure. *)
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

let CONTAINED_ASM_TAC =
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  GEN_REWRITE_TAC (BINOP_CONV o LAND_CONV o LAND_CONV o TOP_DEPTH_CONV)
   [VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
  CONV_TAC(BINOP_CONV(LAND_CONV MOD_DOWN_CONV)) THEN
  GEN_REWRITE_TAC I [CONTAINED_MODULO_MOD2] THEN
  ((GEN_REWRITE_TAC I [CONTAINED_MODULO_REFL] THEN
    MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
    MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_SIMPLE THEN MEMSAFE_ARITH_TAC));;

let DISCHARGE_MEMSAFE_ASM_TAC:tactic =
  SAFE_META_EXISTS_TAC allowed_vars_e THEN
  CONJ_TAC THENL [ EXISTS_E2_TAC allowed_vars_e; ALL_TAC ] THEN
  REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN
  CONJ_TAC THENL
   [REWRITE_TAC[memaccess_inbounds_def; DIMINDEX_32; ALL; EX; FST; SND] THEN
    REPEAT CONJ_TAC THEN
    TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                CONTAINED_ASM_TAC) THEN NO_TAC);
    REWRITE_TAC[APPEND; APPEND_NIL] THEN
    FIRST_ASSUM ACCEPT_TAC];;

(* Proof outline:

   The kernel reads the input in groups of 12 bytes, i.e. four 24-bit
   candidates. `rej_uniform_prefix ... n` states that the first n candidates
   have been consumed and that their accepted prefix sits at the start of the
   output. The main loop (0x24..0xa4) consumes whole groups while at least
   four output slots remain; it stores every candidate and advances the
   output pointer only for accepted ones. The tail loop (0xac..0x138) does
   the same but leaves as soon as the output is full. Both end at 0x13c,
   which returns the number of coefficients written. *)

let rej_uniform_prefix = new_definition
 `rej_uniform_prefix res buf buflen (inlist:(24 word)list) e n s <=>
    let outlist = REJ_SAMPLE (SUB_LIST (0,n) inlist) in
    let outlen = LENGTH outlist in
    read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
    read A0 s = res /\
    read T0 s = word 8380417 /\ read T1 s = word 8388607 /\
    read A1 s = word_add buf (word (3 * n)) /\
    read A3 s = word_add res (word (4 * outlen)) /\
    read A4 s = word_add res (word 1008) /\
    read A5 s = word_add res (word 1024) /\
    read A6 s = word_add buf (word buflen) /\
    read T2 s = word_sub (word_add buf (word buflen)) (word 12) /\
    read (memory :> bytes (res,4 * outlen)) s = num_of_wordlist outlist /\
    (?e2. read events s = APPEND e2 e /\
          memaccess_inbounds e2 [buf,buflen; res,1024] [res,1024])`;;

let REJ_UNIFORM_LENGTH_STEP = prove
 (`!inlist:(24 word)list. !n k.
     LENGTH(REJ_SAMPLE(SUB_LIST(0,n+k) inlist)) <=
     LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) + k`,
  REPEAT GEN_TAC THEN REWRITE_TAC[SUB_LIST_SPLIT; REJ_SAMPLE_APPEND;
    ADD_CLAUSES; LENGTH_APPEND; LE_ADD_LCANCEL] THEN
  REWRITE_TAC[REJ_SAMPLE] THEN MATCH_MP_TAC LE_TRANS THEN
  EXISTS_TAC `LENGTH(MAP (\w:24 word. word (val w MOD 2 EXP 23):int32)
    (SUB_LIST(n,k) inlist))` THEN REWRITE_TAC[LENGTH_FILTER; LENGTH_MAP;
    LENGTH_SUB_LIST] THEN ARITH_TAC);;

let MLDSA_REJ_UNIFORM_INIT = prove
 (`!res buf buflen (inlist:(24 word)list) pc e.
     ensures riscv
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ C_ARGUMENTS [res;buf;word buflen] s /\
            read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
            read events s = e)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + 0x24) /\
            rej_uniform_prefix res buf buflen inlist e 0 s)
       (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                   T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_prefix;
    C_ARGUMENTS] THEN
  ENSURES_INIT_TAC "s0" THEN
  RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--9) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; REJ_SAMPLE_EMPTY] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REWRITE_TAC[LENGTH] THEN
  REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; READ_COMPONENT_COMPOSE;
    READ_BYTES_TRIVIAL; num_of_wordlist] THEN
  CONJ_TAC THENL [CONV_TAC WORD_BLAST; ALL_TAC] THEN
  EXISTS_TAC `[]:((32)address_uarch_event)list` THEN
  REWRITE_TAC[APPEND; memaccess_inbounds_def; ALL]);;

(* Building blocks for one 12-byte group. *)

let ALIGNED4_ADD = prove
 (`!(x:int32) k. aligned 4 x ==> aligned 4 (word_add x (word (4 * k)))`,
  SIMP_TAC[ALIGNED_WORD_ADD_EQ; ALIGNED_WORD; DIMINDEX_32] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_DIVIDES_CONV) THEN
  SIMP_TAC[MOD_MULT; ARITH_EQ]);;

let REJ_UNIFORM_MEM_STEP = prove
 (`!(res:int32) (L:int32 list) (c:int32) (s:riscvstate).
     read (memory :> bytes (res,4 * LENGTH L)) s = num_of_wordlist L /\
     read (memory :> bytes32 (word_add res (word (4 * LENGTH L)))) s = c
     ==> read (memory :> bytes (res,4 * LENGTH (APPEND L
                (if val c < 8380417 then [c] else [])))) s =
         num_of_wordlist (APPEND L (if val c < 8380417 then [c] else []))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN COND_CASES_TAC THEN
  ASM_REWRITE_TAC[APPEND_NIL] THEN
  REWRITE_TAC[LENGTH_APPEND; LENGTH; NUM_OF_WORDLIST_APPEND;
              NUM_OF_WORDLIST_SING; DIMINDEX_32] THEN
  REWRITE_TAC[ARITH_RULE `4 * (n + SUC 0) = 4 * n + 4`] THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_COMBINE] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[READ_COMPONENT_COMPOSE]) THEN
  ASM_REWRITE_TAC[ARITH_RULE `8 * 4 * n = 32 * n`; EQ_ADD_LCANCEL] THEN
  AP_TERM_TAC THEN EXPAND_TAC "c" THEN
  REWRITE_TAC[BYTES32_WBYTES; VAL_READ_WBYTES; DIMINDEX_32] THEN
  CONV_TAC NUM_REDUCE_CONV);;

let DIMINDEX_24 = DIMINDEX_CONV `dimindex(:24)`;;
let DIMINDEX_96 = DIMINDEX_CONV `dimindex(:96)`;;

let READ_MEMORY_WORD_TRIPLE_SPLIT = prove
 (`!m (x:A word) s:S.
        read (m :> wbytes x) s :96 word =
        word_join (read (m :> bytes32 (word_add x (word 8))) s)
                  (word_join (read (m :> bytes32 (word_add x (word 4))) s)
                             (read (m :> bytes32 x) s):int64)`,
  REWRITE_TAC[GSYM VAL_EQ] THEN
  SIMP_TAC[VAL_WORD_JOIN_SIMPLE; DIMINDEX_32; DIMINDEX_64; DIMINDEX_96;
           ARITH] THEN
  REWRITE_TAC[BYTES32_WBYTES] THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; VAL_READ_WBYTES] THEN
  CONV_TAC(ONCE_DEPTH_CONV DIMINDEX_CONV) THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[ARITH_RULE `12 = 4 + 4 + 4`] THEN
  REWRITE_TAC[READ_BYTES_COMBINE; WORD_ADD_ASSOC_CONSTS] THEN
  CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

let VAL_MOD_23_EQ_AND = prove
 (`!w:24 word. (word(val w MOD 2 EXP 23):int32) =
               word_and (word_zx w:int32) (word 8388607)`,
  GEN_TAC THEN CONV_TAC WORD_BLAST);;

let REJ_UNIFORM_ADD_OR = prove
 (`!w0 w1 w2:int32.
     word_add (word_ushr w0 24) (word_shl w1 8) =
     word_or (word_ushr w0 24) (word_shl w1 8) /\
     word_add (word_ushr w1 16) (word_shl w2 16) =
     word_or (word_ushr w1 16) (word_shl w2 16)`,
  REPEAT GEN_TAC THEN CONJ_TAC THEN MATCH_MP_TAC WORD_ADD_OR THEN
  CONV_TAC WORD_BLAST);;

let REJ_UNIFORM_CANDIDATES = prove
 (`!w0 w1 w2:int32.
     let v:96 word = word_join w2 (word_join w1 w0:int64) in
     word_and w0 (word 8388607) =
       word_and (word_zx (word_subword v (0,24):24 word)) (word 8388607) /\
     word_and (word_add (word_ushr w0 24) (word_shl w1 8)) (word 8388607) =
       word_and (word_zx (word_subword v (24,24):24 word)) (word 8388607) /\
     word_and (word_add (word_ushr w1 16) (word_shl w2 16)) (word 8388607) =
       word_and (word_zx (word_subword v (48,24):24 word)) (word 8388607) /\
     word_and (word_ushr w2 8) (word 8388607) =
       word_and (word_zx (word_subword v (72,24):24 word)) (word 8388607)`,
  REPEAT GEN_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[REJ_UNIFORM_ADD_OR] THEN
  REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

let REJ_UNIFORM_GROUP_EL = prove
 (`!buf buflen (inlist:(24 word)list) (s:riscvstate) g.
     buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\
     12 * g + 12 <= buflen /\
     read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist
     ==> !j. j < 4
             ==> EL j (MAP (\x:24 word. word(val x MOD 2 EXP 23):int32)
                         (SUB_LIST(4 * g,4) inlist)) =
                 word_and (word_zx (word_subword
                   (read (memory :> wbytes (word_add buf (word (12 * g)))) s
                     :96 word) (24 * j,24):24 word):int32) (word 8388607)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o AP_TERM
    `\x. x DIV 2 EXP (8 * 12 * g) MOD 2 EXP (8 * 12)`) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_DIV] THEN
  REWRITE_TAC[READ_BYTES_MOD] THEN
  REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
  REWRITE_TAC[ARITH_RULE `8 * 12 = 24 * 4 * 1`] THEN
  REWRITE_TAC[ARITH_RULE `8 * 12 * x = 24 * 4 * x`] THEN
  REWRITE_TAC[GSYM DIMINDEX_24; GSYM NUM_OF_WORDLIST_SUB_LIST] THEN
  SUBGOAL_THEN `MIN (buflen - 12 * g) 12 = dimindex(:96) DIV 8`
  SUBST1_TAC THENL
   [REWRITE_TAC[DIMINDEX_96] THEN CONV_TAC NUM_REDUCE_CONV THEN
    UNDISCH_TAC `12 * g + 12 <= buflen` THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[MULT_CLAUSES] THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; GSYM VAL_READ_WBYTES] THEN
  REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
  DISCH_TAC THEN X_GEN_TAC `j:num` THEN DISCH_TAC THEN
  SUBGOAL_THEN `j < LENGTH(SUB_LIST(4 * g,4) (inlist:(24 word)list))`
  ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST] THEN
    MAP_EVERY UNDISCH_TAC [`j:num < 4`; `12 * g + 12 <= buflen`;
      `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN ARITH_TAC;
    ALL_TAC] THEN
  ASM_SIMP_TAC[EL_MAP] THEN REWRITE_TAC[VAL_MOD_23_EQ_AND] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; DIMINDEX_24;
              ARITH_RULE `MIN 24 24 = 24`] THEN
  ASM_REWRITE_TAC[GSYM DIMINDEX_24; NUM_OF_WORDLIST_EL; LENGTH_SUB_LIST] THEN
  COND_CASES_TAC THENL [REFL_TAC; ASM_MESON_TAC[]]);;

let REJ_UNIFORM_OUT_STEP = prove
 (`!(res:int32) (L:int32 list) (c:int32).
     word_add (word_add res (word (4 * LENGTH L)))
              (word_shl (if val c < 8380417 then word 1 else word 0) 2) =
     word_add res (word (4 * LENGTH (APPEND L
       (if val c < 8380417 then [c] else []))))`,
  REPEAT GEN_TAC THEN COND_CASES_TAC THEN
  REWRITE_TAC[APPEND_NIL; LENGTH_APPEND; LENGTH] THEN
  CONV_TAC WORD_REDUCE_CONV THEN CONV_TAC WORD_RULE);;

let LIST_OF_LENGTH_4 = prove
 (`!l:A list. LENGTH l = 4 ==> l = [EL 0 l; EL 1 l; EL 2 l; EL 3 l]`,
  GEN_TAC THEN DISCH_TAC THEN ONCE_REWRITE_TAC[LIST_EQ] THEN
  ASM_REWRITE_TAC[LENGTH] THEN CONV_TAC NUM_REDUCE_CONV THEN
  X_GEN_TAC `j:num` THEN DISCH_TAC THEN
  SUBGOAL_THEN `j = 0 \/ j = 1 \/ j = 2 \/ j = 3` MP_TAC THENL
   [UNDISCH_TAC `j < 4` THEN ARITH_TAC;
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REFL_TAC]);;

let rej_uniform_step = new_definition
 `rej_uniform_step L (c:int32) =
    APPEND L (if val c < 8380417 then [c] else [])`;;

let REJ_UNIFORM_GROUP_PREFIX = prove
 (`!(inlist:(24 word)list) g.
     4 * g + 4 <= LENGTH inlist
     ==> REJ_SAMPLE (SUB_LIST(0,4 * g + 4) inlist) =
         rej_uniform_step (rej_uniform_step (rej_uniform_step
           (rej_uniform_step (REJ_SAMPLE (SUB_LIST(0,4 * g) inlist))
             (EL 0 (MAP (\x:24 word. word(val x MOD 2 EXP 23):int32)
               (SUB_LIST(4 * g,4) inlist)))) (EL 1 (MAP (\x:24 word. word(val x
                 MOD 2 EXP 23):int32) (SUB_LIST(4 * g,4) inlist)))) (EL 2 (MAP
                   (\x:24 word. word(val x MOD 2 EXP 23):int32) (SUB_LIST(4 *
                     g,4) inlist)))) (EL 3 (MAP (\x:24 word. word(val x MOD 2
                       EXP 23):int32) (SUB_LIST(4 * g,4) inlist)))`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN REWRITE_TAC[rej_uniform_step] THEN
  REWRITE_TAC[SUB_LIST_SPLIT; ADD_CLAUSES; REJ_SAMPLE_APPEND] THEN
  REWRITE_TAC[GSYM APPEND_ASSOC] THEN AP_TERM_TAC THEN
  MP_TAC(ISPEC `MAP (\x:24 word. word(val x MOD 2 EXP 23):int32)
                   (SUB_LIST(4 * g,4) inlist)` LIST_OF_LENGTH_4) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[LENGTH_MAP; LENGTH_SUB_LIST] THEN
    UNDISCH_TAC `4 * g + 4 <= LENGTH(inlist:(24 word)list)` THEN ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[REJ_SAMPLE] THEN
  DISCH_THEN(fun th -> GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV) [th]) THEN
  REWRITE_TAC[FILTER] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[APPEND; APPEND_NIL]));;

let REJ_UNIFORM_STEP_LENGTH = prove
 (`!L (c:int32). LENGTH (rej_uniform_step L c) <= LENGTH L + 1`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_step] THEN COND_CASES_TAC THEN
  REWRITE_TAC[LENGTH_APPEND; LENGTH] THEN ARITH_TAC);;

(* Rewrite only the assumptions about state sv. *)

let is_divides t =
  try fst(strip_comb t) = `(divides):num->num->bool` with Failure _ -> false;;

let STATE_REWRITE_TAC sv ths =
  RULE_ASSUM_TAC(fun a ->
    if vfree_in sv (concl a) then REWRITE_RULE ths a else a);;

(* Set up a pass over the group of candidates 4 * g .. 4 * g + 3:
   cur is the address of the group, w0, w1, w2 its three words, c0 .. c3
   the candidates, and L0 .. L4 the accepted prefixes before and after each
   candidate. The four word expressions computed by the kernel are proved
   equal to c0 .. c3. *)

let REJ_UNIFORM_GROUP_SETUP_TAC =
  let cand j =
    parse_term("c" ^ j ^ " = EL " ^ j ^
      " (MAP (\\x:24 word. word(val x MOD 2 EXP 23):int32)" ^
      " (SUB_LIST(4 * g,4) (inlist:(24 word)list)))") in
  let el th j =
    GSYM(REWRITE_RULE[ARITH_RULE
           `24 * 0 = 0 /\ 24 * 1 = 24 /\ 24 * 2 = 48 /\ 24 * 3 = 72`]
      (MP (SPEC j th)
          (EQT_ELIM(NUM_REDUCE_CONV(mk_binop `(<):num->num->bool` j `4`))))) in
  REPEAT GEN_TAC THEN
  REWRITE_TAC[NONOVERLAPPING_CLAUSES; LENGTH_MLDSA_REJ_UNIFORM_MC;
              rej_uniform_prefix] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  ABBREV_TAC `cur:int32 = word_add buf (word (12 * g))` THEN
  SUBGOAL_THEN `aligned 4 (cur:int32)` ASSUME_TAC THENL
   [EXPAND_TAC "cur" THEN REWRITE_TAC[ARITH_RULE `12 * g = 4 * 3 * g`] THEN
    MATCH_MP_TAC ALIGNED4_ADD THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN
  SUBGOAL_THEN `4 * g + 4 <= LENGTH(inlist:(24 word)list)` ASSUME_TAC THENL
   [MAP_EVERY UNDISCH_TAC [`12 * g + 12 <= buflen`;
      `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN ARITH_TAC;
    ALL_TAC] THEN
  FIRST_ASSUM(MP_TAC o MATCH_MP REJ_UNIFORM_GROUP_PREFIX) THEN
  MAP_EVERY (ABBREV_TAC o cand) ["0"; "1"; "2"; "3"] THEN
  ABBREV_TAC `L0 = REJ_SAMPLE (SUB_LIST(0,4 * g) inlist)` THEN
  ABBREV_TAC `L1 = rej_uniform_step L0 c0` THEN
  ABBREV_TAC `L2 = rej_uniform_step L1 c1` THEN
  ABBREV_TAC `L3 = rej_uniform_step L2 c2` THEN
  ABBREV_TAC `L4 = rej_uniform_step L3 c3` THEN DISCH_TAC THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(TOP_DEPTH_CONV let_CONV))) THEN
  ASM_REWRITE_TAC[ARITH_RULE `3 * 4 * n = 12 * n`;
                  ARITH_RULE `3 * (4 * n + 4) = 12 * n + 12`;
                  ARITH_RULE `4 * (g + 1) = 4 * g + 4`] THEN
  ENSURES_INIT_TAC "s0" THEN
  FIRST_X_ASSUM(CHOOSE_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
  MAP_EVERY ABBREV_TAC
   [`w0 = read (memory :> bytes32 cur) s0`;
    `w1 = read (memory :> bytes32 (word_add cur (word 4))) s0`;
    `w2 = read (memory :> bytes32 (word_add cur (word 8))) s0`] THEN
  SUBGOAL_THEN
   `word_and (w0:int32) (word 8388607) = c0 /\
    word_and (word_add (word_ushr w0 24) (word_shl (w1:int32) 8))
             (word 8388607) = c1 /\
    word_and (word_add (word_ushr w1 16) (word_shl (w2:int32) 16))
             (word 8388607) = c2 /\
    word_and (word_ushr w2 8) (word 8388607) = c3`
  STRIP_ASSUME_TAC THENL
   [MP_TAC(SPECL [`w0:int32`; `w1:int32`; `w2:int32`]
                 REJ_UNIFORM_CANDIDATES) THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
    SUBGOAL_THEN
     `read (memory :> wbytes cur) s0:96 word =
      word_join (w2:int32) (word_join (w1:int32) (w0:int32):int64)`
     (fun th -> REWRITE_TAC[GSYM th]) THENL
     [ASM_REWRITE_TAC[READ_MEMORY_WORD_TRIPLE_SPLIT]; ALL_TAC] THEN
    MP_TAC(SPECL [`buf:int32`; `buflen:num`; `inlist:(24 word)list`;
                  `s0:riscvstate`; `g:num`] REJ_UNIFORM_GROUP_EL) THEN
    ASM_REWRITE_TAC[] THEN
    DISCH_THEN(fun th ->
      REWRITE_TAC(map (el th) [`0`; `1`; `2`; `3`])) THEN
    ASM_REWRITE_TAC[];
    ALL_TAC];;

(* Execute one candidate of the group, from the computation of the
   candidate c to the update of the output pointer, and rewrite the result
   in terms of the next prefix lnext = rej_uniform_step lprev c. The
   assumption LENGTH lprev <= bound becomes LENGTH lnext <= bound + 1. *)

let REJ_UNIFORM_CAND_TAC lprev lnext c bound steps s =
  let sv = mk_var(s,`:riscvstate`) in
  let len l = mk_comb(`LENGTH:int32 list->num`,l) in
  let stepdef = mk_eq(list_mk_comb(`rej_uniform_step`,[lprev;c]),lnext) in
  let lenb = mk_binop `(<=):num->num->bool` (len lprev) bound in
  let is_cand th =
    let t = concl th in
    is_eq t && rand t = c && is_comb(lhand t) &&
    fst(strip_comb(lhand t)) = `word_and:int32->int32->int32` in
  SUBGOAL_THEN
   (subst [len lprev,`n:num`] `aligned 4 (word_add res (word (4 * n)):int32)`)
   ASSUME_TAC THENL [MATCH_MP_TAC ALIGNED4_ADD THEN ASM_REWRITE_TAC[]; ALL_TAC]
     THEN
  RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC steps THEN
  FIRST_ASSUM(fun th -> if is_cand th then STATE_REWRITE_TAC sv [th]
                        else NO_TAC) THEN
  STATE_REWRITE_TAC sv [REJ_UNIFORM_OUT_STEP; GSYM rej_uniform_step] THEN
  STATE_REWRITE_TAC sv [ASSUME stepdef] THEN
  MP_TAC(SPECL [`res:int32`; lprev; c; sv] REJ_UNIFORM_MEM_STEP) THEN
  ASM_REWRITE_TAC[GSYM rej_uniform_step] THEN DISCH_TAC THEN
  MP_TAC(SPECL [lprev; c] REJ_UNIFORM_STEP_LENGTH) THEN
  ASM_REWRITE_TAC[] THEN MP_TAC(ASSUME lenb) THEN
  REWRITE_TAC[IMP_IMP] THEN
  DISCH_THEN(ASSUME_TAC o MATCH_MP
    (ARITH_RULE `a <= b /\ c <= a + 1 ==> c <= b + 1`)) THEN
  RULE_ASSUM_TAC(CONV_RULE NUM_REDUCE_CONV);;

(* One pass of the main loop consumes a whole group of four candidates. *)

let MLDSA_REJ_UNIFORM_MAIN_GROUP = prove
 (`!res buf buflen (inlist:(24 word)list) pc e g.
     aligned 4 res /\ aligned 4 buf /\
     buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\
     12 * g + 12 <= buflen /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * g) inlist)) <= 252 /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,buflen)
     ==> ensures riscv
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x24) /\
                rej_uniform_prefix res buf buflen inlist e (4 * g) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0xa0) /\
                rej_uniform_prefix res buf buflen inlist e (4 * g + 4) s)
           (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                       T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REJ_UNIFORM_GROUP_SETUP_TAC THEN
  REJ_UNIFORM_CAND_TAC `L0:int32 list` `L1:int32 list` `c0:int32`
    `252` (1--9) "s9" THEN
  REJ_UNIFORM_CAND_TAC `L1:int32 list` `L2:int32 list` `c1:int32`
    `253` (10--17) "s17" THEN
  REJ_UNIFORM_CAND_TAC `L2:int32 list` `L3:int32 list` `c2:int32`
    `254` (18--25) "s25" THEN
  REJ_UNIFORM_CAND_TAC `L3:int32 list` `L4:int32 list` `c3:int32`
    `255` (26--31) "s31" THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
  EXPAND_TAC "cur" THEN
  CONJ_TAC THENL [CONV_TAC WORD_RULE; DISCHARGE_MEMSAFE_ASM_TAC]);;

(* The loop tests at 0xa0 and 0xa4 compare pointers. *)

let MLDSA_REJ_UNIFORM_TEST = prove
 (`!res buf buflen (inlist:(24 word)list) e g pc.
     val res + 1024 < 2 EXP 32 /\ val buf + buflen < 2 EXP 32 /\
     12 * g <= buflen /\
     LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * g) inlist)) <= 256 /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures riscv
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + 0xa0) /\
            rej_uniform_prefix res buf buflen inlist e (4 * g) s)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc +
              (if buflen <= 12 * g then 0x13c
               else if LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * g) inlist)) <= 252
               then 0x24 else 0xa8)) /\
            rej_uniform_prefix res buf buflen inlist e (4 * g) s)
       (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                   T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  (REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_prefix;
    LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
  ABBREV_TAC `len = LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * g) inlist))` THEN
  REWRITE_TAC[ARITH_RULE `3 * 4 * g = 12 * g`] THEN
  SUBGOAL_THEN `val(word_add buf (word (12 * g)):int32) = val buf + 12 * g /\
                val(word_add buf (word buflen):int32) = val buf + buflen /\
                val(word_add res (word (4 * len)):int32) = val res + 4 * len /\
                val(word_add res (word 1008):int32) = val res + 1008 /\
                val(word_add res (word 1024):int32) = val res + 1024`
  STRIP_ASSUME_TAC THENL
   [REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
    CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
    REPEAT CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN
    MAP_EVERY UNDISCH_TAC [`val (res:int32) + 1024 < 2 EXP 32`;
      `val (buf:int32) + buflen < 2 EXP 32`; `12 * g <= buflen`; `len <= 256`]
        THEN
    ARITH_TAC;
    ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  FIRST_X_ASSUM(CHOOSE_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC))) THEN
  (ASM_CASES_TAC `buflen <= 12 * g` THENL
   [RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [1] THEN
    STATE_REWRITE_TAC `s1:riscvstate` [GE; LE_ADD_LCANCEL;
      ASSUME `buflen <= 12 * g`] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[]
      THEN DISCHARGE_MEMSAFE_ASM_TAC;
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [1] THEN
    STATE_REWRITE_TAC `s1:riscvstate` [GE; LE_ADD_LCANCEL;
      ASSUME `~(buflen <= 12 * g)`] THEN
    ASM_CASES_TAC `len <= 252` THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [2] THEN
    STATE_REWRITE_TAC `s2:riscvstate` [GE; LE_ADD_LCANCEL;
      ARITH_RULE `4 * len <= 1008 <=> len <= 252`] THEN
    ASM_REWRITE_TAC[] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[]
      THEN DISCHARGE_MEMSAFE_ASM_TAC]));;

let REJ_UNIFORM_GROUP_COUNT = prove
 (`!buflen (inlist:(24 word)list).
     12 divides buflen /\ 0 < buflen
     ==> ?N. 0 < N /\ 12 * N <= buflen /\
             LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * N) inlist)) <= 256 /\
             (buflen <= 12 * N \/
              ~(LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * N) inlist)) <= 252)) /\
             (!i. i < N ==> 12 * i + 12 <= buflen /\
                  LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * i) inlist)) <= 252)`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  FIRST_X_ASSUM(X_CHOOSE_THEN `d:num` SUBST_ALL_TAC o REWRITE_RULE[divides])
    THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ARITH_RULE `0 < 12 * d <=> 0 < d`]) THEN
  REWRITE_TAC[ARITH_RULE `12 * i + 12 <= 12 * d <=> i + 1 <= d`;
              ARITH_RULE `12 * n <= 12 * d <=> n <= d`;
              ARITH_RULE `12 * d <= 12 * n <=> d <= n`] THEN
  ABBREV_TAC `len = \n. LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * n) (inlist:(24
    word)list)))` THEN
  SUBGOAL_THEN `!n. LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * n) (inlist:(24
    word)list))) = len n`
    (fun th -> REWRITE_TAC[th]) THENL [EXPAND_TAC "len" THEN REWRITE_TAC[];
      ALL_TAC] THEN
  SUBGOAL_THEN `!n. len(n + 1) <= len n + 4` ASSUME_TAC THENL
   [EXPAND_TAC "len" THEN REWRITE_TAC[ARITH_RULE `4 * (n + 1) = 4 * n + 4`] THEN
    REWRITE_TAC[REJ_UNIFORM_LENGTH_STEP]; ALL_TAC] THEN
  SUBGOAL_THEN `len 0 = 0` ASSUME_TAC THENL
   [EXPAND_TAC "len" THEN REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES;
     REJ_SAMPLE_EMPTY; LENGTH];
    ALL_TAC] THEN
  SUBGOAL_THEN `?n. 0 < n /\ (d <= n \/ ~((len:num->num) n <= 252))` MP_TAC
    THENL
   [EXISTS_TAC `d:num` THEN ASM_REWRITE_TAC[LE_REFL];
    GEN_REWRITE_TAC LAND_CONV [num_WOP]] THEN
  DISCH_THEN(X_CHOOSE_THEN `N:num` (CONJUNCTS_THEN2
    (CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC) ASSUME_TAC)) THEN
  EXISTS_TAC `N:num` THEN
  SUBGOAL_THEN `!i. i < N ==> i + 1 <= d /\ len i <= 252` ASSUME_TAC THENL
   [X_GEN_TAC `i:num` THEN DISCH_TAC THEN ASM_CASES_TAC `i = 0` THENL
     [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `0 < d` THEN ARITH_TAC;
      FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN ASM_REWRITE_TAC[] THEN
      UNDISCH_TAC `~(i = 0)` THEN ARITH_TAC];
    ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPEC `N - 1` (ASSUME `!i. i < N ==> i + 1 <= d /\ (len:num->num) i <=
    252`)) THEN
  MP_TAC(SPEC `N - 1` (ASSUME `!n. (len:num->num)(n + 1) <= len n + 4`)) THEN
  SIMP_TAC[ASSUME `0 < N`; ARITH_RULE `0 < N ==> N - 1 < N`;
           ARITH_RULE `0 < N ==> N - 1 + 1 = N`] THEN
  ARITH_TAC);;

(* The main loop runs N groups; N comes from REJ_UNIFORM_GROUP_COUNT. *)

let MLDSA_REJ_UNIFORM_LOOP = prove
 (`!res buf buflen (inlist:(24 word)list) e pc N.
    aligned 4 res /\ aligned 4 buf /\
    val res + 1024 < 2 EXP 32 /\ val buf + buflen < 2 EXP 32 /\
    buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\
    nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
    nonoverlapping (res,1024) (buf,buflen) /\
    0 < N /\ 12 * N <= buflen /\
    LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * N) inlist)) <= 256 /\
    (buflen <= 12 * N \/ ~(LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * N) inlist)) <=
      252)) /\
    (!i. i < N ==> 12 * i + 12 <= buflen /\
         LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * i) inlist)) <= 252)
    ==> ensures riscv
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + 0x24) /\
            rej_uniform_prefix res buf buflen inlist e 0 s)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + (if buflen <= 12 * N then 0x13c else 0xa8))
              /\
            rej_uniform_prefix res buf buflen inlist e (4 * N) s)
       (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                   T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  (REPEAT GEN_TAC THEN   DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  ENSURES_WHILE_UP_TAC `N:num` `pc + 0x24` `pc + 0xa0`
   `\i s. rej_uniform_prefix res buf buflen inlist e (4 * i) s` THEN
  REPEAT CONJ_TAC) THENL
  [UNDISCH_TAC `0 < N` THEN ARITH_TAC;
   REWRITE_TAC[MULT_CLAUSES] THEN ENSURES_INIT_TAC "s0" THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];
   X_GEN_TAC `i:num` THEN STRIP_TAC THEN
  REWRITE_TAC[ARITH_RULE `4 * (i + 1) = 4 * i + 4`] THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN ASM_REWRITE_TAC[] THEN STRIP_TAC
    THEN
  MATCH_MP_TAC MLDSA_REJ_UNIFORM_MAIN_GROUP THEN ASM_REWRITE_TAC[];
   X_GEN_TAC `i:num` THEN STRIP_TAC THEN
  FIRST_ASSUM(STRIP_ASSUME_TAC o C MP (ASSUME `i < N`) o SPEC `i:num`) THEN
  MP_TAC(SPECL [`res:int32`; `buf:int32`; `buflen:num`; `inlist:(24 word)list`;
                `e:((32)address_uarch_event)list`; `i:num`;
                  `pc:num`] (MLDSA_REJ_UNIFORM_TEST)) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `~(buflen <= 12 * i)` (fun th -> REWRITE_TAC[th]) THENL
   [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_REWRITE_TAC[];
   MP_TAC(SPECL [`res:int32`; `buf:int32`; `buflen:num`; `inlist:(24 word)list`;
                `e:((32)address_uarch_event)list`; `N:num`;
                  `pc:num`] (MLDSA_REJ_UNIFORM_TEST)) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
  ASM_CASES_TAC `buflen <= 12 * N` THEN ASM_REWRITE_TAC[] THEN
  SUBGOAL_THEN `~(LENGTH(REJ_SAMPLE(SUB_LIST(0,4 * N) (inlist:(24 word)list)))
    <= 252)`
    (fun th -> REWRITE_TAC[th]) THEN
  ASM_MESON_TAC[]]);;

(* The tail loop and the return block. *)

let REJ_UNIFORM_PREFIX_STEP = prove
 (`!(inlist:(24 word)list) n.
     n < LENGTH inlist
     ==> REJ_SAMPLE (SUB_LIST(0,n + 1) inlist) =
         rej_uniform_step (REJ_SAMPLE (SUB_LIST(0,n) inlist))
           (word(val(EL n inlist) MOD 2 EXP 23))`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[SUB_LIST_SPLIT; ADD_CLAUSES; REJ_SAMPLE_APPEND; rej_uniform_step]
    THEN
  AP_TERM_TAC THEN
  SUBGOAL_THEN `SUB_LIST(n,1) (inlist:(24 word)list) = [EL n inlist]`
    SUBST1_TAC THENL
   [ASM_SIMP_TAC[SUB_LIST_1]; ALL_TAC] THEN
  REWRITE_TAC[REJ_SAMPLE; MAP; FILTER] THEN COND_CASES_TAC THEN REWRITE_TAC[]);;

let REJ_UNIFORM_EL_GROUP = prove
 (`!(inlist:(24 word)list) g j.
     4 * g + 4 <= LENGTH inlist /\ j < 4
     ==> EL j (MAP (\x:24 word. word(val x MOD 2 EXP 23):int32)
                 (SUB_LIST(4 * g,4) inlist)) =
         word(val(EL (4 * g + j) inlist) MOD 2 EXP 23)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `j < LENGTH(SUB_LIST(4 * g,4) (inlist:(24 word)list))`
    ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_SUB_LIST] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[EL_MAP; EL_SUB_LIST] THEN REWRITE_TAC[ADD_SYM]);;

let rej_uniform_done = new_definition
 `rej_uniform_done res buf buflen (inlist:(24 word)list) e k s <=>
    let outlist = REJ_SAMPLE (SUB_LIST (0,k) inlist) in
    let outlen = LENGTH outlist in
    read A0 s = res /\
    read A3 s = word_add res (word (4 * outlen)) /\
    read (memory :> bytes (res,4 * outlen)) s = num_of_wordlist outlist /\
    (?e2. read events s = APPEND e2 e /\
          memaccess_inbounds e2 [buf,buflen; res,1024] [res,1024])`;;

let REJ_UNIFORM_PREFIX_DONE = prove
 (`!res buf buflen (inlist:(24 word)list) e k s.
     rej_uniform_prefix res buf buflen inlist e k s
     ==> rej_uniform_done res buf buflen inlist e k s`,
  REWRITE_TAC[rej_uniform_prefix; rej_uniform_done] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN SIMP_TAC[]);;

let VAL_RES_OFFSET = prove
 (`!(res:int32) n. val res + 1024 < 2 EXP 32 /\ n <= 256
     ==> val(word_add res (word(4 * n))) = val res + 4 * n`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
  CONV_TAC MOD_DOWN_CONV THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC);;

let VAL_FACTS_TAC l =
  let n = mk_comb(`LENGTH:int32 list->num`, l) in
  MP_TAC(SPECL [`res:int32`; n] VAL_RES_OFFSET) THEN
  MP_TAC(SPECL [`res:int32`; `256`] VAL_RES_OFFSET) THEN
  CONV_TAC NUM_REDUCE_CONV THEN ASM_REWRITE_TAC[] THEN
  REPEAT DISCH_TAC;;

let EXIT_TAC k =
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN DISJ1_TAC THEN
  EXISTS_TAC k THEN REWRITE_TAC[rej_uniform_done] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC NUM_REDUCE_CONV THEN ASM_REWRITE_TAC[] THEN
  TRY(CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC]) THEN
  EXPAND_TAC "cur" THEN DISCHARGE_MEMSAFE_ASM_TAC;;

let BRANCH_TAC l k step s =
  let sv = mk_var(s,`:riscvstate`) in
  let full = mk_eq(mk_comb(`LENGTH:int32 list->num`, l), `256`) in
  VAL_FACTS_TAC l THEN ASM_CASES_TAC full THENL
   [RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [step] THEN
    RULE_ASSUM_TAC(fun th -> if vfree_in sv (concl th)
                             then CONV_RULE NUM_REDUCE_CONV th else th) THEN
    STATE_REWRITE_TAC sv [GE; LE_REFL; ASSUME full] THEN
    RULE_ASSUM_TAC(fun th -> if vfree_in sv (concl th)
                             then CONV_RULE NUM_REDUCE_CONV th else th) THEN
    EXIT_TAC k;
    SUBGOAL_THEN (mk_binop `(<=):num->num->bool` (mk_comb(`LENGTH:int32
      list->num`, l)) `255`)
      ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [step] THEN
    STATE_REWRITE_TAC sv [GE; LE_ADD_LCANCEL;
      ARITH_RULE `4 * n + 0 = 4 * n`; ARITH_RULE `1024 <= 4 * n <=> 256 <= n`]
        THEN
    SUBGOAL_THEN (mk_neg(mk_binop `(<=):num->num->bool` `256`
      (mk_comb(`LENGTH:int32 list->num`, l))))
      (fun th -> STATE_REWRITE_TAC sv [th]) THENL [ASM_ARITH_TAC; ALL_TAC]];;

(* REJ_SAMPLE of the first 4 * g + k candidates is the prefix Lk. *)

let PARTIAL_PREFIX_TAC k =
  let ks = string_of_int k and kp = string_of_int (k - 1) in
  let prev = if k = 1 then "4 * g" else "4 * g + " ^ kp in
  SUBGOAL_THEN
   (parse_term("REJ_SAMPLE (SUB_LIST(0,4 * g + " ^ ks ^
               ") (inlist:(24 word)list)) = L" ^ ks))
   ASSUME_TAC THENL
   [(if k = 1 then ALL_TAC else
     REWRITE_TAC[ARITH_RULE(parse_term
       ("4 * g + " ^ ks ^ " = (" ^ prev ^ ") + 1"))]) THEN
    MP_TAC(SPECL [`inlist:(24 word)list`; parse_term prev]
                 REJ_UNIFORM_PREFIX_STEP) THEN
    ANTS_TAC THENL
     [UNDISCH_TAC `4 * g + 4 <= LENGTH(inlist:(24 word)list)` THEN ARITH_TAC;
      DISCH_THEN SUBST1_TAC] THEN
    MP_TAC(SPECL [`inlist:(24 word)list`; `g:num`; parse_term kp]
                 REJ_UNIFORM_EL_GROUP) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV;
                    ALL_TAC] THEN
    REWRITE_TAC[ADD_CLAUSES] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
    ASM_REWRITE_TAC[];
    ALL_TAC];;

(* One pass of the tail loop, with its four early exits. *)

let MLDSA_REJ_UNIFORM_TAIL_GROUP = prove
 (`!res buf buflen (inlist:(24 word)list) pc e g.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + buflen < 2 EXP 32 /\
     buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\ 12 divides buflen
       /\
     12 * g + 12 <= buflen /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * g) inlist)) <= 255 /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,buflen)
     ==> ensures riscv
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0xac) /\
                rej_uniform_prefix res buf buflen inlist e (4 * g) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                ((read PC s = word (pc + 0x13c) /\
                  ?k. k <= LENGTH inlist /\
                      LENGTH (REJ_SAMPLE (SUB_LIST (0,k) inlist)) <= 256 /\
                      (k = LENGTH inlist \/
                       LENGTH (REJ_SAMPLE (SUB_LIST (0,k) inlist)) = 256) /\
                      rej_uniform_done res buf buflen inlist e k s) \/
                 (read PC s = word (pc + 0xac) /\
                  12 * (g + 1) + 12 <= buflen /\
                  LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * (g + 1)) inlist)) <= 255
                    /\
                  rej_uniform_prefix res buf buflen inlist e (4 * (g + 1)) s)))
           (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                       T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REJ_UNIFORM_GROUP_SETUP_TAC THEN
  MAP_EVERY PARTIAL_PREFIX_TAC [1; 2; 3] THEN
  REJ_UNIFORM_CAND_TAC `L0:int32 list` `L1:int32 list` `c0:int32`
    `255` (1--9) "s9" THEN
  BRANCH_TAC `L1:int32 list` `4 * g + 1` 10 "s10" THEN
  REJ_UNIFORM_CAND_TAC `L1:int32 list` `L2:int32 list` `c1:int32`
    `255` (11--18) "s18" THEN
  BRANCH_TAC `L2:int32 list` `4 * g + 2` 19 "s19" THEN
  REJ_UNIFORM_CAND_TAC `L2:int32 list` `L3:int32 list` `c2:int32`
    `255` (20--27) "s27" THEN
  BRANCH_TAC `L3:int32 list` `4 * g + 3` 28 "s28" THEN
  REJ_UNIFORM_CAND_TAC `L3:int32 list` `L4:int32 list` `c3:int32`
    `255` (29--34) "s34" THEN
  BRANCH_TAC `L4:int32 list` `4 * g + 4` 35 "s35" THEN
  SUBGOAL_THEN `val(word_sub (word_add buf (word buflen)) (word 12):int32) =
    val buf + buflen - 12 /\
                val(word_add cur (word 12):int32) = val buf + 12 * g + 12`
  STRIP_ASSUME_TAC THENL
   [EXPAND_TAC "cur" THEN
    SUBGOAL_THEN `word_sub (word_add buf (word buflen)) (word 12):int32 =
                  word_add buf (word (buflen - 12)) /\
                  word_add (word_add buf (word (12 * g))) (word 12):int32 =
                  word_add buf (word (12 * g + 12))` (fun th ->
                    REWRITE_TAC[th]) THENL
     [CONJ_TAC THENL
       [SUBGOAL_THEN `buflen = (buflen - 12) + 12` (fun th -> GEN_REWRITE_TAC
         (LAND_CONV o LAND_CONV o RAND_CONV o RAND_CONV) [th]) THENL
         [ASM_ARITH_TAC; REWRITE_TAC[GSYM WORD_ADD] THEN CONV_TAC WORD_RULE];
        CONV_TAC WORD_RULE];
      ALL_TAC] THEN
    REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_32] THEN
    CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
    CONJ_TAC THEN MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  ASM_CASES_TAC `12 * g + 24 <= buflen` THENL
   [SUBGOAL_THEN `val (buf:int32) + buflen - 12 >= val (buf:int32) + 12 * g +
     12` ASSUME_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [36] THEN
    STATE_REWRITE_TAC `s36:riscvstate`
      [ASSUME `val(word_sub (word_add buf (word buflen)) (word 12):int32) =
               val buf + buflen - 12`;
       ASSUME `val(word_add cur (word 12):int32) = val buf + 12 * g + 12`;
       ASSUME `val (buf:int32) + buflen - 12 >=
               val (buf:int32) + 12 * g + 12`] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN DISJ2_TAC THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[ARITH_RULE `12 * (g + 1) + 12 = 12 * g + 24`]
      THEN ASM_REWRITE_TAC[] THEN
    CONJ_TAC THENL [EXPAND_TAC "cur" THEN CONV_TAC WORD_RULE; ALL_TAC] THEN
    EXPAND_TAC "cur" THEN DISCHARGE_MEMSAFE_ASM_TAC;
    SUBGOAL_THEN `~(val (buf:int32) + buflen - 12 >= val (buf:int32) + 12 * g +
      12)` ASSUME_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `4 * g + 4 = LENGTH(inlist:(24 word)list)` ASSUME_TAC THENL
     [FIRST_X_ASSUM(MP_TAC o check (is_divides o concl)) THEN
      DISCH_THEN(X_CHOOSE_THEN `d:num` SUBST_ALL_TAC o REWRITE_RULE[divides])
        THEN
      RULE_ASSUM_TAC(REWRITE_RULE[ARITH_RULE `12 * g + 12 <= 12 * d <=> g + 1
        <= d`;
                                  ARITH_RULE `12 * g + 24 <= 12 * d <=> g + 2
                                    <= d`]) THEN
      UNDISCH_TAC `8 * 12 * d = 24 * LENGTH(inlist:(24 word)list)` THEN
      UNDISCH_TAC `g + 1 <= d` THEN UNDISCH_TAC `~(g + 2 <= d)` THEN ARITH_TAC;
      ALL_TAC] THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [36] THEN
    STATE_REWRITE_TAC `s36:riscvstate`
      [ASSUME `val(word_sub (word_add buf (word buflen)) (word 12):int32) =
               val buf + buflen - 12`;
       ASSUME `val(word_add cur (word 12):int32) = val buf + 12 * g + 12`;
       ASSUME `~(val (buf:int32) + buflen - 12 >=
               val (buf:int32) + 12 * g + 12)`] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN DISJ1_TAC THEN
    EXISTS_TAC `4 * g + 4` THEN REWRITE_TAC[rej_uniform_done] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[LE_REFL] THEN
    TRY(CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC]) THEN
    EXPAND_TAC "cur" THEN DISCHARGE_MEMSAFE_ASM_TAC]);;

(* The tail loop runs until the output is full or the input is used up. *)

let ENSURES_SPLIT = prove
 (`!(step:A->A->bool) P1 P2 Q C.
     ensures step P1 Q C /\ ensures step P2 Q C
     ==> ensures step (\s. P1 s \/ P2 s) Q C`,
  REWRITE_TAC[ensures] THEN MESON_TAC[]);;

let rej_uniform_finished = new_definition
 `rej_uniform_finished res buf buflen (inlist:(24 word)list) e s <=>
    ?k. k <= LENGTH inlist /\
        LENGTH (REJ_SAMPLE (SUB_LIST (0,k) inlist)) <= 256 /\
        (k = LENGTH inlist \/
         LENGTH (REJ_SAMPLE (SUB_LIST (0,k) inlist)) = 256) /\
        rej_uniform_done res buf buflen inlist e k s`;;

let MLDSA_REJ_UNIFORM_TAIL = prove
 (`!res buf buflen (inlist:(24 word)list) pc e g.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + buflen < 2 EXP 32 /\
     buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\ 12 divides buflen
       /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,buflen) /\
     12 * g + 12 <= buflen /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * g) inlist)) <= 255
     ==> ensures riscv
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0xac) /\
                rej_uniform_prefix res buf buflen inlist e (4 * g) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x13c) /\
                rej_uniform_finished res buf buflen inlist e s)
           (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                       T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN WF_INDUCT_TAC `buflen - 12 * g` THEN STRIP_TAC THEN
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN
  EXISTS_TAC
   `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
        ((read PC s = word (pc + 0x13c) /\
          rej_uniform_finished res buf buflen inlist e s) \/
         (read PC s = word (pc + 0xac) /\
          12 * (g + 1) + 12 <= buflen /\
          LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * (g + 1)) inlist)) <= 255 /\
          rej_uniform_prefix res buf buflen inlist e (4 * (g + 1)) s))` THEN
  REPEAT CONJ_TAC THENL
   [MAYCHANGE_IDEMPOT_TAC;
    REWRITE_TAC[rej_uniform_finished] THEN
    MATCH_MP_TAC MLDSA_REJ_UNIFORM_TAIL_GROUP THEN ASM_REWRITE_TAC[];
    REWRITE_TAC[LEFT_OR_DISTRIB] THEN MATCH_MP_TAC ENSURES_SPLIT THEN
    CONJ_TAC THENL
     [MATCH_MP_TAC ENSURES_ALREADY THEN CONJ_TAC THENL
       [SIMP_TAC[];
                SUBSUMED_ID_MAYCHANGE_TAC];
      CONV_TAC(RATOR_CONV(RATOR_CONV(RAND_CONV(ABS_CONV(REWRITE_CONV
        [TAUT `a /\ b /\ c /\ d /\ e <=> c /\ d /\ a /\ b /\ e`]))))) THEN
      REWRITE_TAC[ENSURES_CONSTANT_PRECONDITION_CONJUNCTS] THEN
      REPEAT STRIP_TAC THEN
      FIRST_X_ASSUM(MP_TAC o SPECL [`buflen:num`; `g + 1`]) THEN
      ASM_REWRITE_TAC[] THEN ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[]]]]);;

let REJ_UNIFORM_FINAL_PREFIX = prove
 (`!(inlist:(24 word)list) n.
     LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) <= 256 /\
     (n = LENGTH inlist \/ LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) = 256)
     ==> SUB_LIST(0,256) (REJ_SAMPLE inlist) =
         REJ_SAMPLE(SUB_LIST(0,n) inlist)`,
  REPEAT GEN_TAC THEN STRIP_TAC THENL
   [FIRST_X_ASSUM SUBST_ALL_TAC THEN
    RULE_ASSUM_TAC(SIMP_RULE[SUB_LIST_REFL; LE_REFL]) THEN
    ASM_SIMP_TAC[SUB_LIST_REFL; LE_REFL];
    MP_TAC(ISPECL [`inlist:(24 word)list`; `n:num`] SUB_LIST_TOPSPLIT) THEN
    DISCH_THEN(fun th -> GEN_REWRITE_TAC (LAND_CONV o RAND_CONV o RAND_CONV)
      [SYM th]) THEN REWRITE_TAC[REJ_SAMPLE_APPEND] THEN
    ASM_SIMP_TAC[SUB_LIST_APPEND_LEFT; SUB_LIST_REFL; LE_REFL]]);;

let REJ_UNIFORM_COUNT_WORD = prove
 (`!(res:int32) n. n <= 256
     ==> word_ushr (word_sub (word_add res (word (4 * n))) res) 2 = word n`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[WORD_RULE `word_sub (word_add res x) res:int32 = x`] THEN
  REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_USHR; VAL_WORD; DIMINDEX_32] THEN
  SUBGOAL_THEN `4 * n < 2 EXP 32 /\ n < 2 EXP 32` STRIP_ASSUME_TAC THENL
   [ASM_ARITH_TAC; ASM_SIMP_TAC[MOD_LT]] THEN
  CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
  SIMP_TAC[DIV_MULT; ARITH_EQ]);;

(* The return block computes the number of coefficients written. *)

let MLDSA_REJ_UNIFORM_RETURN = prove
 (`!res buf buflen (inlist:(24 word)list) pc e.
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures riscv
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x13c) /\
                rej_uniform_finished res buf buflen inlist e s)
           (\s. read PC s = word (pc + 0x144) /\
                let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
                C_RETURN s = word(LENGTH outlist) /\
                read (memory :> bytes(res,4 * LENGTH outlist)) s =
                  num_of_wordlist outlist /\
                ?e2. read events s = APPEND e2 e /\
                     memaccess_inbounds e2 [buf,buflen; res,1024] [res,1024])
           (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                       T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_finished; rej_uniform_done;
    LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
  DISCH_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  ENSURES_INIT_TAC "s0" THEN
  FIRST_X_ASSUM(X_CHOOSE_THEN `k:num` (REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC))
    THEN
  FIRST_X_ASSUM(CHOOSE_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
  MP_TAC(SPECL [`inlist:(24 word)list`; `k:num`] REJ_UNIFORM_FINAL_PREFIX) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[]; DISCH_THEN(fun th -> REWRITE_TAC[th])] THEN
  ABBREV_TAC `outlen = LENGTH(REJ_SAMPLE(SUB_LIST(0,k) (inlist:(24
    word)list)))` THEN
  RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--2) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[C_RETURN] THEN
  ASM_SIMP_TAC[REJ_UNIFORM_COUNT_WORD] THEN
  EXISTS_TAC `e2:((32)address_uarch_event)list` THEN ASM_REWRITE_TAC[]);;

(* The check at 0xa8 leads either straight to the return or into the
   tail loop. *)

let MLDSA_REJ_UNIFORM_TAIL_ENTRY = prove
 (`!res buf buflen (inlist:(24 word)list) pc e N.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + buflen < 2 EXP 32 /\
     buflen < 2 EXP 32 /\ 8 * buflen = 24 * LENGTH inlist /\ 12 divides buflen
       /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,buflen) /\
     12 * N <= buflen /\ ~(buflen <= 12 * N) /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * N) inlist)) <= 256 /\
     ~(LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * N) inlist)) <= 252)
     ==> ensures riscv
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0xa8) /\
                rej_uniform_prefix res buf buflen inlist e (4 * N) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x13c) /\
                rej_uniform_finished res buf buflen inlist e s)
           (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                       T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `12 * N + 12 <= buflen /\ 4 * N + 4 <= LENGTH(inlist:(24
    word)list)` STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o check (is_divides o concl)) THEN
    DISCH_THEN(X_CHOOSE_THEN `d:num` SUBST_ALL_TAC o REWRITE_RULE[divides]) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ARITH_RULE `12 * d <= 12 * N <=> d <= N`]) THEN
    REWRITE_TAC[ARITH_RULE `12 * N + 12 <= 12 * d <=> N + 1 <= d`] THEN
    UNDISCH_TAC `8 * 12 * d = 24 * LENGTH(inlist:(24 word)list)` THEN
    UNDISCH_TAC `~(d <= N)` THEN ARITH_TAC;
    ALL_TAC] THEN
  ABBREV_TAC `len = LENGTH (REJ_SAMPLE (SUB_LIST (0,4 * N) (inlist:(24
    word)list)))` THEN
  ASM_CASES_TAC `len = 256` THENL
   [REWRITE_TAC[rej_uniform_prefix; rej_uniform_finished; rej_uniform_done;
      LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
    ENSURES_INIT_TAC "s0" THEN
    FIRST_X_ASSUM(CHOOSE_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
    MP_TAC(SPECL [`res:int32`; `256`] VAL_RES_OFFSET) THEN
    CONV_TAC NUM_REDUCE_CONV THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [1] THEN
    STATE_REWRITE_TAC `s1:riscvstate` [GE; LE_REFL] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    EXISTS_TAC `4 * N` THEN ASM_REWRITE_TAC[LE_REFL] THEN
    TRY(CONJ_TAC THENL [ASM_ARITH_TAC; ALL_TAC]) THEN DISCHARGE_MEMSAFE_ASM_TAC;
    
    SUBGOAL_THEN `len <= 255` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    ENSURES_SEQUENCE_TAC `pc + 0xac`
   `\s. rej_uniform_prefix res buf buflen inlist e (4 * N) s` THEN
  CONJ_TAC THENL
   [REWRITE_TAC[rej_uniform_prefix;
                LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ASM_REWRITE_TAC[] THEN
    ENSURES_INIT_TAC "s0" THEN
    FIRST_X_ASSUM(CHOOSE_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC)) THEN
    MP_TAC(SPECL [`res:int32`; `256`] VAL_RES_OFFSET) THEN
    ASM_REWRITE_TAC[LE_REFL] THEN CONV_TAC NUM_REDUCE_CONV THEN DISCH_TAC THEN
    MP_TAC(SPECL [`res:int32`; `len:num`] VAL_RES_OFFSET) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; DISCH_TAC] THEN
    RISCV_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [1] THEN
    SUBGOAL_THEN `~(256 <= len)` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    STATE_REWRITE_TAC `s1:riscvstate` [GE; LE_ADD_LCANCEL;
      ARITH_RULE `1024 <= 4 * n <=> 256 <= n`; ASSUME `~(256 <= len)`] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    DISCHARGE_MEMSAFE_ASM_TAC;
    MATCH_MP_TAC MLDSA_REJ_UNIFORM_TAIL THEN
    ASM_REWRITE_TAC[]]]);;

(* Functional correctness and memory safety of the core, up to the return. *)

let MLDSA_REJ_UNIFORM_CORRECT_MEMSAFE = prove
 (`!res buf buflen (inlist:(24 word)list) pc e.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + val buflen < 2 EXP 32 /\
     12 divides val buflen /\ 0 < val buflen /\
     8 * val buflen = 24 * LENGTH inlist /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,val buflen)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
               read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen] s /\
               read (memory :> bytes(buf,val buflen)) s = num_of_wordlist
                 inlist /\
               read events s = e)
          (\s. read PC s = word (pc + 0x144) /\
               let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
               C_RETURN s = word(LENGTH outlist) /\
               read (memory :> bytes(res,4 * LENGTH outlist)) s =
                 num_of_wordlist outlist /\
               ?e2. read events s = APPEND e2 e /\
                    memaccess_inbounds e2 [buf,val buflen; res,1024] [res,1024])
          (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                      T0; T1; T2; T3; T4; T5; T6] ,,
            MAYCHANGE [events] ,,
           MAYCHANGE [memory :> bytes(res,1024)])`,
  MAP_EVERY X_GEN_TAC [`res:int32`; `buf:int32`; `buflen:int32`] THEN
  MAP_EVERY X_GEN_TAC [`inlist:(24 word)list`; `pc:num`;
    `e:((32)address_uarch_event)list`] THEN
  ABBREV_TAC `n = val(buflen:int32)` THEN
  SUBGOAL_THEN `buflen:int32 = word n /\ n < 2 EXP 32` STRIP_ASSUME_TAC THENL
   [EXPAND_TAC "n" THEN REWRITE_TAC[WORD_VAL] THEN
    MP_TAC(ISPEC `buflen:int32` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_32];
    ALL_TAC] THEN
  ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
  MP_TAC(SPECL [`n:num`; `inlist:(24 word)list`] REJ_UNIFORM_GROUP_COUNT) THEN
  ASM_REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `N:num` (REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC)) THEN
    ENSURES_SEQUENCE_TAC `pc + 0x13c`
   `\s. rej_uniform_finished res buf n inlist e s` THEN
  CONJ_TAC THENL
   [ALL_TAC;
    MATCH_MP_TAC MLDSA_REJ_UNIFORM_RETURN THEN
    ASM_REWRITE_TAC[]] THEN
  ENSURES_SEQUENCE_TAC `pc + 0x24`
   `\s. rej_uniform_prefix res buf n inlist e 0 s` THEN
  CONJ_TAC THENL
   [MATCH_ACCEPT_TAC MLDSA_REJ_UNIFORM_INIT;
    ALL_TAC] THEN
  MP_TAC(SPECL [`res:int32`; `buf:int32`; `n:num`; `inlist:(24 word)list`;
                `e:((32)address_uarch_event)list`; `pc:num`; `N:num`]
         (MLDSA_REJ_UNIFORM_LOOP)) THEN
  ASM_REWRITE_TAC[] THEN
  ASM_CASES_TAC `n <= 12 * N` THEN ASM_REWRITE_TAC[] THENL
   [MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_POSTCONDITION_THM) THEN
    X_GEN_TAC `s:riscvstate` THEN REWRITE_TAC[] THEN STRIP_TAC THEN
    ASM_REWRITE_TAC[rej_uniform_finished] THEN EXISTS_TAC `4 * N` THEN
    SUBGOAL_THEN `4 * N = LENGTH(inlist:(24 word)list)` ASSUME_TAC THENL
     [ASM_ARITH_TAC; ALL_TAC] THEN
    ASM_REWRITE_TAC[LE_REFL] THEN
    FIRST_ASSUM(SUBST1_TAC o SYM) THEN
    MATCH_MP_TAC REJ_UNIFORM_PREFIX_DONE THEN ASM_REWRITE_TAC[];
    DISCH_TAC THEN
    ENSURES_SEQUENCE_TAC `pc + 0xa8`
     `\s. rej_uniform_prefix res buf n inlist e (4 * N) s` THEN
    ASM_REWRITE_TAC[] THEN
    MATCH_MP_TAC MLDSA_REJ_UNIFORM_TAIL_ENTRY THEN
    ASM_REWRITE_TAC[] THEN ASM_MESON_TAC[]]);;

(* The theorems for a call of the routine. *)

let REJ_UNIFORM_PROJECT_TAC starting_events =
  REWRITE_TAC[ensures] THEN X_GEN_TAC `s0:riscvstate` THEN STRIP_TAC THEN
  MP_TAC(SPECL [`res:int32`; `buf:int32`; `buflen:int32`;
    `inlist:(24 word)list`; `pc:num`; starting_events]
    MLDSA_REJ_UNIFORM_CORRECT_MEMSAFE) THEN
  CONV_TAC(LAND_CONV(TOP_DEPTH_CONV let_CONV)) THEN
  ASM_REWRITE_TAC[ensures] THEN DISCH_THEN(MP_TAC o SPEC `s0:riscvstate`) THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[RIGHT_IMP_FORALL_THM] EVENTUALLY_MONO) THEN
  SIMP_TAC[];;

let MLDSA_REJ_UNIFORM_CORRECT = prove
 (`!res buf buflen (inlist:(24 word)list) pc.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + val buflen < 2 EXP 32 /\
     12 divides val buflen /\ 0 < val buflen /\
     8 * val buflen = 24 * LENGTH inlist /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,val buflen)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
               read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen] s /\
               read (memory :> bytes(buf,val buflen)) s = num_of_wordlist
                 inlist)
          (\s. read PC s = word (pc + 0x144) /\
               let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
               let outlen = LENGTH outlist in
               C_RETURN s = word outlen /\
               read (memory :> bytes(res,4 * outlen)) s = num_of_wordlist
                 outlist)
          (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                      T0; T1; T2; T3; T4; T5; T6] ,,
           MAYCHANGE [events] ,,
           MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REJ_UNIFORM_PROJECT_TAC `read events s0`);;

let MLDSA_REJ_UNIFORM_SUBROUTINE_CORRECT = prove
 (`!res buf buflen (inlist:(24 word)list) pc returnaddress.
     aligned 4 res /\ aligned 4 buf /\ aligned 4 returnaddress /\
     val res + 1024 < 2 EXP 32 /\ val buf + val buflen < 2 EXP 32 /\
     12 divides val buflen /\ 0 < val buflen /\
     8 * val buflen = 24 * LENGTH inlist /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,val buflen)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
               read PC s = word pc /\ read RA s = returnaddress /\
               C_ARGUMENTS [res;buf;buflen] s /\
               read (memory :> bytes(buf,val buflen)) s = num_of_wordlist
                 inlist)
          (\s. read PC s = returnaddress /\
               let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
               let outlen = LENGTH outlist in
               C_RETURN s = word outlen /\
               read (memory :> bytes(res,4 * outlen)) s = num_of_wordlist
                 outlist)
          (MAYCHANGE_REGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(res,1024)])`,
  let conv = TOP_DEPTH_CONV let_CONV THENC
    REWRITE_CONV[fst MLDSA_REJ_UNIFORM_EXEC] in
  CONV_TAC conv THEN RISCV_ADD_RETURN_NOSTACK_TAC MLDSA_REJ_UNIFORM_EXEC
    (CONV_RULE conv MLDSA_REJ_UNIFORM_CORRECT));;
let MLDSA_REJ_UNIFORM_MEMSAFE = prove
 (`!res buf buflen (inlist:(24 word)list) pc e.
     aligned 4 res /\ aligned 4 buf /\
     val res + 1024 < 2 EXP 32 /\ val buf + val buflen < 2 EXP 32 /\
     12 divides val buflen /\ 0 < val buflen /\
     8 * val buflen = 24 * LENGTH inlist /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,val buflen)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
               read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen] s /\
               read (memory :> bytes(buf,val buflen)) s = num_of_wordlist
                 inlist /\
               read events s = e)
          (\s. read PC s = word (pc + 0x144) /\
               ?e2. read events s = APPEND e2 e /\
                    memaccess_inbounds e2 [buf,val buflen; res,1024] [res,1024])
          (MAYCHANGE [PC; A0; A1; A2; A3; A4; A5; A6; A7;
                      T0; T1; T2; T3; T4; T5; T6] ,,
           MAYCHANGE [events] ,,
           MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  REJ_UNIFORM_PROJECT_TAC `e:((32)address_uarch_event)list`);;

let MLDSA_REJ_UNIFORM_SUBROUTINE_MEMSAFE = prove
 (`!res buf buflen (inlist:(24 word)list) pc e returnaddress.
     aligned 4 res /\ aligned 4 buf /\ aligned 4 returnaddress /\
     val res + 1024 < 2 EXP 32 /\ val buf + val buflen < 2 EXP 32 /\
     12 divides val buflen /\ 0 < val buflen /\
     8 * val buflen = 24 * LENGTH inlist /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc) /\
     nonoverlapping (res,1024) (buf,val buflen)
     ==> ensures riscv
          (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
               read PC s = word pc /\ read RA s = returnaddress /\
               C_ARGUMENTS [res;buf;buflen] s /\
               read (memory :> bytes(buf,val buflen)) s = num_of_wordlist
                 inlist /\
               read events s = e)
          (\s. read PC s = returnaddress /\
               ?e2. read events s = APPEND e2 e /\
                    memaccess_inbounds e2 [buf,val buflen; res,1024] [res,1024])
          (MAYCHANGE_REGS_PERMITTED_BY_ABI ,,
           MAYCHANGE [memory :> bytes(res,1024)])`,
  let conv = REWRITE_CONV[fst MLDSA_REJ_UNIFORM_EXEC] in
  CONV_TAC conv THEN RISCV_ADD_RETURN_NOSTACK_TAC MLDSA_REJ_UNIFORM_EXEC
    (CONV_RULE conv MLDSA_REJ_UNIFORM_MEMSAFE) THEN
  DISCHARGE_MEMSAFE_ASM_TAC);;
