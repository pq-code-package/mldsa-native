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
/* simpasm: header-end */

/*
 * Vector-length agnostic: works for any VLEN.
 *
 * Each iteration unpacks VL 24-bit values from 3*VL bytes of input (see
 * rv64v_unpack.inc), where VL = VLMAX for e32,m2 in the main loop, keeps
 * the low 23 bits, and accepts those below q. Once fewer than 3*VL bytes
 * remain, a single final iteration processes the rest with VL equal to
 * the number of remaining values. That VL is below VLMAX, so vsetvli
 * returns it unchanged.
 */

#define out             a0  /* output pointer (advancing) */
#define len             a1
#define buf             a2  /* input pointer (advancing) */
#define remaining       a3  /* remaining input bytes */
#define ctr             a4  /* number of sampled coefficients */
#define nbytes          a5  /* bytes per iteration (3*VL) */
#define vl4             a6  /* 4*VL */
#define room            a7  /* len - ctr */
#define vl              t0  /* values per iteration */
#define accepted        t1  /* values accepted in this iteration */
#define modulus         t2
#define mask            t3
#define tmp             t4
#define two             t5

#define accept_mask     v0
#define gidx            v8  /* register group of 4 */
#define gtmp            v12 /* register group of 4 */
#define src             v16 /* register group of 2 */
#define coeffs          v20 /* register group of 2 */
#define compressed      v24 /* register group of 2 */

#include "rv64v_unpack.inc"

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(rej_uniform_riscv64_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_riscv64_asm)

        li          ctr, 0
        li          modulus, MLDSA_Q
        li          two, 2

        /* Set up for VL = VLMAX. The indices are prefix-consistent, so
         * also valid for smaller VL. */
        vsetvli     vl, zero, e32, m2, ta, ma
        unpack_setup 24
        /* Keep 23 bits */
        li          mask, 0x7FFFFF

        /* nbytes = 3*VL */
        slli        nbytes, vl, 1
        add         nbytes, nbytes, vl

mld_rej_uniform_riscv64_loop:
        bgeu        ctr, len, mld_rej_uniform_riscv64_done
        bltu        remaining, nbytes, mld_rej_uniform_riscv64_tail

mld_rej_uniform_riscv64_body:
        unpack      24
        add         buf, buf, nbytes
        sub         remaining, remaining, nbytes

        vmsltu.vx   accept_mask, coeffs, modulus
        vcpop.m     accepted, accept_mask
        vcompress.vm compressed, coeffs, accept_mask

        /* accepted = min(accepted, len - ctr) */
        sub         room, len, ctr
        bgeu        room, accepted, mld_rej_uniform_riscv64_store
        mv          accepted, room
mld_rej_uniform_riscv64_store:
        vsetvli     zero, accepted, e32, m2, ta, ma
        vse32.v     compressed, (out)
        add         ctr, ctr, accepted
        slli        accepted, accepted, 2  // in bytes
        add         out, out, accepted
        j           mld_rej_uniform_riscv64_loop

mld_rej_uniform_riscv64_tail:
        /* Fewer than 3*VL bytes left. Process all remaining bytes in one
         * final iteration with VL = remaining/3. Afterwards remaining = 0,
         * so the next pass through the loop exits via the beqz below. */
        beqz        remaining, mld_rej_uniform_riscv64_done
        mv          nbytes, remaining
        /* x/3 = (x * 0xAAAB) >> 17, exact for multiples x of 3 below 2^17 */
        li          tmp, 0xAAAB
        mul         vl, remaining, tmp
        srli        vl, vl, 17
        slli        vl4, vl, 2
        j           mld_rej_uniform_riscv64_body

mld_rej_uniform_riscv64_done:
        mv          a0, ctr                // return value
        ret
.option pop

MLD_ASM_FN_SIZE(rej_uniform_riscv64_asm)

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef out
#undef len
#undef buf
#undef remaining
#undef ctr
#undef nbytes
#undef vl4
#undef room
#undef vl
#undef accepted
#undef modulus
#undef mask
#undef tmp
#undef two
#undef accept_mask
#undef gidx
#undef gtmp
#undef src
#undef coeffs
#undef compressed

/* simpasm: footer-start */
#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
