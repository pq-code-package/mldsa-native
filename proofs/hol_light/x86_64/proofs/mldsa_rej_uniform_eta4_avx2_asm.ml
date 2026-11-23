(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* ML-DSA Rejection uniform sampling for eta=4 (x86_64 AVX2).                *)
(* ========================================================================= *)

needs "s2n_bignum/x86/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_utils.ml";;
needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_table.ml";;

(* Make silent type-variable invention an error (avoids nondeterministic     *)
(* "seqapply: Length mismatch" failures from fresh tyvars across subgoals).  *)
type_invention_error := true;;

let mldsa_rej_uniform_eta4_mc = define_assert_from_elf
  "mldsa_rej_uniform_eta4_mc" "x86_64/mldsa/mldsa_rej_uniform_eta4_avx2_asm.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0x41; 0xb8; 0x0f; 0x0f; 0x0f; 0x0f;
                           (* MOV (% r8d) (Imm32 (word 252645135)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xd0;
                           (* VMOVD (%_% xmm2) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xd2;
                           (* VPBROADCASTD (%_% ymm2) (%_% xmm2) *)
  0x41; 0xb8; 0x04; 0x04; 0x04; 0x04;
                           (* MOV (% r8d) (Imm32 (word 67372036)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xd8;
                           (* VMOVD (%_% xmm3) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xdb;
                           (* VPBROADCASTD (%_% ymm3) (%_% xmm3) *)
  0x41; 0xb8; 0x09; 0x09; 0x09; 0x09;
                           (* MOV (% r8d) (Imm32 (word 151587081)) *)
  0xc4; 0xc1; 0x79; 0x6e; 0xe0;
                           (* VMOVD (%_% xmm4) (% r8d) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xe4;
                           (* VPBROADCASTD (%_% ymm4) (%_% xmm4) *)
  0x31; 0xc0;              (* XOR (% eax) (% eax) *)
  0x31; 0xc9;              (* XOR (% ecx) (% ecx) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x0f; 0x87; 0xfb; 0x00; 0x00; 0x00;
                           (* JA (Imm32 (word 251)) *)
  0x81; 0xf9; 0x00; 0x01; 0x00; 0x00;
                           (* CMP (% ecx) (Imm32 (word 256)) *)
  0x0f; 0x87; 0xef; 0x00; 0x00; 0x00;
                           (* JA (Imm32 (word 239)) *)
  0xc4; 0xe2; 0x7d; 0x30; 0x04; 0x0e;
                           (* VPMOVZXBW (%_% ymm0) (Memop Word128 (%%% (rsi,0,rcx))) *)
  0xc5; 0xf5; 0x71; 0xf0; 0x04;
                           (* VPSLLW (%_% ymm1) (%_% ymm0) (Imm8 (word 4)) *)
  0xc5; 0xfd; 0xeb; 0xc1;  (* VPOR (%_% ymm0) (%_% ymm0) (%_% ymm1) *)
  0xc5; 0xfd; 0xdb; 0xc2;  (* VPAND (%_% ymm0) (%_% ymm0) (%_% ymm2) *)
  0xc5; 0xfd; 0xf8; 0xcc;  (* VPSUBB (%_% ymm1) (%_% ymm0) (%_% ymm4) *)
  0xc5; 0xe5; 0xf8; 0xc0;  (* VPSUBB (%_% ymm0) (%_% ymm3) (%_% ymm0) *)
  0xc5; 0x7d; 0xd7; 0xc1;  (* VPMOVMSKB (% r8d) (%_% ymm1) *)
  0xc4; 0xe3; 0x7d; 0x39; 0xc5; 0x00;
                           (* VEXTRACTI128 (%_% xmm5) (%_% ymm0) (Imm8 (word 0)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0xa1; 0x7a; 0x7e; 0x34; 0xd2;
                           (* VMOVQ (%_% xmm6) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0xe2; 0x51; 0x00; 0xf6;
                           (* VPSHUFB (%_% xmm6) (%_% xmm5) (%_% xmm6) *)
  0xc4; 0xe2; 0x7d; 0x21; 0xce;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm6) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x0f; 0x87; 0x97; 0x00; 0x00; 0x00;
                           (* JA (Imm32 (word 151)) *)
  0xc5; 0xd1; 0x73; 0xdd; 0x08;
                           (* VPSRLDQ (%_% xmm5) (%_% xmm5) (Imm8 (word 8)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0xa1; 0x7a; 0x7e; 0x34; 0xd2;
                           (* VMOVQ (%_% xmm6) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0xe2; 0x51; 0x00; 0xf6;
                           (* VPSHUFB (%_% xmm6) (%_% xmm5) (%_% xmm6) *)
  0xc4; 0xe2; 0x7d; 0x21; 0xce;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm6) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x77; 0x63;              (* JA (Imm8 (word 99)) *)
  0xc4; 0xe3; 0x7d; 0x39; 0xc5; 0x01;
                           (* VEXTRACTI128 (%_% xmm5) (%_% ymm0) (Imm8 (word 1)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0xa1; 0x7a; 0x7e; 0x34; 0xd2;
                           (* VMOVQ (%_% xmm6) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0xe2; 0x51; 0x00; 0xf6;
                           (* VPSHUFB (%_% xmm6) (%_% xmm5) (%_% xmm6) *)
  0xc4; 0xe2; 0x7d; 0x21; 0xce;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm6) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x41; 0xc1; 0xe8; 0x08;  (* SHR (% r8d) (Imm8 (word 8)) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0x3d; 0xf8; 0x00; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 248)) *)
  0x77; 0x2e;              (* JA (Imm8 (word 46)) *)
  0xc5; 0xd1; 0x73; 0xdd; 0x08;
                           (* VPSRLDQ (%_% xmm5) (%_% xmm5) (Imm8 (word 8)) *)
  0x45; 0x0f; 0xb6; 0xd0;  (* MOVZX (% r10d) (% r8b) *)
  0xc4; 0xa1; 0x7a; 0x7e; 0x34; 0xd2;
                           (* VMOVQ (%_% xmm6) (Memop Quadword (%%% (rdx,3,r10))) *)
  0xc4; 0xe2; 0x51; 0x00; 0xf6;
                           (* VPSHUFB (%_% xmm6) (%_% xmm5) (%_% xmm6) *)
  0xc4; 0xe2; 0x7d; 0x21; 0xce;
                           (* VPMOVSXBD (%_% ymm1) (%_% xmm6) *)
  0xc5; 0xfe; 0x7f; 0x0c; 0x87;
                           (* VMOVDQU (Memop Word256 (%%% (rdi,2,rax))) (%_% ymm1) *)
  0xf3; 0x45; 0x0f; 0xb8; 0xca;
                           (* POPCNT (% r9d) (% r10d) *)
  0x44; 0x01; 0xc8;        (* ADD (% eax) (% r9d) *)
  0x83; 0xc1; 0x04;        (* ADD (% ecx) (Imm8 (word 4)) *)
  0xe9; 0xfa; 0xfe; 0xff; 0xff;
                           (* JMP (Imm32 (word 4294967034)) *)
  0x3d; 0x00; 0x01; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 256)) *)
  0x73; 0x51;              (* JAE (Imm8 (word 81)) *)
  0x81; 0xf9; 0x10; 0x01; 0x00; 0x00;
                           (* CMP (% ecx) (Imm32 (word 272)) *)
  0x73; 0x49;              (* JAE (Imm8 (word 73)) *)
  0x44; 0x0f; 0xb6; 0x1c; 0x0e;
                           (* MOVZX (% r11d) (Memop Byte (%%% (rsi,0,rcx))) *)
  0xff; 0xc1;              (* INC (% ecx) *)
  0x45; 0x89; 0xda;        (* MOV (% r10d) (% r11d) *)
  0x41; 0x83; 0xe2; 0x0f;  (* AND (% r10d) (Imm8 (word 15)) *)
  0x41; 0x83; 0xfa; 0x09;  (* CMP (% r10d) (Imm8 (word 9)) *)
  0x73; 0x16;              (* JAE (Imm8 (word 22)) *)
  0x41; 0xb9; 0x04; 0x00; 0x00; 0x00;
                           (* MOV (% r9d) (Imm32 (word 4)) *)
  0x45; 0x29; 0xd1;        (* SUB (% r9d) (% r10d) *)
  0x44; 0x89; 0x0c; 0x87;  (* MOV (Memop Doubleword (%%% (rdi,2,rax))) (% r9d) *)
  0xff; 0xc0;              (* INC (% eax) *)
  0x3d; 0x00; 0x01; 0x00; 0x00;
                           (* CMP (% eax) (Imm32 (word 256)) *)
  0x73; 0x1f;              (* JAE (Imm8 (word 31)) *)
  0x41; 0xc1; 0xeb; 0x04;  (* SHR (% r11d) (Imm8 (word 4)) *)
  0x41; 0x83; 0xe3; 0x0f;  (* AND (% r11d) (Imm8 (word 15)) *)
  0x41; 0x83; 0xfb; 0x09;  (* CMP (% r11d) (Imm8 (word 9)) *)
  0x73; 0xb9;              (* JAE (Imm8 (word 185)) *)
  0x41; 0xba; 0x04; 0x00; 0x00; 0x00;
                           (* MOV (% r10d) (Imm32 (word 4)) *)
  0x45; 0x29; 0xda;        (* SUB (% r10d) (% r11d) *)
  0x44; 0x89; 0x14; 0x87;  (* MOV (Memop Doubleword (%%% (rdi,2,rax))) (% r10d) *)
  0xff; 0xc0;              (* INC (% eax) *)
  0xeb; 0xa8;              (* JMP (Imm8 (word 168)) *)
  0xc5; 0xf8; 0x77;        (* VZEROUPPER *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_rej_uniform_eta4_tmc = define_trimmed
  "mldsa_rej_uniform_eta4_tmc" mldsa_rej_uniform_eta4_mc;;

let MLDSA_REJ_UNIFORM_ETA4_EXEC = X86_MK_CORE_EXEC_RULE mldsa_rej_uniform_eta4_tmc;;

(* ------------------------------------------------------------------------- *)
(* Length helpers                                                            *)
(* ------------------------------------------------------------------------- *)

let LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC =
  REWRITE_CONV[mldsa_rej_uniform_eta4_tmc] `LENGTH mldsa_rej_uniform_eta4_tmc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

(* ------------------------------------------------------------------------- *)
(* Supporting spec lemmas, byte-shape interior aliases.                      *)
(*                                                                           *)
(* The public spec REJ_SAMPLE_ETA4 (in common/mldsa_specs.ml) takes a        *)
(* nibble list. The proof below is naturally written against the byte-list   *)
(* shape, since the loop invariant peels off bytes per iteration, so we      *)
(* introduce private byte-shape aliases below and bridge to the public spec  *)
(* at the subroutine spec.                                                   *)
(* ------------------------------------------------------------------------- *)

let REJ_NIBBLES_ETA4 = define
  `REJ_NIBBLES_ETA4 (l:byte list) =
   FILTER (\x:int16. val x < 9) (NIBBLES_OF_BYTES l)`;;

let REJ_SAMPLE_ETA4_BYTES = define
  `REJ_SAMPLE_ETA4_BYTES (l:byte list) =
   MAP (\x:int16. word_sx(word_sub (word 4:int16) x):int32)
       (REJ_NIBBLES_ETA4 l)`;;

(* Conversion lemma: NIBBLES_OF_BYTES (int16 list) = MAP word_zx of BYTES_TO_NIBBLES (4 word list) *)
let REJ_SAMPLE_ETA4_BYTES_EQ = prove
 (`!l:byte list. REJ_SAMPLE_ETA4_BYTES l =
                 REJ_SAMPLE_ETA4 (BYTES_TO_NIBBLES l)`,
  GEN_TAC THEN
  REWRITE_TAC[REJ_SAMPLE_ETA4_BYTES; REJ_NIBBLES_ETA4; REJ_SAMPLE_ETA4;
              NIBBLES_OF_BYTES_EQ_BYTES_TO_NIBBLES] THEN
  REWRITE_TAC[FILTER_MAP; o_DEF; GSYM MAP_o] THEN
  SUBGOAL_THEN `!x:4 word. val (word_zx x:int16) = val x`
    (fun th -> REWRITE_TAC[th]) THENL
   [GEN_TAC THEN MATCH_MP_TAC VAL_WORD_ZX THEN
    REWRITE_TAC[DIMINDEX_4; DIMINDEX_16] THEN ARITH_TAC;
    ALL_TAC] THEN
  SPEC_TAC(`BYTES_TO_NIBBLES (l:byte list)`,`xs:(4 word) list`) THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[FILTER; MAP] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[MAP] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN
  POP_ASSUM MP_TAC THEN POP_ASSUM(K ALL_TAC) THEN
  BITBLAST_TAC);;

needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_eta4_avx2_steps.ml";;

include Make_rej_uniform_eta4_steps(struct
  let exec = MLDSA_REJ_UNIFORM_ETA4_EXEC
  let code_length = LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC
  let nibbles = REJ_NIBBLES_ETA4
  let sample_bytes = REJ_SAMPLE_ETA4_BYTES
end);;

type_invention_error := false;;
needs "mldsa_native/x86_64/proofs/mldsa_rej_uniform_avx2_utils.ml";;
type_invention_error := true;;

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

let MEMSAFE_BITVAL_TAC:tactic =
  W(fun (asl,w) ->
    let bvs = find_terms (fun t ->
      try fst(dest_const(rator t)) = "bitval" with _ -> false) w in
    let bvs = setify bvs in
    MAP_EVERY (fun bv ->
      MP_TAC(SPEC (rand bv) BITVAL_BOUND)) bvs);;

let CONTAINED_ASM_TAC =
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  GEN_REWRITE_TAC (BINOP_CONV o LAND_CONV o LAND_CONV o TOP_DEPTH_CONV)
   [VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(BINOP_CONV(LAND_CONV MOD_DOWN_CONV)) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2; CONTAINED_MODULO_LMOD] THEN
  ((GEN_REWRITE_TAC I [CONTAINED_MODULO_REFL] THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC) ORELSE
   (MATCH_MP_TAC CONTAINED_MODULO_SIMPLE THEN
    MEMSAFE_BITVAL_TAC THEN MEMSAFE_ARITH_TAC));;

let TABLE_IDX_LT_256 = prove
 (`!K:num. val((word_zx:(M)word->int64)
              ((word_zx:(N)word->(M)word)
              ((word:num->(N)word)(K MOD 256)))) < 256`,
  REPEAT GEN_TAC THEN REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD] THEN
  TRANS_TAC LET_TRANS `K MOD 256` THEN
  CONJ_TAC THENL
   [MESON_TAC[MOD_LE; LE_TRANS];
    SIMP_TAC[DIVISION; ARITH_EQ]]);;

let GATHER_CONTAINED = prove
 (`!(table:int64) idx:int64. val idx < 256
     ==> contained_modulo (2 EXP 64)
           (val(word_add table (word(8 * val idx))),8) (val table,2048)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN
  ASM_ARITH_TAC);;

let GATHER_BOUND_TAC : tactic =
  DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN MATCH_ACCEPT_TAC TABLE_IDX_LT_256;;

let rec conj_append_right t ev =
  if is_conj t then
    let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let rec conj_append_right t ev =
  if is_conj t then let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
  else mk_conj(t, ev);;

let q56_ms = `\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
      read RIP s = word(pc + 52) /\ read RSP s = stackpointer /\
      read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
      read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
      read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
      read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
      read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
      read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
      read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist):int32 list)) /\
      read RCX s = word(16*N) /\
      read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist):int32 list))) s =
        num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist))) /\
      (exists e_acc:(uarch_event)list. read events s = APPEND e_acc (e:(uarch_event)list) /\
        memaccess_inbounds e_acc [(buf:int64),272; (table:int64),2048] [(res:int64),1024])`;;

let q318_ms = `\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
      read RIP s = word(pc + 314) /\ read RSP s = stackpointer /\
      read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
      read(memory :> bytes(table,2048)) s = num_of_wordlist(mldsa_rej_uniform_table:byte list) /\
      read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
      read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist):int32 list)) /\
      read RCX s = word(16*N) /\
      read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist):int32 list))) s =
        num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*N) inlist))) /\
      (exists e_acc:(uarch_event)list. read events s = APPEND e_acc (e:(uarch_event)list) /\
        memaccess_inbounds e_acc [(buf:int64),272; (table:int64),2048] [(res:int64),1024])`;;

let exit_offset_ms_tm = `
  !res buf table (inlist:byte list) pc N stackpointer e.
       LENGTH inlist = 272 /\
       nonoverlapping_modulo (2 EXP 64) (pc, 406) (val res,1024) /\
       nonoverlapping_modulo (2 EXP 64) (pc, 406) (val buf, 272) /\
       nonoverlapping_modulo (2 EXP 64) (pc, 406) (val table,2048) /\
       nonoverlapping_modulo (2 EXP 64) (val res,1024) (val buf, 272) /\
       nonoverlapping_modulo (2 EXP 64) (val res,1024) (val table,2048) /\
       16 * N = 272 /\
       LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list) <= 248
       ==> ensures x86
            (\s. (bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                 read RIP s = word(pc + 52) /\ read RSP s = stackpointer /\
                 read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                 read(memory :> bytes(table,2048)) s = num_of_wordlist mldsa_rej_uniform_table /\
                 read RDI s = res /\ read RSI s = buf /\ read RDX s = table /\
                 read YMM2 s = word 6811299366900952671974763824040465167839410862684739061144563765171360567055 /\
                 read YMM3 s = word 1816346497840254045859937019744124044757176230049263749638550337379029484548 /\
                 read YMM4 s = word 4086779620140571603184858294424279100703646517610843436686738259102816340233 /\
                 read RAX s = word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(N-1)) inlist):int32 list)) /\
                 read RCX s = word(16*(N-1)) /\
                 read(memory :> bytes(res, 4 * LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(N-1)) inlist):int32 list))) s =
                   num_of_wordlist(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0, 16*(N-1)) inlist))) /\
                 (exists e_acc:(uarch_event)list. read events s = APPEND e_acc e /\
                   memaccess_inbounds e_acc [buf,272; table,2048] [res,1024]))
            (\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
                 (exists e2. read events s = APPEND e2 e /\
                   memaccess_inbounds e2 [buf,272; table,2048] [res,1024]))
            (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
             MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                        ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
             MAYCHANGE [CF; PF; AF; ZF; SF; OF] ,, MAYCHANGE [events] ,, MAYCHANGE [memory :> bytes(res,1024)])`;;

let core_ms_tm = `!res buf table (inlist:byte list) e pc.
        LENGTH inlist = 272 /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
        nonoverlapping (res, 1024) (buf, 272) /\
        nonoverlapping (res, 1024) (table, 2048)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
                  read RIP s = word pc /\
                  C_ARGUMENTS [res; buf; table] s /\
                  read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                  read(memory :> bytes(table,2048)) s =
                    num_of_wordlist mldsa_rej_uniform_table /\
                  read events s = e)
             (\s. read RIP s = word(pc + LENGTH (BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
                  (exists e2.
                     read events s = APPEND e2 e /\
                     memaccess_inbounds e2 [buf,272; table,2048] [res,1024]))
             (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
              MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                         ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
              MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
              MAYCHANGE [memory :> bytes(res,1024)])`;;

needs "mldsa_native/x86_64/proofs/subroutine_signatures.ml";;

(* ========================================================================= *)
(* Constant-time (SAFE) machinery for rej_uniform_eta4.                       *)
(*                                                                           *)
(* Arch-neutral CT-mask prelude, the eta4 analogue of the eta2 prelude. The   *)
(* only eta-specific changes vs the eta2 source are:                          *)
(*   - REJ_MASK_ETA4 accept condition  val x < 9  (eta2: val x < 15)          *)
(*   - LENGTH_REJ_NIBBLES_ETA4_EQ_MASK references REJ_NIBBLES_ETA4/REJ_MASK_ETA4*)
(*   - REJ_MASK_ETA4_SUB_LIST references REJ_MASK_ETA4                        *)
(* Everything else (NUM_ACCEPTED, PACK_MASK8, NIBBLES_OF_BYTES_SUB_LIST,      *)
(* SUB_LIST_MAP_GEN, PACK_CONNECT) is eta-neutral, identical to eta2.         *)
(* ========================================================================= *)

(* eta4 public reject mask: for each nibble, accept iff its value < 9.        *)
let REJ_MASK_ETA4 = define
  `REJ_MASK_ETA4 (l:byte list) : bool list =
   MAP (\x:int16. val x < 9) (NIBBLES_OF_BYTES l)`;;

(* Abstract core: #elements passing P = #`true`s in the boolean image.       *)
let LENGTH_FILTER_EQ_LENGTH_FILTER_MAP = prove
 (`!(P:A->bool) xs.
     LENGTH(FILTER (\b:bool. b) (MAP P xs)) = LENGTH(FILTER P xs)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN
  REWRITE_TAC[MAP; FILTER; LENGTH] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[LENGTH]);;

(* Store-advance / trip-count bridge: #ACCEPTED nibbles = #`true`s in the    *)
(* PUBLIC reject mask.  Value-free.                                          *)
let LENGTH_REJ_NIBBLES_ETA4_EQ_MASK = prove
 (`!l:byte list.
     LENGTH(REJ_NIBBLES_ETA4 l) = LENGTH(FILTER (\b:bool. b) (REJ_MASK_ETA4 l))`,
  REWRITE_TAC[REJ_NIBBLES_ETA4; REJ_MASK_ETA4;
              LENGTH_FILTER_EQ_LENGTH_FILTER_MAP]);;

(* Public "accepted count" over a mask, additive over APPEND.  (eta-neutral)  *)
let NUM_ACCEPTED = define
  `NUM_ACCEPTED (m:bool list) = LENGTH(FILTER (\b:bool. b) m)`;;

let NUM_ACCEPTED_APPEND = prove
 (`!m1 m2. NUM_ACCEPTED(APPEND m1 m2) = NUM_ACCEPTED m1 + NUM_ACCEPTED m2`,
  REWRITE_TAC[NUM_ACCEPTED; FILTER_APPEND; LENGTH_APPEND]);;

(* Public table-index witness: 8-bit LSB-first packing of an accept-mask     *)
(* group.  The compaction table is indexed by this 0..255 value. (eta-neutral)*)
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

(* byte-index SUB_LIST maps to nibble-index SUB_LIST at 2x offset/length.  (n) *)
let NIBBLES_OF_BYTES_SUB_LIST = prove
 (`!l a b. NIBBLES_OF_BYTES(SUB_LIST(a,b) l) =
           SUB_LIST(2*a,2*b)(NIBBLES_OF_BYTES l)`,
  LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; SUB_LIST_CLAUSES; APPEND;
              MULT_CLAUSES; ADD_CLAUSES; ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`] THEN
  ASM_REWRITE_TAC[SUB_LIST_CLAUSES; APPEND]);;

(* General-offset MAP/SUB_LIST commutation.  (eta-neutral)                    *)
let SUB_LIST_MAP_GEN = prove
 (`!(f:A->B) l a b. SUB_LIST(a,b)(MAP f l) = MAP f (SUB_LIST(a,b) l)`,
  GEN_TAC THEN LIST_INDUCT_TAC THEN REPEAT GEN_TAC THEN
  MAP_EVERY (fun v -> STRUCT_CASES_TAC(SPEC v num_CASES)) [`a:num`;`b:num`] THEN
  ASM_REWRITE_TAC[MAP; SUB_LIST_CLAUSES]);;

(* mask-level length-doubling commutation: REJ_MASK_ETA4(SUB_LIST) into       *)
(* SUB_LIST of the ATOMIC mask.                                               *)
let REJ_MASK_ETA4_SUB_LIST = prove
 (`!l a b. REJ_MASK_ETA4(SUB_LIST(a,b) l) = SUB_LIST(2*a,2*b)(REJ_MASK_ETA4 l)`,
  REWRITE_TAC[REJ_MASK_ETA4; NIBBLES_OF_BYTES_SUB_LIST; SUB_LIST_MAP_GEN]);;

(* ========================================================================= *)
(* Trip-count lemmas.                                                         *)
(*                                                                           *)
(* eta4 analogue of the eta2 trip lemmas (NIBLEN_EQ_NUMACC, N_OF_MASK +       *)
(* _MINIMAL, IVAL_WORD_SMALL). eta-specific changes vs eta2: WOP buffer bound *)
(* 120 -> 256 (= buflen 272 - 16) and existence witness 8 -> 17               *)
(* (256 < 16*17 = 272); count bound 248 unchanged.                            *)
(* ========================================================================= *)

(* niblen(16N,inlist) = NUM_ACCEPTED(SUB_LIST(0,32N) mask): public re-expression *)
(* of the (inlist-based) exit predicate over the mask.                        *)
let NIBLEN_EQ_NUMACC_ETA4 = prove
 (`!(inlist:byte list) (N:num).
     LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16 * N) inlist):int16 list) =
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; NUM_ACCEPTED;
              REJ_MASK_ETA4_SUB_LIST] THEN
  REWRITE_TAC[MULT_CLAUSES; ARITH_RULE `2 * (16 * N) = 32 * N`]);;

(* The mask-based trip count (public loop iteration count). Buffer bound 256  *)
(* (=buflen 272 - 16); count bound 248.                                       *)
let N_OF_MASK_ETA4 = define
  `N_OF_MASK_ETA4 (mask:bool list) : num =
     minimal N. 256 < 16 * N \/ 248 < NUM_ACCEPTED(SUB_LIST(0,32 * N) mask)`;;

(* Trip minimality (dual-exit crux), analogue of N_OF_MASK_ETA2_MINIMAL.      *)
let N_OF_MASK_ETA4_MINIMAL = prove
 (`!(mask:bool list).
     (256 < 16 * N_OF_MASK_ETA4 mask \/
      248 < NUM_ACCEPTED(SUB_LIST(0,32 * N_OF_MASK_ETA4 mask) mask)) /\
     (!i. i < N_OF_MASK_ETA4 mask
          ==> ~(256 < 16 * i) /\
              ~(248 < NUM_ACCEPTED(SUB_LIST(0,32 * i) mask)))`,
  GEN_TAC THEN REWRITE_TAC[N_OF_MASK_ETA4] THEN
  SUBGOAL_THEN
    `?n. 256 < 16 * n \/ 248 < NUM_ACCEPTED(SUB_LIST(0,32 * n)(mask:bool list))`
    ASSUME_TAC THENL
   [EXISTS_TAC `17` THEN DISJ1_TAC THEN ARITH_TAC; ALL_TAC] THEN
  FIRST_X_ASSUM(STRIP_ASSUME_TAC o REWRITE_RULE[MINIMAL]) THEN
  ASM_REWRITE_TAC[] THEN
  X_GEN_TAC `i:num` THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM DE_MORGAN_THM] THEN FIRST_X_ASSUM MATCH_MP_TAC THEN
  ASM_REWRITE_TAC[]);;

(* ========================================================================= *)
(* f_ev_loop_eta4 — the eta4 per-iteration PUBLIC events delta.               *)
(*                                                                           *)
(* A fully type-annotated concrete new_definition, the eta4 analogue of       *)
(* f_ev_loop_eta2_def under the eta4 pc-offset map (offsets confirmed against *)
(* the proven eta4 MEMSAFE head/mid-guard proofs,                             *)
(* RIP=word(pc+{52,63,75,163,215,268,314})):                                  *)
(*     eta2 pc+399 -> eta4 pc+314   (crossover to scalar tail, JA-taken tgt)  *)
(*     eta2 pc+86  -> eta4 pc+52    (loop entry / back-edge)                  *)
(*     eta2 pc+339 -> eta4 pc+268   (mid-guard-3: COND, not self-jump)        *)
(*     eta2 pc+273 -> eta4 pc+215   (sub-iter-3 self-jump)                    *)
(*     eta2 pc+207 -> eta4 pc+163   (mid-guard-1, count-check COND)           *)
(*     eta2 pc+106 -> eta4 pc+75    (head-guard-2, buffer-position COND)      *)
(*     eta2 pc+97  -> eta4 pc+63    (head-guard-1, count-check COND)          *)
(*   WOP buffer bound 120 -> 256 (= buflen 272 - 16); count bound 248         *)
(*   unchanged.                                                               *)
(*                                                                           *)
(* The body is purely PUBLIC (PACK_MASK8 / NUM_ACCEPTED / SUB_LIST over the   *)
(* mask, zero raw stepped terms), so the port is a numeral+name substitution  *)
(* of the eta2 definition.                                                    *)
(* ========================================================================= *)
let f_ev_loop_eta4_def = new_definition `((((=):(uarch_event)list->(uarch_event)list->bool) ((((((((f_ev_loop_eta4):(64)word->(64)word->(64)word->num->(bool)list->num->(uarch_event)list) (res:(64)word)) (buf:(64)word)) (table:(64)word)) (pc:num)) (mask:(bool)list)) (i:num))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (314:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (52:num)))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (24:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (268:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list)))))))))))) (((int_of_num):num->int) (248:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (314:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (268:num))))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (16:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (215:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (215:num)))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((+):num->num->num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (163:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))))) (((int_of_num):num->int) (248:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) ((((word_add):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word):num->(32)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list)))))))))) (((word):num->(32)word) (248:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (314:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (163:num))))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventX86POPCNT):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) (((word_zx):(32)word->(64)word) (((word_zx):(64)word->(32)word) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list))))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventStore):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (res:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (4:num)) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list))))))) (32:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (table:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (8:num)) (((val):(64)word->num) (((word_zx):(32)word->(64)word) (((word_zx):(8)word->(32)word) (((word):num->(8)word) (((PACK_MASK8):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) ((((*):num->num->num) (32:num)) (i:num))) (8:num))) (mask:(bool)list))))))))))) (8:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventLoad):(64)word#num->uarch_event) ((((,):(64)word->num->(64)word#num) ((((word_add):(64)word->(64)word->(64)word) (buf:(64)word)) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (16:num)))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (75:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))))) (((int_of_num):num->int) (256:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (((word):num->(32)word) (256:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) ((((*):num->num->num) (16:num)) (i:num))))) (((word):num->(32)word) (256:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (314:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (75:num))))))) ((((CONS):uarch_event->(uarch_event)list->(uarch_event)list) (((EventJump):(64)word#(64)word->uarch_event) ((((,):(64)word->(64)word->(64)word#(64)word) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (63:num)))) (((((COND):bool->(64)word->(64)word->(64)word) (((~):bool->bool) ((((\/):bool->bool->bool) (((~):bool->bool) ((((=):int->int->bool) ((((int_sub):int->int->int) (((int_of_num):num->int) (((val):(32)word->num) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))))) (((int_of_num):num->int) (248:num)))) (((int_of_num):num->int) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word):num->(32)word) (248:num)))))))) ((((=):num->num->bool) (((val):(32)word->num) ((((word_sub):(32)word->(32)word->(32)word) (((word_zx):(64)word->(32)word) (((word):num->(64)word) (((NUM_ACCEPTED):(bool)list->num) ((((SUB_LIST):num#num->(bool)list->(bool)list) ((((,):num->num->num#num) (0:num)) ((((*):num->num->num) (32:num)) (i:num)))) (mask:(bool)list)))))) (((word):num->(32)word) (248:num))))) (0:num))))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (314:num)))) (((word):num->(64)word) ((((+):num->num->num) (pc:num)) (63:num))))))) ((NIL):(uarch_event)list)))))))))))))))))))))`;;


(* ========================================================================= *)
(* eta4 value bridges (step 2 of SUBROUTINE_SAFE).                            *)
(* ========================================================================= *)

(* ---- eta4 maskbit forall (accept < 9); group 0 offset = 8*k,               *)
(*      groups>0 = 8*(k+g). ---- *)
let eta4_mk_maskbit_forall g =
  let b = 4*g in
  let nib off hi =
    let v = subst [mk_small_numeral off, `OFF:num`] `val(word_subword (chunk0:int128) (OFF,8):byte)` in
    if hi then mk_binop `DIV` v `16` else mk_binop `MOD` v `16` in
  let ellist = end_itlist (fun a b -> mk_binop `CONS:num->(num)list->(num)list` a b)
     ([nib b false; nib b true; nib (b+8) false; nib (b+8) true;
       nib (b+16) false; nib (b+16) true; nib (b+24) false; nib (b+24) true] @ [`[]:num list`]) in
  let bitapp =
    if g = 0 then `bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)`
    else subst [mk_small_numeral g, `G:num`]
                 `bit 7 (word_subword (f1bnd:int256) (8*(k+G),8):byte)` in
  mk_forall(`k:num`,
    mk_imp(`k < 8`,
      mk_eq(bitapp,
            mk_binop `(<):num->num->bool` (mk_comb(mk_comb(`EL:num->(num)list->num`,`k:num`), ellist)) `9`)));;

(* ---- eta-neutral int16 nibble round-trip lemmas (reproved inline here) ---- *)
let VAL_WORD_NIB16 = prove
 (`!x. x < 16 ==> val(word x:int16) = x`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN
  MATCH_MP_TAC MOD_LT THEN ASM_ARITH_TAC);;

let VAL_WORD_NIB_LO = prove
 (`!w:byte. val(word(val w MOD 16):int16) = val w MOD 16`,
  GEN_TAC THEN MATCH_MP_TAC VAL_WORD_NIB16 THEN
  MP_TAC(SPECL[`val(w:byte)`;`16`] MOD_LT_EQ) THEN ARITH_TAC);;
let VAL_WORD_NIB_HI = prove
 (`!w:byte. val(word(val w DIV 16):int16) = val w DIV 16`,
  GEN_TAC THEN MATCH_MP_TAC VAL_WORD_NIB16 THEN
  MP_TAC(ISPEC `w:byte` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN ARITH_TAC);;

(* ---- group-link builder (port of eta2 mk_group_link/prove_group_link) ---- *)
let mk_group_link_eta4 gm =
  let mb = eta4_mk_maskbit_forall gm in
  let boff = gm / 2 in
  let bytelist =
    mk_list(map (fun j -> subst[mk_small_numeral(8*(boff+j)),`OFF:num`]
                   `word_subword (chunk0:int128) (OFF,8):byte`) (0--3), `:byte`) in
  let sublhs = subst[mk_small_numeral boff, `BOFF:num`]
                 `SUB_LIST(16*i+BOFF,4) (inlist:byte list)` in
  let link = mk_eq(sublhs, bytelist) in
  let lhs_bits =
    mk_list(map (fun k -> subst[mk_small_numeral(8*(k+gm)),`OFF:num`]
                   `bit 7 (word_subword (f1bnd:int256) (OFF,8):byte)`) (0--7), `:bool`) in
  let rhs = subst[mk_small_numeral gm, `GM:num`]
              `SUB_LIST(32*i+GM,8)(REJ_MASK_ETA4 (inlist:byte list))` in
  mk_imp(mb, mk_imp(link, mk_eq(lhs_bits, rhs)));;

let prove_group_link_eta4 gm =
  let goal = mk_group_link_eta4 gm in
  let boff = gm / 2 in
  let arith_off = ARITH_RULE(mk_eq(
      `2 * (16 * i + BOFF)`, `32 * i + GM`)
      |> subst[mk_small_numeral boff,`BOFF:num`; mk_small_numeral gm,`GM:num`]) in
  let rhs_reduced = subst[mk_small_numeral boff,`BOFF:num`]
                      `REJ_MASK_ETA4(SUB_LIST(16*i+BOFF,4) (inlist:byte list))` in
  let goal_rhs = subst[mk_small_numeral gm,`GM:num`]
                   `SUB_LIST(32*i+GM,8)(REJ_MASK_ETA4 (inlist:byte list))` in
  prove(goal,
    DISCH_THEN(fun mb -> DISCH_THEN(fun link ->
      SUBGOAL_THEN (mk_eq(goal_rhs, rhs_reduced)) SUBST1_TAC THENL
       [ONCE_REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
        REWRITE_TAC[arith_off] THEN CONV_TAC NUM_REDUCE_CONV;
        ALL_TAC] THEN
      REWRITE_TAC[link] THEN
      REWRITE_TAC[REJ_MASK_ETA4; NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND; MAP] THEN
      REWRITE_TAC[VAL_WORD_NIB_LO; VAL_WORD_NIB_HI] THEN
      (let mbs = map (fun k -> let th = SPEC (mk_small_numeral k) mb in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
       REWRITE_TAC mbs) THEN
      REFL_TAC)));;

let ETA4_PACK_GROUP0 = prove_group_link_eta4 0;;
let ETA4_PACK_GROUP1 = prove_group_link_eta4 8;;
let ETA4_PACK_GROUP2 = prove_group_link_eta4 16;;
let ETA4_PACK_GROUP3 = prove_group_link_eta4 24;;

(* ---- BYTE0_DIVMOD (eta-neutral, port of eta2) ---- *)
let BYTE0_DIVMOD = prove
 (`!p:num->bool.
    (bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
     16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7) +
     256*bitval(p 8) + 512*bitval(p 9) + 1024*bitval(p 10) + 2048*bitval(p 11) +
     4096*bitval(p 12) + 8192*bitval(p 13) + 16384*bitval(p 14) + 32768*bitval(p 15) +
     65536*bitval(p 16) + 131072*bitval(p 17) + 262144*bitval(p 18) + 524288*bitval(p 19) +
     1048576*bitval(p 20) + 2097152*bitval(p 21) + 4194304*bitval(p 22) + 8388608*bitval(p 23) +
     16777216*bitval(p 24) + 33554432*bitval(p 25) + 67108864*bitval(p 26) + 134217728*bitval(p 27) +
     268435456*bitval(p 28) + 536870912*bitval(p 29) + 1073741824*bitval(p 30) + 2147483648*bitval(p 31)) MOD 256 =
    bitval(p 0) + 2*bitval(p 1) + 4*bitval(p 2) + 8*bitval(p 3) +
    16*bitval(p 4) + 32*bitval(p 5) + 64*bitval(p 6) + 128*bitval(p 7)`,
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
  MATCH_MP_TAC ADD256_MOD THEN
  MAP_EVERY (fun k -> MP_TAC(ISPEC (mk_comb(`p:num->bool`,mk_small_numeral k)) BITVAL_BOUND))
    [0;1;2;3;4;5;6;7] THEN ARITH_TAC);;

let MS0 = prove
 (`!S:num. val(word_zx(word S:int32):int64) MOD 256 = S MOD 256`,
  GEN_TAC THEN
  REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_32; DIMINDEX_64] THEN
  REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`; MOD_MOD_EXP_MIN] THEN
  CONV_TAC NUM_REDUCE_CONV);;

(* ---- STORE_BRIDGE_ETA4 (port of eta2 STORE_BRIDGE) ---- *)
let STORE_BRIDGE_ETA4 = prove
 (`!inlist:byte list. !B.
     LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,B) inlist):int32 list) =
     NUM_ACCEPTED(SUB_LIST(0,2*B)(REJ_MASK_ETA4 inlist))`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; LENGTH_REJ_NIBBLES_ETA4_EQ_MASK;
              NUM_ACCEPTED] THEN
  REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST; MULT_CLAUSES]);;

(* ---- GATHER bridges (port of eta2 prove_gather + GATHER_BRIDGE1/2/3) ---- *)
let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)`;;
let byte1_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE1_DIVMOD);;
let byte2_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE2_DIVMOD);;
let byte3_inst = CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV)
                   (SPEC pinst BYTE3_DIVMOD);;
let bigsum = lhand(lhand(lhand(concl byte1_inst)));;
let tower8 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64`;;
let tower16 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64):int32) 8):int64`;;
let tower24 = subst[bigsum,`S:num`]
  `word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word_ushr(word_zx(word_zx(word (S:num):int32):int64):int32) 8):int64):int32) 8):int64):int32) 8):int64`;;

let link_of gm =
  let boff = gm / 2 in
  mk_eq(subst[mk_small_numeral boff,`BOFF:num`] `SUB_LIST(16*i+BOFF,4)(inlist:byte list)`,
        mk_list(map (fun j -> subst[mk_small_numeral(8*(boff+j)),`OFF:num`]
                       `word_subword (chunk0:int128) (OFF,8):byte`) (0--3), `:byte`));;

let prove_gather_eta4 gm maskv shiftlem byteinst packgrp tower =
  let goal =
    mk_imp(mk_eq(tower, maskv),
     mk_imp(eta4_mk_maskbit_forall gm,
      mk_imp(link_of gm,
        mk_eq(mk_comb(mk_comb(`MOD`,mk_comb(`val:int64->num`,maskv)),`256`),
              subst[mk_small_numeral gm,`GM:num`]
                `PACK_MASK8(SUB_LIST(32*i+GM,8)(REJ_MASK_ETA4 (inlist:byte list)))`)))) in
  prove(goal,
    STRIP_TAC THEN STRIP_TAC THEN STRIP_TAC THEN
    FIRST_X_ASSUM(SUBST1_TAC o SYM o
      check (fun th -> try rand(concl th) = maskv with _ -> false)) THEN
    REWRITE_TAC[shiftlem] THEN
    MP_TAC byteinst THEN DISCH_THEN SUBST1_TAC THEN
    W(fun (asl,w) ->
       let mb = find (fun th -> is_forall(concl th)) (map snd asl) in
       let link = find (fun th -> is_eq(concl th) &&
          (try fst(dest_const(fst(strip_comb(lhand(concl th))))) = "SUB_LIST"
           with _ -> false)) (map snd asl) in
       let pg = MP (MP (SPEC_ALL packgrp) mb) link in
       GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM pg]) THEN
    REWRITE_TAC[PACK_MASK8] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;

let GATHER_BRIDGE1_ETA4 = prove_gather_eta4 8 `mask8b:int64` MASK_SHIFT8_MOD256 byte1_inst ETA4_PACK_GROUP1 tower8;;
let GATHER_BRIDGE2_ETA4 = prove_gather_eta4 16 `mask8c:int64` MASK_SHIFT16_MOD256 byte2_inst ETA4_PACK_GROUP2 tower16;;
let GATHER_BRIDGE3_ETA4 = prove_gather_eta4 24 `mask8d:int64` MASK_SHIFT24_MOD256 byte3_inst ETA4_PACK_GROUP3 tower24;;

(* ---- P0_BRIDGE_ETA4 (group-0 gather; programmatic statement).               *)
(* p0_bigsum = the SAME 32-term pinst sum extracted from byte1_inst, so it is   *)
(* guaranteed syntactically identical to the raw stepper's group-0 BIGSUM       *)
(* (both instantiate pinst = \k. bit 7 (word_subword f1bnd (8*k,8))). ---- *)
let p0_bigsum = bigsum;;

(* group-0 link in REDUCED form (16*i, not 16*i+0) to match SUBITER_BLOCK_BYTES *)
(* conjunct 0 in EB_TAC's asl (raw dump: `SUB_LIST (16*i,4) inlist = ...`) and   *)
(* pg0 = REWRITE_RULE[16*i+0=16*i]. link_of 0 would give 16*i+0 -> MP mismatch.  *)
let link0_reduced_eta4 =
  mk_eq(`SUB_LIST(16*i,4)(inlist:byte list)`,
        mk_list([`word_subword (chunk0:int128) (0,8):byte`;
                 `word_subword (chunk0:int128) (8,8):byte`;
                 `word_subword (chunk0:int128) (16,8):byte`;
                 `word_subword (chunk0:int128) (24,8):byte`], `:byte`));;

let P0_BRIDGE_ETA4 = prove
 (mk_imp(eta4_mk_maskbit_forall 0,
   mk_imp(link0_reduced_eta4,
     mk_eq(mk_comb(mk_comb(`MOD`,
             mk_comb(`val:int64->num`,
               subst[p0_bigsum,`S:num`] `word_zx(word (S:num):int32):int64`)), `256`),
           `PACK_MASK8(SUB_LIST(32*i,8)(REJ_MASK_ETA4 (inlist:byte list)))`))),
  STRIP_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[MS0] THEN
  MP_TAC(SPEC pinst BYTE0_DIVMOD) THEN
  CONV_TAC(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
  DISCH_THEN SUBST1_TAC THEN
  W(fun (asl,w) ->
     let mb = find (fun th -> is_forall(concl th)) (map snd asl) in
     let link = find (fun th -> is_eq(concl th) &&
        (try fst(dest_const(fst(strip_comb(lhand(concl th))))) = "SUB_LIST" with _ -> false)) (map snd asl) in
     let pg0 = REWRITE_RULE[ARITH_RULE `16*i+0 = 16*i`; ARITH_RULE `32*i+0 = 32*i`] (SPEC_ALL ETA4_PACK_GROUP0) in
     let pg = MP (MP pg0 mb) link in
     GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [SYM pg]) THEN
  REWRITE_TAC[PACK_MASK8] THEN CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN ARITH_TAC);;


(* ------------------------------------------------------------------------- *)
(* eta4 SAFE-cluster prerequisites: ETA4_EVENTS_BRIDGE + containment prereqs  *)
(* + MEMACCESS_F_EV_LOOP_ETA4.                                                *)
(* ------------------------------------------------------------------------- *)

(* ========================================================================= *)
(* ETA4_EVENTS_BRIDGE.                                                        *)
(* Proves  [raw eta4 loop 19-event trace] = f_ev_loop_eta4 res buf table pc     *)
(* (REJ_MASK_ETA4 inlist) i  (the folded PUBLIC per-iteration event delta),     *)
(* the eta4 analogue of ETA2_EVENTS_BRIDGE. The EB_TAC tactic is inlined into   *)
(* the prove call. Requires only: f_ev_loop_eta4_def, SUBITER_BLOCK_BYTES,      *)
(* P0_BRIDGE_ETA4, GATHER_BRIDGE1/2/3_ETA4, STORE_BRIDGE_ETA4,                  *)
(* LENGTH_REJ_NIBBLES_ETA4_EQ_MASK, NUM_ACCEPTED, REJ_MASK_ETA4_SUB_LIST.       *)
(* ========================================================================= *)
let ETA4_EVENTS_BRIDGE = prove(
`(((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * k),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (0,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (0,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (8,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (8,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (16,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (16,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (24,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (24,8)):(8)word)) DIV 16)]) < 9)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 16)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (64,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (64,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (72,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (72,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (80,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (80,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (88,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (88,8)):(8)word)) DIV 16)]) < 9)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 8)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (32,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (32,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (40,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (40,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (48,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (48,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (56,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (56,8)):(8)word)) DIV 16)]) < 9)))) /\
((!k. ((k < 8) ==>
((bit 7 ((word_subword (f1bnd:(256)word) ((8 * (k + 24)),8)):(8)word)) = ((EL k [((val ((word_subword (chunk0:(128)word) (96,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (96,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (104,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (104,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (112,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (112,8)):(8)word)) DIV 16);
((val ((word_subword (chunk0:(128)word) (120,8)):(8)word)) MOD 16);
((val ((word_subword (chunk0:(128)word) (120,8)):(8)word)) DIV 16)]) < 9)))) /\
(((16 * i) <= 256) /\
(((SUB_LIST ((16 * i),16) (inlist:((8)word)list)) = [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word);
((word_subword (chunk0:(128)word) (32,8)):(8)word);
((word_subword (chunk0:(128)word) (40,8)):(8)word);
((word_subword (chunk0:(128)word) (48,8)):(8)word);
((word_subword (chunk0:(128)word) (56,8)):(8)word);
((word_subword (chunk0:(128)word) (64,8)):(8)word);
((word_subword (chunk0:(128)word) (72,8)):(8)word);
((word_subword (chunk0:(128)word) (80,8)):(8)word);
((word_subword (chunk0:(128)word) (88,8)):(8)word);
((word_subword (chunk0:(128)word) (96,8)):(8)word);
((word_subword (chunk0:(128)word) (104,8)):(8)word);
((word_subword (chunk0:(128)word) (112,8)):(8)word);
((word_subword (chunk0:(128)word) (120,8)):(8)word)]) /\
(((LENGTH (inlist:((8)word)list)) = 272) /\
(((LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,(16 * i)) (inlist:((8)word)list)))) = outlen0) /\
(((LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,((16 * i) + 8)) (inlist:((8)word)list)))) = acc2) /\
(((LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,((16 * i) + 4)) (inlist:((8)word)list)))) = acc1) /\
(((LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,((16 * i) + 12)) (inlist:((8)word)list)))) = acc3) /\
((((word_zx (word_ushr ((word_zx (mask8b:(64)word)):(32)word) 8)):(64)word) = (mask8c:(64)word)) /\
((((word_zx (word_ushr ((word_zx (mask8c:(64)word)):(32)word) 8)):(64)word) = (mask8d:(64)word)) /\
(((word_zx (word_ushr ((word_zx ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)):(32)word) 8)):(64)word) = (mask8b:(64)word))))))))))))))) ==>
([(EventJump (((word (pc + 314)):(64)word),((word (pc + 52)):(64)word)));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8d:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc3)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8d:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 268)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word_zx (word_add ((word_zx ((word acc2):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (64,8)):(8)word);
((word_subword (chunk0:(128)word) (72,8)):(8)word);
((word_subword (chunk0:(128)word) (80,8)):(8)word);
((word_subword (chunk0:(128)word) (88,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word))) (&248)) = (&(val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word acc2):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (64,8)):(8)word);
((word_subword (chunk0:(128)word) (72,8)):(8)word);
((word_subword (chunk0:(128)word) (80,8)):(8)word);
((word_subword (chunk0:(128)word) (88,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word)))))) \/ ((val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word acc2):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (64,8)):(8)word);
((word_subword (chunk0:(128)word) (72,8)):(8)word);
((word_subword (chunk0:(128)word) (80,8)):(8)word);
((word_subword (chunk0:(128)word) (88,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word))) = 0))) then ((word (pc + 314)):(64)word) else ((word (pc + 268)):(64)word))));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8c:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc2)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8c:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 215)):(64)word),((word (pc + 215)):(64)word)));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val (mask8b:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * acc1)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val (mask8b:(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventJump (((word (pc + 163)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word))) (&248)) = (&(val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word)))))) \/ ((val (word_sub ((word_zx ((word_zx (word_add ((word_zx ((word outlen0):(64)word)):(32)word) ((word_zx ((word_zx ((word (LENGTH (REJ_NIBBLES_ETA4 [((word_subword (chunk0:(128)word) (0,8)):(8)word);
((word_subword (chunk0:(128)word) (8,8)):(8)word);
((word_subword (chunk0:(128)word) (16,8)):(8)word);
((word_subword (chunk0:(128)word) (24,8)):(8)word)]))):(32)word)):(64)word)):(32)word))):(64)word)):(32)word) ((word 248):(32)word))) = 0))) then ((word (pc + 314)):(64)word) else ((word (pc + 163)):(64)word))));
(EventX86POPCNT (((word_zx ((word_zx ((word_zx ((word_zx ((word ((val ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)):(32)word)):(64)word),32));
(EventStore ((word_add (res:(64)word) ((word (4 * outlen0)):(64)word)),32));
(EventLoad ((word_add (table:(64)word) ((word (8 * (val ((word_zx ((word_zx ((word ((val ((word_zx ((word ((bitval (bit 7 ((word_subword (f1bnd:(256)word) (0,8)):(8)word))) + ((2 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (8,8)):(8)word)))) + ((4 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (16,8)):(8)word)))) + ((8 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (24,8)):(8)word)))) + ((16 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (32,8)):(8)word)))) + ((32 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (40,8)):(8)word)))) + ((64 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (48,8)):(8)word)))) + ((128 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (56,8)):(8)word)))) + ((256 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (64,8)):(8)word)))) + ((512 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (72,8)):(8)word)))) + ((1024 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (80,8)):(8)word)))) + ((2048 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (88,8)):(8)word)))) + ((4096 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (96,8)):(8)word)))) + ((8192 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (104,8)):(8)word)))) + ((16384 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (112,8)):(8)word)))) + ((32768 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (120,8)):(8)word)))) + ((65536 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (128,8)):(8)word)))) + ((131072 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (136,8)):(8)word)))) + ((262144 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (144,8)):(8)word)))) + ((524288 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (152,8)):(8)word)))) + ((1048576 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (160,8)):(8)word)))) + ((2097152 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (168,8)):(8)word)))) + ((4194304 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (176,8)):(8)word)))) + ((8388608 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (184,8)):(8)word)))) + ((16777216 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (192,8)):(8)word)))) + ((33554432 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (200,8)):(8)word)))) + ((67108864 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (208,8)):(8)word)))) + ((134217728 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (216,8)):(8)word)))) + ((268435456 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (224,8)):(8)word)))) + ((536870912 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (232,8)):(8)word)))) + ((1073741824 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (240,8)):(8)word)))) + (2147483648 * (bitval (bit 7 ((word_subword (f1bnd:(256)word) (248,8)):(8)word)))))))))))))))))))))))))))))))))))):(32)word)):(64)word)) MOD 256)):(8)word)):(32)word)):(64)word)))):(64)word)),8));
(EventLoad ((word_add (buf:(64)word) ((word (16 * i)):(64)word)),16));
(EventJump (((word (pc + 75)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word (16 * i)):(64)word)):(32)word))) (&256)) = (&(val (word_sub ((word_zx ((word (16 * i)):(64)word)):(32)word) ((word 256):(32)word)))))) \/ ((val (word_sub ((word_zx ((word (16 * i)):(64)word)):(32)word) ((word 256):(32)word))) = 0))) then ((word (pc + 314)):(64)word) else ((word (pc + 75)):(64)word))));
(EventJump (((word (pc + 63)):(64)word),(if (~((~((int_sub (&(val ((word_zx ((word outlen0):(64)word)):(32)word))) (&248)) = (&(val (word_sub ((word_zx ((word outlen0):(64)word)):(32)word) ((word 248):(32)word)))))) \/ ((val (word_sub ((word_zx ((word outlen0):(64)word)):(32)word) ((word 248):(32)word))) = 0))) then ((word (pc + 314)):(64)word) else ((word (pc + 63)):(64)word))))] = (f_ev_loop_eta4 (res:(64)word) (buf:(64)word) (table:(64)word) pc (REJ_MASK_ETA4 (inlist:((8)word)list)) i)))`,
  STRIP_TAC THEN REWRITE_TAC[f_ev_loop_eta4_def] THEN
  W(fun (asl,w) ->
    let assoc_asl = map snd asl in
    let fnd p = find (fun th -> p (concl th)) assoc_asl in
    let tower8_mask8b = fnd (fun c -> is_eq c && rand c=`mask8b:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false)) c) in
    let mask8c_def = fnd (fun c -> is_eq c && rand c=`mask8c:int64`) in
    let mask8d_def = fnd (fun c -> is_eq c && rand c=`mask8d:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false)) c) in
    let mb g =
      if g = 0 then
        fnd (fun c -> is_forall c && can(find_term(fun u->u=`f1bnd:int256`)) c &&
             can(find_term(fun u->u=`8*k`)) c)
      else
        fnd (fun c -> is_forall c && can(find_term(fun u->u=`f1bnd:int256`)) c &&
             can(find_term(fun u->u = mk_binop `( * ):num->num->num` `8` (mk_binop `(+):num->num->num` `k:num` (mk_small_numeral g)))) c) in
    let ol_def = fnd (fun c -> is_eq c && rand c=`outlen0:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA4_BYTES",_)->true|_->false)) c) in
    let a1_def = fnd (fun c -> is_eq c && rand c=`acc1:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA4_BYTES",_)->true|_->false)) c) in
    let a2_def = fnd (fun c -> is_eq c && rand c=`acc2:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA4_BYTES",_)->true|_->false)) c) in
    let a3_def = fnd (fun c -> is_eq c && rand c=`acc3:num` && can(find_term(fun u->match u with Const("REJ_SAMPLE_ETA4_BYTES",_)->true|_->false)) c) in
    let i_le = fnd (fun c -> c = `16 * i <= 256`) in
    let leninl = fnd (fun c -> c = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = fnd (fun c -> is_eq c && (try fst(dest_const(fst(strip_comb(lhand c))))="SUB_LIST" && length(dest_list(rand c))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let links = CONJUNCTS bb in
    let t16m8c = REWRITE_RULE[SYM tower8_mask8b] mask8c_def in
    let t24m8d = REWRITE_RULE[SYM t16m8c] mask8d_def in
    let f0 = MP (MP P0_BRIDGE_ETA4 (mb 0)) (el 0 links) in
    let f1 = MP (MP (MP GATHER_BRIDGE1_ETA4 tower8_mask8b) (mb 8)) (el 1 links) in
    let f2 = MP (MP (MP GATHER_BRIDGE2_ETA4 t16m8c) (mb 16)) (el 2 links) in
    let f3 = MP (MP (MP GATHER_BRIDGE3_ETA4 t24m8d) (mb 24)) (el 3 links) in
    let so = TRANS (SYM ol_def) (REWRITE_RULE[ARITH_RULE `2*(16*i)=32*i`] (SPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4)) in
    let s1 = TRANS (SYM a1_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+4)=32*i+8`] (SPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE_ETA4)) in
    let s2 = TRANS (SYM a2_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+8)=32*i+16`] (SPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE_ETA4)) in
    let s3 = TRANS (SYM a3_def) (REWRITE_RULE[ARITH_RULE `2*(16*i+12)=32*i+24`] (SPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE_ETA4)) in
    let niblen0_gen = prove
     (`LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i,4) inlist):int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA4 (inlist:byte list)))`,
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED] THEN
      REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2*(16*i)=32*i`; ARITH_RULE `2*4=8`]) in
    let niblen0 = REWRITE_RULE[el 0 links] niblen0_gen in
    (* niblen2 (group-2): REQUIRED because eta4's mg3 @pc+268 is a COND (over    *)
    (* acc2 + group-2 niblen), unlike eta2's self-jump.  Only meaningful once     *)
    (* f_ev_loop_eta4_def has mg3 as a COND (not a self-jump).                   *)
    let niblen2_gen = prove
     (`LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(16*i+8,4) inlist):int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+16,8)(REJ_MASK_ETA4 (inlist:byte list)))`,
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED] THEN
      REWRITE_TAC[REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2*(16*i+8)=32*i+16`; ARITH_RULE `2*4=8`]) in
    let niblen2 = REWRITE_RULE[el 2 links] niblen2_gen in
    let facts = [f0;f1;f2;f3;so;s1;s2;s3;niblen0;niblen2] in
    CONV_TAC(LAND_CONV(GEN_REWRITE_CONV TOP_DEPTH_CONV facts THENC REWRITE_CONV[]))) THEN
  REFL_TAC);;

(* ------------------------------------------------------------------------- *)
(* eta4 SAFE-cluster containment prerequisites + MEMACCESS_F_EV_LOOP_ETA4.     *)
(* Ports of the eta2 containment lemmas. eta-neutral: NUM_ACCEPTED_PREFIX_MONO,*)
(* STORE_CONTAINED, PACK_MASK8_MOD256. eta4 constant change (buf window        *)
(* 136 -> 272): BUF_CONTAINED_ETA4.                                           *)
(* ------------------------------------------------------------------------- *)

let NUM_ACCEPTED_PREFIX_MONO = prove
 (`!mask:bool list a b. a <= b
     ==> NUM_ACCEPTED(SUB_LIST(0,a) mask) <= NUM_ACCEPTED(SUB_LIST(0,b) mask)`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `SUB_LIST(0,b) (mask:bool list) =
                APPEND (SUB_LIST(0,a) mask) (SUB_LIST(a,b-a) mask)` SUBST1_TAC THENL
   [MP_TAC(ISPECL [`mask:bool list`; `a:num`; `b - a`; `0`] SUB_LIST_SPLIT) THEN
    ASM_SIMP_TAC[ARITH_RULE `a <= b ==> a + (b - a) = b`; ADD_CLAUSES];
    REWRITE_TAC[NUM_ACCEPTED_APPEND] THEN ARITH_TAC]);;

let STORE_CONTAINED = prove
 (`!(res:int64) cnt. cnt <= 248
     ==> contained_modulo (2 EXP 64)
           (val(word_add res (word(4 * cnt))),32) (val res,1024)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

(* eta4: buf window is 272 (buflen 272), so the head-guard bound is 16*j+16<=272. *)
let BUF_CONTAINED_ETA4 = prove
 (`!(buf:int64) j. 16 * j + 16 <= 272
     ==> contained_modulo (2 EXP 64)
           (val(word_add buf (word(16 * j))),16) (val buf,272)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

let PACK_MASK8_MOD256 = prove
 (`!bs:bool list. PACK_MASK8 bs = PACK_MASK8 bs MOD 256`,
  GEN_TAC THEN MATCH_MP_TAC(GSYM MOD_LT) THEN REWRITE_TAC[PACK_MASK8_BOUND]);;

(* MEMACCESS_F_EV_LOOP_ETA4: memaccess of one folded loop iteration.  Port of  *)
(* eta2 MEMACCESS_F_EV_LOOP_ETA2: buf window 136 -> 272,                        *)
(* f_ev_loop_eta2_def -> f_ev_loop_eta4_def, BUF_CONTAINED -> BUF_CONTAINED_ETA4.*)
let MEMACCESS_F_EV_LOOP_ETA4 = prove
 (`!res buf table pc mask j.
     16 * j + 16 <= 272 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * j + 24) mask) <= 248
     ==> memaccess_inbounds (f_ev_loop_eta4 res buf table pc mask j)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * j) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * j + 8) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * j + 16) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [REPEAT CONJ_TAC THEN
    TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * j + 24) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[f_ev_loop_eta4_def; memaccess_inbounds; ALL; EX; FST; SND] THEN
  ONCE_REWRITE_TAC[PACK_MASK8_MOD256] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC STORE_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ1_TAC THEN MATCH_MP_TAC BUF_CONTAINED_ETA4 THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN
    MATCH_ACCEPT_TAC TABLE_IDX_LT_256]);;

(* ------------------------------------------------------------------------- *)
(* eta-neutral SAFE loop-side lemmas. SAFE_THREAD_EVENTS_STEP and             *)
(* MEMACCESS_ENUM_ACC are generic over d:num->(uarch_event)list (eta2 ports); *)
(* MEMACCESS_ENUM_LOOP_ETA4 is the eta4 loop-side memaccess recovery.         *)
(* Dependency order STES -> ACC -> ENUM_LOOP (ENUM_LOOP uses ACC).            *)
(* ------------------------------------------------------------------------- *)

let SAFE_THREAD_EVENTS_STEP = prove
 (`!(d:num->(uarch_event)list) i e.
      APPEND (d i) (APPEND (ENUMERATEL i d) e) = APPEND (ENUMERATEL (i+1) d) e`,
  REWRITE_TAC[ENUMERATEL_ADD1; APPEND_ASSOC]);;

let MEMACCESS_ENUM_ACC = prove
 (`!(d:num->(uarch_event)list) rr wr J.
     (!j. j < J ==> memaccess_inbounds (d j) rr wr)
     ==> memaccess_inbounds (ENUMERATEL J d) rr wr`,
  REPLICATE_TAC 3 GEN_TAC THEN INDUCT_TAC THENL
   [REWRITE_TAC[ENUMERATEL; memaccess_inbounds; ALL];
    REWRITE_TAC[ADD1] THEN ONCE_REWRITE_TAC[ENUMERATEL_ADD1] THEN
    REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN STRIP_TAC THEN CONJ_TAC THENL
     [FIRST_X_ASSUM MATCH_MP_TAC THEN ARITH_TAC;
      FIRST_X_ASSUM MATCH_MP_TAC THEN GEN_TAC THEN DISCH_TAC THEN
      FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC]]);;

let MEMACCESS_ENUM_LOOP_ETA4 = prove
 (`!res buf table inlist pc N.
      ~(N = 0) /\ 16 * (N - 1) <= 256 /\
      (!m. m < N ==> 16 * m <= 256 /\
           LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*m) inlist):int16 list) <= 248)
      ==> memaccess_inbounds
            (ENUMERATEL (N-1) (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 inlist)))
            [buf,272; table,2048] [res,1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC MEMACCESS_ENUM_ACC THEN
  X_GEN_TAC `j:num` THEN DISCH_TAC THEN
  MATCH_MP_TAC MEMACCESS_F_EV_LOOP_ETA4 THEN
  CONJ_TAC THENL
   [MAP_EVERY UNDISCH_TAC [`j < N - 1`; `16 * (N - 1) <= 256`] THEN ARITH_TAC;
    MATCH_MP_TAC LE_TRANS THEN
    EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32*(j+1))(REJ_MASK_ETA4 inlist))` THEN
    CONJ_TAC THENL
     [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
      MP_TAC(SPECL[`inlist:byte list`;`16*(j+1)`] STORE_BRIDGE_ETA4) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (j + 1)) = 32 * (j + 1)`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN
      REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `j + 1` o check(is_forall o concl)) THEN
      ANTS_TAC THENL
       [UNDISCH_TAC `j < N - 1` THEN UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC;
        REWRITE_TAC[] THEN STRIP_TAC THEN FIRST_ASSUM ACCEPT_TAC]]]);;

(* ------------------------------------------------------------------------- *)
(* eta4 SAFE exit-block step (a) — head-guard segment.                        *)
(* pc+52 @ pos 16N=272  ->  pc+314 (scalar tail), concrete PUBLIC events.     *)
(* Port of eta2 LEG1B_HEADGUARD_SAFE_ETA2. The 4-instruction head-guard emits *)
(* exactly two public EventJumps — count-guard (pc+63) not-taken, buffer-guard*)
(* (pc+75) taken -> pc+314.                                                   *)
(* ------------------------------------------------------------------------- *)

let f_ev_headguard_eta4 = define
 `f_ev_headguard_eta4 (pc:num) =
    [EventJump (word (pc + 75),word (pc + 314));
     EventJump (word (pc + 63),word (pc + 63))]`;;

let LEG1B_HEADGUARD_SAFE_ETA4 = prove(
  (* statement: OFFSET-arm head-guard, q56/q318 with 16N->272 + concrete events,
     antecedent+frame lifted directly from EXIT_OFFSET_MS. *)
  (let sv56,body56 = dest_abs q56_ms in
   let sv318,body318 = dest_abs q318_ms in
   let exoff = snd(strip_forall(exit_offset_ms_tm)) in
   let ens = snd(dest_imp exoff) in
   let frame = rand ens in
   let ens_hd = rator(rator(rator ens)) in
   let q52_safe = mk_abs(sv56,
     mk_conj(subst[`272`,`16 * N`] (lhand body56),
             `read events (s:x86state) = ec`)) in
   let q314_safe = mk_abs(sv318,
     mk_conj(subst[`272`,`16 * N`] (lhand body318),
             `read events (s:x86state) = APPEND (f_ev_headguard_eta4 pc) ec`)) in
   list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`;`ec:(uarch_event)list`],
     mk_imp(lhand exoff,
       mk_comb(mk_comb(mk_comb(ens_hd, q52_safe), q314_safe), frame)))),
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,272) inlist):int32 list) <= 248` ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    SUBST1_TAC(SYM(ASSUME `16 * N = 272`)) THEN FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
  ENSURES_INIT_TAC "s0" THEN
  SUBGOAL_THEN
   `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,272) inlist):int32 list)):int64):int32)):int - &248 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,272) inlist):int32 list)):int64):int32) (word 248):int32))) \/ val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,272) inlist):int32 list)):int64):int32) (word 248):int32) = 0`
   ASSUME_TAC THENL
   [MATCH_MP_TAC JA_NOT_TAKEN_LE THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
   `~(~(&(val(word_zx(word(272):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(272):int64):int32) (word 256):int32))) \/ val(word_sub(word_zx(word(272):int64):int32) (word 256):int32) = 0)`
   ASSUME_TAC THENL
   [MATCH_MP_TAC JA_TAKEN_GT THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--4) THEN
  ENSURES_FINAL_STATE_TAC THEN
  ASM_REWRITE_TAC[f_ev_headguard_eta4; APPEND]);;

(* ========================================================================= *)
(* eta4 SAFE scalar-tail (constant-time) lemmas.                              *)
(* Order: body-safe -> tail def+FEV -> run-safe -> memaccess+AT_P corollary.  *)
(* ========================================================================= *)

(* --- eta4 SAFE scalar-tail per-byte BODY (step (b)(ii)) --- *)
(* pc+314 -> pc+314 consuming input byte p, with CONCRETE PUBLIC events.       *)
(* f_ev_scalar_body_eta4 is a COND tree over the two PUBLIC nibble conditions  *)
(* (low<9, high<9). eta4 differs structurally from eta2 — ONE EventLoad,       *)
(* pcs {402,385,371,349,329,321,314}.                                          *)
(* Proof = SCALAR_TAIL_BODY_MEMSAFE with 2 swaps:                              *)
(*   (a) SCALAR_BODY_SETUP_MS -> SCALAR_BODY_SETUP  (no-strip, concrete events) *)
(*   (b) DISCHARGE_MEMSAFE_ASM_TAC -> SAFE_SCALAR_DISCHARGE_TAC_ETA4 (x4).      *)
(* ========================================================================= *)

let f_ev_scalar_body_eta4 = define
 `f_ev_scalar_body_eta4 (res:int64) (buf:int64) (pc:num) (inlist:byte list)
                        (p:num) (outlen0:num) =
    if val(EL p inlist) MOD 16 < 9 then
      (if val(EL p inlist) DIV 16 < 9 then
         [EventJump (word (pc + 402),word (pc + 314));
          EventStore (word_add res (word (4 * (outlen0 + 1))),4);
          EventJump (word (pc + 385),word (pc + 385));
          EventJump (word (pc + 371),word (pc + 371));
          EventStore (word_add res (word (4 * val (word outlen0:int64))),4);
          EventJump (word (pc + 349),word (pc + 349));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 329),word (pc + 329));
          EventJump (word (pc + 321),word (pc + 321))]
       else
         [EventJump (word (pc + 385),word (pc + 314));
          EventJump (word (pc + 371),word (pc + 371));
          EventStore (word_add res (word (4 * val (word outlen0:int64))),4);
          EventJump (word (pc + 349),word (pc + 349));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 329),word (pc + 329));
          EventJump (word (pc + 321),word (pc + 321))])
    else
      (if val(EL p inlist) DIV 16 < 9 then
         [EventJump (word (pc + 402),word (pc + 314));
          EventStore (word_add res (word (4 * outlen0)),4);
          EventJump (word (pc + 385),word (pc + 385));
          EventJump (word (pc + 349),word (pc + 371));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 329),word (pc + 329));
          EventJump (word (pc + 321),word (pc + 321))]
       else
         [EventJump (word (pc + 385),word (pc + 314));
          EventJump (word (pc + 349),word (pc + 371));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 329),word (pc + 329));
          EventJump (word (pc + 321),word (pc + 321))])`;;

let SCALAR_TAIL_BODY_SAFE_ETA4 =
  (* Concrete-events discharge (replaces DISCHARGE_MEMSAFE_ASM_TAC). Goal at
     each branch end: read events sN = APPEND (f_ev_scalar_body_eta4 ...) e /\
     memaccess_inbounds (...) [buf,272;table,2048] [res,1024]. Unfold the def;
     the branch conds (in the asl) reduce the COND; events-eq closes by APPEND
     + the stepped events assumption; memaccess via CONTAINED_ASM_TAC. *)
  let SAFE_SCALAR_DISCHARGE_TAC_ETA4 =
    REWRITE_TAC[f_ev_scalar_body_eta4] THEN
    CONJ_TAC THENL
     [ASM_REWRITE_TAC[APPEND];
      ASM_REWRITE_TAC[] THEN
      REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
      REPEAT CONJ_TAC THEN
      TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                  CONTAINED_ASM_TAC) THEN NO_TAC)] in
  (* Build the SAFE goal term: concrete events conjoined onto SCALAR_TAIL_BODY's
     pre & post (events OUTERMOST), universally over the extra `e`. outlen0 slot
     uses the statement var `L`; the setup substitutes L->outlen0. *)
  let scalar_body_safe_eta4_tm =
    let qvars, body = strip_forall scalar_tail_body_tm in
    let hyps_tm, ens = dest_imp body in
    let ensc, ppf = strip_comb ens in
    let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
    let sv, preb = dest_abs pre in
    let sv2, postb = dest_abs post in
    let fev = `f_ev_scalar_body_eta4 res buf pc (inlist:byte list) p L` in
    let eq_pre = `read events (s:x86state) = e` in
    let eq_post = mk_conj
       (mk_eq(`read events (s:x86state)`, mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)),
        list_mk_comb(`memaccess_inbounds:(uarch_event)list->(int64#num)list->(int64#num)list->bool`,
          [fev; `[(buf:int64),272; (table:int64),2048]`; `[(res:int64),1024]`])) in
    let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] eq_pre)) in
    let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] eq_post)) in
    let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
    list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens')) in
  prove
   (scalar_body_safe_eta4_tm,
    SCALAR_BODY_SETUP THEN
    ASM_CASES_TAC `val(EL p (inlist:byte list)) MOD 16 < 9` THENL
     [(* ===== ACCEPT-LOW (low<9): step to pc+364, store low, to pc+379 ===== *)
      SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 9):int32)))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
      X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (9--14) THEN DISCARD_OLDSTATE_TAC "s14" THEN
      SUBGOAL_THEN `outlen0 + 1 < 256` ASSUME_TAC THENL
       [REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th->let c=concl th in c=`outlen0<256`||c=`val(EL p (inlist:byte list)) MOD 16 < 9`||c=`~(outlen0=255/\val(EL p (inlist:byte list)) MOD 16 < 9)`))) THEN ARITH_TAC; ALL_TAC] THEN
      FIRST_X_ASSUM(fun th -> let c=concl th in
         if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s14:x86state`))c
         then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC (ASSUME `outlen0<256`)] th) else NO_TAC) THEN
      SUBGOAL_THEN `~(&(val(word_zx(word(outlen0+1):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(outlen0+1):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
      X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (15--18) THEN
      RULE_ASSUM_TAC(REWRITE_RULE[R11_NIBBLE_VAL]) THEN DISCARD_OLDSTATE_TAC "s18" THEN
      ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 9` THENL
       [(* ACCEPT-ACCEPT *)
        SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 9):int32)))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (19--22) THEN
        SUBGOAL_THEN `val(word(outlen0+1):int64) = outlen0+1` ASSUME_TAC THENL
         [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0+1<256`) THEN ARITH_TAC; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (23--25) THEN DISCARD_OLDSTATE_TAC "s25" THEN
        FIRST_X_ASSUM(fun th -> let c=concl th in
           if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s25:x86state`))c
           then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC (ASSUME `outlen0+1<256`)] th) else NO_TAC) THEN
        ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 2` ASSUME_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_BOTH) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
          DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
        ASM_REWRITE_TAC[ARITH_RULE `(outlen0+1)+1 = outlen0+2`] THEN
        CONJ_TAC THENL
         [CONJ_TAC THENL
         [RCX_INC_TAC;
          SUBGOAL_THEN `REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist) =
             APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                    [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32;
                     word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]` SUBST1_TAC THENL
           [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_BOTH) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `4 * (outlen0 + 2) = 4 * outlen0 + 8` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
          MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s25:x86state`;
             `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list`;
             `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32;
               word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]`;
             `4*outlen0`; `8`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
          ANTS_TAC THENL
           [REWRITE_TAC[DIMINDEX_32] THEN
            FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN SUBST1_TAC THEN CONJ_TAC THENL
           [FIRST_ASSUM ACCEPT_TAC;
            GEN_REWRITE_TAC (RAND_CONV o RAND_CONV) [GSYM(REWRITE_CONV[APPEND] `APPEND [a:int32] [b:int32]`)] THEN
            SUBGOAL_THEN `(8:num) = 4 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
            MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `word_add res (word(4*outlen0)):int64`; `s25:x86state`;
               `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]`;
               `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]`;
               `4`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
            ANTS_TAC THENL [REWRITE_TAC[DIMINDEX_32; LENGTH] THEN ARITH_TAC; ALL_TAC] THEN
            DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
            SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
             [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`s25:x86state`))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c
               then ASSUME_TAC(REWRITE_RULE[ASSUME `val(word outlen0:int64) = outlen0`; MATCH_MP LO_STORE_VAL (ASSUME `val(EL p (inlist:byte list)) MOD 16 < 9`)] th) else NO_TAC) THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`s25:x86state`))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c
               then ASSUME_TAC(REWRITE_RULE[MATCH_MP HI_STORE_VAL (ASSUME `val(EL p (inlist:byte list)) DIV 16 < 9`)] th) else NO_TAC) THEN
            CONJ_TAC THENL
             [FIRST_X_ASSUM(fun th -> let c=concl th in
                 if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c)
                 then MP_TAC th else NO_TAC) THEN
              STORE4_FROM_SPEC `s25:x86state` `word_add res (word(4 * outlen0)):int64`;
              SUBGOAL_THEN `word_add (word_add res (word (4 * outlen0))) (word 4):int64 = word_add res (word (4 * (outlen0+1)))` SUBST1_TAC THENL
               [CONV_TAC WORD_RULE; ALL_TAC] THEN
              FIRST_X_ASSUM(fun th -> let c=concl th in
                 if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c && not(can(find_term is_cond)c)
                 then MP_TAC th else NO_TAC) THEN
              STORE4_FROM_SPEC `s25:x86state` `word_add res (word(4 * (outlen0+1))):int64`]]];
          SAFE_SCALAR_DISCHARGE_TAC_ETA4];
        (* ===== LO-only (low<9, high>=9): jae pc+383 taken -> pc+314 =====    *)
        SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 9):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL
           [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) DIV 16 < 9)`) THEN ARITH_TAC;
            MP_TAC(ISPEC `EL p (inlist:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
            MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] DIV_LE) THEN ARITH_TAC]; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (19--20) THEN DISCARD_OLDSTATE_TAC "s20" THEN
        ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 1` ASSUME_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_LO) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
          DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
         [CONJ_TAC THENL
         [RCX_INC_TAC;
          SUBGOAL_THEN `REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist) =
             APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                    [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]` SUBST1_TAC THENL
           [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_LO) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `4 * (outlen0 + 1) = 4 * outlen0 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
          MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s20:x86state`;
             `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list`;
             `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]`;
             `4*outlen0`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
          ANTS_TAC THENL
           [REWRITE_TAC[DIMINDEX_32] THEN
            FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
          CONJ_TAC THENL
           [FIRST_ASSUM ACCEPT_TAC;
            SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
             [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`s20:x86state`))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c
               then ASSUME_TAC(REWRITE_RULE[ASSUME `val(word outlen0:int64) = outlen0`; MATCH_MP LO_STORE_VAL (ASSUME `val(EL p (inlist:byte list)) MOD 16 < 9`)] th) else NO_TAC) THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c)
               then MP_TAC th else NO_TAC) THEN
            STORE4_FROM_SPEC `s20:x86state` `word_add res (word(4 * outlen0)):int64`]];
          SAFE_SCALAR_DISCHARGE_TAC_ETA4]];
      (* ===== REJECT-LOW (low>=9): jae pc+347 taken -> pc+371 =====           *)
      SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 9):int32))` ASSUME_TAC THENL
       [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL
         [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) MOD 16 < 9)`) THEN ARITH_TAC;
          MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] MOD_LT_EQ) THEN ARITH_TAC]; ALL_TAC] THEN
      X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (9--12) THEN
      RULE_ASSUM_TAC(REWRITE_RULE[R11_NIBBLE_VAL]) THEN DISCARD_OLDSTATE_TAC "s12" THEN
      ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 9` THENL
       [(* HI-only (low>=9, high<9): jae pc+383 not taken -> store -> pc+314 *)
        SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 9):int32)))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (13--16) THEN
        SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
         [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `outlen0<256`) THEN ARITH_TAC; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (17--19) THEN DISCARD_OLDSTATE_TAC "s19" THEN
        FIRST_X_ASSUM(fun th -> let c=concl th in
           if is_eq c && can(find_term(fun t->t=`RAX`))c && can(find_term(fun t->t=`s19:x86state`))c
           then ASSUME_TAC(REWRITE_RULE[MATCH_MP RAX_INC (ASSUME `outlen0<256`)] th) else NO_TAC) THEN
        ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0 + 1` ASSUME_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_HI) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
          DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
         [CONJ_TAC THENL
         [RCX_INC_TAC;
          SUBGOAL_THEN `REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist) =
             APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                    [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]` SUBST1_TAC THENL
           [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_HI) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
          SUBGOAL_THEN `4 * (outlen0 + 1) = 4 * outlen0 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
          MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s19:x86state`;
             `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list`;
             `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]`;
             `4*outlen0`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
          ANTS_TAC THENL
           [REWRITE_TAC[DIMINDEX_32] THEN
            FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC) THEN ARITH_TAC; ALL_TAC] THEN
          DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
          CONJ_TAC THENL
           [FIRST_ASSUM ACCEPT_TAC;
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`s19:x86state`))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c
               then ASSUME_TAC(REWRITE_RULE[ASSUME `val(word outlen0:int64) = outlen0`; MATCH_MP HI_STORE_VAL (ASSUME `val(EL p (inlist:byte list)) DIV 16 < 9`)] th) else NO_TAC) THEN
            FIRST_X_ASSUM(fun th -> let c=concl th in
               if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) DIV 16`))c && not(can(find_term is_cond)c)
               then MP_TAC th else NO_TAC) THEN
            STORE4_FROM_SPEC `s19:x86state` `word_add res (word(4 * outlen0)):int64`]];
          SAFE_SCALAR_DISCHARGE_TAC_ETA4];
        (* NONE (low>=9, high>=9): jae pc+383 taken -> pc+314, no store        *)
        SUBGOAL_THEN `&(val(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) DIV 16):int64):int32) (word 9):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL
           [MP_TAC(ASSUME `~(val(EL p (inlist:byte list)) DIV 16 < 9)`) THEN ARITH_TAC;
            MP_TAC(ISPEC `EL p (inlist:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
            MP_TAC(SPECL[`val(EL p (inlist:byte list))`;`16`] DIV_LE) THEN ARITH_TAC]; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (13--14) THEN DISCARD_OLDSTATE_TAC "s14" THEN
        ENSURES_FINAL_STATE_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist):int32 list) = outlen0` ASSUME_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LEN_STEP_NONE) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [ASM_ARITH_TAC; ASM_REWRITE_TAC[]]; ALL_TAC] THEN
          DISCH_THEN(fun th->REWRITE_TAC[th]) THEN
          FIRST_ASSUM(fun th->if concl th=`LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist):int32 list) = outlen0` then REWRITE_TAC[th] else NO_TAC); ALL_TAC] THEN
        SUBGOAL_THEN `REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p+1) inlist):int32 list = REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist)` ASSUME_TAC THENL
         [MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_NONE) THEN ASM_REWRITE_TAC[] THEN DISCH_THEN MATCH_ACCEPT_TAC; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONJ_TAC THENL [RCX_INC_TAC; SAFE_SCALAR_DISCHARGE_TAC_ETA4]]]);;

(* ========================================================================= *)
(* f_ev_scalar_tail_eta4 + the 4 FEV_TAIL reduction lemmas.                    *)
(* The public event trace of the eta4 scalar tail (byte loop pc+314 -> pc+402),*)
(* by recursion on the byte budget d.  Terminals mirror eta2's                 *)
(* f_ev_scalar_tail under the pc map {410->321, 418->329, 438->349, 481->371,  *)
(* 542->402}, offset check p=272, midbyte cond val<9, store res+1020 (=4*255)   *)
(* unchanged.  Depends on f_ev_scalar_body_eta4 (the body-safe lemma above).    *)
(* ========================================================================= *)

let f_ev_scalar_tail_eta4 = define
 `(f_ev_scalar_tail_eta4 0 (res:int64) (buf:int64) (pc:num) (inlist:byte list) (p:num) =
     (if 256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)
      then [EventJump (word (pc + 321),word (pc + 402))]
      else [EventJump (word (pc + 329),word (pc + 402));
            EventJump (word (pc + 321),word (pc + 321))])) /\
  (f_ev_scalar_tail_eta4 (SUC d) (res:int64) (buf:int64) (pc:num) (inlist:byte list) (p:num) =
     (if 256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)
      then [EventJump (word (pc + 321),word (pc + 402))]
      else if p = 272
      then [EventJump (word (pc + 329),word (pc + 402));
            EventJump (word (pc + 321),word (pc + 321))]
      else if LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
              val(EL p inlist) MOD 16 < 9
      then [EventJump (word (pc + 371),word (pc + 402));
            EventStore (word_add res (word 1020),4);
            EventJump (word (pc + 349),word (pc + 349));
            EventLoad (word_add buf (word p),1);
            EventJump (word (pc + 329),word (pc + 329));
            EventJump (word (pc + 321),word (pc + 321))]
      else APPEND (f_ev_scalar_tail_eta4 d res buf pc inlist (p+1))
                  (f_ev_scalar_body_eta4 res buf pc inlist p
                     (LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)))))`;;

(* -- Per-terminal reduction lemmas (conditional rewrites, uniform over d). -- *)
let FEV_TAIL_COUNT_ETA4 = prove
 (`!d res buf pc (inlist:byte list) p.
     256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)
     ==> f_ev_scalar_tail_eta4 d res buf pc inlist p =
         [EventJump (word (pc + 321),word (pc + 402))]`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  STRUCT_CASES_TAC (SPEC `d:num` num_CASES) THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail_eta4]);;

let FEV_TAIL_OFFSET_ETA4 = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     p = 272
     ==> f_ev_scalar_tail_eta4 d res buf pc inlist p =
         [EventJump (word (pc + 329),word (pc + 402));
          EventJump (word (pc + 321),word (pc + 321))]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  STRUCT_CASES_TAC (SPEC `d:num` num_CASES) THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail_eta4]);;

let FEV_TAIL_MIDBYTE_ETA4 = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     ~(p = 272) /\
     LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
     val(EL p inlist) MOD 16 < 9
     ==> f_ev_scalar_tail_eta4 (SUC d) res buf pc inlist p =
         [EventJump (word (pc + 371),word (pc + 402));
          EventStore (word_add res (word 1020),4);
          EventJump (word (pc + 349),word (pc + 349));
          EventLoad (word_add buf (word p),1);
          EventJump (word (pc + 329),word (pc + 329));
          EventJump (word (pc + 321),word (pc + 321))]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail_eta4]);;

let FEV_TAIL_REC_ETA4 = prove
 (`!d res buf pc (inlist:byte list) p.
     ~(256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)) /\
     ~(p = 272) /\
     ~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\
       val(EL p inlist) MOD 16 < 9)
     ==> f_ev_scalar_tail_eta4 (SUC d) res buf pc inlist p =
         APPEND (f_ev_scalar_tail_eta4 d res buf pc inlist (p+1))
                (f_ev_scalar_body_eta4 res buf pc inlist p
                   (LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)))`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[f_ev_scalar_tail_eta4]);;

(* ========================================================================= *)
(* SCALAR_TAIL_RUN_SAFE_ETA4 — the SAFE (constant-time) scalar tail run         *)
(* (byte loop pc+314 -> pc+402) with CONCRETE PUBLIC events                     *)
(* (f_ev_scalar_tail_eta4).  Merges the eta4 VALUE SCALAR_TAIL_RUN stepping     *)
(* with the eta2 SCALAR_TAIL_RUN_SAFE_ETA2 events-injection.  Terminals close   *)
(* by FEV_TAIL_{COUNT,OFFSET,MIDBYTE}_ETA4 + APPEND; the recursive leg          *)
(* composes SCALAR_TAIL_BODY_SAFE_ETA4 + IH (events e' =                        *)
(* APPEND (f_ev_scalar_body_eta4 .. p L) e) via ENSURES_SEQUENCE @ pc+314,      *)
(* R pre-rewritten via FEV_TAIL_REC_ETA4 + GSYM APPEND_ASSOC.                    *)
(* ========================================================================= *)

let SCALAR_TAIL_RUN_SAFE_ETA4 =
  let rec conj_append_right t ev =
    if is_conj t then
      let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
    else mk_conj(t, ev) in
  let scalar_run_safe_eta4_tm =
    let qvars, body = strip_forall scalar_tail_run_tm in
    let hyps_tm, ens = dest_imp body in
    let ensc, ppf = strip_comb ens in
    let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
    let sv, preb = dest_abs pre in
    let sv2, postb = dest_abs post in
    let fev = `f_ev_scalar_tail_eta4 d res buf pc (inlist:byte list) p` in
    let eq_pre = `read events (s:x86state) = e` in
    let eq_post = mk_eq(`read events (s:x86state)`,
                        mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)) in
    let pre' = mk_abs(sv, conj_append_right preb (vsubst[sv,`s:x86state`] eq_pre)) in
    let post' = mk_abs(sv2, conj_append_right postb (vsubst[sv2,`s:x86state`] eq_post)) in
    let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
    list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens')) in
  prove
   (scalar_run_safe_eta4_tm,
    INDUCT_TAC THENL
     [(* ================= BASE CASE: d = 0 => p = 272 ================= *)
      REPEAT GEN_TAC THEN STRIP_TAC THEN
      SUBGOAL_THEN `p = 272` SUBST_ALL_TAC THENL
       [REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in c=`272 - p <= 0` || c=`p <= 272`))) THEN ARITH_TAC; ALL_TAC] THEN
      MP_TAC(SPEC `inlist:byte list` SUB_LIST_BYTE_272) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
      RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `SUB_LIST(0,272) (inlist:byte list) = inlist`]) THEN
      REWRITE_TAC[ASSUME `SUB_LIST(0,272) (inlist:byte list) = inlist`] THEN
      ASM_CASES_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = 256` THENL
       [(* --- BASE COUNT-EXIT: outlen = 256 --- *)
        MP_TAC(SPEC `REJ_SAMPLE_ETA4_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
        ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
        REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = 256`] THEN
        REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = REJ_SAMPLE_ETA4_BYTES inlist`] THEN
        ENSURES_INIT_TAC "s0" THEN
        SUBGOAL_THEN `&(val(word_zx(word 256:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 256:int64):int32) (word 256):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--3) THEN
        ENSURES_FINAL_STATE_TAC THEN
        SUBGOAL_THEN `f_ev_scalar_tail_eta4 0 res buf pc (inlist:byte list) 272 = [EventJump (word (pc + 321),word (pc + 402))]` SUBST1_TAC THENL
         [MATCH_MP_TAC FEV_TAIL_COUNT_ETA4 THEN
          SUBGOAL_THEN `SUB_LIST(0,272)(inlist:byte list) = inlist` SUBST1_TAC THENL
           [MATCH_MP_TAC SUB_LIST_BYTE_272 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
          ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = 256`] THEN
        REWRITE_TAC[LENGTH_BUTLAST_TMC] THEN ASM_REWRITE_TAC[APPEND];
        (* --- BASE OFFSET-EXIT: outlen < 256, p = 272 ---                     *)
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) < 256` ASSUME_TAC THENL
         [REPEAT(FIRST_X_ASSUM(MP_TAC o check (fun th -> let c=concl th in c=`LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) <= 256` || c=`~(LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = 256)`))) THEN ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPEC `REJ_SAMPLE_ETA4_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
        ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
        REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = REJ_SAMPLE_ETA4_BYTES inlist`] THEN
        ENSURES_INIT_TAC "s0" THEN
        SUBGOAL_THEN `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list)):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list)):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
        SUBGOAL_THEN `&(val(word_zx(word 272:int64):int32)):int - &272 = &(val(word_sub(word_zx(word 272:int64):int32) (word 272):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--5) THEN
        ENSURES_FINAL_STATE_TAC THEN
        SUBGOAL_THEN `f_ev_scalar_tail_eta4 0 res buf pc (inlist:byte list) 272 =
            [EventJump (word (pc + 329),word (pc + 402)); EventJump (word (pc + 321),word (pc + 321))]` SUBST1_TAC THENL
         [MATCH_MP_TAC FEV_TAIL_OFFSET_ETA4 THEN
          SUBGOAL_THEN `SUB_LIST(0,272)(inlist:byte list) = inlist` SUBST1_TAC THENL
           [MATCH_MP_TAC SUB_LIST_BYTE_272 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
          REWRITE_TAC[NOT_LE] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        REWRITE_TAC[LENGTH_BUTLAST_TMC] THEN ASM_REWRITE_TAC[APPEND]];
      (* ================= STEP CASE: SUC d =================                  *)
      REPEAT GEN_TAC THEN STRIP_TAC THEN
      ASM_CASES_TAC `256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)` THENL
       [(* --- STEP COUNT-EXIT: outlen >= 256 (=256 by invariant) --- *)
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256` ASSUME_TAC THENL
         [ASM_ARITH_TAC; ALL_TAC] THEN
        MP_TAC(SPECL [`inlist:byte list`; `p:num`] SUB_LIST_256_PREFIX_GE) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
        MP_TAC(SPEC `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list` SUB_LIST_256_LE) THEN
        ANTS_TAC THENL [ASM_REWRITE_TAC[LE_REFL]; ALL_TAC] THEN DISCH_TAC THEN
        SUBGOAL_THEN `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)` ASSUME_TAC THENL
         [ASM_REWRITE_TAC[]; ALL_TAC] THEN
        REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist)`;
                    ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256`] THEN
        ENSURES_INIT_TAC "s0" THEN
        SUBGOAL_THEN `&(val(word_zx(word 256:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 256:int64):int32) (word 256):int32))` ASSUME_TAC THENL
         [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
        X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--3) THEN
        ENSURES_FINAL_STATE_TAC THEN
        SUBGOAL_THEN `f_ev_scalar_tail_eta4 (SUC d) res buf pc (inlist:byte list) p = [EventJump (word (pc + 321),word (pc + 402))]` SUBST1_TAC THENL
         [MATCH_MP_TAC FEV_TAIL_COUNT_ETA4 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
        ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
        REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 256`; LENGTH_BUTLAST_TMC] THEN
        ASM_REWRITE_TAC[APPEND];
        (* --- not count-exit: outlen < 256 ---                                *)
        SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) < 256` ASSUME_TAC THENL
         [ASM_ARITH_TAC; ALL_TAC] THEN
        ASM_CASES_TAC `p = 272` THENL
         [(* --- STEP OFFSET-EXIT: p = 272 --- *)
          FIRST_X_ASSUM(SUBST_ALL_TAC o check (fun th -> concl th = `p = 272`)) THEN
          MP_TAC(SPEC `inlist:byte list` SUB_LIST_BYTE_272) THEN ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
          RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `SUB_LIST(0,272) (inlist:byte list) = inlist`]) THEN
          REWRITE_TAC[ASSUME `SUB_LIST(0,272) (inlist:byte list) = inlist`] THEN
          MP_TAC(SPEC `REJ_SAMPLE_ETA4_BYTES inlist:int32 list` SUB_LIST_256_LE) THEN
          ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
          REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) = REJ_SAMPLE_ETA4_BYTES inlist`] THEN
          ENSURES_INIT_TAC "s0" THEN
          SUBGOAL_THEN `~(&(val(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list)):int64):int32)):int - &256 = &(val(word_sub(word_zx(word(LENGTH(REJ_SAMPLE_ETA4_BYTES inlist:int32 list)):int64):int32) (word 256):int32)))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
          SUBGOAL_THEN `&(val(word_zx(word 272:int64):int32)):int - &272 = &(val(word_sub(word_zx(word 272:int64):int32) (word 272):int32))` ASSUME_TAC THENL
           [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
          X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--5) THEN
          ENSURES_FINAL_STATE_TAC THEN
          SUBGOAL_THEN `f_ev_scalar_tail_eta4 (SUC d) res buf pc (inlist:byte list) 272 =
              [EventJump (word (pc + 329),word (pc + 402)); EventJump (word (pc + 321),word (pc + 321))]` SUBST1_TAC THENL
           [MATCH_MP_TAC FEV_TAIL_OFFSET_ETA4 THEN
            SUBGOAL_THEN `SUB_LIST(0,272)(inlist:byte list) = inlist` SUBST1_TAC THENL
             [MATCH_MP_TAC SUB_LIST_BYTE_272 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
            REWRITE_TAC[NOT_LE] THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
          ASM_REWRITE_TAC[] THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
          REWRITE_TAC[LENGTH_BUTLAST_TMC] THEN ASM_REWRITE_TAC[APPEND];
          (* --- p < 272 ---                                                   *)
          SUBGOAL_THEN `p < 272` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
          ASM_CASES_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 9` THENL
           [(* --- STEP MID-BYTE EXIT: outlen=255, low<9 --- *)
            FIRST_X_ASSUM(CONJUNCTS_THEN ASSUME_TAC o check (fun th -> is_conj(concl th) && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))(concl th))) THEN
            SUBGOAL_THEN `256 <= LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list)` ASSUME_TAC THENL
             [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN
              ASM_REWRITE_TAC[] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
            SUBGOAL_THEN `?rest. REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list =
               APPEND (APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                              [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]) rest`
             STRIP_ASSUME_TAC THENL
             [ASM_CASES_TAC `val(EL p (inlist:byte list)) DIV 16 < 9` THENL
               [EXISTS_TAC `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) DIV 16))):int32]` THEN
                MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_BOTH) THEN
                ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
                DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND; GSYM APPEND_ASSOC];
                EXISTS_TAC `[]:int32 list` THEN
                MP_TAC(SPECL[`inlist:byte list`;`p:num`] REJ_STEP_LO) THEN
                ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
                DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_NIL]]; ALL_TAC] THEN
            MP_TAC(SPECL [`inlist:byte list`; `p+1`] SUB_LIST_256_PREFIX_GE) THEN
            ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN DISCH_TAC THEN
            SUBGOAL_THEN `LENGTH(APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                              [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]:int32 list) = 256` ASSUME_TAC THENL
             [REWRITE_TAC[LENGTH_APPEND; LENGTH] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
            SUBGOAL_THEN `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) =
                 APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                        [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]` ASSUME_TAC THENL
             [FIRST_X_ASSUM(fun th -> if is_eq(concl th) && (try lhs(concl th) = `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list)` with _->false) then SUBST1_TAC th else NO_TAC) THEN
              FIRST_X_ASSUM(fun th -> if is_eq(concl th) && (try lhs(concl th) = `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list` with _->false) then SUBST1_TAC th else NO_TAC) THEN
              W(fun (asl,gl) -> let lt = rhs gl in
                 MATCH_MP_TAC EQ_TRANS THEN EXISTS_TAC (mk_comb(`SUB_LIST(0,256):(int32)list->(int32)list`, lt)) THEN
                 CONJ_TAC THENL
                  [MATCH_MP_TAC SUB_LIST_APPEND_LEFT THEN ASM_REWRITE_TAC[LE_REFL];
                   MATCH_MP_TAC SUB_LIST_256_LE THEN ASM_REWRITE_TAC[LE_REFL]]); ALL_TAC] THEN
            REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) =
                  APPEND (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist))
                  [word_sx (word_sub (word 4:int16) (word (val (EL p (inlist:byte list)) MOD 16))):int32]`] THEN
            REWRITE_TAC[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255`] THEN
            ENSURES_INIT_TAC "s0" THEN
            MP_TAC(ISPECL [`inlist:byte list`; `buf:int64`; `s0:x86state`; `p:num`; `272`] READ_1BYTE_EL) THEN
            ASM_REWRITE_TAC[] THEN DISCH_TAC THEN
            SUBGOAL_THEN `~(&(val(word_zx(word 255:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 255:int64):int32) (word 256):int32)))` ASSUME_TAC THENL
             [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
            SUBGOAL_THEN `~(&(val(word_zx(word p:int64):int32)):int - &272 = &(val(word_sub(word_zx(word p:int64):int32) (word 272):int32)))` ASSUME_TAC THENL
             [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
            X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--8) THEN
            SUBGOAL_THEN `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64` ASSUME_TAC THENL
             [AP_TERM_TAC THEN AP_TERM_TAC THEN REWRITE_TAC[MULT_CLAUSES] THEN
              MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN MP_TAC(ASSUME `p < 272`) THEN ARITH_TAC; ALL_TAC] THEN
            RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `word_add buf (word (1 * val (word p:int64))) = word_add buf (word p):int64`;
                                        ASSUME `read (memory :> bytes8 (word_add buf (word p))) s4 = EL p (inlist:byte list)`;
                                        R10_NIBBLE_VAL]) THEN
            DISCARD_OLDSTATE_TAC "s8" THEN
            SUBGOAL_THEN `~(&(val(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32)):int - &9 = &(val(word_sub(word_zx(word(val(EL p (inlist:byte list)) MOD 16):int64):int32) (word 9):int32)))` ASSUME_TAC THENL
             [MATCH_MP_TAC JAE_NOT_TAKEN_LT THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
            X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (9--14) THEN
            DISCARD_OLDSTATE_TAC "s14" THEN
            SUBGOAL_THEN `&(val(word_zx(word 256:int64):int32)):int - &256 = &(val(word_sub(word_zx(word 256:int64):int32) (word 256):int32))` ASSUME_TAC THENL
             [MATCH_MP_TAC JAE_TAKEN_GE THEN CONJ_TAC THENL [ARITH_TAC; CONV_TAC NUM_REDUCE_CONV]; ALL_TAC] THEN
            X86_VSTEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (15--17) THEN
            ENSURES_FINAL_STATE_TAC THEN
            SUBGOAL_THEN `f_ev_scalar_tail_eta4 (SUC d) res buf pc (inlist:byte list) p =
                [EventJump (word (pc + 371),word (pc + 402));
                 EventStore (word_add res (word 1020),4);
                 EventJump (word (pc + 349),word (pc + 349));
                 EventLoad (word_add buf (word p),1);
                 EventJump (word (pc + 329),word (pc + 329));
                 EventJump (word (pc + 321),word (pc + 321))]` SUBST1_TAC THENL
             [MATCH_MP_TAC FEV_TAIL_MIDBYTE_ETA4 THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
            REWRITE_TAC[ASSUME `SUB_LIST(0,256)(REJ_SAMPLE_ETA4_BYTES inlist:int32 list) =
                  APPEND (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,p) inlist))
                  [word_sx (word_sub (word 4:int16) (word (val (EL p (inlist:byte list)) MOD 16))):int32]`] THEN
            CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
            REWRITE_TAC[ASSUME `LENGTH(APPEND (REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist))
                  [word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]:int32 list) = 256`] THEN
            REWRITE_TAC[LENGTH_BUTLAST_TMC] THEN ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
            [REPEAT CONJ_TAC THEN
            SUBGOAL_THEN `4 * 256 = 4 * 255 + 4` SUBST1_TAC THENL [ARITH_TAC; ALL_TAC] THEN
            MP_TAC(ISPECL [`memory:(x86state,int64->byte)component`; `res:int64`; `s17:x86state`;
               `REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list`;
               `[word_sx(word_sub (word 4:int16) (word(val(EL p (inlist:byte list)) MOD 16))):int32]`;
               `4*255`; `4`] BYTES_EQ_NUM_OF_WORDLIST_APPEND) THEN
            ANTS_TAC THENL [REWRITE_TAC[DIMINDEX_32] THEN ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
            DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[NUM_OF_WORDLIST_SINGLETON_INT32] THEN
            CONJ_TAC THENL
             [ASM_REWRITE_TAC[];
              SUBGOAL_THEN `word(4 * 255):int64 = word 1020` SUBST1_TAC THENL [CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
              FIRST_X_ASSUM(fun th -> let c=concl th in
                 if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`s17:x86state`))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c
                 then ASSUME_TAC(REWRITE_RULE[MATCH_MP LO_STORE_VAL (ASSUME `val(EL p (inlist:byte list)) MOD 16 < 9`)] th) else NO_TAC) THEN
              FIRST_X_ASSUM(fun th -> let c=concl th in
                 if is_eq c && can(find_term(fun t->try fst(dest_const t)="bytes32" with _->false))c && can(find_term(fun t->t=`val(EL p (inlist:byte list)) MOD 16`))c && not(can(find_term is_cond)c) && can(find_term(fun t->t=`s17:x86state`))c
                 then MP_TAC th else NO_TAC) THEN
              STORE4_FROM_SPEC `s17:x86state` `word_add res (word 1020):int64`];
             REWRITE_TAC[APPEND] THEN ASM_REWRITE_TAC[]];
            (* --- STEP CLEAN-RECURSIVE: body trip then IH at p+1 ---          *)
            SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p+1) inlist):int32 list) <= 256` ASSUME_TAC THENL
             [MP_TAC(SPECL[`inlist:byte list`;`p:num`] LENGTH_REJ_SAMPLE_STEP_1) THEN ASM_REWRITE_TAC[] THEN
              DISCH_THEN SUBST1_TAC THEN
              REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th -> let c=concl th in
                 c = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) < 256` ||
                 c = `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list) = 255 /\ val(EL p (inlist:byte list)) MOD 16 < 9)`))) THEN
              REPEAT(COND_CASES_TAC THEN ASM_REWRITE_TAC[]) THEN ARITH_TAC; ALL_TAC] THEN
            MP_TAC(SPECL[`d:num`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;`p:num`] FEV_TAIL_REC_ETA4) THEN
            ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
            DISCH_THEN(fun th -> REWRITE_TAC[th; GSYM APPEND_ASSOC]) THEN
            MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p:num`;
               `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list)`;`stackpointer:int64`;`e:(uarch_event)list`] SCALAR_TAIL_BODY_SAFE_ETA4) THEN
            ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
            DISCH_THEN(fun body_th ->
              let bodyQ = rand(rator(concl body_th)) in
              ENSURES_SEQUENCE_TAC `pc + 314` bodyQ THEN
              CONJ_TAC THENL
               [MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
                EXISTS_TAC (rand(rator(concl body_th))) THEN CONJ_TAC THENL
                 [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
                  MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN
                  EXISTS_TAC (rand(rator(rator(concl body_th)))) THEN CONJ_TAC THENL
                   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
                    ACCEPT_TAC body_th]];
                ALL_TAC]) THEN
            W(fun (asl,g) ->
               let ih = snd(List.find (fun (_,th) -> is_forall(concl th) &&
                   can (find_term (fun x -> x = `272 - p <= d`)) (concl th)) asl) in
               let ih_inst = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p+1`;`stackpointer:int64`;
                   `APPEND (f_ev_scalar_body_eta4 res buf pc (inlist:byte list) p (LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,p) inlist):int32 list))) (e:(uarch_event)list)`] ih in
               let ih_pre = rand(rator(rator(snd(dest_imp(concl ih_inst))))) in
               MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC ih_pre THEN CONJ_TAC THENL
                [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
                 MP_TAC ih_inst THEN ANTS_TAC THENL
                  [ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THEN TRY ASM_ARITH_TAC; DISCH_THEN ACCEPT_TAC]])]]]]);;

(* ========================================================================= *)
(* Final step-(b) pieces —                                                     *)
(*   STORE4_CONTAINED_ETA4, LOAD1_CONTAINED_ETA4  (scalar 4B store / 1B load)   *)
(*   MEMACCESS_F_EV_SCALAR_BODY_ETA4, MEMACCESS_F_EV_SCALAR_TAIL_ETA4           *)
(*   MLDSA_REJ_UNIFORM_ETA4_SCALAR_TAIL_AT_P_SAFE                               *)
(* Ports of the eta2 scalar-tail memaccess lemmas with eta4 constants (buf     *)
(* 272, val<9, f_ev_scalar_{body,tail}_eta4, budget 272-p), plus the trivial    *)
(* RUN-SAFE corollary.  The eta4 STORE_CONTAINED/BUF_CONTAINED_ETA4 are 32B/16B *)
(* (SIMD), so the scalar 4B/1B helpers here are distinct new lemmas.            *)
(* ========================================================================= *)

(* 4-byte compaction store  res + 4*cnt  within [res,1024]: 4*255 + 4 = 1024. *)
let STORE4_CONTAINED_ETA4 = prove
 (`!(res:int64) cnt. cnt <= 255
     ==> contained_modulo (2 EXP 64)
           (val(word_add res (word(4 * cnt))),4) (val res,1024)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

(* 1-byte input load  buf + p  within [buf,272]:  p < 272 ==> p + 1 <= 272. *)
let LOAD1_CONTAINED_ETA4 = prove
 (`!(buf:int64) p. p < 272
     ==> contained_modulo (2 EXP 64)
           (val(word_add buf (word p)),1) (val buf,272)`,
  REPEAT STRIP_TAC THEN
  GEN_REWRITE_TAC I [GSYM CONTAINED_MODULO_MOD2] THEN
  REWRITE_TAC[VAL_WORD_ADD; VAL_WORD; DIMINDEX_64] THEN
  CONV_TAC(ONCE_DEPTH_CONV MOD_DOWN_CONV) THEN
  REWRITE_TAC[CONTAINED_MODULO_MOD2] THEN
  MATCH_MP_TAC CONTAINED_MODULO_OFFSET_SIMPLE THEN ASM_ARITH_TAC);;

(* trivial RUN-SAFE corollary at an arbitrary exit position p (budget 272-p). *)
let MLDSA_REJ_UNIFORM_ETA4_SCALAR_TAIL_AT_P_SAFE =
  let rec conj_append_right t ev =
    if is_conj t then
      let l,r = dest_conj t in mk_conj(l, conj_append_right r ev)
    else mk_conj(t, ev) in
  let scalar_at_p_safe_eta4_tm =
    let qvars, body = strip_forall scalar_tail_at_p_tm in
    let hyps_tm, ens = dest_imp body in
    let ensc, ppf = strip_comb ens in
    let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
    let sv, preb = dest_abs pre in
    let sv2, postb = dest_abs post in
    let fev = `f_ev_scalar_tail_eta4 (272 - p) res buf pc (inlist:byte list) p` in
    let eq_pre = `read events (s:x86state) = e` in
    let eq_post = mk_eq(`read events (s:x86state)`,
                        mk_comb(mk_comb(`APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`, fev), `e:(uarch_event)list`)) in
    let pre' = mk_abs(sv, conj_append_right preb (vsubst[sv,`s:x86state`] eq_pre)) in
    let post' = mk_abs(sv2, conj_append_right postb (vsubst[sv2,`s:x86state`] eq_post)) in
    let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
    list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens')) in
  prove
   (scalar_at_p_safe_eta4_tm,
    REPEAT STRIP_TAC THEN
    MP_TAC(SPECL [`272 - p`; `res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`p:num`;`stackpointer:int64`;`e:(uarch_event)list`] SCALAR_TAIL_RUN_SAFE_ETA4) THEN
    ASM_REWRITE_TAC[LE_REFL]);;

(* ========================================================================== *)
(* Mid-exit sub-iteration event defs + memaccess lemmas —                      *)
(*   f_ev_midexit_subiter{1..4}_eta4  +  MEMACCESS_F_EV_MIDEXIT_SUBITER{1..4}_ETA4 *)
(*                                                                            *)
(* Port of the eta2 mid-exit machinery.  The midexit event defs are built      *)
(* MECHANICALLY from f_ev_loop_eta4_def (the same index lists as eta2 — same   *)
(* 19-event loop skeleton), so they inherit eta4's pcs automatically.  The     *)
(* MEMACCESS lemmas are pure value-algebra (store/load addresses only) over    *)
(* the containment lemmas (STORE_CONTAINED, BUF_CONTAINED_ETA4,               *)
(* GATHER_CONTAINED, TABLE_IDX_LT_256, NUM_ACCEPTED_PREFIX_MONO,              *)
(* PACK_MASK8_MOD256).  eta4 constants: buf window 272, head-guard bound       *)
(* 16*i+16<=272 (vs eta2's 136).                                              *)
(* ========================================================================== *)

(* ---- def-builder machinery (f_ev_loop_eta2_def -> _eta4) ---- *)
let feld_mid_eta4 = SPEC_ALL f_ev_loop_eta4_def;;
let evs_mid_eta4 = dest_list (rand(concl feld_mid_eta4));;
let ejc_mid_eta4 = rator (el 0 evs_mid_eta4);;
let wtgt_mid_eta4 = fst(dest_pair(rand(el 0 evs_mid_eta4)));;
let midsrc_eta4 j = fst(dest_pair(rand(el j evs_mid_eta4)));;
let xover_eta4 src = mk_comb(ejc_mid_eta4, mk_pair(src, wtgt_mid_eta4));;
let evty_mid_eta4 = type_of (el 0 evs_mid_eta4);;
let midlist_eta4 idxs headx =
  mk_list(headx :: map (fun j -> el j evs_mid_eta4) idxs, evty_mid_eta4);;
let mid_lhs_vars_eta4 = [`res:int64`;`buf:int64`;`table:int64`;`pc:num`;`mask:bool list`;`i:num`];;
let mkmiddef_eta4 name l =
  let listty = type_of l in
  let fnty = itlist (fun v ty -> mk_fun_ty (type_of v) ty) mid_lhs_vars_eta4 listty in
  define(mk_eq(list_mk_comb(mk_var(name, fnty), mid_lhs_vars_eta4), l));;

(* ---- the 4 midexit event defs (same index lists as eta2) ---- *)
let f_ev_midexit_subiter1_eta4 =
  mkmiddef_eta4 "f_ev_midexit_subiter1_eta4"
    (midlist_eta4 [13;14;15;16;17;18] (xover_eta4 (midsrc_eta4 12)));;
let f_ev_midexit_subiter2_eta4 =
  mkmiddef_eta4 "f_ev_midexit_subiter2_eta4"
    (midlist_eta4 [9;10;11;12;13;14;15;16;17;18] (xover_eta4 (midsrc_eta4 8)));;
let f_ev_midexit_subiter3_eta4 =
  mkmiddef_eta4 "f_ev_midexit_subiter3_eta4"
    (midlist_eta4 [5;6;7;8;9;10;11;12;13;14;15;16;17;18] (xover_eta4 (midsrc_eta4 4)));;
let f_ev_midexit_subiter4_eta4 =
  mkmiddef_eta4 "f_ev_midexit_subiter4_eta4"
    (midlist_eta4 [0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18] (xover_eta4 (midsrc_eta4 18)));;

(* ---- memaccess core tac (port of eta2 MIDEXIT_MEMACC_CORE_TAC;
   BUF_CONTAINED -> BUF_CONTAINED_ETA4) ---- *)
let MIDEXIT_MEMACC_CORE_TAC_ETA4 (def:thm) : tactic =
  REWRITE_TAC[def; memaccess_inbounds; ALL; EX; FST; SND] THEN
  ONCE_REWRITE_TAC[PACK_MASK8_MOD256] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC STORE_CONTAINED THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ1_TAC THEN MATCH_MP_TAC BUF_CONTAINED_ETA4 THEN FIRST_ASSUM ACCEPT_TAC;
    DISJ2_TAC THEN MATCH_MP_TAC GATHER_CONTAINED THEN MATCH_ACCEPT_TAC TABLE_IDX_LT_256];;

(* ---- the 4 MEMACCESS lemmas (buf 136->272, bound 16*i+16<=136 -> <=272) ---- *)
let MEMACCESS_F_EV_MIDEXIT_SUBITER1_ETA4 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 272 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter1_eta4 res buf table pc mask i)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN MIDEXIT_MEMACC_CORE_TAC_ETA4 f_ev_midexit_subiter1_eta4);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER2_ETA4 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 272 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter2_eta4 res buf table pc mask i)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248` ASSUME_TAC THENL
   [TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC_ETA4 f_ev_midexit_subiter2_eta4);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER3_ETA4 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 272 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter3_eta4 res buf table pc mask i)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [CONJ_TAC THEN TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC_ETA4 f_ev_midexit_subiter3_eta4);;

let MEMACCESS_F_EV_MIDEXIT_SUBITER4_ETA4 = prove
 (`!res buf table pc mask i.
     16 * i + 16 <= 272 /\
     NUM_ACCEPTED (SUB_LIST (0,32 * i + 24) mask) <= 248
     ==> memaccess_inbounds (f_ev_midexit_subiter4_eta4 res buf table pc mask i)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  SUBGOAL_THEN
   `NUM_ACCEPTED (SUB_LIST (0,32 * i) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 8) mask) <= 248 /\
    NUM_ACCEPTED (SUB_LIST (0,32 * i + 16) mask) <= 248`
   STRIP_ASSUME_TAC THENL
   [REPEAT CONJ_TAC THEN TRANS_TAC LE_TRANS `NUM_ACCEPTED (SUB_LIST (0,32 * i + 24) mask)` THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC; ALL_TAC] THEN
  MIDEXIT_MEMACC_CORE_TAC_ETA4 f_ev_midexit_subiter4_eta4);;

(* ========================================================================= *)
(* eta4 step-(e) cluster: mask-side scalar tail, f_ev_exit, and bridges.      *)
(* ========================================================================= *)

(* ------------------------------------------------------------------------- *)
(* MASK-SIDE scalar-tail cluster (prerequisite for f_ev_exit_eta4).           *)
(* ------------------------------------------------------------------------- *)

(* --- generic nibble helpers (reproved inline here) --- *)
let LENGTH_NIBBLES_OF_BYTES = prove
 (`!l:byte list. LENGTH(NIBBLES_OF_BYTES l) = 2 * LENGTH l`,
  LIST_INDUCT_TAC THEN
  ASM_REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; LENGTH; LENGTH_APPEND] THEN
  ARITH_TAC);;

let EL_NIBBLES_OF_BYTES = prove
 (`!(l:byte list) p. p < LENGTH l
     ==> EL (2*p) (NIBBLES_OF_BYTES l) = (word(val(EL p l) MOD 16):int16) /\
         EL (2*p+1) (NIBBLES_OF_BYTES l) = (word(val(EL p l) DIV 16):int16)`,
  LIST_INDUCT_TAC THENL
   [REWRITE_TAC[LENGTH; LT];
    GEN_TAC THEN REWRITE_TAC[LENGTH] THEN
    STRUCT_CASES_TAC(SPEC `p:num` num_CASES) THEN
    REWRITE_TAC[NIBBLES_OF_BYTES; NIBBLE_PAIR; APPEND] THENL
     [REWRITE_TAC[ARITH_RULE `2 * 0 = 0`; ARITH_RULE `2 * 0 + 1 = SUC 0`;
                  EL; HD; TL];
      REWRITE_TAC[LT_SUC] THEN DISCH_TAC THEN
      REWRITE_TAC[ARITH_RULE `2 * SUC n = SUC(SUC(2*n))`;
                  ARITH_RULE `2 * SUC n + 1 = SUC(SUC(2*n+1))`;
                  EL; TL; HD] THEN
      FIRST_X_ASSUM(MP_TAC o SPEC `n:num`) THEN ASM_REWRITE_TAC[]]]);;

(* --- REJ_MASK_EL_ETA4: linchpin nibble<->mask-bit bridge (val<9) --- *)
let REJ_MASK_EL_ETA4 = prove
 (`!(l:byte list) p. p < LENGTH l
     ==> (EL (2*p)   (REJ_MASK_ETA4 l) <=> val(EL p l) MOD 16 < 9) /\
         (EL (2*p+1) (REJ_MASK_ETA4 l) <=> val(EL p l) DIV 16 < 9)`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  MP_TAC(SPECL [`l:byte list`; `p:num`] EL_NIBBLES_OF_BYTES) THEN
  ASM_REWRITE_TAC[] THEN STRIP_TAC THEN
  REWRITE_TAC[REJ_MASK_ETA4] THEN
  SUBGOAL_THEN `2 * p < LENGTH(NIBBLES_OF_BYTES(l:byte list)) /\
                2 * p + 1 < LENGTH(NIBBLES_OF_BYTES(l:byte list))` STRIP_ASSUME_TAC THENL
   [REWRITE_TAC[LENGTH_NIBBLES_OF_BYTES] THEN
    UNDISCH_TAC `p < LENGTH(l:byte list)` THEN ARITH_TAC; ALL_TAC] THEN
  ASM_SIMP_TAC[EL_MAP] THEN ASM_REWRITE_TAC[] THEN
  MP_TAC(ISPEC `EL p (l:byte list)` VAL_BOUND) THEN REWRITE_TAC[DIMINDEX_8] THEN
  DISCH_TAC THEN
  MP_TAC(SPECL [`val(EL p (l:byte list))`; `16`] DIVISION) THEN
  ANTS_TAC THENL [ARITH_TAC; ALL_TAC] THEN STRIP_TAC THEN
  SUBGOAL_THEN
    `val(word(val(EL p (l:byte list)) MOD 16):int16) = val(EL p l) MOD 16 /\
     val(word(val(EL p (l:byte list)) DIV 16):int16) = val(EL p l) DIV 16`
    STRIP_ASSUME_TAC THENL
   [CONJ_TAC THEN REWRITE_TAC[VAL_WORD; DIMINDEX_16] THEN MATCH_MP_TAC MOD_LT THEN
    CONV_TAC(RAND_CONV NUM_REDUCE_CONV) THEN ASM_ARITH_TAC;
    ASM_REWRITE_TAC[]]);;

(* --- f_ev_scalar_body_mask_eta4 by term-surgery on f_ev_scalar_body_eta4 --- *)
let newrhs_body_eta4 =
  let eqn = snd(strip_forall(concl f_ev_scalar_body_eta4)) in
  let _,rhs = dest_eq eqn in
  let condlo = `val(EL p (inlist:byte list)) MOD 16 < 9` in
  let condhi = `val(EL p (inlist:byte list)) DIV 16 < 9` in
  subst [`EL (2*p) (mask:bool list)`, condlo;
         `EL (2*p+1) (mask:bool list)`, condhi] rhs;;

let f_ev_scalar_body_mask_eta4 =
  let fty = `:int64->int64->num->(bool)list->num->num->(uarch_event)list` in
  let hd = mk_var("f_ev_scalar_body_mask_eta4", fty) in
  let lhs = list_mk_comb(hd, [`res:int64`;`buf:int64`;`pc:num`;
                              `mask:bool list`;`p:num`;`outlen0:num`]) in
  define (mk_eq(lhs, newrhs_body_eta4));;

let FEV_SCALAR_BODY_MASK_ETA4 = prove
 (`!res buf pc (inlist:byte list) p outlen0.
     p < LENGTH inlist
     ==> f_ev_scalar_body_eta4 res buf pc inlist p outlen0 =
         f_ev_scalar_body_mask_eta4 res buf pc (REJ_MASK_ETA4 inlist) p outlen0`,
  REPEAT STRIP_TAC THEN
  REWRITE_TAC[f_ev_scalar_body_eta4; f_ev_scalar_body_mask_eta4] THEN
  ASM_SIMP_TAC[REJ_MASK_EL_ETA4]);;

(* --- f_ev_scalar_tail_mask_eta4: recursive mask-form of f_ev_scalar_tail_eta4 --- *)
let f_ev_scalar_tail_mask_eta4 = define
 `(f_ev_scalar_tail_mask_eta4 0 (res:int64) (buf:int64) (pc:num) (mask:bool list) (p:num) =
     (if 256 <= NUM_ACCEPTED(SUB_LIST(0,2*p) mask)
      then [EventJump (word (pc + 321),word (pc + 402))]
      else [EventJump (word (pc + 329),word (pc + 402));
            EventJump (word (pc + 321),word (pc + 321))])) /\
  (f_ev_scalar_tail_mask_eta4 (SUC d) (res:int64) (buf:int64) (pc:num) (mask:bool list) (p:num) =
     (if 256 <= NUM_ACCEPTED(SUB_LIST(0,2*p) mask)
      then [EventJump (word (pc + 321),word (pc + 402))]
      else if p = 272
      then [EventJump (word (pc + 329),word (pc + 402));
            EventJump (word (pc + 321),word (pc + 321))]
      else if NUM_ACCEPTED(SUB_LIST(0,2*p) mask) = 255 /\ EL (2*p) mask
      then [EventJump (word (pc + 371),word (pc + 402));
            EventStore (word_add res (word 1020),4);
            EventJump (word (pc + 349),word (pc + 349));
            EventLoad (word_add buf (word p),1);
            EventJump (word (pc + 329),word (pc + 329));
            EventJump (word (pc + 321),word (pc + 321))]
      else APPEND (f_ev_scalar_tail_mask_eta4 d res buf pc mask (p+1))
                  (f_ev_scalar_body_mask_eta4 res buf pc mask p
                     (NUM_ACCEPTED(SUB_LIST(0,2*p) mask)))))`;;

let FEV_SCALAR_TAIL_MASK_ETA4 = prove
 (`!d res buf pc (inlist:byte list) p.
     LENGTH inlist = 272 /\ p <= 272
     ==> f_ev_scalar_tail_eta4 d res buf pc inlist p =
         f_ev_scalar_tail_mask_eta4 d res buf pc (REJ_MASK_ETA4 inlist) p`,
  INDUCT_TAC THEN REPEAT GEN_TAC THEN STRIP_TAC THENL
   [REWRITE_TAC[f_ev_scalar_tail_eta4; f_ev_scalar_tail_mask_eta4; STORE_BRIDGE_ETA4];
    ASM_CASES_TAC `p = 272` THENL
     [ASM_REWRITE_TAC[f_ev_scalar_tail_eta4; f_ev_scalar_tail_mask_eta4; STORE_BRIDGE_ETA4];
      SUBGOAL_THEN `p < LENGTH(inlist:byte list) /\ p + 1 <= 272` STRIP_ASSUME_TAC THENL
       [ASM_ARITH_TAC; ALL_TAC] THEN
      REWRITE_TAC[f_ev_scalar_tail_eta4; f_ev_scalar_tail_mask_eta4] THEN
      REWRITE_TAC[STORE_BRIDGE_ETA4] THEN
      SUBGOAL_THEN
        `f_ev_scalar_tail_eta4 d res buf pc inlist (p+1) =
         f_ev_scalar_tail_mask_eta4 d res buf pc (REJ_MASK_ETA4 inlist) (p+1)`
        SUBST1_TAC THENL
       [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_REWRITE_TAC[]; ALL_TAC] THEN
      ASM_SIMP_TAC[REJ_MASK_EL_ETA4; FEV_SCALAR_BODY_MASK_ETA4]]]);;

(* --- mask-side memaccess (window [buf,272;table,2048][res,1024]) --- *)
let MEMACCESS_F_EV_SCALAR_BODY_MASK_ETA4 = prove
 (`!res buf table pc (mask:bool list) p outlen0.
     p < 272 /\ outlen0 <= 255 /\
     ~(outlen0 = 255 /\ EL (2 * p) mask)
     ==> memaccess_inbounds (f_ev_scalar_body_mask_eta4 res buf pc mask p outlen0)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `val(word outlen0:int64) = outlen0` ASSUME_TAC THENL
   [MATCH_MP_TAC VAL_WORD_EQ THEN REWRITE_TAC[DIMINDEX_64] THEN ASM_ARITH_TAC;
    ALL_TAC] THEN
  REWRITE_TAC[f_ev_scalar_body_mask_eta4] THEN REPEAT COND_CASES_TAC THEN
  ASM_REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
  REPEAT CONJ_TAC THEN
  FIRST
   [DISJ1_TAC THEN MATCH_MP_TAC LOAD1_CONTAINED_ETA4 THEN FIRST_ASSUM ACCEPT_TAC;
    MATCH_MP_TAC STORE4_CONTAINED_ETA4 THEN
    TRY(FIRST_X_ASSUM
         ((fun th -> MP_TAC th THEN ASM_REWRITE_TAC[]) o
          check (fun th -> is_neg(concl th) && is_conj(rand(concl th))))) THEN
    ASM_ARITH_TAC]);;

let MEMACCESS_F_EV_SCALAR_TAIL_MASK_ETA4 = prove
 (`!d res buf table pc (mask:bool list) p.
     p + d <= 272
     ==> memaccess_inbounds (f_ev_scalar_tail_mask_eta4 d res buf pc mask p)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  INDUCT_TAC THENL
   [REPEAT GEN_TAC THEN STRIP_TAC THEN
    REWRITE_TAC[f_ev_scalar_tail_mask_eta4] THEN COND_CASES_TAC THEN
    REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
    REPEAT GEN_TAC THEN STRIP_TAC THEN
    REWRITE_TAC[f_ev_scalar_tail_mask_eta4] THEN REPEAT COND_CASES_TAC THENL
     [REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
      REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND];
      REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN REPEAT CONJ_TAC THEN
      FIRST [REWRITE_TAC[ARITH_RULE `1020 = 4 * 255`] THEN
             MATCH_MP_TAC STORE4_CONTAINED_ETA4 THEN ARITH_TAC;
             DISJ1_TAC THEN MATCH_MP_TAC LOAD1_CONTAINED_ETA4 THEN ASM_ARITH_TAC];
      REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN CONJ_TAC THENL
       [FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC;
        MATCH_MP_TAC MEMACCESS_F_EV_SCALAR_BODY_MASK_ETA4 THEN REPEAT CONJ_TAC THENL
         [ASM_ARITH_TAC; ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC]]]]);;

(* --- headguard memaccess (jumps-only, trivial) --- *)
let MEMACCESS_F_EV_HEADGUARD_ETA4 = prove
 (`!pc rr wr. memaccess_inbounds (f_ev_headguard_eta4 pc) rr wr`,
  REWRITE_TAC[f_ev_headguard_eta4; memaccess_inbounds; ALL; EX; FST; SND]);;

(* ------------------------------------------------------------------------- *)
(* step (e) sub-step 1: f_ev_exit_eta4 + MEMACCESS_F_EV_EXIT_ETA4.            *)
(* ------------------------------------------------------------------------- *)

let f_ev_exit_eta4 = define
 `f_ev_exit_eta4 (res:int64) (buf:int64) (table:int64) (pc:num) (mask:bool list) (N:num)
    : (uarch_event)list =
    if NUM_ACCEPTED(SUB_LIST(0,32 * N) mask) <= 248
    then APPEND (f_ev_scalar_tail_mask_eta4 (272 - 16 * N) res buf pc mask (16 * N))
                (APPEND (f_ev_headguard_eta4 pc)
                        (f_ev_loop_eta4 res buf table pc mask (N-1)))
    else if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8) mask) <= 248
    then (if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16) mask) <= 248
          then (if NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24) mask) <= 248
                then APPEND (f_ev_scalar_tail_mask_eta4 (272 - 16 * N) res buf pc mask (16 * N))
                            (f_ev_midexit_subiter4_eta4 res buf table pc mask (N-1))
                else APPEND (f_ev_scalar_tail_mask_eta4 (272 - (16 * (N-1) + 12)) res buf pc mask
                              (16 * (N-1) + 12))
                            (f_ev_midexit_subiter3_eta4 res buf table pc mask (N-1)))
          else APPEND (f_ev_scalar_tail_mask_eta4 (272 - (16 * (N-1) + 8)) res buf pc mask
                        (16 * (N-1) + 8))
                      (f_ev_midexit_subiter2_eta4 res buf table pc mask (N-1)))
    else APPEND (f_ev_scalar_tail_mask_eta4 (272 - (16 * (N-1) + 4)) res buf pc mask
                  (16 * (N-1) + 4))
                (f_ev_midexit_subiter1_eta4 res buf table pc mask (N-1))`;;

let MEMACCESS_F_EV_EXIT_ETA4 = prove
 (`!res buf table pc (mask:bool list) N.
     16 * N <= 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1)) mask) <= 248
     ==> memaccess_inbounds (f_ev_exit_eta4 res buf table pc mask N)
           [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  REPEAT COND_CASES_TAC THEN
  REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN REPEAT CONJ_TAC THEN
  FIRST
   [MATCH_MP_TAC MEMACCESS_F_EV_SCALAR_TAIL_MASK_ETA4 THEN ASM_ARITH_TAC;
    MATCH_ACCEPT_TAC MEMACCESS_F_EV_HEADGUARD_ETA4;
    MATCH_MP_TAC MEMACCESS_F_EV_LOOP_ETA4 THEN CONJ_TAC THENL
     [ASM_ARITH_TAC;
      MATCH_MP_TAC LE_TRANS THEN
      EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32 * N) (mask:bool list))` THEN
      CONJ_TAC THENL
       [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ASM_ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER1_ETA4 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER2_ETA4 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER3_ETA4 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER4_ETA4 THEN
    CONJ_TAC THENL [ASM_ARITH_TAC; FIRST_ASSUM ACCEPT_TAC]]);;

(* ------------------------------------------------------------------------- *)
(* step (e) sub-step 2: 5 events-bridges + 5 EXISTS helpers.                  *)
(* ------------------------------------------------------------------------- *)

let OFFSET_EVENTS_BRIDGE_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 272 /\ 16 * N = 272 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248
     ==> APPEND (f_ev_scalar_tail_eta4 (272 - 272) res buf pc inlist 272)
                (APPEND (f_ev_headguard_eta4 pc)
                        (APPEND (f_ev_loop_eta4 res buf table pc
                                   (REJ_MASK_ETA4 (inlist:byte list)) (N-1))
                                (e:(uarch_event)list)))
         = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`272 - 272`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;`272`]
               FEV_SCALAR_TAIL_MASK_ETA4) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN
  REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT1_EVENTS_BRIDGE_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
                (APPEND (f_ev_midexit_subiter1_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`272 - (16 * (N-1) + 4)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 4`] FEV_SCALAR_TAIL_MASK_ETA4) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT2_EVENTS_BRIDGE_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
                (APPEND (f_ev_midexit_subiter2_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`272 - (16 * (N-1) + 8)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 8`] FEV_SCALAR_TAIL_MASK_ETA4) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT3_EVENTS_BRIDGE_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248)
     ==> APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
                (APPEND (f_ev_midexit_subiter3_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`272 - (16 * (N-1) + 12)`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * (N-1) + 12`] FEV_SCALAR_TAIL_MASK_ETA4) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

let MIDEXIT4_EVENTS_BRIDGE_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N e.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248
     ==> APPEND (f_ev_scalar_tail_eta4 (272 - 16 * N) res buf pc inlist (16 * N))
                (APPEND (f_ev_midexit_subiter4_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))
         = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N) e`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[f_ev_exit_eta4] THEN
  ASM_REWRITE_TAC[COND_CLAUSES] THEN
  MP_TAC(SPECL [`272 - 16 * N`;`res:int64`;`buf:int64`;`pc:num`;`inlist:byte list`;
               `16 * N`] FEV_SCALAR_TAIL_MASK_ETA4) THEN
  ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN ASM_ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN SUBST1_TAC THEN REWRITE_TAC[APPEND_ASSOC]);;

(* ---- EXISTS helpers: package the CT existential post ---- *)
let OFFSET_EXISTS_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 272 /\ 16 * N = 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248 /\
     read events s =
       APPEND (f_ev_scalar_tail_eta4 (272 - 272) res buf pc inlist 272)
              (APPEND (f_ev_headguard_eta4 pc)
                      (APPEND (f_ev_loop_eta4 res buf table pc
                                 (REJ_MASK_ETA4 inlist) (N-1)) e))
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC OFFSET_EVENTS_BRIDGE_ETA4 THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT_ETA4 THEN ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
     [ASM_ARITH_TAC;
      MATCH_MP_TAC LE_TRANS THEN
      EXISTS_TAC `NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist))` THEN
      CONJ_TAC THENL
       [MATCH_MP_TAC NUM_ACCEPTED_PREFIX_MONO THEN ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]]]);;

let MIDEXIT1_EXISTS_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
              (APPEND (f_ev_midexit_subiter1_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT1_EVENTS_BRIDGE_ETA4 THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT_ETA4 THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT2_EXISTS_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
              (APPEND (f_ev_midexit_subiter2_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT2_EVENTS_BRIDGE_ETA4 THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT_ETA4 THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT3_EXISTS_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248) /\
     read events s =
       APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
              (APPEND (f_ev_midexit_subiter3_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT3_EVENTS_BRIDGE_ETA4 THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT_ETA4 THEN ASM_REWRITE_TAC[]]);;

let MIDEXIT4_EXISTS_ETA4 = prove
 (`!res buf table (inlist:byte list) pc N (e:(uarch_event)list) s.
     LENGTH inlist = 272 /\ 16 * N <= 272 /\ ~(N = 0) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248 /\
     ~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248) /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248 /\
     NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248 /\
     read events s =
       APPEND (f_ev_scalar_tail_eta4 (272 - 16 * N) res buf pc inlist (16 * N))
              (APPEND (f_ev_midexit_subiter4_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1)) e)
     ==> ?e2. read events s = APPEND e2 e /\
              e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N /\
              memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`,
  REPEAT STRIP_TAC THEN
  EXISTS_TAC `f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N` THEN
  REPEAT CONJ_TAC THENL
   [ONCE_ASM_REWRITE_TAC[] THEN MATCH_MP_TAC MIDEXIT4_EVENTS_BRIDGE_ETA4 THEN ASM_REWRITE_TAC[];
    REFL_TAC;
    MATCH_MP_TAC MEMACCESS_F_EV_EXIT_ETA4 THEN ASM_REWRITE_TAC[]]);;

(* ========================================================================= *)
(* eta4 rej_uniform constant-time (SAFE) cluster. Mirrors the eta2 SAFE       *)
(* cluster. Prereq: the rip_mp else-branch structural read-RIP guard above.   *)
(* Depends only on the eta4 machinery (mk_prefix_g_full, mk_midexit1..4,      *)
(* mk_mg*_nt, SI*_*, bridges, f_ev_*, *_EXISTS_ETA4, *_EVENTS_BRIDGE_ETA4,     *)
(* MEMSAFE chain, trip lemmas) + the guarded rip_mp.                          *)
(* ========================================================================= *)

(* SAFE-midexit machinery (variants that shadow the MEMSAFE machinery above): *)
(* mk_midexit2 tail + mk_mg2/mg3_nt / SI4_BODY4 / mk_si2_mg2_taken /          *)
(* mk_si3_mg3_taken differ from the MEMSAFE versions used above. They close   *)
(* over the P1-guarded rip_mp. mk_midexit1 is not re-lifted (the MEMSAFE one  *)
(* is directly correct).                                                      *)
let mk_mg1_nt (memsafe:bool) : tactic =
  W(fun (asl,w) ->
    let r9 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("R9",_)),Var("s21",_))),_) -> true | _ -> false) asl in
    let goal_pc = find_term (fun t -> match t with Comb(Const("word_popcount",_),_) -> true | _ -> false) (concl(snd r9)) in
    let low8 = `bitval(bit 7 (word_subword (f1bnd:int256) (0,8):byte)) + bitval(bit 7 (word_subword f1bnd (8,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (16,8):byte)) + bitval(bit 7 (word_subword f1bnd (24,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (32,8):byte)) + bitval(bit 7 (word_subword f1bnd (40,8):byte)) +
             bitval(bit 7 (word_subword f1bnd (48,8):byte)) + bitval(bit 7 (word_subword f1bnd (56,8):byte))` in
    let mr = CONV_RULE(DEPTH_CONV BETA_CONV THENC NUM_REDUCE_CONV)
               (SPEC `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` MOD_RED) in
    let popeq = prove(mk_eq(goal_pc, low8),
      REWRITE_TAC[VAL_WORD_ZX_GEN; VAL_WORD; DIMINDEX_8; DIMINDEX_32; DIMINDEX_64] THEN
      REWRITE_TAC[ARITH_RULE `256 = 2 EXP 8`; MOD_MOD_EXP_MIN] THEN
      CONV_TAC(ONCE_DEPTH_CONV NUM_REDUCE_CONV) THEN
      REWRITE_TAC[ARITH_RULE `2 EXP 8 = 256`; mr] THEN
      MAP_EVERY (fun b -> BOOL_CASES_TAC b)
        [`bit 7 (word_subword (f1bnd:int256) (0,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (8,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (16,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (24,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (32,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (40,8):byte)`;
         `bit 7 (word_subword (f1bnd:int256) (48,8):byte)`;`bit 7 (word_subword (f1bnd:int256) (56,8):byte)`] THEN
      REWRITE_TAC[BITVAL_CLAUSES] THEN CONV_TAC NUM_REDUCE_CONV THEN CONV_TAC WORD_REDUCE_CONV) in
    let maskbit = snd(find (fun (_,th) -> let c=concl th in is_forall c &&
        can(find_term(fun u->u=`f1bnd:int256`))c && can(find_term(fun u->match u with Comb(Const("bit",_),_)->true|_->false))c &&
        not(can(find_term(fun u->match u with Const("word_zx",_)->true|_->false))c) &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (24,8):byte`))c &&
        not(can(find_term(fun u->u=`word_subword (chunk0:int128) (32,8):byte`))c)) asl) in
    let mb_tm = concl maskbit in
    let blk0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
           (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
    let blkeq = mk_eq(low8, `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)`) in
    let blk0_tm = concl(snd blk0) in
    let bsum_raw = prove(mk_imp(mb_tm, mk_imp(blk0_tm, blkeq)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN DISCH_THEN(fun b -> REWRITE_TAC[b]) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      ASM_SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let bsum = MP (MP bsum_raw maskbit) (snd blk0) in
    let pop_len = TRANS popeq bsum in
    ASSUME_TAC pop_len) THEN
  (* bridge: outlen0 + niblen(SUB(16i,4)) = niblen_sample(16i+4)             *)
  SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [ASM_REWRITE_TAC[] THEN UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
    UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i) inlist):int32 list) = outlen0` THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  (* bnd1: outlen0 + niblen(SUB(16i,4)) <= 248  (= niblen_sample(16i+4) <= 248, direct hyp) *)
  SUBGOAL_THEN `outlen0 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list) <= 248` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("outlen0",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
    FIRST [FIRST_ASSUM ACCEPT_TAC;
           (* mid-exit cases 3+: niblen(16i+4)<=248 follows from a later sample bound by monotonicity *)
           (FIRST_X_ASSUM(fun th -> match concl th with
              Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),k) when k=`248`
                -> MP_TAC th | _ -> NO_TAC) THEN
            MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
            MATCH_MP_TAC REJ_SAMPLE_ETA4_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block0len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `outlen0:num` block0len in
    let bnd = snd(find (fun (_,th) -> concl th = mk_binop `(<=):num->num->bool` sum `248`) asl) in
    let pop_len = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let ja = MP (ISPECL[sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
    ASSUME_TAC pop_len THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (22--23) THEN
  SUBGOAL_THEN `read RIP s23 = word (pc + 163):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let blk0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),l),_) -> (try let h,args=strip_comb l in fst(dest_const h)="SUB_LIST" &&
             (match args with [Comb(Comb(_,off),wid);_] -> wid=`4` && (match off with Comb(Comb(Const("*",_),_),_)->true|_->false) | _->false) with _->false) | _ -> false) asl in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let ja = find (fun (_,th) -> is_disj(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`248`))(concl th)) asl in
      rip_mp memsafe 163 23 THEN
      REWRITE_TAC[GSYM(snd blk0)] THEN REWRITE_TAC[snd rax_red0] THEN
      REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC] THEN
  (* fold RAX s23 read into clean word(acc1) form (mirrors PREFIX_G_FULL lines 426-431) so the
     subsequent SI2 store's memsafe can bound val(RAX)=acc1<=248. *)
  W(fun (asl,w) ->
    let pl = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
    let rr = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
    RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

(* --- mg2_nt ---                                                            *)
(* MG2_NT_TAC: from s33, resolve mid-guard-2 NOT-taken (niblen(16i+8)<=248 direct) -> RIP s35=pc+215.
   = SI2_MG2_TAKEN's pop_len2/bridge2 build but JA_NOT_TAKEN_LE + RIP pc+215, ending with RAX-fold
   so the SI3 store memsafe at s41 discharges. *)
let mk_mg2_nt (memsafe:bool) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
    let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
    let popcnt2 = REWRITE_RULE[m8b_def]
       (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE1)) in
    let lanesum8 = rand(concl popcnt2) in
    let mb2 = find_a (fun th -> let c=concl th in is_forall c &&
       can(find_term(fun u->u=`f1bnd:int256`))c &&
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),_) -> true | _ -> false))c) in
    let mb2_tm = concl mb2 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk1_eq = el 1 (CONJUNCTS bb) in
    let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                   word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
    let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block1)) in
    let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
    ASSUME_TAC pop_len2) THEN
  (* bridge2: acc1 + niblen(SUB(16i+4,4)) = niblen_sample(16i+8) = (acc2 conceptually) *)
  SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then MP_TAC th else NO_TAC) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  (* bnd: acc1 + block1len <= 248 (= niblen(16i+8)<=248 direct hyp)          *)
  SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list) <= 248` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_)->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
    FIRST [FIRST_ASSUM ACCEPT_TAC;
           (* case-4: niblen(16i+8)<=248 follows from niblen(16i+12)<=248 by monotonicity *)
           (FIRST_X_ASSUM(fun th -> match concl th with
              Comb(Comb(Const("<=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),k) when k=`248`
                -> MP_TAC th | _ -> NO_TAC) THEN
            MATCH_MP_TAC(ARITH_RULE `a <= b ==> b <= 248 ==> a <= 248`) THEN
            MATCH_MP_TAC REJ_SAMPLE_ETA4_PREFIX_MONO THEN ARITH_TAC)]; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block1len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `acc1:num` block1len in
    let bnd = snd(find (fun (_,th) -> concl th = mk_binop `(<=):num->num->bool` sum `248`) asl) in
    let pop_len2 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let lt32 = MATCH_MP (ARITH_RULE `a + b <= 248 ==> a + b < 2 EXP 32`) bnd in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let ja = MP (ISPECL [sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
    ASSUME_TAC pop_len2 THEN ASSUME_TAC bnd THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (34--35) THEN
  SUBGOAL_THEN `read RIP s35 = word (pc + 215):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let pop_len2_old = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2_old) in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let ja = find (fun (_,th) -> is_disj(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`acc1:num`))(concl th)) asl in
      rip_mp memsafe 215 35 THEN
      REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[snd rax_red0] THEN
      REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC] THEN
  (* RAX-fold so SI3 store memsafe discharges                                *)
  W(fun (asl,w) ->
    let pl = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
    let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
    let pl_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pl) in
    let rr = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
    RULE_ASSUM_TAC(REWRITE_RULE[pl_typed]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

(* --- mg3_nt ---                                                            *)
(* MG3_NT_TAC: from s45, mid-guard-3 NOT-taken from direct niblen(16i+12)<=248 -> RIP s47=pc+268,
   with RAX-fold so the SI4 store memsafe at s53 discharges. Clone of SI3_MG3_TAKEN w/ JA_NOT_TAKEN_LE. *)
let mk_mg3_nt (memsafe:bool) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
    let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
    let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
    let popcnt3 = REWRITE_RULE[m8b_def; m8c_def]
       (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE2)) in
    let lanesum = rand(concl popcnt3) in
    let mb3 = find_a (fun th -> let c=concl th in is_forall c &&
       can(find_term(fun u->u=`f1bnd:int256`))c &&
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`16` | _ -> false))c) in
    let mb3_tm = concl mb3 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk2_eq = el 2 (CONJUNCTS bb) in
    let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                   word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
    let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block2)) in
    let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum, block2len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
    ASSUME_TAC pop_len3) THEN
  (* bridge3: acc2 + niblen(SUB(16i+8,4)) = niblen_sample(16i+12)            *)
  SUBGOAL_THEN `acc2 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+8,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then MP_TAC th else NO_TAC) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] OUTLEN0_LE_256_FROM_SUBITER) THEN
    ANTS_TAC THENL
     [CONJ_TAC THENL
       [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC;
        FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN ARITH_TAC; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block2len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `acc2:num` block2len in
    let bridge3 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> true | _ -> false) asl) in
    let lt32 = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32`) asl)) in
    let pop_len3 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let bnd = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) <= 248`) asl)) in
    let ja = MP (ISPECL [sum; `248`] JA_NOT_TAKEN_LE) (CONJ bnd (ARITH_RULE `248 < 2 EXP 32`)) in
    ASSUME_TAC pop_len3 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (46--47) THEN
  SUBGOAL_THEN `read RIP s47 = word (pc + 268):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let rax_red0 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
      let ja = find_a (fun th -> is_disj(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`acc2:num`))(concl th)) in
      rip_mp memsafe 268 47 THEN
      REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
      REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC] THEN
  (* RAX-fold so SI4 store memsafe discharges                                *)
  W(fun (asl,w) ->
    let pl = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
    let rr = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) asl in
    RULE_ASSUM_TAC(REWRITE_RULE[snd pl]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]));;

(* --- si4_body4 ---                                                         *)
(* SI4_BODY4_TAC: SI4_INTEGRATED body with forked SI4_PRE (acc3<=248 from direct niblen(16i+12)<=248).
   From s47/pc+268 (after MG3_NT) to s57/pc+52 at pos16(i+1) (back-edge), store folded to 16(i+1). *)
let SI4_BODY4_TAC : tactic =
  ABBREV_TAC `acc3 = acc2 + LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (16*i+8,4) inlist):int16 list)` THEN
  REABBREV_TAC `mask8d = read R8 s47` THEN
  SUBGOAL_THEN `acc3 <= 248` ASSUME_TAC THENL
   [FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Var("acc3",_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_)))->true|_->false) then SUBST1_TAC th else NO_TAC) THEN
    FIRST_ASSUM ACCEPT_TAC; ALL_TAC] THEN
  VAL_INT64_TAC `acc3:num` THEN
  ACC3_IDENT_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3`]) THEN
  X86_VSTEPS_TAC EXEC (48--48) THEN
  X86_VERBOSE_STEP_TAC EXEC "s49" THEN MOVZBL_R10_CAPTURE_TAC THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `read R8 s48 = mask8d:int64`]) THEN
  X86_VSTEPS_TAC EXEC (50--50) THEN TAB4_TEQ_TAC THEN REABBREV_TAC `tab4 = read YMM6 s50` THEN
  X86_VSTEPS_TAC EXEC (51--51) THEN REABBREV_TAC `pshuf4 = read YMM6 s51` THEN
  PURGE_STALE_STATES_TAC ["s50"] THEN
  X86_VSTEPS_TAC EXEC (52--52) THEN REABBREV_TAC `sx4 = read YMM1 s52` THEN
  VAL_INT64_TAC `acc3:num` THEN
  X86_STEPS_TAC EXEC (53--53) THEN
  SUBGOAL_THEN `sx4:int256 = usimd8 (\b:byte. word_sx b:int32) (word_zx(word_zx (pshuf4:int256):int128):int64)` ASSUME_TAC THENL
   [W(fun (asl,w) ->
       let sx4def = find (fun th -> is_eq(concl th) && rand(concl th)=`sx4:int256` &&
           can(find_term(fun u->match u with Const("word_join",_)->true|_->false))(concl th)) (map snd asl) in
       SUBST1_TAC(SYM sx4def) THEN
       REWRITE_TAC[usimd8;usimd4;usimd2;DIMINDEX_8;DIMINDEX_16;DIMINDEX_32;DIMINDEX_64;DIMINDEX_128;DIMINDEX_256] THEN
       CONV_TAC WORD_BLAST);
    ALL_TAC] THEN
  (SUBGOAL_THEN maskbit_tgt_4 ASSUME_TAC THENL [MASKBIT_TGT_4_TAC; ALL_TAC]) THEN
  (SUBGOAL_THEN pf_target_4 ASSUME_TAC THENL [PF_PROOF_4; ALL_TAC]) THEN
  ACC3_IDENT_TAC THEN
  W(fun (asl,w) ->
    let asms = map snd asl in
    let hasC nm th = can (find_term (fun u -> match u with Const(n,_) when n=nm -> true | _ -> false)) (concl th) in
    let bg4 = find (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f0sub:int256`))c &&
        can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))c &&
        can(find_term(fun u->u=`word_subword (chunk0:int128) (96,8):byte`))c &&
        can(find_term(fun u->u=`word_subword (f0sub:int256) (128,128):int128`))c) asms in
    let mthm4 = find (fun th -> concl th = maskbit_tgt_4) asms in
    let pfth4 = find (fun th -> concl th = pf_target_4) asms in
    let sx4u = find (fun th -> match concl th with Comb(Comb(Const("=",_),Var("sx4",_)),r)->can(find_term(fun u->match u with Const("usimd8",_)->true|_->false))r|_->false) asms in
    let storef0 = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),m),Var("s53",_))),Var("sx4",_)) -> can(find_term(fun u->match u with Const("bytes256",_)->true|_->false)) m |_->false) asms in
    let store_full = REWRITE_RULE[pfth4] (REWRITE_RULE[sx4u] storef0) in
    let g4 = `word_zx (word_zx (word_ushr (word_zx (word_zx (word_subword (f0sub:int256) (128,128):int128):int128):int128) 64):int128):int128` in
    let m = `word (val (mask8d:int64) MOD 256):byte` in
    let pc = ISPECL [`word_add res (word (4 * acc3)):int64`; `s53:x86state`; g4; m; `LENGTH(ACC_IDX (word (val (mask8d:int64) MOD 256):byte))`] SUBITER_STORE_POSTCOND in
    let res_th0 = MP pc (CONJ (SPEC m LACC8) store_full) in
    let spec = ISPECL [g4; m; `word_subword (chunk0:int128) (96,8):byte`; `word_subword (chunk0:int128) (104,8):byte`; `word_subword (chunk0:int128) (112,8):byte`; `word_subword (chunk0:int128) (120,8):byte`] SUBITER_STORE_SPEC in
    let rej_store = REWRITE_RULE[MP spec (CONJ mthm4 bg4)] res_th0 in
    let leninl = find (fun th -> concl th = `LENGTH(inlist:byte list)=272`) asms in
    let i116 = find (fun th -> concl th = `16 * (i + 1) <= 272`) asms in
    let blk16 = find (fun th -> is_eq(concl th) && hasC "SUB_LIST" th && (try length(dest_list(rand(concl th)))=16 with _->false)) asms in
    let bb = MP (ISPECL [`inlist:byte list`;`i:num`;`chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*(i+1)<=272 ==> 16*i+16<=272`) i116)) blk16) in
    let blk3_eq = el 3 (CONJUNCTS bb) in
    let lr0 = MP (ISPECL [m;`word_subword (chunk0:int128) (96,8):byte`;`word_subword (chunk0:int128) (104,8):byte`;`word_subword (chunk0:int128) (112,8):byte`;`word_subword (chunk0:int128) (120,8):byte`] LEN_RECONCILE_GEN) mthm4 in
    let lr = REWRITE_RULE[GSYM blk3_eq] lr0 in
    let rej_store1 = REWRITE_RULE[GSYM blk3_eq] rej_store in
    let acc3_ident = find (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc3",_)) -> true | _ -> false) asms in
    let prefix_store0 = find (fun th -> (match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),_),Var("s53",_))),_) -> true | _ -> false) &&
         hasC "num_of_wordlist" th && hasC "SUB_LIST" th && can(find_term(fun u->u=`acc3:num`))(lhand(concl th)) && not(hasC "ACC_IDX" th) && not(hasC "bytes256" th)) asms in
    let prefix_store = REWRITE_RULE[GSYM acc3_ident] prefix_store0 in
    let rej_store2 = REWRITE_RULE[GSYM acc3_ident] rej_store1 in
    let fold = MP (ISPECL [`res:int64`;`s53:x86state`;m;`SUB_LIST(16*i+12,4) (inlist:byte list)`;`SUB_LIST(0,16*i+12) (inlist:byte list)`] SUBITER_FOLD_STEP)
                  (CONJ lr (CONJ prefix_store rej_store2)) in
    let split = REWRITE_RULE[ADD_CLAUSES] (ISPECL[`inlist:byte list`;`16*i+12`;`4`;`0`] SUB_LIST_SPLIT) in
    let clean = REWRITE_RULE[GSYM split; ARITH_RULE `(16*i+12)+4 = 16*i+16`] fold in
    ASSUME_TAC clean) THEN
  X86_STEPS_TAC EXEC (54--57);;
  ALL_TAC;;

let mk_si2_mg2_taken (memsafe:bool) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
    let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
    let popcnt2 = REWRITE_RULE[m8b_def]
       (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE1)) in
    let lanesum8 = rand(concl popcnt2) in
    let mb2 = find_a (fun th -> let c=concl th in is_forall c &&
       can(find_term(fun u->u=`f1bnd:int256`))c &&
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),_) -> true | _ -> false))c) in
    let mb2_tm = concl mb2 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk1_eq = el 1 (CONJUNCTS bb) in
    let block1 = `[word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
                   word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:byte list` in
    let block1len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block1)) in
    let bsum2_raw = prove(mk_imp(mb2_tm, mk_eq(lanesum8, block1len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let pop_len2 = REWRITE_RULE[GSYM blk1_eq] (TRANS popcnt2 (MP bsum2_raw mb2)) in
    ASSUME_TAC pop_len2) THEN
  SUBGOAL_THEN `acc1 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then MP_TAC th else NO_TAC) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+4`] OUTLEN0_LE_256_FROM_SUBITER) THEN
    ANTS_TAC THENL
     [CONJ_TAC THENL
       [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC;
        FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+4) inlist):int32 list) = acc1` then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN ARITH_TAC; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block1len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+4,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `acc1:num` block1len in
    let bridge2 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_) -> true | _ -> false) asl) in
    let lt32 = REWRITE_RULE[SYM bridge2] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32`) asl)) in
    let pop_len2 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let gt248 = REWRITE_RULE[SYM bridge2] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`) asl)) in
    let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
    ASSUME_TAC pop_len2 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (34--35) THEN
  SUBGOAL_THEN `read RIP s35 = word (pc + 314):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let pop_len2_old = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
      let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
      let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2_old) in
      let rax_red0 = find (fun (_,th) -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
      let ja = find (fun (_,th) -> is_neg(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`acc1:num`))(concl th)) asl in
      rip_mp memsafe 314 35 THEN
      REWRITE_TAC[pop_len2_typed] THEN REWRITE_TAC[snd rax_red0] THEN
      REWRITE_TAC[snd ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC];;

let mk_si3_mg3_taken (memsafe:bool) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
    let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
    let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
    let popcnt3 = REWRITE_RULE[m8b_def; m8c_def]
       (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE2)) in
    let lanesum = rand(concl popcnt3) in
    let mb3 = find_a (fun th -> let c=concl th in is_forall c &&
       can(find_term(fun u->u=`f1bnd:int256`))c &&
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`16` | _ -> false))c) in
    let mb3_tm = concl mb3 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) &&
       (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" &&
            length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk2_eq = el 2 (CONJUNCTS bb) in
    let block2 = `[word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
                   word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:byte list` in
    let block2len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block2)) in
    let bsum3_raw = prove(mk_imp(mb3_tm, mk_eq(lanesum, block2len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV)
            (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let pop_len3 = REWRITE_RULE[GSYM blk2_eq] (TRANS popcnt3 (MP bsum3_raw mb3)) in
    ASSUME_TAC pop_len3) THEN
  (* bridge3: acc2 + niblen(SUB(16i+8,4)) = niblen_sample(16i+12)            *)
  SUBGOAL_THEN `acc2 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+8,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then MP_TAC th else NO_TAC) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+8`] OUTLEN0_LE_256_FROM_SUBITER) THEN
    ANTS_TAC THENL
     [CONJ_TAC THENL
       [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC;
        FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) = acc2` then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN ARITH_TAC; ALL_TAC] THEN
  W(fun (asl,w) ->
    let block2len = `LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+8,4) inlist):int16 list)` in
    let sum = mk_binop `(+):num->num->num` `acc2:num` block2len in
    let bridge3 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> true | _ -> false) asl) in
    let lt32 = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32`) asl)) in
    let pop_len3 = snd(find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl) in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    let gt248 = REWRITE_RULE[SYM bridge3] (snd(find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`) asl)) in
    let ja_taken = MP (ISPECL [sum; `248`] JA_TAKEN_GT) (CONJ gt248 lt32) in
    ASSUME_TAC pop_len3 THEN ASSUME_TAC rax_red0 THEN ASSUME_TAC ja_taken) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (46--47) THEN
  SUBGOAL_THEN `read RIP s47 = word (pc + 314):int64` ASSUME_TAC THENL
   [W(fun (asl,w) ->
      let asms = map snd asl in
      let find_a p = find p asms in
      let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
      let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
      let blk16 = find_a (fun th -> is_eq(concl th) &&
         (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
      let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                  (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
      let blk2_eq = el 2 (CONJUNCTS bb) in
      let rax_red0 = find_a (fun th -> match concl th with
          Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) ->
            can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
      let ja = find_a (fun th -> is_neg(concl th) &&
          can(find_term(fun u->match u with Const("word_sub",_)->true|_->false))(concl th) &&
          can(find_term(fun u->u=`acc2:num`))(concl th)) in
      rip_mp memsafe 314 47 THEN
      REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[rax_red0] THEN
      REWRITE_TAC[ja] THEN DISCH_THEN SUBST1_TAC THEN REFL_TAC);
    ALL_TAC];;


let mk_midexit2 (memsafe:bool) (disch:tactic) : tactic =
(mk_prefix_to_s21 memsafe) THEN
  SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
  (mk_mg1_nt memsafe) THEN SI1_FOLD_V2 THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s23",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI2_BODY_TAC THEN
  (mk_si2_mg2_taken memsafe) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  (* discharge if-guard (taken), RAX collapse, RCX collapse                  *)
  W(fun (asl,w) ->
    let pop_len2 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) asl in
    let zbe = MP (SPEC `val (mask8b:int64) MOD 256` zxbyte_eq) (ARITH_RULE `val (mask8b:int64) MOD 256 < 256`) in
    let pop_len2_typed = TRANS (AP_TERM `word_popcount:int32->num` zbe) (snd pop_len2) in
    let rax_red0 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> true | _ -> false) asl in
    let bridge2 = find (fun (_,th) -> match concl th with
        Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc1",_)),_)),_) -> true | _ -> false) asl in
    REWRITE_TAC[pop_len2_typed; snd rax_red0; snd bridge2]) THEN
  W(fun (asl,w) ->
    let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                   (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list)`)
                         (ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+8) inlist):int32 list) < 2 EXP 32`)) in
    REWRITE_TAC[ntake]) THEN
  (* RCX collapse: double +4 nest                                            *)
  MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[ARITH_RULE `16*i+4+4 = 16*i+8`] THEN DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  CONJ_TAC THENL [AP_TERM_TAC THEN ARITH_TAC; disch];;


(* --- SAFE clean-block step/closer + ETA4_CLEAN_BLOCK_SAFE --- *)
let PREFIX_G_FULL_SAFE_TAC : tactic = mk_prefix_g_full false;;

(* ---- clean_block_safe_eta4_tm (port of the eta2 clean-block scaffold) ---- *)
let clean_block_safe_eta4_tm =
  let qvars, body = strip_forall clean_block_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let pretempl = `read events (s:x86state) = (e:(uarch_event)list)` in
  let posttempl =
    `read events (s:x86state) =
       APPEND (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i)
              (e:(uarch_event)list) /\
     memaccess_inbounds
       (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i)
       [(buf:int64),272; (table:int64),2048] [(res:int64),1024]` in
  let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] pretempl)) in
  let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] posttempl)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

(* ---- eta4 SAFE step: plain body (via events-robust prefix) + split finals ---- *)
let ETA4_SAFE_STEP_TAC : tactic =
  PREFIX_G_FULL_SAFE_TAC THEN SI1_FOLD_V2 THEN SI2_INTEGRATED THEN
  SI3_INTEGRATED THEN SI4_INTEGRATED THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ARITH_RULE `16*i+16 = 16*(i+1)`]) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  CONJ_TAC THENL [RAX_FINAL_TAC; ALL_TAC] THEN
  CONJ_TAC THENL [RCX_FINAL_TAC; ALL_TAC];;

let ETA4_SAFE_CLOSER : tactic =
  MP_TAC ETA4_EVENTS_BRIDGE THEN
  ANTS_TAC THENL
   [ REPEAT CONJ_TAC THEN FIRST_ASSUM ACCEPT_TAC;
     DISCH_THEN(fun bridge ->
       CONJ_TAC THENL
        [ REWRITE_TAC[GSYM bridge; APPEND] THEN
          (REFL_TAC ORELSE FIRST_ASSUM ACCEPT_TAC ORELSE ASM_REWRITE_TAC[APPEND]);
          REWRITE_TAC[GSYM bridge] THEN
          REWRITE_TAC[memaccess_inbounds; ALL; EX; FST; SND] THEN
          REPEAT CONJ_TAC THEN
          TRY(REPEAT ((DISJ1_TAC THEN CONTAINED_ASM_TAC) ORELSE DISJ2_TAC ORELSE
                      CONTAINED_ASM_TAC) THEN NO_TAC) THEN
          GATHER_BOUND_TAC ]) ];;

let ETA4_CLEAN_BLOCK_SAFE =
  prove(clean_block_safe_eta4_tm, ETA4_SAFE_STEP_TAC THEN ETA4_SAFE_CLOSER);;

(* --- SAFE loop scaffold + ETA4_LOOP_SAFE --- *)
let ev_concrete_eta4 =
  `read events (s:x86state) =
     APPEND (ENUMERATEL i (f_ev_loop_eta4 res buf table pc
              (REJ_MASK_ETA4 (inlist:byte list)))) (e:(uarch_event)list)`;;

let SAFE_LOOPINV_ETA4 =
  let iv,rest = dest_abs CORRECT_LOOPINV in
  let sv,body = dest_abs rest in
  mk_abs(iv, mk_abs(sv,
    conj_append_right body (vsubst[sv,`s:x86state`; iv,`i:num`] ev_concrete_eta4)));;

let loop_safe_eta4_tm =
  let qvars,body = strip_forall core_ms_tm in
  let hyps_tm,ens = dest_imp body in
  let ensc,ppf = strip_comb ens in
  let pre = el 1 ppf and frame = el 3 ppf in
  let wop = `!m. m < N ==> 16 * m <= 256 /\
               LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let hyps' = list_mk_conj (conjuncts hyps_tm @ [`~(N = 0)`; `~(N = 1)`; wop]) in
  let sv = `s:x86state` in
  let svp,preb = dest_abs pre in
  let pre' = mk_abs(svp, conj_append_right preb
    (vsubst[svp,sv] `read RSP (s:x86state) = stackpointer`)) in
  let iv2,rest2 = dest_abs SAFE_LOOPINV_ETA4 in
  let sv2,invbody = dest_abs rest2 in
  let inv_body = vsubst[`N-1`,iv2; sv,sv2] invbody in
  let post = mk_abs(sv, list_mk_conj
    [ `bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc)`;
      `read RIP s = word(pc + 52)`;
      inv_body ]) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post; frame]) in
  list_mk_forall(qvars @ [`N:num`; `stackpointer:int64`], mk_imp(hyps', ens'));;

let G2_SAFE_BODY_BRIDGE_ETA4_TAC : tactic =
  REPEAT STRIP_TAC THEN
  MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`i:num`;`stackpointer:int64`;
     `APPEND (ENUMERATEL i (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 inlist))) (e:(uarch_event)list)`]
     ETA4_CLEAN_BLOCK_SAFE) THEN
  ANTS_TAC THENL
   [SUBGOAL_THEN `i + 1 < N` ASSUME_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `i+1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN STRIP_TAC THEN
    REPEAT CONJ_TAC THEN
    (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC; ASM_REWRITE_TAC[]]); ALL_TAC] THEN
  DISCH_THEN(fun bth ->
    W(fun (asl,gl) ->
      let lframe = rand(concl bth) in
      let lpost  = rand(rator(concl bth)) in
      let lpre   = rand(rator(rator(concl bth))) in
      let gframe = rand gl in
      let subsumed_tm = mk_binop `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool` lframe gframe in
      let subsumed_th = prove(subsumed_tm,
        REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN SUBSUMED_MAYCHANGE_TAC) in
      let bth' = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
      CONJ_TAC THENL
       [GEN_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[] THEN TRY(ASM_MESON_TAC[]);
        MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
        CONJ_TAC THENL
         [GEN_TAC THEN STRIP_TAC THEN
          ASM_REWRITE_TAC[GSYM SAFE_THREAD_EVENTS_STEP] THEN TRY(ASM_MESON_TAC[]);
          ACCEPT_TAC bth']]));;

let SAFE_LOOP_SCAFFOLD_ETA4_TAC : tactic =
  MAP_EVERY X_GEN_TAC [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                       `e:(uarch_event)list`;`pc:num`;`N:num`;`stackpointer:int64`] THEN
  REWRITE_TAC[C_ARGUMENTS; C_RETURN; SOME_FLAGS; NONOVERLAPPING_CLAUSES;
              LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC] THEN
  STRIP_TAC THEN
  ENSURES_WHILE_UP_TAC `N - 1` `pc + 52` `pc + 52` SAFE_LOOPINV_ETA4 THEN
  REPEAT CONJ_TAC THENL
   [REPEAT(FIRST_X_ASSUM(MP_TAC o check(fun th->concl th=`~(N=0)`||concl th=`~(N=1)`))) THEN ARITH_TAC;
    ENSURES_INIT_TAC "s0" THEN
    X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (1--11) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES; REJ_SAMPLE_ETA4_BYTES;
                REJ_NIBBLES_ETA4; NIBBLES_OF_BYTES; FILTER; MAP; LENGTH; num_of_wordlist] THEN
    CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[READ_COMPONENT_COMPOSE; READ_MEMORY_BYTES_TRIVIAL] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    ASM_REWRITE_TAC[ENUMERATEL; APPEND];
    G2_SAFE_BODY_BRIDGE_ETA4_TAC;
    REPEAT STRIP_TAC THEN ENSURES_INIT_TAC "s0" THEN ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];
    ENSURES_INIT_TAC "s0" THEN ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[]];;

let ETA4_LOOP_SAFE = prove(loop_safe_eta4_tm, SAFE_LOOP_SCAFFOLD_ETA4_TAC);;

(* --- EXIT_OFFSET_SAFE_ETA4 (+ bridges) --- *)
let ev_append_op = `APPEND:(uarch_event)list->(uarch_event)list->(uarch_event)list`;;
let tail_events_e1 =
  `APPEND (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) (N-1))
          (e:(uarch_event)list)`;;
let tail_events_e2 = mk_comb(mk_comb(ev_append_op,`f_ev_headguard_eta4 pc`), tail_events_e1);;
let scalar_tail_events = `f_ev_scalar_tail_eta4 (272 - 272) res buf pc (inlist:byte list) 272`;;
let exit_events_offset = mk_comb(mk_comb(ev_append_op, scalar_tail_events), tail_events_e2);;

(* ---- the two SAFE intermediate predicates (concrete events), rebuilt inline
   exactly as LEG1B_HEADGUARD_SAFE_ETA4 builds q52_safe/q314_safe; then
   specialise ec := tail_events_e1.                                                *)
let q52_pred_e1, q314_pred_e1 =
  let sv56,body56 = dest_abs q56_ms in
  let sv318,body318 = dest_abs q318_ms in
  let q52_safe = mk_abs(sv56,
    mk_conj(subst[`272`,`16 * N`] (lhand body56), `read events (s:x86state) = ec`)) in
  let q314_safe = mk_abs(sv318,
    mk_conj(subst[`272`,`16 * N`] (lhand body318),
            `read events (s:x86state) = APPEND (f_ev_headguard_eta4 pc) ec`)) in
  vsubst[tail_events_e1,`ec:(uarch_event)list`] q52_safe,
  vsubst[tail_events_e1,`ec:(uarch_event)list`] q314_safe;;

(* ---- statement: mirror eta2 exit_offset_safe_eta2_tm (L10986-11001) off the
   eta4 exit_offset_ms_tm; add `read events s = e` to pre and
   `read events s = exit_events_offset` to post (events conjuncts).                  *)
let rej_eta_result =
  `\s:x86state.
    let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES (inlist:byte list)) in
    read RAX s = word(LENGTH outlist) /\
    read(memory :> bytes(res, 4 * LENGTH outlist)) s = num_of_wordlist outlist`;;

let exit_offset_safe_eta4_tm =
  let exoff_ms = snd(strip_forall exit_offset_ms_tm) in
  let hyps_tm, ens = dest_imp exoff_ms in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let pre_val = lhand preb in
  let pre' = mk_abs(sv, mk_conj(pre_val, vsubst[sv,`s:x86state`] `read events (s:x86state) = e`)) in
  let sv2, postb = dest_abs post in
  let post_rip = lhand postb in
  let post_ev = vsubst[sv2,`s:x86state`] (mk_eq(`read events (s:x86state)`, exit_events_offset)) in
  let post' =
    add_rej_eta_result rej_eta_result (mk_abs(sv2, mk_conj(post_rip, post_ev))) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps_tm, list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame])));;

(* ---- bridge tactics (eta4 clones of eta2 EXIT_BRIDGE_CLOSE_TAC / SAFE_BRIDGE_FROM
   / SCALAR_TAIL_LEG2_SAFE, with 16*N=272).  The 16*N=272 rewrite is CORRECT on
   the OFFSET arm (buflen constraint genuinely holds); the clean-closer caveat
   is for the MIDEXIT/core arms (steps d/e), not this one.                     *)
let EXIT_BRIDGE_CLOSE_TAC_ETA4 : tactic =
  GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN RULE_ASSUM_TAC BETA_RULE THEN
  RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `16 * N = 272`]) THEN ASM_REWRITE_TAC[];;

let SAFE_BRIDGE_FROM_ETA4 (bth:thm) : tactic =
  W(fun (asl,gl) ->
    let lframe = rand(concl bth) in
    let lpost  = rand(rator(concl bth)) in
    let lpre   = rand(rator(rator(concl bth))) in
    let gframe = rand gl in
    let subsumed_tm = mk_binop `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool` lframe gframe in
    let subsumed_th = prove(subsumed_tm,
      REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN SUBSUMED_MAYCHANGE_TAC) in
    let bth' = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
    MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
    CONJ_TAC THENL
     [EXIT_BRIDGE_CLOSE_TAC_ETA4;
      MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
      CONJ_TAC THENL [EXIT_BRIDGE_CLOSE_TAC_ETA4; ACCEPT_TAC bth']]);;

let SCALAR_TAIL_LEG2_SAFE_ETA4 (p:term) (etail:term) : tactic =
  W(fun (asl,gl) ->
    let atp = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;p;`stackpointer:int64`;etail]
                    MLDSA_REJ_UNIFORM_ETA4_SCALAR_TAIL_AT_P_SAFE in
    let atp_ens = snd(dest_imp(concl atp)) in
    let _,ppf = strip_comb atp_ens in
    let atp_pre = el 1 ppf and atp_post = el 2 ppf in
    MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC atp_post THEN
    CONJ_TAC THENL
     [EXIT_BRIDGE_CLOSE_TAC_ETA4;
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC atp_pre THEN
      CONJ_TAC THENL
       [EXIT_BRIDGE_CLOSE_TAC_ETA4;
        MP_TAC atp THEN
        ANTS_TAC THENL
         [REPEAT CONJ_TAC THEN
          (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC;
                  (FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` then MP_TAC th else NO_TAC) THEN ARITH_TAC)]);
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_FRAME_SUBSUMED) THEN
          REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
          SUBSUMED_MAYCHANGE_TAC]]]);;


let EXIT_OFFSET_SAFE_ETA4 = prove(exit_offset_safe_eta4_tm,
      REPEAT GEN_TAC THEN STRIP_TAC THEN
      SUBGOAL_THEN `~(N = 0)` ASSUME_TAC THENL
       [UNDISCH_TAC `16 * N = 272` THEN ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` ASSUME_TAC THENL
       [REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
        FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list) <= 248` then ACCEPT_TAC th else NO_TAC); ALL_TAC] THEN
      SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,272) inlist):int32 list) <= 248` ASSUME_TAC THENL
       [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
        SUBST1_TAC(ASSUME `16 * N = 272`) THEN REWRITE_TAC[]; ALL_TAC] THEN
      MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC q314_pred_e1 THEN
      CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN CONJ_TAC THENL
       [MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC q52_pred_e1 THEN
        CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN CONJ_TAC THENL
         [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`] ETA4_CLEAN_BLOCK_SAFE) THEN
          SUBGOAL_THEN `N - 1 + 1 = N` (fun th -> REWRITE_TAC[th]) THENL [ASM_ARITH_TAC; ALL_TAC] THEN
          ANTS_TAC THENL
           [REPEAT CONJ_TAC THEN (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
          DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA4 bth);
          MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`stackpointer:int64`;`e:(uarch_event)list`; tail_events_e1] LEG1B_HEADGUARD_SAFE_ETA4) THEN
          ANTS_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
          DISCH_THEN ACCEPT_TAC];
        SCALAR_TAIL_LEG2_SAFE_ETA4 `272` tail_events_e2]);;

(* --- MID_EXIT_SUBITER1_SAFE_ETA4 (arm 1) --- *)
let midexit_safe_eta4_tm value_tm fev_tm =
  let qvars, body = strip_forall value_tm in
  let hyps_tm, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let pre = el 1 ppf and post = el 2 ppf and frame = el 3 ppf in
  let sv, preb = dest_abs pre in
  let sv2, postb = dest_abs post in
  let pretempl = `read events (s:x86state) = (e:(uarch_event)list)` in
  let posttempl =
    mk_conj(`read events (s:x86state) = APPEND FEV (e:(uarch_event)list)`,
            `memaccess_inbounds FEV [(buf:int64),272; (table:int64),2048] [(res:int64),1024]`) in
  let posttempl = subst [fev_tm, `FEV:(uarch_event)list`] posttempl in
  let pre' = mk_abs(sv, mk_conj(preb, vsubst[sv,`s:x86state`] pretempl)) in
  let post' = mk_abs(sv2, mk_conj(postb, vsubst[sv2,`s:x86state`] posttempl)) in
  let ens' = list_mk_comb(ensc,[el 0 ppf; pre'; post'; frame]) in
  list_mk_forall(qvars @ [`e:(uarch_event)list`], mk_imp(hyps_tm, ens'));;

let midexit1_safe_eta4_tm =
  midexit_safe_eta4_tm midexit1_tm
    `f_ev_midexit_subiter1_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i`;;

(* ---- closer: port of eta2 MID_EXIT_SUBITER1_SAFE_CLOSER (L11389); ETA2->ETA4, 136->272 ---- *)
let MID_EXIT_SUBITER1_SAFE_CLOSER_ETA4 : tactic =
  CONJ_TAC THENL
   [FIRST_ASSUM(fun a1 -> FIRST_ASSUM(fun a2 -> ASSUME_TAC(MP (MP P0_BRIDGE_ETA4 a1) a2))) THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4));
      ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter1_eta4; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER1_ETA4 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`]
               (ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

let MID_EXIT_SUBITER1_SAFE_ETA4 =
  prove(midexit1_safe_eta4_tm, mk_midexit1 false MID_EXIT_SUBITER1_SAFE_CLOSER_ETA4);;

(* --- MID_EXIT_SUBITER2_SAFE_ETA4 (arm 2) --- *)
let MP_BRIDGE_FROM_ASL (bridge:thm) : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let rec go th =
      if is_imp (concl th) then
        let ante = lhand (concl th) in
        let a = try find (fun a -> aconv (concl a) ante) asms
                with Failure _ ->
                  failwith ("MP_BRIDGE_FROM_ASL: unmatched antecedent: " ^
                            string_of_term ante) in
        go (MP th a)
      else th in
    ASSUME_TAC (go bridge));;

let midexit2_safe_eta4_tm =
  midexit_safe_eta4_tm midexit2_tm
    `f_ev_midexit_subiter2_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i`;;
let SUBITER2_SAFE_DISCH_ETA4 : tactic =
  CONJ_TAC THENL
   [MP_BRIDGE_FROM_ASL P0_BRIDGE_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1_ETA4 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA4 (inlist:byte list)))`
      ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with
         Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false)
        then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter2_eta4; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER2_ETA4 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`]
               (ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE_ETA4)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

let MID_EXIT_SUBITER2_SAFE_ETA4 =
  prove(midexit2_safe_eta4_tm, mk_midexit2 false SUBITER2_SAFE_DISCH_ETA4);;

(* --- MID_EXIT_SUBITER3_SAFE_ETA4 (arm 3; RCX4_COLLAPSE tail) --- *)
let ASSUME_MASK_TOWERS : tactic =
  W(fun (asl,w) ->
    let asms = map snd asl in
    let fnd p = find (fun th -> p (concl th)) asms in
    let tower8_mask8b = fnd (fun c -> is_eq c && rand c = `mask8b:int64` &&
        can (find_term (fun u -> match u with Const("word_ushr",_)->true|_->false)) c) in
    let mask8c_def = fnd (fun c -> is_eq c && rand c = `mask8c:int64`) in
    let t16m8c = REWRITE_RULE[SYM tower8_mask8b] mask8c_def in
    let t24opt =
      try let mask8d_def = fnd (fun c -> is_eq c && rand c = `mask8d:int64` &&
            can (find_term (fun u -> match u with Const("word_ushr",_)->true|_->false)) c) in
          [REWRITE_RULE[SYM t16m8c] mask8d_def]
      with Failure _ -> [] in
    EVERY (map ASSUME_TAC (t16m8c :: t24opt)));;

let midexit3_safe_eta4_tm =
  midexit_safe_eta4_tm midexit3_tm
    `f_ev_midexit_subiter3_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i`;;

let SUBITER3_SAFE_DISCH_ETA4 : tactic =
  CONJ_TAC THENL
   [ASSUME_MASK_TOWERS THEN
    MP_BRIDGE_FROM_ASL P0_BRIDGE_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE2_ETA4 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc2 = NUM_ACCEPTED(SUB_LIST(0,32*i+16)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 8) inlist):int32 list) = acc2` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`](ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false) then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
              word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+8,8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 4,4) (inlist:byte list)` | _ -> false) then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    ASM_REWRITE_TAC[f_ev_midexit_subiter3_eta4; APPEND];
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER3_ETA4 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`]
               (ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE_ETA4)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]]];;

(* ---- mk_midexit3_fix: eta4 mk_midexit3 body, tail = eta2 RCX4_COLLAPSE x3 ---- *)
let mk_midexit3_fix (memsafe:bool) (disch:tactic) : tactic =
(mk_prefix_to_s21 memsafe) THEN
  SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
  (mk_mg1_nt memsafe) THEN SI1_FOLD_V2 THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s23",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI2_BODY_TAC THEN (mk_mg2_nt memsafe) THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s35",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI3_BODY3_TAC THEN (mk_si3_mg3_taken memsafe) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) && (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk2_eq = el 2 (CONJUNCTS bb) in
    let pop_len3 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> true | _ -> false) in
    let rax_red0 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> can(find_term(fun u->u=`acc2:num`))(concl th) | _ -> false) in
    let bridge3 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc2",_)),_)),_) -> can(find_term(fun u->match u with Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))->true|_->false))(concl th) | _ -> false) in
    REWRITE_TAC[GSYM blk2_eq] THEN REWRITE_TAC[pop_len3] THEN REWRITE_TAC[rax_red0; bridge3]) THEN
  W(fun (asl,w) ->
    let ntake = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`;`248`] JA_TAKEN_GT)
                   (CONJ (ASSUME `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list)`)
                         (ASSUME `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) < 2 EXP 32`)) in
    REWRITE_TAC[ntake]) THEN
  (* --- eta2 tail (mk_midexit3_eta2): RCX4_COLLAPSE x3, no val-expansion --- *)
  MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
  MP_TAC(SPEC `16*i+8` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  TRY(AP_TERM_TAC THEN ARITH_TAC) THEN REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN disch;;

let MID_EXIT_SUBITER3_SAFE_ETA4 =
  prove(midexit3_safe_eta4_tm, mk_midexit3_fix false SUBITER3_SAFE_DISCH_ETA4);;

(* --- MID_EXIT_SUBITER4_SAFE_ETA4 (arm 4; RCX4_COLLAPSE x4 tail) --- *)
let midexit4_safe_eta4_tm =
  midexit_safe_eta4_tm midexit4_tm
    `f_ev_midexit_subiter4_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) i`;;

(* ---- SUB4_EVENTS_CLOSER_ETA4 (port of eta2) ---- *)
let SUB4_EVENTS_CLOSER_ETA4 : tactic =
    ASSUME_MASK_TOWERS THEN
    MP_BRIDGE_FROM_ASL P0_BRIDGE_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE1_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE2_ETA4 THEN
    MP_BRIDGE_FROM_ASL GATHER_BRIDGE3_ETA4 THEN
    SUBGOAL_THEN `outlen0 = NUM_ACCEPTED(SUB_LIST(0,32*i)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i) inlist):int32 list) = outlen0` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i) = 32 * i`](ISPECL[`inlist:byte list`;`16*i`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc1 = NUM_ACCEPTED(SUB_LIST(0,32*i+8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 4) inlist):int32 list) = acc1` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`](ISPECL[`inlist:byte list`;`16*i+4`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc2 = NUM_ACCEPTED(SUB_LIST(0,32*i+16)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 8) inlist):int32 list) = acc2` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`](ISPECL[`inlist:byte list`;`16*i+8`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN `acc3 = NUM_ACCEPTED(SUB_LIST(0,32*i+24)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if concl th = `LENGTH (REJ_SAMPLE_ETA4_BYTES (SUB_LIST (0,16 * i + 12) inlist):int32 list) = acc3` then SUBST1_TAC(SYM th) else NO_TAC) THEN
      MATCH_ACCEPT_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 12) = 32 * i + 24`](ISPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE_ETA4)); ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (0,8); word_subword chunk0 (8,8);
              word_subword chunk0 (16,8); word_subword chunk0 (24,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i,8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i,4) (inlist:byte list)` | _ -> false) then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i) = 32 * i`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (32,8); word_subword chunk0 (40,8);
              word_subword chunk0 (48,8); word_subword chunk0 (56,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+8,8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 4,4) (inlist:byte list)` | _ -> false) then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 4) = 32 * i + 8`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    SUBGOAL_THEN
      `LENGTH(REJ_NIBBLES_ETA4 [word_subword (chunk0:int128) (64,8); word_subword chunk0 (72,8);
              word_subword chunk0 (80,8); word_subword chunk0 (88,8)]:int16 list) =
       NUM_ACCEPTED(SUB_LIST(32*i+16,8)(REJ_MASK_ETA4 (inlist:byte list)))` ASSUME_TAC THENL
     [FIRST_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),l),_) -> l = `SUB_LIST (16 * i + 8,4) (inlist:byte list)` | _ -> false) then SUBST1_TAC(SYM th) else NO_TAC) THEN
      REWRITE_TAC[LENGTH_REJ_NIBBLES_ETA4_EQ_MASK; GSYM NUM_ACCEPTED; REJ_MASK_ETA4_SUB_LIST] THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * i + 8) = 32 * i + 16`; ARITH_RULE `2 * 4 = 8`]; ALL_TAC] THEN
    (* NOTE: eta4 def f_ev_midexit_subiter4_eta4 keeps mg3 (pc+268) SYMBOLIC (unlike eta2,
       which resolves it via SUB4_MG3_REDUCE). So DO NOT resolve — the acc2/block2 SUBGOALs
       fold the raw COND operands (acc2, LENGTH(REJ_NIBBLES block2)) to NUM_ACCEPTED, matching
       the symbolic def. This is the eta2->eta4 def-shape difference. *)
    ASM_REWRITE_TAC[f_ev_midexit_subiter4_eta4; APPEND];;

(* ---- SUB4_MEMACCESS_CLOSER_ETA4 (port of eta2) ---- *)
let SUB4_MEMACCESS_CLOSER_ETA4 : tactic =
    MATCH_MP_TAC MEMACCESS_F_EV_MIDEXIT_SUBITER4_ETA4 THEN
    CONJ_TAC THENL
     [UNDISCH_TAC `16 * (i + 1) <= 272` THEN ARITH_TAC;
      MP_TAC(REWRITE_RULE[ARITH_RULE `2 * (16 * i + 12) = 32 * i + 24`]
               (ISPECL[`inlist:byte list`;`16*i+12`] STORE_BRIDGE_ETA4)) THEN
      DISCH_THEN(SUBST1_TAC o SYM) THEN ASM_REWRITE_TAC[]];;

let SUBITER4_SAFE_DISCH_ETA4 : tactic =
  W(fun (asl,w) -> if is_eq w then SUB4_EVENTS_CLOSER_ETA4 else SUB4_MEMACCESS_CLOSER_ETA4);;

(* ---- mk_midexit4_fix: eta4 mk_midexit4 body, tail = eta2 RCX4_COLLAPSE x4 ---- *)
let mk_midexit4_fix (memsafe:bool) (disch:tactic) : tactic =
(mk_prefix_to_s21 memsafe) THEN
  SUBGOAL_THEN `16 * i + 4 <= LENGTH(inlist:byte list)` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
  (mk_mg1_nt memsafe) THEN SI1_FOLD_V2 THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s23",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI2_BODY_TAC THEN (mk_mg2_nt memsafe) THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s35",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI3_BODY3_TAC THEN (mk_mg3_nt memsafe) THEN
  FIRST_X_ASSUM(fun th -> match concl th with
    Comb(Comb(Const("=",_),Comb(Comb(Const("read",_),Const("RIP",_)),Var("s47",_))),r) when
      (match r with Comb(Comb(Comb(Const("COND",_),_),_),_)->true|_->false) -> ALL_TAC | _ -> NO_TAC) THEN
  SI4_BODY4_TAC THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) <= 256` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+12`] OUTLEN0_LE_256_FROM_SUBITER) THEN
    ANTS_TAC THENL
     [CONJ_TAC THENL
       [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC;
        FIRST_X_ASSUM(fun th -> if (match concl th with Comb(Comb(Const("=",_),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_))),Var("acc3",_))->true|_->false) then SUBST1_TAC th else NO_TAC) THEN FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    REWRITE_TAC[ARITH_RULE `(16*i+12)+4 = 16*(i+1)`; ARITH_RULE `16*i+16=16*(i+1)`]; ALL_TAC] THEN
  SUBGOAL_THEN `acc3 + LENGTH(REJ_NIBBLES_ETA4 (SUB_LIST(16*i+12,4) inlist):int16 list) = LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)` ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`;`16*i+12`] SUBITER_BRIDGE_ETA4) THEN
    ANTS_TAC THENL [UNDISCH_TAC `16 * (i+1) <= 272` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC; ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (K ALL_TAC) (CONJUNCTS_THEN2 MP_TAC (K ALL_TAC))) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES; ARITH_RULE `(16*i+12)+4 = 16*(i+1)`; ARITH_RULE `16*i+16 = 16*(i+1)`] THEN
    FIRST_X_ASSUM(fun th -> if concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*i+12) inlist):int32 list) = acc3` then MP_TAC th else NO_TAC) THEN
    REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC; ALL_TAC] THEN
  W(fun (asl,w) ->
    let asms = map snd asl in
    let find_a p = find p asms in
    let m8c_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8c:int64` | _ -> false) in
    let m8b_def = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8b:int64` | _ -> false) in
    let m8d_val = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),_),r) -> r = `mask8d:int64` && can(find_term(fun u->match u with Const("word_ushr",_)->true|_->false))(concl th) | _ -> false) in
    let pinst = `\k. bit 7 (word_subword (f1bnd:int256) (8*k,8):byte)` in
    let popcnt4 = REWRITE_RULE[m8d_val] (REWRITE_RULE[m8b_def; m8c_def]
       (CONV_RULE(DEPTH_CONV BETA_CONV THENC ONCE_DEPTH_CONV NUM_REDUCE_CONV) (SPEC pinst POPCNT_BYTE3))) in
    let lanesum = rand(concl popcnt4) in
    let mb4 = find_a (fun th -> let c=concl th in is_forall c && can(find_term(fun u->u=`f1bnd:int256`))c &&
       can(find_term(fun u-> match u with Comb(Comb(Const("+",_),Var("k",_)),n) -> n=`24` | _ -> false))c) in
    let mb4_tm = concl mb4 in
    let i_le = find_a (fun th -> concl th = `16 * i <= 256`) in
    let leninl = find_a (fun th -> concl th = `LENGTH(inlist:byte list) = 272`) in
    let blk16 = find_a (fun th -> is_eq(concl th) && (try fst(dest_const(fst(strip_comb(lhand(concl th)))))="SUB_LIST" && length(dest_list(rand(concl th)))=16 with _->false)) in
    let bb = MP (ISPECL [`inlist:byte list`; `i:num`; `chunk0:int128`] SUBITER_BLOCK_BYTES)
                (CONJ (REWRITE_RULE[GSYM leninl] (MP (ARITH_RULE `16*i<=256 ==> 16*i+16<=272`) i_le)) blk16) in
    let blk3_eq = el 3 (CONJUNCTS bb) in
    let block3 = `[word_subword (chunk0:int128) (96,8); word_subword chunk0 (104,8); word_subword chunk0 (112,8); word_subword chunk0 (120,8)]:byte list` in
    let block3len_x = mk_comb(`LENGTH:(int16)list->num`, mk_comb(`REJ_NIBBLES_ETA4`, block3)) in
    let bsum4_raw = prove(mk_imp(mb4_tm, mk_eq(lanesum, block3len_x)),
      DISCH_THEN(fun mbthm ->
        let mbs = map (fun k -> let th=SPEC(mk_small_numeral k) mbthm in
          CONV_RULE (NUM_REDUCE_CONV THENC ONCE_DEPTH_CONV EL_CONV) (MP th (EQT_ELIM(NUM_REDUCE_CONV(lhand(concl th)))))) [0;1;2;3;4;5;6;7] in
        REWRITE_TAC mbs) THEN
      GEN_REWRITE_TAC RAND_CONV [GSYM LENGTH_FILTER_BYTE_NIBBLES_4_BYTES] THEN
      REWRITE_TAC[GSYM BITVAL_SUM_8_EQ_LENGTH_FILTER] THEN
      SIMP_TAC[VAL_WORD_BYTE_LT256; BYTE_DIV16_LT; BYTE_MOD16_LT]) in
    let pop_len4 = REWRITE_RULE[GSYM blk3_eq] (TRANS popcnt4 (MP bsum4_raw mb4)) in
    let bridge4 = find_a (fun th -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_)))->true|_->false) in
    let le256 = find_a (fun th -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) <= 256`) in
    let lt32 = REWRITE_RULE[SYM bridge4] (MATCH_MP (ARITH_RULE `a<=256 ==> a < 2 EXP 32`) le256) in
    let rax_red0 = MATCH_MP RAX_NEST_REDUCE lt32 in
    ASSUME_TAC pop_len4 THEN ASSUME_TAC rax_red0) THEN
  W(fun (asl,w) ->
    let pl4 = find (fun (_,th) -> match concl th with Comb(Comb(Const("=",_),Comb(Const("word_popcount",_),_)),_) -> can(find_term(fun u->u=`mask8d:int64`))(concl th) | _ -> false) asl in
    let rr = find (fun (_,th) -> match concl th with Comb(Comb(Const("=",_),Comb(Const("word_zx",_),Comb(Comb(Const("word_add",_),_),_))),_) -> can(find_term(fun u->u=`acc3:num`))(concl th) | _ -> false) asl in
    let bridge4 = find (fun (_,th) -> match concl th with Comb(Comb(Const("=",_),Comb(Comb(Const("+",_),Var("acc3",_)),_)),Comb(Const("LENGTH",_),Comb(Const("REJ_SAMPLE_ETA4_BYTES",_),_)))->true|_->false) asl in
    RULE_ASSUM_TAC(REWRITE_RULE[snd pl4]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd rr]) THEN RULE_ASSUM_TAC(REWRITE_RULE[snd bridge4])) THEN
  SUBGOAL_THEN `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32` ASSUME_TAC THENL
   [UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) <= 256` THEN ARITH_TAC; ALL_TAC] THEN
  W(fun (asl,w) ->
    let gt248 = find (fun (_,th) -> concl th = `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`) asl in
    let lt32 = find (fun (_,th) -> concl th = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list) < 2 EXP 32`) asl in
    let ja_taken = MP (ISPECL [`LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(i+1)) inlist):int32 list)`; `248`] JA_TAKEN_GT) (CONJ (snd gt248) (snd lt32)) in
    ASSUME_TAC ja_taken) THEN
  X86_STEPS_TAC MLDSA_REJ_UNIFORM_ETA4_EXEC (58--59) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  (* --- eta2 tail (mk_midexit4_eta2): RCX4_COLLAPSE x4, late normalize --- *)
  MP_TAC(SPEC `16*i` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN
  MP_TAC(SPEC `16*i+4` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+4)+4 = 16*i+8`] THEN
  MP_TAC(SPEC `16*i+8` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+8)+4 = 16*i+12`] THEN
  MP_TAC(SPEC `16*i+12` RCX4_COLLAPSE) THEN ANTS_TAC THENL [UNDISCH_TAC `16*i<=256` THEN ARITH_TAC; ALL_TAC] THEN
  DISCH_THEN(fun th -> REWRITE_TAC[th]) THEN REWRITE_TAC[ARITH_RULE `(16*i+12)+4 = 16*i+16`] THEN
  REWRITE_TAC[ARITH_RULE `16*(i+1) = 16*i+16`] THEN
  ASM_REWRITE_TAC[] THEN TRY(CONJ_TAC) THEN TRY REFL_TAC THEN TRY(AP_TERM_TAC THEN ARITH_TAC) THEN disch;;

let MID_EXIT_SUBITER4_SAFE_ETA4 =
  prove(midexit4_safe_eta4_tm, mk_midexit4_fix false SUBITER4_SAFE_DISCH_ETA4);;

(* --- SAFE dispatch machinery + 5 EXIT_BLOCK_SAFE arms + assembly --- *)
(* --- SAFE dispatch tactics --- *)
let midexit_qpost_safe_eta4 (midthm:thm) : term =
  let post = rand(rator(snd(dest_imp(snd(strip_forall(concl midthm)))))) in
  let post = vsubst [`N-1`,`i:num`] post in
  let sv, body = dest_abs post in
  let value_post = lhand body in
  let ev_and_ma  = rand body in
  let ev_eq      = lhand ev_and_ma in
  mk_abs(sv, mk_conj(value_post, ev_eq));;

let MIDEXIT_DISPATCH_SAFE_ETA4 (safearm:thm) (fev_tm:term) (pexpr:term) (prevpos:term) : tactic =
  let qpost = midexit_qpost_safe_eta4 safearm in
  let _, qbody = dest_abs qpost in
  let etail = rand (rand qbody) in
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN EXISTS_TAC qpost THEN
  CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
  CONJ_TAC THENL
   [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`] safearm) THEN
    ANTS_TAC THENL
     [REPEAT CONJ_TAC THEN (FIRST [FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
    DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA4 bth);
    SUBGOAL_THEN (mk_comb(mk_comb(`(<=):num->num->bool`,
        mk_comb(`LENGTH:(int32)list->num`, mk_comb(`REJ_SAMPLE_ETA4_BYTES:byte list->int32 list`,
          mk_comb(mk_comb(`SUB_LIST:num#num->byte list->byte list`,mk_pair(`0`,pexpr)),`inlist:byte list`)))), `256`)) ASSUME_TAC THENL
     [SUBGOAL_THEN (mk_eq(pexpr, mk_binop `(+):num->num->num` prevpos `4`)) SUBST1_TAC THENL
       [UNDISCH_TAC `~(N=0)` THEN UNDISCH_TAC `16 * N <= 272` THEN ARITH_TAC; ALL_TAC] THEN
      MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER THEN CONJ_TAC THENL
       [UNDISCH_TAC `16 * N <= 272` THEN UNDISCH_TAC `~(N=0)` THEN UNDISCH_TAC `LENGTH(inlist:byte list)=272` THEN ARITH_TAC;
        FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
    SCALAR_TAIL_LEG2_SAFE_ETA4 pexpr etail];;

let OFFSET_ARM_SAFE_ETA4_TAC : tactic =
  SUBGOAL_THEN `16 * N = 272` ASSUME_TAC THENL
   [SUBGOAL_THEN `256 < 16 * N` ASSUME_TAC THENL
     [UNDISCH_TAC `256 < 16 * N \/ 248 < LENGTH (REJ_NIBBLES_ETA4 (SUB_LIST (0,16 * N) inlist):int16 list)` THEN
      REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
      UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
      ARITH_TAC; ALL_TAC] THEN
    SUBGOAL_THEN `N = 17` (fun th -> REWRITE_TAC[th] THEN CONV_TAC NUM_REDUCE_CONV) THEN
    SUBGOAL_THEN `16 * N <= 272` ASSUME_TAC THENL
     [UNDISCH_TAC `16 * (N-1) <= 256` THEN UNDISCH_TAC `~(N=0)` THEN
      SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC; ALL_TAC] THEN
    UNDISCH_TAC `256 < 16 * N` THEN UNDISCH_TAC `16 * N <= 272` THEN ARITH_TAC; ALL_TAC] THEN
  MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;`stackpointer:int64`;`e:(uarch_event)list`] EXIT_OFFSET_SAFE_ETA4) THEN
  ANTS_TAC THENL
   [ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ASM_REWRITE_TAC[] THEN
    UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
    SUBST1_TAC(ASSUME `16 * N = 272`) THEN REWRITE_TAC[]; ALL_TAC] THEN
  DISCH_THEN(fun bth -> SAFE_BRIDGE_FROM_ETA4 bth);;

(* --- EXIT_BLOCK_SAFE arms 2/3/4 (defines shared builder) --- *)
let MASK_DBL_N1_ETA4 = ARITH_RULE `2 * (16 * (N - 1)) = 32 * (N - 1)`;;
let MASK_DBL_N_ETA4 = ARITH_RULE `2 * (16 * N) = 32 * N`;;
let MASK_DBL_N1_4_ETA4 = ARITH_RULE `2 * (16 * (N - 1) + 4) = 32 * (N - 1) + 8`;;
let MASK_DBL_N1_8_ETA4 = ARITH_RULE `2 * (16 * (N - 1) + 8) = 32 * (N - 1) + 16`;;
let MASK_DBL_N1_12_ETA4 = ARITH_RULE `2 * (16 * (N - 1) + 12) = 32 * (N - 1) + 24`;;

let MASK_OF_ETA4 (maskgoal:term) (bexp:term) (redthm:thm) : tactic =
  SUBGOAL_THEN maskgoal ASSUME_TAC THENL
   [MP_TAC(SPECL [`inlist:byte list`; bexp] STORE_BRIDGE_ETA4) THEN
    REWRITE_TAC[redthm] THEN
    DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
    ALL_TAC];;

let mk_midexit_safe_tm_eta4 (extraconds:term list) : term =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA4)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 256 /\
                 LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `256 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list)` in
  let hyps' = list_mk_conj (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN] @ extraconds) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let MIDEXIT_SETUP_TAC_ETA4 : tactic =
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 256 /\
     LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  SUBGOAL_THEN
    `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)) inlist):int32 list) <= 248`
    ASSUME_TAC THENL
   [ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES]; ALL_TAC] THEN
  SUBGOAL_THEN `16 * N <= 272` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (N-1) <= 256` THEN UNDISCH_TAC `~(N = 0)` THEN
    SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
    ALL_TAC];;

let exit_block_midexit2_safe_tm_eta4 = mk_midexit_safe_tm_eta4
  [`~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248)`];;

let midexit2_concrete_post_eta4 =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 8)) res buf pc inlist (16 * (N-1) + 8))
                (APPEND (f_ev_midexit_subiter2_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT2_ETA4 = prove
 (exit_block_midexit2_safe_tm_eta4,
  MIDEXIT_SETUP_TAC_ETA4 THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit2_concrete_post_eta4 THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1_ETA4 THEN
    MASK_OF_ETA4 `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248)`
            `16 * N` MASK_DBL_N_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4_ETA4 THEN
    MASK_OF_ETA4 `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248)`
            `16 * (N-1) + 8` MASK_DBL_N1_8_ETA4 THEN
    MATCH_MP_TAC MIDEXIT2_EXISTS_ETA4 THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA4 MID_EXIT_SUBITER2_SAFE_ETA4
      `f_ev_midexit_subiter2_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) (N-1)`
      `16*(N-1)+8` `16*(N-1)+4`]);;

let exit_block_midexit3_safe_tm_eta4 = mk_midexit_safe_tm_eta4
  [`~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248`;
   `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248)`];;

let midexit3_concrete_post_eta4 =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 12)) res buf pc inlist (16 * (N-1) + 12))
                (APPEND (f_ev_midexit_subiter3_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT3_ETA4 = prove
 (exit_block_midexit3_safe_tm_eta4,
  MIDEXIT_SETUP_TAC_ETA4 THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit3_concrete_post_eta4 THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1_ETA4 THEN
    MASK_OF_ETA4 `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248)`
            `16 * N` MASK_DBL_N_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 8` MASK_DBL_N1_8_ETA4 THEN
    MASK_OF_ETA4 `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248)`
            `16 * (N-1) + 12` MASK_DBL_N1_12_ETA4 THEN
    MATCH_MP_TAC MIDEXIT3_EXISTS_ETA4 THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA4 MID_EXIT_SUBITER3_SAFE_ETA4
      `f_ev_midexit_subiter3_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) (N-1)`
      `16*(N-1)+12` `16*(N-1)+8`]);;

(* --- OFFSET arm --- *)
let exit_block_offset_safe_tm_eta4 =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA4)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 256 /\
                 LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `256 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list)` in
  let offbyte = `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` in
  let hyps' = list_mk_conj (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN; offbyte]) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let EXIT_BLOCK_SAFE_OFFSET_ETA4 = prove
 (exit_block_offset_safe_tm_eta4,
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 256 /\
     LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC (rand(rator(snd(dest_imp(snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA4))))))) THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SUBGOAL_THEN `16 * N = 272` ASSUME_TAC THENL
     [SUBGOAL_THEN `N = 17` (fun th -> REWRITE_TAC[th] THEN CONV_TAC NUM_REDUCE_CONV) THEN
      SUBGOAL_THEN `256 < 16 * N` ASSUME_TAC THENL
       [UNDISCH_TAC `256 < 16 * N \/
                     248 < LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list)` THEN
        REWRITE_TAC[GSYM LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN
        UNDISCH_TAC `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THEN
        ARITH_TAC;
        ALL_TAC] THEN
      SUBGOAL_THEN `16 * N <= 272` ASSUME_TAC THENL
       [UNDISCH_TAC `16 * (N-1) <= 256` THEN UNDISCH_TAC `~(N = 0)` THEN
        SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
        ALL_TAC] THEN
      UNDISCH_TAC `256 < 16 * N` THEN UNDISCH_TAC `16 * N <= 272` THEN ARITH_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN
      `NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * N`] STORE_BRIDGE_ETA4) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * N) = 32 * N`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    MATCH_MP_TAC OFFSET_EXISTS_ETA4 THEN ASM_REWRITE_TAC[];
    OFFSET_ARM_SAFE_ETA4_TAC]);;

(* --- MIDEXIT1 arm --- *)
let exit_block_midexit1_safe_tm_eta4 =
  let body = snd(strip_forall(concl EXIT_OFFSET_SAFE_ETA4)) in
  let hyps_off, ens = dest_imp body in
  let ensc, ppf = strip_comb ens in
  let step = el 0 ppf and pre = el 1 ppf and frame = el 3 ppf in
  let shared = fst(chop_list 6 (conjuncts hyps_off)) in
  let wopf = `!m. m < N ==> 16 * m <= 256 /\
                 LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*m) inlist):int16 list) <= 248` in
  let pN = `256 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list)` in
  let midcase = `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)` in
  let sub1sel = `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248)` in
  let hyps' = list_mk_conj
    (shared @ [`~(N = 0)`; `~(N = 1)`; wopf; pN; midcase; sub1sel]) in
  let sv = `s:x86state` in
  let ctpost = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) N /\
           memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(ensc,[step; pre; ctpost; frame]) in
  list_mk_forall
    ([`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;
      `N:num`;`stackpointer:int64`;`e:(uarch_event)list`],
     mk_imp(hyps', ens'));;

let midexit1_concrete_post_eta4 =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail_eta4 (272 - (16 * (N-1) + 4)) res buf pc inlist (16 * (N-1) + 4))
                (APPEND (f_ev_midexit_subiter1_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT1_ETA4 = prove
 (exit_block_midexit1_safe_tm_eta4,
  REPEAT GEN_TAC THEN DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  SUBGOAL_THEN
    `16 * (N-1) <= 256 /\
     LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*(N-1)) inlist):int16 list) <= 248`
    STRIP_ASSUME_TAC THENL
   [FIRST_X_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
    ANTS_TAC THENL [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; REWRITE_TAC[]];
    ALL_TAC] THEN
  SUBGOAL_THEN
    `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)) inlist):int32 list) <= 248`
    ASSUME_TAC THENL
   [ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES]; ALL_TAC] THEN
  SUBGOAL_THEN `16 * N <= 272` ASSUME_TAC THENL
   [UNDISCH_TAC `16 * (N-1) <= 256` THEN UNDISCH_TAC `~(N = 0)` THEN
    SPEC_TAC(`N:num`,`N:num`) THEN INDUCT_TAC THEN ARITH_TAC;
    ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit1_concrete_post_eta4 THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    SUBGOAL_THEN `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * (N-1)`] STORE_BRIDGE_ETA4) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (N-1)) = 32 * (N-1)`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248)`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * N`] STORE_BRIDGE_ETA4) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * N) = 32 * N`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    SUBGOAL_THEN `~(NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248)`
      ASSUME_TAC THENL
     [MP_TAC(SPECL [`inlist:byte list`; `16 * (N-1) + 4`] STORE_BRIDGE_ETA4) THEN
      REWRITE_TAC[ARITH_RULE `2 * (16 * (N-1) + 4) = 32 * (N-1) + 8`] THEN
      DISCH_THEN(fun th -> REWRITE_TAC[GSYM th]) THEN FIRST_ASSUM ACCEPT_TAC;
      ALL_TAC] THEN
    MATCH_MP_TAC MIDEXIT1_EXISTS_ETA4 THEN ASM_REWRITE_TAC[];
    MIDEXIT_DISPATCH_SAFE_ETA4 MID_EXIT_SUBITER1_SAFE_ETA4
      `f_ev_midexit_subiter1_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) (N-1)`
      `16*(N-1)+4` `16*(N-1)`]);;

(* --- MIDEXIT4 arm --- *)
let SAFE_BRIDGE_CLEAN_ETA4 (bth:thm) : tactic =
  W(fun (asl,gl) ->
    let lframe = rand(concl bth) in
    let lpost  = rand(rator(concl bth)) in
    let lpre   = rand(rator(rator(concl bth))) in
    let gframe = rand gl in
    let subsumed_tm = mk_binop
      `(subsumed):(x86state->x86state->bool)->(x86state->x86state->bool)->bool`
      lframe gframe in
    let subsumed_th = prove(subsumed_tm,
      REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
      SUBSUMED_MAYCHANGE_TAC) in
    let bth2 = MATCH_MP ENSURES_FRAME_SUBSUMED (CONJ subsumed_th bth) in
    MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC lpre THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC lpost THEN
      CONJ_TAC THENL
       [GEN_TAC THEN BETA_TAC THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
        ACCEPT_TAC bth2]]);;

let SCALAR_TAIL_LEG2_CLEAN_ETA4 (p:term) (etail:term) : tactic =
  W(fun (asl,gl) ->
    let atp = SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                     `pc:num`;p;`stackpointer:int64`;etail]
                    MLDSA_REJ_UNIFORM_ETA4_SCALAR_TAIL_AT_P_SAFE in
    let atp_ens = snd(dest_imp(concl atp)) in
    let _,ppf = strip_comb atp_ens in
    let atp_pre = el 1 ppf and atp_post = el 2 ppf in
    MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN EXISTS_TAC atp_post THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC ENSURES_PRECONDITION_THM THEN EXISTS_TAC atp_pre THEN
      CONJ_TAC THENL
       [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
        MP_TAC atp THEN ANTS_TAC THENL
         [REPEAT CONJ_TAC THEN FIRST_ASSUM ACCEPT_TAC;
          MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] ENSURES_FRAME_SUBSUMED) THEN
          REPEAT(MATCH_MP_TAC SUBSUMED_SEQ THEN REWRITE_TAC[SUBSUMED_REFL]) THEN
          SUBSUMED_MAYCHANGE_TAC]]]);;

let exit_block_midexit4_safe_tm_eta4 = mk_midexit_safe_tm_eta4
  [`~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248`;
   `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248`];;

let midexit4_concrete_post_eta4 =
  add_rej_eta_result rej_eta_result
   `\s. read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
       read events s =
         APPEND (f_ev_scalar_tail_eta4 (272 - (16 * ((N-1) + 1))) res buf pc inlist (16 * ((N-1) + 1)))
                (APPEND (f_ev_midexit_subiter4_eta4 res buf table pc (REJ_MASK_ETA4 inlist) (N-1))
                        (e:(uarch_event)list))`;;

let EXIT_BLOCK_SAFE_MIDEXIT4_ETA4 = prove
 (exit_block_midexit4_safe_tm_eta4,
  MIDEXIT_SETUP_TAC_ETA4 THEN
  SUBGOAL_THEN `16 * ((N-1) + 1) = 16 * N` ASSUME_TAC THENL
   [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; ALL_TAC] THEN
  SUBGOAL_THEN
    `248 < LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*((N-1)+1)) inlist):int32 list)`
    ASSUME_TAC THENL
   [SUBST1_TAC(ASSUME `16 * ((N-1) + 1) = 16 * N`) THEN
    UNDISCH_TAC `~(LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248)` THEN
    ARITH_TAC; ALL_TAC] THEN
  MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
  EXISTS_TAC midexit4_concrete_post_eta4 THEN
  CONJ_TAC THENL
   [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
    CONJ_TAC THENL [ASM_REWRITE_TAC[]; ALL_TAC] THEN
    RULE_ASSUM_TAC(REWRITE_RULE[ASSUME `16 * ((N-1) + 1) = 16 * N`]) THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1))(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1)` MASK_DBL_N1_ETA4 THEN
    MASK_OF_ETA4 `~(NUM_ACCEPTED(SUB_LIST(0,32 * N)(REJ_MASK_ETA4 inlist)) <= 248)`
            `16 * N` MASK_DBL_N_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 8)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 4` MASK_DBL_N1_4_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 16)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 8` MASK_DBL_N1_8_ETA4 THEN
    MASK_OF_ETA4 `NUM_ACCEPTED(SUB_LIST(0,32 * (N-1) + 24)(REJ_MASK_ETA4 inlist)) <= 248`
            `16 * (N-1) + 12` MASK_DBL_N1_12_ETA4 THEN
    MATCH_MP_TAC MIDEXIT4_EXISTS_ETA4 THEN ASM_REWRITE_TAC[];
    MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN
    EXISTS_TAC (midexit_qpost_safe_eta4 MID_EXIT_SUBITER4_SAFE_ETA4) THEN
    CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
    CONJ_TAC THENL
     [MP_TAC(SPECL [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;
                    `pc:num`;`N-1`;`stackpointer:int64`;`e:(uarch_event)list`]
                   MID_EXIT_SUBITER4_SAFE_ETA4) THEN
      ANTS_TAC THENL
       [REPEAT CONJ_TAC THEN (FIRST[FIRST_ASSUM ACCEPT_TAC; ASM_ARITH_TAC]); ALL_TAC] THEN
      DISCH_THEN(fun bth -> SAFE_BRIDGE_CLEAN_ETA4 bth);
      SUBGOAL_THEN `16 * ((N-1) + 1) <= 272` ASSUME_TAC THENL
       [UNDISCH_TAC `16 * N <= 272` THEN UNDISCH_TAC `16 * ((N-1) + 1) = 16 * N` THEN
        ARITH_TAC; ALL_TAC] THEN
      SUBGOAL_THEN
        `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*((N-1)+1)) inlist):int32 list) <= 256`
        ASSUME_TAC THENL
       [SUBGOAL_THEN `16 * ((N-1) + 1) = (16 * (N-1) + 12) + 4` SUBST1_TAC THENL
         [UNDISCH_TAC `~(N = 0)` THEN ARITH_TAC; ALL_TAC] THEN
        MATCH_MP_TAC OUTLEN0_LE_256_FROM_SUBITER THEN CONJ_TAC THENL
         [UNDISCH_TAC `16 * N <= 272` THEN UNDISCH_TAC `16 * ((N-1) + 1) = 16 * N` THEN
          UNDISCH_TAC `LENGTH(inlist:byte list) = 272` THEN ARITH_TAC;
          FIRST_ASSUM ACCEPT_TAC]; ALL_TAC] THEN
      SCALAR_TAIL_LEG2_CLEAN_ETA4 `16 * ((N-1) + 1)`
        `APPEND (f_ev_midexit_subiter4_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) (N-1))
                (e:(uarch_event)list)`]]);;

(* --- EXIT_BLOCK_SAFE_ETA4 (assembled) --- *)
let exit_block_safe_eta4_tm = mk_midexit_safe_tm_eta4 [];;

let EXIT_BLOCK_SAFE_ETA4 = prove
 (exit_block_safe_eta4_tm,
  MIDEXIT_SETUP_TAC_ETA4 THEN
  ASM_CASES_TAC
    `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*N) inlist):int32 list) <= 248` THENL
   [MATCH_MP_TAC EXIT_BLOCK_SAFE_OFFSET_ETA4 THEN ASM_REWRITE_TAC[];
    ASM_CASES_TAC
      `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+4) inlist):int32 list) <= 248` THENL
     [ASM_CASES_TAC
        `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+8) inlist):int32 list) <= 248` THENL
       [ASM_CASES_TAC
          `LENGTH(REJ_SAMPLE_ETA4_BYTES(SUB_LIST(0,16*(N-1)+12) inlist):int32 list) <= 248` THENL
         [MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT4_ETA4 THEN ASM_REWRITE_TAC[];
          MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT3_ETA4 THEN ASM_REWRITE_TAC[]];
        MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT2_ETA4 THEN ASM_REWRITE_TAC[]];
      MATCH_MP_TAC EXIT_BLOCK_SAFE_MIDEXIT1_ETA4 THEN ASM_REWRITE_TAC[]]]);;


(* --- CORE_SAFE_FREEN_ETA4 --- *)
let core_safe_freeN_tm_eta4 =
  let bod = snd(strip_forall(concl ETA4_LOOP_SAFE)) in
  let hyps,ens = dest_imp bod in
  let comb,args = strip_comb ens in
  let step = el 0 args and pre = el 1 args and frame = el 3 args in
  let pN = `256 < 16 * N \/
            248 < LENGTH(REJ_NIBBLES_ETA4(SUB_LIST(0,16*N) inlist):int16 list)` in
  let hyps' = list_mk_conj (conjuncts hyps @ [pN]) in
  let sv = `s:x86state` in
  let post = add_rej_eta_result rej_eta_result (mk_abs(sv,
    `read RIP s = word (pc + LENGTH (BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
     (?e2. read events s = APPEND e2 (e:(uarch_event)list) /\
           e2 = APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 (inlist:byte list)) N)
                       (ENUMERATEL (N - 1)
                          (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 inlist))) /\
           memaccess_inbounds e2 [(buf:int64),272; (table:int64),2048]
                                 [(res:int64),1024])`)) in
  let ens' = list_mk_comb(comb, [step; pre; post; frame]) in
  list_mk_forall(fst(strip_forall(concl ETA4_LOOP_SAFE)), mk_imp(hyps', ens'));;

let LOOPP_ETA4 = REWRITE_RULE[SOME_FLAGS] ETA4_LOOP_SAFE;;
let loop_post_tm_eta4 = el 2 (snd(strip_comb(snd(dest_imp(snd(strip_forall(concl ETA4_LOOP_SAFE)))))));;
let EXIT_INST_ETA4 = SPECL
  [`res:int64`;`buf:int64`;`table:int64`;`inlist:byte list`;`pc:num`;`N:num`;
   `stackpointer:int64`;
   `APPEND (ENUMERATEL (N-1) (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 inlist)))
           (e:(uarch_event)list)`]
  EXIT_BLOCK_SAFE_ETA4;;
let q_inter_eta4 = el 1 (snd(strip_comb(snd(dest_imp(concl EXIT_INST_ETA4)))));;
let exit_post_tm_eta4 = el 2 (snd(strip_comb(snd(dest_imp(concl EXIT_INST_ETA4)))));;

let CORE_SAFE_FREEN_ETA4 = prove
 (core_safe_freeN_tm_eta4,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[SOME_FLAGS] THEN
  DISCH_THEN(MAP_EVERY ASSUME_TAC o CONJUNCTS) THEN
  MATCH_MP_TAC ENSURES_TRANS_SIMPLE THEN
  EXISTS_TAC q_inter_eta4 THEN
  CONJ_TAC THENL [MAYCHANGE_IDEMPOT_TAC; ALL_TAC] THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
    EXISTS_TAC loop_post_tm_eta4 THEN
    CONJ_TAC THENL
     [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN ASM_REWRITE_TAC[];
      MATCH_MP_TAC LOOPP_ETA4 THEN ASM_REWRITE_TAC[]];
    SUBGOAL_THEN `16 * (N - 1) <= 256` ASSUME_TAC THENL
     [FIRST_ASSUM(MP_TAC o SPEC `N-1` o check(is_forall o concl)) THEN
      ANTS_TAC THENL
       [UNDISCH_TAC `~(N=0)` THEN ARITH_TAC;
        DISCH_THEN(ACCEPT_TAC o CONJUNCT1)];
      ALL_TAC] THEN
    MP_TAC EXIT_INST_ETA4 THEN ANTS_TAC THENL
     [RULE_ASSUM_TAC(REWRITE_RULE[NONOVERLAPPING_CLAUSES;
                                 LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC]) THEN
      ASM_REWRITE_TAC[];
      DISCH_THEN(fun exitth ->
        MATCH_MP_TAC ENSURES_POSTCONDITION_THM THEN
        EXISTS_TAC exit_post_tm_eta4 THEN
        CONJ_TAC THENL
         [GEN_TAC THEN BETA_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN STRIP_TAC THEN
          FIRST_X_ASSUM(SUBST_ALL_TAC o
            check (fun th -> is_eq(concl th) && is_var(lhs(concl th)))) THEN
          CONJ_TAC THENL
           [ASM_REWRITE_TAC[];
            EXISTS_TAC
              `APPEND (f_ev_exit_eta4 res buf table pc (REJ_MASK_ETA4 inlist) N)
                      (ENUMERATEL (N-1)
                         (f_ev_loop_eta4 res buf table pc (REJ_MASK_ETA4 inlist)))` THEN
            REPEAT CONJ_TAC THENL
             [ASM_REWRITE_TAC[APPEND_ASSOC];
              REFL_TAC;
              REWRITE_TAC[MEMACCESS_INBOUNDS_APPEND] THEN CONJ_TAC THENL
               [FIRST_ASSUM ACCEPT_TAC;
                MATCH_MP_TAC MEMACCESS_ENUM_LOOP_ETA4 THEN ASM_REWRITE_TAC[]]]];
          ACCEPT_TAC exitth])]]);;


(* --- CORE_SAFE / NOIBT_SUBROUTINE_SAFE / SUBROUTINE_SAFE --- *)
let f_ev_core_eta4 =
  `\(res:int64) (buf:int64) (table:int64) (pc:num) (mask:(bool)list).
      APPEND (f_ev_exit_eta4 res buf table pc mask (N_OF_MASK_ETA4 mask))
             (ENUMERATEL (N_OF_MASK_ETA4 mask - 1)
                         (f_ev_loop_eta4 res buf table pc mask))
        :(uarch_event)list`;;

let core_safe_eta4_tm =
 `?f_events:int64->int64->int64->num->(bool)list->(uarch_event)list.
   !res buf table (inlist:byte list) e pc.
    LENGTH inlist = 272 /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta4_tmc) (res,1024) /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta4_tmc) (buf,272) /\
    nonoverlapping (word pc,LENGTH mldsa_rej_uniform_eta4_tmc) (table,2048) /\
    nonoverlapping (res,1024) (buf,272) /\
    nonoverlapping (res,1024) (table,2048)
    ==> ensures x86
        (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
             read RIP s = word pc /\
             C_ARGUMENTS [res; buf; table] s /\
             read (memory :> bytes (buf,272)) s = num_of_wordlist inlist /\
             read (memory :> bytes (table,2048)) s =
             num_of_wordlist mldsa_rej_uniform_table /\
             read events s = e)
        (\s. read RIP s =
             word (pc + LENGTH (BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
             (?e2. read events s = APPEND e2 e /\
                   e2 = f_events res buf table pc (REJ_MASK_ETA4 inlist) /\
                   memaccess_inbounds e2 [buf,272; table,2048] [res,1024]))
        (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
         MAYCHANGE
         [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
          ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
         MAYCHANGE SOME_FLAGS ,,
         MAYCHANGE [events] ,,
         MAYCHANGE [memory :> bytes (res,1024)])`;;

let MLDSA_REJ_UNIFORM_ETA4_CORE_CORRECT_SAFE = prove
 (add_rej_eta_core_result rej_eta_result core_safe_eta4_tm,
  EXISTS_TAC f_ev_core_eta4 THEN
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  GHOST_INTRO_TAC `stackpointer:int64` `read RSP` THEN
  CONV_TAC(TOP_DEPTH_CONV BETA_CONV) THEN
  MATCH_MP_TAC CORE_SAFE_FREEN_ETA4 THEN
  ASM_REWRITE_TAC[] THEN
  MP_TAC(SPEC `REJ_MASK_ETA4 (inlist:byte list)` N_OF_MASK_ETA4_MINIMAL) THEN
  REWRITE_TAC[GSYM NIBLEN_EQ_NUMACC_ETA4] THEN
  ABBREV_TAC `NN = N_OF_MASK_ETA4 (REJ_MASK_ETA4 (inlist:byte list))` THEN
  DISCH_THEN(CONJUNCTS_THEN2 ASSUME_TAC ASSUME_TAC) THEN
  REPEAT CONJ_TAC THENL
   [DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o check(is_disj o concl)) THEN
    ASM_REWRITE_TAC[MULT_CLAUSES; ADD_CLAUSES; SUB_LIST_CLAUSES;
                    REJ_NIBBLES_ETA4_EMPTY; LENGTH] THEN
    ARITH_TAC;
    DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o check(is_disj o concl)) THEN
    ASM_REWRITE_TAC[ARITH_RULE `16 * 1 = 16`; ARITH_RULE `~(256 < 16)`] THEN
    MP_TAC(ISPECL [`inlist:byte list`; `16`]
                  LENGTH_REJ_SAMPLE_ETA4_BYTES_SUB_LIST_BOUND) THEN
    ASM_REWRITE_TAC[LENGTH_REJ_SAMPLE_ETA4_BYTES] THEN ARITH_TAC;
    X_GEN_TAC `m:num` THEN DISCH_TAC THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `m:num` o check(is_forall o concl)) THEN
    ASM_REWRITE_TAC[] THEN REWRITE_TAC[NOT_LT] THEN DISCH_THEN ACCEPT_TAC;
    FIRST_ASSUM ACCEPT_TAC]);;

let MLDSA_REJ_UNIFORM_ETA4_CORE_SAFE = prove
 (core_safe_eta4_tm, REJ_ETA_CORE_SAFE_TAC MLDSA_REJ_UNIFORM_ETA4_CORE_CORRECT_SAFE);;

let MLDSA_REJ_UNIFORM_ETA4_CORE_SAFE_CONCRETE =
  CONV_RULE(REWRITE_CONV[LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC;
                         fst MLDSA_REJ_UNIFORM_ETA4_EXEC])
    MLDSA_REJ_UNIFORM_ETA4_CORE_SAFE;;

let MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_SAFE =
  let saved_tic = !type_invention_error in
  type_invention_error := false;
  let th = prove
   (`?f_events:int64->int64->int64->num->(bool)list->int64->int64->
              (uarch_event)list.
     !res buf table (inlist:byte list) e pc stackpointer returnaddress.
        LENGTH inlist = 272 /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
        nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
        nonoverlapping (res, 1024) (buf, 272) /\
        nonoverlapping (res, 1024) (table, 2048) /\
        nonoverlapping (stackpointer, 8) (res, 1024) /\
        nonoverlapping (stackpointer, 8) (buf, 272) /\
        nonoverlapping (stackpointer, 8) (table, 2048) /\
        nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta4_tmc)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta4_tmc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [res; buf; table] s /\
                  read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                  read(memory :> bytes(table,2048)) s =
                    num_of_wordlist mldsa_rej_uniform_table /\
                  read events s = e)
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (?e2. read events s = APPEND e2 e /\
                        e2 = f_events res buf table pc (REJ_MASK_ETA4 inlist)
                                      stackpointer returnaddress /\
                        memaccess_inbounds e2
                          [buf,272; table,2048; stackpointer,8]
                          [res,1024]))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(res,1024)])`,
    REWRITE_TAC[LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC] THEN
    X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_rej_uniform_eta4_tmc
      MLDSA_REJ_UNIFORM_ETA4_CORE_SAFE_CONCRETE THEN
    ABBREV_TAC `mask:(bool)list = REJ_MASK_ETA4 (inlist:byte list)` THEN
    DISCHARGE_SAFETY_PROPERTY_TAC) in
  type_invention_error := saved_tic;
  th;;

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_SAFE =
  ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_SAFE;;

(* Memory safety follows by forgetting the event-trace equality. *)
type_invention_error := false;;

let MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_MEMSAFE = prove
 (`!res buf table (inlist:byte list) e pc stackpointer returnaddress.
      LENGTH inlist = 272 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 272) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 272) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta4_tmc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta4_tmc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table /\
                read events s = e)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (exists e2.
                   read events s = APPEND e2 e /\
                   memaccess_inbounds e2
                     [buf,272; table,2048; stackpointer,8]
                     [res,1024]))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REJ_ETA_MEMSAFE_TAC MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_SAFE);;

type_invention_error := true;;

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_MEMSAFE = prove
 (`!res buf table (inlist:byte list) e pc stackpointer returnaddress.
      LENGTH inlist = 272 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (buf, 272) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 272) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 272) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta4_mc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table /\
                read events s = e)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (exists e2.
                   read events s = APPEND e2 e /\
                   memaccess_inbounds e2
                     [buf,272; table,2048; stackpointer,8]
                     [res,1024]))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_MEMSAFE));;

let MLDSA_REJ_UNIFORM_ETA4_CORRECT = prove
 (correct_eta4_tm, REJ_ETA_CORE_CORRECT_TAC MLDSA_REJ_UNIFORM_ETA4_CORE_CORRECT_SAFE);;

let correct_bound = prove
 (`!res buf table (inlist:byte list) pc.
    LENGTH inlist = 272 /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
    nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
    nonoverlapping (res, 1024) (buf, 272) /\
    nonoverlapping (res, 1024) (table, 2048)
    ==> ensures x86
         (\s. bytes_loaded s (word pc) (BUTLAST mldsa_rej_uniform_eta4_tmc) /\
              read RIP s = word pc /\
              C_ARGUMENTS [res; buf; table] s /\
              read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
              read(memory :> bytes(table,2048)) s =
                num_of_wordlist mldsa_rej_uniform_table)
         (\s. read RIP s = word(pc + LENGTH (BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
              (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES inlist) in
               let outlen = LENGTH outlist in
               outlen <= 256 /\
               C_RETURN s = word outlen /\
               read(memory :> bytes(res,4 * outlen)) s =
                 num_of_wordlist outlist /\
               (!i. i < outlen
                    ==> ival(EL i outlist:int32) < &5 /\
                        -- &5 < ival(EL i outlist:int32))))
         (MAYCHANGE [RIP; RAX; RCX; R8; R9; R10; R11] ,,
          MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5; ZMM6; ZMM7;
                     ZMM8; ZMM9; ZMM10; ZMM11; ZMM12; ZMM13; ZMM14; ZMM15] ,,
          MAYCHANGE SOME_FLAGS ,, MAYCHANGE [events] ,,
          MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN STRIP_TAC THEN
  MATCH_MP_TAC ENSURES_STRENGTHEN_POST_X86 THEN
  EXISTS_TAC
   `\s:x86state.
      read RIP s = word(pc + LENGTH(BUTLAST mldsa_rej_uniform_eta4_tmc)) /\
      (let outlist = SUB_LIST(0,256) (REJ_SAMPLE_ETA4_BYTES (inlist:byte list)) in
       let outlen = LENGTH outlist in
       C_RETURN s = word outlen /\
       read(memory :> bytes(res:int64,4 * outlen)) s =
         num_of_wordlist outlist)` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC MLDSA_REJ_UNIFORM_ETA4_CORRECT THEN ASM_REWRITE_TAC[];
    BETA_TAC THEN GEN_TAC THEN CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    STRIP_TAC THEN ASM_REWRITE_TAC[] THEN
    CONJ_TAC THENL
     [MATCH_ACCEPT_TAC LENGTH_SUB_LIST_REJ_SAMPLE_ETA4_BYTES; ALL_TAC] THEN
    MATCH_ACCEPT_TAC REJ_SAMPLE_ETA4_BYTES_EL_BOUND]);;

let correct_bound_concrete =
  CONV_RULE(REWRITE_CONV[LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC;
                         fst MLDSA_REJ_UNIFORM_ETA4_EXEC])
    correct_bound;;

type_invention_error := false;;

let MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_CORRECT = prove
 (`!res buf table (inlist:byte list) pc stackpointer returnaddress.
      LENGTH inlist = 272 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (buf, 272) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_tmc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 272) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 272) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta4_tmc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta4_tmc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (let outlist = SUB_LIST(0,256)
                    (REJ_SAMPLE_ETA4_BYTES inlist) in
                 let outlen = LENGTH outlist in
                 outlen <= 256 /\
                 C_RETURN s = word outlen /\
                 read(memory :> bytes(res,4 * outlen)) s =
                   num_of_wordlist outlist /\
                 (!i. i < outlen
                      ==> ival(EL i outlist:int32) < &5 /\
                          -- &5 < ival(EL i outlist:int32))))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REWRITE_TAC[LENGTH_MLDSA_REJ_UNIFORM_ETA4_TMC] THEN
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_rej_uniform_eta4_tmc
    correct_bound_concrete);;

type_invention_error := true;;

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_CORRECT_BYTES =
  ADD_IBT_RULE MLDSA_REJ_UNIFORM_ETA4_NOIBT_SUBROUTINE_CORRECT;;

let MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_CORRECT = prove
 (`!res buf table (inlist:(4 word) list) pc stackpointer returnaddress.
      LENGTH inlist = 544 /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (res, 1024) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (buf, 272) /\
      nonoverlapping (word pc, LENGTH mldsa_rej_uniform_eta4_mc) (table, 2048) /\
      nonoverlapping (res, 1024) (buf, 272) /\
      nonoverlapping (res, 1024) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (res, 1024) /\
      nonoverlapping (stackpointer, 8) (buf, 272) /\
      nonoverlapping (stackpointer, 8) (table, 2048) /\
      nonoverlapping (stackpointer, 8) (word pc, LENGTH mldsa_rej_uniform_eta4_mc)
      ==> ensures x86
           (\s. bytes_loaded s (word pc) mldsa_rej_uniform_eta4_mc /\
                read RIP s = word pc /\
                read RSP s = stackpointer /\
                read (memory :> bytes64 stackpointer) s = returnaddress /\
                C_ARGUMENTS [res; buf; table] s /\
                read(memory :> bytes(buf, 272)) s = num_of_wordlist inlist /\
                read(memory :> bytes(table,2048)) s =
                  num_of_wordlist mldsa_rej_uniform_table)
           (\s. read RIP s = returnaddress /\
                read RSP s = word_add stackpointer (word 8) /\
                (let outlist = SUB_LIST(0,256)
                    (REJ_SAMPLE_ETA4 inlist) in
                 let outlen = LENGTH outlist in
                 outlen <= 256 /\
                 C_RETURN s = word outlen /\
                 read(memory :> bytes(res,4 * outlen)) s =
                   num_of_wordlist outlist /\
                 (!i. i < outlen
                      ==> ival(EL i outlist:int32) < &5 /\
                          -- &5 < ival(EL i outlist:int32))))
           (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(res,1024)])`,
  REPEAT GEN_TAC THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN
  MP_TAC(ISPEC `inlist:(4 word) list` BYTES_TO_NIBBLES_SURJ) THEN
  ANTS_TAC THENL
   [REWRITE_TAC[EVEN_EXISTS] THEN EXISTS_TAC `272` THEN
    ASM_REWRITE_TAC[] THEN CONV_TAC NUM_REDUCE_CONV; ALL_TAC] THEN
  DISCH_THEN(X_CHOOSE_THEN `bs:byte list` STRIP_ASSUME_TAC) THEN
  UNDISCH_THEN `BYTES_TO_NIBBLES (bs:byte list) = inlist`
    (SUBST_ALL_TAC o SYM) THEN
  RULE_ASSUM_TAC(REWRITE_RULE[LENGTH_BYTES_TO_NIBBLES]) THEN
  SUBGOAL_THEN `LENGTH (bs:byte list) = 272` ASSUME_TAC THENL
   [UNDISCH_TAC `2 * LENGTH (bs:byte list) = 544` THEN ARITH_TAC; ALL_TAC] THEN
  REWRITE_TAC[NUM_OF_BYTES_TO_NIBBLES; GSYM REJ_SAMPLE_ETA4_BYTES_EQ] THEN
  MP_TAC(SPECL
   [`res:int64`; `buf:int64`; `table:int64`; `bs:byte list`; `pc:num`;
    `stackpointer:int64`; `returnaddress:int64`]
   MLDSA_REJ_UNIFORM_ETA4_SUBROUTINE_CORRECT_BYTES) THEN
  ASM_REWRITE_TAC[] THEN
  CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
  REWRITE_TAC[]);;
