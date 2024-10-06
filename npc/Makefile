ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

CSRC += ./csrc/main.cpp
VSRC += ./vsrc/top.v

all:
	$(VERILATOR) -cc --exe --build -j --trace-fst $(VSRC) $(CSRC)

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
include ../Makefile
