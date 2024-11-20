#pragma once

#include <cstdint>
#define MAX_RING_BUFFER 20

class Itrace{
  char ring_buffer[MAX_RING_BUFFER][128];
  char inst_buf[128];
  char logstr[128];
  int buffer_index = 0;
public:
  Itrace();
  ~Itrace();
  void insert_buffer();
  void print_buffer();
  void trace(uint32_t pc, uint32_t inst);
};
