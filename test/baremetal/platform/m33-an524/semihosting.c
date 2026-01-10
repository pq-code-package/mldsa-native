/******************************************************************************
 * @file     semihosting.c
 * @brief    Semihosting support for Cortex-M33 Device on MPS3 AN524
 * @version  V1.0.0
 * @date     16. December 2020
 ******************************************************************************/
/*
 * Copyright (c) 2009-2020 Arm Limited. All rights reserved.
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
 */

#ifdef SEMIHOSTING

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>

/*===========================================================================
 * Semihosting Support
 *===========================================================================*/

#define SYS_WRITE 0x05
#define SYS_READ 0x06
#define SYS_ISTTY 0x09
#define SYS_SEEK 0x0A
#define SYS_CLOSE 0x02
#define SYS_OPEN 0x01
#define SYS_EXIT 0x18

/* Angel exit codes */
#define ADP_Stopped_ApplicationExit 0x20026
#define ADP_Stopped_RunTimeError 0x20023

static inline int32_t semihosting_call(uint32_t op, void *arg)
{
  int32_t result;
  __asm__ volatile(
      "mov r0, %[op]\n"
      "mov r1, %[arg]\n"
      "bkpt 0xAB\n"
      "mov %[res], r0\n"
      : [res] "=r"(result)
      : [op] "r"(op), [arg] "r"(arg)
      : "r0", "r1", "r2", "r3", "ip", "lr", "memory", "cc");
  return result;
}

void semihosting_exit(int code)
{
  uint32_t reason =
      (code == 0) ? ADP_Stopped_ApplicationExit : ADP_Stopped_RunTimeError;
  uint32_t args[2] = {reason, (uint32_t)code};
  semihosting_call(SYS_EXIT, args);
  while (1)
  {
    __asm__ volatile("wfi");
  }
}

/*===========================================================================
 * Newlib Syscall Implementation (Semihosting)
 *===========================================================================*/

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

int _open(const char *path, int flags, int mode)
{
  uint32_t args[3] = {(uint32_t)path, (uint32_t)flags, (uint32_t)mode};
  return semihosting_call(SYS_OPEN, args);
}

int _close(int fd) { return semihosting_call(SYS_CLOSE, &fd); }

int _write(int fd, const void *buf, size_t count)
{
  if (count == 0)
  {
    return 0;
  }
  uint32_t args[3] = {(uint32_t)fd, (uint32_t)buf, (uint32_t)count};
  int32_t not_written = semihosting_call(SYS_WRITE, args);
  return (not_written < 0) ? -1 : (int)(count - (size_t)not_written);
}

int _read(int fd, void *buf, size_t count)
{
  if (count == 0)
  {
    return 0;
  }
  uint32_t args[3] = {(uint32_t)fd, (uint32_t)buf, (uint32_t)count};
  int32_t not_read = semihosting_call(SYS_READ, args);
  return (not_read < 0) ? -1 : (int)(count - (size_t)not_read);
}

int _lseek(int fd, int offset, int whence)
{
  (void)whence; /* Semihosting only supports absolute seek */
  uint32_t args[2] = {(uint32_t)fd, (uint32_t)offset};
  return semihosting_call(SYS_SEEK, args);
}

int _isatty(int fd) { return semihosting_call(SYS_ISTTY, &fd); }

int _fstat(int fd, void *st)
{
  (void)fd;
  (void)st;
  return -1;
}

int _getpid(void) { return 1; }

int _kill(int pid, int sig)
{
  (void)pid;
  (void)sig;
  return -1;
}

void _exit(int code) { semihosting_exit(code); }

#else /* !SEMIHOSTING */

/*===========================================================================
 * Minimal Syscall Stubs (No Semihosting)
 *===========================================================================*/

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
    return (void *)-1;
  }

  heap_ptr += incr;
  return (void *)prev;
}

int _write(int fd, const void *buf, size_t count)
{
  (void)fd;
  (void)buf;
  (void)count;
  return -1;
}

int _read(int fd, void *buf, size_t count)
{
  (void)fd;
  (void)buf;
  (void)count;
  return -1;
}

int _close(int fd)
{
  (void)fd;
  return -1;
}

int _fstat(int fd, void *st)
{
  (void)fd;
  (void)st;
  return -1;
}

int _isatty(int fd)
{
  (void)fd;
  return 0;
}

int _lseek(int fd, int offset, int whence)
{
  (void)fd;
  (void)offset;
  (void)whence;
  return -1;
}

int _getpid(void) { return 1; }

int _kill(int pid, int sig)
{
  (void)pid;
  (void)sig;
  return -1;
}

void _exit(int code)
{
  (void)code;
  while (1)
  {
    __asm__ volatile("wfi");
  }
}

#endif /* SEMIHOSTING */
