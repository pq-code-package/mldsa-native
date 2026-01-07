/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *
 * Linker script for Cortex-M33 on MPS2-AN521 (QEMU/FPGA)
 * Configured for TrustZone Secure World boot
 *
 * Hardware Reference:
 *   ARM DAI 0521A - Application Note AN521 "SMM-SSE-200 for MPS2+"
 *   https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/DAI0521A_example_sse200_subsystem_for_v2m_mps2.pdf
 *
 * Memory Configuration (from ARM DAI 0521A):
 *   FLASH: 0x10000000 - Secure SSRAM1 (Table 3-2 Row 6, Table 3-1 Row 3)
 *   RAM:   0x38000000 - Secure SSRAM2+SSRAM3 (Table 3-4 Rows 16-17, Table 3-1 Row 10)
 */

/* Flash: Secure SSRAM1 alias (4MB physical, using 512KB) */
__ROM_BASE = 0x10000000;
__ROM_SIZE = 0x00080000;

/* RAM: Secure SSRAM2+SSRAM3 alias (4MB physical, using 512KB) */
__RAM_BASE = 0x38000000;
__RAM_SIZE = 0x00080000;

/* Stack/Heap sizing for crypto operations */
__STACK_SIZE = 0x00008000;  /* 32KB */
__HEAP_SIZE  = 0x00020000;  /* 128KB */

MEMORY
{
  FLASH (rx)  : ORIGIN = __ROM_BASE, LENGTH = __ROM_SIZE
  RAM   (rw)  : ORIGIN = __RAM_BASE, LENGTH = __RAM_SIZE
}

ENTRY(Reset_Handler)

SECTIONS
{
  /* Code Section (FLASH) */
  .text :
  {
    . = ALIGN(4);
    KEEP(*(.vectors))       /* Vector table must be at start of FLASH */
    *(.text*)               /* Program code */

    KEEP(*(.init))          /* C runtime init */
    KEEP(*(.fini))          /* C runtime cleanup */

    /* C++ constructors - crtbegin/crtend bracket the list */
    *crtbegin.o(.ctors)
    *crtbegin?.o(.ctors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
    *(SORT(.ctors.*))
    *(.ctors)

    /* C++ destructors */
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

  /* Zero Table: used by startup to zero-initialize .bss */
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

  /* Initialized Data (RAM, loaded from FLASH at __etext) */
  .data : AT (__etext)
  {
    . = ALIGN(4);
    __data_start__ = .;
    _sdata = __data_start__;

    *(vtable)               /* C++ virtual function tables */
    *(.data)
    *(.data.*)

    /* Preinit array - called before constructors */
    . = ALIGN(4);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);

    /* Init array - C++ static constructors and C __attribute__((constructor)) */
    . = ALIGN(4);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);

    /* Fini array - C++ static destructors and C __attribute__((destructor)) */
    . = ALIGN(4);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN (__fini_array_end = .);

    /* Java class registration (GCJ) */
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
