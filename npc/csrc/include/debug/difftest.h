#pragma once
#include "regs.h"
#include <area.h>
#include <cpu.h>
#include <cstdint>
#include <memory.h>
#define BUF_NUMS 10
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
class Diff {
  Cpu<REG_NUMS> *cpu;
  Cpu<32> *ref_cpu;

public:
  uint64_t diff_nums = 0;

  Diff(Cpu<REG_NUMS> *cpu_) : cpu(cpu_) { ref_cpu = new Cpu<32>(); }
  ~Diff() { delete ref_cpu; }
  bool difftest_skip = false;
  void init_difftest(const char *ref_so_file, int port, const char *img);
  bool difftest_step(int n);
};
