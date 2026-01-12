/******************************************************************************
 * @file     m33-an524.ld
 * @brief    GNU Linker Script for Cortex-M33 Device on MPS3 AN524
 * @version  V2.2.0
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
 *
 * Modifications for MPS3 AN524:
 * - Flash Base: 0x00000000 (Non-Secure BRAM, 512KB - QEMU kernel load address)
 * - RAM Base: 0x60000000 (Non-Secure DDR4, using 2MB of 256MB available)
 * - Stack Size: 64KB (increased for ML-DSA-87)
 * - Heap Size: 512KB (increased for cryptographic operations)
 * 
 * Hardware Reference:
 *   ARM DAI 0524F - Application Note AN524 "SSE-200 Subsystem for MPS3"
 *   https://developer.arm.com/documentation/dai0524/latest
 *
 * Memory Configuration (from ARM DAI 0524F):
 *   FLASH: 0x10000000 - Secure BRAM alias (Table 3-1 Row 5, 512KB)
 *   RAM:   0x70000000 - Secure DDR4 (Table 3-1 Row 38, using 2MB of 256MB available)
 */

/* Flash: Secure BRAM alias (512KB) */
__ROM_BASE = 0x10000000;
__ROM_SIZE = 0x00080000;

/* RAM: Secure DDR4 (using 2MB from 256MB available at 0x70000000-0x7FFFFFFF) */
/* Note: AN524 has 2GB DDR4, we use secure region for larger working memory */
__RAM_BASE = 0x70000000;
__RAM_SIZE = 0x00200000;

/*--------------------- Stack / Heap Configuration ----------------------------
  Stack Size: 64KB (for ML-DSA-87)
  Heap Size: 512KB (for cryptographic operations)
  -----------------------------------------------------------------------------*/
__STACK_SIZE = 0x00010000;
__HEAP_SIZE  = 0x00080000;

/*
 *-------------------- <<< end of configuration section >>> -------------------
 */

MEMORY
{
  FLASH (rx)  : ORIGIN = __ROM_BASE, LENGTH = __ROM_SIZE
  RAM   (rw)  : ORIGIN = __RAM_BASE, LENGTH = __RAM_SIZE
}

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __copy_table_start__
 *   __copy_table_end__
 *   __zero_table_start__
 *   __zero_table_end__
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 *   __INITIAL_SP (alias for __StackTop)
 *   __STACK_LIMIT (alias for __StackLimit)
 */
ENTRY(Reset_Handler)

SECTIONS
{
  .text :
  {
    . = ALIGN(4);
    KEEP(*(.vectors))       /* Vector table must be at start of FLASH */
    *(.text*)               /* Program code */

    KEEP(*(.init))
    KEEP(*(.fini))

    /* .ctors */
    *crtbegin.o(.ctors)
    *crtbegin?.o(.ctors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
    *(SORT(.ctors.*))
    *(.ctors)

    /* .dtors */
    *crtbegin.o(.dtors)
    *crtbegin?.o(.dtors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
    *(SORT(.dtors.*))
    *(.dtors)

    *(.rodata*)             /* Read-only data (constants, strings) */
    KEEP(*(.eh_frame*))     /* Exception handling frames */

    . = ALIGN(4);
  } > FLASH

  /* ARM Exception Handling */
  .ARM.extab :
  {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } > FLASH

  __exidx_start = .;
  .ARM.exidx :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } > FLASH
  __exidx_end = .;

  /* Copy Table: used by startup to copy .data from FLASH to RAM */
  .copy.table :
  {
    . = ALIGN(4);
    __copy_table_start__ = .;
    LONG (__etext)
    LONG (__data_start__)
    LONG ((__data_end__ - __data_start__) / 4)
    __copy_table_end__ = .;
  } > FLASH

  .zero.table :
  {
    . = ALIGN(4);
    __zero_table_start__ = .;
    LONG (__bss_start__)
    LONG ((__bss_end__ - __bss_start__) / 4)
    __zero_table_end__ = .;
  } > FLASH

  /* End of code in FLASH - data will be copied from here to RAM */
  . = ALIGN(4);
  __etext = .;
  _etext = __etext;

  .data : AT (__etext)
  {
    . = ALIGN(4);
    __data_start__ = .;
    _sdata = __data_start__;

    *(vtable)               /* C++ virtual function tables */
    *(.data)
    *(.data.*)

    . = ALIGN(4);
    /* preinit data */
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);

    . = ALIGN(4);
    /* init data */
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);

    . = ALIGN(4);
    /* finit data */
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN (__fini_array_end = .);

    KEEP(*(.jcr*))
    . = ALIGN(4);
    __data_end__ = .;
    _edata = __data_end__;
  } > RAM

  /* NoInit Section (not zero-initialized) */
  .noinit (NOLOAD) :
  {
    . = ALIGN(4);
    __noinit_start__ = .;
    *(.noinit)
    *(.noinit.*)
    KEEP(*(.noinit*))
    . = ALIGN(4);
    __noinit_end__ = .;
  } > RAM

  /* BSS Section (zero-initialized at startup) */
  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start__ = .;
    _sbss = __bss_start__;

    *(.bss)
    *(.bss.*)
    *(COMMON)               /* Uninitialized global variables */

    . = ALIGN(4);
    __bss_end__ = .;
    _ebss = __bss_end__;
  } > RAM

  /* Heap (grows upward) */
  .heap (NOLOAD) :
  {
    . = ALIGN(8);
    __HeapBase = .;
    __end__ = .;
    _sheap = .;
    PROVIDE(end = .);
    PROVIDE(_end = .);

    . = . + __HEAP_SIZE;
    . = ALIGN(8);
    __HeapLimit = .;
    _eheap = .;
  } > RAM

  /* Stack (at end of RAM, grows downward toward heap) */
  .stack (ORIGIN(RAM) + LENGTH(RAM) - __STACK_SIZE) (NOLOAD) :
  {
    . = ALIGN(8);           /* 8-byte alignment for AAPCS compliance */
    __StackLimit = .;
    _sstack = .;

    . = . + __STACK_SIZE;
    . = ALIGN(8);
    __StackTop = .;         /* Initial stack pointer value */
    _estack = .;
  } > RAM
  
  PROVIDE(__stack = __StackTop);

  /* Memory Overflow Checks */
  ASSERT(__StackLimit >= __HeapLimit, "RAM overflow: heap collides with stack")
  ASSERT(__etext <= (ORIGIN(FLASH) + LENGTH(FLASH)), "FLASH overflow")

  /* Debug Sections */
  .debug_info     0 : { *(.debug_info) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  .debug_ranges   0 : { *(.debug_ranges) }
  .debug_addr     0 : { *(.debug_addr) }
  .debug_line_str 0 : { *(.debug_line_str) }
  .debug_loclists 0 : { *(.debug_loclists) }
  .debug_rnglists 0 : { *(.debug_rnglists) }
  .ARM.attributes 0 : { *(.ARM.attributes) }
  .comment        0 : { *(.comment) }

  /DISCARD/ :
  {
    *(.note.GNU-stack)
    *(.gnu_debuglink)
    *(.gnu.lto_*)
  }
}
