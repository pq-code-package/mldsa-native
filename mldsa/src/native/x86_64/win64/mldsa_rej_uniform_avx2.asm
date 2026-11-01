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
; Name: rej_uniform_avx2_asm
; Description: x86_64 AVX2 rejection sampling of uniform coefficients mod q.
;   Extract 23-bit values from the input byte buffer and accept those that are
;   < MLDSA_Q, writing accepted coefficients to the output buffer. Returns the
;   number of valid coefficients written (at most 256).
; Signature: unsigned mld_rej_uniform_avx2_asm(int32_t *r, const uint8_t buf[840], const uint8_t table[256][8])
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t *r
;     description: Output buffer (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 840
;     permissions: read-only
;     c_parameter: const uint8_t buf[840]
;     description: Input buffer (MLD_POLY_UNIFORM_NBLOCKS * SHAKE128_RATE = 5 * 168)
;   r8:
;     type: buffer
;     size_bytes: 2048
;     permissions: read-only
;     c_parameter: const uint8_t table[256][8]
;     description: Lookup table (256 x 8 x uint8_t)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_rej_uniform_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         .endprolog                                     ; .pushreg rbx optimized out by Claude, see below

         mov           r10,0ff050403ff020100h           ;
         vmovq         xmm0,r10                         ;
         mov           r10,0ff0b0a09ff080706h           ;
         vpinsrq       xmm0,xmm0,r10,01h                ;
         mov           r10,0ff090807ff060504h           ;
         vmovq         xmm3,r10                         ;
         mov           r10,0ff0f0e0dff0c0b0ah           ;
         vpinsrq       xmm3,xmm3,r10,01h                ;
         vinserti128   ymm0,ymm0,xmm3,01h               ;
         mov           r9d,07fffffh                     ; Claude optimization: ebx by r9d
         vmovd         xmm1,r9d                         ;
         vpbroadcastd  ymm1,xmm1                        ;
         mov           r9d,07fe001h                     ;
         vmovd         xmm2,r9d                         ;
         vpbroadcastd  ymm2,xmm2                        ;
         xor           eax,eax                          ;
         xor           r11d,r11d                        ;

         ALIGN         16

Lmld_rej_uniform_avx2_asm_loop:

         cmp           eax,0f8h                         ;
         ja            Lmld_rej_uniform_avx2_asm_scalar ;
         cmp           r11d,0328h                       ;
         ja            Lmld_rej_uniform_avx2_asm_scalar ;
         vmovdqu       ymm3,ymmword ptr [rdx+r11*1]     ;
         add           r11d,018h                        ;
         vpermq        ymm3,ymm3,094h                   ;
         vpshufb       ymm3,ymm3,ymm0                   ;
         vpand         ymm3,ymm3,ymm1                   ;
         vpsubd        ymm4,ymm3,ymm2                   ;
         vmovmskps     r10d,ymm4                        ; Claude optimization: ebx -> r10d
         popcnt        r9d,r10d                         ; Claude optimization: ebx -> r10d
         vmovq         xmm4,qword ptr [r8+r10*8]        ; Claude optimization: ebx -> r10 (vmovmskps zero-extends r10d)
         vpmovzxbd     ymm4,xmm4                        ;
         vpermd        ymm3,ymm4,ymm3                   ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm3     ;
         add           eax,r9d                          ;
         jmp           Lmld_rej_uniform_avx2_asm_loop   ;

         ALIGN         16

Lmld_rej_uniform_avx2_asm_scalar:

         cmp           eax,0100h                        ;
         jae           Lmld_rej_uniform_avx2_asm_done   ;
         cmp           r11d,0345h                       ;
         ja            Lmld_rej_uniform_avx2_asm_done   ;
         movzx         r10d,word ptr [rdx+r11*1]        ;
         movzx         r9d,byte ptr [rdx+r11*1+02h]     ;
         shl           r9d,010h                         ;
         or            r10d,r9d                         ;
         and           r10d,07fffffh                    ; Claude optimization: ebx -> r10d
         add           r11d,03h                         ;
         cmp           r10d,07fe001h                    ;
         jae           Lmld_rej_uniform_avx2_asm_scalar ;
         mov           dword ptr [rcx+rax*4],r10d       ;
         add           eax,01h                          ;
         jmp           Lmld_rej_uniform_avx2_asm_scalar ;

         ALIGN         16

Lmld_rej_uniform_avx2_asm_done:

         vzeroupper                                     ;
         ret                                            ;

FUNC_NAME ENDP

         END
