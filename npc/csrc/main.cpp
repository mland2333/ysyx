#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"
/* #include "verilated_vcd_c.h" */
#include "verilated_fst_c.h"
int main(int argc, char **argv) {
  // See a similar example walkthrough in the verilator manpage.

  // This is intended to be a minimal example.  Before copying this to start a
  // real project, it is better to start with a more complete example,
  // e.g. examples/c_tracing.
  
  // Construct a VerilatedContext to hold simulation time, etc.
  VerilatedContext *const contextp = new VerilatedContext;
  /* VerilatedVcdC* tfp = new VerilatedVcdC; */
  VerilatedFstC* tfp = new VerilatedFstC;
  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  // Construct the Verilated model, from Vtop.h generated from Verilating
  // "top.v"
  Vtop *const top = new Vtop{contextp};
  top->trace(tfp, 99);
  /* tfp->open("dump.vcd"); */
  tfp->open("dump.fst");
  top->clk = 0;
  int clk = 0;
  // Simulate until $finish
  while (!contextp->gotFinish()) {
    if(clk == 99) break;
    clk ++;
    top->clk = !top->clk;
    int a = rand() & 1;
    int b = rand() & 1;
    top->a = a;
    top->b = b;
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
    printf("a = %d, b = %d, f = %d\n", a, b, top->f);
    assert(top->f == (a ^ b));
    // Evaluate model
  }

  // Final model cleanup
  top->final();
  tfp->close();
  // Destroy model
  delete top;

  // Return good completion status
  return 0;
}
