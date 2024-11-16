#pragma once

#include <elf.h>

typedef struct{
  Elf32_Sym* func_table;
  char* string_table;
  int func_num;
} Ftrace;
Ftrace* init_ftrace(char* filename);

int call_func(uint32_t ptr);
int ret_func(uint32_t ptr);



