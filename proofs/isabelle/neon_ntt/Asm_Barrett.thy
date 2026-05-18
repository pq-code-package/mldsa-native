(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Asm_Barrett
  imports Word_Ops Barrett_Montgomery
begin

unbundle %invisible ASM_syntax

chapter \<open>Neon kernels for Barrett-style modular arithmetic \label{ch:asm_barrett}\<close>

text \<open>In this chapter we analyse three Neon ASM kernels for Barrett-style
modular arithmetic and connect them to the corresponding abstract operators.
In consequence, we obtain correctness and bounds statements for the kernel
output.\<close>

section \<open>Signed Barrett multiplication\<close>

text \<open>We verify \cite[Algorithm~10, \S 3.2]{NeonNTT}: the three-instruction
\<^verbatim>\<open>MUL\<close>/\<^verbatim>\<open>SQRDMULH\<close>/\<^verbatim>\<open>MLS\<close> sequence computes
\<^term>\<open>barM\<^sup>\<plusminus>\<lbrakk>N,n,\<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a,b\<rangle>\<close> on signed lanes. The precomputed
constant \<^term>\<open>bt\<close> carries half the round-to-even magic constant (halving
is exact since round-to-even produces an even integer). The bound
\<^term>\<open>\<bar>sint b\<bar> < sint N\<close> ensures \<^term>\<open>bt\<close> avoids the extreme negative
value, excluding \<^verbatim>\<open>SQRDMULH\<close> saturation for any \<^term>\<open>a\<close>.\<close>

definition %internal \<open>barrett_mul_neon_int n N b halfBT a \<equiv>
     let R  = 2^n;
         z1 = (a * b) mod\<^sup>\<plusminus> R;
         t  = \<lfloor>2 * a * halfBT /\<^sub>\<rat> R\<rceil>;
         z2 = (z1 - t * N) mod\<^sup>\<plusminus> R
     in z2\<close>

text %internal \<open>Halving the magic constant is harmless: doubling the second operand of a
rounded high-half multiply exactly cancels the prior division by two, provided
the magic constant is even.\<close>

lemma %internal sqrdmulh_halved_eq:
  fixes a m :: int and n :: nat
  assumes \<open>even m\<close>
  shows \<open>\<lfloor>2 * a * (m div 2) /\<^sub>\<rat> 2^n\<rceil> = \<lfloor>a * m /\<^sub>\<rat> 2^n\<rceil>\<close>
  using assms by (simp add: algebra_simps)

text %internal \<open>Fed \<^term>\<open>\<lfloor>b * R /\<^sub>\<rat> N\<rceil>\<^sub>2 div 2\<close>, the kernel equals \<^term>\<open>barM\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle>\<close> modulo
the lane width. The ambient \<^term>\<open>x mod\<^sup>\<plusminus> R\<close> is identity once inputs are bounded. The
round-to-even approximation produces an even integer, so \<^term>\<open>sqrdmulh_halved_eq\<close>
applies to the magic constant \<^term>\<open>\<lfloor>b * R /\<^sub>\<rat> N\<rceil>\<^sub>2\<close>.\<close>

lemma %internal barrett_mul_neon_int_eq:
  fixes a b N :: int and n :: nat
  defines \<open>m \<equiv> \<lfloor>b * 2^n /\<^sub>\<rat> N\<rceil>\<^sub>2\<close>
  shows \<open>barrett_mul_neon_int n N b (m div 2) a
           = barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle> mod\<^sup>\<plusminus> 2^n\<close>
proof -
  have m_even: \<open>even m\<close>
    unfolding m_def round_even_def by simp
  let ?R = \<open>(2::int)^n\<close>
  let ?t = \<open>\<lfloor>\<cdot>\<rceil> (a * m /\<^sub>\<rat> ?R)\<close>
  define cc :: int where \<open>cc = \<lfloor>\<cdot>\<rceil> ((a * b) /\<^sub>\<rat> ?R)\<close>
  have \<open>barrett_mul_neon_int n N b (m div 2) a
          = ((a * b) mod\<^sup>\<plusminus> ?R - ?t * N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_mul_neon_int_def Let_def
    using sqrdmulh_halved_eq[OF m_even, of a n] by (simp add: algebra_simps)
  also have \<open>\<dots> = (a * b - N * ?t) mod\<^sup>\<plusminus> ?R\<close>
    unfolding mod_approx_def cc_def[symmetric]
    using mod_approx_shift[OF shift_compat_round, of ?R \<open>a * b - N * ?t\<close> \<open>-cc\<close>]
    by (simp add: algebra_simps mod_approx_def)
  also have \<open>\<dots> = barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle> mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_mul_signed_def Let_def m_def by simp
  finally show ?thesis .
qed

definition %internal barrett_mul_neon_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>barrett_mul_neon_word N b halfBT a \<equiv>
     let ASM \<guillemotleft>
       MUL      z1 a b;
       SQRDMULH t  a halfBT;
       MLS      r  z1 t N
     \<guillemotright> in r\<close>

text %internal \<open>Under the absolute-value bounds and the standard cryptographic precondition
on the modulus \<^term>\<open>N\<close>, the signed interpretation of the word-level kernel agrees
with the integer model.\<close>

lemma %internal sint_barrett_mul_neon_word:
  fixes N b halfBT a :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes nondeg_halfBT: \<open>\<bar>sint halfBT\<bar> < 2^(n-1)\<close>
  shows \<open>sint (barrett_mul_neon_word N b halfBT a)
           = barrett_mul_neon_int n (sint N) (sint b) (sint halfBT) (sint a)\<close>
proof -
  let ?z1 = \<open>mul_word a b\<close>
  let ?t  = \<open>sqrdmulh_word a halfBT\<close>
  let ?R  = \<open>(2::int) ^ n\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have not_extreme: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint halfBT = -(2^(n-1)))\<close>
    using nondeg_halfBT by linarith
  have z1_int: \<open>sint ?z1 = (sint a * sint b) mod\<^sup>\<plusminus> ?R\<close>
    by (rule sint_mul_word[OF n_def])
  have t_int: \<open>sint ?t = sqrdmulh_int n (sint a) (sint halfBT)\<close>
    by (rule sint_sqrdmulh_word[OF n_def not_extreme])
  have \<open>sint (barrett_mul_neon_word N b halfBT a)
          = (sint ?z1 - sint ?t * sint N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_mul_neon_word_def Let_def
    by (rule sint_mls_word[OF n_def])
  also have \<open>\<dots> = ((sint a * sint b) mod\<^sup>\<plusminus> ?R
                   - sqrdmulh_int n (sint a) (sint halfBT) * sint N) mod\<^sup>\<plusminus> ?R\<close>
    using z1_int t_int by simp
  also have \<open>\<dots> = barrett_mul_neon_int n (sint N) (sint b) (sint halfBT) (sint a)\<close>
    unfolding barrett_mul_neon_int_def Let_def sqrdmulh_int_def
    by simp
  finally show ?thesis .
qed

text %internal \<open>A small-input identity for the canonical signed residue: when \<^term>\<open>2 * \<bar>x\<bar> < R\<close>,
\<^term>\<open>x mod\<^sup>\<plusminus> R\<close> is just \<^term>\<open>x\<close>. Used to discharge the ambient \<^term>\<open>y mod\<^sup>\<plusminus> (2::int)^n\<close> in the
small-input correctness theorems below.\<close>

lemma %internal mod_approx_round_id_small:
  fixes x R :: int
  assumes \<open>0 < R\<close> and \<open>2 * \<bar>x\<bar> < R\<close>
  shows \<open>x mod\<^sup>\<plusminus> R = x\<close>
proof -
  have iR_pos: \<open>0 < R\<^sub>\<rat>\<close> using assms(1) by simp
  have \<open>\<bar>x /\<^sub>\<rat> R\<bar> < 1/2\<close>
    using assms iR_pos by (simp add: abs_divide field_simps)
  hence \<open>\<lfloor>x /\<^sub>\<rat> R\<rceil> = 0\<close>
    unfolding round_def by linarith
  thus ?thesis unfolding mod_approx_def by simp
qed

theorem barrett_mul_neon_word_correct:
  fixes N a b bt :: \<open>'a::len word\<close> and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes bt_eq: \<open>sint bt = \<lfloor>sint b * 2^n /\<^sub>\<rat> sint N\<rceil>\<^sub>2 div 2\<close>
      and N_std: \<open>StandardModulus (sint N) (n-1)\<close>
      and b_bound: \<open>\<bar>sint b\<bar>\<^sub>\<rat> < (sint N)\<^sub>\<rat>\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    MUL      z1 a b;
                    SQRDMULH t  a bt;
                    MLS      r  z1 t N
                  \<guillemotright> in r\<close>
  shows \<open>sint out = barM\<^sup>\<plusminus> \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
        \<comment> \<open>abstract description\<close>
    and \<open>sint out mod sint N = (sint a * sint b) mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar> * sint N /\<^sub>\<rat> 2^n + sint N /\<^sub>\<rat> 2\<close>
        \<comment> \<open>fine output bound\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
        \<comment> \<open>coarse output bound\<close>
proof -
  define m where \<open>m \<equiv> \<lfloor>sint b * 2^n /\<^sub>\<rat> sint N\<rceil>\<^sub>2\<close>
  have halfBT_eq: \<open>sint bt = m div 2\<close> using bt_eq unfolding m_def .

  interpret SM: StandardModulus \<open>sint N\<close> \<open>n-1\<close> by (rule N_std)
  have npos: \<open>0 < n\<close> using SM.npos by simp
  have N_lt: \<open>sint N < 2^(n-1)\<close> using SM.N_lt_R .
  have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using npos by (cases n) auto
  have N2_bound: \<open>2 * sint N < 2^n\<close> using N_lt R_eq by linarith
  have N_lt_R: \<open>sint N < 2^n\<close>
  proof -
    have \<open>(2::int)^(n-1) \<le> 2^n\<close> by (rule power_increasing) auto
    thus ?thesis using N_lt by linarith
  qed
  \<comment> \<open>Derive non-degeneracy of halfBT from b being signed-canonical\<close>
  have N_pos_int: \<open>(0::int) < sint N\<close> using SM.Npos .
  have N_pos_rat: \<open>(0::rat) < (sint N)\<^sub>\<rat>\<close>
    using N_pos_int by (metis of_int_0_less_iff)
  have b_int: \<open>\<bar>sint b\<bar> < sint N\<close>
    using b_bound by (metis of_int_abs of_int_less_iff)
  \<comment> \<open>From $|sint b| < N$ and $N < 2^{n-1}$: $value = sint b * 2^n / N$ has
      $|value| < 2^n$. Round-to-even adds at most 1 to magnitude, so $|m| \le 2^n$.
      The bad case for halfBT is $m \in \{-2^n, -2^n+1\}$ (giving $m \div 2 = -2^{n-1}$).
      We exclude this using $value > -2^n + 2$ (from $sint b \ge -N + 1$ and $2^n/N > 2$).\<close>
  have approx_err: \<open>\<bar>sint b * 2^n /\<^sub>\<rat> sint N - (\<lfloor>sint b * 2^n /\<^sub>\<rat> sint N\<rceil>\<^sub>2)\<^sub>\<rat>\<bar> \<le> 1\<close>
    using is_int_approx_round_even[unfolded is_int_approx_def, rule_format] .
  have N_lt_R: \<open>2 * sint N < 2^n\<close>
    using N_lt R_eq by linarith
  have val_gt: \<open>sint b * 2^n /\<^sub>\<rat> sint N > -((2^n)\<^sub>\<rat>) + 2\<close>
  proof -
    have b_lo: \<open>sint b \<ge> -sint N + 1\<close> using b_int by linarith
    have prod_lo: \<open>sint b * 2^n \<ge> -sint N * 2^n + 2^n\<close>
    proof -
      have \<open>sint b * 2^n \<ge> (-sint N + 1) * 2^n\<close>
        using b_lo by (intro mult_right_mono) auto
      thus ?thesis by (simp add: algebra_simps)
    qed
    have prod_lo': \<open>sint b * 2^n > -sint N * 2^n + 2 * sint N\<close>
      using prod_lo N_lt_R by linarith
    have rat_lo: \<open>(sint b * 2^n)\<^sub>\<rat> > (-sint N * 2^n + 2 * sint N)\<^sub>\<rat>\<close>
      using prod_lo' by (metis of_int_less_iff)
    have val_eq: \<open>sint b * 2^n /\<^sub>\<rat> sint N = (sint b * 2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>\<close>
      by (simp add: of_int_mult)
    have rhs_eq: \<open>(-sint N * 2^n + 2 * sint N)\<^sub>\<rat> / (sint N)\<^sub>\<rat> = -((2^n)\<^sub>\<rat>) + 2\<close>
      using N_pos_rat by (simp add: of_int_mult of_int_add of_int_minus
                                     field_simps)
    have \<open>(sint b * 2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>
            > (-sint N * 2^n + 2 * sint N)\<^sub>\<rat> / (sint N)\<^sub>\<rat>\<close>
      using rat_lo N_pos_rat by (intro divide_strict_right_mono) auto
    thus ?thesis using val_eq rhs_eq by simp
  qed
  have val_lt: \<open>sint b * 2^n /\<^sub>\<rat> sint N < (2^n)\<^sub>\<rat>\<close>
  proof -
    have b_hi: \<open>sint b < sint N\<close> using b_int by linarith
    have prod_hi: \<open>sint b * 2^n < sint N * 2^n\<close>
      using b_hi by (intro mult_strict_right_mono) auto
    hence \<open>(sint b * 2^n)\<^sub>\<rat> < (sint N * 2^n)\<^sub>\<rat>\<close> by (metis of_int_less_iff)
    hence \<open>(sint b * 2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat> < (sint N * 2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>\<close>
      using N_pos_rat by (intro divide_strict_right_mono) auto
    also have \<open>(sint N * 2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat> = (2^n)\<^sub>\<rat>\<close>
      using N_pos_rat by (simp add: of_int_mult)
    finally show ?thesis by (simp add: of_int_mult)
  qed
  have nondeg_halfBT: \<open>\<bar>sint bt\<bar> < 2^(n-1)\<close>
  proof -
    \<comment> \<open>From $|value - m_\rat| \le 1$, $value > -2^n + 2$, and $value < 2^n$:
        $m_\rat > -2^n + 1$ and $m_\rat < 2^n + 1$, hence $m \ge -2^n + 2$ and $m \le 2^n$.\<close>
    have m_lo: \<open>m \<ge> -(2^n) + 2\<close>
    proof -
      have \<open>(m)\<^sub>\<rat> > -((2^n)\<^sub>\<rat>) + 1\<close>
        using val_gt approx_err unfolding m_def by linarith
      hence \<open>(m)\<^sub>\<rat> > (-(2^n) + 1)\<^sub>\<rat>\<close>
        by (simp add: of_int_add of_int_minus)
      hence \<open>m > -(2^n) + 1\<close> by (metis of_int_less_iff)
      thus ?thesis by linarith
    qed
    have m_hi: \<open>m \<le> 2^n\<close>
    proof -
      have \<open>(m)\<^sub>\<rat> < (2^n)\<^sub>\<rat> + 1\<close>
        using val_lt approx_err unfolding m_def by linarith
      hence \<open>(m)\<^sub>\<rat> < (2^n + 1)\<^sub>\<rat>\<close> by (simp add: of_int_add)
      hence \<open>m < 2^n + 1\<close> by (metis of_int_less_iff)
      thus ?thesis by linarith
    qed
    \<comment> \<open>From $-2^n + 2 \le m \le 2^n$ and $halfBT = m \div 2$: $-2^{n-1} + 1 \le halfBT \le 2^{n-1}$.
        But $sint halfBT < 2^{n-1}$ always (word width), so $halfBT \le 2^{n-1} - 1$.\<close>
    have nge: \<open>n \<ge> 2\<close> using SM.npos by linarith
    have pow_split: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using R_eq .
    have hi_div: \<open>m div 2 \<le> 2^(n-1)\<close>
    proof -
      have \<open>m div 2 \<le> 2^n div 2\<close> using m_hi by (intro zdiv_mono1) auto
      also have \<open>(2::int)^n div 2 = 2^(n-1)\<close>
        using pow_split by (metis nonzero_mult_div_cancel_left zero_neq_numeral)
      finally show ?thesis .
    qed
    have lo_div: \<open>m div 2 \<ge> -(2^(n-1)) + 1\<close>
    proof -
      have \<open>m div 2 \<ge> (-(2^n) + 2) div 2\<close> using m_lo by (intro zdiv_mono1) auto
      also have \<open>(-((2::int)^n) + 2) div 2 = -(2^(n-1)) + 1\<close>
        using pow_split by simp
      finally show ?thesis .
    qed
    have halfBT_range: \<open>-(2^(n-1)) + 1 \<le> sint bt \<and> sint bt \<le> 2^(n-1)\<close>
      using halfBT_eq lo_div hi_div by simp
    \<comment> \<open>The upper end is automatically tighter via word width: $sint halfBT < 2^{n-1}$.\<close>
    have halfBT_word: \<open>sint bt < 2^(n-1)\<close>
      using sint_range_size[of bt] by (simp add: word_size n_def)
    show ?thesis using halfBT_range halfBT_word by linarith
  qed

  \<comment> \<open>sint a is bounded by the word width (always true)\<close>
  have a_range: \<open>-(2^(n-1)) \<le> sint a \<and> sint a < 2^(n-1)\<close>
    using sint_range_size[of a] by (simp add: word_size n_def)
  have a_le_R2: \<open>\<bar>sint a\<bar> \<le> 2^(n-1)\<close> using a_range by linarith
  \<comment> \<open>For SQRDMULH: halfBT not INT_MIN suffices\<close>
  have nondeg_a_or: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint bt = -(2^(n-1)))\<close>
    using nondeg_halfBT by linarith
  let ?abs = \<open>barM\<^sup>\<plusminus> \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
  interpret BMS: BarrettContext \<open>sint N\<close> n \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>
    using SM.Ngt1 SM.Nodd npos N_lt_R is_int_approx_round_even
    by unfold_locales (auto simp: IntegerApproximation_def)
  \<comment> \<open>Barrett output bound: uses |sint a| \<le> 2^(n-1) (word-width constraint)\<close>
  have abs_bound: \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
  proof -
    have B: \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * ((sint N)\<^sub>\<rat> * \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2)) / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
      using BMS.barrett_mul_signed_bound_eps[OF is_int_approx_quality_round_even,
                                              of \<open>sint a\<close> \<open>sint b\<close>]
      by simp
    have \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2) = 1\<close> by (rule quality_round_even)
    thus ?thesis using B by simp
  qed
  \<comment> \<open>The abstract result fits in the lane: \<open>|barM\<^sup>\<plusminus>| \<le> N/2 + N/2 = N \<le> 2^(n-1)\<close>\<close>
  have abs_lt_R2: \<open>\<bar>?abs\<bar> < 2^(n-1)\<close>
  proof -
    have \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
      by (rule abs_bound)
    also have \<open>\<dots> \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
    proof -
      have h1: \<open>\<bar>sint a\<bar>\<^sub>\<rat> \<le> (2^(n-1))\<^sub>\<rat>\<close>
        using a_le_R2 by (metis of_int_abs of_int_le_iff of_int_numeral of_int_power)
      have h2: \<open>0 \<le> (sint N)\<^sub>\<rat>\<close>
        using SM.Npos by (metis of_int_0_le_iff order_less_imp_le)
      have h3: \<open>(0::rat) < (2^n)\<^sub>\<rat>\<close> by simp
      from h1 h2 have step1: \<open>\<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat>\<close>
        by (intro mult_right_mono)
      hence \<open>\<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat>
                \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<close>
        using h3 by (intro divide_right_mono) auto
      thus ?thesis by linarith
    qed
    also have \<open>\<dots> = (sint N)\<^sub>\<rat> / 2 + (sint N)\<^sub>\<rat> / 2\<close>
      using R_eq by simp
    also have \<open>\<dots> = (sint N)\<^sub>\<rat>\<close> by simp
    also have \<open>\<dots> < (2^(n-1))\<^sub>\<rat>\<close> using N_lt by (metis of_int_less_iff of_int_of_nat_eq)
    finally show ?thesis by (metis of_int_abs of_int_less_iff)
  qed
  have small: \<open>2 * \<bar>?abs\<bar> < 2^n\<close>
    using abs_lt_R2 R_eq by linarith
  have R_pos: \<open>(0::int) < 2^n\<close> by simp
  have id_eq: \<open>?abs mod\<^sup>\<plusminus> 2^n = ?abs\<close>
    by (rule mod_approx_round_id_small[OF R_pos small])
  have step1: \<open>sint (barrett_mul_neon_word N b bt a)
                 = barrett_mul_neon_int n (sint N) (sint b) (sint bt) (sint a)\<close>
    by (rule sint_barrett_mul_neon_word[OF n_def nondeg_halfBT])
  have step2: \<open>barrett_mul_neon_int n (sint N) (sint b) (sint bt) (sint a)
                 = barrett_mul_neon_int n (sint N) (sint b) (m div 2) (sint a)\<close>
    using halfBT_eq by simp
  have step3: \<open>barrett_mul_neon_int n (sint N) (sint b) (m div 2) (sint a)
                 = ?abs mod\<^sup>\<plusminus> 2^n\<close>
    using barrett_mul_neon_int_eq[where N=\<open>sint N\<close> and b=\<open>sint b\<close> and a=\<open>sint a\<close>
                                    and n=\<open>n\<close>]
          m_def
    by simp
  have abs_eq: \<open>sint out = ?abs\<close>
    unfolding out_def barrett_mul_neon_word_def[symmetric]
    using step1 step2 step3 id_eq by simp
  show \<open>sint out = barM\<^sup>\<plusminus> \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
    by (rule abs_eq)
  define K :: int where \<open>K \<equiv> \<lfloor>(sint a)\<^sub>\<rat> * \<lfloor>(sint b)\<^sub>\<rat> * (2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>\<rceil>\<^sub>2\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<rceil>\<close>
  have abs_decomp: \<open>?abs = sint a * sint b - sint N * K\<close>
    unfolding barrett_mul_signed_def Let_def K_def by simp
  have mod_eq: \<open>?abs mod sint N = (sint a * sint b) mod sint N\<close>
    unfolding abs_decomp by algebra
  show \<open>sint out mod sint N = (sint a * sint b) mod sint N\<close>
    using abs_eq mod_eq by simp
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar> * sint N /\<^sub>\<rat> 2^n + sint N /\<^sub>\<rat> 2\<close>
    using abs_eq abs_bound by simp
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
  proof (cases \<open>sint b = 0\<close>)
    case True    have \<open>?abs = 0\<close>
    proof -
      have fl: \<open>\<lfloor>(1/2 :: rat)\<rfloor> = 0\<close> by linarith
      show ?thesis using True
        unfolding barrett_mul_signed_def Let_def m_def round_even_def round_def
        by (simp add: fl)
    qed
    thus ?thesis using abs_eq N_pos_int by linarith
  next
    case False
    hence b_ne: \<open>sint b \<noteq> 0\<close> .
    have \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
      using BMS.barrett_mul_narrow(1)[OF a_le_R2 b_int b_ne] .
    thus ?thesis using abs_eq by simp
  qed
qed

section \<open>Unsigned-style Barrett multiplication\<close>

text \<open>Replacing \<^verbatim>\<open>SQRDMULH\<close> with truncating \<^verbatim>\<open>MULH\<close>, the three-instruction
\<^verbatim>\<open>MUL\<close>/\<^verbatim>\<open>MULH\<close>/\<^verbatim>\<open>MLS\<close> sequence computes
\<^term>\<open>barM\<^sup>+\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>\<close> on signed lanes. The coarse output
bound is \<^term>\<open>5*N /\<^sub>\<rat> 4\<close> rather than \<^term>\<open>(N::int)\<close>, requiring a
correspondingly tighter modulus constraint
\<^term>\<open>StandardModulus N (n-2)\<close>.\<close>



definition %internal \<open>barrett_mul_unsigned_neon_int n N b m a \<equiv>
     (let R = (2::int)^n;
          z1 = (a * b) mod\<^sup>\<plusminus> R;
          t  = (a * m) div R;
          z2 = (z1 - t * N) mod\<^sup>\<plusminus> R
      in z2)\<close>

lemma %internal barrett_mul_unsigned_neon_int_eq:
  fixes a b N :: int and n :: nat
    and f :: \<open>rat \<Rightarrow> int\<close>  \<comment> \<open>integer approximation used for the precomputed magic constant\<close>
  defines \<open>m \<equiv> f (b * 2^n /\<^sub>\<rat> N)\<close>
  shows \<open>barrett_mul_unsigned_neon_int n N b m a
           = barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> mod\<^sup>\<plusminus> 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?t = \<open>(a * m) div ?R\<close>
  have div_eq: \<open>\<lfloor>a * m /\<^sub>\<rat> ?R\<rfloor> = (a * m) div ?R\<close>
    using floor_divide_of_int_eq[of \<open>a*m\<close> \<open>?R\<close>] by (simp add: of_int_mult)
  have br_unfold: \<open>barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = a * b - N * ?t\<close>
    unfolding barrett_mul_unsigned_def Let_def m_def[symmetric]
    using div_eq by simp
  have \<open>barrett_mul_unsigned_neon_int n N b m a = ((a * b) mod\<^sup>\<plusminus> ?R - ?t * N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_mul_unsigned_neon_int_def Let_def by simp
  also have \<open>\<dots> = (a * b - ?t * N) mod\<^sup>\<plusminus> ?R\<close>
    using mod_approx_shift[OF shift_compat_round, of ?R \<open>a*b - ?t*N\<close> \<open>- \<lfloor>\<cdot>\<rceil> ((a*b) /\<^sub>\<rat> ?R)\<close>]
    by (simp add: mod_approx_def algebra_simps)
  finally show ?thesis using br_unfold by (simp add: mult.commute)
qed

text %internal \<open>The integer-level kernel transcribes verbatim onto fixed-width signed
lanes: \<^const>\<open>mul_word\<close>, \<^const>\<open>mulh_word\<close> and \<^const>\<open>mls_word\<close> all match
their integer specifications without saturation, so the word kernel computes
exactly the integer kernel on \<^const>\<open>sint\<close>-projected operands.\<close>

definition %internal barrett_mul_unsigned_neon_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>barrett_mul_unsigned_neon_word N b m a \<equiv>
     let ASM \<guillemotleft>
       MUL  z1 a b;
       MULH t  a m;
       MLS  r  z1 t N
     \<guillemotright> in r\<close>

lemma %internal sint_barrett_mul_unsigned_neon_word:
  fixes N b m a :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  shows \<open>sint (barrett_mul_unsigned_neon_word N b m a)
           = barrett_mul_unsigned_neon_int n (sint N) (sint b) (sint m) (sint a)\<close>
proof -
  let ?z1 = \<open>mul_word a b\<close>
  let ?t  = \<open>mulh_word a m\<close>
  let ?R  = \<open>(2::int) ^ n\<close>
  have z1_int: \<open>sint ?z1 = (sint a * sint b) mod\<^sup>\<plusminus> ?R\<close>
    by (rule sint_mul_word[OF n_def])
  have t_int: \<open>sint ?t = mulh_int n (sint a) (sint m)\<close>
    by (rule sint_mulh_word[OF n_def])
  have \<open>sint (barrett_mul_unsigned_neon_word N b m a)
          = (sint ?z1 - sint ?t * sint N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_mul_unsigned_neon_word_def Let_def
    by (rule sint_mls_word[OF n_def])
  also have \<open>\<dots> = ((sint a * sint b) mod\<^sup>\<plusminus> ?R
                   - mulh_int n (sint a) (sint m) * sint N) mod\<^sup>\<plusminus> ?R\<close>
    using z1_int t_int by simp
  also have \<open>\<dots> = barrett_mul_unsigned_neon_int n (sint N) (sint b) (sint m) (sint a)\<close>
    unfolding barrett_mul_unsigned_neon_int_def Let_def mulh_int_def
    by simp
  finally show ?thesis .
qed

theorem barrett_mul_unsigned_neon_word_correct:
  fixes N a b m :: \<open>'a::len word\<close> and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes m_eq: \<open>sint m = \<lfloor>sint b * 2^n /\<^sub>\<rat> sint N\<rceil>\<close>
      and N_std: \<open>StandardModulus (sint N) (n-2)\<close>
      and b_bound: \<open>\<bar>sint b\<bar>\<^sub>\<rat> < (sint N)\<^sub>\<rat>\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    MUL  z1 a b;
                    MULH t  a m;
                    MLS  r  z1 t N
                  \<guillemotright> in r\<close>
  shows \<open>sint out = barM\<^sup>+ \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
        \<comment> \<open>functional description\<close>
    and \<open>sint out mod sint N = (sint a * sint b) mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat>\<close>
        \<comment> \<open>fine output bound\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < 5 * (sint N)\<^sub>\<rat> / 4\<close>
        \<comment> \<open>coarse output bound\<close>

proof -
  interpret SM: StandardModulus \<open>sint N\<close> \<open>n-2\<close> by (rule N_std)
  have npos: \<open>0 < n\<close> using SM.npos by simp
  have N_lt: \<open>sint N < 2^(n-2)\<close> using SM.N_lt_R .
  have N_lt_R: \<open>sint N < 2^n\<close>
  proof -
    have \<open>(2::int)^(n-2) \<le> 2^n\<close> by (rule power_increasing) auto
    thus ?thesis using N_lt by linarith
  qed
  have N3_bound: \<open>3 * sint N < 2^n\<close>
  proof -
    have n2: \<open>2 \<le> n\<close> using SM.npos by simp
    have \<open>3 * sint N < 3 * 2^(n-2)\<close> using N_lt SM.Npos by linarith
    also have \<open>\<dots> < (4::int) * 2^(n-2)\<close> by simp
    also have \<open>\<dots> = 2^n\<close>
    proof -
      have \<open>(4::int) = 2^2\<close> by simp
      hence \<open>(4::int) * 2^(n-2) = 2^2 * 2^(n-2)\<close> by simp
      also have \<open>\<dots> = 2^(2 + (n-2))\<close> by (simp add: power_add)
      also have \<open>2 + (n-2) = n\<close> using n2 by simp
      finally show ?thesis .
    qed
    finally show ?thesis .
  qed

  have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using npos by (cases n) auto
  have N_pos_int: \<open>(0::int) < sint N\<close> using SM.Npos .
  have N_pos_rat: \<open>(0::rat) < (sint N)\<^sub>\<rat>\<close>
    using N_pos_int by (metis of_int_0_less_iff)
  \<comment> \<open>sint a is bounded by the word width\<close>
  have a_range: \<open>-(2^(n-1)) \<le> sint a \<and> sint a < 2^(n-1)\<close>
    using sint_range_size[of a] by (simp add: word_size n_def)
  have a_le_R2: \<open>\<bar>sint a\<bar> \<le> 2^(n-1)\<close> using a_range by linarith
  let ?abs = \<open>barM\<^sup>+ \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
  have Ngt1: \<open>1 < sint N\<close> using SM.Ngt1 .
  have Nodd: \<open>odd (sint N)\<close> using SM.Nodd .
  interpret BMS: BarrettContext \<open>sint N\<close> n \<open>\<lfloor>\<cdot>\<rceil>\<close>
    using Ngt1 Nodd npos N_lt_R is_int_approx_round
    by unfold_locales (auto simp: IntegerApproximation_def)


  have abs_bound: \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat>\<close>
  proof -
    have B: \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * ((sint N)\<^sub>\<rat> * \<epsilon>(\<lfloor>\<cdot>\<rceil>)) / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> - sint N /\<^sub>\<rat> 2^n\<close>
      using BMS.barrett_mul_unsigned_bound_eps[OF is_int_approx_quality_round,
                                                of \<open>sint a\<close> \<open>sint b\<close>]
      by simp
    have eps_le: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>) = 1/2\<close> by (rule quality_round)
    have nn: \<open>0 \<le> (sint N)\<^sub>\<rat> / (2^n :: int)\<^sub>\<rat>\<close>
      using N_pos_rat by simp
    have h2: \<open>0 \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<close>
      using N_pos_rat by simp
    from B eps_le nn h2 show ?thesis by simp
  qed
  have abs_lt_R2: \<open>2 * \<bar>?abs\<bar> < 2^n\<close>
  proof -
    have \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat>\<close>
      by (rule abs_bound)
    also have \<open>\<dots> \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat>\<close>
    proof -
      have h1: \<open>\<bar>sint a\<bar>\<^sub>\<rat> \<le> (2^(n-1))\<^sub>\<rat>\<close>
        using a_le_R2 by (metis of_int_abs of_int_le_iff of_int_numeral of_int_power)
      have h2: \<open>0 \<le> (sint N)\<^sub>\<rat>\<close> using N_pos_rat by linarith
      have h3: \<open>(0::rat) < (2^n)\<^sub>\<rat>\<close> by simp
      from h1 h2 have \<open>\<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat>\<close>
        by (intro mult_right_mono)
      hence \<open>\<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat>
                \<le> (2^(n-1))\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<close>
        using h3 by (intro divide_right_mono) auto
      thus ?thesis by linarith
    qed
    also have \<open>\<dots> = (sint N)\<^sub>\<rat> / 2 + (sint N)\<^sub>\<rat>\<close> using R_eq by simp
    also have \<open>\<dots> = 3/2 * (sint N)\<^sub>\<rat>\<close> by simp
    finally have rat_bd: \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> \<le> 3/2 * (sint N)\<^sub>\<rat>\<close> .
    hence rat_bd2: \<open>(2 * \<bar>?abs\<bar>)\<^sub>\<rat> \<le> (3 * sint N)\<^sub>\<rat>\<close>
      by (simp add: of_int_mult of_int_abs)
    hence int_bd: \<open>2 * \<bar>?abs\<bar> \<le> 3 * sint N\<close> by (metis of_int_le_iff)
    thus ?thesis using N3_bound by linarith
  qed
  have small: \<open>2 * \<bar>?abs\<bar> < 2^n\<close> by (rule abs_lt_R2)
  have R_pos: \<open>(0::int) < 2^n\<close> by simp
  have id_eq: \<open>?abs mod\<^sup>\<plusminus> 2^n = ?abs\<close>
    by (rule mod_approx_round_id_small[OF R_pos small])
  have m_eq': \<open>sint m = \<lfloor>\<cdot>\<rceil> ((sint b)\<^sub>\<rat> * (2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>)\<close>
    using m_eq by simp
  have step1: \<open>sint (barrett_mul_unsigned_neon_word N b m a)
                 = barrett_mul_unsigned_neon_int n (sint N) (sint b) (sint m) (sint a)\<close>
    by (rule sint_barrett_mul_unsigned_neon_word[OF n_def])
  have step2: \<open>barrett_mul_unsigned_neon_int n (sint N) (sint b) (sint m) (sint a)
                 = barrett_mul_unsigned_neon_int n (sint N) (sint b)
                     (\<lfloor>\<cdot>\<rceil> ((sint b)\<^sub>\<rat> * (2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>)) (sint a)\<close>
    using m_eq' by simp
  have step3: \<open>barrett_mul_unsigned_neon_int n (sint N) (sint b)
                  (\<lfloor>\<cdot>\<rceil> ((sint b)\<^sub>\<rat> * (2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>)) (sint a)
                 = ?abs mod\<^sup>\<plusminus> 2^n\<close>
    using barrett_mul_unsigned_neon_int_eq[where N=\<open>sint N\<close> and b=\<open>sint b\<close> and a=\<open>sint a\<close>
                                              and n=\<open>n\<close> and f=round]
    by simp
  have abs_eq: \<open>sint out = ?abs\<close>
    unfolding out_def barrett_mul_unsigned_neon_word_def[symmetric]
    using step1 step2 step3 id_eq by simp
  show \<open>sint out = barM\<^sup>+ \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>sint a, sint b\<rangle>\<close>
    by (rule abs_eq)
  define K :: int where \<open>K \<equiv> \<lfloor>(sint a)\<^sub>\<rat> * \<lfloor>(sint b)\<^sub>\<rat> * (2^n)\<^sub>\<rat> / (sint N)\<^sub>\<rat>\<rceil>\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<rfloor>\<close>
  have abs_decomp: \<open>?abs = sint a * sint b - sint N * K\<close>
    unfolding barrett_mul_unsigned_def Let_def K_def by simp
  have mod_eq: \<open>?abs mod sint N = (sint a * sint b) mod sint N\<close>
    unfolding abs_decomp by algebra
  show \<open>sint out mod sint N = (sint a * sint b) mod sint N\<close>
    using abs_eq mod_eq by simp
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat>\<close>
    using abs_eq abs_bound by simp
  have b_int: \<open>\<bar>sint b\<bar> < sint N\<close>
    using b_bound by (metis of_int_abs of_int_less_iff)
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < 5 * (sint N)\<^sub>\<rat> / 4\<close>
  proof (cases \<open>sint b = 0\<close>)
    case True
    have \<open>?abs = 0\<close>
    proof -
      have fl: \<open>\<lfloor>(1/2 :: rat)\<rfloor> = 0\<close> by linarith
      show ?thesis using True
        unfolding barrett_mul_unsigned_def Let_def round_def
        by (simp add: fl)
    qed
    thus ?thesis using abs_eq N_pos_int by linarith
  next
    case False
    hence b_ne: \<open>sint b \<noteq> 0\<close> .
    have \<open>\<bar>(?abs)\<^sub>\<rat>\<bar> < 5 * (sint N)\<^sub>\<rat> / 4\<close>
      using BMS.barrett_mul_narrow(3)[OF a_le_R2 b_int b_ne] by simp

    thus ?thesis using abs_eq by simp
  qed
qed

section \<open>Single-input Barrett reduction\<close>

text \<open>We verify \cite[Algorithm~9, \S 3.2]{NeonNTT}: the two-instruction
\<^verbatim>\<open>SQRDMULH\<close>/\<^verbatim>\<open>MLS\<close> sequence computes
\<^term>\<open>bar\<^sup>\<plusminus>\<lbrakk>N,n,\<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> z\<close> on signed lanes.\<close>


definition %internal \<open>barrett_red_neon_int n N halfM z \<equiv>
     (let R = 2^n;
          t = \<lfloor>\<cdot>\<rceil> ((2 * z * halfM) /\<^sub>\<rat> R)
      in (z - t * N) mod\<^sup>\<plusminus> R)\<close>

text %internal \<open>Fed half of the round-to-even magic constant, the kernel equals the
abstract single-input Barrett reduction operator modulo the lane width.\<close>

lemma %internal barrett_red_neon_int_eq:
  fixes z N :: int and n :: nat
  defines \<open>m \<equiv> \<lfloor>2^n /\<^sub>\<rat> N\<rceil>\<^sub>2\<close>
  shows \<open>barrett_red_neon_int n N (m div 2) z = bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> z mod\<^sup>\<plusminus> 2^n\<close>
proof -
  have m_even: \<open>even m\<close>
    unfolding m_def round_even_def by simp
  have step1: \<open>\<lfloor>\<cdot>\<rceil> ((2 * z * (m div 2)) /\<^sub>\<rat> (2^n))
                 = \<lfloor>\<cdot>\<rceil> ((z * m) /\<^sub>\<rat> (2^n))\<close>
    using sqrdmulh_halved_eq[OF m_even, of z n] by simp
  have step2: \<open>(z * m) /\<^sub>\<rat> (2^n) = z\<^sub>\<rat> * m\<^sub>\<rat> / (2^n)\<^sub>\<rat>\<close>
    by (simp add: of_int_mult)
  have br_unfold: \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> z
                   = z - N * \<lfloor>\<cdot>\<rceil> (z\<^sub>\<rat> * m\<^sub>\<rat> / (2^n)\<^sub>\<rat>)\<close>
    unfolding barrett_red_signed_def m_def by simp
  let ?R = \<open>(2::int)^n\<close>
  let ?t = \<open>\<lfloor>\<cdot>\<rceil> (z\<^sub>\<rat> * m\<^sub>\<rat> / ?R\<^sub>\<rat>)\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have neon_unfold: \<open>barrett_red_neon_int n N (m div 2) z = (z - ?t * N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_red_neon_int_def Let_def
    using step1 step2 by (simp add: algebra_simps)
  have comm: \<open>z - ?t * N = z - N * ?t\<close> by simp
  have \<open>barrett_red_neon_int n N (m div 2) z = (z - ?t * N) mod\<^sup>\<plusminus> ?R\<close>
    using neon_unfold by simp
  also have \<open>\<dots> = (z - N * ?t) mod\<^sup>\<plusminus> ?R\<close>
    by (subst comm) (rule refl)
  also have \<open>\<dots> = (bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> z) mod\<^sup>\<plusminus> ?R\<close>
    using br_unfold by simp
  finally show ?thesis .
qed

text %internal \<open>The integer-level reduction kernel transcribes onto fixed-width signed
lanes provided the saturation case for \<^const>\<open>sqrdmulh_word\<close> is excluded;
\<^const>\<open>mls_word\<close> matches its integer specification unconditionally.\<close>

definition %internal barrett_red_neon_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>barrett_red_neon_word N halfM z \<equiv>
     let ASM \<guillemotleft>
       SQRDMULH t z halfM;
       MLS      r z t N
     \<guillemotright> in r\<close>

lemma %internal sint_barrett_red_neon_word:
  fixes N halfM z :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes nondeg_halfM: \<open>\<bar>sint halfM\<bar> < 2^(n-1)\<close>
    shows \<open>sint (barrett_red_neon_word N halfM z)
              = barrett_red_neon_int n (sint N) (sint halfM) (sint z)\<close>
proof -
  let ?t = \<open>sqrdmulh_word z halfM\<close>
  let ?R = \<open>(2::int) ^ n\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have not_extreme: \<open>\<not> (sint z = -(2^(n-1)) \<and> sint halfM = -(2^(n-1)))\<close>
    using nondeg_halfM by linarith
  have t_int: \<open>sint ?t = sqrdmulh_int n (sint z) (sint halfM)\<close>
    by (rule sint_sqrdmulh_word[OF n_def not_extreme])
  have \<open>sint (barrett_red_neon_word N halfM z) = (sint z - sint ?t * sint N) mod\<^sup>\<plusminus> ?R\<close>
    unfolding barrett_red_neon_word_def Let_def
    by (rule sint_mls_word[OF n_def])
  also have \<open>\<dots> = (sint z - sqrdmulh_int n (sint z) (sint halfM) * sint N) mod\<^sup>\<plusminus> ?R\<close>
    using t_int by simp
  also have \<open>\<dots> = barrett_red_neon_int n (sint N) (sint halfM) (sint z)\<close>
    unfolding barrett_red_neon_int_def Let_def sqrdmulh_int_def
    by simp
  finally show ?thesis .
qed

theorem barrett_red_neon_word_correct:
  fixes N Nt z :: \<open>'a::len word\<close>
    and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes Nt_eq: \<open>sint Nt = \<lfloor>2^n /\<^sub>\<rat> sint N\<rceil>\<^sub>2 div 2\<close>
      and N_std: \<open>StandardModulus (sint N) (n-2)\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQRDMULH t z Nt;
                    MLS      r z t N
                  \<guillemotright> in r\<close>
  shows \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<close>
        \<comment> \<open>abstract description\<close>
    and \<open>sint out mod sint N = sint z mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint z\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
        \<comment> \<open>fine output bound\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> 3/2 * (sint N)\<^sub>\<rat>\<close>
        \<comment> \<open>coarse output bound\<close>

proof -
  define m where \<open>m \<equiv> \<lfloor>2^n /\<^sub>\<rat> sint N\<rceil>\<^sub>2\<close>
  have halfM_eq: \<open>sint Nt = m div 2\<close> using Nt_eq unfolding m_def .
  interpret SM: StandardModulus \<open>sint N\<close> \<open>n-2\<close> by (rule N_std)

  have n_ge_2: \<open>n \<ge> 2\<close> using SM.npos by simp
  have npos: \<open>0 < n\<close> using n_ge_2 by simp
  have N_lt: \<open>sint N < 2^(n-1)\<close>
    using SM.N_lt_R power_increasing[of \<open>n-2\<close> \<open>n-1\<close> \<open>2::int\<close>] by linarith

  have N_ge_2: \<open>2 \<le> sint N\<close> using SM.Ngt1 by linarith
  have N2_pos: \<open>(0::int) < 2 * sint N\<close> using N_ge_2 by linarith
  \<comment> \<open>Reduce \<open>m div 2\<close> to a single rounded ratio.\<close>
  have m_div2: \<open>m div 2 = \<lfloor>2^n /\<^sub>\<rat> (2 * sint N)\<rceil>\<close>
    unfolding m_def round_even_def by (simp add: field_simps mult.commute)
  \<comment> \<open>Lower and upper bounds on \<open>halfM\<close> via \<open>0 \<le> \<dots> \<le> 2^(n-2) < 2^(n-1)\<close>.\<close>
  have ratio_nonneg: \<open>0 \<le> 2^n /\<^sub>\<rat> (2 * sint N)\<close>
  proof -
    have \<open>0 < (2 * sint N)\<^sub>\<rat>\<close> using N2_pos by linarith
    thus ?thesis by (simp add: zero_le_divide_iff)
  qed
  have halfM_lb: \<open>0 \<le> m div 2\<close>
    unfolding m_div2 using ratio_nonneg by (simp add: round_def)
  have pow_n: \<open>(2::int)^n = 4 * 2^(n-2)\<close>
    using n_ge_2 by (simp add: power_eq_if numeral_eq_Suc)
  have step: \<open>(2::int)^n \<le> 2 * sint N * 2^(n-2)\<close>
    using N_ge_2 pow_n by (simp add: mult_right_mono)
  have ratio_ub: \<open>2^n /\<^sub>\<rat> (2 * sint N) \<le> (2^(n-2))\<^sub>\<rat>\<close>
  proof -
    have N2pos: \<open>0 < (2 * sint N)\<^sub>\<rat>\<close> using N2_pos by linarith
    from step have \<open>(2^n)\<^sub>\<rat> \<le> ((2 * sint N) * 2^(n-2))\<^sub>\<rat>\<close>
      by (simp only: of_int_le_iff)
    hence \<open>(2^n)\<^sub>\<rat> \<le> (2 * sint N)\<^sub>\<rat> * (2^(n-2))\<^sub>\<rat>\<close> by (simp add: of_int_mult)
    thus ?thesis using N2pos by (simp add: pos_divide_le_eq mult.commute)
  qed
  have halfM_ub: \<open>m div 2 \<le> 2^(n-2)\<close>
  proof -
    have \<open>\<lfloor>2^n /\<^sub>\<rat> (2 * sint N)\<rceil> \<le> \<lfloor>(2^(n-2))\<^sub>\<rat>\<rceil>\<close>
      using ratio_ub by (rule round_mono)
    also have \<open>\<lfloor>(2^(n-2))\<^sub>\<rat>\<rceil> = 2^(n-2)\<close> by (rule round_of_int)
    finally show ?thesis unfolding m_div2 .
  qed
  have pow_lt: \<open>(2::int)^(n-2) < 2^(n-1)\<close>
    using n_ge_2 by (intro power_strict_increasing) auto
  have nondeg_Nt: \<open>\<bar>sint Nt\<bar> < 2^(n-1)\<close>
    using halfM_lb halfM_ub halfM_eq pow_lt by linarith
  \<comment> \<open>Chain to the lane-width residue \<open>bar\<^sup>\<plusminus> mod\<^sup>\<plusminus> 2^n\<close>.\<close>
  have step_chain: \<open>sint (barrett_red_neon_word N Nt z)
                      = bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z) mod\<^sup>\<plusminus> 2^n\<close>
    using sint_barrett_red_neon_word[OF n_def nondeg_Nt]
          halfM_eq
          barrett_red_neon_int_eq[where N=\<open>sint N\<close> and z=\<open>sint z\<close> and n=\<open>n\<close>]
          m_def
    by simp


  \<comment> \<open>Bound \<open>2\<bar>bar\<^sup>\<plusminus>\<bar> < 3N\<close> via \<open>barrett_red_narrow\<close>, using \<open>3N \<le> 2^n\<close> to drop \<open>mod\<^sup>\<plusminus> 2^n\<close>.\<close>
  have N_lt_R: \<open>sint N < 2^n\<close>
    using N_lt power_increasing[of "n-1" n "2::int"] by linarith
  interpret BMS: BarrettContext \<open>sint N\<close> n \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>
    using SM.Ngt1 SM.Nodd npos N_lt_R is_int_approx_round_even
    by unfold_locales (auto simp: IntegerApproximation_def)
  have abs_bound: \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<bar> < sint N\<close>
  proof -
    have z_le: \<open>\<bar>sint z\<bar> \<le> 2^(n-1)\<close>
      using sint_range_size[of z] by (simp add: word_size n_def, linarith)
    have \<open>\<bar>(bar\<^sup>\<plusminus> \<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z))\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
      using BMS.barrett_red_narrow(1)[OF z_le] .
    thus ?thesis using SM.Npos by (simp, linarith)
  qed
  have abs_eq: \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<close>
  proof -
    have R_pos: \<open>(0::int) < 2^n\<close> by simp
    have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using npos by (cases n) auto
    have small: \<open>2 * \<bar>bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<bar> < 2^n\<close>
      using abs_bound N_lt R_eq by linarith

    have id_eq: \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z) mod\<^sup>\<plusminus> 2^n
                   = bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<close>
      by (rule mod_approx_round_id_small[OF R_pos small])
    show ?thesis
      unfolding out_def barrett_red_neon_word_def[symmetric]
      using step_chain id_eq by simp
  qed
  show \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z)\<close> by (rule abs_eq)
  show \<open>sint out mod sint N = sint z mod sint N\<close>
  proof -
    define K :: int where \<open>K \<equiv> \<lfloor>(sint z) * \<lfloor>2^n /\<^sub>\<rat> (sint N)\<rceil>\<^sub>2 /\<^sub>\<rat> 2^n\<rceil>\<close>
    have decomp: \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z) = sint z - sint N * K\<close>
      unfolding barrett_red_signed_def K_def by simp
    have \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> (sint z) mod sint N = sint z mod sint N\<close>
      unfolding decomp by algebra
    thus ?thesis using abs_eq by simp
  qed
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint z\<bar>\<^sub>\<rat> * (sint N)\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
    using abs_eq
          BMS.barrett_red_signed_bound_eps[OF is_int_approx_quality_round_even, of \<open>sint z\<close>]
    by (simp add: quality_round_even)
  have out_lt: \<open>\<bar>sint out\<bar> < sint N\<close>
    using abs_eq abs_bound by simp
  hence \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
    by (metis of_int_abs of_int_less_iff)
  thus \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> 3/2 * (sint N)\<^sub>\<rat>\<close>
    using SM.Npos by linarith



qed

section \<open>Refined Barrett reduction\<close>

text \<open>\cite[Algorithm~11, \S 3.2]{NeonNTT} discusses a three-instruction
\<^verbatim>\<open>SQDMULH\<close>/\<^verbatim>\<open>SRSHR\<close>/\<^verbatim>\<open>MLS\<close> sequence implementing refined Barrett reduction
at effective radix \<^term>\<open>2^(n+\<alpha>-1) :: int\<close>. The output is canonical
if we assume \<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) < 1/4\<close> instead of the
guaranteed \<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) < 1/2\<close>. Otherwise, the
output is only guaranteed to be canonical for inputs with
\<^term>\<open>\<bar>sint z\<bar> \<le> 2^(n-2)\<close>. The statement of \cite[Algorithm~11]{NeonNTT} as 
published misses this and is wrong as stated. However, we note --- and show below ---
that the assumption \<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) < 1/4\<close> does hold in the context
of ML-KEM and ML-DSA, so for those applications the error is of no consequence.\<close>

definition %internal \<open>barrett_red_refined_neon_int n \<alpha> N V z \<equiv>
     (let t = sqdmulh_int n z V;
          q = srshr_int \<alpha> t
      in (z - q * N) mod\<^sup>\<plusminus> 2^n)\<close>

text %internal \<open>The integer kernel equals the refined Barrett reduction.\<close>

lemma %internal barrett_red_refined_neon_int_eq:
  shows \<open>barrett_red_refined_neon_int n \<alpha> N V z
           = (barrett_red_refined N n \<alpha> V z) mod\<^sup>\<plusminus> 2^n\<close>
  unfolding barrett_red_refined_neon_int_def barrett_red_refined_def
            sqdmulh_int_def srshr_int_def Let_def
  by simp

definition %internal barrett_red_refined_neon_word
  :: \<open>'a::len word \<Rightarrow> nat \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>barrett_red_refined_neon_word N \<alpha> V z \<equiv>
     let t = sqdmulh_word z V;
         q = srshr_word \<alpha> t
     in mls_word z q N\<close>

lemma %internal sint_barrett_red_refined_neon_word:
  fixes N V z :: \<open>'a::len word\<close> and n \<alpha> :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes nondeg_V: \<open>\<bar>sint V\<bar> < 2^(n-1)\<close>
  shows \<open>sint (barrett_red_refined_neon_word N \<alpha> V z)
            = barrett_red_refined_neon_int n \<alpha> (sint N) (sint V) (sint z)\<close>
proof -
  define t :: \<open>'a word\<close> where \<open>t = sqdmulh_word z V\<close>
  define q :: \<open>'a word\<close> where \<open>q = srshr_word \<alpha> t\<close>
  have expand: \<open>barrett_red_refined_neon_word N \<alpha> V z = mls_word z q N\<close>
    unfolding barrett_red_refined_neon_word_def Let_def t_def q_def by simp
  have not_extreme: \<open>\<not>(sint z = -(2^(n-1)) \<and> sint V = -(2^(n-1)))\<close>
    using nondeg_V by linarith
  have t_int: \<open>sint t = sqdmulh_int n (sint z) (sint V)\<close>
    unfolding t_def by (rule sint_sqdmulh_word[OF n_def not_extreme])
  have q_int: \<open>sint q = srshr_int \<alpha> (sint t)\<close>
    unfolding q_def by (rule sint_srshr_word[OF n_def])
  have mls_eq: \<open>sint (mls_word z q N) = (sint z - sint q * sint N) mod\<^sup>\<plusminus> 2^n\<close>
    by (rule sint_mls_word[OF n_def])
  have \<open>sint (barrett_red_refined_neon_word N \<alpha> V z)
          = (sint z - srshr_int \<alpha> (sqdmulh_int n (sint z) (sint V)) * sint N) mod\<^sup>\<plusminus> 2^n\<close>
    using expand mls_eq q_int t_int by simp
  also have \<open>\<dots> = barrett_red_refined_neon_int n \<alpha> (sint N) (sint V) (sint z)\<close>
    unfolding barrett_red_refined_neon_int_def Let_def by simp
  finally show ?thesis .
qed

theorem barrett_red_refined_neon_word_correct:
  fixes N V z :: \<open>'a::len word\<close> and n \<alpha> \<delta> :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes V_eq: \<open>sint V = \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> sint N\<rceil>\<close>
        \<comment> \<open>magic constant; the RHS fits in a signed \<^term>\<open>n\<close>-bit word
            because \<^term>\<open>2^\<alpha> < sint N\<close>\<close>
      and N_std: \<open>StandardModulus (sint N) n\<close>
      and N_alpha: \<open>2^\<alpha> < sint N\<close> \<open>sint N < 2^(\<alpha>+1)\<close>
        \<comment> \<open>\<open>\<alpha> = \<lfloor>log\<^sub>2 (sint N)\<rfloor>\<close>\<close>
      and \<delta>_quality: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) \<le> 1/2^\<delta>\<close>
      and z_bound: \<open>\<bar>sint z\<bar> \<le> 2^(n-1-(2-\<delta>))\<close>
        \<comment> \<open>\<^term>\<open>\<delta>=1\<close> requires 1 bit of slack, \<^term>\<open>\<delta> \<ge> 2\<close> covers full signed \<^term>\<open>n\<close>-bit range\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQDMULH t z V;
                    SRSHR   q t #\<alpha>;
                    MLS     r z q N
                  \<guillemotright> in r\<close>
  shows \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
        \<comment> \<open>abstract description: refined Barrett at radix \<open>2^(n+\<alpha>-1)\<close>\<close>
    and \<open>sint out = sint z mod\<^sup>\<plusminus> sint N\<close>
        \<comment> \<open>output is the signed canonical residue\<close>
proof -
  have mod_signed_unique:
    \<open>\<And>x y N. odd N \<Longrightarrow> 0 < N \<Longrightarrow> y mod N = x mod N
              \<Longrightarrow> 2 * \<bar>y\<bar> < N \<Longrightarrow> y = x mod\<^sup>\<plusminus> N\<close>
  proof -
    fix x y N :: int
    assume Nodd: \<open>odd N\<close> and Npos: \<open>0 < N\<close>
       and mod_eq: \<open>y mod N = x mod N\<close>
       and small: \<open>2 * \<bar>y\<bar> < N\<close>
    define r where \<open>r = x mod\<^sup>\<plusminus> N\<close>
    have r_lo: \<open>- (N div 2) \<le> r\<close>
      using mod_signed_lower[OF Npos] r_def by simp
    have r_hi: \<open>r \<le> (N - 1) div 2\<close>
      using mod_signed_upper[OF Npos] r_def by simp
    have r_eq: \<open>r = x - N * \<lfloor>x /\<^sub>\<rat> N\<rceil>\<close>
      unfolding r_def mod_approx_def by simp
    have shift_eq: \<open>(x - N * \<lfloor>x /\<^sub>\<rat> N\<rceil>) mod N = x mod N\<close>
    proof -
      have \<open>x - N * \<lfloor>x /\<^sub>\<rat> N\<rceil> = x + N * (- \<lfloor>x /\<^sub>\<rat> N\<rceil>)\<close> by simp
      also have \<open>(x + N * (- \<lfloor>x /\<^sub>\<rat> N\<rceil>)) mod N = x mod N\<close> by (rule mod_mult_self2)
      finally show ?thesis .
    qed
    have r_mod: \<open>r mod N = x mod N\<close> using r_eq shift_eq by simp
    have yr_mod: \<open>y mod N = r mod N\<close> using mod_eq r_mod by simp
    have N_div2: \<open>2 * (N div 2) = N - 1\<close> using Nodd by (auto elim: oddE)
    have small_y: \<open>2 * y < N \<and> -N < 2 * y\<close> using small by linarith
    have small_r: \<open>2 * r < N \<and> -N < 2 * r\<close>
      using r_lo r_hi N_div2 by linarith
    have diff_bd: \<open>\<bar>y - r\<bar> < N\<close> using small_y small_r by linarith
    have Ndvd: \<open>N dvd (y - r)\<close> using yr_mod by (simp add: mod_eq_dvd_iff)
    have \<open>y - r = 0\<close>
    proof (rule ccontr)
      assume \<open>y - r \<noteq> 0\<close>
      hence \<open>\<bar>N\<bar> \<le> \<bar>y - r\<bar>\<close> using Ndvd by (rule dvd_imp_le_int)
      thus False using diff_bd Npos by simp
    qed
    hence \<open>y = r\<close> by simp
    thus \<open>y = x mod\<^sup>\<plusminus> N\<close> using r_def by simp
  qed

  interpret SM: StandardModulus \<open>sint N\<close> n by (rule N_std)
  have \<alpha>_pos: \<open>1 \<le> \<alpha>\<close>
    using N_alpha SM.Ngt1 power_less_imp_less_exp[of \<open>2::int\<close> 1 \<open>\<alpha>+1\<close>] by simp

  \<comment> \<open>Bound on \<^term>\<open>sint V\<close>: nonneg and bounded by \<^term>\<open>2^(n-1)\<close> (since \<^term>\<open>(2::int)^\<alpha> \<le> sint N\<close>).\<close>
  have V_nn: \<open>sint V \<ge> 0\<close>
  proof -
    have \<open>(of_int (sint N) :: rat) > 0\<close> using SM.Ngt1 by linarith
    hence \<open>(0::rat) \<le> of_int ((2::int)^(n+\<alpha>-1)) / of_int (sint N)\<close>
      by (simp add: zero_le_divide_iff)
    thus ?thesis using V_eq by (simp add: round_def)
  qed
  have nondeg_V: \<open>\<bar>sint V\<bar> < 2^(n-1)\<close>
    using V_nn n_def sint_lt[of V] by simp

  \<comment> \<open>Set up Barrett context at radix \<^term>\<open>n+\<alpha>-1\<close>.\<close>
  have N_lt_Rn\<alpha>: \<open>sint N < 2^(n+\<alpha>-1)\<close>
    using SM.N_lt_R power_increasing[of n \<open>n+\<alpha>-1\<close> \<open>2::int\<close>] \<alpha>_pos by linarith
  interpret BMS: BarrettContext \<open>sint N\<close> \<open>n+\<alpha>-1\<close> round
    using SM.Ngt1 SM.Nodd SM.npos \<alpha>_pos N_lt_Rn\<alpha> is_int_approx_round
    by unfold_locales auto

  \<comment> \<open>Coarse bound on the abstract Barrett result via \<^term>\<open>barrett_red_narrow\<close>.\<close>
  have z_le_Rn\<alpha>: \<open>\<bar>sint z\<bar> \<le> 2^(n+\<alpha>-1 - 1)\<close>
    using sint_in_signed_range[OF n_def, of z]
          power_increasing[of \<open>n-1\<close> \<open>n+\<alpha>-1-1\<close> \<open>2::int\<close>] \<alpha>_pos SM.npos by linarith
  have abs_int_bound: \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<bar> < sint N\<close>
  proof -
    have \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z))\<^sub>\<rat>\<bar> < (sint N)\<^sub>\<rat>\<close>
      using BMS.barrett_red_narrow(2)[OF z_le_Rn\<alpha>] by simp
    thus ?thesis by (metis of_int_abs of_int_less_iff)
  qed

  \<comment> \<open>The Barrett result fits in a signed \<open>n\<close>-bit lane, so \<open>mod\<^sup>\<plusminus> 2^n\<close> is the identity.\<close>
  have small: \<open>2 * \<bar>bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<bar> < 2^n\<close>
  proof -
    have N_lt_half: \<open>sint N < 2^(n-1)\<close> using sint_in_signed_range[OF n_def, of N] by auto
    have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close> using SM.npos by (cases n) auto
    show ?thesis using abs_int_bound N_lt_half R_eq by linarith
  qed
  have id_eq: \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z) mod\<^sup>\<plusminus> 2^n
                 = bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
    by (rule mod_approx_round_id_small[OF zero_less_power[of \<open>2::int\<close> n] small]) simp

  \<comment> \<open>Bridge chain: word \<rightarrow> int \<rightarrow> refined \<rightarrow> abstract Barrett.\<close>
  have abs_eq: \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
    using sint_barrett_red_refined_neon_word[OF n_def nondeg_V, of N \<alpha> z]
          barrett_red_refined_neon_int_eq[of n \<alpha> \<open>sint N\<close> \<open>sint V\<close> \<open>sint z\<close>]
          barrett_red_refined_eq[OF \<alpha>_pos V_eq] id_eq
    unfolding out_def Let_def barrett_red_refined_neon_word_def by simp

  show \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close> by (rule abs_eq)

  \<comment> \<open>Correctness: \<open>sint out \<equiv> sint z\<close> modulo \<^term>\<open>sint N\<close>.\<close>
  have mod_eq: \<open>sint out mod sint N = sint z mod sint N\<close>
  proof -
    define K :: int
      where \<open>K = \<lfloor>(sint z)\<^sub>\<rat> * \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> sint N\<rceil>\<^sub>\<rat> / (2^(n+\<alpha>-1))\<^sub>\<rat>\<rceil>\<close>
    have decomp: \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z) = sint z - sint N * K\<close>
      unfolding barrett_red_signed_def K_def by simp
    have \<open>bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z) mod sint N = sint z mod sint N\<close>
      unfolding decomp by algebra
    thus ?thesis using abs_eq by simp
  qed

  \<comment> \<open>Signed canonical bound via the (\<gamma>, \<delta>) corollary, with \<^term>\<open>\<gamma>_canon = \<alpha>+1-\<delta>\<close>.\<close>
  have canonical_bound: \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < sint N /\<^sub>\<rat> 2\<close>
  proof -
    have eps_le: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, BMS.R /\<^sub>\<rat> sint N) \<le> 1/2^\<delta>\<close> using \<delta>_quality by simp
    have N_ge3: \<open>sint N \<ge> 3\<close>
      using N_alpha(1) \<alpha>_pos power_increasing[of 1 \<alpha> \<open>2::int\<close>] by simp
    have n_ge3: \<open>n \<ge> 3\<close>
    proof -
      have \<open>(2::int)^2 \<le> 2^(n-1)\<close> using N_ge3 sint_in_signed_range[OF n_def, of N] by simp
      thus ?thesis using power_le_imp_le_exp[of \<open>2::int\<close> 2 \<open>n-1\<close>] by simp
    qed
    have z_le: \<open>\<bar>sint z\<bar> \<le> 2^((n+\<alpha>-1) - 1 - (\<alpha>+1-\<delta>))\<close>
    proof -
      have \<open>n - 1 - (2 - \<delta>) \<le> (n+\<alpha>-1) - 1 - (\<alpha>+1-\<delta>)\<close> using \<alpha>_pos SM.npos by linarith
      hence \<open>(2::int)^(n - 1 - (2 - \<delta>)) \<le> 2^((n+\<alpha>-1) - 1 - (\<alpha>+1-\<delta>))\<close>
        by (rule power_increasing) simp
      thus ?thesis using z_bound by linarith
    qed
    have \<gamma>_le: \<open>\<alpha> + 1 - \<delta> \<le> (n+\<alpha>-1) - 1\<close> using \<alpha>_pos n_ge3 by linarith
    have N_lt: \<open>sint N < 2^((\<alpha>+1-\<delta>) + \<delta>)\<close>
      using N_alpha(2) power_increasing[of \<open>\<alpha>+1\<close> \<open>(\<alpha>+1-\<delta>)+\<delta>\<close> \<open>2::int\<close>] by linarith
    have \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>sint N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z))\<^sub>\<rat>\<bar> < sint N /\<^sub>\<rat> 2\<close>
      using BMS.barrett_red_signed_canonical[OF eps_le z_le \<gamma>_le N_lt] .
    thus ?thesis using abs_eq by simp
  qed

  \<comment> \<open>Combine: \<^term>\<open>sint out\<close> matches \<^term>\<open>sint z mod\<^sup>\<plusminus> sint N\<close> by the canonical-residue
      uniqueness lemma, since \<^term>\<open>sint N\<close> is odd, positive, and the bounds match.\<close>
  show \<open>sint out = sint z mod\<^sup>\<plusminus> sint N\<close>
  proof -
    have small: \<open>2 * \<bar>sint out\<bar> < sint N\<close>
    proof -
      have \<open>(2 * \<bar>sint out\<bar>)\<^sub>\<rat> < (sint N)\<^sub>\<rat>\<close>
        using canonical_bound by (simp add: of_int_mult of_int_abs)
      thus ?thesis by (metis of_int_less_iff)
    qed
    show ?thesis
      using mod_signed_unique[OF SM.Nodd SM.Npos mod_eq small] .
  qed
qed


text \<open>Specialisation to ML-KEM: \<^term>\<open>N = 3329\<close>, \<^term>\<open>n = 16\<close>, \<^term>\<open>\<alpha> = 11\<close>, \<^term>\<open>\<delta> = 2\<close>.
For this modulus, the rounding-quality factor satisfies
\<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^26 /\<^sub>\<rat> 3329) \<le> 1/4\<close>, so the canonical-output theorem applies for the full
signed 16-bit input range.\<close>

theorem barrett_red_refined_neon_word_correct_ml_kem:
  fixes z :: \<open>16 word\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQDMULH t z 20159; \<comment> \<open>(@{lemma \<open>20159=\<lfloor>2^(16 + 11 - 1) /\<^sub>\<rat> 3329\<rceil>\<close> by eval})\<close>
                    SRSHR   q t #11;
                    MLS     r z q 3329
                  \<guillemotright> in r\<close>
  
  shows \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>3329, 26, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
        \<comment> \<open>abstract description: refined Barrett at radix \<open>2^26\<close>\<close>
    and \<open>sint out = sint z mod\<^sup>\<plusminus> 3329\<close>
        \<comment> \<open>output is the signed canonical residue\<close>
proof -
  have V_eq: \<open>sint (20159 :: 16 word) = \<lfloor>2^(16+11-1) /\<^sub>\<rat> sint (3329 :: 16 word)\<rceil>\<close>
    by eval
  have N_std: \<open>StandardModulus (sint (3329 :: 16 word)) 16\<close>
    by unfold_locales eval+
  have N_alpha1: \<open>(2::int)^11 < sint (3329 :: 16 word)\<close>
    by eval
  have N_alpha2: \<open>sint (3329 :: 16 word) < (2::int)^(11+1)\<close>
    by eval
  have \<delta>_quality: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(16+11-1) /\<^sub>\<rat> sint (3329 :: 16 word)) \<le> 1/2^(2::nat)\<close>
    by eval
  have z_bound: \<open>\<bar>sint z\<bar> \<le> 2^(16-1-(2-(2::nat)))\<close>
    using sint_in_signed_range[of 16 z] by (simp, linarith)
  have len16: \<open>(16 :: nat) = LENGTH(16)\<close> by simp
  have N_sint: \<open>sint (3329 :: 16 word) = 3329\<close> by eval
  have thm1: \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint (3329 :: 16 word), 16+11-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
   and thm2: \<open>sint out = sint z mod\<^sup>\<plusminus> sint (3329 :: 16 word)\<close>
    unfolding out_def
    using barrett_red_refined_neon_word_correct
            [where 'a=16 and n=16 and \<alpha>=11 and \<delta>=2 and N=\<open>3329 :: 16 word\<close>
                and V=\<open>20159 :: 16 word\<close> and z=z,
             OF len16 V_eq N_std N_alpha1 N_alpha2 \<delta>_quality z_bound]
    by simp_all
  show \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>3329, 26, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
    using thm1 N_sint by simp
  show \<open>sint out = sint z mod\<^sup>\<plusminus> 3329\<close>
    using thm2 N_sint by simp
qed



text \<open>Specialisation to ML-DSA: \<^term>\<open>N = 8380417\<close>, \<^term>\<open>n = 32\<close>, \<^term>\<open>\<alpha> = 22\<close>, \<^term>\<open>\<delta> = 2\<close>.
For this modulus, the rounding-quality factor satisfies
\<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^53 /\<^sub>\<rat> 8380417) \<le> 1/4\<close>, so the canonical-output theorem applies for the full
signed 32-bit input range.\<close>

theorem barrett_red_refined_neon_word_correct_ml_dsa:
  fixes z :: \<open>32 word\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQDMULH t z 1074791297; \<comment> \<open>(@{lemma \<open>1074791297 = \<lfloor>2^(32 + 22 - 1) /\<^sub>\<rat> 8380417\<rceil>\<close> by eval})\<close>
                    SRSHR   q t #22;
                    MLS     r z q 8380417
                  \<guillemotright> in r\<close>
  
  shows \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>8380417, 53, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
        \<comment> \<open>abstract description: refined Barrett at radix \<open>2^53\<close>\<close>
    and \<open>sint out = sint z mod\<^sup>\<plusminus> 8380417\<close>
        \<comment> \<open>output is the signed canonical residue\<close>
proof -
  have V_eq: \<open>sint (1074791297 :: 32 word) = \<lfloor>2^(32+22-1) /\<^sub>\<rat> sint (8380417 :: 32 word)\<rceil>\<close>
    by eval
  have N_std: \<open>StandardModulus (sint (8380417 :: 32 word)) 32\<close>
    by unfold_locales eval+
  have N_alpha1: \<open>(2::int)^22 < sint (8380417 :: 32 word)\<close>
    by eval
  have N_alpha2: \<open>sint (8380417 :: 32 word) < (2::int)^(22+1)\<close>
    by eval
  have \<delta>_quality: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(32+22-1) /\<^sub>\<rat> sint (8380417 :: 32 word)) \<le> 1/2^(2::nat)\<close>
    by eval
  have z_bound: \<open>\<bar>sint z\<bar> \<le> 2^(32-1-(2-(2::nat)))\<close>
    using sint_in_signed_range[of 32 z] by (simp, linarith)
  have len32: \<open>(32 :: nat) = LENGTH(32)\<close> by simp
  have N_sint: \<open>sint (8380417 :: 32 word) = 8380417\<close> by eval
  have thm1: \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>sint (8380417 :: 32 word), 32+22-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
   and thm2: \<open>sint out = sint z mod\<^sup>\<plusminus> sint (8380417 :: 32 word)\<close>
    unfolding out_def
    using barrett_red_refined_neon_word_correct
            [where 'a=32 and n=32 and \<alpha>=22 and \<delta>=2 and N=\<open>8380417 :: 32 word\<close>
                and V=\<open>1074791297 :: 32 word\<close> and z=z,
             OF len32 V_eq N_std N_alpha1 N_alpha2 \<delta>_quality z_bound]
    by simp_all
  show \<open>sint out = bar\<^sup>\<plusminus>\<lbrakk>8380417, 53, \<lfloor>\<cdot>\<rceil>\<rbrakk> (sint z)\<close>
    using thm1 N_sint by simp
  show \<open>sint out = sint z mod\<^sup>\<plusminus> 8380417\<close>
    using thm2 N_sint by simp
qed

text \<open>We conclude with a counterexample showing that without the hypothesis
\<^term>\<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) \<le> 1/4\<close>, refined Barrett reduction only
yields canonical outputs for \<^term>\<open>\<bar>sint z\<bar> \<le> 2^(n-2)\<close>:\<close>

lemma refined_barrett_example_3947:
  defines \<open>n \<equiv> (16 :: nat)\<close>
      and \<open>\<alpha> \<equiv> (11 :: nat)\<close>
      and \<open>\<delta> \<equiv> (1 :: nat)\<close>
      and \<open>N \<equiv> (3947 :: 16 word)\<close>
      and \<open>V \<equiv> (17002 :: 16 word)\<close>
      and \<open>z \<equiv> (17762 :: 16 word)\<close>
  shows \<open>sint V = \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> sint N\<rceil>\<close>
    and \<open>StandardModulus (sint N) n\<close>
    and \<open>2^\<alpha> < sint N\<close> \<open>sint N < 2^(\<alpha>+1)\<close>
        \<comment>\<open>Assumptions of @{thm [source] barrett_red_refined_neon_word_correct} are satisfied,
           except for \<^term>\<open>\<bar>sint z\<bar> \<le> 2^(n-1-(2-\<delta>))\<close>: We only have \<^term>\<open>\<bar>sint z\<bar> \<le> 2^(n-1)\<close>.\<close>
    and \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) \<le> 1/2^\<delta>\<close>
        \<comment> \<open>... and only the guaranteed quality bound is available\<close>
    and \<open>\<bar>sint (let ASM \<guillemotleft>
                  SQDMULH t z V;
                  SRSHR   q t #\<alpha>;
                  MLS     r z q N
                \<guillemotright> in r)\<bar>\<^sub>\<rat> \<ge> sint N /\<^sub>\<rat> 2\<close>
        \<comment> \<open>output is \<^emph>\<open>not\<close> signed canonical\<close>
proof -
  show \<open>sint V = \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> sint N\<rceil>\<close>
    unfolding V_def n_def \<alpha>_def N_def by eval
  show \<open>StandardModulus (sint N) n\<close>
    unfolding N_def n_def by unfold_locales eval+
  show \<open>2^\<alpha> < sint N\<close>
    unfolding \<alpha>_def N_def by eval
  show \<open>sint N < 2^(\<alpha>+1)\<close>
    unfolding \<alpha>_def N_def by eval
  show \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, 2^(n+\<alpha>-1) /\<^sub>\<rat> sint N) \<le> 1/2^\<delta>\<close>
    unfolding n_def \<alpha>_def \<delta>_def N_def by eval
  show \<open>\<bar>sint (let ASM \<guillemotleft>
                  SQDMULH t z V;
                  SRSHR   q t #\<alpha>;
                  MLS     r z q N
                \<guillemotright> in r)\<bar>\<^sub>\<rat> \<ge> sint N /\<^sub>\<rat> 2\<close>
    unfolding N_def V_def z_def \<alpha>_def by eval
qed

end


