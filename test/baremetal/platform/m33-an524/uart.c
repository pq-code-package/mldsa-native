/*
 * Copyright (c) 2019-2021 Arm Limited. All rights reserved.
 * Copyright (c) The mldsa-native project authors
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
 *
 * Adapted for MPS3 AN524 platform from pqmx M55-AN547 implementation.
 * Key differences from AN547:
 * - UART0 base address: 0x40200000 (AN524) vs 0x49303000 (AN547)
 * - Uses MPS3_UART_TypeDef from ARMCM33.h device header
 */

#include "uart.h"
#include "ARMCM33.h"
#include <stdint.h>

/*
 * MPS3 AN524 UART Configuration
 * - UART0 base: 0x40200000 (defined in ARMCM33.h as MPS3_UART0_BASE)
 * - System clock: 25 MHz
 * - Default baud rate: 115200
 */
#define UART0_BAUDRATE    115200
#define SYSTEM_CORE_CLOCK 25000000

void uart_init(void)
{
    /* Configure baud rate divider: SystemCoreClock / BaudRate */
    MPS3_UART0->BAUDDIV = SYSTEM_CORE_CLOCK / UART0_BAUDRATE;

    /* Enable TX and RX */
    MPS3_UART0->CTRL = (MPS3_UART_CTRL_TXEN_Msk |  /* TX enable */
                        MPS3_UART_CTRL_RXEN_Msk);  /* RX enable */
}

unsigned char uart_putc(unsigned char ch)
{
    /* Wait while transmit buffer is full (TXBF = 1) */
    while (MPS3_UART0->STATE & MPS3_UART_STATE_TXBF_Msk)
    {
        /* Busy wait */
    }

    /* Convert LF to CRLF for proper terminal output */
    if (ch == '\n')
    {
        MPS3_UART0->DATA = '\r';
        while (MPS3_UART0->STATE & MPS3_UART_STATE_TXBF_Msk)
        {
            /* Wait for CR to be sent */
        }
    }

    /* Write character to transmit data register */
    MPS3_UART0->DATA = ch;

    return ch;
}

unsigned char uart_getc(void)
{
    unsigned char ch;

    /* Wait while receive buffer is empty (RXBF = 0) */
    while ((MPS3_UART0->STATE & MPS3_UART_STATE_RXBF_Msk) == 0)
    {
        /* Busy wait */
    }

    /* Read character from receive data register */
    ch = (unsigned char)(MPS3_UART0->DATA & MPS3_UART_DATA_Msk);

    /* Convert CR to LF for consistent line endings */
    if (ch == '\r')
    {
        ch = '\n';
    }

    return ch;
}
