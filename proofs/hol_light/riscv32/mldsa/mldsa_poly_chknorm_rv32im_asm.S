/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA infinity norm check. For 0 < B and coefficients
 * |a[i]| <= MLD_REDUCE32_RANGE_MAX, returns 0 if |a[i]| < B for all
 * 0 <= i < 256, and 1 otherwise.
 *
 * For each coefficient x, -B < x < B holds exactly when the unsigned
 * value x + (B-1) is at most 2B-2. The bounds on x and B keep x + (B-1)
 * within the signed 32-bit range, so a negative sum is a large unsigned
 * value. The routine ORs the comparison results of all coefficients and
 * does not exit early, so it runs in constant time.
 */

/*yaml
  Name: poly_chknorm_rv32im_asm
  Description: RV32IM infinity norm check of a polynomial
  Signature: int mld_poly_chknorm_rv32im_asm(const int32_t a[256], int32_t B)
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t a[256]
      description: Input polynomial
    a1:
      type: scalar
      c_parameter: int32_t B
      description: Norm bound, positive
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
 *   dev/riscv32/src/mldsa_poly_chknorm_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
#ifdef __APPLE__
.global _mld_poly_chknorm_rv32im_asm
_mld_poly_chknorm_rv32im_asm:
#else
.global mld_poly_chknorm_rv32im_asm
mld_poly_chknorm_rv32im_asm:
#endif

        .cfi_startproc
        addi a3, a1, -0x1
        add a4, a3, a3
        li a5, 0x0
        addi a2, a0, 0x400

.Lmld_poly_chknorm_rv32im_loop:
        lw t0, 0x0(a0)
        lw t1, 0x4(a0)
        lw t2, 0x8(a0)
        lw t3, 0xc(a0)
        add t0, t0, a3
        sltu t0, a4, t0
        or a5, a5, t0
        add t1, t1, a3
        sltu t1, a4, t1
        or a5, a5, t1
        add t2, t2, a3
        sltu t2, a4, t2
        or a5, a5, t2
        add t3, t3, a3
        sltu t3, a4, t3
        or a5, a5, t3
        addi a0, a0, 0x10
        bne a0, a2, .Lmld_poly_chknorm_rv32im_loop
        mv a0, a5
        ret
        .cfi_endproc

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
