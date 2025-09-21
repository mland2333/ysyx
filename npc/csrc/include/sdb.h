#pragma once

#include <args.h>
#include <cpu.h>
#include <cstdint>
#include <cstdio>
#include <debug/difftest.h>
#include <functional>
#include <iostream>
#include <memory.h>
#include <sim.h>
#include <unordered_map>
enum class NPC_STATE { RUNNING, STOP, ABORT, QUIT };
class Sdb {
  std::unordered_map<std::string, std::function<SIM_STATE(Sdb *, char *)>>
      sdb_map_;
  Args args;
  const char *diff_file =
      "/home/mland/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
  Sim *sim;
  Memory *mem;
  Diff *diff;
  uint64_t rtc_begin = 0;
  uint64_t inst_num = 0;
  uint64_t clk_num = 0;
public:
  Sdb(Args &args, Sim *sim, Memory *mem);
  ~Sdb();
  void init();
  void welcome();
  void add_command(const char *command,
                   std::function<SIM_STATE(Sdb *, char *)> func) {
    sdb_map_[command] = func;
  }
  SIM_STATE exec_once();
  SIM_STATE exec(uint32_t n);
  void cpu_display() { sim->cpu.display(); }
  uint32_t mem_read(uint32_t addr) {
    if (args.is_mtrace)
      printf("pc=0x%x, raddr=0x%x, ", sim->cpu.pc, addr);
    uint32_t rdata = mem->read(addr & ~0x3u);
    if (args.is_mtrace)
      printf("rdata=0x%x\n", rdata);
    return rdata;
  }
  void mem_write(uint32_t addr, uint32_t wdata, char wmask) {
    if (args.is_mtrace)
      printf("pc=0x%x, waddr=0x%x, wdata=0x%x\n", sim->cpu.pc, addr, wdata);
    mem->write(addr & ~3u, wdata, wmask);
  }
  void quit() { sim->quit(); }
  uint64_t get_rtc();
  int run();
  int fetch_inst(int pc) { return mem_read(pc);}
};
