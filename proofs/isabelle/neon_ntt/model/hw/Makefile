# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

CC      ?= cc

# Mirror the pedantic flag set used by the main project (test/mk/config.mk),
# minus the inline-asm-incompatible -Wpedantic.
CFLAGS ?= \
  -O2 \
  -std=c99 \
  -march=armv8.1-a \
  -Wall \
  -Wextra \
  -Werror \
  -Wshadow \
  -Wpointer-arith \
  -Wredundant-decls \
  -Wconversion \
  -Wsign-conversion \
  -Wmissing-prototypes \
  -Wstrict-prototypes \
  -Wformat=2 \
  -Wformat-security \
  -Wundef \
  -Wcast-qual \
  -Wnull-dereference \
  -D_FORTIFY_SOURCE=2

.PHONY: all clean
all: hw_exec

hw_exec: hw_exec.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f hw_exec
