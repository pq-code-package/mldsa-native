/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * This file is derived from the public domain
 * AVX2 Dilithium implementation @[REF_AVX2].
 */

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include "consts.h"

.text
.balign 4
.global MLD_ASM_NAMESPACE(mld_rej_uniform)
MLD_ASM_FN_SYMBOL(mld_rej_uniform)

    # Initialize constants
    vpbroadcastd    .Lbound(%rip), %ymm0      # bound = MLDSA_Q
    vpbroadcastd    .Lmask(%rip), %ymm1       # mask = 0x7FFFFF
    vmovdqa         .Lidx8(%rip), %ymm2       # shuffle pattern

    # Initialize counters
    xor             %eax, %eax                # ctr = 0
    xor             %edx, %edx                # pos = 0

.Lvectorized_loop:
    # Check if ctr <= MLDSA_N - 8
    mov             $MLDSA_N, %r8d
    sub             $8, %r8d
    cmp             %r8d, %eax
    jg              .Lscalar_loop

    # Check if pos <= MLD_AVX2_REJ_UNIFORM_BUFLEN - 32
    mov             $MLD_AVX2_REJ_UNIFORM_BUFLEN, %r9d
    sub             $32, %r9d
    cmp             %r9d, %edx
    jg              .Lscalar_loop

    # Load 32 bytes from buf+pos
    vmovdqu         (%rsi,%rdx), %ymm3

    # Permute 64-bit elements (equivalent to _mm256_permute4x64_epi64(d, 0x94))
    vpermq          $0x94, %ymm3, %ymm3

    # Shuffle bytes (equivalent to _mm256_shuffle_epi8(d, idx8))
    vpshufb         %ymm2, %ymm3, %ymm3

    # Mask with 0x7FFFFF (equivalent to _mm256_and_si256(d, mask))
    vpand           %ymm1, %ymm3, %ymm3

    # Add 24 to pos
    add             $24, %edx

    # Subtract bound from each 32-bit element
    vpsubd          %ymm0, %ymm3, %ymm4

    # Get mask of valid values (where result < 0)
    vmovmskps       %ymm4, %ecx

    # Load permutation indices from table
    movslq          %ecx, %rcx
    lea             mld_rej_uniform_table(%rip), %r8
    vmovq           (%r8,%rcx,8), %xmm5
    vpmovsxbd       %xmm5, %ymm5

    # Permute the values to get only valid ones
    vpermd          %ymm3, %ymm5, %ymm3

    # Store to output array
    vmovdqu         %ymm3, (%rdi,%rax,4)

    # Update ctr using popcnt
    popcnt          %ecx, %ecx
    add             %ecx, %eax

    # Loop back
    jmp             .Lvectorized_loop

.Lscalar_loop:
    # Check if ctr < MLDSA_N
    cmp             $MLDSA_N, %eax
    jge             .Lreturn

    # Check if pos <= MLD_AVX2_REJ_UNIFORM_BUFLEN - 3
    mov             $MLD_AVX2_REJ_UNIFORM_BUFLEN, %r9d
    sub             $3, %r9d
    cmp             %r9d, %edx
    jg              .Lreturn

    # Load 3 bytes from buf+pos
    movzbl          (%rsi,%rdx), %ecx         # t = buf[pos]
    movzbl          1(%rsi,%rdx), %r8d
    shl             $8, %r8d
    or              %r8d, %ecx                # t |= buf[pos+1] << 8
    movzbl          2(%rsi,%rdx), %r8d
    shl             $16, %r8d
    or              %r8d, %ecx                # t |= buf[pos+2] << 16

    # Mask with 0x7FFFFF
    and             $0x7FFFFF, %ecx

    # Add 3 to pos
    add             $3, %edx

    # Compare with MLDSA_Q
    cmp             $MLDSA_Q, %ecx
    jge             .Lscalar_loop

    # Store to r[ctr] and increment ctr
    movl            %ecx, (%rdi,%rax,4)
    inc             %eax

    # Loop back
    jmp             .Lscalar_loop

.Lreturn:
    ret

.section .rodata
.balign 32
.Lbound:
    .long MLDSA_Q
.Lmask:
    .long 0x7FFFFF
.Lidx8:
    .byte 255, 15, 14, 13, 255, 12, 11, 10
    .byte 255, 9, 8, 7, 255, 6, 5, 4
    .byte 255, 11, 10, 9, 255, 8, 7, 6
    .byte 255, 5, 4, 3, 255, 2, 1, 0

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
