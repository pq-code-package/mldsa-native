/******************************************************************************
 * @file     ARMCM33.h
 * @brief    CMSIS-Core Device Peripheral Access Layer Header File for
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

#ifndef ARMCM33_H
#define ARMCM33_H

#ifdef __cplusplus
extern "C"
{
#endif

  /*----------------------------- Interrupt Number Definition
   * -------------------------*/

  typedef enum IRQn
  {
    /* ===================== Cortex-M33 Specific Interrupt Numbers
       ==================== */
    NonMaskableInt_IRQn = -14,   /*!< -14 Non Maskable Interrupt           */
    HardFault_IRQn = -13,        /*!< -13 HardFault Interrupt              */
    MemoryManagement_IRQn = -12, /*!< -12 Memory Management Interrupt      */
    BusFault_IRQn = -11,         /*!< -11 Bus Fault Interrupt              */
    UsageFault_IRQn = -10,       /*!< -10 Usage Fault Interrupt            */
    SecureFault_IRQn = -9,       /*!<  -9 Secure Fault Interrupt           */
    SVCall_IRQn = -5,            /*!<  -5 SV Call Interrupt                */
    DebugMonitor_IRQn = -4,      /*!<  -4 Debug Monitor Interrupt          */
    PendSV_IRQn = -2,            /*!<  -2 Pend SV Interrupt                */
    SysTick_IRQn = -1,           /*!<  -1 System Tick Interrupt            */

    /* ==================== MPS3 AN524 Specific Interrupt Numbers
       ==================== */
    UART0_RX_IRQn = 0,      /*!<   0 UART 0 receive interrupt         */
    UART0_TX_IRQn = 1,      /*!<   1 UART 0 transmit interrupt        */
    UART1_RX_IRQn = 2,      /*!<   2 UART 1 receive interrupt         */
    UART1_TX_IRQn = 3,      /*!<   3 UART 1 transmit interrupt        */
    UART2_RX_IRQn = 4,      /*!<   4 UART 2 receive interrupt         */
    UART2_TX_IRQn = 5,      /*!<   5 UART 2 transmit interrupt        */
    GPIO0_IRQn = 6,         /*!<   6 GPIO 0 combined interrupt        */
    GPIO1_IRQn = 7,         /*!<   7 GPIO 1 combined interrupt        */
    TIMER0_IRQn = 8,        /*!<   8 TIMER 0 interrupt                */
    TIMER1_IRQn = 9,        /*!<   9 TIMER 1 interrupt                */
    DUALTIMER_IRQn = 10,    /*!<  10 Dual timer interrupt             */
    MPC_IRQn = 11,          /*!<  11 MPC combined (S + NS) interrupt  */
    PPC_IRQn = 12,          /*!<  12 PPC combined (S + NS) interrupt  */
    MSC_IRQn = 13,          /*!<  13 MSC combined (S + NS) interrupt  */
    BRIDGE_ERROR_IRQn = 14, /*!<  14 Bridge error combined interrupt  */
    /* IRQ 15 is reserved */
    GPIO2_IRQn = 16, /*!<  16 GPIO 2 combined interrupt        */
    GPIO3_IRQn = 17, /*!<  17 GPIO 3 combined interrupt        */
    /* IRQs 18-31 are available for expansion */
  } IRQn_Type;

/*--------------------- Processor and Core Peripheral Section
 * -------------------*/

/* Configuration of the Cortex-M33 Processor and Core Peripherals */
#define __CM33_REV 0x0004     /*!< Core revision r0p4                   */
#define __SAUREGION_PRESENT 1 /*!< SAU regions present                  */
#define __MPU_PRESENT 1       /*!< MPU present                          */
#define __VTOR_PRESENT 1      /*!< VTOR present                         */
#define __NVIC_PRIO_BITS 3    /*!< Number of Bits used for Priority Levels */
#define __Vendor_SysTickConfig \
  0                        /*!< Set to 1 if different SysTick Config is used */
#define __FPU_PRESENT 1    /*!< FPU present                          */
#define __FPU_DP 0         /*!< Double Precision FPU                 */
#define __DSP_PRESENT 1    /*!< DSP extension present                */
#define __ICACHE_PRESENT 1 /*!< Instruction Cache present            */
#define __DCACHE_PRESENT 1 /*!< Data Cache present                   */

#include "core_cm33.h"      /*!< Cortex-M33 processor and core peripherals */
#include "system_ARMCM33.h" /*!< ARMCM33 System                       */

/*--------------------- Device Specific Peripheral Section
 * ----------------------*/

/*==================== MPS3 AN524 Memory Map
 * ===================================*/
/* Flash and internal SRAM */
#define MPS3_CODE_SRAM_BASE (0x00000000UL) /*!< Code SRAM Base Address   */
#define MPS3_SRAM_BASE (0x20000000UL)      /*!< SRAM Base Address        */
#define MPS3_DDR4_BASE (0x60000000UL)      /*!< DDR4 Base Address (NS)   */
#define MPS3_DDR4_BASE_S (0x70000000UL)    /*!< DDR4 Base Address (S)    */

/* APB peripherals */
#define MPS3_APB_BASE (0x40000000UL)       /*!< APB Base Address         */
#define MPS3_TIMER0_BASE (0x40000000UL)    /*!< Timer 0 Base Address     */
#define MPS3_TIMER1_BASE (0x40001000UL)    /*!< Timer 1 Base Address     */
#define MPS3_DUALTIMER_BASE (0x40002000UL) /*!< Dual Timer Base Address  */
/* UART addresses for QEMU mps3-an524 (SSE-200 memory map) */
#define MPS3_UART0_BASE (0x40004000UL) /*!< UART 0 Base Address      */
#define MPS3_UART1_BASE (0x40005000UL) /*!< UART 1 Base Address      */
#define MPS3_UART2_BASE (0x40006000UL) /*!< UART 2 Base Address      */
#define MPS3_UART3_BASE (0x40007000UL) /*!< UART 3 Base Address      */
#define MPS3_UART4_BASE (0x40008000UL) /*!< UART 4 Base Address      */
#define MPS3_UART5_BASE (0x40009000UL) /*!< UART 5 Base Address      */

/* GPIO */
#define MPS3_GPIO0_BASE (0x40100000UL) /*!< GPIO 0 Base Address      */
#define MPS3_GPIO1_BASE (0x40101000UL) /*!< GPIO 1 Base Address      */
#define MPS3_GPIO2_BASE (0x40102000UL) /*!< GPIO 2 Base Address      */
#define MPS3_GPIO3_BASE (0x40103000UL) /*!< GPIO 3 Base Address      */

/*================== MPS3 AN524 Peripheral Declaration
 * =========================*/

/* Peripheral and memory map */
#define MPS3_TIMER0 ((MPS3_TIMER_TypeDef *)MPS3_TIMER0_BASE)
#define MPS3_TIMER1 ((MPS3_TIMER_TypeDef *)MPS3_TIMER1_BASE)
#define MPS3_DUALTIMER ((MPS3_DUALTIMER_BOTH_TypeDef *)MPS3_DUALTIMER_BASE)
#define MPS3_UART0 ((MPS3_UART_TypeDef *)MPS3_UART0_BASE)
#define MPS3_UART1 ((MPS3_UART_TypeDef *)MPS3_UART1_BASE)
#define MPS3_UART2 ((MPS3_UART_TypeDef *)MPS3_UART2_BASE)
#define MPS3_GPIO0 ((MPS3_GPIO_TypeDef *)MPS3_GPIO0_BASE)
#define MPS3_GPIO1 ((MPS3_GPIO_TypeDef *)MPS3_GPIO1_BASE)
#define MPS3_GPIO2 ((MPS3_GPIO_TypeDef *)MPS3_GPIO2_BASE)
#define MPS3_GPIO3 ((MPS3_GPIO_TypeDef *)MPS3_GPIO3_BASE)

  /*------------- Universal Asynchronous Receiver Transmitter (UART)
   * -----------*/
  typedef struct
  {
    __IOM uint32_t DATA;  /*!< Offset: 0x000 (R/W) Data Register    */
    __IOM uint32_t STATE; /*!< Offset: 0x004 (R/W) Status Register  */
    __IOM uint32_t CTRL;  /*!< Offset: 0x008 (R/W) Control Register */
    __IOM uint32_t
        INTSTATUS; /*!< Offset: 0x00C (R/ ) Interrupt Status Register */
    __IOM uint32_t
        BAUDDIV; /*!< Offset: 0x010 (R/W) Baudrate Divider Register */
  } MPS3_UART_TypeDef;

/* UART DATA Register Definitions */
#define MPS3_UART_DATA_Pos 0 /*!< MPS3_UART_DATA: DATA Position */
#define MPS3_UART_DATA_Msk \
  (0xFFUL << MPS3_UART_DATA_Pos) /*!< MPS3_UART_DATA: DATA Mask */

/* UART STATE Register Definitions */
#define MPS3_UART_STATE_RXOR_Pos 3 /*!< MPS3_UART_STATE: RXOR Position */
#define MPS3_UART_STATE_RXOR_Msk \
  (0x1UL << MPS3_UART_STATE_RXOR_Pos) /*!< MPS3_UART_STATE: RXOR Mask */

#define MPS3_UART_STATE_TXOR_Pos 2 /*!< MPS3_UART_STATE: TXOR Position */
#define MPS3_UART_STATE_TXOR_Msk \
  (0x1UL << MPS3_UART_STATE_TXOR_Pos) /*!< MPS3_UART_STATE: TXOR Mask */

#define MPS3_UART_STATE_RXBF_Pos 1 /*!< MPS3_UART_STATE: RXBF Position */
#define MPS3_UART_STATE_RXBF_Msk \
  (0x1UL << MPS3_UART_STATE_RXBF_Pos) /*!< MPS3_UART_STATE: RXBF Mask */

#define MPS3_UART_STATE_TXBF_Pos 0 /*!< MPS3_UART_STATE: TXBF Position */
#define MPS3_UART_STATE_TXBF_Msk \
  (0x1UL << MPS3_UART_STATE_TXBF_Pos) /*!< MPS3_UART_STATE: TXBF Mask */

/* UART CTRL Register Definitions */
#define MPS3_UART_CTRL_HSTM_Pos 6 /*!< MPS3_UART_CTRL: HSTM Position */
#define MPS3_UART_CTRL_HSTM_Msk \
  (0x01UL << MPS3_UART_CTRL_HSTM_Pos) /*!< MPS3_UART_CTRL: HSTM Mask */

#define MPS3_UART_CTRL_RXORIRQEN_Pos \
  5 /*!< MPS3_UART_CTRL: RXORIRQEN Position */
#define MPS3_UART_CTRL_RXORIRQEN_Msk \
  (0x01UL                            \
   << MPS3_UART_CTRL_RXORIRQEN_Pos) /*!< MPS3_UART_CTRL: RXORIRQEN Mask */

#define MPS3_UART_CTRL_TXORIRQEN_Pos \
  4 /*!< MPS3_UART_CTRL: TXORIRQEN Position */
#define MPS3_UART_CTRL_TXORIRQEN_Msk \
  (0x01UL                            \
   << MPS3_UART_CTRL_TXORIRQEN_Pos) /*!< MPS3_UART_CTRL: TXORIRQEN Mask */

#define MPS3_UART_CTRL_RXIRQEN_Pos 3 /*!< MPS3_UART_CTRL: RXIRQEN Position */
#define MPS3_UART_CTRL_RXIRQEN_Msk \
  (0x01UL << MPS3_UART_CTRL_RXIRQEN_Pos) /*!< MPS3_UART_CTRL: RXIRQEN Mask */

#define MPS3_UART_CTRL_TXIRQEN_Pos 2 /*!< MPS3_UART_CTRL: TXIRQEN Position */
#define MPS3_UART_CTRL_TXIRQEN_Msk \
  (0x01UL << MPS3_UART_CTRL_TXIRQEN_Pos) /*!< MPS3_UART_CTRL: TXIRQEN Mask */

#define MPS3_UART_CTRL_RXEN_Pos 1 /*!< MPS3_UART_CTRL: RXEN Position */
#define MPS3_UART_CTRL_RXEN_Msk \
  (0x01UL << MPS3_UART_CTRL_RXEN_Pos) /*!< MPS3_UART_CTRL: RXEN Mask */

#define MPS3_UART_CTRL_TXEN_Pos 0 /*!< MPS3_UART_CTRL: TXEN Position */
#define MPS3_UART_CTRL_TXEN_Msk \
  (0x01UL << MPS3_UART_CTRL_TXEN_Pos) /*!< MPS3_UART_CTRL: TXEN Mask */

  /*---------------------------- Timer (TIMER) -------------------------------*/
  typedef struct
  {
    __IOM uint32_t CTRL;   /*!< Offset: 0x000 (R/W) Control Register */
    __IOM uint32_t VALUE;  /*!< Offset: 0x004 (R/W) Current Value Register */
    __IOM uint32_t RELOAD; /*!< Offset: 0x008 (R/W) Reload Value Register */
    uint32_t RESERVED0[1];
    __IOM uint32_t
        INTSTATUS; /*!< Offset: 0x010 (R/W) Interrupt Status Register */
  } MPS3_TIMER_TypeDef;

  /*------------------------ Dual Timer (DUALTIMER) -------------------------*/
  typedef struct
  {
    __IOM uint32_t Timer1Load; /*!< Offset: 0x000 (R/W) Timer 1 Load Register */
    __IOM uint32_t
        Timer1Value; /*!< Offset: 0x004 (R/ ) Timer 1 Current Value Register */
    __IOM uint32_t
        Timer1Control; /*!< Offset: 0x008 (R/W) Timer 1 Control Register */
    __IOM uint32_t Timer1IntClr; /*!< Offset: 0x00C ( /W) Timer 1 Interrupt
                                    Clear Register */
    __IOM uint32_t Timer1RIS;    /*!< Offset: 0x010 (R/ ) Timer 1 Raw Interrupt
                                    Status Register */
    __IOM uint32_t Timer1MIS; /*!< Offset: 0x014 (R/ ) Timer 1 Masked Interrupt
                                 Status Register */
    __IOM uint32_t Timer1BGLoad; /*!< Offset: 0x018 (R/W) Timer 1 Background
                                    Load Register */
    uint32_t RESERVED0[1];
    __IOM uint32_t Timer2Load; /*!< Offset: 0x020 (R/W) Timer 2 Load Register */
    __IOM uint32_t
        Timer2Value; /*!< Offset: 0x024 (R/ ) Timer 2 Current Value Register */
    __IOM uint32_t
        Timer2Control; /*!< Offset: 0x028 (R/W) Timer 2 Control Register */
    __IOM uint32_t Timer2IntClr; /*!< Offset: 0x02C ( /W) Timer 2 Interrupt
                                    Clear Register */
    __IOM uint32_t Timer2RIS;    /*!< Offset: 0x030 (R/ ) Timer 2 Raw Interrupt
                                    Status Register */
    __IOM uint32_t Timer2MIS; /*!< Offset: 0x034 (R/ ) Timer 2 Masked Interrupt
                                 Status Register */
    __IOM uint32_t Timer2BGLoad; /*!< Offset: 0x038 (R/W) Timer 2 Background
                                    Load Register */
  } MPS3_DUALTIMER_BOTH_TypeDef;

  /*--------------------------- GPIO (GPIO) --------------------------------*/
  typedef struct
  {
    __IOM uint32_t DATA; /*!< Offset: 0x000 (R/W) DATA Register */
    __IOM uint32_t
        DATAOUT; /*!< Offset: 0x004 (R/W) Data Output Latch Register */
    uint32_t RESERVED0[2];
    __IOM uint32_t
        OUTENSET; /*!< Offset: 0x010 (R/W) Output Enable Set Register */
    __IOM uint32_t
        OUTENCLR; /*!< Offset: 0x014 (R/W) Output Enable Clear Register */
    __IOM uint32_t
        ALTFUNCSET; /*!< Offset: 0x018 (R/W) Alternate Function Set Register */
    __IOM uint32_t ALTFUNCCLR; /*!< Offset: 0x01C (R/W) Alternate Function Clear
                                  Register */
    __IOM uint32_t
        INTENSET; /*!< Offset: 0x020 (R/W) Interrupt Enable Set Register */
    __IOM uint32_t
        INTENCLR; /*!< Offset: 0x024 (R/W) Interrupt Enable Clear Register */
    __IOM uint32_t
        INTTYPESET; /*!< Offset: 0x028 (R/W) Interrupt Type Set Register */
    __IOM uint32_t
        INTTYPECLR; /*!< Offset: 0x02C (R/W) Interrupt Type Clear Register */
    __IOM uint32_t
        INTPOLSET; /*!< Offset: 0x030 (R/W) Interrupt Polarity Set Register */
    __IOM uint32_t
        INTPOLCLR; /*!< Offset: 0x034 (R/W) Interrupt Polarity Clear Register */
    union
    {
      __IM uint32_t
          INTSTATUS; /*!< Offset: 0x038 (R/ ) Interrupt Status Register */
      __OM uint32_t
          INTCLEAR; /*!< Offset: 0x038 ( /W) Interrupt Clear Register */
    };
    uint32_t RESERVED1[241];
    __IOM uint32_t LB_MASKED[256]; /*!< Offset: 0x400 - 0x7FC Lower byte Masked
                                      Access Register (R/W) */
    __IOM uint32_t UB_MASKED[256]; /*!< Offset: 0x800 - 0xBFC Upper byte Masked
                                      Access Register (R/W) */
  } MPS3_GPIO_TypeDef;

#ifdef __cplusplus
}
#endif

#endif /* !ARMCM33_H */
