ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

TOPNAME = ysyxSoCFull
NXDC_FILES = constr/top.nxdc
INC_PATH += $(NPC_HOME)/csrc/include
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace-fst --autoflush --timescale "1ns/1ns" --notiming -j 8 \
				-Wno-WIDTHEXPAND

INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/spi/rtl

LIBS += -lcapstone
ARGS ?=

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
IMG ?=
default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS += $(YSYX_HOME)/ysyxSoC/build/ysyxSoCFull.v
VSRCS += $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(abspath $(YSYX_HOME)/ysyxSoC/perip) -name "*.v")

CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)
CSRCS = $(SRC_AUTO_BIND)
CSRCS += $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" -g -fsanitize=address
LDFLAGS += $(LIBS) -fsanitize=address
OBJCACHE = ccache
# CC = ccache gcc
# CXX = ccache g++

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	# @rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module ysyxSoCFull $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(INCFLAGS) --Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

run: $(BIN)
	@$^ $(IMG) $(ARGS)
gdb: $(BIN)
	gdb --args $(BIN) $(IMG) $(ARGS)
clean:
	rm -rf $(BUILD_DIR)
include ../Makefile
