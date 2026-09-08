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

#include "../abicheck_riscv32.h"
#include "../checks_riscv32_all.h"

#if defined(MLD_SYS_RISCV32)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct riscv32_register_state reg_state;

void mld_intt_rv32im_asm(int32_t r[256], const int32_t zetas[510]);

int check_intt_rv32im_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_a0[1024]; /* Input/output polynomial (256 x int32_t) */
  MLD_ALIGN uint8_t
      buf_a1[2040]; /* Forward-NTT twiddle table reused in reverse */

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_riscv32_register_state(&input_state);

    randombytes(buf_a0, 1024);
    randombytes(buf_a1, 2040);

    /* Set up register state for function arguments */
    input_state.gpr[10] = (uint32_t)buf_a0;
    input_state.gpr[11] = (uint32_t)buf_a1;

    /* Call function through ABI test stub */
    call_stub_riscv32(&input_state, &output_state,
                      (void (*)(void))mld_intt_rv32im_asm);

    /* Check ABI compliance */
    violations = check_riscv32_ilp32_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(
          stderr,
          "ABI test FAILED for intt_rv32im_asm (iteration %d): %d violations\n",
          test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_RISCV32 */
