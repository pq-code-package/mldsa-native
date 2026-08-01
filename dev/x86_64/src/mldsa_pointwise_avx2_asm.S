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
 */

/*yaml
  Name: pointwise_avx2_asm
  Description: x86_64 AVX2 pointwise Montgomery multiplication
  Signature: void mld_pointwise_avx2_asm(int32_t *a, const int32_t *b, const int32_t *qdata)
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t *a
      description: Input/output polynomial (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t *b
      description: Input polynomial (256 x int32_t)
    rdx:
      type: buffer
      size_bytes: 2496
      permissions: read-only
      c_parameter: const int32_t *qdata
      description: Precomputed constants (624 x int32_t)
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#include "consts.h"

        .intel_syntax noprefix
        .text

/*
 * void mld_pointwise_avx2_asm(__m256i *a, const __m256i *b, const __m256i *qdata)
 *
 * Pointwise multiplication of polynomials in NTT domain with Montgomery
 * reduction. Destructive in the first argument: a := a * b * R^{-1} mod q.
 *
 * Arguments:
 *   rdi: pointer to first input/output polynomial a
 *   rsi: pointer to second input polynomial b
 *   rdx: pointer to qdata constants
 */
        .balign 4
        .global MLD_ASM_NAMESPACE(pointwise_avx2_asm)
MLD_ASM_FN_SYMBOL(pointwise_avx2_asm)

// Load constants
        vmovdqa ymm0, [rdx + (MLD_AVX2_BACKEND_DATA_OFFSET_8XQINV)*4]
        vmovdqa ymm1, [rdx + (MLD_AVX2_BACKEND_DATA_OFFSET_8XQ)*4]

        xor     eax, eax
mld_pointwise_avx2_looptop1:
// Handle 24 = 3*8 coefficients per iteration

// Load
        vmovdqa ymm2, [rdi]
        vmovdqa ymm4, [rdi + 32]
        vmovdqa ymm6, [rdi + 64]
        vmovdqa ymm10, [rsi]
        vmovdqa ymm12, [rsi + 32]
        vmovdqa ymm14, [rsi + 64]
        vpsrlq  ymm3, ymm2, 32
        vpsrlq  ymm5, ymm4, 32
        vmovshdup ymm7, ymm6
        vpsrlq  ymm11, ymm10, 32
        vpsrlq  ymm13, ymm12, 32
        vmovshdup ymm15, ymm14
        /*
         * ymm{i} stores a's coefficients for i in 2...7, and b's coefficients
         * for i in 10...15.
         *
         * Bounds: |ymm{i}| < 9q for i in 2...7, 10...15
         */

// Multiply
        vpmuldq ymm2, ymm2, ymm10
        vpmuldq ymm3, ymm3, ymm11
        vpmuldq ymm4, ymm4, ymm12
        vpmuldq ymm5, ymm5, ymm13
        vpmuldq ymm6, ymm6, ymm14
        vpmuldq ymm7, ymm7, ymm15
        /*
         * Bounds: |ymm{i}| < 81q^2 < MONTGOMERY_REDUCE_STRONG_DOMAIN_MAX
         *             for i in 2...7
         */

// Reduce
        vpmuldq ymm10, ymm0, ymm2
        vpmuldq ymm11, ymm0, ymm3
        vpmuldq ymm12, ymm0, ymm4
        vpmuldq ymm13, ymm0, ymm5
        vpmuldq ymm14, ymm0, ymm6
        vpmuldq ymm15, ymm0, ymm7
        vpmuldq ymm10, ymm1, ymm10
        vpmuldq ymm11, ymm1, ymm11
        vpmuldq ymm12, ymm1, ymm12
        vpmuldq ymm13, ymm1, ymm13
        vpmuldq ymm14, ymm1, ymm14
        vpmuldq ymm15, ymm1, ymm15
        vpsubq  ymm2, ymm2, ymm10
        vpsubq  ymm3, ymm3, ymm11
        vpsubq  ymm4, ymm4, ymm12
        vpsubq  ymm5, ymm5, ymm13
        vpsubq  ymm6, ymm6, ymm14
        vpsubq  ymm7, ymm7, ymm15
        /*
         * All coefficients are Montgomery-reduced, resulting in
         *
         * Bounds: |ymm{i}| < q for i in 2...7
         *
         * See description of mld_montgomery_reduce() in mldsa/src/reduce.h.
         */

// Store
        vpsrlq  ymm2, ymm2, 32
        vpsrlq  ymm4, ymm4, 32
        vmovshdup ymm6, ymm6
        vpblendd ymm2, ymm2, ymm3, 0xAA
        vpblendd ymm4, ymm4, ymm5, 0xAA
        vpblendd ymm6, ymm6, ymm7, 0xAA
        vmovdqa [rdi], ymm2
        vmovdqa [rdi + 32], ymm4
        vmovdqa [rdi + 64], ymm6

        add     rdi, 96
        add     rsi, 96
        add     eax, 1
        cmp     eax, 10
        jb      mld_pointwise_avx2_looptop1


// Handle the last 256 % 24 = 16 = 2*8 coefficients, left over by the loop

// Load
        vmovdqa ymm2, [rdi]
        vmovdqa ymm4, [rdi + 32]
        vmovdqa ymm10, [rsi]
        vmovdqa ymm12, [rsi + 32]
        vpsrlq  ymm3, ymm2, 32
        vpsrlq  ymm5, ymm4, 32
        vmovshdup ymm11, ymm10
        vmovshdup ymm13, ymm12
        /*
         * ymm{i} stores a's coefficients for i in 2...5, and b's coefficients
         * for i in 10...13.
         *
         * Bounds: |ymm{i}| < 9q for i in 2...5, 10...13
         */

// Multiply
        vpmuldq ymm2, ymm2, ymm10
        vpmuldq ymm3, ymm3, ymm11
        vpmuldq ymm4, ymm4, ymm12
        vpmuldq ymm5, ymm5, ymm13
        /*
         * Bounds: |ymm{i}| < 81q^2 < MONTGOMERY_REDUCE_STRONG_DOMAIN_MAX
         *             for i in 2...5
         */

// Reduce
        vpmuldq ymm10, ymm0, ymm2
        vpmuldq ymm11, ymm0, ymm3
        vpmuldq ymm12, ymm0, ymm4
        vpmuldq ymm13, ymm0, ymm5
        vpmuldq ymm10, ymm1, ymm10
        vpmuldq ymm11, ymm1, ymm11
        vpmuldq ymm12, ymm1, ymm12
        vpmuldq ymm13, ymm1, ymm13
        vpsubq  ymm2, ymm2, ymm10
        vpsubq  ymm3, ymm3, ymm11
        vpsubq  ymm4, ymm4, ymm12
        vpsubq  ymm5, ymm5, ymm13
        /*
         * As explained in the loop.
         *
         * Bounds: |ymm{i}| < q for i in 2...5
         */

// Store
        vpsrlq  ymm2, ymm2, 32
        vmovshdup ymm4, ymm4
        vpblendd ymm2, ymm3, ymm2, 0x55
        vpblendd ymm4, ymm5, ymm4, 0x55
        vmovdqa [rdi], ymm2
        vmovdqa [rdi + 32], ymm4

        ret
/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
