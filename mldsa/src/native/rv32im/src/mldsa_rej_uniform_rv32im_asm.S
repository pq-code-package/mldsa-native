/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM uniform rejection sampling. Parses buf as consecutive 3-byte
 * little-endian candidates, keeps the low 23 bits of each, and stores the
 * candidates t < q to r until 256 coefficients have been written or the
 * input is exhausted. Returns the number of coefficients written.
 *
 * buflen must be a positive multiple of 12 and buf must be 4-byte aligned.
 * Both loops read 12 bytes (four candidates) with three word loads. Each
 * candidate is stored unconditionally and the output pointer advances by 4
 * only if it is accepted. The main loop runs while at least four output
 * slots remain, which keeps every store within r[0, 256). The tail loop
 * checks the output pointer after every store instead.
 *
 * The frontend calls the native function only on the MLD_ALIGN buffers of
 * mld_poly_uniform and mld_poly_uniform_4x.
 *
 * The input is public (the expansion of rho), so the control flow may
 * depend on it.
 */

/*yaml
  Name: rej_uniform_rv32im_asm
  Description: RV32IM uniform rejection sampling mod q
  Signature: unsigned mld_rej_uniform_rv32im_asm(int32_t r[256], const uint8_t *buf, unsigned buflen)
  ABI:
    Architecture: riscv32
    CallingConvention: ILP32
    Features: [RV32M]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t r[256]
      description: Output coefficients
    a1:
      type: buffer
      size_bytes: 840
      permissions: read-only
      c_parameter: const uint8_t *buf
      description: Uniform random bytes, 4-byte aligned
    a2:
      type: scalar
      c_parameter: unsigned buflen
      description: Length of buf, a positive multiple of 12
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV32_M) && defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
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
 *   dev/riscv32/src/mldsa_rej_uniform_rv32im_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.balign 4
.global MLD_ASM_NAMESPACE(rej_uniform_rv32im_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_rv32im_asm)

        .cfi_startproc
        lui t0, 0x7fe
        addi t0, t0, 0x1
        lui t1, 0x800
        addi t1, t1, -0x1
        mv a3, a0
        addi a4, a0, 0x3f0
        addi a5, a0, 0x400
        add a6, a1, a2
        addi t2, a6, -0xc

.Lmld_rej_uniform_rv32im_loop:
        lw t3, 0x0(a1)
        lw t4, 0x4(a1)
        lw t5, 0x8(a1)
        addi a1, a1, 0xc
        and t6, t3, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        srli t6, t3, 0x18
        slli a7, t4, 0x8
        add t6, t6, a7
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        srli t6, t4, 0x10
        slli a7, t5, 0x10
        add t6, t6, a7
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        srli t6, t5, 0x8
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        bgeu a1, a6, .Lmld_rej_uniform_rv32im_done
        bgeu a4, a3, .Lmld_rej_uniform_rv32im_loop
        bgeu a3, a5, .Lmld_rej_uniform_rv32im_done

.Lmld_rej_uniform_rv32im_tail:
        lw t3, 0x0(a1)
        lw t4, 0x4(a1)
        lw t5, 0x8(a1)
        addi a1, a1, 0xc
        and t6, t3, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        bgeu a3, a5, .Lmld_rej_uniform_rv32im_done
        srli t6, t3, 0x18
        slli a7, t4, 0x8
        add t6, t6, a7
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        bgeu a3, a5, .Lmld_rej_uniform_rv32im_done
        srli t6, t4, 0x10
        slli a7, t5, 0x10
        add t6, t6, a7
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        bgeu a3, a5, .Lmld_rej_uniform_rv32im_done
        srli t6, t5, 0x8
        and t6, t6, t1
        sltu a7, t6, t0
        sw t6, 0x0(a3)
        slli a7, a7, 0x2
        add a3, a3, a7
        bgeu a3, a5, .Lmld_rej_uniform_rv32im_done
        bgeu t2, a1, .Lmld_rej_uniform_rv32im_tail

.Lmld_rej_uniform_rv32im_done:
        sub a0, a3, a0
        srli a0, a0, 0x2
        ret
        .cfi_endproc

MLD_ASM_FN_SIZE(rej_uniform_rv32im_asm)

        .option pop
#endif /* MLD_SYS_RISCV32_M && MLD_ARITH_BACKEND_RV32IM && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
