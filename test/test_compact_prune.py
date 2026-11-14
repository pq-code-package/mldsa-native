# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""Test compact HOLTrace pruning records and ID maps."""

import importlib.util
import pathlib
import sys
import unittest


sys.dont_write_bytecode = True
module_path = (
    pathlib.Path(__file__).resolve().parents[1] / "nix/hol_trace/compact_prune.py"
)
spec = importlib.util.spec_from_file_location("compact_prune", module_path)
compact_prune = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compact_prune)


class CompactPruneTests(unittest.TestCase):
    def test_records_round_trip_and_intern_strings(self):
        records = compact_prune.Records()
        records += [(b"a", b""), (b"b", 0, 17, b"name"), (b"c", 42, b"name")]
        self.assertEqual(len(records), 3)
        self.assertEqual(records[0], (b"a", b""))
        self.assertEqual(records[1], (b"b", 0, 17, b"name"))
        self.assertEqual(records[2], (b"c", 42, b"name"))
        self.assertEqual(records.strings, [b"", b"name"])
        with self.assertRaises(IndexError):
            records[3]

    def test_reject_invalid_fields(self):
        for record in ((b"ab", 0), (b"a", -1), (b"a", 1 << 63), (b"a", "text")):
            with (
                self.subTest(record=record),
                self.assertRaises((TypeError, ValueError)),
            ):
                records = compact_prune.Records()
                records += [record]

    def test_id_map_rejects_missing_entries(self):
        ids = compact_prune.id_map(2)
        with self.assertRaisesRegex(ValueError, "unmapped"):
            compact_prune.mapped(ids, 0)
        ids[0] = 23
        self.assertEqual(compact_prune.mapped(ids, 0), 23)


if __name__ == "__main__":
    unittest.main()
