(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Barrett_Reduction
  imports Montgomery_Reduction
begin

chapter \<open>Barrett reduction and multiplication \label{ch:barrett_red}\<close>

text \<open>This chapter introduces the abstract Barrett reduction and multiplication
operators together with an approximation-error bound. Output absolute bounds are
deferred to \autoref{ch:barrett_montgomery}, where they follow sharply from the
Barrett--Montgomery bridge.\<close>

section \<open>Barrett reduction\<close>

text \<open>Barrett reduction \cite[\S 2.4.1]{NeonNTT} replaces division by
the modulus \<^term>\<open>N\<close> with a multiply-shift: with \<^term>\<open>R = (2::int)^n\<close> and \<^term>\<open>R > N\<close> and precomputed
\<open>\<lbrakk>R/N\<rbrakk>\<close>, the quotient \<^term>\<open>z/N\<close> is approximated as \<open>z\<sqdot>\<lbrakk>R/N\<rbrakk>/R\<close>, and the residue
recovered as \<open>z - N\<sqdot>\<lfloor>z\<sqdot>\<lbrakk>R/N\<rbrakk>/R\<rceil>\<close>.\<close>

text \<open>There are two variants, differing only in how the outer quotient is rounded: the
\emph{signed} variant applies round-to-nearest \<open>\<lfloor>\<cdot>\<rceil>\<close>, recovering \<^term>\<open>z mod\<^sup>\<plusminus> N\<close>;
the \emph{unsigned} variant applies floor \<open>\<lfloor>\<cdot>\<rfloor>\<close>, recovering \<^term>\<open>z mod\<^sup>+ N\<close>. Both
are parameterised by the inner approximation \<^term>\<open>f\<close> of \<^term>\<open>R /\<^sub>\<rat> N\<close>.\<close>

definition barrett_red_signed (\<open>bar\<^sup>\<plusminus> \<lbrakk>_,_,_\<rbrakk>\<close>) where
  \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z \<equiv> z - N * \<lfloor>z * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> 2^n\<rceil>\<close> for f ("\<lbrakk>_\<rbrakk>")

definition barrett_red_unsigned (\<open>bar\<^sup>+ \<lbrakk>_,_,_\<rbrakk>\<close>) where
  \<open>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z \<equiv> z - N * \<lfloor>z * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> 2^n\<rfloor>\<close> for f ("\<lbrakk>_\<rbrakk>")

text \<open>We bundle the standing assumptions of this and the next chapter into a
locale \<open>BarrettContext\<close> = \<open>StandardModulus\<close> (a positive odd modulus \<^term>\<open>N\<close> and a
splitting exponent \<^term>\<open>n\<close> with \<^term>\<open>R = (2::int)^n\<close> and \<^term>\<open>R > N\<close>) plus \<open>IntegerApproximation\<close> (an
integer approximation \<open>\<lbrakk>_\<rbrakk>\<close> of the rationals).\<close>

locale BarrettContext = StandardModulus + IntegerApproximation

text \<open>\cite[Fact~2]{NeonNTT} provides a coarse bound for the
approximation error between the signed variant and the canonical signed residue:\<close>

theorem (in BarrettContext) barrett_red_signed_fact2:
  shows \<open>\<bar>z mod\<^sup>\<plusminus> N - bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> N * \<lceil>\<bar>z\<bar> /\<^sub>\<rat> R\<rceil>\<close>
proof -
  define s :: rat where \<open>s = (f (R /\<^sub>\<rat> N))\<^sub>\<rat>\<close>
  define a :: rat where \<open>a = z /\<^sub>\<rat> N\<close>
  define b :: rat where \<open>b = z\<^sub>\<rat> * s / R\<^sub>\<rat>\<close>
  have approx: \<open>\<bar>R /\<^sub>\<rat> N - s\<bar> \<le> 1\<close>
    using f_approx unfolding is_int_approx_def s_def by simp
  have diff_eq: \<open>z mod\<^sup>\<plusminus> N - barrett_red_signed N n f z = N * (\<lfloor>b\<rceil> - \<lfloor>a\<rceil>)\<close>
    unfolding barrett_red_signed_def mod_approx_def a_def b_def s_def
    by (simp add: algebra_simps)
  have ba_diff_eq: \<open>b - a = z\<^sub>\<rat> * (s - R /\<^sub>\<rat> N) / R\<^sub>\<rat>\<close>
    unfolding a_def b_def by (simp add: field_simps)
  have e0: \<open>\<bar>z\<^sub>\<rat> * (s - R /\<^sub>\<rat> N) / R\<^sub>\<rat>\<bar> = \<bar>z\<^sub>\<rat> * (s - R /\<^sub>\<rat> N)\<bar> / \<bar>R\<^sub>\<rat>\<bar>\<close>
    by (simp add: abs_divide)
  have e1: \<open>\<bar>z\<^sub>\<rat> * (s - R /\<^sub>\<rat> N)\<bar> = \<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar>\<close>
    by (simp add: abs_mult)
  have ba_abs_eq: \<open>\<bar>b - a\<bar> = \<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar> / R\<^sub>\<rat>\<close>
    using ba_diff_eq e0 e1 by simp
  have approx': \<open>\<bar>s - R /\<^sub>\<rat> N\<bar> \<le> 1\<close> using approx by (simp add: abs_minus_commute)
  have iz_nn: \<open>0 \<le> \<bar>z\<^sub>\<rat>\<bar>\<close> by simp
  have prod_le: \<open>\<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar> \<le> \<bar>z\<^sub>\<rat>\<bar> * 1\<close>
    using approx' iz_nn by (rule mult_left_mono)
  have prod_le': \<open>\<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar> \<le> \<bar>z\<^sub>\<rat>\<bar>\<close> using prod_le by simp
  have abs_iz: \<open>\<bar>z\<^sub>\<rat>\<bar> = \<bar>z\<bar>\<^sub>\<rat>\<close> by simp
  have ba_bound1: \<open>\<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar> / R\<^sub>\<rat> \<le> \<bar>z\<^sub>\<rat>\<bar> / R\<^sub>\<rat>\<close>
    using prod_le' by (simp add: divide_right_mono)
  have ba_bound: \<open>\<bar>b - a\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> R\<close>
  proof -
    have \<open>\<bar>b - a\<bar> = \<bar>z\<^sub>\<rat>\<bar> * \<bar>s - R /\<^sub>\<rat> N\<bar> / R\<^sub>\<rat>\<close> by (rule ba_abs_eq)
    also have \<open>\<dots> \<le> \<bar>z\<^sub>\<rat>\<bar> / R\<^sub>\<rat>\<close> by (rule ba_bound1)
    also have \<open>\<dots> = \<bar>z\<bar> /\<^sub>\<rat> R\<close> using abs_iz by simp
    finally show ?thesis .
  qed
  have round_diff_lem: \<open>\<And>x y::rat. x \<le> y \<Longrightarrow> \<lfloor>y\<rceil> - \<lfloor>x\<rceil> \<le> \<lceil>y - x\<rceil>\<close>
  proof -
    fix x y :: rat
    assume xy: \<open>x \<le> y\<close>
    have d_le: \<open>y - x \<le> \<lceil>y - x\<rceil>\<^sub>\<rat>\<close> by (rule le_of_int_ceiling)
    from d_le have step1: \<open>y \<le> x + \<lceil>y - x\<rceil>\<^sub>\<rat>\<close> by linarith
    have step2: \<open>y + 1/2 \<le> (x + 1/2) + \<lceil>y - x\<rceil>\<^sub>\<rat>\<close> using step1 by linarith
    from step2 have flo_le: \<open>\<lfloor>y + 1/2\<rfloor> \<le> \<lfloor>(x + 1/2) + \<lceil>y - x\<rceil>\<^sub>\<rat>\<rfloor>\<close>
      by (rule floor_mono)
    have flo_eq: \<open>\<lfloor>(x + 1/2) + \<lceil>y - x\<rceil>\<^sub>\<rat>\<rfloor> = \<lfloor>x + 1/2\<rfloor> + \<lceil>y - x\<rceil>\<close>
      using floor_add_int[of \<open>x + 1/2\<close> \<open>\<lceil>y - x\<rceil>\<close>] by simp
    from flo_le flo_eq have \<open>\<lfloor>y\<rceil> \<le> \<lfloor>x\<rceil> + \<lceil>y - x\<rceil>\<close> by (simp add: round_def)
    thus \<open>\<lfloor>y\<rceil> - \<lfloor>x\<rceil> \<le> \<lceil>y - x\<rceil>\<close> by simp
  qed
  have round_diff_bound: \<open>\<bar>\<lfloor>b\<rceil> - \<lfloor>a\<rceil>\<bar> \<le> \<lceil>\<bar>b - a\<bar>\<rceil>\<close>
  proof (cases \<open>a \<le> b\<close>)
    case True
    have h1: \<open>\<lfloor>b\<rceil> - \<lfloor>a\<rceil> \<le> \<lceil>b - a\<rceil>\<close> using round_diff_lem[OF True] .
    have h2: \<open>\<lfloor>a\<rceil> - \<lfloor>b\<rceil> \<le> 0\<close> using True round_mono by simp
    have h3: \<open>\<lceil>\<bar>b - a\<bar>\<rceil> = \<lceil>b - a\<rceil>\<close> using True by simp
    have h4: \<open>0 \<le> \<lceil>b - a\<rceil>\<close> using True by simp
    show ?thesis using h1 h2 h3 h4 by linarith
  next
    case False
    hence ba: \<open>b \<le> a\<close> by simp
    have h1: \<open>\<lfloor>a\<rceil> - \<lfloor>b\<rceil> \<le> \<lceil>a - b\<rceil>\<close> using round_diff_lem[OF ba] .
    have h2: \<open>\<lfloor>b\<rceil> - \<lfloor>a\<rceil> \<le> 0\<close> using ba round_mono by simp
    have h3: \<open>\<lceil>\<bar>b - a\<bar>\<rceil> = \<lceil>a - b\<rceil>\<close> using ba by (simp add: abs_minus_commute)
    have h4: \<open>0 \<le> \<lceil>a - b\<rceil>\<close> using ba by simp
    show ?thesis using h1 h2 h3 h4 by linarith
  qed
  have ceil_le: \<open>\<lceil>\<bar>b - a\<bar>\<rceil> \<le> \<lceil>\<bar>z\<bar> /\<^sub>\<rat> R\<rceil>\<close>
    using ba_bound by (rule ceiling_mono)
  have abs_diff_bound: \<open>\<bar>z mod\<^sup>\<plusminus> N - barrett_red_signed N n f z\<bar> \<le> N * \<lceil>\<bar>z\<bar> /\<^sub>\<rat> R\<rceil>\<close>
  proof -
    have e: \<open>\<bar>z mod\<^sup>\<plusminus> N - barrett_red_signed N n f z\<bar> = N * \<bar>\<lfloor>b\<rceil> - \<lfloor>a\<rceil>\<bar>\<close>
      using diff_eq Npos by (simp add: abs_mult)
    have N_nn: \<open>N \<ge> 0\<close> using Npos by simp
    have \<open>N * \<bar>\<lfloor>b\<rceil> - \<lfloor>a\<rceil>\<bar> \<le> N * \<lceil>\<bar>b - a\<bar>\<rceil>\<close>
      using round_diff_bound N_nn by (rule mult_left_mono)
    also have \<open>\<dots> \<le> N * \<lceil>\<bar>z\<bar> /\<^sub>\<rat> R\<rceil>\<close>
      using ceil_le N_nn by (rule mult_left_mono)
    finally show ?thesis using e by simp
  qed
  show ?thesis
    using abs_diff_bound by simp
qed

section \<open>Barrett multiplication\<close>

text \<open>In NTTs one operand of each modular multiplication is a fixed twiddle.
Barrett multiplication \cite[\S 3.1.2]{NeonNTT} folds \<^term>\<open>b\<close> into the
magic constant \<open>\<lbrakk>b\<sqdot>R/N\<rbrakk>\<close>, collapsing reduction to a single multiply-shift
\<open>a\<sqdot>\<lbrakk>b\<sqdot>R/N\<rbrakk>/R\<close> with representative \<open>a\<sqdot>b - N\<sqdot>\<lfloor>a\<sqdot>\<lbrakk>b\<sqdot>R/N\<rbrakk>/R\<rceil>\<close>.\<close>

definition barrett_mul_signed (\<open>barM\<^sup>\<plusminus> \<lbrakk>_,_,_\<rbrakk>\<langle>_,_\<rangle>\<close>) where
  \<open>barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> \<equiv> a * b - N * \<lfloor>a * \<lbrakk>b * 2^n /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> 2^n\<rceil>\<close> for f ("\<lbrakk>_\<rbrakk>")

definition barrett_mul_unsigned (\<open>barM\<^sup>+ \<lbrakk>_,_,_\<rbrakk>\<langle>_,_\<rangle>\<close>) where
  \<open>barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> \<equiv> a * b - N * \<lfloor>a * \<lbrakk>b * 2^n /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> 2^n\<rfloor>\<close> for f ("\<lbrakk>_\<rbrakk>")

text\<open>Barrett reduction is recovered as Barrett multiplication with \<^term>\<open>b=1\<close>:\<close>

lemma barrett_red_as_mul:
  shows \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>z, 1\<rangle>\<close>
    and \<open>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z = barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>z, 1\<rangle>\<close>
  by (simp_all add: barrett_red_signed_def barrett_mul_signed_def
                    barrett_red_unsigned_def barrett_mul_unsigned_def)


section \<open>Refined Barrett reduction\<close>

text \<open>The output quality of Barrett reduction improves as the radix \<^term>\<open>2^n\<close>
grows, so one is naturally led to consider radices that fall
\<^emph>\<open>between\<close> word boundaries. This section establishes a way to compute such
reductions in a two-step fashion: a word-sized truncating high-half multiply,
followed by a rounding right shift on the lane-width word.\<close>

definition barrett_red_refined :: \<open>int \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int\<close> where
  \<open>barrett_red_refined N n \<alpha> V z \<equiv>
     let t = (2 * z * V) div 2^n;
         q = \<lfloor>t /\<^sub>\<rat> 2^\<alpha>\<rceil>
     in z - q * N\<close>

text \<open>Key identity: for an integer \<^term>\<open>q :: int\<close>, the value \<^term>\<open>q /\<^sub>\<rat> 2^k + 1/\<^sub>\<rat>2\<close>
has denominator \<^term>\<open>2^k\<close>, so adding a perturbation less than \<open>1/2^k\<close> cannot
cross an integer boundary.\<close>

lemma floor_then_round_shift:
  fixes x :: int and n k :: nat
  assumes \<open>k \<ge> 1\<close>
  shows \<open>\<lfloor>(x div 2^n)\<^sub>\<rat> / (2^k)\<^sub>\<rat>\<rceil> = \<lfloor>x /\<^sub>\<rat> 2^(n+k)\<rceil>\<close>
proof -
  define q where \<open>q = x div 2^n\<close>
  define r where \<open>r = x mod 2^n\<close>
  have xqr: \<open>x = q * 2^n + r\<close> unfolding q_def r_def by (rule div_mult_mod_eq[symmetric])
  have r_ge: \<open>0 \<le> r\<close> unfolding r_def by simp
  have r_lt: \<open>r < 2^n\<close> unfolding r_def by simp
  have q_eq: \<open>x div 2^n = q\<close> unfolding q_def by simp
  have k_pos: \<open>(2::int)^k > 0\<close> by simp
  have nk_pos: \<open>(2::int)^(n+k) > 0\<close> by simp
  have two_k_pos: \<open>(2::int) * 2^k > 0\<close> by simp
  have two_nk_pos: \<open>(2::int) * 2^(n+k) > 0\<close> by simp
  have n_pos: \<open>(2::int)^n > 0\<close> by simp
  have lhs_eq: \<open>\<lfloor>(of_int q :: rat) / of_int ((2::int)^k)\<rceil> = (2*q + 2^k) div (2 * 2^k)\<close>
  proof -
    have step1: \<open>\<lfloor>(of_int q :: rat) / of_int ((2::int)^k)\<rceil> = \<lfloor>(of_int q :: rat) / of_int ((2::int)^k) + 1/2\<rfloor>\<close>
      by (simp add: round_def)
    have step2: \<open>(of_int q :: rat) / of_int ((2::int)^k) + 1/2 = of_int (2*q + 2^k) / (of_int (2 * 2^k) :: rat)\<close>
      using k_pos by (simp add: field_simps of_int_mult)
    have step3: \<open>\<lfloor>of_int (2*q + 2^k) / (of_int (2 * 2^k) :: rat)\<rfloor> = (2*q + 2^k) div (2 * 2^k)\<close>
      using two_k_pos floor_divide_of_int_eq[of \<open>2*q + 2^k\<close> \<open>2 * 2^k\<close>] by simp
    show ?thesis using step1 step2 step3 by simp
  qed
  have rhs_eq: \<open>\<lfloor>(of_int x :: rat) / of_int ((2::int)^(n+k))\<rceil> = (2*x + 2^(n+k)) div (2 * 2^(n+k))\<close>
  proof -
    have step1: \<open>\<lfloor>(of_int x :: rat) / of_int ((2::int)^(n+k))\<rceil> = \<lfloor>(of_int x :: rat) / of_int ((2::int)^(n+k)) + 1/2\<rfloor>\<close>
      by (simp add: round_def)
    have step2: \<open>(of_int x :: rat) / of_int ((2::int)^(n+k)) + 1/2 = of_int (2*x + 2^(n+k)) / (of_int (2 * 2^(n+k)) :: rat)\<close>
      using nk_pos by (simp add: field_simps of_int_mult)
    have step3: \<open>\<lfloor>of_int (2*x + 2^(n+k)) / (of_int (2 * 2^(n+k)) :: rat)\<rfloor> = (2*x + 2^(n+k)) div (2 * 2^(n+k))\<close>
      using two_nk_pos floor_divide_of_int_eq[of \<open>2*x + 2^(n+k)\<close> \<open>2 * 2^(n+k)\<close>] by simp
    show ?thesis using step1 step2 step3 by simp
  qed
  have scale: \<open>(2*q + 2^k) div (2 * 2^k) = (2*q + 2^k) * 2^n div ((2 * 2^k) * 2^n)\<close>
    using n_pos div_mult_mult2[of \<open>2^n\<close> \<open>2*q + 2^k\<close> \<open>2*2^k\<close>] by simp
  have denom_eq: \<open>(2::int) * 2^k * 2^n = 2 * 2^(n+k)\<close>
    by (simp add: power_add)
  have num_eq: \<open>(2*q + 2^k) * (2::int)^n = 2*x - 2*r + 2^(n+k)\<close>
    using xqr by (simp add: algebra_simps power_add)
  have lhs_as_div: \<open>(2*q + 2^k) div (2 * 2^k) = (2*x - 2*r + 2^(n+k)) div (2 * 2^(n+k))\<close>
    using scale num_eq denom_eq by simp
  have key: \<open>(2*x - 2*r + 2^(n+k)) div (2 * 2^(n+k)) = (2*x + 2^(n+k)) div (2 * 2^(n+k))\<close>
  proof -
    define A where \<open>A = 2*x - 2*r + (2::int)^(n+k)\<close>
    define D where \<open>D = (2::int) * 2^(n+k)\<close>
    have D_pos: \<open>D > 0\<close> unfolding D_def by simp
    have rhs_split: \<open>2*x + (2::int)^(n+k) = A + 2*r\<close>
      unfolding A_def by simp
    have two_r_ge: \<open>0 \<le> 2*r\<close> using r_ge by simp
    have two_r_lt_D: \<open>2*r < D\<close>
    proof -
      have \<open>2*r < 2 * 2^n\<close> using r_lt by simp
      also have \<open>2 * (2::int)^n \<le> 2 * 2^(n+k)\<close>
        using assms by (simp add: power_add)
      finally show ?thesis unfolding D_def .
    qed
    have A_eq: \<open>A = (2*q + 2^k) * 2^n\<close>
      unfolding A_def using xqr by (simp add: algebra_simps power_add)
    have D_eq: \<open>D = (2*2^k) * (2::int)^n\<close>
      unfolding D_def by (simp add: power_add)
    have A_mod_D: \<open>A mod D = ((2*q + 2^k) mod (2*2^k)) * 2^n\<close>
      using A_eq D_eq mod_mult_mult2[of \<open>2*q + 2^k\<close> \<open>2^n\<close> \<open>2*2^k\<close>] by simp
    define m where \<open>m = (2*q + (2::int)^k) mod (2 * 2^k)\<close>
    have m_eq: \<open>A mod D = m * 2^n\<close> using A_mod_D unfolding m_def by simp
    have m_ge: \<open>m \<ge> 0\<close> unfolding m_def using two_k_pos by simp
    have m_lt: \<open>m < 2 * 2^k\<close> unfolding m_def using two_k_pos by simp
    have m_even: \<open>even m\<close>
    proof -
      have \<open>even ((2*q + (2::int)^k) mod (2 * 2^k)) = even (2*q + (2::int)^k)\<close>
        using dvd_mod_iff[of 2 \<open>2*2^k\<close> \<open>2*q + 2^k\<close>] by simp
      moreover have \<open>even (2*q + (2::int)^k)\<close>
        using assms by simp
      ultimately show ?thesis unfolding m_def by simp
    qed
    have m_le: \<open>m \<le> 2*2^k - 2\<close> using m_lt m_even by presburger
    have mod_bound: \<open>A mod D + 2*r < D\<close>
    proof -
      have \<open>m * 2^n \<le> (2*2^k - 2) * 2^n\<close>
        using m_le n_pos by (intro mult_right_mono) auto
      also have \<open>\<dots> = D - 2 * 2^n\<close> unfolding D_eq by (simp add: algebra_simps)
      finally have \<open>A mod D \<le> D - 2*2^n\<close> using m_eq by simp
      moreover have \<open>2*r < 2*2^n\<close> using r_lt by simp
      ultimately show ?thesis by linarith
    qed
    have div_eq: \<open>(A + 2*r) div D = A div D\<close>
    proof -
      have \<open>(A + 2*r) div D = A div D + (2*r) div D + (A mod D + (2*r) mod D) div D\<close>
        using div_add1_eq[of A \<open>2*r\<close> D] by simp
      moreover have \<open>(2*r) div D = 0\<close>
        using two_r_ge two_r_lt_D D_pos by (simp add: div_pos_pos_trivial)
      moreover have \<open>(2*r) mod D = 2*r\<close>
        using two_r_ge two_r_lt_D D_pos by (simp add: mod_pos_pos_trivial)
      moreover have \<open>(A mod D + 2*r) div D = 0\<close>
      proof -
        have \<open>A mod D + 2*r < D\<close> by (rule mod_bound)
        moreover have \<open>A mod D + 2*r \<ge> 0\<close>
          using D_pos pos_mod_sign[of D A] two_r_ge by simp
        ultimately show ?thesis using D_pos by (simp add: div_pos_pos_trivial)
      qed
      ultimately show ?thesis by simp
    qed
    show ?thesis using rhs_split div_eq unfolding A_def D_def by simp
  qed
  show ?thesis using lhs_eq rhs_eq lhs_as_div key q_eq by simp
qed

text \<open>The refined kernel equals Barrett reduction at the effective radix
\<^term>\<open>2^(n+\<alpha>-1) :: int\<close>.\<close>

lemma barrett_red_refined_eq:
  assumes \<open>\<alpha> \<ge> 1\<close>
  assumes \<open>V = \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> N\<rceil>\<close>
  shows \<open>barrett_red_refined N n \<alpha> V z = bar\<^sup>\<plusminus>\<lbrakk>N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> z\<close>
proof -
  have key: \<open>\<lfloor>((2*z*V) div 2^n)\<^sub>\<rat> / (2^\<alpha>)\<^sub>\<rat>\<rceil> = \<lfloor>(2*z*V) /\<^sub>\<rat> 2^(n+\<alpha>)\<rceil>\<close>
    by (rule floor_then_round_shift[OF assms(1)])
  have power_eq: \<open>(2::int)^(n+\<alpha>) = 2 * 2^(n+\<alpha>-1)\<close>
    using assms(1) by (simp add: power_eq_if)
  have \<open>barrett_red_refined N n \<alpha> V z = z - \<lfloor>(2*z*V) /\<^sub>\<rat> 2^(n+\<alpha>)\<rceil> * N\<close>
    unfolding barrett_red_refined_def Let_def
    using key by simp
  also have \<open>\<dots> = z - \<lfloor>(z*V) /\<^sub>\<rat> 2^(n+\<alpha>-1)\<rceil> * N\<close>
  proof -
    have \<open>(2*z*V :: int) /\<^sub>\<rat> 2^(n+\<alpha>) = (z*V) /\<^sub>\<rat> 2^(n+\<alpha>-1)\<close>
      using power_eq by (simp add: of_int_mult)
    thus ?thesis by simp
  qed
  also have \<open>\<dots> = z - N * \<lfloor>z\<^sub>\<rat> * V\<^sub>\<rat> / (2^(n+\<alpha>-1))\<^sub>\<rat>\<rceil>\<close>
    by (simp add: of_int_mult algebra_simps)
  also have \<open>\<dots> = z - N * \<lfloor>z\<^sub>\<rat> * \<lfloor>2^(n+\<alpha>-1) /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> / (2^(n+\<alpha>-1))\<^sub>\<rat>\<rceil>\<close>
    using assms(2) by simp
  also have \<open>\<dots> = bar\<^sup>\<plusminus>\<lbrakk>N, n+\<alpha>-1, \<lfloor>\<cdot>\<rceil>\<rbrakk> z\<close>
    unfolding barrett_red_signed_def by simp
  finally show ?thesis .
qed

text \<open>As in the standard Barrett section, output bounds are deferred to the
Barrett--Montgomery bridge chapter (\autoref{ch:barrett_montgomery}); the
instantiation as the Neon \<^verbatim>\<open>SQDMULH\<close>/\<^verbatim>\<open>SRSHR\<close>/\<^verbatim>\<open>MLS\<close> sequence
(\cite[Algorithm~11]{NeonNTT}) is deferred to \autoref{ch:asm_barrett}.\<close>

end


