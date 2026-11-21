/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*************************************************
 * Shared implementation body for PPC64LE poly_pointwise_montgomery
 *
 * This file contains the common pointwise Montgomery multiplication
 * implementation that is instantiated for both POWER8/9 and POWER10.
 *
 * The includer must define MLD_POINTWISE_SUFFIX before including this file:
 *   - For POWER8/9: #define MLD_POINTWISE_SUFFIX p8p9
 *   - For POWER10:  #define MLD_POINTWISE_SUFFIX p10
 *
 * This approach eliminates code duplication while preserving architecture-
 * specific optimizations (different vector multiply-high implementations).
 **************************************************/

#ifndef MLD_POINTWISE_SUFFIX
#error "MLD_POINTWISE_SUFFIX must be defined before including poly_pointwise_montgomery_ppc64le_impl.inc"
#endif

/* Macro concatenation helpers */
#define MLD_POINTWISE_CONCAT_INNER(a, b) a##_##b
#define MLD_POINTWISE_CONCAT(a, b) MLD_POINTWISE_CONCAT_INNER(a, b)
#define MLD_POINTWISE_CONCAT3_INNER(a, b, c) a##_##b##_##c
#define MLD_POINTWISE_CONCAT3(a, b, c) MLD_POINTWISE_CONCAT3_INNER(a, b, c)

/* Generate architecture-specific function and macro names */
#define MLD_POINTWISE_FUNC(name) MLD_POINTWISE_CONCAT3(name, MLD_POINTWISE_SUFFIX, ppc64le)
#define MLD_POINT_MUL MLD_POINTWISE_CONCAT(mld_point_mul, MLD_POINTWISE_SUFFIX)

/******************************************************************************************************
 Standard Montgomery reduction requires 64-bit intermediate values:
   (int64_t) a = z * r                          // a = a1 * 2^32 + a0
   (int32_t) m0 = (int32_t)a * QINV             // m0 = (M - m1 * 2^32)
   (int64_t) t1 = (int64_t)m0 * Q
   (int64_t) t2 = a - t1
   (int32_t) t = t2 >> 32                       // Final result

 Claim: low-order 32 bits of t2 are Zero:
   Q * QINV = 0x1_BFA0_0000_0001 = k * 2^32 + 1
   D1(96) = M * Q = a0 * QINV * Q = a0 * (k * 2^32 +1)
   t1(64) =  m0 * Q =  (M – m1 * 2^32) * Q = D1 – m1 * Q * 2^32 = a0 + 2^32 ( a0 * k – m1 * Q)
   T2(64) = a - t1 = a1 * 2^32 + a0 – (a0 + 2^32 ( a0 * k – m1 * Q)) = 2^32 (a1 + m1 * Q – a0 * k)

 Thus, t can be computed by just subtracting the high part of a and t1.
 With mul-high, mul-low SIMD instructions (like In PPC64), that allows for more efficient SIMD code.

 PPC64 Code:
   A0 = mul_low (z, r)
   A1 = mul_high(z, r)
   M0 = mul_low(A0, QINV)
   T1 = mul_high(M0, Q)
   T = A1 – T1
 *******************************************************************************************************/

/********************************************************************************************************
 * mld_poly_pointwise_montgomery_ppc64le: Pointwise polynomial multiplication with Montgomery reduction
 *
 * computes a[i] = a[i] * b[i] * R^-1 mod Q for all i in [0, MLDSA_N-1]
 * where R = 2^32 is the Montgomery constant.
 *
 * This is an IN-PLACE operation: the result is written back into the first argument 'a'.
 *
 * strategy:
 * - process 4 coefficients per vector (VINT32_WIDTH = 4)
 * - unroll loop 8x to process 32 coefficients per iteration
 * - use point_mul macro for optimized Montgomery multiplication
 * - utilize PPC64LE mul-high/mul-low instructions for efficiency
 *
 * ->Processes MLDSA_N coefficients in MLDSA_N/32 iterations
 *
 * a: input/output polynomial (MLDSA_N coefficients) - destructive operation
 * b: second input polynomial (MLDSA_N coefficients) - read-only
 ********************************************************************************************************/
void MLD_POINTWISE_FUNC(mld_poly_pointwise_montgomery)(int32_t *a, const int32_t *b)
{
    unsigned int vec_idx;
    __vector signed int vt1, vt2;

    /* Note: 'a' is both input and output, so no restrict qualifier.
     * 'b' is read-only, so restrict is safe. */
    __vector signed int *vec_poly_a = (__vector signed int *)a;
    const __vector signed int * restrict vec_poly_b = (const __vector signed int *)b;

    const unsigned int num_of_vecs = MLDSA_N / MLD_VINT32_WIDTH;

    /* Process 8 vectors per iteration */
    for (vec_idx = 0; vec_idx < num_of_vecs; vec_idx += 8) {
        /*  load 8 vectors from each input polynomial (32 coeff each) */
        __vector signed int ina0 = vec_poly_a[vec_idx+0], inb0 = vec_poly_b[vec_idx+0];
        __vector signed int ina1 = vec_poly_a[vec_idx+1], inb1 = vec_poly_b[vec_idx+1];
        __vector signed int ina2 = vec_poly_a[vec_idx+2], inb2 = vec_poly_b[vec_idx+2];
        __vector signed int ina3 = vec_poly_a[vec_idx+3], inb3 = vec_poly_b[vec_idx+3];
        __vector signed int ina4 = vec_poly_a[vec_idx+4], inb4 = vec_poly_b[vec_idx+4];
        __vector signed int ina5 = vec_poly_a[vec_idx+5], inb5 = vec_poly_b[vec_idx+5];
        __vector signed int ina6 = vec_poly_a[vec_idx+6], inb6 = vec_poly_b[vec_idx+6];
        __vector signed int ina7 = vec_poly_a[vec_idx+7], inb7 = vec_poly_b[vec_idx+7];

        /* compute Montgomery multiplication for all 8 vectors
         * point_mul macro performs: result = a * b * R^-1 mod Q
         * w/ mul-high/mul-low sequence */
        __vector signed int inc0, inc1, inc2, inc3, inc4, inc5, inc6, inc7;
        MLD_POINT_MUL(inc0, ina0, inb0, vt1, vt2);
        MLD_POINT_MUL(inc1, ina1, inb1, vt1, vt2);
        MLD_POINT_MUL(inc2, ina2, inb2, vt1, vt2);
        MLD_POINT_MUL(inc3, ina3, inb3, vt1, vt2);
        MLD_POINT_MUL(inc4, ina4, inb4, vt1, vt2);
        MLD_POINT_MUL(inc5, ina5, inb5, vt1, vt2);
        MLD_POINT_MUL(inc6, ina6, inb6, vt1, vt2);
        MLD_POINT_MUL(inc7, ina7, inb7, vt1, vt2);

        /* store all 8 result vectors back into 'a' (in-place) */
        vec_poly_a[vec_idx+0] = inc0;
        vec_poly_a[vec_idx+1] = inc1;
        vec_poly_a[vec_idx+2] = inc2;
        vec_poly_a[vec_idx+3] = inc3;
        vec_poly_a[vec_idx+4] = inc4;
        vec_poly_a[vec_idx+5] = inc5;
        vec_poly_a[vec_idx+6] = inc6;
        vec_poly_a[vec_idx+7] = inc7;
    }
}

/* Undefine macros to allow re-inclusion with different suffix */
#undef MLD_POINTWISE_SUFFIX
#undef MLD_POINTWISE_CONCAT_INNER
#undef MLD_POINTWISE_CONCAT
#undef MLD_POINTWISE_FUNC
#undef MLD_POINT_MUL
