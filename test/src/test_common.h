/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Assertion helpers shared by the mldsa-native test and benchmark drivers.
 *
 * Two flavours are provided:
 *
 * - CHECK(cond) for conditions that are not return codes, e.g. memcmp()
 *   comparisons or the outcome of a test helper. On failure it reports the
 *   source location only, as there is no meaningful value to print.
 *
 * - CHECK_ERR(call, expected) for calls returning an mldsa-native return
 *   code, i.e. the mld_sign_xxx API. On failure it reports the expected and
 *   the actual code, each numerically and by name, which makes a mismatch
 *   diagnosable from the test log alone -- and greppable from CI scripts.
 *
 * Use CHECK_ERR only where the value really is an MLD_ERR_XXX code, otherwise
 * the reported name is meaningless. Notably it does NOT apply to:
 * randombytes(), which is consumer-provided and returns an unspecified
 * non-zero value on failure; and values that merely aggregate return codes,
 * e.g. a bitwise OR over several calls.
 *
 * Both macros `return 1` from the enclosing function on failure. Drivers
 * whose enclosing functions return void define MLD_TEST_CHECK_EXIT before
 * including this header to terminate the process instead.
 */

#ifndef MLD_TEST_SRC_TEST_COMMON_H
#define MLD_TEST_SRC_TEST_COMMON_H

#include <stdio.h>

#if defined(MLD_TEST_CHECK_EXIT)
#include <stdlib.h>
#endif

#include "../../mldsa/src/common.h"

/*
 * Name of an mldsa-native return code, for diagnostics.
 *
 * MLD_INLINE also silences unused-function warnings in drivers that use only
 * CHECK(), so no separate gating on the used assertion flavour is needed.
 */
static MLD_INLINE const char *mld_err_name(int rc)
{
  switch (rc)
  {
    case 0:
      return "Success";
    case MLD_ERR_FAIL:
      return "MLD_ERR_FAIL";
    case MLD_ERR_OUT_OF_MEMORY:
      return "MLD_ERR_OUT_OF_MEMORY";
    case MLD_ERR_RNG_FAIL:
      return "MLD_ERR_RNG_FAIL";
    case MLD_ERR_SIGN_ATTEMPTS_EXHAUSTED:
      return "MLD_ERR_SIGN_ATTEMPTS_EXHAUSTED";
    case MLD_ERR_SIGNING_PAUSED:
      return "MLD_ERR_SIGNING_PAUSED";
    case MLD_ERR_INVALID_SIGNATURE:
      return "MLD_ERR_INVALID_SIGNATURE";
    case MLD_ERR_INVALID_KEY:
      return "MLD_ERR_INVALID_KEY";
    case MLD_ERR_PCT_FAIL:
      return "MLD_ERR_PCT_FAIL";
    case MLD_ERR_INVALID_ARG:
      return "MLD_ERR_INVALID_ARG";
    default:
      return "unknown error";
  }
}

#if defined(MLD_TEST_CHECK_EXIT)
#define MLD_TEST_FAIL() exit(1)
#else
#define MLD_TEST_FAIL() return 1
#endif

/* Assert a condition that is not a return code, e.g. a memcmp() comparison. */
#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    int rc;                                                   \
    rc = (x);                                                 \
    if (!rc)                                                  \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      MLD_TEST_FAIL();                                        \
    }                                                         \
  } while (0)

/*
 * Assert that `call` returns exactly `expected`. `call` is evaluated once.
 *
 * On mismatch, both codes are printed numerically and by name, e.g.
 *
 *   ERROR (test/src/test_mldsa.c,62): Expected 0 (Success) for
 *   mld_sign_keypair(pk, sk), but got -8 (MLD_ERR_PCT_FAIL)
 */
#define CHECK_ERR(call, expected)                                          \
  do                                                                       \
  {                                                                        \
    const int mld_got = (call);                                            \
    const int mld_exp = (expected);                                        \
    if (mld_got != mld_exp)                                                \
    {                                                                      \
      fprintf(stderr,                                                      \
              "ERROR (%s,%d): Expected %d (%s) for %s, but got %d (%s)\n", \
              __FILE__, __LINE__, mld_exp, mld_err_name(mld_exp), #call,   \
              mld_got, mld_err_name(mld_got));                             \
      MLD_TEST_FAIL();                                                     \
    }                                                                      \
  } while (0)

#endif /* !MLD_TEST_SRC_TEST_COMMON_H */
