# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: all clean

PYTHON ?= python3
SLOTHY_KECCAK_M4 ?= slothy_keccak_m4.py

all: keccak_f1600_x1_armv7m_opt_m55.S

keccak_f1600_x1_armv7m_opt_m55.S: ../../armv81m_clean/src/keccak_f1600_x1_armv7m.S $(SLOTHY_KECCAK_M4)
	$(PYTHON) $(SLOTHY_KECCAK_M4) $< $@

clean:
	$(RM) keccak_f1600_x1_armv7m_opt_m55.S
