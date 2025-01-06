#pragma once

#include "simulator.h"
#include "utils.h"
#include <cstdint>
#include <debug/log.h>
#include <simulator.h>


class Perf{
  enum {
    LOAD = 0,
    STORE,
    CSR,
    EXECUTE,
  };
public:
  uint64_t clk_nums = 0;
  uint64_t inst_nums = 0;
  uint64_t timer = 0;
  uint64_t timer_begin = 0;
  uint64_t ifu_get_inst = 0;
  uint64_t lsu_get_data =  0;
  uint64_t exu_finish_cal = 0;
  uint64_t insts[4] = {};
  uint64_t inst_clk[4] = {};
  uint64_t clk_prev = 0;
  uint64_t lsu_begin = 0;
  uint64_t lsu_clk = 0;
  uint64_t ifu_clk = 0;
  int inst_type;
  void idu_decode_inst(int inst){
    int a = inst & 0x7f;
      switch (a) {
      case 0x03:
        insts[LOAD]++;
        inst_type = LOAD;
        break;
      case 0x23:
        insts[STORE]++;
        inst_type = STORE;
        break;
      case 0x73:
        insts[CSR]++;
        inst_type = CSR;
        break;
      default:
        insts[EXECUTE]++;
        inst_type = EXECUTE;
      }
  }
  double get_ipc(){
    return (double)inst_nums / (double)clk_nums;
  }
  void trace(Simulator* sim);
  void statistic();
};
