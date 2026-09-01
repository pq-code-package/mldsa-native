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
 * This file is adapted from the CC0-1.0 sources
 * keccakp1600_fast_cortexm3-4.S and keccakp1600_cortexm7.S at commit
 * b18cd6e792efd911fe9c24fd0d5fe65a534fc620 of:
 * https://github.com/aadomn/keccak_armv7m
 */

/*yaml
  Name: keccak_f1600_x1_armv7m_asm
  Description: Scalar x1 Keccak-f[1600] permutation using the bit-interleaved Armv7-M representation
  Signature: void mld_keccak_f1600_x1_armv7m_asm(uint32_t state[50], const uint32_t rc[49])
  ABI:
    Architecture: armv81m
    CallingConvention: AAPCS32
    Features: []
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
      test_bytes:
        192: 0xff
        193: 0x00
        194: 0x00
        195: 0x00
  Stack:
    bytes: 64
    description: register preservation (40) + scalar scratch/intermediate state (24); no MVE/Q-register scratch
*/

/*
 * AAPCS32 contract: preserves r4-r11 and sp; d8-d15 are not accessed.
 * The caller-saved r0-r3, r12, and APSR condition flags may be clobbered.
 * The 200-byte state buffer is modified; the round-constant buffer is read-only.
 */

/*
 * This file is derived from the CC0-1.0 implementation @[XKCP].
 * Optimizations for Armv7-M are described in @[ADOMNICAI23].
 * Further optimizations using SLOTHY are described in @[SLOTHYM7].
 */
/* WARNING: This implementation requires a little-endian Armv7-M or Armv8-M Mainline CPU. */

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
        sub sp, #0x18
        .cfi_adjust_cfa_offset 0x18
        str r1, [sp, #0x14]

Lmld_keccak_f1600_x1_armv7m_asm_slothy_start:
        ldr.w r11, [r0, #0x4c]
        ldr.w r8, [r0, #0x30]
        ldr.w lr, [r0, #0x24]
        ldr r3, [r0, #0x8]
        ldr.w r10, [r0, #0x74]
        ldr r5, [r0, #0x58]
        eor.w r11, lr, r11
        ldr.w r12, [r0, #0x34]
        eor.w r9, r3, r8
        ldr r6, [r0, #0xc]
        eor.w r4, r11, r10
        ldr r2, [r0, #0x44]
        eor.w r7, r9, r5
        ldr.w lr, [r0, #0x1c]
        eor.w r3, r6, r12
        ldr.w r6, [r0, #0x9c]
        eor.w r2, lr, r2
        ldr.w r10, [r0, #0x48]
        ldr.w r12, [r0, #0x20]
        ldr r5, [r0, #0x5c]
        eor.w r1, r4, r6
        ldr.w r6, [r0, #0x80]
        eor.w r10, r12, r10
        ldr.w r11, [r0, #0x3c]
        eor.w r9, r3, r5
        ldr r3, [r0, #0x14]
        eor.w r5, r7, r6
        ldr r7, [r0, #0x6c]
        eor.w r11, r3, r11
        ldr.w r12, [r0, #0x28]
        ldr.w lr, [r0]
        ldr r3, [r0, #0x64]
        eor.w r7, r2, r7
        ldr.w r8, [r0, #0x40]
        eor.w r12, lr, r12
        ldr r2, [r0, #0x18]
        eor.w lr, r11, r3
        ldr.w r6, [r0, #0xc4]
        eor.w r11, r2, r8
        ldr r3, [r0, #0x70]
        ldr.w r2, [r0, #0x84]
        ldr.w r8, [r0, #0xa8]
        eor.w r4, r1, r6
        ldr r6, [r0, #0x68]
        eor.w r1, r10, r3
        ldr r3, [r0, #0x50]
        eor.w r2, r9, r2
        ldr.w r10, [r0, #0x8c]
        eor.w r5, r5, r8
        ldr.w r9, [r0, #0x94]
        eor.w r11, r11, r6
        ldr.w r6, [r0, #0x98]
        eor.w r3, r12, r3
        eor.w r8, r4, r5
        eor.w lr, lr, r10
        ldr.w r10, [r0, #0x90]
        eor.w r9, r7, r9
        ldr.w r7, [r0, #0xac]
        eor.w r1, r1, r6
        ldr r6, [r0, #0x78]
        eor.w r10, r11, r10
        ldr.w r11, [r0, #0xb4]
        eor.w r12, r2, r7
        ldr.w r7, [r0, #0xc0]
        eor.w r2, r3, r6
        ldr.w r6, [r0, #0xbc]
        eor.w r11, lr, r11
        ldr.w r3, [r0, #0xb8]
        eor.w r1, r1, r7
        ldr.w lr, [r0, #0xa0]
        eor.w r6, r9, r6
        ldr r7, [r0, #0x38]
        eor.w r3, r10, r3
        eor.w r9, r1, r11
        eor.w r10, r2, lr
        ldr.w lr, [r0, #0x10]
        str.w r9, [sp, #0xc]
        ldr.w r9, [r0, #0x2c]
        eor.w r2, lr, r7
        ldr r7, [r0, #0x4]
        eor.w lr, r1, r12, ror #31
        ldr r1, [r0, #0x54]
        eor.w r7, r7, r9
        ldr.w r9, [r0, #0x60]
        str.w lr, [sp]
        ldr.w lr, [r0, #0x7c]
        eor.w r1, r7, r1
        ldr.w r7, [r0, #0x88]
        eor.w r9, r2, r9
        ldr.w r2, [r0, #0xa4]
        eor.w lr, r1, lr
        ldr.w r1, [r0, #0xb0]
        eor.w r9, r9, r7
        eor.w r7, lr, r2
        eor.w r2, r12, r3
        eor.w r1, r9, r1
        ldr.w r9, [r0, #0x84]
        eor.w lr, r6, r10
        eor.w r10, r10, r11, ror #31
        eor.w r11, r7, r1
        eor.w r12, r3, r7, ror #31
        eor.w r3, r11, r9
        ldr.w r9, [r0, #0xb4]
        eor.w r7, r2, r9
        eor.w r9, r1, r4, ror #31
        bic.w r1, r7, r3, ror #8
        str.w r8, [sp, #0x4]
        eor.w r4, r5, r6, ror #31
        ldr r6, [r0, #0x18]
        eor.w r5, r9, r6
        ldr r6, [r0, #0x48]
        str r4, [sp, #0x10]
        eor.w r6, r12, r6
        bic.w r4, r6, r5, ror #28
        str.w r9, [sp, #0x8]
        eor.w r4, r4, r7, ror #11
        str r4, [r0, #0x48]
        bic.w r4, r5, r7, ror #15
        ldr r7, [r0, #0x54]
        eor.w r7, r8, r7
        eor.w r4, r4, r3, ror #23
        str r4, [r0, #0x18]
        ldr r4, [r0, #0x68]
        eor.w r1, r1, r7, ror #29
        str.w r1, [r0, #0xb4]
        bic.w r3, r3, r7, ror #21
        ldr.w r1, [r0, #0x9c]
        eor.w r3, r3, r6, ror #13
        str.w r3, [r0, #0x84]
        eor.w r3, r9, r4
        eor.w r1, lr, r1
        bic.w r4, r7, r6, ror #24
        ldr.w r6, [r0, #0xa4]
        eor.w r7, r4, r5, ror #20
        eor.w r4, r8, r6
        bic.w r5, r1, r3, ror #24
        ldr.w r8, [r0, #0x8]
        eor.w r6, r10, r8
        bic.w r8, r4, r1, ror #5
        str r7, [r0, #0x54]
        bic.w r7, r6, r4, ror #23
        eor.w r1, r7, r1, ror #28
        str r1, [r0, #0x68]
        eor.w r7, r8, r3, ror #29
        ldr.w r8, [r0, #0x3c]
        str r7, [r0, #0x3c]
        eor.w r1, r2, r8
        ldr.w r8, [sp]
        bic.w r7, r1, r6, ror #3
        eor.w r5, r5, r1, ror #1
        str r5, [r0, #0x8]
        bic.w r3, r3, r1, ror #9
        ldr r1, [r0, #0x58]
        eor.w r5, r3, r6, ror #12
        ldr r6, [r0, #0x28]
        str.w r5, [r0, #0xa4]
        eor.w r5, r7, r4, ror #26
        eor.w r7, r8, r6
        ldr r3, [r0, #0x24]
        eor.w r1, r10, r1
        ldr.w r4, [r0, #0x8c]
        eor.w r6, lr, r3
        str.w r5, [r0, #0x9c]
        eor.w r5, r2, r4
        bic.w r4, r1, r7, ror #19
        ldr.w r3, [r0, #0xb8]
        eor.w r4, r4, r6, ror #23
        str r4, [r0, #0x28]
        bic.w r4, r5, r1, ror #3
        eor.w r3, r9, r3
        eor.w r4, r4, r7, ror #22
        str r4, [r0, #0x58]
        bic.w r4, r3, r5, ror #20
        eor.w r1, r4, r1, ror #23
        str.w r1, [r0, #0x8c]
        bic.w r4, r6, r3, ror #18
        ldr r1, [r0, #0x70]
        eor.w r5, r4, r5, ror #6
        str.w r5, [r0, #0xb8]
        bic.w r5, r7, r6, ror #4
        ldr.w r6, [r0, #0xac]
        eor.w r4, r5, r3, ror #22
        ldr r7, [r0, #0x40]
        eor.w r3, r9, r7
        ldr r5, [r0, #0x14]
        eor.w r7, r2, r5
        eor.w r1, r12, r1
        str r4, [r0, #0x24]
        bic.w r4, r1, r3, ror #24
        eor.w r9, r4, r7, ror #20
        eor.w r5, r11, r6
        ldr r4, [r0, #0x78]
        bic.w r6, r3, r7, ror #28
        eor.w r4, r8, r4
        bic.w r7, r7, r5, ror #30
        str.w r9, [r0, #0x78]
        bic.w r9, r4, r1, ror #1
        eor.w r9, r9, r3, ror #25
        str.w r9, [r0, #0xac]
        ldr.w r9, [r0, #0x64]
        bic.w r3, r5, r4, ror #13
        eor.w r3, r3, r1, ror #14
        str r3, [r0, #0x14]
        eor.w r1, r2, r9
        ldr.w r9, [sp, #0xc]
        eor.w r4, r7, r4, ror #11
        ldr.w r2, [r0, #0x94]
        str r4, [r0, #0x40]
        eor.w r3, r9, r2
        eor.w r7, r6, r5, ror #26
        ldr.w r4, [r0, #0xc0]
        eor.w r5, r12, r4
        ldr r4, [r0, #0x30]
        eor.w r2, r10, r4
        bic.w r6, r3, r1, ror #21
        str r7, [r0, #0x70]
        bic.w r7, r5, r3, ror #28
        eor.w r4, r6, r2, ror #21
        str r4, [r0, #0x30]
        eor.w r7, r7, r1, ror #17
        ldr r6, [r0]
        eor.w r4, r8, r6
        bic.w r1, r1, r2
        str r7, [r0, #0x64]
        bic.w r7, r4, r5, ror #25
        ldr.w r6, [r0, #0x80]
        eor.w r1, r4, r1, ror #10
        eor.w r6, r10, r6
        bic.w r4, r2, r4, ror #22
        ldr r2, [sp, #0x10]
        eor.w r5, r4, r5, ror #15
        ldr r4, [sp, #0x14]
        str.w r5, [r0, #0xc0]
        eor.w r5, r7, r3, ror #21
        ldr r3, [r0, #0x50]
        ldr r7, [r0, #0x4c]
        ldr r4, [r4]
        eor.w r3, r8, r3
        eor.w r4, r4, r1
        str.w r5, [r0, #0x94]
        eor.w r1, lr, r7
        ldr r7, [r0, #0x1c]
        str r4, [r0]
        bic.w r4, r6, r3, ror #21
        eor.w r4, r4, r1, ror #12
        eor.w r7, r9, r7
        str.w r4, [r0, #0x80]
        bic.w r5, r3, r1, ror #23
        ldr.w r4, [r0, #0xb0]
        eor.w r5, r5, r7, ror #19
        str r5, [r0, #0x50]
        eor.w r5, r2, r4
        bic.w r4, r5, r6, ror #8
        eor.w r3, r4, r3, ror #29
        str.w r3, [r0, #0xb0]
        bic.w r3, r7, r5, ror #16
        ldr r4, [r0, #0x6c]
        eor.w r4, r9, r4
        eor.w r6, r3, r6, ror #24
        ldr.w r3, [r0, #0x98]
        str r6, [r0, #0x1c]
        eor.w r3, r12, r3
        bic.w r1, r1, r7, ror #28
        ldr r6, [r0, #0xc]
        ldr r7, [r0, #0x38]
        eor.w r7, r2, r7
        eor.w r6, r11, r6
        eor.w r1, r1, r5, ror #12
        str r1, [r0, #0x4c]
        bic.w r5, r4, r7, ror #10
        ldr.w r1, [r0, #0xa0]
        eor.w r5, r5, r6, ror #12
        str.w r5, [r0, #0xa0]
        bic.w r5, r3, r4, ror #23
        eor.w r1, r8, r1
        eor.w r5, r5, r7, ror #1
        str r5, [r0, #0xc]
        ldr.w r8, [sp, #0x4]
        bic.w r5, r1, r3, ror #5
        eor.w r4, r5, r4, ror #28
        str r4, [r0, #0x38]
        ldr r5, [r0, #0x5c]
        bic.w r4, r6, r1, ror #24
        eor.w r4, r4, r3, ror #29
        str r4, [r0, #0x6c]
        ldr.w r4, [r0, #0x88]
        eor.w r3, r11, r5
        bic.w r6, r7, r6, ror #2
        eor.w r4, r2, r4
        ldr r7, [r0, #0x2c]
        ldr r5, [r0, #0x20]
        eor.w r12, r12, r5
        eor.w r7, r8, r7
        eor.w r6, r6, r1, ror #26
        str.w r6, [r0, #0x98]
        ldr.w r1, [r0, #0xbc]
        bic.w r5, r3, r7, ror #19
        eor.w r6, r9, r1
        eor.w r5, r5, r12, ror #24
        ldr r1, [r0, #0x44]
        str r5, [r0, #0x2c]
        eor.w r9, r9, r1
        bic.w r1, r4, r3, ror #2
        ldr r5, [r0, #0x74]
        eor.w r1, r1, r7, ror #21
        str r1, [r0, #0x5c]
        bic.w r1, r6, r4, ror #21
        eor.w r5, lr, r5
        eor.w r3, r1, r3, ror #23
        str.w r3, [r0, #0x88]
        bic.w r3, r12, r6, ror #17
        ldr r1, [r0, #0x7c]
        eor.w r4, r3, r4, ror #6
        eor.w r1, r8, r1
        str.w r4, [r0, #0xbc]
        bic.w r7, r7, r12, ror #5
        ldr r3, [r0, #0x10]
        eor.w r6, r7, r6, ror #22
        eor.w r4, r2, r3
        ldr.w r12, [sp, #0x8]
        ldr.w r7, [r0, #0xa8]
        str r6, [r0, #0x20]
        eor.w r3, r10, r7
        bic.w r10, r5, r9, ror #24
        eor.w r7, r10, r4, ror #21
        str r7, [r0, #0x7c]
        bic.w r6, r1, r5, ror #1
        ldr r7, [r0, #0x60]
        eor.w r6, r6, r9, ror #25
        str.w r6, [r0, #0xa8]
        bic.w r6, r3, r1, ror #12
        eor.w r2, r2, r7
        eor.w r5, r6, r5, ror #13
        str r5, [r0, #0x10]
        bic.w r5, r4, r3, ror #30
        ldr.w r6, [r0, #0x90]
        eor.w r10, r5, r1, ror #10
        eor.w r5, r12, r6
        str.w r10, [r0, #0x44]
        bic.w r9, r9, r4, ror #29
        ldr r7, [r0, #0x4]
        eor.w r1, r9, r3, ror #27
        ldr r6, [r0, #0x34]
        eor.w r3, r8, r7
        eor.w r6, r11, r6
        ldr.w r12, [r0, #0xc4]
        eor.w r8, lr, r12
        str r1, [r0, #0x74]
        bic.w r4, r5, r2, ror #21
        ldr.w r12, [sp, #0x14]
        eor.w r11, r4, r6, ror #20
        str.w r11, [r0, #0x34]
        bic.w lr, r8, r5, ror #29
        ldr.w r11, [r12, #0x4]
        eor.w lr, lr, r2, ror #18
        str.w lr, [r0, #0x60]
        bic.w lr, r2, r6, ror #31
        ldr.w r9, [r0, #0x48]
        bic.w r7, r3, r8, ror #25
        ldr.w r4, [r0, #0xc0]
        eor.w r5, r7, r5, ror #22
        str.w r5, [r0, #0x90]
        bic.w r12, r6, r3, ror #22
        ldr.w r7, [r0, #0x98]
        eor.w r10, r12, r8, ror #15
        str.w r10, [r0, #0xc4]
        eor.w r8, r3, lr, ror #11
        ldr.w lr, [r0, #0x24]
        ldr.w r10, [r0, #0x74]
        ldr r5, [r0, #0x60]
        eor.w r9, r4, r9, ror #12
        ldr.w r4, [r0, #0x80]
        ldr r1, [r0, #0x34]
        ldr.w r12, [r0, #0xb0]
        eor.w r6, r11, r8
        eor.w r2, r9, r7, ror #19
        eor.w r11, r1, r4, ror #20
        ldr r3, [r0, #0x3c]
        eor.w r4, r5, r12, ror #9
        ldr r1, [r0, #0x5c]
        eor.w r5, r2, lr, ror #4
        ldr.w lr, [r0, #0x8]
        ldr.w r8, [r0, #0x88]
        eor.w r12, r4, r3, ror #30
        str r6, [r0, #0x4]
        ldr r2, [r0, #0x18]
        eor.w r7, r11, lr, ror #6
        ldr.w r9, [r0, #0xac]
        eor.w lr, r5, r10, ror #26
        ldr r3, [r0, #0x30]
        eor.w r11, r7, r1, ror #3
        ldr.w r7, [r0, #0x84]
        eor.w r4, r12, r8, ror #11
        ldr.w r12, [r0, #0x4c]
        eor.w r6, r11, r9, ror #22
        ldr.w r5, [r0, #0x94]
        ldr.w r8, [r0, #0x6c]
        eor.w r3, r3, r7, ror #20
        ldr.w r11, [r0, #0xc4]
        ror.w lr, lr, #0xa
        eor.w r9, lr, r6, ror #21
        str.w r9, [sp]
        eor.w r9, r11, r12, ror #12
        ldr.w r10, [r0, #0x14]
        ldr.w r7, [r0, #0xb4]
        eor.w r5, r5, r2, ror #18
        ldr.w r12, [r0, #0xb8]
        ldr.w r2, [r0, #0x9c]
        eor.w r1, r5, r8, ror #31
        ldr.w r8, [r0, #0xc]
        eor.w r10, r4, r10, ror #6
        ldr r5, [r0, #0x64]
        eor.w r11, r1, r12, ror #18
        ldr.w r12, [r0, #0x90]
        eor.w r4, r5, r7, ror #8
        ldr r1, [r0, #0x44]
        eor.w lr, lr, r10, ror #25
        ldr r5, [r0, #0x1c]
        eor.w r7, r3, r8, ror #7
        ldr.w r8, [r0, #0x50]
        eor.w r3, r11, r1, ror #1
        ldr.w r11, [r0, #0x4]
        eor.w r12, r12, r5, ror #18
        ldr r1, [r0, #0x54]
        eor.w r9, r9, r2, ror #19
        ldr r5, [r0, #0x68]
        eor.w r2, r3, r6, ror #22
        ldr r6, [r0]
        eor.w r11, r11, r8, ror #31
        ldr.w r8, [r0, #0x38]
        eor.w r1, r6, r1, ror #30
        ldr.w r6, [r0, #0xa4]
        eor.w r5, r12, r5
        ldr.w r12, [r0, #0xa0]
        eor.w r4, r4, r8, ror #30
        ldr.w r8, [r0, #0x58]
        eor.w r6, r11, r6, ror #20
        ldr.w r11, [r0, #0x28]
        eor.w r12, r1, r12, ror #19
        ldr r1, [r0, #0x20]
        eor.w r8, r7, r8, ror #3
        ldr r7, [r0, #0x7c]
        eor.w r12, r12, r11, ror #27
        ldr.w r11, [r0, #0x8c]
        eor.w r9, r9, r1, ror #4
        str.w lr, [sp, #0xc]
        eor.w lr, r12, r7, ror #12
        ldr r7, [r0, #0x70]
        eor.w r4, r4, r11, ror #11
        ldr.w r11, [r0, #0xbc]
        eor.w r10, lr, r10, ror #24
        ldr.w r1, [r0, #0xa8]
        eor.w r9, r9, r7, ror #27
        ldr.w r12, [r0, #0x40]
        eor.w r11, r5, r11, ror #19
        ldr r5, [r0, #0x2c]
        eor.w r7, r8, r1, ror #22
        ldr r1, [r0, #0x10]
        eor.w r12, r11, r12, ror #1
        ldr.w r8, [r0, #0x78]
        ror.w r7, r7, #0x15
        eor.w r11, r6, r5, ror #27
        eor.w lr, r12, lr
        eor.w r6, r7, r9, ror #10
        eor.w r11, r11, r8, ror #13
        ldr.w r8, [r0, #0xa4]
        eor.w r1, r4, r1, ror #6
        ldr r4, [r0, #0x5c]
        eor.w r7, r7, r12, ror #31
        ldr r5, [r0, #0x48]
        eor.w r12, r3, r11, ror #31
        ror.w r1, r1, #0x19
        str r7, [sp, #0x10]
        eor.w r8, r6, r8, ror #20
        eor.w r11, r11, r1
        eor.w r5, r12, r5, ror #22
        str r6, [sp, #0x4]
        eor.w r4, r11, r4, ror #25
        eor.w r1, r1, r9, ror #9
        ldr r7, [r0, #0x78]
        ldr.w r9, [r0, #0x14]
        bic.w r3, r4, r8, ror #21
        eor.w r3, r3, r5, ror #13
        str r3, [r0, #0x5c]
        eor.w r6, r6, r7, ror #13
        ldr.w r3, [r0, #0x94]
        eor.w r7, r1, r3
        eor.w r3, r2, r9, ror #31
        bic.w r9, r8, r5, ror #24
        bic.w r5, r5, r7, ror #28
        eor.w r9, r9, r7, ror #20
        str.w r9, [r0, #0xa4]
        ldr.w r9, [r0, #0x20]
        bic.w r7, r7, r3, ror #15
        eor.w r5, r5, r3, ror #11
        str r5, [r0, #0x48]
        bic.w r3, r3, r4, ror #8
        ldr r5, [r0, #0x30]
        eor.w r8, r3, r8, ror #29
        str.w r8, [r0, #0x14]
        eor.w r3, lr, r9, ror #14
        eor.w r9, r10, r5, ror #21
        ldr r5, [r0, #0x6c]
        eor.w r7, r7, r4, ror #23
        str.w r7, [r0, #0x94]
        bic.w r7, r9, r6, ror #23
        eor.w r4, r7, r3, ror #28
        ldr.w r7, [r0, #0xb0]
        eor.w r5, r1, r5, ror #31
        str r4, [r0, #0x6c]
        bic.w r4, r6, r3, ror #5
        str r1, [sp, #0x8]
        eor.w r7, r2, r7, ror #2
        bic.w r8, r3, r5, ror #24
        ldr r3, [r0, #0x54]
        eor.w r4, r4, r5, ror #29
        str.w r4, [r0, #0xb0]
        eor.w r8, r8, r7, ror #1
        str.w r8, [r0, #0x30]
        ldr.w r8, [r0, #0x18]
        bic.w r4, r7, r9, ror #3
        eor.w r4, r4, r6, ror #26
        ldr r6, [r0, #0x44]
        str r4, [r0, #0x20]
        bic.w r7, r5, r7, ror #9
        eor.w r5, r1, r8, ror #18
        ldr.w r8, [sp]
        eor.w r1, r1, r6, ror #1
        ldr.w r6, [r0, #0x88]
        eor.w r4, r8, r3, ror #30
        ldr.w r3, [r0, #0xc4]
        eor.w r9, r7, r9, ror #12
        ldr r7, [r0, #0xc]
        str.w r9, [r0, #0x78]
        eor.w r6, r2, r6, ror #4
        eor.w r3, lr, r3, ror #10
        eor.w r7, r10, r7, ror #28
        bic.w r9, r3, r1, ror #18
        eor.w r9, r9, r6, ror #6
        str.w r9, [r0, #0x44]
        bic.w r9, r4, r3, ror #4
        eor.w r9, r9, r1, ror #22
        bic.w r1, r1, r6, ror #20
        str.w r9, [r0, #0xc4]
        eor.w r9, r1, r7, ror #23
        str.w r9, [r0, #0x88]
        bic.w r1, r6, r7, ror #3
        ldr r6, [r0, #0x60]
        bic.w r9, r7, r4, ror #19
        eor.w r7, r1, r4, ror #22
        ldr r4, [r0, #0x3c]
        eor.w r9, r9, r3, ror #23
        ldr.w r1, [r0, #0x98]
        str r7, [r0, #0xc]
        eor.w r7, r2, r6, ror #25
        ldr.w r3, [r0, #0xac]
        eor.w r6, r2, r4, ror #23
        eor.w r2, r12, r1, ror #29
        str.w r9, [r0, #0x54]
        ldr.w r9, [r0, #0x28]
        bic.w r4, r5, r7, ror #28
        eor.w r1, r11, r3, ror #12
        bic.w r3, r2, r5, ror #24
        eor.w r3, r3, r7, ror #20
        str r3, [r0, #0x28]
        eor.w r9, r8, r9, ror #27
        ldr r3, [r0]
        eor.w r4, r4, r1, ror #26
        str.w r4, [r0, #0x98]
        ldr.w r4, [r0, #0x84]
        bic.w r7, r7, r1, ror #30
        eor.w r7, r7, r9, ror #11
        str r7, [r0, #0x18]
        eor.w r3, r8, r3
        bic.w r7, r1, r9, ror #13
        ldr r1, [r0, #0x74]
        eor.w r7, r7, r2, ror #14
        eor.w r4, r10, r4, ror #9
        str r7, [r0, #0x60]
        bic.w r7, r9, r2, ror #1
        ldr.w r9, [sp, #0xc]
        ldr.w r2, [r0, #0xbc]
        eor.w r7, r7, r5, ror #25
        bic.w r5, r6, r4
        str.w r7, [r0, #0xac]
        eor.w r7, r12, r1, ror #4
        ldr r1, [sp, #0x14]
        eor.w r5, r3, r5, ror #10
        ldr r1, [r1, #0x8]
        eor.w r2, r9, r2, ror #19
        eor.w r5, r1, r5
        bic.w r1, r4, r3, ror #22
        str r5, [r0]
        bic.w r3, r3, r7, ror #25
        eor.w r1, r1, r7, ror #15
        str r1, [r0, #0x74]
        bic.w r7, r7, r2, ror #28
        ldr r5, [r0, #0x58]
        ldr r1, [r0, #0x4c]
        eor.w r7, r7, r6, ror #17
        eor.w r3, r3, r2, ror #21
        str.w r3, [r0, #0xbc]
        str r7, [r0, #0x3c]
        eor.w r7, r10, r5, ror #24
        eor.w r5, lr, r1, ror #22
        ldr.w r3, [r0, #0xa0]
        bic.w r6, r2, r6, ror #21
        ldr r1, [r0, #0x7c]
        eor.w r4, r6, r4, ror #21
        str.w r4, [r0, #0x84]
        eor.w r4, r8, r3, ror #19
        ldr.w r3, [r0, #0x90]
        eor.w r1, r8, r1, ror #12
        eor.w r6, r9, r3
        bic.w r3, r4, r5, ror #23
        ldr.w r8, [r0, #0x10]
        eor.w r3, r3, r6, ror #19
        ldr r2, [sp, #0x10]
        str.w r3, [r0, #0xa0]
        bic.w r3, r7, r4, ror #21
        eor.w r8, r2, r8, ror #31
        eor.w r3, r3, r5, ror #12
        str r3, [r0, #0x58]
        bic.w r5, r5, r6, ror #28
        eor.w r5, r5, r8, ror #12
        str r5, [r0, #0x4c]
        bic.w r5, r6, r8, ror #16
        ldr.w r3, [r0, #0xa8]
        ldr r6, [r0, #0x34]
        eor.w r5, r5, r7, ror #24
        bic.w r7, r8, r7, ror #8
        ldr.w r8, [r0, #0xb4]
        eor.w r7, r7, r4, ror #29
        ldr r4, [r0, #0x24]
        str r7, [r0, #0x10]
        eor.w r7, r10, r3, ror #11
        eor.w r10, r11, r6, ror #22
        eor.w r8, r2, r8, ror #1
        str.w r5, [r0, #0x90]
        eor.w r6, r12, r4, ror #14
        ldr.w r4, [r0, #0xc0]
        bic.w r3, r8, r10, ror #2
        eor.w r3, r3, r1, ror #26
        str r3, [r0, #0x24]
        bic.w r5, r10, r1, ror #24
        ldr r3, [r0, #0x68]
        eor.w r5, r5, r6, ror #29
        eor.w r3, r9, r3
        str r5, [r0, #0x68]
        eor.w r12, r12, r4, ror #10
        ldr.w r5, [r0, #0x9c]
        bic.w r4, r6, r3, ror #23
        eor.w r4, r4, r8, ror #1
        bic.w r6, r1, r6, ror #5
        ldr r1, [r0, #0x1c]
        str r4, [r0, #0x34]
        eor.w r5, lr, r5, ror #29
        bic.w r4, r3, r8, ror #10
        ldr.w r8, [r0, #0x8]
        eor.w r3, r6, r3, ror #28
        ldr.w r6, [r0, #0x8c]
        eor.w r4, r4, r10, ror #12
        ldr.w r10, [r0, #0x40]
        str r4, [r0, #0x7c]
        eor.w r4, r9, r1, ror #18
        str.w r3, [r0, #0xb4]
        eor.w r6, r2, r6, ror #4
        eor.w r1, r9, r10, ror #1
        ldr.w r9, [r0, #0x50]
        eor.w r3, r11, r8, ror #28
        ldr.w r8, [sp, #0x4]
        bic.w r10, r1, r6, ror #21
        eor.w r9, r8, r9, ror #31
        eor.w r10, r10, r3, ror #23
        str.w r10, [r0, #0x8c]
        bic.w r10, r6, r3, ror #2
        eor.w r10, r10, r9, ror #21
        str.w r10, [r0, #0x8]
        bic.w r10, r12, r1, ror #17
        eor.w r10, r10, r6, ror #6
        str.w r10, [r0, #0x40]
        ldr.w r10, [r0, #0x64]
        bic.w r3, r3, r9, ror #19
        eor.w r6, r3, r12, ror #24
        str r6, [r0, #0x50]
        bic.w r3, r9, r12, ror #5
        ldr r6, [r0, #0x2c]
        eor.w r1, r3, r1, ror #22
        str.w r1, [r0, #0xc0]
        eor.w r12, r2, r10, ror #25
        ldr.w r10, [r0, #0x38]
        bic.w r1, r5, r4, ror #24
        ldr.w r9, [sp, #0x8]
        ldr.w r3, [r0, #0x80]
        eor.w r6, r8, r6, ror #27
        eor.w r1, r1, r12, ror #21
        str r1, [r0, #0x2c]
        eor.w r10, r2, r10, ror #23
        ldr r1, [r0, #0x4]
        eor.w r8, r8, r1
        bic.w r1, r6, r5, ror #1
        ldr.w r2, [r0, #0xb8]
        eor.w r1, r1, r4, ror #25
        str.w r1, [r0, #0xa8]
        bic.w r1, r7, r6, ror #12
        eor.w r5, r1, r5, ror #13
        str r5, [r0, #0x64]
        eor.w r9, r9, r2, ror #18
        ldr r2, [r0, #0x70]
        ldr r5, [sp, #0x14]
        bic.w r1, r12, r7, ror #30
        eor.w r1, r1, r6, ror #10
        str r1, [r0, #0x1c]
        bic.w r6, r4, r12, ror #29
        ldr r1, [r5, #0xc]
        eor.w r5, r11, r3, ror #10
        ldr r4, [r0, #0x48]
        eor.w r3, r6, r7, ror #27
        str.w r3, [r0, #0x9c]
        eor.w r6, lr, r2, ror #5
        ldr r3, [r0, #0x74]
        ldr r2, [r0, #0x24]
        bic.w lr, r9, r10, ror #21
        eor.w r7, lr, r5, ror #20
        str.w r7, [r0, #0x80]
        bic.w r11, r6, r9, ror #29
        ldr.w r7, [r0, #0xc4]
        eor.w r11, r11, r10, ror #18
        str.w r11, [r0, #0x38]
        ldr.w lr, [r0, #0x9c]
        bic.w r11, r8, r6, ror #25
        eor.w r9, r11, r9, ror #22
        str.w r9, [r0, #0xb8]
        bic.w r12, r10, r5, ror #31
        ldr.w r10, [r0, #0x80]
        bic.w r5, r5, r8, ror #22
        ldr.w r9, [r0, #0x38]
        eor.w r3, r3, r4, ror #12
        ldr.w r11, [r0, #0x58]
        eor.w r6, r5, r6, ror #15
        str r6, [r0, #0x70]
        ldr r4, [r0, #0x10]
        eor.w r6, r3, r2, ror #19
        ldr.w r2, [r0, #0x94]
        eor.w r3, r10, r11, ror #20
        eor.w r11, r6, r7, ror #4
        ldr.w r7, [r0, #0x8c]
        ldr.w r10, [r0, #0xb0]
        eor.w r6, r9, r4, ror #9
        eor.w r5, r11, lr, ror #26
        ldr r4, [r0, #0x30]
        ldr.w r11, [r0, #0x8]
        eor.w lr, r8, r12, ror #11
        eor.w r9, r6, r10, ror #30
        ldr r6, [r0, #0x5c]
        eor.w r3, r3, r4, ror #6
        ldr.w r12, [r0, #0x84]
        eor.w r8, r1, lr
        str.w r8, [r0, #0x4]
        ldr r1, [r0, #0x34]
        ldr.w lr, [r0, #0xc]
        eor.w r4, r12, r6, ror #20
        ldr r6, [r0, #0x60]
        eor.w r10, r9, r7, ror #11
        eor.w r12, r4, r1, ror #7
        ldr.w r7, [r0, #0xa8]
        ldr.w r4, [r0, #0xbc]
        ror.w r5, r5, #0xa
        eor.w r1, r12, lr, ror #3
        ldr.w lr, [r0, #0x90]
        eor.w r2, r4, r2, ror #18
        ldr.w r8, [r0, #0xb8]
        eor.w r7, r1, r7, ror #22
        ldr r4, [r0, #0x68]
        eor.w r11, r3, r11, ror #3
        ldr.w r12, [r0, #0xac]
        ror.w r7, r7, #0x15
        eor.w r3, r10, r6, ror #6
        eor.w r9, r2, r4, ror #31
        ldr r6, [r0, #0x4c]
        eor.w r12, r11, r12, ror #22
        ldr.w r10, [r0, #0x70]
        eor.w r4, r5, r3, ror #25
        ldr.w r1, [r0, #0xa0]
        eor.w lr, r8, lr, ror #18
        ldr.w r8, [r0, #0x4]
        eor.w r2, r5, r12, ror #21
        ldr r5, [r0, #0x14]
        eor.w r6, r10, r6, ror #12
        ldr.w r10, [r0, #0x3c]
        eor.w r1, r8, r1, ror #31
        ldr.w r8, [r0, #0x20]
        eor.w r11, r10, r5, ror #8
        ldr r5, [r0, #0x6c]
        str r4, [sp, #0xc]
        ldr.w r4, [r0, #0xc0]
        eor.w r8, r6, r8, ror #19
        ldr r6, [r0, #0x40]
        eor.w r10, lr, r5
        ldr.w lr, [r0, #0x98]
        eor.w r8, r8, r4, ror #4
        ldr r4, [r0, #0x18]
        eor.w r10, r10, r6, ror #19
        ldr.w r6, [r0, #0xa4]
        eor.w r5, r8, lr, ror #27
        ldr.w lr, [r0]
        str r2, [sp]
        eor.w r4, r10, r4, ror #1
        eor.w r6, lr, r6, ror #30
        ldr.w lr, [r0, #0x7c]
        ldr r2, [r0, #0x44]
        eor.w r8, r7, r5, ror #10
        eor.w r7, r7, r4, ror #31
        ldr.w r10, [r0, #0x54]
        eor.w lr, r6, lr, ror #19
        ldr r6, [r0, #0x1c]
        eor.w r9, r9, r2, ror #18
        ldr r2, [r0, #0x2c]
        str r7, [sp, #0x10]
        eor.w r10, lr, r10, ror #27
        eor.w r9, r9, r6, ror #1
        ldr r7, [r0, #0x78]
        eor.w lr, r10, r2, ror #12
        ldr.w r6, [r0, #0xb4]
        eor.w r2, r9, r12, ror #22
        ldr.w r12, [r0, #0x50]
        eor.w r10, lr, r3, ror #24
        eor.w lr, r4, lr
        eor.w r4, r1, r7, ror #20
        ldr.w r1, [r0, #0x88]
        eor.w r11, r11, r6, ror #30
        ldr r6, [r0, #0x28]
        eor.w r3, r4, r12, ror #27
        ldr.w r12, [r0, #0x64]
        eor.w r1, r11, r1, ror #11
        ldr r7, [r0, #0x60]
        eor.w r11, r3, r6, ror #13
        ldr r4, [r0, #0x8]
        ldr r6, [r0, #0x28]
        eor.w r1, r1, r12, ror #6
        ldr r3, [r0, #0x78]
        eor.w r7, r2, r7, ror #31
        ror.w r1, r1, #0x19
        eor.w r12, r9, r11, ror #31
        eor.w r11, r11, r1
        eor.w r9, r8, r6, ror #13
        eor.w r5, r1, r5, ror #9
        ldr r1, [r0, #0x48]
        eor.w r6, r11, r4, ror #25
        str.w r8, [sp, #0x4]
        eor.w r4, r8, r3, ror #20
        ldr.w r3, [r0, #0xbc]
        eor.w r1, r12, r1, ror #22
        eor.w r3, r5, r3
        bic.w r8, r7, r6, ror #8
        eor.w r8, r8, r4, ror #29
        str.w r8, [r0, #0x60]
        bic.w r8, r4, r1, ror #24
        bic.w r4, r6, r4, ror #21
        eor.w r8, r8, r3, ror #20
        str.w r8, [r0, #0x78]
        eor.w r4, r4, r1, ror #13
        str r4, [r0, #0x8]
        bic.w r8, r1, r3, ror #28
        ldr r4, [r0, #0x68]
        ldr.w r1, [r0, #0x84]
        bic.w r3, r3, r7, ror #15
        eor.w r8, r8, r7, ror #11
        str.w r8, [r0, #0x48]
        eor.w r4, r5, r4, ror #31
        ldr r7, [r0, #0x10]
        ldr.w r8, [r0, #0xc0]
        eor.w r6, r3, r6, ror #23
        eor.w r3, r10, r1, ror #21
        str r5, [sp, #0x8]
        eor.w r1, r2, r7, ror #2
        eor.w r8, lr, r8, ror #14
        str.w r6, [r0, #0xbc]
        bic.w r6, r3, r9, ror #23
        bic.w r7, r4, r1, ror #9
        eor.w r6, r6, r8, ror #28
        str r6, [r0, #0x68]
        eor.w r6, r7, r3, ror #12
        str r6, [r0, #0x28]
        ldr.w r6, [r0, #0xa4]
        bic.w r7, r1, r3, ror #3
        eor.w r7, r7, r9, ror #26
        str.w r7, [r0, #0xc0]
        bic.w r3, r9, r8, ror #5
        ldr.w r9, [r0, #0x34]
        eor.w r3, r3, r4, ror #29
        str r3, [r0, #0x10]
        bic.w r4, r8, r4, ror #24
        ldr.w r8, [sp]
        ldr r3, [r0, #0x70]
        eor.w r7, r4, r1, ror #1
        ldr r4, [r0, #0x1c]
        eor.w r6, r8, r6, ror #30
        eor.w r1, r10, r9, ror #28
        ldr.w r9, [r0, #0x94]
        eor.w r3, lr, r3, ror #10
        str.w r7, [r0, #0x84]
        eor.w r7, r5, r4, ror #1
        eor.w r9, r5, r9, ror #18
        ldr.w r5, [r0, #0x8c]
        bic.w r4, r1, r6, ror #19
        eor.w r4, r4, r3, ror #23
        str.w r4, [r0, #0xa4]
        eor.w r4, r2, r5, ror #4
        bic.w r5, r6, r3, ror #4
        eor.w r5, r5, r7, ror #22
        str r5, [r0, #0x70]
        bic.w r5, r4, r1, ror #3
        eor.w r5, r5, r6, ror #22
        str r5, [r0, #0x34]
        bic.w r6, r3, r7, ror #18
        ldr r3, [r0, #0x54]
        bic.w r7, r7, r4, ror #20
        ldr r5, [r0, #0x24]
        eor.w r1, r7, r1, ror #23
        str.w r1, [r0, #0x8c]
        eor.w r1, r8, r3, ror #27
        ldr r3, [r0, #0x38]
        eor.w r4, r6, r4, ror #6
        str r4, [r0, #0x1c]
        eor.w r4, r12, r5, ror #29
        ldr.w r5, [r0, #0xac]
        eor.w r7, r2, r3, ror #25
        bic.w r3, r4, r9, ror #24
        eor.w r5, r11, r5, ror #12
        eor.w r3, r3, r7, ror #20
        str r3, [r0, #0x54]
        bic.w r3, r1, r4, ror #1
        eor.w r3, r3, r9, ror #25
        str.w r3, [r0, #0xac]
        bic.w r9, r9, r7, ror #28
        ldr r3, [r0, #0x40]
        ldr r6, [r0, #0x5c]
        eor.w r9, r9, r5, ror #26
        str.w r9, [r0, #0x24]
        bic.w r7, r7, r5, ror #30
        bic.w r9, r5, r1, ror #13
        ldr.w r5, [r0, #0xb0]
        eor.w r4, r9, r4, ror #14
        ldr.w r9, [sp, #0xc]
        str r4, [r0, #0x38]
        eor.w r4, r7, r1, ror #11
        ldr.w r1, [r0, #0x9c]
        eor.w r7, r9, r3, ror #19
        str.w r4, [r0, #0x94]
        eor.w r2, r2, r5, ror #23
        eor.w r5, r10, r6, ror #9
        ldr r4, [r0]
        eor.w r1, r12, r1, ror #4
        bic.w r6, r7, r2, ror #21
        ldr r3, [sp, #0x14]
        eor.w r6, r6, r5, ror #21
        str r6, [r0, #0x5c]
        bic.w r6, r1, r7, ror #28
        eor.w r4, r8, r4
        eor.w r6, r6, r2, ror #17
        str.w r6, [r0, #0xb0]
        bic.w r6, r2, r5
        ldr r2, [r3, #0x10]
        bic.w r3, r4, r1, ror #25
        eor.w r3, r3, r7, ror #21
        ldr r7, [r0, #0x7c]
        str r3, [r0, #0x40]
        bic.w r3, r5, r4, ror #22
        eor.w r4, r4, r6, ror #10
        ldr r5, [r0, #0xc]
        eor.w r6, r8, r7, ror #19
        ldr r7, [r0, #0x4c]
        eor.w r3, r3, r1, ror #15
        eor.w r4, r2, r4
        ldr r1, [r0, #0x64]
        eor.w r5, r10, r5, ror #24
        eor.w r7, lr, r7, ror #22
        ldr r2, [sp, #0x10]
        str r4, [r0]
        bic.w r4, r5, r6, ror #21
        str.w r3, [r0, #0x9c]
        eor.w r1, r2, r1, ror #31
        eor.w r4, r4, r7, ror #12
        str r4, [r0, #0xc]
        bic.w r4, r1, r5, ror #8
        ldr.w r3, [r0, #0xb8]
        eor.w r4, r4, r6, ror #29
        eor.w r3, r9, r3
        str r4, [r0, #0x64]
        bic.w r4, r6, r7, ror #23
        ldr r6, [r0, #0x2c]
        bic.w r7, r7, r3, ror #28
        eor.w r4, r4, r3, ror #19
        str r4, [r0, #0x7c]
        eor.w r7, r7, r1, ror #12
        str r7, [r0, #0x4c]
        eor.w r6, r8, r6, ror #12
        ldr.w r8, [r0, #0x14]
        ldr.w r4, [r0, #0xa8]
        bic.w r7, r3, r1, ror #16
        eor.w r7, r7, r5, ror #24
        ldr.w r1, [r0, #0x80]
        str.w r7, [r0, #0xb8]
        eor.w r8, r2, r8, ror #1
        eor.w r7, r10, r4, ror #11
        ldr.w r10, [r0, #0x6c]
        eor.w r4, r9, r10
        eor.w r3, r11, r1, ror #22
        bic.w r1, r4, r8, ror #10
        ldr.w r5, [r0, #0xc4]
        bic.w r10, r3, r6, ror #24
        eor.w r1, r1, r3, ror #12
        str r1, [r0, #0x2c]
        eor.w r1, r12, r5, ror #14
        ldr.w r5, [r0, #0x88]
        bic.w r3, r8, r3, ror #2
        eor.w r3, r3, r6, ror #26
        eor.w r10, r10, r1, ror #29
        str.w r10, [r0, #0x6c]
        eor.w r10, r2, r5, ror #4
        str.w r3, [r0, #0xc4]
        bic.w r5, r1, r4, ror #23
        ldr r3, [r0, #0x30]
        eor.w r5, r5, r8, ror #1
        ldr.w r8, [r0, #0x74]
        str.w r5, [r0, #0x80]
        bic.w r5, r6, r1, ror #5
        eor.w r5, r5, r4, ror #28
        ldr r4, [r0, #0x18]
        eor.w r1, r12, r8, ror #10
        ldr.w r8, [r0, #0x90]
        eor.w r3, r11, r3, ror #28
        ldr.w r12, [r0, #0xa0]
        eor.w r4, r9, r4, ror #1
        ldr r6, [sp, #0x4]
        str r5, [r0, #0x14]
        eor.w r5, r9, r8, ror #18
        eor.w r9, r6, r12, ror #31
        bic.w r12, r4, r10, ror #21
        bic.w r8, r9, r1, ror #5
        eor.w r8, r8, r4, ror #22
        str.w r8, [r0, #0x74]
        bic.w r4, r1, r4, ror #17
        eor.w r8, r12, r3, ror #23
        str.w r8, [r0, #0x88]
        bic.w r8, r3, r9, ror #19
        ldr.w r12, [r0, #0x50]
        eor.w r1, r8, r1, ror #24
        str.w r1, [r0, #0xa0]
        bic.w r3, r10, r3, ror #2
        ldr.w r8, [r0, #0x3c]
        eor.w r12, r6, r12, ror #27
        ldr.w r1, [r0, #0xb4]
        eor.w r4, r4, r10, ror #6
        eor.w r10, r2, r8, ror #25
        str r4, [r0, #0x18]
        eor.w r3, r3, r9, ror #21
        str r3, [r0, #0x30]
        eor.w r3, r2, r1, ror #23
        ldr.w r8, [r0, #0x20]
        bic.w r2, r10, r7, ror #30
        ldr.w r9, [r0, #0x44]
        eor.w r2, r2, r12, ror #10
        ldr r1, [sp, #0x8]
        str.w r2, [r0, #0x90]
        eor.w r2, lr, r8, ror #29
        eor.w r9, r1, r9, ror #18
        ldr.w r8, [r0, #0x4]
        eor.w r4, r6, r8
        bic.w r8, r7, r12, ror #12
        ldr.w r6, [r0, #0x98]
        eor.w r1, r8, r2, ror #13
        bic.w r8, r2, r5, ror #24
        str r1, [r0, #0x3c]
        eor.w r8, r8, r10, ror #21
        str.w r8, [r0, #0x50]
        ldr r1, [r0, #0x58]
        bic.w r10, r5, r10, ror #29
        ldr.w r8, [sp, #0x14]
        bic.w r2, r12, r2, ror #1
        ldr.w r12, [r0, #0x48]
        eor.w r2, r2, r5, ror #25
        eor.w r11, r11, r1, ror #10
        str.w r2, [r0, #0xa8]
        eor.w r5, r10, r7, ror #27
        str r5, [r0, #0x20]
        eor.w r6, lr, r6, ror #5
        ldr.w r1, [r8, #0x14]
        bic.w r5, r9, r3, ror #21
        ldr.w r10, [r0, #0x9c]
        eor.w r5, r5, r11, ror #20
        str r5, [r0, #0x58]
        bic.w r7, r6, r9, ror #29
        ldr.w r2, [r0, #0xc4]
        eor.w r8, r7, r3, ror #18
        str.w r8, [r0, #0xb4]
        bic.w r8, r3, r11, ror #31
        ldr r7, [r0, #0x70]
        bic.w r3, r4, r6, ror #25
        ldr.w lr, [r0, #0x20]
        eor.w r5, r3, r9, ror #22
        str r5, [r0, #0x44]
        bic.w r9, r11, r4, ror #22
        ldr r5, [r0, #0x58]
        eor.w r9, r9, r6, ror #15
        str.w r9, [r0, #0x98]
        eor.w r9, r4, r8, ror #11
        ldr.w r3, [r0, #0xb4]
        eor.w r8, r10, r12, ror #12
        ldr r6, [r0, #0xc]
        eor.w r12, r1, r9
        str.w r12, [r0, #0x4]
        ldr.w r12, [r0, #0x64]
        eor.w r2, r8, r2, ror #19
        eor.w r1, r5, r6, ror #20
        ldr.w r9, [r0, #0xbc]
        ldr.w r5, [r0, #0x84]
        eor.w r2, r2, r7, ror #4
        eor.w r7, r3, r12, ror #9
        ldr.w r8, [r0, #0x10]
        ldr r4, [r0, #0x30]
        eor.w r3, r2, lr, ror #26
        eor.w r12, r1, r5, ror #6
        ldr.w r2, [r0, #0x88]
        eor.w r11, r7, r8, ror #30
        ldr.w r8, [r0, #0xac]
        eor.w r4, r12, r4, ror #3
        ldr r5, [r0, #0x38]
        ldr r1, [r0, #0x6c]
        eor.w r6, r11, r2, ror #11
        eor.w r10, r4, r8, ror #22
        ldr r7, [r0, #0x40]
        ldr r2, [r0, #0x1c]
        eor.w r4, r6, r5, ror #6
        ror.w r3, r3, #0xa
        ldr r5, [r0, #0x8]
        ldr r6, [r0, #0x5c]
        ldr.w r12, [r0, #0xb8]
        eor.w r7, r7, r9, ror #18
        ldr.w lr, [r0, #0x44]
        eor.w r8, r6, r5, ror #20
        ldr.w r9, [r0, #0x80]
        eor.w r11, lr, r12, ror #18
        ldr.w lr, [r0, #0x34]
        ldr.w r12, [r0, #0x90]
        eor.w r5, r3, r10, ror #21
        eor.w r9, r8, r9, ror #7
        ldr.w r8, [r0, #0x78]
        eor.w r1, r7, r1, ror #31
        ldr.w r6, [r0, #0xa8]
        eor.w r7, r9, lr, ror #3
        ldr.w lr, [r0, #0x68]
        eor.w r1, r1, r2, ror #18
        ldr.w r9, [r0, #0x4c]
        eor.w r6, r7, r6, ror #22
        ldr.w r2, [r0, #0x98]
        eor.w r7, r11, lr
        ldr.w r11, [r0, #0x18]
        eor.w r9, r2, r9, ror #12
        ldr.w lr, [r0, #0xc0]
        eor.w r2, r1, r12, ror #1
        ldr.w r1, [r0, #0x94]
        eor.w r12, r7, r11, ror #19
        ldr r7, [r0, #0x7c]
        eor.w r9, r9, lr, ror #19
        ldr.w r11, [r0, #0x4]
        eor.w lr, r12, r1, ror #1
        ldr.w r12, [r0]
        eor.w r3, r3, r4, ror #25
        ldr r1, [r0, #0x2c]
        eor.w r8, r12, r8, ror #30
        ldr.w r12, [r0, #0x28]
        eor.w r11, r11, r7, ror #31
        ldr.w r7, [r0, #0xa4]
        eor.w r1, r8, r1, ror #19
        ldr.w r8, [r0, #0xa0]
        eor.w r11, r11, r12, ror #20
        ldr.w r12, [r0, #0x74]
        eor.w r1, r1, r7, ror #27
        ldr r7, [r0, #0x54]
        eor.w r11, r11, r8, ror #27
        ldr.w r8, [r0, #0x24]
        eor.w r9, r9, r12, ror #4
        ldr.w r12, [r0, #0x60]
        eor.w r11, r11, r7, ror #13
        ldr.w r7, [r0, #0xb0]
        eor.w r9, r9, r8, ror #27
        ldr.w r8, [r0, #0x14]
        str r5, [sp]
        eor.w r7, r7, r12, ror #8
        eor.w r12, r2, r11, ror #31
        ldr.w r5, [r0, #0x8c]
        eor.w r7, r7, r8, ror #30
        ldr.w r8, [r0, #0x50]
        eor.w r2, r2, r10, ror #22
        ldr.w r10, [r0, #0x3c]
        str r3, [sp, #0xc]
        eor.w r5, r7, r5, ror #11
        ror.w r6, r6, #0x15
        eor.w r7, r1, r8, ror #12
        ldr r3, [r0, #0x48]
        eor.w r1, r5, r10, ror #6
        ldr r5, [r0, #0x28]
        eor.w r8, r6, r9, ror #10
        eor.w r10, r7, r4, ror #24
        ror.w r1, r1, #0x19
        eor.w r9, r1, r9, ror #9
        eor.w r11, r11, r1
        eor.w r4, r12, r3, ror #22
        ldr r1, [r0, #0x30]
        eor.w r5, r8, r5, ror #20
        ldr r3, [r0, #0x40]
        eor.w r3, r9, r3
        eor.w r6, r6, lr, ror #31
        eor.w lr, lr, r7
        bic.w r7, r5, r4, ror #24
        str r6, [sp, #0x10]
        eor.w r6, r7, r3, ror #20
        eor.w r7, r11, r1, ror #25
        ldr r1, [r0, #0x38]
        str.w r8, [sp, #0x4]
        ror.w r6, r6, #0x1e
        str r6, [r0, #0x28]
        bic.w r6, r7, r5, ror #21
        eor.w r1, r2, r1, ror #31
        eor.w r6, r6, r4, ror #13
        str.w r9, [sp, #0x8]
        bic.w r4, r4, r3, ror #28
        bic.w r3, r3, r1, ror #15
        ror.w r6, r6, #0x9
        eor.w r3, r3, r7, ror #23
        str r6, [r0, #0x30]
        bic.w r7, r1, r7, ror #8
        ldr r6, [r0, #0x64]
        eor.w r5, r7, r5, ror #29
        ror.w r3, r3, #0x12
        eor.w r1, r4, r1, ror #11
        ldr r4, [r0, #0x5c]
        str r3, [r0, #0x40]
        ldr r3, [r0, #0x54]
        eor.w r7, r2, r6, ror #2
        ldr r6, [r0, #0x6c]
        ror.w r5, r5, #0x1
        eor.w r4, r10, r4, ror #21
        eor.w r8, r8, r3, ror #13
        ldr r3, [r0, #0x74]
        str r5, [r0, #0x38]
        eor.w r6, r9, r6, ror #31
        ror.w r5, r1, #0x16
        bic.w r1, r7, r4, ror #3
        str r5, [r0, #0x48]
        eor.w r3, lr, r3, ror #14
        eor.w r5, r1, r8, ror #26
        bic.w r1, r3, r6, ror #24
        eor.w r1, r1, r7, ror #1
        ror.w r5, r5, #0x1d
        bic.w r7, r6, r7, ror #9
        str r5, [r0, #0x74]
        eor.w r7, r7, r4, ror #12
        ror.w r1, r1, #0x1c
        str r1, [r0, #0x5c]
        ldr.w r5, [r0, #0x98]
        ror.w r1, r7, #0x14
        bic.w r7, r4, r8, ror #23
        str r1, [r0, #0x54]
        bic.w r8, r8, r3, ror #5
        eor.w r3, r7, r3, ror #28
        ldr.w r1, [r0, #0x90]
        eor.w r4, r8, r6, ror #29
        ldr.w r6, [r0, #0x88]
        str r3, [r0, #0x6c]
        ldr.w r8, [sp]
        ldr.w r3, [r0, #0xbc]
        eor.w r7, lr, r5, ror #10
        ror.w r5, r4, #0x17
        eor.w r4, r9, r1, ror #1
        str r5, [r0, #0x64]
        eor.w r5, r2, r6, ror #4
        eor.w r9, r9, r3, ror #18
        ldr r6, [r0, #0x78]
        ldr.w r1, [r0, #0x80]
        bic.w r3, r7, r4, ror #18
        eor.w r3, r3, r5, ror #6
        eor.w r6, r8, r6, ror #30
        ror.w r3, r3, #0x12
        eor.w r1, r10, r1, ror #28
        str.w r3, [r0, #0x90]
        bic.w r3, r6, r7, ror #4
        eor.w r3, r3, r4, ror #22
        bic.w r4, r4, r5, ror #20
        bic.w r5, r5, r1, ror #3
        ror.w r3, r3, #0xe
        eor.w r5, r5, r6, ror #22
        str.w r3, [r0, #0x98]
        eor.w r3, r4, r1, ror #23
        ldr r4, [r0, #0x10]
        bic.w r6, r1, r6, ror #19
        ror.w r5, r5, #0x18
        str.w r5, [r0, #0x80]
        ldr.w r5, [r0, #0xb4]
        eor.w r7, r6, r7, ror #23
        ldr.w r1, [r0, #0xac]
        ldr.w r6, [r0, #0xa4]
        eor.w r4, r2, r4, ror #23
        ror.w r3, r3, #0x4
        eor.w r5, r2, r5, ror #25
        eor.w r2, r11, r1, ror #12
        str.w r3, [r0, #0x88]
        eor.w r1, r8, r6, ror #27
        ror.w r6, r7, #0x1b
        str r6, [r0, #0x78]
        bic.w r6, r9, r5, ror #28
        eor.w r6, r6, r2, ror #26
        ldr.w r7, [r0, #0xc4]
        bic.w r3, r5, r2, ror #30
        eor.w r3, r3, r1, ror #11
        ror.w r6, r6, #0x5
        str.w r6, [r0, #0xc4]
        eor.w r6, r12, r7, ror #29
        bic.w r7, r2, r1, ror #13
        ror.w r3, r3, #0x1
        str.w r3, [r0, #0xbc]
        bic.w r2, r6, r9, ror #24
        bic.w r3, r1, r6, ror #1
        ldr r1, [r0, #0x18]
        eor.w r3, r3, r9, ror #25
        ldr.w r9, [sp, #0xc]
        eor.w r6, r7, r6, ror #14
        ldr r7, [r0, #0x8]
        eor.w r2, r2, r5, ror #20
        ldr r5, [r0, #0x20]
        ror.w r6, r6, #0x1f
        eor.w r1, r9, r1, ror #19
        str.w r6, [r0, #0xb4]
        ror.w r6, r3, #0xc
        eor.w r3, r10, r7, ror #9
        ror.w r7, r2, #0xd
        str.w r7, [r0, #0xa4]
        eor.w r7, r12, r5, ror #4
        str.w r6, [r0, #0xac]
        bic.w r6, r1, r4, ror #21
        bic.w r5, r7, r1, ror #28
        eor.w r2, r5, r4, ror #17
        ldr r5, [r0]
        eor.w r6, r6, r3, ror #21
        eor.w r5, r8, r5
        ror.w r2, r2, #0x19
        bic.w r4, r4, r3
        str r2, [r0, #0x10]
        bic.w r2, r3, r5, ror #22
        eor.w r4, r5, r4, ror #10
        ror.w r6, r6, #0x15
        bic.w r3, r5, r7, ror #25
        ldr r5, [r0, #0x2c]
        eor.w r3, r3, r1, ror #21
        ldr r1, [r0, #0x4c]
        eor.w r2, r2, r7, ror #15
        ldr r7, [sp, #0x14]
        eor.w r5, r8, r5, ror #19
        str r6, [r0, #0x8]
        ldr r6, [r7, #0x18]
        ror.w r2, r2, #0xa
        eor.w r7, r6, r4
        eor.w r4, lr, r1, ror #22
        str r3, [r0, #0x18]
        ldr r6, [r0, #0x44]
        eor.w r3, r9, r6
        str r2, [r0, #0x20]
        ldr r1, [r0, #0x50]
        bic.w r6, r5, r4, ror #23
        str r7, [r0]
        ldr r7, [r0, #0x3c]
        ldr r2, [sp, #0x10]
        eor.w r6, r6, r3, ror #19
        eor.w r8, r8, r1, ror #12
        ldr r1, [r0, #0x34]
        ror.w r6, r6, #0x1f
        eor.w r7, r2, r7, ror #31
        str r6, [r0, #0x2c]
        bic.w r6, r4, r3, ror #28
        eor.w r1, r10, r1, ror #24
        eor.w r6, r6, r7, ror #12
        bic.w r3, r3, r7, ror #16
        ror.w r6, r6, #0x16
        eor.w r3, r3, r1, ror #24
        bic.w r7, r7, r1, ror #8
        str r6, [r0, #0x4c]
        ror.w r3, r3, #0x12
        str r3, [r0, #0x44]
        eor.w r6, r7, r5, ror #29
        ldr r7, [r0, #0x58]
        ldr r3, [r0, #0x70]
        bic.w r1, r1, r5, ror #21
        eor.w r4, r1, r4, ror #12
        ldr.w r1, [r0, #0x9c]
        ror.w r6, r6, #0x2
        eor.w r5, r11, r7, ror #22
        ror.w r7, r4, #0xa
        eor.w r4, r12, r3, ror #14
        str r7, [r0, #0x34]
        bic.w r3, r5, r8, ror #24
        eor.w r1, r12, r1, ror #10
        ldr.w r12, [r0, #0x60]
        str r6, [r0, #0x3c]
        eor.w r6, r3, r4, ror #29
        ldr r3, [r0, #0x68]
        bic.w r7, r8, r4, ror #5
        ror.w r6, r6, #0x1f
        eor.w r3, r9, r3
        str r6, [r0, #0x68]
        eor.w r6, r2, r12, ror #1
        eor.w r12, r7, r3, ror #28
        bic.w r7, r4, r3, ror #23
        ldr.w r4, [r0, #0xb8]
        bic.w r3, r3, r6, ror #10
        ror.w r12, r12, #0x17
        eor.w r3, r3, r5, ror #12
        str.w r12, [r0, #0x60]
        ldr.w r12, [r0, #0x8c]
        eor.w r4, r9, r4, ror #18
        ror.w r3, r3, #0x13
        str r3, [r0, #0x50]
        bic.w r3, r6, r5, ror #2
        ldr.w r5, [r0, #0x94]
        eor.w r3, r3, r8, ror #26
        ldr.w r8, [sp, #0x4]
        eor.w r6, r7, r6, ror #1
        ldr.w r7, [r0, #0x84]
        eor.w r9, r9, r5, ror #1
        ldr r5, [r0, #0x7c]
        eor.w r12, r2, r12, ror #4
        ror.w r3, r3, #0x1d
        str r3, [r0, #0x70]
        eor.w r3, r11, r7, ror #28
        ror.w r7, r6, #0x1c
        eor.w r6, r8, r5, ror #31
        bic.w r5, r9, r12, ror #21
        str r7, [r0, #0x58]
        eor.w r5, r5, r3, ror #23
        bic.w r7, r3, r6, ror #19
        ror.w r5, r5, #0x4
        eor.w r7, r7, r1, ror #24
        str.w r5, [r0, #0x8c]
        bic.w r3, r12, r3, ror #2
        ror.w r5, r7, #0x1b
        bic.w r7, r1, r9, ror #17
        str r5, [r0, #0x7c]
        eor.w r3, r3, r6, ror #21
        bic.w r6, r6, r1, ror #5
        ldr.w r5, [r0, #0xa0]
        ror.w r1, r3, #0x19
        ldr.w r3, [r0, #0xa8]
        eor.w r6, r6, r9, ror #22
        str.w r1, [r0, #0x84]
        ldr r1, [r0, #0x14]
        eor.w r9, r7, r12, ror #6
        ldr.w r12, [r0, #0xc0]
        eor.w r5, r8, r5, ror #27
        eor.w r7, r10, r3, ror #11
        ldr.w r10, [r0, #0xb0]
        eor.w r1, r2, r1, ror #23
        ror.w r3, r6, #0xe
        str.w r3, [r0, #0x9c]
        eor.w r6, lr, r12, ror #29
        ldr.w r12, [sp, #0x14]
        eor.w r10, r2, r10, ror #25
        ror.w r9, r9, #0x13
        bic.w r3, r7, r5, ror #12
        str.w r9, [r0, #0x94]
        eor.w r2, r3, r6, ror #13
        ldr r3, [r0, #0x24]
        bic.w r9, r5, r6, ror #1
        eor.w r9, r9, r4, ror #25
        ror.w r2, r2, #0x1f
        str.w r2, [r0, #0xb0]
        bic.w r2, r10, r7, ror #30
        ror.w r9, r9, #0xb
        bic.w r6, r6, r4, ror #24
        str.w r9, [r0, #0xa8]
        bic.w r4, r4, r10, ror #29
        ldr.w r9, [r0, #0x1c]
        eor.w r6, r6, r10, ror #21
        eor.w lr, lr, r3, ror #5
        ldr.w r10, [sp, #0x8]
        eor.w r3, r4, r7, ror #27
        ldr r4, [r0, #0xc]
        eor.w r5, r2, r5, ror #10
        ror.w r6, r6, #0xc
        eor.w r7, r10, r9, ror #18
        ror.w r3, r3, #0x4
        eor.w r4, r11, r4, ror #10
        ldr.w r10, [r0, #0x4]
        str.w r3, [r0, #0xc0]
        bic.w r2, r7, r1, ror #21
        eor.w r3, r8, r10
        bic.w r9, lr, r7, ror #29
        str.w r6, [r0, #0xa0]
        eor.w r8, r2, r4, ror #20
        ror.w r6, r5, #0x1
        bic.w r2, r4, r3, ror #22
        ror.w r5, r8, #0x16
        eor.w r9, r9, r1, ror #18
        str.w r6, [r0, #0xb8]
        ldr.w r6, [r12, #0x1c]
        ldr r8, [r12, #32]!
        str.w r12, [sp, #0x14]
        bic.w r4, r1, r4, ror #31
        ror.w r12, r9, #0x19
        bic.w r10, r3, lr, ror #25
        str.w r12, [r0, #0x14]
        eor.w r9, r3, r4, ror #11
        cmp.w r8, #0xff
        str r5, [r0, #0xc]
        eor.w r11, r2, lr, ror #15
        eor.w r2, r6, r9
        str r2, [r0, #0x4]
        ror.w r12, r11, #0xa
        str.w r12, [r0, #0x24]
        eor.w r2, r10, r7, ror #22
        str r2, [r0, #0x1c]

Lmld_keccak_f1600_x1_armv7m_asm_slothy_end:
        bne.w Lmld_keccak_f1600_x1_armv7m_asm_slothy_start @ imm = #-0x1572
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
