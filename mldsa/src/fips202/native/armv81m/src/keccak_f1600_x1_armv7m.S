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
 * - [XKCP]
 *   eXtended Keccak Code Package
 *   Bertoni, Daemen, Peeters, Van Assche, Van Keer
 *   https://github.com/XKCP/XKCP
 */

/*
 * This clean, unscheduled source is derived from the public domain SLOTHY
 * source examples/naive/armv7m/keccak/keccakf1600_adomnicai_m4.s.
 * That source is based on public domain XKCP code @[XKCP], with additional
 * optimizations by Alexandre Adomnicai @[ADOMNICAI23].
 */

/*yaml
  Name: keccak_f1600_x1_armv7m_asm
  Description: Clean Armv7-M x1 Keccak-f[1600] permutation using a bit-interleaved state
  Signature: void mld_keccak_f1600_x1_armv7m_asm(uint32_t state[50], const uint32_t rc[49])
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
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
      description: 24 bit-interleaved round constants followed by the 0xff loop terminator
  Stack:
    bytes: 64
    description: register preservation (40 bytes) and scalar scratch storage (24 bytes)
*/

#include "../../../../common.h"

#if defined(MLD_FIPS202_ARMV81M_NEED_X1) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m/src/keccak_f1600_x1_armv7m.S using scripts/simpasm. Do not modify it directly.
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

Lmld_keccak_f1600_x1_armv7m_asm_slothy_start:
        ldr.w r3, [r0, #0x20]
        ldr.w r1, [r0, #0x48]
        ldr.w r5, [r0, #0x70]
        ldr.w r11, [r0, #0x98]
        ldr.w r12, [r0, #0xc0]
        eor.w r3, r3, r1
        eor.w r3, r3, r5
        eor.w r3, r3, r11
        eor.w r3, r3, r12
        ldr.w r7, [r0, #0xc]
        ldr.w r1, [r0, #0x34]
        ldr.w r5, [r0, #0x5c]
        ldr.w r11, [r0, #0x84]
        ldr.w r12, [r0, #0xac]
        eor.w r7, r7, r1
        eor.w r7, r7, r5
        eor.w r7, r7, r11
        eor.w r7, r7, r12
        eor.w r6, r3, r7, ror #31
        ldr.w r4, [r0, #0x14]
        ldr.w r1, [r0, #0x3c]
        ldr.w r5, [r0, #0x64]
        ldr.w r11, [r0, #0x8c]
        ldr.w r12, [r0, #0xb4]
        str.w r6, [sp]
        eor.w r4, r4, r1
        eor.w r4, r4, r5
        eor.w r4, r4, r11
        eor.w r4, r4, r12
        eor.w r6, r3, r4
        ldr.w r3, [r0, #0x18]
        ldr.w r1, [r0, #0x40]
        ldr.w r5, [r0, #0x68]
        ldr.w r11, [r0, #0x90]
        ldr.w r12, [r0, #0xb8]
        str.w r6, [sp, #0xc]
        eor.w r3, r3, r1
        eor.w r3, r3, r5
        eor.w r3, r3, r11
        eor.w r3, r3, r12
        eor.w r2, r7, r3
        ldr.w r7, [r0]
        ldr.w r1, [r0, #0x28]
        ldr.w r5, [r0, #0x50]
        ldr.w r11, [r0, #0x78]
        ldr.w r12, [r0, #0xa0]
        eor.w r7, r7, r1
        eor.w r7, r7, r5
        eor.w r7, r7, r11
        eor.w r7, r7, r12
        eor.w r10, r7, r4, ror #31
        ldr.w r4, [r0, #0x1c]
        ldr.w r1, [r0, #0x44]
        ldr.w r5, [r0, #0x6c]
        ldr.w r11, [r0, #0x94]
        ldr.w r12, [r0, #0xbc]
        eor.w r4, r4, r1
        eor.w r4, r4, r5
        eor.w r4, r4, r11
        eor.w r4, r4, r12
        eor.w lr, r4, r7
        ldr.w r7, [r0, #0x8]
        ldr.w r1, [r0, #0x30]
        ldr.w r5, [r0, #0x58]
        ldr.w r11, [r0, #0x80]
        ldr.w r12, [r0, #0xa8]
        eor.w r7, r7, r1
        eor.w r7, r7, r5
        eor.w r7, r7, r11
        eor.w r7, r7, r12
        eor.w r6, r7, r4, ror #31
        ldr.w r4, [r0, #0x24]
        ldr.w r1, [r0, #0x4c]
        ldr.w r5, [r0, #0x74]
        ldr.w r11, [r0, #0x9c]
        ldr.w r12, [r0, #0xc4]
        str.w r6, [sp, #0x10]
        eor.w r4, r4, r1
        eor.w r4, r4, r5
        eor.w r4, r4, r11
        eor.w r4, r4, r12
        eor.w r8, r4, r7
        ldr.w r7, [r0, #0x10]
        ldr.w r1, [r0, #0x38]
        ldr.w r5, [r0, #0x60]
        ldr.w r11, [r0, #0x88]
        ldr.w r12, [r0, #0xb0]
        str.w r8, [sp, #0x4]
        eor.w r7, r7, r1
        eor.w r7, r7, r5
        eor.w r7, r7, r11
        eor.w r7, r7, r12
        eor.w r9, r7, r4, ror #31
        ldr.w r4, [r0, #0x4]
        ldr.w r1, [r0, #0x2c]
        ldr.w r5, [r0, #0x54]
        ldr.w r11, [r0, #0x7c]
        ldr.w r12, [r0, #0xa4]
        str.w r9, [sp, #0x8]
        eor.w r4, r4, r1
        eor.w r4, r4, r5
        eor.w r4, r4, r11
        eor.w r4, r4, r12
        eor.w r11, r4, r7
        eor.w r12, r3, r4, ror #31
        ldr.w r3, [r0, #0x18]
        ldr.w r4, [r0, #0x48]
        ldr.w r5, [r0, #0x54]
        ldr.w r6, [r0, #0x84]
        ldr.w r7, [r0, #0xb4]
        eor.w r3, r9, r3
        eor.w r4, r12, r4
        eor.w r5, r8, r5
        eor.w r6, r11, r6
        eor.w r7, r2, r7
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x54]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #13
        str.w r1, [r0, #0x84]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0xb4]
        bic.w r1, r3, r7, ror #15
        eor.w r1, r1, r6, ror #23
        str.w r1, [r0, #0x18]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #11
        ldr.w r3, [r0, #0x8]
        ldr.w r4, [r0, #0x3c]
        ldr.w r5, [r0, #0x68]
        ldr.w r6, [r0, #0x9c]
        ldr.w r7, [r0, #0xa4]
        str.w r1, [r0, #0x48]
        eor.w r3, r10, r3
        eor.w r4, r2, r4
        eor.w r5, r9, r5
        eor.w r6, lr, r6
        eor.w r7, r8, r7
        bic.w r1, r5, r4, ror #9
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0xa4]
        bic.w r1, r6, r5, ror #24
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0x8]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x3c]
        bic.w r1, r3, r7, ror #23
        eor.w r1, r1, r6, ror #28
        str.w r1, [r0, #0x68]
        bic.w r1, r4, r3, ror #3
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0x24]
        ldr.w r4, [r0, #0x28]
        ldr.w r5, [r0, #0x58]
        ldr.w r6, [r0, #0x8c]
        ldr.w r7, [r0, #0xb8]
        str.w r1, [r0, #0x9c]
        eor.w r3, lr, r3
        eor.w r4, r8, r4
        eor.w r5, r10, r5
        eor.w r6, r2, r6
        eor.w r7, r9, r7
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #23
        str.w r1, [r0, #0x28]
        bic.w r1, r6, r5, ror #3
        eor.w r1, r1, r4, ror #22
        str.w r1, [r0, #0x58]
        bic.w r1, r7, r6, ror #20
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x8c]
        bic.w r1, r3, r7, ror #18
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0xb8]
        bic.w r1, r4, r3, ror #4
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x14]
        ldr.w r4, [r0, #0x40]
        ldr.w r5, [r0, #0x70]
        ldr.w r6, [r0, #0x78]
        ldr.w r7, [r0, #0xac]
        str.w r1, [r0, #0x24]
        eor.w r3, r2, r3
        eor.w r4, r9, r4
        eor.w r5, r12, r5
        eor.w r6, r8, r6
        eor.w r7, r11, r7
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x78]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xac]
        bic.w r1, r7, r6, ror #13
        eor.w r1, r1, r5, ror #14
        str.w r1, [r0, #0x14]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #11
        str.w r1, [r0, #0x40]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #26
        ldr.w r9, [sp, #0xc]
        ldr.w r3, [r0]
        ldr r4, [r0, #0x30]
        ldr r5, [r0, #0x64]
        ldr.w r6, [r0, #0x94]
        ldr.w r7, [r0, #0xc0]
        str.w r1, [r0, #0x70]
        eor.w r3, r8, r3
        eor.w r4, r10, r4
        eor.w r5, r2, r5
        eor.w r6, r9, r6
        eor.w r7, r12, r7
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x30]
        bic.w r1, r7, r6, ror #28
        eor.w r1, r1, r5, ror #17
        str.w r1, [r0, #0x64]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #21
        str.w r1, [r0, #0x94]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0xc0]
        bic.w r5, r5, r4
        ldr r1, [sp, #0x14]
        ldr r4, [r1]
        eor.w r3, r3, r5, ror #10
        eor.w r1, r4, r3
        ldr.w r2, [sp, #0x10]
        ldr.w r3, [r0, #0x1c]
        ldr.w r4, [r0, #0x4c]
        ldr.w r5, [r0, #0x50]
        ldr.w r6, [r0, #0x80]
        ldr.w r7, [r0, #0xb0]
        str.w r1, [r0]
        eor.w r3, r9, r3
        eor.w r4, lr, r4
        eor.w r5, r8, r5
        eor.w r6, r10, r6
        eor.w r7, r2, r7
        bic.w r1, r5, r4, ror #23
        eor.w r1, r1, r3, ror #19
        str.w r1, [r0, #0x50]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #12
        str.w r1, [r0, #0x80]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0xb0]
        bic.w r1, r3, r7, ror #16
        eor.w r1, r1, r6, ror #24
        str.w r1, [r0, #0x1c]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #12
        ldr.w r3, [r0, #0xc]
        ldr.w r4, [r0, #0x38]
        ldr.w r5, [r0, #0x6c]
        ldr.w r6, [r0, #0x98]
        ldr.w r7, [r0, #0xa0]
        str.w r1, [r0, #0x4c]
        eor.w r3, r11, r3
        eor.w r4, r2, r4
        eor.w r5, r9, r5
        eor.w r6, r12, r6
        eor.w r7, r8, r7
        bic.w r1, r5, r4, ror #10
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0xa0]
        bic.w r1, r6, r5, ror #23
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0xc]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #28
        str.w r1, [r0, #0x38]
        bic.w r1, r3, r7, ror #24
        eor.w r1, r1, r6, ror #29
        str.w r1, [r0, #0x6c]
        bic.w r1, r4, r3, ror #2
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0x20]
        ldr.w r4, [r0, #0x2c]
        ldr.w r5, [r0, #0x5c]
        ldr.w r6, [r0, #0x88]
        ldr.w r7, [r0, #0xbc]
        str.w r1, [r0, #0x98]
        eor.w r3, r12, r3
        eor.w r4, r8, r4
        eor.w r5, r11, r5
        eor.w r6, r2, r6
        eor.w r7, r9, r7
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #24
        str.w r1, [r0, #0x2c]
        bic.w r1, r6, r5, ror #2
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x5c]
        bic.w r1, r7, r6, ror #21
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x88]
        bic.w r1, r3, r7, ror #17
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0xbc]
        bic.w r1, r4, r3, ror #5
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x10]
        ldr.w r4, [r0, #0x44]
        ldr.w r5, [r0, #0x74]
        ldr.w r6, [r0, #0x7c]
        ldr.w r7, [r0, #0xa8]
        str.w r1, [r0, #0x20]
        eor.w r3, r2, r3
        eor.w r4, r9, r4
        eor.w r5, lr, r5
        eor.w r6, r8, r6
        eor.w r7, r10, r7
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #21
        str.w r1, [r0, #0x7c]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xa8]
        bic.w r1, r7, r6, ror #12
        eor.w r1, r1, r5, ror #13
        str.w r1, [r0, #0x10]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #10
        str.w r1, [r0, #0x44]
        bic.w r1, r4, r3, ror #29
        eor.w r1, r1, r7, ror #27
        ldr.w r9, [sp, #0x8]
        ldr.w r3, [r0, #0x4]
        ldr r4, [r0, #0x34]
        ldr r5, [r0, #0x60]
        ldr.w r6, [r0, #0x90]
        ldr.w r7, [r0, #0xc4]
        str.w r1, [r0, #0x74]
        eor.w r3, r8, r3
        eor.w r4, r11, r4
        eor.w r5, r2, r5
        eor.w r6, r9, r6
        eor.w r7, lr, r7
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #20
        str.w r1, [r0, #0x34]
        bic.w r1, r7, r6, ror #29
        eor.w r1, r1, r5, ror #18
        str.w r1, [r0, #0x60]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #22
        str.w r1, [r0, #0x90]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0xc4]
        bic.w r5, r5, r4, ror #31
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x4]
        eor.w r3, r3, r5, ror #11
        eor.w lr, r4, r3
        ldr.w r3, [r0, #0xc0]
        ldr.w r1, [r0, #0x48]
        ldr.w r5, [r0, #0x98]
        ldr.w r11, [r0, #0x24]
        ldr.w r12, [r0, #0x74]
        str.w lr, [r0, #0x4]
        eor.w r3, r3, r1, ror #12
        eor.w r3, r3, r5, ror #19
        eor.w r3, r3, r11, ror #4
        eor.w r3, r3, r12, ror #26
        ldr.w r7, [r0, #0x34]
        ldr.w r1, [r0, #0x80]
        ldr.w r5, [r0, #0x8]
        ldr.w r11, [r0, #0x5c]
        ldr.w r12, [r0, #0xac]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #6
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r3, r3, #0xa
        eor.w r6, r3, r7, ror #21
        ldr.w r4, [r0, #0x60]
        ldr.w r1, [r0, #0xb0]
        ldr.w r5, [r0, #0x3c]
        ldr.w r11, [r0, #0x88]
        ldr.w r12, [r0, #0x14]
        str.w r6, [sp]
        eor.w r4, r4, r1, ror #9
        eor.w r4, r4, r5, ror #30
        eor.w r4, r4, r11, ror #11
        eor.w r4, r4, r12, ror #6
        eor.w r6, r3, r4, ror #25
        ldr.w r3, [r0, #0x94]
        ldr.w r1, [r0, #0x18]
        ldr.w r5, [r0, #0x6c]
        ldr.w r11, [r0, #0xb8]
        ldr.w r12, [r0, #0x44]
        str.w r6, [sp, #0xc]
        eor.w r3, r3, r1, ror #18
        eor.w r3, r3, r5, ror #31
        eor.w r3, r3, r11, ror #18
        eor.w r3, r3, r12, ror #1
        eor.w r2, r3, r7, ror #22
        ldr.w r7, [r0]
        ldr.w r1, [r0, #0x54]
        ldr.w r5, [r0, #0xa0]
        ldr.w r11, [r0, #0x28]
        ldr.w r12, [r0, #0x7c]
        eor.w r7, r7, r1, ror #30
        eor.w r7, r7, r5, ror #19
        eor.w r7, r7, r11, ror #27
        eor.w r7, r7, r12, ror #12
        eor.w r10, r7, r4, ror #24
        ldr.w r4, [r0, #0x90]
        ldr.w r1, [r0, #0x1c]
        ldr.w r5, [r0, #0x68]
        ldr.w r11, [r0, #0xbc]
        ldr.w r12, [r0, #0x40]
        eor.w r4, r4, r1, ror #18
        eor.w r4, r4, r5
        eor.w r4, r4, r11, ror #19
        eor.w r4, r4, r12, ror #1
        eor.w lr, r4, r7
        ldr.w r7, [r0, #0x30]
        ldr.w r1, [r0, #0x84]
        ldr.w r5, [r0, #0xc]
        ldr.w r11, [r0, #0x58]
        ldr.w r12, [r0, #0xa8]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #7
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r7, r7, #0x15
        eor.w r6, r7, r4, ror #31
        ldr.w r4, [r0, #0xc4]
        ldr.w r1, [r0, #0x4c]
        ldr.w r5, [r0, #0x9c]
        ldr.w r11, [r0, #0x20]
        ldr.w r12, [r0, #0x70]
        str.w r6, [sp, #0x10]
        eor.w r4, r4, r1, ror #12
        eor.w r4, r4, r5, ror #19
        eor.w r4, r4, r11, ror #4
        eor.w r4, r4, r12, ror #27
        eor.w r8, r7, r4, ror #10
        ldr.w r7, [r0, #0x64]
        ldr.w r1, [r0, #0xb4]
        ldr.w r5, [r0, #0x38]
        ldr.w r11, [r0, #0x8c]
        ldr.w r12, [r0, #0x10]
        str.w r8, [sp, #0x4]
        eor.w r7, r7, r1, ror #8
        eor.w r7, r7, r5, ror #30
        eor.w r7, r7, r11, ror #11
        eor.w r7, r7, r12, ror #6
        ror.w r7, r7, #0x19
        eor.w r9, r7, r4, ror #9
        ldr.w r4, [r0, #0x4]
        ldr.w r1, [r0, #0x50]
        ldr.w r5, [r0, #0xa4]
        ldr.w r11, [r0, #0x2c]
        ldr.w r12, [r0, #0x78]
        str.w r9, [sp, #0x8]
        eor.w r4, r4, r1, ror #31
        eor.w r4, r4, r5, ror #20
        eor.w r4, r4, r11, ror #27
        eor.w r4, r4, r12, ror #13
        eor.w r11, r4, r7
        eor.w r12, r3, r4, ror #31
        ldr.w r3, [r0, #0x94]
        ldr.w r4, [r0, #0x48]
        ldr.w r5, [r0, #0xa4]
        ldr.w r6, [r0, #0x5c]
        ldr.w r7, [r0, #0x14]
        eor.w r3, r9, r3
        eor.w r4, r12, r4, ror #22
        eor.w r5, r8, r5, ror #20
        eor.w r6, r11, r6, ror #25
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0xa4]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #13
        str.w r1, [r0, #0x5c]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x14]
        bic.w r1, r3, r7, ror #15
        eor.w r1, r1, r6, ror #23
        str.w r1, [r0, #0x94]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #11
        ldr.w r3, [r0, #0x30]
        ldr.w r4, [r0, #0xb0]
        ldr.w r5, [r0, #0x6c]
        ldr.w r6, [r0, #0x20]
        ldr.w r7, [r0, #0x78]
        str.w r1, [r0, #0x48]
        eor.w r3, r10, r3, ror #21
        eor.w r4, r2, r4, ror #2
        eor.w r5, r9, r5, ror #31
        eor.w r6, lr, r6, ror #14
        eor.w r7, r8, r7, ror #13
        bic.w r1, r5, r4, ror #9
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0x78]
        bic.w r1, r6, r5, ror #24
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0x30]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0xb0]
        bic.w r1, r3, r7, ror #23
        eor.w r1, r1, r6, ror #28
        str.w r1, [r0, #0x6c]
        bic.w r1, r4, r3, ror #3
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0xc4]
        ldr.w r4, [r0, #0x54]
        ldr.w r5, [r0, #0xc]
        ldr.w r6, [r0, #0x88]
        ldr.w r7, [r0, #0x44]
        str.w r1, [r0, #0x20]
        eor.w r3, lr, r3, ror #10
        eor.w r4, r8, r4, ror #30
        eor.w r5, r10, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #23
        str.w r1, [r0, #0x54]
        bic.w r1, r6, r5, ror #3
        eor.w r1, r1, r4, ror #22
        str.w r1, [r0, #0xc]
        bic.w r1, r7, r6, ror #20
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x88]
        bic.w r1, r3, r7, ror #18
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0x44]
        bic.w r1, r4, r3, ror #4
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x60]
        ldr.w r4, [r0, #0x18]
        ldr.w r5, [r0, #0x98]
        ldr.w r6, [r0, #0x28]
        ldr.w r7, [r0, #0xac]
        str.w r1, [r0, #0xc4]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, r12, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r11, r7, ror #12
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x28]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xac]
        bic.w r1, r7, r6, ror #13
        eor.w r1, r1, r5, ror #14
        str.w r1, [r0, #0x60]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #11
        str.w r1, [r0, #0x18]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #26
        ldr.w r9, [sp, #0xc]
        ldr.w r3, [r0]
        ldr.w r4, [r0, #0x84]
        ldr r5, [r0, #0x3c]
        ldr.w r6, [r0, #0xbc]
        ldr r7, [r0, #0x74]
        str.w r1, [r0, #0x98]
        eor.w r3, r8, r3
        eor.w r4, r10, r4, ror #9
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #19
        eor.w r7, r12, r7, ror #4
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x84]
        bic.w r1, r7, r6, ror #28
        eor.w r1, r1, r5, ror #17
        str.w r1, [r0, #0x3c]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #21
        str.w r1, [r0, #0xbc]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0x74]
        bic.w r5, r5, r4
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x8]
        eor.w r3, r3, r5, ror #10
        eor.w r1, r4, r3
        ldr.w r2, [sp, #0x10]
        ldr.w r3, [r0, #0x90]
        ldr.w r4, [r0, #0x4c]
        ldr.w r5, [r0, #0xa0]
        ldr.w r6, [r0, #0x58]
        ldr.w r7, [r0, #0x10]
        str.w r1, [r0]
        eor.w r3, r9, r3
        eor.w r4, lr, r4, ror #22
        eor.w r5, r8, r5, ror #19
        eor.w r6, r10, r6, ror #24
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #23
        eor.w r1, r1, r3, ror #19
        str.w r1, [r0, #0xa0]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #12
        str.w r1, [r0, #0x58]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x10]
        bic.w r1, r3, r7, ror #16
        eor.w r1, r1, r6, ror #24
        str.w r1, [r0, #0x90]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #12
        ldr.w r3, [r0, #0x34]
        ldr.w r4, [r0, #0xb4]
        ldr.w r5, [r0, #0x68]
        ldr.w r6, [r0, #0x24]
        ldr.w r7, [r0, #0x7c]
        str.w r1, [r0, #0x4c]
        eor.w r3, r11, r3, ror #22
        eor.w r4, r2, r4, ror #1
        eor.w r5, r9, r5
        eor.w r6, r12, r6, ror #14
        eor.w r7, r8, r7, ror #12
        bic.w r1, r5, r4, ror #10
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0x7c]
        bic.w r1, r6, r5, ror #23
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0x34]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #28
        str.w r1, [r0, #0xb4]
        bic.w r1, r3, r7, ror #24
        eor.w r1, r1, r6, ror #29
        str.w r1, [r0, #0x68]
        bic.w r1, r4, r3, ror #2
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0xc0]
        ldr.w r4, [r0, #0x50]
        ldr.w r5, [r0, #0x8]
        ldr.w r6, [r0, #0x8c]
        ldr.w r7, [r0, #0x40]
        str.w r1, [r0, #0x24]
        eor.w r3, r12, r3, ror #10
        eor.w r4, r8, r4, ror #31
        eor.w r5, r11, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #24
        str.w r1, [r0, #0x50]
        bic.w r1, r6, r5, ror #2
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x8]
        bic.w r1, r7, r6, ror #21
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x8c]
        bic.w r1, r3, r7, ror #17
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0x40]
        bic.w r1, r4, r3, ror #5
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x64]
        ldr.w r4, [r0, #0x1c]
        ldr.w r5, [r0, #0x9c]
        ldr.w r6, [r0, #0x2c]
        ldr.w r7, [r0, #0xa8]
        str.w r1, [r0, #0xc0]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, lr, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r10, r7, ror #11
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #21
        str.w r1, [r0, #0x2c]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xa8]
        bic.w r1, r7, r6, ror #12
        eor.w r1, r1, r5, ror #13
        str.w r1, [r0, #0x64]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #10
        str.w r1, [r0, #0x1c]
        bic.w r1, r4, r3, ror #29
        eor.w r1, r1, r7, ror #27
        ldr.w r9, [sp, #0x8]
        ldr.w r3, [r0, #0x4]
        ldr.w r4, [r0, #0x80]
        ldr r5, [r0, #0x38]
        ldr.w r6, [r0, #0xb8]
        ldr r7, [r0, #0x70]
        str.w r1, [r0, #0x9c]
        eor.w r3, r8, r3
        eor.w r4, r11, r4, ror #10
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #18
        eor.w r7, lr, r7, ror #5
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #20
        str.w r1, [r0, #0x80]
        bic.w r1, r7, r6, ror #29
        eor.w r1, r1, r5, ror #18
        str.w r1, [r0, #0x38]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #22
        str.w r1, [r0, #0xb8]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0x70]
        bic.w r5, r5, r4, ror #31
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0xc]
        eor.w r3, r3, r5, ror #11
        eor.w lr, r4, r3
        ldr.w r3, [r0, #0x74]
        ldr.w r1, [r0, #0x48]
        ldr.w r5, [r0, #0x24]
        ldr.w r11, [r0, #0xc4]
        ldr.w r12, [r0, #0x9c]
        str.w lr, [r0, #0x4]
        eor.w r3, r3, r1, ror #12
        eor.w r3, r3, r5, ror #19
        eor.w r3, r3, r11, ror #4
        eor.w r3, r3, r12, ror #26
        ldr.w r7, [r0, #0x80]
        ldr.w r1, [r0, #0x58]
        ldr.w r5, [r0, #0x30]
        ldr.w r11, [r0, #0x8]
        ldr.w r12, [r0, #0xac]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #6
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r3, r3, #0xa
        eor.w r6, r3, r7, ror #21
        ldr.w r4, [r0, #0x38]
        ldr.w r1, [r0, #0x10]
        ldr.w r5, [r0, #0xb0]
        ldr.w r11, [r0, #0x8c]
        ldr.w r12, [r0, #0x60]
        str.w r6, [sp]
        eor.w r4, r4, r1, ror #9
        eor.w r4, r4, r5, ror #30
        eor.w r4, r4, r11, ror #11
        eor.w r4, r4, r12, ror #6
        eor.w r6, r3, r4, ror #25
        ldr.w r3, [r0, #0xbc]
        ldr.w r1, [r0, #0x94]
        ldr.w r5, [r0, #0x68]
        ldr.w r11, [r0, #0x44]
        ldr.w r12, [r0, #0x1c]
        str.w r6, [sp, #0xc]
        eor.w r3, r3, r1, ror #18
        eor.w r3, r3, r5, ror #31
        eor.w r3, r3, r11, ror #18
        eor.w r3, r3, r12, ror #1
        eor.w r2, r3, r7, ror #22
        ldr.w r7, [r0]
        ldr.w r1, [r0, #0xa4]
        ldr.w r5, [r0, #0x7c]
        ldr.w r11, [r0, #0x54]
        ldr.w r12, [r0, #0x2c]
        eor.w r7, r7, r1, ror #30
        eor.w r7, r7, r5, ror #19
        eor.w r7, r7, r11, ror #27
        eor.w r7, r7, r12, ror #12
        eor.w r10, r7, r4, ror #24
        ldr.w r4, [r0, #0xb8]
        ldr.w r1, [r0, #0x90]
        ldr.w r5, [r0, #0x6c]
        ldr.w r11, [r0, #0x40]
        ldr.w r12, [r0, #0x18]
        eor.w r4, r4, r1, ror #18
        eor.w r4, r4, r5
        eor.w r4, r4, r11, ror #19
        eor.w r4, r4, r12, ror #1
        eor.w lr, r4, r7
        ldr.w r7, [r0, #0x84]
        ldr.w r1, [r0, #0x5c]
        ldr.w r5, [r0, #0x34]
        ldr.w r11, [r0, #0xc]
        ldr.w r12, [r0, #0xa8]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #7
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r7, r7, #0x15
        eor.w r6, r7, r4, ror #31
        ldr.w r4, [r0, #0x70]
        ldr.w r1, [r0, #0x4c]
        ldr.w r5, [r0, #0x20]
        ldr.w r11, [r0, #0xc0]
        ldr.w r12, [r0, #0x98]
        str.w r6, [sp, #0x10]
        eor.w r4, r4, r1, ror #12
        eor.w r4, r4, r5, ror #19
        eor.w r4, r4, r11, ror #4
        eor.w r4, r4, r12, ror #27
        eor.w r8, r7, r4, ror #10
        ldr.w r7, [r0, #0x3c]
        ldr.w r1, [r0, #0x14]
        ldr.w r5, [r0, #0xb4]
        ldr.w r11, [r0, #0x88]
        ldr.w r12, [r0, #0x64]
        str.w r8, [sp, #0x4]
        eor.w r7, r7, r1, ror #8
        eor.w r7, r7, r5, ror #30
        eor.w r7, r7, r11, ror #11
        eor.w r7, r7, r12, ror #6
        ror.w r7, r7, #0x19
        eor.w r9, r7, r4, ror #9
        ldr.w r4, [r0, #0x4]
        ldr.w r1, [r0, #0xa0]
        ldr.w r5, [r0, #0x78]
        ldr.w r11, [r0, #0x50]
        ldr.w r12, [r0, #0x28]
        str.w r9, [sp, #0x8]
        eor.w r4, r4, r1, ror #31
        eor.w r4, r4, r5, ror #20
        eor.w r4, r4, r11, ror #27
        eor.w r4, r4, r12, ror #13
        eor.w r11, r4, r7
        eor.w r12, r3, r4, ror #31
        ldr.w r3, [r0, #0xbc]
        ldr.w r4, [r0, #0x48]
        ldr.w r5, [r0, #0x78]
        ldr.w r6, [r0, #0x8]
        ldr.w r7, [r0, #0x60]
        eor.w r3, r9, r3
        eor.w r4, r12, r4, ror #22
        eor.w r5, r8, r5, ror #20
        eor.w r6, r11, r6, ror #25
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x78]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #13
        str.w r1, [r0, #0x8]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x60]
        bic.w r1, r3, r7, ror #15
        eor.w r1, r1, r6, ror #23
        str.w r1, [r0, #0xbc]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #11
        ldr.w r3, [r0, #0x84]
        ldr.w r4, [r0, #0x10]
        ldr.w r5, [r0, #0x68]
        ldr.w r6, [r0, #0xc0]
        ldr.w r7, [r0, #0x28]
        str.w r1, [r0, #0x48]
        eor.w r3, r10, r3, ror #21
        eor.w r4, r2, r4, ror #2
        eor.w r5, r9, r5, ror #31
        eor.w r6, lr, r6, ror #14
        eor.w r7, r8, r7, ror #13
        bic.w r1, r5, r4, ror #9
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0x28]
        bic.w r1, r6, r5, ror #24
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0x84]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x10]
        bic.w r1, r3, r7, ror #23
        eor.w r1, r1, r6, ror #28
        str.w r1, [r0, #0x68]
        bic.w r1, r4, r3, ror #3
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0x70]
        ldr.w r4, [r0, #0xa4]
        ldr.w r5, [r0, #0x34]
        ldr.w r6, [r0, #0x8c]
        ldr.w r7, [r0, #0x1c]
        str.w r1, [r0, #0xc0]
        eor.w r3, lr, r3, ror #10
        eor.w r4, r8, r4, ror #30
        eor.w r5, r10, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #23
        str.w r1, [r0, #0xa4]
        bic.w r1, r6, r5, ror #3
        eor.w r1, r1, r4, ror #22
        str.w r1, [r0, #0x34]
        bic.w r1, r7, r6, ror #20
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x8c]
        bic.w r1, r3, r7, ror #18
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0x1c]
        bic.w r1, r4, r3, ror #4
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x38]
        ldr.w r4, [r0, #0x94]
        ldr.w r5, [r0, #0x24]
        ldr.w r6, [r0, #0x54]
        ldr.w r7, [r0, #0xac]
        str.w r1, [r0, #0x70]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, r12, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r11, r7, ror #12
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        str.w r1, [r0, #0x54]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xac]
        bic.w r1, r7, r6, ror #13
        eor.w r1, r1, r5, ror #14
        str.w r1, [r0, #0x38]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #11
        str.w r1, [r0, #0x94]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #26
        ldr.w r9, [sp, #0xc]
        ldr.w r3, [r0]
        ldr r4, [r0, #0x5c]
        ldr.w r5, [r0, #0xb0]
        ldr r6, [r0, #0x40]
        ldr.w r7, [r0, #0x9c]
        str.w r1, [r0, #0x24]
        eor.w r3, r8, r3
        eor.w r4, r10, r4, ror #9
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #19
        eor.w r7, r12, r7, ror #4
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x5c]
        bic.w r1, r7, r6, ror #28
        eor.w r1, r1, r5, ror #17
        str.w r1, [r0, #0xb0]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #21
        str.w r1, [r0, #0x40]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0x9c]
        bic.w r5, r5, r4
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x10]
        eor.w r3, r3, r5, ror #10
        eor.w r1, r4, r3
        ldr.w r2, [sp, #0x10]
        ldr.w r3, [r0, #0xb8]
        ldr.w r4, [r0, #0x4c]
        ldr.w r5, [r0, #0x7c]
        ldr.w r6, [r0, #0xc]
        ldr.w r7, [r0, #0x64]
        str.w r1, [r0]
        eor.w r3, r9, r3
        eor.w r4, lr, r4, ror #22
        eor.w r5, r8, r5, ror #19
        eor.w r6, r10, r6, ror #24
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #23
        eor.w r1, r1, r3, ror #19
        str.w r1, [r0, #0x7c]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #12
        str.w r1, [r0, #0xc]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        str.w r1, [r0, #0x64]
        bic.w r1, r3, r7, ror #16
        eor.w r1, r1, r6, ror #24
        str.w r1, [r0, #0xb8]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #12
        ldr.w r3, [r0, #0x80]
        ldr.w r4, [r0, #0x14]
        ldr.w r5, [r0, #0x6c]
        ldr.w r6, [r0, #0xc4]
        ldr.w r7, [r0, #0x2c]
        str.w r1, [r0, #0x4c]
        eor.w r3, r11, r3, ror #22
        eor.w r4, r2, r4, ror #1
        eor.w r5, r9, r5
        eor.w r6, r12, r6, ror #14
        eor.w r7, r8, r7, ror #12
        bic.w r1, r5, r4, ror #10
        eor.w r1, r1, r3, ror #12
        str.w r1, [r0, #0x2c]
        bic.w r1, r6, r5, ror #23
        eor.w r1, r1, r4, ror #1
        str.w r1, [r0, #0x80]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #28
        str.w r1, [r0, #0x14]
        bic.w r1, r3, r7, ror #24
        eor.w r1, r1, r6, ror #29
        str.w r1, [r0, #0x6c]
        bic.w r1, r4, r3, ror #2
        eor.w r1, r1, r7, ror #26
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0x74]
        ldr.w r4, [r0, #0xa0]
        ldr.w r5, [r0, #0x30]
        ldr.w r6, [r0, #0x88]
        ldr.w r7, [r0, #0x18]
        str.w r1, [r0, #0xc4]
        eor.w r3, r12, r3, ror #10
        eor.w r4, r8, r4, ror #31
        eor.w r5, r11, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #24
        str.w r1, [r0, #0xa0]
        bic.w r1, r6, r5, ror #2
        eor.w r1, r1, r4, ror #21
        str.w r1, [r0, #0x30]
        bic.w r1, r7, r6, ror #21
        eor.w r1, r1, r5, ror #23
        str.w r1, [r0, #0x88]
        bic.w r1, r3, r7, ror #17
        eor.w r1, r1, r6, ror #6
        str.w r1, [r0, #0x18]
        bic.w r1, r4, r3, ror #5
        eor.w r1, r1, r7, ror #22
        ldr.w r3, [r0, #0x3c]
        ldr.w r4, [r0, #0x90]
        ldr.w r5, [r0, #0x20]
        ldr.w r6, [r0, #0x50]
        ldr.w r7, [r0, #0xa8]
        str.w r1, [r0, #0x74]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, lr, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r10, r7, ror #11
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #21
        str.w r1, [r0, #0x50]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xa8]
        bic.w r1, r7, r6, ror #12
        eor.w r1, r1, r5, ror #13
        str.w r1, [r0, #0x3c]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #10
        str.w r1, [r0, #0x90]
        bic.w r1, r4, r3, ror #29
        eor.w r1, r1, r7, ror #27
        ldr.w r9, [sp, #0x8]
        ldr.w r3, [r0, #0x4]
        ldr r4, [r0, #0x58]
        ldr.w r5, [r0, #0xb4]
        ldr r6, [r0, #0x44]
        ldr.w r7, [r0, #0x98]
        str.w r1, [r0, #0x20]
        eor.w r3, r8, r3
        eor.w r4, r11, r4, ror #10
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #18
        eor.w r7, lr, r7, ror #5
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #20
        str.w r1, [r0, #0x58]
        bic.w r1, r7, r6, ror #29
        eor.w r1, r1, r5, ror #18
        str.w r1, [r0, #0xb4]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #22
        str.w r1, [r0, #0x44]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        str.w r1, [r0, #0x98]
        bic.w r5, r5, r4, ror #31
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x14]
        eor.w r3, r3, r5, ror #11
        eor.w lr, r4, r3
        ldr.w r3, [r0, #0x9c]
        ldr.w r1, [r0, #0x48]
        ldr.w r5, [r0, #0xc4]
        ldr.w r11, [r0, #0x70]
        ldr.w r12, [r0, #0x20]
        str.w lr, [r0, #0x4]
        eor.w r3, r3, r1, ror #12
        eor.w r3, r3, r5, ror #19
        eor.w r3, r3, r11, ror #4
        eor.w r3, r3, r12, ror #26
        ldr.w r7, [r0, #0x58]
        ldr.w r1, [r0, #0xc]
        ldr.w r5, [r0, #0x84]
        ldr.w r11, [r0, #0x30]
        ldr.w r12, [r0, #0xac]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #6
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r3, r3, #0xa
        eor.w r6, r3, r7, ror #21
        ldr.w r4, [r0, #0xb4]
        ldr.w r1, [r0, #0x64]
        ldr.w r5, [r0, #0x10]
        ldr.w r11, [r0, #0x88]
        ldr.w r12, [r0, #0x38]
        str.w r6, [sp]
        eor.w r4, r4, r1, ror #9
        eor.w r4, r4, r5, ror #30
        eor.w r4, r4, r11, ror #11
        eor.w r4, r4, r12, ror #6
        eor.w r6, r3, r4, ror #25
        ldr.w r3, [r0, #0x40]
        ldr.w r1, [r0, #0xbc]
        ldr.w r5, [r0, #0x6c]
        ldr.w r11, [r0, #0x1c]
        ldr.w r12, [r0, #0x90]
        str.w r6, [sp, #0xc]
        eor.w r3, r3, r1, ror #18
        eor.w r3, r3, r5, ror #31
        eor.w r3, r3, r11, ror #18
        eor.w r3, r3, r12, ror #1
        eor.w r2, r3, r7, ror #22
        ldr.w r7, [r0]
        ldr.w r1, [r0, #0x78]
        ldr.w r5, [r0, #0x2c]
        ldr.w r11, [r0, #0xa4]
        ldr.w r12, [r0, #0x50]
        eor.w r7, r7, r1, ror #30
        eor.w r7, r7, r5, ror #19
        eor.w r7, r7, r11, ror #27
        eor.w r7, r7, r12, ror #12
        eor.w r10, r7, r4, ror #24
        ldr.w r4, [r0, #0x44]
        ldr.w r1, [r0, #0xb8]
        ldr.w r5, [r0, #0x68]
        ldr.w r11, [r0, #0x18]
        ldr.w r12, [r0, #0x94]
        eor.w r4, r4, r1, ror #18
        eor.w r4, r4, r5
        eor.w r4, r4, r11, ror #19
        eor.w r4, r4, r12, ror #1
        eor.w lr, r4, r7
        ldr.w r7, [r0, #0x5c]
        ldr.w r1, [r0, #0x8]
        ldr.w r5, [r0, #0x80]
        ldr.w r11, [r0, #0x34]
        ldr.w r12, [r0, #0xa8]
        eor.w r7, r7, r1, ror #20
        eor.w r7, r7, r5, ror #7
        eor.w r7, r7, r11, ror #3
        eor.w r7, r7, r12, ror #22
        ror.w r7, r7, #0x15
        eor.w r6, r7, r4, ror #31
        ldr.w r4, [r0, #0x98]
        ldr.w r1, [r0, #0x4c]
        ldr.w r5, [r0, #0xc0]
        ldr.w r11, [r0, #0x74]
        ldr.w r12, [r0, #0x24]
        str.w r6, [sp, #0x10]
        eor.w r4, r4, r1, ror #12
        eor.w r4, r4, r5, ror #19
        eor.w r4, r4, r11, ror #4
        eor.w r4, r4, r12, ror #27
        eor.w r8, r7, r4, ror #10
        ldr.w r7, [r0, #0xb0]
        ldr.w r1, [r0, #0x60]
        ldr.w r5, [r0, #0x14]
        ldr.w r11, [r0, #0x8c]
        ldr.w r12, [r0, #0x3c]
        str.w r8, [sp, #0x4]
        eor.w r7, r7, r1, ror #8
        eor.w r7, r7, r5, ror #30
        eor.w r7, r7, r11, ror #11
        eor.w r7, r7, r12, ror #6
        ror.w r7, r7, #0x19
        eor.w r9, r7, r4, ror #9
        ldr.w r4, [r0, #0x4]
        ldr.w r1, [r0, #0x7c]
        ldr.w r5, [r0, #0x28]
        ldr.w r11, [r0, #0xa0]
        ldr.w r12, [r0, #0x54]
        str.w r9, [sp, #0x8]
        eor.w r4, r4, r1, ror #31
        eor.w r4, r4, r5, ror #20
        eor.w r4, r4, r11, ror #27
        eor.w r4, r4, r12, ror #13
        eor.w r11, r4, r7
        eor.w r12, r3, r4, ror #31
        ldr.w r3, [r0, #0x40]
        ldr.w r4, [r0, #0x48]
        ldr.w r5, [r0, #0x28]
        ldr.w r6, [r0, #0x30]
        ldr.w r7, [r0, #0x38]
        eor.w r3, r9, r3
        eor.w r4, r12, r4, ror #22
        eor.w r5, r8, r5, ror #20
        eor.w r6, r11, r6, ror #25
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        ror.w r1, r1, #0x1e
        str.w r1, [r0, #0x28]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #13
        ror.w r1, r1, #0x9
        str.w r1, [r0, #0x30]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        ror.w r1, r1, #0x1
        str.w r1, [r0, #0x38]
        bic.w r1, r3, r7, ror #15
        eor.w r1, r1, r6, ror #23
        ror.w r1, r1, #0x12
        str.w r1, [r0, #0x40]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #11
        ror.w r1, r1, #0x16
        ldr.w r3, [r0, #0x5c]
        ldr.w r4, [r0, #0x64]
        ldr.w r5, [r0, #0x6c]
        ldr.w r6, [r0, #0x74]
        ldr.w r7, [r0, #0x54]
        str.w r1, [r0, #0x48]
        eor.w r3, r10, r3, ror #21
        eor.w r4, r2, r4, ror #2
        eor.w r5, r9, r5, ror #31
        eor.w r6, lr, r6, ror #14
        eor.w r7, r8, r7, ror #13
        bic.w r1, r5, r4, ror #9
        eor.w r1, r1, r3, ror #12
        ror.w r1, r1, #0x14
        str.w r1, [r0, #0x54]
        bic.w r1, r6, r5, ror #24
        eor.w r1, r1, r4, ror #1
        ror.w r1, r1, #0x1c
        str.w r1, [r0, #0x5c]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #29
        ror.w r1, r1, #0x17
        str.w r1, [r0, #0x64]
        bic.w r1, r3, r7, ror #23
        eor.w r1, r1, r6, ror #28
        str.w r1, [r0, #0x6c]
        bic.w r1, r4, r3, ror #3
        eor.w r1, r1, r7, ror #26
        ror.w r1, r1, #0x1d
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0x98]
        ldr.w r4, [r0, #0x78]
        ldr.w r5, [r0, #0x80]
        ldr.w r6, [r0, #0x88]
        ldr.w r7, [r0, #0x90]
        str.w r1, [r0, #0x74]
        eor.w r3, lr, r3, ror #10
        eor.w r4, r8, r4, ror #30
        eor.w r5, r10, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #23
        ror.w r1, r1, #0x1b
        str.w r1, [r0, #0x78]
        bic.w r1, r6, r5, ror #3
        eor.w r1, r1, r4, ror #22
        ror.w r1, r1, #0x18
        str.w r1, [r0, #0x80]
        bic.w r1, r7, r6, ror #20
        eor.w r1, r1, r5, ror #23
        ror.w r1, r1, #0x4
        str.w r1, [r0, #0x88]
        bic.w r1, r3, r7, ror #18
        eor.w r1, r1, r6, ror #6
        ror.w r1, r1, #0x12
        str.w r1, [r0, #0x90]
        bic.w r1, r4, r3, ror #4
        eor.w r1, r1, r7, ror #22
        ror.w r1, r1, #0xe
        ldr.w r3, [r0, #0xb4]
        ldr.w r4, [r0, #0xbc]
        ldr.w r5, [r0, #0xc4]
        ldr.w r6, [r0, #0xa4]
        ldr.w r7, [r0, #0xac]
        str.w r1, [r0, #0x98]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, r12, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r11, r7, ror #12
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #20
        ror.w r1, r1, #0xd
        str.w r1, [r0, #0xa4]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        ror.w r1, r1, #0xc
        str.w r1, [r0, #0xac]
        bic.w r1, r7, r6, ror #13
        eor.w r1, r1, r5, ror #14
        ror.w r1, r1, #0x1f
        str.w r1, [r0, #0xb4]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #11
        ror.w r1, r1, #0x1
        str.w r1, [r0, #0xbc]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #26
        ror.w r1, r1, #0x5
        ldr.w r9, [sp, #0xc]
        ldr.w r3, [r0]
        ldr r4, [r0, #0x8]
        ldr r5, [r0, #0x10]
        ldr r6, [r0, #0x18]
        ldr r7, [r0, #0x20]
        str.w r1, [r0, #0xc4]
        eor.w r3, r8, r3
        eor.w r4, r10, r4, ror #9
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #19
        eor.w r7, r12, r7, ror #4
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #21
        ror.w r1, r1, #0x15
        str.w r1, [r0, #0x8]
        bic.w r1, r7, r6, ror #28
        eor.w r1, r1, r5, ror #17
        ror.w r1, r1, #0x19
        str.w r1, [r0, #0x10]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #21
        str.w r1, [r0, #0x18]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        ror.w r1, r1, #0xa
        str.w r1, [r0, #0x20]
        bic.w r5, r5, r4
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x18]
        eor.w r3, r3, r5, ror #10
        eor.w r1, r4, r3
        ldr.w r2, [sp, #0x10]
        ldr.w r3, [r0, #0x44]
        ldr.w r4, [r0, #0x4c]
        ldr.w r5, [r0, #0x2c]
        ldr.w r6, [r0, #0x34]
        ldr.w r7, [r0, #0x3c]
        str.w r1, [r0]
        eor.w r3, r9, r3
        eor.w r4, lr, r4, ror #22
        eor.w r5, r8, r5, ror #19
        eor.w r6, r10, r6, ror #24
        eor.w r7, r2, r7, ror #31
        bic.w r1, r5, r4, ror #23
        eor.w r1, r1, r3, ror #19
        ror.w r1, r1, #0x1f
        str.w r1, [r0, #0x2c]
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #12
        ror.w r1, r1, #0xa
        str.w r1, [r0, #0x34]
        bic.w r1, r7, r6, ror #8
        eor.w r1, r1, r5, ror #29
        ror.w r1, r1, #0x2
        str.w r1, [r0, #0x3c]
        bic.w r1, r3, r7, ror #16
        eor.w r1, r1, r6, ror #24
        ror.w r1, r1, #0x12
        str.w r1, [r0, #0x44]
        bic.w r1, r4, r3, ror #28
        eor.w r1, r1, r7, ror #12
        ror.w r1, r1, #0x16
        ldr.w r3, [r0, #0x58]
        ldr.w r4, [r0, #0x60]
        ldr.w r5, [r0, #0x68]
        ldr.w r6, [r0, #0x70]
        ldr.w r7, [r0, #0x50]
        str.w r1, [r0, #0x4c]
        eor.w r3, r11, r3, ror #22
        eor.w r4, r2, r4, ror #1
        eor.w r5, r9, r5
        eor.w r6, r12, r6, ror #14
        eor.w r7, r8, r7, ror #12
        bic.w r1, r5, r4, ror #10
        eor.w r1, r1, r3, ror #12
        ror.w r1, r1, #0x13
        str.w r1, [r0, #0x50]
        bic.w r1, r6, r5, ror #23
        eor.w r1, r1, r4, ror #1
        ror.w r1, r1, #0x1c
        str.w r1, [r0, #0x58]
        bic.w r1, r7, r6, ror #5
        eor.w r1, r1, r5, ror #28
        ror.w r1, r1, #0x17
        str.w r1, [r0, #0x60]
        bic.w r1, r3, r7, ror #24
        eor.w r1, r1, r6, ror #29
        ror.w r1, r1, #0x1f
        str.w r1, [r0, #0x68]
        bic.w r1, r4, r3, ror #2
        eor.w r1, r1, r7, ror #26
        ror.w r1, r1, #0x1d
        ldr.w r8, [sp, #0x4]
        ldr.w r3, [r0, #0x9c]
        ldr.w r4, [r0, #0x7c]
        ldr.w r5, [r0, #0x84]
        ldr.w r6, [r0, #0x8c]
        ldr.w r7, [r0, #0x94]
        str.w r1, [r0, #0x70]
        eor.w r3, r12, r3, ror #10
        eor.w r4, r8, r4, ror #31
        eor.w r5, r11, r5, ror #28
        eor.w r6, r2, r6, ror #4
        eor.w r7, r9, r7, ror #1
        bic.w r1, r5, r4, ror #19
        eor.w r1, r1, r3, ror #24
        ror.w r1, r1, #0x1b
        str.w r1, [r0, #0x7c]
        bic.w r1, r6, r5, ror #2
        eor.w r1, r1, r4, ror #21
        ror.w r1, r1, #0x19
        str.w r1, [r0, #0x84]
        bic.w r1, r7, r6, ror #21
        eor.w r1, r1, r5, ror #23
        ror.w r1, r1, #0x4
        str.w r1, [r0, #0x8c]
        bic.w r1, r3, r7, ror #17
        eor.w r1, r1, r6, ror #6
        ror.w r1, r1, #0x13
        str.w r1, [r0, #0x94]
        bic.w r1, r4, r3, ror #5
        eor.w r1, r1, r7, ror #22
        ror.w r1, r1, #0xe
        ldr.w r3, [r0, #0xb0]
        ldr.w r4, [r0, #0xb8]
        ldr.w r5, [r0, #0xc0]
        ldr.w r6, [r0, #0xa0]
        ldr.w r7, [r0, #0xa8]
        str.w r1, [r0, #0x9c]
        eor.w r3, r2, r3, ror #25
        eor.w r4, r9, r4, ror #18
        eor.w r5, lr, r5, ror #29
        eor.w r6, r8, r6, ror #27
        eor.w r7, r10, r7, ror #11
        bic.w r1, r5, r4, ror #24
        eor.w r1, r1, r3, ror #21
        ror.w r1, r1, #0xc
        str.w r1, [r0, #0xa0]
        bic.w r1, r6, r5, ror #1
        eor.w r1, r1, r4, ror #25
        ror.w r1, r1, #0xb
        str.w r1, [r0, #0xa8]
        bic.w r1, r7, r6, ror #12
        eor.w r1, r1, r5, ror #13
        ror.w r1, r1, #0x1f
        str.w r1, [r0, #0xb0]
        bic.w r1, r3, r7, ror #30
        eor.w r1, r1, r6, ror #10
        ror.w r1, r1, #0x1
        str.w r1, [r0, #0xb8]
        bic.w r1, r4, r3, ror #29
        eor.w r1, r1, r7, ror #27
        ror.w r1, r1, #0x4
        ldr.w r9, [sp, #0x8]
        ldr.w r3, [r0, #0x4]
        ldr r4, [r0, #0xc]
        ldr r5, [r0, #0x14]
        ldr r6, [r0, #0x1c]
        ldr r7, [r0, #0x24]
        str.w r1, [r0, #0xc0]
        eor.w r3, r8, r3
        eor.w r4, r11, r4, ror #10
        eor.w r5, r2, r5, ror #23
        eor.w r6, r9, r6, ror #18
        eor.w r7, lr, r7, ror #5
        bic.w r1, r6, r5, ror #21
        eor.w r1, r1, r4, ror #20
        ror.w r1, r1, #0x16
        str.w r1, [r0, #0xc]
        bic.w r1, r7, r6, ror #29
        eor.w r1, r1, r5, ror #18
        ror.w r1, r1, #0x19
        str.w r1, [r0, #0x14]
        bic.w r1, r3, r7, ror #25
        eor.w r1, r1, r6, ror #22
        str.w r1, [r0, #0x1c]
        bic.w r1, r4, r3, ror #22
        eor.w r1, r1, r7, ror #15
        ror.w r1, r1, #0xa
        str.w r1, [r0, #0x24]
        bic.w r5, r5, r4, ror #31
        ldr r1, [sp, #0x14]
        ldr r4, [r1, #0x1c]
        ldr r7, [r1, #32]!
        str r1, [sp, #0x14]
        cmp r7, #0xff
        eor.w r3, r3, r5, ror #11
        eor.w r1, r4, r3
        str.w r1, [r0, #0x4]

Lmld_keccak_f1600_x1_armv7m_asm_slothy_end:
        bne.w Lmld_keccak_f1600_x1_armv7m_asm_slothy_start @ imm = #-0x177c
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

MLD_ASM_FN_SIZE(keccak_f1600_x1_armv7m_asm)

#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
