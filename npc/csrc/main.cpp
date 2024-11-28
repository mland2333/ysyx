#include <exception>
#include <simulator.h>
#include <area.hpp>
#include <memory.h>
#include <args.h>
#include <sdb.h>
Sdb* sdb;

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Args args(argc, argv);
  Area sram("sram", 0x80000000, 0x10000000);
  Area mrom("mrom", 0x20000000, 0x10000, args.image);

  Memory mem({&sram, &mrom});
  Simulator sim(args);
  sim.reset(10);
  try{
    sdb = new Sdb(args, &sim, &mem);
    sdb->welcome();
    sdb->run();
  } catch (const std::exception& e){
    std::cerr << "Caught exception: " << e.what() << std::endl;
  }
  delete sdb;
  /* sim->~Simulator(); */
  return 0;
}
