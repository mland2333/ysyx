#include <cstdint>
#include <simulator.h>
#include <memory.hpp>
#include <args.h>
#include <sdb.h>
Memory* mem;
Simulator* sim;
Sdb* sdb;

int main(int argc, char **argv) {
  Args args(argc, argv);
  mem = new Memory();
  mem->load_img(args.image);
  sim = new Simulator(args);
  sdb = new Sdb(args);
  sim->reset(10);
  sdb->welcome();
  sdb->run(sim);
  return 0;
}
