#include <cstdint>
#include <exception>
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
  try{
    sdb->run();
  } catch (const std::exception& e){
    std::cerr << "Caught exception: " << e.what() << std::endl;
  }
  delete sdb;
  delete mem;
  /* sim->~Simulator(); */
  return 0;
}
