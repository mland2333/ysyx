#pragma once

#include <cstdint>

#define STRING_HELPER(x) #x
#define STRING(x) STRING_HELPER(x)
#define CONCAT_HELPER(x, y) x##y
#define CONCAT(x, y) CONCAT_HELPER(x, y)
#define CONCAT_BY(x, y, z) CONCAT(CONCAT(x, z), y)
#define ADDH(x) x.h
#define HEADER_FILE(x) STRING(ADDH(x))
#define ROOT_HEADER_FILE(x) STRING(CONCAT(x, ___024root.h))
#define SV_HEADER_FILE_HELPER(x) STRING(CONCAT_BY(TOP_NAME, x, _))
#define SV_HEADER_FILE(x) SV_HEADER_FILE_HELPER(x)

#include HEADER_FILE(TOP_NAME)
// #include ROOT_HEADER_FILE(TOP_NAME)
#include SV_HEADER_FILE(ADDH(__024root))
#include SV_HEADER_FILE(ADDH(if_pipeline_vr))
// #include SV_HEADER_FILE(ADDH(TOP_NAME_NOTV))
#include SV_HEADER_FILE(ADDH(_Syms))
#include "regs.h"
#include "verilated_fst_c.h"
#include <args.h>
#include <cpu.h>
#include <iostream>
#include <verilated.h>

#ifdef CONFIG_YSYXSOC
#define TOP_PREFIX                                                             \
  top->rootp->ysyxSoCFull->asic->cpu->cpu->top
#define PC_BEGIN 0xa0000000
#else
// #define TOP_PREFIX top->rootp->ysyx_24110006->top
#define TOP_PREFIX top->rootp->ysyx_24110006__DOT__top__DOT__
#define PC_BEGIN 0x80000000
#endif
// #define TOP_MEMBER(member) CONCAT(TOP_PREFIX, member)
// #define INTERFACE(member) CONCAT(INTERFACE_PREFIX, member)
// #define ARROW_MEMBER(obj, member) obj->member
// #define GET_MEMBER(obj, member) ARROW_MEMBER(obj, member)
#define GET(x) x
#define GET_MEMBER_HELPER(obj, member) obj ## member
#define GET_MEMBER(obj, member) GET_MEMBER_HELPER(obj, member)
#ifdef CONFIG_RISCV32E
#define REG_NUMS 16
#else
#define REG_NUMS 32
#endif
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
