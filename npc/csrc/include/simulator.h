#pragma once

#define STRING_HELPER(x) #x
#define STRING(x) STRING_HELPER(x)
#define CONCAT_HELPER(x, y) x##y
#define CONCAT(x, y) CONCAT_HELPER(x, y)

#define HEADER_FILE(x) STRING(x.h)
#define ROOT_HEADER_FILE(x) STRING(CONCAT(x, ___024root.h))

#include HEADER_FILE(TOP_NAME)
#include ROOT_HEADER_FILE(TOP_NAME)
#include "regs.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <verilated.h>
#include <cpu.h>
#include <args.h>

#ifdef CONFIG_YSYXSOC
  #define TOP_PREFIX top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__
  #define PC_BEGIN 0xa0000000
#else 
  #define TOP_PREFIX top->rootp->ysyx_24110006__DOT__
  #define PC_BEGIN 0x80000000
#endif
#define TOP_MEMBER(member) CONCAT(TOP_PREFIX, member)

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
    cpu.pc = TOP_MEMBER(sim_pc);
    if (TOP_MEMBER(ifu_valid))
      /* cpu.inst = TOP_MEMBER(mifu__DOT__inst); */
      cpu.inst = get_inst();
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
    void quit(){
    state = SIM_STATE::QUIT;
  }
  int get_inst(){
#ifdef CONFIG_ICACHE
    return TOP_MEMBER(mifu__DOT__micache__DOT__inst);
#else
    return TOP_MEMBER(mifu__DOT__inst);
#endif
  }
};
