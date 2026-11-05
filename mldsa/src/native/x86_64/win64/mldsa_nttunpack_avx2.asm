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

; yaml
; Name: nttunpack_avx2_asm
; Description: x86_64 AVX2 NTT coefficient unpacking/permutation
; Signature: void mld_nttunpack_avx2_asm(int32_t *r)
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

                        .CODE

                         ALIGN 16

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_nttunpack_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

  ; Register usage (steady state in this routine):
  ; - ymm4..ymm11 : source/destination coefficient vectors
  ; - ymm3 : temporary cross-lane/interleave vector
  ; - rcx : base pointer to coefficient array r (in-place permutation)

  sub           rsp,068h                      ; 068h and not 060h for alignment purposes
  .allocstack    068h

  vmovdqa       xmmword ptr [rsp+000h],xmm6   ; save xmm6 on stack
  .savexmm128    xmm6,000h
  vmovdqa       xmmword ptr [rsp+010h],xmm7   ; save xmm7 on stack
  .savexmm128    xmm7,010h
  vmovdqa       xmmword ptr [rsp+020h],xmm8   ; save xmm8 on stack
  .savexmm128    xmm8,020h
  vmovdqa       xmmword ptr [rsp+030h],xmm9   ; save xmm9 on stack
  .savexmm128    xmm9,030h
  vmovdqa       xmmword ptr [rsp+040h],xmm10  ; save xmm10 on stack
  .savexmm128    xmm10,040h
  vmovdqa       xmmword ptr [rsp+050h],xmm11  ; save xmm11 on stack
  .savexmm128    xmm11,050h
  .endprolog

  vmovdqa      ymm4,ymmword ptr [rcx]         ; load r[0..7]
  vmovdqa      ymm5,ymmword ptr [rcx+020h]    ; load r[8..15]
  vmovdqa      ymm6,ymmword ptr [rcx+040h]    ; load r[16..23]
  vmovdqa      ymm7,ymmword ptr [rcx+060h]    ; load r[24..31]
  vmovdqa      ymm8,ymmword ptr [rcx+080h]    ; load r[32..39]
  vmovdqa      ymm9,ymmword ptr [rcx+0a0h]    ; load r[40..47]
  vmovdqa      ymm10,ymmword ptr [rcx+0c0h]   ; load r[48..55]
  vmovdqa      ymm11,ymmword ptr [rcx+0e0h]   ; load r[56..63]
  vperm2i128   ymm3,ymm4,ymm8,020h            ; combine low 128-bit halves from (ymm4, ymm8)
  vperm2i128   ymm8,ymm4,ymm8,031h            ; combine high 128-bit halves from (ymm4, ymm8)
  vperm2i128   ymm4,ymm5,ymm9,020h            ; combine low halves from (ymm5, ymm9)
  vperm2i128   ymm9,ymm5,ymm9,031h            ; combine high halves from (ymm5, ymm9)
  vperm2i128   ymm5,ymm6,ymm10,020h           ; combine low halves from (ymm6, ymm10)
  vperm2i128   ymm10,ymm6,ymm10,031h          ; combine high halves from (ymm6, ymm10)
  vperm2i128   ymm6,ymm7,ymm11,020h           ; combine low halves from (ymm7, ymm11)
  vperm2i128   ymm11,ymm7,ymm11,031h          ; combine high halves from (ymm7, ymm11)
  vpunpcklqdq  ymm7,ymm3,ymm5                 ; interleave low qwords (stage transpose)
  vpunpckhqdq  ymm5,ymm3,ymm5                 ; interleave high qwords (stage transpose)
  vpunpcklqdq  ymm3,ymm8,ymm10                ; interleave low qwords
  vpunpckhqdq  ymm10,ymm8,ymm10               ; interleave high qwords
  vpunpcklqdq  ymm8,ymm4,ymm6                 ; interleave low qwords
  vpunpckhqdq  ymm6,ymm4,ymm6                 ; interleave high qwords
  vpunpcklqdq  ymm4,ymm9,ymm11                ; interleave low qwords
  vpunpckhqdq  ymm11,ymm9,ymm11               ; interleave high qwords
  vmovsldup    ymm9,ymm8                      ; duplicate low dwords for blend-based 32-bit lane packing
  vpblendd     ymm9,ymm7,ymm9,0aah            ; merge alternating dwords into unpacked order
  vpsrlq       ymm7,ymm7,020h                 ; move high dword of each qword down
  vpblendd     ymm8,ymm7,ymm8,0aah            ; merge complementary dwords
  vmovsldup    ymm7,ymm6                      ; duplicate low dwords
  vpblendd     ymm7,ymm5,ymm7,0aah            ; merge alternating dwords
  vpsrlq       ymm5,ymm5,020h                 ; shift high dwords into low positions
  vpblendd     ymm6,ymm5,ymm6,0aah            ; merge complementary dwords
  vmovsldup    ymm5,ymm4                      ; duplicate low dwords
  vpblendd     ymm5,ymm3,ymm5,0aah            ; merge alternating dwords
  vpsrlq       ymm3,ymm3,020h                 ; shift high dwords into low positions
  vpblendd     ymm4,ymm3,ymm4,0aah            ; merge complementary dwords
  vmovsldup    ymm3,ymm11                     ; duplicate low dwords
  vpblendd     ymm3,ymm10,ymm3,0aah           ; merge alternating dwords
  vpsrlq       ymm10,ymm10,020h               ; shift high dwords into low positions
  vpblendd     ymm11,ymm10,ymm11,0aah         ; merge complementary dwords
  vmovdqa      ymmword ptr [rcx],ymm9         ; store permuted r[0..7]
  vmovdqa      ymmword ptr [rcx+020h],ymm8    ; store permuted r[8..15]
  vmovdqa      ymmword ptr [rcx+040h],ymm7    ; store permuted r[16..23]
  vmovdqa      ymmword ptr [rcx+060h],ymm6    ; store permuted r[24..31]
  vmovdqa      ymmword ptr [rcx+080h],ymm5    ; store permuted r[32..39]
  vmovdqa      ymmword ptr [rcx+0a0h],ymm4    ; store permuted r[40..47]
  vmovdqa      ymmword ptr [rcx+0c0h],ymm3    ; store permuted r[48..55]
  vmovdqa      ymmword ptr [rcx+0e0h],ymm11   ; store permuted r[56..63]
  ; Repeat same unpack/permutation kernel for r[64..127].
  vmovdqa      ymm4,ymmword ptr [rcx+0100h]   ; load r[64..71]
  vmovdqa      ymm5,ymmword ptr [rcx+0120h]   ; load r[72..79]
  vmovdqa      ymm6,ymmword ptr [rcx+0140h]   ; load r[80..87]
  vmovdqa      ymm7,ymmword ptr [rcx+0160h]   ; load r[88..95]
  vmovdqa      ymm8,ymmword ptr [rcx+0180h]   ; load r[96..103]
  vmovdqa      ymm9,ymmword ptr [rcx+01a0h]   ; load r[104..111]
  vmovdqa      ymm10,ymmword ptr [rcx+01c0h]  ; load r[112..119]
  vmovdqa      ymm11,ymmword ptr [rcx+01e0h]  ; load r[120..127]
  vperm2i128   ymm3,ymm4,ymm8,020h            ; phase 1: cross-lane half swap/combine (same pattern as first block)
  vperm2i128   ymm8,ymm4,ymm8,031h            ;
  vperm2i128   ymm4,ymm5,ymm9,020h            ;
  vperm2i128   ymm9,ymm5,ymm9,031h            ;
  vperm2i128   ymm5,ymm6,ymm10,020h           ;
  vperm2i128   ymm10,ymm6,ymm10,031h          ;
  vperm2i128   ymm6,ymm7,ymm11,020h           ;
  vperm2i128   ymm11,ymm7,ymm11,031h          ;
  vpunpcklqdq  ymm7,ymm3,ymm5                 ;
  vpunpckhqdq  ymm5,ymm3,ymm5                 ;
  vpunpcklqdq  ymm3,ymm8,ymm10                ;
  vpunpckhqdq  ymm10,ymm8,ymm10               ;
  vpunpcklqdq  ymm8,ymm4,ymm6                 ;
  vpunpckhqdq  ymm6,ymm4,ymm6                 ;
  vpunpcklqdq  ymm4,ymm9,ymm11                ;
  vpunpckhqdq  ymm11,ymm9,ymm11               ;
  vmovsldup    ymm9,ymm8                      ; phase 3: 32-bit lane repack (same pattern as first block)
  vpblendd     ymm9,ymm7,ymm9,0aah            ;
  vpsrlq       ymm7,ymm7,020h                 ;
  vpblendd     ymm8,ymm7,ymm8,0aah            ;
  vmovsldup    ymm7,ymm6                      ;
  vpblendd     ymm7,ymm5,ymm7,0aah            ;
  vpsrlq       ymm5,ymm5,020h                 ;
  vpblendd     ymm6,ymm5,ymm6,0aah            ;
  vmovsldup    ymm5,ymm4                      ;
  vpblendd     ymm5,ymm3,ymm5,0aah            ;
  vpsrlq       ymm3,ymm3,020h                 ;
  vpblendd     ymm4,ymm3,ymm4,0aah            ;
  vmovsldup    ymm3,ymm11                     ;
  vpblendd     ymm3,ymm10,ymm3,0aah           ;
  vpsrlq       ymm10,ymm10,020h               ;
  vpblendd     ymm11,ymm10,ymm11,0aah         ;
  vmovdqa      ymmword ptr [rcx+0100h],ymm9   ; store permuted r[64..71]
  vmovdqa      ymmword ptr [rcx+0120h],ymm8   ; store permuted r[72..79]
  vmovdqa      ymmword ptr [rcx+0140h],ymm7   ; store permuted r[80..87]
  vmovdqa      ymmword ptr [rcx+0160h],ymm6   ; store permuted r[88..95]
  vmovdqa      ymmword ptr [rcx+0180h],ymm5   ; store permuted r[96..103]
  vmovdqa      ymmword ptr [rcx+01a0h],ymm4   ; store permuted r[104..111]
  vmovdqa      ymmword ptr [rcx+01c0h],ymm3   ; store permuted r[112..119]
  vmovdqa      ymmword ptr [rcx+01e0h],ymm11  ; store permuted r[120..127]

  ; Repeat same unpack/permutation kernel for r[128..191].
  vmovdqa      ymm4,ymmword ptr [rcx+0200h]   ; load r[128..135]
  vmovdqa      ymm5,ymmword ptr [rcx+0220h]   ; load r[136..143]
  vmovdqa      ymm6,ymmword ptr [rcx+0240h]   ; load r[144..151]
  vmovdqa      ymm7,ymmword ptr [rcx+0260h]   ; load r[152..159]
  vmovdqa      ymm8,ymmword ptr [rcx+0280h]   ; load r[160..167]
  vmovdqa      ymm9,ymmword ptr [rcx+02a0h]   ; load r[168..175]
  vmovdqa      ymm10,ymmword ptr [rcx+02c0h]  ; load r[176..183]
  vmovdqa      ymm11,ymmword ptr [rcx+02e0h]  ; load r[184..191]
  vperm2i128   ymm3,ymm4,ymm8,020h            ; phase 1: cross-lane half swap/combine
  vperm2i128   ymm8,ymm4,ymm8,031h            ;
  vperm2i128   ymm4,ymm5,ymm9,020h            ;
  vperm2i128   ymm9,ymm5,ymm9,031h            ;
  vperm2i128   ymm5,ymm6,ymm10,020h           ;
  vperm2i128   ymm10,ymm6,ymm10,031h          ;
  vperm2i128   ymm6,ymm7,ymm11,020h           ;
  vperm2i128   ymm11,ymm7,ymm11,031h          ;
  vpunpcklqdq  ymm7,ymm3,ymm5                 ;
  vpunpckhqdq  ymm5,ymm3,ymm5                 ;
  vpunpcklqdq  ymm3,ymm8,ymm10                ;
  vpunpckhqdq  ymm10,ymm8,ymm10               ;
  vpunpcklqdq  ymm8,ymm4,ymm6                 ;
  vpunpckhqdq  ymm6,ymm4,ymm6                 ;
  vpunpcklqdq  ymm4,ymm9,ymm11                ;
  vpunpckhqdq  ymm11,ymm9,ymm11               ;
  vmovsldup    ymm9,ymm8                      ; phase 3: 32-bit lane repack (same pattern)
  vpblendd     ymm9,ymm7,ymm9,0aah            ;
  vpsrlq       ymm7,ymm7,020h                 ;
  vpblendd     ymm8,ymm7,ymm8,0aah            ;
  vmovsldup    ymm7,ymm6                      ;
  vpblendd     ymm7,ymm5,ymm7,0aah            ;
  vpsrlq       ymm5,ymm5,020h                 ;
  vpblendd     ymm6,ymm5,ymm6,0aah            ;
  vmovsldup    ymm5,ymm4                      ;
  vpblendd     ymm5,ymm3,ymm5,0aah            ;
  vpsrlq       ymm3,ymm3,020h                 ;
  vpblendd     ymm4,ymm3,ymm4,0aah            ;
  vmovsldup    ymm3,ymm11                     ;
  vpblendd     ymm3,ymm10,ymm3,0aah           ;
  vpsrlq       ymm10,ymm10,020h               ;
  vpblendd     ymm11,ymm10,ymm11,0aah         ;
  vmovdqa      ymmword ptr [rcx+0200h],ymm9   ; store permuted r[128..135]
  vmovdqa      ymmword ptr [rcx+0220h],ymm8   ; store permuted r[136..143]
  vmovdqa      ymmword ptr [rcx+0240h],ymm7   ; store permuted r[144..151]
  vmovdqa      ymmword ptr [rcx+0260h],ymm6   ; store permuted r[152..159]
  vmovdqa      ymmword ptr [rcx+0280h],ymm5   ; store permuted r[160..167]
  vmovdqa      ymmword ptr [rcx+02a0h],ymm4   ; store permuted r[168..175]
  vmovdqa      ymmword ptr [rcx+02c0h],ymm3   ; store permuted r[176..183]
  vmovdqa      ymmword ptr [rcx+02e0h],ymm11  ; store permuted r[184..191]

  ; Repeat same unpack/permutation kernel for r[192..255].
  vmovdqa      ymm4,ymmword ptr [rcx+0300h]   ; load r[192..199]
  vmovdqa      ymm5,ymmword ptr [rcx+0320h]   ; load r[200..207]
  vmovdqa      ymm6,ymmword ptr [rcx+0340h]   ; load r[208..215]
  vmovdqa      ymm7,ymmword ptr [rcx+0360h]   ; load r[216..223]
  vmovdqa      ymm8,ymmword ptr [rcx+0380h]   ; load r[224..231]
  vmovdqa      ymm9,ymmword ptr [rcx+03a0h]   ; load r[232..239]
  vmovdqa      ymm10,ymmword ptr [rcx+03c0h]  ; load r[240..247]
  vmovdqa      ymm11,ymmword ptr [rcx+03e0h]  ; load r[248..255]
  vperm2i128   ymm3,ymm4,ymm8,020h            ; phase 1: cross-lane half swap/combine
  vperm2i128   ymm8,ymm4,ymm8,031h            ;
  vperm2i128   ymm4,ymm5,ymm9,020h            ;
  vperm2i128   ymm9,ymm5,ymm9,031h            ;
  vperm2i128   ymm5,ymm6,ymm10,020h           ;
  vperm2i128   ymm10,ymm6,ymm10,031h          ;
  vperm2i128   ymm6,ymm7,ymm11,020h           ;
  vperm2i128   ymm11,ymm7,ymm11,031h          ;
  vpunpcklqdq  ymm7,ymm3,ymm5                 ;
  vpunpckhqdq  ymm5,ymm3,ymm5                 ;
  vpunpcklqdq  ymm3,ymm8,ymm10                ;
  vpunpckhqdq  ymm10,ymm8,ymm10               ;
  vpunpcklqdq  ymm8,ymm4,ymm6                 ;
  vpunpckhqdq  ymm6,ymm4,ymm6                 ;
  vpunpcklqdq  ymm4,ymm9,ymm11                ;
  vpunpckhqdq  ymm11,ymm9,ymm11               ;
  vmovsldup    ymm9,ymm8                      ; phase 3: 32-bit lane repack (same pattern)
  vpblendd     ymm9,ymm7,ymm9,0aah            ;
  vpsrlq       ymm7,ymm7,020h                 ;
  vpblendd     ymm8,ymm7,ymm8,0aah            ;
  vmovsldup    ymm7,ymm6                      ;
  vpblendd     ymm7,ymm5,ymm7,0aah            ;
  vpsrlq       ymm5,ymm5,020h                 ;
  vpblendd     ymm6,ymm5,ymm6,0aah            ;
  vmovsldup    ymm5,ymm4                      ;
  vpblendd     ymm5,ymm3,ymm5,0aah            ;
  vpsrlq       ymm3,ymm3,020h                 ;
  vpblendd     ymm4,ymm3,ymm4,0aah            ;
  vmovsldup    ymm3,ymm11                     ;
  vpblendd     ymm3,ymm10,ymm3,0aah           ;
  vpsrlq       ymm10,ymm10,020h               ;
  vpblendd     ymm11,ymm10,ymm11,0aah         ;
  vmovdqa      ymmword ptr [rcx+0300h],ymm9   ; store permuted r[192..199]
  vmovdqa      ymmword ptr [rcx+0320h],ymm8   ; store permuted r[200..207]
  vmovdqa      ymmword ptr [rcx+0340h],ymm7   ; store permuted r[208..215]
  vmovdqa      ymmword ptr [rcx+0360h],ymm6   ; store permuted r[216..223]
  vmovdqa      ymmword ptr [rcx+0380h],ymm5   ; store permuted r[224..231]
  vmovdqa      ymmword ptr [rcx+03a0h],ymm4   ; store permuted r[232..239]
  vmovdqa      ymmword ptr [rcx+03c0h],ymm3   ; store permuted r[240..247]
  vmovdqa      ymmword ptr [rcx+03e0h],ymm11  ; store permuted r[248..255]

  ; Clear upper YMM state before returning to potential SSE caller code.
  vzeroupper                                  ; avoid AVX-SSE transition penalty

  vmovdqa       xmm6,xmmword ptr [rsp+000h]   ; restore xmm6 from stack
  vmovdqa       xmm7,xmmword ptr [rsp+010h]   ; restore xmm7 from stack
  vmovdqa       xmm8,xmmword ptr [rsp+020h]   ; restore xmm8 from stack
  vmovdqa       xmm9,xmmword ptr [rsp+030h]   ; restore xmm9 from stack
  vmovdqa       xmm10,xmmword ptr [rsp+040h]  ; restore xmm10 from stack
  vmovdqa       xmm11,xmmword ptr [rsp+050h]  ; restore xmm11 from stack

  add           rsp,068h                      ; restore stack pointer (matches prologue subtraction)

  ret                                         ; return with r unpacked/permuted in place

FUNC_NAME ENDP

  END
