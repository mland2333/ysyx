#pragma once

#include <cstdint>
class Perf{

public:
  uint64_t clk_nums = 0;
  uint64_t inst_nums = 0;
  uint64_t timer = 0;
  double get_ipc(){
    return (double)inst_nums / (double)clk_nums;
  }
};
