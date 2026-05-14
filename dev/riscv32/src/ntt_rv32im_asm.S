/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA forward NTT.
 *
 * Layered structure: 2+2+2+2 (four passes, each merging two layers, with
 * a radix-4 inner kernel holding 4 coefficients in registers).
 *
 * Modular arithmetic: standard signed Montgomery multiplication.
 * Each zeta is provided in Montgomery form (R * w^{bitrev(k)} mod q,
 * R = 2^32) along with its precomputed twist  z' = (z * QINV) mod 2^32,
 * so a Montgomery multiply is 3 multiplies + 1 sub:
 *
 *   m  = low(a * z')
 *   r  = hi(a * z) - hi(m * q)
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

/*****************************************************************
 * Register aliases (RV32 GAS lacks `.req`; use cpp #defines).
 *****************************************************************/

/* Arguments */
#define in_ptr      a0      /* base of int32_t r[256]       */
#define zeta_ptr    a1      /* zeta cursor                  */

/* Working pointers / counters */
#define data        t2      /* inner data cursor            */
#define outer_end   t3      /* end address for outer loop   */
#define inner_end   t4      /* end address for inner loop   */

/* Coefficient registers (caller-saved) */
#define ca          a2
#define cb          a3
#define cc          a4
#define cd          a5

/* Butterfly temporaries (caller-saved) */
#define tmp0        a6
#define tmp1        a7

/* Loaded zeta pair registers (callee-saved; loaded once per outer iter,
 * used across the inner loop). */
#define zeta_lo     s0
#define zeta_lo_tw  s1
#define zeta_h0     s2
#define zeta_h0_tw  s3
#define zeta_h1     s4
#define zeta_h1_tw  s5

/* Constants */
#define q           s6      /* MLDSA_Q = 8380417            */

/*****************************************************************
 * Macros
 *****************************************************************/

/* montmul rd, ra, rb, rb_tw, rt :
 *
 *   rd = (ra * rb) * R^-1 mod q  (signed Montgomery, R = 2^32).
 *
 * Uses the precomputed twist  rb_tw = (rb * QINV) mod 2^32  so that
 *   (ra * rb * QINV) mod 2^32  ==  low(ra * rb_tw),
 * giving the standard 3-mul kernel
 *   m  = low(ra * rb_tw)
 *   rd = hi(ra * rb) - hi(m * q).
 *
 * Bound: |rd| < q (signed Montgomery bound).
 * Clobbers: rt.
 */
.macro montmul rd, ra, rb, rb_tw, rt
        mul   \rt, \ra, \rb_tw    /* low(ra * rb_tw) = m       */
        mulh  \rd, \ra, \rb       /* hi(ra * rb)               */
        mulh  \rt, \rt, q         /* hi(m * q)                 */
        sub   \rd, \rd, \rt
.endm

/* ct_bfly ra, rb, rzeta, rzeta_tw, rt0, rt1 :
 *
 *   t  = montmul(rb, rzeta)
 *   rb = ra - t
 *   ra = ra + t
 *
 * Cooley-Tukey butterfly. Each application grows |coeff| by at most q.
 * Clobbers: rt0, rt1.
 */
.macro ct_bfly ra, rb, rzeta, rzeta_tw, rt0, rt1
        montmul \rt0, \rb, \rzeta, \rzeta_tw, \rt1
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
        ct_bfly ca, cc, zeta_lo, zeta_lo_tw, tmp0, tmp1
        ct_bfly cb, cd, zeta_lo, zeta_lo_tw, tmp0, tmp1

        /* "Hi" layer: (ca,cb) with zeta_h0, (cc,cd) with zeta_h1. */
        ct_bfly ca, cb, zeta_h0, zeta_h0_tw, tmp0, tmp1
        ct_bfly cc, cd, zeta_h1, zeta_h1_tw, tmp0, tmp1

        sw   ca, 0(data)
        sw   cb, (1*\stride)(data)
        sw   cc, (2*\stride)(data)
        sw   cd, (3*\stride)(data)
.endm

/* load_outer_zetas: load 3 zeta pairs (24 bytes) for one outer iter
 * from `zeta_ptr`, advancing it. */
.macro load_outer_zetas
        lw   zeta_lo,    0(zeta_ptr)
        lw   zeta_lo_tw, 4(zeta_ptr)
        lw   zeta_h0,    8(zeta_ptr)
        lw   zeta_h0_tw, 12(zeta_ptr)
        lw   zeta_h1,    16(zeta_ptr)
        lw   zeta_h1_tw, 20(zeta_ptr)
        addi zeta_ptr, zeta_ptr, 24
.endm

/* save / restore the callee-saved regs s0..s6 we use. */
.macro save_regs
        addi sp, sp, -32
        sw   s0,  0(sp)
        sw   s1,  4(sp)
        sw   s2,  8(sp)
        sw   s3, 12(sp)
        sw   s4, 16(sp)
        sw   s5, 20(sp)
        sw   s6, 24(sp)
.endm

.macro restore_regs
        lw   s0,  0(sp)
        lw   s1,  4(sp)
        lw   s2,  8(sp)
        lw   s3, 12(sp)
        lw   s4, 16(sp)
        lw   s5, 20(sp)
        lw   s6, 24(sp)
        addi sp, sp, 32
.endm

/*****************************************************************
 * Function
 *****************************************************************/

        .text
        .global MLD_ASM_NAMESPACE(ntt_rv32im_asm)
        .balign 4
MLD_ASM_FN_SYMBOL(ntt_rv32im_asm)

        save_regs

        /* q = 8380417 = 0x7FE001.
         * lui loads q << 12; we want the upper 20 bits of 0x007FE001 = 0x007FE,
         * so lui q, 0x7FE; then addi q, q, 1 -> 0x007FE001.
         * (Keeps everything within signed 12-bit immediate range.) */
        lui  q, 0x7FE
        addi q, q, 1

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

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
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
#undef zeta_lo_tw
#undef zeta_h0
#undef zeta_h0_tw
#undef zeta_h1
#undef zeta_h1_tw
#undef q

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
