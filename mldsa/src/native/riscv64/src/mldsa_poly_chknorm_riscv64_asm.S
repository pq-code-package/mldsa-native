/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: poly_chknorm_riscv64_asm
  Description: Infinity-norm bound check on polynomial coefficients
  Signature: int mld_poly_chknorm_riscv64_asm(const int32_t a[256], int64_t B)
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t a[256]
      description: Input polynomial
    a1:
      type: scalar
      c_parameter: int64_t B
      description: Norm bound
      test_with: 131072  # representative non-negative bound (1 << 17)
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_poly_chknorm_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(poly_chknorm_riscv64_asm)
MLD_ASM_FN_SYMBOL(poly_chknorm_riscv64_asm)

        li a2, 0x100
        vsetvli t0, a2, e32, m4, ta, ma
        slli t1, t0, 0x2
        vmv.v.i v8, 0x0

mld_poly_chknorm_riscv64_loop:
        vle32.v v0, (a0)
        vrsub.vi v4, v0, 0x0
        vmax.vv v0, v0, v4
        vmaxu.vv v8, v8, v0
        add a0, a0, t1
        sub a2, a2, t0
        bnez a2, mld_poly_chknorm_riscv64_loop
        vmv.s.x v12, zero
        vredmaxu.vs v12, v8, v12
        vmv.x.s t2, v12
        slt a0, t2, a1
        xori a0, a0, 0x1
        ret

.option pop
MLD_ASM_FN_SIZE(poly_chknorm_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
