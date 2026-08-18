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

#if defined(MLD_SYS_AARCH64) && defined(MLD_SYS_AARCH64_NEON)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct aarch64_register_state reg_state;

uint64_t mld_rej_uniform_eta4_aarch64_asm(int32_t r[256], const uint8_t *buf,
                                          unsigned buflen,
                                          const uint8_t table[4096]);

int check_rej_uniform_eta4_aarch64_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_x0[1024]; /* Output buffer (256 x int32_t) */
  MLD_ALIGN uint8_t buf_x1[272];  /* Input buffer */
  MLD_ALIGN uint8_t buf_x3[4096]; /* Lookup table (4096 x uint8_t) */

  if (!mld_sys_check_capability(MLD_SYS_CAP_AARCH64_NEON))
  {
    fprintf(stderr,
            "ABI check rej_uniform_eta4_aarch64_asm: host lacks AArch64 NEON, "
            "skipping\n");
    return MLD_ABICHECK_SKIPPED;
  }

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_aarch64_register_state(&input_state);

    randombytes(buf_x0, 1024);
    randombytes(buf_x1, 272);
    randombytes(buf_x3, 4096);

    /* Set up register state for function arguments */
    input_state.gpr[0] = (uint64_t)buf_x0;
    input_state.gpr[1] = (uint64_t)buf_x1;
    input_state.gpr[2] = 272;
    input_state.gpr[3] = (uint64_t)buf_x3;

    /* Call function through ABI test stub */
    call_stub_aarch64(&input_state, &output_state,
                      (void (*)(void))mld_rej_uniform_eta4_aarch64_asm);

    /* Check ABI compliance */
    violations = check_aarch64_aapcs_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for rej_uniform_eta4_aarch64_asm (iteration "
              "%d): %d violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_AARCH64 && MLD_SYS_AARCH64_NEON */
