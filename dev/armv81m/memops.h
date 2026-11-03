/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_MEMOPS_H
#define MLD_NATIVE_ARMV81M_MEMOPS_H

/* Included by common.h after architecture detection. Byte-tail predication
 * accepts arbitrary lengths and unaligned byte pointers. memcpy retains the
 * usual non-overlap contract. These replace the three standard memory hooks. */
#if defined(MLD_ARMV81M_USE_MVE_MEMOPS)
#if !defined(MLD_SYS_ARMV81M_MVE)
#error MLD_ARMV81M_USE_MVE_MEMOPS requires Armv8.1-M MVE
#endif

#if defined(MLD_CONFIG_CUSTOM_ZEROIZE) || defined(MLD_CONFIG_CUSTOM_MEMCPY) || \
    defined(MLD_CONFIG_CUSTOM_MEMSET)
#error MLD_ARMV81M_USE_MVE_MEMOPS replaces all three custom memory hooks
#endif

#define MLD_CONFIG_CUSTOM_ZEROIZE
#define MLD_CONFIG_CUSTOM_MEMCPY
#define MLD_CONFIG_CUSTOM_MEMSET

#if !defined(__ASSEMBLER__)
#include <stddef.h>
#include "../../sys.h"


static MLD_ALWAYS_INLINE void MLD_NAMESPACE(armv81m_zeroize)(void *ptr,
                                                             size_t len)
{
  __asm__ __volatile__(
      "vdup.8 q0, %[set_val]\n"
      "wlstp.8 lr, %[cnt], 1f\n"
      "2:\n"
      "vstrb.8 q0, [%[out]], #16\n"
      "letp lr, 2b\n"
      "1:\n"
      : [out] "+r"(ptr)
      : [cnt] "r"(len), [set_val] "r"(0)
      : "q0", "memory", "r14");
}

static MLD_ALWAYS_INLINE void *MLD_NAMESPACE(armv81m_memcpy)(void *dest,
                                                             const void *src,
                                                             size_t n)
{
  void *result = dest;
  __asm__ __volatile__(
      "wlstp.8 lr, %[cnt], 1f\n"
      "2:\n"
      "vldrb.8 q0, [%[in]], #16\n"
      "vstrb.8 q0, [%[out]], #16\n"
      "letp lr, 2b\n"
      "1:\n"
      : [in] "+r"(src), [out] "+r"(dest)
      : [cnt] "r"(n)
      : "q0", "memory", "r14");
  return result;
}

static MLD_ALWAYS_INLINE void *MLD_NAMESPACE(armv81m_memset)(void *dest,
                                                             int value,
                                                             size_t n)
{
  void *result = dest;
  __asm__ __volatile__(
      "vdup.8 q0, %[set_val]\n"
      "wlstp.8 lr, %[cnt], 1f\n"
      "2:\n"
      "vstrb.8 q0, [%[out]], #16\n"
      "letp lr, 2b\n"
      "1:\n"
      : [out] "+r"(dest)
      : [cnt] "r"(n), [set_val] "r"(value)
      : "q0", "memory", "r14");
  return result;
}
#endif /* !__ASSEMBLER__ */
#endif /* MLD_ARMV81M_USE_MVE_MEMOPS */


#endif /* !MLD_NATIVE_ARMV81M_MEMOPS_H */
