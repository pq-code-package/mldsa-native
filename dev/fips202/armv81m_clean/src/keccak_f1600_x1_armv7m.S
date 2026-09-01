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
/* simpasm: header-end */

    .thumb
    .syntax unified
.text

    @ Credit: Henry S. Warren, Hacker's Delight, Addison-Wesley, 2002
.macro  toBitInterleaving   x0, x1, s0, s1, t, over

    and     \t,\x0,#0x55555555
    orr     \t,\t,\t, LSR #1
    and     \t,\t,#0x33333333
    orr     \t,\t,\t, LSR #2
    and     \t,\t,#0x0F0F0F0F
    orr     \t,\t,\t, LSR #4
    and     \t,\t,#0x00FF00FF
    bfi     \t,\t,#8, #8
    .if \over != 0
    lsr     \s0,\t, #8
    .else
    eor     \s0,\s0,\t, LSR #8
    .endif

    and     \t,\x1,#0x55555555
    orr     \t,\t,\t, LSR #1
    and     \t,\t,#0x33333333
    orr     \t,\t,\t, LSR #2
    and     \t,\t,#0x0F0F0F0F
    orr     \t,\t,\t, LSR #4
    and     \t,\t,#0x00FF00FF
    orr     \t,\t,\t, LSR #8
    eor     \s0,\s0,\t, LSL #16

    and     \t,\x0,#0xAAAAAAAA
    orr     \t,\t,\t, LSL #1
    and     \t,\t,#0xCCCCCCCC
    orr     \t,\t,\t, LSL #2
    and     \t,\t,#0xF0F0F0F0
    orr     \t,\t,\t, LSL #4
    and     \t,\t,#0xFF00FF00
    orr     \t,\t,\t, LSL #8
    .if \over != 0
    lsr     \s1,\t, #16
    .else
    eor     \s1,\s1,\t, LSR #16
    .endif

    and     \t,\x1,#0xAAAAAAAA
    orr     \t,\t,\t, LSL #1
    and     \t,\t,#0xCCCCCCCC
    orr     \t,\t,\t, LSL #2
    and     \t,\t,#0xF0F0F0F0
    orr     \t,\t,\t, LSL #4
    and     \t,\t,#0xFF00FF00
    orr     \t,\t,\t, LSL #8
    bfc     \t, #0, #16
    eors    \s1,\s1,\t
    .endm

    @ Credit: Henry S. Warren, Hacker's Delight, Addison-Wesley, 2002
.macro  fromBitInterleaving     x0, x1, t

    movs    \t, \x0                 @ t = x0@
    bfi     \x0, \x1, #16, #16      @ x0 = (x0 & 0x0000FFFF) | (x1 << 16)@
    bfc     \x1, #0, #16            @   x1 = (t >> 16) | (x1 & 0xFFFF0000)@
    orr     \x1, \x1, \t, LSR #16

    eor     \t, \x0, \x0, LSR #8    @ t = (x0 ^ (x0 >>  8)) & 0x0000FF00UL@  x0 = x0 ^ t ^ (t <<  8)@
    and     \t, #0x0000FF00
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #8

    eor     \t, \x0, \x0, LSR #4    @ t = (x0 ^ (x0 >>  4)) & 0x00F000F0UL@  x0 = x0 ^ t ^ (t <<  4)@
    and     \t, #0x00F000F0
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #4

    eor     \t, \x0, \x0, LSR #2    @ t = (x0 ^ (x0 >>  2)) & 0x0C0C0C0CUL@  x0 = x0 ^ t ^ (t <<  2)@
    and     \t, #0x0C0C0C0C
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #2

    eor     \t, \x0, \x0, LSR #1    @ t = (x0 ^ (x0 >>  1)) & 0x22222222UL@  x0 = x0 ^ t ^ (t <<  1)@
    and     \t, #0x22222222
    eors    \x0, \x0, \t
    eor     \x0, \x0, \t, LSL #1

    eor     \t, \x1, \x1, LSR #8    @ t = (x1 ^ (x1 >>  8)) & 0x0000FF00UL@  x1 = x1 ^ t ^ (t <<  8)@
    and     \t, #0x0000FF00
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #8

    eor     \t, \x1, \x1, LSR #4    @ t = (x1 ^ (x1 >>  4)) & 0x00F000F0UL@  x1 = x1 ^ t ^ (t <<  4)@
    and     \t, #0x00F000F0
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #4

    eor     \t, \x1, \x1, LSR #2    @ t = (x1 ^ (x1 >>  2)) & 0x0C0C0C0CUL@  x1 = x1 ^ t ^ (t <<  2)@
    and     \t, #0x0C0C0C0C
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #2

    eor     \t, \x1, \x1, LSR #1    @ t = (x1 ^ (x1 >>  1)) & 0x22222222UL@  x1 = x1 ^ t ^ (t <<  1)@
    and     \t, #0x22222222
    eors    \x1, \x1, \t
    eor     \x1, \x1, \t, LSL #1
    .endm

@   --- offsets in state
.equ Aba0, 0*4
.equ Aba1, 1*4
.equ Abe0, 2*4
.equ Abe1, 3*4
.equ Abi0, 4*4
.equ Abi1, 5*4
.equ Abo0, 6*4
.equ Abo1, 7*4
.equ Abu0, 8*4
.equ Abu1, 9*4
.equ Aga0, 10*4
.equ Aga1, 11*4
.equ Age0, 12*4
.equ Age1, 13*4
.equ Agi0, 14*4
.equ Agi1, 15*4
.equ Ago0, 16*4
.equ Ago1, 17*4
.equ Agu0, 18*4
.equ Agu1, 19*4
.equ Aka0, 20*4
.equ Aka1, 21*4
.equ Ake0, 22*4
.equ Ake1, 23*4
.equ Aki0, 24*4
.equ Aki1, 25*4
.equ Ako0, 26*4
.equ Ako1, 27*4
.equ Aku0, 28*4
.equ Aku1, 29*4
.equ Ama0, 30*4
.equ Ama1, 31*4
.equ Ame0, 32*4
.equ Ame1, 33*4
.equ Ami0, 34*4
.equ Ami1, 35*4
.equ Amo0, 36*4
.equ Amo1, 37*4
.equ Amu0, 38*4
.equ Amu1, 39*4
.equ Asa0, 40*4
.equ Asa1, 41*4
.equ Ase0, 42*4
.equ Ase1, 43*4
.equ Asi0, 44*4
.equ Asi1, 45*4
.equ Aso0, 46*4
.equ Aso1, 47*4
.equ Asu0, 48*4
.equ Asu1, 49*4

@   --- offsets on stack
.equ mDa0, 0*4
.equ mDa1, 1*4
.equ mDo0, 2*4
.equ mDo1, 3*4
.equ mDi0, 4*4
.equ mRC    , 5*4
.equ mSize, 6*4

/******************************************************************************
 * Bitwise exclusive-OR where both operands are misaligned (i.e. src1 and src2
 * are rotated by rot1 and rot2, respectively).
 * The output result is also misaligned (i.e. dst is rotated by rot1-rot2).
 *  - dst           destination register
 *  - src1-src2     source registers
 *  - rot1-rot2     rotation values
 *****************************************************************************/
.macro eorror   dst, src1, src2, rot1, rot2
.if \rot1 >= \rot2
    eor  \dst, \src1, \src2, ror #\rot1-\rot2
.else
    eor  \dst, \src1, \src2, ror #32+\rot1-\rot2
.endif
.endm


/******************************************************************************
 * Bit clear instruction where both operands are misaligned (i.e. src1 and src2
 * are rotated by rot1 and rot2, respectively).
 * The output result is also misaligned (i.e. dst is rotated by rot1-rot2).
 *  - dst           destination register
 *  - src1-src2     source registers
 *  - rot1-rot2     rotation values
 *****************************************************************************/
.macro bicror   dst, src1, src2, rot1, rot2
.if \rot1 >= \rot2
    bic  \dst, \src1, \src2, ror #\rot1-\rot2
.else
    bic  \dst, \src1, \src2, ror #32+\rot1-\rot2
.endif
.endm


/******************************************************************************
 * Load 5 words from memory and XOR them all together. It is used to compute
 * the parity columns for the Theta step.
 * Note that all operands may be misaligned (i.e. rotated by a certain amount
 * of bits), as well as the result.
 *  - dst           destination register
 *  - src1-src5     source registers
 *  - rot1-rot5     rotation values
 *****************************************************************************/
.macro xor5   dst, src1, src2, src3, src4, src5, rot1, rot2, rot3, rot4, rot5
    ldr.w   \dst, [r0, #\src1] // @slothy:reads=[r0\src1]
    ldr.w     r1, [r0, #\src2] // @slothy:reads=[r0\src2]
    ldr.w     r5, [r0, #\src3] // @slothy:reads=[r0\src3]
    ldr      r11, [r0, #\src4] // @slothy:reads=[r0\src4]
    ldr      r12, [r0, #\src5] // @slothy:reads=[r0\src5]
    eorror  \dst, \dst,  r1, \rot1, \rot2
    eorror  \dst, \dst,  r5, \rot1, \rot3
    eorror  \dst, \dst, r11, \rot1, \rot4
    eorror  \dst, \dst, r12, \rot1, \rot5
.endm


/******************************************************************************
 * Same as xor5, except that a previous result is stored on the stack after the
 * loads from memory. This allows to have the str instruction for free.
 *  - dst           destination register
 *  - src1-src5     source registers
 *  - rot1-rot5     rotation values
 *  - strreg        register from previous calculations to be stored in memory
 *  - stradr        register holding the address to store `prev`
 *  - strofs        stack pointer memory offset for the str instruction
 *****************************************************************************/
.macro xor5str   dst, src1, src2, src3, src4, src5, rot1, rot2, rot3, rot4, rot5, strreg, stradr, strofs
    ldr.w    \dst, [r0, #\src1] // @slothy:reads=[r0\src1]
    ldr.w      r1, [r0, #\src2] // @slothy:reads=[r0\src2]
    ldr.w      r5, [r0, #\src3] // @slothy:reads=[r0\src3]
    ldr       r11, [r0, #\src4] // @slothy:reads=[r0\src4]
    ldr       r12, [r0, #\src5] // @slothy:reads=[r0\src5]
    str.w \strreg, [\stradr, #\strofs] // @slothy:writes=[\stradr\strofs]
    eorror   \dst, \dst,  r1, \rot1, \rot2
    eorror   \dst, \dst,  r5, \rot1, \rot3
    eorror   \dst, \dst, r11, \rot1, \rot4
    eorror   \dst, \dst, r12, \rot1, \rot5
.endm


/******************************************************************************
 * Exclusive-OR where the 2nd operand is rotated by 1 bit to the left.
 *  - dst           destination register
 *  - src1-src2     source registers
 *  - rot           differential rotation btw src1 & src2 (i.e. rot=rot1-rot2)
 *****************************************************************************/
.macro xorrol   dst, src1, src2, rot
    eor  \dst, \src1, \src2, ror #\rot-1
.endm


/******************************************************************************
 * Bitslice implementation of the Chi step with misaligned operands.
 *  - resofs        memory offset within the internal state to store the result
 *  - src1-src3     source registers
 *  - rot1-rot3     rotation values
 *****************************************************************************/
.macro xandnotlazystr   resofs, src1, src2, src3, rot1, rot2, rot3
    bicror  r1, \src3, \src2, \rot3, \rot2
    eorror  r1, r1, \src1, \rot3, \rot1
    str.w   r1, [r0, #\resofs] // @slothy:writes=[r0\resofs]
.endm


/******************************************************************************
 * Same as xandnotlazystr but without the str instruction which will be carried
 * out later in order to take advantage of future ldr instructions.
 *  - src1-src3     source registers
 *  - rot1-rot3     rotation values
 *****************************************************************************/
.macro xandnotlazy  src1, src2, src3, rot1, rot2, rot3
    bicror  r1, \src3, \src2, \rot3, \rot2
    eorror  r1, r1, \src1, \rot3, \rot1
.endm


/******************************************************************************
 * Same as xandnotlazystr with an additional rotation in order to explictly
 * compute the Rho step. It is useful in KeccakRound3 in order to return to the
 * classical representation every 4 rounds.
 *  - resofs        memory offset within the internal state to store the result
 *  - src1-src3     source registers
 *  - rot1-rot3     rotation values
 *****************************************************************************/
.macro xandnotstr  resofs, src1, src2, src3, rot1, rot2, rot3
    bicror  r1, \src3, \src2, \rot3, \rot2
    eorror  r1,    r1, \src1, \rot3, \rot1
.if \rot3 > 0
    ror     r1, r1, #32-\rot3
.endif
    str.w   r1, [r0, #\resofs] // @slothy:writes=[r0\resofs]
.endm


/******************************************************************************
 * Same as xandnotstr but without the str instruction which will be carried
 * out later in order to take advantage of future ldr instructions.
 *  - src1-src3     source registers
 *  - rot1-rot3     rotation values
 *****************************************************************************/
.macro xandnot  src1, src2, src3, rot1, rot2, rot3
    bicror  r1, \src3, \src2, \rot3, \rot2
    eorror  r1,    r1, \src1, \rot3, \rot1
.if \rot3 > 0
    ror     r1, r1, #32-\rot3
.endif
.endm


/******************************************************************************
 * Same as xandnot followed by the Iota step. Note that the source registers
 * are not specified since they are always r3, r4 and r5.
 *  - out           output reg (useful to store the result in the next round)
 *  - rot2-rot3     rotation values
 *  - rcofs         memory offset to load the round constant
 *  - last          Boolean to indicate whether its the last round of the
 *                  quadruple round routine
 *****************************************************************************/
.macro xandnotiota    out, rot3, rot2, rcofs, last
    bicror  r5, r5, r4, \rot3, \rot2
    ldr     r1, [sp, #mRC] // @slothy:reads=[spmRC]
    ldr     r4, [r1, #\rcofs] // @slothy:reads=[r1\rcofs]
.if  \last == 1
    ldr     r7, [r1, #32]! // @slothy:reads=[r132]
    str     r1, [sp, #mRC] // @slothy:writes=[spmRC]
    cmp     r7, #0xFF
.endif
.if \rot3 > 0
    eor    r3, r3, r5, ror #32-\rot3
.else
    eor.w  r3, r3, r5
.endif
    eor.w  \out, r4, r3
.endm


/******************************************************************************
 * Add the parity bits to the state registers r3-r7. If the state registers are
 * not properly aligned due to previous lazy rotations, use the barrel shifter
 * to fix the misalignment when adding the parity bits.
 *  - par1-par5     registers containing the parity bits
 *  - dly1-dly5     rotation values to compute the (delayed) Rho step
 *****************************************************************************/
.macro addparity par1, dly1, par2, dly2, par3, dly3, par4, dly4, par5, dly5
.if \dly1 > 0
    eor    r3, \par1, r3, ror #32-\dly1
.else
    eor.w  r3, \par1, r3
.endif
.if \dly2 > 0
    eor    r4, \par2, r4, ror #32-\dly2
.else
    eor.w  r4, \par2, r4
.endif
.if \dly3 > 0
    eor    r5, \par3, r5, ror #32-\dly3
.else
    eor.w  r5, \par3, r5
.endif
.if \dly4 > 0
    eor    r6, \par4, r6, ror #32-\dly4
.else
    eor.w  r6, \par4, r6
.endif
.if \dly5 > 0
    eor    r7, \par5, r7, ror #32-\dly5
.else
    eor.w  r7, \par5, r7
.endif
.endm


/******************************************************************************
 * Apply Theta, Pi, Chi and Iota steps to half a plane (i.e. 5 32-bit words) of
 * the internal state.
 * Note that the Rho step is calculated if and only if \lazy == 0, otherwise it
 * is delayed until the next round using ''lazy reductions'' thanks to the
 * inline barrel shifter.
 *  - src1-src5     source registers
 *  - par1-par5     registers containing the parity bits
 *  - rot2-rot5     rotation values to compute the current Rho step
 *  - dly1-dly5     rotation values to compute the delayed Rho step
 *  - prev          register from previous calculations to be stored in memory
 *  - strofs        stack pointer memory offset for the str instruction
 *  - reg           output reg related to the Iota step (to be stored later)
 *****************************************************************************/
.macro    KeccakThetaRhoPiChiIota   src1, par1,       dly1, \
                                    src2, par2, rot2, dly2, \
                                    src3, par3, rot3, dly3, \
                                    src4, par4, rot4, dly4, \
                                    src5, par5, rot5, dly5, \
                                    ofs,  last, lazy, strofs, reg
    ldr.w       r3, [r0, #\src1] // @slothy:reads=[r0\src1]
    ldr       r4, [r0, #\src2] // @slothy:reads=[r0\src2]
    ldr       r5, [r0, #\src3] // @slothy:reads=[r0\src3]
    ldr       r6, [r0, #\src4] // @slothy:reads=[r0\src4]
    ldr       r7, [r0, #\src5] // @slothy:reads=[r0\src5]
    str.w       r1, [r0, #\strofs] // @slothy:writes=[r0\strofs]
    addparity   \par1, \dly1, \par2, \dly2, \par3, \dly3, \par4, \dly4, \par5, \dly5
.if \lazy == 1
    xandnotlazystr  \src2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotlazystr  \src3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotlazystr  \src4, r6, r7, r3, \rot4, \rot5,     0
    xandnotlazystr  \src5, r7, r3, r4, \rot5,     0, \rot2
.else
    xandnotstr     \src2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotstr     \src3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotstr     \src4, r6, r7, r3, \rot4, \rot5,     0
    xandnotstr     \src5, r7, r3, r4, \rot5,     0, \rot2
.endif
    xandnotiota    \reg, \rot3, \rot2, \ofs, \last
.endm


/******************************************************************************
 * Apply Theta, Pi, and Chi steps to half a plane (i.e. 5 32-bit words) of the
 * internal state.
 * Note that the Rho step is calculated if and only if \lazy == 0, otherwise it
 * is delayed until the next round using ''lazy reductions'' thanks to the
 * inline barrel shifter.
 *  - src1-src5     source registers
 *  - dst1-dst5     memory offsets to store the output registers
 *  - par1-par5     registers containing the parity bits
 *  - rot2-rot5     rotation values to compute the current Rho step
 *  - dly1-dly5     rotation values to compute the delayed Rho step
 *  - lazy          Boolean to indicate whether lazy rotations are used or not
 *  - strofs        stack pointer memory offset to store the last output of the
 *                  previous round.
 *****************************************************************************/
.macro    KeccakThetaRhoPiChi   src1, dst1, par1, rot1, dly1, \
                                src2, dst2, par2, rot2, dly2, \
                                src3, dst3, par3, rot3, dly3, \
                                src4, dst4, par4, rot4, dly4, \
                                src5, dst5, par5, rot5, dly5, \
                                lazy, strofs
    ldr.w       r3, [r0, #\src1] // @slothy:reads=[r0\src1]
    ldr.w       r4, [r0, #\src2] // @slothy:reads=[r0\src2]
    ldr.w       r5, [r0, #\src3] // @slothy:reads=[r0\src3]
    ldr.w       r6, [r0, #\src4] // @slothy:reads=[r0\src4]
    ldr.w       r7, [r0, #\src5] // @slothy:reads=[r0\src5]
    str.w       r1, [r0, #\strofs] // @slothy:writes=[r0\strofs]
    addparity   \par1, \dly1, \par2, \dly2, \par3, \dly3, \par4, \dly4, \par5, \dly5
.if \lazy == 1
    xandnotlazystr  \dst1, r3, r4, r5, \rot1, \rot2, \rot3
    xandnotlazystr  \dst2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotlazystr  \dst3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotlazystr  \dst4, r6, r7, r3, \rot4, \rot5, \rot1
    xandnotlazy            r7, r3, r4, \rot5, \rot1, \rot2
.else
    xandnotstr      \dst1, r3, r4, r5, \rot1, \rot2, \rot3
    xandnotstr      \dst2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotstr      \dst3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotstr      \dst4, r6, r7, r3, \rot4, \rot5, \rot1
    xandnot                r7, r3, r4, \rot5, \rot1, \rot2
.endif
.endm

.macro    KeccakThetaRhoPiChiSkipStore   src1, dst1, par1, rot1, dly1, \
                                src2, dst2, par2, rot2, dly2, \
                                src3, dst3, par3, rot3, dly3, \
                                src4, dst4, par4, rot4, dly4, \
                                src5, dst5, par5, rot5, dly5, \
                                lazy, strofs
    ldr.w       r3, [r0, #\src1] // @slothy:reads=[r0\src1]
    ldr.w       r4, [r0, #\src2] // @slothy:reads=[r0\src2]
    ldr.w       r5, [r0, #\src3] // @slothy:reads=[r0\src3]
    ldr.w       r6, [r0, #\src4] // @slothy:reads=[r0\src4]
    ldr.w       r7, [r0, #\src5] // @slothy:reads=[r0\src5]
    addparity   \par1, \dly1, \par2, \dly2, \par3, \dly3, \par4, \dly4, \par5, \dly5
.if \lazy == 1
    xandnotlazystr  \dst1, r3, r4, r5, \rot1, \rot2, \rot3
    xandnotlazystr  \dst2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotlazystr  \dst3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotlazystr  \dst4, r6, r7, r3, \rot4, \rot5, \rot1
    xandnotlazy            r7, r3, r4, \rot5, \rot1, \rot2
.else
    xandnotstr      \dst1, r3, r4, r5, \rot1, \rot2, \rot3
    xandnotstr      \dst2, r4, r5, r6, \rot2, \rot3, \rot4
    xandnotstr      \dst3, r5, r6, r7, \rot3, \rot4, \rot5
    xandnotstr      \dst4, r6, r7, r3, \rot4, \rot5, \rot1
    xandnot                r7, r3, r4, \rot5, \rot1, \rot2
.endif
.endm

/******************************************************************************
 * 1st round of the 4 unrolled rounds routine due to in-place processing.
 * At the beginning of such rounds, the internal state is expected to match the
 * classical representation (i.e. without transition and no delayed Rho step).
 *****************************************************************************/
.macro    KeccakRound0
    xor5      r3, Abu0, Agu0, Aku0, Amu0, Asu0, 0, 0, 0, 0, 0
    xor5      r7, Abe1, Age1, Ake1, Ame1, Ase1, 0, 0, 0, 0, 0
    xorrol    r6, r3, r7, 32
    xor5str   r4, Abi1, Agi1, Aki1, Ami1, Asi1, 0, 0, 0, 0, 0, r6, sp, mDa0
    eor.w     r6, r3, r4
    xor5str   r3, Abo0, Ago0, Ako0, Amo0, Aso0, 0, 0, 0, 0, 0, r6, sp, mDo1
    eor.w     r2, r7, r3
    xor5      r7, Aba0, Aga0, Aka0, Ama0, Asa0, 0, 0, 0, 0, 0
    xorrol   r10, r7, r4, 32
    xor5      r4, Abo1, Ago1, Ako1, Amo1, Aso1, 0, 0, 0, 0, 0
    eor      r14, r4, r7
    xor5      r7, Abe0, Age0, Ake0, Ame0, Ase0, 0, 0, 0, 0, 0
    xorrol    r6, r7, r4, 32
    xor5str   r4, Abu1, Agu1, Aku1, Amu1, Asu1, 0, 0, 0, 0, 0, r6, sp, mDi0
    eor.w     r8, r4, r7
    xor5str   r7, Abi0, Agi0, Aki0, Ami0, Asi0, 0, 0, 0, 0, 0, r8, sp, mDa1
    xorrol    r9, r7, r4, 32
    xor5str   r4, Aba1, Aga1, Aka1, Ama1, Asa1, 0, 0, 0, 0, 0, r9, sp, mDo0
    eor      r11, r4, r7
    xorrol   r12, r3, r4, 32
    KeccakThetaRhoPiChiSkipStore Abo0, Aka1,  r9, 14, 0, \
                        Agu0, Ame1, r12, 10, 0, \
                        Aka1, Asi1,  r8,  2, 0, \
                        Ame1, Abo0, r11, 23, 0, \
                        Asi1, Agu0,  r2, 31, 0, \
                        1, Aka1
    KeccakThetaRhoPiChi Abe0, Asa1, r10,  0, 0, \
                        Agi1, Abe0,  r2,  3, 0, \
                        Ako0, Agi1,  r9, 12, 0, \
                        Amu1, Ako0, r14,  4, 0, \
                        Asa1, Amu1,  r8,  9, 0, \
                        1, Agu0
    ldr         r8, [sp, #mDa0] // @slothy:reads=[spmDa0]
    KeccakThetaRhoPiChi Abu1, Aga0, r14, 14, 0, \
                        Aga0, Ake0,  r8, 18, 0, \
                        Ake0, Ami1, r10,  5, 0, \
                        Ami1, Aso0,  r2,  8, 0, \
                        Aso0, Abu1,  r9, 28, 0, \
                        1, Amu1
    KeccakThetaRhoPiChi Abi1, Ama0,  r2, 31, 0, \
                        Ago0, Ase1,  r9, 27, 0, \
                        Aku0, Abi1, r12, 19, 0, \
                        Ama0, Ago0,  r8, 20, 0, \
                        Ase1, Aku0, r11,  1, 0, \
                        1, Abu1
    ldr         r9, [sp, #mDo1] // @slothy:reads=[spmDo1]
    KeccakThetaRhoPiChiIota Aba0,  r8,  0,    \
                            Age0, r10, 22, 0, \
                            Aki1,  r2, 22, 0, \
                            Amo1,  r9, 11, 0, \
                            Asu0, r12,  7, 0, \
                            0, 0, 1, Aku0, r1
    ldr.w       r2, [sp, #mDi0] // @slothy:reads=[spmDi0]
    KeccakThetaRhoPiChi Abo1, Aka0,  r9, 14, 0, \
                        Agu1, Ame0, r14, 10, 0, \
                        Aka0, Asi0,  r8,  1, 0, \
                        Ame0, Abo1, r10, 22, 0, \
                        Asi0, Agu1,  r2, 30, 0, \
                        1, Aba0
    KeccakThetaRhoPiChi Abe1, Asa0, r11,  1, 0, \
                        Agi0, Abe1,  r2,  3, 0, \
                        Ako1, Agi0,  r9, 13, 0, \
                        Amu0, Ako1, r12,  4, 0, \
                        Asa0, Amu0,  r8,  9, 0, \
                        1, Agu1
    ldr         r8, [sp, #mDa1] // @slothy:reads=[spmDa1]
    KeccakThetaRhoPiChi Abu0, Aga1, r12, 13, 0, \
                        Aga1, Ake1,  r8, 18, 0, \
                        Ake1, Ami0, r11,  5, 0, \
                        Ami0, Aso1,  r2,  7, 0, \
                        Aso1, Abu0,  r9, 28, 0, \
                        1, Amu0
    KeccakThetaRhoPiChi Abi0, Ama1,  r2, 31, 0, \
                        Ago1, Ase0,  r9, 28, 0, \
                        Aku1, Abi0, r14, 20, 0, \
                        Ama1, Ago1,  r8, 21, 0, \
                        Ase0, Aku1, r10,  1, 0, \
                        1, Abu0
    ldr         r9, [sp, #mDo0] // @slothy:reads=[spmDo0]
    KeccakThetaRhoPiChiIota Aba1,  r8,  0,    \
                            Age1, r11, 22, 0, \
                            Aki0,  r2, 21, 0, \
                            Amo0,  r9, 10, 0, \
                            Asu1, r14,  7, 0, \
                            4, 0, 1, Aku1, r14
.endm



/******************************************************************************
 * 2nd round of the 4 unrolled rounds routine due to in-place processing.
 *****************************************************************************/
.macro    KeccakRound1
    xor5str     r3, Asu0, Agu0, Amu0, Abu1, Aku1, 22, 10,  3, 18, 28, r14, r0, Aba1
    xor5        r7, Age1, Ame0, Abe0, Ake1, Ase1, 10, 22,  4,  7, 20
    ror         r3, #32-22
    xorrol      r6, r3, r7, 32-10
    xor5str     r4, Aki0, Asi0, Agi1, Ami0, Abi1,  7, 30,  9, 28,  1, r6, sp, mDa0
    eor         r6, r3, r4, ror #32-7
    xor5str     r3, Amo1, Abo0, Ako1, Aso0, Ago1,  0, 14,  1, 14, 31, r6, sp, mDo1
    eor         r2, r3, r7, ror #32-10
    xor5        r7, Aba0, Aka1, Asa0, Aga0, Ama1,  0,  2, 13,  5, 20
    xorrol     r10, r7, r4, 32-7
    xor5        r4, Amo0, Abo1, Ako0, Aso1, Ago0,  0, 14,  0, 13, 31
    eor        r14, r4, r7
    xor5        r7, Age0, Ame1, Abe1, Ake0, Ase0, 11, 23,  4,  8, 21
    ror         r7, #32-11
    xorrol      r6, r7, r4, 32
    xor5str     r4, Asu1, Agu1, Amu1, Abu0, Aku0, 22, 10,  3, 18, 27, r6, sp, mDi0
    eor         r8, r7, r4, ror #32-22
    xor5str     r7, Aki1, Asi1, Agi0, Ami1, Abi0,  7, 31,  9, 28,  1, r8, sp, mDa1
    ror         r7, #32-7
    xorrol      r9, r7, r4, 32-22
    xor5str     r4, Aba1, Aka0, Asa1, Aga1, Ama0,  0,  1, 12,  5, 19, r9, sp, mDo0
    eor        r11, r4, r7
    xorrol     r12, r3, r4, 32
    KeccakThetaRhoPiChiSkipStore Amo1, Asa1,  r9, 14,  0, \
                        Agu0, Ake1, r12, 10, 10, \
                        Asa1, Abi1,  r8,  2, 12, \
                        Ake1, Amo1, r11, 23,  7, \
                        Abi1, Agu0,  r2, 31,  1, \
                        1, Asa1
    KeccakThetaRhoPiChi Age0, Ama0, r10,  0, 11, \
                        Asi0, Age0,  r2,  3, 30, \
                        Ako1, Asi0,  r9, 12,  1, \
                        Abu0, Ako1, r14,  4, 18, \
                        Ama0, Abu0,  r8,  9, 19, \
                        1, Agu0
    ldr         r8, [sp, #mDa0] // @slothy:reads=[spmDa0]
    KeccakThetaRhoPiChi Asu1, Aka1, r14, 14, 22, \
                        Aka1, Abe1,  r8, 18,  2, \
                        Abe1, Ami0, r10,  5,  4, \
                        Ami0, Ago1,  r2,  8, 28, \
                        Ago1, Asu1,  r9, 28, 31, \
                        1, Abu0
    KeccakThetaRhoPiChi Aki0, Aga0,  r2, 31,  7, \
                        Abo0, Ase1,  r9, 27, 14, \
                        Amu0, Aki0, r12, 19,  3, \
                        Aga0, Abo0,  r8, 20,  5, \
                        Ase1, Amu0, r11,  1, 20, \
                        1, Asu1
    ldr         r9, [sp, #mDo1] // @slothy:reads=[spmDo1]
    KeccakThetaRhoPiChiIota Aba0,  r8,  0,     \
                            Ame1, r10, 22, 23, \
                            Agi1,  r2, 22,  9, \
                            Aso1,  r9, 11, 13, \
                            Aku1, r12,  7, 28, \
                            8, 0, 1, Amu0, r1
    ldr.w         r2, [sp, #mDi0] // @slothy:reads=[spmDi0]
    KeccakThetaRhoPiChi Amo0, Asa0,  r9, 14,  0, \
                        Agu1, Ake0, r14, 10, 10, \
                        Asa0, Abi0,  r8,  1, 13, \
                        Ake0, Amo0, r10, 22,  8, \
                        Abi0, Agu1,  r2, 30,  1, \
                        1, Aba0
    KeccakThetaRhoPiChi Age1, Ama1, r11,  1, 10, \
                        Asi1, Age1,  r2,  3, 31, \
                        Ako0, Asi1,  r9, 13,  0, \
                        Abu1, Ako0, r12,  4, 18, \
                        Ama1, Abu1,  r8,  9, 20, \
                        1, Agu1
    ldr         r8, [sp, #mDa1] // @slothy:reads=[spmDa1]
    KeccakThetaRhoPiChi Asu0, Aka0, r12, 13, 22, \
                        Aka0, Abe0,  r8, 18,  1, \
                        Abe0, Ami1, r11,  5,  4, \
                        Ami1, Ago0,  r2,  7, 28, \
                        Ago0, Asu0,  r9, 28, 31, \
                        1, Abu1
    KeccakThetaRhoPiChi Aki1, Aga1,  r2, 31,  7, \
                        Abo1, Ase0,  r9, 28, 14, \
                        Amu1, Aki1, r14, 20,  3, \
                        Aga1, Abo1,  r8, 21,  5, \
                        Ase0, Amu1, r10,  1, 21, \
                        1, Asu0
    ldr         r9, [sp, #mDo0] // @slothy:reads=[spmDo0]
    KeccakThetaRhoPiChiIota Aba1,  r8,  0,     \
                            Ame0, r11, 22, 22, \
                            Agi0,  r2, 21,  9, \
                            Aso0,  r9, 10, 14, \
                            Aku0, r14,  7, 27, \
                            12, 0, 1, Amu1, r14
.endm

/******************************************************************************
 * 3rd round of the 4 unrolled rounds routine due to in-place processing.
 *****************************************************************************/
.macro    KeccakRound2
    xor5str     r3, Aku1, Agu0, Abu1, Asu1, Amu1, 22, 10,  3, 18, 28, r14, r0, Aba1
    xor5        r7, Ame0, Ake0, Age0, Abe0, Ase1, 10, 22,  4,  7, 20
    ror         r3, #32-22
    xorrol      r6, r3, r7, 32-10
    xor5str     r4, Agi0, Abi0, Asi0, Ami1, Aki0,  7, 30,  9, 28,  1, r6, sp, mDa0
    eor         r6, r3, r4, ror #32-7
    xor5str     r3, Aso1, Amo1, Ako0, Ago1, Abo1,  0, 14,  1, 14, 31, r6, sp, mDo1
    eor         r2, r3, r7, ror #32-10
    xor5        r7, Aba0, Asa1, Ama1, Aka1, Aga1,  0,  2, 13,  5, 20
    xorrol     r10, r7, r4, 32-7
    xor5        r4, Aso0, Amo0, Ako1, Ago0, Abo0,  0, 14,  0, 13, 31
    eor        r14, r4, r7
    xor5        r7, Ame1, Ake1, Age1, Abe1, Ase0, 11, 23,  4,  8, 21
    ror         r7, #32-11
    xorrol      r6, r7, r4, 32
    xor5str     r4, Aku0, Agu1, Abu0, Asu0, Amu0, 22, 10,  3, 18, 27, r6, sp, mDi0
    eor         r8, r7, r4, ror #32-22
    xor5str     r7, Agi1, Abi1, Asi1, Ami0, Aki1,  7, 31,  9, 28,  1, r8, sp, mDa1
    ror         r7, #32-7
    xorrol      r9, r7, r4, 32-22
    xor5str     r4, Aba1, Asa0, Ama0, Aka0, Aga0,  0,  1, 12,  5, 19, r9, sp, mDo0
    eor        r11, r4, r7
    xorrol     r12, r3, r4, 32
    KeccakThetaRhoPiChiSkipStore Aso1, Ama0,  r9, 14,  0, \
                        Agu0, Abe0, r12, 10, 10, \
                        Ama0, Aki0,  r8,  2, 12, \
                        Abe0, Aso1, r11, 23,  7, \
                        Aki0, Agu0,  r2, 31,  1, \
                        1, Ama0
    KeccakThetaRhoPiChi Ame1, Aga0, r10,  0, 11, \
                        Abi0, Ame1,  r2,  3, 30, \
                        Ako0, Abi0,  r9, 12,  1, \
                        Asu0, Ako0, r14,  4, 18, \
                        Aga0, Asu0,  r8,  9, 19, \
                        1, Agu0
    ldr     r8, [sp, #mDa0] // @slothy:reads=[spmDa0]
    KeccakThetaRhoPiChi Aku0, Asa1, r14, 14, 22, \
                        Asa1, Age1,  r8, 18,  2, \
                        Age1, Ami1, r10,  5,  4, \
                        Ami1, Abo1,  r2,  8, 28, \
                        Abo1, Aku0,  r9, 28, 31, \
                        1, Asu0
    KeccakThetaRhoPiChi Agi0, Aka1,  r2, 31,  7, \
                        Amo1, Ase1,  r9, 27, 14, \
                        Abu1, Agi0, r12, 19,  3, \
                        Aka1, Amo1,  r8, 20,  5, \
                        Ase1, Abu1, r11,  1, 20, \
                        1, Aku0
    ldr     r9, [sp, #mDo1] // @slothy:reads=[spmDo1]
    KeccakThetaRhoPiChiIota Aba0, r8,  0,     \
                            Ake1, r10,22, 23, \
                            Asi0, r2, 22,  9, \
                            Ago0, r9, 11, 13, \
                            Amu1, r12, 7, 28, \
                            16, 0, 1, Abu1, r1
    ldr.w   r2, [sp, #mDi0] // @slothy:reads=[spmDi0]
    KeccakThetaRhoPiChi Aso0, Ama1,  r9, 14,  0, \
                        Agu1, Abe1, r14, 10, 10, \
                        Ama1, Aki1,  r8,  1, 13, \
                        Abe1, Aso0, r10, 22,  8, \
                        Aki1, Agu1,  r2, 30,  1, \
                        1, Aba0
    KeccakThetaRhoPiChi Ame0, Aga1, r11,  1, 10, \
                        Abi1, Ame0,  r2,  3, 31, \
                        Ako1, Abi1,  r9, 13,  0, \
                        Asu1, Ako1, r12,  4, 18, \
                        Aga1, Asu1,  r8,  9, 20, \
                        1, Agu1
    ldr     r8, [sp, #mDa1] // @slothy:reads=[spmDa1]
    KeccakThetaRhoPiChi Aku1, Asa0, r12, 13, 22, \
                        Asa0, Age0,  r8, 18,  1, \
                        Age0, Ami0, r11,  5,  4, \
                        Ami0, Abo0,  r2,  7, 28, \
                        Abo0, Aku1,  r9, 28, 31, \
                        1, Asu1
    KeccakThetaRhoPiChi Agi1, Aka0,  r2, 31,  7, \
                        Amo0, Ase0,  r9, 28, 14, \
                        Abu0, Agi1, r14, 20,  3, \
                        Aka0, Amo0,  r8, 21,  5, \
                        Ase0, Abu0, r10,  1, 21, \
                        1, Aku1
    ldr     r9, [sp, #mDo0] // @slothy:reads=[spmDo0]
    KeccakThetaRhoPiChiIota Aba1,  r8,  0,     \
                            Ake0, r11, 22, 22, \
                            Asi1,  r2, 21,  9, \
                            Ago1,  r9, 10, 14, \
                            Amu0, r14,  7, 27, \
                            20, 0, 1, Abu0, r14

.endm


/******************************************************************************
 * 4th round of the 4 unrolled rounds routine due to in-place processing.
 * Note that the Rho step is *not* delayed so that the internal state is
 * compliant w/ the classical representation at the end of the routine.
 *****************************************************************************/
.macro    KeccakRound3
    xor5str     r3, Amu1, Agu0, Asu1, Aku0, Abu0, 22, 10,  3, 18, 28, r14, r0, Aba1
    xor5        r7, Ake0, Abe1, Ame1, Age0, Ase1, 10, 22,  4,  7, 20
    ror         r3, #32-22
    xorrol      r6, r3, r7, 32-10
    xor5str     r4, Asi1, Aki1, Abi0, Ami0, Agi0,  7, 30,  9, 28,  1, r6, sp, mDa0
    eor         r6, r3, r4, ror #32-7
    xor5str     r3, Ago0, Aso1, Ako1, Abo1, Amo0,  0, 14,  1, 14, 31, r6, sp, mDo1
    eor         r2, r3, r7, ror #32-10
    xor5        r7, Aba0, Ama0, Aga1, Asa1, Aka0,  0,  2, 13,  5, 20
    xorrol     r10, r7, r4, 32-7
    xor5        r4, Ago1, Aso0, Ako0, Abo0, Amo1,  0, 14,  0, 13, 31
    eor        r14, r4, r7
    xor5        r7, Ake1, Abe0, Ame0, Age1, Ase0, 11, 23,  4,  8, 21
    ror         r7, #32-11
    xorrol      r6, r7, r4, 32
    xor5str     r4, Amu0, Agu1, Asu0, Aku1, Abu1, 22, 10,  3, 18, 27, r6, sp, mDi0
    eor         r8, r7, r4, ror #32-22
    xor5str     r7, Asi0, Aki0, Abi1, Ami1, Agi1,  7, 31,  9, 28,  1, r8, sp, mDa1
    ror         r7, #32-7
    xorrol      r9, r7, r4, 32-22
    xor5str     r4, Aba1, Ama1, Aga0, Asa0, Aka1,  0,  1, 12,  5, 19, r9, sp, mDo0
    eor        r11, r4, r7
    xorrol     r12, r3, r4, 32
    KeccakThetaRhoPiChiSkipStore     Ago0, Aga0,  r9, 14,  0, \
                            Agu0, Age0, r12, 10, 10, \
                            Aga0, Agi0,  r8,  2, 12, \
                            Age0, Ago0, r11, 23,  7, \
                            Agi0, Agu0,  r2, 31,  1, \
                            0, Aga0
    KeccakThetaRhoPiChi     Ake1, Aka1, r10,  0, 11, \
                            Aki1, Ake1,  r2,  3, 30, \
                            Ako1, Aki1,  r9, 12,  1, \
                            Aku1, Ako1, r14,  4, 18, \
                            Aka1, Aku1,  r8,  9, 19, \
                            0, Agu0
    ldr     r8, [sp, #mDa0] // @slothy:reads=[spmDa0]
    KeccakThetaRhoPiChi     Amu0, Ama0, r14, 14, 22, \
                            Ama0, Ame0,  r8, 18,  2, \
                            Ame0, Ami0, r10,  5,  4, \
                            Ami0, Amo0,  r2,  8, 28, \
                            Amo0, Amu0,  r9, 28, 31, \
                            0, Aku1
    KeccakThetaRhoPiChi     Asi1, Asa1,  r2, 31,  7, \
                            Aso1, Ase1,  r9, 27, 14, \
                            Asu1, Asi1, r12, 19,  3, \
                            Asa1, Aso1,  r8, 20,  5, \
                            Ase1, Asu1, r11,  1, 20, \
                            0, Amu0
    ldr     r9, [sp, #mDo1] // @slothy:reads=[spmDo1]
    KeccakThetaRhoPiChiIota Aba0,  r8,  0,     \
                            Abe0, r10, 22, 23, \
                            Abi0,  r2, 22,  9, \
                            Abo0,  r9, 11, 13, \
                            Abu0, r12,  7, 28, \
                            24, 0, 0, Asu1, r1
    ldr.w   r2, [sp, #mDi0] // @slothy:reads=[spmDi0]
    KeccakThetaRhoPiChi     Ago1, Aga1,  r9, 14,  0, \
                            Agu1, Age1, r14, 10, 10, \
                            Aga1, Agi1,  r8,  1, 13, \
                            Age1, Ago1, r10, 22,  8, \
                            Agi1, Agu1,  r2, 30,  1, \
                            0, Aba0
    KeccakThetaRhoPiChi     Ake0, Aka0, r11,  1, 10, \
                            Aki0, Ake0,  r2,  3, 31, \
                            Ako0, Aki0,  r9, 13,  0, \
                            Aku0, Ako0, r12,  4, 18, \
                            Aka0, Aku0,  r8,  9, 20, \
                            0, Agu1
    ldr     r8, [sp, #mDa1] // @slothy:reads=[spmDa1]
    KeccakThetaRhoPiChi     Amu1, Ama1, r12, 13, 22, \
                            Ama1, Ame1,  r8, 18,  1, \
                            Ame1, Ami1, r11,  5,  4, \
                            Ami1, Amo1,  r2,  7, 28, \
                            Amo1, Amu1,  r9, 28, 31, \
                            0, Aku0
    KeccakThetaRhoPiChi     Asi0, Asa0,  r2, 31,  7, \
                            Aso0, Ase0,  r9, 28, 14, \
                            Asu0, Asi0, r14, 20,  3, \
                            Asa0, Aso0,  r8, 21,  5, \
                            Ase0, Asu0, r10,  1, 21, \
                            0, Amu1
    ldr     r9, [sp, #mDo0] // @slothy:reads=[spmDo0]
    KeccakThetaRhoPiChiIota Aba1,  r8, 0,      \
                            Abe1, r11, 22, 22, \
                            Abi1,  r2, 21,  9, \
                            Abo1,  r9, 10, 14, \
                            Abu1, r14,  7, 27, \
                            28, 1, 0, Asu0, r1
    str.w r1, [r0, #Aba1] // @slothy:writes=[r0Aba1]
.endm

@----------------------------------------------------------------------------
@
@ void KeccakF1600_StatePermute( void *state )
@
.align 8
.global   MLD_ASM_NAMESPACE(keccak_f1600_x1_armv7m_asm)
.type MLD_ASM_NAMESPACE(keccak_f1600_x1_armv7m_asm),%function
MLD_ASM_FN_SYMBOL(keccak_f1600_x1_armv7m_asm)
    push    { r4 - r12, lr }
    sub     sp, #mSize
    str     r1, [sp, #mRC]
mld_keccak_f1600_x1_armv7m_asm_StatePermute_RoundLoop:
mld_keccak_f1600_x1_armv7m_asm_slothy_start:
    KeccakRound0
    KeccakRound1
    KeccakRound2
    KeccakRound3
mld_keccak_f1600_x1_armv7m_asm_slothy_end:
    bne     mld_keccak_f1600_x1_armv7m_asm_StatePermute_RoundLoop
    add     sp, #mSize
    pop     { r4 - r12, pc }

MLD_ASM_FN_SIZE(keccak_f1600_x1_armv7m_asm)

/* simpasm: footer-start */
#endif /* MLD_FIPS202_ARMV81M_NEED_X1 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
