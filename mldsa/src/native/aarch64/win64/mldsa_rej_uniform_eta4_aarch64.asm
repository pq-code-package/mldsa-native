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
; Name: rej_uniform_eta4_aarch64_asm
; Description: AArch64 rejection sampling of eta=4 secret coefficients
; Signature: uint64_t mld_rej_uniform_eta4_aarch64_asm(int32_t r[256], const uint8_t *buf, uint64_t buflen, const uint8_t table[4096])
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t r[256]
;     description: Output buffer (256 x int32_t)
;   x1:
;     type: buffer
;     size_bytes: x2
;     permissions: read-only
;     c_parameter: const uint8_t *buf
;     description: Input buffer
;   x2:
;     type: scalar
;     c_parameter: uint64_t buflen
;     description: Length of input buffer (must be a multiple of 8)
;     test_with: 272  # MLD_AARCH64_REJ_UNIFORM_ETA4_BUFLEN
;   x3:
;     type: buffer
;     size_bytes: 4096
;     permissions: read-only
;     c_parameter: const uint8_t table[4096]
;     description: Lookup table (4096 x uint8_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_rej_uniform_eta4_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        sub     sp, sp, #0x240                          ; 0x00000000, line   35
        ; .cfi_adjust_cfa_offset 0x240
        mov     x7, #0x1                                ; 0x00000004, line   37
        movk    x7, #0x2, lsl #16                       ; 0x00000008, line   38
        movk    x7, #0x4, lsl #32                       ; 0x0000000C, line   39
        movk    x7, #0x8, lsl #48                       ; 0x00000010, line   40
        mov     v31.d[0], x7                            ; 0x00000014, line   41
        mov     x7, #0x10                               ; 0x00000018, line   42
        movk    x7, #0x20, lsl #16                      ; 0x0000001C, line   43
        movk    x7, #0x40, lsl #32                      ; 0x00000020, line   44
        movk    x7, #0x80, lsl #48                      ; 0x00000024, line   45
        mov     v31.d[1], x7                            ; 0x00000028, line   46
        movi    v30.8h, #0x9                            ; 0x0000002C, line   47
        movi    v7.8h, #0x4                             ; 0x00000030, line   48
        mov     x8, sp                                  ; 0x00000034, line   49
        mov     x7, x8                                  ; 0x00000038, line   50
        mov     x11, #0x0                               ; 0x0000003C, line   51
        eor     v16.16b, v16.16b, v16.16b               ; 0x00000040, line   52
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_eta4_initial_zero

        str     q16, [x7], #0x40                        ; 0x00000050, line   55
        stur    q16, [x7, #-0x30]                       ; 0x00000054, line   56
        stur    q16, [x7, #-0x20]                       ; 0x00000058, line   57
        stur    q16, [x7, #-0x10]                       ; 0x0000005C, line   58
        add     x11, x11, #0x20                         ; 0x00000060, line   59
        cmp     x11, #0x100                             ; 0x00000064, line   60
        b.lt    Lmld_rej_uniform_eta4_initial_zero      ; 0x00000068, line   61
        mov     x7, x8                                  ; 0x0000006C, line   62
        mov     x9, #0x0                                ; 0x00000070, line   63
        mov     x4, #0x100                              ; 0x00000074, line   64
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_eta4_loop8

        cmp     x9, x4                                  ; 0x00000080, line   67
        b.hs    Lmld_rej_uniform_eta4_memory_copy       ; 0x00000084, line   68
        sub     x2, x2, #0x8                            ; 0x00000088, line   69
        ld1     { v0.8b }, [x1], #8                     ; 0x0000008C, line   70
        movi    v26.8b, #0xf                            ; 0x00000090, line   71
        and     v27.8b, v0.8b, v26.8b                   ; 0x00000094, line   72
        ushr    v28.8b, v0.8b, #0x4                     ; 0x00000098, line   73
        zip1    v26.8b, v27.8b, v28.8b                  ; 0x0000009C, line   74
        zip2    v29.8b, v27.8b, v28.8b                  ; 0x000000A0, line   75
        ushll   v16.8h, v26.8b, #0x0                    ; 0x000000A4, line   76
        ushll   v17.8h, v29.8b, #0x0                    ; 0x000000A8, line   77
        cmhi    v4.8h, v30.8h, v16.8h                   ; 0x000000AC, line   78
        cmhi    v5.8h, v30.8h, v17.8h                   ; 0x000000B0, line   79
        and     v4.16b, v4.16b, v31.16b                 ; 0x000000B4, line   80
        and     v5.16b, v5.16b, v31.16b                 ; 0x000000B8, line   81
        uaddlv  s20, v4.8h                              ; 0x000000BC, line   82
        uaddlv  s21, v5.8h                              ; 0x000000C0, line   83
        fmov    w12, s20                                ; 0x000000C4, line   84
        fmov    w13, s21                                ; 0x000000C8, line   85
        ldr     q24, [x3, x12, lsl #4]                  ; 0x000000CC, line   86
        ldr     q25, [x3, x13, lsl #4]                  ; 0x000000D0, line   87
        cnt     v4.16b, v4.16b                          ; 0x000000D4, line   88
        cnt     v5.16b, v5.16b                          ; 0x000000D8, line   89
        uaddlv  s20, v4.8h                              ; 0x000000DC, line   90
        uaddlv  s21, v5.8h                              ; 0x000000E0, line   91
        fmov    w12, s20                                ; 0x000000E4, line   92
        fmov    w13, s21                                ; 0x000000E8, line   93
        tbl     v16.16b, { v16.16b }, v24.16b           ; 0x000000EC, line   94
        tbl     v17.16b, { v17.16b }, v25.16b           ; 0x000000F0, line   95
        st1     { v16.8h }, [x7]                        ; 0x000000F4, line   96
        add     x7, x7, x12, lsl #1                     ; 0x000000F8, line   97
        st1     { v17.8h }, [x7]                        ; 0x000000FC, line   98
        add     x7, x7, x13, lsl #1                     ; 0x00000100, line   99
        add     x12, x12, x13                           ; 0x00000104, line  100
        add     x9, x9, x12                             ; 0x00000108, line  101
        cmp     x2, #0x8                                ; 0x0000010C, line  102
        b.hs    Lmld_rej_uniform_eta4_loop8             ; 0x00000110, line  103
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_eta4_memory_copy

        cmp     x9, x4                                  ; 0x00000120, line  106
        csel    x9, x9, x4, lo                          ; 0x00000124, line  107
        mov     x11, #0x0                               ; 0x00000128, line  108
        mov     x7, x8                                  ; 0x0000012C, line  109

Lmld_rej_uniform_eta4_final_copy

        ldr     q16, [x7], #0x20                        ; 0x00000130, line  112
        ldur    q18, [x7, #-0x10]                       ; 0x00000134, line  113
        sub     v16.8h, v7.8h, v16.8h                   ; 0x00000138, line  114
        sub     v18.8h, v7.8h, v18.8h                   ; 0x0000013C, line  115
        sshll2  v17.4s, v16.8h, #0x0                    ; 0x00000140, line  116
        sshll   v16.4s, v16.4h, #0x0                    ; 0x00000144, line  117
        sshll2  v19.4s, v18.8h, #0x0                    ; 0x00000148, line  118
        sshll   v18.4s, v18.4h, #0x0                    ; 0x0000014C, line  119
        str     q16, [x0], #0x40                        ; 0x00000150, line  120
        stur    q17, [x0, #-0x30]                       ; 0x00000154, line  121
        stur    q18, [x0, #-0x20]                       ; 0x00000158, line  122
        stur    q19, [x0, #-0x10]                       ; 0x0000015C, line  123
        add     x11, x11, #0x10                         ; 0x00000160, line  124
        cmp     x11, #0x100                             ; 0x00000164, line  125
        b.lt    Lmld_rej_uniform_eta4_final_copy        ; 0x00000168, line  126
        mov     x0, x9                                  ; 0x0000016C, line  127
        add     sp, sp, #0x240                          ; 0x00000170, line  128
        ; .cfi_adjust_cfa_offset -0x240
        ret                                             ; 0x00000174, line  130
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000178 byte(s)

        AREA    |.xdata|, DATA, READONLY, ALIGN=4

XDATA_$FUNC_NAME

        DCD     0x0820005E                              ; header dword
        DCB     0xC0, 0x24                              ; unwind code 'alloc_m', stack space 0x0240
        DCB     0xE4                                    ; unwind code 'end'
        DCB     0x00                                    ; unwind code padding

        AREA    |.pdata|, DATA, READONLY, ALIGN=4

        DCD     $FUNC_NAME                              ; function start RVA
        DCD     XDATA_$FUNC_NAME                        ; pointer in XDATA section

        END
