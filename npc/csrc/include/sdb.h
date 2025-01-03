#pragma once

#include <cstdint>
#include <cstdio>
#include <functional>
#include <unordered_map>
#include <iostream>
#include <simulator.h>
#include <memory.h>
#include <args.h>
#include <cpu.h>
#include <debug/itrace.h>
#include <debug/ftrace.h>
#include <debug/difftest.h>
enum class NPC_STATE{
  RUNNING,
  STOP,
  ABORT,
  QUIT
};
class Sdb{
  std::unordered_map<std::string, std::function<SIM_STATE(Sdb*, char*)>> sdb_map_;
  bool is_batch = false;
  bool is_itrace = false;
  bool is_ftrace = false;
  bool is_mtrace = false;
  bool is_diff = false;
  bool is_vga = false;
  const char* diff_file = "/home/mland/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
  uint64_t timer = 0;
  uint64_t inst_nums = 0;
  uint64_t clk_nums = 0;
  uint32_t inst = 0;
  uint32_t pc = 0;
  void statistic();
  Simulator* sim;
  Memory* mem;
  Itrace* itrace;
  Ftrace* ftrace;
  Diff* diff;
  bool is_time_to_diff = false;
  bool is_time_to_trace = false;
  uint64_t rtc_begin;
public:
  Sdb(Args& args, Simulator* sim, Memory* mem);
  ~Sdb(); 
  void init();
  void welcome();
  void add_command(const char* command, std::function<SIM_STATE(Sdb*, char*)> func){
    sdb_map_[command] = func;
  }
  SIM_STATE exec_once();
  SIM_STATE exec(int n);
  void cpu_display(){
    sim->cpu.display();
  }
  uint32_t mem_read(uint32_t addr){
    if (is_mtrace) printf("pc=0x%x, raddr=0x%x, ", pc, addr);
    uint32_t rdata = mem->read(addr & ~0x3u);
    if (is_mtrace) printf("rdata=0x%x\n", rdata);
    return rdata;
  }
  void mem_write(uint32_t addr, uint32_t wdata, char wmask){
    if (is_mtrace) printf("pc=0x%x, waddr=0x%x, wdata=0x%x\n", pc, addr, wdata);
    mem->write(addr, wdata, wmask);
  }
  void quit(){
    sim->quit();
  }
  uint64_t get_rtc();
  int run();
  void diff_skip_step(){ if(is_diff) diff->diff_skip_step();}
  void difftest(){ is_time_to_diff = true; }
  void fetch_inst() { inst_nums++; is_time_to_trace = true; }
};
