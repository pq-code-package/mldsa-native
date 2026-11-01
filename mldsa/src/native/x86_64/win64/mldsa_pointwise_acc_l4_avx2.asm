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
; Name: pointwise_acc_l4_avx2_asm
; Description: x86_64 AVX2 pointwise multiply-accumulate of length-4 polynomial vectors
; Signature: void mld_pointwise_acc_l4_avx2_asm(int32_t *c, const int32_t a[4][256], const int32_t b[4][256], const int32_t *qdata)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t *c
;     description: Output polynomial (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 4096
;     permissions: read-only
;     c_parameter: const int32_t a[4][256]
;     description: Input polynomial vector a (4 x 256 x int32_t)
;   r8:
;     type: buffer
;     size_bytes: 4096
;     permissions: read-only
;     c_parameter: const int32_t b[4][256]
;     description: Input polynomial vector b (4 x 256 x int32_t)
;   r9:
;     type: buffer
;     size_bytes: 2496
;     permissions: read-only
;     c_parameter: const int32_t *qdata
;     description: Precomputed constants (624 x int32_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_pointwise_acc_l4_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         sub         rsp,088h                             ; 088h and not 080h for alignment purposes
         .allocstack 088h

         vmovdqa     xmmword ptr [rsp+000h],xmm6          ; save xmm6 on stack
         .savexmm128 xmm6,000h
         vmovdqa     xmmword ptr [rsp+010h],xmm7          ; save xmm7 on stack
         .savexmm128 xmm7,010h
         vmovdqa     xmmword ptr [rsp+020h],xmm8          ; save xmm8 on stack
         .savexmm128 xmm8,020h
         vmovdqa     xmmword ptr [rsp+030h],xmm9          ; save xmm9 on stack
         .savexmm128 xmm9,030h
         vmovdqa     xmmword ptr [rsp+040h],xmm10         ; save xmm10 on stack
         .savexmm128 xmm10,040h
         vmovdqa     xmmword ptr [rsp+050h],xmm11         ; save xmm11 on stack
         .savexmm128 xmm11,050h
         vmovdqa     xmmword ptr [rsp+060h],xmm12         ; save xmm12 on stack
         .savexmm128 xmm12,060h
         vmovdqa     xmmword ptr [rsp+070h],xmm13         ; save xmm13 on stack
         .savexmm128 xmm13,070h
         .endprolog

         vmovdqa     ymm0,ymmword ptr [r9+020h]           ;
         vmovdqa     ymm1,ymmword ptr [r9]                ;
         xor         eax,eax                              ;

         ALIGN       16

Lmld_pointwise_acc_l4_avx2_looptop2:

         vmovdqa     ymm6,ymmword ptr [rdx]               ;
         vmovdqa     ymm8,ymmword ptr [rdx+020h]          ;
         vmovdqa     ymm10,ymmword ptr [r8]               ;
         vmovdqa     ymm12,ymmword ptr [r8+020h]          ;
         vpsrlq      ymm7,ymm6,020h                       ;
         vpsrlq      ymm9,ymm8,020h                       ;
         vmovshdup   ymm11,ymm10                          ;
         vmovshdup   ymm13,ymm12                          ;
         vpmuldq     ymm6,ymm6,ymm10                      ;
         vpmuldq     ymm7,ymm7,ymm11                      ;
         vpmuldq     ymm8,ymm8,ymm12                      ;
         vpmuldq     ymm9,ymm9,ymm13                      ;
         vmovdqa     ymm2,ymm6                            ;
         vmovdqa     ymm3,ymm7                            ;
         vmovdqa     ymm4,ymm8                            ;
         vmovdqa     ymm5,ymm9                            ;
         vmovdqa     ymm6,ymmword ptr [rdx+0400h]         ;
         vmovdqa     ymm8,ymmword ptr [rdx+0420h]         ;
         vmovdqa     ymm10,ymmword ptr [r8+0400h]         ;
         vmovdqa     ymm12,ymmword ptr [r8+0420h]         ;
         vpsrlq      ymm7,ymm6,020h                       ;
         vpsrlq      ymm9,ymm8,020h                       ;
         vmovshdup   ymm11,ymm10                          ;
         vmovshdup   ymm13,ymm12                          ;
         vpmuldq     ymm6,ymm6,ymm10                      ;
         vpmuldq     ymm7,ymm7,ymm11                      ;
         vpmuldq     ymm8,ymm8,ymm12                      ;
         vpmuldq     ymm9,ymm9,ymm13                      ;
         vpaddq      ymm2,ymm6,ymm2                       ;
         vpaddq      ymm3,ymm7,ymm3                       ;
         vpaddq      ymm4,ymm8,ymm4                       ;
         vpaddq      ymm5,ymm9,ymm5                       ;
         vmovdqa     ymm6,ymmword ptr [rdx+0800h]         ;
         vmovdqa     ymm8,ymmword ptr [rdx+0820h]         ;
         vmovdqa     ymm10,ymmword ptr [r8+0800h]         ;
         vmovdqa     ymm12,ymmword ptr [r8+0820h]         ;
         vpsrlq      ymm7,ymm6,020h                       ;
         vpsrlq      ymm9,ymm8,020h                       ;
         vmovshdup   ymm11,ymm10                          ;
         vmovshdup   ymm13,ymm12                          ;
         vpmuldq     ymm6,ymm6,ymm10                      ;
         vpmuldq     ymm7,ymm7,ymm11                      ;
         vpmuldq     ymm8,ymm8,ymm12                      ;
         vpmuldq     ymm9,ymm9,ymm13                      ;
         vpaddq      ymm2,ymm6,ymm2                       ;
         vpaddq      ymm3,ymm7,ymm3                       ;
         vpaddq      ymm4,ymm8,ymm4                       ;
         vpaddq      ymm5,ymm9,ymm5                       ;
         vmovdqa     ymm6,ymmword ptr [rdx+0c00h]         ;
         vmovdqa     ymm8,ymmword ptr [rdx+0c20h]         ;
         vmovdqa     ymm10,ymmword ptr [r8+0c00h]         ;
         vmovdqa     ymm12,ymmword ptr [r8+0c20h]         ;
         vpsrlq      ymm7,ymm6,020h                       ;
         vpsrlq      ymm9,ymm8,020h                       ;
         vmovshdup   ymm11,ymm10                          ;
         vmovshdup   ymm13,ymm12                          ;
         vpmuldq     ymm6,ymm6,ymm10                      ;
         vpmuldq     ymm7,ymm7,ymm11                      ;
         vpmuldq     ymm8,ymm8,ymm12                      ;
         vpmuldq     ymm9,ymm9,ymm13                      ;
         vpaddq      ymm2,ymm6,ymm2                       ;
         vpaddq      ymm3,ymm7,ymm3                       ;
         vpaddq      ymm4,ymm8,ymm4                       ;
         vpaddq      ymm5,ymm9,ymm5                       ;
         vpmuldq     ymm6,ymm0,ymm2                       ;
         vpmuldq     ymm7,ymm0,ymm3                       ;
         vpmuldq     ymm8,ymm0,ymm4                       ;
         vpmuldq     ymm9,ymm0,ymm5                       ;
         vpmuldq     ymm6,ymm1,ymm6                       ;
         vpmuldq     ymm7,ymm1,ymm7                       ;
         vpmuldq     ymm8,ymm1,ymm8                       ;
         vpmuldq     ymm9,ymm1,ymm9                       ;
         vpsubq      ymm2,ymm2,ymm6                       ;
         vpsubq      ymm3,ymm3,ymm7                       ;
         vpsubq      ymm4,ymm4,ymm8                       ;
         vpsubq      ymm5,ymm5,ymm9                       ;
         vpsrlq      ymm2,ymm2,020h                       ;
         vmovshdup   ymm4,ymm4                            ;
         vpblendd    ymm2,ymm2,ymm3,0aah                  ;
         vpblendd    ymm4,ymm4,ymm5,0aah                  ;
         vmovdqa     ymmword ptr [rcx],ymm2               ;
         vmovdqa     ymmword ptr [rcx+020h],ymm4          ;
         add         rdx,040h                             ;
         add         r8,040h                              ;
         add         rcx,040h                             ;
         add         eax,01h                              ;
         cmp         eax,010h                             ;
         jb          Lmld_pointwise_acc_l4_avx2_looptop2  ;

         vzeroupper                                       ;

         vmovdqa     xmm6,xmmword ptr [rsp+000h]          ; restore xmm6 from stack
         vmovdqa     xmm7,xmmword ptr [rsp+010h]          ; restore xmm7 from stack
         vmovdqa     xmm8,xmmword ptr [rsp+020h]          ; restore xmm8 from stack
         vmovdqa     xmm9,xmmword ptr [rsp+030h]          ; restore xmm9 from stack
         vmovdqa     xmm10,xmmword ptr [rsp+040h]         ; restore xmm10 from stack
         vmovdqa     xmm11,xmmword ptr [rsp+050h]         ; restore xmm11 from stack
         vmovdqa     xmm12,xmmword ptr [rsp+060h]         ; restore xmm12 from stack
         vmovdqa     xmm13,xmmword ptr [rsp+070h]         ; restore xmm13 from stack

         add         rsp,088h                             ; 088h and not 080h for alignment purposes

         ret                                              ;

FUNC_NAME ENDP

         END
