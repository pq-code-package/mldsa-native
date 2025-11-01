/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_COMMON_H
#define MLD_COMMON_H

#if defined(MLD_CONFIG_FILE)
#include MLD_CONFIG_FILE
#else
#include "config.h"
#endif

#include "cbmc.h"
#include "params.h"
#include "sys.h"

/* Internal and public API have external linkage by default, but
 * this can be overwritten by the user, e.g. for single-CU builds. */
#if !defined(MLD_CONFIG_INTERNAL_API_QUALIFIER)
#define MLD_INTERNAL_API
#else
#define MLD_INTERNAL_API MLD_CONFIG_INTERNAL_API_QUALIFIER
#endif

#if !defined(MLD_CONFIG_EXTERNAL_API_QUALIFIER)
#define MLD_EXTERNAL_API
#else
#define MLD_EXTERNAL_API MLD_CONFIG_EXTERNAL_API_QUALIFIER
#endif


#if defined(MLD_CONFIG_USE_NATIVE_BACKEND_ARITH) && \
    !defined(MLD_CONFIG_ARITH_BACKEND_FILE)
#error Bad configuration: MLD_CONFIG_USE_NATIVE_BACKEND_ARITH is set, but MLD_CONFIG_ARITH_BACKEND_FILE is not.
#endif


#define MLD_CONCAT_(x1, x2) x1##x2
#define MLD_CONCAT(x1, x2) MLD_CONCAT_(x1, x2)

#if defined(MLD_CONFIG_MULTILEVEL_NO_SHARED) || \
    defined(MLD_CONFIG_MULTILEVEL_WITH_SHARED)
#define MLD_MULTILEVEL_BUILD
#endif

#if defined(MLD_MULTILEVEL_BUILD)
#define MLD_ADD_PARAM_SET(s) MLD_CONCAT(s, MLD_CONFIG_PARAMETER_SET)
#else
#define MLD_ADD_PARAM_SET(s) s
#endif

#define MLD_NAMESPACE_PREFIX MLD_CONCAT(MLD_CONFIG_NAMESPACE_PREFIX, _)
#define MLD_NAMESPACE_PREFIX_KL \
  MLD_CONCAT(MLD_ADD_PARAM_SET(MLD_CONFIG_NAMESPACE_PREFIX), _)

/* Functions are prefixed by MLD_CONFIG_NAMESPACE_PREFIX.
 *
 * If multiple parameter sets are used, functions depending on the parameter
 * set are additionally prefixed with 44/65/87. See config.h.
 *
 * Example: If MLD_CONFIG_NAMESPACE_PREFIX is PQCP_MLDSA_NATIVE, then
 * MLD_NAMESPACE_KL(keypair) becomes PQCP_MLDSA_NATIVE44_keypair/
 * PQCP_MLDSA_NATIVE65_keypair/PQCP_MLDSA_NATIVE87_keypair.
 */
#define MLD_NAMESPACE(s) MLD_CONCAT(MLD_NAMESPACE_PREFIX, s)
#define MLD_NAMESPACE_KL(s) MLD_CONCAT(MLD_NAMESPACE_PREFIX_KL, s)

#if defined(MLD_CONFIG_USE_NATIVE_BACKEND_ARITH)
#include MLD_CONFIG_ARITH_BACKEND_FILE
#endif

/* On Apple platforms, we need to emit leading underscore
 * in front of assembly symbols. We thus introducee a separate
 * namespace wrapper for ASM symbols. */
#if !defined(__APPLE__)
#define MLD_ASM_NAMESPACE(sym) MLD_NAMESPACE(sym)
#else
#define MLD_ASM_NAMESPACE(sym) MLD_CONCAT(_, MLD_NAMESPACE(sym))
#endif

/*
 * On X86_64 if control-flow protections (CET) are enabled (through
 * -fcf-protection=), we add an endbr64 instruction at every global function
 * label.  See sys.h for more details
 */
#if defined(MLD_SYS_X86_64)
#define MLD_ASM_FN_SYMBOL(sym) MLD_ASM_NAMESPACE(sym) : MLD_CET_ENDBR
#else
#define MLD_ASM_FN_SYMBOL(sym) MLD_ASM_NAMESPACE(sym) :
#endif

/* We aim to simplify the user's life by supporting builds where
 * all source files are included, even those that are not needed.
 * Those files are appropriately guarded and will be empty when unneeded.
 * The following is to avoid compilers complaining about this. */
#define MLD_EMPTY_CU(s) extern int MLD_NAMESPACE_KL(empty_cu_##s);

#if defined(MLD_CONFIG_USE_NATIVE_BACKEND_FIPS202)
#include MLD_CONFIG_FIPS202_BACKEND_FILE
#endif

#if !defined(MLD_CONFIG_FIPS202_CUSTOM_HEADER)
#define MLD_FIPS202_HEADER_FILE "fips202/fips202.h"
#else
#define MLD_FIPS202_HEADER_FILE MLD_CONFIG_FIPS202_CUSTOM_HEADER
#endif

#if !defined(MLD_CONFIG_FIPS202X4_CUSTOM_HEADER)
#define MLD_FIPS202X4_HEADER_FILE "fips202/fips202x4.h"
#else
#define MLD_FIPS202X4_HEADER_FILE MLD_CONFIG_FIPS202X4_CUSTOM_HEADER
#endif

/* Standard library function replacements */
#if !defined(__ASSEMBLER__)
#if !defined(MLD_CONFIG_CUSTOM_MEMCPY)
#include <string.h>
#define mld_memcpy memcpy
#endif

#if !defined(MLD_CONFIG_CUSTOM_MEMSET)
#include <string.h>
#define mld_memset memset
#endif
#endif /* !__ASSEMBLER__ */



#endif /* !MLD_COMMON_H */
