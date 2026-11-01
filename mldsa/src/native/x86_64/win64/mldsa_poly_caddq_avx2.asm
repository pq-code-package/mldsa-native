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
; Name: poly_caddq_avx2_asm
; Description: x86_64 AVX2 conditional addition of q to each coefficient.
;   For all coefficients of the in/out polynomial, add Q if the coefficient
;   is negative.
; Signature: void mld_poly_caddq_avx2_asm(int32_t *r)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t *r
;     description: Input/output polynomial (256 x int32_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_poly_caddq_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  .endprolog

  vpxor         xmm2,xmm2,xmm2                     ;
  mov           eax,07fe001h                       ;
  vmovd         xmm1,eax                           ;
  vpbroadcastd  ymm1,xmm1                          ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx]        ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx]        ;
  vmovdqa       ymmword ptr [rcx],ymm0             ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+020h]   ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+020h]   ;
  vmovdqa       ymmword ptr [rcx+020h],ymm3        ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+040h]   ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+040h]   ;
  vmovdqa       ymmword ptr [rcx+040h],ymm4        ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+060h]   ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+060h]   ;
  vmovdqa       ymmword ptr [rcx+060h],ymm5        ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+080h]   ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+080h]   ;
  vmovdqa       ymmword ptr [rcx+080h],ymm0        ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+0a0h]   ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+0a0h]   ;
  vmovdqa       ymmword ptr [rcx+0a0h],ymm3        ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+0c0h]   ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+0c0h]   ;
  vmovdqa       ymmword ptr [rcx+0c0h],ymm4        ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+0e0h]   ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+0e0h]   ;
  vmovdqa       ymmword ptr [rcx+0e0h],ymm5        ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0100h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0100h]  ;
  vmovdqa       ymmword ptr [rcx+0100h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+0120h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+0120h]  ;
  vmovdqa       ymmword ptr [rcx+0120h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+0140h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+0140h]  ;
  vmovdqa       ymmword ptr [rcx+0140h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+0160h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+0160h]  ;
  vmovdqa       ymmword ptr [rcx+0160h],ymm5       ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0180h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0180h]  ;
  vmovdqa       ymmword ptr [rcx+0180h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+01a0h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+01a0h]  ;
  vmovdqa       ymmword ptr [rcx+01a0h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+01c0h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+01c0h]  ;
  vmovdqa       ymmword ptr [rcx+01c0h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+01e0h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+01e0h]  ;
  vmovdqa       ymmword ptr [rcx+01e0h],ymm5       ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0200h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0200h]  ;
  vmovdqa       ymmword ptr [rcx+0200h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+0220h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+0220h]  ;
  vmovdqa       ymmword ptr [rcx+0220h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+0240h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+0240h]  ;
  vmovdqa       ymmword ptr [rcx+0240h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+0260h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+0260h]  ;
  vmovdqa       ymmword ptr [rcx+0260h],ymm5       ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0280h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0280h]  ;
  vmovdqa       ymmword ptr [rcx+0280h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+02a0h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+02a0h]  ;
  vmovdqa       ymmword ptr [rcx+02a0h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+02c0h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+02c0h]  ;
  vmovdqa       ymmword ptr [rcx+02c0h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+02e0h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+02e0h]  ;
  vmovdqa       ymmword ptr [rcx+02e0h],ymm5       ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0300h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0300h]  ;
  vmovdqa       ymmword ptr [rcx+0300h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+0320h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+0320h]  ;
  vmovdqa       ymmword ptr [rcx+0320h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+0340h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+0340h]  ;
  vmovdqa       ymmword ptr [rcx+0340h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+0360h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+0360h]  ;
  vmovdqa       ymmword ptr [rcx+0360h],ymm5       ;
  vpcmpgtd      ymm0,ymm2,ymmword ptr [rcx+0380h]  ;
  vpand         ymm0,ymm0,ymm1                     ;
  vpaddd        ymm0,ymm0,ymmword ptr [rcx+0380h]  ;
  vmovdqa       ymmword ptr [rcx+0380h],ymm0       ;
  vpcmpgtd      ymm3,ymm2,ymmword ptr [rcx+03a0h]  ;
  vpand         ymm3,ymm3,ymm1                     ;
  vpaddd        ymm3,ymm3,ymmword ptr [rcx+03a0h]  ;
  vmovdqa       ymmword ptr [rcx+03a0h],ymm3       ;
  vpcmpgtd      ymm4,ymm2,ymmword ptr [rcx+03c0h]  ;
  vpand         ymm4,ymm4,ymm1                     ;
  vpaddd        ymm4,ymm4,ymmword ptr [rcx+03c0h]  ;
  vmovdqa       ymmword ptr [rcx+03c0h],ymm4       ;
  vpcmpgtd      ymm5,ymm2,ymmword ptr [rcx+03e0h]  ;
  vpand         ymm5,ymm5,ymm1                     ;
  vpaddd        ymm5,ymm5,ymmword ptr [rcx+03e0h]  ;
  vmovdqa       ymmword ptr [rcx+03e0h],ymm5       ;

  vzeroupper                                       ;

  ret                                              ;

FUNC_NAME ENDP

  END
