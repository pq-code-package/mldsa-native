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
; Name: rej_uniform_eta2_aarch64_asm
; Description: AArch64 rejection sampling of eta=2 secret coefficients
; Signature: uint64_t mld_rej_uniform_eta2_aarch64_asm(int32_t r[256], const uint8_t *buf, uint64_t buflen, const uint8_t table[4096])
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
;     test_with: 136  # MLD_AARCH64_REJ_UNIFORM_ETA2_BUFLEN
;   x3:
;     type: buffer
;     size_bytes: 4096
;     permissions: read-only
;     c_parameter: const uint8_t table[4096]
;     description: Lookup table (4096 x uint8_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_rej_uniform_eta2_aarch64_asm"
        ENDIF

        AREA     |.drectve|, DRECTVE

        EXPORT   $FUNC_NAME

        AREA     |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN    16

$FUNC_NAME PROC

        ; .cfi_startproc
        sub      sp, sp, #0x240                          ; 0x00000000, line   35
        ; .cfi_adjust_cfa_offset 0x240
        mov      x7, #0x1                                ; 0x00000004, line   37
        movk     x7, #0x2, lsl #16                       ; 0x00000008, line   38
        movk     x7, #0x4, lsl #32                       ; 0x0000000C, line   39
        movk     x7, #0x8, lsl #48                       ; 0x00000010, line   40
        mov      v31.d[0], x7                            ; 0x00000014, line   41
        mov      x7, #0x10                               ; 0x00000018, line   42
        movk     x7, #0x20, lsl #16                      ; 0x0000001C, line   43
        movk     x7, #0x40, lsl #32                      ; 0x00000020, line   44
        movk     x7, #0x80, lsl #48                      ; 0x00000024, line   45
        mov      v31.d[1], x7                            ; 0x00000028, line   46
        movi     v30.8h, #0xf                            ; 0x0000002C, line   47
        mov      x8, sp                                  ; 0x00000030, line   48
        mov      x7, x8                                  ; 0x00000034, line   49
        mov      x11, #0x0                               ; 0x00000038, line   50
        eor      v16.16b, v16.16b, v16.16b               ; 0x0000003C, line   51

Lmld_rej_uniform_eta2_initial_zero

        str      q16, [x7], #0x40                        ; 0x00000040, line   54
        stur     q16, [x7, #-0x30]                       ; 0x00000044, line   55
        stur     q16, [x7, #-0x20]                       ; 0x00000048, line   56
        stur     q16, [x7, #-0x10]                       ; 0x0000004C, line   57
        add      x11, x11, #0x20                         ; 0x00000050, line   58
        cmp      x11, #0x100                             ; 0x00000054, line   59
        b.lt     Lmld_rej_uniform_eta2_initial_zero      ; 0x00000058, line   60
        mov      x7, x8                                  ; 0x0000005C, line   61
        mov      x9, #0x0                                ; 0x00000060, line   62
        mov      x4, #0x100                              ; 0x00000064, line   63
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_eta2_loop8

        cmp      x9, x4                                  ; 0x00000070, line   66
        b.hs     Lmld_rej_uniform_eta2_memory_copy       ; 0x00000074, line   67
        sub      x2, x2, #0x8                            ; 0x00000078, line   68
        ld1      { v0.8b }, [x1], #8                     ; 0x0000007C, line   69
        movi     v26.8b, #0xf                            ; 0x00000080, line   70
        and      v27.8b, v0.8b, v26.8b                   ; 0x00000084, line   71
        ushr     v28.8b, v0.8b, #0x4                     ; 0x00000088, line   72
        zip1     v26.8b, v27.8b, v28.8b                  ; 0x0000008C, line   73
        zip2     v29.8b, v27.8b, v28.8b                  ; 0x00000090, line   74
        ushll    v16.8h, v26.8b, #0x0                    ; 0x00000094, line   75
        ushll    v17.8h, v29.8b, #0x0                    ; 0x00000098, line   76
        cmhi     v4.8h, v30.8h, v16.8h                   ; 0x0000009C, line   77
        cmhi     v5.8h, v30.8h, v17.8h                   ; 0x000000A0, line   78
        and      v4.16b, v4.16b, v31.16b                 ; 0x000000A4, line   79
        and      v5.16b, v5.16b, v31.16b                 ; 0x000000A8, line   80
        uaddlv   s20, v4.8h                              ; 0x000000AC, line   81
        uaddlv   s21, v5.8h                              ; 0x000000B0, line   82
        fmov     w12, s20                                ; 0x000000B4, line   83
        fmov     w13, s21                                ; 0x000000B8, line   84
        ldr      q24, [x3, x12, lsl #4]                  ; 0x000000BC, line   85
        ldr      q25, [x3, x13, lsl #4]                  ; 0x000000C0, line   86
        cnt      v4.16b, v4.16b                          ; 0x000000C4, line   87
        cnt      v5.16b, v5.16b                          ; 0x000000C8, line   88
        uaddlv   s20, v4.8h                              ; 0x000000CC, line   89
        uaddlv   s21, v5.8h                              ; 0x000000D0, line   90
        fmov     w12, s20                                ; 0x000000D4, line   91
        fmov     w13, s21                                ; 0x000000D8, line   92
        tbl      v16.16b, { v16.16b }, v24.16b           ; 0x000000DC, line   93
        tbl      v17.16b, { v17.16b }, v25.16b           ; 0x000000E0, line   94
        st1      { v16.8h }, [x7]                        ; 0x000000E4, line   95
        add      x7, x7, x12, lsl #1                     ; 0x000000E8, line   96
        st1      { v17.8h }, [x7]                        ; 0x000000EC, line   97
        add      x7, x7, x13, lsl #1                     ; 0x000000F0, line   98
        add      x12, x12, x13                           ; 0x000000F4, line   99
        add      x9, x9, x12                             ; 0x000000F8, line  100
        cmp      x2, #0x8                                ; 0x000000FC, line  101
        b.hs     Lmld_rej_uniform_eta2_loop8             ; 0x00000100, line  102
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT     #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_rej_uniform_eta2_memory_copy

        cmp      x9, x4                                  ; 0x00000110, line  105
        csel     x9, x9, x4, lo                          ; 0x00000114, line  106
        mov      w7, #0x199a                             ; 0x00000118, line  107
        dup      v26.8h, w7                              ; 0x0000011C, line  108
        movi     v27.8h, #0x5                            ; 0x00000120, line  109
        movi     v7.8h, #0x2                             ; 0x00000124, line  110
        mov      x11, #0x0                               ; 0x00000128, line  111
        mov      x7, x8                                  ; 0x0000012C, line  112

Lmld_rej_uniform_eta2_final_copy

        ldr      q16, [x7], #0x20                        ; 0x00000130, line  115
        ldur     q18, [x7, #-0x10]                       ; 0x00000134, line  116
        sqdmulh  v28.8h, v16.8h, v26.8h                  ; 0x00000138, line  117
        mls      v16.8h, v28.8h, v27.8h                  ; 0x0000013C, line  118
        sqdmulh  v28.8h, v18.8h, v26.8h                  ; 0x00000140, line  119
        mls      v18.8h, v28.8h, v27.8h                  ; 0x00000144, line  120
        sub      v16.8h, v7.8h, v16.8h                   ; 0x00000148, line  121
        sub      v18.8h, v7.8h, v18.8h                   ; 0x0000014C, line  122
        sshll2   v17.4s, v16.8h, #0x0                    ; 0x00000150, line  123
        sshll    v16.4s, v16.4h, #0x0                    ; 0x00000154, line  124
        sshll2   v19.4s, v18.8h, #0x0                    ; 0x00000158, line  125
        sshll    v18.4s, v18.4h, #0x0                    ; 0x0000015C, line  126
        str      q16, [x0], #0x40                        ; 0x00000160, line  127
        stur     q17, [x0, #-0x30]                       ; 0x00000164, line  128
        stur     q18, [x0, #-0x20]                       ; 0x00000168, line  129
        stur     q19, [x0, #-0x10]                       ; 0x0000016C, line  130
        add      x11, x11, #0x10                         ; 0x00000170, line  131
        cmp      x11, #0x100                             ; 0x00000174, line  132
        b.lt     Lmld_rej_uniform_eta2_final_copy        ; 0x00000178, line  133
        mov      x0, x9                                  ; 0x0000017C, line  134
        add      sp, sp, #0x240                          ; 0x00000180, line  135
        ; .cfi_adjust_cfa_offset -0x240
        ret                                              ; 0x00000184, line  137
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000188 byte(s)

        AREA     |.xdata|, DATA, READONLY, ALIGN=4

XDATA_$FUNC_NAME

        DCD      0x08200062                              ; header dword
        DCB      0xC0, 0x24                              ; unwind code 'alloc_m', stack space 0x0240
        DCB      0xE4                                    ; unwind code 'end'
        DCB      0x00                                    ; unwind code padding

        AREA     |.pdata|, DATA, READONLY, ALIGN=4

        DCD      $FUNC_NAME                              ; function start RVA
        DCD      XDATA_$FUNC_NAME                        ; pointer in XDATA section

        END
