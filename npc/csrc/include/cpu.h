#pragma once

#include <cstdint>
#include <iostream>
#include <regs.h>
template<uint32_t N>
class Cpu{
public:
  uint32_t gpr[N] = {0};
  uint32_t pc = 0;
  const uint32_t nums = N;
  void display(){
    for (int i = 0; i < N; i++) {
      std::cout << RegName::regs[i] << "=" << gpr[i] << "  ";
    }
    std::cout << '\n';
  }
  int check(Cpu<N>* ref_cpu){
    for (int i = 1 ; i < N; i++) {
      if (gpr[i] != ref_cpu->gpr[i])
        return i;
    }
    if (pc != ref_cpu->pc) {
      return -1;
    }
    return 0;
  }
};
