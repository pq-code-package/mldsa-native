/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_TEST_ABICHECK_SELFTEST_H
#define MLD_TEST_ABICHECK_SELFTEST_H

/* Run the ABI checker meta-test for the active architecture. Returns the
 * number of selftest failures (0 = all good). */
int abicheck_selftest(void);

#endif /* !MLD_TEST_ABICHECK_SELFTEST_H */
