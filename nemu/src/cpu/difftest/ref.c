/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (addr >= CONFIG_MBASE && addr < CONFIG_MBASE + CONFIG_MSIZE) {
    if (direction == DIFFTEST_TO_DUT) {
      for (int i = 0; i < n; i++) {
        *((uint8_t *)(buf) + i) = *guest_to_host(addr + i);
      }
    } else {
      for (int i = 0; i < n; i++) {
        *guest_to_host(addr + i) = *((uint8_t *)(buf) + i);
      }
    }
  }
  else if (addr >= MROM_RADDR && addr < MROM_RADDR + MROM_SIZE) {
    if (direction == DIFFTEST_TO_DUT) {
      for (int i = 0; i < n; i++) {
        *((uint8_t *)(buf) + i) = *mrom_guest_to_host(addr + i);
      }
    } else {
      for (int i = 0; i < n; i++) {
        *mrom_guest_to_host(addr + i) = *((uint8_t *)(buf) + i);
      }
    }
  }
  else if (addr >= SRAM_RADDR && addr < SRAM_RADDR + SRAM_SIZE) {
    if (direction == DIFFTEST_TO_DUT) {
      for (int i = 0; i < n; i++) {
        *((uint8_t *)(buf) + i) = *sram_guest_to_host(addr + i);
      }
    } else {
      for (int i = 0; i < n; i++) {
        *sram_guest_to_host(addr + i) = *((uint8_t *)(buf) + i);
      }
    }
  }
  else if (addr >= FLASH_RADDR && addr < FLASH_RADDR + FLASH_SIZE) {
    if (direction == DIFFTEST_TO_DUT) {
      for (int i = 0; i < n; i++) {
        *((uint8_t *)(buf) + i) = *flash_guest_to_host(addr + i);
      }
    } else {
      for (int i = 0; i < n; i++) {
        *flash_guest_to_host(addr + i) = *((uint8_t *)(buf) + i);
      }
    }
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  CPU_state *dutcpu = (CPU_state *)dut;
  if (direction == DIFFTEST_TO_REF) {
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
      cpu.gpr[i] = dutcpu->gpr[i];
    }
    cpu.pc = dutcpu->pc;
  } else {
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
      dutcpu->gpr[i] = cpu.gpr[i];
    }
    dutcpu->pc = cpu.pc;
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
