# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

FIPS202_SRCS = $(wildcard mldsa/src/fips202/*.c)
ifeq ($(OPT),1)
	FIPS202_SRCS += $(wildcard mldsa/src/fips202/native/aarch64/src/*.S) \
		$(wildcard mldsa/src/fips202/native/aarch64/src/*.c) \
		$(wildcard mldsa/src/fips202/native/x86_64/src/*.c) \
		$(wildcard mldsa/src/fips202/native/x86_64/src/*.S) \
		$(wildcard mldsa/src/fips202/native/armv81m/src/*.[csS])
endif

SOURCES += $(wildcard mldsa/src/*.c)
ifeq ($(OPT),1)
	SOURCES += $(wildcard mldsa/src/native/aarch64/src/*.[csS]) \
		$(wildcard mldsa/src/native/x86_64/src/*.[csS])
	CFLAGS += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH \
		-DMLD_CONFIG_USE_NATIVE_BACKEND_FIPS202
endif

LIB_SRCS := $(SOURCES) $(FIPS202_SRCS)

BASIC_TESTS = test_mldsa gen_KAT test_stack
ACVP_TESTS = acvp_mldsa
WYCHEPROOF_TESTS = wycheproof_mldsa
BENCH_TESTS = bench_mldsa bench_components_mldsa
UNIT_TESTS = test_unit
ALLOC_TESTS = test_alloc
SIGN_HOOK_TESTS = test_sign_hook
RNG_FAIL_TESTS = test_rng_fail
ALL_TESTS = $(BASIC_TESTS) $(ACVP_TESTS) $(WYCHEPROOF_TESTS) $(BENCH_TESTS) $(UNIT_TESTS) $(ALLOC_TESTS) $(SIGN_HOOK_TESTS) $(RNG_FAIL_TESTS)

MLDSA44_DIR = $(BUILD_DIR)/mldsa44
MLDSA65_DIR = $(BUILD_DIR)/mldsa65
MLDSA87_DIR = $(BUILD_DIR)/mldsa87

MLDSA44_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR),$(LIB_SRCS))
MLDSA65_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR),$(LIB_SRCS))
MLDSA87_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR),$(LIB_SRCS))

MLDSA44_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/unit,$(LIB_SRCS))
MLDSA65_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/unit,$(LIB_SRCS))
MLDSA87_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/unit,$(LIB_SRCS))

MLDSA44_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/alloc,$(LIB_SRCS))
MLDSA65_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/alloc,$(LIB_SRCS))
MLDSA87_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/alloc,$(LIB_SRCS))

MLDSA44_SIGN_HOOK_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/sign_hook,$(SOURCES) $(FIPS202_SRCS))
MLDSA65_SIGN_HOOK_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/sign_hook,$(SOURCES) $(FIPS202_SRCS))
MLDSA87_SIGN_HOOK_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/sign_hook,$(SOURCES) $(FIPS202_SRCS))

CFLAGS += -Imldsa

$(BUILD_DIR)/libmldsa44.a: $(MLDSA44_OBJS)
$(BUILD_DIR)/libmldsa65.a: $(MLDSA65_OBJS)
$(BUILD_DIR)/libmldsa87.a: $(MLDSA87_OBJS)

$(BUILD_DIR)/libmldsa44_unit.a: $(MLDSA44_UNIT_OBJS)
$(BUILD_DIR)/libmldsa65_unit.a: $(MLDSA65_UNIT_OBJS)
$(BUILD_DIR)/libmldsa87_unit.a: $(MLDSA87_UNIT_OBJS)

$(BUILD_DIR)/libmldsa44_alloc.a: $(MLDSA44_ALLOC_OBJS)
$(BUILD_DIR)/libmldsa65_alloc.a: $(MLDSA65_ALLOC_OBJS)
$(BUILD_DIR)/libmldsa87_alloc.a: $(MLDSA87_ALLOC_OBJS)

# Sign-hook test libraries with the sign-hook config
$(BUILD_DIR)/libmldsa44_sign_hook.a: $(MLDSA44_SIGN_HOOK_OBJS)
$(BUILD_DIR)/libmldsa65_sign_hook.a: $(MLDSA65_SIGN_HOOK_OBJS)
$(BUILD_DIR)/libmldsa87_sign_hook.a: $(MLDSA87_SIGN_HOOK_OBJS)

$(BUILD_DIR)/libmldsa.a: $(MLDSA44_OBJS) $(MLDSA65_OBJS) $(MLDSA87_OBJS)

# Generic CFLAGS

$(MLDSA44_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
$(MLDSA65_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
$(MLDSA87_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87

# Lib objects also get the parameter set above; this covers the test entrypoints
# (not in LIB_SRCS) and, for custom builds like Zephyr, every source.
$(MLDSA44_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
$(MLDSA65_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
$(MLDSA87_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87

# Per-test CFLAGS

$(MLDSA44_DIR)/bin/bench_mldsa44: CFLAGS += -Itest/hal
$(MLDSA65_DIR)/bin/bench_mldsa65: CFLAGS += -Itest/hal
$(MLDSA87_DIR)/bin/bench_mldsa87: CFLAGS += -Itest/hal

$(MLDSA44_DIR)/bin/bench_components_mldsa44: CFLAGS += -Itest/hal
$(MLDSA65_DIR)/bin/bench_components_mldsa65: CFLAGS += -Itest/hal
$(MLDSA87_DIR)/bin/bench_components_mldsa87: CFLAGS += -Itest/hal

$(MLDSA44_DIR)/bin/test_stack44: CFLAGS += -Imldsa -fstack-usage
$(MLDSA65_DIR)/bin/test_stack65: CFLAGS += -Imldsa -fstack-usage
$(MLDSA87_DIR)/bin/test_stack87: CFLAGS += -Imldsa -fstack-usage

$(MLDSA44_DIR)/bin/test_unit44: CFLAGS += -DMLD_STATIC_TESTABLE= -DMLD_UNIT_TEST -Wno-missing-prototypes
$(MLDSA65_DIR)/bin/test_unit65: CFLAGS += -DMLD_STATIC_TESTABLE= -DMLD_UNIT_TEST -Wno-missing-prototypes
$(MLDSA87_DIR)/bin/test_unit87: CFLAGS += -DMLD_STATIC_TESTABLE= -DMLD_UNIT_TEST -Wno-missing-prototypes

$(MLDSA44_DIR)/bin/test_alloc44: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
$(MLDSA65_DIR)/bin/test_alloc65: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"
$(MLDSA87_DIR)/bin/test_alloc87: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_alloc_config.h\"

$(MLDSA44_DIR)/bin/test_sign_hook44: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_sign_hook_config.h\"
$(MLDSA65_DIR)/bin/test_sign_hook65: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_sign_hook_config.h\"
$(MLDSA87_DIR)/bin/test_sign_hook87: CFLAGS += -DMLD_CONFIG_FILE=\"../test/configs/test_sign_hook_config.h\"

define ADD_SOURCE
# Record this binary's test sources -- entrypoint test/$(3)/$(2).c plus extras
# $(4) -- in the per-binary TEST_SRCS. A custom build (CUSTOM_BUILD, see
# test/mk/rules.mk) consumes these directly; a normal build links lib$(1)$(5).a.
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): TEST_SRCS += test/$(3)/$(2).c $(4)
ifndef CUSTOM_BUILD
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)$(5)
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): $(BUILD_DIR)/lib$(1)$(5).a
endif
endef

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(foreach test,$(ACVP_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),acvp)) \
	) \
	$(foreach test,$(WYCHEPROOF_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),wycheproof)) \
	) \
	$(foreach test,$(BENCH_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),bench,test/hal/hal.c)) \
	) \
	$(foreach test,$(BASIC_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test),src)) \
	) \
	$(eval $(call ADD_SOURCE,$(scheme),test_rng_fail,src)) \
	$(eval $(call ADD_SOURCE,$(scheme),test_unit,src,,_unit)) \
	$(eval $(call ADD_SOURCE,$(scheme),test_alloc,src,,_alloc)) \
	$(eval $(call ADD_SOURCE,$(scheme),test_sign_hook,src,,_sign_hook)) \
)

# The set of test binaries, per parameter set.
BINS_44  := $(ALL_TESTS:%=$(MLDSA44_DIR)/bin/%44)
BINS_65  := $(ALL_TESTS:%=$(MLDSA65_DIR)/bin/%65)
BINS_87  := $(ALL_TESTS:%=$(MLDSA87_DIR)/bin/%87)
ALL_BINS := $(BINS_44) $(BINS_65) $(BINS_87)

# All tests except rng_fail get notrandombytes (rng_fail provides its own).
$(filter-out %test_rng_fail44 %test_rng_fail65 %test_rng_fail87,$(ALL_BINS)): \
	TEST_SRCS += test/notrandombytes/notrandombytes.c

# Turn each binary's TEST_SRCS into its prerequisites (via .SECONDEXPANSION, as
# TEST_SRCS is a per-target variable). The scheme's object dir is derived from
# the target ($@ = .../mldsaNNN/bin/foo, so $(@D) sans /bin = .../mldsaNNN).
# Redundant in a normal build (the .a -> .o -> .c chain already implies it), but
# a custom build links the sources directly and so needs them named explicitly.
.SECONDEXPANSION:
ifndef CUSTOM_BUILD
$(ALL_BINS): $$(call MAKE_OBJS,$$(patsubst %/bin,%,$$(@D)),$$(TEST_SRCS))
# EXTRA_SOURCES (platform-specific) is a normal-build feature: its per-file
# CFLAGS only attach to object targets, which custom builds don't produce, so a
# custom-build platform handles its own extra sources in its CUSTOM_BUILD recipe.
$(ALL_BINS): TEST_SRCS += $(EXTRA_SOURCES)
ifneq ($(EXTRA_SOURCES),)
$(call MAKE_OBJS, $(MLDSA44_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA65_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA87_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
endif
else
$(ALL_BINS): $$(TEST_SRCS) $(LIB_SRCS)
# Extra per-binary prerequisites a custom-build platform needs (e.g. Zephyr's
# app inputs and active-target marker, set in test/zephyr/platform.mk).
$(ALL_BINS): $(CUSTOM_BUILD_DEPS)
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
