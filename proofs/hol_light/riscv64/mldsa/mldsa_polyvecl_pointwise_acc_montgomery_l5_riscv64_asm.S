/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: polyvecl_pointwise_acc_montgomery_l5_riscv64_asm
  Description: Pointwise multiplication and accumulation of two vectors of 5 polynomials with Montgomery reduction
  Signature: void mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm(int32_t w[256], const int32_t u[5][256], const int32_t v[5][256])
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
      size_bytes: 5120
      permissions: read-only
      c_parameter: const int32_t u[5][256]
      description: First input vector
    a2:
      type: buffer
      size_bytes: 5120
      permissions: read-only
      c_parameter: const int32_t v[5][256]
      description: Second input vector
*/


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
#ifdef __APPLE__
.global _mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm
_mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm:
#else
.global mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm
mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm:
#endif

        lui t1, 0x7fe
        addiw t1, t1, 0x1
        lui t2, 0x3802
        addiw t2, t2, 0x1
        li a3, 0x100
        li t4, 0x20
        li a6, 0x400
        vsetvli t0, a3, e32, m4, ta, ma
        slli t3, t0, 0x2

mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_loop:
        vle32.v v0, (a1)
        vle32.v v4, (a2)
        vwmul.vv v8, v0, v4
        mv a4, a1
        mv a5, a2
        add a4, a4, a6
        add a5, a5, a6
        vle32.v v0, (a4)
        vle32.v v4, (a5)
        vwmacc.vv v8, v0, v4
        add a4, a4, a6
        add a5, a5, a6
        vle32.v v0, (a4)
        vle32.v v4, (a5)
        vwmacc.vv v8, v0, v4
        add a4, a4, a6
        add a5, a5, a6
        vle32.v v0, (a4)
        vle32.v v4, (a5)
        vwmacc.vv v8, v0, v4
        add a4, a4, a6
        add a5, a5, a6
        vle32.v v0, (a4)
        vle32.v v4, (a5)
        vwmacc.vv v8, v0, v4
        vnsrl.wi v16, v8, 0x0
        vnsra.wx v20, v8, t4
        vmul.vx v16, v16, t2
        vmulh.vx v16, v16, t1
        vsub.vv v16, v20, v16
        vse32.v v16, (a0)
        add a0, a0, t3
        add a1, a1, t3
        add a2, a2, t3
        sub a3, a3, t0
        bnez a3, mld_polyvecl_pointwise_acc_montgomery_l5_riscv64_loop
        ret

.option pop
#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
