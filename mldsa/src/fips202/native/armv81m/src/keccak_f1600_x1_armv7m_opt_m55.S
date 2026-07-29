/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [ADOMNICAI23]
 *   An update on Keccak performance on ARMv7-M
 *   Alexandre Adomnicai
 *   https://eprint.iacr.org/2023/773
 *
 * - [SLOTHYM7]
 *   Enabling Microarchitectural Agility: Taking ML-KEM and ML-DSA from
 *   Cortex-M4 to M7 with SLOTHY
 *   Abdulrahman, Kannwischer, Lim
 *   https://eprint.iacr.org/2025/366
 *
 * - [XKCP]
 *   eXtended Keccak Code Package
 *   Bertoni, Daemen, Peeters, Van Assche, Van Keer
 *   https://github.com/XKCP/XKCP
 */

/*
 * This file is derived from the public domain SLOTHY source
 * examples/naive/armv7m/keccak/keccakf1600_adomnicai_m4.s.
 * That source is based on public domain XKCP code, with additional
 * optimizations by Alexandre Adomnicai.
 *
 * The theta parity input uses paired LDRD loads. Each pair is consumed before
 * the next load, retaining the immediate-use/no-hoist source shape.
 */

/*yaml
  Name: keccak_f1600_x1_armv7m_asm
  Description: Armv8.1-M paired-theta x1 Keccak-f[1600] permutation using the Adomnicai/XKCP bit-interleaved Armv7-M representation
  Signature: void mld_keccak_f1600_x1_armv7m_asm(uint32_t state[50], const uint32_t rc[49])
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: [MVE]
    r0:
      type: buffer
      size_bytes: 200
      permissions: read/write
      c_parameter: uint32_t state[50]
      description: Bit-interleaved x1 state as even/odd 32-bit halves for each Keccak lane
    r1:
      type: buffer
      size_bytes: 196
      permissions: read
      c_parameter: const uint32_t rc[49]
      description: Bit-interleaved round constants followed by the 0xff loop terminator
  Stack:
    bytes: 64
    description: register preservation (40) + scalar scratch/intermediate state (24); no MVE/Q-register scratch
*/

/*
 * This file is derived from the public domain implementation @[XKCP].
 * Optimizations for Armv7-M are described in @[ADOMNICAI23].
 * The clean round body is adapted from SLOTHY's MIT-licensed
 * examples/naive/armv7m/keccak/keccakf1600_adomnicai_m7.s.
 * Further optimizations using SLOTHY are described in @[SLOTHYM7].
 */
@ WARNING: These functions work only on little endian CPU with@ ARMv7m architecture (ARM Cortex-M3, ...).

#include "../../../../common.h"
#if defined(MLD_FIPS202_ARMV81M_NEED_X1) &&  !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m_opt/src/keccak_f1600_x1_armv7m_opt_m55.S using scripts/simpasm. Do not modify it directly.
 */

.thumb
.syntax unified

.text
.balign 4
.global MLD_ASM_NAMESPACE(keccak_f1600_x1_armv7m_asm)
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_armv7m_asm)

        .cfi_startproc
        push.w {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
        .cfi_adjust_cfa_offset 0x28
        .cfi_rel_offset r4, 0x0
        .cfi_rel_offset r5, 0x4
        .cfi_rel_offset r6, 0x8
        .cfi_rel_offset r7, 0xc
        .cfi_rel_offset r8, 0x10
        .cfi_rel_offset r9, 0x14
        .cfi_rel_offset r10, 0x18
        .cfi_rel_offset r11, 0x1c
        .cfi_rel_offset lr, 0x24
        sub sp, #0x18
        .cfi_adjust_cfa_offset 0x18
        str r1, [sp, #0x14]

Lkeccak_f1600_x1_armv7m_asm_slothy_start:
        ldrd r1, r6, [r0, #8]
        ldrd r12, r2, [r0, #48]
        ldrd r7, r4, [r0, #88]
        eor.w r6, r6, r2
        ldrd r3, r2, [r0, #128]
        eor.w r6, r6, r4
        ldrd r5, r8, [r0, #32]
        eor.w lr, r6, r2
        ldrd r11, r6, [r0, #112]
        ldrd r2, r4, [r0, #72]
        ldrd r10, r9, [r0, #152]
        eor.w r2, r5, r2
        eor.w r4, r8, r4
        eor.w r2, r2, r11
        eor.w r6, r4, r6
        eor.w r10, r2, r10
        ldrd r4, r2, [r0, #192]
        eor.w r6, r6, r9
        eor.w r11, r10, r4
        eor.w r9, r6, r2
        eor.w r2, r1, r12
        ldrd r6, r4, [r0, #168]
        eor.w r2, r2, r7
        eor.w r8, lr, r4
        eor.w r4, r2, r3
        eor.w r2, r11, r8, ror #31
        eor.w r10, r4, r6
        str r2, [sp]
        ldrd r4, r12, [r0, #16]
        ldrd r2, lr, [r0, #56]
        eor.w r6, r9, r10
        eor.w r4, r4, r2
        ldrd r2, r7, [r0, #96]
        str r6, [sp, #0x4]
        eor.w r4, r4, r2
        ldrd r2, r3, [r0, #136]
        eor.w r6, r12, lr
        eor.w lr, r4, r2
        ldrd r2, r4, [r0, #176]
        eor.w r6, r6, r7
        eor.w r1, lr, r2
        eor.w r2, r6, r3
        eor.w r9, r1, r9, ror #31
        eor.w r5, r2, r4
        str.w r9, [sp, #0x8]
        eor.w lr, r11, r5
        ldrd r6, r3, [r0, #24]
        ldrd r4, r2, [r0, #64]
        str.w lr, [sp, #0xc]
        eor.w r6, r6, r4
        ldrd r4, lr, [r0, #104]
        eor.w r2, r3, r2
        eor.w r6, r6, r4
        ldrd r4, r7, [r0, #144]
        eor.w r2, r2, lr
        eor.w lr, r6, r4
        ldrd r4, r6, [r0, #184]
        eor.w r2, r2, r7
        eor.w r3, lr, r4
        eor.w r4, r2, r6
        eor.w r2, r8, r3
        ldrd r8, r12, [r0]
        ldrd lr, r6, [r0, #40]
        eor.w r7, r10, r4, ror #31
        eor.w lr, r8, lr
        eor.w r6, r12, r6
        ldrd r10, r11, [r0, #80]
        str r7, [sp, #0x10]
        eor.w r7, lr, r10
        eor.w r6, r6, r11
        ldrd r10, r11, [r0, #120]
        ldrd r8, r12, [r0, #160]
        eor.w r6, r6, r11
        eor.w lr, r7, r10
        eor.w r11, r6, r12
        ldr.w r7, [r0, #0x48]
        ldr.w r10, [r0, #0x18]
        ldr.w r6, [r0, #0xb4]
        eor.w r12, r3, r11, ror #31
        eor.w r11, r11, r1
        eor.w lr, lr, r8
        eor.w r3, r9, r10
        eor.w r10, lr, r5, ror #31
        ldr.w r1, [r0, #0x84]
        eor.w r8, r12, r7
        eor.w r7, r11, r1
        eor.w r6, r2, r6
        bic.w r5, r8, r3, ror #28
        bic.w r1, r3, r6, ror #15
        eor.w r5, r5, r6, ror #11
        eor.w r1, r1, r7, ror #23
        bic.w r6, r6, r7, ror #8
        eor.w lr, r4, lr
        str.w r1, [r0, #0x18]
        ldr.w r1, [r0, #0x54]
        ldr r4, [sp, #0x4]
        eor.w r1, r4, r1
        bic.w r7, r7, r1, ror #21
        str.w r5, [r0, #0x48]
        eor.w r5, r7, r8, ror #13
        ldr.w r7, [r0, #0x9c]
        eor.w r6, r6, r1, ror #29
        bic.w r1, r1, r8, ror #24
        ldr.w r8, [r0, #0xa4]
        eor.w r1, r1, r3, ror #20
        str.w r6, [r0, #0xb4]
        eor.w r3, lr, r7
        ldr.w r7, [r0, #0x68]
        eor.w r7, r9, r7
        str.w r1, [r0, #0x54]
        eor.w r4, r4, r8
        bic.w r6, r3, r7, ror #24
        str.w r5, [r0, #0x84]
        ldr.w r1, [r0, #0x3c]
        eor.w r5, r2, r1
        eor.w r1, r6, r5, ror #1
        ldr.w r8, [r0, #0x8]
        str.w r1, [r0, #0x8]
        eor.w r1, r10, r8
        bic.w r8, r7, r5, ror #9
        bic.w r6, r5, r1, ror #3
        eor.w r5, r8, r1, ror #12
        bic.w r8, r4, r3, ror #5
        str.w r5, [r0, #0xa4]
        eor.w r5, r8, r7, ror #29
        eor.w r7, r6, r4, ror #26
        str.w r5, [r0, #0x3c]
        ldr.w r6, [r0, #0x24]
        ldr.w r5, [r0, #0x28]
        str.w r7, [r0, #0x9c]
        bic.w r4, r1, r4, ror #23
        ldr.w r8, [sp]
        eor.w r1, r4, r3, ror #28
        ldr.w r7, [r0, #0x8c]
        str.w r1, [r0, #0x68]
        eor.w r3, lr, r6
        eor.w r4, r8, r5
        ldr.w r5, [r0, #0x58]
        eor.w r5, r10, r5
        bic.w r1, r5, r4, ror #19
        eor.w r6, r2, r7
        eor.w r1, r1, r3, ror #23
        ldr.w r7, [r0, #0xb8]
        str.w r1, [r0, #0x28]
        bic.w r1, r6, r5, ror #3
        eor.w r7, r9, r7
        eor.w r1, r1, r4, ror #22
        bic.w r4, r4, r3, ror #4
        str.w r1, [r0, #0x58]
        bic.w r1, r7, r6, ror #20
        bic.w r3, r3, r7, ror #18
        eor.w r1, r1, r5, ror #23
        eor.w r6, r3, r6, ror #6
        str.w r1, [r0, #0x8c]
        str.w r6, [r0, #0xb8]
        ldr.w r6, [r0, #0x40]
        eor.w r9, r9, r6
        eor.w r5, r4, r7, ror #22
        ldr.w r7, [r0, #0x14]
        str.w r5, [r0, #0x24]
        eor.w r5, r2, r7
        ldr.w r4, [r0, #0x70]
        ldr.w r1, [r0, #0x78]
        ldr.w r6, [r0, #0xac]
        eor.w r4, r12, r4
        eor.w r3, r11, r6
        bic.w r7, r4, r9, ror #24
        eor.w r1, r8, r1
        bic.w r6, r1, r4, ror #1
        eor.w r7, r7, r5, ror #20
        eor.w r6, r6, r9, ror #25
        str.w r7, [r0, #0x78]
        str.w r6, [r0, #0xac]
        bic.w r6, r3, r1, ror #13
        bic.w r7, r5, r3, ror #30
        eor.w r4, r6, r4, ror #14
        eor.w r1, r7, r1, ror #11
        ldr r6, [r0, #0x64]
        str.w r4, [r0, #0x14]
        str.w r1, [r0, #0x40]
        ldr.w r1, [r0, #0xc0]
        bic.w r7, r9, r5, ror #28
        ldr.w r9, [sp, #0xc]
        eor.w r4, r7, r3, ror #26
        ldr.w r5, [r0]
        ldr r7, [r0, #0x30]
        eor.w r7, r10, r7
        str.w r4, [r0, #0x70]
        ldr.w r3, [r0, #0x94]
        eor.w r4, r8, r5
        eor.w r5, r2, r6
        eor.w r2, r9, r3
        eor.w r1, r12, r1
        bic.w r3, r2, r5, ror #21
        bic.w r6, r1, r2, ror #28
        eor.w r3, r3, r7, ror #21
        eor.w r6, r6, r5, ror #17
        str.w r3, [r0, #0x30]
        bic.w r3, r4, r1, ror #25
        str.w r6, [r0, #0x64]
        bic.w r6, r7, r4, ror #22
        eor.w r2, r3, r2, ror #21
        eor.w r1, r6, r1, ror #15
        bic.w r3, r5, r7
        str.w r1, [r0, #0xc0]
        ldr r1, [sp, #0x14]
        ldr r5, [r1]
        eor.w r3, r4, r3, ror #10
        str.w r2, [r0, #0x94]
        eor.w r1, r5, r3
        ldr.w r7, [r0, #0xc]
        eor.w r6, r11, r7
        ldr r2, [sp, #0x10]
        ldr.w r5, [r0, #0x38]
        eor.w r5, r2, r5
        bic.w r7, r5, r6, ror #2
        ldr.w r3, [r0, #0xa0]
        eor.w r3, r8, r3
        bic.w r4, r6, r3, ror #24
        eor.w r7, r7, r3, ror #26
        str.w r1, [r0]
        ldr.w r1, [r0, #0x98]
        eor.w r1, r12, r1
        eor.w r4, r4, r1, ror #29
        str.w r7, [r0, #0x98]
        ldr.w r7, [r0, #0x6c]
        str.w r4, [r0, #0x6c]
        eor.w r7, r9, r7
        bic.w r3, r3, r1, ror #5
        bic.w r4, r7, r5, ror #10
        eor.w r3, r3, r7, ror #28
        eor.w r6, r4, r6, ror #12
        str.w r3, [r0, #0x38]
        bic.w r1, r1, r7, ror #23
        ldr.w r7, [r0, #0x1c]
        ldr.w r3, [r0, #0x4c]
        ldr.w r4, [r0, #0x50]
        eor.w r8, r8, r4
        ldr.w r4, [r0, #0xb0]
        eor.w r4, r2, r4
        str.w r6, [r0, #0xa0]
        eor.w r3, lr, r3
        eor.w r5, r1, r5, ror #1
        bic.w r1, r8, r3, ror #23
        eor.w r7, r9, r7
        ldr.w r6, [r0, #0x80]
        str.w r5, [r0, #0xc]
        eor.w r5, r1, r7, ror #19
        eor.w r1, r10, r6
        str.w r5, [r0, #0x50]
        bic.w r5, r1, r8, ror #21
        bic.w r6, r3, r7, ror #28
        eor.w r5, r5, r3, ror #12
        bic.w r7, r7, r4, ror #16
        eor.w r3, r6, r4, ror #12
        str.w r5, [r0, #0x80]
        ldr.w r5, [r0, #0x88]
        eor.w r6, r7, r1, ror #24
        ldr.w r7, [r0, #0xbc]
        bic.w r1, r4, r1, ror #8
        eor.w r7, r9, r7
        eor.w r8, r1, r8, ror #29
        str.w r6, [r0, #0x1c]
        eor.w r5, r2, r5
        bic.w r1, r7, r5, ror #21
        str.w r3, [r0, #0x4c]
        ldr.w r3, [r0, #0x20]
        str.w r8, [r0, #0xb0]
        ldr.w r8, [sp, #0x4]
        ldr.w r6, [r0, #0x2c]
        eor.w r4, r8, r6
        eor.w r3, r12, r3
        ldr.w r12, [r0, #0x5c]
        eor.w r6, r11, r12
        eor.w r1, r1, r6, ror #23
        bic.w r12, r5, r6, ror #2
        str.w r1, [r0, #0x88]
        bic.w r1, r3, r7, ror #17
        bic.w r6, r6, r4, ror #19
        eor.w r1, r1, r5, ror #6
        ldr.w r5, [r0, #0xa8]
        eor.w r10, r10, r5
        eor.w r12, r12, r4, ror #21
        eor.w r6, r6, r3, ror #24
        str.w r1, [r0, #0xbc]
        str.w r6, [r0, #0x2c]
        bic.w r5, r4, r3, ror #5
        str.w r12, [r0, #0x5c]
        eor.w r5, r5, r7, ror #22
        ldr.w r1, [r0, #0x10]
        ldr.w r12, [r0, #0x44]
        ldr.w r7, [r0, #0x74]
        ldr.w r3, [r0, #0x7c]
        str.w r5, [r0, #0x20]
        eor.w r5, r2, r1
        eor.w r9, r9, r12
        eor.w r1, lr, r7
        bic.w r12, r1, r9, ror #24
        eor.w r7, r8, r3
        eor.w r12, r12, r5, ror #21
        bic.w r3, r7, r1, ror #1
        str.w r12, [r0, #0x7c]
        eor.w r12, r3, r9, ror #25
        bic.w r3, r10, r7, ror #12
        str.w r12, [r0, #0xa8]
        eor.w r1, r3, r1, ror #13
        bic.w r12, r5, r10, ror #30
        str.w r1, [r0, #0x10]
        eor.w r1, r12, r7, ror #10
        bic.w r5, r9, r5, ror #29
        str.w r1, [r0, #0x44]
        eor.w r5, r5, r10, ror #27
        ldr.w r9, [sp, #0x8]
        ldr.w r10, [r0, #0x4]
        ldr r1, [r0, #0x34]
        ldr.w r12, [r0, #0x60]
        ldr.w r7, [r0, #0x90]
        ldr.w r3, [r0, #0xc4]
        str.w r5, [r0, #0x74]
        eor.w r5, r8, r10
        eor.w r11, r11, r1
        eor.w r8, r2, r12
        eor.w r9, r9, r7
        eor.w r10, lr, r3
        bic.w r1, r9, r8, ror #21
        bic.w r12, r10, r9, ror #29
        eor.w r1, r1, r11, ror #20
        eor.w r12, r12, r8, ror #18
        str.w r1, [r0, #0x34]
        str.w r12, [r0, #0x60]
        bic.w r1, r5, r10, ror #25
        bic.w r12, r11, r5, ror #22
        eor.w r9, r1, r9, ror #22
        eor.w r10, r12, r10, ror #15
        str.w r9, [r0, #0x90]
        str.w r10, [r0, #0xc4]
        bic.w r11, r8, r11, ror #31
        ldr.w r8, [sp, #0x14]
        eor.w r11, r5, r11, ror #11
        ldr.w r5, [r8, #0x4]
        eor.w r11, r5, r11
        ldrd r5, r8, [r0, #192]
        ldrd r9, r10, [r0, #72]
        ldrd r1, r12, [r0, #32]
        eor.w r5, r5, r9, ror #12
        ldrd r9, r7, [r0, #152]
        eor.w r8, r8, r10, ror #12
        eor.w r5, r5, r9, ror #19
        eor.w r8, r8, r7, ror #19
        eor.w r9, r5, r12, ror #4
        eor.w r4, r8, r1, ror #4
        ldrd r5, r1, [r0, #112]
        str.w r11, [r0, #0x4]
        eor.w r3, r9, r1, ror #26
        eor.w r4, r4, r5, ror #27
        ldrd r7, r8, [r0, #48]
        ldrd r11, r5, [r0, #128]
        ldrd r9, r10, [r0, #8]
        eor.w r5, r7, r5, ror #20
        eor.w r11, r8, r11, ror #20
        eor.w r5, r5, r10, ror #7
        eor.w r11, r11, r9, ror #6
        ldrd r8, r9, [r0, #88]
        ldrd r10, r1, [r0, #168]
        eor.w r5, r5, r8, ror #3
        eor.w r11, r11, r9, ror #3
        eor.w r5, r5, r10, ror #22
        eor.w r11, r11, r1, ror #22
        ror.w r8, r3, #0xa
        ror.w r5, r5, #0x15
        eor.w r9, r8, r11, ror #21
        eor.w r10, r5, r4, ror #10
        str.w r9, [sp]
        str.w r10, [sp, #0x4]
        ldrd r9, r10, [r0, #96]
        ldrd r1, r12, [r0, #176]
        ldrd r7, r3, [r0, #56]
        eor.w r10, r10, r12, ror #8
        eor.w r9, r9, r1, ror #9
        eor.w r10, r10, r7, ror #30
        eor.w r9, r9, r3, ror #30
        ldrd r1, r12, [r0, #136]
        ldrd r7, r3, [r0, #16]
        eor.w r10, r10, r12, ror #11
        eor.w r9, r9, r1, ror #11
        eor.w r10, r10, r7, ror #6
        eor.w r1, r9, r3, ror #6
        ror.w r12, r10, #0x19
        eor.w r8, r8, r1, ror #25
        eor.w r9, r12, r4, ror #9
        str.w r8, [sp, #0xc]
        str.w r9, [sp, #0x8]
        ldrd r8, r10, [r0, #144]
        ldrd r7, r3, [r0, #24]
        ldrd lr, r6, [r0, #104]
        eor.w r10, r10, r7, ror #18
        eor.w r8, r8, r3, ror #18
        eor.w r10, r10, r6, ror #31
        eor.w r8, r8, lr
        ldrd r7, r3, [r0, #184]
        ldrd lr, r6, [r0, #64]
        eor.w r10, r10, r7, ror #18
        eor.w r8, r8, r3, ror #19
        eor.w r7, r10, r6, ror #1
        eor.w r8, r8, lr, ror #1
        eor.w r2, r7, r11, ror #22
        eor.w r11, r5, r8, ror #31
        ldrd r5, r10, [r0]
        str.w r11, [sp, #0x10]
        ldrd r11, r3, [r0, #80]
        ldrd lr, r6, [r0, #160]
        eor.w r5, r5, r3, ror #30
        eor.w r11, r10, r11, ror #31
        eor.w r5, r5, lr, ror #19
        eor.w r11, r11, r6, ror #20
        ldrd r10, r3, [r0, #40]
        ldrd lr, r6, [r0, #120]
        eor.w r5, r5, r10, ror #27
        eor.w r11, r11, r3, ror #27
        eor.w r5, r5, r6, ror #12
        eor.w r3, r11, lr, ror #13
        eor.w r10, r5, r1, ror #24
        eor.w r11, r3, r12
        eor.w r12, r7, r3, ror #31
        eor.w lr, r8, r5
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0x94]
        ldr.w r4, [r0, #0x48]
        eor.w r1, r9, r3
        ldr.w r3, [r0, #0x5c]
        ldr.w r5, [r0, #0x14]
        eor.w r6, r2, r5, ror #31
        eor.w r7, r12, r4, ror #22
        eor.w r4, r11, r3, ror #25
        bic.w r3, r7, r1, ror #28
        bic.w r5, r6, r4, ror #8
        eor.w r3, r3, r6, ror #11
        bic.w r6, r1, r6, ror #15
        str.w r3, [r0, #0x48]
        ldr.w r3, [r0, #0xa4]
        eor.w r6, r6, r4, ror #23
        eor.w r3, r8, r3, ror #20
        str.w r6, [r0, #0x94]
        bic.w r4, r4, r3, ror #21
        eor.w r6, r5, r3, ror #29
        eor.w r4, r4, r7, ror #13
        ldr.w r5, [r0, #0x6c]
        str.w r6, [r0, #0x14]
        str.w r4, [r0, #0x5c]
        ldr.w r4, [r0, #0x30]
        bic.w r6, r3, r7, ror #24
        eor.w r3, r9, r5, ror #31
        eor.w r6, r6, r1, ror #20
        ldr.w r5, [r0, #0xb0]
        str.w r6, [r0, #0xa4]
        eor.w r7, r10, r4, ror #21
        ldr.w r6, [r0, #0x20]
        eor.w r6, lr, r6, ror #14
        eor.w r5, r2, r5, ror #2
        ldr.w r4, [r0, #0x78]
        bic.w r1, r3, r5, ror #9
        eor.w r8, r8, r4, ror #13
        eor.w r1, r1, r7, ror #12
        bic.w r4, r6, r3, ror #24
        str.w r1, [r0, #0x78]
        eor.w r1, r4, r5, ror #1
        bic.w r4, r8, r6, ror #5
        str.w r1, [r0, #0x30]
        ldr.w r1, [r0, #0x44]
        eor.w r4, r4, r3, ror #29
        bic.w r3, r7, r8, ror #23
        str.w r4, [r0, #0xb0]
        eor.w r4, r3, r6, ror #28
        bic.w r7, r5, r7, ror #3
        str.w r4, [r0, #0x6c]
        ldr.w r3, [r0, #0xc]
        eor.w r5, r10, r3, ror #28
        ldr.w r4, [r0, #0x88]
        eor.w r8, r7, r8, ror #26
        eor.w r6, r2, r4, ror #4
        str.w r8, [r0, #0x20]
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0x54]
        eor.w r4, r8, r3, ror #30
        bic.w r3, r6, r5, ror #3
        eor.w r7, r9, r1, ror #1
        eor.w r1, r3, r4, ror #22
        ldr.w r3, [r0, #0xc4]
        str.w r1, [r0, #0xc]
        bic.w r1, r7, r6, ror #20
        eor.w r3, lr, r3, ror #10
        eor.w r1, r1, r5, ror #23
        bic.w r5, r5, r4, ror #19
        str.w r1, [r0, #0x88]
        eor.w r5, r5, r3, ror #23
        bic.w r1, r3, r7, ror #18
        str.w r5, [r0, #0x54]
        eor.w r1, r1, r6, ror #6
        bic.w r4, r4, r3, ror #4
        str.w r1, [r0, #0x44]
        eor.w r5, r4, r7, ror #22
        ldr.w r1, [r0, #0x60]
        ldr.w r7, [r0, #0x18]
        ldr.w r3, [r0, #0x98]
        ldr.w r6, [r0, #0x28]
        ldr.w r4, [r0, #0xac]
        str.w r5, [r0, #0xc4]
        eor.w r5, r2, r1, ror #25
        eor.w r9, r9, r7, ror #18
        eor.w r1, r12, r3, ror #29
        eor.w r7, r8, r6, ror #27
        eor.w r3, r11, r4, ror #12
        bic.w r6, r1, r9, ror #24
        bic.w r4, r7, r1, ror #1
        eor.w r6, r6, r5, ror #20
        eor.w r4, r4, r9, ror #25
        str.w r6, [r0, #0x28]
        str.w r4, [r0, #0xac]
        bic.w r6, r3, r7, ror #13
        bic.w r4, r5, r3, ror #30
        eor.w r1, r6, r1, ror #14
        eor.w r7, r4, r7, ror #11
        str.w r1, [r0, #0x60]
        str.w r7, [r0, #0x18]
        bic.w r5, r9, r5, ror #28
        ldr.w r9, [sp, #0xc]
        eor.w r5, r5, r3, ror #26
        ldr.w r1, [r0]
        ldr.w r7, [r0, #0x84]
        ldr r3, [r0, #0x3c]
        ldr.w r6, [r0, #0xbc]
        ldr r4, [r0, #0x74]
        str.w r5, [r0, #0x98]
        eor.w r5, r8, r1
        eor.w r1, r10, r7, ror #9
        eor.w r7, r2, r3, ror #23
        eor.w r3, r9, r6, ror #19
        eor.w r6, r12, r4, ror #4
        bic.w r4, r3, r7, ror #21
        bic.w r2, r6, r3, ror #28
        eor.w r4, r4, r1, ror #21
        eor.w r2, r2, r7, ror #17
        str.w r4, [r0, #0x84]
        str.w r2, [r0, #0x3c]
        bic.w r4, r5, r6, ror #25
        bic.w r2, r1, r5, ror #22
        eor.w r3, r4, r3, ror #21
        eor.w r6, r2, r6, ror #15
        str.w r3, [r0, #0xbc]
        str.w r6, [r0, #0x74]
        bic.w r1, r7, r1
        ldr r7, [sp, #0x14]
        ldr r7, [r7, #0x8]
        eor.w r5, r5, r1, ror #10
        ldr r2, [sp, #0x10]
        eor.w r5, r7, r5
        ldr.w r3, [r0, #0x90]
        ldr.w r4, [r0, #0x4c]
        ldr.w r1, [r0, #0xa0]
        ldr.w r6, [r0, #0x58]
        ldr.w r7, [r0, #0x10]
        str.w r5, [r0]
        eor.w r4, lr, r4, ror #22
        eor.w r5, r8, r1, ror #19
        eor.w r6, r10, r6, ror #24
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #23
        eor.w r3, r9, r3
        eor.w r1, r1, r3, ror #19
        str.w r1, [r0, #0xa0]
        ldr.w r1, [r0, #0x7c]
        eor.w r1, r8, r1, ror #12
        bic.w r8, r3, r7, ror #16
        bic.w r3, r4, r3, ror #28
        eor.w r8, r8, r6, ror #24
        eor.w r3, r3, r7, ror #12
        bic.w r7, r7, r6, ror #8
        str.w r8, [r0, #0x90]
        ldr.w r8, [r0, #0x68]
        eor.w r8, r9, r8
        eor.w r7, r7, r5, ror #29
        str.w r3, [r0, #0x4c]
        bic.w r6, r6, r5, ror #21
        ldr.w r5, [r0, #0x24]
        eor.w r3, r6, r4, ror #12
        ldr.w r4, [r0, #0x34]
        eor.w r6, r11, r4, ror #22
        ldr.w r4, [r0, #0xb4]
        str.w r7, [r0, #0x10]
        str.w r3, [r0, #0x58]
        eor.w r7, r12, r5, ror #14
        eor.w r3, r2, r4, ror #1
        bic.w r5, r7, r8, ror #23
        ldr.w r4, [r0, #0x8]
        eor.w r5, r5, r3, ror #1
        eor.w r4, r11, r4, ror #28
        str.w r5, [r0, #0x34]
        bic.w r5, r3, r6, ror #2
        bic.w r3, r8, r3, ror #10
        eor.w r5, r5, r1, ror #26
        eor.w r3, r3, r6, ror #12
        str.w r5, [r0, #0x24]
        bic.w r5, r6, r1, ror #24
        ldr.w r6, [r0, #0xc0]
        eor.w r12, r12, r6, ror #10
        eor.w r6, r5, r7, ror #29
        ldr.w r5, [r0, #0x40]
        str.w r3, [r0, #0x7c]
        bic.w r7, r1, r7, ror #5
        ldr.w r3, [r0, #0x50]
        str.w r6, [r0, #0x68]
        eor.w r1, r9, r5, ror #1
        eor.w r6, r7, r8, ror #28
        ldr.w r8, [sp, #0x4]
        eor.w r5, r8, r3, ror #31
        str.w r6, [r0, #0xb4]
        bic.w r3, r4, r5, ror #19
        bic.w r6, r5, r12, ror #5
        eor.w r3, r3, r12, ror #24
        bic.w r12, r12, r1, ror #17
        str.w r3, [r0, #0x50]
        ldr.w r7, [r0, #0x8c]
        eor.w r7, r2, r7, ror #4
        eor.w r3, r6, r1, ror #22
        bic.w r6, r7, r4, ror #2
        eor.w r12, r12, r7, ror #6
        eor.w r5, r6, r5, ror #21
        ldr.w r6, [r0, #0x2c]
        str.w r12, [r0, #0x40]
        str.w r5, [r0, #0x8]
        ldr.w r5, [r0, #0x64]
        ldr.w r12, [r0, #0x1c]
        bic.w r7, r1, r7, ror #21
        ldr.w r1, [r0, #0x9c]
        eor.w r4, r7, r4, ror #23
        ldr.w r7, [r0, #0xa8]
        str.w r3, [r0, #0xc0]
        eor.w r3, r2, r5, ror #25
        str.w r4, [r0, #0x8c]
        eor.w r4, r9, r12, ror #18
        eor.w r5, lr, r1, ror #29
        eor.w r1, r8, r6, ror #27
        bic.w r9, r5, r4, ror #24
        eor.w r10, r10, r7, ror #11
        eor.w r9, r9, r3, ror #21
        bic.w r12, r1, r5, ror #1
        str.w r9, [r0, #0x2c]
        eor.w r9, r12, r4, ror #25
        bic.w r12, r10, r1, ror #12
        str.w r9, [r0, #0xa8]
        eor.w r5, r12, r5, ror #13
        bic.w r9, r3, r10, ror #30
        str.w r5, [r0, #0x64]
        eor.w r5, r9, r1, ror #10
        bic.w r9, r4, r3, ror #29
        str.w r5, [r0, #0x1c]
        eor.w r5, r9, r10, ror #27
        ldr.w r9, [sp, #0x8]
        ldr.w r10, [r0, #0x4]
        ldr.w r1, [r0, #0x80]
        ldr.w r12, [r0, #0x38]
        ldr.w r7, [r0, #0xb8]
        ldr r3, [r0, #0x70]
        str.w r5, [r0, #0x9c]
        eor.w r5, r8, r10
        eor.w r11, r11, r1, ror #10
        eor.w r8, r2, r12, ror #23
        eor.w r9, r9, r7, ror #18
        eor.w r10, lr, r3, ror #5
        bic.w r1, r9, r8, ror #21
        bic.w r12, r10, r9, ror #29
        eor.w r1, r1, r11, ror #20
        eor.w r12, r12, r8, ror #18
        str.w r1, [r0, #0x80]
        str.w r12, [r0, #0x38]
        bic.w r1, r5, r10, ror #25
        bic.w r12, r11, r5, ror #22
        eor.w r9, r1, r9, ror #22
        eor.w r10, r12, r10, ror #15
        str.w r9, [r0, #0xb8]
        str.w r10, [r0, #0x70]
        bic.w r11, r8, r11, ror #31
        ldr.w r8, [sp, #0x14]
        eor.w r11, r5, r11, ror #11
        ldr.w r5, [r8, #0xc]
        eor.w r11, r5, r11
        ldrd r5, r8, [r0, #112]
        ldrd r9, r10, [r0, #72]
        str.w r11, [r0, #0x4]
        eor.w r11, r8, r9, ror #12
        ldrd r8, r1, [r0, #32]
        eor.w r5, r5, r10, ror #12
        eor.w r11, r11, r1, ror #19
        ldrd r9, r10, [r0, #192]
        eor.w r5, r5, r8, ror #19
        eor.w r11, r11, r10, ror #4
        eor.w r9, r5, r9, ror #4
        ldrd r10, r5, [r0, #152]
        ldrd r8, r1, [r0, #128]
        ldrd r12, r7, [r0, #88]
        ldrd lr, r3, [r0, #48]
        eor.w r1, r1, r7, ror #20
        eor.w r8, r8, r12, ror #20
        eor.w r1, r1, r3, ror #7
        eor.w r8, r8, lr, ror #6
        ldrd r12, r7, [r0, #8]
        eor.w r3, r11, r5, ror #26
        eor.w r7, r1, r7, ror #3
        eor.w r8, r8, r12, ror #3
        ldrd r1, r5, [r0, #168]
        eor.w r4, r9, r10, ror #27
        eor.w r11, r8, r5, ror #22
        ror.w r5, r3, #0xa
        eor.w r8, r5, r11, ror #21
        eor.w r9, r7, r1, ror #22
        str.w r8, [sp]
        ror.w r8, r9, #0x15
        eor.w r9, r8, r4, ror #10
        ldrd r10, r1, [r0, #56]
        ldrd r12, r7, [r0, #16]
        str.w r9, [sp, #0x4]
        eor.w r9, r10, r12, ror #9
        ldrd r10, r12, [r0, #176]
        eor.w r1, r1, r7, ror #8
        eor.w r9, r9, r10, ror #30
        ldrd r10, r7, [r0, #136]
        eor.w r1, r1, r12, ror #30
        eor.w r9, r9, r7, ror #11
        ldrd r12, r7, [r0, #96]
        eor.w r10, r1, r10, ror #11
        eor.w r1, r9, r12, ror #6
        eor.w r9, r10, r7, ror #6
        eor.w r5, r5, r1, ror #25
        ror.w r12, r9, #0x19
        str r5, [sp, #0xc]
        eor.w r9, r12, r4, ror #9
        ldrd r5, r10, [r0, #184]
        ldrd r7, r3, [r0, #144]
        str.w r9, [sp, #0x8]
        eor.w r10, r10, r3, ror #18
        ldrd r3, lr, [r0, #104]
        eor.w r5, r5, r7, ror #18
        eor.w r10, r10, r3, ror #31
        ldrd r7, r3, [r0, #64]
        eor.w r5, r5, lr
        eor.w r10, r10, r3, ror #18
        ldrd r3, lr, [r0, #24]
        eor.w r5, r5, r7, ror #19
        eor.w r7, r10, lr, ror #1
        eor.w r5, r5, r3, ror #1
        eor.w r2, r7, r11, ror #22
        eor.w r11, r8, r5, ror #31
        ldrd r8, r10, [r0]
        ldrd r3, lr, [r0, #160]
        str.w r11, [sp, #0x10]
        eor.w r11, r8, lr, ror #30
        ldrd r8, lr, [r0, #120]
        eor.w r10, r10, r3, ror #31
        eor.w r11, r11, lr, ror #19
        ldrd r3, lr, [r0, #80]
        eor.w r8, r10, r8, ror #20
        eor.w r11, r11, lr, ror #27
        ldrd r10, lr, [r0, #40]
        eor.w r8, r8, r3, ror #27
        eor.w r3, r11, lr, ror #12
        eor.w r8, r8, r10, ror #13
        eor.w r10, r3, r1, ror #24
        eor.w r11, r8, r12
        eor.w r12, r7, r8, ror #31
        eor.w lr, r5, r3
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0xbc]
        ldr.w r5, [r0, #0x48]
        ldr.w r6, [r0, #0x78]
        ldr.w r1, [r0, #0x8]
        ldr.w r7, [r0, #0x60]
        eor.w r4, r12, r5, ror #22
        eor.w r5, r8, r6, ror #20
        eor.w r6, r11, r1, ror #25
        eor.w r7, r2, r7, ror #31
        ldr.w r1, [r0, #0x28]
        eor.w r8, r8, r1, ror #13
        bic.w r1, r5, r4, ror #24
        eor.w r3, r9, r3
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x78]
        bic.w r1, r4, r3, ror #28
        bic.w r3, r3, r7, ror #15
        eor.w r1, r1, r7, ror #11
        eor.w r3, r3, r6, ror #23
        str.w r1, [r0, #0x48]
        str.w r3, [r0, #0xbc]
        bic.w r3, r7, r6, ror #8
        bic.w r7, r6, r5, ror #21
        ldr.w r6, [r0, #0x68]
        eor.w r1, r7, r4, ror #13
        eor.w r6, r9, r6, ror #31
        ldr.w r7, [r0, #0xc0]
        eor.w r4, r3, r5, ror #29
        eor.w r5, lr, r7, ror #14
        str.w r4, [r0, #0x60]
        str.w r1, [r0, #0x8]
        ldr.w r4, [r0, #0x84]
        eor.w r7, r10, r4, ror #21
        ldr.w r3, [r0, #0x10]
        bic.w r4, r8, r5, ror #5
        eor.w r1, r2, r3, ror #2
        eor.w r4, r4, r6, ror #29
        bic.w r3, r6, r1, ror #9
        str.w r4, [r0, #0x10]
        bic.w r6, r5, r6, ror #24
        bic.w r4, r1, r7, ror #3
        eor.w r1, r6, r1, ror #1
        eor.w r3, r3, r7, ror #12
        eor.w r6, r4, r8, ror #26
        str.w r1, [r0, #0x84]
        bic.w r4, r7, r8, ror #23
        str.w r6, [r0, #0xc0]
        eor.w r8, r4, r5, ror #28
        ldr.w r7, [r0, #0x34]
        str.w r3, [r0, #0x28]
        ldr.w r3, [r0, #0xa4]
        ldr.w r4, [r0, #0x70]
        ldr.w r6, [r0, #0x8c]
        str.w r8, [r0, #0x68]
        ldr.w r8, [sp]
        eor.w r3, r8, r3, ror #30
        eor.w r4, lr, r4, ror #10
        eor.w r1, r10, r7, ror #28
        eor.w r5, r2, r6, ror #4
        bic.w r7, r1, r3, ror #19
        bic.w r6, r5, r1, ror #3
        eor.w r7, r7, r4, ror #23
        eor.w r6, r6, r3, ror #22
        str.w r7, [r0, #0xa4]
        ldr.w r7, [r0, #0x1c]
        eor.w r7, r9, r7, ror #1
        str.w r6, [r0, #0x34]
        bic.w r6, r4, r7, ror #18
        bic.w r4, r3, r4, ror #4
        eor.w r3, r6, r5, ror #6
        bic.w r5, r7, r5, ror #20
        str.w r3, [r0, #0x1c]
        eor.w r4, r4, r7, ror #22
        ldr.w r6, [r0, #0x54]
        str.w r4, [r0, #0x70]
        ldr.w r3, [r0, #0xac]
        eor.w r7, r11, r3, ror #12
        ldr.w r4, [r0, #0x94]
        ldr.w r3, [r0, #0x38]
        eor.w r6, r8, r6, ror #27
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        ldr.w r9, [r0, #0x24]
        eor.w r1, r5, r1, ror #23
        eor.w r5, r12, r9, ror #29
        bic.w r9, r7, r6, ror #13
        str.w r1, [r0, #0x8c]
        eor.w r1, r9, r5, ror #14
        bic.w r9, r6, r5, ror #1
        str.w r1, [r0, #0x38]
        eor.w r9, r9, r4, ror #25
        bic.w r1, r3, r7, ror #30
        str.w r9, [r0, #0xac]
        eor.w r1, r1, r6, ror #11
        ldr.w r6, [r0, #0xb0]
        bic.w r9, r4, r3, ror #28
        eor.w r6, r2, r6, ror #23
        eor.w r7, r9, r7, ror #26
        ldr r2, [r0, #0x40]
        ldr.w r9, [sp, #0xc]
        eor.w r2, r9, r2, ror #19
        bic.w r5, r5, r4, ror #24
        ldr r4, [r0, #0x5c]
        eor.w r5, r5, r3, ror #20
        ldr.w r3, [r0, #0x9c]
        eor.w r3, r12, r3, ror #4
        str.w r5, [r0, #0x54]
        eor.w r4, r10, r4, ror #9
        str.w r1, [r0, #0x94]
        bic.w r1, r2, r6, ror #21
        ldr.w r5, [r0]
        str.w r7, [r0, #0x24]
        eor.w r1, r1, r4, ror #21
        eor.w r7, r8, r5
        bic.w r5, r7, r3, ror #25
        str.w r1, [r0, #0x5c]
        ldr r1, [sp, #0x14]
        eor.w r5, r5, r2, ror #21
        bic.w r2, r3, r2, ror #28
        str.w r5, [r0, #0x40]
        eor.w r5, r2, r6, ror #17
        bic.w r2, r6, r4
        str.w r5, [r0, #0xb0]
        eor.w r6, r7, r2, ror #10
        ldr.w r5, [r0, #0xc]
        bic.w r2, r4, r7, ror #22
        ldr.w r4, [r0, #0x7c]
        eor.w r2, r2, r3, ror #15
        ldr.w r7, [r0, #0x4c]
        str.w r2, [r0, #0x9c]
        ldr r2, [r1, #0x10]
        eor.w r3, r2, r6
        eor.w r1, r10, r5, ror #24
        eor.w r4, r8, r4, ror #19
        eor.w r6, lr, r7, ror #22
        bic.w r5, r1, r4, ror #21
        ldr r2, [sp, #0x10]
        ldr.w r7, [r0, #0x64]
        eor.w r7, r2, r7, ror #31
        str.w r3, [r0]
        bic.w r3, r7, r1, ror #8
        eor.w r5, r5, r6, ror #12
        eor.w r3, r3, r4, ror #29
        str.w r5, [r0, #0xc]
        ldr.w r5, [r0, #0xb8]
        str.w r3, [r0, #0x64]
        eor.w r3, r9, r5
        bic.w r5, r3, r7, ror #16
        bic.w r4, r4, r6, ror #23
        eor.w r1, r5, r1, ror #24
        eor.w r5, r4, r3, ror #19
        str.w r1, [r0, #0xb8]
        bic.w r1, r6, r3, ror #28
        str.w r5, [r0, #0x7c]
        eor.w r1, r1, r7, ror #12
        ldr.w r5, [r0, #0x80]
        ldr.w r7, [r0, #0x14]
        ldr.w r3, [r0, #0x6c]
        ldr.w r6, [r0, #0xc4]
        ldr.w r4, [r0, #0x2c]
        str.w r1, [r0, #0x4c]
        eor.w r5, r11, r5, ror #22
        eor.w r1, r2, r7, ror #1
        eor.w r7, r9, r3
        eor.w r3, r12, r6, ror #14
        eor.w r6, r8, r4, ror #12
        bic.w r8, r7, r1, ror #10
        bic.w r4, r3, r7, ror #23
        eor.w r8, r8, r5, ror #12
        eor.w r4, r4, r1, ror #1
        str.w r8, [r0, #0x2c]
        str.w r4, [r0, #0x80]
        bic.w r8, r6, r3, ror #5
        bic.w r4, r5, r6, ror #24
        eor.w r8, r8, r7, ror #28
        eor.w r7, r4, r3, ror #29
        str.w r8, [r0, #0x14]
        str.w r7, [r0, #0x6c]
        bic.w r5, r1, r5, ror #2
        ldr.w r8, [sp, #0x4]
        eor.w r5, r5, r6, ror #26
        ldr.w r1, [r0, #0x74]
        ldr.w r7, [r0, #0xa0]
        ldr.w r3, [r0, #0x30]
        ldr.w r6, [r0, #0x88]
        ldr.w r4, [r0, #0x18]
        str.w r5, [r0, #0xc4]
        eor.w r5, r12, r1, ror #10
        eor.w r1, r8, r7, ror #31
        eor.w r12, r11, r3, ror #28
        eor.w r7, r2, r6, ror #4
        eor.w r3, r9, r4, ror #1
        bic.w r6, r12, r1, ror #19
        bic.w r4, r7, r12, ror #2
        eor.w r6, r6, r5, ror #24
        eor.w r4, r4, r1, ror #21
        str.w r6, [r0, #0xa0]
        str.w r4, [r0, #0x30]
        bic.w r6, r3, r7, ror #21
        bic.w r4, r5, r3, ror #17
        eor.w r12, r6, r12, ror #23
        eor.w r7, r4, r7, ror #6
        str.w r12, [r0, #0x88]
        str.w r7, [r0, #0x18]
        bic.w r5, r1, r5, ror #5
        ldr.w r1, [r0, #0x3c]
        eor.w r5, r5, r3, ror #22
        ldr.w r4, [r0, #0x90]
        ldr.w r12, [r0, #0x20]
        ldr.w r6, [r0, #0x50]
        ldr.w r7, [r0, #0xa8]
        eor.w r3, r2, r1, ror #25
        eor.w r12, lr, r12, ror #29
        eor.w r4, r9, r4, ror #18
        eor.w r6, r8, r6, ror #27
        eor.w r7, r10, r7, ror #11
        bic.w r9, r6, r12, ror #1
        bic.w r10, r12, r4, ror #24
        eor.w r1, r9, r4, ror #25
        eor.w r9, r10, r3, ror #21
        str.w r1, [r0, #0xa8]
        ldr r1, [sp, #0x8]
        ldr.w r10, [r0, #0x44]
        eor.w r10, r1, r10, ror #18
        bic.w r1, r7, r6, ror #12
        str.w r5, [r0, #0x74]
        eor.w r1, r1, r12, ror #13
        str.w r9, [r0, #0x50]
        str.w r1, [r0, #0x3c]
        bic.w r5, r3, r7, ror #30
        bic.w r9, r4, r3, ror #29
        eor.w r5, r5, r6, ror #10
        eor.w r9, r9, r7, ror #27
        str.w r5, [r0, #0x90]
        ldr.w r5, [r0, #0x4]
        ldr r1, [r0, #0x58]
        ldr.w r12, [r0, #0xb4]
        ldr.w r7, [r0, #0x98]
        str.w r9, [r0, #0x20]
        eor.w r5, r8, r5
        eor.w r11, r11, r1, ror #10
        eor.w r8, r2, r12, ror #23
        eor.w r9, lr, r7, ror #5
        bic.w r1, r10, r8, ror #21
        bic.w r12, r9, r10, ror #29
        eor.w r1, r1, r11, ror #20
        eor.w r12, r12, r8, ror #18
        str.w r1, [r0, #0x58]
        str.w r12, [r0, #0xb4]
        bic.w r1, r5, r9, ror #25
        bic.w r12, r11, r5, ror #22
        eor.w r10, r1, r10, ror #22
        eor.w r9, r12, r9, ror #15
        str.w r10, [r0, #0x44]
        str.w r9, [r0, #0x98]
        bic.w r11, r8, r11, ror #31
        ldr.w r8, [sp, #0x14]
        eor.w r11, r5, r11, ror #11
        ldr.w r5, [r8, #0x14]
        eor.w r11, r5, r11
        ldrd r5, r8, [r0, #152]
        ldrd r9, r10, [r0, #72]
        str.w r11, [r0, #0x4]
        eor.w r11, r8, r9, ror #12
        ldrd r8, r9, [r0, #192]
        eor.w r5, r5, r10, ror #12
        eor.w r11, r11, r9, ror #19
        ldrd r9, r10, [r0, #112]
        eor.w r5, r5, r8, ror #19
        eor.w r11, r11, r9, ror #4
        ldrd r8, r9, [r0, #32]
        eor.w r5, r5, r10, ror #4
        eor.w r11, r11, r8, ror #26
        ldrd r8, r10, [r0, #88]
        ldrd r1, r12, [r0, #8]
        eor.w r4, r5, r9, ror #27
        eor.w r5, r10, r1, ror #20
        ldrd r9, r10, [r0, #128]
        eor.w r8, r8, r12, ror #20
        eor.w r5, r5, r9, ror #7
        ldrd r9, r1, [r0, #48]
        eor.w r8, r8, r10, ror #6
        eor.w r5, r5, r1, ror #3
        ldrd r10, r1, [r0, #168]
        eor.w r8, r8, r9, ror #3
        eor.w r5, r5, r10, ror #22
        eor.w r8, r8, r1, ror #22
        ror.w r3, r11, #0xa
        ror.w r7, r5, #0x15
        eor.w r11, r7, r4, ror #10
        eor.w r9, r3, r8, ror #21
        str.w r11, [sp, #0x4]
        ldrd r1, r5, [r0, #176]
        ldrd r6, r10, [r0, #96]
        str.w r9, [sp]
        eor.w r1, r1, r6, ror #8
        eor.w r5, r5, r10, ror #9
        ldrd r10, r6, [r0, #16]
        ldrd r11, r9, [r0, #136]
        eor.w r1, r1, r6, ror #30
        eor.w r5, r5, r10, ror #30
        eor.w r9, r1, r9, ror #11
        eor.w r11, r5, r11, ror #11
        ldrd r5, r10, [r0, #56]
        ldrd r1, r12, [r0, #64]
        eor.w r9, r9, r10, ror #6
        eor.w r11, r11, r5, ror #6
        ror.w r5, r9, #0x19
        eor.w r10, r3, r11, ror #25
        eor.w r9, r5, r4, ror #9
        str.w r10, [sp, #0xc]
        ldr.w r3, [r0, #0x40]
        ldrd r10, lr, [r0, #184]
        ldrd r6, r4, [r0, #104]
        eor.w r1, r1, lr, ror #18
        eor.w r10, r12, r10, ror #18
        eor.w r1, r1, r4, ror #31
        eor.w r10, r10, r6
        ldrd r12, lr, [r0, #24]
        ldrd r6, r4, [r0, #144]
        eor.w r1, r1, lr, ror #18
        eor.w r10, r10, r12, ror #19
        eor.w r1, r1, r6, ror #1
        eor.w lr, r10, r4, ror #1
        eor.w r2, r1, r8, ror #22
        eor.w r8, r7, lr, ror #31
        ldrd r10, r12, [r0]
        str.w r8, [sp, #0x10]
        ldrd r8, r7, [r0, #120]
        ldrd r6, r4, [r0, #40]
        eor.w r8, r10, r8, ror #30
        eor.w r10, r12, r7, ror #31
        eor.w r8, r8, r4, ror #19
        eor.w r10, r10, r6, ror #20
        ldrd r12, r7, [r0, #160]
        ldrd r6, r4, [r0, #80]
        eor.w r8, r8, r7, ror #27
        eor.w r10, r10, r12, ror #27
        eor.w r8, r8, r6, ror #12
        eor.w r12, r10, r4, ror #13
        eor.w r10, r8, r11, ror #24
        eor.w r11, r12, r5
        eor.w r12, r1, r12, ror #31
        eor.w lr, lr, r8
        ldr.w r8, [sp, #0x4]
        ldr.w r5, [r0, #0x48]
        eor.w r4, r12, r5, ror #22
        ldr.w r5, [r0, #0x28]
        ldr.w r1, [r0, #0x30]
        eor.w r6, r8, r5, ror #20
        eor.w r3, r9, r3
        eor.w r5, r11, r1, ror #25
        bic.w r1, r6, r4, ror #24
        ldr.w r7, [r0, #0x38]
        eor.w r1, r1, r3, ror #20
        eor.w r7, r2, r7, ror #31
        ror.w r1, r1, #0x1e
        str.w r1, [r0, #0x28]
        bic.w r1, r7, r5, ror #8
        str.w r9, [sp, #0x8]
        eor.w r1, r1, r6, ror #29
        bic.w r6, r5, r6, ror #21
        ror.w r1, r1, #0x1
        eor.w r6, r6, r4, ror #13
        str.w r1, [r0, #0x38]
        ror.w r6, r6, #0x9
        bic.w r1, r3, r7, ror #15
        str.w r6, [r0, #0x30]
        eor.w r1, r1, r5, ror #23
        ldr.w r5, [r0, #0x74]
        ror.w r1, r1, #0x12
        eor.w r5, lr, r5, ror #14
        str.w r1, [r0, #0x40]
        ldr.w r1, [r0, #0x54]
        eor.w r8, r8, r1, ror #13
        bic.w r1, r4, r3, ror #28
        ldr.w r3, [r0, #0x64]
        eor.w r1, r1, r7, ror #11
        eor.w r7, r2, r3, ror #2
        ldr.w r3, [r0, #0x5c]
        eor.w r3, r10, r3, ror #21
        ror.w r1, r1, #0x16
        bic.w r6, r3, r8, ror #23
        str.w r1, [r0, #0x48]
        eor.w r1, r6, r5, ror #28
        ldr.w r6, [r0, #0x6c]
        str.w r1, [r0, #0x6c]
        bic.w r1, r7, r3, ror #3
        bic.w r4, r8, r5, ror #5
        eor.w r8, r1, r8, ror #26
        eor.w r1, r9, r6, ror #31
        ror.w r8, r8, #0x1d
        str.w r8, [r0, #0x74]
        bic.w r8, r1, r7, ror #9
        bic.w r5, r5, r1, ror #24
        eor.w r8, r8, r3, ror #12
        eor.w r1, r4, r1, ror #29
        ror.w r8, r8, #0x14
        str.w r8, [r0, #0x54]
        eor.w r5, r5, r7, ror #1
        ldr.w r8, [sp]
        ror.w r5, r5, #0x1c
        str.w r5, [r0, #0x5c]
        ldr.w r5, [r0, #0x98]
        ldr.w r7, [r0, #0x80]
        ldr.w r3, [r0, #0x78]
        ror.w r1, r1, #0x17
        eor.w r7, r10, r7, ror #28
        eor.w r3, r8, r3, ror #30
        eor.w r5, lr, r5, ror #10
        bic.w r6, r7, r3, ror #19
        str.w r1, [r0, #0x64]
        eor.w r1, r6, r5, ror #23
        ldr.w r6, [r0, #0x88]
        ror.w r1, r1, #0x1b
        str.w r1, [r0, #0x78]
        eor.w r6, r2, r6, ror #4
        ldr.w r1, [r0, #0x90]
        bic.w r4, r6, r7, ror #3
        eor.w r1, r9, r1, ror #1
        eor.w r4, r4, r3, ror #22
        bic.w r3, r3, r5, ror #4
        ror.w r4, r4, #0x18
        str.w r4, [r0, #0x80]
        bic.w r5, r5, r1, ror #18
        eor.w r3, r3, r1, ror #22
        bic.w r4, r1, r6, ror #20
        ror.w r1, r3, #0xe
        eor.w r5, r5, r6, ror #6
        eor.w r7, r4, r7, ror #23
        ror.w r5, r5, #0x12
        ldr.w r3, [r0, #0xb4]
        str.w r5, [r0, #0x90]
        ror.w r7, r7, #0x4
        ldr.w r4, [r0, #0xbc]
        str.w r7, [r0, #0x88]
        ldr.w r5, [r0, #0xc4]
        ldr.w r6, [r0, #0xa4]
        ldr.w r7, [r0, #0xac]
        str.w r1, [r0, #0x98]
        eor.w r1, r2, r3, ror #25
        eor.w r9, r9, r4, ror #18
        eor.w r5, r12, r5, ror #29
        eor.w r3, r8, r6, ror #27
        eor.w r7, r11, r7, ror #12
        bic.w r6, r5, r9, ror #24
        bic.w r4, r3, r5, ror #1
        eor.w r6, r6, r1, ror #20
        eor.w r4, r4, r9, ror #25
        ror.w r6, r6, #0xd
        str.w r6, [r0, #0xa4]
        ror.w r6, r4, #0xc
        str.w r6, [r0, #0xac]
        bic.w r6, r7, r3, ror #13
        bic.w r4, r1, r7, ror #30
        eor.w r5, r6, r5, ror #14
        eor.w r3, r4, r3, ror #11
        ror.w r5, r5, #0x1f
        str.w r5, [r0, #0xb4]
        ror.w r5, r3, #0x1
        str.w r5, [r0, #0xbc]
        bic.w r5, r9, r1, ror #28
        ldr.w r9, [sp, #0xc]
        eor.w r5, r5, r7, ror #26
        ldr.w r1, [r0]
        ror.w r5, r5, #0x5
        ldr r7, [r0, #0x8]
        ldr r3, [r0, #0x10]
        ldr r6, [r0, #0x18]
        ldr r4, [r0, #0x20]
        str.w r5, [r0, #0xc4]
        eor.w r5, r8, r1
        eor.w r1, r10, r7, ror #9
        eor.w r7, r2, r3, ror #23
        eor.w r3, r9, r6, ror #19
        eor.w r6, r12, r4, ror #4
        bic.w r4, r3, r7, ror #21
        bic.w r2, r6, r3, ror #28
        eor.w r4, r4, r1, ror #21
        eor.w r2, r2, r7, ror #17
        ror.w r4, r4, #0x15
        str.w r4, [r0, #0x8]
        ror.w r4, r2, #0x19
        str.w r4, [r0, #0x10]
        bic.w r4, r5, r6, ror #25
        bic.w r2, r1, r5, ror #22
        eor.w r3, r4, r3, ror #21
        eor.w r6, r2, r6, ror #15
        str.w r3, [r0, #0x18]
        ror.w r3, r6, #0xa
        str.w r3, [r0, #0x20]
        bic.w r1, r7, r1
        ldr r7, [sp, #0x14]
        ldr r7, [r7, #0x18]
        eor.w r5, r5, r1, ror #10
        ldr r2, [sp, #0x10]
        eor.w r5, r7, r5
        ldr.w r3, [r0, #0x44]
        ldr.w r4, [r0, #0x4c]
        ldr.w r1, [r0, #0x2c]
        ldr.w r6, [r0, #0x34]
        ldr.w r7, [r0, #0x3c]
        str.w r5, [r0]
        eor.w r4, lr, r4, ror #22
        eor.w r5, r8, r1, ror #19
        eor.w r6, r10, r6, ror #24
        ldr.w r1, [r0, #0x50]
        eor.w r8, r8, r1, ror #12
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #23
        eor.w r3, r9, r3
        eor.w r1, r1, r3, ror #19
        ror.w r1, r1, #0x1f
        str.w r1, [r0, #0x2c]
        bic.w r1, r3, r7, ror #16
        bic.w r3, r4, r3, ror #28
        eor.w r1, r1, r6, ror #24
        eor.w r3, r3, r7, ror #12
        ror.w r1, r1, #0x12
        str.w r1, [r0, #0x44]
        ldr.w r1, [r0, #0x68]
        eor.w r1, r9, r1
        bic.w r7, r7, r6, ror #8
        bic.w r6, r6, r5, ror #21
        eor.w r7, r7, r5, ror #29
        ror.w r3, r3, #0x16
        eor.w r4, r6, r4, ror #12
        ldr.w r6, [r0, #0x70]
        eor.w r5, r12, r6, ror #14
        ror.w r6, r4, #0xa
        bic.w r4, r8, r5, ror #5
        str.w r6, [r0, #0x34]
        eor.w r6, r4, r1, ror #28
        str.w r3, [r0, #0x4c]
        ldr.w r4, [r0, #0x60]
        eor.w r3, r2, r4, ror #1
        ror.w r6, r6, #0x17
        bic.w r4, r1, r3, ror #10
        bic.w r1, r5, r1, ror #23
        str.w r6, [r0, #0x60]
        eor.w r6, r1, r3, ror #1
        ror.w r7, r7, #0x2
        ror.w r1, r6, #0x1c
        ldr.w r6, [r0, #0x58]
        str.w r1, [r0, #0x58]
        eor.w r1, r11, r6, ror #22
        str.w r7, [r0, #0x3c]
        bic.w r7, r3, r1, ror #2
        bic.w r3, r1, r8, ror #24
        eor.w r8, r7, r8, ror #26
        eor.w r7, r3, r5, ror #29
        ldr.w r6, [r0, #0x8c]
        eor.w r4, r4, r1, ror #12
        ldr.w r3, [r0, #0x84]
        eor.w r1, r11, r3, ror #28
        eor.w r6, r2, r6, ror #4
        ror.w r3, r8, #0x1d
        bic.w r5, r6, r1, ror #2
        ldr.w r8, [sp, #0x4]
        ror.w r4, r4, #0x13
        str.w r4, [r0, #0x50]
        ror.w r7, r7, #0x1f
        ldr.w r4, [r0, #0x7c]
        eor.w r4, r8, r4, ror #31
        str.w r7, [r0, #0x68]
        eor.w r5, r5, r4, ror #21
        ldr.w r7, [r0, #0x9c]
        ror.w r5, r5, #0x19
        str.w r5, [r0, #0x84]
        ldr.w r5, [r0, #0x94]
        str.w r3, [r0, #0x70]
        eor.w r3, r12, r7, ror #10
        bic.w r12, r1, r4, ror #19
        eor.w r7, r9, r5, ror #1
        eor.w r5, r12, r3, ror #24
        bic.w r12, r7, r6, ror #21
        ror.w r5, r5, #0x1b
        eor.w r1, r12, r1, ror #23
        str.w r5, [r0, #0x7c]
        ror.w r1, r1, #0x4
        str.w r1, [r0, #0x8c]
        bic.w r1, r3, r7, ror #17
        bic.w r5, r4, r3, ror #5
        eor.w r1, r1, r6, ror #6
        eor.w r12, r5, r7, ror #22
        ror.w r3, r1, #0x13
        str.w r3, [r0, #0x94]
        ror.w r5, r12, #0xe
        ldr.w r12, [r0, #0xb0]
        ldr.w r4, [r0, #0xb8]
        ldr.w r7, [r0, #0xc0]
        ldr.w r1, [r0, #0xa0]
        ldr.w r3, [r0, #0xa8]
        str.w r5, [r0, #0x9c]
        eor.w r12, r2, r12, ror #25
        eor.w r6, r9, r4, ror #18
        eor.w r5, lr, r7, ror #29
        eor.w r9, r8, r1, ror #27
        eor.w r4, r10, r3, ror #11
        bic.w r3, r5, r6, ror #24
        bic.w r10, r9, r5, ror #1
        eor.w r7, r3, r12, ror #21
        eor.w r1, r10, r6, ror #25
        ror.w r7, r7, #0xc
        str.w r7, [r0, #0xa0]
        ror.w r10, r1, #0xb
        str.w r10, [r0, #0xa8]
        bic.w r10, r4, r9, ror #12
        bic.w r3, r12, r4, ror #30
        eor.w r1, r10, r5, ror #13
        eor.w r5, r3, r9, ror #10
        ror.w r3, r1, #0x1f
        str.w r3, [r0, #0xb0]
        ror.w r5, r5, #0x1
        str.w r5, [r0, #0xb8]
        bic.w r1, r6, r12, ror #29
        ldr.w r10, [sp, #0x8]
        eor.w r6, r1, r4, ror #27
        ldr.w r12, [r0, #0x4]
        ror.w r3, r6, #0x4
        ldr r6, [r0, #0xc]
        ldr r1, [r0, #0x14]
        ldr.w r9, [r0, #0x1c]
        ldr r4, [r0, #0x24]
        str.w r3, [r0, #0xc0]
        eor.w r5, r8, r12
        eor.w r7, r11, r6, ror #10
        eor.w r12, r2, r1, ror #23
        eor.w r1, r10, r9, ror #18
        eor.w r6, lr, r4, ror #5
        bic.w r2, r1, r12, ror #21
        bic.w r3, r6, r1, ror #29
        eor.w r4, r2, r7, ror #20
        eor.w r3, r3, r12, ror #18
        ror.w r10, r4, #0x16
        str.w r10, [r0, #0xc]
        ror.w lr, r3, #0x19
        ldr.w r11, [sp, #0x14]
        bic.w r8, r5, r6, ror #25
        bic.w r3, r7, r5, ror #22
        eor.w r10, r8, r1, ror #22
        eor.w r3, r3, r6, ror #15
        str.w r10, [r0, #0x1c]
        ror.w r6, r3, #0xa
        str.w r6, [r0, #0x24]
        bic.w r12, r12, r7, ror #31
        ldr.w r8, [r11, #0x1c]
        ldr r1, [r11, #32]!
        str.w r11, [sp, #0x14]
        cmp r1, #0xff
        eor.w r3, r5, r12, ror #11
        str.w lr, [r0, #0x14]
        eor.w r1, r8, r3
        str r1, [r0, #0x4]

Lkeccak_f1600_x1_armv7m_asm_slothy_end:
        bne.w Lkeccak_f1600_x1_armv7m_asm_slothy_start @ imm = #-0x1600
        add sp, #0x18
        .cfi_adjust_cfa_offset -0x18
        pop.w {r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
        .cfi_restore r4
        .cfi_restore r5
        .cfi_restore r6
        .cfi_restore r7
        .cfi_restore r8
        .cfi_restore r9
        .cfi_restore r10
        .cfi_restore r11
        .cfi_restore lr
        .cfi_adjust_cfa_offset -0x28
        .cfi_endproc
        nop

MLD_ASM_FN_SIZE(keccak_f1600_x1_armv7m_asm)

#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
