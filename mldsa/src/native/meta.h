/*
 * Copyright (c) The mlkem-native project authors
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_NATIVE_META_H
#define MLD_NATIVE_META_H

/*
 * Default arithmetic backend
 */
#include "../sys.h"

#ifdef MLD_SYS_AARCH64
#include "aarch64/meta.h"
#endif

/* The x86_64 backend requires toolchain support for the SysV ABI */
#if defined(MLD_SYS_X86_64_AVX2) && defined(MLD_SYSV_ABI_SUPPORTED)
#include "x86_64/meta.h"
#endif

/* We do not yet include the arithmetic backend for RV32-IM by default
 * as it is still experimental and undergoing review. */
/* #if defined(MLD_SYS_RISCV32) */
/* #include "rv32im/meta.h" */
/* #endif */

#endif /* !MLD_NATIVE_META_H */
