#include <cstdint>
#include <simulator.h>
#include <memory.hpp>
#include <args.h>
#include <sdb.h>
Memory mem;
Simulator* sim;
Sdb* sdb;
extern "C" int inst_fetch(int pc){
  return mem.read<uint32_t>(pc);
}
extern "C" void quit(){
  sim->quit();
}
int main(int argc, char **argv) {
  Args args(argc, argv);
  sim = new Simulator(args);
  sdb = new Sdb(args);
  sim->reset(10);
  sdb->run(sim);
  return 0;
}
