/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: poly_decompose_32_riscv64_asm
  Description: Decompose polynomial coefficients into high and low bits for GAMMA2 = (q-1)/32
  Signature: void mld_poly_decompose_32_riscv64_asm(int32_t a1[256], int32_t a0[256])
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t a1[256]
      description: Output polynomial with high bits
    a1:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t a0[256]
      description: Input polynomial, output polynomial with low bits
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_NO_SIGN_API) && \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87)) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_poly_decompose_32_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(poly_decompose_32_riscv64_asm)
MLD_ASM_FN_SYMBOL(poly_decompose_32_riscv64_asm)

        lui t2, 0x7fe
        addiw t2, t2, 0x1
        li t3, 0x7f
        lui t4, 0x3ff
        lui t5, 0x80
        addiw t5, t5, -0x200
        li t6, 0x401
        lui a3, 0x200
        li a2, 0x100
        vsetvli t0, a2, e32, m8, ta, ma
        slli t1, t0, 0x2

mld_poly_decompose_32_riscv64_loop:
        vle32.v v8, (a1)
        vadd.vx v0, v8, t3
        vsra.vi v0, v0, 0x7
        vmul.vx v0, v0, t6
        vadd.vx v0, v0, a3
        vsra.vi v0, v0, 0x16
        vand.vi v0, v0, 0xf
        vnmsac.vx v8, t5, v0
        vrsub.vx v16, v8, t4
        vsra.vi v16, v16, 0x1f
        vand.vx v16, v16, t2
        vsub.vv v8, v8, v16
        vse32.v v0, (a0)
        vse32.v v8, (a1)
        add a0, a0, t1
        add a1, a1, t1
        sub a2, a2, t0
        bnez a2, mld_poly_decompose_32_riscv64_loop
        ret

.option pop
MLD_ASM_FN_SIZE(poly_decompose_32_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_NO_SIGN_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87) && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
