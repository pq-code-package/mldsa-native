/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA forward NTT, fast-multiplier variant.
 *
 * Thin wrapper: the kernel body is shared via ntt_rv32im_asm.i, which here
 * computes the Barrett low(t*q) reduction with a single multiply by q. The
 * slow-multiplier variant (shift-add) lives in ntt_rv32im_slowmul_asm.S.
 * Exactly one of the two is selected, by MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER.
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && \
    !defined(MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER)
/* simpasm: header-end */

        .text
        .global MLD_ASM_NAMESPACE(ntt_rv32im_asm)
        .balign 4
MLD_ASM_FN_SYMBOL(ntt_rv32im_asm)

#include "ntt_rv32im_asm.i"

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          !MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER */
