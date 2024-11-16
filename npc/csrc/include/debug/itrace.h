#pragma once

#define MAX_RING_BUFFER 20

class Itrace{
  char ring_buffer[MAX_RING_BUFFER][128];
  int buffer_index = 0;
public:
  Itrace();
  void insert_buffer(char* logstr);
  void print_buffer();
};
