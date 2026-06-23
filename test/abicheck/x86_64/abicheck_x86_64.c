/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* References
 * ==========
 *
 * - [SysVAMD64]
 *   System V Application Binary Interface — AMD64 Architecture Processor
 *   Supplement
 *   Matz, Hubička, Jaeger, Mitchell
 *   https://gitlab.com/x86-psABIs/x86-64-ABI
 */

#include <stdio.h>

#include "../../notrandombytes/notrandombytes.h"
#include "abicheck_x86_64.h"

#if defined(MLD_SYS_X86_64) && defined(MLD_SYSV_ABI_SUPPORTED)

/* Callee-saved set per @[SysVAMD64, Section 3.2 "Function Calling Sequence"].
 */
int check_x86_64_sysv_compliance(struct x86_64_register_state *before,
                                 struct x86_64_register_state *after, int quiet)
{
  int violations = 0;

  if (before->rbx != after->rbx)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "rbx");
    violations++;
  }
  if (before->rbp != after->rbp)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "rbp");
    violations++;
  }
  if (before->r12 != after->r12)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "r12");
    violations++;
  }
  if (before->r13 != after->r13)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "r13");
    violations++;
  }
  if (before->r14 != after->r14)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "r14");
    violations++;
  }
  if (before->r15 != after->r15)
  {
    MLD_ABI_VIOLATION(quiet, "%s modified\n", "r15");
    violations++;
  }

  return violations;
}

void init_x86_64_register_state(struct x86_64_register_state *state)
{
  randombytes((uint8_t *)state, sizeof(*state));
}

#endif /* MLD_SYS_X86_64 && MLD_SYSV_ABI_SUPPORTED */
