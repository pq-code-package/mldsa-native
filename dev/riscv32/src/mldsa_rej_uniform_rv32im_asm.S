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
/* simpasm: header-end */

/*****************************************************************
 * Register aliases
 *****************************************************************/

/* Arguments */
#define r_ptr       a0
#define buf         a1
#define buflen      a2

/* Constants */
#define q           t0          /* MLDSA_Q = 8380417              */
#define mask        t1          /* 2^23 - 1 = 0x7FFFFF            */

/* Pointers and limits */
#define out         a3          /* next output slot               */
#define out_lim     a4          /* r + 1008: four slots left      */
#define out_end     a5          /* r + 1024                       */
#define buf_end     a6          /* buf + buflen                   */
#define buf_lim     t2          /* buf_end - 12: last group       */

/* Working set */
#define w0          t3
#define w1          t4
#define w2          t5
#define cand        t6
#define acc         a7          /* accept flag                    */

/*****************************************************************
 * Macros
 *****************************************************************/

/* accept_store:
 *
 * Store cand to *out and advance out by 4 if cand < q. Clobbers acc.
 */
.macro accept_store
        sltu  acc,  cand, q
        sw    cand, 0(out)
        slli  acc,  acc,  2
        add   out,  out,  acc
.endm

/* load_group:
 *
 * Load the next 12 bytes of buf into w0, w1, w2 and advance buf.
 */
.macro load_group
        lw    w0,  0(buf)
        lw    w1,  4(buf)
        lw    w2,  8(buf)
        addi  buf, buf, 12
.endm

/* candidate k:
 *
 * Extract candidate k (0..3) of the loaded group into cand. The two
 * shifted parts of candidates 1 and 2 occupy disjoint bits, so add
 * combines them.
 */
.macro candidate k
.if \k == 0
        and   cand, w0, mask
.elseif \k == 1
        srli  cand, w0, 24
        slli  acc,  w1, 8
        add   cand, cand, acc
        and   cand, cand, mask
.elseif \k == 2
        srli  cand, w1, 16
        slli  acc,  w2, 16
        add   cand, cand, acc
        and   cand, cand, mask
.else
        srli  cand, w2, 8
        and   cand, cand, mask
.endif
.endm

/*****************************************************************
 * Function
 *****************************************************************/

        .text
        .global MLD_ASM_NAMESPACE(rej_uniform_rv32im_asm)
        .balign 4
MLD_ASM_FN_SYMBOL(rej_uniform_rv32im_asm)

        /* check-magic: 8380417 == MLDSA_Q */
        lui   q,    0x7FE
        addi  q,    q,    1
        /* mask = 0x7FFFFF */
        lui   mask, 0x800
        addi  mask, mask, -1

        mv    out,     r_ptr
        addi  out_lim, r_ptr, 1008
        addi  out_end, r_ptr, 1024
        add   buf_end, buf, buflen
        addi  buf_lim, buf_end, -12

mld_rej_uniform_rv32im_loop:
        load_group
        candidate 0
        accept_store
        candidate 1
        accept_store
        candidate 2
        accept_store
        candidate 3
        accept_store
        bgeu  buf, buf_end, mld_rej_uniform_rv32im_done
        bgeu  out_lim, out, mld_rej_uniform_rv32im_loop

        /* Fewer than four slots are left: check after every store. */
        bgeu  out, out_end, mld_rej_uniform_rv32im_done
mld_rej_uniform_rv32im_tail:
        load_group
        candidate 0
        accept_store
        bgeu  out, out_end, mld_rej_uniform_rv32im_done
        candidate 1
        accept_store
        bgeu  out, out_end, mld_rej_uniform_rv32im_done
        candidate 2
        accept_store
        bgeu  out, out_end, mld_rej_uniform_rv32im_done
        candidate 3
        accept_store
        bgeu  out, out_end, mld_rej_uniform_rv32im_done
        bgeu  buf_lim, buf, mld_rej_uniform_rv32im_tail

mld_rej_uniform_rv32im_done:
        sub   a0, out, r_ptr
        srli  a0, a0, 2
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef r_ptr
#undef buf
#undef buflen
#undef q
#undef mask
#undef out
#undef out_lim
#undef out_end
#undef buf_end
#undef buf_lim
#undef w0
#undef w1
#undef w2
#undef cand
#undef acc

/* simpasm: footer-start */
        .option pop
#endif /* MLD_SYS_RISCV32_M && MLD_ARITH_BACKEND_RV32IM && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
