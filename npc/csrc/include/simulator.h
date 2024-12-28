#pragma once
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
/* #include "Vtop.h" */
#include "verilated_fst_c.h"
#include <iostream>
#include <verilated.h>
#include <cpu.h>
#include <args.h>
/* #include <Vtop___024root.h> */
enum class SIM_STATE{
  NORMAL,
  QUIT,
  DIFF_FAILURE
};
class Simulator {
private:
  
  VerilatedContext *contextp;
  VerilatedFstC *tfp;
  bool is_gtk = false;
  bool is_nvboard = false;
  void step_and_dump_wave(); 
  void single_cycle();
  void args_init(int argc, char *argv[]);
  void cpu_update(){
    for (int i = 0; i < cpu.nums; i++) {
      cpu.gpr[i] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__mreg__DOT__rf[i];
    }
    cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__mpc__DOT__pc;
  }
  SIM_STATE state = SIM_STATE::NORMAL;
public:
  TOP_NAME *top;
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
  bool is_jump(){
    return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__jump;
  }
  uint32_t get_upc(){
    return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__upc;
  }
  void quit(){
    state = SIM_STATE::QUIT;
  }
  int get_inst(){
    return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__mifu__DOT__inst;
  }
};
