# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: func kat acvp stack \
	func_44 kat_44 acvp_44 stack_44 \
	func_65 kat_65 acvp_65 stack_65 \
	func_87 kat_87 acvp_87 stack_87 \
	run_func run_kat run_acvp run_stack \
	run_func_44 run_kat_44 run_stack_44 \
	run_func_65 run_kat_65 run_stack_65 \
	run_func_87 run_kat_87 run_stack_87 \
	bench_44 bench_65 bench_87 bench \
	run_bench_44 run_bench_65 run_bench_87 run_bench \
	bench_components_44 bench_components_65 bench_components_87 bench_components \
	run_bench_components_44 run_bench_components_65 run_bench_components_87 run_bench_components \
	build test all \
	clean quickcheck check-defined-CYCLES

.DEFAULT_GOAL := build
all: build

W := $(EXEC_WRAPPER)

# Platform-specific hash command detection for cross-platform compatibility
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    SHA256_CMD = shasum -a 256
else
    SHA256_CMD = sha256sum
endif

include test/mk/config.mk
include test/mk/components.mk
include test/mk/rules.mk

quickcheck: test

build: func kat acvp
	$(Q)echo "  Everything builds fine!"

test: run_kat run_func run_acvp
	$(Q)echo "  Everything checks fine!"

run_kat_44: kat_44
	$(W) $(MLDSA44_DIR)/bin/gen_KAT44 | $(SHA256_CMD) | cut -d " " -f 1 | xargs ./META.sh ML-DSA-44  kat-sha256
run_kat_65: kat_65
	$(W) $(MLDSA65_DIR)/bin/gen_KAT65 | $(SHA256_CMD) | cut -d " " -f 1 | xargs ./META.sh ML-DSA-65  kat-sha256
run_kat_87: kat_87
	$(W) $(MLDSA87_DIR)/bin/gen_KAT87 | $(SHA256_CMD) | cut -d " " -f 1 | xargs ./META.sh ML-DSA-87  kat-sha256
run_kat: run_kat_44 run_kat_65 run_kat_87

run_func_44: func_44
	$(W) $(MLDSA44_DIR)/bin/test_mldsa44
run_func_65: func_65
	$(W) $(MLDSA65_DIR)/bin/test_mldsa65
run_func_87: func_87
	$(W) $(MLDSA87_DIR)/bin/test_mldsa87
run_func: run_func_44 run_func_65 run_func_87

run_acvp: acvp
	python3 ./test/acvp_client.py

func_44: $(MLDSA44_DIR)/bin/test_mldsa44
	$(Q)echo "  FUNC       ML-DSA-44:   $^"
func_65: $(MLDSA65_DIR)/bin/test_mldsa65
	$(Q)echo "  FUNC       ML-DSA-65:   $^"
func_87: $(MLDSA87_DIR)/bin/test_mldsa87
	$(Q)echo "  FUNC       ML-DSA-87:  $^"
func: func_44 func_65 func_87

kat_44: $(MLDSA44_DIR)/bin/gen_KAT44
	$(Q)echo "  KAT        ML-DSA-44:   $^"
kat_65: $(MLDSA65_DIR)/bin/gen_KAT65
	$(Q)echo "  KAT        ML-DSA-65:   $^"
kat_87: $(MLDSA87_DIR)/bin/gen_KAT87
	$(Q)echo "  KAT        ML-DSA-87:  $^"
kat: kat_44 kat_65 kat_87

acvp_44:  $(MLDSA44_DIR)/bin/acvp_mldsa44
	$(Q)echo "  ACVP       ML-DSA-44:   $^"
acvp_65:  $(MLDSA65_DIR)/bin/acvp_mldsa65
	$(Q)echo "  ACVP       ML-DSA-65:   $^"
acvp_87: $(MLDSA87_DIR)/bin/acvp_mldsa87
	$(Q)echo "  ACVP       ML-DSA-87:  $^"
acvp: acvp_44 acvp_65 acvp_87

stack_44: $(MLDSA44_DIR)/bin/test_stack44
	$(Q)echo "  STACK      ML-DSA-44:   $^"
stack_65: $(MLDSA65_DIR)/bin/test_stack65
	$(Q)echo "  STACK      ML-DSA-65:   $^"
stack_87: $(MLDSA87_DIR)/bin/test_stack87
	$(Q)echo "  STACK      ML-DSA-87:  $^"
stack: stack_44 stack_65 stack_87

run_stack_44: stack_44
	$(Q)python3 scripts/stack $(MLDSA44_DIR)/bin/test_stack44 --build-dir $(MLDSA44_DIR) $(STACK_ANALYSIS_FLAGS)
run_stack_65: stack_65
	$(Q)python3 scripts/stack $(MLDSA65_DIR)/bin/test_stack65 --build-dir $(MLDSA65_DIR) $(STACK_ANALYSIS_FLAGS)
run_stack_87: stack_87
	$(Q)python3 scripts/stack $(MLDSA87_DIR)/bin/test_stack87 --build-dir $(MLDSA87_DIR) $(STACK_ANALYSIS_FLAGS)
run_stack: run_stack_44 run_stack_65 run_stack_87

lib: $(BUILD_DIR)/libmldsa.a $(BUILD_DIR)/libmldsa44.a $(BUILD_DIR)/libmldsa65.a $(BUILD_DIR)/libmldsa87.a

# Enforce setting CYCLES make variable when
# building benchmarking binaries
check_defined = $(if $(value $1),, $(error $2))
check-defined-CYCLES:
	@:$(call check_defined,CYCLES,CYCLES undefined. Benchmarking requires setting one of NO PMU PERF MAC)

bench_44: check-defined-CYCLES \
	$(MLDSA44_DIR)/bin/bench_mldsa44
bench_65: check-defined-CYCLES \
	$(MLDSA65_DIR)/bin/bench_mldsa65
bench_87: check-defined-CYCLES \
	$(MLDSA87_DIR)/bin/bench_mldsa87
bench: bench_44 bench_65 bench_87

run_bench_44: bench_44
	$(W) $(MLDSA44_DIR)/bin/bench_mldsa44
run_bench_65: bench_65
	$(W) $(MLDSA65_DIR)/bin/bench_mldsa65
run_bench_87: bench_87
	$(W) $(MLDSA87_DIR)/bin/bench_mldsa87

# Use .WAIT to prevent parallel execution when -j is passed
run_bench: \
	run_bench_44 .WAIT\
	run_bench_65 .WAIT\
	run_bench_87

bench_components_44: check-defined-CYCLES \
	$(MLDSA44_DIR)/bin/bench_components_mldsa44
bench_components_65: check-defined-CYCLES \
	$(MLDSA65_DIR)/bin/bench_components_mldsa65
bench_components_87: check-defined-CYCLES \
	$(MLDSA87_DIR)/bin/bench_components_mldsa87
bench_components: bench_components_44 bench_components_65 bench_components_87

run_bench_components_44: bench_components_44
	$(W) $(MLDSA44_DIR)/bin/bench_components_mldsa44
run_bench_components_65: bench_components_65
	$(W) $(MLDSA65_DIR)/bin/bench_components_mldsa65
run_bench_components_87: bench_components_87
	$(W) $(MLDSA87_DIR)/bin/bench_components_mldsa87

# Use .WAIT to prevent parallel execution when -j is passed
run_bench_components: \
	run_bench_components_44 .WAIT\
	run_bench_components_65 .WAIT\
	run_bench_components_87

clean:
	-$(RM) -rf *.gcno *.gcda *.lcov *.o *.so
	-$(RM) -rf $(BUILD_DIR)
