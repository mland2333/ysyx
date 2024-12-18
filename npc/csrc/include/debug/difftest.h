#pragma once
#include <cpu.h>
#include <memory.hpp>

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
class Diff{
  Memory* mem_;
  Cpu<32>* cpu_;
  Cpu<32>* ref_cpu;
  bool first_inst = true;
  bool diff_skip = false, diff_skip_buf = false;
public:
  Diff(Memory* mem, Cpu<32>* cpu) : mem_(mem), cpu_(cpu){
    ref_cpu = new Cpu<32>();
  }
  ~Diff(){ delete ref_cpu;}
  void init_difftest(const char *ref_so_file, long img_size, int port);
  bool difftest_step();
  void diff_skip_step(){ diff_skip_buf = true;}

};


