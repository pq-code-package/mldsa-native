/******************************************************************************
 * @file     semihosting.c
 * @brief    Semihosting support for Cortex-M33 Device on MPS3 AN524
 * @version  V2.0.0
 * @date     10. January 2026
 ******************************************************************************/
/*
 * Copyright (c) 2009-2020 Arm Limited. All rights reserved.
 * Copyright (c) The mldsa-native project authors
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Aligned with M55-AN547 implementation for main build compatibility.
 */

#if !defined(NO_SEMIHOSTING_EXIT)

#include <stdint.h>
#include <stdio.h>

/* Semihosting syscall numbers */
static const uint32_t REPORT_EXCEPTION = 0x18;
static const uint32_t ApplicationExit = 0x20026;

/* Do a system call towards QEMU or the debugger */
uint32_t semihosting_syscall(uint32_t nr, const uint32_t arg)
{
  __asm__ volatile(
      "mov r0, %[nr]\n"
      "mov r1, %[arg]\n"
      "bkpt 0xAB\n"
      "mov %[nr], r0\n"
      : [nr] "+r"(nr)
      : [arg] "r"(arg)
      : "r0", "r1", "memory");
  return nr;
}

/* Register a destructor that will call QEMU telling it the program has exited
 */
static void __attribute__((destructor)) semihosting_exit(void)
{
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

/* Exception handlers - print message and exit */
void NMI_Handler(void)
{
  puts("NMI_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void HardFault_Handler(void)
{
  puts("HardFault_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void MemManage_Handler(void)
{
  puts("MemManage_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void BusFault_Handler(void)
{
  puts("BusFault_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void UsageFault_Handler(void)
{
  puts("UsageFault_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void SecureFault_Handler(void)
{
  puts("SecureFault_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void SVC_Handler(void)
{
  puts("SVC_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void DebugMon_Handler(void)
{
  puts("DebugMon_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

void PendSV_Handler(void)
{
  puts("PendSV_Handler");
  semihosting_syscall(REPORT_EXCEPTION, ApplicationExit);
}

#endif /* !defined(NO_SEMIHOSTING_EXIT) */

/*===========================================================================
 * Newlib Syscall Stubs (minimal implementations)
 *===========================================================================*/

#include <errno.h>
#include <sys/types.h>

extern uint32_t __HeapBase;
extern uint32_t __HeapLimit;
static uint8_t *heap_ptr = NULL;

void *_sbrk(ptrdiff_t incr)
{
  if (heap_ptr == NULL)
  {
    heap_ptr = (uint8_t *)&__HeapBase;
  }

  uint8_t *prev = heap_ptr;
  if ((heap_ptr + incr) > (uint8_t *)&__HeapLimit)
  {
    return (void *)-1; /* Heap overflow */
  }
  heap_ptr += incr;
  return (void *)prev;
}

int _close(int fd)
{
  (void)fd;
  return 0;
}

int _fstat(int fd, void *st)
{
  (void)fd;
  (void)st;
  errno = ENOSYS;
  return -1;
}

int _getpid(void)
{
  errno = ENOSYS;
  return -1;
}

int _isatty(int fd)
{
  (void)fd;
  errno = ENOSYS;
  return -1;
}

int _lseek(int fd, int offset, int whence)
{
  (void)fd;
  (void)offset;
  (void)whence;
  errno = ENOSYS;
  return -1;
}

int _kill(int pid, int sig)
{
  (void)pid;
  (void)sig;
  errno = ENOSYS;
  return -1;
}
