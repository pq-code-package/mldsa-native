/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA forward NTT -- shared kernel body.
 *
 * This file is #include'd by mldsa_ntt_rv32im_asm.S. It is not a standalone
 * translation unit: the backend guard, the .global directive, and the
 * simpasm header/footer markers live in the wrapper.
 *
 * Layered structure: 2+2+2+2 (four passes, each merging two layers, with
 * a radix-4 inner kernel holding 4 coefficients in registers).
 *
 * Modular arithmetic: Barrett multiplication by a constant twiddle. Write
 * R = 2^32 and q = MLDSA_Q = 8380417. Each table entry is a pair (zeta, w),
 * where zeta is the signed-canonical twiddle, |zeta| <= q/2, and
 * w = round(zeta*R/q). The `barrett` macro computes
 *
 *   t = floor(a*w/R)
 *   r = (a*zeta - t*q) mod R.
 *
 * Thus r == a*zeta (mod q). Moreover, |w-zeta*R/q| <= 1/2 and |a| < R/2
 * imply |a*zeta/q-t| < 5/4. Once the low word is interpreted as a signed
 * integer, this gives
 *
 *   |r| < B,  B = ceil(5q/4) = 10475522.
 *
 * This is the coarse bound for unsigned-style Barrett multiplication proved
 * in @[NeonNTT_Autoformalised, Section 13.2]. The RV32 `mul`/`mulh` followed
 * by the low-word multiplication by q and subtraction implements the same
 * MUL/MULH/MLS word computation used there.
 *
 * The NTT starts with |coefficient| < q < B. Every Cooley-Tukey layer adds
 * one value bounded by B, so after eight layers all coefficients satisfy
 *
 *   |coefficient| < 9B = 94279698 = MLD_NTT_BOUND < 2^31.
 *
 * MLD_NTT_BOUND is the exclusive postcondition of the generic C and native
 * NTT interfaces, and the exclusive input precondition of pointwise
 * Montgomery multiplication. Thus the calculation above establishes the
 * bound needed for this kernel to satisfy the C/CBMC-facing NTT contract and
 * feed pointwise multiplication; it is not merely an internal overflow
 * bound.
 *
 * All additions and subtractions therefore have their mathematical result
 * in signed int32 range. The low-word multiplies deliberately operate modulo
 * R, exactly as specified by RV32. The final representative is unique because
 * B < R/2.
 *
 * The result is in the plain domain (no Montgomery factor). This is the same
 * domain as the C NTT: a Montgomery formulation would fold R into each
 * twiddle and immediately cancel it with R^-1.
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

/* Constant q register used by mul_q_sub. t0 is caller-saved and otherwise
 * unused, so no extra save/restore is needed. */
#define q t0 /* MLDSA_Q = 8380417            */

/*****************************************************************
 * Macros
 *****************************************************************/

/* mul_q_sub rd, rt :
 *
 *   rd = rd - low(rt*q)  (mod R), clobbering rt.
 *
 * q is held in the `q` register. The low multiplication and subtraction
 * intentionally retain only the low word modulo R.
 */
.macro mul_q_sub rd, rt
        mul  \rt, \rt, q          /* low(rt * q)               */
        sub  \rd, \rd, \rt
.endm

/* barrett rd, ra, rzeta, rw, rt :
 *
 *   rd == ra*rzeta (mod q), with |rd| < B = ceil(5q/4).
 *
 * rzeta : plain centered twiddle (constant)
 * rw    : Barrett multiplier round(rzeta * 2^32 / q) (constant)
 * `mulh` is the signed floor t = floor(ra*rw/R); `mul` retains the low
 * word. `mul_q_sub` therefore leaves a value congruent to ra*rzeta modulo q.
 * The error argument in the file header gives the bound whenever |ra| < R/2,
 * which holds at every call below. Clobbers: rt.
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
 * Cooley-Tukey butterfly. If |ra| < A and |rb| < R/2 on entry, `barrett`
 * gives |t| < B and both outputs are bounded by A+B. Every call below has
 * A+B <= 9B < R/2, so the `add` and `sub` do not overflow signed int32.
 * Clobbers: rt0, rt1.
 */
.macro ct_bfly ra, rb, rzeta, rw, rt0, rt1
        barrett \rt0, \rb, \rzeta, \rw, \rt1
        sub  \rb, \ra, \rt0
        add  \ra, \ra, \rt0
.endm

/* radix4_kernel stride (in bytes):
 *
 * Reads four coefficients from offsets [0, s, 2s, 3s] of `data`, runs two
 * layers of CT butterflies using the loaded zeta pairs, and writes them back.
 * If the four inputs are bounded by A, the first layer is bounded by A+B and
 * the second by A+2B.
 */
.macro radix4_kernel stride
        lw   ca, 0(data)
        lw   cb, (1*\stride)(data)
        lw   cc, (2*\stride)(data)
        lw   cd, (3*\stride)(data)

        /* "Lo" layer: pair (ca,cc) and (cb,cd), both with zeta_lo. */
        ct_bfly ca, cc, zeta_lo, zeta_lo_w, tmp0, tmp1
        ct_bfly cb, cd, zeta_lo, zeta_lo_w, tmp0, tmp1
        /* Bounds: |ca|, |cb|, |cc|, |cd| < A+B. */

        /* "Hi" layer: (ca,cb) with zeta_h0, (cc,cd) with zeta_h1. */
        ct_bfly ca, cb, zeta_h0, zeta_h0_w, tmp0, tmp1
        ct_bfly cc, cd, zeta_h1, zeta_h1_w, tmp0, tmp1
        /* Bounds: |ca|, |cb|, |cc|, |cd| < A+2B. */

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

/* Save/restore the ILP32 ABI callee-saved registers s0..s5 used below. The
 * 32-byte frame preserves the required 16-byte stack alignment; the final two
 * words are padding. */
.macro save_regs
        addi sp, sp, -32
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
        addi sp, sp, 32
.endm

/*****************************************************************
 * Function
 *
 * The MLD_ASM_FN_SYMBOL(ntt_rv32im_asm) entry label lives in the wrapper
 * .S file (next to its .global), so it is the first thing in .text.
 *****************************************************************/

        save_regs

        /* q = 8380417 = 0x007FE001, for the multiply in mul_q_sub. */
        lui  q, 0x7FE
        addi q, q, 1

        /***************************************************
         * Pass 1: C-layers 1, 2.
         *   1 outer iter, 64 inner iters, butterfly stride = 256 B.
         *   Input bound q < B; output bound q+2B < 3B.
         ***************************************************/
        load_outer_zetas
        mv   data, in_ptr
        addi inner_end, in_ptr, 256       /* 64 * 4 B */
mld_ntt_rv32im_p1_loop:
        radix4_kernel 256
        addi data, data, 4
        bne  data, inner_end, mld_ntt_rv32im_p1_loop
        /* Bounds after layers 1-2: |r[i]| < 3B. */

        /***************************************************
         * Pass 2: C-layers 3, 4.
         *   4 outer iters, 16 inner iters each, stride = 64 B.
         *   Each outer block is 256 B (= 64 coefs).
         *   Input bound 3B; output bound 5B.
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
mld_ntt_rv32im_p2_outer:
        load_outer_zetas
        addi inner_end, data, 64          /* 16 * 4 B */
mld_ntt_rv32im_p2_inner:
        radix4_kernel 64
        addi data, data, 4
        bne  data, inner_end, mld_ntt_rv32im_p2_inner
        addi data, data, (256 - 64)       /* skip to next 256 B block */
        bne  data, outer_end, mld_ntt_rv32im_p2_outer
        /* Bounds after layers 3-4: |r[i]| < 5B. */

        /***************************************************
         * Pass 3: C-layers 5, 6.
         *   16 outer iters, 4 inner iters each, stride = 16 B.
         *   Each outer block is 64 B (= 16 coefs).
         *   Input bound 5B; output bound 7B.
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
mld_ntt_rv32im_p3_outer:
        load_outer_zetas
        addi inner_end, data, 16          /* 4 * 4 B */
mld_ntt_rv32im_p3_inner:
        radix4_kernel 16
        addi data, data, 4
        bne  data, inner_end, mld_ntt_rv32im_p3_inner
        addi data, data, (64 - 16)        /* skip to next 64 B block */
        bne  data, outer_end, mld_ntt_rv32im_p3_outer
        /* Bounds after layers 5-6: |r[i]| < 7B. */

        /***************************************************
         * Pass 4: C-layers 7, 8.
         *   64 outer iters, 1 inner iter each, stride = 4 B.
         *   Each outer iter handles 4 consecutive coefficients.
         *   Input bound 7B; output bound 9B = MLD_NTT_BOUND.
         ***************************************************/
        mv   data, in_ptr
        addi outer_end, in_ptr, 1024
mld_ntt_rv32im_p4_outer:
        load_outer_zetas
        radix4_kernel 4
        addi data, data, 16
        bne  data, outer_end, mld_ntt_rv32im_p4_outer
        /* Bounds after layers 7-8: |r[i]| < 9B = 94279698 < 2^31. */

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
