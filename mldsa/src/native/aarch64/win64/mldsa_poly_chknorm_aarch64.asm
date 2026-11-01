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
; Name: poly_chknorm_aarch64_asm
; Description: AArch64 infinity-norm bound check on polynomial coefficients
; Signature: int mld_poly_chknorm_aarch64_asm(const int32_t a[256], int64_t B)
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: read-only
;     c_parameter: const int32_t a[256]
;     description: Input polynomial (256 x int32_t)
;   x1:
;     type: scalar
;     c_parameter: int64_t B
;     description: Norm bound
;     test_with: 131072  # representative non-negative bound (1 << 17)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_poly_chknorm_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        dup     v20.4s, w1                              ; 0x00000000, line   23
        eor     v21.16b, v21.16b, v21.16b               ; 0x00000004, line   24
        mov     x2, #0x10                               ; 0x00000008, line   25
        HINT    #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

Lmld_poly_chknorm_loop

        ldr     q1, [x0, #0x10]                         ; 0x00000010, line   27
        ldr     q2, [x0, #0x20]                         ; 0x00000014, line   28
        ldr     q3, [x0, #0x30]                         ; 0x00000018, line   29
        ldr     q0, [x0], #0x40                         ; 0x0000001C, line   30
        abs     v1.4s, v1.4s                            ; 0x00000020, line   31
        cmge    v1.4s, v1.4s, v20.4s                    ; 0x00000024, line   32
        orr     v21.16b, v21.16b, v1.16b                ; 0x00000028, line   33
        abs     v2.4s, v2.4s                            ; 0x0000002C, line   34
        cmge    v2.4s, v2.4s, v20.4s                    ; 0x00000030, line   35
        orr     v21.16b, v21.16b, v2.16b                ; 0x00000034, line   36
        abs     v3.4s, v3.4s                            ; 0x00000038, line   37
        cmge    v3.4s, v3.4s, v20.4s                    ; 0x0000003C, line   38
        orr     v21.16b, v21.16b, v3.16b                ; 0x00000040, line   39
        abs     v0.4s, v0.4s                            ; 0x00000044, line   40
        cmge    v0.4s, v0.4s, v20.4s                    ; 0x00000048, line   41
        orr     v21.16b, v21.16b, v0.16b                ; 0x0000004C, line   42
        subs    x2, x2, #0x1                            ; 0x00000050, line   43
        b.ne    Lmld_poly_chknorm_loop                  ; 0x00000054, line   44
        umaxv   s21, v21.4s                             ; 0x00000058, line   45
        fmov    w0, s21                                 ; 0x0000005C, line   46
        and     w0, w0, #0x1                            ; 0x00000060, line   47
        ret                                             ; 0x00000064, line   48
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000068 byte(s)

        END
