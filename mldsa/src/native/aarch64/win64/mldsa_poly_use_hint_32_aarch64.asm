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
; Name: poly_use_hint_32_aarch64_asm
; Description: AArch64 hint application (alpha = (Q-1)/32)
; Signature: void mld_poly_use_hint_32_aarch64_asm(int32_t a[256], const int32_t h[256])
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
;     c_parameter: const int32_t h[256]
;     description: Hint polynomial (256 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_poly_use_hint_32_aarch64_asm"
        ENDIF

        AREA     |.drectve|, DRECTVE

        EXPORT   $FUNC_NAME

        AREA     |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN    16

$FUNC_NAME PROC

        ; .cfi_startproc
        mov      w4, #0xe001                             ; 0x00000000, line   24
        movk     w4, #0x7f, lsl #16                      ; 0x00000004, line   25
        dup      v20.4s, w4                              ; 0x00000008, line   26
        mov      w5, #0xe100                             ; 0x0000000C, line   27
        movk     w5, #0x7b, lsl #16                      ; 0x00000010, line   28
        dup      v21.4s, w5                              ; 0x00000014, line   29
        mov      w7, #0xfe00                             ; 0x00000018, line   30
        movk     w7, #0x7, lsl #16                       ; 0x0000001C, line   31
        dup      v22.4s, w7                              ; 0x00000020, line   32
        mov      w11, #0x401                             ; 0x00000024, line   33
        movk     w11, #0x4010, lsl #16                   ; 0x00000028, line   34
        dup      v23.4s, w11                             ; 0x0000002C, line   35
        movi     v24.4s, #0xf                            ; 0x00000030, line   36
        mov      x3, #0x10                               ; 0x00000034, line   37
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_poly_use_hint_32_loop

        ldr      q1, [x0, #0x10]                         ; 0x00000040, line   39
        ldr      q2, [x0, #0x20]                         ; 0x00000044, line   40
        ldr      q3, [x0, #0x30]                         ; 0x00000048, line   41
        ldr      q0, [x0]                                ; 0x0000004C, line   42
        ldr      q5, [x1, #0x10]                         ; 0x00000050, line   43
        ldr      q6, [x1, #0x20]                         ; 0x00000054, line   44
        ldr      q7, [x1, #0x30]                         ; 0x00000058, line   45
        ldr      q4, [x1], #0x40                         ; 0x0000005C, line   46
        sqdmulh  v17.4s, v1.4s, v23.4s                   ; 0x00000060, line   47
        srshr    v17.4s, v17.4s, #0x12                   ; 0x00000064, line   48
        cmgt     v25.4s, v1.4s, v21.4s                   ; 0x00000068, line   49
        mls      v1.4s, v17.4s, v22.4s                   ; 0x0000006C, line   50
        bic      v17.16b, v17.16b, v25.16b               ; 0x00000070, line   51
        add      v1.4s, v1.4s, v25.4s                    ; 0x00000074, line   52
        cmle     v1.4s, v1.4s, #0                        ; 0x00000078, line   53
        orr      v1.4s, #0x1                             ; 0x0000007C, line   54
        mla      v17.4s, v1.4s, v5.4s                    ; 0x00000080, line   55
        and      v17.16b, v17.16b, v24.16b               ; 0x00000084, line   56
        sqdmulh  v18.4s, v2.4s, v23.4s                   ; 0x00000088, line   57
        srshr    v18.4s, v18.4s, #0x12                   ; 0x0000008C, line   58
        cmgt     v25.4s, v2.4s, v21.4s                   ; 0x00000090, line   59
        mls      v2.4s, v18.4s, v22.4s                   ; 0x00000094, line   60
        bic      v18.16b, v18.16b, v25.16b               ; 0x00000098, line   61
        add      v2.4s, v2.4s, v25.4s                    ; 0x0000009C, line   62
        cmle     v2.4s, v2.4s, #0                        ; 0x000000A0, line   63
        orr      v2.4s, #0x1                             ; 0x000000A4, line   64
        mla      v18.4s, v2.4s, v6.4s                    ; 0x000000A8, line   65
        and      v18.16b, v18.16b, v24.16b               ; 0x000000AC, line   66
        sqdmulh  v19.4s, v3.4s, v23.4s                   ; 0x000000B0, line   67
        srshr    v19.4s, v19.4s, #0x12                   ; 0x000000B4, line   68
        cmgt     v25.4s, v3.4s, v21.4s                   ; 0x000000B8, line   69
        mls      v3.4s, v19.4s, v22.4s                   ; 0x000000BC, line   70
        bic      v19.16b, v19.16b, v25.16b               ; 0x000000C0, line   71
        add      v3.4s, v3.4s, v25.4s                    ; 0x000000C4, line   72
        cmle     v3.4s, v3.4s, #0                        ; 0x000000C8, line   73
        orr      v3.4s, #0x1                             ; 0x000000CC, line   74
        mla      v19.4s, v3.4s, v7.4s                    ; 0x000000D0, line   75
        and      v19.16b, v19.16b, v24.16b               ; 0x000000D4, line   76
        sqdmulh  v16.4s, v0.4s, v23.4s                   ; 0x000000D8, line   77
        srshr    v16.4s, v16.4s, #0x12                   ; 0x000000DC, line   78
        cmgt     v25.4s, v0.4s, v21.4s                   ; 0x000000E0, line   79
        mls      v0.4s, v16.4s, v22.4s                   ; 0x000000E4, line   80
        bic      v16.16b, v16.16b, v25.16b               ; 0x000000E8, line   81
        add      v0.4s, v0.4s, v25.4s                    ; 0x000000EC, line   82
        cmle     v0.4s, v0.4s, #0                        ; 0x000000F0, line   83
        orr      v0.4s, #0x1                             ; 0x000000F4, line   84
        mla      v16.4s, v0.4s, v4.4s                    ; 0x000000F8, line   85
        and      v16.16b, v16.16b, v24.16b               ; 0x000000FC, line   86
        str      q17, [x0, #0x10]                        ; 0x00000100, line   87
        str      q18, [x0, #0x20]                        ; 0x00000104, line   88
        str      q19, [x0, #0x30]                        ; 0x00000108, line   89
        str      q16, [x0], #0x40                        ; 0x0000010C, line   90
        subs     x3, x3, #0x1                            ; 0x00000110, line   91
        b.ne     Lmld_poly_use_hint_32_loop              ; 0x00000114, line   92
        ret                                              ; 0x00000118, line   93
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x0000011C byte(s)

        END
