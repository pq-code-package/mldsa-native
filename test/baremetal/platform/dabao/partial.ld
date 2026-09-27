/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/* Partial link (ld -r) of a test binary, see link.py */
SECTIONS
{
  .mld_data : { *(.data .data.* .sdata .sdata.*) }
}
