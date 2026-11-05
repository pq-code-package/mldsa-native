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
; Name: rej_uniform_eta4_avx2_asm
; Description: x86_64 AVX2 rejection sampling of eta=4 secret coefficients.
;   Extracts 4-bit nibbles from the input byte buffer, accepts those < 9,
;   and maps an accepted nibble n to the coefficient 4 - n, producing
;   values in [-4, 4].
; Signature: unsigned mld_rej_uniform_eta4_avx2_asm(int32_t *r, const uint8_t *buf, const uint8_t table[256][8])
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
;     size_bytes: 272
;     permissions: read-only
;     c_parameter: const uint8_t *buf
;     description: Input byte buffer (MLD_AVX2_REJ_UNIFORM_ETA4_BUFLEN = 272)
;   r8:
;     type: buffer
;     size_bytes: 2048
;     permissions: read-only
;     c_parameter: const uint8_t *table
;     description: Lookup table (256 x 8 uint8_t = mld_rej_uniform_table)
;

IFNDEF FUNC_NAME
FUNC_NAME EQU mldsa_rej_uniform_eta4_avx2_asm
ENDIF

FUNC_NAME PROC FRAME

         .endprolog                                               ; leaf function: volatile registers only

         mov           r10d,0f0f0f0fh                             ;
         vmovd         xmm2,r10d                                  ;
         vpbroadcastd  ymm2,xmm2                                  ;
         mov           r10d,04040404h                             ;
         vmovd         xmm3,r10d                                  ;
         vpbroadcastd  ymm3,xmm3                                  ;
         mov           r10d,09090909h                             ;
         vmovd         xmm4,r10d                                  ;
         vpbroadcastd  ymm4,xmm4                                  ;
         xor           eax,eax                                    ;
         xor           r9d,r9d                                    ;

         ALIGN         16

Lmld_rej_uniform_eta4_avx2_asm_loop:

         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         cmp           r9d,0100h                                  ;
         ja            Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         vpmovzxbw     ymm0,xmmword ptr [rdx+r9*1]                ;
         vpsllw        ymm1,ymm0,04h                              ;
         vpor          ymm0,ymm0,ymm1                             ;
         vpand         ymm0,ymm0,ymm2                             ;
         vpsubb        ymm1,ymm0,ymm4                             ;
         vpsubb        ymm0,ymm3,ymm0                             ;
         vpmovmskb     r11d,ymm1                                  ;
         vextracti128  xmm5,ymm0,00h                              ;
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm5,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         vpsrldq       xmm5,xmm5,08h                              ;
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm5,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         vextracti128  xmm5,ymm0,01h                              ;
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm5,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         shr           r11d,08h                                   ;
         add           r9d,04h                                    ;
         cmp           eax,0f8h                                   ;
         ja            Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         vpsrldq       xmm5,xmm5,08h                              ;
         movzx         r10d,r11b                                  ; table index = low 8 mask bits
         vmovq         xmm1,qword ptr [r8+r10*8]                  ;
         vpshufb       xmm1,xmm5,xmm1                             ;
         vpmovsxbd     ymm1,xmm1                                  ;
         vmovdqu       ymmword ptr [rcx+rax*4],ymm1               ;
         popcnt        r10d,r10d                                  ;
         add           eax,r10d                                   ;
         add           r9d,04h                                    ;
         jmp           Lmld_rej_uniform_eta4_avx2_asm_loop        ;

         ALIGN         16

Lmld_rej_uniform_eta4_avx2_asm_scalar:
         cmp           eax,0100h                                  ;
         jae           Lmld_rej_uniform_eta4_avx2_asm_done        ;
         cmp           r9d,0110h                                  ;
         jae           Lmld_rej_uniform_eta4_avx2_asm_done        ;
         movzx         r11d,byte ptr [rdx+r9*1]                   ;
         inc           r9d                                        ;
         mov           r10d,r11d                                  ;
         and           r10d,0fh                                   ;
         cmp           r10d,09h                                   ;
         jae           Lmld_rej_uniform_eta4_avx2_asm_high_nibble ;
         neg           r10d                                       ;
         add           r10d,04h                                   ; 4 - nibble
         mov           dword ptr [rcx+rax*4],r10d                 ;
         inc           eax                                        ;
         cmp           eax,0100h                                  ;
         jae           Lmld_rej_uniform_eta4_avx2_asm_done        ;

         ALIGN         16

Lmld_rej_uniform_eta4_avx2_asm_high_nibble:

         shr           r11d,04h                                   ;
         and           r11d,0fh                                   ;
         cmp           r11d,09h                                   ;
         jae           Lmld_rej_uniform_eta4_avx2_asm_scalar      ;
         mov           r10d,04h                                   ;
         sub           r10d,r11d                                  ;
         mov           dword ptr [rcx+rax*4],r10d                 ;
         inc           eax                                        ;
         jmp           Lmld_rej_uniform_eta4_avx2_asm_scalar      ;

         ALIGN         16

Lmld_rej_uniform_eta4_avx2_asm_done:

         vzeroupper                                               ;
         ret                                                      ;

FUNC_NAME ENDP

         END
