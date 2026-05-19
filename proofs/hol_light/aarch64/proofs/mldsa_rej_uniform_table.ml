(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(*
 * WARNING: This file is auto-generated from scripts/autogen
 *          in the mldsa-native repository.
 *          Do not modify it directly.
 *)

(*
 * Constant table values used in the AArch64 rejection sampling.
 * Each entry is 16 bytes. There are 16 entries (one per 4-bit mask),
 * for a total of 256 bytes. Entries use 4-byte (32-bit) coefficient
 * indices since ML-DSA coefficients are 32-bit.
 * See autogen for details.
 *)

let mldsa_rej_uniform_table = (REWRITE_RULE[MAP] o define)
  `mldsa_rej_uniform_table:byte list = MAP word [
  255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255;
    4;   5;   6;   7; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;   4;   5;   6;   7; 255; 255; 255; 255; 255; 255; 255; 255;
    8;   9;  10;  11; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;   8;   9;  10;  11; 255; 255; 255; 255; 255; 255; 255; 255;
    4;   5;   6;   7;   8;   9;  10;  11; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;   4;   5;   6;   7;   8;   9;  10;  11; 255; 255; 255; 255;
   12;  13;  14;  15; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;  12;  13;  14;  15; 255; 255; 255; 255; 255; 255; 255; 255;
    4;   5;   6;   7;  12;  13;  14;  15; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;   4;   5;   6;   7;  12;  13;  14;  15; 255; 255; 255; 255;
    8;   9;  10;  11;  12;  13;  14;  15; 255; 255; 255; 255; 255; 255; 255; 255;
    0;   1;   2;   3;   8;   9;  10;  11;  12;  13;  14;  15; 255; 255; 255; 255;
    4;   5;   6;   7;   8;   9;  10;  11;  12;  13;  14;  15; 255; 255; 255; 255;
    0;   1;   2;   3;   4;   5;   6;   7;   8;   9;  10;  11;  12;  13;  14;  15
  ]`;;
