/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: polyz_unpack_17_riscv64_asm
  Description: Unpack polynomial z with 18-bit packed coefficients for GAMMA1 = 2^17
  Signature: void mld_polyz_unpack_17_riscv64_asm(int32_t r[256], const uint8_t buf[576])
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t r[256]
      description: Output polynomial
    a1:
      type: buffer
      size_bytes: 576
      permissions: read-only
      c_parameter: const uint8_t buf[576]
      description: Packed input bytes
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)) && \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLD_CONFIG_PARAMETER_SET == 44) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_polyz_unpack_17_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(polyz_unpack_17_riscv64_asm)
MLD_ASM_FN_SYMBOL(polyz_unpack_17_riscv64_asm)

        li a2, 0x100
        li a5, 0x2
        lui a6, 0x20
        vsetvli t0, a2, e32, m2, ta, ma
        slli t3, t0, 0x2
        slli a3, t0, 0x3
        add a3, a3, t0
        srli a3, a3, 0x2
        slli a4, t0, 0x2
        li t2, 0x12
        vsetvli zero, a4, e16, m4, ta, ma
        vid.v v8
        vsrl.vi v12, v8, 0x2
        vmul.vx v12, v12, t2
        vsrl.vi v12, v12, 0x3
        vand.vi v8, v8, 0x3
        vminu.vx v8, v8, a5
        vadd.vv v8, v8, v12
        vsetvli zero, t0, e32, m2, ta, ma
        vid.v v4
        vmul.vx v4, v4, t2
        vand.vi v4, v4, 0x7
        lui t1, 0x40
        addiw t1, t1, -0x1

mld_polyz_unpack_17_riscv64_loop:
        vsetvli zero, a3, e8, m2, ta, ma
        vle8.v v16, (a1)
        vsetvli zero, a4, e8, m2, ta, ma
        vrgatherei16.vv v20, v16, v8
        vsetvli zero, t0, e32, m2, ta, ma
        vsrl.vv v20, v20, v4
        vand.vx v20, v20, t1
        vrsub.vx v20, v20, a6
        vse32.v v20, (a0)
        add a1, a1, a3
        add a0, a0, t3
        sub a2, a2, t0
        bnez a2, mld_polyz_unpack_17_riscv64_loop
        ret

.option pop
MLD_ASM_FN_SIZE(polyz_unpack_17_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          (!MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API) && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
          && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
