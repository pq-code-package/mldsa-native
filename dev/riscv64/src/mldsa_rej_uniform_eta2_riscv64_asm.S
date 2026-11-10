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

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_NO_KEYPAIR_API) && \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || MLDSA_ETA == 2) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

/*
 * Splits each input byte into its low and high nibble (in this order),
 * accepts nibbles t < 15 and maps them to 2 - (t mod 5).
 *
 * Vector-length agnostic: works for any VLEN of at least 64.
 *
 * Each iteration loads up to VLEN/8 bytes and zero-extends them to 16-bit
 * lanes (LMUL=2). Moving the high nibble to the upper byte of each lane
 * interleaves the nibbles as 8-bit lanes, which are mapped, compressed and
 * sign-extended to 32 bits (LMUL=8) for the store. The number of bytes per
 * iteration is min(VLEN/8, remaining), which vsetvli returns unchanged.
 */

#define out             a0  /* output pointer (advancing) */
#define len             a1
#define buf             a2  /* input pointer (advancing) */
#define remaining       a3  /* remaining input bytes */
#define ctr             a4  /* number of sampled coefficients */
#define chunk           a5  /* maximum bytes per iteration (VLEN/8) */
#define nbytes          a6  /* bytes in this iteration */
#define room            a7  /* len - ctr */
#define nnibbles        t0  /* 2 * nbytes */
#define accepted        t1  /* nibbles accepted in this iteration */
#define c52             t2
#define c5              t3

#define bytes           v1
#define nibbles         v2  /* register group of 2 */
#define hi              v4  /* register group of 2 */
#define accept_mask     v6
#define quot            v12 /* register group of 2 */
#define compressed      v14 /* register group of 2 */
#define wide            v16 /* register group of 8 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(rej_uniform_eta2_riscv64_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_eta2_riscv64_asm)

        li          ctr, 0
        li          c52, 52
        li          c5, 5
        vsetvli     chunk, zero, e16, m2, ta, ma

mld_rej_uniform_eta2_riscv64_loop:
        bgeu        ctr, len, mld_rej_uniform_eta2_riscv64_done
        beqz        remaining, mld_rej_uniform_eta2_riscv64_done

        /* nbytes = min(chunk, remaining) */
        mv          nbytes, chunk
        bgeu        remaining, chunk, mld_rej_uniform_eta2_riscv64_load
        mv          nbytes, remaining
mld_rej_uniform_eta2_riscv64_load:
        vsetvli     zero, nbytes, e16, m2, ta, ma
        vle8.v      bytes, (buf)
        add         buf, buf, nbytes
        sub         remaining, remaining, nbytes

        /* 16-bit lane i = (byte_i >> 4) << 8 | (byte_i & 15) */
        vzext.vf2   nibbles, bytes
        vsrl.vi     hi, nibbles, 4
        vsll.vi     hi, hi, 8
        vand.vi     nibbles, nibbles, 15
        vor.vv      nibbles, nibbles, hi

        slli        nnibbles, nbytes, 1
        vsetvli     zero, nnibbles, e8, m2, ta, ma
        /* r = 2 - (t mod 5), with t mod 5 = t - 5 * ((t * 52) >> 8) for
         * t < 15 */
        vmsleu.vi   accept_mask, nibbles, 14
        vmulhu.vx   quot, nibbles, c52
        vmul.vx     quot, quot, c5
        vsub.vv     nibbles, nibbles, quot
        vrsub.vi    nibbles, nibbles, 2
        vcpop.m     accepted, accept_mask
        vcompress.vm compressed, nibbles, accept_mask

        /* accepted = min(accepted, len - ctr) */
        sub         room, len, ctr
        bgeu        room, accepted, mld_rej_uniform_eta2_riscv64_store
        mv          accepted, room
mld_rej_uniform_eta2_riscv64_store:
        vsetvli     zero, accepted, e32, m8, ta, ma
        vsext.vf4   wide, compressed
        vse32.v     wide, (out)
        add         ctr, ctr, accepted
        slli        accepted, accepted, 2  // in bytes
        add         out, out, accepted
        j           mld_rej_uniform_eta2_riscv64_loop

mld_rej_uniform_eta2_riscv64_done:
        mv          a0, ctr                // return value
        ret
.option pop

MLD_ASM_FN_SIZE(rej_uniform_eta2_riscv64_asm)

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef out
#undef len
#undef buf
#undef remaining
#undef ctr
#undef chunk
#undef nbytes
#undef room
#undef nnibbles
#undef accepted
#undef c52
#undef c5
#undef bytes
#undef nibbles
#undef hi
#undef accept_mask
#undef quot
#undef compressed
#undef wide

/* simpasm: footer-start */
#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_NO_KEYPAIR_API && (MLD_CONFIG_MULTILEVEL_WITH_SHARED || \
          MLDSA_ETA == 2) && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
