(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Barrett_Montgomery
  imports Barrett_Reduction Montgomery_Reduction
begin

chapter \<open>Barrett \<^latex>\<open>$\leftrightarrow$\<close> Montgomery bridge \label{ch:barrett_montgomery}\<close>

text \<open>This chapter establishes the equivalence of Barrett and Montgomery reduction
and multiplication on a suitably twisted input, and derives the corresponding
output absolute bounds for Barrett from the Montgomery ones.\<close>

text \<open>Throughout the chapter, we fix an integer approximation \<open>f=\<lbrakk>_\<rbrakk>\<close>, an odd modulus \<^term>\<open>N\<close>, 
and an exponent \<^term>\<open>n\<close> with \<^term>\<open>2^n > N\<close>. We abbreviate \<^term>\<open>R = 2^n\<close>. This will be indicated
in by the \<^verbatim>\<open>(in BarrettContext)\<close> below.\<close>

section \<open>Bridge: Barrett reduction and multiplication as Montgomery\<close>

text %internal \<open>Parametric bridge core, covering signed/unsigned via the rounding mode \<^term>\<open>g\<close>
and reduction/multiplication via \<^term>\<open>c = R\<close> resp. \<^term>\<open>c = b*R\<close>. Reads as: under
\<^term>\<open>q*R = x*c\<close> and \<^term>\<open>R dvd c\<close>, the Barrett-style expression \<^term>\<open>q - N*g(x\<^sub>\<rat>*magic\<^sub>\<rat>/R\<^sub>\<rat>)\<close>
equals the additive Montgomery body on \<^term>\<open>x*r\<close>, where \<^term>\<open>r = c - N*magic\<close>.\<close>
lemma %internal (in BarrettContext) bridge_core:
  fixes magic c x q Tneg :: int and g :: \<open>rat \<Rightarrow> int\<close>
  assumes Tneg_inv: \<open>(N * Tneg) mod R = (- 1) mod R\<close>
      and c_mod: \<open>c mod R = 0\<close>
      and q_eq: \<open>q * R = x * c\<close>
      and shift: \<open>shift_compat g\<close>
  defines \<open>r \<equiv> c - N * magic\<close>
  shows \<open>q - N * g (x * magic /\<^sub>\<rat> R)
         = (x * r + (x * r * Tneg) mod\<lbrakk>g\<rbrakk> R * N) div R\<close>
proof -
  \<comment> \<open>Algebraic key: \<open>magic \<equiv> r\<cdot>Tneg (mod R)\<close>, hence \<open>x\<cdot>magic \<equiv> x\<cdot>r\<cdot>Tneg (mod R)\<close>.\<close>
  have key0: \<open>(N * (magic - r * Tneg)) mod R = 0\<close>
  proof -
    have \<open>N * (magic - r * Tneg) = N * magic - r * (N * Tneg)\<close>
      by (simp add: algebra_simps)
    hence \<open>(N * (magic - r * Tneg)) mod R
           = (N * magic - r * ((N * Tneg) mod R)) mod R\<close>
      by (metis mod_diff_right_eq mod_mult_right_eq)
    also have \<open>\<dots> = (N * magic - r * ((-1) mod R)) mod R\<close>
      using Tneg_inv by simp
    also have \<open>\<dots> = (N * magic - r * (-1)) mod R\<close>
      by (metis mod_diff_right_eq mod_mult_right_eq)
    also have \<open>N * magic - r * (-1) = c\<close> using r_def by simp
    finally show ?thesis using c_mod by simp
  qed
  have coprime_NR: \<open>coprime N R\<close>
    using Nodd by (simp add: coprime_power_right_iff)
  have \<open>R dvd (magic - r * Tneg)\<close>
    using key0 coprime_NR
    by (simp add: mod_eq_0_iff_dvd coprime_dvd_mult_right_iff coprime_commute)
  hence magic_cong: \<open>magic mod R = (r * Tneg) mod R\<close>
    by (simp add: mod_eq_dvd_iff)
  have xmagic_cong: \<open>(x * magic) mod R = (x * r * Tneg) mod R\<close>
    using magic_cong
    by (metis (mono_tags, opaque_lifting) mod_mult_right_eq mult.assoc)
  \<comment> \<open>Apply \<open>shift_compat g\<close> to lift the congruence into \<open>mod\<lbrakk>g\<rbrakk>\<close>.\<close>
  have shift_eq: \<open>(x * magic) mod\<lbrakk>g\<rbrakk> R = (x * r * Tneg) mod\<lbrakk>g\<rbrakk> R\<close>
  proof -
    from xmagic_cong have \<open>R dvd ((x * magic) - (x * r * Tneg))\<close>
      by (simp add: mod_eq_dvd_iff)
    then obtain k where k: \<open>(x * magic) - (x * r * Tneg) = R * k\<close>
      unfolding dvd_def by auto
    hence \<open>x * magic = (x * r * Tneg) + R * k\<close> by simp
    thus ?thesis
      using mod_approx_shift[OF shift R_pos, of \<open>x * r * Tneg\<close> k] by simp
  qed
  \<comment> \<open>Multiply the LHS by \<open>R\<close> and combine.\<close>
  let ?z = \<open>x * magic\<close>
  have arg_eq: \<open>g (x\<^sub>\<rat> * magic\<^sub>\<rat> / R\<^sub>\<rat>) = g (?z\<^sub>\<rat> / R\<^sub>\<rat>)\<close>
    by (simp add: of_int_mult)
  have z_split: \<open>R * g (?z\<^sub>\<rat> / R\<^sub>\<rat>) = ?z - ?z mod\<lbrakk>g\<rbrakk> R\<close>
    unfolding mod_approx_def by simp
  have lhs_R: \<open>(q - N * g (x\<^sub>\<rat> * magic\<^sub>\<rat> / R\<^sub>\<rat>)) * R
               = x * r + N * (?z mod\<lbrakk>g\<rbrakk> R)\<close>
  proof -
    have \<open>(q - N * g (?z\<^sub>\<rat> / R\<^sub>\<rat>)) * R = q * R - N * (R * g (?z\<^sub>\<rat> / R\<^sub>\<rat>))\<close>
      by (simp add: algebra_simps)
    also have \<open>\<dots> = q * R - N * (?z - ?z mod\<lbrakk>g\<rbrakk> R)\<close> using z_split by simp
    also have \<open>\<dots> = x * c - N * ?z + N * (?z mod\<lbrakk>g\<rbrakk> R)\<close>
      using q_eq by (simp add: algebra_simps)
    also have \<open>\<dots> = x * (c - N * magic) + N * (?z mod\<lbrakk>g\<rbrakk> R)\<close>
      by (simp add: algebra_simps)
    also have \<open>\<dots> = x * r + N * (?z mod\<lbrakk>g\<rbrakk> R)\<close> using r_def by simp
    finally show ?thesis using arg_eq by simp
  qed
  have \<open>(q - N * g (x\<^sub>\<rat> * magic\<^sub>\<rat> / R\<^sub>\<rat>)) * R
        = x * r + N * ((x * r * Tneg) mod\<lbrakk>g\<rbrakk> R)\<close>
    using lhs_R shift_eq by simp
  hence \<open>q - N * g (x\<^sub>\<rat> * magic\<^sub>\<rat> / R\<^sub>\<rat>)
         = (x * r + N * ((x * r * Tneg) mod\<lbrakk>g\<rbrakk> R)) div R\<close>
    using R_pos by (metis nonzero_mult_div_cancel_right not_less_iff_gr_or_eq)
  thus ?thesis by (simp add: mult.commute)
qed

text \<open>Barrett reduction returns a new representative of \<^term>\<open>z mod N\<close>, while Montgomery
reduction returns a representative of \<^term>\<open>z*R\<^sup>-\<^sup>1 mod N\<close>. They cannot literally be equal:
Any equivalence must absorb a factor of \<^term>\<open>R\<close> somewhere. The equivalence identities
use a \<^term>\<open>R mod\<lbrakk>f\<rbrakk> N\<close>-twist on the Montgomery input. The most direct proof is
obtained by carefully unravelling the definitions;
\autoref{ch:bridge_conceptual} offers a conceptual explanation.\<close>

text %internal \<open>The bridge identities follow by instantiating the parametric core
with \<^term>\<open>g = round\<close> or \<^term>\<open>floor\<close>, and \<open>c = R, x = z, q = z\<close> (reduction) or
\<^term>\<open>c = b*R\<close>, \<^term>\<open>x = a\<close>, \<^term>\<open>q = a*b\<close> (multiplication).\<close>

theorem (in BarrettContext) barrett_montgomery_bridge:
  shows \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N))\<close>
    and \<open>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N))\<close>
    and \<open>barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close>
    and \<open>barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close>
proof -
  have bR_mod: \<open>(b * R) mod R = 0\<close> for b :: int by simp
  have q_mul: \<open>(a * b) * R = a * (b * R)\<close> for a b :: int by (simp add: algebra_simps)
  have arg_eq: \<open>(b * R) /\<^sub>\<rat> N = b\<^sub>\<rat> * R\<^sub>\<rat> / N\<^sub>\<rat>\<close> for b :: int by (simp add: of_int_mult)
  have MS: \<open>barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close> for a b :: int
    using bridge_core[OF mod_inverse_neg_correct bR_mod[of b] q_mul[of a b] shift_compat_round, of \<open>f (b\<^sub>\<rat> * R\<^sub>\<rat> / N\<^sub>\<rat>)\<close>]
          mont_add_signed_unfold[OF mod_inverse_neg_correct, of \<open>a * ((b * R) mod\<lbrakk>f\<rbrakk> N)\<close>]
          arg_eq[of b]
    by (simp add: barrett_mul_signed_def Let_def mod_approx_def algebra_simps)
  have MU: \<open>barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close> for a b :: int
    using bridge_core[OF mod_inverse_neg_correct bR_mod[of b] q_mul[of a b] shift_compat_floor, of \<open>f (b\<^sub>\<rat> * R\<^sub>\<rat> / N\<^sub>\<rat>)\<close>]
          mont_add_unsigned_unfold[OF mod_inverse_neg_correct, of \<open>a * ((b * R) mod\<lbrakk>f\<rbrakk> N)\<close>]
          arg_eq[of b]
    by (simp add: barrett_mul_unsigned_def Let_def mod_approx_def algebra_simps)
  show \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N))\<close>
    using MS[of z 1] barrett_red_as_mul(1) by simp
  show \<open>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (z * (R mod\<lbrakk>f\<rbrakk> N))\<close>
    using MU[of z 1] barrett_red_as_mul(2) by simp
  show \<open>barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close>
    by (rule MS)
  show \<open>barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle> = mont\<^sub>a\<^sub>d\<^sub>d\<^sup>+\<lbrakk>N, n\<rbrakk> (a * ((b * R) mod\<lbrakk>f\<rbrakk> N))\<close>
    by (rule MU)
qed

lemmas %internal (in BarrettContext) barrett_montgomery_bridge_red_signed   = barrett_montgomery_bridge(1)
lemmas %internal (in BarrettContext) barrett_montgomery_bridge_red_unsigned = barrett_montgomery_bridge(2)
lemmas %internal (in BarrettContext) barrett_montgomery_bridge_mul_signed   = barrett_montgomery_bridge(3)
lemmas %internal (in BarrettContext) barrett_montgomery_bridge_mul_unsigned = barrett_montgomery_bridge(4)

section \<open>Bounds for Barrett reduction and multiplication\<close>

text \<open>We now derive absolute bounds for Barrett reduction and multiplication
by combining the bridge lemmas above with the absolute bounds for additive
Montgomery reduction and multiplication.

It should be noted that the signed Barrett reductions/multiplications satisfy a tighter output
bound than the unsigned variants, as for signed vs.\ unsigned Montgomery reduction.\<close>

theorem (in BarrettContext) barrett_montgomery_bounds:
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> * \<bar>R mod\<lbrakk>f\<rbrakk> N\<bar> /\<^sub>\<rat> R + N /\<^sub>\<rat> 2\<close>
  and \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar> * \<bar>R mod\<lbrakk>f\<rbrakk> N\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
  and \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar> /\<^sub>\<rat> R + N /\<^sub>\<rat> 2\<close>
  and \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar> /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
proof -
  have MS: \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> (\<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N /\<^sub>\<rat> 2\<close> for a b
    using mont_add_signed_bound[of \<open>a * ((b * R) mod\<lbrakk>f\<rbrakk> N)\<close>]
    unfolding barrett_montgomery_bridge_mul_signed by (simp add: abs_mult of_int_mult)
  have MU: \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> (\<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close> for a b
    using mont_add_unsigned_bound[of \<open>a * ((b * R) mod\<lbrakk>f\<rbrakk> N)\<close>]
    unfolding barrett_montgomery_bridge_mul_unsigned by (simp add: abs_mult of_int_mult)
  show \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> (\<bar>z\<bar> * \<bar>R mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N /\<^sub>\<rat> 2\<close> for z
    using MS[of z 1] barrett_red_as_mul(1) by simp
  show \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> (\<bar>z\<bar> * \<bar>R mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close> for z
    using MU[of z 1] barrett_red_as_mul(2) by simp
  show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> (\<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N /\<^sub>\<rat> 2\<close> for a b
    by (rule MS)
  show \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> (\<bar>a\<bar> * \<bar>(b * R) mod\<lbrakk>f\<rbrakk> N\<bar>) /\<^sub>\<rat> R + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close> for a b
    by (rule MU)
qed

lemmas %internal (in BarrettContext) barrett_red_signed_bound      = barrett_montgomery_bounds(1)
lemmas %internal (in BarrettContext) barrett_red_unsigned_bound    = barrett_montgomery_bounds(2)
lemmas %internal (in BarrettContext) barrett_mul_signed_bound = barrett_montgomery_bounds(3)
lemmas %internal (in BarrettContext) barrett_mul_unsigned_bound    = barrett_montgomery_bounds(4)

text \<open>The bounds above are stated in terms of \<^term>\<open>\<bar>2^n mod\<lbrakk>f\<rbrakk> N\<bar>\<close>, the magnitude
of the residue of \<^term>\<open>2^n\<close> under \<open>\<lbrakk>_\<rbrakk>\<close>-rounding. This residue equals \<^term>\<open>N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)\<close>
for reduction and \<^term>\<open>N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)\<close> for multiplication, hence giving the
following  pointwise bounds:\<close>

theorem (in BarrettContext) barrett_montgomery_bounds_eps:
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
  and \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
  and \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
  and \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
proof -
  have lift: \<open>\<bar>c mod\<lbrakk>f\<rbrakk> N\<bar>\<^sub>\<rat> = N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N)\<close> for c :: int
    using mod_approx_bound_eps_at[OF Npos, of f c] by simp
  show \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close> for z
    using barrett_montgomery_bounds(1)[of z] lift[of R] by (simp add: of_int_mult abs_mult)
  show \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close> for z
    using barrett_montgomery_bounds(2)[of z] lift[of R] by (simp add: of_int_mult abs_mult)
  show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close> for a b
    using barrett_montgomery_bounds(3)[of a b] lift[of \<open>b * R\<close>] by (simp add: of_int_mult abs_mult)
  show \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close> for a b
    using barrett_montgomery_bounds(4)[of a b] lift[of \<open>b * R\<close>] by (simp add: of_int_mult abs_mult)
qed

text %internal \<open>Specialising the pointwise errors to the uniform quality \<^term>\<open>\<epsilon>(f)\<close> provides a uniform
bound:\<close>

corollary %internal (in BarrettContext) barrett_montgomery_bounds_eps_uniform:
  assumes \<open>is_int_approx_quality f e\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
  and \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
  and \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
  and \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
proof -
  have slope: \<open>\<bar>w\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, x)) / R\<^sub>\<rat> \<le> \<bar>w\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat>\<close> for w x
    using quality_at_le[OF assms] Npos by (simp add: divide_right_mono mult_left_mono)
  show \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
    using barrett_montgomery_bounds_eps(1)[of z] slope[of z \<open>R /\<^sub>\<rat> N\<close>] by linarith
  show \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
    using barrett_montgomery_bounds_eps(2)[of z] slope[of z \<open>R /\<^sub>\<rat> N\<close>] by linarith
  show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
    using barrett_montgomery_bounds_eps(3)[of a b] slope[of a \<open>b * R /\<^sub>\<rat> N\<close>] by linarith
  show \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
    using barrett_montgomery_bounds_eps(4)[of a b] slope[of a \<open>b * R /\<^sub>\<rat> N\<close>] by linarith
qed

lemmas %internal (in BarrettContext) barrett_red_signed_bound_eps      = barrett_montgomery_bounds_eps_uniform(1)
lemmas %internal (in BarrettContext) barrett_red_unsigned_bound_eps    = barrett_montgomery_bounds_eps_uniform(2)
lemmas %internal (in BarrettContext) barrett_mul_signed_bound_eps = barrett_montgomery_bounds_eps_uniform(3)
lemmas %internal (in BarrettContext) barrett_mul_unsigned_bound_eps    = barrett_montgomery_bounds_eps_uniform(4)

text \<open>When the input magnitude is at most \<open>2^(n-1) = R /\<^sub>\<rat> 2\<close>, the slope term is at
most half of \<^term>\<open>N\<^sub>\<rat> * \<epsilon>(f, x)\<close>, yielding the following narrowed bounds:\<close>

theorem (in BarrettContext) barrett_bound_eps_narrow:
  shows \<open>\<bar>z\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 1)/2\<close>
    and \<open>\<bar>z\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 2)/2 - N/\<^sub>\<rat>R\<close>
    and \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b*R)/\<^sub>\<rat> N) + 1)/2\<close>
    and \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b*R)/\<^sub>\<rat> N) + 2)/2 - N/\<^sub>\<rat>R\<close>
proof -
  have half: \<open>\<And>w :: int. \<bar>w\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>w\<bar>\<^sub>\<rat> / R\<^sub>\<rat> \<le> 1/2\<close>
  proof -
    fix w :: int assume A: \<open>\<bar>w\<bar> \<le> 2^(n-1)\<close>
    have \<open>\<bar>w\<bar>\<^sub>\<rat> \<le> ((2^(n-1) :: int))\<^sub>\<rat>\<close>
      using A of_int_le_iff by fastforce
    hence \<open>\<bar>w\<bar>\<^sub>\<rat> / R\<^sub>\<rat> \<le> ((2^(n-1) :: int)\<^sub>\<rat>) / R\<^sub>\<rat>\<close>
      by (simp add: divide_right_mono)
    also have \<open>((2^(n-1) :: int)\<^sub>\<rat>) / R\<^sub>\<rat> = 1/2\<close>
      using R_eq by (simp add: of_int_power)
    finally show \<open>\<bar>w\<bar>\<^sub>\<rat> / R\<^sub>\<rat> \<le> 1/2\<close> .
  qed
  have slope1: \<open>\<And>w c :: int. \<bar>w\<bar> \<le> 2^(n-1) \<Longrightarrow>
                  \<bar>w\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N)) / R\<^sub>\<rat> \<le> N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N) / 2\<close>
  proof -
    fix w c :: int assume A: \<open>\<bar>w\<bar> \<le> 2^(n-1)\<close>
    have nn: \<open>0 \<le> N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N)\<close> using Npos by simp
    have \<open>\<bar>w\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N)) / R\<^sub>\<rat> = (\<bar>w\<bar>\<^sub>\<rat> / R\<^sub>\<rat>) * (N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N))\<close>
      by (simp add: field_simps)
    also have \<open>\<dots> \<le> (1/2) * (N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N))\<close>
      using half[OF A] nn by (rule mult_right_mono)
    finally show \<open>\<bar>w\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N)) / R\<^sub>\<rat> \<le> N\<^sub>\<rat> * \<epsilon>(f, c /\<^sub>\<rat> N) / 2\<close> by simp
  qed
  have MS: \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 1) / 2\<close> for a b
  proof -
    assume A: \<open>\<bar>a\<bar> \<le> 2^(n-1)\<close>
    have \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
      using barrett_montgomery_bounds_eps(3)[of a b] .
    also have \<open>\<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> \<le> N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N) / 2\<close>
      using slope1[OF A, of \<open>b * R\<close>] .
    finally show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 1) / 2\<close>
      by (simp add: distrib_left)
  qed
  have MU: \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 2) / 2 - N /\<^sub>\<rat> R\<close> for a b
  proof -
    assume A: \<open>\<bar>a\<bar> \<le> 2^(n-1)\<close>
    have \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> \<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
      using barrett_montgomery_bounds_eps(4)[of a b] .
    also have \<open>\<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N)) / R\<^sub>\<rat> \<le> N\<^sub>\<rat> * \<epsilon>(f, (b * R) /\<^sub>\<rat> N) / 2\<close>
      using slope1[OF A, of \<open>b * R\<close>] .
    finally show \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 2) / 2 - N /\<^sub>\<rat> R\<close>
      by (simp add: add_divide_distrib distrib_left)
  qed
  show \<open>\<bar>z\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 1) / 2\<close> for z
    using MS[of z 1] barrett_red_as_mul(1) by simp
  show \<open>\<bar>z\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 2) / 2 - N /\<^sub>\<rat> R\<close> for z
    using MU[of z 1] barrett_red_as_mul(2) by simp
  show \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 1) / 2\<close> for a b
    by (rule MS)
  show \<open>\<bar>a\<bar> \<le> 2^(n-1) \<Longrightarrow> \<bar>(barM\<^sup>+ \<lbrakk>N, n, f\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(f, (b * R) /\<^sub>\<rat> N) + 2) / 2 - N /\<^sub>\<rat> R\<close> for a b
    by (rule MU)
qed


text\<open>In \autoref{ch:barrett_bound_quality} we will demonstrate by example that the right hand sides @{thm [show_question_marks=false] (rhs) BarrettContext.barrett_bound_eps_narrow(1)} etc. of
@{thm [source] BarrettContext.barrett_bound_eps_narrow} are \<^emph>\<open>tight\<close>.\<close>

text \<open>The pointwise version of @{thm [source] BarrettContext.barrett_bound_eps_narrow}
above lets us specialise to the three cases of practical interest --- signed
Barrett multiplication with round-to-nearest-even and with round-to-nearest, and
unsigned Barrett multiplication with round-to-nearest. When the second
operand \<^term>\<open>b\<close> satisfies \<^term>\<open>b \<noteq> 0\<close> and \<^term>\<open>\<bar>b\<bar> < N\<close>, then \<^term>\<open>b\<close> is not
divisible by \<^term>\<open>N\<close>, and since \<^term>\<open>N\<close> is odd, neither is \<^term>\<open>b * R\<close> nor
\<^term>\<open>2 * b * R\<close>. So the pointwise rounding error at \<^term>\<open>(b * R) /\<^sub>\<rat> N\<close> is
strictly below the uniform quality, yielding strict output bounds.\<close>

theorem (in StandardModulus) barrett_mul_narrow:
  assumes \<open>\<bar>a\<bar> \<le> 2^(n-1)\<close>
      and \<open>\<bar>b\<bar> < N\<close> and \<open>b \<noteq> 0\<close>
  shows \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> < N\<^sub>\<rat>\<close>
    and \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar>  < 3 * N /\<^sub>\<rat> 4\<close>
    and \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar>  < 5 * N /\<^sub>\<rat> 4\<close>
proof -
  \<comment> \<open>\<^term>\<open>b\<close> is nonzero with absolute value below \<^term>\<open>N\<close>, so it lies
       strictly between two consecutive multiples of \<^term>\<open>N\<close> and is therefore
       not divisible by \<^term>\<open>N\<close>.\<close>
  have N_not_dvd_b: \<open>\<not> N dvd b\<close>
  proof
    assume \<open>N dvd b\<close>
    then obtain k :: int where bk: \<open>b = N * k\<close> by auto
    from bk assms(3) have \<open>k \<noteq> 0\<close> by auto
    hence \<open>\<bar>k\<bar> \<ge> 1\<close> by simp
    hence \<open>\<bar>b\<bar> \<ge> N\<close> using bk Npos by (simp add: abs_mult)
    thus False using assms(2) by simp
  qed
  \<comment> \<open>\<^term>\<open>N\<close> is odd and \<open>> 1\<close>, so it does not divide \<^term>\<open>R = 2^n\<close>;
       and being coprime to both \<^term>\<open>R\<close> and \<^term>\<open>2\<close>, it does not divide
       \<^term>\<open>b * R\<close> or \<^term>\<open>2 * b * R\<close>.\<close>
  have N_not_dvd_R: \<open>\<not> N dvd R\<close>
  proof
    assume A: \<open>N dvd R\<close>
    from A prime_int_iff[of 2] obtain i where \<open>\<bar>N\<bar> = (2::int)^i\<close>
      using divides_primepow[of \<open>2::int\<close> N n] by auto
    hence \<open>N = (2::int)^i\<close> using Npos by simp
    hence \<open>even N \<or> N = 1\<close> by (cases i) auto
    thus False using Nodd Ngt1 by auto
  qed
  have N_not_dvd_bR: \<open>\<not> N dvd b * R\<close>
    using N_not_dvd_b N_not_dvd_R Nodd
    by (metis coprime_commute coprime_left_2_iff_odd
              coprime_dvd_mult_left_iff coprime_power_right_iff)
  have N_not_dvd_2bR: \<open>\<not> N dvd 2 * b * R\<close>
    using N_not_dvd_bR Nodd
    by (metis coprime_dvd_mult_right_iff coprime_commute coprime_left_2_iff_odd
              mult.assoc)
  define x where \<open>x = (b * R) /\<^sub>\<rat> N\<close>
  \<comment> \<open>So neither \<^term>\<open>(b * R) /\<^sub>\<rat> N\<close> nor \<^term>\<open>2 * (b * R) /\<^sub>\<rat> N\<close> is an integer.\<close>
  have twoX_notint: \<open>2 * x \<notin> \<int>\<close>
  proof
    assume \<open>2 * x \<in> \<int>\<close>
    then obtain m :: int where m: \<open>2 * x = m\<^sub>\<rat>\<close> using Ints_cases by blast
    have \<open>(2 * b * R)\<^sub>\<rat> = (m * N)\<^sub>\<rat>\<close>
      using m Npos unfolding x_def by (simp add: field_simps)
    hence \<open>2 * b * R = m * N\<close> by (metis of_int_eq_iff of_int_mult)
    thus False using N_not_dvd_2bR by (metis dvd_triv_right)
  qed
  have x_notint: \<open>x \<notin> \<int>\<close>
  proof
    assume \<open>x \<in> \<int>\<close>
    then obtain k :: int where k: \<open>x = k\<^sub>\<rat>\<close> using Ints_cases by blast
    have \<open>(b * R)\<^sub>\<rat> = (N * k)\<^sub>\<rat>\<close>
      using k Npos unfolding x_def by (simp add: field_simps)
    hence \<open>b * R = N * k\<close> by (metis of_int_eq_iff)
    thus False using N_not_dvd_bR by simp
  qed
  \<comment> \<open>So the pointwise rounding errors at \<^term>\<open>x\<close> are strictly below the
       uniform qualities, by \<open>quality_at_strict_round\<close> and
       \<open>quality_at_strict_round_even\<close>.\<close>
  have eps_round_strict: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, x) < 1/2\<close>
    using quality_at_strict_round[OF twoX_notint] quality_round by simp
  have eps_round_even_strict: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) < 1\<close>
    using quality_at_strict_round_even[OF x_notint] quality_round_even by simp
  \<comment> \<open>Specialise the Barrett locale at the two concrete approximations.\<close>
  interpret R_even: BarrettContext N n \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>
    by unfold_locales (rule is_int_approx_round_even)
  interpret R_round: BarrettContext N n \<open>\<lfloor>\<cdot>\<rceil>\<close>
    by unfold_locales (rule is_int_approx_round)
  \<comment> \<open>Lift a strict pointwise quality to a strict output bound.\<close>
  have step: \<open>\<bar>v\<bar> < N\<^sub>\<rat> * (e' + c) / 2\<close>
    if h1: \<open>\<bar>v\<bar> \<le> N\<^sub>\<rat> * (e + c) / 2\<close> and h2: \<open>e < e'\<close> for v e e' c
  proof -
    have \<open>N\<^sub>\<rat> * (e + c) < N\<^sub>\<rat> * (e' + c)\<close>
      using h2 N_pos_rat by (simp add: mult_strict_left_mono)
    thus ?thesis using h1 by linarith
  qed
  have B1: \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) + 1) / 2\<close>
    using R_even.barrett_bound_eps_narrow(3)[OF assms(1)] unfolding x_def by simp
  have B2: \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(\<lfloor>\<cdot>\<rceil>, x) + 1) / 2\<close>
    using R_round.barrett_bound_eps_narrow(3)[OF assms(1)] unfolding x_def by simp
  have B3: \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(\<lfloor>\<cdot>\<rceil>, x) + 2) / 2\<close>
  proof -
    have \<open>0 \<le> N /\<^sub>\<rat> R\<close> using Npos R_pos by simp
    moreover have \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * (\<epsilon>(\<lfloor>\<cdot>\<rceil>, x) + 2) / 2 - N /\<^sub>\<rat> R\<close>
      using R_round.barrett_bound_eps_narrow(4)[OF assms(1)] unfolding x_def by simp
    ultimately show ?thesis by linarith
  qed
  show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> < N\<^sub>\<rat>\<close>
    using step[OF B1 eps_round_even_strict] by simp
  show \<open>\<bar>(barM\<^sup>\<plusminus> \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> < (3 * N) /\<^sub>\<rat> 4\<close>
    using step[OF B2 eps_round_strict] by simp
  show \<open>\<bar>(barM\<^sup>+ \<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk>\<langle>a, b\<rangle>)\<^sub>\<rat>\<bar> < (5 * N) /\<^sub>\<rat> 4\<close>
    using step[OF B3 eps_round_strict] by simp
qed

text \<open>Specializing at \<^term>\<open>b=1\<close>, we obtain the same bounds for Barrett reduction:\<close>

theorem (in StandardModulus) barrett_red_narrow:
  assumes \<open>\<bar>z\<bar> \<le> 2^(n-1)\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<^sub>2\<rbrakk> z)\<^sub>\<rat>\<bar> < N\<^sub>\<rat>\<close>
    and \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk> z)\<^sub>\<rat>\<bar> < 3 * N /\<^sub>\<rat> 4\<close>
    and \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, \<lfloor>\<cdot>\<rceil>\<rbrakk> z)\<^sub>\<rat>\<bar> < 5 * N /\<^sub>\<rat> 4\<close>
  using barrett_mul_narrow[OF assms, of 1] Ngt1 barrett_red_as_mul
  by simp_all

section \<open>Bounds for refined Barrett reduction\<close>

text \<open>We have seen that the output quality of Barrett reduction improves
as \<^term>\<open>n\<close> grows. For refined Barrett
reduction, the goal is to choose \<^term>\<open>n\<close> large enough that the output
is in fact \<^emph>\<open>signed canonical\<close>. For practical purposes growing
\<^term>\<open>n\<close> alone is not sufficient: one also needs to
take into account the quality of the approximation \<open>\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<close>.\<close>

lemma (in BarrettContext) barrett_montgomery_bounds_quality_pow:
  assumes \<open>\<epsilon>(f, R /\<^sub>\<rat> N) \<le> 1/2^\<delta>\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) + N\<^sub>\<rat> / 2\<close>
    and \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
proof -
  have z_nn: \<open>\<bar>z\<bar>\<^sub>\<rat> \<ge> 0\<close> by simp
  have N_nn: \<open>N\<^sub>\<rat> \<ge> 0\<close> by simp
  have R_pos: \<open>R\<^sub>\<rat> > 0\<close> by simp
  have step: \<open>\<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>)\<close>
  proof -
    have zN_nn: \<open>\<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> \<ge> 0\<close> using z_nn N_nn by simp
    have \<open>\<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N) \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> * (1/2^\<delta>)\<close>
      using mult_left_mono[OF assms zN_nn] .
    hence \<open>\<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / 2^\<delta>\<close>
      by (simp add: algebra_simps)
    thus ?thesis using R_pos by (simp add: divide_right_mono field_simps)
  qed
  show \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) + N\<^sub>\<rat> / 2\<close>
    using barrett_montgomery_bounds_eps(1)[of z] step by linarith
  show \<open>\<bar>(bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
    using barrett_montgomery_bounds_eps(2)[of z] step by linarith
qed

text \<open>If we additionally specialise the input \<^term>\<open>z\<close> to be bounded by
\<^term>\<open>2^(n-1-\<gamma>)\<close> --- that is, we assume \<^term>\<open>\<gamma>\<close> bits of slack for
\<^term>\<open>\<gamma> \<ge> 0\<close> --- we obtain the following bound:\<close>

lemma (in BarrettContext) barrett_red_signed_bound_slack:
  assumes \<open>\<epsilon>(f, R /\<^sub>\<rat> N) \<le> 1/2^\<delta>\<close>
      and \<open>\<bar>z\<bar> \<le> 2^(n-1-\<gamma>)\<close>
      and \<open>\<gamma> \<le> n-1\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1) + N\<^sub>\<rat> / 2\<close>
proof -
  have R_pos: \<open>R\<^sub>\<rat> > 0\<close> by simp
  have N_nn: \<open>N\<^sub>\<rat> \<ge> 0\<close> by simp
  have step1: \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> \<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) + N\<^sub>\<rat> / 2\<close>
    using barrett_montgomery_bounds_quality_pow(1)[OF assms(1)] .
  have z_rat: \<open>\<bar>z\<bar>\<^sub>\<rat> \<le> (2::rat)^(n-1-\<gamma>)\<close>
    using assms(2) by (metis of_int_abs of_int_le_iff of_int_numeral of_int_power)
  have \<open>\<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> \<le> (2::rat)^(n-1-\<gamma>) * N\<^sub>\<rat>\<close>
    using mult_right_mono[OF z_rat N_nn] .
  hence slope_le: \<open>\<bar>z\<bar>\<^sub>\<rat> * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) \<le> (2::rat)^(n-1-\<gamma>) * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>)\<close>
    using R_pos by (simp add: divide_right_mono)
  have R_eq: \<open>R\<^sub>\<rat> = (2::rat)^n\<close> by simp
  have n_eq: \<open>n = (n-1-\<gamma>) + (\<gamma>+1)\<close> using assms(3) npos by simp
  have R_split: \<open>(2::rat)^n = 2^(n-1-\<gamma>) * 2^(\<gamma>+1)\<close>
    using n_eq by (metis power_add)
  have slope_simp: \<open>(2::rat)^(n-1-\<gamma>) * N\<^sub>\<rat> / (R\<^sub>\<rat> * 2^\<delta>) = N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1)\<close>
  proof -
    have \<open>R\<^sub>\<rat> * (2::rat)^\<delta> = 2^(n-1-\<gamma>) * 2^(\<gamma>+1) * 2^\<delta>\<close>
      using R_eq R_split by simp
    also have \<open>\<dots> = 2^(n-1-\<gamma>) * 2^(\<gamma>+\<delta>+1)\<close>
      by (simp add: power_add algebra_simps)
    finally have \<open>R\<^sub>\<rat> * (2::rat)^\<delta> = 2^(n-1-\<gamma>) * 2^(\<gamma>+\<delta>+1)\<close> .
    thus ?thesis by simp
  qed
  show ?thesis using step1 slope_le slope_simp by linarith
qed

text \<open>Finally, we obtain the following statement about canonicity of refined
Barrett reduction. Observe how approximation quality and restricted input
bounds contribute equally and can be balanced on a case-by-case basis.\<close>

corollary (in BarrettContext) barrett_red_signed_canonical:
  assumes eps_le: \<open>\<epsilon>(f, R /\<^sub>\<rat> N) \<le> 1/2^\<delta>\<close>
      and z_le:   \<open>\<bar>z\<bar> \<le> 2^(n-1-\<gamma>)\<close>
      and \<gamma>_le:   \<open>\<gamma> \<le> n-1\<close>
      and N_lt:   \<open>N < 2^(\<gamma>+\<delta>)\<close>
  shows \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> < N /\<^sub>\<rat> 2\<close>
proof -
  have slope: \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1) + N\<^sub>\<rat> / 2\<close>
    using barrett_red_signed_bound_slack[OF eps_le z_le \<gamma>_le] .
  have N_lt_rat: \<open>N\<^sub>\<rat> < (2::rat)^(\<gamma>+\<delta>)\<close>
    using N_lt by (metis of_int_less_iff of_int_numeral of_int_power)
  have \<open>N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1) < (2::rat)^(\<gamma>+\<delta>) / 2^(\<gamma>+\<delta>+1)\<close>
    using N_lt_rat by (simp add: divide_strict_right_mono)
  also have \<open>(2::rat)^(\<gamma>+\<delta>) / 2^(\<gamma>+\<delta>+1) = 1/2\<close>
    by (simp add: power_add)
  finally have slope_lt: \<open>N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1) < 1/2\<close> .
  have total: \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> < (N\<^sub>\<rat> + 1) / 2\<close>
  proof -
    have \<open>N\<^sub>\<rat> / 2^(\<gamma>+\<delta>+1) + N\<^sub>\<rat> / 2 < 1/2 + N\<^sub>\<rat> / 2\<close>
      using slope_lt by linarith
    also have \<open>1/2 + N\<^sub>\<rat> / 2 = (N\<^sub>\<rat> + 1) / 2\<close>
      by (simp add: field_simps)
    finally show ?thesis using slope by linarith
  qed
  have int_bound: \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> (N - 1) div 2\<close>
  proof -
    have even_Np1: \<open>(2::int) dvd (N + 1)\<close> using Nodd by simp
    have Np1_half: \<open>of_int ((N + 1) div 2) = (N\<^sub>\<rat> + 1) / 2\<close>
      using of_int_div[OF even_Np1] by simp
    have \<open>of_int \<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> < (of_int ((N + 1) div 2) :: rat)\<close>
      using total Np1_half by simp
    hence \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> < (N + 1) div 2\<close>
      by (simp add: of_int_less_iff)
    thus ?thesis by linarith
  qed
  have even_Nm1: \<open>(2::int) dvd (N - 1)\<close> using Nodd by simp
  have Nm1_half: \<open>of_int ((N - 1) div 2) = ((N\<^sub>\<rat> - 1) / 2 :: rat)\<close>
    using of_int_div[OF even_Nm1] by simp
  have \<open>\<bar>(bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z)\<^sub>\<rat>\<bar> = of_int \<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar>\<close> by simp
  also have \<open>\<dots> \<le> of_int ((N - 1) div 2 :: int)\<close>
    using int_bound by auto
  also have \<open>(of_int ((N - 1) div 2) :: rat) = (N\<^sub>\<rat> - 1) / 2\<close>
    using Nm1_half .
  also have \<open>(N\<^sub>\<rat> - 1) / 2 < N /\<^sub>\<rat> 2\<close> using Ngt1 by simp
  finally show ?thesis .
qed


end

