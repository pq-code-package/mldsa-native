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
; Name: rej_uniform_aarch64_asm
; Description: AArch64 rejection sampling of uniform coefficients mod q
; Signature: uint64_t mld_rej_uniform_aarch64_asm(int32_t r[256], const uint8_t *buf, uint64_t buflen, const uint8_t table[256])
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
;     description: Length of input buffer (must be a multiple of 24)
;     test_with: 840  # MLD_POLY_UNIFORM_NBLOCKS * SHAKE128_RATE = 5 * 168
;   x3:
;     type: buffer
;     size_bytes: 256
;     permissions: read-only
;     c_parameter: const uint8_t table[256]
;     description: Lookup table (256 x uint8_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_rej_uniform_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        sub     sp, sp, #0x440                          ; 0x00000000, line   35
        ; .cfi_adjust_cfa_offset 0x440
        mov     x7, #0x1                                ; 0x00000004, line   37
        movk    x7, #0x2, lsl #32                       ; 0x00000008, line   38
        mov     v31.d[0], x7                            ; 0x0000000C, line   39
        mov     x7, #0x4                                ; 0x00000010, line   40
        movk    x7, #0x8, lsl #32                       ; 0x00000014, line   41
        mov     v31.d[1], x7                            ; 0x00000018, line   42
        mov     w7, #0xe001                             ; 0x0000001C, line   43
        movk    w7, #0x7f, lsl #16                      ; 0x00000020, line   44
        dup     v30.4s, w7                              ; 0x00000024, line   45
        mov     x8, sp                                  ; 0x00000028, line   46
        mov     x7, x8                                  ; 0x0000002C, line   47
        mov     x11, #0x0                               ; 0x00000030, line   48
        eor     v16.16b, v16.16b, v16.16b               ; 0x00000034, line   49
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_initial_zero

        str     q16, [x7], #0x40                        ; 0x00000040, line   51
        stur    q16, [x7, #-0x30]                       ; 0x00000044, line   52
        stur    q16, [x7, #-0x20]                       ; 0x00000048, line   53
        stur    q16, [x7, #-0x10]                       ; 0x0000004C, line   54
        add     x11, x11, #0x10                         ; 0x00000050, line   55
        cmp     x11, #0x100                             ; 0x00000054, line   56
        b.lt    Lmld_rej_uniform_initial_zero           ; 0x00000058, line   57
        mov     x7, x8                                  ; 0x0000005C, line   58
        mov     x9, #0x0                                ; 0x00000060, line   59
        mov     x4, #0x100                              ; 0x00000064, line   60
        cmp     x2, #0x30                               ; 0x00000068, line   61
        b.lo    Lmld_rej_uniform_loop48_end             ; 0x0000006C, line   62

Lmld_rej_uniform_loop48

        cmp     x9, x4                                  ; 0x00000070, line   64
        b.hs    Lmld_rej_uniform_memory_copy            ; 0x00000074, line   65
        sub     x2, x2, #0x30                           ; 0x00000078, line   66
        ld3     { v0.16b, v1.16b, v2.16b }, [x1], #48   ; 0x0000007C, line   67
        movi    v4.16b, #0x80                           ; 0x00000080, line   68
        bic     v2.16b, v2.16b, v4.16b                  ; 0x00000084, line   69
        zip1    v4.16b, v0.16b, v1.16b                  ; 0x00000088, line   70
        zip2    v5.16b, v0.16b, v1.16b                  ; 0x0000008C, line   71
        ushll   v6.8h, v2.8b, #0x0                      ; 0x00000090, line   72
        ushll2  v7.8h, v2.16b, #0x0                     ; 0x00000094, line   73
        zip1    v16.8h, v4.8h, v6.8h                    ; 0x00000098, line   74
        zip2    v17.8h, v4.8h, v6.8h                    ; 0x0000009C, line   75
        zip1    v18.8h, v5.8h, v7.8h                    ; 0x000000A0, line   76
        zip2    v19.8h, v5.8h, v7.8h                    ; 0x000000A4, line   77
        cmhi    v4.4s, v30.4s, v16.4s                   ; 0x000000A8, line   78
        cmhi    v5.4s, v30.4s, v17.4s                   ; 0x000000AC, line   79
        cmhi    v6.4s, v30.4s, v18.4s                   ; 0x000000B0, line   80
        cmhi    v7.4s, v30.4s, v19.4s                   ; 0x000000B4, line   81
        and     v4.16b, v4.16b, v31.16b                 ; 0x000000B8, line   82
        and     v5.16b, v5.16b, v31.16b                 ; 0x000000BC, line   83
        and     v6.16b, v6.16b, v31.16b                 ; 0x000000C0, line   84
        and     v7.16b, v7.16b, v31.16b                 ; 0x000000C4, line   85
        uaddlv  d20, v4.4s                              ; 0x000000C8, line   86
        uaddlv  d21, v5.4s                              ; 0x000000CC, line   87
        uaddlv  d22, v6.4s                              ; 0x000000D0, line   88
        uaddlv  d23, v7.4s                              ; 0x000000D4, line   89
        fmov    x12, d20                                ; 0x000000D8, line   90
        fmov    x13, d21                                ; 0x000000DC, line   91
        fmov    x14, d22                                ; 0x000000E0, line   92
        fmov    x15, d23                                ; 0x000000E4, line   93
        ldr     q24, [x3, x12, lsl #4]                  ; 0x000000E8, line   94
        ldr     q25, [x3, x13, lsl #4]                  ; 0x000000EC, line   95
        ldr     q26, [x3, x14, lsl #4]                  ; 0x000000F0, line   96
        ldr     q27, [x3, x15, lsl #4]                  ; 0x000000F4, line   97
        cnt     v4.16b, v4.16b                          ; 0x000000F8, line   98
        cnt     v5.16b, v5.16b                          ; 0x000000FC, line   99
        cnt     v6.16b, v6.16b                          ; 0x00000100, line  100
        cnt     v7.16b, v7.16b                          ; 0x00000104, line  101
        uaddlv  d20, v4.4s                              ; 0x00000108, line  102
        uaddlv  d21, v5.4s                              ; 0x0000010C, line  103
        uaddlv  d22, v6.4s                              ; 0x00000110, line  104
        uaddlv  d23, v7.4s                              ; 0x00000114, line  105
        fmov    x12, d20                                ; 0x00000118, line  106
        fmov    x13, d21                                ; 0x0000011C, line  107
        fmov    x14, d22                                ; 0x00000120, line  108
        fmov    x15, d23                                ; 0x00000124, line  109
        tbl     v16.16b, { v16.16b }, v24.16b           ; 0x00000128, line  110
        tbl     v17.16b, { v17.16b }, v25.16b           ; 0x0000012C, line  111
        tbl     v18.16b, { v18.16b }, v26.16b           ; 0x00000130, line  112
        tbl     v19.16b, { v19.16b }, v27.16b           ; 0x00000134, line  113
        st1     { v16.4s }, [x7]                        ; 0x00000138, line  114
        add     x7, x7, x12, lsl #2                     ; 0x0000013C, line  115
        st1     { v17.4s }, [x7]                        ; 0x00000140, line  116
        add     x7, x7, x13, lsl #2                     ; 0x00000144, line  117
        st1     { v18.4s }, [x7]                        ; 0x00000148, line  118
        add     x7, x7, x14, lsl #2                     ; 0x0000014C, line  119
        st1     { v19.4s }, [x7]                        ; 0x00000150, line  120
        add     x7, x7, x15, lsl #2                     ; 0x00000154, line  121
        add     x12, x12, x13                           ; 0x00000158, line  122
        add     x14, x14, x15                           ; 0x0000015C, line  123
        add     x9, x9, x12                             ; 0x00000160, line  124
        add     x9, x9, x14                             ; 0x00000164, line  125
        cmp     x2, #0x30                               ; 0x00000168, line  126
        b.hs    Lmld_rej_uniform_loop48                 ; 0x0000016C, line  127

Lmld_rej_uniform_loop48_end

        cmp     x9, x4                                  ; 0x00000170, line  129
        b.hs    Lmld_rej_uniform_memory_copy            ; 0x00000174, line  130
        cmp     x2, #0x18                               ; 0x00000178, line  131
        b.lo    Lmld_rej_uniform_memory_copy            ; 0x0000017C, line  132
        sub     x2, x2, #0x18                           ; 0x00000180, line  133
        ld3     { v0.8b, v1.8b, v2.8b }, [x1], #24      ; 0x00000184, line  134
        movi    v4.16b, #0x80                           ; 0x00000188, line  135
        bic     v2.16b, v2.16b, v4.16b                  ; 0x0000018C, line  136
        zip1    v4.16b, v0.16b, v1.16b                  ; 0x00000190, line  137
        ushll   v6.8h, v2.8b, #0x0                      ; 0x00000194, line  138
        zip1    v16.8h, v4.8h, v6.8h                    ; 0x00000198, line  139
        zip2    v17.8h, v4.8h, v6.8h                    ; 0x0000019C, line  140
        cmhi    v4.4s, v30.4s, v16.4s                   ; 0x000001A0, line  141
        cmhi    v5.4s, v30.4s, v17.4s                   ; 0x000001A4, line  142
        and     v4.16b, v4.16b, v31.16b                 ; 0x000001A8, line  143
        and     v5.16b, v5.16b, v31.16b                 ; 0x000001AC, line  144
        uaddlv  d20, v4.4s                              ; 0x000001B0, line  145
        uaddlv  d21, v5.4s                              ; 0x000001B4, line  146
        fmov    x12, d20                                ; 0x000001B8, line  147
        fmov    x13, d21                                ; 0x000001BC, line  148
        ldr     q24, [x3, x12, lsl #4]                  ; 0x000001C0, line  149
        ldr     q25, [x3, x13, lsl #4]                  ; 0x000001C4, line  150
        cnt     v4.16b, v4.16b                          ; 0x000001C8, line  151
        cnt     v5.16b, v5.16b                          ; 0x000001CC, line  152
        uaddlv  d20, v4.4s                              ; 0x000001D0, line  153
        uaddlv  d21, v5.4s                              ; 0x000001D4, line  154
        fmov    x12, d20                                ; 0x000001D8, line  155
        fmov    x13, d21                                ; 0x000001DC, line  156
        tbl     v16.16b, { v16.16b }, v24.16b           ; 0x000001E0, line  157
        tbl     v17.16b, { v17.16b }, v25.16b           ; 0x000001E4, line  158
        st1     { v16.4s }, [x7]                        ; 0x000001E8, line  159
        add     x7, x7, x12, lsl #2                     ; 0x000001EC, line  160
        st1     { v17.4s }, [x7]                        ; 0x000001F0, line  161
        add     x7, x7, x13, lsl #2                     ; 0x000001F4, line  162
        add     x9, x9, x12                             ; 0x000001F8, line  163
        add     x9, x9, x13                             ; 0x000001FC, line  164

Lmld_rej_uniform_memory_copy

        cmp     x9, x4                                  ; 0x00000200, line  166
        csel    x9, x9, x4, lo                          ; 0x00000204, line  167
        mov     x11, #0x0                               ; 0x00000208, line  168
        mov     x7, x8                                  ; 0x0000020C, line  169

Lmld_rej_uniform_final_copy

        ldr     q16, [x7], #0x40                        ; 0x00000210, line  171
        ldur    q17, [x7, #-0x30]                       ; 0x00000214, line  172
        ldur    q18, [x7, #-0x20]                       ; 0x00000218, line  173
        ldur    q19, [x7, #-0x10]                       ; 0x0000021C, line  174
        str     q16, [x0], #0x40                        ; 0x00000220, line  175
        stur    q17, [x0, #-0x30]                       ; 0x00000224, line  176
        stur    q18, [x0, #-0x20]                       ; 0x00000228, line  177
        stur    q19, [x0, #-0x10]                       ; 0x0000022C, line  178
        add     x11, x11, #0x10                         ; 0x00000230, line  179
        cmp     x11, #0x100                             ; 0x00000234, line  180
        b.lt    Lmld_rej_uniform_final_copy             ; 0x00000238, line  181
        mov     x0, x9                                  ; 0x0000023C, line  182
        b       Lmld_rej_uniform_return                 ; 0x00000240, line  183
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_return

        add     sp, sp, #0x440                          ; 0x00000250, line  185
        ; .cfi_adjust_cfa_offset -0x440
        ret                                             ; 0x00000254, line  187
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000258 byte(s)

        AREA    |.xdata|, DATA, READONLY, ALIGN=4

XDATA_$FUNC_NAME

        DCD     0x08200096                              ; header dword
        DCB     0xC0, 0x44                              ; unwind code 'alloc_m', stack space 0x0440
        DCB     0xE4                                    ; unwind code 'end'
        DCB     0x00                                    ; unwind code padding

        AREA    |.pdata|, DATA, READONLY, ALIGN=4

        DCD     $FUNC_NAME                              ; function start RVA
        DCD     XDATA_$FUNC_NAME                        ; pointer in XDATA section

        END
