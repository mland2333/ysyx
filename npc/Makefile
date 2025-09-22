TOPNAME = top
INC_PATH += $(NPC_HOME)/csrc/include
INC_PATH += $(NPC_HOME)/vsrc
INC_PATH += $(NPC_HOME)/vsrc/config
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --autoflush --trace-fst --trace-structs -DDUMP_INTERFACE_HIERARCHY -Wno-WIDTHEXPAND
VERILATOR_CFLAGS += -DCONFIG_SIM
VERILATOR_CFLAGS += -sv
VERILATOR_CFLAGS += -Wno-UNOPTFLAT
ARGS ?=

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
IMG ?=
# .PHONY: compile run gdb clean perf $(BIN)
default: complie

$(shell mkdir -p $(BUILD_DIR))

VSRCS += $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")

CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)
CSRCS += $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" -DTOP_NAME_NOTV="$(TOPNAME)" -g
LDFLAGS += $(LIBS) -lSDL2
LDFLAGS += -flto
LDFLAGS += -fuse-ld=mold
OBJCACHE = ccache
CC = ccache gcc
CXX = ccache g++
LIBS += -lcapstone
$(BIN): $(VSRCS) $(CSRCS)
	# @rm -rf $(OBJ_DIR)
	@echo "Running mill npc..."
	cd ./chisel && mill npc
	@echo "Running verilator..."
	verilator $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(INCFLAGS) --Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	@echo "Build completed: $(BIN)"

compile: $(BIN)
	@echo "Compilation finished"

sim: compile
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

run: compile
	@echo "Running simulation..."
	@$(BIN) $(IMG) $(ARGS)
gdb: compile
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
