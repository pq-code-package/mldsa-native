(*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 *)

(* This utility reads the five assembled RV32 object files and prints the
   instruction lists stored near the top of their proof files. The RV32
   Makefile builds it, and
   `scripts/autogen --update-hol-light-bytecode` compares its output with the
   checked-in lists. A changed instruction therefore produces a visible
   generated-file difference in the matching proof. *)

needs "s2n_bignum/riscv/proofs/base.ml";;

(* The RISC-V decoder does not yet provide the ARM/x86 convenience printer.
   Keep the same output format locally so `scripts/autogen` can refresh the
   checked word list at the top of each RV32 proof entry. *)
let print_literal_from_elf file =
  let bs = load_elf_contents_riscv file in
  let instructions = decode_all (term_of_bytes bs) in
  let count = List.length instructions in
  let output = Buffer.create (count * 64) in
  Buffer.add_string output "[\n";
  List.iteri
    (fun i instruction ->
      let opcode = get_int_le bs (4 * i) 4 in
      let separator = if i + 1 = count then "" else ";" in
      Printf.bprintf output "  0x%08x%s       (* %s *)\n"
        opcode separator (string_of_term instruction))
    instructions;
  Buffer.add_string output "];;\n";
  print_string (Buffer.contents output);;

print_string "=== bytecode start: riscv32/mldsa/mldsa_ntt_rv32im_asm.o ===\n";;
print_literal_from_elf "riscv32/mldsa/mldsa_ntt_rv32im_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: riscv32/mldsa/mldsa_ntt_rv32im_slowmul_asm.o ===\n";;
print_literal_from_elf "riscv32/mldsa/mldsa_ntt_rv32im_slowmul_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: riscv32/mldsa/mldsa_intt_rv32im_asm.o ===\n";;
print_literal_from_elf "riscv32/mldsa/mldsa_intt_rv32im_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string "=== bytecode start: riscv32/mldsa/mldsa_intt_rv32im_slowmul_asm.o ===\n";;
print_literal_from_elf "riscv32/mldsa/mldsa_intt_rv32im_slowmul_asm.o";;
print_string "==== bytecode end =====================================\n\n";;

print_string
  ("=== bytecode start: " ^
   "riscv32/mldsa/mldsa_poly_pointwise_montgomery_rv32im_asm.o ===\n");;
print_literal_from_elf "riscv32/mldsa/mldsa_poly_pointwise_montgomery_rv32im_asm.o";;
print_string "==== bytecode end =====================================\n\n";;
