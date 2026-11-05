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
; Name: poly_chknorm_avx2_asm
; Description: x86_64 AVX2 infinity-norm bound check on polynomial coefficients.
;   Check the infinity norm of the polynomial against the given bound B.
;   Returns 0 if the norm is strictly smaller than B; otherwise returns 1
;   (i.e. returns 1 if any |coefficient| >= B, 0 otherwise).
; Signature: int mld_poly_chknorm_avx2_asm(const int32_t *a, int64_t B)
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: read-only
;     c_parameter: const int32_t *a
;     description: Input polynomial (256 x int32_t)
;   rdx:
;     type: scalar
;     c_parameter: int64_t B (uses only the least-significant 32bits)
;     description: Norm bound (must be non-negative)
;     test_with: 131072  # representative non-negative bound (1 << 17)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_poly_chknorm_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  .endprolog

  sub           edx,01h                       ;
  vpxor         xmm1,xmm1,xmm1                ;
  vmovd         xmm2,edx                      ;
  vpbroadcastd  ymm2,xmm2                     ;
  vpabsd        ymm0,ymmword ptr [rcx]        ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+020h]   ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+040h]   ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+060h]   ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+080h]   ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+0a0h]   ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+0c0h]   ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+0e0h]   ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0100h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+0120h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+0140h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+0160h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0180h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+01a0h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+01c0h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+01e0h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0200h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+0220h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+0240h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+0260h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0280h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+02a0h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+02c0h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+02e0h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0300h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+0320h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+0340h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+0360h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  vpabsd        ymm0,ymmword ptr [rcx+0380h]  ;
  vpcmpgtd      ymm0,ymm0,ymm2                ;
  vpor          ymm1,ymm1,ymm0                ;
  vpabsd        ymm3,ymmword ptr [rcx+03a0h]  ;
  vpcmpgtd      ymm3,ymm3,ymm2                ;
  vpor          ymm1,ymm1,ymm3                ;
  vpabsd        ymm4,ymmword ptr [rcx+03c0h]  ;
  vpcmpgtd      ymm4,ymm4,ymm2                ;
  vpor          ymm1,ymm1,ymm4                ;
  vpabsd        ymm5,ymmword ptr [rcx+03e0h]  ;
  vpcmpgtd      ymm5,ymm5,ymm2                ;
  vpor          ymm1,ymm1,ymm5                ;
  xor           eax,eax                       ;
  vptest        ymm1,ymm1                     ;
  setne         al                            ;
  vzeroupper                                  ;
  ret                                         ;

FUNC_NAME ENDP

  END
