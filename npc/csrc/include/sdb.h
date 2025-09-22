#pragma once

#include <args.h>
#include <cpu.h>
#include <cstdint>
#include <debug/difftest.h>
#include <functional>
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
  uint64_t inst_num = 0;
  uint64_t clk_num = 0;
public:
  Sdb(Args &args, Sim *sim, Memory *mem);
  ~Sdb();
  void init();
  void welcome();
  SIM_STATE exec_once();
  SIM_STATE exec(uint32_t n);
  void cpu_display() { sim->cpu.display();}
  uint32_t mem_read(uint32_t addr);
  void mem_write(uint32_t addr, uint32_t wdata, char wmask);
  int run();
  void quit();
  int fetch_inst(int pc);
};
