#include "sim.h"
#include <cstdio>
#include <getopt.h>
#ifdef CONFIG_NVBOARD
#include <nvboard.h>
#endif

Sim::Sim(Args &args) : is_nvboard(args.is_nvboard) {
  top = new TOP_NAME;
#ifdef CONFIG_NVBOARD
  void nvboard_bind_all_pins(TOP_NAME *);
  nvboard_bind_all_pins(top);
  nvboard_init();
#endif
}
void Sim::reset(int n) {
  top->reset = 1;
  while (n-- > 0)
    single_cycle();
  top->reset = 0;
}
void Sim::cpu_update() {
  for (int i = 1; i < REG_NUMS; i++) {
    if (GET_MEMBER(TOP_PREFIX, mrename__DOT__mrat__DOT__areg_state[i]) == 0) {
      cpu.gpr[i] = 0;
      continue;
    }
    cpu.gpr[i] = GET_MEMBER(TOP_PREFIX, mreg__DOT__sim_rf[i]);
  }

  cpu.pc = GET_MEMBER(TOP_PREFIX, sim_pc_w);
}
void Sim::open_wave(const std::string& path) {
  if (wave_on)
    return;
  Verilated::traceEverOn(true);
  contextp = new VerilatedContext;
  tfp = new VerilatedFstC();
  top->trace(tfp, 0);
  tfp->open(path.c_str());
  wave_on = true;
}
void Sim::step_and_dump_wave() {
  top->eval();
  if (wave_on) {
    contextp->timeInc(1);
    tfp->dump(contextp->time());
  }
}

void Sim::single_cycle() {
  top->clock = 1;
  step_and_dump_wave();
  top->clock = 0;
  step_and_dump_wave();
}

SIM_STATE Sim::exec_once() {
#ifdef CONFIG_NVBOARD
  nvboard_update();
#endif
  single_cycle();
  cpu_update();
  return state;
}

Sim::~Sim() {
  top->final();
  delete top;
  if (wave_on) {
    wave_on = false;
    tfp->close();
    delete tfp;
    delete contextp;
  }
}
