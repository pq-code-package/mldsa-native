/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA Performance Benchmark for Cortex-M33
 *
 * Methodology: NTESTS iterations × NITERATIONS measurements per operation
 * Timing: SysTick (24-bit down-counter at processor clock)
 * Note: QEMU timing is approximate; use for relative comparisons only
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "../../../../mldsa/src/sign.h"
#include "../../../../mldsa/src/sys.h"
#include "../../../notrandombytes/notrandombytes.h"

#define NWARMUP 3
#define NITERATIONS 5
#define NTESTS 500
#define MLEN 59
#define CTXLEN 1

/*===========================================================================
 * Semihosting I/O
 *===========================================================================*/

static inline void semihost_print(const char *str)
{
  __asm__ volatile("mov r0, #0x04\n mov r1, %0\n bkpt 0xAB\n"
                   :
                   : "r"(str)
                   : "r0", "r1", "memory");
}

static inline void semihost_exit(int code)
{
  __asm__ volatile("mov r0, #0x18\n mov r1, %0\n bkpt 0xAB\n"
                   :
                   : "r"(code)
                   : "r0", "r1", "memory");
}

/*===========================================================================
 * SysTick Timer (24-bit down-counter)
 *
 * The ARM Cortex-M SysTick is a 24-bit down-counter that:
 * - Counts from RELOAD value (0x00FFFFFF) down to 0
 * - Reloads and continues counting
 * - Runs at processor clock speed when CLKSOURCE=1
 *
 * For timing: start > end normally (since it counts DOWN)
 * Wrap-around: if end > start, the counter wrapped from 0 to 0x00FFFFFF
 *===========================================================================*/

/* SysTick registers (ARMv8-M memory-mapped) */
#define SYST_CSR (*(volatile uint32_t *)0xE000E010) /* Control and Status */
#define SYST_RVR (*(volatile uint32_t *)0xE000E014) /* Reload Value */
#define SYST_CVR (*(volatile uint32_t *)0xE000E018) /* Current Value */

/* SysTick Control bits */
#define SYST_CSR_ENABLE (1UL << 0)    /* Counter enable */
#define SYST_CSR_CLKSOURCE (1UL << 2) /* 1 = processor clock */

/* Maximum count value (24-bit) */
#define SYSTICK_MAX 0x00FFFFFF

static inline void systick_init(void)
{
  SYST_CSR = 0;           /* Disable during setup */
  SYST_RVR = SYSTICK_MAX; /* Set reload to max (24-bit) */
  SYST_CVR = 0;           /* Clear current value (any write clears) */
  SYST_CSR = SYST_CSR_ENABLE | SYST_CSR_CLKSOURCE; /* Enable with CPU clock */
}

static inline uint32_t systick_get(void)
{
  return SYST_CVR & SYSTICK_MAX; /* Read current value (24-bit) */
}

/*
 * Calculate elapsed cycles for a DOWN-counter.
 *
 * SysTick counts: MAX -> MAX-1 -> ... -> 1 -> 0 -> MAX -> ...
 *
 * Normal case (no wrap): start > end
 *   elapsed = start - end
 *
 * Wrap case: end > start (counter wrapped from 0 to MAX)
 *   elapsed = start + (MAX + 1 - end) = start + 0x01000000 - end
 *
 * Note: With 24-bit counter at ~25MHz, wrap occurs every ~0.67 seconds.
 * ML-DSA operations can exceed this, so wrap handling is essential.
 */
static inline uint64_t measure_cycles(uint32_t start, uint32_t end)
{
  if (end <= start)
  {
    /* Normal case: no wrap-around */
    return (uint64_t)(start - end);
  }
  else
  {
    /* Wrap-around: counter went 0 -> MAX between readings */
    return (uint64_t)start + (uint64_t)(SYSTICK_MAX + 1 - end);
  }
}

/*===========================================================================
 * Output Helpers
 *===========================================================================*/

static void uint_to_str(uint64_t num, char *str)
{
  if (num == 0)
  {
    str[0] = '0';
    str[1] = '\0';
    return;
  }
  char temp[32];
  int i = 0;
  while (num > 0)
  {
    temp[i++] = '0' + (num % 10);
    num /= 10;
  }
  int j = 0;
  while (i > 0)
  {
    str[j++] = temp[--i];
  }
  str[j] = '\0';
}

static void print_avg(const char *txt, uint64_t cyc[NTESTS])
{
  uint64_t avg = 0;
  for (int i = 0; i < NTESTS; i++)
  {
    avg += cyc[i];
  }
  avg /= (NTESTS * NITERATIONS);

  char buf[32];
  semihost_print(txt);
  semihost_print(" cycles (avg) = ");
  uint_to_str(avg, buf);
  semihost_print(buf);
  semihost_print("\n");
}

static int percentiles[] = {1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 99};

static void print_percentile_legend(void)
{
  semihost_print("           percentile");
  for (unsigned i = 0; i < sizeof(percentiles) / sizeof(percentiles[0]); i++)
  {
    char buf[8];
    uint_to_str(percentiles[i], buf);
    semihost_print(" ");
    int len = 0;
    while (buf[len])
    {
      len++;
    }
    while (len < 7)
    {
      semihost_print(" ");
      len++;
    }
    semihost_print(buf);
  }
  semihost_print("\n");
}

static void print_percentiles(const char *txt, uint64_t cyc[NTESTS])
{
  semihost_print(txt);
  semihost_print(" percentiles:");
  for (unsigned i = 0; i < sizeof(percentiles) / sizeof(percentiles[0]); i++)
  {
    uint64_t val = cyc[NTESTS * percentiles[i] / 100] / NITERATIONS;
    char buf[16];
    uint_to_str(val, buf);
    semihost_print(" ");
    int len = 0;
    while (buf[len])
    {
      len++;
    }
    while (len < 7)
    {
      semihost_print(" ");
      len++;
    }
    semihost_print(buf);
  }
  semihost_print("\n");
}

static void bubble_sort_uint64(uint64_t *arr, int n)
{
  for (int i = 0; i < n - 1; i++)
  {
    for (int j = 0; j < n - i - 1; j++)
    {
      if (arr[j] > arr[j + 1])
      {
        uint64_t t = arr[j];
        arr[j] = arr[j + 1];
        arr[j + 1] = t;
      }
    }
  }
}

/*===========================================================================
 * Benchmark
 *===========================================================================*/

static int bench(void)
{
  uint8_t pk[MLDSA_CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[MLDSA_CRYPTO_SECRETKEYBYTES];
  uint8_t sig[MLDSA_CRYPTO_BYTES];
  uint8_t m[MLEN], ctx[CTXLEN];
  size_t siglen;
  uint32_t t0, t1;
  uint64_t cycles_kg[NTESTS], cycles_sign[NTESTS], cycles_verify[NTESTS];
  char buf[16];

  for (unsigned i = 0; i < MLEN; i++)
  {
    m[i] = (uint8_t)i;
  }
  for (unsigned i = 0; i < CTXLEN; i++)
  {
    ctx[i] = (uint8_t)(i + MLEN);
  }

  semihost_print("Running ");
  uint_to_str(NTESTS, buf);
  semihost_print(buf);
  semihost_print(" tests x ");
  uint_to_str(NITERATIONS, buf);
  semihost_print(buf);
  semihost_print(" iterations...\n\n");

  for (unsigned i = 0; i < NTESTS; i++)
  {
    int ret = 0;
    randombytes_reset();

    /* KeyGen */
    for (unsigned j = 0; j < NWARMUP; j++)
    {
      ret |= crypto_sign_keypair(pk, sk);
    }
    t0 = systick_get();
    for (unsigned j = 0; j < NITERATIONS; j++)
    {
      ret |= crypto_sign_keypair(pk, sk);
    }
    t1 = systick_get();
    cycles_kg[i] = measure_cycles(t0, t1);

    /* Sign */
    for (unsigned j = 0; j < NWARMUP; j++)
    {
      ret |= crypto_sign_signature(sig, &siglen, m, MLEN, ctx, CTXLEN, sk);
    }
    t0 = systick_get();
    for (unsigned j = 0; j < NITERATIONS; j++)
    {
      ret |= crypto_sign_signature(sig, &siglen, m, MLEN, ctx, CTXLEN, sk);
    }
    t1 = systick_get();
    cycles_sign[i] = measure_cycles(t0, t1);

    /* Verify */
    for (unsigned j = 0; j < NWARMUP; j++)
    {
      ret |= crypto_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk);
    }
    t0 = systick_get();
    for (unsigned j = 0; j < NITERATIONS; j++)
    {
      ret |= crypto_sign_verify(sig, siglen, m, MLEN, ctx, CTXLEN, pk);
    }
    t1 = systick_get();
    cycles_verify[i] = measure_cycles(t0, t1);

    if (ret != 0)
    {
      semihost_print("ERROR: Benchmark failed\n");
      return 1;
    }
    if ((i + 1) % 100 == 0)
    {
      semihost_print("Completed ");
      uint_to_str(i + 1, buf);
      semihost_print(buf);
      semihost_print(" tests\n");
    }
  }

  print_avg("   keypair", cycles_kg);
  print_avg("      sign", cycles_sign);
  print_avg("    verify", cycles_verify);
  semihost_print("\n");

  bubble_sort_uint64(cycles_kg, NTESTS);
  bubble_sort_uint64(cycles_sign, NTESTS);
  bubble_sort_uint64(cycles_verify, NTESTS);

  print_percentile_legend();
  semihost_print("\n");
  print_percentiles("   keypair", cycles_kg);
  semihost_print("\n");
  print_percentiles("      sign", cycles_sign);
  semihost_print("\n");
  print_percentiles("    verify", cycles_verify);

  return 0;
}

int main(void)
{
  char buf[32];

  semihost_print("\n=== ML-DSA Performance Benchmark ===\n");
  semihost_print("Platform: Cortex-M33 (QEMU mps2-an521)\n");
  semihost_print("Timer: SysTick (24-bit down-counter)\n");
  semihost_print("Parameter Set: ML-DSA-");
#if MLD_CONFIG_PARAMETER_SET == 44
  semihost_print("44\n");
#elif MLD_CONFIG_PARAMETER_SET == 65
  semihost_print("65\n");
#elif MLD_CONFIG_PARAMETER_SET == 87
  semihost_print("87\n");
#else
  semihost_print("Unknown\n");
#endif

  semihost_print("Measurements: ");
  uint_to_str(NTESTS * NITERATIONS, buf);
  semihost_print(buf);
  semihost_print(" per operation\n\n");

  systick_init();
  int result = bench();

  semihost_print(result == 0 ? "\n=== Benchmark Complete ===\n"
                             : "\n=== Benchmark Failed ===\n");
  semihost_exit(result);
  return result;
}
