#include "simulator.h"
#include <getopt.h>
#include <nvboard.h>
Simulator::Simulator(int argc, char *argv[]) {
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

void Simulator::args_init(int argc, char *argv[]) {
  constexpr struct option table[] = {
      {"batch", no_argument, NULL, 'b'},
      {"log", required_argument, NULL, 'l'},
      {"diff", required_argument, NULL, 'd'},
      {"port", required_argument, NULL, 'p'},
      {"file", required_argument, NULL, 'f'},
      {"gtktrace", required_argument, NULL, 'g'},
      {"nvboard", no_argument, NULL, 'n'},
      {"help", no_argument, NULL, 'h'},
      {0, 0, NULL, 0},
  };
  int o;
  while ((o = getopt_long(argc, argv, "-bhng:d:f:", table, NULL)) != -1) {
    switch (o) {
    case 'g':
      is_gtk = true;
      gtk_file = optarg;
      break;
    case 'n':
      is_nvboard = true;
      break;
    default:
      printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
      printf("\t-b,--batch              run with batch mode\n");
      printf("\t-l,--log=FILE           output log to FILE\n");
      printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
      printf("\t-g,--gtktrace           run with gtktrace\n");
      printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
      printf("\n");
      exit(0);
    }
  }
  return;
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

int Simulator::run() {

  while (!contextp->gotFinish()) {
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
