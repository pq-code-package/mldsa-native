# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: all clean

SLOTHY_CLI ?= slothy-cli
TARGET_ISA ?= Arm_v7M
TARGET_MICROARCH ?= Arm_Cortex_M7
SLOTHY_EXTRA_FLAGS ?=
TMPFILE ?= $@.round0

SLOTHY_COMMON_FLAGS = -c inputs_are_outputs \
                      -c variable_size \
                      -c reserved_regs="[sp,r13]" \
                      -c locked_registers="[sp,r13]" \
                      -c unsafe_address_offset_fixup=False \
                      -c split_heuristic=true \
                      -c split_heuristic_preprocess_naive_interleaving=true \
                      -c split_heuristic_repeat=2 \
                      -c split_heuristic_optimize_seam=6 \
                      -c split_heuristic_stepsize=0.05 \
                      -c split_heuristic_factor=6

SLOTHY_ROUND0_OUTPUTS = [hint_spEga0,hint_spEge0,hint_spEgi0,hint_spEgo0,hint_spEgu0,hint_spEka1,hint_spEke1,hint_spEki1,hint_spEko1,hint_spEku1,hint_spEma0,hint_spEme0,hint_spEmi0,hint_spEmo0,hint_spEmu0,hint_spEsa1,hint_spEse1,hint_spEsi1,hint_spEso1,hint_spEsu1,hint_spEbe0,hint_spEbi0,hint_spEbo0,hint_spEbu0,hint_spEba0,hint_spEga1,hint_spEge1,hint_spEgi1,hint_spEgo1,hint_spEgu1,hint_spEka0,hint_spEke0,hint_spEki0,hint_spEko0,hint_spEku0,hint_spEma1,hint_spEme1,hint_spEmi1,hint_spEmo1,hint_spEmu1,hint_spEsa0,hint_spEse0,hint_spEsi0,hint_spEso0,hint_spEsu0,hint_spEbe1,hint_spEbi1,hint_spEbo1,hint_spEbu1,hint_spEba1]

SLOTHY_ROUND1_OUTPUTS = [flags,hint_r0Aba0,hint_r0Aba1,hint_r0Abe0,hint_r0Abe1,hint_r0Abi0,hint_r0Abi1,hint_r0Abo0,hint_r0Abo1,hint_r0Abu0,hint_r0Abu1,hint_r0Aga0,hint_r0Aga1,hint_r0Age0,hint_r0Age1,hint_r0Agi0,hint_r0Agi1,hint_r0Ago0,hint_r0Ago1,hint_r0Agu0,hint_r0Agu1,hint_r0Aka0,hint_r0Aka1,hint_r0Ake0,hint_r0Ake1,hint_r0Aki0,hint_r0Aki1,hint_r0Ako0,hint_r0Ako1,hint_r0Aku0,hint_r0Aku1,hint_r0Ama0,hint_r0Ama1,hint_r0Ame0,hint_r0Ame1,hint_r0Ami0,hint_r0Ami1,hint_r0Amo0,hint_r0Amo1,hint_r0Amu0,hint_r0Amu1,hint_r0Asa0,hint_r0Asa1,hint_r0Ase0,hint_r0Ase1,hint_r0Asi0,hint_r0Asi1,hint_r0Aso0,hint_r0Aso1,hint_r0Asu0,hint_r0Asu1]

SLOTHY_ROUND0_FLAGS = $(SLOTHY_COMMON_FLAGS) \
                      -c outputs="$(SLOTHY_ROUND0_OUTPUTS)" \
                      $(SLOTHY_EXTRA_FLAGS)

SLOTHY_ROUND1_FLAGS = $(SLOTHY_COMMON_FLAGS) \
                      -c outputs="$(SLOTHY_ROUND1_OUTPUTS)" \
                      $(SLOTHY_EXTRA_FLAGS)

all: keccak_f1600_x1_armv7m_opt_m7.S

keccak_f1600_x1_armv7m_opt_m7.S: ../../armv81m_clean/src/keccak_f1600_x1_armv7m.S
	$(SLOTHY_CLI) $(TARGET_ISA) $(TARGET_MICROARCH) $< -o $(TMPFILE) -s slothy_start_round0 -e slothy_end_round0 $(SLOTHY_ROUND0_FLAGS)
	$(SLOTHY_CLI) $(TARGET_ISA) $(TARGET_MICROARCH) $(TMPFILE) -o $@ -s slothy_start_round1 -e slothy_end_round1 $(SLOTHY_ROUND1_FLAGS)
	$(RM) $(TMPFILE)

clean:
	$(RM) keccak_f1600_x1_armv7m_opt_m7.S keccak_f1600_x1_armv7m_opt_m7.S.round0
