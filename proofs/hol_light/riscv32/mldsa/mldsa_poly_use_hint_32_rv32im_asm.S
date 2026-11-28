/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA UseHint for GAMMA2 = (q-1)/32. For 0 <= i < 256,
 * c = a[i] in [0, q) and h = h[i] in {0, 1}, computes a[i] = r as
 * mld_use_hint() in mldsa/src/rounding.h does:
 *
 *     f  = (c + 127) >> 7
 *     c1 = (f * 1025 + 2^21) >> 22               in [0, 16]
 *     c0 = c - c1 * 2*GAMMA2
 *     s  = (1 <= c0 <= (q-1)/2)
 *     r  = (c1 - h + 2*(h & s)) & 15
 *
 * Unlike Decompose, c1 = 16 is kept here. In that case c0 <= 0, so
 * s = 0, and the final mask maps r = 16 - h to the result of the border
 * case of Decompose. Since s is the sign of the low bits of Decompose,
 * r is UseHint(h, c). The routine has no branches on data, so it runs
 * in constant time.
 */

/*yaml
  Name: poly_use_hint_32_rv32im_asm
  Description: RV32IM UseHint of a polynomial for GAMMA2 = (q-1)/32
  Signature: void mld_poly_use_hint_32_rv32im_asm(int32_t a[256], const int32_t h[256])
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t a[256]
      description: Input polynomial, output corrected high bits
    a1:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t h[256]
      description: Hint polynomial
*/

        /* Without linker relaxation, GNU as resolves the branches to .L
         * labels and leaves no relocations in the kernel. It uses the
         * setting in force at the end of the file, so keep this outside
         * the push/pop below. */
        .option norelax
        /* Keep RV32IMC builds byte-identical to the verified RV32IM code. */
        .option push
        .option norvc

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv32/src/mldsa_poly_use_hint_32_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
#ifdef __APPLE__
.global _mld_poly_use_hint_32_rv32im_asm
_mld_poly_use_hint_32_rv32im_asm:
#else
.global mld_poly_use_hint_32_rv32im_asm
mld_poly_use_hint_32_rv32im_asm:
#endif

        .cfi_startproc
        li t0, 0x401
        lui t1, 0x200
        lui t2, 0x80
        addi t2, t2, -0x200
        lui t3, 0x3ff
        addi a2, a0, 0x400

.Lmld_poly_use_hint_32_rv32im_loop:
        lw a3, 0x0(a0)
        lw a4, 0x0(a1)
        lw a5, 0x4(a0)
        lw a6, 0x4(a1)
        addi t4, a3, 0x7f
        srli t4, t4, 0x7
        mul t4, t4, t0
        add t4, t4, t1
        srli t4, t4, 0x16
        mul t5, t4, t2
        sub t5, a3, t5
        addi t5, t5, -0x1
        sltu t5, t5, t3
        and t5, t5, a4
        slli t5, t5, 0x1
        sub t4, t4, a4
        add t4, t4, t5
        andi a3, t4, 0xf
        addi t4, a5, 0x7f
        srli t4, t4, 0x7
        mul t4, t4, t0
        add t4, t4, t1
        srli t4, t4, 0x16
        mul t5, t4, t2
        sub t5, a5, t5
        addi t5, t5, -0x1
        sltu t5, t5, t3
        and t5, t5, a6
        slli t5, t5, 0x1
        sub t4, t4, a6
        add t4, t4, t5
        andi a5, t4, 0xf
        sw a3, 0x0(a0)
        sw a5, 0x4(a0)
        addi a0, a0, 0x8
        addi a1, a1, 0x8
        bne a0, a2, .Lmld_poly_use_hint_32_rv32im_loop
        ret
        .cfi_endproc

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
