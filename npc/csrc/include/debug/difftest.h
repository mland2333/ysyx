#pragma once
#include "regs.h"
#include <area.hpp>
#include <cpu.h>
#include <cstdint>
#include <memory.h>
#define BUF_NUMS 10
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
class Diff{
  const Area* area;
  Cpu<REG_NUMS>* cpu;
  Cpu<32>* ref_cpu;
  bool diff_skip_buf[BUF_NUMS] = {};
  int read_index = 0, write_index = 0;
  
public:
  uint64_t diff_nums = 0;
  
  Diff(const Area* area_, Cpu<REG_NUMS>* cpu_) : area(area_), cpu(cpu_){
    ref_cpu = new Cpu<32>();
  }
  ~Diff(){ delete ref_cpu;}
  void init_difftest(const char *ref_so_file, int port);
  bool difftest_step();
  void diff_skip_step(){ diff_skip_buf[write_index] = true; write_index = (write_index+1)%BUF_NUMS; }

};


