#pragma once
#include <elf.h>
#include <string>

class Ftrace{
  Elf32_Sym* func_table;
  char* string_table;
  int func_num = 0;
  int space_num = 0;
  std::string filename;
  int func_head(uint32_t ptr);
  int func_body(uint32_t ptr);
  void ftrace_file(const char*);
public:
  Ftrace(const char* filename);
  void trace(uint32_t pc, uint32_t upc, bool jump);
};
