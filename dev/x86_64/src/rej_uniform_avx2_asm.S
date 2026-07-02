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
  Name: rej_uniform_avx2_asm
  Description: x86_64 AVX2 rejection sampling of uniform coefficients mod q.
    Extract 23-bit values from the input byte buffer and accept those that are
    < MLDSA_Q, writing accepted coefficients to the output buffer. Returns the
    number of valid coefficients written (at most 256).
  Signature: unsigned mld_rej_uniform_avx2_asm(int32_t *r, const uint8_t buf[840], const uint8_t table[256][8])
  ABI:
    Architecture: x86_64
    CallingConvention: SysV
    Features: [AVX2]
    rdi:
      type: buffer
      size_bytes: 1024
      permissions: write-only
      c_parameter: int32_t *r
      description: Output buffer (256 x int32_t)
    rsi:
      type: buffer
      size_bytes: 840
      permissions: read-only
      c_parameter: const uint8_t buf[840]
      description: Input buffer (MLD_POLY_UNIFORM_NBLOCKS * SHAKE128_RATE = 5 * 168)
    rdx:
      type: buffer
      size_bytes: 2048
      permissions: read-only
      c_parameter: const uint8_t table[256][8]
      description: Lookup table (256 x 8 x uint8_t)
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#define out %rdi
#define in %rsi
#define tab %rdx

#define ctr %eax
#define pos %ecx

#define good %r8d
#define cnt %r9d
#define tmp %r10

/* 64-bit views of the above, used as index registers in memory operands. */
#define ctr_q %rax
#define pos_q %rcx
#define good_q %r8

#define idx8 %ymm0
#define mask %ymm1
#define bound %ymm2
#define data %ymm3
#define cmp_result %ymm4

/*
 * Loop bounds. MLD_AVX2_REJ_UNIFORM_BUFLEN (= 5 * 168 = 840) is defined in
 * arith_native_x86_64.h, which is not assembler-safe to include here, so the
 * derived constants are spelled out. Keep these in sync with that header.
 */
#define MLDSA_N 256
#define MLDSA_Q 8380417
#define MASK_23 0x7FFFFF              /* low 23 bits */
#define BUFLEN 840
#define SIMD_CTR_BOUND (MLDSA_N - 8)   /* 248: need room for 8 coefficients */
#define SIMD_POS_BOUND (BUFLEN - 32)   /* 808: need room for a 32-byte load */
#define SCALAR_POS_BOUND (BUFLEN - 3)  /* 837: need room for a 3-byte sample */

        .text

        .balign 4
        .global MLD_ASM_NAMESPACE(rej_uniform_avx2_asm)
MLD_ASM_FN_SYMBOL(rej_uniform_avx2_asm)

/*
 * Construct the shuffle mask for extracting 8 x 23-bit values from 24 bytes.
 *
 * vpermq with 0x94 (= 0b 10 01 01 00) permutes 64-bit lanes via
 * (0,1,2,3) -> (0,1,1,2). The loaded 32 bytes are thus rearranged as:
 *   Low  128 bits: bytes [0..15] of original 32-byte load
 *   High 128 bits: bytes [8..23] of original 32-byte load
 *
 * vpshufb then picks 3-byte groups and zero-pads each to a 32-bit lane:
 *   Low  half: {0,1,2,FF, 3,4,5,FF, 6,7,8,FF, 9,10,11,FF}
 *   High half: {4,5,6,FF, 7,8,9,FF, 10,11,12,FF, 13,14,15,FF}
 *
 * This extracts 8 non-overlapping 3-byte windows from the first 24 input bytes.
 */
        movq    $0xFF050403FF020100, tmp
        vmovq   tmp, %xmm0
        movq    $0xFF0B0A09FF080706, tmp
        vpinsrq $1, tmp, %xmm0, %xmm0
        movq    $0xFF090807FF060504, tmp
        vmovq   tmp, %xmm3
        movq    $0xFF0F0E0DFF0C0B0A, tmp
        vpinsrq $1, tmp, %xmm3, %xmm3
        vinserti128 $1, %xmm3, idx8, idx8

        /* Construct broadcast constants */
        movl    $MASK_23, good
        vmovd   good, %xmm1
        vpbroadcastd %xmm1, mask               /* mask: 23-bit extraction */

        movl    $MLDSA_Q, good
        vmovd   good, %xmm2
        vpbroadcastd %xmm2, bound              /* bound: rejection threshold */

        /* Initialize counters */
        xorl    ctr, ctr                       /* ctr = 0 */
        xorl    pos, pos                       /* pos = 0 */

/*
 * Main SIMD loop: process 24 input bytes into up to 8 coefficients
 * per iteration. Loops while ctr <= MLDSA_N - 8 and pos <= BUFLEN - 32.
 */
rej_uniform_avx2_asm_loop:
        cmpl    $SIMD_CTR_BOUND, ctr
        ja      rej_uniform_avx2_asm_scalar
        cmpl    $SIMD_POS_BOUND, pos
        ja      rej_uniform_avx2_asm_scalar

        vmovdqu (in, pos_q), data              /* load 32 bytes from buf[pos] */
        addl    $24, pos                       /* advance pos */
        vpermq  $0x94, data, data              /* rearrange 64-bit lanes: [2,1,1,0] */
        vpshufb idx8, data, data               /* extract 8 x 3-byte groups */
        vpand   mask, data, data               /* mask to 23 bits */

        vpsubd  bound, data, cmp_result        /* d - Q: negative if d < Q (valid) */
        vmovmskps cmp_result, good             /* extract sign bits as 8-bit mask */

        popcntl good, cnt                      /* count valid coefficients */

        vmovq   (tab, good_q, 8), %xmm4        /* load permutation from table[good] */
        vpmovzxbd %xmm4, cmp_result            /* zero-extend to 8 dword indices */
        vpermd  data, cmp_result, data         /* compact valid coefficients to front */

        vmovdqu data, (out, ctr_q, 4)          /* store at r[ctr] */
        addl    cnt, ctr                       /* ctr += popcount(good) */

        jmp     rej_uniform_avx2_asm_loop

/*
 * Scalar fallback loop: process remaining bytes one coefficient at a time.
 * Loops while ctr < MLDSA_N and pos <= BUFLEN - 3.
 */
rej_uniform_avx2_asm_scalar:
        cmpl    $MLDSA_N, ctr
        jae     rej_uniform_avx2_asm_done
        cmpl    $SCALAR_POS_BOUND, pos
        ja      rej_uniform_avx2_asm_done

        movzwl  (in, pos_q), good              /* load 2 bytes at buf[pos] */
        movzbl  2(in, pos_q), cnt              /* load third byte */
        shll    $16, cnt
        orl     cnt, good
        andl    $MASK_23, good                 /* mask to 23 bits */
        addl    $3, pos                        /* advance pos */

        cmpl    $MLDSA_Q, good
        jae     rej_uniform_avx2_asm_scalar    /* reject if >= Q */

        movl    good, (out, ctr_q, 4)          /* store valid coefficient */
        addl    $1, ctr                        /* ctr++ */
        jmp     rej_uniform_avx2_asm_scalar

rej_uniform_avx2_asm_done:
        ret

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef out
#undef in
#undef tab
#undef ctr
#undef pos
#undef good
#undef cnt
#undef tmp
#undef ctr_q
#undef pos_q
#undef good_q
#undef idx8
#undef mask
#undef bound
#undef data
#undef cmp_result
#undef MASK_23
#undef BUFLEN
#undef SIMD_CTR_BOUND
#undef SIMD_POS_BOUND
#undef SCALAR_POS_BOUND
/* Some macros are kept because they are also defined in a header. */
/* Keep: MLDSA_N (params.h) */
/* Keep: MLDSA_Q (params.h) */

/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED \
        */
