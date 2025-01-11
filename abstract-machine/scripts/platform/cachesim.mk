AM_SRCS := riscv/cachesim/start.S \
					 riscv/cachesim/bootloader.S \
           riscv/cachesim/trm.c \
           riscv/cachesim/ioe.c \
           riscv/cachesim/timer.c \
           riscv/cachesim/input.c \
           riscv/cachesim/cte.c \
           riscv/cachesim/trap.S \
					 riscv/cachesim/gpu.c \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
LDSCRIPTS += $(AM_HOME)/scripts/ysyxsoc.ld
LDFLAGS   += --defsym=_sram_start=0x0f000000 --defsym=_mrom_start=0x20000000
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"
NEMUFLAGS += -c /home/mland/ysyx-workbench/cachesim/itrace/$(NAME).dat -b -l $(shell dirname $(IMAGE).elf)/nemu-log.txt


insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin


run: insert-arg
	$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin CONFIG_CACHESIM=1
	$(MAKE) -C $(NPC_HOME)/../cachesim run ITRACE=$(NAME).txt

cachesim: insert-arg
	$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin CONFIG_CACHESIM=1
	$(MAKE) -C $(NPC_HOME)/../cachesim cachesim
	cd /home/mland/ysyx-workbench/cachesim && python main.py $(NAME).dat

gdb: insert-arg
	$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin CONFIG_CACHESIM=1
	# $(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin CONFIG_YSYXSOC=1
.PHONY: insert-arg
