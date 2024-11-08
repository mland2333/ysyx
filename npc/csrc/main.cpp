#include "simulator.h"
int main(int argc, char **argv) {
  Simulator sim(argc, argv);
  sim.reset(10);
  sim.run();
  return 0;
}
