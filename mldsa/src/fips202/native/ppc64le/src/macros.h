/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Keccakf1600 Permutation Macros for PowerPC 64-bit Little Endian
 *
 * This file implements the Keccakf1600 permutation using PowerPC AltiVec
 * instructions. Operates on a 5×5 array of 64-bit lanes (1600 bits total) and
 * consists of 24 rounds, each applying five steps: Theta (θ), Rho (ρ), Pi (π),
 * Chi (χ), and Iota (ι).
 *
 * SIMD Parallelization Strategy:
 * - Each PowerPC vector register holds 2×64-bit lanes
 * - Enables parallel processing of 2 independent Keccak states simultaneously
 * - 25 vector registers (r0-r24) represent the complete 5×5 state array
 *
 * Reference: FIPS 202 - SHA-3 Standard: Permutation-Based Hash and
 * Extendable-Output Functions
 * https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf
 */

#ifndef MLD_FIPS202_NATIVE_PPC64LE_SRC_MACROS_H
#define MLD_FIPS202_NATIVE_PPC64LE_SRC_MACROS_H

#include <stdint.h>
#include "../../../../params.h"
#include "util.h"

/* ============================================================================
 * Vector Type Constructors and Constants
 * ============================================================================
 */

/* VCONST: Create a 64-bit vector with both lanes set to the same value
 * Example: VCONST(5) creates {5, 5} */
#define MLD_VINT64_CONST(n) ((__vector uint64_t){n, n})

/* VINT32_WIDTH: Number of 32-bit integers that fit in one 128-bit vector
 * register PowerPC vectors are 128 bits = 4 × 32-bit integers */
#define MLD_VINT32_WIDTH 4

/* Zero vector (both lanes = 0) */
#define MLD_VINT64_0 ((__vector uint64_t){0, 0})

/* Vector with both lanes = 1 (used for rotation by 1 bit) */
#define MLD_VINT64_1 ((__vector uint64_t){1, 1})

/* Permutation mask for interleaving even/odd 32-bit elements
 *
 * Byte indices (each int32 is 4 bytes):
 *   0x04-0x07: high 32 bits of first even result  → lane 0
 *   0x14-0x17: high 32 bits of first odd result   → lane 1
 *   0x0C-0x0F: high 32 bits of second even result → lane 2
 *   0x1C-0x1F: high 32 bits of second odd result  → lane 3
 */
#define MLD_VPERM                                                           \
  ((__vector unsigned char){0x04, 0x05, 0x06, 0x07, 0x14, 0x15, 0x16, 0x17, \
                            0x0C, 0x0D, 0x0E, 0x0F, 0x1C, 0x1D, 0x1E, 0x1F})

/* ============================================================================
 * Keccak Rho Step Rotation Constants
 *
 * The Rho step rotates each lane by a specific offset. These are the standard
 * rotation offsets defined in the Keccak specification for the 24 non-zero
 * positions in the 5×5 state array
 * -> position [0,0] has rotation 0
 *
 * The rotation offsets follow the pattern: t(i+1) = (t(i) + i + 1) mod 64
 * starting from t(0) = 0 at position (1,0).
 * ============================================================================
 */
#define MLD_RHO0 MLD_VINT64_CONST(1)   /* Rotation by 1 bit */
#define MLD_RHO1 MLD_VINT64_CONST(3)   /* Rotation by 3 bits */
#define MLD_RHO2 MLD_VINT64_CONST(6)   /* Rotation by 6 bits */
#define MLD_RHO3 MLD_VINT64_CONST(10)  /* Rotation by 10 bits */
#define MLD_RHO4 MLD_VINT64_CONST(15)  /* Rotation by 15 bits */
#define MLD_RHO5 MLD_VINT64_CONST(21)  /* Rotation by 21 bits */
#define MLD_RHO6 MLD_VINT64_CONST(28)  /* Rotation by 28 bits */
#define MLD_RHO7 MLD_VINT64_CONST(36)  /* Rotation by 36 bits */
#define MLD_RHO8 MLD_VINT64_CONST(45)  /* Rotation by 45 bits */
#define MLD_RHO9 MLD_VINT64_CONST(55)  /* Rotation by 55 bits */
#define MLD_RHO10 MLD_VINT64_CONST(2)  /* Rotation by 2 bits */
#define MLD_RHO11 MLD_VINT64_CONST(14) /* Rotation by 14 bits */
#define MLD_RHO12 MLD_VINT64_CONST(27) /* Rotation by 27 bits */
#define MLD_RHO13 MLD_VINT64_CONST(41) /* Rotation by 41 bits */
#define MLD_RHO14 MLD_VINT64_CONST(56) /* Rotation by 56 bits */
#define MLD_RHO15 MLD_VINT64_CONST(8)  /* Rotation by 8 bits */
#define MLD_RHO16 MLD_VINT64_CONST(25) /* Rotation by 25 bits */
#define MLD_RHO17 MLD_VINT64_CONST(43) /* Rotation by 43 bits */
#define MLD_RHO18 MLD_VINT64_CONST(62) /* Rotation by 62 bits */
#define MLD_RHO19 MLD_VINT64_CONST(18) /* Rotation by 18 bits */
#define MLD_RHO20 MLD_VINT64_CONST(39) /* Rotation by 39 bits */
#define MLD_RHO21 MLD_VINT64_CONST(61) /* Rotation by 61 bits */
#define MLD_RHO22 MLD_VINT64_CONST(20) /* Rotation by 20 bits */
#define MLD_RHO23 MLD_VINT64_CONST(44) /* Rotation by 44 bits */

/* ============================================================================
 * Basic Vector Operations
 *
 * These macros provide a consistent interface for vector operations used
 * throughout the Keccak implementation.
 * ============================================================================
 */

/** Bitwise OR: c = a | b */
#define MLD_OR(c, a, b) c = (a | b)

/** Bitwise XOR: c = a ^ b */
#define MLD_XOR(c, a, b) c = (a ^ b)

/** Bitwise AND: c = a & b */
#define MLD_AND(c, a, b) c = (a & b)

/** Vector addition: c = a + b */
#define MLD_ADD(c, a, b) c = (a + b)

/** Left shift: c = a << b */
#define MLD_LSL(c, a, b) c = (a << b)

/** Vector rotate left (PowerPC vec_rl intrinsic) */
#define MLD_VRL(c, a, b) c = vec_rl(a, b)

/* ============================================================================
 * Keccak Algorithm Step Macros
 * ============================================================================
 */

/**
 * CTHETA: Compute column parity for Theta step
 *
 * The Theta step mixes columns by XORing each lane with the parity of two
 * columns. This macro computes the parity (XOR) of all 5 lanes in a single
 * column.
 *
 * Formula: out = a ⊕ b ⊕ c ⊕ d ⊕ e
 *
 * - out is == output: parity of the column
 * - a,b,c,d,e == 5 lanes in the column (rows 0-4)
 */
#define MLD_CTHETA(out, a, b, c, d, e) \
  MLD_XOR(out, a, b);                  \
  MLD_XOR(out, out, c);                \
  MLD_XOR(out, out, d);                \
  MLD_XOR(out, out, e);

/**
 * VROTL64: Rotate left 64-bit lanes within vector
 *
 * Performs left rotation on 64-bit values using PowerPC vector rotate.
 *
 * - c:  output vector
 * - a:  input vector
 * - b:  number of bits to rotate (as vector)
 */
#define MLD_VROTL64(c, a, b) MLD_VRL(c, a, b);

/**
 * DTHETA: Compute diffusion value for Theta step
 *
 * For each column, compute the diffusion value used in Theta mixing.
 * Formula: c = a ⊕ ROT(b, 1)
 * where a is the parity of column (x-1)
 * and b is the parity of column (x+1).
 *
 * - c:  Output: diffusion value
 * - a:  Column parity of previous column (x-1)
 * - b:  Column parity of next column (x+1)
 */
#define MLD_DTHETA(c, a, b)        \
  MLD_VROTL64(c, b, MLD_VINT64_1); \
  MLD_XOR(c, c, a);

/**
 * CHI: Apply Chi (χ) transformation
 *
 * Chi is the only non-linear step in Keccak, providing confusion.
 * Formula: out = a ⊕ ((NOT b) AND c)
 *
 * Uses vec_andc which efficiently computes (NOT b) AND c in one instruction.
 *
 * - out:  Output lane
 * - a:    Current lane A[x]
 * - b:    Next lane A[x+1]
 * - c:    Lane after next A[x+2]
 */
#define MLD_CHI(out, a, b, c) MLD_XOR(out, a, vec_andc(c, b));

/**
 * RHOPI: Combined Rho and Pi transformation
 *
 * Rho: Rotates each lane by a specific offset (diffusion within lanes)
 * Pi: Rearranges lane positions according to (x,y) → (y, 2x+3y mod 5)
 *
 * This macro combines both steps efficiently by:
 * 1. Saving the current temporary value to x
 * 2. Rotating lane z by t bits and storing in y
 *
 * - x:  Temporary output register (receives old y value)
 * - y:  Temporary input/output register (receives rotated z)
 * - z:  Lane to rotate
 * - t:  Rotation amount (RHO constant)
 */
#define MLD_RHOPI(x, y, z, t) \
  x = y;                      \
  MLD_VROTL64(y, z, t);

/* ============================================================================
 * Keccak State Variable Declarations
 *
 * The Keccak state is a 5×5 array of 64-bit lanes (25 lanes total = 1600 bits).
 * We represent this using 25 vector registers (r0 through r24).
 * Each vector can hold 2 lanes for parallel processing of 2 independent states.
 *
 * State Layout (row-major indexing):
 *   Lane index = row * 5 + column
 *
 *   Lanes  0- 4: Row 0 (y=0, x=0..4)
 *   Lanes  5- 9: Row 1 (y=1, x=0..4)
 *   Lanes 10-14: Row 2 (y=2, x=0..4)
 *   Lanes 15-19: Row 3 (y=3, x=0..4)
 *   Lanes 20-24: Row 4 (y=4, x=0..4)
 * ============================================================================
 */

/**
 * XSTATEVARS: Declare 25 vector registers for Keccak state
 *
 * Each register (r0-r24) represents one lane of the 5×5 Keccak state.
 * When processing 2 states in parallel, each vector holds:
 *   - Lane 0: value from first state
 *   - Lane 1: value from second state
 */
#define MLD_XSTATEVARS                       \
  __vector uint64_t r0, r1, r2, r3, r4;      \
  __vector uint64_t r5, r6, r7, r8, r9;      \
  __vector uint64_t r10, r11, r12, r13, r14; \
  __vector uint64_t r15, r16, r17, r18, r19; \
  __vector uint64_t r20, r21, r22, r23, r24;

/**
 * XTHETAVARS: Declare working variables for Theta step
 *
 * c0-c4: Column parities C[x] = XOR of all 5 lanes in column x
 * d0-d4: Diffusion values D[x] = C[x-1] ⊕ ROT(C[x+1], 1)
 *
 * These are intermediate values used in the Theta mixing step.
 */
#define MLD_XTHETAVARS                  \
  __vector uint64_t c0, c1, c2, c3, c4; \
  __vector uint64_t d0, d1, d2, d3, d4;

/**
 * XRhoPIChiVARS: Declare temporary variables for Rho, Pi, and Chi steps
 *
 * These 5 temporaries (t0-t4) are used to:
 * - Hold intermediate values during Rho-Pi permutation
 * - Store row values during Chi transformation
 */
#define MLD_XRhoPIChiVARS __vector uint64_t t0, t1, t2, t3, t4;

/* ============================================================================
 * State Load/Store Macros
 * ============================================================================
 */
/**
 * XLOADST_MULT: Load two Keccak states for parallel processing
 *
 * Loads two states simultaneously, interleaving them in vector registers.
 * This enables SIMD processing of 2 independent Keccak permutations in
 * parallel.
 *
 * Vector lane layout after loading:
 *   - Lane 0: value from state1
 *   - Lane 1: value from state2
 *
 * state1: first uint64_t array of 25 elements
 * state2: second uint64_t array of 25 elements
 */
#define MLD_XLOADST_MULT(state1, state2)             \
  r0 = (__vector uint64_t){state1[0], state2[0]};    \
  r1 = (__vector uint64_t){state1[1], state2[1]};    \
  r2 = (__vector uint64_t){state1[2], state2[2]};    \
  r3 = (__vector uint64_t){state1[3], state2[3]};    \
  r4 = (__vector uint64_t){state1[4], state2[4]};    \
  r5 = (__vector uint64_t){state1[5], state2[5]};    \
  r6 = (__vector uint64_t){state1[6], state2[6]};    \
  r7 = (__vector uint64_t){state1[7], state2[7]};    \
  r8 = (__vector uint64_t){state1[8], state2[8]};    \
  r9 = (__vector uint64_t){state1[9], state2[9]};    \
  r10 = (__vector uint64_t){state1[10], state2[10]}; \
  r11 = (__vector uint64_t){state1[11], state2[11]}; \
  r12 = (__vector uint64_t){state1[12], state2[12]}; \
  r13 = (__vector uint64_t){state1[13], state2[13]}; \
  r14 = (__vector uint64_t){state1[14], state2[14]}; \
  r15 = (__vector uint64_t){state1[15], state2[15]}; \
  r16 = (__vector uint64_t){state1[16], state2[16]}; \
  r17 = (__vector uint64_t){state1[17], state2[17]}; \
  r18 = (__vector uint64_t){state1[18], state2[18]}; \
  r19 = (__vector uint64_t){state1[19], state2[19]}; \
  r20 = (__vector uint64_t){state1[20], state2[20]}; \
  r21 = (__vector uint64_t){state1[21], state2[21]}; \
  r22 = (__vector uint64_t){state1[22], state2[22]}; \
  r23 = (__vector uint64_t){state1[23], state2[23]}; \
  r24 = (__vector uint64_t){state1[24], state2[24]};

/**
 * XSTOREST_MULT: Store vector registers back to two Keccak states
 *
 * De-interleaves the vector registers and stores to two separate states.
 * Used after parallel processing of 2 states.
 *
 * Extraction:
 *   - Lane 0 → state1
 *   - Lane 1 → state2
 *
 * state1:  first uint64_t array of 25 elements
 * state2:  second uint64_t array of 25 elements
 */
#define MLD_XSTOREST_MULT(state1, state2) \
  do                                      \
  {                                       \
    state1[0] = r0[0];                    \
    state2[0] = r0[1];                    \
    state1[1] = r1[0];                    \
    state2[1] = r1[1];                    \
    state1[2] = r2[0];                    \
    state2[2] = r2[1];                    \
    state1[3] = r3[0];                    \
    state2[3] = r3[1];                    \
    state1[4] = r4[0];                    \
    state2[4] = r4[1];                    \
    state1[5] = r5[0];                    \
    state2[5] = r5[1];                    \
    state1[6] = r6[0];                    \
    state2[6] = r6[1];                    \
    state1[7] = r7[0];                    \
    state2[7] = r7[1];                    \
    state1[8] = r8[0];                    \
    state2[8] = r8[1];                    \
    state1[9] = r9[0];                    \
    state2[9] = r9[1];                    \
    state1[10] = r10[0];                  \
    state2[10] = r10[1];                  \
    state1[11] = r11[0];                  \
    state2[11] = r11[1];                  \
    state1[12] = r12[0];                  \
    state2[12] = r12[1];                  \
    state1[13] = r13[0];                  \
    state2[13] = r13[1];                  \
    state1[14] = r14[0];                  \
    state2[14] = r14[1];                  \
    state1[15] = r15[0];                  \
    state2[15] = r15[1];                  \
    state1[16] = r16[0];                  \
    state2[16] = r16[1];                  \
    state1[17] = r17[0];                  \
    state2[17] = r17[1];                  \
    state1[18] = r18[0];                  \
    state2[18] = r18[1];                  \
    state1[19] = r19[0];                  \
    state2[19] = r19[1];                  \
    state1[20] = r20[0];                  \
    state2[20] = r20[1];                  \
    state1[21] = r21[0];                  \
    state2[21] = r21[1];                  \
    state1[22] = r22[0];                  \
    state2[22] = r22[1];                  \
    state1[23] = r23[0];                  \
    state2[23] = r23[1];                  \
    state1[24] = r24[0];                  \
    state2[24] = r24[1];                  \
  } while (0)

/******************************************************************************
 * Helper Macros for Chi Step
 *
 * The Chi transformation operates on rows of the state. These macros copy
 * 5 consecutive state registers (one complete row) into temporaries t0-t4.
 * This allows Chi to process each row independently.
 *******************************************************************************/

/* Copy state lanes 0-4 (row 0) to temporaries for Chi processing */
#define MLD_SET_R0_TO_R4 \
  t0 = r0;               \
  t1 = r1;               \
  t2 = r2;               \
  t3 = r3;               \
  t4 = r4;

/* Copy state lanes 5-9 (row 1) to temporaries for Chi processing */
#define MLD_SET_R5_TO_R9 \
  t0 = r5;               \
  t1 = r6;               \
  t2 = r7;               \
  t3 = r8;               \
  t4 = r9;

/* Copy state lanes 10-14 (row 2) to temporaries for Chi processing */
#define MLD_SET_R10_TO_R14 \
  t0 = r10;                \
  t1 = r11;                \
  t2 = r12;                \
  t3 = r13;                \
  t4 = r14;

/* Copy state lanes 15-19 (row 3) to temporaries for Chi processing */
#define MLD_SET_R15_TO_R19 \
  t0 = r15;                \
  t1 = r16;                \
  t2 = r17;                \
  t3 = r18;                \
  t4 = r19;

/* Copy state lanes 20-24 (row 4) to temporaries for Chi processing */
#define MLD_SET_R20_TO_R24 \
  t0 = r20;                \
  t1 = r21;                \
  t2 = r22;                \
  t3 = r23;                \
  t4 = r24;

/****************************************************************************
 * Keccak Round Function Components
 *
 * Each Keccak round consists of 5 steps applied in sequence:
 * 1. Theta (θ): Linear mixing of columns
 * 2. Rho (ρ): Rotation of lanes
 * 3. Pi (π): Permutation of lane positions
 * 4. Chi (χ): Non-linear transformation
 * 5. Iota (ι): Addition of round constant
 **************************************************************************** */

/**
 * KECCAKF_THETA_INIT: Initialize Theta step
 *
 * Computes column parities and diffusion values for the Theta mixing step.
 *
 * Step 1: Compute column parities
 *   C[x] = A[0,x] ⊕ A[1,x] ⊕ A[2,x] ⊕ A[3,x] ⊕ A[4,x]
 *
 * Step 2: Compute diffusion values
 *   D[x] = C[x-1] ⊕ ROT(C[x+1], 1)
 *
 * These values are then used in KECCAKF_THETA_PROCESS to mix the state.
 */
#define MLD_KECCAKF_THETA_INIT           \
  MLD_CTHETA(c0, r0, r5, r10, r15, r20); \
  MLD_CTHETA(c1, r1, r6, r11, r16, r21); \
  MLD_CTHETA(c2, r2, r7, r12, r17, r22); \
  MLD_CTHETA(c3, r3, r8, r13, r18, r23); \
  MLD_CTHETA(c4, r4, r9, r14, r19, r24); \
  MLD_DTHETA(d0, c4, c1);                \
  MLD_DTHETA(d1, c0, c2);                \
  MLD_DTHETA(d2, c1, c3);                \
  MLD_DTHETA(d3, c2, c4);                \
  MLD_DTHETA(d4, c3, c0);

/**
 * KECCAKF_THETA_PROCESS: Apply Theta diffusion to all lanes
 *
 * XORs each lane with its corresponding diffusion value.
 * Formula: A'[y,x] = A[y,x] ⊕ D[x]
 *
 * This provides diffusion across columns, mixing information from
 * neighboring columns into each lane.
 */
#define MLD_KECCAKF_THETA_PROCESS \
  MLD_XOR(r0, r0, d0);            \
  MLD_XOR(r5, r5, d0);            \
  MLD_XOR(r10, r10, d0);          \
  MLD_XOR(r15, r15, d0);          \
  MLD_XOR(r20, r20, d0);          \
  MLD_XOR(r1, r1, d1);            \
  MLD_XOR(r6, r6, d1);            \
  MLD_XOR(r11, r11, d1);          \
  MLD_XOR(r16, r16, d1);          \
  MLD_XOR(r21, r21, d1);          \
  MLD_XOR(r2, r2, d2);            \
  MLD_XOR(r7, r7, d2);            \
  MLD_XOR(r12, r12, d2);          \
  MLD_XOR(r17, r17, d2);          \
  MLD_XOR(r22, r22, d2);          \
  MLD_XOR(r3, r3, d3);            \
  MLD_XOR(r8, r8, d3);            \
  MLD_XOR(r13, r13, d3);          \
  MLD_XOR(r18, r18, d3);          \
  MLD_XOR(r23, r23, d3);          \
  MLD_XOR(r4, r4, d4);            \
  MLD_XOR(r9, r9, d4);            \
  MLD_XOR(r14, r14, d4);          \
  MLD_XOR(r19, r19, d4);          \
  MLD_XOR(r24, r24, d4);

/**
 * KECCAKF_RHOPI: Combined Rho and Pi steps
 *
 * Rho: Rotates each lane by a specific offset (provides diffusion within lanes)
 * Pi: Rearranges lane positions according to (x,y) → (y, 2x+3y mod 5)
 *
 * This implements the full permutation pattern using temporaries t0-t3.
 * The sequence follows the standard Keccak permutation order,
 * starting from lane (1,0)
 * and following the Pi permutation pattern for 24 steps.
 */
#define MLD_KECCAKF_RHOPI            \
  MLD_RHOPI(t0, r10, r1, MLD_RHO0);  \
  MLD_RHOPI(t1, r7, t0, MLD_RHO1);   \
  MLD_RHOPI(t2, r11, t1, MLD_RHO2);  \
  MLD_RHOPI(t3, r17, t2, MLD_RHO3);  \
  MLD_RHOPI(t0, r18, t3, MLD_RHO4);  \
  MLD_RHOPI(t1, r3, t0, MLD_RHO5);   \
  MLD_RHOPI(t2, r5, t1, MLD_RHO6);   \
  MLD_RHOPI(t3, r16, t2, MLD_RHO7);  \
  MLD_RHOPI(t0, r8, t3, MLD_RHO8);   \
  MLD_RHOPI(t1, r21, t0, MLD_RHO9);  \
  MLD_RHOPI(t2, r24, t1, MLD_RHO10); \
  MLD_RHOPI(t3, r4, t2, MLD_RHO11);  \
  MLD_RHOPI(t0, r15, t3, MLD_RHO12); \
  MLD_RHOPI(t1, r23, t0, MLD_RHO13); \
  MLD_RHOPI(t2, r19, t1, MLD_RHO14); \
  MLD_RHOPI(t3, r13, t2, MLD_RHO15); \
  MLD_RHOPI(t0, r12, t3, MLD_RHO16); \
  MLD_RHOPI(t1, r2, t0, MLD_RHO17);  \
  MLD_RHOPI(t2, r20, t1, MLD_RHO18); \
  MLD_RHOPI(t3, r14, t2, MLD_RHO19); \
  MLD_RHOPI(t0, r22, t3, MLD_RHO20); \
  MLD_RHOPI(t1, r9, t0, MLD_RHO21);  \
  MLD_RHOPI(t2, r6, t1, MLD_RHO22);  \
  MLD_RHOPI(t3, r1, t2, MLD_RHO23);

/**
 * KECCAKF_CHI: Apply Chi transformation to all rows
 *
 * -> Chi is the only non-linear step in Keccak.
 * It operates on each row independently,
 * applying the formula: A'[x,y] = A[x,y] ⊕ ((NOT A[x+1,y]) AND A[x+2,y])
 *
 * This provides confusion and is essential for cryptographic security.
 */
#define MLD_KECCAKF_CHI      \
  MLD_SET_R0_TO_R4           \
  MLD_CHI(r0, r0, t1, t2);   \
  MLD_CHI(r1, r1, t2, t3);   \
  MLD_CHI(r2, r2, t3, t4);   \
  MLD_CHI(r3, r3, t4, t0);   \
  MLD_CHI(r4, r4, t0, t1);   \
  MLD_SET_R5_TO_R9           \
  MLD_CHI(r5, r5, t1, t2);   \
  MLD_CHI(r6, r6, t2, t3);   \
  MLD_CHI(r7, r7, t3, t4);   \
  MLD_CHI(r8, r8, t4, t0);   \
  MLD_CHI(r9, r9, t0, t1);   \
  MLD_SET_R10_TO_R14         \
  MLD_CHI(r10, r10, t1, t2); \
  MLD_CHI(r11, r11, t2, t3); \
  MLD_CHI(r12, r12, t3, t4); \
  MLD_CHI(r13, r13, t4, t0); \
  MLD_CHI(r14, r14, t0, t1); \
  MLD_SET_R15_TO_R19         \
  MLD_CHI(r15, r15, t1, t2); \
  MLD_CHI(r16, r16, t2, t3); \
  MLD_CHI(r17, r17, t3, t4); \
  MLD_CHI(r18, r18, t4, t0); \
  MLD_CHI(r19, r19, t0, t1); \
  MLD_SET_R20_TO_R24         \
  MLD_CHI(r20, r20, t1, t2); \
  MLD_CHI(r21, r21, t2, t3); \
  MLD_CHI(r22, r22, t3, t4); \
  MLD_CHI(r23, r23, t4, t0); \
  MLD_CHI(r24, r24, t0, t1);

/**
 * KECCAKF_IOTA: Apply Iota step (round constant addition)
 *
 * Adds a round-specific constant to lane A[0,0] to break symmetry.
 * Each of the 24 rounds uses a different constant
 *
 * - round:  Round # (0-23)
 */
#define MLD_KECCAKF_IOTA(round) \
  MLD_XOR(r0, r0, (mld_keccakf1600_round_constants_ppc64le[round]));

/**
 * KECCAKF_ROUND: Execute one complete Keccak round
 *
 * Applies all 5 steps of the Keccak round function in sequence:
 * Theta → Rho → Pi → Chi → Iota
 *
 * round:  Round number (0-23) for the Iota step
 */
#define MLD_KECCAKF_ROUND(round) \
  MLD_KECCAKF_THETA_INIT         \
  MLD_KECCAKF_THETA_PROCESS      \
  MLD_KECCAKF_RHOPI              \
  MLD_KECCAKF_CHI                \
  MLD_KECCAKF_IOTA(round)

/**
 * XKECCAKF_ROUND24: Execute all 24 Keccak rounds
 *
 * Performs the complete keccakf1600 permutation by executing
 * 24 rounds sequentially. This is the core of the SHA-3 hash function.
 */
#define MLD_XKECCAKF_ROUND24 \
  MLD_KECCAKF_ROUND(0);      \
  MLD_KECCAKF_ROUND(1);      \
  MLD_KECCAKF_ROUND(2);      \
  MLD_KECCAKF_ROUND(3);      \
  MLD_KECCAKF_ROUND(4);      \
  MLD_KECCAKF_ROUND(5);      \
  MLD_KECCAKF_ROUND(6);      \
  MLD_KECCAKF_ROUND(7);      \
  MLD_KECCAKF_ROUND(8);      \
  MLD_KECCAKF_ROUND(9);      \
  MLD_KECCAKF_ROUND(10);     \
  MLD_KECCAKF_ROUND(11);     \
  MLD_KECCAKF_ROUND(12);     \
  MLD_KECCAKF_ROUND(13);     \
  MLD_KECCAKF_ROUND(14);     \
  MLD_KECCAKF_ROUND(15);     \
  MLD_KECCAKF_ROUND(16);     \
  MLD_KECCAKF_ROUND(17);     \
  MLD_KECCAKF_ROUND(18);     \
  MLD_KECCAKF_ROUND(19);     \
  MLD_KECCAKF_ROUND(20);     \
  MLD_KECCAKF_ROUND(21);     \
  MLD_KECCAKF_ROUND(22);     \
  MLD_KECCAKF_ROUND(23);

/* keccakf_1600_2x_ppc64le: Execute keccakf1600 on two states in parallel
 *
 * Performs the complete keccakf1600 permutation on two independent states
 * simultaneously using SIMD parallelization. This provides approximately 2x
 * throughput compared to processing states sequentially.
 *
 * Process:
 * 1. Declare state and working variables
 * 2. Load both states into vector registers (interleaved)
 * 3. Execute 24 rounds of keccakf1600 in parallel
 * 4. Store results back to both states (de-interleaved)
 *
 * state1:  Pointer to first Keccak state (25 uint64_t elements)
 * state2:  Pointer to second Keccak state (25 uint64_t elements)
 */
#define mld_keccakf_1600_2x_ppc64le(state1, state2) \
  do                                                \
  {                                                 \
    MLD_XSTATEVARS;                                 \
    MLD_XTHETAVARS;                                 \
    MLD_XRhoPIChiVARS;                              \
    MLD_XLOADST_MULT(state1, state2);               \
    MLD_XKECCAKF_ROUND24;                           \
    MLD_XSTOREST_MULT(state1, state2);              \
  } while (0)


#endif /* !MLD_FIPS202_NATIVE_PPC64LE_SRC_MACROS_H */
