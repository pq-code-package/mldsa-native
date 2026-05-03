(*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

needs "s2n_bignum/x86/proofs/base.ml";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_ntt.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_ntt.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_intt.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_intt.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_nttunpack.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_nttunpack.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_pointwise.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_pointwise.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_pointwise_acc_l4.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_pointwise_acc_l4.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_pointwise_acc_l5.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_pointwise_acc_l5.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/mldsa_pointwise_acc_l7.o ================\n";;
print_literal_from_elf "x86_64/mldsa/mldsa_pointwise_acc_l7.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: x86_64/mldsa/keccak_f1600_x4_avx2.o ================\n";;
print_literal_from_elf "x86_64/mldsa/keccak_f1600_x4_avx2.o";;
print_string "==== bytecode end =====================================\n\n";;
