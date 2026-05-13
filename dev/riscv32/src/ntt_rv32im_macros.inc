/*
 * Copyright (c) 2024 Jipeng Zhang and the PQRV authors
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: MIT
 */

/*
 * Shared assembler macros for the RV32IM NTT and inverse-NTT kernels.
 * Included from both `ntt_rv32im_asm.S` and `intt_rv32im_asm.S`. Each
 * file then assembles to its own translation unit, so this fragment is
 * never included twice into the same `.o`.
 */

.macro mld_rv32im_save_regs
    sw s0,  0*4(sp)
    sw s1,  1*4(sp)
    sw s2,  2*4(sp)
    sw s3,  3*4(sp)
    sw s4,  4*4(sp)
    sw s5,  5*4(sp)
    sw s6,  6*4(sp)
    sw s7,  7*4(sp)
    sw s8,  8*4(sp)
    sw s9,  9*4(sp)
    sw s10, 10*4(sp)
    sw s11, 11*4(sp)
    sw gp,  12*4(sp)
    sw tp,  13*4(sp)
    sw ra,  14*4(sp)
.endm

.macro mld_rv32im_restore_regs
    lw s0,  0*4(sp)
    lw s1,  1*4(sp)
    lw s2,  2*4(sp)
    lw s3,  3*4(sp)
    lw s4,  4*4(sp)
    lw s5,  5*4(sp)
    lw s6,  6*4(sp)
    lw s7,  7*4(sp)
    lw s8,  8*4(sp)
    lw s9,  9*4(sp)
    lw s10, 10*4(sp)
    lw s11, 11*4(sp)
    lw gp,  12*4(sp)
    lw tp,  13*4(sp)
    lw ra,  14*4(sp)
.endm

.macro mld_rv32im_load_coeffs len, poly
    lw t0, \len*4*0(\poly)
    lw t1, \len*4*1(\poly)
    lw t2, \len*4*2(\poly)
    lw t3, \len*4*3(\poly)
    lw t4, \len*4*4(\poly)
    lw t5, \len*4*5(\poly)
    lw t6, \len*4*6(\poly)
    lw tp, \len*4*7(\poly)
.endm

.macro mld_rv32im_store_coeffs len, poly
    sw t0, \len*4*0(\poly)
    sw t1, \len*4*1(\poly)
    sw t2, \len*4*2(\poly)
    sw t3, \len*4*3(\poly)
    sw t4, \len*4*4(\poly)
    sw t5, \len*4*5(\poly)
    sw t6, \len*4*6(\poly)
    sw tp, \len*4*7(\poly)
.endm

.macro mld_rv32im_load_zetas
    lw s0,  0*4(a1)
    lw s1,  1*4(a1)
    lw s2,  2*4(a1)
    lw s3,  3*4(a1)
    lw s4,  4*4(a1)
    lw s5,  5*4(a1)
    lw s6,  6*4(a1)
    lw s7,  7*4(a1)
    lw s8,  8*4(a1)
    lw s9,  9*4(a1)
    lw s10, 10*4(a1)
    lw s11, 11*4(a1)
    lw gp,  12*4(a1)
    lw ra,  13*4(a1)
.endm

.macro mld_rv32im_load_zetas_short
    lw s0,  0*4(a1)
    lw s1,  1*4(a1)
    lw s2,  2*4(a1)
    lw s3,  3*4(a1)
    lw s4,  4*4(a1)
    lw s5,  5*4(a1)
    lw s6,  6*4(a1)
    lw s7,  7*4(a1)
    lw s8,  8*4(a1)
    lw s9,  9*4(a1)
    lw s10, 10*4(a1)
    lw s11, 11*4(a1)
.endm

/* Signed Montgomery reduction.
 *
 * In:  a, b (the actual zeta in signed Mont form),
 *      bqinv = low(b * qinv mod 2^32)
 * Out: r = a*b * 2^{-32} mod q
 */
.macro mld_rv32im_montmul r, a, b, bqinv, q, t
    mul  \r, \a, \bqinv
    mulh \t, \a, \b
    mulh \r, \r, \q
    sub  \r, \t, \r
.endm

/* In-place Montgomery reduction:  a = a*b * 2^{-32} mod q.
 *
 * Used by the inverse NTT to fold the 1/256 final scaling into the same
 * primitive used everywhere else, by passing inv256 as `b`. */
.macro mld_rv32im_montmul_inplace a, b, bqinv, q, t
    mul  \t, \a, \bqinv
    mulh \a, \a, \b
    mulh \t, \t, \q
    sub  \a, \a, \t
.endm

/* Cooley-Tukey forward butterfly: (in0, in1) -> (in0 + t, in0 - t),
 * where t = mont_red(in1 * zeta). */
.macro mld_rv32im_ct_bfu in0, in1, zeta, zetaqinv, q, tmp0, tmp1
    mld_rv32im_montmul \tmp0, \in1, \zeta, \zetaqinv, \q, \tmp1
    sub \in1, \in0, \tmp0
    add \in0, \in0, \tmp0
.endm

/* Gentleman-Sande inverse butterfly: (in0, in1) -> (in0 + in1,
 * mont_red((in0 - in1) * zeta)). */
.macro mld_rv32im_gs_bfu in0, in1, zeta, zetaqinv, q, tmp0, tmp1
    sub \tmp0, \in0, \in1
    add \in0, \in0, \in1
    mld_rv32im_montmul \in1, \tmp0, \zeta, \zetaqinv, \q, \tmp1
.endm

/* q * qinv = 1 mod 2^32, used for Montgomery arithmetic. */
.equ mld_rv32im_q,    8380417
.equ mld_rv32im_qinv, 58728449

/* inv256 = 2^64 / 256 mod q = 2^56 mod q.
 * inv256qinv = low(inv256 * qinv mod 2^32). */
.equ mld_rv32im_inv256,     41978
.equ mld_rv32im_inv256qinv, 4286571514
