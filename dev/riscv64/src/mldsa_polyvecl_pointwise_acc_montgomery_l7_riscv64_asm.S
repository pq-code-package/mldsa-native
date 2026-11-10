/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: polyvecl_pointwise_acc_montgomery_l7_riscv64_asm
  Description: Pointwise multiplication and accumulation of two vectors of 7 polynomials with Montgomery reduction
  Signature: void mld_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm(int32_t w[256], const int32_t u[7][256], const int32_t v[7][256])
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t w[256]
      description: Output polynomial
    a1:
      type: buffer
      size_bytes: 7168
      permissions: read-only
      c_parameter: const int32_t u[7][256]
      description: First input vector
    a2:
      type: buffer
      size_bytes: 7168
      permissions: read-only
      c_parameter: const int32_t v[7][256]
      description: Second input vector
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_L == 7) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#include "rv64v_pointwise_acc.inc"

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(polyvecl_pointwise_acc_montgomery_l7_riscv64_asm)
MLD_ASM_FN_SYMBOL(polyvecl_pointwise_acc_montgomery_l7_riscv64_asm)

        pointwise_acc_montgomery 7, mld_polyvecl_pointwise_acc_montgomery_l7_riscv64_loop
        ret
.option pop

MLD_ASM_FN_SIZE(polyvecl_pointwise_acc_montgomery_l7_riscv64_asm)

/* simpasm: footer-start */
#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLDSA_L == 7) && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
