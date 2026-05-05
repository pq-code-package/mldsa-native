(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Inverse number theoretic transform.                                       *)
(* ========================================================================= *)

needs "s2n_bignum/arm/proofs/base.ml";;
needs "mldsa_native/common/mldsa_specs.ml";;
needs "mldsa_native/aarch64/proofs/aarch64_utils.ml";;
needs "mldsa_native/aarch64/proofs/mldsa_zetas.ml";;

(**** print_literal_from_elf "aarch64/mldsa/intt_aarch64_asm.o";;
 ****)

let mldsa_intt_mc = define_assert_from_elf
 "mldsa_intt_mc" "aarch64/mldsa/intt_aarch64_asm.o"
(*** BYTECODE START ***)
[
  0xd10103ff;       (* arm_SUB SP SP (rvalue (word 64)) *)
  0x6d0027e8;       (* arm_STP D8 D9 SP (Immediate_Offset (iword (&0))) *)
  0x6d012fea;       (* arm_STP D10 D11 SP (Immediate_Offset (iword (&16))) *)
  0x6d0237ec;       (* arm_STP D12 D13 SP (Immediate_Offset (iword (&32))) *)
  0x6d033fee;       (* arm_STP D14 D15 SP (Immediate_Offset (iword (&48))) *)
  0x529c0025;       (* arm_MOV W5 (rvalue (word 57345)) *)
  0x72a00fe5;       (* arm_MOVK W5 (word 127) 16 *)
  0x4e040cbf;       (* arm_DUP_GEN Q31 X5 32 128 *)
  0xaa0003e3;       (* arm_MOV X3 X0 *)
  0xd2800204;       (* arm_MOV X4 (rvalue (word 16)) *)
  0x3dc0047b;       (* arm_LDR Q27 X3 (Immediate_Offset (word 16)) *)
  0x3dc00072;       (* arm_LDR Q18 X3 (Immediate_Offset (word 0)) *)
  0x3dc00863;       (* arm_LDR Q3 X3 (Immediate_Offset (word 32)) *)
  0x3dc00c6d;       (* arm_LDR Q13 X3 (Immediate_Offset (word 48)) *)
  0x3dc00c22;       (* arm_LDR Q2 X1 (Immediate_Offset (word 48)) *)
  0x3dc01c68;       (* arm_LDR Q8 X3 (Immediate_Offset (word 112)) *)
  0x3dc01875;       (* arm_LDR Q21 X3 (Immediate_Offset (word 96)) *)
  0x4e9b2a4a;       (* arm_TRN1 Q10 Q18 Q27 32 128 *)
  0x4e9b6a57;       (* arm_TRN2 Q23 Q18 Q27 32 128 *)
  0x4e8d2866;       (* arm_TRN1 Q6 Q3 Q13 32 128 *)
  0x4e8d6872;       (* arm_TRN2 Q18 Q3 Q13 32 128 *)
  0x3dc0142c;       (* arm_LDR Q12 X1 (Immediate_Offset (word 80)) *)
  0x3dc01031;       (* arm_LDR Q17 X1 (Immediate_Offset (word 64)) *)
  0x4ec6695d;       (* arm_TRN2 Q29 Q10 Q6 64 128 *)
  0x4ed26aee;       (* arm_TRN2 Q14 Q23 Q18 64 128 *)
  0x4ec6294a;       (* arm_TRN1 Q10 Q10 Q6 64 128 *)
  0x4ed22afa;       (* arm_TRN1 Q26 Q23 Q18 64 128 *)
  0x6eae87a3;       (* arm_SUB_VEC Q3 Q29 Q14 32 128 *)
  0x4e882aad;       (* arm_TRN1 Q13 Q21 Q8 32 128 *)
  0x3dc00426;       (* arm_LDR Q6 X1 (Immediate_Offset (word 16)) *)
  0x4eba8558;       (* arm_ADD_VEC Q24 Q10 Q26 32 128 *)
  0x6eba855e;       (* arm_SUB_VEC Q30 Q10 Q26 32 128 *)
  0x6eacb46c;       (* arm_SQRDMULH_VEC Q12 Q3 Q12 32 128 *)
  0x3dc00829;       (* arm_LDR Q9 X1 (Immediate_Offset (word 32)) *)
  0x6ea2b7c5;       (* arm_SQRDMULH_VEC Q5 Q30 Q2 32 128 *)
  0x4eb19c64;       (* arm_MUL_VEC Q4 Q3 Q17 32 128 *)
  0x3dc01463;       (* arm_LDR Q3 X3 (Immediate_Offset (word 80)) *)
  0x4eae87aa;       (* arm_ADD_VEC Q10 Q29 Q14 32 128 *)
  0x3dc0107a;       (* arm_LDR Q26 X3 (Immediate_Offset (word 64)) *)
  0x4ea99fcf;       (* arm_MUL_VEC Q15 Q30 Q9 32 128 *)
  0x4e886abe;       (* arm_TRN2 Q30 Q21 Q8 32 128 *)
  0x6eaa8715;       (* arm_SUB_VEC Q21 Q24 Q10 32 128 *)
  0x4eaa871d;       (* arm_ADD_VEC Q29 Q24 Q10 32 128 *)
  0x6f9f40af;       (* arm_MLS_VEC Q15 Q5 (Q31 :> LANE_S 0) 32 128 *)
  0x3cc60430;       (* arm_LDR Q16 X1 (Postimmediate_Offset (word 96)) *)
  0x4e836b4a;       (* arm_TRN2 Q10 Q26 Q3 32 128 *)
  0x6f9f4184;       (* arm_MLS_VEC Q4 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x4e832b43;       (* arm_TRN1 Q3 Q26 Q3 32 128 *)
  0x3dc01420;       (* arm_LDR Q0 X1 (Immediate_Offset (word 80)) *)
  0x4ede6959;       (* arm_TRN2 Q25 Q10 Q30 64 128 *)
  0x6ea6b6ac;       (* arm_SQRDMULH_VEC Q12 Q21 Q6 32 128 *)
  0x4ecd6861;       (* arm_TRN2 Q1 Q3 Q13 64 128 *)
  0x4eb09eb5;       (* arm_MUL_VEC Q21 Q21 Q16 32 128 *)
  0x6eb98437;       (* arm_SUB_VEC Q23 Q1 Q25 32 128 *)
  0x6ea485e2;       (* arm_SUB_VEC Q2 Q15 Q4 32 128 *)
  0x4ea485f4;       (* arm_ADD_VEC Q20 Q15 Q4 32 128 *)
  0x6ea0b6e4;       (* arm_SQRDMULH_VEC Q4 Q23 Q0 32 128 *)
  0x4ecd2867;       (* arm_TRN1 Q7 Q3 Q13 64 128 *)
  0x6ea6b443;       (* arm_SQRDMULH_VEC Q3 Q2 Q6 32 128 *)
  0x4ede294f;       (* arm_TRN1 Q15 Q10 Q30 64 128 *)
  0x6f9f4195;       (* arm_MLS_VEC Q21 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc00c2c;       (* arm_LDR Q12 X1 (Immediate_Offset (word 48)) *)
  0x6eaf84ed;       (* arm_SUB_VEC Q13 Q7 Q15 32 128 *)
  0x4eb09c4a;       (* arm_MUL_VEC Q10 Q2 Q16 32 128 *)
  0x3dc01030;       (* arm_LDR Q16 X1 (Immediate_Offset (word 64)) *)
  0x3dc00825;       (* arm_LDR Q5 X1 (Immediate_Offset (word 32)) *)
  0x6f9f406a;       (* arm_MLS_VEC Q10 Q3 (Q31 :> LANE_S 0) 32 128 *)
  0x4e946bab;       (* arm_TRN2 Q11 Q29 Q20 32 128 *)
  0x6eacb5a2;       (* arm_SQRDMULH_VEC Q2 Q13 Q12 32 128 *)
  0xfc420449;       (* arm_LDR D9 X2 (Postimmediate_Offset (word 32)) *)
  0x4ea59db1;       (* arm_MUL_VEC Q17 Q13 Q5 32 128 *)
  0x4e942bb8;       (* arm_TRN1 Q24 Q29 Q20 32 128 *)
  0x4e8a2aac;       (* arm_TRN1 Q12 Q21 Q10 32 128 *)
  0x4e8a6aaa;       (* arm_TRN2 Q10 Q21 Q10 32 128 *)
  0x4eb09ef6;       (* arm_MUL_VEC Q22 Q23 Q16 32 128 *)
  0x3cdf005a;       (* arm_LDR Q26 X2 (Immediate_Offset (word 18446744073709551600)) *)
  0x4ecc2b0d;       (* arm_TRN1 Q13 Q24 Q12 64 128 *)
  0x4eca2963;       (* arm_TRN1 Q3 Q11 Q10 64 128 *)
  0x6f9f4051;       (* arm_MLS_VEC Q17 Q2 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4096;       (* arm_MLS_VEC Q22 Q4 (Q31 :> LANE_S 0) 32 128 *)
  0x6ea385b7;       (* arm_SUB_VEC Q23 Q13 Q3 32 128 *)
  0x4eca696a;       (* arm_TRN2 Q10 Q11 Q10 64 128 *)
  0x4fbad2e0;       (* arm_SQRDMULH_VEC Q0 Q23 (Q26 :> LANE_S 1) 32 128 *)
  0x4ecc6b15;       (* arm_TRN2 Q21 Q24 Q12 64 128 *)
  0x4f9a82fd;       (* arm_MUL_VEC Q29 Q23 (Q26 :> LANE_S 0) 32 128 *)
  0x6eaa86b7;       (* arm_SUB_VEC Q23 Q21 Q10 32 128 *)
  0x4fbadae8;       (* arm_SQRDMULH_VEC Q8 Q23 (Q26 :> LANE_S 3) 32 128 *)
  0x4eb98426;       (* arm_ADD_VEC Q6 Q1 Q25 32 128 *)
  0x4eaa86ab;       (* arm_ADD_VEC Q11 Q21 Q10 32 128 *)
  0x6f9f401d;       (* arm_MLS_VEC Q29 Q0 (Q31 :> LANE_S 0) 32 128 *)
  0x4ea385be;       (* arm_ADD_VEC Q30 Q13 Q3 32 128 *)
  0x3dc00422;       (* arm_LDR Q2 X1 (Immediate_Offset (word 16)) *)
  0x4f9a8ae3;       (* arm_MUL_VEC Q3 Q23 (Q26 :> LANE_S 2) 32 128 *)
  0x4eaf84ec;       (* arm_ADD_VEC Q12 Q7 Q15 32 128 *)
  0x6f9f4103;       (* arm_MLS_VEC Q3 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x6eab87cd;       (* arm_SUB_VEC Q13 Q30 Q11 32 128 *)
  0x6ea68595;       (* arm_SUB_VEC Q21 Q12 Q6 32 128 *)
  0x4eb6863a;       (* arm_ADD_VEC Q26 Q17 Q22 32 128 *)
  0x4fa9d1bc;       (* arm_SQRDMULH_VEC Q28 Q13 (Q9 :> LANE_S 1) 32 128 *)
  0x4f8981b2;       (* arm_MUL_VEC Q18 Q13 (Q9 :> LANE_S 0) 32 128 *)
  0x6ea387a8;       (* arm_SUB_VEC Q8 Q29 Q3 32 128 *)
  0x6ea2b6b8;       (* arm_SQRDMULH_VEC Q24 Q21 Q2 32 128 *)
  0x4eab87cf;       (* arm_ADD_VEC Q15 Q30 Q11 32 128 *)
  0x4ea387aa;       (* arm_ADD_VEC Q10 Q29 Q3 32 128 *)
  0x4ea6858e;       (* arm_ADD_VEC Q14 Q12 Q6 32 128 *)
  0x4fa9d110;       (* arm_SQRDMULH_VEC Q16 Q8 (Q9 :> LANE_S 1) 32 128 *)
  0x6eb68623;       (* arm_SUB_VEC Q3 Q17 Q22 32 128 *)
  0x4f898108;       (* arm_MUL_VEC Q8 Q8 (Q9 :> LANE_S 0) 32 128 *)
  0x3cc60431;       (* arm_LDR Q17 X1 (Postimmediate_Offset (word 96)) *)
  0xd1000884;       (* arm_SUB X4 X4 (rvalue (word 2)) *)
  0xfc420444;       (* arm_LDR D4 X2 (Postimmediate_Offset (word 32)) *)
  0x4eb19ea0;       (* arm_MUL_VEC Q0 Q21 Q17 32 128 *)
  0x3dc02867;       (* arm_LDR Q7 X3 (Immediate_Offset (word 160)) *)
  0x3dc02c7b;       (* arm_LDR Q27 X3 (Immediate_Offset (word 176)) *)
  0x6f9f4208;       (* arm_MLS_VEC Q8 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc0207d;       (* arm_LDR Q29 X3 (Immediate_Offset (word 128)) *)
  0x4e9a29c9;       (* arm_TRN1 Q9 Q14 Q26 32 128 *)
  0x3dc02479;       (* arm_LDR Q25 X3 (Immediate_Offset (word 144)) *)
  0x6f9f4300;       (* arm_MLS_VEC Q0 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x3c84046f;       (* arm_STR Q15 X3 (Postimmediate_Offset (word 64)) *)
  0x4e9b28e1;       (* arm_TRN1 Q1 Q7 Q27 32 128 *)
  0x3dc0142f;       (* arm_LDR Q15 X1 (Immediate_Offset (word 80)) *)
  0x4e9b68ec;       (* arm_TRN2 Q12 Q7 Q27 32 128 *)
  0x6ea2b470;       (* arm_SQRDMULH_VEC Q16 Q3 Q2 32 128 *)
  0x4e992bb5;       (* arm_TRN1 Q21 Q29 Q25 32 128 *)
  0x3c9f0068;       (* arm_STR Q8 X3 (Immediate_Offset (word 18446744073709551600)) *)
  0x4e996bb3;       (* arm_TRN2 Q19 Q29 Q25 32 128 *)
  0x6f9f4392;       (* arm_MLS_VEC Q18 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc00c36;       (* arm_LDR Q22 X1 (Immediate_Offset (word 48)) *)
  0x4ec16aad;       (* arm_TRN2 Q13 Q21 Q1 64 128 *)
  0x4ecc6a65;       (* arm_TRN2 Q5 Q19 Q12 64 128 *)
  0x4eb19c77;       (* arm_MUL_VEC Q23 Q3 Q17 32 128 *)
  0x4ec12ab1;       (* arm_TRN1 Q17 Q21 Q1 64 128 *)
  0x3dc0103d;       (* arm_LDR Q29 X1 (Immediate_Offset (word 64)) *)
  0x6f9f4217;       (* arm_MLS_VEC Q23 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x6ea585be;       (* arm_SUB_VEC Q30 Q13 Q5 32 128 *)
  0x4ecc2a78;       (* arm_TRN1 Q24 Q19 Q12 64 128 *)
  0x3c9d006a;       (* arm_STR Q10 X3 (Immediate_Offset (word 18446744073709551568)) *)
  0x6eafb7d0;       (* arm_SQRDMULH_VEC Q16 Q30 Q15 32 128 *)
  0x3dc0082a;       (* arm_LDR Q10 X1 (Immediate_Offset (word 32)) *)
  0x4e9a69cc;       (* arm_TRN2 Q12 Q14 Q26 32 128 *)
  0x3c9e0072;       (* arm_STR Q18 X3 (Immediate_Offset (word 18446744073709551584)) *)
  0x4ebd9fcb;       (* arm_MUL_VEC Q11 Q30 Q29 32 128 *)
  0x6eb88628;       (* arm_SUB_VEC Q8 Q17 Q24 32 128 *)
  0x4e972814;       (* arm_TRN1 Q20 Q0 Q23 32 128 *)
  0x3dc00422;       (* arm_LDR Q2 X1 (Immediate_Offset (word 16)) *)
  0x4e97681a;       (* arm_TRN2 Q26 Q0 Q23 32 128 *)
  0x6eb6b513;       (* arm_SQRDMULH_VEC Q19 Q8 Q22 32 128 *)
  0x3cdf004e;       (* arm_LDR Q14 X2 (Immediate_Offset (word 18446744073709551600)) *)
  0x4ed42935;       (* arm_TRN1 Q21 Q9 Q20 64 128 *)
  0x4eaa9d08;       (* arm_MUL_VEC Q8 Q8 Q10 32 128 *)
  0x4eda2986;       (* arm_TRN1 Q6 Q12 Q26 64 128 *)
  0x4ed46920;       (* arm_TRN2 Q0 Q9 Q20 64 128 *)
  0x6f9f420b;       (* arm_MLS_VEC Q11 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x6ea686a7;       (* arm_SUB_VEC Q7 Q21 Q6 32 128 *)
  0x4eda699c;       (* arm_TRN2 Q28 Q12 Q26 64 128 *)
  0x4ea686aa;       (* arm_ADD_VEC Q10 Q21 Q6 32 128 *)
  0x4f8e80f2;       (* arm_MUL_VEC Q18 Q7 (Q14 :> LANE_S 0) 32 128 *)
  0x4ea585b4;       (* arm_ADD_VEC Q20 Q13 Q5 32 128 *)
  0x4faed0fe;       (* arm_SQRDMULH_VEC Q30 Q7 (Q14 :> LANE_S 1) 32 128 *)
  0x6ebc8415;       (* arm_SUB_VEC Q21 Q0 Q28 32 128 *)
  0x4ebc840d;       (* arm_ADD_VEC Q13 Q0 Q28 32 128 *)
  0x4eb88629;       (* arm_ADD_VEC Q9 Q17 Q24 32 128 *)
  0x4faedaa1;       (* arm_SQRDMULH_VEC Q1 Q21 (Q14 :> LANE_S 3) 32 128 *)
  0x3cc60431;       (* arm_LDR Q17 X1 (Postimmediate_Offset (word 96)) *)
  0x4f8e8aae;       (* arm_MUL_VEC Q14 Q21 (Q14 :> LANE_S 2) 32 128 *)
  0x6eb48535;       (* arm_SUB_VEC Q21 Q9 Q20 32 128 *)
  0x6f9f43d2;       (* arm_MLS_VEC Q18 Q30 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f402e;       (* arm_MLS_VEC Q14 Q1 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4268;       (* arm_MLS_VEC Q8 Q19 (Q31 :> LANE_S 0) 32 128 *)
  0x6ead8543;       (* arm_SUB_VEC Q3 Q10 Q13 32 128 *)
  0x4ead854f;       (* arm_ADD_VEC Q15 Q10 Q13 32 128 *)
  0x4fa4d07c;       (* arm_SQRDMULH_VEC Q28 Q3 (Q4 :> LANE_S 1) 32 128 *)
  0x4eae864a;       (* arm_ADD_VEC Q10 Q18 Q14 32 128 *)
  0x6eae8653;       (* arm_SUB_VEC Q19 Q18 Q14 32 128 *)
  0x4f848072;       (* arm_MUL_VEC Q18 Q3 (Q4 :> LANE_S 0) 32 128 *)
  0x6eab8503;       (* arm_SUB_VEC Q3 Q8 Q11 32 128 *)
  0x4eab851a;       (* arm_ADD_VEC Q26 Q8 Q11 32 128 *)
  0x4fa4d270;       (* arm_SQRDMULH_VEC Q16 Q19 (Q4 :> LANE_S 1) 32 128 *)
  0x4eb4852e;       (* arm_ADD_VEC Q14 Q9 Q20 32 128 *)
  0x4f848268;       (* arm_MUL_VEC Q8 Q19 (Q4 :> LANE_S 0) 32 128 *)
  0x6ea2b6b8;       (* arm_SQRDMULH_VEC Q24 Q21 Q2 32 128 *)
  0xf1000484;       (* arm_SUBS X4 X4 (rvalue (word 1)) *)
  0xb5fff6e4;       (* arm_CBNZ X4 (word 2096860) *)
  0x6ea2b473;       (* arm_SQRDMULH_VEC Q19 Q3 Q2 32 128 *)
  0x4e9a69c0;       (* arm_TRN2 Q0 Q14 Q26 32 128 *)
  0x3c84046f;       (* arm_STR Q15 X3 (Postimmediate_Offset (word 64)) *)
  0x4e9a29de;       (* arm_TRN1 Q30 Q14 Q26 32 128 *)
  0x4eb19eba;       (* arm_MUL_VEC Q26 Q21 Q17 32 128 *)
  0x3c9d006a;       (* arm_STR Q10 X3 (Immediate_Offset (word 18446744073709551568)) *)
  0xfc42045d;       (* arm_LDR D29 X2 (Postimmediate_Offset (word 32)) *)
  0x6f9f431a;       (* arm_MLS_VEC Q26 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb19c6a;       (* arm_MUL_VEC Q10 Q3 Q17 32 128 *)
  0x3cdf004e;       (* arm_LDR Q14 X2 (Immediate_Offset (word 18446744073709551600)) *)
  0x6f9f426a;       (* arm_MLS_VEC Q10 Q19 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4208;       (* arm_MLS_VEC Q8 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x4e8a6b56;       (* arm_TRN2 Q22 Q26 Q10 32 128 *)
  0x4e8a2b59;       (* arm_TRN1 Q25 Q26 Q10 32 128 *)
  0x4ed92bc1;       (* arm_TRN1 Q1 Q30 Q25 64 128 *)
  0x4ed62802;       (* arm_TRN1 Q2 Q0 Q22 64 128 *)
  0x4ed96bcd;       (* arm_TRN2 Q13 Q30 Q25 64 128 *)
  0x4ed66807;       (* arm_TRN2 Q7 Q0 Q22 64 128 *)
  0x6f9f4392;       (* arm_MLS_VEC Q18 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x6ea28436;       (* arm_SUB_VEC Q22 Q1 Q2 32 128 *)
  0x4ea785a3;       (* arm_ADD_VEC Q3 Q13 Q7 32 128 *)
  0x4faed2db;       (* arm_SQRDMULH_VEC Q27 Q22 (Q14 :> LANE_S 1) 32 128 *)
  0x6ea785a4;       (* arm_SUB_VEC Q4 Q13 Q7 32 128 *)
  0x3c9f0068;       (* arm_STR Q8 X3 (Immediate_Offset (word 18446744073709551600)) *)
  0x4faed880;       (* arm_SQRDMULH_VEC Q0 Q4 (Q14 :> LANE_S 3) 32 128 *)
  0x4ea28430;       (* arm_ADD_VEC Q16 Q1 Q2 32 128 *)
  0x3c9e0072;       (* arm_STR Q18 X3 (Immediate_Offset (word 18446744073709551584)) *)
  0x4f8e8897;       (* arm_MUL_VEC Q23 Q4 (Q14 :> LANE_S 2) 32 128 *)
  0x4ea38604;       (* arm_ADD_VEC Q4 Q16 Q3 32 128 *)
  0x6ea38611;       (* arm_SUB_VEC Q17 Q16 Q3 32 128 *)
  0x4f8e82ce;       (* arm_MUL_VEC Q14 Q22 (Q14 :> LANE_S 0) 32 128 *)
  0x3c840464;       (* arm_STR Q4 X3 (Postimmediate_Offset (word 64)) *)
  0x6f9f4017;       (* arm_MLS_VEC Q23 Q0 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f436e;       (* arm_MLS_VEC Q14 Q27 (Q31 :> LANE_S 0) 32 128 *)
  0x4f9d822b;       (* arm_MUL_VEC Q11 Q17 (Q29 :> LANE_S 0) 32 128 *)
  0x4fbdd22a;       (* arm_SQRDMULH_VEC Q10 Q17 (Q29 :> LANE_S 1) 32 128 *)
  0x6eb785c0;       (* arm_SUB_VEC Q0 Q14 Q23 32 128 *)
  0x4eb785c6;       (* arm_ADD_VEC Q6 Q14 Q23 32 128 *)
  0x4fbdd00c;       (* arm_SQRDMULH_VEC Q12 Q0 (Q29 :> LANE_S 1) 32 128 *)
  0x4f9d8000;       (* arm_MUL_VEC Q0 Q0 (Q29 :> LANE_S 0) 32 128 *)
  0x3c9d0066;       (* arm_STR Q6 X3 (Immediate_Offset (word 18446744073709551568)) *)
  0x6f9f414b;       (* arm_MLS_VEC Q11 Q10 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4180;       (* arm_MLS_VEC Q0 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x3c9e006b;       (* arm_STR Q11 X3 (Immediate_Offset (word 18446744073709551584)) *)
  0x3c9f0060;       (* arm_STR Q0 X3 (Immediate_Offset (word 18446744073709551600)) *)
  0x5287ffc5;       (* arm_MOV W5 (rvalue (word 16382)) *)
  0x4e040cbd;       (* arm_DUP_GEN Q29 X5 32 128 *)
  0x5281c065;       (* arm_MOV W5 (rvalue (word 3587)) *)
  0x72a00805;       (* arm_MOVK W5 (word 64) 16 *)
  0x4e040cbe;       (* arm_DUP_GEN Q30 X5 32 128 *)
  0xd2800084;       (* arm_MOV X4 (rvalue (word 4)) *)
  0x3cc80440;       (* arm_LDR Q0 X2 (Postimmediate_Offset (word 128)) *)
  0x3cd90041;       (* arm_LDR Q1 X2 (Immediate_Offset (word 18446744073709551504)) *)
  0x3cda0042;       (* arm_LDR Q2 X2 (Immediate_Offset (word 18446744073709551520)) *)
  0x3cdb0043;       (* arm_LDR Q3 X2 (Immediate_Offset (word 18446744073709551536)) *)
  0x3cdc0044;       (* arm_LDR Q4 X2 (Immediate_Offset (word 18446744073709551552)) *)
  0x3cdd0045;       (* arm_LDR Q5 X2 (Immediate_Offset (word 18446744073709551568)) *)
  0x3cde0046;       (* arm_LDR Q6 X2 (Immediate_Offset (word 18446744073709551584)) *)
  0x3cdf0047;       (* arm_LDR Q7 X2 (Immediate_Offset (word 18446744073709551600)) *)
  0x3dc03008;       (* arm_LDR Q8 X0 (Immediate_Offset (word 192)) *)
  0x3dc0201b;       (* arm_LDR Q27 X0 (Immediate_Offset (word 128)) *)
  0x3dc07014;       (* arm_LDR Q20 X0 (Immediate_Offset (word 448)) *)
  0x3dc06017;       (* arm_LDR Q23 X0 (Immediate_Offset (word 384)) *)
  0x3dc0f018;       (* arm_LDR Q24 X0 (Immediate_Offset (word 960)) *)
  0x3dc0101c;       (* arm_LDR Q28 X0 (Immediate_Offset (word 64)) *)
  0x3dc0d019;       (* arm_LDR Q25 X0 (Immediate_Offset (word 832)) *)
  0x3dc0e00a;       (* arm_LDR Q10 X0 (Immediate_Offset (word 896)) *)
  0x6ea8876f;       (* arm_SUB_VEC Q15 Q27 Q8 32 128 *)
  0x3dc0001a;       (* arm_LDR Q26 X0 (Immediate_Offset (word 0)) *)
  0x3dc0c012;       (* arm_LDR Q18 X0 (Immediate_Offset (word 768)) *)
  0x4eb486e9;       (* arm_ADD_VEC Q9 Q23 Q20 32 128 *)
  0x4f8481eb;       (* arm_MUL_VEC Q11 Q15 (Q4 :> LANE_S 0) 32 128 *)
  0x6eb486f3;       (* arm_SUB_VEC Q19 Q23 Q20 32 128 *)
  0x6eb88556;       (* arm_SUB_VEC Q22 Q10 Q24 32 128 *)
  0x3dc0900d;       (* arm_LDR Q13 X0 (Immediate_Offset (word 576)) *)
  0x4fa4d1ec;       (* arm_SQRDMULH_VEC Q12 Q15 (Q4 :> LANE_S 1) 32 128 *)
  0x6ebc874e;       (* arm_SUB_VEC Q14 Q26 Q28 32 128 *)
  0x3dc08011;       (* arm_LDR Q17 X0 (Immediate_Offset (word 512)) *)
  0x4eb98657;       (* arm_ADD_VEC Q23 Q18 Q25 32 128 *)
  0x4fa3d9cf;       (* arm_SQRDMULH_VEC Q15 Q14 (Q3 :> LANE_S 3) 32 128 *)
  0x6eb98652;       (* arm_SUB_VEC Q18 Q18 Q25 32 128 *)
  0x4f8389d9;       (* arm_MUL_VEC Q25 Q14 (Q3 :> LANE_S 2) 32 128 *)
  0x6ead8630;       (* arm_SUB_VEC Q16 Q17 Q13 32 128 *)
  0x6f9f418b;       (* arm_MLS_VEC Q11 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb88555;       (* arm_ADD_VEC Q21 Q10 Q24 32 128 *)
  0x6f9f41f9;       (* arm_MLS_VEC Q25 Q15 (Q31 :> LANE_S 0) 32 128 *)
  0x4f858a0c;       (* arm_MUL_VEC Q12 Q16 (Q5 :> LANE_S 2) 32 128 *)
  0x6eb586ea;       (* arm_SUB_VEC Q10 Q23 Q21 32 128 *)
  0x4fa3d14e;       (* arm_SQRDMULH_VEC Q14 Q10 (Q3 :> LANE_S 1) 32 128 *)
  0x4eb586f7;       (* arm_ADD_VEC Q23 Q23 Q21 32 128 *)
  0x4ea8877b;       (* arm_ADD_VEC Q27 Q27 Q8 32 128 *)
  0x4f83814f;       (* arm_MUL_VEC Q15 Q10 (Q3 :> LANE_S 0) 32 128 *)
  0x4eab8738;       (* arm_ADD_VEC Q24 Q25 Q11 32 128 *)
  0x6eab872a;       (* arm_SUB_VEC Q10 Q25 Q11 32 128 *)
  0x3dc04019;       (* arm_LDR Q25 X0 (Immediate_Offset (word 256)) *)
  0x4fa6da48;       (* arm_SQRDMULH_VEC Q8 Q18 (Q6 :> LANE_S 3) 32 128 *)
  0x4ebc8755;       (* arm_ADD_VEC Q21 Q26 Q28 32 128 *)
  0x3dc0501a;       (* arm_LDR Q26 X0 (Immediate_Offset (word 320)) *)
  0x4fa5da14;       (* arm_SQRDMULH_VEC Q20 Q16 (Q5 :> LANE_S 3) 32 128 *)
  0x4fa7d2dc;       (* arm_SQRDMULH_VEC Q28 Q22 (Q7 :> LANE_S 1) 32 128 *)
  0x4eba872b;       (* arm_ADD_VEC Q11 Q25 Q26 32 128 *)
  0x6f9f41cf;       (* arm_MLS_VEC Q15 Q14 (Q31 :> LANE_S 0) 32 128 *)
  0x4ead8631;       (* arm_ADD_VEC Q17 Q17 Q13 32 128 *)
  0x4f8782cd;       (* arm_MUL_VEC Q13 Q22 (Q7 :> LANE_S 0) 32 128 *)
  0x3dc0a00e;       (* arm_LDR Q14 X0 (Immediate_Offset (word 640)) *)
  0x3dc0b016;       (* arm_LDR Q22 X0 (Immediate_Offset (word 704)) *)
  0x6f9f438d;       (* arm_MLS_VEC Q13 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x6eba8730;       (* arm_SUB_VEC Q16 Q25 Q26 32 128 *)
  0x6ebb86bc;       (* arm_SUB_VEC Q28 Q21 Q27 32 128 *)
  0x6f9f428c;       (* arm_MLS_VEC Q12 Q20 (Q31 :> LANE_S 0) 32 128 *)
  0x4ea98574;       (* arm_ADD_VEC Q20 Q11 Q9 32 128 *)
  0x4eb685da;       (* arm_ADD_VEC Q26 Q14 Q22 32 128 *)
  0x6eb685ce;       (* arm_SUB_VEC Q14 Q14 Q22 32 128 *)
  0x4fa1db96;       (* arm_SQRDMULH_VEC Q22 Q28 (Q1 :> LANE_S 3) 32 128 *)
  0x6ea98569;       (* arm_SUB_VEC Q9 Q11 Q9 32 128 *)
  0x4f8681d9;       (* arm_MUL_VEC Q25 Q14 (Q6 :> LANE_S 0) 32 128 *)
  0x6eba862b;       (* arm_SUB_VEC Q11 Q17 Q26 32 128 *)
  0x4eba8631;       (* arm_ADD_VEC Q17 Q17 Q26 32 128 *)
  0x4ebb86ba;       (* arm_ADD_VEC Q26 Q21 Q27 32 128 *)
  0x4fa2d97b;       (* arm_SQRDMULH_VEC Q27 Q11 (Q2 :> LANE_S 3) 32 128 *)
  0x4f828975;       (* arm_MUL_VEC Q21 Q11 (Q2 :> LANE_S 2) 32 128 *)
  0x4f868a4b;       (* arm_MUL_VEC Q11 Q18 (Q6 :> LANE_S 2) 32 128 *)
  0x6f9f410b;       (* arm_MLS_VEC Q11 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa6d1c8;       (* arm_SQRDMULH_VEC Q8 Q14 (Q6 :> LANE_S 1) 32 128 *)
  0x4eb48752;       (* arm_ADD_VEC Q18 Q26 Q20 32 128 *)
  0x6f9f4375;       (* arm_MLS_VEC Q21 Q27 (Q31 :> LANE_S 0) 32 128 *)
  0x6eb7863b;       (* arm_SUB_VEC Q27 Q17 Q23 32 128 *)
  0x4f818b8e;       (* arm_MUL_VEC Q14 Q28 (Q1 :> LANE_S 2) 32 128 *)
  0x6eb4875c;       (* arm_SUB_VEC Q28 Q26 Q20 32 128 *)
  0x4eb78637;       (* arm_ADD_VEC Q23 Q17 Q23 32 128 *)
  0x6f9f4119;       (* arm_MLS_VEC Q25 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x4eaf86ba;       (* arm_ADD_VEC Q26 Q21 Q15 32 128 *)
  0x6eaf86af;       (* arm_SUB_VEC Q15 Q21 Q15 32 128 *)
  0x4f858268;       (* arm_MUL_VEC Q8 Q19 (Q5 :> LANE_S 0) 32 128 *)
  0x6f9f42ce;       (* arm_MLS_VEC Q14 Q22 (Q31 :> LANE_S 0) 32 128 *)
  0x6ead8576;       (* arm_SUB_VEC Q22 Q11 Q13 32 128 *)
  0x6eb98594;       (* arm_SUB_VEC Q20 Q12 Q25 32 128 *)
  0x4eb98595;       (* arm_ADD_VEC Q21 Q12 Q25 32 128 *)
  0x4fa3d2cc;       (* arm_SQRDMULH_VEC Q12 Q22 (Q3 :> LANE_S 1) 32 128 *)
  0x4f848a11;       (* arm_MUL_VEC Q17 Q16 (Q4 :> LANE_S 2) 32 128 *)
  0x4fa4da19;       (* arm_SQRDMULH_VEC Q25 Q16 (Q4 :> LANE_S 3) 32 128 *)
  0x4ead8570;       (* arm_ADD_VEC Q16 Q11 Q13 32 128 *)
  0x4f8382cb;       (* arm_MUL_VEC Q11 Q22 (Q3 :> LANE_S 0) 32 128 *)
  0x4fa5d273;       (* arm_SQRDMULH_VEC Q19 Q19 (Q5 :> LANE_S 1) 32 128 *)
  0x4fa1d1f6;       (* arm_SQRDMULH_VEC Q22 Q15 (Q1 :> LANE_S 1) 32 128 *)
  0x4fa2da8d;       (* arm_SQRDMULH_VEC Q13 Q20 (Q2 :> LANE_S 3) 32 128 *)
  0x4f828a94;       (* arm_MUL_VEC Q20 Q20 (Q2 :> LANE_S 2) 32 128 *)
  0x6f9f418b;       (* arm_MLS_VEC Q11 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f41b4;       (* arm_MLS_VEC Q20 Q13 (Q31 :> LANE_S 0) 32 128 *)
  0x6eb7864d;       (* arm_SUB_VEC Q13 Q18 Q23 32 128 *)
  0x4eb78657;       (* arm_ADD_VEC Q23 Q18 Q23 32 128 *)
  0x6f9f4331;       (* arm_MLS_VEC Q17 Q25 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4268;       (* arm_MLS_VEC Q8 Q19 (Q31 :> LANE_S 0) 32 128 *)
  0x6eab8692;       (* arm_SUB_VEC Q18 Q20 Q11 32 128 *)
  0x4eab8694;       (* arm_ADD_VEC Q20 Q20 Q11 32 128 *)
  0x4fa2d12c;       (* arm_SQRDMULH_VEC Q12 Q9 (Q2 :> LANE_S 1) 32 128 *)
  0x4f8181ef;       (* arm_MUL_VEC Q15 Q15 (Q1 :> LANE_S 0) 32 128 *)
  0x6ea8862b;       (* arm_SUB_VEC Q11 Q17 Q8 32 128 *)
  0x6f9f42cf;       (* arm_MLS_VEC Q15 Q22 (Q31 :> LANE_S 0) 32 128 *)
  0x4ea88633;       (* arm_ADD_VEC Q19 Q17 Q8 32 128 *)
  0x4fa2d179;       (* arm_SQRDMULH_VEC Q25 Q11 (Q2 :> LANE_S 1) 32 128 *)
  0x4eb38711;       (* arm_ADD_VEC Q17 Q24 Q19 32 128 *)
  0x6eb38718;       (* arm_SUB_VEC Q24 Q24 Q19 32 128 *)
  0x4f828173;       (* arm_MUL_VEC Q19 Q11 (Q2 :> LANE_S 0) 32 128 *)
  0x4fa0db08;       (* arm_SQRDMULH_VEC Q8 Q24 (Q0 :> LANE_S 3) 32 128 *)
  0x6f9f4333;       (* arm_MLS_VEC Q19 Q25 (Q31 :> LANE_S 0) 32 128 *)
  0x4f828139;       (* arm_MUL_VEC Q25 Q9 (Q2 :> LANE_S 0) 32 128 *)
  0xd1000484;       (* arm_SUB X4 X4 (rvalue (word 1)) *)
  0x6eb086b6;       (* arm_SUB_VEC Q22 Q21 Q16 32 128 *)
  0x6f9f4199;       (* arm_MLS_VEC Q25 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb086ac;       (* arm_ADD_VEC Q12 Q21 Q16 32 128 *)
  0x4f808b09;       (* arm_MUL_VEC Q9 Q24 (Q0 :> LANE_S 2) 32 128 *)
  0x6f9f4109;       (* arm_MLS_VEC Q9 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x6eb985d0;       (* arm_SUB_VEC Q16 Q14 Q25 32 128 *)
  0x4eb985ce;       (* arm_ADD_VEC Q14 Q14 Q25 32 128 *)
  0x4fa1d2d8;       (* arm_SQRDMULH_VEC Q24 Q22 (Q1 :> LANE_S 1) 32 128 *)
  0x6eba85cb;       (* arm_SUB_VEC Q11 Q14 Q26 32 128 *)
  0x4fa0da15;       (* arm_SQRDMULH_VEC Q21 Q16 (Q0 :> LANE_S 3) 32 128 *)
  0x4eba85d9;       (* arm_ADD_VEC Q25 Q14 Q26 32 128 *)
  0x4f8182ce;       (* arm_MUL_VEC Q14 Q22 (Q1 :> LANE_S 0) 32 128 *)
  0x6f9f430e;       (* arm_MLS_VEC Q14 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x4f808a10;       (* arm_MUL_VEC Q16 Q16 (Q0 :> LANE_S 2) 32 128 *)
  0x6f9f42b0;       (* arm_MLS_VEC Q16 Q21 (Q31 :> LANE_S 0) 32 128 *)
  0x4eae8538;       (* arm_ADD_VEC Q24 Q9 Q14 32 128 *)
  0x6ebeb735;       (* arm_SQRDMULH_VEC Q21 Q25 Q30 32 128 *)
  0x4fa0d17a;       (* arm_SQRDMULH_VEC Q26 Q11 (Q0 :> LANE_S 1) 32 128 *)
  0x4ebd9f28;       (* arm_MUL_VEC Q8 Q25 Q29 32 128 *)
  0x6f9f42a8;       (* arm_MLS_VEC Q8 Q21 (Q31 :> LANE_S 0) 32 128 *)
  0x4ebd9f19;       (* arm_MUL_VEC Q25 Q24 Q29 32 128 *)
  0x4f808176;       (* arm_MUL_VEC Q22 Q11 (Q0 :> LANE_S 0) 32 128 *)
  0x6eac862b;       (* arm_SUB_VEC Q11 Q17 Q12 32 128 *)
  0x3d802008;       (* arm_STR Q8 X0 (Immediate_Offset (word 128)) *)
  0x6eae8528;       (* arm_SUB_VEC Q8 Q9 Q14 32 128 *)
  0x4eaf860e;       (* arm_ADD_VEC Q14 Q16 Q15 32 128 *)
  0x4fa0d169;       (* arm_SQRDMULH_VEC Q9 Q11 (Q0 :> LANE_S 1) 32 128 *)
  0x6eaf8615;       (* arm_SUB_VEC Q21 Q16 Q15 32 128 *)
  0x6f9f4356;       (* arm_MLS_VEC Q22 Q26 (Q31 :> LANE_S 0) 32 128 *)
  0x4f80816f;       (* arm_MUL_VEC Q15 Q11 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f412f;       (* arm_MLS_VEC Q15 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x4eac862b;       (* arm_ADD_VEC Q11 Q17 Q12 32 128 *)
  0x4f818950;       (* arm_MUL_VEC Q16 Q10 (Q1 :> LANE_S 2) 32 128 *)
  0x3d80a016;       (* arm_STR Q22 X0 (Immediate_Offset (word 640)) *)
  0x4fa1d95a;       (* arm_SQRDMULH_VEC Q26 Q10 (Q1 :> LANE_S 3) 32 128 *)
  0x3d80900f;       (* arm_STR Q15 X0 (Immediate_Offset (word 576)) *)
  0x4fa0d109;       (* arm_SQRDMULH_VEC Q9 Q8 (Q0 :> LANE_S 1) 32 128 *)
  0x4f80810c;       (* arm_MUL_VEC Q12 Q8 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f4350;       (* arm_MLS_VEC Q16 Q26 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa1d36a;       (* arm_SQRDMULH_VEC Q10 Q27 (Q1 :> LANE_S 1) 32 128 *)
  0x6ebeb5cf;       (* arm_SQRDMULH_VEC Q15 Q14 Q30 32 128 *)
  0x4eb38616;       (* arm_ADD_VEC Q22 Q16 Q19 32 128 *)
  0x6eb38613;       (* arm_SUB_VEC Q19 Q16 Q19 32 128 *)
  0x6f9f412c;       (* arm_MLS_VEC Q12 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb486c8;       (* arm_ADD_VEC Q8 Q22 Q20 32 128 *)
  0x6eb486da;       (* arm_SUB_VEC Q26 Q22 Q20 32 128 *)
  0x4f81837b;       (* arm_MUL_VEC Q27 Q27 (Q1 :> LANE_S 0) 32 128 *)
  0x6ebeb571;       (* arm_SQRDMULH_VEC Q17 Q11 Q30 32 128 *)
  0x6f9f415b;       (* arm_MLS_VEC Q27 Q10 (Q31 :> LANE_S 0) 32 128 *)
  0x4ebd9d74;       (* arm_MUL_VEC Q20 Q11 Q29 32 128 *)
  0x6ebeb716;       (* arm_SQRDMULH_VEC Q22 Q24 Q30 32 128 *)
  0x6f9f4234;       (* arm_MLS_VEC Q20 Q17 (Q31 :> LANE_S 0) 32 128 *)
  0x4ebd9dce;       (* arm_MUL_VEC Q14 Q14 Q29 32 128 *)
  0x6ebeb6f0;       (* arm_SQRDMULH_VEC Q16 Q23 Q30 32 128 *)
  0x3d801014;       (* arm_STR Q20 X0 (Immediate_Offset (word 64)) *)
  0x4fa0d2ab;       (* arm_SQRDMULH_VEC Q11 Q21 (Q0 :> LANE_S 1) 32 128 *)
  0x4fa0db94;       (* arm_SQRDMULH_VEC Q20 Q28 (Q0 :> LANE_S 3) 32 128 *)
  0x4ebd9ef1;       (* arm_MUL_VEC Q17 Q23 Q29 32 128 *)
  0x4f808b97;       (* arm_MUL_VEC Q23 Q28 (Q0 :> LANE_S 2) 32 128 *)
  0x6f9f4211;       (* arm_MLS_VEC Q17 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x4f8082aa;       (* arm_MUL_VEC Q10 Q21 (Q0 :> LANE_S 0) 32 128 *)
  0x3d80d00c;       (* arm_STR Q12 X0 (Immediate_Offset (word 832)) *)
  0x6f9f42d9;       (* arm_MLS_VEC Q25 Q22 (Q31 :> LANE_S 0) 32 128 *)
  0x3c810411;       (* arm_STR Q17 X0 (Postimmediate_Offset (word 16)) *)
  0x3dc0b011;       (* arm_LDR Q17 X0 (Immediate_Offset (word 704)) *)
  0x6f9f41ee;       (* arm_MLS_VEC Q14 Q15 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc0800c;       (* arm_LDR Q12 X0 (Immediate_Offset (word 512)) *)
  0x4fa0d1b0;       (* arm_SQRDMULH_VEC Q16 Q13 (Q0 :> LANE_S 1) 32 128 *)
  0x3d804c19;       (* arm_STR Q25 X0 (Immediate_Offset (word 304)) *)
  0x4f8081bc;       (* arm_MUL_VEC Q28 Q13 (Q0 :> LANE_S 0) 32 128 *)
  0x3dc0900d;       (* arm_LDR Q13 X0 (Immediate_Offset (word 576)) *)
  0x3d805c0e;       (* arm_STR Q14 X0 (Immediate_Offset (word 368)) *)
  0x4f81824e;       (* arm_MUL_VEC Q14 Q18 (Q1 :> LANE_S 0) 32 128 *)
  0x6f9f421c;       (* arm_MLS_VEC Q28 Q16 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc03015;       (* arm_LDR Q21 X0 (Immediate_Offset (word 192)) *)
  0x6f9f416a;       (* arm_MLS_VEC Q10 Q11 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4297;       (* arm_MLS_VEC Q23 Q20 (Q31 :> LANE_S 0) 32 128 *)
  0x3d807c1c;       (* arm_STR Q28 X0 (Immediate_Offset (word 496)) *)
  0x3dc0c00b;       (* arm_LDR Q11 X0 (Immediate_Offset (word 768)) *)
  0x4fa1d25c;       (* arm_SQRDMULH_VEC Q28 Q18 (Q1 :> LANE_S 1) 32 128 *)
  0x3d80dc0a;       (* arm_STR Q10 X0 (Immediate_Offset (word 880)) *)
  0x4f808a70;       (* arm_MUL_VEC Q16 Q19 (Q0 :> LANE_S 2) 32 128 *)
  0x4fa0da73;       (* arm_SQRDMULH_VEC Q19 Q19 (Q0 :> LANE_S 3) 32 128 *)
  0x4fa0d34a;       (* arm_SQRDMULH_VEC Q10 Q26 (Q0 :> LANE_S 1) 32 128 *)
  0x4ead8592;       (* arm_ADD_VEC Q18 Q12 Q13 32 128 *)
  0x6ead858c;       (* arm_SUB_VEC Q12 Q12 Q13 32 128 *)
  0x6f9f4270;       (* arm_MLS_VEC Q16 Q19 (Q31 :> LANE_S 0) 32 128 *)
  0x3dc0a009;       (* arm_LDR Q9 X0 (Immediate_Offset (word 640)) *)
  0x3dc0e014;       (* arm_LDR Q20 X0 (Immediate_Offset (word 896)) *)
  0x4ebb86f8;       (* arm_ADD_VEC Q24 Q23 Q27 32 128 *)
  0x6ebb86f9;       (* arm_SUB_VEC Q25 Q23 Q27 32 128 *)
  0x4f808353;       (* arm_MUL_VEC Q19 Q26 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f438e;       (* arm_MLS_VEC Q14 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb1852d;       (* arm_ADD_VEC Q13 Q9 Q17 32 128 *)
  0x6ead865c;       (* arm_SUB_VEC Q28 Q18 Q13 32 128 *)
  0x6f9f4153;       (* arm_MLS_VEC Q19 Q10 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa0d337;       (* arm_SQRDMULH_VEC Q23 Q25 (Q0 :> LANE_S 1) 32 128 *)
  0x4f80832f;       (* arm_MUL_VEC Q15 Q25 (Q0 :> LANE_S 0) 32 128 *)
  0x3d80ac13;       (* arm_STR Q19 X0 (Immediate_Offset (word 688)) *)
  0x3dc02013;       (* arm_LDR Q19 X0 (Immediate_Offset (word 128)) *)
  0x6ebeb516;       (* arm_SQRDMULH_VEC Q22 Q8 Q30 32 128 *)
  0x6f9f42ef;       (* arm_MLS_VEC Q15 Q23 (Q31 :> LANE_S 0) 32 128 *)
  0x4eae861a;       (* arm_ADD_VEC Q26 Q16 Q14 32 128 *)
  0x4ebd9d0a;       (* arm_MUL_VEC Q10 Q8 Q29 32 128 *)
  0x4ead8648;       (* arm_ADD_VEC Q8 Q18 Q13 32 128 *)
  0x6ebeb74d;       (* arm_SQRDMULH_VEC Q13 Q26 Q30 32 128 *)
  0x3d80bc0f;       (* arm_STR Q15 X0 (Immediate_Offset (word 752)) *)
  0x6eb18532;       (* arm_SUB_VEC Q18 Q9 Q17 32 128 *)
  0x4ebd9f5b;       (* arm_MUL_VEC Q27 Q26 Q29 32 128 *)
  0x4fa5d997;       (* arm_SQRDMULH_VEC Q23 Q12 (Q5 :> LANE_S 3) 32 128 *)
  0x6f9f41bb;       (* arm_MLS_VEC Q27 Q13 (Q31 :> LANE_S 0) 32 128 *)
  0x4f868259;       (* arm_MUL_VEC Q25 Q18 (Q6 :> LANE_S 0) 32 128 *)
  0x4fa6d24d;       (* arm_SQRDMULH_VEC Q13 Q18 (Q6 :> LANE_S 1) 32 128 *)
  0x3d806c1b;       (* arm_STR Q27 X0 (Immediate_Offset (word 432)) *)
  0x6eb5867b;       (* arm_SUB_VEC Q27 Q19 Q21 32 128 *)
  0x4eb58675;       (* arm_ADD_VEC Q21 Q19 Q21 32 128 *)
  0x4f858992;       (* arm_MUL_VEC Q18 Q12 (Q5 :> LANE_S 2) 32 128 *)
  0x6eae8609;       (* arm_SUB_VEC Q9 Q16 Q14 32 128 *)
  0x4ebd9f1a;       (* arm_MUL_VEC Q26 Q24 Q29 32 128 *)
  0x3dc0f00c;       (* arm_LDR Q12 X0 (Immediate_Offset (word 960)) *)
  0x6f9f41b9;       (* arm_MLS_VEC Q25 Q13 (Q31 :> LANE_S 0) 32 128 *)
  0x6eac8690;       (* arm_SUB_VEC Q16 Q20 Q12 32 128 *)
  0x6ebeb711;       (* arm_SQRDMULH_VEC Q17 Q24 Q30 32 128 *)
  0x4f87820d;       (* arm_MUL_VEC Q13 Q16 (Q7 :> LANE_S 0) 32 128 *)
  0x6f9f42f2;       (* arm_MLS_VEC Q18 Q23 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f423a;       (* arm_MLS_VEC Q26 Q17 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa0d131;       (* arm_SQRDMULH_VEC Q17 Q9 (Q0 :> LANE_S 1) 32 128 *)
  0x4fa7d218;       (* arm_SQRDMULH_VEC Q24 Q16 (Q7 :> LANE_S 1) 32 128 *)
  0x3dc0d010;       (* arm_LDR Q16 X0 (Immediate_Offset (word 832)) *)
  0x3d803c1a;       (* arm_STR Q26 X0 (Immediate_Offset (word 240)) *)
  0x6eb9864f;       (* arm_SUB_VEC Q15 Q18 Q25 32 128 *)
  0x4f808137;       (* arm_MUL_VEC Q23 Q9 (Q0 :> LANE_S 0) 32 128 *)
  0x3dc06013;       (* arm_LDR Q19 X0 (Immediate_Offset (word 384)) *)
  0x3dc0700e;       (* arm_LDR Q14 X0 (Immediate_Offset (word 448)) *)
  0x4fa2d9e9;       (* arm_SQRDMULH_VEC Q9 Q15 (Q2 :> LANE_S 3) 32 128 *)
  0x4eac8694;       (* arm_ADD_VEC Q20 Q20 Q12 32 128 *)
  0x4eb0856c;       (* arm_ADD_VEC Q12 Q11 Q16 32 128 *)
  0x4f8289fa;       (* arm_MUL_VEC Q26 Q15 (Q2 :> LANE_S 2) 32 128 *)
  0x6eb08570;       (* arm_SUB_VEC Q16 Q11 Q16 32 128 *)
  0x6eb4858b;       (* arm_SUB_VEC Q11 Q12 Q20 32 128 *)
  0x6f9f4237;       (* arm_MLS_VEC Q23 Q17 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb48594;       (* arm_ADD_VEC Q20 Q12 Q20 32 128 *)
  0x6eae866c;       (* arm_SUB_VEC Q12 Q19 Q14 32 128 *)
  0x4f848371;       (* arm_MUL_VEC Q17 Q27 (Q4 :> LANE_S 0) 32 128 *)
  0x6f9f42ca;       (* arm_MLS_VEC Q10 Q22 (Q31 :> LANE_S 0) 32 128 *)
  0x4eae8676;       (* arm_ADD_VEC Q22 Q19 Q14 32 128 *)
  0x3dc0100e;       (* arm_LDR Q14 X0 (Immediate_Offset (word 64)) *)
  0x3d80ec17;       (* arm_STR Q23 X0 (Immediate_Offset (word 944)) *)
  0x4fa4d377;       (* arm_SQRDMULH_VEC Q23 Q27 (Q4 :> LANE_S 1) 32 128 *)
  0x3dc04013;       (* arm_LDR Q19 X0 (Immediate_Offset (word 256)) *)
  0x3dc0500f;       (* arm_LDR Q15 X0 (Immediate_Offset (word 320)) *)
  0x6f9f413a;       (* arm_MLS_VEC Q26 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x3d802c0a;       (* arm_STR Q10 X0 (Immediate_Offset (word 176)) *)
  0x4fa3d16a;       (* arm_SQRDMULH_VEC Q10 Q11 (Q3 :> LANE_S 1) 32 128 *)
  0x6eb4851b;       (* arm_SUB_VEC Q27 Q8 Q20 32 128 *)
  0x6f9f430d;       (* arm_MLS_VEC Q13 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb48508;       (* arm_ADD_VEC Q8 Q8 Q20 32 128 *)
  0x6eaf8674;       (* arm_SUB_VEC Q20 Q19 Q15 32 128 *)
  0x4fa6da09;       (* arm_SQRDMULH_VEC Q9 Q16 (Q6 :> LANE_S 3) 32 128 *)
  0x4eaf8673;       (* arm_ADD_VEC Q19 Q19 Q15 32 128 *)
  0x3dc0000f;       (* arm_LDR Q15 X0 (Immediate_Offset (word 0)) *)
  0x4f848a98;       (* arm_MUL_VEC Q24 Q20 (Q4 :> LANE_S 2) 32 128 *)
  0x6f9f42f1;       (* arm_MLS_VEC Q17 Q23 (Q31 :> LANE_S 0) 32 128 *)
  0x4eae85f7;       (* arm_ADD_VEC Q23 Q15 Q14 32 128 *)
  0x6eae85ee;       (* arm_SUB_VEC Q14 Q15 Q14 32 128 *)
  0x4f83816f;       (* arm_MUL_VEC Q15 Q11 (Q3 :> LANE_S 0) 32 128 *)
  0x6eb586eb;       (* arm_SUB_VEC Q11 Q23 Q21 32 128 *)
  0x4f868a10;       (* arm_MUL_VEC Q16 Q16 (Q6 :> LANE_S 2) 32 128 *)
  0x4eb586f7;       (* arm_ADD_VEC Q23 Q23 Q21 32 128 *)
  0x4eb98655;       (* arm_ADD_VEC Q21 Q18 Q25 32 128 *)
  0x4fa4da99;       (* arm_SQRDMULH_VEC Q25 Q20 (Q4 :> LANE_S 3) 32 128 *)
  0x4fa5d192;       (* arm_SQRDMULH_VEC Q18 Q12 (Q5 :> LANE_S 1) 32 128 *)
  0x4fa3d9d4;       (* arm_SQRDMULH_VEC Q20 Q14 (Q3 :> LANE_S 3) 32 128 *)
  0x4f85818c;       (* arm_MUL_VEC Q12 Q12 (Q5 :> LANE_S 0) 32 128 *)
  0x6f9f4130;       (* arm_MLS_VEC Q16 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f424c;       (* arm_MLS_VEC Q12 Q18 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4338;       (* arm_MLS_VEC Q24 Q25 (Q31 :> LANE_S 0) 32 128 *)
  0x6ead8619;       (* arm_SUB_VEC Q25 Q16 Q13 32 128 *)
  0x4ead8610;       (* arm_ADD_VEC Q16 Q16 Q13 32 128 *)
  0x4f828b8d;       (* arm_MUL_VEC Q13 Q28 (Q2 :> LANE_S 2) 32 128 *)
  0x4fa3d329;       (* arm_SQRDMULH_VEC Q9 Q25 (Q3 :> LANE_S 1) 32 128 *)
  0x4f838332;       (* arm_MUL_VEC Q18 Q25 (Q3 :> LANE_S 0) 32 128 *)
  0x4fa2db99;       (* arm_SQRDMULH_VEC Q25 Q28 (Q2 :> LANE_S 3) 32 128 *)
  0x6f9f4132;       (* arm_MLS_VEC Q18 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f414f;       (* arm_MLS_VEC Q15 Q10 (Q31 :> LANE_S 0) 32 128 *)
  0x6eac8709;       (* arm_SUB_VEC Q9 Q24 Q12 32 128 *)
  0x4f8389dc;       (* arm_MUL_VEC Q28 Q14 (Q3 :> LANE_S 2) 32 128 *)
  0x4eac870c;       (* arm_ADD_VEC Q12 Q24 Q12 32 128 *)
  0x6f9f429c;       (* arm_MLS_VEC Q28 Q20 (Q31 :> LANE_S 0) 32 128 *)
  0x4eb28754;       (* arm_ADD_VEC Q20 Q26 Q18 32 128 *)
  0x4eb68678;       (* arm_ADD_VEC Q24 Q19 Q22 32 128 *)
  0x6f9f432d;       (* arm_MLS_VEC Q13 Q25 (Q31 :> LANE_S 0) 32 128 *)
  0x6eb28752;       (* arm_SUB_VEC Q18 Q26 Q18 32 128 *)
  0x4fa1d97a;       (* arm_SQRDMULH_VEC Q26 Q11 (Q1 :> LANE_S 3) 32 128 *)
  0x4eb886f9;       (* arm_ADD_VEC Q25 Q23 Q24 32 128 *)
  0x4f81896e;       (* arm_MUL_VEC Q14 Q11 (Q1 :> LANE_S 2) 32 128 *)
  0x6eb1878a;       (* arm_SUB_VEC Q10 Q28 Q17 32 128 *)
  0x4eb18791;       (* arm_ADD_VEC Q17 Q28 Q17 32 128 *)
  0x6eb886fc;       (* arm_SUB_VEC Q28 Q23 Q24 32 128 *)
  0x4fa2d12b;       (* arm_SQRDMULH_VEC Q11 Q9 (Q2 :> LANE_S 1) 32 128 *)
  0x6eb68676;       (* arm_SUB_VEC Q22 Q19 Q22 32 128 *)
  0x6eac8638;       (* arm_SUB_VEC Q24 Q17 Q12 32 128 *)
  0x6f9f434e;       (* arm_MLS_VEC Q14 Q26 (Q31 :> LANE_S 0) 32 128 *)
  0x4eac8631;       (* arm_ADD_VEC Q17 Q17 Q12 32 128 *)
  0x4fa2d2cc;       (* arm_SQRDMULH_VEC Q12 Q22 (Q2 :> LANE_S 1) 32 128 *)
  0x6eaf85b7;       (* arm_SUB_VEC Q23 Q13 Q15 32 128 *)
  0x4eaf85ba;       (* arm_ADD_VEC Q26 Q13 Q15 32 128 *)
  0x4f828133;       (* arm_MUL_VEC Q19 Q9 (Q2 :> LANE_S 0) 32 128 *)
  0x4fa1d2e9;       (* arm_SQRDMULH_VEC Q9 Q23 (Q1 :> LANE_S 1) 32 128 *)
  0x4f8182ef;       (* arm_MUL_VEC Q15 Q23 (Q1 :> LANE_S 0) 32 128 *)
  0x6f9f4173;       (* arm_MLS_VEC Q19 Q11 (Q31 :> LANE_S 0) 32 128 *)
  0x6ea8872d;       (* arm_SUB_VEC Q13 Q25 Q8 32 128 *)
  0x6f9f412f;       (* arm_MLS_VEC Q15 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x4ea88737;       (* arm_ADD_VEC Q23 Q25 Q8 32 128 *)
  0x4fa0db08;       (* arm_SQRDMULH_VEC Q8 Q24 (Q0 :> LANE_S 3) 32 128 *)
  0x4f8282d9;       (* arm_MUL_VEC Q25 Q22 (Q2 :> LANE_S 0) 32 128 *)
  0xf1000484;       (* arm_SUBS X4 X4 (rvalue (word 1)) *)
  0xb5ffe4e4;       (* arm_CBNZ X4 (word 2096284) *)
  0x4f808b16;       (* arm_MUL_VEC Q22 Q24 (Q0 :> LANE_S 2) 32 128 *)
  0x6ebeb6e9;       (* arm_SQRDMULH_VEC Q9 Q23 Q30 32 128 *)
  0x6f9f4199;       (* arm_MLS_VEC Q25 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x4ebd9ef7;       (* arm_MUL_VEC Q23 Q23 Q29 32 128 *)
  0x6f9f4137;       (* arm_MLS_VEC Q23 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4116;       (* arm_MLS_VEC Q22 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa1d94b;       (* arm_SQRDMULH_VEC Q11 Q10 (Q1 :> LANE_S 3) 32 128 *)
  0x6eb985c9;       (* arm_SUB_VEC Q9 Q14 Q25 32 128 *)
  0x3c810417;       (* arm_STR Q23 X0 (Postimmediate_Offset (word 16)) *)
  0x4f818957;       (* arm_MUL_VEC Q23 Q10 (Q1 :> LANE_S 2) 32 128 *)
  0x4fa0d938;       (* arm_SQRDMULH_VEC Q24 Q9 (Q0 :> LANE_S 3) 32 128 *)
  0x6f9f4177;       (* arm_MLS_VEC Q23 Q11 (Q31 :> LANE_S 0) 32 128 *)
  0x4f808929;       (* arm_MUL_VEC Q9 Q9 (Q0 :> LANE_S 2) 32 128 *)
  0x6f9f4309;       (* arm_MLS_VEC Q9 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x6eb386f8;       (* arm_SUB_VEC Q24 Q23 Q19 32 128 *)
  0x4eb386f3;       (* arm_ADD_VEC Q19 Q23 Q19 32 128 *)
  0x4f808b88;       (* arm_MUL_VEC Q8 Q28 (Q0 :> LANE_S 2) 32 128 *)
  0x4eb985d7;       (* arm_ADD_VEC Q23 Q14 Q25 32 128 *)
  0x4f8081ab;       (* arm_MUL_VEC Q11 Q13 (Q0 :> LANE_S 0) 32 128 *)
  0x6eb086b9;       (* arm_SUB_VEC Q25 Q21 Q16 32 128 *)
  0x6eaf852a;       (* arm_SUB_VEC Q10 Q9 Q15 32 128 *)
  0x4eaf852f;       (* arm_ADD_VEC Q15 Q9 Q15 32 128 *)
  0x4eb086b0;       (* arm_ADD_VEC Q16 Q21 Q16 32 128 *)
  0x4fa0db9c;       (* arm_SQRDMULH_VEC Q28 Q28 (Q0 :> LANE_S 3) 32 128 *)
  0x4eba86e9;       (* arm_ADD_VEC Q9 Q23 Q26 32 128 *)
  0x4eb0862e;       (* arm_ADD_VEC Q14 Q17 Q16 32 128 *)
  0x4fa0d1b5;       (* arm_SQRDMULH_VEC Q21 Q13 (Q0 :> LANE_S 1) 32 128 *)
  0x6eb0862d;       (* arm_SUB_VEC Q13 Q17 Q16 32 128 *)
  0x4ebd9dd0;       (* arm_MUL_VEC Q16 Q14 Q29 32 128 *)
  0x6eba86ec;       (* arm_SUB_VEC Q12 Q23 Q26 32 128 *)
  0x4f8081b1;       (* arm_MUL_VEC Q17 Q13 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f4388;       (* arm_MLS_VEC Q8 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x6ebeb5dc;       (* arm_SQRDMULH_VEC Q28 Q14 Q30 32 128 *)
  0x6eb4866e;       (* arm_SUB_VEC Q14 Q19 Q20 32 128 *)
  0x4eb48674;       (* arm_ADD_VEC Q20 Q19 Q20 32 128 *)
  0x4fa0d1b3;       (* arm_SQRDMULH_VEC Q19 Q13 (Q0 :> LANE_S 1) 32 128 *)
  0x4fa1d37a;       (* arm_SQRDMULH_VEC Q26 Q27 (Q1 :> LANE_S 1) 32 128 *)
  0x6f9f4390;       (* arm_MLS_VEC Q16 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa0d19c;       (* arm_SQRDMULH_VEC Q28 Q12 (Q0 :> LANE_S 1) 32 128 *)
  0x4f81837b;       (* arm_MUL_VEC Q27 Q27 (Q1 :> LANE_S 0) 32 128 *)
  0x3d800c10;       (* arm_STR Q16 X0 (Immediate_Offset (word 48)) *)
  0x4f80818c;       (* arm_MUL_VEC Q12 Q12 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f438c;       (* arm_MLS_VEC Q12 Q28 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f435b;       (* arm_MLS_VEC Q27 Q26 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa1d33a;       (* arm_SQRDMULH_VEC Q26 Q25 (Q1 :> LANE_S 1) 32 128 *)
  0x3d809c0c;       (* arm_STR Q12 X0 (Immediate_Offset (word 624)) *)
  0x4fa0d1cc;       (* arm_SQRDMULH_VEC Q12 Q14 (Q0 :> LANE_S 1) 32 128 *)
  0x6ebb850d;       (* arm_SUB_VEC Q13 Q8 Q27 32 128 *)
  0x4ebb851b;       (* arm_ADD_VEC Q27 Q8 Q27 32 128 *)
  0x4f8081d0;       (* arm_MUL_VEC Q16 Q14 (Q0 :> LANE_S 0) 32 128 *)
  0x4ebd9e88;       (* arm_MUL_VEC Q8 Q20 Q29 32 128 *)
  0x6f9f4190;       (* arm_MLS_VEC Q16 Q12 (Q31 :> LANE_S 0) 32 128 *)
  0x4f81824c;       (* arm_MUL_VEC Q12 Q18 (Q1 :> LANE_S 0) 32 128 *)
  0x6ebeb68e;       (* arm_SQRDMULH_VEC Q14 Q20 Q30 32 128 *)
  0x3d80ac10;       (* arm_STR Q16 X0 (Immediate_Offset (word 688)) *)
  0x4fa1d254;       (* arm_SQRDMULH_VEC Q20 Q18 (Q1 :> LANE_S 1) 32 128 *)
  0x4f818339;       (* arm_MUL_VEC Q25 Q25 (Q1 :> LANE_S 0) 32 128 *)
  0x6f9f4359;       (* arm_MLS_VEC Q25 Q26 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f4271;       (* arm_MLS_VEC Q17 Q19 (Q31 :> LANE_S 0) 32 128 *)
  0x4ebd9d32;       (* arm_MUL_VEC Q18 Q9 Q29 32 128 *)
  0x4eb986dc;       (* arm_ADD_VEC Q28 Q22 Q25 32 128 *)
  0x6ebeb529;       (* arm_SQRDMULH_VEC Q9 Q9 Q30 32 128 *)
  0x6eb986d7;       (* arm_SUB_VEC Q23 Q22 Q25 32 128 *)
  0x3d808c11;       (* arm_STR Q17 X0 (Immediate_Offset (word 560)) *)
  0x6f9f42ab;       (* arm_MLS_VEC Q11 Q21 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f41c8;       (* arm_MLS_VEC Q8 Q14 (Q31 :> LANE_S 0) 32 128 *)
  0x6ebeb795;       (* arm_SQRDMULH_VEC Q21 Q28 Q30 32 128 *)
  0x3d807c0b;       (* arm_STR Q11 X0 (Immediate_Offset (word 496)) *)
  0x4ebd9f91;       (* arm_MUL_VEC Q17 Q28 Q29 32 128 *)
  0x3d802c08;       (* arm_STR Q8 X0 (Immediate_Offset (word 176)) *)
  0x4f80815c;       (* arm_MUL_VEC Q28 Q10 (Q0 :> LANE_S 0) 32 128 *)
  0x6f9f42b1;       (* arm_MLS_VEC Q17 Q21 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa0d155;       (* arm_SQRDMULH_VEC Q21 Q10 (Q0 :> LANE_S 1) 32 128 *)
  0x4ebd9de8;       (* arm_MUL_VEC Q8 Q15 Q29 32 128 *)
  0x3d804c11;       (* arm_STR Q17 X0 (Immediate_Offset (word 304)) *)
  0x6ebeb5ef;       (* arm_SQRDMULH_VEC Q15 Q15 Q30 32 128 *)
  0x4f808b0a;       (* arm_MUL_VEC Q10 Q24 (Q0 :> LANE_S 2) 32 128 *)
  0x4fa0db18;       (* arm_SQRDMULH_VEC Q24 Q24 (Q0 :> LANE_S 3) 32 128 *)
  0x6f9f428c;       (* arm_MLS_VEC Q12 Q20 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f41e8;       (* arm_MLS_VEC Q8 Q15 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f430a;       (* arm_MLS_VEC Q10 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x6ebeb778;       (* arm_SQRDMULH_VEC Q24 Q27 Q30 32 128 *)
  0x3d805c08;       (* arm_STR Q8 X0 (Immediate_Offset (word 368)) *)
  0x4f8081ae;       (* arm_MUL_VEC Q14 Q13 (Q0 :> LANE_S 0) 32 128 *)
  0x6eac8550;       (* arm_SUB_VEC Q16 Q10 Q12 32 128 *)
  0x4fa0d1b1;       (* arm_SQRDMULH_VEC Q17 Q13 (Q0 :> LANE_S 1) 32 128 *)
  0x4eac854a;       (* arm_ADD_VEC Q10 Q10 Q12 32 128 *)
  0x4ebd9f6d;       (* arm_MUL_VEC Q13 Q27 Q29 32 128 *)
  0x6ebeb554;       (* arm_SQRDMULH_VEC Q20 Q10 Q30 32 128 *)
  0x6f9f422e;       (* arm_MLS_VEC Q14 Q17 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f430d;       (* arm_MLS_VEC Q13 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x4fa0d2f8;       (* arm_SQRDMULH_VEC Q24 Q23 (Q0 :> LANE_S 1) 32 128 *)
  0x3d80bc0e;       (* arm_STR Q14 X0 (Immediate_Offset (word 752)) *)
  0x4fa0d208;       (* arm_SQRDMULH_VEC Q8 Q16 (Q0 :> LANE_S 1) 32 128 *)
  0x3d803c0d;       (* arm_STR Q13 X0 (Immediate_Offset (word 240)) *)
  0x6f9f4132;       (* arm_MLS_VEC Q18 Q9 (Q31 :> LANE_S 0) 32 128 *)
  0x4f8082e9;       (* arm_MUL_VEC Q9 Q23 (Q0 :> LANE_S 0) 32 128 *)
  0x4f80820e;       (* arm_MUL_VEC Q14 Q16 (Q0 :> LANE_S 0) 32 128 *)
  0x3d801c12;       (* arm_STR Q18 X0 (Immediate_Offset (word 112)) *)
  0x4ebd9d5b;       (* arm_MUL_VEC Q27 Q10 Q29 32 128 *)
  0x6f9f42bc;       (* arm_MLS_VEC Q28 Q21 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f410e;       (* arm_MLS_VEC Q14 Q8 (Q31 :> LANE_S 0) 32 128 *)
  0x6f9f429b;       (* arm_MLS_VEC Q27 Q20 (Q31 :> LANE_S 0) 32 128 *)
  0x3d80dc1c;       (* arm_STR Q28 X0 (Immediate_Offset (word 880)) *)
  0x6f9f4309;       (* arm_MLS_VEC Q9 Q24 (Q31 :> LANE_S 0) 32 128 *)
  0x3d80ec0e;       (* arm_STR Q14 X0 (Immediate_Offset (word 944)) *)
  0x3d806c1b;       (* arm_STR Q27 X0 (Immediate_Offset (word 432)) *)
  0x3d80cc09;       (* arm_STR Q9 X0 (Immediate_Offset (word 816)) *)
  0x6d4027e8;       (* arm_LDP D8 D9 SP (Immediate_Offset (iword (&0))) *)
  0x6d412fea;       (* arm_LDP D10 D11 SP (Immediate_Offset (iword (&16))) *)
  0x6d4237ec;       (* arm_LDP D12 D13 SP (Immediate_Offset (iword (&32))) *)
  0x6d433fee;       (* arm_LDP D14 D15 SP (Immediate_Offset (iword (&48))) *)
  0x910103ff;       (* arm_ADD SP SP (rvalue (word 64)) *)
  0xd65f03c0        (* arm_RET X30 *)
];;
(*** BYTECODE END ***)

let MLDSA_INTT_EXEC = ARM_MK_EXEC_RULE mldsa_intt_mc;;

let LENGTH_MLDSA_INTT_MC =
  REWRITE_CONV[mldsa_intt_mc] `LENGTH mldsa_intt_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let MLDSA_INTT_PREAMBLE_LENGTH = new_definition
  `MLDSA_INTT_PREAMBLE_LENGTH = 20`;;

let MLDSA_INTT_POSTAMBLE_LENGTH = new_definition
  `MLDSA_INTT_POSTAMBLE_LENGTH = 24`;;

let MLDSA_INTT_CORE_START = new_definition
  `MLDSA_INTT_CORE_START = MLDSA_INTT_PREAMBLE_LENGTH`;;

let MLDSA_INTT_CORE_END = new_definition
  `MLDSA_INTT_CORE_END = LENGTH mldsa_intt_mc - MLDSA_INTT_POSTAMBLE_LENGTH`;;

let LENGTH_INTT_ZETAS_LAYER78 =
  REWRITE_CONV[intt_zetas_layer78] `LENGTH intt_zetas_layer78`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let LENGTH_INTT_ZETAS_LAYER123456 =
  REWRITE_CONV[intt_zetas_layer123456] `LENGTH intt_zetas_layer123456`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

let LENGTH_SIMPLIFY_CONV =
  REWRITE_CONV[LENGTH_MLDSA_INTT_MC;
              LENGTH_INTT_ZETAS_LAYER78; LENGTH_INTT_ZETAS_LAYER123456;
              MLDSA_INTT_CORE_START; MLDSA_INTT_CORE_END;
              MLDSA_INTT_PREAMBLE_LENGTH; MLDSA_INTT_POSTAMBLE_LENGTH] THENC
  NUM_REDUCE_CONV THENC REWRITE_CONV [ADD_0];;

(* ------------------------------------------------------------------------- *)
(* Correctness proof.                                                        *)
(* ------------------------------------------------------------------------- *)

let MLDSA_INTT_CORRECT = prove
 (`!a z_78 z_123456 (zetas_78:int32 list) (zetas_123456:int32 list) x pc.
      ALL (nonoverlapping (a,1024))
          [(word pc,LENGTH mldsa_intt_mc);
           (z_78,LENGTH intt_zetas_layer78 * 4);
           (z_123456,LENGTH intt_zetas_layer123456 * 4)]
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_intt_mc /\
                read PC s = word (pc + MLDSA_INTT_CORE_START) /\
                C_ARGUMENTS [a; z_78; z_123456] s /\
                wordlist_from_memory(z_78,LENGTH intt_zetas_layer78) s = zetas_78 /\
                wordlist_from_memory(z_123456,LENGTH intt_zetas_layer123456) s = zetas_123456 /\
                !i. i < 256
                    ==> read(memory :> bytes32(word_add a (word(4 * i)))) s =
                        x i)
           (\s. read PC s = word(pc + MLDSA_INTT_CORE_END) /\
                (zetas_78 = MAP iword intt_zetas_layer78 /\
                 zetas_123456 = MAP iword intt_zetas_layer123456 /\
                 (!i. i < 256 ==> abs(ival(x i)) <= &8380416)
                 ==> !i. i < 256
                         ==> let zi =
                        read(memory :> bytes32(word_add a (word(4 * i)))) s in
                        (ival zi == arm_mldsa_inverse_ntt (ival o x) i) (mod &8380417) /\
                        abs(ival zi) <= &8380416))
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [Q8; Q9; Q10; Q11; Q12; Q13; Q14; Q15] ,,
            MAYCHANGE [memory :> bytes(a,1024)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  MAP_EVERY X_GEN_TAC
   [`a:int64`; `z_78:int64`; `z_123456:int64`; `zetas_78:int32 list`;
    `zetas_123456:int32 list`; `x:num->int32`; `pc:num`] THEN
  REWRITE_TAC[MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI; C_ARGUMENTS;
              NONOVERLAPPING_CLAUSES; ALL] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

  (*** Globalize the assumptions on zeta constants by case splitting ***)

  ASM_CASES_TAC
   `zetas_78:int32 list = MAP iword intt_zetas_layer78 /\
    zetas_123456:int32 list = MAP iword intt_zetas_layer123456` THEN
  ASM_REWRITE_TAC[CONJ_ASSOC] THEN REWRITE_TAC[GSYM CONJ_ASSOC] THENL
   [FIRST_X_ASSUM(CONJUNCTS_THEN SUBST1_TAC);
    ARM_QUICKSIM_TAC MLDSA_INTT_EXEC
     [`read X0 s = a`; `read X1 s = z`; `read X2 s = w`;
      `read X3 s = i`; `read X4 s = i`]
     (1--2071)] THEN

  (*** Manually expand the cases in the hypotheses ***)

  CONV_TAC(RATOR_CONV(LAND_CONV(ONCE_DEPTH_CONV
   (EXPAND_CASES_CONV THENC ONCE_DEPTH_CONV NUM_MULT_CONV)))) THEN
  CONV_TAC(ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV) THEN
  REWRITE_TAC[intt_zetas_layer78; intt_zetas_layer123456] THEN
  REWRITE_TAC[MAP; CONS_11] THEN CONV_TAC(ONCE_DEPTH_CONV WORD_IWORD_CONV) THEN
  REWRITE_TAC[WORD_ADD_0] THEN ENSURES_INIT_TAC "s0" THEN

  (*** Manually restructure to match the 128-bit loads. It would be nicer
   *** if the simulation machinery did this automatically.
   ***)

  MEMORY_128_FROM_32_TAC "a" 0 64 THEN
  MEMORY_128_FROM_32_TAC "z_78" 0 96 THEN
  MEMORY_128_FROM_32_TAC "z_123456" 0 40 THEN
  MEMORY_64_FROM_32_TAC "z_123456" 0 80 THEN
  ASM_REWRITE_TAC[WORD_ADD_0] THEN CONV_TAC WORD_REDUCE_CONV THEN
  DISCARD_MATCHING_ASSUMPTIONS [`read (memory :> bytes32 a) s = x`] THEN
  REPEAT STRIP_TAC THEN

  (*** Simulate all the way to the end, in effect unrolling loops ***)
  MAP_EVERY (fun n -> ARM_STEPS_TAC MLDSA_INTT_EXEC [n] THEN
                      SIMD_SIMPLIFY_ABBREV_TAC[arm_mldsa_barmul] [])
            (1--2071) THEN
  ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN

  (*** Reverse the restructuring by splitting the 128-bit words up ***)

  REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
    CONV_RULE(SIMD_SIMPLIFY_CONV[]) o
    CONV_RULE(READ_MEMORY_SPLIT_CONV 2) o
    check (can (term_match [] `read qqq s:int128 = xxx`) o concl))) THEN
  (*** Expand and substitute in the conclusion we want to prove ***)

  DISCH_TAC THEN
  CONV_TAC(ONCE_DEPTH_CONV let_CONV) THEN REWRITE_TAC[INT_ABS_BOUNDS] THEN
  GEN_REWRITE_TAC (BINDER_CONV o RAND_CONV) [GSYM I_THM] THEN
  CONV_TAC(EXPAND_CASES_CONV THENC ONCE_DEPTH_CONV NUM_MULT_CONV) THEN
  ASM_REWRITE_TAC[I_THM; WORD_ADD_0] THEN DISCARD_STATE_TAC "s2071" THEN

  W(fun (asl,w) ->
    let lfn = PROCESS_BOUND_ASSUMPTIONS
      (CONJUNCTS(tryfind (CONV_RULE EXPAND_CASES_CONV o snd) asl))
    and asms =
      map snd (filter (is_local_definition [arm_mldsa_barmul] o concl o snd) asl) in
    let lfn' = LOCAL_CONGBOUND_RULE lfn (rev asms) in

    REPEAT(W(fun (asl,w) ->
      if length(conjuncts w) > 3 then CONJ_TAC else NO_TAC)) THEN

    W(MP_TAC o ASM_CONGBOUND_RULE lfn' o
        rand o lhand o rator o lhand o snd) THEN
   (MATCH_MP_TAC MONO_AND THEN CONJ_TAC THENL
     [MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] INT_CONG_TRANS) THEN
      CONV_TAC(ONCE_DEPTH_CONV ARM_MLDSA_INVERSE_NTT_CONV) THEN
      REWRITE_TAC[GSYM INT_REM_EQ; o_THM] THEN CONV_TAC INT_REM_DOWN_CONV THEN
      REWRITE_TAC[INT_REM_EQ] THEN
      REWRITE_TAC[REAL_INT_CONGRUENCE; INT_OF_NUM_EQ; ARITH_EQ] THEN
      REWRITE_TAC[GSYM REAL_OF_INT_CLAUSES] THEN
      CONV_TAC(RAND_CONV REAL_POLY_CONV) THEN REAL_INTEGER_TAC;
      MATCH_MP_TAC(INT_ARITH
       `l':int <= l /\ u <= u'
        ==> l <= x /\ x <= u ==> l' <= x /\ x <= u'`) THEN
      CONV_TAC INT_REDUCE_CONV])));;

(*** Subroutine form, somewhat messy elaboration of the usual wrapper ***)

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/aarch64/src/arith_native_aarch64.h *)

let MLDSA_INTT_SUBROUTINE_CORRECT = prove
 (`!a z_78 z_123456 zetas_78 zetas_123456 x pc stackpointer returnaddress.
      aligned 16 stackpointer /\
      ALLPAIRS nonoverlapping
       [(a,1024); (word_sub stackpointer (word 64),64)]
       [(word pc,LENGTH mldsa_intt_mc);
        (z_78,LENGTH intt_zetas_layer78 * 4);
        (z_123456,LENGTH intt_zetas_layer123456 * 4)] /\
      nonoverlapping (a,1024) (word_sub stackpointer (word 64),64)
      ==> ensures arm
           (\s. aligned_bytes_loaded s (word pc) mldsa_intt_mc /\
                read PC s = word pc /\
                read SP s = stackpointer /\
                read X30 s = returnaddress /\
                C_ARGUMENTS [a; z_78; z_123456] s /\
                wordlist_from_memory(z_78,LENGTH intt_zetas_layer78) s:int32 list = zetas_78 /\
                wordlist_from_memory(z_123456,LENGTH intt_zetas_layer123456) s:int32 list = zetas_123456 /\
                !i. i < 256
                    ==> read(memory :> bytes32(word_add a (word(4 * i)))) s =
                        x i)
           (\s. read PC s = returnaddress /\
                (zetas_78 = MAP iword intt_zetas_layer78 /\
                 zetas_123456 = MAP iword intt_zetas_layer123456 /\
                 (!i. i < 256 ==> abs(ival(x i)) <= &8380416)
                 ==> !i. i < 256
                         ==> let zi =
                        read(memory :> bytes32(word_add a (word(4 * i)))) s in
                        (ival zi == arm_mldsa_inverse_ntt (ival o x) i) (mod &8380417) /\
                        abs(ival zi) <= &8380416))
           (MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
            MAYCHANGE [memory :> bytes(a,1024);
                       memory :> bytes(word_sub stackpointer (word 64),64)])`,
  CONV_TAC LENGTH_SIMPLIFY_CONV THEN
  let TWEAK_CONV =
    ONCE_DEPTH_CONV let_CONV THENC
    ONCE_DEPTH_CONV WORDLIST_FROM_MEMORY_CONV THENC
    ONCE_DEPTH_CONV EXPAND_CASES_CONV THENC
    ONCE_DEPTH_CONV NUM_MULT_CONV THENC
    PURE_REWRITE_CONV [WORD_ADD_0] in
  REWRITE_TAC[fst MLDSA_INTT_EXEC] THEN
  CONV_TAC TWEAK_CONV THEN
  ARM_ADD_RETURN_STACK_TAC ~pre_post_nsteps:(5,5) MLDSA_INTT_EXEC
   (REWRITE_RULE[fst MLDSA_INTT_EXEC] (CONV_RULE TWEAK_CONV (CONV_RULE LENGTH_SIMPLIFY_CONV MLDSA_INTT_CORRECT)))
    `[D8; D9; D10; D11; D12; D13; D14; D15]` 64);;


(* ------------------------------------------------------------------------- *)
(* Constant-time and memory safety proof.                                    *)
(* ------------------------------------------------------------------------- *)
needs "s2n_bignum/arm/proofs/consttime.ml";;
needs "mldsa_native/aarch64/proofs/subroutine_signatures.ml";;

let full_spec,public_vars = mk_safety_spec
    ~keep_maychanges:false
    (assoc "mldsa_intt_arm" subroutine_signatures)
    MLDSA_INTT_SUBROUTINE_CORRECT
    MLDSA_INTT_EXEC;;

let MLDSA_INTT_SUBROUTINE_SAFE = time prove
 (`exists f_events.
       forall e a z_78 z_123456 pc stackpointer returnaddress.
           aligned 16 stackpointer /\
           ALLPAIRS nonoverlapping
           [a,1024; word_sub stackpointer (word 64),64]
           [word pc,LENGTH mldsa_intt_mc;
            z_78,LENGTH intt_zetas_layer78 * 4;
            z_123456,LENGTH intt_zetas_layer123456 * 4] /\
           nonoverlapping (a,1024) (word_sub stackpointer (word 64),64)
           ==> ensures arm
               (\s.
                    aligned_bytes_loaded s (word pc) mldsa_intt_mc /\
                    read PC s = word pc /\
                    read SP s = stackpointer /\
                    read X30 s = returnaddress /\
                    C_ARGUMENTS [a; z_78; z_123456] s /\
                    read events s = e)
               (\s.
                    read PC s = returnaddress /\
                    exists e2.
                        read events s = APPEND e2 e /\
                        e2 =
                        f_events z_78 z_123456 a pc
                        (word_sub stackpointer (word 64))
                        returnaddress /\
                        memaccess_inbounds e2
                        [a,1024; z_78,1536; z_123456,640;
                         word_sub stackpointer (word 64),64]
                        [a,1024; word_sub stackpointer (word 64),64])
               (\s s'. true)`,
  ASSERT_CONCL_TAC full_spec THEN
  PROVE_SAFETY_SPEC_TAC ~public_vars:public_vars MLDSA_INTT_EXEC);;
