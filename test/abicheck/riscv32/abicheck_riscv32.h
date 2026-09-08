/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_TEST_ABICHECK_ABICHECK_RISCV32_H
#define MLD_TEST_ABICHECK_ABICHECK_RISCV32_H

#include "../abicheck_common.h"

#if defined(MLD_SYS_RISCV32)

/*
 * Integer register state indexed by architectural register number x0..x31.
 * The call stub seeds the argument registers, the reserved gp/tp registers,
 * and the callee-saved registers. It captures gp/tp and the callee-saved set
 * after the call.
 */
struct riscv32_register_state
{
  uint32_t gpr[32];
};

int check_riscv32_ilp32_compliance(struct riscv32_register_state *before,
                                   struct riscv32_register_state *after,
                                   int quiet);
void init_riscv32_register_state(struct riscv32_register_state *state);

extern void asm_call_stub_riscv32(struct riscv32_register_state *input,
                                  struct riscv32_register_state *output,
                                  void (*function_ptr)(void));

static MLD_INLINE void call_stub_riscv32(struct riscv32_register_state *input,
                                         struct riscv32_register_state *output,
                                         void (*function_ptr)(void))
{
  asm_call_stub_riscv32(input, output, function_ptr);
}

#endif /* MLD_SYS_RISCV32 */

#endif /* !MLD_TEST_ABICHECK_ABICHECK_RISCV32_H */
