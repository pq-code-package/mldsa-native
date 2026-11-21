/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_PPC64LE_SRC_MACROS_H
#define MLD_NATIVE_PPC64LE_SRC_MACROS_H

#include <altivec.h>
#include "../../../params.h"

/* MLD_VCONST: Create a 64-bit vector with both lanes set to the same value
 * Example: VCONST(5) creates {5, 5} */
#define MLD_VCONST(n) ((__vector uint64_t){n, n})
/* MLD_VINT32_WIDTH: Number of 32-bit integers that fit in one 128-bit vector
 * register PowerPC vectors are 128 bits = 4 × 32-bit integers */
/* check-magic: 4 == 128 / 32 */
#define MLD_VINT32_WIDTH 4
/* MLD_QINV: Modular inverse of Q modulo 2^32, used in Montgomery reduction
 * Precomputed: q^(-1) mod 2^32 = 58728449 */
/* check-magic: 58728449 == unsigned_mod(pow(MLDSA_Q, -1, 2^32), 2^32) */
#define MLD_QINV 58728449 /* q^(-1) mod 2^32 */
/* MLD_V0: Zero vector with both 64-bit lanes set to 0 */
#define MLD_V0 ((__vector uint64_t){0, 0})
/* MLD_V1: Vector with both 64-bit lanes set to 1 (used for bit rotations) */
#define MLD_V1 ((__vector uint64_t){1, 1})
/* MLD_VQINV4: Vector with all 4 lanes set to QINV
 * Used for Montgomery reduction on 4 coefficients simultaneously */
#define MLD_VQINV4 \
  ((__vector signed int){MLD_QINV, MLD_QINV, MLD_QINV, MLD_QINV})
/* MLD_VQ4: Vector with all 4 lanes set to Q (the modulus)
 * Used for modular reduction on 4 coefficients simultaneously */
#define MLD_VQ4 ((__vector signed int){MLDSA_Q, MLDSA_Q, MLDSA_Q, MLDSA_Q})
/* MLD_VPERM: Permutation mask for extracting high 32 bits from multiplication
 * results */
#define MLD_VPERM                                                           \
  ((__vector unsigned char){0x04, 0x05, 0x06, 0x07, 0x14, 0x15, 0x16, 0x17, \
                            0x0C, 0x0D, 0x0E, 0x0F, 0x1C, 0x1D, 0x1E, 0x1F})

/*
 * PPC64LE SIMD Macros for ML-DSA Arithmetic Operations
 *
 * ARCHITECTURAL REQUIREMENTS:
 * ---------------------------
 * Baseline: POWER8+ (ppc64le architecture)
 *   - AltiVec/VSX SIMD instructions (guaranteed on all ppc64le systems)
 *   - 128-bit vector registers
 *   - Basic vector arithmetic operations
 *
 * Optimizations: POWER10+ (optional, runtime detected)
 *   - vmulhsw instruction for efficient signed high-word multiplication
 *   - Provides better performance than POWER8/9 fallback
 *
 * RUNTIME DISPATCH MECHANISM:
 * ---------------------------
 * This implementation uses runtime capability detection to select the optimal
 * code path based on available hardware features, not processor generation.
 *
 * Two separate NTT implementations are provided:
 *   1. P10 path: Uses vmulhsw instruction (single instruction for mulh)
 *   2. P8/P9 path: Uses vec_mule/vec_mulo + vec_perm (3 instructions for mulh)
 *
 * Selection is made at runtime via
 * mld_sys_check_capability(MLD_SYS_CAP_POWER10) which checks the Linux
 * auxiliary vector (getauxval) for PPC_FEATURE2_ARCH_3_1.
 *
 * This differs from the AVX model: instead of falling back to generic C when
 * P10 is unavailable, we fall back to the P8/P9-optimized SIMD path, which
 * still provides significant performance benefits over scalar code.
 *
 * FALLBACK MECHANISM:
 * -------------------
 * mld_vec_mulh (Vector Multiply High):
 *   - POWER10: Uses native vmulhsw instruction (single instruction)
 *   - POWER8/9: Emulates using vec_mule/vec_mulo + vec_perm (3 instructions)
 *
 *   The fallback computes high 32 bits of 32x32→64 bit multiplication:
 *     1. vec_mule: Multiply even elements (lanes 0,2)
 *     2. vec_mulo: Multiply odd elements (lanes 1,3)
 *     3. vec_perm: Permute to extract high words and interleave results
 *
 *   Both implementations produce identical results; POWER10 is faster.
 */

/*
 * mld_vec_mulh_p10: POWER10 optimized signed high-word multiplication
 *
 * Uses vmulhsw instruction to compute high 32 bits of (a * b) for each lane.
 * Available on: POWER10+
 * Performance: 1 instruction per operation
 */
#define mld_vec_mulh_p10(t, a, b)                          \
  __asm volatile("       vmulhsw %[res], %[arg1], %[arg2]" \
                 : [res] "=v"(t)                           \
                 : [arg1] "v"(a), [arg2] "v"(b));

/*
 * mld_vec_mulh_p8p9: POWER8/9 compatible signed high-word multiplication
 *
 * Emulates vmulhsw using vec_mule, vec_mulo, and vec_perm.
 * Process:
 *   1. vec_mule: Multiply even lanes (0,2) → 64-bit results
 *   2. vec_mulo: Multiply odd lanes (1,3) → 64-bit results
 *   3. vec_perm: Extract high 32 bits and interleave into result vector
 *
 * Available on: POWER8+
 * Performance: 3 instructions per operation
 * Correctness: Produces identical results to POWER10 vmulhsw
 */

#define mld_vec_mulh_p8p9(t, a, b)                                          \
  t = (__vector signed int)vec_perm((__vector unsigned char)vec_mule(a, b), \
                                    (__vector unsigned char)vec_mulo(a, b), \
                                    MLD_VPERM);

/* mld_vec_mul: Vector multiply low (32-bit × 32-bit → low 32 bits)
 *
 * Inline assembly wrapper for vmuluwm instruction
 * Multiplies 4 pairs of 32-bit integers in parallel, keeping only low 32 bits
 *
 * Operation per lane: t[i] = (a[i] * b[i]) & 0xFFFFFFFF
 *
 * Parameters:
 *   t - output vector (receives low 32 bits of each multiplication)
 *   a - first input vector (4 × int32_t)
 *   b - second input vector (4 × int32_t)
 *
 * Example: a={10,20,30,40}, b={2,3,4,5} → t={20,60,120,200}
 */
#define mld_vec_mul(t, a, b)                               \
  __asm volatile("       vmuluwm %[res], %[arg1], %[arg2]" \
                 : [res] "=v"(t)                           \
                 : [arg1] "v"(a), [arg2] "v"(b));

/* mld_point_mul_p10: Pointwise Montgomery multiplication (POWER10 version)
 *
 * Computes Montgomery multiplication: c = (a * b * R^-1) mod Q for 4 elements
 * where R = 2^32 (Montgomery constant)
 *
 * Algorithm (per lane):
 *   1. Compute full product: a * b (64-bit result split into high/low 32 bits)
 *   2. Montgomery reduction to bring result back to (-Q, Q)
 *
 * Montgomery reduction steps:
 *   1. low = (a * b) & 0xFFFFFFFF          [vec_mul: low 32 bits]
 *   2. high = (a * b) >> 32                [vec_mulh_p10: high 32 bits]
 *   3. m = low * QINV                      [vec_mul: compute correction]
 *   4. t = m * Q >> 32                     [vec_mulh_p10: apply correction]
 *   5. result = high - t                   [subtract to get final value]
 *
 * All operations process 4 coefficients simultaneously using SIMD
 *
 * Parameters:
 *   c - output vector (4 Montgomery-reduced products)
 *   a - first input vector (4 coefficients)
 *   b - second input vector (4 coefficients)
 *   vt1 - temporary vector for intermediate results
 *   vt2 - temporary vector for intermediate results
 */
#define mld_point_mul_p10(c, a, b, vt1, vt2) \
  mld_vec_mul(vt1, a, b);                    \
  mld_vec_mulh_p10(vt2, a, b);               \
  mld_vec_mul(vt1, vt1, MLD_VQINV4);         \
  mld_vec_mulh_p10(vt1, vt1, MLD_VQ4);       \
  c = vt2 - vt1;

/* mld_point_mul_p8p9: Pointwise Montgomery multiplication (POWER8/9 version)
 *
 * Same algorithm as point_mul_p10, but uses vec_mulh_p8p9 instead of
 * vec_mulh_p10
 *
 * Parameters:
 *   c - output vector (4 Montgomery-reduced products)
 *   a - first input vector (4 coefficients)
 *   b - second input vector (4 coefficients)
 *   vt1 - temporary vector for intermediate results
 *   vt2 - temporary vector for intermediate results
 */
#define mld_point_mul_p8p9(c, a, b, vt1, vt2) \
  mld_vec_mul(vt1, a, b);                     \
  mld_vec_mulh_p8p9(vt2, a, b);               \
  mld_vec_mul(vt1, vt1, MLD_VQINV4);          \
  mld_vec_mulh_p8p9(vt1, vt1, MLD_VQ4);       \
  c = vt2 - vt1;

/* mld_butterfly_p10: Forward butterfly operation with Montgomery multiplication
 * (POWER10 version)
 *
 * Core operation in forward NTT, processes 4 coefficient pairs simultaneously
 *
 * Algorithm (per lane):
 *   temp = rjlen * vzeta (Montgomery multiplication)
 *   rjlen = rj - temp     (difference)
 *   rj = rj + temp        (sum)
 *
 * Parameters:
 *   rj     - first coefficient vector (updated to sum)
 *   rjlen  - second coefficient vector (updated to difference)
 *   vzeta  - zeta constant vector (4 copies of same value)
 *   vt1    - temporary vector for intermediate results
 *   vt2    - temporary vector for intermediate results
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4    - vector constant with Q in all lanes
 */
#define mld_butterfly_p10(rj, rjlen, vzeta, vt1, vt2, _qinvx4, _qx4) \
  vt1 = rjlen * vzeta;                                               \
  mld_vec_mulh_p10(vt2, rjlen, vzeta);                               \
  mld_vec_mul(vt1, vt1, _qinvx4);                                    \
  mld_vec_mulh_p10(vt1, vt1, _qx4);                                  \
  vt1 = vt2 - vt1;                                                   \
  rjlen = rj - vt1;                                                  \
  rj = rj + vt1;

/* mld_butterfly_p8p9: Forward butterfly operation with Montgomery
 * multiplication (POWER8/9 version)
 *
 * Same algorithm as butterfly_p10, but uses vec_mulh_p8p9 instead of
 * vec_mulh_p10
 *
 * Parameters:
 *   rj     - first coefficient vector (updated to sum)
 *   rjlen  - second coefficient vector (updated to difference)
 *   vzeta  - zeta constant vector (4 copies of same value)
 *   vt1    - temporary vector for intermediate results
 *   vt2    - temporary vector for intermediate results
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4    - vector constant with Q in all lanes
 */
#define mld_butterfly_p8p9(rj, rjlen, vzeta, vt1, vt2, _qinvx4, _qx4) \
  vt1 = rjlen * vzeta;                                                \
  mld_vec_mulh_p8p9(vt2, rjlen, vzeta);                               \
  mld_vec_mul(vt1, vt1, _qinvx4);                                     \
  mld_vec_mulh_p8p9(vt1, vt1, _qx4);                                  \
  vt1 = vt2 - vt1;                                                    \
  rjlen = rj - vt1;                                                   \
  rj = rj + vt1;

/* mld_butterfly_inv_p10: Inverse butterfly operation with Montgomery
 * multiplication (POWER10 version)
 *
 * Core operation in inverse NTT, processes 4 coefficient pairs simultaneously
 * Inverse of the forward butterfly operation
 *
 * Algorithm (per lane):
 *   temp = rj
 *   rj = temp + rjlen
 *   rjlen = (temp - rjlen) * vzeta (difference then multiply)
 *
 * Parameters:
 *   rj     - first coefficient vector (updated to sum)
 *   rjlen  - second coefficient vector (updated to difference * zeta)
 *   vzeta  - zeta constant vector (4 copies of same value)
 *   vt1    - temporary vector for intermediate results
 *   vt2    - temporary vector for intermediate results
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4    - vector constant with Q in all lanes
 */
#define mld_butterfly_inv_p10(rj, rjlen, vzeta, vt1, vt2, _qinvx4, _qx4) \
  vt1 = rj;                                                              \
  rj = vt1 + rjlen;                                                      \
  rjlen = vt1 - rjlen;                                                   \
                                                                         \
  vt1 = rjlen * vzeta;                                                   \
  mld_vec_mulh_p10(vt2, rjlen, vzeta);                                   \
  mld_vec_mul(vt1, vt1, _qinvx4);                                        \
  mld_vec_mulh_p10(vt1, vt1, _qx4);                                      \
  rjlen = vt2 - vt1;

/* mld_butterfly_inv_p8p9: Inverse butterfly operation with Montgomery
 * multiplication (POWER8/9 version)
 *
 * Same algorithm as mld_butterfly_inv_p10, but uses vec_mulh_p8p9 instead of
 * vec_mulh_p10
 *
 * Parameters:
 *   rj     - first coefficient vector (updated to sum)
 *   rjlen  - second coefficient vector (updated to difference * zeta)
 *   vzeta  - zeta constant vector (4 copies of same value)
 *   vt1    - temporary vector for intermediate results
 *   vt2    - temporary vector for intermediate results
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4    - vector constant with Q in all lanes
 */
#define mld_butterfly_inv_p8p9(rj, rjlen, vzeta, vt1, vt2, _qinvx4, _qx4) \
  vt1 = rj;                                                               \
  rj = vt1 + rjlen;                                                       \
  rjlen = vt1 - rjlen;                                                    \
                                                                          \
  vt1 = rjlen * vzeta;                                                    \
  mld_vec_mulh_p8p9(vt2, rjlen, vzeta);                                   \
  mld_vec_mul(vt1, vt1, _qinvx4);                                         \
  mld_vec_mulh_p8p9(vt1, vt1, _qx4);                                      \
  rjlen = vt2 - vt1;

/* mld_monty_red_f_star_p10: Montgomery reduction with scaling factor (POWER10
 * version)
 *
 * Applies Montgomery reduction while multiplying by factor f = mont^2/256
 * Used at the end of inverse NTT
 *
 * Montgomery reduction steps:
 *   1. low = (f * vt3) & 0xFFFFFFFF     [low 32 bits]
 *   2. high = (f * vt3) >> 32           [high 32 bits]
 *   3. m = low * QINV
 *   4. t = m * Q >> 32
 *   5. vt3 = high - t
 *
 * Parameters:
 *   vt3 - input/output vector (4 coefficients to reduce)
 *   vt1 - temporary vector for intermediate results
 *   vt2 - temporary vector for intermediate results
 *   f - scaling factor vector (mont^2/256 in all lanes)
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4 - vector constant with Q in all lanes
 */
#define mld_monty_red_f_star_p10(vt3, vt1, vt2, f, _qinvx4, _qx4) \
  vt1 = f * vt3;                                                  \
  mld_vec_mulh_p10(vt2, f, vt3);                                  \
  mld_vec_mul(vt1, vt1, _qinvx4);                                 \
  mld_vec_mulh_p10(vt1, vt1, _qx4);                               \
  vt3 = vt2 - vt1;

/* mld_monty_red_f_star_p8p9: Montgomery reduction with scaling factor (POWER8/9
 * version)
 *
 * Same algorithm as monty_red_f_star_p10, but uses vec_mulh_p8p9 instead of
 * vec_mulh_p10
 *
 * Parameters:
 *   vt3 - input/output vector (4 coefficients to reduce)
 *   vt1 - temporary vector for intermediate results
 *   vt2 - temporary vector for intermediate results
 *   f - scaling factor vector (mont^2/256 in all lanes)
 *   _qinvx4 - vector constant with QINV in all lanes
 *   _qx4 - vector constant with Q in all lanes
 */
#define mld_monty_red_f_star_p8p9(vt3, vt1, vt2, f, _qinvx4, _qx4) \
  vt1 = f * vt3;                                                   \
  mld_vec_mulh_p8p9(vt2, f, vt3);                                  \
  mld_vec_mul(vt1, vt1, _qinvx4);                                  \
  mld_vec_mulh_p8p9(vt1, vt1, _qx4);                               \
  vt3 = vt2 - vt1;

#endif /* !MLD_NATIVE_PPC64LE_SRC_MACROS_H */
