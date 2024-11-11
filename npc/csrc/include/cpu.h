#pragma once

#include <cstdint>
#include <iostream>

const static char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
template<uint32_t N>
class Cpu{
public:
  const uint32_t nums = N;
  uint32_t gpr[N] = {0};
  uint32_t pc = 0;
  void display(){
    for (int i = 0; i < N; i++) {
      std::cout << regs[i] << "=" << gpr[i] << "  ";
    }
    std::cout << '\n';
  }
};
