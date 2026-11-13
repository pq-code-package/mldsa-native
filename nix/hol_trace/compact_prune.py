# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""Compact storage for HOLTrace prune records and old-to-new IDs."""

from array import array


STRING = 1 << 63
UNMAPPED = (1 << 64) - 1


class Records:
    """Store tuples of a byte tag followed by nonnegative integers or bytes."""

    def __init__(self):
        self.tags = bytearray()
        self.offsets = array("Q", [0])
        self.data = array("Q")
        self.strings = []
        self.string_ids = {}

    def __len__(self):
        return len(self.tags)

    def __iadd__(self, records):
        for record in records:
            tag, *fields = record
            if not isinstance(tag, bytes) or len(tag) != 1:
                raise ValueError("record tag must be one byte")
            self.tags.extend(tag)
            for field in fields:
                if isinstance(field, int):
                    if not 0 <= field < STRING:
                        raise ValueError("record integer is out of range")
                    self.data.append(field)
                elif isinstance(field, bytes):
                    index = self.string_ids.get(field)
                    if index is None:
                        index = len(self.strings)
                        if index >= STRING:
                            raise ValueError("too many distinct record strings")
                        self.strings.append(field)
                        self.string_ids[field] = index
                    self.data.append(STRING | index)
                else:
                    raise TypeError("unsupported record field")
            self.offsets.append(len(self.data))
        return self

    def __getitem__(self, index):
        if not 0 <= index < len(self.tags):
            raise IndexError(index)
        start, end = self.offsets[index], self.offsets[index + 1]
        fields = (
            self.strings[item & (STRING - 1)] if item & STRING else item
            for item in self.data[start:end]
        )
        return (bytes((self.tags[index],)), *fields)


def id_map(length):
    """Allocate an old-to-new ID map with an explicit missing sentinel."""
    return array("Q", [UNMAPPED]) * length


def mapped(ids, index):
    value = ids[index]
    if value == UNMAPPED:
        raise ValueError(f"unmapped record ID {index}")
    return value
