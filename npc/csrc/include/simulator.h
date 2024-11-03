#pragma once

#include "Vtop.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <verilated.h>
#include <cpu.h>
#include <args.h>
#include <Vtop___024root.h>
enum class SIM_STATE{
  NORMAL,
  QUIT
};
class Simulator {
private:
  TOP_NAME *top;
  VerilatedContext *contextp;
  VerilatedFstC *tfp;
  bool is_gtk = false;
  bool is_nvboard = false;
  char *gtk_file;
  void step_and_dump_wave(); 
  void single_cycle();
  void args_init(int argc, char *argv[]);
  void cpu_update(){
    for (int i = 0; i < cpu.nums; i++) {
      cpu.gpr[i] = top->rootp->top__DOT__mreg__DOT__rf[i];
    }
    cpu.pc = top->rootp->top__DOT__pc;
  }
  SIM_STATE state = SIM_STATE::NORMAL;
public:
  Cpu<32> cpu;
  
  Simulator(Args& args);
  ~Simulator();
  int run();
  //重置n个时钟周期
  void reset(int n) {
    top->reset = 1;
    while (n-- > 0)
      single_cycle();
    top->reset = 0;
    cpu_update();
  }
  SIM_STATE exec_once();
  void quit(){
    state = SIM_STATE::QUIT;
  }
};