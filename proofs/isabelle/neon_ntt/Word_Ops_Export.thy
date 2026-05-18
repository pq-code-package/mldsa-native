(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Word_Ops_Export
  imports Word_Ops "HOL-Library.Code_Target_Numeral"
begin

type_synonym w8  = "8 word"
type_synonym w16 = "16 word"
type_synonym w32 = "32 word"
type_synonym w64 = "64 word"

definition mul_w8     :: "w8 \<Rightarrow> w8 \<Rightarrow> w8" where "mul_w8     = mul_word"
definition mul_w16    :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word"           where "mul_w16    = mul_word"
definition mul_w32    :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word"           where "mul_w32    = mul_word"

definition mla_w8     :: "8  word \<Rightarrow> 8  word \<Rightarrow> 8  word \<Rightarrow> 8  word"  where "mla_w8     = mla_word"
definition mla_w16    :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word \<Rightarrow> 16 word" where "mla_w16    = mla_word"
definition mla_w32    :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word \<Rightarrow> 32 word" where "mla_w32    = mla_word"

definition mls_w8     :: "8  word \<Rightarrow> 8  word \<Rightarrow> 8  word \<Rightarrow> 8  word"  where "mls_w8     = mls_word"
definition mls_w16    :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word \<Rightarrow> 16 word" where "mls_w16    = mls_word"
definition mls_w32    :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word \<Rightarrow> 32 word" where "mls_w32    = mls_word"

definition sqdmulh_w16   :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word"          where "sqdmulh_w16   = sqdmulh_word"
definition sqdmulh_w32   :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word"          where "sqdmulh_w32   = sqdmulh_word"

definition sqrdmulh_w16  :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word"          where "sqrdmulh_w16  = sqrdmulh_word"
definition sqrdmulh_w32  :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word"          where "sqrdmulh_w32  = sqrdmulh_word"

definition sqrdmlah_w16  :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word \<Rightarrow> 16 word" where "sqrdmlah_w16  = sqrdmlah_word"
definition sqrdmlah_w32  :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word \<Rightarrow> 32 word" where "sqrdmlah_w32  = sqrdmlah_word"

definition shsub_w8      :: "8  word \<Rightarrow> 8  word \<Rightarrow> 8  word"          where "shsub_w8      = shsub_word"
definition shsub_w16     :: "16 word \<Rightarrow> 16 word \<Rightarrow> 16 word"          where "shsub_w16     = shsub_word"
definition shsub_w32     :: "32 word \<Rightarrow> 32 word \<Rightarrow> 32 word"          where "shsub_w32     = shsub_word"

definition srshr_w8      :: "nat \<Rightarrow> 8  word \<Rightarrow> 8  word"               where "srshr_w8      = srshr_word"
definition srshr_w16     :: "nat \<Rightarrow> 16 word \<Rightarrow> 16 word"               where "srshr_w16     = srshr_word"
definition srshr_w32     :: "nat \<Rightarrow> 32 word \<Rightarrow> 32 word"               where "srshr_w32     = srshr_word"

definition mulh_w64      :: "64 word \<Rightarrow> 64 word \<Rightarrow> 64 word"          where "mulh_w64      = mulh_word"
definition umulh_w64     :: "64 word \<Rightarrow> 64 word \<Rightarrow> 64 word"          where "umulh_w64     = umulh_word"


definition mk8  :: "integer \<Rightarrow> 8  word" where "mk8  x = word_of_int (int_of_integer x)"
definition mk16 :: "integer \<Rightarrow> 16 word" where "mk16 x = word_of_int (int_of_integer x)"
definition mk32 :: "integer \<Rightarrow> 32 word" where "mk32 x = word_of_int (int_of_integer x)"
definition mk64 :: "integer \<Rightarrow> 64 word" where "mk64 x = word_of_int (int_of_integer x)"

definition u8  :: "8  word \<Rightarrow> integer" where "u8  w = integer_of_int (uint w)"
definition u16 :: "16 word \<Rightarrow> integer" where "u16 w = integer_of_int (uint w)"
definition u32 :: "32 word \<Rightarrow> integer" where "u32 w = integer_of_int (uint w)"
definition u64 :: "64 word \<Rightarrow> integer" where "u64 w = integer_of_int (uint w)"

fun model_exec :: "String.literal \<Rightarrow> integer \<Rightarrow> integer list \<Rightarrow> integer option" where
  \<comment> \<open>MUL\<close>
  "model_exec mn bw [a, b] =
     (if mn = STR ''MUL'' then
        (if bw =  8 then Some (u8  (mul_w8  (mk8  a) (mk8  b))) else
         if bw = 16 then Some (u16 (mul_w16 (mk16 a) (mk16 b))) else
         if bw = 32 then Some (u32 (mul_w32 (mk32 a) (mk32 b))) else None)
      else if mn = STR ''SQDMULH'' then
        (if bw = 16 then Some (u16 (sqdmulh_w16 (mk16 a) (mk16 b))) else
         if bw = 32 then Some (u32 (sqdmulh_w32 (mk32 a) (mk32 b))) else None)
      else if mn = STR ''SQRDMULH'' then
        (if bw = 16 then Some (u16 (sqrdmulh_w16 (mk16 a) (mk16 b))) else
         if bw = 32 then Some (u32 (sqrdmulh_w32 (mk32 a) (mk32 b))) else None)
      else if mn = STR ''SHSUB'' then
        (if bw =  8 then Some (u8  (shsub_w8  (mk8  a) (mk8  b))) else
         if bw = 16 then Some (u16 (shsub_w16 (mk16 a) (mk16 b))) else
         if bw = 32 then Some (u32 (shsub_w32 (mk32 a) (mk32 b))) else None)
      else if mn = STR ''SRSHR'' then
        \<comment> \<open>SRSHR k x: first arg is the shift amount k, second is the lane.\<close>
        (if bw =  8 then Some (u8  (srshr_w8  (nat (int_of_integer a)) (mk8  b))) else
         if bw = 16 then Some (u16 (srshr_w16 (nat (int_of_integer a)) (mk16 b))) else
         if bw = 32 then Some (u32 (srshr_w32 (nat (int_of_integer a)) (mk32 b))) else None)
      else if mn = STR ''MULH'' then
        (if bw = 64 then Some (u64 (mulh_w64 (mk64 a) (mk64 b))) else None)
      else if mn = STR ''UMULH'' then
        (if bw = 64 then Some (u64 (umulh_w64 (mk64 a) (mk64 b))) else None)
      else None)"
| "model_exec mn bw [a, b, c] =
     (if mn = STR ''MLA'' then
        (if bw =  8 then Some (u8  (mla_w8  (mk8  a) (mk8  b) (mk8  c))) else
         if bw = 16 then Some (u16 (mla_w16 (mk16 a) (mk16 b) (mk16 c))) else
         if bw = 32 then Some (u32 (mla_w32 (mk32 a) (mk32 b) (mk32 c))) else None)
      else if mn = STR ''MLS'' then
        (if bw =  8 then Some (u8  (mls_w8  (mk8  a) (mk8  b) (mk8  c))) else
         if bw = 16 then Some (u16 (mls_w16 (mk16 a) (mk16 b) (mk16 c))) else
         if bw = 32 then Some (u32 (mls_w32 (mk32 a) (mk32 b) (mk32 c))) else None)
      else if mn = STR ''SQRDMLAH'' then
        (if bw = 16 then Some (u16 (sqrdmlah_w16 (mk16 a) (mk16 b) (mk16 c))) else
         if bw = 32 then Some (u32 (sqrdmlah_w32 (mk32 a) (mk32 b) (mk32 c))) else None)
      else None)"
| "model_exec _ _ _ = None"


export_code model_exec
  in SML module_name Model file_prefix "model"

end
