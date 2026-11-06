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

#if defined(MLD_SYS_RISCV64) && defined(MLD_SYS_RISCV64_RVV)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct riscv64_register_state reg_state;

void mld_intt_vlen256_riscv64_asm(int32_t p[256], const int32_t zetas[512]);

int check_intt_vlen256_riscv64_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_a0[1024]; /* Input/output polynomial */
  MLD_ALIGN uint8_t buf_a1[2048]; /* Twiddle table (mld_rv64v_intt_zetas) */

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_riscv64_register_state(&input_state);

    randombytes(buf_a0, 1024);
    randombytes(buf_a1, 2048);

    /* Set up register state for function arguments */
    input_state.gpr[10] = (uint64_t)buf_a0;
    input_state.gpr[11] = (uint64_t)buf_a1;

    /* Call function through ABI test stub */
    asm_call_stub_riscv64(&input_state, &output_state,
                          (void (*)(void))mld_intt_vlen256_riscv64_asm);

    /* Check ABI compliance */
    violations = check_riscv64_lp64d_compliance(&input_state, &output_state,
                                                MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for intt_vlen256_riscv64_asm (iteration %d): %d "
              "violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_RISCV64 && MLD_SYS_RISCV64_RVV */
