(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Montgomery_Reduction
  imports Integer_Approximation "HOL-Number_Theory.Cong"
begin

chapter \<open>Montgomery reduction and multiplication \label{ch:montgomery_red}\<close>

text \<open>In this chapter, we discuss Montgomery reduction and Montgomery multiplication
along the lines of \cite{NeonNTT} and establish their correctness
and bounds. The idea of Montgomery reduction is to replace an expensive division
by \<^term>\<open>N\<close> with a division by \<^term>\<open>R = 2^n\<close>, by efficiently adjusting a representative
of \<^term>\<open>z mod N\<close> to become divisible by \<^term>\<open>2^n\<close>.\<close>

section %internal \<open>Modular inverse\<close>

text %internal \<open>We introduce \<open>N\<^sup>-\<^sup>1 mod 2^n\<close>, the canonical unsigned representative of
\<open>N\<^sup>-\<^sup>1\<close> in \<open>[0, 2^n)\<close>, so abstract theorems depend only on \<open>(N, n)\<close>. The
negated inverse \<open>-N\<^sup>-\<^sup>1\<close> for the additive variants is \<open>(- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>.\<close>

definition %internal mod_inverse :: \<open>int \<Rightarrow> int \<Rightarrow> int\<close> ("_\<^sup>-\<^sup>1 mod _" [79, 79] 79) where
  \<open>N\<^sup>-\<^sup>1 mod R \<equiv> THE T. 0 \<le> T \<and> T < R \<and> (N * T) mod R = 1 mod R\<close>

lemma %internal mod_inverse_unique:
  fixes N :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>odd N\<close>
  shows \<open>\<exists>!T. 0 \<le> T \<and> T < 2^n \<and> (N * T) mod 2^n = 1 mod 2^n\<close>
proof -
  let ?m = \<open>(2::int)^n\<close>
  have copr: \<open>coprime N ?m\<close>
    using assms(2) by (simp add: coprime_power_right_iff)
  obtain x where x: \<open>[N * x = 1] (mod ?m)\<close>
    using cong_solve_coprime_int[OF copr] by blast
  obtain T where T: \<open>0 \<le> T\<close> \<open>T < ?m\<close> \<open>[x = T] (mod ?m)\<close>
    using cong_less_unique_int[of ?m x] by auto
  have T_eq: \<open>(N * T) mod ?m = 1 mod ?m\<close>
    using x T(3) unfolding cong_def by (metis mod_mult_right_eq)
  show ?thesis
  proof (rule ex1I[of _ T])
    show \<open>0 \<le> T \<and> T < ?m \<and> (N * T) mod ?m = 1 mod ?m\<close> using T T_eq by simp
  next
    fix T'
    assume H: \<open>0 \<le> T' \<and> T' < ?m \<and> (N * T') mod ?m = 1 mod ?m\<close>
    have \<open>[N * T = N * T'] (mod ?m)\<close> using T_eq H unfolding cong_def by simp
    hence \<open>[T = T'] (mod ?m)\<close> using cong_mult_lcancel[OF copr] by simp
    thus \<open>T' = T\<close>
      using cong_less_imp_eq_int[of T' ?m T] T H by (simp add: cong_sym)
  qed
qed

text %internal \<open>Downstream arguments use \<open>mod_inverse_correct\<close> with the substitution lemmas
below, which swap in any explicit \<open>T\<close> satisfying
\<^latex>\<open>$N \cdot T \equiv \pm 1 \pmod{R}$\<close>.\<close>

lemma %internal mod_inverse_correct:
  fixes N :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>odd N\<close>
  shows \<open>0 \<le> N\<^sup>-\<^sup>1 mod 2^n\<close>
    and \<open>N\<^sup>-\<^sup>1 mod 2^n < 2^n\<close>
    and \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
proof -
  let ?P = \<open>\<lambda>T. 0 \<le> T \<and> T < 2^n \<and> (N * T) mod 2^n = 1 mod 2^n\<close>
  have \<open>\<exists>!T. ?P T\<close> using mod_inverse_unique[OF assms] .
  hence h: \<open>?P (N\<^sup>-\<^sup>1 mod 2^n)\<close>
    unfolding mod_inverse_def using theI'[of ?P] by blast
  show \<open>0 \<le> N\<^sup>-\<^sup>1 mod 2^n\<close> using h by simp
  show \<open>(N\<^sup>-\<^sup>1 mod 2^n) < 2^n\<close> using h by simp
  show \<open>(N * N\<^sup>-\<^sup>1 mod 2^n) mod 2^n = 1 mod 2^n\<close> using h by simp
qed

lemma %internal mod_inverse_idem [simp]:
  assumes \<open>n > 0\<close> and \<open>odd N\<close>
  shows \<open>(N\<^sup>-\<^sup>1 mod 2^n) mod 2^n = N\<^sup>-\<^sup>1 mod 2^n\<close>
  using mod_inverse_correct(1)[OF assms] mod_inverse_correct(2)[OF assms]
  by simp

lemma %internal mod_inverse_neg_idem [simp]:
  assumes \<open>n > 0\<close> and \<open>odd N\<close>
  shows \<open>((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n) mod 2^n = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  by (simp add: mod_mod_trivial)

text %internal \<open>Both reductions are invariant under replacing \<^term>\<open>T\<close> by a congruent representative
mod \<^term>\<open>2^n\<close>, since \<^term>\<open>round\<close> and \<^term>\<open>floor\<close> are shift-compatible (\autoref{ch:integer_approx}).\<close>

lemma %internal mod_approx_smod_cong:
  fixes z T1 T2 :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>T1 mod 2^n = T2 mod 2^n\<close>
  shows \<open>(z * T1) mod\<^sup>\<plusminus> 2^n = (z * T2) mod\<^sup>\<plusminus> 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have eq: \<open>(z * T1) mod ?R = (z * T2) mod ?R\<close>
    using assms(2) by (metis mod_mult_right_eq)
  hence dvd: \<open>?R dvd (z * T1 - z * T2)\<close>
    by (simp add: mod_eq_dvd_iff)
  then obtain k where k_eq: \<open>z * T1 - z * T2 = ?R * k\<close>
    using dvd_def by blast
  hence k_eq': \<open>z * T1 = z * T2 + ?R * k\<close> by linarith
  have \<open>(z * T1) mod\<^sup>\<plusminus> ?R = (z * T2 + ?R * k) mod\<^sup>\<plusminus> ?R\<close>
    using k_eq' by simp
  also have \<open>\<dots> = (z * T2) mod\<^sup>\<plusminus> ?R\<close>
    using mod_approx_shift[OF shift_compat_round R_pos, of \<open>z*T2\<close> k] .
  finally show ?thesis .
qed

lemma %internal mod_approx_umod_cong:
  fixes z T1 T2 :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>T1 mod 2^n = T2 mod 2^n\<close>
  shows \<open>(z * T1) mod\<^sup>+ 2^n = (z * T2) mod\<^sup>+ 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have eq: \<open>(z * T1) mod ?R = (z * T2) mod ?R\<close>
    using assms(2) by (metis mod_mult_right_eq)
  hence dvd: \<open>?R dvd (z * T1 - z * T2)\<close>
    by (simp add: mod_eq_dvd_iff)
  then obtain k where k_eq: \<open>z * T1 - z * T2 = ?R * k\<close>
    using dvd_def by blast
  hence k_eq': \<open>z * T1 = z * T2 + ?R * k\<close> by linarith
  have \<open>(z * T1) mod\<^sup>+ ?R = (z * T2 + ?R * k) mod\<^sup>+ ?R\<close>
    using k_eq' by simp
  also have \<open>\<dots> = (z * T2) mod\<^sup>+ ?R\<close>
    using mod_approx_shift[OF shift_compat_floor R_pos, of \<open>z*T2\<close> k] .
  finally show ?thesis .
qed

lemma %internal mod_inverse_alt:
  fixes N T :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>odd N\<close> and \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>T mod 2^n = N\<^sup>-\<^sup>1 mod 2^n\<close>
proof -
  have copr: \<open>coprime N ((2::int)^n)\<close>
    using \<open>odd N\<close> by (simp add: coprime_power_right_iff)
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3)[OF assms(1) assms(2)] .
  have \<open>[N * T = N * (N\<^sup>-\<^sup>1 mod 2^n)] (mod 2^n)\<close>
    using assms(3) inv unfolding cong_def by simp
  hence \<open>[T = N\<^sup>-\<^sup>1 mod 2^n] (mod 2^n)\<close>
    using cong_mult_lcancel[OF copr, of T \<open>N\<^sup>-\<^sup>1 mod 2^n\<close>] by simp
  hence \<open>T mod 2^n = (N\<^sup>-\<^sup>1 mod 2^n) mod 2^n\<close>
    unfolding cong_def .
  also have \<open>(N\<^sup>-\<^sup>1 mod 2^n) mod 2^n = N\<^sup>-\<^sup>1 mod 2^n\<close>
    using mod_inverse_correct(1)[OF assms(1) assms(2)]
          mod_inverse_correct(2)[OF assms(1) assms(2)]
    by simp
  finally show ?thesis .
qed

lemma %internal mod_inverse_neg_alt:
  fixes N T :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>odd N\<close> and \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>T mod 2^n = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
proof -
  have copr: \<open>coprime N ((2::int)^n)\<close>
    using \<open>odd N\<close> by (simp add: coprime_power_right_iff)
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3)[OF assms(1) assms(2)] .
  have ne: \<open>(N * (- (N\<^sup>-\<^sup>1 mod 2^n))) mod 2^n = (- 1) mod 2^n\<close>
    using inv by (metis mod_minus_eq mult_minus_right)
  have \<open>[N * T = N * (- (N\<^sup>-\<^sup>1 mod 2^n))] (mod 2^n)\<close>
    using assms(3) ne unfolding cong_def by simp
  hence \<open>[T = - (N\<^sup>-\<^sup>1 mod 2^n)] (mod 2^n)\<close>
    using cong_mult_lcancel[OF copr, of T \<open>- (N\<^sup>-\<^sup>1 mod 2^n)\<close>] by simp
  thus ?thesis unfolding cong_def by simp
qed

text \<open>Inside \<^locale>\<open>OddModulus\<close>, the side conditions
\<^term>\<open>n > 0\<close> and \<^term>\<open>odd N\<close> are inherited from the locale, and the
modulus \<^term>\<open>2^n\<close> is exposed as the abbreviation \<^term>\<open>R\<close>.\<close>

lemma %internal (in OddModulus) mod_inverse_correct [simp]:
  shows \<open>0 \<le> N\<^sup>-\<^sup>1 mod R\<close>
    and \<open>N\<^sup>-\<^sup>1 mod R < R\<close>
    and \<open>(N * (N\<^sup>-\<^sup>1 mod R)) mod R = 1 mod R\<close>
  using mod_inverse_correct[OF npos Nodd] by simp_all

lemma %internal (in OddModulus) mod_inverse_neg_correct:
  \<open>(N * ((- (N\<^sup>-\<^sup>1 mod R)) mod R)) mod R = (- 1) mod R\<close>
  using mod_inverse_correct(3)
  by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)

section \<open>Montgomery reduction\<close>

text \<open>Following \cite[\S2.4.2, Algorithm~2]{NeonNTT}, we formalise Montgomery
reduction along two independent axes: \emph{additive} vs \emph{subtractive}
(\<^term>\<open>T = N\<^sup>-\<^sup>1 mod R\<close> with \<^term>\<open>z - k*N\<close>, or \<^term>\<open>T = -N\<^sup>-\<^sup>1 mod R\<close> with \<^term>\<open>z + k*N\<close>), and
\emph{signed} (\<open>\<^sup>\<plusminus>\<close>) vs \emph{unsigned} (\<open>\<^sup>+\<close>) twist for the inner residue
\<^term>\<open>k = (z*T) mod R\<close>. Each reduction maps \<^term>\<open>z\<close> to a representative of \<open>z\<sqdot>R\<^sup>-\<^sup>1\<close> in \<open>\<int>\<^sub>N\<close>,
where \<^term>\<open>R = 2^n\<close>; the canonical inverse \<open>\<plusminus>N\<^sup>-\<^sup>1\<close> is supplied via the notation \<^term>\<open>N\<^sup>-\<^sup>1 mod 2^n\<close>.\<close>

definition mont_sub_signed (\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<close>) where
  \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z \<equiv> (z - ((z * (N\<^sup>-\<^sup>1 mod 2^n)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close> for N

definition mont_add_signed (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z \<equiv> (z + ((z * (- (N\<^sup>-\<^sup>1 mod 2^n) mod 2^n)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>

definition mont_add_unsigned (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>_,_\<rbrakk>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z \<equiv> (z + ((z * (- (N\<^sup>-\<^sup>1 mod 2^n) mod 2^n)) mod\<^sup>+ 2^n) * N) div 2^n\<close>

definition mont_sub_unsigned (\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+ \<lbrakk>_,_\<rbrakk>\<close>) where
  \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z \<equiv> (z - ((z * (N\<^sup>-\<^sup>1 mod 2^n)) mod\<^sup>+ 2^n) * N) div 2^n\<close>

subsection %internal \<open>Computational expressions\<close>

text %internal \<open>Each operator equals the same expression with any \<^latex>\<open>$T \equiv \pm N^{-1} \pmod{R}$\<close>
substituted for the canonical \<^term>\<open>N\<^sup>-\<^sup>1 mod 2^n\<close>; downstream reasoning uses this
user-supplied \<^term>\<open>T\<close>.\<close>

lemma %internal (in OddModulus) mont_unfold:
  shows mont_sub_signed_unfold:
    \<open>(N * T) mod 2^n = 1 mod 2^n
       \<Longrightarrow> mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
  and mont_add_signed_unfold:
    \<open>(N * T) mod 2^n = (- 1) mod 2^n
       \<Longrightarrow> mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
  and mont_add_unsigned_unfold:
    \<open>(N * T) mod 2^n = (- 1) mod 2^n
       \<Longrightarrow> mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
  and mont_sub_unsigned_unfold:
    \<open>(N * T) mod 2^n = 1 mod 2^n
       \<Longrightarrow> mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
proof -
  let ?Tpos = \<open>N\<^sup>-\<^sup>1 mod 2^n\<close>
  let ?Tneg = \<open>(- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  show \<open>(N * T) mod 2^n = 1 mod 2^n
          \<Longrightarrow> mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
  proof -
    assume T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
    have \<open>T mod 2^n = ?Tpos mod 2^n\<close>
      using mod_inverse_alt[OF npos Nodd T_inv]
            mod_inverse_idem[OF npos Nodd] by simp
    hence \<open>(z * T) mod\<^sup>\<plusminus> 2^n = (z * ?Tpos) mod\<^sup>\<plusminus> 2^n\<close>
      using mod_approx_smod_cong[OF npos, of T ?Tpos z] by simp
    thus ?thesis unfolding mont_sub_signed_def by simp
  qed
  show \<open>(N * T) mod 2^n = (- 1) mod 2^n
          \<Longrightarrow> mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
  proof -
    assume T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
    have \<open>T mod 2^n = ?Tneg mod 2^n\<close>
      using mod_inverse_neg_alt[OF npos Nodd T_inv] by simp
    hence \<open>(z * T) mod\<^sup>\<plusminus> 2^n = (z * ?Tneg) mod\<^sup>\<plusminus> 2^n\<close>
      using mod_approx_smod_cong[OF npos, of T ?Tneg z] by simp
    thus ?thesis unfolding mont_add_signed_def by simp
  qed
  show \<open>(N * T) mod 2^n = (- 1) mod 2^n
          \<Longrightarrow> mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
  proof -
    assume T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
    have \<open>T mod 2^n = ?Tneg mod 2^n\<close>
      using mod_inverse_neg_alt[OF npos Nodd T_inv] by simp
    hence \<open>(z * T) mod\<^sup>+ 2^n = (z * ?Tneg) mod\<^sup>+ 2^n\<close>
      using mod_approx_umod_cong[OF npos, of T ?Tneg z] by simp
    thus ?thesis unfolding mont_add_unsigned_def by simp
  qed
  show \<open>(N * T) mod 2^n = 1 mod 2^n
          \<Longrightarrow> mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
  proof -
    assume T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
    have \<open>T mod 2^n = ?Tpos mod 2^n\<close>
      using mod_inverse_alt[OF npos Nodd T_inv]
            mod_inverse_idem[OF npos Nodd] by simp
    hence \<open>(z * T) mod\<^sup>+ 2^n = (z * ?Tpos) mod\<^sup>+ 2^n\<close>
      using mod_approx_umod_cong[OF npos, of T ?Tpos z] by simp
    thus ?thesis unfolding mont_sub_unsigned_def by simp
  qed
qed

text \<open>The signed additive and subtractive Montgomery operators agree except
at the boundary case \<^term>\<open>(z * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 2^(n-1)\<close>, where they
differ by exactly \<^term>\<open>N\<close> \cite[\S2.4.2]{NeonNTT}.\<close>

text %internal \<open>Auxiliary lemma: under \<^term>\<open>odd N\<close> and \<^term>\<open>n \<ge> 1\<close>, the boundary condition
\<^term>\<open>(z * T) mod R = 2^(n-1)\<close> (where \<^term>\<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close> and \<^term>\<open>R = 2^n\<close>) is
equivalent to the simpler condition \<^term>\<open>z mod R = 2^(n-1)\<close>. This holds because
\<^term>\<open>T\<close> is odd (since \<^term>\<open>(N * T) mod R = 1 mod R\<close> with \<^term>\<open>R\<close> even forces \<^term>\<open>T\<close> odd) and
\<^term>\<open>(2^(n-1) * m) mod 2^n = 2^(n-1)\<close> for any odd \<^term>\<open>m\<close>.\<close>

lemma %internal (in OddModulus) exceptional_iff:
  shows \<open>((z * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 2^(n-1)) \<longleftrightarrow> (z mod 2^n = 2^(n-1))\<close>
proof -
  define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
  have n_pos: \<open>n > 0\<close> using npos by simp
  have R_ge_2: \<open>(2::int)^n \<ge> 2\<close> using n_pos by (simp add: self_le_power)
  have NT': \<open>(N * T) mod 2^n = 1\<close> unfolding T_def using R_ge_2 n_pos Nodd by simp
  have R_even: \<open>even ((2::int)^n)\<close> using n_pos by auto
  have key: \<open>\<And>m::int. odd m \<Longrightarrow> (2^(n-1) * m) mod 2^n = 2^(n-1)\<close>
  proof -
    fix m::int assume \<open>odd m\<close>
    then obtain k where k: \<open>m = 2*k + 1\<close> using oddE by blast
    have R_half: \<open>(2::int)^(n-1) * 2 = 2^n\<close>
      using n_pos by (metis One_nat_def Suc_pred power_Suc2)
    have lt: \<open>(2::int)^(n-1) < 2^n\<close> using R_half by (smt (verit) zero_less_power)
    have eq: \<open>2^(n-1) * m = 2^n * k + 2^(n-1)\<close>
      using k R_half by (simp add: algebra_simps)
    show \<open>2^(n-1) * m mod 2^n = 2^(n-1)\<close> using eq lt by simp
  qed
  have NTodd: \<open>odd (N * T)\<close>
    using NT' R_even by (metis div_mult_mod_eq even_add even_mult_iff odd_one)
  hence T_odd: \<open>odd T\<close> by simp
  show ?thesis
  proof
    assume \<open>(z * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 2^(n-1)\<close>
    hence H: \<open>(z * T) mod 2^n = 2^(n-1)\<close> unfolding T_def .
    have \<open>z mod 2^n = (z * (N * T)) mod 2^n\<close>
      using NT' by (metis mod_mult_right_eq mult.right_neutral)
    also have \<open>\<dots> = (((z * T) mod 2^n) * N) mod 2^n\<close>
      by (metis mod_mult_left_eq mult.assoc mult.commute)
    also have \<open>\<dots> = (2^(n-1) * N) mod 2^n\<close> using H by simp
    also have \<open>\<dots> = 2^(n-1)\<close> using key[OF Nodd] by simp
    finally show \<open>z mod 2^n = 2^(n-1)\<close> .
  next
    assume \<open>z mod 2^n = 2^(n-1)\<close>
    hence \<open>(z * T) mod 2^n = (2^(n-1) * T) mod 2^n\<close>
      by (metis mod_mult_left_eq mult.commute)
    also have \<open>\<dots> = 2^(n-1)\<close> using key[OF T_odd] .
    finally show \<open>(z * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 2^(n-1)\<close> unfolding T_def .
  qed
qed

lemma (in OddModulus) mont_sub_eq_add_signed_generic:
  assumes \<open>z mod 2^n \<noteq> 2^(n-1)\<close>
  shows \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<close>
proof -
  define T_pos where \<open>T_pos = N\<^sup>-\<^sup>1 mod 2^n\<close>
  have n_ge_1: \<open>n \<ge> 1\<close> using npos by simp
  have T_pos_inv: \<open>(N * T_pos) mod 2^n = 1 mod 2^n\<close>
    unfolding T_pos_def using mod_inverse_correct(3) .
  have T_neg_inv: \<open>(N * (- T_pos)) mod 2^n = (- 1) mod 2^n\<close>
    using T_pos_inv by (metis mod_minus_eq mult_minus_right)
  have z_T_ne: \<open>(z * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n \<noteq> 2^(n-1)\<close>
    using exceptional_iff[of z] assms by blast
  have neg: \<open>(z * (- T_pos)) mod\<^sup>\<plusminus> 2^n = - ((z * T_pos) mod\<^sup>\<plusminus> 2^n)\<close>
    using mod_signed_negate_generic[OF n_ge_1] z_T_ne
    unfolding T_pos_def
    by (simp add: algebra_simps)
  have lhs: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T_pos) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
    using mont_sub_signed_unfold[OF T_pos_inv, of z] .
  have rhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * (- T_pos)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
    using mont_add_signed_unfold[OF T_neg_inv, of z] .
  have \<open>(z + ((z * (- T_pos)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n
        = (z + (- ((z * T_pos) mod\<^sup>\<plusminus> 2^n)) * N) div 2^n\<close>
    using neg by simp
  also have \<open>\<dots> = (z - ((z * T_pos) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
    by (simp add: algebra_simps)
  finally show ?thesis using lhs rhs by simp
qed

lemma (in OddModulus) mont_sub_eq_add_signed_exceptional:
  assumes \<open>z mod 2^n = 2^(n-1)\<close>
  shows \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z - N\<close>
proof -
  define R where \<open>R = (2::int)^n\<close>
  define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
  have R_nz: \<open>R \<noteq> 0\<close> unfolding R_def by simp
  have T_inv: \<open>(N * T) mod R = 1 mod R\<close>
    unfolding T_def R_def using mod_inverse_correct(3) .
  have T_neg: \<open>(N * (- T)) mod R = (- 1) mod R\<close>
    using T_inv by (metis mod_minus_eq mult_minus_right)
  have neg: \<open>(z * (- T)) mod\<^sup>\<plusminus> R = - ((z * T) mod\<^sup>\<plusminus> R) - R\<close>
    using mod_signed_negate_exceptional[of n] exceptional_iff[of z] assms npos
    unfolding R_def T_def by (simp add: algebra_simps)
  have lhs: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>\<plusminus> R) * N) div R\<close>
    using mont_sub_signed_unfold[OF T_inv[unfolded R_def], of z] unfolding R_def by simp
  have rhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * (- T)) mod\<^sup>\<plusminus> R) * N) div R\<close>
    using mont_add_signed_unfold[OF T_neg[unfolded R_def], of z] unfolding R_def by simp
  have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = ((z - ((z * T) mod\<^sup>\<plusminus> R) * N) + (- N) * R) div R\<close>
    unfolding rhs neg by (simp add: algebra_simps)
  also have \<open>\<dots> = (- N) + (z - ((z * T) mod\<^sup>\<plusminus> R) * N) div R\<close>
    using R_nz by (rule div_mult_self1)
  finally show ?thesis using lhs by simp
qed

subsection \<open>Correctness and Absolute Bounds\<close>

text \<open>Each of the four Montgomery reduction variants is correct and bounded by
\<^term>\<open>\<bar>z\<bar>/R + N/2\<close> (signed) or \<^term>\<open>\<bar>z\<bar>/R + N\<close> (unsigned).\<close>

text %internal \<open>\textbf{Additive signed.} Twist \<^latex>\<open>$T \equiv -N^{-1} \pmod{R}$\<close>; we prove divisibility, then correctness.\<close>

lemma %internal mont_add_signed_divisible:
  assumes \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>2^n dvd (z + ((z * T) mod\<^sup>\<plusminus> 2^n) * N)\<close>
proof -
  have aux: \<open>(z * T - 2 ^ n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil>) mod 2 ^ n = (z * T) mod 2 ^ n\<close>
  proof -
    have \<open>2 ^ n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil> mod 2^n = 0\<close> by simp
    thus ?thesis
      using mod_diff_right_eq[of \<open>z*T\<close> \<open>2^n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil>\<close> \<open>2^n\<close>]
      by simp
  qed
  have smod_mod: \<open>((z * T) mod\<^sup>\<plusminus> 2^n) mod 2^n = (z * T) mod 2^n\<close>
    using aux unfolding mod_approx_def by simp
  have \<open>(((z * T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (z * ((N * T) mod 2^n)) mod 2^n\<close>
    using smod_mod
    by (metis mod_mult_left_eq mod_mult_right_eq mult.commute mult.left_commute)
  also have \<open>\<dots> = (z * ((-1) mod 2^n)) mod 2^n\<close> using assms by simp
  also have \<open>\<dots> = (-z) mod 2^n\<close>
    by (metis mod_mult_right_eq mult_minus1_right)
  finally have chain: \<open>(((z*T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (-z) mod 2^n\<close> .
  have \<open>(z + ((z*T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (z + (-z)) mod 2^n\<close>
    using chain by (metis mod_add_right_eq)
  thus ?thesis by (simp add: mod_eq_0_iff_dvd)
qed

text %internal \<open>\textbf{Subtractive signed.} Twist \<^latex>\<open>$T \equiv N^{-1} \pmod{R}$\<close>; the sign of the correction flips.\<close>

lemma %internal mont_sub_signed_divisible:
  assumes \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>2^n dvd (z - ((z * T) mod\<^sup>\<plusminus> 2^n) * N)\<close>
proof -
  have aux: \<open>(z * T - 2 ^ n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil>) mod 2 ^ n = (z * T) mod 2 ^ n\<close>
  proof -
    have \<open>2 ^ n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil> mod 2^n = 0\<close> by simp
    thus ?thesis
      using mod_diff_right_eq[of \<open>z*T\<close> \<open>2^n * \<lfloor>(z*T) /\<^sub>\<rat> (2 ^ n)\<rceil>\<close> \<open>2^n\<close>]
      by simp
  qed
  have smod_mod: \<open>((z * T) mod\<^sup>\<plusminus> 2^n) mod 2^n = (z * T) mod 2^n\<close>
    using aux unfolding mod_approx_def by simp
  have \<open>(((z * T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (z * ((N * T) mod 2^n)) mod 2^n\<close>
    using smod_mod
    by (metis mod_mult_left_eq mod_mult_right_eq mult.commute mult.left_commute)
  also have \<open>\<dots> = (z * (1 mod 2^n)) mod 2^n\<close> using assms by simp
  also have \<open>\<dots> = z mod 2^n\<close>
    by (metis mod_mult_right_eq mult.right_neutral)
  finally have chain: \<open>(((z*T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = z mod 2^n\<close> .
  have \<open>(z - ((z*T) mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (z - z) mod 2^n\<close>
    using chain by (metis mod_diff_right_eq)
  thus ?thesis by (simp add: mod_eq_0_iff_dvd)
qed

text %internal \<open>\textbf{Additive unsigned.} Same shape as additive signed, with \<open>mod\<^sup>+\<close> for the inner residue.\<close>

lemma %internal mont_add_unsigned_divisible:
  assumes \<open>n > 0\<close> and \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>2^n dvd (z + ((z * T) mod\<^sup>+ 2^n) * N)\<close>
proof -
  have R_pos: \<open>((2::int)^n) > 0\<close> using assms(1) by simp
  have umod_mod: \<open>((z * T) mod\<^sup>+ 2^n) mod 2^n = (z * T) mod 2^n\<close>
    using mod_unsigned_eq_mod[OF R_pos] R_pos by simp
  have \<open>(((z * T) mod\<^sup>+ 2^n) * N) mod 2^n = (z * ((N * T) mod 2^n)) mod 2^n\<close>
    using umod_mod
    by (metis mod_mult_left_eq mod_mult_right_eq mult.commute mult.left_commute)
  also have \<open>\<dots> = (z * ((-1) mod 2^n)) mod 2^n\<close> using assms(2) by simp
  also have \<open>\<dots> = (-z) mod 2^n\<close>
    by (metis mod_mult_right_eq mult_minus1_right)
  finally have chain: \<open>(((z*T) mod\<^sup>+ 2^n) * N) mod 2^n = (-z) mod 2^n\<close> .
  have \<open>(z + ((z*T) mod\<^sup>+ 2^n) * N) mod 2^n = (z + (-z)) mod 2^n\<close>
    using chain by (metis mod_add_right_eq)
  thus ?thesis by (simp add: mod_eq_0_iff_dvd)
qed

text %internal \<open>\textbf{Subtractive unsigned.} Twist \<^latex>\<open>$T \equiv N^{-1} \pmod{R}$\<close> with \<open>mod\<^sup>+\<close> for the inner residue.\<close>

lemma %internal mont_sub_unsigned_divisible:
  assumes \<open>n > 0\<close> and \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>2^n dvd (z - ((z * T) mod\<^sup>+ 2^n) * N)\<close>
proof -
  have R_pos: \<open>((2::int)^n) > 0\<close> using assms(1) by simp
  have umod_mod: \<open>((z * T) mod\<^sup>+ 2^n) mod 2^n = (z * T) mod 2^n\<close>
    using mod_unsigned_eq_mod[OF R_pos] R_pos by simp
  have \<open>(((z * T) mod\<^sup>+ 2^n) * N) mod 2^n = (z * ((N * T) mod 2^n)) mod 2^n\<close>
    using umod_mod
    by (metis mod_mult_left_eq mod_mult_right_eq mult.commute mult.left_commute)
  also have \<open>\<dots> = (z * (1 mod 2^n)) mod 2^n\<close> using assms(2) by simp
  also have \<open>\<dots> = z mod 2^n\<close>
    by (metis mod_mult_right_eq mult.right_neutral)
  finally have chain: \<open>(((z*T) mod\<^sup>+ 2^n) * N) mod 2^n = z mod 2^n\<close> .
  have \<open>(z - ((z*T) mod\<^sup>+ 2^n) * N) mod 2^n = (z - z) mod 2^n\<close>
    using chain by (metis mod_diff_right_eq)
  thus ?thesis by (simp add: mod_eq_0_iff_dvd)
qed

theorem (in OddModulus) mont_correct:
  shows \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
    and \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
    and \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
    and \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
proof -
  show \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
  proof -
    define T where \<open>T = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
    have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
      using mod_inverse_correct(3) .
    have T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
      unfolding T_def using inv
      by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
    define k where \<open>k = (z * T) mod\<^sup>\<plusminus> 2^n\<close>
    have div: \<open>2^n dvd (z + k * N)\<close>
      unfolding k_def using T_inv
      by (rule mont_add_signed_divisible)
    have unfold: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + k * N) div 2^n\<close>
      using mont_add_signed_unfold[OF T_inv, of z] k_def by simp
    have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n = z + k * N\<close>
      using unfold div by simp
    then have \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = (z + k * N) mod N\<close>
      by simp
    also have \<open>\<dots> = z mod N\<close> by simp
    finally show ?thesis .
  qed
  show \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
  proof -
    define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
    have T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
      unfolding T_def using mod_inverse_correct(3) .
    define k where \<open>k = (z * T) mod\<^sup>\<plusminus> 2^n\<close>
    have div: \<open>2^n dvd (z - k * N)\<close>
      unfolding k_def using T_inv by (rule mont_sub_signed_divisible)
    have unfold: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - k * N) div 2^n\<close>
      using mont_sub_signed_unfold[OF T_inv, of z] k_def by simp
    have eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z * 2^n = z - k * N\<close>
      using unfold div by simp
    have \<open>(z - k * N) mod N = z mod N\<close>
      using mod_diff_eq[of z N \<open>k * N\<close>]
      by simp
    with eq show ?thesis by simp
  qed
  show \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
  proof -
    define T where \<open>T = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
    have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
      using mod_inverse_correct(3) .
    have T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
      unfolding T_def using inv
      by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
    define k where \<open>k = (z * T) mod\<^sup>+ 2^n\<close>
    have div: \<open>2^n dvd (z + k * N)\<close>
      unfolding k_def using npos T_inv by (rule mont_add_unsigned_divisible)
    have unfold: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z + k * N) div 2^n\<close>
      using mont_add_unsigned_unfold[OF T_inv, of z] k_def by simp
    have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n = z + k * N\<close>
      using unfold div by simp
    then have \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = (z + k * N) mod N\<close>
      by simp
    also have \<open>\<dots> = z mod N\<close> by simp
    finally show ?thesis .
  qed
  show \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n) mod N = z mod N\<close>
  proof -
    define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
    have T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
      unfolding T_def using mod_inverse_correct(3) .
    define k where \<open>k = (z * T) mod\<^sup>+ 2^n\<close>
    have div: \<open>2^n dvd (z - k * N)\<close>
      unfolding k_def using npos T_inv by (rule mont_sub_unsigned_divisible)
    have unfold: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z - k * N) div 2^n\<close>
      using mont_sub_unsigned_unfold[OF T_inv, of z] k_def by simp
    have eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z * 2^n = z - k * N\<close>
      using unfold div by simp
    have \<open>(z - k * N) mod N = z mod N\<close>
      using mod_diff_eq[of z N \<open>k * N\<close>]
      by simp
    with eq show ?thesis by simp
  qed
qed

lemmas %internal (in OddModulus) mont_add_signed_correct   = mont_correct(1)
lemmas %internal (in OddModulus) mont_sub_signed_correct   = mont_correct(2)
lemmas %internal (in OddModulus) mont_add_unsigned_correct = mont_correct(3)
lemmas %internal (in OddModulus) mont_sub_unsigned_correct = mont_correct(4)

text %internal \<open>The triangle inequality \<^term>\<open>\<bar>z + k*N\<bar> \<le> \<bar>z\<bar> + \<bar>k\<bar>*N\<close> makes the bound depend
only on the range of \<^term>\<open>k\<close>:
\[
  \lvert \mathit{mont}^{\pm}(z) \rvert \;\le\; \lvert z \rvert / R + N/2,
  \qquad
  \lvert \mathit{mont}^{+}(z) \rvert \;\le\; \lvert z \rvert / R + N.
\]
We prove each bound on the unfolded expression with an arbitrary inverse \<^term>\<open>T\<close>;
the operator form follows by substitution.\<close>

lemma %internal mont_add_signed_bound_int_raw:
  assumes \<open>N > 0\<close> and \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>2 * \<bar>(z + ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<bar> * 2^n
           \<le> 2 * \<bar>z\<bar> + N * 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>(z * T) mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>z + ?k * N\<close>
  let ?m = \<open>?u div ?R\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have div: \<open>?R dvd ?u\<close>
    using mont_add_signed_divisible[OF assms(2), of z] by simp
  have eq: \<open>?m * ?R = ?u\<close> using div by (simp add: dvd_div_mult_self)
  have k_lo: \<open>- (?R div 2) \<le> ?k\<close> using mod_signed_lower R_pos by blast
  have k_hi: \<open>?k \<le> (?R - 1) div 2\<close> using mod_signed_upper R_pos by blast
  have two_k_abs: \<open>2 * \<bar>?k\<bar> \<le> ?R\<close> using k_lo k_hi by linarith
  have N_nn: \<open>N \<ge> 0\<close> using assms(1) by simp
  have abs_kN: \<open>2 * \<bar>?k * N\<bar> \<le> ?R * N\<close>
    using mult_right_mono[OF two_k_abs N_nn] N_nn by (simp add: abs_mult)
  have abs_u: \<open>2 * \<bar>?u\<bar> \<le> 2 * \<bar>z\<bar> + ?R * N\<close>
    using abs_triangle_ineq[of z \<open>?k * N\<close>] abs_kN by force
  have abs_eq: \<open>\<bar>?m\<bar> * ?R = \<bar>?u\<bar>\<close>
    using eq R_pos by (metis abs_mult abs_of_pos)
  show ?thesis using abs_eq abs_u by (simp add: mult.assoc mult.commute)
qed

lemma %internal (in OddModulus) mont_add_signed_bound_int:
  shows \<open>2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n \<le> 2 * \<bar>z\<bar> + N * 2^n\<close>
proof -
  define T where \<open>T = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3) .
  have T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
    unfolding T_def using inv
    by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
  have eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
    using mont_add_signed_unfold[OF T_inv] .
  show ?thesis
    using mont_add_signed_bound_int_raw[OF Npos T_inv, of z] eq by simp
qed

lemma %internal mont_sub_signed_bound_int_raw:
  assumes \<open>N > 0\<close> and \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>2 * \<bar>(z - ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<bar> * 2^n
           \<le> 2 * \<bar>z\<bar> + N * 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>(z * T) mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>z - ?k * N\<close>
  let ?m = \<open>?u div ?R\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have div: \<open>?R dvd ?u\<close>
    using mont_sub_signed_divisible[OF assms(2), of z] by simp
  have eq: \<open>?m * ?R = ?u\<close> using div by (simp add: dvd_div_mult_self)
  have k_lo: \<open>- (?R div 2) \<le> ?k\<close> using mod_signed_lower R_pos by blast
  have k_hi: \<open>?k \<le> (?R - 1) div 2\<close> using mod_signed_upper R_pos by blast
  have two_k_abs: \<open>2 * \<bar>?k\<bar> \<le> ?R\<close> using k_lo k_hi by linarith
  have N_nn: \<open>N \<ge> 0\<close> using assms(1) by simp
  have step_c: \<open>2 * \<bar>?k * N\<bar> \<le> ?R * N\<close>
    using two_k_abs N_nn mult_right_mono[of \<open>2 * \<bar>?k\<bar>\<close> ?R N]
    by (simp add: abs_mult mult.assoc)
  have abs_u: \<open>2 * \<bar>?u\<bar> \<le> 2 * \<bar>z\<bar> + ?R * N\<close>
    using abs_triangle_ineq4[of z \<open>?k * N\<close>] step_c by arith
  have abs_eq: \<open>\<bar>?m\<bar> * ?R = \<bar>?u\<bar>\<close>
    using eq R_pos by (metis abs_mult abs_of_pos)
  show ?thesis using abs_eq abs_u by (simp add: mult.assoc mult.commute)
qed

lemma %internal (in OddModulus) mont_sub_signed_bound_int:
  shows \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n \<le> 2 * \<bar>z\<bar> + N * 2^n\<close>
proof -
  define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
  have T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
    unfolding T_def using mod_inverse_correct(3) .
  have eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
    using mont_sub_signed_unfold[OF T_inv] .
  show ?thesis
    using mont_sub_signed_bound_int_raw[OF Npos T_inv, of z] eq by simp
qed

text %internal \<open>Unsigned twist: \<open>k \<in> [0, R)\<close>, so \<open>k \<le> R - 1\<close> and the bound is
\<open>\<bar>mont(z)\<bar> \<le> \<bar>z\<bar>/R + N - N/R\<close>.\<close>

lemma %internal mont_add_unsigned_bound_int_raw:
  assumes \<open>N > 0\<close> and \<open>n > 0\<close> and \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>\<bar>(z + ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<bar> * 2^n \<le> \<bar>z\<bar> + N * 2^n - N\<close>
proof -
  let ?R = \<open>(2::int)^n\<close> let ?k = \<open>(z * T) mod\<^sup>+ ?R\<close> let ?u = \<open>z + ?k * N\<close>
  have div: \<open>?R dvd ?u\<close>
    using mont_add_unsigned_divisible[OF assms(2) assms(3), of z] by simp
  have k: \<open>0 \<le> ?k\<close> \<open>?k \<le> ?R - 1\<close>
    using mod_unsigned_lower[of ?R] mod_unsigned_upper[of ?R] by auto
  have \<open>\<bar>?u div ?R\<bar> * ?R = \<bar>?u\<bar>\<close>
    using dvd_div_mult_self[OF div] by (metis abs_mult abs_of_pos zero_less_power zero_less_numeral)
  also have \<open>\<bar>?u\<bar> \<le> \<bar>z\<bar> + ?k * N\<close>
    using k(1) assms(1) abs_triangle_ineq[of z \<open>?k * N\<close>] by (simp add: abs_mult)
  also have \<open>\<dots> \<le> \<bar>z\<bar> + (?R - 1) * N\<close>
    using k(2) assms(1) by (simp add: mult_right_mono)
  finally show ?thesis by (simp add: algebra_simps)
qed

lemma %internal (in OddModulus) mont_add_unsigned_bound_int:
  shows \<open>\<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n \<le> \<bar>z\<bar> + N * 2^n - N\<close>
proof -
  define T where \<open>T = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3) .
  have T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
    unfolding T_def using inv
    by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
  have eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
    using mont_add_unsigned_unfold[OF T_inv] .
  show ?thesis
    using mont_add_unsigned_bound_int_raw[OF Npos npos T_inv, of z] eq by simp
qed

lemma %internal mont_sub_unsigned_bound_int_raw:
  assumes \<open>N > 0\<close> and \<open>n > 0\<close> and \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>\<bar>(z - ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<bar> * 2^n \<le> \<bar>z\<bar> + N * 2^n - N\<close>
proof -
  let ?R = \<open>(2::int)^n\<close> let ?k = \<open>(z * T) mod\<^sup>+ ?R\<close> let ?u = \<open>z - ?k * N\<close>
  have div: \<open>?R dvd ?u\<close>
    using mont_sub_unsigned_divisible[OF assms(2) assms(3), of z] by simp
  have k: \<open>0 \<le> ?k\<close> \<open>?k \<le> ?R - 1\<close>
    using mod_unsigned_lower[of ?R] mod_unsigned_upper[of ?R] by auto
  have \<open>\<bar>?u div ?R\<bar> * ?R = \<bar>?u\<bar>\<close>
    using dvd_div_mult_self[OF div] by (metis abs_mult abs_of_pos zero_less_power zero_less_numeral)
  also have \<open>\<bar>?u\<bar> \<le> \<bar>z\<bar> + ?k * N\<close>
    using k(1) assms(1) abs_triangle_ineq4[of z \<open>?k * N\<close>] by (simp add: abs_mult)
  also have \<open>\<dots> \<le> \<bar>z\<bar> + (?R - 1) * N\<close>
    using k(2) assms(1) by (simp add: mult_right_mono)
  finally show ?thesis by (simp add: algebra_simps)
qed

lemma %internal (in OddModulus) mont_sub_unsigned_bound_int:
  shows \<open>\<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n \<le> \<bar>z\<bar> + N * 2^n - N\<close>
proof -
  define T where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
  have T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
    unfolding T_def using mod_inverse_correct(3) .
  have eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>+ 2^n) * N) div 2^n\<close>
    using mont_sub_unsigned_unfold[OF T_inv] .
  show ?thesis
    using mont_sub_unsigned_bound_int_raw[OF Npos npos T_inv, of z] eq by simp
qed

text \<open>The headline output bound: every Montgomery variant of \<^term>\<open>z\<close>
is bounded in absolute value by \<open>|z|/R + N/2\<close> in the signed forms, and
by \<open>|z|/R + N - N/R\<close> in the unsigned forms. Both are sharp; they say
that Montgomery reduction shrinks any input to \<^emph>\<open>roughly\<close> the canonical
range, with a residual error tied to \<^term>\<open>N\<close>.\<close>

theorem (in OddModulus) mont_bound:
  shows \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    and \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    and \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
    and \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
proof -
  have iR_pos: \<open>(2^n)\<^sub>\<rat> > 0\<close> by simp
  show \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
  proof -
    have \<open>(2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>z\<bar> + N * 2^n)\<^sub>\<rat>\<close>
      using mont_add_signed_bound_int by (simp only: of_int_le_iff)
    hence \<open>2 * \<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> * (2^n)\<^sub>\<rat> \<le> 2 * \<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat>\<close>
      by (simp add: of_int_mult of_int_add)
    thus ?thesis using iR_pos by (simp add: field_simps)
  qed
  show \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
  proof -
    have \<open>(2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>z\<bar> + N * 2^n)\<^sub>\<rat>\<close>
      using mont_sub_signed_bound_int by (simp only: of_int_le_iff)
    hence \<open>2 * \<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> * (2^n)\<^sub>\<rat> \<le> 2 * \<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat>\<close>
      by (simp add: of_int_mult of_int_add)
    thus ?thesis using iR_pos by (simp add: field_simps)
  qed
  show \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
  proof -
    have \<open>(\<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n)\<^sub>\<rat> \<le> (\<bar>z\<bar> + N * 2^n - N)\<^sub>\<rat>\<close>
      using mont_add_unsigned_bound_int by (simp only: of_int_le_iff)
    hence h: \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> * (2^n)\<^sub>\<rat> \<le> \<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>\<close>
      by (simp add: of_int_mult of_int_add of_int_diff)
    from h iR_pos have \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> (\<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>) / (2^n)\<^sub>\<rat>\<close>
      by (simp add: pos_le_divide_eq mult.commute)
    moreover have \<open>(\<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>) / (2^n)\<^sub>\<rat> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
      using iR_pos by (simp add: diff_divide_distrib add_divide_distrib)
    ultimately show ?thesis by simp
  qed
  show \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
  proof -
    have \<open>(\<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z\<bar> * 2^n)\<^sub>\<rat> \<le> (\<bar>z\<bar> + N * 2^n - N)\<^sub>\<rat>\<close>
      using mont_sub_unsigned_bound_int by (simp only: of_int_le_iff)
    hence h: \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> * (2^n)\<^sub>\<rat> \<le> \<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>\<close>
      by (simp add: of_int_mult of_int_add of_int_diff)
    from h iR_pos have \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>+\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> (\<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>) / (2^n)\<^sub>\<rat>\<close>
      by (simp add: pos_le_divide_eq mult.commute)
    moreover have \<open>(\<bar>z\<bar>\<^sub>\<rat> + N\<^sub>\<rat> * (2^n)\<^sub>\<rat> - N\<^sub>\<rat>) / (2^n)\<^sub>\<rat> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
      using iR_pos by (simp add: diff_divide_distrib add_divide_distrib)
    ultimately show ?thesis by simp
  qed
qed

lemmas %internal (in OddModulus) mont_add_signed_bound   = mont_bound(1)
lemmas %internal (in OddModulus) mont_sub_signed_bound   = mont_bound(2)
lemmas %internal (in OddModulus) mont_add_unsigned_bound = mont_bound(3)
lemmas %internal (in OddModulus) mont_sub_unsigned_bound = mont_bound(4)

text \<open>The signed bounds are tight: there exist inputs at which the
inequality is an equality. As an example, we pick \<open>n = 3\<close>, \<open>N = 3\<close>, 
so \<open>R = 8\<close>: then \<^term>\<open>N\<^sup>-\<^sup>1 mod R = 3\<close>, \<open>k = -4\<close> at \<open>z = -4\<close> (additive) or
\<open>z = 4\<close> (subtractive), with \<open>\<bar>m\<bar> = 2\<close> matching\<^term>\<open>\<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2\<close>.\<close>

lemma mont_add_signed_bound_tight:
  shows \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> (-4))\<^sub>\<rat>\<bar> = \<bar>-4\<bar> /\<^sub>\<rat> 2^3 + 3 /\<^sub>\<rat> 2\<close>
proof -
  interpret SM: OddModulus 3 3 by unfold_locales auto
  have inv: \<open>(3 * (5::int)) mod 2^3 = (- 1) mod 2^3\<close> by simp
  have h: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> (-4) = ((-4) + ((-4 * 5) mod\<^sup>\<plusminus> 2^3) * 3) div 2^3\<close>
    using SM.mont_add_signed_unfold[OF inv, of \<open>-4\<close>] by simp
  have k: \<open>((-4 * 5)::int) mod\<^sup>\<plusminus> 2^3 = -4\<close>
    unfolding mod_approx_def by code_simp
  have v: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> (-4) = -2\<close> using h k by simp
  show ?thesis unfolding v by simp
qed

lemma mont_sub_signed_bound_tight:
  shows \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> 4)\<^sub>\<rat>\<bar> = \<bar>4\<bar> /\<^sub>\<rat> 2^3 + 3 /\<^sub>\<rat> 2\<close>
proof -
  interpret SM: OddModulus 3 3 by unfold_locales auto
  have inv: \<open>(3 * (3::int)) mod 2^3 = 1 mod 2^3\<close> by simp
  have h: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> 4 = (4 - ((4 * 3) mod\<^sup>\<plusminus> 2^3) * 3) div 2^3\<close>
    using SM.mont_sub_signed_unfold[OF inv, of 4] by simp
  have k: \<open>((4 * 3)::int) mod\<^sup>\<plusminus> 2^3 = -4\<close>
    unfolding mod_approx_def by code_simp
  have v: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>3, 3\<rbrakk> 4 = 2\<close> using h k by simp
  show ?thesis unfolding v by simp
qed

text \<open>The unsigned bounds are also tight in the sharper form
\<^term>\<open>\<bar>m\<bar>\<^sub>\<rat> \<le> \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>. As an example, we pick \<open>n = 3\<close>, \<open>N = 3\<close>, 
so \<open>R = 8\<close>, with twist \<^term>\<open>-N\<^sup>-\<^sup>1 mod R = 5\<close>. At \<open>z = 3\<close> we get \<open>k = 7\<close>
and \<open>m = 3\<close>, matching \<^term>\<open>\<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R = 3\<close>.\<close>

lemma mont_add_unsigned_bound_tight:
  shows \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>3, 3\<rbrakk> 3)\<^sub>\<rat>\<bar> = \<bar>3\<bar> /\<^sub>\<rat> 2^3 + 3 - 3 /\<^sub>\<rat> 2^3\<close>
proof -
  interpret SM: OddModulus 3 3 by unfold_locales auto
  have inv: \<open>(3 * (5::int)) mod 2^3 = (- 1) mod 2^3\<close> by simp
  have h: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>3, 3\<rbrakk> 3 = (3 + ((3 * 5) mod\<^sup>+ 2^3) * 3) div 2^3\<close>
    using SM.mont_add_unsigned_unfold[OF inv, of 3] by simp
  have k: \<open>((3 * 5)::int) mod\<^sup>+ 2^3 = 7\<close>
    unfolding mod_approx_def by code_simp
  have v: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>3, 3\<rbrakk> 3 = 3\<close> using h k by simp
  show ?thesis unfolding v by simp
qed

subsection \<open>Tightness characterisation of the signed Montgomery bound\<close>

text \<open>The signed Montgomery bound \<^term>\<open>\<bar>m\<bar> \<le> \<bar>z\<bar>/\<^sub>\<rat>R + N/\<^sub>\<rat>2\<close> is attained exactly when the
input \<open>z\<close> has residue \<open>R/2\<close> modulo \<open>R\<close> and lies on the appropriate
side of zero (\<open>z \<le> 0\<close> for the additive variant, \<open>z \<ge> 0\<close> for the subtractive).\<close>

lemma %internal neg_half_mod_R:
  assumes \<open>n > 0\<close>
  shows \<open>(-(2^(n-1)::int)) mod (2^n::int) = 2^(n-1)\<close>
proof -
  have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close>
    using assms by (cases n) auto
  have h1: \<open>(2::int)^(n-1) > 0\<close> by simp
  have h2: \<open>(2::int)^(n-1) < 2 * 2^(n-1)\<close> using h1 by linarith
  have \<open>(-(2^(n-1)) + 2^n :: int) = 2^(n-1)\<close> using R_eq by simp
  hence eq: \<open>(-(2^(n-1):: int)) mod (2::int)^n = ((2::int)^(n-1)) mod (2::int)^n\<close>
    by (metis mod_add_self2)
  also have \<open>\<dots> = 2^(n-1)\<close>
    using h1 h2 R_eq by simp
  finally show ?thesis .
qed

lemma %internal mod_signed_eq_neg_half_iff:
  assumes \<open>n > 0\<close>
  shows \<open>(z mod\<^sup>\<plusminus> (2::int)^n = -(2^(n-1))) \<longleftrightarrow> (z mod (2::int)^n = 2^(n-1))\<close>
proof -
  define R :: int where \<open>R = 2^n\<close>
  have R_pos: \<open>R > 0\<close> unfolding R_def by simp
  have R_eq: \<open>R = 2 * 2^(n-1)\<close>
    unfolding R_def using assms by (cases n) auto
  have lo: \<open>-(R div 2) \<le> z mod\<^sup>\<plusminus> R\<close> using mod_signed_lower[OF R_pos] .
  have hi: \<open>z mod\<^sup>\<plusminus> R \<le> (R - 1) div 2\<close> using mod_signed_upper[OF R_pos] .
  have neg_half: \<open>(-(2^(n-1)::int)) mod R = 2^(n-1)\<close>
    unfolding R_def using neg_half_mod_R[OF assms] .
  have z_eq: \<open>z = (z mod\<^sup>\<plusminus> R) + R * \<lfloor>z /\<^sub>\<rat> R\<rceil>\<close>
    unfolding mod_approx_def by simp
  have modR_eq: \<open>z mod R = (z mod\<^sup>\<plusminus> R) mod R\<close>
  proof -
    have \<open>z mod R = ((z mod\<^sup>\<plusminus> R) + R * \<lfloor>z /\<^sub>\<rat> R\<rceil>) mod R\<close> using z_eq by simp
    thus ?thesis by (simp add: mod_mult_self1)
  qed
  show \<open>(z mod\<^sup>\<plusminus> R = -(2^(n-1))) \<longleftrightarrow> (z mod R = 2^(n-1))\<close>
  proof
    assume H: \<open>z mod\<^sup>\<plusminus> R = -(2^(n-1))\<close>
    show \<open>z mod R = 2^(n-1)\<close> using modR_eq H neg_half by simp
  next
    assume H: \<open>z mod R = 2^(n-1)\<close>
    hence modR: \<open>(z mod\<^sup>\<plusminus> R) mod R = 2^(n-1)\<close> using modR_eq by simp
    show \<open>z mod\<^sup>\<plusminus> R = -(2^(n-1))\<close>
    proof (cases \<open>z mod\<^sup>\<plusminus> R \<ge> 0\<close>)
      case True
      hence \<open>(z mod\<^sup>\<plusminus> R) mod R = z mod\<^sup>\<plusminus> R\<close> using hi R_eq by simp
      thus ?thesis using modR hi R_eq by simp
    next
      case False
      hence rng: \<open>0 \<le> z mod\<^sup>\<plusminus> R + R \<and> z mod\<^sup>\<plusminus> R + R < R\<close> using lo R_eq by linarith
      hence \<open>(z mod\<^sup>\<plusminus> R + R) mod R = z mod\<^sup>\<plusminus> R + R\<close> using mod_pos_pos_trivial by blast
      hence \<open>z mod\<^sup>\<plusminus> R + R = 2^(n-1)\<close> using modR by (simp add: mod_add_self2)
      thus ?thesis using R_eq by simp
    qed
  qed
qed

lemma %internal half_mul_N_mod_R:
  assumes \<open>n > 0\<close> and \<open>odd (N::int)\<close>
  shows \<open>((2::int)^(n-1) * N) mod (2^n::int) = 2^(n-1)\<close>
proof -
  obtain k where Nk: \<open>N = 2 * k + 1\<close> using assms(2) oddE by blast
  have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close>
    using assms(1) by (cases n) auto
  have \<open>(2::int)^(n-1) * N = 2^(n-1) * (2 * k + 1)\<close> using Nk by simp
  also have \<open>\<dots> = 2 * 2^(n-1) * k + 2^(n-1)\<close> by (simp add: algebra_simps)
  also have \<open>\<dots> = (2::int)^n * k + 2^(n-1)\<close> using R_eq by simp
  finally have eq: \<open>(2::int)^(n-1) * N = (2::int)^n * k + 2^(n-1)\<close> .
  have h1: \<open>(2::int)^(n-1) > 0\<close> by simp
  have h2: \<open>(2::int)^(n-1) < (2::int)^n\<close> using R_eq h1 by linarith
  have \<open>((2::int)^(n-1) * N) mod (2^n::int) = ((2::int)^n * k + 2^(n-1)) mod (2^n::int)\<close>
    using eq by simp
  also have \<open>\<dots> = ((2::int)^(n-1)) mod (2^n::int)\<close>
    by simp
  also have \<open>\<dots> = 2^(n-1)\<close>
    using h1 h2 by simp
  finally show ?thesis .
qed

lemma %internal twist_mod_half_forward:
  assumes \<open>n > 0\<close> and \<open>odd (N::int)\<close>
    and TN: \<open>(N * T) mod (2^n::int) = (eps::int) mod (2^n::int)\<close>
    and eps: \<open>eps = 1 \<or> eps = -1\<close>
    and HzT: \<open>(z * T) mod (2^n::int) = 2^(n-1)\<close>
  shows \<open>z mod (2^n::int) = 2^(n-1)\<close>
proof -
  define R :: int where \<open>R = 2^n\<close>
  have R_pos: \<open>R > 0\<close> unfolding R_def by simp
  have R_eq: \<open>R = 2 * 2^(n-1)\<close> unfolding R_def using assms(1) by (cases n) auto
  have HN: \<open>(N * T) mod R = eps mod R\<close> unfolding R_def using TN .
  have half_N: \<open>(2^(n-1) * N) mod R = 2^(n-1)\<close>
    unfolding R_def using half_mul_N_mod_R[OF assms(1,2)] .
  have HzT': \<open>(z * T) mod R = 2^(n-1)\<close> unfolding R_def using HzT .
  have step1: \<open>(z * T * N) mod R = (2^(n-1) * N) mod R\<close>
    using HzT' by (metis mod_mult_left_eq mult.commute)
  also have \<open>\<dots> = 2^(n-1)\<close> using half_N .
  finally have step2: \<open>(z * T * N) mod R = 2^(n-1)\<close> .
  have step3: \<open>(z * T * N) mod R = (z * eps) mod R\<close>
  proof -
    have \<open>(z * (T * N)) mod R = (z * ((T * N) mod R)) mod R\<close>
      by (simp add: mod_mult_right_eq)
    also have \<open>\<dots> = (z * (eps mod R)) mod R\<close>
      using HN by (simp add: mult.commute)
    also have \<open>\<dots> = (z * eps) mod R\<close> by (simp add: mod_mult_right_eq)
    finally show ?thesis by (simp add: mult.assoc)
  qed
  from step2 step3 have step4: \<open>(z * eps) mod R = 2^(n-1)\<close> by simp
  show \<open>z mod (2^n::int) = 2^(n-1)\<close>
  proof (cases \<open>eps = 1\<close>)
    case True
    thus ?thesis using step4 unfolding R_def by simp
  next
    case False
    hence eps_neg: \<open>eps = -1\<close> using eps by simp
    hence negz: \<open>(-z) mod R = 2^(n-1)\<close> using step4 by simp
    have h1: \<open>(2::int)^(n-1) > 0\<close> by simp
    have h2: \<open>(2::int)^(n-1) < R\<close> using R_eq h1 by linarith
    have z_mod_lt: \<open>z mod R < R\<close> using R_pos by simp
    have z_mod_ge: \<open>z mod R \<ge> 0\<close> using R_pos by simp
    show ?thesis
    proof (cases \<open>z mod R = 0\<close>)
      case True
      hence \<open>(-z) mod R = 0\<close> by (simp add: zmod_zminus1_eq_if)
      thus ?thesis using negz h1 by simp
    next
      case False
      hence pos: \<open>z mod R > 0\<close> using z_mod_ge by linarith
      have \<open>(-z) mod R = R - z mod R\<close>
        using pos z_mod_lt by (simp add: zmod_zminus1_eq_if)
      hence \<open>R - z mod R = 2^(n-1)\<close> using negz by simp
      hence \<open>z mod R = R - 2^(n-1)\<close> by simp
      also have \<open>\<dots> = 2^(n-1)\<close> using R_eq by simp
      finally show ?thesis unfolding R_def .
    qed
  qed
qed

lemma %internal mod_inv_odd:
  assumes \<open>n > 0\<close> and \<open>odd (N::int)\<close>
  shows \<open>odd (N\<^sup>-\<^sup>1 mod (2^n :: int))\<close>
proof -
  define M where \<open>M = N\<^sup>-\<^sup>1 mod (2^n::int)\<close>
  have inv: \<open>(N * M) mod (2^n::int) = 1 mod (2^n::int)\<close>
    unfolding M_def using mod_inverse_correct(3)[OF assms(1,2)] .
  have R_pos: \<open>(2::int)^n > 0\<close> by simp
  have NM_mod: \<open>(N * M) mod (2^n::int) = 1\<close>
    using inv assms(1) by simp
  show \<open>odd M\<close>
  proof (rule ccontr)
    assume \<open>\<not> odd M\<close>
    hence \<open>even M\<close> by simp
    hence even_NM: \<open>(2::int) dvd (N * M)\<close> by simp
    have \<open>(2::int) dvd (2^n :: int)\<close> using assms(1) by (simp add: dvd_power)
    hence \<open>(2::int) dvd ((N * M) mod (2^n::int))\<close>
      using even_NM by (metis dvd_mod)
    hence \<open>(2::int) dvd (1::int)\<close> using NM_mod by simp
    thus False by simp
  qed
qed

lemma %internal twist_mod_half_backward:
  assumes \<open>n > 0\<close> and \<open>odd (N::int)\<close>
    and TN: \<open>(N * T) mod (2^n::int) = (eps::int) mod (2^n::int)\<close>
    and eps: \<open>eps = 1 \<or> eps = -1\<close>
    and Hz: \<open>z mod (2^n::int) = 2^(n-1)\<close>
  shows \<open>(z * T) mod (2^n::int) = 2^(n-1)\<close>
proof -
  define R :: int where \<open>R = 2^n\<close>
  have R_pos: \<open>R > 0\<close> unfolding R_def by simp
  have R_eq: \<open>R = 2 * 2^(n-1)\<close> unfolding R_def using assms(1) by (cases n) auto
  have Hz': \<open>z mod R = 2^(n-1)\<close> unfolding R_def using Hz .
  have HN: \<open>(N * T) mod R = eps mod R\<close> unfolding R_def using TN .
  have h1: \<open>(2::int)^(n-1) > 0\<close> by simp
  have h2: \<open>(2::int)^(n-1) < R\<close> using R_eq h1 by linarith
  have step1: \<open>(z * T) mod R = (2^(n-1) * T) mod R\<close>
    using Hz' by (metis mod_mult_left_eq)
  have h3: \<open>(2^(n-1) * T * N) mod R = (2^(n-1) * eps) mod R\<close>
  proof -
    have \<open>((2^(n-1)::int) * T * N) mod R = ((2^(n-1)::int) * (T * N)) mod R\<close>
      by (simp add: mult.assoc)
    also have \<open>\<dots> = ((2^(n-1)::int) * ((T * N) mod R)) mod R\<close>
      by (simp add: mod_mult_right_eq)
    also have \<open>\<dots> = ((2^(n-1)::int) * (eps mod R)) mod R\<close>
      using HN by (simp add: mult.commute)
    also have \<open>\<dots> = ((2^(n-1)::int) * eps) mod R\<close>
      by (simp add: mod_mult_right_eq)
    finally show ?thesis .
  qed
  have h4: \<open>((2^(n-1)::int) * eps) mod R = 2^(n-1)\<close>
  proof (cases \<open>eps = 1\<close>)
    case True
    thus ?thesis using h1 h2 by simp
  next
    case False
    hence eps_neg: \<open>eps = -1\<close> using eps by simp
    have \<open>((2^(n-1)::int) * eps) mod R = (-(2^(n-1))) mod R\<close> using eps_neg by simp
    also have \<open>\<dots> = 2^(n-1)\<close> using neg_half_mod_R[OF assms(1)] unfolding R_def .
    finally show ?thesis .
  qed
  from h3 h4 have step2: \<open>(2^(n-1) * T * N) mod R = 2^(n-1)\<close> by simp
  have step3: \<open>(2^(n-1) * T * N) mod R = (((2^(n-1) * T) mod R) * N) mod R\<close>
    by (simp add: mod_mult_left_eq)
  define M where \<open>M = N\<^sup>-\<^sup>1 mod 2^n\<close>
  define u where \<open>u = (2^(n-1) * T) mod R\<close>
  have inv: \<open>(N * M) mod 2^n = 1 mod 2^n\<close>
    unfolding M_def using mod_inverse_correct(3)[OF assms(1,2)] .
  have u_eq: \<open>(u * N) mod R = 2^(n-1)\<close> using step2 step3 unfolding u_def by simp
  have \<open>(u * N * M) mod R = (u * 1) mod R\<close>
  proof -
    have \<open>(u * N * M) mod R = (u * (N * M)) mod R\<close> by (simp add: mult.assoc)
    also have \<open>\<dots> = (u * ((N * M) mod R)) mod R\<close> by (simp add: mod_mult_right_eq)
    also have \<open>\<dots> = (u * (1 mod R)) mod R\<close> using inv unfolding R_def by simp
    also have \<open>\<dots> = (u * 1) mod R\<close> by (simp add: mod_mult_right_eq)
    finally show ?thesis .
  qed
  hence eqA: \<open>(u * N * M) mod R = u mod R\<close> by simp
  have eqB: \<open>(u * N * M) mod R = ((u * N) mod R * M) mod R\<close>
    by (simp add: mod_mult_left_eq)
  from eqA eqB have \<open>u mod R = ((u * N) mod R * M) mod R\<close> by simp
  also have \<open>\<dots> = (2^(n-1) * M) mod R\<close> using u_eq by simp
  finally have step4: \<open>u mod R = (2^(n-1) * M) mod R\<close> .
  have M_odd: \<open>odd M\<close> unfolding M_def using mod_inv_odd[OF assms(1,2)] .
  have half_M: \<open>(2^(n-1) * M) mod R = 2^(n-1)\<close>
    unfolding R_def using half_mul_N_mod_R[OF assms(1) M_odd] .
  have u_lt: \<open>u < R\<close> using R_pos unfolding u_def by simp
  have u_ge: \<open>u \<ge> 0\<close> using R_pos unfolding u_def by simp
  have u_self: \<open>u mod R = u\<close> using u_lt u_ge by simp
  from step4 u_self half_M have \<open>u = 2^(n-1)\<close> by simp
  thus ?thesis using step1 unfolding u_def R_def by simp
qed

lemma %internal twist_signed_neg_half_iff:
  assumes \<open>n > 0\<close> and \<open>odd (N::int)\<close>
    and TN: \<open>(N * T) mod (2^n::int) = (eps::int) mod (2^n::int)\<close>
    and eps: \<open>eps = 1 \<or> eps = -1\<close>
  shows \<open>((z * T) mod\<^sup>\<plusminus> (2^n::int) = -(2^(n-1))) \<longleftrightarrow> (z mod (2^n::int) = 2^(n-1))\<close>
proof -
  have iff1: \<open>((z * T) mod\<^sup>\<plusminus> (2^n::int) = -(2^(n-1))) \<longleftrightarrow> ((z * T) mod (2^n::int) = 2^(n-1))\<close>
    using mod_signed_eq_neg_half_iff[OF assms(1), of \<open>z * T\<close>] .
  have iff2: \<open>((z * T) mod (2^n::int) = 2^(n-1)) \<longleftrightarrow> (z mod (2^n::int) = 2^(n-1))\<close>
    using twist_mod_half_forward[OF assms(1,2) TN eps, of z]
          twist_mod_half_backward[OF assms(1,2) TN eps, of z]
    by blast
  from iff1 iff2 show ?thesis by simp
qed

lemma %internal rat_int_2R_eq:
  fixes a b R :: int
  assumes \<open>R > 0\<close>
  shows \<open>(\<bar>a\<bar>\<^sub>\<rat> = \<bar>b\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2) \<longleftrightarrow> (2 * \<bar>a\<bar> * R = 2 * \<bar>b\<bar> + R * N)\<close>
proof -
  have iR_pos: \<open>(R::int)\<^sub>\<rat> > 0\<close> using assms by simp
  have iR_nz: \<open>(R::int)\<^sub>\<rat> \<noteq> 0\<close> using assms by simp
  show ?thesis
  proof
    assume H: \<open>\<bar>a\<bar>\<^sub>\<rat> = \<bar>b\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2\<close>
    have eq1: \<open>2 * \<bar>a\<bar>\<^sub>\<rat> * R\<^sub>\<rat> = 2 * \<bar>b\<bar>\<^sub>\<rat> + R\<^sub>\<rat> * N\<^sub>\<rat>\<close>
      using H iR_nz by (simp add: field_simps)
    have \<open>(2 * \<bar>a\<bar> * R)\<^sub>\<rat> = 2 * \<bar>a\<bar>\<^sub>\<rat> * R\<^sub>\<rat>\<close> by simp
    moreover have \<open>(2 * \<bar>b\<bar> + R * N)\<^sub>\<rat> = 2 * \<bar>b\<bar>\<^sub>\<rat> + R\<^sub>\<rat> * N\<^sub>\<rat>\<close> by simp
    ultimately have \<open>(2 * \<bar>a\<bar> * R)\<^sub>\<rat> = (2 * \<bar>b\<bar> + R * N)\<^sub>\<rat>\<close> using eq1 by simp
    thus \<open>2 * \<bar>a\<bar> * R = 2 * \<bar>b\<bar> + R * N\<close> by (metis of_int_eq_iff)
  next
    assume H: \<open>2 * \<bar>a\<bar> * R = 2 * \<bar>b\<bar> + R * N\<close>
    hence \<open>(2 * \<bar>a\<bar> * R)\<^sub>\<rat> = (2 * \<bar>b\<bar> + R * N)\<^sub>\<rat>\<close> by simp
    hence eq1: \<open>2 * \<bar>a\<bar>\<^sub>\<rat> * R\<^sub>\<rat> = 2 * \<bar>b\<bar>\<^sub>\<rat> + R\<^sub>\<rat> * N\<^sub>\<rat>\<close> by simp
    thus \<open>\<bar>a\<bar>\<^sub>\<rat> = \<bar>b\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2\<close>
      using iR_nz iR_pos by (simp add: field_simps)
  qed
qed

theorem (in OddModulus) mont_signed_bound_iff:
  shows mont_add_signed_bound_iff:
    \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> z \<le> 0\<close>
  and mont_sub_signed_bound_iff:
    \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> z \<ge> 0\<close>
proof -
  have half_pos: \<open>(2::int)^(n-1) * N > 0\<close> using Npos by simp
  have rat_iff: \<open>\<And>a. (\<bar>a\<bar>\<^sub>\<rat> = \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2) \<longleftrightarrow> (2 * \<bar>a\<bar> * R = 2 * \<bar>z\<bar> + R * N)\<close>
    using rat_int_2R_eq[OF R_pos] .
  text \<open>A unified helper covering both signed variants:
        the boolean \<open>add\<close> selects between the
        \<^const>\<open>Montgomery_Reduction.mont_add_signed\<close> and
        \<^const>\<open>Montgomery_Reduction.mont_sub_signed\<close> cases.\<close>
  have generic:
    \<open>\<And>M T eps add. (N * T) mod (2^n::int) = eps mod 2^n \<Longrightarrow> eps = 1 \<or> eps = -1 \<Longrightarrow>
       M = (if add then z + ((z * T) mod\<^sup>\<plusminus> R) * N else z - ((z * T) mod\<^sup>\<plusminus> R) * N) div R \<Longrightarrow>
       R dvd (if add then z + ((z * T) mod\<^sup>\<plusminus> R) * N else z - ((z * T) mod\<^sup>\<plusminus> R) * N) \<Longrightarrow>
       (\<bar>M\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> (if add then z \<le> 0 else z \<ge> 0))\<close>
  proof -
    fix M T :: int and eps :: int and add :: bool
    assume TN: \<open>(N * T) mod (2^n::int) = eps mod 2^n\<close>
    assume eps: \<open>eps = 1 \<or> eps = -1\<close>
    define k where \<open>k = (z * T) mod\<^sup>\<plusminus> R\<close>
    define u where \<open>u = (if add then z + k * N else z - k * N)\<close>
    assume Mdef: \<open>M = (if add then z + ((z * T) mod\<^sup>\<plusminus> R) * N else z - ((z * T) mod\<^sup>\<plusminus> R) * N) div R\<close>
    assume div: \<open>R dvd (if add then z + ((z * T) mod\<^sup>\<plusminus> R) * N else z - ((z * T) mod\<^sup>\<plusminus> R) * N)\<close>
    from Mdef have M_eq: \<open>M = u div R\<close> unfolding u_def k_def by simp
    from div have div': \<open>R dvd u\<close> unfolding u_def k_def by simp
    have twist_iff: \<open>\<And>w. ((w * T) mod\<^sup>\<plusminus> (2^n::int) = -(2^(n-1))) \<longleftrightarrow> (w mod (2^n::int) = 2^(n-1))\<close>
      using twist_signed_neg_half_iff[OF npos Nodd TN eps] .
    have abs_eq: \<open>\<bar>M\<bar> * R = \<bar>u\<bar>\<close>
      using div' M_eq R_pos by (metis abs_mult abs_of_pos dvd_div_mult_self)
    have k_lo': \<open>-(2^(n-1)) \<le> k\<close>
      unfolding k_def using mod_signed_lower[OF R_pos, of \<open>z * T\<close>] R_eq by simp
    have k_hi': \<open>k \<le> 2^(n-1) - 1\<close>
      unfolding k_def using mod_signed_upper[OF R_pos, of \<open>z * T\<close>] R_eq by simp
    have abs_kN: \<open>\<bar>k * N\<bar> = \<bar>k\<bar> * N\<close>
      using N_nn by (simp add: abs_mult abs_of_nonneg)
    have triangle: \<open>\<bar>u\<bar> \<le> \<bar>z\<bar> + \<bar>k * N\<bar>\<close> unfolding u_def
      by (cases add) (auto simp: abs_triangle_ineq abs_minus_commute abs_triangle_ineq4)
    have two_k_le_R: \<open>2 * \<bar>k\<bar> \<le> R\<close> using k_lo' k_hi' R_eq by linarith
    have two_kN_le_RN: \<open>2 * \<bar>k * N\<bar> \<le> R * N\<close>
      using two_k_le_R N_nn abs_kN by (metis mult.assoc mult_right_mono)
    have two_k_eq_R_iff: \<open>(2 * \<bar>k\<bar> = R) \<longleftrightarrow> k = -(2^(n-1))\<close>
      using k_lo' k_hi' R_eq by linarith
    show \<open>(\<bar>M\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> (if add then z \<le> 0 else z \<ge> 0))\<close>
    proof
      assume \<open>\<bar>M\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2\<close>
      hence Hi: \<open>2 * \<bar>M\<bar> * R = 2 * \<bar>z\<bar> + R * N\<close> using rat_iff by simp
      have eqU: \<open>2 * \<bar>u\<bar> = 2 * \<bar>z\<bar> + R * N\<close>
        using Hi abs_eq by (simp add: mult.assoc)
      have triangle_tight: \<open>2 * \<bar>u\<bar> = 2 * \<bar>z\<bar> + 2 * \<bar>k * N\<bar>\<close>
        using eqU triangle two_kN_le_RN by linarith
      have k_tight: \<open>2 * \<bar>k\<bar> = R\<close>
        using eqU triangle_tight abs_kN Npos by simp
      have k_val: \<open>k = -(2^(n-1))\<close> using k_tight two_k_eq_R_iff by simp
      have z_mod_unsigned: \<open>z mod\<^sup>+ 2^n = 2^(n-1)\<close>
        using k_val twist_iff[of z] mod_unsigned_eq_mod[OF R_pos]
        unfolding k_def by simp
      have kN_neg: \<open>k * N < 0\<close> using k_val half_pos by simp
      have z_sign: \<open>if add then z \<le> 0 else z \<ge> 0\<close>
      proof (cases add)
        case True
        have \<open>z \<le> 0\<close>
        proof (rule ccontr)
          assume \<open>\<not> z \<le> 0\<close>
          hence \<open>\<bar>z + k * N\<bar> < \<bar>z\<bar> + \<bar>k * N\<bar>\<close> using kN_neg by linarith
          thus False using triangle_tight unfolding u_def using True by simp
        qed
        thus ?thesis using True by simp
      next
        case False
        have \<open>z \<ge> 0\<close>
        proof (rule ccontr)
          assume \<open>\<not> z \<ge> 0\<close>
          hence \<open>\<bar>z - k * N\<bar> < \<bar>z\<bar> + \<bar>k * N\<bar>\<close> using kN_neg by linarith
          thus False using triangle_tight unfolding u_def using False by simp
        qed
        thus ?thesis using False by simp
      qed
      show \<open>z mod\<^sup>+ 2^n = 2^(n-1) \<and> (if add then z \<le> 0 else z \<ge> 0)\<close>
        using z_mod_unsigned z_sign by simp
    next
      assume A: \<open>z mod\<^sup>+ 2^n = 2^(n-1) \<and> (if add then z \<le> 0 else z \<ge> 0)\<close>
      hence Hz: \<open>z mod\<^sup>+ 2^n = 2^(n-1)\<close> and z_sign: \<open>if add then z \<le> 0 else z \<ge> 0\<close> by auto
      have z_mod: \<open>z mod R = 2^(n-1)\<close>
        using Hz mod_unsigned_eq_mod[OF R_pos] by simp
      have k_val: \<open>k = -(2^(n-1))\<close>
        using twist_iff[of z] z_mod unfolding k_def by simp
      hence kN_eq: \<open>k * N = -(2^(n-1) * N)\<close> by simp
      have abs_kN_eq: \<open>\<bar>k * N\<bar> = 2^(n-1) * N\<close> using kN_eq half_pos by simp
      have abs_u: \<open>\<bar>u\<bar> = \<bar>z\<bar> + \<bar>k * N\<bar>\<close>
      proof (cases add)
        case True
        hence z_le: \<open>z \<le> 0\<close> using z_sign by simp
        have \<open>u = z - 2^(n-1) * N\<close> unfolding u_def using True kN_eq by simp
        thus ?thesis using z_le half_pos abs_kN_eq by linarith
      next
        case False
        hence z_ge: \<open>z \<ge> 0\<close> using z_sign by simp
        have \<open>u = z + 2^(n-1) * N\<close> unfolding u_def using False kN_eq by simp
        thus ?thesis using z_ge half_pos abs_kN_eq by linarith
      qed
      have eqU: \<open>2 * \<bar>u\<bar> = 2 * \<bar>z\<bar> + R * N\<close>
        using abs_u abs_kN_eq R_eq by (simp add: algebra_simps)
      hence Hi: \<open>2 * \<bar>M\<bar> * R = 2 * \<bar>z\<bar> + R * N\<close>
        using abs_eq by (simp add: mult.assoc)
      show \<open>\<bar>M\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> / 2\<close> using rat_iff Hi by simp
    qed
  qed
  show \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> z \<le> 0\<close>
  proof -
    define T :: int where \<open>T = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
    have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close> using mod_inverse_correct(3) .
    have T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
      unfolding T_def using inv by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
    have eps_disj: \<open>((-1)::int) = 1 \<or> ((-1)::int) = -1\<close> by simp
    have m_eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + ((z * T) mod\<^sup>\<plusminus> R) * N) div R\<close>
      using mont_add_signed_unfold[OF T_inv, of z] by simp
    have div: \<open>R dvd (z + ((z * T) mod\<^sup>\<plusminus> R) * N)\<close>
      using mont_add_signed_divisible[OF T_inv, of z] by simp
    show ?thesis
      using generic[where add=True and M=\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<close> and T=T and eps=\<open>-1\<close>,
                    OF T_inv eps_disj] m_eq div by simp
  qed
  show \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat>\<bar> = \<bar>z\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2 \<longleftrightarrow> z mod\<^sup>+ 2^n = 2^(n-1) \<and> z \<ge> 0\<close>
  proof -
    define T :: int where \<open>T = N\<^sup>-\<^sup>1 mod 2^n\<close>
    have T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
      unfolding T_def using mod_inverse_correct(3) .
    have eps_disj: \<open>((1)::int) = 1 \<or> ((1)::int) = -1\<close> by simp
    have m_eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z - ((z * T) mod\<^sup>\<plusminus> R) * N) div R\<close>
      using mont_sub_signed_unfold[OF T_inv, of z] by simp
    have div: \<open>R dvd (z - ((z * T) mod\<^sup>\<plusminus> R) * N)\<close>
      using mont_sub_signed_divisible[OF T_inv, of z] by simp
    show ?thesis
      using generic[where add=False and M=\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z\<close> and T=T and eps=1,
                    OF T_inv eps_disj] m_eq div by simp
  qed
qed


section \<open>Montgomery multiplication with a known constant\<close>

text \<open>Montgomery reduction of the product \<^term>\<open>a * b\<close> can be simplified in case one
operand, say \<^term>\<open>b\<close>, is known. In this case, one can precompute the `twist'
\<open>b_tw \<equiv> b \<sqdot> N\<^sup>-\<^sup>1 (mod R)\<close> and compute the Montgomery multiplication as follows:\<close>

definition mont_mul_sub_signed (\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<langle>_,_\<rangle>\<close>) where
  \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> \<equiv>
     \<comment>\<open>\<open>b_tw\<close> should be precomputed in practice\<close>
     (let b_tw = (b * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n in
        (a * b - ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N) div 2^n)\<close>

definition mont_mul_add_signed (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<langle>_,_\<rangle>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> \<equiv>
     \<comment>\<open>\<open>b_tw\<close> should be precomputed in practice\<close>
     (let b_tw = (b * ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n)) mod 2^n in
        (a * b + ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N) div 2^n)\<close>

definition mont_mul_add_unsigned (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>_,_\<rbrakk>\<langle>_,_\<rangle>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> \<equiv>
     \<comment>\<open>\<open>b_tw\<close> should be precomputed in practice\<close>
     (let b_tw = (b * ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n)) mod 2^n in
        (a * b + (a * b_tw mod\<^sup>+ 2^n) * N) div 2^n)\<close>

subsection %internal \<open>Precomputed twist \<open>b_tw\<close>\<close>

text %internal \<open>Any \<^term>\<open>b_tw\<close> congruent to \<^term>\<open>b*T mod R\<close> (for \<^term>\<open>T\<close> with the right inverse
relation) yields the same result.\<close>


lemma %internal mul_smod_shift:
  fixes a b_tw bT :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>b_tw mod 2^n = bT mod 2^n\<close>
  shows \<open>(a * b_tw) mod\<^sup>\<plusminus> 2^n = (a * bT) mod\<^sup>\<plusminus> 2^n\<close>
  using mod_approx_smod_cong[OF assms(1), of b_tw bT a] assms(2) by simp

lemma %internal mul_umod_shift:
  fixes a b_tw bT :: int and n :: nat
  assumes \<open>n > 0\<close> and \<open>b_tw mod 2^n = bT mod 2^n\<close>
  shows \<open>(a * b_tw) mod\<^sup>+ 2^n = (a * bT) mod\<^sup>+ 2^n\<close>
  using mod_approx_umod_cong[OF assms(1), of b_tw bT a] assms(2) by simp

lemma %internal (in OddModulus) mont_mul_sub_signed_unfold:
  assumes T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  assumes bT_def: \<open>b_tw mod 2^n = (b * T) mod 2^n\<close>
  shows \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = (a * b - ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
proof -
  define c where \<open>c = (b * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3) .
  have T_eq: \<open>T mod 2^n = (N\<^sup>-\<^sup>1 mod 2^n) mod 2^n\<close>
    using mod_inverse_alt[OF npos Nodd T_inv]
          mod_inverse_idem[OF npos Nodd] by simp
  have c_eq: \<open>c mod 2^n = (b * T) mod 2^n\<close>
    unfolding c_def using T_eq
    by (metis mod_mod_trivial mod_mult_right_eq)
  hence btw_eq: \<open>b_tw mod 2^n = c mod 2^n\<close>
    using bT_def by simp
  have \<open>(a * b_tw) mod\<^sup>\<plusminus> 2^n = (a * c) mod\<^sup>\<plusminus> 2^n\<close>
    using mul_smod_shift[OF npos btw_eq, of a] .
  thus ?thesis
    unfolding mont_mul_sub_signed_def Let_def c_def[symmetric] by simp
qed

lemma %internal (in OddModulus) mont_mul_add_signed_unfold:
  assumes T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  assumes bT_def: \<open>b_tw mod 2^n = (b * T) mod 2^n\<close>
  shows \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = (a * b + ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
proof -
  define c where \<open>c = (b * ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n)) mod 2^n\<close>
  have T_eq: \<open>T mod 2^n = ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n) mod 2^n\<close>
    using mod_inverse_neg_alt[OF npos Nodd T_inv]
          mod_inverse_neg_idem[OF npos Nodd] by simp
  have c_eq: \<open>c mod 2^n = (b * T) mod 2^n\<close>
    unfolding c_def using T_eq
    by (metis mod_mod_trivial mod_mult_right_eq)
  hence btw_eq: \<open>b_tw mod 2^n = c mod 2^n\<close>
    using bT_def by simp
  have \<open>(a * b_tw) mod\<^sup>\<plusminus> 2^n = (a * c) mod\<^sup>\<plusminus> 2^n\<close>
    using mul_smod_shift[OF npos btw_eq, of a] .
  thus ?thesis
    unfolding mont_mul_add_signed_def Let_def c_def[symmetric] by simp
qed

lemma %internal (in OddModulus) mont_mul_add_unsigned_unfold:
  assumes T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  assumes bT_def: \<open>b_tw mod 2^n = (b * T) mod 2^n\<close>
  shows \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = (a * b + ((a * b_tw) mod\<^sup>+ 2^n) * N) div 2^n\<close>
proof -
  define c where \<open>c = (b * ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n)) mod 2^n\<close>
  have T_eq: \<open>T mod 2^n = ((- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n) mod 2^n\<close>
    using mod_inverse_neg_alt[OF npos Nodd T_inv]
          mod_inverse_neg_idem[OF npos Nodd] by simp
  have c_eq: \<open>c mod 2^n = (b * T) mod 2^n\<close>
    unfolding c_def using T_eq
    by (metis mod_mod_trivial mod_mult_right_eq)
  hence btw_eq: \<open>b_tw mod 2^n = c mod 2^n\<close>
    using bT_def by simp
  have \<open>(a * b_tw) mod\<^sup>+ 2^n = (a * c) mod\<^sup>+ 2^n\<close>
    using mul_umod_shift[OF npos btw_eq, of a] .
  thus ?thesis
    unfolding mont_mul_add_unsigned_def Let_def c_def[symmetric] by simp
qed


text \<open>The multiplication operator coincides with the reduction operator applied
to \<^term>\<open>a*b\<close>: by associativity, \<^term>\<open>(a * b_tw) mod R = (a*b * T) mod R\<close>.\<close>

lemma (in OddModulus) mont_mul_eq_red:
  shows \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk> (a * b)\<close>
    and \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk> (a * b)\<close>
    and \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk> (a * b)\<close>
proof -
  define Tpos where \<open>Tpos = N\<^sup>-\<^sup>1 mod 2^n\<close>
  define Tneg where \<open>Tneg = (- (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  have Tpos_inv: \<open>(N * Tpos) mod 2^n = 1 mod 2^n\<close>
    unfolding Tpos_def using mod_inverse_correct(3) .
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n = 1 mod 2^n\<close>
    using mod_inverse_correct(3) .
  have Tneg_inv: \<open>(N * Tneg) mod 2^n = (- 1) mod 2^n\<close>
    unfolding Tneg_def using inv
    by (metis mod_minus_eq mod_mult_right_eq mult_minus_right)
  have bT_def_pos: \<open>((b * Tpos) mod 2^n) mod 2^n = (b * Tpos) mod 2^n\<close> by simp
  have bT_def_neg: \<open>((b * Tneg) mod 2^n) mod 2^n = (b * Tneg) mod 2^n\<close> by simp
  show \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk> (a * b)\<close>
  proof -
    have lhs: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>
                = (a * b - ((a * ((b * Tpos) mod 2^n)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
      using mont_mul_sub_signed_unfold[OF Tpos_inv bT_def_pos, of a] .
    have shift: \<open>(a * ((b * Tpos) mod 2^n)) mod\<^sup>\<plusminus> 2^n = (a * b * Tpos) mod\<^sup>\<plusminus> 2^n\<close>
    proof -
      have \<open>(a * ((b * Tpos) mod 2^n)) mod 2^n = (a * (b * Tpos)) mod 2^n\<close>
        by (metis mod_mult_right_eq)
      hence \<open>(a * ((b * Tpos) mod 2^n)) mod 2^n = (a * b * Tpos) mod 2^n\<close>
        by (simp add: mult.assoc)
      thus ?thesis
        using mod_approx_smod_cong[OF npos,
          of \<open>a * ((b * Tpos) mod 2^n)\<close> \<open>a * b * Tpos\<close> 1]
        by simp
    qed
    have rhs: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = (a * b - ((a * b * Tpos) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
      using mont_sub_signed_unfold[OF Tpos_inv, of \<open>a*b\<close>] .
    show ?thesis using lhs rhs shift by simp
  qed
  show \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk> (a * b)\<close>
  proof -
    have lhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>
                = (a * b + ((a * ((b * Tneg) mod 2^n)) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
      using mont_mul_add_signed_unfold[OF Tneg_inv bT_def_neg, of a] .
    have shift: \<open>(a * ((b * Tneg) mod 2^n)) mod\<^sup>\<plusminus> 2^n = (a * b * Tneg) mod\<^sup>\<plusminus> 2^n\<close>
    proof -
      have \<open>(a * ((b * Tneg) mod 2^n)) mod 2^n = (a * b * Tneg) mod 2^n\<close>
        by (metis mod_mult_right_eq mult.assoc)
      thus ?thesis
        using mod_approx_smod_cong[OF npos,
          of \<open>a * ((b * Tneg) mod 2^n)\<close> \<open>a * b * Tneg\<close> 1]
        by simp
    qed
    have rhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = (a * b + ((a * b * Tneg) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>
      using mont_add_signed_unfold[OF Tneg_inv, of \<open>a*b\<close>] .
    show ?thesis using lhs rhs shift by simp
  qed
  show \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk> (a * b)\<close>
  proof -
    have lhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>
                = (a * b + ((a * ((b * Tneg) mod 2^n)) mod\<^sup>+ 2^n) * N) div 2^n\<close>
      using mont_mul_add_unsigned_unfold[OF Tneg_inv bT_def_neg, of a] .
    have shift: \<open>(a * ((b * Tneg) mod 2^n)) mod\<^sup>+ 2^n = (a * b * Tneg) mod\<^sup>+ 2^n\<close>
    proof -
      have \<open>(a * ((b * Tneg) mod 2^n)) mod 2^n = (a * b * Tneg) mod 2^n\<close>
        by (metis mod_mult_right_eq mult.assoc)
      thus ?thesis
        using mod_approx_umod_cong[OF npos,
          of \<open>a * ((b * Tneg) mod 2^n)\<close> \<open>a * b * Tneg\<close> 1]
        by simp
    qed
    have rhs: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (a * b) = (a * b + ((a * b * Tneg) mod\<^sup>+ 2^n) * N) div 2^n\<close>
      using mont_add_unsigned_unfold[OF Tneg_inv, of \<open>a*b\<close>] .
    show ?thesis using lhs rhs shift by simp
  qed
qed

lemmas %internal (in OddModulus) mont_mul_sub_signed_eq_red   = mont_mul_eq_red(1)
lemmas %internal (in OddModulus) mont_mul_add_signed_eq_red   = mont_mul_eq_red(2)
lemmas %internal (in OddModulus) mont_mul_add_unsigned_eq_red = mont_mul_eq_red(3)

subsection \<open>Correctness and bounds\<close>

text \<open>Since Montgomery multiplication is the same as Montgomery reduction
of the product, the bounds from the previous section readily carry over to
Montgomery multiplication:\<close>

theorem (in OddModulus) mont_mul_correct:
  shows \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
    and \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
    and \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
proof -
  show \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
    using mont_mul_sub_signed_eq_red
          mont_sub_signed_correct[of \<open>a * b\<close>]
    by simp
  show \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
    using mont_mul_add_signed_eq_red
          mont_add_signed_correct[of \<open>a * b\<close>]
    by simp
  show \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle> * 2^n) mod N = (a * b) mod N\<close>
    using mont_mul_add_unsigned_eq_red
          mont_add_unsigned_correct[of \<open>a * b\<close>]
    by simp
qed

lemmas %internal (in OddModulus) mont_mul_sub_signed_correct   = mont_mul_correct(1)
lemmas %internal (in OddModulus) mont_mul_add_signed_correct   = mont_mul_correct(2)
lemmas %internal (in OddModulus) mont_mul_add_unsigned_correct = mont_mul_correct(3)

theorem (in OddModulus) mont_mul_bound:
  shows \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    and \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    and \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
proof -
  show \<open>\<bar>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    using mont_mul_sub_signed_eq_red
          mont_sub_signed_bound[of \<open>a * b\<close>]
    by simp
  show \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> / 2\<close>
    using mont_mul_add_signed_eq_red
          mont_add_signed_bound[of \<open>a * b\<close>]
    by simp
  show \<open>\<bar>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+ \<lbrakk>N, n\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a * b\<bar> /\<^sub>\<rat> 2^n + N\<^sub>\<rat> - N /\<^sub>\<rat> 2^n\<close>
    using mont_mul_add_unsigned_eq_red
          mont_add_unsigned_bound[of \<open>a * b\<close>]
    by simp
qed

lemmas %internal (in OddModulus) mont_mul_sub_signed_bound   = mont_mul_bound(1)
lemmas %internal (in OddModulus) mont_mul_add_signed_bound   = mont_mul_bound(2)
lemmas %internal (in OddModulus) mont_mul_add_unsigned_bound = mont_mul_bound(3)

end

