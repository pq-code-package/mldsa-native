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
; Name: polyz_unpack_17_avx2_asm
; Description: x86_64 AVX2 unpacking of 17-bit packed coefficients.
;   Unpack polynomial z with 18-bit packed coefficients (GAMMA1 = 2^17),
;   mapping packed [0, 2^18-1] to signed [-(2^17-1), 2^17] via GAMMA1 - x.
; Signature: void mld_polyz_unpack_17_avx2_asm(int32_t *r, const uint8_t *a)
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
;     size_bytes: 576
;     permissions: read-only
;     c_parameter: const uint8_t *a
;     description: Packed input bytes
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_polyz_unpack_17_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  .endprolog

  mov           rax,0ff040302ff020100h        ;
  vmovq         xmm1,rax                      ;
  mov           rax,0ff080706ff060504h        ;
  vpinsrq       xmm1,xmm1,rax,01h             ;
  mov           rax,0ff1b1a19ff191817h        ;
  vmovq         xmm5,rax                      ;
  mov           rax,0ff1f1e1dff1d1c1bh        ;
  vpinsrq       xmm5,xmm5,rax,01h             ;
  vinserti128   ymm1,ymm1,xmm5,01h            ;
  mov           rax,0200000000h               ;
  vmovq         xmm2,rax                      ;
  mov           rax,0600000004h               ;
  vpinsrq       xmm2,xmm2,rax,01h             ;
  vinserti128   ymm2,ymm2,xmm2,01h            ;
  mov           eax,03ffffh                   ;
  vmovd         xmm3,eax                      ;
  vpbroadcastd  ymm3,xmm3                     ;
  mov           eax,020000h                   ;
  vmovd         xmm4,eax                      ;
  vpbroadcastd  ymm4,xmm4                     ;
  vmovdqu       xmm0,xmmword ptr [rdx]        ;
  vmovdqu       xmm5,xmmword ptr [rdx+02h]    ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx],ymm0        ;
  vmovdqu       xmm0,xmmword ptr [rdx+012h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+014h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+020h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+024h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+026h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+040h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+036h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+038h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+060h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+048h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+04ah]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+080h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+05ah]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+05ch]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0a0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+06ch]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+06eh]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0c0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+07eh]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+080h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0e0h],ymm0   ;
  vmovdqu       xmm0,xmmword ptr [rdx+090h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+092h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0100h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0a2h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0a4h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0120h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0b4h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0b6h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0140h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0c6h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0c8h]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0160h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0d8h]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0dah]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0180h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0eah]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0ech]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0fch]   ;
  vmovdqu       xmm5,xmmword ptr [rdx+0feh]   ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+010eh]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0110h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+01e0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0120h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0122h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0200h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0132h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0134h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0220h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0144h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0146h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0240h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0156h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0158h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0260h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+0168h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+016ah]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0280h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+017ah]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+017ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+018ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+018eh]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+019eh]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01a0h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+02e0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01b0h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01b2h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0300h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01c2h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01c4h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0320h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01d4h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01d6h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0340h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01e6h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01e8h]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0360h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+01f8h]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+01fah]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+0380h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+020ah]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+020ch]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+03a0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+021ch]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+021eh]  ;
  vinserti128   ymm0,ymm0,xmm5,01h            ;
  vpshufb       ymm0,ymm0,ymm1                ;
  vpsrlvd       ymm0,ymm0,ymm2                ;
  vpand         ymm0,ymm0,ymm3                ;
  vpsubd        ymm0,ymm4,ymm0                ;
  vmovdqa       ymmword ptr [rcx+03c0h],ymm0  ;
  vmovdqu       xmm0,xmmword ptr [rdx+022eh]  ;
  vmovdqu       xmm5,xmmword ptr [rdx+0230h]  ;
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
