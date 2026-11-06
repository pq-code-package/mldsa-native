/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: rej_uniform_riscv64_asm
  Description: Run rejection sampling on uniform random bytes to generate uniform random integers mod q
  Signature: uint64_t mld_rej_uniform_riscv64_asm(int32_t *r, uint64_t len, const uint8_t *buf, uint64_t buflen)
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t *r
      description: Output buffer (4 * len bytes)
    a1:
      type: scalar
      c_parameter: uint64_t len
      description: Maximum number of coefficients to sample
      test_with: 256  # MLDSA_N
    a2:
      type: buffer
      size_bytes: a3
      permissions: read-only
      c_parameter: const uint8_t *buf
      description: Input buffer
    a3:
      type: scalar
      c_parameter: uint64_t buflen
      description: Length of input buffer (must be a multiple of 3)
      test_with: 840  # MLD_POLY_UNIFORM_NBLOCKS * SHAKE128_RATE = 5 * 168
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_rej_uniform_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(rej_uniform_riscv64_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_riscv64_asm)

        li a4, 0x0
        lui t2, 0x7fe
        addiw t2, t2, 0x1
        li t5, 0x2
        vsetvli t0, zero, e32, m2, ta, ma
        slli a6, t0, 0x2
        li t4, 0x18
        vsetvli zero, a6, e16, m4, ta, ma
        vid.v v8
        vsrl.vi v12, v8, 0x2
        vmul.vx v12, v12, t4
        vsrl.vi v12, v12, 0x3
        vand.vi v8, v8, 0x3
        vminu.vx v8, v8, t5
        vadd.vv v8, v8, v12
        lui t3, 0x1000
        addiw t3, t3, -0x1
        lui t3, 0x800
        addiw t3, t3, -0x1
        slli a5, t0, 0x1
        add a5, a5, t0

mld_rej_uniform_riscv64_loop:
        bgeu a4, a1, mld_rej_uniform_riscv64_done
        bltu a3, a5, mld_rej_uniform_riscv64_tail

mld_rej_uniform_riscv64_body:
        vsetvli zero, a5, e8, m2, ta, ma
        vle8.v v16, (a2)
        vsetvli zero, a6, e8, m2, ta, ma
        vrgatherei16.vv v20, v16, v8
        vsetvli zero, t0, e32, m2, ta, ma
        vand.vx v20, v20, t3
        add a2, a2, a5
        sub a3, a3, a5
        vmsltu.vx v0, v20, t2
        vcpop.m t1, v0
        vcompress.vm v24, v20, v0
        sub a7, a1, a4
        bgeu a7, t1, mld_rej_uniform_riscv64_store
        mv t1, a7

mld_rej_uniform_riscv64_store:
        vsetvli zero, t1, e32, m2, ta, ma
        vse32.v v24, (a0)
        add a4, a4, t1
        slli t1, t1, 0x2
        add a0, a0, t1
        j mld_rej_uniform_riscv64_loop

mld_rej_uniform_riscv64_tail:
        beqz a3, mld_rej_uniform_riscv64_done
        mv a5, a3
        lui t4, 0xb
        addiw t4, t4, -0x555
        mul t0, a3, t4
        srli t0, t0, 0x11
        slli a6, t0, 0x2
        j mld_rej_uniform_riscv64_body

mld_rej_uniform_riscv64_done:
        mv a0, a4
        ret

.option pop
MLD_ASM_FN_SIZE(rej_uniform_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
