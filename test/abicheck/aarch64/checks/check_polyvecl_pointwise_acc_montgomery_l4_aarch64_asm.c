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

#if defined(MLD_SYS_AARCH64)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct aarch64_register_state reg_state;

void mld_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm(
    int32_t r[256], const int32_t a[4][256], const int32_t b[4][256]);

int check_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_x0[1024]; /* Output polynomial (256 x int32_t) */
  MLD_ALIGN uint8_t
      buf_x1[4096]; /* Input polynomial vector a (4 x 256 x int32_t) */
  MLD_ALIGN uint8_t
      buf_x2[4096]; /* Input polynomial vector b (4 x 256 x int32_t) */

  if (!mld_sys_check_capability(MLD_SYS_CAP_AARCH64_NEON))
  {
    fprintf(stderr,
            "ABI check polyvecl_pointwise_acc_montgomery_l4_aarch64_asm: host "
            "lacks AArch64 NEON, skipping\n");
    return MLD_ABICHECK_SKIPPED;
  }

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_aarch64_register_state(&input_state);

    randombytes(buf_x0, 1024);
    randombytes(buf_x1, 4096);
    randombytes(buf_x2, 4096);

    /* Set up register state for function arguments */
    input_state.gpr[0] = (uint64_t)buf_x0;
    input_state.gpr[1] = (uint64_t)buf_x1;
    input_state.gpr[2] = (uint64_t)buf_x2;

    /* Call function through ABI test stub */
    call_stub_aarch64(
        &input_state, &output_state,
        (void (*)(void))mld_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm);

    /* Check ABI compliance */
    violations = check_aarch64_aapcs_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for "
              "polyvecl_pointwise_acc_montgomery_l4_aarch64_asm (iteration "
              "%d): %d violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_AARCH64 */
