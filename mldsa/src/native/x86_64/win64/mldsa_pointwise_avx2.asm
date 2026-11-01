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
; Name: pointwise_avx2_asm
; Description: x86_64 AVX2 pointwise Montgomery multiplication
; Signature: void mld_pointwise_avx2_asm(int32_t *a, const int32_t *b, const int32_t *qdata)
; ABI:
;   Architecture: x86_64
;   CallingConvention: SysV
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
;     c_parameter: const int32_t *b
;     description: Input polynomial (256 x int32_t)
;   r8:
;     type: buffer
;     size_bytes: 2496
;     permissions: read-only
;     c_parameter: const int32_t *qdata
;     description: Precomputed constants (624 x int32_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_pointwise_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         sub         rsp,088h                             ; 088h and not 080h for alignment purposes
         .allocstack 088h

         vmovdqa     xmmword ptr [rsp+000h],xmm6          ; save xmm6 on stack
         .savexmm128 xmm6,000h
         vmovdqa     xmmword ptr [rsp+010h],xmm7          ; save xmm7 on stack
         .savexmm128 xmm7,010h
         vmovdqa     xmmword ptr [rsp+020h],xmm10         ; save xmm10 on stack
         .savexmm128 xmm10,020h
         vmovdqa     xmmword ptr [rsp+030h],xmm11         ; save xmm11 on stack
         .savexmm128 xmm11,030h
         vmovdqa     xmmword ptr [rsp+040h],xmm12         ; save xmm12 on stack
         .savexmm128 xmm12,040h
         vmovdqa     xmmword ptr [rsp+050h],xmm13         ; save xmm13 on stack
         .savexmm128 xmm13,050h
         vmovdqa     xmmword ptr [rsp+060h],xmm14         ; save xmm14 on stack
         .savexmm128 xmm14,060h
         vmovdqa     xmmword ptr [rsp+070h],xmm15         ; save xmm15 on stack
         .savexmm128 xmm15,070h
         .endprolog

         vmovdqa     ymm0,ymmword ptr [r8+020h]    ;
         vmovdqa     ymm1,ymmword ptr [r8]         ;
         xor         eax,eax                       ;

         ALIGN       16

Lmld_pointwise_avx2_looptop1:

         vmovdqa     ymm2,ymmword ptr [rcx]        ;
         vmovdqa     ymm4,ymmword ptr [rcx+020h]   ;
         vmovdqa     ymm6,ymmword ptr [rcx+040h]   ;
         vmovdqa     ymm10,ymmword ptr [rdx]       ;
         vmovdqa     ymm12,ymmword ptr [rdx+020h]  ;
         vmovdqa     ymm14,ymmword ptr [rdx+040h]  ;
         vpsrlq      ymm3,ymm2,020h                ;
         vpsrlq      ymm5,ymm4,020h                ;
         vmovshdup   ymm7,ymm6                     ;
         vpsrlq      ymm11,ymm10,020h              ;
         vpsrlq      ymm13,ymm12,020h              ;
         vmovshdup   ymm15,ymm14                   ;
         vpmuldq     ymm2,ymm2,ymm10               ;
         vpmuldq     ymm3,ymm3,ymm11               ;
         vpmuldq     ymm4,ymm4,ymm12               ;
         vpmuldq     ymm5,ymm5,ymm13               ;
         vpmuldq     ymm6,ymm6,ymm14               ;
         vpmuldq     ymm7,ymm7,ymm15               ;
         vpmuldq     ymm10,ymm0,ymm2               ;
         vpmuldq     ymm11,ymm0,ymm3               ;
         vpmuldq     ymm12,ymm0,ymm4               ;
         vpmuldq     ymm13,ymm0,ymm5               ;
         vpmuldq     ymm14,ymm0,ymm6               ;
         vpmuldq     ymm15,ymm0,ymm7               ;
         vpmuldq     ymm10,ymm1,ymm10              ;
         vpmuldq     ymm11,ymm1,ymm11              ;
         vpmuldq     ymm12,ymm1,ymm12              ;
         vpmuldq     ymm13,ymm1,ymm13              ;
         vpmuldq     ymm14,ymm1,ymm14              ;
         vpmuldq     ymm15,ymm1,ymm15              ;
         vpsubq      ymm2,ymm2,ymm10               ;
         vpsubq      ymm3,ymm3,ymm11               ;
         vpsubq      ymm4,ymm4,ymm12               ;
         vpsubq      ymm5,ymm5,ymm13               ;
         vpsubq      ymm6,ymm6,ymm14               ;
         vpsubq      ymm7,ymm7,ymm15               ;
         vpsrlq      ymm2,ymm2,020h                ;
         vpsrlq      ymm4,ymm4,020h                ;
         vmovshdup   ymm6,ymm6                     ;
         vpblendd    ymm2,ymm2,ymm3,0aah           ;
         vpblendd    ymm4,ymm4,ymm5,0aah           ;
         vpblendd    ymm6,ymm6,ymm7,0aah           ;
         vmovdqa     ymmword ptr [rcx],ymm2        ;
         vmovdqa     ymmword ptr [rcx+020h],ymm4   ;
         vmovdqa     ymmword ptr [rcx+040h],ymm6   ;
         add         rcx,060h                      ;
         add         rdx,060h                      ;
         add         eax,01h                       ;
         cmp         eax,0ah                       ;
         jb          Lmld_pointwise_avx2_looptop1  ;
         vmovdqa     ymm2,ymmword ptr [rcx]        ;
         vmovdqa     ymm4,ymmword ptr [rcx+020h]   ;
         vmovdqa     ymm10,ymmword ptr [rdx]       ;
         vmovdqa     ymm12,ymmword ptr [rdx+020h]  ;
         vpsrlq      ymm3,ymm2,020h                ;
         vpsrlq      ymm5,ymm4,020h                ;
         vmovshdup   ymm11,ymm10                   ;
         vmovshdup   ymm13,ymm12                   ;
         vpmuldq     ymm2,ymm2,ymm10               ;
         vpmuldq     ymm3,ymm3,ymm11               ;
         vpmuldq     ymm4,ymm4,ymm12               ;
         vpmuldq     ymm5,ymm5,ymm13               ;
         vpmuldq     ymm10,ymm0,ymm2               ;
         vpmuldq     ymm11,ymm0,ymm3               ;
         vpmuldq     ymm12,ymm0,ymm4               ;
         vpmuldq     ymm13,ymm0,ymm5               ;
         vpmuldq     ymm10,ymm1,ymm10              ;
         vpmuldq     ymm11,ymm1,ymm11              ;
         vpmuldq     ymm12,ymm1,ymm12              ;
         vpmuldq     ymm13,ymm1,ymm13              ;
         vpsubq      ymm2,ymm2,ymm10               ;
         vpsubq      ymm3,ymm3,ymm11               ;
         vpsubq      ymm4,ymm4,ymm12               ;
         vpsubq      ymm5,ymm5,ymm13               ;
         vpsrlq      ymm2,ymm2,020h                ;
         vmovshdup   ymm4,ymm4                     ;
         vpblendd    ymm2,ymm3,ymm2,055h           ;
         vpblendd    ymm4,ymm5,ymm4,055h           ;
         vmovdqa     ymmword ptr [rcx],ymm2        ;
         vmovdqa     ymmword ptr [rcx+020h],ymm4   ;
         vzeroupper                                ;

         vmovdqa     xmm6,xmmword ptr [rsp+000h]   ; restore xmm6 from stack
         vmovdqa     xmm7,xmmword ptr [rsp+010h]   ; restore xmm7 from stack
         vmovdqa     xmm10,xmmword ptr [rsp+020h]  ; restore xmm10 from stack
         vmovdqa     xmm11,xmmword ptr [rsp+030h]  ; restore xmm11 from stack
         vmovdqa     xmm12,xmmword ptr [rsp+040h]  ; restore xmm12 from stack
         vmovdqa     xmm13,xmmword ptr [rsp+050h]  ; restore xmm13 from stack
         vmovdqa     xmm14,xmmword ptr [rsp+060h]  ; restore xmm14 from stack
         vmovdqa     xmm15,xmmword ptr [rsp+070h]  ; restore xmm15 from stack

         add         rsp,088h                      ; 088h and not 080h for alignment purposes

         ret                                       ;

FUNC_NAME ENDP

         END
