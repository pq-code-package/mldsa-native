/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
/*yaml
  Name: poly_chknorm_aarch64_asm
  Description: AArch64 infinity-norm bound check on polynomial coefficients
  Signature: int mld_poly_chknorm_aarch64_asm(const int32_t *a, int32_t B)
  ABI:
    Architecture: aarch64
    CallingConvention: AAPCS64
    x0:
      type: buffer
      size_bytes: 1024
      permissions: read-only
      c_parameter: const int32_t *a
      description: Input polynomial (256 x int32_t)
    x1:
      type: scalar
      c_parameter: int32_t B
      description: Norm bound
      test_with: 131072  # representative non-negative bound (1 << 17)
*/

#include "../../../common.h"

#if defined(MLD_ARITH_BACKEND_AARCH64) && !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

.macro chknorm a
        abs \a\().4s, \a\().4s
        cmge \a\().4s, \a\().4s, bound.4s
        orr flags.16b, flags.16b, \a\().16b
.endm

        /* Parameters */
        a_ptr           .req x0     // Input polynomial
        B               .req w1     // Input norm bound

        count           .req x2

        /* Constant register assignments */
        bound           .req v20
        flags           .req v21

.text
.global MLD_ASM_NAMESPACE(poly_chknorm_aarch64_asm)
.balign 4
MLD_ASM_FN_SYMBOL(poly_chknorm_aarch64_asm)
        // Load constants
        dup bound.4s, B

        movi flags.4s, 0

        mov count, #(64/4)

poly_chknorm_loop:
        ldr q1, [a_ptr, #1*16]
        ldr q2, [a_ptr, #2*16]
        ldr q3, [a_ptr, #3*16]
        ldr q0, [a_ptr], #4*16

        chknorm v1
        chknorm v2
        chknorm v3
        chknorm v0

        subs count, count, #1
        bne poly_chknorm_loop

        // Return 1 if any of the 4 lanes is 0xffffffff
        umaxv s21, flags.4s
        fmov w0, s21
        and w0, w0, #1

        ret

        .unreq a_ptr
        .unreq B
        .unreq count
        .unreq bound
        .unreq flags
/* simpasm: footer-start */
#endif /* MLD_ARITH_BACKEND_AARCH64 && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
