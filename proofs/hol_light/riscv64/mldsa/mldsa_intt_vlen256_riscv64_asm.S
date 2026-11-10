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


/*
 * WARNING: This file is auto-derived from the mldsa-native source file
 *   dev/riscv64/src/mldsa_intt_vlen256_riscv64_asm.S using scripts/simpasm. Do not modify it directly.
 */

.text
.option push
.option norvc
.option norelax
.balign 4
#ifdef __APPLE__
.global _mld_intt_vlen256_riscv64_asm
_mld_intt_vlen256_riscv64_asm:
#else
.global mld_intt_vlen256_riscv64_asm
mld_intt_vlen256_riscv64_asm:
#endif

        csrwi vxrm, 0x0
        lui t0, 0x7fe
        addiw t0, t0, 0x1
        li t4, 0x40
        li a2, 0x8
        li a3, 0x10
        li a4, 0x20
        li a5, 0x40
        mv a6, a0
        addi a7, a1, 0x80
        li t5, 0x2

mld_intt_vlen256_riscv64_pass_b:
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
        vsub.vv v0, v16, v17
        vadd.vv v16, v16, v17
        vmul.vv v17, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v17, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x80
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v18, v19
        vadd.vv v18, v18, v19
        vmul.vv v19, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v19, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x100
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v20, v21
        vadd.vv v20, v20, v21
        vmul.vv v21, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v21, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x180
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v22, v23
        vadd.vv v22, v22, v23
        vmul.vv v23, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v23, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x200
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v24, v25
        vadd.vv v24, v24, v25
        vmul.vv v25, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v25, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x280
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v26, v27
        vadd.vv v26, v26, v27
        vmul.vv v27, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v27, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x300
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v28, v29
        vadd.vv v28, v28, v29
        vmul.vv v29, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v29, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x380
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vsub.vv v0, v30, v31
        vadd.vv v30, v30, v31
        vmul.vv v31, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v31, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x400
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vsub.vv v0, v16, v18
        vadd.vv v16, v16, v18
        vmul.vv v18, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v18, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x480
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vsub.vv v0, v20, v22
        vadd.vv v20, v20, v22
        vmul.vv v22, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v22, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x500
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vsub.vv v0, v24, v26
        vadd.vv v24, v24, v26
        vmul.vv v26, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v26, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x580
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vsetvli zero, a3, e32, m2, ta, ma
        vsub.vv v0, v28, v30
        vadd.vv v28, v28, v30
        vmul.vv v30, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v30, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x600
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vsub.vv v0, v16, v20
        vadd.vv v16, v16, v20
        vmul.vv v20, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v20, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x680
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vsub.vv v0, v24, v28
        vadd.vv v24, v24, v28
        vmul.vv v28, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v28, t0, v0
        vsetvli zero, a2, e32, m1, ta, ma
        addi t3, a7, 0x700
        vle32.v v8, (t3)
        addi t3, t3, 0x40
        vle32.v v12, (t3)
        vmv1r.v v9, v8
        vmv1r.v v13, v12
        vmv2r.v v10, v8
        vmv2r.v v14, v12
        vsetvli zero, a4, e32, m4, ta, ma
        vsub.vv v0, v16, v24
        vadd.vv v16, v16, v24
        vmul.vv v24, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v24, t0, v0
        vsub.vv v0, v20, v28
        vadd.vv v20, v20, v28
        vmul.vv v28, v0, v8
        vsmul.vv v0, v0, v12
        vnmsac.vx v28, t0, v0
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
        bnez t5, mld_intt_vlen256_riscv64_pass_b
        mv a6, a0
        li t5, 0x2

mld_intt_vlen256_riscv64_pass_a:
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
        vsetvli zero, a2, e32, m1, ta, ma
        lw t1, 0x0(a1)
        lw t2, 0x4(a1)
        vsub.vv v0, v16, v17
        vadd.vv v16, v16, v17
        vmul.vx v17, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v17, t0, v0
        lw t1, 0x8(a1)
        lw t2, 0xc(a1)
        vsub.vv v0, v18, v19
        vadd.vv v18, v18, v19
        vmul.vx v19, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v19, t0, v0
        lw t1, 0x10(a1)
        lw t2, 0x14(a1)
        vsub.vv v0, v20, v21
        vadd.vv v20, v20, v21
        vmul.vx v21, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v21, t0, v0
        lw t1, 0x18(a1)
        lw t2, 0x1c(a1)
        vsub.vv v0, v22, v23
        vadd.vv v22, v22, v23
        vmul.vx v23, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v23, t0, v0
        lw t1, 0x20(a1)
        lw t2, 0x24(a1)
        vsub.vv v0, v24, v25
        vadd.vv v24, v24, v25
        vmul.vx v25, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v25, t0, v0
        lw t1, 0x28(a1)
        lw t2, 0x2c(a1)
        vsub.vv v0, v26, v27
        vadd.vv v26, v26, v27
        vmul.vx v27, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v27, t0, v0
        lw t1, 0x30(a1)
        lw t2, 0x34(a1)
        vsub.vv v0, v28, v29
        vadd.vv v28, v28, v29
        vmul.vx v29, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v29, t0, v0
        lw t1, 0x38(a1)
        lw t2, 0x3c(a1)
        vsub.vv v0, v30, v31
        vadd.vv v30, v30, v31
        vmul.vx v31, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v31, t0, v0
        vsetvli zero, a3, e32, m2, ta, ma
        lw t1, 0x40(a1)
        lw t2, 0x44(a1)
        vsub.vv v0, v16, v18
        vadd.vv v16, v16, v18
        vmul.vx v18, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v18, t0, v0
        lw t1, 0x48(a1)
        lw t2, 0x4c(a1)
        vsub.vv v0, v20, v22
        vadd.vv v20, v20, v22
        vmul.vx v22, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v22, t0, v0
        lw t1, 0x50(a1)
        lw t2, 0x54(a1)
        vsub.vv v0, v24, v26
        vadd.vv v24, v24, v26
        vmul.vx v26, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v26, t0, v0
        lw t1, 0x58(a1)
        lw t2, 0x5c(a1)
        vsub.vv v0, v28, v30
        vadd.vv v28, v28, v30
        vmul.vx v30, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v30, t0, v0
        vsetvli zero, a4, e32, m4, ta, ma
        lw t1, 0x60(a1)
        lw t2, 0x64(a1)
        vsub.vv v0, v16, v20
        vadd.vv v16, v16, v20
        vmul.vx v20, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v20, t0, v0
        lw t1, 0x68(a1)
        lw t2, 0x6c(a1)
        vsub.vv v0, v24, v28
        vadd.vv v24, v24, v28
        vmul.vx v28, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v28, t0, v0
        vsetvli zero, a5, e32, m8, ta, ma
        lw t1, 0x70(a1)
        lw t2, 0x74(a1)
        vsub.vv v0, v16, v24
        vadd.vv v16, v16, v24
        vmul.vx v24, v0, t1
        vsmul.vx v0, v0, t2
        vnmsac.vx v24, t0, v0
        lw t1, 0x78(a1)
        lw t2, 0x7c(a1)
        vsmul.vx v0, v16, t2
        vmul.vx v16, v16, t1
        vnmsac.vx v16, t0, v0
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
        bnez t5, mld_intt_vlen256_riscv64_pass_a
        ret

.option pop
#if defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
