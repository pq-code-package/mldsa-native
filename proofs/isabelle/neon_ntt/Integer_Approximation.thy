(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Integer_Approximation
  imports HOL.Rat HOL.NthRoot
begin

(*<*)
text \<open>Suppress \<open>:: 'a\<close> in document antiquotations only. The IDE
hover-types and outer \<open>term\<close> command are unaffected, since they don't go through
\<^ML>\<open>Document_Output.antiquotation_pretty_source\<close>.\<close>

setup \<open>
  Document_Output.antiquotation_pretty_source_embedded \<^binding>\<open>term\<close>
    (Term_Style.parse -- Args.term)
    (fn ctxt => fn (style, t) =>
      let
        val ctxt' = ctxt
          |> Config.put show_types false
          |> Config.put show_sorts false
          |> Config.put show_question_marks false
          |> Config.put Printer.show_type_emphasis false
      in Document_Output.pretty_term ctxt' (style t) end)
\<close>
(*>*)

chapter \<open>Integer approximations and modular residues \label{ch:integer_approx}\<close>

text \<open>
Barrett and Montgomery reduction are usually presented with a fixed
rounding mode, but multiple variants exist: the textbook bound proofs are
stated for round-to-nearest, the unsigned variant uses flooring, and the
\asminst{SQRDMULH}-based signed Barrett kernel produces an even-rounded result. To avoid replicating the
same proof four times we work uniformly over an arbitrary \emph{integer approximation}
\<open>\<lbrakk>_\<rbrakk> : \<rat> \<rightarrow> \<int>\<close>, prove the underlying arithmetic facts once, and specialise \<open>\<lbrakk>_\<rbrakk>\<close> at each use site.

This chapter develops the predicate \<open>is_int_approx \<lbrakk>_\<rbrakk>\<close> defining what counts as an integer
approximation, and the residue operator \<open>z mod\<lbrakk>f\<rbrakk> N\<close>, which generalises both the unsigned
(\<open>mod\<^sup>+\<close>) and signed (\<open>mod\<^sup>\<plusminus>\<close>) representatives modulo \<open>N\<close>.
We write \<open>_\<^sub>\<rat>\<close> for the embedding \<open>\<int> \<rightarrow> \<rat>\<close> and \<open>_/\<^sub>\<rat>_\<close> for the rational quotient of two integers.
\<close>

notation rat_of_int ("_\<^sub>\<rat>" [1000] 999)
notation %invisible real_of_rat ("_\<^sub>\<real>" [1000] 999)
abbreviation quot_of_int (infixl "'/\<^sub>\<rat>" 70) where "x /\<^sub>\<rat> y \<equiv> x\<^sub>\<rat> / y\<^sub>\<rat>"

section \<open>Integer approximations\<close>

text \<open>
Following \cite[\S2.4]{NeonNTT}, \<open>is_int_approx \<lbrakk>_\<rbrakk>\<close> requires only that
\<open>\<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> 1\<close> — not the stronger \<open>\<lbrakk>z\<rbrakk> = z\<close> on integer inputs, which the
even-rounding function \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close> fails.
\<close>

definition \<open>is_int_approx f \<longleftrightarrow> (\<forall>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> 1)\<close> for f ("\<lbrakk>_\<rbrakk>")

text \<open>
Standard instances of integer approximations are round-to-nearest \<open>\<lfloor>\<cdot>\<rceil>\<close>,
round-half-down \<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close>, floor \<open>\<lfloor>\<cdot>\<rfloor>\<close>, and ceiling \<open>\<lceil>\<cdot>\<rceil>\<close>. Less canonically, the following is an integer
approximation as well:
\<close>

notation %internal round (\<open>\<lfloor>_\<rceil>\<close>)
definition round_half_down :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lfloor>_\<rceil>\<^sub>\<down>\<close>) where
  \<open>round_half_down x = - round (-x)\<close>
definition round_even (\<open>\<lfloor>_\<rceil>\<^sub>2\<close>) where \<open>\<lfloor>z\<rceil>\<^sub>2 \<equiv> 2 * \<lfloor>z/2\<rceil>\<close>

lemma %internal round_eq_iff:
  shows \<open>round x = y \<longleftrightarrow> (-1/2 \<le> x - rat_of_int y \<and> x - rat_of_int y < 1/2)\<close>
  by (metis add.commute diff_le_eq diff_less_eq minus_diff_eq minus_divide_left minus_le_iff
    of_int_round_gt of_int_round_le round_unique)

lemma %internal round_half_down_eq_iff:
  shows \<open>\<lfloor>x\<rceil>\<^sub>\<down> = y \<longleftrightarrow> (-1/2 < x - rat_of_int y \<and> x - rat_of_int y \<le> 1/2)\<close>
proof -
  have \<dagger>: \<open>\<And>x y. - round x = y \<longleftrightarrow> round x = -y\<close> by auto
  show ?thesis unfolding round_half_down_def by (auto simp add: round_eq_iff \<dagger>)
qed

text %internal \<open>We also register notation for the unapplied forms of the approximation operators.
Unfortunately we have to drop down to a print AST translation here: If we introduced the new syntax
as an output notation, it would apply regardless of whether an argument is supplied or not, and lead
to e.g. \<^verbatim>\<open>floor x\<close> being printed as \<^verbatim>\<open>\<lfloor>\<cdot>\<rfloor> x\<close> instead of the desired \<open>\<lfloor>z\<rfloor>\<close>. With a print-AST-translation,
we can restrict the translation to unapplied occurrences.\<close>

notation %internal (input) round           (\<open>\<lfloor>\<cdot>\<rceil>\<close>)
notation %internal (input) round_half_down (\<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close>)
notation %internal (input) round_even      (\<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>)
notation %internal (input) floor           (\<open>\<lfloor>\<cdot>\<rfloor>\<close>)
notation %internal (input) ceiling         (\<open>\<lceil>\<cdot>\<rceil>\<close>)

syntax %internal "_round_dot"           :: "'a" (\<open>\<lfloor>\<cdot>\<rceil>\<close>)
syntax %internal "_round_half_down_dot" :: "'a" (\<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close>)
syntax %internal "_round_even_dot"      :: "'a" (\<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>)
syntax %internal "_floor_dot"           :: "'a" (\<open>\<lfloor>\<cdot>\<rfloor>\<close>)
syntax %internal "_ceiling_dot"         :: "'a" (\<open>\<lceil>\<cdot>\<rceil>\<close>)
print_ast_translation %internal \<open>
   let
    fun unapplied c _ [] = Ast.Constant c
      | unapplied _ _ _ = raise Match
  in
    [(\<^const_syntax>\<open>round\<close>,           unapplied \<^syntax_const>\<open>_round_dot\<close>),
     (\<^const_syntax>\<open>round_half_down\<close>, unapplied \<^syntax_const>\<open>_round_half_down_dot\<close>),
     (\<^const_syntax>\<open>round_even\<close>,      unapplied \<^syntax_const>\<open>_round_even_dot\<close>),
     (\<^const_syntax>\<open>floor\<close>,           unapplied \<^syntax_const>\<open>_floor_dot\<close>),
     (\<^const_syntax>\<open>ceiling\<close>,         unapplied \<^syntax_const>\<open>_ceiling_dot\<close>)]
  end
\<close>

text\<open>We quickly confirm that \<^term>\<open>\<lfloor>\<cdot>\<rceil>\<close> is round-half-up and \<^term>\<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close> is round-half-down:\<close>

lemma %visible shows \<open>\<lfloor>1 /\<^sub>\<rat> 2\<rceil>\<^sub>\<down> = 0\<close> and \<open>\<lfloor>1 /\<^sub>\<rat> 2\<rceil> = 1\<close> by eval+

text \<open>We also confirm that indeed all of the above are integer approximations:\<close>

theorem is_int_approx_instances:
  shows is_int_approx_floor:           \<open>is_int_approx \<lfloor>\<cdot>\<rfloor>\<close>
    and is_int_approx_ceiling:         \<open>is_int_approx \<lceil>\<cdot>\<rceil>\<close>
    and is_int_approx_round:           \<open>is_int_approx \<lfloor>\<cdot>\<rceil>\<close>
    and is_int_approx_round_half_down: \<open>is_int_approx \<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close>
    and is_int_approx_round_even:      \<open>is_int_approx \<lfloor>\<cdot>\<rceil>\<^sub>2\<close>
  unfolding is_int_approx_def round_even_def round_half_down_def round_def by (linarith+)

text %internal \<open>Specialised to a rational \<^term>\<open>z /\<^sub>\<rat> N\<close> with \<^term>\<open>N > 0\<close> and cleared of
denominators, the round-half-down characterisation pins the quotient by an
integer window on the residue \<^term>\<open>z - N * q\<close>: the half-open interval
\<open>(-N/2, N/2]\<close>.\<close>

lemma %internal round_half_down_window:
  fixes N z q :: int
  assumes Npos: \<open>N > 0\<close>
  shows \<open>\<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<down> = q \<longleftrightarrow> - N < 2 * (z - N * q) \<and> 2 * (z - N * q) \<le> N\<close>
proof -
  have Nr: \<open>(rat_of_int N) > 0\<close> using Npos by simp
  have step: \<open>(\<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<down> = q) = (- (1/2) < z /\<^sub>\<rat> N - rat_of_int q \<and> z /\<^sub>\<rat> N - rat_of_int q \<le> 1/2)\<close>
    using round_half_down_eq_iff[of \<open>z /\<^sub>\<rat> N\<close> q] by simp
  have A: \<open>(- (1/2) < z /\<^sub>\<rat> N - rat_of_int q) = (- N < 2 * (z - N * q))\<close>
  proof -
    have \<open>(- (1/2) < z /\<^sub>\<rat> N - rat_of_int q) = (rat_of_int (- N) < rat_of_int (2 * (z - N * q)))\<close>
      using Nr by (simp add: of_int_mult field_simps)
    thus ?thesis by (simp only: of_int_less_iff)
  qed
  have B: \<open>(z /\<^sub>\<rat> N - rat_of_int q \<le> 1/2) = (2 * (z - N * q) \<le> N)\<close>
  proof -
    have \<open>(z /\<^sub>\<rat> N - rat_of_int q \<le> 1/2) = (rat_of_int (2 * (z - N * q)) \<le> rat_of_int N)\<close>
      using Nr by (simp add: of_int_mult field_simps)
    thus ?thesis by (simp only: of_int_le_iff)
  qed
  show ?thesis using step A B by blast
qed


section \<open>Approximation quality\<close>

text \<open>
The predicate \<open>is_int_approx \<lbrakk>_\<rbrakk>\<close> only requires the rounding error \<open>\<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar>\<close> to be
bounded by \<^term>\<open>1\<close>. Different approximations enjoy tighter uniform bounds: \<open>\<lfloor>\<cdot>\<rceil>\<close> and
\<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down>\<close> never err by more than \<^term>\<open>1/2\<close>, while \<open>\<lfloor>\<cdot>\<rfloor>\<close>, \<open>\<lceil>\<cdot>\<rceil>\<close>, and \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2\<close>
can come arbitrarily close to \<^term>\<open>1\<close>. We capture this as the
\emph{approximation quality} \<open>\<epsilon>(\<lbrakk>_\<rbrakk>)\<close>, the smallest rational bound on
\<open>\<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar>\<close>.

In general, the supremum of the rounding error need not be a rational number
(see \S\ref{sec:golden} for a concrete example), so we characterise
\<open>\<epsilon>(\<lbrakk>_\<rbrakk>)\<close> as the unique value (when one exists) that is both a uniform upper
bound and least among all upper bounds; this is captured by the predicate
\<open>is_int_approx_quality\<close>.
\<close>

definition int_approx_quality (\<open>\<epsilon> '(_')\<close>) where
  \<open>\<epsilon>(f) \<equiv> SOME e. (\<forall>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e) \<and>
                    (\<forall>e'. (\<forall>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e') \<longrightarrow> e \<le> e')\<close> for f ("\<lbrakk>_\<rbrakk>")

definition %internal is_int_approx_quality :: \<open>(rat \<Rightarrow> int) \<Rightarrow> rat \<Rightarrow> bool\<close> where
  \<open>is_int_approx_quality f e \<longleftrightarrow> (\<forall>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e) \<and>
                                 (\<forall>e'. (\<forall>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e') \<longrightarrow> e \<le> e')\<close> for f ("\<lbrakk>_\<rbrakk>")

text %internal \<open>
Any two qualities for the same \<open>\<lbrakk>_\<rbrakk>\<close> agree, so \<open>is_int_approx_quality \<lbrakk>_\<rbrakk>\<close> is a singleton
predicate; \<open>\<epsilon>(\<lbrakk>_\<rbrakk>)\<close> picks out its unique witness whenever one exists.
\<close>

lemma %internal is_int_approx_quality_unique:
  assumes \<open>is_int_approx_quality f e1\<close> and \<open>is_int_approx_quality f e2\<close>
  shows \<open>e1 = e2\<close>
  using assms unfolding is_int_approx_quality_def by (meson order_antisym)

lemma %internal int_approx_quality_eq:
  assumes \<open>is_int_approx_quality f e\<close>
  shows \<open>\<epsilon>(f) = e\<close>
  unfolding int_approx_quality_def
  by (rule someI2[where Q=\<open>\<lambda>x. x = e\<close>],
      use assms in \<open>simp add: is_int_approx_quality_def\<close>,
      use assms in \<open>simp add: is_int_approx_quality_unique[OF _ assms] is_int_approx_quality_def\<close>)

lemma %internal quality_charI:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>) and e :: rat
  assumes ub: \<open>\<And>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e\<close>
      and tight: \<open>\<And>e'. (\<And>z. \<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> e') \<Longrightarrow> e \<le> e'\<close>
  shows \<open>is_int_approx_quality f e\<close>
  using assms unfolding is_int_approx_quality_def by blast

text %internal \<open>
Whenever a quality witness exists, it provides the defining uniform bound and is itself
bounded by \<open>1\<close> for any integer approximation.
\<close>

lemma %internal quality_bounds:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>is_int_approx_quality f e\<close>
  shows \<open>\<bar>z - \<lbrakk>z\<rbrakk>\<^sub>\<rat>\<bar> \<le> \<epsilon>(f)\<close>
  using assms int_approx_quality_eq[OF assms]
  unfolding is_int_approx_quality_def by simp

lemma %internal quality_le_one:
  assumes \<open>is_int_approx f\<close> and \<open>is_int_approx_quality f e\<close>
  shows \<open>\<epsilon>(f) \<le> 1\<close>
proof -
  have \<open>e \<le> 1\<close>
    using assms unfolding is_int_approx_def is_int_approx_quality_def by blast
  thus ?thesis using int_approx_quality_eq[OF assms(2)] by simp
qed

text \<open>The uniform quality \<open>\<epsilon>(f)\<close> dominates the actual rounding error
\<open>|x - \<lbrakk>x\<rbrakk>\<^sub>\<rat>|\<close> at every input \<open>x\<close>. We name the latter \<open>\<epsilon>(f, x)\<close>;
the relation \<open>\<epsilon>(f, x) \<le> \<epsilon>(f)\<close> is immediate.\<close>

abbreviation int_approx_quality_at :: \<open>(rat \<Rightarrow> int) \<Rightarrow> rat \<Rightarrow> rat\<close> (\<open>\<epsilon> '(_, _')\<close>)
  where \<open>\<epsilon>(f, x) \<equiv> \<bar>x - \<lbrakk>x\<rbrakk>\<^sub>\<rat>\<bar>\<close> for f ("\<lbrakk>_\<rbrakk>")

lemma %internal quality_at_le:
  assumes \<open>is_int_approx_quality f e\<close>
  shows \<open>\<epsilon>(f, x) \<le> \<epsilon>(f)\<close>
  using quality_bounds[OF assms] .

text \<open>
The five standard approximations admit explicit quality witnesses. Round-to-nearest
and round-half-down attain the ideal quality \<^term>\<open>1/2\<close>; the other three
only come arbitrarily close to \<^term>\<open>1\<close> but no rational below \<^term>\<open>1\<close> is a
uniform bound, so their quality is exactly \<^term>\<open>1\<close>.
\<close>

theorem %internal is_int_approx_quality_instances:
  shows is_int_approx_quality_round:           \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil> (1/2)\<close>
    and is_int_approx_quality_round_half_down: \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>\<down> (1/2)\<close>
    and is_int_approx_quality_floor:           \<open>is_int_approx_quality \<lfloor>\<cdot>\<rfloor> 1\<close>
    and is_int_approx_quality_ceiling:         \<open>is_int_approx_quality \<lceil>\<cdot>\<rceil> 1\<close>
    and is_int_approx_quality_round_even:      \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>2 1\<close>
proof -
  show \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil> (1/2)\<close>
  proof (rule quality_charI)
    fix z :: rat show \<open>\<bar>z - (\<lfloor>\<cdot>\<rceil> z)\<^sub>\<rat>\<bar> \<le> 1/2\<close> unfolding round_def by linarith
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rceil> z)\<^sub>\<rat>\<bar> \<le> e'\<close>
    have \<open>\<lfloor>\<cdot>\<rceil> (1/2 :: rat) = 1\<close> unfolding round_def by simp
    hence eq: \<open>\<bar>(1/2 :: rat) - (\<lfloor>\<cdot>\<rceil> (1/2 :: rat))\<^sub>\<rat>\<bar> = 1/2\<close> by simp
    show \<open>1/2 \<le> e'\<close> using H[of \<open>1/2\<close>] eq by simp
  qed
next
  show \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>\<down> (1/2)\<close>
  proof (rule quality_charI)
    fix z :: rat show \<open>\<bar>z - (\<lfloor>\<cdot>\<rceil>\<^sub>\<down> z)\<^sub>\<rat>\<bar> \<le> 1/2\<close>
      unfolding round_half_down_def round_def by linarith
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rceil>\<^sub>\<down> z)\<^sub>\<rat>\<bar> \<le> e'\<close>
    have \<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<down> (-1/2 :: rat) = -1\<close>
      unfolding round_half_down_def round_def by simp
    hence eq: \<open>\<bar>(-1/2 :: rat) - (\<lfloor>\<cdot>\<rceil>\<^sub>\<down> (-1/2 :: rat))\<^sub>\<rat>\<bar> = 1/2\<close> by simp
    show \<open>1/2 \<le> e'\<close> using H[of \<open>-1/2\<close>] eq by simp
  qed
next
  show \<open>is_int_approx_quality \<lfloor>\<cdot>\<rfloor> 1\<close>
  proof (rule quality_charI)
    fix z :: rat show \<open>\<bar>z - (\<lfloor>\<cdot>\<rfloor> z)\<^sub>\<rat>\<bar> \<le> 1\<close> by linarith
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rfloor> z)\<^sub>\<rat>\<bar> \<le> e'\<close>
    have e'_nn: \<open>e' \<ge> 0\<close> using H[of 0] by simp
    have key: \<open>\<forall>\<delta>::rat. 0 < \<delta> \<longrightarrow> \<delta> < 1 \<longrightarrow> 1 - \<delta> \<le> e'\<close>
    proof (intro allI impI)
      fix \<delta> :: rat assume \<delta>p: \<open>0 < \<delta>\<close> and \<delta>l: \<open>\<delta> < 1\<close>
      have flr: \<open>\<lfloor>\<cdot>\<rfloor> (-\<delta>) = -1\<close> using \<delta>p \<delta>l by linarith
      have \<open>\<bar>(-\<delta>) - (\<lfloor>\<cdot>\<rfloor> (-\<delta>))\<^sub>\<rat>\<bar> = 1 - \<delta>\<close> using \<delta>p \<delta>l flr by simp
      thus \<open>1 - \<delta> \<le> e'\<close> using H[of \<open>-\<delta>\<close>] by simp
    qed
    show \<open>1 \<le> e'\<close>
    proof (rule ccontr)
      assume \<open>\<not> 1 \<le> e'\<close>
      hence elt: \<open>e' < 1\<close> by simp
      define \<delta> where \<delta>_def: \<open>\<delta> = (1 - e') / 2\<close>
      have \<delta>p: \<open>0 < \<delta>\<close> unfolding \<delta>_def using elt by simp
      have eq: \<open>2 * \<delta> = 1 - e'\<close> unfolding \<delta>_def by simp
      hence \<delta>l: \<open>\<delta> < 1\<close> using elt e'_nn by linarith
      from key[rule_format, OF \<delta>p \<delta>l] have h1: \<open>1 - \<delta> \<le> e'\<close> .
      from eq have \<open>e' = 1 - 2*\<delta>\<close> by linarith
      with h1 \<delta>p show False by linarith
    qed
  qed
next
  show \<open>is_int_approx_quality \<lceil>\<cdot>\<rceil> 1\<close>
  proof (rule quality_charI)
    fix z :: rat show \<open>\<bar>z - (\<lceil>\<cdot>\<rceil> z)\<^sub>\<rat>\<bar> \<le> 1\<close> by linarith
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lceil>\<cdot>\<rceil> z)\<^sub>\<rat>\<bar> \<le> e'\<close>
    have e'_nn: \<open>e' \<ge> 0\<close> using H[of 0] by simp
    have key: \<open>\<forall>\<delta>::rat. 0 < \<delta> \<longrightarrow> \<delta> < 1 \<longrightarrow> 1 - \<delta> \<le> e'\<close>
    proof (intro allI impI)
      fix \<delta> :: rat assume \<delta>p: \<open>0 < \<delta>\<close> and \<delta>l: \<open>\<delta> < 1\<close>
      have ce: \<open>\<lceil>\<cdot>\<rceil> \<delta> = 1\<close> using \<delta>p \<delta>l by linarith
      have \<open>\<bar>\<delta> - (\<lceil>\<cdot>\<rceil> \<delta>)\<^sub>\<rat>\<bar> = 1 - \<delta>\<close> using \<delta>p \<delta>l ce by simp
      thus \<open>1 - \<delta> \<le> e'\<close> using H[of \<delta>] by simp
    qed
    show \<open>1 \<le> e'\<close>
    proof (rule ccontr)
      assume \<open>\<not> 1 \<le> e'\<close>
      hence elt: \<open>e' < 1\<close> by simp
      define \<delta> where \<delta>_def: \<open>\<delta> = (1 - e') / 2\<close>
      have \<delta>p: \<open>0 < \<delta>\<close> unfolding \<delta>_def using elt by simp
      have eq: \<open>2 * \<delta> = 1 - e'\<close> unfolding \<delta>_def by simp
      hence \<delta>l: \<open>\<delta> < 1\<close> using elt e'_nn by linarith
      from key[rule_format, OF \<delta>p \<delta>l] have h1: \<open>1 - \<delta> \<le> e'\<close> .
      from eq have \<open>e' = 1 - 2*\<delta>\<close> by linarith
      with h1 \<delta>p show False by linarith
    qed
  qed
next
  show \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>2 1\<close>
  proof (rule quality_charI)
    fix z :: rat show \<open>\<bar>z - (\<lfloor>\<cdot>\<rceil>\<^sub>2 z)\<^sub>\<rat>\<bar> \<le> 1\<close>
      unfolding round_even_def round_def by linarith
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rceil>\<^sub>2 z)\<^sub>\<rat>\<bar> \<le> e'\<close>
    have e'_nn: \<open>e' \<ge> 0\<close> using H[of 0] by simp
    have key: \<open>\<forall>\<delta>::rat. 0 < \<delta> \<longrightarrow> \<delta> < 1 \<longrightarrow> 1 - \<delta> \<le> e'\<close>
    proof (intro allI impI)
      fix \<delta> :: rat assume \<delta>p: \<open>0 < \<delta>\<close> and \<delta>l: \<open>\<delta> < 1\<close>
      let ?z = \<open>1 - \<delta> :: rat\<close>
      have aux: \<open>?z / 2 + 1/2 = 1 - \<delta>/2\<close> by (simp add: field_simps)
      have rng_lo: \<open>(0::rat) \<le> 1 - \<delta>/2\<close> using \<delta>l by simp
      have rng_hi: \<open>(1 - \<delta>/2 :: rat) < 1\<close> using \<delta>p by simp
      have flr0: \<open>\<lfloor>1 - \<delta>/2 :: rat\<rfloor> = 0\<close>
        using rng_lo rng_hi floor_unique[of 0 \<open>1 - \<delta>/2\<close>] by simp
      have \<open>\<lfloor>?z / 2 + 1/2\<rfloor> = 0\<close> using aux flr0 by simp
      hence \<open>\<lfloor>\<cdot>\<rceil> (?z / 2) = 0\<close> unfolding round_def by simp
      hence re: \<open>\<lfloor>\<cdot>\<rceil>\<^sub>2 ?z = 0\<close> unfolding round_even_def by simp
      have \<open>\<bar>?z - (\<lfloor>\<cdot>\<rceil>\<^sub>2 ?z)\<^sub>\<rat>\<bar> = 1 - \<delta>\<close> using \<delta>p \<delta>l re by simp
      thus \<open>1 - \<delta> \<le> e'\<close> using H[of ?z] by simp
    qed
    show \<open>1 \<le> e'\<close>
    proof (rule ccontr)
      assume \<open>\<not> 1 \<le> e'\<close>
      hence elt: \<open>e' < 1\<close> by simp
      define \<delta> where \<delta>_def: \<open>\<delta> = (1 - e') / 2\<close>
      have \<delta>p: \<open>0 < \<delta>\<close> unfolding \<delta>_def using elt by simp
      have eq: \<open>2 * \<delta> = 1 - e'\<close> unfolding \<delta>_def by simp
      hence \<delta>l: \<open>\<delta> < 1\<close> using elt e'_nn by linarith
      from key[rule_format, OF \<delta>p \<delta>l] have h1: \<open>1 - \<delta> \<le> e'\<close> .
      from eq have \<open>e' = 1 - 2*\<delta>\<close> by linarith
      with h1 \<delta>p show False by linarith
    qed
  qed
qed

corollary int_approx_quality_instances:
  shows quality_round:           \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>) = 1/2\<close>
    and quality_round_half_down: \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>) = 1/2\<close>
    and quality_floor:           \<open>\<epsilon>(\<lfloor>\<cdot>\<rfloor>) = 1\<close>
    and quality_ceiling:         \<open>\<epsilon>(\<lceil>\<cdot>\<rceil>) = 1\<close>
    and quality_round_even:      \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2) = 1\<close>
  using int_approx_quality_eq[OF is_int_approx_quality_instances(1)]
        int_approx_quality_eq[OF is_int_approx_quality_instances(2)]
        int_approx_quality_eq[OF is_int_approx_quality_instances(3)]
        int_approx_quality_eq[OF is_int_approx_quality_instances(4)]
        int_approx_quality_eq[OF is_int_approx_quality_instances(5)]
  by simp_all

text \<open>For each of the five standard approximations, the worst-case error
\<^term>\<open>\<epsilon>(f)\<close> is attained only at the supremum locus: for \<^term>\<open>round\<close> and
\<^term>\<open>round_half_down\<close> at half-integers, and approached but never attained
for \<^term>\<open>floor\<close>, \<^term>\<open>ceiling\<close>, \<^term>\<open>round_even\<close> at integers.
Outside these loci the pointwise error is strictly smaller. Note: for
\<^term>\<open>floor\<close> and \<^term>\<open>ceiling\<close> the strict inequality holds
unconditionally — the residue \<open>x - of_int (floor x)\<close> always lies in \<open>[0, 1)\<close>,
so no precondition is needed.\<close>

lemma quality_at_strict:
  shows quality_at_strict_round:           \<open>2 * x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>)\<close>
    and quality_at_strict_round_half_down: \<open>2 * x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>)\<close>
    and quality_at_strict_round_even:      \<open>x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2)\<close>
    and quality_at_strict_floor:           \<open>\<epsilon>(\<lfloor>\<cdot>\<rfloor>, x) < \<epsilon>(\<lfloor>\<cdot>\<rfloor>)\<close>
    and quality_at_strict_ceiling:         \<open>\<epsilon>(\<lceil>\<cdot>\<rceil>, x) < \<epsilon>(\<lceil>\<cdot>\<rceil>)\<close>
proof -
  show \<open>2 * x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>)\<close>
  proof -
    assume A: \<open>2 * x \<notin> \<int>\<close>
    have abs_le: \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rceil> x)\<bar> \<le> 1/2\<close>
      using of_int_round_abs_le by (simp add: abs_minus_commute)
    have \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rceil> x)\<bar> < 1/2\<close>
    proof (rule ccontr)
      assume \<open>\<not> \<bar>x - of_int (\<lfloor>\<cdot>\<rceil> x)\<bar> < 1/2\<close>
      hence eq: \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rceil> x)\<bar> = 1/2\<close> using abs_le by simp
      hence \<open>x - of_int (\<lfloor>\<cdot>\<rceil> x) = 1/2 \<or> x - of_int (\<lfloor>\<cdot>\<rceil> x) = -(1/2)\<close>
        by linarith
      hence \<open>2 * x = of_int (2 * \<lfloor>\<cdot>\<rceil> x + 1) \<or> 2 * x = of_int (2 * \<lfloor>\<cdot>\<rceil> x - 1)\<close>
        by (auto simp: algebra_simps)
      hence \<open>2 * x \<in> \<int>\<close> using Ints_of_int by metis
      thus False using A by simp
    qed
    thus \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>)\<close> using quality_round by simp
  qed
next
  show \<open>2 * x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>)\<close>
  proof -
    assume A: \<open>2 * x \<notin> \<int>\<close>
    have negA: \<open>2 * (- x) \<notin> \<int>\<close> using A by simp
    have abs_le: \<open>\<bar>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x))\<bar> \<le> 1/2\<close>
      using of_int_round_abs_le by (simp add: abs_minus_commute)
    have \<open>\<bar>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x))\<bar> < 1/2\<close>
    proof (rule ccontr)
      assume \<open>\<not> \<bar>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x))\<bar> < 1/2\<close>
      hence eq: \<open>\<bar>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x))\<bar> = 1/2\<close> using abs_le by simp
      hence \<open>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x)) = 1/2 \<or> (-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x)) = -(1/2)\<close>
        by linarith
      hence \<open>2 * (-x) = of_int (2 * \<lfloor>\<cdot>\<rceil> (-x) + 1) \<or> 2 * (-x) = of_int (2 * \<lfloor>\<cdot>\<rceil> (-x) - 1)\<close>
        by (auto simp: algebra_simps)
      hence \<open>2 * (-x) \<in> \<int>\<close> using Ints_of_int by metis
      thus False using negA by simp
    qed
    moreover have \<open>\<bar>(-x) - of_int (\<lfloor>\<cdot>\<rceil> (-x))\<bar> = \<bar>x - of_int (\<lfloor>\<cdot>\<rceil>\<^sub>\<down> x)\<bar>\<close>
      unfolding round_half_down_def by simp
    ultimately have \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rceil>\<^sub>\<down> x)\<bar> < 1/2\<close> by simp
    thus \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>\<down>)\<close> using quality_round_half_down by simp
  qed
next
  show \<open>x \<notin> \<int> \<Longrightarrow> \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2)\<close>
  proof -
    assume A: \<open>x \<notin> \<int>\<close>
    have re_expand: \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rceil>\<^sub>2 x)\<bar> = 2 * \<bar>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<bar>\<close>
    proof -
      have re_eq: \<open>of_int (\<lfloor>\<cdot>\<rceil>\<^sub>2 x) = (2::rat) * of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<close>
        unfolding round_even_def by simp
      have \<open>x - of_int (\<lfloor>\<cdot>\<rceil>\<^sub>2 x) = 2 * (x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2)))\<close>
        using re_eq by (simp add: algebra_simps)
      thus ?thesis by (metis abs_mult abs_numeral)
    qed
    have half_strict: \<open>\<bar>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<bar> < 1/2\<close>
    proof (rule ccontr)
      assume \<open>\<not> \<bar>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<bar> < 1/2\<close>
      moreover have \<open>\<bar>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<bar> \<le> 1/2\<close>
        using of_int_round_abs_le by (simp add: abs_minus_commute)
      ultimately have eq: \<open>\<bar>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2))\<bar> = 1/2\<close> by simp
      hence \<open>x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2)) = 1/2 \<or> x/2 - of_int (\<lfloor>\<cdot>\<rceil> (x/2)) = -(1/2)\<close>
        by linarith
      hence \<open>x = of_int (2 * \<lfloor>\<cdot>\<rceil> (x/2) + 1) \<or> x = of_int (2 * \<lfloor>\<cdot>\<rceil> (x/2) - 1)\<close>
        by (auto simp: algebra_simps)
      hence \<open>x \<in> \<int>\<close> using Ints_of_int by metis
      thus False using A by simp
    qed
    have \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) < 1\<close>
      using re_expand half_strict by simp
    thus \<open>\<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2, x) < \<epsilon>(\<lfloor>\<cdot>\<rceil>\<^sub>2)\<close> using quality_round_even by simp
  qed
next
  show \<open>\<epsilon>(\<lfloor>\<cdot>\<rfloor>, x) < \<epsilon>(\<lfloor>\<cdot>\<rfloor>)\<close>
  proof -
    have \<open>\<bar>x - of_int (\<lfloor>\<cdot>\<rfloor> x)\<bar> < 1\<close>
      by linarith
    thus ?thesis using quality_floor by simp
  qed
next
  show \<open>\<epsilon>(\<lceil>\<cdot>\<rceil>, x) < \<epsilon>(\<lceil>\<cdot>\<rceil>)\<close>
  proof -
    have \<open>\<bar>x - of_int (\<lceil>\<cdot>\<rceil> x)\<bar> < 1\<close>
      by linarith
    thus ?thesis using quality_ceiling by simp
  qed
qed

text \<open>
Fun fact: For every \<open>\<delta> \<in> [0, 1/2]\<close>, the offset rounding \<open>z \<mapsto> round(z + \<delta>)\<close> is an
integer approximation of quality \<^term>\<open>1/2 + \<delta>\<close>. Setting \<^term>\<open>\<delta> = 0\<close> recovers \<^term>\<open>round\<close>;
\<^term>\<open>\<delta> = 1/2\<close> gives \<^term>\<open>floor\<close> (up to a half-integer shift). The map \<open>\<delta> \<mapsto> \<epsilon>(\<dots>)\<close>
is therefore a bijection \<open>[0, 1/2] \<rightarrow> [1/2, 1]\<close>, witnessing that the
quality range is fully achieved.
\<close>

lemma int_approx_quality_offset_round:
  assumes \<open>0 \<le> \<delta>\<close> and \<open>\<delta> \<le> 1/2\<close>
  shows \<open>is_int_approx (\<lambda>z. \<lfloor>\<cdot>\<rceil> (z + \<delta>))\<close>
    and \<open>\<epsilon>(\<lambda>z. \<lfloor>\<cdot>\<rceil> (z + \<delta>)) = 1/2 + \<delta>\<close>
proof -
  have ub: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rceil> (z + \<delta>))\<^sub>\<rat>\<bar> \<le> 1/2 + \<delta>\<close>
  proof -
    fix z :: rat
    have h1: \<open>\<bar>(z + \<delta>) - (\<lfloor>\<cdot>\<rceil> (z + \<delta>))\<^sub>\<rat>\<bar> \<le> 1/2\<close>
      unfolding round_def by linarith
    show \<open>\<bar>z - (\<lfloor>\<cdot>\<rceil> (z + \<delta>))\<^sub>\<rat>\<bar> \<le> 1/2 + \<delta>\<close>
      using h1 assms(1) by linarith
  qed
  show \<open>is_int_approx (\<lambda>z. \<lfloor>\<cdot>\<rceil> (z + \<delta>))\<close>
    unfolding is_int_approx_def
  proof (intro allI)
    fix z :: rat
    show \<open>\<bar>z - \<lfloor>z + \<delta>\<rceil>\<^sub>\<rat>\<bar> \<le> 1\<close>
      using ub[of z] assms(2) by linarith
  qed
  text \<open>Tightness witness: \<^term>\<open>z = -\<delta> - 1/2\<close>.\<close>
  let ?z0 = \<open>- \<delta> - 1/2 :: rat\<close>
  have wit_inner: \<open>?z0 + \<delta> = -1/2\<close> by simp
  have round_neg_half: \<open>\<lfloor>\<cdot>\<rceil> (-1/2 :: rat) = 0\<close>
    unfolding round_def by simp
  have round_witness: \<open>\<lfloor>\<cdot>\<rceil> (?z0 + \<delta>) = 0\<close>
    using wit_inner round_neg_half by simp
  have err_witness: \<open>\<bar>?z0 - (\<lfloor>\<cdot>\<rceil> (?z0 + \<delta>))\<^sub>\<rat>\<bar> = 1/2 + \<delta>\<close>
    using round_witness assms(1) by simp
  have qual: \<open>is_int_approx_quality (\<lambda>z. \<lfloor>\<cdot>\<rceil> (z + \<delta>)) (1/2 + \<delta>)\<close>
  proof (rule quality_charI)
    fix z :: rat
    show \<open>\<bar>z - (\<lfloor>\<cdot>\<rceil> (z + \<delta>))\<^sub>\<rat>\<bar> \<le> 1/2 + \<delta>\<close> using ub[of z] .
  next
    fix e' :: rat
    assume H: \<open>\<And>z. \<bar>z - (\<lfloor>\<cdot>\<rceil> (z + \<delta>))\<^sub>\<rat>\<bar> \<le> e'\<close>
    from H[of ?z0] err_witness show \<open>1/2 + \<delta> \<le> e'\<close> by simp
  qed
  show \<open>\<epsilon>(\<lambda>z. \<lfloor>\<cdot>\<rceil> (z + \<delta>)) = 1/2 + \<delta>\<close>
    using int_approx_quality_eq[OF qual] .
qed

subsection \<open>A non-standard example: the golden-ratio approximation \label{sec:golden}\<close>

text \<open>
This subsection is for illustration and is not essential for the remainder of
the development. We construct an integer approximation whose rounding threshold
is the irrational number \<open>(\<surd>5 - 1)/2\<close> (the golden ratio minus one), proving that
no rational quality witness exists.
\<close>

text %internal \<open>
The following predicate uniquely determines an integer for every rational,
yielding the golden-ratio approximation. The two disjuncts correspond to the
cases where the integer lies below or above \<open>z\<close>.
\<close>

definition %internal golden_predicate :: "rat \<Rightarrow> int \<Rightarrow> bool" where
  "golden_predicate z n \<equiv>
     let r = z - of_int n in
     (r \<ge> 0 \<and> r*r + r < 1) \<or> (-1 < r \<and> r < 0 \<and> (r+1)*(r+1) + (r+1) \<ge> 1)"

lemma %internal golden_predicate_existence:
  "\<exists>n::int. golden_predicate z n"
proof -
  let ?n = "\<lfloor>z\<rfloor>"
  let ?r = "z - of_int ?n"
  have r_nn: "?r \<ge> 0" by linarith
  have r_lt1: "?r < 1" by linarith
  show ?thesis
  proof (cases "?r * ?r + ?r < 1")
    case True
    hence "golden_predicate z ?n"
      unfolding golden_predicate_def Let_def using r_nn by simp
    thus ?thesis by blast
  next
    case False
    hence ge1: "?r * ?r + ?r \<ge> 1" by simp
    let ?m = "\<lceil>z\<rceil>"
    let ?s = "z - of_int ?m"
    have s_le0: "?s \<le> 0" by linarith
    show ?thesis
    proof (cases "?s = 0")
      case True
      hence "z - of_int ?m = 0" by simp
      hence "golden_predicate z ?m"
        unfolding golden_predicate_def Let_def by simp
      thus ?thesis by blast
    next
      case False
      hence s_lt0: "?s < 0" using s_le0 by linarith
      have s_gt_neg1: "?s > -1" by linarith
      have m_eq: "?m = ?n + 1"
        using False s_le0 by linarith
      have ceq: "of_int (\<lceil>z\<rceil>) = of_int (\<lfloor>z\<rfloor>) + (1::rat)" using m_eq by simp
      have sp1_eq: "z - of_int (\<lceil>z\<rceil>) + 1 = z - of_int (\<lfloor>z\<rfloor>)"
        using ceq by linarith
      have key: "(z - of_int (\<lceil>z\<rceil>) + 1) * (z - of_int (\<lceil>z\<rceil>) + 1) + (z - of_int (\<lceil>z\<rceil>) + 1) \<ge> 1"
        using ge1 sp1_eq by metis
      hence "golden_predicate z ?m"
        unfolding golden_predicate_def Let_def using s_gt_neg1 s_lt0
        by linarith
      thus ?thesis by blast
    qed
  qed
qed

lemma %internal golden_predicate_uniqueness:
  assumes "golden_predicate z n1" and "golden_predicate z n2"
  shows "n1 = n2"
proof -
  define r1 where "r1 = z - of_int n1"
  define r2 where "r2 = z - of_int n2"
  have diff: "r1 - r2 = of_int (n2 - n1)" unfolding r1_def r2_def by simp
  from assms(1) have P1: "(r1 \<ge> 0 \<and> r1*r1 + r1 < 1) \<or> (-1 < r1 \<and> r1 < 0 \<and> (r1+1)*(r1+1) + (r1+1) \<ge> 1)"
    unfolding golden_predicate_def Let_def r1_def by simp
  from assms(2) have P2: "(r2 \<ge> 0 \<and> r2*r2 + r2 < 1) \<or> (-1 < r2 \<and> r2 < 0 \<and> (r2+1)*(r2+1) + (r2+1) \<ge> 1)"
    unfolding golden_predicate_def Let_def r2_def by simp
  have aux: "\<And>r::rat. r \<ge> 0 \<Longrightarrow> r*r + r < 1 \<Longrightarrow> r < 1"
  proof -
    fix r :: rat assume rnn: "r \<ge> 0" and rsq: "r*r + r < 1"
    have "r * (r + 1) < 1" using rsq by (simp add: algebra_simps)
    moreover have "r + 1 > 0" using rnn by linarith
    ultimately have "r < 1 / (r + 1)" using \<open>r + 1 > 0\<close>
      by (simp add: field_simps)
    also have "1 / (r + 1) \<le> 1" using rnn by (simp add: field_simps)
    finally show "r < 1" .
  qed
  have goal: "n2 - n1 = 0"
  proof (rule ccontr)
    assume neq: "n2 - n1 \<noteq> 0"
    show False
    proof (cases "r1 \<ge> 0 \<and> r1*r1 + r1 < 1")
      case True
      hence r1_nn: "r1 \<ge> 0" and r1_sq: "r1*r1 + r1 < 1" by auto
      have r1_lt1: "r1 < 1" using aux[OF r1_nn r1_sq] .
      show False
      proof (cases "r2 \<ge> 0 \<and> r2*r2 + r2 < 1")
        case True
        hence r2_nn: "r2 \<ge> 0" and r2_sq: "r2*r2 + r2 < 1" by auto
        have r2_lt1: "r2 < 1" using aux[OF r2_nn r2_sq] .
        have h: "\<bar>r1 - r2\<bar> < 1"
          using r1_nn r1_lt1 r2_nn r2_lt1 by linarith
        have "\<bar>of_int (n2 - n1) :: rat\<bar> < 1" using h diff by linarith
        hence "\<bar>n2 - n1\<bar> < 1" by (metis of_int_abs of_int_less_1_iff)
        thus False using neq by simp
      next
        case not_c2: False
        show False
        proof (cases "-1 < r2 \<and> r2 < 0 \<and> (r2+1)*(r2+1) + (r2+1) \<ge> 1")
          case True
          hence r2_neg: "r2 < 0" and r2_gt: "r2 > -1" and r2_ge: "(r2+1)*(r2+1) + (r2+1) \<ge> 1" by auto
          have d_eq: "of_int (n2 - n1) = r1 - r2" using diff by linarith
          have "r1 - r2 > 0" using r1_nn r2_neg by linarith
          moreover have "r1 - r2 < 2" using r1_lt1 r2_gt by linarith
          ultimately have "n2 - n1 = 1" using d_eq by linarith
          hence "r2 = r1 - 1" using diff by linarith
          hence eq: "r2 + 1 = r1" by simp
          have "(r2+1)*(r2+1) + (r2+1) = r1*r1 + r1"
            using eq by simp
          hence "r1*r1 + r1 \<ge> 1" using r2_ge by simp
          thus False using r1_sq by simp
        next
          case False
          thus False using P2 not_c2 by auto
        qed
      qed
    next
      case not_c1: False
      show False
      proof (cases "-1 < r1 \<and> r1 < 0 \<and> (r1+1)*(r1+1) + (r1+1) \<ge> 1")
        case True
        hence r1_neg: "r1 < 0" and r1_gt: "r1 > -1" and r1_ge: "(r1+1)*(r1+1) + (r1+1) \<ge> 1" by auto
        show False
        proof (cases "r2 \<ge> 0 \<and> r2*r2 + r2 < 1")
          case True
          hence r2_nn: "r2 \<ge> 0" and r2_sq: "r2*r2 + r2 < 1" by auto
          have r2_lt1: "r2 < 1" using aux[OF r2_nn r2_sq] .
          have d_eq: "of_int (n2 - n1) = r1 - r2" using diff by linarith
          have "r1 - r2 < 0" using r1_neg r2_nn by linarith
          moreover have "r1 - r2 > -2" using r1_gt r2_lt1 by linarith
          ultimately have "n2 - n1 = -1" using d_eq by linarith
          hence "r1 = r2 - 1" using diff by linarith
          hence eq: "r1 + 1 = r2" by simp
          have "(r1+1)*(r1+1) + (r1+1) = r2*r2 + r2"
            using eq by simp
          hence "r2*r2 + r2 \<ge> 1" using r1_ge by simp
          thus False using r2_sq by simp
        next
          case not_c2: False
          show False
          proof (cases "-1 < r2 \<and> r2 < 0 \<and> (r2+1)*(r2+1) + (r2+1) \<ge> 1")
            case True
            hence r2_neg: "r2 < 0" and r2_gt: "r2 > -1" by auto
            have h: "\<bar>r1 - r2\<bar> < 1"
              using r1_neg r1_gt r2_neg r2_gt by linarith
            have "\<bar>of_int (n2 - n1) :: rat\<bar> < 1" using h diff by linarith
            hence "\<bar>n2 - n1\<bar> < 1" by (metis of_int_abs of_int_less_1_iff)
            thus False using neq by simp
          next
            case False
            thus False using P2 not_c2 by auto
          qed
        qed
      next
        case False
        thus False using P1 not_c1 by auto
      qed
    qed
  qed
  thus ?thesis by simp
qed

lemma %internal golden_predicate_approx:
  assumes "golden_predicate z n"
  shows "\<bar>z - of_int n\<bar> \<le> 1"
proof -
  define r where "r = z - of_int n"
  from assms have P: "(r \<ge> 0 \<and> r*r + r < 1) \<or> (-1 < r \<and> r < 0 \<and> (r+1)*(r+1) + (r+1) \<ge> 1)"
    unfolding golden_predicate_def Let_def r_def by simp
  have "\<bar>r\<bar> \<le> 1"
  proof (cases "r \<ge> 0 \<and> r*r + r < 1")
    case True
    hence "r \<ge> 0" and "r*r + r < 1" by auto
    hence "r < 1"
    proof -
      have "r * (r + 1) < 1" using \<open>r*r + r < 1\<close> by (simp add: algebra_simps)
      moreover have "r + 1 > 0" using \<open>r \<ge> 0\<close> by linarith
      ultimately have "r < 1 / (r + 1)" by (simp add: field_simps)
      also have "... \<le> 1" using \<open>r \<ge> 0\<close> by (simp add: field_simps)
      finally show ?thesis .
    qed
    thus ?thesis using \<open>r \<ge> 0\<close> by linarith
  next
    case False
    hence "-1 < r \<and> r < 0" using P by auto
    thus ?thesis by linarith
  qed
  thus ?thesis unfolding r_def .
qed

text %internal \<open>
The golden predicate uniquely determines an integer approximation whose worst-case
rounding error is the irrational number \<open>(\<surd>5 - 1)/2\<close>. This makes it an example
of an integer approximation that admits no rational quality witness.
\<close>

definition golden_approx (\<open>\<lfloor>_\<rceil>\<^sub>\<phi>\<close>) where
  "\<lfloor>z\<rceil>\<^sub>\<phi> = (THE n. let r = z - n\<^sub>\<rat> in
     (r \<ge> 0 \<and> r*r + r < 1) \<or> (-1 < r \<and> r < 0 \<and> (r+1)*(r+1) + (r+1) \<ge> 1))"

notation %invisible golden_approx (\<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<phi>\<close>)

lemma %internal golden_approx_alt: "\<lfloor>z\<rceil>\<^sub>\<phi> = (THE n. golden_predicate z n)"
  unfolding golden_approx_def golden_predicate_def ..

lemma %internal golden_approx_predicate: "golden_predicate z \<lfloor>z\<rceil>\<^sub>\<phi>"
proof -
  have ex1: "\<exists>!n. golden_predicate z n"
    using golden_predicate_existence golden_predicate_uniqueness by blast
  show ?thesis unfolding golden_approx_alt[of z] using theI'[OF ex1] .
qed

text \<open>The golden approximation is indeed an integer approximation:\<close>

theorem is_int_approx_golden: "is_int_approx \<lfloor>\<cdot>\<rceil>\<^sub>\<phi>"
  unfolding is_int_approx_def
  using golden_predicate_approx[OF golden_approx_predicate] by simp

paragraph %internal \<open>Real quality\<close>

text %internal \<open>We introduce a real-valued analogue of the approximation quality:\<close>

definition %internal real_quality_pred where \<open>real_quality_pred f q \<equiv>
  (\<forall>z. \<bar>z\<^sub>\<real> - real_of_int (f z)\<bar> \<le> q) \<and>
  (\<forall>q'. (\<forall>z. \<bar>z\<^sub>\<real> - real_of_int (f z)\<bar> \<le> q') \<longrightarrow> q \<le> q')\<close>

definition %internal real_quality (\<open>\<epsilon>\<^sub>\<real> '(_')\<close>) where \<open>\<epsilon>\<^sub>\<real>(f) \<equiv>
  SOME q. real_quality_pred f q\<close>

lemma %internal real_quality_pred_unique:
  assumes \<open>real_quality_pred f q1\<close> and \<open>real_quality_pred f q2\<close>
  shows \<open>q1 = q2\<close>
  using assms unfolding real_quality_pred_def by (meson order_antisym)

lemma %internal real_quality_eq:
  assumes \<open>real_quality_pred f q\<close>
  shows \<open>\<epsilon>\<^sub>\<real>(f) = q\<close>
  unfolding real_quality_def
  by (rule someI2[of _ q])
     (use assms real_quality_pred_unique in auto)

notation %invisible sqrt ("\<surd>")

text %internal \<open>Auxiliary facts about \<open>\<surd>5\<close>.\<close>

lemma %internal sqrt5_gt_2: "sqrt 5 > (2::real)"
proof -
  have "(2::real)^2 = 4" by simp
  also have "(4::real) < 5" by simp
  finally have "(2::real)^2 < 5" .
  moreover have "(0::real) \<le> 2" by simp
  ultimately show ?thesis using real_less_rsqrt by blast
qed

lemma %internal sqrt5_pos: "sqrt 5 > (0::real)"
  using sqrt5_gt_2 by linarith

lemma %internal sqrt5_squared: "(sqrt 5)^2 = (5::real)"
  by simp

lemma %internal sqrt5_lt_3: "sqrt 5 < (3::real)"
proof -
  have "sqrt 5 \<le> sqrt 9" by (intro real_sqrt_le_mono) simp
  have sqrt9: "sqrt 9 = (3::real)" by (rule real_sqrt_unique) auto
  have "sqrt 5 \<noteq> 3"
  proof
    assume "sqrt 5 = 3"
    hence "(sqrt 5)^2 = 9" by simp
    hence "(5::real) = 9" using sqrt5_squared by simp
    thus False by simp
  qed
  show ?thesis using \<open>sqrt 5 \<le> sqrt 9\<close> sqrt9 \<open>sqrt 5 \<noteq> 3\<close> by linarith
qed

lemma %internal phi_pos: "(sqrt 5 - 1) / 2 > (0::real)"
  using sqrt5_gt_2 by simp

lemma %internal phi_lt_1: "(sqrt 5 - 1) / 2 < (1::real)"
  using sqrt5_lt_3 by simp

lemma %internal phi_quadratic: "((sqrt 5 - 1)/2) * ((sqrt 5 - 1)/2) + (sqrt 5 - 1)/2 = (1::real)"
proof -
  have "((sqrt 5 - 1)/2) * ((sqrt 5 - 1)/2) = ((sqrt 5)^2 - 2*sqrt 5 + 1) / 4"
    by (simp add: power2_eq_square algebra_simps)
  also have "\<dots> = (6 - 2*sqrt 5) / 4" using sqrt5_squared by simp
  finally show ?thesis by (simp add: field_simps)
qed

text %internal \<open>
The threshold \<open>r\<^sup>2 + r < 1\<close> for \<open>r \<ge> 0\<close> is equivalent to \<open>r < (\<surd>5 - 1)/2\<close>.
\<close>

lemma %internal golden_threshold:
  fixes r :: real
  assumes "r \<ge> 0" and "r*r + r < 1"
  shows "r < (sqrt 5 - 1) / 2"
proof (rule ccontr)
  assume "\<not> r < (sqrt 5 - 1) / 2"
  hence h: "r \<ge> (sqrt 5 - 1) / 2" by simp
  have step: "r * r + r \<ge> ((sqrt 5 - 1) / 2) * ((sqrt 5 - 1) / 2) + (sqrt 5 - 1) / 2"
    using h assms(1) by (intro add_mono mult_mono) auto
  have "r * r + r \<ge> 1" using step phi_quadratic by simp
  thus False using assms(2) by linarith
qed

lemma %internal golden_complement_bound: "(3 - sqrt 5) / 2 \<le> (sqrt 5 - 1) / (2::real)"
proof -
  have "3 - sqrt 5 \<le> sqrt 5 - 1" using sqrt5_gt_2 by linarith
  thus ?thesis by (simp add: divide_right_mono)
qed

text %internal \<open>The error structure of @{const golden_approx} (i.e.\ @{term \<open>\<lfloor>\<cdot>\<rceil>\<^sub>\<phi>\<close>}).\<close>

lemma %internal golden_error_bound_rat:
  fixes z :: rat
  defines "r \<equiv> z - of_int \<lfloor>z\<rceil>\<^sub>\<phi>"
  shows "(r \<ge> 0 \<and> r*r + r < 1) \<or> (r < 0 \<and> r > -1 \<and> (r+1)*(r+1) + (r+1) \<ge> 1)"
proof -
  have gp: "golden_predicate z \<lfloor>z\<rceil>\<^sub>\<phi>" using golden_approx_predicate .
  show ?thesis unfolding r_def
    using gp unfolding golden_predicate_def Let_def by auto
qed

lemma %internal of_rat_abs_diff:
  "\<bar>real_of_rat z - real_of_int (f z)\<bar> = real_of_rat \<bar>z - (f z)\<^sub>\<rat>\<bar>"
proof -
  have h1: "real_of_rat ((f z)\<^sub>\<rat>) = real_of_int (f z)"
    by (simp add: of_rat_of_int_eq)
  have h2: "real_of_rat z - real_of_int (f z) = real_of_rat (z - (f z)\<^sub>\<rat>)"
    using h1 by (simp add: of_rat_diff)
  show ?thesis using h2 abs_of_rat[of "z - (f z)\<^sub>\<rat>"] by simp
qed

theorem %internal golden_upper_bound:
  "\<bar>real_of_rat z - real_of_int \<lfloor>z\<rceil>\<^sub>\<phi>\<bar> \<le> (sqrt 5 - 1) / 2"
proof -
  define r where "r = z - of_int \<lfloor>z\<rceil>\<^sub>\<phi>"
  define R where "R = real_of_rat r"
  have R_eq: "R = real_of_rat z - real_of_int \<lfloor>z\<rceil>\<^sub>\<phi>"
    unfolding R_def r_def by (simp add: of_rat_diff of_rat_of_int_eq)
  have cases: "(r \<ge> 0 \<and> r*r + r < 1) \<or> (r < 0 \<and> r > -1 \<and> (r+1)*(r+1) + (r+1) \<ge> 1)"
    using golden_error_bound_rat[of z, folded r_def] .
  show ?thesis
  proof (cases "r \<ge> 0 \<and> r*r + r < 1")
    case True
    hence rnn: "r \<ge> 0" and rsq: "r*r + r < 1" by auto
    have Rnn: "R \<ge> 0" unfolding R_def using rnn of_rat_less_eq[of 0 r] by simp
    have "R*R + R < 1"
    proof -
      have "real_of_rat (r*r + r) < real_of_rat 1" using rsq of_rat_less[of "r*r+r" 1] by simp
      thus ?thesis unfolding R_def by (simp add: of_rat_mult of_rat_add)
    qed
    hence "R < (sqrt 5 - 1) / 2" using golden_threshold[OF Rnn] by simp
    moreover have "\<bar>R\<bar> = R" using Rnn by simp
    ultimately show ?thesis using R_eq by simp
  next
    case False
    hence neg_case: "r < 0 \<and> r > -1 \<and> (r+1)*(r+1) + (r+1) \<ge> 1" using cases by auto
    hence rneg: "r < 0" and rgt: "r > -1" and rge: "(r+1)*(r+1) + (r+1) \<ge> 1" by auto
    have Rneg: "R < 0" unfolding R_def using rneg of_rat_less[of r 0] by simp
    have Rgt: "R > -1" unfolding R_def using rgt of_rat_less[of "-1" r] by simp
    have abs_eq: "\<bar>R\<bar> = -R" using Rneg by simp
    have Rge: "(R+1)*(R+1) + (R+1) \<ge> 1"
    proof -
      have "real_of_rat ((r+1)*(r+1) + (r+1)) \<ge> real_of_rat 1"
        using rge of_rat_less_eq[of 1 "(r+1)*(r+1) + (r+1)"] by simp
      thus ?thesis unfolding R_def by (simp add: of_rat_mult of_rat_add)
    qed
    have Rp1_nn: "R+1 \<ge> 0" using Rgt by linarith
    have negR_bound: "-R \<le> (sqrt 5 - 1) / 2"
    proof -
      have "(R+1) \<ge> (sqrt 5 - 1) / 2"
      proof (rule ccontr)
        assume "\<not> (R+1) \<ge> (sqrt 5 - 1) / 2"
        hence lt: "(R+1) < (sqrt 5 - 1) / 2" by simp
        have step: "(R+1)*(R+1) + (R+1) < ((sqrt 5 - 1)/2) * ((sqrt 5 - 1)/2) + (sqrt 5 - 1)/2"
          using Rp1_nn lt phi_pos by (intro add_less_le_mono mult_strict_mono') auto
        have "(R+1)*(R+1) + (R+1) < 1" using step phi_quadratic by simp
        thus False using Rge by linarith
      qed
      hence hR: "-R \<le> 1 - (sqrt 5 - 1) / 2" by linarith
      have "(sqrt 5 - 1) / 2 \<ge> 1 - (sqrt 5 - 1) / 2"
      proof -
        have "sqrt 5 - 1 \<ge> 1" using sqrt5_gt_2 by linarith
        thus ?thesis by (simp add: field_simps)
      qed
      thus ?thesis using hR by linarith
    qed
    show ?thesis using abs_eq negR_bound R_eq by simp
  qed
qed

theorem %internal golden_tightness:
  fixes q' :: real
  assumes ub: "\<forall>z. \<bar>real_of_rat z - real_of_int \<lfloor>z\<rceil>\<^sub>\<phi>\<bar> \<le> q'"
  shows "(sqrt 5 - 1) / 2 \<le> q'"
proof (rule ccontr)
  assume "\<not> (sqrt 5 - 1) / 2 \<le> q'"
  hence q'_lt: "q' < (sqrt 5 - 1) / 2" by simp
  have q'_nn: "q' \<ge> 0" using ub[rule_format, of 0] by simp
  obtain z :: rat where z_gt: "real_of_rat z > q'" and z_lt: "real_of_rat z < (sqrt 5 - 1) / 2"
    using of_rat_dense[OF q'_lt] by blast
  have z_pos: "z > 0"
  proof -
    have "real_of_rat z > 0" using z_gt q'_nn by linarith
    thus ?thesis using of_rat_less[of 0 z] by simp
  qed
  have z_lt1: "z < 1"
  proof -
    have "real_of_rat z < 1" using z_lt phi_lt_1 by linarith
    thus ?thesis using of_rat_less[of z 1] by simp
  qed
  have z_nn: "z \<ge> 0" using z_pos by linarith
  have zsq_lt: "z * z + z < 1"
  proof -
    define Z where "Z = real_of_rat z"
    have Znn: "Z \<ge> 0" unfolding Z_def using z_nn of_rat_less_eq[of 0 z] by simp
    have Zlt: "Z < (sqrt 5 - 1) / 2" using z_lt unfolding Z_def .
    have step: "Z * Z + Z < ((sqrt 5 - 1)/2)*((sqrt 5 - 1)/2) + (sqrt 5 - 1)/2"
      using Znn Zlt phi_pos by (intro add_less_le_mono mult_strict_mono') auto
    have "Z * Z + Z < 1" using step phi_quadratic by simp
    hence "real_of_rat (z * z + z) < real_of_rat 1"
      unfolding Z_def by (simp add: of_rat_mult of_rat_add)
    thus ?thesis using of_rat_less[of "z*z+z" 1] by simp
  qed
  have gp0: "golden_predicate z 0"
    unfolding golden_predicate_def Let_def using z_nn zsq_lt by simp
  have ga_eq: "\<lfloor>z\<rceil>\<^sub>\<phi> = 0"
    using golden_predicate_uniqueness[OF golden_approx_predicate gp0] by simp
  have err_eq: "\<bar>real_of_rat z - real_of_int \<lfloor>z\<rceil>\<^sub>\<phi>\<bar> = real_of_rat z"
  proof -
    have "real_of_rat z > 0" using z_gt q'_nn by linarith
    thus ?thesis using ga_eq by simp
  qed
  show False using ub[rule_format, of z] err_eq z_gt by linarith
qed

text \<open>Its real quality is the golden ratio minus one, where the real quality
\<open>\<epsilon>\<^sub>\<real>(f)\<close> is defined analogously to the rational quality \<open>\<epsilon>(f)\<close>.\<close>

theorem real_quality_golden: \<open>\<epsilon>\<^sub>\<real>(\<lfloor>\<cdot>\<rceil>\<^sub>\<phi>) = (\<surd>5 - 1) / 2\<close>
  by (rule real_quality_eq)
     (unfold real_quality_pred_def,
      use golden_upper_bound golden_tightness in blast)

paragraph %internal \<open>Irrationality and no rational quality\<close>

lemma %internal five_dvd_square: "(5::int) dvd n * n \<Longrightarrow> 5 dvd n"
proof -
  assume h: "5 dvd n * n"
  have "\<not> 5 dvd n \<Longrightarrow> False"
  proof -
    assume nd: "\<not> 5 dvd n"
    have "n mod 5 \<in> {1, 2, 3, 4}"
    proof -
      have "n mod 5 \<in> {0, 1, 2, 3, 4}" by auto
      moreover have "n mod 5 \<noteq> 0" using nd by auto
      ultimately show ?thesis by auto
    qed
    hence "(n mod 5) * (n mod 5) mod 5 \<in> {1, 4}"
      by auto
    hence "(n * n) mod 5 \<noteq> 0"
      by (metis mod_mult_eq insert_iff singletonD
          zero_neq_numeral numeral_eq_one_iff)
    thus False using h by auto
  qed
  thus "5 dvd n" by blast
qed

lemma %internal sqrt5_step1:
  assumes "q > (0::int)" "sqrt 5 = of_int p / of_int q"
  shows "5 * q\<^sup>2 = p\<^sup>2"
proof -
  have q_nz: "of_int q \<noteq> (0::real)" using assms(1) by simp
  have "sqrt 5 * of_int q = (of_int p :: real)"
    using assms(2) q_nz by (simp add: field_simps)
  hence "(sqrt 5)^2 * (of_int q)^2 = (of_int p :: real)^2"
    by (metis power_mult_distrib)
  hence "5 * (of_int q :: real)^2 = (of_int p :: real)^2"
    using sqrt5_squared by simp
  hence "(of_int (5 * q\<^sup>2) :: real) = of_int (p\<^sup>2)"
    by (simp add: of_int_power of_int_mult)
  thus "5 * q\<^sup>2 = p\<^sup>2" using of_int_eq_iff by blast
qed

lemma %internal sqrt5_step2:
  assumes "5 * q\<^sup>2 = p\<^sup>2"
  shows "(5::int) dvd p"
proof -
  from assms have pp: "p * p = 5 * (q * q)" by (simp add: power2_eq_square)
  hence dvd_pp: "(5::int) dvd (p * p)" by simp
  from five_dvd_square[OF dvd_pp] show "5 dvd p" .
qed

lemma %internal sqrt5_step3:
  assumes eq2: "5 * q\<^sup>2 = p\<^sup>2" and p_eq: "p = 5 * k"
  shows "(5::int) dvd q"
proof -
  from eq2 p_eq have "5 * q\<^sup>2 = (5 * k)\<^sup>2" by simp
  hence "5 * (q * q) = 25 * (k * k)" by (simp add: power2_eq_square)
  hence qq: "q * q = 5 * (k * k)" by linarith
  hence dvd_qq: "(5::int) dvd (q * q)" by simp
  from five_dvd_square[OF dvd_qq] show "5 dvd q" .
qed

lemma %internal sqrt5_not_rat: "sqrt 5 \<notin> \<rat>"
proof
  assume "sqrt 5 \<in> \<rat>"
  then obtain p q :: int where q_pos: "q > 0" and eq: "sqrt 5 = of_int p / of_int q"
    and coprime: "coprime p q"
    using Rats_cases' by blast
  have eq2: "5 * q\<^sup>2 = p\<^sup>2" using sqrt5_step1[OF q_pos eq] .
  have p5: "5 dvd p" using sqrt5_step2[OF eq2] .
  then obtain k where p_eq: "p = 5 * k" by auto
  have q5: "5 dvd q" using sqrt5_step3[OF eq2 p_eq] .
  from p5 q5 have "5 dvd gcd p q" by simp
  with coprime show False by simp
qed

lemma %internal phi_not_rat: "(sqrt 5 - 1) / 2 \<notin> \<rat>"
proof
  assume h: "(sqrt 5 - 1) / 2 \<in> \<rat>"
  have "sqrt 5 \<in> \<rat>"
  proof -
    from h obtain r :: rat where r_eq: "(sqrt 5 - 1) / 2 = real_of_rat r"
      using Rats_cases by blast
    hence "sqrt 5 = real_of_rat (2 * r + 1)"
      by (simp add: of_rat_mult of_rat_add field_simps)
    hence "sqrt 5 \<in> \<rat>" using Rats_of_rat by metis
    thus ?thesis .
  qed
  with sqrt5_not_rat show False by simp
qed

text %internal \<open>A rational quality is also a real quality:\<close>

lemma %internal rational_quality_is_real_quality:
  assumes \<open>is_int_approx_quality f e\<close>
  shows \<open>\<epsilon>\<^sub>\<real>(f) = e\<^sub>\<real>\<close>
proof (rule real_quality_eq, unfold real_quality_pred_def, intro conjI allI impI)
  fix z show "\<bar>real_of_rat z - real_of_int (f z)\<bar> \<le> real_of_rat e"
  proof -
    from assms have "\<bar>z - (f z)\<^sub>\<rat>\<bar> \<le> e"
      unfolding is_int_approx_quality_def by blast
    hence "real_of_rat \<bar>z - (f z)\<^sub>\<rat>\<bar> \<le> real_of_rat e"
      using of_rat_less_eq by blast
    thus ?thesis using of_rat_abs_diff[of z f] by simp
  qed
next
  fix q' :: real assume ub: "\<forall>z. \<bar>real_of_rat z - real_of_int (f z)\<bar> \<le> q'"
  show "real_of_rat e \<le> q'"
  proof (rule ccontr)
    assume "\<not> real_of_rat e \<le> q'"
    hence q'_lt: "q' < real_of_rat e" by simp
    obtain r :: rat where r_gt: "real_of_rat r > q'" and r_lt: "real_of_rat r < real_of_rat e"
      using of_rat_dense[OF q'_lt] by blast
    hence r_lt_e: "r < e" using of_rat_less by blast
    from assms have nub: "\<not> (\<forall>z. \<bar>z - (f z)\<^sub>\<rat>\<bar> \<le> r)"
      unfolding is_int_approx_quality_def using r_lt_e by force
    then obtain z0 where z0: "\<not> \<bar>z0 - (f z0)\<^sub>\<rat>\<bar> \<le> r" by blast
    hence z0_gt: "\<bar>z0 - (f z0)\<^sub>\<rat>\<bar> > r" by simp
    hence "real_of_rat \<bar>z0 - (f z0)\<^sub>\<rat>\<bar> > real_of_rat r"
      by (simp add: of_rat_less)
    hence gt: "\<bar>real_of_rat z0 - real_of_int (f z0)\<bar> > real_of_rat r"
      using of_rat_abs_diff[of z0 f] by simp
    have "\<bar>real_of_rat z0 - real_of_int (f z0)\<bar> > q'"
      using gt r_gt by linarith
    thus False using ub[rule_format, of z0] by linarith
  qed
qed

text \<open>Since the golden ratio is irrational, no rational quality exists:\<close>

theorem \<open>\<not> is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>\<phi> e\<close>
proof
  assume h: \<open>is_int_approx_quality \<lfloor>\<cdot>\<rceil>\<^sub>\<phi> e\<close>
  from rational_quality_is_real_quality[OF h]
  have \<open>\<epsilon>\<^sub>\<real>(\<lfloor>\<cdot>\<rceil>\<^sub>\<phi>) = e\<^sub>\<real>\<close> .
  moreover from real_quality_golden
  have \<open>\<epsilon>\<^sub>\<real>(\<lfloor>\<cdot>\<rceil>\<^sub>\<phi>) = (\<surd>5 - 1) / 2\<close> .
  ultimately have \<open>e\<^sub>\<real> = (\<surd>5 - 1) / 2\<close> by simp
  hence \<open>(\<surd>5 - 1) / 2 \<in> \<rat>\<close> using Rats_of_rat by metis
  with phi_not_rat show False by simp
qed

section \<open>Modular residues\<close>

text \<open>
Each approximation \<open>\<lbrakk>_\<rbrakk>\<close> induces a residue \<open>z mod\<lbrakk>f\<rbrakk> N := z - N \<sqdot> \<lbrakk>z /\<^sub>\<rat> N\<rbrakk>\<close>. Setting
\<open>\<lbrakk>_\<rbrakk> = \<lfloor>\<cdot>\<rfloor>\<close> recovers the unsigned representative \<open>z mod\<^sup>+ N\<close> in \<open>{0, \<dots>, N-1}\<close>;
\<open>\<lbrakk>_\<rbrakk> = \<lfloor>\<cdot>\<rceil>\<close> the signed representative \<open>z mod\<^sup>\<plusminus> N\<close> in
\<open>{-\<lfloor>N/2\<rfloor>, \<dots>, \<lfloor>(N-1)/2\<rfloor>}\<close>.
\<close>

definition \<open>mod_approx f z N \<equiv> z - N * \<lbrakk>z /\<^sub>\<rat> N\<rbrakk>\<close> for f ("\<lbrakk>_\<rbrakk>")

abbreviation mod_approx_paper (\<open>(_) mod \<lbrakk>_\<rbrakk> (_)\<close> [70, 0, 71] 70) where
  \<open>z mod\<lbrakk>f\<rbrakk> N \<equiv> mod_approx f z N\<close>

abbreviation mod_unsigned (infixl \<open>mod\<^sup>+\<close> 70) where
  \<open>z mod\<^sup>+ N \<equiv> mod_approx \<lfloor>\<cdot>\<rfloor> z N\<close>

abbreviation mod_signed (infixl \<open>mod\<^sup>\<plusminus>\<close> 70) where
  \<open>z mod\<^sup>\<plusminus> N \<equiv> mod_approx \<lfloor>\<cdot>\<rceil> z N\<close>

text \<open>
A sanity check: the \<^term>\<open>floor\<close>-induced residue coincides with the standard unsigned
reduction, justifying \<open>mod\<^sup>+\<close> as the unsigned representative throughout.
\<close>

lemma mod_unsigned_eq_mod:
  assumes \<open>N > 0\<close>
  shows \<open>z mod\<^sup>+ N = z mod N\<close>
  unfolding mod_approx_def using assms
  by (simp add: floor_divide_of_int_eq, simp add: minus_mult_div_eq_mod)

text \<open>
\noindent A general absolute bound \<^term>\<open>\<bar>z mod\<lbrakk>f\<rbrakk> N\<bar> \<le> N\<close> holds for every integer approximation.
\<close>

lemma mod_approx_bound:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>is_int_approx f\<close> and \<open>N > 0\<close>
  shows \<open>\<bar>z mod\<lbrakk>f\<rbrakk> N\<bar> \<le> N\<close>
proof -
  have h: \<open>\<bar>z /\<^sub>\<rat> N - \<lbrakk>z /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat>\<bar> \<le> 1\<close>
    using assms(1) unfolding is_int_approx_def by simp
  have \<open>\<bar>(mod_approx f z N)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat>\<close>
    unfolding mod_approx_def
    using h assms(2) by (simp add: field_simps abs_mult_pos)
  thus ?thesis by (metis of_int_abs of_int_le_iff)
qed

text \<open>The following is merely a reformulation of the definition, but useful:\<close>

lemma magic_const_rat:
  fixes f :: \<open>rat \<Rightarrow> int\<close> ("\<lbrakk>_\<rbrakk>") and N R :: int
  assumes \<open>is_int_approx f\<close> and \<open>N \<noteq> 0\<close>
  shows \<open>(\<lbrakk>R /\<^sub>\<rat> N\<rbrakk>)\<^sub>\<rat> = (R - R mod\<lbrakk>f\<rbrakk> N) /\<^sub>\<rat> N\<close>
proof -
  have \<open>R mod\<lbrakk>f\<rbrakk> N = R - N * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk>\<close>
    unfolding mod_approx_def by simp
  hence \<open>(R - R mod\<lbrakk>f\<rbrakk> N)\<^sub>\<rat> = (N * \<lbrakk>R /\<^sub>\<rat> N\<rbrakk>)\<^sub>\<rat>\<close> by simp
  thus ?thesis using assms(2) by (simp add: of_int_mult field_simps)
qed
text \<open>If a quality witness exists for \<open>\<lbrakk>_\<rbrakk>\<close>, the residue is bounded by \<^term>\<open>\<epsilon>(f) * N\<close>:
the slope shrinks by exactly the approximation quality.\<close>

lemma mod_approx_bound_eps_at:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>N > 0\<close>
  shows \<open>\<bar>(z mod\<lbrakk>f\<rbrakk> N)\<^sub>\<rat>\<bar> = N\<^sub>\<rat> * \<epsilon>(f, z /\<^sub>\<rat> N)\<close>
proof -
  have iN_pos: \<open>N\<^sub>\<rat> > 0\<close> using assms by simp
  have eq: \<open>(z mod\<lbrakk>f\<rbrakk> N)\<^sub>\<rat> = N\<^sub>\<rat> * (z /\<^sub>\<rat> N - \<lbrakk>z /\<^sub>\<rat> N\<rbrakk>\<^sub>\<rat>)\<close>
    unfolding mod_approx_def using iN_pos by (simp add: field_simps)
  show ?thesis unfolding eq using iN_pos by (simp add: abs_mult)
qed

lemma mod_approx_bound_eps:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>is_int_approx_quality f e\<close> and \<open>N > 0\<close>
  shows \<open>\<bar>(z mod\<lbrakk>f\<rbrakk> N)\<^sub>\<rat>\<bar> \<le> N\<^sub>\<rat> * \<epsilon>(f)\<close>
  using mod_approx_bound_eps_at[OF assms(2), of f z]
        quality_at_le[OF assms(1), of \<open>z /\<^sub>\<rat> N\<close>]
        assms(2)
  by (simp add: mult_left_mono)

text \<open>
For the signed and unsigned residues, both pinned to canonical intervals,
the bound \<^term>\<open>\<epsilon>(f) * N\<close> from @{thm [source] mod_approx_bound_eps} specialises to the integer-form
inequalities below: the signed residue lies in
\<^latex>\<open>$\{-\lfloor N/2\rfloor, \dots, \lfloor (N-1)/2 \rfloor\}$\<close> (matching
\<^term>\<open>\<epsilon>(round) = 1/2\<close>), and the unsigned residue in \<open>\<lbrace>0, \<dots>, N - 1\<rbrace>\<close>
(matching \<^term>\<open>\<epsilon>(floor) = 1\<close>).
\<close>

lemma mod_canonical_bounds:
  assumes \<open>N > 0\<close>
  shows mod_signed_lower:   \<open>- (N div 2) \<le> z mod\<^sup>\<plusminus> N\<close>
    and mod_signed_upper:   \<open>z mod\<^sup>\<plusminus> N \<le> (N - 1) div 2\<close>
    and mod_unsigned_lower: \<open>0 \<le> z mod\<^sup>+ N\<close>
    and mod_unsigned_upper: \<open>z mod\<^sup>+ N < N\<close>
proof -
  have h1: \<open>(z mod\<^sup>\<plusminus> N)\<^sub>\<rat> = z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat>\<close>
    unfolding mod_approx_def by simp
  have h3: \<open>N\<^sub>\<rat> > 0\<close> using assms by simp
  have h2_lo: \<open>\<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> \<le> z /\<^sub>\<rat> N + 1/2\<close>
    unfolding round_def by linarith
  have \<open>N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> \<le> N\<^sub>\<rat> * (z /\<^sub>\<rat> N + 1/2)\<close>
    using h2_lo h3 by (simp add: mult_left_mono)
  also have \<open>\<dots> = z\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
    using h3 by (simp add: field_simps)
  finally have \<open>z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> \<ge> - (N\<^sub>\<rat> / 2)\<close>
    by linarith
  hence \<open>(z mod\<^sup>\<plusminus> N)\<^sub>\<rat> \<ge> - (N\<^sub>\<rat> / 2)\<close>
    using h1 by simp
  hence \<open>(2 * (z mod\<^sup>\<plusminus> N))\<^sub>\<rat> \<ge> - N\<^sub>\<rat>\<close>
    by (simp add: field_simps)
  hence \<open>2 * (z mod\<^sup>\<plusminus> N) \<ge> - N\<close>
    by (metis of_int_le_iff of_int_minus of_int_mult of_int_numeral)
  thus \<open>- (N div 2) \<le> z mod\<^sup>\<plusminus> N\<close> using assms by linarith
next
  have h1: \<open>(z mod\<^sup>\<plusminus> N)\<^sub>\<rat> = z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat>\<close>
    unfolding mod_approx_def by simp
  have h3: \<open>N\<^sub>\<rat> > 0\<close> using assms by simp
  have h2_hi: \<open>\<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> > z /\<^sub>\<rat> N - 1/2\<close>
    unfolding round_def by linarith
  have \<open>N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> > N\<^sub>\<rat> * (z /\<^sub>\<rat> N - 1/2)\<close>
    using h2_hi h3 by (simp add: mult_strict_left_mono)
  also have \<open>N\<^sub>\<rat> * (z /\<^sub>\<rat> N - 1/2) = z\<^sub>\<rat> - N\<^sub>\<rat> / 2\<close>
    using h3 by (simp add: field_simps)
  finally have \<open>z\<^sub>\<rat> - N\<^sub>\<rat> * \<lfloor>z /\<^sub>\<rat> N\<rceil>\<^sub>\<rat> < N\<^sub>\<rat> / 2\<close>
    by linarith
  hence \<open>(z mod\<^sup>\<plusminus> N)\<^sub>\<rat> < N\<^sub>\<rat> / 2\<close>
    using h1 by simp
  hence \<open>(2 * (z mod\<^sup>\<plusminus> N))\<^sub>\<rat> < N\<^sub>\<rat>\<close>
    by (simp add: field_simps)
  hence \<open>2 * (z mod\<^sup>\<plusminus> N) < N\<close>
    by (metis of_int_less_iff of_int_mult of_int_numeral)
  thus \<open>z mod\<^sup>\<plusminus> N \<le> (N - 1) div 2\<close> using assms by linarith
next
  show \<open>0 \<le> z mod\<^sup>+ N\<close> using mod_unsigned_eq_mod[OF assms] assms by simp
next
  show \<open>z mod\<^sup>+ N < N\<close> using mod_unsigned_eq_mod[OF assms] assms by simp
qed

paragraph %internal \<open>Fact 1: negation on the canonical signed range.\<close>

text %internal \<open>
\cite[Fact~1, \S3.1.1]{NeonNTT} describes how the signed residue
interacts with negation on the canonical signed range. With \<^term>\<open>R = 2^n\<close>, signed reduction
commutes with negation — \<^term>\<open>(-x) mod\<^sup>\<plusminus> R = -(x mod\<^sup>\<plusminus> R)\<close> — for almost every \<open>x \<in> \<int>\<^sub>R\<close>
(\<open>mod_signed_negate_generic\<close>). The single exception is the boundary point \<^term>\<open>x = 2^(n-1)\<close>,
whose negation crosses the asymmetric edge of the signed interval, producing an extra
\<^term>\<open>-R\<close> correction (\<open>mod_signed_negate_exceptional\<close>).
\<close>

lemma %internal mod_signed_negate_generic:
  assumes \<open>n \<ge> 1\<close>
  defines \<open>R \<equiv> 2^n\<close>
  assumes \<open>x mod R \<noteq> 2^(n-1)\<close>
  shows \<open>(-x) mod\<^sup>\<plusminus> R = -(x mod\<^sup>\<plusminus> R)\<close>
proof -
  have R_pos: \<open>R > 0\<close> using assms unfolding R_def by simp
  have R_div2: \<open>R = 2 * 2^(n-1)\<close>
    using assms(1) unfolding R_def by (cases n, simp, simp)
  let ?q = \<open>x div R\<close>
  let ?r = \<open>x mod R\<close>
  let ?s = \<open>?r /\<^sub>\<rat> R\<close>
  have iR_pos: \<open>R\<^sub>\<rat> > 0\<close> using R_pos by simp
  have iR_nz: \<open>R\<^sub>\<rat> \<noteq> 0\<close> using R_pos by simp
  have x_decomp_int: \<open>x = R * ?q + ?r\<close> by simp
  have x_decomp: \<open>x\<^sub>\<rat> = R\<^sub>\<rat> * ?q\<^sub>\<rat> + ?r\<^sub>\<rat>\<close>
    using x_decomp_int by (metis of_int_add of_int_mult)
  have r_bounds: \<open>0 \<le> ?r \<and> ?r < R\<close> using R_pos by simp
  have key1: \<open>x /\<^sub>\<rat> R = ?q\<^sub>\<rat> + ?s\<close>
    using x_decomp iR_nz by (simp add: add_divide_distrib)
  have key2: \<open>(-x) /\<^sub>\<rat> R = -?q\<^sub>\<rat> - ?s\<close>
    using x_decomp iR_nz by (simp add: add_divide_distrib field_simps)
  have r_neq: \<open>?s \<noteq> 1/2\<close>
  proof
    assume \<open>?s = 1/2\<close>
    hence \<open>?r\<^sub>\<rat> = R\<^sub>\<rat> / 2\<close> using iR_nz by (simp add: field_simps)
    hence \<open>2 * ?r\<^sub>\<rat> = R\<^sub>\<rat>\<close> by simp
    hence \<open>(2 * ?r)\<^sub>\<rat> = R\<^sub>\<rat>\<close> by simp
    hence \<open>2 * ?r = R\<close> by (metis of_int_eq_iff of_int_mult of_int_numeral)
    hence \<open>?r = R div 2\<close> by simp
    also have \<open>R div 2 = 2^(n-1)\<close> using R_div2 by simp
    finally show False using assms(3) by simp
  qed
  have rR_nn: \<open>0 \<le> ?s\<close> using r_bounds iR_pos by simp
  have rR_lt1: \<open>?s < 1\<close> using r_bounds iR_pos by (simp add: divide_less_eq)
  have round_x: \<open>\<lfloor>x /\<^sub>\<rat> R\<rceil> = ?q + (if ?s < 1/2 then 0 else 1)\<close>
  proof (cases \<open>?s < 1/2\<close>)
    case True
    have \<open>\<lfloor>x /\<^sub>\<rat> R + 1/2\<rfloor> = \<lfloor>(?s + 1/2) + ?q\<^sub>\<rat>\<rfloor>\<close> using key1 by (simp add: algebra_simps)
    also have \<open>\<dots> = \<lfloor>?s + 1/2\<rfloor> + ?q\<close> by (rule floor_add_int[symmetric])
    also have \<open>\<lfloor>?s + 1/2\<rfloor> = 0\<close> using True rR_nn by linarith
    finally show ?thesis using True unfolding round_def by simp
  next
    case False
    hence sgt: \<open>?s > 1/2\<close> using r_neq by linarith
    have \<open>\<lfloor>x /\<^sub>\<rat> R + 1/2\<rfloor> = \<lfloor>(?s + 1/2) + ?q\<^sub>\<rat>\<rfloor>\<close> using key1 by (simp add: algebra_simps)
    also have \<open>\<dots> = \<lfloor>?s + 1/2\<rfloor> + ?q\<close> by (rule floor_add_int[symmetric])
    also have \<open>\<lfloor>?s + 1/2\<rfloor> = 1\<close> using sgt rR_lt1 by linarith
    finally show ?thesis using False unfolding round_def by simp
  qed
  have round_negx: \<open>\<lfloor>(-x) /\<^sub>\<rat> R\<rceil> = -?q - (if ?s < 1/2 then 0 else 1)\<close>
  proof (cases \<open>?s < 1/2\<close>)
    case True
    have \<open>\<lfloor>(-x) /\<^sub>\<rat> R + 1/2\<rfloor> = \<lfloor>(1/2 - ?s) + (-?q)\<^sub>\<rat>\<rfloor>\<close> using key2 by (simp add: algebra_simps)
    also have \<open>\<dots> = \<lfloor>1/2 - ?s\<rfloor> + (-?q)\<close> by (rule floor_add_int[symmetric])
    also have \<open>\<lfloor>1/2 - ?s\<rfloor> = 0\<close> using True rR_nn r_neq by (cases \<open>?s = 1/2\<close>) (linarith+)
    finally show ?thesis using True unfolding round_def by simp
  next
    case False
    hence sgt: \<open>?s > 1/2\<close> using r_neq by linarith
    have \<open>\<lfloor>(-x) /\<^sub>\<rat> R + 1/2\<rfloor> = \<lfloor>(1/2 - ?s) + (-?q)\<^sub>\<rat>\<rfloor>\<close> using key2 by (simp add: algebra_simps)
    also have \<open>\<dots> = \<lfloor>1/2 - ?s\<rfloor> + (-?q)\<close> by (rule floor_add_int[symmetric])
    also have \<open>\<lfloor>1/2 - ?s\<rfloor> = -1\<close> using sgt rR_lt1 by linarith
    finally show ?thesis using False unfolding round_def by simp
  qed
  have round_eq: \<open>\<lfloor>(-x) /\<^sub>\<rat> R\<rceil> = - \<lfloor>x /\<^sub>\<rat> R\<rceil>\<close>
    using round_x round_negx by simp
  show ?thesis
    unfolding mod_approx_def
    using round_eq by (simp add: algebra_simps)
qed

text %internal \<open>The exceptional case \<^term>\<open>x mod R = 2^(n-1)\<close> is exactly the boundary that the
preceding proof excluded, and produces the \<^term>\<open>-R\<close>-correction.\<close>

lemma %internal mod_signed_negate_exceptional:
  assumes \<open>n \<ge> 1\<close>
  defines \<open>R \<equiv> 2^n\<close>
  assumes \<open>x mod R = 2^(n-1)\<close>
  shows \<open>(-x) mod\<^sup>\<plusminus> R = -(x mod\<^sup>\<plusminus> R) - R\<close>
proof -
  have R_pos: \<open>R > 0\<close> using assms unfolding R_def by simp
  have R_div2: \<open>R = 2 * 2^(n-1)\<close>
    using assms(1) unfolding R_def by (cases n, simp, simp)
  let ?q = \<open>x div R\<close>
  let ?r = \<open>x mod R\<close>
  have iR_pos: \<open>R\<^sub>\<rat> > 0\<close> using R_pos by simp
  have iR_nz: \<open>R\<^sub>\<rat> \<noteq> 0\<close> using R_pos by simp
  have x_decomp_int: \<open>x = R * ?q + ?r\<close> by simp
  have x_decomp: \<open>x\<^sub>\<rat> = R\<^sub>\<rat> * ?q\<^sub>\<rat> + ?r\<^sub>\<rat>\<close>
    using x_decomp_int by (metis of_int_add of_int_mult)
  have r_eq: \<open>?r = 2^(n-1)\<close> using assms(3) by simp
  have key1: \<open>x /\<^sub>\<rat> R = ?q\<^sub>\<rat> + ?r /\<^sub>\<rat> R\<close>
    using x_decomp iR_nz by (simp add: add_divide_distrib)
  have key2: \<open>?r /\<^sub>\<rat> R = 1/2\<close>
    using r_eq R_div2 R_pos by simp
  have key: \<open>x /\<^sub>\<rat> R + 1/2 = (?q + 1)\<^sub>\<rat>\<close>
    using key1 key2 by simp
  have round_x: \<open>\<lfloor>x /\<^sub>\<rat> R\<rceil> = ?q + 1\<close>
    unfolding round_def using key by (simp add: floor_of_int)
  have neg_eq: \<open>(-x) /\<^sub>\<rat> R + 1/2 = -((?q + 1)\<^sub>\<rat>) + 1\<close>
    using key by (simp add: field_simps)
  have round_neg: \<open>\<lfloor>(-x) /\<^sub>\<rat> R\<rceil> = - ?q\<close>
    unfolding round_def using neg_eq by (simp add: floor_of_int)
  show ?thesis
    unfolding mod_approx_def
    using round_x round_neg by (simp add: algebra_simps)
qed

paragraph %internal \<open>Shift compatibility.\<close>

text %internal \<open>
An integer approximation \<open>\<lbrakk>_\<rbrakk>\<close> is \emph{shift-compatible} if it commutes with \<^term>\<open>(+) (1 :: rat)\<close>:
\<close>

definition %internal \<open>shift_compat f \<longleftrightarrow> (\<forall>z. \<lbrakk>z + 1\<rbrakk> = \<lbrakk>z\<rbrakk> + 1)\<close> for f ("\<lbrakk>_\<rbrakk>")

text %internal \<open>
Floor, ceiling, and round-to-nearest are shift-compatible. Even-rounding \<^term>\<open>round_even\<close>, however, is not. 
Interestingly, shift-compatibility plays no role in the abstract Barrett-Montgomery development of 
the following chapters, including the bridge of \autoref{ch:barrett_montgomery}: those proofs only invoke shift-compatibility 
of the fixed outer rounding (\<^term>\<open>round\<close> or \<^term>\<open>floor\<close>) used to define the canonical residue, never of the 
parameter \<open>\<lbrakk>_\<rbrakk>\<close>. Shift-compatibility therefore only constrains intermediate technical lemmas; the
headline statements remain generic in \<open>\<lbrakk>_\<rbrakk>\<close>.
\<close>

lemma %internal shift_compat_standard:
  shows shift_compat_floor: \<open>shift_compat \<lfloor>\<cdot>\<rfloor>\<close>
    and shift_compat_ceiling: \<open>shift_compat \<lceil>\<cdot>\<rceil>\<close>
    and shift_compat_round: \<open>shift_compat \<lfloor>\<cdot>\<rceil>\<close>
proof -
  show \<open>shift_compat \<lfloor>\<cdot>\<rfloor>\<close> unfolding shift_compat_def by simp
  show \<open>shift_compat \<lceil>\<cdot>\<rceil>\<close> unfolding shift_compat_def by simp
  show \<open>shift_compat \<lfloor>\<cdot>\<rceil>\<close>
    unfolding shift_compat_def round_def by (simp add: int_add_floor add.commute)
qed

lemma %internal shift_compat_iter_pos:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>shift_compat f\<close>
  shows \<open>\<lbrakk>z + (int k)\<^sub>\<rat>\<rbrakk> = \<lbrakk>z\<rbrakk> + int k\<close>
proof (induction k arbitrary: z)
  case 0
  show ?case by simp
next
  case (Suc m)
  have \<open>\<lbrakk>z + (int (Suc m))\<^sub>\<rat>\<rbrakk> = \<lbrakk>(z + (int m)\<^sub>\<rat>) + 1\<rbrakk>\<close>
    by (simp add: algebra_simps)
  also have \<open>\<dots> = \<lbrakk>z + (int m)\<^sub>\<rat>\<rbrakk> + 1\<close>
    using assms unfolding shift_compat_def by simp
  also have \<open>\<dots> = \<lbrakk>z\<rbrakk> + int m + 1\<close> using Suc by simp
  finally show ?case by simp
qed

lemma %internal shift_compat_iter_int:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>shift_compat f\<close>
  shows \<open>\<lbrakk>z + k\<^sub>\<rat>\<rbrakk> = \<lbrakk>z\<rbrakk> + k\<close>
proof (cases \<open>k \<ge> 0\<close>)
  case True
  then obtain m where m: \<open>k = int m\<close> using zero_le_imp_eq_int by blast
  show ?thesis using shift_compat_iter_pos[OF assms, of z m] m by simp
next
  case False
  hence \<open>- k \<ge> 0\<close> by simp
  then obtain m where m: \<open>- k = int m\<close> using zero_le_imp_eq_int by blast
  hence k_eq: \<open>k = - int m\<close> by simp
  have step: \<open>\<lbrakk>(z + k\<^sub>\<rat>) + (int m)\<^sub>\<rat>\<rbrakk> = \<lbrakk>z + k\<^sub>\<rat>\<rbrakk> + int m\<close>
    using shift_compat_iter_pos[OF assms, of \<open>z + k\<^sub>\<rat>\<close> m] by simp
  have eq: \<open>(z + k\<^sub>\<rat>) + (int m)\<^sub>\<rat> = z\<close>
    using k_eq by simp
  from step have \<open>\<lbrakk>z\<rbrakk> = \<lbrakk>z + k\<^sub>\<rat>\<rbrakk> + int m\<close> using eq by argo
  thus ?thesis using k_eq by simp
qed

lemma %internal mod_approx_shift:
  fixes f :: \<open>rat \<Rightarrow> int\<close> (\<open>\<lbrakk>_\<rbrakk>\<close>)
  assumes \<open>shift_compat f\<close> and \<open>N > 0\<close>
  shows \<open>(x + N * k) mod\<lbrakk>f\<rbrakk> N = x mod\<lbrakk>f\<rbrakk> N\<close>
proof -
  have div_split: \<open>(x + N * k) /\<^sub>\<rat> N = x /\<^sub>\<rat> N + k\<^sub>\<rat>\<close>
    using assms(2) by (simp add: field_simps)
  have \<open>\<lbrakk>(x + N * k) /\<^sub>\<rat> N\<rbrakk> = \<lbrakk>x /\<^sub>\<rat> N + k\<^sub>\<rat>\<rbrakk>\<close>
    using div_split by simp
  also have \<open>\<dots> = \<lbrakk>x /\<^sub>\<rat> N\<rbrakk> + k\<close>
    using shift_compat_iter_int[OF assms(1)] by simp
  finally have shift_eq:
    \<open>\<lbrakk>(x + N * k) /\<^sub>\<rat> N\<rbrakk> = \<lbrakk>x /\<^sub>\<rat> N\<rbrakk> + k\<close> .
  have \<open>(x + N * k) mod\<lbrakk>f\<rbrakk> N = (x + N * k) - N * \<lbrakk>(x + N * k) /\<^sub>\<rat> N\<rbrakk>\<close>
    unfolding mod_approx_def by simp
  also have \<open>\<dots> = (x + N * k) - N * (\<lbrakk>x /\<^sub>\<rat> N\<rbrakk> + k)\<close>
    using shift_eq by simp
  also have \<open>\<dots> = x - N * \<lbrakk>x /\<^sub>\<rat> N\<rbrakk>\<close>
    by (simp add: algebra_simps)
  also have \<open>\<dots> = x mod\<lbrakk>f\<rbrakk> N\<close>
    unfolding mod_approx_def by simp
  finally show ?thesis .
qed

section \<open>Standard locales \label{sec:standard_locales}\<close>

text \<open>
The Barrett and Montgomery analyses repeatedly need the same side conditions on
the modulus \<open>N\<close> and the bit-width \<open>n\<close>: \<open>N > 1\<close>, \<open>n > 0\<close>, \<open>N < 2^n\<close>, and --- for
the parts of the development that need it --- \<open>N\<close> odd. The integer-approximation
analyses likewise rely on \<open>is_int_approx f\<close>. We capture each context in an
Isabelle \isakeywordONE{locale} --- \<open>AnyModulus\<close> for the parity-agnostic modulus
side conditions, \<open>OddModulus\<close> for \<open>AnyModulus\<close> plus oddness of \<open>N\<close>,
\<open>IntegerApproximation\<close> for the rounding hypothesis, and \<open>BarrettContext\<close>
combining \<open>OddModulus\<close> with \<open>IntegerApproximation\<close> (defined in
\autoref{ch:barrett_red}). Lemmas that depend on these conditions are introduced
with the locale annotation \<open>(in AnyModulus)\<close>, \<open>(in OddModulus)\<close>, or
\<open>(in BarrettContext)\<close> and take no explicit \<open>assumes\<close>; the side conditions are
inherited from the locale, and abbreviations like \<open>R \<equiv> 2^n\<close> become visible.
\<close>

locale AnyModulus =
  fixes N :: int and n :: nat
  assumes Ngt1: \<open>N > 1\<close> and npos: \<open>n > 0\<close>
      and N_lt_R: \<open>N < 2^n\<close>
begin

abbreviation R :: int where \<open>R \<equiv> 2^n\<close>

lemma %internal Npos [simp]: \<open>N > 0\<close> using Ngt1 by linarith
lemma %internal N_nn [simp]: \<open>N \<ge> 0\<close> using Npos by linarith
lemma %internal R_pos [simp]: \<open>R > 0\<close> by simp
lemma %internal R_nz_int [simp]: \<open>R \<noteq> 0\<close> by simp
lemma %internal R_nz_rat [simp]: \<open>R\<^sub>\<rat> \<noteq> 0\<close> by simp
lemma %internal N_nz_int [simp]: \<open>N \<noteq> 0\<close> using Ngt1 by simp
lemma %internal N_nz_rat [simp]: \<open>N\<^sub>\<rat> \<noteq> 0\<close> using Npos by simp
lemma %internal N_pos_rat [simp]: \<open>N\<^sub>\<rat> > 0\<close> using Npos by simp
lemma %internal R_pos_rat [simp]: \<open>R\<^sub>\<rat> > 0\<close> by simp
lemma %internal N_lt_R_rat [simp]: \<open>N\<^sub>\<rat> < R\<^sub>\<rat>\<close> using N_lt_R by simp
lemma %internal R_eq: \<open>R = 2 * 2^(n-1)\<close> using npos by (cases n) auto
lemma %internal R_hlv: \<open>2^(n-1) = R /\<^sub>\<rat> 2\<close> by (simp add: Suc_le_eq npos power_diff)

end

locale OddModulus = AnyModulus +
  assumes Nodd: \<open>odd N\<close>

text \<open>\<^locale>\<open>OddModulus\<close> is \<^locale>\<open>AnyModulus\<close> with the extra hypothesis
that \<^term>\<open>N\<close> is odd. Parity-agnostic material lives in \<^locale>\<open>AnyModulus\<close>;
lemmas that genuinely need oddness stay in \<^locale>\<open>OddModulus\<close>, and can be
migrated to \<^locale>\<open>AnyModulus\<close> as the dependence on parity is removed.\<close>

locale IntegerApproximation =
  fixes f :: \<open>rat \<Rightarrow> int\<close>
  assumes f_approx: \<open>is_int_approx f\<close>
begin
notation f (\<open>\<lbrakk>_\<rbrakk>\<close>)
end


end
