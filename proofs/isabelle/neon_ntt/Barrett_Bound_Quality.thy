(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

theory Barrett_Bound_Quality
  imports Barrett_Montgomery "HOL-Library.Code_Target_Numeral"
begin

chapter \<open>Quality of the Barrett bounds \label{ch:barrett_bound_quality}\<close>

text %internal \<open>To avoid hardcoding values, we introduce some helper antiquotation for evaluating
and pretty-printing rationals in decimal form:\<close>
setup %internal \<open>
  let
    fun fmt_decimal {digits, percentage} (p, q) =
      let
        val p1 = if percentage then p * 100 else p
        val sfx = if percentage then "%" else ""
        val sign = if (p1 < 0) <> (q < 0) andalso p1 <> 0 then "-" else ""
        val ap = abs p1 val aq = abs q
        val whole = ap div aq
        val rem = ap mod aq
        fun pow10 0 = 1 | pow10 n = 10 * pow10 (n-1)
        val sc = pow10 digits
        val frac = (rem * sc) div aq
        val exact = (rem * sc) mod aq = 0
        fun pad n s = if size s >= n then s else pad n ("0" ^ s)
        val frac_str = pad digits (string_of_int frac)
        val body =
          if digits = 0 then sign ^ string_of_int whole
          else sign ^ string_of_int whole ^ "." ^ frac_str
        val approx = if exact then "" else "\<approx> "
      in approx ^ body ^ sfx end

    fun dest_pq t =
      case t of
        Const (\<^const_name>\<open>Product_Type.Pair\<close>, _) $ p $ q =>
          (snd (HOLogic.dest_number p), snd (HOLogic.dest_number q))
      | _ => raise TERM ("dest_pq: not a pair", [t])

    fun upd_digits n (_, p) = (n, p)
    val upd_pct = fn (d, _) => (d, true)

    val one_arg =
          (Parse.nat >> (fn n => upd_digits n))
       || (Parse.name >> (fn s =>
             if s = "percentage" then upd_pct
             else error ("Unknown decimal option: " ^ s)))

    val parse_opts =
      Scan.optional (Scan.lift (Args.parens (Parse.enum "," one_arg))) []
      >> (fn fs => fold I fs (4, false))
      >> (fn (d, p) => {digits = d, percentage = p})
  in
    Document_Output.antiquotation_pretty_source_embedded \<^binding>\<open>decimal\<close>
      (parse_opts -- Args.term)
      (fn ctxt => fn (opts, t) =>
         let
           val qot = \<^Const>\<open>quotient_of\<close> $ t
           val v = Value_Command.value ctxt qot
           val pq = dest_pq v
         in Pretty.str (fmt_decimal opts pq) end)
  end
  \<close>

context %internal BarrettContext
begin
text \<open>The purpose of this chapter is to empirically evaluate the quality of the bounds
of @{thm [source] barrett_bound_eps_narrow}. In particular, we will exhibit concrete instantiations
of @{locale BarrettContext} demonstrating that @{thm [source] barrett_bound_eps_narrow} is tight
and cannot be improved further (for generic moduli).\<close>
end %internal

text\<open>Throughout, we work in the context of @{locale BarrettContext}:\<close>

context BarrettContext
begin

section \<open>Empirical maxima and analytic bounds\<close>

text \<open>We define, in \<^locale>\<open>BarrettContext\<close>, the maximum achieved Barrett
magnitude over the input range @{term "{-(2^(n-1)).. 2^(n-1)}"} (signed and unsigned),
and the matching analytic upper bound recorded in \autoref{ch:barrett_montgomery}.\<close>

definition \<open>bar_signed_max \<equiv>  MAX z\<in>{-(2^(n-1))..2^(n-1)}. \<bar>bar\<^sup>\<plusminus> \<lbrakk>N,n,f\<rbrakk> z\<bar>\<close>
definition \<open>bar_unsigned_max \<equiv> MAX z\<in>{-(2^(n-1))..2^(n-1)}. \<bar>bar\<^sup>+ \<lbrakk>N,n,f\<rbrakk> z\<bar>\<close>
definition \<open>bar_signed_bound \<equiv> \<lfloor>N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 1) / 2\<rfloor>\<close>
definition \<open>bar_unsigned_bound \<equiv> \<lfloor>N\<^sub>\<rat> * (\<epsilon>(f, R /\<^sub>\<rat> N) + 2) / 2 - N /\<^sub>\<rat> R\<rfloor>\<close>

text \<open>A pointwise integer-form upper bound on \<^term>\<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar>\<close>,
obtained by floor-applying the rational bound
@{thm [source] barrett_bound_eps_narrow} at the canonical residue
\<^term>\<open>\<epsilon>(f, R /\<^sub>\<rat> N)\<close>. Used as the early-termination predicate for the
exhaustive sweeps below.\<close>

definition \<open>bar_signed_bnd_at z \<equiv> \<lfloor>\<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<rfloor>\<close>
definition \<open>bar_unsigned_bnd_at z \<equiv> \<lfloor>\<bar>z\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<rfloor>\<close>

text\<open>The following is merely a restatement of @{thm [source] barrett_montgomery_bounds_eps}:\<close>
                             
lemma bar_bnd_at_correct_mono:
  shows \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_signed_bnd_at \<bar>z\<bar>\<close>
    and \<open>\<bar>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_unsigned_bnd_at \<bar>z\<bar>\<close>
    and \<open>0 \<le> a \<Longrightarrow> a \<le> b \<Longrightarrow> bar_signed_bnd_at a \<le> bar_signed_bnd_at b\<close>
    and \<open>0 \<le> a \<Longrightarrow> a \<le> b \<Longrightarrow> bar_unsigned_bnd_at a \<le> bar_unsigned_bnd_at b\<close>
proof -
  have \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_signed_bnd_at z\<close>
    unfolding bar_signed_bnd_at_def
    using floor_mono[OF barrett_montgomery_bounds_eps(1)[of z]]
    by (metis floor_of_int of_int_abs)
  moreover have \<open>bar_signed_bnd_at z = bar_signed_bnd_at \<bar>z\<bar>\<close>
    unfolding bar_signed_bnd_at_def by simp
  ultimately show \<open>\<bar>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_signed_bnd_at \<bar>z\<bar>\<close> by simp
next
  have \<open>\<bar>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_unsigned_bnd_at z\<close>
    unfolding bar_unsigned_bnd_at_def
    using floor_mono[OF barrett_montgomery_bounds_eps(2)[of z]]
    by (metis floor_of_int of_int_abs)
  moreover have \<open>bar_unsigned_bnd_at z = bar_unsigned_bnd_at \<bar>z\<bar>\<close>
    unfolding bar_unsigned_bnd_at_def by simp
  ultimately show \<open>\<bar>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> z\<bar> \<le> bar_unsigned_bnd_at \<bar>z\<bar>\<close> by simp
next
  fix a b :: int assume \<open>0 \<le> a\<close> \<open>a \<le> b\<close>
  hence abs_le: \<open>\<bar>a\<bar>\<^sub>\<rat> \<le> \<bar>b\<bar>\<^sub>\<rat>\<close> by simp
  have nn: \<open>0 \<le> N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)\<close> using Npos by simp
  have \<open>\<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2
        \<le> \<bar>b\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> / 2\<close>
    using abs_le nn R_pos_rat by (simp add: divide_right_mono mult_right_mono)
  thus \<open>bar_signed_bnd_at a \<le> bar_signed_bnd_at b\<close>
    unfolding bar_signed_bnd_at_def by (rule floor_mono)
next
  fix a b :: int assume \<open>0 \<le> a\<close> \<open>a \<le> b\<close>
  hence abs_le: \<open>\<bar>a\<bar>\<^sub>\<rat> \<le> \<bar>b\<bar>\<^sub>\<rat>\<close> by simp
  have nn: \<open>0 \<le> N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)\<close> using Npos by simp
  have \<open>\<bar>a\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R
        \<le> \<bar>b\<bar>\<^sub>\<rat> * (N\<^sub>\<rat> * \<epsilon>(f, R /\<^sub>\<rat> N)) / R\<^sub>\<rat> + N\<^sub>\<rat> - N /\<^sub>\<rat> R\<close>
    using abs_le nn R_pos_rat by (simp add: divide_right_mono mult_right_mono)
  thus \<open>bar_unsigned_bnd_at a \<le> bar_unsigned_bnd_at b\<close>
    unfolding bar_unsigned_bnd_at_def by (rule floor_mono)
qed

lemmas %internal correct_signed   = bar_bnd_at_correct_mono(1)
lemmas %internal correct_unsigned = bar_bnd_at_correct_mono(2)
lemmas %internal mono_signed      = bar_bnd_at_correct_mono(3)
lemmas %internal mono_unsigned    = bar_bnd_at_correct_mono(4)

section \<open>Computable maxima via exhaustive sweep with early termination\<close>

text \<open>Naive computation of @{thm [show_question_marks=false] (rhs) bar_signed_max_def} is impractical for larger values
of @{term N} and @{term n}. Instead, we use the following stand-alone helper computing the maximum absolute 
value of an integer function \<open>f\<close> over a symmetric interval @{term "{-max_abs..max_abs}"} with the help of an
\emph{early termination} condition: every \<open>K\<close> inward steps, the recursion checks whether a user-supplied bound 
\<^term>\<open>f_bnd\<close> on the un-swept inner radius is already dominated by the current candidate maximum, and if so 
returns immediately. The recursion sweeps inward from \<^term>\<open>max_abs\<close> toward \<^term>\<open>0\<close>, processing the symmetric
pair @{term "(g i, g (-i))"} per step.\<close>

end \<comment>\<open>... temporarily leaving the context of @{locale BarrettContext}\<close>

function max_abs_with_bound_core ::
  \<open>(int \<Rightarrow> int) \<Rightarrow> (int \<Rightarrow> int) \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int\<close>
where
  \<comment>\<open>Base case: no steps left; return the running maximum.\<close>
  \<open>max_abs_with_bound_core f f_bnd 0       K i cur = cur\<close>
| \<open>max_abs_with_bound_core f f_bnd (Suc k) K i cur =
   (let cur' = max (max cur \<bar>f i\<bar>) \<bar>f (-i)\<bar>;  \<comment>\<open>update with symmetric pair\<close>
        tail_radius = i - 1;
        checkpoint = (K = 0 \<or> k mod K = 0);    \<comment>\<open>consult early-exit every \<open>K\<close> steps\<close>
        can_skip = (checkpoint \<and> tail_radius \<ge> 0 \<and> f_bnd tail_radius \<le> cur')
    in if can_skip then cur'
       else max_abs_with_bound_core f f_bnd k K tail_radius cur')\<close>
  by pat_completeness auto
termination %internal by (relation \<open>measure (\<lambda>(_,_,k,_,_,_). k)\<close>) auto

definition \<open>max_abs_with_bound f f_bnd max_abs K \<equiv>
  \<comment>\<open>Sweep \<open>[-max_abs..max_abs]\<close> from the outside in, starting with \<open>cur = 0\<close>.\<close>
  max_abs_with_bound_core f f_bnd (max_abs + 1) K (int max_abs) 0\<close>

text %internal \<open>Strengthened induction lemma for \<^const>\<open>max_abs_with_bound_core\<close>.
Reading: at recursion depth \<open>Suc k\<close> with index \<open>i\<close> (where \<open>nat i = k\<close>) and
accumulator \<open>cur\<close>, the result is the maximum of \<open>cur\<close> and \<open>Max \<bar>f\<bar>\<close> over
\<open>[-i..i]\<close>.

The early-exit branch is justified by monotonicity of the bound: if
\<open>f_bnd tail_radius \<le> cur'\<close> then for every \<open>z\<close> with \<open>\<bar>z\<bar> \<le> tail_radius\<close> we have
\<open>\<bar>f z\<bar> \<le> f_bnd \<bar>z\<bar> \<le> f_bnd tail_radius \<le> cur'\<close>, so the un-swept inner range
cannot improve \<open>cur'\<close>. The continue branch uses the IH on the smaller index.\<close>

lemma %internal max_abs_with_bound_core_correct:
  fixes f f_bnd :: \<open>int \<Rightarrow> int\<close>
  assumes bnd_correct: \<open>\<And>x. \<bar>f x\<bar> \<le> f_bnd \<bar>x\<bar>\<close>
      and bnd_mono:    \<open>\<And>a b. 0 \<le> a \<Longrightarrow> a \<le> b \<Longrightarrow> f_bnd a \<le> f_bnd b\<close>
  shows \<open>\<And>i cur. i \<ge> 0 \<Longrightarrow> nat i = k \<Longrightarrow>
           max_abs_with_bound_core f f_bnd (Suc k) K i cur =
           max cur (MAX z\<in>{-i..i}. \<bar>f z\<bar>)\<close>
proof (induction k)
  case 0
  then show ?case by simp
next
  case (Suc k)
  then have i_pos: \<open>i \<ge> 1\<close> by linarith
  define cur' where \<open>cur' = max (max cur \<bar>f i\<bar>) \<bar>f (-i)\<bar>\<close>
  define tail_radius where \<open>tail_radius = i - 1\<close>
  have tr_nn: \<open>tail_radius \<ge> 0\<close> using i_pos tail_radius_def by simp
  have nat_tr: \<open>nat tail_radius = k\<close> using Suc.prems tail_radius_def i_pos by simp
  let ?M = \<open>MAX z\<in>{-tail_radius..tail_radius}. \<bar>f z\<bar>\<close>
  have split: \<open>(MAX z\<in>{-i..i}. \<bar>f z\<bar>) = max (max \<bar>f i\<bar> \<bar>f (-i)\<bar>) ?M\<close>
    using i_pos tail_radius_def
    by (subgoal_tac \<open>{-i..i} = insert i (insert (-i) {-tail_radius..tail_radius})\<close>)
       (auto simp: Max.insert max.assoc)
  have unfold: \<open>max_abs_with_bound_core f f_bnd (Suc (Suc k)) K i cur =
                  (if (K = 0 \<or> Suc k mod K = 0) \<and> tail_radius \<ge> 0 \<and> f_bnd tail_radius \<le> cur'
                   then cur'
                   else max_abs_with_bound_core f f_bnd (Suc k) K tail_radius cur')\<close>
    by (simp only: max_abs_with_bound_core.simps(2) Let_def cur'_def tail_radius_def)
  show ?case
  proof (cases \<open>(K = 0 \<or> Suc k mod K = 0) \<and> tail_radius \<ge> 0 \<and> f_bnd tail_radius \<le> cur'\<close>)
    case True
    have inner_bound: \<open>\<And>z. z \<in> {-tail_radius..tail_radius} \<Longrightarrow> \<bar>f z\<bar> \<le> cur'\<close>
    proof -
      fix z assume zin: \<open>z \<in> {-tail_radius..tail_radius}\<close>
      have abs_le: \<open>\<bar>z\<bar> \<le> tail_radius\<close> using zin tr_nn by auto
      have \<open>\<bar>f z\<bar> \<le> f_bnd \<bar>z\<bar>\<close> using bnd_correct by blast
      also have \<open>\<dots> \<le> f_bnd tail_radius\<close> using bnd_mono[OF abs_ge_zero abs_le] .
      also have \<open>\<dots> \<le> cur'\<close> using True by simp
      finally show \<open>\<bar>f z\<bar> \<le> cur'\<close> .
    qed
    have max_le: \<open>?M \<le> cur'\<close>
      using inner_bound tr_nn by (intro Max.boundedI) auto
    have \<open>max cur (MAX z\<in>{-i..i}. \<bar>f z\<bar>) = cur'\<close>
    proof -
      have step1: \<open>max cur (MAX z\<in>{-i..i}. \<bar>f z\<bar>) = max cur' ?M\<close>
        unfolding split cur'_def by (simp add: max.assoc)
      show ?thesis using step1 max_le by simp
    qed
    thus ?thesis using unfold True by simp
  next
    case False
    have IH: \<open>max_abs_with_bound_core f f_bnd (Suc k) K tail_radius cur' =
              max cur' ?M\<close>
      using Suc.IH[OF tr_nn nat_tr] .
    show ?thesis
    proof -
      have rhs_eq: \<open>max cur (MAX z\<in>{-i..i}. \<bar>f z\<bar>) = max cur' ?M\<close>
        using split cur'_def by (metis max.assoc)
      have lhs_eq: \<open>max_abs_with_bound_core f f_bnd (Suc (Suc k)) K i cur =
                    max_abs_with_bound_core f f_bnd (Suc k) K tail_radius cur'\<close>
        using unfold False by (metis (full_types))
      show ?thesis using lhs_eq IH rhs_eq by metis
    qed
  qed
qed

text\<open>The following lemma shows that for a correct early-termination function, the function
@{term max_abs_with_bound} indeed computes a maximum absolute value over a symmetric interval:\<close>

lemma max_abs_with_bound_eq:
  assumes bnd_correct: \<open>\<And>x. \<bar>f x\<bar> \<le> f_bnd \<bar>x\<bar>\<close>
      and bnd_mono:    \<open>\<And>a b. 0 \<le> a \<Longrightarrow> a \<le> b \<Longrightarrow> f_bnd a \<le> f_bnd b\<close>
  shows \<open>max_abs_with_bound f f_bnd max_abs K =
           (MAX z\<in>{-(int max_abs) .. int max_abs}. \<bar>f z\<bar>)\<close>
proof -
  \<comment>\<open>Switch the natural number range to the integer interval.\<close>
  define M where \<open>M = int max_abs\<close>
  have M_nn: \<open>M \<ge> 0\<close> using M_def by simp
  have nat_eq: \<open>(max_abs + 1) = Suc max_abs\<close> by simp
  have nat_max: \<open>nat M = max_abs\<close> using M_def by simp
  \<comment>\<open>Specialise the strengthened induction lemma at recursion depth \<open>Suc max_abs\<close>.\<close>
  note core_correct =
    max_abs_with_bound_core_correct
      [where f=f and f_bnd=f_bnd and K=K and k=max_abs,
       OF bnd_correct bnd_mono M_nn nat_max]
  have core_eq: \<open>\<And>cur. max_abs_with_bound_core f f_bnd (Suc max_abs) K M cur =
                       max cur (MAX z\<in>{-M..M}. \<bar>f z\<bar>)\<close>
    using core_correct by blast
  \<comment>\<open>Unfold the wrapper to the core call with \<open>cur = 0\<close>.\<close>
  have \<open>max_abs_with_bound f f_bnd max_abs K =
        max_abs_with_bound_core f f_bnd (Suc max_abs) K M 0\<close>
    unfolding max_abs_with_bound_def using nat_eq M_def by simp
  \<comment>\<open>Apply the induction lemma to expose the \<open>Max\<close>-form result.\<close>
  also have \<open>\<dots> = max 0 (MAX z\<in>{-M..M}. \<bar>f z\<bar>)\<close>
    using core_eq by blast
  \<comment>\<open>Drop the outer \<open>max 0\<close>: every \<open>\<bar>f z\<bar>\<close> is nonnegative, and the interval is nonempty.\<close>
  also have \<open>\<dots> = (MAX z\<in>{-M..M}. \<bar>f z\<bar>)\<close>
  proof -
    have ne: \<open>{-M..M} \<noteq> {}\<close> using M_nn by auto
    have nn: \<open>\<forall>x \<in> (\<lambda>z. \<bar>f z\<bar>) ` {-M..M}. x \<ge> 0\<close> by auto
    have nonempty_img: \<open>(\<lambda>z. \<bar>f z\<bar>) ` {-M..M} \<noteq> {}\<close> using ne by simp
    have fin: \<open>finite ((\<lambda>z. \<bar>f z\<bar>) ` {-M..M})\<close> by simp
    from Max_in[OF fin nonempty_img] nn
      have \<open>(MAX z\<in>{-M..M}. \<bar>f z\<bar>) \<ge> 0\<close> by blast
    thus ?thesis by simp
  qed
  finally show ?thesis using M_def by simp
qed

context BarrettContext begin \<comment>\<open>... re-entering @{locale BarrettContext}\<close>

text\<open>Applying this to the Barrett context, we obtain the following efficient formula for computing
the maximum absolute value of a Barrett reduction in the interval @{term "{-(2^(n-1))..2^(n-1)}"}.
We will register those lemmas as \<^emph>\<open>code equations\<close> when evaluating @{term bar_signed_max} and 
@{term bar_unsigned_max} in concrete instantiations of @{locale BarrettContext}.\<close>

corollary bar_signed_max_eq:
  \<open>bar_signed_max = max_abs_with_bound bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk> bar_signed_bnd_at (2^(n-1)) K\<close>
proof -
  have intpow: \<open>int (2 ^ (n - 1)) = (2 ^ (n - 1) :: int)\<close> by simp
  show ?thesis
    unfolding bar_signed_max_def
    using max_abs_with_bound_eq
       [where f = \<open>bar\<^sup>\<plusminus>\<lbrakk>N, n, f\<rbrakk>\<close>
          and f_bnd = bar_signed_bnd_at
          and max_abs = \<open>2^(n-1)\<close>
          and K = K,
        OF bar_bnd_at_correct_mono(1) bar_bnd_at_correct_mono(3)] intpow
    by simp
qed

corollary bar_unsigned_max_eq:
  \<open>bar_unsigned_max = max_abs_with_bound bar\<^sup>+\<lbrakk>N, n, f\<rbrakk> bar_unsigned_bnd_at (2^(n-1)) K\<close>
proof -
  have intpow: \<open>int (2 ^ (n - 1)) = (2 ^ (n - 1) :: int)\<close> by simp
  show ?thesis
    unfolding bar_unsigned_max_def
    using max_abs_with_bound_eq
       [where f = \<open>bar\<^sup>+\<lbrakk>N, n, f\<rbrakk>\<close>
          and f_bnd = bar_unsigned_bnd_at
          and max_abs = \<open>2^(n-1)\<close>
          and K = K,
        OF bar_bnd_at_correct_mono(2) bar_bnd_at_correct_mono(4)] intpow by simp
qed

text \<open>For each sample we instantiate \<^locale>\<open>BarrettContext\<close> with concrete
\<open>(N, n, f)\<close> and tag @{thm [source] bar_unsigned_max_eq} and @{thm [source] bar_signed_max_eq}
as code equations so that \<open>value\<close> evaluates \<open>bar_*_max\<close>-constants by an exhaustive sweep with early
termination using \<^const>\<open>max_abs_with_bound\<close>.\<close>

end \<comment>\<open>Leaving the context of @{locale BarrettContext}\<close>

section \<open>Example 1: \<open>N = 97\<close>, \<open>n = 8\<close> (prime, illustrative 8-bit modulus)\<close>

text\<open>We start with a small prime \<^term>\<open>N=97\<close> and \<^term>\<open>n=8\<close> to illustrate the
methodology on a modulus where the bounds and achieved maxima are easy to inspect
by hand.

Here and in the other examples, we use \isakeyword{global\_interpretation} to instantiate
\<^locale>\<open>BarrettContext\<close> with concrete \<open>(N, n, f)\<close>. The command discharges the
locale's assumptions once and propagates every locale conclusion to the global
namespace; the qualifier (here \<open>BC_97_8\<close>) prefixes every fact and definition
introduced by the locale, preventing accidental shadowing.

The \isakeyword{defines} clause has a special role: each entry binds a global
constant to a locale-internal definition, so e.g.\ \<^term>\<open>bar_signed_max_97_8\<close> becomes
a top-level constant whose definitional equation is the locale definition specialised
to the chosen \<open>(N, n, f)\<close>. Without this clause we would still get the qualified name
\<open>BC_97_8.bar_signed_max\<close>, but it would not unfold during code generation: the code
generator treats locale constants as opaque. \<close>

global_interpretation BC_97_8: BarrettContext 97 8 round
  defines bar_signed_max_97_8      = \<open>BC_97_8.bar_signed_max\<close>
      and bar_unsigned_max_97_8    = \<open>BC_97_8.bar_unsigned_max\<close>
      and bar_signed_bound_97_8    = \<open>BC_97_8.bar_signed_bound\<close>
      and bar_unsigned_bound_97_8  = \<open>BC_97_8.bar_unsigned_bound\<close>
      and bar_signed_bnd_at_97_8   = \<open>BC_97_8.bar_signed_bnd_at\<close>
      and bar_unsigned_bnd_at_97_8 = \<open>BC_97_8.bar_unsigned_bnd_at\<close>
  by standard (auto simp add: is_int_approx_round)

declare %internal BC_97_8.bar_signed_max_eq[where K=1000000, code]
declare %internal BC_97_8.bar_unsigned_max_eq[where K=1000000, code]

text\<open>\noindent We can now evaluate the theoretical bounds against the attained maxima:\<close>

lemma BC_97_8_bounds:
    \<comment>\<open>Signed theoretical bound vs attained maximum\<close>
  shows \<open>bar_signed_max_97_8 = 66\<close>
    and \<open>bar_signed_bound_97_8 = 66\<close>
    \<comment>\<open>Unsigned theoretical bound vs attained maximum\<close>
    and \<open>bar_unsigned_max_97_8 = 108\<close>
    and \<open>bar_unsigned_bound_97_8 = 114\<close>
  by eval+

text %internal \<open>Register the above equations as code equations instead of the ones that were used
to compute them, so we can refer to them without re-evaluation:\<close>

declare %internal [[code drop: bar_signed_max_97_8 bar_unsigned_max_97_8]]
declare %internal BC_97_8_bounds[code]

text \<open>The signed theoretical bound is achieved exactly. The unsigned bound is
not attained, but with
  @{decimal (percentage, 1) "(bar_unsigned_bound_97_8 - bar_unsigned_max_97_8) /\<^sub>\<rat> bar_unsigned_bound_97_8"}
of slack.\<close>

section \<open>Example 2: \<open>N = 3329\<close>, \<open>n = 16\<close> (ML-KEM modulus)\<close>

text\<open>In this section, we look at \<^term>\<open>N=3329\<close>, the modulus underlying ML-KEM, together
with \<^term>\<open>n=16\<close> (ML-KEM is computed in 16-bit arithmetic). As before, we first instantiate
the Barrett context:\<close>

global_interpretation BC_3329_16: BarrettContext 3329 16 round
  defines bar_signed_max_3329_16      = \<open>BC_3329_16.bar_signed_max\<close>
      and bar_unsigned_max_3329_16    = \<open>BC_3329_16.bar_unsigned_max\<close>
      and bar_signed_bound_3329_16    = \<open>BC_3329_16.bar_signed_bound\<close>
      and bar_unsigned_bound_3329_16  = \<open>BC_3329_16.bar_unsigned_bound\<close>
      and bar_signed_bnd_at_3329_16   = \<open>BC_3329_16.bar_signed_bnd_at\<close>
      and bar_unsigned_bnd_at_3329_16 = \<open>BC_3329_16.bar_unsigned_bnd_at\<close>
  by standard (auto simp add: is_int_approx_round)

declare %internal BC_3329_16.bar_signed_max_eq[where K=1000, code]
declare %internal BC_3329_16.bar_unsigned_max_eq[where K=1000, code]

text\<open>\noindent We can now evaluate the theoretical bounds against the attained maxima:\<close>

lemma BC_3329_16_bounds:
    \<comment>\<open>Signed theoretical bound vs attained maximum\<close>
  shows \<open>bar_signed_max_3329_16 = 2160\<close>
    and \<open>bar_signed_bound_3329_16 = 2186\<close>
    \<comment>\<open>Unsigned theoretical bound vs attained maximum\<close>
    and \<open>bar_unsigned_max_3329_16 = 3798\<close>
    and \<open>bar_unsigned_bound_3329_16 = 3850\<close>
  by eval+

text %internal \<open>Register the above equations as code equations instead of the ones that were used
to compute them, so we can refer to them without re-evaluation:\<close>

declare %internal [[code drop: bar_signed_max_3329_16 bar_unsigned_max_3329_16]]
declare %internal BC_3329_16_bounds[code]

text \<open>Neither the signed nor the unsigned theoretical bound is attained, but with
  @{decimal (percentage, 1) "(bar_signed_bound_3329_16 - bar_signed_max_3329_16) /\<^sub>\<rat> bar_signed_bound_3329_16"} (signed) and
  @{decimal (percentage, 1) "(bar_unsigned_bound_3329_16 - bar_unsigned_max_3329_16) /\<^sub>\<rat> bar_unsigned_bound_3329_16"}  (unsigned) of slack.\<close>

section \<open>Example 3: \<open>N = 8380417\<close>, \<open>n = 32\<close> (ML-DSA modulus)\<close>

text\<open>In this section, we look at \<^term>\<open>N=8380417\<close>, the modulus underlying ML-DSA, together
with \<^term>\<open>n=32\<close> (ML-DSA is computed in 32-bit arithmetic). As before, we first instantiate
the Barrett context:\<close>

global_interpretation BC_8380417_32: BarrettContext 8380417 32 round
  defines bar_signed_max_8380417_32      = \<open>BC_8380417_32.bar_signed_max\<close>
      and bar_unsigned_max_8380417_32    = \<open>BC_8380417_32.bar_unsigned_max\<close>
      and bar_signed_bound_8380417_32    = \<open>BC_8380417_32.bar_signed_bound\<close>
      and bar_unsigned_bound_8380417_32  = \<open>BC_8380417_32.bar_unsigned_bound\<close>
      and bar_signed_bnd_at_8380417_32   = \<open>BC_8380417_32.bar_signed_bnd_at\<close>
      and bar_unsigned_bnd_at_8380417_32 = \<open>BC_8380417_32.bar_unsigned_bnd_at\<close>
  by standard (auto simp add: is_int_approx_round)

declare %internal BC_8380417_32.bar_signed_max_eq[where K=1000000, code]
declare %internal BC_8380417_32.bar_unsigned_max_eq[where K=1000000, code]

text\<open>\noindent We can now evaluate the theoretical bounds against the attained maxima:\<close>

lemma BC_8380417_32_bounds:
    \<comment>\<open>Signed theoretical bound vs attained maximum\<close>
  shows \<open>bar_signed_max_8380417_32 = 6283521\<close>
    and \<open>bar_signed_bound_8380417_32 = 6283521\<close>
    \<comment>\<open>Unsigned theoretical bound vs attained maximum\<close>
    and \<open>bar_unsigned_max_8380417_32 = 10469648\<close>
    and \<open>bar_unsigned_bound_8380417_32 = 10473729\<close>
  by eval+

text %internal \<open>Register the above equations as code equations instead of the ones that were used
to compute them, so we can refer to them without re-evaluation:\<close>

declare %internal [[code drop: bar_signed_max_8380417_32 bar_unsigned_max_8380417_32]]
declare %internal BC_8380417_32_bounds[code]

text \<open>The signed theoretical bound is achieved exactly. The unsigned bound is
not attained, but with
  @{decimal (percentage, 3) "(bar_unsigned_bound_8380417_32 - bar_unsigned_max_8380417_32) /\<^sub>\<rat> bar_unsigned_bound_8380417_32"}
of slack.\<close>
end

