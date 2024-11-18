#include <cstdint>
#include <simulator.h>
#include <memory.hpp>
#include <args.h>
#include <sdb.h>
Sdb* sdb;

int main(int argc, char **argv) {
  Args args(argc, argv);
  Memory* mem = new Memory();
  auto sim = std::make_unique<Simulator>(args);
  if(mem->load_img(args.image) == 0) return 0;
  sdb = new Sdb(args, sim.get(), mem);
  sim->reset(10);
  sdb->welcome();
  sdb->run();
  /* sim->~Simulator(); */
  return 0;
}
