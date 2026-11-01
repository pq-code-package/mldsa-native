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
; Name: ntt_aarch64_asm
; Description: AArch64 ML-DSA forward NTT
; Signature: void mld_ntt_aarch64_asm(int32_t r[256], const int32_t zetas_l123456[144], const int32_t zetas_l78[384])
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
;     size_bytes: 576
;     permissions: read-only
;     c_parameter: const int32_t zetas_l123456[144]
;     description: Twiddle factors for layers 1-6 (144 x int32_t)
;   x2:
;     type: buffer
;     size_bytes: 1536
;     permissions: read-only
;     c_parameter: const int32_t zetas_l78[384]
;     description: Twiddle factors for layers 7-8 (384 x int32_t)
;

        IF :LNOT: :DEF:FUNC_NAME
        GBLS      FUNC_NAME
FUNC_NAME SETS    "mldsa_ntt_aarch64_asm"
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
        ;     x0  / x3 : pointer into r[] (x3 = saved base; x0 advances)
        ;     x1        : pointer into zetas_l123456[] (auto-incremented)
        ;     x2        : pointer into zetas_l78[]     (auto-incremented)
        ;     x4        : loop counter
        ;     w5        : scratch for immediate constant construction
        ;     v7.4s     : broadcast of Montgomery modulus  q = 0x007fe001 (8380417)
        ;     v0-v3     : twiddle-factor (zeta) vectors for layers 1-6
        ;     v4-v31    : coefficient working registers
        ; ---------------------------------------------------------------------------
        ; .cfi_startproc
        sub       sp, sp, #0x40                           ; 0x00000000, line   30
        ; .cfi_adjust_cfa_offset 0x40
        stp       d8, d9, [sp]                            ; 0x00000004, line   32  save d8,d9  at [sp+0x00]
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
        ;   The Montgomery multiplication pattern used throughout this NTT is:
        ;     (1)  mul      vD.4s, vA.4s, vB.s[i]     ; low 32-bit product
        ;     (2)  sqrdmulh vE.4s, vA.4s, vB.s[j]     ; rounded doubling high half
        ;     (3)  mls      vD.4s, vE.4s, v7.s[0]     ; vD -= vE * q  (reduce mod q)
        ;   After step (3), vD holds the fully-reduced Montgomery product.
        ;   v7.4s is kept constant throughout the entire function.
        ; ---------------------------------------------------------------------------
        mov       w5, #0xe001                             ; 0x00000014, line   44  w5[15:0]  = 0xe001
        movk      w5, #0x7f, lsl #16                      ; 0x00000018, line   45  w5[30:16] = 0x7f  => w5 = 0x007fe001 = q
        dup       v7.4s, w5                               ; 0x0000001C, line   46  v7.4s = {q,q,q,q}
        mov       x3, x0                                  ; 0x00000020, line   47  x3 = base address of r[] (saved for reset)
        mov       x4, #0x8                                ; 0x00000024, line   48  x4 = 8 iterations (layer 1-3 loop count)

        ; ---------------------------------------------------------------------------
        ; Phase 1 pre-loop  --  load first twiddle block and first coefficient group
        ;
        ;   x1 points to zetas_l123456[].  Each 64-byte block holds 16 int32_t
        ;   twiddle factors packed as four 128-bit NEON vectors.
        ;     q0 = zetas[0..3]   (loaded, x1 post-incremented by 0x40)
        ;     q1 = zetas[4..7]   (ldur x1-0x30)
        ;     q2 = zetas[8..11]  (ldur x1-0x20)
        ;     q3 = zetas[12..15] (ldur x1-0x10)
        ;
        ;   Coefficients are loaded scattered across r[] at fixed strides of 0x10
        ;   (four int32_t = 16 bytes) corresponding to NTT butterfly distance.
        ; ---------------------------------------------------------------------------
        ldr       q0, [x1], #0x40                         ; 0x00000028, line   49
        ldur      q1, [x1, #-0x30]                        ; 0x0000002C, line   50
        ldur      q2, [x1, #-0x20]                        ; 0x00000030, line   51
        ldur      q3, [x1, #-0x10]                        ; 0x00000034, line   52
        ldr       q23, [x0, #0x390]                       ; 0x00000038, line   53
        ldr       q13, [x0, #0x380]                       ; 0x0000003C, line   54
        ldr       q22, [x0, #0x80]                        ; 0x00000040, line   55
        ldr       q26, [x0, #0x190]                       ; 0x00000044, line   56
        ldr       q8, [x0, #0x280]                        ; 0x00000048, line   57
        ldr       q6, [x0, #0x210]                        ; 0x0000004C, line   58

        ; ---------------------------------------------------------------------------
        ; Phase 1 butterfly block (pre-loop, first group of two iterations)
        ;
        ;   Each line pair  mul / sqrdmulh  followed by  mls  implements a single
        ;   Montgomery multiplication:  t = monty_mul(a, zeta)
        ;
        ;   The NTT butterfly for one level is then:
        ;     b' = b + t           (add)
        ;     a' = b - t           (sub)
        ;
        ;   Layer 1 butterfly distance = 128 coefficients = 0x200 bytes
        ;   Layer 2 butterfly distance =  64 coefficients = 0x100 bytes
        ;   Layer 3 butterfly distance =  32 coefficients = 0x080 bytes
        ;
        ;   Four coefficients are processed in parallel per NEON vector (v*.4s).
        ; ---------------------------------------------------------------------------
        mul       v10.4s, v13.4s, v0.s[0]                 ; 0x00000050, line   59
        sqrdmulh  v13.4s, v13.4s, v0.s[1]                 ; 0x00000054, line   60
        mul       v12.4s, v8.4s, v0.s[0]                  ; 0x00000058, line   61
        sqrdmulh  v27.4s, v8.4s, v0.s[1]                  ; 0x0000005C, line   62
        mul       v4.4s, v6.4s, v0.s[0]                   ; 0x00000060, line   63
        mls       v10.4s, v13.4s, v7.s[0]                 ; 0x00000064, line   64
        ldr       q13, [x0, #0x180]                       ; 0x00000068, line   65
        sqrdmulh  v14.4s, v23.4s, v0.s[1]                 ; 0x0000006C, line   66
        mls       v12.4s, v27.4s, v7.s[0]                 ; 0x00000070, line   67
        add       v31.4s, v13.4s, v10.4s                  ; 0x00000074, line   68
        sub       v13.4s, v13.4s, v10.4s                  ; 0x00000078, line   69
        mul       v10.4s, v23.4s, v0.s[0]                 ; 0x0000007C, line   70
        sqrdmulh  v8.4s, v13.4s, v1.s[1]                  ; 0x00000080, line   71
        sub       v18.4s, v22.4s, v12.4s                  ; 0x00000084, line   72
        mls       v10.4s, v14.4s, v7.s[0]                 ; 0x00000088, line   73
        mul       v13.4s, v13.4s, v1.s[0]                 ; 0x0000008C, line   74
        mls       v13.4s, v8.4s, v7.s[0]                  ; 0x00000090, line   75
        sub       v29.4s, v26.4s, v10.4s                  ; 0x00000094, line   76
        add       v25.4s, v26.4s, v10.4s                  ; 0x00000098, line   77
        mul       v10.4s, v31.4s, v0.s[2]                 ; 0x0000009C, line   78
        mul       v14.4s, v25.4s, v0.s[2]                 ; 0x000000A0, line   79
        add       v17.4s, v18.4s, v13.4s                  ; 0x000000A4, line   80
        sub       v15.4s, v18.4s, v13.4s                  ; 0x000000A8, line   81
        sqrdmulh  v13.4s, v31.4s, v0.s[3]                 ; 0x000000AC, line   82
        sqrdmulh  v20.4s, v15.4s, v3.s[1]                 ; 0x000000B0, line   83
        sqrdmulh  v5.4s, v17.4s, v2.s[3]                  ; 0x000000B4, line   84
        mls       v10.4s, v13.4s, v7.s[0]                 ; 0x000000B8, line   85
        ldr       q13, [x0, #0x300]                       ; 0x000000BC, line   86
        mul       v18.4s, v17.4s, v2.s[2]                 ; 0x000000C0, line   87
        add       v31.4s, v22.4s, v12.4s                  ; 0x000000C4, line   88
        mul       v23.4s, v15.4s, v3.s[0]                 ; 0x000000C8, line   89
        ldr       q17, [x0, #0x90]                        ; 0x000000CC, line   90
        add       v19.4s, v31.4s, v10.4s                  ; 0x000000D0, line   91
        sub       v16.4s, v31.4s, v10.4s                  ; 0x000000D4, line   92
        mul       v10.4s, v13.4s, v0.s[0]                 ; 0x000000D8, line   93
        sqrdmulh  v13.4s, v13.4s, v0.s[1]                 ; 0x000000DC, line   94
        sqrdmulh  v27.4s, v16.4s, v2.s[1]                 ; 0x000000E0, line   95
        mul       v11.4s, v16.4s, v2.s[0]                 ; 0x000000E4, line   96
        mls       v10.4s, v13.4s, v7.s[0]                 ; 0x000000E8, line   97
        ldr       q13, [x0, #0x290]                       ; 0x000000EC, line   98
        ldr       q22, [x0, #0x100]                       ; 0x000000F0, line   99
        mls       v11.4s, v27.4s, v7.s[0]                 ; 0x000000F4, line  100
        sqrdmulh  v15.4s, v13.4s, v0.s[1]                 ; 0x000000F8, line  101
        sub       v12.4s, v22.4s, v10.4s                  ; 0x000000FC, line  102
        add       v30.4s, v22.4s, v10.4s                  ; 0x00000100, line  103
        mul       v10.4s, v13.4s, v0.s[0]                 ; 0x00000104, line  104
        ldr       q28, [x0]                               ; 0x00000108, line  105
        sqrdmulh  v13.4s, v25.4s, v0.s[3]                 ; 0x0000010C, line  106
        sqrdmulh  v27.4s, v30.4s, v0.s[3]                 ; 0x00000110, line  107
        mls       v10.4s, v15.4s, v7.s[0]                 ; 0x00000114, line  108
        mls       v14.4s, v13.4s, v7.s[0]                 ; 0x00000118, line  109
        ldr       q13, [x0, #0x200]                       ; 0x0000011C, line  110
        sqrdmulh  v25.4s, v12.4s, v1.s[1]                 ; 0x00000120, line  111
        add       v24.4s, v17.4s, v10.4s                  ; 0x00000124, line  112
        sub       v21.4s, v17.4s, v10.4s                  ; 0x00000128, line  113
        sqrdmulh  v8.4s, v13.4s, v0.s[1]                  ; 0x0000012C, line  114
        sub       v9.4s, v24.4s, v14.4s                   ; 0x00000130, line  115
        mul       v26.4s, v12.4s, v1.s[0]                 ; 0x00000134, line  116
        mul       v13.4s, v13.4s, v0.s[0]                 ; 0x00000138, line  117
        mls       v13.4s, v8.4s, v7.s[0]                  ; 0x0000013C, line  118
        mul       v8.4s, v30.4s, v0.s[2]                  ; 0x00000140, line  119
        mls       v8.4s, v27.4s, v7.s[0]                  ; 0x00000144, line  120
        add       v16.4s, v28.4s, v13.4s                  ; 0x00000148, line  121
        sub       v10.4s, v28.4s, v13.4s                  ; 0x0000014C, line  122
        mls       v26.4s, v25.4s, v7.s[0]                 ; 0x00000150, line  123
        sqrdmulh  v12.4s, v19.4s, v1.s[3]                 ; 0x00000154, line  124
        sub       v25.4s, v16.4s, v8.4s                   ; 0x00000158, line  125
        mls       v23.4s, v20.4s, v7.s[0]                 ; 0x0000015C, line  126
        sub       v22.4s, v25.4s, v11.4s                  ; 0x00000160, line  127
        sqrdmulh  v20.4s, v9.4s, v2.s[1]                  ; 0x00000164, line  128
        sub       v15.4s, v10.4s, v26.4s                  ; 0x00000168, line  129
        sub       x4, x4, #0x2                            ; 0x0000016C, line  130  x4 -= 2 (two iterations already done above)

        ; ---------------------------------------------------------------------------
        ; Layer 1-3 main loop  (Lmld_ntt_layer123_start)
        ;
        ;   Iterates x4 times (initial value after pre-loop: 6).
        ;   Each iteration processes one 32-coefficient group (four NEON registers)
        ;   through layers 1, 2, and 3 simultaneously, interleaved for throughput.
        ;
        ;   On entry to each iteration:
        ;     v13/v22/v26/v8/v6/v28/v17 hold coefficient vectors
        ;     v0-v3 hold the corresponding zeta vectors for this group
        ;     x0 points to the current output slice (advances by 0x10 per iteration)
        ;     x1 points to the next twiddle block (auto-incremented every 8 iter.)
        ;
        ;   Mid-loop stores (str qXX, [x0, #off]) write completed butterfly results
        ;   back to r[] as soon as they are no longer needed, overlapping with
        ;   the next group's computation.
        ; ---------------------------------------------------------------------------
Lmld_ntt_layer123_start

        add       v31.4s, v10.4s, v26.4s                  ; 0x00000170, line  133
        mul       v17.4s, v19.4s, v1.s[2]                 ; 0x00000174, line  134
        add       v26.4s, v15.4s, v23.4s                  ; 0x00000178, line  135
        ldr       q30, [x0, #0x2a0]                       ; 0x0000017C, line  136
        sub       v13.4s, v15.4s, v23.4s                  ; 0x00000180, line  137
        mul       v23.4s, v29.4s, v1.s[0]                 ; 0x00000184, line  138
        add       v25.4s, v25.4s, v11.4s                  ; 0x00000188, line  139
        str       q22, [x0, #0x180]                       ; 0x0000018C, line  140
        mul       v11.4s, v9.4s, v2.s[0]                  ; 0x00000190, line  141
        str       q13, [x0, #0x380]                       ; 0x00000194, line  142
        ldr       q28, [x0, #0x10]                        ; 0x00000198, line  143
        add       v10.4s, v16.4s, v8.4s                   ; 0x0000019C, line  144
        mls       v17.4s, v12.4s, v7.s[0]                 ; 0x000001A0, line  145
        ldr       q13, [x0, #0x3a0]                       ; 0x000001A4, line  146
        str       q26, [x0, #0x300]                       ; 0x000001A8, line  147
        sqrdmulh  v27.4s, v30.4s, v0.s[1]                 ; 0x000001AC, line  148
        mls       v18.4s, v5.4s, v7.s[0]                  ; 0x000001B0, line  149
        ldr       q9, [x0, #0x1a0]                        ; 0x000001B4, line  150
        sub       v16.4s, v10.4s, v17.4s                  ; 0x000001B8, line  151
        add       v15.4s, v10.4s, v17.4s                  ; 0x000001BC, line  152
        sqrdmulh  v10.4s, v6.4s, v0.s[1]                  ; 0x000001C0, line  153
        str       q16, [x0, #0x80]                        ; 0x000001C4, line  154
        str       q15, [x0], #0x10                        ; 0x000001C8, line  155
        sqrdmulh  v19.4s, v13.4s, v0.s[1]                 ; 0x000001CC, line  156
        sub       v15.4s, v31.4s, v18.4s                  ; 0x000001D0, line  157
        mul       v8.4s, v13.4s, v0.s[0]                  ; 0x000001D4, line  158
        add       v26.4s, v31.4s, v18.4s                  ; 0x000001D8, line  159
        str       q15, [x0, #0x270]                       ; 0x000001DC, line  160
        sqrdmulh  v13.4s, v29.4s, v1.s[1]                 ; 0x000001E0, line  161
        str       q26, [x0, #0x1f0]                       ; 0x000001E4, line  162
        mls       v8.4s, v19.4s, v7.s[0]                  ; 0x000001E8, line  163
        mls       v11.4s, v20.4s, v7.s[0]                 ; 0x000001EC, line  164
        mls       v23.4s, v13.4s, v7.s[0]                 ; 0x000001F0, line  165
        add       v22.4s, v9.4s, v8.4s                    ; 0x000001F4, line  166
        ldr       q6, [x0, #0x210]                        ; 0x000001F8, line  167
        sub       v29.4s, v9.4s, v8.4s                    ; 0x000001FC, line  168
        mul       v17.4s, v30.4s, v0.s[0]                 ; 0x00000200, line  169
        ldr       q9, [x0, #0x300]                        ; 0x00000204, line  170
        sqrdmulh  v13.4s, v22.4s, v0.s[3]                 ; 0x00000208, line  171
        add       v18.4s, v21.4s, v23.4s                  ; 0x0000020C, line  172
        mls       v4.4s, v10.4s, v7.s[0]                  ; 0x00000210, line  173
        sub       v31.4s, v21.4s, v23.4s                  ; 0x00000214, line  174
        sqrdmulh  v16.4s, v31.4s, v3.s[1]                 ; 0x00000218, line  175
        add       v19.4s, v24.4s, v14.4s                  ; 0x0000021C, line  176
        mul       v14.4s, v22.4s, v0.s[2]                 ; 0x00000220, line  177
        sub       v10.4s, v28.4s, v4.4s                   ; 0x00000224, line  178
        mls       v14.4s, v13.4s, v7.s[0]                 ; 0x00000228, line  179
        ldr       q13, [x0, #0x100]                       ; 0x0000022C, line  180
        sqrdmulh  v22.4s, v9.4s, v0.s[1]                  ; 0x00000230, line  181
        mul       v8.4s, v9.4s, v0.s[0]                   ; 0x00000234, line  182
        mul       v23.4s, v31.4s, v3.s[0]                 ; 0x00000238, line  183
        mls       v8.4s, v22.4s, v7.s[0]                  ; 0x0000023C, line  184
        mls       v23.4s, v16.4s, v7.s[0]                 ; 0x00000240, line  185
        add       v16.4s, v28.4s, v4.4s                   ; 0x00000244, line  186
        ldr       q22, [x0, #0x90]                        ; 0x00000248, line  187
        mul       v4.4s, v6.4s, v0.s[0]                   ; 0x0000024C, line  188
        mls       v17.4s, v27.4s, v7.s[0]                 ; 0x00000250, line  189
        add       v21.4s, v13.4s, v8.4s                   ; 0x00000254, line  190
        sub       v27.4s, v13.4s, v8.4s                   ; 0x00000258, line  191
        sqrdmulh  v31.4s, v21.4s, v0.s[3]                 ; 0x0000025C, line  192
        str       q25, [x0, #0xf0]                        ; 0x00000260, line  193
        mul       v8.4s, v21.4s, v0.s[2]                  ; 0x00000264, line  194
        add       v24.4s, v22.4s, v17.4s                  ; 0x00000268, line  195
        sub       v21.4s, v22.4s, v17.4s                  ; 0x0000026C, line  196
        sqrdmulh  v5.4s, v18.4s, v2.s[3]                  ; 0x00000270, line  197
        mls       v8.4s, v31.4s, v7.s[0]                  ; 0x00000274, line  198
        sub       v9.4s, v24.4s, v14.4s                   ; 0x00000278, line  199
        sqrdmulh  v20.4s, v27.4s, v1.s[1]                 ; 0x0000027C, line  200
        mul       v26.4s, v27.4s, v1.s[0]                 ; 0x00000280, line  201
        sub       v25.4s, v16.4s, v8.4s                   ; 0x00000284, line  202
        mul       v18.4s, v18.4s, v2.s[2]                 ; 0x00000288, line  203
        sub       v22.4s, v25.4s, v11.4s                  ; 0x0000028C, line  204
        mls       v26.4s, v20.4s, v7.s[0]                 ; 0x00000290, line  205
        sqrdmulh  v20.4s, v9.4s, v2.s[1]                  ; 0x00000294, line  206
        sqrdmulh  v12.4s, v19.4s, v1.s[3]                 ; 0x00000298, line  207
        sub       v15.4s, v10.4s, v26.4s                  ; 0x0000029C, line  208
        subs      x4, x4, #0x1                            ; 0x000002A0, line  209  decrement loop counter
        cbnz      x4, Lmld_ntt_layer123_start             ; 0x000002A4, line  210  loop if x4 != 0

        ; ---------------------------------------------------------------------------
        ; Layer 1-3 post-loop tail  --  finalize last group and flush remaining stores
        ;
        ;   The last iteration's butterfly results (v13,v15,v18,v22,v23,v26 etc.)
        ;   are completed here without branching back into the loop body.
        ;   After the stores, x0 is reset to the base address x3 and x4 is reloaded
        ;   to 8 to begin the layer 4-8 pass.
        ; ---------------------------------------------------------------------------
        add       v13.4s, v10.4s, v26.4s                  ; 0x000002A8, line  211
        mls       v18.4s, v5.4s, v7.s[0]                  ; 0x000002AC, line  212
        str       q22, [x0, #0x180]                       ; 0x000002B0, line  213
        add       v27.4s, v16.4s, v8.4s                   ; 0x000002B4, line  214
        mul       v22.4s, v19.4s, v1.s[2]                 ; 0x000002B8, line  215
        add       v26.4s, v24.4s, v14.4s                  ; 0x000002BC, line  216
        ldr       q31, [x0, #0x110]                       ; 0x000002C0, line  217
        sub       v14.4s, v15.4s, v23.4s                  ; 0x000002C4, line  218
        add       v17.4s, v15.4s, v23.4s                  ; 0x000002C8, line  219
        mls       v22.4s, v12.4s, v7.s[0]                 ; 0x000002CC, line  220
        add       v28.4s, v13.4s, v18.4s                  ; 0x000002D0, line  221
        str       q14, [x0, #0x380]                       ; 0x000002D4, line  222
        sqrdmulh  v24.4s, v6.4s, v0.s[1]                  ; 0x000002D8, line  223
        add       v5.4s, v25.4s, v11.4s                   ; 0x000002DC, line  224
        sub       v19.4s, v13.4s, v18.4s                  ; 0x000002E0, line  225
        str       q17, [x0, #0x300]                       ; 0x000002E4, line  226
        str       q5, [x0, #0x100]                        ; 0x000002E8, line  227
        mul       v16.4s, v9.4s, v2.s[0]                  ; 0x000002EC, line  228
        ldr       q18, [x0, #0x310]                       ; 0x000002F0, line  229
        str       q19, [x0, #0x280]                       ; 0x000002F4, line  230
        mls       v16.4s, v20.4s, v7.s[0]                 ; 0x000002F8, line  231
        str       q28, [x0, #0x200]                       ; 0x000002FC, line  232
        add       v13.4s, v27.4s, v22.4s                  ; 0x00000300, line  233
        ldr       q15, [x0, #0x10]                        ; 0x00000304, line  234
        sub       v10.4s, v27.4s, v22.4s                  ; 0x00000308, line  235
        mls       v4.4s, v24.4s, v7.s[0]                  ; 0x0000030C, line  236
        str       q13, [x0], #0x10                        ; 0x00000310, line  237
        str       q10, [x0, #0x70]                        ; 0x00000314, line  238
        sqrdmulh  v12.4s, v29.4s, v1.s[1]                 ; 0x00000318, line  239
        mul       v23.4s, v29.4s, v1.s[0]                 ; 0x0000031C, line  240
        mul       v8.4s, v26.4s, v1.s[2]                  ; 0x00000320, line  241
        add       v20.4s, v15.4s, v4.4s                   ; 0x00000324, line  242
        sub       v6.4s, v15.4s, v4.4s                    ; 0x00000328, line  243
        mls       v23.4s, v12.4s, v7.s[0]                 ; 0x0000032C, line  244
        sqrdmulh  v22.4s, v18.4s, v0.s[1]                 ; 0x00000330, line  245
        mul       v5.4s, v18.4s, v0.s[0]                  ; 0x00000334, line  246
        sub       v28.4s, v21.4s, v23.4s                  ; 0x00000338, line  247
        sqrdmulh  v10.4s, v26.4s, v1.s[3]                 ; 0x0000033C, line  248
        mls       v5.4s, v22.4s, v7.s[0]                  ; 0x00000340, line  249
        sqrdmulh  v30.4s, v28.4s, v3.s[1]                 ; 0x00000344, line  250
        add       v4.4s, v21.4s, v23.4s                   ; 0x00000348, line  251
        mls       v8.4s, v10.4s, v7.s[0]                  ; 0x0000034C, line  252
        add       v12.4s, v31.4s, v5.4s                   ; 0x00000350, line  253
        sub       v9.4s, v31.4s, v5.4s                    ; 0x00000354, line  254
        sqrdmulh  v25.4s, v4.4s, v2.s[3]                  ; 0x00000358, line  255
        sqrdmulh  v15.4s, v9.4s, v1.s[1]                  ; 0x0000035C, line  256
        sqrdmulh  v31.4s, v12.4s, v0.s[3]                 ; 0x00000360, line  257
        mul       v18.4s, v12.4s, v0.s[2]                 ; 0x00000364, line  258
        mul       v11.4s, v9.4s, v1.s[0]                  ; 0x00000368, line  259
        mls       v18.4s, v31.4s, v7.s[0]                 ; 0x0000036C, line  260
        mul       v29.4s, v4.4s, v2.s[2]                  ; 0x00000370, line  261
        mls       v29.4s, v25.4s, v7.s[0]                 ; 0x00000374, line  262
        add       v23.4s, v20.4s, v18.4s                  ; 0x00000378, line  263
        mls       v11.4s, v15.4s, v7.s[0]                 ; 0x0000037C, line  264
        sub       v31.4s, v20.4s, v18.4s                  ; 0x00000380, line  265
        add       v17.4s, v23.4s, v8.4s                   ; 0x00000384, line  266
        add       v5.4s, v31.4s, v16.4s                   ; 0x00000388, line  267
        mul       v24.4s, v28.4s, v3.s[0]                 ; 0x0000038C, line  268
        str       q17, [x0], #0x10                        ; 0x00000390, line  269
        sub       v19.4s, v31.4s, v16.4s                  ; 0x00000394, line  270
        mls       v24.4s, v30.4s, v7.s[0]                 ; 0x00000398, line  271
        str       q5, [x0, #0xf0]                         ; 0x0000039C, line  272
        add       v31.4s, v6.4s, v11.4s                   ; 0x000003A0, line  273
        sub       v26.4s, v23.4s, v8.4s                   ; 0x000003A4, line  274
        str       q19, [x0, #0x170]                       ; 0x000003A8, line  275
        add       v4.4s, v31.4s, v29.4s                   ; 0x000003AC, line  276
        sub       v13.4s, v6.4s, v11.4s                   ; 0x000003B0, line  277
        str       q26, [x0, #0x70]                        ; 0x000003B4, line  278
        sub       v11.4s, v31.4s, v29.4s                  ; 0x000003B8, line  279
        sub       v22.4s, v13.4s, v24.4s                  ; 0x000003BC, line  280
        add       v23.4s, v13.4s, v24.4s                  ; 0x000003C0, line  281
        str       q4, [x0, #0x1f0]                        ; 0x000003C4, line  282
        str       q11, [x0, #0x270]                       ; 0x000003C8, line  283
        str       q23, [x0, #0x2f0]                       ; 0x000003CC, line  284
        str       q22, [x0, #0x370]                       ; 0x000003D0, line  285
        ; ---------------------------------------------------------------------------
        ; Phase 2 setup  --  reset pointers and begin layer 4-8 pass
        ;
        ;   x0 is restored to the array base x3.
        ;   x4 = 8 for the layer 4-8 outer loop (8 groups of 32 coefficients).
        ;
        ;   Twiddle factors for layers 4-8 are loaded from two sources:
        ;     x1  -> zetas_l123456[] continuation (layers 4-6 per-group twiddles)
        ;     x2  -> zetas_l78[]   (layer 7-8 twiddles; 4-coefficient stride)
        ;
        ;   In contrast to layers 1-3, layers 7-8 require a bit-reversal transpose
        ;   of the coefficient layout.  The trn1/trn2 instructions (used later in
        ;   the loop body) perform this 4x4 transpose across two register pairs.
        ; ---------------------------------------------------------------------------
        mov       x0, x3                                  ; 0x000003D4, line  286  x0 = &r[0] (reset to array base)
        mov       x4, #0x8                                ; 0x000003D8, line  287  x4 = 8 (layer 4-8 iteration count)
        ldr       q9, [x0, #0x40]                         ; 0x000003DC, line  288
        ldr       q23, [x1], #0x40                        ; 0x000003E0, line  289
        ldr       q21, [x2, #0x60]                        ; 0x000003E4, line  290
        ldr       q1, [x0, #0x20]                         ; 0x000003E8, line  291
        ldur      q14, [x1, #-0x30]                       ; 0x000003EC, line  292
        ldr       q13, [x0]                               ; 0x000003F0, line  293
        ldr       q11, [x2, #0x50]                        ; 0x000003F4, line  294
        sqrdmulh  v16.4s, v9.4s, v23.s[1]                 ; 0x000003F8, line  295
        ldr       q17, [x0, #0x50]                        ; 0x000003FC, line  296
        mul       v15.4s, v9.4s, v23.s[0]                 ; 0x00000400, line  297
        ldr       q30, [x0, #0x70]                        ; 0x00000404, line  298
        ldr       q27, [x0, #0x60]                        ; 0x00000408, line  299
        ldr       q8, [x2, #0x30]                         ; 0x0000040C, line  300
        sqrdmulh  v12.4s, v17.4s, v23.s[1]                ; 0x00000410, line  301
        ldr       q6, [x0, #0x30]                         ; 0x00000414, line  302
        mls       v15.4s, v16.4s, v7.s[0]                 ; 0x00000418, line  303
        sqrdmulh  v18.4s, v27.4s, v23.s[1]                ; 0x0000041C, line  304
        sqrdmulh  v19.4s, v30.4s, v23.s[1]                ; 0x00000420, line  305
        add       v5.4s, v13.4s, v15.4s                   ; 0x00000424, line  306
        mul       v25.4s, v27.4s, v23.s[0]                ; 0x00000428, line  307
        sub       v26.4s, v13.4s, v15.4s                  ; 0x0000042C, line  308
        mls       v25.4s, v18.4s, v7.s[0]                 ; 0x00000430, line  309
        mul       v10.4s, v17.4s, v23.s[0]                ; 0x00000434, line  310
        mls       v10.4s, v12.4s, v7.s[0]                 ; 0x00000438, line  311
        mul       v4.4s, v30.4s, v23.s[0]                 ; 0x0000043C, line  312
        sub       v22.4s, v1.4s, v25.4s                   ; 0x00000440, line  313
        mls       v4.4s, v19.4s, v7.s[0]                  ; 0x00000444, line  314
        add       v28.4s, v1.4s, v25.4s                   ; 0x00000448, line  315
        sqrdmulh  v19.4s, v28.4s, v23.s[3]                ; 0x0000044C, line  316
        sqrdmulh  v9.4s, v22.4s, v14.s[1]                 ; 0x00000450, line  317
        add       v2.4s, v6.4s, v4.4s                     ; 0x00000454, line  318
        mul       v0.4s, v28.4s, v23.s[2]                 ; 0x00000458, line  319
        sqrdmulh  v27.4s, v2.4s, v23.s[3]                 ; 0x0000045C, line  320
        sub       v17.4s, v6.4s, v4.4s                    ; 0x00000460, line  321
        mul       v3.4s, v2.4s, v23.s[2]                  ; 0x00000464, line  322
        sqrdmulh  v20.4s, v17.4s, v14.s[1]                ; 0x00000468, line  323
        ldr       q1, [x0, #0x10]                         ; 0x0000046C, line  324
        mls       v3.4s, v27.4s, v7.s[0]                  ; 0x00000470, line  325
        mls       v0.4s, v19.4s, v7.s[0]                  ; 0x00000474, line  326
        ldur      q16, [x1, #-0x20]                       ; 0x00000478, line  327
        add       v31.4s, v1.4s, v10.4s                   ; 0x0000047C, line  328
        mul       v30.4s, v17.4s, v14.s[0]                ; 0x00000480, line  329
        mls       v30.4s, v20.4s, v7.s[0]                 ; 0x00000484, line  330
        add       v27.4s, v31.4s, v3.4s                   ; 0x00000488, line  331
        sub       v23.4s, v1.4s, v10.4s                   ; 0x0000048C, line  332
        sub       v24.4s, v31.4s, v3.4s                   ; 0x00000490, line  333
        sqrdmulh  v4.4s, v27.4s, v14.s[3]                 ; 0x00000494, line  334
        sqrdmulh  v10.4s, v24.4s, v16.s[1]                ; 0x00000498, line  335
        mul       v18.4s, v24.4s, v16.s[0]                ; 0x0000049C, line  336
        add       v15.4s, v23.4s, v30.4s                  ; 0x000004A0, line  337
        sub       v23.4s, v23.4s, v30.4s                  ; 0x000004A4, line  338
        mul       v29.4s, v27.4s, v14.s[2]                ; 0x000004A8, line  339
        sub       v2.4s, v5.4s, v0.4s                     ; 0x000004AC, line  340
        add       v12.4s, v5.4s, v0.4s                    ; 0x000004B0, line  341
        mls       v18.4s, v10.4s, v7.s[0]                 ; 0x000004B4, line  342
        ldur      q3, [x1, #-0x10]                        ; 0x000004B8, line  343
        mls       v29.4s, v4.4s, v7.s[0]                  ; 0x000004BC, line  344
        mul       v4.4s, v22.4s, v14.s[0]                 ; 0x000004C0, line  345
        add       v1.4s, v2.4s, v18.4s                    ; 0x000004C4, line  346
        sub       v24.4s, v2.4s, v18.4s                   ; 0x000004C8, line  347
        mls       v4.4s, v9.4s, v7.s[0]                   ; 0x000004CC, line  348
        ldr       q20, [x2, #0x10]                        ; 0x000004D0, line  349
        add       v25.4s, v12.4s, v29.4s                  ; 0x000004D4, line  350
        mul       v9.4s, v23.4s, v3.s[0]                  ; 0x000004D8, line  351
        sub       v5.4s, v12.4s, v29.4s                   ; 0x000004DC, line  352
        sqrdmulh  v31.4s, v23.4s, v3.s[1]                 ; 0x000004E0, line  353
        trn2      v6.4s, v1.4s, v24.4s                    ; 0x000004E4, line  354
        trn2      v10.4s, v25.4s, v5.4s                   ; 0x000004E8, line  355
        sqrdmulh  v13.4s, v15.4s, v16.s[3]                ; 0x000004EC, line  356
        trn2      v30.2d, v10.2d, v6.2d                   ; 0x000004F0, line  357
        ldr       q3, [x2], #0xc0                         ; 0x000004F4, line  358
        mul       v12.4s, v15.4s, v16.s[2]                ; 0x000004F8, line  359
        trn1      v27.2d, v10.2d, v6.2d                   ; 0x000004FC, line  360
        mls       v9.4s, v31.4s, v7.s[0]                  ; 0x00000500, line  361
        trn1      v22.4s, v25.4s, v5.4s                   ; 0x00000504, line  362
        sub       v6.4s, v26.4s, v4.4s                    ; 0x00000508, line  363
        mls       v12.4s, v13.4s, v7.s[0]                 ; 0x0000050C, line  364
        trn1      v1.4s, v1.4s, v24.4s                    ; 0x00000510, line  365
        add       v13.4s, v26.4s, v4.4s                   ; 0x00000514, line  366
        trn2      v10.2d, v22.2d, v1.2d                   ; 0x00000518, line  367
        mul       v28.4s, v30.4s, v3.4s                   ; 0x0000051C, line  368
        sub       v31.4s, v6.4s, v9.4s                    ; 0x00000520, line  369
        sub       x4, x4, #0x1                            ; 0x00000524, line  370  x4 -= 1 (one group pre-processed above)
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics
        HINT      #0x0                                    ; ALIGN 16; bug in armasm64.exe requires 'HINT' mnemonics

        ; ---------------------------------------------------------------------------
        ; Layer 4-8 main loop  (Lmld_ntt_layer45678_start)
        ;
        ;   Iterates x4 times (7 after pre-loop).
        ;   Each iteration processes one 32-coefficient group through layers 4-8.
        ;
        ;   Layer 4-6: standard butterfly using mul/sqrdmulh/mls Montgomery pattern
        ;              with twiddle scalars loaded from x1 (zetas_l123456).
        ;   Layer 7-8: paired twiddle vectors from x2 (zetas_l78).
        ;
        ;   Bit-reversal reordering for layers 7-8 is achieved via a series of
        ;   trn1/trn2 (4-way transpose) operations:
        ;     trn1/trn2 vA.4s, vB.4s, vC.4s  -- interleave within 64-bit lanes
        ;     trn1/trn2 vA.2d, vB.2d, vC.2d  -- interleave 64-bit lane pairs
        ;   Together these perform the 4x4 matrix transpose that maps the natural
        ;   order to the bit-reversed butterfly order required by layers 7 and 8.
        ;
        ;   Results are stored to r[] via str/stur as soon as register pressure
        ;   allows, advancing x0 by 0x80 (32 coefficients = 128 bytes) per group.
        ; ---------------------------------------------------------------------------
Lmld_ntt_layer45678_start

        add       v2.4s, v13.4s, v12.4s                   ; 0x00000530, line  373
        sqrdmulh  v5.4s, v30.4s, v20.4s                   ; 0x00000534, line  374
        sub       v25.4s, v13.4s, v12.4s                  ; 0x00000538, line  375
        add       v17.4s, v6.4s, v9.4s                    ; 0x0000053C, line  376
        mul       v19.4s, v10.4s, v3.4s                   ; 0x00000540, line  377
        trn2      v4.4s, v2.4s, v25.4s                    ; 0x00000544, line  378
        ldur      q24, [x2, #-0x50]                       ; 0x00000548, line  379
        trn2      v29.4s, v17.4s, v31.4s                  ; 0x0000054C, line  380
        sqrdmulh  v15.4s, v10.4s, v20.4s                  ; 0x00000550, line  381
        mls       v28.4s, v5.4s, v7.s[0]                  ; 0x00000554, line  382
        trn2      v3.2d, v4.2d, v29.2d                    ; 0x00000558, line  383
        sqrdmulh  v12.4s, v3.4s, v24.4s                   ; 0x0000055C, line  384
        mul       v16.4s, v3.4s, v21.4s                   ; 0x00000560, line  385
        mls       v19.4s, v15.4s, v7.s[0]                 ; 0x00000564, line  386
        ldur      q10, [x2, #-0xa0]                       ; 0x00000568, line  387
        add       v13.4s, v27.4s, v28.4s                  ; 0x0000056C, line  388
        mls       v16.4s, v12.4s, v7.s[0]                 ; 0x00000570, line  389
        sqrdmulh  v9.4s, v13.4s, v8.4s                    ; 0x00000574, line  390
        sub       v30.4s, v27.4s, v28.4s                  ; 0x00000578, line  391
        ldr       q18, [x1], #0x40                        ; 0x0000057C, line  392
        mul       v8.4s, v13.4s, v10.4s                   ; 0x00000580, line  393
        ldr       q10, [x0, #0xd0]                        ; 0x00000584, line  394
        sqrdmulh  v14.4s, v30.4s, v11.4s                  ; 0x00000588, line  395
        ldr       q23, [x0, #0xe0]                        ; 0x0000058C, line  396
        sqrdmulh  v13.4s, v10.4s, v18.s[1]                ; 0x00000590, line  397
        sqrdmulh  v12.4s, v23.4s, v18.s[1]                ; 0x00000594, line  398
        ldur      q6, [x2, #-0x80]                        ; 0x00000598, line  399
        mul       v3.4s, v10.4s, v18.s[0]                 ; 0x0000059C, line  400
        mls       v3.4s, v13.4s, v7.s[0]                  ; 0x000005A0, line  401
        ldr       q13, [x0, #0xf0]                        ; 0x000005A4, line  402
        trn1      v27.4s, v2.4s, v25.4s                   ; 0x000005A8, line  403
        mul       v2.4s, v30.4s, v6.4s                    ; 0x000005AC, line  404
        trn1      v20.4s, v17.4s, v31.4s                  ; 0x000005B0, line  405
        trn1      v25.2d, v4.2d, v29.2d                   ; 0x000005B4, line  406
        sqrdmulh  v10.4s, v13.4s, v18.s[1]                ; 0x000005B8, line  407
        trn2      v5.2d, v27.2d, v20.2d                   ; 0x000005BC, line  408
        ldur      q6, [x2, #-0x10]                        ; 0x000005C0, line  409
        mls       v8.4s, v9.4s, v7.s[0]                   ; 0x000005C4, line  410
        sub       v15.4s, v25.4s, v16.4s                  ; 0x000005C8, line  411
        sqrdmulh  v31.4s, v5.4s, v24.4s                   ; 0x000005CC, line  412
        sqrdmulh  v30.4s, v15.4s, v6.4s                   ; 0x000005D0, line  413
        ldur      q9, [x2, #-0x30]                        ; 0x000005D4, line  414
        mul       v4.4s, v5.4s, v21.4s                    ; 0x000005D8, line  415
        ldur      q21, [x2, #-0x40]                       ; 0x000005DC, line  416
        ldur      q6, [x2, #-0x20]                        ; 0x000005E0, line  417
        add       v5.4s, v25.4s, v16.4s                   ; 0x000005E4, line  418
        mls       v4.4s, v31.4s, v7.s[0]                  ; 0x000005E8, line  419
        mul       v0.4s, v5.4s, v21.4s                    ; 0x000005EC, line  420
        mul       v17.4s, v13.4s, v18.s[0]                ; 0x000005F0, line  421
        mls       v17.4s, v10.4s, v7.s[0]                 ; 0x000005F4, line  422
        ldr       q28, [x0, #0xb0]                        ; 0x000005F8, line  423
        sqrdmulh  v26.4s, v5.4s, v9.4s                    ; 0x000005FC, line  424
        mul       v9.4s, v15.4s, v6.4s                    ; 0x00000600, line  425
        trn1      v6.2d, v22.2d, v1.2d                    ; 0x00000604, line  426
        mls       v9.4s, v30.4s, v7.s[0]                  ; 0x00000608, line  427
        add       v25.4s, v28.4s, v17.4s                  ; 0x0000060C, line  428
        mls       v2.4s, v14.4s, v7.s[0]                  ; 0x00000610, line  429
        trn1      v5.2d, v27.2d, v20.2d                   ; 0x00000614, line  430
        ldr       q20, [x2, #0x10]                        ; 0x00000618, line  431
        mul       v29.4s, v25.4s, v18.s[2]                ; 0x0000061C, line  432
        add       v15.4s, v6.4s, v19.4s                   ; 0x00000620, line  433
        ldr       q30, [x0, #0xc0]                        ; 0x00000624, line  434
        sub       v19.4s, v6.4s, v19.4s                   ; 0x00000628, line  435
        add       v31.4s, v15.4s, v8.4s                   ; 0x0000062C, line  436
        mls       v0.4s, v26.4s, v7.s[0]                  ; 0x00000630, line  437
        ldur      q14, [x1, #-0x30]                       ; 0x00000634, line  438
        add       v21.4s, v19.4s, v2.4s                   ; 0x00000638, line  439
        sub       v24.4s, v19.4s, v2.4s                   ; 0x0000063C, line  440
        sqrdmulh  v27.4s, v25.4s, v18.s[3]                ; 0x00000640, line  441
        sub       v26.4s, v15.4s, v8.4s                   ; 0x00000644, line  442
        ldr       q2, [x0, #0x90]                         ; 0x00000648, line  443
        mul       v16.4s, v30.4s, v18.s[0]                ; 0x0000064C, line  444
        sub       v25.4s, v28.4s, v17.4s                  ; 0x00000650, line  445
        trn1      v11.4s, v31.4s, v26.4s                  ; 0x00000654, line  446
        ldr       q1, [x0, #0xa0]                         ; 0x00000658, line  447
        trn1      v6.4s, v21.4s, v24.4s                   ; 0x0000065C, line  448
        sqrdmulh  v13.4s, v25.4s, v14.s[1]                ; 0x00000660, line  449
        add       v8.4s, v2.4s, v3.4s                     ; 0x00000664, line  450
        trn2      v28.2d, v11.2d, v6.2d                   ; 0x00000668, line  451
        sqrdmulh  v19.4s, v30.4s, v18.s[1]                ; 0x0000066C, line  452
        sub       v10.4s, v5.4s, v4.4s                    ; 0x00000670, line  453
        ldur      q22, [x1, #-0x20]                       ; 0x00000674, line  454
        str       q28, [x0, #0x20]                        ; 0x00000678, line  455
        mls       v29.4s, v27.4s, v7.s[0]                 ; 0x0000067C, line  456
        add       v15.4s, v10.4s, v9.4s                   ; 0x00000680, line  457
        mul       v25.4s, v25.4s, v14.s[0]                ; 0x00000684, line  458
        ldur      q27, [x1, #-0x10]                       ; 0x00000688, line  459
        trn2      v17.4s, v31.4s, v26.4s                  ; 0x0000068C, line  460
        trn2      v21.4s, v21.4s, v24.4s                  ; 0x00000690, line  461
        mls       v16.4s, v19.4s, v7.s[0]                 ; 0x00000694, line  462
        sub       v24.4s, v8.4s, v29.4s                   ; 0x00000698, line  463
        sub       v10.4s, v10.4s, v9.4s                   ; 0x0000069C, line  464
        mls       v25.4s, v13.4s, v7.s[0]                 ; 0x000006A0, line  465
        trn1      v13.2d, v11.2d, v6.2d                   ; 0x000006A4, line  466
        ldr       q28, [x0, #0x80]                        ; 0x000006A8, line  467
        sqrdmulh  v30.4s, v24.4s, v22.s[1]                ; 0x000006AC, line  468
        trn2      v19.2d, v17.2d, v21.2d                  ; 0x000006B0, line  469
        trn1      v6.2d, v17.2d, v21.2d                   ; 0x000006B4, line  470
        mul       v31.4s, v23.4s, v18.s[0]                ; 0x000006B8, line  471
        str       q13, [x0], #0x80                        ; 0x000006BC, line  472
        stur      q6, [x0, #-0x70]                        ; 0x000006C0, line  473
        stur      q19, [x0, #-0x50]                       ; 0x000006C4, line  474
        ldr       q11, [x2, #0x50]                        ; 0x000006C8, line  475
        mls       v31.4s, v12.4s, v7.s[0]                 ; 0x000006CC, line  476
        ldr       q21, [x2, #0x60]                        ; 0x000006D0, line  477
        trn1      v9.4s, v15.4s, v10.4s                   ; 0x000006D4, line  478
        trn2      v6.4s, v15.4s, v10.4s                   ; 0x000006D8, line  479
        mul       v24.4s, v24.4s, v22.s[0]                ; 0x000006DC, line  480
        sub       v10.4s, v2.4s, v3.4s                    ; 0x000006E0, line  481
        ldr       q3, [x2], #0xc0                         ; 0x000006E4, line  482
        mls       v24.4s, v30.4s, v7.s[0]                 ; 0x000006E8, line  483
        add       v26.4s, v8.4s, v29.4s                   ; 0x000006EC, line  484
        ldur      q8, [x2, #-0x90]                        ; 0x000006F0, line  485
        add       v17.4s, v5.4s, v4.4s                    ; 0x000006F4, line  486
        sqrdmulh  v2.4s, v26.4s, v14.s[3]                 ; 0x000006F8, line  487
        sub       v13.4s, v1.4s, v31.4s                   ; 0x000006FC, line  488
        add       v30.4s, v1.4s, v31.4s                   ; 0x00000700, line  489
        add       v15.4s, v10.4s, v25.4s                  ; 0x00000704, line  490
        sqrdmulh  v19.4s, v13.4s, v14.s[1]                ; 0x00000708, line  491
        sub       v25.4s, v10.4s, v25.4s                  ; 0x0000070C, line  492
        mul       v29.4s, v13.4s, v14.s[0]                ; 0x00000710, line  493
        sub       v5.4s, v28.4s, v16.4s                   ; 0x00000714, line  494
        sqrdmulh  v4.4s, v30.4s, v18.s[3]                 ; 0x00000718, line  495
        sub       v23.4s, v17.4s, v0.4s                   ; 0x0000071C, line  496
        add       v31.4s, v17.4s, v0.4s                   ; 0x00000720, line  497
        mul       v18.4s, v30.4s, v18.s[2]                ; 0x00000724, line  498
        add       v1.4s, v28.4s, v16.4s                   ; 0x00000728, line  499
        trn2      v12.4s, v31.4s, v23.4s                  ; 0x0000072C, line  500
        mls       v29.4s, v19.4s, v7.s[0]                 ; 0x00000730, line  501
        trn1      v13.4s, v31.4s, v23.4s                  ; 0x00000734, line  502
        trn2      v30.2d, v12.2d, v6.2d                   ; 0x00000738, line  503
        mls       v18.4s, v4.4s, v7.s[0]                  ; 0x0000073C, line  504
        trn2      v10.2d, v13.2d, v9.2d                   ; 0x00000740, line  505
        trn1      v31.2d, v13.2d, v9.2d                   ; 0x00000744, line  506
        mul       v19.4s, v26.4s, v14.s[2]                ; 0x00000748, line  507
        trn1      v12.2d, v12.2d, v6.2d                   ; 0x0000074C, line  508
        sub       v6.4s, v5.4s, v29.4s                    ; 0x00000750, line  509
        mls       v19.4s, v2.4s, v7.s[0]                  ; 0x00000754, line  510
        add       v13.4s, v5.4s, v29.4s                   ; 0x00000758, line  511
        stur      q10, [x0, #-0x20]                       ; 0x0000075C, line  512
        sub       v10.4s, v1.4s, v18.4s                   ; 0x00000760, line  513
        add       v28.4s, v1.4s, v18.4s                   ; 0x00000764, line  514
        sqrdmulh  v5.4s, v25.4s, v27.s[1]                 ; 0x00000768, line  515
        stur      q31, [x0, #-0x40]                       ; 0x0000076C, line  516
        add       v26.4s, v10.4s, v24.4s                  ; 0x00000770, line  517
        sub       v31.4s, v10.4s, v24.4s                  ; 0x00000774, line  518
        mul       v9.4s, v25.4s, v27.s[0]                 ; 0x00000778, line  519
        stur      q12, [x0, #-0x30]                       ; 0x0000077C, line  520
        sub       v24.4s, v28.4s, v19.4s                  ; 0x00000780, line  521
        sqrdmulh  v10.4s, v15.4s, v22.s[3]                ; 0x00000784, line  522
        trn1      v1.4s, v26.4s, v31.4s                   ; 0x00000788, line  523
        stur      q30, [x0, #-0x10]                       ; 0x0000078C, line  524
        add       v30.4s, v28.4s, v19.4s                  ; 0x00000790, line  525
        mls       v9.4s, v5.4s, v7.s[0]                   ; 0x00000794, line  526
        trn2      v25.4s, v26.4s, v31.4s                  ; 0x00000798, line  527
        trn2      v14.4s, v30.4s, v24.4s                  ; 0x0000079C, line  528
        mul       v12.4s, v15.4s, v22.s[2]                ; 0x000007A0, line  529
        trn1      v22.4s, v30.4s, v24.4s                  ; 0x000007A4, line  530
        trn1      v27.2d, v14.2d, v25.2d                  ; 0x000007A8, line  531
        mls       v12.4s, v10.4s, v7.s[0]                 ; 0x000007AC, line  532
        trn2      v30.2d, v14.2d, v25.2d                  ; 0x000007B0, line  533
        sub       v31.4s, v6.4s, v9.4s                    ; 0x000007B4, line  534
        trn2      v10.2d, v22.2d, v1.2d                   ; 0x000007B8, line  535
        mul       v28.4s, v30.4s, v3.4s                   ; 0x000007BC, line  536
        subs      x4, x4, #0x1                            ; 0x000007C0, line  537  decrement loop counter
        cbnz      x4, Lmld_ntt_layer45678_start           ; 0x000007C4, line  538  loop if x4 != 0

        ; ---------------------------------------------------------------------------
        ; Layer 4-8 post-loop tail  --  process final group and write output
        ;
        ;   The last butterfly round (layer 8) for the final coefficient group
        ;   is completed here.  This includes:
        ;     - Final Montgomery multiplications for layer 8 twiddles
        ;     - Four-level trn1/trn2 transpose sequence producing bit-reversed order
        ;     - Sequential stur instructions writing the 8 output vectors
        ;       (32 coefficients) back to r[] at stride [x0-0x70]..[x0]
        ;
        ;   After the last stur the NTT result for all 256 coefficients is
        ;   fully written to r[] in correct bit-reversed NTT order.
        ; ---------------------------------------------------------------------------
        add       v9.4s, v6.4s, v9.4s                     ; 0x000007C8, line  539
        sqrdmulh  v6.4s, v30.4s, v20.4s                   ; 0x000007CC, line  540
        ldur      q24, [x2, #-0xa0]                       ; 0x000007D0, line  541
        add       v25.4s, v13.4s, v12.4s                  ; 0x000007D4, line  542
        sub       v15.4s, v13.4s, v12.4s                  ; 0x000007D8, line  543
        mul       v19.4s, v10.4s, v3.4s                   ; 0x000007DC, line  544
        trn2      v5.4s, v9.4s, v31.4s                    ; 0x000007E0, line  545
        sqrdmulh  v3.4s, v10.4s, v20.4s                   ; 0x000007E4, line  546
        trn2      v10.4s, v25.4s, v15.4s                  ; 0x000007E8, line  547
        mls       v28.4s, v6.4s, v7.s[0]                  ; 0x000007EC, line  548
        trn2      v13.2d, v10.2d, v5.2d                   ; 0x000007F0, line  549
        ldur      q30, [x2, #-0x50]                       ; 0x000007F4, line  550
        mul       v12.4s, v13.4s, v21.4s                  ; 0x000007F8, line  551
        mls       v19.4s, v3.4s, v7.s[0]                  ; 0x000007FC, line  552
        add       v20.4s, v27.4s, v28.4s                  ; 0x00000800, line  553
        sqrdmulh  v13.4s, v13.4s, v30.4s                  ; 0x00000804, line  554
        sub       v3.4s, v27.4s, v28.4s                   ; 0x00000808, line  555
        mul       v24.4s, v20.4s, v24.4s                  ; 0x0000080C, line  556
        sqrdmulh  v6.4s, v3.4s, v11.4s                    ; 0x00000810, line  557
        ldur      q27, [x2, #-0x80]                       ; 0x00000814, line  558
        mls       v12.4s, v13.4s, v7.s[0]                 ; 0x00000818, line  559
        trn1      v25.4s, v25.4s, v15.4s                  ; 0x0000081C, line  560
        mul       v27.4s, v3.4s, v27.4s                   ; 0x00000820, line  561
        trn1      v31.4s, v9.4s, v31.4s                   ; 0x00000824, line  562
        trn1      v3.2d, v10.2d, v5.2d                    ; 0x00000828, line  563
        ldur      q13, [x2, #-0x30]                       ; 0x0000082C, line  564
        ldur      q15, [x2, #-0x40]                       ; 0x00000830, line  565
        sqrdmulh  v9.4s, v20.4s, v8.4s                    ; 0x00000834, line  566
        trn2      v20.2d, v25.2d, v31.2d                  ; 0x00000838, line  567
        ldur      q10, [x2, #-0x10]                       ; 0x0000083C, line  568
        mls       v27.4s, v6.4s, v7.s[0]                  ; 0x00000840, line  569
        add       v5.4s, v3.4s, v12.4s                    ; 0x00000844, line  570
        sub       v6.4s, v3.4s, v12.4s                    ; 0x00000848, line  571
        sqrdmulh  v3.4s, v20.4s, v30.4s                   ; 0x0000084C, line  572
        trn1      v12.2d, v22.2d, v1.2d                   ; 0x00000850, line  573
        sqrdmulh  v10.4s, v6.4s, v10.4s                   ; 0x00000854, line  574
        mls       v24.4s, v9.4s, v7.s[0]                  ; 0x00000858, line  575
        sub       v9.4s, v12.4s, v19.4s                   ; 0x0000085C, line  576
        trn1      v25.2d, v25.2d, v31.2d                  ; 0x00000860, line  577
        sqrdmulh  v31.4s, v5.4s, v13.4s                   ; 0x00000864, line  578
        add       v30.4s, v9.4s, v27.4s                   ; 0x00000868, line  579
        add       v13.4s, v12.4s, v19.4s                  ; 0x0000086C, line  580
        mul       v1.4s, v20.4s, v21.4s                   ; 0x00000870, line  581
        ldur      q12, [x2, #-0x20]                       ; 0x00000874, line  582
        add       v21.4s, v13.4s, v24.4s                  ; 0x00000878, line  583
        sub       v13.4s, v13.4s, v24.4s                  ; 0x0000087C, line  584
        mls       v1.4s, v3.4s, v7.s[0]                   ; 0x00000880, line  585
        sub       v3.4s, v9.4s, v27.4s                    ; 0x00000884, line  586
        mul       v9.4s, v6.4s, v12.4s                    ; 0x00000888, line  587
        trn2      v12.4s, v21.4s, v13.4s                  ; 0x0000088C, line  588
        trn1      v6.4s, v30.4s, v3.4s                    ; 0x00000890, line  589
        trn2      v30.4s, v30.4s, v3.4s                   ; 0x00000894, line  590
        mls       v9.4s, v10.4s, v7.s[0]                  ; 0x00000898, line  591
        trn1      v13.4s, v21.4s, v13.4s                  ; 0x0000089C, line  592
        mul       v15.4s, v5.4s, v15.4s                   ; 0x000008A0, line  593
        sub       v3.4s, v25.4s, v1.4s                    ; 0x000008A4, line  594
        add       v5.4s, v25.4s, v1.4s                    ; 0x000008A8, line  595
        mls       v15.4s, v31.4s, v7.s[0]                 ; 0x000008AC, line  596
        trn1      v21.2d, v13.2d, v6.2d                   ; 0x000008B0, line  597
        trn2      v6.2d, v13.2d, v6.2d                    ; 0x000008B4, line  598
        add       v10.4s, v3.4s, v9.4s                    ; 0x000008B8, line  599
        sub       v13.4s, v3.4s, v9.4s                    ; 0x000008BC, line  600
        str       q21, [x0], #0x80                        ; 0x000008C0, line  601
        trn1      v3.2d, v12.2d, v30.2d                   ; 0x000008C4, line  602
        trn2      v31.2d, v12.2d, v30.2d                  ; 0x000008C8, line  603
        trn1      v21.4s, v10.4s, v13.4s                  ; 0x000008CC, line  604
        sub       v30.4s, v5.4s, v15.4s                   ; 0x000008D0, line  605
        add       v12.4s, v5.4s, v15.4s                   ; 0x000008D4, line  606
        stur      q3, [x0, #-0x70]                        ; 0x000008D8, line  607
        trn2      v13.4s, v10.4s, v13.4s                  ; 0x000008DC, line  608
        trn1      v19.4s, v12.4s, v30.4s                  ; 0x000008E0, line  609
        trn2      v12.4s, v12.4s, v30.4s                  ; 0x000008E4, line  610
        stur      q6, [x0, #-0x60]                        ; 0x000008E8, line  611
        stur      q31, [x0, #-0x50]                       ; 0x000008EC, line  612
        trn1      v10.2d, v19.2d, v21.2d                  ; 0x000008F0, line  613
        trn2      v3.2d, v19.2d, v21.2d                   ; 0x000008F4, line  614
        trn1      v21.2d, v12.2d, v13.2d                  ; 0x000008F8, line  615
        trn2      v13.2d, v12.2d, v13.2d                  ; 0x000008FC, line  616
        stur      q10, [x0, #-0x40]                       ; 0x00000900, line  617
        stur      q3, [x0, #-0x20]                        ; 0x00000904, line  618
        stur      q13, [x0, #-0x10]                       ; 0x00000908, line  619
        stur      q21, [x0, #-0x30]                       ; 0x0000090C, line  620

        ; ---------------------------------------------------------------------------
        ; Epilogue  --  restore callee-saved FP registers and deallocate stack frame
        ; ---------------------------------------------------------------------------
        ldp       d8, d9, [sp]                            ; 0x00000910, line  621  restore d8,d9
        ; .cfi_restore d8
        ; .cfi_restore d9
        ldp       d10, d11, [sp, #0x10]                   ; 0x00000914, line  624  restore d10,d11
        ; .cfi_restore d10
        ; .cfi_restore d11
        ldp       d12, d13, [sp, #0x20]                   ; 0x00000918, line  627  restore d12,d13
        ; .cfi_restore d12
        ; .cfi_restore d13
        ldp       d14, d15, [sp, #0x30]                   ; 0x0000091C, line  630  restore d14,d15
        ; .cfi_restore d14
        ; .cfi_restore d15
        add       sp, sp, #0x40                           ; 0x00000920, line  633  deallocate stack frame
        ; .cfi_adjust_cfa_offset -0x40
        ret                                               ; 0x00000924, line  635  return to caller
        ; .cfi_endproc

        ENDP

        ; sizeof function: 0x00000928 byte(s)

        AREA      |.xdata|, DATA, READONLY, ALIGN=4

XDATA_$FUNC_NAME

        DCD       0x1820024A                              ; header dword
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
