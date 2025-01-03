AM_SRCS := riscv/ysyxsoc/start.S \
					 riscv/ysyxsoc/bootloader.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/ioe.c \
           riscv/ysyxsoc/timer.c \
           riscv/ysyxsoc/input.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/trap.S \
					 riscv/ysyxsoc/gpu.c \
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



insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin


run: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin CONFIG_YSYXSOC=1
gdb: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin CONFIG_YSYXSOC=1
.PHONY: insert-arg
