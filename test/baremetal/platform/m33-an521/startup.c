/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * Startup code for Cortex-M33 on MPS2-AN521 (QEMU/FPGA)
 *
 * Hardware Reference:
 *   ARM DAI 0521A - Application Note AN521 "SMM-SSE-200 for MPS2+"
 *   https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/DAI0521A_example_sse200_subsystem_for_v2m_mps2.pdf
 *
 * Interrupt Map: Table 7-1 (124 IRQs per CPU: 92 expansion + 32 base)
 * Memory Map: Tables 3-1 through 3-6
 */

#include <stddef.h>
#include <stdint.h>

/*===========================================================================
 * Linker Script Symbols
 *===========================================================================*/

/* CMSIS-style copy/zero tables for data initialization */
extern uint32_t __copy_table_start__;
extern uint32_t __copy_table_end__;
extern uint32_t __zero_table_start__;
extern uint32_t __zero_table_end__;
extern uint32_t __StackTop;

/* Legacy symbols (for toolchains that don't use tables) */
extern uint32_t _etext;
extern uint32_t _sdata, _edata;
extern uint32_t _sbss, _ebss;
extern uint32_t _estack;

/* C++ initialization arrays */
extern void (*__preinit_array_start[])(void);
extern void (*__preinit_array_end[])(void);
extern void (*__init_array_start[])(void);
extern void (*__init_array_end[])(void);
extern void (*__fini_array_start[])(void);
extern void (*__fini_array_end[])(void);

/*===========================================================================
 * Configuration
 *===========================================================================*/

#ifndef USE_COPY_ZERO_TABLES
#define USE_COPY_ZERO_TABLES \
  1 /* Use CMSIS-style tables (vs legacy direct copy) */
#endif

#ifndef ENABLE_CPP_SUPPORT
#define ENABLE_CPP_SUPPORT 1
#endif

#ifndef ENABLE_FPU
#define ENABLE_FPU 1 /* Cortex-M33 has optional FPU */
#endif

/*===========================================================================
 * Forward Declarations
 *===========================================================================*/

extern int main(int argc, char **argv);
void SystemInit(void) __attribute__((weak));
void Reset_Handler(void);
void Default_Handler(void);

/*===========================================================================
 * Cortex-M33 System Control Block
 *===========================================================================*/

#define SCB_BASE (0xE000ED00UL)
#define SCB_CPACR \
  (*(volatile uint32_t *)(SCB_BASE + 0x88)) /* Coprocessor Access */
#define SCB_CCR \
  (*(volatile uint32_t *)(SCB_BASE + 0x14)) /* Config and Control */
#define SCB_SHCSR \
  (*(volatile uint32_t *)(SCB_BASE + 0x24)) /* Handler Control */

/* FPU enable bits (CP10 and CP11 full access) */
#define CPACR_CP10_FULL (3UL << 20)
#define CPACR_CP11_FULL (3UL << 22)

/* CCR bits */
#define CCR_STKALIGN (1UL << 9) /* 8-byte stack alignment for AAPCS */

/* SHCSR bits - fault handler enables */
#define SHCSR_MEMFAULTENA (1UL << 16)
#define SHCSR_BUSFAULTENA (1UL << 17)
#define SHCSR_USGFAULTENA (1UL << 18)
#define SHCSR_SECUREFAULTENA (1UL << 19)

/*===========================================================================
 * Exception Handlers (Weak Aliases to Default_Handler)
 *===========================================================================*/

/* Cortex-M33 Core Exceptions */
void NMI_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void HardFault_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void MemManage_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void BusFault_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UsageFault_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void SecureFault_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void SVC_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void DebugMon_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void PendSV_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void SysTick_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));

/* MPS2-AN521 External Interrupts (Table 7-1) */
void UART0_RX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UART0_TX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UART1_RX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UART1_TX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UART2_RX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void UART2_TX_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void GPIO0_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void GPIO1_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void GPIO2_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void GPIO3_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void TIMER0_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void TIMER1_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void DUALTIMER_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void MPC_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void PPC_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void MSC_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void BRIDGE_ERROR_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));

/* Reserved/placeholder IRQ handlers */
void IRQ17_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ18_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ19_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ20_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ21_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ22_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ23_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ24_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ25_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ26_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ27_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ28_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ29_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ30_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));
void IRQ31_Handler(void)
    __attribute__((weak, alias("Default_Handler"), noreturn));

/*===========================================================================
 * Vector Table
 *===========================================================================*/

__attribute__((section(".vectors"), used)) const void *__vector_table[] = {
    /* Cortex-M33 Core Exceptions (0-15) */
    &__StackTop,         /*  0: Initial Stack Pointer */
    Reset_Handler,       /*  1: Reset */
    NMI_Handler,         /*  2: NMI */
    HardFault_Handler,   /*  3: Hard Fault */
    MemManage_Handler,   /*  4: MPU Fault */
    BusFault_Handler,    /*  5: Bus Fault */
    UsageFault_Handler,  /*  6: Usage Fault */
    SecureFault_Handler, /*  7: Secure Fault (M33 TrustZone) */
    0, 0, 0,             /*  8-10: Reserved */
    SVC_Handler,         /* 11: SVCall */
    DebugMon_Handler,    /* 12: Debug Monitor */
    0,                   /* 13: Reserved */
    PendSV_Handler,      /* 14: PendSV */
    SysTick_Handler,     /* 15: SysTick */

    /* External Interrupts (16+) - MPS2-AN521 specific */
    UART0_RX_Handler,     /* 16 */
    UART0_TX_Handler,     /* 17 */
    UART1_RX_Handler,     /* 18 */
    UART1_TX_Handler,     /* 19 */
    UART2_RX_Handler,     /* 20 */
    UART2_TX_Handler,     /* 21 */
    GPIO0_Handler,        /* 22 */
    GPIO1_Handler,        /* 23 */
    TIMER0_Handler,       /* 24 */
    TIMER1_Handler,       /* 25 */
    DUALTIMER_Handler,    /* 26 */
    MPC_Handler,          /* 27 */
    PPC_Handler,          /* 28 */
    MSC_Handler,          /* 29 */
    BRIDGE_ERROR_Handler, /* 30 */
    IRQ31_Handler,        /* 31 */
    GPIO2_Handler,        /* 32 */
    GPIO3_Handler,        /* 33 */
    IRQ17_Handler,        /* 34 */
    IRQ18_Handler,        /* 35 */
    IRQ19_Handler,        /* 36 */
    IRQ20_Handler,        /* 37 */
    IRQ21_Handler,        /* 38 */
    IRQ22_Handler,        /* 39 */
    IRQ23_Handler,        /* 40 */
    IRQ24_Handler,        /* 41 */
    IRQ25_Handler,        /* 42 */
    IRQ26_Handler,        /* 43 */
    IRQ27_Handler,        /* 44 */
    IRQ28_Handler,        /* 45 */
    IRQ29_Handler,        /* 46 */
    IRQ30_Handler,        /* 47 */
};

/*===========================================================================
 * Default Handler - catches unhandled exceptions
 *===========================================================================*/

__attribute__((noreturn)) void Default_Handler(void)
{
#ifdef SEMIHOSTING
  const char *msg = "FAULT: Unhandled exception\n";
  uint32_t args[3] = {2, (uint32_t)msg, 27}; /* fd=stderr */
  __asm__ volatile("mov r0, #0x05\n mov r1, %0\n bkpt 0xAB\n"
                   :
                   : "r"(args)
                   : "r0", "r1", "memory");
#endif
  while (1)
  {
    __asm__ volatile("wfi"); /* Low-power wait */
  }
}

/*===========================================================================
 * System Initialization (weak - can be overridden)
 *===========================================================================*/

__attribute__((weak)) void SystemInit(void)
{
#if ENABLE_FPU
  SCB_CPACR |= (CPACR_CP10_FULL | CPACR_CP11_FULL);
  __asm__ volatile("dsb\n isb");
#endif

  SCB_CCR |= CCR_STKALIGN; /* 8-byte stack alignment for exceptions */
  SCB_SHCSR |= (SHCSR_MEMFAULTENA | SHCSR_BUSFAULTENA | SHCSR_USGFAULTENA);

#ifdef __ARM_FEATURE_CMSE
  SCB_SHCSR |= SHCSR_SECUREFAULTENA; /* TrustZone active */
#endif

  __asm__ volatile("dsb\n isb");
}

/*===========================================================================
 * Data Initialization
 *===========================================================================*/

#if USE_COPY_ZERO_TABLES

/* Copy .data from FLASH to RAM using linker-generated table */
static void copy_table_init(void)
{
  uint32_t const *table = &__copy_table_start__;
  while (table < &__copy_table_end__)
  {
    uint32_t const *src = (uint32_t const *)(table[0]);
    uint32_t *dst = (uint32_t *)(table[1]);
    uint32_t count = table[2];
    for (uint32_t i = 0; i < count; i++)
    {
      dst[i] = src[i];
    }
    table += 3;
  }
}

/* Zero .bss using linker-generated table */
static void zero_table_init(void)
{
  uint32_t const *table = &__zero_table_start__;
  while (table < &__zero_table_end__)
  {
    uint32_t *dst = (uint32_t *)(table[0]);
    uint32_t count = table[1];
    for (uint32_t i = 0; i < count; i++)
    {
      dst[i] = 0;
    }
    table += 2;
  }
}

#else /* Legacy direct initialization */

static void data_init(void)
{
  uint32_t *src = &_etext;
  uint32_t *dst = &_sdata;
  while (dst < &_edata)
  {
    *dst++ = *src++;
  }
}

static void bss_init(void)
{
  uint32_t *dst = &_sbss;
  while (dst < &_ebss)
  {
    *dst++ = 0;
  }
}

#endif /* USE_COPY_ZERO_TABLES */

/*===========================================================================
 * C++ Runtime Support
 *===========================================================================*/

#if ENABLE_CPP_SUPPORT

/* Call preinit_array then init_array (constructors) */
static void call_init_array(void)
{
  size_t count = __preinit_array_end - __preinit_array_start;
  for (size_t i = 0; i < count; i++)
  {
    __preinit_array_start[i]();
  }

  count = __init_array_end - __init_array_start;
  for (size_t i = 0; i < count; i++)
  {
    __init_array_start[i]();
  }
}

/* Call fini_array in reverse order (destructors) */
static void call_fini_array(void)
{
  size_t count = __fini_array_end - __fini_array_start;
  for (size_t i = count; i > 0; i--)
  {
    __fini_array_start[i - 1]();
  }
}

/* Pure virtual function handler - called if pure virtual invoked */
void __attribute__((weak, noreturn)) __cxa_pure_virtual(void)
{
  while (1)
  {
    __asm__ volatile("wfi");
  }
}

/* C++11 thread-safe static initialization guards (single-threaded impl) */
int __attribute__((weak)) __cxa_guard_acquire(uint32_t *guard)
{
  return (*guard == 0) ? 1 : 0;
}

void __attribute__((weak)) __cxa_guard_release(uint32_t *guard) { *guard = 1; }

void __attribute__((weak)) __cxa_guard_abort(uint32_t *guard) { (void)guard; }

#endif /* ENABLE_CPP_SUPPORT */

/*===========================================================================
 * Reset Handler
 *===========================================================================*/

__attribute__((noreturn, naked)) void Reset_Handler(void)
{
  __asm__ volatile(
      "ldr r0, =__StackTop\n" /* Set stack pointer (some debuggers need this) */
      "msr msp, r0\n"
      "bl Reset_Handler_C\n");
}

/* C portion of Reset Handler - proper stack frame */
__attribute__((noreturn, used)) void Reset_Handler_C(void)
{
  SystemInit(); /* FPU, fault handlers, etc. */

#if USE_COPY_ZERO_TABLES
  copy_table_init();
  zero_table_init();
#else
  data_init();
  bss_init();
#endif

#if ENABLE_CPP_SUPPORT
  call_init_array();
#endif

  int ret = main(0, NULL);

#if ENABLE_CPP_SUPPORT
  call_fini_array();
#endif

#ifdef SEMIHOSTING
  extern void semihosting_exit(int code);
  semihosting_exit(ret);
#else
  (void)ret;
#endif

  while (1)
  {
    __asm__ volatile("wfi");
  }
}

/*===========================================================================
 * Semihosting Support
 *===========================================================================*/

#ifdef SEMIHOSTING

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
 * Newlib Syscall Stubs (Semihosting)
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

/*===========================================================================
 * Wrapped Main Support
 *===========================================================================*/

#ifdef USE_WRAPPED_MAIN
extern int __real_main(int argc, char **argv);

int __wrap_main(int argc, char **argv) { return __real_main(argc, argv); }
#endif

/*===========================================================================
 * Alternative Entry Point
 *===========================================================================*/

void _start(void) __attribute__((weak, alias("Reset_Handler"), noreturn));
