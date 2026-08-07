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
 * Selected SLOTHY schedule adapted for mldsa-native from pqmx:
 * https://github.com/pq-code-package/pqmx/tree/1eeaf854e60d4ac30a2866d2a05f5935199ad6a6
 * SLOTHY submodule: ed3b034b3a3fbf06530784dd01a7622d4f6cf0fb
 * Input: examples/naive/armv8m/dilithium/ntt_dilithium_12_34_56_78.s
 * Selected pqmx output: examples/opt/armv8m/dilithium/ntt_dilithium_12_34_56_78_opt_m55.s
 *
 * The original MIT notice is retained above. The clean input owns this
 * artifact's metadata; see slothy_ntt_armv81m.py for regeneration.
 */

/*yaml
  Name: ntt_armv81m_asm
  Description: pqmx Armv8.1-M MVE forward ML-DSA NTT
  Signature: void mld_ntt_armv81m_asm(int32_t r[256])
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: [MVE]
    r0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t r[256]
      description: 256-coefficient input/output polynomial; kernel output is pqmx 4-by-4-transposed NTT order
  Stack:
    bytes: 100
    description: saves r4-r11, lr, and d8-d15; no dynamic allocation
*/

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_ARMV81M_PQMX) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) && defined(__ARM_FEATURE_MVE)

.section .rodata
.p2align 2
MLD_ASM_NAMESPACE(ntt_armv81m_asm_roots):
#include "ntt_armv81m_asm_twiddles.inc"
.text

// Barrett multiplication
.macro mld_ntt_armv81m_asm_mulmod dst, src, const, const_twisted
        vmul.s32       \dst,  \src, \const
        vqrdmulh.s32   \src,  \src, \const_twisted
        vmla.s32       \dst,  \src, modulus
.endm

.macro mld_ntt_armv81m_asm_ct_butterfly a, b, root, root_twisted
        mld_ntt_armv81m_asm_mulmod tmp, \b, \root, \root_twisted
        vsub.u32       \b,    \a, tmp
        vadd.u32       \a,    \a, tmp
.endm


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/armv81m_opt/src/ntt_armv81m_asm.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(ntt_armv81m_asm)
MLD_ASM_FN_SYMBOL(ntt_armv81m_asm)

        .cfi_startproc
        push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
        .cfi_adjust_cfa_offset 0x24
        .cfi_rel_offset r4, 0x0
        .cfi_rel_offset r5, 0x4
        .cfi_rel_offset r6, 0x8
        .cfi_rel_offset r7, 0xc
        .cfi_rel_offset r8, 0x10
        .cfi_rel_offset r9, 0x14
        .cfi_rel_offset r10, 0x18
        .cfi_rel_offset r11, 0x1c
        .cfi_rel_offset lr, 0x20
        vpush {d8, d9, d10, d11, d12, d13, d14, d15}
        .cfi_adjust_cfa_offset 0x40
        .cfi_rel_offset d8, 0x0
        .cfi_rel_offset d9, 0x8
        .cfi_rel_offset d10, 0x10
        .cfi_rel_offset d11, 0x18
        .cfi_rel_offset d12, 0x20
        .cfi_rel_offset d13, 0x28
        .cfi_rel_offset d14, 0x30
        .cfi_rel_offset d15, 0x38
        movw r12, #0x1fff
        movt r12, #0xff80
        ldr.w r11, [pc, #0x438]       @ LPQCP_MLDSA_NATIVE_MLDSA44_ntt_armv81m_asm_roots_addr
        add.w r1, r0, #0x200
        ldrd r2, r3, [r11], #8
        ldrd r4, r5, [r11], #8
        ldrd r6, r7, [r11], #8
        mov.w lr, #0x10
        vldrw.u32 q6, [r1, #256]
        vmul.i32 q4, q6, r2
        vldrw.u32 q5, [r0, #256]
        vqrdmulh.s32 q6, q6, r3
        vmla.i32 q4, q6, r12
        sub.w lr, lr, #0x1

Lmld_ntt_armv81m_asm_layer12_loop:
        vsub.i32 q6, q5, q4
        vmul.i32 q7, q6, r6
        vldrw.u32 q3, [r1]
        vqrdmulh.s32 q1, q3, r3
        vldrw.u32 q2, [r0]
        vmul.i32 q3, q3, r2
        vldrw.u32 q0, [r1, #272]
        vmla.i32 q3, q1, r12
        vadd.i32 q5, q5, q4
        vqrdmulh.s32 q6, q6, r7
        vadd.i32 q1, q2, q3
        vmla.i32 q7, q6, r12
        vsub.i32 q6, q2, q3
        vmul.i32 q4, q5, r4
        vadd.i32 q2, q6, q7
        vqrdmulh.s32 q3, q5, r5
        vstrw.32 q2, [r1], #16
        vmla.i32 q4, q3, r12
        vsub.i32 q7, q6, q7
        vldrw.u32 q5, [r0, #272]
        vadd.i32 q6, q1, q4
        vstrw.32 q6, [r0], #16
        vqrdmulh.s32 q3, q0, r3
        vsub.i32 q2, q1, q4
        vmul.i32 q4, q0, r2
        vstrw.32 q7, [r1, #240]
        vmla.i32 q4, q3, r12
        vstrw.32 q2, [r0, #240]
        le lr, Lmld_ntt_armv81m_asm_layer12_loop @ imm = #-0x74
        vadd.i32 q7, q5, q4
        vmul.i32 q6, q7, r4
        vldrw.u32 q1, [r1]
        vqrdmulh.s32 q3, q1, r3
        vsub.i32 q0, q5, q4
        vmul.i32 q5, q1, r2
        vldrw.u32 q2, [r0]
        vmla.i32 q5, q3, r12
        vqrdmulh.s32 q4, q7, r5
        vsub.i32 q1, q2, q5
        vmla.i32 q6, q4, r12
        vadd.i32 q2, q2, q5
        vmul.i32 q3, q0, r6
        vsub.i32 q4, q2, q6
        vqrdmulh.s32 q7, q0, r7
        vstrw.32 q4, [r0, #256]
        vmla.i32 q3, q7, r12
        vadd.i32 q0, q2, q6
        vstrw.32 q0, [r0], #16
        vadd.i32 q5, q1, q3
        vstrw.32 q5, [r1], #16
        vsub.i32 q5, q1, q3
        vstrw.32 q5, [r1, #240]
        sub.w r0, r0, #0x100
        mov.w r1, #0x4

Lmld_ntt_armv81m_asm_out_start:
        ldrd r2, r3, [r11], #8
        ldrd r4, r5, [r11], #8
        ldrd r6, r7, [r11], #8
        mov.w lr, #0x4
        vldrw.u32 q6, [r0, #192]
        vqrdmulh.s32 q7, q6, r3
        vldrw.u32 q0, [r0, #64]
        vmul.i32 q6, q6, r2
        vmla.i32 q6, q7, r12
        sub.w lr, lr, #0x1

Lmld_ntt_armv81m_asm_layer34_loop:
        vadd.i32 q4, q0, q6
        vmul.i32 q2, q4, r4
        vldrw.u32 q5, [r0, #128]
        vmul.i32 q3, q5, r2
        vsub.i32 q0, q0, q6
        vqrdmulh.s32 q5, q5, r3
        vldrw.u32 q1, [r0, #208]
        vmla.i32 q3, q5, r12
        vldrw.u32 q6, [r0]
        vmul.i32 q7, q0, r6
        vsub.i32 q5, q6, q3
        vqrdmulh.s32 q0, q0, r7
        vadd.i32 q6, q6, q3
        vmla.i32 q7, q0, r12
        vldrw.u32 q0, [r0, #80]
        vqrdmulh.s32 q3, q4, r5
        vadd.i32 q4, q5, q7
        vmla.i32 q2, q3, r12
        vstrw.32 q4, [r0, #128]
        vqrdmulh.s32 q4, q1, r3
        vadd.i32 q3, q6, q2
        vstrw.32 q3, [r0], #16
        vsub.i32 q3, q6, q2
        vmul.i32 q6, q1, r2
        vsub.i32 q5, q5, q7
        vstrw.32 q5, [r0, #176]
        vmla.i32 q6, q4, r12
        vstrw.32 q3, [r0, #48]
        le lr, Lmld_ntt_armv81m_asm_layer34_loop @ imm = #-0x74
        vldrw.u32 q1, [r0, #128]
        vmul.i32 q5, q1, r2
        vsub.i32 q7, q0, q6
        vqrdmulh.s32 q3, q1, r3
        vadd.i32 q6, q0, q6
        vqrdmulh.s32 q2, q6, r5
        vmla.i32 q5, q3, r12
        vldrw.u32 q3, [r0]
        vmul.i32 q4, q6, r4
        vadd.i32 q0, q3, q5
        vmla.i32 q4, q2, r12
        vsub.i32 q5, q3, q5
        vmul.i32 q1, q7, r6
        vadd.i32 q6, q0, q4
        vstrw.32 q6, [r0], #16
        vqrdmulh.s32 q2, q7, r7
        vsub.i32 q6, q0, q4
        vmla.i32 q1, q2, r12
        vstrw.32 q6, [r0, #48]
        vadd.i32 q7, q5, q1
        vstrw.32 q7, [r0, #112]
        vsub.i32 q6, q5, q1
        vstrw.32 q6, [r0, #176]
        add.w r0, r0, #0xc0
        subs r1, #0x1
        bne.w Lmld_ntt_armv81m_asm_out_start @ imm = #-0x102
        sub.w r0, r0, #0x400
        mov.w lr, #0x10
        ldrd r4, r9, [r11], #24
        vldrw.u32 q3, [r0, #48]
        vmul.i32 q1, q3, r4
        ldrd r5, r2, [r11, #-16]
        vqrdmulh.s32 q3, q3, r9
        vldrw.u32 q0, [r0, #16]
        vmla.i32 q1, q3, r12
        sub.w lr, lr, #0x1
        nop

Lmld_ntt_armv81m_asm_layer56_loop:
        vadd.i32 q3, q0, q1
        vmul.i32 q2, q3, r5
        vldrw.u32 q7, [r0, #32]
        vqrdmulh.s32 q6, q7, r9
        ldrd r10, r8, [r11, #-8]
        vmul.i32 q7, q7, r4
        vsub.i32 q5, q0, q1
        vmla.i32 q7, q6, r12
        vldrw.u32 q0, [r0]
        vqrdmulh.s32 q4, q3, r2
        vadd.i32 q6, q0, q7
        vmla.i32 q2, q4, r12
        vsub.i32 q7, q0, q7
        vmul.i32 q1, q5, r10
        vsub.i32 q3, q6, q2
        vqrdmulh.s32 q4, q5, r8
        vadd.i32 q2, q6, q2
        vmla.i32 q1, q4, r12
        vldrw.u32 q6, [r0, #112]
        vsub.i32 q5, q7, q1
        vldrw.u32 q0, [r0, #80]
        vadd.i32 q4, q7, q1
        ldrd r4, r9, [r11], #24
        ldrd r5, r2, [r11, #-16]
        vst40.32 {q2, q3, q4, q5}, [r0]
        vqrdmulh.s32 q7, q6, r9
        vst41.32 {q2, q3, q4, q5}, [r0]
        vmul.i32 q1, q6, r4
        vst42.32 {q2, q3, q4, q5}, [r0]
        vmla.i32 q1, q7, r12
        vst43.32 {q2, q3, q4, q5}, [r0]!
        le lr, Lmld_ntt_armv81m_asm_layer56_loop @ imm = #-0x80

Lmld_ntt_armv81m_asm_layer56_loop_end:
        vldrw.u32 q4, [r0, #32]
        vmul.i32 q7, q4, r4
        vadd.i32 q6, q0, q1
        vmul.i32 q5, q6, r5
        vsub.i32 q3, q0, q1
        vqrdmulh.s32 q2, q4, r9
        ldrd r10, r8, [r11, #-8]
        vmla.i32 q7, q2, r12
        vldrw.u32 q4, [r0]
        vqrdmulh.s32 q2, q6, r2
        vadd.i32 q6, q4, q7
        vmla.i32 q5, q2, r12
        vsub.i32 q4, q4, q7
        vqrdmulh.s32 q7, q3, r8
        vadd.i32 q2, q6, q5
        vmul.i32 q1, q3, r10
        vsub.i32 q3, q6, q5
        vmla.i32 q1, q7, r12
        mov.w lr, #0xf
        vsub.i32 q5, q4, q1
        vldrw.u32 q6, [r11], #96
        vadd.i32 q4, q4, q1
        vldrw.u32 q1, [r11, #-80]
        vst40.32 {q2, q3, q4, q5}, [r0]
        vst41.32 {q2, q3, q4, q5}, [r0]
        vst42.32 {q2, q3, q4, q5}, [r0]
        vst43.32 {q2, q3, q4, q5}, [r0]!
        sub.w r0, r0, #0x400
        vldrw.u32 q7, [r0, #32]
        vmul.i32 q2, q7, q6
        vldrw.u32 q3, [r0, #48]
        vqrdmulh.s32 q7, q7, q1
        vldrw.u32 q0, [r0]
        vmla.i32 q2, q7, r12

Lmld_ntt_armv81m_asm_layer78_loop:
        vqrdmulh.s32 q4, q3, q1
        vadd.i32 q7, q0, q2
        vmul.i32 q3, q3, q6
        vldrw.u32 q6, [r0, #16]
        vmla.i32 q3, q4, r12
        vldrw.u32 q1, [r11, #-16]
        vsub.i32 q5, q6, q3
        vldrw.u32 q4, [r11, #-32]
        vmul.i32 q4, q5, q4
        vadd.i32 q3, q6, q3
        vqrdmulh.s32 q6, q5, q1
        vldrw.u32 q5, [r0, #96]
        vmla.i32 q4, q6, r12
        vldrw.u32 q6, [r11, #-48]
        vsub.i32 q0, q0, q2
        vldrw.u32 q1, [r11, #16]
        vadd.i32 q2, q0, q4
        vstrw.32 q2, [r0, #32]
        vqrdmulh.s32 q6, q3, q6
        vsub.i32 q0, q0, q4
        vldrw.u32 q2, [r11, #-64]
        vmul.i32 q4, q3, q2
        vldrw.u32 q3, [r0, #112]
        vmla.i32 q4, q6, r12
        vstrw.32 q0, [r0, #48]
        vadd.i32 q0, q7, q4
        vstrw.32 q0, [r0], #64
        vsub.i32 q4, q7, q4
        vqrdmulh.s32 q7, q5, q1
        vldrw.u32 q6, [r11], #96
        vmul.i32 q2, q5, q6
        vldrw.u32 q0, [r0]
        vmla.i32 q2, q7, r12
        vstrw.32 q4, [r0, #-48]
        le lr, Lmld_ntt_armv81m_asm_layer78_loop @ imm = #-0x8c
        vqrdmulh.s32 q5, q3, q1
        vldrw.u32 q7, [r0, #16]
        vmul.i32 q3, q3, q6
        vldrw.u32 q6, [r11, #-48]
        vmla.i32 q3, q5, r12
        vldrw.u32 q1, [r11, #-64]
        vadd.i32 q4, q7, q3
        vmul.i32 q5, q4, q1
        vsub.i32 q3, q7, q3
        vqrdmulh.s32 q4, q4, q6
        vadd.i32 q7, q0, q2
        vmla.i32 q5, q4, r12
        vldrw.u32 q4, [r11, #-32]
        vsub.i32 q6, q7, q5
        vstrw.32 q6, [r0, #16]
        vadd.i32 q6, q7, q5
        vmul.i32 q4, q3, q4
        vldrw.u32 q5, [r11, #-16]
        vqrdmulh.s32 q1, q3, q5
        vsub.i32 q3, q0, q2
        vmla.i32 q4, q1, r12
        vstrw.32 q6, [r0], #64
        vadd.i32 q6, q3, q4
        vstrw.32 q6, [r0, #-32]
        vsub.i32 q4, q3, q4
        vstrw.32 q4, [r0, #-16]
        vpop {d8, d9, d10, d11, d12, d13, d14, d15}
        .cfi_restore d8
        .cfi_restore d9
        .cfi_restore d10
        .cfi_restore d11
        .cfi_restore d12
        .cfi_restore d13
        .cfi_restore d14
        .cfi_restore d15
        .cfi_adjust_cfa_offset -0x40
        pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
        .cfi_restore r4
        .cfi_restore r5
        .cfi_restore r6
        .cfi_restore r7
        .cfi_restore r8
        .cfi_restore r9
        .cfi_restore r10
        .cfi_restore r11
        .cfi_restore lr
        .cfi_adjust_cfa_offset -0x24
        bx lr
        .cfi_endproc
        nop

LPQCP_MLDSA_NATIVE_MLDSA44_ntt_armv81m_asm_roots_addr:
        .word 0x00000000

MLD_ASM_FN_SIZE(ntt_armv81m_asm)

/* simpasm re-emits the preceding literal but not its source relocation.
 * Keep this footer relocation adjacent to that literal in generated output. */
.reloc . - 4, R_ARM_ABS32, MLD_ASM_NAMESPACE(ntt_armv81m_asm_roots)

#endif /* MLD_ARITH_BACKEND_ARMV81M_PQMX && !MLD_CONFIG_MULTILEVEL_NO_SHARED && \
          __ARM_FEATURE_MVE */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
