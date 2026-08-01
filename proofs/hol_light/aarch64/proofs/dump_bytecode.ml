(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

(* Load base theories for AArch64 from s2n-bignum *)
needs "s2n_bignum/arm/proofs/base.ml";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_ntt_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_ntt_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_intt_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_intt_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_pointwise_montgomery_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_pointwise_montgomery_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l4_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l5_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyvecl_pointwise_acc_montgomery_l7_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_caddq_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_caddq_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_use_hint_32_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_use_hint_32_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_use_hint_88_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_use_hint_88_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_chknorm_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_chknorm_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_decompose_32_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_decompose_32_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_poly_decompose_88_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_poly_decompose_88_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyz_unpack_17_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyz_unpack_17_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_polyz_unpack_19_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_polyz_unpack_19_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_rej_uniform_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_rej_uniform_eta2_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_eta2_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: aarch64/mldsa/mldsa_rej_uniform_eta4_aarch64_asm.o ===\n";;
print_literal_from_elf "aarch64/mldsa/mldsa_rej_uniform_eta4_aarch64_asm.o";;
print_string "==== bytecode end =====================================\n\n";;
