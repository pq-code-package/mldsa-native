(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)


theory Bridge_Conceptual
  imports Barrett_Montgomery
begin

chapter \<open>A conceptual view of the Barrett--Montgomery bridge \label{ch:bridge_conceptual}\<close>

text \<open>
The \autoref{ch:barrett_montgomery} bridge was proved by direct algebraic
manipulation. This chapter recasts it as a corollary of a (trivial) duality
between Euclidean and 2-adic \emph{rounding} of a rational number, plus some
arithmetic properties of the 2-adic side. The recasting was first sketched in the
talk \cite{Becker2022NeonNTTtalk} presenting \cite{NeonNTT} at CHES 2022.

Rounding can be described as the process of expressing a continuum as the sum of
something discrete and something small (relatively compact); the choice of
absolute value on \<^term>\<open>\<rat>\<close> determines the roles. The Euclidean absolute
value gives \<open>\<lfloor>\<cdot>\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>] : \<rat> \<rightarrow> \<int>\<close>, with error in \<open>[-\<onehalf>, \<onehalf>)\<close>: this is the
rounding underlying Barrett. The 2-adic absolute value gives
\<open>\<lfloor>\<cdot>\<rceil>\<^sub>[\<^sub>2\<^sub>] : \<rat> \<rightarrow> \<int>[\<onehalf>] \<inter> [-\<onehalf>, \<onehalf>)\<close>, with error in the odd-denominator
rationals \<open>\<int>\<^sub>(\<^sub>2\<^sub>) \<inter> \<rat>\<close>: this is the rounding underlying Montgomery. The
duality is the swap: each rounding's target sits inside the other's error set.
On the dyadic rationals \<open>\<int>[\<onehalf>]\<close> the two roundings sum to the identity. This,
together with basic arithmetic properties of 2-adic rounding, establishes the
Barrett--Montgomery bridge.

We treat only the signed variant; the unsigned variant follows the same recipe
with floor-rounding.
\<close>


section \<open>Barrett arithmetic via Euclidean rounding\<close>

text \<open>
For the Euclidean metric, the rounding target is \<^term>\<open>\<int>\<close> and the error lies in
\<open>[-\<onehalf>, \<onehalf>)\<close>. The half-open right end is forced by HOL's \<^const>\<open>round\<close>
(round half-up): at \<open>q = \<onehalf>\<close> the error is \<open>-\<onehalf>\<close>.
\<close>

definition \<open>euclid_target q \<equiv> snd (quotient_of q) = 1\<close>
definition \<open>euclid_error q \<equiv> - (1/2) \<le> q \<and> q < 1/2\<close>

text %internal \<open>The Euclidean target is exactly \<^term>\<open>\<int>\<close> (in the \<^term>\<open>\<rat>\<close>-quotient sense).\<close>

lemma %internal euclid_target_iff_int:
  \<open>euclid_target q \<longleftrightarrow> (\<exists>k::int. q = k\<^sub>\<rat>)\<close>
proof
  assume H: \<open>euclid_target q\<close>
  obtain a b where ab: \<open>quotient_of q = (a, b)\<close> by (cases \<open>quotient_of q\<close>) auto
  with H have b1: \<open>b = 1\<close> unfolding euclid_target_def by simp
  have qF: \<open>q = Fract a b\<close>
    using ab Fract_quotient_of[of q] by (metis fst_conv snd_conv)
  with b1 have \<open>q = Fract a 1\<close> by simp
  hence \<open>q = a\<^sub>\<rat>\<close> by (simp add: Fract_of_int_eq)
  thus \<open>\<exists>k::int. q = k\<^sub>\<rat>\<close> by blast
next
  assume \<open>\<exists>k::int. q = k\<^sub>\<rat>\<close>
  then obtain k where qk: \<open>q = k\<^sub>\<rat>\<close> by blast
  have \<open>quotient_of (k\<^sub>\<rat>) = (k, 1)\<close> by simp
  thus \<open>euclid_target q\<close> unfolding euclid_target_def using qk by simp
qed

lemma %internal euclid_target_of_int [simp]: \<open>euclid_target (k\<^sub>\<rat>)\<close>
  unfolding euclid_target_def by simp

lemma %internal round_error_window:
  shows lower: \<open>- (1/2) \<le> q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close> and upper: \<open>q - \<lfloor>q\<rceil>\<^sub>\<rat> < 1/2\<close>
proof -
  let ?h = \<open>q + 1/2\<close>
  let ?n = \<open>\<lfloor>?h\<rfloor>\<close>
  have e1: \<open>?n\<^sub>\<rat> \<le> ?h\<close> by (rule of_int_floor_le)
  have e2: \<open>?h < ?n\<^sub>\<rat> + 1\<close> by linarith
  have unf: \<open>round q = ?n\<close> unfolding round_def ..
  show \<open>- (1/2) \<le> q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close> using e1 unf by linarith
  show \<open>q - \<lfloor>q\<rceil>\<^sub>\<rat> < 1/2\<close> using e2 unf by linarith
qed

text\<open>Every rational has a unique decomposition with respect to Euclidean rounding:\<close>

theorem euclidean_decomposition_unique:
  shows \<open>\<exists>!m. euclid_target m \<and> euclid_error (q - m)\<close>
proof (rule ex1I)
  show \<open>euclid_target (\<lfloor>q\<rceil>\<^sub>\<rat> :: rat) \<and> euclid_error (q - \<lfloor>q\<rceil>\<^sub>\<rat>)\<close>
    using round_error_window[of q] unfolding euclid_error_def by simp
next
  fix m assume H: \<open>euclid_target m \<and> euclid_error (q - m)\<close>
  show \<open>m = \<lfloor>q\<rceil>\<^sub>\<rat>\<close>
    using H euclid_target_iff_int unfolding euclid_error_def
    by (metis add.commute diff_le_eq diff_less_eq minus_diff_eq minus_le_iff round_unique)
qed

definition round_E (\<open>\<lfloor>_\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>]\<close>) where \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>] \<equiv> THE m. euclid_target m \<and> euclid_error (q - m)\<close>

text \<open>\noindent Of course, \<open>[\<infinity>]\<close> is just ordinary rounding:\<close>

lemma round_E_eq_round: \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>] = \<lfloor>q\<rceil>\<^sub>\<rat>\<close>
  by (rule the1_equality[OF euclidean_decomposition_unique, folded round_E_def])
     (use round_error_window[of q] in \<open>simp add: euclid_error_def\<close>)

text \<open>\noindent Finally, Barrett reduction is --- by definition --- based on Euclidean rounding of
\<^term>\<open>z * f (R /\<^sub>\<rat> N) /\<^sub>\<rat> R\<close> scaled by \<^term>\<open>N\<close> and subtracted from \<^term>\<open>z\<close>.\<close>

lemma (in BarrettContext) bar_signed_as_round_E:
  shows \<open>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat> = z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> 2^n\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>]\<close>
  by (simp add: barrett_red_signed_def Let_def round_E_eq_round)

section \<open>Montgomery arithmetic via 2-adic rounding\<close>

text \<open>
For the 2-adic metric, the rounding target is \<open>\<int>[\<onehalf>] \<inter> [-\<onehalf>, \<onehalf>)\<close> (a transversal of
\<open>\<rat>\<^sub>2 / \<int>\<^sub>2\<close>) and the error set is the odd-denominator rationals
\<open>\<int>\<^sub>(\<^sub>2\<^sub>) \<inter> \<rat>\<close>. Compared to the Euclidean side the targets and errors swap:
\<^term>\<open>\<int>\<close> now sits inside the error set, and \<open>[-\<onehalf>, \<onehalf>)\<close> now contains the
target. We need a little more arithmetic groundwork than the Euclidean side.
\<close>

definition %internal \<open>is_power_of_two k \<equiv> (\<exists>m::nat. k = 2^m)\<close>

definition Dyadic ("\<int>\<^sub>[\<^sub>1\<^sub>'/\<^sub>2\<^sub>]")
  where \<open>\<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<equiv> {q. is_power_of_two (snd (quotient_of q))}\<close>

definition TwoAdicIntegral ("\<int>\<^sub>[\<^sub>2\<^sub>]")
  where \<open>\<int>\<^sub>[\<^sub>2\<^sub>] \<equiv> {q. odd (snd (quotient_of q))}\<close>

lemma %internal Dyadic_iff:
  "q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<longleftrightarrow> is_power_of_two (snd (quotient_of q))"
  by (simp add: Dyadic_def)

lemma %internal TwoAdicIntegral_iff:
  "q \<in> \<int>\<^sub>[\<^sub>2\<^sub>] \<longleftrightarrow> odd (snd (quotient_of q))"
  by (simp add: TwoAdicIntegral_def)

text\<open>We will use the following congruence relation to embed modular
arithmetic modulo \<^term>\<open>R\<close> into the intermediate subring \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close> between \<^term>\<open>\<int>\<close>
and \<^term>\<open>\<rat>\<close>. Note that it does not degenerate because we left \<^term>\<open>2\<close> non-invertible
in \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close>.\<close>

abbreviation cong_R_two_adic :: "rat \<Rightarrow> rat \<Rightarrow> int \<Rightarrow> bool"
      ("[_ = _] '( mod _ \<int>\<^sub>[\<^sub>2\<^sub>]')" [50, 50, 50] 50)
      where "[x = y] (mod R \<int>\<^sub>[\<^sub>2\<^sub>]) \<equiv> ((x - y) / R\<^sub>\<rat>) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]"

text\<open>Our 2-adic rounding target is the (2-adically) discrete set of dyadic numbers in the
interval \<^term>\<open>{-1/2..<1/2}\<close>:\<close>

definition TwoAdicTarget ("'[-\<onehalf>, \<onehalf>')\<^sub>[\<^sub>1\<^sub>'/\<^sub>2\<^sub>]") where
  \<open>[-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<equiv> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<inter> {-(1/2)..<(1/2)}\<close>

lemma %internal two_adic_target_iff:
  \<open>q \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<longleftrightarrow> q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> - (1/2) \<le> q \<and> q < 1/2\<close>
  by (simp add: TwoAdicTarget_def)

lemma %internal int_dyadic [simp]: \<open>k\<^sub>\<rat> \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  unfolding Dyadic_iff is_power_of_two_def
  by (rule exI[where x=0]) simp

lemma %internal two_adic_integral_of_int [simp]: \<open>k\<^sub>\<rat> \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  unfolding TwoAdicIntegral_def by simp

lemma %internal dyadic_and_integral_iff_int:
  \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<inter> \<int>\<^sub>[\<^sub>2\<^sub>] \<longleftrightarrow> (\<exists>k::int. q = k\<^sub>\<rat>)\<close>
  by (auto simp: Dyadic_iff TwoAdicIntegral_iff is_power_of_two_def Fract_of_int_eq Fract_quotient_of)
     (metis power_0 not0_implies_Suc power_Suc even_mult_iff dvd_refl Fract_of_int_eq Fract_quotient_of)

text %internal \<open>Equivalent characterisation of \<^term>\<open>\<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> as ``some power of \<open>2\<close>
multiplied into \<^term>\<open>\<int>\<close>''.\<close>

lemma %internal dyadic_iff_pow_int:
  \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<longleftrightarrow> (\<exists>n::nat. 2^n * q \<in> \<int>)\<close>
proof -
  obtain a b where ab: \<open>quotient_of q = (a, b)\<close> and b_pos: \<open>b > 0\<close>
    and copr: \<open>coprime a b\<close> and qfrac: \<open>q = a /\<^sub>\<rat> b\<close>
    using quotient_of_denom_pos quotient_of_coprime Fract_quotient_of[of q]
    by (metis Fract_of_int_quotient prod.collapse)
  show ?thesis
  proof
    assume \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
    thus \<open>\<exists>n::nat. 2^n * q \<in> \<int>\<close>
    proof -
      assume H: \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
      obtain m where bm: \<open>b = 2^m\<close>
        using H ab unfolding Dyadic_iff is_power_of_two_def by force
      have \<open>2^m * q = a\<^sub>\<rat>\<close> using qfrac bm b_pos by simp
      thus ?thesis using Ints_of_int by metis
    qed
  next
    have \<open>prime (2::int)\<close> by simp
    moreover assume \<open>\<exists>n::nat. 2^n * q \<in> \<int>\<close>
    ultimately show \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
    proof -
      assume prime2: \<open>prime (2::int)\<close> and exH: \<open>\<exists>n::nat. 2^n * q \<in> \<int>\<close>
      obtain m k where mk: \<open>2^m * q = k\<^sub>\<rat>\<close> using exH Ints_cases by metis
      hence \<open>2^m * (a\<^sub>\<rat> / b\<^sub>\<rat>) = k\<^sub>\<rat>\<close> using qfrac by simp
      hence rat_eq: \<open>(2^m * a)\<^sub>\<rat> = (k * b)\<^sub>\<rat>\<close>
        using b_pos by (simp add: of_int_mult field_simps)
      have eq: \<open>2^m * a = k * b\<close> using rat_eq by (metis of_int_eq_iff)
      hence \<open>b dvd 2^m * a\<close> by (metis dvd_triv_right)
      hence \<open>b dvd 2^m\<close>
        using copr coprime_dvd_mult_left_iff coprime_commute by (metis mult.commute)
      hence \<open>\<exists>m'. b = 2^m'\<close>
        using prime2 divides_primepow b_pos
        by (metis abs_of_pos normalize_int_def)
      thus \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> using ab unfolding Dyadic_iff is_power_of_two_def by auto
    qed
  qed
qed

lemma %internal int_div_pow2_dyadic [simp]:
  shows \<open>a /\<^sub>\<rat> (2^n) \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  by (metis nonzero_mult_div_cancel_left of_int_numeral of_int_power dyadic_iff_pow_int Ints_of_int
    power_eq_0_iff times_divide_eq_right zero_neq_numeral)

text %internal \<open>Closure: \<^term>\<open>\<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> is closed under subtraction.\<close>

lemma %internal dyadic_diff:
  assumes \<open>q1 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> and \<open>q2 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  shows \<open>q1 - q2 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
proof -
  obtain n1 where ints1: \<open>2^n1 * q1 \<in> \<int>\<close>
    using assms(1) dyadic_iff_pow_int by blast
  obtain n2 where ints2: \<open>2^n2 * q2 \<in> \<int>\<close>
    using assms(2) dyadic_iff_pow_int by blast
  let ?n = \<open>n1 + n2\<close>
  have ints1': \<open>2^?n * q1 \<in> \<int>\<close>
    using Ints_mult[OF Ints_of_int[of \<open>2^n2\<close>] ints1]
    by (simp add: power_add of_int_mult algebra_simps)
  have ints2': \<open>2^?n * q2 \<in> \<int>\<close>
    using Ints_mult[OF Ints_of_int[of \<open>2^n1\<close>] ints2]
    by (simp add: power_add of_int_mult algebra_simps)
  have \<open>2^?n * (q1 - q2) \<in> \<int>\<close>
    using ints1' ints2' by (simp add: right_diff_distrib)
  thus \<open>q1 - q2 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> using dyadic_iff_pow_int by blast
qed

lemma %internal dyadic_minus_int:
  assumes \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  shows \<open>(q - k\<^sub>\<rat>) \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
proof -
  have \<open>(k\<^sub>\<rat>) \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> by simp
  thus ?thesis using dyadic_diff[OF assms] by simp
qed

text %internal \<open>Closure: rationals with odd denominator are closed under subtraction.\<close>

lemma %internal quotient_of_to_Fract:
  assumes \<open>quotient_of q = (a, b)\<close>
  shows \<open>q = Fract a b\<close>
proof -
  have \<open>Fract (fst (quotient_of q)) (snd (quotient_of q)) = q\<close>
    by (rule Fract_quotient_of)
  thus ?thesis using assms by simp
qed

lemma %internal two_adic_integral_diff:
  assumes \<open>q1 \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> and \<open>q2 \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  shows \<open>q1 - q2 \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  obtain a1 b1 a2 b2 where ab1: \<open>quotient_of q1 = (a1, b1)\<close> and ab2: \<open>quotient_of q2 = (a2, b2)\<close>
    by (cases \<open>quotient_of q1\<close>; cases \<open>quotient_of q2\<close>) auto
  obtain a b where ab: \<open>quotient_of (q1 - q2) = (a, b)\<close>
    by (cases \<open>quotient_of (q1 - q2)\<close>) auto
  have \<open>odd (b1 * b2)\<close> \<open>b1 * b2 > 0\<close>
    using assms ab1 ab2 quotient_of_denom_pos
    unfolding TwoAdicIntegral_iff by (auto intro: mult_pos_pos)
  moreover have \<open>Rat.normalize (a1 * b2 - a2 * b1, b1 * b2) = (a, b)\<close>
    using ab ab1 ab2 by (simp add: rat_minus_code)
  ultimately have \<open>odd b\<close>
    by (auto simp: Rat.normalize_def Let_def split: if_splits)
       (metis dvd_div_mult_self gcd_dvd2 even_mult_iff)
  thus ?thesis unfolding TwoAdicIntegral_iff using ab by simp
qed

text \<open>A rational with odd denominator (in lowest terms) lies in \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close>.\<close>

lemma two_adic_integral_div_odd:
  assumes \<open>N > 0\<close> and \<open>odd N\<close>
  shows \<open>a /\<^sub>\<rat> N \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  unfolding TwoAdicIntegral_iff using assms
  by (simp add: Fract_of_int_quotient[symmetric] Rat.quotient_of_Fract Rat.normalize_def Let_def)
     (metis dvd_mult_div_cancel even_mult_iff gcd_dvd2)

text %internal \<open>\<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close> is closed under multiplication by an integer: if \<^term>\<open>q\<close> has odd
denominator (in lowest terms) then so does \<^term>\<open>c\<^sub>\<rat> * q\<close> (any common factor between
\<^term>\<open>c\<close> and the denominator only shrinks the denominator).\<close>

lemma %internal two_adic_integral_int_mult:
  assumes \<open>q \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  shows \<open>c\<^sub>\<rat> * q \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  obtain a b where ab: \<open>quotient_of q = (a, b)\<close>
    by (cases \<open>quotient_of q\<close>) auto
  from assms ab have b_odd: \<open>odd b\<close> unfolding TwoAdicIntegral_iff by simp
  have b_pos: \<open>b > 0\<close> using quotient_of_denom_pos[OF ab] .
  have q_eq: \<open>q = a /\<^sub>\<rat> b\<close>
    using ab Fract_quotient_of[of q] b_pos
    by (metis Fract_of_int_quotient fst_conv snd_conv)
  have \<open>c\<^sub>\<rat> * q = (c * a) /\<^sub>\<rat> b\<close>
    using b_pos q_eq by (simp add: of_int_mult)
  thus ?thesis
    using two_adic_integral_div_odd[OF b_pos b_odd, of \<open>c * a\<close>] by simp
qed

text %internal \<open>The 2-adic congruence \<^term>\<open>[a = b] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close> scales by an integer
factor: if \<^term>\<open>a\<close> and \<^term>\<open>b\<close> agree mod \<^term>\<open>R\<close> in \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close>, so do \<^term>\<open>c\<^sub>\<rat> * a\<close> and \<^term>\<open>c\<^sub>\<rat> * b\<close>.
The proof factors \<^term>\<open>c\<close> out of the difference and uses closure of \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close> under
integer multiplication.\<close>

lemma %internal cong_R_two_adic_scale:
  assumes \<open>[a = b] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
  shows \<open>[c\<^sub>\<rat> * a = c\<^sub>\<rat> * b] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
proof -
  have eq: \<open>(c\<^sub>\<rat> * a - c\<^sub>\<rat> * b) / R\<^sub>\<rat> = c\<^sub>\<rat> * ((a - b) / R\<^sub>\<rat>)\<close>
    by (simp add: field_simps)
  have \<open>c\<^sub>\<rat> * ((a - b) / R\<^sub>\<rat>) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using two_adic_integral_int_mult[OF assms] by simp
  thus ?thesis unfolding eq by simp
qed

text %internal \<open>\<^term>\<open>R dvd (z - z mod\<^sup>\<plusminus> R)\<close>: a basic property of signed mod, used in
existence below.\<close>

lemma %internal R_dvd_z_minus_smod:
  shows \<open>R dvd (z - (z mod\<^sup>\<plusminus> R))\<close>
  unfolding mod_approx_def by simp

text %internal \<open>Uniqueness of the 2-adic decomposition: if two \<open>m\<^sub>i\<close> both lie in
\<^term>\<open>[-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> with \<^term>\<open>q - m\<^sub>i \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>, then \<^term>\<open>m\<^sub>1 = m\<^sub>2\<close>. The argument
takes \<^term>\<open>m\<^sub>1 - m\<^sub>2\<close>, observes it lies in both \<^term>\<open>\<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> (closure under subtraction)
and \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close> (closure of odd-denominator rationals under subtraction);
the intersection is \<^term>\<open>\<int>\<close>, and the bounds \<open>|m\<^sub>i| < \<onehalf>\<close> force the integer to be \<^term>\<open>0\<close>.\<close>

lemma %internal twoadic_uniqueness:
  assumes \<open>m1 \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> \<open>m2 \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
      and \<open>q - m1 \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> \<open>(q - m2) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    shows \<open>m1 = m2\<close>
proof -
  from assms(1) have d1: \<open>m1 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> and lb1: \<open>- (1/2) \<le> m1\<close> and ub1: \<open>m1 < 1/2\<close>
    unfolding two_adic_target_iff by auto
  from assms(2) have d2: \<open>m2 \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> and lb2: \<open>- (1/2) \<le> m2\<close> and ub2: \<open>m2 < 1/2\<close>
    unfolding two_adic_target_iff by auto
  have d_diff: \<open>(m1 - m2) \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> using dyadic_diff[OF d1 d2] .
  have step: \<open>(q - m2) - (q - m1) = m1 - m2\<close> by (simp add: algebra_simps)
  have e_diff: \<open>(m1 - m2) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using two_adic_integral_diff[OF assms(4) assms(3)] step by argo
  have \<open>\<exists>k::int. m1 - m2 = k\<^sub>\<rat>\<close>
    using d_diff e_diff dyadic_and_integral_iff_int by blast
  then obtain k where mk: \<open>m1 - m2 = k\<^sub>\<rat>\<close> by blast
  have lb: \<open>m1 - m2 > - 1\<close> using lb1 ub1 lb2 ub2 by linarith
  have ub: \<open>m1 - m2 < 1\<close> using lb1 ub1 lb2 ub2 by linarith
  have \<open>k\<^sub>\<rat> > - 1\<close> using mk lb by simp
  hence k_lb: \<open>k > - 1\<close>
    by (metis of_int_less_iff of_int_minus of_int_1)
  have \<open>k\<^sub>\<rat> < 1\<close> using mk ub by simp
  hence k_ub: \<open>k < 1\<close>
    by (metis of_int_less_iff of_int_1)
  have \<open>k = 0\<close> using k_lb k_ub by simp
  hence \<open>m1 - m2 = 0\<close> using mk by simp
  thus \<open>m1 = m2\<close> by simp
qed

text %internal \<open>Existence of the 2-adic decomposition for an arbitrary \<^term>\<open>q :: rat\<close>.
Write \<^term>\<open>q = a\<^sub>\<rat> / b\<^sub>\<rat>\<close> with \<^term>\<open>b = 2^n * b'\<close>, \<open>b'\<close> odd. If \<^term>\<open>n = 0\<close>, \<^term>\<open>q\<close> is itself
two-adic-integral and \<^term>\<open>m = 0\<close>. Otherwise, the candidate is
\<open>m = ((a * b'\<^sup>-\<^sup>1) mod\<^sup>\<plusminus> 2\<^sup>n)\<^sub>\<rat> / (2\<^sup>n)\<^sub>\<rat>\<close>: it is dyadic, lies in \<open>[-\<onehalf>, \<onehalf>)\<close>,
and \<^term>\<open>q - m\<close> simplifies to \<^term>\<open>s\<^sub>\<rat> / b'\<^sub>\<rat>\<close> for some integer \<^term>\<open>s\<close>, hence has odd
denominator.\<close>

lemma %internal split_two_pow:
  assumes \<open>b > 0\<close>
  obtains n :: nat and b' :: int where \<open>b = 2^n * b'\<close> and \<open>odd b'\<close> and \<open>b' > 0\<close>
proof -
  define n where \<open>n = multiplicity 2 b\<close>
  define b' where \<open>b' = b div 2^n\<close>
  have eq: \<open>b = 2^n * b'\<close>
    unfolding b'_def n_def using multiplicity_dvd[of 2 b] by simp
  have pos: \<open>b' > 0\<close> using assms eq by (simp add: zero_less_mult_iff)
  have \<open>odd b'\<close>
  proof
    assume \<open>2 dvd b'\<close>
    hence \<open>2 ^ Suc n dvd b\<close> using eq by auto
    with multiplicity_geI[OF _ _ this] assms show False unfolding n_def by simp
  qed
  thus ?thesis using eq pos that by blast
qed

lemma %internal twoadic_decomposition_existence:
  shows \<open>\<exists>m. m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  obtain a b where ab: \<open>quotient_of q = (a, b)\<close> by (cases \<open>quotient_of q\<close>) auto
  obtain n b' where bn: \<open>b = 2^n * b'\<close> and b'_odd: \<open>odd b'\<close> and b'_pos: \<open>b' > 0\<close>
    using split_two_pow[OF quotient_of_denom_pos[OF ab]] by blast
  have q_eq: \<open>q = a /\<^sub>\<rat> b\<close> using ab Fract_quotient_of[of q] quotient_of_denom_pos[OF ab]
    by (metis Fract_of_int_quotient fst_conv snd_conv)
  define R T k m where defs: \<open>R = (2::int)^n\<close> \<open>T = b'\<^sup>-\<^sup>1 mod 2^n\<close>
                              \<open>k = (a * T) mod\<^sup>\<plusminus> R\<close> \<open>m = k /\<^sub>\<rat> R\<close>
  have R_pos: \<open>R > 0\<close> and R_pos_rat: \<open>R\<^sub>\<rat> > 0\<close> and b'_nz_rat: \<open>b'\<^sub>\<rat> \<noteq> 0\<close>
    using b'_pos by (auto simp: defs)
  have md: \<open>m \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  proof -
    have \<open>R\<^sub>\<rat> * m \<in> \<int>\<close> using R_pos_rat by (simp add: defs)
    thus ?thesis using dyadic_iff_pow_int defs(1) by (metis of_int_numeral of_int_power)
  qed
  have k_lb: \<open>-R \<le> 2 * k\<close> and k_ub: \<open>2 * k < R\<close>
    using mod_signed_lower[OF R_pos, of \<open>a * T\<close>] mod_signed_upper[OF R_pos, of \<open>a * T\<close>] R_pos
    by (auto simp: defs)
  have \<open>- R\<^sub>\<rat> \<le> 2 * k\<^sub>\<rat>\<close> \<open>2 * k\<^sub>\<rat> < R\<^sub>\<rat>\<close> using k_lb k_ub
    by (metis of_int_minus of_int_le_iff of_int_mult of_int_numeral,
        metis of_int_less_iff of_int_mult of_int_numeral)
  hence target_m: \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> unfolding two_adic_target_iff using md R_pos_rat
    by (simp add: defs field_simps)
  have R_dvd_bT: \<open>R dvd (b' * T - 1)\<close>
  proof (cases \<open>n = 0\<close>)
    case True thus ?thesis by (simp add: defs)
  next
    case False thus ?thesis unfolding defs(1) defs(2)
      using mod_inverse_correct(3)[OF _ b'_odd, of n] by (metis mod_eq_dvd_iff neq0_conv)
  qed
  have R_dvd_aTk: \<open>R dvd (a * T - k)\<close> unfolding defs by (metis R_dvd_z_minus_smod)
  have \<open>a - b' * k = b' * (a * T - k) - a * (b' * T - 1)\<close> by (simp add: algebra_simps)
  hence \<open>R dvd (a - b' * k)\<close> using R_dvd_bT R_dvd_aTk by (simp add: dvd_diff)
  then obtain s where a_minus: \<open>a - b' * k = R * s\<close> by (elim dvdE)
  have eps_eq: \<open>q - m = s /\<^sub>\<rat> b'\<close>
  proof -
    have \<open>q - m = (a - b' * k) /\<^sub>\<rat> (b' * R)\<close>
      using q_eq bn b'_nz_rat R_pos_rat by (simp add: defs of_int_mult field_simps)
    also have \<open>\<dots> = (R * s) /\<^sub>\<rat> (b' * R)\<close> using a_minus by (metis of_int_diff of_int_mult)
    also have \<open>\<dots> = s /\<^sub>\<rat> b'\<close> using b'_nz_rat R_pos_rat by (simp add: field_simps)
    finally show ?thesis .
  qed
  have \<open>(q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> using eps_eq two_adic_integral_div_odd[OF b'_pos b'_odd, of s] by simp
  with target_m show ?thesis by blast
qed

text\<open>For every rational number, there exists a unique 2-adic decomposition:\<close>

theorem twoadic_decomposition_unique:
  shows \<open>\<exists>!m. m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  obtain m where ex: \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using twoadic_decomposition_existence by blast
  show ?thesis
  proof (rule ex1I[of _ m])
    show \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> using ex .
  next
    fix m'
    assume H: \<open>m' \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m') \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    show \<open>m' = m\<close>
      using twoadic_uniqueness[of m' m q] ex H by simp
  qed
qed

text \<open>The 2-adic rounding \<open>\<lfloor>\<cdot>\<rceil>\<^sub>[\<^sub>2\<^sub>] : \<rat> \<rightarrow> \<rat>\<close> picks the unique decomposition
\<^term>\<open>q = m + e\<close> with \<open>m \<in> \<int>[\<onehalf>] \<inter> [-\<onehalf>, \<onehalf>)\<close> and \<^term>\<open>e\<close> two-adic-integral.\<close>

definition round_2 (\<open>\<lfloor>_\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>) where
  \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>] \<equiv> THE m. m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>

text %internal \<open>On a dyadic \<open>q\<close> the 2-adic round is the Euclidean fractional part: the
candidate \<open>q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close> is dyadic, lies in \<open>[-\<onehalf>, \<onehalf>)\<close>, and has integer
complement \<^term>\<open>\<lfloor>q\<rceil>\<^sub>\<rat>\<close>.\<close>

lemma %internal round_2_dyadic_eq:
  assumes \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  shows \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>] = q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close>
proof -
  let ?m = \<open>q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close>
  have m_dyadic: \<open>?m \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> using dyadic_minus_int[OF assms, of \<open>\<lfloor>q\<rceil>\<close>] .
  have e1: \<open>- (1/2) \<le> ?m\<close> using round_error_window(1)[of q] by simp
  have e2: \<open>?m < 1/2\<close> using round_error_window(2)[of q] by simp
  have target_m: \<open>?m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
    unfolding two_adic_target_iff using m_dyadic e1 e2 by simp
  have int_form: \<open>q - ?m = \<lfloor>q\<rceil>\<^sub>\<rat>\<close> by simp
  have integral_eps: \<open>(q - ?m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> unfolding int_form by simp
  have spec: \<open>?m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - ?m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using target_m integral_eps by simp
  have unique: \<open>\<And>m'. m' \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m') \<in> \<int>\<^sub>[\<^sub>2\<^sub>] \<Longrightarrow> m' = ?m\<close>
    using twoadic_decomposition_unique[of q] spec by metis
  show ?thesis
    unfolding round_2_def using spec unique by (rule the_equality)
qed

text \<open>On a dyadic rational, the Euclidean and 2-adic roundings sum to the
identity. This, while trivial, is a core step in the transition from Barrett
arithmetic (Euclidean domain) to Montgomery arithmetic (2-adic domain).\<close>

theorem complementarity:
  assumes \<open>q \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  shows \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>] + \<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>] = q\<close>
proof -
  have e: \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>] = \<lfloor>q\<rceil>\<^sub>\<rat>\<close> by (rule round_E_eq_round)
  have t: \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>] = q - \<lfloor>q\<rceil>\<^sub>\<rat>\<close> using round_2_dyadic_eq[OF assms] .
  show ?thesis using e t by simp
qed

text %internal \<open>The bridge proof needs one more property of 2-adic rounding:
it factors through \<open>\<rat> / (\<int>\<^sub>(\<^sub>2\<^sub>) \<inter> \<rat>)\<close>. Two rationals that differ by a
two-adic-integral round to the same value.\<close>

lemma %internal round_2_invariance:
  assumes \<open>(q - q') \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  shows \<open>\<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>] = \<lfloor>q'\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  define m where \<open>m = \<lfloor>q\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
  have ex: \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  proof -
    have unique: \<open>\<exists>!m. m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
      by (rule twoadic_decomposition_unique)
    show ?thesis
      using theI'[OF unique] m_def round_2_def by metis
  qed
  hence tgt_m: \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> and int_qm: \<open>(q - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close> by auto
  have step_diff: \<open>q' - m = (q - m) - (q - q')\<close> by (simp add: algebra_simps)
  have int_q'm: \<open>(q' - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using two_adic_integral_diff[OF int_qm assms] step_diff by argo
  have spec: \<open>m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q' - m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using tgt_m int_q'm by simp
  have unique': \<open>\<And>m'. m' \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (q' - m') \<in> \<int>\<^sub>[\<^sub>2\<^sub>] \<Longrightarrow> m' = m\<close>
    using twoadic_decomposition_unique[of q'] spec by metis
  show ?thesis
    unfolding round_2_def using spec unique'
    by (metis (no_types, lifting) m_def round_2_def the_equality)
qed

text \<open>Next, we gather a few basic arithmetic properties of 2-adic rounding.
First, the 2-adic round of an integer divided by \<^term>\<open>2^n :: int\<close> is its
signed remainder modulo \<^term>\<open>2^n :: int\<close>, scaled. The candidate is dyadic and lies in \<open>[-\<onehalf>, \<onehalf>)\<close>;
the integer remainder \<^term>\<open>(x - x mod\<^sup>\<plusminus> 2^n) div 2^n\<close> is trivially in \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close>.\<close>

lemma round_2_int_div_pow2:
  assumes npos: \<open>n > 0\<close>
  shows \<open>\<lfloor>x /\<^sub>\<rat> 2^n\<rceil>\<^sub>[\<^sub>2\<^sub>] = (x mod\<^sup>\<plusminus> 2^n /\<^sub>\<rat> 2^n)\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>x mod\<^sup>\<plusminus> ?R\<close>
  let ?m = \<open>?k /\<^sub>\<rat> ?R\<close>  let ?q = \<open>x /\<^sub>\<rat> ?R\<close>
  have R_eq: \<open>?R = 2 * (?R div 2)\<close> using npos by (induction n) auto
  have target_m: \<open>?m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close>
  proof -
    have d: \<open>?m \<in> \<int>\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>]\<close> using int_div_pow2_dyadic[of ?k n] by simp
    have lo: \<open>2 * ?k \<ge> -?R\<close> using mod_signed_lower[of ?R x] R_eq by simp
    have hi: \<open>2 * ?k < ?R\<close> using mod_signed_upper[of ?R x] R_eq by simp
    have lor: \<open>2 * ?k\<^sub>\<rat> \<ge> - ?R\<^sub>\<rat>\<close> using lo
      by (metis of_int_minus of_int_le_iff of_int_mult of_int_numeral)
    have hir: \<open>2 * ?k\<^sub>\<rat> < ?R\<^sub>\<rat>\<close> using hi
      by (metis of_int_less_iff of_int_mult of_int_numeral)
    show ?thesis unfolding two_adic_target_iff using d lor hir by (simp add: field_simps)
  qed
  obtain s where s_def: \<open>x - ?k = ?R * s\<close>
    using R_dvd_z_minus_smod[of ?R x] by (elim dvdE)
  have integral_diff: \<open>(?q - ?m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
  proof -
    have \<open>x\<^sub>\<rat> - ?k\<^sub>\<rat> = ?R\<^sub>\<rat> * s\<^sub>\<rat>\<close>
      using s_def by (metis of_int_diff of_int_mult)
    hence \<open>?q - ?m = s\<^sub>\<rat>\<close> by (simp add: field_simps)
    thus ?thesis by simp
  qed
  have spec: \<open>?m \<in> [-\<onehalf>, \<onehalf>)\<^sub>[\<^sub>1\<^sub>/\<^sub>2\<^sub>] \<and> (?q - ?m) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using target_m integral_diff by simp
  show ?thesis unfolding round_2_def using spec
    by (rule the_equality) (metis spec twoadic_decomposition_unique[of ?q])
qed

text \<open>Next, \<^term>\<open>1 /\<^sub>\<rat> N\<close> is 2-adically congruent to
\<^term>\<open>(N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>\<close> modulo \<^term>\<open>R\<close>. While this looks trivial, it should be noted that the
left hand side computes \<^term>\<open>1 /\<^sub>\<rat> N\<close> as a \<^emph>\<open>rational\<close> quotient, while the right hand side
computes \<^term>\<open>N\<^sup>-\<^sup>1 mod R\<close> as a quotient in \<open>\<int>/R \<int>\<close> and then re-embeds it into \<^term>\<open>\<rat>\<close> via
the composition of the unsigned embedding \<open>\<int>/R\<int> \<hookrightarrow> \<int>\<close> and the standard embedding \<open>\<int>\<hookrightarrow>\<rat>\<close>.
The point is that \<^term>\<open>\<int>\<^sub>[\<^sub>2\<^sub>]\<close> is a domain that can hoist both while also keeping \<^term>\<open>R\<close>
non-invertible, and hence allowing arithmetic modulo \<^term>\<open>R\<close> in it.\<close>

lemma (in BarrettContext) mod_inverse_cong:
  shows \<open>[1 /\<^sub>\<rat> N = (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    and \<open>[z\<^sub>\<rat> * (1 /\<^sub>\<rat> N) = z\<^sub>\<rat> * (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
proof -
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod R)) mod R = 1 mod R\<close>
    using mod_inverse_correct(3) .
  have \<open>R dvd (N * (N\<^sup>-\<^sup>1 mod R) - 1)\<close>
    using inv by (metis mod_eq_dvd_iff)
  then obtain j where j_eq: \<open>N * (N\<^sup>-\<^sup>1 mod R) - 1 = R * j\<close>
    by (elim dvdE)
  have \<open>1 /\<^sub>\<rat> N - (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat> = (1 - N * (N\<^sup>-\<^sup>1 mod R)) /\<^sub>\<rat> N\<close>
    by (simp add: field_simps)
  also have \<open>\<dots> = (- (R * j)) /\<^sub>\<rat> N\<close>
    using j_eq by (metis minus_diff_eq)
  also have \<open>\<dots> = R\<^sub>\<rat> * ((- j) /\<^sub>\<rat> N)\<close>
    by (simp add: field_simps)
  finally have decomp: \<open>1 /\<^sub>\<rat> N - (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat> = R\<^sub>\<rat> * ((- j) /\<^sub>\<rat> N)\<close> .
  have \<open>(1 /\<^sub>\<rat> N - (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>) / R\<^sub>\<rat> = (- j) /\<^sub>\<rat> N\<close>
    unfolding decomp by (simp add: field_simps)
  thus base2: \<open>[1 /\<^sub>\<rat> N = (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    using two_adic_integral_div_odd[OF Npos Nodd, of \<open>- j\<close>] by simp
  show \<open>[z\<^sub>\<rat> * (1 /\<^sub>\<rat> N) = z\<^sub>\<rat> * (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    by (rule cong_R_two_adic_scale[OF base2])
qed

text \<open>Taking both together gives the following concrete formula for the 
2-adic round of \<^term>\<open>z\<^sub>\<rat> / (N\<^sub>\<rat>*R\<^sub>\<rat>)\<close>. The reader will already notice the similarity
of the right hand side with the definition of Montgomery reduction of \<^term>\<open>z\<close>.\<close>

lemma (in BarrettContext) round_2_div_NR:
  shows \<open>\<lfloor>z /\<^sub>\<rat> (N * R)\<rceil>\<^sub>[\<^sub>2\<^sub>] = ((z * (N\<^sup>-\<^sup>1 mod R)) mod\<^sup>\<plusminus> R) /\<^sub>\<rat> R\<close>
proof -
  have eq: \<open>(z\<^sub>\<rat> * (1 /\<^sub>\<rat> N) - z\<^sub>\<rat> * (N\<^sup>-\<^sup>1 mod R)\<^sub>\<rat>) / R\<^sub>\<rat>
            = z /\<^sub>\<rat> (N * R) - (z * (N\<^sup>-\<^sup>1 mod R)) /\<^sub>\<rat> R\<close>
    by (simp add: field_simps of_int_mult)
  have inv_int: \<open>(z /\<^sub>\<rat> (N * R) - (z * (N\<^sup>-\<^sup>1 mod R)) /\<^sub>\<rat> R) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using mod_inverse_cong(2)[of z] unfolding eq[symmetric] by simp
  have eq1: \<open>z\<^sub>\<rat> / (N\<^sub>\<rat> * R\<^sub>\<rat>) = z /\<^sub>\<rat> (N * R)\<close> by (simp add: of_int_mult)
  have inv_step: \<open>\<lfloor>z /\<^sub>\<rat> (N * R)\<rceil>\<^sub>[\<^sub>2\<^sub>] = \<lfloor>(z * (N\<^sup>-\<^sup>1 mod R)) /\<^sub>\<rat> R\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
    using round_2_invariance[OF inv_int] eq1 by simp
  show ?thesis
    using inv_step round_2_int_div_pow2[OF npos, of \<open>z * (N\<^sup>-\<^sup>1 mod R)\<close>] by simp
qed

text\<open>Finally, this establishes the description of Montgomery reduction
through 2-adic rounding:\<close>

theorem (in BarrettContext) mont_sub_signed_as_round_2:
  shows \<open>(mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat> = z /\<^sub>\<rat> R - N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> (N * R)\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  define k :: int where \<open>k = (z * (N\<^sup>-\<^sup>1 mod R)) mod\<^sup>\<plusminus> R\<close>
  have inv: \<open>(N * (N\<^sup>-\<^sup>1 mod R)) mod R = 1 mod R\<close>
    using mod_inverse_correct(3) by simp
  from mont_sub_signed_divisible[OF inv, of z] obtain s where
    s_eq: \<open>z - k * N = R * s\<close> unfolding k_def by (auto simp: mult.commute elim: dvdE)
  have unfold_eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = s\<close>
    using mont_sub_signed_unfold[OF inv, of z] s_eq unfolding k_def by simp
  have rat_eq: \<open>s\<^sub>\<rat> = z /\<^sub>\<rat> R - N\<^sub>\<rat> * (k /\<^sub>\<rat> R)\<close>
    using s_eq by (simp add: field_simps)
  show ?thesis
    using unfold_eq rat_eq round_2_div_NR[of z]
    unfolding k_def by simp
qed

text %internal \<open>The additive variant has the same form, with the \emph{argument} of the
2-adic round negated --- a uniform formulation requiring no case split, since
negating the argument absorbs the \<open>mont\<^sub>s\<^sub>u\<^sub>b\<close>/\<open>mont\<^sub>a\<^sub>d\<^sub>d\<close> distinction.\<close>

theorem %internal (in BarrettContext) mont_add_signed_as_round_2:
  shows \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z)\<^sub>\<rat> = z /\<^sub>\<rat> R + N\<^sub>\<rat> * \<lfloor>- z /\<^sub>\<rat> (N * R)\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
proof -
  define T :: int where \<open>T = - (N\<^sup>-\<^sup>1 mod R)\<close>
  define k :: int where \<open>k = (z * (- (N\<^sup>-\<^sup>1 mod R))) mod\<^sup>\<plusminus> R\<close>
  note T_def [simp] k_def [simp]

  have inv: \<open>(N * T) mod R = (- 1) mod R\<close>
    using mod_inverse_correct(3) by (simp, metis mod_minus_eq mult_minus_right)
  have k_eq: \<open>k = ((- z) * (N\<^sup>-\<^sup>1 mod R)) mod\<^sup>\<plusminus> R\<close> by (simp add: algebra_simps)
  have unfold_eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> z = (z + k * N) div R\<close>
    using mont_add_signed_unfold[OF inv[unfolded T_def], of z] by simp
  have R_dvd: \<open>R dvd (z + k * N)\<close>
    using mont_sub_signed_divisible[OF mod_inverse_correct(3), of \<open>- z\<close>]
          k_eq dvd_minus_iff[of R "z + k * N"]
    by (simp add: mult.commute)
  obtain s where s_eq: \<open>z + k * N = R * s\<close> using R_dvd by (elim dvdE) simp
  have d1: \<open>(z + k * N) div R = s\<close> using s_eq by simp
  have d2: \<open>(z\<^sub>\<rat> + k\<^sub>\<rat> * N\<^sub>\<rat>) = R\<^sub>\<rat> * s\<^sub>\<rat>\<close> using s_eq by (metis of_int_add of_int_mult)
  have div_to_rat: \<open>((z + k * N) div R)\<^sub>\<rat> = (z + k * N) /\<^sub>\<rat> R\<close> using d1 d2 by (simp add: field_simps)
  have round2_eq: \<open>\<lfloor>- z /\<^sub>\<rat> (N * R)\<rceil>\<^sub>[\<^sub>2\<^sub>] = k /\<^sub>\<rat> R\<close>
    using round_2_div_NR[of \<open>- z\<close>] k_eq by (simp add: field_simps)
  show ?thesis using unfold_eq div_to_rat round2_eq by (simp add: field_simps)
qed

section \<open>The Barrett--Montgomery bridge\<close>

text\<open>To derive the connection between Montgomery and Barrett arithmetic, the last remaining
piece is the following identity relating \<^term>\<open>1/N\<close> and \<open>\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<close> modulo \<^term>\<open>R\<close>:\<close>

lemma (in BarrettContext) magic_const_cong:
  shows \<open>[\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> = - (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    and \<open>[z\<^sub>\<rat> * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> = z\<^sub>\<rat> * (- (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N)] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
proof -
  have eq: \<open>\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> - (- (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N) = R /\<^sub>\<rat> N\<close>
    using magic_const_rat[OF f_approx, of N R] Npos by (simp add: field_simps)
  have \<open>(\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> - (- (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N)) / R\<^sub>\<rat> = 1 /\<^sub>\<rat> N\<close>
    using eq by (simp add: of_int_mult field_simps)
  thus base': \<open>[\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> = - (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    using two_adic_integral_div_odd[OF Npos Nodd, of 1] by simp
  show \<open>[z\<^sub>\<rat> * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat> = z\<^sub>\<rat> * (- (R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N)] (mod R \<int>\<^sub>[\<^sub>2\<^sub>])\<close>
    by (rule cong_R_two_adic_scale[OF base'])
qed

text \<open>The signed Barrett--Montgomery bridge is now a simple chain of equalities putting
together the facts established above:\<close>

text %proofnote \<open>\noindent\textit{Note.} Proof bodies are normally elided in
this PDF; we exceptionally retain this one because of its brevity and
centrality. See \autoref{ch:methodology} for the editorial policy.\<close>

theorem (in BarrettContext) bridge_signed_conceptual:
  shows \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N))\<close>
proof %visible -
  have cong: \<open>(z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R - (- ((z * (R mod\<lbrakk>f\<rbrakk> N)) /\<^sub>\<rat> (N * R)))) \<in> \<int>\<^sub>[\<^sub>2\<^sub>]\<close>
    using magic_const_cong(2)[of z] by (simp add: field_simps of_int_mult)
  have key: \<open>N\<^sub>\<rat> * (z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R) + (z * (R mod\<lbrakk>f\<rbrakk> N)) /\<^sub>\<rat> R = z\<^sub>\<rat>\<close>
    unfolding mod_approx_def by (simp add: field_simps)
  have \<open>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat> = z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R\<rceil>\<^sub>[\<^sub>\<infinity>\<^sub>]\<close>
    by (rule bar_signed_as_round_E)
  also have \<open>\<dots> = z\<^sub>\<rat> - N\<^sub>\<rat> * (z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R - \<lfloor>z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R\<rceil>\<^sub>[\<^sub>2\<^sub>])\<close>
    using complementarity[OF int_div_pow2_dyadic[of \<open>z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<close> n]] by simp
  also have \<open>\<dots> = (z * (R mod\<lbrakk>f\<rbrakk> N)) /\<^sub>\<rat> R + N\<^sub>\<rat> * \<lfloor>z * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk> /\<^sub>\<rat> R\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
    using key by (simp add: algebra_simps)
  also have \<open>\<dots> = (z * (R mod\<lbrakk>f\<rbrakk> N)) /\<^sub>\<rat> R + N\<^sub>\<rat> * \<lfloor>- ((z * (R mod\<lbrakk>f\<rbrakk> N)) /\<^sub>\<rat> (N * R))\<rceil>\<^sub>[\<^sub>2\<^sub>]\<close>
    using round_2_invariance[OF cong] by simp
  also have \<open>\<dots> = (mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N)))\<^sub>\<rat>\<close>
    using mont_add_signed_as_round_2[of \<open>z * (R mod\<lbrakk>f\<rbrakk> N)\<close>] by (simp add: algebra_simps)
  finally show ?thesis
    by (metis of_int_eq_iff)
qed


end

