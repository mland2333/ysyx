#include "simulator.h"
#include <getopt.h>
#include <nvboard.h>
Simulator::Simulator(int argc, char* argv[]){
  top = new TOP_NAME;
  args_init(argc, argv);
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

void Simulator::args_init(int argc, char* argv[]){
  const struct option table[] = {
    {"nvboard"  , no_argument      , NULL, 'n'},
    {"gtktrace" , required_argument, NULL, 'g'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "ng:", table, NULL)) != -1) {
    switch (o) {
      case 'n': is_nvboard = true; break;
      case 'g': is_gtk = true; gtk_file = optarg; break;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-n,--nvboard            run with nvboard\n");
        printf("\t-g,--gtk=FILE           run with gtk_trace FILE\n");
        printf("\n");
        exit(0);
    }
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

int Simulator::exec_once(){
  if (is_nvboard) nvboard_update();
  single_cycle();
  return 0;
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
  delete top;
  if (is_gtk) {
    delete tfp;
    delete contextp;
  }
}
