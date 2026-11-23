(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

(* ========================================================================= *)
(* Uniform rejection sampling for ML-DSA, filtering packed numbers < Q.      *)
(*                                                                           *)
(* ML-DSA uses q = 8380417 with 23-bit coefficients packed as 3 bytes each.  *)
(* The assembly processes 48 bytes (16 coefficients) per main-loop iteration *)
(* and stores accepted coefficients as 32-bit words.                         *)
(* ========================================================================= *)

(* Load base theories for AArch64 from s2n-bignum *)
needs "s2n_bignum/arm/proofs/base.ml";;

needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_rej_uniform_table.ml";;

(**** print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_aarch64_asm.o";;
 ****)

let mldsa_rej_uniform_mc = define_assert_from_elf
  "mldsa_rej_uniform_mc" "aarch64/mldsa/mldsa_rej_uniform_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0xd2800027;       (* arm_MOV X7 (rvalue (word 1)) *)
  0xf2c00047;       (* arm_MOVK X7 (word 2) 32 *)
  0xd280008b;       (* arm_MOV X11 (rvalue (word 4)) *)
  0xf2c0010b;       (* arm_MOVK X11 (word 8) 32 *)
  0x9e6700ff;       (* arm_FMOV_ItoF Q31 X7 0 *)
  0x4e181d7f;       (* arm_INS_GEN Q31 X11 64 64 *)
  0x4f00e43d;       (* arm_MOVI Q29 (word 72340172838076673) *)
  0x4ebd9ffd;       (* arm_MUL_VEC Q29 Q31 Q29 32 128 *)
  0x529c0024;       (* arm_MOV W4 (rvalue (word 57345)) *)
  0x72a00fe4;       (* arm_MOVK W4 (word 127) 16 *)
  0x4e040c9e;       (* arm_DUP_GEN Q30 X4 32 128 *)
  0xd2802007;       (* arm_MOV X7 (rvalue (word 256)) *)
  0xf2b00047;       (* arm_MOVK X7 (word 32770) 16 *)
  0xf2c08067;       (* arm_MOVK X7 (word 1027) 32 *)
  0xf2f000a7;       (* arm_MOVK X7 (word 32773) 48 *)
  0xd280e0cb;       (* arm_MOV X11 (rvalue (word 1798)) *)
  0xf2b0010b;       (* arm_MOVK X11 (word 32776) 16 *)
  0xf2c1412b;       (* arm_MOVK X11 (word 2569) 32 *)
  0xf2f0016b;       (* arm_MOVK X11 (word 32779) 48 *)
  0x9e6700f4;       (* arm_FMOV_ItoF Q20 X7 0 *)
  0x4e181d74;       (* arm_INS_GEN Q20 X11 64 64 *)
  0x4f04441c;       (* arm_MOVI Q28 (word 36028797027352576) *)
  0x4f00e584;       (* arm_MOVI Q4 (word 868082074056920076) *)
  0x4f00e505;       (* arm_MOVI Q5 (word 578721382704613384) *)
  0x4f00e486;       (* arm_MOVI Q6 (word 289360691352306692) *)
  0x4e248695;       (* arm_ADD_VEC Q21 Q20 Q4 8 128 *)
  0x4e258696;       (* arm_ADD_VEC Q22 Q20 Q5 8 128 *)
  0x4e268697;       (* arm_ADD_VEC Q23 Q20 Q6 8 128 *)
  0xd2800009;       (* arm_MOV X9 (rvalue (word 0)) *)
  0xf100c05f;       (* arm_CMP X2 (rvalue (word 48)) *)
  0x54000703;       (* arm_BCC (word 224) *)
  0xf103c13f;       (* arm_CMP X9 (rvalue (word 240)) *)
  0x540006c8;       (* arm_BHI (word 216) *)
  0xd100c042;       (* arm_SUB X2 X2 (rvalue (word 48)) *)
  0x4cdf6020;       (* arm_LDP3 Q0 Q1 Q2 X1 (Postimmediate_Offset (word 48)) *)
  0x4e140010;       (* arm_TBL Q16 [Q0] Q20 128 *)
  0x4e152011;       (* arm_TBL2 Q17 Q0 Q1 Q21 128 *)
  0x4e162032;       (* arm_TBL2 Q18 Q1 Q2 Q22 128 *)
  0x4e170053;       (* arm_TBL Q19 [Q2] Q23 128 *)
  0x4e7c1e10;       (* arm_BIC_VEC Q16 Q16 Q28 128 *)
  0x4e7c1e31;       (* arm_BIC_VEC Q17 Q17 Q28 128 *)
  0x4e7c1e52;       (* arm_BIC_VEC Q18 Q18 Q28 128 *)
  0x4e7c1e73;       (* arm_BIC_VEC Q19 Q19 Q28 128 *)
  0x6eb037c4;       (* arm_CMHI_VEC Q4 Q30 Q16 32 128 *)
  0x6eb137c5;       (* arm_CMHI_VEC Q5 Q30 Q17 32 128 *)
  0x6eb237c6;       (* arm_CMHI_VEC Q6 Q30 Q18 32 128 *)
  0x6eb337c7;       (* arm_CMHI_VEC Q7 Q30 Q19 32 128 *)
  0x4e052884;       (* arm_TRN1 Q4 Q4 Q5 8 128 *)
  0x4e0728c5;       (* arm_TRN1 Q5 Q6 Q7 8 128 *)
  0x4e452884;       (* arm_TRN1 Q4 Q4 Q5 16 128 *)
  0x4e3d1c84;       (* arm_AND_VEC Q4 Q4 Q29 128 *)
  0x6eb03880;       (* arm_UADDLV Q0 Q4 4 32 *)
  0x9e66000f;       (* arm_FMOV_FtoI X15 Q0 0 64 *)
  0xd3400dec;       (* arm_UBFM X12 X15 0 3 *)
  0xd3482ded;       (* arm_UBFM X13 X15 8 11 *)
  0xd3504dee;       (* arm_UBFM X14 X15 16 19 *)
  0xd3586def;       (* arm_UBFM X15 X15 24 27 *)
  0x3cec7878;       (* arm_LDR Q24 X3 (Shiftreg_Offset X12 4) *)
  0x3ced7879;       (* arm_LDR Q25 X3 (Shiftreg_Offset X13 4) *)
  0x3cee787a;       (* arm_LDR Q26 X3 (Shiftreg_Offset X14 4) *)
  0x3cef787b;       (* arm_LDR Q27 X3 (Shiftreg_Offset X15 4) *)
  0x4e205884;       (* arm_CNT Q4 Q4 128 *)
  0x6eb03880;       (* arm_UADDLV Q0 Q4 4 32 *)
  0x9e66000f;       (* arm_FMOV_FtoI X15 Q0 0 64 *)
  0xd34009ec;       (* arm_UBFM X12 X15 0 2 *)
  0xd34829ed;       (* arm_UBFM X13 X15 8 10 *)
  0xd35049ee;       (* arm_UBFM X14 X15 16 18 *)
  0xd35869ef;       (* arm_UBFM X15 X15 24 26 *)
  0x4e180210;       (* arm_TBL Q16 [Q16] Q24 128 *)
  0x4e190231;       (* arm_TBL Q17 [Q17] Q25 128 *)
  0x4e1a0252;       (* arm_TBL Q18 [Q18] Q26 128 *)
  0x4e1b0273;       (* arm_TBL Q19 [Q19] Q27 128 *)
  0x4c007810;       (* arm_STR Q16 X0 No_Offset *)
  0x8b0c0800;       (* arm_ADD X0 X0 (Shiftedreg X12 LSL 2) *)
  0x4c007811;       (* arm_STR Q17 X0 No_Offset *)
  0x8b0d0800;       (* arm_ADD X0 X0 (Shiftedreg X13 LSL 2) *)
  0x4c007812;       (* arm_STR Q18 X0 No_Offset *)
  0x8b0e0800;       (* arm_ADD X0 X0 (Shiftedreg X14 LSL 2) *)
  0x4c007813;       (* arm_STR Q19 X0 No_Offset *)
  0x8b0f0800;       (* arm_ADD X0 X0 (Shiftedreg X15 LSL 2) *)
  0x8b0d018c;       (* arm_ADD X12 X12 X13 *)
  0x8b0f01ce;       (* arm_ADD X14 X14 X15 *)
  0x8b0c0129;       (* arm_ADD X9 X9 X12 *)
  0x8b0e0129;       (* arm_ADD X9 X9 X14 *)
  0xf100c05f;       (* arm_CMP X2 (rvalue (word 48)) *)
  0x54fff942;       (* arm_BCS (word 2096936) *)
  0xf100605f;       (* arm_CMP X2 (rvalue (word 24)) *)
  0x54000643;       (* arm_BCC (word 200) *)
  0xf103e13f;       (* arm_CMP X9 (rvalue (word 248)) *)
  0x54000408;       (* arm_BHI (word 128) *)
  0xd1006042;       (* arm_SUB X2 X2 (rvalue (word 24)) *)
  0x4cdf7020;       (* arm_LDR Q0 X1 (Postimmediate_Offset (word 16)) *)
  0x0cdf7021;       (* arm_LDR D1 X1 (Postimmediate_Offset (word 8)) *)
  0x4e140010;       (* arm_TBL Q16 [Q0] Q20 128 *)
  0x4e152011;       (* arm_TBL2 Q17 Q0 Q1 Q21 128 *)
  0x4e7c1e10;       (* arm_BIC_VEC Q16 Q16 Q28 128 *)
  0x4e7c1e31;       (* arm_BIC_VEC Q17 Q17 Q28 128 *)
  0x6eb037c4;       (* arm_CMHI_VEC Q4 Q30 Q16 32 128 *)
  0x6eb137c5;       (* arm_CMHI_VEC Q5 Q30 Q17 32 128 *)
  0x4e3f1c84;       (* arm_AND_VEC Q4 Q4 Q31 128 *)
  0x4e3f1ca5;       (* arm_AND_VEC Q5 Q5 Q31 128 *)
  0x6eb03880;       (* arm_UADDLV Q0 Q4 4 32 *)
  0x6eb038a1;       (* arm_UADDLV Q1 Q5 4 32 *)
  0x9e66000c;       (* arm_FMOV_FtoI X12 Q0 0 64 *)
  0x9e66002d;       (* arm_FMOV_FtoI X13 Q1 0 64 *)
  0x3cec7878;       (* arm_LDR Q24 X3 (Shiftreg_Offset X12 4) *)
  0x3ced7879;       (* arm_LDR Q25 X3 (Shiftreg_Offset X13 4) *)
  0x4e205884;       (* arm_CNT Q4 Q4 128 *)
  0x4e2058a5;       (* arm_CNT Q5 Q5 128 *)
  0x6eb03880;       (* arm_UADDLV Q0 Q4 4 32 *)
  0x6eb038a1;       (* arm_UADDLV Q1 Q5 4 32 *)
  0x9e66000c;       (* arm_FMOV_FtoI X12 Q0 0 64 *)
  0x9e66002d;       (* arm_FMOV_FtoI X13 Q1 0 64 *)
  0x4e180210;       (* arm_TBL Q16 [Q16] Q24 128 *)
  0x4e190231;       (* arm_TBL Q17 [Q17] Q25 128 *)
  0x4c007810;       (* arm_STR Q16 X0 No_Offset *)
  0x8b0c0800;       (* arm_ADD X0 X0 (Shiftedreg X12 LSL 2) *)
  0x4c007811;       (* arm_STR Q17 X0 No_Offset *)
  0x8b0d0800;       (* arm_ADD X0 X0 (Shiftedreg X13 LSL 2) *)
  0x8b0c0129;       (* arm_ADD X9 X9 X12 *)
  0x8b0d0129;       (* arm_ADD X9 X9 X13 *)
  0xf104013f;       (* arm_CMP X9 (rvalue (word 256)) *)
  0x540001e2;       (* arm_BCS (word 60) *)
  0xb40001c2;       (* arm_CBZ X2 (word 56) *)
  0x39400025;       (* arm_LDRB W5 X1 (Immediate_Offset (word 0)) *)
  0x39400427;       (* arm_LDRB W7 X1 (Immediate_Offset (word 1)) *)
  0x39400826;       (* arm_LDRB W6 X1 (Immediate_Offset (word 2)) *)
  0x91000c21;       (* arm_ADD X1 X1 (rvalue (word 3)) *)
  0xd1000c42;       (* arm_SUB X2 X2 (rvalue (word 3)) *)
  0x120018c6;       (* arm_AND W6 W6 (rvalue (word 127)) *)
  0x2a0720a5;       (* arm_ORR W5 W5 (Shiftedreg W7 LSL 8) *)
  0x2a0640a5;       (* arm_ORR W5 W5 (Shiftedreg W6 LSL 16) *)
  0x6b0400bf;       (* arm_CMP W5 W4 *)
  0x54fffe82;       (* arm_BCS (word 2097104) *)
  0xb8004405;       (* arm_STR W5 X0 (Postimmediate_Offset (word 4)) *)
  0x91000529;       (* arm_ADD X9 X9 (rvalue (word 1)) *)
  0x17fffff1;       (* arm_B (word 268435396) *)
  0xaa0903e0;       (* arm_MOV X0 X9 *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let MLDSA_REJ_UNIFORM_EXEC = ARM_MK_EXEC_RULE mldsa_rej_uniform_mc;;

(* ------------------------------------------------------------------------- *)
(* Code length constants                                                     *)
(* ------------------------------------------------------------------------- *)

let LENGTH_MLDSA_REJ_UNIFORM_MC =
  REWRITE_CONV[mldsa_rej_uniform_mc] `LENGTH mldsa_rej_uniform_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let VAL_MOD_23_EQ_AND = prove
 (`!w:24 word. (word(val w MOD 2 EXP 23):int32) =
               word_and (word_zx w:int32) (word 8388607)`,
  GEN_TAC THEN CONV_TAC WORD_BLAST);;


let DIMINDEX_24 = DIMINDEX_CONV `dimindex(:24)`;;
let DIMINDEX_192 = DIMINDEX_CONV `dimindex(:192)`;;
let DIMINDEX_384 = DIMINDEX_CONV `dimindex(:384)`;;

(* Count accepted coefficients in a group of four. *)
let LENGTH_FILTER_FOUR = prove
 (`!P (a:A) b c d.
     LENGTH (FILTER P [a;b;c;d]) =
     bitval(P a) + bitval(P b) + bitval(P c) + bitval(P d)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[FILTER] THEN
  REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
  ASM_REWRITE_TAC[LENGTH; bitval] THEN ARITH_TAC);;

needs "s2n_bignum/arm/proofs/consttime.ml";;

(* Helper: discharge the memsafe postcondition
     exists e2. read events s = APPEND e2 e /\ memaccess_inbounds e2 R W
   after symbolic simulation, using accumulated events from the invariant.
   This is DISCHARGE_SAFETY_PROPERTY_TAC minus the f_events unification. *)
let DISCHARGE_MEMSAFE_TAC:tactic =
  SAFE_META_EXISTS_TAC allowed_vars_e THEN
  CONJ_TAC THENL [ EXISTS_E2_TAC allowed_vars_e; ALL_TAC ] THEN
  DISCHARGE_MEMACCESS_INBOUNDS_TAC;;

(* Like SIMPLE_ARITH_TAC but allows `val` in assumptions since
   contained_modulo bounds may involve val terms. Filters out
   read/write/word simulation cruft that makes ASM_ARITH_TAC slow. *)
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

(* ASM-aware version of CONTAINED_TAC for loop-body proofs where
   memory addresses involve symbolic loop variables. Uses MEMSAFE_ARITH_TAC
   which filters assumptions to avoid the performance issues of ASM_ARITH_TAC
   with hundreds of symbolic simulation assumptions. *)
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

(* ASM-aware version of DISCHARGE_MEMSAFE_TAC for loop bodies.
   Uses MEMSAFE_ARITH_TAC for contained_modulo proofs with symbolic bounds. *)
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

(* Strip an existential assumption of the form
   `?e_acc. read events s = APPEND e_acc e /\ memaccess_inbounds ...`
   into separate assumptions. Used at ENSURES_INIT_TAC boundaries. *)
let STRIP_EXISTS_ASSUM_TAC =
  FIRST_X_ASSUM(CHOOSE_THEN
   (CONJUNCTS_THEN2 ASSUME_TAC (ASSUME_TAC)));;

(* After n candidates, the output cursor follows the accepted prefix. *)
let rej_uniform_prefix = new_definition
 `rej_uniform_prefix res buf buflen table (inlist:(24 word)list) e n s <=>
    let outlist = REJ_SAMPLE (SUB_LIST (0,n) inlist) in
    let outlen = LENGTH outlist in
    read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
    read (memory :> bytes (table,256)) s =
      num_of_wordlist mldsa_rej_uniform_table /\
    read X0 s = word_add res (word (4 * outlen)) /\
    read X1 s = word_add buf (word (3 * n)) /\
    read X2 s = word_sub (word buflen) (word (3 * n)) /\
    read X3 s = table /\ read X4 s = word 8380417 /\
    read X9 s = word outlen /\
    read (memory :> bytes (res,4 * outlen)) s = num_of_wordlist outlist /\
    (?e2. read events s = APPEND e2 e /\
          memaccess_inbounds e2 [buf,buflen; table,256] [res,1024])`;;

let rej_uniform_vectors = new_definition
 `rej_uniform_vectors s <=>
    read Q20 s = word 0x800b0a09800807068005040380020100 /\
    read Q21 s = word 0x8c1716158c1413128c11100f8c0e0d0c /\
    read Q22 s = word 0x8813121188100f0e880d0c0b880a0908 /\
    read Q23 s = word 0x840f0e0d840c0b0a8409080784060504 /\
    read Q28 s = word 0x00800000008000000080000000800000 /\
    read Q29 s = word 0x08080808040404040202020201010101 /\
    read Q30 s = word 0x007fe001007fe001007fe001007fe001 /\
    read Q31 s = word 0x00000008000000040000000200000001`;;

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
 (`!res buf buflen table (inlist:(24 word)list) pc e.
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ C_ARGUMENTS [res;buf;word buflen;table] s /\
            read (memory :> bytes (table,256)) s =
              num_of_wordlist mldsa_rej_uniform_table /\
            read (memory :> bytes (buf,buflen)) s = num_of_wordlist inlist /\
            read events s = e)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + 0x74) /\ rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e 0 s)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_vectors; rej_uniform_prefix;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS;
    LENGTH_MLDSA_REJ_UNIFORM_MC] THEN DISCH_TAC THEN
  GHOST_INTRO_TAC `q20_init:int128` `read Q20` THEN
  GHOST_INTRO_TAC `q31_init:int128` `read Q31` THEN
  ENSURES_INIT_TAC "s0" THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--29) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  REPEAT(CONJ_TAC THENL [CONV_TAC WORD_BLAST; ALL_TAC]) THEN
  REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; REJ_SAMPLE_EMPTY] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REWRITE_TAC[LENGTH] THEN
  REWRITE_TAC[MULT_CLAUSES; WORD_ADD_0; WORD_SUB_0;
    READ_COMPONENT_COMPOSE; READ_BYTES_TRIVIAL; num_of_wordlist] THEN
  EXISTS_TAC `[]:uarch_event list` THEN REWRITE_TAC[APPEND;
    memaccess_inbounds; ALL]);;

(* Both loop tests branch on the remaining input and output capacity. *)
let MLDSA_REJ_UNIFORM_TEST16 = prove
 (`!res buf buflen table (inlist:(24 word)list) e i pc first take.
     let len = LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist)) in
     buflen < 2 EXP 64 /\ 48 * i <= buflen /\ len <= 256 /\
     (take <=> 48 * i + 48 <= buflen /\ len <= 240) /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + (if first then 0x74 else 0x150)) /\
            rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e (16 * i) s)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word (pc + (if take then 0x84 else 0x158)) /\
            rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e (16 * i) s)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_vectors; rej_uniform_prefix;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
  ABBREV_TAC `len = LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist))` THEN
  SUBGOAL_THEN `val (word_sub (word buflen) (word (3 * 16 * i)):int64) =
                buflen - 48 * i` ASSUME_TAC THENL
   [REWRITE_TAC[ARITH_RULE `3 * 16 * i = 48 * i`] THEN
    SUBGOAL_THEN `48 * i < 2 EXP 64` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    MAP_EVERY VAL_INT64_TAC [`48 * i`; `buflen:num`] THEN
    ASM_REWRITE_TAC[VAL_WORD_SUB_CASES]; ALL_TAC] THEN
  VAL_INT64_TAC `len:num` THEN VAL_INT64_TAC `240` THEN
  SUBGOAL_THEN `(240 <= len /\ ~(val(word_sub (word len) (word 240):int64) = 0))
                <=> ~(len <= 240)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(48 <= buflen - 48 * i <=> 48 * i + 48 <= buflen)`
    ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ASM_CASES_TAC `first:bool` THEN (ASM_REWRITE_TAC[] THEN
  ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
  ASM_CASES_TAC `48 * i + 48 <= buflen` THENL
   [ASM_CASES_TAC `len <= 240` THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--4);
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--2)] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[GSYM NOT_LE] THEN
  DISCHARGE_MEMSAFE_ASM_TAC));;

let MLDSA_REJ_UNIFORM_TEST8 = prove
 (`!res buf buflen table (inlist:(24 word)list) e i pc.
     let len = LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist)) in
     buflen < 2 EXP 64 /\ 48 * i <= buflen /\ len <= 256 /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word(pc + 0x158) /\ rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e (16 * i) s)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word(pc + (if 48 * i + 24 <= buflen then
              if len <= 248 then 0x168 else 0x1e4 else 0x224)) /\
            rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e (16 * i) s)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_vectors; rej_uniform_prefix;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
  ABBREV_TAC `len = LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist))` THEN
  SUBGOAL_THEN `val (word_sub (word buflen) (word (3 * 16 * i)):int64) =
                buflen - 48 * i` ASSUME_TAC THENL
   [REWRITE_TAC[ARITH_RULE `3 * 16 * i = 48 * i`] THEN
    SUBGOAL_THEN `48 * i < 2 EXP 64` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    MAP_EVERY VAL_INT64_TAC [`48 * i`; `buflen:num`] THEN
    ASM_REWRITE_TAC[VAL_WORD_SUB_CASES]; ALL_TAC] THEN
  VAL_INT64_TAC `len:num` THEN VAL_INT64_TAC `248` THEN
  SUBGOAL_THEN `(248 <= len /\ ~(val(word_sub (word len) (word 248):int64) = 0))
                <=> ~(len <= 248)` ASSUME_TAC THENL
   [ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `(24 <= buflen - 48 * i <=> 48 * i + 24 <= buflen)`
    ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
  ASM_CASES_TAC `48 * i + 24 <= buflen` THENL
   [ASM_CASES_TAC `len <= 248` THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--4);
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--2)] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[GSYM NOT_LE] THEN
  DISCHARGE_MEMSAFE_ASM_TAC);;

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

let REJ_UNIFORM_BLOCK_COUNT = prove
 (`!buflen (inlist:(24 word)list).
     ?N. 48 * N <= buflen /\
         LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * N) inlist)) <= 256 /\
         ~(48 * N + 48 <= buflen /\
           LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * N) inlist)) <= 240) /\
         (!i. i < N ==> 48 * i + 48 <= buflen /\
             LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist)) <= 240)`,
  REPEAT GEN_TAC THEN SUBGOAL_THEN
   `?i. ~(48 * i + 48 <= buflen /\
          LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist)) <= 240)` MP_TAC THENL
   [EXISTS_TAC `buflen:num` THEN ARITH_TAC;
    GEN_REWRITE_TAC LAND_CONV [num_WOP] THEN REWRITE_TAC[NOT_CLAUSES]] THEN
  DISCH_THEN(X_CHOOSE_THEN `N:num` STRIP_ASSUME_TAC) THEN
  EXISTS_TAC `N:num` THEN ASM_REWRITE_TAC[] THEN
  ASM_CASES_TAC `N = 0` THENL
   [ASM_REWRITE_TAC[MULT_CLAUSES; SUB_LIST_CLAUSES; REJ_SAMPLE_EMPTY;
                    LENGTH; LE_0] THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o SPEC `N - 1`) THEN
    ASM_SIMP_TAC[ARITH_RULE `~(N = 0) ==> N - 1 < N`] THEN STRIP_TAC THEN
    MP_TAC(SPECL [`inlist:(24 word)list`; `16 * (N - 1)`; `16`]
      REJ_UNIFORM_LENGTH_STEP) THEN
    ASM_SIMP_TAC[ARITH_RULE `~(N = 0) ==> 16 * (N - 1) + 16 = 16 * N`] THEN
    ASM_ARITH_TAC]);;

let MLDSA_REJ_UNIFORM_BLOCK16 = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e i.
     buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
     48 * i + 48 <= buflen /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,16 * i) inlist)) <= 240 /\
     ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,buflen); (table,256)]
     ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x84) /\ rej_uniform_vectors s /\
                rej_uniform_prefix res buf buflen table inlist e (16 * i) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x150) /\ rej_uniform_vectors s /\
                rej_uniform_prefix res buf buflen table inlist e (16 * (i + 1)) s)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ALL; NONOVERLAPPING_CLAUSES;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC;
    rej_uniform_vectors; rej_uniform_prefix] THEN STRIP_TAC THEN
  ABBREV_TAC `cur:int64 = word_add buf (word (48 * i))` THEN
  ABBREV_TAC `curlist = REJ_SAMPLE (SUB_LIST(0,16 * i) inlist)` THEN
  ABBREV_TAC `curlen = LENGTH(curlist:int32 list)` THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(TOP_DEPTH_CONV let_CONV))) THEN
  ASM_REWRITE_TAC[ARITH_RULE `3 * 16 * n = 48 * n`] THEN
  ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
  MAP_EVERY ABBREV_TAC
   [`q0 = read (memory :> bytes128 cur) s0`;
    `q1 = read (memory :> bytes128 (word_add cur (word 16))) s0`;
    `q2 = read (memory :> bytes128 (word_add cur (word 32))) s0`] THEN

  (*** Abbreviate the 16 coefficients as 32-bit words ***)

  ABBREV_TAC
   `(x:num->int32) j =
    word_and (word_zx(word_subword
      (read (memory :> wbytes cur) s0:384 word)
      (24 * j,24):24 word):int32) (word 8388607)` THEN

  (*** Steps 1-10: LD1 + TBL + BIC byte extraction ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--10) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN

  (*** Prove Q16-Q19 contain the correct coefficients ***)

  SUBGOAL_THEN
   `read Q16 s10 =
        word_join (word_join ((x:num->int32) 3) (x 2):int64)
                  (word_join (x 1) (x 0):int64) /\
    read Q17 s10 =
        word_join (word_join ((x:num->int32) 7) (x 6):int64)
                  (word_join (x 5) (x 4):int64) /\
    read Q18 s10 =
        word_join (word_join ((x:num->int32) 11) (x 10):int64)
                  (word_join (x 9) (x 8):int64) /\
    read Q19 s10 =
        word_join (word_join ((x:num->int32) 15) (x 14):int64)
                  (word_join (x 13) (x 12):int64)`
  MP_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o check (is_forall o concl)) THEN
    DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN
    ASM_REWRITE_TAC[READ_MEMORY_TRIPLES_SPLIT] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    CONV_TAC WORD_BLAST;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q16 s = x`; `read Q17 s = x`;
      `read Q18 s = x`; `read Q19 s = x`] THEN
    STRIP_TAC] THEN

  (*** Connect x to EL of SUB_LIST (needed for postcondition) ***)

  SUBGOAL_THEN
   `!j. j < 16
        ==> EL j (MAP (\x:24 word. word(val x MOD 2 EXP 23):int32)
                  (SUB_LIST(16 * i,16) inlist)) = (x:num->int32) j`
  ASSUME_TAC THENL
   [UNDISCH_THEN
     `read (memory :> bytes (buf,buflen)) s10 =
      num_of_wordlist(inlist:(24 word)list)`
     (MP_TAC o AP_TERM
       `\x. x DIV 2 EXP (8 * 48 * i) MOD 2 EXP (8 * 48)`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_DIV] THEN
    REWRITE_TAC[READ_BYTES_MOD] THEN
    REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
    REWRITE_TAC[ARITH_RULE `8 * 48 = 24 * 16 * 1`] THEN
    REWRITE_TAC[ARITH_RULE `8 * 48 * x = 24 * 16 * x`] THEN
    REWRITE_TAC[GSYM DIMINDEX_24; GSYM NUM_OF_WORDLIST_SUB_LIST] THEN
    SUBGOAL_THEN
     `MIN (buflen - 48 * i) 48 = dimindex(:384) DIV 8`
    SUBST1_TAC THENL
     [REWRITE_TAC[DIMINDEX_384] THEN CONV_TAC NUM_REDUCE_CONV THEN
      MATCH_MP_TAC(ARITH_RULE
       `48 * i + 48 <= b ==> MIN (b - 48 * i) 48 = 48`) THEN
      ASM_REWRITE_TAC[];
      REWRITE_TAC[MULT_CLAUSES] THEN ASM_REWRITE_TAC[] THEN
      REWRITE_TAC[READ_COMPONENT_COMPOSE; GSYM VAL_READ_WBYTES] THEN
      ASM_REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE]] THEN
    DISCH_TAC THEN X_GEN_TAC `j:num` THEN DISCH_TAC THEN
    SUBGOAL_THEN
     `j < LENGTH(SUB_LIST(16 * i,16) (inlist:(24 word)list))`
    ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_SUB_LIST] THEN
      MAP_EVERY UNDISCH_TAC
       [`j:num < 16`; `48 * i + 48 <= buflen`;
        `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN
      ARITH_TAC;
      ALL_TAC] THEN
    ASM_SIMP_TAC[EL_MAP] THEN REWRITE_TAC[VAL_MOD_23_EQ_AND] THEN
    FIRST_X_ASSUM(fun th ->
      GEN_REWRITE_TAC RAND_CONV [SYM(SPEC `j:num` th)]) THEN
    AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
    REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; DIMINDEX_24;
                ARITH_RULE `MIN 24 24 = 24`] THEN
    ASM_REWRITE_TAC[GSYM DIMINDEX_24; NUM_OF_WORDLIST_EL;
                    LENGTH_SUB_LIST] THEN
    COND_CASES_TAC THENL [REFL_TAC; ASM_MESON_TAC[]];
    ALL_TAC] THEN

  (*** Steps 11-24: CMHI + TRN1 + AND + UADDLV + FMOV + UBFX ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (11--24) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE
   [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN

  (*** Each byte sums to at most 15, so the packed indices do not carry. ***)

  SUBGOAL_THEN
   `read X12 s24 =
      word_add (word_add (if val ((x:num->int32) 0) < 8380417 then word 1 else word 0)
                         (if val (x 1) < 8380417 then word 2 else word 0))
               (word_add (if val (x 2) < 8380417 then word 4 else word 0)
                         (if val (x 3) < 8380417 then word 8 else word 0)) /\
    read X13 s24 =
      word_add (word_add (if val ((x:num->int32) 4) < 8380417 then word 1 else word 0)
                         (if val (x 5) < 8380417 then word 2 else word 0))
               (word_add (if val (x 6) < 8380417 then word 4 else word 0)
                         (if val (x 7) < 8380417 then word 8 else word 0)) /\
    read X14 s24 =
      word_add (word_add (if val ((x:num->int32) 8) < 8380417 then word 1 else word 0)
                         (if val (x 9) < 8380417 then word 2 else word 0))
               (word_add (if val (x 10) < 8380417 then word 4 else word 0)
                         (if val (x 11) < 8380417 then word 8 else word 0)) /\
    read X15 s24 =
      word_add (word_add (if val ((x:num->int32) 12) < 8380417 then word 1 else word 0)
                         (if val (x 13) < 8380417 then word 2 else word 0))
               (word_add (if val (x 14) < 8380417 then word 4 else word 0)
                         (if val (x 15) < 8380417 then word 8 else word 0))`
  MP_TAC THENL
   [ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THEN CONV_TAC BITBLAST_RULE;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read X12 s = x`; `read X13 s = x`;
      `read X14 s = x`; `read X15 s = x`] THEN
    STRIP_TAC] THEN

  (*** Abbreviate table indices and entries ***)

  MAP_EVERY REABBREV_TAC
   [`idx0 = read X12 s24`; `idx1 = read X13 s24`;
    `idx2 = read X14 s24`; `idx3 = read X15 s24`] THEN
  MAP_EVERY ABBREV_TAC
   [`tab0 = read(memory :> bytes128(word_add table
                (word(16 * val(idx0:int64))))) s24`;
    `tab1 = read(memory :> bytes128(word_add table
                (word(16 * val(idx1:int64))))) s24`;
    `tab2 = read(memory :> bytes128(word_add table
                (word(16 * val(idx2:int64))))) s24`;
    `tab3 = read(memory :> bytes128(word_add table
                (word(16 * val(idx3:int64))))) s24`] THEN

  (*** Steps 25-39: table loads + packed counts + TBL ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (25--39) THEN

  (* Normalize shifted-register table addresses for event containment *)
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_RULE
    `word_shl (x:int64) 4 = word(16 * val x)`]) THEN

  RULE_ASSUM_TAC(REWRITE_RULE[WORD_SUBWORD_AND]) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE
   [word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN

  (*** TBL correctness: Q16-Q19 = word(num_of_wordlist(FILTER ...)) ***)

  SUBGOAL_THEN
   `read Q16 s39 = word(num_of_wordlist (FILTER (\x:int32. val x < 8380417)
                     [(x:num->int32) 0; x 1; x 2; x 3])) /\
    read Q17 s39 = word(num_of_wordlist (FILTER (\x. val x < 8380417)
                     [x 4; x 5; x 6; x 7])) /\
    read Q18 s39 = word(num_of_wordlist (FILTER (\x. val x < 8380417)
                     [x 8; x 9; x 10; x 11])) /\
    read Q19 s39 = word(num_of_wordlist (FILTER (\x. val x < 8380417)
                     [x 12; x 13; x 14; x 15]))`
  MP_TAC THENL
   [UNDISCH_TAC
     `read(memory :> bytes(table,256)) s39 =
      num_of_wordlist mldsa_rej_uniform_table` THEN
    REPLICATE_TAC 4
     (GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
           [GSYM NUM_OF_PAIR_WORDLIST]) THEN
    REWRITE_TAC[mldsa_rej_uniform_table; pair_wordlist] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    CONV_TAC(LAND_CONV BYTES_EQ_NUM_OF_WORDLIST_EXPAND_CONV) THEN
    REWRITE_TAC[GSYM BYTES128_WBYTES] THEN REPEAT STRIP_TAC THEN
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q24 s = x`; `read Q25 s = x`;
      `read Q26 s = x`; `read Q27 s = x`] THEN
    REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
      (fun th -> is_var(rhs(concl th)) &&
                 let n = fst(dest_var(rhs(concl th))) in
                 n = "tab0" || n = "tab1" || n = "tab2" || n = "tab3"))) THEN
    DISCARD_MATCHING_ASSUMPTIONS
     [`read X12 s = x`; `read X13 s = x`;
      `read X14 s = x`; `read X15 s = x`] THEN
    REPEAT(FIRST_X_ASSUM(SUBST_ALL_TAC o SYM o check
      (fun th -> is_var(rhs(concl th)) &&
                 let n = fst(dest_var(rhs(concl th))) in
                 n = "idx0" || n = "idx1" || n = "idx2" || n = "idx3"))) THEN
    ASM_REWRITE_TAC[] THEN
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q16 s = x`; `read Q17 s = x`;
      `read Q18 s = x`; `read Q19 s = x`] THEN
    ASM_REWRITE_TAC[FILTER] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    ASM_REWRITE_TAC[bitval] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    ASM_REWRITE_TAC[WORD_ADD_0] THEN
    CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    REPLICATE_TAC 2
     (ONCE_REWRITE_TAC[GSYM NUM_OF_PAIR_WORDLIST]) THEN
    REWRITE_TAC[pair_wordlist; NUM_OF_WORDLIST_SING; WORD_VAL] THEN
    REWRITE_TAC[num_of_wordlist] THEN CONV_TAC WORD_BLAST;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q16 s = x`; `read Q17 s = x`;
      `read Q18 s = x`; `read Q19 s = x`] THEN
    STRIP_TAC] THEN

  (*** Counting: X12-X15 = word(LENGTH(FILTER ...)) ***)

  SUBGOAL_THEN
   `read X12 s39 = word(LENGTH (FILTER (\x:int32. val x < 8380417)
                     [(x:num->int32) 0; x 1; x 2; x 3])) /\
    read X13 s39 = word(LENGTH (FILTER (\x. val x < 8380417)
                     [x 4; x 5; x 6; x 7])) /\
    read X14 s39 = word(LENGTH (FILTER (\x. val x < 8380417)
                     [x 8; x 9; x 10; x 11])) /\
    read X15 s39 = word(LENGTH (FILTER (\x. val x < 8380417)
                     [x 12; x 13; x 14; x 15]))`
  MP_TAC THENL
   [ASM_REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; BITBLAST_RULE
     `word_popcount(word_and (word 1) x:byte) = bitval(bit 0 x) /\
      word_popcount(word_and (word 2) x:byte) = bitval(bit 1 x) /\
      word_popcount(word_and (word 4) x:byte) = bitval(bit 2 x) /\
      word_popcount(word_and (word 8) x:byte) = bitval(bit 3 x) /\
      word_popcount(word_and (word 16) x:byte) = bitval(bit 4 x) /\
      word_popcount(word_and (word 32) x:byte) = bitval(bit 5 x) /\
      word_popcount(word_and (word 64) x:byte) = bitval(bit 6 x) /\
      word_popcount(word_and (word 128) x:byte) = bitval(bit 7 x)`] THEN
    DISCARD_STATE_TAC "s39" THEN REPEAT CONJ_TAC THEN
    REWRITE_TAC[BIT_WORD_MASK; DIMINDEX_8; LENGTH_FILTER_FOUR;
                GSYM WORD_ADD] THEN
    CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC BITBLAST_RULE;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read X12 s = x`; `read X13 s = x`;
      `read X14 s = x`; `read X15 s = x`] THEN
    STRIP_TAC] THEN

  (*** Abbreviate filtered lists and their lengths ***)

  MAP_EVERY ABBREV_TAC
   [`lis0 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 0; x 1; x 2; x 3]`;
    `lis1 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 4; x 5; x 6; x 7]`;
    `lis2 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 8; x 9; x 10; x 11]`;
    `lis3 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 12; x 13; x 14; x 15]`;
    `len0 = LENGTH(lis0:int32 list)`;
    `len1 = LENGTH(lis1:int32 list)`;
    `len2 = LENGTH(lis2:int32 list)`;
    `len3 = LENGTH(lis3:int32 list)`] THEN

  SUBGOAL_THEN `len0 <= 4 /\ len1 <= 4 /\ len2 <= 4 /\ len3 <= 4`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["len0"; "len1"; "len2"; "len3"] THEN
    MAP_EVERY EXPAND_TAC ["lis0"; "lis1"; "lis2"; "lis3"] THEN
    REPEAT CONJ_TAC THEN
    W(MP_TAC o PART_MATCH lhand LENGTH_FILTER o lhand o snd) THEN
    REWRITE_TAC[LENGTH] THEN ARITH_TAC;
    ALL_TAC] THEN

  (*** First output store: ST1 Q16 + ADD X0 ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (40--41) THEN
  ABBREV_TAC `curlist1:int32 list = APPEND curlist lis0` THEN
  ABBREV_TAC `curlen1:num = curlen + len0` THEN

  SUBGOAL_THEN
   `curlen1 <= 244 /\
    read (memory :> bytes (res,4*curlen1)) s41 =
    num_of_wordlist(curlist1:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen1"; "curlist1"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen <= 240`; `len0 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen)))) s41 =
      word (num_of_wordlist(lis0:int32 list))`
    MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len0 = MIN 16 (4 * len0)` SUBST1_TAC THENL
     [UNDISCH_TAC `len0 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len0 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist1:int32 list) = curlen1` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist1"; "curlen1"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** Second output store ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (42--43) THEN
  ABBREV_TAC `curlist2:int32 list = APPEND curlist1 lis1` THEN
  ABBREV_TAC `curlen2:num = curlen1 + len1` THEN
  SUBGOAL_THEN
   `curlen2 <= 248 /\
    read (memory :> bytes (res,4*curlen2)) s43 =
    num_of_wordlist(curlist2:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen2"; "curlist2"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen1 <= 244`; `len1 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    UNDISCH_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen1)))) s43 =
      word (num_of_wordlist(lis1:int32 list))`
     (MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len1 = MIN 16 (4 * len1)` SUBST1_TAC THENL
     [UNDISCH_TAC `len1 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len1 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist2:int32 list) = curlen2` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist2"; "curlen2"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** Third output store ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (44--45) THEN
  ABBREV_TAC `curlist3:int32 list = APPEND curlist2 lis2` THEN
  ABBREV_TAC `curlen3:num = curlen2 + len2` THEN
  SUBGOAL_THEN
   `curlen3 <= 252 /\
    read (memory :> bytes (res,4*curlen3)) s45 =
    num_of_wordlist(curlist3:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen3"; "curlist3"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen2 <= 248`; `len2 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    UNDISCH_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen2)))) s45 =
      word (num_of_wordlist(lis2:int32 list))`
     (MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len2 = MIN 16 (4 * len2)` SUBST1_TAC THENL
     [UNDISCH_TAC `len2 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len2 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist3:int32 list) = curlen3` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist3"; "curlen3"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** Fourth output store ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (46--47) THEN
  ABBREV_TAC `curlist4:int32 list = APPEND curlist3 lis3` THEN
  ABBREV_TAC `curlen4:num = curlen3 + len3` THEN
  SUBGOAL_THEN
   `curlen4 <= 256 /\
    read (memory :> bytes (res,4*curlen4)) s47 =
    num_of_wordlist(curlist4:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen4"; "curlist4"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen3 <= 252`; `len3 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    UNDISCH_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen3)))) s47 =
      word (num_of_wordlist(lis3:int32 list))`
     (MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len3 = MIN 16 (4 * len3)` SUBST1_TAC THENL
     [UNDISCH_TAC `len3 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len3 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist4:int32 list) = curlen4` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist4"; "curlen4"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** The end of the loop body: 4 ADDs accumulating counts ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (48--51) THEN

  (* Normalize store event addresses: word_shl from ADD Xn, Xn, Xm LSL #2 *)
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_RULE
    `word_add (word_add a (word(4 * n))) (word_shl (word m) 2):int64 =
     word_add a (word(4 * (n + m)))`]) THEN

    SUBGOAL_THEN `val(idx0:int64) < 16` ASSUME_TAC THENL
     [EXPAND_TAC "idx0" THEN
      REWRITE_TAC[bitval] THEN
      REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
      CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
      CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
    SUBGOAL_THEN `val(idx1:int64) < 16` ASSUME_TAC THENL
     [EXPAND_TAC "idx1" THEN
      REWRITE_TAC[bitval] THEN
      REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
      CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
      CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
    SUBGOAL_THEN `val(idx2:int64) < 16` ASSUME_TAC THENL
     [EXPAND_TAC "idx2" THEN
      REWRITE_TAC[bitval] THEN
      REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
      CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
      CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
    SUBGOAL_THEN `val(idx3:int64) < 16` ASSUME_TAC THENL
     [EXPAND_TAC "idx3" THEN
      REWRITE_TAC[bitval] THEN
      REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
      CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
      CONV_TAC NUM_REDUCE_CONV;
      ALL_TAC] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN

  REWRITE_TAC[ARITH_RULE `16 * (i + 1) = 16 * i + 16`] THEN
  ASM_REWRITE_TAC[SUB_LIST_SPLIT; REJ_SAMPLE_APPEND; ADD_CLAUSES] THEN
  SUBGOAL_THEN
   `REJ_SAMPLE (SUB_LIST (16 * i,16) inlist) =
    APPEND (APPEND (APPEND lis0 lis1) lis2) lis3`
  SUBST1_TAC THENL
   [MAP_EVERY EXPAND_TAC ["lis0"; "lis1"; "lis2"; "lis3"] THEN
    REWRITE_TAC[GSYM APPEND_ASSOC; GSYM FILTER_APPEND] THEN
    REWRITE_TAC[APPEND; REJ_SAMPLE] THEN AP_TERM_TAC THEN
    REWRITE_TAC[LIST_EQ] THEN CONV_TAC(ONCE_DEPTH_CONV LENGTH_CONV) THEN
    REWRITE_TAC[LENGTH_MAP] THEN
    MATCH_MP_TAC(TAUT `p /\ (p ==> q) ==> p /\ q`) THEN CONJ_TAC THENL
     [REWRITE_TAC[LENGTH_SUB_LIST] THEN MATCH_MP_TAC(ARITH_RULE
       `16 * (i + 1) <= l ==> MIN 16 (l - 16 * i) = 16`) THEN
      MAP_EVERY UNDISCH_TAC
       [`48 * i + 48 <= buflen`;
        `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN
      ARITH_TAC;
      ASM_SIMP_TAC[EL_MAP] THEN DISCH_THEN(K ALL_TAC) THEN
      CONV_TAC EXPAND_CASES_CONV THEN
      CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REWRITE_TAC[]];
    ASM_REWRITE_TAC[APPEND_ASSOC] THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV)] THEN
  ASM_REWRITE_TAC[] THEN EXPAND_TAC "cur" THEN
  REWRITE_TAC[ARITH_RULE `3 * (16 * i + 16) = 48 * i + 48`] THEN
  REPEAT(CONJ_TAC THENL [CONV_TAC WORD_RULE; ALL_TAC]) THEN
  CONJ_TAC THENL
   [SUBST1_TAC(SYM(ASSUME `curlen3 + len3:num = curlen4`)) THEN
    SUBST1_TAC(SYM(ASSUME `curlen2 + len2:num = curlen3`)) THEN
    SUBST1_TAC(SYM(ASSUME `curlen1 + len1:num = curlen2`)) THEN
    SUBST1_TAC(SYM(ASSUME `curlen + len0:num = curlen1`)) THEN
    CONV_TAC WORD_RULE;
    DISCHARGE_MEMSAFE_ASM_TAC]);;

let MLDSA_REJ_UNIFORM_BLOCK8 = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e N.
     buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
     48 * N + 24 <= buflen /\
     LENGTH (REJ_SAMPLE (SUB_LIST (0,16 * N) inlist)) <= 248 /\
     ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,buflen); (table,256)]
     ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x168) /\ rej_uniform_vectors s /\
                rej_uniform_prefix res buf buflen table inlist e (16 * N) s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x1e4) /\ rej_uniform_vectors s /\
                rej_uniform_prefix res buf buflen table inlist e (16 * N + 8) s)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ALL; NONOVERLAPPING_CLAUSES;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC;
    rej_uniform_vectors; rej_uniform_prefix] THEN STRIP_TAC THEN
  ABBREV_TAC `cur:int64 = word_add buf (word (48 * N))` THEN
  ABBREV_TAC `curlist = REJ_SAMPLE (SUB_LIST(0,16 * N) inlist)` THEN
  ABBREV_TAC `curlen = LENGTH(curlist:int32 list)` THEN
  CONV_TAC(RATOR_CONV(LAND_CONV(TOP_DEPTH_CONV let_CONV))) THEN
  ASM_REWRITE_TAC[ARITH_RULE `3 * 16 * n = 48 * n`] THEN
  ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
  MAP_EVERY ABBREV_TAC
   [`q0 = read (memory :> bytes64 cur) s0`;
    `q1 = read (memory :> bytes64 (word_add cur (word 8))) s0`;
    `q2 = read (memory :> bytes64 (word_add cur (word 16))) s0`] THEN

  ABBREV_TAC
   `(x:num->int32) j =
    word_and (word_zx(word_subword
      (read (memory :> wbytes cur) s0:192 word)
      (24 * j,24):24 word):int32) (word 8388607)` THEN

  SUBGOAL_THEN
   `read (memory :> bytes128 cur) s0 = word_join (q1:int64) (q0:int64)`
  ASSUME_TAC THENL
   [CONV_TAC(LAND_CONV(READ_MEMORY_MERGE_CONV 1)) THEN
    ASM_REWRITE_TAC[WORD_ADD_0];
    ALL_TAC] THEN

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--7) THEN

  SUBGOAL_THEN
   `read Q16 s7 =
        word_join (word_join ((x:num->int32) 3) (x 2):int64)
                  (word_join (x 1) (x 0):int64) /\
    read Q17 s7 =
        word_join (word_join ((x:num->int32) 7) (x 6):int64)
                  (word_join (x 5) (x 4):int64)`
  MP_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o check (is_forall o concl)) THEN
    DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN
    ASM_REWRITE_TAC[READ_MEMORY_TRIPLES_SPLIT] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    CONV_TAC WORD_BLAST;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q16 s = x`; `read Q17 s = x`] THEN
    STRIP_TAC] THEN

  SUBGOAL_THEN
   `!j. j < 8
        ==> EL j (MAP (\w:24 word. word(val w MOD 2 EXP 23):int32)
                  (SUB_LIST(16 * N,8) inlist)) = (x:num->int32) j`
  ASSUME_TAC THENL
   [UNDISCH_THEN
     `read (memory :> bytes (buf,buflen)) s7 =
      num_of_wordlist(inlist:(24 word)list)`
     (MP_TAC o AP_TERM
       `\n:num. n DIV 2 EXP (8 * 48 * N) MOD 2 EXP (8 * 24)`) THEN
    CONV_TAC(DEPTH_CONV BETA_CONV) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_BYTES_DIV; READ_BYTES_MOD] THEN
    REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE] THEN
    REWRITE_TAC[ARITH_RULE `8 * 24 = 24 * 8 * 1`;
                ARITH_RULE `8 * 48 * n = 24 * 16 * n`] THEN
    REWRITE_TAC[GSYM DIMINDEX_24; GSYM NUM_OF_WORDLIST_SUB_LIST] THEN
    SUBGOAL_THEN `MIN (buflen - 48 * N) (dimindex(:24)) = dimindex(:192) DIV 8`
    SUBST1_TAC THENL
     [REWRITE_TAC[DIMINDEX_24; DIMINDEX_192] THEN
      UNDISCH_TAC `48 * N + 24 <= buflen` THEN ARITH_TAC;
      REWRITE_TAC[MULT_CLAUSES] THEN ASM_REWRITE_TAC[] THEN
      REWRITE_TAC[READ_COMPONENT_COMPOSE; GSYM VAL_READ_WBYTES] THEN
      ASM_REWRITE_TAC[GSYM READ_COMPONENT_COMPOSE]] THEN
    DISCH_TAC THEN X_GEN_TAC `j:num` THEN DISCH_TAC THEN
    SUBGOAL_THEN `j < LENGTH(SUB_LIST(16 * N,8) (inlist:(24 word)list))`
    ASSUME_TAC THENL
     [REWRITE_TAC[LENGTH_SUB_LIST] THEN
      MAP_EVERY UNDISCH_TAC [`j:num < 8`; `48 * N + 24 <= buflen`;
        `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN
      ARITH_TAC; ALL_TAC] THEN
    ASM_SIMP_TAC[EL_MAP] THEN REWRITE_TAC[VAL_MOD_23_EQ_AND] THEN
    FIRST_X_ASSUM(fun th ->
      GEN_REWRITE_TAC RAND_CONV [SYM(SPEC `j:num` th)]) THEN
    AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
    REWRITE_TAC[GSYM VAL_EQ; VAL_WORD_SUBWORD; DIMINDEX_24;
                ARITH_RULE `MIN 24 24 = 24`] THEN
    ASM_REWRITE_TAC[GSYM DIMINDEX_24; NUM_OF_WORDLIST_EL;
                    LENGTH_SUB_LIST] THEN
    COND_CASES_TAC THENL [REFL_TAC; ASM_MESON_TAC[]]; ALL_TAC] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (8--15) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  MAP_EVERY REABBREV_TAC
   [`idx0 = read X12 s15`; `idx1 = read X13 s15`] THEN
  MAP_EVERY ABBREV_TAC
   [`tab0 = read(memory :> bytes128(word_add table
                (word(16 * val(idx0:int64))))) s15`;
    `tab1 = read(memory :> bytes128(word_add table
                (word(16 * val(idx1:int64))))) s15`] THEN

  (*** Steps 16-23: LDR Q24/Q25 + CNT + UADDLV + FMOV ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (16--23) THEN

  (* Normalize shifted-register table addresses for event containment *)
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_RULE
    `word_shl (x:int64) 4 = word(16 * val x)`]) THEN

  RULE_ASSUM_TAC(REWRITE_RULE[WORD_SUBWORD_AND]) THEN
  RULE_ASSUM_TAC(CONV_RULE(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV)) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[word_ugt; relational2; GT; WORD_AND_MASK]) THEN
  RULE_ASSUM_TAC(ONCE_REWRITE_RULE[COND_RAND]) THEN
  RULE_ASSUM_TAC(CONV_RULE WORD_REDUCE_CONV) THEN

  (*** Steps 24-25: TBL Q16/Q17 ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (24--25) THEN

  (*** TBL correctness: Q16/Q17 = word(num_of_wordlist(FILTER ...)) ***)

  SUBGOAL_THEN
   `read Q16 s25 = word(num_of_wordlist (FILTER (\x:int32. val x < 8380417)
                         [(x:num->int32) 0; x 1; x 2; x 3])) /\
    read Q17 s25 = word(num_of_wordlist (FILTER (\x. val x < 8380417)
                         [x 4; x 5; x 6; x 7]))`
  MP_TAC THENL
   [UNDISCH_TAC
     `read(memory :> bytes(table,256)) s25 =
      num_of_wordlist mldsa_rej_uniform_table` THEN
    REPLICATE_TAC 4
     (GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
           [GSYM NUM_OF_PAIR_WORDLIST]) THEN
    REWRITE_TAC[mldsa_rej_uniform_table; pair_wordlist] THEN
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
    ASM_REWRITE_TAC[FILTER] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    ASM_REWRITE_TAC[bitval] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    ASM_REWRITE_TAC[WORD_ADD_0] THEN
    CONV_TAC(TOP_DEPTH_CONV WORD_SIMPLE_SUBWORD_CONV) THEN
    CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    REPLICATE_TAC 2
     (ONCE_REWRITE_TAC[GSYM NUM_OF_PAIR_WORDLIST]) THEN
    REWRITE_TAC[pair_wordlist; NUM_OF_WORDLIST_SING; WORD_VAL] THEN
    REWRITE_TAC[num_of_wordlist] THEN CONV_TAC WORD_BLAST;
    DISCARD_MATCHING_ASSUMPTIONS
     [`read Q16 s = x`; `read Q17 s = x`] THEN
    STRIP_TAC] THEN

  (*** Counting: X12/X13 = word(LENGTH(FILTER ...)) ***)

  SUBGOAL_THEN
   `read X12 s25 = word(LENGTH (FILTER (\x:int32. val x < 8380417)
                         [(x:num->int32) 0; x 1; x 2; x 3])) /\
    read X13 s25 = word(LENGTH (FILTER (\x. val x < 8380417)
                         [x 4; x 5; x 6; x 7]))`
  MP_TAC THENL
   [ASM_REWRITE_TAC[WORD_AND_0; WORD_POPCOUNT_0; BITBLAST_RULE
     `word_popcount(word_and (word 1) x:byte) = bitval(bit 0 x) /\
      word_popcount(word_and (word 2) x:byte) = bitval(bit 1 x) /\
      word_popcount(word_and (word 4) x:byte) = bitval(bit 2 x) /\
      word_popcount(word_and (word 8) x:byte) = bitval(bit 3 x) /\
      word_popcount(word_and (word 16) x:byte) = bitval(bit 4 x) /\
      word_popcount(word_and (word 32) x:byte) = bitval(bit 5 x) /\
      word_popcount(word_and (word 64) x:byte) = bitval(bit 6 x) /\
      word_popcount(word_and (word 128) x:byte) = bitval(bit 7 x)`] THEN
    DISCARD_STATE_TAC "s25" THEN REPEAT CONJ_TAC THEN
    REWRITE_TAC[WORD_MASK_ALT] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    ASM_REWRITE_TAC[FILTER] THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
    REWRITE_TAC[LENGTH] THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV);
    DISCARD_MATCHING_ASSUMPTIONS
     [`read X12 s = x`; `read X13 s = x`] THEN
    STRIP_TAC] THEN

  (*** Abbreviate filtered lists and their lengths ***)

  MAP_EVERY ABBREV_TAC
   [`lis0 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 0; x 1; x 2; x 3]`;
    `lis1 = FILTER (\x:int32. val x < 8380417)
                   [(x:num->int32) 4; x 5; x 6; x 7]`;
    `len0 = LENGTH(lis0:int32 list)`;
    `len1 = LENGTH(lis1:int32 list)`] THEN

  SUBGOAL_THEN `len0 <= 4 /\ len1 <= 4`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["len0"; "len1"] THEN
    MAP_EVERY EXPAND_TAC ["lis0"; "lis1"] THEN
    REPEAT CONJ_TAC THEN
    W(MP_TAC o PART_MATCH lhand LENGTH_FILTER o lhand o snd) THEN
    REWRITE_TAC[LENGTH] THEN ARITH_TAC;
    ALL_TAC] THEN

  (*** First output store: STR Q16 + ADD X0 ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (26--27) THEN
  ABBREV_TAC `curlist1:int32 list = APPEND curlist lis0` THEN
  ABBREV_TAC `curlen1:num = curlen + len0` THEN

  SUBGOAL_THEN
   `curlen1 <= 252 /\
    read (memory :> bytes (res,4*curlen1)) s27 =
    num_of_wordlist(curlist1:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen1"; "curlist1"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen <= 248`; `len0 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen)))) s27 =
      word (num_of_wordlist(lis0:int32 list))`
    MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len0 = MIN 16 (4 * len0)` SUBST1_TAC THENL
     [UNDISCH_TAC `len0 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len0 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist1:int32 list) = curlen1` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist1"; "curlen1"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** Second output store: STR Q17 + ADD X0 ***)

  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (28--29) THEN
  ABBREV_TAC `curlist2:int32 list = APPEND curlist1 lis1` THEN
  ABBREV_TAC `curlen2:num = curlen1 + len1` THEN

  SUBGOAL_THEN
   `curlen2 <= 256 /\
    read (memory :> bytes (res,4*curlen2)) s29 =
    num_of_wordlist(curlist2:int32 list)`
  STRIP_ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlen2"; "curlist2"] THEN CONJ_TAC THENL
     [MAP_EVERY UNDISCH_TAC [`curlen1 <= 252`; `len1 <= 4`] THEN ARITH_TAC;
      REWRITE_TAC[LEFT_ADD_DISTRIB]] THEN
    W(MP_TAC o PART_MATCH (lhand o rand)
      BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * l = 32 * l`] THEN
    DISCH_THEN SUBST1_TAC THEN
    SUBGOAL_THEN
     `read (memory :> bytes128
            (word_add res (word (4 * curlen1)))) s29 =
      word (num_of_wordlist(lis1:int32 list))`
    MP_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    DISCH_THEN(MP_TAC o AP_TERM `val:int128->num`) THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES128_WBYTES;
                VAL_READ_WBYTES;
                DIMINDEX_128; ARITH_RULE `128 DIV 8 = 16`] THEN
    SUBGOAL_THEN `4 * len1 = MIN 16 (4 * len1)` SUBST1_TAC THENL
     [UNDISCH_TAC `len1 <= 4` THEN ARITH_TAC;
      REWRITE_TAC[GSYM READ_BYTES_MOD]] THEN
    DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[VAL_WORD] THEN
    REWRITE_TAC[DIMINDEX_128; MOD_MOD_EXP_MIN] THEN
    MATCH_MP_TAC MOD_LT THEN
    MATCH_MP_TAC NUM_OF_WORDLIST_BOUND_GEN THEN
    ASM_REWRITE_TAC[DIMINDEX_32] THEN
    UNDISCH_TAC `len1 <= 4` THEN ARITH_TAC;
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE RAND_CONV
      [WORD_RULE `word_add (word_add a (word (4 * l0)))
                           (word_shl (word l1) 2) =
                  word_add a (word(4 * (l0 + l1)))`]) THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC] THEN
  SUBGOAL_THEN `LENGTH(curlist2:int32 list) = curlen2` ASSUME_TAC THENL
   [MAP_EVERY EXPAND_TAC ["curlist2"; "curlen2"] THEN
    REWRITE_TAC[LENGTH_APPEND] THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN

  (*** REJ_SAMPLE connection ***)

  SUBGOAL_THEN
   `REJ_SAMPLE (SUB_LIST (0,16 * N + 8) inlist) = curlist2:int32 list`
  ASSUME_TAC THENL
   [ASM_REWRITE_TAC[SUB_LIST_SPLIT; REJ_SAMPLE_APPEND; ADD_CLAUSES] THEN
    SUBGOAL_THEN
     `REJ_SAMPLE (SUB_LIST (16 * N,8) inlist) = APPEND lis0 lis1`
    SUBST1_TAC THENL
     [MAP_EVERY EXPAND_TAC ["lis0"; "lis1"] THEN
      REWRITE_TAC[GSYM FILTER_APPEND; APPEND; REJ_SAMPLE] THEN
      AP_TERM_TAC THEN
      REWRITE_TAC[LIST_EQ] THEN CONV_TAC(ONCE_DEPTH_CONV LENGTH_CONV) THEN
      REWRITE_TAC[LENGTH_MAP] THEN
      MATCH_MP_TAC(TAUT `p /\ (p ==> q) ==> p /\ q`) THEN CONJ_TAC THENL
       [REWRITE_TAC[LENGTH_SUB_LIST] THEN MATCH_MP_TAC(ARITH_RULE
         `16 * N + 8 <= l ==> MIN 8 (l - 16 * N) = 8`) THEN
        MAP_EVERY UNDISCH_TAC
         [`48 * N + 24 <= buflen`;
          `8 * buflen = 24 * LENGTH(inlist:(24 word)list)`] THEN
        ARITH_TAC;
        ASM_SIMP_TAC[EL_MAP] THEN DISCH_THEN(K ALL_TAC) THEN
        CONV_TAC EXPAND_CASES_CONV THEN
        CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REWRITE_TAC[]];
      MAP_EVERY EXPAND_TAC ["curlist2"; "curlist1"] THEN
      ASM_REWRITE_TAC[APPEND_ASSOC]];
    ALL_TAC] THEN

  (*** Steps 30-31: accumulation (ADD X9 + ADD X9) ***)
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (30--31) THEN

  (* Normalize store event addresses: word_shl from ADD Xn, Xn, Xm LSL #2 *)
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_RULE
    `word_add (word_add a (word(4 * n))) (word_shl (word m) 2):int64 =
     word_add a (word(4 * (n + m)))`]) THEN

  SUBGOAL_THEN `val(idx0:int64) < 16` ASSUME_TAC THENL
   [EXPAND_TAC "idx0" THEN
    REWRITE_TAC[bitval] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
    CONV_TAC NUM_REDUCE_CONV;
    ALL_TAC] THEN
  SUBGOAL_THEN `val(idx1:int64) < 16` ASSUME_TAC THENL
   [EXPAND_TAC "idx1" THEN
    REWRITE_TAC[bitval] THEN
    REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN
    CONV_TAC(DEPTH_CONV(WORD_NUM_RED_CONV ORELSEC WORD_CONDENSE_CONV)) THEN
    CONV_TAC NUM_REDUCE_CONV;
    ALL_TAC] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  ASM_REWRITE_TAC[ARITH_RULE `3 * (16 * N + 8) = 48 * N + 24`] THEN
  EXPAND_TAC "cur" THEN REPEAT(CONJ_TAC THENL [CONV_TAC WORD_RULE;ALL_TAC]) THEN
  CONJ_TAC THENL
   [SUBST1_TAC(SYM(ASSUME `curlen1 + len1:num = curlen2`)) THEN
    SUBST1_TAC(SYM(ASSUME `curlen + len0:num = curlen1`)) THEN
    CONV_TAC WORD_RULE;
    DISCHARGE_MEMSAFE_ASM_TAC]);;

(* The main loop exits at the first block with insufficient input or output. *)
let MLDSA_REJ_UNIFORM_LOOP = prove
 (`!res buf buflen table (inlist:(24 word)list) e pc N.
    buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,buflen); (table,256)] /\
    48 * N <= buflen /\ LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * N) inlist)) <= 256 /\
    ~(48 * N + 48 <= buflen /\
       LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * N) inlist)) <= 240) /\
    (!i. i < N ==> 48 * i + 48 <= buflen /\
       LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * i) inlist)) <= 240)
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word(pc + 0x74) /\ rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e 0 s)
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word(pc + 0x158) /\ rej_uniform_vectors s /\
            rej_uniform_prefix res buf buflen table inlist e (16 * N) s)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  let normalize = REWRITE_RULE[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; ALL] in
  let test i first take =
    SPECL [`res:int64`; `buf:int64`; `buflen:num`; `table:int64`;
           `inlist:(24 word)list`; `e:uarch_event list`; i; `pc:num`; first; take]
      MLDSA_REJ_UNIFORM_TEST16 |>
    CONV_RULE(TOP_DEPTH_CONV let_CONV) |>
    REWRITE_RULE[COND_CLAUSES; MULT_CLAUSES] |> normalize in
  REPEAT GEN_TAC THEN REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
    ALL] THEN STRIP_TAC THEN ASM_CASES_TAC `N = 0` THENL
   [FIRST_X_ASSUM SUBST_ALL_TAC THEN
    RULE_ASSUM_TAC(REWRITE_RULE[MULT_CLAUSES; ADD_CLAUSES]) THEN
    REWRITE_TAC[MULT_CLAUSES] THEN MATCH_MP_TAC(test `0` `T` `F`) THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; LE_0];
    ALL_TAC] THEN
  ENSURES_WHILE_UP_TAC `N:num` `pc + 0x84` `pc + 0x150`
   `\i s. rej_uniform_vectors s /\
          rej_uniform_prefix res buf buflen table inlist e (16 * i) s` THEN
  REPEAT CONJ_TAC THENL
   [ASM_REWRITE_TAC[];
    FIRST_X_ASSUM(MP_TAC o SPEC `0`) THEN ASM_SIMP_TAC[LT_NZ; MULT_CLAUSES] THEN
    STRIP_TAC THEN MATCH_MP_TAC(test `0` `T` `T`) THEN
    ASM_REWRITE_TAC[LE_0] THEN ASM_ARITH_TAC;
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    MATCH_MP_TAC(normalize MLDSA_REJ_UNIFORM_BLOCK16) THEN ASM_SIMP_TAC[];
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `i:num`) THEN ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
    MATCH_MP_TAC(test `i:num` `F` `T`) THEN ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC;
    MATCH_MP_TAC(test `N:num` `F` `F`) THEN ASM_REWRITE_TAC[]]);;

let MLDSA_REJ_UNIFORM_FINAL = prove
 (`!res buf buflen table (inlist:(24 word)list) e pc.
    nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word(pc + 0x224) /\
            ?k. k <= LENGTH inlist /\
                LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) <= 256 /\
                (k = LENGTH inlist \/
                 LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) = 256) /\
                rej_uniform_prefix res buf buflen table inlist e k s)
       (\s. read PC s = word(pc + 0x228) /\
            let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
            C_RETURN s = word(LENGTH outlist) /\
            read (memory :> bytes(res,4 * LENGTH outlist)) s =
              num_of_wordlist outlist /\
            ?e2. read events s = APPEND e2 e /\
                 memaccess_inbounds e2 [buf,buflen;table,256] [res,1024])
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI;
    LENGTH_MLDSA_REJ_UNIFORM_MC; C_RETURN; rej_uniform_prefix] THEN DISCH_TAC THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN ENSURES_INIT_TAC "s0" THEN
  FIRST_X_ASSUM(X_CHOOSE_THEN `k:num` (REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC)) THEN
  MP_TAC(SPECL [`inlist:(24 word)list`; `k:num`] REJ_UNIFORM_FINAL_PREFIX) THEN
  ASM_REWRITE_TAC[] THEN DISCH_THEN SUBST1_TAC THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [1] THEN ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[]);;

(* One more candidate either appends its low 23 bits or leaves the prefix intact. *)
let REJ_UNIFORM_PREFIX_SUC = prove
 (`!(l:(24 word)list) n. n < LENGTH l
    ==> REJ_SAMPLE (SUB_LIST (0,n+1) l) =
        let a:int32 = word (val (EL n l) MOD 2 EXP 23) in
        if val a < 8380417 then APPEND (REJ_SAMPLE (SUB_LIST (0,n) l)) [a]
        else REJ_SAMPLE (SUB_LIST (0,n) l)`,
  REPEAT STRIP_TAC THEN ONCE_REWRITE_TAC[SUB_LIST_SPLIT] THEN
  ASM_REWRITE_TAC[ADD_CLAUSES; SUB_LIST_1; REJ_SAMPLE_APPEND; LET_DEF; LET_END_DEF] THEN
  GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [REJ_SAMPLE] THEN
  REWRITE_TAC[MAP; FILTER] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[APPEND_NIL]);;

let REJ_UNIFORM_READ_CANDIDATE = prove
 (`!(l:(24 word)list) (buf:int64) s n len.
      n < LENGTH l /\ len = 3 * LENGTH l /\
      read (memory :> bytes(buf,len)) s = num_of_wordlist l
      ==> read (memory :> bytes(word_add buf (word (3*n)),3)) s = val(EL n l)`,
  REPEAT STRIP_TAC THEN
  MP_TAC(ISPECL [`l:(24 word)list`; `n:num`] NUM_OF_WORDLIST_EL) THEN
  ASM_REWRITE_TAC[DIMINDEX_24] THEN DISCH_THEN(SUBST1_TAC o SYM) THEN
  FIRST_X_ASSUM(SUBST1_TAC o SYM o check (fun th -> is_eq(concl th) &&
    rhs(concl th) = `num_of_wordlist(l:(24 word)list)`)) THEN
  REWRITE_TAC[READ_COMPONENT_COMPOSE; ARITH_RULE `24 * n = 8 * (3 * n)`;
              ARITH_RULE `24 = 8 * 3`; READ_BYTES_DIV; READ_BYTES_MOD] THEN
  SUBGOAL_THEN `MIN (len - 3*n) 3 = 3` (fun th -> REWRITE_TAC[th]) THEN ASM_ARITH_TAC);;
(* The three scalar byte loads form one little-endian 24-bit candidate. *)
let REJ_UNIFORM_JOIN_BYTES = prove
 (`!(a:int64) s.
     val (word_join (read (memory :> bytes8 (word_add a (word 2))) s)
          (word_join (read (memory :> bytes8 (word_add a (word 1))) s)
                     (read (memory :> bytes8 a) s):int16):24 word) =
     read (memory :> bytes (a,3)) s`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[GSYM (last(CONJUNCTS READ_MEMORY_BYTESIZED_SPLIT))] THEN
  SIMP_TAC[VAL_WORD_JOIN_SIMPLE; DIMINDEX_8; DIMINDEX_16; DIMINDEX_24; ARITH] THEN
  REWRITE_TAC[BYTES8_WBYTES; BYTES16_WBYTES; READ_COMPONENT_COMPOSE;
              VAL_READ_WBYTES; DIMINDEX_8; DIMINDEX_16] THEN
  CONV_TAC NUM_REDUCE_CONV THEN GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV)
    [ARITH_RULE `3 = 2 + 1`] THEN
  REWRITE_TAC[READ_BYTES_COMBINE] THEN CONV_TAC NUM_REDUCE_CONV THEN ARITH_TAC);;

let REJ_UNIFORM_JOIN_MASK = prove
 (`!(lo:byte) (mid:byte) (hi:byte).
   word_or (word_or (word_zx lo) (word_shl (word_zx mid) 8))
           (word_shl (word_and (word_zx hi) (word 127)) 16):int32 =
   word (val (word_join hi (word_join mid lo:int16):24 word) MOD 2 EXP 23)`,
  CONV_TAC WORD_BLAST);;
(* At the scalar loop head, a full polynomial or an empty input stops sampling. *)
let MLDSA_REJ_UNIFORM_SCALAR_DONE = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e n.
     buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
     n <= LENGTH inlist /\ LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) <= 256 /\
     (n = LENGTH inlist \/ LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) = 256) /\
     nonoverlapping (res,1024) (word pc,LENGTH mldsa_rej_uniform_mc)
     ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x1e4) /\
                rej_uniform_prefix res buf buflen table inlist e n s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x224) /\
                rej_uniform_prefix res buf buflen table inlist e n s)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[rej_uniform_prefix;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  ABBREV_TAC `k = LENGTH(REJ_SAMPLE(SUB_LIST(0,n) (inlist:(24 word)list)))` THEN
  SUBGOAL_THEN `val(word k:int64) = k` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  ASM_CASES_TAC `k = 256` THENL
   [ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--2);
    SUBGOAL_THEN `~(256 <= k)` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `word_sub (word buflen) (word(3*n)):int64 = word 0`
      ASSUME_TAC THENL
     [SUBGOAL_THEN `buflen = 3 * n` SUBST1_TAC THENL
       [ASM_ARITH_TAC; REWRITE_TAC[WORD_SUB_REFL]]; ALL_TAC] THEN
    ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
    ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--3)] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  TRY(CONJ_TAC THENL [ASM_MESON_TAC[]; ALL_TAC]) THEN
  DISCHARGE_MEMSAFE_ASM_TAC);;
let MLDSA_REJ_UNIFORM_SCALAR_STEP = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e n.
     buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
     n < LENGTH inlist /\ LENGTH (REJ_SAMPLE (SUB_LIST (0,n) inlist)) < 256 /\
     ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,buflen); (table,256)]
     ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x1e4) /\
                rej_uniform_prefix res buf buflen table inlist e n s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x1e4) /\
                rej_uniform_prefix res buf buflen table inlist e (n+1) s)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REPEAT GEN_TAC THEN REWRITE_TAC[ALL; NONOVERLAPPING_CLAUSES;
    MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; LENGTH_MLDSA_REJ_UNIFORM_MC;
    rej_uniform_prefix] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
  ABBREV_TAC `out = REJ_SAMPLE(SUB_LIST(0,n) (inlist:(24 word)list))` THEN
  ABBREV_TAC `k = LENGTH (out:int32 list)` THEN
  ABBREV_TAC `(a:int32) = word(val (EL n (inlist:(24 word)list)) MOD 2 EXP 23)` THEN
  SUBGOAL_THEN `REJ_SAMPLE(SUB_LIST(0,n+1) (inlist:(24 word)list)) =
      if val(a:int32) < 8380417 then APPEND out [a] else out` ASSUME_TAC THENL
   [ASM_SIMP_TAC[REJ_UNIFORM_PREFIX_SUC; LET_DEF; LET_END_DEF] THEN
    MAP_EVERY EXPAND_TAC ["a"; "out"] THEN REFL_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `buflen = 3 * LENGTH(inlist:(24 word)list) /\
                3*n + 3 <= buflen /\ 4*k+4 <= 1024`
    STRIP_ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  VAL_INT64_TAC `k:num` THEN
  SUBGOAL_THEN `~(word_sub (word buflen) (word(3*n)):int64 = word 0)`
    ASSUME_TAC THENL
   [REWRITE_TAC[WORD_SUB_EQ_0] THEN DISCH_THEN(MP_TAC o AP_TERM `val:int64->num`) THEN
    SUBGOAL_THEN `val (word buflen:int64) = buflen /\ val(word(3*n):int64) = 3*n`
      (fun th -> REWRITE_TAC[th]) THENL
     [CONJ_TAC THEN MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC;
      ASM_ARITH_TAC]; ALL_TAC] THEN
  SUBGOAL_THEN `~(256 <= k)` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `~(val(word_sub (word buflen) (word(3*n)):int64) = 0)`
    ASSUME_TAC THENL [ASM_REWRITE_TAC[VAL_EQ_0] THEN ASM_MESON_TAC[]; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN STRIP_EXISTS_ASSUM_TAC THEN
  ABBREV_TAC `p = word_add buf (word (3*n)):int64` THEN
  ABBREV_TAC `lo:byte = read (memory :> bytes8 p) s0` THEN
  ABBREV_TAC `mid:byte = read (memory :> bytes8 (word_add p (word 1))) s0` THEN
  ABBREV_TAC `hi:byte = read (memory :> bytes8 (word_add p (word 2))) s0` THEN
  SUBGOAL_THEN
   `word_or (word_or (word_zx (lo:byte)) (word_shl (word_zx (mid:byte)) 8))
            (word_shl (word_and (word_zx (hi:byte)) (word 127)) 16):int32 = a`
    ASSUME_TAC THENL
   [REWRITE_TAC[REJ_UNIFORM_JOIN_MASK] THEN MAP_EVERY EXPAND_TAC ["a"; "hi"; "mid"; "lo"] THEN
    REWRITE_TAC[REJ_UNIFORM_JOIN_BYTES] THEN EXPAND_TAC "p" THEN
    MP_TAC(ISPECL [`inlist:(24 word)list`; `buf:int64`; `s0:armstate`; `n:num`;
                   `buflen:num`] REJ_UNIFORM_READ_CANDIDATE) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_MESON_TAC[]; ALL_TAC] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REFL_TAC; ALL_TAC] THEN
  UNDISCH_THEN `buflen = 3 * LENGTH(inlist:(24 word)list)` (K ALL_TAC) THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (1--11) THEN
  SUBGOAL_THEN `read X5 s11 = word_zx (a:int32)` (LABEL_TAC "candidate") THENL
   [ASM_REWRITE_TAC[] THEN
    FIRST_ASSUM(fun th -> if is_eq(concl th) && rhs(concl th) = `a:int32` &&
      is_comb(lhs(concl th)) && fst(dest_const(fst(strip_comb(lhs(concl th))))) = "word_or"
      then GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM th] else failwith "word_or") THEN
    CONV_TAC WORD_BLAST; ALL_TAC] THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read X5 s11 = word_zx (word_or a b)`] THEN
  ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [12] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[WORD_BLAST
    `word_zx (word_zx (w:int32):int64):int32 = w`]) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[CONV_RULE WORD_REDUCE_CONV
    (ISPECL [`x:int32`; `word 8380417:int32`] NOCARRY_WORD_SUB)]) THEN
  ASM_CASES_TAC `val(a:int32) < 8380417` THENL
   [SUBGOAL_THEN `~(8380417 <= val(a:int32))` ASSUME_TAC THENL
      [ASM_ARITH_TAC; ALL_TAC] THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC (13--16);
    SUBGOAL_THEN `8380417 <= val(a:int32)` ASSUME_TAC THENL
      [ASM_ARITH_TAC; ALL_TAC] THEN ARM_STEPS_TAC MLDSA_REJ_UNIFORM_EXEC [13]] THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[LENGTH_APPEND; LENGTH; ARITH] THEN
  EXPAND_TAC "p" THEN REWRITE_TAC[GSYM WORD_ADD_ASSOC; GSYM WORD_ADD;
    ARITH_RULE `3 * (n + 1) = 3*n + 3 /\ 4*(n+1) = 4*n+4`;
    WORD_RULE `word_sub (word_sub x (word n)) (word k) =
               word_sub x (word(n + k))`] THEN
  TRY(CONJ_TAC THENL
   [W(MP_TAC o PART_MATCH (lhand o rand) BYTES_EQ_NUM_OF_WORDLIST_APPEND o snd) THEN
    ASM_REWRITE_TAC[DIMINDEX_32; ARITH_RULE `8 * 4 * k = 32*k`] THEN
    DISCH_THEN SUBST1_TAC THEN ASM_REWRITE_TAC[NUM_OF_WORDLIST_SING] THEN
    SUBGOAL_THEN
      `read (memory :> bytes32 (word_add res (word(4*k)))) s16 = (a:int32)`
      MP_TAC THENL
     [ASM_REWRITE_TAC[] THEN CONV_TAC WORD_BLAST;
      DISCH_THEN(MP_TAC o AP_TERM `val:int32->num`) THEN
      REWRITE_TAC[READ_COMPONENT_COMPOSE; BYTES32_WBYTES; VAL_READ_WBYTES;
                  DIMINDEX_32; ARITH_RULE `32 DIV 8 = 4`]];
    ALL_TAC]) THEN
  DISCHARGE_MEMSAFE_ASM_TAC);;
(* Each pass consumes exactly one candidate, including rejected candidates. *)
let MLDSA_REJ_UNIFORM_SCALAR = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e n.
     buflen < 2 EXP 64 /\ 8 * buflen = 24 * LENGTH inlist /\
     ALL (nonoverlapping (res,1024))
       [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,buflen); (table,256)] /\
     n <= LENGTH inlist /\ LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) <= 256
     ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x1e4) /\
                rej_uniform_prefix res buf buflen table inlist e n s)
           (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
                read PC s = word (pc + 0x224) /\
                ?k. k <= LENGTH inlist /\
                    LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) <= 256 /\
                    (k = LENGTH inlist \/ LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) = 256) /\
                    rej_uniform_prefix res buf buflen table inlist e k s)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes (res,1024)])`,
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] THEN
  REPEAT GEN_TAC THEN WF_INDUCT_TAC `LENGTH(inlist:(24 word)list) - n` THEN
  STRIP_TAC THEN
  ASM_CASES_TAC `n = LENGTH(inlist:(24 word)list) \/
    LENGTH(REJ_SAMPLE(SUB_LIST(0,n) inlist)) = 256` THENL
   [ENSURES_POSTCONDITION_TAC
      `\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
           read PC s = word (pc+0x224) /\
           rej_uniform_prefix res buf buflen table inlist e n s` THEN
    CONJ_TAC THENL
     [BETA_TAC THEN REPEAT STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
      EXISTS_TAC `n:num` THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC(REWRITE_RULE[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI]
        MLDSA_REJ_UNIFORM_SCALAR_DONE) THEN
      ASM_REWRITE_TAC[] THEN ASM_MESON_TAC[ALL]];
    ALL_TAC] THEN
  ENSURES_SEQUENCE_TAC `pc+0x1e4`
    `\s. rej_uniform_prefix res buf buflen table inlist e (n+1) s` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC(REWRITE_RULE[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI]
      MLDSA_REJ_UNIFORM_SCALAR_STEP) THEN ASM_REWRITE_TAC[] THEN
    ASM_ARITH_TAC;
    FIRST_X_ASSUM(fun th -> MATCH_MP_TAC(REWRITE_RULE[IMP_IMP]
      (SPECL [`inlist:(24 word)list`; `n+1`] th))) THEN REPEAT CONJ_TAC THEN
    ASM_REWRITE_TAC[] THEN TRY ASM_ARITH_TAC THEN
    MP_TAC(ISPECL [`inlist:(24 word)list`; `n:num`; `1`] REJ_UNIFORM_LENGTH_STEP) THEN
    ASM_ARITH_TAC]);;

let MLDSA_REJ_UNIFORM_CORRECT_MEMSAFE = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e.
    24 divides val buflen /\ 8 * val buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,val buflen); (table,256)]
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen;table] s /\
            read (memory :> bytes(table,256)) s = num_of_wordlist mldsa_rej_uniform_table /\
            read (memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist /\
            read events s = e)
       (\s. read PC s = word(pc + 0x228) /\
            let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
            C_RETURN s = word(LENGTH outlist) /\
            read (memory :> bytes(res,4 * LENGTH outlist)) s =
              num_of_wordlist outlist /\
            ?e2. read events s = APPEND e2 e /\
                 memaccess_inbounds e2 [buf,val buflen;table,256] [res,1024])
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  let normalize = REWRITE_RULE[ALL; MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI] in
  let state pc n =
    let p = vsubst[n,`n:num`]
     `\s. rej_uniform_vectors s /\ rej_uniform_prefix res buf buflen table inlist e n s` in
    ENSURES_SEQUENCE_TAC pc p in
  let scalar n =
    let th = SPECL [`res:int64`; `buf:int64`; `buflen:num`; `table:int64`;
                     `inlist:(24 word)list`; `pc:num`; `e:uarch_event list`; n]
                    (normalize MLDSA_REJ_UNIFORM_SCALAR) in
    let p = rand(rator(rator(snd(dest_imp(concl th))))) in
    ENSURES_PRECONDITION_TAC p THEN CONJ_TAC THENL
     [SIMP_TAC[]; MATCH_MP_TAC th THEN ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC] in
  MAP_EVERY X_GEN_TAC [`res:int64`; `buf:int64`] THEN W64_GEN_TAC `buflen:num` THEN
  MAP_EVERY X_GEN_TAC [`table:int64`; `inlist:(24 word)list`; `pc:num`;
                       `e:uarch_event list`] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; ALL] THEN STRIP_TAC THEN
  state `pc + 0x74` `0` THEN CONJ_TAC THENL
   [MATCH_MP_TAC(normalize MLDSA_REJ_UNIFORM_INIT) THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  MP_TAC(SPECL [`buflen:num`; `inlist:(24 word)list`] REJ_UNIFORM_BLOCK_COUNT) THEN
  DISCH_THEN(X_CHOOSE_THEN `N:num` (REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC)) THEN
  state `pc + 0x158` `16 * N` THEN CONJ_TAC THENL
   [MATCH_MP_TAC(normalize MLDSA_REJ_UNIFORM_LOOP) THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
  ENSURES_SEQUENCE_TAC `pc + 0x224`
   `\s. ?k. k <= LENGTH inlist /\
            LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) <= 256 /\
            (k = LENGTH inlist \/ LENGTH(REJ_SAMPLE(SUB_LIST(0,k) inlist)) = 256) /\
            rej_uniform_prefix res buf buflen table inlist e k s` THEN
  CONJ_TAC THENL [ALL_TAC; MATCH_MP_TAC(normalize MLDSA_REJ_UNIFORM_FINAL) THEN
                             ASM_REWRITE_TAC[]] THEN
  MP_TAC(SPECL [`res:int64`; `buf:int64`; `buflen:num`; `table:int64`;
    `inlist:(24 word)list`; `e:uarch_event list`; `N:num`; `pc:num`]
     (normalize MLDSA_REJ_UNIFORM_TEST8)) THEN
  CONV_TAC(LAND_CONV(TOP_DEPTH_CONV let_CONV)) THEN ASM_REWRITE_TAC[] THEN
  ASM_CASES_TAC `48 * N + 24 <= buflen` THEN ASM_REWRITE_TAC[] THENL
   [ASM_CASES_TAC `LENGTH(REJ_SAMPLE(SUB_LIST(0,16 * N) inlist)) <= 248` THEN
    ASM_REWRITE_TAC[] THEN DISCH_TAC THENL
     [state `pc + 0x168` `16 * N` THEN CONJ_TAC THENL
       [FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
      state `pc + 0x1e4` `16 * N + 8` THEN CONJ_TAC THENL
       [MATCH_MP_TAC(normalize MLDSA_REJ_UNIFORM_BLOCK8) THEN ASM_REWRITE_TAC[];
        MP_TAC(SPECL [`inlist:(24 word)list`; `16 * N`; `8`] REJ_UNIFORM_LENGTH_STEP) THEN
        DISCH_TAC THEN scalar `16 * N + 8`];
      state `pc + 0x1e4` `16 * N` THEN CONJ_TAC THENL
       [FIRST_ASSUM ACCEPT_TAC; scalar `16 * N`]];
    DISCH_TAC THEN SUBGOAL_THEN `16 * N = LENGTH(inlist:(24 word)list)` ASSUME_TAC THENL
     [FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE I [divides]) THEN
      DISCH_THEN(X_CHOOSE_TAC `d:num`) THEN
      SUBGOAL_THEN `d = 2 * N` ASSUME_TAC THENL [ASM_ARITH_TAC; ASM_ARITH_TAC]; ALL_TAC] THEN
    FIRST_ASSUM(fun th -> MATCH_MP_TAC(BETA_RULE(MATCH_MP
      (ONCE_REWRITE_RULE[IMP_CONJ_ALT] ENSURES_POSTCONDITION_THM) th))) THEN
    X_GEN_TAC `s:armstate` THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    EXISTS_TAC `16 * N` THEN ASM_REWRITE_TAC[LE_REFL]]);;

(* Project the functional result and the bounds on memory accesses. *)
let REJ_UNIFORM_PROJECT_TAC starting_events =
  REWRITE_TAC[ensures] THEN X_GEN_TAC `s0:armstate` THEN STRIP_TAC THEN
  MP_TAC(SPECL [`res:int64`; `buf:int64`; `buflen:int64`; `table:int64`;
    `inlist:(24 word)list`; `pc:num`; starting_events]
    MLDSA_REJ_UNIFORM_CORRECT_MEMSAFE) THEN
  CONV_TAC(LAND_CONV(TOP_DEPTH_CONV let_CONV)) THEN
  ASM_REWRITE_TAC[ensures] THEN DISCH_THEN(MP_TAC o SPEC `s0:armstate`) THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC(REWRITE_RULE[RIGHT_IMP_FORALL_THM] EVENTUALLY_MONO) THEN
  SIMP_TAC[];;

let MLDSA_REJ_UNIFORM_CORRECT = prove
 (`!res buf buflen table (inlist:(24 word)list) pc.
    24 divides val buflen /\ 8 * val buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,val buflen); (table,256)]
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen;table] s /\
            read (memory :> bytes(table,256)) s = num_of_wordlist mldsa_rej_uniform_table /\
            read (memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist)
       (\s. read PC s = word(pc + 0x228) /\
            let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
            let outlen = LENGTH outlist in
            C_RETURN s = word outlen /\
            read (memory :> bytes(res,4 * outlen)) s = num_of_wordlist outlist)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REJ_UNIFORM_PROJECT_TAC `read events s0`);;

let MLDSA_REJ_UNIFORM_SUBROUTINE_CORRECT = prove
 (`!res buf buflen table (inlist:(24 word)list) pc returnaddress.
    24 divides val buflen /\ 8 * val buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,val buflen); (table,256)]
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ read X30 s = returnaddress /\
            C_ARGUMENTS [res;buf;buflen;table] s /\
            read (memory :> bytes(table,256)) s = num_of_wordlist mldsa_rej_uniform_table /\
            read (memory :> bytes(buf,val buflen)) s = num_of_wordlist inlist)
       (\s. read PC s = returnaddress /\
            let outlist = SUB_LIST(0,256) (REJ_SAMPLE inlist) in
            let outlen = LENGTH outlist in
            C_RETURN s = word outlen /\
            read (memory :> bytes(res,4 * outlen)) s = num_of_wordlist outlist)
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  let conv = TOP_DEPTH_CONV let_CONV THENC
    REWRITE_CONV[wordlist_from_memory; LENGTH_MLDSA_REJ_UNIFORM_MC] in
  CONV_TAC conv THEN ARM_ADD_RETURN_NOSTACK_TAC MLDSA_REJ_UNIFORM_EXEC
    (CONV_RULE conv MLDSA_REJ_UNIFORM_CORRECT));;

let MLDSA_REJ_UNIFORM_MEMSAFE = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e.
    24 divides val buflen /\ 8 * val buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,val buflen); (table,256)]
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ C_ARGUMENTS [res;buf;buflen;table] s /\
            wordlist_from_memory(table,256) s = mldsa_rej_uniform_table /\
            wordlist_from_memory(buf,LENGTH inlist) s = inlist /\
            read events s = e)
       (\s. read PC s = word(pc + 0x228) /\
            ?e2. read events s = APPEND e2 e /\
                 memaccess_inbounds e2 [buf,val buflen;table,256] [res,1024])
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MP_TAC(ISPECL [`table:int64`; `256`; `256`; `mldsa_rej_uniform_table`]
    (INST_TYPE [`:8`,`:N`] WORDLIST_FROM_MEMORY_EQ_ALT)) THEN
  REWRITE_TAC[DIMINDEX_8] THEN DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  MP_TAC(ISPECL [`buf:int64`; `LENGTH(inlist:(24 word)list)`;
    `val(buflen:int64)`; `inlist:(24 word)list`]
    (INST_TYPE [`:24`,`:N`] WORDLIST_FROM_MEMORY_EQ_ALT)) THEN
  ASM_REWRITE_TAC[DIMINDEX_24] THEN DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN REJ_UNIFORM_PROJECT_TAC `e:uarch_event list`);;

let MLDSA_REJ_UNIFORM_SUBROUTINE_MEMSAFE = prove
 (`!res buf buflen table (inlist:(24 word)list) pc e returnaddress.
    24 divides val buflen /\ 8 * val buflen = 24 * LENGTH inlist /\
    ALL (nonoverlapping (res,1024))
      [(word pc,LENGTH mldsa_rej_uniform_mc); (buf,val buflen); (table,256)]
    ==> ensures arm
       (\s. aligned_bytes_loaded s (word pc) mldsa_rej_uniform_mc /\
            read PC s = word pc /\ read X30 s = returnaddress /\
            C_ARGUMENTS [res;buf;buflen;table] s /\
            wordlist_from_memory(table,256) s = mldsa_rej_uniform_table /\
            wordlist_from_memory(buf,LENGTH inlist) s = inlist /\
            read events s = e)
       (\s. read PC s = returnaddress /\
            ?e2. read events s = APPEND e2 e /\
                 memaccess_inbounds e2 [buf,val buflen;table,256] [res,1024])
       (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
        MAYCHANGE [memory :> bytes(res,1024)])`,
  let conv = TOP_DEPTH_CONV let_CONV THENC
    REWRITE_CONV[wordlist_from_memory; LENGTH_MLDSA_REJ_UNIFORM_MC] in
  CONV_TAC conv THEN ARM_ADD_RETURN_NOSTACK_TAC MLDSA_REJ_UNIFORM_EXEC
    (CONV_RULE conv MLDSA_REJ_UNIFORM_MEMSAFE) THEN DISCHARGE_MEMSAFE_TAC);;
