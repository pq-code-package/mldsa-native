/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: poly_pointwise_montgomery_riscv64_asm
  Description: Pointwise Montgomery multiplication of two polynomials
  Signature: void mld_poly_pointwise_montgomery_riscv64_asm(int32_t a[256], const int32_t b[256])
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
    a1:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t b[256]
      description: Input polynomial
*/


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_poly_pointwise_montgomery_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
#ifdef __APPLE__
.global _mld_poly_pointwise_montgomery_riscv64_asm
_mld_poly_pointwise_montgomery_riscv64_asm:
#else
.global mld_poly_pointwise_montgomery_riscv64_asm
mld_poly_pointwise_montgomery_riscv64_asm:
#endif

        lui t1, 0x7fe
        addiw t1, t1, 0x1
        lui t2, 0x3802
        addiw t2, t2, 0x1
        li a2, 0x100
        vsetvli t0, a2, e32, m8, ta, ma
        slli t3, t0, 0x2

mld_poly_pointwise_montgomery_riscv64_loop:
        vle32.v v0, (a0)
        vle32.v v8, (a1)
        vmul.vv v16, v0, v8
        vmulh.vv v24, v0, v8
        vmul.vx v16, v16, t2
        vmulh.vx v16, v16, t1
        vsub.vv v0, v24, v16
        vse32.v v0, (a0)
        add a0, a0, t3
        add a1, a1, t3
        sub a2, a2, t0
        bnez a2, mld_poly_pointwise_montgomery_riscv64_loop
        ret

.option pop
#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
