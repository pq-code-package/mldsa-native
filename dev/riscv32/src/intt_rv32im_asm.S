/*
 * Copyright (c) 2024 Jipeng Zhang and the PQRV authors
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: MIT
 */

/*
 * Inverse NTT for ML-DSA on RV32IM.
 *
 * Derived from the `intt_8l_rv32im` kernel of
 * `ntt_8l_singleissue_mont_rv32im.S` in the PQRV repository at
 * https://github.com/Ji-Peng/PQRV/blob/87440598d6cbd83e3c0471298ebde533c8ab885b/ntt/dilithium/ntt_8l_singleissue_mont_rv32im.S
 *
 * The kernel implements a 2+3+3 layer-merging strategy for the 8-layer
 * inverse NTT and folds the final 1/256 scaling so that only the four
 * coefficients in the high half of the last layer-8 butterfly need an
 * extra `montmul_inplace`. The zeta table is laid out as
 * (zeta, low(zeta * qinv)) pairs (matching the forward table); see
 * scripts/autogen for the exact layout.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

.text

#include "ntt_rv32im_macros.inc"

/* void mld_intt_rv32im_asm(int32_t in[256], const int32_t *zetas);
 *
 * Register usage:
 *  a0/a1: in/out polynomial; zeta table pointer
 *  a6:    q
 *  a4/a5: loop counters / inv256 partner
 *  a2/a3/a7: temporaries
 *  t0..t6, tp: 8 coefficients
 *  s0..s11, gp, ra: 7 (zeta, zetaqinv) pairs
 *
 * Layer-merging strategy (inverse-NTT layers numbered 1..8 from the
 * finest stride to the coarsest): 2+3+3.
 */
.global MLD_ASM_NAMESPACE(intt_rv32im_asm)
.align 2
MLD_ASM_FN_SYMBOL(intt_rv32im_asm)
    addi sp, sp, -4*15
    mld_rv32im_save_regs
    li a6, mld_rv32im_q
    /* inv layers 1..2: 32 iterations of 8 consecutive coefficients. */
    addi a4, a0, 32*8*4
intt_rv32im_looper_12:
    mld_rv32im_load_coeffs 1, a0
    mld_rv32im_load_zetas_short
    /* inv layer 1 (stride 1) */
    mld_rv32im_gs_bfu t0, t1, s0, s1, a6, a2, a3
    mld_rv32im_gs_bfu t2, t3, s2, s3, a6, a2, a3
    /* inv layer 2 (stride 2) */
    mld_rv32im_gs_bfu t0, t2, s4, s5, a6, a2, a3
    mld_rv32im_gs_bfu t1, t3, s4, s5, a6, a2, a3
    /* inv layer 1 (stride 1), high quad */
    mld_rv32im_gs_bfu t4, t5, s6, s7, a6, a2, a3
    mld_rv32im_gs_bfu t6, tp, s8, s9, a6, a2, a3
    /* inv layer 2 (stride 2), high quad */
    mld_rv32im_gs_bfu t4, t6, s10,s11,a6, a2, a3
    mld_rv32im_gs_bfu t5, tp, s10,s11,a6, a2, a3
    mld_rv32im_store_coeffs 1, a0
    addi a0, a0, 8*4
    addi a1, a1, 4*3*2*2
    bne a4, a0, intt_rv32im_looper_12
    /* reset a0 */
    addi a0, a0, -32*8*4
    /* inv layers 3..5: 8 outer groups, 4 inner iterations each. */
    addi a5, a1, 8*4*7*2
intt_rv32im_outer_345:
    mld_rv32im_load_zetas
    addi a4, a0, 4*4
    intt_rv32im_inner_345:
        mld_rv32im_load_coeffs 4, a0
        /* inv layer 3 (stride 4) */
        mld_rv32im_gs_bfu t0, t1, s0, s1, a6, a2, a3
        mld_rv32im_gs_bfu t2, t3, s2, s3, a6, a2, a3
        mld_rv32im_gs_bfu t4, t5, s4, s5, a6, a2, a3
        mld_rv32im_gs_bfu t6, tp, s6, s7, a6, a2, a3
        /* inv layer 4 (stride 8) */
        mld_rv32im_gs_bfu t0, t2, s8, s9, a6, a2, a3
        mld_rv32im_gs_bfu t1, t3, s8, s9, a6, a2, a3
        mld_rv32im_gs_bfu t4, t6, s10,s11,a6, a2, a3
        mld_rv32im_gs_bfu t5, tp, s10,s11,a6, a2, a3
        /* inv layer 5 (stride 16) */
        mld_rv32im_gs_bfu t0, t4, gp, ra, a6, a2, a3
        mld_rv32im_gs_bfu t1, t5, gp, ra, a6, a2, a3
        mld_rv32im_gs_bfu t2, t6, gp, ra, a6, a2, a3
        mld_rv32im_gs_bfu t3, tp, gp, ra, a6, a2, a3
        mld_rv32im_store_coeffs 4, a0
        addi a0, a0, 4
        bne a4, a0, intt_rv32im_inner_345
    addi a0, a0, 32*4-4*4
    addi a1, a1, 4*7*2
    bne a5, a1, intt_rv32im_outer_345
    /* reset a0 */
    addi a0, a0, -8*32*4
    /* inv layers 6..8: 32 iterations, single 7-pair zeta table.
     * After the layer-8 GS butterfly the difference half already
     * carries the 1/256 scaling (gp,ra fuse -zetas[1] with 2^24). The
     * sum half (t0..t3) is scaled explicitly via montmul_inplace using
     * a7 = inv256 and a5 = inv256 * qinv (low). */
    addi a4, a0, 32*4
    mld_rv32im_load_zetas
    li a7, mld_rv32im_inv256
    li a5, mld_rv32im_inv256qinv
intt_rv32im_looper_678:
    mld_rv32im_load_coeffs 32, a0
    /* inv layer 6 (stride 32) */
    mld_rv32im_gs_bfu t0, t1, s0, s1, a6, a2, a3
    mld_rv32im_gs_bfu t2, t3, s2, s3, a6, a2, a3
    mld_rv32im_gs_bfu t4, t5, s4, s5, a6, a2, a3
    mld_rv32im_gs_bfu t6, tp, s6, s7, a6, a2, a3
    /* inv layer 7 (stride 64) */
    mld_rv32im_gs_bfu t0, t2, s8, s9, a6, a2, a3
    mld_rv32im_gs_bfu t1, t3, s8, s9, a6, a2, a3
    mld_rv32im_gs_bfu t4, t6, s10,s11,a6, a2, a3
    mld_rv32im_gs_bfu t5, tp, s10,s11,a6, a2, a3
    /* inv layer 8 (stride 128); difference half receives -zetas[1]/256. */
    mld_rv32im_gs_bfu t0, t4, gp, ra, a6, a2, a3
    mld_rv32im_gs_bfu t1, t5, gp, ra, a6, a2, a3
    mld_rv32im_gs_bfu t2, t6, gp, ra, a6, a2, a3
    mld_rv32im_gs_bfu t3, tp, gp, ra, a6, a2, a3
    /* sum half: explicit 1/256 scaling. */
    mld_rv32im_montmul_inplace t0, a7, a5, a6, a2
    mld_rv32im_montmul_inplace t1, a7, a5, a6, a2
    mld_rv32im_montmul_inplace t2, a7, a5, a6, a2
    mld_rv32im_montmul_inplace t3, a7, a5, a6, a2
    mld_rv32im_store_coeffs 32, a0
    addi a0, a0, 4
    bne a4, a0, intt_rv32im_looper_678
    mld_rv32im_restore_regs
    addi sp, sp, 4*15
    ret

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
