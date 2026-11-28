/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA Decompose for GAMMA2 = (q-1)/88. For 0 <= i < 256 and
 * c = a0[i] in [0, q), computes
 *
 *     a1[i] = c1,  a0[i] = c0,  c = c1 * 2*GAMMA2 + c0 (mod q),
 *
 * with the same arithmetic as mld_decompose() in mldsa/src/rounding.h:
 *
 *     f  = (c + 127) >> 7
 *     c1 = (f * 11275 + 2^23) >> 24              in [0, 44]
 *     c1 = (c1 < 44) ? c1 : 0
 *     c0 = c - c1 * 2*GAMMA2
 *     c0 = (c0 > (q-1)/2) ? c0 - q : c0
 *
 * The selections are computed with masks, so the routine runs in
 * constant time.
 */

/*yaml
  Name: poly_decompose_88_rv32im_asm
  Description: RV32IM Decompose of a polynomial for GAMMA2 = (q-1)/88
  Signature: void mld_poly_decompose_88_rv32im_asm(int32_t a1[256], int32_t a0[256])
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t a1[256]
      description: Output high bits
    a1:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t a0[256]
      description: Input polynomial, output low bits
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV32_M) && defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_NO_SIGN_API) &&                                \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&                       \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) ||                     \
     MLD_CONFIG_PARAMETER_SET == 44)
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
 *   dev/riscv32/src/mldsa_poly_decompose_88_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(poly_decompose_88_rv32im_asm)
MLD_ASM_FN_SYMBOL(poly_decompose_88_rv32im_asm)

        .cfi_startproc
        lui t0, 0x3
        addi t0, t0, -0x3f5
        lui t1, 0x800
        lui t2, 0x2f
        addi t2, t2, -0x800
        lui t3, 0x3ff
        lui t4, 0x7fe
        addi t4, t4, 0x1
        addi a2, a1, 0x400

.Lmld_poly_decompose_88_rv32im_loop:
        lw a3, 0x0(a1)
        lw a4, 0x4(a1)
        addi a5, a3, 0x7f
        srli a5, a5, 0x7
        mul a5, a5, t0
        add a5, a5, t1
        srli a5, a5, 0x18
        sltiu t5, a5, 0x2c
        neg t5, t5
        and a5, a5, t5
        mul t5, a5, t2
        sub a3, a3, t5
        sub t6, t3, a3
        srai t6, t6, 0x1f
        and t6, t6, t4
        sub a3, a3, t6
        addi a6, a4, 0x7f
        srli a6, a6, 0x7
        mul a6, a6, t0
        add a6, a6, t1
        srli a6, a6, 0x18
        sltiu t5, a6, 0x2c
        neg t5, t5
        and a6, a6, t5
        mul t5, a6, t2
        sub a4, a4, t5
        sub t6, t3, a4
        srai t6, t6, 0x1f
        and t6, t6, t4
        sub a4, a4, t6
        sw a5, 0x0(a0)
        sw a6, 0x4(a0)
        sw a3, 0x0(a1)
        sw a4, 0x4(a1)
        addi a0, a0, 0x8
        addi a1, a1, 0x8
        bne a1, a2, .Lmld_poly_decompose_88_rv32im_loop
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(poly_decompose_88_rv32im_asm)

        .option pop
#endif /* MLD_SYS_RISCV32_M && MLD_ARITH_BACKEND_RV32IM && \
          !MLD_CONFIG_NO_SIGN_API && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
