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
  bool is_mtrace = false;
  bool is_diff = false;
  bool is_vga = false;
  const char* diff_file = "/home/mland/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
  uint64_t timer = 0;
  uint64_t inst_nums = 0;
  uint32_t inst_ = 0;
  uint32_t pc_ = 0;
  void statistic();
  Simulator* sim_;
  Memory* mem_;
  Itrace* itrace;
  Ftrace* ftrace;
  Diff* diff;
  
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
    sim_->cpu.display();
  }
  uint32_t mem_read(uint32_t addr){
    if (is_mtrace) printf("pc=0x%x, raddr=0x%x, ", pc_, addr);
    uint32_t rdata = mem_->read<uint32_t>(addr);
    if (is_mtrace) printf("rdata=0x%x\n", rdata);
    return rdata;
  }
  void mem_write(uint32_t addr, uint32_t wdata, char wmask){
    if (is_mtrace) printf("pc=0x%x, waddr=0x%x, wdata=0x%x\n", pc_, addr, wdata);
    uint8_t* data = (uint8_t*)&wdata;
    for(int i = 0; i<4; i++){
      if(((1<<i)&wmask) != 0)
        mem_->write<uint8_t>(addr+i, data[i]);
    }
  }
  uint32_t inst_fetch(uint32_t pc){
    inst_ = mem_->read<uint32_t>(pc);
    pc_ = pc;
    return inst_;
  }
  void quit(){
    sim_->quit();
  }
  uint64_t get_rtc();
  int run();
  void diff_skip_step(){ if(is_diff) diff->diff_skip_step();}
};
