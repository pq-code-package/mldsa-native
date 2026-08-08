///
/// Copyright (c) 2022 Arm Limited
/// Copyright (c) 2022 Hanno Becker
/// Copyright (c) 2023 Amin Abdulrahman, Matthias Kannwischer
/// SPDX-License-Identifier: MIT
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///

/*
 * pqmx inverse NTT with fused ToMont scale adapted for mldsa-native.
 * Source: examples/naive/armv8m/dilithium/intt_dilithium_12_34_56_78.s
 * SLOTHY source revision: 504d1e8d
 *
 * The kernel consumes pqmx's 4-by-4-transposed NTT order and fuses ML-DSA's
 * final ToMont scale into its layer-1/2 stores.
 */

/*yaml
  Name: intt_armv81m_asm
  Description: pqmx Armv8.1-M MVE inverse ML-DSA NTT with fused final ToMont scale
  Signature: void mld_intt_armv81m_asm(int32_t r[256])
  CallerClobberedRegisters: [r0, r1, r2, r3, r12, lr, q0, q1, q2, q3]
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: [MVE]
    r0:
      type: buffer
      size_bytes: 1024
      alignment_bytes: 4
      permissions: read/write
      c_parameter: int32_t r[256]
      description: 256-coefficient input/output polynomial; input is pqmx 4-by-4-transposed NTT order and output is normal coefficient order with the final ToMont scale fused
  Stack:
    bytes: 100
    description: saves r4-r11, lr, and d8-d15; no dynamic allocation
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_ARMV81M_PQMX) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__ARM_FEATURE_MVE)

.section .rodata
.p2align 3
MLD_ASM_NAMESPACE(intt_armv81m_asm_roots):
#include "intt_armv81m_asm_twiddles.inc"
.text

// Barrett multiplication
.macro mld_intt_armv81m_asm_mulmod dst, src, const, const_twisted
        vmul.s32       \dst,  \src, \const
        vqrdmulh.s32   \src,  \src, \const_twisted
        vmla.s32       \dst,  \src, modulus
.endm

.macro mld_intt_armv81m_asm_gs_butterfly a, b, root, root_twisted
        vsub.u32       tmp, \a,  \b
        vadd.u32       \a,  \a,  \b
        mld_intt_armv81m_asm_mulmod         \b,  tmp, \root, \root_twisted
.endm

.macro mld_intt_armv81m_asm_tomont_scale data, scratch
        vmul.u32       \scratch, \data, scale_qinv
        vqdmulh.s32    \data,    \data, scale_factor
        vmul.u32       \scratch, \scratch, scale_factor
        vqdmulh.s32    \scratch, \scratch, scale_modulus
        vhsub.s32      \data,    \data, \scratch
.endm

/* simpasm: header-end */
.syntax unified
.global MLD_ASM_NAMESPACE(intt_armv81m_asm)
MLD_ASM_FN_SYMBOL(intt_armv81m_asm)

        push {r4-r11,lr}
        // Save MVE vector registers
        vpush {d8-d15}

        modulus     .req r12
        root_ptr    .req r11

        .equ mld_intt_armv81m_asm_modulus_const, -8380417
        movw modulus, #:lower16:mld_intt_armv81m_asm_modulus_const
        movt modulus, #:upper16:mld_intt_armv81m_asm_modulus_const
        ldr  root_ptr, MLD_ASM_NAMESPACE(intt_armv81m_asm_roots_addr)

        in .req r0

        data0 .req q0
        data1 .req q1
        data2 .req q2
        data3 .req q3

        root0         .req q5
        root0_twisted .req q6
        root1         .req q5
        root1_twisted .req q6
        root2         .req q5
        root2_twisted .req q6


        tmp .req q4

        scale_factor  .req r8
        scale_qinv    .req r9
        scale_modulus .req r10

        .equ mld_intt_armv81m_asm_scale_factor_const, 41978
        .equ mld_intt_armv81m_asm_scale_qinv_const, 58728449

        // Layers 7,8

        mov lr, #16
mld_intt_armv81m_asm_layer78_loop:
        vldrw.u32 data0, [in]
        vldrw.u32 data1, [in, #(4*4*1)]
        vldrw.u32 data2, [in, #(4*4*2)]
        vldrw.u32 data3, [in, #(4*4*3)]

        vldrw.u32 root1,         [root_ptr, #(32)]
        vldrw.u32 root1_twisted, [root_ptr, #(32+16)]
        mld_intt_armv81m_asm_gs_butterfly data0, data1, root1, root1_twisted

        vldrw.u32 root2,         [root_ptr, #(64)]
        vldrw.u32 root2_twisted, [root_ptr, #(64+16)]
        mld_intt_armv81m_asm_gs_butterfly data2, data3, root2, root2_twisted

        vldrw.u32 root0,         [root_ptr], #(3*32)
        vldrw.u32 root0_twisted, [root_ptr, #(16 - 3*32)]
        mld_intt_armv81m_asm_gs_butterfly data0, data2, root0, root0_twisted
        mld_intt_armv81m_asm_gs_butterfly data1, data3, root0, root0_twisted

        vstrw.u32 data0, [in], #64
        vstrw.u32 data1, [in, #(4*4*1 - 64)]
        vstrw.u32 data2, [in, #(4*4*2 - 64)]
        vstrw.u32 data3, [in, #(4*4*3 - 64)]

        le lr, mld_intt_armv81m_asm_layer78_loop

        sub in, in, #(4*256)

        .unreq root0
        .unreq root0_twisted
        .unreq root1
        .unreq root1_twisted
        .unreq root2
        .unreq root2_twisted

        root0         .req r2
        root0_twisted .req r3
        root1         .req r4
        root1_twisted .req r5
        root2         .req r6
        root2_twisted .req r7

        // Layers 5,6

        mov lr, #16
mld_intt_armv81m_asm_layer56_loop:
        ldrd root0, root0_twisted, [root_ptr], #24
        ldrd root1, root1_twisted, [root_ptr, #-16]
        ldrd root2, root2_twisted, [root_ptr, #-8]

        vld40.u32 {data0, data1, data2, data3}, [in]
        vld41.u32 {data0, data1, data2, data3}, [in]
        vld42.u32 {data0, data1, data2, data3}, [in]
        vld43.u32 {data0, data1, data2, data3}, [in]

        mld_intt_armv81m_asm_gs_butterfly data0, data1, root1, root1_twisted
        mld_intt_armv81m_asm_gs_butterfly data2, data3, root2, root2_twisted
        mld_intt_armv81m_asm_gs_butterfly data0, data2, root0, root0_twisted
        mld_intt_armv81m_asm_gs_butterfly data1, data3, root0, root0_twisted

        vstrw.u32 data0, [in], #(64)
        vstrw.u32 data1, [in, #(4*4*1 - 64)]
        vstrw.u32 data2, [in, #(4*4*2 - 64)]
        vstrw.u32 data3, [in, #(4*4*3 - 64)]

        le lr, mld_intt_armv81m_asm_layer56_loop

        sub in, in, #(4*256)

        // Layers 3,4

        // 4 butterfly blocks per root config, 4 root configs
        // loop over root configs

        count .req r1
        mov count, #4

mld_intt_armv81m_asm_out_start:
        ldrd root0, root0_twisted, [root_ptr], #+8
        ldrd root1, root1_twisted, [root_ptr], #+8
        ldrd root2, root2_twisted, [root_ptr], #+8

        mov lr, #4
mld_intt_armv81m_asm_layer34_loop:
        vldrw.u32 data0, [in]
        vldrw.u32 data1, [in, #(4*1*16)]
        vldrw.u32 data2, [in, #(4*2*16)]
        vldrw.u32 data3, [in, #(4*3*16)]

        mld_intt_armv81m_asm_gs_butterfly data0, data1, root1, root1_twisted
        mld_intt_armv81m_asm_gs_butterfly data2, data3, root2, root2_twisted
        mld_intt_armv81m_asm_gs_butterfly data0, data2, root0, root0_twisted
        mld_intt_armv81m_asm_gs_butterfly data1, data3, root0, root0_twisted

        vstrw.u32 data0, [in], #(16)
        vstrw.u32 data1, [in, #(4*16*1 - 16)]
        vstrw.u32 data2, [in, #(4*16*2 - 16)]
        vstrw.u32 data3, [in, #(4*16*3 - 16)]

        le lr, mld_intt_armv81m_asm_layer34_loop
        add in, in, #(4*64 - 4*16)

        subs count, count, #1
        bne mld_intt_armv81m_asm_out_start

        sub in, in, #(4*256)

        in_low       .req r0
        in_high      .req r1
        add in_high, in_low, #(4*128)

        // Layers 1,2

        ldrd root0, root0_twisted, [root_ptr], #+8
        ldrd root1, root1_twisted, [root_ptr], #+8
        ldrd root2, root2_twisted, [root_ptr], #+8

        movw scale_factor, #:lower16:mld_intt_armv81m_asm_scale_factor_const
        movt scale_factor, #:upper16:mld_intt_armv81m_asm_scale_factor_const
        movw scale_qinv, #:lower16:mld_intt_armv81m_asm_scale_qinv_const
        movt scale_qinv, #:upper16:mld_intt_armv81m_asm_scale_qinv_const
        rsb scale_modulus, modulus, #0

        mov lr, #16
mld_intt_armv81m_asm_layer12_loop:

        vldrw.u32 data0, [in_low]
        vldrw.u32 data1, [in_low,  #(4*64)]
        vldrw.u32 data2, [in_high]
        vldrw.u32 data3, [in_high, #(4*64)]

        mld_intt_armv81m_asm_gs_butterfly data0, data1, root1, root1_twisted
        mld_intt_armv81m_asm_gs_butterfly data2, data3, root2, root2_twisted
        mld_intt_armv81m_asm_gs_butterfly data0, data2, root0, root0_twisted
        mld_intt_armv81m_asm_gs_butterfly data1, data3, root0, root0_twisted

        mld_intt_armv81m_asm_tomont_scale data0, tmp
        mld_intt_armv81m_asm_tomont_scale data1, tmp
        mld_intt_armv81m_asm_tomont_scale data2, tmp
        mld_intt_armv81m_asm_tomont_scale data3, tmp

        vstrw.u32 data0, [in_low], #16
        vstrw.u32 data1, [in_low, #(4*64 - 16)]
        vstrw.u32 data2, [in_high], #16
        vstrw.u32 data3, [in_high, #(4*64 - 16)]

        le lr, mld_intt_armv81m_asm_layer12_loop

        // Restore MVE vector registers
        vpop {d8-d15}
        // Restore GPRs
        pop {r4-r11,lr}
        bx lr
        .unreq modulus
        .unreq root_ptr
        .unreq in
        .unreq in_low
        .unreq in_high
        .unreq count
        .unreq root0
        .unreq root0_twisted
        .unreq root1
        .unreq root1_twisted
        .unreq root2
        .unreq root2_twisted
        .unreq data0
        .unreq data1
        .unreq data2
        .unreq data3
        .unreq tmp
        .unreq scale_factor
        .unreq scale_qinv
        .unreq scale_modulus

.p2align 2
MLD_ASM_NAMESPACE(intt_armv81m_asm_roots_addr):
        .word 0

MLD_ASM_FN_SIZE(intt_armv81m_asm)

/* simpasm: footer-start */
/* simpasm re-emits the preceding literal but not its source relocation.
 * Keep this footer relocation adjacent to that literal in generated output. */
.reloc . - 4, R_ARM_ABS32, MLD_ASM_NAMESPACE(intt_armv81m_asm_roots)

#endif /* MLD_ARITH_BACKEND_ARMV81M_PQMX && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */
