/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 */


#ifndef MLD_TEST_ABICHECK_CHECKS_RISCV64_ALL_H
#define MLD_TEST_ABICHECK_CHECKS_RISCV64_ALL_H

#include <stddef.h>
#include "../abicheck_common.h"

#if defined(MLD_SYS_RISCV64)

#if defined(__riscv_zbb)
int check_keccak_f1600_x1_zbb_riscv64_asm(void);
#endif
#if defined(MLD_SYS_RISCV64_RVV)
int check_intt_vlen128_riscv64_asm(void);
int check_intt_vlen256_riscv64_asm(void);
int check_ntt_vlen128_riscv64_asm(void);
int check_ntt_vlen256_riscv64_asm(void);
int check_poly_caddq_riscv64_asm(void);
int check_poly_chknorm_riscv64_asm(void);
int check_poly_decompose_32_riscv64_asm(void);
int check_poly_decompose_88_riscv64_asm(void);
int check_poly_pointwise_montgomery_riscv64_asm(void);
int check_poly_use_hint_32_riscv64_asm(void);
int check_poly_use_hint_88_riscv64_asm(void);
int check_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm(void);
int check_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm(void);
int check_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm(void);
int check_polyz_unpack_17_riscv64_asm(void);
int check_polyz_unpack_19_riscv64_asm(void);
int check_rej_uniform_eta2_riscv64_asm(void);
int check_rej_uniform_eta4_riscv64_asm(void);
int check_rej_uniform_riscv64_asm(void);
#endif /* MLD_SYS_RISCV64_RVV */

static const abicheck_entry_t all_checks[] = {
#if defined(__riscv_zbb)
    {"keccak_f1600_x1_zbb_riscv64_asm", check_keccak_f1600_x1_zbb_riscv64_asm},
#endif
#if defined(MLD_SYS_RISCV64_RVV)
    {"intt_vlen128_riscv64_asm", check_intt_vlen128_riscv64_asm},
    {"intt_vlen256_riscv64_asm", check_intt_vlen256_riscv64_asm},
    {"ntt_vlen128_riscv64_asm", check_ntt_vlen128_riscv64_asm},
    {"ntt_vlen256_riscv64_asm", check_ntt_vlen256_riscv64_asm},
    {"poly_caddq_riscv64_asm", check_poly_caddq_riscv64_asm},
    {"poly_chknorm_riscv64_asm", check_poly_chknorm_riscv64_asm},
    {"poly_decompose_32_riscv64_asm", check_poly_decompose_32_riscv64_asm},
    {"poly_decompose_88_riscv64_asm", check_poly_decompose_88_riscv64_asm},
    {"poly_pointwise_montgomery_riscv64_asm",
     check_poly_pointwise_montgomery_riscv64_asm},
    {"poly_use_hint_32_riscv64_asm", check_poly_use_hint_32_riscv64_asm},
    {"poly_use_hint_88_riscv64_asm", check_poly_use_hint_88_riscv64_asm},
    {"polyvecl_pointwise_acc_montgomery_l4_riscv64_asm",
     check_polyvecl_pointwise_acc_montgomery_l4_riscv64_asm},
    {"polyvecl_pointwise_acc_montgomery_l5_riscv64_asm",
     check_polyvecl_pointwise_acc_montgomery_l5_riscv64_asm},
    {"polyvecl_pointwise_acc_montgomery_l7_riscv64_asm",
     check_polyvecl_pointwise_acc_montgomery_l7_riscv64_asm},
    {"polyz_unpack_17_riscv64_asm", check_polyz_unpack_17_riscv64_asm},
    {"polyz_unpack_19_riscv64_asm", check_polyz_unpack_19_riscv64_asm},
    {"rej_uniform_eta2_riscv64_asm", check_rej_uniform_eta2_riscv64_asm},
    {"rej_uniform_eta4_riscv64_asm", check_rej_uniform_eta4_riscv64_asm},
    {"rej_uniform_riscv64_asm", check_rej_uniform_riscv64_asm},
#endif           /* MLD_SYS_RISCV64_RVV */
    {NULL, NULL} /* Sentinel */
};

#endif /* MLD_SYS_RISCV64 */

#endif /* !MLD_TEST_ABICHECK_CHECKS_RISCV64_ALL_H */
