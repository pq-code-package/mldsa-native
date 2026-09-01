/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */


#ifndef MLD_TEST_ABICHECK_CHECKS_ARMV81M_ALL_H
#define MLD_TEST_ABICHECK_CHECKS_ARMV81M_ALL_H

#include <stddef.h>
#include "../abicheck_common.h"

#if defined(MLD_SYS_ARMV81M_MVE)

int check_keccak_f1600_x1_armv7m_asm(void);
int check_keccak_f1600_x1_state_extract_bytes_asm(void);
int check_keccak_f1600_x1_state_xor_bytes_asm(void);
#if defined(__ARM_FEATURE_MVE)
int check_keccak_f1600_x4_mve_asm(void);
#endif

static const abicheck_entry_t all_checks[] = {
    {"keccak_f1600_x1_armv7m_asm", check_keccak_f1600_x1_armv7m_asm},
    {"keccak_f1600_x1_state_extract_bytes_asm",
     check_keccak_f1600_x1_state_extract_bytes_asm},
    {"keccak_f1600_x1_state_xor_bytes_asm",
     check_keccak_f1600_x1_state_xor_bytes_asm},
#if defined(__ARM_FEATURE_MVE)
    {"keccak_f1600_x4_mve_asm", check_keccak_f1600_x4_mve_asm},
#endif
    {NULL, NULL} /* Sentinel */
};

#endif /* MLD_SYS_ARMV81M_MVE */

#endif /* !MLD_TEST_ABICHECK_CHECKS_ARMV81M_ALL_H */
