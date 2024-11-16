#pragma once
#include <elf.h>

class Ftrace{
  Elf32_Sym* func_table;
  char* string_table;
  int func_num = 0;
  int space_num = 0;
  int func_head(uint32_t ptr);
  int func_body(uint32_t ptr);
public:
  Ftrace(const char* filename);
  void trace(uint32_t pc, uint32_t upc, bool jump);
};
