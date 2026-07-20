/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */

#include <stdio.h>

#include "../abicheck_aarch64.h"
#include "../checks_aarch64_all.h"

#if defined(MLD_SYS_AARCH64) && defined(__ARM_FEATURE_SHA3)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct aarch64_register_state reg_state;

void mld_keccak_f1600_x2_v84a_aarch64_asm(uint64_t state[50],
                                          const uint64_t rc[24]);

int check_keccak_f1600_x2_v84a_aarch64_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t
      buf_x0[400]; /* Two sequential Keccak states (state0[25], state1[25]) */
  MLD_ALIGN uint8_t buf_x1[192]; /* Round constants (24 x uint64_t) */

  if (!mld_sys_check_capability(MLD_SYS_CAP_AARCH64_NEON))
  {
    fprintf(stderr,
            "ABI check keccak_f1600_x2_v84a_aarch64_asm: host lacks AArch64 "
            "NEON, skipping\n");
    return MLD_ABICHECK_SKIPPED;
  }

  if (!mld_sys_check_capability(MLD_SYS_CAP_AARCH64_SHA3))
  {
    fprintf(stderr,
            "ABI check keccak_f1600_x2_v84a_aarch64_asm: host lacks Armv8.4-A "
            "SHA3 (eor3, rax1, xar, bcax), skipping\n");
    return MLD_ABICHECK_SKIPPED;
  }

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_aarch64_register_state(&input_state);

    randombytes(buf_x0, 400);
    randombytes(buf_x1, 192);

    /* Set up register state for function arguments */
    input_state.gpr[0] = (uint64_t)buf_x0;
    input_state.gpr[1] = (uint64_t)buf_x1;

    /* Call function through ABI test stub */
    call_stub_aarch64(&input_state, &output_state,
                      (void (*)(void))mld_keccak_f1600_x2_v84a_aarch64_asm);

    /* Check ABI compliance */
    violations = check_aarch64_aapcs_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for keccak_f1600_x2_v84a_aarch64_asm (iteration "
              "%d): %d violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_AARCH64 && __ARM_FEATURE_SHA3 */
