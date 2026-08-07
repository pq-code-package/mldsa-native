# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: all clean

PYTHON ?= python3
SLOTHY_NTT ?= slothy_ntt_armv81m.py

all: ntt_armv81m_asm.S

ntt_armv81m_asm.S: ../../armv81m_clean/src/ntt_armv81m_asm.S \
	../../armv81m_clean/src/ntt_armv81m_asm_twiddles.inc $(SLOTHY_NTT)
	$(PYTHON) $(SLOTHY_NTT) $< $@

clean:
	$(RM) ntt_armv81m_asm.S
