# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

FIPS202_SRCS = $(wildcard mldsa/src/fips202/*.c)
ifeq ($(OPT),1)
	FIPS202_SRCS += $(wildcard mldsa/src/fips202/native/aarch64/src/*.S) $(wildcard mldsa/src/fips202/native/aarch64/src/*.c) $(wildcard mldsa/src/fips202/native/x86_64/src/*.c)
endif


SOURCES += $(wildcard mldsa/src/*.c)
ifeq ($(OPT),1)
	SOURCES += $(wildcard mldsa/src/native/aarch64/src/*.[csS]) $(wildcard mldsa/src/native/x86_64/src/*.[csS])
	CFLAGS += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH -DMLD_CONFIG_USE_NATIVE_BACKEND_FIPS202
endif

ALL_TESTS = test_mldsa test_unit acvp_mldsa bench_mldsa bench_components_mldsa gen_KAT test_stack test_alloc test_rng_fail

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
MLDSA44_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
MLDSA65_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
MLDSA87_UNIT_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/unit,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_UNIT_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes

# Alloc test object files - same sources but with custom alloc config
MLDSA44_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"
MLDSA65_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"
MLDSA87_ALLOC_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/alloc,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_ALLOC_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"

# RNG fail test object files - same sources but with custom randombytes config
MLDSA44_RNG_FAIL_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR)/rng_fail,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_RNG_FAIL_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"
MLDSA65_RNG_FAIL_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR)/rng_fail,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_RNG_FAIL_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"
MLDSA87_RNG_FAIL_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR)/rng_fail,$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_RNG_FAIL_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"


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

# RNG fail test libraries with custom randombytes config
$(BUILD_DIR)/libmldsa44_rng_fail.a: $(MLDSA44_RNG_FAIL_OBJS)
$(BUILD_DIR)/libmldsa65_rng_fail.a: $(MLDSA65_RNG_FAIL_OBJS)
$(BUILD_DIR)/libmldsa87_rng_fail.a: $(MLDSA87_RNG_FAIL_OBJS)

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

$(MLDSA44_DIR)/test/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"
$(MLDSA65_DIR)/test/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"
$(MLDSA87_DIR)/test/test_alloc.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_alloc_config.h\"

$(MLDSA44_DIR)/test/test_rng_fail.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"
$(MLDSA65_DIR)/test/test_rng_fail.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"
$(MLDSA87_DIR)/test/test_rng_fail.c.o: CFLAGS += -DMLD_CONFIG_FILE=\"../test/test_rng_fail_config.h\"

$(MLDSA44_DIR)/bin/test_unit44: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
$(MLDSA65_DIR)/bin/test_unit65: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes
$(MLDSA87_DIR)/bin/test_unit87: CFLAGS += -DMLD_STATIC_TESTABLE= -Wno-missing-prototypes

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
$(BUILD_DIR)/$(1)/bin/$(2)$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/$(2).c.o $(BUILD_DIR)/lib$(1).a
endef


# Special rule for test_unit - link against unit libraries with exposed internal functions
define ADD_SOURCE_UNIT
$(BUILD_DIR)/$(1)/bin/test_unit$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)_unit
$(BUILD_DIR)/$(1)/bin/test_unit$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/test_unit.c.o $(BUILD_DIR)/lib$(1)_unit.a $(call MAKE_OBJS, $(BUILD_DIR)/$(1), $(wildcard test/notrandombytes/*.c))
endef

# Special rule for test_alloc - link against alloc libraries with custom alloc config
define ADD_SOURCE_ALLOC
$(BUILD_DIR)/$(1)/bin/test_alloc$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)_alloc
$(BUILD_DIR)/$(1)/bin/test_alloc$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/test_alloc.c.o $(BUILD_DIR)/lib$(1)_alloc.a $(call MAKE_OBJS, $(BUILD_DIR)/$(1), $(wildcard test/notrandombytes/*.c))
endef

# Special rule for test_rng_fail - link against rng_fail libraries with custom randombytes config
define ADD_SOURCE_RNG_FAIL
$(BUILD_DIR)/$(1)/bin/test_rng_fail$(subst mldsa,,$(1)): LDLIBS += -L$(BUILD_DIR) -l$(1)_rng_fail
$(BUILD_DIR)/$(1)/bin/test_rng_fail$(subst mldsa,,$(1)): $(BUILD_DIR)/$(1)/test/test_rng_fail.c.o $(BUILD_DIR)/lib$(1)_rng_fail.a
endef

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(foreach test,$(filter-out test_unit test_alloc test_rng_fail,$(ALL_TESTS)), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test))) \
	) \
)

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(eval $(call ADD_SOURCE_UNIT,$(scheme))) \
)

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(eval $(call ADD_SOURCE_ALLOC,$(scheme))) \
)

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(eval $(call ADD_SOURCE_RNG_FAIL,$(scheme))) \
)

$(ALL_TESTS:%=$(MLDSA44_DIR)/bin/%44): $(call MAKE_OBJS, $(MLDSA44_DIR), $(wildcard test/notrandombytes/*.c) $(EXTRA_SOURCES))
$(ALL_TESTS:%=$(MLDSA65_DIR)/bin/%65): $(call MAKE_OBJS, $(MLDSA65_DIR), $(wildcard test/notrandombytes/*.c) $(EXTRA_SOURCES))
$(ALL_TESTS:%=$(MLDSA87_DIR)/bin/%87): $(call MAKE_OBJS, $(MLDSA87_DIR), $(wildcard test/notrandombytes/*.c) $(EXTRA_SOURCES))

# Apply EXTRA_CFLAGS to EXTRA_SOURCES object files
ifneq ($(EXTRA_SOURCES),)
$(call MAKE_OBJS, $(MLDSA44_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA65_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
$(call MAKE_OBJS, $(MLDSA87_DIR), $(EXTRA_SOURCES)): CFLAGS += $(EXTRA_SOURCES_CFLAGS)
endif

