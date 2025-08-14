ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

ifdef CONFIG_YSYXSOC
TOPNAME = ysyxSoCFull
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/spi/rtl
VERILATOR_CFLAGS += --timescale "1ns/1ns" --notiming -DCONFIG_YSYXSOC
CXXFLAGS += -DCONFIG_YSYXSOC

else
TOPNAME = ysyx_24110006
endif

NXDC_FILES = constr/top.nxdc
INC_PATH += $(NPC_HOME)/csrc/include
INC_PATH += $(NPC_HOME)/vsrc
INC_PATH += $(NPC_HOME)/vsrc/config
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --autoflush --trace-fst --trace-structs -DDUMP_INTERFACE_HIERARCHY -Wno-WIDTHEXPAND
VERILATOR_CFLAGS += -DCONFIG_SIM
LIBS += -lcapstone
ARGS ?=

CXXFLAGS += -DCONFIG_ICACHE
CXXFLAGS += -DCONFIG_RENAME
VERILATOR_CFLAGS += -sv
VERILATOR_CFLAGS += -DCONFIG_DCACHE
VERILATOR_CFLAGS += -DCONFIG_IBUFFER
VERILATOR_CFLAGS += -DCONFIG_RENAME
VERILATOR_CFLAGS += -Wno-UNOPTFLAT
# VERILATOR_CFLAGS += -DCONFIG_ICACHE
# VERILATOR_CFLAGS += -DCONFIG_PIPELINE
# VERILATOR_CFLAGS += -DCONFIG_FORWARD
# VERILATOR_CFLAGS += -DCONFIG_ICACHE_PIPELINE
# VERILATOR_CFLAGS += -DCONFIG_BTB
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
IMG ?=
default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
ifdef CONFIG_NVBOARD
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
CSRCS += $(SRC_AUTO_BIND)
CXXFLAGS += -fsanitize=address
LDFLAGS +=  -fsanitize=address
include $(NVBOARD_HOME)/scripts/nvboard.mk
endif

ifdef CONFIG_YSYXSOC
VSRCS += $(YSYX_HOME)/ysyxSoC/build/ysyxSoCFull.v
VSRCS += $(shell find $(abspath ./vsrc/package) -name "*.v" -or -name "*.sv")
# VSRCS += $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
VSRCS += $(shell find $(abspath ./vsrc) -path "$(abspath ./vsrc)/package" -prune -o \( -name "*.v" -o -name "*.sv" \) -print)
VSRCS += $(shell find $(abspath $(YSYX_HOME)/ysyxSoC/perip) -name "*.v")
else
# VSRCS += $(shell find $(abspath ./vsrc/package) -name "*.v" -or -name "*.sv")
VSRCS += ./vsrc/package/reg_defs.sv
VSRCS += ./vsrc/package/bp_defs.sv
VSRCS += ./vsrc/package/pipe_defs.sv
VSRCS += ./vsrc/package/rename_defs.sv
VSRCS += ./vsrc/package/bypass_defs.sv
VSRCS += ./vsrc/package/rob_defs.sv
VSRCS += ./vsrc/package/alu_defs.sv
VSRCS += ./vsrc/package/lsu_defs.sv
VSRCS += ./vsrc/package/ooo_defs.sv
VSRCS += $(shell find $(abspath ./vsrc) -path "$(abspath ./vsrc)/package" -prune -o \( -name "*.v" -o -name "*.sv" \) -print)
# VSRCS += $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
endif

CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)
CSRCS += $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" -DTOP_NAME_NOTV="$(TOPNAME)" -g
LDFLAGS += $(LIBS) -lSDL2
# CXXFLAGS += -flto
LDFLAGS += -flto
# LDFLAGS += -fuse-ld=lld
LDFLAGS += -fuse-ld=mold
OBJCACHE = ccache
CC = ccache gcc
CXX = ccache g++

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	# @rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
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
perf:
	rm -rf result
	rm -rf $(BUILD_DIR)
	python3 perf.py

parallel: $(BIN)
	python3 parallel.py $^ "$(ARGS)"

include ../Makefile
