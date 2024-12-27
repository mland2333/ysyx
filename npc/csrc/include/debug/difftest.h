#pragma once
#include <area.hpp>
#include <cpu.h>
#include <cstdint>
#include <memory.h>

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
class Diff{
  Area* area_;
  Cpu<32>* cpu_;
  Cpu<32>* ref_cpu;
  bool first_inst = true;
  bool diff_skip = false, diff_skip_buf = false;
  
public:
  uint64_t diff_nums = 0;
  Diff(Area* area, Cpu<32>* cpu) : area_(area), cpu_(cpu){
    ref_cpu = new Cpu<32>();
  }
  ~Diff(){ delete ref_cpu;}
  void init_difftest(const char *ref_so_file, int port);
  bool difftest_step();
  void diff_skip_step(){ diff_skip_buf = true;}

};


