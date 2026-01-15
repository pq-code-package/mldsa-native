/******************************************************************************
 * @file     startup_ARMCM33.c
 * @brief    CMSIS-Core Device Startup File for
 *           Arm Cortex-M33 Device on MPS3 AN524
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

#include <stddef.h>

#if defined(ARMCM33)
#include "ARMCM33.h"
#else
#error device not specified!
#endif

/*---------------------------------------------------------------------------
  External References
 *---------------------------------------------------------------------------*/
extern uint32_t __INITIAL_SP;
extern uint32_t __STACK_LIMIT;
extern uint32_t __StackTop;
#if defined(__ARM_FEATURE_CMSE) && (__ARM_FEATURE_CMSE == 3U)
extern uint32_t __STACK_SEAL;
#endif

/* C library entry point */
extern int main(int argc, char *argv[]);

/*---------------------------------------------------------------------------
  Internal References
 *---------------------------------------------------------------------------*/
__NO_RETURN void Reset_Handler(void);
void Default_Handler(void);

/*---------------------------------------------------------------------------
  Default Handler for Exceptions / Interrupts
 *---------------------------------------------------------------------------*/
void Default_Handler(void)
{
  while (1)
    ;
}

/*---------------------------------------------------------------------------
  Exception / Interrupt Handler
 *---------------------------------------------------------------------------*/
/* Exceptions */
void NMI_Handler(void) __attribute__((weak, alias("Default_Handler")));
void HardFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void MemManage_Handler(void) __attribute__((weak, alias("Default_Handler")));
void BusFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UsageFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SecureFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SVC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void DebugMon_Handler(void) __attribute__((weak, alias("Default_Handler")));
void PendSV_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SysTick_Handler(void) __attribute__((weak, alias("Default_Handler")));

/* External Interrupts - MPS3 AN524 specific */
void UART0_RX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART0_TX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART1_RX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART1_TX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART2_RX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART2_TX_Handler(void) __attribute__((weak, alias("Default_Handler")));
void GPIO0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void GPIO1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void TIMER0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void TIMER1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void DUALTIMER_Handler(void) __attribute__((weak, alias("Default_Handler")));
void MPC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void PPC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void MSC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void BRIDGE_ERROR_Handler(void) __attribute__((weak, alias("Default_Handler")));
void GPIO2_Handler(void) __attribute__((weak, alias("Default_Handler")));
void GPIO3_Handler(void) __attribute__((weak, alias("Default_Handler")));

/* Generic interrupt handlers for unused slots */
void Interrupt17_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt18_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt19_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt20_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt21_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt22_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt23_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt24_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt25_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt26_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt27_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt28_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt29_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt30_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Interrupt31_Handler(void) __attribute__((weak, alias("Default_Handler")));

/*---------------------------------------------------------------------------
  Exception / Interrupt Vector table
 *---------------------------------------------------------------------------*/

#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#endif

extern const void *__VECTOR_TABLE[240];
const void *__VECTOR_TABLE[240] __VECTOR_TABLE_ATTRIBUTE = {
    (void *)(&__StackTop), /*     Initial Stack Pointer */
    Reset_Handler,         /*     Reset Handler */
    NMI_Handler,           /* -14 NMI Handler */
    HardFault_Handler,     /* -13 Hard Fault Handler */
    MemManage_Handler,     /* -12 MPU Fault Handler */
    BusFault_Handler,      /* -11 Bus Fault Handler */
    UsageFault_Handler,    /* -10 Usage Fault Handler */
    SecureFault_Handler,   /*  -9 Secure Fault Handler */
    0,                     /*     Reserved */
    0,                     /*     Reserved */
    0,                     /*     Reserved */
    SVC_Handler,           /*  -5 SVCall Handler */
    DebugMon_Handler,      /*  -4 Debug Monitor Handler */
    0,                     /*     Reserved */
    PendSV_Handler,        /*  -2 PendSV Handler */
    SysTick_Handler,       /*  -1 SysTick Handler */

    /* External Interrupts */
    UART0_RX_Handler,     /*   0 UART 0 receive interrupt */
    UART0_TX_Handler,     /*   1 UART 0 transmit interrupt */
    UART1_RX_Handler,     /*   2 UART 1 receive interrupt */
    UART1_TX_Handler,     /*   3 UART 1 transmit interrupt */
    UART2_RX_Handler,     /*   4 UART 2 receive interrupt */
    UART2_TX_Handler,     /*   5 UART 2 transmit interrupt */
    GPIO0_Handler,        /*   6 GPIO 0 combined interrupt */
    GPIO1_Handler,        /*   7 GPIO 1 combined interrupt */
    TIMER0_Handler,       /*   8 Timer 0 interrupt */
    TIMER1_Handler,       /*   9 Timer 1 interrupt */
    DUALTIMER_Handler,    /*  10 Dual timer interrupt */
    MPC_Handler,          /*  11 MPC combined (S + NS) interrupt */
    PPC_Handler,          /*  12 PPC combined (S + NS) interrupt */
    MSC_Handler,          /*  13 MSC combined (S + NS) interrupt */
    BRIDGE_ERROR_Handler, /*  14 Bridge error combined interrupt */
    0,                    /*  15 Reserved */
    GPIO2_Handler,        /*  16 GPIO 2 combined interrupt */
    GPIO3_Handler,        /*  17 GPIO 3 combined interrupt */
    Interrupt17_Handler,  /*  18 */
    Interrupt18_Handler,  /*  19 */
    Interrupt19_Handler,  /*  20 */
    Interrupt20_Handler,  /*  21 */
    Interrupt21_Handler,  /*  22 */
    Interrupt22_Handler,  /*  23 */
    Interrupt23_Handler,  /*  24 */
    Interrupt24_Handler,  /*  25 */
    Interrupt25_Handler,  /*  26 */
    Interrupt26_Handler,  /*  27 */
    Interrupt27_Handler,  /*  28 */
    Interrupt28_Handler,  /*  29 */
    Interrupt29_Handler,  /*  30 */
    Interrupt30_Handler,  /*  31 */
    Interrupt31_Handler   /*  32 */
                          /* Interrupts 33 .. 239 are left out */
};

#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

/*---------------------------------------------------------------------------
  Reset Handler called on controller reset
 *---------------------------------------------------------------------------*/
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
  /* Use CMSIS __PROGRAM_START which handles:
   * 1. Copy .data from flash to RAM
   * 2. Zero .bss section
   * 3. Call __libc_init_array (C++ constructors, stdio init)
   * 4. Call main()
   * 5. Call exit() on return
   */
  SystemInit(); /* CMSIS System Initialization */

  /* __PROGRAM_START is defined in cmsis_gcc.h and handles all initialization */
  extern void __PROGRAM_START(void);
  __PROGRAM_START();

  /* Should not reach here - __PROGRAM_START calls exit() */
  while (1)
  {
    __asm__ volatile("wfi");
  }
}

/*---------------------------------------------------------------------------
  Wrapped Main Support
 *---------------------------------------------------------------------------*/

/* Note: __wrap_main is provided by cmdline.c for command line argument
 * processing. The linker --wrap=main option redirects main() calls to
 * __wrap_main(), which then calls __real_main() with processed arguments.
 */
