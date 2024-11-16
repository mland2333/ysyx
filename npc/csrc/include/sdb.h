#pragma once

#include <cstdint>
#include <cstdio>
#include <functional>
#include <unordered_map>
#include <iostream>
#include <simulator.h>
#include <memory.hpp>
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
  bool is_diff = false;
  const char* diff_file = "/home/mland/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
  uint64_t timer = 0;
  uint64_t inst_nums = 0;
  uint32_t inst_ = 0;
  uint32_t pc_ = 0;
  void statistic();
  uint64_t get_time();
  Simulator* sim_;
  Memory* mem_;

  Itrace* itrace;
  Ftrace* ftrace;
  Diff* diff;
public:
  Sdb(Args& args, Simulator* sim, Memory* mem);
  void init();
  void welcome();
  void add_command(const char* command, std::function<SIM_STATE(Sdb*, char*)> func){
    sdb_map_[command] = func;
  }
  SIM_STATE exec_once();
  SIM_STATE exec(int n);
  void cpu_display(){
    sim_->cpu.display();
  }
  uint32_t mem_read(uint32_t addr){
    return mem_->read<uint32_t>(addr);
  }
  uint32_t inst_fetch(uint32_t pc){
    inst_ = mem_->read<uint32_t>(pc);
    pc_ = pc;
    return inst_;
  }
  void quit(){
    sim_->quit();
  }
  int run();
};
