;
; Copyright (c) 2022 Arm Limited
; Copyright(c) 2022 Hanno Becker
; Copyright (c) 2023 Amin Abdulrahman, Matthias Kannwischer
; Copyright (c) The mlkem-native project authors
; Copyright (c) The mldsa-native project authors
; SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
;

;  References
;  ==========
;
;  - [NeonNTT]
;    Neon NTT: Faster Dilithium, Kyber, and Saber on Cortex-A72 and Apple M1
;    Becker, Hwang, Kannwischer, Yang, Yang
;    https://eprint.iacr.org/2021/986
;
;  - [NeonNTT_Autoformalised]
;    Neon NTT - (Auto)formalised
;    Hanno Becker
;    https://eprint.iacr.org/2026/1223
;
;  - [SLOTHY_Paper]
;    Fast and Clean: Auditable high-performance assembly via constraint solving
;    Abdulrahman, Becker, Kannwischer, Klein
;    https://eprint.iacr.org/2022/1303
;
; Windows ARM64 port:
; 'armasm64.exe' re-formatting and SEH unwind information provided by
; Ingo A. Kubbilun <ingo.kubbilun@gmail.com>, Oct. 2026
;

; yaml
; Name: poly_pointwise_montgomery_aarch64_asm
; Description: AArch64 pointwise Montgomery multiplication of two polynomials
; Signature: void mld_poly_pointwise_montgomery_aarch64_asm(int32_t a[256], const int32_t b[256])
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t a[256]
;     description: Input/output polynomial (256 x int32_t)
;   x1:
;     type: buffer
;     size_bytes: 1024
;     permissions: read-only
;     c_parameter: const int32_t b[256]
;     description: Input polynomial (256 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_poly_pointwise_montgomery_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        mov     w3, #0xe001                                   ; 0x00000000, line   24
        movk    w3, #0x7f, lsl #16                            ; 0x00000004, line   25
        dup     v0.4s, w3                                     ; 0x00000008, line   26
        mov     w3, #0x2001                                   ; 0x0000000C, line   27
        movk    w3, #0x380, lsl #16                           ; 0x00000010, line   28
        dup     v1.4s, w3                                     ; 0x00000014, line   29
        mov     x3, #0x40                                     ; 0x00000018, line   30
        HINT    #0x0                                          ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_poly_pointwise_montgomery_loop_start

        ldr     q16, [x0]                                     ; 0x00000020, line   33
        ldr     q17, [x0, #0x10]                              ; 0x00000024, line   34
        ldr     q18, [x0, #0x20]                              ; 0x00000028, line   35
        ldr     q19, [x0, #0x30]                              ; 0x0000002C, line   36
        ldr     q21, [x1, #0x10]                              ; 0x00000030, line   37
        ldr     q22, [x1, #0x20]                              ; 0x00000034, line   38
        ldr     q23, [x1, #0x30]                              ; 0x00000038, line   39
        ldr     q20, [x1], #0x40                              ; 0x0000003C, line   40
        smull   v24.2d, v16.2s, v20.2s                        ; 0x00000040, line   41
        smull2  v25.2d, v16.4s, v20.4s                        ; 0x00000044, line   42
        smull   v26.2d, v17.2s, v21.2s                        ; 0x00000048, line   43
        smull2  v27.2d, v17.4s, v21.4s                        ; 0x0000004C, line   44
        smull   v28.2d, v18.2s, v22.2s                        ; 0x00000050, line   45
        smull2  v29.2d, v18.4s, v22.4s                        ; 0x00000054, line   46
        smull   v30.2d, v19.2s, v23.2s                        ; 0x00000058, line   47
        smull2  v31.2d, v19.4s, v23.4s                        ; 0x0000005C, line   48
        uzp1    v16.4s, v24.4s, v25.4s                        ; 0x00000060, line   49
        mul     v16.4s, v16.4s, v1.4s                         ; 0x00000064, line   50
        smlsl   v24.2d, v16.2s, v0.2s                         ; 0x00000068, line   51
        smlsl2  v25.2d, v16.4s, v0.4s                         ; 0x0000006C, line   52
        uzp2    v16.4s, v24.4s, v25.4s                        ; 0x00000070, line   53
        uzp1    v17.4s, v26.4s, v27.4s                        ; 0x00000074, line   54
        mul     v17.4s, v17.4s, v1.4s                         ; 0x00000078, line   55
        smlsl   v26.2d, v17.2s, v0.2s                         ; 0x0000007C, line   56
        smlsl2  v27.2d, v17.4s, v0.4s                         ; 0x00000080, line   57
        uzp2    v17.4s, v26.4s, v27.4s                        ; 0x00000084, line   58
        uzp1    v18.4s, v28.4s, v29.4s                        ; 0x00000088, line   59
        mul     v18.4s, v18.4s, v1.4s                         ; 0x0000008C, line   60
        smlsl   v28.2d, v18.2s, v0.2s                         ; 0x00000090, line   61
        smlsl2  v29.2d, v18.4s, v0.4s                         ; 0x00000094, line   62
        uzp2    v18.4s, v28.4s, v29.4s                        ; 0x00000098, line   63
        uzp1    v19.4s, v30.4s, v31.4s                        ; 0x0000009C, line   64
        mul     v19.4s, v19.4s, v1.4s                         ; 0x000000A0, line   65
        smlsl   v30.2d, v19.2s, v0.2s                         ; 0x000000A4, line   66
        smlsl2  v31.2d, v19.4s, v0.4s                         ; 0x000000A8, line   67
        uzp2    v19.4s, v30.4s, v31.4s                        ; 0x000000AC, line   68
        str     q17, [x0, #0x10]                              ; 0x000000B0, line   69
        str     q18, [x0, #0x20]                              ; 0x000000B4, line   70
        str     q19, [x0, #0x30]                              ; 0x000000B8, line   71
        str     q16, [x0], #0x40                              ; 0x000000BC, line   72
        subs    x3, x3, #0x4                                  ; 0x000000C0, line   73
        cbnz    x3, Lmld_poly_pointwise_montgomery_loop_start ; 0x000000C4, line   74
        ret                                                   ; 0x000000C8, line   75
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x000000CC byte(s)

        END
