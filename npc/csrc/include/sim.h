#pragma once

#include <cstdint>

#include "regs.h"
#include "verilated_fst_c.h"
#include "Vtop.h"
#include "Vtop___024root.h"
#include <args.h>
#include <cpu.h>
#include <iostream>
#include <verilated.h>

#define TOP_PREFIX top->rootp->top__DOT__
#define PC_BEGIN 0x80000000

#define GET(x) x
#define GET_MEMBER_HELPER(obj, member) obj ## member
#define GET_MEMBER(member) GET_MEMBER_HELPER(top->rootp->top__DOT__, member)
#define REG_NUMS 32
enum class SIM_STATE { NORMAL, QUIT, DIFF_FAILURE, TIMEOUT};
class Sim {
public:
  VerilatedContext *contextp;
  VerilatedFstC *tfp;
  bool wave_on = false;
  bool is_nvboard = false;
  SIM_STATE state = SIM_STATE::NORMAL;
  uint64_t old_clk = 0;
  TOP_NAME *top;
  Cpu<REG_NUMS> cpu;
  Sim(Args &args);
  ~Sim();
  void step_and_dump_wave();
  void single_cycle();
  void cpu_update();
  void reset(int n);
  void open_wave(const std::string& path);
  SIM_STATE exec_once();
  void quit() { state = SIM_STATE::QUIT; }
};
