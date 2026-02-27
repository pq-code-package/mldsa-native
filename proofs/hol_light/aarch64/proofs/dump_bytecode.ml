(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

(* Load base theories for AArch64 from s2n-bignum *)
needs "s2n_bignum/arm/proofs/base.ml";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_ntt.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_ntt.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_pointwise.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_pointwise.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_pointwise_acc_l4.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_pointwise_acc_l4.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_pointwise_acc_l5.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_pointwise_acc_l5.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_pointwise_acc_l7.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_pointwise_acc_l7.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_caddq.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_caddq.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/poly_use_hint_32_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/poly_use_hint_32_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/poly_use_hint_88_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/poly_use_hint_88_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_chknorm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_chknorm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/poly_decompose_32_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/poly_decompose_32_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/poly_decompose_88_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/poly_decompose_88_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyz_unpack_17.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyz_unpack_17.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyz_unpack_19.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyz_unpack_19.o";;
print_string "==== bytecode end =====================================\n\n";;
