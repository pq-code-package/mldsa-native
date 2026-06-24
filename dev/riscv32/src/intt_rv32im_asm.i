/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA inverse NTT -- shared kernel body.
 *
 * This file is #include'd by the thin wrapper .S files
 *   intt_rv32im_asm.S         (fast multiplier: low(t*q) via a single mul)
 *   intt_rv32im_slowmul_asm.S (slow multiplier: low(t*q) via shift-add)
 * which differ only in whether they #define
 * MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER before the include. It is not a
 * standalone translation unit: the backend guard, the .global directive,
 * and the simpasm header/footer markers live in the wrappers.
 *
 * Layered structure: 2+2+2+2 (mirror of the forward NTT, with passes
 * applied in reverse layer order). Each pass merges two C-layers into a
 * radix-4 inner kernel that holds 4 coefficients in registers.
 *
 *   inv-pass-1: C-layers 8, 7   (inner stride =  4 B,  64 outer iters)
 *   inv-pass-2: C-layers 6, 5   (inner stride = 16 B,  16 outer iters)
 *   inv-pass-3: C-layers 4, 3   (inner stride = 64 B,   4 outer iters)
 *   inv-pass-4: C-layers 2, 1   (inner stride = 256 B,  1 outer iter )
 *
 * Twiddles: this routine reuses `mld_rv32im_ntt_zetas` (the forward-NTT
 * table). The forward pass-(5-k) consumes its 3*N_outer pairs in
 * outer order 0,1,...,N-1; the inv pass-k requires the *same* zetas but
 * in reverse outer order, with the two "hi" zetas swapped. We implement
 * this by initializing zeta_ptr at the end of each pass region and
 * subtracting 24 bytes per outer iter; within the iter the lo zeta is
 * read from offset 0 and the hi zetas from offsets 8/16 swapped via the
 * GS kernel argument order. The negation that the C reference applies
 * (`-mld_zetas[k]`) is absorbed by the GS butterfly form
 *      a' = a + b
 *      b' = barrett(b - a, +zeta)
 * which produces the same result as the canonical
 *      t  = a; a' = t + b; b' = barrett(t - b, -zeta).
 *
 * Modular arithmetic: Barrett multiplication by a constant twiddle
 * (2-mul kernel  t = hi(a*w), r = low(a*zeta) - low(t*q)), matching the
 * forward NTT. Each zeta is a (zeta, w) pair (plain centered twiddle and
 * its Barrett multiplier). The plain-domain result matches the previous
 * Montgomery convention. The low(t*q) reduction has two bit-identical
 * forms (see mul_q_sub), selected by
 * MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER: shift-add or a single multiply.
 *
 * Final scaling: after the four passes, every coefficient is multiplied
 * by the plain twiddle  f = 16382 = R * 2^{-8} mod q  (= 2^24 mod q),
 * which folds in both the 2^{-8} of the inverse NTT and the R factor of
 * the previous Montgomery output convention. This uses a rounding Barrett
 * (see barrett_round): a doubled multiplier round(f*2^33/q) and a (t+1)>>1
 * round-to-nearest of the quotient, tightening the output to |coef| < q
 * (measured <= 0.503 q). The truncating Barrett of the butterflies gives
 * |coef| < 1.01 q, so the rounding form is used here to meet the invntt
 * output contract of |coef| < q.
 *
 * Bounds (after each inv-pass):
 *
 *   start                       :  |coef| < q          (= 1*q)
 *   after inv-pass-1 (C-L 8,7)  :  |coef| < 4*q
 *   after inv-pass-2 (C-L 6,5)  :  |coef| < 16*q
 *   after inv-pass-3 (C-L 4,3)  :  |coef| < 64*q
 *   after inv-pass-4 (C-L 2,1)  :  |coef| < 256*q   (~ 2^31, fits int32)
 *   after final fqscale         :  |coef| < q       (rounding Barrett)
 */

/*****************************************************************
 * Register aliases
 *****************************************************************/

/* Arguments */
#define in_ptr a0
#define zeta_ptr a1

/* Working pointers / counters */
#define data t2
#define outer_end t3
#define inner_end t4
#define scale_end t5 /* end pointer for final-scaling loop  */

/* Coefficient registers */
#define ca a2
#define cb a3
#define cc a4
#define cd a5

/* Butterfly temporaries */
#define tmp0 a6
#define tmp1 a7

/* Loaded zeta pair registers. Each pair is (zeta, w): the plain centered
 * twiddle and its Barrett multiplier w = round(zeta * 2^32 / q). */
#define zeta_lo s0
#define zeta_lo_w s1
#define zeta_h0 s2
#define zeta_h0_w s3
#define zeta_h1 s4
#define zeta_h1_w s5

/* Constants (used only by the Barrett final-scale post-loop). */
#define f s6    /* plain fqscale: 16382 = R*2^-8 mod q */
#define f_w2 s7 /* doubled Barrett mult: round(f*2^33/q) */

/* Constant q register, used only by mul_q_sub when
 * MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER is undefined. t0 is caller-saved
 * and otherwise unused, so no extra save/restore is needed. */
#define q t0 /* MLDSA_Q = 8380417            */

/*****************************************************************
 * Macros
 *****************************************************************/

/* mul_q_sub rd, rt :
 *
 *   rd = rd - low(rt * q)   (mod 2^32),  clobbers rt.
 *
 * Two bit-identical implementations, selected by
 * MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER:
 *
 *   defined   : shift-add, exploiting q = 2^23 - 2^13 + 1, no multiply.
 *   undefined : single low multiply by q (q held in `q`).
 *
 * The reduction is the only multiplier-dependent step; the Barrett kernels,
 * butterflies, final scaling and zeta table are shared.
 */
.macro mul_q_sub rd, rt
#if defined(MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER)
        sub  \rd, \rd, \rt        /* - rt                      */
        slli \rt, \rt, 13
        add  \rd, \rd, \rt        /* + (rt<<13)                */
        slli \rt, \rt, 10
        sub  \rd, \rd, \rt        /* - (rt<<23) => - low(rt*q) */
#else  /* MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER */
        mul  \rt, \rt, q          /* low(rt * q)               */
        sub  \rd, \rd, \rt
#endif /* !MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER */
.endm

/* barrett rd, ra, rzeta, rw, rt :
 *
 *   rd = (ra * rzeta) mod q   (plain domain, |rd| < 1.01 q).  Clobbers: rt.
 *   t  = hi(ra * rw) ; rd = low(ra * rzeta) - low(t * q).
 *
 * Uses a truncating quotient estimate t = hi(ra * w) with
 * w = round(rzeta * 2^32 / q). Good enough for the butterfly bound.
 */
.macro barrett rd, ra, rzeta, rw, rt
        mulh  \rt, \ra, \rw       /* t   = hi(ra * w)          */
        mul   \rd, \ra, \rzeta    /* azl = low(ra * zeta)      */
        mul_q_sub \rd, \rt        /* rd  = azl - low(t * q)    */
.endm

/* barrett_round rd, ra, rf, rf_w2, rt :
 *
 *   rd = (ra * rf) mod q   (plain domain, |rd| < q).  Clobbers: rt.
 *
 * Rounding Barrett: instead of the truncating hi(ra*w) of `barrett`, it
 * uses the doubled multiplier  rf_w2 = round(rf * 2^33 / q)  and recovers a
 * round-to-nearest quotient by  qhat = (hi(ra*rf_w2) + 1) >> 1:
 *   t    = hi(ra * rf_w2)        ~ floor(2 * ra * rf / q)
 *   qhat = (t + 1) >> 1          ~ round(ra * rf / q)
 *   rd   = low(ra * rf) - low(qhat * q)
 * The round-to-nearest quotient gives the tighter bound |rd| < q (measured
 * <= 0.503 q), versus |rd| < 1.01 q for the truncating `barrett`.
 *
 * rf_w2 fits int32 only because rf is small (here 16382); a general twiddle
 * up to q/2 would overflow the doubled constant. Final scaling only.
 */
.macro barrett_round rd, ra, rf, rf_w2, rt
        mulh  \rt, \ra, \rf_w2    /* t    = hi(ra * (2*f)~)    */
        addi  \rt, \rt, 1
        srai  \rt, \rt, 1         /* qhat = (t + 1) >> 1       */
        mul   \rd, \ra, \rf       /* azl  = low(ra * f)        */
        mul_q_sub \rd, \rt        /* rd   = azl - low(qhat*q)  */
.endm

/* gs_bfly ra, rb, rzeta, rw, rt0, rt1 :
 *
 *   t  = rb - ra
 *   ra = ra + rb
 *   rb = barrett(t, +rzeta)
 *
 * Gentleman-Sande butterfly. Each application grows |coef| by a factor of 2
 * (or by ~q, whichever is greater): the additive part doubles, the
 * multiplicative part is bounded by ~q.
 *
 * The algebraic equivalence with the C reference's
 *      t = ra; ra = t + rb; rb = barrett(t - rb, -zeta)
 * follows from barrett being linear in its constant:
 *      barrett(t - rb, -zeta) = -barrett(t - rb, +zeta)
 *                             =  barrett(rb - t, +zeta)
 *                             =  barrett(rb - ra, +zeta)       (t == ra)
 * which is what this macro computes. This lets us reuse the (un-negated)
 * forward-NTT zeta table.
 *
 * Clobbers: rt0, rt1.
 */
.macro gs_bfly ra, rb, rzeta, rw, rt0, rt1
        sub  \rt0, \rb, \ra
        add  \ra,  \ra, \rb
        barrett \rb, \rt0, \rzeta, \rw, \rt1
.endm

/* gs_radix4 stride :
 *
 * Reads four coefficients from offsets [0, s, 2s, 3s] of `data`,
 * applies the inverse-NTT radix-4 kernel using the loaded zetas,
 * writes them back.
 *
 * Within a single inv-pass:
 *   - "Inner" layer (the smaller-stride C-layer, run first) pairs
 *     (a,b) and (c,d). The C reference uses two distinct zetas here
 *     (k = (1<<L_in)-1-2o and (1<<L_in)-2-2o), which appear in our
 *     table in fwd order as (h0, h1). With the cursor walked
 *     backward, position offsets remain (h0=8, h1=16); the inv
 *     consumption order swaps them: (a,b) gets h1, (c,d) gets h0.
 *   - "Outer" layer (the larger-stride C-layer, run second) pairs
 *     (a,c) and (b,d) with a single shared zeta = lo.
 */
.macro gs_radix4 stride
        lw   ca, 0(data)
        lw   cb, (1*\stride)(data)
        lw   cc, (2*\stride)(data)
        lw   cd, (3*\stride)(data)

        /* Inner C-layer (smaller stride): (a,b) gets h1, (c,d) gets h0. */
        gs_bfly ca, cb, zeta_h1, zeta_h1_w, tmp0, tmp1
        gs_bfly cc, cd, zeta_h0, zeta_h0_w, tmp0, tmp1

        /* Outer C-layer (larger stride): (a,c) and (b,d), shared lo. */
        gs_bfly ca, cc, zeta_lo, zeta_lo_w, tmp0, tmp1
        gs_bfly cb, cd, zeta_lo, zeta_lo_w, tmp0, tmp1

        sw   ca, 0(data)
        sw   cb, (1*\stride)(data)
        sw   cc, (2*\stride)(data)
        sw   cd, (3*\stride)(data)
.endm

/* load_outer_zetas_rev:
 *
 *   zeta_ptr -= 24
 *   load (lo, lo_w, h0, h0_w, h1, h1_w) from [zeta_ptr+0..+23]
 *
 * Walks the forward-NTT zeta table backward, one outer-iter pair set
 * (24 bytes) at a time.
 */
.macro load_outer_zetas_rev
        addi zeta_ptr, zeta_ptr, -24
        lw   zeta_lo,    0(zeta_ptr)
        lw   zeta_lo_w,  4(zeta_ptr)
        lw   zeta_h0,    8(zeta_ptr)
        lw   zeta_h0_w,  12(zeta_ptr)
        lw   zeta_h1,    16(zeta_ptr)
        lw   zeta_h1_w,  20(zeta_ptr)
.endm

/* save / restore the callee-saved regs s0..s7 we use. */
.macro save_regs
        addi sp, sp, -32
        sw   s0,  0(sp)
        sw   s1,  4(sp)
        sw   s2,  8(sp)
        sw   s3, 12(sp)
        sw   s4, 16(sp)
        sw   s5, 20(sp)
        sw   s6, 24(sp)
        sw   s7, 28(sp)
.endm

.macro restore_regs
        lw   s0,  0(sp)
        lw   s1,  4(sp)
        lw   s2,  8(sp)
        lw   s3, 12(sp)
        lw   s4, 16(sp)
        lw   s5, 20(sp)
        lw   s6, 24(sp)
        lw   s7, 28(sp)
        addi sp, sp, 32
.endm

/*****************************************************************
 * Function
 *
 * The MLD_ASM_FN_SYMBOL(intt_rv32im_asm) entry label lives in the wrapper
 * .S file (next to its .global), so it is the first thing in .text.
 *****************************************************************/

        save_regs

#if !defined(MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER)
        /* q = 8380417 = 0x007FE001, for the multiply in mul_q_sub (used by
         * both the butterflies and the final Barrett scaling). */
        lui  q, 0x7FE
        addi q, q, 1
#endif /* !MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER */

        /* Position zeta_ptr at the END of the table (one past last entry).
         * The table has 255 pairs = 510 int32 = 2040 bytes. */
        addi zeta_ptr, zeta_ptr, 2040

        /***************************************************
         * inv-pass-1: C-layers 8, 7.
         *   64 outer iters, 1 inner iter each, stride = 4 B.
         *   Each outer iter handles 4 consecutive coefficients.
         *
         * Reads fwd-pass-4's 64 outer iters in reverse order.
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
intt_rv32im_p1_outer:
        load_outer_zetas_rev
        gs_radix4 4
        addi data, data, 16
        bne  data, outer_end, intt_rv32im_p1_outer

        /***************************************************
         * inv-pass-2: C-layers 6, 5.
         *   16 outer iters, 4 inner iters each, stride = 16 B.
         *   Each outer block is 64 B (= 16 coefs).
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
intt_rv32im_p2_outer:
        load_outer_zetas_rev
        addi inner_end, data, 16          /* 4 * 4 B */
intt_rv32im_p2_inner:
        gs_radix4 16
        addi data, data, 4
        bne  data, inner_end, intt_rv32im_p2_inner
        addi data, data, (64 - 16)        /* skip to next 64 B block */
        bne  data, outer_end, intt_rv32im_p2_outer

        /***************************************************
         * inv-pass-3: C-layers 4, 3.
         *   4 outer iters, 16 inner iters each, stride = 64 B.
         *   Each outer block is 256 B (= 64 coefs).
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
intt_rv32im_p3_outer:
        load_outer_zetas_rev
        addi inner_end, data, 64          /* 16 * 4 B */
intt_rv32im_p3_inner:
        gs_radix4 64
        addi data, data, 4
        bne  data, inner_end, intt_rv32im_p3_inner
        addi data, data, (256 - 64)
        bne  data, outer_end, intt_rv32im_p3_outer

        /***************************************************
         * inv-pass-4: C-layers 2, 1.
         *   1 outer iter, 64 inner iters, stride = 256 B.
         ***************************************************/
        load_outer_zetas_rev
        mv   data, in_ptr
        addi inner_end, in_ptr, 256       /* 64 * 4 B */
intt_rv32im_p4_inner:
        gs_radix4 256
        addi data, data, 4
        bne  data, inner_end, intt_rv32im_p4_inner

        /***************************************************
         * Final scaling: each coefficient *= 16382  (plain, rounding Barrett).
         *
         * f    = 16382 = R * 2^{-8} mod q = 2^24 mod q   (plain twiddle;
         *        folds in both the 2^{-8} of the inverse NTT and the R
         *        factor of the previous Montgomery output convention).
         * f_w2 = round(f * 2^33 / q) = 16791564           (doubled Barrett
         *        multiplier, fits int32 because f is small).
         *
         * Rounding Barrett (see barrett_round) yields |coef| < q, restoring
         * the invntt output contract that the plain butterflies would miss.
         ***************************************************/
        li   f,    16382
        li   f_w2, 16791564

        mv   data, in_ptr
        addi scale_end, in_ptr, 1024
intt_rv32im_scale:
        lw   ca, 0(data)
        barrett_round cb, ca, f, f_w2, tmp0
        sw   cb, 0(data)
        addi data, data, 4
        bne  data, scale_end, intt_rv32im_scale

        restore_regs
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros. */
#undef in_ptr
#undef zeta_ptr
#undef data
#undef outer_end
#undef inner_end
#undef scale_end
#undef ca
#undef cb
#undef cc
#undef cd
#undef tmp0
#undef tmp1
#undef zeta_lo
#undef zeta_lo_w
#undef zeta_h0
#undef zeta_h0_w
#undef zeta_h1
#undef zeta_h1_w
#undef f
#undef f_w2
#undef q
