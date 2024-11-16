#include "simulator.h"
#include <getopt.h>
#include <nvboard.h>
Simulator::Simulator(Args& args) :is_nvboard(args.is_nvboard), is_gtk(args.is_gtk), gtk_file(args.gtk_file){
  top = new TOP_NAME;
  if (is_gtk) {
    Verilated::traceEverOn(true);
    contextp = new VerilatedContext;
    tfp = new VerilatedFstC;
    top->trace(tfp, 0);
    tfp->open(gtk_file);
  }
  if (is_nvboard) {
    void nvboard_bind_all_pins(TOP_NAME *);
    nvboard_bind_all_pins(top);
    nvboard_init();
  }
}


void Simulator::step_and_dump_wave() {
  top->eval();
  if (is_gtk) {
    contextp->timeInc(1);
    tfp->dump(contextp->time());
  }
}

void Simulator::single_cycle() {
  top->clock = 1;
  step_and_dump_wave();
  top->clock = 0;
  step_and_dump_wave();
}

SIM_STATE Simulator::exec_once(){
  if (is_nvboard) nvboard_update();
  single_cycle();
  cpu_update();
  return state;
}

int Simulator::run() {

  while (true) {
    if (is_nvboard)
      nvboard_update();
    single_cycle();
  }
  return 0;
}
Simulator::~Simulator() {
  top->final();
  delete top;
  if (is_gtk) {
    tfp->close();
    delete tfp;
    delete contextp;
  }
}
