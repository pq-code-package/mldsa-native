/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#if defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

/*
 * Each corrupter inverts one ILP32 reserved or callee-saved register. The
 * checker must report exactly one violation for each corrupter and none for
 * the no-op.
 */

.text
.balign 4

.global selftest_riscv32_noop
.type selftest_riscv32_noop, @function
selftest_riscv32_noop:
        ret

.macro define_corrupter name, reg
.global \name
.type \name, @function
\name:
        xori \reg, \reg, -1
        ret
.endm

define_corrupter selftest_riscv32_corrupt_s0, s0
define_corrupter selftest_riscv32_corrupt_s1, s1
define_corrupter selftest_riscv32_corrupt_s2, s2
define_corrupter selftest_riscv32_corrupt_s3, s3
define_corrupter selftest_riscv32_corrupt_s4, s4
define_corrupter selftest_riscv32_corrupt_s5, s5
define_corrupter selftest_riscv32_corrupt_s6, s6
define_corrupter selftest_riscv32_corrupt_s7, s7
define_corrupter selftest_riscv32_corrupt_s8, s8
define_corrupter selftest_riscv32_corrupt_s9, s9
define_corrupter selftest_riscv32_corrupt_s10, s10
define_corrupter selftest_riscv32_corrupt_s11, s11
define_corrupter selftest_riscv32_corrupt_gp, gp
define_corrupter selftest_riscv32_corrupt_tp, tp
