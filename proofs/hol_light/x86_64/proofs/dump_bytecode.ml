(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "s2n_bignum/x86/proofs/base.ml";;

print_string "=== bytecode start: x86_64/mldsa/ntt_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/ntt_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/intt_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/intt_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/nttunpack_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/nttunpack_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/pointwise_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/pointwise_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/pointwise_acc_l4_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/pointwise_acc_l4_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/pointwise_acc_l5_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/pointwise_acc_l5_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/pointwise_acc_l7_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/pointwise_acc_l7_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/keccak_f1600_x4_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/keccak_f1600_x4_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_caddq_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_caddq_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_chknorm_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_chknorm_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_decompose_32_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_decompose_32_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_decompose_88_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_decompose_88_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/polyz_unpack_17_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/polyz_unpack_17_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/polyz_unpack_19_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/polyz_unpack_19_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_use_hint_32_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_use_hint_32_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/poly_use_hint_88_avx2_asm.o ================\n";;
print_literal_from_elf "x86_64/mldsa/poly_use_hint_88_avx2_asm.o";;
print_string "==== bytecode end =====================================\n\n";;
