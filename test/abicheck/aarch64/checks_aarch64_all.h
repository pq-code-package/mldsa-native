/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */


#ifndef MLD_TEST_ABICHECK_CHECKS_AARCH64_ALL_H
#define MLD_TEST_ABICHECK_CHECKS_AARCH64_ALL_H

#include <stddef.h>
#include "../abicheck_common.h"

#if defined(MLD_SYS_AARCH64)

#if defined(MLD_SYS_AARCH64_NEON)
int check_intt_aarch64_asm(void);
#endif
int check_keccak_f1600_x1_scalar_aarch64_asm(void);
#if defined(MLD_SYS_AARCH64_NEON)
#if defined(__ARM_FEATURE_SHA3)
int check_keccak_f1600_x1_v84a_aarch64_asm(void);
int check_keccak_f1600_x2_v84a_aarch64_asm(void);
#endif
#endif /* MLD_SYS_AARCH64_NEON */
#if defined(MLD_SYS_AARCH64_NEON)
int check_keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm(void);
#endif
#if defined(MLD_SYS_AARCH64_NEON)
#if defined(__ARM_FEATURE_SHA3)
int check_keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm(void);
#endif
#endif
#if defined(MLD_SYS_AARCH64_NEON)
int check_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm(void);
int check_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm(void);
int check_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm(void);
int check_ntt_aarch64_asm(void);
int check_poly_pointwise_montgomery_aarch64_asm(void);
int check_poly_caddq_aarch64_asm(void);
int check_poly_chknorm_aarch64_asm(void);
int check_poly_decompose_32_aarch64_asm(void);
int check_poly_decompose_88_aarch64_asm(void);
int check_poly_use_hint_32_aarch64_asm(void);
int check_poly_use_hint_88_aarch64_asm(void);
int check_polyz_unpack_17_aarch64_asm(void);
int check_polyz_unpack_19_aarch64_asm(void);
int check_rej_uniform_aarch64_asm(void);
int check_rej_uniform_eta2_aarch64_asm(void);
int check_rej_uniform_eta4_aarch64_asm(void);
#endif /* MLD_SYS_AARCH64_NEON */

static const abicheck_entry_t all_checks[] = {
#if defined(MLD_SYS_AARCH64_NEON)
    {"intt_aarch64_asm", check_intt_aarch64_asm},
#endif
    {"keccak_f1600_x1_scalar_aarch64_asm",
     check_keccak_f1600_x1_scalar_aarch64_asm},
#if defined(MLD_SYS_AARCH64_NEON)
#if defined(__ARM_FEATURE_SHA3)
    {"keccak_f1600_x1_v84a_aarch64_asm",
     check_keccak_f1600_x1_v84a_aarch64_asm},
    {"keccak_f1600_x2_v84a_aarch64_asm",
     check_keccak_f1600_x2_v84a_aarch64_asm},
#endif
#endif /* MLD_SYS_AARCH64_NEON */
#if defined(MLD_SYS_AARCH64_NEON)
    {"keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm",
     check_keccak_f1600_x4_v8a_scalar_hybrid_aarch64_asm},
#endif
#if defined(MLD_SYS_AARCH64_NEON)
#if defined(__ARM_FEATURE_SHA3)
    {"keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm",
     check_keccak_f1600_x4_v8a_v84a_scalar_hybrid_aarch64_asm},
#endif
#endif
#if defined(MLD_SYS_AARCH64_NEON)
    {"polyvecl_pointwise_acc_montgomery_l4_aarch64_asm",
     check_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm},
    {"polyvecl_pointwise_acc_montgomery_l5_aarch64_asm",
     check_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm},
    {"polyvecl_pointwise_acc_montgomery_l7_aarch64_asm",
     check_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm},
    {"ntt_aarch64_asm", check_ntt_aarch64_asm},
    {"poly_pointwise_montgomery_aarch64_asm",
     check_poly_pointwise_montgomery_aarch64_asm},
    {"poly_caddq_aarch64_asm", check_poly_caddq_aarch64_asm},
    {"poly_chknorm_aarch64_asm", check_poly_chknorm_aarch64_asm},
    {"poly_decompose_32_aarch64_asm", check_poly_decompose_32_aarch64_asm},
    {"poly_decompose_88_aarch64_asm", check_poly_decompose_88_aarch64_asm},
    {"poly_use_hint_32_aarch64_asm", check_poly_use_hint_32_aarch64_asm},
    {"poly_use_hint_88_aarch64_asm", check_poly_use_hint_88_aarch64_asm},
    {"polyz_unpack_17_aarch64_asm", check_polyz_unpack_17_aarch64_asm},
    {"polyz_unpack_19_aarch64_asm", check_polyz_unpack_19_aarch64_asm},
    {"rej_uniform_aarch64_asm", check_rej_uniform_aarch64_asm},
    {"rej_uniform_eta2_aarch64_asm", check_rej_uniform_eta2_aarch64_asm},
    {"rej_uniform_eta4_aarch64_asm", check_rej_uniform_eta4_aarch64_asm},
#endif           /* MLD_SYS_AARCH64_NEON */
    {NULL, NULL} /* Sentinel */
};

#endif /* MLD_SYS_AARCH64 */

#endif /* !MLD_TEST_ABICHECK_CHECKS_AARCH64_ALL_H */
