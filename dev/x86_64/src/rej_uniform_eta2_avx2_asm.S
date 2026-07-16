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
  Name: rej_uniform_eta2_avx2_asm
  Description: x86_64 AVX2 rejection sampling of eta=2 secret coefficients.
    Extracts 4-bit nibbles from the input byte buffer, accepts those < 15,
    and maps an accepted nibble n to the coefficient 2 - (n mod 5) via a
    centered modulo-5 reduction, producing values in [-2, 2].
  Signature: unsigned mld_rej_uniform_eta2_avx2_asm(int32_t *r, const uint8_t *buf, const uint8_t table[256][8])
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t *r
      description: Output coefficient buffer (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 136
      permissions: read-only
      c_parameter: const uint8_t *buf
      description: Input byte buffer (MLD_AVX2_REJ_UNIFORM_ETA2_BUFLEN = 136)
    rdx:
      type: buffer
      size_bytes: 2048
      permissions: read-only
      c_parameter: const uint8_t *table
      description: Lookup table (256 x 8 uint8_t = mld_rej_uniform_table)
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#define out %rdi
#define in %rsi
#define tab %rdx

#define ctr %eax
#define pos %ecx

#define good %r8d
#define good_b %r8b
#define cnt %r9d
#define tmp %r10
#define tmp_d %r10d
#define val %r11d

#define ctr_q %rax
#define pos_q %rcx

#define f0 %ymm0
#define f1 %ymm1
#define f2 %ymm2
#define mask %ymm3
#define mask_x %xmm3
#define eta %ymm4
#define eta_x %xmm4
#define bound %ymm5
#define bound_x %xmm5
#define v_const %ymm6
#define v_const_x %xmm6
#define p_const %ymm7
#define p_const_x %xmm7
#define g0 %xmm8
#define g1 %xmm9

        .text

        .balign 4
        .global MLD_ASM_NAMESPACE(rej_uniform_eta2_avx2_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_eta2_avx2_asm)

// Construct broadcast constants
        movl    $0x0F0F0F0F, good
        vmovd   good, mask_x
        vpbroadcastd mask_x, mask             // mask: extract low 4 bits from each byte

        movl    $0x02020202, good
        vmovd   good, eta_x
        vpbroadcastd eta_x, eta               // eta: broadcast ETA=2

        movl    $0x0F0F0F0F, good
        vmovd   good, bound_x
        vpbroadcastd bound_x, bound           // bound: rejection threshold (15)

        // Modulo-5 magic constants
        // v = -6560 == 32*round(-2**10 / 5) for multiply-high-round-scale
        movl    $-6560, good
        vpinsrw $0, good, v_const_x, v_const_x
        vpbroadcastw v_const_x, v_const       // v_const: -6560 for mulhrs

        movl    $5, good
        vpinsrw $0, good, p_const_x, p_const_x
        vpbroadcastw p_const_x, p_const       // p_const: 5 for mullo

// Initialize counters
        xorl    ctr, ctr                       // ctr = 0
        xorl    pos, pos                       // pos = 0

/*
 * Main SIMD loop: process 16 input bytes into 32 nibbles, producing up to
 * 32 coefficients per iteration (4 groups of 8 nibbles each).
 * Loops while ctr <= MLDSA_N - 8 and pos <= BUFLEN - 16.
 */
rej_uniform_eta2_avx2_asm_loop:
        cmpl    $248, ctr                      // MLDSA_N - 8
        ja      rej_uniform_eta2_avx2_asm_scalar
        cmpl    $120, pos                      // MLD_AVX2_REJ_UNIFORM_ETA2_BUFLEN - 16
        ja      rej_uniform_eta2_avx2_asm_scalar

        // Load 16 bytes and extract 32 nibbles into f0
        vpmovzxbw (in, pos_q), f0              // load 16 bytes, zero-extend to 16 words
        vpsllw  $4, f0, f1                     // shift left by 4 to align high nibbles
        vpor    f1, f0, f0                     // OR: each word now has nibble duplicated
        vpand   mask, f0, f0                   // mask to get 4 bits per byte

        // Check which nibbles are < 15 and compute eta - nibble
        vpsubb  bound, f0, f1                  // f1 = nibble - 15 (negative if valid)
        vpsubb  f0, eta, f0                    // f0 = 2 - nibble
        vpmovmskb f1, good                     // extract sign bits (valid = 1)

        // For valid nibbles, reduce (2 - nibble) mod 5 (centered, range [-2,2]):
        //   t = (2 - nibble) - (205 * (2 - nibble) >> 10) * 5
        // matching r = 2 - (nibble mod 5) from the reference.

        // Process first group of 8 nibbles (low 128 bits, low 64 bits of that)
        vextracti128 $0, f0, g0                // extract low 128 bits
        movzbl  good_b, tmp_d                  // get low 8 bits of mask
        vmovq   (tab, tmp, 8), g1             // load shuffle indices from table
        vpshufb g1, g0, g1                     // compact valid nibbles
        vpmovsxbd g1, f1                       // sign-extend bytes to dwords

        // Apply modulo-5 reduction
        vpmulhrsw v_const, f1, f2              // f2 = mulhrs(f1, -6560)
        vpmullw p_const, f2, f2                // f2 = f2 * 5
        vpaddd  f2, f1, f1                     // f1 = (2 - nibble) reduced mod 5

        vmovdqu f1, (out, ctr_q, 4)            // store 8 dwords
        popcntl tmp_d, cnt                     // popcount of low 8 bits
        addl    cnt, ctr                       // ctr += popcount(low 8 bits)
        shrl    $8, good
        addl    $4, pos                        // consumed 4 input bytes

        cmpl    $248, ctr
        ja      rej_uniform_eta2_avx2_asm_scalar

        // Process second group of 8 nibbles (low 128 bits, high 64 bits)
        vpsrldq $8, g0, g0                     // shift right to get next 8 nibbles
        movzbl  good_b, tmp_d
        vmovq   (tab, tmp, 8), g1
        vpshufb g1, g0, g1
        vpmovsxbd g1, f1
        vpmulhrsw v_const, f1, f2
        vpmullw p_const, f2, f2
        vpaddd  f2, f1, f1
        vmovdqu f1, (out, ctr_q, 4)
        popcntl tmp_d, cnt
        addl    cnt, ctr
        shrl    $8, good
        addl    $4, pos

        cmpl    $248, ctr
        ja      rej_uniform_eta2_avx2_asm_scalar

        // Process third group of 8 nibbles (high 128 bits, low 64 bits)
        vextracti128 $1, f0, g0                // extract high 128 bits
        movzbl  good_b, tmp_d
        vmovq   (tab, tmp, 8), g1
        vpshufb g1, g0, g1
        vpmovsxbd g1, f1
        vpmulhrsw v_const, f1, f2
        vpmullw p_const, f2, f2
        vpaddd  f2, f1, f1
        vmovdqu f1, (out, ctr_q, 4)
        popcntl tmp_d, cnt
        addl    cnt, ctr
        shrl    $8, good
        addl    $4, pos

        cmpl    $248, ctr
        ja      rej_uniform_eta2_avx2_asm_scalar

        // Process fourth group of 8 nibbles (high 128 bits, high 64 bits)
        vpsrldq $8, g0, g0
        movzbl  good_b, tmp_d
        vmovq   (tab, tmp, 8), g1
        vpshufb g1, g0, g1
        vpmovsxbd g1, f1
        vpmulhrsw v_const, f1, f2
        vpmullw p_const, f2, f2
        vpaddd  f2, f1, f1
        vmovdqu f1, (out, ctr_q, 4)
        popcntl tmp_d, cnt
        addl    cnt, ctr
        addl    $4, pos

        jmp     rej_uniform_eta2_avx2_asm_loop

/*
 * Scalar fallback loop: process remaining bytes one nibble at a time.
 * Each byte contains two 4-bit nibbles (low and high).
 * Apply modulo-5 reduction: t = t - (205 * t >> 10) * 5
 */
rej_uniform_eta2_avx2_asm_scalar:
        cmpl    $256, ctr                      // MLDSA_N
        jae     rej_uniform_eta2_avx2_asm_done
        cmpl    $136, pos                      // MLD_AVX2_REJ_UNIFORM_ETA2_BUFLEN
        jae     rej_uniform_eta2_avx2_asm_done

        movzbl  (in, pos_q), val               // load 1 byte
        incl    pos

        // Process low nibble
        movl    val, tmp_d
        andl    $0x0F, tmp_d                   // extract low 4 bits
        cmpl    $15, tmp_d
        jae     rej_uniform_eta2_avx2_asm_high_nibble

        // Apply modulo-5 reduction: t = t - (205 * t >> 10) * 5
        movl    tmp_d, val
        imull   $205, val
        shrl    $10, val
        imull   $5, val
        subl    val, tmp_d                     // tmp = tmp - (205*tmp>>10)*5

        movl    $2, val
        subl    tmp_d, val                     // 2 - tmp
        movl    val, (out, ctr_q, 4)
        incl    ctr

        cmpl    $256, ctr
        jae     rej_uniform_eta2_avx2_asm_done

rej_uniform_eta2_avx2_asm_high_nibble:
        // Reload original byte for high nibble
        movzbl  -1(in, pos_q), val             // reload byte
        shrl    $4, val
        andl    $0x0F, val
        cmpl    $15, val
        jae     rej_uniform_eta2_avx2_asm_scalar

        // Apply modulo-5 reduction
        movl    val, tmp_d
        imull   $205, tmp_d
        shrl    $10, tmp_d
        imull   $5, tmp_d
        subl    tmp_d, val                     // val = val - (205*val>>10)*5

        movl    $2, tmp_d
        subl    val, tmp_d                     // 2 - val
        movl    tmp_d, (out, ctr_q, 4)
        incl    ctr

        jmp     rej_uniform_eta2_avx2_asm_scalar

rej_uniform_eta2_avx2_asm_done:
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef out
#undef in
#undef tab
#undef ctr
#undef pos
#undef good
#undef good_b
#undef cnt
#undef tmp
#undef tmp_d
#undef val
#undef ctr_q
#undef pos_q
#undef f0
#undef f1
#undef f2
#undef mask
#undef mask_x
#undef eta
#undef eta_x
#undef bound
#undef bound_x
#undef v_const
#undef v_const_x
#undef p_const
#undef p_const_x
#undef g0
#undef g1

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
