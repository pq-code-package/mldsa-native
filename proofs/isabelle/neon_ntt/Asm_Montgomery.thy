(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Asm_Montgomery
  imports Word_Ops Montgomery_Doubling
begin

unbundle %invisible ASM_syntax

chapter \<open>Neon kernels for Montgomery-style modular arithmetic \label{ch:asm_montgomery}\<close>


text \<open>In this chapter we analyse three Neon ASM kernels for Montgomery-style
modular multiplication and connect them to the corresponding abstract operators.
In consequence, we obtain correctness and bounds statements for the kernel
output.\<close>

section \<open>Signed Montgomery multiplication\<close>



definition %internal \<open>mont_mul_neon_int n N bT a b \<equiv>
     (let R = (2::int)^n;
          z1 = (2 * (a * b)) div R;             \<comment> \<open>SQDMULH z, a, b\<close>
          k  = (a * bT) mod\<^sup>\<plusminus> R;                  \<comment> \<open>MUL k, a, bT\<close>
          c  = (2 * (k * N)) div R               \<comment> \<open>SQDMULH c, k, N\<close>
      in (z1 - c) div 2)\<close>                       \<comment> \<open>SHSUB z, z, c\<close>

text %internal \<open>The integer-level kernel computes the same value as the abstract
Montgomery doubling algorithm (Algorithm 7). The match is syntactic: both feed
the precomputed product \<^term>\<open>b*T\<close> into the low-half multiply and recover the same
Montgomery quotient.\<close>

lemma %internal mont_mul_neon_int_eq_doubling:
  fixes a b N T :: int and n :: nat
  shows \<open>mont_mul_neon_int n N (b * T) a b = mont_mul_doubling N n T a b\<close>
  unfolding mont_mul_neon_int_def mont_mul_doubling_def Let_def
  by (simp add: algebra_simps)

text %internal \<open>Composing this match with the Algorithm 7 correctness lemma yields
the integer-level correctness of our kernel against the abstract subtractive
Montgomery operator: provided \<^term>\<open>T\<close> is a multiplicative inverse of \<^term>\<open>N\<close> modulo
\<^term>\<open>R\<close> and the modulus satisfies the standard cryptographic conditions, the
kernel returns \<^term>\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk>(a*b)\<close>.\<close>

lemma %internal (in StandardModulus) mont_mul_neon_int_correct:
  fixes a b T :: int
  assumes T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>mont_mul_neon_int n N (b * T) a b = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
  using mont_mul_neon_int_eq_doubling[of n N b T a]
        mont_mul_doubling_eq[OF T_inv, of a b]
  by simp

text %internal \<open>A second form of the kernel exposes the halving subtract \<^verbatim>\<open>SHSUB\<close>
explicitly, putting each of the four lines in one-to-one correspondence with a
Neon mnemonic.\<close>

lemma %internal mont_mul_neon_int_via_shsub:
  fixes a b N bT :: int and n :: nat
  shows \<open>mont_mul_neon_int n N bT a b
           = shsub_int ((2 * (a * b)) div 2^n)
                       ((2 * (((a * bT) mod\<^sup>\<plusminus> 2^n) * N)) div 2^n)\<close>
  unfolding mont_mul_neon_int_def shsub_int_def Let_def by simp


text \<open>The first \<^verbatim>\<open>SQDMULH\<close> needs \<^term>\<open>a\<close> and \<^term>\<open>b\<close> away from \<^term>\<open>-(2^(n-1)) :: int\<close>; the second
needs the same for \<^term>\<open>N\<close>, granted by the standard precondition, and \<^term>\<open>\<bar>k\<bar> \<le> R div 2\<close>,
automatic from \<^verbatim>\<open>MUL\<close>. \<^verbatim>\<open>SHSUB\<close> is non-saturating. The strict input bounds
are exactly the non-saturation conditions.\<close>

definition %internal mont_mul_neon_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mont_mul_neon_word N bT a b \<equiv>
     let ASM \<guillemotleft>
       SQDMULH z1 a b;
       MUL     k  a bT;
       SQDMULH c  k N;
       SHSUB   r  z1 c
     \<guillemotright> in r\<close>

lemma %internal sint_mont_mul_neon_word:
  fixes N bT a b :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes
    \<comment> \<open>\<open>b\<close> non-extreme suffices to avoid SQDMULH saturation\<close>
    nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
    \<comment> \<open>standard cryptographic precondition: \<open>1 < N\<close>, \<open>N < 2^(n-1)\<close>, \<open>odd N\<close>\<close>
    and N_std: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
  shows \<open>sint (mont_mul_neon_word N bT a b)
           = mont_mul_neon_int n (sint N) (sint bT) (sint a) (sint b)\<close>
proof -
  have N_lo: \<open>1 < sint N\<close> using N_std by simp
  have N_lt: \<open>sint N < 2^(n-1)\<close> using N_std by simp
  let ?z1 = \<open>sqdmulh_word a b\<close>
  let ?k  = \<open>mul_word a bT\<close>
  let ?c  = \<open>sqdmulh_word ?k N\<close>
  let ?R  = \<open>(2::int) ^ LENGTH('a)\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have absN: \<open>\<bar>sint N\<bar> < 2^(n-1)\<close>
    using N_lo N_lt by linarith
  have not_extreme1: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint b = -(2^(n-1)))\<close>
    using nondeg_b by linarith
  have not_extreme2: \<open>\<not> (sint ?k = -(2^(n-1)) \<and> sint N = -(2^(n-1)))\<close>
    using absN by linarith
  have z1_int: \<open>sint ?z1 = sqdmulh_int (LENGTH('a)) (sint a) (sint b)\<close>
    by (rule sint_sqdmulh_word[OF refl not_extreme1[unfolded n_def]])
  have k_int: \<open>sint ?k = (sint a * sint bT) mod\<^sup>\<plusminus> ?R\<close>
    by (rule sint_mul_word[OF refl])
  have c_int: \<open>sint ?c = sqdmulh_int (LENGTH('a)) (sint ?k) (sint N)\<close>
    by (rule sint_sqdmulh_word[OF refl not_extreme2[unfolded n_def]])
  have \<open>sint (mont_mul_neon_word N bT a b) = shsub_int (sint ?z1) (sint ?c)\<close>
    unfolding mont_mul_neon_word_def Let_def by (rule sint_shsub_word)
  also have \<open>\<dots> = shsub_int (sqdmulh_int (LENGTH('a)) (sint a) (sint b))
                            (sqdmulh_int (LENGTH('a)) ((sint a * sint bT) mod\<^sup>\<plusminus> ?R) (sint N))\<close>
    using z1_int c_int k_int by simp
  also have \<open>\<dots> = mont_mul_neon_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    unfolding mont_mul_neon_int_def shsub_int_def sqdmulh_int_def Let_def n_def
    by (simp add: algebra_simps)
  finally show ?thesis .
qed

text \<open>The four-instruction \<^verbatim>\<open>SQDMULH\<close>/\<^verbatim>\<open>MUL\<close>/\<^verbatim>\<open>SQDMULH\<close>/\<^verbatim>\<open>SHSUB\<close> sequence
computes \<^term>\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N,n\<rbrakk>(a*b)\<close> on signed lanes.\<close>


theorem mont_mul_neon_word_correct:
  fixes N bT a b :: \<open>'a::len word\<close> and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes N_std: \<open>StandardModulus (sint N) (n-1)\<close>
      and bT_eq: \<open>sint bT = (sint b * ((sint N)\<^sup>-\<^sup>1 mod 2^n)) mod\<^sup>\<plusminus> 2^n\<close>
      and nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQDMULH z1 a b;
                    MUL     k  a bT;
                    SQDMULH c  k N;
                    SHSUB   r  z1 c
                  \<guillemotright> in r\<close>
  shows \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
        \<comment> \<open>abstract description\<close>
    and \<open>(sint out * 2^n) mod sint N = (sint a * sint b) mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a * sint b\<bar>\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
        \<comment> \<open>fine output bound\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (2^(n-1))\<^sub>\<rat>\<close>

        \<comment> \<open>coarse output bound\<close>
proof -
  interpret SM0: StandardModulus \<open>sint N\<close> \<open>n-1\<close> by (rule N_std)
  have N_lo: \<open>1 < sint N\<close> using SM0.Ngt1 .
  have N_lt: \<open>sint N < 2^(n-1)\<close> using SM0.N_lt_R .
  have N_odd: \<open>odd (sint N)\<close> using SM0.Nodd .
  have N_pos: \<open>0 < sint N\<close> using N_lo by linarith
  have n_pos: \<open>n > 0\<close> using SM0.npos by simp
  have N_std_conj: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
    using N_lo N_lt N_odd by simp
  define T where \<open>T \<equiv> (sint N)\<^sup>-\<^sup>1 mod (2^n)\<close>
  have T_inv: \<open>(sint N * T) mod 2^n = 1 mod 2^n\<close>
    unfolding T_def using mod_inverse_correct(3)[OF n_pos N_odd] .
  have step1: \<open>sint (mont_mul_neon_word N bT a b)
                 = mont_mul_neon_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    by (rule sint_mont_mul_neon_word[OF n_def nondeg_b N_std_conj])

  have step2: \<open>mont_mul_neon_int n (sint N) (sint bT) (sint a) (sint b)
                 = mont_mul_neon_int n (sint N) (sint b * T) (sint a) (sint b)\<close>
  proof -
    have n_ge_1: \<open>n \<ge> 1\<close> using n_pos by simp
    hence stb: \<open>\<And>x. signed_take_bit (n-1) x = x mod\<^sup>\<plusminus> 2^n\<close>
      using signed_take_bit_eq_smod by blast
    have bT_smod: \<open>sint bT mod\<^sup>\<plusminus> 2^n = (sint b * T) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_eq unfolding T_def
      by (metis signed_take_bit_int_eq_self_iff signed_take_bit_int_greater_eq_minus_exp
                signed_take_bit_int_less_exp stb)

    have key: \<open>(sint a * sint bT) mod\<^sup>\<plusminus> 2^n
                 = (sint a * (sint b * T)) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_smod stb
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint bT\<close>]
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint b * T\<close>]
      by metis
    show ?thesis
      unfolding mont_mul_neon_int_def Let_def using key by (simp add: n_def)
  qed
  have N_lt_R: \<open>2^n > sint N\<close>
  proof -
    have h: \<open>(2::int)^(n-1) < 2^n\<close>
      using n_pos by (simp add: power_strict_increasing)
    show ?thesis using h N_lt by linarith
  qed
  interpret SM: StandardModulus \<open>sint N\<close> n
    by unfold_locales (use N_lo N_odd n_pos N_lt_R in auto)
  have step3: \<open>mont_mul_neon_int n (sint N) (sint b * T) (sint a) (sint b)
                 = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    using SM.mont_mul_neon_int_correct[OF T_inv] .

  have abs_eq: \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    unfolding out_def mont_mul_neon_word_def[symmetric]
    using step1 step2 step3 by simp
  show \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    by (rule abs_eq)
  show \<open>(sint out * 2^n) mod sint N = (sint a * sint b) mod sint N\<close>
    using abs_eq SM.mont_sub_signed_correct[of \<open>sint a * sint b\<close>] by simp
  have bd: \<open>2 * \<bar>sint out\<bar> * 2^n \<le> 2 * \<bar>sint a * sint b\<bar> + sint N * 2^n\<close>
    using abs_eq SM.mont_sub_signed_bound_int[of \<open>sint a * sint b\<close>] by simp
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a * sint b\<bar>\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
  proof -
    from bd have \<open>(2 * \<bar>sint out\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>sint a * sint b\<bar> + sint N * 2^n)\<^sub>\<rat>\<close>
      by (metis of_int_le_iff)
    thus ?thesis by (simp add: of_int_mult of_int_add of_int_abs field_simps)
  qed





  have bd_abs: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                  \<le> 2 * \<bar>sint a * sint b\<bar> + sint N * 2^n\<close>
    using SM.mont_sub_signed_bound_int[of \<open>sint a * sint b\<close>] .



  have ab_bd: \<open>\<bar>sint a * sint b\<bar> < 2^(n-1) * 2^(n-1)\<close>
  proof -
    have h: \<open>\<bar>sint a * sint b\<bar> = \<bar>sint a\<bar> * \<bar>sint b\<bar>\<close> by (simp add: abs_mult)
    have a_le: \<open>\<bar>sint a\<bar> \<le> 2^(n-1)\<close>
      using sint_range_size[of a] by (simp add: word_size n_def, linarith)
    have h2: \<open>\<bar>sint a\<bar> * \<bar>sint b\<bar> < 2^(n-1) * 2^(n-1)\<close>
    proof -
      have b_pos: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close> using nondeg_b by simp
      have pow_pos: \<open>(0::int) < 2^(n-1)\<close> by simp
      have \<open>\<bar>sint a\<bar> * \<bar>sint b\<bar> \<le> 2^(n-1) * \<bar>sint b\<bar>\<close>
        using a_le by (intro mult_right_mono) auto
      also have \<open>\<dots> < 2^(n-1) * 2^(n-1)\<close>
        using b_pos pow_pos by (intro mult_strict_left_mono) auto
      finally show ?thesis .
    qed
    show ?thesis using h h2 by simp
  qed

  have pow_split: \<open>(2::int)^(2*(n-1)) = 2^(n-1) * 2^(n-1)\<close>
    by (metis power_add mult_2)
  have N_R_bd: \<open>sint N * 2^n < 2^(n-1) * 2^n\<close>
    using N_lt by (simp add: mult_strict_right_mono)
  have R_split: \<open>(2::int)^n = 2 * 2^(n-1)\<close>
    using n_pos by (cases n; auto)
  have step: \<open>2 * \<bar>sint a * sint b\<bar> + sint N * 2^n < 2 * (2^(n-1) * 2^n)\<close>
  proof -
    have h1: \<open>2 * \<bar>sint a * sint b\<bar> < 2 * (2^(n-1) * 2^(n-1))\<close>
      using ab_bd by simp
    have h2: \<open>(2::int) * (2^(n-1) * 2^(n-1)) = 2^(n-1) * 2^n\<close>
      using R_split by (simp add: algebra_simps)
    have h3: \<open>2 * \<bar>sint a * sint b\<bar> < 2^(n-1) * 2^n\<close>
      using h1 h2 by linarith
    have h4: \<open>(2::int)^(n-1) * 2^n + 2^(n-1) * 2^n = 2 * (2^(n-1) * 2^n)\<close>
      by simp
    show ?thesis using h3 N_R_bd h4 by linarith
  qed
  have lhs_lt: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                  < 2 * (2^(n-1) * 2^n)\<close>
    using bd_abs step by linarith
  have R_pos: \<open>(0::int) < 2^n\<close> by simp
  have abs_lt: \<open>\<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> < 2^(n-1)\<close>
  proof -
    have eq: \<open>2 * (2^(n-1) * (2::int)^n) = (2 * 2^(n-1)) * 2^n\<close>
      by (simp add: mult.assoc)
    have lhs2: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                   < (2 * 2^(n-1)) * 2^n\<close>
      using lhs_lt eq by simp
    have can: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar>
                  < 2 * (2::int)^(n-1)\<close>
      using lhs2 R_pos by (simp add: mult_less_cancel_right)
    show ?thesis using can by simp
  qed
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (2^(n-1))\<^sub>\<rat>\<close>
    using abs_eq abs_lt by (metis of_int_abs of_int_less_iff)

qed

section \<open>Signed Montgomery multiplication (rounding variant)\<close>



text \<open>Replacing the two \<^verbatim>\<open>SQDMULH\<close> instructions with their rounding counterparts
\<^verbatim>\<open>SQRDMULH\<close> --- and keeping the trailing \<^verbatim>\<open>SHSUB\<close> --- yields a four-instruction
kernel not explicitly discussed in \cite{NeonNTT}.\<close>


definition %internal \<open>mont_mul_neon_rounding_int n N bT a b \<equiv>
     (let R = (2::int)^n;
          z1 = sqrdmulh_int n a b;                 \<comment> \<open>SQRDMULH z, a, b\<close>
          k  = (a * bT) mod\<^sup>\<plusminus> R;                    \<comment> \<open>MUL k, a, bT\<close>
          c  = sqrdmulh_int n k N                  \<comment> \<open>SQRDMULH c, k, N\<close>
      in (z1 - c) div 2)\<close>                          \<comment> \<open>SHSUB z, z, c\<close>

text %internal \<open>The rounding version uses the same positive-inverse encoding
\<^term>\<open>(N * T) mod 2^n = 1 mod 2^n\<close> as the non-rounding variant; the integer
expansion of \<open>SQRDMULH\<close>'s correction \<open>round(2(kN)/R)\<close> shifts by an
\emph{exact} integer \<^term>\<open>2*q\<close>, with no rounding ambiguity. Hence the kernel
returns \<^term>\<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk>(a * b)\<close> unconditionally.\<close>

lemma %internal (in StandardModulus) mont_mul_neon_rounding_int_correct:
  fixes a b T :: int
  assumes T_inv: \<open>(N * T) mod 2^n = 1 mod 2^n\<close>
  shows \<open>mont_mul_neon_rounding_int n N (b * T) a b = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
proof -
  let ?R = \<open>(2::int)^n\<close>
  let ?k = \<open>(a * b * T) mod\<^sup>\<plusminus> ?R\<close>
  have R_pos: \<open>?R > 0\<close> by simp
  have R_dvd_u: \<open>?R dvd (a * b - ?k * N)\<close>
    using mont_sub_signed_divisible[OF T_inv, of \<open>a * b\<close>] by simp
  then obtain q where q: \<open>a * b - ?k * N = ?R * q\<close>
    unfolding dvd_def by auto
  have mont_eq: \<open>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b) = q\<close>
    using mont_sub_signed_unfold[OF T_inv, of \<open>a * b\<close>]
          q R_pos by simp
  have ab_eq: \<open>2 * (a * b) = ?R * (2 * q) + 2 * (?k * N)\<close>
    using q by (simp add: algebra_simps)
  have c_eq: \<open>sqrdmulh_int n ?k N = sqrdmulh_int n a b - 2 * q\<close>
  proof -
    have eq1: \<open>2 * (?k * N) = 2 * (a * b) - ?R * (2 * q)\<close>
      using ab_eq by (simp add: algebra_simps)
    have \<open>sqrdmulh_int n ?k N = \<lfloor>(2 * (?k * N)) /\<^sub>\<rat> ?R\<rceil>\<close>
      unfolding sqrdmulh_int_def by (simp add: ac_simps)
    also have \<open>\<dots> = \<lfloor>(2 * (a * b) - ?R * (2 * q)) /\<^sub>\<rat> ?R\<rceil>\<close>
      using eq1 by simp
    also have \<open>(2 * (a * b) - ?R * (2 * q)) /\<^sub>\<rat> ?R
                 = (2 * (a * b)) /\<^sub>\<rat> ?R - (2 * q)\<^sub>\<rat>\<close>
      by (simp add: field_simps)
    also have \<open>\<lfloor>(2 * (a * b)) /\<^sub>\<rat> ?R - (2 * q)\<^sub>\<rat>\<rceil>
                 = \<lfloor>(2 * (a * b)) /\<^sub>\<rat> ?R\<rceil> - 2 * q\<close>
      unfolding round_def
      using floor_diff_of_int[of \<open>(2 * (a * b)) /\<^sub>\<rat> ?R + 1/2\<close> \<open>2 * q\<close>]
      by (simp add: algebra_simps)
    also have \<open>\<lfloor>(2 * (a * b)) /\<^sub>\<rat> ?R\<rceil> = sqrdmulh_int n a b\<close>
      unfolding sqrdmulh_int_def by (simp add: mult.assoc)
    finally show ?thesis .
  qed
  have \<open>mont_mul_neon_rounding_int n N (b * T) a b
          = (sqrdmulh_int n a b - sqrdmulh_int n ?k N) div 2\<close>
    unfolding mont_mul_neon_rounding_int_def Let_def
    by (simp add: algebra_simps)
  also have \<open>\<dots> = (2 * q) div 2\<close> using c_eq by simp
  also have \<open>\<dots> = q\<close> by simp
  finally show ?thesis using mont_eq by simp
qed

text %internal \<open>Lifting to fixed-width signed words follows the same template as
\<^term>\<open>mont_mul_neon_word\<close>. The non-saturation conditions on the second
\<^verbatim>\<open>SQRDMULH\<close> are dispatched by the one-sided variant
\<^term>\<open>sqrdmulh_int_no_sat_one_side\<close>.\<close>

definition %internal mont_mul_neon_rounding_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mont_mul_neon_rounding_word N bT a b \<equiv>
     let ASM \<guillemotleft>
       SQRDMULH z1 a b;
       MUL      k  a bT;
       SQRDMULH c  k N;
       SHSUB    r  z1 c
     \<guillemotright> in r\<close>

lemma %internal sint_mont_mul_neon_rounding_word:
  fixes N bT a b :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
      and N_std: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
  shows \<open>sint (mont_mul_neon_rounding_word N bT a b)
           = mont_mul_neon_rounding_int n (sint N) (sint bT) (sint a) (sint b)\<close>
proof -
  have N_lo: \<open>1 < sint N\<close> using N_std by simp
  have N_lt: \<open>sint N < 2^(n-1)\<close> using N_std by simp
  let ?z1 = \<open>sqrdmulh_word a b\<close>
  let ?k  = \<open>mul_word a bT\<close>
  let ?c  = \<open>sqrdmulh_word ?k N\<close>
  let ?R  = \<open>(2::int) ^ LENGTH('a)\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have absN: \<open>\<bar>sint N\<bar> < 2^(n-1)\<close>
    using N_lo N_lt by linarith
  have not_extreme1: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint b = -(2^(n-1)))\<close>
    using nondeg_b by linarith

  have not_extreme2: \<open>\<not> (sint ?k = -(2^(n-1)) \<and> sint N = -(2^(n-1)))\<close>
    using absN by linarith
  have z1_int: \<open>sint ?z1 = sqrdmulh_int (LENGTH('a)) (sint a) (sint b)\<close>
    by (rule sint_sqrdmulh_word[OF refl not_extreme1[unfolded n_def]])
  have k_int: \<open>sint ?k = (sint a * sint bT) mod\<^sup>\<plusminus> ?R\<close>
    by (rule sint_mul_word[OF refl])
  have c_int: \<open>sint ?c = sqrdmulh_int (LENGTH('a)) (sint ?k) (sint N)\<close>
    by (rule sint_sqrdmulh_word[OF refl not_extreme2[unfolded n_def]])
  have \<open>sint (mont_mul_neon_rounding_word N bT a b) = shsub_int (sint ?z1) (sint ?c)\<close>
    unfolding mont_mul_neon_rounding_word_def Let_def by (rule sint_shsub_word)
  also have \<open>\<dots> = shsub_int (sqrdmulh_int (LENGTH('a)) (sint a) (sint b))
                            (sqrdmulh_int (LENGTH('a)) ((sint a * sint bT) mod\<^sup>\<plusminus> ?R) (sint N))\<close>
    using z1_int c_int k_int by simp
  also have \<open>\<dots> = mont_mul_neon_rounding_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    unfolding mont_mul_neon_rounding_int_def shsub_int_def sqrdmulh_int_def Let_def n_def
    by (simp add: algebra_simps)
  finally show ?thesis .
qed


theorem mont_mul_neon_rounding_word_correct:
  fixes N bT a b :: \<open>'a::len word\<close> and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes N_std: \<open>StandardModulus (sint N) (n-1)\<close>
      and bT_eq: \<open>sint bT = (sint b * ((sint N)\<^sup>-\<^sup>1 mod 2^n)) mod\<^sup>\<plusminus> 2^n\<close>
      and nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQRDMULH z1 a b;
                    MUL      k  a bT;
                    SQRDMULH c  k N;
                    SHSUB    r  z1 c
                  \<guillemotright> in r\<close>
  shows \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
        \<comment> \<open>abstract description\<close>
    and \<open>(sint out * 2^n) mod sint N = (sint a * sint b) mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a * sint b\<bar>\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
        \<comment> \<open>fine output bound\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (2^(n-1))\<^sub>\<rat>\<close>

        \<comment> \<open>coarse output bound\<close>

proof -
  interpret SM0: StandardModulus \<open>sint N\<close> \<open>n-1\<close> by (rule N_std)
  have N_lo: \<open>1 < sint N\<close> using SM0.Ngt1 .
  have N_lt: \<open>sint N < 2^(n-1)\<close> using SM0.N_lt_R .
  have N_odd: \<open>odd (sint N)\<close> using SM0.Nodd .
  have N_pos: \<open>0 < sint N\<close> using N_lo by linarith
  have n_pos: \<open>n > 0\<close> using SM0.npos by simp
  have N_std_conj: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
    using N_lo N_lt N_odd by simp

  define T where \<open>T \<equiv> (sint N)\<^sup>-\<^sup>1 mod (2^n)\<close>
  have T_inv: \<open>(sint N * T) mod 2^n = 1 mod 2^n\<close>
    unfolding T_def using mod_inverse_correct(3)[OF n_pos N_odd] .
  have step1: \<open>sint (mont_mul_neon_rounding_word N bT a b)
                 = mont_mul_neon_rounding_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    by (rule sint_mont_mul_neon_rounding_word[OF n_def nondeg_b N_std_conj])

  have step2: \<open>mont_mul_neon_rounding_int n (sint N) (sint bT) (sint a) (sint b)
                 = mont_mul_neon_rounding_int n (sint N) (sint b * T) (sint a) (sint b)\<close>
  proof -
    have n_ge_1: \<open>n \<ge> 1\<close> using n_pos by simp
    hence stb: \<open>\<And>x. signed_take_bit (n-1) x = x mod\<^sup>\<plusminus> 2^n\<close>
      using signed_take_bit_eq_smod by blast
    have bT_smod: \<open>sint bT mod\<^sup>\<plusminus> 2^n = (sint b * T) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_eq unfolding T_def
      by (metis signed_take_bit_int_eq_self_iff signed_take_bit_int_greater_eq_minus_exp
                signed_take_bit_int_less_exp stb)

    have key: \<open>(sint a * sint bT) mod\<^sup>\<plusminus> 2^n
                 = (sint a * (sint b * T)) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_smod stb
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint bT\<close>]
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint b * T\<close>]
      by metis
    show ?thesis
      unfolding mont_mul_neon_rounding_int_def Let_def using key by (simp add: n_def)
  qed
  have N_lt_R: \<open>2^n > sint N\<close>
  proof -
    have h: \<open>(2::int)^(n-1) < 2^n\<close>
      using n_pos by (simp add: power_strict_increasing)
    show ?thesis using h N_lt by linarith
  qed
  interpret SM: StandardModulus \<open>sint N\<close> n
    by unfold_locales (use N_lo N_odd n_pos N_lt_R in auto)
  have step3: \<open>mont_mul_neon_rounding_int n (sint N) (sint b * T) (sint a) (sint b)
                  = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    using SM.mont_mul_neon_rounding_int_correct[OF T_inv] .

  have abs_eq: \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    unfolding out_def mont_mul_neon_rounding_word_def[symmetric]
    using step1 step2 step3 by simp
  show \<open>sint out = mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    by (rule abs_eq)
  show \<open>(sint out * 2^n) mod sint N = (sint a * sint b) mod sint N\<close>
    using abs_eq SM.mont_sub_signed_correct[of \<open>sint a * sint b\<close>] by simp
  have bd: \<open>2 * \<bar>sint out\<bar> * 2^n \<le> 2 * \<bar>sint a * sint b\<bar> + sint N * 2^n\<close>
    using abs_eq SM.mont_sub_signed_bound_int[of \<open>sint a * sint b\<close>] by simp
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> \<bar>sint a * sint b\<bar>\<^sub>\<rat> / (2^n)\<^sub>\<rat> + (sint N)\<^sub>\<rat> / 2\<close>
  proof -
    from bd have \<open>(2 * \<bar>sint out\<bar> * 2^n)\<^sub>\<rat> \<le> (2 * \<bar>sint a * sint b\<bar> + sint N * 2^n)\<^sub>\<rat>\<close>
      by (metis of_int_le_iff)
    thus ?thesis by (simp add: of_int_mult of_int_add of_int_abs field_simps)
  qed

  have bd_abs: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                  \<le> 2 * \<bar>sint a * sint b\<bar> + sint N * 2^n\<close>
    using SM.mont_sub_signed_bound_int[of \<open>sint a * sint b\<close>] .

  have ab_bd: \<open>\<bar>sint a * sint b\<bar> < 2^(n-1) * 2^(n-1)\<close>
  proof -
    have h: \<open>\<bar>sint a * sint b\<bar> = \<bar>sint a\<bar> * \<bar>sint b\<bar>\<close> by (simp add: abs_mult)
    have a_le: \<open>\<bar>sint a\<bar> \<le> 2^(n-1)\<close>
      using sint_range_size[of a] by (simp add: word_size n_def, linarith)
    have h2: \<open>\<bar>sint a\<bar> * \<bar>sint b\<bar> < 2^(n-1) * 2^(n-1)\<close>
    proof -
      have b_pos: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close> using nondeg_b by simp
      have pow_pos: \<open>(0::int) < 2^(n-1)\<close> by simp
      have \<open>\<bar>sint a\<bar> * \<bar>sint b\<bar> \<le> 2^(n-1) * \<bar>sint b\<bar>\<close>
        using a_le by (intro mult_right_mono) auto
      also have \<open>\<dots> < 2^(n-1) * 2^(n-1)\<close>
        using b_pos pow_pos by (intro mult_strict_left_mono) auto
      finally show ?thesis .
    qed
    show ?thesis using h h2 by simp
  qed
  have N_R_bd: \<open>sint N * 2^n < 2^(n-1) * 2^n\<close>
    using N_lt by (simp add: mult_strict_right_mono)

  have R_split: \<open>(2::int)^n = 2 * 2^(n-1)\<close>
    using n_pos by (cases n; auto)
  have step: \<open>2 * \<bar>sint a * sint b\<bar> + sint N * 2^n < 2 * (2^(n-1) * 2^n)\<close>
  proof -
    have h1: \<open>2 * \<bar>sint a * sint b\<bar> < 2 * (2^(n-1) * 2^(n-1))\<close>
      using ab_bd by simp
    have h2: \<open>(2::int) * (2^(n-1) * 2^(n-1)) = 2^(n-1) * 2^n\<close>
      using R_split by (simp add: algebra_simps)
    have h3: \<open>2 * \<bar>sint a * sint b\<bar> < 2^(n-1) * 2^n\<close>
      using h1 h2 by linarith
    have h4: \<open>(2::int)^(n-1) * 2^n + 2^(n-1) * 2^n = 2 * (2^(n-1) * 2^n)\<close>
      by simp
    show ?thesis using h3 N_R_bd h4 by linarith
  qed
  have lhs_lt: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                  < 2 * (2^(n-1) * 2^n)\<close>
    using bd_abs step by linarith
  have R_pos: \<open>(0::int) < 2^n\<close> by simp
  have abs_lt: \<open>\<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> < 2^(n-1)\<close>
  proof -
    have eq: \<open>2 * (2^(n-1) * (2::int)^n) = (2 * 2^(n-1)) * 2^n\<close>
      by (simp add: mult.assoc)
    have lhs2: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
                   < (2 * 2^(n-1)) * 2^n\<close>
      using lhs_lt eq by simp
    have can: \<open>2 * \<bar>mont\<^sub>s\<^sub>u\<^sub>b\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar>
                  < 2 * (2::int)^(n-1)\<close>
      using lhs2 R_pos by (simp add: mult_less_cancel_right)
    show ?thesis using can by simp
  qed
  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> < (2^(n-1))\<^sub>\<rat>\<close>
    using abs_eq abs_lt by (metis of_int_abs of_int_less_iff)

qed

section \<open>Doubled Montgomery multiplication\<close>



text \<open>\cite[Algorithm~13, \S 3.2]{NeonNTT}: the three-instruction
\<^verbatim>\<open>SQRDMULH\<close>/\<^verbatim>\<open>MUL\<close>/\<^verbatim>\<open>SQRDMLAH\<close> sequence doubles the result
and computes \<^term>\<open>2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N,n\<rbrakk>(a*b)\<close> on signed lanes.\<close>


definition %internal \<open>mont_mul_neon_rounding_doubled_int n N bT a b \<equiv>
     (let R = (2::int)^n;
          z = sqrdmulh_int n a b;                  \<comment> \<open>SQRDMULH z, a, b\<close>
          k = (a * bT) mod\<^sup>\<plusminus> R;                     \<comment> \<open>MUL k, a, bT\<close>
          c = sqrdmulh_int n k N                   \<comment> \<open>(rounding correction)\<close>
      in z + c)\<close>                                   \<comment> \<open>SQRDMLAH z, k, N\<close>

text %internal \<open>Up to renaming, the integer kernel coincides syntactically with
\<^term>\<open>mont_mul_rounding_doubled_int\<close> from \<open>Montgomery_Doubling.thy\<close> when the precomputed
twiddle is \<^term>\<open>bT = b*T\<close>. Composing the syntactic equality with
\<^term>\<open>mont_mul_rounding_doubled_eq\<close> gives integer-level correctness.\<close>

lemma %internal mont_mul_neon_rounding_doubled_int_eq_doubled:
  fixes a b N T :: int and n :: nat
  shows \<open>mont_mul_neon_rounding_doubled_int n N (b * T) a b
           = mont_mul_rounding_doubled_int N n T a b\<close>
  unfolding mont_mul_neon_rounding_doubled_int_def mont_mul_rounding_doubled_int_def
            Let_def sqrdmulh_int_def
  by (simp add: algebra_simps)

lemma %internal (in StandardModulus) mont_mul_neon_rounding_doubled_int_correct:
  fixes a b T :: int
  assumes T_inv: \<open>(N * T) mod 2^n = (- 1) mod 2^n\<close>
      and parity: \<open>2 * a * b mod 2^n \<noteq> 2^(n-1)\<close>
  shows \<open>mont_mul_neon_rounding_doubled_int n N (b * T) a b
           = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>N, n\<rbrakk> (a * b)\<close>
  using mont_mul_neon_rounding_doubled_int_eq_doubled[of n N b T a]
        mont_mul_rounding_doubled_eq[OF T_inv parity]
  by simp

text %internal \<open>Discharging the non-tie hypothesis. With \<^term>\<open>\<bar>a\<bar> < (2::int)^(n-2)\<close> and
\<^term>\<open>odd b\<close>, the only way \<^term>\<open>(2*a*b) mod 2^n = (2::int)^(n-1)\<close> would force
\<^term>\<open>(2::int)^(n-2) dvd a\<close>, hence \<^term>\<open>a = 0\<close>; then \<open>2ab = 0 \<noteq> 2^(n-1) (mod 2^n)\<close>, a contradiction.\<close>

lemma %internal parity_discharge:
  fixes a b :: int and n :: nat
  assumes \<open>n \<ge> 2\<close> and \<open>\<bar>a\<bar> < 2^(n-2)\<close> and \<open>odd b\<close>
  shows \<open>2 * a * b mod 2^n \<noteq> 2^(n-1)\<close>
proof
  assume eq: \<open>2 * a * b mod 2^n = 2^(n-1)\<close>
  have nge1: \<open>n \<ge> 1\<close> using assms(1) by linarith
  have R_eq: \<open>(2::int)^n = 2 * 2^(n-1)\<close>
    using nge1 by (cases n) auto
  have H_eq: \<open>(2::int)^(n-1) = 2 * 2^(n-2)\<close>
  proof -
    have \<open>n - 1 = Suc (n - 2)\<close> using assms(1) by simp
    thus ?thesis by simp
  qed
  have ab_eq: \<open>2 * a * b = 2^n * (2 * a * b div 2^n) + 2^(n-1)\<close>
    using eq by (metis div_mod_decomp_int mult.commute)
  define q where q_def: \<open>q = 2 * a * b div 2^n\<close>
  have ab_eq2: \<open>2 * a * b = 2^n * q + 2^(n-1)\<close>
    using ab_eq q_def by simp
  have ab_eq3: \<open>2 * a * b = 2^(n-1) * (2 * q + 1)\<close>
    using ab_eq2 R_eq by (simp add: algebra_simps)
  have ab_eq4: \<open>a * b = 2^(n-2) * (2 * q + 1)\<close>
    using ab_eq3 H_eq by simp
  have H2_dvd_ab: \<open>(2::int)^(n-2) dvd a * b\<close>
    using ab_eq4 by (metis dvd_triv_left)
  have copr: \<open>coprime ((2::int)^(n-2)) b\<close>
    using assms(3) by simp
  have H2_dvd_a: \<open>(2::int)^(n-2) dvd a\<close>
    using H2_dvd_ab copr coprime_dvd_mult_left_iff by blast
  have a_zero: \<open>a = 0\<close>
    using H2_dvd_a assms(2) dvd_imp_le_int by force
  hence \<open>2 * a * b = 0\<close> by simp
  hence \<open>(2::int)^(n-1) * (2 * q + 1) = 0\<close>
    using ab_eq3 by simp
  hence \<open>2 * q + 1 = 0\<close> by simp
  thus False by presburger
qed

text %internal \<open>The word-level kernel uses \<^verbatim>\<open>SQRDMLAH\<close> to fuse the high-product and the
correction. To turn the abstract \<^term>\<open>z + sqrdmulh_int n k N\<close> back into
\<^term>\<open>sint\<close> of the \asminst{SQRDMLAH} output we need (a) non-saturation of the second
\<^verbatim>\<open>SQRDMULH\<close> --- furnished by \<^term>\<open>sqrdmulh_int_no_sat_one_side\<close>; and (b)
non-saturation of the \asminst{SQRDMLAH} itself --- the integer result fits inside
the canonical signed range.\<close>

definition %internal mont_mul_neon_rounding_doubled_word
  :: \<open>'a::len word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word \<Rightarrow> 'a word\<close> where
  \<open>mont_mul_neon_rounding_doubled_word N bT a b \<equiv>
     let ASM \<guillemotleft>
       SQRDMULH z a b;
       MUL      k a bT;
       SQRDMLAH r z k N
     \<guillemotright> in r\<close>

lemma %internal sint_mont_mul_neon_rounding_doubled_word:
  fixes N bT a b :: \<open>'a::len word\<close>
    and n :: nat  \<comment> \<open>number of bits in 'a word\<close>
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes nondeg_a: \<open>\<bar>sint a\<bar> < 2^(n-1)\<close>
      and nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
      and N_std: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
      \<comment> \<open>final SQRDMLAH does not saturate\<close>
      and no_sat: \<open>-(2^(n-1)) \<le> mont_mul_neon_rounding_doubled_int n
                                     (sint N) (sint bT) (sint a) (sint b)\<close>
                  \<open>mont_mul_neon_rounding_doubled_int n
                     (sint N) (sint bT) (sint a) (sint b) < 2^(n-1)\<close>
  shows \<open>sint (mont_mul_neon_rounding_doubled_word N bT a b)
           = mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)\<close>
proof -
  have N_lo: \<open>1 < sint N\<close> using N_std by simp
  have N_lt: \<open>sint N < 2^(n-1)\<close> using N_std by simp
  let ?z = \<open>sqrdmulh_word a b\<close>
  let ?k = \<open>mul_word a bT\<close>
  let ?R = \<open>(2::int) ^ LENGTH('a)\<close>
  have npos: \<open>n > 0\<close> unfolding n_def using len_gt_0[where 'a='a] .
  have not_extreme1: \<open>\<not> (sint a = -(2^(n-1)) \<and> sint b = -(2^(n-1)))\<close>
    using nondeg_a by linarith
  have z_int: \<open>sint ?z = sqrdmulh_int (LENGTH('a)) (sint a) (sint b)\<close>
    by (rule sint_sqrdmulh_word[OF refl not_extreme1[unfolded n_def]])
  have k_int: \<open>sint ?k = (sint a * sint bT) mod\<^sup>\<plusminus> ?R\<close>
    by (rule sint_mul_word[OF refl])
  have body_eq: \<open>sqrdmlah_int n (sint ?z) (sint ?k) (sint N)
                   = mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    unfolding sqrdmlah_int_def mont_mul_neon_rounding_doubled_int_def Let_def
    using z_int k_int by (simp add: n_def)
  have lo: \<open>-(2^(n-1)) \<le> sqrdmlah_int n (sint ?z) (sint ?k) (sint N)\<close>
    using body_eq no_sat(1) by simp
  have hi: \<open>sqrdmlah_int n (sint ?z) (sint ?k) (sint N) < 2 ^ (n - 1)\<close>
    using body_eq no_sat(2) by simp
  have \<open>sint (mont_mul_neon_rounding_doubled_word N bT a b)
          = sint (sqrdmlah_word ?z ?k N)\<close>
    unfolding mont_mul_neon_rounding_doubled_word_def Let_def by (rule refl)
  also have \<open>\<dots> = sqrdmlah_int n (sint ?z) (sint ?k) (sint N)\<close>
    by (rule sint_sqrdmlah_word[OF n_def lo hi])
  also have \<open>\<dots> = mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    using body_eq .
  finally show ?thesis .
qed



theorem mont_mul_neon_rounding_doubled_word_correct:
  fixes N bT a b :: \<open>'a::len word\<close> and n :: nat
  assumes n_def: \<open>n = LENGTH('a)\<close>
  assumes N_std: \<open>StandardModulus (sint N) (n-2)\<close>
      and bT_eq: \<open>sint bT = (sint b * ((- ((sint N)\<^sup>-\<^sup>1 mod 2^n)) mod 2^n)) mod\<^sup>\<plusminus> 2^n\<close>
      and small_a: \<open>\<bar>sint a\<bar> < 2^(n-2)\<close>
      and odd_b: \<open>odd (sint b)\<close>
  defines \<open>out \<equiv> let ASM \<guillemotleft>
                    SQRDMULH z a b;
                    MUL      k a bT;
                    SQRDMLAH r z k N
                  \<guillemotright> in r\<close>
  shows \<open>sint out = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
        \<comment> \<open>abstract description\<close>
    and \<open>(sint out * 2^n) mod sint N = (2 * sint a * sint b) mod sint N\<close>
        \<comment> \<open>correctness\<close>
    and \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> (2^(n-1))\<^sub>\<rat>\<close>
        \<comment> \<open>coarse output bound\<close>
proof -
  interpret SM0: StandardModulus \<open>sint N\<close> \<open>n-2\<close> by (rule N_std)
  have N_lo: \<open>1 < sint N\<close> using SM0.Ngt1 .
  have N_lt_n2: \<open>sint N < 2^(n-2)\<close> using SM0.N_lt_R .
  have N_small: \<open>sint N \<le> 2^(n-2)\<close> using N_lt_n2 by linarith
  have N_lt: \<open>sint N < 2^(n-1)\<close>
    using N_lt_n2 power_increasing[of \<open>n-2\<close> \<open>n-1\<close> \<open>2::int\<close>] by linarith
  have N_odd: \<open>odd (sint N)\<close> using SM0.Nodd .
  have N_std_conj: \<open>1 < sint N \<and> sint N < 2^(n-1) \<and> odd (sint N)\<close>
    using N_lo N_lt N_odd by simp
  have N_pos: \<open>0 < sint N\<close> using N_lo by linarith
  have nge2: \<open>n \<ge> 2\<close>
  proof (rule ccontr)
    assume \<open>\<not> (n \<ge> 2)\<close>
    hence \<open>n \<le> 1\<close> by simp
    hence \<open>n - 1 = 0\<close> by simp
    hence \<open>(2::int)^(n-1) = 1\<close> by simp
    thus False using N_lo N_lt by linarith
  qed
  have n_pos: \<open>n > 0\<close> using nge2 by linarith
  have n_ge_1: \<open>n \<ge> 1\<close> using n_pos by simp
  have nondeg_a: \<open>\<bar>sint a\<bar> < 2^(n-1)\<close>
  proof -
    have h: \<open>(2::int)^(n-2) \<le> 2^(n-1)\<close>
      by (simp add: power_increasing)
    show ?thesis using small_a h by linarith
  qed
  have nondeg_b: \<open>\<bar>sint b\<bar> < 2^(n-1)\<close>
  proof -
    have rb: \<open>-(2^(n-1)) \<le> sint b \<and> sint b < 2 ^ (n - 1)\<close>
      using sint_in_signed_range[OF n_def, of b] .
    have b_ne_min: \<open>sint b \<noteq> -(2^(n-1))\<close>
    proof
      assume \<open>sint b = -(2^(n-1))\<close>
      moreover have \<open>even ((2::int)^(n-1))\<close> using nge2 by simp
      ultimately have \<open>even (sint b)\<close> by simp
      thus False using odd_b by simp
    qed
    show ?thesis using rb b_ne_min by linarith
  qed
  have parity: \<open>2 * sint a * sint b mod 2^n \<noteq> 2^(n-1)\<close>
    by (rule parity_discharge[OF nge2 small_a odd_b])


  have N_lt_R: \<open>2^n > sint N\<close>
  proof -
    have h: \<open>(2::int)^(n-1) < 2^n\<close>
      using n_pos by (simp add: power_strict_increasing)
    show ?thesis using h N_lt by linarith
  qed
  interpret SM: StandardModulus \<open>sint N\<close> n
    by unfold_locales (use N_lo N_odd n_pos N_lt_R in auto)
  define T where \<open>T \<equiv> (- ((sint N)\<^sup>-\<^sup>1 mod 2^n)) mod 2^n\<close>
  have T_inv: \<open>(sint N * T) mod 2^n = (- 1) mod 2^n\<close>
    unfolding T_def using SM.mod_inverse_neg_correct by (simp add: mult.commute)
  \<comment> \<open>Derive the SQRDMLAH non-saturation bound from \<open>|sint a| < 2^(n-2)\<close>,
        \<open>|sint b| < 2^(n-1)\<close> and \<open>sint N \<le> 2^(n-2)\<close>.\<close>
  have B: \<open>2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n
              \<le> 2 * \<bar>sint a * sint b\<bar> + sint N * 2^n\<close>
    using SM.mont_add_signed_bound_int[of \<open>sint a * sint b\<close>] .
  have ab_bd: \<open>\<bar>sint a * sint b\<bar> < 2^(n-2) * 2^(n-1)\<close>
  proof -
    have h1: \<open>\<bar>sint a * sint b\<bar> = \<bar>sint a\<bar> * \<bar>sint b\<bar>\<close> by (simp add: abs_mult)
    have h2: \<open>\<bar>sint a\<bar> * \<bar>sint b\<bar> < 2^(n-2) * 2^(n-1)\<close>
      using small_a nondeg_b by (intro mult_strict_mono) auto
    show ?thesis using h1 h2 by simp
  qed

  have N_2n_eq: \<open>(2::int)^(n-2) * 2^n = 2^(2*n-2)\<close>
  proof -
    have \<open>(n-2) + n = 2*n - 2\<close> using nge2 by simp
    thus ?thesis by (metis power_add)
  qed
  have ab_double_bd: \<open>2 * \<bar>sint a * sint b\<bar> < 2^(2*n-2)\<close>
  proof -
    have e1: \<open>(2::int)^(n-2) * 2^(n-1) = 2^(2*n-3)\<close>
    proof -
      have \<open>(n-2) + (n-1) = 2*n-3\<close> using nge2 by simp
      thus ?thesis by (metis power_add)
    qed
    have e2: \<open>(2::int) * 2^(2*n-3) = 2^(2*n-2)\<close>
    proof -
      have \<open>2*n - 3 + 1 = 2*n - 2\<close> using nge2 by simp
      thus ?thesis by (metis power_Suc Suc_eq_plus1)
    qed
    have \<open>2 * \<bar>sint a * sint b\<bar> < 2 * 2^(2*n-3)\<close>
      using ab_bd e1 by linarith
    thus ?thesis using e2 by linarith
  qed
  have rhs_eq: \<open>(2::int) * 2^(2*n-2) = 2^(n-1) * 2^n\<close>
  proof -
    have h1: \<open>(2::int) * 2^(2*n-2) = 2^(2*n-1)\<close>
    proof -
      have \<open>(2*n-2)+1 = 2*n - 1\<close> using nge2 by simp
      thus ?thesis by (metis power_Suc Suc_eq_plus1)
    qed
    have h2: \<open>(2::int)^(n-1) * 2^n = 2^(2*n-1)\<close>
    proof -
      have \<open>(n-1)+n = 2*n-1\<close> using nge2 by simp
      thus ?thesis by (metis power_add)
    qed
    show ?thesis using h1 h2 by simp
  qed
  have N2n: \<open>sint N * 2^n \<le> 2^(n-2) * 2^n\<close>
    using N_small by simp
  have sum_bd: \<open>2 * \<bar>sint a * sint b\<bar> + sint N * 2^n < 2 * 2^(2*n-2)\<close>
    using ab_double_bd N2n N_2n_eq by linarith
  have lhs_lt: \<open>2 * \<bar>mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> * 2^n < 2^(n-1) * 2^n\<close>
    using B sum_bd rhs_eq by linarith
  have R_pos: \<open>(0::int) < 2^n\<close> by simp
  have no_sat: \<open>\<bar>2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<bar> < 2^(n-1)\<close>
    using lhs_lt R_pos by (simp add: mult_less_cancel_right)
  \<comment> \<open>Step 1: integer kernel applied to the precomputed twiddle = abstract doubled \<open>mont_add\<close>.\<close>
  have step_int_b: \<open>mont_mul_neon_rounding_doubled_int n (sint N) (sint b * T) (sint a) (sint b)
                      = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    using SM.mont_mul_neon_rounding_doubled_int_correct[OF T_inv parity] .

  \<comment> \<open>Step 2: the integer kernel only depends on \<open>bT\<close> through \<open>(a*bT) mod\<^sup>\<plusminus> R\<close>;
        rewriting \<open>sint bT\<close> to \<open>sint b * T\<close> modulo signed reduction
        is the same calculation as for the \asminst{SHSUB} kernel.\<close>
  have step_bT_eq: \<open>mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)
                      = mont_mul_neon_rounding_doubled_int n (sint N) (sint b * T) (sint a) (sint b)\<close>
  proof -
    have stb: \<open>\<And>x. signed_take_bit (n-1) x = x mod\<^sup>\<plusminus> 2^n\<close>
      using signed_take_bit_eq_smod[OF n_ge_1] by blast
    have bT_smod: \<open>sint bT mod\<^sup>\<plusminus> 2^n = (sint b * T) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_eq unfolding T_def
      by (metis signed_take_bit_int_eq_self_iff signed_take_bit_int_greater_eq_minus_exp
                signed_take_bit_int_less_exp stb)


    have key: \<open>(sint a * sint bT) mod\<^sup>\<plusminus> 2^n
                 = (sint a * (sint b * T)) mod\<^sup>\<plusminus> 2^n\<close>
      using bT_smod stb
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint bT\<close>]
            signed_take_bit_mult[of \<open>n-1\<close> \<open>sint a\<close> \<open>sint b * T\<close>]
      by metis
    show ?thesis
      unfolding mont_mul_neon_rounding_doubled_int_def Let_def
      using key by (simp add: n_def)
  qed
  have step_int: \<open>mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)
                    = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    using step_bT_eq step_int_b by simp
  \<comment> \<open>Step 3: lift via \<open>sint_mont_mul_neon_rounding_doubled_word\<close>; the
        non-saturation of \asminst{SQRDMLAH} was derived from the input bounds.\<close>
  have lo: \<open>-(2^(n-1))
              \<le> mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    using step_int no_sat by linarith
  have hi: \<open>mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)
              < 2^(n-1)\<close>
    using step_int no_sat by linarith
  have step_word: \<open>sint (mont_mul_neon_rounding_doubled_word N bT a b)
                     = mont_mul_neon_rounding_doubled_int n (sint N) (sint bT) (sint a) (sint b)\<close>
    by (rule sint_mont_mul_neon_rounding_doubled_word[OF n_def nondeg_a nondeg_b N_std_conj lo hi])

  have abs_eq: \<open>sint out = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    unfolding out_def mont_mul_neon_rounding_doubled_word_def[symmetric]
    using step_word step_int by simp
  show \<open>sint out = 2 * mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b)\<close>
    by (rule abs_eq)
  have mont_eq: \<open>(mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b) * 2^n) mod sint N
                    = (sint a * sint b) mod sint N\<close>
    using SM.mont_add_signed_correct[of \<open>sint a * sint b\<close>] .
  show \<open>(sint out * 2^n) mod sint N = (2 * sint a * sint b) mod sint N\<close>
  proof -
    have e1: \<open>sint out * 2^n
                = 2 * (mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b) * 2^n)\<close>
      using abs_eq by simp
    have e2: \<open>(2 * (mont\<^sub>a\<^sub>d\<^sub>d\<^sup>\<plusminus>\<lbrakk>sint N, n\<rbrakk> (sint a * sint b) * 2^n)) mod sint N
                = (2 * (sint a * sint b)) mod sint N\<close>
      using mont_eq by (metis mod_mult_right_eq)
    show ?thesis using e1 e2 by (simp add: mult.assoc)
  qed
  have rng: \<open>-(2^(n-1)) \<le> sint out \<and> sint out < 2^(n-1)\<close>
    unfolding out_def
    using sint_in_signed_range[OF n_def] by blast

  show \<open>\<bar>(sint out)\<^sub>\<rat>\<bar> \<le> (2^(n-1))\<^sub>\<rat>\<close>
  proof -
    have \<open>\<bar>sint out\<bar> \<le> 2^(n-1)\<close> using rng by linarith
    thus ?thesis by (metis of_int_abs of_int_le_iff)
  qed

qed


end
