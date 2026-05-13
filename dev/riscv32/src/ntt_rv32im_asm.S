/*
 * Copyright (c) 2024 Jipeng Zhang and the PQRV authors
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: MIT
 */

/*
 * Forward NTT for ML-DSA on RV32IM.
 *
 * The kernel and supporting macros are derived from the
 * `ntt_8l_singleissue_mont_rv32im.S` kernel in the PQRV repository at
 * https://github.com/Ji-Peng/PQRV/blob/87440598d6cbd83e3c0471298ebde533c8ab885b/ntt/dilithium/ntt_8l_singleissue_mont_rv32im.S
 *
 * The kernel implements a 3+3+2 layer-merging strategy for the 8-layer
 * forward NTT. It expects a precomputed zeta table laid out as
 * (zeta, low(zeta * qinv)) pairs in signed Montgomery form; see
 * scripts/autogen for the exact layout.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

.text

#include "ntt_rv32im_macros.inc"

/* void mld_ntt_rv32im_asm(int32_t in[256], const int32_t *zetas);
 *
 * Register usage:
 *  a0/a1: in/out polynomial; zeta table pointer
 *  a6:    q
 *  a4/a5: loop counters
 *  a2/a3: temporaries
 *  t0..t6, tp: 8 coefficients
 *  s0..s11, gp, ra: 7 (zeta, zetaqinv) pairs
 *
 * Layer-merging strategy: 3+3+2.
 */
.global MLD_ASM_NAMESPACE(ntt_rv32im_asm)
.align 2
MLD_ASM_FN_SYMBOL(ntt_rv32im_asm)
    addi sp, sp, -4*15
    mld_rv32im_save_regs
    li a6, mld_rv32im_q
    /* Load 7 (zeta, zetaqinv) pairs for layers 1..3 */
    mld_rv32im_load_zetas
    /* Loop bound: 32 iterations over a0[0..31] */
    addi a4, a0, 32*4
ntt_rv32im_looper_123:
    /* t0..tp = a[i, i+32, i+64, ..., i+224] */
    mld_rv32im_load_coeffs 32, a0
    /* level 1 */
    mld_rv32im_ct_bfu t0, t4, s0, s1, a6, a2, a3
    mld_rv32im_ct_bfu t1, t5, s0, s1, a6, a2, a3
    mld_rv32im_ct_bfu t2, t6, s0, s1, a6, a2, a3
    mld_rv32im_ct_bfu t3, tp, s0, s1, a6, a2, a3
    /* level 2 */
    mld_rv32im_ct_bfu t0, t2, s2, s3, a6, a2, a3
    mld_rv32im_ct_bfu t1, t3, s2, s3, a6, a2, a3
    mld_rv32im_ct_bfu t4, t6, s4, s5, a6, a2, a3
    mld_rv32im_ct_bfu t5, tp, s4, s5, a6, a2, a3
    /* level 3 */
    mld_rv32im_ct_bfu t0, t1, s6, s7, a6, a2, a3
    mld_rv32im_ct_bfu t2, t3, s8, s9, a6, a2, a3
    mld_rv32im_ct_bfu t4, t5, s10,s11,a6, a2, a3
    mld_rv32im_ct_bfu t6, tp, gp, ra, a6, a2, a3
    mld_rv32im_store_coeffs 32, a0
    addi a0, a0, 4
    bne a4, a0, ntt_rv32im_looper_123
    /* reset a0 */
    addi a0, a0, -32*4
    addi a1, a1, 4*7*2
    /* layers 4..6 (8 outer groups, 4 inner iterations each) */
    addi a5, a1, 8*4*7*2
ntt_rv32im_outer_456:
    mld_rv32im_load_zetas
    addi a4, a0, 4*4
    ntt_rv32im_inner_456:
        mld_rv32im_load_coeffs 4, a0
        /* level 4 */
        mld_rv32im_ct_bfu t0, t4, s0, s1, a6, a2, a3
        mld_rv32im_ct_bfu t1, t5, s0, s1, a6, a2, a3
        mld_rv32im_ct_bfu t2, t6, s0, s1, a6, a2, a3
        mld_rv32im_ct_bfu t3, tp, s0, s1, a6, a2, a3
        /* level 5 */
        mld_rv32im_ct_bfu t0, t2, s2, s3, a6, a2, a3
        mld_rv32im_ct_bfu t1, t3, s2, s3, a6, a2, a3
        mld_rv32im_ct_bfu t4, t6, s4, s5, a6, a2, a3
        mld_rv32im_ct_bfu t5, tp, s4, s5, a6, a2, a3
        /* level 6 */
        mld_rv32im_ct_bfu t0, t1, s6, s7, a6, a2, a3
        mld_rv32im_ct_bfu t2, t3, s8, s9, a6, a2, a3
        mld_rv32im_ct_bfu t4, t5, s10,s11,a6, a2, a3
        mld_rv32im_ct_bfu t6, tp, gp, ra, a6, a2, a3
        mld_rv32im_store_coeffs 4, a0
        addi a0, a0, 4
        bne a4, a0, ntt_rv32im_inner_456
    addi a0, a0, 32*4-4*4
    addi a1, a1, 4*7*2
    bne  a5, a1, ntt_rv32im_outer_456
    /* reset a0 */
    addi a0, a0, -8*32*4
    /* layers 7..8 (32 iterations) */
    addi a4, a0, 32*8*4
ntt_rv32im_looper_78:
    mld_rv32im_load_coeffs 1, a0
    mld_rv32im_load_zetas_short
    /* levels 7 & 8 */
    mld_rv32im_ct_bfu t0, t2, s0, s1, a6, a2, a3
    mld_rv32im_ct_bfu t1, t3, s0, s1, a6, a2, a3
    mld_rv32im_ct_bfu t0, t1, s2, s3, a6, a2, a3
    mld_rv32im_ct_bfu t2, t3, s4, s5, a6, a2, a3
    mld_rv32im_ct_bfu t4, t6, s6, s7, a6, a2, a3
    mld_rv32im_ct_bfu t5, tp, s6, s7, a6, a2, a3
    mld_rv32im_ct_bfu t4, t5, s8, s9, a6, a2, a3
    mld_rv32im_ct_bfu t6, tp, s10,s11,a6, a2, a3
    mld_rv32im_store_coeffs 1, a0
    addi a0, a0, 8*4
    addi a1, a1, 4*3*2*2
    bne a4, a0, ntt_rv32im_looper_78
    mld_rv32im_restore_regs
    addi sp, sp, 4*15
    ret

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
