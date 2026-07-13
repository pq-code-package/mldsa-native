/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_ARMV81M_MVE_MEMORY_H
#define MLD_NATIVE_ARMV81M_MVE_MEMORY_H

#include "../../sys.h"

#if !defined(__ASSEMBLER__)

#if !defined(MLD_SYS_ARMV81M_MVE)
#error "Armv8.1-M MVE memory helpers require Armv8.1-M MVE"
#endif

#include <stddef.h>

static MLD_INLINE void mld_zeroize_native(void *ptr, size_t len)
{
  __asm__ __volatile__(
      "   vdup.8                  q0, %[set_val]             \n"
      "   wlstp.8                 lr, %[cnt], 1f             \n"
      "2:                                                    \n"
      "   vstrb.8                 q0, [%[out]], #16          \n"
      "   letp                    lr, 2b                     \n"
      "1:                                                    \n"
      : [out] "+r"(ptr)
      : [cnt] "r"(len), [set_val] "r"(0)
      : "q0", "memory", "r14");
}

static MLD_INLINE void *mld_memset_native(void *dest, int c, size_t n)
{
  void *ret = dest;

  __asm__ __volatile__(
      "   vdup.8                  q0, %[set_val]             \n"
      "   wlstp.8                 lr, %[cnt], 1f             \n"
      "2:                                                    \n"
      "   vstrb.8                 q0, [%[out]], #16          \n"
      "   letp                    lr, 2b                     \n"
      "1:                                                    \n"
      : [out] "+r"(dest)
      : [cnt] "r"(n), [set_val] "r"(c)
      : "q0", "memory", "r14");

  return ret;
}

static MLD_INLINE void *mld_memcpy_native(void *dest, const void *src, size_t n)
{
  void *ret = dest;

  __asm__ __volatile__(
      "   wlstp.8                 lr, %[cnt], 1f             \n"
      "2:                                                    \n"
      "   vldrb.8                 q0, [%[in]], #16           \n"
      "   vstrb.8                 q0, [%[out]], #16          \n"
      "   letp                    lr, 2b                     \n"
      "1:                                                    \n"
      : [in] "+r"(src), [out] "+r"(dest)
      : [cnt] "r"(n)
      : "q0", "memory", "r14");

  return ret;
}

#endif /* !__ASSEMBLER__ */

#endif /* !MLD_NATIVE_ARMV81M_MVE_MEMORY_H */

#if !defined(__ASSEMBLER__)

#if defined(MLD_CONFIG_CUSTOM_ZEROIZE)
#define mld_zeroize mld_zeroize_native
#endif

#if defined(MLD_CONFIG_CUSTOM_MEMSET)
#define mld_memset mld_memset_native
#endif

#if defined(MLD_CONFIG_CUSTOM_MEMCPY)
#define mld_memcpy mld_memcpy_native
#endif

#endif /* !__ASSEMBLER__ */
