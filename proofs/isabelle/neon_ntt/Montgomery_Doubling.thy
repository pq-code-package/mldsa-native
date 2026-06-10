(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Montgomery_Doubling
  imports Montgomery_Reduction
begin

chapter \<open>Montgomery multiplication via doubling and rounding \label{ch:montgomery_doubling}\<close>

text \<open>Not every architecture exposes a plain truncating high-half multiply
\<open>MULH\<close> of the kind used in standard Montgomery multiplication. Fixed-point
arithmetic ISAs commonly provide \emph{doubling} or \emph{rounding} high-half
multiplies instead --- on AArch64, \<open>SQDMULH\<close> (returns \<^term>\<open>\<lfloor>2 * a * b /\<^sub>\<rat> R\<rfloor>\<close> for \<^term>\<open>a :: int\<close>, \<^term>\<open>b :: int\<close>, \<^term>\<open>R :: int\<close>) and
\<open>SQRDMULH\<close> (returns \<^term>\<open>\<lfloor>2 * a * b /\<^sub>\<rat> R\<rceil>\<close> under the same typing). \cite[Algorithms~7 and~8, \S3.3]{NeonNTT} rebuild Montgomery multiplication around these
two operations.

\<close>

section \<open>Montgomery Multiplication via Doubling\<close>

text \<open>The idea behind Montgomery Multiplication with Doubling is simple:
use doubling high-half multiplies, and compensate for the doubling through a
halving subtract --- which too is common in fixed-point arithmetic ISAs:\<close>

definition \<open>mont_mul_doubling N n T a b \<equiv>
     (let R = (2::int)^n;
          z = (2 * (a * b)) div R;
          k = ((a * b * T) mod\<^sup>\<plusminus> R);
          c = (2 * (k * N)) div R
      in (z - c) div 2)\<close>

text \<open>Algorithm~7 computes \<^term>\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close> for arbitrary \<^term>\<open>a\<close>, \<^term>\<open>b\<close>:\<close>

theorem (in OddModulus) mont_mul_doubling_eq:
  assumes T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>mont_mul_doubling N n T a b = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>(a * b * T) mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>a * b - ?k * N\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have R_dvd_u: \<open>?R dvd ?u\<close>
    using mont_sub_signed_divisible[OF T_inv, of \<open>a * b\<close>] by simp
  then obtain q where q: \<open>?u = ?R * q\<close> unfolding dvd_def by auto
  have mont_eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = q\<close>
    using mont_sub_signed_unfold[OF T_inv, of \<open>a * b\<close>]
          q R_pos by simp
  have ab_eq: \<open>2 * (a * b) = ?R * (2 * q) + 2 * (?k * N)\<close>
    using q by (simp add: algebra_simps)
  have z_eq: \<open>(2 * (a * b)) div ?R = 2 * q + (2 * (?k * N)) div ?R\<close>
  proof -
    have \<open>(2 * (a * b)) div ?R = (?R * (2 * q) + 2 * (?k * N)) div ?R\<close>
      using ab_eq by simp
    also have \<open>\<dots> = 2 * q + (2 * (?k * N)) div ?R\<close>
      by simp
    finally show ?thesis .
  qed
  have \<open>mont_mul_doubling N n T a b = ((2 * (a * b)) div ?R - (2 * (?k * N)) div ?R) div 2\<close>
    unfolding mont_mul_doubling_def Let_def by simp
  also have \<open>\<dots> = (2 * q) div 2\<close> using z_eq by simp
  also have \<open>\<dots> = q\<close> by simp
  finally show ?thesis using mont_eq by simp
qed

section \<open>Montgomery Multiplication via Rounding\<close>

text \<open>The idea behind Montgomery Multiplication via Rounding is to express
the carry from the low half of the standard Montgomery step as the joint
\emph{rounding carry} of two \<open>SQRDMULH\<close> operations: each contributes a
\<^term>\<open>(1/2 :: rat)\<close> on its own, and combining them recovers the missing high-bit. The
construction is exact for all \<^term>\<open>a\<close>, \<^term>\<open>b\<close> except at one boundary case (low
half exactly \<^term>\<open>2^(n-1)\<close>) where both \<open>SQRDMULH\<close>s round up; the trailing
\<open>SHSUB\<close> halves the doubled output and absorbs the boundary error.

Note: \cite{NeonNTT} did not recognise this corrective effect of \<open>SHSUB\<close>
and unnecessarily assumed one operand to be odd; we drop that assumption.
The boundary case becomes a genuine off-by-one in the doubled variant of
the next section (no \<open>SHSUB\<close>), where assuming it away is the correct fix.\<close>

definition \<open>mont_mul_rounding N n T a b \<equiv>
     (let z = \<lfloor>(2 * (a * b)) /\<^sub>\<rat> 2^n\<rceil>;
          k = ((a * b * T) mod\<^sup>\<plusminus> 2^n);
          c = \<lfloor>(2 * (k * N)) /\<^sub>\<rat> 2^n\<rceil>
      in (z + c) div 2)\<close>

text %internal \<open>A parity fact: under \<^term>\<open>\<bar>a\<bar> < R/2 \<and> \<bar>b\<bar> < R/2\<close> and \<^term>\<open>odd a \<and> odd b\<close>, the product
avoids the midpoint \<^term>\<open>2^(n-1)\<close> modulo \<^term>\<open>R\<close>. Used via
\cite[Fact~1]{NeonNTT}; our equality proof below bypasses Fact~1
and does not consume it.\<close>

lemma %internal ab_mod_not_half:
  fixes a b :: int and n :: nat
  assumes \<open>n \<ge> 1\<close>
      and \<open>2 * \<bar>a\<bar> < 2^n\<close> and \<open>2 * \<bar>b\<bar> < 2^n\<close>
      and \<open>odd a \<and> odd b\<close>
  shows \<open>(a * b) mod 2^n \<noteq> 2^(n-1)\<close>
proof
  let ?R = \<open>(2::int)^n\<close>
  let ?H = \<open>(2::int)^(n-1)\<close>
  assume eq: \<open>(a * b) mod ?R = ?H\<close>
  have R_eq: \<open>?R = 2 * ?H\<close>
    using assms(1) by (cases n) auto
  have ab_odd: \<open>odd (a * b)\<close> using assms(4) by simp
  have ab_par: \<open>(a * b) mod 2 \<noteq> 0\<close>
    using ab_odd by presburger
  have H_par: \<open>?H mod 2 = 0\<close> if \<open>n \<ge> 2\<close>
    using that by (induct n) auto
  consider (n_eq_1) \<open>n = 1\<close> | (n_ge_2) \<open>n \<ge> 2\<close> using assms(1) by linarith
  thus False
  proof cases
    case n_eq_1
    have \<open>a = 0\<close> using assms(2) n_eq_1 by simp
    thus False using assms(4) by simp
  next
    case n_ge_2
    have \<open>(a * b) mod 2 = ?H mod 2\<close>
      using eq by (metis dvd_imp_mod_0 mod_mod_cancel R_eq dvd_triv_left)
    also have \<open>\<dots> = 0\<close> using H_par[OF n_ge_2] .
    finally have \<open>(a * b) mod 2 = 0\<close> .
    thus False using ab_par by simp
  qed
qed


text \<open>Under the standard Montgomery side-conditions, Algorithm~8 computes
exactly \<^term>\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close> for all \<^term>\<open>a\<close>, \<^term>\<open>b\<close>. The parity assumption of \cite[Algorithm~8]{NeonNTT}
that either \<^term>\<open>a\<close> or \<^term>\<open>b\<close> be odd is unnecessary.\<close>

theorem (in OddModulus) mont_mul_rounding_eq:
  assumes T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
  shows \<open>mont_mul_rounding N n T a b = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>(a * b * T) mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>a * b + ?k * N\<close>
  let ?z = \<open>\<lfloor>(2 * (a * b)) /\<^sub>\<rat> ?R\<rceil>\<close>
  let ?c = \<open>\<lfloor>(2 * (?k * N)) /\<^sub>\<rat> ?R\<rceil>\<close>
  let ?s = \<open>(2 * (a * b)) /\<^sub>\<rat> ?R\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have R_dvd_u: \<open>?R dvd ?u\<close>
    using mont_add_signed_divisible[OF T_inv, of \<open>a * b\<close>] by simp
  then obtain q where q: \<open>?u = ?R * q\<close> unfolding dvd_def by auto
  have mont_eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = q\<close>
    using mont_add_signed_unfold[OF T_inv, of \<open>a * b\<close>]
          q R_pos by simp
  have R_rat_nz: \<open>?R\<^sub>\<rat> \<noteq> 0\<close> by simp
  have aux_floor: \<open>\<lfloor>- (x::rat)\<rfloor> + \<lfloor>x\<rfloor> = (if x \<in> \<int> then 0 else -1)\<close> for x
  proof (cases \<open>x \<in> \<int>\<close>)
    case True
    then obtain m :: int where \<open>x = m\<^sub>\<rat>\<close> using Ints_cases by blast
    thus ?thesis by simp
  next
    case False
    hence \<open>x \<noteq> \<lfloor>x\<rfloor>\<^sub>\<rat>\<close> by (metis Ints_of_int)
    hence \<open>\<lceil>x\<rceil> = \<lfloor>x\<rfloor> + 1\<close> by (simp add: ceiling_altdef)
    thus ?thesis using False by (simp add: floor_minus)
  qed
  have round_pair: \<open>\<lfloor>s\<rceil> + \<lfloor>-s\<rceil> \<in> {0, 1}\<close> for s :: rat
  proof -
    let ?h = \<open>s - 1/2\<close>
    have shf: \<open>\<lfloor>?h + 1\<^sub>\<rat>\<rfloor> = \<lfloor>?h\<rfloor> + 1\<close>
      using floor_add_int[of ?h 1] by simp
    have \<open>\<lfloor>s\<rceil> = \<lfloor>s + 1/2\<rfloor>\<close> by (simp add: round_def add.commute)
    also have \<open>s + 1/2 = ?h + 1\<^sub>\<rat>\<close> by simp
    also have \<open>\<lfloor>?h + 1\<^sub>\<rat>\<rfloor> = \<lfloor>?h\<rfloor> + 1\<close> using shf .
    finally have rs: \<open>\<lfloor>s\<rceil> = \<lfloor>?h\<rfloor> + 1\<close> .
    have \<open>\<lfloor>-s\<rceil> = \<lfloor>-s + 1/2\<rfloor>\<close> by (simp add: round_def add.commute)
    also have \<open>-s + 1/2 = - ?h\<close> by simp
    finally have rsn: \<open>\<lfloor>-s\<rceil> = \<lfloor>- ?h\<rfloor>\<close> .
    have sum_eq: \<open>\<lfloor>s\<rceil> + \<lfloor>-s\<rceil> = \<lfloor>?h\<rfloor> + \<lfloor>- ?h\<rfloor> + 1\<close>
      using rs rsn by simp
    show ?thesis using sum_eq aux_floor[of ?h] by (auto split: if_splits)
  qed
  have q_eq_int: \<open>2 * (?k * N) = 2 * ?R * q - 2 * (a * b)\<close>
    using q by (simp add: algebra_simps)
  have rat_q_split: \<open>(2 * (?k * N))\<^sub>\<rat> = (2 * ?R * q)\<^sub>\<rat> - (2 * (a * b))\<^sub>\<rat>\<close>
    using q_eq_int by (metis of_int_diff)
  have \<open>(2 * (?k * N)) /\<^sub>\<rat> ?R = ((2 * ?R * q)\<^sub>\<rat> - (2 * (a * b))\<^sub>\<rat>) / ?R\<^sub>\<rat>\<close>
    using rat_q_split by simp
  also have \<open>\<dots> = (2 * ?R * q) /\<^sub>\<rat> ?R - (2 * (a * b)) /\<^sub>\<rat> ?R\<close>
    by (simp add: diff_divide_distrib)
  also have \<open>(2 * ?R * q) /\<^sub>\<rat> ?R = (2 * q)\<^sub>\<rat>\<close>
    using R_rat_nz by (simp add: field_simps)
  finally have rat_q: \<open>(2 * (?k * N)) /\<^sub>\<rat> ?R = (2 * q)\<^sub>\<rat> - ?s\<close> .
  have c_shift: \<open>\<lfloor>(2 * q)\<^sub>\<rat> - ?s\<rceil> = 2 * q + \<lfloor>- ?s\<rceil>\<close>
  proof -
    have \<open>\<lfloor>(2 * q)\<^sub>\<rat> - ?s\<rceil> = \<lfloor>(2 * q)\<^sub>\<rat> - ?s + 1/2\<rfloor>\<close>
      by (simp add: round_def)
    also have \<open>(2 * q)\<^sub>\<rat> - ?s + 1/2 = (- ?s + 1/2) + (2 * q)\<^sub>\<rat>\<close>
      by simp
    also have \<open>\<lfloor>(- ?s + 1/2) + (2 * q)\<^sub>\<rat>\<rfloor> = \<lfloor>- ?s + 1/2\<rfloor> + 2 * q\<close>
      using floor_add_int[of \<open>- ?s + 1/2\<close> \<open>2 * q\<close>] by simp
    also have \<open>\<lfloor>- ?s + 1/2\<rfloor> = \<lfloor>- ?s\<rceil>\<close> by (simp add: round_def add.commute)
    finally show ?thesis by simp
  qed
  have c_eq2: \<open>?c = 2 * q + \<lfloor>- ?s\<rceil>\<close> using rat_q c_shift by simp
  have z_plus_c: \<open>?z + ?c = 2 * q + (\<lfloor>?s\<rceil> + \<lfloor>- ?s\<rceil>)\<close>
    using c_eq2 by simp
  have div_q: \<open>(?z + ?c) div 2 = q\<close>
  proof -
    from round_pair[of ?s]
    consider \<open>\<lfloor>?s\<rceil> + \<lfloor>- ?s\<rceil> = 0\<close> | \<open>\<lfloor>?s\<rceil> + \<lfloor>- ?s\<rceil> = 1\<close>
      by auto
    thus ?thesis
    proof cases
      case 1 hence \<open>?z + ?c = 2 * q\<close> using z_plus_c by simp
      thus ?thesis by simp
    next
      case 2 hence \<open>?z + ?c = 2 * q + 1\<close> using z_plus_c by simp
      thus ?thesis by simp
    qed
  qed
  have \<open>mont_mul_rounding N n T a b = (?z + ?c) div 2\<close>
    unfolding mont_mul_rounding_def Let_def by simp
  also have \<open>\<dots> = q\<close> using div_q by simp
  also have \<open>\<dots> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close> using mont_eq by simp
  finally show ?thesis .
qed

section \<open>Montgomery Multiplication via Rounding, no halving\<close>

text \<open>A variant of Algorithm~8 that drops the trailing \<open>SHSUB\<close> (the final
\<open>div 2\<close>) and fuses the high-half product with the correction into a single
rounding multiply-accumulate \<open>SQRDMLAH\<close>. Without the halving step there
is no longer a \<^term>\<open>(1/2 :: rat)\<close> to absorb the \<^term>\<open>{0,1}\<close> ambiguity at the boundary
\<^term>\<open>(2*a*b) mod 2^n = 2^(n-1)\<close>, so we exclude this case by hypothesis.
Under that hypothesis the kernel computes exactly
\<^term>\<open>2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>. In implementation contexts, this hypothesis can for example be discharged
by \<^term>\<open>odd b\<close> together with the input bound \<^term>\<open>\<bar>a\<bar> < R/4\<close>,
matching the ``\<open>a\<close> odd or \<open>b\<close> odd'' assumption of \cite[Algorithm~8]{NeonNTT}:
\<^term>\<open>odd b\<close> alone forces \<^term>\<open>(2*a*b) mod 2^n \<noteq> 2^(n-1)\<close> when
\<^term>\<open>\<bar>a\<bar> < 2^(n-2)\<close>.\<close>

definition \<open>mont_mul_rounding_doubled_int N n T a b \<equiv>
     (let z = \<lfloor>2 * a * b /\<^sub>\<rat> 2^n\<rceil>;
          k = a * b * T mod\<^sup>\<plusminus> 2^n;
          c = \<lfloor>2 * k * N /\<^sub>\<rat> 2^n\<rceil>
      in z + c)\<close>

lemma %internal rat_eq_half_imp_int_eq:
  fixes c d :: int
  assumes \<open>d > 0\<close>
      and \<open>c /\<^sub>\<rat> d = m\<^sub>\<rat> + 1/2\<close>
  shows \<open>2 * c = d * (2*m + 1)\<close>
proof -
  have d_nz: \<open>d\<^sub>\<rat> \<noteq> 0\<close> using assms(1) by simp
  have \<open>c\<^sub>\<rat> = (m\<^sub>\<rat> + 1/2) * d\<^sub>\<rat>\<close>
    using assms(2) d_nz by (simp add: field_simps)
  hence \<open>2 * c\<^sub>\<rat> = (2 * m\<^sub>\<rat> + 1) * d\<^sub>\<rat>\<close>
    by (simp add: algebra_simps)
  hence \<open>(2 * c)\<^sub>\<rat> = ((2*m + 1) * d)\<^sub>\<rat>\<close>
    by (simp add: of_int_mult)
  thus ?thesis by (metis of_int_eq_iff mult.commute)
qed

lemma %internal s_minus_half_not_int:
  fixes a b :: int and n :: nat
  assumes \<open>n \<ge> 1\<close>
      and parity: \<open>2 * a * b mod 2^n \<noteq> 2^(n-1)\<close>
  shows \<open>2 * a * b /\<^sub>\<rat> 2^n - 1/2 \<notin> \<int>\<close>
proof
  let ?R = \<open>(2::int)^n\<close>
  let ?H = \<open>(2::int)^(n-1)\<close>
  let ?s = \<open>2 * a * b /\<^sub>\<rat> ?R\<close>
  assume \<open>?s - 1/2 \<in> \<int>\<close>
  then obtain m :: int where m: \<open>?s - 1/2 = m\<^sub>\<rat>\<close>
    using Ints_cases by blast
  hence \<open>?s = m\<^sub>\<rat> + 1/2\<close> by simp
  hence eq: \<open>2 * (2 * a * b) = ?R * (2*m + 1)\<close>
    using rat_eq_half_imp_int_eq[of ?R \<open>2 * a * b\<close> m] by simp
  have R_eq: \<open>?R = 2 * ?H\<close>
    using assms(1) by (cases n) auto
  have \<open>4 * a * b = 2 * ?H * (2*m + 1)\<close> using eq R_eq by (simp add: algebra_simps)
  hence \<open>2 * a * b = ?H * (2*m + 1)\<close> by (simp add: algebra_simps)
  hence \<open>2 * a * b = ?H + ?H * (2*m)\<close> by (simp add: algebra_simps)
  hence \<open>2 * a * b = ?H + ?R * m\<close> using R_eq by (simp add: algebra_simps)
  hence \<open>2 * a * b mod ?R = (?H + ?R * m) mod ?R\<close> by simp
  also have \<open>\<dots> = ?H mod ?R\<close> by simp
  also have \<open>\<dots> = ?H\<close>
  proof -
    have \<open>?H \<ge> 0\<close> by simp
    have \<open>?H < ?R\<close> using R_eq by simp
    thus ?thesis by simp
  qed
  finally have \<open>2 * a * b mod ?R = ?H\<close> .
  thus False using parity by simp
qed

text \<open>The doubled-rounding kernel computes exactly twice the additive
signed Montgomery reduction. The hypothesis
\<^term>\<open>(2*a*b) mod 2^n \<noteq> 2^(n-1)\<close> rules out the only configuration in which the
two \<open>SQRDMULH\<close> roundings would together contribute \<^term>\<open>2\<close> rather than \<^term>\<open>1\<close>.\<close>

theorem (in OddModulus) mont_mul_rounding_doubled_eq:
  assumes T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
      and parity: \<open>2 * a * b mod 2^n \<noteq> 2^(n-1)\<close>
  shows \<open>mont_mul_rounding_doubled_int N n T a b = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>a * b * T mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>a * b + ?k * N\<close>
  let ?z = \<open>\<lfloor>2 * a * b /\<^sub>\<rat> ?R\<rceil>\<close>
  let ?c = \<open>\<lfloor>2 * ?k * N /\<^sub>\<rat> ?R\<rceil>\<close>
  let ?s = \<open>2 * a * b /\<^sub>\<rat> ?R\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have R_dvd_u: \<open>?R dvd ?u\<close>
    using mont_add_signed_divisible[OF T_inv, of \<open>a * b\<close>] by simp
  then obtain q where q: \<open>?u = ?R * q\<close> unfolding dvd_def by auto
  have mont_eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = q\<close>
    using mont_add_signed_unfold[OF T_inv, of \<open>a * b\<close>]
          q R_pos by simp
  have R_rat_nz: \<open>?R\<^sub>\<rat> \<noteq> 0\<close> by simp
  have aux_floor: \<open>\<lfloor>- (x::rat)\<rfloor> + \<lfloor>x\<rfloor> = (if x \<in> \<int> then 0 else -1)\<close> for x
  proof (cases \<open>x \<in> \<int>\<close>)
    case True
    then obtain m :: int where \<open>x = m\<^sub>\<rat>\<close> using Ints_cases by blast
    thus ?thesis by simp
  next
    case False
    hence \<open>x \<noteq> \<lfloor>x\<rfloor>\<^sub>\<rat>\<close> by (metis Ints_of_int)
    hence \<open>\<lceil>x\<rceil> = \<lfloor>x\<rfloor> + 1\<close> by (simp add: ceiling_altdef)
    thus ?thesis using False by (simp add: floor_minus)
  qed
  have round_pair_zero: \<open>\<lfloor>s\<rceil> + \<lfloor>-s\<rceil> = 0\<close> if H: \<open>s - 1/2 \<notin> \<int>\<close> for s :: rat
  proof -
    let ?h = \<open>s - 1/2\<close>
    have shf: \<open>\<lfloor>?h + 1\<^sub>\<rat>\<rfloor> = \<lfloor>?h\<rfloor> + 1\<close>
      using floor_add_int[of ?h 1] by simp
    have \<open>\<lfloor>s\<rceil> = \<lfloor>s + 1/2\<rfloor>\<close> by (simp add: round_def add.commute)
    also have \<open>s + 1/2 = ?h + 1\<^sub>\<rat>\<close> by simp
    also have \<open>\<lfloor>?h + 1\<^sub>\<rat>\<rfloor> = \<lfloor>?h\<rfloor> + 1\<close> using shf .
    finally have rs: \<open>\<lfloor>s\<rceil> = \<lfloor>?h\<rfloor> + 1\<close> .
    have \<open>\<lfloor>-s\<rceil> = \<lfloor>-s + 1/2\<rfloor>\<close> by (simp add: round_def add.commute)
    also have \<open>-s + 1/2 = - ?h\<close> by simp
    finally have rsn: \<open>\<lfloor>-s\<rceil> = \<lfloor>- ?h\<rfloor>\<close> .
    have sum_eq: \<open>\<lfloor>s\<rceil> + \<lfloor>-s\<rceil> = \<lfloor>?h\<rfloor> + \<lfloor>- ?h\<rfloor> + 1\<close>
      using rs rsn by simp
    show ?thesis using sum_eq aux_floor[of ?h] H by simp
  qed
  have q_eq_int: \<open>2 * ?k * N = 2 * ?R * q - 2 * a * b\<close>
    using q by (simp add: algebra_simps)
  have rat_q_split: \<open>(2 * ?k * N)\<^sub>\<rat> = (2 * ?R * q)\<^sub>\<rat> - (2 * a * b)\<^sub>\<rat>\<close>
    using q_eq_int by (metis of_int_diff)
  have \<open>2 * ?k * N /\<^sub>\<rat> ?R = ((2 * ?R * q)\<^sub>\<rat> - (2 * a * b)\<^sub>\<rat>) / ?R\<^sub>\<rat>\<close>
    using rat_q_split by simp
  also have \<open>\<dots> = 2 * ?R * q /\<^sub>\<rat> ?R - 2 * a * b /\<^sub>\<rat> ?R\<close>
    by (simp add: diff_divide_distrib)
  also have \<open>2 * ?R * q /\<^sub>\<rat> ?R = (2 * q)\<^sub>\<rat>\<close>
    using R_rat_nz by (simp add: field_simps)
  finally have rat_q: \<open>2 * ?k * N /\<^sub>\<rat> ?R = (2 * q)\<^sub>\<rat> - ?s\<close> .
  have c_shift: \<open>\<lfloor>(2 * q)\<^sub>\<rat> - ?s\<rceil> = 2 * q + \<lfloor>- ?s\<rceil>\<close>
  proof -
    have \<open>\<lfloor>(2 * q)\<^sub>\<rat> - ?s\<rceil> = \<lfloor>(2 * q)\<^sub>\<rat> - ?s + 1/2\<rfloor>\<close>
      by (simp add: round_def)
    also have \<open>(2 * q)\<^sub>\<rat> - ?s + 1/2 = (- ?s + 1/2) + (2 * q)\<^sub>\<rat>\<close>
      by simp
    also have \<open>\<lfloor>(- ?s + 1/2) + (2 * q)\<^sub>\<rat>\<rfloor> = \<lfloor>- ?s + 1/2\<rfloor> + 2 * q\<close>
      using floor_add_int[of \<open>- ?s + 1/2\<close> \<open>2 * q\<close>] by simp
    also have \<open>\<lfloor>- ?s + 1/2\<rfloor> = \<lfloor>- ?s\<rceil>\<close> by (simp add: round_def add.commute)
    finally show ?thesis by simp
  qed
  have c_eq2: \<open>?c = 2 * q + \<lfloor>- ?s\<rceil>\<close> using rat_q c_shift by simp
  have z_plus_c: \<open>?z + ?c = 2 * q + (\<lfloor>?s\<rceil> + \<lfloor>- ?s\<rceil>)\<close>
    using c_eq2 by simp
  have n_ge_1: \<open>n \<ge> 1\<close> using npos by simp
  have h_not_int: \<open>?s - 1/2 \<notin> \<int>\<close>
    using s_minus_half_not_int[OF n_ge_1 parity] .
  have round_zero: \<open>\<lfloor>?s\<rceil> + \<lfloor>- ?s\<rceil> = 0\<close>
    using round_pair_zero[OF h_not_int] .
  have main: \<open>?z + ?c = 2 * q\<close> using z_plus_c round_zero by simp
  have \<open>mont_mul_rounding_doubled_int N n T a b = ?z + ?c\<close>
    unfolding mont_mul_rounding_doubled_int_def Let_def by simp
  also have \<open>\<dots> = 2 * q\<close> using main .
  also have \<open>\<dots> = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close> using mont_eq by simp
  finally show ?thesis .
qed

end

