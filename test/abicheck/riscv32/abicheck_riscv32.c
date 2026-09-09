/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Reference:
 *
 * - RISC-V ABIs Specification, "Integer Calling Convention"
 */

#include <stdio.h>

#include "../../notrandombytes/notrandombytes.h"
#include "abicheck_riscv32.h"

#if defined(MLD_SYS_RISCV32)

int check_riscv32_ilp32_compliance(struct riscv32_register_state *before,
                                   struct riscv32_register_state *after,
                                   int quiet)
{
  static const int callee_saved[] = {
      8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
  };
  int violations = 0;
  int i;

  if (before->gpr[3] != after->gpr[3])
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "gp");
    violations++;
  }
  if (before->gpr[4] != after->gpr[4])
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "tp");
    violations++;
  }

  for (i = 0; i < 12; i++)
  {
    int reg = callee_saved[i];
    if (before->gpr[reg] != after->gpr[reg])
    {
      if (reg == 8)
      {
        MLD_ABI_VIOLATION(quiet, "%s modified\n", "s0");
      }
      else if (reg == 9)
      {
        MLD_ABI_VIOLATION(quiet, "%s modified\n", "s1");
      }
      else
      {
        MLD_ABI_VIOLATION(quiet, "s%d modified\n", reg - 16);
      }
      violations++;
    }
  }

  return violations;
}

void init_riscv32_register_state(struct riscv32_register_state *state)
{
  randombytes((uint8_t *)state, sizeof(*state));
}

#endif /* MLD_SYS_RISCV32 */
