/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: poly_caddq_riscv64_asm
  Description: Add q to all negative coefficients of a polynomial
  Signature: void mld_poly_caddq_riscv64_asm(int32_t a[256])
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t a[256]
      description: Input/output polynomial
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_poly_caddq_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(poly_caddq_riscv64_asm)
MLD_ASM_FN_SYMBOL(poly_caddq_riscv64_asm)

        lui t1, 0x7fe
        addiw t1, t1, 0x1
        li a1, 0x100
        vsetvli t0, a1, e32, m4, ta, ma
        slli t2, t0, 0x2

mld_poly_caddq_riscv64_loop:
        vle32.v v0, (a0)
        vsra.vi v4, v0, 0x1f
        vand.vx v4, v4, t1
        vadd.vv v0, v0, v4
        vse32.v v0, (a0)
        add a0, a0, t2
        sub a1, a1, t0
        bnez a1, mld_poly_caddq_riscv64_loop
        ret

.option pop
MLD_ASM_FN_SIZE(poly_caddq_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
