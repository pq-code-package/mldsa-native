/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*yaml
  Name: ntt_vlen256_riscv64_asm
  Description: Forward negacyclic NTT of a polynomial in place, output in bitreversed order (VLEN=256 only)
  Signature: void mld_ntt_vlen256_riscv64_asm(int32_t p[256], const int32_t zetas[512])
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

/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_ntt_vlen256_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
.global MLD_ASM_NAMESPACE(ntt_vlen256_riscv64_asm)
MLD_ASM_FN_SYMBOL(ntt_vlen256_riscv64_asm)

        csrwi vxrm, 0x0
        lui t0, 0x7fe
        addiw t0, t0, 0x1
        li t4, 0x40
        li a2, 0x8
        li a3, 0x10
        li a4, 0x20
        li a5, 0x40
        mv a6, a0
        li t5, 0x2

mld_ntt_vlen256_riscv64_pass_a:
        vsetvli zero, a2, e32, m1, ta, ma
        mv t3, a6
        vle32.v v16, (t3)
        addi t3, t3, 0x40
        vle32.v v17, (t3)
        addi t3, t3, 0x40
        vle32.v v18, (t3)
        addi t3, t3, 0x40
        vle32.v v19, (t3)
        addi t3, t3, 0x40
        vle32.v v20, (t3)
        addi t3, t3, 0x40
        vle32.v v21, (t3)
        addi t3, t3, 0x40
        vle32.v v22, (t3)
        addi t3, t3, 0x40
        vle32.v v23, (t3)
        addi t3, t3, 0x40
        vle32.v v24, (t3)
        addi t3, t3, 0x40
        vle32.v v25, (t3)
        addi t3, t3, 0x40
        vle32.v v26, (t3)
        addi t3, t3, 0x40
        vle32.v v27, (t3)
        addi t3, t3, 0x40
        vle32.v v28, (t3)
        addi t3, t3, 0x40
        vle32.v v29, (t3)
        addi t3, t3, 0x40
        vle32.v v30, (t3)
        addi t3, t3, 0x40
        vle32.v v31, (t3)
        addi t3, t3, 0x40
        vsetvli zero, a5, e32, m8, ta, ma
        lw t1, 0x0(a1)
        lw t2, 0x4(a1)
        vmul.vx v0, v24, t1
        vsmul.vx v24, v24, t2
        vnmsac.vx v0, t0, v24
        vsub.vv v24, v16, v0
        vadd.vv v16, v16, v0
        vsetvli zero, a4, e32, m4, ta, ma
        lw t1, 0x8(a1)
        lw t2, 0xc(a1)
        vmul.vx v0, v20, t1
        vsmul.vx v20, v20, t2
        vnmsac.vx v0, t0, v20
        vsub.vv v20, v16, v0
        vadd.vv v16, v16, v0
        lw t1, 0x10(a1)
        lw t2, 0x14(a1)
        vmul.vx v0, v28, t1
        vsmul.vx v28, v28, t2
        vnmsac.vx v0, t0, v28
        vsub.vv v28, v24, v0
        vadd.vv v24, v24, v0
        vsetvli zero, a3, e32, m2, ta, ma
        lw t1, 0x18(a1)
        lw t2, 0x1c(a1)
        vmul.vx v0, v18, t1
        vsmul.vx v18, v18, t2
        vnmsac.vx v0, t0, v18
        vsub.vv v18, v16, v0
        vadd.vv v16, v16, v0
        lw t1, 0x20(a1)
        lw t2, 0x24(a1)
        vmul.vx v0, v22, t1
        vsmul.vx v22, v22, t2
        vnmsac.vx v0, t0, v22
        vsub.vv v22, v20, v0
        vadd.vv v20, v20, v0
        lw t1, 0x28(a1)
        lw t2, 0x2c(a1)
        vmul.vx v0, v26, t1
        vsmul.vx v26, v26, t2
        vnmsac.vx v0, t0, v26
        vsub.vv v26, v24, v0
        vadd.vv v24, v24, v0
        lw t1, 0x30(a1)
        lw t2, 0x34(a1)
        vmul.vx v0, v30, t1
        vsmul.vx v30, v30, t2
        vnmsac.vx v0, t0, v30
        vsub.vv v30, v28, v0
        vadd.vv v28, v28, v0
        vsetvli zero, a2, e32, m1, ta, ma
        lw t1, 0x38(a1)
        lw t2, 0x3c(a1)
        vmul.vx v0, v17, t1
        vsmul.vx v17, v17, t2
        vnmsac.vx v0, t0, v17
        vsub.vv v17, v16, v0
        vadd.vv v16, v16, v0
        lw t1, 0x40(a1)
        lw t2, 0x44(a1)
        vmul.vx v0, v19, t1
        vsmul.vx v19, v19, t2
        vnmsac.vx v0, t0, v19
        vsub.vv v19, v18, v0
        vadd.vv v18, v18, v0
        lw t1, 0x48(a1)
        lw t2, 0x4c(a1)
        vmul.vx v0, v21, t1
        vsmul.vx v21, v21, t2
        vnmsac.vx v0, t0, v21
        vsub.vv v21, v20, v0
        vadd.vv v20, v20, v0
        lw t1, 0x50(a1)
        lw t2, 0x54(a1)
        vmul.vx v0, v23, t1
        vsmul.vx v23, v23, t2
        vnmsac.vx v0, t0, v23
        vsub.vv v23, v22, v0
        vadd.vv v22, v22, v0
        lw t1, 0x58(a1)
        lw t2, 0x5c(a1)
        vmul.vx v0, v25, t1
        vsmul.vx v25, v25, t2
        vnmsac.vx v0, t0, v25
        vsub.vv v25, v24, v0
        vadd.vv v24, v24, v0
        lw t1, 0x60(a1)
        lw t2, 0x64(a1)
        vmul.vx v0, v27, t1
        vsmul.vx v27, v27, t2
        vnmsac.vx v0, t0, v27
        vsub.vv v27, v26, v0
        vadd.vv v26, v26, v0
        lw t1, 0x68(a1)
        lw t2, 0x6c(a1)
        vmul.vx v0, v29, t1
        vsmul.vx v29, v29, t2
        vnmsac.vx v0, t0, v29
        vsub.vv v29, v28, v0
        vadd.vv v28, v28, v0
        lw t1, 0x70(a1)
        lw t2, 0x74(a1)
        vmul.vx v0, v31, t1
        vsmul.vx v31, v31, t2
        vnmsac.vx v0, t0, v31
        vsub.vv v31, v30, v0
        vadd.vv v30, v30, v0
        vsetvli zero, a2, e32, m1, ta, ma
        mv t3, a6
        vse32.v v16, (t3)
        addi t3, t3, 0x40
        vse32.v v17, (t3)
        addi t3, t3, 0x40
        vse32.v v18, (t3)
        addi t3, t3, 0x40
        vse32.v v19, (t3)
        addi t3, t3, 0x40
        vse32.v v20, (t3)
        addi t3, t3, 0x40
        vse32.v v21, (t3)
        addi t3, t3, 0x40
        vse32.v v22, (t3)
        addi t3, t3, 0x40
        vse32.v v23, (t3)
        addi t3, t3, 0x40
        vse32.v v24, (t3)
        addi t3, t3, 0x40
        vse32.v v25, (t3)
        addi t3, t3, 0x40
        vse32.v v26, (t3)
        addi t3, t3, 0x40
        vse32.v v27, (t3)
        addi t3, t3, 0x40
        vse32.v v28, (t3)
        addi t3, t3, 0x40
        vse32.v v29, (t3)
        addi t3, t3, 0x40
        vse32.v v30, (t3)
        addi t3, t3, 0x40
        vse32.v v31, (t3)
        addi t3, t3, 0x40
        addi a6, a6, 0x20
        addi t5, t5, -0x1
        bnez t5, mld_ntt_vlen256_riscv64_pass_a
        mv a6, a0
        addi a7, a1, 0x80
        li t5, 0x2

mld_ntt_vlen256_riscv64_pass_b:
        vsetvli zero, a2, e32, m1, ta, ma
        mv t3, a6
        vlse32.v v16, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v17, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v18, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v19, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v20, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v21, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v22, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v23, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v24, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v25, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v26, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v27, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v28, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v29, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v30, (t3), t4
        addi t3, t3, 0x4
        vlse32.v v31, (t3), t4
        addi t3, t3, 0x4
        vsetvli zero, a2, e32, m1, ta, ma
        mv t3, a7
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vmul.vv v0, v24, v8
        vsmul.vv v4, v24, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v24, v16, v0
        vadd.vv v16, v16, v0
        vmul.vv v0, v28, v8
        vsmul.vv v4, v28, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v28, v20, v0
        vadd.vv v20, v20, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x80
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vmul.vv v0, v20, v8
        vsmul.vv v4, v20, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v20, v16, v0
        vadd.vv v16, v16, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x100
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vmul.vv v0, v28, v8
        vsmul.vv v4, v28, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v28, v24, v0
        vadd.vv v24, v24, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x180
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vmul.vv v0, v18, v8
        vsmul.vv v4, v18, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v18, v16, v0
        vadd.vv v16, v16, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x200
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vmul.vv v0, v22, v8
        vsmul.vv v4, v22, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v22, v20, v0
        vadd.vv v20, v20, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x280
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vmul.vv v0, v26, v8
        vsmul.vv v4, v26, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v26, v24, v0
        vadd.vv v24, v24, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x300
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vmul.vv v0, v30, v8
        vsmul.vv v4, v30, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v30, v28, v0
        vadd.vv v28, v28, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x380
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v17, v8
        vsmul.vv v4, v17, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v17, v16, v0
        vadd.vv v16, v16, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x400
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v19, v8
        vsmul.vv v4, v19, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v19, v18, v0
        vadd.vv v18, v18, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x480
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v21, v8
        vsmul.vv v4, v21, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v21, v20, v0
        vadd.vv v20, v20, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x500
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v23, v8
        vsmul.vv v4, v23, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v23, v22, v0
        vadd.vv v22, v22, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x580
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v25, v8
        vsmul.vv v4, v25, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v25, v24, v0
        vadd.vv v24, v24, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x600
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v27, v8
        vsmul.vv v4, v27, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v27, v26, v0
        vadd.vv v26, v26, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x680
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v29, v8
        vsmul.vv v4, v29, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v29, v28, v0
        vadd.vv v28, v28, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x700
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmul.vv v0, v31, v8
        vsmul.vv v4, v31, v12
        vnmsac.vx v0, t0, v4
        vsub.vv v31, v30, v0
        vadd.vv v30, v30, v0
        vsetvli zero, a2, e32, m1, ta, ma
        mv t3, a6
        vsse32.v v16, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v17, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v18, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v19, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v20, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v21, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v22, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v23, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v24, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v25, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v26, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v27, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v28, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v29, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v30, (t3), t4
        addi t3, t3, 0x4
        vsse32.v v31, (t3), t4
        addi t3, t3, 0x4
        addi a6, a6, 0x200
        addi a7, a7, 0x20
        addi t5, t5, -0x1
        bnez t5, mld_ntt_vlen256_riscv64_pass_b
        ret

.option pop
MLD_ASM_FN_SIZE(ntt_vlen256_riscv64_asm)

#endif /* MLD_SYS_RISCV64_RVV && MLD_ARITH_BACKEND_RISCV64 && \
          !MLD_CONFIG_MULTILEVEL_NO_SHARED */

#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
