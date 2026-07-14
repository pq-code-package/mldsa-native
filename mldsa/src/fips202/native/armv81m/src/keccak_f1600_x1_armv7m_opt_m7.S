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

/*yaml
  Name: keccak_f1600_x1_armv7m_asm
  Description: Armv8.1-M baseline x1 Keccak-f[1600] permutation using the Adomnicai/XKCP bit-interleaved Armv7-M representation
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
      description: Keccak round constants in bit-interleaved form (24 pairs of 32-bit words), followed by the 0xff loop terminator
  Stack:
    bytes: 264
    description: register preservation (40) + scalar scratch/intermediate state (224); no MVE/Q-register scratch
*/

/*
 * This file is derived from the public domain implementation @[XKCP].
 * Optimizations for Armv7-M are described in @[ADOMNICAI23].
 * The clean round body is adapted from SLOTHY's MIT-licensed
 * examples/naive/armv7m/keccak/keccakf1600_adomnicai_m7.s.
 * Further optimizations using SLOTHY are described in @[SLOTHYM7].
 */

#include "../../../../common.h"
#if defined(MLD_FIPS202_ARMV81M_NEED_X1) &&  !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/fips202/armv81m_opt/src/keccak_f1600_x1_armv7m_opt_m7.S using scripts/simpasm. Do not modify it directly.
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
        sub sp, #0xe0
        .cfi_adjust_cfa_offset 0xe0
        str r1, [sp, #0x14]

Lkeccak_f1600_x1_armv7m_slothy_start_round0:
        ldr.w r8, [r0, #0xc]
        ldr r5, [r0, #0x20]
        ldr r2, [r0, #0x48]
        ldr.w r12, [r0, #0x24]
        eors.w r1, r5, r2
        ldr.w r9, [r0, #0x34]
        ldr r2, [r0, #0x5c]
        eors.w r7, r8, r9
        ldr.w r10, [r0, #0x84]
        eors.w lr, r7, r2
        ldr.w r11, [r0, #0xac]
        eors.w r4, lr, r10
        ldr.w r10, [r0, #0x4c]
        eors.w r7, r4, r11
        eors.w r12, r12, r10
        ldr.w r8, [r0, #0x74]
        ldr r3, [r0, #0x30]
        eors.w r2, r12, r8
        ldr.w r6, [r0, #0x9c]
        eors.w r11, r2, r6
        ldr.w r8, [r0, #0xc4]
        eors.w r9, r11, r8
        ldr.w r10, [r0, #0x3c]
        ldr.w r8, [r0, #0xa8]
        ldr r5, [r0, #0x14]
        ldr.w r11, [r0, #0x28]
        eors.w r2, r5, r10
        ldr r4, [r0, #0x4]
        ldr r6, [r0, #0x8]
        ldr.w r10, [r0, #0x64]
        ldr r5, [r0, #0x10]
        eors.w lr, r2, r10
        eors r3, r6
        ldr.w r10, [r0, #0x70]
        ldr.w r12, [r0, #0x8c]
        eors.w r1, r1, r10
        ldr.w r10, [r0, #0x98]
        eors.w lr, lr, r12
        eors.w r6, r1, r10
        ldr.w r2, [r0, #0xc0]
        ldr.w r1, [r0, #0xb4]
        eors r2, r6
        ldr.w r10, [r0, #0x58]
        eor.w r12, r2, r7, ror #31
        eors.w r3, r3, r10
        ldr.w r10, [r0, #0x80]
        str.w r12, [sp]
        eors.w r12, r3, r10
        ldr.w r6, [r0, #0x88]
        eors.w r12, r12, r8
        ldr.w r10, [r0, #0x38]
        eors.w r8, r9, r12
        str.w r8, [sp, #0x4]
        ldr r3, [r0, #0x60]
        eors.w r10, r5, r10
        eors.w lr, lr, r1
        eors.w r3, r10, r3
        ldr.w r10, [r0, #0xb0]
        eors.w r5, r3, r6
        ldr r1, [r0, #0x1c]
        eors.w r3, r5, r10
        ldr r5, [r0, #0x40]
        ldr.w r10, [r0, #0x44]
        eors.w r6, r2, lr
        eors.w r10, r1, r10
        ldr r1, [r0, #0x2c]
        str r6, [sp, #0xc]
        ldr r2, [r0, #0x54]
        eors r1, r4
        ldr r6, [r0]
        ldr r4, [r0, #0x7c]
        eors r2, r1
        ldr r1, [r0, #0x50]
        eors.w r6, r6, r11
        ldr.w r11, [r0, #0x78]
        eors r6, r1
        ldr r1, [r0, #0x6c]
        eors.w r11, r6, r11
        ldr.w r6, [r0, #0xa0]
        eors.w r1, r10, r1
        eors.w r6, r11, r6
        ldr.w r11, [r0, #0x94]
        ldr.w r10, [r0, #0x18]
        eor.w r9, r3, r9, ror #31
        eors.w r5, r10, r5
        eors r2, r4
        ldr r4, [r0, #0x54]
        ldr.w r10, [r0, #0x68]
        eors.w r11, r1, r11
        eors.w r10, r5, r10
        ldr.w r1, [r0, #0x90]
        eors.w r4, r4, r8
        eors.w r1, r10, r1
        ldr.w r5, [r0, #0xbc]
        eor.w r10, r6, lr, ror #31
        ldr.w lr, [r0, #0xa4]
        eors.w r11, r11, r5
        eors.w r2, r2, lr
        ldr.w lr, [r0, #0xb8]
        rors.w r4, r4, #0x1e
        eor.w r12, r12, r11, ror #31
        str.w r12, [sp, #0x10]
        eors.w r1, r1, lr
        eors.w lr, r11, r6
        eors.w r11, r2, r3
        ldr r5, [r0, #0x18]
        eor.w r12, r1, r2, ror #31
        ldr.w r3, [r0, #0x84]
        eors.w r2, r7, r1
        ldr.w r7, [r0, #0xb4]
        ldr r6, [r0, #0x48]
        eors.w r5, r5, r9
        eors.w r3, r3, r11
        eors r7, r2
        ror.w r3, r3, #0x9
        ror.w r7, r7, #0x1
        eors.w r6, r6, r12
        bic.w r1, r7, r3
        rors.w r6, r6, #0x16
        eors r1, r4
        str r1, [sp, #0x50]
        bic.w r1, r3, r4
        rors.w r5, r5, #0x12
        eors r1, r6
        str r1, [sp, #0x48]
        bic.w r1, r5, r7
        bic.w r4, r4, r6
        eors r1, r3
        bic.w r6, r6, r5
        ldr r3, [r0, #0x68]
        eors r7, r6
        str r1, [sp, #0x58]
        ldr.w r6, [r0, #0x9c]
        eors.w r3, r3, r9
        str r7, [sp, #0x60]
        ldr.w r1, [r0, #0xa4]
        ldr r7, [r0, #0x8]
        eors.w r6, r6, lr
        eors r4, r5
        eors.w r1, r1, r8
        ror.w r6, r6, #0x1c
        ror.w r1, r1, #0x17
        eors.w r7, r7, r10
        rors.w r3, r3, #0x14
        bic.w r8, r7, r1
        ldr.w r5, [r0, #0x8c]
        eors.w r8, r8, r6
        str.w r8, [sp, #0x84]
        ldr.w r8, [r0, #0x3c]
        str r4, [sp, #0x40]
        bic.w r4, r1, r6
        eors r5, r2
        eors.w r8, r8, r2
        bic.w r6, r6, r3
        eors r4, r3
        str r4, [sp, #0x7c]
        ror.w r5, r5, #0x18
        rors.w r8, r8, #0x1d
        ldr r4, [r0, #0x58]
        eors.w r6, r6, r8
        str r6, [sp, #0x74]
        bic.w r3, r3, r8
        ldr r6, [r0, #0x28]
        eors.w r4, r4, r10
        bic.w r8, r8, r7
        rors.w r4, r4, #0x1b
        eors r7, r3
        ldr.w r3, [r0, #0xb8]
        eors.w r1, r8, r1
        ldr.w r8, [sp]
        str r1, [sp, #0x8c]
        eors.w r6, r6, r8
        str r7, [sp, #0x6c]
        rors.w r6, r6, #0xe
        bic.w r1, r5, r4
        eors.w r3, r3, r9
        eors r1, r6
        ldr r7, [r0, #0x24]
        ror.w r3, r3, #0x4
        str r1, [sp, #0x98]
        bic.w r1, r3, r5
        eors.w r7, r7, lr
        eors r1, r4
        str r1, [sp, #0xa0]
        rors.w r7, r7, #0x12
        bic.w r1, r4, r6
        bic.w r4, r7, r3
        eors r1, r7
        eors r5, r4
        ldr r4, [r0, #0x70]
        str r1, [sp, #0x90]
        ldr r1, [r0, #0x78]
        bic.w r7, r6, r7
        str.w r9, [sp, #0x8]
        eors r7, r3
        eors.w r4, r4, r12
        str r5, [sp, #0xa8]
        eors.w r1, r1, r8
        rors.w r4, r4, #0xd
        ldr r5, [r0, #0x14]
        str r7, [sp, #0xb0]
        ror.w r1, r1, #0xc
        ldr r7, [r0, #0x40]
        bic.w r3, r1, r4
        eors r5, r2
        ldr r6, [r0, #0x64]
        eors.w r7, r7, r9
        rors.w r5, r5, #0x1
        rors.w r7, r7, #0x5
        ldr.w r9, [r0, #0xac]
        eors r3, r7
        str r3, [sp, #0xc4]
        bic.w r3, r4, r7
        eors.w r9, r9, r11
        eors r3, r5
        ror.w r9, r9, #0x1f
        bic.w r7, r7, r5
        str r3, [sp, #0xbc]
        bic.w r3, r9, r1
        bic.w r5, r5, r9
        eors r4, r3
        eors.w r3, r5, r1
        str r4, [sp, #0xcc]
        ldr r1, [r0]
        eor.w r6, r6, r2
        ldr r2, [r0, #0x30]
        str r3, [sp, #0xd4]
        ldr.w r3, [r0, #0x94]
        eors.w r4, r7, r9
        eor.w r2, r2, r10
        ldr.w r9, [sp, #0xc]
        ror.w r2, r2, #0xa
        eor.w r1, r1, r8
        ldr.w r7, [r0, #0xc0]
        ror.w r6, r6, #0xa
        eor.w r3, r3, r9
        str r4, [sp, #0xdc]
        ror.w r3, r3, #0x15
        eor.w r7, r7, r12
        bic.w r5, r3, r6
        ror.w r7, r7, #0x19
        eors r5, r2
        str r5, [sp, #0x20]
        bics.w r4, r6, r2
        bic.w r5, r2, r1
        bic.w r2, r1, r7
        eors r1, r4
        bic.w r4, r7, r3
        eors r2, r3
        ldr.w r3, [r0, #0x80]
        eors r6, r4
        str r6, [sp, #0x28]
        ldr r4, [r0, #0x50]
        eors.w r3, r3, r10
        str r2, [sp, #0x30]
        ror.w r3, r3, #0xa
        eors.w r4, r4, r8
        ldr r2, [sp, #0x14]
        rors.w r4, r4, #0x1f
        ldr r6, [r0, #0x4c]
        eors r5, r7
        ldr r7, [r0, #0x1c]
        str r5, [sp, #0x38]
        ldr r2, [r2]
        eors.w r6, r6, lr
        eors.w r7, r7, r9
        rors.w r6, r6, #0x16
        rors.w r7, r7, #0x12
        bic.w r5, r4, r6
        eors r2, r1
        ldr.w r1, [r0, #0xb0]
        eors r5, r7
        str r5, [sp, #0x44]
        bic.w r5, r3, r4
        str r2, [sp, #0x18]
        ldr r2, [sp, #0x10]
        eors r5, r6
        eors r1, r2
        str r5, [sp, #0x4c]
        ror.w r1, r1, #0x2
        ldr r5, [r0, #0x6c]
        bic.w r6, r6, r7
        bic.w r7, r7, r1
        eors r6, r1
        eors r7, r3
        bic.w r3, r1, r3
        str r7, [sp, #0x5c]
        ldr r7, [r0, #0xc]
        eors r3, r4
        ldr r4, [r0, #0x38]
        eors.w r5, r5, r9
        eors.w r7, r7, r11
        str r3, [sp, #0x54]
        rors.w r7, r7, #0x1f
        eors r4, r2
        rors.w r5, r5, #0x13
        rors.w r4, r4, #0x1d
        ldr.w r1, [r0, #0xa0]
        str r6, [sp, #0x64]
        ldr.w r6, [r0, #0x98]
        bic.w r3, r5, r4
        eors.w r1, r1, r8
        ldr.w r8, [sp, #0x4]
        eors.w r6, r6, r12
        eors r3, r7
        ror.w r6, r6, #0x1c
        str r3, [sp, #0x68]
        bic.w r3, r6, r5
        ror.w r1, r1, #0x17
        eors r3, r4
        str r3, [sp, #0x70]
        bic.w r3, r1, r6
        bic.w r4, r4, r7
        eors r3, r5
        ldr r5, [r0, #0x5c]
        str r3, [sp, #0x78]
        bic.w r3, r7, r1
        ldr.w r7, [r0, #0x88]
        eors r3, r6
        eors.w r5, r5, r11
        str r3, [sp, #0x80]
        rors.w r5, r5, #0x1b
        eors r7, r2
        ldr r6, [r0, #0x20]
        ror.w r7, r7, #0x19
        ldr r3, [r0, #0x2c]
        eors r4, r1
        ldr.w r1, [r0, #0xbc]
        eors.w r6, r6, r12
        rors.w r6, r6, #0x13
        eors.w r3, r3, r8
        rors.w r3, r3, #0xe
        eors.w r1, r1, r9
        bic.w r12, r5, r3
        str r4, [sp, #0x88]
        eors.w r4, r12, r6
        str r4, [sp, #0x94]
        bic.w r4, r7, r5
        ror.w r1, r1, #0x4
        eors r4, r3
        str r4, [sp, #0x9c]
        bic.w r12, r1, r7
        bic.w r4, r6, r1
        eors.w r12, r12, r5
        ldr r5, [r0, #0x74]
        str.w r12, [sp, #0xa4]
        eors r7, r4
        ldr r4, [r0, #0x7c]
        eors.w r5, r5, lr
        ldr.w r12, [r0, #0x44]
        rors.w r5, r5, #0xc
        bic.w r6, r3, r6
        ldr r3, [r0, #0x10]
        eors.w r4, r4, r8
        eors.w r12, r12, r9
        str r7, [sp, #0xac]
        eors r3, r2
        ldr r7, [sp, #0x8]
        rors.w r3, r3, #0x1
        rors.w r12, r12, #0x4
        eors.w r9, r6, r1
        ror.w r4, r4, #0xb
        str.w r9, [sp, #0xb4]
        bic.w r1, r5, r12
        ldr.w r6, [r0, #0xa8]
        eors r1, r3
        str r1, [sp, #0xb8]
        bic.w r9, r4, r5
        eors.w r6, r6, r10
        eors.w r10, r9, r12
        ror.w r6, r6, #0x1f
        str.w r10, [sp, #0xc0]
        bic.w r10, r6, r4
        bic.w r9, r3, r6
        ldr r1, [r0, #0x60]
        eors.w r5, r10, r5
        ldr.w r10, [r0, #0x90]
        eors.w r4, r9, r4
        eor.w r1, r1, r2
        str r5, [sp, #0xc8]
        eor.w r10, r10, r7
        ror.w r1, r1, #0xb
        ror.w r10, r10, #0x16
        str r4, [sp, #0xd0]
        ldr r2, [r0, #0x34]
        bic.w r9, r12, r3
        ldr r3, [r0, #0x4]
        eor.w r2, r2, r11
        ldr.w r4, [r0, #0xc4]
        ror.w r2, r2, #0xa
        eor.w r3, r3, r8
        eors.w r6, r9, r6
        eor.w r4, r4, lr
        ror.w r4, r4, #0x19
        bic.w lr, r10, r1
        str r6, [sp, #0xd8]
        bic.w r5, r4, r10
        eors.w r8, lr, r2
        eors.w r12, r5, r1
        bics r1, r2
        str.w r12, [sp, #0x2c]
        bic.w r5, r3, r4
        str.w r8, [sp, #0x24]
        eors.w r7, r5, r10
        str r7, [sp, #0x34]
        bic.w r5, r2, r3
        ldr.w r11, [sp, #0x14]
        eors.w r6, r5, r4
        str r6, [sp, #0x3c]
        ldr.w r11, [r11, #0x4]
        eors.w r4, r3, r1
        eors.w r5, r4, r11
        str r5, [sp, #0x1c]

Lkeccak_f1600_x1_armv7m_slothy_start_round1:
        ldr.w r8, [sp, #0x40]
        ldr.w r9, [sp, #0x3c]
        ldr r3, [sp, #0x18]
        ldr r5, [sp, #0x64]
        eors.w lr, r3, r8
        eors.w r2, r9, r5
        ldr.w r12, [sp, #0x4c]
        ldr.w r8, [sp, #0x68]
        eors.w lr, lr, r8
        ldr.w r8, [sp, #0x24]
        eors.w r11, r8, r12
        ldr.w r9, [sp, #0x8c]
        eors.w r8, r2, r9
        ldr r2, [sp, #0x28]
        ldr r3, [sp, #0x2c]
        ldr r7, [sp, #0x50]
        ldr r6, [sp, #0x74]
        eors.w r4, r2, r7
        ldr r2, [sp, #0x90]
        ldr.w r12, [sp, #0x54]
        eors.w r5, lr, r2
        eors.w lr, r3, r12
        eors.w r1, r11, r6
        ldr r7, [sp, #0xb4]
        ldr.w r9, [sp, #0x60]
        eors.w r2, r8, r7
        ldr.w r12, [sp, #0x38]
        ldr.w r8, [sp, #0xdc]
        eors.w r11, r12, r9
        eors.w r6, r2, r8
        ldr.w r9, [sp, #0x78]
        ldr.w r12, [sp, #0x7c]
        eors.w r2, r4, r9
        ldr.w r8, [sp, #0x48]
        eors.w r7, lr, r12
        ldr r4, [sp, #0x20]
        ldr.w r12, [sp, #0x9c]
        eors.w r9, r4, r8
        ldr.w lr, [sp, #0xb8]
        eors.w r8, r1, r12
        eors.w r3, r5, lr
        ldr r5, [sp, #0x88]
        ldr r1, [sp, #0xc4]
        eors.w r5, r11, r5
        ldr.w lr, [sp, #0xb0]
        eors.w r10, r8, r1
        eors.w r4, r5, lr
        ldr r1, [sp, #0x70]
        eors.w r9, r9, r1
        ldr.w lr, [sp, #0xa4]
        ldr r5, [sp, #0x98]
        eors.w r8, r7, lr
        eors.w lr, r9, r5
        ldr.w r11, [sp, #0xa0]
        ldr r5, [sp, #0x1c]
        eors.w r11, r2, r11
        ldr r7, [sp, #0xc8]
        ldr.w r12, [sp, #0xcc]
        ldr.w r9, [sp, #0xd8]
        eors.w r8, r8, r12
        ldr.w r12, [sp, #0x44]
        eors.w r7, r11, r7
        ldr r1, [sp, #0x6c]
        eors.w r12, r5, r12
        ldr r2, [sp, #0x94]
        eors.w r11, r12, r1
        ldr r5, [sp, #0x5c]
        eors.w r12, r11, r2
        ldr.w r11, [sp, #0x34]
        eors.w r2, r4, r9
        eors.w r4, r11, r5
        ldr r1, [sp, #0xbc]
        ldr r5, [sp, #0x58]
        eors.w r1, r12, r1
        ldr.w r12, [sp, #0x30]
        eors.w r11, r1, r7
        eor.w r9, r7, r6, ror #31
        ldr r7, [sp, #0x84]
        eors.w r5, r12, r5
        ldr.w r12, [sp, #0x80]
        str.w r9, [sp, #0x8]
        eors.w r5, r5, r12
        eors r4, r7
        ldr r7, [sp, #0xa8]
        ldr.w r12, [sp, #0xac]
        eors r7, r5
        ldr r5, [sp, #0xd0]
        eors.w r4, r4, r12
        eors r7, r5
        ldr r5, [sp, #0xd4]
        eor.w r12, r7, r1, ror #31
        eors.w r1, r2, r8
        str r1, [sp, #0xc]
        eors r4, r5
        ldr r5, [sp, #0x6c]
        ldr r1, [sp, #0xc0]
        eor.w r2, r2, r10, ror #31
        eors.w lr, lr, r1
        str r2, [sp]
        eors.w r2, r10, r7
        ldr r1, [sp, #0x9c]
        eors.w r6, r6, lr
        ldr r7, [sp, #0xcc]
        eor.w lr, lr, r4, ror #31
        eors.w r1, r1, r11
        str.w lr, [sp, #0x10]
        eors r7, r2
        eors.w lr, r4, r3
        eor.w r10, r3, r8, ror #31
        eors r5, r6
        ldr.w r8, [sp, #0x60]
        ror.w r1, r1, #0x9
        ror.w r7, r7, #0x1
        rors.w r5, r5, #0x1e
        eors.w r8, r8, r12
        bic.w r4, r7, r1
        rors.w r8, r8, #0x16
        ldr r3, [sp, #0x30]
        eors r4, r5
        str r4, [r0, #0x38]
        bic.w r4, r5, r8
        eors.w r3, r3, r9
        bic.w r5, r1, r5
        rors.w r3, r3, #0x12
        eors.w r5, r5, r8
        eors r4, r3
        bic.w r8, r8, r3
        bic.w r3, r3, r7
        eors.w r8, r8, r7
        ldr r7, [sp, #0x20]
        eors r1, r3
        ldr r3, [sp, #0x54]
        str r4, [r0, #0x28]
        eors.w r7, r7, r10
        ldr r4, [sp, #0xbc]
        eors r3, r2
        str r6, [sp, #0x4]
        rors.w r3, r3, #0x1d
        eors r4, r6
        bic.w r6, r3, r7
        str r5, [r0, #0x30]
        ldr r5, [sp, #0xa4]
        str.w r8, [r0, #0x48]
        ror.w r4, r4, #0x17
        str r1, [r0, #0x40]
        eors.w r1, r6, r4
        str r1, [r0, #0x74]
        ldr r1, [sp, #0xb4]
        ldr.w r8, [sp, #0x80]
        eors.w r1, r1, lr
        bic.w r6, r7, r4
        ror.w r1, r1, #0x1c
        eors.w r8, r8, r9
        bic.w r4, r4, r1
        rors.w r8, r8, #0x14
        eors.w r4, r4, r8
        eors r6, r1
        str r6, [r0, #0x6c]
        eors r5, r2
        str r4, [r0, #0x64]
        ldr r6, [sp, #0x3c]
        bic.w r1, r1, r8
        ldr r4, [sp, #0xd0]
        eors r1, r3
        eors.w r6, r6, lr
        bic.w r8, r8, r3
        rors.w r6, r6, #0x12
        eors.w r4, r4, r9
        eors.w r8, r8, r7
        ldr r3, [sp, #0x70]
        ror.w r4, r4, #0x4
        ror.w r5, r5, #0x18
        bic.w r7, r6, r4
        eors.w r3, r3, r10
        eors r7, r5
        rors.w r3, r3, #0x1b
        str.w r7, [r0, #0x90]
        bic.w r7, r4, r5
        str.w r8, [r0, #0x54]
        eors.w r8, r7, r3
        ldr r7, [sp, #0x40]
        str.w r8, [r0, #0x88]
        ldr.w r8, [sp]
        bic.w r5, r5, r3
        eors.w r7, r7, r8
        str r1, [r0, #0x5c]
        rors.w r7, r7, #0xe
        ldr r1, [sp, #0x2c]
        eors r5, r7
        bic.w r3, r3, r7
        bic.w r7, r7, r6
        eors r1, r2
        eors r7, r4
        ldr r4, [sp, #0x88]
        str.w r7, [r0, #0x98]
        ldr r7, [sp, #0x90]
        str.w r5, [r0, #0x80]
        eors.w r4, r4, r12
        rors.w r1, r1, #0x1
        eors.w r7, r7, r8
        eors.w r5, r3, r6
        str r5, [r0, #0x78]
        ldr r3, [sp, #0x58]
        ror.w r7, r7, #0xc
        rors.w r4, r4, #0xd
        ldr r5, [sp, #0xc4]
        eors.w r3, r3, r9
        bic.w r6, r7, r4
        rors.w r3, r3, #0x5
        eors.w r5, r5, r11
        bic.w r9, r4, r3
        ror.w r5, r5, #0x1f
        eors.w r9, r9, r1
        eors r6, r3
        bic.w r3, r3, r1
        str.w r6, [r0, #0xac]
        eors r3, r5
        bic.w r6, r1, r5
        str.w r9, [r0, #0xa4]
        eors.w r1, r6, r7
        ldr r6, [sp, #0x18]
        bic.w r5, r5, r7
        ldr r7, [sp, #0xd8]
        str.w r1, [r0, #0xbc]
        ldr r1, [sp, #0x7c]
        str.w r3, [r0, #0xc4]
        eor.w r7, r7, r12
        eors.w r3, r5, r4
        str.w r3, [r0, #0xb4]
        ldr r3, [sp, #0xac]
        ror.w r7, r7, #0x19
        ldr.w r9, [sp, #0xc]
        eor.w r3, r3, r9
        eor.w r6, r6, r8
        ror.w r3, r3, #0x15
        bic.w r4, r6, r7
        eors.w r5, r4, r3
        ldr r4, [sp, #0x48]
        eor.w r1, r1, r2
        str r5, [r0, #0x18]
        eor.w r4, r4, r10
        ror.w r1, r1, #0xa
        ror.w r4, r4, #0xa
        bic.w r2, r3, r1
        bics.w r5, r1, r4
        eors r2, r4
        eors r5, r6
        bic.w r4, r4, r6
        ldr r6, [sp, #0x14]
        eors r4, r7
        str r4, [r0, #0x20]
        ldr r4, [sp, #0x68]
        ldr r6, [r6, #0x8]
        str r2, [r0, #0x8]
        eors r5, r6
        str r5, [r0]
        bic.w r6, r7, r3
        ldr r2, [sp, #0x64]
        eors.w r4, r4, r8
        ldr r7, [sp, #0x34]
        rors.w r4, r4, #0x1f
        eors.w r2, r2, lr
        eors.w r7, r7, r9
        rors.w r2, r2, #0x16
        rors.w r7, r7, #0x12
        eors r1, r6
        ldr r6, [sp, #0x98]
        str r1, [r0, #0x10]
        bic.w r3, r2, r7
        bic.w r5, r4, r2
        eors.w r6, r6, r10
        eors.w r1, r5, r7
        ror.w r6, r6, #0xa
        ldr r5, [sp, #0xc8]
        str r1, [r0, #0x2c]
        bic.w r1, r6, r4
        eors r1, r2
        ldr r2, [sp, #0x10]
        eors r5, r2
        str r1, [r0, #0x34]
        ror.w r5, r5, #0x2
        ldr r1, [sp, #0xb8]
        eors r3, r5
        bic.w r7, r7, r5
        eors r7, r6
        eors.w r1, r1, r8
        str r7, [r0, #0x44]
        bic.w r6, r5, r6
        ldr r7, [sp, #0xb0]
        ldr.w r8, [sp, #0x84]
        ror.w r1, r1, #0x17
        eors r6, r4
        eors.w r7, r7, r12
        eors.w r8, r8, r9
        ror.w r7, r7, #0x1c
        str r6, [r0, #0x3c]
        ldr r5, [sp, #0x50]
        bic.w r4, r1, r7
        rors.w r8, r8, #0x13
        ldr r6, [sp, #0x24]
        eors.w r4, r4, r8
        str r4, [r0, #0x60]
        eors r5, r2
        bic.w r4, r7, r8
        rors.w r5, r5, #0x1d
        eors.w r6, r6, r11
        bic.w r8, r8, r5
        eors r4, r5
        str r4, [r0, #0x58]
        rors.w r6, r6, #0x1f
        str r3, [r0, #0x4c]
        bic.w r3, r5, r6
        eors.w r4, r8, r6
        ldr r5, [sp, #0xd4]
        bic.w r8, r6, r1
        ldr r6, [sp, #0x74]
        str r4, [r0, #0x50]
        eors.w r5, r5, r9
        eors r3, r1
        ldr r4, [sp, #0x38]
        eors.w r1, r8, r7
        ldr.w r8, [sp, #0x4]
        ldr r7, [sp, #0xa0]
        eors.w r4, r4, r12
        ldr.w r12, [sp, #0x44]
        ror.w r5, r5, #0x4
        str r3, [r0, #0x70]
        eors.w r6, r6, r11
        eors.w r12, r12, r8
        eors r7, r2
        rors.w r6, r6, #0x1b
        ror.w r7, r7, #0x19
        rors.w r12, r12, #0xe
        bic.w r3, r7, r6
        str r1, [r0, #0x68]
        eors.w r1, r3, r12
        str.w r1, [r0, #0x84]
        bic.w r1, r5, r7
        ldr r3, [sp, #0x8c]
        eors r1, r6
        str.w r1, [r0, #0x8c]
        bic.w r6, r6, r12
        rors.w r4, r4, #0x13
        eors.w r3, r3, lr
        eors r6, r4
        ldr r1, [sp, #0x94]
        str r6, [r0, #0x7c]
        rors.w r3, r3, #0xc
        bic.w r6, r12, r4
        bic.w r12, r4, r5
        eors.w r1, r1, r8
        eors.w r4, r12, r7
        ror.w r1, r1, #0xb
        ldr r7, [sp, #0x28]
        str.w r4, [r0, #0x94]
        ldr.w r12, [sp, #0xc0]
        ldr r4, [sp, #0x5c]
        eors r7, r2
        eors r5, r6
        eors.w r12, r12, r10
        eors.w r4, r4, r9
        rors.w r7, r7, #0x1
        rors.w r4, r4, #0x4
        ror.w r12, r12, #0x1f
        bic.w r10, r1, r3
        str.w r5, [r0, #0x9c]
        eors.w r5, r10, r4
        str.w r5, [r0, #0xa8]
        bic.w r6, r3, r4
        ldr.w r10, [sp, #0x78]
        eors.w r9, r6, r7
        bic.w r6, r12, r1
        str.w r9, [r0, #0xa0]
        eor.w r10, r10, r2
        eors r6, r3
        ldr r5, [sp, #0xa8]
        bic.w r9, r7, r12
        ldr r3, [sp, #0x8]
        str.w r6, [r0, #0xb0]
        eor.w r5, r5, r3
        eors.w r1, r9, r1
        ror.w r5, r5, #0x16
        str.w r1, [r0, #0xb8]
        ldr r2, [sp, #0x4c]
        bic.w r1, r4, r7
        ldr r6, [sp, #0x1c]
        ror.w r10, r10, #0xb
        eor.w r2, r2, r11
        ldr r3, [sp, #0xdc]
        ror.w r2, r2, #0xa
        eor.w r6, r6, r8
        eors.w r8, r1, r12
        eor.w r3, r3, lr
        str.w r8, [r0, #0xc0]
        ror.w r3, r3, #0x19
        bic.w r11, r5, r10
        bic.w lr, r3, r5
        eors.w r12, r11, r2
        str.w r12, [r0, #0xc]
        eors.w r9, lr, r10
        bic.w r12, r6, r3
        bics.w r8, r10, r2
        eors.w r10, r12, r5
        str.w r10, [r0, #0x1c]
        bic.w r12, r2, r6
        ldr r2, [sp, #0x14]
        str.w r9, [r0, #0x14]
        eors.w r5, r12, r3
        str r5, [r0, #0x24]
        ldr.w r10, [r2, #0xc]
        eors.w r3, r6, r8
        ldr lr, [r2, #16]!
        eors.w r8, r3, r10
        str r2, [sp, #0x14]
        cmp.w lr, #0xff
        str.w r8, [r0, #0x4]

Lkeccak_f1600_x1_armv7m_slothy_end_round1:
        bne.w Lkeccak_f1600_x1_armv7m_slothy_start_round0 @ imm = #-0xaba
        add sp, #0xe0
        .cfi_adjust_cfa_offset -0xe0
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
