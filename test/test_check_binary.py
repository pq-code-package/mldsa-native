# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""Regression tests for binary binding's handling of ELF files."""

import contextlib
import hashlib
import importlib.machinery
import importlib.util
import io
import pathlib
import sys
import unittest
from unittest import mock


sys.dont_write_bytecode = True
script = pathlib.Path(__file__).resolve().parents[1] / "scripts/check-binary"
loader = importlib.machinery.SourceFileLoader("check_binary", str(script))
spec = importlib.util.spec_from_loader(loader.name, loader)
check_binary = importlib.util.module_from_spec(spec)
loader.exec_module(check_binary)

HEADERS = """\
  Type:                              REL (Relocatable file)
  [ 1] .text PROGBITS 0000000000000000 000040 000004 00 AX 0 0 1
  [ 2] .data PROGBITS 0000000000000000 000044 000004 00 WA 0 0 1
Symbol table '.symtab' contains 4 entries:
   1: 0000000000000000 0 NOTYPE LOCAL DEFAULT 1 LLmld_kernel
   2: 0000000000000000 4 FUNC GLOBAL DEFAULT 1 mld_kernel
   3: 0000000000000000 4 OBJECT GLOBAL DEFAULT 2 bad_kernel
"""
DUMP = """\
Hex dump of section '.text':
  0x00000000 01020304 ....
"""
BIND = {
    "kernel": {
        "arch": "aarch64",
        "function": "kernel",
        "sha256": {"kernel_mc": hashlib.sha256(b"\x01\x02\x03\x04").hexdigest()},
    }
}
RV_CODE = bytes(0x48) + bytes.fromhex("e31c55fc") + bytes(0x10)
RV_HEADERS = """\
  Class:                             ELF32
  Data:                              2's complement, little endian
  Type:                              REL (Relocatable file)
  Machine:                           RISC-V
  [ 1] .text PROGBITS 00000000 000034 00005c 00 AX 0 0 4
  [ 2] .rela.text RELA 00000000 0002e4 00000c 0c I 9 1 4
  [ 9] .symtab SYMTAB 00000000 000144 000080 10 0 8 4
Relocation section '.rela.text' at offset 0x2e4 contains 1 entry:
 Offset     Info    Type                Sym. Value  Symbol's Name + Addend
00000048  00000710 R_RISCV_BRANCH         00000020   loop + 0

Symbol table '.symtab' contains 8 entries:
   6: 00000000 92 FUNC GLOBAL DEFAULT 1 mld_kernel
   7: 00000020 0 NOTYPE LOCAL DEFAULT 1 loop
"""
RV_DUMP = "Hex dump of section '.text':\n" + "".join(
    f"  0x{offset:08x} {RV_CODE[offset : offset + 16].hex()}\n"
    for offset in range(0, len(RV_CODE), 16)
)
RV_BIND = {
    "kernel": {
        "arch": "riscv32",
        "function": "kernel",
        "sha256": {"kernel_mc": hashlib.sha256(RV_CODE).hexdigest()},
    }
}


class CheckBinaryTests(unittest.TestCase):
    def check(self, headers, bind=BIND, dump=DUMP):
        def readelf(path, *args):
            return [(path, headers if "-h" in args else dump)]

        with mock.patch.object(check_binary, "readelf", side_effect=readelf):
            with contextlib.redirect_stdout(io.StringIO()) as output:
                result = check_binary.check(
                    bind, ["fixture.o"], False, False, False, True
                )
        return result, output.getvalue()

    def test_local_label_does_not_shadow_function(self):
        result, output = self.check(HEADERS.replace("bad_kernel", "other"))
        self.assertEqual(result, 0, output)
        self.assertIn("mld_kernel", output)
        self.assertNotIn("LLmld_kernel", output)

    def test_global_non_function_matching_kernel_is_rejected(self):
        result, output = self.check(HEADERS)
        self.assertEqual(result, 1, output)
        self.assertIn("bad_kernel: not a function", output)

    def test_wrong_code_is_rejected(self):
        bind = {"kernel": {**BIND["kernel"], "sha256": {"kernel_mc": "0" * 64}}}
        result, output = self.check(HEADERS.replace("bad_kernel", "other"), bind)
        self.assertEqual(result, 1, output)
        self.assertIn("not kernel_mc", output)

    def test_riscv_local_branch_with_matching_displacement(self):
        result, output = self.check(RV_HEADERS, RV_BIND, RV_DUMP)
        self.assertEqual(result, 0, output)

    def test_unsafe_riscv_relocations_are_rejected(self):
        cases = {
            "wrong addend": RV_HEADERS.replace("loop + 0", "loop + 2"),
            "wrong target": RV_HEADERS.replace(
                "00000020 0 NOTYPE", "00000024 0 NOTYPE"
            ),
            "wrong symbol index": RV_HEADERS.replace("00000710", "00000810"),
            "wrong type": RV_HEADERS.replace("R_RISCV_BRANCH", "R_RISCV_JAL"),
            "wrong info type": RV_HEADERS.replace("00000710", "00000711"),
            "wrong symbol table": RV_HEADERS.replace("0c I 9 1 4", "0c I 8 1 4"),
            "wrong symbol table type": RV_HEADERS.replace(
                ".symtab SYMTAB", ".symtab DYNSYM"
            ),
            "duplicate symbol table": RV_HEADERS.replace(
                "Relocation section",
                "  [10] .symtab SYMTAB 00000000 000144 000080 10 0 8 4\n"
                "Relocation section",
            ),
            "global target": RV_HEADERS.replace("NOTYPE LOCAL", "NOTYPE GLOBAL"),
            "undefined target": RV_HEADERS.replace(
                "LOCAL DEFAULT 1 loop", "LOCAL DEFAULT UND loop"
            ),
            "other section": RV_HEADERS.replace(
                "LOCAL DEFAULT 1 loop", "LOCAL DEFAULT 2 loop"
            ),
            "target outside function": RV_HEADERS.replace(
                "00000020 0 NOTYPE", "0000005c 0 NOTYPE"
            ),
            "branch outside function": RV_HEADERS.replace(
                "00000048  00000710", "0000005c  00000710"
            ),
            "truncated branch": RV_HEADERS.replace(
                "00000048  00000710", "0000005a  00000710"
            ),
            "rv64": RV_HEADERS.replace("ELF32", "ELF64"),
            "big endian": RV_HEADERS.replace("little endian", "big endian"),
            "another machine": RV_HEADERS.replace("RISC-V", "AArch64"),
            "linked": RV_HEADERS.replace(
                "REL (Relocatable file)", "EXEC (Executable file)"
            ),
            "relaxation": RV_HEADERS.replace(
                "00000048  00000710",
                "00000044  00000033 R_RISCV_RELAX 0\n00000048  00000710",
            ),
        }
        for name, headers in cases.items():
            with self.subTest(name=name):
                result, output = self.check(headers, RV_BIND, RV_DUMP)
                self.assertEqual(result, 1, output)
                self.assertIn("relocations apply", output)

    def test_riscv_branch_bytes_must_match_relocation(self):
        for name, replacement in {
            "wrong displacement": "e31a55fc",
            "wrong opcode": "e21c55fc",
        }.items():
            with self.subTest(name=name):
                dump = RV_DUMP.replace("e31c55fc", replacement)
                result, output = self.check(RV_HEADERS, RV_BIND, dump)
                self.assertEqual(result, 1, output)
                self.assertIn("relocations apply", output)

    def test_duplicate_relocation_sections_are_rejected(self):
        headers = RV_HEADERS.replace(
            "Relocation section",
            "  [ 3] .rela.text RELA 00000000 0002f0 00000c 0c I 9 0 4\n"
            "Relocation section",
        )
        with self.assertRaisesRegex(check_binary.Failed, "duplicate relocation"):
            check_binary.parse_headers(headers)


if __name__ == "__main__":
    unittest.main()
