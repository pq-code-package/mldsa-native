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
; Name: poly_caddq_aarch64_asm
; Description: AArch64 conditional addition of q to each coefficient
; Signature: void mld_poly_caddq_aarch64_asm(int32_t a[256])
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
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_poly_caddq_aarch64_asm"
        ENDIF

        AREA    |.drectve|, DRECTVE

        EXPORT  $FUNC_NAME

        AREA    |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN   16

$FUNC_NAME PROC

        ; .cfi_startproc
        mov     w9, #0xe001                             ; 0x00000000, line   18
        movk    w9, #0x7f, lsl #16                      ; 0x00000004, line   19
        dup     v4.4s, w9                               ; 0x00000008, line   20
        mov     x1, #0x10                               ; 0x0000000C, line   21

Lmld_poly_caddq_loop

        ldr     q0, [x0]                                ; 0x00000010, line   23
        ldr     q1, [x0, #0x10]                         ; 0x00000014, line   24
        ldr     q2, [x0, #0x20]                         ; 0x00000018, line   25
        ldr     q3, [x0, #0x30]                         ; 0x0000001C, line   26
        ushr    v5.4s, v0.4s, #0x1f                     ; 0x00000020, line   27
        mla     v0.4s, v5.4s, v4.4s                     ; 0x00000024, line   28
        ushr    v5.4s, v1.4s, #0x1f                     ; 0x00000028, line   29
        mla     v1.4s, v5.4s, v4.4s                     ; 0x0000002C, line   30
        ushr    v5.4s, v2.4s, #0x1f                     ; 0x00000030, line   31
        mla     v2.4s, v5.4s, v4.4s                     ; 0x00000034, line   32
        ushr    v5.4s, v3.4s, #0x1f                     ; 0x00000038, line   33
        mla     v3.4s, v5.4s, v4.4s                     ; 0x0000003C, line   34
        str     q1, [x0, #0x10]                         ; 0x00000040, line   35
        str     q2, [x0, #0x20]                         ; 0x00000044, line   36
        str     q3, [x0, #0x30]                         ; 0x00000048, line   37
        str     q0, [x0], #0x40                         ; 0x0000004C, line   38
        subs    x1, x1, #0x1                            ; 0x00000050, line   39
        b.ne    Lmld_poly_caddq_loop                    ; 0x00000054, line   40
        ret                                             ; 0x00000058, line   41
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x0000005C byte(s)

        END
