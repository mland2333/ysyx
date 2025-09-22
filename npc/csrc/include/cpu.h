#pragma once

#include <cstdint>
#include <cstdio>
#include <iostream>
#include <regs.h>
template <uint32_t N> class Cpu {
public:
  uint32_t gpr[N] = {0};
  uint32_t pc = 0;
  constexpr static uint32_t nums = N;
  Cpu() {
    pc = 0x80000000;
  }
  void display() {
    for (int i = 0; i < N; i++) {
      std::cout << RegName::regs[i] << "=" << gpr[i] << "  ";
    }
    std::cout << '\n';
  }
  template <uint32_t T> int check(Cpu<T> *ref_cpu) {
    int state = 0;
    for (int i = 1; i < N; i++) {
      if (gpr[i] != ref_cpu->gpr[i]) {
        printf("x[%d]错误,cpu:0x%x, ref:0x%x\n", i, gpr[i], ref_cpu->gpr[i]);
        state = 1;
      }
    }
    if (pc != ref_cpu->pc) {
      return -1;
    }
    return state;
  }
};
