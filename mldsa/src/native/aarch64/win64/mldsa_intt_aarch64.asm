;
; Copyright (c) 2022 Arm Limited
; Copyright(c) 2022 Hanno Becker
; Copyright (c) 2023 Amin Abdulrahman, Matthias Kannwischer
; Copyright (c) The mlkem-native project authors
; Copyright (c) The mldsa-native project authors
; SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
;

;  References
;  ==========
;
;  - [NeonNTT]
;    Neon NTT: Faster Dilithium, Kyber, and Saber on Cortex-A72 and Apple M1
;    Becker, Hwang, Kannwischer, Yang, Yang
;    https://eprint.iacr.org/2021/986
;
;  - [NeonNTT_Autoformalised]
;    Neon NTT - (Auto)formalised
;    Hanno Becker
;    https://eprint.iacr.org/2026/1223
;
;  - [SLOTHY_Paper]
;    Fast and Clean: Auditable high-performance assembly via constraint solving
;    Abdulrahman, Becker, Kannwischer, Klein
;    https://eprint.iacr.org/2022/1303
;
; Windows ARM64 port:
; 'armasm64.exe' re-formatting and SEH unwind information provided by
; Ingo A. Kubbilun <ingo.kubbilun@gmail.com>, Oct. 2026
;
; with contributions from Github Copilot (Claude Sonnet 4.6) providing
; ARM64 assembly comments
;

; yaml
; Name: intt_aarch64_asm
; Description: AArch64 ML-DSA inverse NTT
; Signature: void mld_intt_aarch64_asm(int32_t r[256], const int32_t zetas_l78[384], const int32_t zetas_l123456[160])
; ABI:
;   Architecture: aarch64
;   CallingConvention: AAPCS64
;   Features: [NEON]
;   x0:
;     type: buffer
;     size_bytes: 1024
;     permissions: read/write
;     c_parameter: int32_t r[256]
;     description: Input/output polynomial (256 x int32_t)
;   x1:
;     type: buffer
;     size_bytes: 1536
;     permissions: read-only
;     c_parameter: const int32_t zetas_l78[384]
;     description: Twiddle factors for layers 7-8 (384 x int32_t)
;   x2:
;     type: buffer
;     size_bytes: 640
;     permissions: read-only
;     c_parameter: const int32_t zetas_l123456[160]
;     description: Twiddle factors for layers 1-6 (160 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_intt_aarch64_asm"
        ENDIF

        AREA      |.drectve|, DRECTVE

        EXPORT    $FUNC_NAME

        AREA      |.text|, CODE, ARM64, READONLY, ALIGN=4

        ALIGN     16

$FUNC_NAME PROC

        ; ---------------------------------------------------------------------------
        ; Prologue  --  allocate stack frame and save callee-saved FP registers
        ;
        ;   AAPCS64 requires d8-d15 to be preserved across calls.
        ;   We reserve 0x40 bytes (8 x 8 bytes) at [sp+0x00]..[sp+0x38].
        ;
        ;   Register map (entire function):
        ;     x0        : pointer into r[] (advances during Phase 2; restored below)
        ;     x3        : saved base of r[] (set to x0 in prologue; never modified)
        ;     x1        : pointer into zetas_l78[]     (Phase 1, auto-incremented)
        ;     x2        : pointer into zetas_l123456[] (Phase 2, auto-incremented)
        ;     x4        : loop counter
        ;     w5        : scratch for immediate constant construction
        ;     v31.4s    : broadcast of Montgomery modulus  q = 0x007fe001 (8380417)
        ;     v29.4s    : (Phase 2) n^{-1}*R mod q = 0x3ffe  -- final-scaling multiplier
        ;     v30.4s    : (Phase 2) n^{-1}*R*q^{-1} related = 0x00400e03
        ;     v0-v7     : (Phase 2) zeta-vector block loaded from x2
        ;     v0-v17    : (Phase 1) twiddle factor vectors from x1
        ;     v8-v30    : coefficient working registers
        ;
        ;   NOTE: the INTT processes layers in REVERSE order compared to the NTT:
        ;     Phase 1: layer 8 -> 7 -> 6 -> 5  (using zetas_l78,    pointer x1)
        ;     Phase 2: layer 4 -> 3 -> 2 -> 1  (using zetas_l123456, pointer x2)
        ;   The bit-reversal un-transpose (trn1/trn2 sequences) at the start of
        ;   each group converts from bit-reversed storage order back to natural order.
        ; ---------------------------------------------------------------------------
        ; .cfi_startproc
        sub       sp, sp, #0x40                           ; 0x00000000, line   30
        ; .cfi_adjust_cfa_offset 0x40
        stp       d8, d9, [sp]                            ; 0x00000004, line   32  save d8,d9   at [sp+0x00]
        ; .cfi_rel_offset d8, 0x0
        ; .cfi_rel_offset d9, 0x8
        stp       d10, d11, [sp, #0x10]                   ; 0x00000008, line   35  save d10,d11 at [sp+0x10]
        ; .cfi_rel_offset d10, 0x10
        ; .cfi_rel_offset d11, 0x18
        stp       d12, d13, [sp, #0x20]                   ; 0x0000000C, line   38  save d12,d13 at [sp+0x20]
        ; .cfi_rel_offset d12, 0x20
        ; .cfi_rel_offset d13, 0x28
        stp       d14, d15, [sp, #0x30]                   ; 0x00000010, line   41  save d14,d15 at [sp+0x30]
        ; .cfi_rel_offset d14, 0x30
        ; .cfi_rel_offset d15, 0x38

        ; ---------------------------------------------------------------------------
        ; Build and broadcast the Montgomery reduction constant
        ;
        ;   q = MLDSA_Q = 8 380 417 = 0x007F_E001
        ;   Montgomery multiplication pattern (used throughout both phases):
        ;     (1)  mul      vD.4s, vA.4s, vB.4s/s[i]   ; low 32-bit product
        ;     (2)  sqrdmulh vE.4s, vA.4s, vB.4s/s[j]   ; rounded doubling high half
        ;     (3)  mls      vD.4s, vE.4s, v31.s[0]     ; vD -= vE * q  (reduce mod q)
        ;   After step (3), vD holds the fully-reduced Montgomery product.
        ;   v31.4s is kept constant throughout the entire function.
        ; ---------------------------------------------------------------------------
        mov       w5, #0xe001                             ; 0x00000014, line   44  w5[15:0]  = 0xe001
        movk      w5, #0x7f, lsl #16                      ; 0x00000018, line   45  w5[30:16] = 0x7f => w5 = 0x007fe001 = q
        dup       v31.4s, w5                              ; 0x0000001C, line   46  v31.4s = {q,q,q,q}
        mov       x3, x0                                  ; 0x00000020, line   47  x3 = &r[0] (saved base; never modified)
        mov       x4, #0x10                               ; 0x00000024, line   48  x4 = 16 (Phase 1 loop count)
        ; ---------------------------------------------------------------------------
        ; Phase 1 pre-loop  --  first two groups of layer 8->5 butterflies
        ;
        ;   Coefficient groups are stored in bit-reversed NTT order.
        ;   The INTT first un-transposes them using trn1/trn2 before applying
        ;   the inverse butterfly.  A 4x4 un-transpose uses four instructions:
        ;     trn1/trn2 vA.4s, vB.4s, vC.4s  -- un-interleave within 64-bit lanes
        ;     trn1/trn2 vA.2d, vB.2d, vC.2d  -- un-interleave 64-bit lane pairs
        ;
        ;   After un-transpose, each vector holds four adjacent coefficients in
        ;   natural order, ready for inverse butterfly computation.
        ;
        ;   Twiddle factors for layers 7-8 come from x1 (zetas_l78[]).
        ;   Each group consumes 0x60 bytes (24 x int32_t) from x1.
        ;     Full vectors (128-bit): used for layer-8 butterflies
        ;     64-bit scalars (ldr d): used for layer-5/6 scalar butterflies
        ;
        ;   This pre-loop processes 2 coefficient groups (32 coefficients each)
        ;   before entering Lmld_intt_layer5678_start.
        ; ---------------------------------------------------------------------------
        ldr       q27, [x3, #0x10]                        ; 0x00000028, line   49
        ldr       q18, [x3]                               ; 0x0000002C, line   50
        ldr       q3, [x3, #0x20]                         ; 0x00000030, line   51
        ldr       q13, [x3, #0x30]                        ; 0x00000034, line   52
        ldr       q2, [x1, #0x30]                         ; 0x00000038, line   53  load layer-8 zetas
        ldr       q8, [x3, #0x70]                         ; 0x0000003C, line   54
        ldr       q21, [x3, #0x60]                        ; 0x00000040, line   55
        trn1      v10.4s, v18.4s, v27.4s                  ; 0x00000044, line   56  un-transpose: interleave even lanes
        trn2      v23.4s, v18.4s, v27.4s                  ; 0x00000048, line   57
        trn1      v6.4s, v3.4s, v13.4s                    ; 0x0000004C, line   58
        trn2      v18.4s, v3.4s, v13.4s                   ; 0x00000050, line   59
        ldr       q12, [x1, #0x50]                        ; 0x00000054, line   60
        ldr       q17, [x1, #0x40]                        ; 0x00000058, line   61
        trn2      v29.2d, v10.2d, v6.2d                   ; 0x0000005C, line   62
        trn2      v14.2d, v23.2d, v18.2d                  ; 0x00000060, line   63
        trn1      v10.2d, v10.2d, v6.2d                   ; 0x00000064, line   64
        trn1      v26.2d, v23.2d, v18.2d                  ; 0x00000068, line   65
        sub       v3.4s, v29.4s, v14.4s                   ; 0x0000006C, line   66
        trn1      v13.4s, v21.4s, v8.4s                   ; 0x00000070, line   67
        ldr       q6, [x1, #0x10]                         ; 0x00000074, line   68
        add       v24.4s, v10.4s, v26.4s                  ; 0x00000078, line   69
        sub       v30.4s, v10.4s, v26.4s                  ; 0x0000007C, line   70
        sqrdmulh  v12.4s, v3.4s, v12.4s                   ; 0x00000080, line   71
        ldr       q9, [x1, #0x20]                         ; 0x00000084, line   72
        sqrdmulh  v5.4s, v30.4s, v2.4s                    ; 0x00000088, line   73
        mul       v4.4s, v3.4s, v17.4s                    ; 0x0000008C, line   74
        ldr       q3, [x3, #0x50]                         ; 0x00000090, line   75
        add       v10.4s, v29.4s, v14.4s                  ; 0x00000094, line   76
        ldr       q26, [x3, #0x40]                        ; 0x00000098, line   77
        mul       v15.4s, v30.4s, v9.4s                   ; 0x0000009C, line   78
        trn2      v30.4s, v21.4s, v8.4s                   ; 0x000000A0, line   79
        sub       v21.4s, v24.4s, v10.4s                  ; 0x000000A4, line   80
        add       v29.4s, v24.4s, v10.4s                  ; 0x000000A8, line   81
        mls       v15.4s, v5.4s, v31.s[0]                 ; 0x000000AC, line   82
        ldr       q16, [x1], #0x60                        ; 0x000000B0, line   83
        trn2      v10.4s, v26.4s, v3.4s                   ; 0x000000B4, line   84
        mls       v4.4s, v12.4s, v31.s[0]                 ; 0x000000B8, line   85
        trn1      v3.4s, v26.4s, v3.4s                    ; 0x000000BC, line   86
        ldr       q0, [x1, #0x50]                         ; 0x000000C0, line   87
        trn2      v25.2d, v10.2d, v30.2d                  ; 0x000000C4, line   88
        sqrdmulh  v12.4s, v21.4s, v6.4s                   ; 0x000000C8, line   89
        trn2      v1.2d, v3.2d, v13.2d                    ; 0x000000CC, line   90
        mul       v21.4s, v21.4s, v16.4s                  ; 0x000000D0, line   91
        sub       v23.4s, v1.4s, v25.4s                   ; 0x000000D4, line   92
        sub       v2.4s, v15.4s, v4.4s                    ; 0x000000D8, line   93
        add       v20.4s, v15.4s, v4.4s                   ; 0x000000DC, line   94
        sqrdmulh  v4.4s, v23.4s, v0.4s                    ; 0x000000E0, line   95
        trn1      v7.2d, v3.2d, v13.2d                    ; 0x000000E4, line   96
        sqrdmulh  v3.4s, v2.4s, v6.4s                     ; 0x000000E8, line   97
        trn1      v15.2d, v10.2d, v30.2d                  ; 0x000000EC, line   98
        mls       v21.4s, v12.4s, v31.s[0]                ; 0x000000F0, line   99
        ldr       q12, [x1, #0x30]                        ; 0x000000F4, line  100
        sub       v13.4s, v7.4s, v15.4s                   ; 0x000000F8, line  101
        mul       v10.4s, v2.4s, v16.4s                   ; 0x000000FC, line  102
        ldr       q16, [x1, #0x40]                        ; 0x00000100, line  103
        ldr       q5, [x1, #0x20]                         ; 0x00000104, line  104
        mls       v10.4s, v3.4s, v31.s[0]                 ; 0x00000108, line  105
        trn2      v11.4s, v29.4s, v20.4s                  ; 0x0000010C, line  106
        sqrdmulh  v2.4s, v13.4s, v12.4s                   ; 0x00000110, line  107
        ldr       d9, [x2], #0x20                         ; 0x00000114, line  108  load 64-bit scalar pair (2 x int32_t) for layers 5-6
        mul       v17.4s, v13.4s, v5.4s                   ; 0x00000118, line  109
        trn1      v24.4s, v29.4s, v20.4s                  ; 0x0000011C, line  110
        trn1      v12.4s, v21.4s, v10.4s                  ; 0x00000120, line  111
        trn2      v10.4s, v21.4s, v10.4s                  ; 0x00000124, line  112
        mul       v22.4s, v23.4s, v16.4s                  ; 0x00000128, line  113
        ldur      q26, [x2, #-0x10]                       ; 0x0000012C, line  114
        trn1      v13.2d, v24.2d, v12.2d                  ; 0x00000130, line  115
        trn1      v3.2d, v11.2d, v10.2d                   ; 0x00000134, line  116
        mls       v17.4s, v2.4s, v31.s[0]                 ; 0x00000138, line  117
        mls       v22.4s, v4.4s, v31.s[0]                 ; 0x0000013C, line  118
        sub       v23.4s, v13.4s, v3.4s                   ; 0x00000140, line  119
        trn2      v10.2d, v11.2d, v10.2d                  ; 0x00000144, line  120
        sqrdmulh  v0.4s, v23.4s, v26.s[1]                 ; 0x00000148, line  121
        trn2      v21.2d, v24.2d, v12.2d                  ; 0x0000014C, line  122
        mul       v29.4s, v23.4s, v26.s[0]                ; 0x00000150, line  123
        sub       v23.4s, v21.4s, v10.4s                  ; 0x00000154, line  124
        sqrdmulh  v8.4s, v23.4s, v26.s[3]                 ; 0x00000158, line  125
        add       v6.4s, v1.4s, v25.4s                    ; 0x0000015C, line  126
        add       v11.4s, v21.4s, v10.4s                  ; 0x00000160, line  127
        mls       v29.4s, v0.4s, v31.s[0]                 ; 0x00000164, line  128
        add       v30.4s, v13.4s, v3.4s                   ; 0x00000168, line  129
        ldr       q2, [x1, #0x10]                         ; 0x0000016C, line  130
        mul       v3.4s, v23.4s, v26.s[2]                 ; 0x00000170, line  131
        add       v12.4s, v7.4s, v15.4s                   ; 0x00000174, line  132
        mls       v3.4s, v8.4s, v31.s[0]                  ; 0x00000178, line  133
        sub       v13.4s, v30.4s, v11.4s                  ; 0x0000017C, line  134
        sub       v21.4s, v12.4s, v6.4s                   ; 0x00000180, line  135
        add       v26.4s, v17.4s, v22.4s                  ; 0x00000184, line  136
        sqrdmulh  v28.4s, v13.4s, v9.s[1]                 ; 0x00000188, line  137
        mul       v18.4s, v13.4s, v9.s[0]                 ; 0x0000018C, line  138
        sub       v8.4s, v29.4s, v3.4s                    ; 0x00000190, line  139
        sqrdmulh  v24.4s, v21.4s, v2.4s                   ; 0x00000194, line  140
        add       v15.4s, v30.4s, v11.4s                  ; 0x00000198, line  141
        add       v10.4s, v29.4s, v3.4s                   ; 0x0000019C, line  142
        add       v14.4s, v12.4s, v6.4s                   ; 0x000001A0, line  143
        sqrdmulh  v16.4s, v8.4s, v9.s[1]                  ; 0x000001A4, line  144
        sub       v3.4s, v17.4s, v22.4s                   ; 0x000001A8, line  145
        mul       v8.4s, v8.4s, v9.s[0]                   ; 0x000001AC, line  146
        ldr       q17, [x1], #0x60                        ; 0x000001B0, line  147
        sub       x4, x4, #0x2                            ; 0x000001B4, line  148  x4 -= 2 (two groups already processed above)
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

        ; ---------------------------------------------------------------------------
        ; Layer 8->5 main loop  (Lmld_intt_layer5678_start)
        ;
        ;   Iterates x4 times (14 after the pre-loop decrement above).
        ;   Each iteration processes one 32-coefficient group (8 NEON vectors):
        ;
        ;   (a) Load 8 consecutive coefficients from x3 (auto-advanced by 0x40/iter)
        ;   (b) Un-transpose via trn1/trn2 (4-step 4x4 matrix un-transpose)
        ;       to recover natural-order adjacency from bit-reversed storage
        ;   (c) Layer 8 inverse butterfly: sub/add + Montgomery multiply by zeta
        ;   (d) Layer 7 inverse butterfly: same pattern, different zetas
        ;   (e) Layer 6 and 5 inverse butterflies using 64-bit scalar zetas
        ;       loaded with `ldr d, [x2], #0x20` (2 x int32_t per scalar load)
        ;   (f) Store completed results back to x3 (interspersed with above)
        ;
        ;   x1 is auto-incremented by 0x60 (24 x int32_t) per iteration.
        ;   x2 is auto-incremented by 0x20 ( 8 x int32_t) per iteration.
        ;   x3 is auto-incremented by 0x40 (16 x int32_t) per iteration.
        ; ---------------------------------------------------------------------------
Lmld_intt_layer5678_start

        ldr       d4, [x2], #0x20                         ; 0x000001C0, line  151  load 64-bit scalar pair (2 x int32_t) for layers 5-6
        mul       v0.4s, v21.4s, v17.4s                   ; 0x000001C4, line  152
        ldr       q7, [x3, #0xa0]                         ; 0x000001C8, line  153
        ldr       q27, [x3, #0xb0]                        ; 0x000001CC, line  154
        mls       v8.4s, v16.4s, v31.s[0]                 ; 0x000001D0, line  155
        ldr       q29, [x3, #0x80]                        ; 0x000001D4, line  156
        trn1      v9.4s, v14.4s, v26.4s                   ; 0x000001D8, line  157
        ldr       q25, [x3, #0x90]                        ; 0x000001DC, line  158
        mls       v0.4s, v24.4s, v31.s[0]                 ; 0x000001E0, line  159
        str       q15, [x3], #0x40                        ; 0x000001E4, line  160
        trn1      v1.4s, v7.4s, v27.4s                    ; 0x000001E8, line  161
        ldr       q15, [x1, #0x50]                        ; 0x000001EC, line  162
        trn2      v12.4s, v7.4s, v27.4s                   ; 0x000001F0, line  163
        sqrdmulh  v16.4s, v3.4s, v2.4s                    ; 0x000001F4, line  164
        trn1      v21.4s, v29.4s, v25.4s                  ; 0x000001F8, line  165
        stur      q8, [x3, #-0x10]                        ; 0x000001FC, line  166
        trn2      v19.4s, v29.4s, v25.4s                  ; 0x00000200, line  167
        mls       v18.4s, v28.4s, v31.s[0]                ; 0x00000204, line  168
        ldr       q22, [x1, #0x30]                        ; 0x00000208, line  169
        trn2      v13.2d, v21.2d, v1.2d                   ; 0x0000020C, line  170
        trn2      v5.2d, v19.2d, v12.2d                   ; 0x00000210, line  171
        mul       v23.4s, v3.4s, v17.4s                   ; 0x00000214, line  172
        trn1      v17.2d, v21.2d, v1.2d                   ; 0x00000218, line  173
        ldr       q29, [x1, #0x40]                        ; 0x0000021C, line  174
        mls       v23.4s, v16.4s, v31.s[0]                ; 0x00000220, line  175
        sub       v30.4s, v13.4s, v5.4s                   ; 0x00000224, line  176
        trn1      v24.2d, v19.2d, v12.2d                  ; 0x00000228, line  177
        stur      q10, [x3, #-0x30]                       ; 0x0000022C, line  178
        sqrdmulh  v16.4s, v30.4s, v15.4s                  ; 0x00000230, line  179
        ldr       q10, [x1, #0x20]                        ; 0x00000234, line  180
        trn2      v12.4s, v14.4s, v26.4s                  ; 0x00000238, line  181
        stur      q18, [x3, #-0x20]                       ; 0x0000023C, line  182
        mul       v11.4s, v30.4s, v29.4s                  ; 0x00000240, line  183
        sub       v8.4s, v17.4s, v24.4s                   ; 0x00000244, line  184
        trn1      v20.4s, v0.4s, v23.4s                   ; 0x00000248, line  185
        ldr       q2, [x1, #0x10]                         ; 0x0000024C, line  186
        trn2      v26.4s, v0.4s, v23.4s                   ; 0x00000250, line  187
        sqrdmulh  v19.4s, v8.4s, v22.4s                   ; 0x00000254, line  188
        ldur      q14, [x2, #-0x10]                       ; 0x00000258, line  189
        trn1      v21.2d, v9.2d, v20.2d                   ; 0x0000025C, line  190
        mul       v8.4s, v8.4s, v10.4s                    ; 0x00000260, line  191
        trn1      v6.2d, v12.2d, v26.2d                   ; 0x00000264, line  192
        trn2      v0.2d, v9.2d, v20.2d                    ; 0x00000268, line  193
        mls       v11.4s, v16.4s, v31.s[0]                ; 0x0000026C, line  194
        sub       v7.4s, v21.4s, v6.4s                    ; 0x00000270, line  195
        trn2      v28.2d, v12.2d, v26.2d                  ; 0x00000274, line  196
        add       v10.4s, v21.4s, v6.4s                   ; 0x00000278, line  197
        mul       v18.4s, v7.4s, v14.s[0]                 ; 0x0000027C, line  198
        add       v20.4s, v13.4s, v5.4s                   ; 0x00000280, line  199
        sqrdmulh  v30.4s, v7.4s, v14.s[1]                 ; 0x00000284, line  200
        sub       v21.4s, v0.4s, v28.4s                   ; 0x00000288, line  201
        add       v13.4s, v0.4s, v28.4s                   ; 0x0000028C, line  202
        add       v9.4s, v17.4s, v24.4s                   ; 0x00000290, line  203
        sqrdmulh  v1.4s, v21.4s, v14.s[3]                 ; 0x00000294, line  204
        ldr       q17, [x1], #0x60                        ; 0x00000298, line  205
        mul       v14.4s, v21.4s, v14.s[2]                ; 0x0000029C, line  206
        sub       v21.4s, v9.4s, v20.4s                   ; 0x000002A0, line  207
        mls       v18.4s, v30.4s, v31.s[0]                ; 0x000002A4, line  208
        mls       v14.4s, v1.4s, v31.s[0]                 ; 0x000002A8, line  209
        mls       v8.4s, v19.4s, v31.s[0]                 ; 0x000002AC, line  210
        sub       v3.4s, v10.4s, v13.4s                   ; 0x000002B0, line  211
        add       v15.4s, v10.4s, v13.4s                  ; 0x000002B4, line  212
        sqrdmulh  v28.4s, v3.4s, v4.s[1]                  ; 0x000002B8, line  213
        add       v10.4s, v18.4s, v14.4s                  ; 0x000002BC, line  214
        sub       v19.4s, v18.4s, v14.4s                  ; 0x000002C0, line  215
        mul       v18.4s, v3.4s, v4.s[0]                  ; 0x000002C4, line  216
        sub       v3.4s, v8.4s, v11.4s                    ; 0x000002C8, line  217
        add       v26.4s, v8.4s, v11.4s                   ; 0x000002CC, line  218
        sqrdmulh  v16.4s, v19.4s, v4.s[1]                 ; 0x000002D0, line  219
        add       v14.4s, v9.4s, v20.4s                   ; 0x000002D4, line  220
        mul       v8.4s, v19.4s, v4.s[0]                  ; 0x000002D8, line  221
        sqrdmulh  v24.4s, v21.4s, v2.4s                   ; 0x000002DC, line  222
        subs      x4, x4, #0x1                            ; 0x000002E0, line  223  decrement loop counter
        cbnz      x4, Lmld_intt_layer5678_start           ; 0x000002E4, line  224  branch if x4 != 0

        ; ---------------------------------------------------------------------------
        ; Layer 8->5 post-loop tail  --  finalize last group, flush remaining stores
        ;
        ;   Completes the final Montgomery multiplications and trn1/trn2 un-transpose
        ;   for the last coefficient group, then writes all 32 results to x3.
        ;   After these stores, all 256 coefficients have been processed by layers
        ;   8 through 5.  Execution continues with Phase 2 setup (layers 4->1).
        ; ---------------------------------------------------------------------------
        sqrdmulh  v19.4s, v3.4s, v2.4s                    ; 0x000002E8, line  225
        trn2      v0.4s, v14.4s, v26.4s                   ; 0x000002EC, line  226
        str       q15, [x3], #0x40                        ; 0x000002F0, line  227
        trn1      v30.4s, v14.4s, v26.4s                  ; 0x000002F4, line  228
        mul       v26.4s, v21.4s, v17.4s                  ; 0x000002F8, line  229
        stur      q10, [x3, #-0x30]                       ; 0x000002FC, line  230
        ldr       d29, [x2], #0x20                        ; 0x00000300, line  231
        mls       v26.4s, v24.4s, v31.s[0]                ; 0x00000304, line  232
        mul       v10.4s, v3.4s, v17.4s                   ; 0x00000308, line  233
        ldur      q14, [x2, #-0x10]                       ; 0x0000030C, line  234
        mls       v10.4s, v19.4s, v31.s[0]                ; 0x00000310, line  235
        mls       v8.4s, v16.4s, v31.s[0]                 ; 0x00000314, line  236
        trn2      v22.4s, v26.4s, v10.4s                  ; 0x00000318, line  237
        trn1      v25.4s, v26.4s, v10.4s                  ; 0x0000031C, line  238
        trn1      v1.2d, v30.2d, v25.2d                   ; 0x00000320, line  239
        trn1      v2.2d, v0.2d, v22.2d                    ; 0x00000324, line  240
        trn2      v13.2d, v30.2d, v25.2d                  ; 0x00000328, line  241
        trn2      v7.2d, v0.2d, v22.2d                    ; 0x0000032C, line  242
        mls       v18.4s, v28.4s, v31.s[0]                ; 0x00000330, line  243
        sub       v22.4s, v1.4s, v2.4s                    ; 0x00000334, line  244
        add       v3.4s, v13.4s, v7.4s                    ; 0x00000338, line  245
        sqrdmulh  v27.4s, v22.4s, v14.s[1]                ; 0x0000033C, line  246
        sub       v4.4s, v13.4s, v7.4s                    ; 0x00000340, line  247
        stur      q8, [x3, #-0x10]                        ; 0x00000344, line  248
        sqrdmulh  v0.4s, v4.4s, v14.s[3]                  ; 0x00000348, line  249
        add       v16.4s, v1.4s, v2.4s                    ; 0x0000034C, line  250
        stur      q18, [x3, #-0x20]                       ; 0x00000350, line  251
        mul       v23.4s, v4.4s, v14.s[2]                 ; 0x00000354, line  252
        add       v4.4s, v16.4s, v3.4s                    ; 0x00000358, line  253
        sub       v17.4s, v16.4s, v3.4s                   ; 0x0000035C, line  254
        mul       v14.4s, v22.4s, v14.s[0]                ; 0x00000360, line  255
        str       q4, [x3], #0x40                         ; 0x00000364, line  256
        mls       v23.4s, v0.4s, v31.s[0]                 ; 0x00000368, line  257
        mls       v14.4s, v27.4s, v31.s[0]                ; 0x0000036C, line  258
        mul       v11.4s, v17.4s, v29.s[0]                ; 0x00000370, line  259
        sqrdmulh  v10.4s, v17.4s, v29.s[1]                ; 0x00000374, line  260
        sub       v0.4s, v14.4s, v23.4s                   ; 0x00000378, line  261
        add       v6.4s, v14.4s, v23.4s                   ; 0x0000037C, line  262
        sqrdmulh  v12.4s, v0.4s, v29.s[1]                 ; 0x00000380, line  263
        mul       v0.4s, v0.4s, v29.s[0]                  ; 0x00000384, line  264
        stur      q6, [x3, #-0x30]                        ; 0x00000388, line  265
        mls       v11.4s, v10.4s, v31.s[0]                ; 0x0000038C, line  266
        mls       v0.4s, v12.4s, v31.s[0]                 ; 0x00000390, line  267
        stur      q11, [x3, #-0x20]                       ; 0x00000394, line  268
        stur      q0, [x3, #-0x10]                        ; 0x00000398, line  269
        ; ---------------------------------------------------------------------------
        ; Phase 2 setup  --  build normalization constants and begin layers 4->1
        ;
        ;   After the INTT butterfly layers 8->5, all coefficients must be scaled
        ;   by n^{-1} mod q where n = 256 = number of polynomial coefficients.
        ;   This is folded into layers 4->1 as a Montgomery multiplication by a
        ;   combined constant f = n^{-1} * R mod q, applied once per layer-1 output.
        ;
        ;   v29.4s = 0x00003ffe  -- n^{-1} * R (low part) for final butterfly output
        ;   v30.4s = 0x00400e03  -- complementary constant (high part / correction)
        ;
        ;   Twiddle factors for layers 4->1 are loaded from x2 (zetas_l123456[]).
        ;   x2 was already advanced through Phase 1; it now points to the remaining
        ;   layer-1..4 zeta values.
        ;
        ;   x0 is used (not x3) for coefficient addressing in Phase 2; it starts
        ;   at &r[0] (same as x3 but x0 has been reset by Phase 1 operations).
        ;   x4 = 4 (four groups of 64 coefficients for layers 4->1).
        ;
        ;   The coefficient loads in the pre-loop fetch from fixed strides spanning
        ;   the full polynomial (0x00, 0x40, 0x80, ..., 0x3c0) matching the layer-4
        ;   butterfly distance of 64 coefficients = 0x100 bytes.
        ; ---------------------------------------------------------------------------
        mov       w5, #0x3ffe                             ; 0x0000039C, line  270  w5 = 0x3ffe = n^{-1}*R mod q
        dup       v29.4s, w5                              ; 0x000003A0, line  271  v29.4s = {f_lo, f_lo, f_lo, f_lo}
        mov       w5, #0xe03                              ; 0x000003A4, line  272  w5[15:0]  = 0xe03
        movk      w5, #0x40, lsl #16                      ; 0x000003A8, line  273  w5[30:16] = 0x40 => w5 = 0x00400e03
        dup       v30.4s, w5                              ; 0x000003AC, line  274  v30.4s = {f_hi, f_hi, f_hi, f_hi}
        mov       x4, #0x4                                ; 0x000003B0, line  275  x4 = 4 (Phase 2 loop count)
        ; Load 8 twiddle vectors from x2 (zetas_l123456), one 128-byte block:
        ;   v0 = zetas[0..3]   v1 = zetas[4..7]   v2 = zetas[8..11]  v3 = zetas[12..15]
        ;   v4 = zetas[16..19] v5 = zetas[20..23] v6 = zetas[24..27] v7 = zetas[28..31]
        ; These cover layer-4 and layer-3 twiddles for one outer iteration.
        ldr       q0, [x2], #0x80                         ; 0x000003B4, line  276  post-inc x2 by 0x80
        ldur      q1, [x2, #-0x70]                        ; 0x000003B8, line  277
        ldur      q2, [x2, #-0x60]                        ; 0x000003BC, line  278
        ldur      q3, [x2, #-0x50]                        ; 0x000003C0, line  279
        ldur      q4, [x2, #-0x40]                        ; 0x000003C4, line  280
        ldur      q5, [x2, #-0x30]                        ; 0x000003C8, line  281
        ldur      q6, [x2, #-0x20]                        ; 0x000003CC, line  282
        ldur      q7, [x2, #-0x10]                        ; 0x000003D0, line  283
        ldr       q8, [x0, #0xc0]                         ; 0x000003D4, line  284
        ldr       q27, [x0, #0x80]                        ; 0x000003D8, line  285
        ldr       q20, [x0, #0x1c0]                       ; 0x000003DC, line  286
        ldr       q23, [x0, #0x180]                       ; 0x000003E0, line  287
        ldr       q24, [x0, #0x3c0]                       ; 0x000003E4, line  288
        ldr       q28, [x0, #0x40]                        ; 0x000003E8, line  289
        ldr       q25, [x0, #0x340]                       ; 0x000003EC, line  290
        ldr       q10, [x0, #0x380]                       ; 0x000003F0, line  291
        sub       v15.4s, v27.4s, v8.4s                   ; 0x000003F4, line  292
        ldr       q26, [x0]                               ; 0x000003F8, line  293
        ldr       q18, [x0, #0x300]                       ; 0x000003FC, line  294
        add       v9.4s, v23.4s, v20.4s                   ; 0x00000400, line  295
        mul       v11.4s, v15.4s, v4.s[0]                 ; 0x00000404, line  296
        sub       v19.4s, v23.4s, v20.4s                  ; 0x00000408, line  297
        sub       v22.4s, v10.4s, v24.4s                  ; 0x0000040C, line  298
        ldr       q13, [x0, #0x240]                       ; 0x00000410, line  299
        sqrdmulh  v12.4s, v15.4s, v4.s[1]                 ; 0x00000414, line  300
        sub       v14.4s, v26.4s, v28.4s                  ; 0x00000418, line  301
        ldr       q17, [x0, #0x200]                       ; 0x0000041C, line  302
        add       v23.4s, v18.4s, v25.4s                  ; 0x00000420, line  303
        sqrdmulh  v15.4s, v14.4s, v3.s[3]                 ; 0x00000424, line  304
        sub       v18.4s, v18.4s, v25.4s                  ; 0x00000428, line  305
        mul       v25.4s, v14.4s, v3.s[2]                 ; 0x0000042C, line  306
        sub       v16.4s, v17.4s, v13.4s                  ; 0x00000430, line  307
        mls       v11.4s, v12.4s, v31.s[0]                ; 0x00000434, line  308
        add       v21.4s, v10.4s, v24.4s                  ; 0x00000438, line  309
        mls       v25.4s, v15.4s, v31.s[0]                ; 0x0000043C, line  310
        mul       v12.4s, v16.4s, v5.s[2]                 ; 0x00000440, line  311
        sub       v10.4s, v23.4s, v21.4s                  ; 0x00000444, line  312
        sqrdmulh  v14.4s, v10.4s, v3.s[1]                 ; 0x00000448, line  313
        add       v23.4s, v23.4s, v21.4s                  ; 0x0000044C, line  314
        add       v27.4s, v27.4s, v8.4s                   ; 0x00000450, line  315
        mul       v15.4s, v10.4s, v3.s[0]                 ; 0x00000454, line  316
        add       v24.4s, v25.4s, v11.4s                  ; 0x00000458, line  317
        sub       v10.4s, v25.4s, v11.4s                  ; 0x0000045C, line  318
        ldr       q25, [x0, #0x100]                       ; 0x00000460, line  319
        sqrdmulh  v8.4s, v18.4s, v6.s[3]                  ; 0x00000464, line  320
        add       v21.4s, v26.4s, v28.4s                  ; 0x00000468, line  321
        ldr       q26, [x0, #0x140]                       ; 0x0000046C, line  322
        sqrdmulh  v20.4s, v16.4s, v5.s[3]                 ; 0x00000470, line  323
        sqrdmulh  v28.4s, v22.4s, v7.s[1]                 ; 0x00000474, line  324
        add       v11.4s, v25.4s, v26.4s                  ; 0x00000478, line  325
        mls       v15.4s, v14.4s, v31.s[0]                ; 0x0000047C, line  326
        add       v17.4s, v17.4s, v13.4s                  ; 0x00000480, line  327
        mul       v13.4s, v22.4s, v7.s[0]                 ; 0x00000484, line  328
        ldr       q14, [x0, #0x280]                       ; 0x00000488, line  329
        ldr       q22, [x0, #0x2c0]                       ; 0x0000048C, line  330
        mls       v13.4s, v28.4s, v31.s[0]                ; 0x00000490, line  331
        sub       v16.4s, v25.4s, v26.4s                  ; 0x00000494, line  332
        sub       v28.4s, v21.4s, v27.4s                  ; 0x00000498, line  333
        mls       v12.4s, v20.4s, v31.s[0]                ; 0x0000049C, line  334
        add       v20.4s, v11.4s, v9.4s                   ; 0x000004A0, line  335
        add       v26.4s, v14.4s, v22.4s                  ; 0x000004A4, line  336
        sub       v14.4s, v14.4s, v22.4s                  ; 0x000004A8, line  337
        sqrdmulh  v22.4s, v28.4s, v1.s[3]                 ; 0x000004AC, line  338
        sub       v9.4s, v11.4s, v9.4s                    ; 0x000004B0, line  339
        mul       v25.4s, v14.4s, v6.s[0]                 ; 0x000004B4, line  340
        sub       v11.4s, v17.4s, v26.4s                  ; 0x000004B8, line  341
        add       v17.4s, v17.4s, v26.4s                  ; 0x000004BC, line  342
        add       v26.4s, v21.4s, v27.4s                  ; 0x000004C0, line  343
        sqrdmulh  v27.4s, v11.4s, v2.s[3]                 ; 0x000004C4, line  344
        mul       v21.4s, v11.4s, v2.s[2]                 ; 0x000004C8, line  345
        mul       v11.4s, v18.4s, v6.s[2]                 ; 0x000004CC, line  346
        mls       v11.4s, v8.4s, v31.s[0]                 ; 0x000004D0, line  347
        sqrdmulh  v8.4s, v14.4s, v6.s[1]                  ; 0x000004D4, line  348
        add       v18.4s, v26.4s, v20.4s                  ; 0x000004D8, line  349
        mls       v21.4s, v27.4s, v31.s[0]                ; 0x000004DC, line  350
        sub       v27.4s, v17.4s, v23.4s                  ; 0x000004E0, line  351
        mul       v14.4s, v28.4s, v1.s[2]                 ; 0x000004E4, line  352
        sub       v28.4s, v26.4s, v20.4s                  ; 0x000004E8, line  353
        add       v23.4s, v17.4s, v23.4s                  ; 0x000004EC, line  354
        mls       v25.4s, v8.4s, v31.s[0]                 ; 0x000004F0, line  355
        add       v26.4s, v21.4s, v15.4s                  ; 0x000004F4, line  356
        sub       v15.4s, v21.4s, v15.4s                  ; 0x000004F8, line  357
        mul       v8.4s, v19.4s, v5.s[0]                  ; 0x000004FC, line  358
        mls       v14.4s, v22.4s, v31.s[0]                ; 0x00000500, line  359
        sub       v22.4s, v11.4s, v13.4s                  ; 0x00000504, line  360
        sub       v20.4s, v12.4s, v25.4s                  ; 0x00000508, line  361
        add       v21.4s, v12.4s, v25.4s                  ; 0x0000050C, line  362
        sqrdmulh  v12.4s, v22.4s, v3.s[1]                 ; 0x00000510, line  363
        mul       v17.4s, v16.4s, v4.s[2]                 ; 0x00000514, line  364
        sqrdmulh  v25.4s, v16.4s, v4.s[3]                 ; 0x00000518, line  365
        add       v16.4s, v11.4s, v13.4s                  ; 0x0000051C, line  366
        mul       v11.4s, v22.4s, v3.s[0]                 ; 0x00000520, line  367
        sqrdmulh  v19.4s, v19.4s, v5.s[1]                 ; 0x00000524, line  368
        sqrdmulh  v22.4s, v15.4s, v1.s[1]                 ; 0x00000528, line  369
        sqrdmulh  v13.4s, v20.4s, v2.s[3]                 ; 0x0000052C, line  370
        mul       v20.4s, v20.4s, v2.s[2]                 ; 0x00000530, line  371
        mls       v11.4s, v12.4s, v31.s[0]                ; 0x00000534, line  372
        mls       v20.4s, v13.4s, v31.s[0]                ; 0x00000538, line  373
        sub       v13.4s, v18.4s, v23.4s                  ; 0x0000053C, line  374
        add       v23.4s, v18.4s, v23.4s                  ; 0x00000540, line  375
        mls       v17.4s, v25.4s, v31.s[0]                ; 0x00000544, line  376
        mls       v8.4s, v19.4s, v31.s[0]                 ; 0x00000548, line  377
        sub       v18.4s, v20.4s, v11.4s                  ; 0x0000054C, line  378
        add       v20.4s, v20.4s, v11.4s                  ; 0x00000550, line  379
        sqrdmulh  v12.4s, v9.4s, v2.s[1]                  ; 0x00000554, line  380
        mul       v15.4s, v15.4s, v1.s[0]                 ; 0x00000558, line  381
        sub       v11.4s, v17.4s, v8.4s                   ; 0x0000055C, line  382
        mls       v15.4s, v22.4s, v31.s[0]                ; 0x00000560, line  383
        add       v19.4s, v17.4s, v8.4s                   ; 0x00000564, line  384
        sqrdmulh  v25.4s, v11.4s, v2.s[1]                 ; 0x00000568, line  385
        add       v17.4s, v24.4s, v19.4s                  ; 0x0000056C, line  386
        sub       v24.4s, v24.4s, v19.4s                  ; 0x00000570, line  387
        mul       v19.4s, v11.4s, v2.s[0]                 ; 0x00000574, line  388
        sqrdmulh  v8.4s, v24.4s, v0.s[3]                  ; 0x00000578, line  389
        mls       v19.4s, v25.4s, v31.s[0]                ; 0x0000057C, line  390
        mul       v25.4s, v9.4s, v2.s[0]                  ; 0x00000580, line  391
        sub       x4, x4, #0x1                            ; 0x00000584, line  392  x4 -= 1 (one group already processed above)
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

        ; ---------------------------------------------------------------------------
        ; Layer 4->1 main loop  (Lmld_intt_layer1234_start)
        ;
        ;   Iterates x4 times (3 after the pre-loop decrement above).
        ;   Each iteration processes one 64-coefficient group through layers 4->1:
        ;
        ;   Layer 4: butterfly distance = 32 coefficients = 0x080 bytes
        ;   Layer 3: butterfly distance = 64 coefficients = 0x100 bytes
        ;   Layer 2: butterfly distance = 128 coefficients = 0x200 bytes
        ;   Layer 1: butterfly distance = 256 coefficients = 0x400 bytes
        ;             (the final add/sub pairs cross the full polynomial)
        ;
        ;   Each inverse butterfly: a' = a + b;  b' = monty_mul(a - b, zeta)
        ;   where monty_mul = mul / sqrdmulh / mls with v31.s[0] = q.
        ;
        ;   In the final layer (layer 1), the normalization constant
        ;   f = n^{-1}*R mod q is applied via v29 / v30 instead of a zeta,
        ;   scaling the result by n^{-1} to complete the INTT.
        ;
        ;   Coefficient loads/stores use x0 with large fixed offsets; x0 is
        ;   advanced by 0x10 (one vector = 4 x int32_t) once per outer iteration
        ;   via `str qXX, [x0, ...], #0x10`.
        ;   x2 is auto-incremented by 0x60 (six 128-bit vectors) per iteration.
        ; ---------------------------------------------------------------------------
Lmld_intt_layer1234_start

        sub       v22.4s, v21.4s, v16.4s                  ; 0x00000590, line  395
        mls       v25.4s, v12.4s, v31.s[0]                ; 0x00000594, line  396
        add       v12.4s, v21.4s, v16.4s                  ; 0x00000598, line  397
        mul       v9.4s, v24.4s, v0.s[2]                  ; 0x0000059C, line  398
        mls       v9.4s, v8.4s, v31.s[0]                  ; 0x000005A0, line  399
        sub       v16.4s, v14.4s, v25.4s                  ; 0x000005A4, line  400
        add       v14.4s, v14.4s, v25.4s                  ; 0x000005A8, line  401
        sqrdmulh  v24.4s, v22.4s, v1.s[1]                 ; 0x000005AC, line  402
        sub       v11.4s, v14.4s, v26.4s                  ; 0x000005B0, line  403
        sqrdmulh  v21.4s, v16.4s, v0.s[3]                 ; 0x000005B4, line  404
        add       v25.4s, v14.4s, v26.4s                  ; 0x000005B8, line  405
        mul       v14.4s, v22.4s, v1.s[0]                 ; 0x000005BC, line  406
        mls       v14.4s, v24.4s, v31.s[0]                ; 0x000005C0, line  407
        mul       v16.4s, v16.4s, v0.s[2]                 ; 0x000005C4, line  408
        mls       v16.4s, v21.4s, v31.s[0]                ; 0x000005C8, line  409
        add       v24.4s, v9.4s, v14.4s                   ; 0x000005CC, line  410
        sqrdmulh  v21.4s, v25.4s, v30.4s                  ; 0x000005D0, line  411
        sqrdmulh  v26.4s, v11.4s, v0.s[1]                 ; 0x000005D4, line  412
        mul       v8.4s, v25.4s, v29.4s                   ; 0x000005D8, line  413
        mls       v8.4s, v21.4s, v31.s[0]                 ; 0x000005DC, line  414
        mul       v25.4s, v24.4s, v29.4s                  ; 0x000005E0, line  415
        mul       v22.4s, v11.4s, v0.s[0]                 ; 0x000005E4, line  416
        sub       v11.4s, v17.4s, v12.4s                  ; 0x000005E8, line  417
        str       q8, [x0, #0x80]                         ; 0x000005EC, line  418
        sub       v8.4s, v9.4s, v14.4s                    ; 0x000005F0, line  419
        add       v14.4s, v16.4s, v15.4s                  ; 0x000005F4, line  420
        sqrdmulh  v9.4s, v11.4s, v0.s[1]                  ; 0x000005F8, line  421
        sub       v21.4s, v16.4s, v15.4s                  ; 0x000005FC, line  422
        mls       v22.4s, v26.4s, v31.s[0]                ; 0x00000600, line  423
        mul       v15.4s, v11.4s, v0.s[0]                 ; 0x00000604, line  424
        mls       v15.4s, v9.4s, v31.s[0]                 ; 0x00000608, line  425
        add       v11.4s, v17.4s, v12.4s                  ; 0x0000060C, line  426
        mul       v16.4s, v10.4s, v1.s[2]                 ; 0x00000610, line  427
        str       q22, [x0, #0x280]                       ; 0x00000614, line  428
        sqrdmulh  v26.4s, v10.4s, v1.s[3]                 ; 0x00000618, line  429
        str       q15, [x0, #0x240]                       ; 0x0000061C, line  430
        sqrdmulh  v9.4s, v8.4s, v0.s[1]                   ; 0x00000620, line  431
        mul       v12.4s, v8.4s, v0.s[0]                  ; 0x00000624, line  432
        mls       v16.4s, v26.4s, v31.s[0]                ; 0x00000628, line  433
        sqrdmulh  v10.4s, v27.4s, v1.s[1]                 ; 0x0000062C, line  434
        sqrdmulh  v15.4s, v14.4s, v30.4s                  ; 0x00000630, line  435
        add       v22.4s, v16.4s, v19.4s                  ; 0x00000634, line  436
        sub       v19.4s, v16.4s, v19.4s                  ; 0x00000638, line  437
        mls       v12.4s, v9.4s, v31.s[0]                 ; 0x0000063C, line  438
        add       v8.4s, v22.4s, v20.4s                   ; 0x00000640, line  439
        sub       v26.4s, v22.4s, v20.4s                  ; 0x00000644, line  440
        mul       v27.4s, v27.4s, v1.s[0]                 ; 0x00000648, line  441
        sqrdmulh  v17.4s, v11.4s, v30.4s                  ; 0x0000064C, line  442
        mls       v27.4s, v10.4s, v31.s[0]                ; 0x00000650, line  443
        mul       v20.4s, v11.4s, v29.4s                  ; 0x00000654, line  444
        sqrdmulh  v22.4s, v24.4s, v30.4s                  ; 0x00000658, line  445
        mls       v20.4s, v17.4s, v31.s[0]                ; 0x0000065C, line  446
        mul       v14.4s, v14.4s, v29.4s                  ; 0x00000660, line  447
        sqrdmulh  v16.4s, v23.4s, v30.4s                  ; 0x00000664, line  448
        str       q20, [x0, #0x40]                        ; 0x00000668, line  449
        sqrdmulh  v11.4s, v21.4s, v0.s[1]                 ; 0x0000066C, line  450
        sqrdmulh  v20.4s, v28.4s, v0.s[3]                 ; 0x00000670, line  451
        mul       v17.4s, v23.4s, v29.4s                  ; 0x00000674, line  452
        mul       v23.4s, v28.4s, v0.s[2]                 ; 0x00000678, line  453
        mls       v17.4s, v16.4s, v31.s[0]                ; 0x0000067C, line  454
        mul       v10.4s, v21.4s, v0.s[0]                 ; 0x00000680, line  455
        str       q12, [x0, #0x340]                       ; 0x00000684, line  456
        mls       v25.4s, v22.4s, v31.s[0]                ; 0x00000688, line  457
        str       q17, [x0], #0x10                        ; 0x0000068C, line  458
        ldr       q17, [x0, #0x2c0]                       ; 0x00000690, line  459
        mls       v14.4s, v15.4s, v31.s[0]                ; 0x00000694, line  460
        ldr       q12, [x0, #0x200]                       ; 0x00000698, line  461
        sqrdmulh  v16.4s, v13.4s, v0.s[1]                 ; 0x0000069C, line  462
        str       q25, [x0, #0x130]                       ; 0x000006A0, line  463
        mul       v28.4s, v13.4s, v0.s[0]                 ; 0x000006A4, line  464
        ldr       q13, [x0, #0x240]                       ; 0x000006A8, line  465
        str       q14, [x0, #0x170]                       ; 0x000006AC, line  466
        mul       v14.4s, v18.4s, v1.s[0]                 ; 0x000006B0, line  467
        mls       v28.4s, v16.4s, v31.s[0]                ; 0x000006B4, line  468
        ldr       q21, [x0, #0xc0]                        ; 0x000006B8, line  469
        mls       v10.4s, v11.4s, v31.s[0]                ; 0x000006BC, line  470
        mls       v23.4s, v20.4s, v31.s[0]                ; 0x000006C0, line  471
        str       q28, [x0, #0x1f0]                       ; 0x000006C4, line  472
        ldr       q11, [x0, #0x300]                       ; 0x000006C8, line  473
        sqrdmulh  v28.4s, v18.4s, v1.s[1]                 ; 0x000006CC, line  474
        str       q10, [x0, #0x370]                       ; 0x000006D0, line  475
        mul       v16.4s, v19.4s, v0.s[2]                 ; 0x000006D4, line  476
        sqrdmulh  v19.4s, v19.4s, v0.s[3]                 ; 0x000006D8, line  477
        sqrdmulh  v10.4s, v26.4s, v0.s[1]                 ; 0x000006DC, line  478
        add       v18.4s, v12.4s, v13.4s                  ; 0x000006E0, line  479
        sub       v12.4s, v12.4s, v13.4s                  ; 0x000006E4, line  480
        mls       v16.4s, v19.4s, v31.s[0]                ; 0x000006E8, line  481
        ldr       q9, [x0, #0x280]                        ; 0x000006EC, line  482
        ldr       q20, [x0, #0x380]                       ; 0x000006F0, line  483
        add       v24.4s, v23.4s, v27.4s                  ; 0x000006F4, line  484
        sub       v25.4s, v23.4s, v27.4s                  ; 0x000006F8, line  485
        mul       v19.4s, v26.4s, v0.s[0]                 ; 0x000006FC, line  486
        mls       v14.4s, v28.4s, v31.s[0]                ; 0x00000700, line  487
        add       v13.4s, v9.4s, v17.4s                   ; 0x00000704, line  488
        sub       v28.4s, v18.4s, v13.4s                  ; 0x00000708, line  489
        mls       v19.4s, v10.4s, v31.s[0]                ; 0x0000070C, line  490
        sqrdmulh  v23.4s, v25.4s, v0.s[1]                 ; 0x00000710, line  491
        mul       v15.4s, v25.4s, v0.s[0]                 ; 0x00000714, line  492
        str       q19, [x0, #0x2b0]                       ; 0x00000718, line  493
        ldr       q19, [x0, #0x80]                        ; 0x0000071C, line  494
        sqrdmulh  v22.4s, v8.4s, v30.4s                   ; 0x00000720, line  495
        mls       v15.4s, v23.4s, v31.s[0]                ; 0x00000724, line  496
        add       v26.4s, v16.4s, v14.4s                  ; 0x00000728, line  497
        mul       v10.4s, v8.4s, v29.4s                   ; 0x0000072C, line  498
        add       v8.4s, v18.4s, v13.4s                   ; 0x00000730, line  499
        sqrdmulh  v13.4s, v26.4s, v30.4s                  ; 0x00000734, line  500
        str       q15, [x0, #0x2f0]                       ; 0x00000738, line  501
        sub       v18.4s, v9.4s, v17.4s                   ; 0x0000073C, line  502
        mul       v27.4s, v26.4s, v29.4s                  ; 0x00000740, line  503
        sqrdmulh  v23.4s, v12.4s, v5.s[3]                 ; 0x00000744, line  504
        mls       v27.4s, v13.4s, v31.s[0]                ; 0x00000748, line  505
        mul       v25.4s, v18.4s, v6.s[0]                 ; 0x0000074C, line  506
        sqrdmulh  v13.4s, v18.4s, v6.s[1]                 ; 0x00000750, line  507
        str       q27, [x0, #0x1b0]                       ; 0x00000754, line  508
        sub       v27.4s, v19.4s, v21.4s                  ; 0x00000758, line  509
        add       v21.4s, v19.4s, v21.4s                  ; 0x0000075C, line  510
        mul       v18.4s, v12.4s, v5.s[2]                 ; 0x00000760, line  511
        sub       v9.4s, v16.4s, v14.4s                   ; 0x00000764, line  512
        mul       v26.4s, v24.4s, v29.4s                  ; 0x00000768, line  513
        ldr       q12, [x0, #0x3c0]                       ; 0x0000076C, line  514
        mls       v25.4s, v13.4s, v31.s[0]                ; 0x00000770, line  515
        sub       v16.4s, v20.4s, v12.4s                  ; 0x00000774, line  516
        sqrdmulh  v17.4s, v24.4s, v30.4s                  ; 0x00000778, line  517
        mul       v13.4s, v16.4s, v7.s[0]                 ; 0x0000077C, line  518
        mls       v18.4s, v23.4s, v31.s[0]                ; 0x00000780, line  519
        mls       v26.4s, v17.4s, v31.s[0]                ; 0x00000784, line  520
        sqrdmulh  v17.4s, v9.4s, v0.s[1]                  ; 0x00000788, line  521
        sqrdmulh  v24.4s, v16.4s, v7.s[1]                 ; 0x0000078C, line  522
        ldr       q16, [x0, #0x340]                       ; 0x00000790, line  523
        str       q26, [x0, #0xf0]                        ; 0x00000794, line  524
        sub       v15.4s, v18.4s, v25.4s                  ; 0x00000798, line  525
        mul       v23.4s, v9.4s, v0.s[0]                  ; 0x0000079C, line  526
        ldr       q19, [x0, #0x180]                       ; 0x000007A0, line  527
        ldr       q14, [x0, #0x1c0]                       ; 0x000007A4, line  528
        sqrdmulh  v9.4s, v15.4s, v2.s[3]                  ; 0x000007A8, line  529
        add       v20.4s, v20.4s, v12.4s                  ; 0x000007AC, line  530
        add       v12.4s, v11.4s, v16.4s                  ; 0x000007B0, line  531
        mul       v26.4s, v15.4s, v2.s[2]                 ; 0x000007B4, line  532
        sub       v16.4s, v11.4s, v16.4s                  ; 0x000007B8, line  533
        sub       v11.4s, v12.4s, v20.4s                  ; 0x000007BC, line  534
        mls       v23.4s, v17.4s, v31.s[0]                ; 0x000007C0, line  535
        add       v20.4s, v12.4s, v20.4s                  ; 0x000007C4, line  536
        sub       v12.4s, v19.4s, v14.4s                  ; 0x000007C8, line  537
        mul       v17.4s, v27.4s, v4.s[0]                 ; 0x000007CC, line  538
        mls       v10.4s, v22.4s, v31.s[0]                ; 0x000007D0, line  539
        add       v22.4s, v19.4s, v14.4s                  ; 0x000007D4, line  540
        ldr       q14, [x0, #0x40]                        ; 0x000007D8, line  541
        str       q23, [x0, #0x3b0]                       ; 0x000007DC, line  542
        sqrdmulh  v23.4s, v27.4s, v4.s[1]                 ; 0x000007E0, line  543
        ldr       q19, [x0, #0x100]                       ; 0x000007E4, line  544
        ldr       q15, [x0, #0x140]                       ; 0x000007E8, line  545
        mls       v26.4s, v9.4s, v31.s[0]                 ; 0x000007EC, line  546
        str       q10, [x0, #0xb0]                        ; 0x000007F0, line  547
        sqrdmulh  v10.4s, v11.4s, v3.s[1]                 ; 0x000007F4, line  548
        sub       v27.4s, v8.4s, v20.4s                   ; 0x000007F8, line  549
        mls       v13.4s, v24.4s, v31.s[0]                ; 0x000007FC, line  550
        add       v8.4s, v8.4s, v20.4s                    ; 0x00000800, line  551
        sub       v20.4s, v19.4s, v15.4s                  ; 0x00000804, line  552
        sqrdmulh  v9.4s, v16.4s, v6.s[3]                  ; 0x00000808, line  553
        add       v19.4s, v19.4s, v15.4s                  ; 0x0000080C, line  554
        ldr       q15, [x0]                               ; 0x00000810, line  555
        mul       v24.4s, v20.4s, v4.s[2]                 ; 0x00000814, line  556
        mls       v17.4s, v23.4s, v31.s[0]                ; 0x00000818, line  557
        add       v23.4s, v15.4s, v14.4s                  ; 0x0000081C, line  558
        sub       v14.4s, v15.4s, v14.4s                  ; 0x00000820, line  559
        mul       v15.4s, v11.4s, v3.s[0]                 ; 0x00000824, line  560
        sub       v11.4s, v23.4s, v21.4s                  ; 0x00000828, line  561
        mul       v16.4s, v16.4s, v6.s[2]                 ; 0x0000082C, line  562
        add       v23.4s, v23.4s, v21.4s                  ; 0x00000830, line  563
        add       v21.4s, v18.4s, v25.4s                  ; 0x00000834, line  564
        sqrdmulh  v25.4s, v20.4s, v4.s[3]                 ; 0x00000838, line  565
        sqrdmulh  v18.4s, v12.4s, v5.s[1]                 ; 0x0000083C, line  566
        sqrdmulh  v20.4s, v14.4s, v3.s[3]                 ; 0x00000840, line  567
        mul       v12.4s, v12.4s, v5.s[0]                 ; 0x00000844, line  568
        mls       v16.4s, v9.4s, v31.s[0]                 ; 0x00000848, line  569
        mls       v12.4s, v18.4s, v31.s[0]                ; 0x0000084C, line  570
        mls       v24.4s, v25.4s, v31.s[0]                ; 0x00000850, line  571
        sub       v25.4s, v16.4s, v13.4s                  ; 0x00000854, line  572
        add       v16.4s, v16.4s, v13.4s                  ; 0x00000858, line  573
        mul       v13.4s, v28.4s, v2.s[2]                 ; 0x0000085C, line  574
        sqrdmulh  v9.4s, v25.4s, v3.s[1]                  ; 0x00000860, line  575
        mul       v18.4s, v25.4s, v3.s[0]                 ; 0x00000864, line  576
        sqrdmulh  v25.4s, v28.4s, v2.s[3]                 ; 0x00000868, line  577
        mls       v18.4s, v9.4s, v31.s[0]                 ; 0x0000086C, line  578
        mls       v15.4s, v10.4s, v31.s[0]                ; 0x00000870, line  579
        sub       v9.4s, v24.4s, v12.4s                   ; 0x00000874, line  580
        mul       v28.4s, v14.4s, v3.s[2]                 ; 0x00000878, line  581
        add       v12.4s, v24.4s, v12.4s                  ; 0x0000087C, line  582
        mls       v28.4s, v20.4s, v31.s[0]                ; 0x00000880, line  583
        add       v20.4s, v26.4s, v18.4s                  ; 0x00000884, line  584
        add       v24.4s, v19.4s, v22.4s                  ; 0x00000888, line  585
        mls       v13.4s, v25.4s, v31.s[0]                ; 0x0000088C, line  586
        sub       v18.4s, v26.4s, v18.4s                  ; 0x00000890, line  587
        sqrdmulh  v26.4s, v11.4s, v1.s[3]                 ; 0x00000894, line  588
        add       v25.4s, v23.4s, v24.4s                  ; 0x00000898, line  589
        mul       v14.4s, v11.4s, v1.s[2]                 ; 0x0000089C, line  590
        sub       v10.4s, v28.4s, v17.4s                  ; 0x000008A0, line  591
        add       v17.4s, v28.4s, v17.4s                  ; 0x000008A4, line  592
        sub       v28.4s, v23.4s, v24.4s                  ; 0x000008A8, line  593
        sqrdmulh  v11.4s, v9.4s, v2.s[1]                  ; 0x000008AC, line  594
        sub       v22.4s, v19.4s, v22.4s                  ; 0x000008B0, line  595
        sub       v24.4s, v17.4s, v12.4s                  ; 0x000008B4, line  596
        mls       v14.4s, v26.4s, v31.s[0]                ; 0x000008B8, line  597
        add       v17.4s, v17.4s, v12.4s                  ; 0x000008BC, line  598
        sqrdmulh  v12.4s, v22.4s, v2.s[1]                 ; 0x000008C0, line  599
        sub       v23.4s, v13.4s, v15.4s                  ; 0x000008C4, line  600
        add       v26.4s, v13.4s, v15.4s                  ; 0x000008C8, line  601
        mul       v19.4s, v9.4s, v2.s[0]                  ; 0x000008CC, line  602
        sqrdmulh  v9.4s, v23.4s, v1.s[1]                  ; 0x000008D0, line  603
        mul       v15.4s, v23.4s, v1.s[0]                 ; 0x000008D4, line  604
        mls       v19.4s, v11.4s, v31.s[0]                ; 0x000008D8, line  605
        sub       v13.4s, v25.4s, v8.4s                   ; 0x000008DC, line  606
        mls       v15.4s, v9.4s, v31.s[0]                 ; 0x000008E0, line  607
        add       v23.4s, v25.4s, v8.4s                   ; 0x000008E4, line  608
        sqrdmulh  v8.4s, v24.4s, v0.s[3]                  ; 0x000008E8, line  609
        mul       v25.4s, v22.4s, v2.s[0]                 ; 0x000008EC, line  610
        subs      x4, x4, #0x1                            ; 0x000008F0, line  611  decrement loop counter
        cbnz      x4, Lmld_intt_layer1234_start           ; 0x000008F4, line  612  branch if x4 != 0

        ; ---------------------------------------------------------------------------
        ; Layer 4->1 post-loop tail  --  final group + n^{-1} normalization
        ;
        ;   The last iteration's layer-1 butterflies are completed here.
        ;   Remaining Montgomery multiplications use v29 / v30 to apply the
        ;   combined n^{-1} * R scaling factor, after which each coefficient
        ;   holds the fully normalized INTT result in Montgomery representation.
        ;   The final str instructions commit all 256 results to r[].
        ; ---------------------------------------------------------------------------
        mul       v22.4s, v24.4s, v0.s[2]                 ; 0x000008F8, line  613
        sqrdmulh  v9.4s, v23.4s, v30.4s                   ; 0x000008FC, line  614
        mls       v25.4s, v12.4s, v31.s[0]                ; 0x00000900, line  615
        mul       v23.4s, v23.4s, v29.4s                  ; 0x00000904, line  616
        mls       v23.4s, v9.4s, v31.s[0]                 ; 0x00000908, line  617
        mls       v22.4s, v8.4s, v31.s[0]                 ; 0x0000090C, line  618
        sqrdmulh  v11.4s, v10.4s, v1.s[3]                 ; 0x00000910, line  619
        sub       v9.4s, v14.4s, v25.4s                   ; 0x00000914, line  620
        str       q23, [x0], #0x10                        ; 0x00000918, line  621
        mul       v23.4s, v10.4s, v1.s[2]                 ; 0x0000091C, line  622
        sqrdmulh  v24.4s, v9.4s, v0.s[3]                  ; 0x00000920, line  623
        mls       v23.4s, v11.4s, v31.s[0]                ; 0x00000924, line  624
        mul       v9.4s, v9.4s, v0.s[2]                   ; 0x00000928, line  625
        mls       v9.4s, v24.4s, v31.s[0]                 ; 0x0000092C, line  626
        sub       v24.4s, v23.4s, v19.4s                  ; 0x00000930, line  627
        add       v19.4s, v23.4s, v19.4s                  ; 0x00000934, line  628
        mul       v8.4s, v28.4s, v0.s[2]                  ; 0x00000938, line  629
        add       v23.4s, v14.4s, v25.4s                  ; 0x0000093C, line  630
        mul       v11.4s, v13.4s, v0.s[0]                 ; 0x00000940, line  631
        sub       v25.4s, v21.4s, v16.4s                  ; 0x00000944, line  632
        sub       v10.4s, v9.4s, v15.4s                   ; 0x00000948, line  633
        add       v15.4s, v9.4s, v15.4s                   ; 0x0000094C, line  634
        add       v16.4s, v21.4s, v16.4s                  ; 0x00000950, line  635
        sqrdmulh  v28.4s, v28.4s, v0.s[3]                 ; 0x00000954, line  636
        add       v9.4s, v23.4s, v26.4s                   ; 0x00000958, line  637
        add       v14.4s, v17.4s, v16.4s                  ; 0x0000095C, line  638
        sqrdmulh  v21.4s, v13.4s, v0.s[1]                 ; 0x00000960, line  639
        sub       v13.4s, v17.4s, v16.4s                  ; 0x00000964, line  640
        mul       v16.4s, v14.4s, v29.4s                  ; 0x00000968, line  641
        sub       v12.4s, v23.4s, v26.4s                  ; 0x0000096C, line  642
        mul       v17.4s, v13.4s, v0.s[0]                 ; 0x00000970, line  643
        mls       v8.4s, v28.4s, v31.s[0]                 ; 0x00000974, line  644
        sqrdmulh  v28.4s, v14.4s, v30.4s                  ; 0x00000978, line  645
        sub       v14.4s, v19.4s, v20.4s                  ; 0x0000097C, line  646
        add       v20.4s, v19.4s, v20.4s                  ; 0x00000980, line  647
        sqrdmulh  v19.4s, v13.4s, v0.s[1]                 ; 0x00000984, line  648
        sqrdmulh  v26.4s, v27.4s, v1.s[1]                 ; 0x00000988, line  649
        mls       v16.4s, v28.4s, v31.s[0]                ; 0x0000098C, line  650
        sqrdmulh  v28.4s, v12.4s, v0.s[1]                 ; 0x00000990, line  651
        mul       v27.4s, v27.4s, v1.s[0]                 ; 0x00000994, line  652
        str       q16, [x0, #0x30]                        ; 0x00000998, line  653
        mul       v12.4s, v12.4s, v0.s[0]                 ; 0x0000099C, line  654
        mls       v12.4s, v28.4s, v31.s[0]                ; 0x000009A0, line  655
        mls       v27.4s, v26.4s, v31.s[0]                ; 0x000009A4, line  656
        sqrdmulh  v26.4s, v25.4s, v1.s[1]                 ; 0x000009A8, line  657
        str       q12, [x0, #0x270]                       ; 0x000009AC, line  658
        sqrdmulh  v12.4s, v14.4s, v0.s[1]                 ; 0x000009B0, line  659
        sub       v13.4s, v8.4s, v27.4s                   ; 0x000009B4, line  660
        add       v27.4s, v8.4s, v27.4s                   ; 0x000009B8, line  661
        mul       v16.4s, v14.4s, v0.s[0]                 ; 0x000009BC, line  662
        mul       v8.4s, v20.4s, v29.4s                   ; 0x000009C0, line  663
        mls       v16.4s, v12.4s, v31.s[0]                ; 0x000009C4, line  664
        mul       v12.4s, v18.4s, v1.s[0]                 ; 0x000009C8, line  665
        sqrdmulh  v14.4s, v20.4s, v30.4s                  ; 0x000009CC, line  666
        str       q16, [x0, #0x2b0]                       ; 0x000009D0, line  667
        sqrdmulh  v20.4s, v18.4s, v1.s[1]                 ; 0x000009D4, line  668
        mul       v25.4s, v25.4s, v1.s[0]                 ; 0x000009D8, line  669
        mls       v25.4s, v26.4s, v31.s[0]                ; 0x000009DC, line  670
        mls       v17.4s, v19.4s, v31.s[0]                ; 0x000009E0, line  671
        mul       v18.4s, v9.4s, v29.4s                   ; 0x000009E4, line  672
        add       v28.4s, v22.4s, v25.4s                  ; 0x000009E8, line  673
        sqrdmulh  v9.4s, v9.4s, v30.4s                    ; 0x000009EC, line  674
        sub       v23.4s, v22.4s, v25.4s                  ; 0x000009F0, line  675
        str       q17, [x0, #0x230]                       ; 0x000009F4, line  676
        mls       v11.4s, v21.4s, v31.s[0]                ; 0x000009F8, line  677
        mls       v8.4s, v14.4s, v31.s[0]                 ; 0x000009FC, line  678
        sqrdmulh  v21.4s, v28.4s, v30.4s                  ; 0x00000A00, line  679
        str       q11, [x0, #0x1f0]                       ; 0x00000A04, line  680
        mul       v17.4s, v28.4s, v29.4s                  ; 0x00000A08, line  681
        str       q8, [x0, #0xb0]                         ; 0x00000A0C, line  682
        mul       v28.4s, v10.4s, v0.s[0]                 ; 0x00000A10, line  683
        mls       v17.4s, v21.4s, v31.s[0]                ; 0x00000A14, line  684
        sqrdmulh  v21.4s, v10.4s, v0.s[1]                 ; 0x00000A18, line  685
        mul       v8.4s, v15.4s, v29.4s                   ; 0x00000A1C, line  686
        str       q17, [x0, #0x130]                       ; 0x00000A20, line  687
        sqrdmulh  v15.4s, v15.4s, v30.4s                  ; 0x00000A24, line  688
        mul       v10.4s, v24.4s, v0.s[2]                 ; 0x00000A28, line  689
        sqrdmulh  v24.4s, v24.4s, v0.s[3]                 ; 0x00000A2C, line  690
        mls       v12.4s, v20.4s, v31.s[0]                ; 0x00000A30, line  691
        mls       v8.4s, v15.4s, v31.s[0]                 ; 0x00000A34, line  692
        mls       v10.4s, v24.4s, v31.s[0]                ; 0x00000A38, line  693
        sqrdmulh  v24.4s, v27.4s, v30.4s                  ; 0x00000A3C, line  694
        str       q8, [x0, #0x170]                        ; 0x00000A40, line  695
        mul       v14.4s, v13.4s, v0.s[0]                 ; 0x00000A44, line  696
        sub       v16.4s, v10.4s, v12.4s                  ; 0x00000A48, line  697
        sqrdmulh  v17.4s, v13.4s, v0.s[1]                 ; 0x00000A4C, line  698
        add       v10.4s, v10.4s, v12.4s                  ; 0x00000A50, line  699
        mul       v13.4s, v27.4s, v29.4s                  ; 0x00000A54, line  700
        sqrdmulh  v20.4s, v10.4s, v30.4s                  ; 0x00000A58, line  701
        mls       v14.4s, v17.4s, v31.s[0]                ; 0x00000A5C, line  702
        mls       v13.4s, v24.4s, v31.s[0]                ; 0x00000A60, line  703
        sqrdmulh  v24.4s, v23.4s, v0.s[1]                 ; 0x00000A64, line  704
        str       q14, [x0, #0x2f0]                       ; 0x00000A68, line  705
        sqrdmulh  v8.4s, v16.4s, v0.s[1]                  ; 0x00000A6C, line  706
        str       q13, [x0, #0xf0]                        ; 0x00000A70, line  707
        mls       v18.4s, v9.4s, v31.s[0]                 ; 0x00000A74, line  708
        mul       v9.4s, v23.4s, v0.s[0]                  ; 0x00000A78, line  709
        mul       v14.4s, v16.4s, v0.s[0]                 ; 0x00000A7C, line  710
        str       q18, [x0, #0x70]                        ; 0x00000A80, line  711
        mul       v27.4s, v10.4s, v29.4s                  ; 0x00000A84, line  712
        mls       v28.4s, v21.4s, v31.s[0]                ; 0x00000A88, line  713
        mls       v14.4s, v8.4s, v31.s[0]                 ; 0x00000A8C, line  714
        mls       v27.4s, v20.4s, v31.s[0]                ; 0x00000A90, line  715
        str       q28, [x0, #0x370]                       ; 0x00000A94, line  716
        mls       v9.4s, v24.4s, v31.s[0]                 ; 0x00000A98, line  717
        str       q14, [x0, #0x3b0]                       ; 0x00000A9C, line  718
        str       q27, [x0, #0x1b0]                       ; 0x00000AA0, line  719
        str       q9, [x0, #0x330]                        ; 0x00000AA4, line  720
        ; ---------------------------------------------------------------------------
        ; Epilogue  --  restore callee-saved FP registers and deallocate stack frame
        ; ---------------------------------------------------------------------------
        ldp       d8, d9, [sp]                            ; 0x00000AA8, line  721  restore d8,d9
        ; .cfi_restore d8
        ; .cfi_restore d9
        ldp       d10, d11, [sp, #0x10]                   ; 0x00000AAC, line  724  restore d10,d11
        ; .cfi_restore d10
        ; .cfi_restore d11
        ldp       d12, d13, [sp, #0x20]                   ; 0x00000AB0, line  727  restore d12,d13
        ; .cfi_restore d12
        ; .cfi_restore d13
        ldp       d14, d15, [sp, #0x30]                   ; 0x00000AB4, line  730  restore d14,d15
        ; .cfi_restore d14
        ; .cfi_restore d15
        add       sp, sp, #0x40                           ; 0x00000AB8, line  733  deallocate stack frame
        ; .cfi_adjust_cfa_offset -0x40
        ret                                               ; 0x00000ABC, line  735  return to caller
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000AC0 byte(s)

        AREA      |.xdata|, DATA, READONLY, ALIGN=4

XDATA_$FUNC_NAME

        DCD       0x182002B0                              ; header dword
        DCB       0xD9, 0x86                              ; unwind code 'save_fregp', registers d14,d15 at stack offset 0x0030
        DCB       0xD9, 0x04                              ; unwind code 'save_fregp', registers d12,d13 at stack offset 0x0020
        DCB       0xD8, 0x82                              ; unwind code 'save_fregp', registers d10,d11 at stack offset 0x0010
        DCB       0xD8, 0x00                              ; unwind code 'save_fregp', registers d8,d9 at stack offset 0x0000
        DCB       0x04                                    ; unwind code 'alloc_s', stack space 0x0040
        DCB       0xE4                                    ; unwind code 'end'
        DCB       0x00, 0x00                              ; unwind code padding

        AREA      |.pdata|, DATA, READONLY, ALIGN=4

        DCD       $FUNC_NAME                              ; function start RVA
        DCD       XDATA_$FUNC_NAME                        ; pointer in XDATA section

        END
