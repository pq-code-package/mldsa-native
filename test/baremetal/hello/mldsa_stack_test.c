/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * ML-DSA stack usage measurement for Cortex-M33 MPS3-AN524.
 * Uses stack painting to measure actual stack consumption of each API.
 *
 * This provides real measurements instead of estimates.
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "mldsa_native.h"

/* Linker-provided symbols */
extern uint32_t __StackLimit;
extern uint32_t __StackTop;

#define STACK_PATTERN 0xDEADBEEF

/* Get current stack pointer (ARM Cortex-M) */
static inline uint32_t get_msp(void) {
    uint32_t result;
    __asm volatile ("mrs %0, msp" : "=r" (result));
    return result;
}

/*
 * Paint the unused portion of the stack with a known pattern.
 * We leave a safety margin below the current SP.
 */
static void paint_stack(void) {
    volatile uint32_t *ptr = (uint32_t*)&__StackLimit;
    uint32_t current_sp = get_msp();
    
    /* Paint from stack limit up to 512 bytes below current SP (safety margin) */
    while ((uint32_t)ptr < (current_sp - 512)) {
        *ptr++ = STACK_PATTERN;
    }
}

/*
 * Measure stack usage by finding the first unpainted word.
 * Returns the number of bytes used (high water mark).
 */
static uint32_t measure_stack_usage(void) {
    volatile uint32_t *ptr = (uint32_t*)&__StackLimit;
    uint32_t *top = (uint32_t*)&__StackTop;
    
    /* Find first word that's not the pattern (high water mark) */
    while (ptr < top && *ptr == STACK_PATTERN) {
        ptr++;
    }
    
    return (uint32_t)top - (uint32_t)ptr;
}

/* Test data */
static unsigned char pk[CRYPTO_PUBLICKEYBYTES];
static unsigned char sk[CRYPTO_SECRETKEYBYTES];
static unsigned char sig[CRYPTO_BYTES];
static const unsigned char msg[] = "Test message for ML-DSA stack measurement on Cortex-M33";
static const unsigned char ctx[] = "test context";

static int __attribute__((noinline)) test_keygen(void) {
    return crypto_sign_keypair(pk, sk);
}

static int __attribute__((noinline)) test_sign(void) {
    size_t siglen;
    return crypto_sign_signature(sig, &siglen, msg, sizeof(msg) - 1, ctx, sizeof(ctx) - 1, sk);
}

static int __attribute__((noinline)) test_verify(void) {
    return crypto_sign_verify(sig, CRYPTO_BYTES, msg, sizeof(msg) - 1, ctx, sizeof(ctx) - 1, pk);
}

int main(void) {
    uint32_t stack_size = (uint32_t)&__StackTop - (uint32_t)&__StackLimit;
    uint32_t baseline, keygen_usage, sign_usage, verify_usage;
    
    printf("=== ML-DSA Stack Usage Measurement ===\n");
    printf("Platform: Cortex-M33 MPS3-AN524\n");
    printf("Parameter Set: ML-DSA-%d\n\n", 
#if MLDSA_MODE == 2
           44
#elif MLDSA_MODE == 3
           65
#elif MLDSA_MODE == 5
           87
#else
           0
#endif
    );
    
    printf("Stack Configuration:\n");
    printf("  Stack Top:   0x%08lX\n", (unsigned long)&__StackTop);
    printf("  Stack Limit: 0x%08lX\n", (unsigned long)&__StackLimit);
    printf("  Stack Size:  %lu bytes (%lu KB)\n\n", 
           (unsigned long)stack_size, (unsigned long)stack_size / 1024);
    
    /* Measure baseline */
    paint_stack();
    baseline = measure_stack_usage();
    printf("Baseline stack usage: %lu bytes\n\n", (unsigned long)baseline);
    
    /* Measure KeyGen */
    printf("Measuring KeyGen...\n");
    paint_stack();
    test_keygen();
    keygen_usage = measure_stack_usage();
    printf("  KeyGen stack: %lu bytes (%lu KB)\n\n", 
           (unsigned long)keygen_usage, (unsigned long)keygen_usage / 1024);
    
    /* Measure Sign */
    printf("Measuring Sign...\n");
    paint_stack();
    test_sign();
    sign_usage = measure_stack_usage();
    printf("  Sign stack: %lu bytes (%lu KB)\n\n", 
           (unsigned long)sign_usage, (unsigned long)sign_usage / 1024);
    
    /* Measure Verify */
    printf("Measuring Verify...\n");
    paint_stack();
    test_verify();
    verify_usage = measure_stack_usage();
    printf("  Verify stack: %lu bytes (%lu KB)\n\n", 
           (unsigned long)verify_usage, (unsigned long)verify_usage / 1024);
    
    /* Summary */
    uint32_t peak = keygen_usage;
    if (sign_usage > peak) peak = sign_usage;
    if (verify_usage > peak) peak = verify_usage;
    
    printf("=== Summary ===\n");
    printf("  KeyGen: %6lu bytes (%2lu KB)\n", (unsigned long)keygen_usage, (unsigned long)keygen_usage / 1024);
    printf("  Sign:   %6lu bytes (%2lu KB)\n", (unsigned long)sign_usage, (unsigned long)sign_usage / 1024);
    printf("  Verify: %6lu bytes (%2lu KB)\n", (unsigned long)verify_usage, (unsigned long)verify_usage / 1024);
    printf("  Peak:   %6lu bytes (%2lu KB)\n\n", (unsigned long)peak, (unsigned long)peak / 1024);
    
    printf("Stack available: %lu KB\n", (unsigned long)stack_size / 1024);
    printf("Stack headroom:  %lu KB (%lu%%)\n", 
           (unsigned long)(stack_size - peak) / 1024,
           (unsigned long)((stack_size - peak) * 100 / stack_size));
    
    if (peak > stack_size) {
        printf("\nWARNING: Peak usage exceeds stack size!\n");
        return 1;
    }
    
    printf("\nStack measurement completed successfully!\n");
    return 0;
}
