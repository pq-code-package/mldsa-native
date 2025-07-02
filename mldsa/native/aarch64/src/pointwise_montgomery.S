/* Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_AARCH64)

.macro montgomery_reduce_long res, inl, inh
    uzp1   t0.4s, \inl\().4s, \inh\().4s
    mul    t0.4s, t0.4s, modulus_twisted.4s
    smlal  \inl\().2d, t0.2s, modulus.2s
    smlal2 \inh\().2d, t0.4s, modulus.4s
    uzp2   \res\().4s, \inl\().4s, \inh\().4s
.endm


.macro pmull dl, dh, a, b
    smull  \dl\().2d, \a\().2s, \b\().2s
    smull2 \dh\().2d, \a\().4s, \b\().4s
.endm

.macro pmlal dl, dh, a, b
    smlal  \dl\().2d, \a\().2s, \b\().2s
    smlal2 \dh\().2d, \a\().4s, \b\().4s
.endm

.macro save_vregs
        sub sp, sp, #(16*4)
        stp  d8,  d9, [sp, #16*0]
        stp d10, d11, [sp, #16*1]
        stp d12, d13, [sp, #16*2]
        stp d14, d15, [sp, #16*3]
.endm

.macro restore_vregs
        ldp  d8,  d9, [sp, #16*0]
        ldp d10, d11, [sp, #16*1]
        ldp d12, d13, [sp, #16*2]
        ldp d14, d15, [sp, #16*3]
        add sp, sp, #(16*4)
.endm

.macro push_stack
        save_vregs
.endm

.macro pop_stack
        restore_vregs
.endm

out_ptr .req x0
a0_ptr  .req x1
b0_ptr  .req x2
count   .req x3
wtmp    .req w3

modulus         .req v0
modulus_twisted .req v1

aa   .req v2
bb   .req v3
res  .req v4
resl .req v5
resh .req v6
t0   .req v7

q_aa  .req q2
q_bb  .req q3
q_res .req q4

.text
.global MLD_ASM_NAMESPACE(mld_pointwise_montgomery_asm)
.balign 4
MLD_ASM_FN_SYMBOL(mld_pointwise_montgomery_asm)
    push_stack

    // load q = 8380417
    movz wtmp, #57345
    movk wtmp, #127, lsl #16
    dup modulus.4s, wtmp

    // load -q^-1 = 4236238847
    movz wtmp, #57343
    movk wtmp, #64639, lsl #16
    dup modulus_twisted.4s, wtmp
    mov count, #(MLDSA_N / 4)
loop_start:


    ldr q_aa, [a0_ptr], #64
    ldr q_bb, [b0_ptr], #64
    pmull resl, resh, aa, bb
    montgomery_reduce_long res, resl, resh
    str q_res, [out_ptr], #64

    ldr q_aa, [a0_ptr, #-48]
    ldr q_bb, [b0_ptr, #-48]
    pmull resl, resh, aa, bb
    montgomery_reduce_long res, resl, resh
    str q_res, [out_ptr, #-48]

    ldr q_aa, [a0_ptr, #-32]
    ldr q_bb, [b0_ptr, #-32]
    pmull resl, resh, aa, bb
    montgomery_reduce_long res, resl, resh
    str q_res, [out_ptr, #-32]

    ldr q_aa, [a0_ptr, #-16]
    ldr q_bb, [b0_ptr, #-16]
    pmull resl, resh, aa, bb
    montgomery_reduce_long res, resl, resh
    str q_res, [out_ptr, #-16]

    subs count, count, #4
    cbnz count, loop_start

    pop_stack
    ret
#endif /* MLD_ARITH_BACKEND_AARCH64 */
