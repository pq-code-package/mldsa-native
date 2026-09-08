/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [NeonNTT_Autoformalised]
 *   Neon NTT - (Auto)formalised
 *   Hanno Becker
 *   https://eprint.iacr.org/2026/1223
 */

/*
 * RV32-IM ML-DSA forward NTT, fast-multiplier variant.
 *
 * Thin wrapper: the kernel body is shared via mldsa_ntt_rv32im_asm.i, which
 * computes the Barrett low(t*q) reduction with a single multiply by q here.
 * The slow-multiplier variant lives in mldsa_ntt_rv32im_slowmul_asm.S.
 * Exactly one is selected by MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER.
 * The coarse Barrett output bound used by the shared kernel is proved in
 * @[NeonNTT_Autoformalised, Section 13.2].
 */

/*yaml
  Name: ntt_rv32im_asm
  Description: RV32IM ML-DSA forward NTT
  Signature: void mld_ntt_rv32im_asm(int32_t r[256], const int32_t zetas[510])
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t r[256]
      description: Input/output polynomial (256 x int32_t)
    a1:
      type: buffer
      size_bytes: 2040
      permissions: read-only
      c_parameter: const int32_t zetas[510]
      description: Twiddle table (255 Barrett pairs)
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

#include "mldsa_ntt_rv32im_asm.i"

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_RV32IM && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          !MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER */
