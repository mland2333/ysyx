#pragma once

#include <cstdint>
#include "VysyxSoCFull_ysyxSoCFull.h"
#include "VysyxSoCFull__Syms.h"
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
#include <VysyxSoCFull_if_pipeline_vr.h>
#include <args.h>
#include <cpu.h>
#include <iostream>
#include <verilated.h>
#ifdef CONFIG_YSYXSOC
#define TOP_PREFIX                                                             \
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__top__DOT__
#define INTERFACE_PREFIX                                                       \
  top->rootp->__PVT__ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__top__DOT__
#define PC_BEGIN 0xa0000000
#else
#define TOP_PREFIX top->rootp->ysyx_24110006__DOT__
#define PC_BEGIN 0x80000000
#endif
#define TOP_MEMBER(member) CONCAT(TOP_PREFIX, member)
#define INTERFACE(member) CONCAT(INTERFACE_PREFIX, member)
#ifdef CONFIG_RISCV32E
#define REG_NUMS 16
#else
#define REG_NUMS 32
#endif
enum class SIM_STATE { NORMAL, QUIT, DIFF_FAILURE };
class Simulator {
private:
  VerilatedContext *contextp;
  VerilatedFstC *tfp;
  bool is_gtk = false;
  bool is_nvboard = false;
  void step_and_dump_wave();
  void single_cycle();
  SIM_STATE state = SIM_STATE::NORMAL;
  uint64_t old_clk = 0;
  void cpu_update(){
    for(int i = 1; i<REG_NUMS; i++)
      cpu.gpr[i] = top->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu__top.__PVT__mreg__DOT__rf[i];
    cpu.pc = top->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu__top.sim_pc;
    cpu.inst = top->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu__top.sim_inst;
  }
public:
  TOP_NAME *top;
  Cpu<REG_NUMS> cpu;
  uint32_t inst = 0;

  Simulator(Args &args);
  ~Simulator();
  int run();
  // 重置n个时钟周期
  void reset(int n) {
    top->reset = 1;
    while (n-- > 0)
      single_cycle();
    top->reset = 0;
  }
  SIM_STATE exec_once();
  void quit() { state = SIM_STATE::QUIT; }
  int get_inst() { return cpu.inst; }
  void update_inst(int32_t inst) { old_clk = cpu.inst = inst; }
  void update_reg(int rd, int wdata) { cpu.gpr[rd] = wdata; }
  void update_pc(int32_t pc) {
    cpu.pc = pc;
    // std::cout << "update_pc " << TOP_MEMBER(mtime) << "\n";
  }
};
