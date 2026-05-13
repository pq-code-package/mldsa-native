/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA forward NTT -- shared kernel body.
 *
 * This file is #include'd by the thin wrapper .S files
 *   ntt_rv32im_asm.S         (fast multiplier: low(t*q) via a single mul)
 *   ntt_rv32im_slowmul_asm.S (slow multiplier: low(t*q) via shift-add)
 * which differ only in whether they #define
 * MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER before the include. It is not a
 * standalone translation unit: the backend guard, the .global directive,
 * and the simpasm header/footer markers live in the wrappers.
 *
 * Layered structure: 2+2+2+2 (four passes, each merging two layers, with
 * a radix-4 inner kernel holding 4 coefficients in registers).
 *
 * Modular arithmetic: Barrett multiplication by a constant twiddle.
 * Each zeta is provided as a (zeta, w) pair, where zeta is the plain
 * centered twiddle (w^{bitrev(k)} mod q, |zeta| <= q/2) and
 * w = round(zeta * 2^32 / q) is the Barrett multiplier, so a Barrett
 * multiply is 2 multiplies + a sparse "low(t*q)" reduction:
 *
 *   t  = hi(a * w)               ~ round(a * zeta / q)
 *   r  = low(a * zeta) - low(t * q)        == (a * zeta) mod q
 *
 * The low(t*q) reduction has two bit-identical forms (see mul_q_sub),
 * selected by MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER: a shift-add
 * exploiting q = 2^23 - 2^13 + 1 when defined, or a single low multiply
 * by q otherwise.
 *
 * The result is in the plain domain (no Montgomery factor), matching the
 * input/output convention of the previous Montgomery kernel, which folded
 * R into the twiddle and cancelled it via R^-1. Bound: |r| < 1.01 q.
 */

/*****************************************************************
 * Register aliases (RV32 GAS lacks `.req`; use cpp #defines).
 *****************************************************************/

/* Arguments */
#define in_ptr a0   /* base of int32_t r[256]       */
#define zeta_ptr a1 /* zeta cursor                  */

/* Working pointers / counters */
#define data t2      /* inner data cursor            */
#define outer_end t3 /* end address for outer loop   */
#define inner_end t4 /* end address for inner loop   */

/* Coefficient registers (caller-saved) */
#define ca a2
#define cb a3
#define cc a4
#define cd a5

/* Butterfly temporaries (caller-saved) */
#define tmp0 a6
#define tmp1 a7

/* Loaded zeta pair registers (callee-saved; loaded once per outer iter,
 * used across the inner loop). Each pair is (zeta, w): the plain centered
 * twiddle and its Barrett multiplier w = round(zeta * 2^32 / q). */
#define zeta_lo s0
#define zeta_lo_w s1
#define zeta_h0 s2
#define zeta_h0_w s3
#define zeta_h1 s4
#define zeta_h1_w s5

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
 * The reduction is the only multiplier-dependent step; the Barrett kernel,
 * butterflies and zeta table are shared.
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
 *   rd = (ra * rzeta) mod q   (plain domain, |rd| < 1.01 q).
 *
 * rzeta : plain centered twiddle (constant)
 * rw    : Barrett multiplier round(rzeta * 2^32 / q) (constant)
 *   t  = hi(ra * rw)
 *   rd = low(ra * rzeta) - low(t * q)
 * with low(t*q) computed by mul_q_sub. Clobbers: rt.
 */
.macro barrett rd, ra, rzeta, rw, rt
        mulh  \rt, \ra, \rw       /* t   = hi(ra * w)          */
        mul   \rd, \ra, \rzeta    /* azl = low(ra * zeta)      */
        mul_q_sub \rd, \rt        /* rd  = azl - low(t * q)    */
.endm

/* ct_bfly ra, rb, rzeta, rw, rt0, rt1 :
 *
 *   t  = barrett(rb, rzeta)
 *   rb = ra - t
 *   ra = ra + t
 *
 * Cooley-Tukey butterfly. Each application grows |coeff| by at most ~q.
 * Clobbers: rt0, rt1.
 */
.macro ct_bfly ra, rb, rzeta, rw, rt0, rt1
        barrett \rt0, \rb, \rzeta, \rw, \rt1
        sub  \rb, \ra, \rt0
        add  \ra, \ra, \rt0
.endm

/* radix4_kernel stride (in bytes):
 *
 * Reads four coefficients from offsets [0, s, 2s, 3s] of `data`, runs
 * two layers of CT butterflies using the loaded zeta pairs, writes back.
 */
.macro radix4_kernel stride
        lw   ca, 0(data)
        lw   cb, (1*\stride)(data)
        lw   cc, (2*\stride)(data)
        lw   cd, (3*\stride)(data)

        /* "Lo" layer: pair (ca,cc) and (cb,cd), both with zeta_lo. */
        ct_bfly ca, cc, zeta_lo, zeta_lo_w, tmp0, tmp1
        ct_bfly cb, cd, zeta_lo, zeta_lo_w, tmp0, tmp1

        /* "Hi" layer: (ca,cb) with zeta_h0, (cc,cd) with zeta_h1. */
        ct_bfly ca, cb, zeta_h0, zeta_h0_w, tmp0, tmp1
        ct_bfly cc, cd, zeta_h1, zeta_h1_w, tmp0, tmp1

        sw   ca, 0(data)
        sw   cb, (1*\stride)(data)
        sw   cc, (2*\stride)(data)
        sw   cd, (3*\stride)(data)
.endm

/* load_outer_zetas: load 3 (zeta, w) pairs (24 bytes) for one outer iter
 * from `zeta_ptr`, advancing it. */
.macro load_outer_zetas
        lw   zeta_lo,    0(zeta_ptr)
        lw   zeta_lo_w,  4(zeta_ptr)
        lw   zeta_h0,    8(zeta_ptr)
        lw   zeta_h0_w,  12(zeta_ptr)
        lw   zeta_h1,    16(zeta_ptr)
        lw   zeta_h1_w,  20(zeta_ptr)
        addi zeta_ptr, zeta_ptr, 24
.endm

/* save / restore the callee-saved regs s0..s5 we use. */
.macro save_regs
        addi sp, sp, -24
        sw   s0,  0(sp)
        sw   s1,  4(sp)
        sw   s2,  8(sp)
        sw   s3, 12(sp)
        sw   s4, 16(sp)
        sw   s5, 20(sp)
.endm

.macro restore_regs
        lw   s0,  0(sp)
        lw   s1,  4(sp)
        lw   s2,  8(sp)
        lw   s3, 12(sp)
        lw   s4, 16(sp)
        lw   s5, 20(sp)
        addi sp, sp, 24
.endm

/*****************************************************************
 * Function
 *
 * The MLD_ASM_FN_SYMBOL(ntt_rv32im_asm) entry label lives in the wrapper
 * .S file (next to its .global), so it is the first thing in .text.
 *****************************************************************/

        save_regs

#if !defined(MLD_RV32IM_INTERNAL_USE_SLOW_MULTIPLIER)
        /* q = 8380417 = 0x007FE001, for the multiply in mul_q_sub. */
        lui  q, 0x7FE
        addi q, q, 1
#endif

        /***************************************************
         * Pass 1: C-layers 1, 2.
         *   1 outer iter, 64 inner iters, butterfly stride = 256 B.
         ***************************************************/
        load_outer_zetas
        mv   data, in_ptr
        addi inner_end, in_ptr, 256       /* 64 * 4 B */
ntt_rv32im_p1_loop:
        radix4_kernel 256
        addi data, data, 4
        bne  data, inner_end, ntt_rv32im_p1_loop

        /***************************************************
         * Pass 2: C-layers 3, 4.
         *   4 outer iters, 16 inner iters each, stride = 64 B.
         *   Each outer block is 256 B (= 64 coefs).
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
ntt_rv32im_p2_outer:
        load_outer_zetas
        addi inner_end, data, 64          /* 16 * 4 B */
ntt_rv32im_p2_inner:
        radix4_kernel 64
        addi data, data, 4
        bne  data, inner_end, ntt_rv32im_p2_inner
        addi data, data, (256 - 64)       /* skip to next 256 B block */
        bne  data, outer_end, ntt_rv32im_p2_outer

        /***************************************************
         * Pass 3: C-layers 5, 6.
         *   16 outer iters, 4 inner iters each, stride = 16 B.
         *   Each outer block is 64 B (= 16 coefs).
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
ntt_rv32im_p3_outer:
        load_outer_zetas
        addi inner_end, data, 16          /* 4 * 4 B */
ntt_rv32im_p3_inner:
        radix4_kernel 16
        addi data, data, 4
        bne  data, inner_end, ntt_rv32im_p3_inner
        addi data, data, (64 - 16)        /* skip to next 64 B block */
        bne  data, outer_end, ntt_rv32im_p3_outer

        /***************************************************
         * Pass 4: C-layers 7, 8.
         *   64 outer iters, 1 inner iter each, stride = 4 B.
         *   Each outer iter handles 4 consecutive coefficients.
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
ntt_rv32im_p4_outer:
        load_outer_zetas
        radix4_kernel 4
        addi data, data, 16
        bne  data, outer_end, ntt_rv32im_p4_outer

        restore_regs
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros. */
#undef in_ptr
#undef zeta_ptr
#undef data
#undef outer_end
#undef inner_end
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
#undef q
