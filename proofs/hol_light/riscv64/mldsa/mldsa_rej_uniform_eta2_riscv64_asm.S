/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: rej_uniform_eta2_riscv64_asm
  Description: Run rejection sampling on uniform random bytes to generate uniform random integers in [-2, +2]
  Signature: uint64_t mld_rej_uniform_eta2_riscv64_asm(int32_t *r, uint64_t len, const uint8_t *buf, uint64_t buflen)
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
      description: Length of input buffer
      test_with: 272  # 2 * SHAKE256_RATE
*/


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_rej_uniform_eta2_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
#ifdef __APPLE__
.global _mld_rej_uniform_eta2_riscv64_asm
_mld_rej_uniform_eta2_riscv64_asm:
#else
.global mld_rej_uniform_eta2_riscv64_asm
mld_rej_uniform_eta2_riscv64_asm:
#endif

        li a4, 0x0
        li t2, 0x34
        li t3, 0x5
        vsetvli a5, zero, e16, m2, ta, ma

mld_rej_uniform_eta2_riscv64_loop:
        bgeu a4, a1, mld_rej_uniform_eta2_riscv64_done
        beqz a3, mld_rej_uniform_eta2_riscv64_done
        mv a6, a5
        bgeu a3, a5, mld_rej_uniform_eta2_riscv64_load
        mv a6, a3

mld_rej_uniform_eta2_riscv64_load:
        vsetvli zero, a6, e16, m2, ta, ma
        vle8.v v1, (a2)
        add a2, a2, a6
        sub a3, a3, a6
        vzext.vf2 v2, v1
        vsrl.vi v4, v2, 0x4
        vsll.vi v4, v4, 0x8
        vand.vi v2, v2, 0xf
        vor.vv v2, v2, v4
        slli t0, a6, 0x1
        vsetvli zero, t0, e8, m2, ta, ma
        vmsleu.vi v6, v2, 0xe
        vmulhu.vx v12, v2, t2
        vmul.vx v12, v12, t3
        vsub.vv v2, v2, v12
        vrsub.vi v2, v2, 0x2
        vcpop.m t1, v6
        vcompress.vm v14, v2, v6
        sub a7, a1, a4
        bgeu a7, t1, mld_rej_uniform_eta2_riscv64_store
        mv t1, a7

mld_rej_uniform_eta2_riscv64_store:
        vsetvli zero, t1, e32, m8, ta, ma
        vsext.vf4 v16, v14
        vse32.v v16, (a0)
        add a4, a4, t1
        slli t1, t1, 0x2
        add a0, a0, t1
        j mld_rej_uniform_eta2_riscv64_loop

mld_rej_uniform_eta2_riscv64_done:
        mv a0, a4
        ret

.option pop
#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
