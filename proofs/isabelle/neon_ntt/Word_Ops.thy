(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Word_Ops
  imports Integer_Approximation "HOL-Library.Word"
begin

chapter \<open>Models of common word operations \label{ch:word_ops}\<close>

text \<open>
In this chapter, we provide word-level models of common assembly instructions
used in modular arithmetic kernels. The names for our models are aligned with
the Armv8-A Neon instruction mnemonics. However, we emphasise that our models
operate on individual words, while the corresponding Neon operations would ---
in the spirit of Single Instruction Multiple Data (SIMD) --- apply them to
each lane of the corresponding vector.

We model fixed-width words using Isabelle's standard \emph{word library}
(\<open>HOL-Library.Word\<close>). The type \<open>'a word\<close> represents bitvectors whose length is
encoded by the type variable \<open>'a\<close> via the type class \<open>len\<close>; \<^term>\<open>LENGTH('a::len)\<close> is the
corresponding bit-width. \<^term>\<open>sint :: 'a::len word \<Rightarrow> int\<close> is the two's-complement signed
interpretation. Working at this level of generality lets us state every kernel
correctness theorem once, without committing to a specific lane width.

For each instruction --- the low-half multiplies \asminst{MUL}, \asminst{MLA},
\asminst{MLS}; the high-half multiplies \asminst{MULH} and \asminst{UMULH};
the doubling high-half multipliers \asminst{SQDMULH} and \asminst{SQRDMULH};
the multiply-accumulate \asminst{SQRDMLAH}; and the halving subtract
\asminst{SHSUB} --- we give an abstract integer specification, define the
corresponding word operation on \<open>'a::len\<close>-bit lanes, and prove that
\<open>sint\<close> (or \<open>uint\<close>) of the word operation matches the spec.\<close>

section %internal \<open>Word \<^latex>\<open>$\leftrightarrow$\<close> int interpretation\<close>

text %internal \<open>
With \<open>n = LENGTH('a)\<close>, the \emph{canonical signed range} is the integer interval
\<^latex>\<open>$\{-2^{n-1}, \dots, 2^{n-1}-1\}$\<close>, the two's-complement output range of
an \<open>n\<close>-bit signed lane. Every saturation analysis below relies on the shape
constraint that \<open>sint\<close> lands in this range.
\<close>

lemma %internal sint_in_signed_range:
  fixes w :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>-(2^(n-1)) \<le> sint w \<and> sint w < 2 ^ (n - 1)\<close>
  unfolding n_def
  using sint_range_size[of w] by (simp add: word_size)

lemma %internal sint_word_of_int_in_range:
  fixes x :: int and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a::len)\<close>
  assumes \<open>-(2^(n-1)) \<le> x\<close>
      and \<open>x < 2 ^ (n - 1)\<close>
  shows \<open>sint ((word_of_int x) :: 'a word) = x\<close>
proof -
  have \<open>sint ((word_of_int x) :: 'a word) = signed_take_bit (n - 1) x\<close>
    unfolding n_def by (rule sint_sbintrunc')
  also have \<open>\<dots> = x\<close>
    using signed_take_bit_int_eq_self[OF assms(2) assms(3)] .
  finally show ?thesis .
qed

section \<open>Low-half multiply (\<open>MUL\<close>) and multiply-accumulate (\<open>MLA\<close>, \<open>MLS\<close>)\<close>

text \<open>
\asminst{MUL} computes the low half of the product, i.e.\ the signed
reduction of \<open>a * b\<close> modulo the word size.
\asminst{MLA}/\asminst{MLS} combine that product with an accumulator.
\<close>

definition mul_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mul_word a b \<equiv> a * b\<close>

definition mla_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mla_word acc a b \<equiv> acc + a * b\<close>

definition mls_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mls_word acc a b \<equiv> acc - a * b\<close>

lemma %internal round_int_div_2pow:
  fixes z :: int and n :: nat
  assumes \<open>n \<ge> 1\<close>
  shows \<open>\<lfloor>z /\<^sub>\<rat> (2^n)\<rceil> = (z + 2^(n-1)) div 2^n\<close>
proof -
  have npos: \<open>(2::int)^n > 0\<close> by simp
  have nhalf: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using assms
    by (metis One_nat_def Suc_pred neq0_conv not_one_le_zero power_Suc)
  have \<open>z /\<^sub>\<rat> (2^n) + 1/2 = (z + 2^(n-1)) /\<^sub>\<rat> (2^n)\<close>
  proof -
    have \<open>(2^n :: int)\<^sub>\<rat> = (2 * 2^(n-1))\<close> using nhalf by simp
    thus ?thesis by (simp add: field_simps)
  qed
  hence \<open>\<lfloor>z /\<^sub>\<rat> (2^n)\<rceil> = \<lfloor>(z + 2^(n-1)) /\<^sub>\<rat> (2^n)\<rfloor>\<close>
    unfolding round_def by simp
  also have \<open>\<dots> = (z + 2^(n-1)) div 2^n\<close>
    using floor_divide_of_int_eq[of "z + 2^(n-1)" "2^n :: int"] by simp
  finally show ?thesis .
qed

lemma %internal signed_take_bit_eq_smod:
  fixes x :: int and n :: nat
  assumes \<open>n \<ge> 1\<close>
  shows \<open>signed_take_bit (n - 1) x = x mod\<^sup>\<plusminus> 2^n\<close>
proof -
  have nSuc: \<open>Suc (n - 1) = n\<close> using assms by simp
  have h1: \<open>signed_take_bit (n - 1) x = take_bit n (x + 2 ^ (n - 1)) - 2 ^ (n - 1)\<close>
    using signed_take_bit_eq_take_bit_shift[of "n-1" x] nSuc by simp
  also have \<open>\<dots> = (x + 2 ^ (n - 1)) mod 2 ^ n - 2 ^ (n - 1)\<close>
    by (simp add: take_bit_eq_mod)
  finally have h: \<open>signed_take_bit (n - 1) x = (x + 2 ^ (n - 1)) mod 2 ^ n - 2 ^ (n - 1)\<close> .
  have \<open>x mod\<^sup>\<plusminus> 2^n = x - 2^n * \<lfloor>x /\<^sub>\<rat> (2^n)\<rceil>\<close>
    unfolding mod_approx_def by simp
  also have \<open>\<dots> = x - 2^n * ((x + 2^(n-1)) div 2^n)\<close>
    using round_int_div_2pow[OF assms] by simp
  also have \<open>\<dots> = (x + 2^(n-1)) - 2^n * ((x + 2^(n-1)) div 2^n) - 2^(n-1)\<close>
    by simp
  also have \<open>\<dots> = (x + 2^(n-1)) mod 2^n - 2^(n-1)\<close>
    by (simp add: minus_div_mult_eq_mod[symmetric])
  finally have \<open>x mod\<^sup>\<plusminus> 2^n = (x + 2^(n-1)) mod 2^n - 2^(n-1)\<close> .
  thus ?thesis using h by simp
qed

lemma %internal sint_eq_signed_take_bit_self:
  fixes w :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>signed_take_bit (n - 1) (sint w) = sint w\<close>
  unfolding n_def
  using sint_range_size[of w] len_gt_0[where 'a='a]
  by (auto intro!: signed_take_bit_int_eq_self simp: word_size)

lemma %internal sint_mul_low:
  fixes a b :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (a * b) = (sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
proof -
  have \<open>sint (a * b) = signed_take_bit (n - 1) (sint a * sint b)\<close>
    unfolding n_def by (simp add: sint_word_ariths)
  also have \<open>\<dots> = (sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
    using signed_take_bit_eq_smod[of n \<open>sint a * sint b\<close>]
          len_gt_0[where 'a='a]
    unfolding n_def by simp
  finally show \<open>sint (a * b) = (sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close> .
qed

lemma %internal sint_mla:
  fixes acc a b :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (acc + a * b) = (sint acc + sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
proof -
  let ?n1 = \<open>n - 1\<close>
  have \<open>sint (acc + a * b) = signed_take_bit ?n1 (sint acc + sint (a * b))\<close>
    unfolding n_def by (rule sint_word_add)
  also have \<open>sint (a * b) = signed_take_bit ?n1 (sint a * sint b)\<close>
    unfolding n_def by (rule sint_word_mult)
  also have \<open>signed_take_bit ?n1 (sint acc + signed_take_bit ?n1 (sint a * sint b))
            = signed_take_bit ?n1 (signed_take_bit ?n1 (sint acc)
                                  + signed_take_bit ?n1 (sint a * sint b))\<close>
    using sint_eq_signed_take_bit_self[OF n_def, of acc] by simp
  also have \<open>\<dots> = signed_take_bit ?n1 (sint acc + sint a * sint b)\<close>
    by (rule signed_take_bit_add)
  also have \<open>\<dots> = (sint acc + sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
    using signed_take_bit_eq_smod[of n \<open>sint acc + sint a * sint b\<close>]
          len_gt_0[where 'a='a]
    unfolding n_def by simp
  finally show \<open>sint (acc + a * b) = (sint acc + sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close> .
qed

lemma %internal sint_mls:
  fixes acc a b :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (acc - a * b) = (sint acc - sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
proof -
  let ?n1 = \<open>n - 1\<close>
  have \<open>sint (acc - a * b) = signed_take_bit ?n1 (sint acc - sint (a * b))\<close>
    unfolding n_def by (rule sint_word_diff)
  also have \<open>sint (a * b) = signed_take_bit ?n1 (sint a * sint b)\<close>
    unfolding n_def by (rule sint_word_mult)
  also have \<open>signed_take_bit ?n1 (sint acc - signed_take_bit ?n1 (sint a * sint b))
            = signed_take_bit ?n1 (signed_take_bit ?n1 (sint acc)
                                  - signed_take_bit ?n1 (sint a * sint b))\<close>
    using sint_eq_signed_take_bit_self[OF n_def, of acc] by simp
  also have \<open>\<dots> = signed_take_bit ?n1 (sint acc - sint a * sint b)\<close>
    by (rule signed_take_bit_diff)
  also have \<open>\<dots> = (sint acc - sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
    using signed_take_bit_eq_smod[of n \<open>sint acc - sint a * sint b\<close>]
          len_gt_0[where 'a='a]
    unfolding n_def by simp
  finally show \<open>sint (acc - a * b) = (sint acc - sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close> .
qed

text \<open>The signed correctness theorems are uniform: \<^term>\<open>sint\<close> of each
operation equals the corresponding integer expression reduced by symmetric
modulo \<^term>\<open>2 ^ n\<close>. There is no precondition --- the low-half family is
unconditionally well-behaved on signed inputs.\<close>

lemma sint_mul_ops:
  fixes a b acc :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (mul_word a b) = (sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
    and \<open>sint (mla_word acc a b) = (sint acc + sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
    and \<open>sint (mls_word acc a b) = (sint acc - sint a * sint b) mod\<^sup>\<plusminus> (2 ^ n)\<close>
  unfolding mul_word_def mla_word_def mls_word_def
  by (rule sint_mul_low[OF n_def] sint_mla[OF n_def] sint_mls[OF n_def])+

lemmas %internal sint_mul_word = sint_mul_ops(1)
lemmas %internal sint_mla_word = sint_mul_ops(2)
lemmas %internal sint_mls_word = sint_mul_ops(3)

lemma sint_uint_low_mul:
  fixes a b :: \<open>'a::len word\<close>
  shows \<open>(sint a * sint b) mod 2^LENGTH('a) = (uint a * uint b) mod 2^LENGTH('a)\<close>
proof -
  have mod_eq: \<open>sint w mod 2^LENGTH('a) = uint w mod 2^LENGTH('a)\<close> for w :: \<open>'a word\<close>
    by (simp add: take_bit_eq_mod [symmetric] sint_uint take_bit_signed_take_bit)
  thus ?thesis by (metis mod_mult_cong)
qed

text \<open>By the nature of two's complement, low-half multiplication is the same
operation regardless of whether words are interpreted as signed or unsigned:
@{thm [show_question_marks=false] sint_uint_low_mul}.
There is therefore no distinction between signed and unsigned low-half multiply.\<close>

lemma uint_mul_ops:
  fixes a b acc :: \<open>'a::len word\<close>
  shows \<open>uint (mul_word a b) = (uint a * uint b) mod 2^LENGTH('a)\<close>
    and \<open>uint (mla_word acc a b) = (uint acc + uint a * uint b) mod 2^LENGTH('a)\<close>
    and \<open>uint (mls_word acc a b) = (uint acc - uint a * uint b) mod 2^LENGTH('a)\<close>
  unfolding mul_word_def mla_word_def mls_word_def
  by (simp_all add: uint_word_ariths mod_simps)

section \<open>Plain high-half multiply: \<open>MULH\<close>\<close>

text \<open>
This models \emph{signed} high multiplication (\<open>SMULH\<close> in some ISAs):
\<open>mulh_word\<close> interprets both operands via \<open>sint\<close> and returns the high \<open>n\<close> bits
of the full \<open>2n\<close>-bit signed product.
With no doubling, signed-word inputs yield \<^term>\<open>\<bar>sint a * sint b\<bar> \<le> 2^(2*n-2)\<close>, so the
magnitude after dividing by \<^term>\<open>2^n :: int\<close> is at most \<^term>\<open>(2^(n-2) :: int) < 2^(n-1)\<close>: \<open>sint_mulh_word\<close>
carries no saturation precondition.

Unlike the low-half operations where signed and unsigned interpretations agree
(since taking the low \<open>n\<close> bits of \<open>a * b\<close> is the same regardless of sign
interpretation), high multiplication is \emph{not} sign-agnostic: the high half
of the product depends on whether operands are treated as signed or unsigned.
The unsigned variant \<open>UMULH\<close> is given separately below.
\<close>

definition \<open>mulh_int n a b \<equiv> (a * b) div 2^n\<close>

definition mulh_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mulh_word a b \<equiv> word_of_int (mulh_int (LENGTH('a)) (sint a) (sint b))\<close>

lemma %internal mulh_int_no_sat_lo:
  fixes a b :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>-(2^(n-1)) \<le> mulh_int n (sint a) (sint b)\<close>
proof -
  let ?n = n
  let ?H = \<open>2 ^ (?n - 1) :: int\<close>
  let ?R = \<open>2 ^ ?n :: int\<close>
  have npos: \<open>?n \<ge> 1\<close> using len_gt_0[where 'a='a] n_def by linarith
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases ?n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have ra1: \<open>- ?H \<le> sint a\<close> and ra2: \<open>sint a < ?H\<close>
    using sint_in_signed_range[OF n_def, of a] by auto
  have rb1: \<open>- ?H \<le> sint b\<close> and rb2: \<open>sint b < ?H\<close>
    using sint_in_signed_range[OF n_def, of b] by auto
  have abs_a: \<open>\<bar>sint a\<bar> \<le> ?H\<close> using ra1 ra2 by linarith
  have abs_b: \<open>\<bar>sint b\<bar> \<le> ?H\<close> using rb1 rb2 by linarith
  have prod_bound: \<open>\<bar>sint a * sint b\<bar> \<le> ?H * ?H\<close>
  proof -
    have \<open>\<bar>sint a * sint b\<bar> = \<bar>sint a\<bar> * \<bar>sint b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> \<le> ?H * ?H\<close> using abs_a abs_b by (simp add: mult_mono)
    finally show ?thesis .
  qed
  have prod_lo: \<open>- (?H * ?H) \<le> sint a * sint b\<close> using prod_bound by linarith
  have step_lo: \<open>?R * (- ?H) \<le> sint a * sint b\<close>
  proof -
    have \<open>?R * (- ?H) = - (2 * (?H * ?H))\<close> using R_eq by (simp add: algebra_simps)
    also have \<open>\<dots> \<le> - (?H * ?H)\<close> using Hpos by (simp add: mult_left_mono)
    also have \<open>\<dots> \<le> sint a * sint b\<close> using prod_lo .
    finally show ?thesis .
  qed
  have div_lo: \<open>- ?H \<le> (sint a * sint b) div ?R\<close>
  proof -
    have h: \<open>(?R * (- ?H)) div ?R = - ?H\<close>
      using Rpos nonzero_mult_div_cancel_left[of \<open>?R\<close> \<open>- ?H\<close>] by simp
    have \<open>(?R * (- ?H)) div ?R \<le> (sint a * sint b) div ?R\<close>
      using step_lo Rpos zdiv_mono1 by blast
    thus ?thesis using h by simp
  qed
  show ?thesis unfolding mulh_int_def using div_lo .
qed

lemma %internal mulh_int_no_sat_hi:
  fixes a b :: \<open>'a::len word\<close> and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>mulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
proof -
  let ?n = n
  let ?H = \<open>2 ^ (?n - 1) :: int\<close>
  let ?R = \<open>2 ^ ?n :: int\<close>
  have npos: \<open>?n \<ge> 1\<close> using len_gt_0[where 'a='a] n_def by linarith
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases ?n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have ra1: \<open>- ?H \<le> sint a\<close> and ra2: \<open>sint a < ?H\<close>
    using sint_in_signed_range[OF n_def, of a] by auto
  have rb1: \<open>- ?H \<le> sint b\<close> and rb2: \<open>sint b < ?H\<close>
    using sint_in_signed_range[OF n_def, of b] by auto
  have abs_a: \<open>\<bar>sint a\<bar> \<le> ?H\<close> using ra1 ra2 by linarith
  have abs_b: \<open>\<bar>sint b\<bar> \<le> ?H\<close> using rb1 rb2 by linarith
  have prod_bound: \<open>sint a * sint b \<le> ?H * ?H\<close>
  proof -
    have \<open>sint a * sint b \<le> \<bar>sint a * sint b\<bar>\<close> by simp
    also have \<open>\<bar>sint a * sint b\<bar> = \<bar>sint a\<bar> * \<bar>sint b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> \<le> ?H * ?H\<close> using abs_a abs_b by (simp add: mult_mono)
    finally show ?thesis .
  qed
  have prod_lt: \<open>sint a * sint b < ?H * ?R\<close>
  proof -
    have \<open>?H * ?R = 2 * (?H * ?H)\<close> using R_eq by (simp add: algebra_simps)
    moreover have \<open>?H * ?H < 2 * (?H * ?H)\<close> using Hpos by simp
    ultimately show ?thesis using prod_bound by linarith
  qed
  have div_hi: \<open>(sint a * sint b) div ?R < ?H\<close>
  proof (rule ccontr)
    assume \<open>\<not> (sint a * sint b) div ?R < ?H\<close>
    hence H_le: \<open>?H \<le> (sint a * sint b) div ?R\<close> by simp
    have \<open>?H * ?R \<le> (sint a * sint b) div ?R * ?R\<close>
      using H_le Rpos by (intro mult_right_mono) auto
    also have \<open>(sint a * sint b) div ?R * ?R \<le> sint a * sint b\<close>
      using Rpos
      by (metis mult.commute mult_div_mod_eq pos_mod_sign le_add_same_cancel1)
    finally have \<open>?H * ?R \<le> sint a * sint b\<close> .
    thus False using prod_lt by simp
  qed
  show ?thesis unfolding mulh_int_def using div_hi .
qed

text \<open>The signed product of two \<open>n\<close>-bit operands has magnitude at most
\<^term>\<open>2^(2*n-2)\<close>, so its top \<open>n\<close> bits never leave the signed range and the
specification holds unconditionally:\<close>

lemma sint_mulh_word:
  fixes a b :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (mulh_word a b) = mulh_int n (sint a) (sint b)\<close>
  unfolding mulh_word_def n_def
  by (rule sint_word_of_int_in_range[OF refl mulh_int_no_sat_lo[OF refl] mulh_int_no_sat_hi[OF refl]])

subsection \<open>Unsigned high-half multiply: \<open>UMULH\<close>\<close>

text \<open>
The unsigned variant interprets both operands via \<open>uint\<close> instead of \<open>sint\<close>.
The integer-level formula is the same as \<open>mulh_int\<close>; only the word-level
wrapper differs.
\<close>

definition umulh_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>umulh_word a b \<equiv> word_of_int (mulh_int (LENGTH('a)) (uint a) (uint b))\<close>

lemma uint_umulh_word:
  shows \<open>uint (umulh_word a b :: 'a::len word) = (uint a * uint b) div 2^LENGTH('a)\<close>
proof -
  let ?n = \<open>LENGTH('a)\<close>
  have bound: \<open>uint a * uint b div 2^?n < 2^?n\<close>
  proof -
    have au: \<open>uint a < 2^?n\<close> using uint_range_size[of a] by (simp add: word_size)
    have bu: \<open>uint b < 2^?n\<close> using uint_range_size[of b] by (simp add: word_size)
    have pos: \<open>(0::int) < 2^?n\<close> by simp
    have prod: \<open>uint a * uint b < 2^?n * 2^?n\<close>
      using au bu uint_ge_0[of a] uint_ge_0[of b]
      by (meson mult_strict_mono' order_le_less_trans)
    have \<open>uint a * uint b \<le> 2^?n * 2^?n - 1\<close> using prod by linarith
    hence \<open>uint a * uint b div 2^?n \<le> (2^?n * 2^?n - 1) div 2^?n\<close>
      using pos by (intro zdiv_mono1) auto
    also have \<open>((2::int)^?n * 2^?n - 1) div 2^?n < 2^?n\<close>
    proof -
      have eq: \<open>((2::int)^?n * 2^?n - 1) div 2^?n = 2^?n - 1\<close>
      proof -
        have decomp: \<open>(2::int)^?n * 2^?n - 1 = (2^?n - 1) * 2^?n + (2^?n - 1)\<close>
          by (simp add: algebra_simps)
        have r: \<open>(2^?n - 1) div 2^?n = (0::int)\<close>
          using pos by (intro div_pos_pos_trivial) linarith+
        show ?thesis by (simp add: decomp pos r)
      qed
      show ?thesis using eq pos by linarith
    qed
    finally show ?thesis .
  qed
  have nonneg: \<open>0 \<le> uint a * uint b div 2^?n\<close>
    by (simp add: div_int_pos_iff uint_ge_0)
  show ?thesis
    unfolding umulh_word_def mulh_int_def
    by (simp add: uint_word_of_int take_bit_eq_mod mod_pos_pos_trivial[OF nonneg] bound)
qed

section \<open>High-half doubling multiplies: \<open>SQDMULH\<close> and \<open>SQRDMULH\<close>\<close>

text \<open>
Next we model saturating high multiplications. To extract the high part, we use
Isabelle's \<open>div\<close> operation on \<open>int\<close>. We note that \<open>div\<close> on \<open>int\<close> is a floor division, 
matching the arithmetic right shift used by signed two's-complement high-half instructions 
like ARM Neon \<open>SQDMULH\<close> and PowerPC \<open>vmhraddshs\<close>. This is \emph{not} C's \<open>/\<close> on \<open>int32_t\<close>, which
truncates toward zero and would diverge on negative dividends.
\<close>

value \<open>(-1::int) div 2 = -1\<close>  \<comment> \<open>Sanity check\<close>

definition \<open>sqdmulh_int n a b \<equiv> (2 * a * b) div 2^n\<close>

text \<open>
The rounding variant \<open>SQRDMULH\<close> uses Isabelle's \<^term>\<open>round x = \<lfloor>x + 1/2\<rfloor>\<close> — round-to-nearest
with ties broken toward \<open>+\<infinity>\<close>.
\<close>

definition \<open>sqrdmulh_int n a b \<equiv> \<lfloor>(2 * a * b) /\<^sub>\<rat> 2^n\<rceil>\<close>

text \<open>
The word-level operations saturate: when both operands equal the extreme
negative \<open>-2\<^sup>n\<^sup>-\<^sup>1\<close>, the doubled product overflows the signed range and the
hardware clamps to \<open>2\<^sup>n\<^sup>-\<^sup>1 - 1\<close>. This is the only input pair that triggers
saturation. We capture this with a signed saturation function that clamps an
integer to the \<open>n\<close>-bit signed range.
\<close>

definition signed_saturate :: \<open>int \<Rightarrow> 'a::len word\<close> where
  \<open>signed_saturate x \<equiv>
     word_of_int (max (-(2^(LENGTH('a)-1))) (min x (2^(LENGTH('a)-1) - 1)))\<close>

definition sqdmulh_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>sqdmulh_word a b \<equiv> signed_saturate (sqdmulh_int (LENGTH('a)) (sint a) (sint b))\<close>

definition sqrdmulh_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>sqrdmulh_word a b \<equiv> signed_saturate (sqrdmulh_int (LENGTH('a)) (sint a) (sint b))\<close>




text %internal \<open>
The saturation analyses come in two flavours: \emph{two-sided},
\<open>sqdmulh_int_no_sat\<close> / \<open>sqrdmulh_int_no_sat\<close>, requiring strict bounds on both
operands; and \emph{one-sided}, \<open>sqdmulh_int_no_sat_one_side\<close>, relaxing the
first operand to \<^term>\<open>\<bar>a\<bar> \<le> 2^(n-1)\<close> — the form needed by the Barrett kernel. The
helper \<open>sqrdmulh_int_alt\<close> rewrites the rounding division as
\<^term>\<open>(2 * a * b + 2^(n-1)) div 2^n\<close>, on which both \<open>sqrdmulh\<close>-style analyses are based.
With the saturation case excluded — i.e.\ the inputs are not both at the
extreme negative \<^term>\<open>-(2^(n-1))\<close> — \<open>sint\<close> of the word operation matches the abstract
integer spec; this is captured by \<open>sint_sqdmulh_word\<close> and \<open>sint_sqrdmulh_word\<close>
below.
\<close>

lemma %internal round_div_int:
  fixes x N :: int
  assumes Npos: \<open>N > 0\<close> and Neven: \<open>even N\<close>
  shows \<open>\<lfloor>x /\<^sub>\<rat> N\<rceil> = (x + N div 2) div N\<close>
proof -
  have h: \<open>2 * (N div 2) = N\<close> using Neven by simp
  have step1: \<open>\<lfloor>x /\<^sub>\<rat> N\<rceil> = \<lfloor>x /\<^sub>\<rat> N + 1/2\<rfloor>\<close> unfolding round_def by simp
  have step2: \<open>x /\<^sub>\<rat> N + 1/2 = (2 * x + N) /\<^sub>\<rat> (2 * N)\<close>
    using Npos by (simp add: field_simps)
  have step3: \<open>\<lfloor>(2 * x + N) /\<^sub>\<rat> (2 * N)\<rfloor> = (2 * x + N) div (2 * N)\<close>
    using floor_divide_of_int_eq[where ?'a=rat] by metis
  have step5: \<open>\<And>y. 2 * y div (2 * N) = y div N\<close>
    by (simp add: div_mult2_eq[symmetric])
  have step6: \<open>(2 * (x + N div 2)) div (2 * N) = (x + N div 2) div N\<close>
    using step5[of \<open>x + N div 2\<close>] .
  have step7: \<open>2 * x + N = 2 * (x + N div 2)\<close> using h by (simp add: distrib_left)
  have step8: \<open>(2 * x + N) div (2 * N) = (x + N div 2) div N\<close>
    using step6 step7 by argo
  show ?thesis
    using step1 step2 step3 step8 by simp
qed

lemma %internal sqrdmulh_int_alt:
  fixes a b :: int and n :: nat
  assumes npos: \<open>n > 0\<close>
  shows \<open>sqrdmulh_int n a b = (2 * a * b + 2^(n-1)) div 2^n\<close>
proof -
  have R_eq: \<open>(2::int) ^ n = 2 * 2 ^ (n-1)\<close> using npos by (cases n) auto
  have Reven: \<open>even ((2 :: int) ^ n)\<close> using npos by simp
  have Rpos: \<open>(2 :: int) ^ n > 0\<close> by simp
  have hd: \<open>((2::int)^n) div 2 = (2::int)^(n-1)\<close>
    using R_eq by simp
  have \<open>sqrdmulh_int n a b = \<lfloor>(2 * a * b) /\<^sub>\<rat> (2^n)\<rceil>\<close>
    unfolding sqrdmulh_int_def ..
  also have \<open>\<dots> = (2 * a * b + 2^n div 2) div 2^n\<close>
    using round_div_int[OF Rpos Reven] .
  also have \<open>\<dots> = (2 * a * b + 2^(n-1)) div 2^n\<close>
    using hd by simp
  finally show ?thesis .
qed

lemma %internal sqdmulh_int_no_sat:
  fixes a b :: int and n :: nat
  assumes npos: \<open>n > 0\<close>
      and absa: \<open>\<bar>a\<bar> < 2^(n-1)\<close> and absb: \<open>\<bar>b\<bar> < 2^(n-1)\<close>
  shows \<open>-(2^(n-1)) \<le> sqdmulh_int n a b\<close> and \<open>sqdmulh_int n a b < 2^(n-1)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  let ?R = \<open>2 ^ n :: int\<close>
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have abs_prod: \<open>\<bar>a * b\<bar> < ?H * ?H\<close>
  proof -
    have \<open>\<bar>a * b\<bar> = \<bar>a\<bar> * \<bar>b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> < ?H * ?H\<close>
      using absa absb Hpos
      by (simp add: abs_ge_zero mult_strict_mono)
    finally show ?thesis .
  qed
  have prod_abs2: \<open>\<bar>2 * a * b\<bar> < ?H * ?R\<close>
    using abs_prod R_eq by (simp add: abs_mult algebra_simps)
  show \<open>-(2^(n-1)) \<le> sqdmulh_int n a b\<close>
  proof -
    have \<open>- (?H * ?R) \<le> 2 * a * b\<close> using prod_abs2 by linarith
    hence step: \<open>(- ?H) * ?R \<le> 2 * a * b\<close> by (simp add: algebra_simps)
    have h: \<open>((- ?H) * ?R) div ?R = - ?H\<close>
      using Rpos nonzero_mult_div_cancel_right[of ?R \<open>- ?H\<close>] by simp
    have \<open>((- ?H) * ?R) div ?R \<le> (2 * a * b) div ?R\<close>
      using step Rpos zdiv_mono1 by blast
    thus ?thesis unfolding sqdmulh_int_def using h by simp
  qed
  show \<open>sqdmulh_int n a b < 2^(n-1)\<close>
  proof (rule ccontr)
    assume \<open>\<not> sqdmulh_int n a b < ?H\<close>
    hence \<open>?H \<le> (2 * a * b) div ?R\<close> unfolding sqdmulh_int_def by simp
    hence \<open>?H * ?R \<le> ((2 * a * b) div ?R) * ?R\<close>
      using Rpos by (intro mult_right_mono) auto
    moreover have \<open>((2 * a * b) div ?R) * ?R \<le> 2 * a * b\<close>
      using Rpos
      by (metis mult.commute mult_div_mod_eq pos_mod_sign le_add_same_cancel1)
    ultimately have \<open>?H * ?R \<le> 2 * a * b\<close> by linarith
    thus False using prod_abs2 by linarith
  qed
qed

lemma %internal sqdmulh_int_no_sat_one_side:
  fixes a b :: int and n :: nat
  assumes npos: \<open>n > 0\<close>
      and absa: \<open>\<bar>a\<bar> \<le> 2^(n-1)\<close> and absb: \<open>\<bar>b\<bar> < 2^(n-1)\<close>
  shows \<open>-(2^(n-1)) \<le> sqdmulh_int n a b\<close> and \<open>sqdmulh_int n a b < 2^(n-1)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  let ?R = \<open>2 ^ n :: int\<close>
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have bH: \<open>\<bar>b\<bar> \<le> ?H - 1\<close> using absb by linarith
  have abs_prod: \<open>\<bar>a * b\<bar> \<le> ?H * (?H - 1)\<close>
  proof -
    have \<open>\<bar>a * b\<bar> = \<bar>a\<bar> * \<bar>b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> \<le> ?H * (?H - 1)\<close>
      using absa bH Hpos by (intro mult_mono) auto
    finally show ?thesis .
  qed
  have prod_abs2: \<open>\<bar>2 * a * b\<bar> \<le> 2 * ?H * (?H - 1)\<close>
    using abs_prod by (simp add: abs_mult algebra_simps)
  have lt_HR: \<open>2 * ?H * (?H - 1) < ?H * ?R\<close>
  proof -
    have \<open>2 * ?H * (?H - 1) = 2 * ?H * ?H - 2 * ?H\<close>
      by (simp add: algebra_simps)
    also have \<open>\<dots> < 2 * ?H * ?H\<close> using Hpos by linarith
    also have \<open>2 * ?H * ?H = ?H * ?R\<close> using R_eq by (simp add: algebra_simps)
    finally show ?thesis .
  qed
  show \<open>-(2^(n-1)) \<le> sqdmulh_int n a b\<close>
  proof -
    have \<open>- (?H * ?R) < 2 * a * b\<close> using prod_abs2 lt_HR by linarith
    hence step: \<open>(- ?H) * ?R \<le> 2 * a * b\<close> by (simp add: algebra_simps)
    have h: \<open>((- ?H) * ?R) div ?R = - ?H\<close>
      using Rpos nonzero_mult_div_cancel_right[of ?R \<open>- ?H\<close>] by simp
    have \<open>((- ?H) * ?R) div ?R \<le> (2 * a * b) div ?R\<close>
      using step Rpos zdiv_mono1 by blast
    thus ?thesis unfolding sqdmulh_int_def using h by simp
  qed
  show \<open>sqdmulh_int n a b < 2^(n-1)\<close>
  proof (rule ccontr)
    assume \<open>\<not> sqdmulh_int n a b < ?H\<close>
    hence \<open>?H \<le> (2 * a * b) div ?R\<close> unfolding sqdmulh_int_def by simp
    hence \<open>?H * ?R \<le> ((2 * a * b) div ?R) * ?R\<close>
      using Rpos by (intro mult_right_mono) auto
    moreover have \<open>((2 * a * b) div ?R) * ?R \<le> 2 * a * b\<close>
      using Rpos
      by (metis mult.commute mult_div_mod_eq pos_mod_sign le_add_same_cancel1)
    ultimately have \<open>?H * ?R \<le> 2 * a * b\<close> by linarith
    thus False using prod_abs2 lt_HR by linarith
  qed
qed

text %internal \<open>The rounding variant follows the same template, with the rounding offset
absorbed into the \<^term>\<open>(+) (2^(n-1) :: int)\<close> shift of @{thm [source] sqrdmulh_int_alt}.\<close>

lemma %internal sqrdmulh_int_no_sat:
  fixes a b :: int and n :: nat
  assumes npos: \<open>n > 0\<close>
      and absa: \<open>\<bar>a\<bar> < 2^(n-1)\<close> and absb: \<open>\<bar>b\<bar> < 2^(n-1)\<close>
  shows \<open>-(2^(n-1)) \<le> sqrdmulh_int n a b\<close> and \<open>sqrdmulh_int n a b < 2^(n-1)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  let ?R = \<open>2 ^ n :: int\<close>
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have aH: \<open>\<bar>a\<bar> \<le> ?H - 1\<close> using absa by linarith
  have bH: \<open>\<bar>b\<bar> \<le> ?H - 1\<close> using absb by linarith
  have abs_prod: \<open>\<bar>a * b\<bar> \<le> (?H - 1) * (?H - 1)\<close>
  proof -
    have \<open>\<bar>a * b\<bar> = \<bar>a\<bar> * \<bar>b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> \<le> (?H - 1) * (?H - 1)\<close>
      using aH bH by (intro mult_mono) auto
    finally show ?thesis .
  qed
  have prod_abs2: \<open>\<bar>2 * a * b\<bar> \<le> 2 * (?H - 1) * (?H - 1)\<close>
    using abs_prod by (simp add: abs_mult algebra_simps)
  have lt_HR: \<open>2 * (?H - 1) * (?H - 1) < ?H * ?R\<close>
  proof -
    have \<open>2 * (?H - 1) * (?H - 1) = 2 * ?H * ?H - 4 * ?H + 2\<close>
      by (simp add: algebra_simps power2_eq_square)
    also have \<open>\<dots> < 2 * ?H * ?H\<close> using Hpos by linarith
    also have \<open>2 * ?H * ?H = ?H * ?R\<close> using R_eq by (simp add: algebra_simps)
    finally show ?thesis .
  qed
  have alt: \<open>sqrdmulh_int n a b = (2 * a * b + ?H) div ?R\<close>
    using sqrdmulh_int_alt[OF npos] .
  have div_neg: \<open>(- (?H * ?R)) div ?R = - ?H\<close>
  proof -
    have \<open>- (?H * ?R) = (- ?H) * ?R\<close> by simp
    thus ?thesis using Rpos
      by (metis nonzero_mult_div_cancel_right order.strict_iff_not)
  qed
  have div_aux: \<open>(?H * ?R - 1) div ?R = ?H - 1\<close>
  proof -
    have eq: \<open>?H * ?R - 1 = (?H - 1) * ?R + (?R - 1)\<close>
      by (simp add: algebra_simps)
    have \<open>((?H - 1) * ?R + (?R - 1)) div ?R = (?H - 1) + (?R - 1) div ?R\<close>
      using Rpos by simp
    also have \<open>\<dots> = ?H - 1\<close> using Rpos by simp
    finally have eq2: \<open>((?H - 1) * ?R + (?R - 1)) div ?R = ?H - 1\<close> .
    show ?thesis using eq eq2 by argo
  qed
  show \<open>-(2^(n-1)) \<le> sqrdmulh_int n a b\<close>
  proof -
    have lo: \<open>- (?H * ?R) \<le> 2 * a * b\<close>
      using prod_abs2 lt_HR by linarith
    hence step: \<open>- (?H * ?R) \<le> 2 * a * b + ?H\<close> using Hpos by linarith
    have \<open>(- (?H * ?R)) div ?R \<le> (2 * a * b + ?H) div ?R\<close>
      using step Rpos zdiv_mono1 by blast
    thus ?thesis using div_neg alt by simp
  qed
  show \<open>sqrdmulh_int n a b < 2^(n-1)\<close>
  proof -
    have \<open>2 * a * b \<le> 2 * (?H - 1) * (?H - 1)\<close> using prod_abs2 by linarith
    moreover have \<open>2 * (?H - 1) * (?H - 1) + ?H < ?H * ?R\<close>
    proof -
      have \<open>2 * (?H - 1) * (?H - 1) = 2 * ?H * ?H - 4 * ?H + 2\<close>
        by (simp add: algebra_simps power2_eq_square)
      also have \<open>\<dots> + ?H < 2 * ?H * ?H\<close> using Hpos by linarith
      also have \<open>2 * ?H * ?H = ?H * ?R\<close> using R_eq by (simp add: algebra_simps)
      finally show ?thesis by linarith
    qed
    ultimately have hi: \<open>2 * a * b + ?H \<le> ?H * ?R - 1\<close> by linarith
    have \<open>(2 * a * b + ?H) div ?R \<le> (?H * ?R - 1) div ?R\<close>
      using hi Rpos zdiv_mono1 by force
    also have \<open>\<dots> = ?H - 1\<close> using div_aux .
    also have \<open>\<dots> < ?H\<close> by simp
    finally show ?thesis using alt by simp
  qed
qed

text %internal \<open>The one-sided variant for \<open>SQRDMULH\<close>, mirroring
\<open>sqdmulh_int_no_sat_one_side\<close>: relax the bound on the first operand to
\<^term>\<open>\<bar>a\<bar> \<le> 2^(n-1)\<close>, keep the strict bound on the second.
Used by the rounding doubling-Montgomery kernel where \<open>k\<close> is the
output of a low-half multiply.\<close>

lemma %internal sqrdmulh_int_no_sat_one_side:
  fixes a b :: int and n :: nat
  assumes npos: \<open>n > 0\<close>
      and absa: \<open>\<bar>a\<bar> \<le> 2^(n-1)\<close> and absb: \<open>\<bar>b\<bar> < 2^(n-1)\<close>
  shows \<open>-(2^(n-1)) \<le> sqrdmulh_int n a b\<close> and \<open>sqrdmulh_int n a b < 2^(n-1)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  let ?R = \<open>2 ^ n :: int\<close>
  have R_eq: \<open>?R = 2 * ?H\<close>
    using npos by (cases n) auto
  have Hpos: \<open>?H > 0\<close> by simp
  have Rpos: \<open>?R > 0\<close> by simp
  have bH: \<open>\<bar>b\<bar> \<le> ?H - 1\<close> using absb by linarith
  have abs_prod: \<open>\<bar>a * b\<bar> \<le> ?H * (?H - 1)\<close>
  proof -
    have \<open>\<bar>a * b\<bar> = \<bar>a\<bar> * \<bar>b\<bar>\<close> by (simp add: abs_mult)
    also have \<open>\<dots> \<le> ?H * (?H - 1)\<close>
      using absa bH Hpos by (intro mult_mono) auto
    finally show ?thesis .
  qed
  have prod_abs2: \<open>\<bar>2 * a * b\<bar> \<le> 2 * ?H * (?H - 1)\<close>
    using abs_prod by (simp add: abs_mult algebra_simps)
  have HR_eq: \<open>?H * ?R = 2 * ?H * ?H\<close>
    using R_eq by (simp add: algebra_simps)
  have lt_HR_strict: \<open>2 * ?H * (?H - 1) + ?H < ?H * ?R\<close>
  proof -
    have e1: \<open>2 * ?H * (?H - 1) + ?H = 2 * ?H * ?H - ?H\<close>
      by (simp add: algebra_simps)
    have \<open>2 * ?H * ?H - ?H < 2 * ?H * ?H\<close> using Hpos by simp
    thus ?thesis using e1 HR_eq by linarith
  qed
  have le_HR: \<open>2 * ?H * (?H - 1) \<le> ?H * ?R\<close>
    using lt_HR_strict Hpos by linarith
  have alt: \<open>sqrdmulh_int n a b = (2 * a * b + ?H) div ?R\<close>
    using sqrdmulh_int_alt[OF npos] .
  have div_neg: \<open>(- (?H * ?R)) div ?R = - ?H\<close>
  proof -
    have \<open>- (?H * ?R) = (- ?H) * ?R\<close> by simp
    thus ?thesis using Rpos
      by (metis nonzero_mult_div_cancel_right order.strict_iff_not)
  qed
  have div_aux: \<open>(?H * ?R - 1) div ?R = ?H - 1\<close>
  proof -
    have eq: \<open>?H * ?R - 1 = (?H - 1) * ?R + (?R - 1)\<close>
      by (simp add: algebra_simps)
    have \<open>((?H - 1) * ?R + (?R - 1)) div ?R = (?H - 1) + (?R - 1) div ?R\<close>
      using Rpos by simp
    also have \<open>\<dots> = ?H - 1\<close> using Rpos by simp
    finally have eq2: \<open>((?H - 1) * ?R + (?R - 1)) div ?R = ?H - 1\<close> .
    show ?thesis using eq eq2 by argo
  qed
  show \<open>-(2^(n-1)) \<le> sqrdmulh_int n a b\<close>
  proof -
    have lo: \<open>- (?H * ?R) \<le> 2 * a * b\<close>
      using prod_abs2 le_HR by linarith
    hence step: \<open>- (?H * ?R) \<le> 2 * a * b + ?H\<close> using Hpos by linarith
    have \<open>(- (?H * ?R)) div ?R \<le> (2 * a * b + ?H) div ?R\<close>
      using step Rpos zdiv_mono1 by blast
    thus ?thesis using div_neg alt by simp
  qed
  show \<open>sqrdmulh_int n a b < 2^(n-1)\<close>
  proof -
    have hi_part: \<open>2 * a * b \<le> 2 * ?H * (?H - 1)\<close> using prod_abs2 by linarith
    hence hi: \<open>2 * a * b + ?H \<le> ?H * ?R - 1\<close> using lt_HR_strict by linarith
    have \<open>(2 * a * b + ?H) div ?R \<le> (?H * ?R - 1) div ?R\<close>
      using hi Rpos zdiv_mono1 by force
    also have \<open>\<dots> = ?H - 1\<close> using div_aux .
    also have \<open>\<dots> < ?H\<close> by simp
    finally show ?thesis using alt by simp
  qed
qed

text \<open>The word-level lifts: as long as the inputs are not both at the
extreme \<open>-2\<^sup>n\<^sup>-\<^sup>1\<close> (the only saturating case), the signed-integer
specifications transfer to fixed-width word operands.\<close>

lemma sint_sqdmulh_word:
  fixes a b :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes not_extreme: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint b = -(2^(n-1)))\<close>
  shows \<open>sint (sqdmulh_word a b) = sqdmulh_int n (sint a) (sint b)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have ra: \<open>- ?H \<le> sint a\<close> \<open>sint a < ?H\<close>
    using sint_in_signed_range[OF n_def, of a] by auto
  have rb: \<open>- ?H \<le> sint b\<close> \<open>sint b < ?H\<close>
    using sint_in_signed_range[OF n_def, of b] by auto
  have abs_a: \<open>\<bar>sint a\<bar> \<le> ?H\<close> using ra by linarith
  have abs_b: \<open>\<bar>sint b\<bar> \<le> ?H\<close> using rb by linarith
  have sym: \<open>sqdmulh_int n (sint a) (sint b) = sqdmulh_int n (sint b) (sint a)\<close>
    unfolding sqdmulh_int_def by (simp add: algebra_simps)
  have lo: \<open>-(2^(n-1)) \<le> sqdmulh_int n (sint a) (sint b)\<close>
   and hi: \<open>sqdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
  proof (atomize(full), cases \<open>sint a = -(2^(n-1))\<close>)
    case True
    hence b_ne: \<open>sint b \<noteq> -(2^(n-1))\<close> using not_extreme by blast
    hence absb_strict: \<open>\<bar>sint b\<bar> < ?H\<close> using rb by linarith
    show \<open>-(2^(n-1)) \<le> sqdmulh_int n (sint a) (sint b) \<and>
          sqdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
      using sqdmulh_int_no_sat_one_side(1)[OF npos abs_a absb_strict]
            sqdmulh_int_no_sat_one_side(2)[OF npos abs_a absb_strict]
      by simp
  next
    case False
    hence absa_strict: \<open>\<bar>sint a\<bar> < ?H\<close> using ra by linarith
    show \<open>-(2^(n-1)) \<le> sqdmulh_int n (sint a) (sint b) \<and>
          sqdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
      using sqdmulh_int_no_sat_one_side(1)[OF npos abs_b absa_strict]
            sqdmulh_int_no_sat_one_side(2)[OF npos abs_b absa_strict]
            sym
      by simp
  qed
  show ?thesis
    unfolding sqdmulh_word_def signed_saturate_def n_def
    using lo[unfolded n_def] hi[unfolded n_def]
    by (simp add: sint_word_of_int_in_range)
qed

lemma sint_sqrdmulh_word:
  fixes a b :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes not_extreme: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint b = -(2^(n-1)))\<close>
  shows \<open>sint (sqrdmulh_word a b) = sqrdmulh_int n (sint a) (sint b)\<close>
proof -
  let ?H = \<open>2 ^ (n - 1) :: int\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have ra: \<open>- ?H \<le> sint a\<close> \<open>sint a < ?H\<close>
    using sint_in_signed_range[OF n_def, of a] by auto
  have rb: \<open>- ?H \<le> sint b\<close> \<open>sint b < ?H\<close>
    using sint_in_signed_range[OF n_def, of b] by auto
  have abs_a: \<open>\<bar>sint a\<bar> \<le> ?H\<close> using ra by linarith
  have abs_b: \<open>\<bar>sint b\<bar> \<le> ?H\<close> using rb by linarith
  have sym: \<open>sqrdmulh_int n (sint a) (sint b) = sqrdmulh_int n (sint b) (sint a)\<close>
    unfolding sqrdmulh_int_def by (simp add: algebra_simps)
  have lo: \<open>-(2^(n-1)) \<le> sqrdmulh_int n (sint a) (sint b)\<close>
   and hi: \<open>sqrdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
  proof (atomize(full), cases \<open>sint a = -(2^(n-1))\<close>)
    case True
    hence b_ne: \<open>sint b \<noteq> -(2^(n-1))\<close> using not_extreme by blast
    hence absb_strict: \<open>\<bar>sint b\<bar> < ?H\<close> using rb by linarith
    show \<open>-(2^(n-1)) \<le> sqrdmulh_int n (sint a) (sint b) \<and>
          sqrdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
      using sqrdmulh_int_no_sat_one_side(1)[OF npos abs_a absb_strict]
            sqrdmulh_int_no_sat_one_side(2)[OF npos abs_a absb_strict]
      by simp
  next
    case False
    hence absa_strict: \<open>\<bar>sint a\<bar> < ?H\<close> using ra by linarith
    show \<open>-(2^(n-1)) \<le> sqrdmulh_int n (sint a) (sint b) \<and>
          sqrdmulh_int n (sint a) (sint b) < 2 ^ (n - 1)\<close>
      using sqrdmulh_int_no_sat_one_side(1)[OF npos abs_b absa_strict]
            sqrdmulh_int_no_sat_one_side(2)[OF npos abs_b absa_strict]
            sym
      by simp
  qed
  show ?thesis
    unfolding sqrdmulh_word_def signed_saturate_def n_def
    using lo[unfolded n_def] hi[unfolded n_def]
    by (simp add: sint_word_of_int_in_range)
qed


section \<open>Rounding multiply-accumulate high: \<open>SQRDMLAH\<close>\<close>

text \<open>
\<open>SQRDMLAH\<close> is the rounding multiply-accumulate variant: it computes
\<^term>\<open>acc + \<lfloor>(2 * a * b) /\<^sub>\<rat> 2^n\<rceil>\<close>, fusing the high-half rounding multiplication of
\<open>SQRDMULH\<close> with an accumulator add. It is used in the doubled rounding
Montgomery kernel of \cite[Algorithm~13]{NeonNTT}, where the
final \<open>SHSUB\<close> is dropped and the correction is folded into the
multiply-accumulate.
\<close>

definition \<open>sqrdmlah_int n acc a b \<equiv> acc + sqrdmulh_int n a b\<close>

definition sqrdmlah_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>sqrdmlah_word acc a b \<equiv>
     signed_saturate (sqrdmlah_int (LENGTH('a)) (sint acc) (sint a) (sint b))\<close>

text \<open>With the integer result inside the canonical signed range,
\<open>sint\<close> of the word operation matches the integer specification.\<close>

lemma sint_sqrdmlah_word:
  fixes acc a b :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes lo: \<open>-(2^(n-1)) \<le> sqrdmlah_int n (sint acc) (sint a) (sint b)\<close>
      and hi: \<open>sqrdmlah_int n (sint acc) (sint a) (sint b) < 2 ^ (n - 1)\<close>
  shows \<open>sint (sqrdmlah_word acc a b)
           = sqrdmlah_int n (sint acc) (sint a) (sint b)\<close>
  unfolding sqrdmlah_word_def signed_saturate_def n_def
  using lo[unfolded n_def] hi[unfolded n_def]
  by (simp add: sint_word_of_int_in_range)




section \<open>Halving subtract: \<open>SHSUB\<close>\<close>

text \<open>
\<open>SHSUB\<close> absorbs a factor of two inside the Barrett-reduction kernel without losing
the high bit; with no doubling, saturation cannot occur, so the \<open>sint\<close> specification
is unconditional.
\<close>

definition \<open>shsub_int a b \<equiv> (a - b) div 2\<close>

definition shsub_word :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>shsub_word a b \<equiv> word_of_int (shsub_int (sint a) (sint b))\<close>

lemma sint_shsub_word:
  shows \<open>sint (shsub_word a b :: 'a::len word) = shsub_int (sint a) (sint b)\<close>
proof -
  define n :: nat where n_def: \<open>n = LENGTH('a)\<close>
  have ra: \<open>-(2^(n-1)) \<le> sint a \<and> sint a < 2 ^ (n - 1)\<close>
    using sint_in_signed_range[OF n_def, of a] .
  have rb: \<open>-(2^(n-1)) \<le> sint b \<and> sint b < 2 ^ (n - 1)\<close>
    using sint_in_signed_range[OF n_def, of b] .
  have lo: \<open>-(2^(n-1)) \<le> shsub_int (sint a) (sint b)\<close>
    unfolding shsub_int_def using ra rb by linarith
  have hi: \<open>shsub_int (sint a) (sint b) < 2 ^ (n - 1)\<close>
    unfolding shsub_int_def using ra rb by linarith
  show ?thesis
    unfolding shsub_word_def by (rule sint_word_of_int_in_range[OF n_def lo hi])
qed


section \<open>Rounding right shift: \<^verbatim>\<open>SRSHR\<close>\<close>

text \<open>\<^verbatim>\<open>SRSHR\<close> shifts a signed lane right by a compile-time constant \<^term>\<open>k\<close>,
rounding to nearest. We use it in refined Barrett reduction, where it follows
a \<^verbatim>\<open>SQDMULH\<close> to realise an approximation at an inflated effective radix.\<close>

definition \<open>srshr_int k x \<equiv> \<lfloor>x /\<^sub>\<rat> 2^k\<rceil>\<close>

definition srshr_word :: \<open>nat \<Rightarrow> 'a::len word \<Rightarrow> 'a word\<close> where
  \<open>srshr_word k x \<equiv> word_of_int (srshr_int k (sint x))\<close>

lemma sint_srshr_word:
  fixes x :: \<open>'a::len word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (srshr_word k x) = srshr_int k (sint x)\<close>
proof -
  have npos: \<open>n \<ge> 1\<close> unfolding n_def using len_gt_0[where 'a='a] by linarith
  have rx: \<open>-(2^(n-1)) \<le> sint x\<close> \<open>sint x < 2^(n-1)\<close>
    using sint_in_signed_range[OF n_def, of x] by auto
  have lo: \<open>-(2^(n-1)) \<le> srshr_int k (sint x)\<close>
  proof -
    define H :: int where \<open>H = 2^(n-1)\<close>
    have Hpos: \<open>H > 0\<close> unfolding H_def by simp
    have x_lo: \<open>sint x \<ge> -H\<close> using rx(1) unfolding H_def by simp
    have pow_pos: \<open>(of_int ((2::int)^k) :: rat) > 0\<close> by simp
    have pow_ge1: \<open>(of_int ((2::int)^k) :: rat) \<ge> 1\<close> by simp
    have rat_lo: \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) \<ge> - of_int H\<close>
    proof -
      have h1: \<open>(of_int (sint x) :: rat) \<ge> - of_int H\<close>
        using x_lo by (metis of_int_le_iff of_int_minus)
      have h1b: \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) \<ge> (- of_int H) / of_int ((2::int)^k)\<close>
        using h1 pow_pos by (intro divide_right_mono) auto
      have h2: \<open>(- of_int H :: rat) / of_int ((2::int)^k) \<ge> - of_int H\<close>
      proof -
        have neg: \<open>(- of_int H :: rat) \<le> 0\<close> using Hpos by simp
        have \<open>(- of_int H :: rat) = (- of_int H) * 1\<close> by simp
        also have \<open>\<dots> \<le> (- of_int H) * (1 / of_int ((2::int)^k))\<close>
          using neg pow_ge1 by (intro mult_left_mono_neg) auto
        also have \<open>\<dots> = (- of_int H) / of_int ((2::int)^k)\<close> by simp
        finally show ?thesis .
      qed
      show ?thesis using h1b h2 by linarith
    qed
    have \<open>\<lfloor>(of_int (sint x) :: rat) / of_int ((2::int)^k) + 1/2\<rfloor> \<ge> -H\<close>
      using rat_lo by linarith
    thus ?thesis unfolding srshr_int_def round_def H_def by simp
  qed
  have hi: \<open>srshr_int k (sint x) < 2^(n-1)\<close>
  proof -
    define H :: int where \<open>H = 2^(n-1)\<close>
    have Hpos: \<open>H > 0\<close> unfolding H_def by simp
    have x_hi: \<open>sint x < H\<close> using rx(2) unfolding H_def by simp
    hence x_le: \<open>sint x \<le> H - 1\<close> by linarith
    have pow_pos: \<open>(of_int ((2::int)^k) :: rat) > 0\<close> by simp
    have pow_ge1: \<open>(of_int ((2::int)^k) :: rat) \<ge> 1\<close> by simp
    have rat_hi: \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) \<le> of_int (H - 1)\<close>
    proof (cases \<open>sint x \<ge> 0\<close>)
      case True
      have h1: \<open>(of_int (sint x) :: rat) \<le> of_int (H - 1)\<close>
        using x_le by (metis of_int_le_iff)
      have nn: \<open>(of_int (sint x) :: rat) \<ge> 0\<close>
        using True by (metis of_int_0_le_iff)
      have \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) \<le> of_int (sint x)\<close>
      proof -
        have \<open>of_int (sint x) = (of_int (sint x) :: rat) * 1\<close> by simp
        also have \<open>\<dots> \<le> (of_int (sint x) :: rat) * of_int ((2::int)^k)\<close>
          using nn pow_ge1 by (intro mult_left_mono) auto
        finally show ?thesis using pow_pos by (simp add: pos_divide_le_eq)
      qed
      thus ?thesis using h1 by linarith
    next
      case False
      hence \<open>sint x < 0\<close> by simp
      hence \<open>(of_int (sint x) :: rat) < 0\<close>
        by (metis of_int_0 of_int_less_iff)
      hence \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) < 0\<close>
        using pow_pos by (simp add: divide_neg_pos)
      moreover have \<open>(of_int (H - 1) :: rat) \<ge> 0\<close> using Hpos by simp
      ultimately show ?thesis by linarith
    qed
    have \<open>\<lfloor>(of_int (sint x) :: rat) / of_int ((2::int)^k) + 1/2\<rfloor> < H\<close>
    proof -
      have \<open>(of_int (sint x) :: rat) / of_int ((2::int)^k) + 1/2 \<le> of_int (H - 1) + 1/2\<close>
        using rat_hi by linarith
      also have \<open>\<dots> < of_int H\<close> by simp
      finally show ?thesis by linarith
    qed
    thus ?thesis unfolding srshr_int_def round_def H_def by simp
  qed
  show ?thesis
    unfolding srshr_word_def by (rule sint_word_of_int_in_range[OF n_def lo hi])
qed










section \<open>Assembly-style notation for kernel definitions\<close>

text \<open>
We use simple syntax sugar around HOL \<open>let\<close> bindings to provide a shallow
embedding of symbolic assembly sequences using the instructions above:
\begin{quote}
\<open>let ASM \<laquo> MUL z a b; SQRDMULH t a halfBT; MLS r z t N \<raquo> in r\<close>
\end{quote}
desugars to nested \<open>let\<close>-bindings over the \<open>*_word\<close> operations above.
An \<open>ASM \<laquo>\<dots>\<raquo>\<close> block must sit at the tail of its enclosing \<open>let\<close>.
\<close>

(*<*)
nonterminal asm_letbinds and asm_letbind

bundle ASM_syntax
begin

syntax
  "_asm_mul"      :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"           ("MUL _ _ _")
  "_asm_mulh"     :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"           ("MULH _ _ _")
  "_asm_sqdmulh"  :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"           ("SQDMULH _ _ _")
  "_asm_sqrdmulh" :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"           ("SQRDMULH _ _ _")
  "_asm_shsub"    :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"           ("SHSUB _ _ _")
  "_asm_srshr"    :: "pttrn \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> asm_letbind"          ("SRSHR _ _ #_")
  "_asm_mla"      :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"     ("MLA _ _ _ _")
  "_asm_mls"      :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"     ("MLS _ _ _ _")
  "_asm_sqrdmlah" :: "pttrn \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> asm_letbind"     ("SQRDMLAH _ _ _ _")
  ""              :: "asm_letbind \<Rightarrow> asm_letbinds"                ("_")
  "_asm_binds"    :: "[asm_letbind, asm_letbinds] \<Rightarrow> asm_letbinds"  ("_;/ _")
  "_ASM_block"    :: "asm_letbinds \<Rightarrow> letbinds"                   ("ASM \<guillemotleft> _ / \<guillemotright>")

translations
  "_asm_mul d a b"      \<rightleftharpoons> "_bind d (CONST mul_word a b)"
  "_asm_mulh d a b"     \<rightleftharpoons> "_bind d (CONST mulh_word a b)"
  "_asm_sqdmulh d a b"  \<rightleftharpoons> "_bind d (CONST sqdmulh_word a b)"
  "_asm_sqrdmulh d a b" \<rightleftharpoons> "_bind d (CONST sqrdmulh_word a b)"
  "_asm_shsub d a b"    \<rightleftharpoons> "_bind d (CONST shsub_word a b)"
  "_asm_srshr d a k"    \<rightleftharpoons> "_bind d (CONST srshr_word k a)"
  "_asm_mla d a b c"    \<rightleftharpoons> "_bind d (CONST mla_word a b c)"
  "_asm_mls d a b c"    \<rightleftharpoons> "_bind d (CONST mls_word a b c)"
  "_asm_sqrdmlah d a b c" \<rightleftharpoons> "_bind d (CONST sqrdmlah_word a b c)"
  "_ASM_block (_asm_binds b bs)" \<rightharpoonup> "_binds b (_ASM_block bs)"
  "_ASM_block b"                 \<rightharpoonup> "b"



end

context
    includes ASM_syntax
  begin
(*>*)
text \<open>Let's look at a simple example:\<close>

definition asm_test :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>asm_test a b N \<equiv>
     let ASM \<guillemotleft>
       MUL      z a b;
       SQRDMULH t a b;
       MLS      r z t N
     \<guillemotright> in r\<close>

text \<open>\noindent This definitionally desugars to the following:\<close>

lemma asm_test_eq:
  \<open>asm_test a b N
     \<equiv> (let z = mul_word a b;
            t = sqrdmulh_word a b
        in mls_word z t N)\<close>
  unfolding asm_test_def Let_def by (rule reflexive)

(*<*)
end
(*>*)

section \<open>Conformance testing\<close>

text \<open>The instruction models above are pen-and-paper. To gain confidence
that they faithfully reflect the AArch64 ISA, the development ships a small
conformance harness under \<^verbatim>\<open>model/\<close>. Each modelled operation is exposed
through Isabelle's code extractor as a string-keyed dispatcher
\<^verbatim>\<open>model_exec MNEMONIC BITWIDTH ARG ...\<close>, exported to SML; a sibling C
program \<^verbatim>\<open>hw_exec\<close> with the same CLI executes the corresponding instruction
through inline assembly on real silicon (Neon for 8/16/32-bit lanes; scalar
\<^verbatim>\<open>SMULH\<close>/\<^verbatim>\<open>UMULH\<close> at 64 bits). A Python driver pipes identical hex inputs into
both and compares outputs bit-for-bit. The default \<^verbatim>\<open>all\<close> mode runs the 8-bit
operations exhaustively (33M cases) and one million random plus all
edge-value cases per 16/32/64-bit operation; current results are zero
divergences across roughly 50M cases.\<close>

end
