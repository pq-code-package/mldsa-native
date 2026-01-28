/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * Stack usage measurement test for Cortex-M33 MPS3-AN524.
 * Paints the stack with a known pattern, runs some work, then measures
 * how much stack was actually used (high water mark).
 *
 * Use this to determine if ML-DSA tests need more stack space.
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>

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
    
    /* Paint from stack limit up to 256 bytes below current SP (safety margin) */
    while ((uint32_t)ptr < (current_sp - 256)) {
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

/*
 * A function that uses a known amount of stack space.
 * Each recursion level uses ~256 bytes.
 */
static void __attribute__((noinline)) stack_hungry_function(int depth) {
    volatile char buffer[256];  /* Force stack allocation */
    
    /* Prevent optimization - use buffer to avoid warning */
    buffer[0] = (char)depth;
    buffer[255] = (char)(depth + 1);
    (void)buffer[0];  /* Suppress unused warning */
    
    if (depth > 0) {
        stack_hungry_function(depth - 1);
    }
}

/*
 * Simulate some polynomial operations (like ML-DSA uses).
 * This gives a rough idea of stack usage for crypto operations.
 */
static void __attribute__((noinline)) simulate_poly_ops(void) {
    /* Simulate a polynomial (256 coefficients, 4 bytes each = 1KB) */
    volatile int32_t poly[256];
    
    for (int i = 0; i < 256; i++) {
        poly[i] = i * 3 + 1;
    }
    
    /* Simulate some operations */
    volatile int32_t sum = 0;
    for (int i = 0; i < 256; i++) {
        sum += poly[i];
    }
    
    /* Prevent optimization */
    (void)sum;
}

int main(void) {
    uint32_t stack_size = (uint32_t)&__StackTop - (uint32_t)&__StackLimit;
    uint32_t used_before, used_after;
    
    printf("=== Stack Usage Test for Cortex-M33 MPS3-AN524 ===\n\n");
    
    printf("Stack Configuration:\n");
    printf("  Stack Top:   0x%08lX\n", (unsigned long)&__StackTop);
    printf("  Stack Limit: 0x%08lX\n", (unsigned long)&__StackLimit);
    printf("  Stack Size:  %lu bytes (%lu KB)\n", 
           (unsigned long)stack_size, (unsigned long)stack_size / 1024);
    printf("  Current SP:  0x%08lX\n\n", (unsigned long)get_msp());
    
    /* Paint the stack */
    printf("Painting stack with pattern 0x%08X...\n", STACK_PATTERN);
    paint_stack();
    
    /* Measure baseline */
    used_before = measure_stack_usage();
    printf("Baseline stack usage: %lu bytes\n\n", (unsigned long)used_before);
    
    /* Test 1: Recursive function */
    printf("Test 1: Calling stack_hungry_function(10)...\n");
    stack_hungry_function(10);
    used_after = measure_stack_usage();
    printf("  Stack used: %lu bytes (+%lu from baseline)\n\n", 
           (unsigned long)used_after, 
           (unsigned long)(used_after - used_before));
    
    /* Repaint for next test */
    paint_stack();
    used_before = measure_stack_usage();
    
    /* Test 2: Polynomial simulation */
    printf("Test 2: Simulating polynomial operations...\n");
    simulate_poly_ops();
    used_after = measure_stack_usage();
    printf("  Stack used: %lu bytes (+%lu from baseline)\n\n", 
           (unsigned long)used_after,
           (unsigned long)(used_after - used_before));
    
    /* Summary */
    uint32_t stack_free = stack_size - used_after;
    printf("Summary:\n");
    printf("  Total stack:     %lu bytes (%lu KB)\n", 
           (unsigned long)stack_size, (unsigned long)stack_size / 1024);
    printf("  Peak usage:      %lu bytes (%lu KB)\n", 
           (unsigned long)used_after, (unsigned long)used_after / 1024);
    printf("  Stack remaining: %lu bytes (%lu KB)\n", 
           (unsigned long)stack_free, (unsigned long)stack_free / 1024);
    printf("  Usage percent:   %lu%%\n\n", 
           (unsigned long)(used_after * 100 / stack_size));
    
    /* ML-DSA stack requirements estimate */
    printf("ML-DSA Stack Requirements (estimated):\n");
    printf("  ML-DSA-44: ~32KB\n");
    printf("  ML-DSA-65: ~48KB\n");
    printf("  ML-DSA-87: ~64KB\n");
    printf("  Current stack: %lu KB\n\n", (unsigned long)stack_size / 1024);
    
    printf("Note: ML-DSA uses static allocation (no heap).\n");
    printf("Stack is the primary memory resource to validate.\n\n");
    
    if (stack_size >= 64 * 1024) {
        printf("Stack size should be sufficient for ML-DSA-87.\n");
    } else if (stack_size >= 48 * 1024) {
        printf("Stack size should be sufficient for ML-DSA-65.\n");
    } else if (stack_size >= 32 * 1024) {
        printf("Stack size should be sufficient for ML-DSA-44.\n");
    } else {
        printf("WARNING: Stack may be too small for ML-DSA!\n");
        printf("Consider increasing __STACK_SIZE in linker script.\n");
    }
    
    printf("\nStack test completed successfully!\n");
    return 0;
}
