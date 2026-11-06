/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: intt_vlen256_riscv64_asm
  Description: Inverse negacyclic NTT of a polynomial in place, input in bitreversed order, scaled by 2^32 (VLEN=256 only)
  Signature: void mld_intt_vlen256_riscv64_asm(int32_t p[256], const int32_t zetas[512])
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
      description: Twiddle table (mld_rv64v_intt_zetas)
*/

#include "../../../common.h"
#if defined(MLD_SYS_RISCV64_RVV) && defined(MLD_ARITH_BACKEND_RISCV64) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)
/* simpasm: header-end */

#include "rv64v_ntt.inc"

/*
 * Inverse NTT with 8 lanes per register, see rv64v_ntt.inc; the reverse
 * of the forward NTT. Pass B and pass A each run in 2 batches.
 *
 * Requires VLEN = 256: the register groups of layers 1-4 assume that each
 * register holds exactly the VL lanes in use.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(intt_vlen256_riscv64_asm)
MLD_ASM_FN_SYMBOL(intt_vlen256_riscv64_asm)

        ntt_setup   8

        /* Pass B: layers 8-5 */
        mv          ptr, data
        addi        lane_ptr, zetas, 128
        li          batch, 2
mld_intt_vlen256_riscv64_pass_b:
        vsetvl_m1
        access_pass_b vlse32.v
        intt_layers8765
        vsetvl_m1
        access_pass_b vsse32.v
        addi        ptr, ptr, (64 * 8)
        addi        lane_ptr, lane_ptr, (4 * 8)
        addi        batch, batch, -1
        bnez        batch, mld_intt_vlen256_riscv64_pass_b

        /* Pass A: layers 4-1 */
        mv          ptr, data
        li          batch, 2
mld_intt_vlen256_riscv64_pass_a:
        vsetvl_m1
        access_pass_a vle32.v
        intt_layers4321
        vsetvl_m1
        access_pass_a vse32.v
        addi        ptr, ptr, (4 * 8)
        addi        batch, batch, -1
        bnez        batch, mld_intt_vlen256_riscv64_pass_a

        ret
.option pop

MLD_ASM_FN_SIZE(intt_vlen256_riscv64_asm)

/* simpasm: footer-start */
#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */
