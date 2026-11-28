/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * RV32-IM ML-DSA UseHint for GAMMA2 = (q-1)/88. For 0 <= i < 256,
 * c = a[i] in [0, q) and h = h[i] in {0, 1}, computes a[i] = r as
 * mld_use_hint() in mldsa/src/rounding.h does:
 *
 *     f  = (c + 127) >> 7
 *     c1 = (f * 11275 + 2^23) >> 24              in [0, 44]
 *     c0 = c - c1 * 2*GAMMA2
 *     s  = (1 <= c0 <= (q-1)/2)
 *     r  = c1 - h + 2*(h & s)                    in [-1, 44]
 *     r  = (r == -1) ? 43 : (r == 44) ? 0 : r
 *
 * Unlike Decompose, c1 = 44 is kept here. In that case c0 <= 0, so
 * s = 0, and the final selection maps r = 44 - h to the result of the
 * border case of Decompose. Since s is the sign of the low bits of
 * Decompose, r is UseHint(h, c). The selections are computed with
 * masks, so the routine runs in constant time.
 */

/*yaml
  Name: poly_use_hint_88_rv32im_asm
  Description: RV32IM UseHint of a polynomial for GAMMA2 = (q-1)/88
  Signature: void mld_poly_use_hint_88_rv32im_asm(int32_t a[256], const int32_t h[256])
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

#include "../../../common.h"
#if defined(MLD_SYS_RISCV32_M) && defined(MLD_ARITH_BACKEND_RV32IM) && \
    !defined(MLD_CONFIG_NO_VERIFY_API) &&                              \
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
/* simpasm: header-end */

/*****************************************************************
 * Register aliases
 *****************************************************************/

/* Arguments */
#define a_ptr       a0
#define h_ptr       a1

/* Constants */
#define end         a2          /* a_ptr + 1024                    */
#define kmul        t0          /* 11275                           */
#define rnd         t1          /* 2^23                            */
#define g2x2        t2          /* 2*GAMMA2 = 190464               */
#define halfq       t3          /* (q-1)/2 = 4190208               */

/* Working set */
#define c0          a3
#define h0          a4
#define c1          a5
#define h1          a6
#define f           t4
#define t           t5

/*****************************************************************
 * Macros
 *****************************************************************/

/* use_hint c, h:
 *
 * Replace the coefficient c by its high bits corrected with the hint h.
 * Clobbers f, t.
 */
.macro use_hint c, h
        addi  f,  \c, 127
        srli  f,  f,  7
        mul   f,  f,  kmul
        add   f,  f,  rnd
        srli  f,  f,  24
        mul   t,  f,  g2x2
        sub   t,  \c, t
        addi  t,  t,  -1
        sltu  t,  t,  halfq
        and   t,  t,  \h
        slli  t,  t,  1
        sub   f,  f,  \h
        add   f,  f,  t
        srai  t,  f,  31
        andi  t,  t,  44
        add   f,  f,  t
        sltiu t,  f,  44
        neg   t,  t
        and   \c, f,  t
.endm

/*****************************************************************
 * Function
 *****************************************************************/

        .text
        .global MLD_ASM_NAMESPACE(poly_use_hint_88_rv32im_asm)
        .balign 4
MLD_ASM_FN_SYMBOL(poly_use_hint_88_rv32im_asm)

        /* check-magic: 11275 == floor(2**24 / 1488) */
        lui   kmul,  0x3
        addi  kmul,  kmul, -1013
        /* rnd = 2^23 */
        lui   rnd,   0x800
        /* check-magic: 190464 == 2 * intdiv(MLDSA_Q - 1, 88) */
        lui   g2x2,  0x2F
        addi  g2x2,  g2x2, -2048
        /* check-magic: 4190208 == intdiv(MLDSA_Q - 1, 2) */
        lui   halfq, 0x3FF

        addi  end,   a_ptr, 1024

mld_poly_use_hint_88_rv32im_loop:
        lw    c0,  0(a_ptr)
        lw    h0,  0(h_ptr)
        lw    c1,  4(a_ptr)
        lw    h1,  4(h_ptr)
        use_hint c0, h0
        use_hint c1, h1
        sw    c0,  0(a_ptr)
        sw    c1,  4(a_ptr)
        addi  a_ptr, a_ptr, 8
        addi  h_ptr, h_ptr, 8
        bne   a_ptr, end,   mld_poly_use_hint_88_rv32im_loop

        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef a_ptr
#undef h_ptr
#undef end
#undef kmul
#undef rnd
#undef g2x2
#undef halfq
#undef c0
#undef h0
#undef c1
#undef h1
#undef f
#undef t

/* simpasm: footer-start */
        .option pop
#endif /* MLD_SYS_RISCV32_M && MLD_ARITH_BACKEND_RV32IM && \
          !MLD_CONFIG_NO_VERIFY_API && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 44) \
        */
