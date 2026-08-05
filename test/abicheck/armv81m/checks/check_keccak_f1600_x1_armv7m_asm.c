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

#include "../abicheck_armv81m.h"
#include "../checks_armv81m_all.h"

#if defined(MLD_SYS_ARMV81M_MVE)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct armv81m_register_state reg_state;

void mld_keccak_f1600_x1_armv7m_asm(uint32_t state[50], const uint32_t rc[49]);

int check_keccak_f1600_x1_armv7m_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_r0[200]; /* Bit-interleaved x1 state as even/odd 32-bit
                                    halves for each Keccak lane */
  MLD_ALIGN uint8_t buf_r1[196]; /* 24 bit-interleaved round constants followed
                                    by the 0xff loop terminator */

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_armv81m_register_state(&input_state);

    randombytes(buf_r0, 200);
    randombytes(buf_r1, 196);
    buf_r1[192] = 0xff;
    buf_r1[193] = 0x00;
    buf_r1[194] = 0x00;
    buf_r1[195] = 0x00;

    /* Set up register state for function arguments */
    input_state.gpr[0] = (uint32_t)buf_r0;
    input_state.gpr[1] = (uint32_t)buf_r1;

    /* Call function through ABI test stub */
    call_stub_armv81m(&input_state, &output_state,
                      (void (*)(void))mld_keccak_f1600_x1_armv7m_asm);

    /* Check ABI compliance */
    violations = check_armv81m_aapcs32_compliance(&input_state, &output_state,
                                                  MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(stderr,
              "ABI test FAILED for keccak_f1600_x1_armv7m_asm (iteration %d): "
              "%d violations\n",
              test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_ARMV81M_MVE */
