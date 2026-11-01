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

#ifdef MLD_SYS_AARCH64_NEON
#include "aarch64/meta.h"
#endif

/* The x86_64 backend requires toolchain support for the SysV ABI */
/* Native assembly support was added for MSVC X86-64 (and Aarch64, see above),
 * MLD_MS_AMD64_ABI_SUPPORTED is defined in the MS/X86-64 case.
 */
#if defined(MLD_SYS_X86_64_AVX2) && (defined(MLD_SYSV_ABI_SUPPORTED) \
|| defined(MLD_MS_AMD64_ABI_SUPPORTED))
#include "x86_64/meta.h"
#endif

#if defined(MLD_SYS_RISCV32_M)
#include "rv32im/fastmul.h"
#endif

#endif /* !MLD_NATIVE_META_H */
