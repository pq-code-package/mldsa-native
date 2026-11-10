/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: poly_use_hint_32_riscv64_asm
  Description: Use hint polynomial to correct the high bits of a polynomial for GAMMA2 = (q-1)/32
  Signature: void mld_poly_use_hint_32_riscv64_asm(int32_t a[256], const int32_t h[256])
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
      c_parameter: const int32_t h[256]
      description: Hint polynomial
*/


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_poly_use_hint_32_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
#ifdef __APPLE__
.global _mld_poly_use_hint_32_riscv64_asm
_mld_poly_use_hint_32_riscv64_asm:
#else
.global mld_poly_use_hint_32_riscv64_asm
mld_poly_use_hint_32_riscv64_asm:
#endif

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

mld_poly_use_hint_32_riscv64_loop:
        vle32.v v8, (a0)
        vle32.v v24, (a1)
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
        vadd.vi v8, v8, -0x1
        vsra.vi v8, v8, 0x1f
        vxor.vv v16, v24, v8
        vsub.vv v16, v16, v8
        vadd.vv v0, v0, v16
        vand.vi v0, v0, 0xf
        vse32.v v0, (a0)
        add a0, a0, t1
        add a1, a1, t1
        sub a2, a2, t0
        bnez a2, mld_poly_use_hint_32_riscv64_loop
        ret

.option pop
#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
