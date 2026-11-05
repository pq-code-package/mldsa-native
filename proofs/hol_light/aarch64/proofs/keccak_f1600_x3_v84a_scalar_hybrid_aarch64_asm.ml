(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* 3-way batch Keccak-f1600 scalar/vector hybrid code (single pass).         *)
(* Derived from the x4 v84a proof:                                           *)
(* keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm.ml                     *)
(* ========================================================================= *)

(* Load base theories for AArch64 from s2n-bignum *)
needs "s2n_bignum/arm/proofs/base.ml";;

needs "mldsa_native/aarch64/proofs/keccak_utils.ml";;

(**** print_literal_from_elf "aarch64/mldsa/keccak_f1600_x3_v84a_scalar_hybrid_aarch64_asm.o";;
 ****)

let keccak_f1600_x3_v84a_scalar_mc = define_assert_from_elf
  "keccak_f1600_x3_v84a_scalar_mc" "aarch64/mldsa/keccak_f1600_x3_v84a_scalar_hybrid_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0xd10383ff;       (* arm_SUB SP SP (rvalue (word 224)) *)
  0xa90353f3;       (* arm_STP X19 X20 SP (Immediate_Offset (iword (&48))) *)
  0xa9045bf5;       (* arm_STP X21 X22 SP (Immediate_Offset (iword (&64))) *)
  0xa90563f7;       (* arm_STP X23 X24 SP (Immediate_Offset (iword (&80))) *)
  0xa9066bf9;       (* arm_STP X25 X26 SP (Immediate_Offset (iword (&96))) *)
  0xa90773fb;       (* arm_STP X27 X28 SP (Immediate_Offset (iword (&112))) *)
  0xa9087bfd;       (* arm_STP X29 X30 SP (Immediate_Offset (iword (&128))) *)
  0x6d0927e8;       (* arm_STP D8 D9 SP (Immediate_Offset (iword (&144))) *)
  0x6d0a2fea;       (* arm_STP D10 D11 SP (Immediate_Offset (iword (&160))) *)
  0x6d0b37ec;       (* arm_STP D12 D13 SP (Immediate_Offset (iword (&176))) *)
  0x6d0c3fee;       (* arm_STP D14 D15 SP (Immediate_Offset (iword (&192))) *)
  0xaa0103fd;       (* arm_MOV X29 X1 *)
  0xf90007fd;       (* arm_STR X29 SP (Immediate_Offset (word 8)) *)
  0xf9000bfd;       (* arm_STR X29 SP (Immediate_Offset (word 16)) *)
  0xf90003e0;       (* arm_STR X0 SP (Immediate_Offset (word 0)) *)
  0x91032004;       (* arm_ADD X4 X0 (rvalue (word 200)) *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b20;       (* arm_TRN1 Q0 Q25 Q27 64 128 *)
  0x4edb6b21;       (* arm_TRN2 Q1 Q25 Q27 64 128 *)
  0x4edc2b42;       (* arm_TRN1 Q2 Q26 Q28 64 128 *)
  0x4edc6b43;       (* arm_TRN2 Q3 Q26 Q28 64 128 *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b24;       (* arm_TRN1 Q4 Q25 Q27 64 128 *)
  0x4edb6b25;       (* arm_TRN2 Q5 Q25 Q27 64 128 *)
  0x4edc2b46;       (* arm_TRN1 Q6 Q26 Q28 64 128 *)
  0x4edc6b47;       (* arm_TRN2 Q7 Q26 Q28 64 128 *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b28;       (* arm_TRN1 Q8 Q25 Q27 64 128 *)
  0x4edb6b29;       (* arm_TRN2 Q9 Q25 Q27 64 128 *)
  0x4edc2b4a;       (* arm_TRN1 Q10 Q26 Q28 64 128 *)
  0x4edc6b4b;       (* arm_TRN2 Q11 Q26 Q28 64 128 *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b2c;       (* arm_TRN1 Q12 Q25 Q27 64 128 *)
  0x4edb6b2d;       (* arm_TRN2 Q13 Q25 Q27 64 128 *)
  0x4edc2b4e;       (* arm_TRN1 Q14 Q26 Q28 64 128 *)
  0x4edc6b4f;       (* arm_TRN2 Q15 Q26 Q28 64 128 *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b30;       (* arm_TRN1 Q16 Q25 Q27 64 128 *)
  0x4edb6b31;       (* arm_TRN2 Q17 Q25 Q27 64 128 *)
  0x4edc2b52;       (* arm_TRN1 Q18 Q26 Q28 64 128 *)
  0x4edc6b53;       (* arm_TRN2 Q19 Q26 Q28 64 128 *)
  0xacc16819;       (* arm_LDP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4cdfac9b;       (* arm_LDP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4edb2b34;       (* arm_TRN1 Q20 Q25 Q27 64 128 *)
  0x4edb6b35;       (* arm_TRN2 Q21 Q25 Q27 64 128 *)
  0x4edc2b56;       (* arm_TRN1 Q22 Q26 Q28 64 128 *)
  0x4edc6b57;       (* arm_TRN2 Q23 Q26 Q28 64 128 *)
  0xfd400019;       (* arm_LDR D25 X0 (Immediate_Offset (word 0)) *)
  0xfd40009b;       (* arm_LDR D27 X4 (Immediate_Offset (word 0)) *)
  0x4edb2b38;       (* arm_TRN1 Q24 Q25 Q27 64 128 *)
  0xd1030000;       (* arm_SUB X0 X0 (rvalue (word 192)) *)
  0x91064000;       (* arm_ADD X0 X0 (rvalue (word 400)) *)
  0xa9401801;       (* arm_LDP X1 X6 X0 (Immediate_Offset (iword (&0))) *)
  0xa941400b;       (* arm_LDP X11 X16 X0 (Immediate_Offset (iword (&16))) *)
  0xa9420815;       (* arm_LDP X21 X2 X0 (Immediate_Offset (iword (&32))) *)
  0xa9433007;       (* arm_LDP X7 X12 X0 (Immediate_Offset (iword (&48))) *)
  0xa9445811;       (* arm_LDP X17 X22 X0 (Immediate_Offset (iword (&64))) *)
  0xa9452003;       (* arm_LDP X3 X8 X0 (Immediate_Offset (iword (&80))) *)
  0xa946700d;       (* arm_LDP X13 X28 X0 (Immediate_Offset (iword (&96))) *)
  0xa9471017;       (* arm_LDP X23 X4 X0 (Immediate_Offset (iword (&112))) *)
  0xa9483809;       (* arm_LDP X9 X14 X0 (Immediate_Offset (iword (&128))) *)
  0xa9496013;       (* arm_LDP X19 X24 X0 (Immediate_Offset (iword (&144))) *)
  0xa94a2805;       (* arm_LDP X5 X10 X0 (Immediate_Offset (iword (&160))) *)
  0xa94b500f;       (* arm_LDP X15 X20 X0 (Immediate_Offset (iword (&176))) *)
  0xf9406019;       (* arm_LDR X25 X0 (Immediate_Offset (word 192)) *)
  0xd1064000;       (* arm_SUB X0 X0 (rvalue (word 400)) *)
  0xca19031e;       (* arm_EOR X30 X24 X25 *)
  0xca0a013b;       (* arm_EOR X27 X9 X10 *)
  0xce05281e;       (* arm_EOR3 Q30 Q0 Q5 Q10 *)
  0xce0f53de;       (* arm_EOR3 Q30 Q30 Q15 Q20 *)
  0xca1503c0;       (* arm_EOR X0 X30 X21 *)
  0xca06037a;       (* arm_EOR X26 X27 X6 *)
  0xce062c3d;       (* arm_EOR3 Q29 Q1 Q6 Q11 *)
  0xca07035b;       (* arm_EOR X27 X26 X7 *)
  0xce1057bd;       (* arm_EOR3 Q29 Q29 Q16 Q21 *)
  0xca16001d;       (* arm_EOR X29 X0 X22 *)
  0xca1703ba;       (* arm_EOR X26 X29 X23 *)
  0xce07305c;       (* arm_EOR3 Q28 Q2 Q7 Q12 *)
  0xca05009d;       (* arm_EOR X29 X4 X5 *)
  0xce115b9c;       (* arm_EOR3 Q28 Q28 Q17 Q22 *)
  0xca0103be;       (* arm_EOR X30 X29 X1 *)
  0xca080360;       (* arm_EOR X0 X27 X8 *)
  0xce08347b;       (* arm_EOR3 Q27 Q3 Q8 Q13 *)
  0xca0203dd;       (* arm_EOR X29 X30 X2 *)
  0xce125f7b;       (* arm_EOR3 Q27 Q27 Q18 Q23 *)
  0xca14027e;       (* arm_EOR X30 X19 X20 *)
  0xca1003de;       (* arm_EOR X30 X30 X16 *)
  0xce09389a;       (* arm_EOR3 Q26 Q4 Q9 Q14 *)
  0xcac0ff5b;       (* arm_EOR X27 X26 (Shiftedreg X0 ROR 63) *)
  0xce13635a;       (* arm_EOR3 Q26 Q26 Q19 Q24 *)
  0xca1b0084;       (* arm_EOR X4 X4 X27 *)
  0xca1103de;       (* arm_EOR X30 X30 X17 *)
  0xce7c8fd9;       (* arm_RAX1 Q25 Q30 Q28 *)
  0xca1c03de;       (* arm_EOR X30 X30 X28 *)
  0xca0303bd;       (* arm_EOR X29 X29 X3 *)
  0xce7a8f9c;       (* arm_RAX1 Q28 Q28 Q26 *)
  0xcadefc00;       (* arm_EOR X0 X0 (Shiftedreg X30 ROR 63) *)
  0xce7d8f5a;       (* arm_RAX1 Q26 Q26 Q29 *)
  0xcaddffde;       (* arm_EOR X30 X30 (Shiftedreg X29 ROR 63) *)
  0xca1e02d6;       (* arm_EOR X22 X22 X30 *)
  0xce7b8fbd;       (* arm_RAX1 Q29 Q29 Q27 *)
  0xca1e02f7;       (* arm_EOR X23 X23 X30 *)
  0xce7e8f7b;       (* arm_RAX1 Q27 Q27 Q30 *)
  0xf9006bf7;       (* arm_STR X23 SP (Immediate_Offset (word 208)) *)
  0xca0f01d7;       (* arm_EOR X23 X14 X15 *)
  0x6e3a1c1e;       (* arm_EOR_VEC Q30 Q0 Q26 128 *)
  0xca0001ce;       (* arm_EOR X14 X14 X0 *)
  0xce9d0840;       (* arm_XAR Q0 Q2 Q29 (word 2) *)
  0xca0b02f7;       (* arm_EOR X23 X23 X11 *)
  0xca0001ef;       (* arm_EOR X15 X15 X0 *)
  0xce9d5582;       (* arm_XAR Q2 Q12 Q29 (word 21) *)
  0xca1b0021;       (* arm_EOR X1 X1 X27 *)
  0xce9c9dac;       (* arm_XAR Q12 Q13 Q28 (word 39) *)
  0xca0c02f7;       (* arm_EOR X23 X23 X12 *)
  0xca0d02f7;       (* arm_EOR X23 X23 X13 *)
  0xce9be26d;       (* arm_XAR Q13 Q19 Q27 (word 56) *)
  0xca00016b;       (* arm_EOR X11 X11 X0 *)
  0xcad7ffbd;       (* arm_EOR X29 X29 (Shiftedreg X23 ROR 63) *)
  0xce9c22f3;       (* arm_XAR Q19 Q23 Q28 (word 8) *)
  0xcadafef7;       (* arm_EOR X23 X23 (Shiftedreg X26 ROR 63) *)
  0xce9a5df7;       (* arm_XAR Q23 Q15 Q26 (word 23) *)
  0xca0001ba;       (* arm_EOR X26 X13 X0 *)
  0xca17038d;       (* arm_EOR X13 X28 X23 *)
  0xce99fc2f;       (* arm_XAR Q15 Q1 Q25 (word 63) *)
  0xca1e031c;       (* arm_EOR X28 X24 X30 *)
  0xce9c2501;       (* arm_XAR Q1 Q8 Q28 (word 9) *)
  0xca170218;       (* arm_EOR X24 X16 X23 *)
  0xca1e02b0;       (* arm_EOR X16 X21 X30 *)
  0xce994e08;       (* arm_XAR Q8 Q16 Q25 (word 19) *)
  0xca1e0335;       (* arm_EOR X21 X25 X30 *)
  0xce9de8f0;       (* arm_XAR Q16 Q7 Q29 (word 58) *)
  0xca17027e;       (* arm_EOR X30 X19 X23 *)
  0xca170293;       (* arm_EOR X19 X20 X23 *)
  0xce9af547;       (* arm_XAR Q7 Q10 Q26 (word 61) *)
  0xca170234;       (* arm_EOR X20 X17 X23 *)
  0xce9c906a;       (* arm_XAR Q10 Q3 Q28 (word 36) *)
  0xca000191;       (* arm_EOR X17 X12 X0 *)
  0xca1b0040;       (* arm_EOR X0 X2 X27 *)
  0xce9cae43;       (* arm_XAR Q3 Q18 Q28 (word 43) *)
  0xca1d00c2;       (* arm_EOR X2 X6 X29 *)
  0xce9dc632;       (* arm_XAR Q18 Q17 Q29 (word 49) *)
  0xca1d0106;       (* arm_EOR X6 X8 X29 *)
  0x8aedbf88;       (* arm_BIC X8 X28 (Shiftedreg X13 ROR 47) *)
  0xce99d971;       (* arm_XAR Q17 Q11 Q25 (word 54) *)
  0xca1b006c;       (* arm_EOR X12 X3 X27 *)
  0x8af14da3;       (* arm_BIC X3 X13 (Shiftedreg X17 ROR 19) *)
  0xce9bb12b;       (* arm_XAR Q11 Q9 Q27 (word 44) *)
  0xca1b00a5;       (* arm_EOR X5 X5 X27 *)
  0xce9d0ec9;       (* arm_XAR Q9 Q22 Q29 (word 3) *)
  0xf9406bfb;       (* arm_LDR X27 SP (Immediate_Offset (word 208)) *)
  0x8ae21639;       (* arm_BIC X25 X17 (Shiftedreg X2 ROR 5) *)
  0xce9b65d6;       (* arm_XAR Q22 Q14 Q27 (word 25) *)
  0xca1d0129;       (* arm_EOR X9 X9 X29 *)
  0xce9aba8e;       (* arm_XAR Q14 Q20 Q26 (word 46) *)
  0xcac5d337;       (* arm_EOR X23 X25 (Shiftedreg X5 ROR 52) *)
  0xcac26063;       (* arm_EOR X3 X3 (Shiftedreg X2 ROR 24) *)
  0xce9b9494;       (* arm_XAR Q20 Q4 Q27 (word 37) *)
  0xcad10908;       (* arm_EOR X8 X8 (Shiftedreg X17 ROR 2) *)
  0xce9bcb04;       (* arm_XAR Q4 Q24 Q27 (word 50) *)
  0xca1d0151;       (* arm_EOR X17 X10 X29 *)
  0x8af6bd99;       (* arm_BIC X25 X12 (Shiftedreg X22 ROR 47) *)
  0xce99fab8;       (* arm_XAR Q24 Q21 Q25 (word 62) *)
  0xca1d00fd;       (* arm_EOR X29 X7 X29 *)
  0xce9a70b5;       (* arm_XAR Q21 Q5 Q26 (word 28) *)
  0x8afb088a;       (* arm_BIC X10 X4 (Shiftedreg X27 ROR 2) *)
  0x8afc28a7;       (* arm_BIC X7 X5 (Shiftedreg X28 ROR 10) *)
  0xce9950db;       (* arm_XAR Q27 Q6 Q25 (word 20) *)
  0xcad4c94a;       (* arm_EOR X10 X10 (Shiftedreg X20 ROR 50) *)
  0xcacde4ed;       (* arm_EOR X13 X7 (Shiftedreg X13 ROR 57) *)
  0xce272d45;       (* arm_BCAX Q5 Q10 Q7 Q11 *)
  0x8ae5bc47;       (* arm_BIC X7 X2 (Shiftedreg X5 ROR 47) *)
  0xce281d66;       (* arm_BCAX Q6 Q11 Q8 Q7 *)
  0xcad89f22;       (* arm_EOR X2 X25 (Shiftedreg X24 ROR 39) *)
  0x8aebe699;       (* arm_BIC X25 X20 (Shiftedreg X11 ROR 57) *)
  0xce2920e7;       (* arm_BCAX Q7 Q7 Q9 Q8 *)
  0x8ae46625;       (* arm_BIC X5 X17 (Shiftedreg X4 ROR 25) *)
  0xce2a2508;       (* arm_BCAX Q8 Q8 Q10 Q9 *)
  0xcad1d739;       (* arm_EOR X25 X25 (Shiftedreg X17 ROR 53) *)
  0x8af1f171;       (* arm_BIC X17 X11 (Shiftedreg X17 ROR 60) *)
  0xce2b2929;       (* arm_BCAX Q9 Q9 Q11 Q10 *)
  0xcadce4fc;       (* arm_EOR X28 X7 (Shiftedreg X28 ROR 57) *)
  0xce2c41ea;       (* arm_BCAX Q10 Q15 Q12 Q16 *)
  0x8aeca927;       (* arm_BIC X7 X9 (Shiftedreg X12 ROR 42) *)
  0xcad664e7;       (* arm_EOR X7 X7 (Shiftedreg X22 ROR 25) *)
  0xce2d320b;       (* arm_BCAX Q11 Q16 Q13 Q12 *)
  0x8af8e2d6;       (* arm_BIC X22 X22 (Shiftedreg X24 ROR 56) *)
  0xce2e358c;       (* arm_BCAX Q12 Q12 Q14 Q13 *)
  0x8aef7f18;       (* arm_BIC X24 X24 (Shiftedreg X15 ROR 31) *)
  0xcacf5ed6;       (* arm_EOR X22 X22 (Shiftedreg X15 ROR 23) *)
  0xce2f39ad;       (* arm_BCAX Q13 Q13 Q15 Q14 *)
  0x8af4c374;       (* arm_BIC X20 X27 (Shiftedreg X20 ROR 48) *)
  0xce303dce;       (* arm_BCAX Q14 Q14 Q16 Q15 *)
  0x8ae941ef;       (* arm_BIC X15 X15 (Shiftedreg X9 ROR 16) *)
  0xcacce9ec;       (* arm_EOR X12 X15 (Shiftedreg X12 ROR 58) *)
  0xce31568f;       (* arm_BCAX Q15 Q20 Q17 Q21 *)
  0xcadb6caf;       (* arm_EOR X15 X5 (Shiftedreg X27 ROR 27) *)
  0xcacba685;       (* arm_EOR X5 X20 (Shiftedreg X11 ROR 41) *)
  0xce3246b0;       (* arm_BCAX Q16 Q21 Q18 Q17 *)
  0xf94007eb;       (* arm_LDR X11 SP (Immediate_Offset (word 8)) *)
  0xce334a31;       (* arm_BCAX Q17 Q17 Q19 Q18 *)
  0xcac45634;       (* arm_EOR X20 X17 (Shiftedreg X4 ROR 21) *)
  0xcac9bf11;       (* arm_EOR X17 X24 (Shiftedreg X9 ROR 47) *)
  0xce344e52;       (* arm_BCAX Q18 Q18 Q20 Q19 *)
  0xd2800038;       (* arm_MOV X24 (rvalue (word 1)) *)
  0xce355273;       (* arm_BCAX Q19 Q19 Q21 Q20 *)
  0x8af02409;       (* arm_BIC X9 X0 (Shiftedreg X16 ROR 9) *)
  0xf9000ff8;       (* arm_STR X24 SP (Immediate_Offset (word 24)) *)
  0xce360414;       (* arm_BCAX Q20 Q0 Q22 Q1 *)
  0x8ae1b3b8;       (* arm_BIC X24 X29 (Shiftedreg X1 ROR 44) *)
  0xce375835;       (* arm_BCAX Q21 Q1 Q23 Q22 *)
  0x8af5c83b;       (* arm_BIC X27 X1 (Shiftedreg X21 ROR 50) *)
  0x8afdff44;       (* arm_BIC X4 X26 (Shiftedreg X29 ROR 63) *)
  0xce385ed6;       (* arm_BCAX Q22 Q22 Q24 Q23 *)
  0xcac45421;       (* arm_EOR X1 X1 (Shiftedreg X4 ROR 21) *)
  0xce2062f7;       (* arm_BCAX Q23 Q23 Q0 Q24 *)
  0xf940016b;       (* arm_LDR X11 X11 (Immediate_Offset (word 0)) *)
  0x8afee6a4;       (* arm_BIC X4 X21 (Shiftedreg X30 ROR 57) *)
  0xce210318;       (* arm_BCAX Q24 Q24 Q1 Q0 *)
  0xcad57b15;       (* arm_EOR X21 X24 (Shiftedreg X21 ROR 30) *)
  0xcad3b138;       (* arm_EOR X24 X9 (Shiftedreg X19 ROR 44) *)
  0xce226fc0;       (* arm_BCAX Q0 Q30 Q2 Q27 *)
  0x8ae615c9;       (* arm_BIC X9 X14 (Shiftedreg X6 ROR 5) *)
  0xce230b61;       (* arm_BCAX Q1 Q27 Q3 Q2 *)
  0xcac0ad29;       (* arm_EOR X9 X9 (Shiftedreg X0 ROR 43) *)
  0x8ae098c0;       (* arm_BIC X0 X6 (Shiftedreg X0 ROR 38) *)
  0xce240c42;       (* arm_BCAX Q2 Q2 Q4 Q3 *)
  0xca0b0021;       (* arm_EOR X1 X1 X11 *)
  0xce3e1063;       (* arm_BCAX Q3 Q3 Q30 Q4 *)
  0xcada8c8b;       (* arm_EOR X11 X4 (Shiftedreg X26 ROR 35) *)
  0xcad0bc04;       (* arm_EOR X4 X0 (Shiftedreg X16 ROR 47) *)
  0xce3b7884;       (* arm_BCAX Q4 Q4 Q27 Q30 *)
  0x8af38e00;       (* arm_BIC X0 X16 (Shiftedreg X19 ROR 35) *)
  0xcadeaf70;       (* arm_EOR X16 X27 (Shiftedreg X30 ROR 43) *)
  0x8afaabdb;       (* arm_BIC X27 X30 (Shiftedreg X26 ROR 42) *)
  0xf9400bfe;       (* arm_LDR X30 SP (Immediate_Offset (word 16)) *)
  0x4ddfcfdc;       (* arm_LD1R Q28 X30 (Postimmediate_Offset (word 8)) 64 128 *)
  0x8aeea67a;       (* arm_BIC X26 X19 (Shiftedreg X14 ROR 41) *)
  0xf9000bfe;       (* arm_STR X30 SP (Immediate_Offset (word 16)) *)
  0xcace3013;       (* arm_EOR X19 X0 (Shiftedreg X14 ROR 12) *)
  0xcac6bb4e;       (* arm_EOR X14 X26 (Shiftedreg X6 ROR 46) *)
  0x6e3c1c00;       (* arm_EOR_VEC Q0 Q0 Q28 128 *)
  0xcadda766;       (* arm_EOR X6 X27 (Shiftedreg X29 ROR 41) *)
  0xcacbd1e0;       (* arm_EOR X0 X15 (Shiftedreg X11 ROR 52) *)
  0xcacdc000;       (* arm_EOR X0 X0 (Shiftedreg X13 ROR 48) *)
  0xce05281e;       (* arm_EOR3 Q30 Q0 Q5 Q10 *)
  0xce0f53de;       (* arm_EOR3 Q30 Q30 Q15 Q20 *)
  0xcac9e51a;       (* arm_EOR X26 X8 (Shiftedreg X9 ROR 57) *)
  0xcace281b;       (* arm_EOR X27 X0 (Shiftedreg X14 ROR 10) *)
  0xce062c3d;       (* arm_EOR3 Q29 Q1 Q6 Q11 *)
  0xcadcfe1d;       (* arm_EOR X29 X16 (Shiftedreg X28 ROR 63) *)
  0xce1057bd;       (* arm_EOR3 Q29 Q29 Q16 Q21 *)
  0xcac6cf5a;       (* arm_EOR X26 X26 (Shiftedreg X6 ROR 51) *)
  0xcad6cafe;       (* arm_EOR X30 X23 (Shiftedreg X22 ROR 50) *)
  0xce07305c;       (* arm_EOR3 Q28 Q2 Q7 Q12 *)
  0xcaca7f40;       (* arm_EOR X0 X26 (Shiftedreg X10 ROR 31) *)
  0xcad397bd;       (* arm_EOR X29 X29 (Shiftedreg X19 ROR 37) *)
  0xce115b9c;       (* arm_EOR3 Q28 Q28 Q17 Q22 *)
  0xcacc177b;       (* arm_EOR X27 X27 (Shiftedreg X12 ROR 5) *)
  0xce08347b;       (* arm_EOR3 Q27 Q3 Q8 Q13 *)
  0xcad88bde;       (* arm_EOR X30 X30 (Shiftedreg X24 ROR 34) *)
  0xcac76c00;       (* arm_EOR X0 X0 (Shiftedreg X7 ROR 27) *)
  0xce125f7b;       (* arm_EOR3 Q27 Q27 Q18 Q23 *)
  0xcad56bda;       (* arm_EOR X26 X30 (Shiftedreg X21 ROR 26) *)
  0xce09389a;       (* arm_EOR3 Q26 Q4 Q9 Q14 *)
  0xcad93f5a;       (* arm_EOR X26 X26 (Shiftedreg X25 ROR 15) *)
  0x93dbfb7e;       (* arm_ROR X30 X27 62 *)
  0xce13635a;       (* arm_EOR3 Q26 Q26 Q19 Q24 *)
  0xcadae7de;       (* arm_EOR X30 X30 (Shiftedreg X26 ROR 57) *)
  0x93daeb5a;       (* arm_ROR X26 X26 58 *)
  0xce7c8fd9;       (* arm_RAX1 Q25 Q30 Q28 *)
  0xca1003d0;       (* arm_EOR X16 X30 X16 *)
  0xce7a8f9c;       (* arm_RAX1 Q28 Q28 Q26 *)
  0xcadcffdc;       (* arm_EOR X28 X30 (Shiftedreg X28 ROR 63) *)
  0xf9006bfc;       (* arm_STR X28 SP (Immediate_Offset (word 208)) *)
  0xce7d8f5a;       (* arm_RAX1 Q26 Q26 Q29 *)
  0xcad193bd;       (* arm_EOR X29 X29 (Shiftedreg X17 ROR 36) *)
  0xcac2f43c;       (* arm_EOR X28 X1 (Shiftedreg X2 ROR 61) *)
  0xce7b8fbd;       (* arm_RAX1 Q29 Q29 Q27 *)
  0xcad397d3;       (* arm_EOR X19 X30 (Shiftedreg X19 ROR 37) *)
  0xce7e8f7b;       (* arm_RAX1 Q27 Q27 Q30 *)
  0xcad40bbd;       (* arm_EOR X29 X29 (Shiftedreg X20 ROR 2) *)
  0xcac4db9c;       (* arm_EOR X28 X28 (Shiftedreg X4 ROR 54) *)
  0x6e3a1c1e;       (* arm_EOR_VEC Q30 Q0 Q26 128 *)
  0xcac0df5a;       (* arm_EOR X26 X26 (Shiftedreg X0 ROR 55) *)
  0xce9d0840;       (* arm_XAR Q0 Q2 Q29 (word 2) *)
  0xcac39f9c;       (* arm_EOR X28 X28 (Shiftedreg X3 ROR 39) *)
  0xcac5679c;       (* arm_EOR X28 X28 (Shiftedreg X5 ROR 25) *)
  0xce9d5582;       (* arm_XAR Q2 Q12 Q29 (word 21) *)
  0x93c0e000;       (* arm_ROR X0 X0 56 *)
  0xcaddfc00;       (* arm_EOR X0 X0 (Shiftedreg X29 ROR 63) *)
  0xce9c9dac;       (* arm_XAR Q12 Q13 Q28 (word 39) *)
  0xcadbf79b;       (* arm_EOR X27 X28 (Shiftedreg X27 ROR 61) *)
  0xce9be26d;       (* arm_XAR Q13 Q19 Q27 (word 56) *)
  0xcacdb80d;       (* arm_EOR X13 X0 (Shiftedreg X13 ROR 46) *)
  0xcadcffbc;       (* arm_EOR X28 X29 (Shiftedreg X28 ROR 63) *)
  0xce9c22f3;       (* arm_XAR Q19 Q23 Q28 (word 8) *)
  0xcad40bdd;       (* arm_EOR X29 X30 (Shiftedreg X20 ROR 2) *)
  0xcac39f54;       (* arm_EOR X20 X26 (Shiftedreg X3 ROR 39) *)
  0xce9a5df7;       (* arm_XAR Q23 Q15 Q26 (word 23) *)
  0xcacbc80b;       (* arm_EOR X11 X0 (Shiftedreg X11 ROR 50) *)
  0xce99fc2f;       (* arm_XAR Q15 Q1 Q25 (word 63) *)
  0xcad92799;       (* arm_EOR X25 X28 (Shiftedreg X25 ROR 9) *)
  0xcad55383;       (* arm_EOR X3 X28 (Shiftedreg X21 ROR 20) *)
  0xce9c2501;       (* arm_XAR Q1 Q8 Q28 (word 9) *)
  0xca010355;       (* arm_EOR X21 X26 X1 *)
  0xce994e08;       (* arm_XAR Q8 Q16 Q25 (word 19) *)
  0xcac9c769;       (* arm_EOR X9 X27 (Shiftedreg X9 ROR 49) *)
  0xcad87398;       (* arm_EOR X24 X28 (Shiftedreg X24 ROR 28) *)
  0xce9de8f0;       (* arm_XAR Q16 Q7 Q29 (word 58) *)
  0xcad193c1;       (* arm_EOR X1 X30 (Shiftedreg X17 ROR 36) *)
  0xcace200e;       (* arm_EOR X14 X0 (Shiftedreg X14 ROR 8) *)
  0xce9af547;       (* arm_XAR Q7 Q10 Q26 (word 61) *)
  0xcad6b396;       (* arm_EOR X22 X28 (Shiftedreg X22 ROR 44) *)
  0xce9c906a;       (* arm_XAR Q10 Q3 Q28 (word 36) *)
  0xcac8e368;       (* arm_EOR X8 X27 (Shiftedreg X8 ROR 56) *)
  0xcac74f71;       (* arm_EOR X17 X27 (Shiftedreg X7 ROR 19) *)
  0xce9cae43;       (* arm_XAR Q3 Q18 Q28 (word 43) *)
  0xcacff80f;       (* arm_EOR X15 X0 (Shiftedreg X15 ROR 62) *)
  0x8af6be87;       (* arm_BIC X7 X20 (Shiftedreg X22 ROR 47) *)
  0xce9dc632;       (* arm_XAR Q18 Q17 Q29 (word 49) *)
  0xcac4db44;       (* arm_EOR X4 X26 (Shiftedreg X4 ROR 54) *)
  0xce99d971;       (* arm_XAR Q17 Q11 Q25 (word 54) *)
  0xcacc0c00;       (* arm_EOR X0 X0 (Shiftedreg X12 ROR 3) *)
  0xcad7eb9c;       (* arm_EOR X28 X28 (Shiftedreg X23 ROR 58) *)
  0xce9bb12b;       (* arm_XAR Q11 Q9 Q27 (word 44) *)
  0xcac2f757;       (* arm_EOR X23 X26 (Shiftedreg X2 ROR 61) *)
  0xce9d0ec9;       (* arm_XAR Q9 Q22 Q29 (word 3) *)
  0xcac5675a;       (* arm_EOR X26 X26 (Shiftedreg X5 ROR 25) *)
  0xcad09ce2;       (* arm_EOR X2 X7 (Shiftedreg X16 ROR 39) *)
  0xce9b65d6;       (* arm_XAR Q22 Q14 Q27 (word 25) *)
  0x8af4a927;       (* arm_BIC X7 X9 (Shiftedreg X20 ROR 42) *)
  0x8ae941fe;       (* arm_BIC X30 X15 (Shiftedreg X9 ROR 16) *)
  0xce9aba8e;       (* arm_XAR Q14 Q20 Q26 (word 46) *)
  0xcad664e7;       (* arm_EOR X7 X7 (Shiftedreg X22 ROR 25) *)
  0xce9b9494;       (* arm_XAR Q20 Q4 Q27 (word 37) *)
  0xcad4ebcc;       (* arm_EOR X12 X30 (Shiftedreg X20 ROR 58) *)
  0x8af0e2d4;       (* arm_BIC X20 X22 (Shiftedreg X16 ROR 56) *)
  0xce9bcb04;       (* arm_XAR Q4 Q24 Q27 (word 50) *)
  0xcac6af7e;       (* arm_EOR X30 X27 (Shiftedreg X6 ROR 43) *)
  0xcacf5e96;       (* arm_EOR X22 X20 (Shiftedreg X15 ROR 23) *)
  0xce99fab8;       (* arm_XAR Q24 Q21 Q25 (word 62) *)
  0x8aedaa66;       (* arm_BIC X6 X19 (Shiftedreg X13 ROR 42) *)
  0xce9a70b5;       (* arm_XAR Q21 Q5 Q26 (word 28) *)
  0xcad1a4c6;       (* arm_EOR X6 X6 (Shiftedreg X17 ROR 41) *)
  0x8af1fda5;       (* arm_BIC X5 X13 (Shiftedreg X17 ROR 63) *)
  0xce9950db;       (* arm_XAR Q27 Q6 Q25 (word 20) *)
  0xcac556a5;       (* arm_EOR X5 X21 (Shiftedreg X5 ROR 21) *)
  0xce272d45;       (* arm_BCAX Q5 Q10 Q7 Q11 *)
  0x8af5b231;       (* arm_BIC X17 X17 (Shiftedreg X21 ROR 44) *)
  0xcaca5f7b;       (* arm_EOR X27 X27 (Shiftedreg X10 ROR 23) *)
  0xce281d66;       (* arm_BCAX Q6 Q11 Q8 Q7 *)
  0x8af9cab5;       (* arm_BIC X21 X21 (Shiftedreg X25 ROR 50) *)
  0x8ae46774;       (* arm_BIC X20 X27 (Shiftedreg X4 ROR 25) *)
  0xce2920e7;       (* arm_BCAX Q7 Q7 Q9 Q8 *)
  0x8aef7e0a;       (* arm_BIC X10 X16 (Shiftedreg X15 ROR 31) *)
  0xce2a2508;       (* arm_BCAX Q8 Q8 Q10 Q9 *)
  0xcad3aeb0;       (* arm_EOR X16 X21 (Shiftedreg X19 ROR 43) *)
  0xcad97a35;       (* arm_EOR X21 X17 (Shiftedreg X25 ROR 30) *)
  0xce2b2929;       (* arm_BCAX Q9 Q9 Q11 Q10 *)
  0x8af3e733;       (* arm_BIC X19 X25 (Shiftedreg X19 ROR 57) *)
  0xf9400ff9;       (* arm_LDR X25 SP (Immediate_Offset (word 24)) *)
  0xce2c41ea;       (* arm_BCAX Q10 Q15 Q12 Q16 *)
  0xcac9bd51;       (* arm_EOR X17 X10 (Shiftedreg X9 ROR 47) *)
  0xce2d320b;       (* arm_BCAX Q11 Q16 Q13 Q12 *)
  0xf94007e9;       (* arm_LDR X9 SP (Immediate_Offset (word 8)) *)
  0xcadc6e8f;       (* arm_EOR X15 X20 (Shiftedreg X28 ROR 27) *)
  0xce2e358c;       (* arm_BCAX Q12 Q12 Q14 Q13 *)
  0x8afc0894;       (* arm_BIC X20 X4 (Shiftedreg X28 ROR 2) *)
  0xce2f39ad;       (* arm_BCAX Q13 Q13 Q15 Q14 *)
  0xcac1ca8a;       (* arm_EOR X10 X20 (Shiftedreg X1 ROR 50) *)
  0x8afbf174;       (* arm_BIC X20 X11 (Shiftedreg X27 ROR 60) *)
  0xce303dce;       (* arm_BCAX Q14 Q14 Q16 Q15 *)
  0xcac45694;       (* arm_EOR X20 X20 (Shiftedreg X4 ROR 21) *)
  0x8ae1c384;       (* arm_BIC X4 X28 (Shiftedreg X1 ROR 48) *)
  0xce31568f;       (* arm_BCAX Q15 Q20 Q17 Q21 *)
  0x8aebe421;       (* arm_BIC X1 X1 (Shiftedreg X11 ROR 57) *)
  0xce3246b0;       (* arm_BCAX Q16 Q21 Q18 Q17 *)
  0xf879793c;       (* arm_LDR X28 X9 (Shiftreg_Offset X25 3) *)
  0xf9406be9;       (* arm_LDR X9 SP (Immediate_Offset (word 208)) *)
  0xce334a31;       (* arm_BCAX Q17 Q17 Q19 Q18 *)
  0x91000739;       (* arm_ADD X25 X25 (rvalue (word 1)) *)
  0xf9000ff9;       (* arm_STR X25 SP (Immediate_Offset (word 24)) *)
  0xce344e52;       (* arm_BCAX Q18 Q18 Q20 Q19 *)
  0xf1005f3f;       (* arm_CMP X25 (rvalue (word 23)) *)
  0xce355273;       (* arm_BCAX Q19 Q19 Q21 Q20 *)
  0xcadbd439;       (* arm_EOR X25 X1 (Shiftedreg X27 ROR 53) *)
  0x8afabfdb;       (* arm_BIC X27 X30 (Shiftedreg X26 ROR 47) *)
  0xce360414;       (* arm_BCAX Q20 Q0 Q22 Q1 *)
  0xca1c00a1;       (* arm_EOR X1 X5 X28 *)
  0xce375835;       (* arm_BCAX Q21 Q1 Q23 Q22 *)
  0xcacba485;       (* arm_EOR X5 X4 (Shiftedreg X11 ROR 41) *)
  0xcacd8e6b;       (* arm_EOR X11 X19 (Shiftedreg X13 ROR 35) *)
  0xce385ed6;       (* arm_BCAX Q22 Q22 Q24 Q23 *)
  0x8af82b4d;       (* arm_BIC X13 X26 (Shiftedreg X24 ROR 10) *)
  0xcad8e77c;       (* arm_EOR X28 X27 (Shiftedreg X24 ROR 57) *)
  0xce2062f7;       (* arm_BCAX Q23 Q23 Q0 Q24 *)
  0x8ae9bf1b;       (* arm_BIC X27 X24 (Shiftedreg X9 ROR 47) *)
  0xce210318;       (* arm_BCAX Q24 Q24 Q1 Q0 *)
  0x8ae326f3;       (* arm_BIC X19 X23 (Shiftedreg X3 ROR 9) *)
  0x8aeea7a4;       (* arm_BIC X4 X29 (Shiftedreg X14 ROR 41) *)
  0xce226fc0;       (* arm_BCAX Q0 Q30 Q2 Q27 *)
  0xcaddb278;       (* arm_EOR X24 X19 (Shiftedreg X29 ROR 44) *)
  0x8afd8c7d;       (* arm_BIC X29 X3 (Shiftedreg X29 ROR 35) *)
  0xce230b61;       (* arm_BCAX Q1 Q27 Q3 Q2 *)
  0xcac9e5ad;       (* arm_EOR X13 X13 (Shiftedreg X9 ROR 57) *)
  0xce240c42;       (* arm_BCAX Q2 Q2 Q4 Q3 *)
  0xcace33b3;       (* arm_EOR X19 X29 (Shiftedreg X14 ROR 12) *)
  0x8ae04d3d;       (* arm_BIC X29 X9 (Shiftedreg X0 ROR 19) *)
  0xce3e1063;       (* arm_BCAX Q3 Q3 Q30 Q4 *)
  0x8ae815ce;       (* arm_BIC X14 X14 (Shiftedreg X8 ROR 5) *)
  0xce3b7884;       (* arm_BCAX Q4 Q4 Q27 Q30 *)
  0xcad7adc9;       (* arm_EOR X9 X14 (Shiftedreg X23 ROR 43) *)
  0xcac8b88e;       (* arm_EOR X14 X4 (Shiftedreg X8 ROR 46) *)
  0x8af79917;       (* arm_BIC X23 X8 (Shiftedreg X23 ROR 38) *)
  0xcac00b68;       (* arm_EOR X8 X27 (Shiftedreg X0 ROR 2) *)
  0xcac3bee4;       (* arm_EOR X4 X23 (Shiftedreg X3 ROR 47) *)
  0x8afe1403;       (* arm_BIC X3 X0 (Shiftedreg X30 ROR 5) *)
  0xcadad077;       (* arm_EOR X23 X3 (Shiftedreg X26 ROR 52) *)
  0xcade63a3;       (* arm_EOR X3 X29 (Shiftedreg X30 ROR 24) *)
  0xf9400bfe;       (* arm_LDR X30 SP (Immediate_Offset (word 16)) *)
  0x4ddfcfdc;       (* arm_LD1R Q28 X30 (Postimmediate_Offset (word 8)) 64 128 *)
  0xf9000bfe;       (* arm_STR X30 SP (Immediate_Offset (word 16)) *)
  0x6e3c1c00;       (* arm_EOR_VEC Q0 Q0 Q28 128 *)
  0x54ffe96d;       (* arm_BLE (word 2096428) *)
  0x93c2f442;       (* arm_ROR X2 X2 61 *)
  0x93c39c63;       (* arm_ROR X3 X3 39 *)
  0x93c4d884;       (* arm_ROR X4 X4 54 *)
  0x93c564a5;       (* arm_ROR X5 X5 25 *)
  0x93c6acc6;       (* arm_ROR X6 X6 43 *)
  0x93c74ce7;       (* arm_ROR X7 X7 19 *)
  0x93c8e108;       (* arm_ROR X8 X8 56 *)
  0x93c9c529;       (* arm_ROR X9 X9 49 *)
  0x93ca5d4a;       (* arm_ROR X10 X10 23 *)
  0x93cbc96b;       (* arm_ROR X11 X11 50 *)
  0x93cc0d8c;       (* arm_ROR X12 X12 3 *)
  0x93cdb9ad;       (* arm_ROR X13 X13 46 *)
  0x93ce21ce;       (* arm_ROR X14 X14 8 *)
  0x93cff9ef;       (* arm_ROR X15 X15 62 *)
  0x93d19231;       (* arm_ROR X17 X17 36 *)
  0x93dcff9c;       (* arm_ROR X28 X28 63 *)
  0x93d39673;       (* arm_ROR X19 X19 37 *)
  0x93d40a94;       (* arm_ROR X20 X20 2 *)
  0x93d552b5;       (* arm_ROR X21 X21 20 *)
  0x93d6b2d6;       (* arm_ROR X22 X22 44 *)
  0x93d7eaf7;       (* arm_ROR X23 X23 58 *)
  0x93d87318;       (* arm_ROR X24 X24 28 *)
  0x93d92739;       (* arm_ROR X25 X25 9 *)
  0xf94003e0;       (* arm_LDR X0 SP (Immediate_Offset (word 0)) *)
  0x91064000;       (* arm_ADD X0 X0 (rvalue (word 400)) *)
  0xa9001801;       (* arm_STP X1 X6 X0 (Immediate_Offset (iword (&0))) *)
  0xa901400b;       (* arm_STP X11 X16 X0 (Immediate_Offset (iword (&16))) *)
  0xa9020815;       (* arm_STP X21 X2 X0 (Immediate_Offset (iword (&32))) *)
  0xa9033007;       (* arm_STP X7 X12 X0 (Immediate_Offset (iword (&48))) *)
  0xa9045811;       (* arm_STP X17 X22 X0 (Immediate_Offset (iword (&64))) *)
  0xa9052003;       (* arm_STP X3 X8 X0 (Immediate_Offset (iword (&80))) *)
  0xa906700d;       (* arm_STP X13 X28 X0 (Immediate_Offset (iword (&96))) *)
  0xa9071017;       (* arm_STP X23 X4 X0 (Immediate_Offset (iword (&112))) *)
  0xa9083809;       (* arm_STP X9 X14 X0 (Immediate_Offset (iword (&128))) *)
  0xa9096013;       (* arm_STP X19 X24 X0 (Immediate_Offset (iword (&144))) *)
  0xa90a2805;       (* arm_STP X5 X10 X0 (Immediate_Offset (iword (&160))) *)
  0xa90b500f;       (* arm_STP X15 X20 X0 (Immediate_Offset (iword (&176))) *)
  0xf9006019;       (* arm_STR X25 X0 (Immediate_Offset (word 192)) *)
  0xd1064000;       (* arm_SUB X0 X0 (rvalue (word 400)) *)
  0x91032004;       (* arm_ADD X4 X0 (rvalue (word 200)) *)
  0x4ec12819;       (* arm_TRN1 Q25 Q0 Q1 64 128 *)
  0x4ec3285a;       (* arm_TRN1 Q26 Q2 Q3 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ec1681b;       (* arm_TRN2 Q27 Q0 Q1 64 128 *)
  0x4ec3685c;       (* arm_TRN2 Q28 Q2 Q3 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4ec52899;       (* arm_TRN1 Q25 Q4 Q5 64 128 *)
  0x4ec728da;       (* arm_TRN1 Q26 Q6 Q7 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ec5689b;       (* arm_TRN2 Q27 Q4 Q5 64 128 *)
  0x4ec768dc;       (* arm_TRN2 Q28 Q6 Q7 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4ec92919;       (* arm_TRN1 Q25 Q8 Q9 64 128 *)
  0x4ecb295a;       (* arm_TRN1 Q26 Q10 Q11 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ec9691b;       (* arm_TRN2 Q27 Q8 Q9 64 128 *)
  0x4ecb695c;       (* arm_TRN2 Q28 Q10 Q11 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4ecd2999;       (* arm_TRN1 Q25 Q12 Q13 64 128 *)
  0x4ecf29da;       (* arm_TRN1 Q26 Q14 Q15 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ecd699b;       (* arm_TRN2 Q27 Q12 Q13 64 128 *)
  0x4ecf69dc;       (* arm_TRN2 Q28 Q14 Q15 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4ed12a19;       (* arm_TRN1 Q25 Q16 Q17 64 128 *)
  0x4ed32a5a;       (* arm_TRN1 Q26 Q18 Q19 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ed16a1b;       (* arm_TRN2 Q27 Q16 Q17 64 128 *)
  0x4ed36a5c;       (* arm_TRN2 Q28 Q18 Q19 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0x4ed52a99;       (* arm_TRN1 Q25 Q20 Q21 64 128 *)
  0x4ed72ada;       (* arm_TRN1 Q26 Q22 Q23 64 128 *)
  0xac816819;       (* arm_STP Q25 Q26 X0 (Postimmediate_Offset (iword (&32))) *)
  0x4ed56a9b;       (* arm_TRN2 Q27 Q20 Q21 64 128 *)
  0x4ed76adc;       (* arm_TRN2 Q28 Q22 Q23 64 128 *)
  0x4c9fac9b;       (* arm_STP Q27 Q28 X4 (Postimmediate_Offset (word 32)) *)
  0xfd000018;       (* arm_STR D24 X0 (Immediate_Offset (word 0)) *)
  0x4ed86b19;       (* arm_TRN2 Q25 Q24 Q24 64 128 *)
  0xfd000099;       (* arm_STR D25 X4 (Immediate_Offset (word 0)) *)
  0x6d4927e8;       (* arm_LDP D8 D9 SP (Immediate_Offset (iword (&144))) *)
  0x6d4a2fea;       (* arm_LDP D10 D11 SP (Immediate_Offset (iword (&160))) *)
  0x6d4b37ec;       (* arm_LDP D12 D13 SP (Immediate_Offset (iword (&176))) *)
  0x6d4c3fee;       (* arm_LDP D14 D15 SP (Immediate_Offset (iword (&192))) *)
  0xa94353f3;       (* arm_LDP X19 X20 SP (Immediate_Offset (iword (&48))) *)
  0xa9445bf5;       (* arm_LDP X21 X22 SP (Immediate_Offset (iword (&64))) *)
  0xa94563f7;       (* arm_LDP X23 X24 SP (Immediate_Offset (iword (&80))) *)
  0xa9466bf9;       (* arm_LDP X25 X26 SP (Immediate_Offset (iword (&96))) *)
  0xa94773fb;       (* arm_LDP X27 X28 SP (Immediate_Offset (iword (&112))) *)
  0xa9487bfd;       (* arm_LDP X29 X30 SP (Immediate_Offset (iword (&128))) *)
  0x910383ff;       (* arm_ADD SP SP (rvalue (word 224)) *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC = ARM_MK_EXEC_RULE keccak_f1600_x3_v84a_scalar_mc;;

(*** Additional lazy/deferred rotations in the implementation, row-major ***)

let deferred_rotates = define
 `deferred_rotates =
   [ 0; 21; 14;  0; 44;
     3; 45; 61; 28; 20;
    25;  8; 18;  1;  6;
    10; 15; 56; 27; 36;
    39; 41; 2; 62; 55]`;;

(* ------------------------------------------------------------------------- *)
(* Code length constants                                                     *)
(* ------------------------------------------------------------------------- *)

let LENGTH_KECCAK_F1600_X3_V84A_SCALAR_HYBRID_MC =
  REWRITE_CONV[keccak_f1600_x3_v84a_scalar_mc] `LENGTH keccak_f1600_x3_v84a_scalar_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_PREAMBLE_LENGTH = new_definition
  `KECCAK_F1600_X3_V84A_SCALAR_HYBRID_PREAMBLE_LENGTH = 44`;;

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_POSTAMBLE_LENGTH = new_definition
  `KECCAK_F1600_X3_V84A_SCALAR_HYBRID_POSTAMBLE_LENGTH = 48`;;

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_START = new_definition
  `KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_START = KECCAK_F1600_X3_V84A_SCALAR_HYBRID_PREAMBLE_LENGTH`;;

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_END = new_definition
  `KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_END = LENGTH keccak_f1600_x3_v84a_scalar_mc - KECCAK_F1600_X3_V84A_SCALAR_HYBRID_POSTAMBLE_LENGTH`;;

let LENGTH_SIMPLIFY_CONV =
  REWRITE_CONV[LENGTH_KECCAK_F1600_X3_V84A_SCALAR_HYBRID_MC;
              KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_START; KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_END;
              KECCAK_F1600_X3_V84A_SCALAR_HYBRID_PREAMBLE_LENGTH; KECCAK_F1600_X3_V84A_SCALAR_HYBRID_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV [ADD_0];;

(* ------------------------------------------------------------------------- *)
(* Correctness proof                                                         *)
(* ------------------------------------------------------------------------- *)

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORRECT = prove
 (`!a rc A1 A2 A3 pc stackpointer.
      aligned 16 stackpointer /\
      nonoverlapping (a,600) (stackpointer,216) /\
      ALLPAIRS nonoverlapping
               [(a,600); (stackpointer,216)]
               [(word pc,LENGTH keccak_f1600_x3_v84a_scalar_mc); (rc,192)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) keccak_f1600_x3_v84a_scalar_mc /\
                read PC s = word (pc + KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_START) /\
                read SP s = stackpointer /\
                C_ARGUMENTS [a; rc] s /\
                wordlist_from_memory(a,25) s = A1 /\
                wordlist_from_memory(word_add a (word 200),25) s = A2 /\
                wordlist_from_memory(word_add a (word 400),25) s = A3 /\
                wordlist_from_memory(rc,24) s = round_constants)
           (\s. read PC s = word(pc + KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORE_END) /\
                wordlist_from_memory(a,25) s = keccak 24 A1 /\
                wordlist_from_memory(word_add a (word 200),25) s =
                keccak 24 A2 /\
                wordlist_from_memory(word_add a (word 400),25) s =
                keccak 24 A3)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [X19; X20; X21; X22; X23; X24; X25; X26;
                       X27; X28; X29; X30] ,,
            MAYCHANGE [Q8; Q9; Q10; Q11; Q12; Q13; Q14; Q15] ,,
            MAYCHANGE [memory :> bytes(a,600);
                       memory :> bytes(stackpointer,32);
                       memory :> bytes(word_add stackpointer (word 208),8)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  MAP_EVERY X_GEN_TAC
   [`a:int64`; `rc:int64`; `A1:int64 list`; `A2:int64 list`;
    `A3:int64 list`; `pc:num`; `stackpointer:int64`] THEN
  REWRITE_TAC[fst KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS;
              ALL; ALLPAIRS; NONOVERLAPPING_CLAUSES] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

  (*** Establish once and for all that all the Ai have length 25 ***)

  ASM_CASES_TAC
   `LENGTH(A1:int64 list) = 25 /\ LENGTH(A2:int64 list) = 25 /\
    LENGTH(A3:int64 list) = 25`
  THENL
   [FIRST_X_ASSUM(CONJUNCTS_THEN STRIP_ASSUME_TAC);
    ENSURES_INIT_TAC "s0" THEN MATCH_MP_TAC(TAUT `F ==> p`) THEN
    REPEAT(FIRST_X_ASSUM(MP_TAC o AP_TERM `LENGTH:int64 list->num`)) THEN
    CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
    REWRITE_TAC[LENGTH; ARITH] THEN ASM_MESON_TAC[]] THEN

  (*** The main loop: one scalar and one vector round per iteration ***)

  ENSURES_WHILE_PAUP_TAC `1` `24` `pc + 0x3dc` `pc + 0x6b0`
   `\i s.
      (read SP s = stackpointer /\
       wordlist_from_memory(rc,24) s:int64 list = round_constants /\
       read (memory :> bytes64 stackpointer) s = a /\
       read (memory :> bytes64 (word_add stackpointer (word 8))) s = rc /\
       read (memory :> bytes64 (word_add stackpointer (word 16))) s =
       word_add rc (word(8 * i)) /\
       read (memory :> bytes64 (word_add stackpointer (word 24))) s =
       word i /\
       [read Q0 s; read Q1 s; read Q2 s; read Q3 s; read Q4 s;
        read Q5 s; read Q6 s; read Q7 s; read Q8 s; read Q9 s;
        read Q10 s; read Q11 s; read Q12 s; read Q13 s; read Q14 s;
        read Q15 s; read Q16 s; read Q17 s; read Q18 s; read Q19 s;
        read Q20 s; read Q21 s; read Q22 s; read Q23 s; read Q24 s] =
       MAP2 word_join (keccak i A2) (keccak i A1) /\
       [read X1 s; read X6 s; read X11 s; read X16 s; read X21 s;
        read X2 s; read X7 s; read X12 s; read X17 s; read X22 s;
        read X3 s; read X8 s; read X13 s; read X28 s; read X23 s;
        read X4 s; read X9 s; read X14 s; read X19 s; read X24 s;
        read X5 s; read X10 s; read X15 s; read X20 s; read X25 s] =
       MAP2 word_rol (keccak i A3) (MAP (\j. 64 - j) deferred_rotates)) /\
     (condition_semantics Condition_LE s <=> i < 24)` THEN
  REWRITE_TAC[condition_semantics] THEN REPEAT CONJ_TAC THENL
   [ARITH_TAC;

    (*** Initial holding of the invariant ***)

    REWRITE_TAC[round_constants; CONS_11; GSYM CONJ_ASSOC;
                WORDLIST_FROM_MEMORY_CONV `wordlist_from_memory(rc,24) s:int64 list`] THEN
    ENSURES_INIT_TAC "s0" THEN
    BIGNUM_DIGITIZE_TAC "A_" `read (memory :> bytes (a,8 * 75)) s0` THEN
    REPEAT(FIRST_X_ASSUM
     (MP_TAC o CONV_RULE(LAND_CONV WORDLIST_FROM_MEMORY_CONV))) THEN
    CONV_TAC(ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) THEN
    ASM_REWRITE_TAC[] THEN REPEAT DISCH_TAC THEN
    MEMORY_128_FROM_64_TAC "a" 0 12 THEN
    MEMORY_128_FROM_64_TAC "a" 200 12 THEN
    ASM_REWRITE_TAC[WORD_ADD_0] THEN REPEAT STRIP_TAC THEN
    ARM_STEPS_TAC KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC (1--236) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    CONJ_TAC THENL [CONV_TAC WORD_RULE; ALL_TAC] THEN
    CONJ_TAC THENL
     [GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV)
       [ARITH_RULE `1 = 0 + 1`] THEN
      REWRITE_TAC[keccak; round_constants; keccak_round] THEN
      MAP_EVERY EXPAND_TAC ["A1"; "A2"; "A3"] THEN
      CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
      CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      REWRITE_TAC[MAP2; CONS_11] THEN REPEAT CONJ_TAC THEN
      KECCAK_BITBLAST_TAC;

      GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV)
       [ARITH_RULE `1 = 0 + 1`] THEN
      REWRITE_TAC[keccak; round_constants; keccak_round;
                  deferred_rotates; MAP] THEN
      CONV_TAC(RAND_CONV NUM_REDUCE_CONV) THEN
      MAP_EVERY EXPAND_TAC ["A1"; "A2"; "A3"] THEN
      CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
      CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
      REWRITE_TAC[MAP2; CONS_11] THEN REPEAT CONJ_TAC THEN
      KECCAK_BITBLAST_TAC];

    (*** Preservation of the invariant including end condition code ***)

    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    VAL_INT64_TAC `i:num` THEN
    MP_TAC(WORD_RULE `word_add (word i) (word 1):int64 = word(i + 1)`) THEN
    DISCH_TAC THEN
    CONV_TAC(RATOR_CONV(LAND_CONV
     (ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THENC
      ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV)) THEN
    ASM_REWRITE_TAC[round_constants; CONS_11; GSYM CONJ_ASSOC] THEN
    MP_TAC(ISPECL [`A1:int64 list`; `i:num`] LENGTH_KECCAK) THEN
    MP_TAC(ISPECL [`A2:int64 list`; `i:num`] LENGTH_KECCAK) THEN
    MP_TAC(ISPECL [`A3:int64 list`; `i:num`] LENGTH_KECCAK) THEN
    ASM_REWRITE_TAC[IMP_IMP] THEN REWRITE_TAC[LENGTH_EQ_25] THEN
    DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN SUBST1_TAC) THEN
    REWRITE_TAC[deferred_rotates; MAP] THEN CONV_TAC NUM_REDUCE_CONV THEN
    REWRITE_TAC[MAP2; CONS_11; GSYM CONJ_ASSOC] THEN
    ENSURES_INIT_TAC "s0" THEN

    (*** Both rc cursors read rc[i]: [sp+16] for the vector round and ***)
    (*** [sp+8] indexed by the counter [sp+24] for the scalar round    ***)

    SUBGOAL_THEN
     `read (memory :> bytes64 (word_add rc (word(8 * i)))) s0 =
      EL i round_constants`
    ASSUME_TAC THENL
     [UNDISCH_TAC `i < 24` THEN SPEC_TAC(`i:num`,`i:num`) THEN
      CONV_TAC EXPAND_CASES_CONV THEN
      CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV) THEN
      ASM_REWRITE_TAC[round_constants; WORD_ADD_0] THEN
      CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN REWRITE_TAC[];
      ALL_TAC] THEN

    ARM_STEPS_TAC KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC (1--181) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    REWRITE_TAC[CONJ_ASSOC] THEN CONJ_TAC THENL
     [REWRITE_TAC[GSYM CONJ_ASSOC];
      UNDISCH_TAC `i < 24` THEN SPEC_TAC(`i:num`,`i:num`) THEN
      CONV_TAC EXPAND_CASES_CONV THEN
      CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV)] THEN
    CONJ_TAC THENL
     [CONV_TAC(LAND_CONV WORDLIST_FROM_MEMORY_CONV) THEN
      CONV_TAC(ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) THEN
      ASM_REWRITE_TAC[];
      ALL_TAC] THEN
    CONJ_TAC THENL [CONV_TAC WORD_RULE; ALL_TAC] THEN

    (*** One round for both the vector and the scalar lanes ***)

    CONJ_TAC THEN
    REWRITE_TAC[keccak; keccak_round] THEN
    CONV_TAC(ONCE_DEPTH_CONV EL_CONV) THEN
    CONV_TAC(TOP_DEPTH_CONV let_CONV) THEN
    REWRITE_TAC[MAP2; CONS_11] THEN REPEAT CONJ_TAC THEN
    KECCAK_BITBLAST_TAC;

    (*** The trivial loop-back goal ***)

    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
    CONV_TAC(ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) THEN
    ARM_SIM_TAC KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC [1] THEN
    VAL_INT64_TAC `i:num` THEN
    ASM_REWRITE_TAC[] THEN CONV_TAC(DEPTH_CONV WORD_NUM_RED_CONV);

    ALL_TAC] THEN

  (*** The finale making final deferred rotations and writing back ***)

  CONV_TAC NUM_REDUCE_CONV THEN
  MP_TAC(ISPECL [`A1:int64 list`; `24`] LENGTH_KECCAK) THEN
  MP_TAC(ISPECL [`A2:int64 list`; `24`] LENGTH_KECCAK) THEN
  MP_TAC(ISPECL [`A3:int64 list`; `24`] LENGTH_KECCAK) THEN
  ASM_REWRITE_TAC[] THEN
  REWRITE_TAC[IMP_IMP] THEN REWRITE_TAC[LENGTH_EQ_25] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN SUBST1_TAC) THEN
  REWRITE_TAC[deferred_rotates; MAP] THEN CONV_TAC NUM_REDUCE_CONV THEN
  REWRITE_TAC[MAP2; CONS_11; GSYM CONJ_ASSOC] THEN
  CONV_TAC(RATOR_CONV(LAND_CONV
   (ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THENC
    ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV)) THEN
  ASM_REWRITE_TAC[round_constants; CONS_11; GSYM CONJ_ASSOC] THEN
  REWRITE_TAC[GSYM round_constants] THEN
  ENSURES_INIT_TAC "s0" THEN
  ARM_STEPS_TAC KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC (1--80) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
  CONV_TAC(ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) THEN
  ASM_REWRITE_TAC[] THEN
  RULE_ASSUM_TAC(GEN_REWRITE_RULE TRY_CONV
   [el 1 (CONJUNCTS READ_MEMORY_BYTESIZED_UNSPLIT)]) THEN
  RULE_ASSUM_TAC(CONV_RULE
   (ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV)) THEN
  ASM_REWRITE_TAC[] THEN POP_ASSUM_LIST(K ALL_TAC) THEN
  REWRITE_TAC[CONS_11] THEN REPEAT CONJ_TAC THEN CONV_TAC WORD_BLAST);;

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/fips202/native/aarch64/src/fips202_native_aarch64.h *)

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_SUBROUTINE_CORRECT = prove
 (`!a rc A1 A2 A3 pc stackpointer returnaddress.
      aligned 16 stackpointer /\
      nonoverlapping (a,600) (word_sub stackpointer (word 224),224) /\
      ALLPAIRS nonoverlapping
               [(a,600); (word_sub stackpointer (word 224),224)]
               [(word pc,LENGTH keccak_f1600_x3_v84a_scalar_mc); (rc,192)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) keccak_f1600_x3_v84a_scalar_mc /\
                read PC s = word pc /\
                read SP s = stackpointer /\
                read X30 s = returnaddress /\
                C_ARGUMENTS [a; rc] s /\
                wordlist_from_memory(a,25) s = A1 /\
                wordlist_from_memory(word_add a (word 200),25) s = A2 /\
                wordlist_from_memory(word_add a (word 400),25) s = A3 /\
                wordlist_from_memory(rc,24) s = round_constants)
           (\s. read PC s = returnaddress /\
                wordlist_from_memory(a,25) s = keccak 24 A1 /\
                wordlist_from_memory(word_add a (word 200),25) s =
                keccak 24 A2 /\
                wordlist_from_memory(word_add a (word 400),25) s =
                keccak 24 A3)
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(a,600);
                       memory :> bytes(word_sub stackpointer (word 224),224)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  let TWEAK_CONV =
   ONCE_DEPTH_CONV
    (WORDLIST_FROM_MEMORY_CONV THENC
     ONCE_DEPTH_CONV NORMALIZE_RELATIVE_ADDRESS_CONV) in
  CONV_TAC TWEAK_CONV THEN
  ARM_ADD_RETURN_STACK_TAC ~pre_post_nsteps:(11,11) KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC
   (CONV_RULE TWEAK_CONV (CONV_RULE LENGTH_SIMPLIFY_CONV KECCAK_F1600_X3_V84A_SCALAR_HYBRID_CORRECT))
  `[D8; D9; D10; D11; D12; D13; D14; D15;
    X19; X20; X21; X22; X23; X24; X25; X26; X27; X28; X29; X30]` 224);;

(* ------------------------------------------------------------------------- *)
(* Constant-time and memory safety proof.                                    *)
(* ------------------------------------------------------------------------- *)

needs "s2n_bignum/arm/proofs/consttime.ml";;
needs "mldsa_native/aarch64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    (assoc "sha3_keccak3_f1600_alt" subroutine_signatures)
    KECCAK_F1600_X3_V84A_SCALAR_HYBRID_SUBROUTINE_CORRECT
    KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC;;

let KECCAK_F1600_X3_V84A_SCALAR_HYBRID_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a rc pc stackpointer returnaddress.
           aligned 16 stackpointer /\
           nonoverlapping (a,600) (word_sub stackpointer (word 224),224) /\
           ALLPAIRS nonoverlapping
           [a,600; word_sub stackpointer (word 224),224]
           [word pc,LENGTH keccak_f1600_x3_v84a_scalar_mc; rc,192]
           ==> ensures arm
               (\s.
                    aligned_bytes_loaded s (word pc) keccak_f1600_x3_v84a_scalar_mc /\
                    read PC s = word pc /\
                    read SP s = stackpointer /\
                    read X30 s = returnaddress /\
                    C_ARGUMENTS [a; rc] s /\
                    read events s = e)
               (\s.
                    read PC s = returnaddress /\
                    exists e2.
                        read events s = APPEND e2 e /\
                        e2 =
                        f_events rc a pc (word_sub stackpointer (word 224))
                        returnaddress /\
                        memaccess_inbounds e2
                        [a,600; rc,192;
                         word_sub stackpointer (word 224),224]
                        [a,600; word_sub stackpointer (word 224),224])
               (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars KECCAK_F1600_X3_V84A_SCALAR_HYBRID_EXEC);;
