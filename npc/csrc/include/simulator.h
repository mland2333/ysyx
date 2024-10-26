#include "Vtop.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <verilated.h>

class Simulator {

private:
  TOP_NAME *top;
  VerilatedContext *contextp;
  VerilatedFstC *tfp;
  bool is_gtk = false;
  bool is_nvboard = false;
  char *gtk_file;

  void step_and_dump_wave(); 
  void single_cycle();
  void args_init(int argc, char *argv[]);

public:
  Simulator(int argc, char *argv[]);
  ~Simulator();
  int run();
  //重置n个时钟周期
  void reset(int n) {
    top->reset = 1;
    while (n-- > 0)
      single_cycle();
    top->reset = 0;
  }
};
