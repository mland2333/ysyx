#pragma once

#include <args.h>
#include <cpu.h>
#include <cstdint>
#include <cstdio>
#include <debug/difftest.h>
#include <debug/ftrace.h>
#include <debug/itrace.h>
#include <functional>
#include <iostream>
#include <memory.h>
#include <perf.h>
#include <simulator.h>
#include <unordered_map>
enum class NPC_STATE { RUNNING, STOP, ABORT, QUIT };
class Sdb {
  std::unordered_map<std::string, std::function<SIM_STATE(Sdb *, char *)>>
      sdb_map_;
  Args args;
  const char *diff_file =
      "/home/mland/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
  // PerfMonitor perf;
  uint32_t inst = 0;
  uint32_t pc = 0;
  Simulator *sim;
  Memory *mem;
  Itrace *itrace;
  Ftrace *ftrace;
  Diff *diff;
  bool is_time_to_diff = false;
  bool is_time_to_trace = false;
  uint64_t rtc_begin;
  uint64_t inst_num = 0;
  uint64_t clk_num = 0;
  uint64_t ibuf_empty = 0, ibuf_full = 0, flush_num = 0;
  uint64_t rob_full = 0;

public:
  Sdb(Args &args, Simulator *sim, Memory *mem);
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
  void diff_skip_step() {
    if (args.is_diff)
      diff->diff_skip_step();
  }
  void difftest() { is_time_to_diff = true; }
  void fetch_inst() {
    is_time_to_trace = true;
  }
  void update_reg(int rd, int wdata) { sim->update_reg(rd, wdata); }
  void update_pc(int32_t pc) { sim->update_pc(pc); }
  void update_inst(int32_t inst) { sim->update_inst(inst); }
  void perf();
};
