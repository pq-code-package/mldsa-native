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
; Name: polyz_unpack_19_aarch64_asm
; Description: AArch64 unpacking of 19-bit packed coefficients
; Signature: void mld_polyz_unpack_19_aarch64_asm(int32_t r[256], const uint8_t buf[640], const uint8_t indices[64])
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
;     size_bytes: 640
;     permissions: read-only
;     c_parameter: const uint8_t buf[640]
;     description: Packed input bytes
;   x2:
;     type: buffer
;     size_bytes: 64
;     permissions: read-only
;     c_parameter: const uint8_t indices[64]
;     description: Permutation index table (64 x uint8_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_polyz_unpack_19_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        ldr     q24, [x2]                               ; 0x00000000, line   30
        ldr     q25, [x2, #0x10]                        ; 0x00000004, line   31
        ldr     q26, [x2, #0x20]                        ; 0x00000008, line   32
        ldr     q27, [x2, #0x30]                        ; 0x0000000C, line   33
        mov     x3, #0xfc00000000                       ; 0x00000010, line   34
        dup     v28.2d, x3                              ; 0x00000014, line   35
        movi    v29.4s, #0xf, msl #16                   ; 0x00000018, line   36
        movi    v30.4s, #0x8, lsl #16                   ; 0x0000001C, line   37
        mov     x9, #0x10                               ; 0x00000020, line   38
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_polyz_unpack_19_loop

        ld1     { v0.16b, v1.16b }, [x1]                ; 0x00000030, line   40
        add     x1, x1, #0x18                           ; 0x00000034, line   41
        ld1     { v2.16b }, [x1], #16                   ; 0x00000038, line   42
        tbl     v4.16b, { v0.16b }, v24.16b             ; 0x0000003C, line   43
        tbl     v5.16b, { v0.16b, v1.16b }, v25.16b     ; 0x00000040, line   44
        tbl     v6.16b, { v1.16b }, v26.16b             ; 0x00000044, line   45
        tbl     v7.16b, { v1.16b, v2.16b }, v27.16b     ; 0x00000048, line   46
        ushl    v4.4s, v4.4s, v28.4s                    ; 0x0000004C, line   47
        and     v4.16b, v4.16b, v29.16b                 ; 0x00000050, line   48
        sub     v4.4s, v30.4s, v4.4s                    ; 0x00000054, line   49
        ushl    v5.4s, v5.4s, v28.4s                    ; 0x00000058, line   50
        and     v5.16b, v5.16b, v29.16b                 ; 0x0000005C, line   51
        sub     v5.4s, v30.4s, v5.4s                    ; 0x00000060, line   52
        ushl    v6.4s, v6.4s, v28.4s                    ; 0x00000064, line   53
        and     v6.16b, v6.16b, v29.16b                 ; 0x00000068, line   54
        sub     v6.4s, v30.4s, v6.4s                    ; 0x0000006C, line   55
        ushl    v7.4s, v7.4s, v28.4s                    ; 0x00000070, line   56
        and     v7.16b, v7.16b, v29.16b                 ; 0x00000074, line   57
        sub     v7.4s, v30.4s, v7.4s                    ; 0x00000078, line   58
        str     q5, [x0, #0x10]                         ; 0x0000007C, line   59
        str     q6, [x0, #0x20]                         ; 0x00000080, line   60
        str     q7, [x0, #0x30]                         ; 0x00000084, line   61
        str     q4, [x0], #0x40                         ; 0x00000088, line   62
        subs    x9, x9, #0x1                            ; 0x0000008C, line   63
        b.ne    Lmld_polyz_unpack_19_loop               ; 0x00000090, line   64
        ret                                             ; 0x00000094, line   65
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000098 byte(s)

        END
