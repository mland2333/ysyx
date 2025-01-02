#pragma once
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
/* #include "Vtop.h" */
#include "regs.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <verilated.h>
#include <cpu.h>
#include <args.h>
/* #include <Vtop___024root.h> */
#define TOP_MEMBER(member) top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ ## member

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
  void cpu_update(){
    for (int i = 0; i < 16; i++) {
      cpu.gpr[i] = TOP_MEMBER(mreg__DOT__rf[i]);
    }
    cpu.pc = TOP_MEMBER(mpc__DOT__pc);
    if (TOP_MEMBER(ifu_valid))
      cpu.inst = TOP_MEMBER(mifu__DOT__inst);
  }
  SIM_STATE state = SIM_STATE::NORMAL;
public:
  TOP_NAME *top;
  Cpu<REG_NUMS> cpu;
  
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
  /* bool is_jump(){ */
  /*   return TOP_MEMBER(mpc__DOT__jump); */
  /* } */
  /* uint32_t get_upc(){ */
  /*   return TOP_MEMBER(upc); */
  /* } */
  void quit(){
    state = SIM_STATE::QUIT;
  }
};
