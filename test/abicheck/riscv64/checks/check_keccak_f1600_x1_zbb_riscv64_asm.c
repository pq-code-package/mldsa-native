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

#include "../abicheck_riscv64.h"
#include "../checks_riscv64_all.h"

#if defined(MLD_SYS_RISCV64) && defined(__riscv_zbb)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct riscv64_register_state reg_state;

void mld_keccak_f1600_x1_zbb_riscv64_asm(uint64_t state[25],
                                         const uint64_t rc[24]);

int check_keccak_f1600_x1_zbb_riscv64_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_a0[200]; /* Keccak state (25 x uint64_t) */
  MLD_ALIGN uint8_t buf_a1[192]; /* Round constants (24 x uint64_t) */

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_riscv64_register_state(&input_state);

    randombytes(buf_a0, 200);
    randombytes(buf_a1, 192);

    /* Set up register state for function arguments */
    input_state.gpr[10] = (uint64_t)buf_a0;
    input_state.gpr[11] = (uint64_t)buf_a1;

    /* Call function through ABI test stub */
    asm_call_stub_riscv64(&input_state, &output_state,
                          (void (*)(void))mld_keccak_f1600_x1_zbb_riscv64_asm);

    /* Check ABI compliance */
    violations = check_riscv64_lp64d_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for keccak_f1600_x1_zbb_riscv64_asm (iteration "
              "%d): %d violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_RISCV64 && __riscv_zbb */
