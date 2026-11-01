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
; MASM (Microsoft Assembler) verdxon for MS Windows
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
; Name: rej_uniform_eta2_avx2_asm
; Description: x86_64 AVX2 rejection sampling of eta=2 secret coefficients.
;   Extracts 4-bit nibbles from the input byte buffer, accepts those < 15,
;   and maps an accepted nibble n to the coefficient 2 - (n mod 5) via a
;   centered modulo-5 reduction, producing values in [-2, 2].
; Signature: unsigned mld_rej_uniform_eta2_avx2_asm(int32_t *r, const uint8_t *buf, const uint8_t table[256][8])
; ABI:
;   Architecture: x86_64
;   CallingConvention: Microsoft AMD64 ABI
;   Features: [AVX2]
;   rcx:
;     type: buffer
;     size_bytes: 1024
;     permissions: write-only
;     c_parameter: int32_t *r
;     description: Output coefficient buffer (256 x int32_t)
;   rdx:
;     type: buffer
;     size_bytes: 136
;     permissions: read-only
;     c_parameter: const uint8_t *buf
;     description: Input byte buffer (MLD_AVX2_REJ_UNIFORM_ETA2_BUFLEN = 136)
;   r8:
;     type: buffer
;     size_bytes: 2048
;     permissions: read-only
;     c_parameter: const uint8_t *table
;     description: Lookup table (256 x 8 uint8_t = mld_rej_uniform_table)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_rej_uniform_eta2_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         sub           rsp,018h                                   ; 018h and not 010h for alignment purposes
         .allocstack   018h

         vmovdqa       xmmword ptr [rsp+000h],xmm6                ; save xmm6 on stack
         .savexmm128   xmm6,000h
         .endprolog

         mov           r10d,0f0f0f0fh                             ;
         vmovd         xmm3,r10d                                  ;
         vpbroadcastd  ymm3,xmm3                                  ;
         mov           r10d,02020202h                             ;
         vmovd         xmm4,r10d                                  ;
         vpbroadcastd  ymm4,xmm4                                  ;
         mov           r10d,0ffffe660h                            ;
         vpinsrw       xmm5,xmm5,r10d,00h                         ;
         vpbroadcastw  ymm5,xmm5                                  ;
         mov           r10d,05h                                   ;
         vpinsrw       xmm6,xmm6,r10d,00h                         ;
         vpbroadcastw  ymm6,xmm6                                  ;
         xor           eax,eax                                    ;
         xor           r9d,r9d                                    ;

         ALIGN         16

Lmld_rej_uniform_eta2_avx2_asm_loop:

         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         cmp           r9d,078h                                   ;
         ja            Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         vpmovzxbw     ymm0,xmmword ptr [rdx+r9*1]                ;
         vpsllw        ymm1,ymm0,04h                              ;
         vpor          ymm0,ymm0,ymm1                             ;
         vpand         ymm0,ymm0,ymm3                             ;
         vpsubb        ymm1,ymm0,ymm3                             ;
         vpsubb        ymm0,ymm4,ymm0                             ;
         vpmovmskb     r11d,ymm1                                  ;
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm0,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vpmulhrsw     ymm2,ymm1,ymm5                             ;
         vpmullw       ymm2,ymm2,ymm6                             ;
         vpaddd        ymm1,ymm1,ymm2                             ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         vpermq        ymm0,ymm0,039h                             ; rotate next qword into low lane
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm0,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vpmulhrsw     ymm2,ymm1,ymm5                             ;
         vpmullw       ymm2,ymm2,ymm6                             ;
         vpaddd        ymm1,ymm1,ymm2                             ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         vpermq        ymm0,ymm0,039h                             ; rotate next qword into low lane
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm0,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vpmulhrsw     ymm2,ymm1,ymm5                             ;
         vpmullw       ymm2,ymm2,ymm6                             ;
         vpaddd        ymm1,ymm1,ymm2                             ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         vpermq        ymm0,ymm0,039h                             ; rotate next qword into low lane
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm0,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vpmulhrsw     ymm2,ymm1,ymm5                             ;
         vpmullw       ymm2,ymm2,ymm6                             ;
         vpaddd        ymm1,ymm1,ymm2                             ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         add           r9d,04h                                    ;
         jmp           Lmld_rej_uniform_eta2_avx2_asm_loop        ;

         ALIGN         16

Lmld_rej_uniform_eta2_avx2_asm_scalar:
         cmp           eax,0100h                                  ;
         jae           Lmld_rej_uniform_eta2_avx2_asm_done        ;
         cmp           r9d,088h                                   ;
         jae           Lmld_rej_uniform_eta2_avx2_asm_done        ;
         movzx         r11d,byte ptr [rdx+r9*1]                   ;
         inc           r9d                                        ;
         mov           r10d,r11d                                  ;
         and           r10d,0fh                                   ;
         cmp           r10d,0fh                                   ;
         jae           Lmld_rej_uniform_eta2_avx2_asm_high_nibble ;
         mov           r11d,r10d                                  ;
         imul          r11d,r11d,0cdh                             ;
         shr           r11d,0ah                                   ;
         imul          r11d,r11d,05h                              ;
         sub           r10d,r11d                                  ;
         mov           r11d,02h                                   ;
         sub           r11d,r10d                                  ;
         mov           dword ptr [rcx+rax*4],r11d                 ;
         inc           eax                                        ;
         cmp           eax,0100h                                  ;
         jae           Lmld_rej_uniform_eta2_avx2_asm_done        ;

         align         16

Lmld_rej_uniform_eta2_avx2_asm_high_nibble:

         movzx         r11d,byte ptr [rdx+r9*1-01h]               ;
         shr           r11d,04h                                   ;
         and           r11d,0fh                                   ;
         cmp           r11d,0fh                                   ;
         jae           Lmld_rej_uniform_eta2_avx2_asm_scalar      ;
         mov           r10d,r11d                                  ;
         imul          r10d,r10d,0cdh                             ;
         shr           r10d,0ah                                   ;
         imul          r10d,r10d,05h                              ;
         sub           r11d,r10d                                  ;
         mov           r10d,02h                                   ;
         sub           r10d,r11d                                  ;
         mov           dword ptr [rcx+rax*4],r10d                 ;
         inc           eax                                        ;
         jmp           Lmld_rej_uniform_eta2_avx2_asm_scalar      ;

         align         16

Lmld_rej_uniform_eta2_avx2_asm_done:

         vzeroupper                                               ;

         vmovdqa       xmm6,xmmword ptr [rsp+000h]                ; restore xmm6 from stack

         add           rsp,018h                                   ;

         ret                                                      ;

FUNC_NAME ENDP

         END
