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
; Name: polyz_unpack_19_avx2_asm
; Description: x86_64 AVX2 unpacking of 19-bit packed coefficients.
;   Unpack polynomial z with 20-bit packed coefficients (GAMMA1 = 2^19),
;   mapping packed [0, 2^20-1] to signed [-(2^19-1), 2^19] via GAMMA1 - x.
; Signature: void mld_polyz_unpack_19_avx2_asm(int32_t *r, const uint8_t *a)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t *r
;     description: Output polynomial (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 640
;     permissions: read-only
;     c_parameter: const uint8_t *a
;     description: Packed input bytes
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_polyz_unpack_19_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  .endprolog

  mov           rax,0ff040302ff020100h        ;
  vmovq         xmm1,rax                      ;
  mov           rax,0ff090807ff070605h        ;
  vpinsrq       xmm1,xmm1,rax,01h             ;
  mov           rax,0ff1a1918ff181716h        ;
  vmovq         xmm5,rax                      ;
  mov           rax,0ff1f1e1dff1d1c1bh        ;
  vpinsrq       xmm5,xmm5,rax,01h             ;
  vinserti128   ymm1,ymm1,xmm5,01h            ;
  mov           rax,0400000000h               ;
  vmovq         xmm2,rax                      ;
  mov           rax,0400000000h               ;
  vpinsrq       xmm2,xmm2,rax,01h             ;
  vinserti128   ymm2,ymm2,xmm2,01h            ;
  mov           eax,0fffffh                   ;
  vmovd         xmm3,eax                      ;
  vpbroadcastd  ymm3,xmm3                     ;
  mov           eax,080000h                   ;
  vmovd         xmm4,eax                      ;
  vpbroadcastd  ymm4,xmm4                     ;
  vmovdqu       xmm0,xmmword ptr [rdx]        ;
  vmovdqu       xmm5,xmmword ptr [rdx+04h]    ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx],ymm0        ;
  vmovdqu       xmm0,xmmword ptr [rdx+014h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+018h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+020h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+028h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+02ch]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+040h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+03ch]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+040h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+060h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+050h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+054h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+080h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+064h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+068h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0a0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+078h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+07ch]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0c0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+08ch]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+090h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0e0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+0a0h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0a4h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0100h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0b4h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0b8h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0120h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0c8h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0cch]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0140h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0dch]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0e0h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0160h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0f0h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0f4h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0180h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0104h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0108h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0118h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+011ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+012ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0130h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01e0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0140h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0144h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0200h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0154h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0158h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0220h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0168h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+016ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0240h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+017ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0180h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0260h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0190h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0194h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0280h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01a4h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01a8h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01b8h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01bch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01cch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01d0h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02e0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01e0h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01e4h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0300h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01f4h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01f8h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0320h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0208h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+020ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0340h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+021ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0220h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0360h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0230h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0234h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0380h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0244h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0248h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+03a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0258h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+025ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+03c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+026ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0270h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+03e0h],ymm0  ;

  vzeroupper                                  ;

  ret                                         ;

FUNC_NAME ENDP

  END
