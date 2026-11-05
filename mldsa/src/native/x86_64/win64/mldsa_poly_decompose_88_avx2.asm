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

; Name: poly_decompose_88_avx2_asm
; Description: x86_64 AVX2 coefficient decomposition (alpha = 2*(Q-1)/88).
;   For all coefficients c of the input polynomial, compute high and low bits
;   c0, c1 such that c = c1*ALPHA + c0 with -ALPHA/2 < c0 <= ALPHA/2, except if
;   c1 = (Q-1)/ALPHA where we set c1 = 0 and -ALPHA/2 <= c0 = c - Q < 0.
;   Assumes coefficients to be standard (unsigned canonical) representatives,
;   i.e. 0 <= c < Q. For ML-DSA-44 (gamma2 = (Q-1)/88, alpha = 2*gamma2).
; Signature: void mld_poly_decompose_88_avx2_asm(int32_t *a1, int32_t *a0)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t *a1
;     description: Output high-part polynomial (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t *a0
;     description: Input polynomial / output low-part (256 x int32_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_poly_decompose_88_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  sub           rsp,058h                      ; 058h and not 050h for alignment purposes
  .allocstack   058h

  vmovdqa       xmmword ptr [rsp+000h],xmm10  ; save xmm10 on stack
  .savexmm128   xmm10,000h
  vmovdqa       xmmword ptr [rsp+010h],xmm11  ; save xmm11 on stack
  .savexmm128   xmm11,010h
  vmovdqa       xmmword ptr [rsp+020h],xmm12  ; save xmm12 on stack
  .savexmm128   xmm12,020h
  vmovdqa       xmmword ptr [rsp+030h],xmm13  ; save xmm13 on stack
  .savexmm128   xmm13,030h
  vmovdqa       xmmword ptr [rsp+040h],xmm14  ; save xmm14 on stack
  .savexmm128   xmm14,040h
  .endprolog

  mov           eax,07fh                      ;
  vmovd         xmm10,eax                     ;
  vpbroadcastd  ymm10,xmm10                   ;
  mov           eax,02c0bh                    ;
  vmovd         xmm11,eax                     ;
  vpbroadcastd  ymm11,xmm11                   ;
  mov           eax,080h                      ;
  vmovd         xmm12,eax                     ;
  vpbroadcastd  ymm12,xmm12                   ;
  mov           eax,07e6c00h                  ;
  vmovd         xmm13,eax                     ;
  vpbroadcastd  ymm13,xmm13                   ;
  mov           eax,02e800h                   ;
  vmovd         xmm14,eax                     ;
  vpbroadcastd  ymm14,xmm14                   ;
  vmovdqa       ymm0,ymmword ptr [rdx]        ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx],ymm1        ;
  vmovdqa       ymmword ptr [rdx],ymm2        ;
  vmovdqa       ymm0,ymmword ptr [rdx+020h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+020h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+020h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+040h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+040h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+040h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+060h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+060h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+060h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+080h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+080h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+080h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+0a0h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0a0h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+0a0h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+0c0h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0c0h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+0c0h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+0e0h]   ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0e0h],ymm1   ;
  vmovdqa       ymmword ptr [rdx+0e0h],ymm2   ;
  vmovdqa       ymm0,ymmword ptr [rdx+0100h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0100h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0100h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0120h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0120h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0120h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0140h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0140h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0140h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0160h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0160h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0160h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0180h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0180h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0180h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+01a0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+01a0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+01a0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+01c0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+01c0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+01c0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+01e0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+01e0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+01e0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0200h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0200h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0200h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0220h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0220h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0220h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0240h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0240h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0240h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0260h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0260h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0260h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0280h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0280h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0280h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+02a0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+02a0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+02a0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+02c0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+02c0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+02c0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+02e0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+02e0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+02e0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0300h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0300h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0300h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0320h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0320h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0320h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0340h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0340h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0340h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0360h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0360h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0360h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+0380h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+0380h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+0380h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+03a0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+03a0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+03a0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+03c0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+03c0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+03c0h],ymm2  ;
  vmovdqa       ymm0,ymmword ptr [rdx+03e0h]  ;
  vpaddd        ymm1,ymm0,ymm10               ;
  vpsrld        ymm1,ymm1,07h                 ;
  vpmulhuw      ymm1,ymm1,ymm11               ;
  vpmulhrsw     ymm1,ymm1,ymm12               ;
  vpcmpgtd      ymm3,ymm0,ymm13               ;
  vpmulld       ymm2,ymm1,ymm14               ;
  vpsubd        ymm2,ymm0,ymm2                ;
  vpandn        ymm1,ymm3,ymm1                ;
  vpaddd        ymm2,ymm2,ymm3                ;
  vmovdqa       ymmword ptr [rcx+03e0h],ymm1  ;
  vmovdqa       ymmword ptr [rdx+03e0h],ymm2  ;

  vzeroupper                                  ;

  vmovdqa       xmm10,xmmword ptr [rsp+000h]  ; restore xmm10 from stack
  vmovdqa       xmm11,xmmword ptr [rsp+010h]  ; restore xmm11 from stack
  vmovdqa       xmm12,xmmword ptr [rsp+020h]  ; restore xmm12 from stack
  vmovdqa       xmm13,xmmword ptr [rsp+030h]  ; restore xmm13 from stack
  vmovdqa       xmm14,xmmword ptr [rsp+040h]  ; restore xmm14 from stack

  add           rsp,058h                      ; 058h and not 050h for alignment purposes

  ret                                         ;

FUNC_NAME ENDP

  END
