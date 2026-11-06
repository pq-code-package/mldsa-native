/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: ntt_vlen128_riscv64_asm
  Description: Forward negacyclic NTT of a polynomial in place, output in bitreversed order (VLEN=128 only)
  Signature: void mld_ntt_vlen128_riscv64_asm(int32_t p[256], const int32_t zetas[512])
  ABI:
    Architecture: riscv64
    CallingConvention: LP64D
    Features: [RVV]
    a0:
      type: buffer
      size_bytes: 1024
      permissions: read/write
      c_parameter: int32_t p[256]
      description: Input/output polynomial
    a1:
      type: buffer
      size_bytes: 2048
      permissions: read-only
      c_parameter: const int32_t zetas[512]
      description: Twiddle table (mld_rv64v_ntt_zetas)
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#include "rv64v_ntt.inc"

/*
 * Forward NTT with 4 lanes per register, see rv64v_ntt.inc. Pass A and
 * pass B each run in 4 batches.
 *
 * Requires VLEN = 128: the register groups of layers 1-4 assume that each
 * register holds exactly the VL lanes in use.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(ntt_vlen128_riscv64_asm)
MLD_ASM_FN_SYMBOL(ntt_vlen128_riscv64_asm)

        ntt_setup   4

        /* Pass A: layers 1-4 */
        mv          ptr, data
        li          batch, 4
mld_ntt_vlen128_riscv64_pass_a:
        vsetvl_m1
        access_pass_a vle32.v
        ntt_layers1234
        vsetvl_m1
        access_pass_a vse32.v
        addi        ptr, ptr, (4 * 4)
        addi        batch, batch, -1
        bnez        batch, mld_ntt_vlen128_riscv64_pass_a

        /* Pass B: layers 5-8 */
        mv          ptr, data
        addi        lane_ptr, zetas, 128
        li          batch, 4
mld_ntt_vlen128_riscv64_pass_b:
        vsetvl_m1
        access_pass_b vlse32.v
        ntt_layers5678
        vsetvl_m1
        access_pass_b vsse32.v
        addi        ptr, ptr, (64 * 4)
        addi        lane_ptr, lane_ptr, (4 * 4)
        addi        batch, batch, -1
        bnez        batch, mld_ntt_vlen128_riscv64_pass_b

        ret
.option pop

MLD_ASM_FN_SIZE(ntt_vlen128_riscv64_asm)

/* simpasm: footer-start */
#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
