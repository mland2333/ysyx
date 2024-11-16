#include <cstdint>
#include <simulator.h>
#include <memory.hpp>
#include <args.h>
#include <sdb.h>
Sdb* sdb;

int main(int argc, char **argv) {
  Args args(argc, argv);
  Memory* mem = new Memory();
  mem->load_img(args.image);
  Simulator* sim = new Simulator(args);
  sdb = new Sdb(args, sim, mem);
  sim->reset(10);
  sdb->welcome();
  sdb->run();
  return 0;
}
