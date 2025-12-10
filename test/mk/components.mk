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

ALL_TESTS = test_mldsa acvp_mldsa bench_mldsa bench_components_mldsa gen_KAT test_stack

MLDSA44_DIR = $(BUILD_DIR)/mldsa44
MLDSA65_DIR = $(BUILD_DIR)/mldsa65
MLDSA87_DIR = $(BUILD_DIR)/mldsa87

MLDSA44_OBJS = $(call MAKE_OBJS,$(MLDSA44_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA44_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
MLDSA65_OBJS = $(call MAKE_OBJS,$(MLDSA65_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA65_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
MLDSA87_OBJS = $(call MAKE_OBJS,$(MLDSA87_DIR),$(SOURCES) $(FIPS202_SRCS))
$(MLDSA87_OBJS): CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87


CFLAGS += -Imldsa

$(BUILD_DIR)/libmldsa44.a: $(MLDSA44_OBJS)
$(BUILD_DIR)/libmldsa65.a: $(MLDSA65_OBJS)
$(BUILD_DIR)/libmldsa87.a: $(MLDSA87_OBJS)

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

$(MLDSA44_DIR)/bin/bench_mldsa44: $(MLDSA44_DIR)/test/hal/hal.c.o
$(MLDSA65_DIR)/bin/bench_mldsa65: $(MLDSA65_DIR)/test/hal/hal.c.o
$(MLDSA87_DIR)/bin/bench_mldsa87: $(MLDSA87_DIR)/test/hal/hal.c.o
$(MLDSA44_DIR)/bin/bench_components_mldsa44: $(MLDSA44_DIR)/test/hal/hal.c.o
$(MLDSA65_DIR)/bin/bench_components_mldsa65: $(MLDSA65_DIR)/test/hal/hal.c.o
$(MLDSA87_DIR)/bin/bench_components_mldsa87: $(MLDSA87_DIR)/test/hal/hal.c.o

$(MLDSA44_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44
$(MLDSA65_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65
$(MLDSA87_DIR)/bin/%: CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87

# Link tests with respective library
define ADD_SOURCE
$(BUILD_DIR)/$(1)/bin/$(2)$(shell echo $(1) | tr -d -c 0-9): LDLIBS += -L$(BUILD_DIR) -l$(1)
$(BUILD_DIR)/$(1)/bin/$(2)$(shell echo $(1) | tr -d -c 0-9): $(BUILD_DIR)/$(1)/test/$(2).c.o $(BUILD_DIR)/lib$(1).a
endef

$(foreach scheme,mldsa44 mldsa65 mldsa87, \
	$(foreach test,$(ALL_TESTS), \
		$(eval $(call ADD_SOURCE,$(scheme),$(test))) \
	) \
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

