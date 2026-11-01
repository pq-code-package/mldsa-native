;
; Copyright(c) The mlkem - native project authors
; Copyright(c) The mldsa - native project authors
; SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
;
;  References
;  ==========
;
;  - [REF_AVX2]
;    CRYSTALS-Dilithium optimized AVX2 implementation
;    Bai, Ducas, Kiltz, Lepoint, Lyubashevsky, Schwabe, Seiler, Stehlé
;    https://github.com/pq-crystals/dilithium/tree/master/avx2
;
; This file is derived from the public domain
; AVX2 Dilithium implementation @[REF_AVX2].
;
; MASM (Microsoft Assembler) version for MS Windows
; provided by Ingo A. Kubbilun <ingo.kubbilun@gmail.com>
; Oct. 2026
;
; This honors the Microsoft AMD64 ABI instead of
; Sys V AMD64 ABI (e.g. Linux/GNU Compiler Collection)
;
; pseudo assembly instructions (prologue, FRAME/UNWIND)
; added with help from Github Copilot, assembly checking
; performed by Github Copilot, too.
;

                               .CODE

                                ALIGN 16

; yaml
; Name: poly_use_hint_88_avx2_asm
; Description: x86_64 AVX2 hint application (alpha = (Q-1)/88).
;   Use the hint polynomial h to correct the high bits of the polynomial a,
;   in place. Variant for parameter set ML-DSA-44 (GAMMA2 = (Q-1)/88).
; Signature: void mld_poly_use_hint_88_avx2_asm(int32_t *a, const int32_t *h)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t *a
;     description: Input/output polynomial (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 1024
;     permissions: read-only
;     c_parameter: const int32_t *h
;     description: Hint polynomial (256 x int32_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_poly_use_hint_88_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         sub           rsp,078h                             ; 078h and not 070h for alignment purposes
         .allocstack   078h

         vmovdqa       xmmword ptr [rsp+000h],xmm6          ; save xmm6 on stack
         .savexmm128   xmm6,000h
         vmovdqa       xmmword ptr [rsp+010h],xmm7          ; save xmm7 on stack
         .savexmm128   xmm7,010h
         vmovdqa       xmmword ptr [rsp+020h],xmm8          ; save xmm8 on stack
         .savexmm128   xmm8,020h
         vmovdqa       xmmword ptr [rsp+030h],xmm9          ; save xmm9 on stack
         .savexmm128   xmm9,030h
         vmovdqa       xmmword ptr [rsp+040h],xmm10         ; save xmm10 on stack
         .savexmm128   xmm10,040h
         vmovdqa       xmmword ptr [rsp+050h],xmm11         ; save xmm11 on stack
         .savexmm128   xmm11,050h
         vmovdqa       xmmword ptr [rsp+060h],xmm12         ; save xmm12 on stack
         .savexmm128   xmm12,060h
         .endprolog

         mov           r11d,07fh                            ;
         xor           eax,eax                              ;
         vpxor         xmm5,xmm5,xmm5                       ;
         mov           r8d,02c0bh                           ;
         vmovd         xmm8,r8d                             ;
         vpbroadcastd  ymm8,xmm8                            ;
         vmovd         xmm4,r11d                            ;
         mov           r11d,07e6c00h                        ;
         mov           r9d,080h                             ;
         vmovd         xmm7,r9d                             ;
         vpbroadcastd  ymm7,xmm7                            ;
         mov           r10d,02bh                            ;
         vmovd         xmm6,r10d                            ;
         vpbroadcastd  ymm6,xmm6                            ;
         vmovd         xmm3,r11d                            ;
         vpbroadcastd  ymm4,xmm4                            ;
         vpbroadcastd  ymm3,xmm3                            ;

         ALIGN         16

Lmld_poly_use_hint_88_avx2_asm_loop:

         vmovdqa       ymm0,ymmword ptr [rcx]               ;
         vmovdqa       ymm1,ymmword ptr [rdx]               ;
         vpaddd        ymm10,ymm4,ymm0                      ;
         vpsrld        ymm10,ymm10,07h                      ;
         vpmulhuw      ymm10,ymm10,ymm8                     ;
         vpmulhrsw     ymm10,ymm10,ymm7                     ;
         vpcmpgtd      ymm11,ymm0,ymm3                      ;
         vpandn        ymm9,ymm11,ymm10                     ;
         vpslld        ymm12,ymm10,01h                      ;
         vpaddd        ymm12,ymm12,ymm10                    ;
         vpslld        ymm10,ymm12,05h                      ;
         vpsubd        ymm10,ymm10,ymm12                    ;
         vpslld        ymm10,ymm10,0bh                      ;
         vpsubd        ymm0,ymm0,ymm10                      ;
         vpaddd        ymm0,ymm0,ymm11                      ;
         vpcmpgtd      ymm0,ymm0,ymm5                       ;
         vpandn        ymm0,ymm0,ymm1                       ;
         vpslld        ymm0,ymm0,01h                        ;
         vpsubd        ymm0,ymm1,ymm0                       ;
         vpaddd        ymm0,ymm0,ymm9                       ;
         vpblendvb     ymm0,ymm0,ymm6,ymm0                  ;
         vpcmpgtd      ymm1,ymm0,ymm6                       ;
         vpandn        ymm0,ymm1,ymm0                       ;
         vmovdqa       ymmword ptr [rcx],ymm0               ;
         add           rcx,020h                             ;
         add           rdx,020h                             ;
         add           rax,020h                             ;
         cmp           rax,0400h                            ;
         jne           Lmld_poly_use_hint_88_avx2_asm_loop  ;

         vzeroupper                                         ;

         vmovdqa       xmm6,xmmword ptr [rsp+000h]          ; restore xmm6 from stack
         vmovdqa       xmm7,xmmword ptr [rsp+010h]          ; restore xmm7 from stack
         vmovdqa       xmm8,xmmword ptr [rsp+020h]          ; restore xmm8 from stack
         vmovdqa       xmm9,xmmword ptr [rsp+030h]          ; restore xmm9 from stack
         vmovdqa       xmm10,xmmword ptr [rsp+040h]         ; restore xmm10 from stack
         vmovdqa       xmm11,xmmword ptr [rsp+050h]         ; restore xmm11 from stack
         vmovdqa       xmm12,xmmword ptr [rsp+060h]         ; restore xmm12 from stack

         add           rsp,078h                             ; 078h and not 070h for alignment purposes

         ret                                   ;

FUNC_NAME ENDP

         END
