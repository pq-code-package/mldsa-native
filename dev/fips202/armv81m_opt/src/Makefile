# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: all clean

PYTHON ?= python3
SLOTHY_KECCAK_M4 ?= slothy_keccak_m4.py
SLOTHY_KECCAK_X1_HELPERS_MVE ?= slothy_keccak_x1_helpers_mve.py

all: keccak_f1600_x1_armv7m_opt_m55.S \
	keccak_f1600_x1_state_xor_bytes_mve.S \
	keccak_f1600_x1_state_extract_bytes_mve.S

keccak_f1600_x1_armv7m_opt_m55.S: ../../armv81m_clean/src/keccak_f1600_x1_armv81m.S $(SLOTHY_KECCAK_M4)
	$(PYTHON) $(SLOTHY_KECCAK_M4) $< $@

keccak_f1600_x1_state_xor_bytes_mve.S: ../../armv81m_clean/src/keccak_f1600_x1_state_xor_bytes_mve.S $(SLOTHY_KECCAK_X1_HELPERS_MVE)
	$(PYTHON) $(SLOTHY_KECCAK_X1_HELPERS_MVE) $< $@ xor

keccak_f1600_x1_state_extract_bytes_mve.S: ../../armv81m_clean/src/keccak_f1600_x1_state_extract_bytes_mve.S $(SLOTHY_KECCAK_X1_HELPERS_MVE)
	$(PYTHON) $(SLOTHY_KECCAK_X1_HELPERS_MVE) $< $@ extract

clean:
	$(RM) keccak_f1600_x1_armv7m_opt_m55.S \
		keccak_f1600_x1_state_xor_bytes_mve.S \
		keccak_f1600_x1_state_extract_bytes_mve.S
