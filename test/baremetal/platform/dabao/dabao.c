/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * newlib glue for running a test binary inside the Xous baremetal image on
 * the Dabao board. The Rust side (see xous-core.patch) calls mld_bench_entry
 * from its `mldsa` console command, provides the heap, prints through
 * mld_putchar over USB serial and resets into boot1 on mld_bench_exit.
 */

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/stat.h>

extern void mld_putchar(unsigned char c);
extern void mld_bench_exit(int rc) __attribute__((noreturn));
extern int main(int argc, char **argv);

/* Called from the Rust side */
int mld_bench_entry(char *heap, size_t heap_len);

/* Initialized data of the C side, see partial.ld and the patched link.x */
extern char _smld_data[], _emld_data[], _smld_data_lma[];

static char *heap_cur;
static char *heap_end;

int mld_bench_entry(char *heap, size_t heap_len)
{
  static char arg0[] = "bench";
  static char *argv[] = {arg0, NULL};
  volatile char *dst = _smld_data;
  const char *src = _smld_data_lma;
  /* Plain loop: memcpy may itself depend on initialized data */
  while (dst < _emld_data)
  {
    *dst++ = *src++;
  }
  heap_cur = heap;
  heap_end = heap + heap_len;
  /* exit() flushes stdio before reaching _exit */
  exit(main(1, argv));
}

void *_sbrk(ptrdiff_t incr)
{
  char *prev = heap_cur;
  if (incr > heap_end - heap_cur)
  {
    errno = ENOMEM;
    return (void *)-1;
  }
  heap_cur += incr;
  return prev;
}

int _write(int fd, const char *buf, int len)
{
  int i;
  (void)fd;
  for (i = 0; i < len; i++)
  {
    mld_putchar((unsigned char)buf[i]);
  }
  return len;
}

int _read(int fd, char *buf, int len)
{
  (void)fd;
  (void)buf;
  (void)len;
  return 0;
}

int _close(int fd)
{
  (void)fd;
  return -1;
}

int _fstat(int fd, struct stat *st)
{
  (void)fd;
  st->st_mode = S_IFCHR;
  return 0;
}

int _isatty(int fd)
{
  (void)fd;
  return 1;
}

int _lseek(int fd, int off, int whence)
{
  (void)fd;
  (void)off;
  (void)whence;
  return 0;
}

int _kill(int pid, int sig)
{
  (void)pid;
  (void)sig;
  errno = EINVAL;
  return -1;
}

int _getpid(void) { return 1; }

void _exit(int rc) { mld_bench_exit(rc); }
