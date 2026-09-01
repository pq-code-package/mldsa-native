# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: all clean

PYTHON ?= python3
SCHEDULE_KECCAK_M7 ?= schedule_keccak_m7.py
# Every incumbent used by the checked-in run appeared within 743 seconds. Keep
# useful headroom while ensuring regeneration finishes without intervention.
# This is an operational ceiling per split solve, not a scheduling-policy knob.
SCHEDULE_KECCAK_M7_ARGS ?= --timeout 900

all: keccak_f1600_x1_armv7m_opt_m7.S

keccak_f1600_x1_armv7m_opt_m7.S: ../../armv81m_clean/src/keccak_f1600_x1_armv7m.S $(SCHEDULE_KECCAK_M7)
	$(PYTHON) $(SCHEDULE_KECCAK_M7) $(SCHEDULE_KECCAK_M7_ARGS) $< $@

clean:
	$(RM) keccak_f1600_x1_armv7m_opt_m7.S
