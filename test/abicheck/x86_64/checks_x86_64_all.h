/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */


#ifndef MLD_TEST_ABICHECK_CHECKS_X86_64_ALL_H
#define MLD_TEST_ABICHECK_CHECKS_X86_64_ALL_H

#include <stddef.h>
#include "../abicheck_common.h"

#if defined(MLD_SYS_X86_64)

#if defined(MLD_SYSV_ABI_SUPPORTED)
#if defined(__AVX2__)
int check_invntt_avx2_asm(void);
int check_keccak_f1600_x4_avx2_asm(void);
int check_ntt_avx2_asm(void);
int check_nttunpack_avx2_asm(void);
int check_pointwise_acc_l4_avx2_asm(void);
int check_pointwise_acc_l5_avx2_asm(void);
int check_pointwise_acc_l7_avx2_asm(void);
int check_pointwise_avx2_asm(void);
int check_poly_caddq_avx2_asm(void);
int check_poly_chknorm_avx2_asm(void);
int check_poly_decompose_32_avx2_asm(void);
int check_poly_decompose_88_avx2_asm(void);
int check_poly_use_hint_32_avx2_asm(void);
int check_poly_use_hint_88_avx2_asm(void);
int check_polyz_unpack_17_avx2_asm(void);
int check_polyz_unpack_19_avx2_asm(void);
int check_rej_uniform_avx2_asm(void);
int check_rej_uniform_eta2_avx2_asm(void);
int check_rej_uniform_eta4_avx2_asm(void);
#endif /* __AVX2__ */
#endif /* MLD_SYSV_ABI_SUPPORTED */

static const abicheck_entry_t all_checks[] = {
#if defined(MLD_SYSV_ABI_SUPPORTED)
#if defined(__AVX2__)
    {"invntt_avx2_asm", check_invntt_avx2_asm},
    {"keccak_f1600_x4_avx2_asm", check_keccak_f1600_x4_avx2_asm},
    {"ntt_avx2_asm", check_ntt_avx2_asm},
    {"nttunpack_avx2_asm", check_nttunpack_avx2_asm},
    {"pointwise_acc_l4_avx2_asm", check_pointwise_acc_l4_avx2_asm},
    {"pointwise_acc_l5_avx2_asm", check_pointwise_acc_l5_avx2_asm},
    {"pointwise_acc_l7_avx2_asm", check_pointwise_acc_l7_avx2_asm},
    {"pointwise_avx2_asm", check_pointwise_avx2_asm},
    {"poly_caddq_avx2_asm", check_poly_caddq_avx2_asm},
    {"poly_chknorm_avx2_asm", check_poly_chknorm_avx2_asm},
    {"poly_decompose_32_avx2_asm", check_poly_decompose_32_avx2_asm},
    {"poly_decompose_88_avx2_asm", check_poly_decompose_88_avx2_asm},
    {"poly_use_hint_32_avx2_asm", check_poly_use_hint_32_avx2_asm},
    {"poly_use_hint_88_avx2_asm", check_poly_use_hint_88_avx2_asm},
    {"polyz_unpack_17_avx2_asm", check_polyz_unpack_17_avx2_asm},
    {"polyz_unpack_19_avx2_asm", check_polyz_unpack_19_avx2_asm},
    {"rej_uniform_avx2_asm", check_rej_uniform_avx2_asm},
    {"rej_uniform_eta2_avx2_asm", check_rej_uniform_eta2_avx2_asm},
    {"rej_uniform_eta4_avx2_asm", check_rej_uniform_eta4_avx2_asm},
#endif           /* __AVX2__ */
#endif           /* MLD_SYSV_ABI_SUPPORTED */
    {NULL, NULL} /* Sentinel */
};

#endif /* MLD_SYS_X86_64 */

#endif /* !MLD_TEST_ABICHECK_CHECKS_X86_64_ALL_H */
