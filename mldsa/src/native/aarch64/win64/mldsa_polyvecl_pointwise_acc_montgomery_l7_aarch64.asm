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
; Name: polyvecl_pointwise_acc_montgomery_l7_aarch64_asm
; Description: AArch64 pointwise multiply-accumulate of length-7 polynomial vectors
; Signature: void mld_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm(int32_t r[256], const int32_t a[7][256], const int32_t b[7][256])
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t r[256]
;     description: Output polynomial (256 x int32_t)
;   x1:
;     type: buffer
;     size_bytes: 7168
;     permissions: read-only
;     c_parameter: const int32_t a[7][256]
;     description: Input polynomial vector a (7 x 256 x int32_t)
;   x2:
;     type: buffer
;     size_bytes: 7168
;     permissions: read-only
;     c_parameter: const int32_t b[7][256]
;     description: Input polynomial vector b (7 x 256 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        mov     w3, #0xe001                                              ; 0x00000000, line   30
        movk    w3, #0x7f, lsl #16                                       ; 0x00000004, line   31
        dup     v0.4s, w3                                                ; 0x00000008, line   32
        mov     w3, #0x2001                                              ; 0x0000000C, line   33
        movk    w3, #0x380, lsl #16                                      ; 0x00000010, line   34
        dup     v1.4s, w3                                                ; 0x00000014, line   35
        mov     x3, #0x40                                                ; 0x00000018, line   36
        HINT    #0x0                                                     ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_polyvecl_pointwise_acc_montgomery_l7_loop_start

        ldr     q17, [x1, #0x10]                                         ; 0x00000020, line   38
        ldr     q18, [x1, #0x20]                                         ; 0x00000024, line   39
        ldr     q19, [x1, #0x30]                                         ; 0x00000028, line   40
        ldr     q16, [x1], #0x40                                         ; 0x0000002C, line   41
        ldr     q21, [x2, #0x10]                                         ; 0x00000030, line   42
        ldr     q22, [x2, #0x20]                                         ; 0x00000034, line   43
        ldr     q23, [x2, #0x30]                                         ; 0x00000038, line   44
        ldr     q20, [x2], #0x40                                         ; 0x0000003C, line   45
        smull   v24.2d, v16.2s, v20.2s                                   ; 0x00000040, line   46
        smull2  v25.2d, v16.4s, v20.4s                                   ; 0x00000044, line   47
        smull   v26.2d, v17.2s, v21.2s                                   ; 0x00000048, line   48
        smull2  v27.2d, v17.4s, v21.4s                                   ; 0x0000004C, line   49
        smull   v28.2d, v18.2s, v22.2s                                   ; 0x00000050, line   50
        smull2  v29.2d, v18.4s, v22.4s                                   ; 0x00000054, line   51
        smull   v30.2d, v19.2s, v23.2s                                   ; 0x00000058, line   52
        smull2  v31.2d, v19.4s, v23.4s                                   ; 0x0000005C, line   53
        ldr     q16, [x1, #0x3c0]                                        ; 0x00000060, line   54
        ldr     q17, [x1, #0x3d0]                                        ; 0x00000064, line   55
        ldr     q18, [x1, #0x3e0]                                        ; 0x00000068, line   56
        ldr     q19, [x1, #0x3f0]                                        ; 0x0000006C, line   57
        ldr     q20, [x2, #0x3c0]                                        ; 0x00000070, line   58
        ldr     q21, [x2, #0x3d0]                                        ; 0x00000074, line   59
        ldr     q22, [x2, #0x3e0]                                        ; 0x00000078, line   60
        ldr     q23, [x2, #0x3f0]                                        ; 0x0000007C, line   61
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x00000080, line   62
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x00000084, line   63
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x00000088, line   64
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x0000008C, line   65
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x00000090, line   66
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x00000094, line   67
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x00000098, line   68
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x0000009C, line   69
        ldr     q16, [x1, #0x7c0]                                        ; 0x000000A0, line   70
        ldr     q17, [x1, #0x7d0]                                        ; 0x000000A4, line   71
        ldr     q18, [x1, #0x7e0]                                        ; 0x000000A8, line   72
        ldr     q19, [x1, #0x7f0]                                        ; 0x000000AC, line   73
        ldr     q20, [x2, #0x7c0]                                        ; 0x000000B0, line   74
        ldr     q21, [x2, #0x7d0]                                        ; 0x000000B4, line   75
        ldr     q22, [x2, #0x7e0]                                        ; 0x000000B8, line   76
        ldr     q23, [x2, #0x7f0]                                        ; 0x000000BC, line   77
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x000000C0, line   78
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x000000C4, line   79
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x000000C8, line   80
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x000000CC, line   81
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x000000D0, line   82
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x000000D4, line   83
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x000000D8, line   84
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x000000DC, line   85
        ldr     q16, [x1, #0xbc0]                                        ; 0x000000E0, line   86
        ldr     q17, [x1, #0xbd0]                                        ; 0x000000E4, line   87
        ldr     q18, [x1, #0xbe0]                                        ; 0x000000E8, line   88
        ldr     q19, [x1, #0xbf0]                                        ; 0x000000EC, line   89
        ldr     q20, [x2, #0xbc0]                                        ; 0x000000F0, line   90
        ldr     q21, [x2, #0xbd0]                                        ; 0x000000F4, line   91
        ldr     q22, [x2, #0xbe0]                                        ; 0x000000F8, line   92
        ldr     q23, [x2, #0xbf0]                                        ; 0x000000FC, line   93
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x00000100, line   94
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x00000104, line   95
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x00000108, line   96
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x0000010C, line   97
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x00000110, line   98
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x00000114, line   99
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x00000118, line  100
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x0000011C, line  101
        ldr     q16, [x1, #0xfc0]                                        ; 0x00000120, line  102
        ldr     q17, [x1, #0xfd0]                                        ; 0x00000124, line  103
        ldr     q18, [x1, #0xfe0]                                        ; 0x00000128, line  104
        ldr     q19, [x1, #0xff0]                                        ; 0x0000012C, line  105
        ldr     q20, [x2, #0xfc0]                                        ; 0x00000130, line  106
        ldr     q21, [x2, #0xfd0]                                        ; 0x00000134, line  107
        ldr     q22, [x2, #0xfe0]                                        ; 0x00000138, line  108
        ldr     q23, [x2, #0xff0]                                        ; 0x0000013C, line  109
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x00000140, line  110
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x00000144, line  111
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x00000148, line  112
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x0000014C, line  113
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x00000150, line  114
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x00000154, line  115
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x00000158, line  116
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x0000015C, line  117
        ldr     q16, [x1, #0x13c0]                                       ; 0x00000160, line  118
        ldr     q17, [x1, #0x13d0]                                       ; 0x00000164, line  119
        ldr     q18, [x1, #0x13e0]                                       ; 0x00000168, line  120
        ldr     q19, [x1, #0x13f0]                                       ; 0x0000016C, line  121
        ldr     q20, [x2, #0x13c0]                                       ; 0x00000170, line  122
        ldr     q21, [x2, #0x13d0]                                       ; 0x00000174, line  123
        ldr     q22, [x2, #0x13e0]                                       ; 0x00000178, line  124
        ldr     q23, [x2, #0x13f0]                                       ; 0x0000017C, line  125
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x00000180, line  126
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x00000184, line  127
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x00000188, line  128
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x0000018C, line  129
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x00000190, line  130
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x00000194, line  131
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x00000198, line  132
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x0000019C, line  133
        ldr     q16, [x1, #0x17c0]                                       ; 0x000001A0, line  134
        ldr     q17, [x1, #0x17d0]                                       ; 0x000001A4, line  135
        ldr     q18, [x1, #0x17e0]                                       ; 0x000001A8, line  136
        ldr     q19, [x1, #0x17f0]                                       ; 0x000001AC, line  137
        ldr     q20, [x2, #0x17c0]                                       ; 0x000001B0, line  138
        ldr     q21, [x2, #0x17d0]                                       ; 0x000001B4, line  139
        ldr     q22, [x2, #0x17e0]                                       ; 0x000001B8, line  140
        ldr     q23, [x2, #0x17f0]                                       ; 0x000001BC, line  141
        smlal   v24.2d, v16.2s, v20.2s                                   ; 0x000001C0, line  142
        smlal2  v25.2d, v16.4s, v20.4s                                   ; 0x000001C4, line  143
        smlal   v26.2d, v17.2s, v21.2s                                   ; 0x000001C8, line  144
        smlal2  v27.2d, v17.4s, v21.4s                                   ; 0x000001CC, line  145
        smlal   v28.2d, v18.2s, v22.2s                                   ; 0x000001D0, line  146
        smlal2  v29.2d, v18.4s, v22.4s                                   ; 0x000001D4, line  147
        smlal   v30.2d, v19.2s, v23.2s                                   ; 0x000001D8, line  148
        smlal2  v31.2d, v19.4s, v23.4s                                   ; 0x000001DC, line  149
        uzp1    v16.4s, v24.4s, v25.4s                                   ; 0x000001E0, line  150
        mul     v16.4s, v16.4s, v1.4s                                    ; 0x000001E4, line  151
        smlsl   v24.2d, v16.2s, v0.2s                                    ; 0x000001E8, line  152
        smlsl2  v25.2d, v16.4s, v0.4s                                    ; 0x000001EC, line  153
        uzp2    v16.4s, v24.4s, v25.4s                                   ; 0x000001F0, line  154
        uzp1    v17.4s, v26.4s, v27.4s                                   ; 0x000001F4, line  155
        mul     v17.4s, v17.4s, v1.4s                                    ; 0x000001F8, line  156
        smlsl   v26.2d, v17.2s, v0.2s                                    ; 0x000001FC, line  157
        smlsl2  v27.2d, v17.4s, v0.4s                                    ; 0x00000200, line  158
        uzp2    v17.4s, v26.4s, v27.4s                                   ; 0x00000204, line  159
        uzp1    v18.4s, v28.4s, v29.4s                                   ; 0x00000208, line  160
        mul     v18.4s, v18.4s, v1.4s                                    ; 0x0000020C, line  161
        smlsl   v28.2d, v18.2s, v0.2s                                    ; 0x00000210, line  162
        smlsl2  v29.2d, v18.4s, v0.4s                                    ; 0x00000214, line  163
        uzp2    v18.4s, v28.4s, v29.4s                                   ; 0x00000218, line  164
        uzp1    v19.4s, v30.4s, v31.4s                                   ; 0x0000021C, line  165
        mul     v19.4s, v19.4s, v1.4s                                    ; 0x00000220, line  166
        smlsl   v30.2d, v19.2s, v0.2s                                    ; 0x00000224, line  167
        smlsl2  v31.2d, v19.4s, v0.4s                                    ; 0x00000228, line  168
        uzp2    v19.4s, v30.4s, v31.4s                                   ; 0x0000022C, line  169
        str     q17, [x0, #0x10]                                         ; 0x00000230, line  170
        str     q18, [x0, #0x20]                                         ; 0x00000234, line  171
        str     q19, [x0, #0x30]                                         ; 0x00000238, line  172
        str     q16, [x0], #0x40                                         ; 0x0000023C, line  173
        subs    x3, x3, #0x4                                             ; 0x00000240, line  174
        cbnz    x3, Lmld_polyvecl_pointwise_acc_montgomery_l7_loop_start ; 0x00000244, line  175
        ret                                                              ; 0x00000248, line  176
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x0000024C byte(s)

        END
