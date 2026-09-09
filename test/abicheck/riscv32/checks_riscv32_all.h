/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */


#ifndef MLD_TEST_ABICHECK_CHECKS_RISCV32_ALL_H
#define MLD_TEST_ABICHECK_CHECKS_RISCV32_ALL_H

#include <stddef.h>
#include "../abicheck_common.h"

#if defined(MLD_SYS_RISCV32)

int check_intt_rv32im_asm(void);
int check_ntt_rv32im_asm(void);
int check_poly_pointwise_montgomery_rv32im_asm(void);

static const abicheck_entry_t all_checks[] = {
    {"intt_rv32im_asm", check_intt_rv32im_asm},
    {"ntt_rv32im_asm", check_ntt_rv32im_asm},
    {"poly_pointwise_montgomery_rv32im_asm",
     check_poly_pointwise_montgomery_rv32im_asm},
    {NULL, NULL} /* Sentinel */
};

#endif /* MLD_SYS_RISCV32 */

#endif /* !MLD_TEST_ABICHECK_CHECKS_RISCV32_ALL_H */
