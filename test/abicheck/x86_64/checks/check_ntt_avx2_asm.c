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

#include "../abicheck_x86_64.h"
#include "../checks_x86_64_all.h"

#if defined(MLD_SYS_X86_64) && defined(MLD_SYSV_ABI_SUPPORTED) && \
    defined(__AVX2__)

#include "../../../notrandombytes/notrandombytes.h"

typedef struct x86_64_register_state reg_state;

MLD_SYSV_ABI
void mld_ntt_avx2_asm(int32_t *r, const int32_t *qdata);

int check_ntt_avx2_asm(void)
{
  int test_iter;
  reg_state input_state, output_state;
  int violations;
  MLD_ALIGN uint8_t buf_rdi[1024]; /* Input/output polynomial (256 x int32_t) */
  MLD_ALIGN uint8_t buf_rsi[2496]; /* Precomputed constants (624 x int32_t) */

  if (!mld_sys_check_capability(MLD_SYS_CAP_X86_64_AVX2))
  {
    fprintf(stderr, "ABI check ntt_avx2_asm: host lacks AVX2, skipping\n");
    return MLD_ABICHECK_SKIPPED;
  }

  for (test_iter = 0; test_iter < MLD_ABICHECK_NUM_TESTS; test_iter++)
  {
    /* Initialize random register state */
    init_x86_64_register_state(&input_state);

    randombytes(buf_rdi, 1024);
    randombytes(buf_rsi, 2496);

    /* Set up register state for function arguments */
    input_state.rdi = (uint64_t)buf_rdi;
    input_state.rsi = (uint64_t)buf_rsi;

    /* Call function through ABI test stub */
    call_stub_x86_64_sysv(
        &input_state, &output_state,
        (MLD_SYSV_ABI
         void (*)(void))mld_ntt_avx2_asm);

    /* Check ABI compliance */
    violations = check_x86_64_sysv_compliance(&input_state, &output_state,
                                              MLD_ABICHECK_VERBOSE);
    if (violations > 0)
    {
      fprintf(
          stderr,
          "ABI test FAILED for ntt_avx2_asm (iteration %d): %d violations\n",
          test_iter + 1, violations);
      return MLD_ABICHECK_FAILED;
    }
  }

  return MLD_ABICHECK_PASSED;
}

#endif /* MLD_SYS_X86_64 && MLD_SYSV_ABI_SUPPORTED && __AVX2__ */
