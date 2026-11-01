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
; Name: poly_decompose_88_aarch64_asm
; Description: AArch64 coefficient decomposition (alpha = (Q-1)/88)
; Signature: void mld_poly_decompose_88_aarch64_asm(int32_t a1[256], int32_t a0[256])
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t a1[256]
;     description: Output high-part polynomial (256 x int32_t)
;   x1:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t a0[256]
;     description: Input polynomial / output low-part (256 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_poly_decompose_88_aarch64_asm"
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
        mov      w5, #0x6c00                             ; 0x0000000C, line   27
        movk     w5, #0x7e, lsl #16                      ; 0x00000010, line   28
        dup      v21.4s, w5                              ; 0x00000014, line   29
        mov      w7, #0xe800                             ; 0x00000018, line   30
        movk     w7, #0x2, lsl #16                       ; 0x0000001C, line   31
        dup      v22.4s, w7                              ; 0x00000020, line   32
        mov      w11, #0x581                             ; 0x00000024, line   33
        movk     w11, #0x5816, lsl #16                   ; 0x00000028, line   34
        dup      v23.4s, w11                             ; 0x0000002C, line   35
        mov      x3, #0x10                               ; 0x00000030, line   36
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_poly_decompose_88_loop

        ldr      q0, [x1]                                ; 0x00000040, line   38
        ldr      q1, [x1, #0x10]                         ; 0x00000044, line   39
        ldr      q2, [x1, #0x20]                         ; 0x00000048, line   40
        ldr      q3, [x1, #0x30]                         ; 0x0000004C, line   41
        sqdmulh  v5.4s, v1.4s, v23.4s                    ; 0x00000050, line   42
        srshr    v5.4s, v5.4s, #0x11                     ; 0x00000054, line   43
        cmgt     v24.4s, v1.4s, v21.4s                   ; 0x00000058, line   44
        mls      v1.4s, v5.4s, v22.4s                    ; 0x0000005C, line   45
        bic      v5.16b, v5.16b, v24.16b                 ; 0x00000060, line   46
        add      v1.4s, v1.4s, v24.4s                    ; 0x00000064, line   47
        sqdmulh  v6.4s, v2.4s, v23.4s                    ; 0x00000068, line   48
        srshr    v6.4s, v6.4s, #0x11                     ; 0x0000006C, line   49
        cmgt     v24.4s, v2.4s, v21.4s                   ; 0x00000070, line   50
        mls      v2.4s, v6.4s, v22.4s                    ; 0x00000074, line   51
        bic      v6.16b, v6.16b, v24.16b                 ; 0x00000078, line   52
        add      v2.4s, v2.4s, v24.4s                    ; 0x0000007C, line   53
        sqdmulh  v7.4s, v3.4s, v23.4s                    ; 0x00000080, line   54
        srshr    v7.4s, v7.4s, #0x11                     ; 0x00000084, line   55
        cmgt     v24.4s, v3.4s, v21.4s                   ; 0x00000088, line   56
        mls      v3.4s, v7.4s, v22.4s                    ; 0x0000008C, line   57
        bic      v7.16b, v7.16b, v24.16b                 ; 0x00000090, line   58
        add      v3.4s, v3.4s, v24.4s                    ; 0x00000094, line   59
        sqdmulh  v4.4s, v0.4s, v23.4s                    ; 0x00000098, line   60
        srshr    v4.4s, v4.4s, #0x11                     ; 0x0000009C, line   61
        cmgt     v24.4s, v0.4s, v21.4s                   ; 0x000000A0, line   62
        mls      v0.4s, v4.4s, v22.4s                    ; 0x000000A4, line   63
        bic      v4.16b, v4.16b, v24.16b                 ; 0x000000A8, line   64
        add      v0.4s, v0.4s, v24.4s                    ; 0x000000AC, line   65
        str      q5, [x0, #0x10]                         ; 0x000000B0, line   66
        str      q6, [x0, #0x20]                         ; 0x000000B4, line   67
        str      q7, [x0, #0x30]                         ; 0x000000B8, line   68
        str      q4, [x0], #0x40                         ; 0x000000BC, line   69
        str      q1, [x1, #0x10]                         ; 0x000000C0, line   70
        str      q2, [x1, #0x20]                         ; 0x000000C4, line   71
        str      q3, [x1, #0x30]                         ; 0x000000C8, line   72
        str      q0, [x1], #0x40                         ; 0x000000CC, line   73
        subs     x3, x3, #0x1                            ; 0x000000D0, line   74
        b.ne     Lmld_poly_decompose_88_loop             ; 0x000000D4, line   75
        ret                                              ; 0x000000D8, line   76
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x000000DC byte(s)

        END
