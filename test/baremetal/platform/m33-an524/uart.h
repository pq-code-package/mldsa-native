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
 */

#ifndef UART_H
#define UART_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Initialize UART0 for serial communication
 *
 * Configures UART0 at 115200 baud with TX and RX enabled.
 * Uses MPS3 AN524 UART0 at address 0x40200000.
 */
void uart_init(void);

/**
 * @brief Output a character via UART
 *
 * @param ch Character to transmit
 * @return The transmitted character
 *
 * Automatically converts '\n' to '\r\n' for proper line endings.
 * Blocks until transmit buffer is ready.
 */
unsigned char uart_putc(unsigned char ch);

/**
 * @brief Read a character from UART
 *
 * @return The received character
 *
 * Blocks until a character is available.
 * Automatically converts '\r' to '\n'.
 */
unsigned char uart_getc(void);

#ifdef __cplusplus
}
#endif

#endif /* UART_H */
