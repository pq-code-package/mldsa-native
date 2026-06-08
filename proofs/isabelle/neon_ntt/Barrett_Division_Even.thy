(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Barrett_Division_Even
  imports Bridge_Conceptual
begin

chapter \<open>Barrett division for even moduli \label{ch:barrett_division_even}\<close>

text \<open>
The Montgomery reduction and multiplication of the previous chapters are
defined in terms of the inverse \<^term>\<open>N\<^sup>-\<^sup>1 mod R\<close>, and are hence --- \<^emph>\<open>as
written\<close> --- confined to an odd modulus \<^term>\<open>N\<close>. Implementations of the ML-DSA
\<^emph>\<open>decompose\<close> routine \cite[Algorithm~36]{FIPS204}, however, often use Barrett
arithmetic to divide exactly by an \<^emph>\<open>even\<close> modulus. The purpose of this chapter is to explain how the previous chapters
can be generalized to even moduli, obtaining exactness of Barrett division
as a corollary to (a version of) signed canonicity of Barrett reduction derived
from the Barrett-Montgomery bridge.

The main observation is that the Montgomery reduction of \<^term>\<open>z\<close> does not need
\<^term>\<open>N\<^sup>-\<^sup>1 mod R\<close> to exist, but only the division \<^term>\<open>z / N\<close> \<^emph>\<open>modulo \<^term>\<open>R\<close>\<close>.
This quotient can exist even if \<^term>\<open>N\<^sup>-\<^sup>1 mod R\<close> doesn't, though it is also non-unique
in this case. We generalize the definition of Montgomery arithmetic to the choice of
such modular quotients, and show how to express the Barrett--Montgomery bridge in this setting.
Signed canonicity of Barrett reduction follows along the sames lines as before, and the exactness
of Barrett division is a corollary.
\<close>
section \<open>Montgomery arithmetic again -- for any modulus\<close>

(*<*) context OddModulus begin (*>*)
text \<open>For an even modulus, \<^term>\<open>N\<close> is not invertible modulo \<^term>\<open>R = 2^n\<close>, so
the definition \<^latex>\<open>\begin{center}\<close>@{thm [show_question_marks=false] mont_sub_signed_def}\<^latex>\<open>\end{center}\<close>is ill-defined as written. However, it is well-defined as a partial function if we replace \<^term>\<open>z * (N\<^sup>-\<^sup>1 mod R)\<close> by a \<^emph>\<open>choice\<close> of modular quotient
\<open>z / N mod R\<close>, assuming it exists. This renders Montgomery reduction well-defined for all inputs
whose residue \<open>mod R\<close> is a multiple of \<^term>\<open>N\<close>:\<close> (*<*) end (*>*)

definition div_mod :: \<open>int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> bool\<close>
    (\<open>(_) \<equiv> (_) '/ (_) '(mod _')\<close> [61, 61, 61, 61] 60) where
  \<open>q \<equiv> a / b (mod m) \<equiv> (b * q) mod m = a mod m\<close>

text \<open>\noindent A modular division by a unit is computed by its inverse:\<close>

lemma div_mod_inv_iff:
  assumes \<open>(b * binv) mod m = 1 mod m\<close>
  shows \<open>(q \<equiv> a / b (mod m)) \<longleftrightarrow> q mod m = (a * binv) mod m\<close>
proof
  assume \<open>q \<equiv> a / b (mod m)\<close>
  hence h: \<open>(b * q) mod m = a mod m\<close> unfolding div_mod_def .
  have \<open>q mod m = (q * ((b * binv) mod m)) mod m\<close>
    using assms by (metis mod_mult_right_eq mult.right_neutral)
  also have \<open>... = (binv * (b * q)) mod m\<close> by (metis mod_mult_right_eq mult.assoc mult.commute)
  also have \<open>... = (binv * a) mod m\<close> using h by (metis mod_mult_right_eq)
  finally show \<open>q mod m = (a * binv) mod m\<close> by (simp add: mult.commute)
next
  assume h: \<open>q mod m = (a * binv) mod m\<close>
  have \<open>(b * q) mod m = (b * (a * binv)) mod m\<close> using h by (metis mod_mult_right_eq)
  also have \<open>... = (a * ((b * binv) mod m)) mod m\<close> by (metis mod_mult_right_eq mult.assoc mult.commute)
  also have \<open>... = a mod m\<close> using assms by (metis mod_mult_right_eq mult.right_neutral)
  finally show \<open>q \<equiv> a / b (mod m)\<close> unfolding div_mod_def .
qed

text\<open>\noindent This readily specializes to the case of interest to us:\<close>

corollary div_mod_odd_iff:
  assumes \<open>n > 0\<close> and \<open>odd N\<close>
  shows \<open>(q \<equiv> a / N (mod 2^n)) \<longleftrightarrow> q mod 2^n = (a * (N\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  using div_mod_inv_iff[OF mod_inverse_correct(3)[OF assms]] .

text \<open>Montgomery reduction for any modulus takes an input \<^term>\<open>z\<close> and a chosen
modular quotient \<^term>\<open>z_div_N\<close> of \<^term>\<open>- z\<close> by \<^term>\<open>N\<close> modulo \<^term>\<open>R = 2^n\<close>, and
returns \<^term>\<open>(z + (z_div_N mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>. The shape mirrors the
additive signed Montgomery reduction \<^term>\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk>\<close> of
\autoref{ch:montgomery_red}, with the chosen inverse replaced by the explicit
quotient.\<close>

definition mont_red (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<langle>_; _\<rangle>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle> \<equiv> (z + ((z_div_N mod\<^sup>\<plusminus> 2^n) * N)) div 2^n\<close>

text %internal \<open>The radix \<^term>\<open>2^n\<close> divides the Montgomery numerator: \<^term>\<open>z_div_N mod\<^sup>\<plusminus> 2^n\<close>
is congruent to \<^term>\<open>z_div_N\<close> modulo \<^term>\<open>2^n\<close>, so \<^term>\<open>z + (z_div_N mod\<^sup>\<plusminus> 2^n) * N\<close>
reduces to \<^term>\<open>z + z_div_N * N\<close>, which the quotient condition collapses to \<^term>\<open>0\<close>.\<close>

lemma %internal mont_red_divisible:
  assumes \<open>z_div_N \<equiv> - z / N (mod 2^n)\<close>
  shows \<open>(2::int)^n dvd (z + ((z_div_N mod\<^sup>\<plusminus> 2^n) * N))\<close>
proof -
  have smod_mod: \<open>(z_div_N mod\<^sup>\<plusminus> 2^n) mod 2^n = z_div_N mod 2^n\<close>
    using R_dvd_z_minus_smod[of \<open>2^n\<close> z_div_N] by (metis mod_eq_dvd_iff)
  have step1: \<open>(z + (z_div_N mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = (z + z_div_N * N) mod 2^n\<close>
    using smod_mod by (metis mod_add_right_eq mod_mult_left_eq)
  have wit: \<open>(N * z_div_N) mod 2^n = (- z) mod 2^n\<close> using assms unfolding div_mod_def .
  have step2: \<open>(z + z_div_N * N) mod 2^n = 0\<close>
  proof -
    have \<open>(z + z_div_N * N) mod 2^n = (z + N * z_div_N) mod 2^n\<close> by (simp add: mult.commute)
    also have \<open>\<dots> = (z + ((N * z_div_N) mod 2^n)) mod 2^n\<close> by (simp add: mod_add_right_eq)
    also have \<open>\<dots> = (z + ((- z) mod 2^n)) mod 2^n\<close> using wit by simp
    also have \<open>\<dots> = (z + (- z)) mod 2^n\<close> by (simp add: mod_add_right_eq)
    also have \<open>\<dots> = 0\<close> by simp
    finally show ?thesis .
  qed
  have \<open>(z + (z_div_N mod\<^sup>\<plusminus> 2^n) * N) mod 2^n = 0\<close> using step1 step2 by simp
  thus ?thesis by (simp add: mod_eq_0_iff_dvd)
qed

text \<open>We obtain the same bound as before:\<close>

lemma %internal mont_red_bound_raw:
  assumes \<open>N > 0\<close> and \<open>z_div_N \<equiv> - z / N (mod 2^n)\<close>
  shows \<open>2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle>\<bar> * 2^n \<le> 2 * \<bar>z\<bar> + N * 2^n\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>z_div_N mod\<^sup>\<plusminus> ?R\<close>
  let ?u = \<open>z + ?k * N\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have div: \<open>?R dvd ?u\<close> using mont_red_divisible[OF assms(2)] by (simp add: mult.commute)
  have eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle> * ?R = ?u\<close>
    unfolding mont_red_def using div by (simp add: dvd_div_mult_self)
  have k_lo: \<open>- (?R div 2) \<le> ?k\<close> using mod_signed_lower R_pos by blast
  have k_hi: \<open>?k \<le> (?R - 1) div 2\<close> using mod_signed_upper R_pos by blast
  have two_k_abs: \<open>2 * \<bar>?k\<bar> \<le> ?R\<close> using k_lo k_hi by linarith
  have N_nn: \<open>N \<ge> 0\<close> using assms(1) by simp
  have step_c: \<open>2 * \<bar>?k * N\<bar> \<le> N * ?R\<close>
    using two_k_abs N_nn mult_left_mono[of \<open>2 * \<bar>?k\<bar>\<close> ?R N]
    by (simp add: abs_mult mult.assoc mult.commute)
  have abs_u: \<open>2 * \<bar>?u\<bar> \<le> 2 * \<bar>z\<bar> + N * ?R\<close>
    using abs_triangle_ineq[of z \<open>?k * N\<close>] step_c by arith
  have abs_eq: \<open>\<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle>\<bar> * ?R = \<bar>?u\<bar>\<close>
    using eq R_pos by (metis abs_mult abs_of_pos)
  show ?thesis using abs_eq abs_u by (simp add: mult.assoc mult.commute)
qed

lemma mont_red_bound:
  assumes \<open>N > 0\<close> and \<open>z_div_N \<equiv> - z / N (mod 2^n)\<close>
  shows \<open>\<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle>\<bar>\<^sub>\<rat> \<le> \<bar>z\<bar> /\<^sub>\<rat> 2^n + N /\<^sub>\<rat> 2\<close>
proof -
  let ?x = \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z; z_div_N\<rangle>\<close>
  have Rpos: \<open>(0::rat) < (2^n)\<^sub>\<rat>\<close> by simp
  have \<open>(2 * \<bar>?x\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>z\<bar> + N * 2^n)\<^sub>\<rat>\<close>
    using mont_red_bound_raw[OF assms] by (simp only: of_int_le_iff)
  hence \<open>2 * \<bar>?x\<bar>\<^sub>\<rat> * (2^n)\<^sub>\<rat> \<le> 2 * \<bar>z\<bar>\<^sub>\<rat> + (N)\<^sub>\<rat> * (2^n)\<^sub>\<rat>\<close>
    by (simp add: of_int_mult of_int_add of_int_abs)
  thus ?thesis using Rpos by (simp add: field_simps)
qed

text \<open>Montgomery multiplication also generalizes to potentially even moduli
by passing (and assuming the existence of) a chosen modular quotient @{term \<open>b_tw \<equiv> b / N (mod R)\<close>}:\<close>

definition mont_mul (\<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>_,_\<rbrakk>\<langle>_, _; _\<rangle>\<close>) where
  \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b; b_tw\<rangle> \<equiv> (a * b + ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N) div 2^n\<close>

text \<open>As expected, multiplication is just reduction of the product against the folded twiddle:\<close>

lemma mont_mul_as_red:
  shows \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b; b_tw\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a * b; a * b_tw\<rangle>\<close>
  unfolding mont_mul_def mont_red_def by (rule refl)

text %internal \<open>If the twiddle is a division of \<^term>\<open>- b\<close> by \<^term>\<open>N\<close> modulo \<^term>\<open>R\<close>, then the
folded twiddle \<^term>\<open>a * b_tw\<close> is a division of \<^term>\<open>- (a * b)\<close>, so the
multiplication numerator is divisible by \<^term>\<open>R\<close> --- via the reduction.\<close>

lemma %internal mont_mul_divisible:
  assumes \<open>b_tw \<equiv> - b / N (mod 2^n)\<close>
  shows \<open>(2::int)^n dvd (a * b + ((a * b_tw) mod\<^sup>\<plusminus> 2^n) * N)\<close>
proof -
  have wit: \<open>(a * b_tw) \<equiv> - (a * b) / N (mod 2^n)\<close>
  proof -
    have \<open>(N * (a * b_tw)) mod 2^n = (a * (N * b_tw)) mod 2^n\<close> by (simp add: algebra_simps)
    also have \<open>\<dots> = (a * ((N * b_tw) mod 2^n)) mod 2^n\<close> by (simp add: mod_mult_right_eq)
    also have \<open>\<dots> = (a * ((- b) mod 2^n)) mod 2^n\<close>
      using assms unfolding div_mod_def by simp
    also have \<open>\<dots> = (a * (- b)) mod 2^n\<close> by (simp add: mod_mult_right_eq)
    also have \<open>\<dots> = (- (a * b)) mod 2^n\<close> by (simp add: algebra_simps)
    finally show ?thesis unfolding div_mod_def .
  qed
  show ?thesis using mont_red_divisible[OF wit] by (simp add: mult.commute)
qed

text \<open>Correctness for any modulus: as long as the twiddle is a modular division of
\<^term>\<open>- b\<close> by \<^term>\<open>N\<close> modulo \<^term>\<open>R\<close>, the Montgomery multiplication is correct:\<close>

theorem mont_mul_correct:
  assumes \<open>b_tw \<equiv> - b / N (mod 2^n)\<close>
  shows \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b; b_tw\<rangle> * 2^n) mod N = (a * b) mod N\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>  let ?q = \<open>(a * b_tw) mod\<^sup>\<plusminus> ?R\<close>
  have dvd: \<open>?R dvd (a * b + ?q * N)\<close> using mont_mul_divisible[OF assms] .
  have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b; b_tw\<rangle> * ?R = a * b + ?q * N\<close>
    unfolding mont_mul_def using dvd by (simp add: dvd_mult_div_cancel mult.commute)
  hence \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>a, b; b_tw\<rangle> * ?R) mod N = (a * b + ?q * N) mod N\<close> by simp
  also have \<open>\<dots> = (a * b) mod N\<close> by simp
  finally show ?thesis .
qed

section \<open>The Barrett--Montgomery bridge, again\<close>

(*<*) context BarrettContext begin (*>*)
text \<open>Recall the bridge for an odd modulus (\autoref{ch:barrett_montgomery}):
signed Barrett reduction is signed Montgomery reduction of the input scaled by the
correction \<^term>\<open>R mod\<lbrakk>f\<rbrakk> N\<close>:
\<^latex>\<open>\begin{center}\<close>@{thm [show_question_marks=false] (concl) barrett_montgomery_bridge(1)}\<^latex>\<open>\end{center}\<close>
To make sense of this for even \<^term>\<open>N\<close>, we exhibit a modular quotient of \<^term>\<open>R mod\<lbrakk>f\<rbrakk> N\<close> by \<^term>\<open>N\<close>.\<close>
(*<*) end (*>*)

text %internal \<open>The general fact behind this: for \<^emph>\<open>any\<close> correction \<^term>\<open>c = R - N * M\<close>,
the value \<^term>\<open>z * M\<close> is a modular quotient of \<^term>\<open>- (z * c)\<close> by \<^term>\<open>N\<close>. From
\<^term>\<open>N * M + c = R\<close> we get \<^term>\<open>N * (z * M) = z * R - z * c\<close>, hence
\<^term>\<open>(N * (z * M)) mod R = (- (z * c)) mod R\<close>.\<close>

lemma %internal magic_quotient:
  fixes N :: int and n :: nat and z M c :: int
  assumes c_def: \<open>c = 2^n - N * M\<close>
  shows \<open>(z * M) \<equiv> - (z * c) / N (mod 2^n)\<close>
proof -
  have \<open>N * (z * M) = z * (N * M)\<close> by (simp add: algebra_simps)
  also have \<open>\<dots> = z * (2^n - c)\<close> using c_def by simp
  also have \<open>\<dots> = z * 2^n - z * c\<close> by (simp add: algebra_simps)
  finally have \<open>N * (z * M) = z * 2^n - z * c\<close> .
  hence \<open>(N * (z * M)) mod 2^n = (- (z * c)) mod 2^n\<close>
    by (metis mod_mult_self2 mult.commute uminus_add_conv_diff)
  thus ?thesis unfolding div_mod_def .
qed

lemma magic_quotient_f:
  fixes N :: int and n :: nat and f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  shows \<open>\<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk> \<equiv> - (2^n mod\<lbrakk>f\<rbrakk> N) / N (mod 2^n)\<close>
proof -
  have c_eq: \<open>(2^n mod\<lbrakk>f\<rbrakk> N) = 2^n - N * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk>\<close>
    unfolding mod_approx_def by simp
  show ?thesis using magic_quotient[OF c_eq, of 1] by simp
qed

(*<*) context BarrettContext begin (*>*)
text \<open>The bridge then carries over to \<^emph>\<open>any\<close> modulus, passing @{term \<open>\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<close>}
as the concrete choice of modular quotient:\<close>
(*<*) end (*>*)

lemma %internal barrett_montgomery_bridge_any_red:
  fixes N :: int and n :: nat and z :: int and f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  shows \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * (2^n mod\<lbrakk>f\<rbrakk> N); z * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk>\<rangle>\<close>
proof -
  define M where \<open>M = \<lbrakk>(2^n :: int) /\<^sub>\<rat> N\<rbrakk>\<close>
  define c where \<open>c = (2^n :: int) mod\<lbrakk>f\<rbrakk> N\<close>
  have cNM: \<open>c + N * M = 2^n\<close> unfolding c_def M_def mod_approx_def by simp
  let ?q = \<open>\<lfloor>z * M /\<^sub>\<rat> 2^n\<rceil>\<close>
  have bar: \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = z - N * ?q\<close>
    unfolding barrett_red_signed_def M_def by simp
  have smod: \<open>(z * M) mod\<^sup>\<plusminus> 2^n = z * M - 2^n * ?q\<close>
    unfolding mod_approx_def by simp
  have num: \<open>z * c + ((z * M) mod\<^sup>\<plusminus> 2^n) * N = 2^n * (z - N * ?q)\<close>
  proof -
    have \<open>z * c + ((z * M) mod\<^sup>\<plusminus> 2^n) * N = z * c + N * (z * M) - N * (2^n * ?q)\<close>
      unfolding smod by (simp add: algebra_simps)
    also have \<open>\<dots> = z * (c + N * M) - N * (2^n * ?q)\<close> by (simp add: algebra_simps)
    also have \<open>\<dots> = z * 2^n - N * (2^n * ?q)\<close> using cNM by simp
    also have \<open>\<dots> = 2^n * (z - N * ?q)\<close> by (simp add: algebra_simps)
    finally show ?thesis .
  qed
  have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * c; z * M\<rangle> = (2^n * (z - N * ?q)) div 2^n\<close>
    unfolding mont_red_def using num by simp
  also have \<open>\<dots> = z - N * ?q\<close> by simp
  finally show ?thesis using bar unfolding M_def c_def by simp
qed

text %internal \<open>Folding the input into the precomputed twiddle (\<open>mont_mul_as_red\<close>), this is
exactly a Montgomery \<^emph>\<open>multiplication\<close>: Barrett reduction of \<^term>\<open>z\<close> is the
Montgomery product of \<^term>\<open>z\<close> with the correction \<open>R mod\<^bsub>f\<^esub> N\<close>, against the magic
\<open>f (R/N)\<close> as twiddle.\<close>

lemma barrett_montgomery_bridge_any:
  fixes N :: int and n :: nat and z :: int and f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  shows \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z, 2^n mod\<lbrakk>f\<rbrakk> N; \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk>\<rangle>\<close>
proof -
  have \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z, 2^n mod\<lbrakk>f\<rbrakk> N; \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk>\<rangle>
        = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * (2^n mod\<lbrakk>f\<rbrakk> N); z * \<lbrakk>2^n /\<^sub>\<rat> N\<rbrakk>\<rangle>\<close>
    by (rule mont_mul_as_red)
  thus ?thesis using barrett_montgomery_bridge_any_red[of N n f z] by simp
qed

text \<open>As before, we derive a bound for Barrett multiplication from the bridge:\<close>

theorem %internal barrett_bound_gen_raw:
  fixes N :: int and n :: nat and z :: int and f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes Npos: \<open>N > 0\<close>
  shows \<open>2 * \<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> * 2^n \<le> 2 * \<bar>z * (2^n mod\<lbrakk>f\<rbrakk> N)\<bar> + N * 2^n\<close>
proof -
  define M where \<open>M = \<lbrakk>(2^n :: int) /\<^sub>\<rat> N\<rbrakk>\<close>
  define c where \<open>c = (2^n :: int) mod\<lbrakk>f\<rbrakk> N\<close>
  have c_eq: \<open>c = (2^n :: int) - N * M\<close> unfolding c_def M_def mod_approx_def by simp
  have \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * c; z * M\<rangle>\<close>
    using barrett_montgomery_bridge_any_red[of N n f z] unfolding M_def c_def by simp
  moreover have \<open>2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * c; z * M\<rangle>\<bar> * 2^n \<le> 2 * \<bar>z * c\<bar> + N * 2^n\<close>
    using mont_red_bound_raw[OF Npos magic_quotient[OF c_eq]] by simp
  ultimately show ?thesis unfolding c_def by simp
qed

theorem barrett_bound_gen:
  fixes N :: int and n :: nat and z :: int and f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes Npos: \<open>N > 0\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z * (2^n mod\<lbrakk>f\<rbrakk> N)\<bar> /\<^sub>\<rat> 2^n + N /\<^sub>\<rat> 2\<close>
proof -
  let ?b = \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<close>
  let ?c = \<open>z * (2^n mod\<lbrakk>f\<rbrakk> N)\<close>
  have Rpos: \<open>(0::rat) < (2^n)\<^sub>\<rat>\<close> by simp
  have \<open>(2 * \<bar>?b\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>?c\<bar> + N * 2^n)\<^sub>\<rat>\<close>
    using barrett_bound_gen_raw[OF Npos] by (simp only: of_int_le_iff)
  hence \<open>2 * \<bar>?b\<bar>\<^sub>\<rat> * (2^n)\<^sub>\<rat> \<le> 2 * \<bar>?c\<bar>\<^sub>\<rat> + (N)\<^sub>\<rat> * (2^n)\<^sub>\<rat>\<close>
    by (simp add: of_int_mult of_int_add of_int_abs)
  thus ?thesis using Rpos by (simp add: field_simps)
qed

section \<open>Exactness of Barrett division via signed-canonicity\<close>

text \<open>Recall from \<open>barrett_red_signed_exact_iff\<close> (\autoref{ch:barrett_montgomery})
that exactness of the Barrett quotient and signed-canonicity of the Barrett
reduction are equivalent. In this section we obtain a sufficient condition for the
generalized (any-modulus) Barrett reduction to be signed-canonical, and read off
exactness of the Barrett-division quotient as a corollary.\<close>

text \<open>\noindent\textbf{Warning.} The signed-canonical window below is the half-open
interval \<open>- N/2 < x \<le> N/2\<close>: it admits \<^term>\<open>N /\<^sub>\<rat> 2\<close> and \<^emph>\<open>excludes\<close>
\<^term>\<open>- (N /\<^sub>\<rat> 2)\<close>, matching the round-half-down \<open>mod\<^sup>\<plusminus>\<close> of
\cite[Algorithm~36]{FIPS204}. It is the \<^emph>\<open>mirror image\<close> of the \<open>mod\<^sup>\<plusminus>\<close> used
here, whose range \<^term>\<open>- (N div 2) \<le> x\<close>, \<^term>\<open>x < N div 2\<close> admits
\<open>-N/2\<close> and excludes \<open>N/2\<close>: the two place the half-way point at opposite ends.
Our \<open>mod\<^sup>\<plusminus>\<close> matches the two's-complement interpretation of signed machine
words, which is why it admits \<open>-N/2\<close> rather than \<open>N/2\<close>.\<close>

theorem barrettE_signed_canonical:
  fixes N :: int and n :: nat and z c :: int
  assumes Npos: \<open>N > 0\<close> and znn: \<open>0 \<le> z\<close> and cpos: \<open>0 < c\<close>
      and c_def: \<open>c = 2^n - N * \<lfloor>2^n /\<^sub>\<rat> N\<rfloor>\<close>
      and small: \<open>2 * (z * c) < 2^n\<close>
  shows \<open>- (N /\<^sub>\<rat> 2) < (bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z)\<^sub>\<rat>\<close>
    and \<open>(bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z)\<^sub>\<rat> \<le> N /\<^sub>\<rat> 2\<close>
proof -
  define M where \<open>M = \<lfloor>(2^n :: int) /\<^sub>\<rat> N\<rfloor>\<close>
  define q where \<open>q = \<lfloor>z * M /\<^sub>\<rat> 2^n\<rceil>\<close>
  define k where \<open>k = (z * M) mod\<^sup>\<plusminus> 2^n\<close>
  have c_def': \<open>c = 2^n - N * M\<close> using c_def unfolding M_def by simp
  have bar_eq: \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z = z - N * q\<close>
    unfolding q_def barrett_red_signed_def M_def by simp
  \<comment> \<open>The signed Montgomery identity carried by the bridge: \<open>(z - N q) \<cdot> R = z\<cdot>c + N\<cdot>k\<close>,
      where \<^term>\<open>k\<close> is the signed residue \<^term>\<open>(z * M) mod\<^sup>\<plusminus> 2^n\<close>.\<close>
  have quot: \<open>(z * M) \<equiv> - (z * c) / N (mod 2^n)\<close> by (rule magic_quotient[OF c_def'])
  have div: \<open>(2::int)^n dvd (z * c + N * k)\<close>
    using mont_red_divisible[OF quot] unfolding k_def by (simp add: mult.commute)
  have montred_eq: \<open>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * c; z * M\<rangle> = (z * c + N * k) div 2^n\<close>
    unfolding mont_red_def k_def by (simp add: mult.commute)
  have bar_montred: \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus> \<lbrakk>N, n\<rbrakk>\<langle>z * c; z * M\<rangle>\<close>
    using barrett_montgomery_bridge_any_red[of N n \<open>\<lfloor>\<cdot>\<rfloor>\<close> z] c_def' M_def unfolding mod_approx_def by simp
  have ident: \<open>(z - N * q) * 2^n = z * c + N * k\<close>
  proof -
    have \<open>(z - N * q) = (z * c + N * k) div 2^n\<close> using bar_eq bar_montred montred_eq by simp
    thus ?thesis using div by (simp add: dvd_mult_div_cancel)
  qed
  have k_lo: \<open>- (2^n div 2) \<le> k\<close>
    using mod_canonical_bounds(1)[of \<open>2^n\<close> \<open>z*M\<close>] unfolding k_def by simp
  have k_hi: \<open>2 * k < 2^n\<close>
    using mod_canonical_bounds(2)[of \<open>2^n\<close> \<open>z*M\<close>] unfolding k_def by simp
  have twok_lo: \<open>- (2^n) \<le> 2 * k\<close> using k_lo by simp
  have Rpos: \<open>(2::int)^n > 0\<close> by simp
  have zcnn: \<open>0 \<le> z * c\<close> using znn cpos by simp
  \<comment> \<open>Upper end of the window: closed, since \<^term>\<open>2 * (z * c) < 2^n\<close> and \<^term>\<open>2 * k < 2^n\<close>.\<close>
  have up: \<open>2 * (z - N * q) \<le> N\<close>
  proof -
    have \<open>2 * (z - N * q) * 2^n = 2 * (z * c) + N * (2 * k)\<close>
      using ident by (simp add: algebra_simps)
    also have \<open>\<dots> < 2^n + N * 2^n\<close>
      using small k_hi Npos by (simp add: add_strict_mono mult_strict_left_mono)
    also have \<open>\<dots> = (N + 1) * 2^n\<close> by (simp add: algebra_simps)
    finally have \<open>2 * (z - N * q) * 2^n < (N + 1) * 2^n\<close> .
    hence \<open>2 * (z - N * q) < N + 1\<close> using Rpos by (simp add: mult_less_cancel_right)
    thus ?thesis by simp
  qed
  \<comment> \<open>Lower end: strict. Equality would force the residue and the signed remainder
      to their extremes simultaneously, which \<open>0 < c\<close> rules out.\<close>
  have lo: \<open>- N < 2 * (z - N * q)\<close>
  proof -
    have base: \<open>2 * (z - N * q) * 2^n = 2 * (z * c) + N * (2 * k)\<close>
      using ident by (simp add: algebra_simps)
    have kbnd: \<open>N * (- (2^n)) \<le> N * (2 * k)\<close>
      using mult_left_mono[OF twok_lo, of N] Npos by simp
    hence ge: \<open>- (N * 2^n) \<le> 2 * (z - N * q) * 2^n\<close> using base zcnn by simp
    hence weak: \<open>- N \<le> 2 * (z - N * q)\<close>
      using ge Rpos by (simp add: mult_le_cancel_right flip: mult_minus_left)
    show ?thesis
    proof (rule ccontr)
      assume \<open>\<not> - N < 2 * (z - N * q)\<close>
      hence eq: \<open>2 * (z - N * q) = - N\<close> using weak by simp
      have \<open>2 * (z * c) + N * (2 * k) = - (N * 2^n)\<close> using base eq by simp
      hence \<open>2 * (z * c) = - (N * (2^n + 2 * k))\<close> by (simp add: algebra_simps)
      moreover have \<open>2^n + 2 * k \<ge> 0\<close> using twok_lo by simp
      ultimately have \<open>2 * (z * c) \<le> 0\<close> using Npos by (simp add: mult_le_0_iff)
      hence zc0: \<open>z * c = 0\<close> using zcnn by linarith
      hence zz: \<open>z = 0\<close> using cpos by (metis mult_eq_0_iff order_less_irrefl)
      hence kk: \<open>k = 0\<close> unfolding k_def by (simp add: mod_approx_def)
      have \<open>2 * (z - N * q) = 0\<close> using base zc0 kk Rpos by simp
      thus False using eq Npos by simp
    qed
  qed
  show \<open>- (N /\<^sub>\<rat> 2) < (bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z)\<^sub>\<rat>\<close>
    using lo bar_eq by (simp add: field_simps)
  show \<open>(bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z)\<^sub>\<rat> \<le> N /\<^sub>\<rat> 2\<close>
    using up bar_eq by (simp add: field_simps)
qed

text \<open>We obtain the desired exactness of the Barrett division as a corollary. Recall
from \autoref{ch:integer_approx} that \<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close> denotes \<^const>\<open>round_half_down\<close>,
the round-half-down operator that FIPS\,204 uses for \<^emph>\<open>decompose\<close>:\<close>

theorem barrettE_division_exact:
  fixes N :: int and n :: nat and z c :: int
  assumes Npos: \<open>N > 0\<close> and znn: \<open>0 \<le> z\<close> and cpos: \<open>0 < c\<close>
      and c_def: \<open>c = 2^n - N * \<lfloor>2^n /\<^sub>\<rat> N\<rfloor>\<close>
      and small: \<open>2 * (z * c) < 2^n\<close>
  shows \<open>\<lfloor>z * \<lfloor>2^n /\<^sub>\<rat> N\<rfloor> /\<^sub>\<rat> 2^n\<rceil> = \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<down>\<close>
proof -
  let ?q = \<open>\<lfloor>z * \<lfloor>2^n /\<^sub>\<rat> N\<rfloor> /\<^sub>\<rat> 2^n\<rceil>\<close>
  have bar_eq: \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rfloor>\<rbrakk> z = z - N * ?q\<close>
    unfolding barrett_red_signed_def by simp
  have rat: \<open>- (N /\<^sub>\<rat> 2) < (z - N * ?q)\<^sub>\<rat> \<and> (z - N * ?q)\<^sub>\<rat> \<le> N /\<^sub>\<rat> 2\<close>
    using barrettE_signed_canonical[OF Npos znn cpos c_def small] bar_eq by simp
  have lo: \<open>- N < 2 * (z - N * ?q)\<close>
  proof -
    have \<open>(- N)\<^sub>\<rat> < (2 * (z - N * ?q))\<^sub>\<rat>\<close> using rat by (simp add: field_simps of_int_mult)
    thus ?thesis by (simp only: of_int_less_iff)
  qed
  have up: \<open>2 * (z - N * ?q) \<le> N\<close>
  proof -
    have \<open>(2 * (z - N * ?q))\<^sub>\<rat> \<le> (N)\<^sub>\<rat>\<close> using rat by (simp add: field_simps of_int_mult)
    thus ?thesis by (simp only: of_int_le_iff)
  qed
  show ?thesis using round_half_down_window[OF Npos, of z ?q] lo up by simp
qed

text %internal \<open>Rewriting the round-to-nearest of a power-of-two quotient as a shifted
integer division, so the exact quotient matches the multiply-shift the kernels
actually compute.\<close>

lemma %internal round_div_by_power2:
  assumes \<open>n > 0\<close>
  shows \<open>\<lfloor>rat_of_int a / 2^n\<rceil> = (a + 2^(n-1)) div 2^n\<close>
proof -
  have fl: \<open>\<And>x. \<lfloor>rat_of_int x / 2^n\<rfloor> = x div 2^n\<close>
    by (metis floor_divide_of_int_eq of_int_eq_numeral_power_cancel_iff)
  have half: \<open>(1/2 :: rat) = 2^(n-1) / 2^n\<close>
    using assms by (metis (no_types, lifting) div_self divide_divide_eq_left
      power_eq_0_iff power_minus_mult zero_neq_numeral)
  hence \<open>rat_of_int a / 2^n + 1/2 = rat_of_int (a + 2^(n-1)) / 2^n\<close>
    using assms by (simp add: add_divide_distrib)
  thus ?thesis by (metis round_def fl)
qed

text %internal \<open>The exact-quotient theorem in the multiply-shift form used by the
implementations: round-half-down division by \<^term>\<open>N\<close> equals
\<^term>\<open>(a * M + 2^(n-1)) div 2^n\<close>.\<close>

corollary %internal barrettE_division_shift:
  fixes N :: int and n :: nat and a M c :: int
  assumes Npos: \<open>N > 0\<close> and npos: \<open>n > 0\<close> and ann: \<open>0 \<le> a\<close> and cpos: \<open>0 < c\<close>
      and M_def: \<open>M = \<lfloor>(2^n :: int) /\<^sub>\<rat> N\<rfloor>\<close> and c_def: \<open>c = (2^n :: int) - N * M\<close>
      and small: \<open>2 * (a * c) < 2^n\<close>
  shows \<open>\<lfloor>rat_of_int a / rat_of_int N\<rceil>\<^sub>\<down> = (a * M + 2^(n-1)) div 2^n\<close>
proof -
  have \<open>\<lfloor>a * M /\<^sub>\<rat> 2^n\<rceil> = \<lfloor>a /\<^sub>\<rat> N\<rceil>\<^sub>\<down>\<close>
    using barrettE_division_exact[OF Npos ann cpos _ small] c_def unfolding M_def by simp
  moreover have \<open>\<lfloor>a * M /\<^sub>\<rat> 2^n\<rceil> = (a * M + 2^(n-1)) div 2^n\<close>
    using round_div_by_power2[OF npos, of \<open>a * M\<close>] by (simp add: of_int_mult)
  ultimately show ?thesis by (simp add: of_int_mult)
qed

text %internal \<open>One further ingredient is needed for the C and AVX2 strategy, which divides
by \<^term>\<open>128\<close> before applying Barrett: for an \<^emph>\<open>even\<close> divisor \<^term>\<open>128 * B\<close>, the
round-half-down division factors as a round-up by \<^term>\<open>128\<close> followed by a
round-half-down division by \<^term>\<open>B\<close>. Evenness is essential --- it forces the
rounding ties of the outer division onto multiples of \<^term>\<open>128\<close>, where the
ceiling introduces no perturbation.\<close>

lemma %internal factor_128_window:
  fixes a B cl q :: int
  assumes Bpos: \<open>0 < B\<close> and Beven: \<open>even B\<close>
      and win1: \<open>- (128 * B) < 2 * (a - 128 * B * q) \<and> 2 * (a - 128 * B * q) \<le> 128 * B\<close>
      and cl_ub: \<open>a \<le> 128 * cl\<close> and cl_lb: \<open>128 * cl - 128 < a\<close>
  shows \<open>- B < 2 * (cl - B * q) \<and> 2 * (cl - B * q) \<le> B\<close>
proof
  have lo_raw: \<open>2 * (a - 128 * B * q) \<le> 128 * (2 * (cl - B * q))\<close>
    using cl_ub by (simp add: algebra_simps)
  have up_raw: \<open>128 * (2 * (cl - B * q)) \<le> 2 * (a - 128 * B * q) + 254\<close>
    using cl_lb by (simp add: algebra_simps)
  show \<open>- B < 2 * (cl - B * q)\<close>
  proof -
    have \<open>128 * (- B) < 128 * (2 * (cl - B * q))\<close> using win1 lo_raw by linarith
    thus ?thesis by simp
  qed
  show \<open>2 * (cl - B * q) \<le> B\<close>
  proof -
    have \<open>128 * (2 * (cl - B * q)) < 128 * (B + 2)\<close> using win1 up_raw by (simp add: algebra_simps)
    hence \<open>2 * (cl - B * q) \<le> B + 1\<close> by simp
    moreover have \<open>even (2 * (cl - B * q))\<close> by simp
    ultimately show ?thesis using Beven by presburger
  qed
qed

lemma %internal factor_128:
  fixes a B :: int
  assumes apos: \<open>0 \<le> a\<close> and Bpos: \<open>0 < B\<close> and Beven: \<open>even B\<close>
  shows \<open>\<lfloor>a /\<^sub>\<rat> (128 * B)\<rceil>\<^sub>\<down> = \<lfloor>\<lceil>a /\<^sub>\<rat> 128\<rceil> /\<^sub>\<rat> B\<rceil>\<^sub>\<down>\<close>
proof -
  define q where \<open>q = \<lfloor>a /\<^sub>\<rat> (128 * B)\<rceil>\<^sub>\<down>\<close>
  define cl where \<open>cl = \<lceil>a /\<^sub>\<rat> 128\<rceil>\<close>
  have B2pos: \<open>(0::int) < 128 * B\<close> using Bpos by simp
  have win1: \<open>- (128 * B) < 2 * (a - 128 * B * q) \<and> 2 * (a - 128 * B * q) \<le> 128 * B\<close>
    using round_half_down_window[OF B2pos, of a q] q_def by simp
  have cl_ub: \<open>a \<le> 128 * cl\<close>
  proof -
    have \<open>(of_int a :: rat) \<le> of_int cl * 128\<close>
      using ceiling_divide_upper[of \<open>(128::rat)\<close> \<open>of_int a\<close>] unfolding cl_def by simp
    hence \<open>(of_int a :: rat) \<le> of_int (128 * cl)\<close> by (simp add: of_int_mult mult.commute)
    thus ?thesis by (simp only: of_int_le_iff)
  qed
  have cl_lb: \<open>128 * cl - 128 < a\<close>
  proof -
    have \<open>(of_int cl - 1) * (128::rat) < of_int a\<close>
      using ceiling_divide_lower[of \<open>(128::rat)\<close> \<open>of_int a\<close>] unfolding cl_def by simp
    hence \<open>(of_int (128 * cl - 128) :: rat) < of_int a\<close> by (simp add: field_simps of_int_mult)
    thus ?thesis by (simp only: of_int_less_iff)
  qed
  have \<open>- B < 2 * (cl - B * q) \<and> 2 * (cl - B * q) \<le> B\<close>
    by (rule factor_128_window[OF Bpos Beven win1 cl_ub cl_lb])
  thus ?thesis
    unfolding q_def[symmetric] cl_def[symmetric]
    using round_half_down_window[OF Bpos, of cl q] by simp
qed

section \<open>ML-DSA decompose specialisations\<close>

text \<open>The above material can be specialized to the context of the \<open>decompose\<close> routine of ML-DSA 
\cite[Algorithm~36]{FIPS204}. That algorithm relies on round-half-down division of
integers in the range \<^term>\<open>{0..<MLDSA_Q}\<close> by the even integer \<^term>\<open>2 * \<gamma>\<^sub>2\<close>
\cite[Table~1]{FIPS204}. We justify two efficient Barrett-division
strategies,
both used among the backends of \texttt{mldsa-native}.\<close>

definition \<open>MLDSA_Q :: int \<equiv> 2^23 - 2^13 + 1\<close>
 \<comment>\<open>The 32-bit modulus underlying ML-DSA\<close>
definition \<open>MLDSA_GAMMA2_88 :: int \<equiv> (MLDSA_Q - 1) div 88\<close> 
\<comment>\<open>The value of \<open>\<gamma>\<^sub>2\<close> in ML-DSA-44\<close>
definition \<open>MLDSA_GAMMA2_32 :: int \<equiv> (MLDSA_Q - 1) div 32\<close> 
\<comment>\<open>The value of \<open>\<gamma>\<^sub>2\<close> in ML-DSA-65 and ML-DSA-87\<close>

text\<open>For concreteness, we confirm the specific values of the two even moduli:\<close>

lemma %visible \<open>2 * MLDSA_GAMMA2_88 = 190464\<close>
  and \<open>2 * MLDSA_GAMMA2_32 = 523776\<close>
  by eval+

text\<open>The following results are at the heart of the correctness of the AArch64
assembly computing \cite[Algorithm~36]{FIPS204} in \texttt{mldsa-native}, proved
against the instruction model in \autoref{sec:aarch64_decompose}:\<close>

corollary barrett_decompose_32_aarch64:
  assumes \<open>a \<ge> 0\<close> and \<open>a < MLDSA_Q\<close>
  shows \<open>\<lfloor>a /\<^sub>\<rat> (2 * MLDSA_GAMMA2_32)\<rceil>\<^sub>\<down> = \<lfloor>a * 1074791425 /\<^sub>\<rat> 2^49\<rceil>\<close>
proof -
  have g: \<open>(2 * MLDSA_GAMMA2_32 :: int) = 523776\<close> by (simp add: MLDSA_GAMMA2_32_def MLDSA_Q_def)
  have aQ: \<open>a < 8380417\<close> using assms(2) unfolding MLDSA_Q_def by simp
  have cc: \<open>(512 :: int) = (2^49 :: int) - 523776 * \<lfloor>(2^49 :: int) /\<^sub>\<rat> 523776\<rfloor>\<close> by eval
  have m: \<open>\<lfloor>(2^49 :: int) /\<^sub>\<rat> 523776\<rfloor> = (1074791425 :: int)\<close> by eval
  have \<open>\<lfloor>a * \<lfloor>(2^49 :: int) /\<^sub>\<rat> 523776\<rfloor> /\<^sub>\<rat> 2^49\<rceil> = \<lfloor>a /\<^sub>\<rat> 523776\<rceil>\<^sub>\<down>\<close>
    apply (rule barrettE_division_exact[where N=523776 and n=49 and c=512])
    using assms(1) aQ cc by simp_all
  thus ?thesis unfolding g using m by simp
qed

corollary barrett_decompose_88_aarch64:
  assumes \<open>a \<ge> 0\<close> and \<open>a < MLDSA_Q\<close>
  shows \<open>\<lfloor>a /\<^sub>\<rat> (2 * MLDSA_GAMMA2_88)\<rceil>\<^sub>\<down> = \<lfloor>a * 1477838209 /\<^sub>\<rat> 2^48\<rceil>\<close>
proof -
  have g: \<open>(2 * MLDSA_GAMMA2_88 :: int) = 190464\<close> by (simp add: MLDSA_GAMMA2_88_def MLDSA_Q_def)
  have aQ: \<open>a < 8380417\<close> using assms(2) unfolding MLDSA_Q_def by simp
  have cc: \<open>(71680 :: int) = (2^48 :: int) - 190464 * \<lfloor>(2^48 :: int) /\<^sub>\<rat> 190464\<rfloor>\<close> by eval
  have m: \<open>\<lfloor>(2^48 :: int) /\<^sub>\<rat> 190464\<rfloor> = (1477838209 :: int)\<close> by eval
  have \<open>\<lfloor>a * \<lfloor>(2^48 :: int) /\<^sub>\<rat> 190464\<rfloor> /\<^sub>\<rat> 2^48\<rceil> = \<lfloor>a /\<^sub>\<rat> 190464\<rceil>\<^sub>\<down>\<close>
    apply (rule barrettE_division_exact[where N=190464 and n=48 and c=71680])
    using assms(1) aQ cc by simp_all
  thus ?thesis unfolding g using m by simp
qed

text \<open>The C and AVX2 backends in mldsa-native instead divide by \<^term>\<open>128\<close> first --- rounding \<^emph>\<open>up\<close>,
i.e.\ taking \<^term>\<open>\<lceil>a /\<^sub>\<rat> 128\<rceil>\<close> --- and then Barrett-divide by \<^term>\<open>(2 * \<gamma>\<^sub>2) div 128\<close>:\<close>

corollary barrett_decompose_32_c_avx2:
  assumes \<open>a \<ge> 0\<close> and \<open>a < MLDSA_Q\<close>
  shows \<open>\<lfloor>a /\<^sub>\<rat> (2 * MLDSA_GAMMA2_32)\<rceil>\<^sub>\<down> = \<lfloor>\<lceil>a /\<^sub>\<rat> 128\<rceil> * 1025 /\<^sub>\<rat> 2^22\<rceil>\<close>
proof -
  have g: \<open>(2 * MLDSA_GAMMA2_32 :: int) = 523776\<close> by (simp add: MLDSA_GAMMA2_32_def MLDSA_Q_def)
  have aQ: \<open>a < 8380417\<close> using assms(2) unfolding MLDSA_Q_def by simp
  define cl where \<open>cl = \<lceil>a /\<^sub>\<rat> 128\<rceil>\<close>
  have cl_nn: \<open>0 \<le> cl\<close> unfolding cl_def using assms(1) by (simp add: zero_le_divide_iff)
  have cl_lt: \<open>cl < 65473\<close>
  proof -
    have ce: \<open>cl = - ((- a) div 128)\<close> unfolding cl_def by (metis ceiling_divide_eq_div of_int_numeral)
    have \<open>- 8380416 \<le> - a\<close> using aQ by simp
    hence \<open>(- 8380416) div 128 \<le> (- a) div 128\<close> by (rule zdiv_mono1) simp
    thus ?thesis using ce by simp
  qed
  have step1: \<open>\<lfloor>a /\<^sub>\<rat> 523776\<rceil>\<^sub>\<down> = \<lfloor>cl /\<^sub>\<rat> 4092\<rceil>\<^sub>\<down>\<close>
    using factor_128[of a 4092] assms(1) unfolding cl_def by simp
  have cc: \<open>(4 :: int) = (2^22 :: int) - 4092 * \<lfloor>(2^22 :: int) /\<^sub>\<rat> 4092\<rfloor>\<close> by eval
  have m: \<open>(1025 :: int) = \<lfloor>(2^22 :: int) /\<^sub>\<rat> 4092\<rfloor>\<close> by eval
  have step2: \<open>\<lfloor>cl * \<lfloor>(2^22 :: int) /\<^sub>\<rat> 4092\<rfloor> /\<^sub>\<rat> 2^22\<rceil> = \<lfloor>cl /\<^sub>\<rat> 4092\<rceil>\<^sub>\<down>\<close>
    apply (rule barrettE_division_exact[where N=4092 and n=22 and c=4])
    using cl_nn cl_lt cc by simp_all
  show ?thesis unfolding g using step1 step2 m unfolding cl_def by simp
qed

corollary barrett_decompose_88_c_avx2:
  assumes \<open>a \<ge> 0\<close> and \<open>a < MLDSA_Q\<close>
  shows \<open>\<lfloor>a /\<^sub>\<rat> (2 * MLDSA_GAMMA2_88)\<rceil>\<^sub>\<down> = \<lfloor>\<lceil>a /\<^sub>\<rat> 128\<rceil> * 11275 /\<^sub>\<rat> 2^24\<rceil>\<close>
proof -
  have g: \<open>(2 * MLDSA_GAMMA2_88 :: int) = 190464\<close> by (simp add: MLDSA_GAMMA2_88_def MLDSA_Q_def)
  have aQ: \<open>a < 8380417\<close> using assms(2) unfolding MLDSA_Q_def by simp
  define cl where \<open>cl = \<lceil>a /\<^sub>\<rat> 128\<rceil>\<close>
  have cl_nn: \<open>0 \<le> cl\<close> unfolding cl_def using assms(1) by (simp add: zero_le_divide_iff)
  have cl_lt: \<open>cl < 65473\<close>
  proof -
    have ce: \<open>cl = - ((- a) div 128)\<close> unfolding cl_def by (metis ceiling_divide_eq_div of_int_numeral)
    have \<open>- 8380416 \<le> - a\<close> using aQ by simp
    hence \<open>(- 8380416) div 128 \<le> (- a) div 128\<close> by (rule zdiv_mono1) simp
    thus ?thesis using ce by simp
  qed
  have step1: \<open>\<lfloor>a /\<^sub>\<rat> 190464\<rceil>\<^sub>\<down> = \<lfloor>cl /\<^sub>\<rat> 1488\<rceil>\<^sub>\<down>\<close>
    using factor_128[of a 1488] assms(1) unfolding cl_def by simp
  have cc: \<open>(16 :: int) = (2^24 :: int) - 1488 * \<lfloor>(2^24 :: int) /\<^sub>\<rat> 1488\<rfloor>\<close> by eval
  have m: \<open>(11275 :: int) = \<lfloor>(2^24 :: int) /\<^sub>\<rat> 1488\<rfloor>\<close> by eval
  have step2: \<open>\<lfloor>cl * \<lfloor>(2^24 :: int) /\<^sub>\<rat> 1488\<rfloor> /\<^sub>\<rat> 2^24\<rceil> = \<lfloor>cl /\<^sub>\<rat> 1488\<rceil>\<^sub>\<down>\<close>
    apply (rule barrettE_division_exact[where N=1488 and n=24 and c=16])
    using cl_nn cl_lt cc by simp_all
  show ?thesis unfolding g using step1 step2 m unfolding cl_def by simp
qed

end
