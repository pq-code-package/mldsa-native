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
