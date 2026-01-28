/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * Minimal "hello world" test to validate Cortex-M33 MPS3-AN524 platform setup.
 * If this works but ML-DSA tests fail, the issue is likely stack/heap sizing.
 * If this fails, the platform setup itself is broken.
 */

#include <stdio.h>
#include <stdint.h>

/* Linker-provided symbols */
extern uint32_t __StackLimit;
extern uint32_t __StackTop;
extern uint32_t __RAM_BASE;
extern uint32_t __RAM_SIZE;

/* Get current stack pointer (ARM Cortex-M) */
static inline uint32_t get_msp(void) {
    uint32_t result;
    __asm volatile ("mrs %0, msp" : "=r" (result));
    return result;
}

int main(void) {
    printf("=== Cortex-M33 MPS3-AN524 Platform Validation ===\n");
    printf("Hello from Cortex-M33 MPS3-AN524!\n\n");
    
    /* Memory layout info */
    printf("Memory Layout:\n");
    printf("  Stack Top:   0x%08lX\n", (unsigned long)&__StackTop);
    printf("  Stack Limit: 0x%08lX\n", (unsigned long)&__StackLimit);
    printf("  Stack Size:  %lu bytes (%lu KB)\n", 
           (unsigned long)&__StackTop - (unsigned long)&__StackLimit,
           ((unsigned long)&__StackTop - (unsigned long)&__StackLimit) / 1024);
    printf("  Current SP:  0x%08lX\n", (unsigned long)get_msp());
    printf("\n");
    
    /* Basic sanity checks */
    uint32_t sp = get_msp();
    uint32_t stack_top = (uint32_t)&__StackTop;
    uint32_t stack_limit = (uint32_t)&__StackLimit;
    
    if (sp > stack_top || sp < stack_limit) {
        printf("ERROR: Stack pointer 0x%08lX outside stack region!\n", (unsigned long)sp);
        return 1;
    }
    
    printf("Stack pointer is within valid range.\n");
    printf("Platform setup validated successfully!\n");
    
    return 0;
}
