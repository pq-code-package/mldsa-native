/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Meta-test for the ABI checker.
 *
 * For each supported architecture, this file iterates over a registry of
 * "corrupter" functions. Each corrupter is a tiny hand-written assembly
 * stub that violates the platform calling convention by clobbering exactly
 * one callee-saved register (without restoring it). We call each through
 * the architecture's call stub, run the matching check_*_compliance, and
 * assert the checker reports the expected violation count - that proves
 * the checker actually fires.
 *
 * The corrupter sources live in selftest_<arch>.S; the registry below maps
 * each one to a human-readable name. We do not assert *which* register was
 * flagged (that would require parsing stderr); strict-equal-count plus a
 * known-good no-op is sufficient to validate the checker's polarity, basic
 * plumbing, and that it doesn't over-count.
 *
 * If any selftest fails, abicheck.c bails before running the kernel
 * registry, on the principle that a broken checker's verdicts cannot be
 * trusted.
 */

#include <stdio.h>

#include "abicheck_common.h"
#include "selftest.h"

/* Per-arch register-state structs + declarations; each is guarded on its arch
 * macro, so only the active arch's definitions materialize. selftest.c
 * dispatches across all arches, so it pulls in every arch's header. */
#include "aarch64/abicheck_aarch64.h"
#include "armv81m/abicheck_armv81m.h"
#include "x86_64/abicheck_x86_64.h"

/* Shared registry shape: per-arch tables of (name, fn-ptr, expected count).
 * On x86_64 Windows-MinGW the corrupter symbols are MLD_SYSV_ABI; we store
 * them as plain void(*)(void) here and re-qualify with a cast at the call
 * site below, matching the per-kernel check_*.c pattern. */
typedef struct
{
  const char *name;
  void (*fn)(void);
  int expected_violations; /* 0 for noop, >=1 for corrupters */
} selftest_entry_t;

/* Run a per-arch selftest pass: iterate `entries`, for each call the stub
 * with a freshly-initialised input state, run the compliance check, and
 * count cases where the violation count doesn't match expectations
 * (catches both polarity flips and over-counting). */
#define SELFTEST_RUN_ARCH(arch_label, state_t, init_fn, stub_fn, check_fn,    \
                          entries, fn_cast)                                   \
  do                                                                          \
  {                                                                           \
    state_t input_state, output_state;                                        \
    const selftest_entry_t *e;                                                \
    for (e = (entries); e->name != NULL; e++)                                 \
    {                                                                         \
      int violations;                                                         \
      init_fn(&input_state);                                                  \
      stub_fn(&input_state, &output_state, fn_cast e->fn);                    \
      violations = check_fn(&input_state, &output_state, MLD_ABICHECK_QUIET); \
      if (violations != e->expected_violations)                               \
      {                                                                       \
        fprintf(stderr,                                                       \
                "selftest FAIL: " arch_label                                  \
                " %s: expected %d violations, got %d\n",                      \
                e->name, e->expected_violations, violations);                 \
        failures++;                                                           \
      }                                                                       \
    }                                                                         \
  } while (0)

#if defined(MLD_SYS_AARCH64)

/* Corrupter declarations. Defined in selftest_aarch64.S. */
extern void selftest_aarch64_noop(void);
/* x18 is the AArch64 platform register (Darwin-reserved, ELF-unused);
 * the call stub does not seed it on Apple, but we still verify that
 * kernels leave it alone. The corrupter is registered only on
 * non-Apple builds because on Darwin user code must not touch x18. */
#if !defined(__APPLE__)
extern void selftest_aarch64_corrupt_x18(void);
#endif
/* GPRs: callee-saved set is x19-x29. */
extern void selftest_aarch64_corrupt_x19(void);
extern void selftest_aarch64_corrupt_x20(void);
extern void selftest_aarch64_corrupt_x21(void);
extern void selftest_aarch64_corrupt_x22(void);
extern void selftest_aarch64_corrupt_x23(void);
extern void selftest_aarch64_corrupt_x24(void);
extern void selftest_aarch64_corrupt_x25(void);
extern void selftest_aarch64_corrupt_x26(void);
extern void selftest_aarch64_corrupt_x27(void);
extern void selftest_aarch64_corrupt_x28(void);
extern void selftest_aarch64_corrupt_x29(void);
/* SIMD: lower 64 bits of d8-d15 are callee-saved. */
extern void selftest_aarch64_corrupt_d8(void);
extern void selftest_aarch64_corrupt_d9(void);
extern void selftest_aarch64_corrupt_d10(void);
extern void selftest_aarch64_corrupt_d11(void);
extern void selftest_aarch64_corrupt_d12(void);
extern void selftest_aarch64_corrupt_d13(void);
extern void selftest_aarch64_corrupt_d14(void);
extern void selftest_aarch64_corrupt_d15(void);

static const selftest_entry_t aarch64_entries[] = {
    {"noop", selftest_aarch64_noop, 0},
#if !defined(__APPLE__)
    {"corrupt_x18", selftest_aarch64_corrupt_x18, 1},
#endif
    {"corrupt_x19", selftest_aarch64_corrupt_x19, 1},
    {"corrupt_x20", selftest_aarch64_corrupt_x20, 1},
    {"corrupt_x21", selftest_aarch64_corrupt_x21, 1},
    {"corrupt_x22", selftest_aarch64_corrupt_x22, 1},
    {"corrupt_x23", selftest_aarch64_corrupt_x23, 1},
    {"corrupt_x24", selftest_aarch64_corrupt_x24, 1},
    {"corrupt_x25", selftest_aarch64_corrupt_x25, 1},
    {"corrupt_x26", selftest_aarch64_corrupt_x26, 1},
    {"corrupt_x27", selftest_aarch64_corrupt_x27, 1},
    {"corrupt_x28", selftest_aarch64_corrupt_x28, 1},
    {"corrupt_x29", selftest_aarch64_corrupt_x29, 1},
    {"corrupt_d8", selftest_aarch64_corrupt_d8, 1},
    {"corrupt_d9", selftest_aarch64_corrupt_d9, 1},
    {"corrupt_d10", selftest_aarch64_corrupt_d10, 1},
    {"corrupt_d11", selftest_aarch64_corrupt_d11, 1},
    {"corrupt_d12", selftest_aarch64_corrupt_d12, 1},
    {"corrupt_d13", selftest_aarch64_corrupt_d13, 1},
    {"corrupt_d14", selftest_aarch64_corrupt_d14, 1},
    {"corrupt_d15", selftest_aarch64_corrupt_d15, 1},
    {NULL, NULL, 0},
};

#elif defined(MLD_SYS_X86_64) && defined(MLD_SYSV_ABI_SUPPORTED)

/* Defined in selftest_x86_64.S. The .S symbols are MLD_SYSV_ABI-qualified;
 * we store them as plain void(*)(void) and re-qualify the cast at the call
 * site (see SELFTEST_RUN_ARCH below). */
extern MLD_SYSV_ABI
void selftest_x86_64_noop(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_rbx(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_rbp(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_r12(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_r13(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_r14(void);
extern MLD_SYSV_ABI
void selftest_x86_64_corrupt_r15(void);

static const selftest_entry_t x86_64_entries[] = {
    {"noop", (void (*)(void))selftest_x86_64_noop, 0},
    {"corrupt_rbx", (void (*)(void))selftest_x86_64_corrupt_rbx, 1},
    {"corrupt_rbp", (void (*)(void))selftest_x86_64_corrupt_rbp, 1},
    {"corrupt_r12", (void (*)(void))selftest_x86_64_corrupt_r12, 1},
    {"corrupt_r13", (void (*)(void))selftest_x86_64_corrupt_r13, 1},
    {"corrupt_r14", (void (*)(void))selftest_x86_64_corrupt_r14, 1},
    {"corrupt_r15", (void (*)(void))selftest_x86_64_corrupt_r15, 1},
    {NULL, NULL, 0},
};

#elif defined(MLD_SYS_ARMV81M_MVE)

extern void selftest_armv81m_noop(void);
extern void selftest_armv81m_corrupt_r4(void);
extern void selftest_armv81m_corrupt_r5(void);
extern void selftest_armv81m_corrupt_r6(void);
extern void selftest_armv81m_corrupt_r7(void);
extern void selftest_armv81m_corrupt_r8(void);
extern void selftest_armv81m_corrupt_r9(void);
extern void selftest_armv81m_corrupt_r10(void);
extern void selftest_armv81m_corrupt_r11(void);
extern void selftest_armv81m_corrupt_q4(void);
extern void selftest_armv81m_corrupt_q5(void);
extern void selftest_armv81m_corrupt_q6(void);
extern void selftest_armv81m_corrupt_q7(void);

static const selftest_entry_t armv81m_entries[] = {
    {"noop", selftest_armv81m_noop, 0},
    {"corrupt_r4", selftest_armv81m_corrupt_r4, 1},
    {"corrupt_r5", selftest_armv81m_corrupt_r5, 1},
    {"corrupt_r6", selftest_armv81m_corrupt_r6, 1},
    {"corrupt_r7", selftest_armv81m_corrupt_r7, 1},
    {"corrupt_r8", selftest_armv81m_corrupt_r8, 1},
    {"corrupt_r9", selftest_armv81m_corrupt_r9, 1},
    {"corrupt_r10", selftest_armv81m_corrupt_r10, 1},
    {"corrupt_r11", selftest_armv81m_corrupt_r11, 1},
    {"corrupt_q4", selftest_armv81m_corrupt_q4, 1},
    {"corrupt_q5", selftest_armv81m_corrupt_q5, 1},
    {"corrupt_q6", selftest_armv81m_corrupt_q6, 1},
    {"corrupt_q7", selftest_armv81m_corrupt_q7, 1},
    {NULL, NULL, 0},
};

#endif /* !MLD_SYS_AARCH64 && !(MLD_SYS_X86_64 && MLD_SYSV_ABI_SUPPORTED) && \
          MLD_SYS_ARMV81M_MVE */

int abicheck_selftest(void)
{
  int failures = 0;

#if defined(MLD_SYS_AARCH64)
  SELFTEST_RUN_ARCH("aarch64", struct aarch64_register_state,
                    init_aarch64_register_state, asm_call_stub_aarch64,
                    check_aarch64_aapcs_compliance, aarch64_entries,
                    (void (*)(void)));
#elif defined(MLD_SYS_X86_64) && defined(MLD_SYSV_ABI_SUPPORTED)
  SELFTEST_RUN_ARCH(
      "x86_64", struct x86_64_register_state, init_x86_64_register_state,
      asm_call_stub_x86_64_sysv, check_x86_64_sysv_compliance, x86_64_entries,
      (MLD_SYSV_ABI
       void (*)(void)));
#elif defined(MLD_SYS_ARMV81M_MVE)
  SELFTEST_RUN_ARCH("armv81m", struct armv81m_register_state,
                    init_armv81m_register_state, asm_call_stub_armv81m,
                    check_armv81m_aapcs32_compliance, armv81m_entries,
                    (void (*)(void)));
#else  /* !MLD_SYS_AARCH64 && !(MLD_SYS_X86_64 && MLD_SYSV_ABI_SUPPORTED) && \
          MLD_SYS_ARMV81M_MVE */
  /* No abicheck support on this architecture. */
#endif /* !MLD_SYS_AARCH64 && !(MLD_SYS_X86_64 && MLD_SYSV_ABI_SUPPORTED) && \
          !MLD_SYS_ARMV81M_MVE */

  return failures;
}
