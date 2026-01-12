/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * Adapted for MPS3 AN524 (Cortex-M33) from pqmx integration/cmdline.c
 *
 * This file provides __wrap_main which:
 * 1. Initializes stdio (disables buffering for semihosting)
 * 2. Processes command line arguments
 * 3. Calls the real main()
 * 4. Handles exit via semihosting
 */
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "ARMCM33.h"

typedef struct cmdline_s
{
  int argc;
  char *argv[];
} cmdline_t;

/* AN524 DDR4: 0x70000000-0x701FFFFF (2MB)
 * Stack ends at 0x70200000, so cmdline must be BEFORE that.
 * Place cmdline at end of heap area (0x70190000) to avoid collision.
 * This leaves ~64KB for cmdline data, which is plenty. */
#define CMDLINE_ADDR ((cmdline_t *)0x70190000)

/* Provide a prototype for the real main that the C library expects. */
extern int __real_main(int argc, char *argv[]);
int __wrap_main(int unused_argc, char *unused_argv[]);

#ifdef SEMIHOSTING
#define SYS_EXIT_EXTENDED 0x20
#define ADP_Stopped_ApplicationExit 0x20026
/* Use semihosting_syscall from semihosting.c */
extern uint32_t semihosting_syscall(uint32_t nr, const uint32_t arg);
void semihosting_exit_with_rc(int rc);

void semihosting_exit_with_rc(int rc)
{
  struct exit_code_s
  {
    int32_t reason_code;
    int32_t return_code;
  } s = {ADP_Stopped_ApplicationExit, rc};
  semihosting_syscall(SYS_EXIT_EXTENDED, (uint32_t)&s);
}
#endif

/* Wrap main: forward to __real_main with semihosting exit. */
int __wrap_main(int unused_argc, char *unused_argv[])
{
  (void)unused_argc;
  (void)unused_argv;
  
  /* Note: We skip setvbuf() because it causes BusFault on mps3-an524.
   * Instead, __wrap__write uses semihosting which is unbuffered. */
  
  /* Call real main with no arguments. */
  int rc = __real_main(0, (char **)0);
  
#ifdef SEMIHOSTING
  semihosting_exit_with_rc(rc);
#endif
  return rc;
}
