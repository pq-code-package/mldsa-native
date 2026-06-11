/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [REF_AVX2]
 *   CRYSTALS-Dilithium optimized AVX2 implementation
 *   Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé
 *   https://github.com/pq-crystals/dilithium/tree/master/avx2
 */

/*
 * This file is derived from the public domain
 * AVX2 Dilithium implementation @[REF_AVX2].
 *
 * The algorithm for Decompose(r) (more specifically the handling for the
 * wrap-around cases) is modified. See the AVX2 intrinsics version
 * (poly_decompose_32_avx2.c, predecessor of this file) for a more detailed
 * comparison.
 */


/*yaml
  Name: poly_decompose_32_avx2_asm
  Description: x86_64 AVX2 coefficient decomposition (alpha = 2*(Q-1)/32).
    For all coefficients c of the input polynomial, compute high and low bits
    c0, c1 such that c = c1*ALPHA + c0 with -ALPHA/2 < c0 <= ALPHA/2, except if
    c1 = (Q-1)/ALPHA where we set c1 = 0 and -ALPHA/2 <= c0 = c - Q < 0.
    Assumes coefficients to be standard (unsigned canonical) representatives,
    i.e. 0 <= c < Q. For ML-DSA-65 / ML-DSA-87 (gamma2 = (Q-1)/32,
    alpha = 2*gamma2).
  Signature: void mld_poly_decompose_32_avx2_asm(int32_t *a1, int32_t *a0)
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t *a1
      description: Output high-part polynomial (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t *a0
      description: Input polynomial / output low-part (256 x int32_t)
*/

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) &&   \
    !defined(MLD_CONFIG_NO_SIGN_API) &&            \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) &&   \
    (defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED) || \
     (MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_PARAMETER_SET == 87))

/* simpasm: header-end */

/*
 * Symbolic names for the broadcast constant registers. Each holds a 32-bit
 * constant broadcast across all 8 lanes; the *_x aliases name the low 128-bit
 * (xmm) view used while building the constant.
 */
#define off        %ymm10   /* broadcast 127                            */
#define off_x      %xmm10
#define v          %ymm11   /* broadcast 1025                           */
#define v_x        %xmm11
#define shift      %ymm12   /* broadcast 512                            */
#define shift_x    %xmm12
#define q_bound    %ymm13   /* broadcast 31 * ((Q-1)/32) = 8118528      */
#define q_bound_x  %xmm13
#define alpha      %ymm14   /* broadcast 2 * ((Q-1)/32)  = 523776       */
#define alpha_x    %xmm14

/*
 * Broadcast a 32-bit immediate across all 8 lanes of a ymm register. Building
 * constants via mov-immediate + vmovd + vpbroadcastd (rather than loading from
 * .rodata) keeps the routine self-contained for HOL-Light.
 *
 *   imm    - 32-bit constant
 *   dst_x  - xmm view of the destination register
 *   dst    - ymm view of the destination register
 */
.macro bcast_const imm, dst_x, dst
        movl    \imm, %eax
        vmovd   %eax, \dst_x
        vpbroadcastd \dst_x, \dst
.endm

/*
 * Per-block decompose.
 *
 *   f   - loaded coefficient block (clobbered)
 *   f1  - scratch holding the high-part output
 *   f0  - scratch holding the low-part output
 *   t   - scratch holding the wrap-around mask
 *
 * The broadcast constants off, v, shift, q_bound and alpha are passed in
 * registers (see the #defines above).
 */
.macro decompose32_block off_in, off_out_a1, f, f1, f0, t
        vmovdqa  \off_in(%rsi), \f
        vpaddd   off, \f, \f1                   /* f1 = f + 127 */
        vpsrld   $7, \f1, \f1                   /* f1 = (f + 127) >> 7 */
        vpmulhuw v, \f1, \f1                    /* f1'' = mulhi_u16(f1, 1025) */
        vpmulhrsw shift, \f1, \f1               /* f1 = mulhrs_i16(f1'', 512) */
        vpcmpgtd q_bound, \f, \t                /* t = (f > 31*GAMMA2) */
        vpmulld  alpha, \f1, \f0                /* f0 = f1 * (2*GAMMA2) */
        vpsubd   \f0, \f, \f0                   /* f0 = f - f0 */
        vpandn   \f1, \t, \f1                   /* f1 = ~t & f1 */
        vpaddd   \t, \f0, \f0                   /* f0 = f0 + t */
        vmovdqa  \f1, \off_out_a1(%rdi)
        vmovdqa  \f0, \off_in(%rsi)
.endm

.text
.global MLD_ASM_NAMESPACE(poly_decompose_32_avx2_asm)
.balign 16
MLD_ASM_FN_SYMBOL(poly_decompose_32_avx2_asm)

        bcast_const $127,     off_x,     off
        bcast_const $1025,    v_x,       v
        bcast_const $512,     shift_x,   shift
        bcast_const $8118528, q_bound_x, q_bound    /* 31 * ((Q-1)/32) */
        bcast_const $523776,  alpha_x,   alpha      /* 2 * ((Q-1)/32) */

        decompose32_block    0,    0, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block   32,   32, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block   64,   64, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block   96,   96, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  128,  128, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  160,  160, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  192,  192, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  224,  224, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  256,  256, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  288,  288, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  320,  320, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  352,  352, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  384,  384, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  416,  416, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  448,  448, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  480,  480, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  512,  512, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  544,  544, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  576,  576, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  608,  608, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  640,  640, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  672,  672, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  704,  704, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  736,  736, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  768,  768, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  800,  800, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  832,  832, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  864,  864, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  896,  896, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  928,  928, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  960,  960, %ymm0, %ymm1, %ymm2, %ymm3
        decompose32_block  992,  992, %ymm0, %ymm1, %ymm2, %ymm3

        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef off
#undef off_x
#undef v
#undef v_x
#undef shift
#undef shift_x
#undef q_bound
#undef q_bound_x
#undef alpha
#undef alpha_x

/* simpasm: footer-start */

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_NO_SIGN_API && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          (MLD_CONFIG_MULTILEVEL_WITH_SHARED || MLD_CONFIG_PARAMETER_SET == 65 \
          || MLD_CONFIG_PARAMETER_SET == 87) */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
