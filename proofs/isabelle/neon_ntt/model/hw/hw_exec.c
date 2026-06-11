/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * hw_exec -- run a single AArch64 instruction via inline asm and print
 * its unsigned result, mirroring the model_exec CLI:
 *
 *   hw_exec MNEMONIC BITWIDTH ARG0 [ARG1 ...]
 *
 * Inputs accept hex (0x...) or signed decimal. Output is 0x-prefixed
 * unsigned hex padded to BITWIDTH/4 nibbles.
 *
 * NEON ops at 8/16/32-bit element sizes use the corresponding Q-register
 * arrangement; lane 0 is the result. MULH/UMULH only exist as 64-bit
 * scalar instructions on AArch64, so they're handled with `smulh`/`umulh`
 * on Xn registers.
 *
 * Supported MNEMONIC / BITWIDTH / arity matrix:
 *
 *   MNEMONIC   BITWIDTH      arity   args
 *   --------   --------      -----   --------------------------
 *   MUL         8 / 16 / 32    2     a, b
 *   MLA         8 / 16 / 32    3     acc, a, b
 *   MLS         8 / 16 / 32    3     acc, a, b
 *   SHSUB       8 / 16 / 32    2     a, b
 *   SRSHR       8 / 16 / 32    2     k (shift in [1,bw]), a
 *   SQDMULH         16 / 32    2     a, b
 *   SQRDMULH        16 / 32    2     a, b
 *   SQRDMLAH        16 / 32    3     acc, a, b
 *   MULH                  64   2     a, b   (scalar smulh on Xn)
 *   UMULH                 64   2     a, b   (scalar umulh on Xn)
 */

#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if !defined(__aarch64__)
#error "hw_exec must be built on AArch64"
#endif

/* Maximum length of a single input case (line in stream mode, joined argv
   in one-shot mode). Long enough for the worst case allowed by the CLI
   surface: a mnemonic + bw + three 64-bit hex values with separators. */
#define LINE_BUF_SIZE 1024
#define MAX_TOKENS 8
#define OUT_BUF_SIZE 1024

#if defined(__GNUC__) || defined(__clang__)
__attribute__((noreturn))
#endif
static void die(const char *msg)
{
  fprintf(stderr, "%s\n", msg);
  exit(1);
}

/*
 * Convert a single character to its digit value in `base`. Returns the digit
 * on success or -1 on failure (non-digit, or digit out of range for base).
 */
static int digit_value(char c, int base)
{
  int v;
  if (c >= '0' && c <= '9')
  {
    v = c - '0';
  }
  else if (c >= 'a' && c <= 'z')
  {
    v = 10 + (c - 'a');
  }
  else if (c >= 'A' && c <= 'Z')
  {
    v = 10 + (c - 'A');
  }
  else
  {
    return -1;
  }
  if (v >= base)
  {
    return -1;
  }
  return v;
}

/*
 * Parse a non-negative int in [0, INT_MAX] from an untrusted string.
 * Returns 0 on success, nonzero on parse error or out-of-range. Accepts only
 * decimal digits (no sign, no whitespace, no trailing junk).
 */
static int parse_int(const char *s, int *out)
{
  unsigned int acc = 0;
  unsigned int limit = (unsigned int)INT_MAX;
  int d;

  if (s == NULL || *s == '\0')
  {
    return 1;
  }
  for (; *s != '\0'; s++)
  {
    d = digit_value(*s, 10);
    if (d < 0)
    {
      return 1;
    }
    if (acc > (limit - (unsigned int)d) / 10u)
    {
      return 1;
    }
    acc = acc * 10u + (unsigned int)d;
  }
  *out = (int)acc;
  return 0;
}

/*
 * Parse a signed integer in decimal or 0x-prefixed hex from an untrusted
 * string and reduce it mod 2^bw into [0, 2^bw). On parse failure: writes a
 * diagnostic into *err and returns nonzero. `bw` must be in [1, 64].
 *
 * On overflow of the uint64_t accumulator we accept the wrap-around value:
 * the result is masked to bw bits below regardless, so an over-long literal
 * is treated as its natural mod-2^bw reduction. We still require strict
 * digit-only input (no trailing junk, no embedded sign or whitespace).
 */
static int parse_arg(const char *s, int bw, uint64_t *out, char *err,
                     size_t errlen)
{
  int neg = 0;
  int base = 10;
  uint64_t acc = 0;
  uint64_t mask;
  uint64_t v;
  int d;

  if (bw < 1 || bw > 64)
  {
    snprintf(err, errlen, "bitwidth out of range: %d", bw);
    return 1;
  }

  if (*s == '-')
  {
    neg = 1;
    s++;
  }
  if (*s == '0' && (s[1] == 'x' || s[1] == 'X'))
  {
    base = 16;
    s += 2;
  }
  if (*s == '\0')
  {
    snprintf(err, errlen, "not an integer: empty");
    return 1;
  }

  for (; *s != '\0'; s++)
  {
    d = digit_value(*s, base);
    if (d < 0)
    {
      snprintf(err, errlen, "not an integer: %s", s);
      return 1;
    }
    /* Wrap-around on overflow is accepted; the bw-mask below normalises it. */
    acc = acc * (uint64_t)base + (uint64_t)d;
  }

  mask = (bw == 64) ? ~(uint64_t)0 : (((uint64_t)1 << bw) - 1);
  /* Unsigned negation is well-defined: equals (-acc) mod 2^64; mask reduces
     mod 2^bw. Avoids the UB of `-(int64_t)acc` when acc == 2^63. */
  v = neg ? ((uint64_t)0 - acc) : acc;
  *out = v & mask;
  return 0;
}

static void fmt_hex(int bw, uint64_t v, char *buf, size_t buflen)
{
  int nibbles = (bw + 3) / 4;
  snprintf(buf, buflen, "0x%0*" PRIx64, nibbles, v);
}


/* ============================================================
 * NEON 8-bit element ops (16 lanes: .16b on a Q-reg)
 * ============================================================ */

static uint64_t neon_mul_8(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.16b, %w[a]\n\t"
      "dup v1.16b, %w[b]\n\t"
      "mul v2.16b, v0.16b, v1.16b\n\t"
      "umov %w[out], v2.b[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xff;
}

static uint64_t neon_mla_8(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.16b, %w[acc]\n\t"
      "dup v1.16b, %w[a]\n\t"
      "dup v2.16b, %w[b]\n\t"
      "mla v0.16b, v1.16b, v2.16b\n\t"
      "umov %w[out], v0.b[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xff;
}

static uint64_t neon_mls_8(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.16b, %w[acc]\n\t"
      "dup v1.16b, %w[a]\n\t"
      "dup v2.16b, %w[b]\n\t"
      "mls v0.16b, v1.16b, v2.16b\n\t"
      "umov %w[out], v0.b[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xff;
}

static uint64_t neon_shsub_8(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.16b, %w[a]\n\t"
      "dup v1.16b, %w[b]\n\t"
      "shsub v2.16b, v0.16b, v1.16b\n\t"
      "umov %w[out], v2.b[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xff;
}

/* SRSHR (vector) takes an immediate shift in [1, esize] -- i.e. [1, 8] for
 * .16b, [1, 16] for .8h, [1, 32] for .4s. A shift of 0 is not architecturally
 * encodable: the Arm ARM constrains shift to 1 <= shift <= esize, and any
 * AArch64 assembler rejects #0 outright. We dispatch on k so the immediate
 * can be stringised at compile time. */
#define SRSHR_8_ASM(K)             \
  __asm__ volatile(                \
      "dup v0.16b, %w[a]\n\t"      \
      "srshr v1.16b, v0.16b, #" #K \
      "\n\t"                       \
      "umov %w[out], v1.b[0]\n\t"  \
      : [out] "=r"(out)            \
      : [a] "r"((uint32_t)a)       \
      : "v0", "v1")

static uint64_t neon_srshr_8(int k, uint64_t a)
{
  uint64_t out = 0;
  switch (k)
  {
    case 1:
      SRSHR_8_ASM(1);
      break;
    case 2:
      SRSHR_8_ASM(2);
      break;
    case 3:
      SRSHR_8_ASM(3);
      break;
    case 4:
      SRSHR_8_ASM(4);
      break;
    case 5:
      SRSHR_8_ASM(5);
      break;
    case 6:
      SRSHR_8_ASM(6);
      break;
    case 7:
      SRSHR_8_ASM(7);
      break;
    case 8:
      SRSHR_8_ASM(8);
      break;
    default:
      die("SRSHR 8: shift must be in [1,8]");
  }
  return out & 0xff;
}

/* ============================================================
 * NEON 16-bit element ops (8 lanes: .8h)
 * ============================================================ */

static uint64_t neon_mul_16(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[a]\n\t"
      "dup v1.8h, %w[b]\n\t"
      "mul v2.8h, v0.8h, v1.8h\n\t"
      "umov %w[out], v2.h[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_mla_16(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[acc]\n\t"
      "dup v1.8h, %w[a]\n\t"
      "dup v2.8h, %w[b]\n\t"
      "mla v0.8h, v1.8h, v2.8h\n\t"
      "umov %w[out], v0.h[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_mls_16(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[acc]\n\t"
      "dup v1.8h, %w[a]\n\t"
      "dup v2.8h, %w[b]\n\t"
      "mls v0.8h, v1.8h, v2.8h\n\t"
      "umov %w[out], v0.h[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_sqdmulh_16(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[a]\n\t"
      "dup v1.8h, %w[b]\n\t"
      "sqdmulh v2.8h, v0.8h, v1.8h\n\t"
      "umov %w[out], v2.h[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_sqrdmulh_16(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[a]\n\t"
      "dup v1.8h, %w[b]\n\t"
      "sqrdmulh v2.8h, v0.8h, v1.8h\n\t"
      "umov %w[out], v2.h[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_sqrdmlah_16(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[acc]\n\t"
      "dup v1.8h, %w[a]\n\t"
      "dup v2.8h, %w[b]\n\t"
      "sqrdmlah v0.8h, v1.8h, v2.8h\n\t"
      "umov %w[out], v0.h[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

static uint64_t neon_shsub_16(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.8h, %w[a]\n\t"
      "dup v1.8h, %w[b]\n\t"
      "shsub v2.8h, v0.8h, v1.8h\n\t"
      "umov %w[out], v2.h[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffff;
}

#define SRSHR_16_ASM(K)           \
  __asm__ volatile(               \
      "dup v0.8h, %w[a]\n\t"      \
      "srshr v1.8h, v0.8h, #" #K  \
      "\n\t"                      \
      "umov %w[out], v1.h[0]\n\t" \
      : [out] "=r"(out)           \
      : [a] "r"((uint32_t)a)      \
      : "v0", "v1")

static uint64_t neon_srshr_16(int k, uint64_t a)
{
  uint64_t out = 0;
  switch (k)
  {
    case 1:
      SRSHR_16_ASM(1);
      break;
    case 2:
      SRSHR_16_ASM(2);
      break;
    case 3:
      SRSHR_16_ASM(3);
      break;
    case 4:
      SRSHR_16_ASM(4);
      break;
    case 5:
      SRSHR_16_ASM(5);
      break;
    case 6:
      SRSHR_16_ASM(6);
      break;
    case 7:
      SRSHR_16_ASM(7);
      break;
    case 8:
      SRSHR_16_ASM(8);
      break;
    case 9:
      SRSHR_16_ASM(9);
      break;
    case 10:
      SRSHR_16_ASM(10);
      break;
    case 11:
      SRSHR_16_ASM(11);
      break;
    case 12:
      SRSHR_16_ASM(12);
      break;
    case 13:
      SRSHR_16_ASM(13);
      break;
    case 14:
      SRSHR_16_ASM(14);
      break;
    case 15:
      SRSHR_16_ASM(15);
      break;
    case 16:
      SRSHR_16_ASM(16);
      break;
    default:
      die("SRSHR 16: shift must be in [1,16]");
  }
  return out & 0xffff;
}

/* ============================================================
 * NEON 32-bit element ops (4 lanes: .4s)
 * ============================================================ */

static uint64_t neon_mul_32(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[a]\n\t"
      "dup v1.4s, %w[b]\n\t"
      "mul v2.4s, v0.4s, v1.4s\n\t"
      "umov %w[out], v2.s[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_mla_32(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[acc]\n\t"
      "dup v1.4s, %w[a]\n\t"
      "dup v2.4s, %w[b]\n\t"
      "mla v0.4s, v1.4s, v2.4s\n\t"
      "umov %w[out], v0.s[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_mls_32(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[acc]\n\t"
      "dup v1.4s, %w[a]\n\t"
      "dup v2.4s, %w[b]\n\t"
      "mls v0.4s, v1.4s, v2.4s\n\t"
      "umov %w[out], v0.s[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_sqdmulh_32(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[a]\n\t"
      "dup v1.4s, %w[b]\n\t"
      "sqdmulh v2.4s, v0.4s, v1.4s\n\t"
      "umov %w[out], v2.s[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_sqrdmulh_32(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[a]\n\t"
      "dup v1.4s, %w[b]\n\t"
      "sqrdmulh v2.4s, v0.4s, v1.4s\n\t"
      "umov %w[out], v2.s[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_sqrdmlah_32(uint64_t acc, uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[acc]\n\t"
      "dup v1.4s, %w[a]\n\t"
      "dup v2.4s, %w[b]\n\t"
      "sqrdmlah v0.4s, v1.4s, v2.4s\n\t"
      "umov %w[out], v0.s[0]\n\t"
      : [out] "=r"(out)
      : [acc] "r"((uint32_t)acc), [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

static uint64_t neon_shsub_32(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile(
      "dup v0.4s, %w[a]\n\t"
      "dup v1.4s, %w[b]\n\t"
      "shsub v2.4s, v0.4s, v1.4s\n\t"
      "umov %w[out], v2.s[0]\n\t"
      : [out] "=r"(out)
      : [a] "r"((uint32_t)a), [b] "r"((uint32_t)b)
      : "v0", "v1", "v2");
  return out & 0xffffffff;
}

#define SRSHR_32_ASM(K)           \
  __asm__ volatile(               \
      "dup v0.4s, %w[a]\n\t"      \
      "srshr v1.4s, v0.4s, #" #K  \
      "\n\t"                      \
      "umov %w[out], v1.s[0]\n\t" \
      : [out] "=r"(out)           \
      : [a] "r"((uint32_t)a)      \
      : "v0", "v1")

static uint64_t neon_srshr_32(int k, uint64_t a)
{
  uint64_t out = 0;
  switch (k)
  {
    case 1:
      SRSHR_32_ASM(1);
      break;
    case 2:
      SRSHR_32_ASM(2);
      break;
    case 3:
      SRSHR_32_ASM(3);
      break;
    case 4:
      SRSHR_32_ASM(4);
      break;
    case 5:
      SRSHR_32_ASM(5);
      break;
    case 6:
      SRSHR_32_ASM(6);
      break;
    case 7:
      SRSHR_32_ASM(7);
      break;
    case 8:
      SRSHR_32_ASM(8);
      break;
    case 9:
      SRSHR_32_ASM(9);
      break;
    case 10:
      SRSHR_32_ASM(10);
      break;
    case 11:
      SRSHR_32_ASM(11);
      break;
    case 12:
      SRSHR_32_ASM(12);
      break;
    case 13:
      SRSHR_32_ASM(13);
      break;
    case 14:
      SRSHR_32_ASM(14);
      break;
    case 15:
      SRSHR_32_ASM(15);
      break;
    case 16:
      SRSHR_32_ASM(16);
      break;
    case 17:
      SRSHR_32_ASM(17);
      break;
    case 18:
      SRSHR_32_ASM(18);
      break;
    case 19:
      SRSHR_32_ASM(19);
      break;
    case 20:
      SRSHR_32_ASM(20);
      break;
    case 21:
      SRSHR_32_ASM(21);
      break;
    case 22:
      SRSHR_32_ASM(22);
      break;
    case 23:
      SRSHR_32_ASM(23);
      break;
    case 24:
      SRSHR_32_ASM(24);
      break;
    case 25:
      SRSHR_32_ASM(25);
      break;
    case 26:
      SRSHR_32_ASM(26);
      break;
    case 27:
      SRSHR_32_ASM(27);
      break;
    case 28:
      SRSHR_32_ASM(28);
      break;
    case 29:
      SRSHR_32_ASM(29);
      break;
    case 30:
      SRSHR_32_ASM(30);
      break;
    case 31:
      SRSHR_32_ASM(31);
      break;
    case 32:
      SRSHR_32_ASM(32);
      break;
    default:
      die("SRSHR 32: shift must be in [1,32]");
  }
  return out & 0xffffffff;
}

/* ============================================================
 * 64-bit scalar SMULH/UMULH (no NEON form)
 * ============================================================ */

static uint64_t scalar_smulh_64(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile("smulh %[out], %[a], %[b]"
                   : [out] "=r"(out)
                   : [a] "r"(a), [b] "r"(b));
  return out;
}

static uint64_t scalar_umulh_64(uint64_t a, uint64_t b)
{
  uint64_t out;
  __asm__ volatile("umulh %[out], %[a], %[b]"
                   : [out] "=r"(out)
                   : [a] "r"(a), [b] "r"(b));
  return out;
}

/* ============================================================
 * Dispatcher
 * ============================================================ */

static int streq(const char *a, const char *b) { return strcmp(a, b) == 0; }

/*
 * Run one case. On success: writes the formatted hex line into out (no
 * trailing newline) and returns 0. On failure: writes a diagnostic into
 * out and returns nonzero.
 */
static int dispatch(const char *mn, int bw, int nargs, uint64_t a0, uint64_t a1,
                    uint64_t a2, char *out, size_t outlen)
{
  uint64_t r;

  if (streq(mn, "MUL") && nargs == 2)
  {
    if (bw == 8)
    {
      r = neon_mul_8(a0, a1);
    }
    else if (bw == 16)
    {
      r = neon_mul_16(a0, a1);
    }
    else if (bw == 32)
    {
      r = neon_mul_32(a0, a1);
    }
    else
    {
      snprintf(out, outlen, "ERROR MUL: bw must be 8/16/32");
      return 1;
    }
  }
  else if (streq(mn, "MLA") && nargs == 3)
  {
    if (bw == 8)
    {
      r = neon_mla_8(a0, a1, a2);
    }
    else if (bw == 16)
    {
      r = neon_mla_16(a0, a1, a2);
    }
    else if (bw == 32)
    {
      r = neon_mla_32(a0, a1, a2);
    }
    else
    {
      snprintf(out, outlen, "ERROR MLA: bw must be 8/16/32");
      return 1;
    }
  }
  else if (streq(mn, "MLS") && nargs == 3)
  {
    if (bw == 8)
    {
      r = neon_mls_8(a0, a1, a2);
    }
    else if (bw == 16)
    {
      r = neon_mls_16(a0, a1, a2);
    }
    else if (bw == 32)
    {
      r = neon_mls_32(a0, a1, a2);
    }
    else
    {
      snprintf(out, outlen, "ERROR MLS: bw must be 8/16/32");
      return 1;
    }
  }
  else if (streq(mn, "SQDMULH") && nargs == 2)
  {
    if (bw == 16)
    {
      r = neon_sqdmulh_16(a0, a1);
    }
    else if (bw == 32)
    {
      r = neon_sqdmulh_32(a0, a1);
    }
    else
    {
      snprintf(out, outlen, "ERROR SQDMULH: bw must be 16/32");
      return 1;
    }
  }
  else if (streq(mn, "SQRDMULH") && nargs == 2)
  {
    if (bw == 16)
    {
      r = neon_sqrdmulh_16(a0, a1);
    }
    else if (bw == 32)
    {
      r = neon_sqrdmulh_32(a0, a1);
    }
    else
    {
      snprintf(out, outlen, "ERROR SQRDMULH: bw must be 16/32");
      return 1;
    }
  }
  else if (streq(mn, "SQRDMLAH") && nargs == 3)
  {
    if (bw == 16)
    {
      r = neon_sqrdmlah_16(a0, a1, a2);
    }
    else if (bw == 32)
    {
      r = neon_sqrdmlah_32(a0, a1, a2);
    }
    else
    {
      snprintf(out, outlen, "ERROR SQRDMLAH: bw must be 16/32");
      return 1;
    }
  }
  else if (streq(mn, "SHSUB") && nargs == 2)
  {
    if (bw == 8)
    {
      r = neon_shsub_8(a0, a1);
    }
    else if (bw == 16)
    {
      r = neon_shsub_16(a0, a1);
    }
    else if (bw == 32)
    {
      r = neon_shsub_32(a0, a1);
    }
    else
    {
      snprintf(out, outlen, "ERROR SHSUB: bw must be 8/16/32");
      return 1;
    }
  }
  else if (streq(mn, "SRSHR") && nargs == 2)
  {
    /* First arg is the shift amount k in [1, bw]; second is the lane. Reject
       out-of-range k here rather than relying on the case-table `default`,
       which would terminate the process via die() and break stream mode. */
    if (bw != 8 && bw != 16 && bw != 32)
    {
      snprintf(out, outlen, "ERROR SRSHR: bw must be 8/16/32");
      return 1;
    }
    if (a0 < 1 || a0 > (uint64_t)bw)
    {
      snprintf(out, outlen, "ERROR SRSHR: shift must be in [1,%d]", bw);
      return 1;
    }
    if (bw == 8)
    {
      r = neon_srshr_8((int)a0, a1);
    }
    else if (bw == 16)
    {
      r = neon_srshr_16((int)a0, a1);
    }
    else
    {
      r = neon_srshr_32((int)a0, a1);
    }
  }
  else if (streq(mn, "MULH") && nargs == 2)
  {
    if (bw != 64)
    {
      snprintf(out, outlen, "ERROR MULH: bw must be 64");
      return 1;
    }
    r = scalar_smulh_64(a0, a1);
  }
  else if (streq(mn, "UMULH") && nargs == 2)
  {
    if (bw != 64)
    {
      snprintf(out, outlen, "ERROR UMULH: bw must be 64");
      return 1;
    }
    r = scalar_umulh_64(a0, a1);
  }
  else
  {
    snprintf(out, outlen, "ERROR unsupported: %s %d arity=%d", mn, bw, nargs);
    return 1;
  }

  fmt_hex(bw, r, out, outlen);
  return 0;
}

/*
 * Parse a whitespace-separated tokenized line: MNEMONIC BITWIDTH ARG...
 * Mutates `line`. Returns number of tokens; -1 on too many.
 */
#define IS_SEP(c) ((c) == ' ' || (c) == '\t' || (c) == '\r' || (c) == '\n')

static int tokenize(char *line, char **toks, int max_toks)
{
  int n = 0;
  char *p = line;

  while (*p)
  {
    while (IS_SEP(*p))
    {
      p++;
    }
    if (!*p)
    {
      break;
    }
    if (n >= max_toks)
    {
      return -1;
    }
    toks[n++] = p;
    while (*p && !IS_SEP(*p))
    {
      p++;
    }
    if (*p)
    {
      *p++ = '\0';
    }
  }
  return n;
}

#undef IS_SEP

static int run_one_from_tokens(char **toks, int n, char *out, size_t outlen)
{
  const char *mn;
  int bw;
  int nargs;
  uint64_t a[3] = {0, 0, 0};
  char err[128];
  int i;

  if (n < 3)
  {
    snprintf(out, outlen, "ERROR expected: MNEMONIC BITWIDTH ARG...");
    return 1;
  }
  mn = toks[0];
  if (parse_int(toks[1], &bw) != 0)
  {
    snprintf(out, outlen, "ERROR bitwidth not an integer: %s", toks[1]);
    return 1;
  }
  nargs = n - 2;
  if (nargs > 3)
  {
    snprintf(out, outlen, "ERROR too many args");
    return 1;
  }

  for (i = 0; i < nargs; i++)
  {
    if (parse_arg(toks[2 + i], bw, &a[i], err, sizeof err) != 0)
    {
      snprintf(out, outlen, "ERROR %s", err);
      return 1;
    }
  }
  return dispatch(mn, bw, nargs, a[0], a[1], a[2], out, outlen);
}

/*
 * Print the offending input and exit. Any malformed input is treated as
 * fatal: the streaming conformance protocol is one-line-in / one-line-out,
 * so silently skipping or emitting a placeholder would cause the driver to
 * fall out of lockstep. The one-shot CLI applies the same policy.
 *
 * `original` is the un-tokenised input line, kept around because tokenize()
 * destructively NUL-terminates inside it. In one-shot mode there is no such
 * line (argv strings are untouched), so callers pass NULL and we print
 * "<argv>" instead.
 */
#if defined(__GNUC__) || defined(__clang__)
__attribute__((noreturn))
#endif
static void die_with_input(const char *reason, const char *original)
{
  if (original == NULL)
  {
    fprintf(stderr, "hw_exec: %s\n  input: <argv>\n", reason);
  }
  else
  {
    size_t len = strlen(original);
    fprintf(stderr, "hw_exec: %s\n  input: %s", reason, original);
    if (len == 0 || original[len - 1] != '\n')
    {
      fputc('\n', stderr);
    }
  }
  exit(1);
}

/*
 * Process a tokenised input case: dispatch, write the result to stdout, or
 * exit on error. `original` may be NULL when called from one-shot mode.
 */
static void process_tokens(char **toks, int n, const char *original)
{
  char out[OUT_BUF_SIZE];

  if (run_one_from_tokens(toks, n, out, sizeof out) != 0)
  {
    /* `out` now holds the diagnostic written by run_one_from_tokens. */
    die_with_input(out, original);
  }
  fputs(out, stdout);
  fputc('\n', stdout);
  fflush(stdout);
}

/*
 * Read one case from stdin into `line`, copy it to `original` for
 * diagnostics, and return the number of tokens. Returns 0 on blank line, -1
 * on EOF. Aborts on a too-long line or too-many-tokens line, since either
 * indicates a protocol violation we cannot recover from. `line` and
 * `original` must point at buffers of size at least LINE_BUF_SIZE.
 */
static int read_one_line(char *line, char *original, char **toks, int max_toks)
{
  int n;

  if (!fgets(line, LINE_BUF_SIZE, stdin))
  {
    return -1;
  }
  if (strchr(line, '\n') == NULL && !feof(stdin))
  {
    die_with_input("line too long", line);
  }
  memcpy(original, line, LINE_BUF_SIZE);

  n = tokenize(line, toks, max_toks);
  if (n < 0)
  {
    die_with_input("too many tokens", original);
  }
  return n;
}

/*
 * Drive the harness over its input. In stream mode we loop over stdin until
 * EOF; in one-shot mode we run a single case taken directly from argv and
 * return. The two modes share tokenisation, dispatch, output, and error
 * handling.
 */
static void run(int stream_mode, int argc, char **argv)
{
  if (stream_mode)
  {
    char line[LINE_BUF_SIZE];
    char original[LINE_BUF_SIZE];
    char *toks[MAX_TOKENS];
    int n;

    for (;;)
    {
      n = read_one_line(line, original, toks, MAX_TOKENS);
      if (n < 0)
      {
        return; /* EOF */
      }
      if (n == 0)
      {
        continue; /* blank line: no case, no output */
      }
      process_tokens(toks, n, original);
    }
  }
  else
  {
    /* One-shot: argv[1..argc-1] are the tokens. */
    process_tokens(argv + 1, argc - 1, NULL);
  }
}

int main(int argc, char **argv)
{
  if (argc == 2 && streq(argv[1], "--stream"))
  {
    run(1, 0, NULL);
    return 0;
  }
  if (argc < 4)
  {
    die("usage: hw_exec MNEMONIC BITWIDTH ARG... | hw_exec --stream");
  }
  run(0, argc, argv);
  return 0;
}
