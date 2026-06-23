# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

FIPS202_SRCS = $(wildcard mldsa/src/fips202/*.c)
ifeq ($(OPT),1)
	FIPS202_SRCS += $(wildcard mldsa/src/fips202/native/aarch64/src/*.S) $(wildcard mldsa/src/fips202/native/aarch64/src/*.c) $(wildcard mldsa/src/fips202/native/x86_64/src/*.c) $(wildcard mldsa/src/fips202/native/x86_64/src/*.S) $(wildcard mldsa/src/fips202/native/armv81m/src/*.[csS])
endif


SOURCES += $(wildcard mldsa/src/*.c)
ifeq ($(OPT),1)
	SOURCES += $(wildcard mldsa/src/native/aarch64/src/*.[csS]) $(wildcard mldsa/src/native/x86_64/src/*.[csS])
	CFLAGS += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH -DMLD_CONFIG_USE_NATIVE_BACKEND_FIPS202
endif

BASIC_TESTS = test_mldsa gen_KAT test_stack
ACVP_TESTS = acvp_mldsa
WYCHEPROOF_TESTS = wycheproof_mldsa
BENCH_TESTS = bench_mldsa bench_components_mldsa
UNIT_TESTS = test_unit
ALLOC_TESTS = test_alloc
RNG_FAIL_TESTS = test_rng_fail
ALL_TESTS = $(BASIC_TESTS) $(ACVP_TESTS) $(WYCHEPROOF_TESTS) $(BENCH_TESTS) $(UNIT_TESTS) $(ALLOC_TESTS) $(RNG_FAIL_TESTS)

MLDSA44_DIR = $(BUILD_DIR)/mldsa44
MLDSA65_DIR = $(BUILD_DIR)/mldsa65
MLDSA87_DIR = $(BUILD_DIR)/mldsa87

MLDSA44_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
MLDSA65_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
MLDSA87_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87

# Unit test object files - same sources but with MLD_STATIC_TESTABLE=
UNIT_CFLAGS = -DMLD_STATIC_TESTABLE= -DMLD_UNIT_TEST -Wno-missing-prototypes

MLDSA44_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 $(UNIT_CFLAGS)
MLDSA65_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 $(UNIT_CFLAGS)
MLDSA87_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 $(UNIT_CFLAGS)

# Alloc test object files - same sources but with custom alloc config
MLDSA44_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
MLDSA65_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
MLDSA87_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"

CFLAGS += -Imldsa

$(BUILD_DIR)/libmldsa44.a: $(MLDSA44_OBJS)
$(BUILD_DIR)/libmldsa65.a: $(MLDSA65_OBJS)
$(BUILD_DIR)/libmldsa87.a: $(MLDSA87_OBJS)

# Unit libraries with exposed internal functions
$(BUILD_DIR)/libmldsa44_unit.a: $(MLDSA44_UNIT_OBJS)
$(BUILD_DIR)/libmldsa65_unit.a: $(MLDSA65_UNIT_OBJS)
$(BUILD_DIR)/libmldsa87_unit.a: $(MLDSA87_UNIT_OBJS)

# Alloc test libraries with custom alloc config
$(BUILD_DIR)/libmldsa44_alloc.a: $(MLDSA44_ALLOC_OBJS)
$(BUILD_DIR)/libmldsa65_alloc.a: $(MLDSA65_ALLOC_OBJS)
$(BUILD_DIR)/libmldsa87_alloc.a: $(MLDSA87_ALLOC_OBJS)

$(BUILD_DIR)/libmldsa.a: $(MLDSA44_OBJS) $(MLDSA65_OBJS) $(MLDSA87_OBJS)

$(MLDSA44_DIR)/bin/bench_mldsa44: CFLAGS += -Itest/hal
$(MLDSA65_DIR)/bin/bench_mldsa65: CFLAGS += -Itest/hal
$(MLDSA87_DIR)/bin/bench_mldsa87: CFLAGS += -Itest/hal
$(MLDSA44_DIR)/bin/bench_components_mldsa44: CFLAGS += -Itest/hal
$(MLDSA65_DIR)/bin/bench_components_mldsa65: CFLAGS += -Itest/hal
$(MLDSA87_DIR)/bin/bench_components_mldsa87: CFLAGS += -Itest/hal

$(MLDSA44_DIR)/bin/test_stack44: CFLAGS += -Imldsa -fstack-usage
$(MLDSA65_DIR)/bin/test_stack65: CFLAGS += -Imldsa -fstack-usage
$(MLDSA87_DIR)/bin/test_stack87: CFLAGS += -Imldsa -fstack-usage

$(MLDSA44_DIR)/test/src/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
$(MLDSA65_DIR)/test/src/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
$(MLDSA87_DIR)/test/src/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"

$(MLDSA44_DIR)/test/src/test_unit.c.o: CFLAGS += $(UNIT_CFLAGS)
$(MLDSA65_DIR)/test/src/test_unit.c.o: CFLAGS += $(UNIT_CFLAGS)
$(MLDSA87_DIR)/test/src/test_unit.c.o: CFLAGS += $(UNIT_CFLAGS)

$(MLDSA44_DIR)/bin/test_unit44: CFLAGS += $(UNIT_CFLAGS)
$(MLDSA65_DIR)/bin/test_unit65: CFLAGS += $(UNIT_CFLAGS)
$(MLDSA87_DIR)/bin/test_unit87: CFLAGS += $(UNIT_CFLAGS)

# Unit library object files compiled with MLD_STATIC_TESTABLE=
$(MLDSA44_DIR)/unit_%: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
$(MLDSA65_DIR)/unit_%: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
$(MLDSA87_DIR)/unit_%: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes


$(MLDSA44_DIR)/bin/bench_mldsa44: $(MLDSA44_DIR)/test/hal/hal.c.o
$(MLDSA65_DIR)/bin/bench_mldsa65: $(MLDSA65_DIR)/test/hal/hal.c.o
$(MLDSA87_DIR)/bin/bench_mldsa87: $(MLDSA87_DIR)/test/hal/hal.c.o
$(MLDSA44_DIR)/bin/bench_components_mldsa44: $(MLDSA44_DIR)/test/hal/hal.c.o
$(MLDSA65_DIR)/bin/bench_components_mldsa65: $(MLDSA65_DIR)/test/hal/hal.c.o
$(MLDSA87_DIR)/bin/bench_components_mldsa87: $(MLDSA87_DIR)/test/hal/hal.c.o

$(MLDSA44_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
$(MLDSA65_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
$(MLDSA87_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87

# Link tests with respective library (except test_unit which includes sources directly)
define ADD_SOURCE
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/$(3)/$(2).c.o $(BUILD_DIR)/lib$(1).a
endef


# Special rule for test_unit - link against unit libraries with exposed internal functions
define ADD_SOURCE_UNIT
$(BUILD_DIR)/$(1)/bin/test_unit$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)_unit
$(BUILD_DIR)/$(1)/bin/test_unit$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/src/test_unit.c.o $(BUILD_DIR)/lib$(1)_unit.a $(call MAKE_OBJS, $(BUILD_DIR)/$(1), $(wildcard test/notrandombytes/*.c))
endef

# Special rule for test_alloc - link against alloc libraries with custom alloc config
define ADD_SOURCE_ALLOC
$(BUILD_DIR)/$(1)/bin/test_alloc$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)_alloc
$(BUILD_DIR)/$(1)/bin/test_alloc$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/src/test_alloc.c.o $(BUILD_DIR)/lib$(1)_alloc.a $(call MAKE_OBJS, $(BUILD_DIR)/$(1), $(wildcard test/notrandombytes/*.c))
endef

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(foreach test,$(ACVP_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),acvp)) \
	) \
	$(foreach test,$(WYCHEPROOF_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),wycheproof)) \
	) \
	$(foreach test,$(BENCH_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),bench)) \
	) \
	$(foreach test,$(BASIC_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),src)) \
	) \
	$(eval $(call ADD_SOURCE,$(scheme),test_rng_fail,src)) \
	$(eval $(call ADD_SOURCE_UNIT,$(scheme))) \
	$(eval $(call ADD_SOURCE_ALLOC,$(scheme))) \
)

# All tests get EXTRA_SOURCES
$(ALL_TESTS:%=$(MLDSA44_DIR)/bin/%44): $(call MAKE_OBJS, $(MLDSA44_DIR), $(EXTRA_SOURCES))
$(ALL_TESTS:%=$(MLDSA65_DIR)/bin/%65): $(call MAKE_OBJS, $(MLDSA65_DIR), $(EXTRA_SOURCES))
$(ALL_TESTS:%=$(MLDSA87_DIR)/bin/%87): $(call MAKE_OBJS, $(MLDSA87_DIR), $(EXTRA_SOURCES))

# All tests except rng_fail get notrandombytes (rng_fail provides its own)
$(filter-out %test_rng_fail44,$(ALL_TESTS:%=$(MLDSA44_DIR)/bin/%44)): $(call MAKE_OBJS, $(MLDSA44_DIR), $(wildcard test/notrandombytes/*.c))
$(filter-out %test_rng_fail65,$(ALL_TESTS:%=$(MLDSA65_DIR)/bin/%65)): $(call MAKE_OBJS, $(MLDSA65_DIR), $(wildcard test/notrandombytes/*.c))
$(filter-out %test_rng_fail87,$(ALL_TESTS:%=$(MLDSA87_DIR)/bin/%87)): $(call MAKE_OBJS, $(MLDSA87_DIR), $(wildcard test/notrandombytes/*.c))

# Apply EXTRA_CFLAGS to EXTRA_SOURCES object files
ifneq ($(EXTRA_SOURCES),)
$(call MAKE_OBJS, $(MLDSA44_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA65_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA87_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
endif

# ABI checker
ABICHECK_DIR = $(BUILD_DIR)/abicheck

# Map $(ARCH) to the abicheck per-arch subdir name. For most architectures
# the subdir matches $(ARCH); one exception:
#   - arm-none-eabi- targets: $(ARCH) = arm (a generic label for the
#     bare-metal Cortex-M family). The abicheck subdir is the more specific
#     armv81m.
ifeq ($(ARCH),arm)
ABICHECK_ARCH := armv81m
else
ABICHECK_ARCH := $(ARCH)
endif

ABICHECK_SOURCES = test/abicheck/abicheck.c test/abicheck/selftest.c
ABICHECK_SOURCES += $(wildcard test/abicheck/$(ABICHECK_ARCH)/abicheck_$(ABICHECK_ARCH).c)
ABICHECK_SOURCES += $(wildcard test/abicheck/$(ABICHECK_ARCH)/callstub_$(ABICHECK_ARCH).S)
ABICHECK_SOURCES += $(wildcard test/abicheck/$(ABICHECK_ARCH)/selftest_$(ABICHECK_ARCH).S)
ABICHECK_SOURCES += $(wildcard test/abicheck/$(ABICHECK_ARCH)/checks/check_*.c)
ABICHECK_SOURCES += $(wildcard test/notrandombytes/*.c)

# Per-arch shipped assembly (mldsa/src/.../*.S), assembled directly with
# ABICHECK_ASM_CFLAGS (defined below).
ifeq ($(ABICHECK_ARCH),aarch64)
ABICHECK_ASM_SOURCES := $(wildcard mldsa/src/native/aarch64/src/*.S) \
                        $(wildcard mldsa/src/fips202/native/aarch64/src/*.S)
else ifeq ($(ABICHECK_ARCH),x86_64)
ABICHECK_ASM_SOURCES := $(wildcard mldsa/src/native/x86_64/src/*.S) \
                        $(wildcard mldsa/src/fips202/native/x86_64/src/*.S)
else ifeq ($(ABICHECK_ARCH),armv81m)
ABICHECK_ASM_SOURCES := $(wildcard mldsa/src/fips202/native/armv81m/src/*.S)
else
ABICHECK_ASM_SOURCES :=
endif

# Per-capability CFLAGS injection (e.g. -march=armv8.4-a+sha3 for SHA3,
# -mavx2 -mbmi2 for AVX2), generated by scripts/autogen from each kernel's
# YAML 'ABI.Features:' list. abicheck.mk includes the per-arch abicheck_<arch>.mk.
include test/abicheck/abicheck.mk

# SHA3-not-assemblable case: some aarch64 compilers do not support
# `-march=armv8.4-a+sha3`, in which case we cannot even assemble the SHA3
# Keccak kernels.
ifeq ($(ARCH),aarch64)
ifneq ($(MK_COMPILER_SUPPORTS_SHA3),1)
ABICHECK_ASM_SOURCES := $(filter-out $(ABICHECK_REQ_SHA3_FILES),$(ABICHECK_ASM_SOURCES))
endif
endif

ABICHECK_ALL_SOURCES = $(ABICHECK_SOURCES) $(ABICHECK_ASM_SOURCES)
ABICHECK_OBJS = $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_ALL_SOURCES))

# Predefine the kernel-gating macros (arith backend, fips202 NEED_*) so the
# shipped #ifs evaluate true. Undefine the two USE_NATIVE_BACKEND switches so
# common.h does not pull in the per-arch backend headers and the constant-table
# C declarations the abicheck does not link against.
ABICHECK_ASM_CFLAGS := \
  -UMLD_CONFIG_USE_NATIVE_BACKEND_ARITH \
  -UMLD_CONFIG_USE_NATIVE_BACKEND_FIPS202 \
  -DMLD_CONFIG_MULTILEVEL_WITH_SHARED \
  -DMLD_CONFIG_PARAMETER_SET=65 \
  -DMLD_CONFIG_NAMESPACE_PREFIX=mld \
  -DMLD_ARITH_BACKEND_AARCH64 \
  -DMLD_ARITH_BACKEND_X86_64_DEFAULT \
  -DMLD_FIPS202_AARCH64_NEED_X1_SCALAR \
  -DMLD_FIPS202_AARCH64_NEED_X1_V84A \
  -DMLD_FIPS202_AARCH64_NEED_X2_V84A \
  -DMLD_FIPS202_AARCH64_NEED_X4_V8A_SCALAR_HYBRID \
  -DMLD_FIPS202_AARCH64_NEED_X4_V8A_V84A_SCALAR_HYBRID \
  -DMLD_FIPS202_ARMV81M_NEED_X4 \
  -DMLD_FIPS202_X86_64_NEED_X4_AVX2

ABICHECK_ASM_OBJS = $(call MAKE_OBJS,$(ABICHECK_DIR),$(ABICHECK_ASM_SOURCES))
$(ABICHECK_ASM_OBJS): CFLAGS += $(ABICHECK_ASM_CFLAGS)

# Force the full ML-DSA API surface for the ABI check, regardless of any
# reduced-API config the caller passes in.
ABICHECK_FULL_API_CFLAGS := \
  -UMLD_CONFIG_NO_KEYPAIR_API \
  -UMLD_CONFIG_NO_SIGN_API \
  -UMLD_CONFIG_NO_VERIFY_API
$(ABICHECK_OBJS): CFLAGS += $(ABICHECK_FULL_API_CFLAGS)

# Platform support objects (e.g. the bare-metal startup providing _start and the
# semihosting runtime). EXTRA_SOURCES is set by a platform makefile (see
# test/baremetal/platform/*/platform.mk via EXTRA_MAKEFILE); empty for native
# builds. Like the other test binaries, the ABI checker must link these or it has
# no entry point on bare metal. The platform's LDSCRIPT is already applied via
# LDFLAGS in the link rule.
ABICHECK_EXTRA_OBJS = $(call MAKE_OBJS,$(ABICHECK_DIR),$(EXTRA_SOURCES))
ifneq ($(EXTRA_SOURCES),)
$(ABICHECK_EXTRA_OBJS): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
endif

$(ABICHECK_DIR)/bin/abicheck: $(ABICHECK_OBJS) $(ABICHECK_EXTRA_OBJS)
